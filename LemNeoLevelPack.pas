unit LemNeoLevelPack;

interface

uses
  System.Generics.Collections, System.Generics.Defaults,
  GR32, CRC32, PngInterface, LemLevel,
  Windows, Dialogs, Classes, SysUtils, StrUtils, Contnrs, Controls, Forms,
  LemTalisman,
  LemStrings, LemTypes, LemNeoParser, LemNeoPieceManager, LemGadgets, LemGadgetsConstants, LemCore,
  UMisc;

type
  TNeoLevelStatus = (lst_None, lst_Attempted, lst_Completed_Outdated, lst_Completed);
  TNeoLevelLoadState = (lls_None, lls_BasicInfo, lls_Full);

const
  STATUS_TEXTS: array[TNeoLevelStatus] of String = ('none', 'attempted', 'outdated', 'completed');

type
  TNeoLevelEntry = class;
  TNeoLevelEntries = class;
  TNeoLevelGroup = class;
  TNeoLevelGroups = class;

  TPostviewCondition = (pvc_Zero, pvc_Absolute, pvc_Relative, pvc_Percent, pvc_RelativePercent);

  TPostviewText = class // class rather than record so it plays nicely with a TObjectList and can create / destroy a TStringList
    private
      fText: TStringList;
      procedure LoadLine(aLine: TParserLine; const aIteration: Integer);
      procedure InterpretCondition(aConditionString: String);
    public
      ConditionType: TPostviewCondition;
      ConditionValue: Integer;
      property Text: TStringList read fText;
      constructor Create;
      destructor Destroy; override;
  end;

  TPostviewTexts = class(TObjectList)
    private
      function GetItem(Index: Integer): TPostviewText;
    public
      constructor Create;
      function Add: TPostviewText;
      property Items[Index: Integer]: TPostviewText read GetItem; default;
      property List;
  end;

  TLevelRecordEntry = record
    Value: Integer;
    User: String;
  end;

  TLevelRecords = record
    LemmingsRescued: TLevelRecordEntry;
    TimeTaken: TLevelRecordEntry;
    TotalSkills: TLevelRecordEntry;
    SkillTypes: TLevelRecordEntry;
    SkillCount: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of TLevelRecordEntry;
    procedure Wipe;
    procedure SetNameOnAll(aName: String);
  end;

  TNeoLevelEntry = class  // This is an entry in a level pack's list, and does NOT contain the level itself
    private
      fGroup: TNeoLevelGroup;

      fLoadState: TNeoLevelLoadState;

      fTitle: String;
      fAuthor: String;
      fFilename: String;
      fTalismans: TObjectList<TTalisman>;

      fLevelID: Int64;

      fStatus: TNeoLevelStatus;
      fUnlockedTalismanList: TList<LongWord>;

      fCRC32: Cardinal;
      fCalculatedCRC: Boolean;

      procedure LoadLevelFileData(aExtent: TNeoLevelLoadState);

      function GetFullPath: String;
      function GetRelativePath: String;
      function GetTitle: String;
      function GetAuthor: String;
      function GetLevelID: Int64;
      function GetGroupIndex: Integer;
      function GetMusicRotationIndex: Integer;
      function GetTalismans: TObjectList<TTalisman>;

      function GetCRC32: Cardinal;

      procedure SetTalismanStatus(aIndex: LongWord; aStatus: Boolean);
      function GetTalismanStatus(aIndex: LongWord): Boolean;

      procedure ValidateTalismans;
    public
      UserRecords: TLevelRecords;
      WorldRecords: TLevelRecords;

      constructor Create(aGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure WriteNewRecords(aRecords: TLevelRecords; aUserRecords: Boolean);
      procedure WipeRecords;

      property Group: TNeoLevelGroup read fGroup;
      property Title: String read GetTitle;
      property Author: String read GetAuthor;
      property Filename: String read fFilename write fFilename;
      property LevelID: Int64 read GetLevelID;
      property Path: String read GetFullPath;
      property RelativePath: String read GetRelativePath;
      property Status: TNeoLevelStatus read fStatus write fStatus;
      property UnlockedTalismanList: TList<LongWord> read fUnlockedTalismanList;
      property Talismans: TObjectList<TTalisman> read GetTalismans;
      property TalismanStatus[Index: LongWord]: Boolean read GetTalismanStatus write SetTalismanStatus;
      property GroupIndex: Integer read GetGroupIndex;
      property MusicRotationIndex: Integer read GetMusicRotationIndex;

      property CRC32: Cardinal read GetCRC32;
  end;

  TNeoLevelGroup = class
    private
      fDisableSaveProgress: Boolean;

      fParentGroup: TNeoLevelGroup;
      fChildGroups: TNeoLevelGroups;
      fLevels: TNeoLevelEntries;

      fEnableSave: Boolean;

      fName: String;
      fAuthor: String;
      fFolder: String;
      fIsBasePack: Boolean;
      fIsOrdered: Boolean;

      fTalismans: TObjectList<TTalisman>;

      fPackTitle: String;
      fPackAuthor: String;
      fPackVersion: String;
      fScrollerList: TStringList;
      fHasOwnScrollerList: Boolean;

      fMusicList: TStringList;
      fHasOwnMusicList: Boolean;

      fPostviewTexts: TPostviewTexts;
      fHasOwnPostviewTexts: Boolean;

      fRandomMusicTemp: String;

      function GetFullPath: String;
      function GetAuthor: String;

      procedure LoadFromMetaInfo(aPath: String = '');
      procedure LoadFromSearchRec;

      procedure LoadLevel(aLine: TParserLine; const aIteration: Integer);
      procedure LoadSubGroup(aSection: TParserSection; const aIteration: Integer);

      procedure Load;

      procedure SetDefaultData;
      procedure LoadScrollerData;
      procedure LoadScrollerDataDefault;
      procedure LoadScrollerSection(aSection: TParserSection; const aIteration: Integer);
      procedure LoadMusicData;
      procedure LoadRandomMusicLine(aLine: TParserLine; const aIteration: Integer);
      procedure LoadMusicLine(aLine: TParserLine; const aIteration: Integer);
      procedure LoadPostviewData;
      procedure LoadPostviewSection(aSection: TParserSection; const aIteration: Integer);

      function GetRecursiveLevelCount: Integer;

      function GetLevelIndex(aLevel: TNeoLevelEntry): Integer;
      function GetGroupIndex(aGroup: TNeoLevelGroup): Integer;
      function GetParentGroupIndex: Integer;

      function GetFirstUnbeatenLevel: TNeoLevelEntry;
      function GetFirstUnbeatenLevelRecursive: TNeoLevelEntry;
      function GetFirstLevelRecursive: TNeoLevelEntry;

      function GetNextGroup: TNeoLevelGroup;
      function GetPrevGroup: TNeoLevelGroup;

      function GetStatus: TNeoLevelStatus;

      function GetTalismans: TObjectList<TTalisman>;
      function GetCompleteTalismanCount: Integer;

      function GetParentBasePack: TNeoLevelGroup;

      {$ifdef exp}
      procedure InternalDumpSuperLemmixWebsiteMetaInfo(Titles: TStringList; Stats: TStringList);
      {$endif}
    public
      constructor Create(aParentGroup: TNeoLevelGroup; aPath: String);
      destructor Destroy; override;

      procedure LoadUserData;
      procedure SaveUserData;

      function FindFile(aName: String): String;

      procedure DumpImages(aPath: String; aPrefix: String = '');
      procedure CleanseLevels(aPath: String; aOutput: TStringList = nil);

      {$ifdef exp}
      procedure DumpSuperLemmixWebsiteMetaInfo(aPath: String);
      {$endif}

      function GetLevelForTalisman(aTalisman: TTalisman): TNeoLevelEntry;
      procedure WipeAllRecords;

      property Parent: TNeoLevelGroup read fParentGroup;
      property ParentBasePack: TNeoLevelGroup read GetParentBasePack;
      property Children: TNeoLevelGroups read fChildGroups;
      property Levels: TNeoLevelEntries read fLevels;
      property LevelCount: Integer read GetRecursiveLevelCount;
      property Status: TNeoLevelStatus read GetStatus;
      property Name: String read fName write fName;
      property Author: String read GetAuthor write fAuthor;
      property IsBasePack: Boolean read fIsBasePack write fIsBasePack;
      property IsOrdered: Boolean read fIsOrdered write fIsOrdered;
      property Folder: String read fFolder write fFolder;
      property Path: String read GetFullPath;
      property PackTitle: String read fPackTitle;
      property PackAuthor: String read fPackAuthor;
      property PackVersion: String read fPackVersion;
      property ScrollerList: TStringList read fScrollerList;
      property MusicList: TStringList read fMusicList;
      property PostviewTexts: TPostviewTexts read fPostviewTexts;

      property Talismans: TObjectList<TTalisman> read GetTalismans;
      property TalismansUnlocked: Integer read GetCompleteTalismanCount;

      property LevelIndex[aLevel: TNeoLevelEntry]: Integer read GetLevelIndex;
      property GroupIndex[aGroup: TNeoLevelGroup]: Integer read GetGroupIndex;
      property ParentGroupIndex: Integer read GetParentGroupIndex;
      property FirstUnbeatenLevel: TNeoLevelEntry read GetFirstUnbeatenLevel;
      property FirstUnbeatenLevelRecursive: TNeoLevelEntry read GetFirstUnbeatenLevelRecursive;
      property FirstLevelRecursive: TNeoLevelEntry read GetFirstLevelRecursive;

      property PrevGroup: TNeoLevelGroup read GetPrevGroup;
      property NextGroup: TNeoLevelGroup read GetNextGroup;

      property EnableSave: Boolean read fEnableSave write fEnableSave;
  end;


  // Lists //

  TNeoLevelEntries = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelEntry;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add: TNeoLevelEntry;
      property Items[Index: Integer]: TNeoLevelEntry read GetItem; default;
      property List;
  end;

  TNeoLevelGroups = class(TObjectList)
    private
      fOwner: TNeoLevelGroup;
      function GetItem(Index: Integer): TNeoLevelGroup;
    public
      constructor Create(aOwner: TNeoLevelGroup);
      function Add(aFolder: String): TNeoLevelGroup;
      property Items[Index: Integer]: TNeoLevelGroup read GetItem; default;
      property List;
  end;

  function SortAlphabetical(Item1, Item2: Pointer): Integer;

var
  DumpImagesFallbackFlag: Boolean;

implementation

uses
  GameControl, Math, UITypes;

function SortAlphabetical(Item1, Item2: Pointer): Integer;
var
  G1: TNeoLevelGroup;
  G2: TNeoLevelGroup;
  L1: TNeoLevelEntry;
  L2: TNeoLevelEntry;
  S1: String;
  S2: String;
begin
  Result := 0;
  S1 := '';
  S2 := '';

  if (TObject(Item1) is TNeoLevelGroup) and (TObject(Item2) is TNeoLevelGroup) then
  begin
    G1 := TNeoLevelGroup(Item1);
    G2 := TNeoLevelGroup(Item2);
    Result := CompareStr(G1.Name, G2.Name);
  end;

  if (TObject(Item1) is TNeoLevelEntry) and (TObject(Item2) is TNeoLevelEntry) then
  begin
    L1 := TNeoLevelEntry(Item1);
    L2 := TNeoLevelEntry(Item2);
    Result := CompareStr(L1.Title, L2.Title);
  end;
end;


function GetFileAge(FilePath: String): Integer;
var
  DateTime: TDateTime;
begin
  if not FileAge(FilePath, DateTime) then
    DateTime := 32100; // some time in 1987...

  Result := DateTimeToFileDate(DateTime);
end;

{ TPostviewText }

constructor TPostviewText.Create;
begin
  inherited;
  fText := TStringList.Create;
end;

destructor TPostviewText.Destroy;
begin
  fText.Free;
  inherited;
end;

procedure TPostviewText.LoadLine(aLine: TParserLine; const aIteration: Integer);
begin
  Text.Add(aLine.ValueTrimmed);
end;

procedure TPostviewText.InterpretCondition(aConditionString: String);
var
  IsRelative: Boolean;
  IsPercent: Boolean;
begin
  IsRelative := false;
  IsPercent := false;
  if (LeftStr(aConditionString, 1) = '+') or (LeftStr(aConditionString, 1) = '-') then
    IsRelative := true;

  if RightStr(aConditionString, 1) = '%' then
  begin
    aConditionString := LeftStr(aConditionString, Length(aConditionString)-1);
    IsPercent := true;
  end;

  ConditionValue := StrToIntDef(aConditionString, 0);
  if IsRelative then
  begin
    if IsPercent then
      ConditionType := pvc_RelativePercent
    else
      ConditionType := pvc_Relative;
  end else begin
    if IsPercent then
      ConditionType := pvc_Percent
    else
      ConditionType := pvc_Absolute;
  end;
end;

{ TNeoLevelEntry }

constructor TNeoLevelEntry.Create(aGroup: TNeoLevelGroup);
begin
  inherited Create;
  fGroup := aGroup;
  fTalismans := TObjectList<TTalisman>.Create(true);
  fUnlockedTalismanList := TList<LongWord>.Create;

  WipeRecords;
end;

destructor TNeoLevelEntry.Destroy;
begin
  fUnlockedTalismanList.Free;
  fTalismans.Free;
  inherited;
end;

function TNeoLevelEntry.GetTitle: String;
begin
  LoadLevelFileData(lls_BasicInfo);
  Result := fTitle;
end;

function TNeoLevelEntry.GetLevelID: Int64;
begin
  LoadLevelFileData(lls_BasicInfo);
  Result := fLevelID;
end;

function TNeoLevelEntry.GetMusicRotationIndex: Integer;
var
  Pack: TNeoLevelGroup;
  MusicIndex: Integer;

  function CountRecursive(aPack: TNeoLevelGroup): Boolean;
  var
    P, LevelIndex: Integer;
  begin
    for P := 0 to aPack.Children.Count-1 do
      if CountRecursive(aPack.Children[P]) then
        Break;

    LevelIndex := aPack.Levels.IndexOf(self);

    if LevelIndex < 0 then
    begin
      Result := false;
      Inc(MusicIndex, aPack.Levels.Count)
    end else begin
      Result := true;
      Inc(MusicIndex, LevelIndex);
    end;
  end;
begin
  Pack := Group;
  if Pack = nil then
  begin
    Result := 0;
    Exit;
  end;

  while (not Pack.fHasOwnMusicList) and (Pack.Parent <> nil) and (Pack.Parent <> GameParams.BaseLevelPack) do
    Pack := Pack.Parent;

  MusicIndex := 0;
  CountRecursive(Pack);

  Result := MusicIndex;
end;

function TNeoLevelEntry.GetAuthor: String;
begin
  LoadLevelFileData(lls_BasicInfo);
  Result := fAuthor;
end;

function TNeoLevelEntry.GetCRC32: Cardinal;
begin
  if not fCalculatedCRC then
    fCRC32 := CalculateCRC32(Path);

  Result := fCRC32;
end;

procedure TNeoLevelEntry.LoadLevelFileData(aExtent: TNeoLevelLoadState);
var
  Parser: TParser;
  i: Integer;

  TalInfoLevel: TLevel;
  CloneTal: TTalisman;
begin
  if fLoadState >= aExtent then Exit;

  if not FileExists(Path) then
  begin
    MessageDlg('No file at location: ' + Path, mtWarning, [mbOK], 0);
    Exit;
  end;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(Path);

    if aExtent >= lls_BasicInfo then
    begin
      fTitle := Parser.MainSection.LineTrimString['title'];
      fAuthor := Parser.MainSection.LineTrimString['author'];
      fLevelID := Parser.MainSection.LineNumeric['id'];

      if Parser.MainSection.Section['talisman'] <> nil then
      begin
        if (aExtent = lls_Full) then
        begin
          fTalismans.Clear;
          // set talisman.Data to "self"
          TalInfoLevel := TLevel.Create;
          try
            try
              TalInfoLevel.LoadFromFile(Path);
              for i := 0 to TalInfoLevel.Talismans.Count-1 do
              begin
                CloneTal := TTalisman.Create;
                CloneTal.Clone(TalInfoLevel.Talismans[i]);
                fTalismans.Add(CloneTal);
              end;
            except
              // Fail silently.
            end;
          finally
            TalInfoLevel.Free;
          end;
        end;
      end;
    end;

    fLoadState := aExtent;
  finally
    Parser.Free;
  end;
end;

function TNeoLevelEntry.GetFullPath: String;
begin
  if (fGroup = nil) or (Pos(':', fFilename) <> 0) then
    Result := ''
  else
    Result := fGroup.Path;

  Result := Result + fFilename;
end;

function TNeoLevelEntry.GetRelativePath: String;
begin
  Result := Path;

  if LeftStr(Result, Length(AppPath)) = AppPath then
    Result := RightStr(Result, Length(Result) - Length(AppPath));
end;

function TNeoLevelEntry.GetGroupIndex: Integer;
begin
  if fGroup = nil then
    Result := -1
  else
    Result := fGroup.LevelIndex[self];
end;

function TNeoLevelEntry.GetTalismans: TObjectList<TTalisman>;
begin
  LoadLevelFileData(lls_Full);
  Result := fTalismans;
end;

procedure TNeoLevelEntry.SetTalismanStatus(aIndex: Cardinal; aStatus: Boolean);
var
  i: Integer;
begin
  if aStatus then
  begin
    for i := 0 to fUnlockedTalismanList.Count-1 do
      if fUnlockedTalismanList[i] = aIndex then Exit;
    fUnlockedTalismanList.Add(aIndex);
  end else begin
    for i := fUnlockedTalismanList.Count-1 downto 0 do
      if fUnlockedTalismanList[i] = aIndex then
        fUnlockedTalismanList.Delete(i);
  end;
end;

function TNeoLevelEntry.GetTalismanStatus(aIndex: Cardinal): Boolean;
var
  i: Integer;
begin
  Result := false;
  ValidateTalismans;
  for i := 0 to fUnlockedTalismanList.Count-1 do
    if fUnlockedTalismanList[i] = aIndex then
    begin
      Result := true;
      Exit;
    end;
end;

procedure TNeoLevelEntry.ValidateTalismans;
var
  i, i2: Integer;
begin
  LoadLevelFileData(lls_Full);

  for i := fUnlockedTalismanList.Count-1 downto 0 do
    for i2 := 0 to fTalismans.Count do
      if i2 = fTalismans.Count then
        fUnlockedTalismanList.Delete(i)
      else if fTalismans[i2].ID = fUnlockedTalismanList[i] then
        Break;
end;

procedure TNeoLevelEntry.WipeRecords;
begin
  UserRecords.Wipe;
  WorldRecords.Wipe;
end;

procedure TNeoLevelEntry.WriteNewRecords(aRecords: TLevelRecords; aUserRecords: Boolean);
  procedure Apply(var Existing: TLevelRecordEntry; New: TLevelRecordEntry; aHigherIsBetter: Boolean);
  begin
    if New.Value >= 0 then
    begin
      if Existing.Value < 0 then
        Existing := New
      else if (New.Value = Existing.Value) and (Pos(New.User, Existing.User) = 0) then
      begin
        Existing.User := Existing.User + ' & ' + New.User;
        if Length(Existing.User) > 64 then
          Existing.User := 'Many users';
      end else if (aHigherIsBetter and (New.Value > Existing.Value)) or
              ((not aHigherIsBetter) and (New.Value < Existing.Value)) then
        Existing := New;
    end;
  end;
var
  Skill: TSkillPanelButton;
begin
  Apply(WorldRecords.LemmingsRescued, aRecords.LemmingsRescued, true);
  Apply(WorldRecords.TimeTaken, aRecords.TimeTaken, false);
  Apply(WorldRecords.TotalSkills, aRecords.TotalSkills, false);
  Apply(WorldRecords.SkillTypes, aRecords.SkillTypes, false);
  if aUserRecords then
  begin
    Apply(UserRecords.LemmingsRescued, aRecords.LemmingsRescued, true);
    Apply(UserRecords.TimeTaken, aRecords.TimeTaken, false);
    Apply(UserRecords.TotalSkills, aRecords.TotalSkills, false);
    Apply(UserRecords.SkillTypes, aRecords.SkillTypes, false);
  end;

  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
  begin
    Apply(WorldRecords.SkillCount[Skill], aRecords.SkillCount[Skill], false);
    if aUserRecords then
      Apply(UserRecords.SkillCount[Skill], aRecords.SkillCount[Skill], false);
  end;
end;

{ TNeoLevelGroup }

constructor TNeoLevelGroup.Create(aParentGroup: TNeoLevelGroup; aPath: String);
begin
  inherited Create;

  fFolder := aPath;
  if RightStr(fFolder, 1) = '\' then
    fFolder := LeftStr(fFolder, Length(fFolder)-1);
  fName := ExtractFileName(fFolder);

  fChildGroups := TNeoLevelGroups.Create(self);
  fLevels := TNeoLevelEntries.Create(self);
  fParentGroup := aParentGroup;

  fEnableSave := fParentGroup = nil;

  SetDefaultData;
  Load;
end;

destructor TNeoLevelGroup.Destroy;
begin
  fChildGroups.Free;
  fLevels.Free;
  if fHasOwnMusicList and (fMusicList <> nil) then
    fMusicList.Free;
  if fTalismans <> nil then
    fTalismans.Free;
  if fHasOwnScrollerList and (fScrollerList <> nil) then
    fScrollerList.Free;
  inherited;
end;

procedure TNeoLevelGroup.CleanseLevels(aPath: String; aOutput: TStringList = nil);
var
  i: Integer;
  L: TNeoLevelEntry;
  SL: TStringList;

  IsStartingPoint: Boolean;

  procedure RecursiveCopy(aSubPath: String);
  var
    SearchRec: TSearchRec;
    i: Integer;
  begin
    ForceDirectories(aPath + aSubPath);

    if FindFirst(Path + aSubPath + '*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue
        else if (SearchRec.Attr and faDirectory) <> 0 then
          RecursiveCopy(aSubPath + IncludeTrailingPathDelimiter(SearchRec.Name))
        else if Lowercase(SearchRec.Name) = 'levels.nxmi' then
        begin
          SL := TStringList.Create;
          try
            SL.LoadFromFile(Path + aSubPath + SearchRec.Name);
            for i := 0 to SL.Count-1 do
              SL[i] := StringReplace(SL[i], '$RANK', '$GROUP', [rfIgnoreCase, rfReplaceAll]);
            SL.SaveToFile(aPath + aSubPath + SearchRec.Name);
          finally
            SL.Free;
          end;
        end else
          CopyFile(PWideChar(Path + aSubPath + SearchRec.Name), PWideChar(aPath + aSubPath + SearchRec.Name), false);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure CheckForWarnings;
  var
    Level: TLevel;
    Ident: TLabelRecord;
    WrittenAny: Boolean;
    i, n, Cnt, CntGrp: Integer;

    function IsPlaceholder(aIdent: TLabelRecord): Boolean;
    begin
      Result := (Ident.GS = 'default') and (Ident.Piece = 'fallback');
    end;

    procedure Write(aText: String);
    begin
      if not WrittenAny then
      begin
        if aOutput.Count > 0 then
          aOutput.Add('');

        aOutput.Add('WARNINGS for ' + L.Filename);
        WrittenAny := true;
      end;

      aOutput.Add('  ' + aText);
    end;
  begin
    WrittenAny := false;
    Level := GameParams.Level;

    Ident := SplitIdentifier(Level.Info.Background);
    if IsPlaceholder(Ident) then Write('Background replaced with placeholder');

    Cnt := 0;
    for i := 0 to Level.InteractiveObjects.Count-1 do
      if IsPlaceholder(SplitIdentifier(Level.InteractiveObjects[i].Identifier)) then
        Inc(Cnt);
    if Cnt > 0 then Write(IntToStr(Cnt) + ' gadgets replaced with placeholder');

    Cnt := 0;
    CntGrp := 0;
    for i := 0 to Level.Terrains.Count-1 do
      if IsPlaceholder(SplitIdentifier(Level.Terrains[i].Identifier)) then
        Inc(Cnt);
    for i := 0 to Level.TerrainGroups.Count-1 do
      for n := 0 to Level.TerrainGroups[i].Terrains.Count-1 do
        if IsPlaceholder(SplitIdentifier(Level.TerrainGroups[i].Terrains[n].Identifier)) then
        begin
          Inc(Cnt);
          Inc(CntGrp);
        end;
    if Cnt > 0 then Write(IntToStr(Cnt) + ' terrains replaced with placeholder (' + IntToStr(CntGrp) + ' in terrain groups)');
  end;

begin
  if aOutput = nil then
  begin
    IsStartingPoint := true;
    aOutput := TStringList.Create;
  end else
    IsStartingPoint := false;

  if IsStartingPoint then
    RecursiveCopy('');

  aPath := IncludeTrailingPathDelimiter(aPath);

  for i := 0 to Children.Count-1 do
    Children[i].CleanseLevels(aPath + Children[i].Folder, aOutput);

  for i := 0 to Levels.Count-1 do
  begin
    L := Levels[i];
    try
      GameParams.SetLevel(L);
      GameParams.LoadCurrentLevel(true);

      CheckForWarnings;

      GameParams.Level.Info.LevelVersion := GameParams.Level.Info.LevelVersion + 1;
      GameParams.Level.SaveToFile(aPath + ChangeFileExt(L.Filename, '.nxlv'));
      GameParams.Level.Info.LevelVersion := GameParams.Level.Info.LevelVersion - 1; // just in case
    except
      if aOutput.Count > 0 then
        aOutput.Add('');

      aOutput.Add('ERROR cleansing "' + L.Title + '". This level will be copied unmodified.');
    end;
  end;

  if IsStartingPoint then
  begin
    if aOutput.Count > 0 then
    begin
      ShowMessage('Cleanse complete. Some warnings or errors occurred during cleansing. See ' + MakeSafeForFilename(Name) + ' Cleanse Report.txt for more information.');
      aOutput.SaveToFile(AppPath + MakeSafeForFilename(Name) + ' Cleanse Report.txt');
    end else
      ShowMessage('Cleanse complete. No errors or warnings reported.');
    aOutput.Free;
  end;
end;

procedure TNeoLevelGroup.DumpImages(aPath: String; aPrefix: String = '');
var
  i: Integer;
  Output: TBitmap32;
begin
  aPath := IncludeTrailingPathDelimiter(aPath);
  ForceDirectories(aPath);

  for i := 0 to Children.Count-1 do
    Children[i].DumpImages(aPath, LeadZeroStr(i+1, 2));

  if (Children.Count > 0) or IsBasePack then
    aPrefix := '00' + aPrefix;

  Output := TBitmap32.Create;
  try
    for i := 0 to Levels.Count-1 do
    begin
      GameParams.SetLevel(Levels[i]);
      GameParams.LoadCurrentLevel;

      if GameParams.Level.HasAnyFallbacks then
        DumpImagesFallbackFlag := true;

      Output.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);
      GameParams.Renderer.RenderWorld(Output, true);
      TPngInterface.SavePngFile(aPath + aPrefix + LeadZeroStr(i+1, 2) + '.png', Output);
    end;
  finally
    Output.Free;
  end;
end;

{$ifdef exp}
procedure TNeoLevelGroup.DumpSuperLemmixWebsiteMetaInfo(aPath: String);
var
  Ranks: TStringList;
  Titles: TStringList;
  Stats: TStringList;

  procedure AddGroup(Group: TNeoLevelGroup; Prefix: String);
  var
    i: Integer;
  begin
    if not Group.IsBasePack then
    begin
      if Prefix <> '' then
        Prefix := Prefix + ':';
      Prefix := Prefix + Group.Name;
    end;

    for i := 0 to Group.Children.Count-1 do
      AddGroup(Group.Children[i], Prefix);

    if Group.Levels.Count > 0 then
      Ranks.Add(Prefix + '>' + IntToStr(Group.Levels.Count));
  end;
begin
  aPath := IncludeTrailingPathDelimiter(aPath);
  ForceDirectories(aPath);

  Ranks := TStringList.Create;
  Titles := TStringList.Create;
  Stats := TStringList.Create;
  try
    AddGroup(self, '');
    InternalDumpSuperLemmixWebsiteMetaInfo(Titles, Stats);

    Ranks.SaveToFile(aPath + 'ranks.txt');
    Titles.SaveToFile(aPath + 'titles.txt');
    Stats.SaveToFile(aPath + 'stats.txt');
  finally
    Ranks.Free;
    Titles.Free;
    Stats.Free;
  end;
end;

procedure TNeoLevelGroup.InternalDumpSuperLemmixWebsiteMetaInfo(Titles: TStringList; Stats: TStringList);
var
  i: Integer;

  Level: TLevel;

  function LemmingCountString: String;
  var
    i: Integer;
    PreplacedZombieCount: Integer;
  begin
    PreplacedZombieCount := 0;

    for i := 0 to Level.PreplacedLemmings.Count-1 do
      if Level.PreplacedLemmings[i].IsZombie then
        Inc(PreplacedZombieCount);

    Result := IntToStr(Level.Info.LemmingsCount) + '|' +
              IntToStr(Level.Info.ZombieCount) + '|' +
              IntToStr(Level.PreplacedLemmings.Count) + '|' +
              IntToStr(PreplacedZombieCount);
  end;

  function MiscString: String;
  begin
    Result := IntToStr(Level.Info.RescueCount) + '|';

    if Level.Info.SpawnIntervalLocked or (Level.Info.SpawnInterval = 4) then
      Result := Result + '-';
    Result := Result + IntToStr(103 - Level.Info.SpawnInterval) + '|';

    if Level.Info.HasTimeLimit then
      Result := Result + IntToStr(Level.Info.TimeLimit)
    else
      Result := Result + '0';

    if Level.Info.SuperLemming then
      Result := Result + Level.Info.SuperLemming;
  end;

  function SkillsetString: String;
  var
    Skill: TSkillPanelButton;
  begin
    Result := '';

    for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    begin
      if not (Skill in Level.Info.Skillset) then
        Result := Result + '-1'
      else
        Result := Result + IntToStr(Level.Info.SkillCount[Skill]);

      if Skill < LAST_SKILL_BUTTON then
        Result := Result + '|';
    end;
  end;
begin
  for i := 0 to Children.Count-1 do
    Children[i].InternalDumpSuperLemmixWebsiteMetaInfo(Titles, Stats);

  for i := 0 to Levels.Count-1 do
  begin
    GameParams.SetLevel(Levels[i]);
    GameParams.LoadCurrentLevel;

    Level := GameParams.Level;
    Level.PrepareForUse;

    Titles.Add(Level.Info.Title);

    Stats.Add(LemmingCountString + '|' +
              MiscString + '|' +
              SkillsetString);
  end;
end;
{$endif}

function TNeoLevelGroup.FindFile(aName: String): String;
begin
  Result := '';
  if FileExists(Path + aName) then
    Result := Path + aName
  else if (not IsBasePack) and (Parent <> nil) then
    Result := Parent.FindFile(aName);
end;

procedure TNeoLevelGroup.SetDefaultData;
begin
  LoadScrollerDataDefault;
  LoadMusicData;
  LoadPostviewData;
end;

procedure TNeoLevelGroup.WipeAllRecords;
var
  i: Integer;
begin
  for i := 0 to fChildGroups.Count-1 do
    fChildGroups[i].WipeAllRecords;

  for i := 0 to fLevels.Count-1 do
    fLevels[i].WipeRecords;
end;

procedure TNeoLevelGroup.LoadScrollerDataDefault;
begin
  fPackTitle := '';
  fPackAuthor := '';
  fPackVersion := '';

  if (fParentGroup <> nil) and not FileExists(Path + 'info.nxmi') then
  begin
    if fParentGroup.PackTitle.Length > 0 then
      fPackTitle := fParentGroup.PackTitle;
    if fParentGroup.PackAuthor.Length > 0 then
      fPackAuthor := fParentGroup.PackAuthor;
    if fParentGroup.PackVersion.Length > 0 then
      fPackVersion := fParentGroup.PackVersion;

    fScrollerList := fParentGroup.ScrollerList;
    fHasOwnScrollerList := false;
  end else begin
    fScrollerList := TStringList.Create;
    fHasOwnScrollerList := true;
  end;
end;

procedure TNeoLevelGroup.LoadScrollerData;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  if not FileExists(Path + 'info.nxmi') then
    Exit;

  if not fHasOwnScrollerList then
  begin
    fScrollerList := TStringList.Create;
    fHasOwnScrollerList := true;
  end;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(Path + 'info.nxmi');
    MainSec := Parser.MainSection;
    fPackTitle := MainSec.LineTrimString['title'];
    fName := fPackTitle;
    fPackAuthor := MainSec.LineTrimString['author'];
    fAuthor := fPackAuthor;
    fPackVersion := MainSec.LineTrimString['version'];
    MainSec.DoForEachSection('scroller', LoadScrollerSection);
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadScrollerSection(aSection: TParserSection; const aIteration: Integer);
begin
  aSection.DoForEachLine('line',
    procedure(aLine: TParserLine; const aIteration: Integer)
    begin
      fScrollerList.Add(aLine.ValueTrimmed);
    end
  );
end;

procedure TNeoLevelGroup.LoadMusicData;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  if (fParentGroup <> nil) and not FileExists(Path + 'music.nxmi') then
  begin
    fMusicList := fParentGroup.MusicList;
    fHasOwnMusicList := false;
    Exit;
  end;

  fMusicList := TStringList.Create;
  fHasOwnMusicList := true;
  Parser := TParser.Create;
  try
    if FileExists(Path + 'music.nxmi') then
      Parser.LoadFromFile(Path + 'music.nxmi')
    else if FileExists(AppPath + SFData + 'music.nxmi') then
      Parser.LoadFromFile(AppPath + SFData + 'music.nxmi');

    MainSec := Parser.MainSection;
    if (MainSec.Line['random'] <> nil) then
    begin
      fRandomMusicTemp := '';
      MainSec.DoForEachLine('track', LoadRandomMusicLine);
      fMusicList.Add('!' + fRandomMusicTemp);
    end else
      MainSec.DoForEachLine('track', LoadMusicLine);
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadPostviewData;
var
  Parser: TParser;
  MainSec: TParserSection;
  buttonSelected: Integer;
begin
  if (fParentGroup <> nil) and not FileExists(Path + 'postview.nxmi') then
  begin
    fPostviewTexts := fParentGroup.PostviewTexts;
    fHasOwnPostviewTexts := false;
    Exit;
  end;

  fPostviewTexts := TPostviewTexts.Create;
  fHasOwnPostviewTexts := true;
  Parser := TParser.Create;
  try
    if FileExists(Path + 'postview.nxmi') then
      Parser.LoadFromFile(Path + 'postview.nxmi')
    else if FileExists(AppPath + SFData + 'postview.nxmi') then
      Parser.LoadFromFile(AppPath + SFData + 'postview.nxmi')
    else
    begin
      buttonSelected := MessageDlg('Could not find postview.nxmi in the folder data\. Try to continue?',
                                   mtWarning, mbOKCancel, 0);
      if buttonSelected = mrCancel then Application.Terminate();
    end;

    MainSec := Parser.MainSection;
    MainSec.DoForEachSection('result', LoadPostviewSection);
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadMusicLine(aLine: TParserLine; const aIteration: Integer);
begin
  fMusicList.Add(aLine.ValueTrimmed);
end;

procedure TNeoLevelGroup.LoadRandomMusicLine(aLine: TParserLine;
  const aIteration: Integer);
begin
  if fRandomMusicTemp <> '' then
    fRandomMusicTemp := fRandomMusicTemp + ';';
  fRandomMusicTemp := fRandomMusicTemp + aLine.ValueTrimmed;
end;

procedure TNeoLevelGroup.LoadPostviewSection(aSection: TParserSection; const aIteration: Integer);
var
  NewText: TPostviewText;
begin
  NewText := fPostviewTexts.Add;
  NewText.InterpretCondition(aSection.LineTrimString['condition']);
  aSection.DoForEachLine('line', NewText.LoadLine);
end;

procedure TNeoLevelGroup.LoadUserData;
var
  Parser: TParser;
  LevelSec: TParserSection;

  procedure HandleGroup(aGroup: TNeoLevelGroup);
  var
    i: Integer;

    procedure HandleLevel(aLevel: TNeoLevelEntry);
    var
      Sec: TParserSection;
      i: TNeoLevelStatus;
      S: String;
      Skill: TSkillPanelButton;

      procedure CheckIfOutdated;
      begin
        // This should check if the level is outdated, and if so, mark as "Completed Outdated".
        // Currently, it is not totally reliable.
        if (GetFileAge(aLevel.Path) <> Sec.LineNumeric['modified_date']) then
        begin
          if (Sec.Line['crc'] = nil) or
             (aLevel.CRC32 <> Sec.LineNumeric['crc']) then
            aLevel.Status := lst_Completed_Outdated;
        end;
      end;

      procedure LoadRecord(aLabel: String; var aUserEntry: TLevelRecordEntry; var aWorldEntry: TLevelRecordEntry);
      var
        SubSec: TParserSection;
      begin
        if Sec.Line[aLabel] <> nil then
        begin
          // Fallback behavior for older files
          aUserEntry.Value := Sec.LineNumericDefault[aLabel, -1];
          aUserEntry.User := GameParams.Username;
          aWorldEntry.Value := Sec.LineNumericDefault[aLabel, -1];
          aWorldEntry.User := GameParams.Username;
        end else begin
          aUserEntry.Value := -1;
          aUserEntry.User := '';
          aWorldEntry.Value := -1;
          aWorldEntry.User := '';

          SubSec := Sec.Section[aLabel];
          if SubSec = nil then Exit;

          aUserEntry.Value := SubSec.LineNumericDefault['user', -1];
          if aUserEntry.Value >= 0 then aUserEntry.User := GameParams.Username;
          aWorldEntry.Value := SubSec.LineNumericDefault['world', -1];
          aWorldEntry.User := SubSec.LineString['world_username'];
        end;
      end;
    begin
      Sec := LevelSec.Section[aLevel.RelativePath];
      if Sec = nil then Exit;

      S := Sec.LineTrimString['status'];
      for i := High(TNeoLevelStatus) downto Low(TNeoLevelStatus) do
        if Lowercase(S) = STATUS_TEXTS[i] then
        begin
          aLevel.Status := i;
          Break;
        end;

      if aLevel.Status = lst_Completed then
        CheckIfOutdated;

      LoadRecord('lemming_record', aLevel.UserRecords.LemmingsRescued, aLevel.WorldRecords.LemmingsRescued);
      LoadRecord('time_record', aLevel.UserRecords.TimeTaken, aLevel.WorldRecords.TimeTaken);
      LoadRecord('fewest_skills', aLevel.UserRecords.TotalSkills, aLevel.WorldRecords.TotalSkills);
      LoadRecord('fewest_skill_types', aLevel.UserRecords.SkillTypes, aLevel.WorldRecords.SkillTypes);

      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        LoadRecord('fewest_' + SKILL_NAMES[Skill], aLevel.UserRecords.SkillCount[Skill], aLevel.WorldRecords.SkillCount[Skill]);

      Sec.DoForEachLine('talisman',
                        procedure(aLine: TParserLine; const aIteration: Integer)
                        begin
                          aLevel.TalismanStatus[aLine.ValueNumeric] := true;
                        end);
    end;

  begin
    for i := 0 to aGroup.Children.Count-1 do
      HandleGroup(aGroup.Children[i]);

    for i := 0 to aGroup.Levels.Count-1 do
      HandleLevel(aGroup.Levels[i]);
  end;
begin
  if Parent <> nil then
    raise Exception.Create('TNeoLevelGroup.LoadUserData called for group other than base group');

  if not FileExists(AppPath + SFSaveData + 'userdata.nxsv') then
  begin
    fChildGroups.Sort(SortAlphabetical);
    fLevels.Sort(SortAlphabetical);
    Exit;
  end;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFSaveData + 'userdata.nxsv');
    LevelSec := Parser.MainSection.Section['levels'];

    fChildGroups.Sort(SortAlphabetical);
    fLevels.Sort(SortAlphabetical);

    if LevelSec <> nil then
      HandleGroup(self);
  except
    on E: Exception do
    begin
      fDisableSaveProgress := true;
      raise E;
    end;
  end;

  Parser.Free;
end;

procedure TNeoLevelGroup.SaveUserData;
var
  Parser: TParser;
  LevelSec: TParserSection;

  procedure HandleGroup(aGroup: TNeoLevelGroup);
  var
    i: Integer;

    procedure HandleLevel(aLevel: TNeoLevelEntry);
    var
      ActiveLevelSec: TParserSection;
      i: Integer;
      Skill: TSkillPanelButton;

      UserExit, WorldExit: Boolean;

      procedure SaveRecord(aLabel: String; aUserEntry: TLevelRecordEntry; aWorldEntry: TLevelRecordEntry);
      var
        RealSubSec: TParserSection;
        function SubSec: TParserSection;
        begin
          if RealSubSec = nil then
            RealSubSec := ActiveLevelSec.SectionList.Add(aLabel);
          Result := RealSubSec;
        end;
      begin
        RealSubSec := nil;

        if (not UserExit) and (aUserEntry.Value >= 0) then
          SubSec.AddLine('user', aUserEntry.Value);

        if (not WorldExit) and (aWorldEntry.Value >= 0) then
        begin
          SubSec.AddLine('world', aWorldEntry.Value);
          SubSec.AddLine('world_username', aWorldEntry.User);
        end;
      end;
    begin
      UserExit := (aLevel.Status = lst_None);
      WorldExit := (aLevel.WorldRecords.LemmingsRescued.Value <= 0);

      if UserExit and WorldExit then
        Exit;

      ActiveLevelSec := LevelSec.SectionList.Add(aLevel.RelativePath);

      if not UserExit then
      begin
        ActiveLevelSec.AddLine('status', STATUS_TEXTS[aLevel.Status]);

        if aLevel.Status >= lst_Completed_Outdated then
        begin
          ActiveLevelSec.AddLine('modified_date', GetFileAge(aLevel.Path));
          ActiveLevelSec.AddLine('crc', aLevel.CRC32);
        end;

        for i := 0 to aLevel.fUnlockedTalismanList.Count-1 do
          ActiveLevelSec.AddLine('talisman', 'x' + IntToHex(aLevel.fUnlockedTalismanList[i], 8));
      end;

      SaveRecord('lemming_record', aLevel.UserRecords.LemmingsRescued, aLevel.WorldRecords.LemmingsRescued);
      SaveRecord('time_record', aLevel.UserRecords.TimeTaken, aLevel.WorldRecords.TimeTaken);
      SaveRecord('fewest_skills', aLevel.UserRecords.TotalSkills, aLevel.WorldRecords.TotalSkills);
      SaveRecord('fewest_skill_types', aLevel.UserRecords.SkillTypes, aLevel.WorldRecords.SkillTypes);

      for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
        if (aLevel.UserRecords.SkillCount[Skill].Value >= 0) or
           (aLevel.WorldRecords.SkillCount[Skill].Value >= 0) then // avoid skills that don't exist in the level
          SaveRecord('fewest_' + SKILL_NAMES[Skill], aLevel.UserRecords.SkillCount[Skill], aLevel.WorldRecords.SkillCount[Skill]);
    end;
  begin
    for i := 0 to aGroup.Children.Count-1 do
      HandleGroup(aGroup.Children[i]);

    for i := 0 to aGroup.Levels.Count-1 do
    begin
      HandleLevel(aGroup.Levels[i]);
    end;
  end;

begin
  if not fEnableSave then
    Exit;

  if Parent <> nil then
    raise Exception.Create('TNeoLevelGroup.SaveUserData called for group other than base group');
  Parser := TParser.Create;
  try
    LevelSec := Parser.MainSection.SectionList.Add('levels');

    HandleGroup(self);

    ForceDirectories(AppPath + SFSaveData);
    Parser.SaveToFile(AppPath + SFSaveData + 'userdata.nxsv');
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.Load;
begin
  LoadScrollerData; // doesn't do anything if there is no info.nxmo file...

  if FileExists(Path + 'levels.nxmi') and (Parent <> nil) then
    LoadFromMetaInfo
  else
    LoadFromSearchRec;
end;

procedure TNeoLevelGroup.LoadLevel(aLine: TParserLine; const aIteration: Integer);
var
  L: TNeoLevelEntry;
begin
  L := fLevels.Add;
  L.Filename := aLine.ValueTrimmed;
end;

procedure TNeoLevelGroup.LoadSubGroup(aSection: TParserSection; const aIteration: Integer);
var
  G: TNeoLevelGroup;
begin
  G := fChildGroups.Add(aSection.LineTrimString['folder']);
  G.Name := aSection.LineTrimString['name'];
end;

procedure TNeoLevelGroup.LoadFromMetaInfo;
var
  Parser: TParser;
  MainSec: TParserSection;
begin
  Parser := TParser.Create;
  try
    Parser.LoadFromFile(Path + 'levels.nxmi');
    MainSec := Parser.MainSection;
    if MainSec.Section['group'] = nil then
      MainSec.DoForEachSection('rank', LoadSubGroup)
    else
      MainSec.DoForEachSection('group', LoadSubGroup);
    MainSec.DoForEachLine('level', LoadLevel);
    fIsBasePack := MainSec.Line['base'] <> nil;
    fIsOrdered := true;

    // we do NOT want to sort alphabetically here, we want them to stay in the order
    // the metainfo file lists them in!
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadFromSearchRec;
var
  SearchRec: TSearchRec;
  L: TNeoLevelEntry;
  G: TNeoLevelGroup;
begin
  if FindFirst(Path + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if SearchRec.Attr and faDirectory <> faDirectory then Continue;
      if (SearchRec.Name = '..') or (SearchRec.Name = '.') then Continue;
      G := fChildGroups.Add(SearchRec.Name + '\');
      if Parent = nil then G.IsBasePack := true;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  if FindFirst(Path + '*.nxlv', 0, SearchRec) = 0 then
  begin
    repeat
      L := fLevels.Add;
      L.Filename := SearchRec.Name;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  if Parent <> nil then
  begin
    // It's done after loading extra groups / levels for the base group
    fChildGroups.Sort(SortAlphabetical);
    fLevels.Sort(SortAlphabetical);
  end;

  fIsOrdered := false;
end;

function TNeoLevelGroup.GetFullPath: String;
begin
  if Pos(':', fFolder) <> 0 then
    Result := ''
  else if fParentGroup = nil then
    Result := AppPath + SFLevels
  else
    Result := fParentGroup.Path;

  Result := Result + fFolder + '\';
end;

function TNeoLevelGroup.GetAuthor: String;
begin
  if fAuthor = '' then
    if fParentGroup <> nil then
      fAuthor := fParentGroup.Author;

  Result := fAuthor;
end;

function TNeoLevelGroup.GetRecursiveLevelCount: Integer;
var
  i: Integer;
begin
  Result := fLevels.Count;
  for i := 0 to fChildGroups.Count-1 do
    Result := Result + fChildGroups[i].LevelCount;
end;

function TNeoLevelGroup.GetLevelForTalisman(aTalisman: TTalisman): TNeoLevelEntry;
var
  i, n: Integer;
begin
  Result := nil;

  for i := 0 to fChildGroups.Count-1 do
  begin
    Result := fChildGroups[i].GetLevelForTalisman(aTalisman);
    if Result <> nil then Exit;
  end;

  for i := 0 to fLevels.Count-1 do
    for n := 0 to fLevels[i].Talismans.Count-1 do
      if fLevels[i].Talismans[n] = aTalisman then
      begin
        Result := fLevels[i];
        Exit;
      end;
end;

function TNeoLevelGroup.GetLevelIndex(aLevel: TNeoLevelEntry): Integer;
begin
  for Result := 0 to fLevels.Count-1 do
    if fLevels[Result] = aLevel then Exit;
  Result := -1;
end;

function TNeoLevelGroup.GetGroupIndex(aGroup: TNeoLevelGroup): Integer;
begin
  for Result := 0 to fChildGroups.Count-1 do
    if fChildGroups[Result] = aGroup then Exit;
  Result := -1;
end;

function TNeoLevelGroup.GetParentGroupIndex: Integer;
begin
  if fParentGroup = nil then
    Result := -1
  else
    Result := fParentGroup.GroupIndex[self];
end;

function TNeoLevelGroup.GetFirstUnbeatenLevel: TNeoLevelEntry;
var
  i: Integer;
begin
  if fLevels.Count = 0 then
  begin
    raise EAccessViolation.Create('No levels contained in selected rank!');
    Exit;
  end;

  Result := fLevels[0];
  for i := 0 to fLevels.Count - 1 do
  begin
    if fLevels[i].Status <> lst_Completed then
    begin
      Result := fLevels[i];
      Exit;
    end;
  end;
end;

function TNeoLevelGroup.GetFirstUnbeatenLevelRecursive: TNeoLevelEntry;
var
  i: Integer;
begin
  for i := 0 to fChildGroups.Count-1 do
  begin
    Result := fChildGroups[i].FirstUnbeatenLevelRecursive;
    if (Result <> nil) and (Result.Status <> lst_Completed) then Exit;
  end;

  for i := 0 to fLevels.Count-1 do
  begin
    if fLevels[i].Status <> lst_Completed then
    begin
      Result := fLevels[i];
      Exit;
    end;
  end;

  // Get first level, if there is no unbeaten one
  Result := FirstLevelRecursive;
end;

function TNeoLevelGroup.GetFirstLevelRecursive: TNeoLevelEntry;
var
  i: Integer;
begin
  // Check for levels directly in this group entry
  if fLevels.Count > 0 then
  begin
    Result := fLevels[0];
    Exit;
  end;

  // Check for groups withint this group
  for i := 0 to fChildGroups.Count-1 do
  begin
    Result := fChildGroups[i].FirstLevelRecursive;
    if (Result <> nil) then Exit;
  end;

  // If we get here, then there is no level at all in this pack and we throw an exception
  raise EAccessViolation.Create('No levels contained in selected pack!');
end;


function TNeoLevelGroup.GetNextGroup: TNeoLevelGroup;
var
  NextChildIndex: Integer;

  procedure GoDeepest;
  begin
    while Result.Children.Count > 0 do
      Result := Result.Children[0];
  end;
begin
  Result := self; // failsafe
  if Result.Parent = nil then Exit;

  repeat
    if Result.IsBasePack then
      GoDeepest
    else begin
      NextChildIndex := Result.Parent.Children.IndexOf(Result) + 1;
      if NextChildIndex < Result.Parent.Children.Count then
      begin
        Result := Result.Parent.Children[NextChildIndex];
        GoDeepest;
      end else
        Result := Result.Parent;
    end;
  until (Result.Levels.Count > 0) or (Result = self);
end;

function TNeoLevelGroup.GetPrevGroup: TNeoLevelGroup;
var
  AsChildIndex: Integer;
begin
  Result := self; // failsafe
  if Result.Parent = nil then Exit;

  repeat
    if Result.Children.Count > 0 then
      Result := Result.Children[Result.Children.Count-1]
    else begin
      AsChildIndex := Result.Parent.Children.IndexOf(Result);
      while (AsChildIndex = 0) and (not Result.IsBasePack) do
      begin
        Result := Result.Parent;
        AsChildIndex := Result.Parent.Children.IndexOf(Result);
      end;

      if (AsChildIndex > 0) and not Result.IsBasePack then
        Result := Result.Parent.Children[AsChildIndex - 1];
    end;
  until (Result.Levels.Count > 0) or (Result = self);
end;

function TNeoLevelGroup.GetStatus: TNeoLevelStatus;
var
  i: Integer;
  TempStatus: TNeoLevelStatus;
  HasAttempted: Boolean;
begin
  Result := lst_Completed;
  HasAttempted := false;

  for i := 0 to fChildGroups.Count-1 do
  begin
    TempStatus := fChildGroups[i].Status;
    if TempStatus > lst_None then
    begin
      HasAttempted := true;
      if (TempStatus < Result) then
        Result := TempStatus;
      if Result = lst_Attempted then
        Exit;
    end else
      Result := lst_Attempted;
  end;

  for i := 0 to fLevels.Count-1 do
  begin
    TempStatus := fLevels[i].Status;
    if TempStatus > lst_None then
    begin
      HasAttempted := true;
      if (TempStatus < Result) then
        Result := TempStatus;
      if Result = lst_Attempted then
        Exit;
    end else
      Result := lst_Attempted;
  end;

  if not HasAttempted then
    Result := lst_None;
end;

function TNeoLevelGroup.GetTalismans: TObjectList<TTalisman>;
var
  i: Integer;

  procedure AddList(aList: TObjectList<TTalisman>);
  var
    i: Integer;
  begin
    for i := 0 to aList.Count-1 do
      fTalismans.Add(aList[i]);
  end;

  procedure SortTalismans;
  var
    i, n: Integer;
    Color: TTalismanColor;
  begin
    for Color := Low(TTalismanColor) to High(TTalismanColor) do
    begin
      n := 0;
      for i := 0 to fTalismans.Count-1 do
        if fTalismans[n].Color = Color then
          fTalismans.Move(n, fTalismans.Count-1)
        else
          Inc(n);
    end;
  end;
begin
  if fTalismans = nil then
  begin
    fTalismans := TObjectList<TTalisman>.Create(false);

    if Parent <> nil then
      for i := 0 to Children.Count-1 do
        AddList(Children[i].Talismans);

    for i := 0 to Levels.Count-1 do
      AddList(Levels[i].Talismans);

    SortTalismans;
  end;
  Result := fTalismans;
end;

function TNeoLevelGroup.GetCompleteTalismanCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Children.Count-1 do
    Result := Result + Children[i].TalismansUnlocked;
  for i := 0 to Levels.Count-1 do
    Result := Result + Levels[i].UnlockedTalismanList.Count;
end;

function TNeoLevelGroup.GetParentBasePack: TNeoLevelGroup;
begin
  if IsBasePack or (Parent = nil) or (Parent.Parent = nil) then
    Result := self
  else
    Result := Parent.ParentBasePack;
end;

// --------- LISTS --------- //

{ TNeoLevelEntries }

constructor TNeoLevelEntries.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelEntries.Add: TNeoLevelEntry;
begin
  Result := TNeoLevelEntry.Create(fOwner);
  inherited Add(Result);
end;

function TNeoLevelEntries.GetItem(Index: Integer): TNeoLevelEntry;
begin
  Result := inherited Get(Index);
end;

{ TNeoLevelGroups }

constructor TNeoLevelGroups.Create(aOwner: TNeoLevelGroup);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
  fOwner := aOwner;
end;

function TNeoLevelGroups.Add(aFolder: String): TNeoLevelGroup;
begin
  Result := TNeoLevelGroup.Create(fOwner, aFolder);
  inherited Add(Result);
end;

function TNeoLevelGroups.GetItem(Index: Integer): TNeoLevelGroup;
begin
  Result := inherited Get(Index);
end;

{ TPostviewTexts }

constructor TPostviewTexts.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TPostviewTexts.Add: TPostviewText;
begin
  Result := TPostviewText.Create;
  inherited Add(Result);
end;

function TPostviewTexts.GetItem(Index: Integer): TPostviewText;
begin
  Result := inherited Get(Index);
end;


{ TLevelRecords }

procedure TLevelRecords.SetNameOnAll(aName: String);
  procedure SetNameOnRecordEntry(var aEntry: TLevelRecordEntry);
  begin
    aEntry.User := aName;
  end;
var
  Skill: TSkillPanelButton;
begin
  SetNameOnRecordEntry(LemmingsRescued);
  SetNameOnRecordEntry(TimeTaken);
  SetNameOnRecordEntry(TotalSkills);
  SetNameOnRecordEntry(SkillTypes);
  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    SetNameOnRecordEntry(SkillCount[Skill]);
end;

procedure TLevelRecords.Wipe;
  procedure WipeRecordEntry(var aEntry: TLevelRecordEntry);
  begin
    aEntry.Value := -1;
    aEntry.User := '';
  end;
var
  Skill: TSkillPanelButton;
begin
  WipeRecordEntry(LemmingsRescued);
  WipeRecordEntry(TimeTaken);
  WipeRecordEntry(TotalSkills);
  WipeRecordEntry(SkillTypes);
  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    WipeRecordEntry(SkillCount[Skill]);
end;

end.