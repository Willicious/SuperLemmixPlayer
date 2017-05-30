{$include lem_directives.inc}

unit GameMenuScreen;

{-------------------------------------------------------------------------------
  The main menu dos screen.
-------------------------------------------------------------------------------}

interface

uses
  Math,
  PngInterface, SharedGlobals,
  Windows, Classes, Controls, Graphics, MMSystem, Forms, SysUtils, ShellApi,
  FNeoLemmixConfig,
  GR32, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs, LemVersion,
  LemTypes, LemStrings, LemDosStructures, LemGame,
  GameControl, GameBaseScreen;

type
  {-------------------------------------------------------------------------------
    these are the images we need for the menuscreen.
  -------------------------------------------------------------------------------}
  TGameMenuBitmap = (
    gmbLogo,
    gmbPlay,         // 1st row, 1st button
    gmbLevelCode,    // 1st row, 2nd button
    gmbConfig,        // 1st row, 3d button
    gmbSection,      // 1st row, 4th button
    gmbExit,         // 2nd row, 1st button
    gmbTalisman,   // 2nd row, 2nd button
    gmbGameSection1, // mayhem/havoc    drawn in gmbSection
    gmbGameSection2, // taxing/wicked   drawn in gmbSection
    gmbGameSection3, // tricky/wild     drawn in gmbSection
    gmbGameSection4, // fun/crazy       drawn in gmbSection
    gmbGameSection5, // .../tame        drawn in gmbSection
    gmbGameSection6,
    gmbGameSection7,
    gmbGameSection8,
    gmbGameSection9,
    gmbGameSection10,
    gmbGameSection11,
    gmbGameSection12,
    gmbGameSection13,
    gmbGameSection14,
    gmbGameSection15
  );

const
  {-------------------------------------------------------------------------------
    Positions at which the images of the menuscreen are drawn
  -------------------------------------------------------------------------------}
  GameMenuBitmapPositions: array[TGameMenuBitmap] of TPoint = (
    (X:8;    Y:20),                   // gmbLogo
    (X:136;   Y:140),                  // gmbPlay
    (X:264;  Y:140),                  // gmbLevelCode
    (X:136;  Y:236),
    (X:392;  Y:140),                  // gmbSection
    (X:392;  Y:236),
    (X:264;  Y:236),                  // gmbTalisman
    (X:392 + 32;    Y:140 + 24),      // gmbSection1
    (X:392 + 32;    Y:140 + 24),      // gmbSection2
    (X:392 + 32;    Y:140 + 24),      // gmbSection3
    (X:392 + 32;    Y:140 + 24),      // gmbSection4
    (X:392 + 32;    Y:140 + 24),      // gmbSection5
    (X:392 + 32;    Y:140 + 24),       // gmbSection6
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24),
    (X:392 + 32;    Y:140 + 24)
  );

  YPos_ProgramText = 322;
  YPos_Credits = 400 - 24;

  Reel_Width = 34 * 16;
  Reel_Height = 16;

  Font_Width = 16;

type
  TGameMenuScreen = class(TGameBaseScreen)
  private
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
    CreditString          : string;
    TextX           : Integer;
    TextPauseX      : Integer; // if -1 then no pause
    TextGoneX       : Integer;

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
    procedure DumpLevels;
    procedure DumpImages;
    procedure ShowConfigMenu;
    procedure DoTestStuff; //what a great name. it's a function I have here for testing things.
    procedure PerformUpdateCheck;
    procedure DoMassReplayCheck;
    procedure DoLevelSelect;
  { eventhandlers }
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Application_Idle(Sender: TObject; var Done: Boolean);
    function BuildText(intxt: Array of char): String;
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

  procedure GetGraphic(aName: String; aDst: TBitmap32);

implementation

uses
  LemNeoLevelPack,
  FNeoLemmixLevelSelect,
  FNeoLemmixSetup,
  LemNeoOnline;

{ TGameMenuScreen }

procedure GetGraphic(aName: String; aDst: TBitmap32);
var
  MaskColor: TColor32;
  SrcFile: String;
begin
  SrcFile := GameParams.BaseLevelPack.Path + aName;
  if not FileExists(SrcFile) then
    SrcFile := AppPath + SFGraphicsMenu + aName;

  TPngInterface.LoadPngFile(SrcFile, aDst);
end;

procedure TGameMenuScreen.DoTestStuff;
{$ifdef exp}
var
  Format, Core, Feature, Fix: Integer;
  S: String;
{$endif}
begin
// Any random test code can go here. Since it's for testing purposes, I've
// added a conditional define so it doesn't get included in release versions.
{$ifdef exp}
  if GetLatestNeoLemmixVersion(NxaPlayer, Format, Core, Feature, Fix) then
  begin
    S := 'V' + MakeVersionString(Format, Core, Feature, Fix);
    ShowMessage('Latest version reported as: ' + S);
  end else
    ShowMessage('Version check fail.');
{$endif}
end;

procedure TGameMenuScreen.PerformUpdateCheck;
var
  Format, Core, Feature, Fix: Integer;
  CurVer, AvailVer: Int64;
begin
  // Checks if the latest version according to NeoLemmix Website is more recent than the
  // one currently running. If running an experimental version, also checks if it's the
  // exact same version (as it would be a stable release).
  GameParams.DoneUpdateCheck := true;
  if not (GameParams.EnableOnline and GameParams.CheckUpdates) then Exit;
  if GetLatestNeoLemmixVersion(NxaPlayer, Format, Core, Feature, Fix) then
  begin
    CurVer := CurrentVersionID;
    AvailVer := MakeVersionID(Format, Core, Feature, Fix);
    if (AvailVer > CurVer)
    {$ifdef exp}or (AvailVer = CurVer){$endif} then
      if MessageDlg('Update available: NeoLemmix V' + MakeVersionString(Format, Core, Feature, Fix) + #13 +
                    'Go to the NeoLemmix website?', mtCustom, [mbYes, mbNo], 0) = mrYes then
      begin
        ShellExecute(handle,'open',PChar('http://www.neolemmix.com/neolemmix.html'), '','',SW_SHOWNORMAL);
        CloseScreen(gstExit);
      end;
  end;
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
  if GameParams.Talismans.Count = 0 then
    case aElement of
      gmbConfig: P.X := P.X + 64;
      gmbExit: P.X := P.X - 64;
      gmbTalisman: Exit;
    end;
  BitmapElements[aElement].DrawTo(ScreenImg.Bitmap, P.X, P.Y);
end;

procedure TGameMenuScreen.BuildScreen;
{-------------------------------------------------------------------------------
  extract bitmaps from the lemmingsdata and draw
-------------------------------------------------------------------------------}
var
  Mainpal: TArrayOfColor32;
  Tmp: TBitmap32;
  i: Integer;
  GrabRect: TRect;
  S: String;
  iPanel: TGameMenuBitmap;

  procedure LoadScrollerGraphics;
  var
    TempBMP: TBitmap32;
    SourceRect: TRect;
  begin
    TempBMP := TBitmap32.Create;
    GetGraphic('scroller_segment.png', Tmp);
    GetGraphic('scroller_lemmings.png', TempBMP);
    SourceRect := Rect(0, 0, 48, 256);
    LeftLemmingAnimation.SetSize(48, 256);
    RightLemmingAnimation.SetSize(48, 256);
    TempBmp.DrawTo(LeftLemmingAnimation, 0, 0, SourceRect);
    SourceRect.Right := SourceRect.Right + 48;
    SourceRect.Left := SourceRect.Left + 48;
    TempBmp.DrawTo(RightLemmingAnimation, 0, 0, SourceRect);
    TempBmp.Free;
    LeftLemmingAnimation.DrawMode := dmBlend;
    RightLemmingAnimation.DrawMode := dmBlend;
  end;
begin
  Tmp := TBitmap32.Create;
  ScreenImg.BeginUpdate;
  try
    MainPal := GetDosMainMenuPaletteColors32;
    InitializeImageSizeAndPosition(640, 400);
    ExtractBackGround;
    ExtractPurpleFont;

    GetGraphic('logo.png', BitmapElements[gmbLogo]);
    GetGraphic('sign_play.png', BitmapElements[gmbPlay]);
    GetGraphic('sign_code.png', BitmapElements[gmbLevelCode]);
    GetGraphic('sign_config.png', BitmapElements[gmbConfig]);
    GetGraphic('sign_rank.png', BitmapElements[gmbSection]);
    GetGraphic('sign_quit.png', BitmapElements[gmbExit]);
    GetGraphic('sign_talisman.png', BitmapElements[gmbTalisman]);

    for i := 0 to 14 do
      GetGraphic('rank_' + LeadZeroStr(i+1, 2) + '.png', BitmapElements[TGameMenuBitmap(Integer(gmbGameSection1) + i)]);

    LoadScrollerGraphics;

    for iPanel := Low(TGameMenuBitmap) to High(TGameMenuBitmap) do
      BitmapElements[iPanel].DrawMode := dmBlend;

    // a little oversize
    Reel.SetSize(ReelLetterBoxCount * 16 + 32, 16);
    for i := 0 to ReelLetterBoxCount - 1 + 4 do
      Tmp.DrawTo(Reel, i * 16, 0);

    // make sure the reelbuffer is the right size
    ReelBuffer.SetSize(ReelLetterBoxCount * 16, 16);

    // background
    TileBackgroundBitmap(0, 0);
    BackBuffer.Assign(ScreenImg.Bitmap); // save it

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
    GrabRect := BitmapElements[gmbSection].BoundsRect;
    GrabRect.Right := GrabRect.Right + 392;
    GrabRect.Left := GrabRect.Left + 392;
    GrabRect.Bottom := GrabRect.Bottom + 140;
    GrabRect.Top := GrabRect.Top + 140;
    ScreenImg.Bitmap.DrawTo(BitmapElements[gmbSection], BitmapElements[gmbSection].BoundsRect, GrabRect);
    BitmapElements[gmbSection].DrawMode := dmOpaque;

    // program text
    S := CurrentVersionString;
    {$ifdef exp}if COMMIT_ID <> '' then S := S + ':' + Uppercase(COMMIT_ID);{$endif}
    DrawPurpleTextCentered(ScreenImg.Bitmap, GameParams.BaseLevelPack.Name + #13 + 'NeoLemmix Player V' + S, YPos_ProgramText);

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
end;

constructor TGameMenuScreen.Create(aOwner: TComponent);
var
  E: TGameMenuBitmap;
  Bmp: TBitmap32;
begin
  inherited Create(aOwner);

  CurrentSection := 0;

  // create bitmaps
  for E := Low(TGameMenuBitmap) to High(TGameMenuBitmap) do
  begin
    Bmp := TBitmap32.Create;
    BitmapElements[E] := Bmp;
    if not (E in [gmbGameSection1, gmbGameSection2, gmbGameSection3, gmbGameSection4,
      gmbGameSection5, gmbGameSection6, gmbGameSection7, gmbGameSection8, gmbGameSection9, gmbGameSection10,
      gmbGameSection11, gmbGameSection12, gmbGameSection13, gmbGameSection14, gmbGameSection15])
    then Bmp.DrawMode := dmTransparent;
  end;

  LeftLemmingAnimation := TBitmap32.Create;
  LeftLemmingAnimation.DrawMode := dmTransparent;

  RightLemmingAnimation := TBitmap32.Create;
  RightLemmingAnimation.DrawMode := dmTransparent;

  Reel := TBitmap32.Create;
  ReelBuffer := TBitmap32.Create;
  CreditList := TStringList.Create;

  FrameTimeMS := 32;
  ReadingPauseMS := 1000;
  CreditList.Text := '';
  CreditIndex := -1;
  ReelLetterBoxCount := 34;
  SetNextCredit;
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

  inherited Destroy;
end;

procedure TGameMenuScreen.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift = [] then
  begin
    case Key of
      VK_RETURN : CloseScreen(gstPreview);
      VK_F1     : CloseScreen(gstPreview);
      VK_F2     : DoLevelSelect;
      VK_F3     : ShowConfigMenu;
      VK_F4     : DumpLevels;
      VK_F5     : DumpImages;
      VK_F6     : if GameParams.Talismans.Count <> 0 then CloseScreen(gstTalisman);
      VK_F7     : DoMassReplayCheck;
      VK_F12    : DoTestStuff;
      VK_ESCAPE : CloseScreen(gstExit);
      VK_UP     : NextSection(True);
      VK_DOWN   : NextSection(False);
    end;
  end;
end;

procedure TGameMenuScreen.ShowConfigMenu;
var
  ConfigDlg: TFormNXConfig;
  OldFullScreen: Boolean;
begin
  OldFullScreen := GameParams.FullScreen;
  ConfigDlg := TFormNXConfig.Create(self);
  ConfigDlg.SetGameParams;
  ConfigDlg.NXConfigPages.TabIndex := 0;
  ConfigDlg.ShowModal;
  ConfigDlg.Free;

  // Wise advice from Simon - save these things on exiting the
  // config dialog, rather than waiting for a quit or a screen
  // transition to save them.
  GameParams.Save;

  if (GameParams.FullScreen <> OldFullScreen) then
  begin
    if GameParams.FullScreen then
    begin
      GameParams.MainForm.WindowState := wsMaximized;
      GameParams.MainForm.BorderStyle := bsNone;
    end else begin
      GameParams.MainForm.BorderStyle := bsSizeable;
      GameParams.MainForm.WindowState := wsNormal;
      GameParams.MainForm.ClientWidth := Min(GameParams.ZoomLevel * 320, Min(Screen.Width div 320, Screen.Height div 200) * 320);
      GameParams.MainForm.ClientHeight := Min(GameParams.ZoomLevel * 200, Min(Screen.Width div 320, Screen.Height div 200) * 200);
      GameParams.MainForm.Left := (Screen.Width div 2) - (GameParams.MainForm.Width div 2);
      GameParams.MainForm.Top := (Screen.Height div 2) - (GameParams.MainForm.Height div 2);
    end;
  end;

  if GameParams.LinearResampleMenu then
  begin
    if ScreenImg.Bitmap.Resampler is TNearestResampler then
    begin
      TLinearResampler.Create(ScreenImg.Bitmap);
      ScreenImg.Bitmap.Changed;
    end;
  end else begin
    if ScreenImg.Bitmap.Resampler is TLinearResampler then
    begin
      TNearestResampler.Create(ScreenImg.Bitmap);
      ScreenImg.Bitmap.Changed;
    end;
  end;

end;

procedure TGameMenuScreen.DumpImages;
var
  I: Integer;
begin
  I := MessageDlg('Dump all level images? Warning: This is very slow!', mtCustom, [mbYes, mbNo], 0);
  if I = mrYes then
  begin
    raise Exception.Create('TGameMenuScreen.DumpImages not yet implemented with new level pack code');
    //TBaseDosLevelSystem(GameParams.Style.LevelSystem).DumpAllImages;
  end;
end;

procedure TGameMenuScreen.DumpLevels;
var
  I: Integer;
begin
  I := MessageDlg('Dump all level files? Warning: This may overwrite' + CrLf + 'LVL files currently present!', mtCustom, [mbYes, mbNo], 0);
  if I = mrYes then
  begin
    raise Exception.Create('TGameMenuScreen.DumpLevels not yet implemented with new level pack code');
    //TBaseDosLevelSystem(GameParams.Style.LevelSystem).DumpAllLevels;
  end;
end;

procedure TGameMenuScreen.Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    CloseScreen(gstPreview);
end;

procedure TGameMenuScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  if Button = mbLeft then
    CloseScreen(gstPreview);
end;

procedure TGameMenuScreen.NextSection(Forwards: Boolean);
begin
  if Forwards then
    GameParams.NextGroup
  else
    GameParams.PrevGroup;

  SetSection;

  GameParams.ShownText := false;
end;

procedure TGameMenuScreen.PrepareGameParams;
var
  i: Integer;
  k: String;
begin
  inherited PrepareGameParams;

  CurrentSection := GameParams.CurrentLevel.Group.ParentGroupIndex;

  CreditList.Text := {$ifdef exp}'EXPERIMENTAL PLAYER RELEASE' + #13 +{$endif} GameParams.BaseLevelPack.Name + #13;
  (*for i := 0 to 15 do
  begin
    k := BuildText(GameParams.SysDat.ScrollerTexts[i]);
    if k <> '' then
      CreditList.Text := CreditList.Text + k + #13;
  end;
  CreditList.Text := CreditList.Text + SCredits;*)
  SetNextCredit;

  if Assigned(GlobalGame) then
    GlobalGame.ReplayManager.Clear(true);
end;

function TGameMenuScreen.BuildText(intxt: Array of char): String;
begin
  // Casts the array to a string and trims it.
  Result := '';
  if Length(intxt) > 0 then
  begin
    SetString(Result, PChar(@intxt[0]), Length(intxt));
    Result := Trim(Result);
  end;
end;

procedure TGameMenuScreen.SetSoundOptions(aOptions: TGameSoundOptions);
begin
  GameParams.SoundOptions := aOptions;
end;

procedure TGameMenuScreen.SetSection;
begin
  CurrentSection := GameParams.CurrentLevel.Group.ParentGroupIndex;
  //@styledef
  DrawBitmapElement(gmbSection); // This allows for transparency in the gmbGameSectionN bitmaps
  case CurrentSection of
    0: DrawBitmapElement(gmbGameSection1);
    1: DrawBitmapElement(gmbGameSection2);
    2: DrawBitmapElement(gmbGameSection3);
    3: DrawBitmapElement(gmbGameSection4);
    4: DrawBitmapElement(gmbGameSection5);
    5: DrawBitmapElement(gmbGameSection6);
    6: DrawBitmapElement(gmbGameSection7);
    7: DrawBitmapElement(gmbGameSection8);
    8: DrawBitmapElement(gmbGameSection9);
    9: DrawBitmapElement(gmbGameSection10);
    10: DrawBitmapElement(gmbGameSection11);
    11: DrawBitmapElement(gmbGameSection12);
    12: DrawBitmapElement(gmbGameSection13);
    13: DrawBitmapElement(gmbGameSection14);
    14: DrawBitmapElement(gmbGameSection15);
  end;

  //GameParams.SetLevel(CurrentSection, -1);
end;

procedure TGameMenuScreen.DrawWorkerLemmings(aFrame: Integer);
var
  SrcRect, DstRect: TRect;
begin
  SrcRect := CalcFrameRect(LeftLemmingAnimation, 16, aFrame);
  DstRect := Rect(0, 0, RectWidth(SrcRect), RectHeight(SrcRect));
  OffsetRect(DstRect, 0, YPos_Credits);
  BackBuffer.DrawTo(ScreenImg.Bitmap, DstRect, DstRect);
  LeftLemmingAnimation.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);

  DstRect := Rect(0, 0, RectWidth(SrcRect), RectHeight(SrcRect));
  OffsetRect(DstRect, 640 - 48, YPos_Credits);
  BackBuffer.DrawTo(ScreenImg.Bitmap, DstRect, DstRect);
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
  DrawPurpleText(ReelBuffer, CreditString, TextX, 0);
  ReelBuffer.DrawTo(ScreenImg.Bitmap, 48, YPos_Credits);
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

  if not GameParams.LoadedConfig then
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
    begin
      SetNextCredit;
    end;

    if not PausingDone then
    begin
      // if text can be centered then pause if we are there
      if TextPauseX >= 0 then
        if TextX <= TextPauseX then
          Pausing := True;
    end;

    DrawWorkerLemmings(CurrentFrame);
    DrawReel;
  end;
end;

procedure TGameMenuScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited CloseScreen(aNextScreen);
end;

procedure TGameMenuScreen.DoMassReplayCheck;
var
  OpenDlg: TOpenDialog;
begin
  if MessageDlg('Mass replay checking can take a very long time. Proceed?', mtcustom, [mbYes, mbNo], 0) = mrNo then Exit;
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';
    OpenDlg.InitialDir := AppPath + 'Replay\' + ChangeFileExt(ExtractFileName(GameFile), '');
    OpenDlg.Filter := 'NeoLemmix Replay (*.nxrp, *.lrb)|*.nxrp;*.lrb';
    OpenDlg.Options := [ofHideReadOnly, ofFileMustExist];
    if not OpenDlg.Execute then
      Exit;
    GameParams.ReplayCheckPath := ExtractFilePath(OpenDlg.FileName);
  finally
    OpenDlg.Free;
  end;
  CloseScreen(gstReplayTest);
end;

procedure TGameMenuScreen.ShowSetupMenu;
var
  F: TFNLSetup;
begin
  F := TFNLSetup.Create(self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TGameMenuScreen.DoLevelSelect;
var
  F: TFLevelSelect;
  OldLevel: TNeoLevelEntry;
  Success: Boolean;
begin
  OldLevel := GameParams.CurrentLevel;
  F := TFLevelSelect.Create(self);
  try
    Success := F.ShowModal = mrOk;
  finally
    F.Free;
  end;

  if not Success then
    GameParams.SetLevel(OldLevel)
  else
    CloseScreen(gstPreview);
end;

end.

