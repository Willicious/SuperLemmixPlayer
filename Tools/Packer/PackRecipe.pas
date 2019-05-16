unit PackRecipe;

interface

uses
  Zip,
  Classes,
  SysUtils, StrUtils, IOUtils,
  LemNeoLevelPack, LemLevel, LemTypes, LemNeoPieceManager, LemNeoTheme,
  GameSound, LemGadgetsMeta,
  Generics.Collections,
  PackerDefaultContent;

type
  TStyleInclude = (siFull, siPartial, siNone);

  TRecipePack = class
    public
      PackFolder: String;
      NewStylesInclude: TStyleInclude;
      NewMusicInclude: Boolean;
      ResourcesOnly: Boolean;
  end;

  TRecipeStyle = class
    public
      AutoAdded: Boolean;
      StyleName: String;
      Include: TStyleInclude;
  end;

  TRecipeFile = class
    public
      AutoAdded: Boolean;
      FilePath: String;
  end;

  TPackageRecipe = class
    private
      fFilePath: String;
    
      fPackageName: String;
      fPackageAuthor: String;
      fPackageType: String;
      fPackageVersion: String;
      
      fPacks: TObjectList<TRecipePack>;
      fStyles: TObjectList<TRecipeStyle>;
      fFiles: TObjectList<TRecipeFile>;

      procedure BuildPackAutoAdds(aPack: TRecipePack); overload;
      procedure BuildPackAutoAdds(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aLemmings, aMusic: TStringList); overload;
      procedure BuildPackAutoAddLists(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aLemmings, aMusic: TStringList);
    public
      constructor Create;
      destructor Destroy; override;

      procedure ExportPackage(aDest: TFilename; aMetaInfo: TFilename = ''; aPackageInfoText: Boolean = true);

      procedure LoadFromFile(aFile: TFilename);
      procedure SaveToFile(aFile: TFilename);
      procedure LoadFromStream(aStream: TStream);
      procedure SaveToStream(aStream: TStream);

      procedure ClearAutoAdds;
      procedure BuildAutoAdds;

      property FilePath: String read fFilePath write fFilePath;

      property PackageName: String read fPackageName write fPackageName;
      property PackageAuthor: String read fPackageAuthor write fPackageAuthor;
      property PackageType: String read fPackageType write fPackageType;
      property PackageVersion: String read fPackageVersion write fPackageVersion;
      
      property Packs: TObjectList<TRecipePack> read fPacks;
      property Styles: TObjectList<TRecipeStyle> read fStyles;
      property Files: TObjectList<TRecipeFile> read fFiles;
  end;

implementation

uses
  GameControl;

constructor TPackageRecipe.Create;
begin
  fPacks := TObjectList<TRecipePack>.Create;
  fStyles := TObjectList<TRecipeStyle>.Create;
  fFiles := TObjectList<TRecipeFile>.Create;
end;

destructor TPackageRecipe.Destroy;
begin
  fPacks.Free;
  fStyles.Free;
  fFiles.Free;
end;

procedure TPackageRecipe.ExportPackage(aDest: TFileName; aMetaInfo: TFileName = ''; aPackageInfoText: Boolean = true);
var
  ZipFile: TZipFile;

  FilesToAdd: TStringList;
  RequiredObjects, RequiredTerrain, RequiredBackgrounds, RequiredMusic, RequiredThemes, RequiredLemmings: TStringList;

  MetaInfoStream: TMemoryStream;
  i: Integer;

  procedure AddWildcard(aPath: String; aExpression: String);
  var
    SearchRec: TSearchRec;
  begin
    aPath := IncludeTrailingPathDelimiter(aPath);
    if FindFirst(AppPath + aPath + aExpression, faReadOnly, SearchRec) = 0 then
    begin
      repeat
        FilesToAdd.Add(aPath + SearchRec.Name);  
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure AddFolder(aPath: String);
  begin
    AddWildcard(aPath, '*');
  end;

  procedure AddFolderRecursive(aPath: String);
  var
    SearchRec: TSearchRec;
  begin
    aPath := IncludeTrailingPathDelimiter(aPath);
    if FindFirst(AppPath + aPath + '*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if ((SearchRec.Attr and faDirectory) <> 0) then
        begin
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
            AddFolderRecursive(aPath + SearchRec.Name);
        end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);

      AddFolder(aPath);
    end;
  end;
  
  procedure AddPacks;
  var
    ThisPack: TRecipePack;
    i: Integer;
  begin
    for i := 0 to fPacks.Count-1 do
    begin
      ThisPack := fPacks[i];
      BuildPackAutoAdds(ThisPack, RequiredObjects, RequiredTerrain, RequiredBackgrounds, RequiredThemes, RequiredLemmings, RequiredMusic);
      if not ThisPack.ResourcesOnly then
        AddFolderRecursive(IncludeTrailingPathDelimiter('levels') + ThisPack.PackFolder);
    end;
  end;

  procedure AddRequiredPiecesOnly(aStyle: TRecipeStyle);
  var
    i: Integer;

    function ExtractSet(aIdentifier: String): String;
    var
      SplitPos: Integer;
    begin
      SplitPos := Pos(':', aIdentifier);
      Result := LeftStr(aIdentifier, SplitPos-1);
    end;

    function ExtractPiece(aIdentifier: String): String;
    var
      SplitPos: Integer;
    begin
      SplitPos := Pos(':', aIdentifier);
      Result := RightStr(aIdentifier, Length(aIdentifier) - SplitPos);
    end;
  begin
    for i := 0 to RequiredObjects.Count-1 do
    begin
      if ExtractSet(RequiredObjects[i]) <> aStyle.StyleName then
        Continue;

      AddWildcard(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) +
                  IncludeTrailingPathDelimiter('objects'), ExtractPiece(RequiredObjects[i]) + '.*');
      AddWildcard(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) +
                  IncludeTrailingPathDelimiter('objects'), ExtractPiece(RequiredObjects[i]) + '_mask*');
    end;

    for i := 0 to RequiredTerrain.Count-1 do
    begin
      if ExtractSet(RequiredTerrain[i]) <> aStyle.StyleName then
        Continue;

      AddWildcard(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) +
                  IncludeTrailingPathDelimiter('terrain'), ExtractPiece(RequiredTerrain[i]) + '.*');
    end;

    for i := 0 to RequiredBackgrounds.Count-1 do
    begin
      if ExtractSet(RequiredBackgrounds[i]) <> aStyle.StyleName then
        Continue;

      AddWildcard(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) +
                  IncludeTrailingPathDelimiter('backgrounds'), ExtractPiece(RequiredBackgrounds[i]) + '.*');
    end;

    if RequiredThemes.IndexOf(aStyle.StyleName) >= 0 then
      FilesToAdd.Add(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) + 'theme.nxtm');

    if RequiredLemmings.IndexOf(aStyle.StyleName) >= 0 then
      AddFolder(IncludeTrailingPathDelimiter('styles') + IncludeTrailingPathDelimiter(aStyle.StyleName) + 'lemmings');
  end;

  procedure AddStyles;
  var
    i: Integer;
    ThisStyle: TRecipeStyle;
  begin
    for i := 0 to fStyles.Count-1 do
    begin
      ThisStyle := fStyles[i];

      if (ThisStyle.Include = siFull) then
        AddFolderRecursive(IncludeTrailingPathDelimiter('styles') + ThisStyle.StyleName)
      else if (ThisStyle.Include = siPartial) then
        AddRequiredPiecesOnly(ThisStyle);
      // else if siNone, do nothing
    end;
  end;

  procedure AddFiles;
  var
    i: Integer;
  begin
    for i := 0 to fFiles.Count-1 do
      FilesToAdd.Add(fFiles[i].FilePath);
  end;

  procedure MakeMetaInfo;
  var
    SL: TStringList;
  begin
    SL := TStringList.Create;
    try
      SL.Add('NAME=' + fPackageName);
      SL.Add('AUTHOR=' + fPackageAuthor);
      SL.Add('TYPE=' + fPackageType);
      SL.Add('VERSION=' + fPackageVersion);
      SL.SaveToStream(MetaInfoStream);
    finally
      SL.Free;
    end;
  end;
begin
  if not TPath.IsPathRooted(aDest) then
    aDest := AppPath + aDest;

  if not TPath.IsPathRooted(aMetaInfo) then
    aMetaInfo := AppPath + aMetaInfo;

  FilesToAdd := TStringList.Create;
  MetaInfoStream := TMemoryStream.Create;
  try
    RequiredObjects := TStringList.Create;
    RequiredTerrain := TStringList.Create;
    RequiredBackgrounds := TStringList.Create;
    RequiredMusic := TStringList.Create;
    RequiredThemes := TStringList.Create;
    RequiredLemmings := TStringList.Create;
    try
      ClearAutoAdds;

      AddPacks;
      AddStyles;
      AddFiles;
      MakeMetaInfo;
    finally
      RequiredObjects.Free;
      RequiredTerrain.Free;
      RequiredBackgrounds.Free;
      RequiredMusic.Free;
      RequiredThemes.Free;    
      RequiredLemmings.Free;
    end;

    ZipFile := TZipFile.Create;
    try
      if FileExists(aDest) then
        DeleteFile(aDest);

      ZipFile.Open(aDest, zmWrite);

      if aPackageInfoText then
      begin
        MetaInfoStream.Position := 0;
        ZipFile.Add(MetaInfoStream, 'package_meta.nxmi');
      end;

      for i := 0 to FilesToAdd.Count-1 do
        ZipFile.Add(AppPath + FilesToAdd[i], FilesToAdd[i]);

      ZipFile.Close;
    finally
      ZipFile.Free;
    end;
  finally
    FilesToAdd.Free;
    MetaInfoStream.Free;
  end;
end;

procedure TPackageRecipe.LoadFromFile(aFile: TFileName);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmOpenRead);
  try
    LoadFromStream(F);
    fFilePath := aFile;
  finally
    F.Free;
  end;
end;

procedure TPackageRecipe.SaveToFile(aFile: TFileName);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmCreate);
  try
    SaveToStream(F);
    fFilePath := aFile;
  finally
    F.Free;
  end;
end;

procedure TPackageRecipe.LoadFromStream(aStream: TStream);
var
  SL, SubSL: TStringList;
  i: Integer;

  NewPack: TRecipePack;
  NewStyle: TRecipeStyle;
  NewFile: TRecipeFile;

  S: String;
begin
  SL := TStringList.Create;
  SubSL := TStringList.Create;
  try
    SubSL.Delimiter := '|';
    SubSL.StrictDelimiter := true;

    SL.LoadFromStream(aStream);

    for i := 0 to SL.Count-1 do
      if Trim(SL[i]) <> '' then
      begin
        SubSL.DelimitedText := SL[i];

        if UpperCase(SubSL[0]) = 'PACK' then
        begin
          NewPack := TRecipePack.Create;
        
          NewPack.PackFolder := SubSL.Values['FOLDER'];

          S := UpperCase(SubSL.Values['NEW_STYLES_INCLUDE']);
          if (S = 'FULL') then
            NewPack.NewStylesInclude := siFull
          else if (S = 'PARTIAL') then
            NewPack.NewStylesInclude := siPartial
          else
            NewPack.NewStylesInclude := siNone;

          NewPack.NewMusicInclude := Uppercase(SubSL.Values['NEW_MUSIC_INCLUDE']) = 'TRUE';
          NewPack.ResourcesOnly := Uppercase(SubSL.Values['RESOURCES_ONLY']) = 'TRUE';

          Packs.Add(NewPack);  
        end else if UpperCase(SubSL[0]) = 'STYLE' then
        begin
          NewStyle := TRecipeStyle.Create;
        
          NewStyle.AutoAdded := false;
          NewStyle.StyleName := SubSL.Values['NAME'];

          if Uppercase(SubSL.Values['INCLUDE']) = 'PARTIAL' then
            NewStyle.Include := siPartial
          else if Uppercase(SubSL.Values['INCLUDE']) = 'NONE' then
            NewStyle.Include := siNone
          else
            NewStyle.Include := siFull;

          Styles.Add(NewStyle);
        end else if UpperCase(SubSL[0]) = 'FILE' then
        begin
          NewFile := TRecipeFile.Create;
          
          NewFile.AutoAdded := false;
          NewFile.FilePath := SubSL.Values['PATH'];

          Files.Add(NewFile);
        end else if UpperCase(SubSL[0]) = 'META' then
        begin
          fPackageName := SubSL.Values['NAME'];
          fPackageAuthor := SubSL.Values['AUTHOR'];
          fPackageType := SubSL.Values['TYPE'];
          fPackageVersion := SubSL.Values['VERSION'];
        end;
      end;
    BuildAutoAdds;
  finally
    SL.Free;
    SubSL.Free;
  end;
end;

procedure TPackageRecipe.SaveToStream(aStream: TStream);
var
  SL, SubSL: TStringList;
  i: Integer;

  ThisPack: TRecipePack;
  ThisStyle: TRecipeStyle;
  ThisFile: TRecipeFile;
begin
  SL := TStringList.Create;
  SubSL := TStringList.Create;
  try
    SubSL.Delimiter := '|';
    SubSL.StrictDelimiter := true;

    SubSL.Add('META');
    SubSL.Add('NAME=' + fPackageName);
    SubSL.Add('AUTHOR=' + fPackageAuthor);
    SubSL.Add('TYPE=' + fPackageType);
    SubSL.Add('VERSION=' + fPackageVersion);
    SL.Add(SubSL.DelimitedText);

    for i := 0 to fPacks.Count-1 do
    begin
      ThisPack := fPacks[i];
      SubSL.Clear;

      SubSL.Add('PACK');
      SubSL.Add('FOLDER=' + ThisPack.PackFolder);

      if ThisPack.NewStylesInclude = siFull then
        SubSL.Add('NEW_STYLES_INCLUDE=FULL')
      else if ThisPack.NewStylesInclude = siPartial then
        SubSL.Add('NEW_STYLES_INCLUDE=PARTIAL')
      else
        SubSL.Add('NEW_STYLES_INCLUDE=NONE');

      if ThisPack.NewMusicInclude then
        SubSL.Add('NEW_MUSIC_INCLUDE=TRUE')
      else
        SubSL.Add('NEW_MUSIC_INCLUDE=FALSE');

      if ThisPack.ResourcesOnly then
        SubSL.Add('RESOURCES_ONLY=TRUE')
      else
        SubSL.Add('RESOURCES_ONLY=FALSE');

      SL.Add(SubSL.DelimitedText);
    end;

    for i := 0 to fStyles.Count-1 do
    begin
      ThisStyle := fStyles[i];
      if ThisStyle.AutoAdded then
        Continue;

      SubSL.Clear;

      SubSL.Add('STYLE');
      SubSL.Add('NAME=' + ThisStyle.StyleName);

      if ThisStyle.Include = siFull then
        SubSL.Add('INCLUDE=FULL')
      else if ThisStyle.Include = siPartial then
        SubSL.Add('INCLUDE=PARTIAL')
      else
        SubSL.Add('INCLUDE=NONE');

      SL.Add(SubSL.DelimitedText);
    end;

    for i := 0 to fFiles.Count-1 do
    begin
      ThisFile := fFiles[i];
      if ThisFile.AutoAdded then
        Continue;

      SubSL.Clear;

      SubSL.Add('FILE');
      SubSL.Add('PATH=' + ThisFile.FilePath);

      SL.Add(SubSL.DelimitedText);
    end;

    SL.SaveToStream(aStream);
  finally
    SL.Free;
    SubSL.Free;
  end;
end;

procedure TPackageRecipe.ClearAutoAdds;
var
  i: Integer;
begin
  for i := fStyles.Count-1 downto 0 do
    if fStyles[i].AutoAdded then
      fStyles.Delete(i);

  for i := fFiles.Count-1 downto 0 do
    if fFiles[i].AutoAdded then
      fFiles.Delete(i);
end;

procedure TPackageRecipe.BuildAutoAdds;
var
  i: Integer;
begin
  ClearAutoAdds;
  for i := 0 to fPacks.Count-1 do
    BuildPackAutoAdds(fPacks[i]);
end;

procedure TPackageRecipe.BuildPackAutoAdds(aPack: TRecipePack);
var
  UsedObjects: TStringList;
  UsedTerrain: TStringList;
  UsedBackgrounds: TStringList;
  UsedThemes: TStringList;
  UsedLemmings: TStringList;
  UsedMusic: TStringList;
begin
  UsedObjects := TStringList.Create;
  UsedTerrain := TStringList.Create;
  UsedBackgrounds := TStringList.Create;
  UsedThemes := TStringList.Create;
  UsedLemmings := TStringList.Create;
  UsedMusic := TStringList.Create;
  try
    BuildPackAutoAdds(aPack, UsedObjects, UsedTerrain, UsedBackgrounds, UsedThemes, UsedLemmings, UsedMusic);
  finally
    UsedObjects.Free;
    UsedTerrain.Free;
    UsedBackgrounds.Free;
    UsedThemes.Free;
    UsedLemmings.Free;
    UsedMusic.Free;
  end;
end;

procedure TPackageRecipe.BuildPackAutoAdds(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aLemmings, aMusic: TStringList);
var
  UsedStyles: TStringList;
  i: Integer;

  NewStyle: TRecipeStyle;
  NewFile: TRecipeFile;
  n: Integer;

  SkipThis: Boolean;

  procedure AddStyleFromList(Src: TStringList);
  var
    i: Integer;
  begin
    for i := 0 to Src.Count-1 do
      if Pos(':', Src[i]) = 0 then
        UsedStyles.Add(Src[i])
      else
        UsedStyles.Add(MidStr(Src[i], 1, Pos(':', Src[i])-1) );
  end;

  procedure AddStyleSounds(aStyle: TRecipeStyle);
  var
    SoundList: TStringList;
    Info: TGadgetMetaAccessor;
    SearchRec: TSearchRec;
    i, n: Integer;
    S: String;
  begin
    if (aStyle.Include = siNone) then
      Exit; // Just in case.

    SoundList := TStringList.Create;
    try
      SoundList.Sorted := true;
      SoundList.Duplicates := dupIgnore;

      if aStyle.Include = siPartial then
      begin
        for i := 0 to aObjects.Count-1 do
        begin
          if LeftStr(aObjects[i], Length(aStyle.StyleName) + 1) <> aStyle.StyleName + ':' then
            Continue;

          Info := PieceManager.Objects[aObjects[i]].GetInterface(false, false, false);
          if Info.SoundEffect <> '' then
            SoundList.Add(Info.SoundEffect);
        end;
      end else begin
        if FindFirst(AppPath + 'styles\' + aStyle.StyleName + '\objects\*.nxmo', faReadOnly, SearchRec) = 0 then
        begin
          repeat
            Info := PieceManager.Objects[aStyle.StyleName + ':' + ChangeFileExt(SearchRec.Name, '')].GetInterface(false, false, false);
            if Info.SoundEffect <> '' then
              SoundList.Add(Info.SoundEffect);
          until FindNext(SearchRec) <> 0;
          FindClose(SearchRec);
        end;
      end;

      for i := 0 to SoundList.Count-1 do
      begin
        S := 'sound\' + SoundList[i] + SoundManager.FindExtension(SoundList[i], false);

        if IsFileDefaultContent(s) then
          Continue;

        SkipThis := false;
        for n := 0 to fFiles.Count-1 do
          if fFiles[n].FilePath = S then
            SkipThis := true;

        if SkipThis then
          Continue;

        NewFile := TRecipeFile.Create;
        NewFile.AutoAdded := true;
        NewFile.FilePath := S;

        fFiles.Add(NewFile);
      end;
    finally
      SoundList.Free;
    end;
  end;
begin
  if (aPack.NewStylesInclude = siNone) and (aPack.NewMusicInclude = false) then
    Exit;
    
  UsedStyles := TStringList.Create;
  try
    BuildPackAutoAddLists(aPack, aObjects, aTerrains, aBackgrounds, aThemes, aLemmings, aMusic);

    UsedStyles.Sorted := true;
    UsedStyles.Duplicates := dupIgnore;
    AddStyleFromList(aObjects);
    AddStyleFromList(aTerrains);
    AddStyleFromList(aBackgrounds);
    AddStyleFromList(aThemes);
    AddStyleFromList(aLemmings);

    for i := 0 to UsedStyles.Count-1 do
    begin
      if IsStyleDefaultContent(UsedStyles[i]) then
        Continue;

      SkipThis := false;
      for n := 0 to fStyles.Count-1 do
        if fStyles[n].StyleName = UsedStyles[i] then
          SkipThis := true;
        
      if SkipThis then
        Continue;

      NewStyle := TRecipeStyle.Create;
      NewStyle.AutoAdded := true;
      NewStyle.StyleName := UsedStyles[i];
      NewStyle.Include := aPack.NewStylesInclude;

      fStyles.Add(NewStyle);

      AddStyleSounds(NewStyle);
    end;

    for i := 0 to aMusic.Count-1 do
    begin
      if IsFileDefaultContent(aMusic[i]) then
        Continue;

      SkipThis := false;
      for n := 0 to fFiles.Count-1 do
        if fFiles[n].FilePath = aMusic[i] then
          SkipThis := true;

      if SkipThis then
        Continue;

      NewFile := TRecipeFile.Create;
      NewFile.AutoAdded := true;
      NewFile.FilePath := 'music/' + aMusic[i];

      fFiles.Add(NewFile);
    end;
  finally
    UsedStyles.Free;
  end;
end;

procedure TPackageRecipe.BuildPackAutoAddLists(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aLemmings, aMusic: TStringList);
var
  UsedObjects: TStringList;
  UsedTerrain: TStringList;
  UsedBackgrounds: TStringList;
  UsedThemes: TStringList;
  UsedLemmings: TStringList;
  UsedMusic: TStringList;

  i: Integer;
  FoundPack: Boolean;

  procedure RecursiveIdentify(aGroup: TNeoLevelGroup);
  var
    i, n: Integer;
    S: String;

    Level: TLevel;

    TempTheme: TNeoTheme; 
  begin
    for i := 0 to aGroup.Children.Count-1 do
      RecursiveIdentify(aGroup.Children[i]);

    if aPack.NewMusicInclude then
      for i := 0 to aGroup.MusicList.Count-1 do
        UsedMusic.Add(aGroup.MusicList[i] + SoundManager.FindExtension(aGroup.MusicList[i], true));

    TempTheme := TNeoTheme.Create;
    try
      for i := 0 to aGroup.Levels.Count-1 do
      begin
        GameParams.SetLevel(aGroup.Levels[i]);
        GameParams.LoadCurrentLevel(true);
        Level := GameParams.Level;
      
        S := Trim(Level.Info.MusicFile);
        if (S <> '') and (S[1] <> '?') and (aPack.NewMusicInclude) then
        begin
          S := S + SoundManager.FindExtension(S, true);
          UsedMusic.Add(S);
        end;

        if (aPack.NewStylesInclude <> siNone) then
        begin
          UsedThemes.Add(Level.Info.GraphicSetName);

          if (Level.Info.Background <> '') then
            UsedBackgrounds.Add(Level.Info.Background);

          for n := 0 to Level.InteractiveObjects.Count-1 do
            UsedObjects.Add(Level.InteractiveObjects[n].Identifier);

          for n := 0 to Level.Terrains.Count-1 do
            UsedTerrain.Add(Level.Terrains[n].Identifier);

          TempTheme.Load(Level.Info.GraphicSetName);
          if TempTheme.Lemmings <> '' then
            UsedLemmings.Add(TempTheme.Lemmings);
        end;
      end;
    finally
      TempTheme.Free;
    end;
  end;

  procedure Append(aDest: TStrings; aSrc: TStrings);
  var
    i: Integer;
  begin
    for i := 0 to aSrc.Count-1 do
      aDest.Add(aSrc[i]);
  end;
begin
  if (aPack.NewStylesInclude = siNone) and not aPack.NewMusicInclude then
    Exit;

  FoundPack := false;
  for i := 0 to GameParams.BaseLevelPack.Children.Count-1 do
    if GameParams.BaseLevelPack.Children[i].Folder = aPack.PackFolder then
    begin
      GameParams.SetGroup(GameParams.BaseLevelPack.Children[i]);
      FoundPack := true;
    end;

  if not FoundPack then
    Exit;

  UsedObjects := TStringList.Create;
  UsedTerrain := TStringList.Create;
  UsedBackgrounds := TStringList.Create;
  UsedThemes := TStringList.Create;
  UsedLemmings := TStringList.Create;
  UsedMusic := TStringList.Create;
  try
    UsedObjects.Sorted := true;
    UsedTerrain.Sorted := true;
    UsedBackgrounds.Sorted := true;
    UsedThemes.Sorted := true;
    UsedLemmings.Sorted := true;
    UsedMusic.Sorted := true;
    UsedObjects.Duplicates := dupIgnore;
    UsedTerrain.Duplicates := dupIgnore;
    UsedBackgrounds.Duplicates := dupIgnore;
    UsedThemes.Duplicates := dupIgnore;
    UsedLemmings.Duplicates := dupIgnore;
    UsedMusic.Duplicates := dupIgnore;
  
    RecursiveIdentify(GameParams.CurrentLevel.Group.ParentBasePack);

    Append(aObjects, UsedObjects);
    Append(aTerrains, UsedTerrain);
    Append(aBackgrounds, UsedBackgrounds);
    Append(aThemes, UsedThemes);
    Append(aLemmings, UsedLemmings);
    Append(aMusic, UsedMusic);
  finally
    UsedObjects.Free;
    UsedTerrain.Free;
    UsedBackgrounds.Free;
    UsedThemes.Free;
    UsedLemmings.Free;
    UsedMusic.Free;
  end;
end;

end.