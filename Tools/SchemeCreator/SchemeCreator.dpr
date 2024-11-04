program SchemeCreator;

uses
  Vcl.Forms,
  Main in 'Main.pas' {SchemeCreatorForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSchemeCreatorForm, SchemeCreatorForm);
  Application.Run;
end.
