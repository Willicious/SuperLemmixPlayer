unit FNeoLemmixLevelSelect;

interface

uses
  GameControl,
  LemNeoLevelPack,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TFLevelSelect = class(TForm)
    tvLevelSelect: TTreeView;
    btnCancel: TButton;
    btnOK: TButton;
    lblName: TLabel;
    pnLevelInfo: TPanel;
    lblPosition: TLabel;
    lblAuthor: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvLevelSelectClick(Sender: TObject);
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
  begin
    tvLevelSelect.Items.AddChildObject(ParentNode, '(' + IntToStr(aLevel.GroupIndex + 1) + ') ' + aLevel.Title, aLevel);
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
  end;
begin
  tvLevelSelect.Items.BeginUpdate;
  try
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

begin
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

end.
