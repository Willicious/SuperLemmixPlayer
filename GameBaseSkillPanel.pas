unit GameBaseSkillPanel;

// TODO - Show hotkey labels on panel buttons

interface

uses
  System.Types, System.StrUtils, Graphics,
  Classes, Controls, GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  GameWindowInterface,
  LemAnimationSet, LemMetaAnimation, LemNeoLevelPack, LemProjectile,
  LemCore, LemLemming, LemGame, LemLevel, LemGadgets, LemTalisman,
  SharedGlobals;

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;

type
  TPanelButtonArray = array of TSkillPanelButton;

type
  TFontBitmapArray = array['0'..'9', 0..1] of TBitmap32;

type
  TTalismanStatus = (tsFailed, tsFailing, tsSucceeding);

  TBaseSkillPanel = class(TCustomControl)
  private
    fGame                 : TLemmingGame;
    fShowUsedSkills       : Boolean;
    fRRIsPressed          : Boolean;

    // Talisman button info
    fTalismanIconIndex    : Integer;
    fCurrentTalisman      : Integer;
    fTalSaveRequirement   : Integer;
    fTalHasSaveRequirement: Boolean;
    fTalTimeLimit         : Integer;
    fTalHasTimeLimit      : Boolean;
    fTalMaxSkillTypes     : Integer;
    fSkillTypesUsed       : Integer;
    fTalHasMaxSkillTypes  : Boolean;

    fPanelButtons         : TBitmap32; // for storing panel buttons & button text
    fPanelIcons           : TBitmap32; // for storing all panel icons

    fMinimapViewRectColor : TColor32;
    fSelectDx             : Integer;
    fOnMinimapClick       : TMinimapClickEvent; // Event handler for minimap

    procedure LoadPanelIcons;
    procedure LoadSkillIcons;
    procedure LoadSkillFont;

    function GetLevel: TLevel;

    procedure SetShowUsedSkills(const Value: Boolean);
  protected
    fGameWindow           : IGameWindow;
    fButtonRects          : array[TSkillPanelButton] of TRect;

    fImage                : TImage32;  // Panel image to be displayed
    fOriginal             : TBitmap32; // Original panel image
    fMinimap              : TBitmap32; // Full minimap image
    fMinimapImage         : TImage32;  // Minimap to be displayed
    fMinimapTemp          : TBitmap32; // Temp image, to create fMinimapImage from fMinimap

    fResizePercentage     : Single;
    fResizedPanelWidth    : Integer;
    fResizedPanelHeight   : Integer;
    fResizedMinimapLeft   : Integer;
    fResizedMinimapTop    : Integer;
    fResizedMinimapWidth  : Integer;
    fResizedMinimapHeight : Integer;

    fMinimapScrollFreeze  : Boolean;

    fSkillFont            : TFontBitmapArray;
    fSkillFontInvert      : TFontBitmapArray;
    fSkillFontTalActive   : TFontBitmapArray;
    fSkillFontTalFailed   : TFontBitmapArray;
    fSkillOvercount       : array[100..MAXIMUM_SI] of TBitmap32;
    fSkillCountErase      : TBitmap32;
    fSkillCountEraseInvert: TBitmap32;
    fSkillLock            : TBitmap32;
    fSkillInfinite        : TBitmap32;
    fSkillInfiniteMode    : TBitmap32;
    fSkillSelected        : TBitmap32;
    fSkillTypesHighlight  : TBitmap32;
    fSkillTypesOvercount  : TBitmap32;
    fSquiggleHighlight    : TBitmap32;
    fTurboHighlight       : TBitmap32;
    fSkillIcons           : array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of TBitmap32;

    fHighlitSkill         : TSkillPanelButton;
    fLastHighlitSkill     : TSkillPanelButton; // To avoid sounds when shouldn't be played

    fButtonHint           : String;

    // Global stuff
    property Level: TLevel read GetLevel;
    property Game: TLemmingGame read fGame;

    // Helper functions for positioning
    function FirstButtonRect: TRect; virtual;
    function ButtonRect(Index: Integer): TRect;
    function MinimapRect: TRect; virtual; abstract;
    function MinimapWidth: Integer;
    function MinimapHeight: Integer;
    function ReplayIconRect: TRect; virtual; abstract;
    function CollectibleIconRect: TRect; virtual; abstract;
    function TalismanIconRect: TRect; virtual; abstract;
    function HatchIconRect: TRect; virtual; abstract;
    function AliveIconRect: TRect; virtual; abstract;
    function ExitIconRect: TRect; virtual; abstract;
    function TimeIconRect: TRect; virtual; abstract;

    function FirstSkillButtonIndex: Integer; virtual;
    function LastSkillButtonIndex: Integer; virtual;

    // Drawing routines for the buttons and minimap
    procedure ReadBitmapFromStyle;
    function GetButtonList: TPanelButtonArray; virtual; abstract;
    procedure DrawBlankPanel(NumButtons: Integer);
    procedure AddButtonImage(ButtonName: string; Index: Integer);
    procedure SetButtonRects;
    procedure SetSkillIcons;
    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer; CursorOverInvincible: Boolean = False);

    // Drawing routines for the info string at the top
    function GetCursorInfoString: String;
    function GetCollectibleString: String;
    function GetHatchCountString: String;
    function GetLemsAliveString: String;
    function GetLemsSavedString: String;
    function GetTimeString: String;

    procedure DrawPanelMessage;
    procedure DrawCursorInfo;
    procedure DrawPanelIcon(Index, X, Y: Integer);
    procedure DrawReplayIcon;
    procedure DrawCollectibleIcon;
    procedure DrawTalismanIcon(Index: Integer);
    procedure DrawHatchInfo;
    procedure DrawLemsAliveInfo;
    procedure DrawLemsSavedInfo;
    procedure DrawTimeInfo;

    function GetLemReplayTaskString(L: TLemming): String;
    function GetSkillString(L: TLemming): String;
    function GetPickupString(P: TGadget): String;

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

    procedure HandleTalismanIconClick;
    procedure DrawMaxSkillTypes;

    function GetSpawnIntervalValue(aSI: Integer): Integer; // Returns the SI or the equivalent RR, depending on user's settings
  public
    constructor Create(aOwner: TComponent); override;
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); virtual;
    destructor Destroy; override;

    procedure PrepareForGame;
    procedure ClearInfo;
    procedure RefreshInfo;
    procedure SetCursor(aCursor: TCursor);
    procedure SetOnMinimapClick(const Value: TMinimapClickEvent);
    procedure SetGame(const Value: TLemmingGame);

    procedure PlayReleaseRateSound;
    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
    procedure DrawHighlight(aButton: TSkillPanelButton); virtual;
    procedure DrawMaxSkillTypesHighlight(aButton: TSkillPanelButton; Overcount: Boolean);
    procedure DrawSquiggleHighlight;
    procedure DrawTurboHighlight;
    procedure RemoveButtonHighlights;
    procedure RemoveMaxSkillTypesHighlights;
    procedure RemoveHighlight(aButton: TSkillPanelButton); virtual;

    procedure DrawMinimap; virtual;

    procedure ResizePanelWithWindow;
    procedure GetButtonHints(aButton: TSkillPanelButton);

    function LevelHasCollectibles: Boolean;
    function LevelHasTalismans: Boolean;

    function PanelWidth: Integer; virtual; abstract;
    function PanelHeight: Integer; virtual; abstract;

    function CursorOverSkillButton(out Button: TSkillPanelButton): Boolean;
    function CursorOverClickableItem: Boolean;
    function CursorOverPanelItem: Boolean;
    function CursorOverIcon(aIconRect: TRect): Boolean;
    function CursorOverMinimap: Boolean;

    property Image: TImage32 read fImage;

    property Minimap: TBitmap32 read fMinimap;
    property MinimapScrollFreeze: Boolean read fMinimapScrollFreeze write SetMinimapScrollFreeze;

    property ResizePercentage: Single read fResizePercentage write fResizePercentage;
    property ResizedPanelWidth: Integer read fResizedPanelWidth write fResizedPanelWidth;
    property ResizedPanelHeight: Integer read fResizedPanelHeight write fResizedPanelHeight;
    property ResizedMinimapLeft: Integer read fResizedMinimapLeft write fResizedMinimapLeft;
    property ResizedMinimapTop: Integer read fResizedMinimapTop write fResizedMinimapTop;
    property ResizedMinimapWidth: Integer read fResizedMinimapWidth write fResizedMinimapWidth;
    property ResizedMinimapHeight: Integer read fResizedMinimapHeight write fResizedMinimapHeight;

    property SkillPanelSelectDx: Integer read fSelectDx write fSelectDx;
    property ShowUsedSkills: Boolean read fShowUsedSkills write SetShowUsedSkills;
    property RRIsPressed: Boolean read fRRIsPressed write fRRIsPressed;
    property ButtonHint: String read fButtonHint write fButtonHint;
  end;

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
    'empty_slot.png', 'empty_slot.png', //'empty_slot.png', 'empty_slot.png',
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
  LemmixHotkeys,
  FSuperLemmixLevelSelect;


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
  ParentBackground := False;

  // Initialize images
  fImage := TImage32.Create(Self);
  fImage.Parent := Self;
  fImage.RepaintMode := rmOptimizer;
  fImage.ScaleMode := smResize;

  fMinimapImage := TImage32.Create(Self);
  fMinimapImage.Parent := Self;
  fMinimapImage.RepaintMode := rmOptimizer;
  fMinimapImage.ScaleMode := smScale;
  fMinimapImage.BitmapAlign := baCustom;

  fPanelButtons := TBitmap32.Create;
  fPanelButtons.DrawMode := dmBlend;
  fPanelButtons.CombineMode := cmMerge;

  fPanelIcons := TBitmap32.Create;
  fPanelIcons.DrawMode := dmBlend;
  fPanelIcons.CombineMode := cmMerge;

  fMinimapTemp := TBitmap32.Create;
  fMinimap := TBitmap32.Create;

  fOriginal := TBitmap32.Create;
  fOriginal.Resampler := TLinearResampler.Create;

  // Initialize event handlers
  fImage.OnMouseDown := ImgMouseDown;
  fImage.OnMouseMove := ImgMouseMove;
  fImage.OnMouseUp := ImgMouseUp;

  fMinimapImage.OnMouseDown := MinimapMouseDown;
  fMinimapImage.OnMouseMove := MinimapMouseMove;
  fMinimapImage.OnMouseUp := MinimapMouseUp;

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

      fSkillFontTalActive[c, i] := TBitmap32.Create;
      fSkillFontTalActive[c, i].DrawMode := dmBlend;
      fSkillFontTalActive[c, i].CombineMode := cmMerge;

      fSkillFontTalFailed[c, i] := TBitmap32.Create;
      fSkillFontTalFailed[c, i].DrawMode := dmBlend;
      fSkillFontTalFailed[c, i].CombineMode := cmMerge;
    end;

  fSkillInfinite := TBitmap32.Create;
  fSkillInfinite.DrawMode := dmBlend;
  fSkillInfinite.CombineMode := cmMerge;

  fSkillInfiniteMode := TBitmap32.Create;
  fSkillInfiniteMode.DrawMode := dmBlend;
  fSkillInfiniteMode.CombineMode := cmMerge;

  fSkillSelected := TBitmap32.Create;
  fSkillSelected.DrawMode := dmBlend;
  fSkillSelected.CombineMode := cmMerge;

  fSkillTypesHighlight := TBitmap32.Create;
  fSkillTypesHighlight.DrawMode := dmBlend;
  fSkillTypesHighlight.CombineMode := cmMerge;

  fSkillTypesOvercount := TBitmap32.Create;
  fSkillTypesOvercount.DrawMode := dmBlend;
  fSkillTypesOvercount.CombineMode := cmMerge;

  fSquiggleHighlight := TBitmap32.Create;
  fSquiggleHighlight.DrawMode := dmBlend;
  fSquiggleHighlight.CombineMode := cmMerge;

  fTurboHighlight := TBitmap32.Create;
  fTurboHighlight.DrawMode := dmBlend;
  fTurboHighlight.CombineMode := cmMerge;

  fSkillCountErase := TBitmap32.Create;
  fSkillCountErase.DrawMode := dmBlend;
  fSkillCountErase.CombineMode := cmMerge;

  fSkillCountEraseInvert := TBitmap32.Create;
  fSkillCountEraseInvert.DrawMode := dmBlend;
  fSkillCountEraseInvert.CombineMode := cmMerge;

  fSkillLock := TBitmap32.Create;
  fSkillLock.DrawMode := dmBlend;
  fSkillLock.CombineMode := cmMerge;

  if GameParams.AmigaTheme then
    fMinimapViewRectColor := $FF00DD00
  else
    fMinimapViewRectColor := $FF4444DD;

  fHighlitSkill := spbNone;
  fLastHighlitSkill := spbNone;

  for i := 100 to MAXIMUM_SI do                    
    fSkillOvercount[i] := TBitmap32.Create;

  fRRIsPressed := False;
  fTalismanIconIndex := 12;
  fCurrentTalisman := -1;
  fTalSaveRequirement := -1;
  fTalHasSaveRequirement := False;
  fTalTimeLimit := -1;
  fTalHasTimeLimit := False;
  fTalMaxSkillTypes := -1;
  fSkillTypesUsed := 0;
  fTalHasMaxSkillTypes := False;
end;

destructor TBaseSkillPanel.Destroy;
var
  c: Char;
  i: Integer;
  Button: TSkillPanelButton;
begin
  for c := '0' to '9' do
    for i := 0 to 1 do
    begin
      fSkillFont[c, i].Free;
      fSkillFontInvert[c, i].Free;
      fSkillFontTalActive[c, i].Free;
      fSkillFontTalFailed[c, i].Free;
    end;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillIcons[Button].Free;

  for i := 100 to MAXIMUM_SI do
    fSkillOvercount[i].Free;

  fSkillInfinite.Free;
  fSkillInfiniteMode.Free;
  fSkillSelected.Free;
  fSkillTypesHighlight.Free;
  fSkillTypesOvercount.Free;
  fSquiggleHighlight.Free;
  fTurboHighlight.Free;
  fSkillCountErase.Free;
  fSkillCountEraseInvert.Free;
  fSkillLock.Free;

  fMinimapTemp.Free;
  fMinimap.Free;

  fOriginal.Free;
  fImage.Free;
  fMinimapImage.Free;
  fPanelButtons.Free;
  fPanelIcons.Free;
  inherited;
end;

{-----------------------------------------
    Positions of buttons, ...
-----------------------------------------}
function TBaseSkillPanel.FirstButtonRect: TRect;
begin
  Result := Rect(2, 32, 30, 76);
end;

function TBaseSkillPanel.ButtonRect(Index: Integer): TRect;
begin
  Result := FirstButtonRect;
  OffsetRect(Result, Index * 32, 0);
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
  SrcFile: String;
  Target: TNeoLevelGroup;
begin
  // Check styles folder first
  SrcFile := AppPath + SFStyles + GameParams.Level.Info.GraphicSetName + SFIcons + aName;

  // Then levelpack folder
  if not FileExists(SrcFile) then
  begin
    Target := GameParams.CurrentLevel.Group;
    SrcFile := Target.Path + aName;

    while not (FileExists(SrcFile) or Target.IsBasePack or (Target.Parent = nil)) do
    begin
      Target := Target.Parent;
      SrcFile := Target.Path + aName;
    end;
  end;

  // Then default
  if not FileExists(SrcFile) then
  begin
    if GameParams.AmigaTheme then
      SrcFile := AppPath + SFGraphicsPanel + 'amiga/' + aName;

    if not FileExists(SrcFile) or not GameParams.AmigaTheme then
      SrcFile := AppPath + SFGraphicsPanel + aName;
  end;

  TPngInterface.LoadPngFile(SrcFile, aDst)
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
  for i := 1 to (NumButtons * 32 - 1) div SrcWidth do
  begin
    BlankPanel.DrawTo(fOriginal, DstRect, SrcRect);
    OffsetRect(DstRect, SrcWidth, 0);
  end;

  // Draw partial panel at the end
  DstRect.Right := ButtonRect(NumButtons - 1).Right + 2;
  DstRect.Bottom := ButtonRect(NumButtons - 1).Bottom + 2;
  SrcRect.Right := SrcRect.Left - DstRect.Left + DstRect.Right;
  SrcRect.Bottom := SrcRect.Top - DstRect.Top + DstRect.Bottom;
  BlankPanel.DrawTo(fOriginal, DstRect, SrcRect);

  BlankPanel.Free;
end;

procedure TBaseSkillPanel.AddButtonImage(ButtonName: string; Index: Integer);
begin
  if (Index >= FirstSkillButtonIndex) and (Index <= LastSkillButtonIndex) then
    Exit; // Otherwise, "empty_slot.png" placeholder causes some graphical glitches

  GetGraphic(ButtonName, fPanelButtons);
  fPanelButtons.DrawTo(fOriginal, ButtonRect(Index).Left, ButtonRect(Index).Top);
end;

procedure TBaseSkillPanel.LoadPanelIcons;
var
  Width: Integer;

  procedure AddGraphic(const Name: String);
  var
    Bitmap: TBitmap32;
    Combined: TBitmap32;
  begin
    Bitmap := TBitmap32.Create;
    Bitmap.DrawMode := dmBlend;
    try
      GetGraphic(Name, Bitmap);

      Combined := TBitmap32.Create;
      try
        Width := fPanelIcons.Width;
        Combined.SetSize(Width + Bitmap.Width, Max(fPanelIcons.Height, Bitmap.Height));
        fPanelIcons.DrawTo(Combined, 0, 0);

        Bitmap.DrawTo(Combined, Width, 0);
        fPanelIcons.Assign(Combined);
      finally
        Combined.Free;
      end;
    finally
      Bitmap.Free;
    end;
  end;
begin
  AddGraphic('panel_icons.png');
  AddGraphic('replay_icons.png');
  AddGraphic('talisman_icons.png');
end;

procedure TBaseSkillPanel.LoadSkillIcons;
const
  PANEL_FALLBACK_BRICK_COLOR = $FF00BB00;
var
  BrickColor: TColor32;
  Button: TSkillPanelButton;
  X, Y, FloaterY: Integer;
  Offset: TPoint;
  IconsImg: TBitmap32;

  procedure LoadIcons;
  var
    IconsImgPath, aStyle, aStylePath, aPath: String;
  begin
    IconsImgPath := 'levelinfo_icons.png';
    aStyle := GameParams.Level.Info.GraphicSetName;
    aStylePath := AppPath + SFStyles + aStyle + SFIcons;
    aPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

    if FileExists(aStylePath + IconsImgPath) then // Check styles folder first
      TPNGInterface.LoadPngFile(aStylePath + IconsImgPath, IconsImg)
    else if FileExists(GameParams.CurrentLevel.Group.FindFile(IconsImgPath)) then // Then levelpack folder
      TPNGInterface.LoadPngFile(aPath + IconsImgPath, IconsImg)
    else
      TPNGInterface.LoadPngFile(AppPath + SFGraphicsMenu + IconsImgPath, IconsImg); // Then default
  end;

  procedure DrawIcon(dst: TBitmap32; IconIndex: Integer);
  var
    SrcRect, DstRect: TRect;
    PixelColor: TColor32;
    x, y: Integer;
  begin
    SrcRect.Left := (IconIndex mod 6) * 32;
    SrcRect.Top := (IconIndex div 6) * 32;
    SrcRect.Right := SrcRect.Left + 32;
    SrcRect.Bottom := SrcRect.Top + 32;

    DstRect.Left := 0 + Offset.X;
    DstRect.Top := 0 + Offset.Y;
    DstRect.Right := DstRect.Left + 32;
    DstRect.Bottom := DstRect.Top + 32;

    // Recolor bricks for all construction skills
    if (IconIndex in [44, 45, 46, 47, 48])
    // Recolor crumbs for Digger
    or (IconIndex = 54) then
    begin
      BrickColor := GameParams.Renderer.Theme.Colors['MASK'];

      // Prevents colors that don't contrast well with outline
      if (BrickColor and $00C0C0C0) = 0 then
        BrickColor := PANEL_FALLBACK_BRICK_COLOR;

      for y := 0 to 31 do
      begin
        for x := 0 to 31 do
        begin
          PixelColor := IconsImg.Pixel[x + SrcRect.Left, y + SrcRect.Top];

          if (PixelColor = $FFB400B4) or (PixelColor = $FF780078) then
            IconsImg.Pixel[x + SrcRect.Left, y + SrcRect.Top] := BrickColor;
        end;
      end;
    end;

    IconsImg.DrawTo(dst, DstRect, SrcRect);
  end;

begin
  // Load the erasing icon and selection outline first
  GetGraphic('skill_count_erase.png', fSkillCountErase);
  GetGraphic('skill_selected.png', fSkillSelected);
  GetGraphic('skill_types_highlight.png', fSkillTypesHighlight);
  GetGraphic('skill_types_overcount.png', fSkillTypesOvercount);
  GetGraphic('squiggle_highlight.png', fSquiggleHighlight);
  GetGraphic('turbo_highlight.png', fTurboHighlight);

  fSkillCountEraseInvert.Assign(fSkillCountErase);
  for y := 0 to fSkillCountEraseInvert.Height-1 do
    for x := 0 to fSkillCountEraseInvert.Width-1 do
      fSkillCountEraseInvert[x, y] := fSkillCountEraseInvert[x, y] xor $00FFFFFF; // Don't invert alpha

  IconsImg := TBitmap32.Create;
  try
    LoadIcons;

    for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    begin
      fSkillIcons[Button].SetSize(32, 48); // Make the full button available for drawing

      // Set Offset for each button
      Offset := Point(0, 0);

      if GameParams.AmigaTheme then
        FloaterY := 16
      else
        FloaterY := 12;

      case Button of
        spbWalker:    Offset := Point(1, 14);
        spbJumper:    Offset := Point(0, 16);
        spbShimmier:  Offset := Point(0, 16);
        spbBallooner: Offset := Point(0, FloaterY);
        spbSlider:    Offset := Point(-2, 15);
        spbClimber:   Offset := Point(-1, 13);
        spbSwimmer:   Offset := Point(0, 12);
        spbFloater:   Offset := Point(0, FloaterY);
        spbGlider:    Offset := Point(0, FloaterY);
        spbDisarmer:  Offset := Point(-2, 16);
        spbTimebomber:Offset := Point(-1, 12);
        spbBomber:    Offset := Point(-1, 12);
        spbFreezer:   Offset := Point(0, 15);
        spbBlocker:   Offset := Point(1, 14);
        spbLadderer:  Offset := Point(0, 16);
        spbPlatformer:Offset := Point(0, 12);
        spbBuilder:   Offset := Point(0, 12);
        spbStacker:   Offset := Point(0, 16);
        spbSpearer:   Offset := Point(0, 15);
        spbGrenader:  Offset := Point(0, 15);
        spbLaserer:   Offset := Point(0, 14);
        spbBasher:    Offset := Point(0, 14);
        spbFencer:    Offset := Point(-2, 16);
        spbMiner:     Offset := Point(0, 15);
        spbDigger:    Offset := Point(-1, 16);
        //spbPropeller: Offset := Point(0, 14);
        //spbBatter:    Offset := Point(0, 14);
        spbCloner:    Offset := Point(-1, 15);
        else          Offset := Point(0, 0);
      end;

      // Draw icons
      DrawIcon(fSkillIcons[Button], ICON_SKILLS[Button]);
    end;
  finally
    IconsImg.Free;
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
    CountStr := LeadZeroStr(aCount, 3); // Just in case
    fSkillFont[CountStr[1], 1].DrawTo(TempBmp, 0, 0, Rect(0, 0, 8, 16));
    fSkillFont[CountStr[2], 1].DrawTo(TempBmp, 8, 0, Rect(0, 0, 8, 16));
    fSkillFont[CountStr[3], 1].DrawTo(TempBmp, 16, 0, Rect(0, 0, 8, 16));
  end;

begin
  GetGraphic('skill_count_digits.png', fPanelButtons);
  SrcRect := Rect(0, 0, 8, 16);
  for c := '0' to '9' do
  begin
    for i := 0 to 1 do
    begin
      fSkillFont[c, i].SetSize(17, 16);
      fPanelButtons.DrawTo(fSkillFont[c, i], ((4 - 4 * i) * 2) + 1, 0, SrcRect);

      fSkillFontInvert[c, i].Assign(fSkillFont[c, i]);
      for y := 0 to fSkillFontInvert[c, i].Height-1 do
        for x := 0 to fSkillFontInvert[c, i].Width-1 do
          fSkillFontInvert[c, i][x, y] := fSkillFontInvert[c,i][x,y] xor $00FFFFFF; // Don't invert alpha

      fSkillFontTalActive[c, i].Assign(fSkillFont[c, i]);
      for y := 0 to fSkillFontTalActive[c, i].Height - 1 do
        for x := 0 to fSkillFontTalActive[c, i].Width - 1 do
          fSkillFontTalActive[c, i][x, y] :=
            (fSkillFontTalActive[c, i][x, y] and $FF000000) or $0000FF00; // Shift white to green

      fSkillFontTalFailed[c, i].Assign(fSkillFont[c, i]);
      for y := 0 to fSkillFontTalFailed[c, i].Height - 1 do
        for x := 0 to fSkillFontTalFailed[c, i].Width - 1 do
          fSkillFontTalFailed[c, i][x, y] :=
            (fSkillFontTalFailed[c, i][x, y] and $FF000000) or $00FF0000; // Shift white to red
    end;
    OffsetRect(SrcRect, 8, 0);
  end;

  Inc(SrcRect.Right, 8); // Position is correct at this point, but Infinite symbol is 8px wide not 4px
  fSkillInfinite.SetSize(16, 16);
  fPanelButtons.DrawTo(fSkillInfinite, 0, 0, SrcRect);

  OffsetRect(SrcRect, 16, 0); // Additional blue infinity symbol for when Infinite Skills mode is active
  fSkillInfiniteMode.SetSize(16, 16);
  fPanelButtons.DrawTo(fSkillInfiniteMode, 0, 0, SrcRect);

  OffsetRect(SrcRect, 16, 0); // Locked RR/SI icon
  fSkillLock.SetSize(16, 16);
  fPanelButtons.DrawTo(fSkillLock, 0, 0, SrcRect);

  TempBmp := TBitmap32.Create;
  TKernelResampler.Create(TempBmp);
  TKernelResampler(TempBmp.Resampler).Kernel := TCubicKernel.Create;
  try
    TempBMP.SetSize(24, 16);
    for i := 100 to MAXIMUM_SI do
    begin
      MakeOvercountImage(i);
      fSkillOvercount[i].SetSize(18, 16);
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
  CustomAssert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

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
    MinimapRegion.DrawTo(fOriginal, MinimapRect.Left - 6, MinimapRect.Top - 4);
    MinimapRegion.Free;
  end;

  // Copy the created bitmap
  fImage.Bitmap.Assign(fOriginal);

  // Load the remaining graphics for icons, ...
  LoadPanelIcons;
  LoadSkillIcons;
  LoadSkillFont;
end;

procedure TBaseSkillPanel.PlayReleaseRateSound;
//  Minimum Freq = 3300 (we don't want to go lower than this)
//  Original Freq = 7418 (original frequency of SFX_ReleaseRate)
//  Maximum Freq = 24000 (we don't want to go higher than this)
//  Minimum RR = 1 (SI 102)
//  Maximum RR = 99 (SI 4)
var
  RR: Integer;
  MagicFrequencyAmiga: Single;
  //MagicFrequencyCalculatedByWillAndEric: Single;
begin
  // Stops the sound cueing during backwards framesteps and rewind
  if (Game.IsBackstepping or (fGameWindow.GameSpeed = gspRewind))
    // Unless the change is at the current frame
    and not (Game.ReplayManager.HasRRChangeAt(Game.CurrentIteration)) then Exit;

  if Game.SpawnIntervalChanged then
  begin
    RR := (103 - Game.CurrentSpawnInterval);

    // Linear pitch slide
    //MagicFrequencyCalculatedByWillAndEric := 210 * RR + 3300;

    // Logarithmic pitch slide modelled on Amiga
    MagicFrequencyAmiga := 3300 * (Power(1.02, RR));

    SoundManager.PlaySound(SFX_ReleaseRate, 0, MagicFrequencyAmiga);
  end;
end;

procedure TBaseSkillPanel.PrepareForGame;
begin
  // Sets game-dependant properties of the skill panel:
  // Size of the minimap, style, scaling factor, skills on the panel, ...
  fImage.BeginUpdate;
  try
    Minimap.SetSize(Level.Info.Width div 4, Level.Info.Height div 4);

    ReadBitmapFromStyle;
    SetButtonRects;
    SetSkillIcons;

  finally
    fImage.EndUpdate;
  end;
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
  CustomAssert(Assigned(ButtonList), 'SkillPanel: List of Buttons was nil');

  // Set only rectangles for non-skill buttons
  // The skill buttons are dealt with in SetSkillIcons
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
  ViewRectWidth, ViewRectHeight: Integer;
begin
  if not GameParams.ShowMinimap then Exit;

  if Parent = nil then Exit;

  { N.B.

    fMinimap = the miniaturised level
    fMinimapTemp = the bitmap onto which fMinimap is drawn
    fMinimapImage = the complete minimap, including view frame and lem dots }

  { Add 4px on each edge to allow space for the view frame
    when fMinimapTemp meets the very edges of fMinimapImage }
  fMinimapTemp.SetSize(fMinimap.Width + 4, fMinimap.Height + 4);
  fMinimapTemp.Clear(0);

  fMinimap.DrawTo(fMinimapTemp, 2, 2);

  { ============================= View Frame ================================ }

  // Set the view frame to the correct minimap position relative to the level
  BaseOffsetHoriz := fGameWindow.ScreenImage.OffsetHorz / fGameWindow.ScreenImage.Scale / (4 * ResMod);
  BaseOffsetVert := fGameWindow.ScreenImage.OffsetVert / fGameWindow.ScreenImage.Scale / (4 * ResMod);

  // Draw the view frame
  ViewRectWidth := fGameWindow.DisplayWidth div (4 * ResMod) + 2;
  ViewRectHeight := fGameWindow.DisplayHeight div (4 * ResMod) + 2;

  ViewRect := Rect(0, 0, ViewRectWidth, ViewRectHeight);
  OffsetRect(ViewRect, -Round(BaseOffsetHoriz), -Round(BaseOffsetVert));
  fMinimapTemp.FrameRectS(ViewRect, fMinimapViewRectColor);

  // Thicken the view frame by 1px
  InnerViewRect := Rect(ViewRect.Left + 1, ViewRect.Top + 1, ViewRect.Right - 1, ViewRect.Bottom - 1);
  fMinimapTemp.FrameRectS(InnerViewRect, fMinimapViewRectColor);

  { ========================================================================== }

  // Assign the minimap bitmap to fMinimapImage
  fMinimapImage.Bitmap.Assign(fMinimapTemp);

  // Move the bitmap to the correct position within fMinimapImage
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
var
  ButtonPos: Integer;
  MagicFrequency: Single;
begin
  if fGameWindow.IsHyperSpeed then Exit;
  if aButton = spbNone then Exit;

  if (aButton <= LAST_SKILL_BUTTON) then
  begin
    ButtonPos := Game.GetSelectedSkill + 1;

    // Pitch - matches Amiga        // This makes sure the interval is 1 semitone
    MagicFrequency := 6900 * (IntPower(1.0595, ButtonPos));

    if (fLastHighlitSkill <> spbNone) and (fLastHighlitSkill <> fHighlitSkill) then
      SoundManager.PlaySound(SFX_SkillButton, 0, MagicFrequency);

    if (fHighlitSkill = aButton) and Highlight then Exit;
    if (fHighlitSkill = spbNone) and not Highlight then Exit;
  end;
  if fButtonRects[aButton].Left <= 0 then Exit;

  RemoveHighlight(aButton);

  if Highlight then
  begin
    if aButton = spbSquiggle then
      DrawSquiggleHighlight
    else
      DrawHighlight(aButton);
  end;
end;

procedure TBaseSkillPanel.DrawHighlight(aButton: TSkillPanelButton);
var
  BorderRect: TRect;
begin
  if aButton <= LAST_SKILL_BUTTON then
  begin
    BorderRect := fButtonRects[aButton];
    fHighlitSkill := aButton; // No need to memorize this for non-skill buttons
  end else
    BorderRect := fButtonRects[aButton];

  Inc(BorderRect.Right, 4);
  Inc(BorderRect.Bottom, 2);

  fSkillSelected.DrawTo(Image.Bitmap, BorderRect, fSkillSelected.BoundsRect);
end;

procedure TBaseSkillPanel.DrawMaxSkillTypesHighlight(aButton: TSkillPanelButton; Overcount: Boolean);
var
  BorderRect: TRect;
begin
  BorderRect := fButtonRects[aButton];

  Inc(BorderRect.Right, 4);
  Inc(BorderRect.Bottom, 2);

  if Overcount then
    fSkillTypesOvercount.DrawTo(Image.Bitmap, BorderRect, fSkillTypesOvercount.BoundsRect)
  else
    fSkillTypesHighlight.DrawTo(Image.Bitmap, BorderRect, fSkillTypesHighlight.BoundsRect);
end;

procedure TBaseSkillPanel.RemoveMaxSkillTypesHighlights;
var
  Button: TSkillPanelButton;
  BorderRect: TRect;
begin
  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    BorderRect := fButtonRects[Button];

    Inc(BorderRect.Right, 4);
    Inc(BorderRect.Bottom, 2);

    fOriginal.DrawTo(Image.Bitmap, BorderRect, BorderRect);
  end;

  if fHighlitSkill <> spbNone then
    DrawHighlight(fHighlitSkill);
end;

procedure TBaseSkillPanel.DrawTurboHighlight;
var
  BorderRect: TRect;
begin
  BorderRect := fButtonRects[spbFastForward];

  Inc(BorderRect.Right, 4);
  Inc(BorderRect.Bottom, 2);

  if (fGameWindow.GameSpeed = gspTurbo) then
    fTurboHighlight.DrawTo(Image.Bitmap, BorderRect, fTurboHighlight.BoundsRect)
  else if not (fGameWindow.GameSpeed in [gspFF, gspTurbo]) then
    RemoveHighlight(spbFastForward);
end;

procedure TBaseSkillPanel.DrawSquiggleHighlight;
var
  BorderRect: TRect;
begin
  BorderRect := fButtonRects[spbSquiggle];

  if GameParams.AmigaTheme then
  begin
    Inc(BorderRect.Right, 184);
    Inc(BorderRect.Bottom, 4);
  end else begin
    Inc(BorderRect.Right, 3);
    Inc(BorderRect.Bottom, 1);
  end;

  fSquiggleHighlight.DrawTo(Image.Bitmap, BorderRect, fSquiggleHighlight.BoundsRect);
end;

procedure TBaseSkillPanel.RemoveButtonHighlights;
begin
  RemoveHighlight(spbSlower);
  RemoveHighlight(spbFaster);
  RemoveHighlight(spbRestart);
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

  if GameParams.AmigaTheme and (aButton = spbSquiggle) then
    Inc(BorderRect.Right, 184)
  else
    Inc(BorderRect.Right, 4);

  Inc(BorderRect.Bottom, 4);

  fOriginal.DrawTo(Image.Bitmap, BorderRect, BorderRect);
  Exit;

  // Top
  EraseRect := BorderRect;
  EraseRect.Bottom := EraseRect.Top + 2;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // Left
  EraseRect := BorderRect;
  EraseRect.Right := EraseRect.Left + 2;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // Right
  EraseRect := BorderRect;
  EraseRect.Left := EraseRect.Right - 2;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);

  // Bottom
  EraseRect := BorderRect;
  EraseRect.Top := EraseRect.Bottom - 2;
  fOriginal.DrawTo(Image.Bitmap, EraseRect, EraseRect);
end;

procedure TBaseSkillPanel.DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer; CursorOverInvincible: Boolean = False);
var
  ButtonLeft, ButtonTop: Integer;
  NumberStr: string;

  EraseBMP: TBitmap32;
  FontBMP: TFontBitmapArray;

  IsRegularSkill: Boolean;

  // Talisman requirements
  TalismanHasSkillRequirement: Boolean;
  TalismanStatus: TTalismanStatus;
  OrigNumber, UsedOfSkill: Integer;
  SkillMax, SkillMin, TotalLimit: Integer;
begin
  if fButtonRects[aButton].Left < 0 then Exit;
  if fGameWindow.IsHyperSpeed then Exit;

  IsRegularSkill := aButton <= LAST_SKILL_BUTTON;

  TalismanHasSkillRequirement := False;
  TalismanStatus := tsSucceeding;

  // Handle talisman requirement info
  if fCurrentTalisman >= 0 then
  begin
    OrigNumber := aNumber;
    UsedOfSkill := Game.SkillsUsed[aButton];

    SkillMax := Level.Talismans[fCurrentTalisman].SkillMaximum[aButton];
    SkillMin := Level.Talismans[fCurrentTalisman].SkillMinimum[aButton];
    TotalLimit := Level.Talismans[fCurrentTalisman].TotalSkillLimit;

    TalismanHasSkillRequirement := (SkillMax >= 0) or (SkillMin > 0) or (TotalLimit >= 0);

    if TalismanHasSkillRequirement then
    begin
      if SkillMax >= 0 then
      begin
        if UsedOfSkill > SkillMax then
          TalismanStatus := tsFailed
        else
          aNumber := SkillMax - UsedOfSkill;
      end;

      if (SkillMin > 0) and (UsedOfSkill < SkillMin) then
      begin
        { TODO - Unsure what's the best way of displaying a Minimum limit...
          We could display the (minimum - used) or just the (used) in red,
          but that could be misleading. Just displaying the (available) in
          red doesn't give enough info though }

        //aNumber := SkillMin - UsedOfSkill;
        //TalismanStatus := tsFailing; // TODO - Use this to display (Min - Used) in red

        TalismanStatus := tsFailed; // NOTE: This will just show the (available) in red...
      end;

      if TotalLimit >= 0 then
      begin
        if UsedOfSkill > TotalLimit then
          TalismanStatus := tsFailed
        else
          aNumber := TotalLimit - UsedOfSkill;
      end;

      if aNumber < 0 then
        TalismanStatus := tsFailed;
    end;

    if fShowUsedSkills then
      aNumber := UsedOfSkill
    else if TalismanStatus = tsFailed then //...because the number gets reset here
      aNumber := OrigNumber;

    if TalismanStatus <> tsSucceeding then
      FontBMP := fSkillFontTalFailed
    else if TalismanHasSkillRequirement then
      FontBMP := fSkillFontTalActive
    else if IsRegularSkill and fShowUsedSkills then
      FontBMP := fSkillFontInvert
    else
      FontBMP := fSkillFont;

    if fShowUsedSkills then
      EraseBMP := fSkillCountEraseInvert
    else
      EraseBMP := fSkillCountErase;
  end else if IsRegularSkill and fShowUsedSkills then
  begin
    if aNumber > 99 then
      aNumber := 99;

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

  if IsRegularSkill and (aNumber = 0) and not fShowUsedSkills then
    Exit;

  if (aButton = spbFaster) and (Level.Info.SpawnIntervalLocked or (Level.Info.SpawnInterval = MINIMUM_SI)) then
    fSkillLock.DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2)
  else if (aNumber > 99) then
  begin
    if (aButton <= LAST_SKILL_BUTTON) then
    begin
      if CursorOverInvincible or Game.IsInfiniteSkillsMode then
        fSkillInfiniteMode.DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2)
      else
        fSkillInfinite.DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2)
    end else
      fSkillOvercount[aNumber].DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2);
  end else if (aNumber < 10) and not GameParams.AmigaTheme then
  begin
    NumberStr := LeadZeroStr(aNumber, 2);
    FontBMP[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 2, ButtonTop + 2);
  end else begin
    NumberStr := LeadZeroStr(aNumber, 2);
    FontBMP[NumberStr[1], 1].DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2);
    FontBMP[NumberStr[2], 0].DrawTo(fImage.Bitmap, ButtonLeft + 6, ButtonTop + 2);
  end;
end;

{-----------------------------------------
    Info string at top
-----------------------------------------}
procedure TBaseSkillPanel.DrawCursorInfo;
var
  Color: TColor32;
begin
  if not (CursorOverPanelItem or (Game.RenderInterface.SelectedLemming <> nil)) then
    Exit;

  if CursorOverPanelItem then
    Color := clCornflowerBlue32
  else if Game.SelectedLemFutureTaskCount > 0 then
    Color := clTeal32
  else
    Color := clLightGreen32;

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;
    RenderText(4, 6, GetCursorInfoString, Color, True);
  end;
end;

procedure TBaseSkillPanel.DrawPanelIcon(Index, X, Y: Integer);
begin
  fPanelIcons.DrawTo(fImage.Bitmap, X, Y, Rect(Index * 24, 0, (Index + 1) * 24, 32));
end;

procedure TBaseSkillPanel.DrawReplayIcon;
var
  Icon: Integer;
  TickCount: Cardinal;
  BlinkIcon, IsReplaying, IsClassicModeRewind: Boolean;
begin
  Icon := -2;
  TickCount := GetTickCount;
  BlinkIcon := ((TickCount div 500) mod 2) = 0;

  IsReplaying := Game.ReplayingNoRR[fGameWindow.GameSpeed = gspPause];
  IsClassicModeRewind := (GameParams.ClassicMode and (fGameWindow.GameSpeed = gspRewind));

  if BlinkIcon or Game.StateIsUnplayable or (not GameParams.PlaybackModeActive and not IsReplaying) then
    Icon := -1
  else if GameParams.PlaybackModeActive and not IsReplaying then
    Icon := 11 // Purple "R"
  else if Game.ReplayInsert and not IsClassicModeRewind then
    Icon := 10  // Blue "R"
  else if not (RRIsPressed or IsClassicModeRewind) then
    Icon := 9; // Red "R"

  DrawPanelIcon(Icon, ReplayIconRect.Left - 4, ReplayIconRect.Top);
end;

procedure TBaseSkillPanel.DrawCollectibleIcon;
var
  Icon: Integer;
begin
  if not LevelHasCollectibles then
    Exit;

  if (Game.CollectiblesRemaining > 0) then
    Icon := 0
  else
    Icon := 1;

  DrawPanelIcon(Icon, CollectibleIconRect.Left, CollectibleIconRect.Top);

//  with fImage.Bitmap do
//  begin
//    Font.Name := 'Hobo Std';
//    Font.Size := 8;
//    RenderText(CollectibleIconRect.Left + 28, 6, GetCollectibleString, clLightGreen32, True);
//  end;
end;

procedure TBaseSkillPanel.DrawTalismanIcon(Index: Integer);
begin
  if not LevelHasTalismans then
    Exit;

  DrawPanelIcon(Index, TalismanIconRect.Left, TalismanIconRect.Top);
end;

procedure TBaseSkillPanel.DrawHatchInfo;
begin
  DrawPanelIcon(2, HatchIconRect.Left, HatchIconRect.Top);

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;
    RenderText(HatchIconRect.Left + 32, 6, GetHatchCountString, clLightGreen32, True);
  end;
end;

procedure TBaseSkillPanel.DrawLemsAliveInfo;
var
  Color: TColor32;
  LemmingKinds: TLemmingKinds;

  function NotEnoughLemmings: Boolean;
  var
    LemsAlive, LemsToSave: Integer;
  begin
    LemsAlive := Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead;

    if (fCurrentTalisman >= 0) and fTalHasSaveRequirement then
      LemsToSave := fTalSaveRequirement - Game.LemmingsSaved
    else
      LemsToSave := Level.Info.RescueCount - Game.LemmingsSaved;

    Result := LemsAlive < LemsToSave;
  end;
begin
  DrawPanelIcon(3, AliveIconRect.Left, AliveIconRect.Top);
  LemmingKinds := Game.ActiveLemmingTypes;

  if NotEnoughLemmings then
    Color := clRed32
  else if (lkNeutral in LemmingKinds) and not (lkNormal in LemmingKinds) then
    Color := clTeal32
  else
    Color := clLightGreen32;

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;
    RenderText(AliveIconRect.Left + 32, 6, GetLemsAliveString, Color, True);
  end;
end;

procedure TBaseSkillPanel.DrawLemsSavedInfo;
var
  Color: TColor32;
  Icon: Integer;
begin
  if (Game.LemmingsSaved >= Level.Info.RescueCount) then
  begin
    Color := clAquamarine32;
    Icon := 5;
  end else begin
    Color := clLightGreen32;
    Icon := 4;
  end;

  if (fCurrentTalisman >= 0) and (fTalHasSaveRequirement) then
  begin
    if (Game.LemmingsSaved >= fTalSaveRequirement) then
    begin
      Color := clAquamarine32;
      Icon := 5;
    end else begin
      Color := clCornflowerBlue32;
      Icon := 4;
    end;
  end;

  DrawPanelIcon(Icon, ExitIconRect.Left, ExitIconRect.Top);

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;
    RenderText(ExitIconRect.Left + 32, 6, GetLemsSavedString, Color, True);
  end;
end;

procedure TBaseSkillPanel.DrawTimeInfo;
var
  Icon: Integer;
  Color: TColor32;
begin
  Icon := 6;
  Color := clLightGreen32;

  if Level.Info.HasTimeLimit then
  begin
    Color := clYellow32;
    Icon := 7;

    if Game.IsOutOfTime then
    begin
      Color := clRed32;
      Icon := 8;
    end;
  end;

  if (fCurrentTalisman >= 0) and (fTalTimeLimit > 0) then
  begin
    Color := clYellow32;
    Icon := 7;

    if Game.IsOutOfTime or (Game.CurrentIteration > fTalTimeLimit) then
    begin
      Color := clRed32;
      Icon := 8;
    end;
  end;

  DrawPanelIcon(Icon, TimeIconRect.Left, TimeIconRect.Top);

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;
    RenderText(TimeIconRect.Left + 28, 6, GetTimeString, Color, True);
  end;
end;

procedure TBaseSkillPanel.DrawMaxSkillTypes;
var
  Button: TSkillPanelButton;
  SkillTypesStr: String;
  Overcount: Boolean;
  CountRect, CountRectErase: TRect;
begin
  if (fCurrentTalisman < 0) or not fTalHasMaxSkillTypes then
    Exit;

  if fSkillTypesUsed > 0 then
    RemoveMaxSkillTypesHighlights;

  CountRect := Rect(TalismanIconRect.Right + 2, 6, TalismanIconRect.Right + 26, 28);
  CountRectErase := Rect(CountRect.Left + 2, CountRect.Top + 2, CountRect.Right - 2, CountRect.Bottom - 2);

  fSkillTypesUsed := 0;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if Game.SkillsUsed[Button] > 0 then
      Inc(fSkillTypesUsed);

  SkillTypesStr := IntToStr(Max(0, fTalMaxSkillTypes - fSkillTypesUsed));
  Overcount := fSkillTypesUsed > fTalMaxSkillTypes;

  with fImage.Bitmap do
  begin
    if Overcount then
      FillRectS(CountRect, $FFFF0055)
    else
      FillRectS(CountRect, $FFB200FF);

    FillRectS(CountRectErase, $FF000000);

    if Overcount then
      fSkillFontTalFailed[SkillTypesStr[1], 1].DrawTo(
        fImage.Bitmap, CountRect.Left + 6, CountRect.Top + 5)
    else if Length(SkillTypesStr) = 1 then
      fSkillFont[SkillTypesStr[1], 1].DrawTo(
        fImage.Bitmap, CountRect.Left + 6, CountRect.Top + 5)
    else begin
      fSkillFont[SkillTypesStr[1], 1].DrawTo(
        fImage.Bitmap, CountRect.Left + 3, CountRect.Top + 5);

      fSkillFont[SkillTypesStr[2], 0].DrawTo(
        fImage.Bitmap, CountRect.Left + 3, CountRect.Top + 5);
    end;
  end;

  for Button := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if Game.SkillsUsed[Button] > 0 then
      DrawMaxSkillTypesHighlight(Button, Overcount);
end;

procedure TBaseSkillPanel.DrawPanelMessage;
begin
  if not Game.StateIsUnplayable then
    Exit;

  if Game.ShouldExitToPostview then
    Exit;

  ClearInfo;

  with fImage.Bitmap do
  begin
    Font.Name := 'Hobo Std';
    Font.Size := 8;

    RenderText(4,   6, 'No lemmings remaining!', clLightGreen32, True);
    RenderText(200, 6, 'Rewind or Restart to continue...', clCornflowerBlue32, True);
  end;
end;

procedure TBaseSkillPanel.ClearInfo;
var
  PanelInfoEnd: Integer;
begin
  PanelInfoEnd := TimeIconRect.Right;
  fImage.Bitmap.FillRectS(0, 0, PanelInfoEnd, 32, $00000000);
end;

procedure TBaseSkillPanel.RefreshInfo;
var
  i : TSkillPanelButton;
  L: TLemming;
begin
  L := Game.RenderInterface.SelectedLemming;

  Image.BeginUpdate;
  try
    for i := Low(fButtonRects) to High(fButtonRects) do
      GetButtonHints(i);

    // Text info string
    ClearInfo;
    DrawCursorInfo;
    DrawReplayIcon;
    DrawCollectibleIcon;
    DrawTalismanIcon(fTalismanIconIndex);
    DrawHatchInfo;
    DrawLemsAliveInfo;
    DrawLemsSavedInfo;
    DrawTimeInfo;
    DrawMaxSkillTypes;
    DrawPanelMessage;

    DrawSkillCount(spbSlower, GetSpawnIntervalValue(Level.Info.SpawnInterval));
    DrawSkillCount(spbFaster, GetSpawnIntervalValue(Game.CurrentSpawnInterval));
    PlayReleaseRateSound;

    // Highlight selected button
    if fHighlitSkill <> Game.RenderInterface.SelectedSkill then
    begin
      DrawButtonSelector(fHighlitSkill, False);
      DrawButtonSelector(Game.RenderInterface.SelectedSkill, True);
    end;

    // Skill numbers
    if Self.fShowUsedSkills then
    begin
      for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        DrawSkillCount(i, Game.SkillsUsed[i]);
    end else begin
      for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      begin
        if (L <> nil) and L.LemIsInvincible then
          DrawSkillCount(i, 100, True)
        else
          DrawSkillCount(i, Game.SkillCount[i]);
      end;
    end;

    DrawButtonSelector(spbNuke, (Game.NukeIsActive or (Game.ReplayManager.Assignment[Game.CurrentIteration, 0] is TReplayNuke)));
  finally
    Image.EndUpdate;
  end;
end;

function TBaseSkillPanel.GetPickupString(P: TGadget): String;
begin
  Result := IntToStr(P.SkillCount) + ' ' + Uppercase(SKILL_NAMES[P.SkillType] + IfThen(P.SkillCount > 1, 'S', ''));
end;

function TBaseSkillPanel.GetLemReplayTaskString(L: TLemming): String;
var
  Tasks: Integer;
begin
  Tasks := Game.SelectedLemFutureTaskCount;
  Result := 'CUT ' + IntToStr(Tasks) + ' TASK' + IfThen(Tasks > 1, 'S', ' ');
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

  if (L = nil) then Exit;

  if L.LemAction in [baTimebombing, baOhnoing] then
    Result := SExploder
  else
    Result := LemmingActionStrings[L.LemAction];

  if L.HasPermanentSkills and GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo) then
  begin
    Result := '-----------';
    if L.LemIsSlider then Result[2] := 'L';
    if L.LemIsClimber then Result[3] := 'C';
    if L.LemIsSwimmer then Result[4] := 'S';
    if L.LemIsFloater then Result[5] := 'F';
    if L.LemIsGlider then Result[6] := 'G';
    if L.LemIsDisarmer then Result[7] := 'D';
    if L.LemIsZombie then Result[8] := 'Z';
    if L.LemIsNeutral then Result[9] := 'N';
    if L.LemIsRival then Result[10] := 'R';
    if L.LemIsInvincible then Result[11] := 'I';
  end
  else if (L.LemAction in [baWalking, baAscending, baFalling]) then
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
    if L.LemIsTimebomber then Result := STimebomber;
    if L.LemIsRadiating then Result := SRadiator;
    if (L.LemFreezerExplosionTimer > 0) then Result := SSlowfreezer;
    if L.LemIsRival then Result := SRival;
    if L.LemIsInvincible then Result := SInvincible;
    if L.LemIsZombie and L.LemIsNeutral then Result := SNeutralZombie;
  end else
    if L.LemIsZombie and not L.LemIsNeutral then
      Result := 'Z-' + Result
    else if L.LemIsNeutral and not L.LemIsZombie then
      Result := 'N-' + Result
    else if L.LemIsZombie and L.LemIsNeutral then
      Result := 'ZN-' + Result
    else if L.LemIsRival then
      Result := 'R-' + Result;
end;

function TBaseSkillPanel.GetCursorInfoString: String;
var
  S: String;
  SelectedLemming: TLemming;
  PickupInCursor: TGadget;
const
  LEN = 14;
begin
  if (Game.StateIsUnplayable and not Game.ShouldExitToPostview) then
    Exit;

  SelectedLemming := Game.RenderInterface.SelectedLemming;
  PickupInCursor := Game.RenderInterface.PickupInCursor;

  S := '';

  if ((PickupInCursor <> nil) and (SelectedLemming = nil)) then
    S := Uppercase(GetPickupString(PickupInCursor))
  else if CursorOverPanelItem and GameParams.ShowButtonHints then
    S := ButtonHint + StringOfChar(' ', 13 - Length(ButtonHint))
  else begin
    if (Game.SelectedLemFutureTaskCount > 0) then
      S := Uppercase(GetLemReplayTaskString(SelectedLemming))
    else begin
      S := Uppercase(GetSkillString(SelectedLemming));
      if S = '' then
        S := StringOfChar(' ', LEN)
      else if (Game.GetCursorLemmingCount = 0) then
        S := PadR(S, LEN)
      else
        S := PadR(S + ' ' + IntToStr(Game.GetCursorLemmingCount), LEN);
    end;
  end;

  Result := S;
end;

function TBaseSkillPanel.GetCollectibleString: String;
var
  C: Integer;
begin
  C := Level.Info.CollectibleCount - Game.CollectiblesRemaining;

  if C >= 999 then
    Result := ' 999'
  else
    Result := IntToStr(C);
end;

function TBaseSkillPanel.GetHatchCountString: String;
var
  HatchLems: Integer;
begin
  HatchLems := Game.LemmingsToSpawn - Game.SpawnedDead;

  CustomAssert(HatchLems >= 0, 'Negative number of lemmings in hatch displayed');

  if HatchLems >= 999 then
    Result := ' 999'
  else
    Result := IntToStr(HatchLems);
end;

function TBaseSkillPanel.GetLemsAliveString: String;
var
  LemNum: Integer;
begin
  LemNum := Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead;

  if not (Game.IsOutOfTime or Game.NukeIsActive) then
    CustomAssert(LemNum >= 0, 'Negative number of alive lemmings displayed');

  if (LemNum >= 999) then
    Result := ' 999'
  else
    Result := IntToStr(LemNum);
end;

function TBaseSkillPanel.GetLemsSavedString: String;
var
  ToSave, Required, TotalSaved: Integer;
begin
  TotalSaved := Game.LemmingsSaved;
  Required := Level.Info.RescueCount;

  if (fCurrentTalisman >= 0) and fTalHasSaveRequirement then
    Required := fTalSaveRequirement;

  ToSave := Required - TotalSaved;

  if (ToSave < 0) then
    Result := IntToStr(TotalSaved)
  else
    Result := IntToStr(ToSave);

  if (TotalSaved <= -99) or (ToSave <= -99) then // Should never happen
    Result := ' -99'
  else if (TotalSaved >= 999) or (Required >= 999) or (ToSave >= 999) then
    Result := ' 999';
end;

function TBaseSkillPanel.GetTimeString: String;
var
  Time: Integer;
  Prefix, Minutes, Seconds: String;
begin
  if (Level.Info.HasTimeLimit and not Game.IsInfiniteTimeMode) then
  begin
    if Game.IsSuperLemmingMode then
      Time := Level.Info.TimeLimit - Game.CurrentIteration div 50
    else
      Time := Level.Info.TimeLimit - Game.CurrentIteration div 17;
    if Time < 0 then
      Time := 0 - Time;
  end else
    if Game.IsSuperLemmingMode then
      Time := Game.CurrentIteration div 50
    else
      Time := Game.CurrentIteration div 17;

  if (fCurrentTalisman >= 0) and fTalHasTimeLimit and (Game.CurrentIteration < fTalTimeLimit) then
  begin
    Time := fTalTimeLimit - Game.CurrentIteration;

    if Game.IsSuperLemmingMode then
      Time := Time div 50
    else
      Time := Time div 17;
  end;

  if Game.IsOutOfTime and (Time <> 0) then
    Prefix := '-'
  else
    Prefix := ' ';

  if Time div 60 >= 100 then
  begin
    Minutes := '99';
    Seconds := '59';
  end else begin
    Minutes := PadL(IntToStr(Time div 60), 2);
    Seconds := LeadZeroStr(Time mod 60, 2);
  end;

  Result := Prefix + Minutes + ':' + Seconds;
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

  if CursorOverIcon(ReplayIconRect) then
  begin
    // Stop playback if the "P" icon is clicked (replay must have finished or been cancelled, so this needs to be called first)
    if GameParams.PlaybackModeActive and (Game.CurrentIteration > Game.ReplayManager.LastActionFrame) then
      GameParams.PlaybackModeActive := False;

    // Cancel replay if the "R" icon is clicked
    Game.RegainControl(True);
  end;

  if CursorOverIcon(TalismanIconRect) then
    HandleTalismanIconClick;

  { Although we don't want to attempt game control whilst in HyperSpeed,
    we do want the Rewind, FF and Turbo keys to respond }
  if fGameWindow.IsHyperSpeed and not (fGameWindow.GameSpeed in [gspRewind, gspFF, gspTurbo]) then Exit;

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
        Game.IsBackstepping := False; // Ensures RR sound will be cued
        RRIsPressed := True; // Prevents replay icon being drawn when using RR buttons
        DrawButtonSelector(spbSlower, True);

        // Deactivates min/max RR jumping in ClassicMode
        if GameParams.ClassicMode then
          begin
            Game.SetSelectedSkill(i, True);
          end else
        Game.SetSelectedSkill(i, True, (Button = mbRight));
      end;
    spbFaster:
      begin
        Game.IsBackstepping := False; // Ensures RR sound will be cued
        RRIsPressed := True; // Prevents replay icon being drawn when using RR buttons
        DrawButtonSelector(spbFaster, True);

        // Deactivates min/max RR jumping in ClassicMode
        if GameParams.ClassicMode then
          begin
            Game.SetSelectedSkill(i, True);
          end else
        Game.SetSelectedSkill(i, True, (Button = mbRight));
      end;
    spbPause:
      begin
        // 55 frames' grace at the start of the level (before music starts) for the NoPause talisman
        if (Game.CurrentIteration > 55) then Game.PauseWasPressed := True;

        // Cancel replay if pausing directly from Rewind in Classic Mode
        if GameParams.ClassicMode and (fGameWindow.GameSpeed = gspRewind) then
          Game.RegainControl(True);

        if (fGameWindow.GameSpeed = gspPause) then
        begin
          Game.IsBackstepping := False;
          fGameWindow.GameSpeed := gspNormal;
        end else begin
          Game.IsBackstepping := True;
          fGameWindow.GameSpeed := gspPause;
        end;
      end;
    spbNuke:
      begin
        Game.RegainControl;
        if GameParams.Hotkeys.CheckForKey(lka_Highlight) or (Button = mbRight) then
        begin
          Game.SetSelectedSkill(i, True, True);
          fGameWindow.GotoSaveState(Game.CurrentIteration, 0, Game.CurrentIteration - 85);
        end else
          Game.SetSelectedSkill(i, True);
      end;
    spbFastForward:
      begin
        if Game.IsSuperLemmingMode then Exit;

        Game.IsBackstepping := False;

        if GameParams.TurboFF then
        begin
          if (fGameWindow.GameSpeed = gspTurbo) then
            fGameWindow.GameSpeed := gspNormal
          else
            fGameWindow.GameSpeed := gspTurbo;
        end else begin
          if (fGameWindow.GameSpeed = gspFF) then
            fGameWindow.GameSpeed := gspNormal
          else
            fGameWindow.GameSpeed := gspFF;
        end;
      end;
    spbRewind:
      begin
        if Game.IsSuperLemmingMode then Exit;

        // Cancel replay only when stopping Rewind in Classic Mode
        if (fGameWindow.GameSpeed = gspRewind) and GameParams.ClassicMode then
          Game.RegainControl(True);

        // Pressing Rewind fails the NoPause talisman  (1 second grace at start of level)
        if (Game.CurrentIteration > 17) then Game.PauseWasPressed := True;

        if fGameWindow.GameSpeed <> gspRewind then
          fGameWindow.GameSpeed := gspRewind
        else
          fGameWindow.GameSpeed := gspNormal;
      end;
    spbRestart:
      begin
        DrawButtonSelector(spbRestart, True);
        fGameWindow.GotoSaveState(0);
        Game.Restarted := True;

        // Always reset these if user restarts
        Game.PauseWasPressed := False;
        Game.ReplayLoaded := False;

        // Cancel replay if in Classic Mode or if Replay After Restart is deactivated
        if GameParams.ClassicMode or not GameParams.ReplayAfterRestart then
          Game.RegainControl(True);
      end;
    spbSquiggle:
      begin
        if not GameParams.ClassicMode then
        fGameWindow.PhysicsViewActive := not fGameWindow.PhysicsViewActive;
      end;
    spbNone: {nothing};
  else // Usual skill buttons
    Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
  end;
end;

procedure TBaseSkillPanel.ImgMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := True;
  Game.HitTest;
  fGameWindow.SetCurrentCursor;

  MinimapScrollFreeze := False;
end;

procedure TBaseSkillPanel.ImgMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  Game.SetSelectedSkill(spbSlower, False);
  Game.SetSelectedSkill(spbFaster, False);
  RemoveButtonHighlights;
  RRIsPressed := False;
end;

procedure TBaseSkillPanel.MinimapMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if GameParams.EdgeScroll then fGameWindow.ApplyMouseTrap;
  fMinimapScrollFreeze := True;

  if Assigned(fOnMinimapClick) then
    fOnMinimapClick(Self, MousePosMinimap(X, Y));
end;

procedure TBaseSkillPanel.MinimapMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  Pos: TPoint;
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := True;
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
  fMinimapScrollFreeze := False;
  DrawMinimap;
end;

procedure TBaseSkillPanel.GetButtonHints(aButton: TSkillPanelButton);
begin
  ButtonHint := '';

  if CursorOverMinimap then
                   ButtonHint := 'MINIMAP'
  else if CursorOverIcon(CollectibleIconRect) and LevelHasCollectibles then
                   ButtonHint := 'COLLECTIBLES'
  else if CursorOverIcon(TalismanIconRect) and LevelHasTalismans then
  begin
    if fCurrentTalisman = -1 then
                   ButtonHint := 'TALISMANS'
    else
                   ButtonHint := 'TALISMAN ' + IntToStr(fCurrentTalisman + 1) + ' of ' + IntToStr(Level.Talismans.Count)
  end else if CursorOverIcon(HatchIconRect) then
                   ButtonHint := 'TO SPAWN'
  else if CursorOverIcon(AliveIconRect) then
                   ButtonHint := 'AVAILABLE'
  else if CursorOverIcon(TimeIconRect)then
                   ButtonHint := 'TIMER'
  else if CursorOverIcon(ExitIconRect) then
  begin
    if Game.LemmingsSaved <= Level.Info.RescueCount then
                   ButtonHint := 'TO SAVE'
    else
                   ButtonHint := 'SAVED';
  end else if CursorOverIcon(ReplayIconRect) then
  begin
    if Game.ReplayingNoRR[fGameWindow.GameSpeed = gspPause] then
                   ButtonHint := 'CANCEL REPLAY'
    else if GameParams.PlaybackModeActive then
                   ButtonHint := 'STOP PLAYBACK'
    else
                   ButtonHint := '';
  end else if CursorOverSkillButton(aButton) then
  begin
    case aButton of
      spbNone:     ButtonHint := '';
      spbSlower:   ButtonHint := 'SLOWER';
      spbFaster:   ButtonHint := 'FASTER';
      spbPause:    ButtonHint := 'PAUSE';
      spbRewind:   ButtonHint := 'REWIND';
      spbFastForward:
        if GameParams.TurboFF then
                   ButtonHint := 'TURBO-FF'
        else
                   ButtonHint := 'FAST-FORWARD';
      spbRestart:  ButtonHint := 'RESTART';
      spbNuke:     ButtonHint := 'NUKE';
      spbSquiggle: ButtonHint := '';
      else         ButtonHint := Uppercase(SKILL_NAMES[aButton]);
    end;
  end;
end;

function TBaseSkillPanel.CursorOverIcon(aIconRect: TRect): Boolean;
var
  CursorPos: TPoint;
  P: TPoint;
begin
  Result := False;
  CursorPos := Mouse.CursorPos;
  P := Image.ControlToBitmap(Image.ScreenToClient(CursorPos));

  if PtInRect(aIconRect, P) then
  begin
    Result := True;
    Exit;
  end;
end;

function TBaseSkillPanel.CursorOverSkillButton(out Button: TSkillPanelButton): Boolean;
var
  CursorPos: TPoint;
  P: TPoint;
  i: TSkillPanelButton;
begin
  Result := False;
  Button := spbNone; // Initialize Button to a default value

  CursorPos := Mouse.CursorPos;
  P := Image.ControlToBitmap(Image.ScreenToClient(CursorPos));

  for i := Low(fButtonRects) to High(fButtonRects) do
  begin
    if PtInRect(fButtonRects[i], P) then
    begin
      Result := True;
      Button := TSkillPanelButton(i); // Assign the button value
      Exit;
    end;
  end;

  // If no button found, set Button to spbNone
  Button := spbNone;
end;

function TBaseSkillPanel.CursorOverMinimap: Boolean;
var
  CursorPos: TPoint;
  P: TPoint;
begin
  Result := False;
  CursorPos := Mouse.CursorPos;
  P := Image.ControlToBitmap(Image.ScreenToClient(CursorPos));

  if PtInRect(MinimapRect, P) then
  begin
    Result := True;
    Exit;
  end;
end;

function TBaseSkillPanel.CursorOverClickableItem: Boolean;
var
  aButton: TSkillPanelButton;
begin
  Result := False or CursorOverSkillButton(aButton)
                  or CursorOverIcon(ReplayIconRect)
                  or CursorOverMinimap;
end;

function TBaseSkillPanel.CursorOverPanelItem: Boolean;
var
  aButton: TSkillPanelButton;
begin
  Result := False or CursorOverSkillButton(aButton)
                  or CursorOverIcon(ReplayIconRect)
                  or CursorOverIcon(CollectibleIconRect)
                  or CursorOverIcon(TalismanIconRect)
                  or CursorOverIcon(HatchIconRect)
                  or CursorOverIcon(AliveIconRect)
                  or CursorOverIcon(ExitIconRect)
                  or CursorOverIcon(TimeIconRect)
                  or CursorOverMinimap;
end;

procedure TBaseSkillPanel.HandleTalismanIconClick;
var
  Button: TSkillPanelButton;

  procedure DisplayTalismanInfo(Tal: Integer);
  var
    Index: Integer;
  begin
    if Tal < 0 then
      Index := 12
    else begin
      case Level.Talismans[Tal].Color of
        tcBronze: Index := 13;
        tcSilver: Index := 14;
        tcGold:   Index := 15;
      end;

      // TODO - if Talisman is completed, add 3 to index

      fTalSaveRequirement := Level.Talismans[Tal].RescueCount;
      fTalHasSaveRequirement := fTalSaveRequirement > 0;

      fTalTimeLimit := Level.Talismans[Tal].TimeLimit;
      fTalHasTimeLimit := fTalTimeLimit > 0;

      fTalMaxSkillTypes := Level.Talismans[Tal].SkillTypeLimit;
      fTalHasMaxSkillTypes := fTalMaxSkillTypes > 0;

      // TODO - fTalHasNoPause
      // TODO - fTalHasClassicMode
      // TODO - fTalHasKillZombies
    end;

    fTalismanIconIndex := Index;
    DrawTalismanIcon(fTalismanIconIndex);
  end;
begin
  if not LevelHasTalismans then
    Exit;

  if fCurrentTalisman < Level.Talismans.Count - 1 then
    Inc(fCurrentTalisman)
  else
    fCurrentTalisman := -1;

  RemoveMaxSkillTypesHighlights;

  with fImage.Bitmap do
  begin
    FillRectS(TimeIconRect.Right, 4, TimeIconRect.Right + 24, 24, $FF000000);
  end;

  DisplayTalismanInfo(fCurrentTalisman);
end;

{-----------------------------------------
    General stuff
-----------------------------------------}
function TBaseSkillPanel.GetLevel: TLevel;
begin
  Result := GameParams.Level;
end;

procedure TBaseSkillPanel.ResizePanelWithWindow;
begin
  // Resize and reposition the panel relative to the width of the window
  fImage.Width := GameParams.MainForm.ClientWidth;
  fImage.Left := (GameParams.MainForm.ClientWidth - fImage.Width) div 2;

  // Calculate the resize percentage based on the panel width
  ResizePercentage := fImage.Width / PanelWidth;

  // Calculate the new panel height
  fImage.Height := Round(PanelHeight * ResizePercentage);

  // Store the new panel width and height
  ResizedPanelWidth := fImage.Width;
  ResizedPanelHeight := fImage.Height;

  // Calculate Minimap position and size relative to the resized panel
  ResizedMinimapLeft := Round(MinimapRect.Left * ResizePercentage);
  ResizedMinimapTop := Round(MinimapRect.Top * ResizePercentage);
  ResizedMinimapWidth := Round(MinimapWidth * ResizePercentage);
  ResizedMinimapHeight := Round(MinimapHeight * ResizePercentage);

  // Resize the minimap
  fMinimapImage.Width := ResizedMinimapWidth;
  fMinimapImage.Height := ResizedMinimapHeight;
  fMinimapImage.Left := ResizedMinimapLeft;
  fMinimapImage.Top := ResizedMinimapTop;
  fMinimapImage.Scale := ResizePercentage;
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

function TBaseSkillPanel.LevelHasCollectibles: Boolean;
begin
  Result := Level.Info.CollectibleCount > 0;
end;

function TBaseSkillPanel.LevelHasTalismans: Boolean;
begin
  Result := Level.Talismans.Count > 0;
end;

end.
