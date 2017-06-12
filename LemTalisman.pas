unit LemTalisman;

interface

uses
  LemCore,
  LemNeoParser,
  Classes, SysUtils;

type
  TTalismanColor = (tcBronze, tcSilver, tcGold);
  TTalismanSpecialCondition = (tscNull, tscOneSkillPerLemming, tscAssignToOne);
  TTalismanSpecialConditions = set of TTalismanSpecialCondition;

  TTalisman = class
  private
    fTitle: String;
    fID: LongWord;
    fColor: TTalismanColor;
    fRescueCount: Integer;
    fTimeLimit: Integer;
    fTotalSkillLimit: Integer;
    fSkillLimits: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of Integer;

    function GetSkillLimit(aSkill: TSkillPanelButton): Integer;
    procedure SetSkillLimit(aSkill: TSkillPanelButton; aCount: Integer);
  public
    constructor Create;

    procedure LoadFromSection(aSec: TParserSection);
    procedure SaveToSection(aSec: TParserSection);

    //function CheckIfAchieved(aGame: TLemmingGame): Boolean;

    property Title: String read fTitle write fTitle;
    property ID: LongWord read fID write fID;
    property Color: TTalismanColor read fColor write fColor;
    property RescueCount: Integer read fRescueCount write fRescueCount;
    property TimeLimit: Integer read fTimeLimit write fTimeLimit;
    property TotalSkillLimit: Integer read fTotalSkillLimit write fTotalSkillLimit;
    property SkillLimit[Index: TSkillPanelButton]: Integer read GetSkillLimit write SetSkillLimit;
  end;

implementation

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

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillLimits[i] := -1;
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
  fTimeLimit := aSec.LineNumericDefault['time_limit', -1];
  fTotalSkillLimit := aSec.LineNumericDefault['skill_limit', -1];

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    fSkillLimits[i] := aSec.LineNumericDefault[SKILL_NAMES[i] + '_limit', -1];
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

  AddLine('save', fRescueCount);
  AddLine('time_limit', fTimeLimit);
  AddLine('skill_limit', fTotalSkillLimit);

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    AddLine(SKILL_NAMES[i] + '_limit', fSkillLimits[i]);
end;

(*function TTalisman.CheckIfAchieved(aGame: TLemmingGame): Boolean;
var
  SaveReq: Integer;
  i: TSkillPanelButton;
  TotalSkills: Integer;
begin
  Result := false;

  if fRescueCount >= 0 then
    SaveReq := fRescueCount
  else
    SaveReq := aGame.Level.Info.RescueCount;

  if aGame.LemmingsSaved < SaveReq then Exit;
  if (aGame.CurrentIteration >= fTimeLimit) and (fTimeLimit >= 0) then Exit;

  TotalSkills := 0;
  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    if (aGame.SkillsUsed[i] > fSkillLimits[i]) and (fSkillLimits[i] >= 0) then Exit;
    Inc(TotalSkills, aGame.SkillsUsed[i]);
  end;

  if (TotalSkills > fTotalSkillLimit) and (fTotalSkillLimit >= 0) then Exit;
end;*)

end.
