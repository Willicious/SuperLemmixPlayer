{$include lem_directives.inc}
unit LemGadgets;

interface

uses
  Math, Classes, GR32,
  Windows, Contnrs, LemTypes, LemCore,
  LemGadgetsMeta, LemGadgetsModel,
  LemGadgetAnimation,
  Generics.Collections;

type
  TGadget = class;

  TGadgetAnimationInstance = class
    private
      fGadget: TGadget;
      fAnimation: TGadgetAnimation;
      fFrame: Integer;
      fState: TGadgetAnimationState;
      fVisible: Boolean;
      fPrimary: Boolean;

      function GetBitmap: TBitmap32;
    public
      constructor Create(aGadget: TGadget; aAnimation: String);
      function UpdateOneFrame: Boolean; // if returns false, the object PERMANENTLY removes the animation. Futureproofing.
      procedure ProcessTriggers;

      procedure Clone(aSrc: TGadgetAnimationInstance);

      property MetaAnimation: TGadgetAnimation read fAnimation;
      property Bitmap: TBitmap32 read GetBitmap;
      property Primary: Boolean read fPrimary;
      property Frame: Integer read fFrame write fFrame;
      property Visible: Boolean read fVisible;
      property State: TGadgetAnimationState read fState;
  end;

  TGadgetAnimationInstances = class(TObjectList<TGadgetAnimationInstance>)
    private
      fPrimaryAnimation: TGadgetAnimationInstance;
      function GetPrimaryAnimation: TGadgetAnimationInstance;
    public
      procedure Clone(aSrc: TGadgetAnimationInstances; newObj: TGadget);
      property PrimaryAnimation: TGadgetAnimationInstance read GetPrimaryAnimation;
  end;

  // internal object used by game
  TGadget = class
  private
    sTop            : Integer;
    sLeft           : Integer;
    sHeight         : Integer;
    sWidth          : Integer;

    sWidthVariance  : Integer; // difference from default. used by secondary animations.
    sHeightVariance : Integer;

    sTriggerRect    : TRect;  // We assume that trigger areas will never move!!!
    sTriggerEffect  : Integer;
    sReceiverId     : Integer;
    sPairingId      : Integer;
    sZombieMode     : Boolean;
    sSecondariesTreatAsBusy: Boolean;

    Obj            : TGadgetModel;

    procedure CreateAnimationInstances;

    function GetTriggerRect: TRect;
    procedure SetLeft(Value: Integer);
    procedure SetTop(Value: Integer);
    procedure SetZombieMode(Value: Boolean);
    function GetSkillType: TSkillPanelButton;
    function GetSoundEffect: String;
    function GetIsOnlyOnTerrain: Boolean;
    function GetIsUpsideDown: Boolean;
    function GetIsNoOverwrite: Boolean;
    function GetIsFlipPhysics: Boolean;
    function GetIsFlipImage: Boolean;
    function GetIsRotate: Boolean;
    function GetAnimationFrameCount: Integer;
    function GetPreassignedSkill(BitField: Integer): Boolean;
    function GetHasPreassignedSkills: Boolean;
    function GetCenterPoint: TPoint;
    function GetKeyFrame: Integer;
    function GetCanDrawToBackground: Boolean;
    function GetSpeed: Integer;
    function GetSkillCount: Integer;
    function GetTriggerEffectBase: Integer;

    function GetCurrentFrame: Integer; // Just remaps to primary animation. This allows LemGame to control
    procedure SetCurrentFrame(aValue: Integer); // the primary animation directly, as it always has.

    function GetAnimFlagState(aFlag: TGadgetAnimationTriggerCondition): Boolean;
  public
    MetaObj        : TGadgetMetaAccessor;

    Animations: TGadgetAnimationInstances;

    Triggered      : Boolean;
    TeleLem        : Integer; // saves which lemming is currently teleported
    HoldActive     : Boolean;

    constructor Create; overload;
    constructor Create(ObjParam: TGadgetModel; MetaParam: TGadgetMetaAccessor); overload;
    constructor Create(Template: TGadget); overload;

    destructor Destroy; override;
    function Clone: TGadget;

    property TriggerRect: TRect read sTriggerRect;
    property CurrentFrame: Integer read GetCurrentFrame write SetCurrentFrame;
    property Top: Integer read sTop write SetTop;
    property Left: Integer read sLeft write SetLeft;
    property Width: Integer read sWidth;
    property Height: Integer read sHeight;
    property WidthVariance: Integer read sWidthVariance;
    property HeightVariance: Integer read sHeightVariance;
    property Center: TPoint read GetCenterPoint;
    property TriggerEffect: Integer read sTriggerEffect write sTriggerEffect;
    property ReceiverId: Integer read sReceiverId;
    property PairingId: Integer read sPairingId;  // Teleporters and receivers that are matched have same value; used for helper icons only (otherwise use ReceiverID)
    property SkillType: TSkillPanelButton read GetSkillType;
    property IsOnlyOnTerrain: Boolean read GetIsOnlyOnTerrain;  // ... and 1
    property IsUpsideDown: Boolean read GetIsUpsideDown;        // ... and 2
    property IsNoOverwrite: Boolean read GetIsNoOverwrite;      // ... and 4
    property IsFlipPhysics: Boolean read GetIsFlipPhysics;      // ... and 8
    property IsFlipImage: Boolean read GetIsFlipImage;          // ... and 64
    property IsRotate: Boolean read GetIsRotate;                // ... and 128
    property AnimationFrameCount: Integer read GetAnimationFrameCount;
    property SoundEffect: String read GetSoundEffect;
    property ZombieMode: Boolean read sZombieMode write SetZombieMode;
    property KeyFrame: Integer read GetKeyFrame;
    property CanDrawToBackground: Boolean read GetCanDrawToBackground; // moving backgrounds: if only one frame and zero speed, this returns true
    property Speed: Integer read GetSpeed;
    property SkillCount: Integer read GetSkillCount;
    property IsPreassignedClimber: Boolean index 1 read GetPreassignedSkill;
    property IsPreassignedSwimmer: Boolean index 2 read GetPreassignedSkill;
    property IsPreassignedFloater: Boolean index 4 read GetPreassignedSkill;
    property IsPreassignedGlider: Boolean index 8 read GetPreassignedSkill;
    property IsPreassignedDisarmer: Boolean index 16 read GetPreassignedSkill;
    property IsPreassignedZombie: Boolean index 64 read GetPreassignedSkill;
    property HasPreassignedSkills: Boolean read GetHasPreassignedSkills;
    property TriggerEffectBase: Integer read GetTriggerEffectBase;
    property SecondariesTreatAsBusy: Boolean read sSecondariesTreatAsBusy write sSecondariesTreatAsBusy;

    property AnimationFlag[Flag: TGadgetAnimationTriggerCondition]: Boolean read GetAnimFlagState;

    procedure AssignTo(NewObj: TGadget);
    procedure UnifyFlippingFlagsOfTeleporter();
    procedure SetFlipOfReceiverTo(Teleporter: TGadget);

    // true = X-movement, false = Y-movement
    function Movement(Direction: Boolean; CurrentIteration: Integer): Integer;
  end;

type
  // internal list, used by game
  TGadgetList = class(TObjectList)
  private
    function GetItem(Index: Integer): TGadget;
  protected
  public
    function Add(Item: TGadget): Integer;
    procedure Insert(Index: Integer; Item: TGadget);
    procedure FindReceiverID;
    property Items[Index: Integer]: TGadget read GetItem; default;
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
  DOM_SKETCH           = 16; // replaces DOM_SECRET, shouldn't be in LVL files, and gets hidden if it is
  DOM_BUTTON           = 17;
  //DOM_RADIATION        = 18;
  DOM_ONEWAYDOWN       = 19;
  DOM_UPDRAFT          = 20;
  DOM_FLIPPER          = 21;
  //DOM_SLOWFREEZE       = 22;
  DOM_WINDOW           = 23;
  //DOM_ANIMATION        = 24;
  DOM_HINT             = 25;
  //DOM_NOSPLAT          = 26;
  DOM_SPLAT            = 27;
  //DOM_TWOWAYTELE       = 28;
  //DOM_SINGLETELE       = 29;
  DOM_BACKGROUND       = 30;
  DOM_TRAPONCE         = 31;
  //DOM_BGIMAGE          = 32;
  DOM_ONEWAYUP         = 33;

implementation

{ TGadget }
constructor TGadget.Create;
begin
  inherited;
  Animations := TGadgetAnimationInstances.Create;
end;

constructor TGadget.Create(ObjParam: TGadgetModel; MetaParam: TGadgetMetaAccessor);

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

    if IsRotate then
      Inc(UseDir, 1);

    if IsFlipImage and (UseDir mod 2 = 0) then
      Inc(UseDir, 2);

    if IsUpsideDown and (UseDir mod 2 = 1) then
      Inc(UseDir, 2);

    sTriggerEffect := DIRS[UseDir mod 4];
  end;
begin
  Create;

  Obj := ObjParam;
  MetaObj := MetaParam;

  CreateAnimationInstances;

  // Set basic stuff
  sTop := Obj.Top;
  sLeft := Obj.Left;
  if (not MetaObj.CanResizeVertical) or (Obj.Height < 1) then
    Obj.Height := MetaObj.Height;
  sHeight := Obj.Height;
  if (not MetaObj.CanResizeHorizontal) or (Obj.Width < 1) then
    Obj.Width := MetaObj.Width;
  sWidth := Obj.Width;

  sWidthVariance := sWidth - MetaObj.Width;
  sHeightVariance := sHeight - MetaObj.Height;

  sTriggerEffect := MetaObj.TriggerEffect;
  AdjustOWWDirection; // adjusts eg. flipped OWL becomes OWR
  sTriggerRect := GetTriggerRect;
  sReceiverId := 65535;

  // Set other stuff
  Triggered := False;
  TeleLem := -1; // Set to a value no lemming has (hopefully!)

  HoldActive := False;
  ZombieMode := False;
end;

procedure TGadget.CreateAnimationInstances;
var
  NewInstance: TGadgetAnimationInstance;
  i: Integer;
begin
  for i := 0 to MetaObj.Animations.Count-1 do
  begin
    NewInstance := TGadgetAnimationInstance.Create(self, MetaObj.Animations.Items[i].Name);
    Animations.Add(NewInstance);
  end;
end;

destructor TGadget.Destroy;
begin
  Animations.Free;
  inherited;
end;

function TGadget.Clone: TGadget;
begin
  Result := TGadget.Create(Obj, MetaObj);
  // doesn't clone state
end;

function TGadget.GetTriggerRect: TRect;
// Note that the trigger area is only the inside of the TRect,
// which by definition does not include the right and bottom line!
var
  X, Y: Integer;
  W, H: Integer;
begin
  Y := Obj.Top; // of whole object
  X := Obj.Left;

  X := X + MetaObj.TriggerLeft;
  Y := Y + MetaObj.TriggerTop;
  W := MetaObj.TriggerWidth;
  H := MetaObj.TriggerHeight;

  if MetaObj.CanResizeHorizontal then
    W := W + (sWidth - MetaObj.Width);

  if MetaObj.CanResizeVertical then
    H := H + (sHeight - MetaObj.Height);

  if MetaObj.TriggerEffect = DOM_RECEIVER then
    if (W > 1) or (H > 1) then
    begin
      X := X + (W div 2);
      Y := Obj.Top + Min(Height, MetaObj.TriggerTop + H - 1);
      W := 1;
      H := 1;
    end else begin
      W := 1;
      H := 1;
      // for cases where these are zero
    end;

  Result.Top := Y;
  Result.Bottom := Y + H;
  Result.Left := X;
  Result.Right := X + W;
end;

procedure TGadget.SetLeft(Value: Integer);
begin
  sLeft := Value;
  Obj.Left := Value;
end;

procedure TGadget.SetTop(Value: Integer);
begin
  sTop := Value;
  Obj.Top := Value;
end;

procedure TGadget.SetZombieMode(Value: Boolean);
begin
  sZombieMode := Value;
  Obj.DrawAsZombie := Value;
end;

function TGadget.GetSkillType: TSkillPanelButton;
begin
  Assert(TriggerEffect = DOM_PICKUP, 'Object.SkillType called for non-PickUp skill');
  Result := TSkillPanelButton(Obj.Skill);
end;

function TGadget.GetSoundEffect: String;
begin
  Result := MetaObj.SoundEffect;
end;

function TGadget.GetIsOnlyOnTerrain: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_OnlyOnTerrain) <> 0);
end;

function TGadget.GetIsUpsideDown: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_UpsideDown) <> 0);
end;

function TGadget.GetIsNoOverwrite: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_NoOverwrite) <> 0);
end;

function TGadget.GetIsFlipPhysics: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_FlipLem) <> 0);
end;

function TGadget.GetIsFlipImage: Boolean;
begin
  if (TriggerEffect = DOM_FLIPPER) then
    Result := (CurrentFrame = 1)
  else
    Result := ((Obj.DrawingFlags and odf_FlipLem) <> 0)
          and (TriggerEffect <> DOM_WINDOW);
end;

function TGadget.GetIsRotate: Boolean;
begin
  Result := ((Obj.DrawingFlags and odf_Rotate) <> 0);
end;

function TGadget.GetAnimationFrameCount: Integer;
begin
  Result := MetaObj.FrameCount;
end;

function TGadget.GetAnimFlagState(aFlag: TGadgetAnimationTriggerCondition): Boolean;
const
  FRAME_ZERO_OBJECTS = [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_PICKUP, DOM_LOCKEXIT, DOM_BUTTON, DOM_FLIPPER, DOM_WINDOW, DOM_TRAPONCE];
  FRAME_ONE_OBJECTS = [DOM_PICKUP {hardcoded}, DOM_LOCKEXIT, DOM_BUTTON, DOM_FLIPPER, DOM_WINDOW, DOM_TRAPONCE];
  BUSY_OBJECTS = [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_TRAPONCE];
  TRIGGERED_OBJECTS = [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_LOCKEXIT, DOM_WINDOW, DOM_TRAPONCE];
  DISABLED_OBJECTS = [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_TRAPONCE];
begin
  Result := false;
  case aFlag of
    gatcFrameZero: if MetaObj.TriggerEffect in FRAME_ZERO_OBJECTS then
                     Result := Animations.PrimaryAnimation.Frame = 0;
    gatcFrameOne: if MetaObj.TriggerEffect = DOM_PICKUP then
                    Result := Animations.PrimaryAnimation.Frame <> 0
                  else if MetaObj.TriggerEffect in FRAME_ONE_OBJECTS then
                    Result := Animations.PrimaryAnimation.Frame = 1;
    gatcBusy: if MetaObj.TriggerEffect in BUSY_OBJECTS then
                Result := Triggered or SecondariesTreatAsBusy;
    gatcTriggered: if MetaObj.TriggerEffect in TRIGGERED_OBJECTS then
                     Result := Triggered;
    gatcDisabled: if MetaObj.TriggerEffect in DISABLED_OBJECTS then
                    Result := TriggerEffect = DOM_NONE;
  end;
end;

function TGadget.GetPreassignedSkill(BitField: Integer): Boolean;
begin
  // Only call this function for hatches and preplaced lemmings
  Assert(MetaObj.TriggerEffect in [DOM_WINDOW, DOM_LEMMING], 'Preassigned skill called for object not a hatch or a preplaced lemming');
  Result := (Obj.TarLev and BitField) <> 0; // Yes, "TargetLevel" stores this info!
end;

function TGadget.GetHasPreassignedSkills: Boolean;
begin
  Assert(MetaObj.TriggerEffect in [DOM_WINDOW, DOM_LEMMING], 'Preassigned skill called for object not a hatch or a preplaced lemming');
  Result := Obj.TarLev <> 0; // Yes, "TargetLevel" stores this info!
end;

function TGadget.GetCenterPoint: TPoint;
begin
  Result.X := sLeft + (sWidth div 2);
  Result.Y := sTop + (sHeight div 2);
end;

function TGadget.GetCurrentFrame: Integer;
begin
  Result := Animations.PrimaryAnimation.Frame;
end;

function TGadget.GetKeyFrame: Integer;
begin
  Result := MetaObj.KeyFrame;
end;

function TGadget.Movement(Direction: Boolean; CurrentIteration: Integer): Integer;
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
  f := GetDistanceFactor(GetSpeed, CurrentIteration);

  if Direction then
    Result := (AnimObjMov[Obj.Skill] * f) div 2
  else
    Result := (AnimObjMov[(Obj.Skill + 12) mod 16] * f) div 2;
end;

function TGadget.GetCanDrawToBackground: Boolean;
var
  i: Integer;
begin
  Assert(MetaObj.TriggerEffect = DOM_BACKGROUND, 'GetCanDrawToBackground called for an object that isn''t a moving background!');
  Result := false;
  if GetSpeed <> 0 then Exit;
  for i := 0 to MetaObj.Animations.Count-1 do
    if MetaObj.Animations.Items[i].FrameCount > 1 then
      Exit;

  Result := true;
end;

function TGadget.GetSpeed: Integer;
begin
  Assert(MetaObj.TriggerEffect = DOM_BACKGROUND, 'GetSpeed called for an object that isn''t a moving background!');
  Result := Obj.TarLev;
end;

function TGadget.GetSkillCount: Integer;
begin
  Assert(MetaObj.TriggerEffect = DOM_PICKUP, 'GetSkillCount called for an object that isn''t a pick-up skill!');
  Result := Obj.TarLev;
end;


function TGadget.GetTriggerEffectBase: Integer;
begin
  Result := MetaObj.TriggerEffect;
end;

procedure TGadget.AssignTo(NewObj: TGadget);
begin
  NewObj.MetaObj := MetaObj;
  NewObj.Animations.Clone(Animations, NewObj);

  NewObj.sTop := sTop;
  NewObj.sLeft := sLeft;
  NewObj.sHeight := sHeight;
  NewObj.sWidth := sWidth;
  NewObj.sTriggerRect := sTriggerRect;
  NewObj.sTriggerEffect := sTriggerEffect;
  NewObj.MetaObj := MetaObj;
  NewObj.Obj := Obj;
  NewObj.Triggered := Triggered;
  NewObj.TeleLem := TeleLem;
  NewObj.HoldActive := HoldActive;
  NewObj.ZombieMode := ZombieMode;
end;

procedure TGadget.UnifyFlippingFlagsOfTeleporter();
begin
  Assert(MetaObj.TriggerEffect = DOM_TELEPORT, 'UnifyFlippingFlagsOfTeleporter called for object that isn''t a teleporter!');
  if IsFlipPhysics then
    Obj.DrawingFlags := Obj.DrawingFlags or odf_FlipLem
  else
    Obj.DrawingFlags := Obj.DrawingFlags and not odf_FlipLem;
end;


procedure TGadget.SetCurrentFrame(aValue: Integer);
begin
  Animations.PrimaryAnimation.Frame := aValue;
end;

procedure TGadget.SetFlipOfReceiverTo(Teleporter: TGadget);
begin
  Assert(Teleporter.MetaObj.TriggerEffect = DOM_TELEPORT, 'SetFlipOfReceiverTo with an argument that isn''t a teleporter!');
  Assert(MetaObj.TriggerEffect = DOM_RECEIVER, 'SetFlipOfReceiverTo called for an object that isn''t a receiver!');
  Assert(Teleporter.IsFlipImage = Teleporter.IsFlipPhysics, 'Teleporter in SetFlipOfReceiverTo has diverging flipping image and flipping physics!');
  if Teleporter.IsFlipImage then
    Obj.DrawingFlags := Obj.DrawingFlags or odf_FlipLem
  else
    Obj.DrawingFlags := Obj.DrawingFlags and not odf_FlipLem;
end;


constructor TGadget.Create(Template: TGadget);
begin
  Create(Template.Obj, Template.MetaObj);
end;

{ TGadgetList }

function TGadgetList.Add(Item: TGadget): Integer;
begin
  Result := inherited Add(Item);
end;

function TGadgetList.GetItem(Index: Integer): TGadget;
begin
  Result := inherited Get(Index);
end;

procedure TGadgetList.Insert(Index: Integer; Item: TGadget);
begin
  inherited Insert(Index, Item);
end;

procedure TGadgetList.FindReceiverID;
var
  i, TestId: Integer;
  Gadget, TestGadget: TGadget;
  ItemCount, PairCount: Integer;
  IsReceiverUsed: array of Boolean;
begin
  PairCount := 0;
  ItemCount := Count;
  SetLength(IsReceiverUsed, ItemCount);
  for i := 0 to ItemCount - 1 do
  begin
    IsReceiverUsed[i] := false;
    Items[i].sPairingId := -1;
  end;

  for i := 0 to ItemCount - 1 do
  begin
    Gadget := Items[i];
    if Gadget.TriggerEffect = DOM_TELEPORT then
    begin
      // Find receiver for this teleporter with index i
      TestID := i;
      repeat
        Inc(TestID);
        TestGadget := List[TestId mod ItemCount];
      until ((TestGadget.TriggerEffect = DOM_RECEIVER) and (TestGadget.Obj.Skill = Gadget.Obj.Skill))
            or (TestID = i + ItemCount);

      TestID := TestID mod ItemCount;
      if i = TestID then
        // If TestID = i then there is no receiver and we disable the teleporter
        Gadget.TriggerEffect := DOM_NONE
      else begin
        Gadget.sReceiverId := TestID;
        if IsReceiverUsed[TestID] then
        begin
          // Clone the receiver, if it is used by more than one teleporter
          TestGadget := TestGadget.Clone;
          Add(TestGadget); // to this GadgetList
          Gadget.sReceiverId := Count - 1; // set to newly added receiver
        end;
        Gadget.sPairingId := PairCount;
        TestGadget.sPairingId := PairCount;
        IsReceiverUsed[TestID] := true; // ignore newly added receivers for this
        Inc(PairCount);
        // Flip receiver according to teleporter
        Gadget.UnifyFlippingFlagsOfTeleporter();
        TestGadget.SetFlipOfReceiverTo(Gadget);
      end;
    end; // end test whether object is teleporter
  end; // next gadget

  for i := 0 to ItemCount - 1 do
    if (Items[i].TriggerEffect = DOM_RECEIVER) and not IsReceiverUsed[i] then
      Items[i].TriggerEffect := DOM_NONE // set to no-effect as a means of disabling if
end;

{ TGadgetAnimationInstance }

procedure TGadgetAnimationInstance.Clone(aSrc: TGadgetAnimationInstance);
begin
  fFrame := aSrc.fFrame;
  fState := aSrc.fState;
  fVisible := aSrc.fVisible;
  fPrimary := aSrc.fPrimary;
end;

constructor TGadgetAnimationInstance.Create(aGadget: TGadget;
  aAnimation: String);
var
  MetaObj: TGadgetMetaAccessor;
begin
  inherited Create;
  fGadget := aGadget;
  fAnimation := aGadget.MetaObj.Animations[aAnimation];

  if fAnimation.StartFrameIndex < 0 then
    fFrame := Random(fAnimation.FrameCount)
  else if fAnimation.StartFrameIndex < fAnimation.FrameCount then
    fFrame := fAnimation.StartFrameIndex
  else
    fFrame := 0;

  if fAnimation.Primary then
  begin
    fPrimary := true;

    MetaObj := aGadget.MetaObj;

    if MetaObj.TriggerEffect = DOM_PICKUP then
      fFrame := aGadget.Obj.Skill + 1;

    if MetaObj.TriggerEffect in [DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE] then
      fFrame := 1;
  end else
    fPrimary := false;
end;

function TGadgetAnimationInstance.GetBitmap: TBitmap32;
begin
  Result := fAnimation.GetFrameBitmap(fFrame);
end;

function TGadgetAnimationInstance.UpdateOneFrame: Boolean;
begin
  Result := true;

  ProcessTriggers;

  if fState = gasStop then
  begin
    fFrame := 0;
    fState := gasPause;
  end;

  if fState <> gasPause then
    fFrame := (fFrame + 1) mod fAnimation.FrameCount;

  if (fState = gasLoopToZero) and (fFrame = 0) then
    fState := gasPause;
end;

procedure TGadgetAnimationInstance.ProcessTriggers;
var
  i: Integer;
  Cond: TGadgetAnimationTriggerCondition;
  ThisTrigger: TGadgetAnimationTrigger;
  Pass: Boolean;
begin
  for i := fAnimation.Triggers.Count-1 downto 0 do
  begin
    ThisTrigger := fAnimation.Triggers[i];

    Pass := true;
    for Cond := Low(TGadgetAnimationTriggerCondition) to High(TGadgetAnimationTriggerCondition) do
      case ThisTrigger.Condition[Cond] of
        gatsTrue: if not fGadget.AnimationFlag[Cond] then Pass := false;
        gatsFalse: if fGadget.AnimationFlag[Cond] then Pass := false;
      end;

    if Pass then
    begin
      fState := ThisTrigger.State;
      fVisible := ThisTrigger.Visible;
      Exit;
    end;
  end;
end;

{ TGadgetAnimationInstances }

procedure TGadgetAnimationInstances.Clone(aSrc: TGadgetAnimationInstances; newObj: TGadget);
var
  i: Integer;
  NewInstance: TGadgetAnimationInstance;
begin
  for i := 0 to aSrc.Count-1 do
  begin
    NewInstance := TGadgetAnimationInstance.Create(newObj, aSrc[i].MetaAnimation.Name);
    NewInstance.Clone(aSrc[i]);
    Add(NewInstance);
    if NewInstance.Primary then
      fPrimaryAnimation := NewInstance;
  end;
end;

function TGadgetAnimationInstances.GetPrimaryAnimation: TGadgetAnimationInstance;
var
  i: Integer;
begin
  if fPrimaryAnimation = nil then
    for i := 0 to Count-1 do
      if Items[i].Primary then
      begin
        fPrimaryAnimation := Items[i];
        Break;
      end;

  Result := fPrimaryAnimation;
end;

end.
