{$include lem_directives.inc}
unit LemPiece;

interface

uses
  Classes, SysUtils;

type
  // Abstract ancestor for object, terrain and steel
  TPieceClass = class of TPiece;
  TPiece = class
  private
  protected
    fLeft : Integer;
    fTop  : Integer;
  public
    procedure Assign(Source: TPiece); virtual;
  published
    property Left: Integer read fLeft write fLeft;
    property Top: Integer read fTop write fTop;
  end;

type
  // Basically ancestor for object and terrain
  TIdentifiedPiece = class(TPiece)
  private
  protected
    fSet: String;
    fPiece: String;
    fLoadIdentifier: String;
    fWidth: Integer;
    fHeight: Integer;
    function GetFlip: Boolean; virtual;
    function GetInvert: Boolean; virtual;
    function GetRotate: Boolean; virtual;
    procedure SetFlip(aValue: Boolean); virtual;
    procedure SetInvert(aValue: Boolean); virtual;
    procedure SetRotate(aValue: Boolean); virtual;
    function GetIdentifier: String;
  public
    procedure Assign(Source: TPiece); override;
  published
    property GS: String read fSet write fSet; // "Set" is a reserved keyword :(
    property Piece: String read fPiece write fPiece;
    property LoadIdentifier: String read fLoadIdentifier write fLoadIdentifier;
    property Identifier: String read GetIdentifier;
    property Width: Integer read fWidth write fWidth;
    property Height: Integer read fHeight write fHeight;
    property Flip   : Boolean read GetFlip write SetFlip;
    property Invert : Boolean read GetInvert write SetInvert;
    property Rotate : Boolean read GetRotate write SetRotate;    
  end;

type
  // Basically ancestor for steel
  TSizedPiece = class(TPiece)
  private
  protected
    fHeight: Integer;
    fWidth: Integer;
  public
    procedure Assign(Source: TPiece); override;
  published
    property Width: Integer read fWidth write fWidth;
    property Height: Integer read fHeight write fHeight;
  end;

implementation

{ TPiece }

procedure TPiece.Assign(Source: TPiece);
begin
  Left := Source.Left;
  Top := Source.Top;
end;

{ TIdentifiedPiece }

procedure TIdentifiedPiece.Assign(Source: TPiece);
var
  IP: TIdentifiedPiece absolute Source;
begin
  if Source is TIdentifiedPiece then
  begin
    inherited;
    GS := IP.GS;
    Piece := IP.Piece;
    LoadIdentifier := IP.LoadIdentifier;
    Width := IP.Width;
    Height := IP.Height;
  end;
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

function TIdentifiedPiece.GetIdentifier: String;
begin
  Result := fSet + ':' + fPiece;
end;

{ TSizedPiece }

procedure TSizedPiece.Assign(Source: TPiece);
var
  SP: TSizedPiece absolute Source;
begin
  if Source is TSizedPiece then
  begin
    inherited;
    Width := SP.Width;
    Height := SP.Height;
  end;
end;

end.
