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

    fGraphicSet     : Integer;
    fGraphicSetEx   : Integer;

    fLevelOptions   : Cardinal;

    fSuperLemming   : Integer;
    fScreenPosition : Integer;
    fScreenYPosition: Integer;
    fDisplayPercent : Integer;
    fTitle          : string;
    fAuthor         : string;

    fGraphicSetFile : string;
    fVgaspecFile    : string;
    fGraphicMetaFile : string;
    fGraphicSetName : string;
    fMusicFile      : string;

    fGimmickSet     : LongWord;
    fGimmickSet2    : LongWord;
    fGimmickSet3    : LongWord;

    fVgaspecX       : Integer;
    fVgaspecY       : Integer;

    fBnsRank        : Integer;
    fBnsLevel       : Integer;

    fLevelID        : LongWord;
  protected
  public
    fOddtarget        : Integer;
    WindowOrder       : array of word;
    constructor Create;
    procedure Assign(Source: TPersistent); override;
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

    property GraphicSet     : Integer read fGraphicSet write fGraphicSet;
    property GraphicSetEx   : Integer read fGraphicSetEx write fGraphicSetEx;
    property SuperLemming   : Integer read fSuperLemming write fSuperLemming;
    property ScreenPosition : Integer read fScreenPosition write fScreenPosition;
    property ScreenYPosition : Integer read fScreenYPosition write fScreenYPosition;
    property DisplayPercent : Integer read fDisplayPercent write fDisplayPercent;
    property Title          : string read fTitle write fTitle;
    property Author         : string read fAuthor write fAuthor;

    property LevelOptions   : Cardinal read fLevelOptions write fLevelOptions;

    property Width          : Integer read fWidth write fWidth;
    property Height         : Integer read fHeight write fHeight;
    property VgaspecX       : Integer read fVgaspecX write fVgaspecX;
    property VgaspecY       : Integer read fVgaspecY write fVgaspecY;

    property GimmickSet     : LongWord read fGimmickSet write fGimmickSet;
    property GimmickSet2    : LongWord read fGimmickSet2 write fGimmickSet2;
    property GimmickSet3    : LongWord read fGimmickSet3 write fGimmickSet3;

    property GraphicMetaFile : String read fGraphicMetaFile write fGraphicMetaFile;
    property GraphicSetFile : String read fGraphicSetFile write fGraphicSetFile;
    property VgaspecFile    : String read fVgaspecFile write fVgaspecFile;
    property GraphicSetName : String read fGraphicSetName write fGraphicSetName;
    property MusicFile      : String read fMusicFile write fMusicFile;

    property BnsRank: Integer read fBnsRank write fBnsRank;
    property BnsLevel: Integer read fBnsLevel write fBnsLevel;

    property LevelID: LongWord read fLevelID write fLevelID;
  end;

  TLevel = class(TComponent)
  private
  protected
    fLevelInfo       : TLevelInfo;
    fTerrains           : TTerrains;
    fInteractiveObjects : TInteractiveObjects;
    fSteels             : TSteels;
    fPreplacedLemmings  : TPreplacedLemmingList;
  { internal }
    fUpdateCounter      : Integer;
  { property access }
    procedure SetTerrains(Value: TTerrains); virtual;
    procedure SetInteractiveObjects(Value: TInteractiveObjects); virtual;
    procedure SetSteels(Value: TSteels); virtual;
    procedure SetLevelInfo(const Value: TLevelInfo); virtual;
  { dynamic creation }
    function DoCreateLevelInfo: TLevelInfo; dynamic;
    function DoCreateTerrains: TTerrains; dynamic;
    function DoCreateInteractiveObjects: TInteractiveObjects; dynamic;
    function DoCreateSteels: TSteels; dynamic;
  { protected overrides }
  public
    { TODO : TLevel maybe does not need to be a Component }
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignOddtable(Source: TLevel);
    procedure SaveToFile(const aFileName: string);
    procedure SaveToStream(S: TStream);
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure ClearLevel;
  published
    property Info: TLevelInfo read fLevelInfo write SetLevelInfo;
    property InteractiveObjects: TInteractiveObjects read fInteractiveObjects write SetInteractiveObjects;
    property Terrains: TTerrains read fTerrains write SetTerrains;
    property Steels: TSteels read fSteels write SetSteels;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings write fPreplacedLemmings;
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

procedure TLevelInfo.Assign(Source: TPersistent);
// don't use this, it's very outdated
var
  L: TLevelInfo absolute Source;
begin
  if Source is TLevelInfo then
  begin
    ReleaseRate    := L.ReleaseRate;
    LemmingsCount  := L.LemmingsCount;
    RescueCount    := L.RescueCount;
    TimeLimit      := L.TimeLimit;
    ClimberCount   := L.ClimberCount;
    FloaterCount   := L.FloaterCount;
    BomberCount    := L.BomberCount;
    BlockerCount   := L.BlockerCount;
    BuilderCount   := L.BuilderCount;
    BasherCount    := L.BasherCount;
    MinerCount     := L.MinerCount;
    DiggerCount    := L.DiggerCount;
    GraphicSet     := L.GraphicSet;
    GraphicSetEx   := L.GraphicSetEx;
    SuperLemming   := L.SuperLemming;
    ScreenPosition := L.ScreenPosition;
    Title          := L.Title;
  end
  else inherited Assign(Source);
end;

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
  GraphicSet     := 0;
  GraphicSetEx   := 0;
  LevelOptions   := 0;
  SuperLemming   := 0;
  ScreenPosition := 0;
  ScreenYPosition := 0;
  Width := 1584;
  Height := 160;
  Title          := '';
  Author         := '';
  for i := 0 to Length(WindowOrder)-1 do
    WindowOrder[i] := 0;
end;

constructor TLevelInfo.Create;
begin
  inherited Create;
  Clear;
end;

{ TLevel }

procedure TLevel.AssignOddtable(Source: TLevel);
var
  i: Integer;
  O, SO: TInteractiveObject;
  T, ST: TTerrain;
  S, SS: TSteel;
begin
  with Info do
  begin
    LevelOptions := (LevelOptions and $71) or (Source.Info.LevelOptions and not $71);
    Width := Source.Info.Width;
    Height := Source.Info.Height;
    GraphicSet := (GraphicSet and $FF00) or (Source.Info.GraphicSet and $FF);
    GraphicSetEx := Source.Info.GraphicSetEx;
    ScreenPosition := Source.Info.ScreenPosition;
    ScreenYPosition := Source.Info.ScreenYPosition;
    GraphicSetFile := Source.Info.GraphicSetFile;
    GraphicMetaFile := Source.Info.GraphicMetaFile;
    GraphicSetName := Source.Info.GraphicSetName;
    VgaspecFile := Source.Info.VgaspecFile;
    VgaspecX := Source.Info.VgaspecX;
    VgaspecY := Source.Info.VgaspecY;
    SetLength(Info.WindowOrder, Length(Source.Info.WindowOrder));
    for i := 0 to Length(Source.Info.WindowOrder)-1 do
      Info.WindowOrder[i] := Source.Info.WindowOrder[i];
  end;

  InteractiveObjects.Clear;
  for i := 0 to Source.InteractiveObjects.Count-1 do
  begin
    O := InteractiveObjects.Add;
    SO := Source.InteractiveObjects[i];
    O.Assign(SO);
  end;

  Terrains.Clear;
  for i := 0 to Source.Terrains.Count-1 do
  begin
    T := Terrains.Add;
    ST := Source.Terrains[i];
    T.Assign(ST);
  end;

  Steels.Clear;
  for i := 0 to Source.Steels.Count-1 do
  begin
    S := Steels.Add;
    SS := Source.Steels[i];
    S.Assign(SS);
  end;
end;

procedure TLevel.Assign(Source: TPersistent);
var
  L: TLevel absolute Source;
begin
  if Source is TLevel then
  begin
    BeginUpdate;
    try
      Info := L.Info;
      InteractiveObjects := L.InteractiveObjects;
      Terrains := L.Terrains;
      Steels := L.Steels;
    finally
      EndUpdate;
    end;
  end
  else inherited Assign(Source)
end;

procedure TLevel.BeginUpdate;
begin
{ TODO : a little more protection for beginupdate endupdate }
  Inc(fUpdateCounter);
  if fUpdateCounter = 1 then
  begin
    fInteractiveObjects.BeginUpdate;
    fTerrains.BeginUpdate;
    fSteels.BeginUpdate;
  end;
end;

procedure TLevel.ClearLevel;
begin
  //fLevelInfo.Clear;
  fInteractiveObjects.Clear;
  fTerrains.Clear;
  fSteels.Clear;
  fPreplacedLemmings.Clear;
end;

constructor TLevel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fLevelInfo := DoCreateLevelInfo;
  fInteractiveObjects := DoCreateInteractiveObjects;
  fTerrains := DoCreateTerrains;
  fSteels := DoCreateSteels;
  fPreplacedLemmings := TPreplacedLemmingList.Create;
end;

destructor TLevel.Destroy;
begin
  fLevelInfo.Free;
  fInteractiveObjects.Free;
  fTerrains.Free;
  fSteels.Free;
  fPreplacedLemmings.Create;
  inherited Destroy;
end;

function TLevel.DoCreateInteractiveObjects: TInteractiveObjects;
begin
  Result := TInteractiveObjects.Create(TInteractiveObject);
end;

function TLevel.DoCreateLevelInfo: TLevelInfo;
begin
  Result := TLevelInfo.Create;
end;

function TLevel.DoCreateSteels: TSteels;
begin
  Result := TSteels.Create(TSteel);
end;

function TLevel.DoCreateTerrains: TTerrains;
begin
  Result := TTerrains.Create(TTerrain);
end;

procedure TLevel.EndUpdate;
begin
  if fUpdateCounter > 0 then
  begin
    Dec(fUpdateCounter);
    if fUpdateCounter = 0 then
    begin
      fInteractiveObjects.EndUpdate;
      fTerrains.EndUpdate;
      fSteels.EndUpdate;
    end;
  end;
end;

procedure TLevel.SaveToFile(const aFileName: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFileName, fmCreate);
  try
     SaveToStream(F);
  finally
    F.Free;
  end;
end;

procedure TLevel.SaveToStream(S: TStream);
begin
  S.WriteComponent(Self);
end;

procedure TLevel.SetLevelInfo(const Value: TLevelInfo);
begin
  fLevelInfo.Assign(Value);
end;

procedure TLevel.SetInteractiveObjects(Value: TInteractiveObjects);
begin
  fInteractiveObjects.Assign(Value);
end;

procedure TLevel.SetTerrains(Value: TTerrains);
begin
  fTerrains.Assign(Value);
end;

procedure TLevel.SetSteels(Value: TSteels);
begin
  fSteels.Assign(Value);
end;

end.

