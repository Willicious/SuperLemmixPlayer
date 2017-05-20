unit GameBaseSkillPanel;

interface

uses
  Classes, Controls, Types, Math, Windows,
  GR32, GR32_Image, GR32_Layers,
  GameControl,
  GameWindowInterface,
  LemCore, LemGame, LemLevel,
  LemDosStyle, LemDosStructures, LemStrings;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TBaseSkillPanel = class(TCustomControl)

  private
    fGame                 : TLemmingGame;

    function GetLevel: TLevel;

  protected
    fGameWindow           : IGameWindow;
    fImage                : TImage32;

    fLastClickFrameskip: Cardinal;

    fStyle         : TBaseDosLemmingStyle;


    fMinimapImage  : TImage32;

    fOriginal      : TBitmap32;
    fMinimapRegion : TBitmap32;
    fMinimapTemp   : TBitmap32;
    fMinimap       : TBitmap32;

    fMinimapScrollFreeze: Boolean;

    fSkillFont     : array['0'..'9', 0..1] of TBitmap32;
    fSkillCountErase : TBitmap32;
    fSkillLock     : TBitmap32;
    fSkillInfinite : TBitmap32;
    fSkillIcons    : array of TBitmap32;
    fInfoFont      : array of TBitmap32; {%} { 0..9} {A..Z} // make one of this!

    fButtonRects   : array[TSkillPanelButton] of TRect;
    fRectColor     : TColor32;

    fSelectDx      : Integer;

    fOnMinimapClick            : TMinimapClickEvent; // event handler for minimap

    fHighlitSkill: TSkillPanelButton;
    fLastHighlitSkill: TSkillPanelButton; // to avoid sounds when shouldn't be played
    fSkillCounts: Array[TSkillPanelButton] of Integer; // includes "non-skill" buttons as error-protection, but also for the release rate

    fDoHorizontalScroll: Boolean;
    fDisplayWidth: Integer;
    fDisplayHeight: Integer;

    fLastDrawnStr: string[38];
    fNewDrawStr: string[38];

    function GetFrameSkip: Integer;
    function GetZoom: Integer; virtual; abstract;
    function GetMaxZoom: Integer;
    procedure SetZoom(aZoom: Integer); virtual; abstract;
    procedure SetMinimapScrollFreeze(aValue: Boolean);


    function PanelWidth: Integer; virtual; abstract;
    function PanelHeight: Integer; virtual; abstract;

    property Level : TLevel read GetLevel;
    property Game  : TLemmingGame read fGame;

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

  public
    constructor Create(aOwner: TComponent); overload; override;
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); overload; virtual;
    destructor Destroy; override;

    procedure SetSkillIcons; virtual; abstract;
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

    property FrameSkip: Integer read GetFrameSkip;
    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
    procedure SetStyleAndGraph(const Value: TBaseDosLemmingStyle; aScale: Integer); virtual; abstract;

    procedure SetGame(const Value: TLemmingGame);
  end;

const
  NUM_SKILL_ICONS = 17;
  NUM_FONT_CHARS = 45;

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

  Color := $000000;
  ParentBackground := false;

  fLastClickFrameskip := GetTickCount;

  DoubleBuffered := true;

  fImage := TImage32.Create(Self);
  fImage.Parent := Self;
  fImage.RepaintMode := rmOptimizer;

  fMinimapImage := TImage32.Create(Self);
  fMinimapImage.Parent := Self;
  fMinimapImage.RepaintMode := rmOptimizer;

  fMinimapRegion := TBitmap32.Create;
  fMinimapTemp := TBitmap32.Create;
  fMinimap := TBitmap32.Create;

  fImage.OnMouseDown := ImgMouseDown;
  fImage.OnMouseMove := ImgMouseMove;
  fImage.OnMouseUp := ImgMouseUp;

  fMinimapImage.OnMouseDown := MinimapMouseDown;
  fMinimapImage.OnMouseMove := MinimapMouseMove;
  fMinimapImage.OnMouseUp := MinimapMouseUp;

  fRectColor := DosVgaColorToColor32(DosInLevelPalette[3]);

  fOriginal := TBitmap32.Create;

  SetLength(fInfoFont, NUM_FONT_CHARS);
  for i := 0 to NUM_FONT_CHARS - 1 do
    fInfoFont[i] := TBitmap32.Create;

  SetLength(fSkillIcons, NUM_SKILL_ICONS);
  for i := 0 to NUM_SKILL_ICONS - 1 do
    fSkillIcons[i] := TBitmap32.Create;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i] := TBitmap32.Create;

  fSkillInfinite := TBitmap32.Create;
  fSkillCountErase := TBitmap32.Create;
  fSkillLock := TBitmap32.Create;


  // info positions types:
  // stringspositions=cursor,out,in,time=1,15,24,32
  // 1. BUILDER(23)             1/14               0..13      14
  // 2. OUT 28                  15/23              14..22      9
  // 3. IN 99%                  24/31              23..30      8
  // 4. TIME 2-31               32/40              31..39      9
                                                           //=40
  fLastDrawnStr := StringOfChar(' ', 38);
  fNewDrawStr := StringOfChar(' ', 38);
  fNewDrawStr := SSkillPanelTemplate;

  Assert(length(fnewdrawstr) = 38, 'length error infostring');

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

  fMinimapRegion.Free;
  fMinimapTemp.Free;
  fMinimap.Free;

  fOriginal.Free;

  fImage.Free;
  fMinimapImage.Free;
  inherited;
end;




function TBaseSkillPanel.GetFrameSkip: Integer;
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
