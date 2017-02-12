{$include lem_directives.inc}
unit LemDosStyle;

interface

uses
  Classes,
  UMisc,
  GR32,
  SharedGlobals,
  Dialogs, Controls,
  LemTypes, LemLevel, LemLVLLoader,
  LemMetaAnimation, LemAnimationSet, LemDosCmp, LemDosStructures, LemDosAnimationSet,
  LemDosMainDat,
  LemStyle, LemLevelSystem, LemMusicSystem,
  LemNeoSave,
  LemNeoParserOld,
  LemNeoParser,
  LemRendering, PngInterface, // for image mass dump, yeah, finally moved it to here :D
  UZip; // For checking whether files actually exist

type
  TBaseDosLemmingStyle = class(TBaseLemmingStyle)
  private
    fMainDataFile: string;
    function GetAnimationSet: TBaseDosAnimationSet;
  protected
    function DoCreateAnimationSet: TBaseAnimationSet; override;
  public
    procedure LoadSystemDat;
    property AnimationSet: TBaseDosAnimationSet read GetAnimationSet; // get it typed
  published
    property MainDataFile: string read fMainDataFile write fMainDataFile; // default main.dat
  end;

  TDosFlexiStyle = class(TBaseDosLemmingStyle)
  public
    SysDat : TSysDatRec;
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
  private
    fLevelNames: array of array of String;
    fTempLevel: TLevel;
    fDoneQuickLevelNameLoad: Boolean;
  protected
    fDefaultLevelCount: Integer;
    fLevelCount : array[0..15] of Integer;
    fLookForLVL: Boolean; // looks for user-overridden lvl-files on disk
  { overridden from base loader }
    procedure InternalLoadLevel(aInfo: TLevelInfo; aLevel: TLevel; OddLoad: Byte = 0); override;
    procedure InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0); override;
    function EasyGetSectionName(aSection: Integer): string;
  public
    fDefaultSectionCount: Integer; // initialized at creation
    SysDat : TSysDatRec;
    fTestMode: Boolean;
    fTestLevel: String;
    fOneLvlString: String;
    constructor Create(aOwner: TPersistent);
    destructor Destroy; override;
  { these methods must be overridden by derived dos loaders }
    procedure GetSections(aSectionNames: TStrings); virtual;
    procedure GetEntry(aSection, aLevel: Integer; var aFileName: string; var aFileIndex: Integer);
    function GetLevelPackPrefix: String;
    function GetLevelCount(aSection: Integer): Integer; virtual; //override;
    function GetSectionCount: Integer; virtual;
    function GetLevelName(aSection, aLevel: Integer): String;
    procedure DumpAllLevels;
    procedure DumpAllImages;

    //For the time being it is not needed to virtualize this into a higher class.
    function FindFirstLevel(var Rec: TDosGamePlayInfoRec): Boolean; override;
    function FindNextLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindFinalLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindFirstUnsolvedLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindNextUnsolvedLevel(var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindPreviousUnsolvedLevel(var Rec : TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean; override;

    procedure QuickLoadLevelNames;

    function FindLevelCode(const aCode: string; var Rec : TDosGamePlayInfoRec): Boolean; override;
    function FindCheatCode(const aCode: string; var Rec : TDosGamePlayInfoRec; CheatsEnabled: Boolean = true): Boolean; override;

    property LookForLVL: Boolean read fLookForLVL write fLookForLVL;
  end;

  TDosFlexiLevelSystem = class(TBaseDosLevelSystem)
  private
  public
    procedure LoadSystemInfo();
    procedure GetSections(aSectionNames: TStrings); override;
    function GetRankName(aSection: Byte): String;
  end;

  TDosFlexiMusicSystem = class(TBaseMusicSystem)
  private
  protected
  public
    MusicCount : Byte;
    function GetMusicFileName(aPack, aSection, aLevel: Integer): string; override;
  end;

function GenCode(aRandseed, aSection, aLevel: Integer): string;

function AutoCreateStyle(const aDirectory: string; aSysDat: TSysDatRec): TBaseDosLemmingStyle;
function CreateDosFlexiStyle(const aDirectory: string; aSysDat: TSysDatRec): TDosFlexiStyle;

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
  Result := 0;
end;

function GenCode(aRandseed, aSection, aLevel: Integer): string;
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
  i: Integer;
  c : Char;
  DoMedeKlinker: Boolean;
  TempStream: TMemoryStream;
  SL: TStringList;
  Arc: TArchive; // for checking whether files actually exist
begin
  Arc := TArchive.Create;
  if Arc.CheckIfFileExists('codes.txt') then
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
  end;
  Arc.Free;

  // never change this
  LemRandseed := (aLevel div 99) * 1000000 + aRandseed * 10000 + (aSection + 1) * 100 + ((aLevel mod 99) + 1);

  Result := StringOfChar(' ', 10);

  DoMedeKlinker := Boolean(LemRandom(2)); // init on random
  for i := 1 to 10 do
  begin
    C := RndChar(DoMedeKlinker);
    DoMedeKlinker := not DoMedeKlinker;
    Result[i] := c;
  end;
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

function AutoCreateStyle(const aDirectory: string; aSysDat: TSysDatRec): TBaseDosLemmingStyle;
begin
  Result := CreateDosFlexiStyle(aDirectory, aSysDat);
  Assert(Result <> nil);
end;

{ TBaseDosLemmingStyle }

procedure TBaseDosLemmingStyle.LoadSystemDat;
var
  SysDatFile: TMemoryStream;
begin
  SysDatFile := CreateDataStream('system.dat', ldtLemmings);
  SysDatFile.Seek(0, soFromBeginning);
  SysDatFile.ReadBuffer(SysDat, SYSDAT_SIZE);
  SysDatFile.Free;
end;

function TBaseDosLemmingStyle.DoCreateAnimationSet: TBaseAnimationSet;
begin
  Result := TBaseDosAnimationSet.Create;
end;

function TBaseDosLemmingStyle.GetAnimationSet: TBaseDosAnimationSet;
begin
  Result := TBaseDosAnimationSet(fAnimationSet);
end;

function TDosFlexiStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := TDosFlexiLevelSystem.Create(Self);
end;

function TDosFlexiStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := TDosFlexiMusicSystem.Create;
end;

{ TBaseDosLevelSystem }

constructor TBaseDosLevelSystem.Create(aOwner: TPersistent);
var
  i: integer;
begin
  inherited;
  fTempLevel := TLevel.Create;
  fDefaultSectionCount := GetSectionCount;
  fDefaultLevelCount := GetLevelCount(0);
  for i := 0 to 15 do
    fLevelCount[i] := -1;
end;

destructor TBaseDosLevelSystem.Destroy;
begin
  fTempLevel.Free;
  inherited;
end;

procedure TBaseDosLevelSystem.DumpAllImages;
var
  aInfo: TLevelInfo;
  aLevel: TLevel;
  dS, dL: Integer;
  aFileName: String;
  aFileIndex: Integer;
  OldLookForLvls: Boolean;
  BasePath: String;
  FilePath: String;

  Renderer: TRenderer;
  RenderInfo: TRenderInfoRec;

  BMP: TBitmap32;
begin
  OldLookForLvls := fLookForLVL;
  fLookForLVL := false;
  aInfo := TLevelInfo.Create(nil);
  aLevel := TLevel.Create;
  Renderer := TRenderer.Create;
  BMP := TBitmap32.Create;

  try
    if not ForceDirectories(ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\') then Exit;

    BasePath :=   AppPath + 'Dump\'
              + ChangeFileExt(ExtractFileName(GameFile), '')
              + '\';

    for dS := 0 to fDefaultSectionCount-1 do
      for dL := 0 to GetLevelCount(dS)-1 do
      begin

        GetEntry(dS, dL, aFilename, aFileIndex);
        aInfo.DosLevelPackFileName := aFilename;
        aInfo.DosLevelPackIndex := aFileIndex;
        LoadSingleLevel(aFileIndex, dS, dL, aLevel);

        RenderInfo.Level := aLevel;
        Renderer.PrepareGameRendering(RenderInfo);
        Renderer.RenderWorld(BMP, true);

        FilePath := BasePath + LeadZeroStr(dS + 1, 2) + LeadZeroStr(dL + 1, 2) + '.png';

        TPngInterface.SavePngFile(FilePath, BMP);

      end;

  except
  end;

  aInfo.Free;
  aLevel.Free;
  Renderer.Free;
  fLookForLVL := OldLookForLvls;
  BMP.Free;

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
  BasePath: String;
  FilePath: String;
  FileStream: TFileStream;

  n: Integer;
  Suffix: String;

  Parser: TParser;
  MainSec: TParserSection;
  Sec: TParserSection;

  SubParser: TParser;
  SubMainSec: TParserSection;
begin
  OldLookForLvls := fLookForLVL;
  fLookForLVL := false;
  aInfo := TLevelInfo.Create(nil);
  aLevel := TLevel.Create;
try
  if not ForceDirectories(ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\') then Exit;
  SoftOddMode := true;
  if not SoftOddMode then
    SoftOddMode := MessageDlg('Hard-apply oddtabling to dumped levels?', mtCustom, [mbYes, mbNo], 0) = mrNo
    else
    SoftOddMode := false;

  BasePath :=   AppPath + 'Dump\'
            + ChangeFileExt(ExtractFileName(GameFile), '')
            + '\';

  Parser := TParser.Create;
  MainSec := Parser.MainSection;

  for dS := 0 to fDefaultSectionCount-1 do
  begin
    Sec := MainSec.SectionList.Add('RANK');
    Sec.AddLine('NAME', EasyGetSectionName(dS));
    Sec.AddLine('FOLDER', MakeSuitableForFilename(EasyGetSectionName(dS)));

    ForceDirectories(BasePath + MakeSuitableForFilename(EasyGetSectionName(dS)));

    SubParser := TParser.Create;
    SubMainSec := SubParser.MainSection;

    for DL := 0 to GetLevelCount(dS)-1 do
    begin

      GetEntry(dS, dL, aFilename, aFileIndex);
      aInfo.DosLevelPackFileName := aFilename;
      aInfo.DosLevelPackIndex := aFileIndex;
      LoadSingleLevel(aFileIndex, dS, dL, aLevel, SoftOddMode);
      FilePath := BasePath + MakeSuitableForFilename(EasyGetSectionName(dS)) + '\' + Trim(MakeSuitableForFilename(aLevel.Info.Title));

      n := 0;
      Suffix := '';

      while FileExists(FilePath + Suffix + '.nxlv') do
      begin
        Inc(n);
        Suffix := LeadZeroStr(n, 2);
      end;

      FilePath := FilePath + Suffix + '.nxlv';

      SubMainSec.AddLine('LEVEL', ExtractFileName(FilePath));

      FileStream := TFileStream.Create(FilePath, fmCreate);
      try
        aLevel.SaveToStream(FileStream);
      finally
        FileStream.Free;
      end;

    end;

    SubParser.SaveToFile(BasePath + MakeSuitableForFilename(EasyGetSectionName(dS)) + '\levels.nxmi');
    SubParser.Free;
  end;

  Parser.SaveToFile(BasePath + 'levels.nxmi');
  Parser.Free;
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
      dLevel         := 0;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindFirstUnsolvedLevel(var Rec: TDosGamePlayInfoRec): Boolean;
var
  L: TStringList;
  i: Integer;
  FoundLevel: Boolean;
begin
  Result := True;
  FoundLevel := false;
  L := TStringList.Create;
  try
    GetSections(L);
    with Rec do
    begin
      dValid         := True;
      dPack          := 0;
      dLevel         := 0;
      for i := 0 to GetLevelCount(dSection) - 1 do
      begin
        dLevel := i;
        if not SaveSystem.CheckCompleted(dSection, i) then
        begin
          FoundLevel := true;
          Break;
        end;
      end;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;

  if not FoundLevel then Rec.dLevel := 0; // go to first level if all available levels are completed
end;

function TBaseDosLevelSystem.FindNextUnsolvedLevel(var Rec: TDosGamePlayInfoRec): Boolean;
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
      while i <> odLevel do
      begin
        dLevel := i;
        dec(i);
        if i < 0 then i := GetLevelCount(dSection) - 1;
      end;
      dSectionName   := L[dSection]; //#EL watch out for the record-string-mem-leak
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindPreviousUnsolvedLevel(var Rec: TDosGamePlayInfoRec; CheatMode: Boolean = false): Boolean;
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
      i := dLevel + 1;
      while i <> odLevel do
      begin
        dLevel := i;
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
  Code: string;
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
      dSection       := fDefaultSectionCount - 1;
      dLevel         := GetLevelCount(dSection) - 1;
    end;
  finally
    L.Free;
  end;
end;

function TBaseDosLevelSystem.FindNextLevel(var Rec: TDosGamePlayInfoRec): Boolean;
var
  L: TStringList;
  KT: TDosGamePlayInfoRec;
begin
  Result := (Rec.dLevel < GetLevelCount(Rec.dSection)) or (Rec.dSection < fDefaultSectionCount - 1);

  Rec.dValid := False;

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
        if dLevel >= GetLevelCount(dSection) then
        begin
          dLevel := 0;
          Inc(dSection); // this can lead to a overflow so...
          if dSection >= fDefaultSectionCount then
            dSection := 0;
        end;
      end;
      dSectionName   := L[dSection];

    end;
  finally
    L.Free;
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

function TBaseDosLevelSystem.GetLevelCount(aSection: Integer): Integer;
var
  FSt : TMemoryStream;

  Parser: TNeoLemmixParser;
  Line: LemNeoParserOld.TParserLine;
  i: Integer;
begin
  Result := fLevelCount[aSection];
  if Result <> -1 then Exit;

  Fst := CreateDataStream('levels.nxmi', ldtLemmings);

  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromStream(Fst);
    i := 0;
    repeat
      Line := Parser.NextLine;
      if Line.Keyword = 'LEVELCOUNT' then
      begin
        fLevelCount[i] := Line.Numeric;
        if i = aSection then Result := Line.Numeric;
        Inc(i);
      end;
    until (Line.Keyword = '') or (i = GetSectionCount);
  finally
    Fst.Free;
    Parser.Free;
  end;
end;

function TBaseDosLevelSystem.GetSectionCount: Integer;
// we could overwrite this function with a faster one but maybe we are
// to lazy :)
var
  Dummy: TStringList;
begin
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
  DataStream: TMemoryStream;
begin
  Assert(Owner is TBaseDosLemmingStyle);

  DataStream := CreateDataStream(LeadZeroStr(aInfo.DosLevelRankIndex, 2) + LeadZeroStr(aInfo.DosLevelPackIndex, 2) + '.lvl', ldtLemmings);
  TLVLLoader.LoadLevelFromStream(DataStream, aLevel, OddLoad);
end;

procedure TBaseDosLevelSystem.InternalLoadSingleLevel(aSection, aLevelIndex: Integer; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Method for loading one level, without the preparing caching system.
-------------------------------------------------------------------------------}
var
  LocalSectionNames: TStringList;
  Fn: string;
  FileIndex: Integer;
  Sty: TBaseDosLemmingStyle;
  LocalLevelInfo: TLevelInfo;

var
  F: TMemoryStream;
  IsLoaded: Boolean;

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
      try
        TLVLLoader.LoadLevelFromStream(F, aLevel, OddLoad);
        IsLoaded := True;
      finally
        F.Free;
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
  LocalLevelInfo.DosLevelRankIndex := aSection;
  LocalLevelInfo.DosLevelPackIndex := FileIndex;

  InternalLoadLevel(LocalLevelInfo, aLevel, 0);
  FINALLY
  
  LocalSectionNames.Free;
  LocalLevelInfo.Free;

  END;
end;

procedure TBaseDosLevelSystem.QuickLoadLevelNames;
var
  DataStream: TMemoryStream;
  Parser: TNeoLemmixParser;
  Line: LemNeoParserOld.TParserLine;
  R, L: Integer;
begin
  if fDoneQuickLevelNameLoad then Exit;
  fDoneQuickLevelNameLoad := true;

  DataStream := CreateDataStream('levels.nxmi', ldtLemmings);

  L := 0;

  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromStream(DataStream);

    SetLength(fLevelNames, GetSectionCount);
    for R := 0 to GetSectionCount-1 do
      SetLength(fLevelNames[R], GetLevelCount(R));

    R := -1;
    repeat
      Line := Parser.NextLine;
      if (Line.Keyword <> 'LEVEL') and (R = -1) then Continue;

      if Line.Keyword = 'LEVEL' then
      begin
        if Line.Numeric > 9999 then
        begin
          R := Line.Numeric div 1000;
          L := Line.Numeric mod 1000;
        end else begin
          R := Line.Numeric div 100;
          L := Line.Numeric mod 100;
        end;

        if (R > GetSectionCount) or (L > GetLevelCount(R)) then
          R := -1;
      end;

      if Line.Keyword = 'TITLE' then
        fLevelNames[R][L] := Trim(Line.Value);

    until (Line.Keyword = '');
  finally
    Parser.Free;
  end;
end;

function TBaseDosLevelSystem.GetLevelName(aSection, aLevel: Integer): String;
begin
  Result := '';
  QuickLoadLevelNames;
  if (aSection < Length(fLevelNames)) and (aLevel < Length(fLevelNames[aSection])) then
    Result := fLevelNames[aSection][aLevel]
  else
    raise Exception.Create('TBaseDosLevelSystem.GetLevelName called for a non-existant level');
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

procedure TDosFlexiLevelSystem.GetSections(aSectionNames: TStrings);
var
  x : byte;
begin
  aSectionNames.CommaText := '';
  for x := 0 to (SysDat.RankCount - 1) do
  begin
    aSectionNames.Add(GetRankName(x));
  end;
end;

function TDosFlexiLevelSystem.GetRankName(aSection: Byte): String;
begin
  Result := Trim(SysDat.RankNames[aSection]);
end;


end.

