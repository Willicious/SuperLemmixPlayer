unit FNeoLemmixLevelSelect;

interface

uses
  GameControl,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  PngInterface,
  GR32, GR32_Resamplers,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList,
  LemNeoParser, GR32_Image;

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
    btnAddContent: TButton;
    lblCompletion: TLabel;
    imgLevel: TImage32;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvLevelSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAddContentClick(Sender: TObject);
  private
    fLoadAsPack: Boolean;
    procedure InitializeTreeview;
    procedure SetInfo;
    procedure WriteToParams;
    procedure DisplayLevelInfo;
  public
    property LoadAsPack: Boolean read fLoadAsPack;
  end;

implementation

uses
  LemLevel, LemDosCmp; // used to import DAT level packs

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
  InitializeTreeview;
  TLinearResampler.Create(imgLevel.Bitmap);
end;

procedure TFLevelSelect.btnOKClick(Sender: TObject);
begin
  WriteToParams;
  ModalResult := mrOk;
end;

procedure TFLevelSelect.WriteToParams;
var
  Obj: TObject;
  G: TNeoLevelGroup;
  L: TNeoLevelEntry;
  N: TTreeNode;
begin
  N := tvLevelSelect.Selected;
  if N = nil then Exit; // safeguard

  Obj := TObject(N.Data);

  fLoadAsPack := false;

  if Obj is TNeoLevelGroup then
  begin
    G := TNeoLevelGroup(Obj);
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
  begin
    L := TNeoLevelEntry(Obj);
    GameParams.SetLevel(L);
  end;
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

    pnLevelInfo.Visible := false;

    btnOk.Enabled := G.LevelCount > 0; // note: Levels.Count is not recursive; LevelCount is
  end else if Obj is TNeoLevelEntry then
  begin
    L := TNeoLevelEntry(Obj);
    lblName.Caption := L.Title;
    lblPosition.Caption := GetLevelPositionText;

    if L.Author <> '' then
      lblAuthor.Caption := 'By ' + L.Author
    else
      lblAuthor.Caption := '';

    if L.Talismans.Count = 0 then
      lblCompletion.Caption := ''
    else
      lblCompletion.Caption := IntToStr(L.UnlockedTalismanList.Count) + ' of ' + IntToStr(L.Talismans.Count) + ' talismans unlocked';

    pnLevelInfo.Visible := true;

    DisplayLevelInfo;

    btnOk.Enabled := true;
  end;
end;

procedure TFLevelSelect.FormShow(Sender: TObject);
begin
  SetInfo;
end;

procedure TFLevelSelect.btnAddContentClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  Ext: String;

  procedure Import(aFile: String);
  var
    Level: TLevel;
    DstFile: String;
  begin
    Level := TLevel.Create;
    try
      Level.LoadFromFile(aFile);
      DstFile := AppPath + SFLevels + MakeSafeForFilename(Level.Info.Title) + '.nxlv';
      Level.SaveToFile(DstFile);
      GameParams.BaseLevelPack.Levels.Add.Filename := ExtractFileName(DstFile);
    finally
      Level.Free;
    end;
  end;

  procedure LoadDatFile(aFile: String);
  var
    DatFile, LvlFile: TMemoryStream;
    n: Integer;
    Success, AlreadyExists: Boolean;
    Level: TLevel;
    Parser: TParser;
    MainSec: TParserSection;
    DstPath: String;
  begin
    DatFile := TMemoryStream.Create;
    LvlFile := TMemoryStream.Create;
    Level := TLevel.Create;
    Parser := TParser.Create;
    try
      MainSec := Parser.MainSection;
      MainSec.AddLine('base');

      Success := false;
      DatFile.LoadFromFile(aFile);
      DstPath := AppPath + SFLevels + ExtractFileName(aFile) + '\';
      if DirectoryExists(DstPath) then
        AlreadyExists := true
      else begin
        ForceDirectories(DstPath);
        AlreadyExists := false;
      end;
      SetCurrentDir(DstPath);
      n := -1;
      while DatFile.Position < DatFile.Size do
      begin
        LvlFile.Clear;
        try
          Inc(n);
          DecompressDat(DatFile, LvlFile);
          LvlFile.Position := 0;
          Level.LoadFromStream(LvlFile);
          Level.SaveToFile(DstPath + MakeSafeForFilename(Level.Info.Title) + '.nxlv');
          MainSec.AddLine('level', MakeSafeForFilename(Level.Info.Title) + '.nxlv');
          Success := true;
        except
          ShowMessage('Section ' + IntToStr(n) + ' of this DAT file is not a valid level, or you are missing required style files.');
        end;
      end;

      if Success then
      begin
        Parser.SaveToFile(DstPath + 'levels.nxmi');
        GameParams.BaseLevelPack.Children.Add(ExtractFileName(aFile) + '\');
      end else if not AlreadyExists then
        RemoveDir(DstPath);
    finally
      Level.Free;
      DatFile.Free;
      LvlFile.Free;
      Parser.Free;
    end;
  end;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select pack or level file';
    OpenDlg.Filter := 'All supported files|*.nxlv;*.lvl;*.ini;*.lev;*.dat|NeoLemmix Levels (*.nxlv)|*.nxlv|Lemmix or Old NeoLemmix Levels (*.lvl)|*.lvl|Lemmini or SuperLemmini Levels (*.ini)|*.ini|Lemmins Levels|*.lev';
    OpenDlg.Options := [ofHideReadOnly, ofFileMustExist];
    OpenDlg.InitialDir := AppPath;
    if not OpenDlg.Execute then Exit;

    try
      Ext := Lowercase(ExtractFileExt(OpenDlg.FileName));
      if (Ext = '.nxlv') then
        GameParams.BaseLevelPack.Levels.Add.Filename := OpenDlg.Filename
      else if (Ext = '.dat') then
        LoadDatFile(OpenDlg.Filename)
      else
        Import(OpenDlg.FileName);
    except
      ShowMessage('The selected file could not be imported.');
    end;

    InitializeTreeview;
    SetInfo;
  finally
    OpenDlg.Free;
  end;
end;

procedure TFLevelSelect.DisplayLevelInfo;
begin
  WriteToParams;
  GameParams.LoadCurrentLevel(false);
  imgLevel.Bitmap.BeginUpdate;
  try
    GameParams.Renderer.RenderWorld(imgLevel.Bitmap, true);
  finally
    imgLevel.Bitmap.EndUpdate;
    imgLevel.Bitmap.Changed;
  end;
end;

end.
