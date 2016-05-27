{$include lem_directives.inc}

program NeoLemmix;

uses
  LemRes,
  Forms,
  FMain in 'FMain.pas' {MainForm},
  LemObjects in 'LemObjects.pas',
  LemRecolorSprites in 'LemRecolorSprites.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'NeoLemmix';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
