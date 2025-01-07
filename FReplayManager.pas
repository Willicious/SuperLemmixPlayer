unit FReplayManager;

interface

uses
  LemStrings, LemTypes,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls,
  SharedGlobals;

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
    btnRunReplayCheck: TButton;
    btnCancel: TButton;
    cbAppendResult: TCheckBox;
    lblDoForPassed: TLabel;
    lblDoForTalisman: TLabel;
    lblDoForUndetermined: TLabel;
    lblDoForFailed: TLabel;
    lblDoForLevelNotFound: TLabel;
    lblDoForError: TLabel;
    gbActionsList: TGroupBox;
    stDoForPassed: TStaticText;
    stDoForTalisman: TStaticText;
    stDoForUndetermined: TStaticText;
    stDoForFailed: TStaticText;
    stDoForLevelNotFound: TStaticText;
    stDoForError: TStaticText;
    stPackName: TStaticText;
    lblSelectedFolder: TLabel;
    stSelectedFolder: TStaticText;
    btnBrowse: TButton;
    lblWelcome: TLabel;
    procedure rgReplayKindClick(Sender: TObject);
    procedure rbReplayActionClick(Sender: TObject);
    procedure cbNamingSchemeChange(Sender: TObject);
    procedure cbUpdateVersionClick(Sender: TObject);
    procedure cbAppendResultClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnRunReplayCheckClick(Sender: TObject);
    procedure cbNamingSchemeEnter(Sender: TObject);
    procedure UpdateLabels;
    procedure btnBrowseClick(Sender: TObject);
  private
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    fIsSetting: Boolean;

    procedure SetFromOptions;
    procedure SetToOptions(aSetAction, aSetUpdateVersion, aSetAppendResult: Boolean);

    procedure SetNamingDropdown(aValue: String);
    function GetNamingDropdown: String;
  public
    class procedure ClearManagerSettings;

    procedure UpdatePackNameText;
    property SelectedFolder: string read fSelectedFolder write fSelectedFolder;
    property CurrentlySelectedPack: string read fCurrentlySelectedPack write fCurrentlySelectedPack;

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

procedure TFReplayManager.btnBrowseClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  InitialDir: String;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';

    InitialDir := AppPath + SFReplays + MakeSafeForFilename(GameParams.CurrentGroupName);

    if not SysUtils.DirectoryExists(InitialDir) then
      InitialDir := AppPath + SFReplays;

    OpenDlg.InitialDir := InitialDir;
    OpenDlg.Filter := 'SuperLemmix Replay (*.nxrp)|*.nxrp';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing, ofPathMustExist];

    if OpenDlg.Execute then
    begin
      fSelectedFolder := ExtractFilePath(OpenDlg.FileName);

      if SysUtils.DirectoryExists(fSelectedFolder) then
      begin
        SetCurrentDir(fSelectedFolder);
        stSelectedFolder.Caption := ExtractFileName(ExcludeTrailingPathDelimiter(fSelectedFolder));
        GameParams.ReplayCheckPath := fSelectedFolder;  // Use fSelectedFolder directly
      end else
        ShowMessage('The selected folder path is invalid.');
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TFReplayManager.btnRunReplayCheckClick(Sender: TObject);
begin
  if fSelectedFolder = '' then
  begin
    ShowMessage('No replays selected. Please choose a folder of replays to begin Replay Check.');
    ModalResult := mrNone;
    Exit;
  end;

  if (ReplayManager[CR_PASS].Action = rnaDelete) or
     (ReplayManager[CR_PASS_TALISMAN].Action = rnaDelete) then
  begin
    if RunCustomPopup(Self, 'Delete successful replays?',
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

  SetToOptions(True, False, False);
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

  SetToOptions(False, True, False);
end;

procedure TFReplayManager.cbAppendResultClick(Sender: TObject);
begin
  if fIsSetting then
    Exit;

  SetToOptions(False, False, True);
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
    //ReplayManager[i].UpdateVersion := False;
    ReplayManager[i].Template := NewPattern;
  end;
end;

procedure TFReplayManager.FormShow(Sender: TObject);
begin
  SetFromOptions;
  UpdateLabels;
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

  fIsSetting := True;
  try
    if not (rbCopyTo.Checked or rbMoveTo.Checked) then
    begin
      cbNamingScheme.Text := '';
      cbNamingScheme.Enabled := False;
    end else if not cbNamingScheme.Enabled then
    begin
      cbNamingScheme.ItemIndex := 0;
      cbNamingScheme.Enabled := True;
    end;

    if rbDeleteFile.Checked then
    begin
      cbUpdateVersion.Enabled := False;
      cbUpdateVersion.Checked := False;
      cbAppendResult.Enabled := False;
      cbAppendResult.Checked := False;
    end else
    begin
      cbUpdateVersion.Enabled := True;
      cbAppendResult.Enabled := True;
    end;
  finally
    fIsSetting := False;
  end;

  SetToOptions(True, False, False);
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
  fIsSetting := True;

  try
    gbAction.Caption := 'Action for ' + Lowercase(rgReplayKind.Items[rgReplayKind.ItemIndex]);
    ToSet := GetSettingIndexes(rgReplayKind.ItemIndex);

    case ReplayManager[ToSet[0]].Action of
      rnaNone: rbDoNothing.Checked := True;
      rnaDelete: rbDeleteFile.Checked := True;
      rnaCopy: rbCopyTo.Checked := True;
      rnaMove: rbMoveTo.Checked := True;
    end;

    SetNamingDropdown(ReplayManager[ToSet[0]].Template);

    cbUpdateVersion.Enabled := not rbDeleteFile.Checked;
    cbAppendResult.Enabled  := not rbDeleteFile.Checked;
    cbUpdateVersion.Checked := ReplayManager[ToSet[0]].UpdateVersion and not rbDeleteFile.Checked;
    cbAppendResult.Checked  := ReplayManager[ToSet[0]].AppendResult  and not rbDeleteFile.Checked;

    for i := 1 to Length(ToSet)-1 do
    begin
      if ReplayManager[ToSet[i]].Action <> ReplayManager[ToSet[0]].Action then
      begin
        rbDoNothing.Checked := False;
        rbDeleteFile.Checked := False;
        rbCopyTo.Checked := False;
        rbMoveTo.Checked := False;
      end;

      if ReplayManager[ToSet[i]].Template <> ReplayManager[ToSet[0]].Template then
        cbNamingScheme.Text := '';
      if ReplayManager[ToSet[i]].UpdateVersion <> ReplayManager[ToSet[0]].UpdateVersion then
        cbUpdateVersion.Checked := False;
    end;

    if not (rbCopyTo.Checked or rbMoveTo.Checked) then
    begin
      cbNamingScheme.Text := '';
      cbNamingScheme.Enabled := False;
    end else
      cbNamingScheme.Enabled := True;
  finally
    fIsSetting := False;
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

    UpdateLabels;
  end;
end;

procedure TFReplayManager.UpdateLabels;
var
  OptionCaption: string;
  Index: Integer;

  procedure SetAllLabels;
  begin
    lblDoForPassed.Caption        := OptionCaption;
    lblDoForTalisman.Caption      := OptionCaption;
    lblDoForUndetermined.Caption  := OptionCaption ;
    lblDoForFailed.Caption        := OptionCaption;
    lblDoForLevelNotFound.Caption := OptionCaption ;
    lblDoForError.Caption         := OptionCaption;
  end;

  procedure SetAllPassedLabels;
  begin
    lblDoForPassed.Caption        := OptionCaption;
    lblDoForTalisman.Caption      := OptionCaption;
  end;

  procedure SetAllFailedLabels;
  begin
    lblDoForUndetermined.Caption  := OptionCaption ;
    lblDoForFailed.Caption        := OptionCaption;
    lblDoForLevelNotFound.Caption := OptionCaption ;
    lblDoForError.Caption         := OptionCaption;
  end;
begin
  OptionCaption := '';
  Index := rgReplayKind.ItemIndex;

  if rbDoNothing.Checked then
    OptionCaption := 'Keep Existing Name'
  else if rbDeleteFile.Checked then
    OptionCaption := 'Delete Replay'
  else if rbCopyTo.Checked then
    OptionCaption := 'Rename New Copy'
  else if rbMoveTo.Checked then
    OptionCaption := 'Rename Replay';

  if cbAppendResult.Checked and not rbDeleteFile.Checked then
    OptionCaption := OptionCaption + ', Append Result';

  if cbUpdateVersion.Checked and not rbDeleteFile.Checked then
    OptionCaption := OptionCaption + ', Update Version';


  case Index of
    0: SetAllLabels;
    1: SetAllPassedLabels;
    2: SetAllFailedLabels;
    3: lblDoForPassed.Caption        := OptionCaption;
    4: lblDoForTalisman.Caption      := OptionCaption;
    5: lblDoForUndetermined.Caption  := OptionCaption;
    6: lblDoForFailed.Caption        := OptionCaption;
    7: lblDoForLevelNotFound.Caption := OptionCaption;
    8: lblDoForError.Caption         := OptionCaption;
  end;
end;

procedure TFReplayManager.UpdatePackNameText;
var
  Pack: String;
begin
  Pack := CurrentlySelectedPack;

  if Pack <> '' then
    stPackName.Caption := Pack
  else
    stPackName.Caption := 'Replay Manager';
end;

end.
