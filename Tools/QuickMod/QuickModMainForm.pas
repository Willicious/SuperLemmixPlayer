unit QuickModMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, StrUtils;

const
  SKILL_COUNT = 19;
  SKILLS: array[0..SKILL_COUNT-1] of String =
   ('Walker', 'Jumper', 'Shimmier',
    'Climber', 'Swimmer', 'Floater', 'Glider', 'Disarmer',
    'Bomber', 'Stoner', 'Blocker',
    'Platformer', 'Builder', 'Stacker',
    'Basher', 'Fencer', 'Miner', 'Digger',
    'Cloner');

type
  TSkillInputComponents = record
    SILabel: TLabel;
    SIEdit: TEdit;
  end;

  TSkillInputs = array[0..SKILL_COUNT-1] of TSkillInputComponents;

  TFQuickmodMain = class(TForm)
    lblPack: TLabel;
    cbPack: TComboBox;
    gbStats: TGroupBox;
    cbLemCount: TCheckBox;
    ebLemCount: TEdit;
    cbSaveRequirement: TCheckBox;
    ebSaveRequirement: TEdit;
    cbReleaseRate: TCheckBox;
    ebReleaseRate: TEdit;
    cbLockRR: TCheckBox;
    cbUnlockRR: TCheckBox;
    cbTimeLimit: TCheckBox;
    ebTimeLimit: TEdit;

    gbSkillset: TGroupBox;
    btnApply: TButton;
    cbCustomSkillset: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure cbStatCheckboxClicked(Sender: TObject);
    procedure cbCustomSkillsetClick(Sender: TObject);
    procedure cbLockRRClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    AppPath: String;

    fSkillInputs: TSkillInputs;
    fPackList: TStringList;

    procedure BuildPackList;
    procedure LoadPackInfo(aPackFolder: String);
    procedure CreateSkillInputs;

    procedure ApplyChanges;
    procedure ApplyChangesToLevelFile(aFile: String);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FQuickmodMain: TFQuickmodMain;

implementation

{$R *.dfm}

{ TFQuickmodMain }

procedure TFQuickmodMain.cbCustomSkillsetClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to SKILL_COUNT-1 do
    fSkillInputs[i].SIEdit.Enabled := cbCustomSkillset.Checked;
end;

procedure TFQuickmodMain.cbLockRRClick(Sender: TObject);
begin
  if cbLockRR.Checked and cbUnlockRR.Checked then
  begin
    if Sender <> cbLockRR then cbLockRR.Checked := false;
    if Sender <> cbUnlockRR then cbUnlockRR.Checked := false;
  end;
end;

procedure TFQuickmodMain.cbStatCheckboxClicked(Sender: TObject);
begin
  ebLemCount.Enabled := cbLemCount.Checked;
  ebSaveRequirement.Enabled := cbSaveRequirement.Checked;
  ebReleaseRate.Enabled := cbReleaseRate.Checked;
  ebTimeLimit.Enabled := cbTimeLimit.Checked;
end;

constructor TFQuickmodMain.Create(aOwner: TComponent);
begin
  inherited;
  fPackList := TStringList.Create;
  AppPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

destructor TFQuickmodMain.Destroy;
begin
  fPackList.Free;
  inherited;
end;

procedure TFQuickmodMain.btnApplyClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to apply these changes?', mtCustom, [mbYes, mbNo], 0, mbNo) = mrYes then
    ApplyChanges;
end;

procedure TFQuickmodMain.BuildPackList;
var
  SearchRec: TSearchRec;
  i: Integer;
begin
  if FindFirst(AppPath + 'levels\*', faDirectory, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then Continue;
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
        LoadPackInfo(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  fPackList.SaveToFile(AppPath + 'test.txt');

  cbPack.Items.Clear;
  for i := 0 to fPackList.Count-1 do
    cbPack.Items.Add(fPackList.ValueFromIndex[i]);
  cbPack.ItemIndex := 0;
end;

procedure TFQuickmodMain.LoadPackInfo(aPackFolder: String);
var
  FullPath: String;
  PackName: String;
  ThisLine: String;
  SL: TStringList;
begin
  FullPath := IncludeTrailingPathDelimiter(AppPath + 'levels\' + aPackFolder);
  PackName := '';
  if FileExists(FullPath + 'info.nxmi') then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(FullPath + 'info.nxmi');
      while SL.Count > 0 do
      begin
        ThisLine := TrimLeft(SL[0]);
        if Uppercase(LeftStr(ThisLine, 5)) = 'TITLE' then
          PackName := RightStr(ThisLine, Length(ThisLine)-6);
        SL.Delete(0);
      end;
    finally
      SL.Free;
    end;
  end;

  if PackName = '' then PackName := aPackFolder;
  fPackList.Values[FullPath] := PackName;
end;

procedure TFQuickmodMain.CreateSkillInputs;
var
  i: Integer;
  AddHeight: Integer;
  ThisInput: TSkillInputComponents;
const
  ORIGIN_X = 8;
  ORIGIN_Y = 49;
  SPACING_X = 119;
  SPACING_Y = 27;
  LABEL_WIDTH = 56;
  EDIT_WIDTH = 36;
begin
  gbSkillset.Anchors := [akLeft, akTop, akRight, akBottom];

  for i := 0 to SKILL_COUNT-1 do
  begin
    ThisInput.SILabel := TLabel.Create(self);
    ThisInput.SIEdit := TEdit.Create(self);

    with ThisInput.SILabel do
    begin
      Parent := gbSkillset;
      Caption := SKILLS[i];
      Height := 13;
      Left := ORIGIN_X + (SPACING_X * (i mod 2));
      Top := ORIGIN_Y + (SPACING_Y * (i div 2)) + 2;
      Width := LABEL_WIDTH;
    end;

    with ThisInput.SIEdit do
    begin
      Parent := gbSkillset;
      Enabled := false;
      Height := 21;
      Left := ORIGIN_X + (SPACING_X * (i mod 2)) + LABEL_WIDTH + 8;
      NumbersOnly := true;
      Text := '0';
      Top := ORIGIN_Y + (SPACING_Y * (i div 2));
      Width := EDIT_WIDTH;

      AddHeight := (Top + Height) - ORIGIN_Y;
    end;

    fSkillInputs[i] := ThisInput;
  end;

  ClientHeight := ClientHeight + AddHeight;
end;

procedure TFQuickmodMain.FormCreate(Sender: TObject);
begin
  BuildPackList;
  CreateSkillInputs;
end;

procedure TFQuickmodMain.ApplyChanges;
begin

end;

procedure TFQuickmodMain.ApplyChangesToLevelFile(aFile: String);
begin

end;

end.
