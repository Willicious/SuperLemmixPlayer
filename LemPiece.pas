{$include lem_directives.inc}
unit LemPiece;

interface

uses
  Classes, SysUtils,
  UTools;

type
  // abstract ancestor for object, terrain and steel
  TPieceClass = class of TPiece;
  TPiece = class(TCollectionItem)
  private
  protected
    fLeft : Integer;
    fTop  : Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Left: Integer read fLeft write fLeft;
    property Top: Integer read fTop write fTop;
  end;

type
  // basically ancestor for object and terrain
  TIdentifiedPiece = class(TPiece)
  private
  protected
    fSet: String;
    fPiece: String;
    function GetFlip: Boolean; virtual;
    function GetInvert: Boolean; virtual;
    function GetRotate: Boolean; virtual;
    procedure SetFlip(aValue: Boolean); virtual;
    procedure SetInvert(aValue: Boolean); virtual;
    procedure SetRotate(aValue: Boolean); virtual;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property GS: String read fSet write fSet; // "Set" is a reserved keyword :(
    property Piece: String read fPiece write fPiece;
    property Flip   : Boolean read GetFlip write SetFlip;
    property Invert : Boolean read GetInvert write SetInvert;
    property Rotate : Boolean read GetRotate write SetRotate;    
  end;

type
  // basically ancestor for steel
  TSizedPiece = class(TPiece)
  private
  protected
    fHeight: Integer;
    fWidth: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Width: Integer read fWidth write fWidth;
    property Height: Integer read fHeight write fHeight;
  end;

type
  TPieces = class(TCollectionEx)
  public
    constructor Create(aItemClass: TPieceClass);
  end;

implementation


{ TPieces }

constructor TPieces.Create(aItemClass: TPieceClass);
begin
  inherited Create(aItemClass);
end;

{ TPiece }

procedure TPiece.Assign(Source: TPersistent);
var
  P: TPiece absolute Source;
begin
  if Source is TPiece then
  begin
    Left := P.Left;
    Top := P.Top;
  end
  else inherited Assign(Source);
end;

{ TIdentifiedPiece }

procedure TIdentifiedPiece.Assign(Source: TPersistent);
var
  IP: TIdentifiedPiece absolute Source;
begin
  if Source is TIdentifiedPiece then
  begin
    inherited Assign(Source);
    GS := IP.GS;
    Piece := IP.Piece;
  end
  else inherited Assign(Source);
end;

procedure TIdentifiedPiece.SetFlip(aValue: Boolean);
begin
  // Discard if not overridden
end;

procedure TIdentifiedPiece.SetInvert(aValue: Boolean);
begin
end;

procedure TIdentifiedPiece.SetRotate(aValue: Boolean);
begin
end;

function TIdentifiedPiece.GetFlip: Boolean;
begin
  // False, if not overridden
  Result := false;
end;

function TIdentifiedPiece.GetInvert: Boolean;
begin
  Result := false;
end;

function TIdentifiedPiece.GetRotate: Boolean;
begin
  Result := false;
end;

{ TSizedPiece }

procedure TSizedPiece.Assign(Source: TPersistent);
var
  SP: TSizedPiece absolute Source;
begin
  if Source is TSizedPiece then
  begin
    inherited Assign(Source);
    Width := SP.Width;
    Height := SP.Height;
  end
  else inherited Assign(Source);
end;

end.
