{$include lem_directives.inc}
unit LemLevelSystem;

interface

uses
  Classes, UClasses,
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
  TLevelInfo = class(TCollectionItem)
  private
  protected
    fDosLevelPackFileName    : string; // dos file where we can find this level (levelxxx.dat)
    fDosLevelRankIndex       : Integer;
    fDosLevelPackIndex       : Integer; // dos file position in doslevelpackfilename(in fact: which decompression section)
  public
  published
    property DosLevelPackFileName: string read fDosLevelPackFileName write fDosLevelPackFileName;
    property DosLevelRankIndex: Integer read fDosLevelRankIndex write fDosLevelRankIndex;
    property DosLevelPackIndex: Integer read fDosLevelPackIndex write fDosLevelPackIndex;
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

  TBaseLevelSystem = class(TOwnedPersistent)
  private
    fSaveSystem : TNeoSave;
  protected
    procedure InternalLoadLevel(aInfo: TLevelInfo; aLevel: TLevel; OddLoad: Byte = 0); virtual; abstract;
    procedure InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0); virtual; abstract;
  public
    SysDat : TSysDatRec;

    procedure SetSaveSystem(aValue: Pointer);

    procedure LoadSingleLevel(aPack, aSection, aLevelIndex: Integer; aLevel: TLevel; SoftOdd: Boolean = false);

    function FindFirstLevel(var Rec: TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindNextLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindFinalLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindFirstUnsolvedLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindNextUnsolvedLevel(var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindPreviousUnsolvedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; virtual; abstract;

    function FindLevelCode(const aCode: string; var Rec : TDosGamePlayInfoRec): Boolean; virtual; abstract;
    function FindCheatCode(const aCode: string; var Rec : TDosGamePlayInfoRec; CheatsEnabled: Boolean = true): Boolean; virtual; abstract;

    property SaveSystem: TNeoSave read fSaveSystem;
  end;



implementation

{ TBaseLevelSystem }

procedure TBaseLevelSystem.SetSaveSystem(aValue: Pointer);
begin
  fSaveSystem := TNeoSave(aValue^);
end;

procedure TBaseLevelSystem.LoadSingleLevel(aPack, aSection, aLevelIndex: Integer; aLevel: TLevel; SoftOdd: Boolean = false);
begin
  if SoftOdd then
    InternalLoadSingleLevel(aSection, aLevelIndex, aLevel, 2)
  else
    InternalLoadSingleLevel(aSection, aLevelIndex, aLevel);
end;

end.

