unit LemNeoPieceManager;

// The TNeoPieceManager class is used in a similar manner to how
// graphic sets were in the past. It could be thought of as a huge
// dynamic graphic set.

interface

uses
  Dialogs,
  LemNeoParser, PngInterface,
  LemMetaTerrain, LemMetaObject, LemTypes, GR32, LemStrings,
  Classes, SysUtils;

type

  TLabelRecord = record
    GS: String;
    Piece: String;
  end;

  TTerrainRecord = record
    Meta: TMetaTerrain;
    Image: TBitmap32;
  end;

  TObjectRecord = record
    Meta: TMetaObject;
    Image: TBitmaps;
  end;

  TNeoPieceManager = class
    private
      fTerrains: TMetaTerrains;
      fObjects: TMetaObjects;
      fTerrainImages: TBitmaps;
      fObjectImages: TBitmapses;

      function GetTerrainCount: Integer;
      function GetObjectCount: Integer;

      function FindTerrainIndexByIdentifier(Identifier: String): Integer;
      function FindObjectIndexByIdentifier(Identifier: String): Integer;
      function ObtainTerrain(Identifier: String): Integer;
      function ObtainObject(Identifier: String): Integer;

      function GetTerrain(Identifier: String): TTerrainRecord;
      function GetObject(Identifier: String): TObjectRecord;
      function GetMetaTerrain(Identifier: String): TMetaTerrain;
      function GetMetaObject(Identifier: String): TMetaObject;
      function GetTerrainBitmap(Identifier: String): TBitmap32;
      function GetObjectBitmaps(Identifier: String): TBitmaps;

      property TerrainCount: Integer read GetTerrainCount;
      property ObjectCount: Integer read GetObjectCount;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Tidy;

      property Terrains[Identifier: String]: TTerrainRecord read GetTerrain;
      property Objects[Identifier: String]: TObjectRecord read GetObject;
      property MetaTerrains[Identifier: String]: TMetaTerrain read GetMetaTerrain;
      property MetaObjects[Identifier: String]: TMetaObject read GetMetaObject;
      property TerrainBitmaps[Identifier: String]: TBitmap32 read GetTerrainBitmap;
      property ObjectBitmaps[Identifier: String]: TBitmaps read GetObjectBitmaps;
  end;

  function SplitIdentifier(Identifier: String): TLabelRecord;
  function CombineIdentifier(Identifier: TLabelRecord): String;

implementation

// These two standalone functions are just to help shifting labels around

function SplitIdentifier(Identifier: String): TLabelRecord;
var
  i: Integer;
  FoundDivider: Boolean;
begin
  Result.GS := '';
  Result.Piece := '';
  FoundDivider := false;
  for i := 1 to Length(Identifier) do
    if Identifier[i] = ':' then
      FoundDivider := true
    else if FoundDivider then
      Result.Piece := Result.Piece + Identifier[i]
    else
      Result.GS := Result.GS + Identifier[i];
end;

function CombineIdentifier(Identifier: TLabelRecord): String;
begin
  // This one is much simpler.
  Result := Identifier.GS + ':' + Identifier.Piece;
end;

// Constructor, destructor, usual boring stuff

constructor TNeoPieceManager.Create;
begin
  inherited;
  fTerrains := TMetaTerrains.Create;
  fObjects := TMetaObjects.Create;
  fTerrainImages := TBitmaps.Create(true);
  fObjectImages := TBitmapses.Create(true);
end;

destructor TNeoPieceManager.Destroy;
begin
  fTerrains.Free;
  fObjects.Free;
  fTerrainImages.Free;
  fObjectImages.Free;
  inherited;
end;

// Tidy-up function. Pretty much clears out the lists. Might add
// stuff in the future so it retains frequently-used pieces.
procedure TNeoPieceManager.Tidy;
begin
  fTerrains.Clear;
  fObjects.Clear;
  fTerrainImages.Clear;
  fObjectImages.Clear;
end;

// Quick shortcuts to get number of pieces currently present

function TNeoPieceManager.GetTerrainCount: Integer;
begin
  Result := fTerrains.Count;
end;

function TNeoPieceManager.GetObjectCount: Integer;
begin
  Result := fObjects.Count;
end;

// Some functions to locate a piece in the internal arrays...

function TNeoPieceManager.FindTerrainIndexByIdentifier(Identifier: String): Integer;
begin
  Identifier := Lowercase(Identifier);
  for Result := 0 to TerrainCount-1 do
    if fTerrains[Result].Identifier = Identifier then Exit;

  // if it's not found
  Result := ObtainTerrain(Identifier);
end;

function TNeoPieceManager.FindObjectIndexByIdentifier(Identifier: String): Integer;
begin
  Identifier := Lowercase(Identifier);
  for Result := 0 to ObjectCount-1 do
    if fObjects[Result].Identifier = Identifier then Exit;

  // if it's not found
  Result := ObtainObject(Identifier);
end;

// ... and to load it if not found.

function TNeoPieceManager.ObtainTerrain(Identifier: String): Integer;
var
  TerrainLabel: TLabelRecord;
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  T: TMetaTerrain;
  BMP: TBitmap32;
begin
  TerrainLabel := SplitIdentifier(Identifier);
  if not DirectoryExists(AppPath + SFStyles + SFStylesPieces + TerrainLabel.GS) then
    raise Exception.Create('TNeoPieceManager.ObtainTerrain: ' + TerrainLabel.GS + ' does not exist.');
  SetCurrentDir(AppPath + SFStyles + SFStylesPieces + TerrainLabel.GS + '\');

  Result := fTerrains.Count;

  T := fTerrains.Add;
  BMP := TBitmap32.Create;

  T.GS := TerrainLabel.GS;
  T.Piece := TerrainLabel.Piece;

  // If the metainfo file exists, load and process it.
  if FileExists(TerrainLabel.Piece + '.nxtp') then
  begin
    Parser := TNeoLemmixParser.Create;
    try
      Parser.LoadFromFile(TerrainLabel.Piece + '.nxtp');
      repeat
        Line := Parser.NextLine;
        if Line.Keyword = 'STEEL' then
          T.Unknown := 1;
      until Line.Keyword = '';
    finally
      Parser.Free;
    end;
  end;

  // Either way, load the terrain's image
  TPngInterface.LoadPngFile(TerrainLabel.Piece + '.png', BMP);

  fTerrainImages.Add(BMP);
end;

function TNeoPieceManager.ObtainObject(Identifier: String): Integer;
var
  ObjectLabel: TLabelRecord;
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  O: TMetaObject;
  BMP: TBitmap32;
  BMPs: TBitmaps;

  procedure ShiftRect(var aRect: TRect; dX, dY: Integer);
  begin
    aRect.Left := aRect.Left + dX;
    aRect.Right := aRect.Right + dX;
    aRect.Top := aRect.Top + dY;
    aRect.Bottom := aRect.Bottom + dY;
  end;

  procedure MakeStripFromHorizontal(aFrames: Integer);
  var
    TempBmp: TBitmap32;
    SrcRect, DstRect: TRect;
    i: Integer;
  begin
    TempBmp := TBitmap32.Create;
    TempBmp.Assign(BMP);
    BMP.SetSize(BMP.Width div aFrames, BMP.Height * aFrames);
    BMP.Clear($00000000);
    SrcRect := Rect(0, 0, BMP.Width, TempBmp.Height);
    DstRect := SrcRect;

    for i := 0 to aFrames do
    begin
      TempBmp.DrawTo(BMP, DstRect, SrcRect);
      ShiftRect(SrcRect, BMP.Width, 0);
      ShiftRect(DstRect, 0, TempBmp.Height);
    end;
  end;

begin
  ObjectLabel := SplitIdentifier(Identifier);
  if not DirectoryExists(AppPath + SFStyles + SFStylesPieces + ObjectLabel.GS) then
    raise Exception.Create('TNeoPieceManager.ObtainTerrain: ' + ObjectLabel.GS + ' does not exist.');
  SetCurrentDir(AppPath + SFStyles + SFStylesPieces + ObjectLabel.GS + '\');

  Result := fObjects.Count;

  O := fObjects.Add;
  BMP := TBitmap32.Create;

  TPngInterface.LoadPngFile(ObjectLabel.Piece + '.png', BMP);

  O.GS := ObjectLabel.GS;
  O.Piece := ObjectLabel.Piece;

  // We always need the parser for an object.
  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromFile(ObjectLabel.Piece + '.nxob');
    repeat
      Line := Parser.NextLine;

      // Trigger effects
      if Line.Keyword = 'EXIT' then O.TriggerEffect := 1;
      if Line.Keyword = 'OWL_FIELD' then O.TriggerEffect := 2;
      if Line.Keyword = 'OWR_FIELD' then O.TriggerEffect := 3;
      if Line.Keyword = 'TRAP' then O.TriggerEffect := 4;
      if Line.Keyword = 'WATER' then O.TriggerEffect := 5;
      if Line.Keyword = 'FIRE' then O.TriggerEffect := 6;
      if Line.Keyword = 'OWL_ARROW' then O.TriggerEffect := 7;
      if Line.Keyword = 'OWR_ARROW' then O.TriggerEffect := 8;
      if Line.Keyword = 'TELEPORTER' then O.TriggerEffect := 11;
      if Line.Keyword = 'RECEIVER' then O.TriggerEffect := 12;
      if Line.Keyword = 'LEMMING' then O.TriggerEffect := 13;
      if Line.Keyword = 'PICKUP' then O.TriggerEffect := 14;
      if Line.Keyword = 'LOCKED_EXIT' then O.TriggerEffect := 15;
      if Line.Keyword = 'BUTTON' then O.TriggerEffect := 17;
      if Line.Keyword = 'RADIATION' then O.TriggerEffect := 18;
      if Line.Keyword = 'OWD_ARROW' then O.TriggerEffect := 19;
      if Line.Keyword = 'UPDRAFT' then O.TriggerEffect := 20;
      if Line.Keyword = 'SPLITTER' then O.TriggerEffect := 21;
      if Line.Keyword = 'SLOWFREEZE' then O.TriggerEffect := 22;
      if Line.Keyword = 'WINDOW' then O.TriggerEffect := 23;
      if Line.Keyword = 'ANIMATION' then O.TriggerEffect := 24;
      if Line.Keyword = 'HINT' then O.TriggerEffect := 25;
      if Line.Keyword = 'ANTISPLAT' then O.TriggerEffect := 26;
      if Line.Keyword = 'SPLAT' then O.TriggerEffect := 27;
      if Line.Keyword = 'BACKGROUND' then O.TriggerEffect := 30;
      if Line.Keyword = 'TRAP_ONCE' then O.TriggerEffect := 31;

      if Line.Keyword = 'FRAMES' then
        O.AnimationFrameCount := Line.Numeric;

      if Line.Keyword = 'HORIZONTAL' then
        MakeStripFromHorizontal(O.AnimationFrameCount);

      if Line.Keyword = 'TRIGGER_X' then
        O.TriggerLeft := Line.Numeric;

      if Line.Keyword = 'TRIGGER_Y' then
        O.TriggerTop := Line.Numeric;

      if Line.Keyword = 'TRIGGER_W' then
        O.TriggerWidth := Line.Numeric;

      if Line.Keyword = 'TRIGGER_H' then
        O.TriggerHeight := Line.Numeric;

      if Line.Keyword = 'SOUND' then
        O.SoundEffect := Line.Numeric;

      if Line.Keyword = 'PREVIEW' then
        O.PreviewFrameIndex := Line.Numeric;

      if Line.Keyword = 'KEYFRAME' then
        O.TriggerNext := Line.Numeric;

      if Line.Keyword = 'RANDOM_FRAME' then
        O.RandomStartFrame := true;

    until Line.Keyword = '';
  finally
    Parser.Free;
  end;

  O.Width := BMP.Width;
  O.Height := BMP.Height div O.AnimationFrameCount;

  with fObjectImages.Add do
    Generate(BMP, O.AnimationFrameCount);

  BMP.Free;
end;

// Functions to get piece records (which contain pointers to both the metainfo and the images)

function TNeoPieceManager.GetTerrain(Identifier: String): TTerrainRecord;
var
  i: Integer;
begin
  i := FindTerrainIndexByIdentifier(Identifier);
  Result.Meta := fTerrains[i];
  Result.Image := fTerrainImages[i];
end;

function TNeoPieceManager.GetObject(Identifier: String): TObjectRecord;
var
  i: Integer;
begin
  i := FindObjectIndexByIdentifier(Identifier);
  Result.Meta := fObjects[i];
  Result.Image := fObjectImages[i];
end;

// And some for those cases where we only want one or the other

function TNeoPieceManager.GetMetaTerrain(Identifier: String): TMetaTerrain;
begin
  Result := GetTerrain(Identifier).Meta;
end;

function TNeoPieceManager.GetMetaObject(Identifier: String): TMetaObject;
begin
  Result := GetObject(Identifier).Meta;
end;

function TNeoPieceManager.GetTerrainBitmap(Identifier: String): TBitmap32;
begin
  Result := GetTerrain(Identifier).Image;
end;

function TNeoPieceManager.GetObjectBitmaps(Identifier: String): TBitmaps;
begin
  Result := GetObject(Identifier).Image;
end;

end.