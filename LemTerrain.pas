{$include lem_directives.inc}
unit LemTerrain;

interface

uses
  Dialogs,
  Classes,
  UTools,
  LemPiece,
  LemNeoParser,
  Contnrs,
  SysUtils;

const
  // Terrain Drawing Flags
  tdf_Erase                    = 1;    // bit 0 use terrain bitmap as eraser
  tdf_Invert                   = 2;    // bit 1 invert terrain bitmap
  tdf_NoOverwrite              = 4;    // bit 2 do not overwrite existing terrain pixels
  tdf_Steel                    = 8;    // bit 3 steel
  tdf_Flip                     = 16;
  tdf_NoOneWay                 = 32;
  tdf_Rotate                   = 64;

type
  TTerrainClass = class of TTerrain;

  TTerrain = class(TIdentifiedPiece)
  private
  protected
    fDrawingFlags : Byte;
    procedure SetFlip(aValue: Boolean); override;
    procedure SetInvert(aValue: Boolean); override;
    procedure SetRotate(aValue: Boolean); override;
    function GetFlip: Boolean; override;
    function GetInvert: Boolean; override;
    function GetRotate: Boolean; override;
  public
    procedure Assign(Source: TPiece); override;
    procedure EvaluateParserLine(Line: TParserLine);
  published
    property DrawingFlags: Byte read fDrawingFlags write fDrawingFlags;
  end;

type
  TTerrains = class(TObjectList)
    private
      function GetItem(Index: Integer): TTerrain;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add(Item: TTerrain): Integer; overload;
      function Add: TTerrain; overload;
      procedure Insert(Index: Integer; Item: TTerrain); overload;
      function Insert(Index: Integer): TTerrain; overload;
      procedure Assign(aSrc: TTerrains);
      property Items[Index: Integer]: TTerrain read GetItem; default;
      property List;
  end;

implementation

{ TTerrain }

procedure TTerrain.Assign(Source: TPiece);
var
  T: TTerrain absolute Source;
begin
  if Source is TTerrain then
  begin
    inherited;
    DrawingFlags := T.DrawingFlags;
  end;
end;

procedure TTerrain.EvaluateParserLine(Line: TParserLine);
begin
  if Line.Keyword = 'SET' then
    fSet := Lowercase(Line.ValueTrimmed);

  if Line.Keyword = 'PIECE' then
    fPiece := Lowercase(Line.ValueTrimmed);

  if Line.Keyword = 'X' then
    fLeft := Line.Numeric;

  if Line.Keyword = 'Y' then
    fTop := Line.Numeric;

  if Line.Keyword = 'NO_OVERWRITE' then
    fDrawingFlags := fDrawingFlags or tdf_NoOverwrite;

  if Line.Keyword = 'FLIP_HORIZONTAL' then
    fDrawingFlags := fDrawingFlags or tdf_Flip;

  if Line.Keyword = 'FLIP_VERTICAL' then
    fDrawingFlags := fDrawingFlags or tdf_Invert;

  if Line.Keyword = 'ERASE' then
    fDrawingFlags := fDrawingFlags or tdf_Erase;

  if Line.Keyword = 'ROTATE' then
    fDrawingFlags := fDrawingFlags or tdf_Rotate;

  if Line.Keyword = 'ONE_WAY' then
    fDrawingFlags := fDrawingFlags and not tdf_NoOneWay;
end;


procedure TTerrain.SetFlip(aValue: Boolean);
begin
  if aValue then
    DrawingFlags := DrawingFlags or tdf_Flip
  else
    DrawingFlags := DrawingFlags and not tdf_Flip;
end;

procedure TTerrain.SetInvert(aValue: Boolean);
begin
  if aValue then
    DrawingFlags := DrawingFlags or tdf_Invert
  else
    DrawingFlags := DrawingFlags and not tdf_Invert;
end;

procedure TTerrain.SetRotate(aValue: Boolean);
begin
  if aValue then
    DrawingFlags := DrawingFlags or tdf_Rotate
  else
    DrawingFlags := DrawingFlags and not tdf_Rotate;
end;

function TTerrain.GetFlip: Boolean;
begin
  Result := (DrawingFlags and tdf_Flip) <> 0;
end;

function TTerrain.GetInvert: Boolean;
begin
  Result := (DrawingFlags and tdf_Invert) <> 0;
end;

function TTerrain.GetRotate: Boolean;
begin
  Result := (DrawingFlags and tdf_Rotate) <> 0;
end;

{ TTerrains }

constructor TTerrains.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TTerrains.Add(Item: TTerrain): Integer;
begin
  Result := inherited Add(Item);
end;

function TTerrains.Add: TTerrain;
begin
  Result := TTerrain.Create;
  inherited Add(Result);
end;

procedure TTerrains.Insert(Index: Integer; Item: TTerrain);
begin
  inherited Insert(Index, Item);
end;

function TTerrains.Insert(Index: Integer): TTerrain;
begin
  Result := TTerrain.Create;
  inherited Insert(Index, Result);
end;

procedure TTerrains.Assign(aSrc: TTerrains);
var
  i: Integer;
  Item: TTerrain;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TTerrains.GetItem(Index: Integer): TTerrain;
begin
  Result := inherited Get(Index);
end;


end.

