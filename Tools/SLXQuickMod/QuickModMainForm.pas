unit QuickModMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.UITypes, StrUtils,
  Vcl.ExtCtrls, Vcl.Samples.Spin;

const
  SKILL_COUNT = 27;
  SKILLS: array[0..SKILL_COUNT-1] of String =
   ('Walker', 'Jumper', 'Shimmier', 'Ballooner',
    'Slider', 'Climber', 'Swimmer', 'Floater', 'Glider', 'Disarmer',
    'Timebomber', 'Bomber', 'Freezer', 'Stoner', 'Blocker',
    'Ladderer', 'Platformer', 'Builder', 'Stacker',
    'Spearer', 'Grenader', 'Laserer', 'Basher',
    'Fencer', 'Miner', 'Digger', 'Cloner');

type
  TSkillInputComponents = record
    SILabel: TLabel;
    SIEdit: TEdit;
  end;

  TSkillInputs = array[0..SKILL_COUNT-1] of TSkillInputComponents;

  TFQuickmodMain = class(TForm)
    lblPack: TLabel;
    cbPack: TComboBox;
    gbStats: TGroupBox;
    cbLemCount: TCheckBox;
    ebLemCount: TEdit;
    cbSaveRequirement: TCheckBox;
    ebSaveRequirement: TEdit;
    cbReleaseRate: TCheckBox;
    ebReleaseRate: TEdit;
    cbLockRR: TCheckBox;
    cbUnlockRR: TCheckBox;
    cbTimeLimit: TCheckBox;
    ebTimeLimit: TEdit;
    gbCustomSkillset: TGroupBox;
    btnApply: TButton;
    cbCustomSkillset: TCheckBox;
    cbRemoveTalismans: TCheckBox;
    cbChangeID: TCheckBox;
    cbRemoveSpecialLemmings: TCheckBox;
    cbRemovePreplaced: TCheckBox;
    gbSuperlemming: TGroupBox;
    cbActivateSuperlemming: TCheckBox;
    cbDeactivateSuperlemming: TCheckBox;
    gbTalismans: TGroupBox;
    cbAddKillZombiesTalisman: TCheckBox;
    cbAddClassicModeTalisman: TCheckBox;
    gbReleaseRate: TGroupBox;
    cbAddSaveAllTalisman: TCheckBox;
    cbChangeAuthor: TCheckBox;
    ebAuthor: TEdit;
    gbSkillConversions: TGroupBox;
    cbTimebomberToBomber: TCheckBox;
    cbBomberToTimebomber: TCheckBox;
    cbStonerToFreezer: TCheckBox;
    cbFreezerToStoner: TCheckBox;
    gbCrossPlatformConversions: TGroupBox;
    cbSwapStyles: TCheckBox;
    rbNeoToSuper: TRadioButton;
    rbSuperToNeo: TRadioButton;
    lblConversionInfo: TLabel;
    gbSkills: TGroupBox;
    cbSetAllSkillCounts: TCheckBox;
    seSkillCounts: TSpinEdit;
    cbCorrectWaterAndExits: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure cbStatCheckboxClicked(Sender: TObject);
    procedure cbCustomSkillsetClick(Sender: TObject);
    procedure cbLockRRClick(Sender: TObject);
    procedure cbTimebomberChangeClick(Sender: TObject);
    procedure cbSuperlemmingClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure cbSwapStylesClick(Sender: TObject);
    procedure cbFreezerChangeClick(Sender: TObject);
    procedure cbSetAllSkillCountsClick(Sender: TObject);
    procedure seSkillCountsChange(Sender: TObject);
    procedure seSkillCountsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClick(Sender: TObject);
    procedure gbSkillsClick(Sender: TObject);
  private
    AppPath: String;

    fSkillInputs: TSkillInputs;
    fPackList: TStringList;
    fProcessCompletedSuccessfully: Boolean;

    procedure BuildPackList;
    procedure LoadPackInfo(aPackFolder: String);
    procedure CreateSkillInputs;

    procedure ApplyChanges;
    procedure RecursiveFindLevels(aBaseFolder: String);
    procedure ApplyChangesToLevelFile(aFile: String);

    function SaveAllTalisman: string;
    function ClassicModeTalisman: string;
    function KillZombiesTalisman: string;
    function GetAppVersion: string;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FQuickmodMain: TFQuickmodMain;
  TalismanID: Integer;
  TotalLemmings: Integer;
  SaveRequirement: Integer;

implementation

{$R *.dfm}

{ TFQuickmodMain }

function TFQuickmodMain.GetAppVersion: String;
var
  Size, Handle: DWORD;
  Buffer: Pointer;
  FileInfo: Pointer;
  FileVersionInfoSize: UINT;
  Major, Minor, Release, Build: Word;
begin
  Result := 'Version information not available';

  // Get the size of the version info block
  Size := GetFileVersionInfoSize(PChar(ParamStr(0)), Handle);
  if Size > 0 then
  begin
    GetMem(Buffer, Size);
    try
      // Retrieve version information
      if GetFileVersionInfo(PChar(ParamStr(0)), Handle, Size, Buffer) then
      begin
        if VerQueryValue(Buffer, '\', FileInfo, FileVersionInfoSize) then
        begin
          with TVSFixedFileInfo(FileInfo^) do
          begin
            Major := HiWord(dwFileVersionMS);
            Minor := LoWord(dwFileVersionMS);
          end;
          Result := Format('Version %d.%d', [Major, Minor]);
        end;
      end;
    finally
      FreeMem(Buffer);
    end;
  end;
end;

procedure TFQuickmodMain.cbSwapStylesClick(Sender: TObject);
begin
  if cbSwapStyles.Checked then
  begin
    rbNeoToSuper.Enabled := True;
    rbSuperToNeo.Enabled := True;
    cbCorrectWaterAndExits.Enabled := True;
    cbCorrectWaterAndExits.Checked := True;
  end else begin
    rbNeoToSuper.Enabled := False;
    rbNeoToSuper.Checked := False;

    rbSuperToNeo.Enabled := False;
    rbSuperToNeo.Checked := False;

    cbCorrectWaterAndExits.Enabled := False;
    cbCorrectWaterAndExits.Checked := False;
  end;
end;

procedure TFQuickmodMain.cbCustomSkillsetClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to SKILL_COUNT-1 do
    fSkillInputs[i].SIEdit.Enabled := cbCustomSkillset.Checked;

  if cbCustomSkillset.Checked then
  begin
    cbSetAllSkillCounts.Checked := False;
    cbSetAllSkillCounts.Enabled := False;
    cbBomberToTimebomber.Checked := False;
    cbBomberToTimebomber.Enabled := False;
    cbTimebomberToBomber.Checked := False;
    cbTimebomberToBomber.Enabled := False;
    cbStonerToFreezer.Checked := False;
    cbStonerToFreezer.Enabled := False;
    cbFreezerToStoner.Checked := False;
    cbFreezerToStoner.Enabled := False;
    end else begin
    cbSetAllSkillCounts.Enabled := True;
    cbBomberToTimebomber.Enabled := True;
    cbTimebomberToBomber.Enabled := True;
    cbStonerToFreezer.Enabled := True;
    cbFreezerToStoner.Enabled := True;
  end;
end;

procedure TFQuickmodMain.cbLockRRClick(Sender: TObject);
begin
  if cbLockRR.Checked and cbUnlockRR.Checked then
  begin
    if Sender <> cbLockRR then cbLockRR.Checked := False;
    if Sender <> cbUnlockRR then cbUnlockRR.Checked := False;
  end;
end;

procedure TFQuickmodMain.cbTimebomberChangeClick(Sender: TObject);
begin
  if cbBomberToTimebomber.Checked or cbTimebomberToBomber.Checked then
  begin
    cbCustomSkillset.Checked := False;
    cbCustomSkillset.Enabled := False;
  end else
    cbCustomSkillSet.Enabled := True;

  if cbBomberToTimebomber.Checked and cbTimebomberToBomber.Checked then
  begin
    if Sender <> cbBomberToTimebomber then cbBomberToTimebomber.Checked := False;
    if Sender <> cbTimebomberToBomber then cbTimebomberToBomber.Checked := False;
  end;
end;

procedure TFQuickmodMain.cbFreezerChangeClick(Sender: TObject);
begin
  if cbStonerToFreezer.Checked or cbFreezerToStoner.Checked then
  begin
    cbCustomSkillset.Checked := False;
    cbCustomSkillset.Enabled := False;
  end else
    cbCustomSkillSet.Enabled := True;

  if cbStonerToFreezer.Checked and cbFreezerToStoner.Checked then
  begin
    if Sender <> cbStonerToFreezer then cbStonerToFreezer.Checked := False;
    if Sender <> cbFreezerToStoner then cbFreezerToStoner.Checked := False;
  end;
end;

procedure TFQuickmodMain.cbSuperlemmingClick(Sender: TObject);
begin
  if cbActivateSuperlemming.Checked and cbDeactivateSuperlemming.Checked then
  begin
    if Sender <> cbActivateSuperlemming then cbActivateSuperlemming.Checked := False;
    if Sender <> cbDeactivateSuperlemming then cbDeactivateSuperlemming.Checked := False;
  end;
end;

procedure TFQuickmodMain.cbSetAllSkillCountsClick(Sender: TObject);
begin
  if cbSetAllSkillCounts.Checked then
  begin
    cbCustomSkillset.Enabled := False;
    cbCustomSkillset.Checked := False;
  end else begin
    cbCustomSkillset.Enabled := True;
  end;
end;

procedure TFQuickmodMain.cbStatCheckboxClicked(Sender: TObject);
begin
  ebLemCount.Enabled := cbLemCount.Checked;
  ebSaveRequirement.Enabled := cbSaveRequirement.Checked;
  ebReleaseRate.Enabled := cbReleaseRate.Checked;
  ebTimeLimit.Enabled := cbTimeLimit.Checked;
end;

constructor TFQuickmodMain.Create(aOwner: TComponent);
begin
  inherited;
  Randomize;
  fPackList := TStringList.Create;
  AppPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  fProcessCompletedSuccessfully := False;

  Self.Caption := 'SLX QuickMod' + GetAppVersion;
end;

destructor TFQuickmodMain.Destroy;
begin
  fPackList.Free;
  inherited;
end;

procedure TFQuickmodMain.btnApplyClick(Sender: TObject);
var
  SelectedChanges, SelectedPack, NoUndo, AreYouSure: String;
begin
  SelectedChanges := 'Your selected changes will now be applied to' + sLineBreak;
  SelectedPack := ' ' + sLineBreak + cbPack.Text + sLineBreak;
  NoUndo := sLineBreak + 'This action cannot be undone. Please make sure you have a backup copy before proceeding!' + sLineBreak;
  AreYouSure := sLineBreak + 'Would you like to go ahead?';

  if MessageDlg(SelectedChanges + SelectedPack + NoUndo + AreYouSure,
                mtCustom, [mbYes, mbNo], 0, mbNo) = mrYes then
    ApplyChanges;
end;

procedure TFQuickmodMain.BuildPackList;
var
  SearchRec: TSearchRec;
  i: Integer;
begin
  if FindFirst(AppPath + 'levels\*', faDirectory, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then Continue;
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
        LoadPackInfo(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  cbPack.Items.Clear;
  for i := 0 to fPackList.Count-1 do
    cbPack.Items.Add(fPackList.ValueFromIndex[i]);
  cbPack.ItemIndex := 0;
end;

procedure TFQuickmodMain.LoadPackInfo(aPackFolder: String);
var
  FullPath: String;
  PackName: String;
  ThisLine: String;
  SL: TStringList;
begin
  FullPath := IncludeTrailingPathDelimiter(AppPath + 'levels\' + aPackFolder);
  PackName := '';
  if FileExists(FullPath + 'info.nxmi') then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(FullPath + 'info.nxmi');
      while SL.Count > 0 do
      begin
        ThisLine := TrimLeft(SL[0]);
        if Uppercase(LeftStr(ThisLine, 5)) = 'TITLE' then
          PackName := RightStr(ThisLine, Length(ThisLine)-6);
        SL.Delete(0);
      end;
    finally
      SL.Free;
    end;
  end;

  if PackName = '' then PackName := aPackFolder;
  fPackList.Values[FullPath] := PackName;
end;

procedure TFQuickmodMain.CreateSkillInputs;
var
  i: Integer;
  ThisInput: TSkillInputComponents;
const
  ORIGIN_X = 24;
  ORIGIN_Y = 70;
  SPACING_X = 160;
  SPACING_Y = 30;
  LABEL_WIDTH = 100;
  EDIT_WIDTH = 40;
begin
  gbCustomSkillset.Anchors := [akLeft, akTop, akRight, akBottom];

  for i := 0 to SKILL_COUNT-1 do
  begin
    ThisInput.SILabel := TLabel.Create(Self);
    ThisInput.SIEdit := TEdit.Create(Self);

    with ThisInput.SILabel do
    begin
      Parent := gbCustomSkillset;
      Caption := SKILLS[i];
      Height := 22;
      Left := ORIGIN_X + (SPACING_X * (i mod 3)) + EDIT_WIDTH + 8;
      Top := ORIGIN_Y + (SPACING_Y * (i div 3)) + 2;
      Width := LABEL_WIDTH;
    end;

    with ThisInput.SIEdit do
    begin
      Parent := gbCustomSkillset;
      Enabled := False;
      Height := 22;
      Left := ORIGIN_X + (SPACING_X * (i mod 3));
      NumbersOnly := True;
      Text := '0';
      Top := ORIGIN_Y + (SPACING_Y * (i div 3));
      Width := EDIT_WIDTH;
    end;

    fSkillInputs[i] := ThisInput;
  end;
end;


procedure TFQuickmodMain.FormClick(Sender: TObject);
begin
  cbPack.SetFocus;
end;

procedure TFQuickmodMain.gbSkillsClick(Sender: TObject);
begin
  cbPack.SetFocus;
end;

procedure TFQuickmodMain.FormCreate(Sender: TObject);
begin
  BuildPackList;
  CreateSkillInputs;
end;

function TFQuickmodMain.SaveAllTalisman: string;
begin
  Result := sLineBreak +
            ' $TALISMAN' + sLineBreak +
            '   TITLE Save All Lemmings' + sLineBreak +
            '   ID ' + IntToStr(TalismanID) + sLineBreak +
            '   COLOR Gold' + sLineBreak +
            '   SAVE_REQUIREMENT ' + IntToStr(TotalLemmings) + sLineBreak +
            ' $END' + sLineBreak;
end;

procedure TFQuickmodMain.seSkillCountsChange(Sender: TObject);
begin
  if seSkillCounts.Value < 1 then
    seSkillCounts.Value := 1;

  if seSkillCounts.Value > 100 then
    seSkillCounts.Value := 100;
end;

procedure TFQuickmodMain.seSkillCountsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    cbPack.SetFocus;
end;

function TFQuickmodMain.ClassicModeTalisman: string;
begin
  Result := sLineBreak +
            ' $TALISMAN' + sLineBreak +
            '   TITLE Classic Mode' + sLineBreak +
            '   ID ' + IntToStr(TalismanID) + sLineBreak +
            '   COLOR Gold' + sLineBreak +
            '   CLASSIC_MODE 0' + sLineBreak +
            ' $END' + sLineBreak;
end;

function TFQuickmodMain.KillZombiesTalisman: string;
begin
  Result := sLineBreak +
            ' $TALISMAN' + sLineBreak +
            '   TITLE Kill All Zombies' + sLineBreak +
            '   ID ' + IntToStr(TalismanID) + sLineBreak +
            '   COLOR Gold' + sLineBreak +
            '   KILL_ZOMBIES 0' + sLineBreak +
            ' $END' + sLineBreak;
end;

procedure TFQuickmodMain.ApplyChanges;
begin
  fProcessCompletedSuccessfully := False;
  RecursiveFindLevels(fPackList.Names[cbPack.ItemIndex]);

  if fProcessCompletedSuccessfully then
  ShowMessage('Done!');
end;

procedure TFQuickmodMain.RecursiveFindLevels(aBaseFolder: String);
var
  SearchRec: TSearchRec;
begin
  if FindFirst(aBaseFolder + '*', faDirectory, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then Continue;
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
        RecursiveFindLevels(IncludeTrailingPathDelimiter(aBaseFolder + SearchRec.Name));
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  if FindFirst(aBaseFolder + '*.sxlv', 0, SearchRec) = 0 then
  begin
    try
      repeat
        ApplyChangesToLevelFile(aBaseFolder + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  if FindFirst(aBaseFolder + '*.nxlv', 0, SearchRec) = 0 then
  begin
    try
      repeat
        ApplyChangesToLevelFile(aBaseFolder + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  fProcessCompletedSuccessfully := True;
end;

procedure TFQuickmodMain.ApplyChangesToLevelFile(aFile: String);
var
  SL: TStringList;
  LevelSkillsList: TStringList;
  ThisLine: String;
  SecLevel: Integer;
  n, i, p, YPos: Integer;
  ExitOffset: Integer;
  NewID: String;
  LevelHasZombies: Boolean;
  AlreadyModified: Boolean;
  ShouldConvertSkills: Boolean;
  ShouldConvertLevels: Boolean;
  ShouldCorrectWaterAndExits: Boolean;
  NeoToSuper: Boolean;
  SuperToNeo: Boolean;
begin
  SecLevel := 0;
  n := 0;
  SL := TStringList.Create;
  TalismanID := -1;
  TotalLemmings := 0;
  SaveRequirement := 0;
  LevelHasZombies := False;
  AlreadyModified := False;

  ShouldConvertSkills := cbBomberToTimebomber.Checked
                      or cbTimebomberToBomber.Checked
                      or cbStonerToFreezer.Checked
                      or cbFreezerToStoner.Checked;

  ShouldConvertLevels := cbSwapStyles.Checked and
                         (rbNeoToSuper.Checked or rbSuperToNeo.Checked);

  ShouldCorrectWaterAndExits := ShouldConvertLevels and
                                cbCorrectWaterAndExits.Checked;

  NeoToSuper := rbNeoToSuper.Checked;
  SuperToNeo := rbSuperToNeo.Checked;

  LevelSkillsList := TStringList.Create;

  try
    SL.LoadFromFile(aFile);

    // First, make sure all styles are correct
    if ShouldConvertLevels and SuperToNeo then
    begin
      for n := 0 to SL.Count - 1 do
      begin
        SL[n] := StringReplace(SL[n], 'slx_crystal', 'orig_crystal', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_dirt', 'orig_dirt', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_fire', 'orig_fire', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_marble', 'orig_marble', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_pillar', 'orig_pillar', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_brick', 'ohno_brick', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_bubble', 'ohno_bubble', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_rock', 'ohno_rock', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'slx_snow', 'ohno_snow', [rfReplaceAll, rfIgnoreCase]);
      end;
    end;

    // Reset to the start of the level file
    n := 0;

    // Go ahead and make changes
    while n < SL.Count do
    begin
      ThisLine := Uppercase(TrimLeft(SL[n]));

      if (Trim(ThisLine) = '# LEVEL FILE MODIFIED BY SLX QUICKMOD') then
        AlreadyModified := True;

      // Get some values for adding Talismans
      if (Trim(ThisLine) = '$TALISMAN') then
      begin
        Inc(TalismanID);
      end;

      if cbLemCount.Checked then
        TotalLemmings := StrToInt(ebLemCount.Text)
      else if (Pos('LEMMINGS ', ThisLine) = 1) then
      begin
        Val(Copy(ThisLine, Length('LEMMINGS ') + 1, Length(ThisLine)), TotalLemmings, p);
      end;

      if cbSaveRequirement.Checked then
        SaveRequirement := StrToInt(ebSaveRequirement.Text)
      else if (Pos('SAVE_REQUIREMENT ', ThisLine) = 1) then
      begin
        if (SecLevel = 0) then
          SaveRequirement := StrToInt(Copy(ThisLine, Length('SAVE_REQUIREMENT ') + 1, MaxInt));
      end;

      if (Trim(ThisLine) = 'ZOMBIE') then
        LevelHasZombies := True;

      // Set any changed values
      if LeftStr(ThisLine, 4) = '$END' then
      begin
        Dec(SecLevel);
        if SecLevel < 0 then Break;
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$SKILLSET') and cbSetAllSkillCounts.Checked then
      begin
        LevelSkillsList.Clear;
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          SL[n] := '# ' + SL[n];

          if (ThisLine <> '$SKILLSET') and (ThisLine <> '$END') then
            LevelSkillsList.Add(Copy(ThisLine, 1, Pos(' ', ThisLine + ' ') - 1));

          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$SKILLSET') and cbCustomSkillset.Checked then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$SKILLSET') and ShouldConvertSkills then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));

          if (LeftStr(ThisLine, 10) = 'TIMEBOMBER') and cbTimebomberToBomber.Checked then
            SL[n] := '   BOMBER ' + Copy(ThisLine, 12, Length(ThisLine))
          else if (LeftStr(ThisLine, 6) = 'BOMBER') and cbBomberToTimebomber.Checked then
            SL[n] := '   TIMEBOMBER ' + Copy(ThisLine, 8, Length(ThisLine))
          else if (LeftStr(ThisLine, 6) = 'STONER') and cbStonerToFreezer.Checked then
            SL[n] := '   FREEZER ' + Copy(ThisLine, 8, Length(ThisLine))
          else if (LeftStr(ThisLine, 7) = 'FREEZER') and cbFreezerToStoner.Checked then
            SL[n] := '   STONER ' + Copy(ThisLine, 9, Length(ThisLine));

          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$TALISMAN') and (cbRemoveTalismans.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$GADGET') and ShouldCorrectWaterAndExits then
      begin
        {======================================================================}
        {=============== Correct Water Objects & Exit Positions ===============}
        {======================================================================}
        repeat
          ThisLine := Uppercase(Trim(SL[n]));

          // Crystal - move locked exits 8px
          if (Trim(ThisLine) = 'STYLE ORIG_CRYSTAL') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := -8
              else if SuperToNeo then
                ExitOffset := 8
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Dirt - move locked exits 3px
          if (Trim(ThisLine) = 'STYLE ORIG_DIRT') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := -3
              else if SuperToNeo then
                ExitOffset := 3
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Fire - swap water/lava, move locked exits 24px
          if (Trim(ThisLine) = 'STYLE ORIG_FIRE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') or (Trim(ThisLine) = 'PIECE LAVA') then
            begin
              if NeoToSuper then
              begin
                if (Trim(ThisLine) = 'PIECE WATER') then
                  SL[n] := '   PIECE lava';
              end else if SuperToNeo then
              begin
                if (Trim(ThisLine) = 'PIECE LAVA') then
                  SL[n] := '   PIECE water';
              end;
            end else
            if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := -24
              else if SuperToNeo then
                ExitOffset := 24
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Marble - swap water/poison
          if (Trim(ThisLine) = 'STYLE ORIG_MARBLE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if NeoToSuper then
            begin
              if (Trim(ThisLine) = 'PIECE WATER') then
                SL[n] := '   PIECE poison';
            end else if SuperToNeo then
            begin
              if (Trim(ThisLine) = 'PIECE POISON') then
                SL[n] := '   PIECE water';
            end;
          end;

          // Brick - move regular exits 13px
          if (Trim(ThisLine) = 'STYLE OHNO_BRICK') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE EXIT') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := 13
              else if SuperToNeo then
                ExitOffset := -13
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Bubble - swap water/blasticine, move exits 8px
          if (Trim(ThisLine) = 'STYLE OHNO_BUBBLE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') or (Trim(ThisLine) = 'PIECE BLASTICINE') then
            begin
              if NeoToSuper then
              begin
                if (Trim(ThisLine) = 'PIECE WATER') then
                  SL[n] := '   PIECE blasticine';
              end else if SuperToNeo then
              begin
                if (Trim(ThisLine) = 'PIECE BLASTICINE') then
                  SL[n] := '   PIECE water';
              end;
            end else
            if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := -8
              else if SuperToNeo then
                ExitOffset := 8
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Rock - swap water/vinewater, move regular exits 6px, move locked exits 8px
          if (Trim(ThisLine) = 'STYLE OHNO_ROCK') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') or (Trim(ThisLine) = 'PIECE VINEWATER') then
            begin
              if NeoToSuper then
              begin
                if (Trim(ThisLine) = 'PIECE WATER') then
                  SL[n] := '   PIECE vinewater';
              end else if SuperToNeo then
              begin
                if (Trim(ThisLine) = 'PIECE VINEWATER') then
                  SL[n] := '   PIECE water';
              end;
            end else
            if (Trim(ThisLine) = 'PIECE EXIT') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := 6
              else if SuperToNeo then
                ExitOffset := -6
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);

            end else if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := -8
              else if SuperToNeo then
                ExitOffset := 8
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          // Snow - move regular exits 5px
          if (Trim(ThisLine) = 'STYLE OHNO_SNOW') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE EXIT') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);

              if NeoToSuper then
                ExitOffset := 5
              else if SuperToNeo then
                ExitOffset := -5
              else
                ExitOffset := 0; // Just in case

              SL[n] := '   Y ' + IntToStr(YPos + ExitOffset);
            end;
          end;

          Inc(n);
        until (ThisLine = '$END');
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$GADGET') and (cbRemoveSpecialLemmings.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          if (LeftStr(ThisLine, 8) = 'LEMMINGS') or (ThisLine = 'ZOMBIE') or (ThisLine = 'NEUTRAL') then
            SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$LEMMING') and (cbRemovePreplaced.Checked or cbRemoveSpecialLemmings.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          if (cbRemovePreplaced.Checked) or (ThisLine = 'ZOMBIE') or (ThisLine = 'NEUTRAL') then
          SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if LeftStr(ThisLine, 1) = '$' then
        Inc(SecLevel)
      else if SecLevel = 0 then begin
        if (LeftStr(ThisLine, 8) = 'LEMMINGS') and cbLemCount.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 16) = 'SAVE_REQUIREMENT') and cbSaveRequirement.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 18) = 'MAX_SPAWN_INTERVAL') and cbReleaseRate.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 10) = 'TIME_LIMIT') and cbTimeLimit.Checked then
          SL[n] := '# ' + SL[n];

        if (Trim(ThisLine) = 'SPAWN_INTERVAL_LOCKED') and (cbLockRR.Checked or cbUnlockRR.Checked) then
          SL[n] := '# ' + SL[n];

        if (Trim(ThisLine) = 'SUPERLEMMING') and cbDeactivateSuperlemming.Checked then
          SL[n] := '# ' + SL[n];

        if (LeftStr(ThisLine, 6) = 'AUTHOR') and cbChangeAuthor.Checked then
          SL[n] := '# ' + SL[n];

        if ((LeftStr(ThisLine, 2)) = 'ID') and cbChangeID.Checked then
          SL[n] := '# ' + SL[n];
      end;

      Inc(n);
    end;

    // If necessary, update all styles after other changes have been made
    if ShouldConvertLevels and NeoToSuper then
    begin
      for n := 0 to SL.Count - 1 do
      begin
        SL[n] := StringReplace(SL[n], 'orig_crystal', 'slx_crystal', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'orig_dirt', 'slx_dirt', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'orig_fire', 'slx_fire', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'orig_marble', 'slx_marble', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'orig_pillar', 'slx_pillar', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'ohno_brick', 'slx_brick', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'ohno_bubble', 'slx_bubble', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'ohno_rock', 'slx_rock', [rfReplaceAll, rfIgnoreCase]);
        SL[n] := StringReplace(SL[n], 'ohno_snow', 'slx_snow', [rfReplaceAll, rfIgnoreCase]);
      end;
    end;

    if not AlreadyModified then
    begin
      SL.Insert(0, '# Level file modified by SLX QuickMod');
      SL.Insert(1, '');
    end;

    SL.Add('');
    SL.Add('# SLX QuickMod modifications');
    SL.Add('');

    if cbChangeAuthor.Checked then SL.Add('AUTHOR ' + ebAuthor.Text);

    if cbChangeID.Checked then
    begin
      repeat
        NewID := IntToHex(Random($10000), 4) + IntToHex(Random($10000), 4) + IntToHex(Random($10000), 4) + IntToHex(Random($10000), 4);
      until NewID <> '0000000000000000';

      SL.Add('ID x' + NewID);
    end;

    if cbLemCount.Checked then SL.Add('LEMMINGS ' + IntToStr(StrToIntDef(ebLemCount.Text, 0)));
    if cbSaveRequirement.Checked then SL.Add('SAVE_REQUIREMENT ' + IntToStr(StrToIntDef(ebSaveRequirement.Text, 0)));
    if cbReleaseRate.Checked then SL.Add('MAX_SPAWN_INTERVAL ' + IntToStr(103 - StrToIntDef(ebReleaseRate.Text, 0)));
    if cbLockRR.Checked then SL.Add('SPAWN_INTERVAL_LOCKED');
    if cbTimeLimit.Checked and (StrToIntDef(ebTimeLimit.Text, 0) >= 1) then
      SL.Add('TIME_LIMIT ' + IntToStr(StrToIntDef(ebTimeLimit.Text, 0)));
    if cbActivateSuperlemming.Checked then SL.Add('SUPERLEMMING');

    if cbAddSaveAllTalisman.Checked and not (TotalLemmings = SaveRequirement)
      and not LevelHasZombies then
    begin
      Inc(TalismanID);
      SL.Add(SaveAllTalisman);
    end;

    if cbAddClassicModeTalisman.Checked then
    begin
      Inc(TalismanID);
      SL.Add(ClassicModeTalisman);
    end;

    if cbAddKillZombiesTalisman.Checked and LevelHasZombies then
    begin
      Inc(TalismanID);
      SL.Add(KillZombiesTalisman);
    end;

//    if cbAddNoPauseTalisman.Checked then
//    begin
//      Inc(TalismanID);
//      SL.Add(NoPauseTalisman);
//    end;

    if cbBomberToTimebomber.Checked then SL.Add('# BOMBERS CHANGED TO TIMEBOMBERS');
    if cbTimebomberToBomber.Checked then SL.Add('# TIMEBOMBERS CHANGED TO BOMBERS');
    if cbStonerToFreezer.Checked then SL.Add('# STONERS CHANGED TO FREEZERS');
    if cbFreezerToStoner.Checked then SL.Add('# FREEZERS CHANGED TO STONERS');
    if ShouldConvertLevels then SL.Add('# WATER OBJECTS UPDATED');
    if ShouldConvertLevels then SL.Add('# EXIT POSITIONS UPDATED');
    if cbRemoveTalismans.Checked then SL.Add('# TALISMANS REMOVED');
    if cbRemoveSpecialLemmings.Checked then SL.Add('# SPECIAL LEMS REMOVED');
    if cbRemovePreplaced.Checked then SL.Add('# PRE-PLACED LEMS REMOVED');
    if cbDeactivateSuperlemming.Checked then SL.Add('# SUPERLEMMING DEACTIVATED');

    if cbSetAllSkillCounts.Checked then
    begin
      SL.Add('# SKILLSET CHANGED:');
      SL.Add('$SKILLSET');

      for i := 0 to LevelSkillsList.Count - 1 do
      begin
        var Skill := LevelSkillsList[i];

        if ShouldConvertSkills then
        begin
          if (Skill = 'BOMBER') and cbBomberToTimebomber.Checked then
            Skill := 'TIMEBOMBER'
          else if (Skill = 'TIMEBOMBER') and cbTimebomberToBomber.Checked then
            Skill := 'BOMBER'
          else if (Skill = 'STONER') and cbStonerToFreezer.Checked then
            Skill := 'FREEZER'
          else if (Skill = 'FREEZER') and cbFreezerToStoner.Checked then
            Skill := 'STONER';
        end;

        SL.Add('  ' + Skill + ' ' + IntToStr(seSkillCounts.Value));
      end;

      SL.Add('$END');
    end;

    if cbCustomSkillset.Checked then
    begin
      SL.Add('# SKILLSET CHANGED:');
      SL.Add('$SKILLSET');

      for i := 0 to SKILL_COUNT-1 do
        if StrToIntDef(fSkillInputs[i].SIEdit.Text, 0) > 0 then
          SL.Add('  ' + Uppercase(SKILLS[i]) + ' ' + IntToStr(StrToIntDef(fSkillInputs[i].SIEdit.Text, 0)));

      SL.Add('$END');
    end;

    SL.SaveToFile(aFile);
  finally
    LevelSkillsList.Free;
    SL.Free;
  end;
end;

end.
