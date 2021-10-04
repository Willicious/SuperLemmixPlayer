program StyleMetaGen;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Metagen;

var
  Processor: TStyleProcessor;

begin
  try
    Processor := TStyleProcessor.Create;
    try

    finally
      Processor.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
