{$include lem_directives.inc}
unit LemMetaPiece;

interface

uses
  Classes;

type
  TMetaPiece = class
  private
  protected
    fGS    : String;
    fPiece  : String;
    fWidth  : Integer;
    fHeight : Integer;
    procedure Error(const S: string); virtual;
    function GetIdentifier: String;
  public
    procedure LoadFromStream(S: TStream); virtual;
  published
    property Identifier : String read GetIdentifier;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;
    property Width  : Integer read fWidth write fWidth;
    property Height : Integer read fHeight write fHeight;
  end;

implementation

uses
  Lemstrings, LemMisc;

{ TMetaPiece }

procedure TMetaPiece.Error(const S: string);
begin
  raise ELemmixError.Create(S);
end;

procedure TMetaPiece.LoadFromStream(S: TStream);
begin
  Error(SMetaPieceLoadError);
end;

function TMetaPiece.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

end.

