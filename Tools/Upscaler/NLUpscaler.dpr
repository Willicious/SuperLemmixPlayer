program NLUpscaler;

uses
  Vcl.Forms,
  UpscalerMain in 'UpscalerMain.pas' {Form1},
  LemTypesTrimmed in 'LemTypesTrimmed.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
