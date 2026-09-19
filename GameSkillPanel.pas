{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  Math,
  LemTypes,
  Classes, GR32,
  GameWindowInterface, GameBaseSkillPanel,
  SharedGlobals;

type
  TSkillPanel = class(TBaseSkillPanel)
  protected
    function GetButtonList: TPanelButtonArray; override;

    function MinimapRect: TRect; override;
    function ReplayIconRect: TRect; override;
    function CollectibleIconRect: TRect; override;
    function TalismanIconRect: TRect; override;
    function HatchIconRect: TRect; override;
    function AliveIconRect: TRect; override;
    function ExitIconRect: TRect; override;
    function TimeIconRect: TRect; override;
  public
    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

implementation

uses
  GameControl, LemCore;

constructor TSkillPanel.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited;
end;

destructor TSkillPanel.Destroy;
begin
  inherited;
end;

function TSkillPanel.PanelWidth: Integer;
begin
  if GameParams.ShowMinimap then
    Result := 888
  else
    Result := 672;
end;

function TSkillPanel.PanelHeight: Integer;
begin
  Result := 80;
end;

// First 2 digits = left & top of minimap frame
// Second 2 digits = width & height of minimap itself
function TSkillPanel.MinimapRect: TRect;
begin
  if GameParams.AmigaTheme then
    Result := Rect(704, 4, 862, 72)
  else
    Result := Rect(710, 4, 880, 72);
end;

function TSkillPanel.ReplayIconRect: TRect;
begin
  Result := Rect(200, 0, 220, 32);
end;

function TSkillPanel.CollectibleIconRect: TRect;
begin                 // add 36 if including text
  Result := Rect(240, 0, 266, 32);
end;

function TSkillPanel.TalismanIconRect: TRect;
begin
  Result := Rect(280, 0, 306, 32);
end;

function TSkillPanel.HatchIconRect: TRect;
begin
  var Left := IfThen(LevelHasCollectibles or LevelHasTalismans, 360, 280);
  Result := Rect(Left, 0, Left + 60, 32);
end;

function TSkillPanel.AliveIconRect: TRect;
begin
  var Left := IfThen(LevelHasCollectibles or LevelHasTalismans, 440, 380);
  Result := Rect(Left, 0, Left + 60, 32);
end;

function TSkillPanel.ExitIconRect: TRect;
begin
  var Left := IfThen(LevelHasCollectibles or LevelHasTalismans, 520, 480);
  Result := Rect(Left, 0, Left + 60, 32);
end;

function TSkillPanel.TimeIconRect: TRect;
begin
  Result := Rect(600, 0, 676, 32);
end;

function TSkillPanel.GetButtonList: TPanelButtonArray;
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

end.

