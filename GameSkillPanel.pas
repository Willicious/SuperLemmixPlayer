{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  LemTypes,
  Classes, GR32,
  GameWindowInterface, GameBaseSkillPanel,
  SharedGlobals;

type
  TSkillPanelStandard = class(TBaseSkillPanel)
  protected
    function GetButtonList: TPanelButtonArray; override;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    function MinimapRect: TRect; override;
    function ReplayMarkRect: TRect; override;
    function RescueCountRect: TRect; override;

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
  if GameParams.AmigaTheme then
    Result := '..............' +       // 0 Cursor info
              '.' + ' ' +              // 14 Replay mark
              '.' + ' ' +              // 16 Collectible icon
              'OUT' + ' ...' + ' ' +   // 18 Lemmings out       // 22 LemAlive
              'IN' + ' ...' + ' ' +    // 26 Lemmings in (home) // 29 LemIn
              'TIME' + ' .-..'         // 34 Time               // 39 Time limit
  else
    Result := '..............' +       // 0 Cursor info
              '.' + ' ' +              // 14 Replay mark
              '.' + ' ' +              // 16 Collectible icon
              #93 + '_...' + ' ' +     // 18 Hatch icon        // 19 LemHatch
              #94 + '_...' + ' ' +     // 24 Lem icon          // 25 LemAlive
              #95 + '_...' + ' ' +     // 30 Exit icon         // 31 LemIn
              #97 + '_.-..';           // 36 Time icon         // 37 Time Limit
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

// Assigns a non-clickable rectangle to the rescue count icon & digits
function TSkillPanelStandard.RescueCountRect: TRect;
var
  LemmingsSaved: Integer;
  DigitCount: Integer;
begin
  LemmingsSaved := Game.LemmingsSaved;

  if LemmingsSaved >= 0 then // For positive numbers
  begin
    if LemmingsSaved < 10 then
      DigitCount := 1
    else if LemmingsSaved < 100 then
      DigitCount := 2
    else
      DigitCount := 3;
  end else
  begin
    if LemmingsSaved > -10 then // For negative numbers, including the '-' sign
      DigitCount := 2
    else
      DigitCount := 3;
  end;

  Result := Rect(478, 4, 512 + DigitCount * 16, 32);
end;

procedure TSkillPanelStandard.CreateNewInfoString;
begin
  if (Game.StateIsUnplayable and not Game.ShouldExitToPostview) then
    SetPanelMessage(1);

  if GameParams.AmigaTheme then
  begin
    SetInfoCursor(1);
    SetReplayMark(14);
    SetCollectibleIcon(16);
    SetInfoLemAlive(22);
    SetInfoLemIn(29);
    SetInfoTime(38, 41);
  end else begin
    SetInfoCursor(1);
    SetReplayMark(14);
    SetCollectibleIcon(16);
    SetInfoLemHatch(20);
    SetInfoLemAlive(26);
    SetExitIcon(31);
    SetInfoLemIn(32);
    SetTimeLimit(37);
    SetInfoTime(38, 41);
  end;
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
  if GameParams.AmigaTheme then
    Result := 22
  else
    Result := 26;
end;

function TSkillPanelStandard.LemmingSavedStartIndex: Integer;
begin
  if GameParams.AmigaTheme then
    Result := 29
  else
  Result := 32;
end;

end.

