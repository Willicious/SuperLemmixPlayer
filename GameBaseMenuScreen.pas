unit GameBaseMenuScreen;

interface

uses
  Types, UMisc,
  LemCursor,
  LemMenuFont,
  LemNeoLevelPack,
  LemNeoPieceManager,
  LemStrings,
  LemTypes,
  LemmixHotkeys,
  GameBaseScreenCommon,
  GameControl,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  Generics.Collections,
  Math, Forms, Controls, ExtCtrls, Dialogs, Classes, SysUtils;

const
  INTERNAL_SCREEN_WIDTH = 864;
  INTERNAL_SCREEN_HEIGHT = 486;

  FOOTER_OPTIONS_ONE_ROW_Y = 462;

  FOOTER_ONE_OPTION_X = INTERNAL_SCREEN_WIDTH div 2;

  FOOTER_TWO_OPTIONS_X_LEFT = INTERNAL_SCREEN_WIDTH * 5 div 16;
  FOOTER_TWO_OPTIONS_X_RIGHT = INTERNAL_SCREEN_WIDTH * 11 div 16;

  FOOTER_THREE_OPTIONS_X_LEFT = INTERNAL_SCREEN_WIDTH * 3 div 16;
  FOOTER_THREE_OPTIONS_X_MID = INTERNAL_SCREEN_WIDTH div 2;
  FOOTER_THREE_OPTIONS_X_RIGHT = INTERNAL_SCREEN_WIDTH * 13 div 16;

type
  TRegionState = (rsNormal, rsHover, rsClick);
  TRegionAction = procedure of object;

  TClickableRegion = class
    private
      fBitmaps: TBitmap32;
      fBounds: TRect;
      fClickArea: TRect;
      fShortcutKeys: TList<Word>;

      fAction: TRegionAction;

      fCurrentState: TRegionState;
      fResetTimer: TTimer;

      function GetSrcRect(aState: TRegionState): TRect;
    public
      constructor Create(aAction: TRegionAction; aFunc: TLemmixHotkeyAction); overload;
      constructor Create(aAction: TRegionAction; aKey: Word); overload;
      constructor Create(aCenter: TPoint; aClickRect: TRect; aAction: TRegionAction; aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil); overload;
      destructor Destroy; override;

      procedure AddKeysFromFunction(aFunc: TLemmixHotkeyAction);

      property Bounds: TRect read fBounds;
      property ClickArea: TRect read fClickArea;
      property Bitmaps: TBitmap32 read fBitmaps;
      property SrcRect[State: TRegionState]: TRect read GetSrcRect;
      property ShortcutKeys: TList<Word> read fShortcutKeys;

      property Action: TRegionAction read fAction;
      property CurrentState: TRegionState read fCurrentState write fCurrentState;
      property ResetTimer: TTimer read fResetTimer write fResetTimer;
  end;

  TGameBaseMenuScreen = class(TGameBaseScreen)
    private
      fMenuFont          : TMenuFont;

      fBasicCursor: TNLCursor;

      fClickableRegions: TObjectList<TClickableRegion>;

      procedure LoadBasicCursor;
      procedure SetBasicCursor;

      procedure InitializeImage;

      procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
      procedure Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);

      procedure HandleKeyboardInput(Key: Word);
      procedure HandleMouseMove;
      procedure HandleMouseClick(Button: TMouseButton);

      procedure OnClickTimer(Sender: TObject);
    protected
      procedure DoLevelSelect;
      procedure DoMassReplayCheck;
      procedure SaveReplay;

      procedure ShowConfigMenu;
      procedure ApplyConfigChanges(OldFullScreen, OldHighResolution, ResetWindowSize, ResetWindowPos: Boolean);
      procedure DoAfterConfig; virtual;

      procedure DrawBackground; overload;
      procedure DrawBackground(aRegion: TRect); overload;

      function MakeClickableImage(aImageCenter: TPoint; aImageClickRect: TRect; aAction: TRegionAction;
                                   aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil): TClickableRegion;
      function MakeClickableText(aTextCenter: TPoint; aText: String; aAction: TRegionAction): TClickableRegion;

      function MakeHiddenOption(aKey: Word; aAction: TRegionAction): TClickableRegion; overload;
      function MakeHiddenOption(aFunc: TLemmixHotkeyAction; aAction: TRegionAction): TClickableRegion; overload;

      function GetInternalMouseCoordinates: TPoint;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); virtual;
      procedure OnMouseMoved(aPoint: TPoint); virtual;
      procedure OnKeyPress(var aKey: Word); virtual;

      property MenuFont: TMenuFont read fMenuFont;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure MainFormResized; override;
  end;

implementation

uses
  LemGame,
  FMain, FNeoLemmixLevelSelect, FNeoLemmixConfig,
  PngInterface;

{ TGameBaseMenuScreen }

constructor TGameBaseMenuScreen.Create(aOwner: TComponent);
begin
  inherited;

  fClickableRegions := TObjectList<TClickableRegion>.Create;

  fMenuFont := TMenuFont.Create;
  fMenuFont.Load;

  fBasicCursor := TNLCursor.Create(Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS);
  LoadBasicCursor;
  SetBasicCursor;

  InitializeImage;

  OnKeyDown := Form_KeyDown;
  OnMouseDown := Form_MouseDown;
  OnMouseMove := Form_MouseMove;
  ScreenImg.OnMouseDown := Img_MouseDown;
  ScreenImg.OnMouseMove := Img_MouseMove;
end;

destructor TGameBaseMenuScreen.Destroy;
begin
  fMenuFont.Free;
  fBasicCursor.Free;
  fClickableRegions.Free;

  inherited;
end;

procedure TGameBaseMenuScreen.LoadBasicCursor;
var
  BMP: TBitmap32;
  i: Integer;
begin
  BMP := TBitmap32.Create;
  try
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(AppPath + 'gfx/cursor-hr/standard.png', BMP)
    else
      TPngInterface.LoadPngFile(AppPath + 'gfx/cursor/standard.png', BMP);

    fBasicCursor.LoadFromBitmap(BMP);

    for i := 1 to fBasicCursor.MaxZoom+1 do
      Screen.Cursors[i] := fBasicCursor.GetCursor(i);
  finally
    BMP.Free;
  end;
end;

procedure TGameBaseMenuScreen.InitializeImage;
begin
  with ScreenImg do
  begin
    Bitmap.SetSize(INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);
    DrawBackground;

    BoundsRect := Rect(0, 0, ClientWidth, ClientHeight);

    ScreenImg.Align := alClient;
    ScreenImg.ScaleMode := smResize;
    ScreenImg.BitmapAlign := baCenter;

    if GameParams.LinearResampleMenu then
      TLinearResampler.Create(ScreenImg.Bitmap);
  end;
end;

procedure TGameBaseMenuScreen.MainFormResized;
begin
  ScreenImg.Width := GameParams.MainForm.ClientWidth;
  ScreenImg.Height := GameParams.MainForm.ClientHeight;
  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;

  SetBasicCursor;
end;

function TGameBaseMenuScreen.MakeClickableImage(aImageCenter: TPoint;
  aImageClickRect: TRect; aAction: TRegionAction; aNormal, aHover,
  aClick: TBitmap32): TClickableRegion;
var
  tmpNormal, tmpHover, tmpClick: TBitmap32;
  ScreenRect: TRect;
begin
  if aHover = nil then aHover := aNormal;
  if aClick = nil then aClick := aHover;

  tmpNormal := TBitmap32.Create;
  tmpHover := TBitmap32.Create;
  tmpClick := TBitmap32.Create;
  try
    tmpNormal.SetSize(aNormal.Width, aNormal.Height);
    tmpNormal.Clear(0);

    ScreenRect := SizedRect(aImageCenter.X - aNormal.Width div 2, aImageCenter.Y - aNormal.Height div 2, aNormal.Width, aNormal.Height);
    ScreenImg.Bitmap.DrawTo(tmpNormal, 0, 0, ScreenRect);

    tmpHover.Assign(tmpNormal);
    tmpClick.Assign(tmpNormal);

    aNormal.DrawTo(tmpNormal, 0, 0);
    aHover.DrawTo(tmpHover, 0, 0);
    aClick.DrawTo(tmpClick, 0, 0);

    Result := TClickableRegion.Create(aImageCenter, aImageClickRect, aAction, tmpNormal, tmpHover, tmpClick);
    fClickableRegions.Add(Result);

    if Types.PtInRect(Result.ClickArea, GetInternalMouseCoordinates) then
    begin
      Result.CurrentState := rsHover;
      Result.Bitmaps.DrawTo(ScreenImg.Bitmap, Result.Bounds, Result.GetSrcRect(rsHover));
    end else begin
      Result.CurrentState := rsNormal;
      Result.Bitmaps.DrawTo(ScreenImg.Bitmap, Result.Bounds, Result.GetSrcRect(rsNormal));
    end;
  finally
    tmpNormal.Free;
    tmpHover.Free;
    tmpClick.Free;
  end;
end;

function TGameBaseMenuScreen.MakeClickableText(aTextCenter: TPoint;
  aText: String; aAction: TRegionAction): TClickableRegion;
const
  HUE_SHIFT_NORMAL = -0.125;
  HUE_SHIFT_HOVER = -0.250;
  HUE_SHIFT_CLICK = -0.375;
var
  tmpNormal, tmpHover, tmpClick: TBitmap32;
  ScreenRect: TRect;
  x, y: Integer;

  NormalShift, HoverShift, ClickShift: TColorDiff;
begin
  FillChar(NormalShift, SizeOf(TColorDiff), 0);
  FillChar(HoverShift, SizeOf(TColorDiff), 0);
  FillChar(ClickShift, SizeOf(TColorDiff), 0);

  NormalShift.HShift := HUE_SHIFT_NORMAL;
  HoverShift.HShift := HUE_SHIFT_HOVER;
  ClickShift.HShift := HUE_SHIFT_CLICK;

  tmpNormal := TBitmap32.Create;
  tmpHover := TBitmap32.Create;
  tmpClick := TBitmap32.Create;
  try
    ScreenRect := MenuFont.GetTextSize(aText);
    Types.OffsetRect(ScreenRect, aTextCenter.X - ScreenRect.Width div 2, aTextCenter.Y - ScreenRect.Height div 2);

    tmpNormal.SetSize(ScreenRect.Width, ScreenRect.Height);
    MenuFont.DrawText(tmpNormal, aText, 0, 0);

    tmpHover.Assign(tmpNormal);
    tmpClick.Assign(tmpNormal);

    for y := 0 to tmpNormal.Height-1 do
      for x := 0 to tmpNormal.Width-1 do
      begin
        tmpNormal[x, y] := ApplyColorShift(tmpNormal[x, y], NormalShift);
        tmpHover[x, y] := ApplyColorShift(tmpHover[x, y], HoverShift);
        tmpClick[x, y] := ApplyColorShift(tmpClick[x, y], ClickShift);
      end;

    tmpNormal.DrawMode := dmBlend;
    tmpHover.DrawMode := dmBlend;
    tmpClick.DrawMode := dmBlend;

    Result := MakeClickableImage(aTextCenter, tmpNormal.BoundsRect, aAction, tmpNormal, tmpHover, tmpClick);
  finally
    tmpNormal.Free;
    tmpHover.Free;
    tmpClick.Free;
  end;
end;

function TGameBaseMenuScreen.MakeHiddenOption(aFunc: TLemmixHotkeyAction;
  aAction: TRegionAction): TClickableRegion;
begin
  Result := TClickableRegion.Create(aAction, aFunc);
  fClickableRegions.Add(Result);
end;

function TGameBaseMenuScreen.MakeHiddenOption(aKey: Word;
  aAction: TRegionAction): TClickableRegion;
begin
  Result := TClickableRegion.Create(aAction, aKey);
  fClickableRegions.Add(Result);
end;

procedure TGameBaseMenuScreen.OnClickTimer(Sender: TObject);
var
  Region: TClickableRegion;
  P: TPoint;
begin
  Region := fClickableRegions[TComponent(Sender).Tag];
  P := GetInternalMouseCoordinates;

  if Types.PtInRect(Region.ClickArea, P) then
    Region.CurrentState := rsHover
  else
    Region.CurrentState := rsNormal;

  Region.ResetTimer := nil;
  Sender.Free;
end;

procedure TGameBaseMenuScreen.HandleKeyboardInput(Key: Word);
var
  i, n: Integer;
  NewTimer: TTimer;
begin
  for i := 0 to fClickableRegions.Count-1 do
    for n := 0 to fClickableRegions[i].ShortcutKeys.Count-1 do
      if Key = fClickableRegions[i].ShortcutKeys[n] then
      begin
        if fClickableRegions[i].Bitmaps <> nil then
        begin
          if fClickableRegions[i].ResetTimer = nil then
          begin
            NewTimer := TTimer.Create(self);
            NewTimer.Interval := 100;
            NewTimer.Tag := i;
            NewTimer.OnTimer := OnClickTimer;
            fClickableRegions[i].ResetTimer := NewTimer;
          end else begin
            fClickableRegions[i].ResetTimer.Enabled := false;
            fClickableRegions[i].ResetTimer.Enabled := true;
          end;

          fClickableRegions[i].CurrentState := rsClick;
          fClickableRegions[i].Bitmaps.DrawTo(ScreenImg.Bitmap, fClickableRegions[i].Bounds, fClickableRegions[i].SrcRect[rsClick]);
        end;

        fClickableRegions[i].Action;

        Key := 0;
        Exit;
      end;

  OnKeyPress(Key);
end;

procedure TGameBaseMenuScreen.HandleMouseMove;
var
  i: Integer;

  P: TPoint;
begin
  P := GetInternalMouseCoordinates;

  for i := 0 to fClickableRegions.Count-1 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) and (fClickableRegions[i].CurrentState = rsNormal) then
      begin
        fClickableRegions[i].CurrentState := rsHover;
        fClickableRegions[i].Bitmaps.DrawTo(ScreenImg.Bitmap, fClickableRegions[i].Bounds, fClickableRegions[i].SrcRect[rsHover]);

        ScreenImg.Bitmap.Changed;
      end else if (not Types.PtInRect(fClickableRegions[i].ClickArea, P)) and (fClickableRegions[i].CurrentState = rsHover) then
      begin
        fClickableRegions[i].CurrentState := rsNormal;
        fClickableRegions[i].Bitmaps.DrawTo(ScreenImg.Bitmap, fClickableRegions[i].Bounds, fClickableRegions[i].SrcRect[rsNormal]);

        ScreenImg.Bitmap.Changed;
      end;

  OnMouseMoved(P); // This one we want to always call.
end;

procedure TGameBaseMenuScreen.HandleMouseClick(Button: TMouseButton);
var
  i: Integer;
  NewTimer: TTimer;

  P: TPoint;
begin
  P := GetInternalMouseCoordinates;

  for i := 0 to fClickableRegions.Count-1 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) then
      begin
        if fClickableRegions[i].ResetTimer = nil then
        begin
          NewTimer := TTimer.Create(self);
          NewTimer.Interval := 100;
          NewTimer.Tag := i;
          NewTimer.OnTimer := OnClickTimer;
          fClickableRegions[i].ResetTimer := NewTimer;
        end else begin
          fClickableRegions[i].ResetTimer.Enabled := false;
          fClickableRegions[i].ResetTimer.Enabled := true;
        end;

        fClickableRegions[i].CurrentState := rsClick;
        fClickableRegions[i].Bitmaps.DrawTo(ScreenImg.Bitmap, fClickableRegions[i].Bounds, fClickableRegions[i].SrcRect[rsClick]);

        ScreenImg.Bitmap.Changed;

        fClickableRegions[i].Action;
        Exit;
      end;

  OnMouseClick(P, Button); // Only occurs if the above code didn't catch the click.
end;

procedure TGameBaseMenuScreen.OnKeyPress(var aKey: Word);
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.OnMouseMoved(aPoint: TPoint);
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.SaveReplay;
var
  S: String;
begin
  S := GlobalGame.ReplayManager.GetSaveFileName(self, GlobalGame.Level);
  if S = '' then Exit;
  GlobalGame.EnsureCorrectReplayDetails;
  GlobalGame.ReplayManager.SaveToFile(S);
end;

procedure TGameBaseMenuScreen.SetBasicCursor;
var
  CursorIndex: Integer;
begin
  CursorIndex := Max(1, Min(MainForm.Width div 320, MainForm.Height div 180));

  Cursor := CursorIndex;
  MainForm.Cursor := CursorIndex;
  Screen.Cursor := CursorIndex;
  ScreenImg.Cursor := CursorIndex;
end;

procedure TGameBaseMenuScreen.DrawBackground;
begin
  DrawBackground(ScreenImg.Bitmap.BoundsRect);
end;

procedure TGameBaseMenuScreen.DrawBackground(aRegion: TRect);
var
  aX, aY: Integer;
  BgImage, Dst: TBitmap32;
  SrcRect: TRect;
begin
  Dst := ScreenImg.Bitmap;
  BgImage := TBitmap32.Create;

  try
    if (not (GameParams.CurrentLevel = nil)) and FileExists(GameParams.CurrentLevel.Group.FindFile('background.png')) then
      TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('background.png'), BgImage)
    else if FileExists(AppPath + SFGraphicsMenu + 'background.png') then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'background.png', BgImage);

    if (BgImage.Width = 0) or (BgImage.Height = 0) then
    begin
      Dst.FillRect(aRegion.Left, aRegion.Top, aRegion.Right, aRegion.Bottom, $FF000000);
      Exit;
    end;

    aY := aRegion.Top;
    aX := aRegion.Left;
    while aY < aRegion.Bottom do
    begin
      SrcRect.Left := 0;
      SrcRect.Top := 0;
      SrcRect.Bottom := Min(BgImage.Height, aRegion.Bottom - aY);

      while aX < aRegion.Right do
      begin
        SrcRect.Right := Min(BgImage.Width, aRegion.Right - aX);

        BgImage.DrawTo(Dst, aX, aY, SrcRect);
        Inc(aX, BgImage.Width);
      end;
      Inc(aY, BgImage.Height);
      aX := aRegion.Left;
    end;
  finally
    BgImage.Free;
  end;

end;

procedure TGameBaseMenuScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  HandleKeyboardInput(Key);
end;

procedure TGameBaseMenuScreen.Form_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  HandleMouseClick(Button);
end;

procedure TGameBaseMenuScreen.Form_MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  HandleMouseMove;
end;

procedure TGameBaseMenuScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  HandleMouseClick(Button);
end;

procedure TGameBaseMenuScreen.Img_MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer; Layer: TCustomLayer);
begin
  HandleMouseMove;
end;

function TGameBaseMenuScreen.GetInternalMouseCoordinates: TPoint;
begin
  Result := ScreenImg.ControlToBitmap(ScreenImg.ScreenToClient(Mouse.CursorPos));
end;

procedure TGameBaseMenuScreen.DoAfterConfig;
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.DoLevelSelect;
var
  F: TFLevelSelect;
  OldLevel: TNeoLevelEntry;
  Success: Boolean;
  LoadAsPack: Boolean;
begin
  if GameParams.TestModeLevel <> nil then Exit;

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
    GameParams.SetLevel(OldLevel);
  end else begin
    if LoadAsPack then
      CloseScreen(gstMenu)
    else
      CloseScreen(gstPreview);
  end;
end;

procedure TGameBaseMenuScreen.DoMassReplayCheck;
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';
    OpenDlg.InitialDir := AppPath + 'Replay\' + MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name, false);
    OpenDlg.Filter := 'NeoLemmix Replay (*.nxrp)|*.nxrp';
    OpenDlg.Options := [ofHideReadOnly, ofFileMustExist, ofEnableSizing];
    if not OpenDlg.Execute then
      Exit;
    GameParams.ReplayCheckPath := ExtractFilePath(OpenDlg.FileName);
  finally
    OpenDlg.Free;
  end;
  CloseScreen(gstReplayTest);
end;

procedure TGameBaseMenuScreen.ShowConfigMenu;
var
  ConfigDlg: TFormNXConfig;
  OldFullScreen, OldHighResolution, ResetWindowSize, ResetWindowPos: Boolean;
  ConfigResult: TModalResult;
begin
  OldFullScreen := GameParams.FullScreen;
  OldHighResolution := GameParams.HighResolution;

  ConfigDlg := TFormNXConfig.Create(self);
  try
    ConfigDlg.SetGameParams;
    ConfigDlg.NXConfigPages.TabIndex := 0;
    ConfigResult := ConfigDlg.ShowModal;
    ResetWindowSize := ConfigDlg.ResetWindowSize;
    ResetWindowPos := ConfigDlg.ResetWindowPosition;
  finally
    ConfigDlg.Free;
  end;

  // Wise advice from Simon - save these things on exiting the
  // config dialog, rather than waiting for a quit or a screen
  // transition to save them.
  GameParams.Save;

  ApplyConfigChanges(OldFullScreen, OldHighResolution, ResetWindowSize, ResetWindowPos);

  // Apply Mass replay check, if the result was a mrRetry (which we abuse for our purpose here)
  if ConfigResult = mrRetry then
    DoMassReplayCheck
  else
    DoAfterConfig;
end;

procedure TGameBaseMenuScreen.ApplyConfigChanges(OldFullScreen, OldHighResolution, ResetWindowSize, ResetWindowPos: Boolean);
begin
  if GameParams.FullScreen and not OldFullScreen then
  begin
    GameParams.MainForm.BorderStyle := bsNone;
    GameParams.MainForm.WindowState := wsMaximized;
    GameParams.MainForm.Left := 0;
    GameParams.MainForm.Top := 0;
    GameParams.MainForm.Width := Screen.Width;
    GameParams.MainForm.Height := Screen.Height;
  end else if not GameParams.FullScreen then
  begin
    GameParams.MainForm.BorderStyle := bsSizeable;
    GameParams.MainForm.WindowState := wsNormal;

    if ResetWindowSize then TMainForm(GameParams.MainForm).RestoreDefaultSize;
    if ResetWindowPos then TMainForm(GameParams.MainForm).RestoreDefaultPosition;
  end;


  if GameParams.HighResolution <> OldHighResolution then
    PieceManager.Clear;

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

{ TClickableRegion }


procedure TClickableRegion.AddKeysFromFunction(aFunc: TLemmixHotkeyAction);
var
  n: Word;
begin
  for n := 0 to MAX_KEY do
    if GameParams.Hotkeys.CheckKeyEffect(n).Action = aFunc then
      fShortcutKeys.Add(n);
end;

constructor TClickableRegion.Create(aCenter: TPoint; aClickRect: TRect; aAction: TRegionAction; aNormal, aHover, aClick: TBitmap32);
begin
  inherited Create;

  fShortcutKeys := TList<Word>.Create;

  fBitmaps := TBitmap32.Create(aNormal.Width * 3, aNormal.Height);

  fBounds := SizedRect(aCenter.X - aNormal.Width div 2, aCenter.Y - aNormal.Height div 2, aNormal.Width, aNormal.Height);
  fClickArea := SizedRect(fBounds.Left + aClickRect.Left, fBounds.Top + aClickRect.Top, aClickRect.Width, aClickRect.Height);

  if aHover = nil then aHover := aNormal;
  if aClick = nil then aClick := aHover;

  aNormal.DrawTo(fBitmaps, 0, 0);
  aHover.DrawTo(fBitmaps, aNormal.Width, 0);
  aClick.DrawTo(fBitmaps, aNormal.Width * 2, 0);

  fAction := aAction;
end;

constructor TClickableRegion.Create(aAction: TRegionAction;
  aFunc: TLemmixHotkeyAction);
begin
  inherited Create;

  fShortcutKeys := TList<Word>.Create;
  fAction := aAction;

  AddKeysFromFunction(aFunc);
end;

constructor TClickableRegion.Create(aAction: TRegionAction; aKey: Word);
begin
  inherited Create;

  fShortcutKeys := TList<Word>.Create;
  fAction := aAction;

  fShortcutKeys.Add(aKey);
end;

destructor TClickableRegion.Destroy;
begin
  fBitmaps.Free;
  fShortcutKeys.Free;
  inherited;
end;

function TClickableRegion.GetSrcRect(aState: TRegionState): TRect;
begin
  Result := Rect(0, 0, fBitmaps.Width div 3, fBitmaps.Height);

  case aState of
    rsHover: Types.OffsetRect(Result, fBitmaps.Width div 3, 0);
    rsClick: Types.OffsetRect(Result, fBitmaps.Width div 3 * 2, 0);
  end;
end;

end.
