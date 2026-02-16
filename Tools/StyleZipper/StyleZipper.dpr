program StyleZipper;

{$R *.res}

uses
  Vcl.Forms,
  Main in 'Main.pas',
  StyleZipCore in 'StyleZipCore.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormStyleZipper, FormStyleZipper);
  Application.Run;
end.
