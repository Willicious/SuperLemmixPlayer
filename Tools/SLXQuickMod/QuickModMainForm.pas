unit QuickModMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.UITypes, StrUtils,
  Vcl.ExtCtrls;

const
  SKILL_COUNT = 26;
  SKILLS: array[0..SKILL_COUNT-1] of String =
   ('Walker', 'Jumper', 'Shimmier', 'Ballooner',
    'Slider', 'Climber', 'Swimmer', 'Floater', 'Glider', 'Disarmer',
    'Timebomber', 'Bomber', 'Freezer', 'Blocker',
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

    gbSkillset: TGroupBox;
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
    cbUpdateWater: TCheckBox;
    gbSkillConversions: TGroupBox;
    cbTimebomberToBomber: TCheckBox;
    cbBomberToTimebomber: TCheckBox;
    cbStonerToFreezer: TCheckBox;
    cbUpdateExitPositions: TCheckBox;
    gbNLConversions: TGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure cbStatCheckboxClicked(Sender: TObject);
    procedure cbCustomSkillsetClick(Sender: TObject);
    procedure cbLockRRClick(Sender: TObject);
    procedure cbTimebomberChangeClick(Sender: TObject);
    procedure cbSuperlemmingClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
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

procedure TFQuickmodMain.cbCustomSkillsetClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to SKILL_COUNT-1 do
    fSkillInputs[i].SIEdit.Enabled := cbCustomSkillset.Checked;
end;

procedure TFQuickmodMain.cbLockRRClick(Sender: TObject);
begin
  if cbLockRR.Checked and cbUnlockRR.Checked then
  begin
    if Sender <> cbLockRR then cbLockRR.Checked := false;
    if Sender <> cbUnlockRR then cbUnlockRR.Checked := false;
  end;
end;

procedure TFQuickmodMain.cbTimebomberChangeClick(Sender: TObject);
begin
  if cbBomberToTimebomber.Checked or cbTimebomberToBomber.Checked then
  begin
    cbCustomSkillset.Checked := false;
    cbCustomSkillset.Enabled := false;
  end;

  if cbBomberToTimebomber.Checked and cbTimebomberToBomber.Checked then
  begin
    if Sender <> cbBomberToTimebomber then cbBomberToTimebomber.Checked := false;
    if Sender <> cbTimebomberToBomber then cbTimebomberToBomber.Checked := false;
  end;
end;

procedure TFQuickmodMain.cbSuperlemmingClick(Sender: TObject);
begin
  if cbActivateSuperlemming.Checked and cbDeactivateSuperlemming.Checked then
  begin
    if Sender <> cbActivateSuperlemming then cbActivateSuperlemming.Checked := false;
    if Sender <> cbDeactivateSuperlemming then cbDeactivateSuperlemming.Checked := false;
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
  UpdateExit, AreYouSure, SelectedPack, NoUndo: String;
begin
  if cbUpdateExitPositions.Checked then
    UpdateExit := 'Please note that updating Exit positions should only be performed ONCE per pack!' + sLineBreak
  else
    UpdateExit := '';

  AreYouSure := 'Are you sure you want to apply these changes to' + sLineBreak;
  SelectedPack := ' ' + sLineBreak + cbPack.Text + '?' + sLineBreak;
  NoUndo := sLineBreak + 'This action cannot be undone. Please make sure you have a backup copy before proceeding!';

  if MessageDlg(UpdateExit + AreYouSure + SelectedPack + NoUndo,
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
  gbSkillset.Anchors := [akLeft, akTop, akRight, akBottom];

  for i := 0 to SKILL_COUNT-1 do
  begin
    ThisInput.SILabel := TLabel.Create(self);
    ThisInput.SIEdit := TEdit.Create(self);

    with ThisInput.SILabel do
    begin
      Parent := gbSkillset;
      Caption := SKILLS[i];
      Height := 22;
      Left := ORIGIN_X + (SPACING_X * (i mod 3)) + EDIT_WIDTH + 8;
      Top := ORIGIN_Y + (SPACING_Y * (i div 3)) + 2;
      Width := LABEL_WIDTH;
    end;

    with ThisInput.SIEdit do
    begin
      Parent := gbSkillset;
      Enabled := false;
      Height := 22;
      Left := ORIGIN_X + (SPACING_X * (i mod 3));
      NumbersOnly := true;
      Text := '0';
      Top := ORIGIN_Y + (SPACING_Y * (i div 3));
      Width := EDIT_WIDTH;
    end;

    fSkillInputs[i] := ThisInput;
  end;
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
  ThisLine: String;
  SecLevel: Integer;
  n, i, p, YPos: Integer;
  NewID: String;
  LevelHasZombies: Boolean;
  AlreadyModified: Boolean;
  ShouldConvertSkills: Boolean;
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
                      or cbStonerToFreezer.Checked;

  try
    SL.LoadFromFile(aFile);

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
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$SKILLSET') and (cbCustomSkillset.Checked) then
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
            SL[n] := '  BOMBER ' + Copy(ThisLine, 12, Length(ThisLine))
          else if (LeftStr(ThisLine, 6) = 'BOMBER') and cbBomberToTimebomber.Checked then
            SL[n] := '  TIMEBOMBER ' + Copy(ThisLine, 8, Length(ThisLine))
          else if (LeftStr(ThisLine, 6) = 'STONER') and cbStonerToFreezer.Checked then
            SL[n] := '  FREEZER ' + Copy(ThisLine, 8, Length(ThisLine));

          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$TALISMAN') and (cbRemoveTalismans.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$GADGET') and (cbUpdateWater.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));

          if (Trim(ThisLine) = 'STYLE ORIG_FIRE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') then
              SL[n] := '   PIECE lava';
          end;

          if (Trim(ThisLine) = 'STYLE ORIG_MARBLE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') then
              SL[n] := '   PIECE poison';
          end;

          if (Trim(ThisLine) = 'STYLE OHNO_BUBBLE') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') then
              SL[n] := '   PIECE blasticine';
          end;

          if (Trim(ThisLine) = 'STYLE OHNO_ROCK') then
          begin
            Inc(n);
            ThisLine := Uppercase(Trim(SL[n]));

            if (Trim(ThisLine) = 'PIECE WATER') then
              SL[n] := '   PIECE vinewater';
          end;

          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$GADGET') and (cbRemoveSpecialLemmings.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));
          if (LeftStr(ThisLine, 8) = 'LEMMINGS') or (ThisLine = 'ZOMBIE') or (ThisLine = 'NEUTRAL') then
            SL[n] := '# ' + SL[n];
          Inc(n);
        until ThisLine = '$END';
      end else if (SecLevel = 0) and (Trim(ThisLine) = '$GADGET') and (cbUpdateExitPositions.Checked) then
      begin
        repeat
          ThisLine := Uppercase(Trim(SL[n]));

          // Brick - move regular exits down 13px
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
              SL[n] := '   Y ' + IntToStr(YPos + 13);
            end;
          end;

          // Bubble - move locked exits up 8px
          if (Trim(ThisLine) = 'STYLE OHNO_BUBBLE') then
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
              SL[n] := '   Y ' + IntToStr(YPos - 8);
            end;
          end;

          // Rock - regular exits down 6px / move locked exits up 8px
          if (Trim(ThisLine) = 'STYLE OHNO_ROCK') then
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
              SL[n] := '   Y ' + IntToStr(YPos + 6);

            end else if (Trim(ThisLine) = 'PIECE EXIT_LOCKED') then
            begin
              repeat
                Inc(n);
                ThisLine := Uppercase(Trim(SL[n]));
              until (Copy(ThisLine, 1, 1) = 'Y') and (Length(ThisLine) > 1);

              YPos := StrToIntDef(Copy(ThisLine, 3, Length(ThisLine) - 2), 0);
              SL[n] := '   Y ' + IntToStr(YPos - 8);
            end;
          end;

          // Snow - move regular exits down 5px
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
              SL[n] := '   Y ' + IntToStr(YPos + 5);
            end;
          end;

          // Crystal - move locked exits up 8px
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
              SL[n] := '   Y ' + IntToStr(YPos - 8);
            end;
          end;

          // Dirt - move locked exits up 3px
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
              SL[n] := '   Y ' + IntToStr(YPos - 3);
            end;
          end;

          // Fire - move locked exits up 24px
          if (Trim(ThisLine) = 'STYLE ORIG_FIRE') then
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
              SL[n] := '   Y ' + IntToStr(YPos - 24);
            end;
          end;

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
    if cbUpdateWater.Checked then SL.Add('# WATER OBJECTS UPDATED');
    if cbUpdateExitPositions.Checked then SL.Add('# EXIT POSITIONS UPDATED');
    if cbRemoveTalismans.Checked then SL.Add('# TALISMANS REMOVED');
    if cbRemoveSpecialLemmings.Checked then SL.Add('# SPECIAL LEMS REMOVED');
    if cbRemovePreplaced.Checked then SL.Add('# PRE-PLACED LEMS REMOVED');
    if cbDeactivateSuperlemming.Checked then SL.Add('# SUPERLEMMING DEACTIVATED');

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
    SL.Free;
  end;
end;

end.
