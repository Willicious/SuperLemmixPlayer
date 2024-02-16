program SLXQuickMod;

uses
  Vcl.Forms,
  QuickModMainForm in 'QuickModMainForm.pas' {FQuickmodMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFQuickmodMain, FQuickmodMain);
  Application.Title := 'SLX QuickMod';
  Application.Run;
end.
