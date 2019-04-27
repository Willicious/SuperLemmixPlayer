program NLPacker;

uses
  Vcl.Forms,
  PackerMain in 'PackerMain.pas' {FNLContentPacker};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFNLContentPacker, FNLContentPacker);
  Application.Run;
end.
