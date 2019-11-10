program NLPacker;
{$AppType CONSOLE}

uses
  AppController,
  LemGame,
  LemRes,
  Vcl.Forms,
  PackerCommandLine in 'PackerCommandLine.pas',
  PackerDefaultContent in 'PackerDefaultContent.pas',
  PackRecipe in 'PackRecipe.pas',
  SysUtils;

var
  DecoyAppController: TAppController;

{$R *.res}
begin
  GlobalGame := TLemmingGame.Create(nil);
  DecoyAppController := TAppController.Create(TForm.Create(nil));
  try
    try
      RunCommandLine;
    except
      on E: Exception do
        WriteLn(E.ClassName + ': ' + E.Message);
    end;
  finally
    DecoyAppController.Free;
  end;
end.
