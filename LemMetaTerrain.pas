{$include lem_directives.inc}
unit LemMetaTerrain;

interface

uses
  Dialogs,
  Classes, SysUtils, GR32,
  LemRenderHelpers,
  LemNeoParser, PngInterface, LemStrings, LemTypes, Contnrs;

const
  ALIGNMENT_COUNT = 8; // 8 possible combinations of Flip + Invert + Rotate

type
  TTerrainVariableProperties = record // For properties that vary based on flip / invert
    GraphicImage:        TBitmap32;
    GraphicImageHighRes: TBitmap32;
    ResizeHorizontal: Boolean;
    ResizeVertical  : Boolean;
    DefaultWidth: Integer;
    DefaultHeight: Integer;
    CutLeft: Integer;
    CutTop: Integer;
    CutRight: Integer;
    CutBottom: Integer;
  end;
  PTerrainVariableProperties = ^TTerrainVariableProperties;

  TTerrainMetaProperty = (tv_Width, tv_Height, tv_DefaultHeight, tv_DefaultWidth, tv_CutLeft, tv_CutTop, tv_CutRight, tv_CutBottom);
                         // Integer properties only.

   TMetaTerrain = class
    private
      fGS    : String;
      fPiece  : String;

      fVariableInfo: array[0..ALIGNMENT_COUNT-1] of TTerrainVariableProperties;
      fGeneratedVariableInfo: array[0..ALIGNMENT_COUNT-1] of Boolean;

      fIsSteel         : Boolean;

      fCyclesSinceLastUse: Integer; // To improve TNeoPieceManager.Tidy

      function GetIdentifier: String;
      function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
      function GetGraphicImage(Flip, Invert, Rotate: Boolean): TBitmap32;
      function GetGraphicImageHighRes(Flip, Invert, Rotate: Boolean): TBitmap32;
      procedure EnsureVariationMade(Flip, Invert, Rotate: Boolean);
      procedure DeriveVariation(Flip, Invert, Rotate: Boolean);

      function GetVariableProperty(Flip, Invert, Rotate: Boolean; Index: TTerrainMetaProperty): Integer;
      // Bookmark - why is this commented out?
      //procedure SetVariableProperty(Flip, Invert, Rotate: Boolean; Index: TTerrainMetaProperty; const aValue: Integer);

      function GetResizableProperty(Flip, Invert, Rotate: Boolean; aDirection: Integer): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      procedure SetGraphic(aImage: TBitmap32; aImageHighRes: TBitmap32);
      procedure ClearImages;

      procedure Load(aCollection, aPiece: String);
      procedure LoadFromImage(aImage: TBitmap32; aImageHighRes: TBitmap32; aCollection, aPiece: String; aSteel: Boolean);

      property Identifier : String read GetIdentifier;
      property GraphicImage[Flip, Invert, Rotate: Boolean]: TBitmap32 read GetGraphicImage;
      property GraphicImageHighRes[Flip, Invert, Rotate: Boolean]: TBitmap32 read GetGraphicImageHighRes;
      property GS     : String read fGS write fGS;
      property Piece  : String read fPiece write fPiece;
      property Width[Flip, Invert, Rotate: Boolean] : Integer index tv_Width read GetVariableProperty;
      property Height[Flip, Invert, Rotate: Boolean]: Integer index tv_Height read GetVariableProperty;
      property ResizeHorizontal[Flip, Invert, Rotate: Boolean]: Boolean index 0 read GetResizableProperty;
      property ResizeVertical[Flip, Invert, Rotate: Boolean]: Boolean index 1 read GetResizableProperty;
      property DefaultWidth[Flip, Invert, Rotate: Boolean] : Integer index tv_DefaultWidth read GetVariableProperty;
      property DefaultHeight[Flip, Invert, Rotate: Boolean]: Integer index tv_DefaultHeight read GetVariableProperty;
      property CutLeft[Flip, Invert, Rotate: Boolean]: Integer index tv_CutLeft read GetVariableProperty;
      property CutTop[Flip, Invert, Rotate: Boolean]: Integer index tv_CutTop read GetVariableProperty;
      property CutRight[Flip, Invert, Rotate: Boolean]: Integer index tv_CutRight read GetVariableProperty;
      property CutBottom[Flip, Invert, Rotate: Boolean]: Integer index tv_CutBottom read GetVariableProperty;
      property IsSteel       : Boolean read fIsSteel write fIsSteel;
      property CyclesSinceLastUse: Integer read fCyclesSinceLastUse write fCyclesSinceLastUse;
  end;

  TMetaTerrains = class(TObjectList)
    private
      function GetItem(Index: Integer): TMetaTerrain;
    public
      constructor Create;
      function Add(Item: TMetaTerrain): Integer; overload;
      function Add: TMetaTerrain; overload;
      property Items[Index: Integer]: TMetaTerrain read GetItem; default;
      property List;
  end;

implementation

uses
  LemNeoPieceManager,
  GameControl;

{ TMetaTerrain }

constructor TMetaTerrain.Create;
begin
  inherited;
  fVariableInfo[0].GraphicImage := TBitmap32.Create;

  if GameParams.HighResolution then
    fVariableInfo[0].GraphicImageHighRes := TBitmap32.Create;
end;

destructor TMetaTerrain.Destroy;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fVariableInfo[i].GraphicImage.Free;
    fVariableInfo[i].GraphicImageHighRes.Free;
  end;
  inherited;
end;

procedure TMetaTerrain.Load(aCollection, aPiece: String);
var
  Parser: TParser;
  Info: TUpscaleInfo;
begin
  ClearImages;

  if not DirectoryExists(AppPath + SFStyles + aCollection + SFPiecesTerrain) then
    raise Exception.Create('TMetaTerrain.Load: Collection "' + aCollection + '" does not exist or lacks terrain.');
  SetCurrentDir(AppPath + SFStyles + aCollection + SFPiecesTerrain);

  fGS := Lowercase(aCollection);
  fPiece := Lowercase(aPiece);

  if FileExists(aPiece + '.nxmt') then
  begin
    Parser := TParser.Create;
    try
      Parser.LoadFromFile(aPiece + '.nxmt');
      fIsSteel := Parser.MainSection.Line['steel'] <> nil;
      fVariableInfo[0].ResizeHorizontal := (Parser.MainSection.Line['resize_horizontal'] <> nil) or (Parser.MainSection.Line['resize_both'] <> nil);
      fVariableInfo[0].ResizeVertical := (Parser.MainSection.Line['resize_vertical'] <> nil) or (Parser.MainSection.Line['resize_both'] <> nil);
      fVariableInfo[0].DefaultWidth := Parser.MainSection.LineNumeric['default_width'];
      fVariableInfo[0].DefaultHeight := Parser.MainSection.LineNumeric['default_height'];
      fVariableInfo[0].CutLeft := Parser.MainSection.LineNumeric['nine_slice_left'];
      fVariableInfo[0].CutTop := Parser.MainSection.LineNumeric['nine_slice_top'];
      fVariableInfo[0].CutRight := Parser.MainSection.LineNumeric['nine_slice_right'];
      fVariableInfo[0].CutBottom := Parser.MainSection.LineNumeric['nine_slice_bottom'];
    finally
      Parser.Free;
    end;
  end;

  TPngInterface.LoadPngFile(aPiece + '.png', fVariableInfo[0].GraphicImage);

  if GameParams.HighResolution then
  begin
    if FileExists(AppPath + SFStyles + aCollection + SFPiecesTerrainHighRes + aPiece + '.png') then
      TPngInterface.LoadPngFile(AppPath + SFStyles + aCollection + SFPiecesTerrainHighRes + aPiece + '.png', fVariableInfo[0].GraphicImageHighRes)
    else begin
      Info := PieceManager.GetUpscaleInfo(Identifier, rkTerrain);
      Upscale(fVariableInfo[0].GraphicImage, Info.Settings, fVariableInfo[0].GraphicImageHighRes);
    end;
  end;

  fGeneratedVariableInfo[0] := true;
end;

procedure TMetaTerrain.LoadFromImage(aImage: TBitmap32; aImageHighRes: TBitmap32; aCollection, aPiece: String; aSteel: Boolean);
begin
  ClearImages;
  fVariableInfo[0].GraphicImage.Assign(aImage);

  if GameParams.HighResolution then
    fVariableInfo[0].GraphicImageHighRes.Assign(aImageHighRes);

  fGeneratedVariableInfo[0] := true;

  fGS := Lowercase(aCollection);
  fPiece := Lowercase(aPiece);
  fIsSteel := aSteel;
end;

procedure TMetaTerrain.ClearImages;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    if fVariableInfo[i].GraphicImage <> nil then fVariableInfo[i].GraphicImage.Clear;
    if fVariableInfo[i].GraphicImageHighRes <> nil then fVariableInfo[i].GraphicImageHighRes.Clear;

    fGeneratedVariableInfo[i] := false;
  end;
end;

procedure TMetaTerrain.SetGraphic(aImage: TBitmap32; aImageHighRes: TBitmap32);
begin
  ClearImages;
  fVariableInfo[0].GraphicImage.Assign(aImage);

  if GameParams.HighResolution then
    fVariableInfo[0].GraphicImageHighRes.Assign(aImageHighRes);

  fGeneratedVariableInfo[0] := true;
end;

{procedure TMetaTerrain.SetVariableProperty(Flip, Invert, Rotate: Boolean;
  Index: TTerrainMetaProperty; const aValue: Integer);
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  with fVariableInfo[GetImageIndex(Flip, Invert, Rotate)] do
  begin
    case Index of
      tv_Width: ; // Remove this later, it's just here so the "else" doesn't give a syntax error
      else raise Exception.Create('TMetaTerrain.SetVariableProperty given invalid value.');
    end;
  end;
end;
}

function TMetaTerrain.GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
begin
  Result := 0;
  if Flip then Inc(Result, 1);
  if Invert then Inc(Result, 2);
  if Rotate then Inc(Result, 4);
end;

function TMetaTerrain.GetResizableProperty(Flip, Invert, Rotate: Boolean;
  aDirection: Integer): Boolean;
var
  i: Integer;
begin           
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  case aDirection of
    0: Result := fVariableInfo[i].ResizeHorizontal;
    1: Result := fVariableInfo[i].ResizeVertical;
    else raise Exception.Create('Invalid input to TMetaTerrain.GetResizableProperty');
  end;
end;

function TMetaTerrain.GetGraphicImage(Flip, Invert, Rotate: Boolean): TBitmap32;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].GraphicImage;
end;

function TMetaTerrain.GetGraphicImageHighRes(Flip, Invert, Rotate: Boolean): TBitmap32;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].GraphicImageHighRes;
end;

function TMetaTerrain.GetVariableProperty(Flip, Invert, Rotate: Boolean;
  Index: TTerrainMetaProperty): Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  with fVariableInfo[GetImageIndex(Flip, Invert, Rotate)] do
  begin
    case Index of
      tv_Width: Result := GraphicImage.Width;
      tv_Height: Result := GraphicImage.Height;
      tv_DefaultWidth: Result := DefaultWidth;
      tv_DefaultHeight: Result := DefaultHeight;
      tv_CutLeft: Result := CutLeft;
      tv_CutTop: Result := CutTop;
      tv_CutRight: Result := CutRight;
      tv_CutBottom: Result := CutBottom;
      else raise Exception.Create('TMetaTerrain.GetVariableProperty given invalid value.');
    end;
  end;
end;

procedure TMetaTerrain.EnsureVariationMade(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if not fGeneratedVariableInfo[i] then
    DeriveVariation(Flip, Invert, Rotate);
end;

procedure TMetaTerrain.DeriveVariation(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
  BMP: TBitmap32;
  Temp: Integer;

  procedure CloneFromStandard;
  var
    GfxBmp, HrGfxBmp: TBitmap32;
  begin
    GfxBmp := fVariableInfo[i].GraphicImage;
    HrGfxBmp := fVariableInfo[i].GraphicImageHighRes;
    fVariableInfo[i] := fVariableInfo[0];
    fVariableInfo[i].GraphicImage := GfxBmp;
    fVariableInfo[i].GraphicImageHighRes := HrGfxBmp;
  end;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  CloneFromStandard;

  if fVariableInfo[i].GraphicImage = nil then fVariableInfo[i].GraphicImage := TBitmap32.Create;
  BMP := fVariableInfo[i].GraphicImage;
  BMP.Assign(fVariableInfo[0].GraphicImage);
  if Rotate then BMP.Rotate90;
  if Flip then BMP.FlipHorz;
  if Invert then BMP.FlipVert;

  if GameParams.HighResolution then
  begin
    if fVariableInfo[i].GraphicImageHighRes = nil then fVariableInfo[i].GraphicImageHighRes := TBitmap32.Create;
    BMP := fVariableInfo[i].GraphicImageHighRes;
    BMP.Assign(fVariableInfo[0].GraphicImageHighRes);
    if Rotate then BMP.Rotate90;
    if Flip then BMP.FlipHorz;
    if Invert then BMP.FlipVert;
  end;

  if Rotate then
  begin
    fVariableInfo[i].ResizeHorizontal := fVariableInfo[0].ResizeVertical;
    fVariableInfo[i].ResizeVertical := fVariableInfo[0].ResizeHorizontal;
    fVariableInfo[i].DefaultWidth := fVariableInfo[0].DefaultHeight;
    fVariableInfo[i].DefaultHeight := fVariableInfo[0].DefaultWidth;
    fVariableInfo[i].CutLeft := fVariableInfo[0].CutBottom;
    fVariableInfo[i].CutTop := fVariableInfo[0].CutLeft;
    fVariableInfo[i].CutRight := fVariableInfo[0].CutTop;
    fVariableInfo[i].CutBottom := fVariableInfo[0].CutRight;
  end;

  if Flip then
  begin
    Temp := fVariableInfo[0].CutLeft;
    fVariableInfo[i].CutLeft := fVariableInfo[i].CutRight;
    fVariableInfo[i].CutRight := Temp;
  end;

  if Invert then
  begin
    Temp := fVariableInfo[0].CutTop;
    fVariableInfo[i].CutTop := fVariableInfo[i].CutBottom;
    fVariableInfo[i].CutBottom := Temp;
  end;

  fGeneratedVariableInfo[i] := true;
end;

function TMetaTerrain.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

{ TMetaTerrains }

constructor TMetaTerrains.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TMetaTerrains.Add(Item: TMetaTerrain): Integer;
begin
  Result := inherited Add(Item);
end;

function TMetaTerrains.Add: TMetaTerrain;
begin
  Result := TMetaTerrain.Create;
  inherited Add(Result);
end;

function TMetaTerrains.GetItem(Index: Integer): TMetaTerrain;
begin
  Result := inherited Get(Index);
end;

end.

