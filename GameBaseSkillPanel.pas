unit GameBaseSkillPanel;

interface

uses
  System.Types,
  Classes, Controls, GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  GameWindowInterface,
  LemAnimationSet, LemMetaAnimation,
  LemCore, LemLemming, LemGame, LemLevel;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TPanelButtonArray = array of TSkillPanelButton;

type
  TBaseSkillPanel = class(TCustomControl)

  private
    fGame                 : TLemmingGame;
    fIconBmp              : TBitmap32;   // for temporary storage

    fSetInitialZoom       : Boolean;

    fRectColor            : TColor32;
    fSelectDx             : Integer;
    fIsBlinkFrame         : Boolean;
    fOnMinimapClick       : TMinimapClickEvent; // event handler for minimap

    function CheckFrameSkip: Integer; // Checks the duration since the last click on the panel.

    procedure LoadPanelFont;
    procedure LoadSkillIcons;
    procedure LoadSkillFont;

    function GetLevel: TLevel;
    function GetZoom: Integer;
    procedure SetZoom(NewZoom: Integer);
    function GetMaxZoom: Integer;

    procedure CombineToRed(F: TColor32; var B: TColor32; M: TColor32);
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

    fSkillFont            : array['0'..'9', 0..1] of TBitmap32;
    fSkillOvercount       : array[100..MAXIMUM_SI] of TBitmap32;
    fSkillCountErase      : TBitmap32;
    fSkillLock            : TBitmap32;
    fSkillInfinite        : TBitmap32;
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

    property Image: TImage32 read fImage;

    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
    procedure DrawMinimap; virtual;

    property Minimap: TBitmap32 read fMinimap;
    property MinimapScrollFreeze: Boolean read fMinimapScrollFreeze write SetMinimapScrollFreeze;

    property Zoom: Integer read GetZoom write SetZoom;
    property MaxZoom: Integer read GetMaxZoom;

    property FrameSkip: Integer read CheckFrameSkip;
    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
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
    'empty_slot.png', 'empty_slot.png',              {Skills end here}
    'empty_slot.png', 'icon_rr_plus.png', 'icon_rr_minus.png', 'icon_pause.png',
    'icon_nuke.png', 'icon_ff.png', 'icon_restart.png', 'icon_frameskip.png',
    'icon_directional.png', 'icon_cpm_and_replay.png',

    // These ones are placeholders - they're the bottom half of splits
    'icon_frameskip.png', 'icon_directional.png', 'icon_cpm_and_replay.png'
    );


implementation

uses
  SysUtils, Math, Windows, UMisc, PngInterface,
  GameControl, GameSound,
  LemTypes, LemReplay, LemStrings, LemNeoTheme,
  LemmixHotkeys, LemDosStructures;

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
    end;

  fSkillInfinite := TBitmap32.Create;
  fSkillInfinite.DrawMode := dmBlend;
  fSkillInfinite.CombineMode := cmMerge;

  fSkillCountErase := TBitmap32.Create;
  fSkillCountErase.DrawMode := dmBlend;
  fSkillCountErase.CombineMode := cmMerge;

  fSkillLock := TBitmap32.Create;
  fSkillLock.DrawMode := dmBlend;
  fSkillLock.CombineMode := cmMerge;

  fLastDrawnStr := StringOfChar(' ', DrawStringLength);
  fNewDrawStr := DrawStringTemplate;

  Assert(Length(fNewDrawStr) = DrawStringLength, 'SkillPanel.Create: InfoString has not the correct length.');

  fRectColor := DosVgaColorToColor32(DosInLevelPalette[3]);
  fHighlitSkill := spbNone;
  fLastHighlitSkill := spbNone;
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
      fSkillFont[c, i].Free;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillIcons[Button].Free;

  fSkillInfinite.Free;
  fSkillCountErase.Free;
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
  Result := Rect(1, 16, 15, 38);
end;

function TBaseSkillPanel.ButtonRect(Index: Integer): TRect;
begin
  Result := FirstButtonRect;
  OffsetRect(Result, Index * 16, 0);
end;

function TBaseSkillPanel.HalfButtonRect(Index: Integer; IsUpper: Boolean): TRect;
begin
  Result := FirstButtonRect;
  OffsetRect(Result, Index * 16, 0);
  if IsUpper then
    Result.Bottom := (Result.Top + Result.Bottom) div 2 - 1
  else
    Result.Top := (Result.Top + Result.Bottom) div 2 + 1;
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
  SrcFile: String;
begin
  SrcFile := GameParams.CurrentLevel.Group.PanelPath + aName;
  if not FileExists(SrcFile) then
    SrcFile := AppPath + SFStyles + SFDefaultStyle + SFPiecesPanel + aName;
  MaskColor := GameParams.Renderer.Theme.Colors[MASK_COLOR];

  TPngInterface.LoadPngFile(SrcFile, aDst);
  TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(SrcFile, '_mask.png'), MaskColor);
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
  GetGraphic('skill_panels.png', BlankPanel);

  SrcRect := BlankPanel.BoundsRect;
  SrcWidth := SrcRect.Right - SrcRect.Left;
  DstRect := BlankPanel.BoundsRect;
  OffsetRect(DstRect, FirstButtonRect.Left, FirstButtonRect.Top);

  // Draw full panels
  for i := 1 to (NumButtons * 16 - 1) div SrcWidth do
  begin
    BlankPanel.DrawTo(fOriginal, DstRect, SrcRect);
    OffsetRect(DstRect, SrcWidth, 0);
  end;

  // Draw partial panel at the end
  DstRect.Right := ButtonRect(NumButtons - 1).Right + 1;
  DstRect.Bottom := ButtonRect(NumButtons - 1).Bottom + 1;
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
  SrcRect := Rect(0, 0, 8, 16);
  for i := 0 to 37 do
  begin
    fInfoFont[i].SetSize(8, 16);
    fIconBmp.DrawTo(fInfoFont[i], 0, 0, SrcRect);
    OffsetRect(SrcRect, 8, 0);
  end;

  // Load now the icons for the text panel
  GetGraphic('panel_icons.png', fIconBmp);
  SrcRect := Rect(0, 0, 8, 16);
  for i := 38 to NUM_FONT_CHARS - 1 do
  begin
    fInfoFont[i].SetSize(8, 16);
    fIconBmp.DrawTo(fInfoFont[i], 0, 0, SrcRect);
    OffsetRect(SrcRect, 8, 0);
  end;
end;

procedure TBaseSkillPanel.LoadSkillIcons;
const
  PANEL_FALLBACK_BRICK_COLOR = $FF00B000;
var
  BrickColor: TColor32;
  Button: TSkillPanelButton;
  TempBmp: TBitmap32;

  procedure DrawAnimationFrame(dst: TBitmap32; aAnimationIndex: Integer; aFrame: Integer; footX, footY: Integer);
  var
    Ani: TBaseAnimationSet;
    Meta: TMetaLemmingAnimation;
    SrcRect: TRect;
  begin
    Ani := GameParams.Renderer.LemmingAnimations;
    Meta := Ani.MetaLemmingAnimations[aAnimationIndex];

    SrcRect := Ani.LemmingAnimations[aAnimationIndex].BoundsRect;
    SrcRect.Bottom := SrcRect.Bottom div Meta.FrameCount;
    SrcRect.Offset(0, SrcRect.Height * aFrame);

    Ani.LemmingAnimations[aAnimationIndex].DrawTo(dst, footX - Meta.FootX, footY - Meta.FootY, SrcRect);
  end;

  procedure DrawAnimationFrameResized(dst: TBitmap32; aAnimationIndex: Integer; aFrame: Integer; dstRect: TRect);
  var
    Ani: TBaseAnimationSet;
    Meta: TMetaLemmingAnimation;
    SrcRect: TRect;
  begin
    Ani := GameParams.Renderer.LemmingAnimations;
    Meta := Ani.MetaLemmingAnimations[aAnimationIndex];

    SrcRect := Ani.LemmingAnimations[aAnimationIndex].BoundsRect;
    SrcRect.Bottom := SrcRect.Bottom div Meta.FrameCount;
    SrcRect.Offset(0, SrcRect.Height * aFrame);

    Ani.LemmingAnimations[aAnimationIndex].DrawTo(dst, dstRect, SrcRect);
  end;

  procedure DrawBrick(dst: TBitmap32; X, Y: Integer; W: Integer = 2);
  var
    oX: Integer;
  begin
    for oX := 0 to W-1 do
      dst.PixelS[X + oX, Y] := BrickColor;
  end;

  procedure Outline(dst: TBitmap32);
  var
    x, y: Integer;
    oX, oY: Integer;
    ThisAlpha, MaxAlpha: Byte;
  begin
    TempBmp.Assign(dst);
    dst.Clear(0);
    TempBmp.WrapMode := wmClamp;
    TempBmp.OuterColor := $00000000;

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
        dst[x, y] := MaxAlpha shl 24;
      end;

    TempBmp.DrawTo(dst);
  end;
begin
  // Load the erasing icon first
  GetGraphic('skill_count_erase.png', fSkillCountErase);

  //for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  //  GetGraphic('icon_' + SKILL_NAMES[Button] + '.png', fSkillIcons[Button]);
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
      fSkillIcons[Button].SetSize(15, 23);

    // Walker, Climber, - both simple
    DrawAnimationFrame(fSkillIcons[spbWalker], WALKING, 1, 6, 21);
    DrawAnimationFrame(fSkillIcons[spbClimber], CLIMBING, 3, 10, 22);

    // Swimmer - we need to draw the background water
    DrawAnimationFrame(fSkillIcons[spbSwimmer], SWIMMING, 2, 8, 19);
    Outline(fSkillIcons[spbSwimmer]);
    TempBmp.Assign(fSkillIcons[spbSwimmer]);
    fSkillIcons[spbSwimmer].Clear(0);
    fSkillIcons[spbSwimmer].FillRect(0, 17, 15, 23, $FF000000);
    fSkillIcons[spbSwimmer].FillRect(0, 18, 15, 23, $FF0000FF);
    TempBmp.DrawTo(fSkillIcons[spbSwimmer]);

    // Floater, Glider - both simple
    DrawAnimationFrame(fSkillIcons[spbFloater], UMBRELLA, 4, 7, 26);
    DrawAnimationFrame(fSkillIcons[spbGlider], GLIDING, 4, 7, 26);

    // Disarmer - graphic would be too easily confused with digger, so we fall back to the old graphic for now
    GetGraphic('icon_disarmer.png', fSkillIcons[spbDisarmer]);

    // Shimmier is straightforward
    DrawAnimationFrame(fSkillIcons[spbShimmier], SHIMMYING, 1, 7, 20);

    // Bomber is drawn resized
    DrawAnimationFrameResized(fSkillIcons[spbBomber], EXPLOSION, 0, Rect(-2, 7, 15, 24));

    // Stoner is tricky - the goal is an outlined stoned lemming over a stoner explosion graphic
    DrawAnimationFrame(fSkillIcons[spbStoner], STONED, 0, 8, 21);
    Outline(fSkillIcons[spbStoner]);
    TempBmp.Assign(fSkillIcons[spbStoner]);
    fSkillIcons[spbStoner].Clear(0);
    DrawAnimationFrameResized(fSkillIcons[spbStoner], STONEEXPLOSION, 0, Rect(-2, 7, 15, 24));
    TempBmp.DrawTo(fSkillIcons[spbStoner], 0, 0);

    // Blocker is simple
    DrawAnimationFrame(fSkillIcons[spbBlocker], BLOCKING, 0, 7, 21);

    // Platformer, Builder and Stacker have bricks drawn to clarify the direction of building.
    // Platformer additionally has some extra black pixels drawn in to make the outline nicer.
    DrawAnimationFrame(fSkillIcons[spbPlatformer], PLATFORMING, 1, 7, 20);
    fSkillIcons[spbPlatformer].FillRect(2, 21, 12, 22, $FF000000);
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

    // Basher, Fencer, Miner are all simple - we do have to take care to avoid frames with destruction particles
    DrawAnimationFrame(fSkillIcons[spbBasher], BASHING, 0, 8, 21);
    DrawAnimationFrame(fSkillIcons[spbFencer], FENCING, 1, 7, 21);
    DrawAnimationFrame(fSkillIcons[spbMiner], MINING, 12, 4, 21);

    // The digger doesn't HAVE any frames without particles. But the Disarmer's similar animation does! ;)
    DrawAnimationFrame(fSkillIcons[spbDigger], FIXING, 0, 7, 21);

    // And finally, outline everything. We generate the cloner after this, as it makes use of
    // the post-outlined Walker graphic.
    for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if not (Button in [spbSwimmer, spbDisarmer, spbCloner]) then
        Outline(fSkillIcons[Button]);
        // Swimmer and Cloner are already outlined during their generation, and Disarmer remains
        // loaded from a file, and current conventions is that the file already has outlines.

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

  procedure MakeOvercountImage(aCount: Integer);
  var
    CountStr: String;
  begin
    TempBmp.Clear(0);
    CountStr := LeadZeroStr(aCount, 3); // just in case
    fSkillFont[CountStr[1], 1].DrawTo(TempBmp, 0, 0, Rect(0, 0, 4, 8));
    fSkillFont[CountStr[2], 1].DrawTo(TempBmp, 4, 0, Rect(0, 0, 4, 8));
    fSkillFont[CountStr[3], 1].DrawTo(TempBmp, 8, 0, Rect(0, 0, 4, 8));
  end;

begin
  GetGraphic('skill_count_digits.png', fIconBmp);
  SrcRect := Rect(0, 0, 4, 8);
  for c := '0' to '9' do
  begin
    for i := 0 to 1 do
    begin
      fSkillFont[c, i].SetSize(8, 8);
      fIconBmp.DrawTo(fSkillFont[c, i], 4 - 4 * i, 0, SrcRect);
    end;
    OffsetRect(SrcRect, 4, 0);
  end;

  Inc(SrcRect.Right, 4); // Position is correct at this point, but Infinite symbol is 8px wide not 4px
  fSkillInfinite.SetSize(8, 8);
  fIconBmp.DrawTo(fSkillInfinite, 0, 0, SrcRect);

  OffsetRect(SrcRect, 8, 0);
  fSkillLock.SetSize(8, 8);
  fIconBmp.DrawTo(fSkillLock, 0, 0, SrcRect);

  TempBmp := TBitmap32.Create;
  TKernelResampler.Create(TempBmp);
  TKernelResampler(TempBmp.Resampler).Kernel := TCubicKernel.Create;
  try
    TempBMP.SetSize(12, 8);
    for i := 100 to MAXIMUM_SI do
    begin
      MakeOvercountImage(i);
      fSkillOvercount[i] := TBitmap32.Create;
      fSkillOvercount[i].SetSize(9, 8);
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
    if GameParams.SpawnInterval then Exit;

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
  MinimapRegion := TBitmap32.Create;
  GetGraphic('minimap_region.png', MinimapRegion);
  ResizeMinimapRegion(MinimapRegion);
  MinimapRegion.DrawTo(fOriginal, MinimapRect.Left - 3, MinimapRect.Top - 2);
  MinimapRegion.Free;

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

  Minimap.SetSize(Level.Info.Width div 8, Level.Info.Height div 8);

  ReadBitmapFromStyle;
  SetButtonRects;
  SetSkillIcons;

  fImage.EndUpdate;
  fImage.Changed;
  Invalidate;
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

  // Set only rectangles for non-skill buttons
  // The skill buttons are dealt with in SetSkillIcons
  for i := 0 to Length(ButtonList) - 1 do
  begin
    if ButtonList[i] in [spbDirLeft, spbDirRight] then
    begin
      fButtonRects[spbDirLeft] := HalfButtonRect(i, true);
      fButtonRects[spbDirRight] := HalfButtonRect(i, false);
    end else if ButtonList[i] in [spbBackOneFrame, spbForwardOneFrame] then
    begin
      fButtonRects[spbBackOneFrame] := HalfButtonRect(i, true);
      fButtonRects[spbForwardOneFrame] := HalfButtonRect(i, false);
    end else if ButtonList[i] in [spbClearPhysics, spbLoadReplay] then
    begin
      fButtonRects[spbClearPhysics] := HalfButtonRect(i, true);
      fButtonRects[spbLoadReplay] := HalfButtonRect(i, false);
    end else if ButtonList[i] > spbNone then
      fButtonRects[ButtonList[i]] := ButtonRect(i);
  end;
end;

procedure TBaseSkillPanel.DrawMinimap;
var
  BaseOffsetHoriz, BaseOffsetVert: Double;
  OH, OV: Double;
  ViewRect: TRect;
begin
  if Parent = nil then Exit;

  // Add some space for when the viewport rect lies on the very edges
  fMinimapTemp.Width := fMinimap.Width + 2;
  fMinimapTemp.Height := fMinimap.Height + 2;
  fMinimapTemp.Clear(0);
  fMinimap.DrawTo(fMinimapTemp, 1, 1);

  BaseOffsetHoriz := fGameWindow.ScreenImage.OffsetHorz / fGameWindow.ScreenImage.Scale / 8;
  BaseOffsetVert := fGameWindow.ScreenImage.OffsetVert / fGameWindow.ScreenImage.Scale / 8;

  // Draw the visible area frame
  ViewRect := Rect(0, 0, fGameWindow.DisplayWidth div 8 + 2, fGameWindow.DisplayHeight div 8 + 2);
  OffsetRect(ViewRect, -Round(BaseOffsetHoriz), -Round(BaseOffsetVert));
  fMinimapTemp.FrameRectS(ViewRect, fRectColor);

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

procedure TBaseSkillPanel.DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
begin
  if fGameWindow.IsHyperSpeed then Exit;
  if aButton = spbNone then Exit;
  if (aButton <= LAST_SKILL_BUTTON) then
  begin
    if (fHighlitSkill = aButton) and Highlight then Exit;
    if (fHighlitSkill = spbNone) and not Highlight then Exit;
  end;
  if fButtonRects[aButton].Left <= 0 then Exit;

  if Highlight then
    DrawHighlight(aButton)
  else
    RemoveHighlight(aButton);
end;

procedure TBaseSkillPanel.DrawHighlight(aButton: TSkillPanelButton);
var
  BorderRect: TRect;
begin
  if aButton <= LAST_SKILL_BUTTON then // we don't want to memorize this for eg. fast forward
  begin
    BorderRect := fButtonRects[aButton];
    fHighlitSkill := aButton;
    if (fLastHighlitSkill <> spbNone) and (fLastHighlitSkill <> fHighlitSkill) then
      SoundManager.PlaySound(SFX_SKILLBUTTON);
  end else
    BorderRect := fButtonRects[aButton];

  Inc(BorderRect.Right);
  Inc(BorderRect.Bottom, 2);

  Image.Bitmap.FrameRectS(BorderRect, fRectColor);
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

  Inc(BorderRect.Right);
  Inc(BorderRect.Bottom, 2);

  // top
  EraseRect := BorderRect;
  EraseRect.Bottom := EraseRect.Top + 1;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // left
  EraseRect := BorderRect;
  EraseRect.Right := EraseRect.Left + 1;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // right
  EraseRect := BorderRect;
  EraseRect.Left := EraseRect.Right - 1;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // bottom
  EraseRect := BorderRect;
  EraseRect.Top := EraseRect.Bottom - 1;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);
end;



procedure TBaseSkillPanel.DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
var
  ButtonLeft, ButtonTop: Integer;
  NumberStr: string;
begin
  if fButtonRects[aButton].Left < 0 then Exit;
  if fGameWindow.IsHyperSpeed then Exit;

  ButtonLeft := fButtonRects[aButton].Left;
  ButtonTop := fButtonRects[aButton].Top;

  // Erase previous number
  fSkillCountErase.DrawTo(fImage.Bitmap, ButtonLeft, ButtonTop);
  if aNumber = 0 then Exit;

  if (aButton = spbFaster) and (Level.Info.SpawnIntervalLocked or (Level.Info.SpawnInterval = MINIMUM_SI)) then
    fSkillLock.DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1)
  else if (aNumber > 99) then
  begin
    if (aButton <= LAST_SKILL_BUTTON) then
      fSkillInfinite.DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1)
    else
      fSkillOvercount[aNumber].DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1);
  end else if aNumber < 10 then
  begin
    NumberStr := LeadZeroStr(aNumber, 2);
    fSkillFont[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 1, ButtonTop + 1);
  end else begin
    NumberStr := LeadZeroStr(aNumber, 2);
    fSkillFont[NumberStr[1], 1].DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1);
    fSkillFont[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1);
  end;
end;

{-----------------------------------------
    Info string at top
-----------------------------------------}
procedure TBaseSkillPanel.CombineToRed(F: TColor32; var B: TColor32; M: TColor32);
begin
  if AlphaComponent(F) = 0 then Exit;
  // Swap red and green component
  B := Color32(GreenComponent(F), RedComponent(F), BlueComponent(F), AlphaComponent(F));
end;

procedure TBaseSkillPanel.DrawNewStr;
var
  Old, New: char;
  i, CharID: integer;
  DoRecolor: Boolean;
begin
  for i := 1 to DrawStringLength do
  begin
    Old := fLastDrawnStr[i];
    New := fNewDrawStr[i];

    if Old <> New then
    begin
      case New of
        '%':        CharID := 0;
        '0'..'9':   CharID := ord(New) - ord('0') + 1;
        '-':        CharID := 11;
        'A'..'Z':   CharID := ord(New) - ord('A') + 12;
        #91 .. #97: CharID := ord(New) - ord('A') + 12;
      else CharID := -1;
      end;

      // Erase previous text there
      fImage.Bitmap.FillRectS((i - 1) * 8, 0, i * 8, 16, 0);

      DoRecolor := Level.Info.HasTimeLimit and (i >= TimeLimitStartIndex) and (CharID >= 0);
      if DoRecolor then
      begin
        fInfoFont[CharID].DrawMode := dmCustom;
        fInfoFont[CharID].OnPixelCombine := CombineToRed;
        fInfoFont[CharID].DrawTo(fImage.Bitmap, (i - 1) * 8, 0);
        fInfoFont[CharID].DrawMode := dmBlend;
        fInfoFont[CharID].CombineMode := cmMerge;
      end
      else if CharID >= 0 then
        fInfoFont[CharID].DrawTo(fImage.Bitmap, (i - 1) * 8, 0);
    end;
  end;
end;

procedure TBaseSkillPanel.RefreshInfo;
var
  i : TSkillPanelButton;
begin
  fIsBlinkFrame := (GetTickCount mod 1000) > 499;

  // Text info string
  CreateNewInfoString;
  DrawNewStr;
  fLastDrawnStr := fNewDrawStr;

  // Skill and RR numbers
  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    DrawSkillCount(i, Game.SkillCount[i]);

  DrawSkillCount(spbSlower, GetSpawnIntervalValue(Level.Info.SpawnInterval));
  DrawSkillCount(spbFaster, GetSpawnIntervalValue(Game.CurrentSpawnInterval));

  // Highlight selected button
  if fHighlitSkill <> Game.RenderInterface.SelectedSkill then
  begin
    DrawButtonSelector(fHighlitSkill, false);
    DrawButtonSelector(Game.RenderInterface.SelectedSkill, true);
  end;

  DrawButtonSelector(spbNuke, (Game.UserSetNuking or (Game.ReplayManager.Assignment[Game.CurrentIteration, 0] is TReplayNuke)));
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
    end;
  end;
begin
  Result := '';
  if L = nil then Exit;

  Result := LemmingActionStrings[L.LemAction];

  if L.HasPermanentSkills and GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo) then
  begin
    Result := '-----';
    if L.LemIsClimber then Result[1] := 'C';
    if L.LemIsSwimmer then Result[2] := 'S';
    if L.LemIsFloater then Result[3] := 'F';
    if L.LemIsGlider then Result[3] := 'G';
    if L.LemIsDisarmer then Result[4] := 'D';
    if L.LemIsZombie then Result[5] := 'Z';
  end
  else if not (L.LemAction in [baBuilding, baPlatforming, baStacking, baBashing, baMining, baDigging, baBlocking]) then
  begin
    i := 0;
    if L.LemIsClimber then DoInc(SClimber);
    if L.LemIsSwimmer then DoInc(SSwimmer);
    if L.LemIsFloater then DoInc(SFloater);
    if L.LemIsGlider then DoInc(SGlider);
    if L.LemIsDisarmer then DoInc(SDisarmer);
    if L.LemIsZombie then Result := SZombie;
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
    Time := Level.Info.TimeLimit - Game.CurrentIteration div 17
  else
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
    if    ((aButton = spbSlower) and (Game.CurrentSpawnInterval < Level.Info.SpawnInterval))
       or ((aButton = spbFaster) and (Game.CurrentSpawnInterval > MINIMUM_SI)) then
      Game.RegainControl;
  end;

  // Do button-specific actions
  case aButton of
    spbSlower: Game.SetSelectedSkill(i, True, (Button = mbRight));
    spbFaster: Game.SetSelectedSkill(i, True, (Button = mbRight));
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
        Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
      end;
    spbFastForward:
      begin
        if fGameWindow.GameSpeed = gspFF then
          fGameWindow.GameSpeed := gspNormal
        else if fGameWindow.GameSpeed = gspNormal then
          fGameWindow.GameSpeed := gspFF;
      end;
    spbRestart: fGameWindow.GotoSaveState(0, -1);
    spbBackOneFrame:
      begin
        if Button = mbLeft then
        begin
          fGameWindow.GotoSaveState(Game.CurrentIteration - 1);
          fLastClickFrameskip := GetTickCount;
        end else if Button = mbRight then
          fGameWindow.GotoSaveState(Game.CurrentIteration - 17)
        else if Button = mbMiddle then
          fGameWindow.GotoSaveState(Game.CurrentIteration - 85);
      end;
    spbForwardOneFrame:
      begin
        if Button = mbLeft then
        begin
          fGameWindow.SetForceUpdateOneFrame(True);
          fLastClickFrameskip := GetTickCount;
        end else if Button = mbRight then
          fGameWindow.SetHyperSpeedTarget(Game.CurrentIteration + 17)
        else if Button = mbMiddle then
          fGameWindow.SetHyperSpeedTarget(Game.CurrentIteration + 85);
      end;
    spbClearPhysics: fGameWindow.ClearPhysics := not fGameWindow.ClearPhysics;
    spbDirLeft:
      begin
        if fSelectDx = -1 then
        begin
          fSelectDx := 0;
          DrawButtonSelector(spbDirLeft, false);
        end else begin
          fSelectDx := -1;
          DrawButtonSelector(spbDirLeft, true);
          DrawButtonSelector(spbDirRight, false);
        end;
      end;
    spbDirRight:
      begin
        if fSelectDx = 1 then
        begin
          fSelectDx := 0;
          DrawButtonSelector(spbDirRight, false);
        end else begin
          fSelectDx := 1;
          DrawButtonSelector(spbDirLeft, false);
          DrawButtonSelector(spbDirRight, true);
        end;
      end;
    spbLoadReplay: fGameWindow.LoadReplay;
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
  if PtInRect(fButtonRects[spbBackOneFrame], P) then
  begin
    Result := -1;
    fLastClickFrameskip := GetTickCount - 150;
  end
  else if PtInRect(fButtonRects[spbForwardOneFrame], P) then
  begin
    Result := 1;
    fLastClickFrameskip := GetTickCount - 150;
  end;
end;

{-----------------------------------------
    General stuff
-----------------------------------------}
function TBaseSkillPanel.GetLevel: TLevel;
begin
  Result := GameParams.Level;
end;

procedure TBaseSkillPanel.SetZoom(NewZoom: Integer);
begin
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
  if GameParams.SpawnInterval then
    Result := aSI
  else
    Result := SpawnIntervalToReleaseRate(aSI);
end;

end.
