{$include lem_directives.inc}
unit LemTerrain;

interface

uses
  LemNeoParser,
  Dialogs,
  Classes,
  LemPiece,
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

    procedure LoadFromSection(aSection: TParserSection);
    procedure SaveToSection(aSection: TParserSection);
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

uses
  LemNeoPieceManager;

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

procedure TTerrain.LoadFromSection(aSection: TParserSection);
  procedure Flag(aValue: Integer);
  begin
    fDrawingFlags := fDrawingFlags or aValue;
  end;
var
  Ident: TLabelRecord;
begin
  if aSection.Line['style'] = nil then
    GS := aSection.LineTrimString['collection']
  else
    GS := aSection.LineTrimString['style'];

  Ident := SplitIdentifier(PieceManager.Dealias(Identifier, rkTerrain));
  GS := Ident.GS;
  Piece := Ident.Piece;

  Piece := aSection.LineTrimString['piece'];
  Left := aSection.LineNumeric['x'];
  Top := aSection.LineNumeric['y'];

  DrawingFlags := tdf_NoOneWay;
  if (aSection.Line['one_way'] <> nil) then fDrawingFlags := 0;
  if (aSection.Line['rotate'] <> nil) then Flag(tdf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(tdf_Flip);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(tdf_Invert);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(tdf_NoOverwrite);
  if (aSection.Line['erase'] <> nil) then Flag(tdf_Erase);
end;

procedure TTerrain.SaveToSection(aSection: TParserSection);
  function Flag(aValue: Integer): Boolean;
  begin
    Result := DrawingFlags and aValue = aValue;
  end;
begin
  aSection.AddLine('STYLE', GS);
  aSection.AddLine('PIECE', Piece);
  aSection.AddLine('X', Left);
  aSection.AddLine('Y', Top);

  if Flag(tdf_Rotate) then aSection.AddLine('ROTATE');
  if Flag(tdf_Flip) then aSection.AddLine('FLIP_HORIZONTAL');
  if Flag(tdf_Invert) then aSection.AddLine('FLIP_VERTICAL');
  if Flag(tdf_NoOverwrite) then aSection.AddLine('NO_OVERWRITE');
  if Flag(tdf_Erase) then aSection.AddLine('ERASE');
  if not Flag(tdf_NoOneWay) then aSection.AddLine('ONE_WAY');
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

