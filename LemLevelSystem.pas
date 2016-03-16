{$include lem_directives.inc}
unit LemLevelSystem;

interface

uses
  Classes,
  UMisc, UTools, UClasses,
  LemDosStructures,
  LemNeoSave, LemLevel;

  {-------------------------------------------------------------------------------
    Nested classes for levelpack system:
    system
      levelpack (DosOrig=Default: only for multi levelpacks like Lemmini)
        section (FUN)
          levelinfo (just dig)
      levelpack
        section
          levelinfo
  -------------------------------------------------------------------------------}
type
  TPackSection = class;
  TLevelPack = class;

  TLevelInfo = class(TCollectionItem)
  private
    function GetOwnerSection: TPackSection;
  protected
    fTrimmedTitle            : string; // the title: this is only for display purposes.
    fDosLevelPackFileName    : string; // dos file where we can find this level (levelxxx.dat)
    fDosLevelPackIndex       : Integer; // dos file position in doslevelpackfilename(in fact: which decompression section)
    fOwnerFile               : string; // lemmini: lemmini ini file containing this level
  public
    property OwnerSection: TPackSection read GetOwnerSection;
  published
    property TrimmedTitle: string read fTrimmedTitle write fTrimmedTitle;
    property DosLevelPackFileName: string read fDosLevelPackFileName write fDosLevelPackFileName;
    property DosLevelPackIndex: Integer read fDosLevelPackIndex write fDosLevelPackIndex;
    property OwnerFile: string read fOwnerFile write fOwnerFile;
  end;

  TLevelInfos = class(TOwnedCollectionEx)
  private
    function GetItem(Index: Integer): TLevelInfo;
    procedure SetItem(Index: Integer; const Value: TLevelInfo);
  protected
  public
    constructor Create(aOwner: TPersistent); // owner = TPackSection
    function Add: TLevelInfo;
    function Insert(Index: Integer): TLevelInfo;
    property Items[Index: Integer]: TLevelInfo read GetItem write SetItem; default;
  published
  end;

  TPackSection = class(TCollectionItem)
  private
    fLevelInfos: TLevelInfos;
    fSectionName: string;
    fSourceFileName: string;
    function GetOwnerPack: TLevelPack;
  protected
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property OwnerPack: TLevelPack read GetOwnerPack;
  published
    property SourceFileName: string read fSourceFileName write fSourceFileName;
    property SectionName: string read fSectionName write fSectionName;
    property LevelInfos: TLevelInfos read fLevelInfos write fLevelInfos; // tricky?
  end;

  TPackSections = class(TOwnedCollectionEx)
  private
    function GetItem(Index: Integer): TPackSection;
    procedure SetItem(Index: Integer; const Value: TPackSection);
  protected
  public
    constructor Create(aOwner: TPersistent); // owner = TLevelPack
    function Add: TPackSection;
    function Insert(Index: Integer): TPackSection;
    property Items[Index: Integer]: TPackSection read GetItem write SetItem; default;
  published
  end;

  TLevelPack = class(TCollectionItem)
  private
    fPackSections: TPackSections;
    fLevelPackName: string;
    fSourceFileName: string;
    function GetPackSection(Index: Integer): TPackSection;
  protected
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property PackSection[Index: Integer]: TPackSection read GetPackSection; default;
  published
    property SourceFileName: string read fSourceFileName write fSourceFileName stored True; // only lemmini
    property LevelPackName: string read fLevelPackName write fLevelPackName;
    property PackSections: TPackSections read fPackSections write fPackSections; // tricky?
  end;

  TLevelPacks = class(TCollectionEx)
  private
    function GetItem(Index: Integer): TLevelPack;
    procedure SetItem(Index: Integer; const Value: TLevelPack);
  protected
  public
    constructor Create;
    function Add: TLevelPack;
    function Insert(Index: Integer): TLevelPack;

    procedure SaveToStream(S: TStream);
    procedure SaveToTxtFile(const aFileName: string);

    property Items[Index: Integer]: TLevelPack read GetItem write SetItem; default;
  published
  end;

  TLevelPacksWrapper = class(TComponent)
  private
    fLevelPacks: TLevelPacks;
  public
    procedure SaveToTxtFile(const aFileName: string);
    procedure SaveToStream(S: TStream);
  published
    property LevelPacks: TLevelPacks read fLevelPacks write fLevelPacks;
  end;

  {-------------------------------------------------------------------------------
    This record is used as parameter for retrieving levels.
    TBaseDosLevelSystem provides the mechanism.
  -------------------------------------------------------------------------------}
  TDosGamePlayInfoRec = record
    dValid         : Boolean;
    dPack          : Integer; // this is a dummy for dos
    dSection       : Integer;
    dLevel         : Integer; // zero based!
    dSectionName   : string;
  end;

  TBaseLevelSystemClass = class of TBaseLevelSystem;
  TBaseLevelSystem = class(TOwnedPersistent)
  private
    fSaveSystem : TNeoSave;
    function GetLevelPackCount: Integer;

  protected
    fLevelPacks       : TLevelPacks;
    fPrepared         : Boolean;
    procedure InternalPrepare; virtual; abstract;
//    function InternalGetLevelInfo(aPack, aSection, aLevel: Integer): TLevelInfo; virtual; abstract;
    procedure InternalLoadLevel(aInfo: TLevelInfo; aLevel: TLevel; OddLoad: Byte = 0); virtual; abstract;
    procedure InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0); virtual; abstract;
  public
    SysDat : TSysDatRec;
    constructor Create(aOwner: TPersistent);
    destructor Destroy; override;

    procedure SetSaveSystem(aValue: Pointer);

    procedure Prepare;
    procedure LoadSingleLevel(aPack, aSection, aLevelIndex: Integer; aLevel: TLevel; SoftOdd: Boolean = false);


    function FindFirstLevel(var Rec: TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindNextLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindFinalLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindLastUnlockedLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindNextUnlockedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; virtual; abstract;
    function FindPreviousUnlockedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; virtual; abstract;

    function GetLevelCode(const Rec : TDosGamePlayInfoRec): string; virtual; abstract;
    function FindLevelCode(const aCode: string; var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindCheatCode(const aCode: string; var Rec : TDosGamePlayInfoRec; CheatsEnabled: Boolean = true): Boolean; virtual; abstract;

    property LevelPacks: TLevelPacks read fLevelPacks;
    property LevelPackCount: Integer read GetLevelPackCount;
    property SaveSystem: TNeoSave read fSaveSystem;
  end;



implementation


{ TLevelInfo }

function TLevelInfo.GetOwnerSection: TPackSection;
begin
  Result := TPackSection(Collection.Owner);
end;


{ TLevelInfos }

function TLevelInfos.Add: TLevelInfo; 
begin 
  Result := TLevelInfo(inherited Add);
end; 

constructor TLevelInfos.Create(aOwner: TPersistent); 
begin 
  inherited Create(aOwner, TLevelInfo); 
end; 

function TLevelInfos.GetItem(Index: Integer): TLevelInfo;
begin 
  Result := TLevelInfo(inherited GetItem(Index)) 
end; 

function TLevelInfos.Insert(Index: Integer): TLevelInfo; 
begin
  Result := TLevelInfo(inherited Insert(Index))
end;

procedure TLevelInfos.SetItem(Index: Integer; const Value: TLevelInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TPackSection }

constructor TPackSection.Create(Collection: TCollection);
begin
  inherited;
  fLevelInfos := TLevelInfos.Create(Self);
end;

destructor TPackSection.Destroy;
begin
  fLevelInfos.Free;
  inherited;
end;

function TPackSection.GetOwnerPack: TLevelPack;
begin
  Result := TLevelPack(Collection.Owner);
end;

{ TPackSections }

function TPackSections.Add: TPackSection;
begin
  Result := TPackSection(inherited Add);
end;

constructor TPackSections.Create(aOwner: TPersistent);
begin
  inherited Create(aOwner, TPackSection);
end;

function TPackSections.GetItem(Index: Integer): TPackSection;
begin
  Result := TPackSection(inherited GetItem(Index))
end;

function TPackSections.Insert(Index: Integer): TPackSection;
begin
  Result := TPackSection(inherited Insert(Index))
end;

procedure TPackSections.SetItem(Index: Integer; const Value: TPackSection);
begin
  inherited SetItem(Index, Value);
end;

{ TLevelPack }

constructor TLevelPack.Create(Collection: TCollection);
begin
  inherited;
  fPackSections := TPackSections.Create(Self);
end;

destructor TLevelPack.Destroy;
begin
  fPackSections.Free;
  inherited;
end;


(*function TLevelPack.GetPackSection(Index: Integer): TPackSection;
begin
  Result := fPackSections[Index];
end;*)

function TLevelPack.GetPackSection(Index: Integer): TPackSection;
begin
  Result := fPackSections[Index];
end;

{ TLevelPacks }

function TLevelPacks.Add: TLevelPack;
begin
  Result := TLevelPack(inherited Add);
end; 

constructor TLevelPacks.Create;
begin
  inherited Create(TLevelPack);
end; 

function TLevelPacks.GetItem(Index: Integer): TLevelPack; 
begin 
  Result := TLevelPack(inherited GetItem(Index))
end;

function TLevelPacks.Insert(Index: Integer): TLevelPack;
begin
  Result := TLevelPack(inherited Insert(Index))
end;

procedure TLevelPacks.SaveToStream(S: TStream);
var
  Wrapper: TLevelPacksWrapper;
begin
  Wrapper := TLevelPacksWrapper.Create(nil);
  try
    Wrapper.LevelPacks := Self;
    Wrapper.SaveToStream(S);
  finally
    Wrapper.Free;
  end;
end;

procedure TLevelPacks.SaveToTxtFile(const aFileName: string);
var
  Wrapper: TLevelPacksWrapper;
begin
  Wrapper := TLevelPacksWrapper.Create(nil);
  try
    Wrapper.LevelPacks := Self;
    Wrapper.SaveToTxtFile(aFileName);
  finally
    Wrapper.Free;
  end;
end;

procedure TLevelPacks.SetItem(Index: Integer; const Value: TLevelPack);
begin 
  inherited SetItem(Index, Value); 
end;

{ TLevelPacksWrapper }

procedure TLevelPacksWrapper.SaveToStream(S: TStream);
begin
  S.WriteComponent(Self);
end;

procedure TLevelPacksWrapper.SaveToTxtFile(const aFileName: string);
begin
  ComponentToTextFile(Self, aFileName);
end;

{ TBaseLevelSystem }

constructor TBaseLevelSystem.Create(aOwner: TPersistent);
begin
  inherited Create(aOwner);
  fLevelPacks := TLevelPacks.Create;
end;

destructor TBaseLevelSystem.Destroy;
begin
  fLevelPacks.Free;
  inherited;
end;

procedure TBaseLevelSystem.SetSaveSystem(aValue: Pointer);
var
  p : ^TNeoSave;
begin
  p := aValue;
  fSaveSystem := p^;
end;

function TBaseLevelSystem.GetLevelPackCount: Integer;
begin
  Result := fLevelPacks.Count
end;

procedure TBaseLevelSystem.LoadSingleLevel(aPack, aSection, aLevelIndex: Integer; aLevel: TLevel; SoftOdd: Boolean = false);
begin
  if SoftOdd then
    InternalLoadSingleLevel(aSection, aLevelIndex, aLevel, 2)
    else
    InternalLoadSingleLevel(aSection, aLevelIndex, aLevel);
end;

procedure TBaseLevelSystem.Prepare;
begin
  if not fPrepared then
  begin
    InternalPrepare;
    fPrepared := True;
  end;
end;


end.

