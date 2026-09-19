{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
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
    function TimeIconRect: TRect; override;

    function HatchIconRect: TRect; override;
    function AliveIconRect: TRect; override;
    function ExitIconRect: TRect; override;
    function GetPanelRect(aPos, aOffset, aValue: Integer): TRect;
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

// Assigns a clickable rectangle to the replay "R" icon
function TSkillPanel.ReplayIconRect: TRect;
begin
  Result := Rect(212, 4, 232, 32);
end;

// Assigns a non-clickable rectangle to the timer icon & digits
function TSkillPanel.TimeIconRect: TRect;
begin
  if GameParams.AmigaTheme then
    Result := Rect(0, 0, 0, 0) // No need to show panel hint in Amiga theme
  else
    Result := Rect(578, 0, 672, 32)
end;

// Assigns a non-clickable rectangle to the hatch count icon & digits
function TSkillPanel.HatchIconRect: TRect;
begin
  if GameParams.AmigaTheme then
    Result := Rect(0, 0, 0, 0) // Amiga theme doesn't show hatch count
  else
    //Result := GetPanelRect(288, Game.LemmingsToSpawn - Game.SpawnedDead, 32);
    Result := Rect(288, 0, 340, 32);
end;

// Assigns a non-clickable rectangle to the alive count icon & digits
function TSkillPanel.AliveIconRect: TRect;
var
  Left, ThemeOffset, LemAliveCount: Integer;
begin
  if GameParams.AmigaTheme then
  begin
    Left := 288;
    ThemeOffset := 64;
    LemAliveCount := Game.LemmingsActive;
  end else begin
    Left := 386;
    ThemeOffset := 32;
    LemAliveCount := Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead;
  end;

  Result := Rect(386, 0, 432, 32);
  //Result := GetPanelRect(Left, ThemeOffset, LemAliveCount);
end;

// Assigns a non-clickable rectangle to the exit count icon & digits
function TSkillPanel.ExitIconRect: TRect;
var
  Left, ThemeOffset, SaveCount: Integer;
begin
  if GameParams.AmigaTheme then
  begin
    Left := 418;
    ThemeOffset := 46;
  end else begin
    Left := 478;
    ThemeOffset := 32;
  end;

  if (Game.LemmingsSaved > Level.Info.RescueCount) then
    SaveCount := Game.LemmingsSaved
  else
    SaveCount := Level.Info.RescueCount;

  Result := Rect(478, 0, 510, 32);
  //Result := GetPanelRect(Left, ThemeOffset, SaveCount)
end;

function TSkillPanel.GetPanelRect(aPos, aOffset, aValue: Integer): TRect;
var
  Left, Right, DigitCount: Integer;
begin
  if aValue >= 0 then // For positive numbers
  begin
    if aValue < 10 then
      DigitCount := 1
    else if aValue < 100 then
      DigitCount := 2
    else
      DigitCount := 3;
  end else
  begin
    if aValue > -10 then // For negative numbers, including the '-' sign
      DigitCount := 2
    else
      DigitCount := 3;
  end;

  Left := aPos;
  Right := Left + aOffset + (DigitCount * 16);

  Result := Rect(Left, 4, Right, 32);
end;

//procedure TSkillPanel.CreateNewInfoString; // TODO - extract to refactor
//begin
//  if (Game.StateIsUnplayable and not Game.ShouldExitToPostview) then
//    SetPanelMessage(1);
//end;

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

