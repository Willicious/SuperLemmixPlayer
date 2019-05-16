program NLPacker;

uses
  AppController,
  LemGame,
  LemRes,
  PackerCommandLine,
  Vcl.Forms;

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
