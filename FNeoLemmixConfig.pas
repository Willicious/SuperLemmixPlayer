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
    cbNoAutoReplay: TCheckBox;
    TabSheet4: TTabSheet;
    tbSoundVol: TTrackBar;
    Label3: TLabel;
    Label5: TLabel;
    tbMusicVol: TTrackBar;
    Label6: TLabel;
    Label7: TLabel;
    cbSuccessJingle: TCheckBox;
    cbFailureJingle: TCheckBox;
    TabSheet5: TTabSheet;
    GroupBox2: TGroupBox;
    btnHotkeys: TButton;
    cbPauseAfterBackwards: TCheckBox;
    GroupBox3: TGroupBox;
    cbLemmingBlink: TCheckBox;
    cbTimerBlink: TCheckBox;
    cbBlackOut: TCheckBox;
    cbNoBackgrounds: TCheckBox;
    GroupBox1: TGroupBox;
    cbEnableOnline: TCheckBox;
    cbUpdateCheck: TCheckBox;
    cbDisableShadows: TCheckBox;
    GroupBox6: TGroupBox;
    cbZoom: TComboBox;
    Label1: TLabel;
    cbLinearResampleMenu: TCheckBox;
    cbLinearResampleGame: TCheckBox;
    cbFullScreen: TCheckBox;
    cbMinimapHighQuality: TCheckBox;
    cbIncreaseZoom: TCheckBox;
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
    fForceSkillset: Word;
    procedure SetFromParams;
    procedure SaveToParams;
  public
    procedure SetGameParams;
  end;

var
  FormNXConfig: TFormNXConfig;

implementation

{$R *.dfm}

procedure TFormNXConfig.SetGameParams;
begin
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
  fForceSkillset := GameParams.ForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  cbAutoSaveReplay.Checked := GameParams.AutoSaveReplay;
  cbExplicitCancel.Checked := GameParams.ExplicitCancel;
  cbNoAutoReplay.Checked := GameParams.NoAutoReplayMode;

  cbUpdateCheck.Checked := GameParams.CheckUpdates; // in reverse order as the next one may override this
  cbEnableOnline.Checked := GameParams.EnableOnline;

  // Replay Naming Dropdown
  if GameParams.AutoReplayNames = false then
    i := 3 // Manual naming
  else if GameParams.AlwaysTimestamp then
    i := 2
  else if GameParams.ConfirmOverwrite then
    i := 1
  else
    i := 0;
  cbReplayNaming.ItemIndex := i;

  //// Page 2 (Interface Options) ////
  // Checkboxes
  cbLemmingBlink.Checked := GameParams.LemmingBlink;
  cbTimerBlink.Checked := GameParams.TimerBlink;
  cbBlackOut.Checked := GameParams.BlackOutZero;
  cbNoBackgrounds.Checked := GameParams.NoBackgrounds;
  cbDisableShadows.Checked := GameParams.NoShadows;
  cbPauseAfterBackwards.Checked := GameParams.PauseAfterBackwardsSkip;
  cbFullScreen.Checked := GameParams.FullScreen;
  cbLinearResampleMenu.Checked := GameParams.LinearResampleMenu;
  cbLinearResampleGame.Checked := GameParams.LinearResampleGame;
  cbMinimapHighQuality.Checked := GameParams.MinimapHighQuality;

  // Zoom Dropdown
  cbZoom.Items.Clear;
  i := 1;
  while ((i - 2) * 320 <= Screen.Width) and ((i - 2) * 200 < Screen.Height) do
  begin
    cbZoom.Items.Add(IntToStr(i) + 'x Zoom');
    Inc(i);
  end;
  cbZoom.ItemIndex := GameParams.ZoomLevel-1;

  //// Page 3 (Audio Options) ////
  if SoundManager.MuteSound then
    tbSoundVol.Position := 0
  else
    tbSoundVol.Position := SoundManager.SoundVolume;
  if SoundManager.MuteMusic then
    tbMusicVol.Position := 0
  else
    tbMusicVol.Position := SoundManager.MusicVolume;
  cbSuccessJingle.Checked := GameParams.PostLevelVictorySound;
  cbFailureJingle.Checked := GameParams.PostLevelFailureSound;

  //// Page 4 (Game-Specific Options) ////
  // Checkboxes
  cbLookForLVL.Enabled := (GameParams.SysDat.Options and 1) <> 0;
  cbLookForLVL.Checked := GameParams.LookForLVLFiles and cbLookForLVL.Enabled;
  cbChallengeMode.Enabled := ((GameParams.SysDat.Options and 32) <> 0) and (GameParams.ForceSkillset = 0);
  cbChallengeMode.Checked := (GameParams.ChallengeMode or (GameParams.ForceSkillset <> 0));
  cbTimerMode.Enabled := (GameParams.SysDat.Options and 32) <> 0;
  cbTimerMode.Checked := GameParams.TimerMode and cbTimerMode.Enabled;
  cbForceSkill.Enabled := (GameParams.SysDat.Options and 32) <> 0;
  cbForceSkill.Checked := ((fForceSkillset and $8000) <> 0) and cbForceSkill.Enabled; // set based on first skill in list (highest bit)

  // Skillset dropdown / etc
  cbSkillList.Enabled := (GameParams.SysDat.Options and 32) <> 0;
  btnCheckSkills.Enabled := ((GameParams.SysDat.Options and 32) <> 0) and
                            (fForceSkillset <> 0);
  btnClearSkill.Enabled := btnCheckSkills.Enabled;

  if (GameParams.SysDat.Options and 33) = 0 then
    TabSheet2.TabVisible := false;

  btnApply.Enabled := false;
end;

procedure TFormNXConfig.SaveToParams;
begin
  //// Variables ////
  GameParams.ForceSkillset := fForceSkillset;

  //// Page 1 (Global Options) ////
  // Checkboxes
  GameParams.EnableOnline := cbEnableOnline.Checked;
  GameParams.CheckUpdates := cbUpdateCheck.Checked;
  GameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  GameParams.ExplicitCancel := cbExplicitCancel.Checked;
  GameParams.NoAutoReplayMode := cbNoAutoReplay.Checked;

  // Replay Naming Dropdown
  case cbReplayNaming.ItemIndex of
    0: begin
         GameParams.AutoReplayNames := true;
         GameParams.AlwaysTimestamp := false;
         GameParams.ConfirmOverwrite := false;
       end;
    1: begin
         GameParams.AutoReplayNames := true;
         GameParams.AlwaysTimestamp := false;
         GameParams.ConfirmOverwrite := true;
       end;
    2: begin
         GameParams.AutoReplayNames := true;
         GameParams.AlwaysTimestamp := true;
         GameParams.ConfirmOverwrite := false;
       end;
    3: begin
         GameParams.AutoReplayNames := false;
         GameParams.AlwaysTimestamp := false;
         GameParams.ConfirmOverwrite := false;
       end;
  end;

  //// Page 2 (Interface Options) ////
  // Checkboxes
  GameParams.LemmingBlink := cbLemmingBlink.Checked;
  GameParams.TimerBlink := cbTimerBlink.Checked;
  GameParams.BlackOutZero := cbBlackOut.Checked;
  GameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  GameParams.NoShadows := cbDisableShadows.Checked;
  GameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;
  GameParams.FullScreen := cbFullScreen.Checked;
  GameParams.LinearResampleMenu := cbLinearResampleMenu.Checked;
  GameParams.LinearResampleGame := cbLinearResampleGame.Checked;
  GameParams.MinimapHighQuality := cbMinimapHighQuality.Checked;

  // Zoom Dropdown
  GameParams.ZoomLevel := cbZoom.ItemIndex + 1;

  //// Page 3 (Audio Options) ////
  SoundManager.MuteSound := tbSoundVol.Position = 0;
  if tbSoundVol.Position <> 0 then
    SoundManager.SoundVolume := tbSoundVol.Position;
  SoundManager.MuteMusic := tbMusicVol.Position = 0;
  if tbMusicVol.Position <> 0 then
    SoundManager.MusicVolume := tbMusicVol.Position;
  GameParams.PostLevelVictorySound := cbSuccessJingle.Checked;
  GameParams.PostLevelFailureSound := cbFailureJingle.Checked;

  //// Page 4 (Game Options) ////
  // Checkboxes
  GameParams.LookForLVLFiles := cbLookForLVL.Checked;
  TBaseDosLevelSystem(GameParams.Style.LevelSystem).LookForLVL := GameParams.LookForLVLFiles;
  if fForceSkillset <> 0 then
    GameParams.ChallengeMode := true
  else
    GameParams.ChallengeMode := cbChallengeMode.Checked;
  GameParams.TimerMode := cbTimerMode.Checked;

  btnApply.Enabled := false;
end;

procedure TFormNXConfig.btnHotkeysClick(Sender: TObject);
var
  HotkeyForm: TFLemmixHotkeys;
begin
  HotkeyForm := TFLemmixHotkeys.Create(self);
  HotkeyForm.HotkeyManager := GameParams.Hotkeys;
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
