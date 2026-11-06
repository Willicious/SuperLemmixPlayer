unit SuperLemmixManifest;

{ This unit is used to build a hash-based manifest for all files in the
  SuperLemmix directory. The idea is that it generates and stores both
  'Current' and previously 'Known' hashes for every file.

  This can then be used when applying updates. If a user has modded a
  particular file, we can check to see if its hash is different from
  what SuperLemmix expects, given the Current and Known hashes.

  If it's different, we can move the file rather than replacing it.

  We'll also only apply updates to files that have actually changed in
  the current version, so users don't have to needlessly re-apply
  mods to files that haven't been updated. }

interface

uses
  Windows, System.Zip, System.SysUtils, System.Classes, System.IniFiles,
  System.Hash, System.IOUtils, System.Generics.Collections, System.Types,
  SharedGlobals;

type
  TManifestFileStatus = (
    mfsMissing,
    mfsCurrent,
    mfsOutdated,
    mfsUserModified,
    mfsNotTracked,
    mfsRemoved
  );

  TManifestAction = (
    maNone,
    maInstall,
    maUpdate,
    maPreserve,
    maReviewRemoval
  );

  TUpdateActionItem = class
  private
    fRelativePath: string;
    fAction: TManifestAction;
  public
    constructor Create(const aPath: string; aAction: TManifestAction);
    property RelativePath: string read fRelativePath write fRelativePath;
    property Action: TManifestAction read fAction write fAction;
  end;

  TSuperLemmixManifest = class
  private
    type
      TFileEntry = class
        Current: string;
        Known: TList<string>;
        constructor Create;
        destructor Destroy; override;
      end;

  private
    fEntries: TObjectDictionary<string, TFileEntry>;

    function NormalizePath(const BaseFolder, FullPath: string): string;
    function ComputeShortHash(const FileName: string): string;
    function IsInScope(const RelativePath, RelativeFolder: string): Boolean;

    procedure UpdateHash(const RelativePath, Hash: string);
    procedure MarkFileDeleted(const RelativePath: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ScanZipFile(const ZipFileName: string);
    procedure ScanFolders(const BaseFolder: string; const RelativeFolders: array of string);
    procedure ScanInstallation(const BaseFolder: string; Results: TStrings);
    procedure LoadFromIni(const FileName: string);
    procedure SaveToIni(const FileName: string);

    function GetCurrentHash(const RelativePath: string): string;
    function IsKnownHash(const RelativePath, Hash: string): Boolean;
    function GetFileStatus(const BaseFolder, RelativePath: string): TManifestFileStatus;
    function GetFileAction(const BaseFolder, RelativePath: string): TManifestAction;
    function GetUpdatePlan(const BaseFolder: string): TObjectList<TUpdateActionItem>;
  end;

implementation

{ TUpdateActionItem }

constructor TUpdateActionItem.Create(const aPath: string; aAction: TManifestAction);
begin
  inherited Create;
  fRelativePath := aPath;
  fAction := aAction;
end;

{ TSuperLemmixManifest.TFileEntry }

constructor TSuperLemmixManifest.TFileEntry.Create;
begin
  Known := TList<string>.Create;
end;

destructor TSuperLemmixManifest.TFileEntry.Destroy;
begin
  Known.Free;
  inherited;
end;

{ TSuperLemmixManifest }

constructor TSuperLemmixManifest.Create;
begin
  fEntries := TObjectDictionary<string, TFileEntry>.Create([doOwnsValues]);
end;

destructor TSuperLemmixManifest.Destroy;
begin
  fEntries.Free;
  inherited;
end;

function TSuperLemmixManifest.NormalizePath(const BaseFolder, FullPath: string): string;
begin
  Result := FullPath.Substring(BaseFolder.Length).TrimLeft(['\', '/']);
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
  Result := LowerCase(Result);
end;

function TSuperLemmixManifest.ComputeShortHash(const FileName: string): string;
begin
  Result := Copy(LowerCase(THashSHA2.GetHashStringFromFile(FileName)), 1, 16);
end;

function TSuperLemmixManifest.IsInScope(const RelativePath, RelativeFolder: string): Boolean;
var
  Folder: string;
begin
  Folder := LowerCase(
    StringReplace(RelativeFolder, '/', '\', [rfReplaceAll]));

  Folder := ExcludeTrailingPathDelimiter(Folder);

  Result := (RelativePath = Folder) or
    RelativePath.StartsWith(Folder + '\');
end;

procedure TSuperLemmixManifest.UpdateHash(const RelativePath, Hash: string);
var
  Entry: TFileEntry;
begin
  if not fEntries.TryGetValue(RelativePath, Entry) then
  begin
    Entry := TFileEntry.Create;
    Entry.Current := Hash;
    Entry.Known.Add(Hash);
    fEntries.Add(RelativePath, Entry);
    Exit;
  end;

  { If hash changed, update current and preserve history }
  if Entry.Current <> Hash then
  begin
    if (Entry.Current <> '') and not Entry.Known.Contains(Entry.Current) then
      Entry.Known.Add(Entry.Current);

    Entry.Current := Hash;
  end;

  if not Entry.Known.Contains(Hash) then
    Entry.Known.Add(Hash);
end;

procedure TSuperLemmixManifest.MarkFileDeleted(const RelativePath: string);
var
  Entry: TFileEntry;
begin
  if fEntries.TryGetValue(RelativePath, Entry) then
    Entry.Current := '';
end;

procedure TSuperLemmixManifest.ScanZipFile(const ZipFileName: string);
var
  Zip: TZipFile;
  FileNames: TArray<string>;
  ScannedFiles: TDictionary<string, string>;
  Pair: TPair<string, TFileEntry>;
  ScannedPair: TPair<string, string>;
  OriginalEntryName, EntryName, RelativePath, Hash: string;
  i: Integer;
  IsDirectory: Boolean;
  EntryStream: TMemoryStream;
  Bytes: TBytes;
begin
  { Preserve the existing manifest if the ZIP is missing }
  if not FileExists(ZipFileName) then
    raise Exception.CreateFmt(
      'Release ZIP not found: %s', [ZipFileName]);

  Zip := TZipFile.Create;
  ScannedFiles := TDictionary<string, string>.Create;
  try
    Zip.Open(ZipFileName, zmRead);
    try
      FileNames := Zip.FileNames;

      { Read and hash every file before modifying the manifest }
      for i := 0 to High(FileNames) do
      begin
        OriginalEntryName := FileNames[i];
        EntryName := StringReplace(OriginalEntryName, '/', '\', [rfReplaceAll]);

        IsDirectory := EntryName.EndsWith('\');

        if IsDirectory then
          Continue;

        RelativePath := LowerCase(EntryName);

        { Styles are updated separately }
        if IsInScope(RelativePath, 'styles') then
          Continue;

        { Reject unsafe paths rather than recording them }
        if RelativePath.StartsWith('\') or (Pos(':', RelativePath) > 0) then
          raise Exception.CreateFmt(
            'Invalid path in release ZIP: %s', [OriginalEntryName]);

        if (RelativePath = '..') or RelativePath.StartsWith('..\') or
           (Pos('\..\', '\' + RelativePath + '\') > 0) then
          raise Exception.CreateFmt(
            'Invalid path in release ZIP: %s', [OriginalEntryName]);

        Zip.Read(OriginalEntryName, Bytes);

        EntryStream := TMemoryStream.Create;
        try
          if Length(Bytes) > 0 then
            EntryStream.WriteBuffer(Bytes[0], Length(Bytes));

          EntryStream.Position := 0;
          Hash := Copy(
            LowerCase(THashSHA2.GetHashString(EntryStream)), 1, 16);
        finally
          EntryStream.Free;
        end;

        ScannedFiles.AddOrSetValue(RelativePath, Hash);
      end;
    finally
      Zip.Close;
    end;

    { Only update the manifest after the entire ZIP was read }
    for Pair in fEntries do
    begin
      if IsInScope(Pair.Key, 'styles') then
        Continue;

      if (Pair.Value.Current <> '') and
         not ScannedFiles.ContainsKey(Pair.Key) then
        Pair.Value.Current := '';
    end;

    for ScannedPair in ScannedFiles do
      UpdateHash(ScannedPair.Key, ScannedPair.Value);
  finally
    ScannedFiles.Free;
    Zip.Free;
  end;
end;

procedure TSuperLemmixManifest.ScanFolders(const BaseFolder: string; const RelativeFolders: array of string);
var
  Files: TStringDynArray;
  FilePath, RelPath, Hash, Folder: string;
  ScannedFiles, Scopes: TStringList;
  Pair: TPair<string, TFileEntry>;
  I, J: Integer;
  InScope: Boolean;
begin
  ScannedFiles := TStringList.Create;
  Scopes := TStringList.Create;
  try
    ScannedFiles.CaseSensitive := False;
    ScannedFiles.Sorted := True;
    ScannedFiles.Duplicates := dupIgnore;

    Scopes.CaseSensitive := False;
    Scopes.Sorted := True;
    Scopes.Duplicates := dupIgnore;

    { Normalize the selected folders }
    for I := 0 to High(RelativeFolders) do
    begin
      Folder := StringReplace(
        RelativeFolders[I], '/', '\', [rfReplaceAll]);

      Folder := ExcludeTrailingPathDelimiter(Folder);
      Folder := LowerCase(Folder);

      if Folder <> '' then
        Scopes.Add(Folder);
    end;

    { Scan all selected folders }
    for I := 0 to Scopes.Count - 1 do
    begin
      Folder := TPath.Combine(BaseFolder, Scopes[I]);

      { A missing directory is still a valid scope: its old files
        will be marked as deleted during reconciliation }
      if not TDirectory.Exists(Folder) then
        Continue;

      Files := TDirectory.GetFiles(
        Folder, '*.*', TSearchOption.soAllDirectories);

      for FilePath in Files do
      begin
        RelPath := NormalizePath(BaseFolder, FilePath);
        ScannedFiles.Add(RelPath);

        Hash := ComputeShortHash(FilePath);
        UpdateHash(RelPath, Hash);
      end;
    end;

    { Mark previously known files as deleted when they are no
      longer present in any of the selected folder scopes }
    for Pair in fEntries do
    begin
      if Pair.Value.Current = '' then
        Continue;

      InScope := False;

      for J := 0 to Scopes.Count - 1 do
      begin
        if IsInScope(Pair.Key, Scopes[J]) then
        begin
          InScope := True;
          Break;
        end;
      end;

      if InScope and (ScannedFiles.IndexOf(Pair.Key) = -1) then
        MarkFileDeleted(Pair.Key);
    end;

  finally
    Scopes.Free;
    ScannedFiles.Free;
  end;
end;


procedure TSuperLemmixManifest.ScanInstallation(const BaseFolder: string; Results: TStrings);
var
  Pair: TPair<string, TFileEntry>;
  FilePath, RelativePath: string;
  Files: TStringDynArray;
  Status: TManifestFileStatus;

  function StatusText(Value: TManifestFileStatus): string;
  begin
    case Value of
      mfsMissing:
        Result := 'Missing';

      mfsCurrent:
        Result := 'Up to date';

      mfsOutdated:
        Result := 'Official update available';

      mfsUserModified:
        Result := 'User-modified';

      mfsNotTracked:
        Result := 'Not tracked';

      mfsRemoved:
        Result := 'Officially removed';
    else
      Result := 'Unknown';
    end;
  end;

begin
  Results.Clear;

  if not TDirectory.Exists(BaseFolder) then
    raise Exception.CreateFmt(
      'Installation folder not found: %s', [BaseFolder]);

  // Check every file recorded in the manifest, including any missing from the local installation
  for Pair in fEntries do
  begin
    if IsInScope(Pair.Key, 'styles') then
      Continue;

    Status := GetFileStatus(BaseFolder, Pair.Key);

    Results.Add(
      Pair.Key + ' = ' + StatusText(Status));
  end;

  // Find local files that do not appear in the manifest.
  Files := TDirectory.GetFiles(
    BaseFolder, '*', TSearchOption.soAllDirectories);

  for FilePath in Files do
  begin
    RelativePath := NormalizePath(BaseFolder, FilePath);

    if IsInScope(RelativePath, 'styles') then
      Continue;

    if not fEntries.ContainsKey(RelativePath) then
      Results.Add(RelativePath + ' = Not tracked');
  end;
end;

procedure TSuperLemmixManifest.LoadFromIni(const FileName: string);
var
  Ini: TIniFile;
  Sections: TStringList;
  I: Integer;
  Entry: TFileEntry;
  KnownStr: string;
  KnownItems: TArray<string>;
  S: string;
begin
  if not FileExists(FileName) then
    Exit;

  Ini := TIniFile.Create(FileName);
  Sections := TStringList.Create;
  try
    Ini.ReadSections(Sections);

    for i := 0 to Sections.Count - 1 do
    begin
      Entry := TFileEntry.Create;
      Entry.Current := Ini.ReadString(Sections[i], 'Current', '');

      KnownStr := Ini.ReadString(Sections[i], 'Known', '');
      KnownItems := KnownStr.Split([',']);

      for S in KnownItems do
        if Trim(S) <> '' then
          if not Entry.Known.Contains(Trim(S)) then
            Entry.Known.Add(Trim(S));

      if (Entry.Current <> '') and not Entry.Known.Contains(Entry.Current) then
        Entry.Known.Add(Entry.Current);

      fEntries.AddOrSetValue(Sections[i], Entry);
    end;

  finally
    Sections.Free;
    Ini.Free;
  end;
end;

procedure TSuperLemmixManifest.SaveToIni(const FileName: string);
var
  Ini: TMemIniFile;
  Pair: TPair<string, TFileEntry>;
  KnownStr: string;
begin
  Ini := TMemIniFile.Create(FileName);
  try
    { Remove old sections, including entries for files no longer scanned }
    Ini.Clear;

    for Pair in fEntries do
    begin
      KnownStr := string.Join(',', Pair.Value.Known.ToArray);

      Ini.WriteString(Pair.Key, 'Current', Pair.Value.Current);
      Ini.WriteString(Pair.Key, 'Known', KnownStr);
    end;

    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

function TSuperLemmixManifest.GetCurrentHash(const RelativePath: string): string;
var
  Entry: TFileEntry;
begin
  if fEntries.TryGetValue(LowerCase(StringReplace(RelativePath, '/', '\', [rfReplaceAll])), Entry) then
    Result := Entry.Current
  else
    Result := '';
end;

function TSuperLemmixManifest.IsKnownHash(const RelativePath, Hash: string): Boolean;
var
  Entry: TFileEntry;
begin
  if fEntries.TryGetValue(LowerCase(StringReplace(RelativePath, '/', '\', [rfReplaceAll])), Entry) then
    Result := Entry.Known.Contains(LowerCase(Hash))
  else
    Result := False;
end;

function TSuperLemmixManifest.GetFileStatus(const BaseFolder, RelativePath: string): TManifestFileStatus;
var
  Entry: TFileEntry;
  FullPath, NormalizedPath, Hash: string;
begin
  NormalizedPath := LowerCase(
    StringReplace(RelativePath, '/', '\', [rfReplaceAll]));

  FullPath := TPath.Combine(BaseFolder, NormalizedPath);

  if not FileExists(FullPath) then
    Exit(mfsMissing);

  if not fEntries.TryGetValue(NormalizedPath, Entry) then
    Exit(mfsNotTracked);

  Hash := ComputeShortHash(FullPath);

  if (Entry.Current <> '') and (Hash = Entry.Current) then
    Exit(mfsCurrent);

  if Entry.Known.Contains(Hash) then
  begin
    if Entry.Current = '' then
      Exit(mfsRemoved)
    else
      Exit(mfsOutdated);
  end;

  Result := mfsUserModified;
end;

function TSuperLemmixManifest.GetFileAction(const BaseFolder, RelativePath: string): TManifestAction;
var
  Status: TManifestFileStatus;
begin
  Status := GetFileStatus(BaseFolder, RelativePath);

  case Status of
    mfsCurrent:
      Result := maNone;

    mfsMissing:
      begin
        if GetCurrentHash(RelativePath) <> '' then
          Result := maInstall
        else
          Result := maReviewRemoval;
      end;

    mfsOutdated:
      Result := maUpdate;

    mfsUserModified,
    mfsNotTracked:
      Result := maPreserve;

    mfsRemoved:
      Result := maReviewRemoval;
  else
    Result := maNone;
  end;
end;

function TSuperLemmixManifest.GetUpdatePlan(const BaseFolder: string): TObjectList<TUpdateActionItem>;
var
  Pair: TPair<string, TFileEntry>;
  Action: TManifestAction;
begin
  if not TDirectory.Exists(BaseFolder) then
    raise Exception.CreateFmt('Installation folder not found: %s', [BaseFolder]);

  Result := TObjectList<TUpdateActionItem>.Create(True);
  try
    for Pair in fEntries do
    begin
      if SameText(Pair.Key, 'SuperLemmix.exe') then
        Continue;

      if IsInScope(Pair.Key, 'styles') then
        Continue;

      Action := GetFileAction(BaseFolder, Pair.Key);

      if Action = maNone then
        Continue;

      Result.Add(TUpdateActionItem.Create(Pair.Key, Action));
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
