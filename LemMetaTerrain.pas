{$include lem_directives.inc}
unit LemMetaTerrain;

interface

uses
  Classes, SysUtils, GR32,
  LemRenderHelpers,
  UTools;

type
 TMetaTerrain = class(TCollectionItem)
  private
    fGraphicImage: TBitmap32;
    fPhysicsImage: TBitmap32;
    fGeneratedPhysicsImage: Boolean;
    fGS    : String;
    fPiece  : String;
    fWidth          : Integer;
    fHeight         : Integer;
    fIsSteel        : Boolean;
    function GetIdentifier: String;
    function GetPhysicsImage: TBitmap32;
  protected
    procedure GeneratePhysicsImage; virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property Identifier : String read GetIdentifier;
    property GraphicImage: TBitmap32 read fGraphicImage;
    property PhysicsImage: TBitmap32 read GetPhysicsImage;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;
    property Width         : Integer read fWidth write fWidth;
    property Height        : Integer read fHeight write fHeight;
    property IsSteel       : Boolean read fIsSteel write fIsSteel;
  end;

  TMetaTerrains = class(TCollectionEx)
  private
    function GetItem(Index: Integer): TMetaTerrain;
    procedure SetItem(Index: Integer; const Value: TMetaTerrain);
  protected
  public
    constructor Create;
    function Add: TMetaTerrain;
    function Insert(Index: Integer): TMetaTerrain;
    property Items[Index: Integer]: TMetaTerrain read GetItem write SetItem; default;
  end;

implementation

{ TMetaTerrain }

constructor TMetaTerrain.Create(Collection: TCollection);
begin
  inherited;
  fGraphicImage := TBitmap32.Create;
  fPhysicsImage := TBitmap32.Create;
end;

destructor TMetaTerrain.Destroy;
begin
  fGraphicImage.Free;
  fPhysicsImage.Free;
  inherited;
end;

function TMetaTerrain.GetPhysicsImage: TBitmap32;
begin
  if not fGeneratedPhysicsImage then GeneratePhysicsImage;
  Result := fPhysicsImage;
end;

procedure TMetaTerrain.GeneratePhysicsImage;
var
  x, y: Integer;
begin
  fPhysicsImage.SetSizeFrom(fGraphicImage);
  for y := 0 to fGraphicImage.Height-1 do
    for x := 0 to fGraphicImage.Width-1 do
      if (fGraphicImage[x, y] and ALPHA_CUTOFF) <> 0 then
        if fIsSteel then
          fPhysicsImage[x, y] := PM_SOLID or PM_STEEL
        else
          fPhysicsImage[x, y] := PM_SOLID;
  fGeneratedPhysicsImage := true;
end;

procedure TMetaTerrain.Assign(Source: TPersistent);
var
  T: TMetaTerrain absolute Source;
begin
  if Source is TMetaTerrain then
  begin
    fGraphicImage.Assign(T.fGraphicImage);
    fPhysicsImage.Assign(T.fPhysicsImage);
    fGS := T.fGS;
    fPiece := T.fPiece;
    fWidth := T.fWidth;
    fHeight := T.fHeight;
    fIsSteel := T.fIsSteel;
  end
  else inherited Assign(Source);
end;

function TMetaTerrain.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

{ TMetaTerrains }

function TMetaTerrains.Add: TMetaTerrain;
begin
  Result := TMetaTerrain(inherited Add);
end;

constructor TMetaTerrains.Create;
begin
  inherited Create(TMetaTerrain);
end;

function TMetaTerrains.GetItem(Index: Integer): TMetaTerrain;
begin
  Result := TMetaTerrain(inherited GetItem(Index))
end;

function TMetaTerrains.Insert(Index: Integer): TMetaTerrain;
begin
  Result := TMetaTerrain(inherited Insert(Index))
end;

procedure TMetaTerrains.SetItem(Index: Integer; const Value: TMetaTerrain);
begin
  inherited SetItem(Index, Value);
end;

end.

