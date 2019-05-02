program NLPacker;

uses
  AppController,
  LemGame,
  PackerCommandLine,
  Vcl.Forms,
  PackerMain in 'PackerMain.pas' {FNLContentPacker};

var
  DecoyAppController: TAppController;

{$R *.res}
begin
  GlobalGame := TLemmingGame.Create(nil);
  DecoyAppController := TAppController.Create(TForm.Create(nil));
  try
    if not RunCommandLine then
    begin
      Application.Initialize;
      Application.MainFormOnTaskbar := True;
      Application.CreateForm(TFNLContentPacker, FNLContentPacker);
      Application.Run;
    end;
  finally
  DecoyAppController.Free;
  end;
end.
