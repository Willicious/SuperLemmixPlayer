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
    rgPlaybackStyle: TRadioGroup;
    cbAutoskip: TCheckBox;
    lblPlaybackCancelHotkey: TLabel;
    stPlaybackCancelHotkey: TStaticText;
    btnOK: TButton;
    btnCancel: TButton;
    stPackName: TStaticText;
    procedure btnBrowseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    function GetPlaybackModeHotkey: String;

  public
    procedure UpdatePackNameText;
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

    Result := '[' + KeyNames[n] + ']';
  end;
end;

procedure TFPlaybackMode.FormCreate(Sender: TObject);
begin
  stPlaybackCancelHotkey.Caption := GetPlaybackModeHotkey;
end;

end.
