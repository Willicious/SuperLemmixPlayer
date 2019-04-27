unit PackRecipe;

interface

uses
  Classes,
  SysUtils,
  Generics.Collections;

type
  TStyleInclude = (siFull, siPartial, siNone);

  TRecipePack = record
    PackFolder: String;
    NewStylesInclude: TStyleInclude;
    NewMusicInclude: Boolean;
  end;

  TRecipeStyle = record
    AutoAdded: Boolean;
    StyleName: String;
    Include: TStyleInclude;
  end;

  TRecipeFile = record
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
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadFromStream(aStream: TStream);
      procedure SaveToStream(aStream: TStream);

      property PackageName: String read fPackageName write fPackageName;
      property PackageType: String read fPackageType write fPackageType;
      property PackageVersion: String read fPackageVersion write fPackageVersion;
      
      property Packs: TList<TRecipePack> read fPacks;
      property Styles: TList<TRecipeStyle> read fStyles;
      property Files: TList<TRecipeFile> read fFiles;
  end;

implementation

constructor TPackageRecipe.Create;
begin
  fPacks := TList<TRecipePack>.Create;
  fStyles := TList<TRecipeStyle>.Create;
  fFiles := TList<TRecipeFile>.Create;
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
          NewFile.AutoAdded := false;
          NewFile.FilePath := SubSL.Values['PATH'];
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

end.