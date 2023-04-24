unit GameBaseSkillPanel;

interface

uses
  System.Types,
  Classes, Controls, GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  GameWindowInterface,
  LemAnimationSet, LemMetaAnimation, LemNeoLevelPack, LemProjectile,
  LemCore, LemLemming, LemGame, LemLevel;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TPanelButtonArray = array of TSkillPanelButton;

type
  TFontBitmapArray = array['0'..'9', 0..1] of TBitmap32;

  TBaseSkillPanel = class(TCustomControl)
  private
    fGame                 : TLemmingGame;
    fIconBmp              : TBitmap32;   // for temporary storage
    fShowUsedSkills       : Boolean;

    fSetInitialZoom       : Boolean;

    fRectColor            : TColor32;
    fSelectDx             : Integer;
    fIsBlinkFrame         : Boolean;
    fOnMinimapClick       : TMinimapClickEvent; // event handler for minimap

    fCombineHueShift : Single;

    function CheckFrameSkip: Integer; // Checks the duration since the last click on the panel.

    procedure LoadPanelFont;
    procedure LoadSkillIcons;
    procedure LoadSkillFont;

    function GetLevel: TLevel;
    function GetZoom: Integer;
    procedure SetZoom(NewZoom: Integer);
    function GetMaxZoom: Integer;

    procedure CombineShift(F: TColor32; var B: TColor32; M: TColor32);
    procedure SetShowUsedSkills(const Value: Boolean);
  protected
    fGameWindow           : IGameWindow;
    fButtonRects          : array[TSkillPanelButton] of TRect;

    fImage                : TImage32;  // panel image to be displayed
    fOriginal             : TBitmap32; // original panel image
    fMinimap              : TBitmap32; // full minimap image
    fMinimapImage         : TImage32;  // minimap to be displayed
    fMinimapTemp          : TBitmap32; // temp image, to create fMinimapImage from fMinimap

    fMinimapScrollFreeze  : Boolean;
    fLastClickFrameskip   : Cardinal;

    fSkillFont            : TFontBitmapArray;
    fSkillFontInvert      : TFontBitmapArray;
    fSkillOvercount       : array[100..MAXIMUM_SI] of TBitmap32;
    fSkillCountErase      : TBitmap32;
    fSkillCountEraseInvert: TBitmap32;
    fSkillLock            : TBitmap32;
    fSkillInfinite        : TBitmap32;
    fSkillSelected        : TBitmap32;
    fSkillIcons           : array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of TBitmap32;
    fInfoFont             : array of TBitmap32; {%} { 0..9} {A..Z} // make one of this!

    fHighlitSkill         : TSkillPanelButton;
    fLastHighlitSkill     : TSkillPanelButton; // to avoid sounds when shouldn't be played

    fLastDrawnStr         : String;
    fNewDrawStr           : String;

    // Global stuff
    property Level: TLevel read GetLevel;
    property Game: TLemmingGame read fGame;

    function PanelWidth: Integer; virtual; abstract;
    function PanelHeight: Integer; virtual; abstract;

    // Helper functions for positioning
    function FirstButtonRect: TRect; virtual;
    function ButtonRect(Index: Integer): TRect;
    function HalfButtonRect(Index: Integer; IsUpper: Boolean): TRect;
    function MinimapRect: TRect; virtual; abstract;
    function MinimapWidth: Integer;
    function MinimapHeight: Integer;

    function FirstSkillButtonIndex: Integer; virtual;
    function LastSkillButtonIndex: Integer; virtual;

    // Drawing routines for the buttons and minimap
    procedure ReadBitmapFromStyle;
    function GetButtonList: TPanelButtonArray; virtual; abstract;
    procedure DrawBlankPanel(NumButtons: Integer);
    procedure AddButtonImage(ButtonName: string; Index: Integer);
    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); virtual; abstract;
    procedure SetButtonRects;
    procedure SetSkillIcons;
    procedure DrawHighlight(aButton: TSkillPanelButton); virtual;
    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
    procedure RemoveHighlight(aButton: TSkillPanelButton); virtual;

    // Drawing routines for the info string at the top
    function DrawStringLength: Integer; virtual; abstract;
    function DrawStringTemplate: string; virtual; abstract;

    procedure DrawNewStr;
      function LemmingCountStartIndex: Integer; virtual; abstract;
      function TimeLimitStartIndex: Integer; virtual; abstract;
    procedure CreateNewInfoString; virtual; abstract;
    procedure SetInfoCursorLemming(Pos: Integer);
      function GetSkillString(L: TLemming): String;
    procedure SetInfoLemHatch(Pos: Integer);
    procedure SetInfoLemAlive(Pos: Integer);
    procedure SetInfoLemIn(Pos: Integer);
    procedure SetInfoTime(PosMin, PosSec: Integer);
    procedure SetReplayMark(Pos: Integer);
    procedure SetTimeLimit(Pos: Integer);

    // Event handlers for user interaction and related routines.
    function MousePos(X, Y: Integer): TPoint;
    function MousePosMinimap(X, Y: Integer): TPoint;
    procedure SetMinimapScrollFreeze(aValue: Boolean);

    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;
    procedure ImgMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;
    procedure ImgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;

    procedure MinimapMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;
    procedure MinimapMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;
    procedure MinimapMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual;

    function GetSpawnIntervalValue(aSI: Integer): Integer; // Returns the SI or the equivalent RR, depending on user's settings

  public
    constructor Create(aOwner: TComponent); override;
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); virtual;
    destructor Destroy; override;

    procedure PrepareForGame;
    procedure RefreshInfo;
    procedure SetCursor(aCursor: TCursor);
    procedure SetOnMinimapClick(const Value: TMinimapClickEvent);
    procedure SetGame(const Value: TLemmingGame);

    procedure ResetMinimapPosition;

    property Image: TImage32 read fImage;

    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
    procedure DrawMinimap; virtual;

    property Minimap: TBitmap32 read fMinimap;
    property MinimapScrollFreeze: Boolean read fMinimapScrollFreeze write SetMinimapScrollFreeze;

    property Zoom: Integer read GetZoom write SetZoom;
    property MaxZoom: Integer read GetMaxZoom;

    property FrameSkip: Integer read CheckFrameSkip;
    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
    property ShowUsedSkills: Boolean read fShowUsedSkills write SetShowUsedSkills;
  end;

  procedure ModString(var aString: String; const aNew: String; const aStart: Integer);

const
  NUM_FONT_CHARS = 45;

const
  // WARNING: The order of the strings has to correspond to the one
  //          of TSkillPanelButton in LemCore.pas!
  // As skill icons are dealt with separately, we use a placeholder here
  BUTTON_TO_STRING: array[TSkillPanelButton] of string = (
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    {Skills end here}

    'empty_slot.png',
    'button_rr_plus.png',
    'button_rr_minus.png',
    'button_pause.png',
    'button_rewind.png',
    'button_ff.png',
    'button_restart.png',
    'button_nuke.png',
    'squiggle.png'
    );


implementation

uses
  SysUtils, Math, Windows, UMisc, PngInterface,
  GameControl, GameSound,
  LemTypes, LemReplay, LemStrings, LemNeoTheme,
  LemmixHotkeys;

procedure ModString(var aString: String; const aNew: String; const aStart: Integer);
var
  i: Integer;
begin
  {  Classes, Controls, GR32, GR32_Image, GR32_Layers,}
  for i := 1 to Length(aNew) do
    aString[aStart + i - 1] := aNew[i];
end;


constructor TBaseSkillPanel.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  Create(aOwner);
  fGameWindow := aGameWindow;
end;

constructor TBaseSkillPanel.Create(aOwner: TComponent);
var
  c: Char;
  i: Integer;
  Button: TSkillPanelButton;
begin
  inherited Create(aOwner);

  // Some general settings for the panel
  Color := $000000;
  ParentBackground := false;
  DoubleBuffered := true;

  fLastClickFrameskip := GetTickCount;

  // Initialize images
  fImage := TImage32.Create(Self);
  fImage.Parent := Self;
  fImage.RepaintMode := rmOptimizer;
  fImage.ScaleMode := smScale;

  fMinimapImage := TImage32.Create(Self);
  fMinimapImage.Parent := Self;
  fMinimapImage.RepaintMode := rmOptimizer;
  fMinimapImage.ScaleMode := smScale;
  fMinimapImage.BitmapAlign := baCustom;

  fIconBmp := TBitmap32.Create;
  fIconBmp.DrawMode := dmBlend;
  fIconBmp.CombineMode := cmMerge;

  fMinimapTemp := TBitmap32.Create;
  fMinimap := TBitmap32.Create;

  fOriginal := TBitmap32.Create;

  // Initialize event handlers
  fImage.OnMouseDown := ImgMouseDown;
  fImage.OnMouseMove := ImgMouseMove;
  fImage.OnMouseUp := ImgMouseUp;

  fMinimapImage.OnMouseDown := MinimapMouseDown;
  fMinimapImage.OnMouseMove := MinimapMouseMove;
  fMinimapImage.OnMouseUp := MinimapMouseUp;

  // Create font and skill panel images (but do not yet load them)
  SetLength(fInfoFont, NUM_FONT_CHARS);
  for i := 0 to NUM_FONT_CHARS - 1 do
  begin
    fInfoFont[i] := TBitmap32.Create;
  end;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    fSkillIcons[Button] := TBitmap32.Create;
    fSkillIcons[Button].DrawMode := dmBlend;
    fSkillIcons[Button].CombineMode := cmMerge;
  end;

  for c := '0' to '9' do
    for i := 0 to 1 do
    begin
      fSkillFont[c, i] := TBitmap32.Create;
      fSkillFont[c, i].DrawMode := dmBlend;
      fSkillFont[c, i].CombineMode := cmMerge;

      fSkillFontInvert[c, i] := TBitmap32.Create;
      fSkillFontInvert[c, i].DrawMode := dmBlend;
      fSkillFontInvert[c, i].CombineMode := cmMerge;
    end;

  fSkillInfinite := TBitmap32.Create;
  fSkillInfinite.DrawMode := dmBlend;
  fSkillInfinite.CombineMode := cmMerge;

  fSkillSelected := TBitmap32.Create;
  fSkillSelected.DrawMode := dmBlend;
  fSkillSelected.CombineMode := cmMerge;

  fSkillCountErase := TBitmap32.Create;
  fSkillCountErase.DrawMode := dmBlend;
  fSkillCountErase.CombineMode := cmMerge;

  fSkillCountEraseInvert := TBitmap32.Create;
  fSkillCountEraseInvert.DrawMode := dmBlend;
  fSkillCountEraseInvert.CombineMode := cmMerge;

  fSkillLock := TBitmap32.Create;
  fSkillLock.DrawMode := dmBlend;
  fSkillLock.CombineMode := cmMerge;

  fLastDrawnStr := StringOfChar(' ', DrawStringLength);
  fNewDrawStr := DrawStringTemplate;

  Assert(Length(fNewDrawStr) = DrawStringLength, 'SkillPanel.Create: InfoString has not the correct length.');

  fRectColor := $FFF0D0D0;
  fHighlitSkill := spbNone;
  fLastHighlitSkill := spbNone;

  for i := 100 to MAXIMUM_SI do                    
    fSkillOvercount[i] := TBitmap32.Create;
end;

destructor TBaseSkillPanel.Destroy;
var
  c: Char;
  i: Integer;
  Button: TSkillPanelButton;
begin
  for i := 0 to NUM_FONT_CHARS - 1 do
    fInfoFont[i].Free;

  for c := '0' to '9' do
    for i := 0 to 1 do
    begin
      fSkillFont[c, i].Free;
      fSkillFontInvert[c, i].Free;
    end;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillIcons[Button].Free;

  for i := 100 to MAXIMUM_SI do
    fSkillOvercount[i].Free;

  fSkillInfinite.Free;
  fSkillSelected.Free;
  fSkillCountErase.Free;
  fSkillCountEraseInvert.Free;
  fSkillLock.Free;

  fMinimapTemp.Free;
  fMinimap.Free;

  fOriginal.Free;

  fImage.Free;
  fMinimapImage.Free;
  fIconBmp.Free;
  inherited;
end;

{-----------------------------------------
    Positions of buttons, ...
-----------------------------------------}
function TBaseSkillPanel.FirstButtonRect: TRect;
begin
  Result := Rect(1 * ResMod, 16 * ResMod, 15 * ResMod, 38 * ResMod);
end;

function TBaseSkillPanel.ButtonRect(Index: Integer): TRect;
begin
  Result := FirstButtonRect;
  OffsetRect(Result, Index * 16 * ResMod, 0);
end;

function TBaseSkillPanel.HalfButtonRect(Index: Integer; IsUpper: Boolean): TRect;
begin
  Result := FirstButtonRect;
  OffsetRect(Result, Index * 16 * ResMod, 0);
  if IsUpper then
    Result.Bottom := (Result.Top + Result.Bottom) div 2 - ResMod
  else
    Result.Top := (Result.Top + Result.Bottom) div 2 + ResMod;
end;

function TBaseSkillPanel.FirstSkillButtonIndex: Integer;
begin
  Result := 2;
end;

function TBaseSkillPanel.LastSkillButtonIndex: Integer;
begin
  Result := (FirstSkillButtonIndex + MAX_SKILL_TYPES_PER_LEVEL) - 1;
end;

function TBaseSkillPanel.MinimapWidth: Integer;
begin
  Result := MinimapRect.Right - MinimapRect.Left;
end;

function TBaseSkillPanel.MinimapHeight: Integer;
begin
  Result := MinimapRect.Bottom - MinimapRect.Top;
end;


{-----------------------------------------------
  Draw the initial skill panel and the minimap
-----------------------------------------------}
procedure GetGraphic(aName: String; aDst: TBitmap32);
var
  MaskColor: TColor32;
  SrcFile, SrcFileHr, SrcFileHrMask: String;
  Target: TNeoLevelGroup;

  UpscaleSettings: TUpscaleSettings;
begin
  Target := GameParams.CurrentLevel.Group;

  SrcFile := Target.Path + aName;
  if GameParams.HighResolution then
  begin
    SrcFileHr := ChangeFileExt(SrcFile, '-hr.png');
    SrcFileHrMask := ChangeFileExt(SrcFile, '_mask-hr.png');
  end;

  while not (FileExists(SrcFile) or Target.IsBasePack or (Target.Parent = nil)) do
  begin
    Target := Target.Parent;
    SrcFile := Target.Path + aName;
    if GameParams.HighResolution then
    begin
      SrcFileHr := ChangeFileExt(SrcFile, '-hr.png');
      SrcFileHrMask := ChangeFileExt(SrcFile, '_mask-hr.png');
    end;
  end;

  if not FileExists(SrcFile) then
  begin
    SrcFile := AppPath + SFGraphicsPanel + aName;
    if GameParams.HighResolution then
    begin
      SrcFileHr := AppPath + SFGraphicsPanelHighRes + aName;
      SrcFileHrMask := AppPath + SFGraphicsPanelHighRes + ChangeFileExt(aName, '_mask.png');
    end;
  end;

  MaskColor := GameParams.Renderer.Theme.Colors[MASK_COLOR];

  if GameParams.HighResolution then
  begin
    if FileExists(SrcFileHr) then
    begin
      TPngInterface.LoadPngFile(SrcFileHr, aDst);
      TPngInterface.MaskImageFromFile(aDst, SrcFileHrMask, MaskColor);
    end else begin
      TPngInterface.LoadPngFile(SrcFile, aDst);
      TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(SrcFile, '_mask.png'), MaskColor);

      UpscaleSettings.Mode := umPixelArt;
      UpscaleSettings.LeftSide := uebTransparent;
      UpscaleSettings.TopSide := uebTransparent;
      UpscaleSettings.RightSide := uebTransparent;
      UpscaleSettings.BottomSide := uebTransparent;

      Upscale(aDst, UpscaleSettings);
    end;
  end else begin
    TPngInterface.LoadPngFile(SrcFile, aDst);
    TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(SrcFile, '_mask.png'), MaskColor);
  end;
end;

// Pave the area of NumButtons buttons with the blank panel
procedure TBaseSkillPanel.DrawBlankPanel(NumButtons: Integer);
var
  i: Integer;
  BlankPanel: TBitmap32;
  SrcRect, DstRect: TRect;
  SrcWidth: Integer;
begin
  BlankPanel := TBitmap32.Create;
  BlankPanel.DrawMode := dmBlend;
  BlankPanel.CombineMode := cmMerge;
  GetGraphic('button.png', BlankPanel);

  SrcRect := BlankPanel.BoundsRect;
  SrcWidth := SrcRect.Right - SrcRect.Left;
  DstRect := BlankPanel.BoundsRect;
  OffsetRect(DstRect, FirstButtonRect.Left, FirstButtonRect.Top);

  // Draw full panels
  for i := 1 to (NumButtons * (16 * ResMod) - 1) div SrcWidth do
  begin
    BlankPanel.DrawTo(fOriginal, DstRect, SrcRect);
    OffsetRect(DstRect, SrcWidth, 0);
  end;

  // Draw partial panel at the end
  DstRect.Right := ButtonRect(NumButtons - 1).Right + ResMod;
  DstRect.Bottom := ButtonRect(NumButtons - 1).Bottom + ResMod;
  SrcRect.Right := SrcRect.Left - DstRect.Left + DstRect.Right;
  SrcRect.Bottom := SrcRect.Top - DstRect.Top + DstRect.Bottom;
  BlankPanel.DrawTo(fOriginal, DstRect, SrcRect);

  BlankPanel.Free;
end;

procedure TBaseSkillPanel.AddButtonImage(ButtonName: string; Index: Integer);
begin
  if (Index >= FirstSkillButtonIndex) and (Index <= LastSkillButtonIndex) then Exit; // otherwise, "empty_slot.png" placeholder causes some graphical glitches
  GetGraphic(ButtonName, fIconBmp);
  fIconBmp.DrawTo(fOriginal, ButtonRect(Index).Left, ButtonRect(Index).Top);
end;

procedure TBaseSkillPanel.LoadPanelFont;
var
  SrcRect: TRect;
  i: Integer;
begin
  // Load first the characters
  GetGraphic('panel_font.png', fIconBmp);
  SrcRect := Rect(0, 0, 8 * ResMod, 16 * ResMod);
  for i := 0 to 37 do
  begin
    fInfoFont[i].SetSize(8 * ResMod, 16 * ResMod);
    fIconBmp.DrawTo(fInfoFont[i], 0, 0, SrcRect);
    OffsetRect(SrcRect, 8 * ResMod, 0);
  end;

  // Load now the icons for the text panel
  GetGraphic('panel_icons.png', fIconBmp);
  SrcRect := Rect(0, 0, 12 * ResMod, 16 * ResMod);
  for i := 38 to NUM_FONT_CHARS - 1 do
  begin
    fInfoFont[i].SetSize(12 * ResMod, 16 * ResMod);
    fIconBmp.DrawTo(fInfoFont[i], 0, 0, SrcRect);
    OffsetRect(SrcRect, 12 * ResMod, 0);
  end;
end;

procedure TBaseSkillPanel.LoadSkillIcons;
const
  PANEL_FALLBACK_BRICK_COLOR = $FF00B000;
var
  BrickColor: TColor32;
  Button: TSkillPanelButton;
  TempBmp: TBitmap32;
  x, y: Integer;

  procedure DrawAnimationFrame(dst: TBitmap32; aAnimationIndex: Integer; aFrame: Integer; footX, footY: Integer);
  var
    Ani: TBaseAnimationSet;
    Meta: TMetaLemmingAnimation;
    SrcRect: TRect;
    OldDrawMode: TDrawMode;
  begin
    Ani := GameParams.Renderer.LemmingAnimations;
    Meta := Ani.MetaLemmingAnimations[aAnimationIndex];

    SrcRect := Ani.LemmingAnimations[aAnimationIndex].BoundsRect;
    SrcRect.Bottom := SrcRect.Bottom div Meta.FrameCount;
    SrcRect.Offset(0, SrcRect.Height * aFrame);

    OldDrawMode := Ani.LemmingAnimations[aAnimationIndex].DrawMode;
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := dmBlend;
    Ani.LemmingAnimations[aAnimationIndex].DrawTo(dst, footX * ResMod - Meta.FootX, footY * ResMod - Meta.FootY, SrcRect);
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := OldDrawMode;
  end;

  procedure DrawAnimationFrameResized(dst: TBitmap32; aAnimationIndex: Integer; aFrame: Integer; dstRect: TRect);
  var
    Ani: TBaseAnimationSet;
    Meta: TMetaLemmingAnimation;
    SrcRect: TRect;
    OldDrawMode: TDrawMode;
  begin
    if GameParams.HighResolution then
    begin
      dstRect.Left := dstRect.Left * 2 + 1;
      dstRect.Top := dstRect.Top * 2;
      dstRect.Right := dstRect.Right * 2 + 1;
      dstRect.Bottom := dstRect.Bottom * 2;
    end;

    Ani := GameParams.Renderer.LemmingAnimations;
    Meta := Ani.MetaLemmingAnimations[aAnimationIndex];

    SrcRect := Ani.LemmingAnimations[aAnimationIndex].BoundsRect;
    SrcRect.Bottom := SrcRect.Bottom div Meta.FrameCount;
    SrcRect.Offset(0, SrcRect.Height * aFrame);

    OldDrawMode := Ani.LemmingAnimations[aAnimationIndex].DrawMode;
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := dmBlend;
    Ani.LemmingAnimations[aAnimationIndex].DrawTo(dst, dstRect, SrcRect);
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := OldDrawMode;
  end;

  procedure DrawBrick(dst: TBitmap32; X, Y: Integer; W: Integer = 2);
  var
    oX: Integer;
  begin
    for oX := 0 to W-1 do
      if GameParams.HighResolution then
      begin
        dst.PixelS[(X + oX) * ResMod, Y * ResMod] := BrickColor;
        dst.PixelS[(X + oX) * ResMod + 1, Y * ResMod] := BrickColor;
        dst.PixelS[(X + oX) * ResMod, Y * ResMod + 1] := BrickColor;
        dst.PixelS[(X + oX) * ResMod + 1, Y * ResMod + 1] := BrickColor;
      end else
        dst.PixelS[X + oX, Y] := BrickColor;
  end;

  procedure Outline(dst: TBitmap32; isRecursive: Boolean = false);
  var
    x, y: Integer;
    oX, oY: Integer;
    ThisAlpha, MaxAlpha: Byte;
    OutlineColor: TColor32;
  begin
    TempBmp.Assign(dst);
    dst.Clear(0);
    TempBmp.WrapMode := wmClamp;
    TempBmp.OuterColor := $00000000;

    if GameParams.Renderer.Theme.DoesColorExist('PANEL_OUTLINE') then
      OutlineColor := GameParams.Renderer.Theme.Colors['PANEL_OUTLINE'] and $FFFFFF
    else
      OutlineColor := $000000;

    for y := 0 to TempBmp.Height-1 do
      for x := 0 to TempBmp.Width-1 do
      begin
        MaxAlpha := 0;
        for oY := -1 to 1 do
          for oX := -1 to 1 do
          begin
            if Abs(oY) + Abs(oX) <> 1 then
              Continue;
            ThisAlpha := (TempBmp.PixelS[x + oX, y + oY] and $FF000000) shr 24;
            if ThisAlpha > MaxAlpha then
              MaxAlpha := ThisAlpha;
          end;
        dst[x, y] := (MaxAlpha shl 24) or OutlineColor;
      end;

    TempBmp.DrawTo(dst);

    if GameParams.HighResolution and not isRecursive then
      Outline(dst, true);
  end;

  procedure DrawMiscBmp(Src, Dst: TBitmap32; dstX, dstY: Integer; SrcRect: TRect);
  begin
    if GameParams.HighResolution then
    begin
      dstX := dstX * 2;
      dstY := dstY * 2;
      SrcRect.Left := SrcRect.Left * 2;
      SrcRect.Top := SrcRect.Top * 2;
      SrcRect.Right := SrcRect.Right * 2;
      SrcRect.Bottom := SrcRect.Bottom * 2;
    end;

    Src.DrawTo(Dst, dstX, dstY, SrcRect);
  end;

begin
  // Load the erasing icon and selection outline first
  GetGraphic('skill_count_erase.png', fSkillCountErase);
  GetGraphic('skill_selected.png', fSkillSelected);

  fSkillCountEraseInvert.Assign(fSkillCountErase);
  for y := 0 to fSkillCountEraseInvert.Height-1 do
    for x := 0 to fSkillCountEraseInvert.Width-1 do
      fSkillCountEraseInvert[x, y] := fSkillCountEraseInvert[x, y] xor $00FFFFFF; // don't invert alpha

  TempBmp := TBitmap32.Create; // freely useable as long as Outline isn't called while it's being used
  try
    // Some preparation
    TempBmp.DrawMode := dmBlend;
    TempBmp.CombineMode := cmMerge;

    BrickColor := GameParams.Renderer.Theme.Colors['MASK'];
    if (BrickColor and $00C0C0C0) = 0 then
      BrickColor := PANEL_FALLBACK_BRICK_COLOR; // Prevent too-dark colors being used, that won't contrast well with outline

    // Set image sizes
    for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      fSkillIcons[Button].SetSize(15 * ResMod, 23 * ResMod);

    //////////////////////////////////////////////////////////
    ///  This code is mostly copied to LemGadgetAnimation. ///
    //////////////////////////////////////////////////////////

    // Walker, Jumper, Shimmier, Slider, Climber, - all simple
    DrawAnimationFrame(fSkillIcons[spbWalker], WALKING, 1, 6, 21);
    DrawAnimationFrame(fSkillIcons[spbJumper], JUMPING, 0, 6, 20);
    DrawAnimationFrame(fSkillIcons[spbShimmier], SHIMMYING, 1, 7, 20);
    DrawAnimationFrame(fSkillIcons[spbSlider], SLIDING_RTL, 0, 5, 21);
    DrawAnimationFrame(fSkillIcons[spbClimber], CLIMBING, 3, 10, 22);

    // Swimmer - we need to draw the background water
    DrawAnimationFrame(fSkillIcons[spbSwimmer], SWIMMING, 2, 8, 19);
    Outline(fSkillIcons[spbSwimmer]);
    TempBmp.Assign(fSkillIcons[spbSwimmer]);
    fSkillIcons[spbSwimmer].Clear(0);
    fSkillIcons[spbSwimmer].FillRect(0, 17 * ResMod, 15 * ResMod, 23 * ResMod, $FF000000);
    fSkillIcons[spbSwimmer].FillRect(0, 18 * ResMod, 15 * ResMod, 23 * ResMod, $FF0000FF);
    TempBmp.DrawTo(fSkillIcons[spbSwimmer]);

    // Floater, Glider, Disarmer - all simple
    DrawAnimationFrame(fSkillIcons[spbFloater], UMBRELLA, 4, 7, 26);
    DrawAnimationFrame(fSkillIcons[spbGlider], GLIDING, 4, 7, 26);
    DrawAnimationFrame(fSkillIcons[spbDisarmer], FIXING, 6, 4, 21);

    //Timebomber has its own graphic
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsPanelHighRes + 'icon_timebomber.png', fIconBMP)
    else
      TPngInterface.LoadPngFile(AppPath + SFGraphicsPanel + 'icon_timebomber.png', fIconBMP);

      fIconBmp.DrawTo(fSkillIcons[spbTimebomber], -1 * ResMod, 8 * ResMod);

    // Bomber is drawn resized
    DrawAnimationFrameResized(fSkillIcons[spbBomber], EXPLOSION, 0, Rect(-2, 7, 15, 24));

    // Freezer is tricky - the goal is an outlined frozen lemming over a freezer explosion graphic
    // Explosion graphic currently commented out
    DrawAnimationFrame(fSkillIcons[spbFreezer], FROZEN, 0, 8, 21);
    Outline(fSkillIcons[spbFreezer]);
    TempBmp.Assign(fSkillIcons[spbFreezer]);
    fSkillIcons[spbFreezer].Clear(0);
    //DrawAnimationFrameResized(fSkillIcons[spbFreezer], FREEZEREXPLOSION, 0, Rect(-2, 7, 15, 24));
    TempBmp.DrawTo(fSkillIcons[spbFreezer], 0, 0);

    // Blocker is simple
    DrawAnimationFrame(fSkillIcons[spbBlocker], BLOCKING, 0, 7, 21);

    // Platformer, Builder and Stacker have bricks drawn to clarify the direction of building.
    // Platformer additionally has some extra black pixels drawn in to make the outline nicer.
    DrawAnimationFrame(fSkillIcons[spbPlatformer], PLATFORMING, 1, 7, 20);
    fSkillIcons[spbPlatformer].FillRect(2 * ResMod, 21 * ResMod, 12 * ResMod, 22 * ResMod, $FF000000);
    DrawBrick(fSkillIcons[spbPlatformer], 2, 21);
    DrawBrick(fSkillIcons[spbPlatformer], 5, 21);
    DrawBrick(fSkillIcons[spbPlatformer], 8, 21);
    DrawBrick(fSkillIcons[spbPlatformer], 11, 21);

    DrawAnimationFrame(fSkillIcons[spbBuilder], BRICKLAYING, 1, 7, 20);
    DrawBrick(fSkillIcons[spbBuilder], 4, 22);
    DrawBrick(fSkillIcons[spbBuilder], 6, 21);
    DrawBrick(fSkillIcons[spbBuilder], 8, 20);
    DrawBrick(fSkillIcons[spbBuilder], 10, 19);

    DrawAnimationFrame(fSkillIcons[spbStacker], STACKING, 0, 7, 21);
    DrawBrick(fSkillIcons[spbStacker], 10, 20);
    DrawBrick(fSkillIcons[spbStacker], 10, 19);
    DrawBrick(fSkillIcons[spbStacker], 10, 18);
    DrawBrick(fSkillIcons[spbStacker], 10, 17);

    // Projectiles are messy.
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'projectiles-hr.png', TempBMP)
    else
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'projectiles.png', TempBMP);

    DoProjectileRecolor(TempBMP, BrickColor);

    DrawMiscBmp(TempBMP, fSkillIcons[spbSpearer], 2, 8, PROJECTILE_GRAPHIC_RECTS[pgSpearSlightBLTR]);
    DrawMiscBmp(TempBMP, fSkillIcons[spbGrenader], 10, 8, PROJECTILE_GRAPHIC_RECTS[pgGrenade]);

    DrawAnimationFrame(fSkillIcons[spbSpearer], THROWING, 2, 6, 21);
    DrawAnimationFrame(fSkillIcons[spbGrenader], THROWING, 3, 3, 21);

    // Laserer, Basher, Fencer, Miner are all simple - we do have to take care to avoid frames with destruction particles
    // For Digger, we just have to accept some particles.
    DrawAnimationFrame(fSkillIcons[spbLaserer], LASERING, 0, 8, 21);
    DrawAnimationFrame(fSkillIcons[spbBasher], BASHING, 0, 8, 21);
    DrawAnimationFrame(fSkillIcons[spbFencer], FENCING, 1, 7, 21);
    DrawAnimationFrame(fSkillIcons[spbMiner], MINING, 12, 4, 21);
    DrawAnimationFrame(fSkillIcons[spbDigger], DIGGING, 4, 7, 21);

    // And finally, outline everything. We generate the cloner after this, as it makes use of
    // the post-outlined Walker graphic.
    for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if not (Button in [spbSwimmer, spbCloner]) then
        Outline(fSkillIcons[Button]);
        // Swimmer and Cloner are already outlined during their generation.

    // Cloner is drawn as two back-to-back walkers, individually outlined.
    DrawAnimationFrame(fSkillIcons[spbCloner], WALKING_RTL, 1, 6, 21);
    Outline(fSkillIcons[spbCloner]);
    TempBmp.Assign(fSkillIcons[spbWalker]);
    TempBmp.DrawTo(fSkillIcons[spbCloner], 2, 0); // We want it drawn 2px to the right of where it is in the walker icon
  finally
    TempBmp.Free;
  end;
end;

procedure TBaseSkillPanel.LoadSkillFont;
var
  c: Char;
  i: Integer;
  SrcRect: TRect;
  TempBmp: TBitmap32;
  x, y: Integer;

  procedure MakeOvercountImage(aCount: Integer);
  var
    CountStr: String;
  begin
    TempBmp.Clear(0);
    CountStr := LeadZeroStr(aCount, 3); // just in case
    fSkillFont[CountStr[1], 1].DrawTo(TempBmp, 0, 0, Rect(0, 0, 4 * ResMod, 8 * ResMod));
    fSkillFont[CountStr[2], 1].DrawTo(TempBmp, 4 * ResMod, 0, Rect(0, 0, 4 * ResMod, 8 * ResMod));
    fSkillFont[CountStr[3], 1].DrawTo(TempBmp, 8 * ResMod, 0, Rect(0, 0, 4 * ResMod, 8 * ResMod));
  end;

begin
  GetGraphic('skill_count_digits.png', fIconBmp);
  SrcRect := Rect(0, 0, 4 * ResMod, 8 * ResMod);
  for c := '0' to '9' do
  begin
    for i := 0 to 1 do
    begin
      fSkillFont[c, i].SetSize(8 * ResMod, 8 * ResMod);
      fIconBmp.DrawTo(fSkillFont[c, i], (4 - 4 * i)  * ResMod, 0, SrcRect);

      fSkillFontInvert[c, i].Assign(fSkillFont[c, i]);
      for y := 0 to fSkillFontInvert[c, i].Height-1 do
        for x := 0 to fSkillFontInvert[c, i].Width-1 do
          fSkillFontInvert[c, i][x, y] := fSkillFontInvert[c,i][x,y] xor $00FFFFFF; // don't invert alpha
    end;
    OffsetRect(SrcRect, 4 * ResMod, 0);
  end;

  Inc(SrcRect.Right, 4 * ResMod); // Position is correct at this point, but Infinite symbol is 8px wide not 4px
  fSkillInfinite.SetSize(8 * ResMod, 8 * ResMod);
  fIconBmp.DrawTo(fSkillInfinite, 0, 0, SrcRect);

  OffsetRect(SrcRect, 8 * ResMod, 0);
  fSkillLock.SetSize(8 * ResMod, 8 * ResMod);
  fIconBmp.DrawTo(fSkillLock, 0, 0, SrcRect);

  TempBmp := TBitmap32.Create;
  TKernelResampler.Create(TempBmp);
  TKernelResampler(TempBmp.Resampler).Kernel := TCubicKernel.Create;
  try
    TempBMP.SetSize(12 * ResMod, 8 * ResMod);
    for i := 100 to MAXIMUM_SI do
    begin
      MakeOvercountImage(i);
      fSkillOvercount[i].SetSize(9 * ResMod, 8 * ResMod);
      TempBMP.DrawTo(fSkillOvercount[i], fSkillOvercount[i].BoundsRect, TempBMP.BoundsRect);
    end;
  finally
    TempBMP.Free;
  end;
end;


procedure TBaseSkillPanel.ReadBitmapFromStyle;
var
  ButtonList: TPanelButtonArray;
  MinimapRegion : TBitmap32;
  i: Integer;

  procedure SwapSIButtons;
  var
    SlowerIndex: Integer;
    FasterIndex: Integer;
    i: Integer;
  begin
    // We want to swap the order of + and - when displaying release rate
    if GameParams.SpawnInterval and not GameParams.ClassicMode then Exit;

    SlowerIndex := -1;
    FasterIndex := -1;

    for i := 0 to Length(ButtonList)-1 do
      if ButtonList[i] = spbSlower then
        SlowerIndex := i
      else if ButtonList[i] = spbFaster then
        FasterIndex := i;

    if (SlowerIndex = -1) or (FasterIndex = -1) then Exit;

    ButtonList[SlowerIndex] := spbFaster;
    ButtonList[FasterIndex] := spbSlower;
  end;
begin
  fOriginal.SetSize(PanelWidth, PanelHeight);
  fOriginal.Clear($FF000000);

  // Get array of buttons to draw
  ButtonList := GetButtonList;
  Assert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

  // Draw empty panel
  DrawBlankPanel(Length(ButtonList));


  // Draw single buttons icons
  SwapSIButtons;
  for i := 0 to Length(ButtonList) - 1 do
    AddButtonImage(BUTTON_TO_STRING[ButtonList[i]], i);

  // Draw minimap region
  if GameParams.ShowMinimap then
  begin
    MinimapRegion := TBitmap32.Create;
    GetGraphic('minimap_region.png', MinimapRegion);
    ResizeMinimapRegion(MinimapRegion);
    MinimapRegion.DrawTo(fOriginal, MinimapRect.Left - (3 * ResMod), MinimapRect.Top - (2 * ResMod));
    MinimapRegion.Free;
  end;

  // Copy the created bitmap
  fImage.Bitmap.Assign(fOriginal);
  fImage.Bitmap.Changed;

  // Load the remaining graphics for icons, ...
  LoadPanelFont;
  LoadSkillIcons;
  LoadSkillFont;
end;

procedure TBaseSkillPanel.PrepareForGame;
begin
  // Sets game-dependant properties of the skill panel:
  // Size of the minimap, style, scaling factor, skills on the panel, ...
  fImage.BeginUpdate;

  Minimap.SetSize(Level.Info.Width div 8 * ResMod, Level.Info.Height div 8 * ResMod);

  ReadBitmapFromStyle;
  SetButtonRects;
  SetSkillIcons;

  fImage.EndUpdate;
  fImage.Changed;
  Invalidate;
end;

procedure TBaseSkillPanel.SetShowUsedSkills(const Value: Boolean);
begin
  fShowUsedSkills := Value;
  RefreshInfo;
end;

procedure TBaseSkillPanel.SetSkillIcons;
var
  ButtonIndex: Integer;
  ButRect: TRect;
  Skill: TSkillPanelButton;
  EmptySlot: TBitmap32;
begin
  ButtonIndex := FirstSkillButtonIndex;
  for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    if Skill in Level.Info.Skillset then
    begin
      ButRect := ButtonRect(ButtonIndex);
      Inc(ButtonIndex);

      fButtonRects[Skill] := ButRect;
      fSkillIcons[Skill].DrawTo(fImage.Bitmap, ButRect.Left, ButRect.Top);
      fSkillIcons[Skill].DrawTo(fOriginal, ButRect.Left, ButRect.Top);
    end;
  end;

  if ButtonIndex <= LastSkillButtonIndex then
  begin
    EmptySlot := TBitmap32.Create;
    try
      GetGraphic('empty_slot.png', EmptySlot);
      EmptySlot.DrawMode := dmBlend;
      EmptySlot.CombineMode := cmMerge;
      while ButtonIndex <= LastSkillButtonIndex do
      begin
        ButRect := ButtonRect(ButtonIndex);
        Inc(ButtonIndex);
        fImage.Bitmap.FillRectS(ButRect, $FF000000);
        fOriginal.FillRectS(ButRect, $FF000000);
        EmptySlot.DrawTo(fImage.Bitmap, ButRect.Left, ButRect.Top);
        EmptySlot.DrawTo(fOriginal, ButRect.Left, ButRect.Top);
      end;
    finally
      EmptySlot.Free;
    end;
  end;
end;

procedure TBaseSkillPanel.SetButtonRects;
var
  ButtonList: TPanelButtonArray;
  Button: TSkillPanelButton;
  i : Integer;
begin
  // Set all to never reached rectangles
  for Button := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    fButtonRects[Button] := Rect(-1, -1, 0, 0);

  ButtonList := GetButtonList;
  Assert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

  //Set only rectangles for non-skill buttons
  //The skill buttons are dealt with in SetSkillIcons
  for i := 0 to Length(ButtonList) - 1 do
  begin
    if ButtonList[i] > spbNone then
    fButtonRects[ButtonList[i]] := ButtonRect(i);
  end;
end;

procedure TBaseSkillPanel.DrawMinimap;
var
  BaseOffsetHoriz, BaseOffsetVert: Double;
  OH, OV: Double;
  ViewRect: TRect;
  InnerViewRect: TRect;
begin
if GameParams.ShowMinimap then
  begin
    if Parent = nil then Exit;

    // Add some space for when the viewport rect lies on the very edges
    fMinimapTemp.SetSize(fMinimap.Width + 2 * ResMod, fMinimap.Height + 2 * ResMod);
    fMinimapTemp.Clear(0);
    fMinimap.DrawTo(fMinimapTemp, 1 * ResMod, 1 * ResMod);

    BaseOffsetHoriz := fGameWindow.ScreenImage.OffsetHorz / fGameWindow.ScreenImage.Scale / 8;
    BaseOffsetVert := fGameWindow.ScreenImage.OffsetVert / fGameWindow.ScreenImage.Scale / 8;

    // Draw the visible area frame
    ViewRect := Rect(0, 0, fGameWindow.DisplayWidth div 8 + 2, fGameWindow.DisplayHeight div 8 + 2);
    OffsetRect(ViewRect, -Round(BaseOffsetHoriz), -Round(BaseOffsetVert));
    fMinimapTemp.FrameRectS(ViewRect, fRectColor);

    if GameParams.HighResolution then
      begin
        InnerViewRect := ViewRect;
        Inc(InnerViewRect.Left);
        Inc(InnerViewRect.Top);
        Dec(InnerViewRect.Bottom);
        Dec(InnerViewRect.Right);
        fMinimapTemp.FrameRectS(InnerViewRect, fRectColor);
      end;

    fMinimapImage.Bitmap.Assign(fMinimapTemp);

    if not fMinimapScrollFreeze then
      begin
        if fMinimapTemp.Width < MinimapWidth then
        OH := (MinimapWidth - fMinimapTemp.Width) / 2
      else begin
        OH := BaseOffsetHoriz + (MinimapWidth - RectWidth(ViewRect)) / 2;
        OH := Min(Max(OH, MinimapWidth - fMinimapTemp.Width), 0);
      end;

      if fMinimapTemp.Height < MinimapHeight then
        OV := (MinimapHeight - fMinimapTemp.Height) / 2
      else begin
        OV := BaseOffsetVert + (MinimapHeight - RectHeight(ViewRect)) / 2;
        OV := Min(Max(OV, MinimapHeight - fMinimapTemp.Height), 0);
      end;

      fMinimapImage.OffsetHorz := OH * fMinimapImage.Scale;
      fMinimapImage.OffsetVert := OV * fMinimapImage.Scale;
    end;

    fMinimapImage.Changed;
  end;
end;

procedure TBaseSkillPanel.DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
var
  ButtonPos: Integer;
  MagicFrequency: Single;
begin
  if fGameWindow.IsHyperSpeed then Exit;
  if aButton = spbNone then Exit;
  if (aButton <= LAST_SKILL_BUTTON) then
  begin
    ButtonPos := Game.GetSelectedSkill + 1;

                   //pitch             //this makes sure the interval is 1 semitone
    MagicFrequency := 6900 * (IntPower(1.06, ButtonPos));
                   //matches Amiga - lower might be better for levels with more skills?
    if (fLastHighlitSkill <> spbNone) and (fLastHighlitSkill <> fHighlitSkill) then
    SoundManager.PlaySound(SFX_SKILLBUTTON, 0, MagicFrequency);
    if (fHighlitSkill = aButton) and Highlight then Exit;
    if (fHighlitSkill = spbNone) and not Highlight then Exit;
  end;
  if fButtonRects[aButton].Left <= 0 then Exit;

  RemoveHighlight(aButton);
  if Highlight then
    DrawHighlight(aButton);
end;

procedure TBaseSkillPanel.DrawHighlight(aButton: TSkillPanelButton);
var
  BorderRect: TRect;
begin
  if aButton <= LAST_SKILL_BUTTON then // we don't want to memorize this for eg. fast forward
  begin
    BorderRect := fButtonRects[aButton];
    fHighlitSkill := aButton;
  end else
  BorderRect := fButtonRects[aButton];

  Inc(BorderRect.Right, ResMod);
  Inc(BorderRect.Bottom, ResMod * 2);

  DrawNineSlice(Image.Bitmap, BorderRect, fSkillSelected.BoundsRect, Rect(3 * ResMod, 3 * ResMod, 3 * ResMod, 3 * ResMod), fSkillSelected);
end;

procedure TBaseSkillPanel.RemoveHighlight(aButton: TSkillPanelButton);
var
  BorderRect, EraseRect: TRect;
begin
  if aButton <= LAST_SKILL_BUTTON then
  begin
    BorderRect := fButtonRects[fHighlitSkill];
    fLastHighlitSkill := fHighlitSkill;
    fHighlitSkill := spbNone;
  end else
    BorderRect := fButtonRects[aButton];

  Inc(BorderRect.Right, ResMod);
  Inc(BorderRect.Bottom, 2 * ResMod);

  fOriginal.DrawTo(Image.Bitmap, BorderRect, BorderRect);
  Exit;

  // top
  EraseRect := BorderRect;
  EraseRect.Bottom := EraseRect.Top + 1 * ResMod;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // left
  EraseRect := BorderRect;
  EraseRect.Right := EraseRect.Left + 1 * ResMod;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // right
  EraseRect := BorderRect;
  EraseRect.Left := EraseRect.Right - 1 * ResMod;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // bottom
  EraseRect := BorderRect;
  EraseRect.Top := EraseRect.Bottom - 1 * ResMod;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);
end;



procedure TBaseSkillPanel.ResetMinimapPosition;
begin
  fMinimapImage.Left := MinimapRect.Left * Trunc(fMinimapImage.Scale) + Image.Left;
  fMinimapImage.Top := MinimapRect.Top * Trunc(fMinimapImage.Scale);
end;

procedure TBaseSkillPanel.DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
var
  ButtonLeft, ButtonTop: Integer;
  NumberStr: string;

  EraseBMP: TBitmap32;
  FontBMP: TFontBitmapArray;
  // Don't need variables for Infinite, Lock or Overcount as they're never used in inverted form

  IsRegularSkill: Boolean;
begin
  if fButtonRects[aButton].Left < 0 then Exit;
  if fGameWindow.IsHyperSpeed then Exit;

  IsRegularSkill := aButton <= LAST_SKILL_BUTTON;

  if IsRegularSkill and fShowUsedSkills then
  begin
    if aNumber > 99 then aNumber := 99;
    EraseBMP := fSkillCountEraseInvert;
    FontBMP := fSkillFontInvert;
  end else begin
    EraseBMP := fSkillCountErase;
    FontBMP := fSkillFont;
  end;

  ButtonLeft := fButtonRects[aButton].Left;
  ButtonTop := fButtonRects[aButton].Top;

  // Erase previous number
  EraseBMP.DrawTo(fImage.Bitmap, ButtonLeft, ButtonTop);
  if IsRegularSkill and (aNumber = 0) and not fShowUsedSkills then Exit;

  if (aButton = spbFaster) and (Level.Info.SpawnIntervalLocked or (Level.Info.SpawnInterval = MINIMUM_SI)) then
    fSkillLock.DrawTo(fImage.Bitmap, ButtonLeft + 3 * ResMod, ButtonTop + 1 * ResMod)
  else if (aNumber > 99) then
  begin
    if (aButton <= LAST_SKILL_BUTTON) then
      fSkillInfinite.DrawTo(fImage.Bitmap, ButtonLeft + 3 * ResMod, ButtonTop + 1 * ResMod)
    else
      fSkillOvercount[aNumber].DrawTo(fImage.Bitmap, ButtonLeft + 3 * ResMod, ButtonTop + 1 * ResMod);
  end else if aNumber < 10 then
  begin
    NumberStr := LeadZeroStr(aNumber, 2);
    FontBMP[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 1 * ResMod, ButtonTop + 1 * ResMod);
  end else begin
    NumberStr := LeadZeroStr(aNumber, 2);
    FontBMP[NumberStr[1], 1].DrawTo(fImage.Bitmap, ButtonLeft + 3 * ResMod, ButtonTop + 1 * ResMod);
    FontBMP[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 3 * ResMod, ButtonTop + 1 * ResMod);
  end;
end;

{-----------------------------------------
    Info string at top
-----------------------------------------}
procedure TBaseSkillPanel.CombineShift(F: TColor32; var B: TColor32; M: TColor32);
var
  H, S, V: Single;
begin
  if AlphaComponent(F) = 0 then Exit;
  RGBToHSV(F, H, S, V);
  H := H + fCombineHueShift;
  B := HSVToRGB(H, S, V);
end;

procedure TBaseSkillPanel.DrawNewStr;
var
  New: char;
  i, CharID: integer;
  SpecialCombine: Boolean;

  LemmingKinds: TLemmingKinds;
begin
  LemmingKinds := Game.ActiveLemmingTypes;

  // Erase previous text there
  fImage.Bitmap.FillRectS(0, 0, DrawStringLength * 8 * ResMod, 16 * ResMod, $00000000);

  for i := 1 to DrawStringLength do
  begin
    New := fNewDrawStr[i];

    case New of
      '%':        CharID := 0;
      '0'..'9':   CharID := ord(New) - ord('0') + 1;
      '-':        CharID := 11;
      'A'..'Z':   CharID := ord(New) - ord('A') + 12;
      #91 .. #97: CharID := ord(New) - ord('A') + 12;
    else CharID := -1;
    end;

    if (CharID >= 0) then
    begin
      if (i > LemmingCountStartIndex) and (i <= LemmingCountStartIndex + 4) then
      begin
        if Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead < Level.Info.RescueCount - Game.LemmingsSaved then
        begin
          SpecialCombine := true;
          fCombineHueShift := -1 / 3;
        end else if (lkNeutral in LemmingKinds) then
        begin
          SpecialCombine := true;

          if lkNormal in LemmingKinds then
            fCombineHueShift := -1 / 6
          else
            fCombineHueShift := 1 / 6;
        end else
          SpecialCombine := false;
      end else if Level.Info.HasTimeLimit and (i > TimeLimitStartIndex) and (i <= TimeLimitStartIndex + 5) then
      begin
        SpecialCombine := true;

        if Game.IsOutOfTime then
          fCombineHueShift := 1 / 2
        else if Level.Info.TimeLimit * 17 < Game.CurrentIteration + 255 {15 * 17} then
          fCombineHueShift := -1 / 3
        else
          fCombineHueShift := -1 / 6;
      end else
        SpecialCombine := false;

      //this changes the position of the game info string (lems, time limit, etc) - bookmark
      if SpecialCombine then
      begin
        fInfoFont[CharID].DrawMode := dmCustom;
        fInfoFont[CharID].OnPixelCombine := CombineShift;
        fInfoFont[CharID].DrawTo(fImage.Bitmap, ((i - 1) * 8) * ResMod, 0);
      end else begin
        fInfoFont[CharID].DrawMode := dmOpaque;
        fInfoFont[CharID].DrawTo(fImage.Bitmap, ((i - 1) * 8) * ResMod, 0);
      end;
    end;
  end;
end;

procedure TBaseSkillPanel.RefreshInfo;
var
  i : TSkillPanelButton;
begin
  fIsBlinkFrame := (GetTickCount mod 1000) > 499;

  Image.BeginUpdate;
  try
    // Text info string
    CreateNewInfoString;
    DrawNewStr;
    fLastDrawnStr := fNewDrawStr;

    DrawSkillCount(spbSlower, GetSpawnIntervalValue(Level.Info.SpawnInterval));
    DrawSkillCount(spbFaster, GetSpawnIntervalValue(Game.CurrentSpawnInterval));

    // Highlight selected button
    if fHighlitSkill <> Game.RenderInterface.SelectedSkill then
    begin
      DrawButtonSelector(fHighlitSkill, false);
      DrawButtonSelector(Game.RenderInterface.SelectedSkill, true);
    end;

    // Skill numbers
    if self.fShowUsedSkills then
    begin
      for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        DrawSkillCount(i, Game.SkillsUsed[i]);
    end else begin
      for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        DrawSkillCount(i, Game.SkillCount[i]);
    end;

    DrawButtonSelector(spbNuke, (Game.UserSetNuking or (Game.ReplayManager.Assignment[Game.CurrentIteration, 0] is TReplayNuke)));
  finally
    Image.EndUpdate;
    Image.Invalidate;
  end;
end;

function TBaseSkillPanel.GetSkillString(L: TLemming): String;
var
  i: Integer;

  procedure DoInc(aText: String);
  begin
    Inc(i);
    case i of
      1: Result := aText;
      2: Result := SAthlete;
      3: Result := STriathlete;
      4: Result := SQuadathlete;
      5: Result := SQuintathlete
    end;
  end;
begin
  Result := '';
  if L = nil then Exit;

  Result := LemmingActionStrings[L.LemAction];

  if L.HasPermanentSkills and GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo) then
  begin
    Result := '-------';
    if L.LemIsSlider then Result[1] := 'L';    
    if L.LemIsClimber then Result[2] := 'C';
    if L.LemIsSwimmer then Result[3] := 'S';
    if L.LemIsFloater then Result[4] := 'F';
    if L.LemIsGlider then Result[4] := 'G';
    if L.LemIsDisarmer then Result[5] := 'D';
    if L.LemIsZombie then Result[6] := 'Z';
    if L.LemIsNeutral then Result[7] := 'N';
  end
  else if not (L.LemAction in [baBuilding, baPlatforming, baStacking, baLasering, baBashing, baMining, baDigging, baBlocking]) then
  begin
    i := 0;
    if L.LemIsSlider then DoInc(SSlider);
    if L.LemIsClimber then DoInc(SClimber);
    if L.LemIsSwimmer then DoInc(SSwimmer);
    if L.LemIsFloater then DoInc(SFloater);
    if L.LemIsGlider then DoInc(SGlider);
    if L.LemIsDisarmer then DoInc(SDisarmer);
    if L.LemIsZombie then Result := SZombie;
    if L.LemIsNeutral then Result := SNeutral;
    if L.LemIsZombie and L.LemIsNeutral then Result := SNeutralZombie;
  end;
end;

procedure TBaseSkillPanel.SetInfoCursorLemming(Pos: Integer);
var
  S: string;
const
  LEN = 12;
begin
  S := Uppercase(GetSkillString(Game.RenderInterface.SelectedLemming));
  if S = '' then
    S := StringOfChar(' ', LEN)
  else if Game.LastHitCount = 0 then
    S := PadR(S, LEN)
  else
    S := PadR(S + ' ' + IntToStr(Game.LastHitCount), LEN);

  ModString(fNewDrawStr, S, Pos);
end;

procedure TBaseSkillPanel.SetInfoLemHatch(Pos: Integer);
var
  S: string;
const
  LEN = 4;
begin
  Assert(Game.LemmingsToSpawn - Game.SpawnedDead >= 0, 'Negative number of lemmings in hatch displayed');
  S := IntToStr(Game.LemmingsToSpawn - Game.SpawnedDead);

  if Length(S) < LEN then
    S := PadL(PadR(S, LEN - 1), LEN);

  ModString(fNewDrawStr, S, Pos);
end;

procedure TBaseSkillPanel.SetInfoLemAlive(Pos: Integer);
var
  LemNum: Integer;
  S: string;
const
  LEN = 4;
begin
  LemNum := Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead;
  Assert(LemNum >= 0, 'Negative number of alive lemmings displayed');

  S := IntToStr(LemNum);
  if Length(S) < LEN then
    S := PadL(PadR(S, LEN - 1), LEN);

  ModString(fNewDrawStr, S, Pos);
end;

procedure TBaseSkillPanel.SetInfoLemIn(Pos: Integer);
var
  S: string;
const
  LEN = 4;
begin
  S := IntToStr(Game.LemmingsSaved - Level.Info.RescueCount);

  if Length(S) < LEN then
    S := PadL(PadR(S, LEN - 1), LEN);

  ModString(fNewDrawStr, S, Pos);
end;

procedure TBaseSkillPanel.SetInfoTime(PosMin, PosSec: Integer);
var
  Time : Integer;
  S: string;
const
  LEN = 2;
begin
  if Level.Info.HasTimeLimit then
  begin
    Time := Level.Info.TimeLimit - Game.CurrentIteration div 17;
    if Time < 0 then
      Time := 0 - Time;
  end else
    Time := Game.CurrentIteration div 17;

  // Minutes
  S := PadL(IntToStr(Time div 60), 2);
  ModString(fNewDrawStr, S, PosMin);

  // Seconds
  S := LeadZeroStr(Time mod 60, 2);
  ModString(fNewDrawStr, S, PosSec);
end;

procedure TBaseSkillPanel.SetReplayMark(Pos: Integer);
begin
  if not Game.ReplayingNoRR[fGameWindow.GameSpeed = gspPause] then
    fNewDrawStr[Pos] := ' '
  else if Game.ReplayInsert then
    fNewDrawStr[Pos] := #97
  else
    fNewDrawStr[Pos] := #91;
end;

procedure TBaseSkillPanel.SetTimeLimit(Pos: Integer);
begin
  if Level.Info.HasTimeLimit then
    fNewDrawStr[Pos] := #96
  else
    fNewDrawStr[Pos] := #95;
end;


{-----------------------------------------
    User interaction
-----------------------------------------}
function TBaseSkillPanel.MousePos(X, Y: Integer): TPoint;
begin
  Result := fImage.ControlToBitmap(Point(X, Y));
end;

function TBaseSkillPanel.MousePosMinimap(X, Y: Integer): TPoint;
begin
  Result := fMinimapImage.ControlToBitmap(Point(X, Y));
end;

procedure TBaseSkillPanel.ImgMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  aButton: TSkillPanelButton;
  i: TSkillPanelButton;
begin
  if GameParams.EdgeScroll then fGameWindow.ApplyMouseTrap;
  if fGameWindow.IsHyperSpeed then Exit;

  // Get pressed button
  aButton := spbNone;
  for i := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    if PtInRect(fButtonRects[i], MousePos(X, Y)) then
    begin
      aButton := i;
      Break;
    end;
  end;

  // Do some global stuff
  if aButton = spbNone then Exit;
  if (aButton = spbNuke) and not (ssDouble in Shift) then Exit;

  if Game.Replaying and not Level.Info.SpawnIntervalLocked then
  begin
    if ((aButton = spbSlower) and (Game.CurrentSpawnInterval < Level.Info.SpawnInterval))
    or ((aButton = spbFaster) and (Game.CurrentSpawnInterval > MINIMUM_SI)) then
    Game.RegainControl;
  end;

  // Do button-specific actions
  case aButton of
    spbSlower:
      begin
        if GameParams.ClassicMode then //deactivates min/max RR jumping in ClassicMode
          begin
            Game.SetSelectedSkill(i, True);
          end else
        Game.SetSelectedSkill(i, True, (Button = mbRight));
      end;
    spbFaster:
      begin
        if GameParams.ClassicMode then //deactivates min/max RR jumping in ClassicMode
          begin
            Game.SetSelectedSkill(i, True);
            end else
        Game.SetSelectedSkill(i, True, (Button = mbRight));
      end;
    spbPause:
      begin
        if fGameWindow.GameSpeed = gspPause then
        fGameWindow.GameSpeed := gspNormal
        else
        fGameWindow.GameSpeed := gspPause;
      end;
    spbNuke:
      begin
        Game.RegainControl;
        if GameParams.Hotkeys.CheckForKey(lka_Highlight) or (Button = mbRight) then
        begin
          Game.SetSelectedSkill(i, True, true);
          fGameWindow.GotoSaveState(Game.CurrentIteration, 0, Game.CurrentIteration - 85);
        end else
          Game.SetSelectedSkill(i, True);
      end;
    spbFastForward:
      begin
        if fGameWindow.GameSpeed = gspFF then
          fGameWindow.GameSpeed := gspNormal
        else if fGameWindow.GameSpeed in [gspNormal, gspSlowMo, gspPause, gspRewind] then
          fGameWindow.GameSpeed := gspFF;
      end;
    spbRewind:
      begin
        if fGameWindow.GameSpeed = gspRewind then
          fGameWindow.GameSpeed := gspNormal
        else if fGameWindow.GameSpeed in [gspNormal, gspSlowMo, gspPause, gspFF] then
          fGameWindow.GameSpeed := gspRewind;
      end;
    spbRestart:
      begin
        if GameParams.ClassicMode or not GameParams.ReplayAfterRestart then // cancels Replay after Restart in ClassicMode
          begin
            Game.CancelReplayAfterSkip := true;
            fGameWindow.GotoSaveState(0);
          end else
            fGameWindow.GotoSaveState(0);
      end;
    spbSquiggle:
      begin
        if not GameParams.HideClearPhysics then  //formerly spbClearPhysics
        fGameWindow.ClearPhysics := not fGameWindow.ClearPhysics;
      end;
    spbNone: {nothing};
  else // usual skill buttons
    Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
  end;
end;

procedure TBaseSkillPanel.ImgMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := true;
  Game.HitTest;
  fGameWindow.SetCurrentCursor;

  MinimapScrollFreeze := false;
end;

procedure TBaseSkillPanel.ImgMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  Game.SetSelectedSkill(spbSlower, False);
  Game.SetSelectedSkill(spbFaster, False);
end;

procedure TBaseSkillPanel.MinimapMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if GameParams.EdgeScroll then fGameWindow.ApplyMouseTrap;
  fMinimapScrollFreeze := true;

  if Assigned(fOnMinimapClick) then
    fOnMinimapClick(Self, MousePosMinimap(X, Y));
end;

procedure TBaseSkillPanel.MinimapMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  Pos: TPoint;
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := true;
  Game.HitTest;
  fGameWindow.SetCurrentCursor;

  if not fMinimapScrollFreeze then Exit;
  if not (ssLeft in Shift) then Exit;

  Pos := MousePosMinimap(X, Y);
  if PtInRect(fMinimapImage.Bitmap.BoundsRect, Pos) and Assigned(fOnMinimapClick) then
    fOnMinimapClick(Self, Pos)
  else
    MinimapMouseUp(Sender, mbLeft, Shift, X, Y, Layer);
end;

procedure TBaseSkillPanel.MinimapMouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  fMinimapScrollFreeze := false;
  DrawMinimap;
end;


function TBaseSkillPanel.CheckFrameSkip: Integer;
var
  P: TPoint;
begin
  Result := 0;
  if GetTickCount - fLastClickFrameskip < 250 then Exit;
  if GetKeyState(VK_LBUTTON) >= 0 then Exit;

  P := Image.ControlToBitmap(Image.ScreenToClient(Mouse.CursorPos));
end;

{-----------------------------------------
    General stuff
-----------------------------------------}
function TBaseSkillPanel.GetLevel: TLevel;
begin
  Result := GameParams.Level;
end;

////zooming code: this needs to be changed to resizing code
procedure TBaseSkillPanel.SetZoom(NewZoom: Integer);
begin
  if GameParams.HighResolution then
    NewZoom := NewZoom * 2;
  NewZoom := Max(Min(MaxZoom, NewZoom), 1);
  if (NewZoom = Trunc(fImage.Scale)) and fSetInitialZoom then Exit;

  Width := GameParams.MainForm.ClientWidth;    // for the whole skill panel
  Height := GameParams.MainForm.ClientHeight;  // for the whole skill panel

  fImage.Width := PanelWidth * NewZoom;
  fImage.Height := PanelHeight * NewZoom;
  fImage.Left := (Width - Image.Width) div 2;
  fImage.Scale := NewZoom;

  fMinimapImage.Width := MinimapWidth * NewZoom;
  fMinimapImage.Height := MinimapHeight * NewZoom;
  fMinimapImage.Left := MinimapRect.Left * NewZoom + Image.Left;
  fMinimapImage.Top := MinimapRect.Top * NewZoom;
  fMinimapImage.Scale := NewZoom;

  fSetInitialZoom := true;
end;

function TBaseSkillPanel.GetZoom: Integer;
begin
  Result := Trunc(fImage.Scale);
end;

function TBaseSkillPanel.GetMaxZoom: Integer;
begin
  Result := Max(Min(GameParams.MainForm.ClientWidth div PanelWidth, (GameParams.MainForm.ClientHeight - 160) div 40), 1);
end;

procedure TBaseSkillPanel.SetMinimapScrollFreeze(aValue: Boolean);
begin
  fMinimapScrollFreeze := aValue;
  if fMinimapScrollFreeze then DrawMinimap;
end;

procedure TBaseSkillPanel.SetGame(const Value: TLemmingGame);
begin
  fGame := Value;
end;

procedure TBaseSkillPanel.SetOnMinimapClick(const Value: TMinimapClickEvent);
begin
  fOnMinimapClick := Value;
end;

procedure TBaseSkillPanel.SetCursor(aCursor: TCursor);
begin
  Cursor := aCursor;
  fImage.Cursor := aCursor;
  fMinimapImage.Cursor := aCursor;
end;

function TBaseSkillPanel.GetSpawnIntervalValue(aSI: Integer): Integer;
begin
  if GameParams.SpawnInterval and not GameParams.ClassicMode then
    Result := aSI
  else
    Result := SpawnIntervalToReleaseRate(aSI);
end;

end.
