{$include lem_directives.inc}
unit LemMetaTerrain;

interface

uses
  Dialogs,
  Classes, SysUtils, GR32,
  LemRenderHelpers,
  LemNeoParser, PngInterface, LemStrings, LemTypes, Contnrs,
  UTools;

const
  ALIGNMENT_COUNT = 8; // 8 possible combinations of Flip + Invert + Rotate

type

 TMetaTerrain = class
  private
    fGS    : String;
    fPiece  : String;
    fWidth          : Integer;
    fHeight         : Integer;
    fIsSteel        : Boolean;
    function GetIdentifier: String;
    function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
    function GetGraphicImage(Flip, Invert, Rotate: Boolean): TBitmap32;
    function GetPhysicsImage(Flip, Invert, Rotate: Boolean): TBitmap32;
    procedure EnsureImageMade(Flip, Invert, Rotate: Boolean);
    procedure DeriveGraphicImage(Flip, Invert, Rotate: Boolean);
    procedure DerivePhysicsImage(Flip, Invert, Rotate: Boolean);
  protected
    fGraphicImages: array[0..ALIGNMENT_COUNT-1] of TBitmap32;
    fPhysicsImages: array[0..ALIGNMENT_COUNT-1] of TBitmap32;
    fGeneratedGraphicImage: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fGeneratedPhysicsImage: array[0..ALIGNMENT_COUNT-1] of Boolean;  
    procedure GenerateGraphicImage; virtual;
    procedure GeneratePhysicsImage; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetGraphic(aImage: TBitmap32);
    procedure ClearImages;

    procedure Load(aCollection, aPiece: String); virtual;

    property Identifier : String read GetIdentifier;
    property GraphicImage[Flip, Invert, Rotate: Boolean]: TBitmap32 read GetGraphicImage;
    property PhysicsImage[Flip, Invert, Rotate: Boolean]: TBitmap32 read GetPhysicsImage;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;
    property Width         : Integer read fWidth write fWidth;
    property Height        : Integer read fHeight write fHeight;
    property IsSteel       : Boolean read fIsSteel write fIsSteel;
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

{ TMetaTerrain }

constructor TMetaTerrain.Create;
var
  i: Integer;
begin
  inherited;
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fGraphicImages[i] := TBitmap32.Create;
    fPhysicsImages[i] := TBitmap32.Create;
  end;
end;

destructor TMetaTerrain.Destroy;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fGraphicImages[i].Free;
    fPhysicsImages[i].Free;
  end;
  inherited;
end;

procedure TMetaTerrain.Load(aCollection, aPiece: String);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
begin
  Parser := TNeoLemmixParser.Create;
  try
    ClearImages;

    if not DirectoryExists(AppPath + SFStylesPieces + aCollection) then
    raise Exception.Create('TMetaTerrain.Load: Collection "' + aCollection + '" does not exist.');
    SetCurrentDir(AppPath + SFStylesPieces + aCollection + SFPiecesTerrain);

    fGS := Lowercase(aCollection);
    fPiece := Lowercase(aPiece);

    if FileExists(aPiece + '.nxtp') then
    begin
      Parser.LoadFromFile(fPiece + '.nxtp');
      repeat
        Line := Parser.NextLine;
        if Line.Keyword = 'STEEL' then
          fIsSteel := true;
      until Line.Keyword = '';
    end;

    TPngInterface.LoadPngFile(aPiece + '.png', fGraphicImages[0]);
    fGeneratedGraphicImage[0] := true;
  finally
    Parser.Free;
  end;
end;

procedure TMetaTerrain.ClearImages;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fGraphicImages[i].Clear;
    fPhysicsImages[i].Clear;
    fGeneratedGraphicImage[i] := false;
    fGeneratedPhysicsImage[i] := false;
  end;
end;

procedure TMetaTerrain.SetGraphic(aImage: TBitmap32);
begin
  ClearImages;
  fGraphicImages[0].Assign(aImage);
  fGeneratedGraphicImage[0] := true;
end;

function TMetaTerrain.GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
begin
  Result := 0;
  if Flip then Inc(Result, 1);
  if Invert then Inc(Result, 2);
  if Rotate then Inc(Result, 4);
end;

function TMetaTerrain.GetGraphicImage(Flip, Invert, Rotate: Boolean): TBitmap32;
var
  i: Integer;
begin
  EnsureImageMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fGraphicImages[i];
end;

function TMetaTerrain.GetPhysicsImage(Flip, Invert, Rotate: Boolean): TBitmap32;
var
  i: Integer;
begin
  EnsureImageMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fPhysicsImages[i];
end;

procedure TMetaTerrain.GenerateGraphicImage;
begin
  raise Exception.Create('Basic TMetaTerrain cannot interally generate the graphical image!');
end;

procedure TMetaTerrain.GeneratePhysicsImage;
var
  x, y: Integer;
begin
  fPhysicsImages[0].SetSizeFrom(fGraphicImages[0]);
  for y := 0 to fGraphicImages[0].Height-1 do
    for x := 0 to fGraphicImages[0].Width-1 do
      if (fGraphicImages[0][x, y] and ALPHA_CUTOFF) <> 0 then
        if fIsSteel then
          fPhysicsImages[0][x, y] := PM_SOLID or PM_STEEL
        else
          fPhysicsImages[0][x, y] := PM_SOLID;
  fGeneratedPhysicsImage[0] := true;
end;

procedure TMetaTerrain.EnsureImageMade(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
begin
  if not fGeneratedGraphicImage[0] then GenerateGraphicImage;
  if not fGeneratedPhysicsImage[0] then GeneratePhysicsImage;

  i := GetImageIndex(Flip, Invert, Rotate);
  if not fGeneratedGraphicImage[i] then
    DeriveGraphicImage(Flip, Invert, Rotate);
  if not fGeneratedPhysicsImage[i] then
    DerivePhysicsImage(Flip, Invert, Rotate);
end;

procedure TMetaTerrain.DeriveGraphicImage(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
  BMP: TBitmap32;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  BMP := fGraphicImages[i];
  BMP.Assign(fGraphicImages[0]);
  if Rotate then BMP.Rotate90;
  if Flip then BMP.FlipHorz;
  if Invert then BMP.FlipVert;
  fGeneratedGraphicImage[i] := true;
end;

procedure TMetaTerrain.DerivePhysicsImage(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
  BMP: TBitmap32;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  BMP := fPhysicsImages[i];
  BMP.Assign(fPhysicsImages[0]);
  if Rotate then BMP.Rotate90;
  if Flip then BMP.FlipHorz;
  if Invert then BMP.FlipVert;
  fGeneratedPhysicsImage[i] := true;
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

