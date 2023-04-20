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
  Math, Forms, Controls, ExtCtrls, Dialogs, Classes, SysUtils, Windows;

const
  //this determines the size of the available window space
  INTERNAL_SCREEN_WIDTH = 836;
  INTERNAL_SCREEN_HEIGHT = 492;

  //MM = Minimap - we need different menu sizes for when the Minimap is or isn't displayed
  MM_INTERNAL_SCREEN_WIDTH = 1092;

  //FS = FullScreen - we need different menu size for FullScreen mode
  FS_INTERNAL_SCREEN_WIDTH = 874;

  FOOTER_OPTIONS_ONE_ROW_Y = 460;

  FOOTER_OPTIONS_TWO_ROWS_HIGH_Y = 440;
  FOOTER_OPTIONS_TWO_ROWS_LOW_Y = 460;

  MM_FOOTER_ONE_OPTION_X = MM_INTERNAL_SCREEN_WIDTH div 2; //hotbookmark
  FS_FOOTER_ONE_OPTION_X = FS_INTERNAL_SCREEN_WIDTH div 2; //hotbookmark
  FOOTER_ONE_OPTION_X = INTERNAL_SCREEN_WIDTH div 2;

  MM_FOOTER_TWO_OPTIONS_X_LEFT = MM_INTERNAL_SCREEN_WIDTH * 5 div 16; //hotbookmark
  FS_FOOTER_TWO_OPTIONS_X_LEFT = FS_INTERNAL_SCREEN_WIDTH * 5 div 16; //hotbookmark
  FOOTER_TWO_OPTIONS_X_LEFT = INTERNAL_SCREEN_WIDTH * 5 div 16;

  MM_FOOTER_TWO_OPTIONS_X_RIGHT = MM_INTERNAL_SCREEN_WIDTH * 11 div 16; //hotbookmark
  FS_FOOTER_TWO_OPTIONS_X_RIGHT = FS_INTERNAL_SCREEN_WIDTH * 11 div 16; //hotbookmark
  FOOTER_TWO_OPTIONS_X_RIGHT = INTERNAL_SCREEN_WIDTH * 11 div 16;

  MM_FOOTER_THREE_OPTIONS_X_LEFT = MM_INTERNAL_SCREEN_WIDTH * 3 div 16; //hotbookmark
  FS_FOOTER_THREE_OPTIONS_X_LEFT = FS_INTERNAL_SCREEN_WIDTH * 3 div 16; //hotbookmark
  FOOTER_THREE_OPTIONS_X_LEFT = INTERNAL_SCREEN_WIDTH * 3 div 16;

  MM_FOOTER_THREE_OPTIONS_X_MID = MM_INTERNAL_SCREEN_WIDTH div 2; //hotbookmark
  FS_FOOTER_THREE_OPTIONS_X_MID = FS_INTERNAL_SCREEN_WIDTH div 2; //hotbookmark
  FOOTER_THREE_OPTIONS_X_MID = INTERNAL_SCREEN_WIDTH div 2;

  MM_FOOTER_THREE_OPTIONS_X_RIGHT = MM_INTERNAL_SCREEN_WIDTH * 13 div 16; //hotbookmark
  FS_FOOTER_THREE_OPTIONS_X_RIGHT = FS_INTERNAL_SCREEN_WIDTH * 13 div 16; //hotbookmark
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
      fMenuFont          : TMenuFont;
      fKeyStates: TDictionary<Word, UInt64>;

      fBasicCursor: TNLCursor;



      procedure LoadBasicCursor;
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

      {$ifdef exp}{$ifndef rc}
      procedure SaveScreenImage;
      {$endif}{$endif}
    protected
      fClickableRegions: TObjectList<TClickableRegion>;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;

      procedure DoLevelSelect;
      procedure SaveReplay;

      procedure ShowConfigMenu;
      procedure ApplyConfigChanges(OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean);
      procedure DoAfterConfig; virtual;

      function GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = false; aFromPackOnly: Boolean = false): Boolean;

      procedure DrawBackground; overload;
      procedure DrawBackground(aRegion: TRect); overload;

      function MakeClickableImage(aImageCenter: TPoint; aImageClickRect: TRect; aAction: TRegionAction;
                                   aNormal: TBitmap32; aHover: TBitmap32 = nil; aClick: TBitmap32 = nil): TClickableRegion;
      function MakeClickableImageAuto(aImageCenter: TPoint; aImageClickRect: TRect; aAction: TRegionAction;
                                   aNormal: TBitmap32; aMargin: Integer = -1): TClickableRegion;
      function MakeClickableText(aTextCenter: TPoint; aText: String; aAction: TRegionAction): TClickableRegion;

      function MakeHiddenOption(aKey: Word; aAction: TRegionAction): TClickableRegion; overload;
      function MakeHiddenOption(aFunc: TLemmixHotkeyAction; aAction: TRegionAction): TClickableRegion; overload;
      procedure DrawAllClickables(aForceNormalState: Boolean = false);

      function GetInternalMouseCoordinates: TPoint;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); virtual;
      procedure OnMouseMoved(aPoint: TPoint); virtual;
      procedure OnKeyPress(var aKey: Word); virtual;

      procedure AfterRedrawClickables; virtual;

      function GetBackgroundSuffix: String; virtual; abstract;

      procedure ReloadCursor;

      procedure AfterCancelLevelSelect; virtual;

      property MenuFont: TMenuFont read fMenuFont;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure MainFormResized; override;
  end;

implementation

uses
  LemGame, LemReplay,
  FMain, FSuperLemmixLevelSelect, FSuperLemmixConfig,
  PngInterface;

const
  ACCEPT_KEY_DELAY = 200;

{ TGameBaseMenuScreen }

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
  LoadBasicCursor;
  SetBasicCursor;

  InitializeImage;

  OnKeyDown := Form_KeyDown;
  OnKeyUp := Form_KeyUp;
  OnMouseDown := Form_MouseDown;
  OnMouseMove := Form_MouseMove;
  ScreenImg.OnMouseDown := Img_MouseDown;
  ScreenImg.OnMouseMove := Img_MouseMove;

  {$ifdef exp}{$ifndef rc}
  //MakeHiddenOption(lka_SaveImage, SaveScreenImage);
  {$endif}{$endif}
end;

{$ifdef exp}{$ifndef rc}
procedure TGameBaseMenuScreen.SaveScreenImage;
var
  i: Integer;
begin
  i := 1;
  while FileExists(AppPath + 'Screenshot_' + LeadZeroStr(i, 3) + '.png') do
    Inc(i);
  TPngInterface.SavePngFile(AppPath + 'Screenshot_' + LeadZeroStr(i, 3) + '.png', ScreenImg.Bitmap);
end;
{$endif}{$endif}

destructor TGameBaseMenuScreen.Destroy;
begin
  fMenuFont.Free;
  fBasicCursor.Free;
  fClickableRegions.Free;
  fKeyStates.Free;

  inherited;
end;

procedure TGameBaseMenuScreen.LoadBasicCursor;
var
  BMP: TBitmap32;
  i: Integer;
begin
  BMP := TBitmap32.Create;
  try
    //if {we're on the postview screen} then     //bookmark - need code to check
                                                 //for postview screen status
    //begin
    //if GameParams.HighResolution then
      //TPngInterface.LoadPngFile(AppPath + 'gfx/cursor-hr/postview.png', BMP)
    //else
      //TPngInterface.LoadPngFile(AppPath + 'gfx/cursor/postview.png', BMP);
    //end else begin
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(AppPath + 'gfx/cursor-hr/amiga.png', BMP)
    else
      TPngInterface.LoadPngFile(AppPath + 'gfx/cursor/amiga.png', BMP);
    //end;

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
    if GameParams.ShowMinimap and not GameParams.FullScreen then
    Bitmap.SetSize(MM_INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);

    if GameParams.FullScreen then
    Bitmap.SetSize(FS_INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);

    if not GameParams.ShowMinimap and not GameParams.FullScreen then
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

    // tmpNormal is used as a second temporary image within this loop
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
    // end of usage of tmpNormal as a temporary image

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

//changes hue of clickable text in pre-level screen
function TGameBaseMenuScreen.MakeClickableText(aTextCenter: TPoint;
  aText: String; aAction: TRegionAction): TClickableRegion;
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

  NormalShift.HShift := HUE_SHIFT_NORMAL;
  HoverShift.HShift := HUE_SHIFT_HOVER;

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

  DrawAllClickables;

  Region.ResetTimer := nil;
  Sender.Free;
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
  FoundActive := false;
  StatusChanged := false;

  for i := fClickableRegions.Count-1 downto 0 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) and not FoundActive then
      begin
        if (fClickableRegions[i].CurrentState = rsNormal) then
        begin
          fClickableRegions[i].CurrentState := rsHover;
          StatusChanged := true;
        end;

        FoundActive := true;
      end else if (FoundActive or not Types.PtInRect(fClickableRegions[i].ClickArea, P)) and (fClickableRegions[i].CurrentState = rsHover) then
      begin
        fClickableRegions[i].CurrentState := rsNormal;
        StatusChanged := true;
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
  InvokeCustomHandler := true;

  for i := fClickableRegions.Count-1 downto 0 do
    if fClickableRegions[i].Bitmaps <> nil then
      if Types.PtInRect(fClickableRegions[i].ClickArea, P) then
      begin
        if fClickableRegions[i].ResetTimer = nil then
        begin
          NewTimer := TTimer.Create(self);
          NewTimer.Interval := 150;
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
        InvokeCustomHandler := false;
        Break;
      end else begin
        ExpRegion := fClickableRegions[i].ClickArea;
        ExpRegion.Left := ExpRegion.Left - DEAD_ZONE_SIZE;
        ExpRegion.Top := ExpRegion.Top - DEAD_ZONE_SIZE;
        ExpRegion.Right := ExpRegion.Right + DEAD_ZONE_SIZE;
        ExpRegion.Bottom := ExpRegion.Bottom + DEAD_ZONE_SIZE;

        if Types.PtInRect(ExpRegion, P) then
          InvokeCustomHandler := false;
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

procedure TGameBaseMenuScreen.ReloadCursor;
begin
  LoadBasicCursor;
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
  S := GlobalGame.ReplayManager.GetSaveFileName(self, rsoPostview, GlobalGame.ReplayManager);
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

procedure TGameBaseMenuScreen.DrawAllClickables(aForceNormalState: Boolean = false);
var
  i: Integer;
  Region: TClickableRegion;

  function CheckDrawCurrentRegion(aDrawingFront: Boolean): Boolean;
  begin
    Result := false;

    if Region.Bitmaps = nil then Exit;
    if (Region.DrawInFrontWhenHighlit and (Region.CurrentState <> rsNormal)) xor aDrawingFront then Exit;

    Result := true;
  end;
begin
  if aForceNormalState then
  begin
    for i := 0 to fClickableRegions.Count-1 do
      fClickableRegions[i].CurrentState := rsNormal;
  end else
    HandleMouseMove; // To set statuses

  for i := 0 to fClickableRegions.Count-1 do
  begin
    Region := fClickableRegions[i];
    if CheckDrawCurrentRegion(false) then
      Region.Bitmaps.DrawTo(ScreenImg.Bitmap, Region.Bounds, Region.GetSrcRect(Region.CurrentState));
  end;

  for i := 0 to fClickableRegions.Count-1 do
  begin
    Region := fClickableRegions[i];
    if CheckDrawCurrentRegion(true) then
      Region.Bitmaps.DrawTo(ScreenImg.Bitmap, Region.Bounds, Region.GetSrcRect(Region.CurrentState));
  end;

  AfterRedrawClickables;
end;

function TGameBaseMenuScreen.GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = false; aFromPackOnly: Boolean = false): Boolean;
begin
  Result := true;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile(aName)) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile(aName), aDst)
  else if FileExists(AppPath + SFGraphicsMenu + aName) and ((not aFromPackOnly) or (not aAcceptFailure)) then // aFromPackOnly + aAcceptFailure is an invalid combination
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, aDst)
  else begin
    if not aAcceptFailure then
      raise Exception.Create('Could not find gfx\menu\' + aName + '.');

    Result := false;
  end;

  aDst.DrawMode := dmBlend;
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
    if not GetGraphic('background_' + GetBackgroundSuffix + '.png', BgImage, true) then
      GetGraphic('background.png', BgImage, true);

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
  F := TFLevelSelect.Create(self);
  try
    PopupResult := F.ShowModal;
    Success := PopupResult = mrOk;
    LoadAsPack := F.LoadAsPack;
  finally
    F.Free;
  end;

  if PopupResult = mrRetry then
  begin
    CloseScreen(gstReplayTest)
  end else if not Success then
  begin
    GameParams.SetLevel(OldLevel);
    AfterCancelLevelSelect;
  end else begin
    GameParams.ShownText := false;

    if LoadAsPack then
      CloseScreen(gstMenu)
    else
      CloseScreen(gstPreview);
  end;
end;

procedure TGameBaseMenuScreen.ShowConfigMenu;
var
  ConfigDlg: TFormNXConfig;
  OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean;
begin
  OldFullScreen := GameParams.FullScreen;
  OldHighResolution := GameParams.HighResolution;
  OldShowMinimap := GameParams.ShowMinimap;

  ConfigDlg := TFormNXConfig.Create(self);
  try
    ConfigDlg.SetGameParams;
    ConfigDlg.NXConfigPages.TabIndex := 0;
    ConfigDlg.ShowModal;
    ResetWindowSize := ConfigDlg.ResetWindowSize;
    ResetWindowPos := ConfigDlg.ResetWindowPosition;
  finally
    ConfigDlg.Free;
  end;

  // Wise advice from Simon - save these things on exiting the
  // config dialog, rather than waiting for a quit or a screen
  // transition to save them.
  GameParams.Save(scImportant);

  ApplyConfigChanges(OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos);

  DoAfterConfig;
end;

procedure TGameBaseMenuScreen.ApplyConfigChanges(OldFullScreen, OldHighResolution, OldShowMinimap, ResetWindowSize, ResetWindowPos: Boolean);
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

  if GameParams.FullScreen <> OldFullScreen then
  begin
     InitializeImage;
     BuildScreen;
  end;

  if GameParams.ShowMinimap <> OldShowMinimap then
  begin
     InitializeImage;
     BuildScreen;
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

  fDrawInFrontWhenHighlit := true;

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
