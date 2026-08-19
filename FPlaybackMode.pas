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
  Generics.Collections, Generics.Defaults,
  Types, System.IOUtils,
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
    fReplayFiles: TStringDynArray;
    fSelectedFolder: string;
    fCurrentlySelectedPack: string;
    fOrderedLevels: TList<TNeoLevelEntry>;
    fLevelIndex: TDictionary<Int64, Integer>;

    function GetPlaybackCancelHotkey: String;
    function ReadyForPlayback: Boolean;
    procedure ShowPlaybackCancelHotkey;
    procedure BuildPlaybackItems;
    procedure BuildPlaylist;

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
    Exit;
  end;

  if ReadyForPlayback then
    ModalResult := mrOK;
end;

procedure TFPlaybackMode.FormCreate(Sender: TObject);
begin
  stPackName.Font.Name := 'Hobo Std';

  fOrderedLevels := TList<TNeoLevelEntry>.Create;
  fLevelIndex := TDictionary<Int64, Integer>.Create;

  // Set options and clear list
  rgPlaybackOrder.ItemIndex := Ord(GameParams.PlaybackOrder);
  cbAutoSkip.Checked := GameParams.AutoSkipPreviewPostview;
  GameParams.PlaybackItems.Clear;

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

procedure TFPlaybackMode.BuildPlaybackItems;
var
  ReplayFile: string;
  PlaybackItem: TPlaybackItem;
begin
  GameParams.PlaybackItems.Clear;

  fReplayFiles := TDirectory.GetFiles(SelectedFolder, '*.nxrp');

  for ReplayFile in fReplayFiles do
  begin
    PlaybackItem.ReplayFile := ReplayFile;
    PlaybackItem.ReplayID := GameParams.GetReplayID(ReplayFile);
    PlaybackItem.Level := GameParams.FindLevelByID(PlaybackItem.ReplayID, True);
    GameParams.PlaybackItems.Add(PlaybackItem);
  end;
end;

procedure TFPlaybackMode.BuildPlaylist;
var
  Items: TList<TPlaybackItem>;

  procedure BuildOrderedLevelList(G: TNeoLevelGroup);
  var
    i: Integer;
  begin
    for i := 0 to G.Children.Count - 1 do
      BuildOrderedLevelList(G.Children[i]);

    for i := 0 to G.Levels.Count - 1 do
      fOrderedLevels.Add(G.Levels[i]);
  end;

  procedure FinaliseLevelIndex;
  var
    i: Integer;
  begin
    for i := 0 to fOrderedLevels.Count - 1 do
      fLevelIndex.Add(fOrderedLevels[i].LevelID, i);
  end;

  procedure SortItemsByLevel;
  begin
    Items := GameParams.PlaybackItems;

    Items.Sort(
      TComparer<TPlaybackItem>.Construct(
        function(const A, B: TPlaybackItem): Integer
        var
          IA, IB: Integer;
        begin
          if (A.Level = nil) or (not fLevelIndex.TryGetValue(A.Level.LevelID, IA)) then
            IA := MaxInt;

          if (B.Level = nil) or (not fLevelIndex.TryGetValue(B.Level.LevelID, IB)) then
            IB := MaxInt;

          Result := IA - IB;
        end));
  end;

  procedure ShuffleItems(const List: TList<TPlaybackItem>);
  var
    i, j: Integer;
    Temp: TPlaybackItem;
  begin
    if List.Count <= 1 then Exit;

    for i := List.Count - 1 downto 1 do
    begin
      j := Random(i + 1);

      Temp := List[i];
      List[i] := List[j];
      List[j] := Temp;
    end;
  end;
begin
  fOrderedLevels.Clear;
  fLevelIndex.Clear;

  case GameParams.PlaybackOrder of
    poByReplay:
    begin
      // Do nothing - BuildPlaybackItems already built the list in folder order
    end;

    poByLevel:
    begin
      BuildOrderedLevelList(GameParams.CurrentLevel.Group.ParentBasePack);
      FinaliseLevelIndex;
      SortItemsByLevel;
    end;

    poRandom:
    begin
      ShuffleItems(GameParams.PlaybackItems);
    end;
  end;
end;

function TFPlaybackMode.ReadyForPlayback: Boolean;
begin
  Result := False;

  if fSelectedFolder = '' then
    Exit;

  SetGameParams;

  GameParams.PlaybackModeActive := True;
  GameParams.Save(scImportant);

  BuildPlaybackItems;
  BuildPlaylist;

  Result := True;
end;

procedure TFPlaybackMode.FormDestroy(Sender: TObject);
begin
  fOrderedLevels.Free;
  fLevelIndex.Free;
end;

end.
