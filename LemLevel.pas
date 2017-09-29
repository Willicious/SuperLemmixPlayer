{$include lem_directives.inc}
unit LemLevel;

interface

uses
  System.Generics.Collections,
  Classes, SysUtils, StrUtils,
  LemCore, LemLemming,
  LemTalisman,
  LemTerrain, LemGadgetsModel, LemGadgets,
  LemNeoPieceManager, LemNeoParser;

type
  TSkillset = set of TSkillPanelButton;
  TSkillCounts = array[Low(TSkillPanelButton)..High(TSkillPanelButton)] of Integer; // non-skill buttons are just unused

  TLevelInfo = class
  private
  protected
    fSpawnIntervalLocked : Boolean;
    fSpawnInterval  : Integer;
    fLemmingsCount  : Integer;
    fZombieCount    : Integer;
    fRescueCount    : Integer;
    fHasTimeLimit   : Boolean;
    fTimeLimit      : Integer;

    fSkillset: TSkillset;
    fSkillCounts: TSkillCounts;

    fWidth : Integer;
    fHeight : Integer;

    fBackground: String;

    fIsSimpleAutoSteel: Boolean;

    fScreenPosition : Integer;
    fScreenYPosition: Integer;
    fTitle          : string;
    fAuthor         : string;

    fGraphicSetName : string;
    fMusicFile      : string;

    fLevelID        : Int64;

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
    property RescueCount    : Integer read fRescueCount write fRescueCount;
    property HasTimeLimit   : Boolean read fHasTimeLimit write fHasTimeLimit;
    property TimeLimit      : Integer read fTimeLimit write fTimeLimit;

    property Skillset: TSkillset read fSkillset write fSkillset;
    property SkillCount[Index: TSkillPanelButton]: Integer read GetSkillCount write SetSkillCount;

    property ScreenPosition : Integer read fScreenPosition write fScreenPosition;
    property ScreenYPosition : Integer read fScreenYPosition write fScreenYPosition;
    property Title          : string read fTitle write fTitle;
    property Author         : string read fAuthor write fAuthor;

    property IsSimpleAutoSteel: Boolean read fIsSimpleAutoSteel write fIsSimpleAutoSteel;

    property Width          : Integer read fWidth write fWidth;
    property Height         : Integer read fHeight write fHeight;

    property GraphicSetName : String read fGraphicSetName write fGraphicSetName;
    property MusicFile      : String read fMusicFile write fMusicFile;

    property Background: String read fBackground write fBackground;

    property LevelID: Int64 read fLevelID write fLevelID;
  end;

  TLevel = class
  private
    fLevelInfo       : TLevelInfo;
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
    procedure HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTalismanEntry(aSection: TParserSection; const aIteration: Integer);
    procedure LoadPretextLine(aLine: TParserLine; const aIteration: Integer);
    procedure LoadPosttextLine(aLine: TParserLine; const aIteration: Integer);

    // Saving routines
    procedure SaveGeneralInfo(aSection: TParserSection);
    procedure SaveSkillsetSection(aSection: TParserSection);
    procedure SaveObjectSections(aSection: TParserSection);
    procedure SaveTerrainSections(aSection: TParserSection);
    procedure SaveLemmingSections(aSection: TParserSection);
    procedure SaveTalismanSections(aSection: TParserSection);
    procedure SaveTextSections(aSection: TParserSection);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadFromFile(aFile: String);
    procedure LoadFromStream(aStream: TStream; aExt: String = '');

    procedure SaveToFile(aFile: String);
    procedure SaveToStream(aStream: TStream);

    procedure Sanitize;
    procedure PrepareForUse;
  published
    property Info: TLevelInfo read fLevelInfo;
    property InteractiveObjects: TGadgetModelList read fInteractiveObjects;
    property Terrains: TTerrains read fTerrains;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings;
    property Talismans: TObjectList<TTalisman> read fTalismans;
    property PreText: TStringList read fPreText;
    property PostText: TStringList read fPostText;
  end;

implementation

uses
  LemLVLLoader; // for backwards compatibility

{ TLevelInfo }

procedure TLevelInfo.Clear;
begin
  SpawnInterval     := 53;
  SpawnIntervalLocked := false;
  LemmingsCount   := 1;
  ZombieCount     := 0;
  RescueCount     := 1;
  HasTimeLimit    := false;
  TimeLimit       := 0;

  fSkillset       := [];
  FillChar(fSkillCounts, SizeOf(TSkillCounts), 0);

  IsSimpleAutoSteel := false;
  ScreenPosition  := 0;
  ScreenYPosition := 0;
  Width           := 320;
  Height          := 160;
  Title           := '';
  Author          := '';
  fBackground     := '';

  GraphicSetName  := '';
  MusicFile       := '';
  LevelID         := 0;
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
  fPreplacedLemmings.Free;
  fTalismans.Free;
  fPreText.Free;
  fPostText.Free;
  inherited;
end;

procedure TLevel.Clear;
begin
  fLevelInfo.Clear;
  fInteractiveObjects.Clear;
  fTerrains.Clear;
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
    LoadFromStream(F, ExtractFileExt(aFile));

    if Lowercase(ExtractFileExt(aFile)) = '.lev' then
      TLVLLoader.LoadExtraLemminsInfo(aFile, Self);
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

procedure TLevel.LoadFromStream(aStream: TStream; aExt: String = '');
var
  Parser: TParser;
  Main: TParserSection;
begin
  Clear;

  aExt := Lowercase(aExt);
  if aExt = '.lvl' then
    TLVLLoader.LoadLevelFromStream(aStream, Self, lfLemmix)
  else if aExt = '.ini' then
    TLVLLoader.LoadLevelFromStream(aStream, Self, lfLemmini)
  else if aExt = '.lev' then
    TLVLLoader.LoadLevelFromStream(aStream, Self, lfLemmins)
  else begin
    Parser := TParser.Create;
    try
      Parser.LoadFromStream(aStream);
      Main := Parser.MainSection;

      LoadGeneralInfo(Main);
      LoadSkillsetSection(Main.Section['skillset']);

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
begin
  // This procedure should receive the Parser's MAIN section
  with Info do
  begin
    Title := aSection.LineString['title'];
    Author := aSection.LineString['author'];
    GraphicSetName := aSection.LineTrimString['theme'];
    MusicFile := aSection.LineTrimString['music'];
    LevelID := aSection.LineNumeric['id'];

    LemmingsCount := aSection.LineNumeric['lemmings'];
    RescueCount := aSection.LineNumeric['requirement'];
    HandleTimeLimit(aSection.LineTrimString['time_limit']);
    SpawnInterval := 53 - (aSection.LineNumeric['release_rate'] div 2);
    if aSection.Line['max_spawn_interval'] <> nil then
      SpawnInterval := aSection.LineNumeric['max_spawn_interval'];
    SpawnIntervalLocked := (aSection.Line['spawn_interval_locked'] <> nil) or (aSection.Line['release_rate_locked'] <> nil);

    Width := aSection.LineNumeric['width'];
    Height := aSection.LineNumeric['height'];
    ScreenPosition := aSection.LineNumeric['start_x'];
    ScreenYPosition := aSection.LineNumeric['start_y'];

    if Lowercase(aSection.LineTrimString['autosteel']) = 'simple' then
      isSimpleAutoSteel := true;

    Background := aSection.LineTrimString['background'];
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
  HandleSkill('climber', spbClimber);
  HandleSkill('swimmer', spbSwimmer);
  HandleSkill('floater', spbFloater);
  HandleSkill('glider', spbGlider);
  HandleSkill('disarmer', spbDisarmer);
  HandleSkill('bomber', spbBomber);
  HandleSkill('stoner', spbStoner);
  HandleSkill('blocker', spbBlocker);
  HandleSkill('platformer', spbPlatformer);
  HandleSkill('builder', spbBuilder);
  HandleSkill('stacker', spbStacker);
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

  procedure GetTeleporterData;
  begin
    if (aSection.Line['flip_lemming'] <> nil) then Flag(odf_FlipLem);
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
    if S = 'climber' then O.Skill := Integer(spbClimber);
    if S = 'swimmer' then O.Skill := Integer(spbSwimmer);
    if S = 'floater' then O.Skill := Integer(spbFloater);
    if S = 'glider' then O.Skill := Integer(spbGlider);
    if S = 'disarmer' then O.Skill := Integer(spbDisarmer);
    if S = 'bomber' then O.Skill := Integer(spbBomber);
    if S = 'stoner' then O.Skill := Integer(spbStoner);
    if S = 'blocker' then O.Skill := Integer(spbBlocker);
    if S = 'platformer' then O.Skill := Integer(spbPlatformer);
    if S = 'builder' then O.Skill := Integer(spbBuilder);
    if S = 'stacker' then O.Skill := Integer(spbStacker);
    if S = 'basher' then O.Skill := Integer(spbBasher);
    if S = 'fencer' then O.Skill := Integer(spbFencer);
    if S = 'miner' then O.Skill := Integer(spbMiner);
    if S = 'digger' then O.Skill := Integer(spbDigger);
    if S = 'cloner' then O.Skill := Integer(spbCloner);
  end;

  procedure GetSplitterData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then
      Flag(odf_FlipLem);
  end;

  procedure GetWindowData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then Flag(odf_FlipLem);
    if (aSection.Line['climber'] <> nil) then O.TarLev := O.TarLev or 1;
    if (aSection.Line['swimmer'] <> nil) then O.TarLev := O.TarLev or 2;
    if (aSection.Line['floater'] <> nil) then O.TarLev := O.TarLev or 4;
    if (aSection.Line['glider'] <> nil) then O.TarLev := O.TarLev or 8;
    if (aSection.Line['disarmer'] <> nil) then O.TarLev := O.TarLev or 16;
    if (aSection.Line['zombie'] <> nil) then O.TarLev := O.TarLev or 64;
  end;

  procedure GetMovingBackgroundData;
  var
    Angle: Integer;
  begin
    Angle := aSection.LineNumeric['angle'];
    O.Skill := (Round(Angle / 22.5) mod 16 + 16) mod 16; // Convert angle in degrees to a mod 16 segment
    O.TarLev := aSection.LineNumeric['speed'];
  end;
begin
  O := fInteractiveObjects.Add;

  O.GS := aSection.LineTrimString['collection'];
  O.Piece := aSection.LineTrimString['piece'];
  O.Left := aSection.LineNumeric['x'];
  O.Top := aSection.LineNumeric['y'];
  O.Width := aSection.LineNumeric['width'];
  O.Height := aSection.LineNumeric['height'];

  O.DrawingFlags := 0;
  if (aSection.Line['rotate'] <> nil) then Flag(odf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(odf_Flip);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(odf_UpsideDown);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(odf_NoOverwrite);
  if (aSection.Line['only_on_terrain'] <> nil) then Flag(odf_OnlyOnTerrain);

  case PieceManager.Objects[O.Identifier].TriggerEffect of
    11: GetTeleporterData;
    12: GetReceiverData;
    14: GetPickupData;
    21: GetSplitterData;
    23: GetWindowData;
    30: GetMovingBackgroundData;
  end;
end;

procedure TLevel.HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTerrain;

  procedure Flag(aValue: Integer);
  begin
    T.DrawingFlags := T.DrawingFlags or aValue;
  end;
begin
  T := fTerrains.Add;

  T.GS := aSection.LineTrimString['collection'];
  T.Piece := aSection.LineTrimString['piece'];
  T.Left := aSection.LineNumeric['x'];
  T.Top := aSection.LineNumeric['y'];

  T.DrawingFlags := tdf_NoOneWay;
  if (aSection.Line['one_way'] <> nil) then T.DrawingFlags := 0;
  if (aSection.Line['rotate'] <> nil) then Flag(tdf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(tdf_Flip);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(tdf_Invert);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(tdf_NoOverwrite);
  if (aSection.Line['erase'] <> nil) then Flag(tdf_Erase);
end;

procedure TLevel.HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
var
  L: TPreplacedLemming;
begin
  L := fPreplacedLemmings.Add;

  L.X := aSection.LineNumeric['x'];
  L.Y := aSection.LineNumeric['y'];

  if Lowercase(LeftStr(aSection.LineTrimString['direction'], 1)) = 'l' then
    L.Dx := -1
  else
    L.Dx := 1; // We use right as a "default", but we're also lenient - we accept just an L rather than the full word "left".
               // Side effects may include a left-facing lemming if user manually enters "DIRECTION LEMMING FACES IS RIGHT".

  L.IsClimber  := (aSection.Line['climber']  <> nil);
  L.IsSwimmer  := (aSection.Line['swimmer']  <> nil);
  L.IsFloater  := (aSection.Line['floater']  <> nil);
  L.IsGlider   := (aSection.Line['glider']   <> nil);
  L.IsDisarmer := (aSection.Line['disarmer'] <> nil);
  L.IsZombie   := (aSection.Line['zombie']   <> nil);
  L.IsBlocker  := (aSection.Line['blocker']  <> nil);
end;

procedure TLevel.HandleTalismanEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTalisman;
begin
  T := TTalisman.Create;
  T.LoadFromSection(aSection);
  fTalismans.Add(T);
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
begin
  with Info do
  begin
    Title := Trim(Title);
    Author := Trim(Author);

    if Width < 1 then Width := 1;
    if Height < 1 then Height := 1;

    if ScreenPosition < 0 then ScreenPosition := 0;
    if ScreenPosition > Width-1 then ScreenPosition := Width-1;

    if ScreenYPosition < 0 then ScreenYPosition := 0;
    if ScreenYPosition > Height-1 then ScreenYPosition := Height-1;

    if LemmingsCount < PreplacedLemmings.Count then LemmingsCount := PreplacedLemmings.Count;
    if RescueCount < 0 then RescueCount := 0;

    if TimeLimit < 1 then TimeLimit := 1;
    if TimeLimit > 5999 then TimeLimit := 5999;

    if SpawnInterval < ReleaseRateToSpawnInterval(99) then SpawnInterval := ReleaseRateToSpawnInterval(99);
    if SpawnInterval > ReleaseRateToSpawnInterval(1) then SpawnInterval := ReleaseRateToSpawnInterval(1);

    for SkillIndex := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    begin
      if SkillCount[SkillIndex] < 0 then SkillCount[SkillIndex] := 0;
      if SkillCount[SkillIndex] > 100 then SkillCount[SkillIndex] := 100;
      if not(SkillIndex in Skillset) then SkillCount[SkillIndex] := 0;
    end;
  end;

  PrepareForUse;
end;

procedure TLevel.PrepareForUse;
var
  i: Integer;
  S: TSkillPanelButton;
  FoundSkill: Boolean;

  IsWindow: array of Boolean;
  FoundWindow: Boolean;
  n: Integer;

  procedure SetNextWindow;
  begin
    repeat
      Inc(n);
      if n >= InteractiveObjects.Count then n := 0;
    until IsWindow[n];
  end;
begin
  // 1. Validate skillset - remove skills that don't exist in the level
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

  // 2. Calculate ZombieCount, precise spawn order, and finalised lemming count
  FoundWindow := false;
  SetLength(IsWindow, InteractiveObjects.Count);
  for i := 0 to InteractiveObjects.Count-1 do
    if (PieceManager.Objects[InteractiveObjects[i].Identifier].TriggerEffect = DOM_WINDOW) then
    begin
      FoundWindow := true;
      IsWindow[i] := true;
    end else
      IsWindow[i] := false;

  Info.ZombieCount := 0;
  for i := 0 to PreplacedLemmings.Count-1 do
    if PreplacedLemmings[i].IsZombie then
      Info.ZombieCount := Info.ZombieCount + 1;

  if not FoundWindow then
  begin
    Info.LemmingsCount := PreplacedLemmings.Count;
    SetLength(Info.SpawnOrder, 0);
  end else begin
    n := -1;
    SetLength(Info.SpawnOrder, Info.LemmingsCount - PreplacedLemmings.Count);
    for i := 0 to Length(Info.SpawnOrder)-1 do
    begin
      SetNextWindow;
      if (InteractiveObjects[n].TarLev and 64) <> 0 then
        Info.ZombieCount := Info.ZombieCount + 1;
      Info.SpawnOrder[i] := n;
    end;
  end;
end;

// TLevel Saving Routines

procedure TLevel.SaveToStream(aStream: TStream);
var
  Parser: TParser;
begin
  Parser := TParser.Create;
  try
    SaveGeneralInfo(Parser.MainSection);
    SaveSkillsetSection(Parser.MainSection);
    SaveObjectSections(Parser.MainSection);
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
    aSection.AddLine('THEME', GraphicSetName);
    aSection.AddLine('MUSIC', MusicFile);
    aSection.AddLine('ID', 'x' + IntToHex(LevelID, 16));

    aSection.AddLine('LEMMINGS', LemmingsCount);
    aSection.AddLine('REQUIREMENT', RescueCount);

    if HasTimeLimit then
      aSection.AddLine('TIME_LIMIT', TimeLimit);

    aSection.AddLine('MAX_SPAWN_INTERVAL', SpawnInterval);
    if SpawnIntervalLocked then
      aSection.AddLine('SPAWN_INTERVAL_LOCKED');

    aSection.AddLine('WIDTH', Width);
    aSection.AddLine('HEIGHT', Height);
    aSection.AddLine('START_X', ScreenPosition);
    aSection.AddLine('START_Y', ScreenYPosition);

    if Info.IsSimpleAutoSteel then
      aSection.AddLine('AUTOSTEEL', 'simple');

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
  HandleSkill('CLIMBER', spbClimber);
  HandleSkill('SWIMMER', spbSwimmer);
  HandleSkill('FLOATER', spbFloater);
  HandleSkill('GLIDER', spbGlider);
  HandleSkill('DISARMER', spbDisarmer);
  HandleSkill('BOMBER', spbBomber);
  HandleSkill('STONER', spbStoner);
  HandleSkill('BLOCKER', spbBlocker);
  HandleSkill('PLATFORMER', spbPlatformer);
  HandleSkill('BUILDER', spbBuilder);
  HandleSkill('STACKER', spbStacker);
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

  function Flag(aValue: Integer): Boolean;
  begin
    Result := O.DrawingFlags and aValue = aValue;
  end;

  procedure SetTeleporterData;
  begin
    if Flag(odf_FlipLem) then Sec.AddLine('FLIP_LEMMING');
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
     spbClimber: s := 'CLIMBER';
     spbSwimmer: s := 'SWIMMER';
     spbFloater: s := 'FLOATER';
     spbGlider: s := 'GLIDER';
     spbDisarmer: s := 'DISARMER';
     spbBomber: s := 'BOMBER';
     spbStoner: s := 'STONER';
     spbBlocker: s := 'BLOCKER';
     spbPlatformer: s := 'PLATFORMER';
     spbBuilder: s := 'BUILDER';
     spbStacker: s := 'STACKER';
     spbBasher: s := 'BASHER';
     spbFencer: s := 'FENCER';     
     spbMiner: s := 'MINER';
     spbDigger: s := 'DIGGER';
     spbCloner: s := 'CLONER';
    end;

    Sec.AddLine('SKILL', S);
  end;

  procedure SetSplitterData;
  begin
    if Flag(odf_FlipLem) then
      Sec.AddLine('DIRECTION', 'left')
    else
      Sec.AddLine('DIRECTION', 'right');
  end;

  procedure SetWindowData;
  begin
    if Flag(odf_FlipLem) then
      Sec.AddLine('DIRECTION', 'left')
    else
      Sec.AddLine('DIRECTION', 'right');

    if O.TarLev and 1 <> 0 then Sec.AddLine('CLIMBER');
    if O.TarLev and 2 <> 0 then Sec.AddLine('SWIMMER');
    if O.TarLev and 4 <> 0 then Sec.AddLine('FLOATER');
    if O.TarLev and 8 <> 0 then Sec.AddLine('GLIDER');
    if O.TarLev and 16 <> 0 then Sec.AddLine('DISARMER');
    if O.TarLev and 64 <> 0 then Sec.AddLine('ZOMBIE');
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
    Sec := aSection.SectionList.Add('OBJECT');

    Sec.AddLine('COLLECTION', O.GS);
    Sec.AddLine('PIECE', O.Piece);
    Sec.AddLine('X', O.Left);
    Sec.AddLine('Y', O.Top);
    if O.Width > 0 then Sec.AddLine('WIDTH', O.Width);
    if O.Height > 0 then Sec.AddLine('HEIGHT', O.Height);

    if Flag(odf_Rotate) then Sec.AddLine('ROTATE');
    if Flag(odf_Flip) then Sec.AddLine('FLIP_HORIZONTAL');
    if Flag(odf_UpsideDown) then Sec.AddLine('FLIP_VERTICAL');
    if Flag(odf_NoOverwrite) then Sec.AddLine('NO_OVERWRITE');
    if Flag(odf_OnlyOnTerrain) then Sec.AddLine('ONLY_ON_TERRAIN');

    case PieceManager.Objects[O.Identifier].TriggerEffect of
      11: SetTeleporterData;
      12: SetReceiverData;
      14: SetPickupData;
      21: SetSplitterData;
      23: SetWindowData;
      30: SetMovingBackgroundData;
    end;
  end;
end;

procedure TLevel.SaveTerrainSections(aSection: TParserSection);
var
  i: Integer;
  T: TTerrain;
  Sec: TParserSection;

  function Flag(aValue: Integer): Boolean;
  begin
    Result := T.DrawingFlags and aValue = aValue;
  end;
begin
  for i := 0 to fTerrains.Count-1 do
  begin
    T := fTerrains[i];
    Sec := aSection.SectionList.Add('TERRAIN');

    Sec.AddLine('COLLECTION', T.GS);
    Sec.AddLine('PIECE', T.Piece);
    Sec.AddLine('X', T.Left);
    Sec.AddLine('Y', T.Top);

    if Flag(tdf_Rotate) then Sec.AddLine('ROTATE');
    if Flag(tdf_Flip) then Sec.AddLine('FLIP_HORIZONTAL');
    if Flag(tdf_Invert) then Sec.AddLine('FLIP_VERTICAL');
    if Flag(tdf_NoOverwrite) then Sec.AddLine('NO_OVERWRITE');
    if Flag(tdf_Erase) then Sec.AddLine('ERASE');
    if not Flag(tdf_NoOneWay) then Sec.AddLine('ONE_WAY');
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

    if L.Dx > 0 then
      Sec.AddLine('DIRECTION', 'right')
    else
      Sec.AddLine('DIRECTION', 'left');

    if L.IsClimber then Sec.AddLine('CLIMBER');
    if L.IsSwimmer then Sec.AddLine('SWIMMER');
    if L.IsFloater then Sec.AddLine('FLOATER');
    if L.IsGlider then Sec.AddLine('GLIDER');
    if L.IsDisarmer then Sec.AddLine('DISARMER');
    if L.IsZombie then Sec.AddLine('ZOMBIE');
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

