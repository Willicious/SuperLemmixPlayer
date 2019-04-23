{$include lem_directives.inc}

program NeoLemmix;





uses
  Windows,
  LemRes,
  Forms,
  FMain in 'FMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'NeoLemmix';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
