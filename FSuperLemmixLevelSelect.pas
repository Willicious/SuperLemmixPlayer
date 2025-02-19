unit FSuperLemmixLevelSelect;

interface

uses
  GameControl, GameSound,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  LemCore,
  LemTalisman,
  PngInterface,
  FLevelInfo, FPlaybackMode,
  GR32, GR32_Resamplers, GR32_Layers, GR32_Image,
  Generics.Collections,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Buttons,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList, StrUtils, UMisc, Math, UITypes,
  Types, IOUtils, Vcl.FileCtrl, // For Playback Mode
  ActiveX, ShlObj, ComObj, // For the shortcut creation
  LemNeoParser, System.ImageList,
  SharedGlobals, ShellAPI, Vcl.WinXCtrls;

type
  TFLevelSelect = class(TForm)
    tvLevelSelect: TTreeView;
    btnOK: TButton;
    lblName: TLabel;
    pnLevelInfo: TPanel;
    lblPosition: TLabel;
    lblAuthor: TLabel;
    ilStatuses: TImageList;
    lblCompletion: TLabel;
    btnMakeShortcut: TButton;
    lblRecordsOptions: TLabel;
    btnSaveImage: TButton;
    btnReplayManager: TButton;
    btnCleanseLevels: TButton;
    btnCleanseOne: TButton;
    btnClearRecords: TButton;
    btnResetTalismans: TBitBtn;
    btnPlaybackMode: TButton;
    lblAdvancedOptions: TLabel;
    lblReplayOptions: TLabel;
    btnShowHideOptions: TButton;
    sbSearchLevels: TSearchBox;
    lblSearchLevels: TLabel;
    pbSearchProgress: TProgressBar;
    lbSearchResults: TListBox;
    btnCloseSearch: TButton;
    lblEditingOptions: TLabel;
    btnEditLevel: TButton;
    btnClose: TButton;
    lblSearchResultsInfo: TLabel;
    pbUIProgress: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure LoadCurrentLevelToPlayer;
    procedure FormShow(Sender: TObject);
    procedure btnMakeShortcutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure btnReplayManagerClick(Sender: TObject);
    procedure btnPlaybackModeClick(Sender:TObject);
    procedure btnCleanseLevelsClick(Sender: TObject);
    procedure btnCleanseOneClick(Sender: TObject);
    procedure btnClearRecordsClick(Sender: TObject);
    procedure tvLevelSelectChange(Sender: TObject; Node: TTreeNode);
    procedure tvLevelSelectKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnResetTalismansClick(Sender: TObject);
    procedure tvLevelSelectExpanded(Sender: TObject; Node: TTreeNode);
    procedure btnShowHideOptionsClick(Sender: TObject);
    procedure SetOptionButtons;
    procedure ShowOptionButtons;
    procedure HideOptionButtons;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure SearchLevels;
    procedure CloseSearchResultsPanel;
    procedure sbSearchLevelsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbSearchLevelsInvokeSearch(Sender: TObject);
    procedure lbSearchResultsClick(Sender: TObject);
    procedure btnCloseSearchClick(Sender: TObject);
    procedure btnEditLevelClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    fLastLevelPath: String;
    fLastGroup: TNeoLevelGroup;
    fLoadAsPack: Boolean;
    fInfoForm: TLevelInfoPanel;
    fIconBMP: TBitmap32;
    fPackTalBox: TScrollBox;
    fTalismanButtons: TObjectList<TSpeedButton>;
    fDisplayRecords: TRecordDisplay;
    fSearchingLevels: Boolean;
    fCurrentLevelVersion: Int64; // Used to check if we need to re-load the current level info
    fIsHandlingActivation: Boolean;

    procedure InitializeTreeview;
    procedure SetInfo;
    procedure LoadNodeLabels;
    procedure WriteToParams;

    function GetCompletedLevelString(G: TNeoLevelGroup): String;
    function GetPackResultsString(G: TNeoLevelGroup): String;

    procedure DisplayLevelInfo(RefreshLevel: Boolean = False);
    procedure SetTalismanInfo;
    procedure DrawTalismanButtons;
    procedure ClearTalismanButtons;
    procedure TalButtonClick(Sender: TObject);
    procedure PackListTalButtonClick(Sender: TObject);
    procedure DisplayPackTalismanInfo(Group: TNeoLevelGroup);

    procedure DrawSpeedButton(aButton: TSpeedButton; aIconIndex: Integer; aOverlayIndex: Integer = -1);

    procedure DrawIcon(aIconIndex: Integer; aDst: TBitmap32; aEraseColor: TColor);
    procedure OverlayIcon(aIconIndex: Integer; aDst: TBitmap32);

    procedure SetAdvancedOptionsGroup(G: TNeoLevelGroup);
    procedure SetAdvancedOptionsLevel(L: TNeoLevelEntry);
    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
    procedure MaybeReloadLevelInfo;

    property SearchingLevels: Boolean read fSearchingLevels write fSearchingLevels;
 public
    property LoadAsPack: Boolean read fLoadAsPack;
    procedure LoadIcons;

    function GetCurrentlySelectedPack: String;
  end;

const // Icon indexes
  ICON_BLANK = -1;

  ICON_NORMAL_LEMMING = 0;
  ICON_RIVAL_LEMMING = 1;
  ICON_ZOMBIE_LEMMING = 2;
  ICON_NEUTRAL_LEMMING = 3;

  // Empty slot = 4;
  // Empty slot = 5;

  ICON_RELEASE_RATE = 6;
  ICON_RELEASE_RATE_LOCKED = 7;
  ICON_SAVE_REQUIREMENT = 8;
  ICON_TIME_LIMIT = 9;
  ICON_TIMER = 10;

  // Empty slot = 11;

  ICON_RECORDS = 12;
  ICON_BRONZE_TALISMAN = 13;
  ICON_SILVER_TALISMAN = 14;
  ICON_GOLD_TALISMAN = 15;
  ICON_COLLECTIBLE = 16;

  // Empty slot = 17;

  ICON_WORLD_RECORDS = 18;
  ICON_TALISMAN: array[tcBronze..tcGold] of Integer =
    ( ICON_BRONZE_TALISMAN, ICON_SILVER_TALISMAN, ICON_GOLD_TALISMAN );
  ICON_TALISMAN_UNOBTAINED_OFFSET = 6;
  ICON_COLLECTIBLE_UNOBTAINED = 22;

  // Empty slot = 23;

  ICON_SELECTED_TALISMAN = 24;
  ICON_MAX_SKILLS = 25;
  ICON_MAX_SKILL_TYPES = 26;
  ICON_CLASSIC_MODE = 27;
  ICON_NO_PAUSE = 28;
  ICON_KILL_ZOMBIES = 29;

  ICON_SKILLS: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of Integer = (
    30, // 0 Walker
    31, // 1 Jumper
    32, // 2 Shimmier
    33, // 3 Ballooner
    34, // 4 Slider
    35, // 5 Climber
    36, // 6 Swimmer
    37, // 7 Floater
    38, // 8 Glider
    39, // 9 Disarmer
    40, // 10 Timebomber
    41, // 11 Bomber
    42, // 12 Freezer
    43, // 13 Blocker
    44, // 14 Ladderer
    45, // 15 Platformer
    46, // 16 Builder
    47, // 17 Stacker
    48, // 18 Spearer
    49, // 19 Grenader
    50, // 20 Laserer
    51, // 21 Basher
    52, // 22 Fencer
    53, // 23 Miner
    54, // 24 Digger

    // 55, Empty slot
    // 56, Empty slot
    // 57, Empty slot
    // 58, Empty slot

    59  // 25 Cloner

    //?, // // Batter
    //?, // // Propeller
  );

implementation

uses
  FReplayManager,
  LemLevel;

const
  SPEEDBUTTON_PADDING_SIZE = 3;

{$R *.dfm}

procedure TFLevelSelect.InitializeTreeview;

  procedure AddLevel(aLevel: TNeoLevelEntry; ParentNode: TTreeNode);
  var
    N: TTreeNode;
  begin
    N := tvLevelSelect.Items.AddChildObject(ParentNode, '', aLevel);
    case aLevel.Status of
      lst_None: N.ImageIndex := 0;
      lst_Attempted: N.ImageIndex := 1;
      lst_Completed_Outdated: N.ImageIndex := 2;
      lst_Completed: N.ImageIndex := 3;
    end;
    N.SelectedIndex := N.ImageIndex;

    if GameParams.CurrentLevel = aLevel then
      tvLevelSelect.Selected := N;
  end;

  procedure AddGroup(aGroup: TNeoLevelGroup; ParentNode: TTreeNode);
  var
    GroupNode: TTreeNode;
    i: Integer;
  begin
    if aGroup = GameParams.BaseLevelPack then
      GroupNode := nil
    else
      GroupNode := tvLevelSelect.Items.AddChildObject(ParentNode, aGroup.Name, aGroup);
    for i := 0 to aGroup.Children.Count-1 do
      AddGroup(aGroup.Children[i], GroupNode);
    for i := 0 to aGroup.Levels.Count-1 do
      AddLevel(aGroup.Levels[i], GroupNode);

    if GroupNode <> nil then
    begin
      case aGroup.Status of
        lst_None: GroupNode.ImageIndex := 0;
        lst_Attempted: GroupNode.ImageIndex := 1;
        lst_Completed_Outdated: GroupNode.ImageIndex := 2;
        lst_Completed: GroupNode.ImageIndex := 3;
      end;
      GroupNode.SelectedIndex := GroupNode.ImageIndex;
    end;
  end;

  procedure MakeImages;
  var
    BMP32, TempBMP: TBitmap32;
    ImgBMP, MaskBMP: TBitmap;

    procedure Load(aName: String; aName2: String = '');
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, BMP32);
      if aName2 <> '' then
      begin
        TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName2, TempBMP);
        TempBMP.DrawMode := dmBlend;
        TempBMP.CombineMode := cmMerge;
        TempBMP.DrawTo(BMP32);
      end;
      TPngInterface.SplitBmp32(BMP32, ImgBMP, MaskBMP);
      tvLevelSelect.Images.Add(ImgBMP, MaskBMP);
    end;
  begin
    BMP32 := TBitmap32.Create;
    TempBMP := TBitmap32.Create;
    ImgBMP := TBitmap.Create;
    MaskBMP := TBitmap.Create;
    try
      Load('level_not_attempted.png');
      Load('level_attempted.png');
      Load('level_completed_outdated.png');
      Load('level_completed.png');

      Load('level_talisman.png', 'level_not_attempted.png');
      Load('level_talisman.png', 'level_attempted.png',);
      Load('level_talisman.png', 'level_completed_outdated.png');
      Load('level_talisman.png', 'level_completed.png');
    finally
      TempBMP.Free;
      BMP32.Free;
      ImgBMP.Free;
      MaskBMP.Free;
    end;
  end;
begin
  MakeImages;

  tvLevelSelect.Items.BeginUpdate;
  try
    tvLevelSelect.Items.Clear;
    AddGroup(GameParams.BaseLevelPack, nil);
  finally
    tvLevelSelect.Items.EndUpdate;
    tvLevelSelect.Update;
  end;
end;

procedure TFLevelSelect.LoadCurrentLevelToPlayer;
begin
  WriteToParams;

  if GameParams.MenuSounds then
    SoundManager.PlaySound(SFX_OK);

  ModalResult := mrOk;
end;

procedure TFLevelSelect.LoadIcons;
var
  IconsImg, aStyle, aStylePath, aPath: String;
begin
  IconsImg := 'levelinfo_icons.png';
  aStyle := GameParams.Level.Info.GraphicSetName;
  aStylePath := AppPath + SFStyles + aStyle + SFIcons;
  aPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

  if FileExists(aStylePath + IconsImg) then // Check styles folder first
    TPNGInterface.LoadPngFile(aStylePath + IconsImg, fIconBMP)
  else if FileExists(GameParams.CurrentLevel.Group.FindFile(IconsImg)) then // Then levelpack folder
    TPNGInterface.LoadPngFile(aPath + IconsImg, fIconBMP)
  else
    TPNGInterface.LoadPngFile(AppPath + SFGraphicsMenu + IconsImg, fIconBMP); // Then default
end;

procedure TFLevelSelect.MaybeReloadLevelInfo;
var
  NewVersion: Int64;
begin
  GameParams.LoadCurrentLevel;
  NewVersion := GameParams.Level.Info.LevelVersion;
  if (NewVersion <> fCurrentLevelVersion) then
  begin
    DisplayLevelInfo(True);
    fCurrentLevelVersion := NewVersion;
  end;
end;

procedure TFLevelSelect.WMActivate(var Msg: TWMActivate);
begin
  inherited;

  if fIsHandlingActivation then Exit; // Prevent overload

  fIsHandlingActivation := True;
  try
    if Msg.Active = WA_ACTIVE then
      MaybeReloadLevelInfo;
  finally
    fIsHandlingActivation := False;
  end;
end;

procedure TFLevelSelect.FormCreate(Sender: TObject);
begin
  fTalismanButtons := TObjectList<TSpeedButton>.Create;

  fIconBMP := TBitmap32.Create;
  LoadIcons;
  fIconBMP.DrawMode := dmBlend;
  fIconBMP.CombineMode := cmMerge;

  fInfoForm := TLevelInfoPanel.Create(Self, fIconBMP);
  fInfoForm.Parent := Self;
  fInfoForm.BoundsRect := pnLevelInfo.BoundsRect;
  fInfoForm.Visible := False;

  fPackTalBox := TScrollBox.Create(Self);
  fPackTalBox.Parent := Self;
  fPackTalBox.BoundsRect := pnLevelInfo.BoundsRect;
  fPackTalBox.VertScrollBar.Tracking := True;
  fPackTalBox.Visible := False;

  pnLevelInfo.Visible := False;

  btnResetTalismans.Enabled := False;
  btnOK.Enabled := False;

  SearchingLevels := False;

  InitializeTreeview;
  SetOptionButtons;
end;

procedure TFLevelSelect.FormShow(Sender: TObject);
begin
  LoadNodeLabels;
  SetInfo;
end;

function TFLevelSelect.GetCurrentlySelectedPack: String;
var
  G: TNeoLevelGroup;
  N: TTreeNode;
  Obj: TObject;
begin
  Result := '';

  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
    G := TNeoLevelGroup(Obj).ParentBasePack
  else if Obj is TNeoLevelEntry then
    G := TNeoLevelEntry(Obj).Group.ParentBasePack
  else
    Exit;

  Result := G.PackTitle;

  if Result = '' then
    Result := StringReplace(G.Name, '_', ' ', [rfReplaceAll]);
end;

procedure TFLevelSelect.FormDestroy(Sender: TObject);
begin
  fIconBMP.Free;

  fTalismanButtons.OwnsObjects := False; // Because TFLevelSelect itself will take care of any that remain
  fTalismanButtons.Free;

  GameParams.Save(scImportant);
end;

procedure TFLevelSelect.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Close;
  end;
end;

procedure TFLevelSelect.btnCleanseOneClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Title := 'Select file to save to';
    SaveDlg.Filter := 'NXLV Level Files|*.nxlv';
    SaveDlg.InitialDir := AppPath + SFLevels;
    SaveDlg.FileName := MakeSafeForFilename(GameParams.Level.Info.Title) + '.nxlv';
    SaveDlg.Options := [ofOverwritePrompt];
    if SaveDlg.Execute then
    begin
      GameParams.Level.Info.LevelVersion := GameParams.Level.Info.LevelVersion + 1;
      GameParams.Level.SaveToFile(SaveDlg.FileName);
      GameParams.Level.Info.LevelVersion := GameParams.Level.Info.LevelVersion - 1;
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TFLevelSelect.btnMakeShortcutClick(Sender: TObject);
var
  N: TTreeNode;
  Obj: TObject;
  G: TNeoLevelGroup absolute Obj;
  L: TNeoLevelEntry absolute Obj;

  TargetPath: String;
  Description: String;

  Dlg: TSaveDialog;

  // Source: delphiexamples.com/others/createlnk.html
  procedure CreateLink(const PathObj, PathLink, Desc, Param: string);
  var
    IObject: IUnknown;
    SLink: IShellLink;
    PFile: IPersistFile;
  begin
    IObject:=CreateComObject(CLSID_ShellLink);
    SLink:=IObject as IShellLink;
    PFile:=IObject as IPersistFile;
    with SLink do
    begin
      SetArguments(PChar(Param));
      SetDescription(PChar(Desc));
      SetPath(PChar(PathObj));
    end;
    PFile.Save(PWChar(WideString(PathLink)), FALSE);
  end;

  function MakeNameRecursive(aGroup: TNeoLevelGroup): String;
  begin
    if aGroup.Parent = nil then
      Result := ''
    else if aGroup.IsBasePack then
      Result := aGroup.Name
    else begin
      Result := MakeNameRecursive(aGroup.Parent);
      if (Result <> '') then Result := Result + ' :: ';
      Result := Result + aGroup.Name;
    end;
  end;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    TargetPath := G.Path;
    Description := SProgramName + ' - ' + MakeNameRecursive(G);
  end else if Obj is TNeoLevelEntry then
  begin
    TargetPath := L.Path;
    Description := SProgramName + ' - ' + MakeNameRecursive(L.Group) + ' :: ' + L.Title;
  end else
    Exit;

  if Pos(AppPath + SFLevels, TargetPath) = 1 then
    TargetPath := RightStr(TargetPath, Length(TargetPath) - Length(AppPath + SFLevels));


  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Title := 'Select location for shortcut';
    Dlg.Filter := 'Windows Shortcut (*.lnk)|*.lnk';
    Dlg.FilterIndex := 1;
    Dlg.DefaultExt := '.lnk';
    Dlg.Options := [ofOverwritePrompt, ofEnableSizing];
    if not Dlg.Execute then Exit;

    CreateLink(ParamStr(0), Dlg.FileName, Description, 'shortcut "' + TargetPath + '"');
  finally
    Dlg.Free;
  end;
end;

procedure TFLevelSelect.btnOKClick(Sender: TObject);
begin
  LoadCurrentLevelToPlayer;
end;

procedure TFLevelSelect.btnPlaybackModeClick(Sender: TObject);
var
  PlaybackModeForm: TFPlaybackMode;
  ReplayFiles: TStringDynArray;
  ReplayFile: string;
begin
  PlaybackModeForm := TFPlaybackMode.Create(nil);

  try
    // Populate the form with the currently selected pack
    PlaybackModeForm.CurrentlySelectedPack := GetCurrentlySelectedPack;
    PlaybackModeForm.UpdatePackNameText;

    if PlaybackModeForm.ShowModal = mrOk then
    begin
      if PlaybackModeForm.SelectedFolder = '' then
        Exit;

      // Get list of replay files
      ReplayFiles := TDirectory.GetFiles(PlaybackModeForm.SelectedFolder, '*.nxrp');

      // Add replay file names to ReplayVerifyList
      for ReplayFile in ReplayFiles do
        GameParams.ReplayVerifyList.Add(ReplayFile); // Storing full path for easier access later

      GameParams.PlaybackModeActive := True;
      GameParams.Save(scImportant);
      WriteToParams;
      ModalResult := mrRetry;
    end;
  finally
    PlaybackModeForm.Free;
  end;
end;

procedure TFLevelSelect.btnResetTalismansClick(Sender: TObject);
var
  Obj: TObject;
  L: TNeoLevelEntry absolute Obj;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // Safeguard

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then Exit;

  if MessageDlg('Are you sure you want to reset talismans for the level "' + L.Title + '"?',
                  mtCustom, [mbYes, mbNo], 0, mbNo) = mrYes then
  begin
    L.ResetTalismans;
    SetTalismanInfo;
  end;
end;

procedure TFLevelSelect.WriteToParams;
var
  Obj: TObject;
  G: TNeoLevelGroup absolute Obj;
  L: TNeoLevelEntry absolute Obj;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // Safeguard

  Obj := TObject(N.Data);

  fLoadAsPack := False;

  if Obj is TNeoLevelGroup then
  begin
    if G.Levels.Count = 0 then
    begin
      if G.LevelCount > 0 then
        fLoadAsPack := True
      else
        Exit;
    end;
    GameParams.SetGroup(G);
  end
  else if Obj is TNeoLevelEntry then
    GameParams.SetLevel(L);
end;

procedure TFLevelSelect.btnClearRecordsClick(Sender: TObject);
var
  Obj: TObject;
  G: TNeoLevelGroup absolute Obj;
  L: TNeoLevelEntry absolute Obj;
  N: TTreeNode;

  GroupWord: String;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // Safeguard

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    if G.IsBasePack then
      GroupWord := 'pack'
    else
      GroupWord := 'group';

    if MessageDlg('Are you sure you want to clear records for all levels in the ' + GroupWord + ' "' + G.Name + '"?',
                  mtCustom, [mbYes, mbNo], 0, mbNo) = mrYes then
      G.WipeAllRecords;
  end else begin
    if MessageDlg('Are you sure you want to clear records for the level "' + L.Title + '"?',
                  mtCustom, [mbYes, mbNo], 0, mbNo) = mrYes then
      L.WipeRecords;

    if fDisplayRecords <> rdNone then
      fInfoForm.PrepareEmbedRecords(fDisplayRecords);

    SetTalismanInfo;
  end;
end;

procedure TFLevelSelect.tvLevelSelectChange(Sender: TObject; Node: TTreeNode);
begin
  // Update the UI first
  Node.Selected := True;
  tvLevelSelect.Update;
  Application.ProcessMessages;

  SetInfo;
end;

procedure TFLevelSelect.tvLevelSelectExpanded(Sender: TObject; Node: TTreeNode);
begin
  // Update the UI first
  Node.Selected := True;
  tvLevelSelect.Update;
  Application.ProcessMessages;

  LoadNodeLabels;
  SetInfo;
end;

// When treeview is active, pressing return loads the currently selected level
procedure TFLevelSelect.tvLevelSelectKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    LoadCurrentLevelToPlayer;
end;

function TFLevelSelect.GetCompletedLevelString(G: TNeoLevelGroup): String;
var
  CompletedCount, ProcessedLevels: Integer;

  procedure ProcessGroup(Group: TNeoLevelGroup);
  var
    k, l: Integer;
    ChildGroup: TNeoLevelGroup;
  begin
    if (Group = nil) then Exit;

    // Process levels in the current group
    for k := 0 to Group.Levels.Count - 1 do
    begin
      if Group.Levels[k].Status = lst_Completed then
        Inc(CompletedCount);

      Inc(ProcessedLevels);

      pbUIProgress.Position := ProcessedLevels;  // Update progress

      // Ensure UI responsiveness every 50 levels
      if (ProcessedLevels mod 50 = 0) then
        Application.ProcessMessages;
    end;

    // Process subgroups (packs and other groups)
    for l := 0 to Group.Children.Count - 1 do
    begin
      ChildGroup := Group.Children[l];
      ProcessGroup(ChildGroup);  // Recursive call for subgroups
    end;
  end;

begin
  Result := '';
  CompletedCount := 0;
  ProcessedLevels := 0;

  // Set up the progress bar
  pbUIProgress.Visible := True;
  pbUIProgress.Position := 0;
  pbUIProgress.Max := G.LevelCount;

  // Process everything in one pass
  ProcessGroup(G);

  // Final result
  Result := Format('%d of %d levels ', [CompletedCount, G.LevelCount]);

  // Hide progress bar when done
  pbUIProgress.Visible := False;
end;

function TFLevelSelect.GetPackResultsString(G: TNeoLevelGroup): String;
begin
  Result := '';

  if G.LevelCount > 0 then
    Result := GetCompletedLevelString(G);

  if Result <> '' then
    Result := Result + 'completed';

  if G.Talismans.Count > 0 then
  begin
    if Result <> '' then
      Result := Result + '; ';

    Result := Result + IntToStr(G.TalismansUnlocked) + ' of ' + IntToStr(G.Talismans.Count) + ' talismans unlocked';
  end;
end;

procedure TFLevelSelect.LoadNodeLabels;
var
  i: Integer;
  L: TNeoLevelEntry;
  S: String;
  CurrentNode: Integer;
begin
  tvLevelSelect.Items.BeginUpdate;
  CurrentNode := 0;

  try
//    pbUIProgress.Visible := True;
//    pbUIProgress.Max := tvLevelSelect.Items.Count -1;

    for i := 0 to tvLevelSelect.Items.Count-1 do
    begin
      if not tvLevelSelect.Items[i].IsVisible then Continue;
      if tvLevelSelect.Items[i].Text <> '' then Continue;

      if TObject(tvLevelSelect.Items[i].Data) is TNeoLevelEntry then
      begin
        L := TNeoLevelEntry(tvLevelSelect.Items[i].Data);
        S := '';
        if L.Group.IsOrdered then
          S := '(' + IntToStr(L.GroupIndex + 1) + ') ';
        S := S + L.Title;
        tvLevelSelect.Items[i].Text := S;

        if (L.UnlockedTalismanList.Count < L.Talismans.Count)
          and (tvLevelSelect.Items[i].ImageIndex < 4) {just in case}
            and not SearchingLevels then
              with tvLevelSelect.Items[i] do
              begin
                ImageIndex := ImageIndex + 4;
                SelectedIndex := ImageIndex;
              end;
      end;

      // Update progress
      Inc(CurrentNode);
      //pbUIProgress.Position := CurrentNode;

      // Call every 50 nodes to ensure UI responsiveness
      if (CurrentNode mod 50 = 0) then
        Application.ProcessMessages;
    end;
  finally
    //pbUIProgress.Visible := False;
    tvLevelSelect.Items.EndUpdate;
  end;
end;

procedure TFLevelSelect.SetInfo;
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;

  function GetGroupPositionText: String;
  begin
    if (G = GameParams.BaseLevelPack) or (G.IsBasePack) or not (G.Parent.IsOrdered) then
      Result := ''
    else
      Result := 'Group ' + IntToStr(G.ParentGroupIndex + 1) + ' in ' + G.Parent.Name;
  end;

  function GetLevelPositionText: String;
  begin
    if not L.Group.IsOrdered then
      Result := ''
    else
      Result := 'Level ' + IntToStr(L.GroupIndex + 1) + ' of ' + L.Group.Name;
  end;
begin
  if SearchingLevels then
    Exit;

  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    Caption := 'SuperLemmix Level Select - Pack selected...';
    G := TNeoLevelGroup(Obj);
    lblName.Caption := G.Name;
    lblPosition.Caption := GetGroupPositionText;

    lblAuthor.Caption := G.Author;

    if G.PackVersion <> '' then
      lblAuthor.Caption := lblAuthor.Caption + ' | Version: ' + G.PackVersion;

    Caption := 'SuperLemmix Level Select - Loading level completion info...';
    lblCompletion.Caption := GetPackResultsString(G);
    lblCompletion.Visible := True;

    // Set the first unsolved level in the pack as the current level (or first level if pack is completed)
    Caption := 'SuperLemmix Level Select - Updating user settings...';
    WriteToParams;
    GameParams.LoadCurrentLevel(False);

    ClearTalismanButtons;
    fInfoForm.Visible := False;

    Caption := 'SuperLemmix Level Select - Gathering talisman completion info...';
    DisplayPackTalismanInfo(G);
    SetAdvancedOptionsGroup(G);
    Caption := 'SuperLemmix Level Select';
  end else if Obj is TNeoLevelEntry then
  begin
    L := TNeoLevelEntry(Obj);
    lblName.Caption := L.Title;
    lblPosition.Caption := GetLevelPositionText;

    if L.Author <> '' then
      lblAuthor.Caption := 'Author: ' + L.Author
    else
      lblAuthor.Caption := '';

    lblCompletion.Caption := '';
    lblCompletion.Visible := False;

    DisplayLevelInfo;
    fPackTalBox.Visible := False;

    SetAdvancedOptionsLevel(L);
    fCurrentLevelVersion := GameParams.Level.Info.LevelVersion;
  end;
end;

procedure TFLevelSelect.ShowOptionButtons;
begin
  { Resizes and recenters the main form to show the option buttons }

  Self.Width := btnClearRecords.Left + btnClearRecords.Width + 20;

  btnOK.Width := pnLevelInfo.Width - btnClose.Width;
  btnClose.Left := btnClearRecords.Left;

  btnShowHideOptions.Caption := '< Hide Options';

  Self.Left := (Application.MainForm.Left + (Application.MainForm.Width div 2)) - (Self.Width div 2);
  Self.Top := (Application.MainForm.Top + (Application.MainForm.Height div 2)) - (Self.Height div 2);
end;

procedure TFLevelSelect.HideOptionButtons;
begin
  { Resizes and recenters the main form to hide the option buttons }

  Self.Width := btnClearRecords.Left - 5;
  btnShowHideOptions.Caption := 'Show Options >';

  btnOK.Width := pnLevelInfo.Width - (btnClose.Width * 2) - 20;
  btnClose.Left := btnOK.Left + btnOK.Width + 10;

  Self.Left := (Application.MainForm.Left + (Application.MainForm.Width div 2)) - (Self.Width div 2);
  Self.Top := (Application.MainForm.Top + (Application.MainForm.Height div 2)) - (Self.Height div 2);
end;

procedure TFLevelSelect.SetOptionButtons;
begin
  if GameParams.ShowLevelSelectOptions then
  begin
    ShowOptionButtons;
  end else begin
    HideOptionButtons;
  end;
end;

procedure TFLevelSelect.DisplayLevelInfo(RefreshLevel: Boolean = False);
var
  LevelChanged: Boolean;
begin
  WriteToParams;
  GameParams.LoadCurrentLevel(False);

  LevelChanged := (GameParams.CurrentLevel.Path <> fLastLevelPath);
  fLastLevelPath := GameParams.CurrentLevel.Path;

  fInfoForm.Visible := True;
  fInfoForm.BoundsRect := pnLevelInfo.BoundsRect;
  fInfoForm.Level := GameParams.Level;
  fInfoForm.Talisman := nil;
  fDisplayRecords := rdNone;

  LoadIcons;
  fInfoForm.PrepareEmbed(LevelChanged or RefreshLevel);

  SetTalismanInfo;
end;

procedure TFLevelSelect.DisplayPackTalismanInfo(Group: TNeoLevelGroup);
var
  TotalTalismans, CurrentTalisman: Integer;
  Level: TNeoLevelEntry;
  Talismans: TObjectList<TTalisman>;
  Tal: TTalisman;
  i, TotalHeight: Integer;

  procedure CreateUIElements;
  var
    TitleLabel, LevLabel, ReqLabel: TLabel;
    NewButton: TSpeedButton;
    LabelStartY, LabelTotalHeight: Integer;
  begin
    if Trim(Tal.Title) <> '' then
    begin
      TitleLabel := TLabel.Create(Self);
      TitleLabel.Parent := fPackTalBox;
      TitleLabel.Font.Style := [fsBold];
      TitleLabel.Caption := Tal.Title;
    end
    else
      TitleLabel := nil;

    LevLabel := TLabel.Create(Self);
    LevLabel.Parent := fPackTalBox;
    LevLabel.Caption := Level.Group.Name + ' ' + IntToStr(Level.GroupIndex + 1) + ': ' + Level.Title;

    ReqLabel := TLabel.Create(Self);
    ReqLabel.Parent := fPackTalBox;
    ReqLabel.Caption := BreakString(Tal.RequirementText, ReqLabel, fPackTalBox.ClientWidth - 16 - 40);

    NewButton := TSpeedButton.Create(Self);
    NewButton.Parent := fPackTalBox;

    NewButton.Width := 32 + (SPEEDBUTTON_PADDING_SIZE * 2);
    NewButton.Height := 32 + (SPEEDBUTTON_PADDING_SIZE * 2);

    NewButton.Margins.Left := SPEEDBUTTON_PADDING_SIZE - 3;
    NewButton.Margins.Top := SPEEDBUTTON_PADDING_SIZE - 3;
    NewButton.Margins.Right := SPEEDBUTTON_PADDING_SIZE - 1;
    NewButton.Margins.Bottom := SPEEDBUTTON_PADDING_SIZE - 1;

    NewButton.Tag := NativeInt(Level);
    NewButton.OnClick := PackListTalButtonClick;

    if Level.TalismanStatus[Tal.ID] then
      DrawSpeedButton(NewButton, ICON_TALISMAN[Tal.Color])
    else
      DrawSpeedButton(NewButton, ICON_TALISMAN[Tal.Color] + ICON_TALISMAN_UNOBTAINED_OFFSET);

    if TitleLabel <> nil then
    begin
      TitleLabel.Left := 48;
      LevLabel.Left := 60;
    end
    else
      LevLabel.Left := 48;
    ReqLabel.Left := 48;
    NewButton.Left := 8 - SPEEDBUTTON_PADDING_SIZE;

    LabelTotalHeight := LevLabel.Height + ReqLabel.Height;
    if TitleLabel <> nil then
      LabelTotalHeight := LabelTotalHeight + TitleLabel.Height;

    if (NewButton.Height > LabelTotalHeight) then
    begin
      NewButton.Top := TotalHeight;
      LabelStartY := TotalHeight + ((NewButton.Height - LabelTotalHeight) div 2);

      TotalHeight := TotalHeight + NewButton.Height + 8;
    end
    else
    begin
      LabelStartY := TotalHeight;
      NewButton.Top := TotalHeight + ((LabelTotalHeight - NewButton.Height) div 2);

      TotalHeight := TotalHeight + LabelTotalHeight + 8;
    end;

    if TitleLabel <> nil then
    begin
      TitleLabel.Top := LabelStartY;
      LevLabel.Top := TitleLabel.Top + TitleLabel.Height;
    end
    else
      LevLabel.Top := LabelStartY;
    ReqLabel.Top := LevLabel.Top + LevLabel.Height;
  end;
begin
  fPackTalBox.VertScrollBar.Position := 0;

  if Group = fLastGroup then
  begin
    fPackTalBox.Visible := True;
    Exit;
  end;
  fLastGroup := Group;

  TotalHeight := 8;
  Talismans := Group.Talismans;
  TotalTalismans := Talismans.Count;
  CurrentTalisman := 0;

  pbUIProgress.Visible := True;
  pbUIProgress.Max := TotalTalismans;

  for i := fPackTalBox.ControlCount - 1 downto 0 do
    fPackTalBox.Controls[i].Free;

  for i := 0 to Talismans.Count - 1 do
  begin
    Tal := Talismans[i];
    Level := Group.GetLevelForTalisman(Tal);
    CreateUIElements;

    // Update progress
    Inc(CurrentTalisman);
    pbUIProgress.Position := CurrentTalisman;

    // Call every 50 talismans to ensure UI responsiveness
    if (CurrentTalisman mod 50 = 0) then
      Application.ProcessMessages;
  end;

  fPackTalBox.VertScrollBar.Position := 0;
  fPackTalBox.VertScrollBar.Range := Max(0, TotalHeight);
  fPackTalBox.Visible := True;

  pbUIProgress.Visible := False;
end;


procedure TFLevelSelect.SetTalismanInfo;
var
  i, n: Integer;

  procedure MakeButton(aTag: Integer);
  var
    NewButton: TSpeedButton;
  begin
    NewButton := TSpeedButton.Create(Self);
    NewButton.Parent := Self;

    NewButton.Left := lblCompletion.Left + (40 * n) - SPEEDBUTTON_PADDING_SIZE;
    NewButton.Top := lblCompletion.Top - SPEEDBUTTON_PADDING_SIZE;
    NewButton.Width := 32 + (SPEEDBUTTON_PADDING_SIZE * 2);
    NewButton.Height := 32 + (SPEEDBUTTON_PADDING_SIZE * 2);

    NewButton.Margins.Left := SPEEDBUTTON_PADDING_SIZE - 3;
    NewButton.Margins.Top := SPEEDBUTTON_PADDING_SIZE - 3;
    NewButton.Margins.Right := SPEEDBUTTON_PADDING_SIZE - 1;
    NewButton.Margins.Bottom := SPEEDBUTTON_PADDING_SIZE - 1;

    NewButton.Tag := aTag;
    NewButton.OnClick := TalButtonClick;

    fTalismanButtons.Add(NewButton);
    Inc(n);
  end;
begin
  ClearTalismanButtons;

  n := 0;

  if GameParams.CurrentLevel.Status in [lst_Completed_Outdated, lst_Completed] then
  begin
    MakeButton(-1);
    MakeButton(-2);

    if (GameParams.Level.Info.CollectibleCount > 0) then
      MakeButton(-3);
  end else if GameParams.CurrentLevel.WorldRecords.LemmingsRescued.Value > 0 then
    MakeButton(-2);

  for i := 0 to GameParams.Level.Talismans.Count-1 do
    MakeButton(i);

  DrawTalismanButtons;
end;

procedure TFLevelSelect.TalButtonClick(Sender: TObject);
var
  TalBtn: TSpeedButton absolute Sender;
  Tal: TTalisman;
  NewRecords: TRecordDisplay;
begin
  if TalBtn.Tag < 0 then
  begin
    NewRecords := rdWorld;
    if TalBtn.Tag = -1 then NewRecords := rdUser;
    if TalBtn.Tag = -3 then NewRecords := rdCollectibles;

    if fDisplayRecords = NewRecords then
      fDisplayRecords := rdNone
    else
      fDisplayRecords := NewRecords;
    fInfoForm.Talisman := nil;

    DrawTalismanButtons;

    if fDisplayRecords <> rdNone then
      fInfoForm.PrepareEmbedRecords(fDisplayRecords)
    else begin
      fInfoForm.Talisman := nil;
      fInfoForm.PrepareEmbed(False);
    end;
  end else begin
    Tal := GameParams.Level.Talismans[TalBtn.Tag];
    fDisplayRecords := rdNone;

    if fInfoForm.Talisman = Tal then
      fInfoForm.Talisman := nil
    else
      fInfoForm.Talisman := Tal;

    DrawTalismanButtons;
    fInfoForm.PrepareEmbed(False);
  end;
end;

procedure TFLevelSelect.PackListTalButtonClick(Sender: TObject);
var
  TalBtn: TSpeedButton absolute Sender;
  LevelRef: TNeoLevelEntry;
  NodeRef: TTreeNode;

  function RecursiveSearch(aBase: TTreeNode): TTreeNode;
  var
    i: Integer;
  begin
    if aBase.Data = LevelRef then
    begin
      Result := aBase;
      Exit;
    end;

    Result := nil;

    for i := 0 to aBase.Count-1 do
    begin
      Result := RecursiveSearch(aBase[i]);
      if Result <> nil then
        Exit;
    end;
  end;
begin
  LevelRef := TNeoLevelEntry(TalBtn.Tag);
  if not (LevelRef is TNeoLevelEntry) then
    raise Exception.Create('TFLevelSelect.PackListTalButtonClick received invalid input');

  NodeRef := RecursiveSearch(tvLevelSelect.Selected);

  if NodeRef = nil then
    raise Exception.Create('TFLevelSelect.PackListTalButtonClick couldn''t match the level.');

  tvLevelSelect.Select(NodeRef);
end;

procedure TFLevelSelect.ClearTalismanButtons;
begin
  fTalismanButtons.Clear;
end;

procedure TFLevelSelect.DrawIcon(aIconIndex: Integer; aDst: TBitmap32; aEraseColor: TColor);
var
  EraseColor32: TColor32;
begin
  EraseColor32 := ColorToRGB(aEraseColor);
  EraseColor32 := $FF000000 or
                  ((EraseColor32 and $00FF0000) shr 16) or
                  (EraseColor32 and $0000FF00) or
                  ((EraseColor32 and $000000FF) shl 16);

  aDst.SetSize(32, 32);
  aDst.Clear(EraseColor32);

  OverlayIcon(aIconIndex, aDst);
end;

procedure TFLevelSelect.OverlayIcon(aIconIndex: Integer; aDst: TBitmap32);
begin
  fIconBMP.DrawTo(aDst, 0, 0, SizedRect((aIconIndex mod 6) * 32, (aIconIndex div 6) * 32, 32, 32));
end;

procedure TFLevelSelect.DrawSpeedButton(aButton: TSpeedButton; aIconIndex,
  aOverlayIndex: Integer);
var
  BMP: TBitmap32;
begin
  BMP := TBitmap32.Create;
  try
    DrawIcon(aIconIndex, BMP, clBtnFace);
    if aOverlayIndex >= 0 then
      OverlayIcon(aOverlayIndex, BMP);

    aButton.Glyph.SetSize(1, 1); // This seems necessary in order for the glyph to actually re-draw.
    aButton.Glyph.Assign(BMP);
  finally
    BMP.Free;
  end;
end;

procedure TFLevelSelect.DrawTalismanButtons;
var
  i: Integer;
  TalIcon: Integer;
  Tal: TTalisman;
  RecordType: TRecordDisplay;
begin
  for i := 0 to fTalismanButtons.Count-1 do
  begin
    if fTalismanButtons[i].Tag < 0 then
    begin
      RecordType := rdWorld;

      if fTalismanButtons[i].Tag = -1 then
        RecordType := rdUser;
      if fTalismanButtons[i].Tag = -3 then
        RecordType := rdCollectibles;

      if RecordType = rdCollectibles then
      begin
        if GameParams.CurrentLevel.UserRecords.CollectiblesGathered.Value < GameParams.Level.Info.CollectibleCount then
        begin
          if fDisplayRecords = rdCollectibles then
            DrawSpeedButton(fTalismanButtons[i], ICON_COLLECTIBLE_UNOBTAINED, ICON_SELECTED_TALISMAN)
          else
            DrawSpeedButton(fTalismanButtons[i], ICON_COLLECTIBLE_UNOBTAINED);
        end else begin
          if fDisplayRecords = rdCollectibles then
            DrawSpeedButton(fTalismanButtons[i], ICON_COLLECTIBLE, ICON_SELECTED_TALISMAN)
          else
            DrawSpeedButton(fTalismanButtons[i], ICON_COLLECTIBLE);
        end;
      end else
      if RecordType = rdUser then
      begin
        if fDisplayRecords = rdUser then
          DrawSpeedButton(fTalismanButtons[i], ICON_RECORDS, ICON_SELECTED_TALISMAN)
        else
          DrawSpeedButton(fTalismanButtons[i], ICON_RECORDS);
      end else begin
        if fDisplayRecords = rdWorld then
          DrawSpeedButton(fTalismanButtons[i], ICON_WORLD_RECORDS, ICON_SELECTED_TALISMAN)
        else
          DrawSpeedButton(fTalismanButtons[i], ICON_WORLD_RECORDS);
      end;
    end else begin
      Tal := GameParams.Level.Talismans[fTalismanButtons[i].Tag];

      TalIcon := ICON_TALISMAN[Tal.Color];
      if not GameParams.CurrentLevel.TalismanStatus[Tal.ID] then
        TalIcon := TalIcon + ICON_TALISMAN_UNOBTAINED_OFFSET;

      if Tal = fInfoForm.Talisman then
        DrawSpeedButton(fTalismanButtons[i], TalIcon, ICON_SELECTED_TALISMAN)
      else
        DrawSpeedButton(fTalismanButtons[i], TalIcon);
    end;
  end;
end;

procedure TFLevelSelect.sbSearchLevelsInvokeSearch(Sender: TObject);
begin
  SearchLevels;
end;

procedure TFLevelSelect.sbSearchLevelsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    SearchLevels;
end;

procedure TFLevelSelect.SearchLevels;
  procedure CollapseAllNodes(TreeView: TTreeView; Node: TTreeNode);
  begin
    while Node <> nil do
    begin
      Node.Collapse(False);
      Node := Node.GetNextSibling;
    end;
  end;

  procedure ExpandAllNodes(TreeView: TTreeView; Node: TTreeNode; var Progress: Integer);
  var
    ChildNode: TTreeNode;
  begin
    while Node <> nil do
    begin
      Node.Expand(False);

      // Update progress bar for expansion
      Inc(Progress);
      pbSearchProgress.Position := Progress;

      // Keep the UI responsive
      if (Progress mod 100 = 0) then
        Application.ProcessMessages;

      if Node.HasChildren then
      begin
        ChildNode := Node.GetFirstChild;
        ExpandAllNodes(TreeView, ChildNode, Progress);
      end;

      Node := Node.GetNextSibling;
    end;
  end;

var
  SearchText: string;
  i: Integer;
  L: TNeoLevelEntry;
  Node: TTreeNode;
  Progress: Integer;
begin
  // Update flag & prevent infinite re-entry
  if SearchingLevels then
    Exit;

  SearchingLevels := True;

  // Initialize search results list
  lbSearchResults.Clear;
  SearchText := Trim(sbSearchLevels.Text);

  // Ensure valid search
  if SearchText = '' then
  begin
    SearchingLevels := False;
    Exit;
  end;

  // Update UI
  sbSearchLevels.Enabled := False;
  tvLevelSelect.Visible := False;
  lblSearchResultsInfo.Visible := False;
  lbSearchResults.Visible := False;
  lbSearchResults.Enabled := True;
  btnCloseSearch.Visible := False;

  // Initialize progress bar and counter
  pbSearchProgress.Position := 0;
  pbSearchProgress.Max := tvLevelSelect.Items.Count * 2;
  pbSearchProgress.Visible := True;

  Progress := 0;

  // Expand all nodes for searchability
  tvLevelSelect.Items.BeginUpdate;
  try
    ExpandAllNodes(tvLevelSelect, tvLevelSelect.Items.GetFirstNode, Progress); // Start expanding from the root
  finally
    tvLevelSelect.Items.EndUpdate;
  end;

  // Perform search and update progress bar
  tvLevelSelect.Items.BeginUpdate;
  try
    for i := 0 to tvLevelSelect.Items.Count - 1 do
    begin
      if TObject(tvLevelSelect.Items[i].Data) is TNeoLevelEntry then
      begin
        L := TNeoLevelEntry(tvLevelSelect.Items[i].Data);

        if AnsiContainsText(L.Title, SearchText) then
        begin
          Node := tvLevelSelect.Items[i];
          lbSearchResults.Items.AddObject(L.Title, Node);
        end;
      end;

      // Update progress bar during the search
      Inc(Progress);
      pbSearchProgress.Position := Progress;

      // Keep the UI responsive
      if (Progress mod 100 = 0) then
        Application.ProcessMessages;
    end;
  finally
    tvLevelSelect.Items.EndUpdate;
  end;

  // Collapse all nodes after search
  CollapseAllNodes(tvLevelSelect, tvLevelSelect.Items.GetFirstNode);

  // Handle no results found
  if (lbSearchResults.Items.Count <= 0) then
  begin
    lbSearchResults.Items.Add('No results found for "' + SearchText + '"');
    lbSearchResults.Enabled := False;
  end;

  // Update UI
  pbSearchProgress.Visible := False;
  sbSearchLevels.Enabled := True;
  lblSearchResultsInfo.Visible := True;
  lbSearchResults.Visible := True;
  btnCloseSearch.Visible := True;

  SearchingLevels := False;
end;

procedure TFLevelSelect.lbSearchResultsClick(Sender: TObject);
var
  TargetNode, CurrentNode, Node: TTreeNode;
  TreeFlow: array of TTreeNode;
  Count, i: Integer;
begin
  if lbSearchResults.ItemIndex = -1 then
    Exit;

  // Set the target node to the clicked search result
  TargetNode := TTreeNode(lbSearchResults.Items.Objects[lbSearchResults.ItemIndex]);

  if not Assigned(TargetNode) then
    Exit;

  SearchingLevels := True; // Prevent unnecessary UI loading

  // Build the treeflow from the target node up to the root
  Count := 0;
  CurrentNode := TargetNode;
  while Assigned(CurrentNode) do
  begin
    Inc(Count);
    SetLength(TreeFlow, Count);
    TreeFlow[Count - 1] := CurrentNode;
    CurrentNode := CurrentNode.Parent;
  end;

  // Reverse the treeflow so that TreeFlow[0] is now the top-most node
  for i := 0 to (Count div 2) - 1 do
  begin
    CurrentNode := TreeFlow[i];
    TreeFlow[i] := TreeFlow[Count - 1 - i];
    TreeFlow[Count - 1 - i] := CurrentNode;
  end;

  // For each node in the treeflow except the last (the target node),
  // expand it, and then collapse any node not in the treeflow
  for i := 0 to Count - 2 do
  begin
    if not TreeFlow[i].Expanded then
      TreeFlow[i].Expand(False);

    Node := TreeFlow[i].GetFirstChild;
    while Assigned(Node) do
    begin
      if Node <> TreeFlow[i+1] then
        Node.Collapse(False);
      Node := Node.GetNextSibling;
    end;
  end;

  SearchingLevels := False; // Let the UI load (labels, preview, etc)

  // Finally, select the chosen level
  tvLevelSelect.Selected := TargetNode;

  CloseSearchResultsPanel;
  tvLevelSelect.SetFocus;
end;

procedure TFLevelSelect.CloseSearchResultsPanel;
begin
  // Close and reset search panel
  lbSearchResults.Clear;
  lbSearchResults.Visible := False;
  btnCloseSearch.Visible := False;
  sbSearchLevels.Text := '';

  tvLevelSelect.Visible := True;
  lblSearchResultsInfo.Visible := False;
end;

procedure TFLevelSelect.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFLevelSelect.btnCloseSearchClick(Sender: TObject);
begin
  CloseSearchResultsPanel;
end;

procedure TFLevelSelect.btnEditLevelClick(Sender: TObject);
var
  LevelFile, EditorPath: string;
begin
  if GameParams.CurrentLevel = nil then
  begin
    ShowMessage('Please select a level file to edit.');
    Exit;
  end;

  // Set LevelFile and check it exists
  LevelFile := GameParams.CurrentLevel.Path;

  if not FileExists(LevelFile) then
  begin
    ShowMessage('The selected level file' + #13#10 + #13#10 +
                LevelFile + #13#10 + #13#10 +
                'does not exist.');
    Exit;
  end;

  // Set EditorPath and check it exists
  EditorPath := ExtractFilePath(Application.ExeName) + 'SLXEditor.exe';

  if not FileExists(EditorPath) then
  begin
    ShowMessage('SLXEditor.exe not found in the SuperLemmix directory.');
    Exit;
  end;

  // Add double quotes to handle spaces in LevelFile
  LevelFile := '"' + LevelFile + '"';

  // Launch SLX Editor with the selected level
  if ShellExecute(0, 'open', PChar(EditorPath), PChar(LevelFile), nil, SW_SHOWNORMAL) <= 32 then
  begin
    ShowMessage('Failed to launch the level editor.');
  end;

  fCurrentLevelVersion := GameParams.Level.Info.LevelVersion;
end;

// --- Advanced options --- //
procedure TFLevelSelect.SetAdvancedOptionsGroup(G: TNeoLevelGroup);
begin
  btnSaveImage.Caption := 'Save Level Images';
  btnReplayManager.Enabled := True;
  btnCleanseLevels.Enabled := True;
  btnCleanseOne.Enabled := False;
  btnResetTalismans.Enabled := False;
  btnOk.Enabled := G.LevelCount > 0; // N.B: Levels.Count is not recursive; LevelCount is
end;

procedure TFLevelSelect.SetAdvancedOptionsLevel(L: TNeoLevelEntry);
begin
  btnSaveImage.Caption := 'Save Image';
  btnReplayManager.Enabled := TNeoLevelEntry(tvLevelSelect.Selected.Data).Group.ParentBasePack <> GameParams.BaseLevelPack;
  btnCleanseLevels.Enabled := btnReplayManager.Enabled;
  btnCleanseOne.Enabled := True;
  btnResetTalismans.Enabled := L.Talismans.Count <> 0;
  btnOK.Enabled := True;
end;

procedure TFLevelSelect.btnSaveImageClick(Sender: TObject);
var
  N: TTreeNode;
  Obj: TObject;

  BasePack: TNeoLevelGroup;
  PathString: String;

  BMP: TBitmap32;
  SaveDlg: TSaveDialog;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    DumpImagesFallbackFlag := False;
    BasePack := TNeoLevelGroup(Obj).ParentBasePack;

    PathString := MakeSafeForFilename(BasePack.Name);

    BasePack.DumpImages(AppPath + 'Dump\' + PathString + '\');
    {$ifdef exp}
    BasePack.DumpSuperLemmixWebsiteMetaInfo(AppPath + 'Dump\' + PathString + '\');
    {$endif}

    if DumpImagesFallbackFlag then
      ShowMessage('Some styles used in this group appear to be missing. Use the Style Manager to download these. Level images with fallbacks saved to "Dump\' + PathString + '"')
    else
      ShowMessage('Level images saved to "Dump\' + PathString + '"');
  end else if Obj is TNeoLevelEntry then
  begin
    BMP := TBitmap32.Create;
    SaveDlg := TSaveDialog.Create(Self);
    try
      if GameParams.Level.HasAnyFallbacks then
        ShowMessage('Some styles used by this level appear to be missing. Use the Style Manager to download these.');
      SaveDlg.Options := [ofOverwritePrompt];
      SaveDlg.Filter := 'PNG File|*.png';
      SaveDlg.DefaultExt := '.png';
      if SaveDlg.Execute then
      begin
        GameParams.Renderer.RenderWorld(BMP, True);
        TPngInterface.SavePngFile(SaveDlg.FileName, BMP);
      end;
    finally
      BMP.Free;
    end;
  end else
    Exit;
end;

procedure TFLevelSelect.btnShowHideOptionsClick(Sender: TObject);
begin
  if GameParams.ShowLevelSelectOptions then
  begin
    HideOptionButtons;
    GameParams.ShowLevelSelectOptions := False;
  end else begin
    ShowOptionButtons;
    GameParams.ShowLevelSelectOptions := True;
  end;
end;

procedure TFLevelSelect.btnReplayManagerClick(Sender: TObject);
var
  ReplayManagerForm: TFReplayManager;
begin
  ReplayManagerForm := TFReplayManager.Create(nil);

  try
    // Populate the form with the currently selected pack
    ReplayManagerForm.CurrentlySelectedPack := GetCurrentlySelectedPack;
    ReplayManagerForm.UpdatePackNameText;

    if ReplayManagerForm.ShowModal = mrOk then
    begin
      WriteToParams;
      ModalResult := mrRetry;
    end;
  finally
    ReplayManagerForm.Free;
  end;
end;

procedure TFLevelSelect.btnCleanseLevelsClick(Sender: TObject);
var
  Group: TNeoLevelGroup;
  N: TTreeNode;
  Obj: TObject;
  AlreadyExistsMsg: String;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
    Group := TNeoLevelGroup(Obj)
  else if Obj is TNeoLevelEntry then
    Group := TNeoLevelEntry(Obj).Group
  else
    Exit;

  Group := Group.ParentBasePack;
  AlreadyExistsMsg := 'Folder "Cleanse\' + MakeSafeForFilename(Group.Name)
                    + '\" already exists. Continuing will erase it. Continue?';

  if SysUtils.DirectoryExists(AppPath + 'Cleanse\' + MakeSafeForFilename(Group.Name) + '\') then
    if MessageDlg(AlreadyExistsMsg, mtCustom, [mbYes, mbNo], 0) = mrNo then
      Exit;

  Group.CleanseLevels(AppPath + 'Cleanse\' + MakeSafeForFilename(Group.Name) + '\');
end;

end.
