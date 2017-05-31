unit FNeoLemmixLevelSelect;

interface

uses
  GameControl,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  PngInterface,
  GR32,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList;

type
  TFLevelSelect = class(TForm)
    tvLevelSelect: TTreeView;
    btnCancel: TButton;
    btnOK: TButton;
    lblName: TLabel;
    pnLevelInfo: TPanel;
    lblPosition: TLabel;
    lblAuthor: TLabel;
    ilStatuses: TImageList;
    btnAddContent: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvLevelSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAddContentClick(Sender: TObject);
  private
    procedure InitializeTreeview;
    procedure SetInfo;
    procedure WriteToParams;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TFLevelSelect.InitializeTreeview;

  procedure AddLevel(aLevel: TNeoLevelEntry; ParentNode: TTreeNode);
  var
    N: TTreeNode;
  begin
    N := tvLevelSelect.Items.AddChildObject(ParentNode, '', aLevel);
    case aLevel.Status of
      lst_None: N.ImageIndex := 0;
      lst_Attempted: N.ImageIndex := 1;
      lst_Completed_Outdated: N.ImageIndex := 2;
      lst_Completed: N.ImageIndex := 3;
    end;
    N.SelectedIndex := N.ImageIndex;

    if GameParams.CurrentLevel = aLevel then
      tvLevelSelect.Selected := N;
  end;

  procedure AddGroup(aGroup: TNeoLevelGroup; ParentNode: TTreeNode);
  var
    GroupNode: TTreeNode;
    i: Integer;
  begin
    if aGroup = GameParams.BaseLevelPack then
      GroupNode := nil
    else
      GroupNode := tvLevelSelect.Items.AddChildObject(ParentNode, aGroup.Name, aGroup);
    for i := 0 to aGroup.Children.Count-1 do
      AddGroup(aGroup.Children[i], GroupNode);
    for i := 0 to aGroup.Levels.Count-1 do
      AddLevel(aGroup.Levels[i], GroupNode);

    if GroupNode <> nil then
    begin
      case aGroup.Status of
        lst_None: GroupNode.ImageIndex := 0;
        lst_Attempted: GroupNode.ImageIndex := 1;
        lst_Completed_Outdated: GroupNode.ImageIndex := 2;
        lst_Completed: GroupNode.ImageIndex := 3;
      end;
      GroupNode.SelectedIndex := GroupNode.ImageIndex;
    end;
  end;

  procedure MakeImages;
  var
    BMP32: TBitmap32;
    ImgBMP, MaskBMP: TBitmap;

    procedure Load(aName: String);
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, BMP32);
      TPngInterface.SplitBmp32(BMP32, ImgBMP, MaskBMP);
      tvLevelSelect.Images.Add(ImgBMP, MaskBMP);
    end;
  begin
    BMP32 := TBitmap32.Create;
    ImgBMP := TBitmap.Create;
    MaskBMP := TBitmap.Create;
    try
      Load('dash.png');
      Load('cross.png');
      Load('tick_red.png');
      Load('tick.png');
    finally
      BMP32.Free;
      ImgBMP.Free;
      MaskBMP.Free;
    end;
  end;
begin
  MakeImages;
  tvLevelSelect.Items.BeginUpdate;
  try
    tvLevelSelect.Items.Clear;
    AddGroup(GameParams.BaseLevelPack, nil);
  finally
    tvLevelSelect.Items.EndUpdate;
    tvLevelSelect.Update;
  end;
end;

procedure TFLevelSelect.FormCreate(Sender: TObject);
begin
  InitializeTreeview;
end;

procedure TFLevelSelect.btnOKClick(Sender: TObject);
begin
  WriteToParams;
end;

procedure TFLevelSelect.WriteToParams;
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // safeguard

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    G := TNeoLevelGroup(Obj);
    if G.Levels.Count = 0 then Exit;
    GameParams.SetGroup(G);
  end else if Obj is TNeoLevelEntry then
  begin
    L := TNeoLevelEntry(Obj);
    GameParams.SetLevel(L);
  end;

  ModalResult := mrOk;
end;

procedure TFLevelSelect.tvLevelSelectClick(Sender: TObject);
begin
  SetInfo;
end;

procedure TFLevelSelect.SetInfo;
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;

  function GetGroupPositionText: String;
  begin
    if (G.Parent = GameParams.BaseLevelPack) or (G.IsBasePack) then
      Result := ''
    else
      Result := 'Group ' + IntToStr(G.ParentGroupIndex + 1) + ' in ' + G.Parent.Name;
  end;

  function GetLevelPositionText: String;
  begin
    if L.Group = GameParams.BaseLevelPack then
      Result := 'Standalone level'
    else
      Result := 'Level ' + IntToStr(L.GroupIndex + 1) + ' of ' + L.Group.Name;
  end;

  procedure LoadNodeLabels;
  var
    i: Integer;
    L: TNeoLevelEntry;
  begin
    tvLevelSelect.Items.BeginUpdate;
    try
      for i := 0 to tvLevelSelect.Items.Count-1 do
      begin
        if not tvLevelSelect.Items[i].IsVisible then Continue;
        if tvLevelSelect.Items[i].Text <> '' then Continue;
        if TObject(tvLevelSelect.Items[i].Data) is TNeoLevelEntry then
        begin
          L := TNeoLevelEntry(tvLevelSelect.Items[i].Data);
          tvLevelSelect.Items[i].Text := '(' + IntToStr(L.GroupIndex + 1) + ') ' + L.Title;
        end;
      end;
    finally
      tvLevelSelect.Items.EndUpdate;
    end;
  end;

begin
  LoadNodeLabels;

  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    G := TNeoLevelGroup(Obj);
    lblName.Caption := G.Name;
    lblPosition.Caption := GetGroupPositionText;
    lblAuthor.Caption := G.Author;

    pnLevelInfo.Visible := false;

    btnOk.Enabled := G.LevelCount > 0; // note: Levels.Count is not recursive; LevelCount is
  end else if Obj is TNeoLevelEntry then
  begin
    L := TNeoLevelEntry(Obj);
    lblName.Caption := L.Title;
    lblPosition.Caption := GetLevelPositionText;
    lblAuthor.Caption := L.Author;

    pnLevelInfo.Visible := true;

    btnOk.Enabled := true;
  end;
end;

procedure TFLevelSelect.FormShow(Sender: TObject);
begin
  SetInfo;
end;

procedure TFLevelSelect.btnAddContentClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select pack or level file';
    OpenDlg.Filter := 'NeoLemmix Levels or Packs (*.nxlv, info.nxmi)|*.nxlv;info.nxmi';
    OpenDlg.InitialDir := AppPath;
    if not OpenDlg.Execute then Exit;

    if Lowercase(ExtractFileExt(OpenDlg.FileName)) = '.nxlv' then
      GameParams.BaseLevelPack.Levels.Add.Filename := OpenDlg.Filename
    else
      GameParams.BaseLevelPack.Children.Add(ExtractFilePath(OpenDlg.Filename));

    InitializeTreeview;
  finally
    OpenDlg.Free;
  end;
end;

end.
