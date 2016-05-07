program ParserTestApp;

uses
  SharedGlobals,
  Forms,
  ParserTest in 'ParserTest.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
