unit LemNeoPieceManager;

{ The TNeoPieceManager class is used in a similar manner to how graphic sets were in the past.
  It could be thought of as a huge dynamic graphic set. }

interface

uses
  Dialogs,
  PngInterface, LemNeoTheme, LemAnimationSet,
  LemMetaTerrain, LemTerrainGroup, LemGadgetsMeta, LemGadgetsConstants, LemTypes, GR32, LemStrings,
  Generics.Collections,
  StrUtils, Classes, SysUtils,
  LemNeoParser;

const
  RETAIN_PIECE_CYCLES = 20; // How many times Tidy can be called without a piece being used before it's discarded
  COMPOSITE_PIECE_STYLE = '*GROUP'; // What to use for the style name in per-level composite pieces

type

  TLabelRecord = record
    GS: String;
    Piece: String;
  end;

  TAliasKind = (rkStyle, rkGadget, rkTerrain, rkBackground, rkLemmings);

  TStyleAlias = record
    Source: TLabelRecord;
    Dest: TLabelRecord;
    DefWidth: Integer;
    DefHeight: Integer;
    Kind: TAliasKind;
  end;

  TDealiasResult = record
    Piece: TLabelRecord;
    DefWidth: Integer;
    DefHeight: Integer;
  end;

  TUpscaleInfo = record
    Source: TLabelRecord;
    Kind: TAliasKind;
    Settings: TUpscaleSettings;
  end;

  TNeoPieceManager = class
    private
      fTheme: TNeoTheme;
      fTerrains: TMetaTerrains;
      fObjects: TGadgetMetaInfoList;

      fNeedCheckStyles: TStringList;
      fLoadedPropertiesStyles: TStringList;
      fAliases: TList<TStyleAlias>;
      fUpscaling: TList<TUpscaleInfo>;

      fLoadPropertiesStyle: String; // Temporary usage only.

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

      procedure LoadUpscaling(aStyle: String);
      procedure AddUpscaling(aSection: TParserSection; const aIteration: Integer; aData: Pointer);

      property TerrainCount: Integer read GetTerrainCount;
      property ObjectCount: Integer read GetObjectCount;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Tidy;
      procedure RemoveCompositePieces;
      procedure Clear;

      procedure SetTheme(aTheme: TNeoTheme);
      procedure RegenerateAutoAnims(aTheme: TNeoTheme; aAni: TBaseAnimationSet);
      procedure MakePiecesFromGroups(aGroups: TTerrainGroups);
      procedure MakePieceFromGroup(aGroup: TTerrainGroup);

      procedure LoadProperties(aStyle: String);
      function Dealias(aIdentifier: String; aKind: TAliasKind): TDealiasResult;
      function GetUpscaleInfo(aIdentifier: String; aKind: TAliasKind): TUpscaleInfo;

      property Terrains[Identifier: String]: TMetaTerrain read GetMetaTerrain;
      property Objects[Identifier: String]: TGadgetMetaInfo read GetMetaObject;

      property NeedCheckStyles: TStringList read fNeedCheckStyles;
  end;

  function SplitIdentifier(Identifier: String): TLabelRecord;
  function CombineIdentifier(Identifier: TLabelRecord): String;

var
  PieceManager: TNeoPieceManager; // Globalized as this does not need to have seperate instances

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

procedure TNeoPieceManager.Clear;
begin
  fTerrains.Clear;
  fObjects.Clear;
  fLoadedPropertiesStyles.Clear;
  fAliases.Clear;
  fUpscaling.Clear;
  fNeedCheckStyles.Clear;
  LoadProperties('default');
end;

constructor TNeoPieceManager.Create;
begin
  inherited;
  fTerrains := TMetaTerrains.Create;
  fObjects := TGadgetMetaInfoList.Create;
  fTheme := nil;
  fLoadedPropertiesStyles := TStringList.Create;
  fAliases := TList<TStyleAlias>.Create;
  fUpscaling := TList<TUpscaleInfo>.Create;

  fNeedCheckStyles := TStringList.Create;
  fNeedCheckStyles.Sorted := true;
  fNeedCheckStyles.Duplicates := dupIgnore;

  LoadProperties('default');
end;

destructor TNeoPieceManager.Destroy;
begin
  fTerrains.Free;
  fObjects.Free;
  fAliases.Free;
  fUpscaling.Free;
  fLoadedPropertiesStyles.Free;
  fNeedCheckStyles.Free;
  inherited;
end;

// Tidy-up function, clears out the lists. Might add stuff in the future so it retains frequently-used pieces.
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

  // If it's not found
  Result := ObtainTerrain(Identifier);
end;

function TNeoPieceManager.FindObjectIndexByIdentifier(Identifier: String): Integer;
begin
  Identifier := Lowercase(Identifier);
  for Result := 0 to ObjectCount-1 do
    if fObjects[Result].Identifier = Identifier then Exit;

  // If it's not found
  Result := ObtainObject(Identifier);
end;

// ... And to load it if not found.

function TNeoPieceManager.ObtainTerrain(Identifier: String): Integer;
var
  BasePath: String;
  TerrainLabel: TLabelRecord;
  T: TMetaTerrain;
begin
  TerrainLabel := SplitIdentifier(Identifier);

  Result := fTerrains.Count;

  BasePath := AppPath + SFStyles + TerrainLabel.GS + SFPiecesTerrain + TerrainLabel.Piece;

  if FileExists(BasePath + '.png') then  // .nxmt is optional, but .png is not :)
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
  BMP, HrBMP: TBitmap32;
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
  if GameParams.HighResolution then
    HrBMP := TBitmap32.Create
  else
    HrBMP := nil;

  BMP := TBitmap32.Create;
  try
    GameParams.Renderer.PrepareCompositePieceBitmaps(aGroup.Terrains, BMP, HrBMP);

    T := fTerrains.Add;
    T.LoadFromImage(BMP, HrBMP, COMPOSITE_PIECE_STYLE, aGroup.Name, IsGroupSteel);
  finally
    BMP.Free;
    HrBMP.Free;
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

// Aliases and upscaling

procedure TNeoPieceManager.LoadAliases(aStyle: String);
var
  Parser: TParser;
begin
  if not FileExists(AppPath + SFStyles + aStyle + '\alias.nxmi') then Exit;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFStyles + aStyle + '\alias.nxmi');

    Parser.MainSection.DoForEachSection('GADGET', AddAlias, Pointer(rkGadget));
    Parser.MainSection.DoForEachSection('TERRAIN', AddAlias, Pointer(rkTerrain));
    Parser.MainSection.DoForEachSection('BACKGROUND', AddAlias, Pointer(rkBackground));
    Parser.MainSection.DoForEachSection('STYLE', AddAlias, Pointer(rkStyle));
    Parser.MainSection.DoForEachSection('LEMMINGS', AddAlias, Pointer(rkLemmings));
  finally
    Parser.Free;
  end;
end;

procedure TNeoPieceManager.LoadProperties(aStyle: String);
begin
  if fLoadedPropertiesStyles.IndexOf(aStyle) >= 0 then Exit;
  fLoadedPropertiesStyles.Add(aStyle);

  fLoadPropertiesStyle := aStyle;

  LoadAliases(aStyle);
  LoadUpscaling(aStyle);
end;

procedure TNeoPieceManager.LoadUpscaling(aStyle: String);
var
  Parser: TParser;
begin
  if not FileExists(AppPath + SFStyles + aStyle + '\upscaling.nxmi') then
  begin
    Exit;
  end;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFStyles + aStyle + '\upscaling.nxmi');

    Parser.MainSection.DoForEachSection('GADGET', AddUpscaling, Pointer(rkGadget));
    Parser.MainSection.DoForEachSection('TERRAIN', AddUpscaling, Pointer(rkTerrain));
    Parser.MainSection.DoForEachSection('BACKGROUND', AddUpscaling, Pointer(rkBackground));
    Parser.MainSection.DoForEachSection('STYLE', AddUpscaling, Pointer(rkStyle));
    Parser.MainSection.DoForEachSection('LEMMINGS', AddUpscaling, Pointer(rkLemmings));
  finally
    Parser.Free;
  end;
end;

procedure TNeoPieceManager.AddAlias(aSection: TParserSection;
  const aIteration: Integer; aData: Pointer);
var
  Kind: TAliasKind absolute aData;
  NewRec: TStyleAlias;
begin
  NewRec.Source := SplitIdentifier(aSection.LineString['FROM']);
  NewRec.Dest := SplitIdentifier(aSection.LineString['TO']);
  NewRec.DefWidth := aSection.LineNumericDefault['WIDTH', -1];
  NewRec.DefHeight := aSection.LineNumericDefault['HEIGHT', -1];
  NewRec.Kind := Kind;

  if NewRec.Source.GS = '' then NewRec.Source.GS := fLoadPropertiesStyle;
  if NewRec.Dest.GS = '' then NewRec.Dest.GS := fLoadPropertiesStyle;

  fAliases.Add(NewRec);
end;

procedure TNeoPieceManager.AddUpscaling(aSection: TParserSection;
  const aIteration: Integer; aData: Pointer);
var
  Kind: TAliasKind absolute aData;
  NewRec: TUpscaleInfo;

  function GetEdgeBehaviour(aLabel: String): TUpscaleEdgeBehaviour;
  begin
    Result := uebRepeat;
    if Uppercase(aSection.LineTrimString[aLabel]) = 'MIRROR' then Result := uebMirror;
    if Uppercase(aSection.LineTrimString[aLabel]) = 'BLANK' then Result := uebTransparent;
  end;
begin
  NewRec.Source.GS := fLoadPropertiesStyle;
  NewRec.Kind := Kind;
  NewRec.Settings.LeftSide := GetEdgeBehaviour('LEFT_EDGE');
  NewRec.Settings.TopSide := GetEdgeBehaviour('TOP_EDGE');
  NewRec.Settings.RightSide := GetEdgeBehaviour('RIGHT_EDGE');
  NewRec.Settings.BottomSide := GetEdgeBehaviour('BOTTOM_EDGE');

  NewRec.Settings.Mode := umPixelArt;
  if Uppercase(aSection.LineTrimString['UPSCALE']) = 'ZOOM' then NewRec.Settings.Mode := umNearest;
  if Uppercase(aSection.LineTrimString['UPSCALE']) = 'RESAMPLE' then NewRec.Settings.Mode := umFullColor;

  aSection.DoForEachLine('PIECE', procedure(aLine: TParserLine; const aIteration: Integer)
  begin
    NewRec.Source.Piece := aLine.ValueTrimmed;
    fUpscaling.Add(NewRec);
  end);
end;

function TNeoPieceManager.Dealias(aIdentifier: String; aKind: TAliasKind): TDealiasResult;
var
  LastIdent: TLabelRecord;
  i: Integer;
begin
  Result.Piece := SplitIdentifier(aIdentifier);
  Result.DefWidth := 0;
  Result.DefHeight := 0;
  repeat
    LastIdent := Result.Piece;
    LoadProperties(Result.Piece.GS);

    if aKind <> rkStyle then
      for i := 0 to fAliases.Count-1 do
      begin
        if Result.Piece.GS <> fAliases[i].Source.GS then Continue;

        if (fAliases[i].Kind = aKind) and (Result.Piece.Piece = fAliases[i].Source.Piece) then
        begin
          Result.Piece := fAliases[i].Dest;
          Result.DefWidth := fAliases[i].DefWidth;
          Result.DefHeight := fAliases[i].DefHeight;
        end;
      end;

    for i := 0 to fAliases.Count-1 do
    begin
      if Result.Piece.GS <> fAliases[i].Source.GS then Continue;

      if fAliases[i].Kind = rkStyle then
        Result.Piece.GS := fAliases[i].Dest.GS;
    end;
  until (Result.Piece.GS = LastIdent.GS) and (Result.Piece.Piece = LastIdent.Piece);
end;

function TNeoPieceManager.GetUpscaleInfo(aIdentifier: String;
  aKind: TAliasKind): TUpscaleInfo;
var
  Ident: TLabelRecord;
  i: Integer;
begin
  Ident := SplitIdentifier(aIdentifier);

  LoadProperties(Ident.GS);

  // Fallback settings
  FillChar(Result, SizeOf(TUpscaleInfo), 0);

  if aKind = rkLemmings then
    Result.Settings.Mode := umNearest
  else
    Result.Settings.Mode := umPixelArt;

  if aKind in [rkTerrain, rkBackground] then
  begin
    Result.Settings.LeftSide := uebRepeat;
    Result.Settings.TopSide := uebRepeat;
    Result.Settings.RightSide := uebRepeat;
    Result.Settings.BottomSide := uebRepeat;
  end else begin
    Result.Settings.LeftSide := uebTransparent;
    Result.Settings.TopSide := uebTransparent;
    Result.Settings.RightSide := uebTransparent;
    Result.Settings.BottomSide := uebTransparent;
  end;

  for i := 0 to fUpscaling.Count-1 do
  begin
    if Ident.GS <> fUpscaling[i].Source.GS then Continue;

    if fUpscaling[i].Kind = rkStyle then Result := fUpscaling[i];

    if (fUpscaling[i].Kind = aKind) and
       ((aKind = rkLemmings) or (Ident.Piece = fUpscaling[i].Source.Piece)) then
    begin
      Result := fUpscaling[i];
      Exit;
    end;
  end;
end;

end.