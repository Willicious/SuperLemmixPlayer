{$include lem_directives.inc}
unit LemNeoGraphicSet;

interface

uses
  Classes, SysUtils,
  GR32,
  UMisc,
  GameSound,
  LemRenderHelpers,
  LemTypes,
  LemMetaObject,
  LemMetaTerrain,
  LemGraphicSet,
  LemDosGraphicSet, // backwards-compatibility
  LemDosStructures,
  LemDosBmp,
  LemDosCmp,
  LemNeoOnline,
  LemNeoEncryption, Dialogs, Contnrs;

const
  dtSecMarker = $FF;

  dtEof = $00;      //not strictly required
  dtComment = $01;
  dtHeader = $02;
  dtObject = $03;
  dtTerrain = $04;
  dtSound = $05;
  dtLemming = $06;

type

  NeoLemmixSoundData = packed record
    SoundID: Byte;
    SoundLoc: LongWord;
  end;

  NeoLemmixColorEntry = packed record
    case Byte of
      0: (A, R, G, B: Byte); // don't think this structure is ever needed, but nice to have just in case
      1: (ARGB: TColor32);
  end;

  NeoLemmixHeader = packed record
    VersionNumber: Byte;
    Resolution: Byte;
    Reserved: Array[0..13] of Byte;
    KeyColors: Array[0..7] of NeoLemmixColorEntry;
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
    Reserved2: Array[0..7] of Byte;
  end;

  NeoLemmixTerrainData = packed record
    TerrainFlags: Word;
    BaseLoc: LongWord;
    Reserved: Array[0..9] of Byte;
  end;

  TBaseNeoGraphicSet = class (TBaseDosGraphicSet)
    protected
      fFile: string;

      fLoadedSections: Boolean;

      fResolution      : Byte;

      fOnlineEnabled: Boolean; // REALLY bad place to put it, I know, but it works every time, until I bother tidying up other code.

      fMetaDataStream: TMemoryStream;
      fGraphicsStream: TMemoryStream;

      procedure DoReadMetaData(XmasPal : Boolean = false); override;
      procedure DoReadData; override;
      procedure GetSections;

      function LoadHeader(aStream: TStream): NeoLemmixHeader;
      function GetNextSection(srcStream: TStream; dstStream: TStream): Byte;
      function DecodeGraphic(aStream: TStream): TBitmap32; overload;
      function DecodeGraphic(aStream: TStream; Loc: LongWord): TBitmap32; overload;
      procedure DecodeSound(Src: TStream; Dst: TMemoryStream; Loc: LongWord);

      procedure SetGraphicFile(aValue: String);
      procedure LoadVgaspec;
      procedure ObtainGraphicSet(aName: String); // also shouldn't be here
    public
      CustSounds: Array[0..255] of TMemoryStream;

      constructor Create; override;
      destructor Destroy; override;
      procedure LoadFromStream(aStream: TStream);
      property Resolution: Byte read fResolution write fResolution;
      property OnlineEnabled: Boolean read fOnlineEnabled write fOnlineEnabled;
    published
      property GraphicSetFile: string read fFile write SetGraphicFile;
  end;

  TNeoLemmixGraphicSets = class(TObjectList)
    private
      function GetItem(Index: Integer): TBaseNeoGraphicSet;
    public
      function Add(Item: TBaseNeoGraphicSet): Integer; overload;
      function Add: TBaseNeoGraphicSet; overload;
      property Items[Index: Integer]: TBaseNeoGraphicSet read GetItem; default;
      property List;
  end;

implementation

constructor TBaseNeoGraphicSet.Create;
var
  i: Integer;
begin
  inherited Create;
  fMetaDataStream := TMemoryStream.Create;
  fGraphicsStream := TMemoryStream.Create;

  fAutoSteel := true; //NeoLemmix graphic sets ALWAYS support autosteel
  fGraphicSetName := ChangeFileExt(ExtractFileName(fFile), '');
  fLoadedSections := false;
  Resolution := 8; //backwards compatibility

  for i := 0 to 255 do
    CustSounds[i] := TMemoryStream.Create;
end;

destructor TBaseNeoGraphicSet.Destroy;
var
  i: Integer;
begin
  for i := 0 to 255 do
    CustSounds[i].Free;

  fMetaDataStream.Destroy;
  fGraphicsStream.Destroy;
  inherited Destroy;
end;

procedure TBaseNeoGraphicSet.ObtainGraphicSet(aName: String);
var
  SL: TStringList;
begin
  // Is it passed with or without path / extension / etc? Not sure, so let's clear them just in case.
  aName := ExtractFileName(aName);
  aName := ChangeFileExt(aName, '');
  SL := TStringList.Create;
  if DownloadToStringList(NX_STYLES_URL, SL) then
  begin
    if SL.Values[aName] = '' then Exit;
    ForceDirectories(AppPath + 'styles/');
    DownloadToFile(NX_BASE_URL + LowerCase(aName) + '.dat', AppPath + 'styles/' + LowerCase(aName) + '.dat');
  end;
  SL.Free;
end;

procedure TBaseNeoGraphicSet.SetGraphicFile(aValue: String);
var
  i: Integer;
begin
  fLoadedSections := false;
  fFile := aValue;
  for i := 0 to 255 do
    CustSounds[i].Clear;
end;

procedure TBaseNeoGraphicSet.LoadFromStream(aStream: TStream);
var
  Decompressor: TDosDatDecompressor;
begin
  fLoadedSections := true;

  Decompressor := TDosDatDecompressor.Create;

  aStream.Seek(0, soFromBeginning);
  fMetaDataStream.Clear;
  fGraphicsStream.Clear;

  try
    fMetaDataStream.Seek(0, soFromBeginning);
    fGraphicsStream.Seek(0, soFromBeginning);

    Decompressor.DecompressSection(aStream, fMetaDataStream);
    Decompressor.DecompressSection(aStream, fGraphicsStream);
  finally
    Decompressor.Free;
  end;
end;

procedure TBaseNeoGraphicSet.GetSections;
var
  DataStream: TMemoryStream;
  Decompressor: TDosDatDecompressor;
begin
  if fLoadedSections then Exit;
  fLoadedSections := true;

  Decompressor := TDosDatDecompressor.Create;


  if FileExists(GraphicSetFile) and (ParamStr(1) = 'testmode') then
  begin
    DataStream := TMemoryStream.Create;
    DataStream.LoadFromFile(GraphicSetFile);
  end else begin
    DataStream := CreateDataStream(GraphicSetFile, ldtStyle, true); // Allow external
    if (DataStream = nil) and (fOnlineEnabled) then
    begin
      ObtainGraphicSet(GraphicSetFile);
      DataStream := CreateDataStream(GraphicSetFile, ldtStyle, true); // Allow external for sure here
    end;
  end;

  fMetaDataStream.Clear;
  fGraphicsStream.Clear;

  try
    fMetaDataStream.Seek(0, soFromBeginning);
    fGraphicsStream.Seek(0, soFromBeginning);

    Decompressor.DecompressSection(DataStream, fMetaDataStream);
    Decompressor.DecompressSection(DataStream, fGraphicsStream);
  finally
    DataStream.Free;
    Decompressor.Free;
  end;
end;

procedure TBaseNeoGraphicSet.DoReadMetaData(XmasPal: Boolean = false);
var
  gsHeader: NeoLemmixHeader;
  gsTerrain: NeoLemmixTerrainData;
  gsObject: NeoLemmixObjectData;
  gsSound: NeoLemmixSoundData;
  //TempBMP: TBitmap32;

  TempTerrain: TMetaTerrain;
  TempObject: TMetaObject;

  TempStream: TMemoryStream;

  i: Integer;
  b: Byte;
  s: String;
  //lw: LongWord;
begin

  if GraphicSetFile = '' then
  begin
    inherited;
    exit;
  end;

  GetSections;
  gsHeader := LoadHeader(fMetaDataStream);
  fResolution := gsHeader.Resolution;

  SetLength(fPalette, 32);

  for i := 0 to 7 do
    fPalette[i] := DosVgaColorToColor32(DosInLevelPalette[0]);
  for i := 8 to 15 do
    fPalette[i] := gsHeader.KeyColors[i-8].ARGB and not ($FF000000);
  for i := 16 to 31 do
    fPalette[i] := fPalette[i-16];
  fPalette[7] := fPalette[8];
  fBrickColor := fPalette[8];

  // Now load the pieces
  TempStream := TMemoryStream.Create;
  fMetaDataStream.Seek(0, soFromBeginning);
  try
    TempStream.Seek(0, soFromBeginning);
    b := GetNextSection(fMetaDataStream, TempStream);
    while b <> dtEof do
    begin
      TempStream.Seek(0, soFromBeginning);
      case b of
        dtTerrain: begin
                     TempStream.Read(gsTerrain, SizeOf(gsTerrain));
                     TempTerrain := MetaTerrains.Add;
                     TempTerrain.ImageLocation := gsTerrain.BaseLoc;
                     if (gsTerrain.TerrainFlags and 1) <> 0 then
                       TempTerrain.Unknown := 1
                     else
                       TempTerrain.Unknown := 0;
                   end;
        dtObject:  begin
                     TempStream.Read(gsObject, SizeOf(gsObject));
                     TempObject := MetaObjects.Add;
                     if gsObject.TriggerEff = 23 then
                     begin
                       TempObject.AnimationType := 3;
                       TempObject.StartAnimationFrameIndex := 1;
                     end else if (gsObject.ObjectFlags and 1) <> 0 then
                       TempObject.AnimationType := 1
                     else
                       TempObject.AnimationType := 2;
                     TempObject.AnimationFrameCount := gsObject.FrameCount;
                     Tempobject.AnimationFramesBaseLoc := gsObject.BaseLoc;
                     TempObject.PreviewFrameIndex := gsObject.PreviewFrame;
                     TempObject.TriggerNext := gsObject.KeyFrame;
                     TempObject.TriggerEffect := gsObject.TriggerEff;
                     TempObject.TriggerLeft := gsObject.PTriggerX;
                     TempObject.TriggerTop := gsObject.PTriggerY;
                     TempObject.TriggerWidth := gsObject.PTriggerW;
                     TempObject.TriggerHeight := gsObject.PTriggerH;
                     TempObject.TriggerPointX := gsObject.STriggerX;
                     TempObject.TriggerPointY := gsObject.STriggerY;
                     TempObject.TriggerPointW := gsObject.STriggerW;
                     TempObject.TriggerPointH := gsObject.STriggerH;

                     TempObject.RandomStartFrame := (gsObject.ObjectFlags and 2) <> 0;

                     if Resolution <> 8 then
                       with TempObject do
                       begin
                         TriggerLeft := (TriggerLeft * 8) div Resolution;
                         TriggerTop := (TriggerTop * 8) div Resolution;
                         TriggerWidth := (TriggerWidth * 8) div Resolution;
                         TriggerHeight := (TriggerHeight * 8) div Resolution;
                         TriggerPointX := (TriggerPointX * 8) div Resolution;
                         TriggerPointY := (TriggerPointY * 8) div Resolution;
                         TriggerPointW := (TriggerPointW * 8) div Resolution;
                         TriggerPointH := (TriggerPointH * 8) div Resolution;
                         if (TriggerWidth * Resolution) div 8 <> gsObject.PTriggerW then TriggerWidth := TriggerWidth + 1;
                         if (TriggerHeight * Resolution) div 8 <> gsObject.PTriggerH then TriggerHeight := TriggerHeight + 1;
                         if (TriggerPointW * Resolution) div 8 <> gsObject.STriggerW then TriggerPointW := TriggerPointW + 1;
                         if (TriggerPointH * Resolution) div 8 <> gsObject.STriggerH then TriggerPointH := TriggerPointH + 1;
                       end;

                     TempObject.SoundEffect := gsObject.TriggerSound;
                   end;
        dtSound: begin
                   TempStream.Read(gsSound, SizeOf(gsSound));
                   DecodeSound(fGraphicsStream, CustSounds[gsSound.SoundID], gsSound.SoundLoc);
                 end;
        dtLemming: begin
                     s := '';
                     repeat
                       fMetaDataStream.Read(b, 1);
                       if b <> 0 then s := s + Chr(b);
                     until b = 0;
                     fLemmingSprites := s;
                   end;
      end;
      TempStream.Seek(0, soFromBeginning);
      b := GetNextSection(fMetaDataStream, TempStream);
    end;
  finally
    TempStream.Free;
  end;
end;

procedure TBaseNeoGraphicSet.DecodeSound(Src: TStream; Dst: TMemoryStream; Loc: LongWord);
// Yes, this just loads it as a stream. Since BASS can handle WAV (or OGG for that matter)
// sound data directly, no need to do any fancy stuff.
// As for the unusual structure (as a procedure, etc) this is just because it's less error-prone this way,
// by having the streams already exist and just clearing unneeded ones rather than freeing them.
var
  lw: LongWord;
begin
  Src.Seek(Loc, soFromBeginning);
  Src.Read(lw, 4);

  if Dst = nil then
    Dst := TMemoryStream.Create //just in case
  else
    Dst.Clear;
  Dst.Seek(0, soFromBeginning);
  Dst.CopyFrom(Src, lw);
end;

procedure TBaseNeoGraphicSet.DoReadData;
var
  i, i2: Integer;
  TempBMP: TBitmap32;
  TempBmps: TBitmaps;
  mw, mh: Integer;
begin

  if GraphicSetFile = '' then
  begin
    inherited;
    exit;
  end;

  GetSections;

  //Terrain
  for i := 0 to MetaTerrains.Count-1 do
  begin
    TempBMP := DecodeGraphic(fGraphicsStream, MetaTerrains[i].ImageLocation);
    TerrainBitmaps.Add(TempBMP);
    MetaTerrains[i].Width := TempBMP.Width;
    MetaTerrains[i].Height := TempBMP.Height;
  end;

  //Objects
  for i := 0 to MetaObjects.Count-1 do
  begin
    TempBmps := TBitmaps.Create;
    mw := 0;
    mh := 0;
    for i2 := 0 to MetaObjects[i].AnimationFrameCount-1 do
    begin
      if i2 = 0 then
        TempBMP := DecodeGraphic(fGraphicsStream, MetaObjects[i].AnimationFramesBaseLoc)
      else
        TempBMP := DecodeGraphic(fGraphicsStream);
      if TempBMP.Width > mw then mw := TempBMP.Width;
      if TempBMP.Height > mh then mh := TempBMP.Height;
      TempBmps.Add(TempBMP);
    end;
    MetaObjects[i].Width := mw;
    MetaObjects[i].Height := mh;
    TempBMP := TBitmap32.Create;
    TempBMP.SetSize(mw, mh*MetaObjects[i].AnimationFrameCount);
    for i2 := 0 to TempBmps.Count-1 do
      TempBmps[i2].DrawTo(TempBMP, 0, mh*i2);
    TempBmps.Free;
    ObjectBitmaps.Add(TempBmp);
  end;

  //Vgaspec - directly copied from LemDosGraphicSet
  LoadVgaspec;

end;

procedure TBaseNeoGraphicSet.LoadVgaspec;
var
  SpecBmp: TVgaSpecBitmap;
  DataStream: TMemoryStream;
begin
  if GraphicSetIdExt <> 0 then
      begin
        SpecBmp := TVgaSpecBitmap.Create;
        try

          if FileExists(GraphicExtFile) and (ParamStr(1) = 'testmode') then
          begin
            DataStream := TMemoryStream.Create;
            DataStream.LoadFromFile(GraphicExtFile);
          end else begin
            DataStream := CreateDataStream(GraphicExtFile, ldtStyle, true); // Allow external
            if (DataStream = nil) and (fOnlineEnabled) then
            begin
              ObtainGraphicSet(GraphicExtFile);
              DataStream := CreateDataStream(GraphicExtFile, ldtStyle, true); // Allow external for sure here
            end;
          end;

          try
            SpecBmp.LoadFromStream(DataStream, SpecialBitmaps);
          finally
            DataStream.Free;
          end;
        finally
          SpecBmp.Free;
        end;
      end;
end;



function TBaseNeoGraphicSet.LoadHeader(aStream: TStream): NeoLemmixHeader;
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

function TBaseNeoGraphicSet.GetNextSection(srcStream: TStream; dstStream: TStream): Byte;
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

function TBaseNeoGraphicSet.DecodeGraphic(aStream: TStream; Loc: LongWord): TBitmap32;
begin
  aStream.Seek(Loc, soFromBeginning);
  Result := DecodeGraphic(aStream);
end;

function TBaseNeoGraphicSet.DecodeGraphic(aStream: TStream): TBitmap32;
var
  x, y, W, H: LongWord;
  a, r, g, b: Byte;
  TempBMP: TBitmap32;
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

  if Resolution = 8 then Exit;

  TempBMP := TBitmap32.Create;
  TempBMP.SetSize((W * 8) div Resolution, (H * 8) div Resolution);
  TempBMP.Clear(0);
  Result.DrawTo(TempBMP, TempBMP.BoundsRect);
  Result.Free;
  Result := TempBMP;
end;

///////////////////////////
// TNeoLemmixGraphicSets //
///////////////////////////

function TNeoLemmixGraphicSets.Add(Item: TBaseNeoGraphicSet): Integer;
begin
  // Adds an existing TBaseNeoGraphicSet to the list.
  Result := inherited Add(Item);
end;

function TNeoLemmixGraphicSets.Add: TBaseNeoGraphicSet;
begin
  // Creates a new TBaseNeoGraphicSet, adds it, and returns it.
  Result := TBaseNeoGraphicSet.Create;
  inherited Add(Result);
end;

function TNeoLemmixGraphicSets.GetItem(Index: Integer): TBaseNeoGraphicSet;
begin
  // Gets a TBaseNeoGraphicSet from the list.
  Result := inherited Get(Index);
end;

end.
