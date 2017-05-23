unit LemNeoLevelPack;

// Replaces LemDosStyle, LemDosLevelSystem etc. Those are messy. This should be tidier.

// NOTE TO NEPSTER: This is a work-in-progress file that I haven't integrated yet, not an unused one. Do not remove.

interface

uses
  GR32, CRC32, PngInterface,
  Classes, SysUtils, StrUtils, Contnrs,
  LemStrings, LemTypes, LemNeoParser;

type
  TNeoLevelEntry = class;
  TNeoLevelEntries = class;
  TNeoLevelGroup = class;
  TNeoLevelGroups = class;

  TNeoLevelStatus = (lst_None, lst_Attempted, lst_Completed_Outdated, lst_Completed);

  TNeoLevelEntry = class  // This is an entry in a level pack's list, and does NOT contain the level itself
    private
      fGroup: TNeoLevelGroup;

      fTitle: String;
      fFilename: String;

      fStatus: TNeoLevelStatus;

      fLastCRC32: Cardinal;

      procedure Wipe;
      procedure SetFilename(aValue: String);
      function GetFullPath: String;
      function GetTitle: String;
    public
      constructor Create(aGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Title: String read GetTitle;
      property Filename: String read fFilename write SetFilename;
      property Path: String read GetFullPath;
      property Status: TNeoLevelStatus read fStatus write fStatus;
  end;

  TNeoLevelGroup = class
    private
      fParentGroup: TNeoLevelGroup;
      fChildGroups: TNeoLevelGroups;
      fLevels: TNeoLevelEntries;

      fName: String;
      fFolder: String;
      fPanelStyle: String;

      procedure SetFolderName(aValue: String);
      function GetFullPath: String;

      procedure LoadFromMetaInfo;
      procedure LoadFromSearchRec;

      procedure LoadLevel(aLine: TParserLine; const aIteration: Integer);
      procedure LoadSubGroup(aSection: TParserSection; const aIteration: Integer);

      procedure Load;
    public
      constructor Create(aParentGroup: TNeoLevelGroup);
      destructor Destroy; override;

      procedure EnsureUpdated;

      property Name: String read fName write fName;
      property Folder: String read fFolder write SetFolderName;
      property Path: String read GetFullPath;
      property PanelStyle: String read fPanelStyle;
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
      function Add: TNeoLevelGroup;
      property Items[Index: Integer]: TNeoLevelGroup read GetItem; default;
      property List;
  end;

  function SortAlphabetical(Item1, Item2: Pointer): Integer;

implementation

function SortAlphabetical(Item1, Item2: Pointer): Integer;
var
  G1: TNeoLevelGroup;
  G2: TNeoLevelGroup;
  L1: TNeoLevelEntry;
  L2: TNeoLevelEntry;
begin
  Result := 0;

  if (TObject(Item1^) is TNeoLevelGroup) and (TObject(Item2^) is TNeoLevelGroup) then
  begin
    G1 := TNeoLevelGroup(Item1^);
    G2 := TNeoLevelGroup(Item2^);
    Result := CompareStr(G1.Name, G2.Name);
  end;

  if (TObject(Item1^) is TNeoLevelEntry) and (TObject(Item2^) is TNeoLevelEntry) then
  begin
    L1 := TNeoLevelEntry(Item1^);
    L2 := TNeoLevelEntry(Item2^);
    Result := CompareStr(L1.Title, L2.Title);
  end;
end;

{ TNeoLevelEntry }

constructor TNeoLevelEntry.Create(aGroup: TNeoLevelGroup);
begin
  inherited Create;
  fGroup := aGroup;
end;

destructor TNeoLevelEntry.Destroy;
begin
  // Did have stuff here but it's no longer used. But left this here because stuff that needs it
  // will probably be added later.
  inherited;
end;

procedure TNeoLevelEntry.Wipe;
begin
  fTitle := '';
end;

function TNeoLevelEntry.GetTitle: String;
var
  Parser: TParser;
begin
  if fTitle = '' then
  begin
    Parser := TParser.Create;
    try
      Parser.LoadFromFile(Path);
      fTitle := Parser.MainSection.LineTrimString['title'];
    finally
      Parser.Free;
    end;
  end;

  Result := fTitle;
end;

procedure TNeoLevelEntry.EnsureUpdated;
var
  CRC: Cardinal;
begin
  CRC := CalculateCRC32(fFilename);
  if CRC <> fLastCRC32 then Wipe;
  fLastCRC32 := CRC;
end;

procedure TNeoLevelEntry.SetFilename(aValue: String);
begin
  if fFilename = aValue then Exit;
  fFilename := aValue;
  EnsureUpdated;
end;

function TNeoLevelEntry.GetFullPath: String;
begin
  if fGroup = nil then
    Result := ''
  else
    Result := fGroup.Path;

  Result := Result + fFilename;
end;

{ TNeoLevelGroup }

constructor TNeoLevelGroup.Create(aParentGroup: TNeoLevelGroup);
begin
  inherited Create;
  fChildGroups := TNeoLevelGroups.Create(self);
  fLevels := TNeoLevelEntries.Create(self);
  fParentGroup := aParentGroup;

  if fParentGroup = nil then
    fPanelStyle := 'default'
  else
    fPanelStyle := fParentGroup.PanelStyle;
end;

destructor TNeoLevelGroup.Destroy;
begin
  fChildGroups.Free;
  fLevels.Free;
  inherited;
end;

procedure TNeoLevelGroup.Load;
begin
  if FileExists(Path + 'levels.nxmi') then
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
  G := fChildGroups.Add;
  G.Name := aSection.LineTrimString['name'];
  G.Folder := aSection.LineTrimString['folder'];
  G.Load;
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
    MainSec.DoForEachSection('rank', LoadSubGroup);
    MainSec.DoForEachLine('level', LoadLevel);
    fPanelStyle := MainSec.LineTrimString['panel_style'];

    // we do NOT want to sort alphabetically here, we want them to stay in the order
    // the metainfo file lists them in!
  finally
    Parser.Free;
  end;
end;

procedure TNeoLevelGroup.LoadFromSearchRec;
var
  SearchRec: TSearchRec;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
begin
  if FindFirst(Path + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      G := fChildGroups.Add;
      G.Name := SearchRec.Name;
      G.Folder := SearchRec.Name;
      G.Load;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    fChildGroups.Sort(SortAlphabetical);
  end;

  if FindFirst(Path + '*.nxlv', 0, SearchRec) = 0 then
  begin
    repeat
      L := fLevels.Add;
      L.Filename := SearchRec.Name;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    fLevels.Sort(SortAlphabetical);
  end;
end;

procedure TNeoLevelGroup.SetFolderName(aValue: String);
begin
  if fFolder = aValue then Exit;
  fFolder := aValue;
  EnsureUpdated;
end;

procedure TNeoLevelGroup.EnsureUpdated;
var
  i: Integer;
begin
  for i := 0 to fChildGroups.Count-1 do
    fChildGroups[i].EnsureUpdated;

  for i := 0 to fLevels.Count-1 do
    fLevels[i].EnsureUpdated;
end;

function TNeoLevelGroup.GetFullPath: String;
begin
  if fParentGroup = nil then
    Result := AppPath + SFLevels
  else
    Result := fParentGroup.Path;

  Result := Result + fFolder + '\';
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

function TNeoLevelGroups.Add: TNeoLevelGroup;
begin
  Result := TNeoLevelGroup.Create(fOwner);
  inherited Add(Result);
end;

function TNeoLevelGroups.GetItem(Index: Integer): TNeoLevelGroup;
begin
  Result := inherited Get(Index);
end;

end.