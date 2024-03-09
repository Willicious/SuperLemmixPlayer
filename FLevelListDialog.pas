unit FLevelListDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFLevelListDialog = class(TForm)
    ListBoxFiles: TListBox;
    btnSelect: TButton;
    procedure btnSelectClick(Sender: TObject);
  private
    FSelectedFileName: string;
  public
    property SelectedFileName: string read FSelectedFileName write FSelectedFileName;
  end;

implementation

{$R *.dfm}

procedure TFLevelListDialog.btnSelectClick(Sender: TObject);
begin
  if ListBoxFiles.ItemIndex <> -1 then
    SelectedFileName := ListBoxFiles.Items[ListBoxFiles.ItemIndex];
  ModalResult := mrOk;
end;

end.
