unit TalisData;

interface

uses
  SysUtils, Classes, StrUtils, Contnrs;

const
  tls_Walker = 0;
  tls_Climber = 1;
  tls_Swimmer = 2;
  tls_Floater = 3;
  tls_Glider = 4;
  tls_Mechanic = 5;
  tls_Bomber = 6;
  tls_Stoner = 7;
  tls_Blocker = 8;
  tls_Platformer = 9;
  tls_Builder = 10;
  tls_Stacker = 11;
  tls_Basher = 12;
  tls_Miner = 13;
  tls_Digger = 14;
  tls_Cloner = 15;
  tls_Fencer = 16;

  tls_FormatVersion = 1;
  tls_Signature = $E39F;

type

  TalismanMiscOpts = (tmFindSecret, tmOneSkill, tmOneLemming, tmUnlockLevel,
                      tmRestrictFencer, tm5, tm6, tm7,
                      tm8, tm9, tm10, tm11,
                      tm12, tm13, tm14, tm15,
                      tm16, tm17, tm18, tm19,
                      tm20, tm21, tm22, tm23,
                      tm24, tm25, tm26, tm27,
                      tm28, tm29, tm30, tm31);
  TalismanMisc = set of TalismanMiscOpts;

  TalismanHeaderRec = packed record
    Version            : Byte;
    Signature          : Word;
    Reserved           : Array[0..12] of Byte;
  end;


  TalismanRec = packed record
    Color              : Byte;
    RankNumber         : Byte;
    LevelNumber        : Byte;
    SaveRequirement    : Word;
    TimeLimit          : Word;
    AppliedSkillLimits : Word;
    SkillLimits        : Array[0..15] of Byte;
    RRMinimum          : Byte;
    RRMaximum          : Byte;
    TotalSkillLimit    : Word;
    MiscOptions        : LongWord;
    UnlockRank         : Byte;
    UnlockLevel        : Byte;
    FencerLimit        : Byte;
    Reserved           : Array[0..7] of Byte;
    Signature          : LongWord;
    Description        : Array[0..63] of AnsiChar;
  end;


  TTalisman = class
    private
      fTalismanType: Integer;
      fDescription: String;
      fRankNumber: Integer;
      fLevelNumber: Integer;
      fSaveRequirement: Integer;
      fTimeLimit: Integer;
      fRRMin: Integer;
      fRRMax: Integer;
      fTotalSkillLimit: Integer;
      fUnlockRank: Integer;
      fUnlockLevel: Integer;
      fMiscOptions: TalismanMisc;
      fSignature: Cardinal;
    public
      SkillLimit: Array[0..16] of Integer;
      constructor Create;
      destructor Destroy; override; // just in case this is needed at a later date
      procedure Assign(aValue: TTalisman);
      procedure LoadFromLevelStream(aStream: TStream);
      procedure LoadFromLevelFile(aFile: String);
      property TalismanType: Integer read fTalismanType write fTalismanType;
      property Description: String read fDescription write fDescription;
      property RankNumber: Integer read fRankNumber write fRankNumber;
      property LevelNumber: Integer read fLevelNumber write fLevelNumber;
      property SaveRequirement: Integer read fSaveRequirement write fSaveRequirement;
      property TimeLimit: Integer read fTimeLimit write fTimeLimit;
      property RRMin: Integer read fRRMin write fRRMin;
      property RRMax: Integer read fRRMax write fRRMax;
      property TotalSkillLimit: Integer read fTotalSkillLimit write fTotalSkillLimit;
      property UnlockRank: Integer read fUnlockRank write fUnlockRank;
      property UnlockLevel: Integer read fUnlockLevel write fUnlockLevel;
      property MiscOptions: TalismanMisc read fMiscOptions write fMiscOptions;
      property Signature: Cardinal read fSignature write fSignature;
  end;

  TTalismans = class(TObjectList)
  private
    fVisibleCount: Integer;
    function GetVisibleCount: Integer;
    function GetItem(Index: Integer): TTalisman;
  public
    constructor Create;
    constructor CreateFromFile(aFile: String);
    constructor CreateFromStream(aStream: TStream);
    procedure LoadFromStream(aStream: TStream);
    procedure SaveToStream(aStream: TStream);
    procedure LoadFromFile(aFile: String);
    procedure SaveToFile(aFile: String);
    function Add: TTalisman; overload;
    function Add(Item: TTalisman): Integer; overload;
    function Insert(Index: Integer): TTalisman; overload;
    procedure Insert(Index: Integer; Item: TTalisman); overload;
    procedure SortTalismans;
    property Items[Index: Integer]: TTalisman read GetItem; default;
    property List;
    property VisibleCount: Integer read GetVisibleCount;
  end;

  function TalismanOrderCompare(Item1, Item2: Pointer): Integer;

implementation

// Misc

function TalismanOrderCompare(Item1, Item2: Pointer): Integer;
var
  i1, i2: TTalisman;
begin
  i1 := TTalisman(Item1);
  i2 := TTalisman(Item2);

  Result := i1.TalismanType - i2.TalismanType;
  if (i1.TalismanType = 0) and (i2.TalismanType <> 0) then Result := 1;
  if (i1.TalismanType <> 0) and (i2.TalismanType = 0) then Result := -1;
  if Result <> 0 then Exit;

  Result := i1.RankNumber - i2.RankNumber;
  if Result <> 0 then Exit;

  Result := i1.LevelNumber - i2.LevelNumber;
  if Result <> 0 then Exit;

  Result := CompareStr(i1.Description, i2.Description);
end;

// TTalismans (Collection)

constructor TTalismans.Create;
begin
  inherited;
  fVisibleCount := -1;
end;

constructor TTalismans.CreateFromFile(aFile: String);
begin
  Create;
  LoadFromFile(aFile);
end;

constructor TTalismans.CreateFromStream(aStream: TStream);
begin
  Create;
  LoadFromStream(aStream);
end;

procedure TTalismans.SortTalismans;
begin
  Sort(@TalismanOrderCompare);
end;

procedure TTalismans.LoadFromStream(aStream: TStream);
var
  HeaderRec: TalismanHeaderRec;
  DataRec:   TalismanRec;
  i: Integer;
begin
  i := aStream.Read(HeaderRec, SizeOf(TalismanHeaderRec));
  if (i <> SizeOf(TalismanHeaderRec)) or (HeaderRec.Signature <> tls_Signature) then
    raise Exception.Create('Talisman file is invalid.');
  Clear;
  while (aStream.Read(DataRec, SizeOf(TalismanRec)) = SizeOf(TalismanRec)) do
    with Add do
    begin
      TalismanType := DataRec.Color;
      Description := Trim(DataRec.Description);
      RankNumber := DataRec.RankNumber;
      LevelNumber := DataRec.LevelNumber;
      SaveRequirement := DataRec.SaveRequirement;
      TimeLimit := DataRec.TimeLimit;
      RRMin := DataRec.RRMinimum;
      RRMax := DataRec.RRMaximum;
      for i := 0 to 15 do
        if (DataRec.AppliedSkillLimits and (1 shl i)) <> 0 then
          SkillLimit[i] := DataRec.SkillLimits[i]
        else
          SkillLimit[i] := -1;
      if tmRestrictFencer in TalismanMisc(DataRec.MiscOptions) then
        SkillLimit[16] := DataRec.FencerLimit
      else
        SkillLimit[16] := -1;
      TotalSkillLimit := DataRec.TotalSkillLimit;
      if TotalSkillLimit = 65535 then TotalSkillLimit := -1;
      UnlockRank := DataRec.UnlockRank;
      UnlockLevel := DataRec.UnlockLevel;
      MiscOptions := TalismanMisc(DataRec.MiscOptions) - [tmRestrictFencer];
      Signature := DataRec.Signature;
    end;
  fVisibleCount := -1;
end;

procedure TTalismans.SaveToStream(aStream: TStream);
begin
  raise Exception.Create('TTalismans.SaveToStream called');
end;

procedure TTalismans.LoadFromFile(aFile: String);
var
  TempStream: TFileStream;
begin
  TempStream := TFileStream.Create(aFile, fmOpenRead);
  try
    TempStream.Seek(0, soFromBeginning);
    LoadFromStream(TempStream);
  finally
    TempStream.Free;
  end;
end;

procedure TTalismans.SaveToFile(aFile: String);
var
  TempStream: TFileStream;
begin
  TempStream := TFileStream.Create(aFile, fmCreate);
  try
    TempStream.Seek(0, soFromBeginning);
    SaveToStream(TempStream);
  finally
    TempStream.Free;
  end;
end;

function TTalismans.Add: TTalisman;
begin
  Result := TTalisman.Create;
  Add(Result);
end;

function TTalismans.Add(Item: TTalisman): Integer;
begin
  Result := inherited Add(Item);
  fVisibleCount := -1;
end;

function TTalismans.GetItem(Index: Integer): TTalisman;
begin
  Result := inherited Get(Index);
end;

function TTalismans.Insert(Index: Integer): TTalisman;
begin
  Result := TTalisman.Create;
  Insert(Index, Result);
end;

procedure TTalismans.Insert(Index: Integer; Item: TTalisman);
begin
  inherited Insert(Index, Item);
  fVisibleCount := -1;
end;

function TTalismans.GetVisibleCount: Integer;
var
  i: Integer;
begin
  if fVisibleCount <> -1 then
  begin
    Result := fVisibleCount;
    Exit;
  end;
  Result := 0;
  for i := 0 to Count-1 do
    if Items[i].fTalismanType <> 0 then Result := Result + 1;
  fVisibleCount := Result;
end;

// TTalisman  (Item)

constructor TTalisman.Create;
var
  i: Integer;
begin
  inherited;
  fTalismanType := 1;
  fRankNumber := 0;
  fLevelNumber := 0;
  fSaveRequirement := 0;
  fTimeLimit := 0;
  fRRMin := 1;
  fRRMax := 99;
  for i := 0 to 15 do
    SkillLimit[i] := -1;
  fDescription := '(No description provided)';
  fTotalSkillLimit := -1;
  fSignature := 0;
  fMiscOptions := [];
  fUnlockRank := 0;
  fUnlockLevel := 0;
end;

destructor TTalisman.Destroy;
begin
  inherited;
end;

procedure TTalisman.Assign(aValue: TTalisman);
var
  i: Integer;
begin
  fTalismanType := aValue.TalismanType;
  fDescription := aValue.Description;
  fRankNumber := aValue.RankNumber;
  fLevelNumber := aValue.LevelNumber;
  fSaveRequirement := aValue.SaveRequirement;
  fTimeLimit := aValue.TimeLimit;
  fRRMin := aValue.RRMin;
  fRRMax := aValue.RRMax;
  fTotalSkillLimit := aValue.TotalSkillLimit;
  fSignature := aValue.Signature;
  for i := 0 to 16 do
    SkillLimit[i] := aValue.SkillLimit[i];
  fUnlockRank := aValue.UnlockRank;
  fUnlockLevel := aValue.UnlockLevel;
  fMiscOptions := aValue.MiscOptions;
end;

procedure TTalisman.LoadFromLevelStream(aStream: TStream);
// Should really use level records and stuff. But since this only
// needs a very select few bytes, it's easier to just hardcode the shit.
var
  b: Byte;
  w: Word;
  i: Integer;
  adj: Integer;
begin
  aStream.Seek(0, soFromBeginning);
  aStream.ReadBuffer(b, 1);
  if b = 0 then
  begin
    // don't really need to support this format at all. but just in case, it's supported
    // as far as traditional Lemmix goes; the NeoLemmix additions are not since they're
    // no longer supported at all in the Player

    aStream.Seek(4, soFromBeginning); // same place in all formats actually, but easier to split it up before this
    aStream.ReadBuffer(w, 2);
    w := ((w and $FF00) shr 8) + ((w and $FF) shl 8); // different endianness
    SaveRequirement := w;

    aStream.Seek(1, soFromBeginning);
    aStream.ReadBuffer(b, 1);
    RRMin := b;
    RRMax := 99;

    aStream.Seek(7, soFromBeginning);
    aStream.ReadBuffer(b, 1);
    if b > 64 then
      TimeLimit := 0
    else
      TimeLimit := b * 60 * 17;

    for i := 0 to 15 do
      SkillLimit[i] := 0;

    // somewhat kludgy code to avoid repeated seeks or endian-fixes
    aStream.Seek(9, soFromBeginning);
    aStream.ReadBuffer(w, 2);
    SkillLimit[1] := w and $FF; //climber
    aStream.ReadBuffer(w, 2);
    SkillLimit[3] := w and $FF; //floater
    aStream.ReadBuffer(w, 2);
    SkillLimit[6] := w and $FF; //bomber
    aStream.ReadBuffer(w, 2);
    SkillLimit[8] := w and $FF; //blocker
    aStream.ReadBuffer(w, 2);
    SkillLimit[10] := w and $FF; //builder
    aStream.ReadBuffer(w, 2);
    SkillLimit[12] := w and $FF; //basher
    aStream.ReadBuffer(w, 2);
    SkillLimit[13] := w and $FF; //miner
    aStream.ReadBuffer(w, 2);
    SkillLimit[14] := w and $FF; //digger
  end else begin
    if b >= 5 then
      adj := 4 //adjust for extra bytes in screen start positions
    else
      adj := 0;
    aStream.Seek(4, soFromBeginning);
    aStream.ReadBuffer(w, 2);
    SaveRequirement := w;

    aStream.Seek(6, soFromBeginning);
    aStream.ReadBuffer(w, 2);
    if w > 3855 then // 6000+ = infinite time, but talisman data format can't handle a value this high due to
                     //         using a frame count rather than a seconds count. max is 64mins 15secs exactly.
      TimeLimit := 0
    else
      TimeLimit := w * 17;

    aStream.Seek(8, soFromBeginning);
    aStream.ReadBuffer(b, 1);
    RRMin := b;
    RRMax := 99;

    aStream.Seek(36+adj, soFromBeginning); // only this byte is far enough in to need the adjustment
    aStream.ReadBuffer(w, 2);
    for i := 0 to 15 do
      if (w and (1 shl (15 - i))) = 0 then
        SkillLimit[i] := 0
      else begin
        aStream.Seek(16+adj + i, soFromBeginning);
        aStream.Read(b, 1);
        if b > 99 then
          SkillLimit[i] := -1 //infinite
        else
          SkillLimit[i] := b;
      end;
  end;
end;

procedure TTalisman.LoadFromLevelFile(aFile: String);
var
  TempStream: TFileStream;
begin
  TempStream := TFileStream.Create(aFile, fmOpenRead);
  try
    LoadFromLevelStream(TempStream);
    aFile := ChangeFileExt(aFile, '');
    if (StrToIntDef(LeftStr(aFile, 2), -1) <> -1) and (StrToIntDef(RightStr(aFile, Length(aFile)-2), -1) <> -1) then
    begin
      RankNumber := StrToInt(LeftStr(aFile, 2));
      LevelNumber := StrToInt(RightStr(aFile, Length(aFile)-2));
    end;
  finally
    TempStream.Free;
  end;
end;

end.
