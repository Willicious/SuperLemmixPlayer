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
    fData: Pointer; // unused when loaded in a TLevel; points to the owner TNeoLevelEntry when in a TNeoLevelEntry or TNeoLevelGroup
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
    property Data: Pointer read fData write fData;
    property Color: TTalismanColor read fColor write fColor;
    property RescueCount: Integer read fRescueCount write fRescueCount;
    property TimeLimit: Integer read fTimeLimit write fTimeLimit;
    property TotalSkillLimit: Integer read fTotalSkillLimit write fTotalSkillLimit;
    property SkillLimit[Index: TSkillPanelButton]: Integer read GetSkillLimit write SetSkillLimit;
    property RequirementText: String read MakeRequirementText;
  end;

implementation

uses
  Math;

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
  fTimeLimit := aSec.LineNumericDefault['time_limit', -1];
  fTotalSkillLimit := aSec.LineNumericDefault['skill_limit', -1];

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
  NumSkillsTypes, NumNoSkillUsage: Integer;
  LastSkillRestr: Integer;
  IsConstantSkillRestr: Boolean;
  HasLemReq: Boolean;
  HasTimeReq: Boolean;
  HasSkillZeroReq: Boolean;
  HasSkillNonZeroReq: Boolean;
  HasSkillReq: Boolean;
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

  // Save requirement
  if HasLemReq then
    Result := Result + 'save ' + IntToStr(RescueCount) + ' '
  else
    Result := Result + 'complete ';

  // Time requirement
  if HasTimeReq then
    Result := Result + 'in under ' + IntToStr(TimeLimit div 1020) + ':' +
                                     LeadZeroStr((TimeLimit mod 1020) div 17, 2) + '.' +
                                     CENTISECONDS[TimeLimit mod 17] + ' ';

  // Get stats for skill requirements
  NumSkillsTypes := 0;
  NumNoSkillUsage := 0;
  LastSkillRestr := 200;
  IsConstantSkillRestr := True;
  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    Inc(NumSkillsTypes);
    if SkillLimit[i] = 0 then
      Inc(NumNoSkillUsage);

    if (SkillLimit[i] < 0) or ((LastSkillRestr < 200) and (SkillLimit[i] <> LastSkillRestr)) then
      IsConstantSkillRestr := False;

    if (LastSkillRestr = 200) then
      LastSkillRestr := SkillLimit[i];
  end;

  // Single skill requirements
  if IsConstantSkillRestr then
  begin
    // Restrict to a constant value for all skills
    Result := Result + 'with no more than '
                     + IntToStr(SkillLimit[Low(TSkillPanelButton)])
                     + ' of each skill';

    HasSkillReq := true;
    HasSkillNonZeroReq := true;
  end
  else if NumNoSkillUsage = NumSkillsTypes - 1 then
  begin
    // Only use one skill
    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if SkillLimit[i] < 0 then
        Result := Result + 'using only ' + SKILL_NAMES[i] + 's';

    HasSkillReq := true;
    HasSkillZeroReq := true;
  end
  else
  begin
    // General requirements
    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    begin
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
    end;

    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    begin
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
    end;
  end;

  // Total skill number requirement
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
