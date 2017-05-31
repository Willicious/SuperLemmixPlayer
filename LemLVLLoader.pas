{$include lem_directives.inc}
unit LemLVLLoader;

interface

uses
  Classes, SysUtils, StrUtils,
  //Dialogs, Controls,
  //LemNeoLevelLoader,
  Dialogs,
  UMisc,
  Math,
  LemStrings,
  LemNeoParser,
  LemPiece,
  LemTerrain,
  LemInteractiveObject,
  LemSteel,
  LemDosStructures,
  LemLevel,
  LemLemming,
  LemTypes,
  LemCore;

type
  TWindowOrder = array of Integer;

  TStyleName = class
  private
    fStyleName : ShortString;
    fID : Byte;
    fSpecial : Boolean;
  protected
  public
    constructor Create(aTag: ShortString; aID: Byte; aSpec: Boolean = false);
  published
    property StyleName : ShortString read fStyleName;
    property ID: Byte read fID;
    property Special: Boolean read fSpecial;
  end;

  TStyleFinder = class
  private
    fStyleList : TList;
    //fSysDat: TSysDatRec;
    procedure InitList;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    function FindNumber(tag: ShortString; spec: Boolean): Integer;
    function FindName(id: Byte; spec: Boolean): ShortString;
  published
  end;

  TMusicName = class
  private
    fMusicName: ShortString;
    fID: Byte;
  public
    constructor Create(aTag: ShortString; aID: Byte);
  published
    property MusicName: ShortString read fMusicName;
    property ID: Byte read fID;
  end;

  TMusicFinder = class
  private
    fMusicList : TList;
    procedure InitList;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    function FindNumber(tag: ShortString): Integer;
    function FindName(id: Byte): ShortString;
  published
  end;

  TTranslationItemType = (itTerrain, itObject, itBackground);
  TTranslationItem = record
    ItemType: TTranslationItemType;
    SrcGS: String;
    SrcName: String;
    DstGS: String;
    DstName: String;
    Width: Integer;
    Height: Integer;
    OffsetL: Integer;
    OffsetT: Integer;
    OffsetR: Integer;
    OffsetB: Integer;
    Flip: Boolean;
    Invert: Boolean;
    Rotate: Boolean;
    PickupPatch: Boolean;
  end;

  TTranslationTable = class
    private
      fCurrentSet: String;
      fCurrentPos: Integer;
      fThemeChange: TStringList;
      fMatchArray: array of TTranslationItem;
      procedure LoadEntry(aSec: TParserSection; const aIteration: Integer);
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure LoadForGS(aSet: String);
      procedure Apply(aLevel: TLevel);
  end;

  TLVLLoader = class
  private
    class procedure UpgradeFormat(var Buf: TNeoLVLRec);
    class procedure ApplyWindowOrder(aLevel: TLevel; WindowOrder: TWindowOrder);
  protected
  public
    class procedure LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadTradLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadNewNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure StoreLevelInStream(aLevel: TLevel; aStream: TStream);
  end;

implementation

{ TTranslationTable }

constructor TTranslationTable.Create;
begin
  inherited;
  SetLength(fMatchArray, 0);
  fThemeChange := TStringList.Create;
end;

destructor TTranslationTable.Destroy;
begin
  fThemeChange.Free;
  inherited;
end;

procedure TTranslationTable.Clear;
begin
  SetLength(fMatchArray, 0);
  fThemeChange.Clear;
end;

procedure TTranslationTable.LoadEntry(aSec: TParserSection; const aIteration: Integer);
var
  NewItem: TTranslationItem;
begin
  if aSec.Keyword = 'object' then NewItem.ItemType := itObject;
  if aSec.Keyword = 'terrain' then NewItem.ItemType := itTerrain;
  if aSec.Keyword = 'background' then NewItem.ItemType := itBackground;

  NewItem.SrcGS := Lowercase(fCurrentSet);
  NewItem.SrcName := aSec.LineTrimString['index'];
  NewItem.DstGS := aSec.LineTrimString['collection'];
  NewItem.DstName := aSec.LineTrimString['piece'];

  if Lowercase(aSec.LineTrimString['special']) = 'lemming' then
    NewItem.DstName := '*lemming';

  NewItem.Width := aSec.LineNumeric['width'];
  NewItem.Height := aSec.LineNumeric['height'];

  NewItem.OffsetL := aSec.LineNumeric['left_offset'];
  NewItem.OffsetR := aSec.LineNumeric['right_offset'];
  NewItem.OffsetT := aSec.LineNumeric['top_offset'];
  NewItem.OffsetB := aSec.LineNumeric['bottom_offset'];

  NewItem.Rotate := aSec.Line['rotate'] <> nil;
  NewItem.Flip := aSec.Line['flip_horizontal'] <> nil;
  NewItem.Invert := aSec.Line['flip_vertical'] <> nil;

  NewItem.PickupPatch := aSec.Line['pickup_patch'] <> nil;

  fMatchArray[fCurrentPos] := NewItem;
  Inc(fCurrentPos);
end;

procedure TTranslationTable.LoadForGS(aSet: String);
var
  Parser: TParser;
  TotalEntries: Integer;
begin
  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFDataTranslation + aSet + '.nxtt');
    fCurrentSet := aSet;

    if Parser.MainSection.Line['theme'] <> nil then
      fThemeChange.Values[aSet] := Parser.MainSection.Line['theme'].ValueTrimmed;

    TotalEntries := Length(fMatchArray);
    fCurrentPos := TotalEntries;
    SetLength(fMatchArray, Length(fMatchArray) + Parser.MainSection.SectionList.Count);

    TotalEntries := TotalEntries + Parser.MainSection.DoForEachSection('terrain', LoadEntry);
    TotalEntries := TotalEntries + Parser.MainSection.DoForEachSection('object', LoadEntry);
    TotalEntries := TotalEntries + Parser.MainSection.DoForEachSection('background', LoadEntry);

    SetLength(fMatchArray, TotalEntries);
  finally
    Parser.Free;
  end;
end;

procedure TTranslationTable.Apply(aLevel: TLevel);
var
  i: Integer;
  MatchIndex: Integer;
  MatchRec: TTranslationItem;

  T: TTerrain;
  O: TInteractiveObject;
  L: TPreplacedLemming;

  PatchL, PatchT: Integer;

  procedure LoadTables;
  var
    i: Integer;
    SetList: array of String;

    procedure AddToList(aValue: String);
    var
      i: Integer;
    begin
      aValue := Lowercase(Trim(aValue));
      for i := 0 to Length(SetList)-1 do
        if SetList[i] = aValue then Exit;
      SetLength(SetList, Length(SetList)+1);
      SetList[Length(SetList)-1] := aValue;
    end;
  begin
    Clear;
    AddToList(aLevel.Info.GraphicSetName);
    for i := 0 to aLevel.Terrains.Count-1 do
      AddToList(aLevel.Terrains[i].GS);
    for i := 0 to aLevel.InteractiveObjects.Count-1 do
      AddToList(aLevel.InteractiveObjects[i].GS);

    for i := 0 to Length(SetList)-1 do
      LoadForGS(SetList[i]);
  end;

  function FindMatchIndex(aCollection, aName: String; aType: TTranslationItemType): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to Length(fMatchArray)-1 do
      if (fMatchArray[i].SrcGS = aCollection) and (fMatchArray[i].SrcName = aName) and (fMatchArray[i].ItemType = aType) then
      begin
        Result := i;
        MatchRec := fMatchArray[i];
        Exit;
      end;
  end;

  procedure SetPatchValues(Flip, Invert, Rotate: Boolean);
  begin
    if Rotate then
    begin
      if Flip then
        PatchL := MatchRec.OffsetT
      else
        PatchL := MatchRec.OffsetB;
      if Invert then
        PatchT := MatchRec.OffsetR
      else
        PatchT := MatchRec.OffsetL;
    end else begin
      if Flip then
        PatchL := MatchRec.OffsetR
      else
        PatchL := MatchRec.OffsetL;
      if Invert then
        PatchT := MatchRec.OffsetB
      else
        PatchT := MatchRec.OffsetT;
    end;
  end;
begin
  LoadTables;

  if fThemeChange.Values[aLevel.Info.GraphicSetName] <> '' then
    aLevel.Info.GraphicSetName := fThemeChange.Values[aLevel.Info.GraphicSetName];

  for i := 0 to aLevel.Terrains.Count-1 do
  begin
    T := aLevel.Terrains[i];
    MatchIndex := FindMatchIndex(Lowercase(T.GS), T.Piece, itTerrain);
    if MatchIndex = -1 then
    begin
      T.Piece := '*nil';
      Continue;
    end;

    T.GS := MatchRec.DstGS;
    T.Piece := MatchRec.DstName;

    SetPatchValues(T.Flip, T.Invert, T.Rotate);
    T.Left := T.Left + PatchL;
    T.Top := T.Top + PatchT;

    if T.Rotate and MatchRec.Rotate then
      T.Invert := not T.Invert;

    T.Rotate := T.Rotate xor MatchRec.Rotate;
    T.Flip := T.Flip xor MatchRec.Flip;
    T.Invert := T.Invert xor MatchRec.Invert;
  end;

  for i := aLevel.Terrains.Count-1 downto 0 do
    if aLevel.Terrains[i].Piece = '*nil' then
      aLevel.Terrains.Delete(i);

  for i := 0 to aLevel.InteractiveObjects.Count-1 do
  begin
    O := aLevel.InteractiveObjects[i];
    MatchIndex := FindMatchIndex(Lowercase(O.GS), O.Piece, itObject);
    if MatchIndex = -1 then
    begin
      O.Piece := '*nil';
      Continue;
    end;

    O.GS := MatchRec.DstGS;
    O.Piece := MatchRec.DstName;

    SetPatchValues(O.Flip, O.Invert, O.Rotate);
    O.Left := O.Left + PatchL;
    O.Top := O.Top + PatchT;

    if O.Rotate and MatchRec.Rotate then
      O.Invert := not O.Invert;

    O.Rotate := O.Rotate xor MatchRec.Rotate;
    O.Flip := O.Flip xor MatchRec.Flip;
    O.Invert := O.Invert xor MatchRec.Invert;

    if O.Rotate then
    begin
      O.Width := MatchRec.Height;
      O.Height := MatchRec.Width;
    end else begin
      O.Width := MatchRec.Width;
      O.Height := MatchRec.Height;
    end;

    if MatchRec.PickupPatch then
    begin
      // because pickup skill S Values are now ordered more logically
      case O.Skill + (O.TarLev * 16) of
        0: O.Skill := Integer(spbClimber);
        1: O.Skill := Integer(spbFloater);
        2: O.Skill := Integer(spbBomber);
        3: O.Skill := Integer(spbBlocker);
        4: O.Skill := Integer(spbBuilder);
        5: O.Skill := Integer(spbBasher);
        6: O.Skill := Integer(spbMiner);
        7: O.Skill := Integer(spbDigger);
        8: O.Skill := Integer(spbWalker);
        9: O.Skill := Integer(spbSwimmer);
        10: O.Skill := Integer(spbGlider);
        11: O.Skill := Integer(spbDisarmer);
        12: O.Skill := Integer(spbStoner);
        13: O.Skill := Integer(spbPlatformer);
        14: O.Skill := Integer(spbStacker);
        15: O.Skill := Integer(spbCloner);
        16: O.Skill := Integer(spbFencer);
        // else raise exception?
      end;
    end;
  end;

  for i := aLevel.InteractiveObjects.Count-1 downto 0 do
  begin
    O := aLevel.InteractiveObjects[i];

    if O.Piece = '*lemming' then
    begin
      L := aLevel.PreplacedLemmings.Insert(0);
      L.X := O.Left;
      L.Y := O.Top;
      if O.DrawingFlags and odf_FlipLem <> 0 then
        L.Dx := -1
      else
        L.Dx := 1;
      L.IsClimber := O.TarLev and 1 <> 0;
      L.IsSwimmer := O.TarLev and 2 <> 0;
      L.IsFloater := O.TarLev and 4 <> 0;
      L.IsGlider := O.TarLev and 8 <> 0;
      L.IsDisarmer := O.TarLev and 16 <> 0;
      L.IsBlocker := O.TarLev and 32 <> 0;
      L.IsZombie := O.TarLev and 64 <> 0;

      O.Piece := '*nil';
    end;

    if O.Piece = '*nil' then
      aLevel.InteractiveObjects.Delete(i);
  end;

  MatchIndex := FindMatchIndex(Lowercase(aLevel.Info.GraphicSetName), aLevel.Info.Background, itBackground);
  if MatchIndex = -1 then
    aLevel.Info.Background := ''
  else
    aLevel.Info.Background := MatchRec.DstGS + ':' + MatchRec.DstName;
end;

{ TStyleName }

constructor TStyleName.Create(aTag: ShortString; aID: Byte; aSpec: Boolean = false);
begin
  inherited Create;
  fStyleName := trim(lowercase(leftstr(aTag, 16)));
  fID := aID;
  fSpecial := aSpec;
end;

{ TMusicName }

constructor TMusicName.Create(aTag: ShortString; aID: Byte);
begin
  inherited Create;
  fMusicName := trim(lowercase(leftstr(aTag, 16)));
  fID := aID;
end;

{ TStyleFinder }

constructor TStyleFinder.Create;
begin
  InitList;
end;

destructor TStyleFinder.Destroy;
begin
  fStyleList.Free;
  inherited Destroy;
end;

procedure TStyleFinder.InitList;
//var
  //i: Integer;
  //fMainDatExtractor : TMainDatExtractor;

  procedure Sty(tag: ShortString; ID: byte; Spec: boolean = false);
  var
    SN : TStyleName;
  begin
    SN := TStyleName.Create(tag, ID, Spec);
    fStyleList.Add(SN);
  end;

begin
  fStyleList := TList.Create;
    Sty('dirt',         0);
    Sty('fire',         1);
    Sty('marble',       2);
    Sty('pillar',       3);
    Sty('crystal',      4);
    Sty('brick',        5);
    Sty('rock',         6);
    Sty('snow',         7);
    Sty('bubble',       8);
    Sty('xmas',         9);
    Sty('tree',        10);
    Sty('purple',      11);
    Sty('psychedelic', 12);
    Sty('metal',       13);
    Sty('desert',      14);
    Sty('sky',         15);
    Sty('circuit',     16);
    Sty('martian',     17);
    Sty('lab',         18);
    Sty('sega',        19);
    Sty('dirt_md',     20);
    Sty('fire_md',     21);
    Sty('marble_md',   22);
    Sty('pillar_md',   23);
    Sty('crystal_md',  24);
    Sty('horror',      25);
end;

function TStyleFinder.FindNumber(tag: ShortString; Spec: Boolean): Integer;
var
  i: Integer;
  SN: TStyleName;
begin
  tag := trim(lowercase(leftstr(tag, 16)));
  for i := 0 to fStyleList.Count - 1 do
  begin
    SN := TStyleName(fStyleList[i]);
    if SN.Special <> Spec then Continue;
    if SN.StyleName <> tag then Continue;
    Result := SN.ID;
    Exit;
  end;
  Result := -1;
end;

function TStyleFinder.FindName(ID: byte; Spec: Boolean): ShortString;
var
  i: Integer;
  SN: TStyleName;
begin
  for i := 0 to fStyleList.Count - 1 do
  begin
    SN := TStyleName(fStyleList[i]);
    if SN.Special <> Spec then Continue;
    if SN.ID <> ID then Continue;
    Result := SN.StyleName;
    Exit;
  end;
  Result := '';
end;

{ TMusicFinder }

constructor TMusicFinder.Create;
begin
  InitList;
end;

destructor TMusicFinder.Destroy;
begin
  fMusicList.Free;
  inherited Destroy;
end;

procedure TMusicFinder.InitList;

  procedure Mus(tag: ShortString; ID: byte);
  var
    SN : TMusicName;
  begin
    SN := TMusicName.Create(tag, ID);
    fMusicList.Add(SN);
  end;

begin
  fMusicList := TList.Create;
end;

function TMusicFinder.FindNumber(tag: ShortString): Integer;
var
  i: Integer;
  SN: TMusicName;
begin
  tag := trim(lowercase(leftstr(tag, 16)));
  for i := 0 to fMusicList.Count - 1 do
  begin
    SN := TMusicName(fMusicList[i]);
    if SN.MusicName <> tag then Continue;
    Result := SN.ID;
    Exit;
  end;
  Result := -1;
end;

function TMusicFinder.FindName(ID: byte): ShortString;
var
  i: Integer;
  SN: TMusicName;
begin
  for i := 0 to fMusicList.Count - 1 do
  begin
    SN := TMusicName(fMusicList[i]);
    if SN.ID <> ID then Continue;
    Result := SN.MusicName;
    Exit;
  end;
  Result := '';
end;

{ TLVLLoader }

class procedure TLVLLoader.LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
var
  b: byte;
  i, i2: integer;
  NewLevelID: Integer;
  //TempStream: TMemoryStream;
  //TempLevel: TLevel;
  Trans: TTranslationTable;
begin
  aStream.Seek(0, soFromBeginning);
  aStream.Read(b, 1);
  aStream.Seek(0, soFromBeginning);

  aLevel.Clear;

  case b of
    0: LoadTradLevelFromStream(aStream, aLevel);
  1..3: LoadNeoLevelFromStream(aStream, aLevel);
    4: LoadNewNeoLevelFromStream(aStream, aLevel);
    else aLevel.LoadFromStream(aStream);
  end;

  if (b <= 4) then
    aLevel.Info.HasTimeLimit := aLevel.Info.TimeLimit < 6000;

  // if the level has no Level ID, make one.
  // must be pseudo-random to enough extent to generate a different ID for each level,
  // but the same ID for the same level if unmodified

  i2 := 0;
  while aLevel.Info.LevelID = 0 do
  begin
    NewLevelID := aLevel.Info.LevelID;
    Inc(i2);
    for i := 0 to aLevel.InteractiveObjects.Count-1 do
    begin
      NewLevelID := NewLevelID + aLevel.InteractiveObjects[i].Left * i2;
      NewLevelID := NewLevelID + aLevel.InteractiveObjects[i].Top * i2;
      NewLevelID := NewLevelID + aLevel.InteractiveObjects[i].DrawingFlags;
      NewLevelID := NewLevelID + aLevel.InteractiveObjects[i].Skill;
      NewLevelID := NewLevelID + aLevel.InteractiveObjects[i].TarLev;
      if NewLevelID = 0 then NewLevelID := aLevel.Info.RescueCount;
    end;

    for i := 0 to aLevel.Terrains.Count-1 do
    begin
      NewLevelID := NewLevelID + aLevel.Terrains[i].Left * i2;
      NewLevelID := NewLevelID + aLevel.Terrains[i].Top * i2;
      NewLevelID := NewLevelID + aLevel.Terrains[i].DrawingFlags;
      if NewLevelID = 0 then NewLevelID := aLevel.Info.LemmingsCount;
    end;

    for i := 0 to aLevel.Steels.Count-1 do
    begin
      NewLevelID := NewLevelID + aLevel.Steels[i].Left * i2;
      NewLevelID := NewLevelID + aLevel.Steels[i].Top * i2;
      NewLevelID := NewLevelID + aLevel.Steels[i].Width * i2;
      NewLevelID := NewLevelID + aLevel.Steels[i].Height * i2;
      NewLevelID := NewLevelID + aLevel.Steels[i].fType;
      if NewLevelID = 0 then NewLevelID := aLevel.Info.ReleaseRate;
    end;

    while (NewLevelID > 0) do
      NewLevelID := NewLevelID xor (NewLevelID shl 1);

    for i := 1 to Length(aLevel.Info.Title)-3 do
    begin
      NewLevelID := NewLevelID + (i2 * i2);
      NewLevelID := NewLevelID xor ((Ord(aLevel.Info.Title[i]) shl 24) +
                                    (Ord(aLevel.Info.Title[i+1]) shl 16) +
                                    (Ord(aLevel.Info.Title[i+2]) shl 8) +
                                    (Ord(aLevel.Info.Title[i+3])));
    end;

    NewLevelID := NewLevelID + aLevel.InteractiveObjects.Count + aLevel.Terrains.Count + aLevel.Steels.Count;

    aLevel.Info.LevelID := NewLevelID;
  end;

  if b < 5 then  // earlier in this procedure, this was used to differentiate between formats. >5 = NXLV format = does not need translation table
  begin
    aLevel.Info.LevelID := aLevel.Info.LevelID or (aLevel.Info.LevelID shl 32);

    Trans := TTranslationTable.Create;
    Trans.Apply(aLevel);
    Trans.Free;
    aLevel.Sanitize;
  end;
end;

class procedure TLVLLoader.ApplyWindowOrder(aLevel: TLevel; WindowOrder: TWindowOrder);
var
  i, i2: Integer;
  OrigCount: Integer;
  SrcO, DstO: TInteractiveObject;
begin
  OrigCount := aLevel.InteractiveObjects.Count;

  for i := 0 to Length(WindowOrder)-1 do
  begin
    SrcO := aLevel.InteractiveObjects[WindowOrder[i]];
    DstO := aLevel.InteractiveObjects.Add;
    DstO.Assign(SrcO);
  end;

  for i := OrigCount-1 downto 0 do
    for i2 := 0 to Length(WindowOrder)-1 do
      if WindowOrder[i2] = i then
      begin
        aLevel.InteractiveObjects.Delete(i);
        Break;
      end;
end;


class procedure TLVLLoader.LoadNewNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Translate a LVL file and fill the collections.
  For decoding and technical details see documentation or read the code :)
-------------------------------------------------------------------------------}
var
  Buf: TNeoLVLHeader;
  Buf2: TNeoLVLSecondHeader;
  i, x, x2: Integer;
  O: TNewNeoLVLObject;
  T: TNewNeoLVLTerrain;
  S: TNewNeoLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  //SFinder: TStyleFinder;
  GSNames: array of String;
  GSName: array[0..15] of Char;

  WindowOrder: TWindowOrder;

  b: Byte;
  w: Word;

  LRes: Byte;

  HasSubHeader: Boolean;

  SkipObjects: Array of Integer;

  procedure AddSkill(aSkill: TSkillPanelButton);
  begin
    if x2 < 8 then
      aLevel.Info.Skillset := aLevel.Info.Skillset + [aSkill];
    Inc(x2);
  end;

  procedure SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
  begin
    if not(aSkill in aLevel.Info.Skillset) then Exit;
    aLevel.Info.SkillCount[aSkill] := aCount;
  end;
begin
  SetLength(SkipObjects, 0);
  SetLength(WindowOrder, 0);
  HasSubHeader := false;
  with aLevel do
  begin
    aStream.ReadBuffer(Buf, SizeOf(Buf));
    //UpgradeFormat(Buf);
    {-------------------------------------------------------------------------------
      Get the statics. This is easy
    -------------------------------------------------------------------------------}
    with Info do
    begin
      if OddLoad <> 1 then
      begin
        aLevel.Clear;
        ReleaseRate      := Buf.ReleaseRate;
        ReleaseRateLocked := (Buf.LevelOptions2 and 1) <> 0;
        if Buf.BgIndex = $FF then
          Background := ''
        else
          Background := IntToStr(Buf.BgIndex);

        LemmingsCount    := Buf.LemmingsCount;
        RescueCount      := Buf.RescueCount;
        TimeLimit        := Buf.TimeLimit; // internal structure now matches NeoLemmix file format structure (just a number of seconds)

        x2 := 0;
        if Buf.Skillset and $8000 <> 0 then AddSkill(spbWalker);
        if Buf.Skillset and $4000 <> 0 then AddSkill(spbClimber);
        if Buf.Skillset and $2000 <> 0 then AddSkill(spbSwimmer);
        if Buf.Skillset and $1000 <> 0 then AddSkill(spbFloater);
        if Buf.Skillset and $800 <> 0 then AddSkill(spbGlider);
        if Buf.Skillset and $400 <> 0 then AddSkill(spbDisarmer);
        if Buf.Skillset and $200 <> 0 then AddSkill(spbBomber);
        if Buf.Skillset and $100 <> 0 then AddSkill(spbStoner);
        if Buf.Skillset and $80 <> 0 then AddSkill(spbBlocker);
        if Buf.Skillset and $40 <> 0 then AddSkill(spbPlatformer);
        if Buf.Skillset and $20 <> 0 then AddSkill(spbBuilder);
        if Buf.Skillset and $10 <> 0 then AddSkill(spbStacker);
        if Buf.Skillset and $8 <> 0 then AddSkill(spbBasher);
        if Buf.Skillset and $4 <> 0 then AddSkill(spbMiner);
        if Buf.Skillset and $2 <> 0 then AddSkill(spbDigger);
        if Buf.Skillset and $1 <> 0 then AddSkill(spbCloner);
        if Buf.LevelOptions2 and $2 <> 0 then AddSkill(spbFencer);

        SetSkillCount(spbWalker, Buf.WalkerCount);
        SetSkillCount(spbClimber, Buf.ClimberCount);
        SetSkillCount(spbSwimmer, Buf.SwimmerCount);
        SetSkillCount(spbFloater, Buf.FloaterCount);
        SetSkillCount(spbGlider, Buf.GliderCount);
        SetSkillCount(spbDisarmer, Buf.MechanicCount);
        SetSkillCount(spbBomber, Buf.BomberCount);
        SetSkillCount(spbStoner, Buf.StonerCount);
        SetSkillCount(spbBlocker, Buf.BlockerCount);
        SetSkillCount(spbPlatformer, Buf.PlatformerCount);
        SetSkillCount(spbBuilder, Buf.BuilderCount);
        SetSkillCount(spbStacker, Buf.StackerCount);
        SetSkillCount(spbBasher, Buf.BasherCount);
        SetSkillCount(spbMiner, Buf.MinerCount);
        SetSkillCount(spbDigger, Buf.DiggerCount);
        SetSkillCount(spbCloner, Buf.ClonerCount);
        SetSkillCount(spbFencer, Buf.FencerCount);

        Title            := Buf.LevelName;
        Author           := Buf.LevelAuthor;
        LevelID := Buf.LevelID;
      end;

      if (OddLoad = 2) and (Buf.LevelOptions and 16 <> 0) then
      begin
        LevelOptions := $71;
        LRes := 8;
      end else begin

        LRes := Buf.Resolution;
        if LRes = 0 then LRes := 8;

        Width := (Buf.Width * 8) div LRes;
        Height := (Buf.Height * 8) div LRes;


        if Width < 1 then Width := 1;
        if Height < 1 then Height := 1;

        // Screen positions are saved as a Word, i.e. unsigned. So we treat anything >32768 as negative
        if Buf.ScreenPosition > 32768 then ScreenPosition := 160
        else
        begin
          ScreenPosition   := ((Buf.ScreenPosition * 8) div LRes) + 160;
          if ScreenPosition > (Width - 160) then ScreenPosition := (Width - 160);
          if ScreenPosition < 0 then ScreenPosition := 0;
        end;
        if Buf.ScreenYPosition > 32768 then ScreenYPosition := 80
        else
        begin
          ScreenYPosition := ((Buf.ScreenYPosition * 8) div LRes) + 80;
          if ScreenYPosition > (Height - 80) then ScreenYPosition := (Height - 80);
          if ScreenYPosition < 0 then ScreenYPosition := 0;
        end;

        GraphicSetName := trim(Buf.StyleName);

        SetLength(GSNames, 1);
        GSNames[0] := GraphicSetName; // fallback in case lvl file has no graphic set list, as most won't

        LevelOptions := Buf.LevelOptions;
      end;
      if LevelOptions and $2 = 0 then
        LevelOptions := LevelOptions and $F7;
    end;

    //if (OddLoad = 2) and (Info.LevelOptions and 16 <> 0) then Exit;

    //b := 0;
    //aStream.Read(b, 1);
    while (aStream.Read(b, 1) <> 0) do
    begin
      case b of
        1: begin
             aStream.Read(O, SizeOf(O));
             if (O.ObjectFlags and 128) = 0 then
             begin
               SetLength(SkipObjects, Length(SkipObjects) + 1);
               SkipObjects[Length(SkipObjects)-1] := InteractiveObjects.Count + Length(SkipObjects) - 1;
             end else begin
             Obj := InteractiveObjects.Add;
             Obj.Left := (O.XPos * 8) div LRes;
             Obj.Top := (O.YPos * 8) div LRes;
             Obj.GS := IntToStr(O.GSIndex);
             Obj.Piece := IntToStr(O.ObjectID);
             Obj.TarLev := O.LValue;
             if O.ObjectFlags and $1 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_NoOverwrite;
             if O.ObjectFlags and $2 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_OnlyOnTerrain;
             if O.ObjectFlags and $4 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_UpsideDown;
             if O.ObjectFlags and $8 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_FlipLem;
             if O.ObjectFlags and $10 <> 0 then
               Obj.IsFake := true;
             if O.ObjectFlags and $20 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_Invisible;
             if O.ObjectFlags and $40 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_Flip;
             if O.ObjectFlags and $100 <> 0 then
               Obj.DrawingFlags := Obj.DrawingFlags or odf_Rotate;
             Obj.Skill := O.SValue mod 16;

             Obj.LastDrawX := Obj.Left;
             Obj.LastDrawY := Obj.Top;
             Obj.DrawAsZombie := false;
             end;
           end;
        2: begin
             aStream.Read(T, SizeOf(T));
             if (T.TerrainFlags and 128) <> 0 then
             begin
             Ter := Terrains.Add;
             Ter.Left := (T.XPos * 8) div LRes;
             Ter.Top := (T.YPos * 8) div LRes;
             Ter.GS := IntToStr(T.GSIndex);
             Ter.Piece := IntToStr(T.TerrainID);
             if T.TerrainFlags and $1 <> 0 then
               Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOverwrite;
             if T.TerrainFlags and $2 <> 0 then
               Ter.DrawingFlags := Ter.DrawingFlags or tdf_Erase;
             if T.TerrainFlags and $4 <> 0 then
               Ter.DrawingFlags := Ter.DrawingFlags or tdf_Invert;
             if T.TerrainFlags and $8 <> 0 then
               Ter.DrawingFlags := Ter.DrawingFlags or tdf_Flip;
             if T.TerrainFlags and $20 <> 0 then
               Ter.DrawingFlags := Ter.DrawingFlags or tdf_Rotate;
             if Info.LevelOptions and $80 = 0 then
             begin
               if T.TerrainFlags and $10 <> 0 then
                 Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOneWay;
             end else begin
               if T.TerrainFlags and $10 = 0 then
                 Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOneWay;
             end;
             end;
           end;
        3: begin
             aStream.Read(S, SizeOf(S));
             if (S.SteelFlags and 128) <> 0 then
             begin
             Steel := Steels.Add;
             Steel.Left := (S.XPos * 8) div LRes;
             Steel.Top := (S.YPos * 8) div LRes;
             Steel.Width := ((S.SteelWidth + 1) * 8) div LRes;
             Steel.Height := ((S.SteelHeight + 1) * 8) div LRes;
             Steel.fType := S.SteelFlags and not $80;
             end;
           end;
        4: begin
             SetLength(WindowOrder, 0);
             w := $FFFF;
             aStream.Read(w, 2);
             while w <> $FFFF do
             begin
               SetLength(WindowOrder, Length(WindowOrder) + 1);
               WindowOrder[Length(WindowOrder) - 1] := w;
               w := $FFFF;
               aStream.Read(w, 2);
             end;
           end;
        5: begin
             aStream.Read(Buf2, SizeOf(Buf2));
             HasSubHeader := true;
             Info.ScreenPosition := ((Buf2.ScreenPosition * 8) div LRes) + 160;
             Info.ScreenYPosition := ((Buf2.ScreenYPosition * 8) div LRes) + 80;
             with Info do
             begin
               if ScreenPosition > Width-1 then ScreenPosition := Width-1;
               if ScreenYPosition > Height-1 then ScreenYPosition := Height-1;
               if ScreenPosition < 0 then ScreenPosition := 0;
               if ScreenYPosition < 0 then ScreenYPosition := 0;
             end;
             if OddLoad <> 1 then
             begin
               Info.MusicFile := Trim(Buf2.MusicName);
             end;
           end;
        6: begin
             aStream.Read(w, 2);
             SetLength(GSNames, w);
             for i := 0 to w-1 do
             begin
               aStream.Read(GSName, 16);
               GSNames[i] := Lowercase(Trim(GSName));
             end;
           end;
        else Break;
      end;

      //b := 0;
      //aStream.Read(b, 1);
    end;

    for i := 0 to Length(SkipObjects)-1 do
      for x := 0 to Length(WindowOrder)-1 do
        if WindowOrder[x] > SkipObjects[i] then Dec(WindowOrder[x]);

    if (not HasSubHeader) and (OddLoad <> 1) then
    with Info do
      begin
        case Buf.MusicNumber of
          0: MusicFile := '';
        253: MusicFile := '*';
        254: MusicFile := 'frenzy';
        255: MusicFile := 'gimmick';
          else  MusicFile := 'track_' + LeadZeroStr(Buf.MusicNumber, 2); // best compatibility with existing packs
        end;
      end;

    (*if (OddLoad = 2) and (Info.LevelOptions and $10 <> 0) then
    begin
      InteractiveObjects.Clear;
      Terrains.Clear;
      Steels.Clear;
      SetLength(Info.WindowOrder, 0);
    end;*)

    if Length(WindowOrder) <> 0 then
      ApplyWindowOrder(aLevel, WindowOrder);

    for i := 0 to InteractiveObjects.Count-1 do
      with InteractiveObjects[i] do
        GS := GSNames[StrToInt(GS)];

    for i := 0 to Terrains.Count-1 do
      with Terrains[i] do
        GS := GSNames[StrToInt(GS)];

  end; // with aLevel
end;


class procedure TLVLLoader.LoadTradLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Translate a LVL file and fill the collections.
  For decoding and technical details see documentation or read the code :)
-------------------------------------------------------------------------------}
var
  Buf: TLVLRec;
  H, i: Integer;
  O: TLVLObject;
  T: TLVLTerrain;
  S: TLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  GraphicSet: Integer;
  SFinder: TStyleFinder;
begin
  with aLevel do
  begin

    aStream.ReadBuffer(Buf, LVL_SIZE);
    {-------------------------------------------------------------------------------
      Get the statics. This is easy
    -------------------------------------------------------------------------------}
    with Info do
    begin
      aLevel.Clear;
      ReleaseRate      := System.Swap(Buf.ReleaseRate) mod 256;
      LemmingsCount    := System.Swap(Buf.LemmingsCount);
      RescueCount      := System.Swap(Buf.RescueCount);
      TimeLimit        := (Buf.TimeMinutes * 60){ + Buf.TimeSeconds};
      Skillset := [spbClimber, spbFloater, spbBomber, spbBlocker, spbBuilder, spbBasher, spbMiner, spbDigger];
      SkillCount[spbClimber]     := System.Swap(Buf.ClimberCount) mod 256;
      SkillCount[spbFloater]     := System.Swap(Buf.FloaterCount) mod 256;
      SkillCount[spbBomber]      := System.Swap(Buf.BomberCount) mod 256;
      SkillCount[spbBlocker]     := System.Swap(Buf.BlockerCount) mod 256;
      SkillCount[spbBuilder]     := System.Swap(Buf.BuilderCount) mod 256;
      SkillCount[spbBasher]      := System.Swap(Buf.BasherCount) mod 256;
      SkillCount[spbMiner]       := System.Swap(Buf.MinerCount) mod 256;
      SkillCount[spbDigger]      := System.Swap(Buf.DiggerCount) mod 256;
      LevelOptions     := 0;
      Title            := Buf.LevelName;
      Author           := '';
      GraphicSet := System.Swap(Buf.GraphicSet);
      case (GraphicSet shr 8) and $FF of
        0: MusicFile := '';
      253: MusicFile := '*';
      254: MusicFile := 'frenzy';
      255: MusicFile := 'gimmick';
        else MusicFile := '?';
      end;
      ScreenPosition   := System.Swap(Buf.ScreenPosition) + 160;
      ScreenYPosition  := 0;
      Width := 1584;
      Height := 160;
      if ScreenPosition > (Width - 160) then ScreenPosition := (Width - 160);
      if ScreenPosition < 160 then ScreenPosition := 160;

      SFinder := TStyleFinder.Create;

      if SFinder.FindName(GraphicSet mod 256, false) <> '' then
        GraphicSetName := SFinder.FindName(GraphicSet mod 256, false);

      SFinder.Free;
    end;

    {-------------------------------------------------------------------------------
      Get the objects
    -------------------------------------------------------------------------------}
    for i := 0 to LVL_MAXOBJECTCOUNT - 1 do
    begin
      O := Buf.Objects[i];
      if O.AsInt64 = 0 then
        Continue;
      Obj := InteractiveObjects.Add;
      Obj.Left := (Integer(O.B0) shl 8 + Integer(O.B1) - 16) and not 7;
      Obj.Top := Integer(O.B2) shl 8 + Integer(O.B3);
      If Obj.Top > 32767 then Obj.Top := Obj.Top - 65536;
      Obj.GS := Info.GraphicSetName;
      Obj.Piece := IntToStr(Integer(O.B5 and 31));
      //Obj.TarLev := (O.B4);
      if O.Modifier and $80 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_NoOverwrite;
      if O.Modifier and $40 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_OnlyOnTerrain;
      {if O.Modifier and $20 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_FlipLem;}
      if O.DisplayMode = $8F then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_UpsideDown;
      //Obj.Skill := O.Modifier and $0F;
      {if (O.Modifier and $10) <> 0 then Obj.IsFake := true;}
      if (O.ObjectID <> 1) and (i >= 16) then Obj.IsFake := true;

      Obj.LastDrawX := Obj.Left;
      Obj.LastDrawY := Obj.Top;
      Obj.DrawAsZombie := false;
    end;

    {-------------------------------------------------------------------------------
      Get the terrain.
    -------------------------------------------------------------------------------}
    for i := 0 to LVL_MAXTERRAINCOUNT - 1 do
    begin
      T := Buf.Terrain[i];
      if T.D0 = $FFFFFFFF then
        Continue;
      Ter := Terrains.Add;
      Ter.Left := Integer(T.B0 and 15) shl 8 + Integer(T.B1) - 16; // 9 bits
      Ter.DrawingFlags := T.B0 shr 5; // the bits are compatible
      H := Integer(T.B2) shl 1 + Integer(T.B3 and $80) shr 7;
      if H >= 256 then
        Dec(H, 512);
      Dec(H, 4);
      Ter.Top := H;
      Ter.GS := Info.GraphicSetName;
      if T.B0 and 16 <> 0 then
        Ter.Piece := IntToStr((T.B3 and 63) + 64)
      else
        Ter.Piece := IntToStr(T.B3 and 63);
    end;

    {-------------------------------------------------------------------------------
      Get the steel.
    -------------------------------------------------------------------------------}
    for i := 0 to LVL_MAXSTEELCOUNT - 1 do
    begin
      S := Buf.Steel[i];
      //if S.D0 = 0 then
      //  Continue;
      Steel := Steels.Add;  
      Steel.Left := ((Integer(S.B0) shl 1) + (Integer(S.B1 and (1 shl 7)) shr 7)) * 4 - 16;  // 9 bits
      Steel.Top := Integer(S.B1 and not (1 shl 7)) * 4;  // bit 7 belongs to steelx
      Steel.Width := Integer(S.B2 shr 4) * 4 + 4;  // first nibble bits 4..7 is width in units of 4 pixels (and then add 4)
      Steel.Height := Integer(S.B2 and $F) * 4 + 4;  // second nibble bits 0..3 is height in units of 4 pixels (and then add 4)
      {Steel.Left := Steel.Left - (Integer(S.B3 shr 6) mod 4);
      Steel.Top := Steel.Top - (Integer(S.B3 shr 4) mod 4);
      Steel.Width := Steel.Width - (Integer(S.B3 shr 2) mod 4);
      Steel.Height := Steel.Height - (Integer(S.B3) mod 4);
      if (i >= 16) and (aLevel.Info.LevelOptions and 1 <> 0) then Steel.fType := 1 else} Steel.fType := 0;
    end;

  end; // with aLevel
end;


class procedure TLVLLoader.UpgradeFormat(var Buf: TNeoLVLRec);
var
  i: Integer;
begin
  while Buf.FormatTag < 3 do
  begin
    case Buf.FormatTag of
      1: begin
           Buf.FormatTag := 2;
           Buf.MusicNumber := Buf.ScreenPosition mod 256;
           Buf.ScreenPosition := Buf.ScreenYPosition;
           Buf.ScreenYPosition := 0;
         end;
      2: begin
           Buf.StyleName := '                ';
           Buf.VgaspecName := '                ';
           for i := 0 to 31 do
             Buf.WindowOrder[i] := 0;
           for i := 0 to 63 do
             Buf.Objects[i].AsInt64 := Buf.Objects[i * 2].AsInt64;
           for i := 64 to 127 do
             Buf.Objects[i].AsInt64 := 0;
           Buf.FormatTag := 3;
         end;
    end;
  end;
end;


class procedure TLVLLoader.LoadNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Translate a LVL file and fill the collections.
  For decoding and technical details see documentation or read the code :)
-------------------------------------------------------------------------------}
var
  Buf: TNeoLVLRec;
  i, x, x2: Integer;
  O: TNeoLVLObject;
  T: TNeoLVLTerrain;
  S: TNeoLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  SFinder: TStyleFinder;
  TempWindowOrder: Array[0..31] of Byte;
  WindowOrder: TWindowOrder;

  procedure AddSkill(aSkill: TSkillPanelButton);
  begin
    if x2 < 8 then
      aLevel.Info.Skillset := aLevel.Info.Skillset + [aSkill];
    Inc(x2);
  end;

  procedure SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
  begin
    if not(aSkill in aLevel.Info.Skillset) then Exit;
    aLevel.Info.SkillCount[aSkill] := aCount;
  end;
begin
  with aLevel do
  begin

    aStream.ReadBuffer(Buf, NEO_LVL_SIZE);
    UpgradeFormat(Buf);
    {-------------------------------------------------------------------------------
      Get the statics. This is easy
    -------------------------------------------------------------------------------}
    with Info do
    begin
      if OddLoad <> 1 then
      begin
      aLevel.Clear;
      ReleaseRate      := Buf.ReleaseRate;
      LemmingsCount    := Buf.LemmingsCount;
      RescueCount      := Buf.RescueCount;
      TimeLimit        := Buf.TimeLimit; // internal structure now matches NeoLemmix file format structure (just a number of seconds)

        x2 := 0;
        if Buf.Skillset and $8000 <> 0 then AddSkill(spbWalker);
        if Buf.Skillset and $4000 <> 0 then AddSkill(spbClimber);
        if Buf.Skillset and $2000 <> 0 then AddSkill(spbSwimmer);
        if Buf.Skillset and $1000 <> 0 then AddSkill(spbFloater);
        if Buf.Skillset and $800 <> 0 then AddSkill(spbGlider);
        if Buf.Skillset and $400 <> 0 then AddSkill(spbDisarmer);
        if Buf.Skillset and $200 <> 0 then AddSkill(spbBomber);
        if Buf.Skillset and $100 <> 0 then AddSkill(spbStoner);
        if Buf.Skillset and $80 <> 0 then AddSkill(spbBlocker);
        if Buf.Skillset and $40 <> 0 then AddSkill(spbPlatformer);
        if Buf.Skillset and $20 <> 0 then AddSkill(spbBuilder);
        if Buf.Skillset and $10 <> 0 then AddSkill(spbStacker);
        if Buf.Skillset and $8 <> 0 then AddSkill(spbBasher);
        if Buf.Skillset and $4 <> 0 then AddSkill(spbMiner);
        if Buf.Skillset and $2 <> 0 then AddSkill(spbDigger);
        if Buf.Skillset and $1 <> 0 then AddSkill(spbCloner);

        SetSkillCount(spbWalker, Buf.WalkerCount);
        SetSkillCount(spbClimber, Buf.ClimberCount);
        SetSkillCount(spbSwimmer, Buf.SwimmerCount);
        SetSkillCount(spbFloater, Buf.FloaterCount);
        SetSkillCount(spbGlider, Buf.GliderCount);
        SetSkillCount(spbDisarmer, Buf.MechanicCount);
        SetSkillCount(spbBomber, Buf.BomberCount);
        SetSkillCount(spbStoner, Buf.StonerCount);
        SetSkillCount(spbBlocker, Buf.BlockerCount);
        SetSkillCount(spbPlatformer, Buf.PlatformerCount);
        SetSkillCount(spbBuilder, Buf.BuilderCount);
        SetSkillCount(spbStacker, Buf.StackerCount);
        SetSkillCount(spbBasher, Buf.BasherCount);
        SetSkillCount(spbMiner, Buf.MinerCount);
        SetSkillCount(spbDigger, Buf.DiggerCount);
        SetSkillCount(spbCloner, Buf.ClonerCount);

      Title            := Buf.LevelName;
      Author           := Buf.LevelAuthor;
      case Buf.MusicNumber of
        0: MusicFile := '';
      253: MusicFile := '*';
      254: MusicFile := 'frenzy';
      255: MusicFile := 'gimmick';
        else MusicFile := '?';
      end;
      end;
      if (OddLoad = 2) and (Buf.LevelOptions and 16 <> 0) then
      begin
        LevelOptions := $71;
        Exit;
      end else begin
      Width := Buf.WidthAdjust + 1584;
      Height := Buf.HeightAdjust + 160;
      if Width < 320 then Width := 320;
      if Height < 160 then Height := 160;
      ScreenPosition   := Buf.ScreenPosition + 160;
      if ScreenPosition > (Width - 160) then ScreenPosition := (Width - 160);
      if ScreenPosition < 160 then ScreenPosition := 160;
      ScreenYPosition := Buf.ScreenYPosition + 80;
      if ScreenYPosition > (Height - 80) then ScreenYPosition := (Height - 80);
      if ScreenYPosition < 80 then ScreenYPosition := 80;

      SFinder := TStyleFinder.Create;

      if (Trim(Buf.StyleName) <> '') or (Trim(Buf.VgaspecName) <> '') then
      begin
        x := SFinder.FindNumber(Buf.StyleName, false);
        if (x <> -1) and (Buf.GraphicSet <> 255) then Buf.GraphicSet := x;
        x := SFinder.FindNumber(Buf.VgaspecName, true);
        if (x <> -1) and (Buf.GraphicSetEx <> 255) then Buf.GraphicSetEx := x;
      end;

      if trim(Buf.StyleName) <> '' then
      begin
        //GraphicSetFile := 'v_' + trim(Buf.StyleName) + '.dat';
        //GraphicMetaFile := 'g_' + trim(Buf.StyleName) + '.dat';
        if LowerCase(LeftStr(Buf.StyleName, 5)) = 'vgagr' then
          GraphicSetName := SFinder.FindName(StrToInt(Trim(MidStr(Buf.StyleName, 6, 3))), false)
        else
          GraphicSetName := trim(Buf.StyleName);
        Buf.GraphicSet := 255;
      end else begin
        GraphicSetName := SFinder.FindName(Buf.GraphicSet, false);
      end;

      SFinder.Free;

      LevelOptions := Buf.LevelOptions;

      for x := 0 to 31 do
        TempWindowOrder[x] := Buf.WindowOrder[x];
      end;
      if LevelOptions and $2 = 0 then
        LevelOptions := LevelOptions and $F7;
    end;

    if (OddLoad = 2) and (Info.LevelOptions and 16 <> 0) then Exit;

    {-------------------------------------------------------------------------------
      Get the objects
    -------------------------------------------------------------------------------}
    for i := 0 to 127 do
    begin
      O := Buf.Objects[i];
      if O.ObjectFlags and 128 = 0 then
      begin
        {Obj := InteractiveObjects.Add;
        Obj.Left := -32768;
        Obj.Top := -32768;
        Obj.Identifier := 0;}
        for x := i to 127 do
          for x2 := 0 to 31 do
            if ((Buf.WindowOrder[x2] and $80) <> 0) and ((Buf.WindowOrder[x2] and $7F) = x) then
              Buf.WindowOrder[x2] := Buf.WindowOrder[x2] - 1;
        Continue;
      end;
      Obj := InteractiveObjects.Add;
      Obj.Left := O.XPos;
      Obj.Top := O.YPos;
      Obj.GS := Info.GraphicSetName;
      Obj.Piece := IntToStr(O.ObjectID);
      Obj.TarLev := O.LValue;
      if O.ObjectFlags and $1 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_NoOverwrite;
      if O.ObjectFlags and $2 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_OnlyOnTerrain;
      if O.ObjectFlags and $4 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_UpsideDown;
      if O.ObjectFlags and $8 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_FlipLem;
      if O.ObjectFlags and $10 <> 0 then
        Obj.IsFake := true;
      if O.ObjectFlags and $20 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_Invisible;
      if O.ObjectFlags and $40 <> 0 then
        Obj.DrawingFlags := Obj.DrawingFlags or odf_Flip;
      Obj.Skill := O.SValue mod 16;

      Obj.LastDrawX := Obj.Left;
      Obj.LastDrawY := Obj.Top;
      Obj.DrawAsZombie := false;
    end;

    {-------------------------------------------------------------------------------
      Get the terrain.
    -------------------------------------------------------------------------------}
    for i := 0 to 999 do
    begin
      T := Buf.Terrain[i];
      if T.TerrainFlags and 128 = 0 then
        Continue;
      Ter := Terrains.Add;
      Ter.Left := T.XPos;
      Ter.Top := T.YPos;
      Ter.GS := Info.GraphicSetName;
      Ter.Piece := IntToStr(T.TerrainID);
      if T.TerrainFlags and $1 <> 0 then
        Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOverwrite;
      if T.TerrainFlags and $2 <> 0 then
        Ter.DrawingFlags := Ter.DrawingFlags or tdf_Erase;
      if T.TerrainFlags and $4 <> 0 then
        Ter.DrawingFlags := Ter.DrawingFlags or tdf_Invert;
      if T.TerrainFlags and $8 <> 0 then
        Ter.DrawingFlags := Ter.DrawingFlags or tdf_Flip;
      if Info.LevelOptions and $80 = 0 then
      begin
        if T.TerrainFlags and $10 <> 0 then
          Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOneWay;
      end else begin
        if T.TerrainFlags and $10 = 0 then
          Ter.DrawingFlags := Ter.DrawingFlags or tdf_NoOneWay;
      end;
    end;

    {-------------------------------------------------------------------------------
      Get the steel.
    -------------------------------------------------------------------------------}
    for i := 0 to 127 do
    begin
      S := Buf.Steel[i];
      if S.SteelFlags and 128 = 0 then
        Continue;
      Steel := Steels.Add;
      Steel.Left := S.XPos;
      Steel.Top := S.YPos;
      Steel.Width := S.SteelWidth + 1;
      Steel.Height := S.SteelHeight + 1;
      Steel.fType := S.SteelFlags and not $80;
    end;

    SetLength(WindowOrder, 0);
    with Info do
      for i := 0 to 31 do
        if (TempWindowOrder[i] and $80) <> 0 then
        begin
          SetLength(WindowOrder, Length(WindowOrder) + 1);
          WindowOrder[Length(WindowOrder) - 1] := TempWindowOrder[i] and $7F;
        end;

  end; // with aLevel

  ApplyWindowOrder(aLevel, WindowOrder);
end;



class procedure TLVLLoader.StoreLevelInStream(aLevel: TLevel; aStream: TStream);
begin
  aLevel.SaveToStream(aStream);
end;

end.

