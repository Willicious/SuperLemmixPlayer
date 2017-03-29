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
    procedure OptionChanged(Sender: TObject);
    procedure cbEnableOnlineClick(Sender: TObject);
    procedure SliderChange(Sender: TObject);
  private
    procedure SetFromParams;
    procedure SaveToParams;
  public
    procedure SetGameParams;
  end;

var
  FormNXConfig: TFormNXConfig;

implementation

uses
  GameWindow; // for EXTRA_ZOOM_LEVELS constant

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
  cbPauseAfterBackwards.Checked := GameParams.PauseAfterBackwardsSkip;

  cbLemmingBlink.Checked := GameParams.LemmingBlink;
  cbTimerBlink.Checked := GameParams.TimerBlink;
  cbBlackOut.Checked := GameParams.BlackOutZero;
  cbNoBackgrounds.Checked := GameParams.NoBackgrounds;
  cbDisableShadows.Checked := GameParams.NoShadows;

  cbFullScreen.Checked := GameParams.FullScreen;
  cbIncreaseZoom.Checked := GameParams.IncreaseZoom;
  cbLinearResampleMenu.Checked := GameParams.LinearResampleMenu;
  cbLinearResampleGame.Checked := GameParams.LinearResampleGame;
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
  GameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;

  GameParams.LemmingBlink := cbLemmingBlink.Checked;
  GameParams.TimerBlink := cbTimerBlink.Checked;
  GameParams.BlackOutZero := cbBlackOut.Checked;
  GameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  GameParams.NoShadows := cbDisableShadows.Checked;

  GameParams.FullScreen := cbFullScreen.Checked;
  GameParams.IncreaseZoom := cbIncreaseZoom.Checked;
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
