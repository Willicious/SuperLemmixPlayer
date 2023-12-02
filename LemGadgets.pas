{$include lem_directives.inc}
unit LemGadgets;

interface

uses
  Math, Classes, GR32,
  Windows, Contnrs, SysUtils, LemTypes, LemCore,
  LemGadgetsMeta, LemGadgetsModel, LemGadgetsConstants,
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
      fDisableTriggers: Boolean;

      function GetBitmap: TBitmap32;
      function GetDisableTriggers: Boolean;
    public
      constructor Create(aGadget: TGadget; aAnimation: TGadgetAnimation);
      function UpdateOneFrame: Boolean; // If returns false, the object PERMANENTLY removes the animation. Futureproofing.
      procedure UpdateAnimationState; // Basically, all frame update logic *except* moving to the next frame
      procedure ProcessTriggers;

      procedure Clone(aSrc: TGadgetAnimationInstance);

      property MetaAnimation: TGadgetAnimation read fAnimation;
      property Bitmap: TBitmap32 read GetBitmap;
      property Primary: Boolean read fPrimary;
      property Frame: Integer read fFrame write fFrame;
      property Visible: Boolean read fVisible;
      property State: TGadgetAnimationState read fState;
      property DisableTriggers: Boolean read GetDisableTriggers write fDisableTriggers;
  end;

  TGadgetAnimationInstances = class(TObjectList<TGadgetAnimationInstance>)
    private
      fPrimaryAnimation: TGadgetAnimationInstance;
      fPrimaryAnimationFrameCount: Integer;
      function GetPrimaryAnimation: TGadgetAnimationInstance;
      procedure SetPrimaryAnimation(const aValue: TGadgetAnimationInstance);
    public
      procedure Clone(aSrc: TGadgetAnimationInstances; newObj: TGadget);
      procedure ChangePrimaryAnimation(aNewPrimaryName: String; aSetFrame: Integer = -1); // Discards the old primary!
      property PrimaryAnimation: TGadgetAnimationInstance read GetPrimaryAnimation write SetPrimaryAnimation;
      property PrimaryAnimationFrameCount: Integer read fPrimaryAnimationFrameCount;
  end;

  // Internal object used by game
  TGadget = class
  private
    sTop            : Integer;
    sLeft           : Integer;
    sHeight         : Integer;
    sWidth          : Integer;

    sWidthVariance  : Integer; // Difference from default. used by secondary animations.
    sHeightVariance : Integer;

    sTriggerRect    : TRect;  // We assume that trigger areas will never move!!!
    sTriggerEffect  : Integer;
    sReceiverId     : Integer;
    sPairingId      : Integer;
    sZombieMode     : Boolean;
    sNeutralMode    : Boolean;
    sSecondariesTreatAsBusy: Boolean;

    sRemainingLemmingsCount: Integer;
    sShowRemainingLemmings: Boolean;

    sCountdownLength: Integer;

    Obj            : TGadgetModel;

    procedure CreateAnimationInstances;
    procedure PrepareAnimationInstances;

    function GetTriggerRect: TRect;
    procedure SetLeft(Value: Integer);
    procedure SetTop(Value: Integer);
    function GetSkillType: TSkillPanelButton;
    function GetSoundEffectActivate: String;
    function GetSoundEffectExhaust: String;
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
    function GetRemainingLemmingsCount: Integer;
    function GetCountdownLength: Integer;

    function GetCurrentFrame: Integer; { Just remaps to primary animation. This allows LemGame to control
                                         the primary animation directly, as it always has. }
    procedure SetCurrentFrame(aValue: Integer);

    function GetAnimFlagState(aFlag: TGadgetAnimationTriggerCondition): Boolean;
  public
    MetaObj        : TGadgetMetaAccessor;

    Animations: TGadgetAnimationInstances;

    Triggered      : Boolean;
    TeleLem        : Integer; // Saves which lemming is currently teleported
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
    property SoundEffectActivate: String read GetSoundEffectActivate;
    property SoundEffectExhaust: String read GetSoundEffectExhaust;
    property ZombieMode: Boolean read sZombieMode write sZombieMode;
    property NeutralMode: Boolean read sNeutralMode write sNeutralMode;
    property KeyFrame: Integer read GetKeyFrame;
    property CanDrawToBackground: Boolean read GetCanDrawToBackground; // Moving backgrounds: if only one frame and zero speed, this returns true
    property Speed: Integer read GetSpeed;
    property SkillCount: Integer read GetSkillCount;
    property IsPreassignedClimber: Boolean index 1 read GetPreassignedSkill;
    property IsPreassignedSwimmer: Boolean index 2 read GetPreassignedSkill;
    property IsPreassignedFloater: Boolean index 4 read GetPreassignedSkill;
    property IsPreassignedGlider: Boolean index 8 read GetPreassignedSkill;
    property IsPreassignedDisarmer: Boolean index 16 read GetPreassignedSkill;
    property IsPreassignedZombie: Boolean index 64 read GetPreassignedSkill;
    property IsPreassignedNeutral: Boolean index 128 read GetPreassignedSkill;
    property IsPreassignedSlider: Boolean index 256 read GetPreassignedSkill;
    property HasPreassignedSkills: Boolean read GetHasPreassignedSkills;
    property TriggerEffectBase: Integer read GetTriggerEffectBase;
    property SecondariesTreatAsBusy: Boolean read sSecondariesTreatAsBusy write sSecondariesTreatAsBusy;
    property RemainingLemmingsCount: Integer read GetRemainingLemmingsCount write sRemainingLemmingsCount;
    property ShowRemainingLemmings: Boolean read sShowRemainingLemmings write sShowRemainingLemmings;
    property SRCountdownLength: Integer read GetCountdownLength write sCountdownLength;

    property AnimationFlag[Flag: TGadgetAnimationTriggerCondition]: Boolean read GetAnimFlagState;

    procedure AssignTo(NewObj: TGadget);
    procedure UnifyFlippingFlagsOfTeleporter();
    procedure SetFlipOfReceiverTo(Teleporter: TGadget);

    // True = X-movement, False = Y-movement
    function Movement(Direction: Boolean; CurrentIteration: Integer): Integer;
  end;

type
  // Internal list, used by game
  TGadgetList = class(TObjectList)
  private
    function GetItem(Index: Integer): TGadget;
  protected
  public
    function Add(Item: TGadget): Integer;
    procedure Insert(Index: Integer; Item: TGadget);
    procedure FindReceiverID;
    procedure InitializeAnimations;
    property Items[Index: Integer]: TGadget read GetItem; default;
  published
  end;

implementation

{ TGadget }
constructor TGadget.Create;
begin
  inherited;
  Animations := TGadgetAnimationInstances.Create;
  sRemainingLemmingsCount := -2;
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
  Obj.Width := EvaluateResizable(Obj.Width, MetaObj.DefaultWidth, MetaObj.Width, MetaObj.CanResizeHorizontal);
  Obj.Height := EvaluateResizable(Obj.Height, MetaObj.DefaultHeight, MetaObj.Height, MetaObj.CanResizeVertical);
  sHeight := Obj.Height;
  sWidth := Obj.Width;

  sWidthVariance := sWidth - MetaObj.Width;
  sHeightVariance := sHeight - MetaObj.Height;

  sTriggerEffect := MetaObj.TriggerEffect;
  AdjustOWWDirection; // Adjusts eg. flipped OWL becomes OWR
  sTriggerRect := GetTriggerRect;
  sReceiverId := 65535;

  if IsFlipImage then
  begin
    if sTriggerEffect = DOM_FORCELEFT then sTriggerEffect := DOM_FORCERIGHT
    else if sTriggerEffect = DOM_FORCERIGHT then sTriggerEffect := DOM_FORCELEFT;
  end;

  // Set other stuff
  Triggered := False;
  TeleLem := -1; // Set to a value no lemming has (hopefully!)

  HoldActive := False;
  ZombieMode := False;

  sCountdownLength := 0;
end;

procedure TGadget.CreateAnimationInstances;
var
  NewInstance: TGadgetAnimationInstance;
  i: Integer;
begin
  for i := 0 to MetaObj.Animations.Count-1 do
  begin
    NewInstance := TGadgetAnimationInstance.Create(self, MetaObj.Animations.Items[i]);
    Animations.Add(NewInstance);
  end;
end;

procedure TGadget.PrepareAnimationInstances;
var
  i: Integer;
begin
  for i := 0 to Animations.Count-1 do
  begin
    Animations[i].ProcessTriggers;
    Animations[i].UpdateAnimationState;
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
  // Doesn't clone state
end;

function TGadget.GetTriggerRect: TRect;
{ Note that the trigger area is only the inside of the TRect,
  which by definition does not include the right and bottom line! }
var
  X, Y: Integer;
  W, H: Integer;
begin
  Y := Obj.Top; // Of whole object
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
      // For cases where these are zero
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

function TGadget.GetSkillType: TSkillPanelButton;
begin
  Assert(TriggerEffect = DOM_PICKUP, 'Object.SkillType called for non-PickUp skill');
  Result := TSkillPanelButton(Obj.Skill);
end;

function TGadget.GetSoundEffectActivate: String;
begin
  Result := MetaObj.SoundEffectActivate;
end;

function TGadget.GetSoundEffectExhaust: String;
begin
  Result := MetaObj.SoundEffectExhaust;
end;

function TGadget.GetIsOnlyOnTerrain: Boolean;
begin
  Result := (MetaObj.TriggerEffect = DOM_PAINT) or ((Obj.DrawingFlags and odf_OnlyOnTerrain) <> 0);
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
  Result := Animations.PrimaryAnimationFrameCount;
end;

function TGadget.GetAnimFlagState(aFlag: TGadgetAnimationTriggerCondition): Boolean;
const
  READY_OBJECT_TYPES = // Any object not listed here, always returns *TRUE* (not false like the others)
    [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_PICKUP, DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE,
     DOM_ANIMATION, DOM_ANIMONCE];
  BUSY_OBJECT_TYPES = // Any object not listed here, always returns false
    [DOM_TRAP, DOM_TELEPORT, DOM_RECEIVER, DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE, DOM_ANIMATION,
     DOM_ANIMONCE];
  DISABLED_OBJECT_TYPES = // Any object not listed here, always returns false
    [DOM_EXIT, DOM_TRAP, DOM_PICKUP, DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE, DOM_ANIMONCE];
  EXHAUSTED_OBJECT_TYPES = // Any object not listed here, always returns false
    [DOM_EXIT, DOM_PICKUP, DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE, DOM_ANIMONCE];

  function CheckReadyFlag: Boolean;
  begin
    Result := true;
    if TriggerEffectBase in READY_OBJECT_TYPES then
    begin
      if sSecondariesTreatAsBusy // For DOM_TELEPORT, "receiver is busy" is marked as this
      or (TriggerEffect = DOM_NONE) then // Local trigger effect is set to DOM_NONE when disarmed / etc
        Result := false
      else
        case TriggerEffectBase of
          DOM_EXIT: Result := RemainingLemmingsCount <> 0;
          DOM_TRAP, DOM_TELEPORT, DOM_ANIMATION: Result := (CurrentFrame = 0);
          DOM_LOCKEXIT: Result := (CurrentFrame = 0) and (RemainingLemmingsCount <> 0);
          DOM_BUTTON, DOM_TRAPONCE, DOM_ANIMONCE: Result := CurrentFrame = 1;
          DOM_PICKUP: Result := CurrentFrame mod 2 <> 0;
          DOM_RECEIVER: Result := (CurrentFrame = 0) and (not HoldActive);
          DOM_WINDOW: Result := (CurrentFrame = 0) and (RemainingLemmingsCount <> 0);
        end;
    end;
  end;

  function CheckBusyFlag: Boolean;
  begin
    Result := false;
    if TriggerEffectBase in BUSY_OBJECT_TYPES then
    begin
      if sSecondariesTreatAsBusy then // For DOM_TELEPORT, "receiver is busy" is marked as this
        Result := true
      else
        case TriggerEffectBase of
          DOM_TRAP, DOM_ANIMATION, DOM_TELEPORT: Result := CurrentFrame > 0;
          DOM_TRAPONCE, DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_ANIMONCE: Result := CurrentFrame > 1;
          DOM_RECEIVER: Result := (CurrentFrame > 0) or HoldActive;
        end;
    end;
  end;

  function CheckDisabledFlag: Boolean;
  begin
    Result := false;
    if TriggerEffectBase in DISABLED_OBJECT_TYPES then
    begin
       if TriggerEffect = DOM_NONE then // Local trigger effect is set to DOM_NONE when disarmed trap, unmatched teleport / receiver
        Result := true
      else
        case TriggerEffectBase of
          DOM_EXIT: Result := RemainingLemmingsCount = 0;
          // DOM_TRAP: Only condition is handled by the above TriggerEffect check // Bookmark - remove?
          DOM_PICKUP: Result := CurrentFrame mod 2 = 0;
          DOM_BUTTON, DOM_TRAPONCE, DOM_ANIMONCE: Result := CurrentFrame = 0;
          DOM_LOCKEXIT: Result := (CurrentFrame = 1) or (RemainingLemmingsCount = 0);
          DOM_WINDOW: Result := RemainingLemmingsCount = 0; // Bookmark - check this is done: todo: when all lemmings are released even on infinite windows
        end;
    end;
  end;

  function CheckExhaustedFlag: Boolean;
  begin
    Result := false;
    if TriggerEffectBase in EXHAUSTED_OBJECT_TYPES then
      case TriggerEffectBase of
        DOM_PICKUP: Result := CurrentFrame mod 2 = 0;
        DOM_BUTTON, DOM_TRAPONCE, DOM_ANIMONCE: Result := CurrentFrame = 0;
        DOM_EXIT, DOM_LOCKEXIT, DOM_WINDOW: Result := RemainingLemmingsCount = 0;
      end;
  end;
begin
  case aFlag of
    gatcUnconditional: Result := true;
    gatcReady: Result := CheckReadyFlag;
    gatcBusy: Result := CheckBusyFlag;
    gatcDisabled: Result := CheckDisabledFlag;
    gatcExhausted: Result := CheckExhaustedFlag;
    else raise Exception.Create('TGadget.GetAnimFlagState passed an invalid param.');
  end;
end;

function TGadget.GetPreassignedSkill(BitField: Integer): Boolean;
begin
  // Only call this function for hatches
  Assert(MetaObj.TriggerEffect in [DOM_WINDOW], 'Preassigned skill called for object not a hatch or a preplaced lemming');
  Result := (Obj.TarLev and BitField) <> 0; // Yes, "TargetLevel" stores this info!
end;

function TGadget.GetRemainingLemmingsCount: Integer;
begin
  if sRemainingLemmingsCount < -1 then
  begin
    if Obj.LemmingCap > 0 then
      sRemainingLemmingsCount := Obj.LemmingCap
    else
      sRemainingLemmingsCount := -1;

    sShowRemainingLemmings := true;
  end;

  Result := sRemainingLemmingsCount;
end;

function TGadget.GetCountdownLength: Integer;
begin
  if sCountdownLength = 0 then
  begin
    if (Obj.CountdownLength > 0) and not (Obj.CountdownLength >= 100) then
      sCountdownLength := Obj.CountdownLength
    else if Obj.CountdownLength >= 100 then
      sCountdownLength := 99
    else
      sCountdownLength := 0;
  end;

  Result := sCountdownLength;
end;

function TGadget.GetHasPreassignedSkills: Boolean;
begin
  Assert(MetaObj.TriggerEffect in [DOM_WINDOW], 'Preassigned skill called for object not a hatch');
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
  NewObj.sRemainingLemmingsCount := sRemainingLemmingsCount;
  NewObj.sCountdownLength := sCountdownLength;
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

procedure TGadgetList.InitializeAnimations;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].PrepareAnimationInstances;
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
          Add(TestGadget); // To this GadgetList
          Gadget.sReceiverId := Count - 1; // Set to newly added receiver
        end;
        Gadget.sPairingId := PairCount;
        TestGadget.sPairingId := PairCount;
        IsReceiverUsed[TestID] := true; // Ignore newly added receivers for this
        Inc(PairCount);
        // Flip receiver according to teleporter
        Gadget.UnifyFlippingFlagsOfTeleporter();
        TestGadget.SetFlipOfReceiverTo(Gadget);
      end;
    end; // End test whether object is teleporter
  end; // Next gadget

  for i := 0 to ItemCount - 1 do
    if (Items[i].TriggerEffect = DOM_RECEIVER) and not IsReceiverUsed[i] then
      Items[i].TriggerEffect := DOM_NONE // Set to no-effect as a means of disabling if
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
  aAnimation: TGadgetAnimation);
var
  MetaObj: TGadgetMetaAccessor;
begin
  inherited Create;

  if aGadget.MetaObj.Animations.IndexOf(aAnimation) < 0 then
    raise Exception.Create('TGadgetAnimationInstance.Create called with an animation from a different gadget!');

  fGadget := aGadget;
  fAnimation := aAnimation;

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
      fFrame := (aGadget.Obj.Skill * 2) + 1;

    if MetaObj.TriggerEffect in [DOM_LOCKEXIT, DOM_BUTTON, DOM_WINDOW, DOM_TRAPONCE, DOM_ANIMONCE] then
      fFrame := 1;

    if (MetaObj.TriggerEffect = DOM_FLIPPER) and (aGadget.IsFlipPhysics) then
      fFrame := 1;
  end else
    fPrimary := false;
end;

function TGadgetAnimationInstance.GetBitmap: TBitmap32;
begin
  Result := fAnimation.GetFrameBitmap(fFrame);
end;

function TGadgetAnimationInstance.GetDisableTriggers: Boolean;
begin
  Result := fDisableTriggers or fPrimary;
end;

function TGadgetAnimationInstance.UpdateOneFrame: Boolean;
begin
  Result := true;

  ProcessTriggers;

  if (fState <> gasPause) and ((fState <> gasLoopToZero) or (fFrame > 0)) then
    fFrame := (fFrame + 1) mod fAnimation.FrameCount;

  UpdateAnimationState;
end;

procedure TGadgetAnimationInstance.UpdateAnimationState;
begin
  case fState of
    gasPlay: ; // Nothing to do
    gasPause: ; // Nothing to do
    gasLoopToZero: if fFrame = 0 then fState := gasPause;
    gasStop: begin fFrame := 0; fState := gasPause; end;
    gasMatchPrimary: fFrame := fGadget.CurrentFrame;
  end;
end;

procedure TGadgetAnimationInstance.ProcessTriggers;
var
  i: Integer;
  ThisTrigger: TGadgetAnimationTrigger;
begin
  if DisableTriggers then Exit;

  for i := fAnimation.Triggers.Count-1 downto 0 do
  begin
    ThisTrigger := fAnimation.Triggers[i];

    if fGadget.AnimationFlag[ThisTrigger.Condition] then
    begin
      fState := ThisTrigger.State;
      fVisible := ThisTrigger.Visible;
      Exit;
    end;
  end;
end;

{ TGadgetAnimationInstances }

procedure TGadgetAnimationInstances.ChangePrimaryAnimation(aNewPrimaryName: String; aSetFrame: Integer = -1);
var
  i: Integer;
  NewPrimary: TGadgetAnimationInstance;
begin
  aNewPrimaryName := Trim(Uppercase(aNewPrimaryName));
  for i := 0 to Count-1 do
    if Items[i].fAnimation.Name = aNewPrimaryName then
    begin
      NewPrimary := Items[i];
      Remove(fPrimaryAnimation);

      PrimaryAnimation := NewPrimary;
      NewPrimary.fPrimary := true;
      NewPrimary.fState := gasPause;
      NewPrimary.fVisible := true;

      if (aSetFrame >= 0) then
        NewPrimary.fFrame := aSetFrame; { Futureproofing, in case we ever have a situation where we *don't* need
                                          to set the frame, but can allow INITIAL_FRAME to take effect. }
      Exit;
    end;
end;

procedure TGadgetAnimationInstances.Clone(aSrc: TGadgetAnimationInstances; newObj: TGadget);
var
  i: Integer;
  NewInstance: TGadgetAnimationInstance;
begin
  Clear;

  for i := 0 to aSrc.Count-1 do
  begin
    NewInstance := TGadgetAnimationInstance.Create(newObj, aSrc[i].MetaAnimation);
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
        PrimaryAnimation := Items[i];
        Break;
      end;

  Result := fPrimaryAnimation;
end;

procedure TGadgetAnimationInstances.SetPrimaryAnimation(const aValue: TGadgetAnimationInstance);
begin
  fPrimaryAnimation := aValue;

  if aValue = nil then
    fPrimaryAnimationFrameCount := 0
  else
    fPrimaryAnimationFrameCount := aValue.fAnimation.FrameCount;
end;

end.
