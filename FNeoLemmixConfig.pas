unit FNeoLemmixConfig;

interface

uses
  GameControl, GameSound, FEditHotkeys, FStyleManager, Math,
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
    TabSheet4: TTabSheet;
    tbSoundVol: TTrackBar;
    Label3: TLabel;
    Label5: TLabel;
    tbMusicVol: TTrackBar;
    Label6: TLabel;
    cbPostviewJingles: TCheckBox;
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
    btnHotkeys: TButton;
    cbNoAutoReplay: TCheckBox;
    cbPauseAfterBackwards: TCheckBox;
    lblUserName: TLabel;
    ebUserName: TEdit;
    cbHighResolution: TCheckBox;
    btnStyles: TButton;
    cbResetWindowSize: TCheckBox;
    cbResetWindowPosition: TCheckBox;
    cbHideShadows: TCheckBox;
    cbHideAdvanced: TCheckBox;
    cbAutoSaveReplay: TCheckBox;
    cbAutoSaveReplayPattern: TComboBox;
    lblIngameSaveReplay: TLabel;
    cbIngameSaveReplayPattern: TComboBox;
    cbPostviewSaveReplayPattern: TComboBox;
    lblPostviewSaveReplay: TLabel;
    cbPanelZoom: TComboBox;
    Label2: TLabel;
    cbForceDefaultLemmings: TCheckBox;
    cbDisableTestplayMusic: TCheckBox;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnHotkeysClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure cbEnableOnlineClick(Sender: TObject);
    procedure SliderChange(Sender: TObject);
    procedure btnStylesClick(Sender: TObject);
    procedure cbFullScreenClick(Sender: TObject);
    procedure cbAutoSaveReplayClick(Sender: TObject);
    procedure cbReplayPatternEnter(Sender: TObject);
  private
    fIsSetting: Boolean;
    fResetWindowSize: Boolean;
    fResetWindowPosition: Boolean;

    procedure SetFromParams;
    procedure SaveToParams;

    procedure SetZoomDropdown(aValue: Integer = -1);
    procedure SetPanelZoomDropdown(aValue: Integer = -1);
    function GetResetWindowSize: Boolean;
    function GetResetWindowPosition: Boolean;

    procedure SetReplayPatternDropdown(aBox: TComboBox; aPattern: String);
    function GetReplayPattern(aBox: TComboBox): String;
  public
    procedure SetGameParams;
    property ResetWindowSize: Boolean read GetResetWindowSize;
    property ResetWindowPosition: Boolean read GetResetWindowPosition;
  end;

var
  FormNXConfig: TFormNXConfig;

implementation

uses
  GameBaseScreenCommon, // for EXTRA_ZOOM_LEVELS constant
  GameMenuScreen; // for disabling the MassReplayCheck button if necessary.

const
  PRESET_REPLAY_PATTERNS: array[0..3] of String =
  (
    '{GROUP}_{GROUPPOS}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '{TITLE}__{TIMESTAMP}',
    '{GROUP}_{GROUPPOS}__{TITLE}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '*{TITLE}__{TIMESTAMP}'
  );

{$R *.dfm}

function TFormNXConfig.GetResetWindowSize: Boolean;
begin
  Result := fResetWindowSize and not GameParams.FullScreen;
end;

function TFormNXConfig.GetReplayPattern(aBox: TComboBox): String;
begin
  if aBox.ItemIndex = -1 then
    Result := aBox.Text
  else
    Result := PRESET_REPLAY_PATTERNS[aBox.ItemIndex];
end;

function TFormNXConfig.GetResetWindowPosition: Boolean;
begin
  Result := fResetWindowPosition and not GameParams.FullScreen;
end;

procedure TFormNXConfig.SetGameParams;
begin
  SetFromParams;
end;

procedure TFormNXConfig.SetReplayPatternDropdown(aBox: TComboBox;
  aPattern: String);
var
  i: Integer;
begin
  for i := 0 to aBox.Items.Count-1 do
    if PRESET_REPLAY_PATTERNS[i] = aPattern then
    begin
      aBox.ItemIndex := i;
      Exit;
    end;

  aBox.Text := aPattern;
end;

procedure TFormNXConfig.SetZoomDropdown(aValue: Integer = -1);
var
  i: Integer;
  MaxZoom: Integer;
begin
  cbZoom.Items.Clear;

  MaxZoom := Min(
                   (Screen.Width div 320) + EXTRA_ZOOM_LEVELS,
                   (Screen.Height div 200) + EXTRA_ZOOM_LEVELS
                );

  if cbHighResolution.Checked then
    MaxZoom := Max(1, MaxZoom div 2);

  for i := 1 to MaxZoom do
    cbZoom.Items.Add(IntToStr(i) + 'x Zoom');

  if aValue < 0 then
    aValue := GameParams.ZoomLevel - 1;

  cbZoom.ItemIndex := Max(0, Min(aValue, cbZoom.Items.Count - 1));
end;

procedure TFormNXConfig.SetPanelZoomDropdown(aValue: Integer);
var
  i: Integer;
  MaxWidth: Integer;
  MaxZoom: Integer;
begin
  cbPanelZoom.Items.Clear;

  if GameParams.FullScreen or cbFullScreen.Checked then
    MaxWidth := Screen.Width
  else
    MaxWidth := GameParams.MainForm.ClientWidth;

  if cbCompactSkillPanel.Checked then
    MaxZoom := Max(MaxWidth div 320, 1)
  else
    MaxZoom := Max(MaxWidth div 416, 1);

  if cbHighResolution.Checked then
    MaxZoom := Max(1, MaxZoom div 2);

  for i := 1 to MaxZoom do
    cbPanelZoom.Items.Add(IntToStr(i) + 'x Zoom');

  if aValue < 0 then
    aValue := GameParams.PanelZoomLevel - 1;

  cbPanelZoom.ItemIndex := Max(0, Min(aValue, cbPanelZoom.Items.Count - 1));
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
begin
  fIsSetting := true;

  try
    //// Page 1 (Global Options) ////

    ebUserName.Text := GameParams.UserName;

    // Checkboxes
    cbAutoSaveReplay.Checked := GameParams.AutoSaveReplay;
    SetReplayPatternDropdown(cbAutoSaveReplayPattern, GameParams.AutoSaveReplayPattern);
    SetReplayPatternDropdown(cbIngameSaveReplayPattern, GameParams.IngameSaveReplayPattern);
    SetReplayPatternDropdown(cbPostviewSaveReplayPattern, GameParams.PostviewSaveReplayPattern);

    cbUpdateCheck.Checked := GameParams.CheckUpdates; // in reverse order as the next one may override this
    cbEnableOnline.Checked := GameParams.EnableOnline;

    //// Page 2 (Interface Options) ////
    // Checkboxes
    cbPauseAfterBackwards.Checked := GameParams.PauseAfterBackwardsSkip;
    cbNoAutoReplay.Checked := GameParams.NoAutoReplayMode;

    cbNoBackgrounds.Checked := GameParams.NoBackgrounds;
    cbForceDefaultLemmings.Checked := GameParams.ForceDefaultLemmings;
    cbHideShadows.Checked := GameParams.HideShadows;
    cbEdgeScrolling.Checked := GameParams.EdgeScroll;
    cbSpawnInterval.Checked := GameParams.SpawnInterval;
    cbHideAdvanced.Checked := GameParams.HideAdvancedOptions;

    cbFullScreen.Checked := GameParams.FullScreen;
    cbResetWindowSize.Enabled := not GameParams.FullScreen;
    cbResetWindowSize.Checked := false;
    cbResetWindowPosition.Enabled := not GameParams.FullScreen;
    cbResetWindowPosition.Checked := false;
    cbHighResolution.Checked := GameParams.HighResolution; // must be done before SetZoomDropdown
    cbIncreaseZoom.Checked := GameParams.IncreaseZoom;
    cbLinearResampleMenu.Checked := GameParams.LinearResampleMenu;
    cbLinearResampleGame.Checked := GameParams.LinearResampleGame;
    cbCompactSkillPanel.Checked := GameParams.CompactSkillPanel;
    cbMinimapHighQuality.Checked := GameParams.MinimapHighQuality;

    // Zoom Dropdown
    SetZoomDropdown;
    SetPanelZoomDropdown;

    //// Page 3 (Audio Options) ////
    if SoundManager.MuteSound then
      tbSoundVol.Position := 0
    else
      tbSoundVol.Position := SoundManager.SoundVolume;
    if SoundManager.MuteMusic then
      tbMusicVol.Position := 0
    else
      tbMusicVol.Position := SoundManager.MusicVolume;

    cbDisableTestplayMusic.Checked := GameParams.DisableMusicInTestplay;
    cbPostviewJingles.Checked := GameParams.PostviewJingles;

    btnApply.Enabled := false;
  finally
    fIsSetting := false;
  end;
end;

procedure TFormNXConfig.SaveToParams;
begin

  //// Page 1 (Global Options) ////

  GameParams.UserName := ebUserName.Text;

  // Checkboxes
  GameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  GameParams.AutoSaveReplayPattern := GetReplayPattern(cbAutoSaveReplayPattern);
  GameParams.IngameSaveReplayPattern := GetReplayPattern(cbIngameSaveReplayPattern);
  GameParams.PostviewSaveReplayPattern := GetReplayPattern(cbPostviewSaveReplayPattern);

  GameParams.EnableOnline := cbEnableOnline.Checked;
  GameParams.CheckUpdates := cbUpdateCheck.Checked;

  //// Page 2 (Interface Options) ////
  // Checkboxes
  GameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;
  GameParams.NoAutoReplayMode := cbNoAutoReplay.Checked;

  GameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  GameParams.ForceDefaultLemmings := cbForceDefaultLemmings.Checked;
  GameParams.HideShadows := cbHideShadows.Checked;
  GameParams.EdgeScroll := cbEdgeScrolling.Checked;
  GameParams.SpawnInterval := cbSpawnInterval.Checked;
  GameParams.HideAdvancedOptions := cbHideAdvanced.Checked;

  GameParams.FullScreen := cbFullScreen.Checked;
  fResetWindowSize := cbResetWindowSize.Checked;
  fResetWindowPosition := cbResetWindowPosition.Checked;
  GameParams.HighResolution := cbHighResolution.Checked;
  GameParams.IncreaseZoom := cbIncreaseZoom.Checked;
  GameParams.LinearResampleMenu := cbLinearResampleMenu.Checked;
  GameParams.LinearResampleGame := cbLinearResampleGame.Checked;
  GameParams.CompactSkillPanel := cbCompactSkillPanel.Checked;
  GameParams.MinimapHighQuality := cbMinimapHighQuality.Checked;

  // Zoom Dropdown
  GameParams.ZoomLevel := cbZoom.ItemIndex + 1;
  GameParams.PanelZoomLevel := cbPanelZoom.ItemIndex + 1;

  //// Page 3 (Audio Options) ////
  SoundManager.MuteSound := tbSoundVol.Position = 0;
  if tbSoundVol.Position <> 0 then
    SoundManager.SoundVolume := tbSoundVol.Position;
  SoundManager.MuteMusic := tbMusicVol.Position = 0;
  if tbMusicVol.Position <> 0 then
    SoundManager.MusicVolume := tbMusicVol.Position;

  GameParams.DisableMusicInTestplay := cbDisableTestplayMusic.Checked;
  GameParams.PostviewJingles := cbPostviewJingles.Checked;

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

procedure TFormNXConfig.btnStylesClick(Sender: TObject);
var
  F: TFManageStyles;
  OldEnableOnline: Boolean;
begin
  OldEnableOnline := GameParams.EnableOnline;
  GameParams.EnableOnline := cbEnableOnline.Checked; // Behave as checkbox indicates; but don't break the Cancel button.
  F := TFManageStyles.Create(self);
  try
    F.ShowModal;
  finally
    F.Free;
    GameParams.EnableOnline := OldEnableOnline;
  end;
end;

procedure TFormNXConfig.OptionChanged(Sender: TObject);
var
  NewZoom: Integer;
  NewPanelZoom: Integer;
begin
  if not fIsSetting then
  begin
    NewZoom := -1;
    NewPanelZoom := -1;

    if Sender = cbHighResolution then
      if cbHighResolution.Checked then
      begin
        NewZoom := cbZoom.ItemIndex div 2;
        NewPanelZoom := cbPanelZoom.ItemIndex div 2;
      end else begin
        NewZoom := cbZoom.ItemIndex * 2 + 1;
        NewPanelZoom := cbZoom.ItemIndex * 2 + 1;
      end;

    if Sender = cbCompactSkillPanel then
      NewPanelZoom := cbPanelZoom.ItemIndex;

    if (Sender = cbFullScreen) and not GameParams.FullScreen then
      NewPanelZoom := cbPanelZoom.ItemIndex;

    if NewZoom >= 0 then SetZoomDropdown(NewZoom);
    if NewPanelZoom >= 0 then SetPanelZoomDropdown(NewPanelZoom);

    btnApply.Enabled := true;
  end;
end;

procedure TFormNXConfig.cbAutoSaveReplayClick(Sender: TObject);
begin
  cbAutoSaveReplayPattern.Enabled := cbAutoSaveReplay.Checked;
  OptionChanged(Sender);
end;

procedure TFormNXConfig.cbReplayPatternEnter(Sender: TObject);
var
  P: TComboBox;
begin
  if not (Sender is TComboBox) then Exit;
  P := TComboBox(Sender);

  if P.ItemIndex >= 0 then
    P.Text := PRESET_REPLAY_PATTERNS[P.ItemIndex];
end;

procedure TFormNXConfig.cbEnableOnlineClick(Sender: TObject);
begin
  cbUpdateCheck.Enabled := cbEnableOnline.Checked;
  if not cbEnableOnline.Checked then cbUpdateCheck.Checked := false;
  btnApply.Enabled := true;
end;

procedure TFormNXConfig.cbFullScreenClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    OptionChanged(Sender);

    if cbFullScreen.Checked then
    begin
      cbResetWindowSize.Checked := false;
      cbResetWindowSize.Enabled := false;
      cbResetWindowPosition.Checked := false;
      cbResetWindowPosition.Enabled := false;
    end else begin
      cbResetWindowSize.Enabled := not GameParams.FullScreen;
      cbResetWindowSize.Checked := GameParams.FullScreen;
      cbResetWindowPosition.Enabled := not GameParams.FullScreen;
      cbResetWindowPosition.Checked := GameParams.FullScreen;
    end;
  end;
end;

procedure TFormNXConfig.SliderChange(Sender: TObject);
begin
  btnApply.Enabled := true;
end;

end.
