unit LemObjects;

interface

uses
  Windows, {Classes,} Contnrs, {SysUtils, Math, Forms, Dialogs,}
  LemMetaObject, LemInteractiveObject;

type
  // internal object used by game
  TInteractiveObjectInfo = class
  private
    sTop            : Integer;
    sLeft           : Integer;
    sHeight         : Integer;
    sWidth          : Integer;
    sTriggerRect    : TRect;

    function GetTriggerRect(): TRect;


  public
    MetaObj        : TMetaObject;
    Obj            : TInteractiveObject;

    CurrentFrame   : Integer;
    Triggered      : Boolean;
    TeleLem        : Integer; // saves which lemming is currently teleported
    HoldActive     : Boolean;
    ZombieMode     : Boolean;
    TwoWayReceive  : Boolean;

    constructor Create(ObjParam: TInteractiveObject; MetaObjParam: TMetaObject);

    property TriggerRect: TRect read sTriggerRect;
    property Top: Integer read sTop write sTop;
    property Left: Integer read sLeft write sLeft;
    property Width: Integer read sWidth;
    property Height: Integer read sHeight;
  end;

type
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

const
  DOM_NOOBJECT         = 65535;
  DOM_NONE             = 0;
  DOM_EXIT             = 1;
  DOM_FORCELEFT        = 2; // left arm of blocker
  DOM_FORCERIGHT       = 3; // right arm of blocker
  DOM_TRAP             = 4; // triggered trap
  DOM_WATER            = 5; // causes drowning
  DOM_FIRE             = 6; // causes vaporizing
  DOM_ONEWAYLEFT       = 7;
  DOM_ONEWAYRIGHT      = 8;
  DOM_STEEL            = 9;
  DOM_BLOCKER          = 10; // the middle part of blocker
  DOM_TELEPORT         = 11;
  DOM_RECEIVER         = 12;
  DOM_LEMMING          = 13;
  DOM_PICKUP           = 14;
  DOM_LOCKEXIT         = 15;
  //DOM_SECRET           = 16;
  DOM_BUTTON           = 17;
  DOM_RADIATION        = 18;
  DOM_ONEWAYDOWN       = 19;
  DOM_UPDRAFT          = 20;
  DOM_FLIPPER          = 21;
  DOM_SLOWFREEZE       = 22;
  DOM_WINDOW           = 23;
  DOM_ANIMATION        = 24;
  DOM_HINT             = 25;
  DOM_NOSPLAT          = 26;
  DOM_SPLAT            = 27;
  DOM_TWOWAYTELE       = 28;
  DOM_SINGLETELE       = 29;
  DOM_BACKGROUND       = 30;
  DOM_TRAPONCE         = 31;


implementation

{ TInteractiveObjectInfo }
constructor TInteractiveObjectInfo.Create(ObjParam: TInteractiveObject;
                                          MetaObjParam: TMetaObject);
begin
  Obj := ObjParam;
  MetaObj := MetaObjParam; // fGameParams.GraphicSet.MetaObjects[ObjParam.Identifier];

  // Set basic stuff
  sTop := Obj.Top;
  sLeft := Obj.Left;
  sHeight := MetaObj.Height;
  sWidth := MetaObj.Width;
  sTriggerRect := GetTriggerRect;

  // Set CurrentFrame
  if MetaObj.RandomStartFrame then
    CurrentFrame := ((Abs(sLeft) + 1) * (Abs(sTop) + 1) + (Obj.Skill + 1) * (Obj.TarLev + 1){ + i}) mod MetaObj.AnimationFrameCount
  else if MetaObj.TriggerEffect = DOM_PICKUP then
    CurrentFrame := ObjParam.Skill + 1
  else if MetaObj.TriggerEffect in [DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE] then
    CurrentFrame := 1
  else
    CurrentFrame := MetaObj.PreviewFrameIndex;

  if (MetaObj.TriggerEffect = DOM_FLIPPER) then
    if ((ObjParam.DrawingFlags and odf_FlipLem) <> 0) then
      CurrentFrame := 1
    else
      CurrentFrame := 0;

  // Set other stuff
  Triggered := False;
  TeleLem := -1; // Set to a value no lemming has (hopefully!)

  HoldActive := False;
  ZombieMode := False;
  TwoWayReceive := False;

end;


function TInteractiveObjectInfo.GetTriggerRect(): TRect;
// Note that the trigger area is only the inside of the TRect,
// which by definition does not include the right and bottom line!
var
  X, Y: Integer;
begin
  Y := Obj.Top; // of whole object
  X := Obj.Left;

  if (Obj.DrawingFlags and odf_Flip) <> 0 then
    X := X + (MetaObj.Width - 1) - MetaObj.TriggerLeft - (MetaObj.TriggerWidth - 1)
  else
    X := X + MetaObj.TriggerLeft;

  if (Obj.DrawingFlags and odf_UpsideDown) <> 0 then
  begin
    Y := Y + (MetaObj.Height - 1) - MetaObj.TriggerTop - (MetaObj.TriggerHeight - 1);
    if not (MetaObj.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_STEEL, DOM_ONEWAYDOWN]) then
      Y := Y + 9;
  end else
    Y := Y + MetaObj.TriggerTop;

  Result.Top := Y;
  Result.Bottom := Y + MetaObj.TriggerHeight;
  Result.Left := X;
  Result.Right := X + MetaObj.TriggerWidth;
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
