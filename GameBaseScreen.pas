{$include lem_directives.inc}
unit GameBaseScreen;

interface

uses
  System.Types,
  Windows, Messages, Classes, Controls, Graphics, MMSystem, Forms, Dialogs, Math,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  FBaseDosForm,
  GameControl,
  LemDosStructures,
  LemSystemMessages,
  LemStrings, PngInterface, LemTypes,
  LemReplay, LemGame,
  SysUtils;

const
  PURPLEFONTCOUNT = ord(#132) - ord('!') + 1;
  PurpleFontCharSet = [#26..#126] - [#32];

type
  TPurpleFont = class(TComponent)
  private
    function GetBitmapOfChar(Ch: Char): TBitmap32;
    procedure Combine(F: TColor32; var B: TColor32; M: TColor32);
  protected
  public
    fBitmaps: array[0..PURPLEFONTCOUNT - 1] of TBitmap32;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property BitmapOfChar[Ch: Char]: TBitmap32 read GetBitmapOfChar;
  published
  end;

type
  {-------------------------------------------------------------------------------
    This is the ancestor for all dos forms that are used in the program.
  -------------------------------------------------------------------------------}
  TGameBaseScreen = class(TBaseDosForm)
  private
    fScreenImg           : TImage32;
    fBackGround          : TBitmap32;
    fBackBuffer          : TBitmap32; // general purpose buffer
    fPurpleFont          : TPurpleFont;
    fOriginalImageBounds : TRect;
    fScreenIsClosing     : Boolean;
    fCloseDelay          : Integer;
    procedure AdjustImage;
    procedure MakeList(const S: string; aList: TStrings);
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure PrepareGameParams; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property PurpleFont: TPurpleFont read fPurpleFont;
    property ScreenIsClosing: Boolean read fScreenIsClosing;
    property CloseDelay: Integer read fCloseDelay write fCloseDelay;
    procedure DoLevelSelect(isPlaying: Boolean = false);
    procedure ShowConfigMenu;
    procedure ApplyConfigChanges(OldFullScreen: Boolean);
    procedure DoMassReplayCheck;
    function LoadReplay: Boolean;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
    procedure ExtractBackGround;
    procedure ExtractPurpleFont;
    procedure DrawPurpleText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
    procedure DrawPurpleTextCentered(Dst: TBitmap32; const S: string;
      Y: Integer; aRestoreBuffer: TBitmap32 = nil; EraseOnly: Boolean = False);
    function CalcPurpleTextSize(const S: string): TRect;
    procedure FadeOut;
    procedure InitializeImageSizeAndPosition(aWidth, aHeight: Integer);

    procedure MainFormResized; virtual;

    property ScreenImg: TImage32 read fScreenImg;
    property BackGround: TBitmap32 read fBackGround;
    property BackBuffer: TBitmap32 read fBackBuffer;
  end;

implementation

uses
  FNeoLemmixConfig, LemNeoLevelPack, FNeoLemmixLevelSelect, UITypes;

{ TPurpleFont }

procedure TPurpleFont.Combine(F: TColor32; var B: TColor32; M: TColor32);
// just show transparent
begin
  if F <> 0 then B := F;
end;

constructor TPurpleFont.Create(aOwner: TComponent);
var
  i: Integer;
{-------------------------------------------------------------------------------
  The purple font has it's own internal pixelcombine.
  I don't think this ever has to be different.
-------------------------------------------------------------------------------}
begin
  inherited;
  for i := 0 to PURPLEFONTCOUNT - 1 do
  begin
    fBitmaps[i] := TBitmap32.Create;
    fBitmaps[i].OnPixelCombine := Combine;
    fBitmaps[i].DrawMode := dmCustom;
  end;
end;

destructor TPurpleFont.Destroy;
var
  i: Integer;
begin
  for i := 0 to PURPLEFONTCOUNT - 1 do
    fBitmaps[i].Free;
  inherited;
end;

function TPurpleFont.GetBitmapOfChar(Ch: Char): TBitmap32;
var
  Idx: Integer;
  ACh: AnsiChar;
begin
  ACh := AnsiChar(Ch);
  // Ignore any character not supported by the purple font
  //Assert((ACh in [#26..#126]) and (ACh <> ' '), 'Assertion failure on GetBitmapOfChar, character 0x' + IntToHex(Ord(ACh), 2));
  if (not (ACh in [#26..#126])) and (ACh <> ' ') then
    Idx := 0
  else if Ord(ACh) > 32 then
    Idx := Ord(ACh) - 33
  else
    Idx := 94 + Ord(ACh) - 26;
  Result := fBitmaps[Idx];
end;

{ TGameBaseScreen }

procedure TGameBaseScreen.CNKeyDown(var Message: TWMKeyDown);
var
  AssignedEventHandler: TKeyEvent;
begin
  AssignedEventHandler := OnKeyDown;
  if Message.CharCode = vk_tab then
    if Assigned(AssignedEventHandler) then
      OnKeyDown(Self, Message.CharCode, KeyDataToShiftState(Message.KeyData));
  inherited;
end;

procedure TGameBaseScreen.AdjustImage;
begin
  fScreenImg.Align := alClient;
  fScreenImg.ScaleMode := smResize;
  fScreenImg.BitmapAlign := baCenter;

  Update;
  Changed;
end;

procedure TGameBaseScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  Self.OnKeyDown := nil;
  Self.OnKeyPress := nil;
  Self.OnClick := nil;
  Self.OnMouseDown := nil;
  Self.OnMouseMove := nil;
  ScreenImg.OnMouseDown := nil;
  ScreenImg.OnMouseMove := nil;
  Application.OnIdle := nil;
  fScreenIsClosing := True;
  if fCloseDelay > 0 then
  begin
    Update;
    Sleep(fCloseDelay);
  end;

  FadeOut;

  if GameParams <> nil then
  begin
    GameParams.NextScreen := aNextScreen;
    GameParams.MainForm.Cursor := crNone;
  end;

  Close;

  SendMessage(MainFormHandle, LM_NEXT, 0, 0);
end;

constructor TGameBaseScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fScreenImg := TImage32.Create(Self);
  fScreenImg.Parent := Self;

  fPurpleFont := TPurpleFont.Create(nil);

  fBackGround := TBitmap32.Create;
  fBackBuffer := TBitmap32.Create;

  ScreenImg.Cursor := crNone;
end;

destructor TGameBaseScreen.Destroy;
begin
  fBackGround.Free;
  fPurpleFont.Free;
  fBackBuffer.Free;
  inherited Destroy;
end;

function TGameBaseScreen.CalcPurpleTextSize(const S: string): TRect;
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  C: Char;
  CX, i: Integer;
begin
  CX := 0;
  FillChar(Result, SizeOf(Result), 0);
  if S <> '' then
    Result.Bottom := 16;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    case C of
      #12:
        begin
          Inc(Result.Bottom, 8);
          CX := 0;
        end;
      #13:
        begin
          Inc(Result.Bottom, 16);
          CX := 0;
        end;
      #26..#126:
        begin
          Inc(CX, 16);
          if CX > Result.Right then
            Result.Right := CX;
        end;
    end;
  end;
end;

procedure TGameBaseScreen.DrawPurpleText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  C: Char;
  CX, CY, i: Integer;
  R: TRect;
begin
  Y := Y + 1; // accounts for moving graphic up by 1 pixel

  if aRestoreBuffer <> nil then
  begin
    R := CalcPurpleTextSize(S);
    OffsetRect(R, X, Y);
    IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
    aRestoreBuffer.DrawTo(Dst, R, R);
  end;

  CX := X;
  CY := Y;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    case C of
      #12:
        begin
          Inc(CY, 8);
          CX := X;
        end;
      #13:
        begin
          Inc(CY, 16);
          CX := X;
        end;
      ' ':
        begin
          Inc(CX, 16);
        end;
      #26..#31, #33..#132:
        begin
          fPurpleFont.BitmapOfChar[C].DrawTo(Dst, CX, CY);
          Inc(CX, 16);
        end;
    end;
  end;

end;

procedure TGameBaseScreen.DrawPurpleTextCentered(Dst: TBitmap32; const S: string; Y: Integer; aRestoreBuffer: TBitmap32 = nil;
  EraseOnly: Boolean = False);
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  X, i: Integer;
  R: TRect;
  List: TStringList;
  H: string;
begin
  List := TStringList.Create;
  MakeList(S, List);

  if aRestoreBuffer <> nil then
  begin
    R := CalcPurpleTextSize(S);
    OffsetRect(R, (Dst.Width - (R.Right - R.Left)) div 2, Y);
    IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
    aRestoreBuffer.DrawTo(Dst, R, R);
  end;

  if not EraseOnly then
    for i := 0 to List.Count - 1 do
    begin
      H := List[i]; // <= 40 characters!!!
      X := (Dst.Width - 16 * Length(H)) div 2;
      if (H <> #13) and (H <> #12) then
        DrawPurpleText(Dst, H, X, Y)
      else if H = #13 then
        Inc(Y, 16)
      else
        Inc(Y, 8);
    end;

  List.Free;
end;

procedure TGameBaseScreen.ExtractBackground;
begin
  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('background.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('background.png'), fBackground)
  else if FileExists(AppPath + SFGraphicsMenu + 'background.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'background.png', fBackground);
end;

procedure TGameBaseScreen.ExtractPurpleFont;
var
  i: Integer;
  TempBMP: TBitmap32;
  buttonSelected: Integer;
begin
  TempBMP := TBitmap32.Create;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('menu_font.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('menu_font.png'), TempBMP)
  else if FileExists(AppPath + SFGraphicsMenu + 'menu_font.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'menu_font.png', TempBMP)
  else
  begin
    buttonSelected := MessageDlg('Could not find the menu font gfx\menu\menu_font.png. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  for i := 0 to PURPLEFONTCOUNT-7 do
  begin
    fPurpleFont.fBitmaps[i].SetSize(16, 16);
    fPurpleFont.fBitmaps[i].Clear(0);
    TempBMP.DrawTo(fPurpleFont.fBitmaps[i], 0, 0, Rect(i*16, 0, (i+1)*16, 16));
    fPurpleFont.fBitmaps[i].DrawMode := dmBlend;
    fPurpleFont.fBitmaps[i].CombineMode := cmMerge;
  end;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('talismans.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('talismans.png'), TempBMP)
  else if FileExists(AppPath + SFGraphicsMenu + 'talismans.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'talismans.png', TempBMP)
  else
  begin
    buttonSelected := MessageDlg('Could not find the talisman graphics gfx\menu\talismans.png. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  for i := 0 to 5 do
  begin
    fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].SetSize(48, 48);
    fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].Clear(0);
    TempBMP.DrawTo(fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i], 0, 0, Rect(48 * (i mod 2), 48 * (i div 2), 48 * ((i mod 2) + 1), 48 * ((i div 2) + 1)));
    fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].DrawMode := dmBlend;
    fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].CombineMode := cmMerge;
  end;

  TempBMP.Free;
end;

procedure TGameBaseScreen.InitializeImageSizeAndPosition(aWidth, aHeight: Integer);
begin
  with fScreenImg do
  begin
    Bitmap.SetSize(aWidth, aHeight);

    with fOriginalImageBounds do
    begin
      Left := 0;
      Height := 0;
      Right := ClientWidth;
      Bottom := ClientHeight;
    end;

    BoundsRect := fOriginalImageBounds;

    AdjustImage;

    if GameParams.LinearResampleMenu and not IsGameplayScreen then
      TLinearResampler.Create(fScreenImg.Bitmap);
  end;
end;

procedure TGameBaseScreen.PrepareGameParams;
begin
  inherited;
end;

procedure TGameBaseScreen.TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
var
  aX, aY: Integer;
begin
  if Dst = nil then Dst := fScreenImg.Bitmap;
  if (fBackground.Width = 0) or (fBackground.Height = 0) then Exit;

  aY := Y;
  aX := X;
  while aY <= Dst.Height do
  begin
    while aX <= Dst.Width do
    begin
      fBackground.DrawTo(Dst, aX, aY);
      Inc(aX, fBackground.Width);
    end;
    Inc(aY, fBackground.Height);
    aX := X;
  end;

end;


procedure TGameBaseScreen.MakeList(const S: string; aList: TStrings);
var
  StartP, P: PChar;
  NewS: string;
begin
  StartP := PChar(S);
  P := StartP;
  repeat
    case P^ of
    #12, #13 :
      begin
        if P >= StartP then
        begin
          SetString(NewS, StartP, P - StartP);
          aList.Add(NewS);

          while (P^ = #12) or (P^ = #13) do
          begin
            aList.Add(P^);
            Inc(P);
          end;
          if P^ = #0 then Break;

          StartP := P;
        end;

      end;

    #0:
      begin
        if P >= StartP then
        begin
          SetString(NewS, StartP, P - StartP);
          aList.Add(NewS);
          Break;
        end;
      end;

    end;

    Inc(P);
    if P = #0 then Break;

  until False;
end;

procedure TGameBaseScreen.FadeOut;
var
  Steps: Cardinal;
  i: Integer;
  P: PColor32;
  StartTickCount: Cardinal;
  IterationDiff: Integer;
  RGBDiff: Integer;
const
  TOTAL_STEPS = 32;
  STEP_DELAY = 6;
begin
  Steps := 0;
  StartTickCount := GetTickCount;
  while Steps < TOTAL_STEPS do
  begin
    IterationDiff := ((GetTickCount - StartTickCount) div STEP_DELAY) - Steps;

    if IterationDiff = 0 then
      Continue;

    RGBDiff := IterationDiff * 8;

    with ScreenImg.Bitmap do
    begin
      P := PixelPtr[0, 0];
      for i := 0 to Width * Height - 1 do
      begin
        with TColor32Entry(P^) do
        begin
          if R > RGBDiff then Dec(R, RGBDiff) else R := 0;
          if G > RGBDiff then Dec(G, RGBDiff) else G := 0;
          if B > RGBDiff then Dec(B, RGBDiff) else B := 0;
        end;
        Inc(P);
      end;
    end;
    Inc(Steps, IterationDiff);

    ScreenImg.Bitmap.Changed;
    Changed;
    Update;
  end;

  Application.ProcessMessages;
end;

procedure TGameBaseScreen.MainFormResized;
begin
  // basic procedure. Special handling needed for in-game screen, hence why this procedure can be overridden.
  fScreenImg.Width := GameParams.MainForm.ClientWidth;
  fScreenImg.Height := GameParams.MainForm.ClientHeight;
  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;
end;

procedure TGameBaseScreen.DoLevelSelect(isPlaying: Boolean = false);
var
  F: TFLevelSelect;
  OldLevel: TNeoLevelEntry;
  Success: Boolean;
  LoadAsPack: Boolean;
begin
  OldLevel := GameParams.CurrentLevel;
  F := TFLevelSelect.Create(self);
  try
    Success := F.ShowModal = mrOk;
    LoadAsPack := F.LoadAsPack;
  finally
    F.Free;
  end;

  if not Success then
  begin
    if not isPlaying then GameParams.SetLevel(OldLevel);
  end
  else begin
    if LoadAsPack then
      CloseScreen(gstMenu)
    else
      CloseScreen(gstPreview);
  end;
end;

procedure TGameBaseScreen.DoMassReplayCheck;
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';
    OpenDlg.InitialDir := AppPath + 'Replay\' + MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name, false);
    OpenDlg.Filter := 'NeoLemmix Replay (*.nxrp, *.lrb)|*.nxrp;*.lrb';
    OpenDlg.Options := [ofHideReadOnly, ofFileMustExist, ofEnableSizing];
    if not OpenDlg.Execute then
      Exit;
    GameParams.ReplayCheckPath := ExtractFilePath(OpenDlg.FileName);
  finally
    OpenDlg.Free;
  end;
  CloseScreen(gstReplayTest);
end;

function TGameBaseScreen.LoadReplay: Boolean;
var
  Dlg: TOpenDialog;
  s: String;

  function GetDefaultLoadPath: String;
    function GetGroupName: String;
    var
      G: TNeoLevelGroup;
    begin
      G := GameParams.CurrentLevel.Group;
      if G.Parent = nil then
        Result := ''
      else begin
        while not (G.IsBasePack or (G.Parent.Parent = nil)) do
          G := G.Parent;
        Result := MakeSafeForFilename(G.Name, false) + '\';
      end;
    end;
  begin
    Result := AppPath + 'Replay\' + GetGroupName;
  end;

  function GetInitialLoadPath: String;
  begin
    if (LastReplayDir <> '') then
      Result := LastReplayDir
    else
      Result := GetDefaultLoadPath;
  end;
begin
  s := '';
  Dlg := TOpenDialog.Create(self);
  try
    Dlg.Title := 'Select a replay file to load (' + GameParams.CurrentGroupName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
    Dlg.Filter := 'All Compatible Replays (*.nxrp, *.lrb)|*.nxrp;*.lrb|NeoLemmix Replay (*.nxrp)|*.nxrp|Old NeoLemmix Replay (*.lrb)|*.lrb';
    Dlg.FilterIndex := 1;
    if LastReplayDir = '' then
    begin
      Dlg.InitialDir := AppPath + 'Replay\' + GetInitialLoadPath;
      if not DirectoryExists(Dlg.InitialDir) then
        Dlg.InitialDir := AppPath + 'Replay\';
      if not DirectoryExists(Dlg.InitialDir) then
        Dlg.InitialDir := AppPath;
    end else
      Dlg.InitialDir := LastReplayDir;
    Dlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    if Dlg.execute then
    begin
      s:=Dlg.filename;
      LastReplayDir := ExtractFilePath(s);
      Result := true;
    end else
      Result := false;
  finally
    Dlg.Free;
  end;

  if s <> '' then
  begin
    GlobalGame.ReplayManager.LoadFromFile(s);
    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level. NeoLemmix' + #13 +
                  'will attempt to play the replay anyway.');
  end;
end;

procedure TGameBaseScreen.ShowConfigMenu;
var
  ConfigDlg: TFormNXConfig;
  OldFullScreen: Boolean;
  ConfigResult: TModalResult;
begin
  OldFullScreen := GameParams.FullScreen;
  ConfigDlg := TFormNXConfig.Create(self);
  ConfigDlg.SetGameParams;
  ConfigDlg.NXConfigPages.TabIndex := 0;
  ConfigResult := ConfigDlg.ShowModal;
  ConfigDlg.Free;

  // Wise advice from Simon - save these things on exiting the
  // config dialog, rather than waiting for a quit or a screen
  // transition to save them.
  GameParams.Save;

  ApplyConfigChanges(OldFullScreen);

  // Apply Mass replay check, if the result was a mrRetry (which we abuse for our purpose here)
  if ConfigResult = mrRetry then DoMassReplayCheck;

end;

procedure TGameBaseScreen.ApplyConfigChanges(OldFullScreen: Boolean);
begin
  if (GameParams.FullScreen <> OldFullScreen) then
  begin
    if GameParams.FullScreen then
    begin
      GameParams.MainForm.BorderStyle := bsNone;
      GameParams.MainForm.WindowState := wsMaximized;
      GameParams.MainForm.Left := 0;
      GameParams.MainForm.Top := 0;
      GameParams.MainForm.Width := Screen.Width;
      GameParams.MainForm.Height := Screen.Height;
    end else begin
      GameParams.MainForm.BorderStyle := bsSizeable;
      GameParams.MainForm.WindowState := wsNormal;
      GameParams.MainForm.ClientWidth := Min(GameParams.ZoomLevel * 320, Min(Screen.WorkAreaWidth div 320, Screen.WorkAreaHeight div 200) * 320);
      GameParams.MainForm.ClientHeight := Min(GameParams.ZoomLevel * 200, Min(Screen.WorkAreaWidth div 320, Screen.WorkAreaHeight div 200) * 200);
      GameParams.MainForm.Left := (Screen.WorkAreaWidth div 2) - (GameParams.MainForm.Width div 2);
      GameParams.MainForm.Top := (Screen.WorkAreaHeight div 2) - (GameParams.MainForm.Height div 2);
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



end.

