unit PackerMain;

interface

uses
  LemRes,
  LemGame, AppController,

  PackRecipe,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ExtCtrls;

type
  TFNLContentPacker = class(TForm)
    lbContent: TListBox;
    lblContentList: TLabel;
    gbLevelPack: TGroupBox;
    gbStyle: TGroupBox;
    gbFile: TGroupBox;
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
    cbGraphicSet: TComboBox;
    rgSetFull: TRadioGroup;
    ebFilePath: TEdit;
    btnBrowse: TButton;
    btnFileAdd: TButton;
    Button1: TButton;
    Button2: TButton;
    btnItemOptions: TButton;
    btnGlobalOptions: TButton;
  private
    fRecipe: TPackageRecipe;
  public
    { Public declarations }
  end;

var
  FNLContentPacker: TFNLContentPacker;

implementation

{$R *.dfm}

end.
