unit FSuperLemmixConfig;

interface

uses
  GameControl, GameSound, LemStrings, FEditHotkeys, LemmixHotkeys, Math,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Vcl.WinXCtrls, Vcl.ExtCtrls,
  SharedGlobals;

type
  TFormNXConfig = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    NXConfigPages: TPageControl;
    Graphics: TTabSheet;
    TabSheet1: TTabSheet;
    lblUserName: TLabel;
    lblIngameSaveReplay: TLabel;
    lblPostviewSaveReplay: TLabel;
    gbReplayNamingOptions: TGroupBox;
    cbAutoSaveReplay: TCheckBox;
    cmbAutoSaveReplayPattern: TComboBox;
    cmbIngameSaveReplayPattern: TComboBox;
    cmbPostviewSaveReplayPattern: TComboBox;
    btnHotkeys: TButton;
    ebUserName: TEdit;
    cbAutoReplay: TCheckBox;
    cbPauseAfterBackwards: TCheckBox;
    cbSpawnInterval: TCheckBox;
    cbNoBackgrounds: TCheckBox;
    cbEdgeScrolling: TCheckBox;
    cbClassicMode: TCheckbox;
    cbHideShadows: TCheckBox;
    cbHideHelpers: TCheckBox;
    Label3: TLabel;
    Label5: TLabel;
    tbSoundVol: TTrackBar;
    tbMusicVol: TTrackBar;
    cbDisableTestplayMusic: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    cmbZoom: TComboBox;
    cbLinearResampleMenu: TCheckBox;
    cbFullScreen: TCheckBox;
    cbMinimapHighQuality: TCheckBox;
    cbIncreaseZoom: TCheckBox;
    cbHighResolution: TCheckBox;
    cbResetWindowSize: TCheckBox;
    cbResetWindowPosition: TCheckBox;
    cmbPanelZoom: TComboBox;
    btnResetWindow: TButton;
    rgExitSound: TRadioGroup;
    cbShowMinimap: TCheckBox;
    cbReplayAfterRestart: TCheckBox;
    cbTurboFF: TCheckBox;
    gbMenuSounds: TGroupBox;
    cbPostviewJingles: TCheckBox;
    rgGameLoading: TRadioGroup;
    cbMenuSounds: TCheckBox;
    cbColourCycle: TCheckBox;
    cbHideSkillQ: TCheckBox;
    gbReplayOptions: TGroupBox;
    gbSkillPanelOptions: TGroupBox;
    cbShowButtonHints: TCheckBox;
    cbAmigaTheme: TCheckBox;
    imgAmigaTick: TImage;
    lblScrollSpeed: TLabel;
    cmbScrollSpeed: TComboBox;
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnHotkeysClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure SliderChange(Sender: TObject);
    procedure cbFullScreenClick(Sender: TObject);
    procedure cbAutoSaveReplayClick(Sender: TObject);
    procedure cbReplayPatternEnter(Sender: TObject);
    procedure cbClassicModeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnResetWindowClick(Sender: TObject);
    procedure cbShowMinimapClick(Sender: TObject);
    procedure cbEdgeScrollingClick(Sender: TObject);
  private
    fIsSetting: Boolean;
    fResetWindowSize: Boolean;
    fResetWindowPosition: Boolean;

    procedure SetFromParams;
    procedure SaveToParams;

    procedure SetZoomDropdown(aValue: Integer = -1);
    procedure SetPanelZoomDropdown(aValue: Integer = -1);
    procedure SetCheckboxes;
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
  GameBaseScreenCommon; // For EXTRA_ZOOM_LEVELS constant

const
  PRESET_REPLAY_PATTERNS: array[0..6] of String =
  (
    '{GROUP}_{GROUPPOS}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '{TITLE}__{TIMESTAMP}',
    '{GROUP}_{GROUPPOS}__{TITLE}__{TIMESTAMP}|{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{GROUP}_{GROUPPOS}__{TIMESTAMP}|{USERNAME}__{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{TITLE}__{TIMESTAMP}',
    '{USERNAME}__{GROUP}_{GROUPPOS}__{TITLE}__{TIMESTAMP}|{USERNAME}__{TITLE}__{TIMESTAMP}',
    '*{USERNAME}__{TITLE}__{TIMESTAMP}'
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

  aBox.ItemIndex := -1;
  aBox.Text := aPattern;
end;

procedure TFormNXConfig.SetZoomDropdown(aValue: Integer = -1);
var
  i: Integer;
  MaxZoom: Integer;
begin
  cmbZoom.Items.Clear;

  MaxZoom := Min(
                   (Screen.Width div 320) + EXTRA_ZOOM_LEVELS,
                   (Screen.Height div 200) + EXTRA_ZOOM_LEVELS
                );

  if cbHighResolution.Checked then
    MaxZoom := Max(1, MaxZoom div 2);

  for i := 1 to MaxZoom do
    cmbZoom.Items.Add(IntToStr(i) + 'x Zoom');

  if aValue < 0 then
    aValue := GameParams.ZoomLevel - 1;

  cmbZoom.ItemIndex := Max(0, Min(aValue, cmbZoom.Items.Count - 1));
end;

procedure TFormNXConfig.SetPanelZoomDropdown(aValue: Integer);
var
  i: Integer;
  MaxWidth: Integer;
  MaxZoom: Integer;
begin
  cmbPanelZoom.Items.Clear;

  if GameParams.FullScreen or cbFullScreen.Checked then
    MaxWidth := Screen.Width
  else
    MaxWidth := GameParams.MainForm.ClientWidth;

  if cbShowMinimap.Checked then
    begin
      MaxZoom := Max(MaxWidth div 444, 1);
    end else begin
      MaxZoom := Max(MaxWidth div 336, 1);
    end;

  MaxZoom := Max(1, MaxZoom div 2);

  for i := 1 to MaxZoom do
    cmbPanelZoom.Items.Add(IntToStr(i) + 'x Zoom');

  if aValue < 0 then
    aValue := GameParams.PanelZoomLevel - 1;

  cmbPanelZoom.ItemIndex := Max(0, Min(aValue, cmbPanelZoom.Items.Count - 1));
end;

procedure TFormNXConfig.btnApplyClick(Sender: TObject);
begin
  SaveToParams;
end;

procedure TFormNXConfig.btnOKClick(Sender: TObject);
begin
  SaveToParams;

  if GameParams.MenuSounds then SoundManager.PlaySound(SFX_OK);
  if GameParams.AmigaTheme then SoundManager.PlaySound(SFX_AmigaDisk1);

  ModalResult := mrOK;
end;

procedure TFormNXConfig.btnResetWindowClick(Sender: TObject);
begin
  cbResetWindowSize.Checked := True;
  cbResetWindowPosition.Checked := True;
end;

procedure TFormNXConfig.SetFromParams;
begin
  fIsSetting := True;

  try
    // --- Page 1 (Global Options) --- //

    ebUserName.Text := GameParams.UserName;

    // Checkboxes
    cbAutoSaveReplay.Checked := GameParams.AutoSaveReplay;
    cmbAutoSaveReplayPattern.Enabled := GameParams.AutoSaveReplay;
    SetReplayPatternDropdown(cmbAutoSaveReplayPattern, GameParams.AutoSaveReplayPattern);
    SetReplayPatternDropdown(cmbIngameSaveReplayPattern, GameParams.IngameSaveReplayPattern);
    SetReplayPatternDropdown(cmbPostviewSaveReplayPattern, GameParams.PostviewSaveReplayPattern);

    // --- Page 2 (Interface Options) --- //
    // Checkboxes
    cbPauseAfterBackwards.Checked := GameParams.PauseAfterBackwardsSkip;
    cbAutoReplay.Checked := GameParams.AutoReplayMode;
    cbReplayAfterRestart.Checked := GameParams.ReplayAfterRestart;
    cbNoBackgrounds.Checked := GameParams.NoBackgrounds;
    cbColourCycle.Checked := GameParams.ColourCycle;
    cbShowButtonHints.Checked := GameParams.ShowButtonHints;
    cbClassicMode.Checked := GameParams.ClassicMode;
    cbHideShadows.Checked := GameParams.HideShadows;
    cbHideHelpers.Checked := GameParams.HideHelpers;
    cbHideSkillQ.Checked := GameParams.HideSkillQ;
    cbSpawnInterval.Checked := GameParams.SpawnInterval;

    // Edge scrolling
    cbEdgeScrolling.Checked := GameParams.EdgeScroll;
    cmbScrollSpeed.ItemIndex := GameParams.EdgeScrollSpeed;

    cbFullScreen.Checked := GameParams.FullScreen;
    cbResetWindowSize.Enabled := not GameParams.FullScreen;
    cbResetWindowSize.Checked := False;
    cbResetWindowPosition.Enabled := not GameParams.FullScreen;
    cbResetWindowPosition.Checked := False;
    cbHighResolution.Checked := GameParams.HighResolution; // Must be done before SetZoomDropdown
    cbIncreaseZoom.Checked := GameParams.IncreaseZoom;
    cbLinearResampleMenu.Checked := GameParams.LinearResampleMenu;
    cbMinimapHighQuality.Checked := GameParams.MinimapHighQuality;

    cbShowMinimap.Checked := GameParams.ShowMinimap;
    cbTurboFF.Checked := GameParams.TurboFF;

    // Zoom Dropdown
    SetZoomDropdown;
    SetPanelZoomDropdown;

    // --- Page 3 (Audio Options) --- //
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
    cbMenuSounds.Checked := GameParams.MenuSounds;

    cbAmigaTheme.Checked := GameParams.AmigaTheme;

    btnApply.Enabled := False;
  finally
    fIsSetting := False;
  end;
end;

procedure TFormNXConfig.SaveToParams;
begin

  // --- Page 1 (Global Options) --- //

  GameParams.UserName := ebUserName.Text;

  // Checkboxes
  GameParams.AutoSaveReplay := cbAutoSaveReplay.Checked;
  GameParams.AutoSaveReplayPattern := GetReplayPattern(cmbAutoSaveReplayPattern);
  GameParams.IngameSaveReplayPattern := GetReplayPattern(cmbIngameSaveReplayPattern);
  GameParams.PostviewSaveReplayPattern := GetReplayPattern(cmbPostviewSaveReplayPattern);

  GameParams.LoadNextUnsolvedLevel := rgGameLoading.ItemIndex = 0;

  // --- Page 2 (Interface Options) --- //
  // Checkboxes
  GameParams.PauseAfterBackwardsSkip := cbPauseAfterBackwards.Checked;
  GameParams.AutoReplayMode := cbAutoReplay.Checked;
  GameParams.ReplayAfterRestart := cbReplayAfterRestart.Checked;

  GameParams.NoBackgrounds := cbNoBackgrounds.Checked;
  GameParams.ColourCycle := cbColourCycle.Checked;
  GameParams.ShowButtonHints := cbShowButtonHints.Checked;
  GameParams.ClassicMode := cbClassicMode.Checked;
  GameParams.HideShadows := cbHideShadows.Checked;
  GameParams.HideHelpers := cbHideHelpers.Checked;
  GameParams.HideSkillQ := cbHideSkillQ.Checked;
  GameParams.SpawnInterval := cbSpawnInterval.Checked;

  // Edge scrolling
  GameParams.EdgeScroll := cbEdgeScrolling.Checked;
  GameParams.EdgeScrollSpeed := cmbScrollSpeed.ItemIndex;

  GameParams.FullScreen := cbFullScreen.Checked;
  fResetWindowSize := cbResetWindowSize.Checked;
  fResetWindowPosition := cbResetWindowPosition.Checked;
  GameParams.HighResolution := cbHighResolution.Checked;
  GameParams.IncreaseZoom := cbIncreaseZoom.Checked;
  GameParams.LinearResampleMenu := cbLinearResampleMenu.Checked;
  GameParams.MinimapHighQuality := cbMinimapHighQuality.Checked;

  GameParams.ShowMinimap := cbShowMinimap.Checked;
  GameParams.TurboFF := cbTurboFF.Checked;

  // Zoom Dropdown
  GameParams.ZoomLevel := cmbZoom.ItemIndex + 1;
  GameParams.PanelZoomLevel := cmbPanelZoom.ItemIndex + 1;

  // --- Page 3 (Audio Options) --- //
  SoundManager.MuteSound := tbSoundVol.Position = 0;
  if tbSoundVol.Position <> 0 then
    SoundManager.SoundVolume := tbSoundVol.Position;
  SoundManager.MuteMusic := tbMusicVol.Position = 0;
  if tbMusicVol.Position <> 0 then
    SoundManager.MusicVolume := tbMusicVol.Position;

  GameParams.DisableMusicInTestplay := cbDisableTestplayMusic.Checked;

  GameParams.PreferYippee := rgExitSound.ItemIndex = 0;

  GameParams.PostviewJingles := cbPostviewJingles.Checked;
  GameParams.MenuSounds := cbMenuSounds.Checked;

  GameParams.AmigaTheme := cbAmigaTheme.Checked;

  btnApply.Enabled := False;
end;

procedure TFormNXConfig.btnHotkeysClick(Sender: TObject);
var
  HotkeyForm: TFLemmixHotkeys;
begin
  HotkeyForm := TFLemmixHotkeys.Create(Self);
  HotkeyForm.HotkeyManager := GameParams.Hotkeys;
  HotkeyForm.ShowModal;
  HotkeyForm.Free;
end;

//procedure TFormNXConfig.btnStylesClick(Sender: TObject);
//var
  //F: TFManageStyles;
  //OldEnableOnline: Boolean;
//begin
  //OldEnableOnline := GameParams.EnableOnline;
  //GameParams.EnableOnline := cbEnableOnline.Checked; // Behave as checkbox indicates; but don't break the Cancel button.
  //F := TFManageStyles.Create(Self);
  //try
    //F.ShowModal;
  //finally
    //F.Free;
   // GameParams.EnableOnline := OldEnableOnline;
  //end;
//end;

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
    begin
      if cbHighResolution.Checked then
      begin
        NewZoom := cmbZoom.ItemIndex div 2;
        NewPanelZoom := cmbPanelZoom.ItemIndex div 2;
      end else begin
        NewZoom := cmbZoom.ItemIndex * 2 + 1;
        NewPanelZoom := cmbZoom.ItemIndex * 2 + 1;
      end;

      // If changing showminimap, we need to reset window
      if (Sender = cbShowMinimap) and not GameParams.FullScreen then
      begin
        cbResetWindowPosition.Checked := True;
        cbResetWindowSize.Checked := True;
        cbResetWindowPosition.Enabled := False;
        cbResetWindowSize.Enabled := False;
      end;
    end;

    if (Sender = cbFullScreen) and not GameParams.FullScreen then
      NewPanelZoom := cmbPanelZoom.ItemIndex;

    if NewZoom >= 0 then
      SetZoomDropdown(NewZoom);

    if NewPanelZoom >= 0 then SetPanelZoomDropdown(NewPanelZoom);

    btnApply.Enabled := True;
  end;
end;

procedure TFormNXConfig.cbAutoSaveReplayClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    cmbAutoSaveReplayPattern.Enabled := cbAutoSaveReplay.Checked;
  end;

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

procedure TFormNXConfig.cbShowMinimapClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    if cbShowMinimap.Checked then
    begin
      cbMinimapHighQuality.Enabled := True;
    end else begin
      cbMinimapHighQuality.Checked := False;
      cbMinimapHighQuality.Enabled := False;
    end;

    if not GameParams.FullScreen then
    begin
      cbResetWindowPosition.State := cbChecked;
      cbResetWindowSize.State := cbChecked;
      cbResetWindowPosition.Enabled := False;
      cbResetWindowSize.Enabled := False;
    end;
  end;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.FormCreate(Sender: TObject);
begin
  SetCheckboxes;
end;

// --- Classic Mode --- //
procedure TFormNXConfig.cbClassicModeClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    if cbClassicMode.Checked then
    begin
      cbHideShadows.Checked := True;
      cbHideHelpers.Checked := True;
      cbHideSkillQ.Checked := True;
      cbHideShadows.Enabled := False;
      cbHideHelpers.Enabled := False;
      cbHideSkillQ.Enabled := False;
    end else begin
      cbHideShadows.Checked := False;
      cbHideHelpers.Checked := False;
      cbHideSkillQ.Checked := False;
      cbHideShadows.Enabled := True;
      cbHideHelpers.Enabled := True;
      cbHideSkillQ.Enabled := True;
    end;
  end;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.cbEdgeScrollingClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    if cbEdgeScrolling.Checked then
    begin
      lblScrollSpeed.Enabled := True;
      cmbScrollSpeed.Enabled := True;
    end else begin
      lblScrollSpeed.Enabled := False;
      cmbScrollSpeed.Enabled := False;
    end;
  end;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.SetCheckboxes;
  begin
    if not GameParams.EdgeScroll then
    begin
      lblScrollSpeed.Enabled := False;
      cmbScrollSpeed.Enabled := False;
    end;


    if GameParams.ClassicMode then
    begin
      cbHideShadows.Enabled := False;
      cbHideHelpers.Enabled := False;
      cbHideSkillQ.Enabled := False;
    end;

    if not GameParams.ShowMinimap then
    begin
      cbMinimapHighQuality.Checked := False;
      cbMinimapHighQuality.Enabled := False;
    end;

    if GameParams.LoadNextUnsolvedLevel then
      rgGameLoading.ItemIndex := 0
    else
      rgGameLoading.ItemIndex := 1;

    if GameParams.PreferYippee then
      rgExitSound.ItemIndex := 0
    else
      rgExitSound.ItemIndex := 1;
  end;

procedure TFormNXConfig.cbFullScreenClick(Sender: TObject);
begin
  if not fIsSetting then
  begin
    if cbFullScreen.Checked then
    begin
      cbResetWindowSize.Checked := False;
      cbResetWindowSize.Enabled := False;
      cbResetWindowPosition.Checked := False;
      cbResetWindowPosition.Enabled := False;
    end else begin
      cbResetWindowSize.Enabled := not GameParams.FullScreen;
      cbResetWindowSize.Checked := GameParams.FullScreen;
      cbResetWindowPosition.Enabled := not GameParams.FullScreen;
      cbResetWindowPosition.Checked := GameParams.FullScreen;
    end;
  end;

  OptionChanged(Sender);
end;

procedure TFormNXConfig.SliderChange(Sender: TObject);
begin
  if not fIsSetting then
    btnApply.Enabled := True;
end;

end.
