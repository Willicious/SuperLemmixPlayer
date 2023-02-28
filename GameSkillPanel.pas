{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  LemTypes,
  Classes, GR32,
  GameWindowInterface, GameBaseSkillPanel;

type
  TSkillPanelStandard = class(TBaseSkillPanel)
  protected
    function GetButtonList: TPanelButtonArray; override;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    function MinimapRect: TRect; override;

    procedure CreateNewInfoString; override;
    function DrawStringLength: Integer; override;
    function DrawStringTemplate: string; override;
    function TimeLimitStartIndex: Integer; override;
    function LemmingCountStartIndex: Integer; override;
  public
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

  //TSkillPanelCompact = class(TBaseSkillPanel)
  //protected
    //function GetButtonList: TPanelButtonArray; override;

    //function PanelWidth: Integer; override;
    //function PanelHeight: Integer; override;

    //procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    //function MinimapRect: TRect; override;

    //procedure CreateNewInfoString; override;
    //function DrawStringLength: Integer; override;
    //function DrawStringTemplate: string; override;
    //function TimeLimitStartIndex: Integer; override;
    //function LemmingCountStartIndex: Integer; override;
  //public
    //constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    //destructor Destroy; override;
  //end;

implementation

uses
  GameControl, LemCore;

{ TSkillPanelStandard }

constructor TSkillPanelStandard.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited;
end;

destructor TSkillPanelStandard.Destroy;
begin
  inherited;
end;

function TSkillPanelStandard.PanelWidth: Integer;
begin
  Result := 442 * ResMod;
end;

function TSkillPanelStandard.PanelHeight: Integer;
begin
  Result := 40 * ResMod;
end;

function TSkillPanelStandard.DrawStringLength: Integer;
begin
  Result := 41;
end;

function TSkillPanelStandard.DrawStringTemplate: string;
begin
  Result := '...............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;

function TSkillPanelStandard.TimeLimitStartIndex: Integer;
begin
  Result := 35;
end;

//First set of digits adust left & top pos of minimap frame, second set of digits adjusts left & top pos of minimap itself
function TSkillPanelStandard.MinimapRect: TRect;
begin
  Result := Rect(371 * ResMod, 2 * ResMod, 438 * ResMod, 36 * ResMod);
end;

procedure TSkillPanelStandard.CreateNewInfoString;
begin
  SetInfoCursorLemming(1);
  SetReplayMark(16);
  SetInfoLemHatch(19);
  SetInfoLemAlive(25);
  SetInfoLemIn(31);
  SetTimeLimit(36);
  SetInfoTime(37, 40);
end;

function TSkillPanelStandard.GetButtonList: TPanelButtonArray;
var
  i : Integer;
begin
  SetLength(Result, 23);
  Result[0] := spbSlower;
  Result[1] := spbFaster;
  for i := 2 to (0 + MAX_SKILL_TYPES_PER_LEVEL -1) do
    Result[i] := Low(TSkillPanelButton); // placeholder for any skill
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL] := spbPause;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 1] := spbFastForward;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 2] := spbRestart;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 3] := spbNuke;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 4] := spbSquiggle; //spbBackOneFrame; // and below: spbForwardOneFrame
  //Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 5] := spbDirLeft; // and below: spbDirRight
  //Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 6] := spbClearPhysics; // and below: spbLoadReplay
end;

function TSkillPanelStandard.LemmingCountStartIndex: Integer;
begin
  Result := 21;
end;

procedure TSkillPanelStandard.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(MinimapRegion);

  //changing the first digit changes the right side of the minimap frame
  if (MinimapRegion.Width <> 72 * ResMod) or (MinimapRegion.Height <> 40 * ResMod) then
  begin
    MinimapRegion.SetSize(72 * ResMod, 40 * ResMod);
    MinimapRegion.Clear($FF000000);
    DrawNineSlice(MinimapRegion, MinimapRegion.BoundsRect, TempBmp.BoundsRect,
                  Rect(8 * ResMod, 8 * ResMod, 8 * ResMod, 8 * ResMod), TempBmp);
  end;

  TempBmp.Free;
end;


{ TSkillPanelCompact }

//constructor TSkillPanelCompact.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
//begin
  //inherited;
//end;

//destructor TSkillPanelCompact.Destroy;
//begin
  //inherited;
//end;

//function TSkillPanelCompact.PanelWidth: Integer;
//begin
  //Result := 320 * ResMod;
//end;

//function TSkillPanelCompact.PanelHeight: Integer;
//begin
  //Result := 40 * ResMod;
//end;

//function TSkillPanelCompact.DrawStringLength: Integer;
//begin
  //Result := 38;
//end;

//function TSkillPanelCompact.DrawStringTemplate: string;
//begin
  //Result := '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           //+ #94 + '_...' + ' ' + #95 +  '_.-..';
//end;

//function TSkillPanelCompact.TimeLimitStartIndex: Integer;
//begin
  //Result := 33;
//end;

//function TSkillPanelCompact.LemmingCountStartIndex: Integer;
//begin
  //Result := 21;
//end;

//function TSkillPanelCompact.MinimapRect: TRect;
//begin
  //Result := Rect(228 * ResMod, 18 * ResMod, 316 * ResMod, 38 * ResMod)
//end;

//procedure TSkillPanelCompact.CreateNewInfoString;
//begin
  //SetInfoCursorLemming(1);
  //SetReplayMark(13);
  //SetInfoLemHatch(16);
  //SetInfoLemAlive(22);
  //SetInfoLemIn(28);
  //SetTimeLimit(33);
  //SetInfoTime(34, 37);
//end;

//function TSkillPanelCompact.GetButtonList: TPanelButtonArray;
//var
  //i : Integer;
//begin
  //SetLength(Result, 14);
  //Result[0] := spbSlower;
  //Result[1] := spbFaster;
  //for i := 2 to (2 + MAX_SKILL_TYPES_PER_LEVEL - 1) do
    //Result[i] := Low(TSkillPanelButton); // placeholder for any skill
  //Result[2 + MAX_SKILL_TYPES_PER_LEVEL] := spbPause;
  //Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 1] := spbNuke;
//end;

//procedure TSkillPanelCompact.ResizeMinimapRegion(MinimapRegion: TBitmap32);
//var
  //TempBmp: TBitmap32;
//begin
  //TempBmp := TBitmap32.Create;
  //TempBmp.Assign(MinimapRegion);

  //if (MinimapRegion.Width <> 95 * ResMod) or (MinimapRegion.Height <> 24 * ResMod) then
  //begin
    //MinimapRegion.SetSize(95 * ResMod, 24 * ResMod);
    //MinimapRegion.Clear($FF000000);
    //DrawNineSlice(MinimapRegion, MinimapRegion.BoundsRect, TempBmp.BoundsRect,
                  //Rect(8 * ResMod, 8 * ResMod, 8 * ResMod, 8 * ResMod), TempBmp);
  //end;

  //TempBmp.Free;
//end;


end.

