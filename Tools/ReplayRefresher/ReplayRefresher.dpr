program ReplayRefresher;

uses
  Vcl.Forms,
  FReplayRefesherMain in 'FReplayRefesherMain.pas' {FNLReplayRefresher};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFNLReplayRefresher, FNLReplayRefresher);
  Application.Run;
end.
