unit FNeoLemmixConfig;

interface

uses
  GameControl, GameSound, FEditHotkeys,
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
    GroupBox3: TGroupBox;
    cbNoBackgrounds: TCheckBox;
    GroupBox1: TGroupBox;
    cbEnableOnline: TCheckBox;
    cbUpdateCheck: TCheckBox;
    GroupBox6: TGroupBox;
    cbZoom: TComboBox;
    Label1: TLabel;
    cbLinearResampleMenu: TCheckBox;
    cbLinearResampleGame: TCheckBox;
    cbFullScreen: TCheckBox;
    cbMinimapHighQuality: TCheckBox;
    cbIncreaseZoom: TCheckBox;
    cbCompactSkillPanel: TCheckBox;
    cbEdgeScrolling: TCheckBox;
    cbSpawnInterval: TCheckBox;
    cbReplayAutoName: TCheckBox;
    btnHotkeys: TButton;
    btnReplayCheck: TButton;
    cbNoAutoReplay: TCheckBox;
    cbPauseAfterBackwards: TCheckBox;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnHotkeysClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure cbEnableOnlineClick(Sender: TObject);
    procedure SliderChange(Sender: TObject);
    procedure btnReplayCheckClick(Sender: TObject);
  private
    procedure SetFromParams;
    procedure SaveToParams;
  public
    constructor Create(aOwner: TComponent); override;
    procedure SetGameParams;
  end;

var
  FormNXConfig: TFormNXConfig;

implementation

uses
  GameWindow, // for EXTRA_ZOOM_LEVELS constant
  GameMenuScreen; // for disabling the MassReplayCheck button if necessary.

{$R *.dfm}

constructor TFormNXConfig.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  btnReplayCheck.Enabled := (aOwner is TGameMenuScreen);
end;

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

  //// Page 1 (Global Options) ////
  // Checkboxes
  cbAutoSaveReplay.Checked := GameParams.AutoSaveReplay;
  cbReplayAutoName.Checked := GameParams.ReplayAutoName;

  cbNoAutoReplay.Checked := GameParams.NoAutoReplayMode;
  cbUpdateCheck.Checked := GameParams.CheckUpdates; // in reverse order as the next one may override this
  cbEnableOnline.Checked := GameParams.EnableOnline;

  //// Page 2 (Interface Options) ////
  // Checkboxes
  cbPauseAfterBackwards.Checked := GameParams.PauseAfterBackwardsSkip;

  cbNoBackgrounds.Checked := GameParams.NoBackgrounds;
  cbEdgeScrolling.Checked := GameParams.EdgeScroll;
  cbSpawnInterval.Checked := GameParams.SpawnInterval;

  cbFullScreen.Checked := GameParams.FullScreen;
  cbIncreaseZoom.Checked := GameParams.IncreaseZoom;
  cbLinearResampleMenu.Checked := GameParams.LinearResampleMenu;
  cbLinearResampleGame.Checked := GameParams.LinearResampleGame;
  cbCompactSkillPanel.Checked := GameParams.CompactSkillPanel;
  cbMinimapHighQuality.Checked := GameParams.MinimapHighQuality;

  // Zoom Dropdown
  cbZoom.Items.Clear;
  i := 1;
  while ((i - EXTRA_ZOOM_LEVELS) * 320 <= Screen.Width) and ((i - EXTRA_ZOOM_LEVELS) * 200 < Screen.Height) do
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

  btnApply.Enabled := false;
end;

procedure TFormNXConfig.SaveToParams;
begin

  //// Page 1 (Global Options) ////
  // Checkboxes
  GameParams.EnableOnline := cbEnableOnline.Checked;
  GameParams.CheckUpdates := cbUpdateCheck.Checked;
  GameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  GameParams.ReplayAutoName := cbReplayAutoName.Checked;
  GameParams.NoAutoReplayMode := cbNoAutoReplay.Checked;

  //// Page 2 (Interface Options) ////
  // Checkboxes
  GameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;

  GameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  GameParams.EdgeScroll := cbEdgeScrolling.Checked;
  GameParams.SpawnInterval := cbSpawnInterval.Checked;

  GameParams.FullScreen := cbFullScreen.Checked;
  GameParams.IncreaseZoom := cbIncreaseZoom.Checked;
  GameParams.LinearResampleMenu := cbLinearResampleMenu.Checked;
  GameParams.LinearResampleGame := cbLinearResampleGame.Checked;
  GameParams.CompactSkillPanel := cbCompactSkillPanel.Checked;
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

procedure TFormNXConfig.btnReplayCheckClick(Sender: TObject);
begin
  // We abuse mrRetry here to signal the menu screen that we want to mass replay check
  ModalResult := mrRetry;
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
