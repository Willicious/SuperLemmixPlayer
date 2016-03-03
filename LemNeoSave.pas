{$include lem_directives.inc}
unit LemNeoSave;

interface

uses
  SharedGlobals,
  Dialogs,
  Classes, SysUtils, LemTypes, LemDosStructures,
  LemNeoEncryption, TalisData;

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
    function GetScoreRecord(aSection, aLevel: Integer): Integer;
    procedure SetScoreRecord(aSection, aLevel, aValue: Integer);
    procedure SaveFile(aPointer: Pointer);
    procedure LoadFile(aPointer: Pointer);
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
  fSaveData.Config.ForceSkillset := p.ForceSkillset;
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
    p.ForceSkillset := ForceSkillset;
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

function TNeoSave.GetScoreRecord(aSection, aLevel: Integer): Integer;
begin
  Result := fSaveData.RecordTable[aSection][aLevel].BestScore;
end;

procedure TNeoSave.SetScoreRecord(aSection, aLevel, aValue: Integer);
var
  p : ^word;
begin
  p := @fSaveData.RecordTable[aSection][aLevel].BestScore;
  if aValue > p^ then p^ := aValue;
end;

procedure TNeoSave.SaveFile(aPointer: Pointer);
var
  S : TMemoryStream;
  i: Integer;
begin
  //if TDosGameParams(aPointer).fTestMode then Exit; // this line was giving false positives and needed an urgent fix so kludge time!
  //if (ParamStr(0) = 'testmode')
  //or (GameFile = 'Single Levels') then
  //  Exit;
  if fDisableSave then Exit;

  // Make sure keys are set for *correct* behaviour
  fNeoEncrypt.KeyNumber := fCodeSeed;
  fNeoEncrypt.RepKey := 7;

  UpdateConfig(aPointer);
  S := TMemoryStream.Create;
  try
    S.SetSize(SizeOf(fSaveData));
    S.WriteBuffer(fSaveData, S.Size);
    for i := 0 to Length(fTalismanData)-1 do
      S.Write(fTalismanData[i], SizeOf(fTalismanData[i]));
    //S.SaveToFile(ChangeFileExt(GameFile, '.sav'));
    fNeoEncrypt.SaveFile(S, ChangeFileExt(GameFile, '.sav'));
  finally
    S.Free;
  end;
end;

procedure TNeoSave.LoadFile(aPointer: Pointer);
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
