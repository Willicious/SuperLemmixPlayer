{$include lem_directives.inc}
unit LemMetaTerrain;

interface

uses
  Classes, SysUtils,
  UTools;

type
 TMetaTerrain = class(TCollectionItem)
  private
    fGS    : String;
    fPiece  : String;
    fWidth          : Integer;
    fHeight         : Integer;
    fImageLocation  : Integer; // DOS history: data location of image in vgagr??.dat
    fUnknown        : Integer;
    function GetIdentifier: String;
  protected
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Identifier : String read GetIdentifier;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;
    property Width         : Integer read fWidth write fWidth;
    property Height        : Integer read fHeight write fHeight;
    property ImageLocation : Integer read fImageLocation write fImageLocation;
    property Unknown       : Integer read fUnknown write fUnknown;
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

procedure TMetaTerrain.Assign(Source: TPersistent);
var
  T: TMetaTerrain absolute Source;
begin
  if Source is TMetaTerrain then
  begin
    fWidth := T.fWidth;
    fHeight := T.fHeight;
    fImageLocation := T.fImageLocation;
    fUnknown := T.fUnknown;
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

