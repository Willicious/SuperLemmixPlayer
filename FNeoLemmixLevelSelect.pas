unit FNeoLemmixLevelSelect;

interface

uses
  GameControl,
  LemNeoLevelPack,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TFLevelSelect = class(TForm)
    tvLevelSelect: TTreeView;
    btnCancel: TButton;
    btnOK: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    procedure InitializeTreeview;
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
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
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

end.
