{$include lem_directives.inc}
unit LemNeoSave;

interface

uses
  SharedGlobals,
  Dialogs, StrUtils, UMisc,
  Classes, SysUtils, LemTypes, LemDosStructures,
  LemNeoEncryption, TalisData;

  // LemNeoEncryption is now only used for backwards-compatibility.

type
  TalismanLog = packed record
    TalSignature: LongWord;
    Acheived: Byte;
  end;

  TNeoSave = class(TPersistent)
  private
    fCodeSeed   : Integer;
    fTalismans  : TTalismans;
    fNeoEncrypt : TNeoEncryption;
    fDisableSave: Boolean;
    fSaveData   : TNeoSaveRecord;
    fTalismanData : Array of TalismanLog;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure UnlockLevel(aSection, aLevel: Integer);
    function CheckUnlocked(aSection, aLevel: Integer): Boolean;
    function CheckUnlockedRank(aSection: Integer): Boolean;
    procedure CompleteLevel(aSection, aLevel: Integer);
    function CheckCompleted(aSection, aLevel: Integer): Boolean;
    procedure UpdateConfig(aPointer: Pointer);
    procedure LoadConfig(aPointer: Pointer);
    function GetLemmingRecord(aSection, aLevel: Integer): Integer;
    procedure SetLemmingRecord(aSection, aLevel, aValue: Integer);
    function GetTimeRecord(aSection, aLevel: Integer): Integer;
    procedure SetTimeRecord(aSection, aLevel, aValue: Integer);
    procedure SaveFile(aPointer: Pointer);
    procedure LoadFile(aPointer: Pointer);
    procedure LoadOldFile(aPointer: Pointer);
    procedure SetTalismans(aValue: TTalismans);
    procedure AddMissingTalismans;
    function CheckTalisman(aSig: Cardinal): Boolean;
    procedure GetTalisman(aSig: Cardinal);
    procedure SetCodeSeed(aValue: Integer);
    property DisableSave: Boolean read fDisableSave write fDisableSave;
  end;

implementation

uses
  GameControl;

constructor TNeoSave.Create;
begin
  inherited Create;
  fNeoEncrypt := TNeoEncryption.Create;
  SetLength(fTalismanData, 0);
  fCodeSeed := 0;
  fDisableSave := false;
end;

destructor TNeoSave.Destroy;
begin
  fNeoEncrypt.Free;
  inherited Destroy;
end;

procedure TNeoSave.SetCodeSeed(aValue: Integer);
begin
  fCodeSeed := aValue;
end;

procedure TNeoSave.SetTalismans(aValue: TTalismans);
begin
  fTalismans := aValue;
  SetLength(fTalismanData, fTalismans.Count);
  AddMissingTalismans;
end;

procedure TNeoSave.Clear;
var
  i: Integer;
  p: ^Byte;
begin
  p := @fSaveData;
  for i := 0 to SizeOf(fSaveData)-1 do
  begin
    p^ := 0;
    inc(p);
  end;
  for i := 0 to Length(fTalismanData)-1 do
    FillChar(fTalismanData[i], SizeOf(fTalismanData[i]), 0);
  SetLength(fTalismanData, fTalismans.Count);
  AddMissingTalismans;
end;

procedure TNeoSave.UpdateConfig(aPointer: Pointer);
var
  p : ^TDOSGameParams;
  //g : TDOSGameParams;
  i : integer;
begin
  p := aPointer;
  //g := p^;
  fSaveData.Config.ToggleOptions := LongWord(p.MiscOptions);
  i := StrToInt('0x' + p.BackgroundColor);
  fSaveData.Config.BackgroundColor[0] := i shr 16;
  fSaveData.Config.BackgroundColor[1] := (i shr 8) mod 256;
  fSaveData.Config.BackgroundColor[2] := i mod 256;
  fSaveData.Config.PercentOption := p.UsePercentages;
  fSaveData.Config.ForceGimmick := p.ForceGimmick;
  fSaveData.Config.ForceGimmick2 := p.ForceGimmick2;
  fSaveData.Config.ForceGimmick3 := p.ForceGimmick3;
  fSaveData.Config.ForceSkillset := p.ForceSkillset;
  fSaveData.Config.SteelOption := p.SteelOverride;
  fSaveData.Config.TestOption := p.fTestScreens;
  fSaveData.Config.SoundOption := Byte(p.SoundOptions);
  fSaveData.Config.PackName := '                                ';
  StrPLCopy(fSaveData.Config.PackName, p.fLevelPack, Length(p.fLevelPack));
  fSaveData.Config.PrefixName := '                ';
  StrPLCopy(fSaveData.Config.PrefixName, p.fExternalPrefix, Length(p.fExternalPrefix));
  for i := 0 to SizeOf(fSaveData.Config.Reserved)-1 do
    fSaveData.Config.Reserved[i] := 0;
end;

procedure TNeoSave.LoadConfig(aPointer: Pointer);
var
  p : ^TDOSGameParams;
  //g : TDOSGameParams;
  i : integer;
begin
  p := aPointer;
  //g := p^;
  with fSaveData.Config do
  begin
    p.MiscOptions := TMiscOptions(ToggleOptions);
    i := (BackgroundColor[0] shl 16) + (BackgroundColor[1] shl 8) + (BackgroundColor[2]);
    p.BackgroundColor := IntToHex(i, 6);
    p.UsePercentages := PercentOption;
    p.ForceGimmick := ForceGimmick;
    p.ForceGimmick2 := ForceGimmick2;
    p.ForceGimmick3 := ForceGimmick3;
    p.ForceSkillset := ForceSkillset;
    p.SteelOverride := SteelOption;
    p.fTestScreens := TestOption;
    p.SoundOptions := TGameSoundOptions(SoundOption);
    p.fLevelPack := Trim(PackName);
    p.fExternalPrefix := Trim(PrefixName);
  end;
end;

procedure TNeoSave.UnlockLevel(aSection, aLevel: Integer);
var
  p : ^byte;
  b : byte;
begin
  p := @fSaveData.UnlockTable[aSection][aLevel div 8];
  b := p^;
  b := b or (1 shl (aLevel mod 8));
  p^ := b;
end;

function TNeoSave.CheckUnlocked(aSection, aLevel: Integer): Boolean;
var
  b: byte;
begin
  b := fSaveData.UnlockTable[aSection][aLevel div 8];
  Result := b and (1 shl (aLevel mod 8)) <> 0;
end;

function TNeoSave.CheckUnlockedRank(aSection: Integer): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to 31 do
    if fSaveData.UnlockTable[aSection][i] <> 0 then Result := true;
end;

procedure TNeoSave.CompleteLevel(aSection, aLevel: Integer);
var
  p : ^byte;
  b : byte;
begin
  p := @fSaveData.CompleteTable[aSection][aLevel div 8];
  b := p^;
  b := b or (1 shl (aLevel mod 8));
  p^ := b;
end;

function TNeoSave.CheckCompleted(aSection, aLevel: Integer): Boolean;
var
  b: byte;
begin
  b := fSaveData.CompleteTable[aSection][aLevel div 8];
  Result := b and (1 shl (aLevel mod 8)) <> 0;
end;

function TNeoSave.GetLemmingRecord(aSection, aLevel: Integer): Integer;
begin
  Result := fSaveData.RecordTable[aSection][aLevel].BestSave;
end;

procedure TNeoSave.SetLemmingRecord(aSection, aLevel, aValue: Integer);
var
  p : ^word;
begin
  p := @fSaveData.RecordTable[aSection][aLevel].BestSave;
  if aValue > p^ then p^ := aValue;
end;

function TNeoSave.GetTimeRecord(aSection, aLevel: Integer): Integer;
begin
  Result := fSaveData.RecordTable[aSection][aLevel].BestTime;
end;

procedure TNeoSave.SetTimeRecord(aSection, aLevel, aValue: Integer);
var
  p : ^longword;
begin
  p := @fSaveData.RecordTable[aSection][aLevel].BestTime;
  if (aValue < p^) or (p^ = 0) then p^ := aValue;
end;

procedure TNeoSave.SaveFile(aPointer: Pointer);
var
  SL: TStringList;
  GameParams: TDosGameParams;

  function CheckNeedSaveConfig: Boolean;
  begin
    Result := false;
    if ((GameParams.SysDat.Options and 1) <> 0) and GameParams.LookForLVLFiles then Result := true;
    if ((GameParams.SysDat.Options and 32) = 0) then Exit;

    // The rest will only execute if these modes are enabled. ^_^
    if GameParams.DebugSteel then Result := true;
    if GameParams.ChallengeMode then Result := true;
    if GameParams.TimerMode then Result := true;
    if GameParams.ForceSkillset <> 0 then Result := true;
  end;

  procedure AddBoolean(aLabel: String; aValue: Boolean);
  var
    s: String;
  begin
    if aValue then
      s := 'on'
    else
      s := 'off';

    s := aLabel + '=' + s;
    SL.Add(s);
  end;

  procedure AddForcedSkillset;
  var
    s: String;
    i: Integer;
  const
    SkillKeys: array[0..15] of String = (
               'Walker',
               'Climber',
               'Swimmer',
               'Floater',
               'Glider',
               'Disarmer',
               'Bomber',
               'Stoner',
               'Blocker',
               'Platformer',
               'Builder',
               'Stacker',
               'Basher',
               'Miner',
               'Digger',
               'Cloner');
  begin
    if GameParams.ForceSkillset = 0 then
    begin
      SL.Add('ForcedSkillset=none');
      Exit;
    end;
    s := '';
    for i := 0 to 15 do
      if (GameParams.ForceSkillset and (1 shl (15-i))) <> 0 then
        s := s + SkillKeys[i] + ',';
    s := LeftStr(s, Length(s) - 1); // remove final comma
    SL.Add('ForcedSkillset=' + s);
  end;

  procedure AddTalismans;
  var
    i: Integer;
  begin
    for i := 0 to fTalismans.Count-1 do
      if CheckTalisman(fTalismans[i].Signature) then
        SL.Add(IntToHex(fTalismans[i].Signature, 8));
  end;

  function FramesToTime(aFrameCount: Integer): String;
  var
    Mins, Secs, Frames: Integer;
  begin
    Result := '';
    Secs := Frames div 17;
    Mins := Secs div 60;

    Frames := Frames mod 17;
    Secs := Secs mod 60;

    Result := IntToStr(Mins) + ':' + LeadZeroStr(Secs, 2) + '.' + LeadZeroStr(Frames, 2);
  end;

  procedure AddLevelRecords;
  var
    R, L: Integer;
  begin
    for R := 0 to 14 do
      for L := 0 to 254 do
      begin
        if not (CheckUnlocked(R, L) or CheckCompleted(R, L)) then Continue;
        SL.Add('[L' + LeadZeroStr(R+1, 2) + LeadZeroStr(L+1, 2) + ']');
        if CheckCompleted(R, L) then
        begin
          SL.Add('Completed');
          SL.Add('MostLemmingsSaved=' + IntToStr(GetLemmingRecord(R, L)));
          SL.Add('FastestTime=' + FramesToTime(GetTimeRecord(R, L)));
        end else
          SL.Add('Unlocked');
        SL.Add('');
      end;
  end;

  procedure ClearFinalEmptyLines;
  var
    i: Integer;
  begin
    for i := SL.Count-1 downto 0 do
      if SL[i] = '' then
        SL.Delete(i)
      else
        Break;
  end;

begin
  if fDisableSave then Exit;

  GameParams := TDosGameParams(aPointer^);

  SL := TStringList.Create;

  // First, the config.
  if CheckNeedSaveConfig then
  begin
    SL.Add('[config]');
    if ((GameParams.SysDat.Options and 1) <> 0) then
      AddBoolean('LookForLVLFiles', GameParams.LookForLVLFiles);
    if ((GameParams.SysDat.Options and 32) <> 0) then
    begin
      AddBoolean('DebugSteel', GameParams.DebugSteel);
      AddBoolean('ChallengeMode', GameParams.ChallengeMode);
      AddBoolean('TimerMode', GameParams.TimerMode);
      AddForcedSkillset;
    end;
    SL.Add('');
  end;

  // Talismans next
  if fTalismans.Count <> 0 then
  begin
    SL.Add('[talismans]');
    AddTalismans;
    SL.Add('');
  end;

  // Levels finally
  AddLevelRecords;

  // And, save it.
  ClearFinalEmptyLines;
  SL.SaveToFile(ChangeFileExt(GameFile, '.nxsv'));
  SL.Free; 
end;

procedure TNeoSave.LoadFile(aPointer: Pointer);
var
  SaveFileName: String;
  GameParams: TDosGameParams;
  SL: TStringList;
  CurrentLine: Integer;
  Line: String;

  function CheckValidTalisman(aSig: LongWord): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to fTalismans.Count-1 do
      if fTalismans[i].Signature = aSig then Result := true;
  end;

  function GetKey(aString: String): String;
  var
    i: Integer;
  begin
    aString := Trim(aString);
    i := 1;
    Result := '';
    while (i <= Length(aString)) and (aString[i] <> '=') do
    begin
      Result := Result + aString[i];
      Inc(i);
    end;

    Result := Lowercase(Result);
  end;

  function GetValue(aString: String): String;
  var
    i: Integer;
  begin
    aString := Trim(aString);
    i := 1;
    Result := '';
    while (i <= Length(aString)) and (aString[i] <> '=') do
      Inc(i);
    Inc(i); // get past the =, not just to it

    while (i <= Length(aString)) do
    begin
      Result := Result + aString[i];
      Inc(i);
    end;

    Result := Lowercase(Result);
  end;

  function GetToggle(aString: String): Boolean;
  begin
    Result := (GetValue(aString) = 'on');
  end;

  function GetForcedSkillset(aString: String): Word;
  var
    LocalSL: TStringList;
    i: Integer;
  begin
    Result := 0;
    LocalSL := TStringList.Create;
    try
      LocalSL.CommaText := GetValue(aString);
      for i := 0 to LocalSL.Count-1 do
      begin
        LocalSL[i] := Trim(LocalSL[i]); // spaces for readability, but they're undesirable here
        if LocalSL[i] = 'walker' then
          Result := Result or $8000;
        if LocalSL[i] = 'climber' then
          Result := Result or $4000;
        if LocalSL[i] = 'swimmer' then
          Result := Result or $2000;
        if LocalSL[i] = 'floater' then
          Result := Result or $1000;
        if LocalSL[i] = 'glider' then
          Result := Result or $0800;
        if LocalSL[i] = 'disarmer' then
          Result := Result or $0400;
        if LocalSL[i] = 'bomber' then
          Result := Result or $0200;
        if LocalSL[i] = 'stoner' then
          Result := Result or $0100;
        if LocalSL[i] = 'blocker' then
          Result := Result or $0080;
        if LocalSL[i] = 'platformer' then
          Result := Result or $0040;
        if LocalSL[i] = 'builder' then
          Result := Result or $0020;
        if LocalSL[i] = 'stacker' then
          Result := Result or $0010;
        if LocalSL[i] = 'basher' then
          Result := Result or $0008;
        if LocalSL[i] = 'miner' then
          Result := Result or $0004;
        if LocalSL[i] = 'digger' then
          Result := Result or $0002;
        if LocalSL[i] = 'cloner' then
          Result := Result or $0001;
      end;
    except
      // Not worth raising an exception over. Just silently turn the
      // option off instead.
      Result := 0;
    end;
    LocalSL.Free;
  end;

  procedure LoadConfigSection;
  begin
    // Which options are used, and stored in the per-game files?
    // -- Look For LVL Files
    // -- Debug Steel
    // -- Challenge Mode
    // -- Timer Mode
    // -- Forced Skillset
    // Don't forget - file is not case sensitive. But all lines
    // are read from it as lowercase.
    repeat
      Line := trim(LowerCase(SL[CurrentLine]));
      Inc(CurrentLine);

      // First four are simple on/off options
      if GetKey(Line) = 'lookforlvlfiles' then
        GameParams.LookForLVLFiles := GetToggle(Line);
      if GetKey(Line) = 'debugsteel' then
        GameParams.DebugSteel := GetToggle(Line);
      if GetKey(Line) = 'challengemode' then
        GameParams.ChallengeMode := GetToggle(Line);
      if GetKey(Line) = 'timermode' then
        GameParams.TimerMode := GetToggle(Line);

      // Last one is a bit more complicated. Let's delegate it to another
      // subfunction.
      if GetKey(Line) = 'forcedskillset' then
        GameParams.ForceSkillset := GetForcedSkillset(Line);

      // And if we get a blank line, we break. Between sections we must have one
      // blank line (or more). Within a section we must not have any.
      if Line = '' then Break;

    until CurrentLine = SL.Count;
  end;

  function TimeToFrames(aTime: String): Integer;
  var
    TempString: String;
    Mins, Secs, Frames: Integer;
    i: Integer;
  begin
    // Takes a time in the format:
    // (M)M:SS.ff
    // And returns it as a frame count
    try
      i := 1;
      TempString := '';
      while aTime[i] <> ':' do
      begin
        TempString := TempString + aTime[i];
        Inc(i);
      end;
      Inc(i); // move past the :
      Mins := StrToInt(TempString);

      TempString := '';
      while aTime[i] <> '.' do
      begin
        TempString := TempString + aTime[i];
        Inc(i);
      end;
      Inc(i); // move past the .
      Secs := StrToInt(TempString);

      TempString := '';
      while i <= Length(aTime) do
      begin
        TempString := TempString + aTime[i];
        Inc(i);
      end;
      Frames := StrToInt(TempString);

      Result := (Mins * 17 * 60) + (Secs * 17) + Frames;
    except
      Result := 0;
    end;
  end;

  procedure LoadLevelInfo;
  var
    SubString: String;
    RankID, LevelID: Integer;
  begin
    // Our first step - find out what level we're loading info of.
    // Keep in mind - in the file, eg. Fun 25 would be 0125. But internally,
    // it's 0024.
    try
      SubString := MidStr(Line, 3, 2);
      RankID := StrToInt(SubString) - 1;

      SubString := MidStr(Line, 5, 3); // need to handle the rare but supported case of a 3-digit level number
      if RightStr(SubString, 1) = ']' then SubString := LeftStr(SubString, 2);
      LevelID := StrToInt(SubString) - 1;

      if (RankID < 0) or (RankID > 14)
      or (LevelID < 0) or (LevelID > 254) then
        Exit;
    except
      Exit;
    end;

    // If we've got to here, we've at least grabbed a valid level reference.
    repeat
      Line := trim(LowerCase(SL[CurrentLine]));
      Inc(CurrentLine);

      if Line = 'unlocked' then
        UnlockLevel(RankID, LevelID);
      if Line = 'completed' then
      begin
        UnlockLevel(RankID, LevelID);
        CompleteLevel(RankID, LevelID);
      end;
      if GetKey(Line) = 'mostlemmingssaved' then
        SetLemmingRecord(RankID, LevelID, StrToIntDef(GetValue(Line), 0));
      if GetKey(Line) = 'fastesttime' then
        SetTimeRecord(RankID, LevelID, TimeToFrames(GetValue(Line)));

      if Line = '' then Break;
    until CurrentLine = SL.Count;
  end;

  procedure LoadTalismanSection;
  var
    TalismanID: LongWord;
  begin
    // We can jump straight into this one.
    repeat
      Line := trim(LowerCase(SL[CurrentLine]));
      Inc(CurrentLine);

      if Line = '' then Break;

      try
        TalismanID := StrToInt('x' + Line);
        if CheckValidTalisman(TalismanID) then
          GetTalisman(TalismanID);
      except
        Continue;
      end;
    until CurrentLine = SL.Count;
  end;

begin
  if fDisableSave then Exit;
  SaveFileName := ChangeFileExt(GameFile, '.nxsv');
  GameParams := TDosGameParams(aPointer^);
  Clear;

  if not FileExists(SaveFileName) then
  begin
    if FileExists(ChangeFileExt(SaveFileName, '.sav')) then
    begin
      LoadOldFile(aPointer);
      DeleteFile(ChangeFileExt(SaveFileName, '.sav'));
    end;
    SaveFile(aPointer);
  end;

  SL := TStringList.Create;
  try
    // Should be using a proper class for this. I'll change to one eventually.
    // Let's get it working as a concept first.
    SL.LoadFromFile(SaveFileName);
    SL.Add(''); // Add a blank line. This ensures that if the last section is
                // empty, it will terminate rather than crash.
    CurrentLine := 0;
    repeat
      Line := trim(LowerCase(SL[CurrentLine]));
      Inc(CurrentLine);

      // Config header
      if Line = '[config]' then
      begin
        LoadConfigSection;
        Continue;
      end;

      if Line = '[talismans]' then
      begin
        LoadTalismanSection;
        Continue;
      end;

      // Any section name starting with l is level data
      if LeftStr(Line, 2) = '[l' then
      begin
        LoadLevelInfo;
        Continue;
      end;

    until CurrentLine = SL.Count;
  finally
    SL.Free;
  end;
end;

procedure TNeoSave.LoadOldFile(aPointer: Pointer);
var
  S : TMemoryStream;
  TempTalis: TalismanLog;
  DecryptSuccess: Boolean;
  w: Word;

  function CheckValidTalisman(aSig: LongWord): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to fTalismans.Count-1 do
      if fTalismans[i].Signature = aSig then Result := true;
  end;

begin
  //if TDosGameParams(aPointer).fTestMode then Exit;
  //if (ParamStr(0) = 'testmode')
  //or (GameFile = 'Single Levels') then
  //  Exit;
  if fDisableSave then Exit;

  if not FileExists(ChangeFileExt(GameFile, '.sav')) then
  begin
    Clear;
    SaveFile(aPointer);
  end;
  S := TMemoryStream.Create;
  try
    S.LoadFromFile(ChangeFileExt(GameFile, '.sav'));

    // We need to check multiple sets of encryption variables.
    // This is due to flexi / hardcode differences, as well as
    // a Flexi bug, in older NeoLemmix versions.
    DecryptSuccess := false;

    // First, let's try decrypting the way it should be.
    if not DecryptSuccess then
    begin
      fNeoEncrypt.KeyNumber := fCodeSeed;
      fNeoEncrypt.RepKey := 7;
      if fNeoEncrypt.CheckEncrypted(S) then
      begin
        fNeoEncrypt.LoadStream(S);
        // Due to an invalid RepKey not being directly detectable, we must
        // try checking the actual contents. For the purpose of this, we'll
        // use some bytes that will ALWAYS be zero.
        S.Position := 990;
        S.Read(w, 2);
        if w = 0 then
          DecryptSuccess := true
        else
          S.LoadFromFile(ChangeFileExt(GameFile, '.sav'));
      end;
    end;

    // No luck? Let's try Flexi decryption with the old bug emulated.
    if not DecryptSuccess then
    begin
      fNeoEncrypt.KeyNumber := 50;
      fNeoEncrypt.RepKey := 7;
      if fNeoEncrypt.CheckEncrypted(S) then
      begin
        DecryptSuccess := true;
        fNeoEncrypt.LoadStream(S);
      end;
    end;

    // Still no luck? Let's try made-from-source decryption (which didn't have the bug).
    if not DecryptSuccess then
    begin
      fNeoEncrypt.KeyNumber := fCodeSeed;
      fNeoEncrypt.RepKey := 3;
      if fNeoEncrypt.CheckEncrypted(S) then
      begin
        DecryptSuccess := true;
        fNeoEncrypt.LoadStream(S);
      end;
    end;


    // At this point, if none of these have worked, we are dealing with an invalid save,
    // or one from a different game.
    if not DecryptSuccess then
    begin
      Clear;
      SaveFile(aPointer);
      Exit;
    end;

    S.Position := 0;
    S.ReadBuffer(fSaveData, SizeOf(fSaveData));
    LoadConfig(aPointer);

    SetLength(fTalismanData, 0); // erase any existing data. otherwise, it may get duplicated, then the first one is read, and thus determines achievement has not been unlocked
    while (S.Read(TempTalis, SizeOf(TempTalis)) = SizeOf(TempTalis)) do
      if CheckValidTalisman(TempTalis.TalSignature) then
      begin
        SetLength(fTalismanData, Length(fTalismanData) + 1);
        fTalismanData[Length(fTalismanData)-1] := TempTalis;
      end;

    SetLength(fTalismanData, fTalismans.Count);
    AddMissingTalismans;
  finally
    S.Free;
  end;


end;

procedure TNeoSave.AddMissingTalismans;
var
  i, i2: Integer;
  found: Boolean;
begin
  for i := 0 to fTalismans.Count-1 do
  begin
    found := false;
    for i2 := 0 to Length(fTalismanData)-1 do
      if fTalismanData[i2].TalSignature = fTalismans[i].Signature then Found := true;
    if found = false then
      for i2 := 0 to Length(fTalismanData)-1 do
        if fTalismanData[i2].TalSignature = 0 then
        begin
          fTalismanData[i2].TalSignature := fTalismans[i].Signature;
          Break;
        end;
  end;
end;

function TNeoSave.CheckTalisman(aSig: Cardinal): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Length(fTalismanData)-1 do
    if fTalismanData[i].TalSignature = aSig then
    begin
      Result := fTalismanData[i].Acheived <> 0;
      Exit;
    end;
end;

procedure TNeoSave.GetTalisman(aSig: Cardinal);
var
  i, i2: Integer;
begin
  for i := 0 to Length(fTalismanData)-1 do
    if fTalismanData[i].TalSignature = aSig then
    begin
      fTalismanData[i].Acheived := 1;
      for i2 := 0 to fTalismans.Count-1 do
        if (fTalismans[i2].Signature = aSig) and (tmUnlockLevel in fTalismans[i].MiscOptions) then UnlockLevel(fTalismans[i].UnlockRank, fTalismans[i].UnlockLevel);
    end;
end;

end.
