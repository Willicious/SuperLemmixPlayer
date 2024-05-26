unit FReplayManager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TReplayManagerAction = (rnaNone, rnaDelete, rnaCopy, rnaMove);
  TReplayManagerSetting = record
    Action: TReplayManagerAction;
    AppendResult: Boolean;
    UpdateVersion: Boolean;
    Template: String;
  end;
  TReplayManagerSettings = array[0..6] of TReplayManagerSetting;

  TFReplayManager = class(TForm)
    rgReplayKind: TRadioGroup;
    gbAction: TGroupBox;
    rbDoNothing: TRadioButton;
    rbDeleteFile: TRadioButton;
    rbCopyTo: TRadioButton;
    rbMoveTo: TRadioButton;
    cbNamingScheme: TComboBox;
    cbUpdateVersion: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    cbAppendResult: TCheckBox;
    procedure rgReplayKindClick(Sender: TObject);
    procedure rbReplayActionClick(Sender: TObject);
    procedure cbNamingSchemeChange(Sender: TObject);
    procedure cbUpdateVersionClick(Sender: TObject);
    procedure cbAppendResultClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbNamingSchemeEnter(Sender: TObject);
  private
    fIsSetting: Boolean;

    procedure SetFromOptions;
    procedure SetToOptions(aSetAction, aSetUpdateVersion, aSetAppendResult: Boolean);

    procedure SetNamingDropdown(aValue: String);
    function GetNamingDropdown: String;
  public
    class procedure ClearManagerSettings;
  end;

var
  ReplayManager: TReplayManagerSettings;

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

{ TFReplayManager }

procedure TFReplayManager.btnOKClick(Sender: TObject);
begin
  if (ReplayManager[CR_PASS].Action = rnaDelete) or
     (ReplayManager[CR_PASS_TALISMAN].Action = rnaDelete) then
  begin
    if RunCustomPopup(self, 'Delete successful replays?',
                      'You have selected to delete pass and/or pass-with-talisman replays. Are you sure?',
                      'Yes|No') = 1 then
      ModalResult := mrOk;
  end else
    ModalResult := mrOk;
end;

procedure TFReplayManager.cbNamingSchemeChange(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  SetToOptions(true, false, false);
end;

procedure TFReplayManager.cbNamingSchemeEnter(Sender: TObject);
begin
  if cbNamingScheme.ItemIndex >= 0 then
    cbNamingScheme.Text := PRESET_REPLAY_PATTERNS[cbNamingScheme.ItemIndex];
end;

procedure TFReplayManager.cbUpdateVersionClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  SetToOptions(false, true, false);
end;

procedure TFReplayManager.cbAppendResultClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  SetToOptions(false, false, true);
end;

class procedure TFReplayManager.ClearManagerSettings;
var
  i: Integer;
  NewPattern: String;
begin
  NewPattern := StringReplace(GameParams.IngameSaveReplayPattern, '*', '', [rfReplaceAll]);
  for i := 0 to Length(ReplayManager)-1 do
  begin
    ReplayManager[i].Action := rnaNone;
    //ReplayManager[i].UpdateVersion := false;
    ReplayManager[i].Template := NewPattern;
  end;
end;

procedure TFReplayManager.FormShow(Sender: TObject);
begin
  SetFromOptions;
end;

procedure TFReplayManager.SetNamingDropdown(aValue: String);
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

function TFReplayManager.GetNamingDropdown: String;
begin
  if cbNamingScheme.ItemIndex < 0 then
    Result := cbNamingScheme.Text
  else
    Result := PRESET_REPLAY_PATTERNS[cbNamingScheme.ItemIndex];
end;

procedure TFReplayManager.rbReplayActionClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

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

  SetToOptions(true, false, false);
end;

procedure TFReplayManager.rgReplayKindClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  SetFromOptions;
end;

procedure TFReplayManager.SetFromOptions;
var
  ToSet: TIntArray;
  i: Integer;
begin
  fIsSetting := true;

  try
    gbAction.Caption := 'Action for ' + Lowercase(rgReplayKind.Items[rgReplayKind.ItemIndex]);
    ToSet := GetSettingIndexes(rgReplayKind.ItemIndex);

    case ReplayManager[ToSet[0]].Action of
      rnaNone: rbDoNothing.Checked := true;
      rnaDelete: rbDeleteFile.Checked := true;
      rnaCopy: rbCopyTo.Checked := true;
      rnaMove: rbMoveTo.Checked := true;
    end;
    SetNamingDropdown(ReplayManager[ToSet[0]].Template);
    cbUpdateVersion.Checked := ReplayManager[ToSet[0]].UpdateVersion;
    cbAppendResult.Checked := ReplayManager[ToSet[0]].AppendResult;

    for i := 1 to Length(ToSet)-1 do
    begin
      if ReplayManager[ToSet[i]].Action <> ReplayManager[ToSet[0]].Action then
      begin
        rbDoNothing.Checked := false;
        rbDeleteFile.Checked := false;
        rbCopyTo.Checked := false;
        rbMoveTo.Checked := false;
      end;
      if ReplayManager[ToSet[i]].Template <> ReplayManager[ToSet[0]].Template then
        cbNamingScheme.Text := '';
      if ReplayManager[ToSet[i]].UpdateVersion <> ReplayManager[ToSet[0]].UpdateVersion then
        cbUpdateVersion.Checked := false;
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

procedure TFReplayManager.SetToOptions(aSetAction, aSetUpdateVersion, aSetAppendResult: Boolean);
var
  ToSet: TIntArray;
  i: Integer;
begin
  ToSet := GetSettingIndexes(rgReplayKind.ItemIndex);
  for i := 0 to Length(ToSet)-1 do
  begin
    if aSetUpdateVersion then
      ReplayManager[ToSet[i]].UpdateVersion := cbUpdateVersion.Checked;

    if aSetAppendResult then
      ReplayManager[ToSet[i]].AppendResult := cbAppendResult.Checked;

    if aSetAction then
    begin
      if rbDoNothing.Checked then
        ReplayManager[ToSet[i]].Action := rnaNone
      else if rbDeleteFile.Checked then
        ReplayManager[ToSet[i]].Action := rnaDelete
      else if rbCopyTo.Checked then
        ReplayManager[ToSet[i]].Action := rnaCopy
      else if rbMoveTo.Checked then
        ReplayManager[ToSet[i]].Action := rnaMove
      else
        Continue;

      if rbCopyTo.Checked or rbMoveTo.Checked then
        ReplayManager[ToSet[i]].Template := GetNamingDropdown
      else
        ReplayManager[ToSet[i]].Template := '';
    end;
  end;
end;

end.
