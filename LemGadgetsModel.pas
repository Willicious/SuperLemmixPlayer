{$include lem_directives.inc}
unit LemGadgetsModel;

interface

uses
  Contnrs,
  Classes,
  LemCore,
  LemPiece;

const
  // Object Drawing Flags
  odf_OnlyOnTerrain = 1; // Bit 0
  odf_UpsideDown    = 2; // Bit 1
  odf_NoOverwrite   = 4; // Bit 2
  odf_FlipLem       = 8;
  //odf_Invisible     = 32;  // Removed
  //odf_Flip          = 64;  // Better name: odf_FlipImage
  odf_Rotate        = 128;

type
  TGadgetModel = class(TIdentifiedPiece)
  private
  protected
    fDrawingFlags: Byte; // N.B. odf_xxxx
    fSkill: Integer;
    fTarLev: Integer; { This saves the preassigned skills for hatches
                               and the speed of movable backgrounds.
                               and the skill amount for pick-up skills. }
    fLemmingCap: Integer;
    fCountdownLength: Integer;
    procedure SetInvert(aValue: Boolean); override;
    function GetInvert: Boolean; override;
  public
    procedure Assign(Source: TPiece); override;
  published
    constructor Create;
    property DrawingFlags: Byte read fDrawingFlags write fDrawingFlags;
    property Skill : Integer read fSkill write fSkill;
    property TarLev : Integer read fTarLev write fTarLev;
    property LemmingCap: Integer read fLemmingCap write fLemmingCap;
    property CountdownLength: Integer read fCountdownLength write fCountdownLength;
  end;

type
  TGadgetModelList = class(TObjectList)
    private
      function GetItem(Index: Integer): TGadgetModel;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add(Item: TGadgetModel): Integer; overload;
      function Add: TGadgetModel; overload;
      procedure Insert(Index: Integer; Item: TGadgetModel); overload;
      function Insert(Index: Integer): TGadgetModel; overload;
      procedure Assign(aSrc: TGadgetModelList);
      property Items[Index: Integer]: TGadgetModel read GetItem; default;
      property List;
  end;

implementation


{ TGadgetModelList }

constructor TGadgetModelList.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TGadgetModelList.Add(Item: TGadgetModel): Integer;
begin
  Result := inherited Add(Item);
end;

function TGadgetModelList.Add: TGadgetModel;
begin
  Result := TGadgetModel.Create;
  inherited Add(Result);
end;

procedure TGadgetModelList.Insert(Index: Integer; Item: TGadgetModel);
begin
  inherited Insert(Index, Item);
end;

function TGadgetModelList.Insert(Index: Integer): TGadgetModel;
begin
  Result := TGadgetModel.Create;
  inherited Insert(Index, Result);
end;

procedure TGadgetModelList.Assign(aSrc: TGadgetModelList);
var
  i: Integer;
  Item: TGadgetModel;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TGadgetModelList.GetItem(Index: Integer): TGadgetModel;
begin
  Result := inherited Get(Index);
end;


{ TGadgetModel }

constructor TGadgetModel.Create;
begin
  inherited;
  fWidth := -1;
  fHeight := -1;
end;

procedure TGadgetModel.Assign(Source: TPiece);
var
  O: TGadgetModel absolute Source;
begin
  if Source is TGadgetModel then
  begin
    inherited;
    DrawingFlags := O.DrawingFlags;
    Skill := O.Skill;
    TarLev := O.TarLev;
    LemmingCap := O.LemmingCap;
    CountdownLength := O.CountdownLength;
  end;
end;

procedure TGadgetModel.SetInvert(aValue: Boolean);
begin
  if aValue then
    DrawingFlags := DrawingFlags or odf_UpsideDown
  else
    DrawingFlags := DrawingFlags and not odf_UpsideDown;
end;

function TGadgetModel.GetInvert: Boolean;
begin
  Result := (DrawingFlags and odf_UpsideDown) <> 0;
end;

end.

