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
    btnStyleAdd: TButton;
    btnPackAdd: TButton;
    btnItemOptions: TButton;
    btnGlobalOptions: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPackAddClick(Sender: TObject);
  private
    fRecipe: TPackageRecipe;
    //fPackInternalNames: TStringList;
    //fStyleInternalNames: TStringList;

    procedure PreparePacksList;
    procedure PrepareStylesList;

    procedure RebuildContentList;
  public
    { Public declarations }
  end;

var
  FNLContentPacker: TFNLContentPacker;

implementation

{$R *.dfm}

procedure TFNLContentPacker.RebuildContentList;
var
  i: Integer;
  SelIndex: Integer;
  S: String;

  ThisPack: TRecipePack;
  ThisStyle: TRecipeStyle;
  ThisFile: TRecipeFile;

  function MakeStyleString(aStyle: TRecipeStyle): String;
  begin
    if aStyle.AutoAdded then
      Result := '(AUTO) STYLE: '
    else
      Result := 'STYLE: ';

    Result := Result + aStyle.StyleName;

    case aStyle.Include of
      siPartial: Result := Result + ' (Partial)';
      siNone: Result := Result + ' <! EXCLUDE !>';
    end;
  end;

  function MakeFileString(aFile: TRecipeFile): String;
  begin
    if aFile.AutoAdded then
      Result := '(AUTO) FILE: '
    else
      Result := 'FILE: ';

    Result := Result + aFile.FilePath;
  end;
begin
  SelIndex := lbContent.ItemIndex;
  try
    lbContent.Items.Clear;

    for i := 0 to fRecipe.Packs.Count-1 do
    begin
      ThisPack := fRecipe.Packs[i];

      S := 'PACK: ' + ThisPack.PackFolder;

      case ThisPack.NewStylesInclude of
        siFull: S := S + ' (Styles)';
        siPartial: S := S + ' (Partial Styles)';
      end;

      if ThisPack.NewMusicInclude then
        S := S + ' (Music)';

      if ThisPack.ResourcesOnly then
        S := S + ' (resources only)';

      lbContent.AddItem(S, ThisPack);
    end;

    for i := 0 to fRecipe.Styles.Count-1 do
    begin
      ThisStyle := fRecipe.Styles[i];
      if ThisStyle.AutoAdded then Continue;
      lbContent.AddItem(MakeStyleString(ThisStyle), ThisStyle);
    end;

    for i := 0 to fRecipe.Styles.Count-1 do
    begin
      ThisStyle := fRecipe.Styles[i];
      if not ThisStyle.AutoAdded then Continue;
      lbContent.AddItem(MakeStyleString(ThisStyle), ThisStyle);
    end;

    for i := 0 to fRecipe.Files.Count-1 do
    begin
      ThisFile := fRecipe.Files[i];
      if ThisFile.AutoAdded then Continue;
      lbContent.AddItem(MakeFileString(ThisFile), ThisFile);
    end;

    for i := 0 to fRecipe.Files.Count-1 do
    begin
      ThisFile := fRecipe.Files[i];
      if not ThisFile.AutoAdded then Continue;
      lbContent.AddItem(MakeFileString(ThisFile), ThisFile);
    end;
  finally
    if SelIndex > lbContent.Items.Count then
      SelIndex := lbContent.Items.Count-1;

    lbContent.ItemIndex := SelIndex;
  end;
end;

procedure TFNLContentPacker.btnPackAddClick(Sender: TObject);
var
  PackFolder: String;

  NewPack: TRecipePack;
begin
  if (cbLevelPack.ItemIndex < 0) or (cbLevelPack.Items.Objects[cbLevelPack.ItemIndex] = nil) then
    PackFolder := cbLevelPack.Text
  else
    PackFolder := TNeoLevelGroup(cbLevelPack.Items.Objects[cbLevelPack.ItemIndex]).Folder;

  if not DirectoryExists(AppPath + 'levels/' + PackFolder) then
  begin
    ShowMessage('Error - Path not found: ' + AppPath + 'levels/' + PackFolder);
    Exit;
  end;

  NewPack := TRecipePack.Create;
  NewPack.PackFolder := PackFolder;
  NewPack.NewStylesInclude := TStyleInclude(rgPackGraphicSets.ItemIndex);
  NewPack.NewMusicInclude := rgPackMusic.ItemIndex = 0;
  NewPack.ResourcesOnly := false;

  fRecipe.Packs.Add(NewPack);
  fRecipe.BuildAutoAdds;

  RebuildContentList;
end;

procedure TFNLContentPacker.FormCreate(Sender: TObject);
begin
  //fPackInternalNames := TStringList.Create;
  //fStyleInternalNames := TStringList.Create;

  fRecipe := TPackageRecipe.Create;

  LoadDefaultContentList;
  PreparePacksList;
  PrepareStylesList;
end;

procedure TFNLContentPacker.FormDestroy(Sender: TObject);
begin
  fRecipe.Free;

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
