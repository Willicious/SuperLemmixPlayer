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
  GameBaseScreenCommon,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  Generics.Collections,
  Math, Forms, Controls, Dialogs, Classes, SysUtils;

const
  INTERNAL_SCREEN_WIDTH = 864;
  INTERNAL_SCREEN_HEIGHT = 486;

type
  TRegionState = (rsNormal, rsHover, rsClick);

  TClickableRegion = class
    private
      fBitmaps: TBitmap32;
      fBounds: TRect;
      fClickArea: TRect;
      fShortcutKeys: TList<Word>;

      function GetSrcRect(aState: TRegionState): TRect;
    public
      constructor Create(aCenter: TPoint; aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil); overload;
      constructor Create(aCenter: TPoint; aClickRect: TRect; aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil); overload;
      destructor Destroy; override;

      property Bounds: TRect read fBounds;
      property ClickArea: TRect read fClickArea;
      property Bitmaps: TBitmap32 read fBitmaps;
      property SrcRect[State: TRegionState]: TRect read GetSrcRect;
      property ShortcutKeys: TList<Word> read fShortcutKeys;
  end;

  TGameBaseMenuScreen = class(TGameBaseScreen)
    private
      fMenuFont          : TMenuFont;

      fBasicCursor: TNLCursor;

      procedure LoadBasicCursor;
      procedure SetBasicCursor;

      procedure InitializeImage;

      procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    protected
      procedure DoLevelSelect(isPlaying: Boolean = false);
      procedure DoMassReplayCheck;

      procedure ShowConfigMenu;
      procedure ApplyConfigChanges(OldFullScreen, OldHighResolution, ResetWindowSize, ResetWindowPos: Boolean);
      procedure DoAfterConfig; virtual;

      procedure DrawBackground; overload;
      procedure DrawBackground(aRegion: TRect); overload;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); virtual;
      procedure OnMouseMove(aPoint: TPoint); virtual;
      procedure OnKeyPress(aKey: Integer); virtual;

      property MenuFont: TMenuFont read fMenuFont;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure MainFormResized; override;
  end;

implementation

uses
  FMain, FNeoLemmixLevelSelect, FNeoLemmixConfig,
  PngInterface,
  GameControl;

{ TGameBaseMenuScreen }

constructor TGameBaseMenuScreen.Create(aOwner: TComponent);
begin
  inherited;

  fMenuFont := TMenuFont.Create;
  fMenuFont.Load;

  fBasicCursor := TNLCursor.Create(Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS);
  LoadBasicCursor;
  SetBasicCursor;

  InitializeImage;

  OnKeyDown := Form_KeyDown;
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;
end;

destructor TGameBaseMenuScreen.Destroy;
begin
  fMenuFont.Free;
  fBasicCursor.Free;

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

procedure TGameBaseMenuScreen.OnKeyPress(aKey: Integer);
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.OnMouseMove(aPoint: TPoint);
begin
  // Intentionally blank.
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
  OnKeyPress(Key);
end;

procedure TGameBaseMenuScreen.Form_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  OnMouseClick(ScreenImg.ControlToBitmap(ScreenImg.ParentToClient(Point(X, Y))), Button);
end;

procedure TGameBaseMenuScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  OnMouseClick(Point(X, Y), Button);
end;

procedure TGameBaseMenuScreen.DoAfterConfig;
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.DoLevelSelect(isPlaying: Boolean = false);
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
    if not isPlaying then GameParams.SetLevel(OldLevel);
  end
  else begin
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


constructor TClickableRegion.Create(aCenter: TPoint; aClickRect: TRect; aNormal, aHover, aClick: TBitmap32);
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
end;

constructor TClickableRegion.Create(aCenter: TPoint; aNormal, aHover,
  aClick: TBitmap32);
begin
  Create(aCenter, aNormal.BoundsRect, aNormal, aHover, aClick);
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
