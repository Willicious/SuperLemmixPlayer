unit FNeoLemmixConfig;

interface

uses
  GameControl, GameSound, FEditHotkeys, LemDosStyle,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TFormNXConfig = class(TForm)
    NXConfigPages: TPageControl;
    TabSheet1: TTabSheet;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    GroupBox2: TGroupBox;
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
    cbChallengeMode: TCheckBox;
    cbTimerMode: TCheckBox;
    GroupBox7: TGroupBox;
    Label4: TLabel;
    cbSkillList: TComboBox;
    cbForceSkill: TCheckBox;
    btnCheckSkills: TButton;
    btnClearSkill: TButton;
    cbExplicitCancel: TCheckBox;
    cbBlackOut: TCheckBox;
    TabSheet3: TTabSheet;
    cbEnableOnline: TCheckBox;
    cbUpdateCheck: TCheckBox;
    cbNoAutoReplay: TCheckBox;
    cbPauseAfterBackwards: TCheckBox;
    cbNoBackgrounds: TCheckBox;
    TabSheet4: TTabSheet;
    tbSoundVol: TTrackBar;
    Label3: TLabel;
    Label5: TLabel;
    tbMusicVol: TTrackBar;
    Label6: TLabel;
    Label7: TLabel;
    cbSuccessJingle: TCheckBox;
    cbFailureJingle: TCheckBox;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnHotkeysClick(Sender: TObject);
    procedure cbSkillListChange(Sender: TObject);
    procedure cbForceSkillClick(Sender: TObject);
    procedure btnClearSkillClick(Sender: TObject);
    procedure btnCheckSkillsClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure cbEnableOnlineClick(Sender: TObject);
    procedure SliderChange(Sender: TObject);
  private
    fGameParams: TDosGameParams;
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
  fForceSkillset := fGameParams.ForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  cbLemmingBlink.Checked := fGameParams.LemmingBlink;
  cbTimerBlink.Checked := fGameParams.TimerBlink;
  cbBlackOut.Checked := fGameParams.BlackOutZero;
  cbNoBackgrounds.Checked := fGameParams.NoBackgrounds;
  cbAutoSaveReplay.Checked := fGameParams.AutoSaveReplay;
  cbExplicitCancel.Checked := fGameParams.ExplicitCancel;
  cbNoAutoReplay.Checked := fGameParams.NoAutoReplayMode;
  cbPauseAfterBackwards.Checked := fGameParams.PauseAfterBackwardsSkip;

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

  //// Page 2 (Audio Options) ////
  tbSoundVol.Position := SoundVolume;
  tbMusicVol.Position := MusicVolume;
  cbSuccessJingle.Checked := fGameParams.PostLevelVictorySound;
  cbFailureJingle.Checked := fGameParams.PostLevelFailureSound;

  //// Page 3 (Online Options) ////
  cbUpdateCheck.Checked := fGameParams.CheckUpdates; // in reverse order as the next one may override this
  cbEnableOnline.Checked := fGameParams.EnableOnline;

  //// Page 4 (Game-Specific Options) ////
  // Checkboxes
  cbLookForLVL.Enabled := (fGameParams.SysDat.Options and 1) <> 0;
  cbLookForLVL.Checked := fGameParams.LookForLVLFiles and cbLookForLVL.Enabled;
  cbChallengeMode.Enabled := ((fGameParams.SysDat.Options and 32) <> 0) and (fGameParams.ForceSkillset = 0);
  cbChallengeMode.Checked := (fGameParams.ChallengeMode or (fGameParams.ForceSkillset <> 0));
  cbTimerMode.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbTimerMode.Checked := fGameParams.TimerMode and cbTimerMode.Enabled;
  cbForceSkill.Enabled := (fGameParams.SysDat.Options and 32) <> 0;
  cbForceSkill.Checked := ((fForceSkillset and $8000) <> 0) and cbForceSkill.Enabled; // set based on first skill in list (highest bit)

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
  fGameParams.ForceSkillset := fForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  fGameParams.LemmingBlink := cbLemmingBlink.Checked;
  fGameParams.TimerBlink := cbTimerBlink.Checked;
  fGameParams.BlackOutZero := cbBlackOut.Checked;
  fGameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  fGameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  fGameParams.ExplicitCancel := cbExplicitCancel.Checked;
  fGameParams.NoAutoReplayMode := cbNoAutoReplay.Checked;
  fGameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;

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

  //// Page 2 (Audio Options) ////
  SoundVolume := tbSoundVol.Position;
  MusicVolume := tbMusicVol.Position;
  fGameParams.PostLevelVictorySound := cbSuccessJingle.Checked;
  fGameParams.PostLevelFailureSound := cbFailureJingle.Checked;

  //// Page 3 (Online Options) ////
  // Checkboxes
  fGameParams.EnableOnline := cbEnableOnline.Checked;
  fGameParams.CheckUpdates := cbUpdateCheck.Checked;

  //// Page 4 (Game Options) ////
  // Checkboxes
  fGameParams.LookForLVLFiles := cbLookForLVL.Checked;
  TBaseDosLevelSystem(fGameParams.Style.LevelSystem).LookForLVL := fGameParams.LookForLVLFiles;
  if fForceSkillset <> 0 then
    fGameParams.ChallengeMode := true
  else
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
  cbChallengeMode.Checked := (fForceSkillset <> 0);
  cbChallengeMode.Enabled := (fForceSkillset <> 0);
  btnClearSkill.Enabled := btnCheckSkills.Enabled;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.btnClearSkillClick(Sender: TObject);
begin
  fForceSkillset := 0;
  cbForceSkill.Checked := false;
  btnCheckSkills.Enabled := false;
  btnClearSkill.Enabled := false;
  cbChallengeMode.Enabled := true;
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
  btnApply.Enabled := true;
end;

procedure TFormNXConfig.SliderChange(Sender: TObject);
begin
  btnApply.Enabled := true;
end;

end.
