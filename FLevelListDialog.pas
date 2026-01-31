unit FLevelListDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  LemNeoLevelPack,
  SharedGlobals;

type
  TFLevelListDialog = class(TForm)
    MatchingLevelsList: TListBox;
    btnSelect: TButton;
    procedure btnSelectClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    fSelectedLevel: TNeoLevelEntry;
  public
    property SelectedLevel: TNeoLevelEntry read fSelectedLevel write fSelectedLevel;
  end;

implementation

{$R *.dfm}

procedure TFLevelListDialog.btnSelectClick(Sender: TObject);
begin
  if MatchingLevelsList.ItemIndex <> -1 then
    SelectedLevel := TNeoLevelEntry(MatchingLevelsList.Items.Objects[MatchingLevelsList.ItemIndex]);

  ModalResult := mrOk;
end;

procedure TFLevelListDialog.FormResize(Sender: TObject);
begin
  // Center the "Load" button horizontally when the form is resized
  btnSelect.Left := (ClientWidth - btnSelect.Width) div 2;
end;

end.
