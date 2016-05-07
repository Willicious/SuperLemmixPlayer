unit ParserTest;

interface

uses
  LemNeoParser,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    ShowMessage('assign');
    SL.Assign(Memo1.Lines);
    ShowMessage('rf');
    RemoveFluff(SL);
    ShowMessage('clear');
    Memo1.Clear;
    ShowMessage('recopy');
    //for i := 0 to SL.Count-1 do
    //  Memo1.Lines.Add(SL[i]);
    Memo1.Lines.Assign(SL);
    ShowMessage('update');
    Memo1.Update;
  finally
    ShowMessage('free');
    SL.Free;
  end;
end;

end.
