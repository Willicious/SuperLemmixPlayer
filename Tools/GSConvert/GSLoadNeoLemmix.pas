unit GSLoadNeoLemmix;

// Loads a NeoLemmix graphic set into the editor's internal format. To use,
// create a TNeoLemmixGraphicSet object, then call:
//
// <TBaseGraphicSet> := <TNeoLemmixGraphicSet>.LoadGraphicSet(<file>);
//
// The TBaseGraphicSet object is created during TNeoLemmixGraphicSet.LoadGraphicSet, so you should
// not use <TBaseGraphicSet> := TBaseGraphicSet.Create; beforehand.
//
// Once TNeoLemmixGraphicSet.LoadGraphicSet has been allowed to run, there is no need to keep the
// TNeoLemmixGraphicSet object around, it can be freed.

// Saving NeoLemmix graphic sets is very similar, but use this instead:
//
// <TNeoLemmixGraphicSet>.SaveGraphicSet(<file>, <TBaseGraphicSet>);

// NeoLemmix-format graphic sets always use 24-bit + 8-bit alpha images. Current versions of
// NeoLemmix do not support alpha values other than 0 or 255 (anything non-zero will be treated
// as 255), but nonetheless this unit can save and load them with values inbetween.

// Proper specification of this format requires that the header is the first non-comment section.
// This unit will follow this specification when saving; however it can load files that do not have
// the header first, as long as the header is present somewhere.

// Graphics in a NeoLemmix graphic set are almost just an array of ARGB pixels. However, if the A
// is zero, then the RGB is omitted and the next pixel is started immediately.

// The encode graphic function in this unit is non-destructive, so it is safe to pass images to it
// directly without an intermediary TBitmap32 object.

interface

uses
  Dialogs,
  Classes, SysUtils, LemGraphicSet, LemDosCmp, GR32;

const
  gsVersionNumber = 0;

  dtSecMarker = $FF;

  dtEof = $00;      //not strictly required
  dtComment = $01;
  dtHeader = $02;
  dtObject = $03;
  dtTerrain = $04;
  dtSound = $05;
  dtLemming = $06;
  dtNames = $07;
  dtOffsets = $08;

type

  ColorEntry = packed record
    case Byte of
      0: (A, R, G, B: Byte); // don't think this structure is ever needed, but nice to have just in case
      1: (ARGB: TColor32);
  end;

  NeoLemmixHeader = packed record
    VersionNumber: Byte;
    Resolution: Byte;
    Updated: Byte;
    Reserved: Array[0..12] of Byte;
    KeyColors: Array[0..7] of ColorEntry;
  end;

  NeoLemmixObjectData = packed record
    ObjectFlags: Word;
    FrameCount: Word;
    PreviewFrame: Word;
    KeyFrame: Word;
    BaseLoc: LongWord;
    TriggerEff: Byte;
    TriggerSound: Byte;
    PTriggerX: SmallInt;
    PTriggerY: SmallInt;
    PTriggerW: SmallInt;
    PTriggerH: SmallInt;
    Reserved: Array[0..1] of Byte;
    STriggerX: SmallInt;
    STriggerY: SmallInt;
    STriggerW: SmallInt;
    STriggerH: SmallInt;
    Resize: Byte;
    Reserved2: Array[0..6] of Byte;
  end;

  NeoLemmixTerrainData = packed record
    TerrainFlags: Word;
    BaseLoc: LongWord;
    Reserved: Array[0..9] of Byte;
  end;

  NeoLemmixSoundData = packed record
    SoundID: Byte;
    SoundLoc: LongWord;
  end;

  TNeoLemmixGraphicSetClass = class of TNeoLemmixGraphicSet;
  TNeoLemmixGraphicSet = class(TComponent)
    private
      procedure FixBmpSize(aBmp: TBitmap32; aSrcRes: Integer);
      procedure FixObject(aObject: TMetaObject; aSrcRes: Integer);
    public
      function LoadGraphicSet(fn: String): TBaseGraphicSet;
      function LoadHeader(aStream: TStream): NeoLemmixHeader;
      function GetNextSection(srcStream: TStream; dstStream: TStream): Byte;
      function DecodeGraphic(aStream: TStream; Loc: LongWord): TBitmap32; overload;
      function DecodeGraphic(aStream: TStream): TBitmap32; overload;
      function DecodeSound(aStream: TStream; Loc: LongWord): TMemoryStream;
  end;

  function LeadZeroStr(aValue, aLen: Integer): String;

implementation

function LeadZeroStr(aValue, aLen: Integer): String;
begin
  Result := IntToStr(aValue);
  if Length(Result) < aLen then
    Result := StringOfChar('0', Length(Result) - aLen) + Result;
end;

procedure TNeoLemmixGraphicSet.FixBmpSize(aBmp: TBitmap32; aSrcRes: Integer);
var
  TempBMP: TBitmap32;
begin
  TempBMP := TBitmap32.Create;
  TempBMP.Assign(aBmp);
  aBmp.SetSize(aBmp.Width * 8 div aSrcRes, aBmp.Height * 8 div aSrcRes);
  aBmp.Clear(0);
  TempBMP.DrawTo(aBmp, aBmp.BoundsRect, TempBMP.BoundsRect);
  TempBMP.Free;
end;

procedure TNeoLemmixGraphicSet.FixObject(aObject: TMetaObject; aSrcRes: Integer);
  function Fix(aValue: Integer): Integer;
  begin
    Result := aValue * 8 div aSrcRes;
  end;
begin
  with aObject do
  begin
    PTriggerX := Fix(PTriggerX);
    PTriggerY := Fix(PTriggerY);
    PTriggerW := Fix(PTriggerW);
    PTriggerH := Fix(PTriggerH);
    STriggerX := Fix(STriggerX);
    STriggerY := Fix(STriggerY);
    STriggerW := Fix(STriggerW);
    STriggerH := Fix(STriggerH);
  end;
end;

function TNeoLemmixGraphicSet.LoadGraphicSet(fn: String): TBaseGraphicSet;
var
  MetaInfoStream, GfxStream: TMemoryStream;
  CompressedStream: TMemoryStream;
  TempStream: TMemoryStream;
  TempHeader: NeoLemmixHeader;
  TempTerrain: NeoLemmixTerrainData;
  TempObject: NeoLemmixObjectData;
  TempSound: NeoLemmixSoundData;

  TempGSTerrain: TMetaTerrain;
  TempGSObject: TMetaObject;
  TempGSSound: TMemoryStream; //since the GS editor doesn't actually handle sounds in any special way
  TempBMP: TBitmap32;
  TempBMPs: TBitmaps;

  i: Integer;
  li: Integer;
  b: Byte;
  s: String;

  FlushColors: Boolean;
  SrcRes: Integer;

  function GetAverageColor(BMPs: TBitmaps): TColor32;
  var
    i, x, y: Integer;
    R, G, B: Int64;
    C: TColor32;
    Count: Int64;

    function Restrict(aValue: Int64): Int64;
    begin
      Result := aValue;
      if Result > 255 then Result := 255;
      if Result < 0 then Result := 0;
      // Should NEVER happen, but just in case.
    end;
  begin
    R := 0;
    G := 0;
    B := 0;
    Count := 0;
    for i := 0 to BMPs.Count-1 do
      for y := 0 to BMPs[i].Height-1 do
        for x := 0 to BMPs[i].Width-1 do
        begin
          C := BMPs[i].Pixel[x, y];
          if C and $FF000000 = 0 then Continue;
          R := R + RedComponent(C);
          G := G + GreenComponent(C);
          B := B + BlueComponent(C);
          Inc(Count);
        end;
    R := Restrict(R div Count);
    G := Restrict(G div Count);
    B := Restrict(B div Count);
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
  end;
begin
  Result := TBaseGraphicSet.Create;
  MetaInfoStream := TMemoryStream.Create;
  GfxStream := TMemoryStream.Create;
  CompressedStream := TMemoryStream.Create;
  TempStream := TMemoryStream.Create;

  CompressedStream.LoadFromFile(fn);

  MetaInfoStream.Seek(0, soFromBeginning);
  GfxStream.Seek(0, soFromBeginning);
  CompressedStream.Seek(0, soFromBeginning);
  TempStream.Seek(0, soFromBeginning);

  DecompressDat(CompressedStream, MetaInfoStream);
  DecompressDat(CompressedStream, GfxStream);

  CompressedStream.Free;

  TempHeader := LoadHeader(MetaInfoStream);
  SrcRes := TempHeader.Resolution;
  Result.Resolution := 8;

  Result.Name := ChangeFileExt(ExtractFileName(fn), '');

  for i := 0 to 7 do
    Result.KeyColors[i] := TempHeader.KeyColors[i].ARGB;

  if not (TempHeader.Updated = 1) then
  begin
    FlushColors := true;
    Result.KeyColors[1] := Result.KeyColors[0];
    for i := 2 to 7 do
      Result.KeyColors[i] := 0;
  end else
    FlushColors := false;

  MetaInfoStream.Seek(0, soFromBeginning);

  b := GetNextSection(MetaInfoStream, TempStream);
  while b <> dtEof do
  begin
    TempStream.Seek(0, soFromBeginning);
    case b of
      dtTerrain: begin
                   TempStream.Read(TempTerrain, SizeOf(TempTerrain));
                   TempGSTerrain := TMetaTerrain.Create;
                   TempGSTerrain.Steel := ((TempTerrain.TerrainFlags and $0001) <> 0);
                   TempGSTerrain.Name := 'T' + IntToStr(Result.MetaTerrains.Count);
                   TempBMP := DecodeGraphic(GfxStream, TempTerrain.BaseLoc);
                   Result.MetaTerrains.Add(TempGSTerrain);
                   Result.TerrainImages.Add(TempBMP);
                   FixBmpSize(TempBMP, SrcRes);
                 end;
      dtObject:  begin
                   TempStream.Read(TempObject, SizeOf(TempObject));
                   TempGSObject := TMetaObject.Create;
                   TempGSObject.Name := 'O' + IntToStr(Result.MetaObjects.Count);
                   TempGSObject.PreviewFrame := TempObject.PreviewFrame;
                   TempGSObject.KeyFrame := TempObject.KeyFrame;
                   TempGSObject.TriggerAnim := ((TempObject.ObjectFlags and $0001) <> 0);
                   TempGSObject.TriggerType := TempObject.TriggerEff;
                   TempGSObject.TriggerSound := TempObject.TriggerSound;
                   TempGSObject.PTriggerX := TempObject.PTriggerX;
                   TempGSObject.PTriggerY := TempObject.PTriggerY;
                   TempGSObject.PTriggerW := TempObject.PTriggerW;
                   TempGSObject.PTriggerH := TempObject.PTriggerH;
                   TempGSObject.STriggerX := TempObject.STriggerX;
                   TempGSObject.STriggerY := TempObject.STriggerY;
                   TempGSObject.STriggerW := TempObject.STriggerW;
                   TempGSObject.STriggerH := TempObject.STriggerH;
                   TempGSObject.RandomFrame := ((TempObject.ObjectFlags and $0002) <> 0);
                   TempGSObject.ResizeHorizontal := false;
                   TempGSObject.ResizeVertical := false;
                   TempGSObject.NoAutoResizeSettings := false;

                   TempBMPs := TBitmaps.Create;
                   for i := 0 to TempObject.FrameCount-1 do
                   begin
                     if i = 0 then
                       TempBMP := DecodeGraphic(GfxStream, TempObject.BaseLoc)
                     else
                       TempBMP := DecodeGraphic(GfxStream);
                     TempBMPs.Add(TempBmp);
                     FixBmpSize(TempBmp, SrcRes);
                   end;

                   //if FlushColors then
                   //begin
                     if TempObject.TriggerEff = 14 then
                     begin
                       Result.KeyColors[4] := TempBMPs[1].Pixel[5, 0] or $FF000000;
                       Result.KeyColors[5] := TempBMPs[1].Pixel[5, 1] or $FF000000;
                     end;

                     if TempObject.TriggerEff in [7, 8, 19] then
                     begin
                       Result.KeyColors[3] := GetAverageColor(TempBMPs);
                     end;
                   //end;

                   FixObject(TempGSObject, SrcRes);

                   Result.ObjectImages.Add(TempBMPs);
                   Result.MetaObjects.Add(TempGSObject);

                 end;
      dtSound:  begin
                  TempStream.Read(TempSound, SizeOf(TempSound));
                  TempGSSound := DecodeSound(GfxStream, TempSound.SoundLoc);
                  if Result.Sounds[TempSound.SoundID] <> nil then Result.Sounds[TempSound.SoundID].Free;
                  Result.Sounds[TempSound.SoundID] := TempGSSound;
                end;
      dtLemming: begin
                   s := '';
                   repeat
                     MetaInfoStream.Read(b, 1);
                     if b <> 0 then s := s + Chr(b);
                   until b = 0;
                   Result.LemmingSprites := s;
                 end;
      dtNames: begin
                 FlushColors := false;
                 for i := 0 to Result.MetaObjects.Count-1 do
                 begin
                   s := '';
                   repeat
                     MetaInfoStream.Read(b, 1);
                     if b <> 0 then s := s + Chr(b);
                   until b = 0;
                   if s = '' then s := 'object_' + LeadZeroStr(i, 2);
                   Result.MetaObjects[i].Name := s;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaObjects[i].OffsetL := 0;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaObjects[i].OffsetT := 0;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaObjects[i].OffsetR := 0;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaObjects[i].OffsetB := 0;
                   MetaInfoStream.Read(b, 1);
                   Result.MetaObjects[i].ConvertFlip := (b and $01) <> 0;
                   Result.MetaObjects[i].ConvertInvert := (b and $02) <> 0;
                   for li := 17 to 31 do
                     MetaInfoStream.Read(b, 1);
                 end;

                 for i := 0 to Result.MetaTerrains.Count-1 do
                 begin
                   s := '';
                   repeat
                     MetaInfoStream.Read(b, 1);
                     if b <> 0 then s := s + Chr(b);
                   until b = 0;
                   if s = '' then s := 'terrain_' + LeadZeroStr(i, 2);
                   Result.MetaTerrains[i].Name := s;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaTerrains[i].OffsetL := li;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaTerrains[i].OffsetT := li;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaTerrains[i].OffsetR := li;
                   MetaInfoStream.Read(li, 4);
                   Result.MetaTerrains[i].OffsetB := li;
                   MetaInfoStream.Read(b, 1);
                   Result.MetaTerrains[i].ConvertFlip := (b and $01) <> 0;
                   Result.MetaTerrains[i].ConvertInvert := (b and $02) <> 0;
                   Result.MetaTerrains[i].ConvertRotate := (b and $04) <> 0;
                   for li := 17 to 31 do
                     MetaInfoStream.Read(b, 1);
                 end;
               end;
    end;
    TempStream.Seek(0, soFromBeginning);
    b := GetNextSection(MetaInfoStream, TempStream);
  end;

  GfxStream.Free;
  MetaInfoStream.Free;
  TempStream.Free;

end;

function TNeoLemmixGraphicSet.DecodeSound(aStream: TStream; Loc: LongWord): TMemoryStream;
var
  lw: LongWord;
begin
  aStream.Seek(Loc, soFromBeginning);
  aStream.Read(lw, 4);
  Result := TMemoryStream.Create;
  Result.Seek(0, soFromBeginning);
  Result.CopyFrom(aStream, lw);
end;

function TNeoLemmixGraphicSet.DecodeGraphic(aStream: TStream; Loc: LongWord): TBitmap32;
begin
  aStream.Seek(Loc, soFromBeginning);
  Result := DecodeGraphic(aStream);
end;

function TNeoLemmixGraphicSet.DecodeGraphic(aStream: TStream): TBitmap32;
var
  x, y, W, H: LongWord;
  a, r, g, b: Byte;
begin
  Result := TBitmap32.Create;
  aStream.Read(W, 4);
  aStream.Read(H, 4);
  Result.SetSize(W, H);
  for y := 0 to H-1 do
    for x := 0 to W-1 do
    begin
      aStream.Read(a, 1);
      if a = 0 then
        Result.Pixel[x, y] := 0
      else begin
        aStream.Read(r, 1);
        aStream.Read(g, 1);
        aStream.Read(b, 1);
        Result.Pixel[x, y] := (a shl 24) + (r shl 16) + (g shl 8) + b;
      end;
    end;
end;

function TNeoLemmixGraphicSet.LoadHeader(aStream: TStream): NeoLemmixHeader;
var
  b: Byte;
  TempStream: TMemoryStream;
begin
  aStream.Seek(0, soFromBeginning);
  TempStream := TMemoryStream.Create;
  repeat
    TempStream.Seek(0, soFromBeginning);
    b := GetNextSection(aStream, TempStream);
  until b in [dtHeader, dtEof];
  TempStream.Seek(0, soFromBeginning);
  if b = dtHeader then TempStream.Read(Result, SizeOf(Result));
  TempStream.Free;
end;

function TNeoLemmixGraphicSet.GetNextSection(srcStream: TStream; dstStream: TStream): Byte;
var
  b: Byte;
  i: Integer;
begin
  b := 0;
  i := 0;
  while b <> $FF do
    srcStream.Read(b, 1);
  srcStream.Read(Result, 1);
  case Result of
    dtEof: Exit;
    dtComment: while true do
               begin
                 srcStream.Read(b, 1);
                 if b = $FF then
                 begin
                   srcStream.Position := srcStream.Position - 1;
                   Exit;
                 end;
                 dstStream.Write(b, 1);
               end;
    dtHeader: i := SizeOf(NeoLemmixHeader);
    dtObject: i := SizeOf(NeoLemmixObjectData);
    dtTerrain: i := SizeOf(NeoLemmixTerrainData);
    dtSound: i := SizeOf(NeoLemmixSoundData);
  end;
  while i > 0 do
  begin
    srcStream.Read(b, 1);
    dstStream.Write(b, 1);
    i := i - 1;
  end;
end;

end.
