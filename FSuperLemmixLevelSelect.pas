unit FSuperLemmixLevelSelect;

interface

uses
  GameControl,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  LemCore,
  LemTalisman,
  PngInterface,
  FLevelInfo,
  GR32, GR32_Resamplers, GR32_Layers,
  Generics.Collections,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Buttons,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList, StrUtils, UMisc, Math, UITypes,
  ActiveX, ShlObj, ComObj, // for the shortcut creation
  LemNeoParser, GR32_Image, System.ImageList;

type
  TFLevelSelect = class(TForm)
    tvLevelSelect: TTreeView;
    btnCancel: TButton;
    btnOK: TButton;
    lblName: TLabel;
    pnLevelInfo: TPanel;
    lblPosition: TLabel;
    lblAuthor: TLabel;
    ilStatuses: TImageList;
    lblCompletion: TLabel;
    btnMakeShortcut: TButton;
    lblAdvancedOptions: TLabel;
    btnSaveImage: TButton;
    btnMassReplay: TButton;
    btnCleanseLevels: TButton;
    btnCleanseOne: TButton;
    btnClearRecords: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvLevelSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnMakeShortcutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure btnMassReplayClick(Sender: TObject);
    procedure btnCleanseLevelsClick(Sender: TObject);
    procedure btnCleanseOneClick(Sender: TObject);
    procedure btnClearRecordsClick(Sender: TObject);
    procedure tvLevelSelectChange(Sender: TObject; Node: TTreeNode);
    procedure tvLevelSelectKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    fLastLevelPath: String;

    fLoadAsPack: Boolean;
    fInfoForm: TLevelInfoPanel;
    fIconBMP: TBitmap32;

    fPackTalBox: TScrollBox;

    fTalismanButtons: TObjectList<TSpeedButton>;
    fDisplayRecords: TRecordDisplay;

    procedure InitializeTreeview;
    procedure SetInfo;
    procedure WriteToParams;

    procedure DisplayLevelInfo;
    procedure SetTalismanInfo;
    procedure DrawTalismanButtons;
    procedure ClearTalismanButtons;
    procedure TalButtonClick(Sender: TObject);
    procedure PackListTalButtonClick(Sender: TObject);

    procedure DisplayPackTalismanInfo;

    procedure DrawSpeedButton(aButton: TSpeedButton; aIconIndex: Integer; aOverlayIndex: Integer = -1);

    procedure DrawIcon(aIconIndex: Integer; aDst: TBitmap32; aEraseColor: TColor);
    procedure OverlayIcon(aIconIndex: Integer; aDst: TBitmap32);

    procedure SetAdvancedOptionsGroup;
    procedure SetAdvancedOptionsLevel;
  public
    property LoadAsPack: Boolean read fLoadAsPack;
  end;

const // Icon indexes
  ICON_NORMAL_LEMMING = 0;
  ICON_ZOMBIE_LEMMING = 1;
  ICON_NEUTRAL_LEMMING = 2;

  ICON_SAVE_REQUIREMENT = 34;
  ICON_RELEASE_RATE = 4;
  ICON_RELEASE_RATE_LOCKED = 33;
  ICON_TIME_LIMIT = 5;

  ICON_SKILLS: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of Integer = (
    6, // Walker
    7, // Jumper
    8, // Shimmier
    38, // Slider
    9, // Climber
    10, // Swimmer
    11, // Floater
    12, // Glider
    13, // Disarmer
    42, // Timebomber
    14, // Bomber
    15, // Freezer
    16, // Blocker
    17, // Platformer
    18, // Builder
    19, // Stacker
    40, // Spearer
    41, // Grenader
    37, // Laserer
    20, // Basher
    21, // Fencer
    22, // Miner
    23, // Digger
    24  // Cloner
  );

  ICON_BRONZE_TALISMAN = 25;
  ICON_SILVER_TALISMAN = 26;
  ICON_GOLD_TALISMAN = 27;

  ICON_TALISMAN: array[tcBronze..tcGold] of Integer =
    ( ICON_BRONZE_TALISMAN, ICON_SILVER_TALISMAN, ICON_GOLD_TALISMAN );

  ICON_TALISMAN_UNOBTAINED_OFFSET = 3;

  ICON_SELECTED_TALISMAN = 31;

  ICON_MAX_SKILLS = 32;
  ICON_MAX_SKILL_TYPES = 3;

  ICON_KILL_ZOMBIES = 43;

  ICON_RECORDS = 35;
  ICON_WORLD_RECORDS = 39;
  ICON_TIMER = 36;

  ICON_BLANK = -1;

implementation

uses
  fReplayRename,
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
      Load('level_not_attempted.png');  // Load('level_attempted.png'); // We use the same image here!
      Load('level_completed_outdated.png');
      Load('level_completed.png');

      Load('level_not_attempted.png', 'level_talisman.png');
      Load('level_not_attempted.png', 'level_talisman.png'); // Load('level_attempted.png', 'level_talisman.png');
      Load('level_completed_outdated.png', 'level_talisman.png');
      Load('level_completed.png', 'level_talisman.png');
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

procedure TFLevelSelect.FormCreate(Sender: TObject);
begin
  fTalismanButtons := TObjectList<TSpeedButton>.Create;

  fIconBMP := TBitmap32.Create;
  TPNGInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'levelinfo_icons.png', fIconBMP);
  fIconBMP.DrawMode := dmBlend;

  fInfoForm := TLevelInfoPanel.Create(self, fIconBMP);
  fInfoForm.Parent := self;
  fInfoForm.BoundsRect := pnLevelInfo.BoundsRect;
  fInfoForm.Visible := false;

  fPackTalBox := TScrollBox.Create(self);
  fPackTalBox.Parent := self;
  fPackTalBox.BoundsRect := pnLevelInfo.BoundsRect;
  fPackTalBox.VertScrollBar.Tracking := true;
  fPackTalBox.Visible := false;

  pnLevelInfo.Visible := false;

  InitializeTreeview;
end;

procedure TFLevelSelect.FormShow(Sender: TObject);
begin
  SetInfo;
end;

procedure TFLevelSelect.FormDestroy(Sender: TObject);
begin
  fIconBMP.Free;

  fTalismanButtons.OwnsObjects := false; // because TFLevelSelect itself will take care of any that remain
  fTalismanButtons.Free;
end;

procedure TFLevelSelect.btnCleanseOneClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(self);
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

  // Source: http://delphiexamples.com/others/createlnk.html
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
    Description := 'SuperLemmix - ' + MakeNameRecursive(G);
  end else if Obj is TNeoLevelEntry then
  begin
    TargetPath := L.Path;
    Description := 'SuperLemmix - ' + MakeNameRecursive(L.Group) + ' :: ' + L.Title;
  end else
    Exit;

  if Pos(AppPath + SFLevels, TargetPath) = 1 then
    TargetPath := RightStr(TargetPath, Length(TargetPath) - Length(AppPath + SFLevels));


  Dlg := TSaveDialog.Create(self);
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
  WriteToParams;
  ModalResult := mrOk;
end;

procedure TFLevelSelect.WriteToParams;
var
  Obj: TObject;
  G: TNeoLevelGroup absolute Obj;
  L: TNeoLevelEntry absolute Obj;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // safeguard

  Obj := TObject(N.Data);

  fLoadAsPack := false;

  if Obj is TNeoLevelGroup then
  begin
    if G.Levels.Count = 0 then
    begin
      if G.LevelCount > 0 then
        fLoadAsPack := true
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
  if N = nil then Exit; // safeguard

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
  end;
end;

procedure TFLevelSelect.tvLevelSelectChange(Sender: TObject; Node: TTreeNode);
begin
  SetInfo;
end;

procedure TFLevelSelect.tvLevelSelectClick(Sender: TObject);
begin
  SetInfo;
end;

//when treeview is active, pressing return loads the currently selected level
procedure TFLevelSelect.tvLevelSelectKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  btnOK.Click;
end;

procedure TFLevelSelect.SetInfo;
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;
  i: Integer;
  S: String;
  CompletedCount: Integer;

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

  procedure LoadNodeLabels;
  var
    i: Integer;
    L: TNeoLevelEntry;
    S: String;
  begin
    tvLevelSelect.Items.BeginUpdate;
    try
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

          if (L.UnlockedTalismanList.Count < L.Talismans.Count) and (tvLevelSelect.Items[i].ImageIndex < 4 {just in case}) then
            with tvLevelSelect.Items[i] do
            begin
              ImageIndex := ImageIndex + 4;
              SelectedIndex := ImageIndex;
            end;
        end;
      end;
    finally
      tvLevelSelect.Items.EndUpdate;
    end;
  end;

begin
  LoadNodeLabels;

  N := tvLevelSelect.Selected;
  if N = nil then
  begin
    btnOk.Enabled := false;
    Exit;
  end;

  Obj := TObject(N.Data);

  if Obj is TNeoLevelGroup then
  begin
    G := TNeoLevelGroup(Obj);
    lblName.Caption := G.Name;
    lblPosition.Caption := GetGroupPositionText;

    lblAuthor.Caption := G.Author;

    if G.PackVersion <> '' then
      lblAuthor.Caption := lblAuthor.Caption + ' | Version: ' + G.PackVersion;

    S := '';
    CompletedCount := 0;
    if G.Children.Count > 0 then
    begin
      for i := 0 to G.Children.Count-1 do
        if G.Children[i].Status = lst_Completed then
          Inc(CompletedCount);
      S := S + IntToStr(CompletedCount) + ' of ' + IntToStr(G.Children.Count) + ' subgroups ';
    end;

    CompletedCount := 0;
    if G.Levels.Count > 0 then
    begin
      for i := 0 to G.Levels.Count-1 do
        if G.Levels[i].Status = lst_Completed then
          Inc(CompletedCount);
      if S <> '' then
        S := S + 'and ';
      S := S + IntToStr(CompletedCount) + ' of ' + IntToStr(G.Levels.Count) + ' levels ';
    end;

    if S <> '' then
      S := S + 'completed';

    if G.Talismans.Count > 0 then
    begin
      if S <> '' then
        S := S + '; ';

      S := S + IntToStr(G.TalismansUnlocked) + ' of ' + IntToStr(G.Talismans.Count) + ' talismans unlocked';
    end;

    lblCompletion.Caption := S;
    lblCompletion.Visible := true;

    DisplayPackTalismanInfo;

    fInfoForm.Visible := false;

    btnOk.Enabled := G.LevelCount > 0; // note: Levels.Count is not recursive; LevelCount is

    ClearTalismanButtons;
    SetAdvancedOptionsGroup;
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
    lblCompletion.Visible := false;

    DisplayLevelInfo;

    fPackTalBox.Visible := false;

    btnOk.Enabled := true;

    SetAdvancedOptionsLevel;
  end;
end;

procedure TFLevelSelect.DisplayLevelInfo;
var
  NeedRedraw: Boolean;
begin
  WriteToParams;
  GameParams.LoadCurrentLevel(false);

  NeedRedraw := (GameParams.CurrentLevel.Path <> fLastLevelPath);
  fLastLevelPath := GameParams.CurrentLevel.Path;

  fInfoForm.Visible := true;
  fInfoForm.BoundsRect := pnLevelInfo.BoundsRect; // Delphi 10.4 bugfix
  fInfoForm.Level := GameParams.Level;
  fInfoForm.Talisman := nil;
  fDisplayRecords := rdNone;

  fInfoForm.PrepareEmbed(NeedRedraw);

  SetTalismanInfo;
end;

procedure TFLevelSelect.DisplayPackTalismanInfo;
  function GetGroup: TNeoLevelGroup;
  var
    N: TTreeNode;
    Obj: TObject;
  begin
    Result := nil;

    N := tvLevelSelect.Selected;
    if N <> nil then
    begin
      Obj := TObject(N.Data);
      if Obj is TNeoLevelGroup then
        Result := TNeoLevelGroup(Obj);
    end;
  end;
var
  Group: TNeoLevelGroup;
  Level: TNeoLevelEntry;
  Talismans: TObjectList<TTalisman>;
  i: Integer;
  TotalHeight: Integer;

  NewButton: TSpeedButton;
  TitleLabel, LevLabel, ReqLabel: TLabel;
  Tal: TTalisman;

  LabelStartY: Integer;
  LabelTotalHeight: Integer;
begin
  fPackTalBox.VertScrollBar.Position := 0;

  Group := GetGroup;
  TotalHeight := 8;
  Talismans := Group.Talismans;

  for i := fPackTalBox.ControlCount-1 downto 0 do
    fPackTalBox.Controls[i].Free;

  for i := 0 to Talismans.Count-1 do
  begin
    Tal := Talismans[i];
    Level := Group.GetLevelForTalisman(Tal);

    if Trim(Tal.Title) <> '' then
    begin
      TitleLabel := TLabel.Create(self);
      TitleLabel.Parent := fPackTalBox;
      TitleLabel.Font.Style := [fsBold];
      TitleLabel.Caption := Tal.Title;
    end else
      TitleLabel := nil;

    LevLabel := TLabel.Create(self);
    LevLabel.Parent := fPackTalBox;
    LevLabel.Caption := Level.Group.Name + ' ' + IntToStr(Level.GroupIndex + 1) + ': ' + Level.Title;

    ReqLabel := TLabel.Create(self);
    ReqLabel.Parent := fPackTalBox;
    ReqLabel.Caption := BreakString(Tal.RequirementText, ReqLabel, fPackTalBox.ClientWidth - 16 - 40);

    NewButton := TSpeedButton.Create(self);
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
    end else
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
    end else begin
      LabelStartY := TotalHeight;
      NewButton.Top := TotalHeight + ((LabelTotalHeight - NewButton.Height) div 2);

      TotalHeight := TotalHeight + LabelTotalHeight + 8;
    end;

    if TitleLabel <> nil then
    begin
      TitleLabel.Top := LabelStartY;
      LevLabel.Top := TitleLabel.Top + TitleLabel.Height;
    end else
      LevLabel.Top := LabelStartY;
    ReqLabel.Top := LevLabel.Top + LevLabel.Height;
  end;

  fPackTalBox.VertScrollBar.Position := 0;
  fPackTalBox.VertScrollBar.Range := Max(0, TotalHeight);
  fPackTalBox.Visible := true;
end;

procedure TFLevelSelect.SetTalismanInfo;
var
  i, n: Integer;

  procedure MakeButton(aTag: Integer);
  var
    NewButton: TSpeedButton;
  begin
    NewButton := TSpeedButton.Create(self);
    NewButton.Parent := self;

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
      fInfoForm.PrepareEmbed(false);
    end;
  end else begin
    Tal := GameParams.Level.Talismans[TalBtn.Tag];
    fDisplayRecords := rdNone;

    if fInfoForm.Talisman = Tal then
      fInfoForm.Talisman := nil
    else
      fInfoForm.Talisman := Tal;

    DrawTalismanButtons;
    fInfoForm.PrepareEmbed(false);
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
  tvLevelSelectClick(tvLevelSelect);
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
  fIconBMP.DrawTo(aDst, 0, 0, SizedRect((aIconIndex mod 4) * 32, (aIconIndex div 4) * 32, 32, 32));
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

//////////////////////
// Advanced options //
//////////////////////

procedure TFLevelSelect.SetAdvancedOptionsGroup;
begin
    btnSaveImage.Caption := 'Save Level Images';
    btnMassReplay.Enabled := true;
    btnCleanseLevels.Enabled := true;
    btnCleanseOne.Enabled := false;
end;

procedure TFLevelSelect.SetAdvancedOptionsLevel;
begin
    btnSaveImage.Caption := 'Save Image';
    btnMassReplay.Enabled := TNeoLevelEntry(tvLevelSelect.Selected.Data).Group.ParentBasePack <> GameParams.BaseLevelPack;
    btnCleanseLevels.Enabled := btnMassReplay.Enabled;
    btnCleanseOne.Enabled := true;
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
    DumpImagesFallbackFlag := false;
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
    SaveDlg := TSaveDialog.Create(self);
    try
      if GameParams.Level.HasAnyFallbacks then
        ShowMessage('Some styles used by this level appear to be missing. Use the Style Manager to download these.');
      SaveDlg.Options := [ofOverwritePrompt];
      SaveDlg.Filter := 'PNG File|*.png';
      SaveDlg.DefaultExt := '.png';
      if SaveDlg.Execute then
      begin
        GameParams.Renderer.RenderWorld(BMP, true);
        TPngInterface.SavePngFile(SaveDlg.FileName, BMP);
      end;
    finally
      BMP.Free;
    end;
  end else
    Exit;
end;

procedure TFLevelSelect.btnMassReplayClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  F: TFReplayNaming;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select any file in the folder containing replays';
    OpenDlg.InitialDir := AppPath + 'Replay\' + MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name, false);
    OpenDlg.Filter := 'SuperLemmix Replay (*.nxrp)|*.nxrp';
    OpenDlg.Options := [ofHideReadOnly, ofFileMustExist, ofEnableSizing];
    if not OpenDlg.Execute then
      Exit;
    GameParams.ReplayCheckPath := ExtractFilePath(OpenDlg.FileName);
  finally
    OpenDlg.Free;
  end;

  F := TFReplayNaming.Create(self);
  try
    if F.ShowModal = mrCancel then
      Exit;
  finally
    F.Free;
  end;

  WriteToParams;
  ModalResult := mrRetry;
end;

procedure TFLevelSelect.btnCleanseLevelsClick(Sender: TObject);
var
  Group: TNeoLevelGroup;
  N: TTreeNode;
  Obj: TObject;
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

  if DirectoryExists(AppPath + 'Cleanse\' + MakeSafeForFilename(Group.Name) + '\') then
    if MessageDlg('Folder "Cleanse\' + MakeSafeForFilename(Group.Name) + '\" already exists. Continuing will erase it. Continue?',
                  mtCustom, [mbYes, mbNo], 0) = mrNo then
      Exit;

  Group.CleanseLevels(AppPath + 'Cleanse\' + MakeSafeForFilename(Group.Name) + '\');
end;

end.
