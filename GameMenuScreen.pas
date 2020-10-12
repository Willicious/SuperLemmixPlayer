{$include lem_directives.inc}

unit GameMenuScreen;

{-------------------------------------------------------------------------------
  The main menu dos screen.
-------------------------------------------------------------------------------}

interface

uses
  Classes, Controls,
  CustomPopup,
  GameBaseScreenCommon, GameBaseMenuScreen, GameControl,
  LemNeoOnline, StrUtils,
  LemNeoLevelPack, {$ifdef exp}LemLevel, LemNeoPieceManager, LemGadgets, LemCore,{$endif}
  GR32, GR32_Layers;

type
  {-------------------------------------------------------------------------------
    these are the images we need for the menuscreen.
  -------------------------------------------------------------------------------}
  TGameMenuBitmap = (
    gmbLogo,
    gmbPlay,         // 1st row, 1st button
    gmbLevelCode,    // 1st row, 2nd button
    gmbSection,      // 1st row, 3rd button
    gmbConfig,        // 2nd row, 1st button
    gmbTalisman,   // 2nd row, 2nd button
    gmbExit,         // 2nd row, 3rd button
    gmbGameSection
  );

const
  {-------------------------------------------------------------------------------
    Positions at which the images of the menuscreen are drawn
  -------------------------------------------------------------------------------}
  GameMenuBitmapPositions: array[TGameMenuBitmap] of TPoint = (
    (X:432;    Y:72),                   // gmbLogo
    (X:304;  Y:196),                  // gmbPlay
    (X:432;  Y:196),                  // gmbLevelCode
    (X:560;  Y:196),                  // gmbSection
    (X:304;  Y:300),
    (X:432;  Y:300),                  // gmbTalisman
    (X:560;  Y:300),
    (X:570;  Y:206)
  );

  YPos_ProgramText = 364;
  YPos_Credits = 486 - 24;

  Reel_Width = 34 * 16;
  Reel_Height = 19;

  Font_Width = 16;

type
  TGameMenuScreen = class(TGameBaseMenuScreen)
  private
    fUpdateCheckThread: TDownloadThread;
    fVersionInfo: TStringList;

    DoneCleanInstallCheck: Boolean;

    fBackBuffer          : TBitmap32; // general purpose buffer

  { enumerated menu bitmap elements }
    BitmapElements : array[TGameMenuBitmap] of TBitmap32;
  { section }
    CurrentSection : Integer; // game section
  { credits }
    LeftLemmingAnimation   : TBitmap32;
    RightLemmingAnimation  : TBitmap32;
    Reel                   : TBitmap32;
    ReelBuffer             : TBitmap32;
    CanAnimate             : Boolean;
  { credits animation counters }
    FrameTimeMS            : Cardinal;
    PrevTime               : Cardinal;
    ReadingPauseMS         : Cardinal; //
    ReelLetterBoxCount     : Integer; // the number of letterboxes on the reel (34)
    Pausing                : Boolean;
    UserPausing            : Boolean;
    PausingDone            : Boolean; // the current text has been paused
    CreditList             : TStringList;
    CreditIndex            : Integer;
    CreditString           : String;
    TextX                  : Integer;
    TextPauseX             : Integer; // if -1 then no pause
    TextGoneX              : Integer;

    CurrentFrame           : Integer;
    ReelShift              : Integer;
  { internal }
    procedure DrawBitmapElement(aElement: TGameMenuBitmap);
    procedure SetSoundOptions(aOptions: TGameSoundOptions);
    procedure SetSection;
    procedure NextSection(Forwards: Boolean);
    procedure DrawWorkerLemmings(aFrame: Integer);
    procedure DrawReel;
    procedure SetNextCredit;
    procedure DumpImages;
    procedure CleanseLevels;
    procedure PerformUpdateCheck;
    procedure PerformCleanInstallCheck;
  { eventhandlers }
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Application_Idle(Sender: TObject; var Done: Boolean);
    procedure ShowSetupMenu;
  protected
  { overrides }
    procedure PrepareGameParams; override;
    procedure BuildScreen; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

  procedure GetGraphic(aName: String; aDst: TBitmap32; altName: String = '');

implementation

uses
  Forms, Math, Graphics, SysUtils, UMisc, Dialogs, Windows,
  UITypes, ShellApi, MMSystem,
  PngInterface, SharedGlobals,
  FNeoLemmixSetup, FStyleManager,
  LemTypes, LemStrings, LemGame, LemVersion;

{ TGameMenuScreen }

procedure GetGraphic(aName: String; aDst: TBitmap32; altName: String = '');
var
  buttonSelected: Integer;
begin
  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile(aName)) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile(aName), aDst)
  else if (altName <> '') and FileExists(AppPath + SFGraphicsMenu + altName) then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + altName, aDst)
  else if FileExists(AppPath + SFGraphicsMenu + aName) then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, aDst)
  else
  begin
    buttonSelected := MessageDlg('Could not find gfx\menu\' + aName + '. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;
end;


procedure TGameMenuScreen.DumpImages;
var
  BasePack: TNeoLevelGroup;
begin
  BasePack := GameParams.CurrentLevel.Group.ParentBasePack;
  BasePack.DumpImages(AppPath + 'Dump\' + MakeSafeForFilename(BasePack.Name) + '\');
  {$ifdef exp}
  BasePack.DumpNeoLemmixWebsiteMetaInfo(AppPath + 'Dump\' + MakeSafeForFilename(BasePack.Name) + '\');
  {$endif}
end;

procedure TGameMenuScreen.CleanseLevels;
var
  BasePack: TNeoLevelGroup;
begin
  BasePack := GameParams.CurrentLevel.Group.ParentBasePack;

  if DirectoryExists(AppPath + 'Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\') then
    ShowMessage('Output directory "Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\" already exists. Please delete this first.')
  else
    BasePack.CleanseLevels(AppPath + 'Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\');
end;

procedure TGameMenuScreen.PerformCleanInstallCheck;
var
  SL: TStringList;
  FMVer, CVer: Integer;
begin
  DoneCleanInstallCheck := true;

  SL := TStringList.Create;
  try
    if FileExists(AppPath + 'styles\version.ini') then
    begin
      SL.LoadFromFile(AppPath + 'styles\version.ini');
      if SL.Count >= 4 then
      begin
        FMVer := StrToIntDef(SL[0], -1);
        CVer := StrToIntDef(SL[1], -1);

        if (FMVer < FORMAT_VERSION) or
           ((FMVer = FORMAT_VERSION) and (CVer < CORE_VERSION)) then
        ShowMessage('It appears you have installed this version of NeoLemmix over an older major version. This is not recommended. ' +
                    'It is recommended that you perform a fresh, clean install of NeoLemmix whenever updating between major versions. ' +
                    'If you encounter any bugs, especially relating to styles, please test with a fresh install before reporting them.');
      end;
    end;

    SL.Clear;
    SL.Add(IntToStr(FORMAT_VERSION));
    SL.Add(IntToStr(CORE_VERSION));
    SL.Add(IntToStr(FEATURES_VERSION));
    SL.Add(IntToStr(HOTFIX_VERSION));
    {$ifdef rc}
      SL.Add('RC');
    {$else}
      {$ifdef exp}
        SL.Add('EXP');
      {$else}
        SL.Add('STABLE');
      {$endif}
    {$endif}

    SL.SaveToFile(AppPath + 'styles\version.ini');
  finally
    SL.Free;
  end;
end;

procedure TGameMenuScreen.PerformUpdateCheck;
begin
  // Checks if the latest version according to NeoLemmix Website is more recent than the
  // one currently running. If running an experimental version, also checks if it's the
  // exact same version (as it would be a stable release).
  GameParams.DoneUpdateCheck := true;

  if not GameParams.CheckUpdates then Exit;

  fUpdateCheckThread := DownloadInThread(VERSION_FILE, fVersionInfo,
    procedure
    var
      NewVersionStr, OrigVersionStr: String;
      SL: TStringList;
      n: Integer;
      NewestID: Int64;
      URL: String;
      F: TFManageStyles;
    begin
      NewVersionStr := fVersionInfo.Values['game'];
      if LeftStr(NewVersionStr, 1) = 'V' then
        NewVersionStr := RightStr(NewVersionStr, Length(NewVersionStr)-1);

      OrigVersionStr := NewVersionStr;
      NewVersionStr := StringReplace(NewVersionStr, '-', '.', [rfReplaceAll]);

      SL := TStringList.Create;
      try
        try
          SL.Delimiter := '.';
          SL.StrictDelimiter := true;
          SL.DelimitedText := NewVersionStr;

          if SL.Count < 4 then
            SL.Add('A');

          SL[3] := Char(Ord(SL[3][1]) - 65);

          NewestID := 0;
          for n := 0 to 3 do
            NewestID := (NewestID * 1000) + StrToIntDef(SL[n], 0);

          if (NewestID > CurrentVersionID){$ifdef exp} or (NewestID = CurrentVersionID){$endif} then
          begin
            case RunCustomPopup(self, 'Update', 'A NeoLemmix update, V' + OrigVersionStr + ', is available. Do you want to download it?',
              'Go to NeoLemmix website|Remind me later') of
              1: begin
                   URL := 'https://www.neolemmix.com/?page=neolemmix';
                   ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
                   CloseScreen(gstExit);
                 end;
               // 2: do nothing;
            end;
          end else if CheckStyleUpdates then
          begin
            // Add cursor stuff here

            case RunCustomPopup(self, 'Styles Update', 'Styles updates are available. Do you want to download them?',
              'Open Style Manager|Remind me later') of
              1: begin
                   F := TFManageStyles.Create(self);
                   try
                     F.ShowModal;
                   finally
                     F.Free;
                   end;
                 end;
              // 2: do nothing;
            end;
          end;

        except
          // Fail silently.
        end;
      finally
        SL.Free;
      end;

      fUpdateCheckThread := nil;
    end
  );
end;

procedure TGameMenuScreen.DrawBitmapElement(aElement: TGameMenuBitmap);
{-------------------------------------------------------------------------------
  Draw bitmap at appropriate place on the screen.
-------------------------------------------------------------------------------}
var
  P: TPoint;
begin
  P := GameMenuBitmapPositions[aElement];
  // adjust gmbConfig to right, gmbExit to left, if no talismans
  // and don't draw gmbTalisman at all
  if   (GameParams.CurrentLevel = nil)
    or (GameParams.CurrentLevel.Group.ParentBasePack.Talismans.Count = 0) then
    case aElement of
      gmbConfig: P.X := P.X + 64;
      gmbExit: P.X := P.X - 64;
      gmbTalisman: Exit;
    end;

  P.X := P.X - (BitmapElements[aElement].Width div 2);
  P.Y := P.Y - (BitmapElements[aElement].Height div 2);

  BitmapElements[aElement].DrawTo(ScreenImg.Bitmap, P.X, P.Y);
end;

procedure TGameMenuScreen.BuildScreen;
{-------------------------------------------------------------------------------
  extract bitmaps from the lemmingsdata and draw
-------------------------------------------------------------------------------}
var
  Tmp: TBitmap32;
  i: Integer;
  GrabRect: TRect;
  S, S2: String;
  iPanel: TGameMenuBitmap;
  P: TPoint;

  procedure LoadScrollerGraphics;
  var
    TempBMP: TBitmap32;
    SourceRect: TRect;
  begin
    TempBMP := TBitmap32.Create;
    GetGraphic('scroller_segment.png', Tmp);
    GetGraphic('scroller_lemmings.png', TempBMP);
    SourceRect := Rect(0, 0, 48, 304);
    LeftLemmingAnimation.SetSize(48, 304);
    RightLemmingAnimation.SetSize(48, 304);
    TempBmp.DrawTo(LeftLemmingAnimation, 0, 0, SourceRect);
    SourceRect.Right := SourceRect.Right + 48;
    SourceRect.Left := SourceRect.Left + 48;
    TempBmp.DrawTo(RightLemmingAnimation, 0, 0, SourceRect);
    TempBmp.Free;
    LeftLemmingAnimation.DrawMode := dmBlend;
    LeftLemmingAnimation.CombineMode := cmMerge;
    RightLemmingAnimation.DrawMode := dmBlend;
    RightLemmingAnimation.CombineMode := cmMerge;
  end;
begin
  Tmp := TBitmap32.Create;
  ScreenImg.BeginUpdate;
  try
    GetGraphic('logo.png', BitmapElements[gmbLogo]);
    GetGraphic('sign_play.png', BitmapElements[gmbPlay]);
    GetGraphic('sign_code.png', BitmapElements[gmbLevelCode]);
    GetGraphic('sign_rank.png', BitmapElements[gmbSection]);
    GetGraphic('sign_config.png', BitmapElements[gmbConfig]);
    GetGraphic('sign_talisman.png', BitmapElements[gmbTalisman]);
    GetGraphic('sign_quit.png', BitmapElements[gmbExit]);
    // rank graphic will be loaded in SetSection!

    LoadScrollerGraphics;

    for iPanel := Low(TGameMenuBitmap) to High(TGameMenuBitmap) do
    begin
      BitmapElements[iPanel].DrawMode := dmBlend;
      BitmapElements[iPanel].CombineMode := cmMerge;
    end;

    // a little oversize
    Reel.SetSize(ReelLetterBoxCount * 16 + 32, 19);
    for i := 0 to ReelLetterBoxCount - 1 + 4 do
      Tmp.DrawTo(Reel, i * 16, 0);

    // make sure the reelbuffer is the right size
    ReelBuffer.SetSize(ReelLetterBoxCount * 16, 19);

    // background
    DrawBackground;
    fBackBuffer.Assign(ScreenImg.Bitmap); // save it

    // menu elements
    DrawBitmapElement(gmbLogo);
    DrawBitmapElement(gmbPlay);
    DrawBitmapElement(gmbLevelCode);
    DrawBitmapElement(gmbConfig);
    DrawBitmapElement(gmbSection);
    DrawBitmapElement(gmbExit);
    DrawBitmapElement(gmbTalisman);

    // re-capture the gmbSection, because we'll probably need to re-draw it later
    // to prevent writing over section graphics with other semitransparent ones
    //    (X:392;  Y:120),                  // gmbSection
    P := GameMenuBitmapPositions[gmbSection];

    GrabRect := BitmapElements[gmbSection].BoundsRect;
    GrabRect.Offset(P.X - GrabRect.Width div 2, P.Y - GrabRect.Height div 2);
    ScreenImg.Bitmap.DrawTo(BitmapElements[gmbSection], BitmapElements[gmbSection].BoundsRect, GrabRect);
    BitmapElements[gmbSection].DrawMode := dmOpaque;

    // program text
    S := CurrentVersionString;
    {$ifdef exp}if COMMIT_ID <> '' then S := S + ':' + Uppercase(COMMIT_ID);{$endif}

    if GameParams.CurrentLevel <> nil then
      S2 := GameParams.CurrentLevel.Group.PackTitle + #13 +
            GameParams.CurrentLevel.Group.PackAuthor + #13 + #13 +
            'NeoLemmix Player V' + S
    else if GameParams.BaseLevelPack <> nil then
      S2 := 'No Levels Found' + #13 + #13 + 'NeoLemmix Player V' + S
    else
      S2 := 'No Pack' + #13 + #13 + 'NeoLemmix Player V' + S;
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, S2, YPos_ProgramText);

    // scroller text
    if GameParams.CurrentLevel <> nil then
      CreditList.assign(GameParams.CurrentLevel.Group.ScrollerList)
    else
      CreditList.Text := 'No pack' + #13;

    // credits animation
    DrawWorkerLemmings(0);
    DrawReel;

    // a bit weird place, but here we know the bitmaps are loaded
    SetSection;
    SetSoundOptions(GameParams.SoundOptions);

    CanAnimate := True;
  finally
    ScreenImg.EndUpdate;
    Tmp.Free;
  end;

  GameParams.ShownText := false;
end;

constructor TGameMenuScreen.Create(aOwner: TComponent);
var
  E: TGameMenuBitmap;
  Bmp: TBitmap32;
begin
  inherited Create(aOwner);

  fBackBuffer := TBitmap32.Create;

  fVersionInfo := TStringList.Create;

  CurrentSection := 0;

  // create bitmaps
  for E := Low(TGameMenuBitmap) to High(TGameMenuBitmap) do
  begin
    Bmp := TBitmap32.Create;
    BitmapElements[E] := Bmp;
    if not (E = gmbGameSection)
    then Bmp.DrawMode := dmBlend;
  end;

  LeftLemmingAnimation := TBitmap32.Create;
  LeftLemmingAnimation.DrawMode := dmBlend;

  RightLemmingAnimation := TBitmap32.Create;
  RightLemmingAnimation.DrawMode := dmBlend;

  Reel := TBitmap32.Create;
  ReelBuffer := TBitmap32.Create;
  CreditList := TStringList.Create;

  FrameTimeMS := 32;
  ReadingPauseMS := 1000;
  CreditList.Text := '';
  CreditIndex := -1;
  ReelLetterBoxCount := 34;
  CreditIndex := -1;

  // set eventhandlers
  OnKeyDown := Form_KeyDown;
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;
  Application.OnIdle := Application_Idle;
end;

destructor TGameMenuScreen.Destroy;
var
  E: TGameMenuBitmap;
begin
  for E := Low(TGameMenuBitmap) to High(TGameMenuBitmap) do
    BitmapElements[E].Free;

  LeftLemmingAnimation.Free;
  RightLemmingAnimation.Free;
  Reel.Free;
  ReelBuffer.Free;
  CreditList.Free;
  fVersionInfo.Free;
  fBackBuffer.Free;

  inherited Destroy;
end;

procedure TGameMenuScreen.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift = [] then
  begin
    case Key of
      VK_RETURN : if GameParams.CurrentLevel <> nil then CloseScreen(gstPreview);
      VK_F1     : if GameParams.CurrentLevel <> nil then CloseScreen(gstPreview);
      VK_F2     : DoLevelSelect;
      VK_F3     : ShowConfigMenu;
      VK_F4     : begin
                    if (GameParams.CurrentLevel <> nil)
                       and (GameParams.CurrentLevel.Group.ParentBasePack.Talismans.Count <> 0) then
                      CloseScreen(gstTalisman);
                  end;
      VK_F6     : DumpImages;
      VK_F7     : DoMassReplayCheck;
      VK_F8     : CleanseLevels;
      VK_ESCAPE : CloseScreen(gstExit);
      VK_UP     : if GameParams.CurrentLevel <> nil then NextSection(True);
      VK_DOWN   : if GameParams.CurrentLevel <> nil then NextSection(False);
    end;
  end;
end;

procedure TGameMenuScreen.Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (GameParams.CurrentLevel <> nil) then
    CloseScreen(gstPreview)
  else if (Button = mbMiddle) then
    DoLevelSelect
  else if (Button = mbRight) then
    CloseScreen(gstExit);
end;

procedure TGameMenuScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  if (Button = mbLeft) and (GameParams.CurrentLevel <> nil) then
    CloseScreen(gstPreview)
  else if (Button = mbMiddle) then
    DoLevelSelect
  else if (Button = mbRight) then
    CloseScreen(gstExit);
end;

procedure TGameMenuScreen.NextSection(Forwards: Boolean);
begin
  if Forwards then
    GameParams.NextGroup
  else
    GameParams.PrevGroup;

  SetSection;
end;

procedure TGameMenuScreen.PrepareGameParams;
begin
  inherited PrepareGameParams;

  if not (GameParams.CurrentLevel = nil) then
    CurrentSection := GameParams.CurrentLevel.Group.ParentGroupIndex
  else
    CurrentSection := 0;

  if Assigned(GlobalGame) then
    GlobalGame.ReplayManager.Clear(true);
end;

procedure TGameMenuScreen.SetSoundOptions(aOptions: TGameSoundOptions);
begin
  GameParams.SoundOptions := aOptions;
end;

procedure TGameMenuScreen.SetSection;
var
  index: Integer;
  altName: String;
begin
  DrawBitmapElement(gmbSection); // This allows for transparency in the gmbGameSectionN bitmaps

  if (GameParams.CurrentLevel = nil) or (GameParams.CurrentLevel.Group = nil) or (GameParams.CurrentLevel.Group.Parent = nil) then
    altName := ''
  else
  begin
      index := GameParams.CurrentLevel.Group.Parent.GroupIndex[GameParams.CurrentLevel.Group] + 1;
      altName := 'rank_' + Integer.ToString(index).PadLeft(2, '0') + '.png';
  end;
  GetGraphic('rank_graphic.png', BitmapElements[gmbGameSection], altName);
  DrawBitmapElement(gmbGameSection);
end;

procedure TGameMenuScreen.DrawWorkerLemmings(aFrame: Integer);
var
  SrcRect, DstRect: TRect;
begin
  SrcRect := CalcFrameRect(LeftLemmingAnimation, 16, aFrame);
  DstRect := Rect(0, 0, RectWidth(SrcRect), RectHeight(SrcRect));
  OffsetRect(DstRect, (864 - ReelBuffer.Width) div 2 - LeftLemmingAnimation.Width, YPos_Credits);
  fBackBuffer.DrawTo(ScreenImg.Bitmap, DstRect, DstRect);
  LeftLemmingAnimation.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);

  DstRect := Rect(0, 0, RectWidth(SrcRect), RectHeight(SrcRect));
  OffsetRect(DstRect, (864 + ReelBuffer.Width) div 2, YPos_Credits);
  fBackBuffer.DrawTo(ScreenImg.Bitmap, DstRect, DstRect);
  RightLemmingAnimation.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
end;

procedure TGameMenuScreen.SetNextCredit;
var
  TextSize: Integer;
begin
  TextX := 33 * 16;

  if CreditList.Count = 0 then
  begin
    CreditString := '';
    Exit;
  end;

  Inc(CreditIndex);
  if CreditIndex > CreditList.Count - 1 then
    CreditIndex := 0;

  // set new string
  CreditString := CreditList[CreditIndex];
  Pausing := False;
  PausingDone := False;
  TextSize := Length(CreditString) * Font_Width;
  TextPauseX := (Reel_Width - TextSize) div 2;
  TextGoneX := -TextSize;// + 10 * Font_Width;
end;

procedure TGameMenuScreen.DrawReel;
begin
  // Drawing of the moving credits.
  Reel.DrawTo(ReelBuffer, ReelShift, 0);
  MenuFont.DrawText(ReelBuffer, CreditString, TextX, 0);
  ReelBuffer.DrawTo(ScreenImg.Bitmap, (864 - ReelBuffer.Width) div 2, YPos_Credits);
end;

procedure TGameMenuScreen.Application_Idle(Sender: TObject; var Done: Boolean);
{-------------------------------------------------------------------------------
  Animation of credits.
  - 34 characters fit into the reel.
  - text scolls from right to left. When one line is centered into the reel,
    scrolling is paused for a while.
-------------------------------------------------------------------------------}
var
  CurrTime: Cardinal;
begin
  if not GameParams.DoneUpdateCheck then
    PerformUpdateCheck;

  if not DoneCleanInstallCheck then
    PerformCleanInstallCheck;

  if (not GameParams.LoadedConfig) then
  begin
    GameParams.LoadedConfig := true;
    ShowSetupMenu;
  end;

  if not CanAnimate or ScreenIsClosing then
    Exit;

  Sleep(1);
  Done := False;
  CurrTime := TimeGetTime;
  if UserPausing then
    Exit;

  { check end reading pause }
  if Pausing then
  begin
    if CurrTime > PrevTime + ReadingPauseMS then
    begin
      PrevTime := CurrTime;
      Pausing := False;
      PausingDone := True; // we only pause once per text
    end;
    Exit;
  end;

  { update frames }
  if CurrTime > PrevTime + FrameTimeMS then
  begin
    PrevTime := CurrTime;

    { workerlemmings animation has 16 frames }
    Inc(CurrentFrame);
    if CurrentFrame >= 15 then
      CurrentFrame := 0;

    { text + reel }
    Dec(ReelShift, 4);
    if ReelShift <= - 16 then
      ReelShift := 0;

    Dec(TextX, 4);
    if TextX < TextGoneX then
      SetNextCredit;

    // if text can be centered then pause if we are there
    if (not PausingDone) and (TextPauseX >= 0) and (TextX <= TextPauseX) then
      Pausing := True;

    DrawWorkerLemmings(CurrentFrame);
    DrawReel;
  end;
end;

procedure TGameMenuScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  if fUpdateCheckThread <> nil then
    fUpdateCheckThread.Kill;
  inherited CloseScreen(aNextScreen);
end;

procedure TGameMenuScreen.ShowSetupMenu;
var
  F: TFNLSetup;
begin
  F := TFNLSetup.Create(self);
  try
    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(true, false, false, false);
  finally
    F.Free;
  end;
end;

end.

