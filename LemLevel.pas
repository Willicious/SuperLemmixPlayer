{$include lem_directives.inc}
unit LemLevel;

interface

uses
  Classes, SysUtils,
  UMisc,
  LemLemming,
  LemTerrain,
  LemInteractiveObject,
  LemSteel,
  LemNeoParser;

type
  TLevelInfo = class(TPersistent)
  private
  protected
    fReleaseRateLocked : Boolean;
    fReleaseRate    : Integer;
    fLemmingsCount  : Integer;
    fZombieGhostCount: Integer;
    fRescueCount    : Integer;
    fTimeLimit      : Integer;
    fClimberCount   : Integer;
    fFloaterCount   : Integer;
    fBomberCount    : Integer;
    fBlockerCount   : Integer;
    fBuilderCount   : Integer;
    fBasherCount    : Integer;
    fMinerCount     : Integer;
    fDiggerCount    : Integer;

    fWalkerCount : Integer;
    fSwimmerCount : Integer;
    fGliderCount : Integer;
    fMechanicCount : Integer;
    fStonerCount : Integer;
    fPlatformerCount : Integer;
    fStackerCount : Integer;
    fClonerCount : Integer;

    fSkillTypes : Integer;

    fWidth : Integer;
    fHeight : Integer;

    fBackgroundIndex: Integer;

    fLevelOptions   : Cardinal;

    fScreenPosition : Integer;
    fScreenYPosition: Integer;
    fTitle          : string;
    fAuthor         : string;

    fGraphicSetName : string;
    fMusicFile      : string;

    fLevelID        : LongWord;
  protected
  public
    WindowOrder       : array of word;
    constructor Create;
    procedure Clear; virtual;
  published
    property ReleaseRate    : Integer read fReleaseRate write fReleaseRate;
    property ReleaseRateLocked: Boolean read fReleaseRateLocked write fReleaseRateLocked;
    property LemmingsCount  : Integer read fLemmingsCount write fLemmingsCount;
    property ZombieGhostCount: Integer read fZombieGhostCount write fZombieGhostCount;
    property RescueCount    : Integer read fRescueCount write fRescueCount;
    property TimeLimit      : Integer read fTimeLimit write fTimeLimit;
    property ClimberCount   : Integer read fClimberCount write fClimberCount;
    property FloaterCount   : Integer read fFloaterCount write fFloaterCount;
    property BomberCount    : Integer read fBomberCount write fBomberCount;
    property BlockerCount   : Integer read fBlockerCount write fBlockerCount;
    property BuilderCount   : Integer read fBuilderCount write fBuilderCount;
    property BasherCount    : Integer read fBasherCount write fBasherCount;
    property MinerCount     : Integer read fMinerCount write fMinerCount;
    property DiggerCount    : Integer read fDiggerCount write fDiggerCount;

    property WalkerCount    : Integer read fWalkerCount write fWalkerCount;
    property SwimmerCount    : Integer read fSwimmerCount write fSwimmerCount;
    property GliderCount    : Integer read fGliderCount write fGliderCount;
    property MechanicCount    : Integer read fMechanicCount write fMechanicCount;
    property StonerCount    : Integer read fStonerCount write fStonerCount;
    property PlatformerCount    : Integer read fPlatformerCount write fPlatformerCount;
    property StackerCount    : Integer read fStackerCount write fStackerCount;
    property ClonerCount    : Integer read fClonerCount write fClonerCount;

    property SkillTypes     : Integer read fSkillTypes write fSkillTypes;

    property ScreenPosition : Integer read fScreenPosition write fScreenPosition;
    property ScreenYPosition : Integer read fScreenYPosition write fScreenYPosition;
    property Title          : string read fTitle write fTitle;
    property Author         : string read fAuthor write fAuthor;

    property LevelOptions   : Cardinal read fLevelOptions write fLevelOptions;

    property Width          : Integer read fWidth write fWidth;
    property Height         : Integer read fHeight write fHeight;

    property GraphicSetName : String read fGraphicSetName write fGraphicSetName;
    property MusicFile      : String read fMusicFile write fMusicFile;

    property BackgroundIndex: Integer read fBackgroundIndex write fBackgroundIndex;

    property LevelID: LongWord read fLevelID write fLevelID;
  end;

  TLevel = class
  private
    fLevelInfo       : TLevelInfo;
    fTerrains           : TTerrains;
    fInteractiveObjects : TInteractiveObjects;
    fSteels             : TSteels;
    fPreplacedLemmings  : TPreplacedLemmingList;

    // Loading routines
    procedure LoadGeneralInfo(aSection: TParserSection);
    procedure LoadSpawnOrderSection(aSection: TParserSection);
      procedure HandleSpawnEntry(aLine: TParserLine; const aIteration: Integer);
    procedure LoadSkillsetSection(aSection: TParserSection);
    procedure HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleAreaEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);

    // Saving routines
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(aFile: String);
    procedure LoadFromStream(aStream: TStream);

    procedure SaveToFile(aFile: String);
    procedure SaveToStream(aStream: TStream);
  published
    property Info: TLevelInfo read fLevelInfo;
    property InteractiveObjects: TInteractiveObjects read fInteractiveObjects;
    property Terrains: TTerrains read fTerrains;
    property Steels: TSteels read fSteels;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings;
  end;

implementation

uses
  LemLVLLoader; // for backwards compatibility

{ TLevelInfo }

procedure TLevelInfo.Clear;
var
  i : Integer;
begin
  ReleaseRate    := 1;
  ReleaseRateLocked := false;
  LemmingsCount  := 1;
  RescueCount    := 1;
  TimeLimit      := 1;
  ClimberCount   := 0;
  FloaterCount   := 0;
  BomberCount    := 0;
  BlockerCount   := 0;
  BuilderCount   := 0;
  BasherCount    := 0;
  MinerCount     := 0;
  DiggerCount    := 0;
  WalkerCount    := 0;
  SwimmerCount   := 0;
  GliderCount    := 0;
  MechanicCount  := 0;
  StonerCount    := 0;
  PlatformerCount := 0;
  StackerCount   := 0;
  ClonerCount := 0;
  LevelOptions   := 0;
  ScreenPosition := 0;
  ScreenYPosition := 0;
  Width := 1584;
  Height := 160;
  Title          := '';
  Author         := '';
  fBackgroundIndex := 0;
  SetLength(WindowOrder, 0);
end;

constructor TLevelInfo.Create;
begin
  inherited Create;
  Clear;
end;

{ TLevel }

constructor TLevel.Create;
begin
  inherited;
  fLevelInfo := TLevelInfo.Create;
  fInteractiveObjects := TInteractiveObjects.Create;
  fTerrains := TTerrains.Create;
  fSteels := TSteels.Create;
  fPreplacedLemmings := TPreplacedLemmingList.Create;
end;

destructor TLevel.Destroy;
begin
  fLevelInfo.Free;
  fInteractiveObjects.Free;
  fTerrains.Free;
  fSteels.Free;
  fPreplacedLemmings.Free;
  inherited;
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

procedure TLevel.LoadFromStream(aStream: TStream);
var
  Parser: TParser;
  Main: TParserSection;
  b: Byte;
begin
  aStream.Read(b, 1);
  aStream.Position := aStream.Position - 1;

  if b < 5 then
    TLVLLoader.LoadLevelFromStream(aStream, self); 

  Parser := TParser.Create;
  try
    Parser.LoadFromStream(aStream);
    Main := Parser.MainSection;

    LoadGeneralInfo(Main);
    LoadSkillsetSection(Main.Section['skillset']);

    Main.DoForEachSection('object', HandleObjectEntry);
    Main.DoForEachSection('terrain', HandleTerrainEntry);
    Main.DoForEachSection('area', HandleAreaEntry);
  finally
    Parser.Free;
  end;
end;

procedure TLevel.LoadGeneralInfo(aSection: TParserSection);

  function GetLevelOptionsValue(aString: String): Byte;
  begin
    aString := Lowercase(aString);
    if aString = 'simple' then
      Result := $0A
    else if aString = 'off' then
      Result := $00
    else
      Result := $02;
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
    TimeLimit := aSection.LineNumeric['time_limit'];
    if TimeLimit = 0 then TimeLimit := 6000; // treated as infinite
    ReleaseRate := aSection.LineNumeric['release_rate'];
    ReleaseRateLocked := (aSection.Line['release_rate_locked'] <> nil);

    Width := aSection.LineNumeric['width'];
    Height := aSection.LineNumeric['height'];
    ScreenPosition := aSection.LineNumeric['start_x'];
    ScreenYPosition := aSection.LineNumeric['start_y'];

    LevelOptions := GetLevelOptionsValue(aSection.LineTrimString['autosteel']);

    BackgroundIndex := aSection.LineNumeric['background']; // temporary, need to replace with referencing it by filename
  end;
end;

procedure TLevel.LoadSpawnOrderSection(aSection: TParserSection);
var
  Count: Integer;
begin
  if aSection = nil then
  begin
    SetLength(Info.WindowOrder, 0);
    Exit;
  end;
  SetLength(Info.WindowOrder, aSection.LineList.Count);
  Count := aSection.DoForEachLine('object', HandleSpawnEntry);
  SetLength(Info.WindowOrder, Count);
end;

procedure TLevel.HandleSpawnEntry(aLine: TParserLine; const aIteration: Integer);
begin
  Info.WindowOrder[aIteration] := aLine.ValueNumeric;
end;

procedure TLevel.LoadSkillsetSection(aSection: TParserSection);
  function HandleSkill(aLabel: String; aFlag: Cardinal): Integer;
  var
    Line: TParserLine;
  begin
    Result := 0;
    Line := aSection.Line[aLabel];
    if Line = nil then Exit;
    Result := Line.ValueNumeric;
    Info.SkillTypes := Info.SkillTypes or aFlag;
  end;
begin
  Info.SkillTypes := 0;
  if aSection = nil then Exit;

  Info.WalkerCount := HandleSkill('walker', $8000);
  Info.ClimberCount := HandleSkill('climber', $4000);
  Info.SwimmerCount := HandleSkill('swimmer', $2000);
  Info.FloaterCount := HandleSkill('floater', $1000);
  Info.GliderCount := HandleSkill('glider', $0800);
  Info.MechanicCount := HandleSkill('disarmer', $0400);
  Info.BomberCount := HandleSkill('bomber', $0200);
  Info.StonerCount := HandleSkill('stoner', $0100);
  Info.BlockerCount := HandleSkill('blocker', $0080);
  Info.PlatformerCount := HandleSkill('platformer', $0040);
  Info.BuilderCount := HandleSkill('builder', $0020);
  Info.StackerCount := HandleSkill('stacker', $0010);
  Info.BasherCount := HandleSkill('basher', $0008);
  Info.MinerCount := HandleSkill('miner', $0004);
  Info.DiggerCount := HandleSkill('digger', $0002);
  Info.ClonerCount := HandleSkill('cloner', $0001);
end;

procedure TLevel.HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
var
  O: TInteractiveObject;

  procedure Flag(aValue: Integer);
  begin
    O.DrawingFlags := O.DrawingFlags or aValue;
  end;
begin
  O := fInteractiveObjects.Add;
  
  O.GS := aSection.LineTrimString['collection'];
  O.Piece := aSection.LineTrimString['piece'];
  O.Left := aSection.LineNumeric['x'];
  O.Top := aSection.LineNumeric['y'];
  O.Width := aSection.LineNumeric['width'];
  O.Height := aSection.LineNumeric['height'];

  O.IsFake := (aSection.Line['fake'] <> nil);
  O.DrawingFlags := 0;
  if (aSection.Line['invisible'] <> nil) then Flag(odf_Invisible);
  if (aSection.Line['rotate'] <> nil) then Flag(odf_Rotate);
  if (aSection.Line['flip'] <> nil) then Flag(odf_Flip);
  if (aSection.Line['invert'] <> nil) then Flag(odf_UpsideDown);
  if (aSection.Line['face_left'] <> nil) then Flag(odf_FlipLem);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(odf_NoOverwrite);
  if (aSection.Line['only_on_terrain'] <> nil) then Flag(odf_OnlyOnTerrain);

  // Need to replace with better stuff
  O.Skill := aSection.LineNumeric['s_value'];
  O.TarLev := aSection.LineNumeric['l_value'];
end;

procedure TLevel.HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTerrain;
begin
end;

procedure TLevel.HandleAreaEntry(aSection: TParserSection; const aIteration: Integer);
var
  S: TSteel;
begin
end;

procedure TLevel.HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
var
  L: TPreplacedLemming;
begin
end;

procedure TLevel.SaveToStream(aStream: TStream);
begin
end;

end.

