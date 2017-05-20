{$include lem_directives.inc}

program NeoLemmix;

uses
  LemRes,
  Forms,
  FMain in 'FMain.pas' {MainForm},
  GameWindowInterface in 'GameWindowInterface.pas',
  GameBaseSkillPanel in 'GameBaseSkillPanel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'NeoLemmix';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
