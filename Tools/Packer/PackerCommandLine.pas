unit PackerCommandLine;

interface

uses
  Forms,
  SysUtils, IOUtils, Classes,
  PackRecipe, PackerDefaultContent;

  function RunCommandLine: Boolean;

implementation

procedure RunCommandLineBuild;
var
  BasePath: String;
  InputFile: String;
  OutputFile: String;
  OutputMetaFile: String;
  CmdLineRecipe: TPackageRecipe;
begin
  CmdLineRecipe := TPackageRecipe.Create;
  try
    BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

    InputFile := ParamStr(1);
    if not TPath.IsPathRooted(InputFile) then
      InputFile := BasePath + InputFile;

    OutputFile := ParamStr(2);
    if OutputFile = '' then
      OutputFile := ChangeFileExt(ParamStr(1), '.nx.zip')
    else if not TPath.IsPathRooted(OutputFile) then
      OutputFile := BasePath + OutputFile;

    OutputMetaFile := ParamStr(3);
    if (OutputMetaFile <> '') and (not TPath.IsPathRooted(OutputMetaFile)) then
      OutputMetaFile := BasePath + OutputMetaFile;

    CmdLineRecipe.LoadFromFile(InputFile);
    CmdLineRecipe.ExportPackage(OutputFile, OutputMetaFile);
  finally
    CmdLineRecipe.Free;
  end;
end;

procedure PackEachStyle;
var
  BasePath: String;
  SearchRec: TSearchRec;
  Recipe: TPackageRecipe;
  Style: TRecipeStyle;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

  if FindFirst(BasePath + 'styles\*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then Continue;
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;

      Recipe := TPackageRecipe.Create;
      Style := TRecipeStyle.Create;
      try
        Style.StyleName := SearchRec.Name;
        Style.Include := siFull;
        Recipe.Styles.Add(Style);

        Recipe.PackageName := SearchRec.Name;
        Recipe.PackageType := 'style';
        Recipe.PackageVersion := FormatDateTime('yymmdd-hhmmss', Now);

        ForceDirectories(BasePath + 'stylezips');
        Recipe.ExportPackage(BasePath + 'stylezips\' + SearchRec.Name + '.zip');
      finally
        Recipe.Free;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function RunCommandLine: Boolean;
begin
  Result := false;
  if ParamStr(1) = '' then Exit;

  Result := true;

  if ParamStr(1) = '-d' then
  begin
    BuildDefaultContentList;
    Exit;
  end;

  if ParamStr(1) = '-all-styles' then
  begin
    PackEachStyle;
    Exit;
  end;

  LoadDefaultContentList;
  RunCommandLineBuild;
end;

end.