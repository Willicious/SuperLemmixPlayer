unit PackerMain;

interface

uses
  LemRes,
  LemGame, AppController,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ExtCtrls;

type
  TFNLContentPacker = class(TForm)
    ListBox1: TListBox;
    lblContentList: TLabel;
    gbLevelPack: TGroupBox;
    gbStyle: TGroupBox;
    GroupBox2: TGroupBox;
    btnDelete: TButton;
    MainMenu1: TMainMenu;
    msFile: TMenuItem;
    miNew: TMenuItem;
    miOpen: TMenuItem;
    miSave: TMenuItem;
    miSaveAs: TMenuItem;
    miFileSep1: TMenuItem;
    miExport: TMenuItem;
    miFileSep2: TMenuItem;
    miQuit: TMenuItem;
    cbLevelPack: TComboBox;
    rgPackGraphicSets: TRadioGroup;
    rgPackMusic: TRadioGroup;
    procedure FormCreate(Sender: TObject);
  private
    AppController: TAppController;
  public
    { Public declarations }
  end;

var
  FNLContentPacker: TFNLContentPacker;

implementation

{$R *.dfm}

procedure TFNLContentPacker.FormCreate(Sender: TObject);
begin
  GlobalGame := TLemmingGame.Create(nil);
  AppController := TAppController.Create(TForm.Create(self)); // Dummy form, so this one doesn't get messed with.
end;

end.
