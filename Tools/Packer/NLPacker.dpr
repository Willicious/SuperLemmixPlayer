program NLPacker;

uses
  LemGame,
  AppController,
  SysUtils, IOUtils,
  PackRecipe,
  Vcl.Forms,
  PackerMain in 'PackerMain.pas' {FNLContentPacker};

{$R *.res}

var
  BasePath: String;
  InputFile: String;
  OutputFile: String;
  OutputMetaFile: String;
  CmdLineRecipe: TPackageRecipe;
  DecoyAppController: TAppController;

begin
  if ParamStr(1) <> '' then
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
        OutputFile := ChangeFileExt(ParamStr(1), '.zip')
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
    end;
  end else begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TFNLContentPacker, FNLContentPacker);
    Application.Run;
  end;
end.
