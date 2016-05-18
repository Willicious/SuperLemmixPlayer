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
  public
    procedure Assign(Source: TPersistent); override;
  published
    property GS: String read fSet write fSet; // "Set" is a reserved keyword :(
    property Piece: String read fPiece write fPiece;
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
