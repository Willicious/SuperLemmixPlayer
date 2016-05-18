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
  NLP: TNeoLemmixParser;
begin
  NLP := TNeoLemmixParser.Create;
  NLP.LoadFromStringList(Memo1.Lines);
  Memo1.Lines.Assign(NLP.StringList);
  Memo1.Update;
end;

end.
