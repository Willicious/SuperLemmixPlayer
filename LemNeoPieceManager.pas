unit LemNeoPieceManager;

// The TNeoPieceManager class is used in a similar manner to how
// graphic sets were in the past. It could be thought of as a huge
// dynamic graphic set.

interface

uses
  Dialogs,
  PngInterface, LemNeoTheme,
  LemMetaTerrain, LemGadgetsMeta, LemTypes, GR32, LemStrings,
  StrUtils, Classes, SysUtils;

const
  RETAIN_PIECE_CYCLES = 10; // how many times Tidy can be called without a piece being used before it's discarded

type

  TLabelRecord = record
    GS: String;
    Piece: String;
  end;

  TNeoPieceManager = class
    private
      fTheme: TNeoTheme;
      fTerrains: TMetaTerrains;
      fObjects: TGadgetMetaInfoList;

      fDisableTidy: Boolean;

      function GetTerrainCount: Integer;
      function GetObjectCount: Integer;

      function FindTerrainIndexByIdentifier(Identifier: String): Integer;
      function FindObjectIndexByIdentifier(Identifier: String): Integer;
      function ObtainTerrain(Identifier: String): Integer;
      function ObtainObject(Identifier: String): Integer;

      function GetMetaTerrain(Identifier: String): TMetaTerrain;
      function GetMetaObject(Identifier: String): TGadgetMetaInfo;

      property TerrainCount: Integer read GetTerrainCount;
      property ObjectCount: Integer read GetObjectCount;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Tidy;

      procedure SetTheme(aTheme: TNeoTheme);

      property Terrains[Identifier: String]: TMetaTerrain read GetMetaTerrain;
      property Objects[Identifier: String]: TGadgetMetaInfo read GetMetaObject;

      property DisableTidy: Boolean read fDisableTidy write fDisableTidy;
  end;

  function SplitIdentifier(Identifier: String): TLabelRecord;
  function CombineIdentifier(Identifier: TLabelRecord): String;

var
  PieceManager: TNeoPieceManager; // globalized as this does not need to have seperate instances

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
  fObjects := TGadgetMetaInfoList.Create;
  fTheme := nil;
end;

destructor TNeoPieceManager.Destroy;
begin
  fTerrains.Free;
  fObjects.Free;
  inherited;
end;

// Tidy-up function. Pretty much clears out the lists. Might add
// stuff in the future so it retains frequently-used pieces.
procedure TNeoPieceManager.Tidy;
var
  i: Integer;
begin
  if fDisableTidy then Exit; // speeds up replay testing by not discarding and having to reload tiles

  for i := fTerrains.Count-1 downto 0 do
  begin
    fTerrains[i].CyclesSinceLastUse := fTerrains[i].CyclesSinceLastUse + 1;
    if fTerrains[i].CyclesSinceLastUse >= RETAIN_PIECE_CYCLES then
      fTerrains.Delete(i);
  end;
  for i := fObjects.Count-1 downto 0 do
  begin
    fObjects[i].CyclesSinceLastUse := fObjects[i].CyclesSinceLastUse + 1;
    if (fObjects[i].CyclesSinceLastUse >= RETAIN_PIECE_CYCLES) or (fObjects[i].IsMasked) then
      fObjects.Delete(i);
  end;
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

  BasePath := AppPath + SFStyles + TerrainLabel.GS + SFPiecesTerrain + TerrainLabel.Piece;

  if FileExists(BasePath + '.png') then  // .nxtp is optional, but .png is not :)
    T := TMetaTerrain.Create
  else
    raise EAbort.Create('Error loading the level: Could not find terrain piece: ' + Identifier);
  fTerrains.Add(T);
  T.Load(TerrainLabel.GS, TerrainLabel.Piece);
end;

function TNeoPieceManager.ObtainObject(Identifier: String): Integer;
var
  ObjectLabel: TLabelRecord;
  MO: TGadgetMetaInfo;
begin
  try
    ObjectLabel := SplitIdentifier(Identifier);
    Result := fObjects.Count;
    MO := TGadgetMetaInfo.Create;
    MO.Load(ObjectLabel.GS, ObjectLabel.Piece, fTheme);
    fObjects.Add(MO);
  except
    raise EAbort.Create('Error loading the level: Could not find object piece: ' + Identifier);
  end;
end;

// Functions to get the metainfo

function TNeoPieceManager.GetMetaTerrain(Identifier: String): TMetaTerrain;
var
  i: Integer;
begin
  i := FindTerrainIndexByIdentifier(Identifier);
  Result := fTerrains[i];
  Result.CyclesSinceLastUse := 0;
end;

function TNeoPieceManager.GetMetaObject(Identifier: String): TGadgetMetaInfo;
var
  i: Integer;
begin
  i := FindObjectIndexByIdentifier(Identifier);
  Result := fObjects[i];
  Result.CyclesSinceLastUse := 0;
end;

// And the stuff for communicating with the theme

procedure TNeoPieceManager.SetTheme(aTheme: TNeoTheme);
begin
  fTheme := aTheme;
  Tidy;
end;

end.