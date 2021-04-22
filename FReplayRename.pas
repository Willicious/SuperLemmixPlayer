unit FReplayRename;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TReplayNamingAction = (rnaNone, rnaDelete, rnaCopy, rnaMove);
  TReplayNamingSetting = record
    Action: TReplayNamingAction;
    Refresh: Boolean;
    Template: String;
  end;
  TReplayNamingSettings = array[0..6] of TReplayNamingSetting;

  TFReplayNaming = class(TForm)
    rgReplayKind: TRadioGroup;
    gbAction: TGroupBox;
    rbDoNothing: TRadioButton;
    rbDeleteFile: TRadioButton;
    rbCopyTo: TRadioButton;
    rbMoveTo: TRadioButton;
    cbNamingScheme: TComboBox;
    cbRefresh: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    lblClassic: TLabel;
    procedure rgReplayKindClick(Sender: TObject);
    procedure rbReplayActionClick(Sender: TObject);
    procedure cbNamingSchemeChange(Sender: TObject);
    procedure cbRefreshClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbNamingSchemeEnter(Sender: TObject);
  private
    fIsSetting: Boolean;

    procedure SetFromOptions;
    procedure SetToOptions(aSetAction, aSetRefresh: Boolean);

    procedure SetNamingDropdown(aValue: String);
    function GetNamingDropdown: String;
  public
    class procedure ClearNamingSettings;
  end;

var
  ReplayNaming: TReplayNamingSettings;

implementation

{$R *.dfm}

uses
  CustomPopup,
  GameControl,
  GameReplayCheckScreen;

const
  PRESET_REPLAY_PATTERNS: array[0..5] of String =
  (
    '{GROUP}_{GROUPPOS}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '{TITLE}__{TIMESTAMP}',
    '{GROUP}_{GROUPPOS}__{TITLE}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{GROUP}_{GROUPPOS}__{TIMESTAMP}|{USERNAME}__{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{GROUP}_{GROUPPOS}__{TITLE}__{TIMESTAMP}|{USERNAME}__{TITLE}__{TIMESTAMP}'
  );

type
  TIntArray = array of Integer;

function GetSettingIndexes(aOptionIndex: Integer): TIntArray;
begin
  SetLength(Result, 0);
  case aOptionIndex of
    0: Result := [CR_UNKNOWN, CR_PASS, CR_FAIL, CR_UNDETERMINED, CR_NOLEVELMATCH, CR_ERROR, CR_PASS_TALISMAN];
    1: Result := [CR_PASS, CR_PASS_TALISMAN];
    2: Result := [CR_UNKNOWN, CR_FAIL, CR_UNDETERMINED, CR_NOLEVELMATCH, CR_ERROR];
    3: Result := [CR_PASS];
    4: Result := [CR_PASS_TALISMAN];
    5: Result := [CR_UNDETERMINED];
    6: Result := [CR_FAIL];
    7: Result := [CR_NOLEVELMATCH];
    8: Result := [CR_UNKNOWN, CR_ERROR];
    else raise Exception.Create('Invalid option passed to GetSettingIndexes');  
  end;
end;

{ TFReplayNaming }

procedure TFReplayNaming.btnOKClick(Sender: TObject);
begin
  if (ReplayNaming[CR_PASS].Action = rnaDelete) or
     (ReplayNaming[CR_PASS_TALISMAN].Action = rnaDelete) then
  begin
    if RunCustomPopup(self, 'Delete successful replays?',
                      'You have selected to delete pass and/or pass-with-talisman replays. Are you sure?',
                      'Yes|No') = 1 then
      ModalResult := mrOk;
  end else
    ModalResult := mrOk;
end;

procedure TFReplayNaming.cbNamingSchemeChange(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  lblClassic.Visible := false;
  SetToOptions(true, false);
end;

procedure TFReplayNaming.cbNamingSchemeEnter(Sender: TObject);
begin
  if cbNamingScheme.ItemIndex >= 0 then
    cbNamingScheme.Text := PRESET_REPLAY_PATTERNS[cbNamingScheme.ItemIndex];
end;

procedure TFReplayNaming.cbRefreshClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  lblClassic.Visible := false;
  SetToOptions(false, true);
end;

class procedure TFReplayNaming.ClearNamingSettings;
var
  i: Integer;
  NewPattern: String;
begin
  NewPattern := StringReplace(GameParams.IngameSaveReplayPattern, '*', '', [rfReplaceAll]);
  for i := 0 to Length(ReplayNaming)-1 do
  begin
    ReplayNaming[i].Action := rnaNone;
    ReplayNaming[i].Refresh := false;
    ReplayNaming[i].Template := NewPattern;
  end;
end;

procedure TFReplayNaming.FormShow(Sender: TObject);
begin
  SetFromOptions;
end;

procedure TFReplayNaming.SetNamingDropdown(aValue: String);
var
  i: Integer;
begin
  for i := 0 to Length(PRESET_REPLAY_PATTERNS)-1 do
    if aValue = PRESET_REPLAY_PATTERNS[i] then
    begin
      cbNamingScheme.ItemIndex := i;
      Exit;
    end;

  cbNamingScheme.Text := aValue;
end;

function TFReplayNaming.GetNamingDropdown: String;
begin
  if cbNamingScheme.ItemIndex < 0 then
    Result := cbNamingScheme.Text
  else
    Result := PRESET_REPLAY_PATTERNS[cbNamingScheme.ItemIndex];
end;

procedure TFReplayNaming.rbReplayActionClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  lblClassic.Visible := false;

  fIsSetting := true;
  try
    if not (rbCopyTo.Checked or rbMoveTo.Checked) then
    begin
      cbNamingScheme.Text := '';
      cbNamingScheme.Enabled := false;
    end else if not cbNamingScheme.Enabled then
    begin
      cbNamingScheme.ItemIndex := 0;
      cbNamingScheme.Enabled := true;
    end;
  finally
    fIsSetting := false;
  end;

  SetToOptions(true, false);
end;

procedure TFReplayNaming.rgReplayKindClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  lblClassic.Visible := false;
  SetFromOptions;
end;

procedure TFReplayNaming.SetFromOptions;
var
  ToSet: TIntArray;
  i: Integer;
begin
  fIsSetting := true;

  try
    gbAction.Caption := 'Action for ' + Lowercase(rgReplayKind.Items[rgReplayKind.ItemIndex]);
    ToSet := GetSettingIndexes(rgReplayKind.ItemIndex);

    case ReplayNaming[ToSet[0]].Action of
      rnaNone: rbDoNothing.Checked := true;
      rnaDelete: rbDeleteFile.Checked := true;
      rnaCopy: rbCopyTo.Checked := true;
      rnaMove: rbMoveTo.Checked := true;
    end;
    SetNamingDropdown(ReplayNaming[ToSet[0]].Template);
    cbRefresh.Checked := ReplayNaming[ToSet[0]].Refresh;

    for i := 1 to Length(ToSet)-1 do
    begin
      if ReplayNaming[ToSet[i]].Action <> ReplayNaming[ToSet[0]].Action then
      begin
        rbDoNothing.Checked := false;
        rbDeleteFile.Checked := false;
        rbCopyTo.Checked := false;
        rbMoveTo.Checked := false;
      end;
      if ReplayNaming[ToSet[i]].Template <> ReplayNaming[ToSet[0]].Template then
        cbNamingScheme.Text := '';
      if ReplayNaming[ToSet[i]].Refresh <> ReplayNaming[ToSet[0]].Refresh then
        cbRefresh.Checked := false;
    end;

    if not (rbCopyTo.Checked or rbMoveTo.Checked) then
    begin
      cbNamingScheme.Text := '';
      cbNamingScheme.Enabled := false;
    end else
      cbNamingScheme.Enabled := true;
  finally
    fIsSetting := false;
  end;
end;

procedure TFReplayNaming.SetToOptions(aSetAction, aSetRefresh: Boolean);
var
  ToSet: TIntArray;
  i: Integer;
begin
  ToSet := GetSettingIndexes(rgReplayKind.ItemIndex);
  for i := 0 to Length(ToSet)-1 do
  begin
    if aSetRefresh then
      ReplayNaming[ToSet[i]].Refresh := cbRefresh.Checked;

    if aSetAction then
    begin
      if rbDoNothing.Checked then
        ReplayNaming[ToSet[i]].Action := rnaNone
      else if rbDeleteFile.Checked then
        ReplayNaming[ToSet[i]].Action := rnaDelete
      else if rbCopyTo.Checked then
        ReplayNaming[ToSet[i]].Action := rnaCopy
      else if rbMoveTo.Checked then
        ReplayNaming[ToSet[i]].Action := rnaMove
      else
        Continue;

      if rbCopyTo.Checked or rbMoveTo.Checked then
        ReplayNaming[ToSet[i]].Template := GetNamingDropdown
      else
        ReplayNaming[ToSet[i]].Template := '';
    end;
  end;
end;

end.
