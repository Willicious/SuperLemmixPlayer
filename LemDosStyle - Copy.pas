{$include lem_directives.inc}
unit LemDosStyle;

interface

uses
  Classes,
  UMisc,
  GR32,
  SharedGlobals,
  Dialogs, Controls,
  LemTypes, LemLevel, LemLVLLoader, LemGraphicSet, LemDosGraphicSet, LemNeoGraphicSet,
  LemMetaAnimation, LemAnimationSet, LemDosCmp, LemDosStructures, LemDosAnimationSet,
  LemDosMainDat,
  LemStyle, LemLevelSystem, LemMusicSystem,
  LemNeoEncryption,
  LemNeoSave;

const
  DosMiniMapCorners: TRect = (
    Left: 208;   // width =about 100
    Top: 18;
    Right: 311;  // height =about 20
    Bottom: 37
  );

  // to draw
  DosMiniMapBounds: TRect = (
    Left: 208;   // width =about 100
    Top: 18;
    Right: 311 + 1;  // height =about 20
    Bottom: 37 + 1
  );

const
  DOS_MINIMAP_WIDTH  = 104;
  DOS_MINIMAP_HEIGHT = 20;

type
  TBaseDosLemmingStyle = class(TBaseLemmingStyle)
  private
    fMainDataFile: string;
    function GetAnimationSet: TBaseDosAnimationSet;
  protected
    function DoCreateAnimationSet: TBaseAnimationSet; override;
  public
    function CreateGraphicSet: TBaseGraphicSet; override;
    procedure LoadSystemDat;
    property AnimationSet: TBaseDosAnimationSet read GetAnimationSet; // get it typed
  published
    property MainDataFile: string read fMainDataFile write fMainDataFile; // default main.dat
  end;

  TDosOrigStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosOhNoStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPDOSStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPIIStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLP2BStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPIIIStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLP3BStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPIVStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPZStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosH94Style = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosCustStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosFlexiStyle = class(TBaseDosLemmingStyle)
  public
    SysDat : TSysDatRec;
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosCovoxStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosPrimaStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosXmasStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosExtraStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPHStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPCStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosLPCIIStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosZombieStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;

  TDosCopycatStyle = class(TBaseDosLemmingStyle)
  protected
    function DoCreateLevelSystem: TBaseLevelSystem; override;
    function DoCreateMusicSystem: TBaseMusicSystem; override;
  end;



  {-------------------------------------------------------------------------------
    Basic levelloadingsystem for dos.
    We virtualized it until this class was able to load all levelinfo's for
    all dos styles, overriding only 3 methods.
  -------------------------------------------------------------------------------}
  TBaseDosLevelSystem = class(TBaseLevelSystem)
  protected
    fDefaultLevelCount: Integer;
    fLevelCount : array[0..15] of Integer;
    fLookForLVL: Boolean; // looks for user-overridden lvl-files on disk
  { overridden from base loader }
    procedure InternalLoadLevel(aInfo: TLevelInfo; aLevel: TLevel; OddLoad: Byte = 0); override;
    procedure InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0); override;
    procedure InternalPrepare; override;
    function EasyGetSectionName(aSection: Integer): string;
  public
    fDefaultSectionCount: Integer; // initialized at creation
    SysDat : TSysDatRec;
    fTestMode: Boolean;
    fTestLevel: String;
    fOneLvlString: String;
    constructor Create(aOwner: TPersistent);
  { these methods must be overridden by derived dos loaders }
    procedure GetSections(aSectionNames: TStrings); virtual;
    procedure GetEntry(aSection, aLevel: Integer; var aFileName: string; var aFileIndex: Integer);
    function GetLevelPackPrefix: String;
    function GetLevelCount(aSection: Integer): Integer; virtual; //override;
    function GetSecretLevelCount(aSection: Integer): Integer; virtual; //override;
    function GetSectionCount: Integer; virtual;
    procedure DumpAllLevels;
    procedure InitSave;

    //For the time being it is not needed to virtualize this into a higher class.
    function FindFirstLevel(var Rec: TDosGamePlayInfoRec): Boolean; override;
    function FindNextLevel(var Rec : TDosGamePlayInfoRec; Secret: Integer = -1; Overrider: Integer = -1): Boolean; override;
    function FindLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindFinalLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindLastUnlockedLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindNextUnlockedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; override;
    function FindPreviousUnlockedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; override;
    procedure UnlockAllLevels;


    function GetLevelCode(const Rec : TDosGamePlayInfoRec): string; override;
    function FindLevelCode(const aCode: string; var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindCheatCode(const aCode: string; var Rec : TDosGamePlayInfoRec; CheatsEnabled: Boolean = true): Boolean; override;

    property LookForLVL: Boolean read fLookForLVL write fLookForLVL;
  end;

  TDosOrigLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosOhNoLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPDOSLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPIILevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPIIILevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLP3BLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPIVLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPZLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLP2BLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosH94LevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosCustLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
  end;

  TDosFlexiLevelSystem = class(TBaseDosLevelSystem)
  private
    //SysLoaded : Boolean;
  public
    SysDat : TSysDatRec;
    procedure LoadSystemInfo();
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
    function GetSecretLevelCount(aSection: Integer): Integer; override;
    function GetRankName(aSection: Byte): String;
  end;

  TDosCovoxLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosPrimaLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosXmasLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosExtraLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPHLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosLPCLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosZombieLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;

  TDosCopycatLevelSystem = class(TBaseDosLevelSystem)
  public
    procedure GetSections(aSectionNames: TStrings); override;
    //function GetLevelCount(aSection: Integer): Integer; override;
  end;


  TDosOrigMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosOhNoMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPDOSMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPIIMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLP2BMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPIIIMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLP3BMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPIVMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPZMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosH94MusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosCustMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosFlexiMusicSystem = class(TBaseMusicSystem)
  private
    //SysLoaded : Boolean;
  protected
  public
    MusicCount : Byte;
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosCovoxMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosPrimaMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosXmasMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosExtraMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPHMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosLPCMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosZombieMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

  TDosCopycatMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

function GenCode(aRandseed, aSection, aLevel: Integer): string;

function AutoCreateStyle(const aDirectory: string; aSysDat: TSysDatRec): TBaseDosLemmingStyle;
function CreateDosOrigStyle(const aDirectory: string): TDosOrigStyle;
function CreateDosOhnoStyle(const aDirectory: string): TDosOhNoStyle;
function CreateDosLPDOSStyle(const aDirectory: string): TDosLPDOSStyle;
function CreateDosLPIIStyle(const aDirectory: string): TDosLPIIStyle;
function CreateDosLP2BStyle(const aDirectory: string): TDosLP2BStyle;
function CreateDosH94Style(const aDirectory: string): TDosH94Style;
function CreateDosCustStyle(const aDirectory: string): TDosCustStyle;
function CreateDosFlexiStyle(const aDirectory: string; aSysDat: TSysDatRec): TDosFlexiStyle;
function CreateDosLPIIIStyle(const aDirectory: string): TDosLPIIIStyle;
function CreateDosLP3BStyle(const aDirectory: string): TDosLP3BStyle;
function CreateDosLPIVStyle(const aDirectory: string): TDosLPIVStyle;
function CreateDosLPZStyle(const aDirectory: string): TDosLPZStyle;
function CreateDosCovoxStyle(const aDirectory: string): TDosCovoxStyle;
function CreateDosPrimaStyle(const aDirectory: string): TDosPrimaStyle;
function CreateDosXmasStyle(const aDirectory: string): TDosXmasStyle;
function CreateDosExtraStyle(const aDirectory: string): TDosExtraStyle;
function CreateDosLPHStyle(const aDirectory: string): TDosLPHStyle;
function CreateDosLPCStyle(const aDirectory: string): TDosLPCStyle;
function CreateDosLPCIIStyle(const aDirectory: string): TDosLPCIIStyle;
function CreateDosZombieStyle(const aDirectory: string): TDosZombieStyle;
function CreateDosCopycatStyle(const aDirectory: string): TDosCopycatStyle;

implementation

uses
  SysUtils;

{-------------------------------------------------------------------------------
  BEGIN Random code gen.
  Original from Borland Delphi 5 system._randint.
-------------------------------------------------------------------------------}

var
  LemRandSeed: Integer = 0;

function LemRandom(Range: Integer): Integer;
asm
{     ->EAX     Range   }
{     <-EAX     Result  }
        IMUL    EDX, LemRandSeed, 08088405H
        INC     EDX
        MOV     LemRandSeed, EDX
        MUL     EDX
        MOV     EAX, EDX
end;

function LemRandomPAS(Range: Integer): Integer;
var
  D: Integer;
begin
  D := LemRandSeed * $08088405 + 1;
  LemRandSeed := D;


  //      IMUL    EDX, LemRandSeed, 08088405H
    //    INC     EDX
      //  MOV     LemRandSeed, EDX
        //MUL     EDX
//        MOV     EAX, EDX
  Result := 0;
end;

(*
function ChRandom64: U64;
var
  A, B: Integer;
type
  T64 = record
    IntA: Integer;
    IntB: Integer;
  end;
begin
  A := ChRandom(MaxInt);
  B := ChRandom(MaxInt);
  T64(Result).IntA := A;
  T64(Result).IntB := B;
end; *)

(*
procedure LemRandomize;
var
  systemTime :
  record
          wYear   : Word;
          wMonth  : Word;
          wDayOfWeek      : Word;
          wDay    : Word;
          wHour   : Word;
          wMinute : Word;
          wSecond : Word;
          wMilliSeconds: Word;
          reserved        : array [0..7] of char;
  end;
asm
        LEA     EAX,systemTime
        PUSH    EAX
        CALL    GetSystemTime
        MOVZX   EAX,systemTime.wHour
        IMUL    EAX,60
        ADD     AX,systemTime.wMinute   { sum = hours * 60 + minutes    }
        IMUL    EAX,60
        XOR     EDX,EDX
        MOV     DX,systemTime.wSecond
        ADD     EAX,EDX                 { sum = sum * 60 + seconds              }
        IMUL    EAX,1000
        MOV     DX,systemTime.wMilliSeconds
        ADD     EAX,EDX                 { sum = sum * 1000 + milliseconds       }
        MOV     ChRandSeed,EAX
end;
*)

{-------------------------------------------------------------------------------
  END random gen
-------------------------------------------------------------------------------}

function GenCode(aRandseed, aSection, aLevel: Integer): string;
{-------------------------------------------------------------------------------
  generate access code for a lemming system. every lemming system should have
  its own randseed.
  aRandseed should be a low positive number
-------------------------------------------------------------------------------}
//var
  //r, i: Integer;
//  c: Char;
  (*
begin
  LemRandseed := aRandseed * 1000 + aSection * 100 + aLevel * 10;

  SetLength(Result, 10);
  for i := 1 to 10 do
  begin
    r := LemRandom(26);
    c := Chr(r + ord('A'));
    Result[i] := c;
  end;
*)

{-------------------------------------------------------------------------------
  generates random codes with alternating nouns non-nouns
-------------------------------------------------------------------------------}
const
  klinkers: array[0..14] of char = ('A','E','F','H','I','K','L','M','N','T','V','W','X','Y','Z');
  medeklinkers: array[0..9] of char = ('B','C','D','G','J','O','P','R','S','U');

  function RndChar(aMedeklinker: Boolean): Char;
  begin
    if aMedeklinker then
      Result := Klinkers[LemRandom(15)]
    else
      Result := Medeklinkers[LemRandom(10)];
  end;

var
  //L: TStringList;
  //Sec, Lev,
  i: Integer;
  //r: Integer;
  c : Char;
  //s: string;
  DoMedeKlinker: Boolean;
  TempStream: TMemoryStream;
  SL: TStringList;
begin
  TempStream := CreateDataStream('codes.txt', ldtText);
  if TempStream <> nil then
  begin
    SL := TStringList.Create;
    SL.LoadFromStream(TempStream);
    TempStream.Free;
    Result := UpperCase(SL.Values[LeadZeroStr(aSection+1, 2) + LeadZeroStr(aLevel+1, 2)]);
    SL.Free;
    if Result <> '' then Exit;
  end;

  // never change this
  LemRandseed := (aLevel div 99) * 1000000 + aRandseed * 10000 + (aSection + 1) * 100 + ((aLevel mod 99) + 1);

//  randseed := -1207816797; // so we do not need consts
  Result := StringOfChar(' ', 10);

  DoMedeKlinker := Boolean(LemRandom(2)); // init on random
  for i := 1 to 10 do
  begin
    //r := LemRandom(26);
    //c := Chr(r + ord('A'));
    C := RndChar(DoMedeKlinker);
    DoMedeKlinker := not DoMedeKlinker;
    Result[i] := c;
  end;
end;

function CreateDosOrigStyle(const aDirectory: string): TDosOrigStyle;
{var
  s,l:integer;
  sl:tstringlist;}
begin
  Result := TDosOrigStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosOhnoStyle(const aDirectory: string): TDosOhNoStyle;
begin
  Result := TDosOhNoStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPDOSStyle(const aDirectory: string): TDosLPDOSStyle;
begin
  Result := TDosLPDOSStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPIIStyle(const aDirectory: string): TDosLPIIStyle;
begin
  Result := TDosLPIIStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLP2BStyle(const aDirectory: string): TDosLP2BStyle;
begin
  Result := TDosLP2BStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPIIIStyle(const aDirectory: string): TDosLPIIIStyle;
begin
  Result := TDosLPIIIStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLP3BStyle(const aDirectory: string): TDosLP3BStyle;
begin
  Result := TDosLP3BStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPIVStyle(const aDirectory: string): TDosLPIVStyle;
begin
  Result := TDosLPIVStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPZStyle(const aDirectory: string): TDosLPZStyle;
begin
  Result := TDosLPZStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosH94Style(const aDirectory: string): TDosH94Style;
begin
  Result := TDosH94Style.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosCustStyle(const aDirectory: string): TDosCustStyle;
begin
  Result := TDosCustStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosFlexiStyle(const aDirectory: string; aSysDat: TSysDatRec): TDosFlexiStyle;
begin
  Result := TDosFlexiStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
  Result.SysDat := aSysDat;
end;

function CreateDosCovoxStyle(const aDirectory: string): TDosCovoxStyle;
begin
  Result := TDosCovoxStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosPrimaStyle(const aDirectory: string): TDosPrimaStyle;
begin
  Result := TDosPrimaStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosXmasStyle(const aDirectory: string): TDosXmasStyle;
begin
  Result := TDosXmasStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosExtraStyle(const aDirectory: string): TDosExtraStyle;
begin
  Result := TDosExtraStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPHStyle(const aDirectory: string): TDosLPHStyle;
begin
  Result := TDosLPHStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPCStyle(const aDirectory: string): TDosLPCStyle;
begin
  Result := TDosLPCStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosLPCIIStyle(const aDirectory: string): TDosLPCIIStyle;
begin
  Result := TDosLPCIIStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosZombieStyle(const aDirectory: string): TDosZombieStyle;
begin
  Result := TDosZombieStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;

function CreateDosCopycatStyle(const aDirectory: string): TDosCopycatStyle;
begin
  Result := TDosCopycatStyle.Create;
  Result.CommonPath := IncludeTrailingBackslash(aDirectory);
  Result.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.MainDataFile := Result.CommonPath + 'main.dat';
  Result.AnimationSet.ReadMetaData;
end;



function AutoCreateStyle(const aDirectory: string; aSysDat: TSysDatRec): TBaseDosLemmingStyle;
begin
  Result := CreateDosFlexiStyle(aDirectory, aSysDat);
  Assert(Result <> nil);
end;

{ TBaseDosLemmingStyle }

procedure TBaseDosLemmingStyle.LoadSystemDat;
var
  SysDatFile: TMemoryStream;
  NeoEncrypt: TNeoEncryption;
begin
  NeoEncrypt := TNeoEncryption.Create;
  SysDatFile := CreateDataStream('system.dat', ldtLemmings);
  if NeoEncrypt.CheckEncrypted(SysDatFile) then
    NeoEncrypt.LoadStream(SysDatFile);
  SysDatFile.Seek(0, soFromBeginning);
  SysDatFile.ReadBuffer(SysDat, SYSDAT_SIZE);
  SysDatFile.Free;
end;

function TBaseDosLemmingStyle.CreateGraphicSet: TBaseGraphicSet;
begin
  Result := TBaseDosGraphicSet.Create;
end;

function TBaseDosLemmingStyle.DoCreateAnimationSet: TBaseAnimationSet;
begin
  Result := TBaseDosAnimationSet.Create;
end;

function TBaseDosLemmingStyle.GetAnimationSet: TBaseDosAnimationSet;
begin
  Result := TBaseDosAnimationSet(fAnimationSet);
end;

{ TDosOrigStyle }

function TDosOrigStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosOrigLevelSystem.Create(Self);
end;


function TDosOrigStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosOrigMusicSystem.Create;
end;

{ TDosOhNoStyle }

function TDosOhNoStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosOhNoLevelSystem.Create(Self);
end;

function TDosOhNoStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosOhNoMusicSystem.Create;
end;

function TDosLPDOSStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPDOSLevelSystem.Create(Self);
end;

function TDosLPDOSStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPDOSMusicSystem.Create;
end;

function TDosLPIIStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPIILevelSystem.Create(Self);
end;

function TDosLPIIStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPIIMusicSystem.Create;
end;

function TDosLP2BStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLP2BLevelSystem.Create(Self);
end;

function TDosLP2BStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLP2BMusicSystem.Create;
end;

function TDosLPIIIStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPIIILevelSystem.Create(Self);
end;

function TDosLPIIIStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPIIIMusicSystem.Create;
end;

function TDosLP3BStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLP3BLevelSystem.Create(Self);
end;

function TDosLP3BStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLP3BMusicSystem.Create;
end;

function TDosLPIVStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPIVLevelSystem.Create(Self);
end;

function TDosLPIVStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPIVMusicSystem.Create;
end;

function TDosLPZStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPZLevelSystem.Create(Self);
end;

function TDosLPZStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPZMusicSystem.Create;
end;

function TDosH94Style.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosH94LevelSystem.Create(Self);
end;

function TDosH94Style.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosH94MusicSystem.Create;
end;

function TDosCustStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosCustLevelSystem.Create(Self);
end;

function TDosCustStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosCustMusicSystem.Create;
end;

function TDosFlexiStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosFlexiLevelSystem.Create(Self);
end;

function TDosFlexiStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosFlexiMusicSystem.Create;
end;

function TDosCovoxStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosCovoxLevelSystem.Create(Self);
end;

function TDosCovoxStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosCovoxMusicSystem.Create;
end;

function TDosPrimaStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosPrimaLevelSystem.Create(Self);
end;

function TDosPrimaStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosPrimaMusicSystem.Create;
end;

function TDosXmasStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosXmasLevelSystem.Create(Self);
end;

function TDosXmasStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosXmasMusicSystem.Create;
end;

function TDosExtraStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosExtraLevelSystem.Create(Self);
end;

function TDosExtraStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosExtraMusicSystem.Create;
end;

function TDosLPHStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPHLevelSystem.Create(Self);
end;

function TDosLPHStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPHMusicSystem.Create;
end;

function TDosLPCStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPCLevelSystem.Create(Self);
end;

function TDosLPCStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPCMusicSystem.Create;
end;

function TDosLPCIIStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosLPCLevelSystem.Create(Self);
end;

function TDosLPCIIStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosLPCMusicSystem.Create;
end;

function TDosZombieStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosZombieLevelSystem.Create(Self);
end;

function TDosZombieStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosZombieMusicSystem.Create;
end;

function TDosCopycatStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosCopycatLevelSystem.Create(Self);
end;

function TDosCopycatStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosCopycatMusicSystem.Create;
end;


{ TBaseDosLevelSystem }

constructor TBaseDosLevelSystem.Create(aOwner: TPersistent);
var
  i: integer;
begin
  inherited;
  fDefaultSectionCount := GetSectionCount;
  fDefaultLevelCount := GetLevelCount(0);
  for i := 0 to 15 do
    fLevelCount[i] := -1;
end;

procedure TBaseDosLevelSystem.InitSave;
var
  i: Integer;
begin
  for i := 0 to (fDefaultSectionCount - 1) do
    if GetLevelCount(i) > GetSecretLevelCount(i) then SaveSystem.UnlockLevel(i, 0);
end;

procedure TBaseDosLevelSystem.UnlockAllLevels;
var
  i, i2: Integer;
begin
  for i := 0 to GetSectionCount-1 do
    for i2 := 0 to GetLevelCount(i)-1 do
      if i2 < (GetLevelCount(i) - GetSecretLevelCount(i)) then SaveSystem.UnlockLevel(i, i2);
end;

procedure TBaseDosLevelSystem.DumpAllLevels;
var
  aInfo: TLevelInfo;
  aLevel: TLevel;
  dS, dL: Integer;
  aFileName: String;
  aFileIndex: Integer;
  OldLookForLvls: Boolean;
  SoftOddMode: Boolean;

  //i: integer;
  //fHasSteel : Boolean;
begin
  OldLookForLvls := fLookForLVL;
  fLookForLVL := false;
  aInfo := TLevelInfo.Create(nil);
  aLevel := TLevel.Create(nil);
try
  if not ForceDirectories(ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\') then Exit;
  SoftOddMode := true;
  if not SoftOddMode then
    SoftOddMode := MessageDlg('Hard-apply oddtabling to dumped levels?', mtCustom, [mbYes, mbNo], 0) = mrNo
    else
    SoftOddMode := false;

  for dS := 0 to fDefaultSectionCount-1 do
    for DL := 0 to GetLevelCount(dS)-1 do
    begin
      GetEntry(dS, dL, aFilename, aFileIndex);
      aInfo.DosLevelPackFileName := aFilename;
      aInfo.DosLevelPackIndex := aFileIndex;
      LoadSingleLevel(aFileIndex, dS, dL, aLevel, SoftOddMode);
      TLVLLoader.SaveLevelToFile(aLevel, ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\' + LeadZeroStr(dS + 1, 2) + LeadZeroStr(dL + 1, 2) + '.lvl');
    end;
except
end;

  aInfo.Free;
  aLevel.Free;
  fLookForLVL := OldLookForLvls;

end;

function TBaseDosLevelSystem.EasyGetSectionName(aSection: Integer): string;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    GetSections(L);
    Result := L[aSection];
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindCheatCode(const aCode: string;
  var Rec: TDosGamePlayInfoRec; CheatsEnabled: Boolean = true): Boolean;
var
  //Sec, Lev: Integer;
  P, i, L: Integer;
  Comp, Comp2: string;
  List: TStringList;
begin
  // cheat: "fun19" works too
  Result := false;
  Comp := LowerCase(StringReplace(aCode, '.', '', [rfReplaceAll]));
  List := TStringList.Create;
  try
  GetSections(List);
  for i := 0 to List.Count - 1 do
  begin
    P := pos(lowercase(list[i]), Comp);
    if P <> 1 then
      begin
      Comp2 := Comp;
      P := pos(LeadZeroStr((i+1), 2), Comp);
      Comp := lowercase(list[i]) + copy(Comp, 3, 3);
      end;

    if P = 1 then
    begin
      L := StrToIntDef(copy(Comp, Length(List[i]) + 1, 3), 0);

      if (L >= 1) and (L <= GetLevelCount(i)) then
      begin
      if (((SysDat.Options and $4 <> 0) or (L <= GetLevelCount(i) - GetSecretLevelCount(i))) and
         CheatsEnabled) or
         SaveSystem.CheckUnlocked(i, L-1)
          then
      begin
        with Rec do
        begin
          dValid := True;
          dPack := 0;
          dSection := i;
          dLevel := L - 1;
          dSectionName := List[i]
        end;
        Result := True;
        Exit;
      end;
      end;
    end else
      Comp := Comp2;
  end;
  finally
    List.Free;
  end;

end;

function TBaseDosLevelSystem.FindFirstLevel(var Rec: TDosGamePlayInfoRec): Boolean;
var
  L: TStringList;
begin
  Result := True;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      //if dSection >= 0
      //dSection       := 0;
      dLevel         := 0;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindLastUnlockedLevel(var Rec: TDosGamePlayInfoRec): Boolean;
// Somewhat misleading name. It finds the first level that is unlocked but not completed.
var
  L: TStringList;
  i: Integer;
begin
  Result := True;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      //if dSection >= 0
      //dSection       := 0;
      dLevel         := 0;
      for i := 0 to GetLevelCount(dSection) - 1 do
      begin
        if SaveSystem.CheckUnlocked(dSection, i)  then
        begin
          dLevel := i;
          if not SaveSystem.CheckCompleted(dSection, i) then Break;
        end;
      end;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindNextUnlockedLevel(var Rec: TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean;
var
  L: TStringList;
  i, odLevel: Integer;
begin
  Result := True;
  if GetLevelCount(Rec.dSection) = 1 then Exit;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      odLevel := dLevel;
      i := dLevel - 1;
      //for i := (GetLevelCount(dSection) - 1) downto (dLevel + 1) do
      while i <> odLevel do
      begin
        if SaveSystem.CheckUnlocked(dSection, i) or (CheatMode) then dLevel := i;
        dec(i);
        if i < 0 then i := GetLevelCount(dSection) - 1;
      end;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindPreviousUnlockedLevel(var Rec: TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean;
var
  L: TStringList;
  i, odLevel: Integer;
begin
  Result := True;
  if GetLevelCount(Rec.dSection) = 1 then Exit;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      //if dSection >= 0
      //dSection       := 0;
      odLevel := dLevel;
      i := dLevel + 1;
      //for i := 0 to dLevel - 1 do
      while i <> odLevel do
      begin
        if SaveSystem.CheckUnlocked(dSection, i) or CheatMode  then dLevel := i;
        inc(i);
        if i >= GetLevelCount(dSection) then i := 0;
      end;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindLevel(var Rec: TDosGamePlayInfoRec): Boolean;
begin
  with Rec do
  begin
    Result := (dPack = 0) and (dSection >= 0) and (dSection < fDefaultSectionCount) and
    (dLevel >= 0) and (dLevel < GetLevelCount(dSection));
    dValid := Result;
    if not Result then
      Exit;
    dSectionName := EasyGetSectionName(dSection);
  end;
end;

function TBaseDosLevelSystem.FindLevelCode(const aCode: string; var Rec: TDosGamePlayInfoRec): Boolean;
var
  Sec, Lev: Integer;
  //P, i, L: Integer;
  Code: string;
  //List: TStringList;
begin
  Result := False;

  if Length(aCode) <> 10 then
    Exit;

  for Sec := 0 to fDefaultSectionCount-1 do
    for Lev := 0 to GetLevelCount(Sec) do
    begin
      Code := GenCode(SysDat.CodeSeed, Sec, Lev);



      if CompareText(Code, aCode) = 0 then
      begin
        Result := True;
        Rec.dValid := True;
        Rec.dPack := 0;
        Rec.dSection := Sec;
        Rec.dLevel := Lev;
        Rec.dSectionName := EasyGetSectionName(Sec);
        Exit;
      end;
    end;
end;

function TBaseDosLevelSystem.FindFinalLevel(var Rec: TDosGamePlayInfoRec): Boolean;
var
  L: TStringList;
begin
  Result := True;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      //if dSection >= 0
      dSection       := fDefaultSectionCount - 1;
      while GetLevelCount(dSection) <= GetSecretLevelCount(dSection) do Dec(dSection);
      dLevel         := GetLevelCount(dSection) - 1 - GetSecretLevelCount(dSection);
      //dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindNextLevel(var Rec: TDosGamePlayInfoRec; Secret: Integer = -1; Overrider: Integer = -1): Boolean;
var
  L: TStringList;
  STe1, STe2: Byte;
  KT: TDosGamePlayInfoRec;
begin
  Result := (Rec.dLevel < GetLevelCount(Rec.dSection) - GetSecretLevelCount(Rec.dSection)) or (Rec.dSection < fDefaultSectionCount - 1);

  Rec.dValid := False;
  //if not Result then
  //  Exit;


  if (Rec.dLevel >= GetLevelCount(Rec.dSection) - GetSecretLevelCount(Rec.dSection)) and (Secret = -1) then
    begin
      Secret := Overrider;
      STe1 := Secret shr 8;
      STe2 := Secret mod 256;
      //if STe1 = 0 then STe1 := Rec.dSection + 1;
      //if STe2 = 0 then STe2 := GetLevelCount(Rec.dSection) - GetSecretLevelCount(Rec.dSection) + 1;
      //Dec(STe1);
      //Dec(STe2);
      Rec.dSection := STe1;
      Rec.dLevel := STe2;
      Rec.dValid := True;
      L := TStringList.Create;
      GetSections(L);
      Rec.dSectionName := L[Rec.dSection];
      Rec.dValid := True;
    end
    else if Secret <> -1 then
    begin
      STe1 := trunc(Secret / 256);
      STe2 := Secret mod 256;
      if STe1 = 0 then STe1 := Rec.dSection + 1;
      if STe2 = 0 then STe2 := GetLevelCount(Rec.dSection) - GetSecretLevelCount(Rec.dSection) + 1;
      Dec(STe1);
      Dec(STe2);
      Rec.dSection := STe1;
      Rec.dLevel := STe2;
      Rec.dValid := True;
      L := TStringList.Create;
      GetSections(L);
      Rec.dSectionName := L[Rec.dSection];
    end
    else begin


  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      FindFinalLevel(KT);
      dValid         := True;
      dPack          := 0;

      if (dSection = KT.dSection) and (dLevel = KT.dLevel) then
      begin
        dLevel := 0;
        dSection := 0;
      end else begin
        Inc(dLevel); // this can lead to a overflow so...
        if dLevel >= GetLevelCount(dSection)-GetSecretLevelCount(dSection)  then
        begin
          dLevel := 0;
          Inc(dSection); // this can lead to a overflow so...
          if dSection >= fDefaultSectionCount then
            dSection := 0;
        end;
      end;
      dSectionName   := L[dSection];

      {if dSection = 5 then
      begin
        if dLevel = 1 then
          begin
          dSection := 0;
          dLevel := 0;
          dSectionName := L[dSection];
          end;
      end;}
      //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
  end;
end;

function TBaseDosLevelSystem.GetLevelPackPrefix;
begin
  Result := 'LEVEL';
  // this is here because older versions used different filenames for some players, eg. OhNo used DLVEL, LPII used LP2LV, etc
  // as of V1.33n they all use LEVEL
end;

procedure TBaseDosLevelSystem.GetEntry(aSection, aLevel: Integer; var aFileName: string;
  var aFileIndex: Integer);
{-------------------------------------------------------------------------------
  This method must return information on where to get a level from
-------------------------------------------------------------------------------}
var
  FnPrefix : String;
begin
  FnPrefix := GetLevelPackPrefix;
  aFileName := FnPrefix + LeadZeroStr(aSection, 3) + '.DAT';
  afileIndex := aLevel;
end;

function TBaseDosLevelSystem.GetLevelCode(const Rec: TDosGamePlayInfoRec): string;
begin
  Result := GenCode(SysDat.CodeSeed, Rec.dSection, Rec.dLevel);
end;

function TBaseDosLevelSystem.GetLevelCount(aSection: Integer): Integer;
var
  Dcmp : TDosDatDecompressor;
  FSt : TMemoryStream;
  FSl : TDosDatSectionList;
  Dcr : TNeoEncryption;
begin
  Result := fLevelCount[aSection];
  if Result <> -1 then Exit;
  Fst := CreateDataStream(GetLevelPackPrefix + LeadZeroStr(aSection, 3) + '.dat', ldtLemmings);
  Dcmp := TDosDatDecompressor.Create;
  Fsl := TDosDatSectionList.Create;
  Dcr := TNeoEncryption.Create;
  try
    if Dcr.CheckEncrypted(Fst) then
      Dcr.LoadStream(Fst);
    Dcmp.LoadSectionList(Fst, Fsl, False);
    Result := Fsl.Count;
    fLevelCount[aSection] := Result;
  finally
    Fst.Free;
    Dcmp.Free;
    Fsl.Free;
    Dcr.Free;
  end;
end;

function TBaseDosLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 0;
end;

function TBaseDosLevelSystem.GetSectionCount: Integer;
// we could overwrite this function with a faster one but maybe we are
// to lazy :)
var
  Dummy: TStringList;
begin
//  Result := 0;
  Dummy := TStringList.Create;
  try
    GetSections(Dummy);
    Result := Dummy.Count;
  finally
    Dummy.Free;
  end;
end;

procedure TBaseDosLevelSystem.GetSections(aSectionNames: TStrings);
begin
  raise Exception.Create(ClassName + '.GetSections is abstract');
end;

procedure TBaseDosLevelSystem.InternalLoadLevel(aInfo: TLevelInfo; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------

  NB: a little moving/messing around here with mem
-------------------------------------------------------------------------------}
var
  //LVL: TLVLRec;
  //Ox: Integer;
  DataStream: TMemoryStream;
  Sections: TDosDatSectionList;
  Decompressor: TDosDatDecompressor;
  TheSection: TDosDatSection;
  NeoEncrypt: TNeoEncryption;
begin
  Assert(Owner is TBaseDosLemmingStyle);

  Sections := TDosDatSectionList.Create;
  Decompressor := TDosDatDecompressor.Create;
  NeoEncrypt := TNeoEncryption.Create;
  try
    DataStream := CreateDataStream(aInfo.DosLevelPackFileName, ldtLemmings);
    if NeoEncrypt.CheckEncrypted(DataStream) then
      NeoEncrypt.LoadStream(DataStream);
    try
      Decompressor.LoadSectionList(DataStream, Sections, False);
    finally
      DataStream.Free;
    end;
    //Decompressor.LoadSectionListFromFile(aInfo.DosLevelPackFileName, Sections, False);
    TheSection := Sections[aInfo.DosLevelPackIndex];
    with TheSection do
    begin
      Decompressor.DecompressSection(CompressedData, DecompressedData);
      DecompressedData.Seek(0, soFromBeginning);
      //DecompressedData.ReadBuffer(LVL, SizeOf(LVL));
      //DecompressedData.Seek(0, soFromBeginning);
    end;

    TLVLLoader.LoadLevelFromStream(TheSection.DecompressedData, aLevel, OddLoad);



  finally
    NeoEncrypt.Free;
    Decompressor.Free;
    Sections.Free;
  end;

end;

procedure TBaseDosLevelSystem.InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Method for loading one level, without the preparing caching system.
-------------------------------------------------------------------------------}
var
  LocalSectionNames: TStringList;
  Fn: string;
  //IsOdd: Boolean;
  //OddIndex: Integer;
  FileIndex: Integer;
  Sty: TBaseDosLemmingStyle;
  LocalLevelInfo: TLevelInfo;

var
  F: TMemoryStream;
  IsLoaded: Boolean;
  Enc: TNeoEncryption;

begin
  Assert(Owner is TBaseDosLemmingStyle);

  IsLoaded := False;

  // added override on demand (look for tricky21 = 221.lvl)

  if fLookForLVL or fTestMode
  or (fOneLvlString <> '') then
  begin
    FN := ExtractFilePath(GameFile) + LeadZeroStr(aSection + 1, 2) + LeadZeroStr(aLevelIndex + 1, 2) + '.LVL';
    if fOneLvlString <> '' then
      FN := fOneLvlString;

    if fTestMode then FN := fTestLevel;

    if FileExists(FN) then
    begin
      F := TMemoryStream.Create;
      F.LoadFromFile(FN);
      Enc := TNeoEncryption.Create;
      try
        if Enc.CheckEncrypted(F) then
          Enc.LoadStream(F);
        TLVLLoader.LoadLevelFromStream(F, aLevel, OddLoad);
        if (((aLevel.Info.LevelOptions) and 16) <> 0) and (OddLoad <> 2) then
          InternalLoadSingleLevel((aLevel.Info.fOddtarget shr 8), (aLevel.Info.fOddtarget mod 256), aLevel, 1);
        IsLoaded := True;
      finally
        F.Free;
        Enc.Free;
      end;
    end;
  end;

  if IsLoaded then
    Exit;

  // back to the normal procedure here

  LocalSectionNames := TStringList.Create;
  Sty := TBaseDosLemmingStyle(Owner);
  LocalLevelInfo := TLevelInfo.Create(nil);

  TRY

  GetSections(LocalSectionNames);

  FileIndex := -1;
  Fn := '';
  GetEntry(aSection, aLevelIndex, Fn, FileIndex);
  Fn := Sty.CommonPath + Fn;//IncludeCommonPath(Fn);

  LocalLevelInfo.DosLevelPackFileName := Fn;
  LocalLevelInfo.DosLevelPackIndex := FileIndex;

  InternalLoadLevel(LocalLevelInfo, aLevel, OddLoad);
  if (((aLevel.Info.LevelOptions) and 16) <> 0) and (OddLoad <> 2) then
    InternalLoadSingleLevel((aLevel.Info.fOddtarget shr 8), (aLevel.Info.fOddtarget mod 256), aLevel, 1);
  FINALLY
  
  LocalSectionNames.Free;
  LocalLevelInfo.Free;

  END;

end;

procedure TBaseDosLevelSystem.InternalPrepare;
begin

  raise Exception.Create('Internal Prepare not implemented');

end;

{ TDosOrigLevelLoader }

procedure TDosOrigLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Fun,Tricky,Taxing,Mayhem,2P';
end;

function TDosOrigMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((aLevel mod 17) + 1, 2);
end;



function TDosOhNoMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 6 + 1, 2);
end;

procedure TDosOhNoLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Tame,Crazy,Wild,Wicked,Havoc,2P';
end;






procedure TDosLPDOSLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Mild,Wimpy,Medi,Danger,PSYCHO,PreV7';
end;

function TDosLPDOSMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((aLevel mod 17) + 1, 2);
end;







function TDosLPIIMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 6 + 1, 2);
  if aLevel = 20 then
    Result := 'track_' + LeadZeroStr(aSection mod 6 + 1, 2);
end;

function TDosLPIILevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 1;
end;

procedure TDosLPIILevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Nice,Cheeky,Sneaky,Cunning,Genius';
end;




function TDosLP2BMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 6 + 1, 2);
end;

function TDosLP2BLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 0;
  if aSection in [1, 3] then Result := 1;
end;

procedure TDosLP2BLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Trial,Challenge,Reverse,Flight,Rush';
end;





function TDosLPIIIMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 7 + 1, 2);
end;

function TDosLPIIILevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 2;
  if (aSection = 1) then Result := 3;
end;

procedure TDosLPIIILevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Timid,Dodgy,Rough,Fierce';
end;




function TDosLP3BMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 7 + 1, 2);
end;

function TDosLP3BLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 0;
  if aSection = 5 then Result := 7;
end;

procedure TDosLP3BLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Breather,Rehash,Moonwalk,Teamwork,Party,Secret';
end;



function TDosLPIVMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 5 + 1, 2);
end;

function TDosLPIVLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 0;
end;

procedure TDosLPIVLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Smooth,Bumpy,Twisted,Insane';
end;



function TDosLPZMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 15 + 1, 2);
end;

procedure TDosLPZLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Breezy,Puzzling,Perplexing,Mental,Playtime';
end;





function TDosH94MusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 3 + 1, 2);
end;

procedure TDosH94LevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Frost,Hail,Flurry,Blitz';
end;



function TDosCustMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Randomize;
  Result := 'track_' + LeadZeroStr(Random(23) + 1, 2);
end;

function TDosCustLevelSystem.GetLevelCount(aSection: Integer): Integer;
begin
  Result := 3;
end;

function TDosCustLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := 1;
end;

procedure TDosCustLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Step1,Step2,Step3,Step4,Step5';
end;


procedure TDosFlexiLevelSystem.LoadSystemInfo();
var
  fMainDatExtractor : TMainDatExtractor;
begin
  fMainDatExtractor := TMainDatExtractor.Create;
  fMainDatExtractor.FileName := LemmingsPath + 'main.dat';
  SysDat := fMainDatExtractor.GetSysData;
  fMainDatExtractor.free;
end;

function TDosFlexiMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((aLevel mod MusicCount) + 1, 2);
end;

function TDosFlexiLevelSystem.GetSecretLevelCount(aSection: Integer): Integer;
begin
  Result := SysDat.SecretLevelCounts[aSection]; //RankLevels[aSection].SLvlCount;
end;

procedure TDosFlexiLevelSystem.GetSections(aSectionNames: TStrings);
var
  x : byte;
begin
  aSectionNames.CommaText := '';
  for x := 0 to (SysDat.RankCount - 1) do
  begin
    aSectionNames.Add(GetRankName(x));
    {aSectionNames.CommaText := aSectionNames.CommaText + GetRankName(x);
    if x <> (SysDat.RankCount - 1) then aSectionNames.CommaText := aSectionNames.CommaText + ','};
  end;
end;

function TDosFlexiLevelSystem.GetRankName(aSection: Byte): String;
var
  tstr : String;
  x : byte;
begin
  for x := 0 to 15 do
  begin
    if (tstr <> '') or (SysDat.RankNames[aSection][x] <> ' ') then
    begin
      tstr := tstr + SysDat.RankNames[aSection][x];
      if SysDat.RankNames[aSection][x] <> ' ' then Result := tstr;
    end;
  end;
end;



function TDosCovoxMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((((aSection * 2) + aLevel) mod 17) + 1, 2);
end;

procedure TDosCovoxLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Fun,Tricky,Taxing,Mayhem';
end;


function TDosPrimaMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((((aSection * 4) + aLevel) mod 17) + 1, 2);
end;

procedure TDosPrimaLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Fun,Tricky,Taxing,Mayhem';
end;




function TDosXmasMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 3 + 1, 2);
end;

procedure TDosXmasLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Xmas91,Xmas92';
end;


function TDosExtraMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(((aLevel + 2) * (aSection + 1)) mod 23 + 1, 2);
end;

procedure TDosExtraLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Genesis,Present,Sunsoft,Genesis2P,Sega,PSP,Other';
end;


function TDosLPHMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr(aLevel mod 6 + 1, 2);
end;

procedure TDosLPHLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Glimmer,Arctic';
end;



function TDosLPCMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_01';
end;

procedure TDosLPCLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Easy,Medium,Hard,Extreme';
end;


function TDosZombieMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((((aSection * 5) + aLevel) mod 2) + 1, 2);
end;

procedure TDosZombieLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Outbreak,Plague,Apocalypse';
end;

procedure TDosCopycatLevelSystem.GetSections(aSectionNames: TStrings);
begin
  aSectionNames.CommaText := 'Fun,Tricky,Taxing,Mayhem';
end;

function TDosCopycatMusicSystem.GetMusicFileName(aPack, aSection, aLevel: Integer): string;
begin
  Result := 'track_' + LeadZeroStr((aLevel mod 17) + 1, 2);
end;


end.

