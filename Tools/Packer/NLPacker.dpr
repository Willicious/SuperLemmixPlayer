program NLPacker;

uses
  PackerCommandLine,
  Vcl.Forms,
  PackerMain in 'PackerMain.pas' {FNLContentPacker};

{$R *.res}
begin
  if not RunCommandLine then
  begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TFNLContentPacker, FNLContentPacker);
    Application.Run;
  end;
end.
