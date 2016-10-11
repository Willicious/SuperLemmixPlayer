{$include lem_directives.inc}
unit LemInteractiveObject;

interface

uses
  Contnrs,
  Classes,
  LemPiece;

const
  // Object Drawing Flags
  odf_OnlyOnTerrain = 1; // bit 0
  odf_UpsideDown    = 2; // bit 1
  odf_NoOverwrite   = 4; // bit 2
  odf_FlipLem       = 8;
  odf_Invisible     = 32;
  odf_Flip          = 64;            // Better name: odf_FlipImage
  odf_Rotate        = 128;

type
  TInteractiveObjectClass = class of TInteractiveObject;
  TInteractiveObject = class(TIdentifiedPiece)
  private
  protected
    fWidth: Integer;
    fHeight: Integer;
    fDrawingFlags: Byte; // odf_xxxx
    fFake: Boolean;
    fSkill: Byte;
    fTarLev: Byte;
    fLastDrawX: Integer;
    fLastDrawY: Integer;
    fDrawAsZombie: Boolean;
    procedure SetFlip(aValue: Boolean); override;
    procedure SetInvert(aValue: Boolean); override;
    function GetFlip: Boolean; override;
    function GetInvert: Boolean; override;
  public
    procedure Assign(Source: TPiece); override;
  published
    constructor Create;
    property Width: Integer read fWidth write fWidth;
    property Height: Integer read fHeight write fHeight;
    property DrawingFlags: Byte read fDrawingFlags write fDrawingFlags;
    property IsFake: Boolean read fFake write fFake;
    property Skill : Byte read fSkill write fSkill;
    property TarLev : Byte read fTarLev write fTarLev;
    property LastDrawX: Integer read fLastDrawX write fLastDrawX;
    property LastDrawY: Integer read fLastDrawY write fLastDrawY;
    property DrawAsZombie: Boolean read fDrawAsZombie write fDrawAsZombie;
  end;

type
  TInteractiveObjects = class(TObjectList)
    private
      function GetItem(Index: Integer): TInteractiveObject;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add(Item: TInteractiveObject): Integer; overload;
      function Add: TInteractiveObject; overload;
      procedure Insert(Index: Integer; Item: TInteractiveObject); overload;
      function Insert(Index: Integer): TInteractiveObject; overload;
      procedure Assign(aSrc: TInteractiveObjects);
      property Items[Index: Integer]: TInteractiveObject read GetItem; default;
      property List;
  end;

implementation


{ TInteractiveObjects }

constructor TInteractiveObjects.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TInteractiveObjects.Add(Item: TInteractiveObject): Integer;
begin
  Result := inherited Add(Item);
end;

function TInteractiveObjects.Add: TInteractiveObject;
begin
  Result := TInteractiveObject.Create;
  inherited Add(Result);
end;

procedure TInteractiveObjects.Insert(Index: Integer; Item: TInteractiveObject);
begin
  inherited Insert(Index, Item);
end;

function TInteractiveObjects.Insert(Index: Integer): TInteractiveObject;
begin
  Result := TInteractiveObject.Create;
  inherited Insert(Index, Result);
end;

procedure TInteractiveObjects.Assign(aSrc: TInteractiveObjects);
var
  i: Integer;
  Item: TInteractiveObject;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TInteractiveObjects.GetItem(Index: Integer): TInteractiveObject;
begin
  Result := inherited Get(Index);
end;


{ TInteractiveObject }

constructor TInteractiveObject.Create;
begin
  inherited;
  fWidth := -1;
  fHeight := -1;
end;

procedure TInteractiveObject.Assign(Source: TPiece);
var
  O: TInteractiveObject absolute Source;
begin
  if Source is TInteractiveObject then
  begin
    inherited;
    DrawingFlags := O.DrawingFlags;
    Width := O.Width;
    Height := O.Height;
    IsFake := O.IsFake;
    Skill := O.Skill;
    TarLev := O.TarLev;
    LastDrawX := O.LastDrawX;
    LastDrawY := O.LastDrawY;
    DrawAsZombie := O.DrawAsZombie;
    // some of these probably don't need to be copied really
  end;
end;

procedure TInteractiveObject.SetFlip(aValue: Boolean);
begin
  if aValue then
    DrawingFlags := DrawingFlags or odf_Flip
  else
    DrawingFlags := DrawingFlags and not odf_Flip;
end;

procedure TInteractiveObject.SetInvert(aValue: Boolean);
begin
    if aValue then
    DrawingFlags := DrawingFlags or odf_UpsideDown
  else
    DrawingFlags := DrawingFlags and not odf_UpsideDown;
end;

function TInteractiveObject.GetFlip: Boolean;
begin
  Result := (DrawingFlags and odf_Flip) <> 0;
end;

function TInteractiveObject.GetInvert: Boolean;
begin
  Result := (DrawingFlags and odf_UpsideDown) <> 0;
end;

end.

