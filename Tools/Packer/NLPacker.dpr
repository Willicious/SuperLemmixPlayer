program NLPacker;

uses
  SysUtils,
  PackRecipe,
  Vcl.Forms,
  PackerMain in 'PackerMain.pas' {FNLContentPacker};

{$R *.res}

var
  OutputFile: String;
  CmdLineRecipe: TPackageRecipe;

begin
  if ParamStr(1) <> '' then
  begin
    CmdLineRecipe := TPackageRecipe.Create;
    try
      OutputFile := ParamStr(2);
      if OutputFile = '' then
        OutputFile := ChangeFileExt(ParamStr(1), '.zip');

      CmdLineRecipe.LoadFromFile(ParamStr(1));
      CmdLineRecipe.ExportPackage(OutputFile, ParamStr(3));
    finally
      CmdLineRecipe.Free;
    end;
  end else begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TFNLContentPacker, FNLContentPacker);
    Application.Run;
  end;
end.
