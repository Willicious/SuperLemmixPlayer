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
    function ReplayMarkRect: TRect; override;

    procedure CreateNewInfoString; override;
    function DrawStringLength: Integer; override;
    function DrawStringTemplate: string; override;
    function TimeLimitStartIndex: Integer; override;
    function CursorInfoEndIndex: Integer; override;
    function LemmingCountStartIndex: Integer; override;
    function LemmingSavedStartIndex: Integer; override;
  public
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

implementation

uses
  GameControl, LemCore;

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
  if GameParams.ShowMinimap then
    Result := 888
  else
    Result := 672;
end;

function TSkillPanelStandard.PanelHeight: Integer;
begin
  Result := 80;
end;

function TSkillPanelStandard.DrawStringLength: Integer;
begin
  Result := 42;
end;

function TSkillPanelStandard.DrawStringTemplate: string;
begin
  Result := '..............' + '.' + ' ' + '.' + ' ' + #93 + '_...' + ' ' + #94 + '_...' + ' '
                           + #95 + '_...' + ' ' + #96 +  '_.-..';
end;

function TSkillPanelStandard.TimeLimitStartIndex: Integer;
begin
  Result := 37;
end;

// First 2 digits = left & top of minimap frame
// Second 2 digits = width & height of minimap itself
function TSkillPanelStandard.MinimapRect: TRect;
begin
  if GameParams.AmigaTheme then
    Result := Rect(704, 4, 862, 72)
  else
    Result := Rect(710, 4, 880, 72);
end;

// Assigns a clickable rectangle to the replay "R" icon
function TSkillPanelStandard.ReplayMarkRect: TRect;
begin
  Result := Rect(212, 4, 232, 32);
end;

procedure TSkillPanelStandard.CreateNewInfoString;
begin
  if (Game.StateIsUnplayable and not Game.ShouldExitToPostview) then
    SetPanelMessage(1);

  SetInfoCursor(1);
  SetReplayMark(14);
  SetCollectibleIcon(16);
  SetInfoLemHatch(20);
  SetInfoLemAlive(26);
  SetInfoLemIn(32);
  SetTimeLimit(37);
  SetInfoTime(38, 41);
end;

function TSkillPanelStandard.GetButtonList: TPanelButtonArray;
var
  i : Integer;
begin
  SetLength(Result, 24);
  Result[0] := spbSlower;
  Result[1] := spbFaster;
  for i := 2 to (0 + MAX_SKILL_TYPES_PER_LEVEL -1) do
    Result[i] := Low(TSkillPanelButton); // Placeholder for any skill
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL] := spbPause;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 1] := spbRewind;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 2] := spbFastForward;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 3] := spbRestart;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 4] := spbNuke;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 5] := spbSquiggle;
end;

function TSkillPanelStandard.CursorInfoEndIndex: Integer;
begin
  Result := 13;
end;

function TSkillPanelStandard.LemmingCountStartIndex: Integer;
begin
  Result := 26;
end;

function TSkillPanelStandard.LemmingSavedStartIndex: Integer;
begin
  Result := 32;
end;

procedure TSkillPanelStandard.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
if GameParams.ShowMinimap then
  begin
    TempBmp := TBitmap32.Create;
    TempBmp.Assign(MinimapRegion);

    // Changing the first digit changes the right side of the minimap frame
    if GameParams.AmigaTheme then
    begin
      MinimapRegion.SetSize(188, 78);
      MinimapRegion.Clear($FF000000);
      DrawNineSlice(MinimapRegion, MinimapRegion.BoundsRect, TempBmp.BoundsRect, Rect(16, 16, 32, 6), TempBmp);
    end else if (MinimapRegion.Width <> 182) or (MinimapRegion.Height <> 78) then
    begin
      MinimapRegion.SetSize(182, 78);
      MinimapRegion.Clear($FF000000);
      DrawNineSlice(MinimapRegion, MinimapRegion.BoundsRect, TempBmp.BoundsRect, Rect(16, 16, 16, 16), TempBmp);
    end;

    TempBmp.Free;
  end;
end;

end.

