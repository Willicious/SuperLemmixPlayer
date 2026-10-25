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
    procedure AddOrUpdateFile(const RelativePath, Hash: string);

  public
    constructor Create;
    destructor Destroy; override;

    // Build-time
    procedure ScanFolder(const BaseFolder: string; IncludeSubfolders: Boolean = True);
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
end;

function TSuperLemmixManifest.ComputeShortHash(const FileName: string): string;
begin
  Result := Copy(LowerCase(THashSHA2.GetHashStringFromFile(FileName)), 1, 16);
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

  // If hash changed, update current and preserve history
  if Entry.Current <> Hash then
  begin
    if not Entry.Known.Contains(Entry.Current) then
      Entry.Known.Add(Entry.Current);

    Entry.Current := Hash;
  end;

  if not Entry.Known.Contains(Hash) then
    Entry.Known.Add(Hash);
end;

procedure TSuperLemmixManifest.ScanFolder(const BaseFolder: string; IncludeSubfolders: Boolean);
var
  Files: TStringDynArray;
  FilePath, RelPath, Hash: string;
  SearchOpt: TSearchOption;
begin
  if IncludeSubfolders then
    SearchOpt := TSearchOption.soAllDirectories
  else
    SearchOpt := TSearchOption.soTopDirectoryOnly;

  Files := TDirectory.GetFiles(BaseFolder, '*.*', SearchOpt);

  for FilePath in Files do
  begin
    // TODO: Add filter to only search in certain folders

    RelPath := NormalizePath(BaseFolder, FilePath);
    Hash := ComputeShortHash(FilePath);
    AddOrUpdateFile(RelPath, Hash);
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
        if S <> '' then
          Entry.Known.Add(Trim(S));

      if not Entry.Known.Contains(Entry.Current) then
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
  Ini: TIniFile;
  Pair: TPair<string, TFileEntry>;
  KnownStr: string;
begin
  Ini := TIniFile.Create(FileName);
  try
    Ini.EraseSection('');

    for Pair in FEntries do
    begin
      KnownStr := string.Join(',', Pair.Value.Known.ToArray);

      Ini.WriteString(Pair.Key, 'Current', Pair.Value.Current);
      Ini.WriteString(Pair.Key, 'Known', KnownStr);
    end;

  finally
    Ini.Free;
  end;
end;

procedure TSuperLemmixManifest.LoadFromResource(const ResourceName: string);
var
  ResStream: TResourceStream;
  Ini: TMemIniFile;
  Sections: TStringList;
  Entry: TFileEntry;
  KnownStr: string;
  KnownItems: TArray<string>;
  S: string;
  SL: TStringList;
begin
  ResStream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
  try
    SL := TStringList.Create;
    try
      SL.LoadFromStream(ResStream, TEncoding.UTF8);

      Ini := TMemIniFile.Create('');
      try
        Ini.SetStrings(SL);

        Sections := TStringList.Create;
        try
          Ini.ReadSections(Sections);
          for var I := 0 to Sections.Count - 1 do
          begin
            Entry := TFileEntry.Create;
            Entry.Current := Ini.ReadString(Sections[I], 'Current', '');
            KnownStr := Ini.ReadString(Sections[I], 'Known', '');
            KnownItems := KnownStr.Split([',']);
            for S in KnownItems do
              if S <> '' then
                Entry.Known.Add(Trim(S));
            if not Entry.Known.Contains(Entry.Current) then
              Entry.Known.Add(Entry.Current);
            FEntries.AddOrSetValue(Sections[I], Entry);
          end;
        finally
          Sections.Free;
        end;

      finally
        Ini.Free;
      end;
    finally
      SL.Free;
    end;
  finally
    ResStream.Free;
  end;
end;

function TSuperLemmixManifest.GetCurrentHash(const RelativePath: string): string;
var
  Entry: TFileEntry;
begin
  if FEntries.TryGetValue(RelativePath, Entry) then
    Result := Entry.Current
  else
    Result := '';
end;

function TSuperLemmixManifest.IsKnownHash(const RelativePath, Hash: string): Boolean;
var
  Entry: TFileEntry;
begin
  if FEntries.TryGetValue(RelativePath, Entry) then
    Result := Entry.Known.Contains(Hash)
  else
    Result := False;
end;

end.
