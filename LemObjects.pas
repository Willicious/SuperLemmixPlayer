unit LemObjects;

interface

uses
  Windows, Contnrs, LemTypes, LemCore,
  LemMetaObject, LemInteractiveObject;

type
  // internal object used by game
  TInteractiveObjectInfo = class
  private
    sTop            : Integer;
    sLeft           : Integer;
    sHeight         : Integer;
    sWidth          : Integer;
    sTriggerRect    : TRect;  // We assume that trigger areas will never move!!!
    sTriggerEffect  : Integer;
    sIsDisabled     : Boolean;
    sReceiverId     : Integer;
    sPairingId      : Integer;
    sZombieMode     : Boolean;

    function GetTriggerRect: TRect;
    procedure SetIsDisabled(Value: Boolean);
    procedure SetLeft(Value: Integer);
    procedure SetTop(Value: Integer);
    procedure SetZombieMode(Value: Boolean);
    function GetSkillType: TSkillPanelButton;
    function GetSoundEffect: String;
    function GetIsOnlyOnTerrain: Boolean;
    function GetIsUpsideDown: Boolean;
    function GetIsNoOverwrite: Boolean;
    function GetIsFlipPhysics: Boolean;
    function GetIsInvisible: Boolean;
    function GetIsFlipImage: Boolean;
    function GetIsRotate: Boolean;
    function GetAnimationFrameCount: Integer;
    function GetPreassignedSkills: Integer;
    function GetCenterPoint: TPoint;
    function GetKeyFrame: Integer;

  public
    MetaObj        : TMetaObjectInterface;
    Obj            : TInteractiveObject;
    Frames         : TBitmaps;

    CurrentFrame   : Integer;
    Triggered      : Boolean;
    TeleLem        : Integer; // saves which lemming is currently teleported
    HoldActive     : Boolean;

    constructor Create(ObjParam: TInteractiveObject; MetaParam: TMetaObjectInterface); Overload;

    property TriggerRect: TRect read sTriggerRect;
    property Top: Integer read sTop write SetTop;
    property Left: Integer read sLeft write SetLeft;
    property Width: Integer read sWidth;
    property Height: Integer read sHeight;
    property Center: TPoint read GetCenterPoint;
    property TriggerEffect: Integer read sTriggerEffect;
    property IsDisabled: Boolean read sIsDisabled write SetIsDisabled;
    property ReceiverId: Integer read sReceiverId;
    property PairingId: Integer read sPairingId;  // Teleporters and receivers that are matched have same value; used for helper icons only (otherwise use ReceiverID)
    property SkillType: TSkillPanelButton read GetSkillType;
    property IsOnlyOnTerrain: Boolean read GetIsOnlyOnTerrain;  // ... and 1
    property IsUpsideDown: Boolean read GetIsUpsideDown;        // ... and 2
    property IsNoOverwrite: Boolean read GetIsNoOverwrite;      // ... and 4
    property IsFlipPhysics: Boolean read GetIsFlipPhysics;      // ... and 8
    property IsInvisible: Boolean read GetIsInvisible;          // ... and 32
    property IsFlipImage: Boolean read GetIsFlipImage;          // ... and 64
    property IsRotate: Boolean read GetIsRotate;                // ... and 128
    property AnimationFrameCount: Integer read GetAnimationFrameCount;
    property SoundEffect: String read GetSoundEffect;
    property PreassignedSkills: Integer read GetPreassignedSkills;
    property ZombieMode: Boolean read sZombieMode write SetZombieMode;
    property KeyFrame: Integer read GetKeyFrame;

    procedure AssignTo(NewObj: TInteractiveObjectInfo);

    // true = X-movement, false = Y-movement
    function Movement(Direction: Boolean; CurrentIteration: Integer): Integer;
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
    procedure FindReceiverID;
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
  DOM_BGIMAGE          = 32;
  DOM_ONEWAYUP         = 33; // let's NOT make this apparent to end-users; just use it internally

implementation


{ TInteractiveObjectInfo }
constructor TInteractiveObjectInfo.Create(ObjParam: TInteractiveObject; MetaParam: TMetaObjectInterface);

  procedure AdjustOWWDirection;
  var
    UseDir: Integer;
  const
    DIRS: array[0..3] of Integer = (DOM_ONEWAYLEFT, DOM_ONEWAYUP, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN);
  begin
    case sTriggerEffect of
      DOM_ONEWAYLEFT: UseDir := 0;
      DOM_ONEWAYUP: UseDir := 1;
      DOM_ONEWAYRIGHT: UseDir := 2;
      DOM_ONEWAYDOWN: UseDir := 3;
      else Exit;
    end;

    if Obj.Rotate then
      Inc(UseDir, 1);

    if Obj.Flip and (UseDir mod 2 = 0) then
      Inc(UseDir, 2);

    if Obj.Invert and (UseDir mod 2 = 1) then
      Inc(UseDir, 2);

    sTriggerEffect := DIRS[UseDir mod 4];
  end;
begin
  Obj := ObjParam;
  MetaObj := MetaParam;
  Frames := MetaObj.Images;

  // Legacy code for old hatches, that haven't set a proper trigger area
  if      (MetaObj.TriggerEffect = DOM_WINDOW)
     and ((MetaObj.TriggerTop = -4) or (MetaObj.TriggerTop = 0))
     and  (MetaObj.TriggerLeft = 0) then
  begin
    MetaObj.TriggerTop := 24;
    MetaObj.TriggerLeft := 13;
    MetaObj.TriggerHeight := 1;
    MetaObj.TriggerWidth := 1;
  end;

  // Set basic stuff
  sTop := Obj.Top;
  sLeft := Obj.Left;
  if (not MetaObj.CanResizeVertical) or (Obj.Height = -1) then
    Obj.Height := MetaObj.Height;
  sHeight := Obj.Height;
  if (not MetaObj.CanResizeHorizontal) or (Obj.Width = -1) then
    Obj.Width := MetaObj.Width;
  sWidth := Obj.Width;
  sTriggerEffect := MetaObj.TriggerEffect;
  AdjustOWWDirection; // adjusts eg. flipped OWL becomes OWR
  sTriggerRect := GetTriggerRect;
  sIsDisabled := Obj.IsFake;
  sReceiverId := 65535;

  // Set CurrentFrame
  if MetaObj.RandomStartFrame then
    CurrentFrame := ((Abs(sLeft) + 1) * (Abs(sTop) + 1) + (Obj.Skill + 1) * (Obj.TarLev + 1){ + i}) mod MetaObj.FrameCount
  else if MetaObj.TriggerEffect = DOM_PICKUP then
    CurrentFrame := Obj.Skill + 1
  else if MetaObj.TriggerEffect in [DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE] then
    CurrentFrame := 1
  else
    CurrentFrame := MetaObj.PreviewFrame;

  if (MetaObj.TriggerEffect = DOM_FLIPPER) then
    if ((Obj.DrawingFlags and odf_FlipLem) <> 0) then
      CurrentFrame := 1
    else
      CurrentFrame := 0;

  // Set OWW to Only-On-Terrain and remove No-Overwrite
  // from namida: Don't think this is nessecary anymore, OWWs are handled seperately during rendering so these properties would be ignored
  (*if MetaObj.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN] then
  begin
    Obj.DrawingFlags := Obj.DrawingFlags and not 4; // odf_NoOverwrite
    Obj.DrawingFlags := Obj.DrawingFlags or 1; // odf_OnlyOnTerrain
  end;*)


  // Set other stuff
  Triggered := False;
  TeleLem := -1; // Set to a value no lemming has (hopefully!)

  HoldActive := False;
  ZombieMode := False;

  // Remove TriggerEffect if object disabled
  // If it is a preplaced lemming, we unfortunately have to keep it (or this lemming will be drawn)
  //    from namida: Woudln't it be safer to apply the change, but set the Invisible flag?
  if sIsDisabled and not (TriggerEffect = DOM_LEMMING) then
    sTriggerEffect := DOM_NONE;

end;


function TInteractiveObjectInfo.GetTriggerRect: TRect;
// Note that the trigger area is only the inside of the TRect,
// which by definition does not include the right and bottom line!
var
  X, Y: Integer;
  W, H: Integer;
begin
  Y := Obj.Top; // of whole object
  X := Obj.Left;

  (*if IsFlipImage then
    X := X + (sWidth - 1) - MetaObj.TriggerLeft - (MetaObj.TriggerWidth - 1)
  else
    X := X + MetaObj.TriggerLeft;

  if IsUpsideDown then
  begin
    Y := Y + (sHeight - 1) - MetaObj.TriggerTop - (MetaObj.TriggerHeight - 1);
    if not (MetaObj.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_STEEL, DOM_ONEWAYDOWN]) then
      Y := Y + 9;
  end else
    Y := Y + MetaObj.TriggerTop;*)

  // TMetaObject itself takes care of this now, and TMetaObjectInterface hides needing to specify
  // the flip / etc every time.

  X := X + MetaObj.TriggerLeft;
  Y := Y + MetaObj.TriggerTop;
  W := MetaObj.TriggerWidth;
  H := MetaObj.TriggerHeight;

  if MetaObj.CanResizeHorizontal then
    W := W + (sWidth - MetaObj.Width);

  if MetaObj.CanResizeVertical then
    H := H + (sHeight - MetaObj.Height);

  Result.Top := Y;
  Result.Bottom := Y + H;
  Result.Left := X;
  Result.Right := X + W;
end;

procedure TInteractiveObjectInfo.SetIsDisabled(Value: Boolean);
begin
  Assert(Value = True, 'Changing object from Disabled to Enabled impossible'); // do we really want this? we might want this to be possible in the future...

  sIsDisabled := Value;
  sTriggerEffect := DOM_NONE;
end;

procedure TInteractiveObjectInfo.SetLeft(Value: Integer);
begin
  sLeft := Value;
  Obj.Left := Value;
end;

procedure TInteractiveObjectInfo.SetTop(Value: Integer);
begin
  sTop := Value;
  Obj.Top := Value;
end;

procedure TInteractiveObjectInfo.SetZombieMode(Value: Boolean);
begin
  sZombieMode := Value;
  Obj.DrawAsZombie := Value;
end;

function TInteractiveObjectInfo.GetSkillType: TSkillPanelButton;
begin
  Assert(TriggerEffect = DOM_PICKUP, 'Object.SkillType called for non-PickUp skill');
  Result := TSkillPanelButton(Obj.Skill);
end;

function TInteractiveObjectInfo.GetSoundEffect: String;
begin
  Result := MetaObj.SoundEffect;
end;

function TInteractiveObjectInfo.GetIsOnlyOnTerrain: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_OnlyOnTerrain) <> 0);
end;

function TInteractiveObjectInfo.GetIsUpsideDown: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_UpsideDown) <> 0);
end;

function TInteractiveObjectInfo.GetIsNoOverwrite: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_NoOverwrite) <> 0);
end;

function TInteractiveObjectInfo.GetIsFlipPhysics: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_FlipLem) <> 0);
end;

function TInteractiveObjectInfo.GetIsInvisible: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_Invisible) <> 0);
end;

function TInteractiveObjectInfo.GetIsFlipImage: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_Flip) <> 0);
end;

function TInteractiveObjectInfo.GetIsRotate: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_Rotate) <> 0);
end;

function TInteractiveObjectInfo.GetAnimationFrameCount: Integer;
begin
  Result := MetaObj.FrameCount;
end;

function TInteractiveObjectInfo.GetPreassignedSkills: Integer;
begin
  // Only call this function for hatches and preplaces lemmings
  Assert(TriggerEffect in [DOM_WINDOW, DOM_LEMMING], 'Preassigned skill called for object not a hatch or a preplaced lemming');
  Result := Obj.TarLev; // Yes, "TargetLevel" stores this info!
end;

function TInteractiveObjectInfo.GetCenterPoint: TPoint;
begin
  Result.X := sLeft + (sWidth div 2);
  Result.Y := sTop + (sHeight div 2);
end;

function TInteractiveObjectInfo.GetKeyFrame: Integer;
begin
  Result := MetaObj.KeyFrame;
end;

function TInteractiveObjectInfo.Movement(Direction: Boolean; CurrentIteration: Integer): Integer;
var
  f: Integer;
const
  AnimObjMov: array[0..15] of Integer =
    (0, 1, 2, 2, 2, 2, 2, 1, 0, -1, -2, -2, -2, -2, -2, -1);

  function GetDistanceFactor(Speed: Integer; Iter: Integer): Integer;
  begin
    Result := ((2 * Speed * (Iter + 1)) div 17) - ((2 * Speed * Iter) div 17)
  end;
begin
  f := GetDistanceFactor(Obj.TarLev, CurrentIteration);

  if Direction then
    Result := (AnimObjMov[Obj.Skill] * f) div 2
  else
    Result := (AnimObjMov[(Obj.Skill + 12) mod 16] * f) div 2;
end;

procedure TInteractiveObjectInfo.AssignTo(NewObj: TInteractiveObjectInfo);
begin
  NewObj.sTop := sTop;
  NewObj.sLeft := sLeft;
  NewObj.sHeight := sHeight;
  NewObj.sWidth := sWidth;
  NewObj.sTriggerRect := sTriggerRect;
  NewObj.sTriggerEffect := sTriggerEffect;
  NewObj.sIsDisabled := sIsDisabled;
  NewObj.MetaObj := MetaObj;
  NewObj.Obj := Obj;
  NewObj.CurrentFrame := CurrentFrame;
  NewObj.Triggered := Triggered;
  NewObj.TeleLem := TeleLem;
  NewObj.HoldActive := HoldActive;
  NewObj.ZombieMode := ZombieMode;
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

procedure TInteractiveObjectInfoList.FindReceiverID;
var
  i, TestId: Integer;
  Inf, TestInf: TInteractiveObjectInfo;
  PairCount: Integer;
  IsReceiverUsed: array of Boolean;
begin
  PairCount := 0;
  SetLength(IsReceiverUsed, Count);
  for i := 0 to Count-1 do
  begin
    IsReceiverUsed[i] := false;
    Items[i].sPairingId := -1;
  end;

  for i := 0 to Count - 1 do
  begin
    Inf := List^[i];
    if Inf.TriggerEffect = DOM_TELEPORT then
    begin
      // Find receiver for this teleporter with index i
      TestID := i;
      repeat
        Inc(TestID);
        TestInf := List^[TestId mod Count];
      until ((TestInf.TriggerEffect = DOM_RECEIVER) and (TestInf.Obj.Skill = Inf.Obj.Skill))
            or (TestID = i + Count);

      TestID := TestID mod Count;
      // If TestID = i then there is no receiver and we disable the teleporter
      if i = TestID then
        Inf.IsDisabled := True
      else begin
        Inf.sReceiverId := TestID;
        if IsReceiverUsed[TestID] then
          Inf.sPairingId := TestInf.sPairingId
        else begin
          Inf.sPairingId := PairCount;
          TestInf.sPairingId := PairCount;
          IsReceiverUsed[TestID] := true;
          Inc(PairCount);
        end;
      end;
    end; // end test whether object is teleporter
  end; // next i
end;


end.
