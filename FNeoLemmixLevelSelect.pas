unit FNeoLemmixLevelSelect;

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
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList, StrUtils, UMisc, Math,
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
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvLevelSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnMakeShortcutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fLoadAsPack: Boolean;
    fInfoForm: TLevelInfoPanel;
    fIconBMP: TBitmap32;

    fPackTalBox: TScrollBox;

    fTalismanButtons: TObjectList<TImage32>;

    procedure InitializeTreeview;
    procedure SetInfo;
    procedure WriteToParams;

    procedure DisplayLevelInfo;
    procedure SetTalismanInfo;
    procedure DrawTalismanButtons;
    procedure ClearTalismanButtons;
    procedure TalButtonClick(Sender: TObject);

    procedure DisplayPackTalismanInfo;

    procedure DrawIcon(aIconIndex: Integer; aDst: TBitmap32; aErase: Boolean = true);
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

  ICON_SKILLS: array[spbWalker..spbCloner] of Integer = (
    6, // Walker
    7, // Jumper
    8, // Shimmier
    9, // Climber
    10, // Swimmer
    11, // Floater
    12, // Glider
    13, // Disarmer
    14, // Bomber
    15, // Stoner
    16, // Blocker
    17, // Platformer
    18, // Builder
    19, // Stacker
    20, // Basher
    21, // Fencer
    22, // Miner
    23, // Digger
    24 // Cloner
  );

  ICON_TALISMAN: array[tcBronze..tcGold] of Integer =
    ( 25, 26, 27 );

  ICON_TALISMAN_UNOBTAINED_OFFSET = 3;

  ICON_SELECTED_TALISMAN = 31;

  ICON_MAX_SKILLS = 32;

  ICON_BLANK = 3;

implementation

uses
  LemLevel;

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
  fTalismanButtons := TObjectList<TImage32>.Create;

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

procedure TFLevelSelect.FormDestroy(Sender: TObject);
begin
  fIconBMP.Free;

  fTalismanButtons.OwnsObjects := false; // because TFLevelSelect itself will take care of any that remain
  fTalismanButtons.Free;
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
    Description := 'NeoLemmix - ' + MakeNameRecursive(G);
  end else if Obj is TNeoLevelEntry then
  begin
    TargetPath := L.Path;
    Description := 'NeoLemmix - ' + MakeNameRecursive(L.Group) + ' :: ' + L.Title;
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

procedure TFLevelSelect.tvLevelSelectClick(Sender: TObject);
begin
  SetInfo;
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
  end else if Obj is TNeoLevelEntry then
  begin
    L := TNeoLevelEntry(Obj);
    lblName.Caption := L.Title;
    lblPosition.Caption := GetLevelPositionText;

    if L.Author <> '' then
      lblAuthor.Caption := 'By ' + L.Author
    else
      lblAuthor.Caption := '';

    lblCompletion.Caption := '';
    lblCompletion.Visible := false;

    DisplayLevelInfo;

    fPackTalBox.Visible := false;

    btnOk.Enabled := true;
  end;
end;

procedure TFLevelSelect.FormShow(Sender: TObject);
begin
  SetInfo;
end;

procedure TFLevelSelect.DisplayLevelInfo;
begin
  WriteToParams;
  GameParams.LoadCurrentLevel(false);

  fInfoForm.Visible := true;
  fInfoForm.Level := GameParams.Level;
  fInfoForm.Talisman := nil;

  fInfoForm.PrepareEmbed;

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

  function BreakString(S: String; aLabel: TLabel; aMaxWidth: Integer): String;
  var
    PrevResult: String;
    SL: TStringList;
    n: Integer;
  begin
    PrevResult := '';
    Result := '';

    SL := TStringList.Create;
    try
      SL.Delimiter := ' ';
      SL.StrictDelimiter := true;

      SL.DelimitedText := S;

      n := 0;
      while n < SL.Count do
      begin
        if n > 0 then
          Result := Result + ' ';
        Result := Result + SL[n];

        if aLabel.Canvas.TextWidth(Result) > aMaxWidth then
          Result := PrevResult + #13 + SL[n];

        PrevResult := Result;

        Inc(n);
      end;
    finally
      SL.Free;
    end;
  end;
var
  Group: TNeoLevelGroup;
  Level: TNeoLevelEntry;
  Talismans: TObjectList<TTalisman>;
  i: Integer;
  TotalHeight: Integer;

  NewImage: TImage32;
  TitleLabel, LevLabel, ReqLabel: TLabel;
  Tal: TTalisman;
begin
  Group := GetGroup;
  TotalHeight := 8;
  Talismans := Group.Talismans;

  for i := fPackTalBox.ControlCount-1 downto 0 do
    fPackTalBox.Controls[i].Free;

  for i := 0 to Talismans.Count-1 do
  begin
    Tal := Talismans[i];
    Level := Group.GetLevelForTalisman(Tal);

    TitleLabel := TLabel.Create(self);
    TitleLabel.Parent := fPackTalBox;
    TitleLabel.Font.Style := [fsBold];
    TitleLabel.Caption := Tal.Title;

    LevLabel := TLabel.Create(self);
    LevLabel.Parent := fPackTalBox;
    LevLabel.Caption := Level.Group.Name + ' ' + IntToStr(Level.GroupIndex + 1) + ': ' + Level.Title;

    ReqLabel := TLabel.Create(self);
    ReqLabel.Parent := fPackTalBox;
    ReqLabel.Caption := BreakString(Tal.RequirementText, ReqLabel, fPackTalBox.ClientWidth - 16 - 40);

    NewImage := TImage32.Create(self);
    NewImage.Parent := fPackTalBox;
    NewImage.Width := 32;
    NewImage.Height := 32;

    if Level.TalismanStatus[Tal.ID] then
      DrawIcon(ICON_TALISMAN[Tal.Color], NewImage.Bitmap)
    else
      DrawIcon(ICON_TALISMAN[Tal.Color] + ICON_TALISMAN_UNOBTAINED_OFFSET, NewImage.Bitmap);

    TitleLabel.Left := 40;
    LevLabel.Left := 52;
    ReqLabel.Left := 40;
    NewImage.Left := 8;

    if (NewImage.Height > TitleLabel.Height + LevLabel.Height + ReqLabel.Height) then
    begin
      NewImage.Top := TotalHeight;
      TitleLabel.Top := TotalHeight + ((NewImage.Height - (TitleLabel.Height + LevLabel.Height + ReqLabel.Height)) div 2);

      TotalHeight := TotalHeight + NewImage.Height + 8;
    end else begin
      TitleLabel.Top := TotalHeight;
      NewImage.Top := TotalHeight + (((TitleLabel.Height + LevLabel.Height + ReqLabel.Height) - NewImage.Height) div 2);

      TotalHeight := TotalHeight + TitleLabel.Height + LevLabel.Height + ReqLabel.Height + 8;
    end;

    LevLabel.Top := TitleLabel.Top + TitleLabel.Height;
    ReqLabel.Top := LevLabel.Top + LevLabel.Height;
  end;

  fPackTalBox.VertScrollBar.Position := 0;
  fPackTalBox.VertScrollBar.Range := Max(0, TotalHeight);
  fPackTalBox.Visible := true;
end;

procedure TFLevelSelect.SetTalismanInfo;
var
  i: Integer;
  NewImage: TImage32;
begin
  ClearTalismanButtons;

  for i := 0 to GameParams.Level.Talismans.Count-1 do
  begin
    NewImage := TImage32.Create(self);
    NewImage.Parent := self;
    NewImage.Left := lblCompletion.Left + (40 * i);
    NewImage.Top := lblCompletion.Top;
    NewImage.Width := 32;
    NewImage.Height := 32;
    NewImage.Color := $F0F0F0;
    NewImage.Tag := i;
    NewImage.OnClick := TalButtonClick;

    fTalismanButtons.Add(NewImage);
  end;

  DrawTalismanButtons;
end;

procedure TFLevelSelect.TalButtonClick(Sender: TObject);
var
  TalBtn: TImage32 absolute Sender;
  Tal: TTalisman;
begin
  Tal := GameParams.Level.Talismans[TalBtn.Tag];

  if fInfoForm.Talisman = Tal then
    fInfoForm.Talisman := nil
  else
    fInfoForm.Talisman := Tal;

  DrawTalismanButtons;
  fInfoForm.PrepareEmbed;
end;

procedure TFLevelSelect.ClearTalismanButtons;
begin
  fTalismanButtons.Clear;
end;

procedure TFLevelSelect.DrawIcon(aIconIndex: Integer; aDst: TBitmap32; aErase: Boolean = true);
begin
  if aErase then
  begin
    aDst.SetSize(32, 32);
    aDst.Clear($FFF0F0F0);
  end;

  fIconBMP.DrawTo(aDst, 0, 0, SizedRect((aIconIndex mod 4) * 32, (aIconIndex div 4) * 32, 32, 32));
end;

procedure TFLevelSelect.DrawTalismanButtons;
var
  i: Integer;
  TalIcon: Integer;
  Tal: TTalisman;
begin
  for i := 0 to GameParams.Level.Talismans.Count-1 do
  begin
    Tal := GameParams.Level.Talismans[i];

    TalIcon := ICON_TALISMAN[Tal.Color];
    if not GameParams.CurrentLevel.TalismanStatus[Tal.ID] then
      TalIcon := TalIcon + ICON_TALISMAN_UNOBTAINED_OFFSET;

    DrawIcon(TalIcon, fTalismanButtons[i].Bitmap);

    if Tal = fInfoForm.Talisman then
      DrawIcon(ICON_SELECTED_TALISMAN, fTalismanButtons[i].Bitmap, false);
  end;
end;

end.
