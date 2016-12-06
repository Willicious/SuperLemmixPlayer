unit LemGSConvert;

interface

uses
  GSCDebug,
  Classes, SysUtils, StrUtils,
  LemNeoParser, Math,
  PngInterface, LemGraphicSet, GR32;

  procedure Prepare(aGS: TBaseGraphicSet);
  procedure Adjust(aGS: TBaseGraphicSet; aSL: TStringList);

  procedure ShrinkTerrain(T: TMetaTerrain; BMP: TBitmap32);
  function FindTerrainMatch(var Index: Integer; var Rotate, Flip, Invert: Boolean): Boolean;

  procedure ShrinkObject(O: TMetaObject; BMPs: TBitmaps);

  procedure DoSave(aGS: TBaseGraphicSet; aName: String);

  function LeadZeroStr(aValue, aLen: Integer): String;

type
  TConvertFunctions = class // Because TParser's foreach type procedures need methods of an object
    private
      fPieceIndex: Integer;
    public
      procedure HandleObjectMerge(aSection: TParserSection; const aIteration: Integer);
      // haven't seen the need to implement a terrain merge
      procedure HandleObjectAdjust(aSection: TParserSection; const aIteration: Integer);
      procedure HandleTerrainAdjust(aSection: TParserSection; const aIteration: Integer);
  end;

implementation

var
  GS: TBaseGraphicSet;

function LeadZeroStr(aValue, aLen: Integer): String;
begin
  Result := IntToStr(aValue);
  if Length(Result) < aLen then
    Result := StringOfChar('0', Length(Result) - aLen) + Result;
end;

// Actual save

procedure DoSave(aGS: TBaseGraphicSet; aName: String);
var
  BasePath: String;
  i: Integer;

  TranslationTable: TParser;
  Parser: TParser;

  procedure MakeFolders;
  var
    i: Integer;
  begin
    // Terrains - if there are any, we need a folder
    if GS.MetaTerrains.Count > 0 then
      ForceDirectories(BasePath + aName + '\terrain\');
    // Objects - ignore backgrounds, *lemming, *pickup and *nil
    for i := 0 to GS.MetaObjects.Count-1 do
      if (LeftStr(GS.MetaObjects[i].Name, 1) <> '*') and (LeftStr(GS.MetaObjects[i].Name, 1) <> '&') then
      begin
        ForceDirectories(BasePath + aName + '\objects\');
        Break;
      end;
    // Backgrounds - look for an object name starting with &
    for i := 0 to GS.MetaObjects.Count-1 do
      if (LeftStr(GS.MetaObjects[i].Name, 1) = '&') then
      begin
        ForceDirectories(BasePath + aName + '\backgrounds\');
        Break;
      end;
  end;

  procedure AddTerrainConversion(i: Integer);
  var
    Sec: TParserSection;
    T, TSrc: TMetaTerrain;
    n: Integer;
    S: String;
  begin
    T := GS.MetaTerrains[i];

    Sec := TranslationTable.MainSection.SectionList.Add('TERRAIN');
    Sec.AddLine('INDEX', i);

    if LeftStr(T.Name, 1) = '*' then
    begin
      TSrc := GS.MetaTerrains[StrToInt(RightStr(T.Name, Length(T.Name)-1))];
      Sec.AddLine('COLLECTION', aName);
      Sec.AddLine('PIECE', TSrc.Name);
    end else if LeftStr(T.Name, 1) = '#' then
    begin
      S := RightStr(T.Name, Length(T.Name)-1);
      n := Pos(':', S);
      Sec.AddLine('COLLECTION', LeftStr(S, n-1));
      Sec.AddLine('PIECE', RightStr(S, Length(S)-n));
    end else begin
      Sec.AddLine('COLLECTION', aName);
      Sec.AddLine('PIECE', T.Name);
    end;

    Sec.AddLine('LEFT_OFFSET', T.OffsetL);
    Sec.AddLine('RIGHT_OFFSET', T.OffsetR);
    Sec.AddLine('TOP_OFFSET', T.OffsetT);
    Sec.AddLine('BOTTOM_OFFSET', T.OffsetB);

    if T.ConvertRotate then
      Sec.AddLine('ROTATE');
    if T.ConvertFlip then
      Sec.AddLine('FLIP_HORIZONTAL');
    if T.ConvertInvert then
      Sec.AddLine('FLIP_VERTICAL');
  end;

  procedure AddObjectConversion(i: Integer);
  var
    Sec: TParserSection;
    O: TMetaObject;
    n, n2: Integer;
    S: String;
  begin
    O := GS.MetaObjects[i];

    if O.Name = '*nil' then Exit;

    if LeftStr(O.Name, 1) = '&' then
    begin
      Sec := TranslationTable.MainSection.SectionList.Add('BACKGROUND');
      n := 0;
      for n2 := 0 to i-1 do
        if LeftStr(GS.MetaObjects[n2].Name, 1) = '&' then
          Inc(n);
      Sec.AddLine('INDEX', n);
      Sec.AddLine('COLLECTION', aName);
      Sec.AddLine('PIECE', RightStr(O.Name, Length(O.Name)-1));
      Exit;
    end;

    Sec := TranslationTable.MainSection.SectionList.Add('OBJECT');
    Sec.AddLine('INDEX', i);

    if O.Name = '*pickup' then
    begin
      Sec.AddLine('SPECIAL', 'pickup');
      Exit;
    end;

    if O.Name = '*lemming' then
    begin
      Sec.AddLine('SPECIAL', 'lemming');
      Sec.AddLine('LEFT_OFFSET', O.OffsetL);
      Sec.AddLine('TOP_OFFSET', O.OffsetT);
      Exit;
    end;

    if LeftStr(O.Name, 1) = '#' then
    begin
      S := RightStr(O.Name, Length(O.Name)-1);
      n := Pos(':', S);
      Sec.AddLine('COLLECTION', LeftStr(S, n-1));
      Sec.AddLine('PIECE', RightStr(S, Length(S)-n));
    end else begin
      Sec.AddLine('COLLECTION', aName);
      Sec.AddLine('PIECE', O.Name);
    end;

    Sec.AddLine('LEFT_OFFSET', O.OffsetL);
    Sec.AddLine('RIGHT_OFFSET', O.OffsetR);
    Sec.AddLine('TOP_OFFSET', O.OffsetT);
    Sec.AddLine('BOTTOM_OFFSET', O.OffsetB);

    if O.ConvertFlip then
      Sec.AddLine('FLIP_HORIZONTAL');
    if O.ConvertInvert then
      Sec.AddLine('FLIP_VERTICAL');
  end;

  procedure SaveTerrain(i: Integer);
  var
    T: TMetaTerrain;
  begin
    T := GS.MetaTerrains[i];
    if LeftStr(T.Name, 1) = '*' then Exit;
    if LeftStr(T.Name, 1) = '#' then Exit;

    SetCurrentDir(BasePath + aName + '\terrain\');
    TPngInterface.SavePngFile(T.Name + '.png', GS.TerrainImages[i]);

    if T.Steel then
    begin
      Parser.Clear;
      Parser.MainSection.AddLine('STEEL');
      Parser.SaveToFile(T.Name + '.nxmt');
    end;
  end;

  procedure SaveObject(i: Integer);
  var
    O: TMetaObject;
    S: String;
    Sec: TParserSection;
    BMP: TBitmap32;
    Frame: Integer;
  begin
    O := GS.MetaObjects[i];
    if LeftStr(O.Name, 1) = '*' then Exit;
    if LeftStr(O.Name, 1) = '#' then Exit;

    if LeftStr(O.Name, 1) = '&' then
    begin
      S := RightStr(O.Name, Length(O.Name)-1);
      TPngInterface.SavePngFile(BasePath + aName + '\backgrounds\' + S + '.png', GS.ObjectImages[i][0]);
      Exit;
    end;

    Parser.Clear;
    Sec := Parser.MainSection;

    Sec.AddLine('FRAMES', GS.ObjectImages[i].Count);

    case O.TriggerType of
      1: S := 'EXIT';
      2: S := 'FORCE_LEFT';
      3: S := 'FORCE_RIGHT';
      4: S := 'TRAP';
      5: S := 'WATER';
      6: S := 'FIRE';
      7: S := 'ONE_WAY_LEFT';
      8: S := 'ONE_WAY_RIGHT';
      // 9, 10 are unused
      11: S := 'TELEPORTER';
      12: S := 'RECEIVER';
      // 13, 14 are unused
      15: S := 'LOCKED_EXIT';
      // 16 is unused
      17: S := 'BUTTON';
      18: S := 'RADIATION';
      19: S := 'ONE_WAY_DOWN';
      20: S := 'UPDRAFT';
      21: S := 'SPLITTER';
      22: S := 'SLOWFREEZE';
      23: S := 'WINDOW';
      24: S := 'ANIMATION';
      // 25 is unused
      26: S := 'ANTI_SPLATPAD';
      27: S := 'SPLATPAD';
      // 28, 29 are unused
      30: S := 'MOVING_BACKGROUND';
      31: S := 'SINGLE_USE_TRAP';
      // 32 is unused and 33+ are not valid values
      else begin
        S := 'NO_EFFECT';
        O.TriggerType := 0;
      end;
    end;

    Sec.AddLine(S);

    if not (O.TriggerType in [0, 30]) then
    begin
      Sec.AddLine('TRIGGER_X', O.PTriggerX);
      Sec.AddLine('TRIGGER_Y', O.PTriggerY);
    end;

    if not (O.TriggerType in [0, 23, 30]) then
    begin
      Sec.AddLine('TRIGGER_WIDTH', O.PTriggerW);
      Sec.AddLine('TRIGGER_HEIGHT', O.PTriggerH);
    end;

    if O.TriggerType in [4, 11, 15, 17, 24, 31] then
    begin
      Sec.AddLine('SOUND', O.TriggerSound);
    end;

    if not O.TriggerType in [4, 11, 12, 15, 17, 21, 23, 24, 31] then
    begin
      if O.RandomFrame then
        Sec.AddLine('RANDOM_START_FRAME')
      else
        Sec.AddLine('PREVIEW_FRAME', O.PreviewFrame);
    end;

    if O.TriggerType in [11, 12] then
    begin
      Sec.AddLine('KEY_FRAME', O.KeyFrame);
    end;

    SetCurrentDir(BasePath + aName + '\objects\');
    Parser.SaveToFile(O.Name + '.nxmo');

    BMP := TBitmap32.Create;
    BMP.SetSize(GS.ObjectImages[i][0].Width, GS.ObjectImages[i][0].Height * GS.ObjectImages[i].Count);

    for Frame := 0 to GS.ObjectImages[i].Count-1 do
      GS.ObjectImages[i][Frame].DrawTo(BMP, 0, Frame * GS.ObjectImages[i][0].Height);

    TPngInterface.SavePngFile(O.Name + '.png', BMP);
    BMP.Free;
  end;

  procedure SaveTheme;
  var
    Sec: TParserSection;
  begin
    Parser.Clear;
    Sec := Parser.MainSection;

    if GS.LemmingSprites = 'xlemming' then
      Sec.AddLine('LEMMINGS', 'xmas')
    else
      Sec.AddLine('LEMMINGS', 'default');

    Sec := Sec.SectionList.Add('COLORS');

    Sec.AddLine('MASK', GS.KeyColors[0] and $FFFFFF, 6);
    Sec.AddLine('MINIMAP', GS.KeyColors[1] and $FFFFFF, 6);
    Sec.AddLine('BACKGROUND', GS.KeyColors[2] and $FFFFFF, 6);
    Sec.AddLine('ONE_WAYS', GS.KeyColors[3] and $FFFFFF, 6);
    Sec.AddLine('PICKUP_BORDER', GS.KeyColors[4] and $FFFFFF, 6);
    Sec.AddLine('PICKUP_INSIDE', GS.KeyColors[5] and $FFFFFF, 6);

    Parser.SaveToFile(BasePath + aName + '\theme.nxtm'); 
  end;
begin
  GS := aGS;
  BasePath := ExtractFilePath(ParamStr(0));

  ForceDirectories(BasePath + aName + '\');

  MakeFolders;

  TranslationTable := TParser.Create;
  Parser := TParser.Create; //general purpose, reused several times

  for i := 0 to GS.MetaTerrains.Count-1 do
  begin
    AddTerrainConversion(i);
    SaveTerrain(i);
  end;

  for i := 0 to GS.MetaObjects.Count-1 do
  begin
    AddObjectConversion(i);
    SaveObject(i);
  end;

  TranslationTable.SaveToFile(BasePath + aName + '\' + 'translation.nxtt');

  TranslationTable.Free;
  Parser.Free;

end;

// Helpful stuff
function CheckSizeMatch(BMP1: TBitmap32; BMP2: TBitmap32): Boolean;
begin
  if ((BMP1.Width = BMP2.Width) and (BMP1.Height = BMP2.Height))
  or ((BMP1.Width = BMP2.Height) and (BMP1.Height = BMP2.Width)) then
    Result := true
  else
    Result := false;
end;

function MakeBitmapHash(BMP: TBitmap32): Cardinal;
var
  x, y: Integer;
begin
  Result := 0;
  for y := 0 to BMP.Height-1 do
    for x := 0 to BMP.Width-1 do
      if BMP.Pixel[x, y] and $FF000000 <> 0 then
        Result := Result xor BMP.Pixel[x, y];
end;

function CheckHashMatch(BMP1, BMP2: TBitmap32): Boolean;
begin
  Result := MakeBitmapHash(BMP1) = MakeBitmapHash(BMP2);
end;

function CheckImageMatch(BMP1, BMP2: TBitmap32): Boolean;
var
  x, y: Integer;
begin
  Result := false;
  if BMP1.Width <> BMP2.Width then Exit;
  if BMP1.Height <> BMP2.Height then Exit;

  for y := 0 to BMP1.Height-1 do
    for x := 0 to BMP1.Width-1 do
      if (BMP1.Pixel[x, y] and $FF000000 = 0) and (BMP2.Pixel[x, y] and $FF000000 = 0) then
        Continue
      else if BMP1.Pixel[x, y] <> BMP2.Pixel[x, y] then
        Exit;

  Result := true;
end;

// Actual preparation code
procedure Adjust(aGS: TBaseGraphicSet; aSL: TStringList);
var
  Parser: TParser;
  Funcs: TConvertFunctions;
  Sec: TParserSection;
begin
  GS := aGS;

  Parser := TParser.Create;
  Funcs := TConvertFunctions.Create;
  try
    Parser.LoadFromStrings(aSL);
    Parser.MainSection.DoForEachSection('object', Funcs.HandleObjectAdjust);
    Parser.MainSection.DoForEachSection('terrain', Funcs.HandleTerrainAdjust);

    Sec := Parser.MainSection.Section['colors'];
    if Sec <> nil then
    begin
      if Sec.Line['mask'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['mask'] or $FF000000;
      if Sec.Line['minimap'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['minimap'] or $FF000000;
      if Sec.Line['background'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['background'] or $FF000000;
      if Sec.Line['pickup_border'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['pickup_border'] or $FF000000;
      if Sec.Line['pickup_inside'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['pickup_inside'] or $FF000000;
      if Sec.Line['one_ways'] <> nil then GS.KeyColors[0] := Sec.LineNumeric['one_ways'] or $FF000000;
    end;
  finally
    Parser.Free;
    Funcs.Free;
  end;
end;

procedure TConvertFunctions.HandleObjectMerge(aSection: TParserSection; const aIteration: Integer);
type
  TPieceSide = (psUndefined, psLeft, psTop, psRight, psBottom);
var
  DstO: TMetaObject;
  SrcO: TMetaObject;
  SrcBmps, DstBmps: TBitmaps;
  TempBMP: TBitmap32;
  NewBMPs: TBitmaps;

  i: Integer;
  S: String;

  NewFrames: Integer;

  MergeOnSide: TPieceSide;
  SrcOffsetX: Integer;
  SrcOffsetY: Integer;
  DstOffsetX: Integer;
  DstOffsetY: Integer;

  OrigWidth, OrigHeight: Integer;

  function FindMinimumFrameCount: Integer;
  var
    SrcF, DstF: Integer;
  begin
    SrcF := SrcBmps.Count;
    DstF := DstBmps.Count;
    Result := DstF;
    while Result mod SrcF <> 0 do
      Inc(Result, DstF);
  end;

  procedure MergeImage;
  var
    Src, Dst: TBitmap32;
    NewW, NewH: Integer;

    SrcPos, DstPos: TPoint;
  begin
    Src := SrcBmps[i mod SrcBmps.Count];
    Dst := DstBmps[i mod DstBmps.Count];

    if MergeOnSide in [psLeft, psRight] then
    begin
      NewW := Src.Width + Dst.Width + SrcOffsetX + DstOffsetX;
      NewH := Max(Src.Height + SrcOffsetY, Dst.Height + DstOffsetY);
    end else begin
      NewW := Max(Src.Width + SrcOffsetX, Dst.Width + DstOffsetX);
      NewH := Src.Height + Dst.Height + SrcOffsetY + DstOffsetY;
    end;

    TempBMP.SetSize(NewW, NewH);
    TempBMP.Clear(0);

    SrcPos := Point(SrcOffsetX, SrcOffsetY);
    DstPos := Point(DstOffsetX, DstOffsetY);

    case MergeOnSide of
      psLeft: DstPos.X := DstPos.X + Src.Width;
      psRight: SrcPos.X := SrcPos.X + Dst.Width;
      psTop: DstPos.Y := DstPos.Y + Src.Height;
      psBottom: SrcPos.Y := SrcPos.Y + Dst.Height;
    end;

    Src.DrawMode := dmBlend;
    Src.CombineMode := cmMerge;
    Dst.DrawMode := dmBlend;
    Dst.CombineMode := cmMerge;

    Src.DrawTo(TempBMP, SrcPos.X, SrcPos.Y);
    Dst.DrawTo(TempBMP, DstPos.X, DstPos.Y);
  end;

  procedure SetOffsets;
  var
    ModLeft, ModTop, ModRight, ModBottom: Integer;
    SrcW, SrcH, DstW, DstH: Integer;
  begin
    SrcW := SrcBMPs[0].Width;
    SrcH := SrcBMPs[0].Height;
    DstW := OrigWidth;
    DstH := OrigHeight;
    ModLeft := 0;
    ModTop := 0;
    ModRight := 0;
    ModBottom := 0;

    // Basic stuff - apply the width and height of the image being merged, including offsets
    case MergeOnSide of
      psLeft: ModLeft := 0 - SrcW;
      psRight: ModRight := 0 - SrcW;
      psTop: ModTop := 0 - SrcH;
      psBottom: ModBottom := 0 - SrcH;
    end;

    // Apply the effects of any offsets in the applied direction
    if MergeOnSide in [psLeft, psRight] then
    begin
      ModLeft := ModLeft - DstOffsetX;
      ModRight := ModRight - SrcOffsetX;
    end;
    if MergeOnSide in [psTop, psBottom] then
    begin
      ModTop := ModTop - DstOffsetY;
      ModBottom := ModBottom - SrcOffsetY;
    end;

    // Apply the effects of any offsets in the other directions - this is tricky
    if MergeOnSide in [psLeft, psRight] then
    begin
      ModTop := ModTop - DstOffsetY;
      ModBottom := ModBottom + DstOffsetY;

      if SrcOffsetY + SrcH > DstH then
        ModBottom := ModBottom - ((SrcOffsetY + SrcH) - DstH);
    end;
    if MergeOnSide in [psTop, psBottom] then
    begin
      ModLeft := ModLeft - DstOffsetX;
      ModRight := ModRight + DstOffsetX;

      if SrcOffsetX + SrcW > DstW then
        ModRight := ModRight - ((SrcOffsetX + SrcW) - DstW);
    end;

    DstO.OffsetL := DstO.OffsetL + ModLeft;
    DstO.OffsetR := DstO.OffsetR + ModRight;
    DstO.OffsetT := DstO.OffsetT + ModTop;
    DstO.OffsetB := DstO.OffsetB + ModBottom;
  end;
begin
  DstO := GS.MetaObjects[fPieceIndex];
  DstBmps := GS.ObjectImages[fPieceIndex];

  OrigWidth := DstBmps[0].Width;
  OrigHeight := DstBmps[0].Height;

  i := aSection.LineNumeric['index'];
  SrcO := GS.MetaObjects[i];
  SrcBmps := GS.ObjectImages[i];

  S := LeftStr(LowerCase(aSection.LineTrimString['side']), 1);

  MergeOnSide := psUndefined;
  if S = 'l' then MergeOnSide := psLeft;
  if S = 'r' then MergeOnSide := psRight;
  if S = 't' then MergeOnSide := psTop;
  if S = 'b' then MergeOnSide := psBottom;

  if MergeOnSide = psUndefined then Exit;

  SrcOffsetX := aSection.LineNumeric['offset_x'];
  SrcOffsetY := aSection.LineNumeric['offset_y'];

  if SrcOffsetX <= 0 then
  begin
    DstOffsetX := 0 - SrcOffsetX;
    SrcOffsetX := 0;
  end else
    DstOffsetX := 0;

  if SrcOffsetY <= 0 then
  begin
    DstOffsetY := 0 - SrcOffsetY;
    SrcOffsetY := 0;
  end else
    DstOffsetY := 0;

  NewFrames := FindMinimumFrameCount;

  TempBMP := TBitmap32.Create;
  NewBMPs := TBitmaps.Create(false);

  for i := 0 to NewFrames-1 do
  begin
    MergeImage;
    NewBmps.Add(TempBMP);
    TempBMP := TBitmap32.Create;
  end;

  DstBMPs.Clear;
  for i := 0 to NewFrames-1 do
    DstBMPs.Add(NewBMPs[i]);

  NewBMPs.Free;

  // Now fix the trigger area
  case MergeOnSide of
    psLeft: DstO.PTriggerX := DstO.PTriggerX + SrcBmps[0].Width;
    psTop: DstO.PTriggerY := DstO.PTriggerY + SrcBmps[0].Height;
    // no change needed for right or bottom
  end;

  DstO.PTriggerX := DstO.PTriggerX + DstOffsetX;
  DstO.PTriggerY := DstO.PTriggerY + DstOffsetY;

  // Now apply offsets as need be
  SetOffsets;

  // And make sure the source piece isn't output
  if aSection.Line['keep_piece'] = nil then
    SrcO.Name := '*nil';

  TempBMP.Free;
end;

procedure TConvertFunctions.HandleObjectAdjust(aSection: TParserSection; const aIteration: Integer);
var
  O: TMetaObject;
  IsBackground: Boolean;
begin
  fPieceIndex := aSection.LineNumeric['index'];
  O := GS.MetaObjects[fPieceIndex];

  if aSection.Line['reference'] <> nil then
  begin
    O.Name := '#' + aSection.LineTrimString['reference'];
    O.OffsetL := aSection.LineNumeric['offset_left'];
    O.OffsetR := aSection.LineNumeric['offset_right'];
    O.OffsetT := aSection.LineNumeric['offset_top'];
    O.OffsetB := aSection.LineNumeric['offset_bottom'];
    O.ConvertFlip := (aSection.Line['flip_horizontal'] <> nil);
    O.ConvertInvert := (aSection.Line['flip_vertical'] <> nil);
    Exit;
  end;

  IsBackground := LeftStr(O.Name, 1) = '&';
  if IsBackground then
  begin
    O.Name := RightStr(O.Name, Length(O.Name)-1);
  end;

  if aSection.Line['name'] <> nil then O.Name := aSection.LineTrimString['name'];

  O.ResizeHorizontal := (aSection.Line['resize_horizontal'] <> nil);
  O.ResizeVertical := (aSection.Line['resize_vertical'] <> nil);

  aSection.DoForEachSection('merge', HandleObjectMerge);

  if IsBackground then
    O.Name := '&' + O.Name;
end;

procedure TConvertFunctions.HandleTerrainAdjust(aSection: TParserSection; const aIteration: Integer);
var
  T: TMetaTerrain;
begin
  fPieceIndex := aSection.LineNumeric['index'];
  T := GS.MetaTerrains[fPieceIndex];

  if aSection.Line['reference'] <> nil then
  begin
    T.Name := '#' + aSection.LineTrimString['reference'];
    T.OffsetL := aSection.LineNumeric['offset_left'];
    T.OffsetR := aSection.LineNumeric['offset_right'];
    T.OffsetT := aSection.LineNumeric['offset_top'];
    T.OffsetB := aSection.LineNumeric['offset_bottom'];
    T.ConvertRotate := (aSection.Line['rotate'] <> nil);
    T.ConvertFlip := (aSection.Line['flip_horizontal'] <> nil);
    T.ConvertInvert := (aSection.Line['flip_vertical'] <> nil);
    Exit;
  end;

  if aSection.Line['name'] <> nil then T.Name := aSection.LineTrimString['name'];
end;

procedure Prepare(aGS: TBaseGraphicSet);
var
  i: Integer;
  n: Integer;

  T: TMetaTerrain;
  O: TMetaObject;

  ReplaceIndex: Integer;
  ReplaceRotate, ReplaceFlip, ReplaceInvert: Boolean;
begin
  GS := aGS;

  n := 0;
  for i := 0 to GS.MetaTerrains.Count-1 do
  begin
    T := GS.MetaTerrains[i];
    if T.Name = '' then
      T.Name := 'terrain_' + LeadZeroStr(n, 2);

    ShrinkTerrain(T, GS.TerrainImages[i]);

    ReplaceIndex := i;
    if FindTerrainMatch(ReplaceIndex, ReplaceRotate, ReplaceFlip, ReplaceInvert) then
    begin
      T.Name := '*' + IntToStr(ReplaceIndex);
      T.ConvertFlip := ReplaceFlip;
      T.ConvertInvert := ReplaceInvert;
      T.ConvertRotate := ReplaceRotate;
      Continue;
    end;

    if LeftStr(T.Name, 1) <> '*' then
      Inc(n);
  end;

  n := 0;
  for i := 0 to GS.MetaObjects.Count-1 do
  begin
    O := GS.MetaObjects[i];
    if O.Name = '' then
      O.Name := 'object_' + LeadZeroStr(n, 2);

    ShrinkObject(O, GS.ObjectImages[i]);

    // We won't try to check for matches here as they're far less common AND far
    // more complicated to detect. We'll let this be done manually.

    // However, we will address some common situations.

    if O.TriggerType = 13 {Preplaced Lemming} then
    begin
      O.Name := '*lemming';
      O.OffsetL := 0 - O.PTriggerX;
      O.OffsetT := 0 - O.PTriggerY;
      // We must account for the differences in trigger positions; some use Y = 9, some use Y = 10
    end;

    if O.TriggerType = 14 {Pickup Skill} then
      O.Name := '*pickup';

    if O.TriggerType = 32 {Background Image} then
      O.Name := '&' + O.Name;

    if O.TriggerType in [9, 10, 16, 25, 28, 29] then
      O.Name := '*nil';

    if LeftStr(O.Name, 1) <> '*' then
      Inc(n);
  end;
end;

procedure ShrinkTerrain(T: TMetaTerrain; BMP: TBitmap32);
var
  TempBMP: TBitmap32;
  x, y: Integer;
  MinX, MaxX, MinY, MaxY: Integer;
begin
  TempBMP := TBitmap32.Create;

  MinX := BMP.Width;
  MaxX := 0;
  MinY := BMP.Height;
  MaxY := 0;

  for y := 0 to BMP.Height-1 do
    for x := 0 to BMP.Width-1 do
    begin
      if BMP.Pixel[x, y] and $FF000000 = 0 then Continue;
      if x < MinX then MinX := x;
      if x > MaxX then MaxX := x;
      if y < MinY then MinY := y;
      if y > MaxY then MaxY := y;
    end;

  T.OffsetL := MinX;
  T.OffsetT := MinY;
  T.OffsetR := ((BMP.Width - 1) - MaxX);
  T.OffsetB := ((BMP.Height - 1) - MaxY);

  TempBMP.SetSize(MaxX - MinX + 1, MaxY - MinY + 1);
  for y := MinY to MaxY do
    for x := MinX to MaxX do
      TempBMP.Pixel[x - MinX, y - MinY] := BMP.Pixel[x, y];

  BMP.Assign(TempBMP);

  TempBMP.Free;
end;

function FindTerrainMatch(var Index: Integer; var Rotate, Flip, Invert: Boolean): Boolean;
var
  i: Integer;
  TempBMP: TBitmap32;
  InternalRotate, InternalFlip, InternalInvert: Boolean;
begin
  Result := false;
  TempBMP := TBitmap32.Create;
  try
    for i := 0 to Index-1 do
    begin
      if GS.MetaTerrains[i].Steel <> GS.MetaTerrains[Index].Steel then Continue;
      if not CheckSizeMatch(GS.TerrainImages[i], GS.TerrainImages[Index]) then Continue;
      if not CheckHashMatch(GS.TerrainImages[i], GS.TerrainImages[Index]) then Continue;

      for InternalRotate := false to true do
        for InternalFlip := false to true do
          for InternalInvert := false to true do
          begin
            TempBMP.Assign(GS.TerrainImages[i]);
            Rotate := InternalRotate;
            Flip := InternalFlip;
            Invert := InternalInvert;

            if Rotate then TempBMP.Rotate90;
            if Flip then TempBMP.FlipHorz;
            if Invert then TempBMP.FlipVert;
            if not CheckImageMatch(TempBMP, GS.TerrainImages[Index]) then Continue;

            Result := true;
            Index := i;
            Exit;
          end;
    end;
  finally
    TempBMP.Free;
  end;
end;

procedure ShrinkObject(O: TMetaObject; BMPs: TBitmaps);
var
  TempBMP: TBitmap32;
  i, x, y: Integer;
  MinX, MaxX, MinY, MaxY: Integer;
begin
  TempBMP := TBitmap32.Create;

  MinX := BMPs[0].Width;
  MaxX := 0;
  MinY := BMPs[0].Height;
  MaxY := 0;

  for i := 0 to BMPs.Count-1 do
    for y := 0 to BMPs[i].Height-1 do
      for x := 0 to BMPs[i].Width-1 do
      begin
        if BMPs[i].Pixel[x, y] and $FF000000 = 0 then Continue;
        if x < MinX then MinX := x;
        if x > MaxX then MaxX := x;
        if y < MinY then MinY := y;
        if y > MaxY then MaxY := y;
      end;

  O.OffsetL := O.OffsetL + MinX;
  O.OffsetT := O.OffsetT + MinY;
  O.OffsetR := O.OffsetR + ((BMPs[0].Width - 1) - MaxX);
  O.OffsetB := O.OffsetB + ((BMPs[0].Height - 1) - MaxY);

  O.PTriggerX := O.PTriggerX - MinX;
  O.PTriggerY := O.PTriggerY - MinY;

  TempBMP.SetSize(MaxX - MinX + 1, MaxY - MinY + 1);
  for i := 0 to BMPs.Count-1 do
  begin
    for y := MinY to MaxY do
      for x := MinX to MaxX do
        TempBMP.Pixel[x - MinX, y - MinY] := BMPs[i].Pixel[x, y];
    BMPs[i].Assign(TempBMP);
  end;

  TempBMP.Free;
end;

end.