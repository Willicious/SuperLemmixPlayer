unit LemTalisman;

interface

uses
  LemCore,
  LemNeoParser,
  UMisc,
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

    function MakeRequirementText: String;
  public
    constructor Create;

    procedure LoadFromSection(aSec: TParserSection);
    procedure SaveToSection(aSec: TParserSection);

    property Title: String read fTitle write fTitle;
    property ID: LongWord read fID write fID;
    property Color: TTalismanColor read fColor write fColor;
    property RescueCount: Integer read fRescueCount write fRescueCount;
    property TimeLimit: Integer read fTimeLimit write fTimeLimit;
    property TotalSkillLimit: Integer read fTotalSkillLimit write fTotalSkillLimit;
    property SkillLimit[Index: TSkillPanelButton]: Integer read GetSkillLimit write SetSkillLimit;
    property RequirementText: String read MakeRequirementText;
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

function TTalisman.MakeRequirementText: String;
var
  i: TSkillPanelButton;
  HasLemReq: Boolean;
  HasTimeReq: Boolean;
  HasSkillZeroReq: Boolean;
  HasSkillNonZeroReq: Boolean;
  HasSkillReq: Boolean;
  DoneFirstSkillLimit: Boolean;
const
  CENTISECONDS: array[0..16] of String = ('00', '06', '12', '18',
                                          '24', '29', '35', '41',
                                          '47', '53', '59', '65',
                                          '71', '76', '82', '88',
                                          '94');
begin
  Result := '';
  HasLemReq := RescueCount >= 0;
  HasTimeReq := TimeLimit >= 0;
  HasSkillZeroReq := false; // for now
  HasSkillNonZeroReq := false; // for now
  HasSkillReq := false; // for now

  if HasLemReq then
    Result := Result + 'save ' + IntToStr(RescueCount) + ' '
  else
    Result := Result + 'complete ';

  if HasTimeReq then
    Result := Result + 'in under ' + IntToStr(TimeLimit div 1020) + ':' +
                                     LeadZeroStr((TimeLimit mod 1020) div 17, 2) + '.' +
                                     CENTISECONDS[TimeLimit mod 17] + ' ';

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if SkillLimit[i] = 0 then
    begin
      if not HasSkillZeroReq then
      begin
        HasSkillZeroReq := true;
        HasSkillReq := true;
        Result := Result + 'with no ' + SKILL_NAMES[i] + 's';
      end else
        Result := Result + ', ' + SKILL_NAMES[i] + 's';
    end;

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if SkillLimit[i] > 0 then
    begin
      if not HasSkillReq then
        Result := Result + 'with ';
      if HasSkillZeroReq then
        Result := Result + '; ';
      if not HasSkillNonZeroReq then
      begin
        Result := Result + 'max ';
        HasSkillReq := true;
        HasSkillNonZeroReq := true;
      end else
        Result := Result + ', ';

      Result := Result + IntToStr(SkillLimit[i]) + ' ' + SKILL_NAMES[i];
      if SkillLimit[i] > 1 then
        Result := Result + 's';
    end;

  if TotalSkillLimit > 0 then
  begin
    if not HasSkillReq then
    begin
      Result := Result + 'with ';
      HasSkillReq := true;
    end;
    if HasSkillZeroReq then
      Result := Result + '; ';
    if not HasSkillNonZeroReq then
      Result := Result + 'max '
    else
      Result := Result + ', ';

    Result := Result + IntToStr(TotalSkillLimit) + ' total skills';
  end;

  if not (HasLemReq or HasTimeReq or HasSkillReq) then
    Result := Result + 'the level';

  Result[1] := Uppercase(Result[1])[1];
end;

end.
