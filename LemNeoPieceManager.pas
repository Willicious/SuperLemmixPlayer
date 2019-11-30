unit LemNeoPieceManager;

// The TNeoPieceManager class is used in a similar manner to how
// graphic sets were in the past. It could be thought of as a huge
// dynamic graphic set.

interface

uses
  Dialogs,
  PngInterface, LemNeoTheme, LemAnimationSet,
  LemMetaTerrain, LemTerrainGroup, LemGadgetsMeta, LemGadgetsConstants, LemTypes, GR32, LemStrings,
  Generics.Collections,
  StrUtils, Classes, SysUtils,
  LemNeoParser;

const
  RETAIN_PIECE_CYCLES = 20; // how many times Tidy can be called without a piece being used before it's discarded
  COMPOSITE_PIECE_STYLE = '*GROUP'; // what to use for the style name in per-level composite pieces

type

  TLabelRecord = record
    GS: String;
    Piece: String;
  end;

  TAliasKind = (rkStyle, rkGadget, rkTerrain, rkBackground);

  TStyleAlias = record
    Source: TLabelRecord;
    Dest: TLabelRecord;
    Kind: TAliasKind;
  end;

  TNeoPieceManager = class
    private
      fTheme: TNeoTheme;
      fTerrains: TMetaTerrains;
      fObjects: TGadgetMetaInfoList;

      fLoadedPropertiesStyles: TStringList;
      fAliases: TList<TStyleAlias>;

      fAddAliasStyle: String; // Temporary usage only.

      function GetTerrainCount: Integer;
      function GetObjectCount: Integer;

      function FindTerrainIndexByIdentifier(Identifier: String): Integer;
      function FindObjectIndexByIdentifier(Identifier: String): Integer;
      function ObtainTerrain(Identifier: String): Integer;
      function ObtainObject(Identifier: String): Integer;

      function GetMetaTerrain(Identifier: String): TMetaTerrain;
      function GetMetaObject(Identifier: String): TGadgetMetaInfo;

      procedure LoadAliases(aStyle: String);
      procedure AddAlias(aSection: TParserSection; const aIteration: Integer; aData: Pointer);

      property TerrainCount: Integer read GetTerrainCount;
      property ObjectCount: Integer read GetObjectCount;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Tidy;
      procedure RemoveCompositePieces;

      procedure SetTheme(aTheme: TNeoTheme);
      procedure RegenerateAutoAnims(aTheme: TNeoTheme; aAni: TBaseAnimationSet);
      procedure MakePiecesFromGroups(aGroups: TTerrainGroups);
      procedure MakePieceFromGroup(aGroup: TTerrainGroup);

      procedure LoadProperties(aStyle: String);
      function Dealias(aIdentifier: String; aKind: TAliasKind): String;

      property Terrains[Identifier: String]: TMetaTerrain read GetMetaTerrain;
      property Objects[Identifier: String]: TGadgetMetaInfo read GetMetaObject;
  end;

  function SplitIdentifier(Identifier: String): TLabelRecord;
  function CombineIdentifier(Identifier: TLabelRecord): String;

var
  PieceManager: TNeoPieceManager; // globalized as this does not need to have seperate instances

implementation

uses
  GameControl, LemTerrain;

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
  fLoadedPropertiesStyles := TStringList.Create;
  fAliases := TList<TStyleAlias>.Create;

  LoadProperties('default');
end;

destructor TNeoPieceManager.Destroy;
begin
  fTerrains.Free;
  fObjects.Free;
  fAliases.Free;
  fLoadedPropertiesStyles.Free;
  inherited;
end;

// Tidy-up function. Pretty much clears out the lists. Might add
// stuff in the future so it retains frequently-used pieces.
procedure TNeoPieceManager.Tidy;
var
  i: Integer;
begin
  for i := fTerrains.Count-1 downto 0 do
  begin
    fTerrains[i].CyclesSinceLastUse := fTerrains[i].CyclesSinceLastUse + 1;
    if fTerrains[i].CyclesSinceLastUse >= RETAIN_PIECE_CYCLES then
      fTerrains.Delete(i);
  end;
  for i := fObjects.Count-1 downto 0 do
  begin
    fObjects[i].CyclesSinceLastUse := fObjects[i].CyclesSinceLastUse + 1;
    if (fObjects[i].CyclesSinceLastUse >= RETAIN_PIECE_CYCLES) then
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
  else begin
    Result := -1;
    Exit;
  end;
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
    Result := -1;
  end;
end;

// Functions to get the metainfo

function TNeoPieceManager.GetMetaTerrain(Identifier: String): TMetaTerrain;
var
  i: Integer;
begin
  i := FindTerrainIndexByIdentifier(Identifier);
  if i >= 0 then
  begin
    Result := fTerrains[i];
    Result.CyclesSinceLastUse := 0;
  end else
    Result := nil;
end;

function TNeoPieceManager.GetMetaObject(Identifier: String): TGadgetMetaInfo;
var
  i: Integer;
begin
  i := FindObjectIndexByIdentifier(Identifier);
  if i >= 0 then
  begin
    Result := fObjects[i];
    Result.CyclesSinceLastUse := 0;
  end else
    Result := nil;
end;

// And the stuff for communicating with the theme

procedure TNeoPieceManager.SetTheme(aTheme: TNeoTheme);
var
  i: Integer;
begin
  fTheme := aTheme;
  Tidy;

  for i := 0 to fObjects.Count-1 do
    if fObjects[i].Animations[false, false, false].AnyMasked then
      fObjects[i].Remask(aTheme);
end;

procedure TNeoPieceManager.RegenerateAutoAnims(aTheme: TNeoTheme;
  aAni: TBaseAnimationSet);
var
  i: Integer;
begin
  for i := 0 to fObjects.Count-1 do
    fObjects[i].RegenerateAutoAnims(aTheme, aAni);
end;

//  Functions for composite pieces

procedure TNeoPieceManager.MakePieceFromGroup(aGroup: TTerrainGroup);
var
  BMP: TBitmap32;
  T: TMetaTerrain;

  function IsGroupSteel: Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to aGroup.Terrains.Count-1 do
      if (aGroup.Terrains[i].DrawingFlags and tdf_Erase) = 0 then
      begin
        Result := Terrains[aGroup.Terrains[i].Identifier].IsSteel;
        Exit;
      end;
  end;
begin
  BMP := TBitmap32.Create;
  try
    GameParams.Renderer.PrepareCompositePieceBitmap(aGroup.Terrains, BMP);
    T := fTerrains.Add;
    T.LoadFromImage(BMP, COMPOSITE_PIECE_STYLE, aGroup.Name, IsGroupSteel);
  finally
    BMP.Free;
  end;
end;

procedure TNeoPieceManager.MakePiecesFromGroups(aGroups: TTerrainGroups);
var
  i: Integer;
begin
  for i := 0 to aGroups.Count-1 do
    MakePieceFromGroup(aGroups[i]);
end;

procedure TNeoPieceManager.RemoveCompositePieces;
var
  i: Integer;
begin
  for i := fTerrains.Count-1 downto 0 do
    if fTerrains[i].GS = COMPOSITE_PIECE_STYLE then
      fTerrains.Delete(i);
end;

// Aliases

procedure TNeoPieceManager.LoadAliases(aStyle: String);
var
  Parser: TParser;
begin
  if not FileExists(AppPath + SFStyles + aStyle + '\alias.nxmi') then Exit;

  fAddAliasStyle := aStyle;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFStyles + aStyle + '\alias.nxmi');

    Parser.MainSection.DoForEachSection('GADGET', AddAlias, Pointer(rkGadget));
    Parser.MainSection.DoForEachSection('TERRAIN', AddAlias, Pointer(rkTerrain));
    Parser.MainSection.DoForEachSection('BACKGROUND', AddAlias, Pointer(rkBackground));
    Parser.MainSection.DoForEachSection('STYLE', AddAlias, Pointer(rkStyle));
  finally
    Parser.Free;
  end;
end;

procedure TNeoPieceManager.LoadProperties(aStyle: String);
begin
  if fLoadedPropertiesStyles.IndexOf(aStyle) >= 0 then Exit;
  fLoadedPropertiesStyles.Add(aStyle);

  LoadAliases(aStyle);
end;

procedure TNeoPieceManager.AddAlias(aSection: TParserSection;
  const aIteration: Integer; aData: Pointer);
var
  Kind: TAliasKind absolute aData;
  NewRec: TStyleAlias;
begin
  NewRec.Source := SplitIdentifier(aSection.LineString['FROM']);
  NewRec.Dest := SplitIdentifier(aSection.LineString['TO']);
  NewRec.Kind := Kind;

  if NewRec.Source.GS = '' then NewRec.Source.GS := fAddAliasStyle;
  if NewRec.Dest.GS = '' then NewRec.Dest.GS := fAddAliasStyle;

  fAliases.Add(NewRec);
end;

function TNeoPieceManager.Dealias(aIdentifier: String; aKind: TAliasKind): String;
var
  Ident: TLabelRecord;
  i: Integer;
begin
  Ident := SplitIdentifier(aIdentifier);

  LoadProperties(Ident.GS);

  for i := 0 to fAliases.Count-1 do
  begin
    if Ident.GS <> fAliases[i].Source.GS then Continue;

    if fAliases[i].Kind = rkStyle then
      Ident.GS := fAliases[i].Dest.GS
    else if (fAliases[i].Kind = aKind) and (Ident.Piece = fAliases[i].Source.Piece) then
      Ident := fAliases[i].Dest;
  end;

  if aKind = rkStyle then
    Result := Ident.GS
  else
    Result := CombineIdentifier(Ident);
end;

end.