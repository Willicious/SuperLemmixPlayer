unit FPlaybackMode;

interface

uses
  GameControl,
  LemStrings,
  LemTypes,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, FileCtrl, ExtCtrls;

type
  TFPlaybackMode = class(TForm)
    btnBrowse: TButton;
    stSelectedFolder: TStaticText;
    lblSelectedFolder: TLabel;
    rgPlaybackOrder: TRadioGroup;
    cbAutoskip: TCheckBox;
    lblPlaybackCancelHotkey: TLabel;
    stPlaybackCancelHotkey: TStaticText;
    btnBeginPlayback: TButton;
    btnCancel: TButton;
    stPackName: TStaticText;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBeginPlaybackClick(Sender: TObject);

  private
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    function GetPlaybackModeHotkey: String;

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
  OpenDlg: TOpenDialog;
  Dir: string;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    Dir := IncludeTrailingPathDelimiter(AppPath) + SFReplays;
    OpenDlg.Title := 'Select any file in the folder containing replays';
    OpenDlg.InitialDir := Dir;
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing, ofPathMustExist];

    if OpenDlg.Execute then
    begin
      fSelectedFolder := ExtractFilePath(OpenDlg.FileName);
      SetCurrentDir(fSelectedFolder);
      stSelectedFolder.Caption := ExtractFileName(ExcludeTrailingPathDelimiter(fSelectedFolder));
    end;
  finally
    OpenDlg.Free;
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

function TFPlaybackMode.GetPlaybackModeHotkey: String;
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
    if ThisKey.Action <> Key then Continue;

    Result := KeyNames[n];
  end;
end;

procedure TFPlaybackMode.SetGameParams;
begin
  GameParams.AutoSkipPreAndPostview := cbAutoSkip.Checked;

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
  end else
    ModalResult := mrRetry;
end;

procedure TFPlaybackMode.FormCreate(Sender: TObject);
begin
  // Set default options and clear PlaybackList
  rgPlaybackOrder.ItemIndex := 0;
  cbAutoSkip.Checked := True;
  GameParams.PlaybackList.Clear;

  // Show currently-assigned Playback Mode hotkey
  stPlaybackCancelHotkey.Caption := GetPlaybackModeHotkey;
end;

procedure TFPlaybackMode.FormDestroy(Sender: TObject);
begin
  SetGameParams;
end;

end.
