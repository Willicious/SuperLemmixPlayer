unit QuickModMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.UITypes, StrUtils;

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
    procedure RecursiveFindLevels(aBaseFolder: String);
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
  RecursiveFindLevels(fPackList.Names[cbPack.ItemIndex]);
end;

procedure TFQuickmodMain.RecursiveFindLevels(aBaseFolder: String);
var
  SearchRec: TSearchRec;
begin
  if FindFirst(aBaseFolder + '*', faDirectory, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then Continue;
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
        RecursiveFindLevels(IncludeTrailingPathDelimiter(aBaseFolder + SearchRec.Name));
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  if FindFirst(aBaseFolder + '*.nxlv', 0, SearchRec) = 0 then
  begin
    try
      repeat
        ApplyChangesToLevelFile(aBaseFolder + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

procedure TFQuickmodMain.ApplyChangesToLevelFile(aFile: String);
var
  SL: TStringList;
  ThisLine: String;
  SecLevel: Integer;
  n: Integer;
  i: Integer;
begin
  SecLevel := 0;
  n := 0;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(aFile);

    while n < SL.Count do
    begin
      ThisLine := Uppercase(TrimLeft(SL[n]));

      if LeftStr(ThisLine, 4) = '$END' then
      begin
        Dec(SecLevel);
        if SecLevel < 0 then Break;
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$SKILLSET') and (cbCustomSkillset.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if LeftStr(ThisLine, 1) = '$' then
        Inc(SecLevel)
      else if SecLevel = 0 then begin
        if (LeftStr(ThisLine, 8) = 'LEMMINGS') and cbLemCount.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 16) = 'SAVE_REQUIREMENT') and cbSaveRequirement.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 18) = 'MAX_SPAWN_INTERVAL') and cbReleaseRate.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 10) = 'TIME_LIMIT') and cbTimeLimit.Checked then
          SL[n] := '# ' + SL[n];

        if (Trim(ThisLine) = 'SPAWN_INTERVAL_LOCKED') and (cbLockRR.Checked or cbUnlockRR.Checked) then
          SL[n] := '# ' + SL[n];
      end;

      Inc(n);
    end;

    SL.Add('');
    SL.Add('# Modified by NL QuickMod');
    SL.Add('');

    if cbLemCount.Checked then SL.Add('LEMMINGS ' + IntToStr(StrToIntDef(ebLemCount.Text, 0)));
    if cbSaveRequirement.Checked then SL.Add('SAVE_REQUIREMENT ' + IntToStr(StrToIntDef(ebSaveRequirement.Text, 0)));
    if cbReleaseRate.Checked then SL.Add('MAX_SPAWN_INTERVAL ' + IntToStr(103 - StrToIntDef(ebReleaseRate.Text, 0)));
    if cbLockRR.Checked then SL.Add('SPAWN_INTERVAL_LOCKED');
    if cbTimeLimit.Checked and (StrToIntDef(ebTimeLimit.Text, 0) >= 1) then
      SL.Add('TIME_LIMIT' + IntToStr(StrToIntDef(ebTimeLimit.Text, 0)));

    if cbCustomSkillset.Checked then
    begin
      SL.Add('$SKILLSET');

      for i := 0 to SKILL_COUNT-1 do
        if StrToIntDef(fSkillInputs[i].SIEdit.Text, 0) > 0 then
          SL.Add('  ' + Uppercase(SKILLS[i]) + ' ' + IntToStr(StrToIntDef(fSkillInputs[i].SIEdit.Text, 0)));

      SL.Add('$END');
    end;

    SL.SaveToFile(aFile);
  finally
    SL.Free;
  end;
end;

end.
