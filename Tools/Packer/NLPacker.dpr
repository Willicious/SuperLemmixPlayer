program NLPacker;

uses
  AppController,
  LemGame,
  LemRes,
  Vcl.Forms,
  OptionsPack in 'OptionsPack.pas' {Form1},
  PackerCommandLine in 'PackerCommandLine.pas',
  PackerDefaultContent in 'PackerDefaultContent.pas',
  PackerMain in 'PackerMain.pas' {FNLContentPacker},
  PackRecipe in 'PackRecipe.pas';

var
  DecoyAppController: TAppController;

{$R *.res}
begin
  GlobalGame := TLemmingGame.Create(nil);
  DecoyAppController := TAppController.Create(TForm.Create(nil));
  try
    RunCommandLine;
  finally
    DecoyAppController.Free;
  end;
end.
