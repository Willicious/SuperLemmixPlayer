unit LemTalisman;

interface

uses
  LemCore,
  LemNeoParser,
  UMisc,
  Classes, SysUtils;

type
  TTalismanColor = (tcBronze, tcSilver, tcGold);

  TTalisman = class
  private
    fTitle: String;
    fData: Pointer; // Unused when loaded in a TLevel; points to the owner TNeoLevelEntry when in a TNeoLevelEntry or TNeoLevelGroup
    fID: LongWord;
    fColor: TTalismanColor;
    fRescueCount: Integer;
    fTimeLimit: Integer;
    fTotalSkillLimit: Integer;
    fSkillTypeLimit: Integer;
    fSkillLimits: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of Integer;
    fRequireKillZombies: Boolean;
    fRequireClassicMode: Boolean;
    fRequireNoPause: Boolean;

    fLevelLemmingCount: Integer;

    fRequirementText: String;

    function GetSkillLimit(aSkill: TSkillPanelButton): Integer;
    procedure SetSkillLimit(aSkill: TSkillPanelButton; aCount: Integer);
  public
    constructor Create;

    procedure LoadFromSection(aSec: TParserSection);
    procedure SaveToSection(aSec: TParserSection);

    procedure SetRequirementText(aValue: String);
    procedure Clone(aSrc: TTalisman);

    property Title: String read fTitle write fTitle;
    property ID: LongWord read fID write fID;
    property Data: Pointer read fData write fData;
    property Color: TTalismanColor read fColor write fColor;
    property RescueCount: Integer read fRescueCount write fRescueCount;
    property TimeLimit: Integer read fTimeLimit write fTimeLimit;
    property TotalSkillLimit: Integer read fTotalSkillLimit write fTotalSkillLimit;
    property SkillTypeLimit: Integer read fSkillTypeLimit write fSkillTypeLimit;
    property SkillLimit[Index: TSkillPanelButton]: Integer read GetSkillLimit write SetSkillLimit;
    property RequireKillZombies: Boolean read fRequireKillZombies write fRequireKillZombies;
    property RequireClassicMode: Boolean read fRequireClassicMode write fRequireClassicMode;
    property RequireNoPause: Boolean read fRequireNoPause write fRequireNoPause;
    property RequirementText: String read fRequirementText;

    property LevelLemmingCount: Integer read fLevelLemmingCount write fLevelLemmingCount;
  end;

implementation

uses
  Math;

procedure TTalisman.Clone(aSrc: TTalisman);
var
  Skill: TSkillPanelButton;
begin
  fTitle := aSrc.fTitle;
  fData := aSrc.fData;
  fID := aSrc.fID;
  fColor := aSrc.fColor;
  fRescueCount := aSrc.fRescueCount;
  fTimeLimit := aSrc.fTimeLimit;
  fTotalSkillLimit := aSrc.fTotalSkillLimit;
  fSkillTypeLimit := aSrc.fSkillTypeLimit;

  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillLimits[Skill] := aSrc.fSkillLimits[Skill];

  fLevelLemmingCount := aSrc.fLevelLemmingCount;
  fRequirementText := aSrc.fRequirementText;
end;

constructor TTalisman.Create;
var
  i: TSkillPanelButton;
begin
  inherited;
  fTitle := 'Untitled Talisman';
  fID := 0;
  fColor := tcBronze;
  fRescueCount := -1;
  fTimeLimit := -1;
  fTotalSkillLimit := -1;
  fSkillTypeLimit := -1;

  fLevelLemmingCount := -1;

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillLimits[i] := -1;
end;

procedure TTalisman.SetRequirementText(aValue: String);
begin
  fRequirementText := aValue;
end;

procedure TTalisman.SetSkillLimit(aSkill: TSkillPanelButton; aCount: Integer);
begin
  if aSkill <= LAST_SKILL_BUTTON then
    fSkillLimits[aSkill] := aCount;
end;

function TTalisman.GetSkillLimit(aSkill: TSkillPanelButton): Integer;
begin
  if aSkill <= LAST_SKILL_BUTTON then
    Result := fSkillLimits[aSkill]
  else
    Result := -1;
end;

procedure TTalisman.LoadFromSection(aSec: TParserSection);
var
  i: TSkillPanelButton;
  NumEachSkillRestr: Integer;
  S: String;
begin
  fTitle := aSec.LineTrimString['title'];
  fID := aSec.LineNumericDefault['id', 0];

  S := Lowercase(aSec.LineTrimString['color']);
  if S = 'gold' then
    fColor := tcGold
  else if S = 'silver' then
    fColor := tcSilver
  else
    fColor := tcBronze;

  fRescueCount := aSec.LineNumericDefault['save', -1];
  fRescueCount := aSec.LineNumericDefault['save_requirement', fRescueCount];
  fTimeLimit := aSec.LineNumericDefault['time_limit', -1];
  fTotalSkillLimit := aSec.LineNumericDefault['skill_limit', -1];
  fSkillTypeLimit := aSec.LineNumericDefault['skill_type_limit', -1];

  // Apply single skill restrictions
  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillLimits[i] := aSec.LineNumericDefault[SKILL_NAMES[i] + '_limit', -1];

  // Apply skill restrictions to all
  NumEachSkillRestr := aSec.LineNumericDefault['skill_each_limit', -1];
  if (NumEachSkillRestr >= 0) then
    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      fSkillLimits[i] := NumEachSkillRestr;

  // Apply use-only-one skill restriction
  S := Lowercase(aSec.LineTrimString['use_only_skill']);
  if S.Length > 1 then
    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if SKILL_NAMES[i] <> S then
        fSkillLimits[i] := 0;

  if aSec.Line['kill_zombies'] <> nil then
    fRequireKillZombies := true;

  if aSec.Line['classic_mode'] <> nil then
    fRequireClassicMode := true;

  if aSec.Line['no_pause'] <> nil then
    fRequireNoPause := true;

end;

procedure TTalisman.SaveToSection(aSec: TParserSection);
var
  i: TSkillPanelButton;

  procedure AddLine(aKeyword: String; aValue: Integer);
  begin
    if aValue = -1 then Exit;
    aSec.AddLine(aKeyword, aValue);
  end;
begin
  aSec.AddLine('title', fTitle);
  aSec.AddLine('id', fID);

  case fColor of
    tcBronze: aSec.AddLine('color', 'bronze');
    tcSilver: aSec.AddLine('color', 'silver');
    tcGold: aSec.AddLine('color', 'gold');
  end;

  AddLine('save_requirement', fRescueCount);
  AddLine('time_limit', fTimeLimit);
  AddLine('skill_limit', fTotalSkillLimit);
  AddLine('skill_type_limit', fSkillTypeLimit);

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    AddLine(SKILL_NAMES[i] + '_limit', fSkillLimits[i]);

  if fRequireKillZombies then
    aSec.AddLine('kill_zombies');

  if fRequireClassicMode then
    aSec.AddLine('classic_mode');

  if fRequireNoPause then
    aSec.AddLine('no_pause');
end;

end.
