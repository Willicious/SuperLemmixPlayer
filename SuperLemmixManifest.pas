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
  System.SysUtils, System.Classes, System.IniFiles, System.Hash,
  System.IOUtils, System.Generics.Collections, System.Types;

type
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
    FEntries: TObjectDictionary<string, TFileEntry>;

    function NormalizePath(const BaseFolder, FullPath: string): string;
    function ComputeShortHash(const FileName: string): string;
    function IsInScope(const RelativePath, RelativeFolder: string): Boolean;

    procedure AddOrUpdateFile(const RelativePath, Hash: string);
    procedure MarkFileDeleted(const RelativePath: string);
  public
    constructor Create;
    destructor Destroy; override;

    // Build-time
    procedure ScanFolders(const BaseFolder: string; const RelativeFolders: array of string);
    procedure LoadFromIni(const FileName: string);
    procedure SaveToIni(const FileName: string);

    // Runtime
    procedure LoadFromResource(const ResourceName: string);
    function GetCurrentHash(const RelativePath: string): string;
    function IsKnownHash(const RelativePath, Hash: string): Boolean;
  end;

implementation

uses
  Windows;

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
  FEntries := TObjectDictionary<string, TFileEntry>.Create([doOwnsValues]);
end;

destructor TSuperLemmixManifest.Destroy;
begin
  FEntries.Free;
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

procedure TSuperLemmixManifest.AddOrUpdateFile(const RelativePath, Hash: string);
var
  Entry: TFileEntry;
begin
  if not FEntries.TryGetValue(RelativePath, Entry) then
  begin
    Entry := TFileEntry.Create;
    Entry.Current := Hash;
    Entry.Known.Add(Hash);
    FEntries.Add(RelativePath, Entry);
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
        AddOrUpdateFile(RelPath, Hash);
      end;
    end;

    { Mark previously known files as deleted when they are no
      longer present in any of the selected folder scopes }
    for Pair in FEntries do
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

    for I := 0 to Sections.Count - 1 do
    begin
      Entry := TFileEntry.Create;
      Entry.Current := Ini.ReadString(Sections[I], 'Current', '');

      KnownStr := Ini.ReadString(Sections[I], 'Known', '');
      KnownItems := KnownStr.Split([',']);

      for S in KnownItems do
        if Trim(S) <> '' then
          if not Entry.Known.Contains(Trim(S)) then
            Entry.Known.Add(Trim(S));

      if (Entry.Current <> '') and not Entry.Known.Contains(Entry.Current) then
        Entry.Known.Add(Entry.Current);

      FEntries.AddOrSetValue(Sections[I], Entry);
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

    for Pair in FEntries do
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

procedure TSuperLemmixManifest.LoadFromResource(const ResourceName: string);
var
  ResStream: TResourceStream;
  Strings: TStringList;
  Ini: TMemIniFile;
  Sections: TStringList;
  I: Integer;
  Entry: TFileEntry;
  KnownStr: string;
  KnownItems: TArray<string>;
  S: string;
begin
  ResStream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
  try
    Strings := TStringList.Create;
    try
      Strings.LoadFromStream(ResStream);

      Ini := TMemIniFile.Create('');
      try
        Ini.SetStrings(Strings);

        Sections := TStringList.Create;
        try
          Ini.ReadSections(Sections);

          for I := 0 to Sections.Count - 1 do
          begin
            Entry := TFileEntry.Create;
            try
              Entry.Current := Ini.ReadString(
                Sections[I], 'Current', '');

              KnownStr := Ini.ReadString(
                Sections[I], 'Known', '');

              KnownItems := KnownStr.Split([',']);

              for S in KnownItems do
                if Trim(S) <> '' then
                  if not Entry.Known.Contains(Trim(S)) then
                    Entry.Known.Add(Trim(S));

              if (Entry.Current <> '') and not Entry.Known.Contains(Entry.Current) then
                Entry.Known.Add(Entry.Current);

              FEntries.AddOrSetValue(Sections[I], Entry);
              Entry := nil;
            finally
              Entry.Free;
            end;
          end;
        finally
          Sections.Free;
        end;
      finally
        Ini.Free;
      end;
    finally
      Strings.Free;
    end;
  finally
    ResStream.Free;
  end;
end;

function TSuperLemmixManifest.GetCurrentHash(const RelativePath: string): string;
var
  Entry: TFileEntry;
begin
  if FEntries.TryGetValue(LowerCase(StringReplace(RelativePath, '/', '\', [rfReplaceAll])), Entry) then
    Result := Entry.Current
  else
    Result := '';
end;

function TSuperLemmixManifest.IsKnownHash(const RelativePath, Hash: string): Boolean;
var
  Entry: TFileEntry;
begin
  if FEntries.TryGetValue(LowerCase(StringReplace(RelativePath, '/', '\', [rfReplaceAll])), Entry) then
    Result := Entry.Known.Contains(LowerCase(Hash))
  else
    Result := False;
end;

procedure TSuperLemmixManifest.MarkFileDeleted(const RelativePath: string);
var
  Entry: TFileEntry;
begin
  if FEntries.TryGetValue(RelativePath, Entry) then
    Entry.Current := '';
end;

end.
