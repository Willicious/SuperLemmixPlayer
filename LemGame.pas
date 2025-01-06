{$include lem_directives.inc}

{-------------------------------------------------------------------------------
  Some source code notes:

  • Transition() method: It has a default parameter. So if you see a
    call to Transition() with three parameters and the last one is TRUE, it means
    that the lemming has to turn around as well. I commented this too at all
    places where this happens.
-------------------------------------------------------------------------------}

unit LemGame;

interface

uses
  System.Types, Generics.Collections,
  PngInterface,
  Windows, Classes, Contnrs, SysUtils, Math, Forms, Dialogs,
  Controls, StrUtils, UMisc,
  GR32, GR32_OrdinalMaps,
  LemCore, LemTypes, LemStrings,
  LemLevel,
  LemRenderHelpers, LemRendering,
  LemNeoTheme,
  LemGadgets, LemGadgetsConstants, LemLemming, LemProjectile, LemRecolorSprites,
  LemReplay,
  LemTalisman,
  LemGameMessageQueue,
  GameControl, GameSound,
  SharedGlobals;

const
  ParticleColorIndices: array[0..15] of Byte =
    (4, 15, 14, 13, 12, 11, 10, 9, 8, 11, 10, 9, 8, 7, 6, 2);

  AlwaysAnimateObjects = [DOM_NONE, DOM_EXIT, DOM_FORCELEFT, DOM_FORCERIGHT,
                          DOM_DECORATION, DOM_WATER, DOM_FIRE, DOM_UPDRAFT,
                          DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN,
                          DOM_NOSPLAT, DOM_SPLAT, DOM_RADIATION, DOM_SLOWFREEZE,
                          DOM_BLASTICINE, DOM_VINEWATER, DOM_POISON, DOM_LAVA];

type
  TLemmingKind = (lkNormal, lkNeutral, lkZombie // Rivals are lkNormal for the purposes of TLemmingKind
  );
  TLemmingKinds = set of TLemmingKind;

type
  TLemmingGame = class;

  TLemmingGameSavedState = class
    public
      LemmingList: TLemmingList;
      ProjectileList: TProjectileList;
      SelectedSkill: TSkillPanelButton;
      TerrainLayer: TBitmap32;  // The visual terrain image
      PhysicsMap: TBitmap32;    // The actual physics
      ZombieMap: TByteMap; // Still needed for now, because there is no proper method to set the ZombieMap
      CurrentIteration: Integer;
      ClockFrame: Integer;
      ButtonsRemain: Integer;
      CollectiblesRemain: Integer;
      LemmingsToRelease: Integer;
      LemmingsCloned: Integer;
      LemmingsOut: Integer;
      fSpawnedDead: Integer;
      LemmingsIn: Integer;
      LemmingsRemoved: Integer;
      NextLemmingCountdown: Integer;
      DelayEndFrames: Integer;
      TimePlay: Integer;
      EntriesOpened: Boolean;
      Gadgets: TGadgetList;
      CurrSpawnInterval: Integer;

      CurrSkillCount: array[TBasicLemmingAction] of Integer;  // Should only be called with arguments in AssignableSkills
      UsedSkillCount: array[TBasicLemmingAction] of Integer;  // Should only be called with arguments in AssignableSkills

      IsInfiniteSkillsMode: Boolean;
      IsInfiniteTimeMode: Boolean;

      NukeIsActive: Boolean;
      ExploderAssignInProgress: Boolean;
      Index_LemmingToBeNuked: Integer;

      constructor Create;
      destructor Destroy; override;
  end;

  TLemmingGameSavedStateList = class(TObjectList)
    private
      function GetItem(Index: Integer): TLemmingGameSavedState;
    public
      procedure TidyList(aCurrentIteration: Integer);
      function FindNearestState(aTargetIteration: Integer): Integer;
      procedure ClearAfterIteration(aTargetIteration: Integer);
      function Add: TLemmingGameSavedState;
      property Items[Index: Integer]: TLemmingGameSavedState read GetItem; default;
      property List;
  end;


  TLemmingMethod = function (L: TLemming): Boolean of object;
  TLemmingMethodArray = array[TBasicLemmingAction] of TLemmingMethod;

  TNewSkillMethod = function (L: TLemming): Boolean of object;
  TNewSkillMethodArray = array[TBasicLemmingAction] of TNewSkillMethod;

  TLemmingEvent = procedure (L: TLemming) of object;

  TLemmingGame = class(TComponent)
  private
    fRenderInterface           : TRenderInterface;
    fMessageQueue              : TGameMessageQueue;

    fTalismanReceived          : Boolean;
    fNewTalismanReceived       : Boolean;
    fCollectiblesCompleted     : Boolean;

    fSelectedSkill             : TSkillPanelButton; // TUserSelectedSkill; // Currently selected skill restricted by F3-F9

    fDoneAssignmentThisFrame   : Boolean;

  { internal objects }
    LemmingList                : TLemmingList; // List of lemmings
    ProjectileList             : TProjectileList;
    PhysicsMap                 : TBitmap32;
    BlockerMap                 : TBitmap32;    // For blockers
    ZombieMap                  : TByteMap;
    ExitMap                    : TArrayArrayBoolean;
    LockedExitMap              : TArrayArrayBoolean;
    WaterMap                   : TArrayArrayBoolean;
    FireMap                    : TArrayArrayBoolean;
    TrapMap                    : TArrayArrayBoolean;
    TeleporterMap              : TArrayArrayBoolean;
    UpdraftMap                 : TArrayArrayBoolean;
    PickupMap                  : TArrayArrayBoolean;
    ButtonMap                  : TArrayArrayBoolean;
    CollectibleMap             : TArrayArrayBoolean;
    SplitterMap                : TArrayArrayBoolean;
    NoSplatMap                 : TArrayArrayBoolean;
    SplatMap                   : TArrayArrayBoolean;
    ForceLeftMap               : TArrayArrayBoolean;
    ForceRightMap              : TArrayArrayBoolean;
    AnimMap                    : TArrayArrayBoolean;
    BlasticineMap              : TArrayArrayBoolean;
    VinewaterMap               : TArrayArrayBoolean;
    PoisonMap                  : TArrayArrayBoolean;
    LavaMap                    : TArrayArrayBoolean;
    RadiationMap               : TArrayArrayBoolean;
    SlowfreezeMap              : TArrayArrayBoolean;

    fReplayManager             : TReplay;

  { reference objects, mostly for easy access in the mechanics-code }
    fRenderer                  : TRenderer; // Ref to gameparams.renderer
    fLevel                     : TLevel; // Ref to gameparams.level

  { masks }
    TimebomberMask             : TBitmap32;
    BomberMask                 : TBitmap32;
    FreezerMask                : TBitmap32;
    BasherMasks                : TBitmap32;
    FencerMasks                : TBitmap32;
    MinerMasks                 : TBitmap32;
    GrenadeMask                : TBitmap32;
    SpearMasks                 : TBitmap32;
    //BatMask                    : TBitmap32; // Batter
    LaserMask                  : TBitmap32;
    fMasksLoaded               : Boolean;

  { vars }
    fCurrentIteration          : Integer;
    fClockFrame                : Integer; // 17 frames is one game-second
    ButtonsRemain              : Byte;
    CollectiblesRemain         : Byte;
    LemmingsToRelease          : Integer; // Number of lemmings that were created
    LemmingsCloned             : Integer; // Number of cloned lemmings
    LemmingsOut                : Integer; // Number of lemmings currently walking around
    fSpawnedDead               : Integer; // Number of zombies that were created
    LemmingsIn                 : integer; // Number of lemmings that made it to heaven
    LemmingsRemoved            : Integer; // Number of lemmings removed
    DelayEndFrames             : Integer;
    fCursorPoint               : TPoint;
    fIsSelectWalkerHotkey      : Boolean;
    fIsSelectUnassignedHotkey  : Boolean;
    fIsShowAthleteInfo         : Boolean;
    fIsHighlightHotkey         : Boolean;
    TimePlay                   : Integer; // Positive when time limit
                                          // Negative when just counting time used
    fPlaying                   : Boolean; // Game in active playing mode?
    HatchesOpened              : Boolean;
    LemmingMethods             : TLemmingMethodArray; // Method for each basic lemming state
    NewSkillMethods            : TNewSkillMethodArray; // The replacement of SkillMethods
    fLemSelected               : TLemming; // Lem under cursor, who would receive the skill
    fLemWithShadow             : TLemming; // Needed for CheckForNewShadow to erase previous shadow
    fLemWithShadowButton       : TSkillPanelButton; // Correct skill to be erased
    fExistShadow               : Boolean;  // Whether a shadow is currently drawn somewhere
    fLemNextAction             : TBasicLemmingAction; // Action to transition to at the end of lemming movement
    fLemJumpToHoistAdvance     : Boolean; // When using above with Jumper -> Hoister, whether to apply a frame offset
    fLastBlockerCheckLem       : TLemming; // Blocker responsible for last blocker field check, or nil if none
    Gadgets                    : TGadgetList; // List of objects excluding entrances
    CurrSpawnInterval          : Integer; // The current spawn interval, obviously

    CurrSkillCount             : array[TBasicLemmingAction] of Integer;  // Should only be called with arguments in AssignableSkills
    UsedSkillCount             : array[TBasicLemmingAction] of Integer;  // Should only be called with arguments in AssignableSkills

    fIsInfiniteSkillsMode      : Boolean;
    fIsInfiniteTimeMode        : Boolean;
    fNukeIsActive              : Boolean;
    ExploderAssignInProgress   : Boolean;
    DoExplosionCrater          : Boolean;
    Index_LemmingToBeNuked     : Integer;
    fGameFinished              : Boolean;
    fGameCheated               : Boolean;
    NextLemmingCountDown       : Integer;

    fTargetIteration           : Integer; // This is used in hyperspeed
    fHyperSpeedCounter         : Integer; // No screenoutput
    fHyperSpeed                : Boolean; // We are at hyperspeed no targetbitmap output
    fLeavingHyperSpeed         : Boolean; // In between state (see UpdateLemmings)
    fPauseOnHyperSpeedExit     : Boolean; // To maintain pause state before invoking a savestate

    fIsBackstepping            : Boolean; // Track any game action that causes backward movement
    fIsSuperlemmingMode        : Boolean;
    fPauseWasPressed           : Boolean;
    fReplayLoaded              : Boolean;

    fHitTestAutoFail           : Boolean;
    fHighlightLemmingID        : Integer;
    fTargetLemmingID           : Integer; // For replay skill assignments

  { events }
    fParticleFinishTimer       : Integer; // Extra frames to enable viewing of explosions
    fSimulationDepth           : Integer; // Whether we are in simulation mode for drawing shadows
    fSoundList                 : TList<string>; // List of sounds that have been played already on this frame

  { pixel combine eventhandlers }
    // CombineMaskPixels has variants based on the direction of destruction
    procedure CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32; E: Cardinal); // General-purpose
    procedure CombineMaskPixelsLeft(F: TColor32; var B: TColor32; M: Cardinal);       // Left-facing basher
    procedure CombineMaskPixelsRight(F: TColor32; var B: TColor32; M: Cardinal);      // Right-facing basher
    procedure CombineMaskPixelsUpLeft(F: TColor32; var B: TColor32; M: Cardinal);     // Left-facing fencer
    procedure CombineMaskPixelsUpRight(F: TColor32; var B: TColor32; M: Cardinal);    // Right-facing fencer
    procedure CombineMaskPixelsDownLeft(F: TColor32; var B: TColor32; M: Cardinal);   // Left-facing miner
    procedure CombineMaskPixelsDownRight(F: TColor32; var B: TColor32; M: Cardinal);  // Right-facing miner
    procedure CombineMaskPixelsNeutral(F: TColor32; var B: TColor32; M: Cardinal);    // Bomber & Timebomber
    procedure CombineNoOverwriteFreezer(F: TColor32; var B: TColor32; M: Cardinal);
    procedure CombineNoOverwriteMask(F: TColor32; var B: TColor32; M: Cardinal);

  { internal methods }
    procedure DoTalismanCheck;
    function AllZombiesKilled: Boolean; // Checks for remaining zombies, returning false if nuke is used or if zombies remain
    function ZombiesRemain: Boolean; // Slightly different - checks for remaining zombies, returns true if zombies remain
    function LevelHasKillZombiesTalisman: Boolean;
    function CheckForClassicMode: Boolean; // Checks if classic mode is activated
    function CheckForNoPause: Boolean; // Checks if pause has been pressed at any time
    procedure CheckReplayLoaded; // Checks for action on any future frame and sets flag to true if it finds any
    function GetIsReplaying: Boolean;
    function GetIsReplayingNoRR(isPaused: Boolean): Boolean;
    procedure ApplySpear(P: TProjectile);
    //procedure ApplyBat(P: TProjectile); // Batter
    procedure ApplyGrenadeExplosionMask(P: TProjectile);
    procedure ApplyLaserMask(P: TPoint; L: TLemming);
    procedure ApplyBashingMask(L: TLemming; MaskFrame: Integer);
    procedure ApplyFencerMask(L: TLemming; MaskFrame: Integer);
    procedure ApplyTimebombMask(L: TLemming);
    procedure ApplyExplosionMask(L: TLemming);
    procedure ApplyFreezerIceCube(L: TLemming);
    procedure ApplyMinerMask(L: TLemming; MaskFrame, AdjustX, AdjustY: Integer);
    procedure AddConstructivePixel(X, Y: Integer; Color: TColor32);
    function CalculateNextLemmingCountdown: Integer;
    procedure ZombieCheckForProjectiles(L: TLemming);
    procedure ZombieCheckForLaser(L: TLemming);
    // The next few procedures are for checking the behavior of lems in trigger areas!
    procedure CheckTriggerArea(L: TLemming; IsPostTeleportCheck: Boolean = false);
      function GetGadgetCheckPositions(L: TLemming): TArrayArrayInt;
      function FindGadgetID(X, Y: Integer; TriggerType: TTriggerTypes): Word;

      function HandleTrap(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleAnimation(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleTeleport(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandlePickup(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleButton(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleCollectible(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleExit(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleForceField(L: TLemming; Direction: Integer): Boolean;
      function HandleFire(L: TLemming): Boolean;
      function HandleSplitter(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleRadiation(L: TLemming; PosX, PosY: Integer): Boolean;
      function HandleSlowfreeze(L: TLemming; PosX, PosY: Integer): Boolean;

      procedure StartSwimming(L: TLemming);
      function HandleWaterFatality(L: TLemming): Boolean;
      function HandleWaterSwim(L: TLemming): Boolean;
      function HandleBlasticineFatality(L: TLemming): Boolean;
      function HandleBlasticineSwim(L: TLemming): Boolean;
      function HandleVinewaterFatality(L: TLemming): Boolean;
      function HandleVinewaterSwim(L: TLemming): Boolean;
      function HandleLavaFatality(L: TLemming): Boolean;
      function HandleLavaSwim(L: TLemming): Boolean;
      function HandlePoison(L: TLemming): Boolean;

    function CheckForOverlappingField(L: TLemming): Boolean;
    procedure CheckForQueuedAction;
    procedure CheckForReplayAction(PausedRRCheck: Boolean = false);
    procedure CheckLemmings;
    function CheckLemTeleporting(L: TLemming): Boolean;
    procedure HandlePostTeleport(L: TLemming);
    procedure CheckReleaseLemming;
    procedure CheckUpdateNuking;
    procedure CueExitSound(L: TLemming);
    procedure CueSoundEffect(aSound: String); overload;
    procedure CueSoundEffect(aSound: String; aOrigin: TPoint); overload;
    //procedure CueSoundEffectFrequency(aSound: String; aFrequency: Single);
    function DigOneRow(PosX, PosY: Integer): Boolean;
    //function PropellerOneRow(PosX, PosY: Integer): Boolean; // Propeller
    procedure DrawAnimatedGadgets;
    procedure IncrementIteration;
    procedure InitializeAllTriggerMaps;
    function IsStartingSeconds: Boolean;

    function GetIsSimulating: Boolean;

    procedure LayBrick(L: TLemming);
    procedure LayLadder(L:TLemming);
    function LayStackBrick(L: TLemming): Boolean;
    procedure MoveLemToReceivePoint(L: TLemming; GadgetID: Byte);

    procedure RecordNuke(aInsert: Boolean);
    procedure RecordSpawnInterval(aSI: Integer);
    procedure RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
    procedure RemoveLemming(L: TLemming; RemMode: Integer = 0; Silent: Boolean = false);
    procedure RemovePixelAt(X, Y: Integer);
    procedure ReplaySkillAssignment(aReplayItem: TReplaySkillAssignment);

    procedure SetGadgetMap;
      procedure WriteTriggerMap(Map: TArrayArrayBoolean; Rect: TRect);
      function ReadTriggerMap(X, Y: Integer; Map: TArrayArrayBoolean): Boolean;

    procedure SetBlockerMap;
      procedure WriteBlockerMap(X, Y: Integer; aLemmingIndex: Word; aFieldEffect: Byte);
      function ReadBlockerMap(X, Y: Integer; L: TLemming = nil): Byte;

    procedure SetZombieField(L: TLemming);
      procedure WriteZombieMap(X, Y: Integer; aValue: Byte);
      function ReadZombieMap(X, Y: Integer): Byte;

    procedure SimulateTransition(L: TLemming; NewAction: TBasicLemmingAction);
    function SimulateLem(L: TLemming; DoCheckObjects: Boolean = True): TArrayArrayInt;
    procedure AddPreplacedLemmings;
    procedure FixDuplicatePreplacedLemmingIdentifiers;
    procedure Transition(L: TLemming; NewAction: TBasicLemmingAction; DoTurn: Boolean = False);
    procedure TurnAround(L: TLemming);
    function UpdateExplosionTimer(L: TLemming): Boolean;
    function UpdateFreezerExplosionTimer(L: TLemming): Boolean;
    procedure UpdateFreezingTimer(L: TLemming);
    procedure UpdateUnfreezingTimer(L: TLemming);
    procedure UpdateBalloonPopTimer(L: TLemming);
    procedure UpdateGadgets;
    procedure UpdateProjectiles;

    function CheckSkillAvailable(aAction: TBasicLemmingAction; L: TLemming): Boolean;
    procedure UpdateSkillCount(aAction: TBasicLemmingAction; Amount: Integer = -1);

  { lemming actions }
    function HandleLemming(L: TLemming): Boolean;
      function CheckLevelBoundaries(L: TLemming) : Boolean;
      //procedure WrapLemming(L: TLemming; WrapPosX, WrapPosY: Integer);
    function HandleWalking(L: TLemming): Boolean;
    function HandleAscending(L: TLemming): Boolean;
    function HandleDigging(L: TLemming): Boolean;
    function HandleClimbing(L: TLemming): Boolean;
    function HandleDrowning(L: TLemming): Boolean;
    function HandleHoisting(L: TLemming): Boolean;
    function HandleBuilding(L: TLemming): Boolean;
    function HandleBashing(L: TLemming): Boolean;
    function HandleMining(L: TLemming): Boolean;
    function HandleFalling(L: TLemming): Boolean;
    function HandleBallooning(L: TLemming): Boolean;
    function HandleFloating(L: TLemming): Boolean;
    function HandleSplatting(L: TLemming): Boolean;
    function HandleExiting(L: TLemming): Boolean;
    function HandleVaporizing(L: TLemming): Boolean;
    function HandleVinetrapping(L: TLemming): Boolean;
    function HandleBlocking(L: TLemming): Boolean;
    function HandleShrugging(L: TLemming): Boolean;
    function HandleTimebombing(L: TLemming): Boolean;
    function HandleTimebombFinish(L: TLemming): Boolean;
    function HandleOhNoing(L: TLemming): Boolean;
    function HandleExploding(L: TLemming): Boolean;
    function HandleFreezing(L: TLemming): Boolean;
    function HandleFreezerExplosion(L: TLemming): Boolean;
    function HandleFrozen(L: TLemming): Boolean;
    function HandleUnfreezing(L: TLemming): Boolean;
    function HandleLaddering(L: TLemming): Boolean;
    function HandlePlatforming(L: TLemming): Boolean;
    function LemCanLadder(L: TLemming): Boolean;
    function LemCanPlatform(L: TLemming): Boolean;
    function HandleStacking(L: TLemming): Boolean;
    function HandleSwimming(L: TLemming): Boolean;
    function HandleDrifting(L: TLemming): Boolean;
    function HandleGliding(L: TLemming): Boolean;
    function HandleDisarming(L: TLemming): Boolean;
    function HandleFencing(L: TLemming): Boolean;
    function HandleReaching(L: TLemming) : Boolean;
    function HandleShimmying(L: TLemming) : Boolean;
    function HandleTurning(L: TLemming) : Boolean;
    function HandleJumping(L: TLemming) : Boolean;
    function HandleDehoisting(L: TLemming) : Boolean;
      function LemCanDehoist(L: TLemming; AlreadyMovedX: Boolean): Boolean;
    function HandleSliding(L: TLemming) : Boolean;
      function LemSliderTerrainChecks(L: TLemming; MaxYCheckOffset: Integer = 7): Boolean;
    function HandleDangling(L: TLemming) : Boolean;
    //function HandlePropelling(L: TLemming) : Boolean; // Propeller
    function HandleLasering(L: TLemming) : Boolean;
    function HandleThrowing(L: TLemming) : Boolean;
    //function HandleBatting(L: TLemming) : Boolean; // Batter
    function HandleLooking(L: TLemming) : Boolean;
    function HandleSleeping(L: TLemming): Boolean;

    // Make sure non-Freezer lems can ascend out of Freezer cubes
    procedure BoostAscend(L: TLemming; YBoost: Integer; ShouldTurn: Boolean = False);
    procedure CheckIfShouldBoostAscend(L: TLemming);

  { interaction }
    function AssignNewSkill(Skill: TBasicLemmingAction; IsHighlight: Boolean = False; IsReplayAssignment: Boolean = false): Boolean;
    procedure GenerateClonedLem(L: TLemming);
    function GetPriorityLemming(out PriorityLem: TLemming;
                                  NewSkillOrig: TBasicLemmingAction;
                                  MousePos: TPoint;
                                  IsHighlight: Boolean = False;
                                  IsReplay: Boolean = False): Integer;
    function DoSkillAssignment(L: TLemming; NewSkill: TBasicLemmingAction): Boolean;

    function MayAssignWalker(L: TLemming): Boolean;
    function MayAssignClimber(L: TLemming): Boolean;
    function MayAssignFloaterGlider(L: TLemming): Boolean;
    function MayAssignSwimmer(L: TLemming): Boolean;
    function MayAssignBallooner(L: TLemming) : Boolean;
    function MayAssignDisarmer(L: TLemming): Boolean;
    function MayAssignBlocker(L: TLemming): Boolean;
    function MayAssignTimebomber(L: TLemming): Boolean;
    function MayAssignExploder(L: TLemming): Boolean;
    function MayAssignFreezer(L: TLemming): Boolean;
    function MayAssignBuilder(L: TLemming): Boolean;
    function MayAssignLadderer(L: TLemming): Boolean;
    function MayAssignPlatformer(L: TLemming): Boolean;
    function MayAssignStacker(L: TLemming): Boolean;
    function MayAssignBasher(L: TLemming): Boolean;
    function MayAssignFencer(L: TLemming): Boolean;
    function MayAssignMiner(L: TLemming): Boolean;
    function MayAssignDigger(L: TLemming): Boolean;
    function MayAssignCloner(L: TLemming): Boolean;
    function MayAssignShimmier(L: TLemming) : Boolean;
    function MayAssignJumper(L: TLemming) : Boolean;
    function MayAssignSlider(L: TLemming) : Boolean;
    function MayAssignLaserer(L: TLemming) : Boolean;
    //function MayAssignPropeller(L: TLemming) : Boolean; // Propeller
    function MayAssignThrowingSkill(L: TLemming) : Boolean;

    // For properties
    function GetSkillCount(aSkill: TSkillPanelButton): Integer;
    function GetUsedSkillCount(aSkill: TSkillPanelButton): Integer;

    function GetActiveLemmingTypes: TLemmingKinds;
    function GetOutOfTime: Boolean;

    procedure UpdateLevelRecords;
  public
    GameResultRec              : TGameResultsRec;
    fSelectDx                  : Integer;
    fXmasPal                   : Boolean;
    fActiveSkills              : array[0..MAX_SKILL_TYPES_PER_LEVEL-1] of TSkillPanelButton;
    SpawnIntervalModifier      : Integer; // Negative = decrease each update, positive = increase each update, 0 = no change
    fSpawnIntervalChanged      : Boolean; // Set to true in AdjustSpawnInterval when the SI has changed
    ReplayInsert               : Boolean;

    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  { iteration }
    procedure PrepareParams;
    procedure PlayMusic;
    procedure Start(aReplay: Boolean = False);
    procedure UpdateLemmings;

  { callable }
    // All checks for terrain, objects, etc
    function HasPixelAt(X, Y: Integer): Boolean;
    function HasTriggerAt(X, Y: Integer; TriggerType: TTriggerTypes; L: TLemming = nil): Boolean;
    function HasWaterObjectAt(X, Y: Integer): Boolean;
    function FindGroundPixel(x, y: Integer): Integer;
    function HasSteelAt(x, y: Integer): Boolean;
    function HasIndestructibleAt(x, y, Direction: Integer; Skill: TBasicLemmingAction): Boolean;
    function HasLaserAt(X, Y: Integer): Boolean;
    function HasProjectileAt(X, Y: Integer): Boolean;

    function ShouldExitToPostview: Boolean;
    procedure MaybeExitToPostview;
    function StateIsUnplayable: Boolean;
    procedure CheckAdjustSpawnInterval;
    procedure AdjustSpawnInterval(aSI: Integer);
    function CheckIfLegalSI(aSI: Integer): Boolean;
    procedure Finish(aReason: Integer);
    procedure Cheat;
    procedure HitTest(Autofail: Boolean = false);
    function ProcessSkillAssignment(IsHighlight: Boolean = false): Boolean;
    function ProcessHighlightAssignment: Boolean;
    procedure RegainControl(Force: Boolean = false);
    procedure EnsureCorrectReplayDetails;
    procedure SetGameResult;
    procedure SetSelectedSkill(Value: TSkillPanelButton; MakeActive: Boolean = True; RightClick: Boolean = False);
    procedure SaveGameplayImage(Filename: String);
    function GetSelectedSkill: Integer;
    function Checkpass: Boolean;
    function CheckFinishedTest: Boolean;
    function GetHighlitLemming: TLemming;
    function GetTargetLemming: TLemming;
    function LemIsInCursor(L: TLemming; MousePos: TPoint): Boolean;
    function GetCursorLemmingCount: Integer;
    procedure CheckForNewShadow(aForceRedraw: Boolean = false);
    function SpawnIntervalChanged: Boolean;
    procedure PlayAssignFailSound(PlayForHighlit: Boolean = False);
    procedure PopBalloon(L: TLemming; BalloonPopTimerValue: Integer; NewAction: TBasicLemmingAction);

    procedure ResetSkillCount;
    procedure SetSkillsToInfinite;
    procedure RecordInfiniteSkills;
    procedure RecordInfiniteTime;

    procedure GenerateNewLemming(X, Y: Integer; Left: Boolean; ShiftPressed: Boolean = False; AltPressed: Boolean = False);

  { properties }
    property CurrentIteration: Integer read fCurrentIteration;
    property LemmingsToSpawn: Integer read LemmingsToRelease;
    property SpawnedDead: Integer read fSpawnedDead;
    property LemmingsActive: Integer read LemmingsOut;
    property LemmingsSaved: Integer read LemmingsIn;
    property CurrentSpawnInterval: Integer read CurrSpawnInterval; // For skill panel's usage
    property SkillCount[Index: TSkillPanelButton]: Integer read GetSkillCount;
    property SkillsUsed[Index: TSkillPanelButton]: Integer read GetUsedSkillCount;
    property ClockFrame: Integer read fClockFrame;
    property CursorPoint: TPoint read fCursorPoint write fCursorPoint;
    property GameFinished: Boolean read fGameFinished;
    property CollectiblesCompleted: Boolean read fCollectiblesCompleted write fCollectiblesCompleted;
    property Level: TLevel read fLevel write fLevel;
    property MessageQueue: TGameMessageQueue read fMessageQueue;
    property Playing: Boolean read fPlaying write fPlaying;
    property Renderer: TRenderer read fRenderer;
    property Replaying: Boolean read GetIsReplaying;
    property PauseWasPressed: Boolean read fPauseWasPressed write fPauseWasPressed;
    property ReplayLoaded: Boolean read fReplayLoaded write fReplayLoaded;
    property ReplayingNoRR[isPaused: Boolean]: Boolean read GetIsReplayingNoRR;
    property ReplayManager: TReplay read fReplayManager;
    property IsSelectWalkerHotkey: Boolean read fIsSelectWalkerHotkey write fIsSelectWalkerHotkey;
    property IsSelectUnassignedHotkey: Boolean read fIsSelectUnassignedHotkey write fIsSelectUnassignedHotkey;
    property IsShowAthleteInfo: Boolean read fIsShowAthleteInfo write fIsShowAthleteInfo;
    property IsHighlightHotkey: Boolean read fIsHighlightHotkey write fIsHighlightHotkey;

    property IsBackstepping: Boolean read fIsBackstepping write fIsBackstepping;

    property TargetIteration: Integer read fTargetIteration write fTargetIteration;
    property IsSuperlemmingMode: Boolean read fIsSuperlemmingMode;

    property HitTestAutoFail: Boolean read fHitTestAutoFail write fHitTestAutoFail;
    property IsOutOfTime: Boolean read GetOutOfTime;

    property RenderInterface: TRenderInterface read fRenderInterface;
    property IsSimulating: Boolean read GetIsSimulating;

    property IsInfiniteSkillsMode: Boolean read fIsInfiniteSkillsMode write fIsInfiniteSkillsMode;
    property IsInfiniteTimeMode: Boolean read fIsInfiniteTimeMode write fIsInfiniteTimeMode;
    property NukeIsActive: Boolean read fNukeIsActive write fNukeIsActive;
    property ActiveLemmingTypes: TLemmingKinds read GetActiveLemmingTypes;

    function GetLevelWidth: Integer;
    function GetLevelHeight: Integer;

  { save / load state }
    procedure CreateSavedState(aState: TLemmingGameSavedState);
    procedure LoadSavedState(aState: TLemmingGameSavedState);
  end;

{-------------------------------------------------------------------------------
  The global game mechanics instance, which has to be global  (for now) because
  we have to be able to start/save/load replay from the postview screen.
  GlobalGame is initialized by the mainform.
-------------------------------------------------------------------------------}
var
  GlobalGame: TLemmingGame;

implementation

uses
  LemNeoLevelPack;

const
  LEMMIX_REPLAY_VERSION    = 105;
  MAX_FALLDISTANCE         = 62;

type
  TJumpPattern = array[0..5] of array[0..1] of Integer;

const
  { Each entry in a pattern should only move ONE pixel, be it horizontal or vertical. Horizontal
    movements here are for right-facing lemmings. }
  JUMP_PATTERNS: array[0..8] of TJumpPattern =
  (
    (( 0, -1), ( 0, -1), ( 1,  0), ( 0, -1), ( 0, -1), ( 1,  0)), // Occurs twice
    (( 0, -1), ( 1,  0), ( 0, -1), ( 1,  0), ( 0, -1), ( 1,  0)), // Occurs twice
    (( 0, -1), ( 1,  0), ( 0, -1), ( 1,  0), ( 1,  0), ( 0,  0)),
    (( 0, -1), ( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0), ( 0,  0)),
    (( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0), ( 0,  0), ( 0,  0)),
    (( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0), ( 0,  1), ( 0,  0)),
    (( 1,  0), ( 1,  0), ( 0,  1), ( 1,  0), ( 0,  1), ( 0,  0)),
    (( 1,  0), ( 0,  1), ( 1,  0), ( 0,  1), ( 1,  0), ( 0,  1)), // Occurs twice
    (( 1,  0), ( 0,  1), ( 0,  1), ( 1,  0), ( 0,  1), ( 0,  1))  // Occurs twice
  );

  SUPER_JUMP_PATTERNS: array[0..14] of TJumpPattern =
  (
   (( 0, -1), ( 0, -1), ( 0, -1), ( 1,  0), ( 0, -1), ( 1,  0)),
   (( 0, -1), ( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0), ( 0, -1)),
   (( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0), ( 0, -1), ( 1,  0)),
   (( 1,  0), ( 0, -1), ( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0)), // Occurs 3 times
   (( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0), ( 1,  0), ( 0, -1)),
   (( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0)),
   (( 1,  0), ( 1,  0), ( 1,  0), ( 0, -1), ( 1,  0), ( 1,  0)),
   (( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0)),
   (( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0)),
   (( 0,  1), ( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0), ( 0,  1)),
   (( 1,  0), ( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0), ( 1,  0)),
   (( 0,  1), ( 1,  0), ( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0)), // Occurs 3 times
   (( 0,  1), ( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0), ( 0,  1)),
   (( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0), ( 0,  1), ( 1,  0)),
   (( 0,  1), ( 1,  0), ( 0,  1), ( 0,  1), ( 0,  1), ( 0,  0))
  );

  HOP_JUMP_PATTERNS: array[0..3] of TJumpPattern =
    (
   (( 1,  0), ( 1,  0), ( 1,  0), ( 0,  1), ( 1,  0), ( 1,  0)),
   (( 0,  1), ( 1,  0), ( 0,  1), ( 1,  0), ( 0,  1), ( 0,  1)),
   (( 1,  0), ( 0,  1), ( 0,  1), ( 1,  0), ( 0,  1), ( 0,  1)),
   (( 0,  1), ( 1,  0), ( 0,  1), ( 0,  1), ( 0,  1), ( 0,  1))
  );


const
  // Removal modes
  RM_NEUTRAL           = 0;
  RM_SAVE              = 1;
  RM_KILL              = 2;
  RM_ZOMBIE            = 3;

  HEAD_MIN_Y = -7;
  LEMMING_MAX_Y = 9;

const
  // Order is important, because fTalismans[i].SkillLimit uses the corresponding integers!!!
  // THIS IS NOT THE ORDER THE PICKUP-SKILLS ARE NUMBERED!!!
  ActionListArray: array[0..25] of TBasicLemmingAction =
            (baToWalking, baClimbing, baSwimming, baFloating, baGliding, baFixing,
             baTimebombing, baExploding, baFreezing, baBlocking, baPlatforming, baBuilding,
             baStacking, baBashing, baMining, baDigging, baCloning, baFencing, baShimmying,
             baJumping, baSliding, baLasering, baSpearing, baGrenading,
             baBallooning, baLaddering//, baBatting, baPropelling // Batter // Propeller
             );                       // Double-check these skills are in the correct place after adding them

function CheckRectCopy(const A, B: TRect): Boolean;
begin
  Result := (RectWidth(A) = RectWidth(B))
            and (Rectheight(A) = Rectheight(B));
end;



{ TLemmingGameSavedState }

constructor TLemmingGameSavedState.Create;
begin
  inherited;
  LemmingList := TLemmingList.Create(true);
  ProjectileList := TProjectileList.Create(true);
  Gadgets := TGadgetList.Create(true);
  TerrainLayer := TBitmap32.Create;
  PhysicsMap := TBitmap32.Create;
  ZombieMap := TByteMap.Create;
end;

destructor TLemmingGameSavedState.Destroy;
begin
  LemmingList.Free;
  ProjectileList.Free;
  Gadgets.Free;
  TerrainLayer.Free;
  PhysicsMap.Free;
  ZombieMap.Free;
  inherited;
end;

{ TLemmingGameSavedStateList }

procedure TLemmingGameSavedStateList.TidyList(aCurrentIteration: Integer);
var
  i: Integer;

  function CheckKeepSaveState(aStateIndex: Integer): Boolean;
  const
    MINUTE_IN_FRAMES = 17 * 60;
    HALF_MINUTE_IN_FRAMES = 17 * 30;
    TEN_SECONDS_IN_FRAMES = 17 * 10;
  begin
    Result := false;
    if Items[aStateIndex].CurrentIteration = 0 then
      Result := true;
    if Items[aStateIndex].CurrentIteration mod MINUTE_IN_FRAMES = 0 then
      Result := true;
    if (Items[aStateIndex].CurrentIteration mod HALF_MINUTE_IN_FRAMES = 0)
    and (aCurrentIteration - Items[aStateIndex].CurrentIteration <= MINUTE_IN_FRAMES * 3) then
      Result := true;
    if (Items[aStateIndex].CurrentIteration mod TEN_SECONDS_IN_FRAMES = 0)
    and (aCurrentIteration - Items[aStateIndex].CurrentIteration <= MINUTE_IN_FRAMES) then
      Result := true;
  end;
begin
  { What we want to save:
    -- Last minute: One save every 10 seconds
    -- Last 3 minutes: One save every 30 seconds
    -- Beyond that: One save every minute
    -- Additionally, a save immediately after the level is initially rendered
    This will result in 11 saved states, plus one more for every minute taken
    that isn't in the most recent 3 minutes. This should be manageable. }
  for i := Count-1 downto 0 do
    if not CheckKeepSaveState(i) then Delete(i);
end;

function TLemmingGameSavedStateList.Add: TLemmingGameSavedState;
begin
  // Creates a new TLemmingGameSavedState, adds it, and returns it.
  Result := TLemmingGameSavedState.Create;
  inherited Add(Result);
end;

function TLemmingGameSavedStateList.GetItem(Index: Integer): TLemmingGameSavedState;
begin
  // Gets a TLemmingGameSavedState from the list.
  Result := inherited Get(Index);
end;

function TLemmingGameSavedStateList.FindNearestState(aTargetIteration: Integer): Integer;
var
  i: Integer;
  ClosestFrame: Integer;
begin
  Result := -1;
  ClosestFrame := -1;
  for i := 0 to Count-1 do
    if (Items[i].CurrentIteration < aTargetIteration) and (Items[i].CurrentIteration > ClosestFrame) then
    begin
      Result := i;
      ClosestFrame := Items[i].CurrentIteration;
    end;
end;

procedure TLemmingGameSavedStateList.ClearAfterIteration(aTargetIteration: Integer);
var
  i: Integer;
begin
  for i := Count-1 downto 0 do
    if Items[i].CurrentIteration > aTargetIteration then Delete(i);
end;

{ TLemmingGame }

procedure TLemmingGame.CreateSavedState(aState: TLemmingGameSavedState);
var
  i: Integer;
begin
  // Simple stuff
  aState.SelectedSkill := fSelectedSkill;
  aState.TerrainLayer.Assign(fRenderer.TerrainLayer);
  aState.PhysicsMap.Assign(PhysicsMap);
  aState.ZombieMap.Assign(ZombieMap);
  aState.CurrentIteration := fCurrentIteration;
  aState.ClockFrame := fClockFrame;
  aState.ButtonsRemain := ButtonsRemain;
  aState.CollectiblesRemain := CollectiblesRemain;
  aState.LemmingsToRelease := LemmingsToRelease;
  aState.LemmingsCloned := LemmingsCloned;
  aState.LemmingsOut := LemmingsOut;
  aState.fSpawnedDead := fSpawnedDead;
  aState.LemmingsIn := LemmingsIn;
  aState.LemmingsRemoved := LemmingsRemoved;
  aState.NextLemmingCountdown := NextLemmingCountdown;
  aState.DelayEndFrames := DelayEndFrames;
  aState.TimePlay := TimePlay;
  aState.EntriesOpened := HatchesOpened;
  aState.CurrSpawnInterval := CurrSpawnInterval;

  for i := 0 to Integer(LAST_SKILL_BUTTON) do
  begin
    aState.CurrSkillCount[ActionListArray[i]] := CurrSkillCount[ActionListArray[i]];
    aState.UsedSkillCount[ActionListArray[i]] := UsedSkillCount[ActionListArray[i]];
  end;

  aState.NukeIsActive := NukeIsActive;
  aState.IsInfiniteSkillsMode := IsInfiniteSkillsMode;
  aState.IsInfiniteTimeMode := IsInfiniteTimeMode;
  aState.ExploderAssignInProgress := ExploderAssignInProgress;
  aState.Index_LemmingToBeNuked := Index_LemmingToBeNuked;

  // Lemmings.
  aState.LemmingList.Clear;
  for i := 0 to LemmingList.Count-1 do
  begin
    aState.LemmingList.Add(TLemming.Create);
    aState.LemmingList[i].Assign(LemmingList[i]);
  end;

  // Projectiles.
  aState.ProjectileList.Clear;
  for i := 0 to ProjectileList.Count-1 do
    aState.ProjectileList.Add(TProjectile.CreateAssign(ProjectileList[i]));

  // Objects.
  aState.Gadgets.Clear;
  for i := 0 to Gadgets.Count-1 do
  begin
    aState.Gadgets.Add(TGadget.Create(Gadgets[i]));
    Gadgets[i].AssignTo(aState.Gadgets[i]);
  end;
end;

procedure TLemmingGame.LoadSavedState(aState: TLemmingGameSavedState);
var
  i: Integer;
begin
  // Simple stuff
  fRenderer.TerrainLayer.Assign(aState.TerrainLayer);
  PhysicsMap.Assign(aState.PhysicsMap);
  ZombieMap.Assign(aState.ZombieMap);
  fCurrentIteration := aState.CurrentIteration;
  fClockFrame := aState.ClockFrame;
  ButtonsRemain := aState.ButtonsRemain;
  CollectiblesRemain := aState.CollectiblesRemain;
  LemmingsToRelease := aState.LemmingsToRelease;
  LemmingsCloned := aState.LemmingsCloned;
  LemmingsOut := aState.LemmingsOut;
  fSpawnedDead := aState.fSpawnedDead;
  LemmingsIn := aState.LemmingsIn;
  LemmingsRemoved := aState.LemmingsRemoved;
  NextLemmingCountdown := aState.NextLemmingCountdown;
  DelayEndFrames := aState.DelayEndFrames;
  TimePlay := aState.TimePlay;
  HatchesOpened := aState.EntriesOpened;
  CurrSpawnInterval := aState.CurrSpawnInterval;

  for i := 0 to Integer(LAST_SKILL_BUTTON) do
  begin
    CurrSkillCount[ActionListArray[i]] := aState.CurrSkillCount[ActionListArray[i]];
    UsedSkillCount[ActionListArray[i]] := aState.UsedSkillCount[ActionListArray[i]];
  end;

  NukeIsActive := aState.NukeIsActive;
  IsInfiniteSkillsMode := aState.IsInfiniteSkillsMode;
  IsInfiniteTimeMode := aState.IsInfiniteTimeMode;
  ExploderAssignInProgress := aState.ExploderAssignInProgress;
  Index_LemmingToBeNuked := aState.Index_LemmingToBeNuked;

  // Lemmings.
  LemmingList.Clear;
  for i := 0 to aState.LemmingList.Count-1 do
  begin
    LemmingList.Add(TLemming.Create);
    LemmingList[i].Assign(aState.LemmingList[i]);
    LemmingList[i].LemIndex := i;
  end;

  // Projectiles.
  ProjectileList.Clear;
  for i := 0 to aState.ProjectileList.Count-1 do
  begin
    ProjectileList.Add(TProjectile.CreateAssign(aState.ProjectileList[i]));
    ProjectileList[i].Relink(PhysicsMap, LemmingList);
  end;

  // Objects
  for i := 0 to Gadgets.Count-1 do
  begin
    aState.Gadgets[i].AssignTo(Gadgets[i]);
  end;

  // Recreate Blocker map
  SetBlockerMap;

  SpawnIntervalModifier := 0; // We don't want to continue changing it if it's currently changing
end;

procedure TLemmingGame.DoTalismanCheck;
var
  i: Integer;

  function CheckTalisman(aTalisman: TTalisman): Boolean;
  var
    TotalSkills: Integer;
    TotalSkillTypes: Integer;
    SaveReq: Integer;
    i: TSkillPanelButton;
  begin
    Result := false;

    if aTalisman.RescueCount >= 0 then
      SaveReq := aTalisman.RescueCount
    else
      SaveReq := Level.Info.RescueCount;

    if LemmingsSaved < SaveReq then Exit;
    if (CurrentIteration >= aTalisman.TimeLimit) and (aTalisman.TimeLimit >= 0) then Exit;

    TotalSkills := 0;
    TotalSkillTypes := 0;
    for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    begin
      if (SkillsUsed[i] > aTalisman.SkillLimit[i]) and (aTalisman.SkillLimit[i] >= 0) then Exit;
      Inc(TotalSkills, SkillsUsed[i]);
      if SkillsUsed[i] > 0 then
        Inc(TotalSkillTypes);
    end;

    if (TotalSkills > aTalisman.TotalSkillLimit) and (aTalisman.TotalSkillLimit >= 0) then Exit;
    if (TotalSkillTypes > aTalisman.SkillTypeLimit) and (aTalisman.SkillTypeLimit >= 0) then Exit;

    if (aTalisman.RequireKillZombies) then
      if not AllZombiesKilled then
        Exit;

    if (aTalisman.RequireClassicMode) then
      if not CheckForClassicMode then
        Exit;

    if (aTalisman.RequireNoPause) then
      if not CheckForNoPause then
        Exit;

    Result := true;
  end;
begin
  for i := 0 to Level.Talismans.Count-1 do
  begin
    if CheckTalisman(Level.Talismans[i]) then
    begin
      fTalismanReceived := true;

      if fReplayManager.IsThisUsersReplay then
      begin
        if not GameParams.CurrentLevel.TalismanStatus[Level.Talismans[i].ID] then
          fNewTalismanReceived := true;

        GameParams.CurrentLevel.TalismanStatus[Level.Talismans[i].ID] := true;
      end;
    end;
  end;
end;

function TLemmingGame.CheckForClassicMode: Boolean;
begin
  Result := false;

  // Check if a replay has been loaded
  if ReplayLoaded then Exit;

  // Classic mode has to be active
  if GameParams.ClassicMode then
    Result := true;
end;

function TLemmingGame.CheckForNoPause: Boolean;
begin
  Result := False;

  // Check if a replay has been loaded
  if ReplayLoaded then Exit;

  // Check if pause was pressed
  if PauseWasPressed then Exit;

  Result := True;
end;

function TLemmingGame.AllZombiesKilled: Boolean;
var
  i: Integer;
  ReleaseOffset: Integer;
begin
  Result := false;

  if NukeIsActive then
    Exit;

  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i].LemIsZombie and not LemmingList[i].LemRemoved then
      Exit;

  ReleaseOffset := 0;
  if (LemmingsToRelease - ReleaseOffset > 0) then
  begin
    i := Level.Info.SpawnOrder[Level.Info.LemmingsCount - Level.PreplacedLemmings.Count - LemmingsToRelease + ReleaseOffset];
    if i >= 0 then
      if Gadgets[i].IsPreassignedZombie then
        Exit;
  end;

  Result := true;
end;

function TLemmingGame.LevelHasKillZombiesTalisman: Boolean;
var
  i: Integer;
begin
  Result := False;

  if Level.Talismans.Count > 0 then
  begin
    for i := 0 to Level.Talismans.Count -1 do
      if Level.Talismans[i].RequireKillZombies then
        Result := True;
  end;
end;

function TLemmingGame.ZombiesRemain: Boolean;
var
  i: Integer;
  ReleaseOffset: Integer;
begin
  Result := True;

  // Check if there are any zombies active in the level
  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i].LemIsZombie and not LemmingList[i].LemRemoved then
      Exit;

  // Check pre-assigned lems and hatches
  ReleaseOffset := 0;
  if (LemmingsToRelease - ReleaseOffset > 0) then
  begin
    i := Level.Info.SpawnOrder[Level.Info.LemmingsCount - Level.PreplacedLemmings.Count - LemmingsToRelease + ReleaseOffset];
    if i >= 0 then
      if Gadgets[i].IsPreassignedZombie then
        Exit;
  end;

  Result := False;
end;

function TLemmingGame.Checkpass: Boolean;
begin
  Result := fGameCheated or (LemmingsIn >= Level.Info.RescueCount);
end;

function TLemmingGame.CheckFinishedTest;
var
  i: Integer;
begin
  Result := false;
  if not Checkpass then Exit;

  for i := 0 to Level.Talismans.Count-1 do
    if not GameParams.CurrentLevel.TalismanStatus[Level.Talismans[i].ID] then
      Exit;

  Result := true;
end;

function TLemmingGame.GetLevelWidth: Integer;
begin
  Result := GameParams.Level.Info.Width;
end;

function TLemmingGame.GetOutOfTime: Boolean;
begin
  Result := (Level.Info.HasTimeLimit and not IsInfiniteTimeMode) and
            ((TimePlay < 0) or
             ((TimePlay = 0) and (fClockFrame > 0)));
end;

function TLemmingGame.GetLevelHeight: Integer;
begin
  Result := GameParams.Level.Info.Height;
end;

constructor TLemmingGame.Create(aOwner: TComponent);
var
  P: string;
begin
  inherited Create(aOwner);

  fRenderInterface := TRenderInterface.Create;
  fMessageQueue  := TGameMessageQueue.Create;

  LemmingList    := TLemmingList.Create;
  ProjectileList := TProjectileList.Create;

  TimebomberMask          := TBitmap32.Create;
  BomberMask              := TBitmap32.Create;
  FreezerMask             := TBitmap32.Create;
  BasherMasks             := TBitmap32.Create;
  FencerMasks             := TBitmap32.Create;
  MinerMasks              := TBitmap32.Create;
  GrenadeMask             := TBitmap32.Create;
  SpearMasks              := TBitmap32.Create;
  //BatMask                 := TBitmap32.Create;  // Batter
  LaserMask               := TBitmap32.Create;

  Gadgets        := TGadgetList.Create;
  BlockerMap     := TBitmap32.Create;
  ZombieMap      := TByteMap.Create;
  fReplayManager := TReplay.Create;

  fRenderInterface.LemmingList := LemmingList;
  fRenderInterface.ProjectileList := ProjectileList;
  fRenderInterface.Gadgets := Gadgets;
  fRenderInterface.SetSelectedSkillPointer(fSelectedSkill);
  fRenderInterface.SelectedLemming := nil;
  fRenderInterface.ReplayLemming := nil;
  fRenderInterface.SetSimulateLemRoutine(SimulateLem, SimulateTransition);
  fRenderInterface.SetGetHighlitRoutine(GetHighlitLemming);
  fRenderInterface.SetIsStartingSecondsRoutine(IsStartingSeconds);

  LemmingMethods[baNone]          := nil;
  LemmingMethods[baWalking]       := HandleWalking;
  LemmingMethods[baAscending]     := HandleAscending;
  LemmingMethods[baDigging]       := HandleDigging;
  LemmingMethods[baClimbing]      := HandleClimbing;
  LemmingMethods[baDrowning]      := HandleDrowning;
  LemmingMethods[baHoisting]      := HandleHoisting;
  LemmingMethods[baBuilding]      := HandleBuilding;
  LemmingMethods[baBashing]       := HandleBashing;
  LemmingMethods[baMining]        := HandleMining;
  LemmingMethods[baFalling]       := HandleFalling;
  LemmingMethods[baFloating]      := HandleFloating;
  LemmingMethods[baSplatting]     := HandleSplatting;
  LemmingMethods[baExiting]       := HandleExiting;
  LemmingMethods[baVaporizing]    := HandleVaporizing;
  LemmingMethods[baVinetrapping]  := HandleVinetrapping;
  LemmingMethods[baBlocking]      := HandleBlocking;
  LemmingMethods[baShrugging]     := HandleShrugging;
  LemmingMethods[baOhnoing]       := HandleOhNoing;
  LemmingMethods[baExploding]     := HandleExploding;
  LemmingMethods[baTimebombing]   := HandleTimebombing;
  LemmingMethods[baTimebombFinish]:= HandleTimebombFinish;
  LemmingMethods[baToWalking]     := HandleWalking; // Should never happen anyway
  LemmingMethods[baLaddering]     := HandleLaddering;
  LemmingMethods[baPlatforming]   := HandlePlatforming;
  LemmingMethods[baStacking]      := HandleStacking;
  LemmingMethods[baFreezing]      := HandleFreezing;
  LemmingMethods[baFreezerExplosion]  := HandleFreezerExplosion;
  LemmingMethods[baFrozen]        := HandleFrozen;
  LemmingMethods[baUnfreezing]    := HandleUnfreezing;
  LemmingMethods[baSwimming]      := HandleSwimming;
  LemmingMethods[baDrifting]      := HandleDrifting;
  LemmingMethods[baGliding]       := HandleGliding;
  LemmingMethods[baFixing]        := HandleDisarming;
  LemmingMethods[baFencing]       := HandleFencing;
  LemmingMethods[baReaching]      := HandleReaching;
  LemmingMethods[baShimmying]     := HandleShimmying;
  LemmingMethods[baTurning]       := HandleTurning;
  LemmingMethods[baJumping]       := HandleJumping;
  LemmingMethods[baDehoisting]    := HandleDehoisting;
  LemmingMethods[baSliding]       := HandleSliding;
  LemmingMethods[baDangling]      := HandleDangling;
  LemmingMethods[baLasering]      := HandleLasering;
  //LemmingMethods[baPropelling]    := HandlePropelling; // Propeller
  LemmingMethods[baSpearing]      := HandleThrowing;
  LemmingMethods[baGrenading]     := HandleThrowing;
  LemmingMethods[baLooking]       := HandleLooking;
  LemmingMethods[baBallooning]    := HandleBallooning;
  //LemmingMethods[baBatting]       := HandleBatting; // Batter
  LemmingMethods[baSleeping]      := HandleSleeping;

  NewSkillMethods[baNone]         := nil;
  NewSkillMethods[baWalking]      := nil;
  NewSkillMethods[baAscending]    := nil;
  NewSkillMethods[baDigging]      := MayAssignDigger;
  NewSkillMethods[baClimbing]     := MayAssignClimber;
  NewSkillMethods[baDrowning]     := nil;
  NewSkillMethods[baHoisting]     := nil;
  NewSkillMethods[baBuilding]     := MayAssignBuilder;
  NewSkillMethods[baBashing]      := MayAssignBasher;
  NewSkillMethods[baMining]       := MayAssignMiner;
  NewSkillMethods[baFalling]      := nil;
  NewSkillMethods[baFloating]     := MayAssignFloaterGlider;
  NewSkillMethods[baSplatting]    := nil;
  NewSkillMethods[baExiting]      := nil;
  NewSkillMethods[baVaporizing]   := nil;
  NewSkillMethods[baVinetrapping] := nil;
  NewSkillMethods[baBlocking]     := MayAssignBlocker;
  NewSkillMethods[baShrugging]    := nil;
  NewSkillMethods[baOhnoing]      := nil;
  NewSkillMethods[baTimebombing]  := MayAssignTimebomber;
  NewSkillMethods[baExploding]    := MayAssignExploder;
  NewSkillMethods[baToWalking]    := MayAssignWalker;
  NewSkillMethods[baLaddering]    := MayAssignLadderer;
  NewSkillMethods[baPlatforming]  := MayAssignPlatformer;
  NewSkillMethods[baStacking]     := MayAssignStacker;
  NewSkillMethods[baFreezing]     := MayAssignFreezer;
  NewSkillMethods[baSwimming]     := MayAssignSwimmer;
  NewSkillMethods[baGliding]      := MayAssignFloaterGlider;
  NewSkillMethods[baFixing]       := MayAssignDisarmer;
  NewSkillMethods[baCloning]      := MayAssignCloner;
  NewSkillMethods[baFencing]      := MayAssignFencer;
  NewSkillMethods[baShimmying]    := MayAssignShimmier;
  NewSkillMethods[baTurning]      := nil;
  NewSkillMethods[baJumping]      := MayAssignJumper;
  NewSkillMethods[baDehoisting]   := nil;
  NewSkillMethods[baSliding]      := MayAssignSlider;
  NewSkillMethods[baDangling]     := nil;
  NewSkillMethods[baLasering]     := MayAssignLaserer;
  //NewSkillMethods[baPropelling]   := MayAssignPropeller; // Propeller
  NewSkillMethods[baSpearing]     := MayAssignThrowingSkill;
  NewSkillMethods[baGrenading]    := MayAssignThrowingSkill;
  NewSkillMethods[baLooking]      := nil;
  NewSkillMethods[baBallooning]   := MayAssignBallooner;
  //NewSkillMethods[baBatting]      := MayAssignBatter; // Batter
  NewSkillMethods[baSleeping]     := nil;

  P := AppPath;

  ButtonsRemain := 0;
  CollectiblesRemain := 0;

  fHitTestAutoFail := false;

  fSimulationDepth := 0;
  fSoundList := TList<string>.Create();
end;

destructor TLemmingGame.Destroy;
begin
  TimebomberMask.Free;
  BomberMask.Free;
  FreezerMask.Free;
  GrenadeMask.Free;
  SpearMasks.Free;
  //BatMask.Free; // Batter
  LaserMask.Free;
  BasherMasks.Free;
  FencerMasks.Free;
  MinerMasks.Free;

  LemmingList.Free;
  ProjectileList.Free;
  Gadgets.Free;
  BlockerMap.Free;
  ZombieMap.Free;
  fReplayManager.Free;
  fRenderInterface.Free;
  fMessageQueue.Free;
  fSoundList.Free;
  inherited Destroy;
end;

procedure TLemmingGame.PlayAssignFailSound(PlayForHighlit: Boolean = False);
var
  SelectedLemming: TLemming;
  HighlitLemming: TLemming;
begin
  SelectedLemming := fRenderInterface.SelectedLemming;
  HighlitLemming := GetHighlitLemming;

  if (SelectedLemming <> nil) then
  begin
    if  (HasSteelAt(SelectedLemming.LemX, SelectedLemming.LemY)
    and (RenderInterface.SelectedSkill in [spbMiner, spbDigger])) then
      CueSoundEffect(SFX_Steel_OWW, SelectedLemming.Position)
    else
      CueSoundEffect(SFX_AssignFail, SelectedLemming.Position);
  end else if (GetHighlitLemming <> nil) and PlayForHighlit then
    begin
    if  (HasSteelAt(HighlitLemming.LemX, HighlitLemming.LemY)
    and (RenderInterface.SelectedSkill in [spbMiner, spbDigger])) then
      CueSoundEffect(SFX_Steel_OWW, HighlitLemming.Position)
    else
      CueSoundEffect(SFX_AssignFail, HighlitLemming.Position);
  end;
end;

procedure TLemmingGame.PlayMusic;
begin
  MessageQueue.Add(GAMEMSG_MUSIC);
end;

procedure TLemmingGame.PrepareParams;

  procedure LoadMask(aDst: TBitmap32; aFilename: String; aCombine: TPixelCombineEvent);
  begin
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + aFilename, aDst);
    aDst.DrawMode := dmCustom;
    aDst.OnPixelCombine := aCombine;
  end;

begin
  fRenderer := GameParams.Renderer; // Set ref
  Level := GameParams.Level;

  fHighlightLemmingID := -1;

  if not fMasksLoaded then
  begin
    LoadMask(TimebomberMask, 'timebomber.png', CombineMaskPixelsNeutral);
    LoadMask(BomberMask, 'bomber.png', CombineMaskPixelsNeutral);
    LoadMask(FreezerMask, 'freezer.png', CombineNoOverwriteFreezer);
    LoadMask(BasherMasks, 'basher.png', CombineMaskPixelsNeutral);  // Combine routines for Laserer, Basher, Fencer and Miner are set when used
    LoadMask(FencerMasks, 'fencer.png', CombineMaskPixelsNeutral);
    LoadMask(MinerMasks, 'miner.png', CombineMaskPixelsNeutral);
    LoadMask(GrenadeMask, 'grenader.png', CombineMaskPixelsNeutral);
    LoadMask(SpearMasks, 'spears.png', CombineNoOverwriteMask);
    //LoadMask(BatMask, 'bat.png', CombineNoOverwriteMask); // Batter
    LoadMask(LaserMask, 'laser.png', CombineMaskPixelsNeutral);
    fMasksLoaded := true;
  end;

  PhysicsMap := Renderer.PhysicsMap;
  RenderInterface.PhysicsMap := PhysicsMap;
end;

procedure TLemmingGame.Start(aReplay: Boolean = False);
var
  i: Integer;
  Gadget: TGadget;

  Skill: TSkillPanelButton;
  InitialSkill: TSkillPanelButton;
begin
  Playing := False;

  // Hyperspeed things
  fTargetIteration := 0;
  fHyperSpeedCounter := 0;
  fHyperSpeed := False;
  fLeavingHyperSpeed := False;
  fPauseOnHyperSpeedExit := False;

  fIsSuperLemmingMode := Level.Info.SuperLemmingMode;

  fIsBackstepping := False;
  fPauseWasPressed := False;
  fReplayLoaded := False;

  fGameFinished := False;
  fGameCheated := False;

  LemmingsToRelease := Level.Info.LemmingsCount;
  LemmingsCloned := 0;
  TimePlay := Level.Info.TimeLimit;
  if not Level.Info.HasTimeLimit then
    TimePlay := 0; // Infinite time

  FillChar(GameResultRec, SizeOf(GameResultRec), 0);
  GameResultRec.gCount  := Level.Info.LemmingsCount;
  GameResultRec.gToRescue := Level.Info.RescueCount;

  LemmingsOut := 0;
  fSpawnedDead := Level.Info.ZombieCount;
  LemmingsIn := 0;
  LemmingsRemoved := 0;
  DelayEndFrames := 0;
  IsSelectWalkerHotkey := False;
  IsSelectUnassignedHotkey := False;
  IsShowAthleteInfo := False;
  IsHighlightHotkey := False;
  fCurrentIteration := 0;
  fClockFrame := 0;
  HatchesOpened := False;
  CollectiblesCompleted := False;

  SpawnIntervalModifier := 0;
  IsInfiniteSkillsMode := False;
  IsInfiniteTimeMode := False;
  NukeIsActive := False;
  ExploderAssignInProgress := False;
  Index_LemmingToBeNuked := 0;
  fParticleFinishTimer := 0;
  LemmingList.Clear;
  ProjectileList.Clear;

  if Level.Info.LevelID <> fReplayManager.LevelID then
  begin
    fReplayManager.Clear(true);
    fReplayManager.LevelName := Level.Info.Title;
    fReplayManager.LevelAuthor := Level.Info.Author;
    fReplayManager.LevelGame := GameParams.BaseLevelPack.Name;
    fReplayManager.LevelRank := GameParams.CurrentGroupName;
    fReplayManager.LevelPosition := GameParams.CurrentLevel.GroupIndex+1;
    fReplayManager.LevelID := Level.Info.LevelID;
    fReplayManager.LevelVersion := Level.Info.LevelVersion;
  end;

  with Level.Info do
  begin
    CurrSpawnInterval := SpawnInterval;
    fSpawnIntervalChanged := false;

    // Set available skills
    for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
      if SkillPanelButtonToAction[Skill] <> baNone then
        CurrSkillCount[SkillPanelButtonToAction[Skill]] := SkillCount[Skill];
    // Initialize used skills
    for i := 0 to Integer(LAST_SKILL_BUTTON) do
      UsedSkillCount[ActionListArray[i]] := 0;
  end;

  NextLemmingCountDown := 20;

  ButtonsRemain := 0;
  CollectiblesRemain := 0;

  // Create the list of interactive objects
  Gadgets.Clear;
  fRenderer.CreateGadgetList(Gadgets);

  with Level do
  for i := 0 to Gadgets.Count - 1 do
  begin
    Gadget := Gadgets[i];
    // Update number of buttons
    if Gadget.TriggerEffect = DOM_BUTTON then
      Inc(ButtonsRemain);

    // Update number of collectibles
    if Gadget.TriggerEffect = DOM_COLLECTIBLE then
      Inc(CollectiblesRemain);
  end;

  InitializeAllTriggerMaps;
  SetGadgetMap;

  AddPreplacedLemmings;

  SetBlockerMap;

  DrawAnimatedGadgets; // First draw needed

  // Force update
  fSelectedSkill := spbNone;
  InitialSkill := spbNone;

  for i := 0 to MAX_SKILL_TYPES_PER_LEVEL-1 do
    fActiveSkills[i] := spbNone;
  i := 0;
  for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    if Skill in Level.Info.Skillset then
    begin
      if InitialSkill = spbNone then InitialSkill := Skill;
      fActiveSkills[i] := Skill;
      Inc(i);

      if i = MAX_SKILL_TYPES_PER_LEVEL then Break;
    end;
  end;
  if InitialSkill <> spbNone then
    SetSelectedSkill(InitialSkill, True); // Default

  fTalismanReceived := false;
  fNewTalismanReceived := false;

  MessageQueue.Clear;

  ReplayInsert := false;
  Playing := True;

  UpdateLevelRecords;
  SoundManager.LoadDefaultSounds;
end;


procedure TLemmingGame.AddPreplacedLemmings;
var
  L: TLemming;
  Lem: TPreplacedLemming;
  i: Integer;

  function CanShimmy: Boolean;
  begin
    Result := HasPixelAt(L.LemX, L.LemY - 9)
           or HasPixelAt(L.LemX, L.LemY - 10);
  end;
begin
  for i := 0 to GameParams.Level.PreplacedLemmings.Count-1 do
  begin
    Lem := GameParams.Level.PreplacedLemmings[i];
    L := TLemming.Create;
    with L do
    begin
      LemIndex := LemmingList.Add(L);
      L.LemIdentifier := 'P' + IntToStr(Lem.X) + '.' + IntToStr(Lem.Y);
      SetFromPreplaced(Lem);

      if Lem.IsShimmier then
      begin
        if CanShimmy then
          Transition(L, baShimmying)
        else
          Transition(L, baReaching);
      end else if Lem.IsBallooner then
        Transition(L, baBallooning)
      else if not HasPixelAt(L.LemX, L.LemY) then
        Transition(L, baFalling)
      else if Lem.IsBlocker and not CheckForOverlappingField(L) then
        Transition(L, baBlocking)
      else
        Transition(L, baWalking);

      if L.LemAction = baFalling then
        L.LemInitialFall := true;

      if Lem.IsZombie then
      begin
        RemoveLemming(L, RM_ZOMBIE, true);
        Dec(fSpawnedDead);
      end;
    end;

    // Out-of-area pre-placed lemmings are automatically saved
    if (Lem.Y <= 0) or (Lem.Y >= PhysicsMap.Height + LEMMING_MAX_Y)
    or (Lem.X <= 0) or (Lem.X >= PhysicsMap.Width - 1) then
    begin
      RemoveLemming(L, RM_SAVE);
      CueExitSound(L);
    end;

    Dec(LemmingsToRelease);
    Inc(LemmingsOut);
  end;

  FixDuplicatePreplacedLemmingIdentifiers;
end;

procedure TLemmingGame.FixDuplicatePreplacedLemmingIdentifiers;
var
  i, i2: Integer;

  BaseName: String;
  Suffix: Integer;

  function BuildModifiedName(aBaseName: String; aModifier: Integer): String;
  begin
    if aModifier = 0 then
      Result := aBaseName
    else
      Result := aBaseName + '.' + LeadZeroStr(aModifier, 3);
  end;
begin
  for i := 0 to LemmingList.Count-1 do
  begin
    BaseName := LemmingList[i].LemIdentifier;
    Suffix := 0;
    i2 := 0;

    while i2 < i do
    begin
      if LemmingList[i2].LemIdentifier = BuildModifiedName(BaseName, Suffix) then
      begin
        i2 := 0;
        Inc(Suffix);
        Continue;
      end;

      Inc(i2);
    end;

    LemmingList[i].LemIdentifier := BuildModifiedName(BaseName, Suffix);
  end;
end;

procedure TLemmingGame.CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32; E: Cardinal);
// Copy masks to world
begin
  if (AlphaComponent(F) <> 0) and (B and E = 0) then B := B and not PM_TERRAIN;
end;

{ Not sure who wrote this (probably me), but upon seeing this I forgot what the hell they were
  for. The pixel in "E" is excluded, IE: anything that matches even one bit of E, will not be
  removed when applying the mask. }
procedure TLemmingGame.CombineMaskPixelsUpLeft(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYRIGHT or PM_ONEWAYDOWN;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsUpRight(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYLEFT or PM_ONEWAYDOWN;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsLeft(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYRIGHT or PM_ONEWAYDOWN or PM_ONEWAYUP;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsRight(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYLEFT or PM_ONEWAYDOWN or PM_ONEWAYUP;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsDownLeft(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYRIGHT or PM_ONEWAYUP;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsDownRight(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYLEFT or PM_ONEWAYUP;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsNeutral(F: TColor32; var B: TColor32; M: Cardinal);
var
  E: TColor32;
begin
  E := PM_STEEL;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineNoOverwriteMask(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if (B and PM_SOLID = 0) and (AlphaComponent(F) <> 0) then B := (B or PM_SOLID);
end;

procedure TLemmingGame.CombineNoOverwriteFreezer(F: TColor32; var B: TColor32; M: Cardinal);
// Copy Freezer to world
begin
  if (B and PM_SOLID = 0) and (AlphaComponent(F) <> 0) then B := (B or PM_SOLID);
end;


function TLemmingGame.HasPixelAt(X, Y: Integer): Boolean;
begin
  Result := (Y >= 0) and (Y < PhysicsMap.Height) and (X >= 0) and (X < PhysicsMap.Width)
             and (PhysicsMap.Pixel[X, Y] and PM_SOLID <> 0);
end;


procedure TLemmingGame.RemovePixelAt(X, Y: Integer);
begin
  PhysicsMap.PixelS[X, Y] := PhysicsMap.PixelS[X, Y] and not PM_TERRAIN;
end;

procedure TLemmingGame.MoveLemToReceivePoint(L: TLemming; GadgetID: Byte);
var
  Gadget, Gadget2: TGadget;
begin
  Gadget := Gadgets[GadgetID];
  CustomAssert(Gadget.ReceiverId <> 65535, 'Teleporter used without receiver');
  Gadget2 := Gadgets[Gadget.ReceiverId];

  if Gadget.IsFlipPhysics then TurnAround(L);

  // Mirror trigger area, if Upside-Down Flag is valid for exactly one object
  L.LemX := Gadget2.TriggerRect.Left;
  L.LemY := Gadget2.TriggerRect.Top;
end;


function TLemmingGame.ReadZombieMap(X, Y: Integer): Byte;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := ZombieMap.Value[X, Y]
  else
    Result := DOM_NONE; // Whoops, important
end;

procedure TLemmingGame.WriteZombieMap(X, Y: Integer; aValue: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    ZombieMap.Value[X, Y] := ZombieMap.Value[X, Y] or aValue
end;

procedure TLemmingGame.SetZombieField(L: TLemming);
var
  X, Y: Integer;
begin
  with L do
  begin
    for X := LemX - 5 to LemX + 5 do
    for Y := LemY - 6 to LemY + 4 do
      WriteZombieMap(X, Y, 1);
    for Y := LemY - 6 to LemY + 4 do
      WriteZombieMap(LemX + (LemDX * 6), Y, 1);
  end;
end;

function TLemmingGame.CheckForOverlappingField(L: TLemming): Boolean;
var
  X: Integer;
begin
  // Check only the vertices of the new blocker field
  X := L.LemX - 6;
  if L.LemDx = 1 then Inc(X);

  Result :=    HasTriggerAt(X, L.LemY - 6, trBlocker)
            or HasTriggerAt(X + 11, L.LemY - 6, trBlocker)
            or HasTriggerAt(X, L.LemY + 4, trBlocker)
            or HasTriggerAt(X + 11, L.LemY + 4, trBlocker);
end;


procedure TLemmingGame.Transition(L: TLemming; NewAction: TBasicLemmingAction; DoTurn: Boolean = False);
{-------------------------------------------------------------------------------
  Handling of a transition and/or turnaround
-------------------------------------------------------------------------------}
var
  i: Integer;
  OldIsStartingAction: Boolean;
const
  // Number of physics frames for the various lemming actions.
  ANIM_FRAMECOUNT: array[TBasicLemmingAction] of Integer =
    (
     0, // 1 baNone
     4, // 2 baWalking
     8, // 3 baZombieWalking
     1, // 4 baAscending
    16, // 5 baDigging
     8, // 6 baClimbing
    16, // 7 baDrowning
     8, // 8 baHoisting
    16, // 9 baBuilding
    16, // 10 baBashing
    24, // 11 baMining
     4, // 12 baFalling
    17, // 13 baFloating
    16, // 14 baSplatting
     8, // 15 baExiting
    14, // 16 baVaporizing
     9, // 17 baVinetrapping
    16, // 18 baBlocking
     8, // 19 baShrugging
    16, // 20 baTimebombing - same as OhNoing
     1, // 21 baTimebombFinish - same as Exploding
    16, // 22 baOhnoing
     1, // 23 baExploding
     0, // 24 baToWalking
    16, // 25 baPlatforming
     8, // 26 baStacking
     8, // 27 baFreezing
     1, // 28 baFreezerExplosion
     1, // 29 baFrozen
    12, // 30 baUnfreezing
     8, // 31 baSwimming
    17, // 32 baGliding
    16, // 33 baFixing
     0, // 34 baCloning
    16, // 35 baFencing
     8, // 36 baReaching
    20, // 37 baShimmying
     6, // 38 baTurning
    19, // 39 baJumping
     7, // 40 baDehoisting
     1, // 41 baSliding
    16, // 42 baDangling
    10, // 43 baSpearing
    10, // 44 baGrenading
    14, // 45 baLooking
    12, // 46 baLasering - it's, ironically, this high for rendering purposes
    17, // 47 baBallooning
    25, // 48 baLaddering
    8,  // 49 baDrifting
    //10, // batting // Batter
    20  // 50 baSleeping
     //4, // 47 baPropelling // Propeller
    );
begin
  if DoTurn then TurnAround(L);

  // Switch from baToWalking to baWalking
  if NewAction = baToWalking then NewAction := baWalking;

  if L.LemHasBlockerField and not (NewAction in [baTimebombing, baOhNoing, baFreezing]) then
  begin
    L.LemHasBlockerField := False;
    SetBlockerMap;
  end;

  // Transition to faller instead walker, if no pixel below lemming
  if (not HasPixelAt(L.LemX, L.LemY)) and (NewAction = baWalking) then
    NewAction := baFalling;

  // Should not happen, except for assigning walkers to walkers
  if L.LemAction = NewAction then Exit;

  // Makes sure that the Jumper skill shadow is displayed
  if (NewAction = baJumping) and (L.LemAction = baSwimming)
    and not HasPixelAt(L.LemX, L.LemY -1) then
      Dec(L.LemY);

  // Stops invincible lems momentarily transitioning to faller when exploding in water/poison
  if ((L.LemAction in [baTimebombFinish, baExploding]) and L.LemIsInvincible)
    and (HasWaterObjectAt(L.LemX, L.LemY)) then
    begin
      Inc(L.LemY);
      Inc(L.LemX, L.LemDx);
      NewAction := baSwimming;
    end;

  // Set initial fall heights according to previous skill
  if (NewAction = baFalling) then
  begin
     // For Swimming/Drifting it's set in HandleSwimming/Drifting as there is no single universal value
    if not (L.LemAction in [baSwimming, baDrifting]) then
    begin
      L.LemFallen := 1;
      if L.LemAction in [baWalking, baBashing] then L.LemFallen := 3
      else if L.LemAction in [baMining, baDigging] then L.LemFallen := 0
      else if L.LemAction in [baBlocking, baJumping, baLasering, baSpearing, baGrenading] then L.LemFallen := -1;
    end;
    L.LemTrueFallen := L.LemFallen;
  end;

                     // N.B. baReaching here allows Climber to enter Reacher state
  if ((NewAction in [baReaching, baShimmying, baJumping]) and (L.LemAction = baClimbing)) or
     ((NewAction = baJumping) and (L.LemAction = baSliding)) then
  begin
    // Turn around and get out of the wall
    TurnAround(L);
    Inc(L.LemX, L.LemDx);

    if NewAction = baShimmying then
      if HasPixelAt(L.LemX, L.LemY - 8) then
        Inc(L.LemY);
  end;

  if (NewAction = baShimmying) then
  begin
    case L.LemAction of
      baTurning: Inc(L.LemY);

      baSliding: begin
                   Inc(L.LemY, 2);

                   if HasPixelAt(L.LemX, L.LemY - 8) then
                     Inc(L.LemY);
                 end;

      baDehoisting: begin
                      Inc(L.LemY, 2);
                      if HasPixelAt(L.LemX, L.LemY - 9 + 1) then
                        Inc(L.LemY);
                    end;

      baDangling: begin
                    // Adjust starting position of Shimmier according to Dangler position
                    if L.LemPhysicsFrame = 0 then
                      Inc(L.LemY)
                    else if L.LemPhysicsFrame = 2 then
                      Dec(L.LemY)
                    else if L.LemPhysicsFrame >= 3 then
                      Dec(L.LemY, 2);
                  end;

      baJumping: begin
                   for i := -1 to 3 do
                   if HasPixelAt(L.LemX, L.LemY - 9 - i) and not HasPixelAt(L.LemX, L.LemY - 8 - i) then
                   begin
                     L.LemY := L.LemY - i;
                     Break;
                   end;
                 end;
    end;
  end;

  if (NewAction = baFreezerExplosion) and (L.LemAction = baSwimming) then
    L.LemY := L.LemY + 3;

  if (NewAction = baBallooning) and (L.LemAction = baSwimming) then
    L.LemY := L.LemY - 1;

  if (NewAction = baBlocking) and (L.LemAction = baSwimming) then
    L.LemY := L.LemY + 2;

  if NewAction = baDehoisting then
    L.LemDehoistPinY := L.LemY;
  if NewAction = baSliding then
    L.LemDehoistPinY := -1;

  // Change Action
  L.LemAction := NewAction;
  L.LemFrame := 0;
  L.LemPhysicsFrame := 0;
  L.LemEndOfAnimation := False;
  L.LemNumberOfBricksLeft := 0;
  OldIsStartingAction := L.LemIsStartingAction; // Because for some actions (eg baHoisting) we need to restore previous value
  L.LemIsStartingAction := True;
  L.LemInitialFall := False;

  L.LemMaxFrame := -1;
  L.LemMaxPhysicsFrame := ANIM_FRAMECOUNT[NewAction] - 1;

  // Some things to do when entering state
  case L.LemAction of
    baAscending  : L.LemAscended := 0;
    baHoisting   : L.LemIsStartingAction := OldIsStartingAction; // It needs to know what the Climber's value was
    baSplatting  : begin
                     L.LemExplosionTimer := 0;
                     L.LemFreezerExplosionTimer := 0;
                     if L.LemIsZombie then
                       CueSoundEffect(SFX_ZombieSplat, L.Position)
                     else
                       CueSoundEffect(SFX_Splat, L.Position);
                   end;
    baBlocking   : begin
                     L.LemHasBlockerField := True;
                     SetBlockerMap;
                   end;
    baExiting    : begin
                     CueExitSound(L);

                     if not IsOutOfTime then
                     begin
                       L.LemExplosionTimer := 0;
                       L.LemFreezerExplosionTimer := 0;
                     end;
                   end;
    baVaporizing   : begin
                       L.LemExplosionTimer := 0;
                       L.LemFreezerExplosionTimer := 0;
                     end;
    baVinetrapping : begin
                       L.LemExplosionTimer := 0;
                       L.LemFreezerExplosionTimer := 0;
                     end;
    baBuilding   : begin
                     L.LemNumberOfBricksLeft := 12;
                     L.LemConstructivePositionFreeze := false;
                   end;
    baPlatforming: begin
                     L.LemNumberOfBricksLeft := 12;
                     L.LemConstructivePositionFreeze := false;
                   end;
    baStacking   : L.LemNumberOfBricksLeft := 8;
    baOhnoing    : begin
                     // Invincible lems keep all permaskills and don't cue sound effect
                     if L.LemIsInvincible then Exit;
                     
                     if L.LemIsZombie then
                       CueSoundEffect(SFX_ZombieOhNo, L.Position)
                     else
                       CueSoundEffect(SFX_OhNo, L.Position);
                     L.LemIsSlider := false;
                     L.LemIsClimber := false;
                     L.LemIsSwimmer := false;
                     L.LemIsFloater := false;
                     L.LemIsGlider := false;
                     L.LemIsDisarmer := false;
                     L.LemHasBeenOhnoer := true;
                   end;
    baTimebombing :begin
                     // Invincible lems keep all permaskills and don't cue sound effect
                     if L.LemIsInvincible then Exit;

                     if L.LemIsZombie then
                       CueSoundEffect(SFX_ZombieOhNo, L.Position)
                     else
                       CueSoundEffect(SFX_OhNo, L.Position);
                     L.LemIsSlider := false;
                     L.LemIsClimber := false;
                     L.LemIsSwimmer := false;
                     L.LemIsFloater := false;
                     L.LemIsGlider := false;
                     L.LemIsDisarmer := false;
                     L.LemHasBeenOhnoer := true;
                   end;
    baFreezing: CueSoundEffect(SFX_Freeze, L.Position);
    baTimebombFinish: CueSoundEffect(SFX_Pop, L.Position);
    baExploding: CueSoundEffect(SFX_Pop, L.Position);
    baFreezerExplosion: CueSoundEffect(SFX_Pop, L.Position);
    baSwimming   : begin // If possible, float up 4 pixels when starting
                     i := 0;
                     while (i < 4) and HasWaterObjectAt(L.LemX, L.LemY - i - 1)
                                   and not HasPixelAt(L.LemX, L.LemY - i - 1) do
                       Inc(i);
                     Dec(L.LemY, i);
                   end;
    baFixing     : L.LemDisarmingFrames := 42;
    baJumping    : begin
                     L.LemJumpProgress := 0;
                     L.LemJumperBounceAllowance := 3;
                     CueSoundEffect(SFX_Jump, L.Position);
                   end;
    baLasering   : begin
                     L.LemLaserRemainTime := 10;
                     CueSoundEffect(SFX_Laser, L.Position);
                    end;
    //baPropelling : CueSoundEffect(SFX_Propeller, L.Position); // Propeller
    baBallooning : CueSoundEffect(SFX_BalloonInflate, L.Position);
  end;
end;

procedure TLemmingGame.TurnAround(L: TLemming);
// We assume that the mirrored animations have the same framecount, key frames and physics frames.
// This is safe because current code elsewhere enforces this anyway.
begin
  L.LemDX := -L.LemDX;
end;

function TLemmingGame.UpdateExplosionTimer(L: TLemming): Boolean;
begin
  Result := False;

  // Sleepers cancel explosion timer because lem would have exited
  if (L.LemAction = baSleeping) then
  begin
    L.LemExplosionTimer := 0;
    Exit;
  end;

  Dec(L.LemExplosionTimer);

  DoExplosionCrater := True;

  if NukeIsActive and L.LemIsRadiating then
  begin
    L.LemIsRadiating := False;
  end;

  if L.LemExplosionTimer = 0 then
  begin               // All these states bypass ohno phase
    if L.LemAction in [baJumping, baReaching, baShimmying, baTurning, baClimbing, baSliding,
                      baVaporizing, baVinetrapping, baDrowning, baFreezing, baFrozen,
                      baFloating, baGliding, baBallooning, baSwimming, baDrifting, baFalling] then
    begin
      if L.LemAction = baBallooning then
      begin
        if L.LemIsTimebomber then
          PopBalloon(L, 1, baTimebombFinish)
        else
          PopBalloon(L, 1, baExploding);
      end else if L.LemIsTimebomber then
        Transition(L, baTimebombFinish)
      else
        Transition(L, baExploding);
    end else begin
      if L.LemIsTimebomber then
        Transition(L, baTimebombing)
      else
        Transition(L, baOhnoing);
    end;
    Result := True;
  end;
end;

function TLemmingGame.UpdateFreezerExplosionTimer(L: TLemming): Boolean;
begin
  Result := False;

  if NukeIsActive then
  begin
    if (L.LemFreezerExplosionTimer > 0) then L.LemFreezerExplosionTimer := 0;
    Exit;
  end;

  Dec(L.LemFreezerExplosionTimer);

  if L.LemFreezerExplosionTimer = 0 then
  begin               // All these states bypass freezing phase
    if L.LemAction in [baJumping, baReaching, baShimmying, baTurning, baClimbing, baSliding,
                      baVaporizing, baVinetrapping, baDrowning, baFreezing, baFrozen,
                      baFloating, baGliding, baBallooning, baSwimming, baDrifting, baFalling] then
    begin
      if L.LemAction = baBallooning then
        PopBalloon(L, 1, baFreezerExplosion)
      else
        Transition(L, baFreezerExplosion);
    end else begin
      Transition(L, baFreezing);
    end;
    Result := True;
  end;
end;

procedure TLemmingGame.UpdateFreezingTimer(L: TLemming);
begin
  if L.LemFreezingTimer > 0 then
    Dec(L.LemFreezingTimer);
end;

procedure TLemmingGame.UpdateUnfreezingTimer(L: TLemming);
begin
  if L.LemUnfreezingTimer > 0 then
    Dec(L.LemUnfreezingTimer);
end;

procedure TLemmingGame.UpdateBalloonPopTimer(L: TLemming);
begin
  if L.LemBalloonPopTimer > 0 then
    Dec(L.LemBalloonPopTimer);
end;

function TLemmingGame.StateIsUnplayable: Boolean;
begin
  // Always wait for animations to finish
  Result := (((DelayEndFrames = 0) and (fParticleFinishTimer = 0)))

  // Plus, other conditions...
  and (

  // Ends level if no lemmings remain
  ((LemmingsOut <= 0) and
    {Prevents level ending immediately if there are no pre-placed lems
     and allows nuke whilst there are still lems to spawn}
    (NukeIsActive or (LemmingsToSpawn = 0)) and not
    // Allows nuke animation to play out in full for zombies
    (NukeIsActive and ZombiesRemain) and not
    // Keep playing if there is a Kill All Zombies talisman and active zombies
    (LevelHasKillZombiesTalisman and ZombiesRemain))

  // Ends level if all lems are saved
  or (LemmingsIn >= Level.Info.LemmingsCount + LemmingsCloned)

  // Stops level continuing into overtime when time is up and save req is met
  or (IsOutOfTime and (LemmingsIn >= Level.Info.RescueCount))
  );
end;

function TLemmingGame.ShouldExitToPostview: Boolean;
begin
  Result := False;

  // Only exit to postview if the game is currently unplayable
  if StateIsUnplayable then
    Result := // and we're in Classic Mode
            (GameParams.ClassicMode

            // or the save requirement is met
            or (LemmingsIn >= Level.Info.RescueCount))

            // or the nuke has finished
            or (NukeIsActive and (fParticleFinishTimer = 0));
end;

procedure TLemmingGame.MaybeExitToPostview;
begin
  if fGameFinished then
    Exit;

  if ShouldExitToPostview then
    Finish(GM_FIN_LEMMINGS);
end;

procedure TLemmingGame.SetSkillsToInfinite;
var
  Skill: TSkillPanelButton;
begin
  // Set all skill counts to 100 (infinite)
  with Level.Info do
  begin
    for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    if SkillPanelButtonToAction[Skill] <> baNone then
        CurrSkillCount[SkillPanelButtonToAction[Skill]] := 100;
  end;

  IsInfiniteSkillsMode := True;
end;

procedure TLemmingGame.ResetSkillCount;
var
  Skill: TSkillPanelButton;
begin
  // Reset to original skill count, accounting for any used skills
  with Level.Info do
  begin
    for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    if SkillPanelButtonToAction[Skill] <> baNone then
        CurrSkillCount[SkillPanelButtonToAction[Skill]] := (Level.Info.SkillCount[Skill] - SkillsUsed[Skill]);
  end;

  IsInfiniteSkillsMode := False;
end;

// --- Setting Size of Object Maps --- //

procedure TLemmingGame.InitializeAllTriggerMaps;
begin
  SetLength(WaterMap, 0, 0); // Lines like these are required to clear the arrays
  SetLength(WaterMap, Level.Info.Width, Level.Info.Height);
  SetLength(FireMap, 0, 0);
  SetLength(FireMap, Level.Info.Width, Level.Info.Height);
  SetLength(TeleporterMap, 0, 0);
  SetLength(TeleporterMap, Level.Info.Width, Level.Info.Height);
  SetLength(UpdraftMap, 0, 0);
  SetLength(UpdraftMap, Level.Info.Width, Level.Info.Height);
  SetLength(ButtonMap, 0, 0);
  SetLength(ButtonMap, Level.Info.Width, Level.Info.Height);
  SetLength(CollectibleMap, 0, 0);
  SetLength(CollectibleMap, Level.Info.Width, Level.Info.Height);
  SetLength(PickupMap, 0, 0);
  SetLength(PickupMap, Level.Info.Width, Level.Info.Height);
  SetLength(SplitterMap, 0, 0);
  SetLength(SplitterMap, Level.Info.Width, Level.Info.Height);
  SetLength(NoSplatMap, 0, 0);
  SetLength(NoSplatMap, Level.Info.Width, Level.Info.Height);
  SetLength(SplatMap, 0, 0);
  SetLength(SplatMap, Level.Info.Width, Level.Info.Height);
  SetLength(ExitMap, 0, 0);
  SetLength(ExitMap, Level.Info.Width, Level.Info.Height);
  SetLength(LockedExitMap, 0, 0);
  SetLength(LockedExitMap, Level.Info.Width, Level.Info.Height);
  SetLength(TrapMap, 0, 0);
  SetLength(TrapMap, Level.Info.Width, Level.Info.Height);
  SetLength(ForceLeftMap, 0, 0);
  SetLength(ForceLeftMap, Level.Info.Width, Level.Info.Height);
  SetLength(ForceRightMap, 0, 0);
  SetLength(ForceRightMap, Level.Info.Width, Level.Info.Height);
  SetLength(AnimMap, 0, 0);
  SetLength(AnimMap, Level.Info.Width, Level.Info.Height);
  SetLength(BlasticineMap, 0, 0);
  SetLength(BlasticineMap, Level.Info.Width, Level.Info.Height);
  SetLength(VinewaterMap, 0, 0);
  SetLength(VinewaterMap, Level.Info.Width, Level.Info.Height);
  SetLength(PoisonMap, 0, 0);
  SetLength(PoisonMap, Level.Info.Width, Level.Info.Height);
  SetLength(LavaMap, 0, 0);
  SetLength(LavaMap, Level.Info.Width, Level.Info.Height);
  SetLength(RadiationMap, 0, 0);
  SetLength(RadiationMap, Level.Info.Width, Level.Info.Height);
  SetLength(SlowfreezeMap, 0, 0);
  SetLength(SlowfreezeMap, Level.Info.Width, Level.Info.Height);

  BlockerMap.SetSize(Level.Info.Width, Level.Info.Height);
  BlockerMap.Clear(DOM_NONE);

  ZombieMap.SetSize(Level.Info.Width, Level.Info.Height);
  ZombieMap.Clear(0);
end;


//  BLOCKER MAP TREATMENT

procedure TLemmingGame.WriteBlockerMap(X, Y: Integer; aLemmingIndex: Word; aFieldEffect: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    BlockerMap[X, Y] := (aLemmingIndex shl 8) or aFieldEffect;
end;

function TLemmingGame.ReadBlockerMap(X, Y: Integer; L: TLemming = nil): Byte;
var
  CheckPosX: Integer;
begin
  if (X >= 0) and (X < Level.Info.Width) and (Y >= 0) and (Y < Level.Info.Height) then
  begin
    Result := (BlockerMap[X, Y] and $FF);

    if Result <> DOM_NONE then
      fLastBlockerCheckLem := LemmingList[(BlockerMap[X, Y] shr 8) and $FFFF]
    else
      fLastBlockerCheckLem := nil;

    if fLastBlockerCheckLem <> nil then
    begin
      // For builders, check that this is not the middle part of a newly created blocker area
      // See www.lemmingsforums.net/index.php?topic=3295.0
      if (Result <> DOM_NONE) and (L <> nil) and (L.LemAction = baBuilding) then
      begin
        if fLastBlockerCheckLem.LemDX = L.LemDx then
          CheckPosX := L.LemX + 2 * L.LemDx
        else
          CheckPosX := L.LemX + 3 * L.LemDx;

        if     (L.LemY >= fLastBlockerCheckLem.LemY - 1) and (L.LemY <= fLastBlockerCheckLem.LemY + 3)
           and (fLastBlockerCheckLem.LemX = CheckPosX) then
        begin
          Result := DOM_NONE;
          Exit;
        end;
      end;

      // For simulations check in addition if the trigger area does not come from a blocker with removed terrain under his feet
      if IsSimulating and (Result in [DOM_FORCERIGHT, DOM_FORCELEFT]) then
      begin
        if not HasPixelAt(fLastBlockerCheckLem.LemX, fLastBlockerCheckLem.LemY) then
        begin
          Result := DOM_NONE;
          Exit;
        end;
      end;
    end;
  end
  else
    Result := DOM_NONE; // Whoops, important
end;

procedure TLemmingGame.SetBlockerMap();
var
  i: Integer;

  procedure SetBlockerField(L: TLemming);
  var
    X, Y, Step: Integer;
  begin
    X := L.LemX - 6;
    if L.LemDx = 1 then Inc(X);

    for Step := 0 to 11 do
      for Y := L.LemY - 6 to L.LemY + 4 do
        case Step of
          0..3: WriteBlockerMap(X + Step, Y, i, DOM_FORCELEFT);
          4..7: WriteBlockerMap(X + Step, Y, i, DOM_BLOCKER);
          8..11: WriteBlockerMap(X + Step, Y, i, DOM_FORCERIGHT);
        end;
  end;

begin
  BlockerMap.Clear(DOM_NONE);

  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i].LemHasBlockerField and not LemmingList[i].LemRemoved then
      SetBlockerField(LemmingList[i]);
end;


//  OBJECT MAP TREATMENT

procedure TLemmingGame.WriteTriggerMap(Map: TArrayArrayBoolean; Rect: TRect);
var
  X, Y: Integer;
begin
  for X := Rect.Left to Rect.Right - 1 do
  for Y := Rect.Top to Rect.Bottom - 1 do
    if (X >= 0) and (X < Level.Info.Width) and (Y >= 0) and (Y < Level.Info.Height) then
      Map[X, Y] := True;
end;

function TLemmingGame.ReadTriggerMap(X, Y: Integer; Map: TArrayArrayBoolean): Boolean;
begin
  if (X >= 0) and (X < Level.Info.Width) and (Y >= 0) and (Y < Level.Info.Height) then
    Result := Map[X, Y]
  else
    Result := False;
end;

procedure TLemmingGame.SetGadgetMap;
// WARNING: Only call this after InitializeAllObjectMaps
// Otherwise the maps might already contain trigger areas
var
  i: Integer;
begin
  for i := 0 to Gadgets.Count - 1 do
  begin
    case Gadgets[i].TriggerEffect of
      DOM_EXIT:       WriteTriggerMap(ExitMap, Gadgets[i].TriggerRect);
      DOM_LOCKEXIT: begin
                      WriteTriggerMap(LockedExitMap, Gadgets[i].TriggerRect);
                      if ButtonsRemain = 0 then Gadgets[i].CurrentFrame := 0;
                    end;
      DOM_WATER:      WriteTriggerMap(WaterMap, Gadgets[i].TriggerRect);
      DOM_FIRE:       WriteTriggerMap(FireMap, Gadgets[i].TriggerRect);
      DOM_TRAP:       WriteTriggerMap(TrapMap, Gadgets[i].TriggerRect);
      DOM_TRAPONCE:   WriteTriggerMap(TrapMap, Gadgets[i].TriggerRect);
      DOM_TELEPORT:   WriteTriggerMap(TeleporterMap, Gadgets[i].TriggerRect);
      DOM_UPDRAFT:    WriteTriggerMap(UpdraftMap, Gadgets[i].TriggerRect);
      DOM_PICKUP:     WriteTriggerMap(PickupMap, Gadgets[i].TriggerRect);
      DOM_BUTTON:     WriteTriggerMap(ButtonMap, Gadgets[i].TriggerRect);
      DOM_COLLECTIBLE:WriteTriggerMap(CollectibleMap, Gadgets[i].TriggerRect);
      DOM_SPLITTER:   WriteTriggerMap(SplitterMap, Gadgets[i].TriggerRect);
      DOM_NOSPLAT:    WriteTriggerMap(NoSplatMap, Gadgets[i].TriggerRect);
      DOM_SPLAT:      WriteTriggerMap(SplatMap, Gadgets[i].TriggerRect);
      DOM_FORCELEFT:  WriteTriggerMap(ForceLeftMap, Gadgets[i].TriggerRect);
      DOM_FORCERIGHT: WriteTriggerMap(ForceRightMap, Gadgets[i].TriggerRect);
      DOM_ANIMATION:  WriteTriggerMap(AnimMap, Gadgets[i].TriggerRect);
      DOM_ANIMONCE:   WriteTriggerMap(AnimMap, Gadgets[i].TriggerRect);
      DOM_BLASTICINE: WriteTriggerMap(BlasticineMap, Gadgets[i].TriggerRect);
      DOM_VINEWATER:  WriteTriggerMap(VinewaterMap, Gadgets[i].TriggerRect);
      DOM_POISON:     WriteTriggerMap(PoisonMap, Gadgets[i].TriggerRect);
      DOM_LAVA:       WriteTriggerMap(LavaMap, Gadgets[i].TriggerRect);
      DOM_RADIATION:  WriteTriggerMap(RadiationMap, Gadgets[i].TriggerRect);
      DOM_SLOWFREEZE: WriteTriggerMap(SlowfreezeMap, Gadgets[i].TriggerRect);
    end;
  end;
end;

function TLemmingGame.AssignNewSkill(Skill: TBasicLemmingAction; IsHighlight: Boolean = False; IsReplayAssignment: Boolean = false): Boolean;
const
  PermSkillSet = [baSliding, baClimbing, baFloating, baGliding, baFixing, baSwimming];
var
  L, LQueue: TLemming;
  OldHTAF: Boolean;
begin
  Result := False;

  OldHTAF := HitTestAutoFail;
  HitTestAutoFail := false;

  // Just to be safe, though this should always return in fLemSelected
  GetPriorityLemming(L, Skill, CursorPoint, IsHighlight, IsReplayAssignment);
  // Get lemming to queue the skill assignment
  GetPriorityLemming(LQueue, baNone, CursorPoint, IsHighlight);

  HitTestAutoFail := OldHTAF;

  // Queue skill assignment if current assignment is impossible
  if not Assigned(L) or not CheckSkillAvailable(Skill, L) then
  begin

  if not GameParams.HideSkillQ then
    begin
      if Assigned(LQueue) and not (Skill in PermSkillSet) then
      begin
        LQueue.LemQueueAction := Skill;
        LQueue.LemQueueFrame := 0;
      end;
    end;
  end

  // If the assignment is written in the replay, change lemming state
  else if IsReplayAssignment then
  begin
    Result := DoSkillAssignment(L, Skill);
    if Result then
      CueSoundEffect(SFX_AssignSkill, L.Position);
  end

  // Record new skill assignment to be assigned once we call again UpdateLemmings
  else
  begin
    Result := CheckSkillAvailable(Skill, L);
    if Result then
    begin
      RegainControl;
      RecordSkillAssignment(L, Skill);
    end;
  end;
end;


function TLemmingGame.DoSkillAssignment(L: TLemming; NewSkill: TBasicLemmingAction): Boolean;
begin
  Result := False;

  // We check first, whether the skill is available at all
  if not CheckSkillAvailable(NewSkill, L) then Exit;

  if fDoneAssignmentThisFrame then Exit;

  // Ensures the 'available' count stays the same for invincible lems, whilst still updating the 'used' count as normal
  if L.LemIsInvincible then UpdateSkillCount(NewSkill, 1);

  UpdateSkillCount(NewSkill);

  // Remove queued skill assignment
  L.LemQueueAction := baNone;
  L.LemQueueFrame := 0;

  // Get starting position for stacker
  if (Newskill = baStacking) then L.LemStackLow := not HasPixelAt(L.LemX + L.LemDx, L.LemY);

  { Important! If a builder just placed a brick and part of the previous brick
    got removed, he should not fall if turned into a walker! }
  if     (NewSkill = baToWalking) and (L.LemAction = baBuilding)
     and HasPixelAt(L.LemX, L.LemY - 1) and not HasPixelAt(L.LemX + L.LemDx, L.LemY) then
    L.LemY := L.LemY - 1;

  // Turn around walking lem, if assigned a walker
  if (NewSkill = baToWalking) and (L.LemAction = baWalking) then
  begin
    TurnAround(L);

    // Special treatment if in one-way-field facing the wrong direction
    // See www.lemmingsforums.net/index.php?topic=2640.0
    if    (HasTriggerAt(L.LemX, L.LemY, trForceRight, L) and (L.LemDx = -1))
       or (HasTriggerAt(L.LemX, L.LemY, trForceLeft, L) and (L.LemDx = 1)) then
    begin
      // Go one back to cancel the Inc(L.LemX, L.LemDx) in HandleWalking
      // Unless the Lem will fall down (which is handles already in Transition)
      if HasPixelAt(L.LemX, L.LemY) then
      begin
        L.LemWalkerPositionAdjusted := True;
        Dec(L.LemX, L.LemDx);
      end;
    end;
  end;

  if L.LemAction = baBallooning then
  begin
    if (NewSkill in [baToWalking, baJumping, baShimmying]) then
      // Needs to be 2 because timer gets updated on same frame for these actions
      PopBalloon(L, 2, NewSkill);
  end;

  // Special behavior of permament skills.
  if (NewSkill = baSliding) then L.LemIsSlider := True
  else if (NewSkill = baClimbing) then L.LemIsClimber := True
  else if (NewSkill = baFloating) then L.LemIsFloater := True
  else if (NewSkill = baGliding) then L.LemIsGlider := True
  else if (NewSkill = baFixing) then L.LemIsDisarmer := True
  else if (NewSkill = baSwimming) then
  begin
    L.LemIsSwimmer := True;
    if L.LemAction = baDrowning then Transition(L, baSwimming);
  end
  else if (NewSkill = baTimebombing) then
  begin
    L.LemIsTimebomber := True;
    L.LemExplosionTimer := 85;
    L.LemHideCountdown := False;
  end
  else if (NewSkill = baExploding) then
  begin
    L.LemExplosionTimer := 1;
    L.LemHideCountdown := True;
  end
  else if (NewSkill = baFreezing) then
  begin
    L.LemFreezingTimer := 8;
    L.LemFreezerExplosionTimer := 1;
    if not L.LemIsTimebomber then L.LemHideCountdown := True;
  end
  else if (NewSkill = baCloning) then
  begin
    Inc(LemmingsCloned);
    GenerateClonedLem(L);
  end
  else if (NewSkill = baShimmying) then
  begin                // These actions skip reacher state and go straight to shimmier
    if L.LemAction in [baSliding, baJumping, baDehoisting, baDangling, baTurning] then
      Transition(L, baShimmying)
    else
      Transition(L, baReaching);
  end
  else Transition(L, NewSkill);

  Result := True;
  fDoneAssignmentThisFrame := true;
end;


procedure TLemmingGame.GenerateClonedLem(L: TLemming);
var
  NewL: TLemming;
begin
  CustomAssert(not L.LemIsZombie, 'cloner assigned to zombie');

  NewL := TLemming.Create;
  NewL.Assign(L);
  NewL.LemIndex := LemmingList.Count;
  NewL.LemIdentifier := 'C' + IntToStr(CurrentIteration);
  LemmingList.Add(NewL);
  TurnAround(NewL);
  Inc(LemmingsOut);

  // Avoid moving into terrain, see www.lemmingsforums.net/index.php?topic=2575.0
  if NewL.LemAction = baMining then
  begin
    if NewL.LemPhysicsFrame = 2 then
      ApplyMinerMask(NewL, 1, 0, 0)
    else if (NewL.LemPhysicsFrame >= 3) and (NewL.LemPhysicsFrame < 15) then
      ApplyMinerMask(NewL, 1, -2*NewL.LemDx, -1);
  end
  // Required for turned builders not to walk into air
  // For platformers, see www.lemmingsforums.net/index.php?topic=2530.0
  else if (NewL.LemAction in [baBuilding, baPlatforming]) and (NewL.LemPhysicsFrame >= 9) then
    LayBrick(NewL)
  // If in an early-enough phase of spearing or grenading, create a clone projectile
  else if (NewL.LemAction in [baSpearing, baGrenading]) and (NewL.LemPhysicsFrame <= 4) then
  begin
    ProjectileList.Add(TProjectile.CreateForCloner(PhysicsMap, NewL, ProjectileList[L.LemHoldingProjectileIndex]));
    NewL.LemHoldingProjectileIndex := ProjectileList.Count - 1;
  end;
end;

function TLemmingGame.LemIsInCursor(L: TLemming; MousePos: TPoint): Boolean;
  var
    X, Y: Integer;
  begin
    X := L.LemX - ((L.LemDX + 16) div 2);
    Y := L.LemY - 10;
    Result := PtInRect(Rect(X, Y, X + 13, Y + 13), MousePos);
  end;

function TLemmingGame.GetCursorLemmingCount: Integer;
var
  L: TLemming;
  i: Integer;
  MousePos: TPoint;
begin
  Result := 0;

  // Initialize MousePos as Game's CursorPos property
  MousePos := CursorPoint;

  for i := 0 to (LemmingList.Count - 1) do
  begin
    L := LemmingList.List[i];  // Retrieve the lemming from the list

    if LemIsInCursor(L, MousePos) and not (L.LemRemoved or L.LemTeleporting) then
      Inc(Result);
  end;
end;

function TLemmingGame.GetPriorityLemming(out PriorityLem: TLemming;
                                          NewSkillOrig: TBasicLemmingAction;
                                          MousePos: TPoint;
                                          IsHighlight: Boolean = False;
                                          IsReplay: Boolean = False): Integer;
const
  NonPerm = 0;
  Perm = 1;
  NonWalk = 2;
  Walk = 3;
var
  i, CurPriorityBox: Integer;
  // CurValue = 1, 2, 3, 4: Lem is assignable and in one PriorityBox
  // CurValue = 8: Lem is unassignable, but no zombie
  // CurValue = 9: Lem is zombie
  CurValue: Integer;
  L: TLemming;
  LemIsInBox: Boolean;
  NumLemInCursor: Integer;
  NewSkill: TBasicLemmingAction;

  function GetLemDistance(L: TLemming; MousePos: TPoint): Integer;
  begin
    // We compute the distance to the center of the cursor after 2x-zooming, to have integer values
    Result :=   Sqr(2 * (L.LemX - 8) - 2 * MousePos.X + 13)
              + Sqr(2 * (L.LemY - 10) - 2 * MousePos.Y + 13)
  end;

  function IsCloserToCursorCenter(LOld, LNew: TLemming; MousePos: TPoint): Boolean;
  begin
    Result := (GetLemDistance(LNew, MousePos) < GetLemDistance(LOld, MousePos));
  end;

  function IsLemInPriorityBox(L: TLemming; PriorityBox: Integer): Boolean;
  begin
    Result := True;
    case PriorityBox of
      Perm    : Result :=     L.HasPermanentSkills;
      NonPerm : Result :=     (L.LemAction in [baBashing, baFencing, baMining, baDigging,
                                               baBuilding, baLaddering, baPlatforming, baStacking,
                                               baBlocking, baShrugging, baReaching, baShimmying,
                                               baTurning, baLasering, baLooking]);
      Walk    : Result :=     (L.LemAction in [baWalking, baAscending]);
      NonWalk : Result := not (L.LemAction in [baWalking, baAscending]);
    end;
  end;
begin
  PriorityLem := nil;

  if fHitTestAutoFail then
  begin
    Result := 0;
    Exit;
  end;

  NumLemInCursor := 0;
  CurValue := 10;
  if NewSkillOrig = baNone then
  begin
    NewSkill := SkillPanelButtonToAction[fSelectedSkill];
    // Set NewSkill if level has no skill at all in the skillbar
    if NewSkill = baNone then NewSkill := baExploding;
  end
  else
    NewSkill := NewSkillOrig;

  for i := (LemmingList.Count - 1) downto 0 do
  begin
    L := LemmingList.List[i];

    // Check if we only look for highlighted Lems
    if (IsHighlight and not (L = GetHighlitLemming))
    or (IsReplay and not (L = GetTargetLemming)) then Continue;
    // Does Lemming exist
    if L.LemRemoved or L.LemTeleporting then Continue;
    // Is the Lemming unable to receive skills, because zombie, neutral, or was-ohnoer? (remove unless we haven't yet had any lem under the cursor)
    if L.CannotReceiveSkills and Assigned(PriorityLem) then Continue;
    // Is Lemming inside cursor (only check if we are not using Hightlightning!)
    if (not LemIsInCursor(L, MousePos)) and (not (IsHighlight or IsReplay)) then Continue;
    // Directional select
    if (fSelectDx <> 0) and (fSelectDx <> L.LemDx) and (not (IsHighlight or IsReplay)) then Continue;
    // Select only walkers
    if IsSelectWalkerHotkey and (L.LemAction <> baWalking) and (not (IsHighlight or IsReplay)) then Continue;

    // Increase number of lemmings in cursor (if not a zombie or neutral)
    if not L.CannotReceiveSkills then Inc(NumLemInCursor);

    // Determine priority class of current lemming
    if IsSelectUnassignedHotkey or IsSelectWalkerHotkey then
      CurPriorityBox := 1
    else
    begin
      CurPriorityBox := 0;
      repeat
        LemIsInBox := IsLemInPriorityBox(L, CurPriorityBox {PriorityBoxOrder[CurPriorityBox]});
        Inc(CurPriorityBox);
      until (CurPriorityBox > MinIntValue([CurValue, 4])) or LemIsInBox;
    end;

    // Can this lemmings actually receive the skill?
    if not NewSkillMethods[NewSkill](L) then CurPriorityBox := 8;

    // Deprioritize zombie even when just counting lemmings
    if L.CannotReceiveSkills then CurPriorityBox := 9;

    if     (CurPriorityBox < CurValue)
       or ((CurPriorityBox = CurValue) and IsCloserToCursorCenter(PriorityLem, L, MousePos)) then
    begin
      // New top priority lemming found
      PriorityLem := L;
      CurValue := CurPriorityBox;
    end;
  end;

  //  Delete PriorityLem if too low-priority and we wish to assign a skill
  if (CurValue > 6) and not (NewSkillOrig = baNone) then PriorityLem := nil;

  Result := NumLemInCursor;
end;

function TLemmingGame.GetActiveLemmingTypes: TLemmingKinds;
var
  i: Integer;
  G: TGadget;
  L: TLemming;
begin
  Result := [];

  for i := 0 to LemmingList.Count-1 do
  begin
    L := LemmingList[i];
    if L.LemRemoved then Continue;

    if not (L.LemIsZombie or L.LemIsNeutral) then Include(Result, lkNormal);
    if L.LemIsZombie then Include(Result, lkZombie);
    if L.LemIsNeutral then Include(Result, lkNeutral);
  end;

  for i := (Level.Info.LemmingsCount - Level.PreplacedLemmings.Count - LemmingsToRelease) to Length(Level.Info.SpawnOrder) - 1 do
  begin
    G := Gadgets[Level.Info.SpawnOrder[i]];
    if not (G.IsPreassignedZombie or G.IsPreassignedNeutral) then Include(Result, lkNormal);
    if G.IsPreassignedZombie then Include(Result, lkZombie);
    if G.IsPreassignedNeutral then Include(Result, lkNeutral);
  end;

  // Ahh, wish Delphi had LINQ...
end;

function TLemmingGame.MayAssignWalker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBlocking, baPlatforming, baBuilding, baLaddering,
               baStacking, baBashing, baFencing, baMining, baDigging, baBallooning,
               baReaching, baShimmying, baTurning, baLasering, baDangling, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignSlider(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDrowning, baVaporizing, baVinetrapping,
               baSplatting, baExiting, baSleeping];

begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsSlider;
end;

function TLemmingGame.MayAssignClimber(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDrowning, baDangling, baVaporizing,
               baVinetrapping, baSplatting, baExiting, baSleeping];

begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsClimber;
end;

function TLemmingGame.MayAssignFloaterGlider(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDrowning, baDangling, baSplatting,
               baVaporizing, baVinetrapping, baExiting, baSleeping];

begin
  Result := (not (L.LemAction in ActionSet)) and not (L.LemIsFloater or L.LemIsGlider);
end;

function TLemmingGame.MayAssignSwimmer(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDangling, baVaporizing, baVinetrapping,
               baSplatting, baExiting, baSleeping];   // Does NOT contain baDrowning!
begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsSwimmer;
end;

function TLemmingGame.MayAssignBallooner(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baDangling, baVaporizing, baVinetrapping, baDrowning,
               baTurning, baSplatting, baExiting, baSleeping, baBallooning];
begin
  Result := (not (L.LemAction in ActionSet));
end;

function TLemmingGame.MayAssignDisarmer(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDrowning, baDangling, baSplatting,
               baVaporizing, baVinetrapping, baExiting, baSleeping];

begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsDisarmer;
end;

function TLemmingGame.MayAssignBlocker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baSwimming, baShrugging, baPlatforming, baBuilding,
               baStacking, baLaddering, baBashing, baFencing, baMining, baDigging,
               baLasering, baLooking];

begin
  Result := (L.LemAction in ActionSet) and not CheckForOverlappingField(L);
end;


// Timebomber can be assigned to all states except those in list
function TLemmingGame.MayAssignTimebomber(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDangling, baVaporizing, baVinetrapping,
               baSplatting, baExiting, baSleeping];
begin
  Result := not (L.LemAction in ActionSet)

  // Stops repeat timebomber assignments to same lem, and bomber assignments to timebomber
  // Also prevents assigning timebombers to slowfreezing & radiating lems
  and not ((L.LemExplosionTimer > 0) or (L.LemFreezerExplosionTimer > 0));
end;

// Bomber can be assigned to all states except those in list
function TLemmingGame.MayAssignExploder(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezerExplosion, baDangling, baVaporizing, baVinetrapping,
               baSplatting, baExiting, baSleeping];
begin
  Result := not (L.LemAction in ActionSet)

  // Stops repeat bomber assignments to same lem, and bomber assignments to timebomber
  and not (L.LemExplosionTimer > 0);
end;

function TLemmingGame.MayAssignFreezer(L: TLemming): Boolean;
const
  ActionSet = [baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baSplatting, baDrowning,
               baExiting, baSleeping];
begin
  Result := not (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignBuilder(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baStacking, baLaddering,
               baLasering, baBashing, baFencing, baMining, baDigging, baLooking];
begin
  Result := (L.LemAction in ActionSet)

  // Non-assignable from 1px below the top of the level (prevents wastage)
  and not (L.LemY <= 1);
end;

function TLemmingGame.MayAssignPlatformer(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBuilding, baStacking, baLaddering,
               baBashing, baFencing, baMining, baDigging, baLasering, baLooking];
var
  n: Integer;
begin
  // Next brick must add at least one pixel, but contrary to LemCanPlatform we ignore pixels above the platform
  Result := False;
  for n := 0 to 5 do
    Result := Result or not HasPixelAt(L.LemX + n*L.LemDx, L.LemY);

  // Test current action
  Result := Result and (L.LemAction in ActionSet) and LemCanPlatform(L);
end;

function TLemmingGame.MayAssignLadderer(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBuilding, baStacking, baPlatforming,
               baBashing, baFencing, baMining, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet) and LemCanLadder(L);
end;

function TLemmingGame.MayAssignStacker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baLaddering,
               baBashing, baFencing, baMining, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet)

  // Non-assignable from the top of the level
  and not (L.LemY <= 1);
end;

function TLemmingGame.MayAssignThrowingSkill(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baBashing, baFencing, baMining, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignBasher(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baFencing, baMining, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignFencer(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baBashing, baMining, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignMiner(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baBashing, baFencing, baDigging, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet)
  and not HasIndestructibleAt(L.LemX, L.LemY, L.LemDx, baMining)
end;

//function TLemmingGame.MayAssignPropeller(L: TLemming): Boolean; // Propeller
//const
//  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
//               baBashing, baFencing, baMining, baLasering, baLooking];
//begin
////  Result := (L.LemAction in ActionSet);
////  //and not HasIndestructibleAt(L.LemX, L.LemY - 1, L.LemDx, baPropelling);
//end;

function TLemmingGame.MayAssignDigger(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baBashing, baFencing, baMining, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet)
  and not HasIndestructibleAt(L.LemX, L.LemY, L.LemDx, baDigging);
end;

function TLemmingGame.MayAssignCloner(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baLaddering,
               baStacking, baBallooning, baBashing, baFencing, baMining, baDigging,
               baAscending, baFalling, baFloating, baSwimming, baGliding, baFixing,
               baReaching, baShimmying, baJumping, baLasering, baSpearing, baGrenading,
               baDangling, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignShimmier(L: TLemming) : Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baLaddering,
               baTurning, baClimbing, baSwimming, baStacking, baBashing,
               baFencing, baMining, baDigging, baLasering, baDangling,
               baLooking, baBallooning];
var
  CopyL: TLemming;
  i: Integer;
  OldAction: TBasicLemmingAction;
begin
  Result := (L.LemAction in ActionSet);

  if L.LemAction = baTurning then
  begin
    // Only allow Shimmier assignment once the lem has turned
    Result := (L.LemFrame >= 2);

  end else if L.LemAction = baClimbing then
  begin
    // Check whether the lemming would fall down the next frame
    CopyL := TLemming.Create;
    CopyL.Assign(L);
    CopyL.LemIsPhysicsSimulation := true;

    SimulateLem(CopyL, False);

    if ((CopyL.LemAction = baFalling) and (CopyL.LemDX = -L.LemDX)) or
        (CopyL.LemAction = baSliding) then
      if HasPixelAt(CopyL.LemX, CopyL.LemY - 9) or HasPixelAt(CopyL.LemX, CopyL.LemY - 8) then
        Result := True;

    CopyL.Free;
  end else if L.LemAction in [baDehoisting, baSliding, baDangling] then
  begin
    // Check whether the lemming would fall down the next frame
    CopyL := TLemming.Create;
    CopyL.Assign(L);
    CopyL.LemIsPhysicsSimulation := true;
    OldAction := CopyL.LemAction;

    SimulateLem(CopyL, False);

    if (CopyL.LemAction <> OldAction) and (CopyL.LemDX = L.LemDX) and
       ((OldAction <> baDehoisting) or (CopyL.LemAction <> baSliding) or (OldAction <> baDangling)) then
      Result := True;

    CopyL.Free;
  end else if L.LemAction = baJumping then
  begin
    for i := -1 to 3 do
      if HasPixelAt(L.LemX, L.LemY - 9 - i) and not HasPixelAt(L.LemX, L.LemY - 8 - i) then
      begin
        Result := true;
        Break;
      end;
  end;
end;

function TLemmingGame.MayAssignJumper(L: TLemming) : Boolean;
const
  ActionSet = [baWalking, baDigging, baBuilding, baBashing, baMining, baLaddering,
               baShrugging, baPlatforming, baStacking, baFencing, baBallooning,
               baClimbing, baSliding, baDangling, baLasering, baLooking];
begin
  Result := (L.LemAction in ActionSet)
         or ((L.LemAction = baSwimming) and not HasPixelAt(L.LemX, L.LemY -1));
end;

function TLemmingGame.MayAssignLaserer(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baLaddering,
               baBashing, baFencing, baMining, baDigging, baLooking];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.GetGadgetCheckPositions(L: TLemming): TArrayArrayInt;
// The intermediate checks are made according to www.lemmingsforums.net/index.php?topic=2604.7
var
  CurrPosX, CurrPosY: Integer;
  n: Integer;

  procedure SaveCheckPos;
  begin
    Result[0, n] := CurrPosX;
    Result[1, n] := CurrPosY;
    Inc(n);
  end;

  procedure MoveHorizontal;
  begin
    while CurrPosX <> L.LemX do
    begin
      Inc(CurrPosX, sign(L.LemX - CurrPosX));
      SaveCheckPos;
    end;
  end;

  procedure MoveVertical;
  begin
    while CurrPosY <> L.LemY do
    begin
      Inc(CurrPosY, sign(L.LemY - CurrPosY));
      SaveCheckPos;
    end;
  end;

  procedure HandleJumperMovement;
  var
    i: Integer;
  begin
    for i := 0 to 5 do
    begin
      if (L.LemJumpPositions[i, 0] < 0) or (L.LemJumpPositions[i, 1] < 0) then
        Break;

      CurrPosX := L.LemJumpPositions[i, 0];
      CurrPosY := L.LemJumpPositions[i, 1];
      SaveCheckPos;
    end;
  end;

begin
  SetLength(Result, 0, 0); // To ensure clearing
  SetLength(Result, 2, 11);

  n := 0;
  CurrPosX := L.LemXOld;
  CurrPosY := L.LemYOld;

  // No movement
  if (L.LemX = L.LemXOld) and (L.LemY = L.LemYOld) then
  begin
    SaveCheckPos;
  end else begin
    if L.LemActionOld = baJumping then
      HandleJumperMovement; // But continue with the rest as normal

    // Special treatment of miners!
    if L.LemActionOld = baMining then
    begin
      // First move one pixel down, if Y-coordinate changed
      if L.LemYOld < L.LemY then
      begin
        Inc(CurrPosY);
        SaveCheckPos;
      end;
      MoveHorizontal;
      MoveVertical;
    end

    // Lem moves up or is faller; exception is made for builders!
    else if ((L.LemY < L.LemYOld) or (L.LemAction = baFalling)) and not (L.LemActionOld = baBuilding) then
    begin
      MoveHorizontal;
      MoveVertical;
    end

    // Lem moves down (or straight) and is no faller; alternatively lem is a builder!
    else begin
      MoveVertical;
      MoveHorizontal;
    end;
  end;
end;

procedure TLemmingGame.ZombieCheckForLaser(L: TLemming);
var
YOffset: Integer;
begin
  if L.LemIsZombie then
  begin
    for YOffset := 0 to 10 do
    begin
      if HasLaserAt(L.LemX, L.LemY - YOffset) then
      begin
        DoExplosionCrater := False;

        if L.LemAction = baBallooning then
          PopBalloon(L, 1, baExploding)
        else
          Transition(L, baExploding);
        Exit;
      end;
    end;
  end;
end;

procedure TLemmingGame.ZombieCheckForProjectiles(L: TLemming);
var
XOffset, YOffset: Integer;
begin
  if L.LemIsZombie then
  begin
    for YOffset := 0 to 15 do
    for XOffset := -6 to 6 do
    begin
      if HasProjectileAt(L.LemX - XOffset, L.LemY - YOffset)
        and not (L.LemAction in [baSpearing, baGrenading]) then
      begin
        DoExplosionCrater := False;

        if L.LemAction = baBallooning then
          PopBalloon(L, 1, baExploding)
        else
          Transition(L, baExploding);
        Exit;
      end;
    end;
  end;
end;


procedure TLemmingGame.CheckTriggerArea(L: TLemming; IsPostTeleportCheck: Boolean = false);
// For intermediate pixels, we call the trigger function according to trigger area
var
  CheckPos: TArrayArrayInt; // Combined list for both X- and Y-coordinates
  i: Integer;
  AbortChecks: Boolean;

  NeedShiftPosition: Boolean;
  SavePos: TPoint;
  LemDY: Integer;
begin
  // If this is a post-teleport check, (a) reset previous position and (b) remember new position
  if IsPostTeleportCheck then
  begin
    L.LemXOld := L.LemX;
    L.LemYOld := L.LemY;
    SavePos := Point(L.LemX, L.LemY);
  end;

  // Get positions to check for trigger areas
  CheckPos := GetGadgetCheckPositions(L);

  // Now move through the values in CheckPosX/Y and check for trigger areas
  i := -1;
  AbortChecks := False;
  NeedShiftPosition := False;
  repeat
    Inc(i);

    // Make sure, that we do not move outside the range of CheckPos.
    CustomAssert(i <= Length(CheckPos[0]), 'CheckTriggerArea: CheckPos has not enough entries');
    CustomAssert(i <= Length(CheckPos[1]), 'CheckTriggerArea: CheckPos has not enough entries');

    // Transition if we are at the end position and need to do one
    // Except if we try to splat and there is water at the lemming position - then let this take precedence.
    if (fLemNextAction <> baNone) and ([CheckPos[0, i], CheckPos[1, i]] = [L.LemX, L.LemY])
      and ((fLemNextAction <> baSplatting)
      or not HasWaterObjectAt(L.LemX, L.LemY)) then
    begin
      Transition(L, fLemNextAction);
      if fLemJumpToHoistAdvance then
      begin
        Inc(L.LemFrame, 2);
        Inc(L.LemPhysicsFrame, 2);
      end;

      fLemNextAction := baNone;
      fLemJumpToHoistAdvance := false;
    end;

    // Pickup Skills
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trPickup) then
      HandlePickup(L, CheckPos[0, i], CheckPos[1, i]);

    // Buttons
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trButton) then
      HandleButton(L, CheckPos[0, i], CheckPos[1, i]);

    // Collectibles
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trCollectible) then
      HandleCollectible(L, CheckPos[0, i], CheckPos[1, i]);

    // Radiation
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trRadiation) then
      HandleRadiation(L, CheckPos[0, i], CheckPos[1, i]);

    // Slowfreeze
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trSlowfreeze) then
      HandleSlowfreeze(L, CheckPos[0, i], CheckPos[1, i]);

    { The following objects all involve aborting position checks as they potentially remove the lemming }

    // Exits - priority over all other objects
    if HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trExit) then
      AbortChecks := HandleExit(L, CheckPos[0, i], CheckPos[1, i]);

    // Fire
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trFire)
    // Don't even call HandleFire if lem is invincible
    and not L.LemIsInvincible then
      AbortChecks := HandleFire(L);

    // Water objects - Check only for fatalities here!
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trWater) then
      AbortChecks := HandleWaterFatality(L);
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trBlasticine) then
      AbortChecks := HandleBlasticineFatality(L);
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trVinewater) then
      AbortChecks := HandleVinewaterFatality(L);
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trLava) then
      AbortChecks := HandleLavaFatality(L);

    // Triggered traps and one-shot traps
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trTrap) then
    begin
      // Don't even call HandleTrap if lem is invincible
      if not L.LemIsInvincible then
        AbortChecks := HandleTrap(L, CheckPos[0, i], CheckPos[1, i]);
      // Disarmers move always to final X-position, see www.lemmingsforums.net/index.php?topic=3004.0
      if (L.LemAction = baFixing) then CheckPos[0, i] := L.LemX;
    end;

    // Teleporter
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trTeleport) and not IsPostTeleportCheck then
      AbortChecks := HandleTeleport(L, CheckPos[0, i], CheckPos[1, i]);

    // Splitter (except for blockers / jumpers)
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trSplitter)
                         and not (L.LemAction = baBlocking)
                         and not ((L.LemActionOld = baJumping) or (L.LemAction = baJumping)) then
    begin
      NeedShiftPosition := (L.LemAction in [baClimbing, baSliding, baDehoisting]);
      AbortChecks := HandleSplitter(L, CheckPos[0, i], CheckPos[1, i]);
      NeedShiftPosition := NeedShiftPosition and AbortChecks;
    end;

    // Triggered / one-shot animations - these don't abort checks, but do potentially halt movement for the duration of the animation
    if (not AbortChecks) and HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trAnim) then
      HandleAnimation(L, CheckPos[0, i], CheckPos[1, i]);

    // If the lem was required stop, move him there!
    if AbortChecks then
    begin
      L.LemX := CheckPos[0, i];
      L.LemY := CheckPos[1, i];
    end;

    // Set L.LemInSplitter correctly
    if not HasTriggerAt(CheckPos[0, i], CheckPos[1, i], trSplitter)
       and not ((L.LemActionOld = baJumping) or (L.LemAction = baJumping)) then
      L.LemInSplitter := DOM_NOOBJECT;
  until (CheckPos[0, i] = L.LemX) and (CheckPos[1, i] = L.LemY);

  if NeedShiftPosition then
    Inc(L.LemX, L.LemDX);

  { end of AbortChecks }

  // Check for water object to transition to swimmer/drifter only at final position
  if HasTriggerAt(L.LemX, L.LemY, trWater) then
    HandleWaterSwim(L);
  if HasTriggerAt(L.LemX, L.LemY, trBlasticine) then
    HandleBlasticineSwim(L);
  if HasTriggerAt(L.LemX, L.LemY, trVinewater) then
    HandleVinewaterSwim(L);
  if HasTriggerAt(L.LemX, L.LemY, trLava) then
    HandleLavaSwim(L);
  if HasTriggerAt(L.LemX, L.LemY, trPoison) then
    HandlePoison(L);

  { Check for blocker fields and force-fields | not for Jumpers, as this is handled during movement.
    Also not for miners removing terrain, see www.lemmingsforums.net/index.php?topic=2710.0 }
  if ((L.LemAction <> baMining) or not (L.LemPhysicsFrame in [1, 2])) and
     (L.LemAction <> baJumping) then
  begin
    // Checks specifically for contradictory vertical field/blocker
    for LemDY := 0 to 4 do
    begin
      if HasTriggerAt(L.LemX, L.LemY, trForceLeft, L)
        and not HasTriggerAt(L.LemX, L.LemY -LemDY, trForceRight) then
          HandleForceField(L, -1);

      if HasTriggerAt(L.LemX, L.LemY, trForceRight, L)
        and not HasTriggerAt(L.LemX, L.LemY -LemDY, trForceLeft) then
          HandleForceField(L, 1);

      //This is so lems don't ignore Blockers on one-way fields
      if HasTriggerAt(L.LemX, L.LemY, trForceLeft)
        and HasTriggerAt(L.LemX, L.LemY -LemDY, trForceRight)
          then Inc(L.LemX);

      if HasTriggerAt(L.LemX, L.LemY, trForceRight)
        and HasTriggerAt(L.LemX, L.LemY -LemDY, trForceLeft)
          then Dec(L.LemX);
    end;
  end;

  // Reset any position changes that may have occurred post-teleporter
  if IsPostTeleportCheck then
  begin
    L.LemX := SavePos.X;
    L.LemY := SavePos.Y;
  end;
end;

function TLemmingGame.HasTriggerAt(X, Y: Integer; TriggerType: TTriggerTypes; L: TLemming = nil): Boolean;
// Checks whether the trigger area TriggerType occurs at position (X, Y)
begin
  Result := False;
  fLastBlockerCheckLem := nil;

  case TriggerType of
    trExit:       Result :=     ReadTriggerMap(X, Y, ExitMap)
                             or ((ButtonsRemain = 0) and ReadTriggerMap(X, Y, LockedExitMap));
    trForceLeft:  Result :=     (ReadBlockerMap(X, Y, L) = DOM_FORCELEFT) or ReadTriggerMap(X, Y, ForceLeftMap);
    trForceRight: Result :=     (ReadBlockerMap(X, Y, L) = DOM_FORCERIGHT) or ReadTriggerMap(X, Y, ForceRightMap);
    trTrap:       Result :=     ReadTriggerMap(X, Y, TrapMap);
    trAnim:       Result :=     ReadTriggerMap(X, Y, AnimMap);
    trWater:      Result :=     ReadTriggerMap(X, Y, WaterMap);
    trFire:       Result :=     ReadTriggerMap(X, Y, FireMap);
    trOWLeft:     Result :=     (PhysicsMap.PixelS[X, Y] and PM_ONEWAYLEFT <> 0);
    trOWRight:    Result :=     (PhysicsMap.PixelS[X, Y] and PM_ONEWAYRIGHT <> 0);
    trOWDown:     Result :=     (PhysicsMap.PixelS[X, Y] and PM_ONEWAYDOWN <> 0);
    trOWUp:       Result :=     (PhysicsMap.PixelS[X, Y] and PM_ONEWAYUP <> 0);
    trSteel:      Result :=     (PhysicsMap.PixelS[X, Y] and PM_STEEL <> 0);
    trBlocker:    Result :=     (ReadBlockerMap(X, Y) = DOM_BLOCKER)
                            or  (ReadBlockerMap(X, Y) = DOM_FORCERIGHT)
                            or  (ReadBlockerMap(X, Y) = DOM_FORCELEFT);
    trTeleport:   Result :=     ReadTriggerMap(X, Y, TeleporterMap);
    trPickup:     Result :=     ReadTriggerMap(X, Y, PickupMap);
    trButton:     Result :=     ReadTriggerMap(X, Y, ButtonMap);
    trCollectible:Result :=     ReadTriggerMap(X, Y, CollectibleMap);
    trUpdraft:    Result :=     ReadTriggerMap(X, Y, UpdraftMap);
    trSplitter:    Result :=     ReadTriggerMap(X, Y, SplitterMap);
    trNoSplat:    Result :=     ReadTriggerMap(X, Y, NoSplatMap);
    trSplat:      Result :=     ReadTriggerMap(X, Y, SplatMap);
    trZombie:     Result :=     (ReadZombieMap(X, Y) and 1 <> 0);
    trBlasticine: Result :=     ReadTriggerMap(X, Y, BlasticineMap);
    trVinewater:  Result :=     ReadTriggerMap(X, Y, VinewaterMap);
    trPoison:     Result :=     ReadTriggerMap(X, Y, PoisonMap);
    trLava:       Result :=     ReadTriggerMap(X, Y, LavaMap);
    trRadiation:  Result :=     ReadTriggerMap(X, Y, RadiationMap);
    trSlowfreeze: Result :=     ReadTriggerMap(X, Y, SlowfreezeMap);
  end;
end;

function TLemmingGame.FindGadgetID(X, Y: Integer; TriggerType: TTriggerTypes): Word;
// Finds a suitable object that has the correct trigger type and is not currently active.
var
  GadgetID: Word;
  GadgetFound: Boolean;
  Gadget: TGadget;
begin
  // Because ObjectTypeToTrigger defaults to trZombie, looking for this trigger type is nonsense!
  CustomAssert(TriggerType <> trZombie, 'FindObjectId called for trZombie');

  GadgetID := Gadgets.Count;
  GadgetFound := False;
  repeat
    Dec(GadgetID);
    Gadget := Gadgets[GadgetID];
    // Check correct TriggerType
    if ObjectTypeToTrigger[Gadget.TriggerEffect] = TriggerType then
    begin
      // Check trigger areas for this object
      if PtInRect(Gadget.TriggerRect, Point(X, Y)) then
        GadgetFound := True;
    end;

    // Additional checks for locked exit
    if (Gadget.TriggerEffect = DOM_LOCKEXIT) and not (ButtonsRemain = 0) then
      GadgetFound := False;
    // Additional check for any exit
    if (Gadget.TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT]) and (Gadget.RemainingLemmingsCount = 0) then // We specifically must not use <= 0 here, as -1 = no limit
      GadgetFound := False;

    // Additional checks for triggered traps, triggered animations, teleporters
    if Gadget.Triggered then
      GadgetFound := False;
    // Ignore already used buttons and one-shot traps
    if     (Gadget.TriggerEffect in [DOM_BUTTON, DOM_COLLECTIBLE, DOM_TRAPONCE, DOM_ANIMONCE])
       and (Gadget.CurrentFrame = 0) then  // Other objects have always CurrentFrame = 0, so the first check is needed!
      GadgetFound := False;
    // Ignore already used pickup skills
    if (Gadget.TriggerEffect = DOM_PICKUP) and (Gadget.CurrentFrame mod 2 = 0) then
      GadgetFound := False;
    // Additional check, that the corresponding receiver is inactive
    if     (Gadget.TriggerEffect = DOM_TELEPORT)
       and (Gadgets[Gadget.ReceiverId].Triggered or Gadgets[Gadget.ReceiverId].HoldActive) then
      GadgetFound := False;

  until GadgetFound or (GadgetID = 0);

  if GadgetFound then
    Result := GadgetID
  else
    Result := 65535;
end;


function TLemmingGame.HandleTrap(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := True;

  GadgetID := FindGadgetID(PosX, PosY, trTrap);
  // Exit if there is no Object
  if GadgetID = 65535 then
  begin
    Result := False;
    Exit;
  end;

  // Set ObjectInfos
  Gadget := Gadgets[GadgetID];

  if     L.LemIsDisarmer and HasPixelAt(PosX, PosY) // (PosX, PosY) is the correct current lemming position, due to intermediate checks!
     and not (L.LemAction in [baDehoisting, baSliding, baClimbing, baHoisting, baSwimming,
                              baOhNoing, baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
                              baJumping, baDangling])
  then begin
    // Set action after fixing, if we are moving upwards and haven't reached the top yet
    if (L.LemYOld > L.LemY) and HasPixelAt(PosX, PosY + 1) then L.LemActionNew := baAscending
    else L.LemActionNew := baWalking;

    Gadget.TriggerEffect := DOM_NONE; // Effectively disables the object
    Transition(L, baFixing);
  end
  else
  begin
    // Traps don't affect lems in any of the freezer states
    if L.LemAction in [baFreezing, baFreezerExplosion, baFrozen, baUnfreezing] then Exit;

    // Trigger trap
    Gadget.Triggered := True;
    Gadget.ZombieMode := L.LemIsZombie;
    Gadget.NeutralMode := L.LemIsNeutral;
    // Make sure to remove the blocker field!
    L.LemHasBlockerField := False;
    SetBlockerMap;
    RemoveLemming(L, RM_KILL);
    CueSoundEffect(Gadget.SoundEffectActivate, L.Position);
    DelayEndFrames := MaxIntValue([DelayEndFrames, Gadget.AnimationFrameCount]);

    // Check for one-shot trap and possibly disable it
    if Gadget.TriggerEffect = DOM_TRAPONCE then Gadget.TriggerEffect := DOM_NONE;
  end;
end;


function TLemmingGame.HandleAnimation(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := False;

  if GameParams.NoBackgrounds then
    Exit;

  GadgetID := FindGadgetID(PosX, PosY, trAnim);
  // Exit if there is no Object
  if GadgetID = 65535 then
  begin
    Result := False;
    Exit;
  end;

  // Set ObjectInfos
  Gadget := Gadgets[GadgetID];

  // Trigger trap
  Gadget.Triggered := True;

  CueSoundEffect(Gadget.SoundEffectActivate, L.Position);

  // Check for one-shot animation and possibly disable it
  if Gadget.TriggerEffect = DOM_ANIMONCE then Gadget.TriggerEffect := DOM_NONE;
end;


function TLemmingGame.HandleTeleport(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := False;

  // Exit if lemming is splatting
  if L.LemAction = baSplatting then Exit;
  // Exit if lemming is falling, has ground under his feet and will splat
  if (L.LemAction = baFalling) and HasPixelAt(PosX, PosY) and (L.LemFallen > MAX_FALLDISTANCE) then Exit;

  GadgetID := FindGadgetID(PosX, PosY, trTeleport);

  // Exit if there is no Object
  if GadgetID = 65535 then Exit;

  Result := True;

  Gadget := Gadgets[GadgetID];

  CustomAssert((Gadget.ReceiverID >= 0) and (Gadget.ReceiverID < Gadgets.Count), 'ReceiverID for teleporter out of bounds.');
  CustomAssert(Gadgets[Gadget.ReceiverID].TriggerEffect = DOM_RECEIVER, 'Receiving object for teleporter has wrong trigger effect.');

  Gadget.Triggered := True;
  Gadget.ZombieMode := L.LemIsZombie;
  Gadget.NeutralMode := L.LemIsNeutral;
  CueSoundEffect(Gadget.SoundEffectActivate, L.Position);
  L.LemTeleporting := True;
  Gadget.TeleLem := L.LemIndex;

  // Make sure to remove the blocker field and the Dehoister pin
  L.LemHasBlockerField := False;
  L.LemDehoistPinY := -1;

  SetBlockerMap;

  Gadgets[Gadget.ReceiverID].HoldActive := True;
end;

function TLemmingGame.HandlePickup(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := False;

  GadgetID := FindGadgetID(PosX, PosY, trPickup);
  // Exit if there is no Object
  if GadgetID = 65535 then Exit;

  Gadget := Gadgets[GadgetID];
  Gadget.CurrentFrame := Gadget.CurrentFrame and not $01;

  if not L.LemIsZombie then
  begin
    CueSoundEffect(SFX_Pickup, L.Position);
    UpdateSkillCount(SkillPanelButtonToAction[Gadget.SkillType], Gadget.SkillCount);
  end else begin
    CueSoundEffect(SFX_ZombiePickup, L.Position);
    UpdateSkillCount(SkillPanelButtonToAction[Gadget.SkillType], 0);
  end;
end;

function TLemmingGame.HandleCollectible(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := False;

  GadgetID := FindGadgetID(PosX, PosY, trCollectible);
  // Exit if there is no Object
  if GadgetID = 65535 then Exit;

  Gadget := Gadgets[GadgetID];

  // Zombies deactivate collectibles
  if L.LemIsZombie then
  begin
    Gadget.TriggerEffect := DOM_NONE;
    CueSoundEffect(SFX_ZombiePickup, L.Position);
    Exit;
  end;

  // Play default sound effect if none specified
  if Gadget.SoundEffectActivate = '' then
    CueSoundEffect(SFX_Collect, L.Position)
  else
    CueSoundEffect(Gadget.SoundEffectActivate, L.Position);

  Gadget.Triggered := True;
  Dec(CollectiblesRemain);

  if (CollectiblesRemain = 0) then
  begin
    CollectiblesCompleted := True;
    CueSoundEffect(SFX_CollectAll);

    // Optionally apply invincibility to the first lem who reaches the final collectible
    if Level.Info.InvincibilityMode then
    begin
      if L.LemIsNeutral then L.LemIsNeutral := False;
      L.LemIsInvincible := True;
    end;
  end else
    CollectiblesCompleted := False;
end;

function TLemmingGame.HandleButton(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  n: Integer;
  GadgetID: Word;
begin
  Result := False;

  GadgetID := FindGadgetID(PosX, PosY, trButton);
  // Exit if there is no Object
  if GadgetID = 65535 then Exit;

  Gadget := Gadgets[GadgetID];
  CueSoundEffect(Gadget.SoundEffectActivate, L.Position);
  Gadget.Triggered := True;
  Dec(ButtonsRemain);

  if ButtonsRemain = 0 then
  begin
    for n := 0 to (Gadgets.Count - 1) do
      if Gadgets[n].TriggerEffect = DOM_LOCKEXIT then
      begin
        Gadget := Gadgets[n];
        Gadget.Triggered := True;
        if Gadget.SoundEffectActivate = '' then
          CueSoundEffect(SFX_ExitUnlock, Gadget.Center)
        else
          CueSoundEffect(Gadget.SoundEffectActivate, Gadget.Center);
      end;
  end;
end;

function TLemmingGame.HandleExit(L: TLemming; PosX, PosY: Integer): Boolean;
var
  GadgetID: Word;
  Gadget: TGadget;
begin
  Result := False; // Only see exit trigger area, if it actually used

  if IsOutOfTime and NukeIsActive and (L.LemAction = baOhNoing) then
    Exit;

  GadgetID := FindGadgetID(PosX, PosY, trExit);
  if GadgetID = 65535 then Exit;
  Gadget := Gadgets[GadgetID];

  if Gadget.RemainingLemmingsCount > 0 then
  begin
    Gadget.RemainingLemmingsCount := Gadget.RemainingLemmingsCount - 1;
    if Gadget.RemainingLemmingsCount = 0 then
      CueSoundEffect(Gadget.SoundEffectExhaust, Gadget.Center);
  end;

  { Rival Exit check }
  { Whatever the designation (i.e. Normal or Rival), lems will treat an Exit
    as their own type unless the level provides a mix of both Normals and Rivals }
  L.LemIsInRivalExit := False or (Gadget.IsRivalExit and (Level.Info.RivalCount > 0))
                              or (not Gadget.IsRivalExit and (Level.Info.LemmingsCount - Level.Info.RivalCount = 0));

  Result := True;

  if not IsOutOfTime then
    Transition(L, baExiting)
  else begin
    // Stops the lems from appearing to exit if time has run out
    Transition(L, baSleeping);
    Exit;
  end;
end;

function TLemmingGame.HandleForceField(L: TLemming; Direction: Integer): Boolean;
begin
  Result := False;
  if (L.LemDx = -Direction) and not (L.LemAction in [baDehoisting, baHoisting]) then
  begin
    Result := True;

    // We want to cancel certain actions first
    if (L.LemAction = baPlatforming) then
      Transition(L, baWalking);

    TurnAround(L);

    // Zombies always infect a blocker they bounce off
    if L.LemIsZombie and (fLastBlockerCheckLem <> nil)
      and not (fLastBlockerCheckLem.LemIsZombie or fLastBlockerCheckLem.LemIsInvincible) then
        RemoveLemming(fLastBlockerCheckLem, RM_ZOMBIE);

    // Avoid moving into terrain, see www.lemmingsforums.net/index.php?topic=2575.0
    if L.LemAction = baMining then
    begin
      if L.LemPhysicsFrame = 2 then
        ApplyMinerMask(L, 1, 0, 0)
      else if (L.LemPhysicsFrame >= 3) and (L.LemPhysicsFrame < 15) then
        ApplyMinerMask(L, 1, -2*L.LemDx, -1);
    end
    // Required for turned builders not to walk into air
    else if (L.LemAction = baBuilding) and (L.LemPhysicsFrame >= 9) then
      LayBrick(L)
    else if L.LemAction in [baClimbing, baSliding, baDehoisting] then
    begin
      Inc(L.LemX, L.LemDx); // Move out of the wall
      if not L.LemIsStartingAction then Inc(L.LemY); // Don't move below original position
      Transition(L, baWalking);
    end;
  end;
end;

function TLemmingGame.HandleFire(L: TLemming): Boolean;
begin
  Result := True;

  Transition(L, baVaporizing);
  CueSoundEffect(SFX_Fire, L.Position);
end;

function TLemmingGame.HandleSplitter(L: TLemming; PosX, PosY: Integer): Boolean;
var
  Gadget: TGadget;
  GadgetID: Word;
begin
  Result := False;

  GadgetID := FindGadgetID(PosX, PosY, trSplitter);
  // Exit if there is no Object
  if GadgetID = 65535 then Exit;

  Gadget := Gadgets[GadgetID];
  if not (L.LemInSplitter = GadgetID) then
  begin
    L.LemInSplitter := GadgetID;
    if (Gadget.CurrentFrame = 1) xor (L.LemDX < 0) then
      Result := HandleForceField(L, -L.LemDX);

    if not IsSimulating then
      Gadget.CurrentFrame := 1 - Gadget.CurrentFrame // Swap the possible values 0 and 1
  end;
end;

function TLemmingGame.HandleRadiation(L: TLemming; PosX, PosY: Integer): Boolean;
var
  GadgetID: Word;
  Gadget: TGadget;
begin
  Result := True;

  GadgetID := FindGadgetID(PosX, PosY, trRadiation);
  if GadgetID = 65535 then Exit;
  Gadget := Gadgets[GadgetID];

  if not (L.LemFreezerExplosionTimer > 0) then
    L.LemIsRadiating := True;

  // Prevents repeatedly assigning to the same lemming whilst in trigger area
  if (L.LemExplosionTimer = 0)
  // Radiation doesn't work on Slowfreezing lems
  and not (L.LemFreezerExplosionTimer > 0)
  // Disallowed actions
  and not (L.LemAction in [baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
                          baOhnoing, baTimebombing, baExploding, baTimebombfinish]) then
  begin
    if (Gadget.SRCountdownLength <> 0) then
      L.LemExplosionTimer := ((Gadget.SRCountdownLength * 17) - 1)
    else
      L.LemExplosionTimer := 169;
    L.LemHideCountdown := False;
    L.LemIsTimebomber := True; // Allows Freezers to be assigned without stopping the countdown
  end;
end;

function TLemmingGame.HandleSlowfreeze(L: TLemming; PosX, PosY: Integer): Boolean;
var
  GadgetID: Word;
  Gadget: TGadget;
begin
  Result := True;

  GadgetID := FindGadgetID(PosX, PosY, trSlowfreeze);
  if GadgetID = 65535 then Exit;
  Gadget := Gadgets[GadgetID];

  // Prevents repeatedly assigning to the same lemming whilst in trigger area
  if (L.LemFreezerExplosionTimer = 0)
  // Slowfreeze doesn't work on radiating lems
  and not (L.LemExplosionTimer > 0)
  // Disallowed actions
  and not (L.LemAction in [baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
                          baOhnoing, baTimebombing, baExploding, baTimebombfinish]) then
  begin
    if (Gadget.SRCountdownLength <> 0) then
      L.LemFreezerExplosionTimer := ((Gadget.SRCountdownLength * 17) - 1)
    else
      L.LemFreezerExplosionTimer := 169;
    L.LemHideCountdown := False;
  end;
end;

{ Water objects}

procedure TLemmingGame.StartSwimming(L: TLemming);
begin
  Transition(L, baSwimming);
  CueSoundEffect(SFX_Swim, L.Position);
end;

function TLemmingGame.HandleWaterFatality(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baExploding, baFreezerExplosion, baVaporizing,
               baVinetrapping, baExiting, baSplatting];
begin
  Result := False;

  if not (L.LemIsSwimmer or L.LemIsInvincible) then
  begin
    Result := True;

    if not (L.LemAction in ActionSet) then
    begin
      Transition(L, baDrowning);
      CueSoundEffect(SFX_Drown, L.Position);
    end;
  end;
end;

function TLemmingGame.HandleWaterSwim(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baClimbing, baHoisting, baBlocking,
               baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baExiting, baSplatting];
begin
  Result := True;

  if (L.LemIsSwimmer or L.LemIsInvincible) and not (L.LemAction in ActionSet) then
    StartSwimming(L);
end;

function TLemmingGame.HandleBlasticineFatality(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baExploding, baFreezerExplosion, baVaporizing,
               baVinetrapping, baExiting, baSplatting];
begin
  Result := False;

  if not L.LemIsInvincible then
  begin
    Result := True;

    if not (L.LemAction in ActionSet) then
    begin
      DoExplosionCrater := False;
      Transition(L, baExploding);
    end;
  end;
end;

function TLemmingGame.HandleBlasticineSwim(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baClimbing, baHoisting, baBlocking,
               baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baExiting, baSplatting];
begin
  Result := True;

  if L.LemIsInvincible and not (L.LemAction in ActionSet) then
    StartSwimming(L);
end;

function TLemmingGame.HandleVinewaterFatality(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baExploding, baFreezerExplosion, baVaporizing,
               baVinetrapping, baExiting, baSplatting];
begin
  Result := False;

  if not L.LemIsInvincible then
  begin
    Result := True;

    if not (L.LemAction in ActionSet) then
    begin
      Transition(L, baVinetrapping);
      CueSoundEffect(SFX_Vinetrap, L.Position);
    end;
  end;
end;

function TLemmingGame.HandleVinewaterSwim(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baClimbing, baHoisting, baBlocking,
               baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baExiting, baSplatting];
begin
  Result := True;

  if L.LemIsInvincible and not (L.LemAction in ActionSet) then
    StartSwimming(L);
end;

function TLemmingGame.HandleLavaFatality(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baExploding, baFreezerExplosion, baVaporizing,
               baVinetrapping, baExiting, baSplatting];
begin
  Result := False;

  if not L.LemIsInvincible then
  begin
    Result := True;

    if not (L.LemAction in ActionSet) then
    begin
      Transition(L, baVaporizing);
      CueSoundEffect(SFX_Fire, L.Position);
    end;
  end;
end;

function TLemmingGame.HandleLavaSwim(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baClimbing, baHoisting, baBlocking,
               baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baExiting, baSplatting];
begin
  Result := True;

  if L.LemIsInvincible and not (L.LemAction in ActionSet) then
    StartSwimming(L);
end;

function TLemmingGame.HandlePoison(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baDrifting, baClimbing, baHoisting, baBlocking,
               baTimebombing, baTimebombFinish, baOhnoing, baExploding,
               baFreezing, baFreezerExplosion, baFrozen, baUnfreezing,
               baVaporizing, baVinetrapping, baExiting, baSplatting];
begin
  Result := True;

  if not (L.LemAction in ActionSet) then
  begin
    if not (L.LemIsZombie or L.LemIsInvincible) then
      RemoveLemming(L, RM_ZOMBIE);

    if (L.LemIsSwimmer or L.LemIsInvincible) then
      StartSwimming(L)
    else begin
      Transition(L, baDrifting);
      CueSoundEffect(SFX_Swim, L.Position);
    end;
  end;
end;


procedure TLemmingGame.ApplyFreezerIceCube(L: TLemming);
var
  X: Integer;
begin
  X := L.LemX;
  if L.LemDx = 1 then Inc(X);

  FreezerMask.DrawTo(PhysicsMap, X -8, L.LemY -11);

  if not IsSimulating then // Could happen as a result of slowfreeze objects!
    fRenderInterface.AddTerrainFreezer(X - 8, L.LemY -11);
end;

procedure TLemmingGame.ApplyTimebombMask(L: TLemming);
var
  PosX, PosY: Integer;
begin
  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);
  PosY := L.LemY;

  TimebomberMask.DrawTo(PhysicsMap, PosX - 8, PosY - 14);

  if not IsSimulating then // Could happen as a result of nuking
    fRenderInterface.RemoveTerrain(PosX - 8, PosY - 14, TimebomberMask.Width, TimebomberMask.Height);
end;

procedure TLemmingGame.ApplyExplosionMask(L: TLemming);
var
  PosX, PosY: Integer;
begin
  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);
  PosY := L.LemY;

  BomberMask.DrawTo(PhysicsMap, PosX - 8, PosY - 14);

  if not IsSimulating then // Could happen as a result of nuking
    fRenderInterface.RemoveTerrain(PosX - 8, PosY - 14, BomberMask.Width, BomberMask.Height);
end;

procedure TLemmingGame.ApplySpear(P: TProjectile);
var
  Graphic: TSpearGraphic;
  SrcRect: TRect;
  Hotspot: TPoint;
  Target: TPoint;
begin
  Graphic := P.SpearGraphic;
  SrcRect := SPEAR_GRAPHIC_RECTS[Graphic];
  Hotspot := P.SpearHotspot;
  Target := Point(P.X, P.Y);

  SpearMasks.DrawTo(PhysicsMap, Target.X - Hotspot.X, Target.Y - Hotspot.Y, SrcRect);

  if not IsSimulating then
    fRenderInterface.AddTerrainSpear(P);
end;

//procedure TLemmingGame.ApplyBat(P: TProjectile); // Batter
//var
//  Hotspot: TPoint;
//begin
//  Hotspot := P.SpearHotspot;
//
//  BatMask.DrawTo(PhysicsMap, P.X - Hotspot.X, P.Y - Hotspot.Y);
//end;

procedure TLemmingGame.ApplyGrenadeExplosionMask(P: TProjectile);
begin
  GrenadeMask.DrawTo(PhysicsMap, P.X - 9, P.Y - 9);

  if not IsSimulating then
    fRenderInterface.RemoveTerrain(P.X - 9, P.Y - 9, GrenadeMask.Width, GrenadeMask.Height);
end;

procedure TLemmingGame.ApplyBashingMask(L: TLemming; MaskFrame: Integer);
var
  S, D: TRect;
begin
  // Basher mask = 16 x 10

  S := Rect(0, 0, 16, 10);

  if L.LemDx = 1 then
  begin
    BasherMasks.OnPixelCombine := CombineMaskPixelsRight;
    MoveRect(S, 16, MaskFrame * 10);
  end else begin
    BasherMasks.OnPixelCombine := CombineMaskPixelsLeft;
    MoveRect(S, 0, MaskFrame * 10);
  end;

  D.Left := L.LemX - 8;
  D.Top := L.LemY - 10;
  D.Right := D.Left + 16;
  D.Bottom := D.Top + 10;

  CustomAssert(CheckRectCopy(D, S), 'bash rect err');

  BasherMasks.DrawTo(PhysicsMap, D, S);

  // Only change the PhysicsMap if simulating stuff
  if not IsSimulating then
    fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);
end;

procedure TLemmingGame.ApplyFencerMask(L: TLemming; MaskFrame: Integer);
var
  S, D: TRect;
begin
  // Fencer mask = 16 x 10

  S := Rect(0, 0, 16, 10);

  if L.LemDx = 1 then
  begin
    FencerMasks.OnPixelCombine := CombineMaskPixelsUpRight;
    MoveRect(S, 16, MaskFrame * 10);
  end else begin
    FencerMasks.OnPixelCombine := CombineMaskPixelsUpLeft;
    MoveRect(S, 0, MaskFrame * 10);
  end;

  D.Left := L.LemX - 8;
  D.Top := L.LemY - 10;
  D.Right := D.Left + 16;
  D.Bottom := D.Top + 10;

  CustomAssert(CheckRectCopy(D, S), 'fence rect err');

  FencerMasks.DrawTo(PhysicsMap, D, S);

  // Only change the PhysicsMap if simulating stuff
  if not IsSimulating then
    // Delete these pixels from the terrain layer
    fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);
end;

procedure TLemmingGame.ApplyLaserMask(P: TPoint; L: TLemming);
var
  D, S: TRect;
  DOrigin: TPoint;
  TargetRect: TRect;
begin
  if L.LemDX = 1 then
  begin
    LaserMask.OnPixelCombine := CombineMaskPixelsUpRight;
    TargetRect := Rect(L.LemX, 0, Level.Info.Width, L.LemY);
  end else begin
    LaserMask.OnPixelCombine := CombineMaskPixelsUpLeft;
    TargetRect := Rect(0, 0, L.LemX + 1, L.LemY);
  end;

  D.Left := P.X - 4;
  D.Top := P.Y - 4;
  D.Right := P.X + 4 + 1;
  D.Bottom := P.Y + 4 + 1;

  DOrigin := D.TopLeft;

  D := TRect.Intersect(D, TargetRect);

  S := Rect(D.Left - DOrigin.X, D.Top - DOrigin.Y, D.Right - DOrigin.X, D.Bottom - DOrigin.Y);

  LaserMask.DrawTo(PhysicsMap, D, S);

  if not IsSimulating then
    fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);
end;

procedure TLemmingGame.ApplyMinerMask(L: TLemming; MaskFrame, AdjustX, AdjustY: Integer);
// The miner mask is usually centered at the feet of L
// AdjustX, AdjustY lets one adjust the position of the miner mask relative to this
var
  MaskX, MaskY: Integer;
  S, D: TRect;
begin
  CustomAssert((MaskFrame >=0) and (MaskFrame <= 1), 'miner mask error');

  MaskX := L.LemX + L.LemDx - 8 + AdjustX;
  MaskY := L.LemY + MaskFrame - 12 + AdjustY;

  S := Rect(0, 0, 16, 13);

  if L.LemDx = 1 then
  begin
    MinerMasks.OnPixelCombine := CombineMaskPixelsDownRight;
    MoveRect(S, 16, MaskFrame * 13);
  end else begin
    MinerMasks.OnPixelCombine := CombineMaskPixelsDownLeft;
    MoveRect(S, 0, MaskFrame * 13);
  end;

  D.Left := MaskX;
  D.Top := MaskY;
  D.Right := MaskX + RectWidth(S);
  D.Bottom := MaskY + RectHeight(S);

  CustomAssert(CheckRectCopy(D, S), 'miner rect error');

  MinerMasks.DrawTo(PhysicsMap, D, S);

  // Delete these pixels from the terrain layer
  if not IsSimulating then
    fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);
end;


procedure TLemmingGame.DrawAnimatedGadgets;
var
  i, f: Integer;
  Gadget : TGadget;
begin

  for i := 0 to Gadgets.Count-1 do
  begin
    Gadget := Gadgets[i];
    if Gadget.TriggerEffect = DOM_DECORATION then
    begin
      Gadget.Left := Gadget.Left + Gadget.Movement(True, CurrentIteration); // X-movement
      Gadget.Top := Gadget.Top + Gadget.Movement(False, CurrentIteration); // Y-movement

      // Check level borders:
      // The additional "+f" are necessary! Delphi's definition of mod returns negative numbers when passing negative numbers.
      // The following code works only if the coordinates are not too negative, so Asserts are added
      f := Level.Info.Width + Gadget.Width;
      CustomAssert(Gadget.Left + Gadget.Width + f >= 0, 'Animation Object too far left');
      Gadget.Left := ((Gadget.Left + Gadget.Width + f) mod f) - Gadget.Width;

      f := Level.Info.Height + Gadget.Height;
      CustomAssert(Gadget.Top + Gadget.Height + f >= 0, 'Animation Object too far above');
      Gadget.Top := ((Gadget.Top + Gadget.Height + f) mod f) - Gadget.Height;
    end;
  end;
end;


procedure TLemmingGame.CheckForNewShadow(aForceRedraw: Boolean = false);
var
  ShadowSkillButton: TSkillPanelButton;
  ShadowLem: TLemming;
const
  ShadowSkillSet = [spbJumper, spbShimmier, spbLadderer, spbPlatformer, spbBuilder, spbStacker, spbDigger,
                    spbMiner, spbBasher, spbFencer, spbBomber, spbGlider, spbCloner, spbFreezer,
                    spbSpearer, spbGrenader, spbLaserer, spbBallooner];  // Timebomber not included by choice
begin
  if fHyperSpeed then Exit;

  // Get correct skill to draw the shadow
  if Assigned(fLemSelected) and (fSelectedSkill in ShadowSkillSet) then
  begin
    ShadowSkillButton := fSelectedSkill;
    ShadowLem := fLemSelected;
  end else begin
    // Get next highest lemming under the cursor, even if he cannot receive the skill
    GetPriorityLemming(ShadowLem, baNone, CursorPoint);

    // Glider happens if the lemming is a glider, even when other skills are
    if Assigned(ShadowLem) and ShadowLem.LemIsGlider and (ShadowLem.LemAction in [baFalling, baGliding]) then
    begin
      ShadowSkillButton := spbGlider;
    end else begin
      if fRenderInterface.ProjectionType = 0 then
      begin
        ShadowSkillButton := spbNone;
        ShadowLem := nil;
      end else begin
        if Assigned(ShadowLem) then
          ShadowSkillButton := spbNone
        else begin
          ShadowSkillButton := fSelectedSkill;
          ShadowLem := fRenderInterface.SelectedLemming;
        end;
      end;
    end
  end;


  // Check whether we have to redraw the Shadow (if lem or skill changed)
  if aForceRedraw or
     (not fExistShadow) or (not (fLemWithShadow = ShadowLem))
                        or (not (fLemWithShadowButton = ShadowSkillButton)) then
  begin
    if fExistShadow then // False if coming from UpdateLemming
    begin
      // Erase existing ShadowBridge
      fRenderer.ClearShadows;
      fExistShadow := false;
    end;

    // Draw the new ShadowBridge
    try
      if not Assigned(ShadowLem) then Exit;
      if not ((ShadowSkillButton in ShadowSkillSet) or (fRenderInterface.ProjectionType <> 0)) then Exit;

      // Draw the shadows
      fRenderer.DrawShadows(ShadowLem, ShadowSkillButton, fSelectedSkill, false);

      // Remember stats for lemming with shadow
      fLemWithShadow := ShadowLem;
      fLemWithShadowButton := ShadowSkillButton;
      fExistShadow := True;

    except
      // Reset existing shadows
      fLemWithShadow := nil;
      fLemWithShadowButton := fSelectedSkill;
      fExistShadow := False;
    end;
  end;
end;

procedure TLemmingGame.LayLadder(L: TLemming);
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  i: Integer;
  PosX, PosY, FrameOffset: Integer;
  BrickColor: TColor32;
const
  LadderBrick: array[0..8, 0..1] of Integer = (
       (0, 0), (1, 0), (2, 0),
               (1, 1), (2, 1), (3, 1),
                       (2, 2), (3, 2),(4, 2)
               );
begin
  PosX := L.LemX + L.LemDX;
  PosY := L.LemY;

  for i := 0 to Length(LadderBrick) - 1 do
  begin
    if L.LemPhysicsFrame in [10, 12, 14, 16, 18, 20, 22, 24] then
    begin
        case L.LemPhysicsFrame of
          10: FrameOffset := 0;
          12: FrameOffset := 3;
          14: FrameOffset := 6;
          16: FrameOffset := 9;
          18: FrameOffset := 12;
          20: FrameOffset := 15;
          22: FrameOffset := 18;
          24: FrameOffset := 21;
          else Exit;
        end;

      BrickColor := Renderer.BrickPixelColors[(FrameOffset +1) div 2];

      if L.LemDX > 0 then
        AddConstructivePixel((PosX + FrameOffset) + LadderBrick[i, 0],
                             (PosY + FrameOffset) + LadderBrick[i, 1], BrickColor)
      else
        AddConstructivePixel((PosX - FrameOffset) - LadderBrick[i, 0],
                             (PosY + FrameOffset) + LadderBrick[i, 1], BrickColor);
    end;
  end;
end;

procedure TLemmingGame.LayBrick(L: TLemming);
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  n, BrickPosY: Integer;
  BrickColor: TColor32;
begin
  CustomAssert((L.LemNumberOfBricksLeft > 0) and (L.LemNumberOfBricksLeft < 13),
            'Number bricks out of bounds');

  BrickColor := Renderer.BrickPixelColors[12 - L.LemNumberOfBricksLeft];

  // Builders
  if L.LemAction = baBuilding then
  begin
    BrickPosY := L.LemY - 1;

    for n := 0 to 5 do
      AddConstructivePixel(L.LemX + n*L.LemDx, BrickPosY, BrickColor);
  end;

  // Platformers
  if L.LemAction = baPlatforming then
  begin
    BrickPosY := L.LemY;

    for n := 0 to 5 do
    begin
      AddConstructivePixel(L.LemX + n*L.LemDx, BrickPosY, BrickColor);
      AddConstructivePixel(L.LemX + n*L.LemDx, BrickPosY + 1, BrickColor);
    end;
  end;
end;

function TLemmingGame.LayStackBrick(L: TLemming): Boolean;
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  n, BrickPosY, PixPosX: Integer;
  BrickColor: TColor32;
begin
  CustomAssert((L.LemNumberOfBricksLeft > 0) and (L.LemNumberOfBricksLeft < 13),
            'Number stacker bricks out of bounds');

  BrickPosY := L.LemY - 9 + L.LemNumberOfBricksLeft;
  if L.LemStackLow then Inc(BrickPosY);

  BrickColor := Renderer.BrickPixelColors[12 - L.LemNumberOfBricksLeft];

  Result := False;

  for n := 1 to 3 do
  begin
    PixPosX := L.LemX + n*L.LemDx;
    if not HasPixelAt(PixPosX, BrickPosY) then
    begin
      AddConstructivePixel(PixPosX, BrickPosY, BrickColor);
      Result := true;
    end;
  end;
end;

procedure TLemmingGame.AddConstructivePixel(X, Y: Integer; Color: TColor32);
begin
  PhysicsMap.PixelS[X, Y] := PhysicsMap.PixelS[X, Y] or PM_SOLID;
  if not IsSimulating then fRenderInterface.AddTerrainBrick(X, Y, Color);
end;


function TLemmingGame.DigOneRow(PosX, PosY: Integer): Boolean;
// The central pixel of the removed row lies at (PosX, PosY)
var
  n: Integer;
begin
  Result := False;

  For n := -4 to 4 do
  begin
    if HasPixelAt(PosX + n, PosY) and not HasIndestructibleAt(PosX + n, PosY, 0, baDigging) then // We can live with not passing a proper LemDx here
    begin
      RemovePixelAt(PosX + n, PosY);
      if (n > -4) and (n < 4) then Result := True;
    end;

    // Delete these pixels from the terrain layer
    if not IsSimulating then fRenderInterface.RemoveTerrain(PosX - 4, PosY, 9, 1);
  end;
end;

//function TLemmingGame.PropellerOneRow(PosX, PosY: Integer): Boolean; // Propeller
//// The central pixel of the removed row lies at (PosX, PosY)
//var
//  n: Integer;
//begin
//  Result := False;
//
//  For n := -4 to 4 do
//  begin
//    if HasPixelAt(PosX + n, PosY) and not HasIndestructibleAt(PosX + n, PosY, 0, baPropelling) then // We can live with not passing a proper LemDx here
//    begin
//      RemovePixelAt(PosX + n, PosY);
//      if (n > -4) and (n < 4) then Result := True;
//    end;
//
//    // Delete these pixels from the terrain layer
//    if not IsSimulating then fRenderInterface.RemoveTerrain(PosX - 4, PosY, 9, 1);
//  end;
//end;

function TLemmingGame.HandleLasering(L: TLemming): Boolean;
type
  THitType = (htNone, htSolid, htIndestructible, htOutOfBounds);
var
  Target: TPoint;
  i: Integer;
  Hit: Boolean;
  HitUseful: Boolean;
const
  DISTANCE_CAP = 3200;

  function CheckForHit: THitType;
  const
    CHECK_COUNT = 11;
    OFFSET_CHECKS: array[0..CHECK_COUNT-1] of TPoint =
     (
       (X:  1; Y: -1),
       (X:  0; Y: -1),
       (X:  1; Y:  0),
       (X: -1; Y: -1),
       (X: -1; Y: -2),
       (X:  0; Y: -2),
       (X:  1; Y: -2),
       (X:  2; Y: -1),
       (X:  2; Y:  0),
       (X:  2; Y:  2),
       (X:  1; Y:  1)
     );
  var
    n: Integer;
    ThisCheckPoint: TPoint;
  begin
    if (Target.X < -4) or (Target.Y < -4) or (Target.X >= Level.Info.Width + 4) then // Some allowance for graphical niceties
      Result := htOutOfBounds
    else begin
      Result := htNone;

      for n := 0 to CHECK_COUNT-1 do
      begin
        ThisCheckPoint := Point(Target.X + (OFFSET_CHECKS[n].X * L.LemDX), Target.Y + OFFSET_CHECKS[n].Y);

        if HasPixelAt(ThisCheckPoint.X, ThisCheckPoint.Y) then
        begin
          if HasIndestructibleAt(ThisCheckPoint.X, ThisCheckPoint.Y, L.LemDX, baLasering) and (Result <> htSolid) then
            Result := htIndestructible
          else
            Result := htSolid;
        end;
      end;
    end;
  end;
begin
  Result := true;
  if not HasPixelAt(L.LemX, L.LemY) then
    Transition(L, baFalling)
  else begin
    Hit := false;
    HitUseful := false;

    Target := Point(L.LemX + (L.LemDX * 2), L.LemY - 5);
    for i := 0 to DISTANCE_CAP-1 do
      case CheckForHit of
        htNone: begin Inc(Target.X, L.LemDX); Dec(Target.Y); end;
        htSolid: begin Hit := true; HitUseful := true; Break; end;
        htIndestructible: begin Hit := true; Break; end;
        htOutOfBounds: Break;
      end;

    L.LemLaserHitPoint := Target;

    if Hit then
    begin
      L.LemLaserHit := true;
      ApplyLaserMask(Target, L);
    end else
      L.LemLaserHit := false;

    if HitUseful then
      L.LemLaserRemainTime := 10
    else begin
      Dec(L.LemLaserRemainTime);
      if L.LemLaserRemainTime <= 0 then
        Transition(L, baWalking);
    end;
  end;
end;

function TLemmingGame.HandleLemming(L: TLemming): Boolean;
{-------------------------------------------------------------------------------
  This is the main lemming method, called by CheckLemmings().
  The return value should return true if the lemming has to be checked by
  interactive objects.
  o Increment lemming frame
  o Call specialized action-method
  o Do *not* call this method for a removed lemming
-------------------------------------------------------------------------------}
const
  // These are any lemming actions which don't repeat the animation
  OneTimeActionSet = [baDrowning, baHoisting, baSplatting, baExiting,
                      baShrugging, baTimebombing, baOhnoing, baExploding,
                      baFreezerExplosion, baFreezing, baFrozen, baUnfreezing,
                      baReaching, baTurning, baDehoisting, baVaporizing,
                      baVinetrapping, baDangling, baLooking, baLaddering];
begin
  // Remember old position and action for CheckTriggerArea
  L.LemXOld := L.LemX;
  L.LemYOld := L.LemY;
  L.LemDXOld := L.LemDX;
  L.LemActionOld := L.LemAction;
  // No transition to do at the end of lemming movement
  fLemNextAction := baNone;
  fLemJumpToHoistAdvance := false;

  Inc(L.LemFrame);
  Inc(L.LemPhysicsFrame);

  if L.LemPhysicsFrame > L.LemMaxPhysicsFrame then
  begin
    L.LemPhysicsFrame := 0;
    // Floater, Glider and Ballooner start cycle at frame 9!
    if L.LemAction in [baFloating, baGliding, baBallooning] then L.LemPhysicsFrame := 9;
    if L.LemAction in OneTimeActionSet then L.LemEndOfAnimation := True;
  end;

  // Do Lem action
  Result := LemmingMethods[L.LemAction](L);

  if L.LemIsZombie and not IsSimulating then SetZombieField(L);
end;

// Generates a new lemming at the cursor position (LMB + modifiers)
procedure TLemmingGame.GenerateNewLemming(X, Y: Integer; Left: Boolean; ShiftPressed: Boolean = False; AltPressed: Boolean = False);
var
  NewLemming: TLemming;
begin
  // This feature is for test/debug mode only
  {$ifndef debug}
  if GameParams.TestModeLevel = nil then Exit;
  {$endif}

  NewLemming := TLemming.Create;

  with NewLemming do
  begin
    // Add the lemming to the level
    LemIndex := LemmingList.Add(NewLemming);
    LemIdentifier := 'N' + IntToStr(CurrentIteration);

    // Spawn as faller
    Transition(NewLemming, baFalling);
    LemInitialFall := True;

    // Set permaskill properties
    LemIsSlider := False;
    LemIsClimber := False;
    LemIsSwimmer := False;
    LemIsDisarmer := False;
    LemIsFloater := False;
    LemIsGlider := False;

    // Ctrl + Shift generates a Neutral lemming
    LemIsNeutral := ShiftPressed and not AltPressed;

    // Ctrl + Alt generates a Zombie lemming
    LemIsZombie := AltPressed and not ShiftPressed;

    // Ctrl + Shift + Alt generates a Rival lemming
    LemIsRival := ShiftPressed and AltPressed;

    // Set lemming position to cursor
    NewLemming.LemX := CursorPoint.X;
    NewLemming.LemY := CursorPoint.Y;

    // Set direction
    if Left then
      LemDX := -1
    else
      LemDX := 1;
  end;

  Inc(LemmingsOut);
end;

//procedure TLemmingGame.WrapLemming(L: TLemming; WrapPosX, WrapPosY: Integer);
//var
//  X, Y: Integer;
//
//  procedure GenerateWrapLem;
//  var
//    NewL: TLemming;
//  begin
//    NewL := TLemming.Create;
//    NewL.Assign(L);
//    NewL.LemIndex := LemmingList.Count;
//    NewL.LemIdentifier := 'W' + IntToStr(CurrentIteration);
//    LemmingList.Add(NewL);
//    NewL.LemX := X;
//    NewL.LemY := Y;
//    Inc(LemmingsOut);
//  end;
//begin
//  X := WrapPosX;
//  Y := WrapPosY;
//  Inc(LemmingsCloned);
//  GenerateWrapLem;
//  RemoveLemming(L, RM_NEUTRAL, True); // "True" here mutes the sound
//end;

function TLemmingGame.CheckLevelBoundaries(L: TLemming) : Boolean;
begin
  Result := True;

  { /////////////////////////////// Top /////////////////////////////////////// }
  { The top of the level is a forcefield which nudges lems back into the level  }
  { and prevents certain skill assignments/actions from taking place            }
  { /////////////////////////////////////////////////////////////////////////// }

  { /// NOTE - Walkers at the top of the level are handled in HandleWalking /// }

  // The top of the level is a virtual forcefield that nudges lems downwards by at least 1px
  if (L.LemY <= 0) and (L.LemAction = baWalking) then
    Inc(L.LemY)
  else begin
    // Jumpers complete their arc, but are nudged down to keep them visible
    if (L.LemAction = baJumping) and (L.LemY <= 0) then
    begin
      Inc(L.LemY, (2 - L.LemY));

      // Jumpers turn if their arc meets vertically with a pixel at the top of the level
      if HasPixelAt(L.LemX + L.LemDX, 0) then
      begin
        TurnAround(L);
        Inc(L.LemX, L.LemDX);
      end;
    end;

    // Swimmers and Gliders-in-Updrafts are nudged down to keep them visible
    if ((L.LemAction = baSwimming)
      or ((L.LemAction = baGliding) and HasTriggerAt(L.LemX, L.LemY, trUpdraft)))
        and (L.LemY <= 1) then
        begin
          Inc(L.LemY);
          Exit;
        end;

    // Climbers and Hoisters are cancelled mid-action
    if (L.LemAction in [baClimbing, baHoisting]) and (L.LemY <= 7) then
    begin
      if L.LemIsSlider then
        Transition(L, baSliding)
      else begin
        Transition(L, baFalling);
        TurnAround(L);
        Inc(L.LemX, L.LemDX);
      end;
    end;

    // Builders and Stackers stop when the most-recently-placed brick is 1px below level top
    if ((L.LemAction = baBuilding) and (L.LemY <= 1))
      or ((L.LemAction = baStacking) and (L.LemY <= 9 - L.LemNumberOfBricksLeft)) then
        Transition(L, baWalking);

    // Ballooners bob around at the top...
    if (L.LemAction = baBallooning) and (L.LemY < 30) and not (L.LemPhysicsFrame <= 8) then
    begin
      // ...Unless they find terrain at their foot position, in which case they ascend...
      if HasPixelAt(L.LemX, L.LemY) then
      begin
        Dec(L.LemY);

        // ...Until they can walk onto it
        if (HasPixelAt(L.LemX, L.LemY) and not HasPixelAt(L.LemX, L.LemY -1)) then
          PopBalloon(L, 1, baWalking);
      end else begin
        var BalloonerNudgeDistance := 3;

        // Prevents clipping into terrain
        if      HasPixelAt(L.LemX, L.LemY + 1) then BalloonerNudgeDistance := 0
        else if HasPixelAt(L.LemX, L.LemY + 2) then BalloonerNudgeDistance := 1
        else if HasPixelAt(L.LemX, L.LemY + 3) then BalloonerNudgeDistance := 2;

        Inc(L.LemY, BalloonerNudgeDistance);
      end;
    end;
  end;

  { /////////////////// Sides ////////////////// }
  { Left and right sides are one-way forcefields }
  { //////////////////////////////////////////// }

  if (L.LemX <= 1) then // Left side
  begin
    HandleForceField(L, 1);
    Result := True;
  end;

  if (L.LemX >= PhysicsMap.Width -2) then // Right side
  begin
    HandleForceField(L, -1);
    Result := True;
  end;

  { ///////////////////// Bottom //////////////////// }
  { Lems are removed if they fall off the bottom edge }
  { ///////////////////////////////////////////////// }

  if (L.LemY > LEMMING_MAX_Y + PhysicsMap.Height) then
  begin                                                        // The - 3 is to make sure they're at 0
    //WrapLemming(L, L.LemX, L.LemY - LEMMING_MAX_Y - PhysicsMap.Height - 3);
    RemoveLemming(L, RM_NEUTRAL);
    Result := False;
  end;
end;

// Make sure non-Freezer lems can ascend out of Freezer cubes
procedure TLemmingGame.BoostAscend(L: TLemming; YBoost: Integer; ShouldTurn: Boolean = False);
begin
  if ShouldTurn then
    TurnAround(L); // Keeps the lem facing the same way, ironically

  Dec(L.LemY, YBoost); // Initial boost for smooth transition
  Transition(L, baAscending);
end;

procedure TLemmingGame.CheckIfShouldBoostAscend(L: TLemming);
var
  LemDy: Integer;
  LemDXL: Integer;
  LemDXR: Integer;

  function CheckForFirstBlankPixel(i: Integer): Boolean;
  begin
    Result := False;

    if  not HasPixelAt(L.LemX, L.LemY -i)
    and not HasPixelAt(L.LemX -1, L.LemY -i)
    and not HasPixelAt(L.LemX +1, L.LemY -i) then
      Result := True;
  end;
begin
  LemDy := FindGroundPixel(L.LemX, L.LemY);
  LemDXL := FindGroundPixel(L.LemX -1, L.LemY);
  LemDXR := FindGroundPixel(L.LemX +1, L.LemY);

  if (LemDy < -6) and (LemDXL < -6) and (LemDXR < -6) then
  begin
    // Check for blank pixel up to 12px (height of ice cube)
    if CheckForFirstBlankPixel(7)
    or CheckForFirstBlankPixel(8)
    or CheckForFirstBlankPixel(9)
    or CheckForFirstBlankPixel(10)
    or CheckForFirstBlankPixel(11)
    or CheckForFirstBlankPixel(12) then
    begin
      BoostAscend(L, 6, True);
      Exit;
    end;
  end;
end;

function TLemmingGame.HandleWalking(L: TLemming): Boolean;
var
  LemDy: Integer;
  WalkerPositionAdjusted: Boolean;
  LemIsAtLevelTop: Boolean;
begin
  Result := True;

  WalkerPositionAdjusted := L.LemWalkerPositionAdjusted;
  L.LemWalkerPositionAdjusted := False;
  LemIsAtLevelTop := L.LemY <= 6;

  // Zombies walk at half the speed of regular lems
  if L.LemIsZombie then
  begin
    if L.LemPhysicsFrame in [0, 2] then
      Inc(L.LemX, L.LemDx);
  end else
    Inc(L.LemX, L.LemDx);

  LemDy := FindGroundPixel(L.LemX, L.LemY);

  if (LemDy > 0) and (L.LemIsSlider) and (LemCanDehoist(L, true)) then
  begin
    Dec(L.LemX, L.LemDX);
    Transition(L, baDehoisting, true);
    Exit;
  end;

  if LemIsAtLevelTop and (L.LemY = 0 - LemDy) then
    TurnAround(L)
  else if (LemDy < -6) then
  begin
    if L.LemIsClimber then
      Transition(L, baClimbing)
    else
    begin
      TurnAround(L);
      if not WalkerPositionAdjusted then
        Inc(L.LemX, L.LemDx);
    end;
  end else if (LemDy < -2) then
  begin
    Transition(L, baAscending);
    Inc(L.LemY, -2);
  end else if (LemDy < 1) then
    Inc(L.LemY, LemDy);

  // Get new ground pixel again in case the Lem has turned
  LemDy := FindGroundPixel(L.LemX, L.LemY);

  if (LemDy > 3) then
  begin
    Inc(L.LemY, 4);
    Transition(L, baFalling);
  end
  else if (LemDy > 0) then
    Inc(L.LemY, LemDy);

  CheckIfShouldBoostAscend(L);
end;

function TLemmingGame.HandleSwimming(L: TLemming): Boolean;
var
  LemDy: Integer;
  DiveDist: Integer;

  function LemDive(L: TLemming): Integer;
    // Returns 0 if the lem may not dive down
    // Otherwise return the amount of pixels the lem dives
  begin
    Result := 1;
    while HasPixelAt(L.LemX, L.LemY + Result) and (Result <= 4) do
    begin
      Inc(Result);
      Inc(L.LemFallen);
      if HasWaterObjectAt(L.LemX, L.LemY + Result)
        then L.LemFallen := 0;
      if L.LemY + Result >= PhysicsMap.Height then Break;
    end;

    if Result > 4 then Result := 0; // Too much terrain to dive
  end;

begin
  Result := True;
  L.LemFallen := 0; { Transition expects HandleSwimming to set this for Swimmers, as it's not constant.
                      0 is the fallback value that's correct for *most* situations. Transition will
                      still set LemTrueFallen so we don't need to worry about that one. }

  Inc(L.LemX, L.LemDx);

  if HasWaterObjectAt(L.LemX, L.LemY)
  or HasPixelAt(L.LemX, L.LemY) then
  begin
    LemDy := FindGroundPixel(L.LemX, L.LemY);

    // Rise if there is water above the lemming
    if (LemDy >= -1) and HasWaterObjectAt(L.LemX, L.LemY - 1)
                     and not HasPixelAt(L.LemX, L.LemY - 1) then
      Dec(L.LemY)

    else if LemDy < -6 then
    begin
      DiveDist := LemDive(L);

      if DiveDist > 0 then
      begin
        Inc(L.LemY, DiveDist); // Dive below the terrain
        if not HasWaterObjectAt(L.LemX, L.LemY) then
          Transition(L, baWalking);
      end else if L.LemIsClimber
        and not HasWaterObjectAt(L.LemX, L.LemY -1) then
      // Only transition to climber, if the lemming is not under water
        Transition(L, baClimbing)
      else begin
        TurnAround(L);
        Inc(L.LemX, L.LemDx); // Move lemming back
      end
    end

    else if LemDy <= -3 then
    begin
      Transition(L, baAscending);
      Dec(L.LemY, 2);
    end

    // See www.lemmingsforums.net/index.php?topic=3380.0
    // And the swimmer should not yet stop if the water and terrain overlaps
    else if (LemDy <= -1)
         or ((LemDy = 0) and not HasWaterObjectAt(L.LemX, L.LemY)) then
    begin
      Transition(L, baWalking);
      Inc(L.LemY, LemDy);
    end;
  end

  else // If no water or terrain on current position
  begin
    LemDy := FindGroundPixel(L.LemX, L.LemY);
    If LemDy > 1 then
    begin
      Inc(L.LemY);
      Transition(L, baFalling);
    end
    else // If LemDy = 0 or 1
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baWalking);
    end;
  end;
end;

// This is a very specific LemAction that only takes place if a non-Swimmer-Zombie is in poison!
function TLemmingGame.HandleDrifting(L: TLemming): Boolean;
var
  LemDy: Integer;
  DiveDist: Integer;

  function LemDive(L: TLemming): Integer;
  // Returns 0 if the lem may not dive down
  // Otherwise return the amount of pixels the lem dives
  begin
    Result := 1;
    while HasPixelAt(L.LemX, L.LemY + Result) and (Result <= 4) do
    begin
      Inc(Result);
      Inc(L.LemFallen);
      if HasTriggerAt(L.LemX, L.LemY + Result, trPoison)
        then L.LemFallen := 0;
      if L.LemY + Result >= PhysicsMap.Height then Break;
    end;

    if Result > 4 then Result := 0; // Too much terrain to dive
  end;

begin
  Result := True;
  L.LemFallen := 0; // Transition expects HandleDrifting to set this

  // Moves at half the speed of a Swimmer
  if L.LemPhysicsFrame in [0, 2, 4, 6] then
    Inc(L.LemX, L.LemDx);

  if HasTriggerAt(L.LemX, L.LemY, trPoison) or HasPixelAt(L.LemX, L.LemY) then
  begin
    LemDy := FindGroundPixel(L.LemX, L.LemY);

    // Rise if there is poison above the lemming
    if (LemDy >= -1) and HasTriggerAt(L.LemX, L.LemY -1, trPoison)
                     and not HasPixelAt(L.LemX, L.LemY - 1) then
      Dec(L.LemY)

    else if LemDy < -6 then
    begin
      DiveDist := LemDive(L);

      if DiveDist > 0 then
      begin
        Inc(L.LemY, DiveDist); // Dive below the terrain
        if not HasTriggerAt(L.LemX, L.LemY, trPoison) then
          Transition(L, baWalking);
      end else if L.LemIsClimber
        and not HasTriggerAt(L.LemX, L.LemY -1, trPoison) then
      // Only transition to climber, if the lemming is not under poison
        Transition(L, baClimbing)
      else begin
        TurnAround(L);
        Inc(L.LemX, L.LemDx); // Move lemming back
      end
    end

    else if LemDy <= -3 then
    begin
      Transition(L, baAscending);
      Dec(L.LemY, 2);
    end

    // See www.lemmingsforums.net/index.php?topic=3380.0
    // And the drifter should not yet stop if the poison and terrain overlaps
    else if (LemDy <= -1)
    or ((LemDy = 0) and not HasTriggerAt(L.LemX, L.LemY, trPoison)) then
    begin
      Transition(L, baWalking);
      Inc(L.LemY, LemDy);
    end;
  end

  else // If no poison or terrain on current position
  begin
    LemDy := FindGroundPixel(L.LemX, L.LemY);
    If LemDy > 1 then
    begin
      Inc(L.LemY);
      Transition(L, baFalling);
    end
    else // If LemDy = 0 or 1
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baWalking);
    end;
  end;
end;

function TLemmingGame.HandleAscending(L: TLemming): Boolean;
var
  dy: Integer;
begin
  Result := True;
  with L do
  begin
    dy := 0;
    while (dy < 2) and (LemAscended < 5) and (HasPixelAt(LemX, LemY-1)) do
    begin
      Inc(dy);
      Dec(LemY);
      Inc(LemAscended);
    end;

    if (dy < 2) and not HasPixelAt(LemX, LemY-1) then
    begin
      fLemNextAction := baWalking;
    end else if ((LemAscended = 4) and HasPixelAt(LemX, LemY-1) and HasPixelAt(LemX, LemY-2))
    or ((LemAscended >= 5) and HasPixelAt(LemX, LemY-1)) then
    begin
      Transition(L, baWalking);
    end;
  end;
end;

//function TLemmingGame.HandlePropelling(L: TLemming): Boolean; // Propeller
//var
//  ContinueUpwards, FoundTerrain, FoundAir, NudgeDown: Boolean;
//  XChecks: Integer;
//begin
//  Result := True;
//
//  for XChecks := -4 to 4 do
//  begin
//    FoundAir := not HasPixelAt(L.LemX + XChecks, L.LemY - 11);
//    FoundTerrain := HasPixelAt(L.LemX + XChecks, L.LemY - 10);
//    NudgeDown := HasPixelAt(L.LemX + XChecks, L.LemY - 9);
//  end;
//
//  if (L.LemY <= 10) then
//    Transition(L, baFalling)
//  else if (FoundTerrain and NudgeDown) then
//    Inc(L.LemY)
//  else if not FoundTerrain then
//    Dec(L.LemY, 2);
//
//  if FoundTerrain then
//  begin
//    ContinueUpwards := PropellerOneRow(L.LemX, L.LemY - 10) and not FoundAir;
//
//    Dec(L.LemY);
//
//    if HasIndestructibleAt(L.LemX, L.LemY - 10, L.LemDX, baPropelling) then
//    begin
//      if HasSteelAt(L.LemX, L.LemY - 10) then
//        CueSoundEffect(SFX_Steel_OWW, L.Position);
//      Transition(L, baFalling);
//    end
//
//    else if not ContinueUpwards then
//      Transition(L, baJumping);
//  end;
//end;

function TLemmingGame.HandleDigging(L: TLemming): Boolean;
var
  ContinueWork: Boolean;
begin
  Result := True;

  if L.LemIsStartingAction then
  begin
    L.LemIsStartingAction := False;
    DigOneRow(L.LemX, L.LemY - 1);
    // The first digger cycle is one frame longer!
    // So we need to artificially cancel the very first frame advancement.
    Dec(L.LemPhysicsFrame);
  end;

  if L.LemPhysicsFrame in [0, 8] then
  begin
    Inc(L.LemY);

    ContinueWork := DigOneRow(L.LemX, L.LemY - 1);

    if HasIndestructibleAt(L.LemX, L.LemY, L.LemDX, baDigging) then
    begin
      if HasSteelAt(L.LemX, L.LemY) then
        CueSoundEffect(SFX_Steel_OWW, L.Position);
      Transition(L, baWalking);
    end

    else if not ContinueWork then
      Transition(L, baFalling);
  end;
end;


function TLemmingGame.HandleDangling(L: TLemming): Boolean;
begin
  Result := True;

  if L.LemPhysicsFrame in [0 .. 3] then
    Inc(L.LemY);

  if HasPixelAt(L.LemX, L.LemY) then
  begin
    Transition(L, baWalking);
    Exit;
  end else if L.LemEndOfAnimation then
    Transition(L, baFalling);
end;

function TLemmingGame.HandleDehoisting(L: TLemming): Boolean;
var
  n: Integer;
begin
  Result := True;

  if L.LemEndOfAnimation then
  begin
    if HasPixelAt(L.LemX, L.LemY - 7) then
      Transition(L, baSliding)
    else
      Transition(L, baDangling);
  end else if L.LemPhysicsFrame >= 2 then
  begin
    for n := 0 to 1 do
    begin
      Inc(L.LemY);
      if not LemSliderTerrainChecks(L, (L.LemPhysicsFrame * 2) - 3 + n) then
      begin
        if L.LemAction = baDrowning then Result := false;
        Break;
      end;
    end;
  end;
end;

function TLemmingGame.LemCanDehoist(L: TLemming; AlreadyMovedX: Boolean): Boolean;
var
  CurX, NextX: Integer;
  n: Integer;
begin
  CurX := L.LemX;
  NextX := L.LemX;

  if AlreadyMovedX then
    CurX := CurX - L.LemDX
  else
    NextX := NextX + L.LemDX;

  if (NextX < 0) or (NextX >= Level.Info.Width) then
    Result := false
  else if (not HasPixelAt(CurX, L.LemY)) or HasPixelAt(NextX, L.LemY) then
    Result := false
  else begin
    Result := true;

    // Dehoist if cannot step down
    for n := 1 to 3 do
      if HasPixelAt(NextX, L.LemY + n) then
      begin
        Result := false;
        Exit;
      end else if not HasPixelAt(CurX, L.LemY + n) then
        Break;
  end;
end;

function TLemmingGame.HandleSliding(L: TLemming): Boolean;
var
  n: Integer;
begin
  if ((L.LemX <= 0) and (L.LemDX = -1)) or ((L.LemX >= Level.Info.Width - 1) and (L.LemDX = 1)) then
    RemoveLemming(L, RM_NEUTRAL); // Shouldn't happen

  Result := true;
  for n := 0 to 1 do
  begin
    Inc(L.LemY);
    if not LemSliderTerrainChecks(L) then
    begin
      if L.LemAction = baDrowning then Result := false;
      Break;
    end;
  end;
end;

function TLemmingGame.HandleSleeping(L: TLemming): Boolean;
begin
   Result := True;

   // Wait for penultimate animation frame before changing the lem count
   if L.LemFrame = 19 then
     Dec(LemmingsOut);

   if ((L.LemX <= 0) and (L.LemDX = -1)) or ((L.LemX >= Level.Info.Width - 1) and (L.LemDX = 1)) then
    RemoveLemming(L, RM_NEUTRAL); // Shouldn't happen

   // Let lemming fall
   if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then
    Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 2]))
   else
    Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 3]));
end;

function TLemmingGame.LemSliderTerrainChecks(L: TLemming; MaxYCheckOffset: Integer = 7): Boolean;
  function SliderHasPixelAt(X, Y: Integer): Boolean;
  begin
    Result := HasPixelAt(X, Y);
    if (not Result) and (X = L.LemX) and (Y = L.LemDehoistPinY) and (Y >= 0) then
      Result := HasPixelAt(X, Y+1);
  end;
begin
  Result := true;

  if SliderHasPixelAt(L.LemX, L.LemY) and not SliderHasPixelAt(L.LemX, L.LemY-1) then
  begin
    Transition(L, baWalking);
    Result := false;
  end else if not SliderHasPixelAt(L.LemX, L.LemY - Min(MaxYCheckOffset, 7)) then
  begin
  if SliderHasPixelAt(L.LemX, L.LemY) then
    Transition(L, baWalking) // Prevents Dangling state if there is terrain
    else
    Transition(L, baDangling); // Prevents Slider falling straightaway if there isn't
    Result := false;
  end else if SliderHasPixelAt(L.LemX, L.LemY) then
  begin
    if HasTriggerAt(L.LemX - L.LemDX, L.LemY, trWater, L)
    or HasTriggerAt(L.LemX - L.LemDX, L.LemY, trPoison, L) then
    begin
      Dec(L.LemX, L.LemDX);
      if L.LemIsSwimmer then
      begin
        Transition(L, baSwimming, true);
        CueSoundEffect(SFX_Swim, L.Position);
      end else begin
        Transition(L, baDrowning, true);
        CueSoundEffect(SFX_Drown, L.Position);
      end;
      Result := false;
    end else if SliderHasPixelAt(L.LemX - L.LemDX, L.LemY) then
    begin
      Dec(L.LemX, L.LemDX);
      Transition(L, baWalking, true);
      Result := false;
    end;
  end;
end;


function TLemmingGame.HandleClimbing(L: TLemming): Boolean;
// Be very careful when changing the terrain/hoister checks for climbers!
// See www.lemmingsforums.net/index.php?topic=2506.0 first!
var
  FoundClip: Boolean;
begin
  Result := True;

  if L.LemPhysicsFrame <= 3 then
  begin
    FoundClip := (HasPixelAt(L.LemX - L.LemDx, L.LemY - 6 - L.LemPhysicsFrame))
              or (HasPixelAt(L.LemX - L.LemDx, L.LemY - 5 - L.LemPhysicsFrame) and (not L.LemIsStartingAction));

    if L.LemPhysicsFrame = 0 then // First triggered after 8 frames!
      FoundClip := FoundClip and HasPixelAt(L.LemX - L.LemDx, L.LemY - 7);

    if FoundClip then
    begin
      // Don't fall below original position on hitting terrain in first cycle
      if not L.LemIsStartingAction then L.LemY := L.LemY - L.LemPhysicsFrame + 3;

      if L.LemIsSlider then
      begin
        Dec(L.LemY);
        Transition(L, baSliding);
      end else begin
        Dec(L.LemX, L.LemDx);
        Transition(L, baFalling, True); // Turn around as well
        Inc(L.LemFallen); // Least-impact way to fix a fall distance inconsistency. See www.lemmingsforums.net/index.php?topic=5794.0
      end;
    end
    else if not HasPixelAt(L.LemX, L.LemY - 7 - L.LemPhysicsFrame) then
    begin
      // If-case prevents too deep bombing, see www.lemmingsforums.net/index.php?topic=2620.0
      if not (L.LemIsStartingAction and (L.LemPhysicsFrame = 1)) then
      begin
        L.LemY := L.LemY - L.LemPhysicsFrame + 2;
        L.LemIsStartingAction := False;
      end;
      Transition(L, baHoisting);
    end;
  end

  else
  begin
    Dec(L.LemY);
    L.LemIsStartingAction := False;

    FoundClip := HasPixelAt(L.LemX - L.LemDx, L.LemY - 7);

    if L.LemPhysicsFrame = 7 then
      FoundClip := FoundClip and HasPixelAt(L.LemX, L.LemY - 7);

    if FoundClip then
    begin
      Inc(L.LemY);

      if L.LemIsSlider then
        Transition(L, baSliding)
      else begin
        Dec(L.LemX, L.LemDx);
        Transition(L, baFalling, True); // Turn around as well
      end;
    end;
  end;
end;


function TLemmingGame.HandleTurning(L: TLemming): Boolean;
begin
  Result := True;

  if L.LemFrame = 2 then
    TurnAround(L);

  if L.LemEndOfAnimation then
  begin
    Dec(L.LemY);
    Transition(L, baClimbing);
  end;
end;


function TLemmingGame.HandleDrowning(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;


function TLemmingGame.HandleDisarming(L: TLemming): Boolean;
begin
  Result := False;
  Dec(L.LemDisarmingFrames);
  if L.LemDisarmingFrames <= 0 then
  begin
    if L.LemActionNew <> baNone then Transition(L, L.LemActionNew)
    else Transition(L, baWalking);
    L.LemActionNew := baNone;
  end
  else if L.LemPhysicsFrame mod 8 = 0 then
    CueSoundEffect(SFX_DisarmTrap, L.Position);
end;


function TLemmingGame.HandleHoisting(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
    Transition(L, baWalking)
  // Special case due to www.lemmingsforums.net/index.php?topic=2620.0
  else if (L.LemPhysicsFrame = 1) and L.LemIsStartingAction then
    Dec(L.LemY, 1)
  else if L.LemPhysicsFrame <= 4 then
    Dec(L.LemY, 2);
end;


function TLemmingGame.LemCanLadder(L: TLemming): Boolean;
var
  PosX, PosY: Integer;
begin
  Result := False;

  PosX := L.LemX + L.LemDX;
  PosY := L.LemY;

  Result := Result or

  // First brick must add at least one pixel at its extreme edge
  not HasPixelAt(PosX + (4 * L.LemDX), PosY + 2)

//  // Offset next possible ladder by 1px due to LadderHitObstacle checks
//  and not HasPixelAt(PosX + (4 * L.LemDX), PosY + 3);
end;

function TLemmingGame.HandleLaddering(L: TLemming): Boolean;
  // Check if the ladder has met terrain - this must be done per-frame
  function LadderHitObstacle: Boolean;
  var
  XOffset, YOffset: Integer;
  i, FrameOffset: Integer;
  begin
    Result := False;

    case L.LemPhysicsFrame of
      12: FrameOffset := 5;   // 9, 5 and 8, 6
      14: FrameOffset := 8;   // Add 3 to each digit
      16: FrameOffset := 11;  // Etc.
      18: FrameOffset := 14;
      20: FrameOffset := 17;
      22: FrameOffset := 20;
      else Exit;
    end;

    XOffset := FrameOffset + 3;
    YOffset := FrameOffset;

    if (L.LemPhysicsFrame in [12, 14, 16, 18, 20, 22]) then
    begin
      for i := 0 to 1 do
        // Check for terrain 1px beyond final pixel of most-recently-placed ladder brick
        if (HasPixelAt(L.LemX + ((XOffset + 1) * L.LemDX), L.LemY + YOffset)
        and HasPixelAt(L.LemX + (XOffset * L.LemDX), L.LemY + (YOffset + 1)))

        // Check for Blocker/OWF at, and 1px beyond, final pixel of most recently-placed ladder brick
        or HasTriggerAt(L.LemX + ((XOffset + i) * L.LemDX), L.LemY + (YOffset + i), trForceRight)
        or HasTriggerAt(L.LemX + ((XOffset + i) * L.LemDX), L.LemY + (YOffset + i), trForceLeft)

        // Check for Edge-of-level at extreme X edge
        or (L.LemX + (XOffset * L.LemDX) >= PhysicsMap.Width)
        or (L.LemX + (XOffset * L.LemDX) <= 0)

        // Check for Bottom-of-level at extreme Y edge
        or (L.LemY + YOffset >= PhysicsMap.Height) then
          Result := True
        else
          Result := False;
    end else
      Result := False;
  end;
begin
  Result := True;

  if L.LemPhysicsFrame >=10 then
    LayLadder(L);

  if (L.LemPhysicsFrame in [10, 12, 14, 16, 18, 20, 22, 24, 26]) then
  begin
    CueSoundEffect(SFX_Brick, L.Position);
  end;

  if LadderHitObstacle or L.LemEndOfAnimation then
    Transition(L, baWalking);
end;


function TLemmingGame.LemCanPlatform(L: TLemming): Boolean;
var
  n: Integer;
begin
  Result := False;
  // Next brick must add at least one pixel
  for n := 0 to 5 do
    Result := Result or not HasPixelAt(L.LemX + n*L.LemDx, L.LemY);

  // Lem may not hit terrain where the previous brick was already placed.
  Result := Result and not HasPixelAt(L.LemX + L.LemDx, L.LemY - 1);
  Result := Result and not HasPixelAt(L.LemX + 2*L.LemDx, L.LemY - 1);
end;

function TLemmingGame.HandlePlatforming(L: TLemming): Boolean;
  function PlatformerTerrainCheck(X, Y: Integer): Boolean;
  begin
    Result := HasPixelAt(X, Y - 1) or HasPixelAt(X, Y - 2);
  end;

begin
  Result := True;

  if L.LemPhysicsFrame = 9 then
  begin
    L.LemPlacedBrick := LemCanPlatform(L);
    LayBrick(L);
  end

  else if (L.LemPhysicsFrame = 10) and (L.LemNumberOfBricksLeft <= 3) then
  begin
    CueSoundEffect(SFX_Brick, L.Position);
  end
  else if L.LemPhysicsFrame = 15 then
  begin
    if not L.LemPlacedBrick then
      Transition(L, baWalking, True) // Turn around as well

    else if PlatformerTerrainCheck(L.LemX + 2*L.LemDx, L.LemY) then
    begin
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True);  // Turn around as well
    end

    else if not L.LemConstructivePositionFreeze then
      Inc(L.LemX, L.LemDx);
  end

  else if L.LemPhysicsFrame = 0 then
  begin
    if PlatformerTerrainCheck(L.LemX + 2*L.LemDx, L.LemY) and (L.LemNumberOfBricksLeft > 1) then
    begin
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True);  // Turn around as well
    end

    else if PlatformerTerrainCheck(L.LemX + 3*L.LemDx, L.LemY) and (L.LemNumberOfBricksLeft > 1) then
    begin
      Inc(L.LemX, 2*L.LemDx);
      Transition(L, baWalking, True);  // Turn around as well
    end

    else
    begin
      if not L.LemConstructivePositionFreeze then
        Inc(L.LemX, 2*L.LemDx);
      Dec(L.LemNumberOfBricksLeft); // Why are we doing this here, instead at the beginning of frame 15??
      if L.LemNumberOfBricksLeft = 0 then
      begin
        // Stalling if there are pixels in the way:
        if HasPixelAt(L.LemX, L.LemY - 1) then Dec(L.LemX, L.LemDx);
        Transition(L, baShrugging);
      end;
    end;
  end;

  if L.LemPhysicsFrame = 0 then
    L.LemConstructivePositionFreeze := false;
end;



function TLemmingGame.HandleBuilding(L: TLemming): Boolean;
begin
  Result := True;

  if L.LemPhysicsFrame = 9 then
    LayBrick(L)

  else if (L.LemPhysicsFrame = 10) and (L.LemNumberOfBricksLeft <= 3) then
  begin
    CueSoundEffect(SFX_Brick, L.Position);
  end
  else if L.LemPhysicsFrame = 1 then
  begin                                    // Relax this check for first brick
    if HasPixelAt(L.LemX, L.LemY - 1) and (L.LemNumberOfBricksLeft < 12) then
      Transition(L, baWalking, True)  // Turn around as well
  end
  else if L.LemPhysicsFrame = 0 then
  begin
    Dec(L.LemNumberOfBricksLeft);

    if HasPixelAt(L.LemX + L.LemDx, L.LemY - 2) then
      Transition(L, baWalking, True)  // Turn around as well

    else if (HasPixelAt(L.LemX + 2*L.LemDx, L.LemY - 10) and (L.LemNumberOfBricksLeft > 0)) then
    begin
      Dec(L.LemY);
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True)  // Turn around as well

    end else begin
      if not L.LemConstructivePositionFreeze then
      begin
        Dec(L.LemY);
        Inc(L.LemX, 2*L.LemDx);
      end;

      if (HasPixelAt(L.LemX +   L.LemDx, L.LemY - 9) and (L.LemNumberOfBricksLeft > 0))
      or (HasPixelAt(L.LemX + 2*L.LemDx, L.LemY - 1) and (L.LemNumberOfBricksLeft = 1)) then
         Transition(L, baWalking, True)  // Turn around as well

      else if L.LemNumberOfBricksLeft = 0 then
         Transition(L, baShrugging);
    end;
  end;

  if L.LemPhysicsFrame = 0 then
    L.LemConstructivePositionFreeze := false;
end;


function TLemmingGame.HandleStacking(L: TLemming): Boolean;
  function MayPlaceNextBrick(L: TLemming): Boolean;
  var
    BrickPosY: Integer;
  begin
    BrickPosY := L.LemY - 9 + L.LemNumberOfBricksLeft;
    if L.LemStackLow then Inc(BrickPosY);
    Result := not (     HasPixelAt(L.LemX + L.LemDX, BrickPosY)
                    and HasPixelAt(L.LemX + 2 * L.LemDX, BrickPosY)
                    and HasPixelAt(L.LemX + 3 * L.LemDX, BrickPosY))
  end;

begin
  Result := True;

  if L.LemPhysicsFrame = 7 then
    L.LemPlacedBrick := LayStackBrick(L)

  else if L.LemPhysicsFrame = 0 then
  begin
    Dec(L.LemNumberOfBricksLeft);

    if L.LemNumberOfBricksLeft < 3 then
    begin
      CueSoundEffect(SFX_Brick, L.Position);
    end;

    if not L.LemPlacedBrick then
    begin
      // Relax the check on the first brick - see www.lemmingsforums.net/index.php?topic=2862.0
      if (L.LemNumberOfBricksLeft < 7) or not MayPlaceNextBrick(L) then
        Transition(L, baWalking, True) // Turn around as well
    end
    else if L.LemNumberOfBricksLeft = 0 then
      Transition(L, baShrugging);
  end;
end;

function TLemmingGame.HandleBashing(L: TLemming): Boolean;
var
  LemDy, n: Integer;
  ContinueWork: Boolean;

  function BasherIndestructibleCheck(x, y, Direction: Integer): Boolean;
  begin
    // Check for indestructible terrain 3, 4 and 5 pixels above (x, y)
    Result := (    (HasIndestructibleAt(x, y - 3, Direction, baBashing))
                or (HasIndestructibleAt(x, y - 4, Direction, baBashing))
                or (HasIndestructibleAt(x, y - 5, Direction, baBashing))
              );
  end;

  procedure BasherTurn(L: TLemming; SteelSound: Boolean);
  begin
    // Turns basher around an transitions to walker
    Dec(L.LemX, L.LemDx);
    Transition(L, baWalking, True); // Turn around as well
    if SteelSound then CueSoundEffect(SFX_Steel_OWW, L.Position);
  end;

  function BasherStepUpCheck(x, y, Direction, Step: Integer): Boolean;
  begin
    Result := True;

    if Step = -1 then
    begin
      if (     (not HasPixelAt(x + Direction, y + Step - 1))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 2)
         ) then Result := False;
      if (     (not HasPixelAt(x + Direction, y + Step - 2))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 2)
         ) then Result := False;
      if (     HasPixelAt(x + Direction, y + Step - 2)
           and HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + Direction, y + Step)
         ) then Result := False;
    end
    else if Step = -2 then
    begin
      if (     (not HasPixelAt(x + Direction, y + Step))
           and HasPixelAt(x + Direction, y + Step + 1)
           and HasPixelAt(x + 2*Direction, y + Step + 1)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
         ) then Result := False;
      if (     (not HasPixelAt(x + Direction, y + Step - 1))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
         ) then Result := False;
      if (     HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + Direction, y + Step)
         ) then Result := False;
    end;
  end;

  // Simulate the behavior of the basher in the next two frames
  function DoTurnAtSteel(L: TLemming): Boolean;
  var
    CopyL: TLemming;
    SavePhysicsMap: TBitmap32;
    i: Integer;
  begin
    // Make deep copy of the lemming
    CopyL := TLemming.Create;
    CopyL.Assign(L);
    CopyL.LemIsPhysicsSimulation := true;

    // Make a deep copy of the PhysicsMap
    SavePhysicsMap := TBitmap32.Create;
    SavePhysicsMap.Assign(PhysicsMap);

    Result := False;

    // Simulate two basher cycles
    // 11 iterations is hopefully correct: CopyL.LemPhysicsFrame changes as follows:
    // 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16 -> 11 -> 12 -> 13 -> 14 -> 15
    CopyL.LemPhysicsFrame := 10;
    for i := 0 to 10 do
    begin
      // On CopyL.LemPhysicsFrame = 0 or 16, apply all basher masks and jump to frame 10 again
      if (CopyL.LemPhysicsFrame in [0, 16]) then
      begin
        Inc(fSimulationDepth);
        ApplyBashingMask(CopyL, 0);
        ApplyBashingMask(CopyL, 1);
        ApplyBashingMask(CopyL, 2);
        ApplyBashingMask(CopyL, 3);
        Dec(fSimulationDepth); // Should not matter, because we do this in SimulateLem anyway, but to be safe...
        // Do *not* check whether continue bashing, but move directly ahead to frame 10
        CopyL.LemPhysicsFrame := 10;
      end;

      // Move one frame forward
      SimulateLem(CopyL, False);

      // Check if we have turned around at steel
      if (CopyL.LemDX = -L.LemDX) and (CopyL.LemAction <> baDehoisting) then
      begin
        Result := True;
        Break;
      end
      // Check if we are still a basher
      else if CopyL.LemRemoved or not (CopyL.LemAction = baBashing) then
        Break; // And return false
    end;

    // Copy PhysicsMap back
    PhysicsMap.Assign(SavePhysicsMap);
    SavePhysicsMap.Free;

    // Free CopyL
    CopyL.Free;
  end;
begin
  Result := True;

  // Remove terrain
  if L.LemPhysicsFrame in [2, 3, 4, 5] then
    ApplyBashingMask(L, L.LemPhysicsFrame - 2);

  // Check for enough terrain to continue working
  if L.LemPhysicsFrame = 5 then
  begin
    ContinueWork := False;

    // Check for destructible terrain at height 5 and 6
    for n := 1 to 14 do
    begin
      if (     HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 6)
           and not HasIndestructibleAt(L.LemX + n*L.LemDx, L.LemY - 6, L.LemDx, baBashing)
         ) then ContinueWork := True;
      if (     HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 5)
           and not HasIndestructibleAt(L.LemX + n*L.LemDx, L.LemY - 5, L.LemDx, baBashing)
         ) then ContinueWork := True;
    end;

    // Check whether we turn around within the next two basher strokes (only if we don't simulate)
    if (not ContinueWork) and (not L.LemIsPhysicsSimulation) then
      ContinueWork := DoTurnAtSteel(L);

    if not ContinueWork then
    begin
      if HasPixelAt(L.LemX, L.LemY) then
        Transition(L, baWalking)
      else
        Transition(L, baFalling);
    end;
  end;

  // Basher movement
  if L.LemPhysicsFrame in [11, 12, 13, 14, 15] then
  begin
    Inc(L.LemX, L.LemDx);

    LemDy := FindGroundPixel(L.LemX, L.LemY);

    if (LemDy > 0) and L.LemIsSlider and LemCanDehoist(L, true) then
    begin
      Dec(L.LemX, L.LemDX);
      Transition(L, baDehoisting, true);
    end

    else if LemDy = 4 then
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baFalling);
    end

    else if LemDy = 3 then
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baWalking);
    end

    else if LemDy in [0, 1, 2] then
    begin
      // Move no, one or two pixels down, if there no steel
      if BasherIndestructibleCheck(L.LemX, L.LemY + LemDy, L.LemDx) then
        BasherTurn(L, HasSteelAt(L.LemX, L.LemY + LemDy - 4))
      else
        Inc(L.LemY, LemDy)
    end

    else if (LemDy = -1) or (LemDy = -2) then
    begin
      // Move one or two pixels up, if there is no steel and not too much terrain
      if BasherIndestructibleCheck(L.LemX, L.LemY + LemDy, L.LemDx) then
        BasherTurn(L, HasSteelAt(L.LemX, L.LemY + LemDy - 4))
      else if BasherStepUpCheck(L.LemX, L.LemY, L.LemDx, LemDy) = False then
      begin
        if BasherIndestructibleCheck(L.LemX + L.LemDx, L.LemY + 2, L.LemDx) then
          BasherTurn(L,    HasSteelAt(L.LemX + L.LemDx, L.LemY + LemDy)
                        or HasSteelAt(L.LemX + L.LemDx, L.LemY + LemDy + 1))
        else
          // Stall basher
          Dec(L.LemX, L.LemDx);
      end
      else
        Inc(L.LemY, LemDy); // Lem may move up
    end

    else if LemDy < -2 then
    begin
      // Either stall or turn if there is steel
      if BasherIndestructibleCheck(L.LemX, L.LemY, L.LemDx) then
        BasherTurn(L,(    HasSteelAt(L.LemX, L.LemY - 3)
                       or HasSteelAt(L.LemX, L.LemY - 4)
                       or HasSteelAt(L.LemX, L.LemY - 5)
                     ))
      else
        Dec(L.LemX, L.LemDx);
    end;
  end;
end;

function TLemmingGame.HandleFencing(L: TLemming): Boolean;
// This is based off HandleBashing but has some changes.
var
  LemDy, n: Integer;
  ContinueWork: Boolean;
  SteelContinue, MoveUpContinue: Boolean;
  NeedUndoMoveUp: Boolean;

  function FencerIndestructibleCheck(x, y, Direction: Integer): Boolean;
  begin
    // Check for indestructible terrain 3 pixels above (x, y)
    Result := HasIndestructibleAt(x, y - 3, Direction, baFencing);
  end;

  procedure FencerTurn(L: TLemming; SteelSound: Boolean);
  begin
    // Turns fencer around and transitions to walker
    Dec(L.LemX, L.LemDx);
    if NeedUndoMoveUp then
      Inc(L.LemY);
    Transition(L, baWalking, True); // Turn around as well
    if SteelSound then CueSoundEffect(SFX_Steel_OWW, L.Position);
  end;

  function FencerStepUpCheck(x, y, Direction, Step: Integer): Boolean;
  begin
    Result := True;

    if Step = -1 then
    begin
      if (     (not HasPixelAt(x + Direction, y + Step - 1))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 2)
         ) then Result := False;
      if (     (not HasPixelAt(x + Direction, y + Step - 2))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
           and HasPixelAt(x + 2*Direction, y + Step - 2)
         ) then Result := False;
      if (     HasPixelAt(x + Direction, y + Step - 2)
           and HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + Direction, y + Step)
         ) then Result := False;
    end
    else if Step = -2 then
    begin
      if (     (not HasPixelAt(x + Direction, y + Step))
           and HasPixelAt(x + Direction, y + Step + 1)
           and HasPixelAt(x + 2*Direction, y + Step + 1)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
         ) then Result := False;
      if (     (not HasPixelAt(x + Direction, y + Step - 1))
           and HasPixelAt(x + Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step)
           and HasPixelAt(x + 2*Direction, y + Step - 1)
         ) then Result := False;
      if (     HasPixelAt(x + Direction, y + Step - 1)
           and HasPixelAt(x + Direction, y + Step)
         ) then Result := False;
    end;
  end;

  // Simulate the behavior of the fencer in the next two frames
  procedure DoFencerContinueTests(L: TLemming; var SteelContinue: Boolean; var MoveUpContinue: Boolean);
  var
    CopyL: TLemming;
    SavePhysicsMap: TBitmap32;
    i: Integer;
  begin
    // Make deep copy of the lemming
    CopyL := TLemming.Create;
    CopyL.Assign(L);
    CopyL.LemIsPhysicsSimulation := true;

    // Make a deep copy of the PhysicsMap
    SavePhysicsMap := TBitmap32.Create;
    SavePhysicsMap.Assign(PhysicsMap);

    SteelContinue := False;
    MoveUpContinue := False;

    // Simulate two fencer cycles
    // 11 iterations is hopefully correct: CopyL.LemPhysicsFrame changes as follows:
    // 10 -> 11 -> 12 -> 13 -> 14 -> 15 -> 16 -> 11 -> 12 -> 13 -> 14 -> 15
    CopyL.LemPhysicsFrame := 10;

    for i := 0 to 10 do
    begin
      // On CopyL.LemPhysicsFrame = 0, apply all fencer masks and jump to frame 10 again
      if (CopyL.LemPhysicsFrame = 0) then
      begin
        Inc(fSimulationDepth); // Do not apply the changes to the TerrainLayer
        ApplyFencerMask(CopyL, 0);
        ApplyFencerMask(CopyL, 1);
        ApplyFencerMask(CopyL, 2);
        ApplyFencerMask(CopyL, 3);
        Dec(fSimulationDepth); // Should not matter, because we do this in SimulateLem anyway, but to be safe...
        // Do *not* check whether continue fencing, but move directly ahead to frame 10
        CopyL.LemPhysicsFrame := 10;
      end;

      // Move one frame forward
      SimulateLem(CopyL, False);

      // Check if we've moved upwards
      if (CopyL.LemY < L.LemY) then
        MoveUpContinue := true;

      // Check if we have turned around at steel
      if (CopyL.LemDX = -L.LemDX) and (CopyL.LemAction <> baDehoisting) then
      begin
        SteelContinue := True;
        Break;
      end

      // Check if we are still a fencer
      else if CopyL.LemRemoved or not (CopyL.LemAction = baFencing) then
        Break; // And return false
    end;

    // Copy PhysicsMap back
    PhysicsMap.Assign(SavePhysicsMap);
    SavePhysicsMap.Free;

    // Free the copy lemming! This was missing in Nepster's code.
    CopyL.Free;
  end;

begin
  Result := True;

  // Remove terrain
  if L.LemPhysicsFrame in [2, 3, 4, 5] then
    ApplyFencerMask(L, L.LemPhysicsFrame - 2);

  if L.LemPhysicsFrame = 15 then
    L.LemIsStartingAction := false;

  // Check for enough terrain to continue working
  if L.LemPhysicsFrame = 5 then
  begin
    ContinueWork := False;

    // Check for destructible terrain at height 5 and 6
    for n := 1 to 14 do
    begin
      if (     HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 6)
           and not HasIndestructibleAt(L.LemX + n*L.LemDx, L.LemY - 6, L.LemDx, baFencing)
         ) then ContinueWork := True;
      if (     HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 5)
           and not HasIndestructibleAt(L.LemX + n*L.LemDx, L.LemY - 5, L.LemDx, baFencing)
         ) then ContinueWork := True;
    end;

    // Check whether we turn around within the next two fencer strokes (only if we don't simulate)
    if not L.LemIsPhysicsSimulation then
      if not (ContinueWork and L.LemIsStartingAction) then // If BOTH of these are true, then both things being tested for are irrelevant
      begin
        DoFencerContinueTests(L, SteelContinue, MoveUpContinue);

        if ContinueWork and not L.LemIsStartingAction then
          ContinueWork := MoveUpContinue;

        if not ContinueWork then
          ContinueWork := SteelContinue;
      end;

    if not ContinueWork then
    begin
      if HasPixelAt(L.LemX, L.LemY) then
        Transition(L, baWalking)
      else
        Transition(L, baFalling);
    end;
  end;

  // Fencer movement
  if L.LemPhysicsFrame in [11, 12, 13, 14] then
  begin
    Inc(L.LemX, L.LemDx);

    LemDy := FindGroundPixel(L.LemX, L.LemY);

    if (LemDy = -1) and (L.LemPhysicsFrame in [11, 13]) then
    begin
      Dec(L.LemY, 1);
      LemDy := 0;
      NeedUndoMoveUp := true;
      // This is to ignore the effect of the fencer's own slope on determining how far it can step up or down.
      // I'm starting to think I should've based the Fencer code off Miner rather than Basher...
    end else
      NeedUndoMoveUp := false;

    if (LemDy > 0) and L.LemIsSlider and LemCanDehoist(L, true) then
    begin
      Dec(L.LemX, L.LemDX);
      Transition(L, baDehoisting, true);
    end

    else if LemDy = 4 then
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baFalling);
    end

    else if LemDy > 0 then
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baWalking);
    end

    else if LemDy = 0 then
    begin
      if FencerIndestructibleCheck(L.LemX, L.LemY, L.LemDx) then
        FencerTurn(L, HasSteelAt(L.LemX, L.LemY - 4))
    end

    else if (LemDy = -1) or (LemDy = -2) then
    begin
      // Move one or two pixels up, if there is no steel and not too much terrain
      if FencerIndestructibleCheck(L.LemX, L.LemY + LemDy, L.LemDx) then
        FencerTurn(L, HasSteelAt(L.LemX, L.LemY + LemDy - 4))
      else if FencerStepUpCheck(L.LemX, L.LemY, L.LemDx, LemDy) = False then
      begin
        if FencerIndestructibleCheck(L.LemX + L.LemDx, L.LemY + 2, L.LemDx) then
          FencerTurn(L,    HasSteelAt(L.LemX + L.LemDx, L.LemY + LemDy)
                        or HasSteelAt(L.LemX + L.LemDx, L.LemY + LemDy + 1))
        else begin
          // Stall fencer
          Dec(L.LemX, L.LemDx);
          if NeedUndoMoveUp then Inc(L.LemY);
        end;
      end
      else
        Inc(L.LemY, LemDy); // Lem may move up
    end

    else if LemDy < -2 then
    begin
      // Either stall or turn if there is steel
      if FencerIndestructibleCheck(L.LemX, L.LemY, L.LemDx) then
        FencerTurn(L,(    HasSteelAt(L.LemX, L.LemY - 3)
                       or HasSteelAt(L.LemX, L.LemY - 4)
                       or HasSteelAt(L.LemX, L.LemY - 5)
                     ))
      else
        Dec(L.LemX, L.LemDx);
    end;
  end;
end;

function TLemmingGame.HandleReaching(L: TLemming): Boolean;
const
  MovementList: array[0..7] of Byte = (0, 3, 2, 2, 1, 1, 1, 0);
var
  MinimumReachDistance: Integer;
  CannotAscendOrShimmy: Boolean;

begin
  Result := True;
  CannotAscendOrShimmy := HasPixelAt(L.LemX, L.LemY - 9) and HasPixelAt(L.LemX, L.LemY - 10);

  if HasPixelAt(L.LemX, L.LemY - 10) then
    MinimumReachDistance := 1
  else if HasPixelAt(L.LemX, L.LemY - 11) then
    MinimumReachDistance := 2
  else if HasPixelAt(L.LemX, L.LemY - 12) then
    MinimumReachDistance := 3
  else if HasPixelAt(L.LemX, L.LemY - 13) then
    MinimumReachDistance := 4
  else
    MinimumReachDistance := 5;

  // On the first frame, check if both ascent and shimmy are blocked by terrain
  if (L.LemPhysicsFrame = 1) and CannotAscendOrShimmy then
  begin
    Transition(L, baFalling)
  end
  // Check whether we can reach the ceiling for shimmying
  else if MinimumReachDistance <= MovementList[L.LemPhysicsFrame] then
  begin
    Dec(L.LemY, MinimumReachDistance);
    Transition(L, baShimmying);
  end
  // Move upwards and fall when height limit is reached (determined by frame)
  else begin
    Dec(L.LemY, MovementList[L.LemPhysicsFrame]);
    if L.LemPhysicsFrame = 7 then
      Transition(L, baFalling);
  end;
end;

function TLemmingGame.HandleShimmying(L: TLemming): Boolean;
var
  i: Integer;
  LemDY: Integer;
begin
  Result := True;
  if L.LemPhysicsFrame mod 2 = 0 then
  begin
    // Check whether we find terrain to walk onto
    for i := 0 to 2 do
    begin
      if HasPixelAt(L.LemX + L.LemDX, L.LemY - i) and not HasPixelAt(L.LemX + L.LemDX, L.LemY - i - 1) then
      begin
        Inc(L.LemX, L.LemDX);
        Dec(L.LemY, i);
        Transition(L, baWalking);
        Exit;
      end;
    end;
    // Check whether we find terrain to hoist onto
    for i := 3 to 5 do
    begin
      if HasPixelAt(L.LemX + L.LemDX, L.LemY - i) and not HasPixelAt(L.LemX + L.LemDX, L.LemY - i - 1) then
      begin
        Inc(L.LemX, L.LemDX);
        Dec(L.LemY, i - 4);
        L.LemIsStartingAction := False;
        Transition(L, baHoisting);
        Inc(L.LemFrame, 2);
        Inc(L.LemPhysicsFrame, 2);
        Exit;
      end;
    end;
    // Check whether we fall down due to a wall
    for i := 5 to 6 do
    begin
      if HasPixelAt(L.LemX + L.LemDX, L.LemY - i) then
      begin
        if L.LemIsSlider then
        begin
          Inc(L.LemX, L.LemDX);
          Transition(L, baSliding);
        end else
          Transition(L, baFalling);
        Exit;
      end;
    end;
    // Check whether we fall down due to not enough ceiling terrain
    if not (HasPixelAt(L.LemX + L.LemDX, L.LemY - 9) or HasPixelAt(L.LemX + L.LemDX, L.LemY - 10)) then
    begin
      LemDY := FindGroundPixel(L.LemX, L.LemY -9);

      // For transition to Climber, there must be at least 2px of climbable terrain
      if (LemDY <= -1) and L.LemIsClimber then
        begin
          //TurnAround(L);
          Dec(L.LemY);
          Transition(L, baTurning); // Turner then transitions to Climber
          Exit;
        end else
          Transition(L, baFalling);
          Exit;
    end;
    // Check whether we fall down due a checkerboard ceiling
    if HasPixelAt(L.LemX + L.LemDX, L.LemY - 8) and (not HasPixelAt(L.LemX + L.LemDX, L.LemY - 9)) then
    begin
      Transition(L, baFalling);
      Exit;
    end;
    // Move along
    Inc(L.LemX, L.LemDX);
    if HasPixelAt(L.LemX, L.LemY - 8) then
    begin
      Inc(L.LemY, 1);
      if HasPixelAt(L.LemX, L.LemY) then
      begin
        Transition(L, baWalking);
        Exit;
      end else if L.LemY >= Level.Info.Height + 8 then
      begin
        Transition(L, baFalling);
        Exit;
      end;
    end;
    if not HasPixelAt(L.LemX, L.LemY - 9) then
      Dec(L.LemY, 1);
      if HasPixelAt(L.LemX, L.LemY - 5) then
      begin
        Dec(L.LemY, 5);
        Transition(L, baWalking);
        Exit;
      end;
  end
end;

function TLemmingGame.HandleJumping(L: TLemming): Boolean;
var
  JumperArcFrames: Integer;

  procedure HandleJumperWallBounce;
  begin
    if (L.LemJumperBounceAllowance = 0) then
      Transition(L, baFalling)
    else begin
      TurnAround(L);
      Dec(L.LemJumperBounceAllowance);
    end;
  end;

  procedure DoJumperTriggerChecks;
  begin
    if not HasTriggerAt(L.LemX, L.LemY, trSplitter) then
      L.LemInSplitter := DOM_NOOBJECT
    else
      if HandleSplitter(L, L.LemX, L.LemY) then
        Exit;

    if HasTriggerAt(L.LemX, L.LemY, trZombie, L)
      and not (L.LemIsZombie or L.LemIsInvincible) then
        RemoveLemming(L, RM_ZOMBIE);

    if HasTriggerAt(L.LemX, L.LemY, trForceLeft, L) then
      HandleForceField(L, -1)
    else if HasTriggerAt(L.LemX, L.LemY, trForceRight, L) then
      HandleForceField(L, 1);
  end;

  function ShouldContinueJumping: Boolean;
  var
    IgnoreX: Integer;
  begin
    Result := False;

    if L.LemDX = 1 then
      IgnoreX := -1
    else
      IgnoreX := 1;

    // Ignore pixels below head height unless approached from the side
    if HasPixelAt(L.LemX + IgnoreX, L.LemY) then
      Result := True;
  end;

  function MakeJumpMovement: Boolean;
  var
    Pattern: TJumpPattern;
    PatternIndex: Integer;
    i, n, CheckX: Integer;
  begin
    Result := false;

    JumperArcFrames := 13;

    case L.LemJumpProgress of
      0..1: PatternIndex := 0;
      2..3: PatternIndex := 1;
      4..8: PatternIndex := L.LemJumpProgress -2;
      9..10: PatternIndex := 7;
      11..12: PatternIndex := 8;
      else Exit;
    end;

    Pattern := JUMP_PATTERNS[PatternIndex];

    FillChar(L.LemJumpPositions, SizeOf(L.LemJumpPositions), $FF);

    for i := 0 to 5 do
    begin
      L.LemJumpPositions[i, 0] := L.LemX;
      L.LemJumpPositions[i, 1] := L.LemY;

      if (Pattern[i][0] = 0) and (Pattern[i][1] = 0) then
        Break;

      if (Pattern[i][0] <> 0) then // Wall check
      begin
        CheckX := L.LemX + L.LemDX;

        if not ShouldContinueJumping then
        begin
          if HasPixelAt(CheckX, L.LemY) or (HasTriggerAt(CheckX, L.LemY, trWater) and L.LemIsSwimmer)
                                        or (HasWaterObjectAt(CheckX, L.LemY) and L.LemIsInvincible) then
          begin
            for n := 1 to 8 do
            begin
              if not HasPixelAt(CheckX, L.LemY - n) then
              begin
                if n <= 2 then
                begin
                  L.LemX := CheckX;
                  L.LemY := L.LemY - n + 1;
                  fLemNextAction := baWalking;
                end else if n <= 5 then begin
                  L.LemX := CheckX;
                  L.LemY := L.LemY - n + 5;

                  if not ShouldContinueJumping then
                  begin
                    fLemNextAction := baHoisting;
                    fLemJumpToHoistAdvance := true;
                  end;
                end else begin
                  L.LemX := CheckX;
                  L.LemY := L.LemY - n + 8;

                  if not ShouldContinueJumping then
                    fLemNextAction := baHoisting;
                end;

                Exit;
              end;

              if ((n = 5) and not (L.LemIsClimber)) or (n = 7) then
              begin
                if L.LemIsClimber then
                begin
                  L.LemX := CheckX;
                  fLemNextAction := baClimbing;
                end else begin
                  if L.LemIsSlider then
                  begin
                    Inc(L.LemX, L.LemDX);
                    fLemNextAction := baSliding;
                  end else
                    HandleJumperWallBounce;
                end;
                Exit;
              end;
            end;
          end;
        end;
      end;

      if (Pattern[i][1] < 0) then // Head check
      begin
        if HasPixelAt(L.LemX, L.LemY - 10) then
        begin
          fLemNextAction := baFalling;
          Exit;
        end;
      end;

      L.LemX := L.LemX + (Pattern[i][0] * L.LemDX);
      L.LemY := L.LemY + Pattern[i][1];

      DoJumperTriggerChecks;

      if HasPixelAt(L.LemX, L.LemY) then // Foot check
      begin
        // Ignore pixels below original head height
        if (L.LemJumpProgress > 2) then
        begin
          fLemNextAction := baWalking;
          Exit;
        end;
      end;
    end;

    Result := True;
  end;
begin
  if MakeJumpMovement then
  begin
    Inc(L.LemJumpProgress);

    if (L.LemJumpProgress >= 8) and (L.LemIsGlider) then
      fLemNextAction := baGliding
    else if L.LemJumpProgress = JumperArcFrames then
      fLemNextAction := baWalking;
  end;

  Result := True;
end;

function TLemmingGame.FindGroundPixel(x, y: Integer): Integer;
begin
  // Find the new ground pixel
  // If Result = 4, then at least 4 pixels are air below (X, Y)
  // If Result = -10, then at least 10 pixels are terrain above (X, Y)
  Result := 0;
  if HasPixelAt(x, y) then
  begin
    while HasPixelAt(x, y + Result - 1) and (Result > -10) do
      Dec(Result);
  end
  else
  begin
    Inc(Result);
    while (not HasPixelAt(x, y + Result)) and (Result < 4) do
      Inc(Result);
  end;
end;

function TLemmingGame.HasWaterObjectAt(x, y: Integer): Boolean;
begin
  Result := False
         or HasTriggerAt(x, y, trWater)
         or HasTriggerAt(x, y, trPoison)
         or HasTriggerAt(x, y, trVinewater)
         or HasTriggerAt(x, y, trBlasticine)
         or HasTriggerAt(x, y, trLava);
end;

function TLemmingGame.HasIndestructibleAt(x, y, Direction: Integer;
                                          Skill: TBasicLemmingAction): Boolean;
begin
  // Check for indestructible terrain at position (x, y), depending on skill.
  Result := (    ( HasTriggerAt(X, Y, trSteel) )
              or ( HasTriggerAt(X, Y, trOWUp) and (Skill in [baBashing, baMining, baDigging]))  // Propeller
              or ( HasTriggerAt(X, Y, trOWDown) and (Skill in [baBashing, baFencing, baLasering//, baPropelling
              ]))
              or ( HasTriggerAt(X, Y, trOWLeft) and (Direction = 1) and (Skill in [baBashing, baFencing, baMining, baLasering]))
              or ( HasTriggerAt(X, Y, trOWRight) and (Direction = -1) and (Skill in [baBashing, baFencing, baMining, baLasering]))
            );
end;

function TLemmingGame.HasSteelAt(X, Y: Integer): Boolean;
begin
  Result := (PhysicsMap.PixelS[X, Y] and PM_STEEL <> 0);
end;



function TLemmingGame.HandleMining(L: TLemming): Boolean;
  procedure MinerTurn(L: TLemming; X, Y: Integer);
  begin
    if HasSteelAt(X, Y) then CueSoundEffect(SFX_Steel_OWW, L.Position);
    // Independently of (X, Y) this check is always made at Lem position
    // No longer check at Lem position, due to www.lemmingsforums.net/index.php?topic=2547.0
    if HasPixelAt(L.LemX, L.LemY-1) then Dec(L.LemY);
    Transition(L, baWalking, True);  // Turn around as well
  end;

begin
  Result := True;

  if L.LemPhysicsFrame in [1, 2] then
    ApplyMinerMask(L, L.LemPhysicsFrame - 1, 0, 0)

  else if L.LemPhysicsFrame in [3, 15] then
  begin
    if L.LemIsSlider and LemCanDehoist(L, false) then
    begin
      Transition(L, baDehoisting, true);
      Exit;
    end;

    Inc(L.LemX, 2*L.LemDx);
    Inc(L.LemY);

    if L.LemIsSlider and LemCanDehoist(L, true) then
    begin
      Dec(L.LemX, L.LemDX);
      Transition(L, baDehoisting, true);
      Exit;
    end;

    // Note that all if-checks are relative to the end position!

    // Lem cannot go down, so turn; see www.lemmingsforums.net/index.php?topic=2547.0
    if     HasIndestructibleAt(L.LemX - L.LemDx, L.LemY - 1, L.LemDx, baMining)
       and HasIndestructibleAt(L.LemX, L.LemY - 1, L.LemDx, baMining) then
    begin
      Dec(L.LemX, 2*L.LemDx);
      MinerTurn(L, L.LemX + 2*L.LemDx, L.LemY - 1);
    end

    // This first check is only relevant during the very first cycle.
    // Otherwise the pixel was already checked in frame 15 of the previous cycle
    else if (L.LemPhysicsFrame = 3) and HasIndestructibleAt(L.LemX - L.LemDx, L.LemY - 2, L.LemDx, baMining) then
    begin
      Dec(L.LemX, 2*L.LemDx);
      MinerTurn(L, L.LemX + L.LemDx, L.LemY - 2);
    end

    // Do we really want the to check the second HasPixel during frame 3 ????
    else if     not HasPixelAt(L.LemX - L.LemDx, L.LemY - 1) // Lem can walk over it
            and not HasPixelAt(L.LemX - L.LemDx, L.LemY)
            and not HasPixelAt(L.LemX - L.LemDx, L.LemY + 1) then
    begin
      Dec(L.LemX, L.LemDx);
      Inc(L.LemY);
      Transition(L, baFalling);
      L.LemFallen := L.LemFallen + 1;
    end

    else if HasIndestructibleAt(L.LemX, L.LemY - 2, L.LemDx, baMining) then
    begin
      Dec(L.LemX, L.LemDx);
      MinerTurn(L, L.LemX + L.LemDx, L.LemY - 2);
    end

    else if not HasPixelAt(L.LemX, L.LemY) then
    begin
      Inc(L.LemY);
      Transition(L, baFalling);
    end

    else if HasIndestructibleAt(L.LemX + L.LemDx, L.LemY - 2, L.LemDx, baMining) then
      MinerTurn(L, L.LemX + L.LemDx, L.LemY - 2)

    else if HasIndestructibleAt(L.LemX, L.LemY, L.LemDx, baMining) then
      MinerTurn(L, L.LemX, L.LemY);
  end;
end;

function TLemmingGame.HandleFalling(L: TLemming): Boolean;
var
  CurrFallDist: Integer;
  MaxFallDist: Integer;

  function IsFallFatal: Boolean;
  begin
    Result := (not (L.LemIsFloater or L.LemIsGlider))
          and (not HasTriggerAt(L.LemX, L.LemY, trExit))
          and (not HasTriggerAt(L.LemX, L.LemY, trNoSplat))
          and ((L.LemFallen > MAX_FALLDISTANCE) or HasTriggerAt(L.LemX, L.LemY, trSplat));
  end;

  function CheckFloaterOrGliderTransition: Boolean;
  begin
    Result := false;

    if L.LemIsFloater and (L.LemTrueFallen > 16) and (CurrFallDist = 0) then
    begin
      // Depending on updrafts, this happens on the 6th-8th frame
      Transition(L, baFloating);
      Result := true;
    end else if L.LemIsGlider and
      ((L.LemTrueFallen > 8) or
       ((L.LemInitialFall) and (L.LemTrueFallen > 6))) then
    begin
      Transition(L, baGliding);
      Result := true;
    end;
  end;
begin
  Result := True;

  CurrFallDist := 0;
  MaxFallDist := 3;

  if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then MaxFallDist := 2;

  if CheckFloaterOrGliderTransition then // This check needs to happen even if we don't enter the while loop.
    Exit;

  // Move lem until hitting ground
  while (CurrFallDist < MaxFallDist) and not HasPixelAt(L.LemX, L.LemY) do
  begin
    if (CurrFallDist > 0) and CheckFloaterOrGliderTransition then // Already checked above on first iteration.
      Exit;

    Inc(L.LemY);
    Inc(CurrFallDist);
    Inc(L.LemFallen);
    Inc(L.LemTrueFallen);
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then L.LemFallen := 0;
  end;

  if L.LemFallen > MAX_FALLDISTANCE then L.LemFallen := MAX_FALLDISTANCE + 1;
  if L.LemTrueFallen > MAX_FALLDISTANCE then L.LemTrueFallen := MAX_FALLDISTANCE + 1;

  if CurrFallDist < MaxFallDist then
  begin
    // Object checks at hitting ground
    if IsFallFatal and not L.LemIsInvincible then
      fLemNextAction := baSplatting
    else
      fLemNextAction := baWalking;
  end;
end;

procedure TLemmingGame.PopBalloon(L: TLemming; BalloonPopTimerValue: Integer; NewAction: TBasicLemmingAction);
begin
  L.LemBalloonPopTimer := BalloonPopTimerValue;
  CueSoundEffect(SFX_BalloonPop, L.Position);
  Transition(L, NewAction);
end;

function TLemmingGame.HandleBallooning(L: TLemming): Boolean;
var
XChecks, YChecks, XOffset: Integer;
ShouldPop: Boolean;

  procedure Pop;
  begin
    ShouldPop := True;
    PopBalloon(L, 1, baFalling);
  end;

begin
  Result := True;
  ShouldPop := False;

  // Pre-flight checks
  if L.LemPhysicsFrame <= 8 then
  begin
    for XChecks := 0 to 5 do
    begin
      YChecks := FindGroundPixel(L.LemX + (XChecks * L.LemDX), L.LemY);

      // Only turn if the lem would turn/climb anyway
      if (YChecks < -9) then
        TurnAround(L);

      XOffset := 0;  // Initialise XOffset

      // Move away from terrain that would immediately pop the balloon
      case L.LemFrame of
        0 .. 4: XOffset := L.LemFrame;
        5, 6: XOffset := 4;
        7, 8: XOffset := 5;
      end;

      YChecks := FindGroundPixel(L.LemX - (XOffset * L.LemDX), L.LemY);

      if (YChecks < -9) then
      begin
        // Prevent clipping into opposite terrain
        if not HasPixelAt(L.LemX + L.LemDX, L.LemY -1) then
          Inc(L.LemX, L.LemDX)
        else if not HasPixelAt(L.LemX, L.LemY -1) then
          Dec(L.LemY, 1);
      end;
    end;

  end else begin // Flight checks

    // Always ascend
    Dec(L.LemY);

    // Slight diagonal drift every 2 frames
    if (L.LemPhysicsFrame in [10, 12, 14, 16])
    // Unless there is terrain at foot position, in which case we only ascend
    and not HasPixelAt(L.LemX, L.LemY) then
      Inc(L.LemX, L.LemDX);

    // Move upwards faster in an updraft
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then Dec(L.LemY);

    // Pop the balloon when there is terrain overhead
    for YChecks := 27 to 30 do
    begin
      case YChecks of
        27, 28: begin
                for XChecks := -5 to 5 do
                  begin
                    if HasPixelAt((L.LemX + L.LemDX) - XChecks, L.LemY - YChecks)
                      and not HasPixelAt(L.LemX, L.LemY) then Pop;
                  end;
                end;
        29: begin
              for XChecks := -4 to 4 do
              begin
                if HasPixelAt((L.LemX + L.LemDX) - XChecks, L.LemY - YChecks)
                  and not HasPixelAt(L.LemX, L.LemY) then Pop;
              end;
            end;
        30: begin
              for XChecks := -2 to 2 do
              begin
                if HasPixelAt((L.LemX + L.LemDX) - XChecks, L.LemY - YChecks)
                  and not HasPixelAt(L.LemX, L.LemY) then Pop;
              end;
            end;
      end;
    end;

    // Bounce and turn when there is terrain at the side of the balloon
    for YChecks := 20 to 26 do
    begin
      for XChecks := 4 to 7 do
      begin
        if HasPixelAt(L.LemX + (XChecks * L.LemDX), L.LemY - YChecks)
          and not ShouldPop then
            TurnAround(L);
      end;
    end;

    // Walk onto terrain if there is a clear platform of at least 1px
    if HasPixelAt(L.LemX, L.LemY) and not HasPixelAt(L.LemX, L.LemY - 1) then
      PopBalloon(L, 1, baWalking);

    // Pop balloon if a laser or projectile makes contact with it
    for YChecks := 10 to 30 do
    for XChecks := -6 to 6 do
    begin
      if HasLaserAt(L.LemX, L.LemY - YChecks) then
        PopBalloon(L, 1, baFalling);

      if HasProjectileAt(L.LemX - XChecks, L.LemY - YChecks) then
        PopBalloon(L, 1, baFalling);
    end;
  end;
end;

function TLemmingGame.HandleFloating(L: TLemming): Boolean;
var
  MaxFallDist: Integer;
const
  FloaterFallTable: array[1..17] of Integer =
    (3, 3, 3, 3, -1, 0, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2);
begin
  Result := True;

  MaxFallDist := FloaterFallTable[L.LemPhysicsFrame];
  if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then Dec(MaxFallDist);

  if MaxFallDist > MaxIntValue([FindGroundPixel(L.LemX, L.LemY), 0]) then
  begin
    // Lem has found solid terrain
    Inc(L.LemY, MaxIntValue([FindGroundPixel(L.LemX, L.LemY), 0]));
    fLemNextAction := baWalking;
  end
  else
    Inc(L.LemY, MaxFallDist);
end;


function TLemmingGame.HandleGliding(L: TLemming): Boolean;
var
  MaxFallDist, GroundDist: Integer;
  LemDy: Integer;

  // Check for turning around
  function DoTurnAround(L: TLemming; MoveForwardFirst: Boolean): Boolean;
  var
    Dy: Integer;
    CurLemX: Integer; // Adapted X-coordinate of Lemming
  begin
    CurLemX := L.LemX;
    if MoveForwardFirst then Inc(CurLemX, L.LemDx);

    // Search for free pixels below
    Dy := 0;
    repeat
      // Bug-fix for www.lemmingsforums.net/index.php?topic=2693
      if HasPixelAt(CurLemX, L.LemY + Dy) and HasPixelAt(CurLemX - L.LemDx, L.LemY + Dy) then
      begin
        // Abort computation and let lemming turn around
        Result := True;
        Exit;
      end;
      Inc(Dy);
    until (Dy > 3) or (not HasPixelAt(CurLemX, L.LemY + Dy));

    if Dy > 3 then Result := True
    else Result := False;
  end;

  // Special behavior in 1-pxiel wide shafts: Move one pixel down even when turning
  procedure CheckOnePixelShaft(L: TLemming);
  var
    LemYDir: Integer;

    function HasConsecutivePixels: Boolean;
    var
      i: Integer;
      OneWayCheckType: TTriggerTypes;
    begin
      // Check at LemY +1, +2, +3 for (a) solid terrain, or (b) a one-way field that will turn the lemming around
      Result := false;

      if L.LemDX > 0 then
        OneWayCheckType := trForceLeft
      else
        OneWayCheckType := trForceRight;

      for i := 1 to 3 do
        if not (HasPixelAt(L.LemX + L.LemDX, L.LemY + i) or
                HasTriggerAt(L.LemX + L.LemDX, L.LemY + i, OneWayCheckType)) then
          Exit;

      Result := true;
    end;
  begin
    // Move upwards if in updraft
    LemYDir := 1;
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then LemYDir := -1;

    if    ((FindGroundPixel(L.LemX + L.LemDx, L.LemY) < -4) and DoTurnAround(L, True))
       or (HasConsecutivePixels) then
    begin
      if HasPixelAt(L.LemX, L.LemY) and (LemYDir = 1) then
        fLemNextAction := baWalking
      else if HasPixelAt(L.LemX, L.LemY - 2) and (LemYDir = -1) then
        // Do nothing
      else
        Inc(L.LemY, LemYDir);
    end;
  end;

  function HeadCheck(LemX, Lemy: Integer): Boolean; // Returns False if lemming hits his head
  begin
    Result := not (     HasPixelAt(LemX - 1, LemY - 12)
                    and HasPixelAt(LemX, LemY - 12)
                    and HasPixelAt(LemX + 1, LemY - 12));
  end;


const
  GliderFallTable: array[1..17] of Integer =
    (3, 3, 3, 3, -1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
begin
  Result := True;
  MaxFallDist := GliderFallTable[L.LemPhysicsFrame];

  if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then
  begin
    Dec(MaxFallDist);
    // Rise a pixel every second frame
    if (L.LemPhysicsFrame >= 9) and (L.LemPhysicsFrame mod 2 = 1)
       and (not HasPixelAt(L.LemX + L.LemDx, L.LemY + MaxFallDist - 1))
       and HeadCheck(L.LemX, L.LemY - 1) then
      Dec(MaxFallDist);
  end;

  Inc(L.LemX, L.LemDx);

  // Do upwards movement right away
  if MaxFallDist < 0 then Inc(L.LemY, MaxFallDist);

  GroundDist := FindGroundPixel(L.LemX, L.LemY);

  if GroundDist < -4 then // Pushed down or turn around
  begin
    if DoTurnAround(L, false) then
    begin
      // Move back and turn around
      Dec(L.LemX, L.LemDx);
      TurnAround(L);
      CheckOnePixelShaft(L);
    end
    else
    begin
      // Move down
      LemDy := 0;
      repeat
        Inc(LemDy);
      until not HasPixelAt(L.LemX, L.LemY + LemDy);
      Inc(L.LemY, LemDy);
    end
  end

  else if GroundDist < 0 then // Move 1 to 4 pixels up
  begin
    Inc(L.LemY, GroundDist);
    fLemNextAction := baWalking;
  end

  else if MaxFallDist > 0 then // No pixel above current location; not checked if one has moved upwards
  begin // Same algorithm as for faller!
    if MaxFallDist > GroundDist then
    begin
      // Lem has found solid terrain
      CustomAssert(GroundDist >= 0, 'glider GroundDist negative');
      Inc(L.LemY, GroundDist);
      fLemNextAction := baWalking;
    end
    else
      Inc(L.LemY, MaxFallDist);
  end

  else if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then // Head check for pushing down in updraft
  begin
    // Move down at most 2 pixels until the HeadCheck passes
    LemDy := -1;
    while (not HeadCheck(L.LemX, L.LemY)) and (LemDy < 2) do
    begin
      Inc(L.LemY);
      Inc(LemDy);
      // Check whether the glider has reached the ground
      if HasPixelAt(L.LemX, L.LemY) then
      begin
        fLemNextAction := baWalking;
        LemDy := 4;
      end;
    end;
  end;
end;

function TLemmingGame.HandleThrowing(L: TLemming): Boolean;
var
  NewProjectile: TProjectile;
begin
  case L.LemPhysicsFrame of
    1: begin
         L.LemFrame := 0;

         if not IsSimulating then
         begin
           if L.LemAction = baGrenading then
             NewProjectile := TProjectile.CreateGrenade(PhysicsMap, L)
           else
             NewProjectile := TProjectile.CreateSpear(PhysicsMap, L);

           ProjectileList.Add(NewProjectile);

           L.LemHoldingProjectileIndex := ProjectileList.Count - 1;
         end;
       end;

    0, 2, 3: L.LemFrame := 0;

    6: begin
         if (L.LemAction = baSpearing) then
           CueSoundEffect(SFX_SpearThrow, L.Position)
         else
           CueSoundEffect(SFX_GrenadeThrow, L.Position);

         if not HasPixelAt(L.LemX, L.LemY) then Transition(L, baFalling);
       end;

    7..8: if not HasPixelAt(L.LemX, L.LemY) then Transition(L, baFalling);

    9: if not HasPixelAt(L.LemX, L.LemY) then Transition(L, baFalling) else Transition(L, baLooking);
  end;

  Result := true;
end;

//function TLemmingGame.HandleBatting(L: TLemming): Boolean; // Batter
//var
//  NewProjectile: TProjectile;
//begin
//  if L.LemPhysicsFrame = 4 then
//  begin
//     if not IsSimulating then // Is this needed? We will never simulate Batters
//     begin
//       NewProjectile := TProjectile.CreateBat(PhysicsMap, L);
//
//       ProjectileList.Add(NewProjectile);
//
//       L.LemHoldingProjectileIndex := ProjectileList.Count - 1;
//     end;
//  end;
//
//  if L.LemEndOfAnimation then
//    Transition(L, baWalking);
//
//  Result := true;
//end;

function TLemmingGame.HandleLooking(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then Transition(L, baWalking);
end;

function TLemmingGame.HandleSplatting(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleExiting(L: TLemming): Boolean;
begin
  Result := False;

  if IsOutOfTime then
  begin
    if NukeIsActive and (L.LemExplosionTimer <= 0) and (Index_LemmingToBeNuked > L.LemIndex) then
      Transition(L, baOhnoing);
  end;

  // Lems that have begun to exit after time has run out still count as saved
  if L.LemEndOfAnimation then
  begin
    { Zombies, (Rivals in Normal Exits) and (Normals in Rival Exits) decrease save count by 1
      - Neutrals count as +1 in both Exit types - LemIsInRivalExit is checked in HandleExit }
    if L.LemIsZombie or ((L.LemIsRival and not L.LemIsInRivalExit)
                     or  (L.LemIsInRivalExit and not L.LemIsRival) and not L.LemIsNeutral) then
    begin
      RemoveLemming(L, RM_NEUTRAL, True);
      Dec(LemmingsIn);
    end else
      RemoveLemming(L, RM_SAVE);
  end;
end;

function TLemmingGame.HandleVaporizing(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleVinetrapping(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleBlocking(L: TLemming): Boolean;
begin
  Result := True;
  L.LemIsWaterblocker := False;

  if HasWaterObjectAt(L.LemX, L.LemY) then
  begin
    L.LemIsWaterblocker := True;

    case L.LemPhysicsFrame of
      0,  8: Dec(L.LemY);
      4, 12: Inc(L.LemY);
    end;
  end;

  if not (HasPixelAt(L.LemX, L.LemY) or HasWaterObjectAt(L.LemX, L.LemY)) then
    Transition(L, baFalling);
end;

function TLemmingGame.HandleShrugging(L: TLemming): Boolean;
begin
  Result := True;

  if (LemmingsOut > 0) and (L.LemFrame = 7) and fGameCheated then
    Finish(GM_FIN_TERMINATE)
  else if L.LemEndOfAnimation then
    Transition(L, baWalking);
end;

function TLemmingGame.HandleTimebombing(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
  begin
    Transition(L, baTimebombFinish);
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    Result := False;
  end
  else if not HasPixelAt(L.LemX, L.LemY) then
  begin
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    // Let lemming fall
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 2]))
    else
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 3]));
  end;
end;


function TLemmingGame.HandleTimebombFinish(L: TLemming): Boolean;
begin
  Renderer.IsFreezerExplosion := False;
  Result := False;

  if L.LemAction = baTimebombFinish then
    ApplyTimebombMask(L);

  // Invincible lems aren't removed, but do create fireworks and a crater
  if L.LemIsInvincible then
    Transition(L, baWalking)
  else
    RemoveLemming(L, RM_KILL);

  L.LemExploded := True;
  L.LemParticleTimer := PARTICLE_FRAMECOUNT;
  fParticleFinishTimer := PARTICLE_FRAMECOUNT;
end;

function TLemmingGame.HandleOhNoing(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
  begin
    DoExplosionCrater := True;
    Transition(L, baExploding);
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    Result := False;
  end
  else if not HasPixelAt(L.LemX, L.LemY) then
  begin
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    // Let lemming fall
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 2]))
    else
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 3]));
  end;
end;


function TLemmingGame.HandleExploding(L: TLemming): Boolean;
begin
  Renderer.IsFreezerExplosion := False;
  Result := False;

  if (L.LemAction = baExploding) and DoExplosionCrater then
    ApplyExplosionMask(L);

  // Invincible lems aren't removed, but still create fireworks and a crater
  if L.LemIsInvincible then
    Transition(L, baWalking)
  else
    RemoveLemming(L, RM_KILL);

  L.LemExploded := True;
  L.LemParticleTimer := PARTICLE_FRAMECOUNT;
  fParticleFinishTimer := PARTICLE_FRAMECOUNT;
end;

function TLemmingGame.HandleFreezing(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
  begin
    Transition(L, baFreezerExplosion);
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    Result := False;
  end
  else if not HasPixelAt(L.LemX, L.LemY) then
  begin
    L.LemHasBlockerField := False; // Remove blocker field
    SetBlockerMap;
    // Let lemming fall
    if HasTriggerAt(L.LemX, L.LemY, trUpdraft) then
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 2]))
    else
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 3]));
  end;
end;

function TLemmingGame.HandleFreezerExplosion(L: TLemming): Boolean;
begin
  Renderer.IsFreezerExplosion := True;
  Result := false;

  if (L.LemAction = baFreezerExplosion) then
  begin
    ApplyFreezerIceCube(L);

    // Invincible lems don't become frozen, but do leave an ice cube
    if L.LemIsInvincible then
      Transition(L, baWalking)
    else
      Transition(L, baFrozen);

    L.LemParticleTimer := PARTICLE_FRAMECOUNT;
    fParticleFinishTimer := PARTICLE_FRAMECOUNT;
  end;
end;

function TLemmingGame.HandleFrozen(L: TLemming): Boolean;

  function CanUnfreeze: Boolean;
  begin
    Result := False

    // Top 5 pixels must be removed
    or (not HasPixelAt(L.LemX, L.LemY - 11)
    and not HasPixelAt(L.LemX, L.LemY - 10)
    and not HasPixelAt(L.LemX, L.LemY -  9)
    and not HasPixelAt(L.LemX, L.LemY -  8)
    and not HasPixelAt(L.LemX, L.LemY -  7))

    // Middle 4 pixels must be removed
    or (not HasPixelAt(L.LemX, L.LemY - 7)
    and not HasPixelAt(L.LemX, L.LemY - 6)
    and not HasPixelAt(L.LemX, L.LemY - 5)
    and not HasPixelAt(L.LemX, L.LemY - 4))

    // Bottom 4 pixels must be removed
    or (not HasPixelAt(L.LemX, L.LemY - 4)
    and not HasPixelAt(L.LemX, L.LemY - 3)
    and not HasPixelAt(L.LemX, L.LemY - 2)
    and not HasPixelAt(L.LemX, L.LemY - 1));
  end;

  procedure Unfreeze;
  begin
    Transition(L, baUnfreezing);
    L.LemUnfreezingTimer := 12;
  end;
begin
  Result := True;

  // Normal Freezer checks
  if (L.LemAction = baFrozen) and CanUnfreeze then
  begin
    // Freezer at bottom-of-level checks
    if (L.LemY > PhysicsMap.Height) then
    begin
      // The topmost 2 pixels of the visible ice cube must be removed to allow unfreezing
      if not    HasPixelAt(L.LemX, L.LemY - 11)
        and not HasPixelAt(L.LemX, L.LemY - 10) then
          Unfreeze;
    end else
    // Freezer at top-of-level checks
    if (L.LemY <= 7) then
    begin
      // The top-or-bottom-most pixel of the visible ice cube must be removed to allow unfreezing
      if not   HasPixelAt(L.LemX, 0)
        or not HasPixelAt(L.LemX, L.LemY -1) then
          Unfreeze;
    end else
      Unfreeze;
  end;

  if NukeIsActive then L.LemHideCountdown := False;
end;

function TLemmingGame.HandleUnfreezing(L: TLemming): Boolean;
var
  LemDY: Integer;
begin
  Result := True;

  if L.LemEndOfAnimation then
  begin
    LemDY := FindGroundPixel(L.LemX, L.LemY);

    if (LemDY < 0) then
      BoostAscend(L, Abs(LemDY))
    else if HasPixelAt(L.LemX, L.LemY) then
      Transition(L, baWalking)
    else
      Transition(L, baFalling);
  end;
end;

procedure TLemmingGame.RemoveLemming(L: TLemming; RemMode: Integer = 0; Silent: Boolean = false);
begin
  if IsSimulating then Exit;

  if L.LemIsZombie then
  begin
    CustomAssert(RemMode <> RM_SAVE, 'Zombie removed with RM_SAVE removal type!');
    CustomAssert(RemMode <> RM_ZOMBIE, 'Zombie removed with RM_ZOMBIE removal type!');

    L.LemRemoved := True;

    if L.LemIsZombie and (RemMode = RM_NEUTRAL) and not Silent then
      CueSoundEffect(SFX_ZombieFallOff, L.Position)
    else if (RemMode = RM_NEUTRAL) and not Silent then
      CueSoundEffect(SFX_FallOff, L.Position)
  end

  else if not L.LemRemoved then // Usual and living lemming
  begin
    Inc(LemmingsRemoved);
    Dec(LemmingsOut);
    L.LemRemoved := True;
    L.LemIsInvincible := False;

    case RemMode of
    RM_SAVE : begin
                Inc(LemmingsIn);
                if LemmingsIn = Level.Info.RescueCount then
                begin
                  GameResultRec.gLastRescueIteration := fCurrentIteration;
                  fReplayManager.ExpectedCompletionIteration := fCurrentIteration;
                end;
                UpdateLevelRecords;
              end;
    RM_NEUTRAL: if L.LemIsZombie and not Silent then
                  CueSoundEffect(SFX_ZombieFallOff, L.Position)
                else if not Silent then
                  CueSoundEffect(SFX_FallOff, L.Position);
    RM_ZOMBIE: begin
                 if not Silent then
                   CueSoundEffect(SFX_Zombie);
                 L.LemIsZombie := True;
                 L.LemRemoved := False;
               end;
    end;           
  end;

  DoTalismanCheck;
end;


procedure TLemmingGame.UpdateLemmings;
{-------------------------------------------------------------------------------
  The main method: handling a single frame of the game.
-------------------------------------------------------------------------------}
begin
  fDoneAssignmentThisFrame := false;

  CheckReplayLoaded;

  // Don't update if the game is finished, or we've reached an unplayable state
  if fGameFinished or StateIsUnplayable then
    Exit;

  fSoundList.Clear(); // Clear list of played sound effects

  CheckAdjustSpawnInterval;
  CheckForQueuedAction; // Needs to be done before CheckForReplayAction, because it writes an assignment in the replay
  CheckForReplayAction;

  // Erase existing ShadowBridge
  if fExistShadow then
  begin
    fRenderer.ClearShadows;
    fExistShadow := false;
  end;

  // Just as a warning: do *not* mess around with the order here
  IncrementIteration;
  CheckReleaseLemming;
  CheckLemmings;
  UpdateProjectiles;
  CheckUpdateNuking;
  UpdateGadgets;

  if (fReplayManager.ExpectedCompletionIteration = fCurrentIteration) and (not Checkpass) then
    fReplayManager.ExpectedCompletionIteration := 0;

  // Get highest priority lemming under cursor
  GetPriorityLemming(fLemSelected, SkillPanelButtonToAction[fSelectedSkill], CursorPoint);

  DrawAnimatedGadgets;

  // Check lemmings under cursor
  HitTest;
  fSoundList.Clear(); // Clear list of played sound effects - just to be safe
end;

procedure TLemmingGame.UpdateLevelRecords;
var
  NewRecs: TLevelRecords;
  Skill: TSkillPanelButton;
begin
  // Don't update records if Infinite Skills or Infinite Time mode is active
  if IsInfiniteSkillsMode or IsInfiniteTimeMode then Exit;

  NewRecs.Wipe;
  NewRecs.LemmingsRescued.Value := LemmingsIn;

  if LemmingsIn = Level.Info.RescueCount then
  begin
    // We only want to update the rest when we're at the rescue count EXACTLY.
    NewRecs.TimeTaken.Value := fCurrentIteration;
    NewRecs.TotalSkills.Value := 0;
    NewRecs.SkillTypes.Value := 0;

    for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if Skill in Level.Info.Skillset then
      begin
        NewRecs.SkillCount[Skill].Value := SkillsUsed[Skill];
        NewRecs.TotalSkills.Value := NewRecs.TotalSkills.Value + SkillsUsed[Skill];
        if SkillsUsed[Skill] > 0 then
          NewRecs.SkillTypes.Value := NewRecs.SkillTypes.Value + 1;
      end;
  end;

  // Continue updating collectibles records for each new lem saved beyond the rescue count
  if LemmingsIn >= Level.Info.RescueCount then
    NewRecs.CollectiblesGathered.Value := Level.Info.CollectibleCount - CollectiblesRemain;

  if fReplayManager.IsThisUsersReplay then
  begin
    NewRecs.SetNameOnAll(GameParams.Username);
    if LemmingsIn >= Level.Info.RescueCount then
      GameParams.CurrentLevel.Status := lst_Completed
    else if GameParams.CurrentLevel.Status = lst_None then
      GameParams.CurrentLevel.Status := lst_Attempted;

    GameParams.CurrentLevel.WriteNewRecords(NewRecs, true);
  end else begin
    NewRecs.SetNameOnAll(fReplayManager.PlayerName);
    GameParams.CurrentLevel.WriteNewRecords(NewRecs, false);
  end;
end;

function TLemmingGame.HasLaserAt(X, Y: Integer): Boolean;
var
  i: Integer;
  L: TLemming;
  CheckPointA, CheckPointB: TPoint;
  LaserLine: TArray<TPoint>;
  VirtualX: Integer;
begin
  Result := False;

  // Find the relevant CheckPointA and CheckPointB
  for i := 0 to LemmingList.Count - 1 do
  begin
    L := LemmingList[i];

    if L.LemAction = baLasering then
    begin
      CheckPointA := Point(L.LemX, L.LemY);
      CheckPointB := L.LemLaserHitPoint;

      // Create virtual line array to represent laser
      SetLength(LaserLine, Abs(CheckPointB.X - CheckPointA.X) + 1);
      for VirtualX := 0 to High(LaserLine) do
      begin
        LaserLine[VirtualX].X := CheckPointA.X + (VirtualX * L.LemDX);
        LaserLine[VirtualX].Y := CheckPointA.Y - VirtualX;
      end;

      // Check if (X, Y) matches any point in LaserLine
      for VirtualX := Low(LaserLine) to High(LaserLine) do
      begin
        if (X = LaserLine[VirtualX].X) and (Y = LaserLine[VirtualX].Y) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;


function TLemmingGame.HasProjectileAt(X, Y: Integer): Boolean;
var
  i: Integer;
  P: TProjectile;
begin
  Result := False;

  for i := 0 to ProjectileList.Count - 1 do
  begin
    P := ProjectileList[i];

    if (P.X = X) and (P.Y = Y) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;


procedure TLemmingGame.UpdateProjectiles;
var
  i: Integer;
  P: TProjectile;

  function IsOutOfBounds(P: TProjectile): Boolean;
  begin
    Result := (P.X < -108) or (P.X >= Level.Info.Width + 108) or
              (P.Y < -108) or (P.Y >= Level.Info.Height + 108);
  end;
begin
  for i := ProjectileList.Count-1 downto 0 do
  begin
    P := ProjectileList[i];
    if P.Hit and (P.IsGrenade //or P.IsBat  // Batter
    ) then
       ProjectileList.Delete(i);
  end;

  for i := 0 to ProjectileList.Count-1 do
  begin
    P := ProjectileList[i];
    P.Update;
  end;

  for i := ProjectileList.Count-1 downto 0 do
  begin
    P := ProjectileList[i];
    if P.SilentRemove or IsOutOfBounds(P) then
      ProjectileList.Delete(i)
    else if P.Hit then
    begin
      if P.IsSpear then
      begin
        ApplySpear(P);
        CueSoundEffect(SFX_SpearHit);
        ProjectileList.Delete(i);
      end else //if P.IsGrenade then
      begin
        ApplyGrenadeExplosionMask(P);
        CueSoundEffect(SFX_Pop, Point(P.X, P.Y));
      end //else       // Batter
        //ApplyBat(P)
        ;
    end;
  end;
end;

procedure TLemmingGame.IncrementIteration;
var
  i: Integer;
  AX, AY: Integer; // Average position of entrances
  HatchOpenCount: Integer;

  function UseZombieSound: Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to Gadgets.Count-1 do
      if   (Gadgets[i].TriggerEffect = DOM_WINDOW)
        and Gadgets[i].IsPreassignedZombie then
      begin
        Result := true;
        Exit;
      end;
  end;
begin
  Inc(fCurrentIteration);
  Inc(fClockFrame);
  if DelayEndFrames > 0 then Dec(DelayEndFrames);

  if fParticleFinishTimer > 0 then
    Dec(fParticleFinishTimer);

  if IsSuperLemmingMode then
  begin
    if fClockFrame = 50 then
    begin
      fClockFrame := 0;
      if TimePlay > -5999 then Dec(TimePlay);
      if TimePlay = 0 then CueSoundEffect(SFX_TimeUp);
    end;
  end else if fClockFrame = 17 then
    begin
      fClockFrame := 0;
      if TimePlay > -5999 then Dec(TimePlay);
      if TimePlay = 0 then CueSoundEffect(SFX_TimeUp);
    end;

  // Hard coded dos frame numbers
  case CurrentIteration of
    15:
      // Prevents double-triggering the sound when Rewinding to the start
      if not IsBackstepping then
      begin
        if UseZombieSound then
          CueSoundEffect(SFX_Zombie)
        else
          CueSoundEffect(SFX_LetsGo);
      end;
    35:
      begin
        HatchesOpened := False;
        HatchOpenCount := 0;
        AX := 0;
        AY := 0;
        for i := 0 to Gadgets.Count - 1 do
          if Gadgets[i].TriggerEffectBase = DOM_WINDOW then // Uses TriggerEffectBase so that fake windows still animate
          begin
            Gadgets[i].Triggered := True;
            Gadgets[i].CurrentFrame := 1;
            HatchesOpened := true;
            Inc(HatchOpenCount);
            AX := AX + Gadgets[i].Center.X;
            AY := AY + Gadgets[i].Center.Y;
          end;
        if HatchesOpened then
        begin
          AX := AX div HatchOpenCount;
          AY := AY div HatchOpenCount;
          CueSoundEffect(SFX_Entrance, Point(AX, AY));
        end;
        if not HatchesOpened then
          PlayMusic;
        HatchesOpened := True;
      end;
    55:
      PlayMusic;
  end;

end;


procedure TLemmingGame.HitTest(Autofail: Boolean = false);
var
  L, OldLemSelected: TLemming;
begin
  if Autofail then fHitTestAutoFail := true;

  OldLemSelected := fRenderInterface.SelectedLemming;
  // Shadow stuff for updated selected lemming
  GetPriorityLemming(fLemSelected, SkillPanelButtonToAction[fSelectedSkill], CursorPoint);
  CheckForNewShadow;

  // Get new priority lemming including lems that cannot receive the skill
  GetPriorityLemming(L, baNone, CursorPoint);

  if L <> OldLemSelected then
  begin
    fLemSelected := L;
    fRenderInterface.SelectedLemming := L;
  end;
end;

function TLemmingGame.ProcessSkillAssignment(IsHighlight: Boolean = false): Boolean;
var
  Sel: TBasicLemmingAction;
begin
  Result := False;

  // Prevents overwriting same-frame assignments in ReplayInsert Mode
  if not (ReplayInsert and ReplayManager.HasAssignmentAt(CurrentIteration)) then
  begin
    // Convert buttontype to skilltype
    Sel := SkillPanelButtonToAction[fSelectedSkill];
    if Sel = baNone then Exit;

    Result := AssignNewSkill(Sel, IsHighlight);
  end;

  if not Result then PlayAssignFailSound;
end;

function TLemmingGame.ProcessHighlightAssignment: Boolean;
var
  L: TLemming;
begin
  Result := False;
  if GetPriorityLemming(L, baNone, CursorPoint) > 0 then
    fHighlightLemmingID := L.LemIndex
  else
    fHighlightLemmingID := -1;
end;

procedure TLemmingGame.ReplaySkillAssignment(aReplayItem: TReplaySkillAssignment);
var
  L: TLemming;
  i: Integer;
begin
  with aReplayItem do
  begin
    L := nil;

    if LemmingIdentifier = '' then
    begin
      if (LemmingIndex >= 0) and (LemmingIndex < LemmingList.Count) then
      begin
        L := LemmingList.List[LemmingIndex];
        LemmingIdentifier := L.LemIdentifier;
      end;
    end else begin
      for i := 0 to LemmingList.Count-1 do
        if LemmingList[i].LemIdentifier = LemmingIdentifier then
        begin
          L := LemmingList[i];
          LemmingIndex := L.LemIndex;
          Break;
        end;
    end;

    if (L <> nil) and (Skill in AssignableSkills) then
    begin
      fTargetLemmingID := L.LemIndex;
      AssignNewSkill(Skill, false, true);
    end;
  end;
end;


function TLemmingGame.GetSelectedSkill: Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to MAX_SKILL_TYPES_PER_LEVEL do
    if fSelectedSkill = fActiveSkills[i] then
    begin
      Result := i;
      Exit;
    end;
end;


procedure TLemmingGame.SetSelectedSkill(Value: TSkillPanelButton; MakeActive: Boolean = True; RightClick: Boolean = False);
  function CheckSkillInSet(Value: TSkillPanelButton): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to MAX_SKILL_TYPES_PER_LEVEL - 1 do
      if fActiveSkills[i] = Value then Result := true;
  end;
begin

  case Value of
    spbFaster:
      begin
        if not MakeActive then
        begin
          SpawnIntervalModifier := 0;
          Exit;
        end;

        if Level.Info.SpawnIntervalLocked or (CurrSpawnInterval = MINIMUM_SI) then Exit;

        if RightClick then
        begin
          RecordSpawnInterval(MINIMUM_SI);
        end else
          SpawnIntervalModifier := -1;
      end;
    spbSlower:
      begin
        if not MakeActive then
        begin
          SpawnIntervalModifier := 0;
          Exit;
        end;

        if Level.Info.SpawnIntervalLocked or (CurrSpawnInterval = Level.Info.SpawnInterval) then Exit;

        if RightClick then
        begin
          RecordSpawnInterval(Level.Info.SpawnInterval);
        end else
          SpawnIntervalModifier := 1;
      end;
    spbNuke:
      begin
        if StateIsUnplayable then
        begin
          Finish(GM_FIN_TERMINATE);
          Exit;
        end;

        RecordNuke(RightClick);
      end;
    spbPause: ; // Do Nothing
    spbNone: ; // Do Nothing
    else // All skill buttons
      begin
        if (not CheckSkillInSet(Value)) then
          Exit;

        if fSelectedSkill <> Value then
        begin
          fSelectedSkill := Value;
          CheckForNewShadow;
        end;

        if RightClick and (GetHighlitLemming <> nil) and (SkillPanelButtonToAction[Value] <> baNone) then
        begin
          if ProcessSkillAssignment(true) then
            fRenderInterface.ForceUpdate := true
          else
            PlayAssignFailSound(True);
        end;
      end;
  end;
end;

procedure TLemmingGame.CheckReleaseLemming;
var
  NewLemming: TLemming;
  ix: Integer;
begin
                                            
  if not HatchesOpened then
    Exit;
  if NukeIsActive then
    Exit;

  // NextLemmingCountdown is initialized to 20 before start of a level
  if NextLemmingCountdown > 0 then Dec(NextLemmingCountdown);

  if NextLemmingCountdown = 0 then
  begin
    NextLemmingCountdown := CalculateNextLemmingCountdown;
    if (LemmingsToRelease > 0) then
    begin
      ix := Level.Info.SpawnOrder[Level.Info.LemmingsCount - Level.PreplacedLemmings.Count - LemmingsToRelease];
      if ix >= 0 then
      begin
        NewLemming := TLemming.Create;
        with NewLemming do
        begin
          LemIndex := LemmingList.Add(NewLemming);
          LemIdentifier := 'N' + IntToStr(Level.Info.LemmingsCount - Level.PreplacedLemmings.Count - LemmingsToRelease);
          Transition(NewLemming, baFalling);

          if LemAction = baFalling then // Could be a walker if eg. spawned inside terrain
            LemInitialFall := true;

          LemX := Gadgets[ix].TriggerRect.Left;
          LemY := Gadgets[ix].TriggerRect.Top;
          LemDX := 1;
          if Gadgets[ix].IsFlipPhysics then TurnAround(NewLemming);

          LemIsSlider := Gadgets[ix].IsPreassignedSlider;
          LemIsClimber := Gadgets[ix].IsPreassignedClimber;
          LemIsSwimmer := Gadgets[ix].IsPreassignedSwimmer;
          LemIsDisarmer := Gadgets[ix].IsPreassignedDisarmer;
          LemIsFloater := Gadgets[ix].IsPreassignedFloater;
          if not LemIsFloater then
            LemIsGlider := Gadgets[ix].IsPreassignedGlider;

          if Gadgets[ix].IsPreassignedZombie then
          begin
            Dec(fSpawnedDead);
            RemoveLemming(NewLemming, RM_ZOMBIE, true);
          end;

          LemIsNeutral := Gadgets[ix].IsPreassignedNeutral
                  and not Gadgets[ix].IsPreassignedRival;

          LemIsRival := Gadgets[ix].IsPreassignedRival
                  and not Gadgets[ix].IsPreassignedZombie;

          if Gadgets[ix].RemainingLemmingsCount > 0 then
          begin
            Gadgets[ix].RemainingLemmingsCount := Gadgets[ix].RemainingLemmingsCount - 1;
            if Gadgets[ix].RemainingLemmingsCount = 0 then
              CueSoundEffect(Gadgets[ix].SoundEffectExhaust, Gadgets[ix].Center);
            // TLevel.PrepareForUse handles enforcing the limits. This only needs to be updated for display purposes.
          end;
        end;
        Dec(LemmingsToRelease);
        Inc(LemmingsOut);

        // Automatically save lemmings that spawn outside of the level area
        if (NewLemming.LemX <= 0) or (NewLemming.LemX >= PhysicsMap.Width)
        or (NewLemming.LemY <= 0) or (NewLemming.LemY >= PhysicsMap.Height) then
        begin
          RemoveLemming(NewLemming, RM_SAVE);
          CueExitSound(NewLemming);
        end;
      end;
    end;
  end;
end;

procedure TLemmingGame.CheckUpdateNuking;
var
  CurrentLemming: TLemming;
begin

  if NukeIsActive and ExploderAssignInProgress then
  begin

    // Find first following non removed lemming
    while     (Index_LemmingToBeNuked < LemmingList.Count-1)
          and (LemmingList[Index_LemmingToBeNuked].LemRemoved) do
      Inc(Index_LemmingToBeNuked);

    if (Index_LemmingToBeNuked > LemmingList.Count-1) then
      ExploderAssignInProgress := FALSE
    else
    begin
      CurrentLemming := LemmingList[Index_LemmingToBeNuked];
      with CurrentLemming do
      begin
        if         (LemExplosionTimer = 0)
           and not (LemAction in [baSplatting, baExploding]) then
          LemExplosionTimer := 84;
      end;
      Inc(Index_LemmingToBeNuked);

    end;
  end;
end;


function TLemmingGame.CalculateNextLemmingCountdown: Integer;
(* ccexplore:
  All I know is that in the DOS version, the formula is that for a given RR,
  the number of frames from one release to the next is:
  (99 - RR) / 2 + 4
  Where the division is the standard truncating integer division
  (so for example RR 99 and RR 98 acts identically).

  This means for example, at RR 99,
  it'd be release, wait, wait, wait, release, wait, wait, wait, release,

  I don't know what the frame rate is though on the DOS version,
  although to a large extent this mostly does not matter, since most aspects
  of the game mechanics is based off of number of frames rather than absolute time.
*)
begin
  Result := CurrSpawnInterval;
end;

procedure TLemmingGame.CueSoundEffect(aSound: String);
begin
  if IsSimulating then Exit; // Not play sound in simulation mode

  // Check that the sound was not yet played on this frame
  if fSoundList.Contains(aSound) then Exit;

  fSoundList.Add(aSound);
  MessageQueue.Add(GAMEMSG_SOUND, aSound);
end;

procedure TLemmingGame.CueExitSound(L: TLemming);
begin
  if L.LemIsZombie then
    CueSoundEffect(SFX_ZombieExit, L.Position)
  else if GameParams.PreferYippee then
    CueSoundEffect(SFX_Yippee, L.Position)
  else
    CueSoundEffect(SFX_Boing, L.Position);
end;

procedure TLemmingGame.CueSoundEffect(aSound: String; aOrigin: TPoint);
begin
  if IsSimulating then Exit; // Not play sound in simulation mode

  // Check that the sound was not yet played on this frame
  if fSoundList.Contains(aSound) then Exit;

  fSoundList.Add(aSound);
  MessageQueue.Add(GAMEMSG_SOUND_BAL, aSound, aOrigin.X);
end;

function TLemmingGame.GetHighlitLemming: TLemming;
begin
  Result := nil;
  if fHighlightLemmingID < 0 then Exit;
  if fHighlightLemmingID >= LemmingList.Count then Exit;
  if LemmingList[fHighlightLemmingID].LemRemoved then Exit;
  if LemmingList[fHighlightLemmingID].LemTeleporting then Exit;
  Result := LemmingList[fHighlightLemmingID];
end;

function TLemmingGame.GetTargetLemming: TLemming;
begin
  Result := nil;
  if fTargetLemmingID < 0 then Exit;
  if fTargetLemmingID >= LemmingList.Count then Exit;
  if LemmingList[fTargetLemmingID].LemRemoved then Exit;
  if LemmingList[fTargetLemmingID].LemTeleporting then Exit;
  Result := LemmingList[fTargetLemmingID];
end;


function TLemmingGame.CheckIfLegalSI(aSI: Integer): Boolean;
begin
  if Level.Info.SpawnIntervalLocked
  or (aSI < MINIMUM_SI)
  or (aSI > Level.Info.SpawnInterval) then
    Result := false
  else
    Result := true;
end;

// Called in GameBaseSkillPanel to cue the sound when the SI is changed
function TLemmingGame.SpawnIntervalChanged: Boolean;
begin
  Result := fSpawnIntervalChanged;
  fSpawnIntervalChanged := False;
end;

procedure TLemmingGame.AdjustSpawnInterval(aSI: Integer);
begin
  if (aSI <> CurrSpawnInterval) and CheckIfLegalSI(aSI) then
  begin
    CurrSpawnInterval := aSI;
    fSpawnIntervalChanged := True;
  end;
end;

procedure TLemmingGame.RecordInfiniteSkills;
var
  E: TReplayInfiniteSkills;
begin
  if not fPlaying then Exit;

  E := TReplayInfiniteSkills.Create;
  E.Frame := fCurrentIteration;

  E.AddedByInsert := ReplayInsert;

  fReplayManager.Add(E);
end;

procedure TLemmingGame.RecordInfiniteTime;
var
  E: TReplayInfiniteTime;
begin
  if not fPlaying then Exit;

  E := TReplayInfiniteTime.Create;
  E.Frame := fCurrentIteration;

  E.AddedByInsert := ReplayInsert;

  fReplayManager.Add(E);
end;

procedure TLemmingGame.RecordNuke(aInsert: Boolean);
var
  E: TReplayNuke;
begin
  if (aInsert and (fCurrentIteration < 84)) or (not fPlaying) then
    Exit;
  E := TReplayNuke.Create;
  if aInsert then
    E.Frame := fCurrentIteration - 84
  else
    E.Frame := fCurrentIteration;

  E.AddedByInsert := ReplayInsert;

  fReplayManager.Add(E);
end;

procedure TLemmingGame.RecordSpawnInterval(aSI: Integer);
var
  E: TReplayChangeSpawnInterval;
begin
  if not fPlaying then Exit;

  E := TReplayChangeSpawnInterval.Create;
  E.Frame := fCurrentIteration;
  E.NewSpawnInterval := aSI;
  E.SpawnedLemmingCount := LemmingList.Count;

  E.AddedByInsert := ReplayInsert;

  fReplayManager.Add(E);
  CheckForReplayAction(true);
end;

procedure TLemmingGame.RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
var
  E: TReplaySkillAssignment;
begin
  if not fPlaying then Exit;

  E := TReplaySkillAssignment.Create;
  E.Skill := aSkill;
  E.SetInfoFromLemming(L, (L.LemIndex = fHighlightLemmingID));
  E.Frame := fCurrentIteration;

  E.AddedByInsert := ReplayInsert;

  fReplayManager.Add(E);
end;

procedure TLemmingGame.CheckForReplayAction(PausedRRCheck: Boolean = false);
var
  R: TBaseReplayItem;
  i: Integer;

  procedure ApplySkillAssign;
  var
    E: TReplaySkillAssignment absolute R;
  begin
    ReplaySkillAssignment(E);
  end;

  procedure ApplySpawnInterval;
  var
    E: TReplayChangeSpawnInterval absolute R;
  begin
    AdjustSpawnInterval(E.NewSpawnInterval);
  end;

  procedure ApplyNuke;
  var
    E: TReplayNuke absolute R;
  begin
    NukeIsActive := True;
    ExploderAssignInProgress := True;
  end;

  procedure ApplyInfiniteSkills;
  var
    E: TReplayInfiniteSkills absolute R;
  begin
    SetSkillsToInfinite;
  end;

  procedure ApplyInfiniteTime;
  var
    E: TReplayInfiniteTime absolute R;
  begin
    IsInfiniteTimeMode := True;
  end;

  function Handle: Boolean;
  begin
    Result := false;
    if R = nil then Exit;

    Result := true;

    if R is TReplaySkillAssignment then
      ApplySkillAssign;

    if R is TReplayChangeSpawnInterval then
      ApplySpawnInterval;

    if R is TReplayNuke then
      ApplyNuke;

    if R is TReplayInfiniteSkills then
      ApplyInfiniteSkills;

    if R is TReplayInfiniteTime then
      ApplyInfiniteTime;
  end;
begin
  try
    // Note - the fReplayManager getters can return nil, and often will!
    // The "Handle" procedure ensures this does not lead to errors.
    i := 0;
    repeat
      R := fReplayManager.SpawnIntervalChange[fCurrentIteration, i];
      Inc(i);
    until not Handle;

    if PausedRRCheck then Exit; // Bookmark - maybe we can get rid of paused RR code?

    i := 0;
    repeat
      R := fReplayManager.Assignment[fCurrentIteration, i];
      Inc(i);
    until not Handle;

    i := 0;
    repeat
      R := fReplayManager.SkillCountChange[fCurrentIteration, i];
      Inc(i);
    until not Handle;

    i := 0;
    repeat
      R := fReplayManager.TimeChange[fCurrentIteration, i];
      Inc(i);
    until not Handle;

  finally
    // Do nothing
  end;
end;

procedure TLemmingGame.CheckForQueuedAction;
var
  i: Integer;
  L: TLemming;
  NewSkill: TBasicLemmingAction;
begin
  // First check whether there was already a skill assignment this frame
  if Assigned(fReplayManager.Assignment[fCurrentIteration, 0]) then Exit;

  for i := 0 to LemmingList.Count - 1 do
  begin
    L := LemmingList.List[i];

    if L.LemQueueAction = baNone then Continue;

    if L.LemRemoved or L.CannotReceiveSkills or L.LemTeleporting then // CannotReceiveSkills covers neutral and zombie
    begin
      // Delete queued action first
      L.LemQueueAction := baNone;
      L.LemQueueFrame := 0;
      Continue;
    end;

    NewSkill := L.LemQueueAction;

    // Try assigning the skill
    if NewSkillMethods[NewSkill](L) and CheckSkillAvailable(NewSkill, L) then
      // Record skill assignment, so that we apply it in CheckForReplayAction
      RecordSkillAssignment(L, NewSkill)
    else
    begin;
      Inc(L.LemQueueFrame);
      // Delete queued action after 16 frames
      if L.LemQueueFrame > 15 then
      begin
        L.LemQueueAction := baNone;
        L.LemQueueFrame := 0;
      end;
    end;
  end;

end;


procedure TLemmingGame.CheckLemmings;
var
  i: Integer;
  CurrentLemming: TLemming;
  ContinueWithLem: Boolean;
begin

  ZombieMap.Clear(0);

  for i := 0 to LemmingList.Count - 1 do
  begin
    CurrentLemming := LemmingList.List[i];

    with CurrentLemming do
    begin
      ContinueWithLem := True;

      if fGameCheated then Transition(CurrentLemming, baShrugging);

      if LemParticleTimer >= 0 then
        Dec(LemParticleTimer);

      if LemRemoved then
        Continue;

      // Put lemming out of receiver if teleporting is finished.
      if LemTeleporting then
        ContinueWithLem := CheckLemTeleporting(CurrentLemming);

      // Explosion-Countdown
      if ContinueWithLem and (LemExplosionTimer <> 0) then
        ContinueWithLem := not UpdateExplosionTimer(CurrentLemming);

      // FreezerExplosion-Countdown
      if ContinueWithLem and (LemFreezerExplosionTimer <> 0) then
        ContinueWithLem := not UpdateFreezerExplosionTimer(CurrentLemming);

      // Freezing
      if ContinueWithLem and (LemFreezingTimer <> 0) then
        UpdateFreezingTimer(CurrentLemming);

      // Unfreezing
      if ContinueWithLem and (LemUnfreezingTimer <> 0) then
        UpdateUnfreezingTimer(CurrentLemming);

      // Balloon Pop
      if ContinueWithLem and (LemBalloonPopTimer <> 0) then
        UpdateBalloonPopTimer(CurrentLemming);

      // Let lemmings move
      if ContinueWithLem then
        ContinueWithLem := HandleLemming(CurrentLemming);

      // Check whether the lem is still on screen
      if ContinueWithLem then
        ContinueWithLem := CheckLevelBoundaries(CurrentLemming);

      // Check whether the lem has moved over trigger areas
      if ContinueWithLem then
        CheckTriggerArea(CurrentLemming);

      // Check to see whether a laser or projectile has hit the lemming {applies to Zombies only}
      if ContinueWithLem and CurrentLemming.LemIsZombie then
      begin
        ZombieCheckForLaser(CurrentLemming);
        ZombieCheckForProjectiles(CurrentLemming);
      end;
    end;
  end;

  // Check for lemmings meeting zombies
  // Need to do this in separate loop, because the ZombieMap gets only set during HandleLemming!
  for i := 0 to LemmingList.Count - 1 do
  begin
    CurrentLemming := LemmingList.List[i];
    with CurrentLemming do
    begin
      // Zombies
      if     (ReadZombieMap(LemX, LemY) and 1 <> 0)
         and (LemAction <> baExiting)
         and not (CurrentLemming.LemIsZombie or CurrentLemming.LemIsInvincible)
         // Freezers are protected from zombies
         and not (LemAction in [baFreezing, baFreezerExplosion, baFrozen])
         and not CurrentLemming.LemTeleporting then
           RemoveLemming(CurrentLemming, RM_ZOMBIE);
    end;
  end;
end;

procedure TLemmingGame.SimulateTransition(L: TLemming; NewAction: TBasicLemmingAction);
begin
  Inc(fSimulationDepth);

  if (NewAction = baStacking) then L.LemStackLow := not HasPixelAt(L.LemX + L.LemDx, L.LemY);
  Transition(L, NewAction);

  Dec(fSimulationDepth);
end;

function TLemmingGame.SimulateLem(L: TLemming; DoCheckObjects: Boolean = True): TArrayArrayInt; // Simulates advancing one frame for the lemming L
var
  HandleGadgets: Boolean;
  LemPosArray: TArrayArrayInt;
  i: Integer;
begin
  // Start Simulation Mode
  Inc(fSimulationDepth);

  // Advance lemming one frame
  HandleGadgets := HandleLemming(L);
  // Check whether the lem is still on screen
  if HandleGadgets then
    HandleGadgets := CheckLevelBoundaries(L);
  // Check whether the lem has moved over trigger areas
  if HandleGadgets and DoCheckObjects then
  begin
    // Get positions to check
    LemPosArray := GetGadgetCheckPositions(L);

    // Check for exit, traps and teleporters (but stop at teleporters!)
    for i := 0 to Length(LemPosArray[0]) do
    begin
      // Transition if we are at the end position and need to do one
      if (fLemNextAction <> baNone) and ([LemPosArray[0, i], LemPosArray[1, i]] = [L.LemX, L.LemY]) then
      begin
        Transition(L, fLemNextAction);
        if fLemJumpToHoistAdvance then
        begin
          Inc(L.LemFrame, 2);
          Inc(L.LemPhysicsFrame, 2);
        end;

        fLemNextAction := baNone;
        fLemJumpToHoistAdvance := false;
      end;

      if    (    HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trTrap)
             and (FindGadgetID(LemPosArray[0, i], LemPosArray[1, i], trTrap) <> 65535)
             and not (L.LemIsDisarmer or L.LemIsInvincible))
         or ((L.LemAction = baBallooning) and (L.LemY <= 30))
         or (HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trExit))
         or (HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trWater) and not L.LemIsSwimmer)
         or (HasWaterObjectAt(LemPosArray[0, i], LemPosArray[1, i]) and not L.LemIsInvincible)
         or HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trFire)
         or (    HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trTeleport)
             and (FindGadgetID(LemPosArray[0, i], LemPosArray[1, i], trTeleport) <> 65535))
         then
      begin
        L.LemAction := baExploding; // This always stops the simulation!
        L := nil;
        Break;
      end;

      if HasWaterObjectAt(LemPosArray[0, i], LemPosArray[1, i])
        and (L.LemIsSwimmer or L.LemIsInvincible) then
          fLemNextAction := baSwimming;

      if (HasTriggerAt(LemPosArray[0, i], LemPosArray[1, i], trTrap)
            and (FindGadgetID(LemPosArray[0, i], LemPosArray[1, i], trTrap) <> 65535))
          and HasPixelAt(LemPosArray[0, i], LemPosArray[1, i]) then
          begin
           if L.LemIsDisarmer then
             fLemNextAction := baFixing
           else if L.LemIsInvincible then
             fLemNextAction := baWalking;
          end;

      // End this loop when we have reached the lemming position
      if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
    end;

    // Check for blocker fields and force-fields at the end of movement
    if Assigned(L) then
    begin
      if HasTriggerAt(L.LemX, L.LemY, trForceLeft, L) then
        HandleForceField(L, -1)
      else if HasTriggerAt(L.LemX, L.LemY, trForceRight, L) then
        HandleForceField(L, 1);
    end;
  end else
    SetLength(LemPosArray, 0);

  // End Simulation Mode
  Dec(fSimulationDepth);

  Result := LemPosArray;
end;



function TLemmingGame.CheckLemTeleporting(L: TLemming): Boolean;
// This function checks, whether a lemming appears out of a receiver
var
  Gadget: TGadget;
  GadgetID: Integer;
begin
  Result := False;

  CustomAssert(L.LemTeleporting = True, 'CheckLemTeleporting called for non-teleporting lemming');

  // Search for Teleporter, the lemming is in
  GadgetID := -1;
  repeat
    Inc(GadgetID);
  until (GadgetID > Gadgets.Count - 1) or (L.LemIndex = Gadgets[GadgetID].TeleLem);

  CustomAssert(GadgetID < Gadgets.Count, 'Teleporter associated to teleporting lemming not found');

  Gadget := Gadgets[GadgetID];
  if Gadget.TriggerEffect <> DOM_RECEIVER then Exit;
  if (Gadget.KeyFrame = 0) and (Gadget.CurrentFrame < Gadget.AnimationFrameCount - 1) then Exit;
  if (Gadget.KeyFrame > 0) and (Gadget.CurrentFrame < Gadget.KeyFrame - 1) then Exit;

  L.LemTeleporting := False; // Let lemming reappear
  Gadget.TeleLem := -1;
  Result := True;

  HandlePostTeleport(L);
end;

procedure TLemmingGame.HandlePostTeleport(L: TLemming);
var
  i: Integer;
  BrickColor: TColor32;
begin
  // Check for trigger areas.
  CheckTriggerArea(L, true);
  BrickColor := Renderer.BrickPixelColors[12 - L.LemNumberOfBricksLeft];

  // Reset blocker map, if lemming is a blocker and the target position is free
  if L.LemAction = baBlocking then
  begin
    if CheckForOverlappingField(L) then
      Transition(L, baWalking)
    else
    begin
      L.LemHasBlockerField := True;
      SetBlockerMap;
    end;
  end;

  if (L.LemAction in [baBuilding, baPlatforming]) and (L.LemPhysicsFrame >= 9) then
    L.LemConstructivePositionFreeze := true;

  if (L.LemAction = baBuilding) and ((L.LemNumberOfBricksLeft < 12) or (L.LemPhysicsFrame >= 9)) then
  begin
    if L.LemPhysicsFrame < 9 then
      Inc(L.LemNumberOfBricksLeft);
    for i := 0 to 3 do
      AddConstructivePixel(L.LemX + (i * L.LemDX), L.LemY, BrickColor);
    if L.LemPhysicsFrame < 9 then
      Dec(L.LemNumberOfBricksLeft);
  end else if (L.LemAction = baPlatforming) and ((L.LemNumberOfBricksLeft < 12) or (L.LemPhysicsFrame >= 9)) then
  begin
    if L.LemPhysicsFrame < 9 then
      Inc(L.LemNumberOfBricksLeft);
    AddConstructivePixel(L.LemX, L.LemY, BrickColor);
    if L.LemPhysicsFrame < 9 then
      Dec(L.LemNumberOfBricksLeft);
  end;
end;


procedure TLemmingGame.SetGameResult;
begin
  with GameResultRec do
  begin
    gCount              := Level.Info.LemmingsCount;
    gToRescue           := Level.Info.RescueCount;
    gRescued            := LemmingsIn;
    gGotTalisman        := fTalismanReceived;
    gGotNewTalisman     := fNewTalismanReceived;
    gCheated            := fGameCheated;
    gSuccess            := (gRescued >= gToRescue) or gCheated;
    gTimeIsUp           := IsOutOfTime;
    gLastIteration      := fCurrentIteration;

    if fGameCheated then
    begin
      gRescued := gCount;
      if spbCloner in Level.Info.Skillset then
        Inc(gRescued, Level.Info.SkillCount[spbCloner]);
    end;
  end;
end;

procedure TLemmingGame.RegainControl(Force: Boolean = false);
begin
  if ReplayInsert and not Force then Exit;

  if CurrentIteration > fReplayManager.LastActionFrame then Exit;

  fReplayManager.Cut(fCurrentIteration, CurrSpawnInterval);
end;


procedure TLemmingGame.UpdateGadgets;
{-------------------------------------------------------------------------------
  This method handles the updating of the moving interactive objects:
  o Entrances moving
  o Continuously moving objects like water
  o Triggered objects (traps)
  NB: It does not handle the drawing
-------------------------------------------------------------------------------}
var
  Gadget, Gadget2: TGadget;
  i, i2: Integer;
begin
  for i := Gadgets.Count - 1 downto 0 do
  begin
    Gadget := Gadgets[i];

    if (Gadget.Triggered or (Gadget.TriggerEffectBase in AlwaysAnimateObjects))
       and (Gadget.TriggerEffect <> DOM_PICKUP) then
      Gadget.CurrentFrame := Gadget.CurrentFrame + 1;

    if (Gadget.TriggerEffect = DOM_TELEPORT) then
    begin
      Gadget2 := Gadgets[Gadget.ReceiverId];

      if (((Gadget.CurrentFrame >= Gadget.AnimationFrameCount) and (Gadget.KeyFrame = 0))
         or ((Gadget.CurrentFrame = Gadget.KeyFrame) and (Gadget.KeyFrame <> 0))   ) then
      begin
        MoveLemToReceivePoint(LemmingList.List[Gadget.TeleLem], i);

        CustomAssert(Gadget2.TriggerEffect = DOM_RECEIVER, 'Lemming teleported to non-receiver object.');

        Gadget2.TeleLem := Gadget.TeleLem;
        Gadget2.Triggered := True;
        Gadget2.ZombieMode := Gadget.ZombieMode;
        Gadget2.NeutralMode := Gadget.NeutralMode;
        // Reset TeleLem for Teleporter
        Gadget.TeleLem := -1;
      end;

      Gadget.SecondariesTreatAsBusy := Gadget2.Triggered;
    end;

    if Gadget.CurrentFrame >= Gadget.AnimationFrameCount then
    begin
      Gadget.CurrentFrame := 0;
      Gadget.Triggered := False;
      Gadget.HoldActive := False;
      Gadget.ZombieMode := False;
      Gadget.NeutralMode := False;
    end;

    for i2 := Gadget.Animations.Count-1 downto 0 do
    begin
      if Gadget.Animations[i2].Primary then
        Continue
      else if not Gadget.Animations[i2].UpdateOneFrame then
        Gadget.Animations.Delete(i2);
    end;
  end;
end;

procedure TLemmingGame.CheckAdjustSpawnInterval;
var
  NewSI: Integer;
begin
  if SpawnIntervalModifier = 0 then Exit;

  NewSI := CurrSpawnInterval + SpawnIntervalModifier;
  if CheckIfLegalSI(NewSI) then RecordSpawnInterval(NewSI);
end;

procedure TLemmingGame.CheckReplayLoaded;
var
  i: Integer;
begin
  // Only proceed with check if the level has Classic Mode or No Pause talisman
  for i := 0 to Level.Talismans.Count-1 do
    if not (Level.Talismans[i].RequireClassicMode) or (Level.Talismans[i].RequireNoPause) then
      Exit;

  // Check for action on any future frame - 55 frames' grace at the start of the level (before music starts)
  if (CurrentIteration > 55) and (CurrentIteration < fReplayManager.LastActionFrame) then
    ReplayLoaded := True;
end;

procedure TLemmingGame.Finish(aReason: Integer);
begin
  SetGameResult;
  fGameFinished := True;
  MessageQueue.Add(GAMEMSG_FINISH, aReason);
end;

procedure TLemmingGame.Cheat;
begin
  fGameCheated := True;
  CueSoundEffect(SFX_OK);

  // Finish immediately if there are no active lemmings (see HandleShrugging)
  if (LemmingsOut <= 0) then
    Finish(GM_FIN_TERMINATE);
end;

procedure TLemmingGame.EnsureCorrectReplayDetails;
begin
  with fReplayManager do
  begin
    LevelName := Trim(fLevel.Info.Title);
    LevelAuthor := Trim(fLevel.Info.Author);
    LevelGame := GameParams.CurrentLevel.Group.ParentBasePack.Name;
    LevelRank := GameParams.CurrentGroupName;
    LevelPosition := GameParams.CurrentLevel.GroupIndex + 1;
    LevelID := fLevel.Info.LevelID;
  end;
end;

function TLemmingGame.CheckSkillAvailable(aAction: TBasicLemmingAction; L: TLemming): Boolean;
var
  HasSkillButton: Boolean;
  i: Integer;
begin
  CustomAssert(aAction in AssignableSkills, 'CheckSkillAvailable for not assignable skill');

  HasSkillButton := false;
  for i := 0 to MAX_SKILL_TYPES_PER_LEVEL - 1 do
    HasSkillButton := HasSkillButton or (fActiveSkills[i] = ActionToSkillPanelButton[aAction]);

  // Invincible lems get free skills, even when they have run out
  if L.LemIsInvincible then
  begin
    Result := HasSkillButton;
  end else
    Result := HasSkillButton and (CurrSkillCount[aAction] > 0);
end;


procedure TLemmingGame.UpdateSkillCount(aAction: TBasicLemmingAction; Amount: Integer = -1);
begin
  if CurrSkillCount[aAction] < 100 then // So, not infinite skills
    CurrSkillCount[aAction] := Max(Min(CurrSkillCount[aAction] + Amount, 99), 0);

  if Amount < 0 then Inc(UsedSkillCount[aAction], -Amount);
end;

procedure TLemmingGame.SaveGameplayImage(Filename: String);
var
  BMP: TBitmap32;
begin
  BMP := TBitmap32.Create;
  try
    fRenderer.DrawLevel(BMP);
    TPngInterface.SavePngFile(Filename, BMP, true);
  finally
    BMP.Free;
  end;
end;

function TLemmingGame.GetIsReplaying: Boolean;
begin
  Result := fCurrentIteration <= fReplayManager.LastActionFrame;
end;

function TLemmingGame.GetIsReplayingNoRR(isPaused: Boolean): Boolean;
var
  RRItem: TReplayChangeSpawnInterval;
begin
  // Ignore RR changes at the current frame when paused
  // Moreover ignore changes at the current frame, when not paused

  // If there's action on any future frame
  Result := fCurrentIteration < fReplayManager.LastActionFrame;

  { If paused, and there's a non-RR action on the current frame or an RR action that
    doesn't agree with the current RR }
  if (not Result) and isPaused then
  begin
    Result := (fReplayManager.Assignment[fCurrentIteration, 0] <> nil) and
              not (fReplayManager.Assignment[fCurrentIteration, 0] is TReplayNuke);

    RRItem := TReplayChangeSpawnInterval(fReplayManager.SpawnIntervalChange[fCurrentIteration, 0]);
    if RRItem <> nil then
      Result := Result or (RRItem.NewSpawnInterval <> CurrSpawnInterval);
  end;

  //
  if (not Result) and (not isPaused) then
    Result := (fReplayManager.SpawnIntervalChange[fCurrentIteration, 0] <> nil);
end;


function TLemmingGame.GetIsSimulating: Boolean;
begin
  Result := fSimulationDepth > 0;
end;

function TLemmingGame.GetSkillCount(aSkill: TSkillPanelButton): Integer;
begin
  if (aSkill < Low(TSkillPanelButton)) or (aSkill > LAST_SKILL_BUTTON) then
    Result := 0
  else
    Result := CurrSkillCount[SkillPanelButtonToAction[aSkill]];
end;

function TLemmingGame.GetUsedSkillCount(aSkill: TSkillPanelButton): Integer;
begin
  if (aSkill < Low(TSkillPanelButton)) or (aSkill > LAST_SKILL_BUTTON) then
    Result := 0
  else
    Result := UsedSkillCount[SkillPanelButtonToAction[aSkill]];
end;

function TLemmingGame.IsStartingSeconds: Boolean;
begin
  Result := (fCurrentIteration < 35) and not fGameFinished;
end;

end.
