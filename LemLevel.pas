{$include lem_directives.inc}
unit LemLevel;

interface

uses
  System.Generics.Collections, System.Generics.Defaults,
  Classes, SysUtils, StrUtils, UMisc,
  LemCore, LemLemming,
  LemTalisman,
  LemTerrain, LemTerrainGroup, LemGadgetsModel, LemGadgets, LemGadgetsConstants, LemGadgetsMeta,
  LemStrings, LemTypes,
  LemNeoPieceManager, LemNeoParser;

type
  TSkillSet = set of TSkillPanelButton;
  TSkillCounts = array[Low(TSkillPanelButton)..High(TSkillPanelButton)] of Integer; // non-skill buttons are just unused

  TLevelInfo = class
  private
  protected
    fSpawnIntervalLocked : Boolean;
    fSpawnInterval  : Integer;
    fLemmingsCount  : Integer;
    fZombieCount    : Integer;
    fNeutralCount   : Integer;
    fRescueCount    : Integer;
    fHasTimeLimit   : Boolean;
    fTimeLimit      : Integer;
    fSuperlemming   : Boolean;
    //fKaroshi        : Boolean;

    fSkillset: TSkillset;
    fSkillCounts: TSkillCounts;

    fWidth : Integer;
    fHeight : Integer;

    fBackground: String;
    fLoadBackground: String;

    fScreenStartX : Integer;
    fScreenStartY: Integer;
    fScreenStartAuto: Boolean;

    fTitle          : string;
    fAuthor         : string;

    fGraphicSetName : string;
    fLoadGraphicSetName: string;
    fMusicFile      : string;

    fLevelID        : Int64;
    fLevelVersion   : Int64;

    procedure SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
    function GetSkillCount(aSkill: TSkillPanelButton): Integer;
  protected
  public
    SpawnOrder       : array of Integer;
    constructor Create;
    procedure Clear; virtual;

    property SpawnInterval    : Integer read fSpawnInterval write fSpawnInterval;
    property SpawnIntervalLocked: Boolean read fSpawnIntervalLocked write fSpawnIntervalLocked;
    property LemmingsCount  : Integer read fLemmingsCount write fLemmingsCount;
    property ZombieCount    : Integer read fZombieCount write fZombieCount;
    property NeutralCount   : Integer read fNeutralCount write fNeutralCount;
    property RescueCount    : Integer read fRescueCount write fRescueCount;
    property HasTimeLimit   : Boolean read fHasTimeLimit write fHasTimeLimit;
    property TimeLimit      : Integer read fTimeLimit write fTimeLimit;

    property SuperLemming : Boolean read fSuperLemming write fSuperLemming;

    property Skillset: TSkillset read fSkillset write fSkillset;
    property SkillCount[Index: TSkillPanelButton]: Integer read GetSkillCount write SetSkillCount;

    property ScreenStartX : Integer read fScreenStartX write fScreenStartX;
    property ScreenStartY : Integer read fScreenStartY write fScreenStartY;
    property ScreenStartAuto: Boolean read fScreenStartAuto write fScreenStartAuto;

    property Title          : string read fTitle write fTitle;
    property Author         : string read fAuthor write fAuthor;

    property Width          : Integer read fWidth write fWidth;
    property Height         : Integer read fHeight write fHeight;

    property GraphicSetName : String read fGraphicSetName write fGraphicSetName;
    property LoadGraphicSetName: String read fLoadGraphicSetName write fLoadGraphicSetName;
    property MusicFile      : String read fMusicFile write fMusicFile;

    property Background: String read fBackground write fBackground;
    property LoadBackground: String read fLoadBackground write fLoadBackground;

    property LevelID: Int64 read fLevelID write fLevelID;
    property LevelVersion: Int64 read fLevelVersion write fLevelVersion;
  end;

  TLevel = class
  private
    fLevelInfo       : TLevelInfo;
    fTerrainGroups      : TTerrainGroups;
    fTerrains           : TTerrains;
    fInteractiveObjects : TGadgetModelList;
    fPreplacedLemmings  : TPreplacedLemmingList;

    fTalismans: TObjectList<TTalisman>;
    fPreText: TStringList;
    fPostText: TStringList;

    // Loading routines
    procedure LoadGeneralInfo(aSection: TParserSection);
    procedure LoadSkillsetSection(aSection: TParserSection);
    procedure HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTerrainGroupEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTalismanEntry(aSection: TParserSection; const aIteration: Integer);
    procedure LoadPretextLine(aLine: TParserLine; const aIteration: Integer);
    procedure LoadPosttextLine(aLine: TParserLine; const aIteration: Integer);

    // Saving routines
    procedure SaveGeneralInfo(aSection: TParserSection);
    procedure SaveSkillsetSection(aSection: TParserSection);
    procedure SaveObjectSections(aSection: TParserSection);
    procedure SaveTerrainGroupSections(aSection: TParserSection);
    procedure SaveTerrainSections(aSection: TParserSection);
    procedure SaveLemmingSections(aSection: TParserSection);
    procedure SaveTalismanSections(aSection: TParserSection);
    procedure SaveTextSections(aSection: TParserSection);

    function GetHasAnyFallbacks: Boolean;

    procedure SanitizeTalismanAndSetText(aTalisman: TTalisman);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadFromFile(aFile: String);
    procedure LoadFromStream(aStream: TStream);

    procedure SaveToFile(aFile: String);
    procedure SaveToStream(aStream: TStream);

    procedure Sanitize;
    procedure PrepareForUse;

    function GetPickupSkillCount(aSkill: TSkillPanelButton): Integer;

    procedure CalculateAutoScreenStart(out HorzStart: Integer; out VertStart: Integer);

    property HasAnyFallbacks: Boolean read GetHasAnyFallbacks;
  published
    property Info: TLevelInfo read fLevelInfo;
    property InteractiveObjects: TGadgetModelList read fInteractiveObjects;
    property TerrainGroups: TTerrainGroups read fTerrainGroups;
    property Terrains: TTerrains read fTerrains;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings;
    property Talismans: TObjectList<TTalisman> read fTalismans;
    property PreText: TStringList read fPreText;
    property PostText: TStringList read fPostText;
  end;

implementation

uses
  LemVersion,
  Dialogs, Math; // for backwards compatibility

{ TLevelInfo }

procedure TLevelInfo.Clear;
begin
  SpawnInterval     := 53;
  SpawnIntervalLocked := false;
  LemmingsCount   := 1;
  ZombieCount     := 0;
  NeutralCount    := 0;
  RescueCount     := 1;
  HasTimeLimit    := false;
  TimeLimit       := 0;

  SuperLemming := false;

  fSkillset       := [];
  FillChar(fSkillCounts, SizeOf(TSkillCounts), 0);

  ScreenStartX  := 0;
  ScreenStartY := 0;
  ScreenStartAuto := true;

  Width           := 320;
  Height          := 160;
  Title           := '';
  Author          := '';
  fBackground     := '';

  GraphicSetName  := '';
  MusicFile       := '';
  LevelID         := 0;
  LevelVersion    := 0;
end;

constructor TLevelInfo.Create;
begin
  inherited Create;
  Clear;
end;

procedure TLevelInfo.SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
begin
  fSkillCounts[aSkill] := aCount;
end;

function TLevelInfo.GetSkillCount(aSkill: TSkillPanelButton): Integer;
begin
  Result := fSkillCounts[aSkill];
end;

{ TLevel }

constructor TLevel.Create;
begin
  inherited;
  fLevelInfo := TLevelInfo.Create;
  fInteractiveObjects := TGadgetModelList.Create;
  fTerrains := TTerrains.Create;
  fTerrainGroups := TTerrainGroups.Create;
  fPreplacedLemmings := TPreplacedLemmingList.Create;
  fTalismans := TObjectList<TTalisman>.Create(true);
  fPreText := TStringList.Create;
  fPostText := TStringList.Create;
end;

destructor TLevel.Destroy;
begin
  fLevelInfo.Free;
  fInteractiveObjects.Free;
  fTerrains.Free;
  fTerrainGroups.Free;
  fPreplacedLemmings.Free;
  fTalismans.Free;
  fPreText.Free;
  fPostText.Free;
  inherited;
end;


procedure TLevel.SanitizeTalismanAndSetText(aTalisman: TTalisman);
const
  CENTISECONDS: array[0..16] of String = ('00', '06', '12', '18',
                                          '24', '29', '35', '41',
                                          '47', '53', '59', '65',
                                          '71', '76', '82', '88',
                                          '94');
var
  Skill: TSkillPanelButton;
  ReqText: String;

  SkillTypeCount: Integer;
  AllowedSkillTypeCount: Integer;
  RemainSkillTypeCount: Integer;
  EverySkillZero: Boolean;
  TotalAvailableSkills: Integer;
  AtLeastOneSkillInfinite: Boolean;

  FirstLimitedSkillLimit: Integer;
  LimitedSkillCount: Integer;
  FoundNonMatch: Boolean;

  RestrictedSkills, ProhibitedSkills: Integer;
  MoreThanTwoSkills: Boolean;

  MadeSkillRestrictionText: Boolean;
begin
  // Save requirement - if equal or lower than level save requirement, set to none
  if aTalisman.RescueCount <= Info.RescueCount then
    aTalisman.RescueCount := -1;

  // Save requirement text - straightforward
  if aTalisman.RescueCount >= 0 then
    ReqText := 'Save ' + IntToStr(aTalisman.RescueCount) + ' / ' + IntToStr(Info.LemmingsCount - Info.ZombieCount)
  else
    ReqText := 'Complete';

  // Time limit - if level has a time limit, equal to or lower than talisman limit, set to none
  if Info.HasTimeLimit and (aTalisman.TimeLimit >= Info.TimeLimit * 17) then // Info.TimeLimit is seconds, aTalisman.TimeLimit is frames
    aTalisman.TimeLimit := -1;

  // Time limit text - straightforward. Only show centiseconds if nonzero.
  if aTalisman.TimeLimit >= 0 then
  begin
    ReqText := ReqText + ' in under ' + IntToStr(aTalisman.TimeLimit div (60 * 17)) + ':' +
                                        LeadZeroStr((aTalisman.TimeLimit div 17) mod 60, 2);

    if aTalisman.TimeLimit mod 17 <> 0 then
      ReqText := ReqText + '.' + CENTISECONDS[aTalisman.TimeLimit mod 17];
  end;

  // Skillset - if skill not in skillset, or same / lesser amount provided, set to none
  //            also do this if requirement is higher than or equal to total skills limit
  // Also gather some info for total skills to use.
  EverySkillZero := true;
  AtLeastOneSkillInfinite := false;
  TotalAvailableSkills := 0;
  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    if Skill in Info.Skillset then
    begin
      if ((Info.SkillCount[Skill] < 100) and (Info.SkillCount[Skill] + GetPickupSkillCount(Skill) <= aTalisman.SkillLimit[Skill])) or
         ((aTalisman.TotalSkillLimit >= 0) and (aTalisman.SkillLimit[Skill] >= aTalisman.TotalSkillLimit)) then
        aTalisman.SkillLimit[Skill] := -1;

      if aTalisman.SkillLimit[Skill] <> 0 then
        EverySkillZero := false;

      if Info.SkillCount[Skill] > 99 then
        AtLeastOneSkillInfinite := true;

      if aTalisman.SkillLimit[Skill] < 0 then
        TotalAvailableSkills := TotalAvailableSkills + Info.SkillCount[Skill] + GetPickupSkillCount(Skill)
      else
        TotalAvailableSkills := TotalAvailableSkills + Min(Info.SkillCount[Skill] + GetPickupSkillCount(Skill), aTalisman.SkillLimit[Skill]);
    end else
      aTalisman.SkillLimit[Skill] := -1;
  end;

  // Total skills - if every skill's limit is zero, set zero total skills limit and remove individual skill limits
  //                else if total skill limit is greater than available skill count, set it to none
  if EverySkillZero then
  begin
    aTalisman.TotalSkillLimit := 0;
    for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      aTalisman.SkillLimit[Skill] := -1;
  end else if (not AtLeastOneSkillInfinite) and (aTalisman.TotalSkillLimit >= TotalAvailableSkills) then
    aTalisman.TotalSkillLimit := -1;


  // Special cases to look for with skills, or else build default text

  MadeSkillRestrictionText := false;

  SkillTypeCount := 0;
  AllowedSkillTypeCount := 0;

  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if Skill in Info.Skillset then
    begin
      SkillTypeCount := SkillTypeCount + 1;
      if aTalisman.SkillLimit[Skill] <> 0 then
        AllowedSkillTypeCount := AllowedSkillTypeCount + 1;
    end;

  // - Skillset has at least one skill type, but talisman doesn't allow any skills

  if not MadeSkillRestrictionText then
  begin
    if ((aTalisman.TotalSkillLimit = 0) or (aTalisman.SkillTypeLimit = 0)) and (SkillTypeCount > 0) then
    begin
      ReqText := ReqText + ' without any skills';
      MadeSkillRestrictionText := true;
    end;
  end;

  // - Skillset has at least X skill types, with Y or fewer of them allowed:
  //    X 10, Y 4
  //    X  7, Y 3
  //    X  5, Y 2
  //    X  2, Y 1

  if not MadeSkillRestrictionText then
  begin
    if ((SkillTypeCount >= 10) and (AllowedSkillTypeCount <= 4)) or
       ((SkillTypeCount >=  7) and (AllowedSkillTypeCount <= 3)) or
       ((SkillTypeCount >=  5) and (AllowedSkillTypeCount <= 2)) or
       ((SkillTypeCount >=  2) and (AllowedSkillTypeCount <= 1)) then
    begin
      // "using only X[, Y and Z]"
      ReqText := ReqText + ' using only';

      RemainSkillTypeCount := AllowedSkillTypeCount;

      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if (Skill in Info.Skillset) and (aTalisman.SkillLimit[Skill] < 0) then
        begin
          ReqText := ReqText + ' ' + SKILL_PLURAL_NAMES[Skill];
          Dec(RemainSkillTypeCount);
          case RemainSkillTypeCount of
            2: ReqText := ReqText + ',';
            1: begin
                 if AllowedSkillTypeCount > 2 then
                   ReqText := ReqText + ',';
                 ReqText := ReqText + ' and';
               end;
          end;
        end;

      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if aTalisman.SkillLimit[Skill] > 0 then
        begin
          if aTalisman.SkillLimit[Skill] = 1 then
            ReqText := ReqText + ' 1 or less ' + SKILL_NAMES[Skill]
          else
            ReqText := ReqText + ' ' + IntToStr(aTalisman.SkillLimit[Skill]) + ' or less ' + SKILL_PLURAL_NAMES[Skill];
          Dec(RemainSkillTypeCount);
          case RemainSkillTypeCount of
            2: ReqText := ReqText + ',';
            1: begin
                 if AllowedSkillTypeCount > 2 then
                   ReqText := ReqText + ',';
                 ReqText := ReqText + ' and';
               end;
          end;
        end;

      MadeSkillRestrictionText := true;
    end;
  end;


  // - Same requirement (or lower purely due to skillset, on less than half) for all skill types

  if not MadeSkillRestrictionText then
  begin
    if SkillTypeCount > 1 then
    begin
      // First, we check: Do all limited skills have the same limit?
      FirstLimitedSkillLimit := -1;
      LimitedSkillCount := 0;
      FoundNonMatch := false;
      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if aTalisman.SkillLimit[Skill] > 0 then
        begin
          if FirstLimitedSkillLimit < 0 then
            FirstLimitedSkillLimit := aTalisman.SkillLimit[Skill]
          else if aTalisman.SkillLimit[Skill] <> FirstLimitedSkillLimit then
          begin
            FoundNonMatch := true;
            Break;
          end;

          Inc(LimitedSkillCount);
        end;

      // We can also check now that enough skills are limited
      if (FirstLimitedSkillLimit > 0) and
         (not FoundNonMatch) and (LimitedSkillCount > SkillTypeCount div 2) and
         ((LimitedSkillCount = 2) or (SkillTypeCount > 2)) then
      begin
        // Now we check: Do any non-limited skills allow for more uses than this limit?
        for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
          if (Skill in Info.Skillset) and (aTalisman.SkillLimit[Skill] < 0) then
          begin
            if (Info.SkillCount[Skill] > 99) or (Info.SkillCount[Skill] + GetPickupSkillCount(Skill) >= aTalisman.SkillLimit[Skill]) then
            begin
              FoundNonMatch := true;
              Break;
            end;
          end;

        if not FoundNonMatch then
        begin
          ReqText := ReqText + ' using no more than ' + IntToStr(FirstLimitedSkillLimit) + ' of each skill';
          MadeSkillRestrictionText := true;
        end;
      end;
    end;
  end;

  // Default

  if not MadeSkillRestrictionText then
  begin
    RestrictedSkills := 0;
    ProhibitedSkills := 0;
    for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if aTalisman.SkillLimit[Skill] > 0 then
        Inc(RestrictedSkills)
      else if aTalisman.SkillLimit[Skill] = 0 then
        Inc(ProhibitedSkills);

    if RestrictedSkills > 0 then
    begin
      MoreThanTwoSkills := RestrictedSkills > 2;

      ReqText := ReqText + ' using no more than';
      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if aTalisman.SkillLimit[Skill] > 0 then
        begin
          if aTalisman.SkillLimit[Skill] = 1 then
            ReqText := ReqText + ' 1 ' + SKILL_NAMES[Skill]
          else
            ReqText := ReqText + ' ' + IntToStr(aTalisman.SkillLimit[Skill]) + ' ' + SKILL_PLURAL_NAMES[Skill];

          Dec(RestrictedSkills);
          if RestrictedSkills = 1 then
          begin
            if MoreThanTwoSkills then
              ReqText := ReqText + ',';
            ReqText := ReqText + ' and';
          end else if RestrictedSkills > 1 then
            ReqText := ReqText + ',';
        end;

      MadeSkillRestrictionText := true;
    end;

    if ProhibitedSkills > 0 then
    begin
      MoreThanTwoSkills := ProhibitedSkills > 2;

      if MadeSkillRestrictionText then // at this point this would mean there WERE restricted skills
      begin
        ReqText := ReqText + ';';
        if aTalisman.TotalSkillLimit < 0 then
          ReqText := ReqText + ' and';
      end;

      ReqText := ReqText + ' without using';
      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if aTalisman.SkillLimit[Skill] = 0 then
        begin
          ReqText := ReqText + ' ' + SKILL_PLURAL_NAMES[Skill];
          Dec(ProhibitedSkills);
          if ProhibitedSkills = 1 then
          begin
            if MoreThanTwoSkills then
              ReqText := ReqText + ',';
            ReqText := ReqText + ' or';
          end else if ProhibitedSkills > 1 then
            ReqText := ReqText + ',';
        end;

      MadeSkillRestrictionText := true;
    end;
  end;

  // Total skill limit
  if aTalisman.TotalSkillLimit > 0 then
  begin
    if MadeSkillRestrictionText then
    begin
      ReqText := ReqText + ';';
      if aTalisman.SkillTypeLimit <= 0 then
        ReqText := ReqText + ' and';
    end;

    ReqText := ReqText + ' using no more than ' + IntToStr(aTalisman.TotalSkillLimit) + ' total skills';
  end;

  // Skill type limit
  if aTalisman.SkillTypeLimit > 0 then
  begin
    if MadeSkillRestrictionText or (aTalisman.TotalSkillLimit > 0) then
      ReqText := ReqText + '; and';

    ReqText := ReqText + ' using no more than ' + IntToStr(aTalisman.SkillTypeLimit) + ' different skill types';
  end;

  // Special case for talismans with no further requirements
  if ReqText = 'Complete' then
    ReqText := 'Complete the level';

  // And finally, add the note about killing zombies
  if aTalisman.RequireKillZombies then
    ReqText := ReqText + ', killing all zombies';

  ReqText := ReqText + '.';

  // Write values
  aTalisman.LevelLemmingCount := Info.LemmingsCount - Info.ZombieCount;
  aTalisman.SetRequirementText(ReqText);
end;

function TLevel.GetHasAnyFallbacks: Boolean;
var
  i: Integer;
begin
  Result := true;

  if Info.Background = 'default:fallback' then
    Exit;

  for i := 0 to InteractiveObjects.Count-1 do
    if InteractiveObjects[i].Identifier = 'default:fallback' then
      Exit;

  for i := 0 to Terrains.Count-1 do
    if Terrains[i].Identifier = 'default:fallback' then
      Exit;

  Result := false;
end;

function TLevel.GetPickupSkillCount(aSkill: TSkillPanelButton): Integer;
var
  i: Integer;
  MO: TGadgetMetaInfo;
  O: TGadgetModel;
begin
  Result := 0;
  for i := 0 to fInteractiveObjects.Count-1 do
  begin
    O := fInteractiveObjects[i];
    MO := PieceManager.Objects[O.Identifier];
    if (MO.TriggerEffect = DOM_PICKUP) and (O.Skill = Integer(aSkill)) then
      Result := Result + O.TarLev;
  end;

end;

procedure TLevel.CalculateAutoScreenStart(out HorzStart, VertStart: Integer);
var
  EntranceIndexes: TList<Integer>;
  ExitIndexes: TList<Integer>;
  PreplacedLemmingIndexes: TList<Integer>;
  i: Integer;
  O: TGadgetModel;
  MO: TGadgetMetaInfo;
  L: TPreplacedLemming;

  TargetDX: Integer;
  TargetVertShift: Boolean;
  ThisDX: Integer;

  AverageX: Double;
  AverageY: Double;

  ClosestDistance: Double;

  procedure TryPosition(X, Y, DX: Integer; VertShift: Boolean);
  var
    ThisDistance: Double;
  begin
    ThisDistance := Sqrt(((X - AverageX) * (X - AverageX)) + ((Y - AverageY) * (Y - AverageY)));
    if (ThisDistance < ClosestDistance) or (ClosestDistance < 0) then
    begin
      ClosestDistance := ThisDistance;
      HorzStart := X;
      VertStart := Y;
      TargetDX := DX;
      TargetVertShift := VertShift;
    end;
  end;
begin
  EntranceIndexes := TList<Integer>.Create;
  ExitIndexes := TList<Integer>.Create;
  PreplacedLemmingIndexes := TList<Integer>.Create;

  try
    // Fallback
    HorzStart := Info.Width div 2;
    VertStart := Info.Height div 2;
    TargetDX := 0;
    TargetVertShift := false;

    for i := 0 to fInteractiveObjects.Count-1 do
    begin
      O := fInteractiveObjects[i];
      MO := PieceManager.Objects[O.Identifier];
      if (MO.TriggerEffect = DOM_WINDOW) and ((O.TarLev and 192) = 0) then
          EntranceIndexes.Add(i);
      if MO.TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT] then
        ExitIndexes.Add(i);
    end;

    for i := 0 to fPreplacedLemmings.Count-1 do
    begin
      L := fPreplacedLemmings[i];
      if not (L.IsZombie or L.IsNeutral) then
        PreplacedLemmingIndexes.Add(i);
    end;

    AverageX := 0;
    AverageY := 0;

    if EntranceIndexes.Count >= 1 then
    begin
      for i := 0 to EntranceIndexes.Count-1 do
      begin
        O := fInteractiveObjects[EntranceIndexes[i]];
        MO := PieceManager.Objects[O.Identifier];

        AverageX := AverageX + (O.Left + MO.TriggerLeft[O.Flip, O.Invert, O.Rotate]);
        AverageY := AverageY + (O.Top + MO.TriggerTop[O.Flip, O.Invert, O.Rotate]);
      end;

      AverageX := AverageX / EntranceIndexes.Count;
      AverageY := AverageY / EntranceIndexes.Count;
    end else if PreplacedLemmingIndexes.Count >= 1 then
    begin
      for i := 0 to PreplacedLemmingIndexes.Count-1 do
      begin
        L := fPreplacedLemmings[PreplacedLemmingIndexes[i]];

        AverageX := AverageX + L.X;
        AverageY := AverageY + L.Y;
      end;

      AverageX := AverageX / PreplacedLemmingIndexes.Count;
      AverageY := AverageY / PreplacedLemmingIndexes.Count;
    end;

    ClosestDistance := -1;

    for i := 0 to EntranceIndexes.Count-1 do
    begin
      O := fInteractiveObjects[EntranceIndexes[i]];
      MO := PieceManager.Objects[O.Identifier];

      if O.Flip then
        ThisDX := -1
      else
        ThisDX := 1;

      TryPosition(O.Left + MO.TriggerLeft[O.Flip, O.Invert, O.Rotate],
                  O.Top + MO.TriggerTop[O.Flip, O.Invert, O.Rotate],
                  ThisDX, true);
    end;

    for i := 0 to ExitIndexes.Count-1 do
    begin
      O := fInteractiveObjects[ExitIndexes[i]];
      MO := PieceManager.Objects[O.Identifier];

      TryPosition(O.Left + MO.TriggerLeft[O.Flip, O.Invert, O.Rotate] + (MO.TriggerWidth[O.Flip, O.Invert, O.Rotate] div 2),
                  O.Top + MO.TriggerTop[O.Flip, O.Invert, O.Rotate] + (MO.TriggerHeight[O.Flip, O.Invert, O.Rotate] div 2),
                  0, false);
    end;

    for i := 0 to PreplacedLemmingIndexes.Count-1 do
    begin
      L := fPreplacedLemmings[PreplacedLemmingIndexes[i]];
      TryPosition(L.X, L.Y, L.Dx, false);
    end;

    if TargetDX <> 0 then
      HorzStart := HorzStart + (48 * TargetDX);

    if TargetVertShift then
      VertStart := VertStart + 20
    else
      VertStart := VertStart - 12;
  finally
    EntranceIndexes.Free;
    ExitIndexes.Free;
    PreplacedLemmingIndexes.Free;
  end;
end;

procedure TLevel.Clear;
begin
  fLevelInfo.Clear;
  fInteractiveObjects.Clear;
  fTerrains.Clear;
  fTerrainGroups.Clear;
  fPreplacedLemmings.Clear;
  fTalismans.Clear;
  fPreText.Clear;
  fPostText.Clear;
end;

procedure TLevel.LoadFromFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmOpenRead);
  try
    F.Position := 0;
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TLevel.SaveToFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmCreate);
  try
    F.Position := 0;
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

// TLevel Loading Routines

procedure TLevel.LoadFromStream(aStream: TStream);
var
  Parser: TParser;
  Main: TParserSection;
begin
  Clear;

  Parser := TParser.Create;
  try
    Parser.LoadFromStream(aStream);
    Main := Parser.MainSection;

    LoadGeneralInfo(Main);
    LoadSkillsetSection(Main.Section['skillset']);

    Main.DoForEachSection('terraingroup', HandleTerrainGroupEntry);
    if (Main.Section['gadget'] <> nil) then
      Main.DoForEachSection('gadget', HandleObjectEntry)
    else
      Main.DoForEachSection('object', HandleObjectEntry);
    Main.DoForEachSection('terrain', HandleTerrainEntry);
    Main.DoForEachSection('lemming', HandleLemmingEntry);
    Main.DoForEachSection('talisman', HandleTalismanEntry);

    if Main.Section['pretext'] <> nil then
      Main.Section['pretext'].DoForEachLine('line', LoadPretextLine);

    if Main.Section['posttext'] <> nil then
      Main.Section['posttext'].DoForEachLine('line', LoadPosttextLine);
  finally
    Parser.Free;
  end;

  Sanitize;
end;

procedure TLevel.LoadGeneralInfo(aSection: TParserSection);

  procedure HandleTimeLimit(aString: String);
  begin
    aString := Lowercase(aString);
    if (aString = '') or (aString = 'infinite') then
    begin
      Info.HasTimeLimit := false;
      Info.TimeLimit := 0;
    end else begin
      Info.HasTimeLimit := true;
      Info.TimeLimit := StrToIntDef(aString, 1);
    end;
  end;

  procedure HandleSuperLemming(aString: String);
  begin
    aString := Lowercase(aString);
    if (aString = 'true') then
    begin
      Info.SuperLemming := true;
    end else begin
      Info.SuperLemming := false;
    end;
  end;

var
  Ident: TLabelRecord;
begin
  // This procedure should receive the Parser's MAIN section
  with Info do
  begin
    Title := aSection.LineString['title'];
    Author := aSection.LineString['author'];

    GraphicSetName := PieceManager.Dealias(aSection.LineTrimString['theme'], rkStyle).Piece.GS;
    LoadGraphicSetName := aSection.LineTrimString['theme'];
    if not FileExists(AppPath + SFStyles + GraphicSetName + '\theme.nxtm') then
    begin
      PieceManager.NeedCheckStyles.Add(GraphicSetName);
      GraphicSetName := 'default'; // Tidier than using a fake "fallback"
    end;

    MusicFile := aSection.LineTrimString['music'];
    LevelID := aSection.LineNumeric['id'];
    LevelVersion := aSection.LineNumeric['version'];
    LemmingsCount := aSection.LineNumeric['lemmings'];
    RescueCount := aSection.LineNumeric['requirement'];
    RescueCount := aSection.LineNumericDefault['save_requirement', RescueCount];
    HandleTimeLimit(aSection.LineTrimString['time_limit']);
    SpawnInterval := 53 - (aSection.LineNumeric['release_rate'] div 2);
    if aSection.Line['max_spawn_interval'] <> nil then
      SpawnInterval := aSection.LineNumeric['max_spawn_interval'];
    SpawnIntervalLocked := (aSection.Line['spawn_interval_locked'] <> nil) or (aSection.Line['release_rate_locked'] <> nil);

    HandleSuperLemming(aSection.LineTrimString['superlemming']);

    Width := aSection.LineNumeric['width'];
    Height := aSection.LineNumeric['height'];

    ScreenStartAuto := (aSection.Line['start_x'] = nil) or (aSection.Line['start_y'] = nil);
    ScreenStartX := aSection.LineNumeric['start_x'];
    ScreenStartY := aSection.LineNumeric['start_y'];

    Background := CombineIdentifier(PieceManager.Dealias(aSection.LineTrimString['background'], rkBackground).Piece);
    LoadBackground := aSection.LineTrimString['background'];

    if (Background <> '') and (Background <> ':') then
    begin
      Ident := SplitIdentifier(Background);
      if not FileExists(AppPath + SFStyles + Ident.GS + '\backgrounds\' + Ident.Piece + '.png') then
      begin
        PieceManager.NeedCheckStyles.Add(Ident.GS);
        Background := 'default:fallback';
      end;
    end;
  end;
end;

procedure TLevel.LoadSkillsetSection(aSection: TParserSection);
  procedure HandleSkill(aLabel: String; aFlag: TSkillPanelButton);
  var
    Line: TParserLine;
    Count: Integer;
  begin
    Line := aSection.Line[aLabel];
    if Line = nil then Exit;
    if Lowercase(Line.ValueTrimmed) = 'infinite' then
      Count := 100
    else
      Count := Line.ValueNumeric;
    Info.Skillset := Info.Skillset + [aFlag];
    Info.SkillCount[aFlag] := Count;
  end;
begin
  Info.Skillset := [];
  if aSection = nil then Exit;

  HandleSkill('walker', spbWalker);
  HandleSkill('jumper', spbJumper);
  HandleSkill('shimmier', spbShimmier);
  HandleSkill('slider', spbSlider);
  HandleSkill('climber', spbClimber);
  HandleSkill('swimmer', spbSwimmer);
  HandleSkill('floater', spbFloater);
  HandleSkill('glider', spbGlider);
  HandleSkill('disarmer', spbDisarmer);
  HandleSkill('timebomber', spbTimebomber);
  HandleSkill('bomber', spbBomber);
  HandleSkill('freezer', spbFreezer);
  HandleSkill('blocker', spbBlocker);
  HandleSkill('platformer', spbPlatformer);
  HandleSkill('builder', spbBuilder);
  HandleSkill('stacker', spbStacker);
  HandleSkill('spearer', spbSpearer);
  HandleSkill('grenader', spbGrenader);
  HandleSkill('laserer', spbLaserer);
  HandleSkill('basher', spbBasher);
  HandleSkill('fencer', spbFencer);
  HandleSkill('miner', spbMiner);
  HandleSkill('digger', spbDigger);
  HandleSkill('cloner', spbCloner);
end;

procedure TLevel.HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
var
  O: TGadgetModel;

  procedure Flag(aValue: Integer);
  begin
    O.DrawingFlags := O.DrawingFlags or aValue;
  end;

  procedure GetExitData;
  begin
    O.LemmingCap := aSection.LineNumeric['lemmings'];
  end;

  procedure GetTeleporterData;
  begin
    if (aSection.Line['flip_lemming'] <> nil) then Flag(odf_FlipLem); // Deprecated!

    O.Skill := aSection.LineNumeric['pairing'];
  end;

  procedure GetReceiverData;
  begin
    O.Skill := aSection.LineNumeric['pairing'];
  end;

  procedure GetPickupData;
  var
    S: String;
  begin
    S := Lowercase(aSection.LineTrimString['skill']);

    if S = 'walker' then O.Skill := Integer(spbWalker);
    if S = 'jumper' then O.Skill := Integer(spbJumper);    
    if S = 'shimmier' then O.Skill := Integer(spbShimmier);
    if S = 'slider' then O.Skill := Integer(spbSlider);
    if S = 'climber' then O.Skill := Integer(spbClimber);
    if S = 'swimmer' then O.Skill := Integer(spbSwimmer);
    if S = 'floater' then O.Skill := Integer(spbFloater);
    if S = 'glider' then O.Skill := Integer(spbGlider);
    if S = 'disarmer' then O.Skill := Integer(spbDisarmer);
    if S = 'timebomber' then O.Skill := Integer(spbTimebomber);
    if S = 'bomber' then O.Skill := Integer(spbBomber);
    if S = 'freezer' then O.Skill := Integer(spbFreezer);
    if S = 'blocker' then O.Skill := Integer(spbBlocker);
    if S = 'platformer' then O.Skill := Integer(spbPlatformer);
    if S = 'builder' then O.Skill := Integer(spbBuilder);
    if S = 'stacker' then O.Skill := Integer(spbStacker);
    if S = 'spearer' then O.Skill := Integer(spbSpearer);
    if S = 'grenader' then O.Skill := Integer(spbGrenader);
    if S = 'laserer' then O.Skill := Integer(spbLaserer);
    if S = 'basher' then O.Skill := Integer(spbBasher);
    if S = 'fencer' then O.Skill := Integer(spbFencer);
    if S = 'miner' then O.Skill := Integer(spbMiner);
    if S = 'digger' then O.Skill := Integer(spbDigger);
    if S = 'cloner' then O.Skill := Integer(spbCloner);

    if aSection.Line['skill_count'] = nil then
      O.TarLev := Max(aSection.LineNumeric['skillcount'], 1)
    else
      O.TarLev := Max(aSection.LineNumeric['skill_count'], 1);
  end;

  procedure GetSplitterData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then
      Flag(odf_FlipLem)
    else if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'r' then
      O.DrawingFlags := O.DrawingFlags and not odf_FlipLem;
  end;

  procedure GetWindowData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then Flag(odf_FlipLem); // Deprecated!!
    if (aSection.Line['slider'] <> nil) then O.TarLev := O.TarLev or 256;
    if (aSection.Line['climber'] <> nil) then O.TarLev := O.TarLev or 1;
    if (aSection.Line['swimmer'] <> nil) then O.TarLev := O.TarLev or 2;
    if (aSection.Line['floater'] <> nil) then O.TarLev := O.TarLev or 4;
    if (aSection.Line['glider'] <> nil) then O.TarLev := O.TarLev or 8;
    if (aSection.Line['disarmer'] <> nil) then O.TarLev := O.TarLev or 16;
    if (aSection.Line['zombie'] <> nil) then O.TarLev := O.TarLev or 64;
    if (aSection.Line['neutral'] <> nil) then O.TarLev := O.TarLev or 128;

    O.LemmingCap := aSection.LineNumeric['lemmings'];
  end;

  procedure GetMovingBackgroundData;
  var
    Angle: Integer;
  begin
    Angle := aSection.LineNumeric['angle'];
    O.Skill := (Round(Angle / 22.5) mod 16 + 16) mod 16; // Convert angle in degrees to a mod 16 segment
    O.TarLev := aSection.LineNumeric['speed'];
  end;

var
  MO: TGadgetMetaInfo;
  DealiasInfo: TDealiasResult;
const
  NO_FLIP_HORIZONTAL_TYPES = [DOM_PICKUP];
  NO_FLIP_VERTICAL_TYPES = [DOM_WINDOW, DOM_PICKUP, DOM_UPDRAFT];
  NO_ROTATE_TYPES = [DOM_WINDOW, DOM_FORCELEFT, DOM_FORCERIGHT, DOM_PICKUP, DOM_UPDRAFT, DOM_FLIPPER];
begin
  O := fInteractiveObjects.Add;

  if aSection.Line['style'] = nil then
    O.GS := aSection.LineTrimString['collection']
  else
    O.GS := aSection.LineTrimString['style'];

  O.Piece := aSection.LineTrimString['piece'];

  O.LoadIdentifier := O.Identifier;

  DealiasInfo := PieceManager.Dealias(O.Identifier, rkGadget);
  O.GS := DealiasInfo.Piece.GS;
  O.Piece := DealiasInfo.Piece.Piece;

  MO := PieceManager.Objects[O.Identifier];
  if MO = nil then
  begin
    PieceManager.NeedCheckStyles.Add(O.GS);
    O.GS := 'default';
    O.Piece := 'fallback';
    MO := PieceManager.Objects[O.Identifier];
  end;

  O.Left := aSection.LineNumeric['x'];
  O.Top := aSection.LineNumeric['y'];
  O.Width := aSection.LineNumeric['width'];
  O.Height := aSection.LineNumeric['height'];

  if O.Width = 0 then O.Width := DealiasInfo.DefWidth;
  if O.Height = 0 then O.Height := DealiasInfo.DefHeight;

  O.DrawingFlags := 0;
  if (aSection.Line['rotate'] <> nil) then Flag(odf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(odf_FlipLem);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(odf_UpsideDown);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(odf_NoOverwrite);
  if (aSection.Line['only_on_terrain'] <> nil) then Flag(odf_OnlyOnTerrain);

  case MO.TriggerEffect of
    DOM_TELEPORT: GetTeleporterData;
    DOM_RECEIVER: GetReceiverData;
    DOM_PICKUP: GetPickupData;
    DOM_FLIPPER: GetSplitterData;
    DOM_WINDOW: GetWindowData;
    DOM_BACKGROUND: GetMovingBackgroundData;
    DOM_EXIT, DOM_LOCKEXIT: GetExitData;
  end;

  if MO.TriggerEffect in NO_FLIP_HORIZONTAL_TYPES then O.DrawingFlags := O.DrawingFlags and not odf_FlipLem;
  if MO.TriggerEffect in NO_FLIP_VERTICAL_TYPES then O.DrawingFlags := O.DrawingFlags and not odf_UpsideDown;
  if MO.TriggerEffect in NO_ROTATE_TYPES then O.DrawingFlags := O.DrawingFlags and not odf_Rotate;
end;

procedure TLevel.HandleTerrainGroupEntry(aSection: TParserSection; const aIteration: Integer);
var
  G: TTerrainGroup;
begin
  G := TTerrainGroup.Create;
  G.Name := aSection.LineString['name'];
  aSection.DoForEachSection('terrain',
    procedure (aSec: TParserSection; const aIter: Integer)
    var
      T: TTerrain;
    begin
      T := G.Terrains.Add;
      T.LoadFromSection(aSec);
    end
  );
  fTerrainGroups.Add(G);
end;

procedure TLevel.HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTerrain;
begin
  T := fTerrains.Add;
  T.LoadFromSection(aSection);
end;

procedure TLevel.HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
var
  L: TPreplacedLemming;
begin
  L := fPreplacedLemmings.Add;

  L.X := aSection.LineNumeric['x'];
  L.Y := aSection.LineNumeric['y'];

  if (aSection.Line['flip_horizontal'] <> nil) then
    L.Dx := -1
  else if Lowercase(LeftStr(aSection.LineTrimString['direction'], 1)) = 'l' then
    L.Dx := -1
  else
    L.Dx := 1; // We use right as a "default", but we're also lenient - we accept just an L rather than the full word "left".
               // Side effects may include a left-facing lemming if user manually enters "DIRECTION LEMMING FACES IS RIGHT".

  L.IsShimmier := (aSection.Line['shimmier'] <> nil);
  L.IsSlider   := (aSection.Line['slider'] <> nil);
  L.IsClimber  := (aSection.Line['climber']  <> nil);
  L.IsSwimmer  := (aSection.Line['swimmer']  <> nil);
  L.IsFloater  := (aSection.Line['floater']  <> nil);
  L.IsGlider   := (aSection.Line['glider']   <> nil);
  L.IsDisarmer := (aSection.Line['disarmer'] <> nil);
  L.IsZombie   := (aSection.Line['zombie']   <> nil);
  L.IsNeutral  := (aSection.Line['neutral']  <> nil);
  L.IsBlocker  := (aSection.Line['blocker']  <> nil);
end;

procedure TLevel.HandleTalismanEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTalisman;
  Success: Boolean;
begin
  Success := True;
  T := TTalisman.Create;
  try
    T.LoadFromSection(aSection);
  except
    ShowMessage('Error loading a talisman for ' + Info.Title);
    Success := False;
    T.Free;
  end;
  if Success then fTalismans.Add(T);
end;

procedure TLevel.LoadPretextLine(aLine: TParserLine; const aIteration: Integer);
begin
  fPreText.Add(aLine.ValueTrimmed);
end;

procedure TLevel.LoadPosttextLine(aLine: TParserLine; const aIteration: Integer);
begin
  fPostText.Add(aLine.ValueTrimmed);
end;

procedure TLevel.Sanitize;
var
  SkillIndex: TSkillPanelButton;
  SkillNumber: Integer;
begin
  with Info do
  begin
    Title := Trim(Title);
    Author := Trim(Author);

    if Width < 1 then Width := 1;
    if Height < 1 then Height := 1;

    if ScreenStartX < 0 then ScreenStartX := 0;
    if ScreenStartX > Width-1 then ScreenStartX := Width-1;

    if ScreenStartY < 0 then ScreenStartY := 0;
    if ScreenStartY > Height-1 then ScreenStartY := Height-1;

    if LemmingsCount < PreplacedLemmings.Count then LemmingsCount := PreplacedLemmings.Count;
    if RescueCount < 0 then RescueCount := 0;

    if TimeLimit < 1 then TimeLimit := 1;
    if TimeLimit > 5999 then TimeLimit := 5999;

    //if SuperLemming = true then GameSpeed := gspSuperLemming;

    if SpawnInterval < ReleaseRateToSpawnInterval(99) then SpawnInterval := ReleaseRateToSpawnInterval(99);
    if SpawnInterval > ReleaseRateToSpawnInterval(1) then SpawnInterval := ReleaseRateToSpawnInterval(1);

    SkillNumber := 0;
    for SkillIndex := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    begin
      if SkillCount[SkillIndex] < 0 then SkillCount[SkillIndex] := 0;
      if SkillCount[SkillIndex] > 100 then SkillCount[SkillIndex] := 100;
      if SkillIndex in Skillset then Inc(SkillNumber);

      if (SkillNumber > MAX_SKILL_TYPES_PER_LEVEL) or not (SkillIndex in Skillset) then
      begin
        SkillCount[SkillIndex] := 0;
        Exclude(fSkillset, SkillIndex);
      end
    end;

  end;

  PrepareForUse;
end;

procedure TLevel.PrepareForUse;
var
  i: Integer;
  S: TSkillPanelButton;
  FoundSkill: Boolean;

  WindowLemmingCount: array of Integer;
  FoundWindow: Boolean;
  n: Integer;
  SpawnedCount: Integer;
  MaxPossibleLemmingCount, MaxPossibleExitCount: Integer;

  TriggerEffect: Integer;

  procedure SetNextWindow;
  var
    initial: Integer;
  begin
    initial := n;
    if initial = -1 then
      initial := InteractiveObjects.Count-1;
    repeat
      Inc(n);
      if n >= InteractiveObjects.Count then n := 0;
      if (n = initial) and (WindowLemmingCount[n] = 0) then
      begin
        n := -1;
        Exit;
      end;
    until WindowLemmingCount[n] <> 0;
  end;
begin
  for i := 0 to InteractiveObjects.Count-1 do
    if InteractiveObjects[i].Identifier = 'default:fallback' then
      Exit; // safer not to do this with fallbacks in play

  // 1. Validate skillset - remove skills that don't exist in the level, and forbid infinite cloners
  for S := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    if not (S in Info.Skillset) then Continue;
    if Info.SkillCount[S] > 0 then Continue;
    FoundSkill := false;
    for i := 0 to InteractiveObjects.Count-1 do
    begin
      if PieceManager.Objects[InteractiveObjects[i].Identifier].TriggerEffect <> DOM_PICKUP then Continue;
      if InteractiveObjects[i].Skill <> Integer(S) then Continue;
      FoundSkill := true;
      Break;
    end;
    if not FoundSkill then Info.Skillset := Info.Skillset - [S];
  end;

  if Info.SkillCount[spbCloner] > 99 then Info.SkillCount[spbCloner] := 99;
  

  // 2. Calculate ZombieCount and NeutralCount, precise spawn order, and finalised lemming count
  FoundWindow := false;
  SetLength(WindowLemmingCount, InteractiveObjects.Count);
  for i := 0 to InteractiveObjects.Count-1 do
    if (PieceManager.Objects[InteractiveObjects[i].Identifier].TriggerEffect = DOM_WINDOW) then
    begin
      FoundWindow := true;
      if InteractiveObjects[i].LemmingCap > 0 then
        WindowLemmingCount[i] := InteractiveObjects[i].LemmingCap
      else
        WindowLemmingCount[i] := -1;
    end else
      WindowLemmingCount[i] := 0;

  Info.ZombieCount := 0;
  Info.NeutralCount := 0;

  for i := 0 to PreplacedLemmings.Count-1 do
    if PreplacedLemmings[i].IsZombie then
      Info.ZombieCount := Info.ZombieCount + 1
    else if PreplacedLemmings[i].IsNeutral then
      Info.NeutralCount := Info.NeutralCount + 1;

  if not FoundWindow then
  begin
    Info.LemmingsCount := PreplacedLemmings.Count;
    SetLength(Info.SpawnOrder, 0);
  end else begin
    n := -1;
    SetLength(Info.SpawnOrder, Info.LemmingsCount - PreplacedLemmings.Count);

    SpawnedCount := PreplacedLemmings.Count;

    for i := 0 to Length(Info.SpawnOrder)-1 do
    begin
      SetNextWindow;

      if (n = -1) then
      begin
        Info.LemmingsCount := SpawnedCount; // remember - this already includes preplaced lemmings
        Break;
      end;

      if (InteractiveObjects[n].TarLev and 64) <> 0 then
        Info.ZombieCount := Info.ZombieCount + 1
      else if (InteractiveObjects[n].TarLev and 128) <> 0 then
        Info.NeutralCount := Info.NeutralCount + 1;
      Info.SpawnOrder[i] := n;

      if WindowLemmingCount[n] > 0 then
        Dec(WindowLemmingCount[n]);

      Inc(SpawnedCount);
    end;

    SetLength(Info.SpawnOrder, Info.LemmingsCount - PreplacedLemmings.Count); // in case this got overridden
  end;

  // 3. Validate save requirement and lower it if need be. It must:
  //  - Not exceed the lemming count + cloner count (including neutrals but excluding zombies, of course)
  //  - Not exceed the total number of lemmings permitted to enter the level's exits
  MaxPossibleLemmingCount := Info.LemmingsCount + Info.SkillCount[spbCloner] - Info.ZombieCount;
  MaxPossibleExitCount := 0;

  for i := 0 to InteractiveObjects.Count-1 do
  begin
    TriggerEffect := PieceManager.Objects[InteractiveObjects[i].Identifier].TriggerEffect;

    if TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT] then
    begin
      if (InteractiveObjects[i].LemmingCap > 0) and (MaxPossibleExitCount >= 0) then
        MaxPossibleExitCount := MaxPossibleExitCount + InteractiveObjects[i].LemmingCap
      else
        MaxPossibleExitCount := -1;
    end;

    if (TriggerEffect = DOM_PICKUP) and (InteractiveObjects[i].Skill = Integer(spbCloner)) then
      Inc(MaxPossibleLemmingCount, InteractiveObjects[i].TarLev);
  end;

  if Info.RescueCount > MaxPossibleLemmingCount then
    Info.RescueCount := MaxPossibleLemmingCount;

  if (MaxPossibleExitCount >= 0) and (Info.RescueCount > MaxPossibleExitCount) then
    Info.RescueCount := MaxPossibleExitCount;

  // 4. Sanitize and make requirement text for talismans
  for i := 0 to fTalismans.Count-1 do
    SanitizeTalismanAndSetText(fTalismans[i]);

  fTalismans.Sort(TComparer<TTalisman>.Construct(
     function(const L, R: TTalisman): Integer
     begin
       if L.Color < R.Color then
         Result := -1
       else if L.Color > R.Color then
         Result := 1
       else if L.Title <> R.Title then
         Result := CompareStr(L.Title, R.Title)
       else
         Result := CompareStr(L.RequirementText, R.RequirementText);
     end
    ));
end;

// TLevel Saving Routines

procedure TLevel.SaveToStream(aStream: TStream);
var
  Parser: TParser;
begin
  Parser := TParser.Create;
  try
    Parser.MainSection.AddLine('#', 'Level cleansed using SuperLemmix V' + CurrentVersionString + ':' + COMMIT_ID);
    if HasAnyFallbacks then
      Parser.MainSection.AddLine('#', 'SOME PIECES WERE NOT FOUND');

    Parser.MainSection.AddLine('');

    SaveGeneralInfo(Parser.MainSection);
    SaveSkillsetSection(Parser.MainSection);
    SaveObjectSections(Parser.MainSection);
    SaveTerrainGroupSections(Parser.MainSection);
    SaveTerrainSections(Parser.MainSection);
    SaveLemmingSections(Parser.MainSection);
    SaveTalismanSections(Parser.MainSection);
    SaveTextSections(Parser.MainSection);
    Parser.SaveToStream(aStream);
  finally
    Parser.Free;
  end;
end;

procedure TLevel.SaveGeneralInfo(aSection: TParserSection);
begin
  with Info do
  begin
    aSection.AddLine('TITLE', Title);
    aSection.AddLine('AUTHOR', Author);
    if (GraphicSetName = 'default') then
    begin
      aSection.AddLine('THEME', LoadGraphicSetName);
      aSection.AddLine('#', 'Theme not found');
    end else
      aSection.AddLine('THEME', GraphicSetName);
    aSection.AddLine('MUSIC', MusicFile);
    aSection.AddLine('ID', 'x' + IntToHex(LevelID, 16));
    aSection.AddLine('VERSION', LevelVersion);

    aSection.AddLine('LEMMINGS', LemmingsCount);
    aSection.AddLine('SAVE_REQUIREMENT', RescueCount);

    if HasTimeLimit then
      aSection.AddLine('TIME_LIMIT', TimeLimit);

    if SuperLemming then
      aSection.AddLine('SUPERLEMMING');

    aSection.AddLine('MAX_SPAWN_INTERVAL', SpawnInterval);
    if SpawnIntervalLocked then
      aSection.AddLine('SPAWN_INTERVAL_LOCKED');

    aSection.AddLine('WIDTH', Width);
    aSection.AddLine('HEIGHT', Height);

    if not ScreenStartAuto then
    begin
      aSection.AddLine('START_X', ScreenStartX);
      aSection.AddLine('START_Y', ScreenStartY);
    end;

    if Background = 'default:fallback' then
    begin
      aSection.AddLine('BACKGROUND', LoadBackground);
      aSection.AddLine('#', 'Background not found');
    end else if not ((Background = '') or (Background = ':')) then
      aSection.AddLine('BACKGROUND', Background);
  end;
end;

procedure TLevel.SaveSkillsetSection(aSection: TParserSection);
var
  Sec: TParserSection;

  procedure HandleSkill(aLabel: String; aFlag: TSkillPanelButton);
  begin
    if not (aFlag in Info.Skillset) then Exit;
    if Info.SkillCount[aFlag] > 99 then
      Sec.AddLine(aLabel, 'infinite')
    else
      Sec.AddLine(aLabel, Info.SkillCount[aFlag]);
  end;
begin
  if Info.Skillset = [] then Exit;
  Sec := aSection.SectionList.Add('SKILLSET');

  HandleSkill('WALKER', spbWalker);
  HandleSkill('JUMPER', spbJumper);
  HandleSkill('SHIMMIER', spbShimmier);
  HandleSkill('SLIDER', spbSlider);
  HandleSkill('CLIMBER', spbClimber);
  HandleSkill('SWIMMER', spbSwimmer);
  HandleSkill('FLOATER', spbFloater);
  HandleSkill('GLIDER', spbGlider);
  HandleSkill('DISARMER', spbDisarmer);
  HandleSkill('TIMEBOMBER', spbTimebomber);
  HandleSkill('BOMBER', spbBomber);
  HandleSkill('Freezer', spbFreezer);
  HandleSkill('BLOCKER', spbBlocker);
  HandleSkill('PLATFORMER', spbPlatformer);
  HandleSkill('BUILDER', spbBuilder);
  HandleSkill('STACKER', spbStacker);
  HandleSkill('SPEARER', spbSpearer);
  HandleSkill('GRENADER', spbGrenader);
  HandleSkill('LASERER', spbLaserer);
  HandleSkill('BASHER', spbBasher);
  HandleSkill('FENCER', spbFencer);
  HandleSkill('MINER', spbMiner);
  HandleSkill('DIGGER', spbDigger);
  HandleSkill('CLONER', spbCloner);
end;

procedure TLevel.SaveObjectSections(aSection: TParserSection);
var
  i: Integer;
  O: TGadgetModel;
  Sec: TParserSection;
  LocalIdentifier: TLabelRecord;

  function Flag(aValue: Integer): Boolean;
  begin
    Result := O.DrawingFlags and aValue = aValue;
  end;

  procedure SetTeleporterData;
  begin
    Sec.AddLine('PAIRING', O.Skill);
  end;

  procedure SetReceiverData;
  begin
    Sec.AddLine('PAIRING', O.Skill);
  end;

  procedure SetPickupData;
  var
    S: String;
  begin
    case TSkillPanelButton(O.Skill) of
     spbWalker: s := 'WALKER';
     spbJumper: s := 'JUMPER';
     spbShimmier: s := 'SHIMMIER';
     spbSlider: s := 'SLIDER';
     spbClimber: s := 'CLIMBER';
     spbSwimmer: s := 'SWIMMER';
     spbFloater: s := 'FLOATER';
     spbGlider: s := 'GLIDER';
     spbDisarmer: s := 'DISARMER';
     spbTimebomber: s := 'TIMEBOMBER';
     spbBomber: s := 'BOMBER';
     spbFreezer: s := 'Freezer';
     spbBlocker: s := 'BLOCKER';
     spbPlatformer: s := 'PLATFORMER';
     spbBuilder: s := 'BUILDER';
     spbStacker: s := 'STACKER';
     spbSpearer: s := 'SPEARER';
     spbGrenader: s := 'GRENADER';
     spbLaserer: s := 'LASERER';
     spbBasher: s := 'BASHER';
     spbFencer: s := 'FENCER';     
     spbMiner: s := 'MINER';
     spbDigger: s := 'DIGGER';
     spbCloner: s := 'CLONER';
    end;

    Sec.AddLine('SKILL', S);
    if O.TarLev > 1 then
      Sec.AddLine('SKILL_COUNT', O.TarLev);
  end;

  procedure SetWindowData;
  begin
    if O.TarLev and 256 <> 0 then Sec.AddLine('SLIDER');
    if O.TarLev and 1 <> 0 then Sec.AddLine('CLIMBER');
    if O.TarLev and 2 <> 0 then Sec.AddLine('SWIMMER');
    if O.TarLev and 4 <> 0 then Sec.AddLine('FLOATER');
    if O.TarLev and 8 <> 0 then Sec.AddLine('GLIDER');
    if O.TarLev and 16 <> 0 then Sec.AddLine('DISARMER');
    if O.TarLev and 64 <> 0 then Sec.AddLine('ZOMBIE');
    if O.TarLev and 128 <> 0 then Sec.AddLine('NEUTRAL');

    if O.LemmingCap > 0 then
      Sec.AddLine('LEMMINGS', O.LemmingCap);
  end;

  procedure SetExitData;
  begin
    if O.LemmingCap > 0 then
      Sec.AddLine('LEMMINGS', O.LemmingCap);
  end;

  procedure SetMovingBackgroundData;
  var
    Angle: Integer;
  begin
    Angle := (O.Skill * 225) div 10;

    Sec.AddLine('ANGLE', Angle);
    Sec.AddLine('SPEED', O.TarLev);
  end;
begin
  for i := 0 to fInteractiveObjects.Count-1 do
  begin
    O := fInteractiveObjects[i];
    Sec := aSection.SectionList.Add('GADGET');

    if O.Identifier = 'default:fallback' then
    begin
      LocalIdentifier := SplitIdentifier(O.LoadIdentifier);
      Sec.AddLine('STYLE', LocalIdentifier.GS);
      Sec.AddLine('PIECE', LocalIdentifier.Piece);
      Sec.AddLine('#', 'Gadget not found');
    end else begin
      Sec.AddLine('STYLE', O.GS);
      Sec.AddLine('PIECE', O.Piece);
    end;
    Sec.AddLine('X', O.Left);
    Sec.AddLine('Y', O.Top);
    if O.Width > 0 then Sec.AddLine('WIDTH', O.Width);
    if O.Height > 0 then Sec.AddLine('HEIGHT', O.Height);

    if Flag(odf_Rotate) then Sec.AddLine('ROTATE');
    if Flag(odf_FlipLem) then Sec.AddLine('FLIP_HORIZONTAL');
    if Flag(odf_UpsideDown) then Sec.AddLine('FLIP_VERTICAL');
    if Flag(odf_NoOverwrite) then Sec.AddLine('NO_OVERWRITE');
    if Flag(odf_OnlyOnTerrain) then Sec.AddLine('ONLY_ON_TERRAIN');

    if O.Identifier = 'default:fallback' then
    begin
      // Just have to save everything and hope for the best.
      SetTeleporterData;
      SetPickupData;
      SetWindowData;
      SetMovingBackgroundData;
      // Receiver and Exit's data are covered by Teleporter and Window respectively.
    end else begin
      case PieceManager.Objects[O.Identifier].TriggerEffect of
        DOM_EXIT, DOM_LOCKEXIT: SetExitData;
        DOM_TELEPORT: SetTeleporterData;
        DOM_RECEIVER: SetReceiverData;
        DOM_PICKUP: SetPickupData;
        DOM_WINDOW: SetWindowData;
        DOM_BACKGROUND: SetMovingBackgroundData;
      end;
    end;
  end;
end;

procedure TLevel.SaveTerrainGroupSections(aSection: TParserSection);
var
  G: TTerrainGroup;
  T: TTerrain;
  i, n: Integer;
  Sec, SubSec: TParserSection;
begin
  for i := 0 to fTerrainGroups.Count-1 do
  begin
    G := fTerrainGroups[i];
    Sec := aSection.SectionList.Add('TERRAINGROUP');

    Sec.AddLine('NAME', G.Name);
    for n := 0 to G.Terrains.Count-1 do
    begin
      T := G.Terrains[n];
      SubSec := Sec.SectionList.Add('TERRAIN');
      T.SaveToSection(SubSec);
    end;
  end;
end;

procedure TLevel.SaveTerrainSections(aSection: TParserSection);
var
  i: Integer;
  T: TTerrain;
  Sec: TParserSection;
begin
  for i := 0 to fTerrains.Count-1 do
  begin
    T := fTerrains[i];
    Sec := aSection.SectionList.Add('TERRAIN');
    T.SaveToSection(Sec);
  end;
end;

procedure TLevel.SaveLemmingSections(aSection: TParserSection);
var
  i: Integer;
  L: TPreplacedLemming;
  Sec: TParserSection;
begin
  for i := 0 to fPreplacedLemmings.Count-1 do
  begin
    L := fPreplacedLemmings[i];
    Sec := aSection.SectionList.Add('LEMMING');

    Sec.AddLine('X', L.X);
    Sec.AddLine('Y', L.Y);

    if L.Dx < 0 then
      Sec.AddLine('FLIP_HORIZONTAL');

    if L.IsShimmier then Sec.AddLine('SHIMMIER');
    if L.IsSlider then Sec.AddLine('SLIDER');
    if L.IsClimber then Sec.AddLine('CLIMBER');
    if L.IsSwimmer then Sec.AddLine('SWIMMER');
    if L.IsFloater then Sec.AddLine('FLOATER');
    if L.IsGlider then Sec.AddLine('GLIDER');
    if L.IsDisarmer then Sec.AddLine('DISARMER');
    if L.IsBlocker then Sec.AddLine('BLOCKER');
    if L.IsZombie then Sec.AddLine('ZOMBIE');
    if L.IsNeutral then Sec.AddLine('NEUTRAL');
  end;
end;

procedure TLevel.SaveTalismanSections(aSection: TParserSection);
var
  i: Integer;
  Sec: TParserSection;
begin
  for i := 0 to fTalismans.Count-1 do
  begin
    Sec := TParserSection.Create('talisman');
    aSection.SectionList.Add(Sec);
    fTalismans[i].SaveToSection(Sec);
  end;
end;

procedure TLevel.SaveTextSections(aSection: TParserSection);

  procedure WriteTexts(aSL: TStringList; aKeyword: String);
  var
    NewSec: TParserSection;
    i: Integer;
  begin
    if aSL.Count = 0 then Exit;
    NewSec := TParserSection.Create(aKeyword);
    for i := 0 to aSL.Count-1 do
      NewSec.AddLine('line', aSL[i]);
    aSection.SectionList.Add(NewSec);
  end;
begin
  WriteTexts(fPreText, 'pretext');
  WriteTexts(fPostText, 'posttext');
end;

end.

