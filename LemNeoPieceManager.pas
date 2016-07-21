unit LemNeoPieceManager;

// The TNeoPieceManager class is used in a similar manner to how
// graphic sets were in the past. It could be thought of as a huge
// dynamic graphic set.

interface

uses
  Dialogs,
  LemNeoParser, PngInterface, LemNeoTheme,
  LemMetaTerrain, LemMetaObject, LemTypes, GR32, LemStrings,
  StrUtils, Classes, SysUtils;

type

  TLabelRecord = record
    GS: String;
    Piece: String;
  end;

  TNeoPieceManager = class
    private
      fTheme: TNeoTheme;
      fTerrains: TMetaTerrains;
      fObjects: TMetaObjects;
      //fTerrainImages: TBitmaps;
      fObjectImages: TBitmapses;

      function GetTerrainCount: Integer;
      function GetObjectCount: Integer;

      function FindTerrainIndexByIdentifier(Identifier: String): Integer;
      function FindObjectIndexByIdentifier(Identifier: String): Integer;
      function ObtainTerrain(Identifier: String): Integer;
      function ObtainObject(Identifier: String): Integer;

      //function GetTerrain(Identifier: String): TMetaTerrain;
      //function GetObject(Identifier: String): TMetaObject;
      function GetMetaTerrain(Identifier: String): TMetaTerrain;
      function GetMetaObject(Identifier: String): TMetaObject;
      //function GetTerrainBitmap(Identifier: String): TBitmap32;
      //function GetObjectBitmaps(Identifier: String): TBitmaps;
      function GetThemeColor(Index: String): TColor32;

      property TerrainCount: Integer read GetTerrainCount;
      property ObjectCount: Integer read GetObjectCount;

      property ThemeColor[Index: String]: TColor32 read GetThemeColor;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Tidy;

      procedure SetTheme(aTheme: TNeoTheme);

      property Terrains[Identifier: String]: TMetaTerrain read GetMetaTerrain;
      property Objects[Identifier: String]: TMetaObject read GetMetaObject;
  end;

  function SplitIdentifier(Identifier: String): TLabelRecord;
  function CombineIdentifier(Identifier: TLabelRecord): String;

implementation

uses
  LemMetaConstruct;

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
  //fTerrainImages := TBitmaps.Create(true);
  fObjectImages := TBitmapses.Create(true);
  fTheme := nil;
end;

destructor TNeoPieceManager.Destroy;
begin
  fTerrains.Free;
  fObjects.Free;
  //fTerrainImages.Free;
  fObjectImages.Free;
  inherited;
end;

// Tidy-up function. Pretty much clears out the lists. Might add
// stuff in the future so it retains frequently-used pieces.
procedure TNeoPieceManager.Tidy;
begin
  fTerrains.Clear;
  fObjects.Clear;
  //fTerrainImages.Clear;
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
  BasePath: String;
  TerrainLabel: TLabelRecord;
  T: TMetaTerrain;
begin
  TerrainLabel := SplitIdentifier(Identifier);

  Result := fTerrains.Count;

  BasePath := AppPath + SFStylesPieces + TerrainLabel.GS + SFPiecesTerrain + TerrainLabel.Piece;

  if FileExists(BasePath + '.png') then  // .nxtp is optional, but .png is not :)
    T := TMetaTerrain.Create
  else if FileExists(BasePath + '.nxcs') then
    T := TMetaConstruct.Create;
  fTerrains.Add(T);
  T.Load(TerrainLabel.GS, TerrainLabel.Piece);
end;

function TNeoPieceManager.ObtainObject(Identifier: String): Integer;
var
  ObjectLabel: TLabelRecord;
  MO: TMetaObject;
begin
  ObjectLabel := SplitIdentifier(Identifier);
  Result := fObjects.Count;
  MO := fObjects.Add;
  MO.Load(ObjectLabel.GS, ObjectLabel.Piece, fTheme);
end;

// Functions to get the metainfo

function TNeoPieceManager.GetMetaTerrain(Identifier: String): TMetaTerrain;
var
  i: Integer;
begin
  i := FindTerrainIndexByIdentifier(Identifier);
  Result := fTerrains[i];
end;

function TNeoPieceManager.GetMetaObject(Identifier: String): TMetaObject;
var
  i: Integer;
begin
  i := FindObjectIndexByIdentifier(Identifier);
  Result := fObjects[i];
end;

// And the stuff for communicating with the theme

procedure TNeoPieceManager.SetTheme(aTheme: TNeoTheme);
begin
  fTheme := aTheme;
  Tidy;
end;

function TNeoPieceManager.GetThemeColor(Index: String): TColor32;
begin
  if fTheme = nil then
  begin
    Result := DEFAULT_COLOR;
    if Uppercase(Index) = 'BACKGROUND' then
      Result := $FF000000;
  end else
    Result := fTheme.Colors[Index];
end;

end.