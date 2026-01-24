unit GameBaseMenuScreen;

interface

uses
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  Math, Forms, Controls, ExtCtrls, Dialogs, Classes, SysUtils, Windows,
  StrUtils, ShellApi,
  Types, UMisc,
  LemCursor,
  LemMenuFont,
  LemNeoLevelPack,
  LemNeoParser,
  LemNeoPieceManager,
  LemStrings,
  LemTalisman,
  LemTypes,
  LemmixHotkeys,
  FLevelInfo,
  GameBaseScreenCommon,
  GameControl,
  Generics.Collections,
  IOUtils, Vcl.FileCtrl, // For Playback Mode
  SharedGlobals;

var
  // Stores the size of the available window space
  InternalScreenWidth      : Integer;
  InternalScreenHeight     : Integer;

  FooterOptionsOneRowY     : Integer;

  FooterOptionsTwoRowsHighY: Integer;
  FooterOptionsTwoRowsLowY : Integer;

  FooterOneOptionX         : Integer;

  FooterTwoOptionsLeftX    : Integer;
  FooterTwoOptionsRightX   : Integer;

  FooterThreeOptionsLeftX  : Integer;
  FooterThreeOptionsMidX   : Integer;
  FooterThreeOptionsRightX : Integer;

  TalismanPadding          : Integer;

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

      fDrawInFrontWhenHighlit: Boolean;

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

      property DrawInFrontWhenHighlit: Boolean read fDrawInFrontWhenHighlit write fDrawInFrontWhenHighlit;
  end;

  TGameBaseMenuScreen = class(TGameBaseScreen)
    private
      fCalledFromClassicModeButton: Boolean;
      fMenuFont                   : TMenuFont;
      fBasicCursor                : TNLCursor;
      fKeyStates                  : TDictionary<Word, UInt64>;

      fTalRects: TList<TRect>;
      fTalismanImage : TBitmap32;

      procedure LoadBasicCursor(aName: string);
      procedure SetBasicCursor;

      procedure InitializeImage;

      procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure Form_KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
      procedure Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);

      procedure HandleKeyboardInput(Key: Word);
      procedure HandleMouseMove;
      procedure HandleMouseClick(Button: TMouseButton);

      procedure OnClickTimer(Sender: TObject);
    protected
      fClickableRegions: TObjectList<TClickableRegion>;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;

      procedure DoLevelSelect;
      procedure SaveReplay;
      procedure CancelPlaybackMode;

      procedure ShowConfigMenu;
      procedure ApplyConfigChanges(OldAmigaTheme, OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean);
      procedure DoAfterConfig; virtual;

      function GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = False; aFromPackOnly: Boolean = False): Boolean;

      procedure DrawWallpaper; overload;
      procedure DrawWallpaper(aRegion: TRect); overload;
      function GetWallpaperDrawMode: String;

      function MakeClickableImage(aImageCenter: TPoint; aImageClickRect: TRect; aAction: TRegionAction;
                                   aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil): TClickableRegion;
      function MakeClickableImageAuto(aImageCenter: TPoint; aImageClickRect: TRect; aAction: TRegionAction;
                                   aNormal: TBitmap32; aMargin: Integer = -1): TClickableRegion;
      function MakeClickableText(aTextCenter: TPoint; aText: String; aAction: TRegionAction; SwapHues: Boolean = False): TClickableRegion;

      function MakeHiddenOption(aKey: Word; aAction: TRegionAction): TClickableRegion; overload;
      function MakeHiddenOption(aFunc: TLemmixHotkeyAction; aAction: TRegionAction): TClickableRegion; overload;
      procedure DrawAllClickables(aForceNormalState: Boolean = False);

      function GetInternalMouseCoordinates: TPoint;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); virtual;
      procedure OnMouseMoved(aPoint: TPoint); virtual;
      procedure OnKeyPress(var aKey: Word); virtual;

      procedure AfterRedrawClickables; virtual;

      function GetWallpaperSuffix: String; virtual; abstract;

      procedure ReloadCursor(aName: string);

      procedure AfterCancelLevelSelect; virtual;

      property MenuFont: TMenuFont read fMenuFont;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
      procedure MainFormResized; override;
      procedure GetInternalScreenVars;
      procedure ResetMinimumWindowHeight;

      procedure DrawClassicModeButton;
      procedure HandleClassicModeClick;
      procedure MakeTalismanOptions;
      procedure HandleTalismanClick;
      procedure HandleCollectibleClick;
  end;

implementation

uses
  LemGame, LemReplay, GameSound,
  FMain, FSuperLemmixLevelSelect, FSuperLemmixConfig,
  PngInterface;

const
  ACCEPT_KEY_DELAY = 200;

{ TGameBaseMenuScreen }

procedure TGameBaseMenuScreen.CancelPlaybackMode;
begin
  if GameParams.PlaybackModeActive then
    StopPlayback(True);
end;

procedure TGameBaseMenuScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  OnKeyDown := nil;
  OnKeyUp := nil;
  OnMouseDown := nil;
  OnMouseMove := nil;
  ScreenImg.OnMouseDown := nil;
  ScreenImg.OnMouseMove := nil;
  inherited;
end;

constructor TGameBaseMenuScreen.Create(aOwner: TComponent);
begin
  inherited;

  fKeyStates := TDictionary<Word, UInt64>.Create;
  fClickableRegions := TObjectList<TClickableRegion>.Create;

  fMenuFont := TMenuFont.Create;
  fMenuFont.Load;

  fBasicCursor := TNLCursor.Create(Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS);
  LoadBasicCursor('menu');
  SetBasicCursor;

  GetInternalScreenVars;
  InitializeImage;

  OnKeyDown := Form_KeyDown;
  OnKeyUp := Form_KeyUp;
  OnMouseDown := Form_MouseDown;
  OnMouseMove := Form_MouseMove;
  ScreenImg.OnMouseDown := Img_MouseDown;
  ScreenImg.OnMouseMove := Img_MouseMove;

  fCalledFromClassicModeButton := False;

  fTalRects := TList<TRect>.Create;
  fTalismanImage := nil;
end;

destructor TGameBaseMenuScreen.Destroy;
begin
  fMenuFont.Free;
  fBasicCursor.Free;
  fClickableRegions.Free;
  fKeyStates.Free;

  fTalRects.Free;

  if fTalismanImage <> nil then
    fTalismanImage.Free;

  inherited;
end;

procedure TGameBaseMenuScreen.LoadBasicCursor(aName: string);
var
  BMP: TBitmap32;
  aPath: string;
  i: Integer;
begin
  BMP := TBitmap32.Create;
  try
    if GameParams.HighResolution then
      aName := aName + '-hr.png'
    else
      aName := aName + '.png';

    aPath := AppPath + SFGraphicsCursor + aName;

    TPngInterface.LoadPngFile(aPath, BMP);
    fBasicCursor.LoadFromBitmap(BMP);

    for i := 1 to fBasicCursor.MaxZoom do
      Screen.Cursors[i] := fBasicCursor.GetCursor(i);
  finally
    BMP.Free;
  end;
end;

// Determines the size of the available window space
procedure TGameBaseMenuScreen.GetInternalScreenVars;
var
  WindowWidth: Integer;
  UseLargerWidth, UseMediumWidth: Boolean;
begin
  WindowWidth := GameParams.MainForm.ClientWidth;

  UseLargerWidth := (WindowWidth > 1600) and not GameParams.FullScreen;

  UseMediumWidth := (WindowWidth > 1400) and (WindowWidth < 1599)
                     and not GameParams.FullScreen;

  if UseLargerWidth then
    InternalScreenWidth := 1092
  else if UseMediumWidth then
    InternalScreenWidth := 990
  else
    InternalScreenWidth := 888;

  InternalScreenHeight := 492;

  FooterOptionsOneRowY := 460;

  FooterOptionsTwoRowsHighY := 440;
  FooterOptionsTwoRowsLowY := 460;

  FooterOneOptionX := InternalScreenWidth div 2;

  FooterTwoOptionsLeftX := InternalScreenWidth * 5 div 16;
  FooterTwoOptionsRightX := InternalScreenWidth * 11 div 16;

  FooterThreeOptionsLeftX := InternalScreenWidth * 3 div 16;
  FooterThreeOptionsMidX := InternalScreenWidth div 2;
  FooterThreeOptionsRightX := InternalScreenWidth * 13 div 16;

  TalismanPadding := 8;
end;

procedure TGameBaseMenuScreen.InitializeImage;
begin
  with ScreenImg do
  begin
    Bitmap.SetSize(InternalScreenWidth, InternalScreenHeight);

    DrawWallpaper;

    BoundsRect := Rect(0, 0, ClientWidth, ClientHeight);

    ScreenImg.Align := alClient;
    ScreenImg.ScaleMode := smStretch;
    ScreenImg.BitmapAlign := baCenter;

    TLinearResampler.Create(ScreenImg.Bitmap);

    ResetMinimumWindowHeight;
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

procedure TGameBaseMenuScreen.ResetMinimumWindowHeight;
begin
  GameParams.MinimumWindowHeight := GameParams.DefaultMinHeight;
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
  finally
    tmpNormal.Free;
    tmpHover.Free;
    tmpClick.Free;
  end;
end;

function TGameBaseMenuScreen.MakeClickableImageAuto(aImageCenter: TPoint;
  aImageClickRect: TRect; aAction: TRegionAction;
  aNormal: TBitmap32; aMargin: Integer): TClickableRegion;
const
  DEFAULT_MARGIN = 5;

  HOVER_COLOR = $FFA0A0A0;
  CLICK_COLOR = $FF404040;
var
  tmpNormal, tmpHover, tmpClick: TBitmap32;
  Temp: TBitmap32;
  x, y, n: Integer;
  Intensity: Cardinal;
begin
  if aMargin < 0 then
    aMargin := DEFAULT_MARGIN;

  Temp := TBitmap32.Create;
  tmpNormal := TBitmap32.Create;
  tmpHover := TBitmap32.Create;
  tmpClick := TBitmap32.Create;
  try
    Temp.SetSize(aNormal.Width + aMargin * 2, aNormal.Height + aMargin * 2);
    Temp.Clear(0);
    Temp.DrawMode := dmBlend;

    tmpNormal.Assign(Temp);
    tmpHover.Assign(Temp);
    tmpClick.Assign(Temp);

    aNormal.DrawTo(Temp, aMargin, aMargin);

    // N.B. tmpNormal is used as a second temporary image within this loop
    for n := 1 to aMargin do
    begin
      for y := 0 to Temp.Height-1 do
        for x := 0 to Temp.Width-1 do
        begin
          Intensity := 0;

          // Diagonals
          Intensity := Intensity + ((Temp.PixelS[x - 1, y - 1] and $FF000000) shr 24);
          Intensity := Intensity + ((Temp.PixelS[x + 1, y - 1] and $FF000000) shr 24);
          Intensity := Intensity + ((Temp.PixelS[x - 1, y + 1] and $FF000000) shr 24);
          Intensity := Intensity + ((Temp.PixelS[x + 1, y + 1] and $FF000000) shr 24);

          // Straights
          Intensity := Intensity + ((Temp.PixelS[x - 1, y] and $FF000000) shr 24) * 2;
          Intensity := Intensity + ((Temp.PixelS[x + 1, y] and $FF000000) shr 24) * 2;
          Intensity := Intensity + ((Temp.PixelS[x, y - 1] and $FF000000) shr 24) * 2;
          Intensity := Intensity + ((Temp.PixelS[x, y + 1] and $FF000000) shr 24) * 2;

          Intensity := Min(Round(Intensity / 12 * 2), 255);
          tmpNormal[x, y] := Intensity shl 24;
        end;

      Temp.Assign(tmpNormal);
      tmpNormal.Clear(0);
    end;
    // End of usage of tmpNormal as a temporary image

    for y := 0 to Temp.Height-1 do
      for x := 0 to Temp.Width-1 do
      begin
        tmpHover[x, y] := (Temp[x, y] and $FF000000) or (HOVER_COLOR and $00FFFFFF);
        tmpClick[x, y] := (Temp[x, y] and $FF000000) or (CLICK_COLOR and $00FFFFFF);
      end;

    Temp.Assign(aNormal);
    Temp.DrawMode := dmBlend;

    Temp.DrawTo(tmpNormal, aMargin, aMargin);
    Temp.DrawTo(tmpHover, aMargin, aMargin);
    Temp.DrawTo(tmpClick, aMargin, aMargin);

    Types.OffsetRect(aImageClickRect, aMargin, aMargin);

    Result := MakeClickableImage(aImageCenter, aImageClickRect, aAction,
                                 tmpNormal, tmpHover, tmpClick);
  finally
    tmpNormal.Free;
    tmpHover.Free;
    tmpClick.Free;
    Temp.Free;
  end;

end;

// Changes hue of clickable text in pre-level screen
function TGameBaseMenuScreen.MakeClickableText(aTextCenter: TPoint;
  aText: String; aAction: TRegionAction; SwapHues: Boolean = False): TClickableRegion;
const
  HUE_SHIFT_NORMAL = 0.250;
  HUE_SHIFT_HOVER = 0;
  VALUE_SHIFT_CLICK = -0.250;
var
  tmpNormal, tmpHover, tmpClick: TBitmap32;
  ScreenRect: TRect;
  x, y: Integer;

  NormalShift, HoverShift, ClickShift: TColorDiff;
begin
  FillChar(NormalShift, SizeOf(TColorDiff), 0);
  FillChar(HoverShift, SizeOf(TColorDiff), 0);
  FillChar(ClickShift, SizeOf(TColorDiff), 0);

  if SwapHues then
  begin
    NormalShift.HShift := HUE_SHIFT_HOVER;
    HoverShift.HShift := HUE_SHIFT_NORMAL;
  end else begin
    NormalShift.HShift := HUE_SHIFT_NORMAL;
    HoverShift.HShift := HUE_SHIFT_HOVER;
  end;

  ClickShift.HShift := HUE_SHIFT_HOVER;
  ClickShift.VShift := VALUE_SHIFT_CLICK;

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

procedure TGameBaseMenuScreen.MakeTalismanOptions;
var
  NewRegion: TClickableRegion;
  Temp: TBitmap32;
  Tal: TTalisman;
  SrcRect: TRect;
  TalPoint: TPoint;
  LoadPath, aImage: String;
  i, TalCount, TotalTalWidth, YOffset: Integer;
  KeepTalismans, HasCollectibles, AllCollectiblesGathered: Boolean;

  procedure DrawButtons(IsCollectible: Boolean = False);
  begin
    Temp.Clear(0);
    fTalismanImage.DrawTo(Temp, 0, 0, SrcRect);

    if IsCollectible then
      NewRegion := MakeClickableImageAuto(TalPoint, Temp.BoundsRect, HandleCollectibleClick, Temp)
    else
      NewRegion := MakeClickableImageAuto(TalPoint, Temp.BoundsRect, HandleTalismanClick, Temp);

    fTalRects.Add(NewRegion.ClickArea);
    TalPoint.X := TalPoint.X + Temp.Width + TalismanPadding;
  end;
const
  TALISMANS_Y_POSITION = 408;
begin
  if (GameParams.Level.Talismans.Count = 0) and
     (GameParams.Level.Info.CollectibleCount = 0) then
        Exit;

  YOffset := 0;
  KeepTalismans := False;
  HasCollectibles := GameParams.Level.Info.CollectibleCount > 0;

  if (CurrentScreen = gstPostview) then
    YOffset := 316;

  if fTalismanImage = nil then
    fTalismanImage := TBitmap32.Create;

  Temp := TBitmap32.Create;
  try
    aImage := 'talismans.png';

    // Try styles folder first
    LoadPath := AppPath + SFStyles + GameParams.Level.Info.GraphicSetName + SFIcons + aImage;

    if not FileExists(LoadPath) then
    begin
      // Then level pack folder
      LoadPath := GameParams.CurrentLevel.Group.FindFile(aImage);
      // Then default
      if LoadPath = '' then
        LoadPath := AppPath + SFGraphicsMenu + aImage
      else
        KeepTalismans := True;
    end;

    TPngInterface.LoadPngFile(LoadPath, fTalismanImage);
    fTalismanImage.DrawMode := dmOpaque;

    Temp.SetSize(fTalismanImage.Width div 2, fTalismanImage.Height div 4);

    TalCount := GameParams.Level.Talismans.Count;
    if HasCollectibles then TalCount := TalCount + 1;

    TotalTalWidth := (TalCount * (Temp.Width + TalismanPadding)) - TalismanPadding;
    TalPoint := Point((ScreenImg.Bitmap.Width - TotalTalWidth + Temp.Width) div 2,
                       TALISMANS_Y_POSITION - YOffset);

    for i := 0 to GameParams.Level.Talismans.Count-1 do
    begin
      Tal := GameParams.Level.Talismans[i];
      case Tal.Color of
        tcBronze: SrcRect := SizedRect(0, 0, Temp.Width, Temp.Height);
        tcSilver: SrcRect := SizedRect(0, Temp.Height, Temp.Width, Temp.Height);
        tcGold: SrcRect := SizedRect(0, Temp.Height * 2, Temp.Width, Temp.Height);
      end;

      if GameParams.CurrentLevel.TalismanStatus[Tal.ID] then
        OffsetRect(SrcRect, Temp.Width, 0);

      DrawButtons;
    end;

    if (GameParams.Level.Info.CollectibleCount > 0) then
    begin
      AllCollectiblesGathered := (GameParams.CurrentLevel.UserRecords.CollectiblesGathered.Value
                               = GameParams.Level.Info.CollectibleCount);

      SrcRect := SizedRect(0, Temp.Height * 3, Temp.Width, Temp.Height);

      if AllCollectiblesGathered then
        OffsetRect(SrcRect, Temp.Width, 0);

      DrawButtons(True);
    end;
  finally
    Temp.Free;

    if not KeepTalismans then
    begin
      fTalismanImage.Free;
      fTalismanImage := nil;
    end;
  end;
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
  if ScreenIsClosing then
    Exit;

  Region := fClickableRegions[TComponent(Sender).Tag];
  P := GetInternalMouseCoordinates;

  if Types.PtInRect(Region.ClickArea, P) then
    Region.CurrentState := rsHover
  else
    Region.CurrentState := rsNormal;

  DrawAllClickables;

  Region.ResetTimer := nil;
  Sender.Free;
end;

procedure TGameBaseMenuScreen.DrawClassicModeButton;
  function SetButtonPosition(XOffset: Integer; YOffset: Integer): TPoint;
  begin
    Result.X := (ScreenImg.Bitmap.Width - XOffset);
    Result.Y := (0 + YOffset);
  end;

var
  NewRegion: TClickableRegion;
  BMP: TBitmap32;
begin
  BMP := TBitmap32.Create;
  try
    BMP.Clear;

    if GameParams.ClassicMode then
      GetGraphic('classic_mode_on.png', BMP)
    else
      GetGraphic('classic_mode_off.png', BMP);
    NewRegion := MakeClickableImageAuto(SetButtonPosition((BMP.Width div 3) * 2, BMP.Height),
                                        BMP.BoundsRect, HandleClassicModeClick, BMP);
    NewRegion.ShortcutKeys.Add(VK_F4);
  finally
    BMP.Free;
  end;
end;

procedure TGameBaseMenuScreen.HandleClassicModeClick;
begin
  if GameParams.MenuSounds then SoundManager.PlaySound(SFX_OK);

  // Set Classic Mode properties
  if not GameParams.ClassicMode then
  begin
    GameParams.ClassicMode := True;
    GameParams.HideShadows := True;
    GameParams.HideHelpers := True;
    GameParams.HideSkillQ := True;
  end else begin
    GameParams.ClassicMode := False;
    GameParams.HideShadows := False;
    GameParams.HideHelpers := False;
    GameParams.HideSkillQ := False;
  end;

  // Reload config to apply changes and redraw button
  if GameParams.TestModeLevel <> nil then
  begin
    fCalledFromClassicModeButton := True;
    ShowConfigMenu;
  end else begin
    GameParams.Save(scCritical);
    GameParams.Load;
    DrawClassicModeButton;
  end;
end;

procedure TGameBaseMenuScreen.HandleCollectibleClick;
var
  P: TPoint;
  i: Integer;
  F: TLevelInfoPanel;
begin
  P := GetInternalMouseCoordinates;
  for i := 0 to fTalRects.Count-1 do
    if PtInRect(fTalRects[i], P) then
    begin
      F := TLevelInfoPanel.Create(Self, nil, fTalismanImage);
      try
        F.Level := GameParams.Level;
        F.ShowCollectiblePopup;
      finally
        F.Free;
      end;
      Break;
    end;
end;

procedure TGameBaseMenuScreen.HandleTalismanClick;
var
  P: TPoint;
  i: Integer;
  F: TLevelInfoPanel;
begin
  P := GetInternalMouseCoordinates;
  for i := 0 to fTalRects.Count-1 do
    if PtInRect(fTalRects[i], P) then
    begin
      F := TLevelInfoPanel.Create(Self, nil, fTalismanImage);
      try
        F.Level := GameParams.Level;
        F.Talisman := GameParams.Level.Talismans[i];
        F.ShowPopup;
      finally
        F.Free;
      end;
      Break;
    end;
end;

procedure TGameBaseMenuScreen.HandleKeyboardInput(Key: Word);
var
  i, n: Integer;
  NewTimer: TTimer;
begin
  if ScreenIsClosing then
    Exit;

  for i := 0 to fClickableRegions.Count-1 do
    for n := 0 to fClickableRegions[i].ShortcutKeys.Count-1 do
      if Key = fClickableRegions[i].ShortcutKeys[n] then
      begin
        if fClickableRegions[i].Bitmaps <> nil then
        begin
          if fClickableRegions[i].ResetTimer = nil then
          begin
            NewTimer := TTimer.Create(Self);
            NewTimer.Interval := 100;
            NewTimer.Tag := i;
            NewTimer.OnTimer := OnClickTimer;
            fClickableRegions[i].ResetTimer := NewTimer;
          end else begin
            fClickableRegions[i].ResetTimer.Enabled := False;
            fClickableRegions[i].ResetTimer.Enabled := True;
          end;

          fClickableRegions[i].CurrentState := rsClick;
          DrawAllClickables;
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
  FoundActive: Boolean;
  StatusChanged: Boolean;

  P: TPoint;
begin
  if ScreenIsClosing then
    Exit;

  P := GetInternalMouseCoordinates;
  FoundActive := False;
  StatusChanged := False;

  for i := fClickableRegions.Count-1 downto 0 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) and not FoundActive then
      begin
        if (fClickableRegions[i].CurrentState = rsNormal) then
        begin
          fClickableRegions[i].CurrentState := rsHover;
          StatusChanged := True;
        end;

        FoundActive := True;
      end else if (FoundActive or not Types.PtInRect(fClickableRegions[i].ClickArea, P)) and (fClickableRegions[i].CurrentState = rsHover) then
      begin
        fClickableRegions[i].CurrentState := rsNormal;
        StatusChanged := True;
      end;

  if StatusChanged then
    DrawAllClickables;

  OnMouseMoved(P); // This one we want to always call.
end;

procedure TGameBaseMenuScreen.HandleMouseClick(Button: TMouseButton);
var
  i: Integer;
  NewTimer: TTimer;

  P: TPoint;
  ExpRegion: TRect;

  InvokeCustomHandler: Boolean;
const
  DEAD_ZONE_SIZE = 6;
begin
  if ScreenIsClosing then
    Exit;

  P := GetInternalMouseCoordinates;
  InvokeCustomHandler := True;

  for i := fClickableRegions.Count-1 downto 0 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) then
      begin
        if fClickableRegions[i].ResetTimer = nil then
        begin
          NewTimer := TTimer.Create(Self);
          NewTimer.Interval := 150;
          NewTimer.Tag := i;
          NewTimer.OnTimer := OnClickTimer;
          fClickableRegions[i].ResetTimer := NewTimer;
        end else begin
          fClickableRegions[i].ResetTimer.Enabled := False;
          fClickableRegions[i].ResetTimer.Enabled := True;
        end;

        fClickableRegions[i].CurrentState := rsClick;
        fClickableRegions[i].Bitmaps.DrawTo(ScreenImg.Bitmap, fClickableRegions[i].Bounds, fClickableRegions[i].SrcRect[rsClick]);

        fClickableRegions[i].Action;
        InvokeCustomHandler := False;
        Break;
      end else begin
        ExpRegion := fClickableRegions[i].ClickArea;
        ExpRegion.Left := ExpRegion.Left - DEAD_ZONE_SIZE;
        ExpRegion.Top := ExpRegion.Top - DEAD_ZONE_SIZE;
        ExpRegion.Right := ExpRegion.Right + DEAD_ZONE_SIZE;
        ExpRegion.Bottom := ExpRegion.Bottom + DEAD_ZONE_SIZE;

        if Types.PtInRect(ExpRegion, P) then
          InvokeCustomHandler := False;
      end;

  if InvokeCustomHandler then
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

procedure TGameBaseMenuScreen.ReloadCursor(aName: string);
begin
  LoadBasicCursor(aName);
  SetBasicCursor;
end;

procedure TGameBaseMenuScreen.AfterCancelLevelSelect;
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.AfterRedrawClickables;
begin
  // Intentionally blank.
end;

procedure TGameBaseMenuScreen.SaveReplay;
var
  S: String;
begin
  GlobalGame.EnsureCorrectReplayDetails;
  S := GlobalGame.ReplayManager.GetSaveFileName(Self, rsoPostview, GlobalGame.ReplayManager);
  if S = '' then Exit;
  GlobalGame.ReplayManager.SaveToFile(S);
end;

procedure TGameBaseMenuScreen.SetBasicCursor;
var
  CursorIndex: Integer;
begin
  CursorIndex := Max(1, Min(MainForm.Width div 320, MainForm.Height div 180) div ResMod);

  Cursor := CursorIndex;
  MainForm.Cursor := CursorIndex;
  Screen.Cursor := CursorIndex;
  ScreenImg.Cursor := CursorIndex;
end;

procedure TGameBaseMenuScreen.DrawAllClickables(aForceNormalState: Boolean = False);
var
  i: Integer;
  Region: TClickableRegion;

  function CheckDrawCurrentRegion(aDrawingFront: Boolean): Boolean;
  begin
    Result := False;

    if Region.Bitmaps = nil then Exit;
    if (Region.DrawInFrontWhenHighlit and (Region.CurrentState <> rsNormal)) xor aDrawingFront then Exit;

    Result := True;
  end;
begin
  if ScreenIsClosing then
    Exit;

  if aForceNormalState then
  begin
    for i := 0 to fClickableRegions.Count-1 do
      fClickableRegions[i].CurrentState := rsNormal;
  end else
    HandleMouseMove; // To set statuses

  for i := 0 to fClickableRegions.Count-1 do
  begin
    Region := fClickableRegions[i];
    if CheckDrawCurrentRegion(False) then
      Region.Bitmaps.DrawTo(ScreenImg.Bitmap, Region.Bounds, Region.GetSrcRect(Region.CurrentState));
  end;

  for i := 0 to fClickableRegions.Count-1 do
  begin
    Region := fClickableRegions[i];
    if CheckDrawCurrentRegion(True) then
      Region.Bitmaps.DrawTo(ScreenImg.Bitmap, Region.Bounds, Region.GetSrcRect(Region.CurrentState));
  end;

  AfterRedrawClickables;
end;

function TGameBaseMenuScreen.GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = False; aFromPackOnly: Boolean = False): Boolean;
begin
  Result := True;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile(aName)) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile(aName), aDst)
  else if FileExists(AppPath + SFGraphicsMenu + aName) and ((not aFromPackOnly) or (not aAcceptFailure)) then // N.B. aFromPackOnly + aAcceptFailure is an invalid combination
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, aDst)
  else begin
    if not aAcceptFailure then
      raise Exception.Create('Could not find gfx\menu\' + aName + '.');

    Result := False;
  end;

  aDst.DrawMode := dmBlend;
end;

procedure TGameBaseMenuScreen.DrawWallpaper;
begin
  DrawWallpaper(ScreenImg.Bitmap.BoundsRect);
end;

function TGameBaseMenuScreen.GetWallpaperDrawMode: String;
var
  Parser: TParser;
  Sec: TParserSection;
begin
  Parser := TParser.Create;
  try
    Result := 'TILE'; // Default

    Sec := Parser.MainSection;
    Parser.LoadFromFile(AppPath + SFData + 'title.nxmi');

    if GameParams.CurrentLevel.Group.FindFile('title.nxmi') <> '' then
      Parser.LoadFromFile(GameParams.CurrentLevel.Group.FindFile('title.nxmi'));

    Result := Sec.LineTrimString['BACKGROUND_DRAW_MODE'];
  finally
    Parser.Free;
  end;
end;

procedure TGameBaseMenuScreen.DrawWallpaper(aRegion: TRect);
var
  aX, aY: Integer;
  BgImage, Dst: TBitmap32;
  SrcRect, DstRect: TRect;
  WallpaperDrawMode: String;
  WallpaperPath: String;
begin
  Dst := ScreenImg.Bitmap;
  BgImage := TBitmap32.Create;

  if GameParams.AmigaTheme then
    WallpaperPath := 'amiga/wallpaper'
  else
    WallpaperPath := 'wallpaper';

  try
    if not GetGraphic(WallpaperPath + '_' + GetWallpaperSuffix + '.png', BgImage, True) then
      GetGraphic(WallpaperPath + '.png', BgImage, True);

    if (BgImage.Width = 0) or (BgImage.Height = 0) then
    begin
      Dst.FillRect(aRegion.Left, aRegion.Top, aRegion.Right, aRegion.Bottom, $FF000000);
      Exit;
    end;

    WallpaperDrawMode := GetWallpaperDrawMode;

    if (WallpaperDrawMode <> 'STRETCH') then
    begin
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
    end else begin
      SrcRect := Rect(0, 0, BgImage.Width, BgImage.Height);
      DstRect := aRegion;

      Dst.Draw(DstRect, SrcRect, BgImage);
    end;
  finally
    BgImage.Free;
  end;
end;

procedure TGameBaseMenuScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not fKeyStates.ContainsKey(Key) then
    fKeyStates.Add(Key, GetTickCount64);
end;

procedure TGameBaseMenuScreen.Form_KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  TimeDiff: UInt64;
begin
  if fKeyStates.ContainsKey(Key) then
  begin
    TimeDiff := GetTickCount64 - fKeyStates[Key];
    fKeyStates.Remove(Key);
    if TimeDiff <= ACCEPT_KEY_DELAY then
      HandleKeyboardInput(Key);
  end;
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

  PopupResult: Integer;
begin
  if GameParams.TestModeLevel <> nil then Exit;

  OldLevel := GameParams.CurrentLevel;
  F := TFLevelSelect.Create(Self);
  try
    PopupResult := F.ShowModal;
    Success := PopupResult = mrOk;
    LoadAsPack := F.LoadAsPack;
  finally
    F.Free;
  end;

  if PopupResult = mrRetry then
  begin
    if GameParams.PlaybackModeActive then
    begin
      GeneratePlaybackList;
    end else
      CloseScreen(gstReplayTest)
  end else if not Success then
  begin
    GameParams.SetLevel(OldLevel);
    AfterCancelLevelSelect;
  end else begin
    GameParams.ShownText := False;

    if LoadAsPack then
      CloseScreen(gstMenu)
    else
      CloseScreen(gstPreview);
  end;
end;

procedure TGameBaseMenuScreen.ShowConfigMenu;
var
  ConfigDlg: TFormNXConfig;
  OldAmigaTheme, OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean;
begin
  OldAmigaTheme := GameParams.AmigaTheme;
  OldFullScreen := GameParams.FullScreen;
  OldHighResolution := GameParams.HighResolution;
  OldShowMinimap := GameParams.ShowMinimap;
  ResetWindowSize := False;
  ResetWindowPos := False;

  ConfigDlg := TFormNXConfig.Create(Self);
  try
    ConfigDlg.SetGameParams;

    // Skip the dialog and go straight to result
    if fCalledFromClassicModeButton and (GameParams.TestModeLevel <> nil) then
      ConfigDlg.ModalResult := MrOK

    // Show the dialog
    else begin
      ConfigDlg.NXConfigPages.TabIndex := 0;
      ConfigDlg.ShowModal;
      ResetWindowSize := ConfigDlg.ResetWindowSize;
      ResetWindowPos := ConfigDlg.ResetWindowPosition;
    end;
  finally
    ConfigDlg.Free;
  end;

  { Wise advice from Simon - save these things on exiting the config dialog, rather than
    waiting for a quit or a screen transition to save them. }
  GameParams.Save(scImportant);
  ApplyConfigChanges(OldAmigaTheme, OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos);

  if fCalledFromClassicModeButton then
  begin
    fCalledFromClassicModeButton := False;
    DrawClassicModeButton;
  end else
    DoAfterConfig;
end;

procedure TGameBaseMenuScreen.ApplyConfigChanges(OldAmigaTheme, OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean);
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

    if ResetWindowSize then
      TMainForm(GameParams.MainForm).RestoreDefaultSize;

    if ResetWindowPos then
      TMainForm(GameParams.MainForm).RestoreDefaultPosition;
  end;

  if (GameParams.FullScreen <> OldFullScreen)
    or (GameParams.AmigaTheme <> OldAmigaTheme)
      or (GameParams.ShowMinimap <> OldShowMinimap) then
        CloseScreen(CurrentScreen);

  if (GameParams.HighResolution <> OldHighResolution) then
  begin
    // Reload the preview screen again to ensure the level gets redrawn correctly
    if (CurrentScreen = gstPreview) then
      CloseScreen(CurrentScreen);

    PieceManager.Clear;
  end;

  TLinearResampler.Create(ScreenImg.Bitmap);
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

  fDrawInFrontWhenHighlit := True;

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
