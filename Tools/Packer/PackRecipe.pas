unit PackRecipe;

interface

uses
  Classes,
  SysUtils,
  LemNeoLevelPack, LemLevel,
  Generics.Collections;

type
  TStyleInclude = (siFull, siPartial, siNone);

  TRecipePack = class
    public
      PackFolder: String;
      NewStylesInclude: TStyleInclude;
      NewMusicInclude: Boolean;
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
      fPackageName: String;
      fPackageType: String;
      fPackageVersion: String;
      
      fPacks: TList<TRecipePack>;
      fStyles: TList<TRecipeStyle>;
      fFiles: TList<TRecipeFile>;

      procedure ClearAutoAdds;
      procedure BuildAutoAdds;

      procedure BuildPackAutoAdds(aPack: TRecipePack);
      procedure BuildPackAutoAddLists(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aMusic: TStringList);
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadFromStream(aStream: TStream);
      procedure SaveToStream(aStream: TStream);

      property PackageName: String read fPackageName write fPackageName;
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
    SubSL.Delimiter = '|';

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

          NewPack.NewMusicInclude := SubSL.IndexOfName('NEW_MUSIC_INCLUDE') >= 0;

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
          fPackageType := SubSL.Values['TYPE'];
          fPackageVersion := SubSL.Values['VERSION'];
        end;
      end;
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

    SubSL.Add('META');
    SubSL.Add('NAME=' + fPackageName);
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
        SubSL.Add('NEW_MUSIC_INCLUDE');

      SL.Add(SubSL.DelimitedText);
    end;

    for i := 0 to fStyles.Count-1 do
    begin
      ThisStyle = fStyles[i];
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
  for i := 0 to fPacks.Count-1 do
    BuildPackAutoAdds(fPacks[i]);
end;

procedure TPackageRecipe.BuildPackAutoAdds(aPack: TRecipePack);
begin

end;

procedure TPackageRecipe.BuildPackAutoAddLists(aPack: TRecipePack; var aObjects, aTerrains, aBackgrounds, aThemes, aMusic: TStringList);
var
  UsedObjects: TStringList;
  UsedTerrain: TStringList;
  UsedBackgrounds: TStringList;
  UsedThemes: TStringList;
  UsedMusic: TStringList;

  i: Integer;
  FoundPack: Boolean;

  procedure RecursiveIdentify(aPack: TNeoLevelGroup);
  var
    i, n: Integer;
    S: String;

    Level: TLevel;
  begin
    for i := 0 to aPack.Children.Count-1 do
      RecursiveIdentify(aPack.Children[i]);

    for i := 0 to aPack.Levels.Count-1 do
    begin
      GameParams.SetLevel(aPack.Levels[i]);
      GameParams.LoadCurrentLevel(true);
      Level := GameParams.Level;
      
      S := Trim(Level.Info.MusicFile);
      if (S <> '') and (S[1] <> '?') then
        UsedMusic.Add(S);

      UsedThemes.Add(Level.Info.GraphicSetName);

      if (Level.Info.Background <> '') then
        UsedBackgrounds.Add(Level.Info.Background);

      for n := 0 to Level.InteractiveObjects.Count-1 do
        UsedObjects.Add(Level.InteractiveObjects[n].Identifier);

      for n := 0 to Level.Terrains.Count-1 do
        UsedTerrain.Add(Level.Terrains[n].Identifier);
    end;
  end;
begin
  if (aPack.NewStylesInclude = siNone) and not aPack.NewMusicInclude then
    Exit;

  FoundPack := false;
  for i := 0 to GameParams.BaseLevelPack.Children.Count-1 do
    if GameParams.BaseLevelPack.Children[i].Path = aPack.PackFolder then
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
  UsedMusic := TStringList.Create;
  try
    UsedObjects.Duplicates := dupIgnore;
    UsedTerrain.Duplicates := dupIgnore;
    UsedBackgrounds.Duplicates := dupIgnore;
    UsedThemes.Duplicates := dupIgnore;
    UsedMusic.Duplicates := dupIgnore;
  
    RecursiveIdentify(GameParams.CurrentLevel.Group.ParentBasePack);

    aObjects.Assign(UsedObjects);
    aTerrains.Assign(UsedTerrain);
    aBackgrounds.Assign(UsedBackgrounds);
    aThemes.Assign(UsedThemes);
    aMusic.Assign(UsedMusic);
  finally
    UsedObjects.Free;
    UsedTerrain.Free;
    UsedBackgrounds.Free;
    UsedThemes.Free;
    UsedMusic.Free;
  end;
end;

end.