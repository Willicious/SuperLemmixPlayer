unit PackerMain;

interface

uses
  LemTypes,
  LemNeoLevelPack,
  LemRes,
  LemGame, AppController,
  GameControl,

  PackRecipe, PackerDefaultContent,

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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fRecipe: TPackageRecipe;
    //fPackInternalNames: TStringList;
    //fStyleInternalNames: TStringList;

    procedure PreparePacksList;
    procedure PrepareStylesList;
  public
    { Public declarations }
  end;

var
  FNLContentPacker: TFNLContentPacker;

implementation

{$R *.dfm}

procedure TFNLContentPacker.FormCreate(Sender: TObject);
begin
  //fPackInternalNames := TStringList.Create;
  //fStyleInternalNames := TStringList.Create;

  LoadDefaultContentList;
  PreparePacksList;
  PrepareStylesList;
end;

procedure TFNLContentPacker.FormDestroy(Sender: TObject);
begin
  //fPackInternalNames.Free;
  //fStyleInternalNames.Free;
end;

procedure TFNLContentPacker.PreparePacksList;
var
  i: Integer;
  ThisGroup: TNeoLevelGroup;
begin
  for i := 0 to GameParams.BaseLevelPack.Children.Count-1 do
  begin
    ThisGroup := GameParams.BaseLevelPack.Children[i];
    cbLevelPack.AddItem(ThisGroup.Name, ThisGroup);
  end;
end;

procedure TFNLContentPacker.PrepareStylesList;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(AppPath + 'styles\*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if ((SearchRec.Attr and faDirectory) = 0) or (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;

      cbGraphicSet.AddItem(SearchRec.Name, nil);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

end.
