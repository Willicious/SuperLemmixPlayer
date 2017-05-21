unit GameBaseSkillPanel;

interface

uses
  Classes, Controls, SysUtils, Types, Math, Windows,

  GR32, GR32_Image, GR32_Layers,
  PngInterface,
  GameControl,
  GameWindowInterface,
  LemTypes, LemCore, LemStrings, LemNeoTheme,
  LemGame, LemLevel,
  LemDosStyle, LemDosStructures;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TStringArray = array of string;

type
  TBaseSkillPanel = class(TCustomControl)

  private
    fGame                   : TLemmingGame;
    fIconBmp                : TBitmap32;   // for temporary storage

    function GetLevel       : TLevel;

    function CheckFrameSkip : Integer; // Checks the duration since the last click on the panel.

    procedure LoadPanelFont;
    procedure LoadSkillIcons;
    procedure LoadSkillFont;

  protected
    fGameWindow           : IGameWindow;
    fImage                : TImage32;

    fLastClickFrameskip: Cardinal;

    fStyle         : TBaseDosLemmingStyle;

    fMinimapImage  : TImage32;

    fOriginal      : TBitmap32;
    fMinimapTemp   : TBitmap32;
    fMinimap       : TBitmap32;

    fMinimapScrollFreeze: Boolean;

    fSkillFont        : array['0'..'9', 0..1] of TBitmap32;
    fSkillCountErase  : TBitmap32;
    fSkillLock        : TBitmap32;
    fSkillInfinite    : TBitmap32;
    fSkillIcons       : array of TBitmap32;
    fInfoFont         : array of TBitmap32; {%} { 0..9} {A..Z} // make one of this!

    fButtonRects      : array[TSkillPanelButton] of TRect;
    fRectColor        : TColor32;

    fSelectDx         : Integer;

    fOnMinimapClick            : TMinimapClickEvent; // event handler for minimap

    fHighlitSkill: TSkillPanelButton;
    fLastHighlitSkill: TSkillPanelButton; // to avoid sounds when shouldn't be played
    fSkillCounts: array[TSkillPanelButton] of Integer; // includes "non-skill" buttons as error-protection, but also for the release rate

    fDoHorizontalScroll: Boolean;
    fDisplayWidth: Integer;
    fDisplayHeight: Integer;

    fLastDrawnStr: string[38];
    fNewDrawStr: string[38];

    function FirstButtonRect: TRect; virtual;
    function ButtonRect(Index: Integer): TRect;
    function MinimapRect: TRect; virtual; abstract;
    function MinimapWidth: Integer;
    function MinimapHeight: Integer;

    function FirstSkillButtonIndex: Integer; virtual;

    procedure ReadBitmapFromStyle;
    function GetButtonList: TStringArray; virtual; abstract;
    procedure DrawBlankPanel(NumButtons: Integer);
    procedure AddButtonImage(ButtonName: string; Index: Integer);
    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); virtual; abstract;

    function PanelWidth: Integer; virtual; abstract;
    function PanelHeight: Integer; virtual; abstract;

    property Level : TLevel read GetLevel;
    property Game  : TLemmingGame read fGame;


    function GetZoom: Integer; virtual; abstract;
    function GetMaxZoom: Integer;
    procedure SetZoom(aZoom: Integer); virtual; abstract;
    procedure SetMinimapScrollFreeze(aValue: Boolean);

    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual; abstract;
    procedure ImgMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); virtual; abstract;
    procedure ImgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);  virtual; abstract;

    procedure MinimapMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);  virtual; abstract;
    procedure MinimapMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);  virtual; abstract;
    procedure MinimapMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);  virtual; abstract;

    procedure SetTimeLimit(Status: Boolean); virtual; abstract;

    procedure SetButtonRects; virtual; abstract;
  public
    constructor Create(aOwner: TComponent); overload; override;
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); overload; virtual;
    destructor Destroy; override;

    procedure SetSkillIcons;
    procedure RefreshInfo; virtual; abstract;
    procedure SetCursor(aCursor: TCursor); virtual; abstract;

    property Image: TImage32 read fImage;

    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer); virtual; abstract;
    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean); virtual; abstract;
    procedure DrawMinimap; virtual; abstract;

    property OnMinimapClick: TMinimapClickEvent read fOnMinimapClick write fOnMinimapClick;

    property DisplayWidth: Integer read fDisplayWidth write fDisplayWidth;
    property DisplayHeight: Integer read fDisplayHeight write fDisplayHeight;

    property Minimap: TBitmap32 read fMinimap;
    property MinimapScrollFreeze: Boolean read fMinimapScrollFreeze write SetMinimapScrollFreeze;

    property Zoom: Integer read GetZoom write SetZoom;
    property MaxZoom: Integer read GetMaxZoom;

    property FrameSkip: Integer read CheckFrameSkip;
    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
    procedure SetStyleAndGraph(const Value: TBaseDosLemmingStyle; aScale: Integer); virtual; abstract;

    procedure SetGame(const Value: TLemmingGame);
  end;

const
  NUM_SKILL_ICONS = 17;
  NUM_FONT_CHARS = 45;

  TEXT_TEMPLATE = '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' ' + #94 + '_...' + ' ' + #95 +  '_.-..';

const
  SKILL_NAMES: array[0..NUM_SKILL_ICONS - 1] of string = (
      'walker', 'climber', 'swimmer', 'floater', 'glider',
      'disarmer', 'bomber', 'stoner', 'blocker', 'platformer',
      'builder', 'stacker', 'basher', 'fencer', 'miner',
      'digger', 'cloner' );

implementation

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

  fMinimapImage := TImage32.Create(Self);
  fMinimapImage.Parent := Self;
  fMinimapImage.RepaintMode := rmOptimizer;

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
  // WARNING:
  // THE FOLLOWING INFO NEED NO LONGER TO BE TRUE!!!

  // info positions types:
  // stringspositions=cursor,out,in,time=1,15,24,32
  // 1. BUILDER(23)             1/14               0..13      14
  // 2. OUT 28                  15/23              14..22      9
  // 3. IN 99%                  24/31              23..30      8
  // 4. TIME 2-31               32/40              31..39      9
                                                           //=40
  fLastDrawnStr := StringOfChar(' ', 38);
  fNewDrawStr := TEXT_TEMPLATE;

  Assert(Length(fNewDrawStr) = 38, 'SkillPanel.Create: InfoString has not length 38 characters.');

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

function TBaseSkillPanel.FirstSkillButtonIndex: Integer;
begin
  Result := 2;
end;

function TBaseSkillPanel.MinimapWidth: Integer;
begin
  Result := MinimapRect.Right - MinimapRect.Left;
end;

function TBaseSkillPanel.MinimapHeight: Integer;
begin
  Result := MinimapRect.Bottom - MinimapRect.Top;
end;


{-----------------------------------------
    Draw the initial skill panel
-----------------------------------------}
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
  (*
  // This was originally there, but it seems we don't need it.
  if   (ButtonName = 'icon_rr_minus.png')
    or (ButtonName = 'icon_rr_plus.png')
    or (ButtonName = 'empty_slot.png') then
    fSkillCountErase.DrawTo(fOriginal, ButtonRect(Index).Left, ButtonRect(Index).Top);
  *)

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
  fSkillCountErase.SetSize(16, 23);
  GetGraphic('skill_count_erase.png', fSkillCountErase);

  for i := 0 to NUM_SKILL_ICONS - 1 do
  begin
    fSkillIcons[i].SetSize(16, 23);
    GetGraphic('icon_' + SKILL_NAMES[i] + '.png', fSkillIcons[i]);
  end;
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
  ButtonList: TStringArray;
  MinimapRegion : TBitmap32;
  i: Integer;
begin
  if not (fStyle is TBaseDosLemmingStyle) then Exit;

  SetButtonRects;

  fOriginal.SetSize(PanelWidth, PanelHeight);
  fOriginal.Clear($FF000000);

  // Get array of buttons to draw
  ButtonList := GetButtonList;
  Assert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

  // Draw empty panel
  DrawBlankPanel(Length(ButtonList));

  // Draw single buttons icons
  for i := 0 to Length(ButtonList) - 1 do
    AddButtonImage(ButtonList[i], i);

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


procedure TBaseSkillPanel.SetSkillIcons;
var
  ButtonIndex: Integer;
  ButRect: TRect;
  Skill: TSkillPanelButton;
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
end;

{-----------------------------------------
    User interaction
-----------------------------------------}
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


function TBaseSkillPanel.GetLevel: TLevel;
begin
  Result := GameParams.Level;
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
  SetTimeLimit(Level.Info.HasTimeLimit);
end;

end.
