unit LemLemming;

// TLemming and TLemmingList were moved here so that both
// LemGame and LemRendering can use them.

interface

uses
  LemMetaAnimation, GR32, LemTypes, LemCore,
  Contnrs, Types, Classes, SysUtils;

type
  TPreplacedLemming = class
    private
      fX: Integer;
      fY: Integer;
      fDx: Integer;
      fIsSlider:       Boolean;
      fIsClimber:      Boolean;
      fIsSwimmer:      Boolean;
      fIsFloater:      Boolean;
      fIsGlider:       Boolean;
      fIsDisarmer:     Boolean;
      fIsBallooner:    Boolean;
      fIsShimmier:     Boolean;
      fIsBlocker:      Boolean;
      fIsZombie:       Boolean;
      fIsNeutral:      Boolean;
    public
      constructor Create;
      procedure Assign(aSrc: TPreplacedLemming);
      property X: Integer read fX write fX;
      property Y: Integer read fY write fY;
      property Dx: Integer read fDx write fDx;
      property IsSlider: Boolean read fIsSlider write fIsSlider;
      property IsClimber: Boolean read fIsClimber write fIsClimber;
      property IsSwimmer: Boolean read fIsSwimmer write fIsSwimmer;
      property IsFloater: Boolean read fIsFloater write fIsFloater;
      property IsGlider: Boolean read fIsGlider write fIsGlider;
      property IsDisarmer: Boolean read fIsDisarmer write fIsDisarmer;
      property IsBallooner: Boolean read fIsBallooner write fIsBallooner;
      property IsShimmier: Boolean read fIsShimmier write fIsShimmier;
      property IsBlocker: Boolean read fIsBlocker write fIsBlocker;
      property IsZombie: Boolean read fIsZombie write fIsZombie;
      property IsNeutral: Boolean read fIsNeutral write fIsNeutral;
  end;

  TPreplacedLemmingList = class(TObjectList)
    private
      function GetItem(Index: Integer): TPreplacedLemming;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add: TPreplacedLemming;
      function Insert(Index: Integer): TPreplacedLemming;
      procedure Assign(aSrc: TPreplacedLemmingList);
      property Items[Index: Integer]: TPreplacedLemming read GetItem; default;
      property List;
  end;

  TLemming = class
  private
    function CheckForPermanentSkills: Boolean;
    function GetPosition: TPoint;
    function GetCannotReceiveSkills: Boolean;

    function GetJumperDebug(Index: Integer): Boolean;
  public
  { misc sized }
    LemEraseRect                  : TRect; // Rectangle of the last drawaction (can include space for countdown digits)
  { integer sized fields }
    LemIndex                      : Integer; // Index in the lemminglist
    LemIdentifier                 : String;  // Identifier for replay purposes
    LemX                          : Integer; // The "main" foot x position
    LemY                          : Integer; // The "main" foot y position
    LemDX                         : Integer; // X speed (1 if left to right, -1 if right to left)
    LemAscended                   : Integer; // Number of pixels the lem ascended while walking
    LemFallen                     : Integer; // Number of fallen pixels after last updraft
    LemTrueFallen                 : Integer; // Total number of fallen pixels
    LemExplosionTimer             : Integer; // 84 (before 79) downto 0
    LemFreezerExplosionTimer      : Integer; // 0 unless slowfreeze
    LemFreezingTimer              : Integer; // 8 downto 0
    LemUnfreezingTimer            : Integer; // 12 downto 0
    LemBalloonPopTimer            : Integer; // 1 single frame
    LemDisarmingFrames            : Integer;
    LemFrame                      : Integer; // Current animationframe
    LemMaxFrame                   : Integer; // Copy from LMA
    LemFrameDiff                  : Integer;
    LemPhysicsFrame               : Integer;
    LemMaxPhysicsFrame            : Integer;
    LemParticleTimer              : Integer; // @particles, 52 downto 0, after explosion
    LemNumberOfBricksLeft         : Integer; // For builder, platformer, stacker
  { byte sized fields }
    LemAction                     : TBasicLemmingAction; // Current action of the lemming
    LemRemoved                    : Boolean; // The lemming is not in the level anymore
    LemTeleporting                : Boolean;
    LemEndOfAnimation             : Boolean; // Got to the end of non-looping animation
                                             // Equal to (LemFrame > LemMaxFrame)
    LemIsPhysicsSimulation        : Boolean; { For simulations that are used for physics (eg. Basher/Fencer checks)
                                               as opposed to simulations to determine shadows }
    LemIsSlider                   : Boolean;
    LemIsClimber                  : Boolean;
    LemIsSwimmer                  : Boolean;
    LemIsFloater                  : Boolean;
    LemIsGlider                   : Boolean;
    LemIsDisarmer                 : Boolean;
    LemIsTimebomber               : Boolean;
    LemIsRadiating                : Boolean;
    LemIsZombie                   : Boolean;
    LemIsNeutral                  : Boolean;
    LemHasBeenOhnoer              : Boolean;
    LemHasTurned                  : Boolean;
    LemPlacedBrick                : Boolean; // Placed useful brick during this cycle (plaformer and stacker)
    LemInFlipper                  : Integer;
    LemHasBlockerField            : Boolean; // For blockers, even during ohno
    LemIsStartingAction           : Boolean; // Replaces LemIsNewDigger, LemIsNewClimber, and acts as LemIsNewFencer
    LemHighlightReplay            : Boolean;
    LemExploded                   : Boolean; // @particles, set after a Lemming actually exploded, used to control particles-drawing
    LemHideCountdown              : Boolean; // Used to ensure countdown is not displayed when assigned Bomber / Freezer --- needs to be set to "False" for Timebomber
    LemStackLow                   : Boolean; // Is the starting position one pixel below usual??
    LemJumpProgress               : Integer;
    LemDehoistPinY                : Integer; // The Y coordinate the lemming started dehoisting on
    LemLaserHit                   : Boolean;
    LemLaserHitPoint              : TPoint;
    LemLaserRemainTime            : Integer;
    LemHoldingProjectileIndex     : Integer;
    LemConstructivePositionFreeze : Boolean;
    LemWalkerPositionAdjusted     : Boolean;

    LemInitialFall                : Boolean; // Set during the lemming's initial fall at the start of a level for a glider / floater special case

    { The next three values are only needed to determine intermediate trigger area checks.
      They are set in HandleLemming }
    LemXOld                       : Integer; // Position of previous frame
    LemYOld                       : Integer;
    LemDXOld                      : Integer;

    LemActionOld                  : TBasicLemmingAction; // Action in previous frame
    LemActionNew                  : TBasicLemmingAction; // New action after fixing a trap, see www.lemmingsforums.net/index.php?topic=3004.0
    LemJumpPositions              : array[0..5, 0..1] of Integer; // Tracking exact positions is the only way jumper shadows can be accurate

    LemQueueAction                : TBasicLemmingAction; // Queued action to be assigned within the next few frames
    LemQueueFrame                 : Integer; // Number of frames the skill is already queued

    constructor Create;
    procedure Assign(Source: TLemming);
    procedure SetFromPreplaced(Source: TPreplacedLemming);

    property Position          : TPoint read GetPosition;    
    property HasPermanentSkills: Boolean read CheckForPermanentSkills;
    property CannotReceiveSkills: Boolean read GetCannotReceiveSkills;

    property JumperGliderDebug: Boolean Index 1 read GetJumperDebug;
    property JumperSplatDebug: Boolean Index 2 read GetJumperDebug;
  end;

  TLemmingList = class(TObjectList)
  private
    function GetItem(Index: Integer): TLemming;
  protected
  public
    function Add(Item: TLemming): Integer;
    procedure Insert(Index: Integer; Item: TLemming);
    property Items[Index: Integer]: TLemming read GetItem; default;
    property List; // For fast access
  end;

implementation

{ TPreplacedLemming }

constructor TPreplacedLemming.Create;
begin
  inherited;
  fX := 0;
  fY := 0;
  fDx := 1;
  fIsSlider := false;
  fIsClimber := false;
  fIsSwimmer := false;
  fIsFloater := false;
  fIsGlider := false;
  fIsDisarmer := false;
  fIsBallooner := false;
  fIsShimmier := false;
  fIsBlocker := false;
  fIsZombie := false;
  fIsNeutral := false;
end;

procedure TPreplacedLemming.Assign(aSrc: TPreplacedLemming);
begin
  X := aSrc.X;
  Y := aSrc.Y;
  Dx := aSrc.Dx;
  IsSlider := aSrc.IsSlider;
  IsClimber := aSrc.IsClimber;
  IsSwimmer := aSrc.IsSwimmer;
  IsFloater := aSrc.IsFloater;
  IsGlider := aSrc.IsGlider;
  IsDisarmer := aSrc.IsDisarmer;
  IsBallooner := aSrc.IsBallooner;
  IsShimmier := aSrc.IsShimmier;
  IsBlocker := aSrc.IsBlocker;
  IsZombie := aSrc.IsZombie;
  IsNeutral := aSrc.IsNeutral;
end;

{ TPreplacedLemmingList }

constructor TPreplacedLemmingList.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TPreplacedLemmingList.Add: TPreplacedLemming;
begin
  Result := TPreplacedLemming.Create;
  inherited Add(Result);
end;

function TPreplacedLemmingList.Insert(Index: Integer): TPreplacedLemming;
begin
  Result := TPreplacedLemming.Create;
  inherited Insert(Index, Result);
end;

procedure TPreplacedLemmingList.Assign(aSrc: TPreplacedLemmingList);
var
  i: Integer;
  Item: TPreplacedLemming;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TPreplacedLemmingList.GetItem(Index: Integer): TPreplacedLemming;
begin
  Result := inherited Get(Index);
end;

{ TLemming }

constructor TLemming.Create;
begin
  inherited;
  LemInFlipper := -1;
  LemParticleTimer := -1;
  LemHoldingProjectileIndex := -1;
end;

function TLemming.CheckForPermanentSkills: Boolean;
begin
  Result := (LemIsSlider or LemIsClimber or LemIsSwimmer or LemIsFloater or LemIsGlider or LemIsDisarmer);
end;

procedure TLemming.SetFromPreplaced(Source: TPreplacedLemming);
begin
  LemX := Source.X;
  LemY := Source.Y;
  LemDx := Source.Dx;
  LemIsSlider := Source.IsSlider;
  LemIsClimber := Source.IsClimber;
  LemIsSwimmer := Source.IsSwimmer;
  LemIsFloater := Source.IsFloater;
  LemIsGlider := Source.IsGlider;
  LemIsDisarmer := Source.IsDisarmer;
  LemIsNeutral := Source.IsNeutral;
  // Shimmier, Blocker and Zombie must be handled by the calling routine
end;

function TLemming.GetCannotReceiveSkills: Boolean;
begin
  Result := LemIsZombie or LemIsNeutral or LemHasBeenOhnoer;
end;

function TLemming.GetJumperDebug(Index: Integer): Boolean;
begin
  case Index of
    1: Result := LemIsSwimmer;
    2: Result := LemIsDisarmer;
    else Result := false;
  end;
end;

function TLemming.GetPosition: TPoint;
begin
  Result.X := LemX;
  Result.Y := LemY;
end;

procedure TLemming.Assign(Source: TLemming);
begin

  // Does NOT copy LemIndex! This is intentional //
  LemIdentifier := Source.LemIdentifier;
  LemEraseRect := Source.LemEraseRect;
  LemX := Source.LemX;
  LemY := Source.LemY;
  LemDX := Source.LemDX;
  LemAscended := Source.LemAscended;
  LemFallen := Source.LemFallen;
  LemTrueFallen := Source.LemTrueFallen;
  LemInitialFall := Source.LemInitialFall;
  LemExplosionTimer := Source.LemExplosionTimer;
  LemFreezerExplosionTimer := Source.LemFreezerExplosionTimer;
  LemFreezingTimer := Source.LemFreezingTimer;
  LemUnfreezingTimer := Source.LemUnfreezingTimer;
  LemBalloonPopTimer := Source.LemBalloonPopTimer;
  LemDisarmingFrames := Source.LemDisarmingFrames;
  LemFrame := Source.LemFrame;
  LemMaxFrame := Source.LemMaxFrame;
  LemFrameDiff := Source.LemFrameDiff;
  LemPhysicsFrame := Source.LemPhysicsFrame;
  LemMaxPhysicsFrame := Source.LemMaxPhysicsFrame;
  LemParticleTimer := Source.LemParticleTimer;
  LemNumberOfBricksLeft := Source.LemNumberOfBricksLeft;

  LemAction := Source.LemAction;
  LemRemoved := Source.LemRemoved;
  LemTeleporting := Source.LemTeleporting;
  LemEndOfAnimation := Source.LemEndOfAnimation;
  LemIsPhysicsSimulation := Source.LemIsPhysicsSimulation;
  LemIsSlider := Source.LemIsSlider;
  LemIsClimber := Source.LemIsClimber;
  LemIsSwimmer := Source.LemIsSwimmer;
  LemIsFloater := Source.LemIsFloater;
  LemIsGlider := Source.LemIsGlider;
  LemIsDisarmer := Source.LemIsDisarmer;
  LemIsTimebomber := Source.LemIsTimebomber;
  LemIsRadiating := Source.LemIsRadiating;
  LemIsZombie := Source.LemIsZombie;
  LemHasBeenOhnoer := Source.LemHasBeenOhnoer;
  LemHasTurned := Source.LemHasTurned;
  LemIsNeutral := Source.LemIsNeutral;
  LemPlacedBrick := Source.LemPlacedBrick;
  LemInFlipper := Source.LemInFlipper;
  LemHasBlockerField := Source.LemHasBlockerField;
  LemIsStartingAction := Source.LemIsStartingAction;
  LemHighlightReplay := Source.LemHighlightReplay;
  LemExploded := Source.LemExploded;
  LemHideCountdown := Source.LemHideCountdown;
  LemStackLow := Source.LemStackLow;
  LemJumpProgress := Source.LemJumpProgress;
  LemDehoistPinY := Source.LemDehoistPinY;
  LemLaserHit := Source.LemLaserHit;
  LemLaserHitPoint := Source.LemLaserHitPoint;
  LemLaserRemainTime := Source.LemLaserRemainTime;
  LemHoldingProjectileIndex := Source.LemHoldingProjectileIndex;
  LemConstructivePositionFreeze := Source.LemConstructivePositionFreeze;
  LemWalkerPositionAdjusted := Source.LemWalkerPositionAdjusted;

  LemXOld := Source.LemXOld;
  LemYOld := Source.LemYOld;
  LemDXOld := Source.LemDXOld;
  LemActionOld := Source.LemActionOld;
  LemActionNew := Source.LemActionNew;
  LemJumpPositions := Source.LemJumpPositions;
  // Does NOT copy LemQueueAction or LemQueueFrame! This is intentional, because we want to cancel queuing on backwards frameskips.
end;

{ TLemmingList }

function TLemmingList.Add(Item: TLemming): Integer;
begin
  Result := inherited Add(Item);
end;

function TLemmingList.GetItem(Index: Integer): TLemming;
begin
  Result := inherited Get(Index);
end;

procedure TLemmingList.Insert(Index: Integer; Item: TLemming);
begin
  inherited Insert(Index, Item);
end;

end.