{$include lem_directives.inc}
unit LemSteel;

(*--------------------------------------------------
    Steel areas only exist for loading old levels!
    This is ONLY for use in LemLVLLoader!
    DO NOT USE IT ANYWHERE ELSE!!!
  --------------------------------------------------*)

interface

uses
  Contnrs, Classes,
  LemPiece;

type
  TSteelClass = class of TSteel;
  TSteel = class(TSizedPiece)
  public
    fType : Byte;
  end;

type
  TSteels = class(TObjectList)
    private
      function GetItem(Index: Integer): TSteel;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add(Item: TSteel): Integer; overload;
      function Add: TSteel; overload;
      procedure Insert(Index: Integer; Item: TSteel); overload;
      function Insert(Index: Integer): TSteel; overload;
      procedure Assign(aSrc: TSteels);
      property Items[Index: Integer]: TSteel read GetItem; default;
      property List;
  end;

implementation

{ TSteels }

constructor TSteels.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TSteels.Add(Item: TSteel): Integer;
begin
  Result := inherited Add(Item);
end;

function TSteels.Add: TSteel;
begin
  Result := TSteel.Create;
  inherited Add(Result);
end;

procedure TSteels.Insert(Index: Integer; Item: TSteel);
begin
  inherited Insert(Index, Item);
end;

function TSteels.Insert(Index: Integer): TSteel;
begin
  Result := TSteel.Create;
  inherited Insert(Index, Result);
end;

procedure TSteels.Assign(aSrc: TSteels);
var
  i: Integer;
  Item: TSteel;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TSteels.GetItem(Index: Integer): TSteel;
begin
  Result := inherited Get(Index);
end;

end.

