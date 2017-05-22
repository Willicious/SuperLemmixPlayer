unit GameBaseSkillPanel;

interface

uses
  Classes, Controls, GR32, GR32_Image, GR32_Layers,
  GameWindowInterface,
  LemCore, LemLemming, LemGame, LemLevel;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TPanelButtonArray = array of TSkillPanelButton;

type
  TBaseSkillPanel = class(TCustomControl)

  private
    fGame                   : TLemmingGame;
    fIconBmp                : TBitmap32;   // for temporary storage

    fDisplayWidth         : Integer;
    fDisplayHeight        : Integer;

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
    fSkillCountErase      : TBitmap32;
    fSkillLock            : TBitmap32;
    fSkillInfinite        : TBitmap32;
    fSkillIcons           : array of TBitmap32;
    fInfoFont             : array of TBitmap32; {%} { 0..9} {A..Z} // make one of this!

    fHighlitSkill         : TSkillPanelButton;
    fLastHighlitSkill     : TSkillPanelButton; // to avoid sounds when shouldn't be played

    fLastDrawnStr         : string;
    fNewDrawStr           : string;

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
    procedure DrawHightlight(aButton: TSkillPanelButton); virtual;
    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
    procedure RemoveHightlight(aButton: TSkillPanelButton); virtual;

    // Drawing routines for the info string at the top
    function DrawStringLength: Integer; virtual; abstract;
    function DrawStringTemplate: string; virtual; abstract;

    procedure DrawNewStr;
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

  public
    constructor Create(aOwner: TComponent); overload; override;
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); overload; virtual;
    destructor Destroy; override;

    procedure PrepareForGame;
    procedure RefreshInfo;
    procedure SetCursor(aCursor: TCursor);
    procedure SetOnMinimapClick(const Value: TMinimapClickEvent);
    procedure SetGame(const Value: TLemmingGame);

    property Image: TImage32 read fImage;

    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
    procedure DrawMinimap; virtual;

    property DisplayWidth: Integer read fDisplayWidth write fDisplayWidth;
    property DisplayHeight: Integer read fDisplayHeight write fDisplayHeight;

    property Minimap: TBitmap32 read fMinimap;
    property MinimapScrollFreeze: Boolean read fMinimapScrollFreeze write SetMinimapScrollFreeze;

    property Zoom: Integer read GetZoom write SetZoom;
    property MaxZoom: Integer read GetMaxZoom;

    property FrameSkip: Integer read CheckFrameSkip;
    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
  end;

const
  NUM_SKILL_ICONS = 17;
  NUM_FONT_CHARS = 45;

const
  SKILL_NAMES: array[0..NUM_SKILL_ICONS - 1] of string = (
      'walker', 'climber', 'swimmer', 'floater', 'glider',
      'disarmer', 'bomber', 'stoner', 'blocker', 'platformer',
      'builder', 'stacker', 'basher', 'fencer', 'miner',
      'digger', 'cloner' );

const
  // WARNING: The order of the strings has to correspond to the one
  //          of TSkillPanelButton in LemCore.pas!
  // As skill icons are dealt with separately, we use a placeholder here
  BUTTON_TO_STRING: array[TSkillPanelButton] of string = (
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png', 'empty_slot.png', 'empty_slot.png', 'empty_slot.png',
    'empty_slot.png',                                 {Skills end here}
    'empty_slot.png', 'icon_rr_minus.png', 'icon_rr_plus.png', 'icon_pause.png',
    'icon_nuke.png', 'icon_ff.png', 'icon_restart.png', 'icon_1fb.png',
    'icon_1ff.png', 'icon_clearphysics.png', 'icon_directional.png', 'icon_load_replay.png',
    'icon_directional.png'
    );


implementation

uses
  SysUtils, Types, Math, Windows, UMisc, PngInterface,
  GameControl, GameSound,
  LemTypes, LemReplay, LemStrings, LemNeoTheme,
  LemmixHotkeys, LemDosStructures;


constructor TBaseSkillPanel.Create(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  Create(aOwner);
  fGameWindow := aGameWindow;
end;

constructor TBaseSkillPanel.Create(aOwner: TComponent);
var
  c: Char;
  i: Integer;
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

  SetLength(fSkillIcons, NUM_SKILL_ICONS);
  for i := 0 to NUM_SKILL_ICONS - 1 do
  begin
    fSkillIcons[i] := TBitmap32.Create;
    fSkillIcons[i].DrawMode := dmBlend;
    fSkillIcons[i].CombineMode := cmMerge;
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
begin
  for i := 0 to NUM_FONT_CHARS - 1 do
    fInfoFont[i].Free;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i].Free;

  for i := 0 to NUM_SKILL_ICONS - 1 do
    fSkillIcons[i].Free;

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
  Result := (FirstSkillButtonIndex + 8) - 1; // we might want to use a CONST here, in case we later allow more than 8 skills per level
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
begin
  aName := AppPath + SFGraphicsPanel + aName;
  MaskColor := GameParams.Renderer.Theme.Colors[MASK_COLOR];

  TPngInterface.LoadPngFile(aName, aDst);
  TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(aName, '_mask.png'), MaskColor);
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
var
  i: Integer;
begin
  // Load the erasing icon first
  GetGraphic('skill_count_erase.png', fSkillCountErase);

  for i := 0 to NUM_SKILL_ICONS - 1 do
    GetGraphic('icon_' + SKILL_NAMES[i] + '.png', fSkillIcons[i]);
end;

procedure TBaseSkillPanel.LoadSkillFont;
var
  c: Char;
  i: Integer;
  SrcRect: TRect;
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
end;


procedure TBaseSkillPanel.ReadBitmapFromStyle;
var
  ButtonList: TPanelButtonArray;
  MinimapRegion : TBitmap32;
  i: Integer;
begin
  fOriginal.SetSize(PanelWidth, PanelHeight);
  fOriginal.Clear($FF000000);

  // Get array of buttons to draw
  ButtonList := GetButtonList;
  Assert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

  // Draw empty panel
  DrawBlankPanel(Length(ButtonList));

  // Draw single buttons icons
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
      fSkillIcons[Integer(Skill)].DrawTo(fImage.Bitmap, ButRect.Left, ButRect.Top);
      fSkillIcons[Integer(Skill)].DrawTo(fOriginal, ButRect.Left, ButRect.Top);
    end;
  end;

  if ButtonIndex <= LastSkillButtonIndex then
  begin
    EmptySlot := TBitmap32.Create;
    try
      GetGraphic('empty_slot.png', EmptySlot);
      EmptySlot.DrawMode := dmBlend;
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
    end
    else if ButtonList[i] > spbNone then
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
  ViewRect := Rect(0, 0, fDisplayWidth div 8 + 2, fDisplayHeight div 8 + 2);
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
  if (fHighlitSkill = aButton) and Highlight then Exit;
  if (fHighlitSkill = spbNone) and not Highlight then Exit;
  if fButtonRects[aButton].Left <= 0 then Exit;

  if Highlight then
    DrawHightlight(aButton)
  else
    RemoveHightlight(aButton);
end;

procedure TBaseSkillPanel.DrawHightlight(aButton: TSkillPanelButton);
var
  BorderRect: TRect;
begin
  if aButton < spbNone then // we don't want to memorize this for eg. fast forward
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

procedure TBaseSkillPanel.RemoveHightlight(aButton: TSkillPanelButton);
var
  BorderRect, EraseRect: TRect;
begin
  if aButton < spbNone then
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
  if (aNumber = 0) and GameParams.BlackOutZero then Exit;

  // Check for locked release rate icon
  if (aButton = spbFaster) and (Level.Info.ReleaseRateLocked or (Level.Info.ReleaseRate = 99)) then
    fSkillLock.DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1)
  // Check for infinite icon
  else if aNumber > 99 then
    fSkillInfinite.DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1)
  // Otherwise draw the digits
  else if aNumber < 10 then
  begin
    NumberStr := LeadZeroStr(aNumber, 2);
    fSkillFont[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 1, ButtonTop + 1);
  end
  else
  begin
    NumberStr := LeadZeroStr(aNumber, 2);
    fSkillFont[NumberStr[1], 1].DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1);
    fSkillFont[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 3, ButtonTop + 1);
  end;
end;

{-----------------------------------------
    Info string at top
-----------------------------------------}
procedure TBaseSkillPanel.DrawNewStr;
var
  Old, New: char;
  i, CharID: integer;
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

      if CharID >= 0 then
        fInfoFont[CharID].DrawTo(fImage.Bitmap, (i - 1) * 8, 0)
      else // draw black rectangle
        fImage.Bitmap.FillRectS((i - 1) * 8, 0, i * 8, 16, 0);
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

  DrawSkillCount(spbSlower, Level.Info.ReleaseRate);
  DrawSkillCount(spbFaster, Game.CurrentReleaseRate);

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

  if L.LemIsZombie or GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo) then
  begin
    Result := '-----';
    if L.LemIsClimber then Result[1] := 'C';
    if L.LemIsSwimmer then Result[2] := 'S';
    if L.LemIsFloater then Result[3] := 'F';
    if L.LemIsGlider then Result[3] := 'G';
    if L.LemIsMechanic then Result[4] := 'D';
    if L.LemIsZombie then Result[5] := 'Z';
  end
  else if not (L.LemAction in [baBuilding, baPlatforming, baStacking, baBashing, baMining, baDigging, baBlocking]) then
  begin
    i := 0;
    if L.LemIsClimber then DoInc(SClimber);
    if L.LemIsSwimmer then DoInc(SSwimmer);
    if L.LemIsFloater then DoInc(SFloater);
    if L.LemIsGlider then DoInc(SGlider);
    if L.LemIsMechanic then DoInc(SMechanic);
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

  Move(S[1], fNewDrawStr[Pos], LEN);
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

  Move(S[1], fNewDrawStr[Pos], LEN);
end;

procedure TBaseSkillPanel.SetInfoLemAlive(Pos: Integer);
var
  LemNum, LemToSave: Integer;
  Blinking : Boolean;
  S: string;
const
  LEN = 4;
begin
  LemNum := Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead;
  Assert(LemNum >= 0, 'Negative number of alive lemmings displayed');
  LemToSave := Level.Info.RescueCount - Game.LemmingsSaved - Game.SkillCount[spbCloner];
  Blinking := GameParams.LemmingBlink and fIsBlinkFrame and (LemNum < LemToSave);

  if Blinking then
    S := StringOfChar(' ', LEN)
  else
    S := IntToStr(LemNum);

  if Length(S) < LEN then
    S := PadL(PadR(S, LEN - 1), LEN);

  Move(S[1], fNewDrawStr[Pos], Len);
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

  Move(S[1], fNewDrawStr[Pos], LEN);
end;

procedure TBaseSkillPanel.SetInfoTime(PosMin, PosSec: Integer);
var
  Time : Integer;
  Blinking : Boolean;
  S: string;
const
  LEN = 2;
begin
  if Level.Info.HasTimeLimit then
  begin
    Time := Level.Info.TimeLimit - Game.CurrentIteration div 17;
    Blinking := GameParams.TimerBlink and fIsBlinkFrame and (Time <= 30);
  end
  else
  begin
    Time := Game.CurrentIteration div 17;
    Blinking := false;
  end;

  // Minutes
  if Blinking then
    S := StringOfChar(' ', LEN)
  else
    S := PadL(IntToStr(Time div 60), 2);
  Move(S[1], fNewDrawStr[PosMin], LEN);

  // Seconds
  if Blinking then
    S := StringOfChar(' ', LEN)
  else
    S := LeadZeroStr(Time mod 60, 2);
  Move(S[1], fNewDrawStr[PosSec], LEN);
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
  fGameWindow.ApplyMouseTrap;
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
  if (aButton in [spbSlower, spbFaster, spbNuke]) and GameParams.ExplicitCancel then Exit;

  if Game.Replaying and not Level.Info.ReleaseRateLocked then
  begin
    if    ((aButton = spbSlower) and (Game.CurrentReleaseRate > Level.Info.ReleaseRate))
       or ((aButton = spbFaster) and (Game.CurrentReleaseRate < 99)) then
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
  fGameWindow.ApplyMouseTrap;
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
  if NewZoom = Trunc(fImage.Scale) then Exit;

  Width := fGameWindow.GetWidth;    // for the whole skill panel
  Height := fGameWindow.GetHeight;  // for the whole skill panel

  fImage.Width := PanelWidth * NewZoom;
  fImage.Height := PanelHeight * NewZoom;
  fImage.Left := (Width - Image.Width) div 2;
  fImage.Scale := NewZoom;

  fMinimapImage.Width := MinimapWidth * NewZoom;
  fMinimapImage.Height := MinimapHeight * NewZoom;
  fMinimapImage.Left := MinimapRect.Left * NewZoom + Image.Left;
  fMinimapImage.Top := MinimapRect.Top * NewZoom;
  fMinimapImage.Scale := NewZoom;
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

end.
