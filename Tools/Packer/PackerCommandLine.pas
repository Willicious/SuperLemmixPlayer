unit PackerCommandLine;

interface

uses
  Forms,
  LemGame,
  AppController,
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
  DecoyAppController: TAppController;
begin
  GlobalGame := TLemmingGame.Create(nil);
  DecoyAppController := TAppController.Create(TForm.Create(nil));

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
    DecoyAppController.Free;
    GlobalGame.Free;
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

  LoadDefaultContentList;
  RunCommandLineBuild;
end;

end.