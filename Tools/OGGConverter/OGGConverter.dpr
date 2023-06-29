program OGGConverter;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  bass in 'bass.pas',
  bassenc_ogg in 'bassenc_ogg.pas',
  bassenc in 'bassenc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
