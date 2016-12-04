{$include lem_directives.inc}
unit LemLevel;

interface

uses
  Classes, SysUtils,
  UMisc,
  LemLemming,
  LemTerrain,
  LemInteractiveObject,
  LemSteel;

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
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Info: TLevelInfo read fLevelInfo;
    property InteractiveObjects: TInteractiveObjects read fInteractiveObjects;
    property Terrains: TTerrains read fTerrains;
    property Steels: TSteels read fSteels;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings;
  end;

  {
  T_Level = class
  private
  protected
  public
  published
  end;}

implementation

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
  inherited Destroy;
end;

end.

