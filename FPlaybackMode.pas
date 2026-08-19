unit FPlaybackMode;

interface

uses
  GameControl,
  LemStrings,
  LemTypes,
  LemNeoLevelPack,
  LemmixHotkeys,
  FEditHotkeys,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, FileCtrl, ExtCtrls,
  SharedGlobals;

type
  TFPlaybackMode = class(TForm)
    btnBrowse: TButton;
    stSelectedFolder: TStaticText;
    lblSelectedFolder: TLabel;
    rgPlaybackOrder: TRadioGroup;
    cbAutoskip: TCheckBox;
    lblPlaybackCancelHotkey: TLabel;
    btnBeginPlayback: TButton;
    btnCancel: TButton;
    stPackName: TStaticText;
    lblWelcome: TLabel;
    btnConfigureHotkeys: TButton;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBeginPlaybackClick(Sender: TObject);
    procedure btnConfigureHotkeysClick(Sender: TObject);

  private
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    function GetPlaybackCancelHotkey: String;
    procedure ShowPlaybackCancelHotkey;

  public
    procedure UpdatePackNameText;
    procedure SetGameParams;
    property SelectedFolder: string read fSelectedFolder write fSelectedFolder;
    property CurrentlySelectedPack: string read fCurrentlySelectedPack write fCurrentlySelectedPack;

  end;

implementation

  uses
    FSuperLemmixLevelSelect;

{$R *.dfm}

procedure TFPlaybackMode.btnBrowseClick(Sender: TObject);
var
  Dialog: TFileOpenDialog;
  InitialDir: String;
begin
  InitialDir := AppPath + SFReplays +
    MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name);

  if not SysUtils.DirectoryExists(InitialDir) then
    InitialDir := AppPath + SFReplays;

  Dialog := TFileOpenDialog.Create(Self);
  try
    Dialog.Title := 'Select a folder containing replays';
    Dialog.DefaultFolder := InitialDir;
    Dialog.Options := Dialog.Options + [fdoPickFolders];

    if Dialog.Execute then
    begin
      fSelectedFolder := Dialog.FileName;

      if SysUtils.DirectoryExists(fSelectedFolder) then
      begin
        SetCurrentDir(fSelectedFolder);
        stSelectedFolder.Caption :=
          ExtractFileName(ExcludeTrailingPathDelimiter(fSelectedFolder));
      end else
        ShowMessage('The selected folder path is invalid.');
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TFPlaybackMode.UpdatePackNameText;
var
  Pack: String;
begin
  Pack := CurrentlySelectedPack;

  if Pack <> '' then
    stPackName.Caption := Pack
  else
    stPackName.Caption := 'Playback Mode';
end;

function TFPlaybackMode.GetPlaybackCancelHotkey: String;
var
  Key: TLemmixHotkeyAction;
  ThisKey: TLemmixHotkey;
  KeyNames: TKeyNameArray;

  n: Integer;
begin
  Result := '';

  Key := lka_CancelPlayback;
  KeyNames := TLemmixHotkeyManager.GetKeyNames(True);

  for n := 0 to MAX_KEY do
  begin
    ThisKey := GameParams.Hotkeys.CheckKeyEffect(n);
    if ThisKey.Action = Key then
    begin
      Result := KeyNames[n];
      Exit;
    end;
  end;
end;

procedure TFPlaybackMode.btnConfigureHotkeysClick(Sender: TObject);
var
  HotkeyForm: TFLemmixHotkeys;
begin
  HotkeyForm := TFLemmixHotkeys.Create(Self);
  HotkeyForm.HotkeyManager := GameParams.Hotkeys;
  HotkeyForm.ShowModal;
  HotkeyForm.Free;

  ShowPlaybackCancelHotkey;
end;

procedure TFPlaybackMode.SetGameParams;
begin
  GameParams.AutoSkipPreviewPostview := cbAutoSkip.Checked;

  if (rgPlaybackOrder.ItemIndex >= Ord(Low(TPlaybackOrder)))
    and (rgPlaybackOrder.ItemIndex <= Ord(High(TPlaybackOrder))) then
      GameParams.PlaybackOrder := TPlaybackOrder(rgPlaybackOrder.ItemIndex);
end;

procedure TFPlaybackMode.btnBeginPlaybackClick(Sender: TObject);
begin
  if fSelectedFolder = '' then
  begin
    ShowMessage('No replays selected. Please choose a folder of replays to begin Playback Mode.');
    ModalResult := mrNone;
  end;
end;

procedure TFPlaybackMode.FormCreate(Sender: TObject);
begin
  stPackName.Font.Name := 'Hobo Std';

  // Set options and clear lists
  rgPlaybackOrder.ItemIndex := Ord(GameParams.PlaybackOrder);
  cbAutoSkip.Checked := GameParams.AutoSkipPreviewPostview;
  GameParams.PlaybackList.Clear;
  GameParams.UnmatchedList.Clear;
  GameParams.ReplayVerifyList.Clear;

  // Show currently-assigned Playback Cancel Hotkey
  ShowPlaybackCancelHotkey;
end;

procedure TFPlaybackMode.ShowPlaybackCancelHotkey;
var
  sHotkey: String;
begin
  sHotkey := GetPlaybackCancelHotkey;

  if (sHotkey = '') then
    sHotkey := '...';

  btnConfigureHotkeys.Caption := sHotkey;
end;

procedure TFPlaybackMode.FormDestroy(Sender: TObject);
begin
  SetGameParams;
end;

end.
