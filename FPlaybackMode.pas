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
    btnOK: TButton;
    btnCancel: TButton;
    stPackName: TStaticText;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

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
  Dir: string;
  DisplayDir: string;
begin
  // Set the initial directory
  Dir := IncludeTrailingPathDelimiter(AppPath) + SFReplays;

  if SelectDirectory('Select a directory', Dir, DisplayDir) then
  begin
    FSelectedFolder := DisplayDir;
    stSelectedFolder.Caption := ExtractFileName(DisplayDir);
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
