unit FNeoLemmixConfig;

interface

uses
  GameControl, FEditHotkeys, LemDosStyle,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TFormNXConfig = class(TForm)
    NXConfigPages: TPageControl;
    TabSheet1: TTabSheet;
    GroupBox1: TGroupBox;
    cbMusic: TCheckBox;
    cbSound: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    GroupBox2: TGroupBox;
    cbOneClickHighlight: TCheckBox;
    cbFixedKeys: TCheckBox;
    btnHotkeys: TButton;
    GroupBox3: TGroupBox;
    cbLemmingBlink: TCheckBox;
    cbTimerBlink: TCheckBox;
    Label1: TLabel;
    cbZoom: TComboBox;
    GroupBox4: TGroupBox;
    cbAutoSaveReplay: TCheckBox;
    Label2: TLabel;
    cbReplayNaming: TComboBox;
    TabSheet2: TTabSheet;
    GroupBox5: TGroupBox;
    cbLookForLVL: TCheckBox;
    cbSteelDebug: TCheckBox;
    cbChallengeMode: TCheckBox;
    cbTimerMode: TCheckBox;
    GroupBox6: TGroupBox;
    Label3: TLabel;
    cbGimmickList: TComboBox;
    cbEnableGimmick: TCheckBox;
    btnCheckGimmicks: TButton;
    btnClearGimmick: TButton;
    GroupBox7: TGroupBox;
    Label4: TLabel;
    cbSkillList: TComboBox;
    cbForceSkill: TCheckBox;
    btnCheckSkills: TButton;
    btnClearSkill: TButton;
    cbExplicitCancel: TCheckBox;
    cbWhiteOut: TCheckBox;
    cbIgnoreReplaySelection: TCheckBox;
    TabSheet3: TTabSheet;
    cbEnableOnline: TCheckBox;
    cbUpdateCheck: TCheckBox;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnHotkeysClick(Sender: TObject);
    procedure cbEnableGimmickClick(Sender: TObject);
    procedure cbGimmickListChange(Sender: TObject);
    procedure btnClearGimmickClick(Sender: TObject);
    procedure btnCheckGimmicksClick(Sender: TObject);
    procedure cbSkillListChange(Sender: TObject);
    procedure cbForceSkillClick(Sender: TObject);
    procedure btnClearSkillClick(Sender: TObject);
    procedure btnCheckSkillsClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure cbEnableOnlineClick(Sender: TObject);
  private
    fGameParams: TDosGameParams;
    fForceGimmick1: LongWord;
    fForceGimmick2: LongWord;
    fForceGimmick3: LongWord;
    fForceSkillset: Word;
    procedure SetFromParams;
    procedure SaveToParams;
  public
    procedure SetGameParams(aGameParams: TDosGameParams);
  end;

var
  FormNXConfig: TFormNXConfig;

implementation

{$R *.dfm}

procedure TFormNXConfig.SetGameParams(aGameParams: TDosGameParams);
begin
  fGameParams := aGameParams;
  SetFromParams;
end;

procedure TFormNXConfig.btnApplyClick(Sender: TObject);
begin
  SaveToParams;
end;

procedure TFormNXConfig.btnOKClick(Sender: TObject);
begin
  SaveToParams;
  ModalResult := mrOK;
end;

procedure TFormNXConfig.SetFromParams;
var
  i: Integer;
begin
  //// Variables ////
  fForceGimmick1 := fGameParams.ForceGimmick;
  fForceGimmick2 := fGameParams.ForceGimmick2;
  fForceGimmick3 := fGameParams.ForceGimmick3;
  fForceSkillset := fGameParams.ForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  cbMusic.Checked := fGameParams.MusicEnabled;
  cbSound.Checked := fGameParams.SoundEnabled;
  cbOneClickHighlight.Checked := fGameParams.ClickHighlight;
  cbFixedKeys.Checked := fGameParams.FixedKeys;
  cbIgnoreReplaySelection.Checked := fGameParams.IgnoreReplaySelection;
  cbLemmingBlink.Checked := fGameParams.LemmingBlink;
  cbTimerBlink.Checked := fGameParams.TimerBlink;
  cbWhiteOut.Checked := fGameParams.WhiteOutZero;
  cbAutoSaveReplay.Checked := fGameParams.AutoSaveReplay;
  cbExplicitCancel.Checked := fGameParams.ExplicitCancel;

  // Zoom Dropdown
  cbZoom.Items.Clear;
  cbZoom.Items.Add('Fullscreen');
  i := 1;
  while (i * 320 <= Screen.Width) and (i * 200 < Screen.Height) do
  begin
    cbZoom.Items.Add('Windowed, ' + IntToStr(i) + 'x Zoom');
    Inc(i);
  end;
  cbZoom.ItemIndex := fGameParams.ZoomLevel;

  // Replay Naming Dropdown
  if fGameParams.AutoReplayNames = false then
    i := 3 // Manual naming
  else if fGameParams.AlwaysTimestamp then
    i := 2
  else if fGameParams.ConfirmOverwrite then
    i := 1
  else
    i := 0;
  cbReplayNaming.ItemIndex := i;

  //// Page 2 (Online Options) ////
  cbUpdateCheck.Checked := fGameParams.CheckUpdates; // in reverse order as the next one may override this
  cbEnableOnline.Checked := fGameParams.EnableOnline;

  //// Page 3 (Game Options) ////
  // Checkboxes
  cbLookForLVL.Enabled := (fGameParams.SysDat.Options and 1) <> 0;
  cbLookForLVL.Checked := fGameParams.LookForLVLFiles and cbLookForLVL.Enabled;
  cbSteelDebug.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbSteelDebug.Checked := fGameParams.DebugSteel and cbSteelDebug.Enabled;
  cbChallengeMode.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbChallengeMode.Checked := fGameParams.ChallengeMode and cbChallengeMode.Enabled;
  cbTimerMode.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbTimerMode.Checked := fGameParams.TimerMode and cbTimerMode.Enabled;
  cbEnableGimmick.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbEnableGimmick.Checked := ((fForceGimmick1 and 1) <> 0) and cbEnableGimmick.Enabled; // set based on first gimmick in list
  cbForceSkill.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbForceSkill.Checked := ((fForceSkillset and $8000) <> 0) and cbForceSkill.Enabled; // set based on first skill in list (highest bit)

  // Gimmick dropdown / etc
  cbGimmickList.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  btnCheckGimmicks.Enabled := ((fGameParams.SysDat.Options and 32) <> 0) and
                              ((fForceGimmick1 <> 0) or (fForceGimmick2 <> 0) or (fForceGimmick3 <> 0));
  btnClearGimmick.Enabled := btnCheckGimmicks.Enabled;

  // Skillset dropdown / etc
  cbSkillList.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  btnCheckSkills.Enabled := ((fGameParams.SysDat.Options and 32) <> 0) and
                            (fForceSkillset <> 0);
  btnClearSkill.Enabled := btnCheckSkills.Enabled;

  if (fGameParams.SysDat.Options and 33) = 0 then
    TabSheet2.TabVisible := false;

  btnApply.Enabled := false;
end;

procedure TFormNXConfig.SaveToParams;
begin
  //// Variables ////
  fGameParams.ForceGimmick := fForceGimmick1;
  fGameParams.ForceGimmick2 := fForceGimmick2;
  fGameParams.ForceGimmick3 := fForceGimmick3;
  fGameParams.ForceSkillset := fForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  fGameParams.MusicEnabled := cbMusic.Checked;
  fGameParams.SoundEnabled := cbSound.Checked;
  fGameParams.ClickHighlight := cbOneClickHighlight.Checked;
  fGameParams.FixedKeys := cbFixedKeys.Checked;
  fGameParams.IgnoreReplaySelection := cbIgnoreReplaySelection.Checked;
  fGameParams.LemmingBlink := cbLemmingBlink.Checked;
  fGameParams.TimerBlink := cbTimerBlink.Checked;
  fGameParams.WhiteOutZero := cbWhiteOut.Checked;
  fGameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  fGameParams.ExplicitCancel := cbExplicitCancel.Checked;

  // Zoom Dropdown
  if fGameParams.ZoomLevel <> cbZoom.ItemIndex then
    ShowMessage('New zoom setting will be applied upon leaving the main menu.');
  fGameParams.ZoomLevel := cbZoom.ItemIndex;

  // Replay Naming Dropdown
  case cbReplayNaming.ItemIndex of
    0: begin
         fGameParams.AutoReplayNames := true;
         fGameParams.AlwaysTimestamp := false;
         fGameParams.ConfirmOverwrite := false;
       end;
    1: begin
         fGameParams.AutoReplayNames := true;
         fGameParams.AlwaysTimestamp := false;
         fGameParams.ConfirmOverwrite := true;
       end;
    2: begin
         fGameParams.AutoReplayNames := true;
         fGameParams.AlwaysTimestamp := true;
         fGameParams.ConfirmOverwrite := false;
       end;
    3: begin
         fGameParams.AutoReplayNames := false;
         fGameParams.AlwaysTimestamp := false;
         fGameParams.ConfirmOverwrite := false;
       end;
  end;

  //// Page 2 (Online Options) ////
  // Checkboxes
  fGameParams.EnableOnline := cbEnableOnline.Checked;
  fGameParams.CheckUpdates := cbUpdateCheck.Checked;

  //// Page 3 (Game Options) ////
  // Checkboxes
  fGameParams.LookForLVLFiles := cbLookForLVL.Checked;
  TBaseDosLevelSystem(fGameParams.Style.LevelSystem).LookForLVL := fGameParams.LookForLVLFiles;
  fGameParams.DebugSteel := cbSteelDebug.Checked;
  fGameParams.ChallengeMode := cbChallengeMode.Checked;
  fGameParams.TimerMode := cbTimerMode.Checked;

  btnApply.Enabled := false;
end;

procedure TFormNXConfig.btnHotkeysClick(Sender: TObject);
var
  HotkeyForm: TFLemmixHotkeys;
begin
  HotkeyForm := TFLemmixHotkeys.Create(self);
  HotkeyForm.HotkeyManager := fGameParams.Hotkeys;
  HotkeyForm.ShowModal;
  HotkeyForm.Free;
end;

procedure TFormNXConfig.cbEnableGimmickClick(Sender: TObject);
var
  pGimmickFlags: PLongWord;
  ChangeFlag: LongWord;
begin
  // Using pointery stuff to simplify handling the split into three
  // different variables.
  case cbGimmickList.ItemIndex of
    0..31: pGimmickFlags := @fForceGimmick1;
    32..63: pGimmickFlags := @fForceGimmick2;
    64..95: pGimmickFlags := @fForceGimmick3;
  end;
  ChangeFlag := 1 shl (cbGimmickList.ItemIndex mod 32);

  if cbEnableGimmick.Checked then
    pGimmickFlags^ := pGimmickFlags^ or ChangeFlag
  else
    pGimmickFlags^ := pGimmickFlags^ and not ChangeFlag;

  btnCheckGimmicks.Enabled := ((fForceGimmick1 <> 0) or (fForceGimmick2 <> 0) or (fForceGimmick3 <> 0));
  btnClearGimmick.Enabled := btnCheckGimmicks.Enabled;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.cbGimmickListChange(Sender: TObject);
var
  pGimmickFlags: PLongWord;
  ChangeFlag: LongWord;
begin
  // Using pointery stuff to simplify handling the split into three
  // different variables.
  case cbGimmickList.ItemIndex of
    0..31: pGimmickFlags := @fForceGimmick1;
    32..63: pGimmickFlags := @fForceGimmick2;
    64..95: pGimmickFlags := @fForceGimmick3;
  end;
  ChangeFlag := 1 shl (cbGimmickList.ItemIndex mod 32);

  cbEnableGimmick.Checked := (pGimmickFlags^ and ChangeFlag) <> 0;
end;

procedure TFormNXConfig.btnClearGimmickClick(Sender: TObject);
begin
  fForceGimmick1 := 0;
  fForceGimmick2 := 0;
  fForceGimmick3 := 0;
  cbEnableGimmick.Checked := false;
  btnCheckGimmicks.Enabled := false;
  btnClearGimmick.Enabled := false;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.btnCheckGimmicksClick(Sender: TObject);
var
  pGimmickFlags: PLongWord;
  ChangeFlag: LongWord;
  i: Integer;
  S: String;
begin
  S := '';

  // Using pointery stuff to simplify handling the split into three
  // different variables.
  for i := 0 to cbGimmickList.Items.Count-1 do
  begin
    case i of
      0..31: pGimmickFlags := @fForceGimmick1;
      32..63: pGimmickFlags := @fForceGimmick2;
      64..95: pGimmickFlags := @fForceGimmick3;
    end;
    ChangeFlag := 1 shl (i mod 32);

    if (pGimmickFlags^ and ChangeFlag) <> 0 then
      S := S + '- ' + cbGimmickList.Items[i] + #13;
  end;

  S := 'Forced Gimmicks:' + #13 + #13 + S;
  ShowMessage(S);
end;

procedure TFormNXConfig.cbSkillListChange(Sender: TObject);
begin
  cbForceSkill.Checked := (fForceSkillset and (1 shl (15 - cbSkillList.ItemIndex))) <> 0;
end;

procedure TFormNXConfig.cbForceSkillClick(Sender: TObject);
begin
  if cbForceSkill.Checked then
    fForceSkillset := fForceSkillset or (1 shl (15 - cbSkillList.ItemIndex))
  else
    fForceSkillset := fForceSkillset and not (1 shl (15 - cbSkillList.ItemIndex));

  btnCheckSkills.Enabled := (fForceSkillset <> 0);
  btnClearSkill.Enabled := btnCheckSkills.Enabled;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.btnClearSkillClick(Sender: TObject);
begin
  fForceSkillset := 0;
  cbForceSkill.Checked := false;
  btnCheckSkills.Enabled := false;
  btnClearSkill.Enabled := false;
  OptionChanged(Sender);
end;

procedure TFormNXConfig.btnCheckSkillsClick(Sender: TObject);
var
  i: Integer;
  S: String;
begin
  S := '';

  // Using pointery stuff to simplify handling the split into three
  // different variables.
  for i := 15 downto 0 do
    if (fForceSkillset and (1 shl i)) <> 0 then
      S := S + '- ' + cbSkillList.Items[15-i] + #13;

  S := 'Forced Skillset:' + #13 + #13 + S;
  ShowMessage(S);
end;

procedure TFormNXConfig.OptionChanged(Sender: TObject);
begin
  btnApply.Enabled := true;
end;

procedure TFormNXConfig.cbEnableOnlineClick(Sender: TObject);
begin
  cbUpdateCheck.Enabled := cbEnableOnline.Checked;
  if not cbEnableOnline.Checked then cbUpdateCheck.Checked := false;
end;

end.
