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

    fPanelWidth: Integer;
    fLastClickFrameskip: Cardinal;

    fStyle         : TBaseDosLemmingStyle;

    fImg           : TImage32;
    fMinimapImg    : TImage32;

    fOriginal      : TBitmap32;
    fMinimapRegion : TBitmap32;
    fMinimapTemp   : TBitmap32;
    fMinimap       : TBitmap32;

    fMinimapScrollFreeze: Boolean;

    fSkillFont     : array['0'..'9', 0..1] of TBitmap32;
    fSkillCountErase : TBitmap32;
    fSkillLock     : TBitmap32;
    fSkillInfinite : TBitmap32;
    fSkillIcons    : array[0..16] of TBitmap32;
    fInfoFont      : array[0..44] of TBitmap32; {%} { 0..9} {A..Z} // make one of this!

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


    function GetPanelWidth: Integer; virtual; abstract;
    function GetPanelHeight: Integer; virtual; abstract;

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

    property Image: TImage32 read fImg;

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

  fPanelWidth := GetPanelWidth;

  fLastClickFrameskip := GetTickCount;

  DoubleBuffered := true;

  fImg := TImage32.Create(Self);
  fImg.Parent := Self;
  fImg.RepaintMode := rmOptimizer;

  fMinimapImg := TImage32.Create(Self);
  fMinimapImg.Parent := Self;
  fMinimapImg.RepaintMode := rmOptimizer;

  fMinimapRegion := TBitmap32.Create;
  fMinimapTemp := TBitmap32.Create;
  fMinimap := TBitmap32.Create;

  fImg.OnMouseDown := ImgMouseDown;
  fImg.OnMouseMove := ImgMouseMove;
  fImg.OnMouseUp := ImgMouseUp;

  fMinimapImg.OnMouseDown := MinimapMouseDown;
  fMinimapImg.OnMouseMove := MinimapMouseMove;
  fMinimapImg.OnMouseUp := MinimapMouseUp;

  fRectColor := DosVgaColorToColor32(DosInLevelPalette[3]);

  fOriginal := TBitmap32.Create;

  for i := 0 to 44 do
    fInfoFont[i] := TBitmap32.Create;

  for i := 0 to 16 do
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
  for i := 0 to 43 do
    fInfoFont[i].Free;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i].Free;

  for i := 0 to 16 do
    fSkillIcons[i].Free;

  fSkillInfinite.Free;
  fSkillCountErase.Free;
  fSkillLock.Free;

  fMinimapRegion.Free;
  fMinimapTemp.Free;
  fMinimap.Free;

  fOriginal.Free;

  fImg.Free;
  fMinimapImg.Free;
  inherited;
end;

function TBaseSkillPanel.GetFrameSkip: Integer;
var
  P: TPoint;
begin
  Result := 0;
  if GetTickCount - fLastClickFrameskip < 250 then Exit;
  P := Image.ControlToBitmap(Image.ScreenToClient(Mouse.CursorPos));
  if GetKeyState(VK_LBUTTON) < 0 then
    if PtInRect(fButtonRects[spbBackOneFrame], P) then
      Result := -1
    else if PtInRect(fButtonRects[spbForwardOneFrame], P) then
      Result := 1;

  if Result <> 0 then
    fLastClickFrameskip := GetTickCount - 150;
end;


function TBaseSkillPanel.GetLevel: TLevel;
begin
  Result := GameParams.Level;
end;

function TBaseSkillPanel.GetMaxZoom: Integer;
begin
  Result := Max(Min(GameParams.MainForm.ClientWidth div fPanelWidth, (GameParams.MainForm.ClientHeight - 160) div 40), 1);
end;

procedure TBaseSkillPanel.SetMinimapScrollFreeze(aValue: Boolean);
begin
  fMinimapScrollFreeze := aValue;
  if fMinimapScrollFreeze then DrawMinimap;
end;

procedure TBaseSkillPanel.SetGame(const Value: TLemmingGame);
begin
  fGame := Value;
  SetTimeLimit(GameParams.Level.Info.HasTimeLimit);
end;

end.
