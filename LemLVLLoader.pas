{$include lem_directives.inc}
unit LemLVLLoader;

interface

uses
  Classes, SysUtils, StrUtils,
  //Dialogs, Controls,
  LemNeoLevelLoader,
  Dialogs,
  UMisc,
  Math,
  LemDosMainDat,
  LemTerrain,
  LemInteractiveObject,
  LemSteel,
  LemDosStructures,
  LemLevel;

type
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

  TLVLLoader = class
  private
    class procedure UpgradeFormat(var Buf: TNeoLVLRec);
  protected
  public
    class procedure LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadTradLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure LoadNewNeoLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
    class procedure StoreLevelInStream(aLevel: TLevel; aStream: TStream);
  end;

implementation

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
  TempStream: TMemoryStream;
  TempLevel: TLevel;
begin
  SetLength(aLevel.Info.WindowOrder, 0); //kludgy bug fix

  TempStream := TMemoryStream.Create;
  TempLevel := TLevel.Create(nil);
  aStream.Seek(0, soFromBeginning);
  aStream.Read(b, 1);
  aStream.Seek(0, soFromBeginning);

  case b of
    0: LoadTradLevelFromStream(aStream, TempLevel);
  1..3: LoadNeoLevelFromStream(aStream, TempLevel);
    4: LoadNewNeoLevelFromStream(aStream, TempLevel);
    else begin
      TNeoLevelLoader.LoadLevelFromStream(aStream, aLevel);
      Exit;
    end;
  end;

  // easiest way to avoid issues with older level formats is to save as a new level then re-load that
  TempStream.Seek(0, soFromBeginning);
  StoreLevelInStream(TempLevel, TempStream);
  TempStream.Seek(0, soFromBeginning);
  if OddLoad = 2 then
    LoadNewNeoLevelFromStream(TempStream, aLevel, 0)
  else
    LoadNewNeoLevelFromStream(TempStream, aLevel, OddLoad);
  TempLevel.Free;
  TempStream.Free;

  // if the level has no Level ID, make one.
  // must be pseudo-random to enough extent to generate a different ID for each level,
  // but the same ID for the same level if unmodified

  i2 := 0;
  while aLevel.Info.LevelID = 0 do
  begin
    Inc(i2);
    for i := 0 to aLevel.InteractiveObjects.Count-1 do
    begin
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects[i].Left * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects[i].Top * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects[i].DrawingFlags;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects[i].Skill;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects[i].TarLev;
      if aLevel.Info.LevelID = 0 then aLevel.Info.LevelID := aLevel.Info.RescueCount;
    end;

    for i := 0 to aLevel.Terrains.Count-1 do
    begin
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Terrains[i].Left * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Terrains[i].Top * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Terrains[i].DrawingFlags;
      if aLevel.Info.LevelID = 0 then aLevel.Info.LevelID := aLevel.Info.LemmingsCount;
    end;

    for i := 0 to aLevel.Steels.Count-1 do
    begin
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Steels[i].Left * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Steels[i].Top * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Steels[i].Width * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Steels[i].Height * i2;
      aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.Steels[i].fType;
      if aLevel.Info.LevelID = 0 then aLevel.Info.LevelID := aLevel.Info.ReleaseRate;
    end;

    while (aLevel.Info.LevelID < $80000000) and (aLevel.Info.LevelID <> 0) do
      aLevel.Info.LevelID := aLevel.Info.LevelID xor (aLevel.Info.LevelID shl 1);

    for i := 1 to Length(aLevel.Info.Title)-3 do
    begin
      aLevel.Info.LevelID := aLevel.Info.LevelID + (i2 * i2);
      aLevel.Info.LevelID := aLevel.Info.LevelID xor ((Ord(aLevel.Info.Title[i]) shl 24) +
                                                      (Ord(aLevel.Info.Title[i+1]) shl 16) +
                                                      (Ord(aLevel.Info.Title[i+2]) shl 8) +
                                                      (Ord(aLevel.Info.Title[i+3])));
    end;

    aLevel.Info.LevelID := aLevel.Info.LevelID + aLevel.InteractiveObjects.Count + aLevel.Terrains.Count + aLevel.Steels.Count;
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
  i, x, x2, x3: Integer;
  O: TNewNeoLVLObject;
  T: TNewNeoLVLTerrain;
  S: TNewNeoLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  //SFinder: TStyleFinder;

  b: Byte;
  w: Word;

  LRes: Byte;

  HasSubHeader: Boolean;

  SkipObjects: Array of Integer;
begin
  SetLength(SkipObjects, 0);
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
        ClearLevel;
        DisplayPercent   := 0;
        ReleaseRate      := Buf.ReleaseRate;
        LemmingsCount    := Buf.LemmingsCount;
        RescueCount      := Buf.RescueCount;
        TimeLimit        := Buf.TimeLimit; // internal structure now matches NeoLemmix file format structure (just a number of seconds)

        SkillTypes := Buf.Skillset;
        x2 := 0;
        for x := 0 to 15 do
        begin
          x3 := Trunc(IntPower(2, (15-x)));
          if (SkillTypes and x3) <> 0 then Inc(x2);
          if x2 > 8 then SkillTypes := SkillTypes and (not x3);
        end;
        WalkerCount := Buf.WalkerCount;
        ClimberCount := Buf.ClimberCount;
        SwimmerCount := Buf.SwimmerCount;
        FloaterCount := Buf.FloaterCount;
        GliderCount := Buf.GliderCount;
        MechanicCount := Buf.MechanicCount;
        BomberCount := Buf.BomberCount;
        StonerCount := Buf.StonerCount;
        BlockerCount := Buf.BlockerCount;
        PlatformerCount := Buf.PlatformerCount;
        BuilderCount := Buf.BuilderCount;
        StackerCount := Buf.StackerCount;
        BasherCount := Buf.BasherCount;
        MinerCount := Buf.MinerCount;
        DiggerCount := Buf.DiggerCount;
        ClonerCount := Buf.ClonerCount;

        SuperLemming     := 0;

        GimmickSet := Buf.Gimmick;

        Title            := Buf.LevelName;
        Author           := Buf.LevelAuthor;
        GraphicSet := Buf.MusicNumber shl 8;
        LevelID := Buf.LevelID;
      end;

      fOddTarget       := (Buf.RefSection shl 8) + (Buf.RefLevel);
      if (OddLoad = 2) and (Buf.LevelOptions and 16 <> 0) then
      begin
        LevelOptions := $71;
        LRes := 8;
      end else begin

        LRes := Buf.Resolution;
        if LRes = 0 then LRes := 8;

        Width := (Buf.Width * 8) div LRes;
        Height := (Buf.Height * 8) div LRes;


        if Width < 320 then Width := 320;
        if Height < 160 then Height := 160;
        ScreenPosition   := (Buf.ScreenPosition * 8) div LRes;
        if ScreenPosition > (Width - 320) then ScreenPosition := (Width - 320);
        ScreenYPosition := (Buf.ScreenYPosition * 8) div LRes;
        if ScreenYPosition > (Height - 160) then ScreenYPosition := (Height - 160);

        GraphicSetFile := 'v_' + trim(Buf.StyleName) + '.dat';
        GraphicMetaFile := 'g_' + trim(Buf.StyleName) + '.dat';
        GraphicSetName := trim(Buf.StyleName);

        if trim(Buf.VgaspecName) = 'none' then
        begin
          VgaspecFile := '';
          GraphicSetEx := 0;
        end else begin
          VgaspecFile := 'x_' + trim(Buf.VgaspecName) + '.dat';
          GraphicSetEx := 255;
        end;

        GraphicSet       := 255 + (GraphicSet and $FF00);

        LevelOptions := Buf.LevelOptions;
        VgaspecX := (Buf.VgaspecX * 8) div LRes;
        VgaspecY := (Buf.VgaspecY * 8) div LRes;
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
               SkipObjects[Length(SkipObjects)-1] := InteractiveObjects.Count; //not a mistake; it's *intended* that it doesn't take into account previous skipped objects
             end else begin
             Obj := InteractiveObjects.Add;
             Obj.Left := (O.XPos * 8) div LRes;
             Obj.Top := (O.YPos * 8) div LRes;
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
           end;
        2: begin
             aStream.Read(T, SizeOf(T));
             if (T.TerrainFlags and 128) <> 0 then
             begin
             Ter := Terrains.Add;
             Ter.Left := (T.XPos * 8) div LRes;
             Ter.Top := (T.YPos * 8) div LRes;
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
             SetLength(Info.WindowOrder, 0);
             w := $FFFF;
             aStream.Read(w, 2);
             while w <> $FFFF do
             begin
               SetLength(Info.WindowOrder, Length(Info.WindowOrder) + 1);
               Info.WindowOrder[Length(Info.WindowOrder) - 1] := w;
               w := $FFFF;
               aStream.Read(w, 2);
             end;
           end;
        5: begin
             aStream.Read(Buf2, SizeOf(Buf2));
             HasSubHeader := true;
             Info.ScreenPosition := (Buf2.ScreenPosition * 8) div LRes;
             Info.ScreenYPosition := (Buf2.ScreenYPosition * 8) div LRes;
             with Info do
             begin
               if ScreenPosition > Width-320 then ScreenPosition := Width-320;
               if ScreenYPosition > Height-160 then ScreenYPosition := Height-160;
             end;
             if OddLoad <> 1 then
             begin
               Info.GimmickSet2 := Buf2.GimmickFlags2;
               Info.GimmickSet3 := Buf2.GimmickFlags3;
               Info.MusicFile := Trim(Buf2.MusicName);
               Info.BnsRank := Buf2.BnsRedirectRank;
               Info.BnsLevel := Buf2.BnsRedirectLevel;
             end;
           end;
        else Break;
      end;

      //b := 0;
      //aStream.Read(b, 1);
    end;

    for i := 0 to Length(SkipObjects)-1 do
      for x := 0 to Length(Info.WindowOrder)-1 do
        if Info.WindowOrder[x] > SkipObjects[i] then Dec(Info.WindowOrder[x]);

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
        GimmickSet2 := 0;
        GimmickSet3 := 0;
        BnsRank := Buf.RefSection;
        BnsLevel := Buf.RefLevel;
      end;

    if (OddLoad = 2) and (Info.LevelOptions and $10 <> 0) then
    begin
      InteractiveObjects.Clear;
      Terrains.Clear;
      Steels.Clear;
      SetLength(Info.WindowOrder, 0);
    end;

  end; // with aLevel
end;


class procedure TLVLLoader.LoadTradLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
{-------------------------------------------------------------------------------
  Translate a LVL file and fill the collections.
  For decoding and technical details see documentation or read the code :)
-------------------------------------------------------------------------------}
var
  Buf: TLVLRec;
  H, i{, x, x2, x3}: Integer;
  O: TLVLObject;
  T: TLVLTerrain;
  S: TLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  //SkTemp: array[0..15] of byte;
  //SkT2: array[0..7] of byte;
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
      if OddLoad <> 1 then
      begin
      ClearLevel;
      DisplayPercent   := {Buf.ReleaseRate mod 256} 0;
      ReleaseRate      := SwapWord(Buf.ReleaseRate) mod 256;
      LemmingsCount    := SwapWord(Buf.LemmingsCount);
      RescueCount      := SwapWord(Buf.RescueCount);
      TimeLimit        := (Buf.TimeMinutes * 60){ + Buf.TimeSeconds};
      {if (Buf.LevelOptions and 64) = 0 then
      begin}
        SkillTypes := $52AE;
        ClimberCount     := SwapWord(Buf.ClimberCount) mod 256;
        FloaterCount     := SwapWord(Buf.FloaterCount) mod 256;
        BomberCount      := SwapWord(Buf.BomberCount) mod 256;
        BlockerCount     := SwapWord(Buf.BlockerCount) mod 256;
        BuilderCount     := SwapWord(Buf.BuilderCount) mod 256;
        BasherCount      := SwapWord(Buf.BasherCount) mod 256;
        MinerCount       := SwapWord(Buf.MinerCount) mod 256;
        DiggerCount      := SwapWord(Buf.DiggerCount) mod 256;
      {end else begin
        SkillTypes := ((Buf.MinerCount mod 256) shl 8) + (Buf.DiggerCount mod 256);
        SkT2[0]     := SwapWord(Buf.ClimberCount) mod 256;
        SkT2[1]     := SwapWord(Buf.FloaterCount) mod 256;
        SkT2[2]      := SwapWord(Buf.BomberCount) mod 256;
        SkT2[3]     := SwapWord(Buf.BlockerCount) mod 256;
        SkT2[4]     := SwapWord(Buf.BuilderCount) mod 256;
        SkT2[5]      := SwapWord(Buf.BasherCount) mod 256;
        SkT2[6]       := SwapWord(Buf.MinerCount) mod 256;
        SkT2[7]      := SwapWord(Buf.DiggerCount) mod 256;
        x2 := 0;
        for x := 0 to 15 do
        begin
          x3 := Trunc(IntPower(2, (15-x)));
          if (x2 <= 7) then
          begin
          if (SkillTypes and x3) <> 0 then
          begin
            SkTemp[x] := SkT2[x2];
            Inc(x2);
          end else
            SkTemp[x] := 0;
          end else
            SkillTypes := SkillTypes and (not x3);
        end;
        WalkerCount := SkTemp[0];
        ClimberCount := SkTemp[1];
        SwimmerCount := SkTemp[2];
        FloaterCount := SkTemp[3];
        GliderCount := SkTemp[4];
        MechanicCount := SkTemp[5];
        BomberCount := SkTemp[6];
        StonerCount := SkTemp[7];
        BlockerCount := SkTemp[8];
        PlatformerCount := SkTemp[9];
        BuilderCount := SkTemp[10];
        StackerCount := SkTemp[11];
        BasherCount := SkTemp[12];
        MinerCount := SkTemp[13];
        DiggerCount := SkTemp[14];
        ClonerCount := SkTemp[15];
      end;}
      if Buf.Reserved = $FFFF then
        GimmickSet := 1
      else
        GimmickSet := 0;
      GraphicSetEx     := Buf.GraphicSetEx;
      LevelOptions     := Buf.LevelOptions and $10;
      {if (LevelOptions and 32) <> 0 then
        begin
        GimmickSet := ((Buf.ClimberCount mod 256) shl 24) + ((Buf.FloaterCount mod 256) shl 16) +
                      ((Buf.BomberCount mod 256) shl 8) + (Buf.BlockerCount mod 256);
        fSuperlem := (GimmickSet and 1 <> 0);
        fKaroshi := (GimmickSet and 8 <> 0);
        SuperLemming := 0;
        end else begin
        GimmickSet := 0;
        fSuperlem := false;
        fKaroshi := false;
        if (SuperLemming = $4201) or (SuperLemming = $4209) or (SuperLemming = $420A) or (SuperLemming = $FFFF) then fSuperLem := true;
        if (SuperLemming = $4204) or (SuperLemming = $4209) then fKaroshi := true;
        end;}
      Title            := Buf.LevelName;
      Author           := '';
      GraphicSet := SwapWord(Buf.GraphicSet);
      case (GraphicSet shr 8) and $FF of
        0: MusicFile := '';
      253: MusicFile := '*';
      254: MusicFile := 'frenzy';
      255: MusicFile := 'gimmick';
        else MusicFile := '?';
      end;
      end;
      fOddTarget       := (((Buf.BuilderCount) mod 256) shl 8) + ((Buf.BasherCount) mod 256);
      if (OddLoad = 2) and (LevelOptions and $10 <> 0) then
      begin
        LevelOptions := LevelOptions and $71;
        Exit;
      end;
      ScreenPosition   := SwapWord(Buf.ScreenPosition);
      ScreenYPosition  := 0;
      Width := 1584;
      Height := 160;
      if ScreenPosition > (Width - 320) then ScreenPosition := (Width - 320);
      GraphicSet       := (SwapWord(Buf.GraphicSet) and $00FF) + (GraphicSet and $FF00);
      GraphicSetEx     := Buf.GraphicSetEx;

      SFinder := TStyleFinder.Create;

      GraphicSetFile := 'vgagr' + i2s(GraphicSet mod 256) + '.dat';
      GraphicMetaFile := 'ground' + i2s(GraphicSet mod 256) + 'o.dat';
      if GraphicSetEx > 0 then
        VgaspecFile := 'vgaspec' + i2s(GraphicSetEx - 1) + '.dat'
        else
        VgaspecFile := '';

      if SFinder.FindName(GraphicSet mod 256, false) <> '' then
        GraphicSetName := SFinder.FindName(GraphicSet mod 256, false);

      SFinder.Free;

      VgaspecX := 304;
      VgaspecY := 0;


      GimmickSet2 := 0;
      GimmickSet3 := 0;

      {if (LevelOptions) and $2 = 0 then
        LevelOptions := LevelOptions and $77
        else
        LevelOptions := LevelOptions and $7F;}
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
      Steel.Left := ((Integer(S.B0) shl 1) + (Integer(S.B1 and Bit7) shr 7)) * 4 - 16;  // 9 bits
      Steel.Top := Integer(S.B1 and not Bit7) * 4;  // bit 7 belongs to steelx
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
  {H, }i, x, x2, x3: Integer;
  O: TNeoLVLObject;
  T: TNeoLVLTerrain;
  S: TNeoLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  SFinder: TStyleFinder;
  TempWindowOrder: Array[0..31] of Byte;
begin
  with aLevel do
  begin

    aStream.ReadBuffer(Buf, NEO_LVL_SIZE);
    UpgradeFormat(Buf);
    //if MessageDlg('OddLoad: ' + i2s(OddLoad), mtCustom, [mbYes, mbNo], 0) = mrNo then Halt;
    {-------------------------------------------------------------------------------
      Get the statics. This is easy
    -------------------------------------------------------------------------------}
    with Info do
    begin
      if OddLoad <> 1 then
      begin
      ClearLevel;
      DisplayPercent   := {Buf.ReleaseRate mod 256} 0;
      ReleaseRate      := Buf.ReleaseRate;
      LemmingsCount    := Buf.LemmingsCount;
      RescueCount      := Buf.RescueCount;
      TimeLimit        := Buf.TimeLimit; // internal structure now matches NeoLemmix file format structure (just a number of seconds)

        SkillTypes := Buf.Skillset;
        x2 := 0;
        for x := 0 to 15 do
        begin
          x3 := Trunc(IntPower(2, (15-x)));
          if (SkillTypes and x3) <> 0 then Inc(x2);
          if x2 > 8 then SkillTypes := SkillTypes and (not x3);
        end;
        WalkerCount := Buf.WalkerCount;
        ClimberCount := Buf.ClimberCount;
        SwimmerCount := Buf.SwimmerCount;
        FloaterCount := Buf.FloaterCount;
        GliderCount := Buf.GliderCount;
        MechanicCount := Buf.MechanicCount;
        BomberCount := Buf.BomberCount;
        StonerCount := Buf.StonerCount;
        BlockerCount := Buf.BlockerCount;
        PlatformerCount := Buf.PlatformerCount;
        BuilderCount := Buf.BuilderCount;
        StackerCount := Buf.StackerCount;
        BasherCount := Buf.BasherCount;
        MinerCount := Buf.MinerCount;
        DiggerCount := Buf.DiggerCount;
        ClonerCount := Buf.ClonerCount;

      SuperLemming     := 0;

        GimmickSet := Buf.Gimmick;
        GimmickSet2 := 0;
        GimmickSet3 := 0;

      Title            := Buf.LevelName;
      Author           := Buf.LevelAuthor;
      GraphicSet := Buf.MusicNumber shl 8;
      case Buf.MusicNumber of
        0: MusicFile := '';
      253: MusicFile := '*';
      254: MusicFile := 'frenzy';
      255: MusicFile := 'gimmick';
        else MusicFile := '?';
      end;
      end;
      fOddTarget       := (Buf.RefSection shl 8) + (Buf.RefLevel);
      if (OddLoad = 2) and (Buf.LevelOptions and 16 <> 0) then
      begin
        LevelOptions := $71;
        Exit;
      end else begin
      Width := Buf.WidthAdjust + 1584;
      Height := Buf.HeightAdjust + 160;
      if Width < 320 then Width := 320;
      if Height < 160 then Height := 160;
      ScreenPosition   := Buf.ScreenPosition;
      if ScreenPosition > (Width - 320) then ScreenPosition := (Width - 320);
      ScreenYPosition := Buf.ScreenYPosition;
      if ScreenYPosition > (Height - 160) then ScreenYPosition := (Height - 160);

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
        GraphicSetFile := 'vgagr' + i2s(Buf.GraphicSet) + '.dat';
        GraphicMetaFile := 'ground' + i2s(Buf.GraphicSet) + 'o.dat';
      end;

      if trim(Buf.VgaspecName) <> '' then
      begin
        if trim(Buf.VgaspecName) = 'none' then
        begin
          Buf.GraphicSetEx := 0;
          VgaspecFile := ''
        end else begin
          Buf.GraphicSetEx := 255;
          VgaspecFile := 'x_' + trim(Buf.VgaspecName) + '.dat';
        end;
      end else begin
        if Buf.GraphicSetEx = 0 then
          VgaspecFile := ''
        else begin
          if SFinder.FindName(Buf.GraphicSetEx, true) <> '' then
            VgaSpecFile := 'x_' + SFinder.FindName(Buf.GraphicSetEx, true) + '.dat'
          else
            VgaspecFile := 'vgaspec' + i2s(Buf.GraphicSetEx - 1) + '.dat';
        end;
      end;

      SFinder.Free;

      GraphicSet       := Buf.GraphicSet + (GraphicSet and $FF00);
      GraphicSetEx     := Buf.GraphicSetEx;
      LevelOptions := Buf.LevelOptions;
      VgaspecX := Buf.VgaspecX;
      VgaspecY := Buf.VgaspecY;
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

    SetLength(Info.WindowOrder, 0);
    with Info do
      for i := 0 to 31 do
        if (TempWindowOrder[i] and $80) <> 0 then
        begin
          SetLength(WindowOrder, Length(WindowOrder) + 1);
          WindowOrder[Length(WindowOrder) - 1] := TempWindowOrder[i] and $7F;
        end;

  end; // with aLevel
end;



class procedure TLVLLoader.StoreLevelInStream(aLevel: TLevel; aStream: TStream);
var
  //Int16: SmallInt; Int32: Integer;
  {H,} i: Integer;
  //M: Byte;
  W: Word;
  O: TNewNeoLVLObject;
  T: TNewNeoLVLTerrain;
  S: TNewNeoLVLSteel;
  Obj: TInteractiveObject;
  Ter: TTerrain;
  Steel: TSteel;
  Buf: TNeoLVLHeader;
  Buf2: TNeoLVLSecondHeader;
  k: ShortString;
  //SFinder: TStyleFinder;

  b: Byte;
  //w: Word;
begin


  with aLevel do
  begin
    FillChar(Buf, SizeOf(Buf), 0);
    FillChar(Buf.LevelName, 32, ' ');
    FillChar(Buf.LevelAuthor, 16, ' ');
    FillChar(Buf.StyleName, 16, ' ');
    FillChar(Buf.VgaspecName, 16, ' ');
    FillChar(Buf.ReservedStr, 32, ' ');

    {-------------------------------------------------------------------------------
      Set the statics.
    -------------------------------------------------------------------------------}
    with Info do
    begin

      Buf.FormatTag     := 4;
      Buf.ReleaseRate   := ReleaseRate;
      Buf.LemmingsCount := LemmingsCount;
      Buf.RescueCount   := RescueCount;
      Buf.TimeLimit     := TimeLimit;
      Buf.Skillset      := SkillTypes;

      if (SkillTypes and $8000 <> 0) then Buf.WalkerCount := WalkerCount;
      if (SkillTypes and $4000 <> 0) then Buf.ClimberCount := ClimberCount;
      if (SkillTypes and $2000 <> 0) then Buf.SwimmerCount := SwimmerCount;
      if (SkillTypes and $1000 <> 0) then Buf.FloaterCount := FloaterCount;
      if (SkillTypes and $0800 <> 0) then Buf.GliderCount := GliderCount;
      if (SkillTypes and $0400 <> 0) then Buf.MechanicCount := MechanicCount;
      if (SkillTypes and $0200 <> 0) then Buf.BomberCount := BomberCount;
      if (SkillTypes and $0100 <> 0) then Buf.StonerCount := StonerCount;
      if (SkillTypes and $0080 <> 0) then Buf.BlockerCount := BlockerCount;
      if (SkillTypes and $0040 <> 0) then Buf.PlatformerCount := PlatformerCount;
      if (SkillTypes and $0020 <> 0) then Buf.BuilderCount := BuilderCount;
      if (SkillTypes and $0010 <> 0) then Buf.StackerCount := StackerCount;
      if (SkillTypes and $0008 <> 0) then Buf.BasherCount := BasherCount;
      if (SkillTypes and $0004 <> 0) then Buf.MinerCount := MinerCount;
      if (SkillTypes and $0002 <> 0) then Buf.DiggerCount := DiggerCount;
      if (SkillTypes and $0001 <> 0) then Buf.ClonerCount := ClonerCount;

      Buf.LevelOptions := LevelOptions;
      //Buf.GraphicSetEx := GraphicSetEx;
      //Buf.GraphicSet   := GraphicSet;
      Buf.MusicNumber  := GraphicSet shr 8;
      Buf.ScreenPosition := ScreenPosition;
      Buf.ScreenYPosition := ScreenYPosition;

      Buf.Resolution := 8;

      Buf.Width := Width;
      Buf.Height := Height;

      Buf.Gimmick := GimmickSet;

      if Length(Title) > 0 then
         System.Move(Title[1], Buf.LevelName, Length(Title));

      if Length(Author) > 0 then
         System.Move(Author[1], Buf.LevelAuthor, Length(Author));

      {SFinder := TStyleFinder.Create;
      k := SFinder.FindName(Buf.GraphicSet, false);
      if k <> '' then System.Move(k[1], Buf.StyleName, Length(k));
      k := SFinder.FindName(Buf.GraphicSetEx, true);
      if k <> '' then System.Move(k[1], Buf.VgaspecName, Length(k));
      SFinder.Free;}

      {if Buf.GraphicSet = 255 then
      begin}
        k := GraphicSetName;
        System.Move(k[1], Buf.StyleName, Length(k));
      {end;

      if Buf.GraphicSetEx = 255 then
      begin}
        k := RightStr(LeftStr(VgaspecFile, Length(VgaSpecFile) - 4), Length(VgaspecFile) - 6);
        if k = '' then k := 'none';
        System.Move(k[1], Buf.VgaspecName, Length(k));
      //end;

      {for i := 0 to 31 do
        Buf.WindowOrder[i] := WindowOrder[i];}

      Buf.RefSection := fOddTarget shr 8;
      Buf.RefLevel   := fOddTarget;

      Buf.VgaspecX := VgaspecX;
      Buf.VgaspecY := VgaspecY;

      Buf.LevelID := LevelID;
    end;

    aStream.Write(Buf, SizeOf(Buf));

    {-------------------------------------------------------------------------------
      Set the objects.
    -------------------------------------------------------------------------------}
    for i := 0 to (InteractiveObjects.Count - 1) do
    begin
      Obj := InteractiveObjects[i];

      //if (Obj.Left = -32768) and (Obj.Top = -32768) then Continue;

      FillChar(O, Sizeof(O), 0);

      O.XPos := Obj.Left;
      O.YPos := Obj.Top;
      O.ObjectID := StrToIntDef(Obj.Piece, 0);
      O.LValue := Obj.TarLev;
      O.SValue := Obj.Skill;

      O.ObjectFlags := $80;

      if Obj.DrawingFlags and odf_NoOverwrite <> 0 then
        O.ObjectFlags := O.ObjectFlags or $1;
      if Obj.DrawingFlags and odf_OnlyOnTerrain <> 0 then
        O.ObjectFlags := O.ObjectFlags or $2;
      if Obj.DrawingFlags and odf_UpsideDown <> 0 then
        O.ObjectFlags := O.ObjectFlags or $4;
      if Obj.DrawingFlags and odf_FlipLem <> 0 then
        O.ObjectFlags := O.ObjectFlags or $8;
      if Obj.IsFake then
        O.ObjectFlags := O.ObjectFlags or $10;
      if Obj.DrawingFlags and odf_Invisible <> 0 then
        O.ObjectFlags := O.ObjectFlags or $20;
      if Obj.DrawingFlags and odf_Flip <> 0 then
        O.ObjectFlags := O.ObjectFlags or $40;

      b := 1;
      aStream.Write(b, 1);
      aStream.Write(O, SizeOf(O));
    end;

    {-------------------------------------------------------------------------------
      set the terrain
    -------------------------------------------------------------------------------}
    for i := 0 to Terrains.Count - 1 do
    begin
      Ter := Terrains[i];

      FillChar(T, Sizeof(T), 0);

      T.XPos := Ter.Left;
      T.YPos := Ter.Top;
      T.TerrainID := StrToIntDef(Ter.Piece, 0);

      T.TerrainFlags := $80;

      if Ter.DrawingFlags and tdf_NoOverwrite <> 0 then
        T.TerrainFlags := T.TerrainFlags or $1;
      if Ter.DrawingFlags and tdf_Erase <> 0 then
        T.TerrainFlags := T.TerrainFlags or $2;
      if Ter.DrawingFlags and tdf_Invert <> 0 then
        T.TerrainFlags := T.TerrainFlags or $4;
      if Ter.DrawingFlags and tdf_Flip <> 0 then
        T.TerrainFlags := T.TerrainFlags or $8;
      if Info.LevelOptions and $80 = 0 then
      begin
        if Ter.DrawingFlags and tdf_NoOneWay <> 0 then
          T.TerrainFlags := T.TerrainFlags or $10;
      end else begin
        if Ter.DrawingFlags and tdf_NoOneWay = 0 then
          T.TerrainFlags := T.TerrainFlags or $10;
      end;
      if Ter.DrawingFlags and tdf_Rotate <> 0 then
        T.TerrainFlags := T.TerrainFlags or $20;

      b := 2;
      aStream.Write(b, 1);
      aStream.Write(T, SizeOf(T));
    end;

    {-------------------------------------------------------------------------------
      set the steel.
    -------------------------------------------------------------------------------}
  if (Info.LevelOptions and 4) = 0 then
    for i := 0 to Steels.Count - 1 do
    begin
      Steel := Steels[i];
      FillChar(S, SizeOf(S), 0);

      S.XPos := Steel.Left;
      S.YPos := Steel.Top;
      S.SteelWidth := Steel.Width - 1;
      S.SteelHeight := Steel.Height - 1;

      S.SteelFlags := Steel.fType or $80;
      b := 3;
      aStream.Write(b, 1);
      aStream.Write(s, SizeOf(S));
    end;
  {end;}

    if Length(Info.WindowOrder) > 0 then
    begin
      b := 4;
      aStream.Write(b, 1);
      for i := 0 to Length(Info.WindowOrder)-1 do
      begin
        w := Info.WindowOrder[i];
        aStream.Write(w, 2);
      end;
      w := $FFFF;
      aStream.Write(w, 2);
    end;

    b := 5;
    aStream.Write(b, 1);
    FillChar(Buf2, SizeOf(Buf2), 0);
    FillChar(Buf2.MusicName, 16, 0);
    Buf2.ScreenPosition := Info.ScreenPosition;
    Buf2.ScreenYPosition := Info.ScreenYPosition;
    Buf2.GimmickFlags2 := Info.GimmickSet2;
    Buf2.GimmickFlags3 := Info.GimmickSet3;
    k := LowerCase(LeftStr(Info.MusicFile, 16));
    Move(k[1], Buf2.MusicName, Length(k));
    Buf2.SecRedirectRank := 0;
    Buf2.SecRedirectLevel := 0;
    Buf2.BnsRedirectRank := Info.BnsRank;
    Buf2.BnsRedirectLevel := Info.BnsLevel;
    aStream.Write(Buf2, SizeOf(Buf2));

    //aStream.WriteBuffer(Buf, NEO_LVL_SIZE);
    b := 0;
    aStream.Write(b, 1);

  end;
end;

end.

