unit LemObjects;

interface

uses
  Windows, {Classes,} Contnrs, {SysUtils, Math, Forms, Dialogs,    }
  LemMetaObject, LemInteractiveObject;

type
  // internal object used by game
  TInteractiveObjectInfo = class
  private
    function GetBounds: TRect;
  public
    MetaObj        : TMetaObject;
    Obj            : TInteractiveObject;
    CurrentFrame   : Integer;
    Triggered      : Boolean;
    TeleLem        : Integer; // saves which lemming is currently teleported
    HoldActive     : Boolean;
    ZombieMode     : Boolean;
    TwoWayReceive  : Boolean;
    // OffsetX        : Integer;
    // OffsetY        : Integer;
    Left           : Integer; // these are NOT used directly from TInteractiveObjectInfo
    Top            : Integer; // They're only used to back it up in save states!
    // TotalFactor    : Integer; //faster way to handle the movement
    //SoundIndex     : Integer; // cached soundindex
    property Bounds: TRect read GetBounds;
  end;

  // internal list, used by game
  TInteractiveObjectInfoList = class(TObjectList)
  private
    function GetItem(Index: Integer): TInteractiveObjectInfo;
  protected
  public
    function Add(Item: TInteractiveObjectInfo): Integer;
    procedure Insert(Index: Integer; Item: TInteractiveObjectInfo);
    property Items[Index: Integer]: TInteractiveObjectInfo read GetItem; default;
  published
  end;


implementation


{ TInteractiveObjectInfo }

function TInteractiveObjectInfo.GetBounds: TRect;
begin
  Result.Left := Obj.Left;
  Result.Top := Obj.Top;
  Result.Right := Result.Left + MetaObj.Height;
  Result.Bottom := Result.Top + MetaObj.Width;
end;


{ TObjectAnimationInfoList }

function TInteractiveObjectInfoList.Add(Item: TInteractiveObjectInfo): Integer;
begin
  Result := inherited Add(Item);
end;

function TInteractiveObjectInfoList.GetItem(Index: Integer): TInteractiveObjectInfo;
begin
  Result := inherited Get(Index);
end;

procedure TInteractiveObjectInfoList.Insert(Index: Integer; Item: TInteractiveObjectInfo);
begin
  inherited Insert(Index, Item);
end;


end.
