{$include lem_directives.inc}

{-------------------------------------------------------------------------------
  Some source code notes:

  � Places with optional mechanics are marked with a comment
  :
    "// @Optional Game Mechanic"

  � Note that a lot of routines start with "Result := False". I removed
    redundant code, so if you see just an "Exit" call then it is always
    to be interpreted as "Return False".
    Nepster: This is no longer true in rewritten code. Here the default is
    to return True.

  � Transition() method: It has a default parameter. So if you see a
    call to Transition() with three parameters and the last one is TRUE, it means
    that the lemming has to turn around as well. I commented this too at all
    places where this happens.
-------------------------------------------------------------------------------}

unit LemGame;

interface

uses
  SharedGlobals, PngInterface,
  Windows, Classes, Contnrs, SysUtils, Math, Forms, Dialogs,
  TalisData,
  PngImage,
  Controls, StrUtils,
  UMisc, TypInfo,
  GR32, GR32_OrdinalMaps, GR32_Layers,
  LemNeoPieceManager, // makes use of the records containing images + metainfo
  LemCore, LemTypes, LemDosBmp, LemDosStructures, LemStrings, LemMetaAnimation,
  LemMetaObject, LemInteractiveObject, LemSteel, LemLevel, LemStyle,
  LemRenderHelpers, LemRendering, LemDosAnimationSet,
  LemMusicSystem, LemDosMainDat, LemNeoTheme,
  LemObjects, LemLemming, LemRecolorSprites,
  LemReplay,
  GameInterfaces, GameControl, GameSound;

type
  TParticleRec = packed record
    DX, DY: ShortInt
  end;
  TParticleArray = packed array[0..79] of TParticleRec;
  TParticleTable = packed array[0..50] of TParticleArray;

const
  ParticleColorIndices: array[0..15] of Byte =
    (4, 15, 14, 13, 12, 11, 10, 9, 8, 11, 10, 9, 8, 7, 6, 2);

  AlwaysAnimateObjects = [0, 1, 2, 3, 5, 6, 7, 8, 18, 19, 20, 22, 25, 26, 27, 30];

type
  tFloatParameterRec = record
    Dy: Integer;
    AnimationFrameIndex: Integer;
  end;

type
  // never change this anymore. it's stored in replayfile
  TDosGameOption = (
    dgoDisableObjectsAfter15,    // objects with index higher than 15 will not work
    dgoMinerOneWayRightBug,      // the miner bug check
    dgoObsolete,                 // deleted skillbutton option. never replace.
    dgoSplattingExitsBug,
    dgoOldEntranceABBAOrder,
    dgoEntranceX25,
    dgoFallerStartsWith3,
    dgoMax4EnabledEntrances,
    dgoAssignClimberShruggerActionBug
  );
  TDosGameOptions = set of TDosGameOption;

const      // todo: remove this and all references to it; it's irrelevant in NeoLemmix
  DOSORIG_GAMEOPTIONS = [
    dgoDisableObjectsAfter15,
    dgoMinerOneWayRightBug,
    dgoObsolete,
    dgoSplattingExitsBug,
    dgoFallerStartsWith3,
    dgoEntranceX25,
    dgoMax4EnabledEntrances
  ];

  DOSOHNO_GAMEOPTIONS = [
    dgoDisableObjectsAfter15,
    dgoMinerOneWayRightBug,
    dgoObsolete,
    dgoSplattingExitsBug,
    dgoFallerStartsWith3,
    dgoEntranceX25,
    dgoMax4EnabledEntrances
  ];

  CUSTLEMM_GAMEOPTIONS = [
    dgoDisableObjectsAfter15,
    dgoMinerOneWayRightBug,
    dgoObsolete,
    dgoSplattingExitsBug,
    dgoFallerStartsWith3,
    dgoEntranceX25,
    dgoMax4EnabledEntrances
  ];

{-------------------------------------------------------------------------------
  Replay things
-------------------------------------------------------------------------------}
type

  TReplayOption = (
    rpoLevelComplete,
    rpoNoModes,
    rpoB2,
    rpoB3,
    rpoB4,
    rpoB5,
    rpoB6,
    rpoB7);
  TReplayOptions = set of TReplayOption;

  TReplayFileHeaderRec = packed record
    Signature         : array[0..2] of Char;     //  3 bytes -  3
    Version           : Byte;                    //  1 byte  -  4
    FileSize          : Integer;                 //  4 bytes -  8
    HeaderSize        : Word;                    //  2 bytes - 10
    Mechanics         : TDosGameOptions;         //  2 bytes - 12
    FirstRecordPos    : Integer;                 //  4 bytes - 16
    ReplayRecordSize  : Word;                    //  2 bytes - 18
    ReplayRecordCount : Word;                    //  2 bytes - 20

    ReplayGame        : Byte;
    ReplaySec         : Byte;
    ReplayLev         : Byte;
    ReplayOpt         : TReplayOptions;

    ReplayTime        : LongWord;
    ReplaySaved       : Word;

    ReplayLevelID    : LongWord;

    {
    Reserved1         : Integer;                 //  4 bytes - 24
    Reserved2         : Integer;                 //  4 bytes - 28
    Reserved3         : Integer;                 //  4 bytes - 32
    }

    Reserved        : array[0..29] of Char;    // 32 bytes - 64
  end;

const
  // never change, do NOT trust the bits are the same as the enumerated type.

  //Recorded Game Flags
  rgf_DisableObjectsAfter15          = Bit0;
	rgf_MinerOneWayRightBug            = Bit1;
	rgf_DisableButtonClicksWhenPaused  = Bit2;
	rgf_SplattingExitsBug              = Bit3;
	rgf_OldEntranceABBAOrder           = Bit4;
	rgf_EntranceX25                    = Bit5;
	rgf_FallerStartsWith3              = Bit6;
  rgf_Max4EnabledEntrances           = Bit7;
	rgf_AssignClimberShruggerActionBug = Bit8;

  //Recorded Action Flags
	//raf_StartPause        = Bit0;
	//raf_EndPause          = Bit1;
	//raf_Pausing           = Bit2;
	raf_StartIncreaseRR   = Bit3;  // only allowed when not pausing
	raf_StartDecreaseRR   = Bit4;  // only allowed when not pausing
	raf_StopChangingRR    = Bit5;  // only allowed when not pausing
	raf_SkillSelection    = Bit6;
	raf_SkillAssignment   = Bit7;
	raf_Nuke              = Bit8;  // only allowed when not pausing, as in the game
  raf_NewNPLemming      = Bit9;  // related to emulation of right-click bug
  //raf_RR99              = Bit10;
  //raf_RRmin             = Bit11;

  //Recorded Lemming Action
  rla_None       = 0;
  rla_Walking    = 1;  // not allowed
  rla_Jumping    = 2;  // not allowed
  rla_Digging    = 3;
  rla_Climbing   = 4;
  rla_Drowning   = 5;  // not allowed
  rla_Hoisting   = 6;  // not allowed
  rla_Building   = 7;
  rla_Bashing    = 8;
  rla_Mining     = 9;
  rla_Falling    = 10; // not allowed
  rla_Floating   = 11;
  rla_Splatting  = 12; // not allowed
  rla_Exiting    = 13; // not allowed
  rla_Vaporizing = 14; // not allowed
  rla_Blocking   = 15;
  rla_Shrugging  = 16; // not allowed
  rla_Ohnoing    = 17; // not allowed
  rla_Exploding  = 18;

  // Recorded Selected Button
  rsb_None       = 0;
  rsb_Slower     = 1;  // not allowed
  rsb_Faster     = 2;  // not allowed
  rsb_Climber    = 3;
  rsb_Umbrella   = 4;
  rsb_Explode    = 5;
  rsb_Stopper    = 6;
  rsb_Builder    = 7;
  rsb_Basher     = 8;
  rsb_Miner      = 9;
  rsb_Digger     = 10;
  rsb_Pause      = 11; // not allowed
  rsb_Nuke       = 12; // not allowed
  rsb_Walker     = 13;
  rsb_Swimmer    = 14;
  rsb_Glider     = 15;
  rsb_Mechanic   = 16;
  rsb_Stoner     = 17;
  rsb_Platformer = 18;
  rsb_Stacker    = 19;
  rsb_Cloner     = 20;

type
  TLemmingGame = class;

  TLemmingGameSavedState = class
    public
      LemmingList: TLemmingList;
      SelectedSkill: TSkillPanelButton;
      TargetBitmap: TBitmap32;
      World: TBitmap32;         // the visual terrain image
      PhysicsMap: TBitmap32;    // the actual physics
      //SteelWorld: TBitmap32;
      ObjectMap: TByteMap;
      BlockerMap: TByteMap;
      //SpecialMap: TByteMap;
      WaterMap: TByteMap;
      ZombieMap: TByteMap;
      CurrentIteration: Integer;
      ClockFrame: Integer;
      ButtonsRemain: Integer;
      LemmingsReleased: Integer;
      LemmingsCloned: Integer;
      LemmingsOut: Integer;
      SpawnedDead: Integer;
      LemmingsIn: Integer;
      LemmingsRemoved: Integer;
      NextLemmingCountdown: Integer;
      DelayEndFrames: Integer;
      TimePlay: Integer;
      EntriesOpened: Boolean;
      ObjectInfos: TInteractiveObjectInfoList;
      LowestReleaseRate: Integer;
      HighestReleaseRate: Integer;
      CurrReleaseRate: Integer;
      LastReleaseRate: Integer;

      CurrSkillCount: array[TBasicLemmingAction] of Integer;  // should only be called with arguments in AssignableSkills
      UsedSkillCount: array[TBasicLemmingAction] of Integer;  // should only be called with arguments in AssignableSkills

      UserSetNuking: Boolean;
      Index_LemmingToBeNuked: Integer;
      LastRecordedRR: Integer;
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
    fTalismans                 : TTalismans;
    fTalismanReceived          : Boolean;

    fLastReplayDir             : String;

    fTargetBitmap              : TBitmap32; // reference to the drawing bitmap on the gamewindow
    fSelectedSkill             : TSkillPanelButton; // TUserSelectedSkill; // currently selected skill restricted by F3-F9
    fOptions                   : TDosGameOptions; // mechanic options
    
    fParticleColors            : array[0..15] of TColor32;

  { internal objects }
    LemmingList                : TLemmingList; // the list of lemmings
    //World                      : TBitmap32; // actual bitmap that is changed by the lemmings
    //SteelWorld                 : TBitmap32; // backup bitmap for steel purposes
    PhysicsMap                 : TBitmap32; 
    ObjectMap                  : TByteMap;
    BlockerMap                 : TByteMap; // for blockers
    //SpecialMap                 : TByteMap; // for steel and oneway
    WaterMap                   : TByteMap; // for water, so that other objects can be on it for swimmers etc to use
    ZombieMap                  : TByteMap;
    fReplayManager             : TReplay;

  { reference objects, mostly for easy access in the mechanics-code }
    fGameParams                : TDosGameParams; // ref
    fRenderer                  : TRenderer; // ref to gameparams.renderer
    fInfoPainter               : IGameToolbar; // ref to interface to enable this component to draw to skillpanel
    fLevel                     : TLevel; // ref to gameparams.level
    Style                      : TBaseLemmingStyle; // ref to gameparams.style
    CntDownBmp                 : TBitmap32; // ref to style.animationset.countdowndigits
    HighlightBmp               : TBitmap32;
    ExplodeMaskBmp             : TBitmap32; // ref to style.animationset.explosionmask
    BashMasks                  : TBitmap32; // ref to style.animationset.bashmasks
    BashMasksRTL               : TBitmap32; // ref to style.animationset.bashmasksrtl
    MineMasks                  : TBitmap32; // ref to style.animationset.minemasks
    MineMasksRTL               : TBitmap32; // ref to style.animationset.minemasksrtl
    StoneLemBmp                : TBitmap32;

  { vars }
    fCurrentIteration          : Integer;
    fClockFrame                : Integer; // 17 frames is one game-second
    ButtonsRemain              : Byte;
    LemmingsReleased           : Integer; // number of lemmings that were created
    LemmingsCloned             : Integer;
    LemmingsOut                : Integer; // number of lemmings currently walking around
    SpawnedDead                : Integer;
    LemmingsIn                 : integer; // number of lemmings that made it to heaven
    LemmingsRemoved            : Integer; // number of lemmings removed
    DelayEndFrames             : Integer;
    fCursorPoint               : TPoint;
    fRightMouseButtonHeldDown  : Boolean;
    fShiftButtonHeldDown       : Boolean;
    fAltButtonHeldDown         : Boolean;
    fCtrlButtonHeldDown        : Boolean;
    TimePlay                   : Integer; // positive when time limit
                                          // negative when just counting time used
    fPlaying                   : Boolean; // game in active playing mode?
    EntriesOpened              : Boolean;
    LemmingMethods             : TLemmingMethodArray; // a method for each basic lemming state
    NewSkillMethods            : TNewSkillMethodArray; // The replacement of SkillMethods
    fCheckWhichLemmingOnly     : Boolean; // use during replays only, to signal the AssignSkill methods
                                          // to only indicate which Lemming gets the assignment, without
                                          // actually doing the assignment
    fFreezeSkillCount          : Boolean; // used when skill count should be frozen, for example when
                                          // calling assign routines that should assign the skill for free
                                          // note that this also overrides the test for if skills are available
    fFreezeRecording           : Boolean;
    WhichLemming               : TLemming; // see above
    LastNPLemming              : TLemming; // for emulation of right-click bug
    fLemSelected               : TLemming; // lem under cursor, who would receive the skill
    fLemWithShadow             : TLemming; // needed for CheckForNewShadow to erase previous shadow
    fLemWithShadowButton       : TSkillPanelButton; // correct skill to be erased
    fExistShadow               : Boolean;  // Whether a shadow is currently drawn somewhere
    ObjectInfos                : TInteractiveObjectInfoList; // list of objects excluding entrances
    Entries                    : TInteractiveObjectInfoList; // list of entrances (NOT USED ANYMORE)
    DosEntryTable              : array of Integer; // table for entrance release order
    fSlowingDownReleaseRate    : Boolean;
    fSpeedingUpReleaseRate     : Boolean;
    fPaused                    : Boolean;
    MaxNumLemmings             : Integer;
    LowestReleaseRate          : Integer;
    HighestReleaseRate         : Integer;
    CurrReleaseRate            : Integer;
    LastReleaseRate            : Integer;

    CurrSkillCount             : array[TBasicLemmingAction] of Integer;  // should only be called with arguments in AssignableSkills
    UsedSkillCount             : array[TBasicLemmingAction] of Integer;  // should only be called with arguments in AssignableSkills

    UserSetNuking              : Boolean;
    ExploderAssignInProgress   : Boolean;
    Index_LemmingToBeNuked     : Integer;
    fCurrentCursor             : Integer; // normal or highlight
    BrickPixelColor            : TColor32;
    BrickPixelColors           : array[0..11] of TColor32; // gradient steps
    fGameFinished              : Boolean;
    fGameCheated               : Boolean;
    NextLemmingCountDown       : Integer;
    fDrawLemmingPixel          : Boolean;
    fFastForward               : Boolean;
    fReplaying                 : Boolean;
    //fReplayIndex               : Integer;
    fCurrentScreenPosition     : TPoint; // for minimap, this really sucks but works ok for the moment
    fLastCueSoundIteration     : Integer;
    fFading                    : Boolean;
    fReplayCommanding          : Boolean;
    fTargetIteration           : Integer; // this is used in hyperspeed
    fHyperSpeedCounter         : Integer; // no screenoutput
    fHyperSpeed                : Boolean; // we are at hyperspeed no targetbitmap output
    fLeavingHyperSpeed         : Boolean; // in between state (see UpdateLemmings)
    fPauseOnHyperSpeedExit     : Boolean; // to maintain pause state before invoking a savestate
    fEntranceAnimationCompleted: Boolean;
    fStartupMusicAfterEntry    : Boolean;
    fHitTestAutoFail           : Boolean;
    fHighlightLemming          : TLemming;
    fHighlightLemmingID        : Integer;

    fFallLimit                 : Integer;
    fAssignedSkillThisFrame    : Boolean;
    fLastRecordedRR            : Integer;

    fCurrentlyDrawnLemming     : TLemming; // needed for pixelcombining bridges in combinebuilderpixels
    fUseGradientBridges        : Boolean;
    fExplodingGraphics         : Boolean;
    fDoTimePause               : Boolean;
    fCancelReplayAfterSkip     : Boolean;
  { sound vars }
    fSoundOpts                 : TGameSoundOptions;
    SoundMgr                   : TSoundMgr;
  { sound indices in list of soundmgr}
    SFX_BUILDER_WARNING        : Integer;
    SFX_ASSIGN_SKILL           : Integer;
    SFX_YIPPEE                 : Integer;
    SFX_SPLAT                  : Integer;
    SFX_LETSGO                 : Integer;
    SFX_ENTRANCE               : Integer;
    SFX_VAPORIZING             : Integer;
    SFX_DROWNING               : Integer;
    SFX_EXPLOSION              : Integer;
    SFX_HITS_STEEL             : Integer;
    SFX_OHNO                   : Integer;
    SFX_SKILLBUTTON            : Integer;
    SFX_ROPETRAP               : Integer;
    SFX_TENTON                 : Integer;
    SFX_BEARTRAP               : Integer;
    SFX_ELECTROTRAP            : Integer;
    SFX_SPINNINGTRAP           : Integer;
    SFX_SQUISHINGTRAP          : Integer;
    SFX_PICKUP                 : Integer;
    SFX_MECHANIC               : Integer;
    SFX_VACCUUM                : Integer;
    SFX_WEED                   : Integer;
    SFX_SLURP                  : Integer;
    SFX_SWIMMING               : Integer;
    SFX_FALLOUT                : Integer;
    SFX_FIXING                 : Integer;
    SFX_CUSTOM                 : Array[0..255] of Integer;
  { errors }
    //fErrorFrameCountDown       : Integer;
    //fErrorMsg                  : string;
    //fErrorCode                 : Integer;
  { events }
    fOnDebugLemming            : TLemmingEvent; // eventhandler for debugging lemming under the cursor
    fOnFinish                  : TNotifyEvent;
    fParticleFinishTimer       : Integer; // extra frames to enable viewing of explosions
  { update skill panel functions }
    procedure UpdateLemmingCounts;
    procedure UpdateTimeLimit;
    procedure UpdateOneSkillCount(aSkill: TSkillPanelButton);
    procedure UpdateAllSkillCounts;
  { pixel combine eventhandlers }
    procedure DoTalismanCheck;
    procedure CombineBuilderPixels(F: TColor32; var B: TColor32; M: TColor32);

    // CombineMaskPixels has variants based on the direction of destruction
    procedure CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32; E: TColor32); // general-purpose
    procedure CombineMaskPixelsLeft(F: TColor32; var B: TColor32; M: TColor32);       //left-facing basher
    procedure CombineMaskPixelsRight(F: TColor32; var B: TColor32; M: TColor32);      //right-facing basher
    procedure CombineMaskPixelsDownLeft(F: TColor32; var B: TColor32; M: TColor32);   //left-facing miner
    procedure CombineMaskPixelsDownRight(F: TColor32; var B: TColor32; M: TColor32);  //right-facing miner
    procedure CombineMaskPixelsNeutral(F: TColor32; var B: TColor32; M: TColor32);    //bomber

    procedure CombineNoOverwriteStoner(F: TColor32; var B: TColor32; M: TColor32);
  { internal methods }
    procedure ApplyBashingMask(L: TLemming; MaskFrame: Integer);
    procedure ApplyExplosionMask(L: TLemming);
    procedure ApplyStoneLemming(L: TLemming);
    procedure ApplyMinerMask(L: TLemming; MaskFrame, AdjustX, AdjustY: Integer);
    procedure AddConstructivePixel(X, Y: Integer);
    procedure ApplyAutoSteel;
    procedure ApplyLevelEntryOrder;
    function CalculateNextLemmingCountdown: Integer;
    procedure CheckAdjustReleaseRate;
    procedure CheckForGameFinished;
    // The next few procedures are for checking the behavior of lems in trigger areas!
    procedure CheckTriggerArea(L: TLemming);
      function HasTriggerAt(X, Y: Integer; TriggerType: TTriggerTypes): Boolean;
      function FindObjectID(X, Y: Integer; TriggerType: TTriggerTypes): Word;

      function HandleTrap(L: TLemming; ObjectID: Word): Boolean;
      function HandleTrapOnce(L: TLemming; ObjectID: Word): Boolean;
      function HandleObjAnimation(L: TLemming; ObjectID: Word): Boolean;
      function HandleTelepSingle(L: TLemming; ObjectID: Word): Boolean;
      function HandleTeleport(L: TLemming; ObjectID: Word): Boolean;
      function HandlePickup(L: TLemming; ObjectID: Word): Boolean;
      function HandleButton(L: TLemming; ObjectID: Word): Boolean;
      function HandleExit(L: TLemming; IsLocked: Boolean): Boolean;
      function HandleRadiation(L: TLemming; Stoning: Boolean): Boolean;
      function HandleForceField(L: TLemming; Direction: Integer): Boolean;
      function HandleFire(L: TLemming): Boolean;
      function HandleFlipper(L: TLemming; ObjectID: Word): Boolean;
      function HandleWaterDrown(L: TLemming): Boolean;
      function HandleWaterSwim(L: TLemming): Boolean;

    function CheckForOverlappingField(L: TLemming): Boolean;
    procedure CheckForPlaySoundEffect;
    procedure CheckForReplayAction(RRCheck: Boolean);
    procedure CheckLemmings;
    function CheckLemTeleporting(L: TLemming): Boolean;
    procedure CheckReleaseLemming;
    procedure CheckUpdateNuking;
    procedure CueSoundEffect(aSoundId: Integer); overload;
    procedure CueSoundEffect(aSoundId: Integer; aOrigin: TPoint); overload;
    function DigOneRow(PosX, PosY: Integer): Boolean;
    procedure DrawAnimatedObjects;
    procedure DrawDebugString(L: TLemming);
    //procedure DrawLemmings;
    //  procedure DrawThisLemming(L: TLemming; IsSelected: Boolean = False);
    procedure DrawParticles(L: TLemming; DoErase: Boolean); // This also erases particles now!
    procedure CheckForNewShadow;
      function GetShadowEndPos: Integer;
    procedure EraseLemmings;
    function GetTrapSoundIndex(aDosSoundEffect: Integer): Integer;
    function GetMusicFileName: String;
    function HasPixelAt(X, Y: Integer): Boolean;
    procedure IncrementIteration;
    procedure InitializeBrickColors(aBrickPixelColor: TColor32);
    procedure InitializeMiniMap;
    procedure InitializeObjectMap;
    procedure InitializeBlockerMap;
    procedure LayBrick(L: TLemming);
    function LayStackBrick(L: TLemming): Boolean;
    procedure MoveLemToReceivePoint(L: TLemming; oid: Byte);
    function ReadObjectMap(X, Y: Integer): Word;
    function ReadObjectMapType(X, Y: Integer): Byte;
    function ReadBlockerMap(X, Y: Integer): Byte;
    //function ReadSpecialMap(X, Y: Integer): Byte;
    function ReadWaterMap(X, Y: Integer): Byte;
    function ReadZombieMap(X, Y: Integer): Byte;
    procedure RecordNuke;
    procedure RecordReleaseRate(aActionFlag: Byte);
    procedure RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
    //procedure RecordSkillSelection(aSkill: TSkillPanelButton);
    procedure RemoveLemming(L: TLemming; RemMode: Integer = 0);
    procedure RemovePixelAt(X, Y: Integer);
    procedure ReplaySkillAssignment(aReplayItem: TReplaySkillAssignment);
    //procedure ReplaySkillSelection(aReplayItem: TReplaySelectSkill);
    procedure RestoreMap;
    procedure SetBlockerField(L: TLemming);
    procedure SetZombieField(L: TLemming);
    procedure AddPreplacedLemming;
    procedure Transition(L: TLemming; NewAction: TBasicLemmingAction; DoTurn: Boolean = False);
    procedure TurnAround(L: TLemming);
    function UpdateExplosionTimer(L: TLemming): Boolean;
    procedure UpdateInteractiveObjects;
    procedure WriteObjectMap(X, Y: Integer; aValue: Word; Advance: Boolean = False);
    procedure WriteBlockerMap(X, Y: Integer; aValue: Byte);
    //procedure WriteSpecialMap(X, Y: Integer; aValue: Byte);
    procedure WriteWaterMap(X, Y: Integer; aValue: Byte);
    procedure WriteZombieMap(X, Y: Integer; aValue: Byte);

    function CheckLemmingBlink: Boolean;
    function CheckTimerBlink: Boolean;

    function CheckSkillAvailable(aAction: TBasicLemmingAction): Boolean;
    procedure UpdateSkillCount(aAction: TBasicLemmingAction; Rev: Boolean = false);


  { lemming actions }
    function FindGroundPixel(x, y: Integer): Integer;
    function HasSteelAt(x, y: Integer): Boolean;
    function HasIndestructibleAt(x, y, Direction: Integer;
                                     Skill: TBasicLemmingAction): Boolean;


    function HandleLemming(L: TLemming): Boolean;
      function CheckLevelBoundaries(L: TLemming) : Boolean;
    function HandleWalking(L: TLemming): Boolean;
    function HandleJumping(L: TLemming): Boolean;
    function HandleDigging(L: TLemming): Boolean;
    function HandleClimbing(L: TLemming): Boolean;
    function HandleDrowning(L: TLemming): Boolean;
    function HandleHoisting(L: TLemming): Boolean;
    function HandleBuilding(L: TLemming): Boolean;
    function HandleBashing(L: TLemming): Boolean;
    function HandleMining(L: TLemming): Boolean;
    function HandleFalling(L: TLemming): Boolean;
    function HandleFloating(L: TLemming): Boolean;
    function HandleSplatting(L: TLemming): Boolean;
    function HandleExiting(L: TLemming): Boolean;
    function HandleVaporizing(L: TLemming): Boolean;
    function HandleBlocking(L: TLemming): Boolean;
    function HandleShrugging(L: TLemming): Boolean;
    function HandleOhNoing(L: TLemming): Boolean;
    function HandleExploding(L: TLemming): Boolean;
    function HandlePlatforming(L: TLemming): Boolean;
      function LemCanPlatform(L: TLemming): Boolean;
    function HandleStacking(L: TLemming): Boolean;
    function HandleSwimming(L: TLemming): Boolean;
    function HandleGliding(L: TLemming): Boolean;
    function HandleFixing(L: TLemming): Boolean;

  { interaction }
    function AssignNewSkill(Skill: TBasicLemmingAction; IsHighlight: Boolean = False): Boolean;
    procedure GenerateClonedLem(L: TLemming);
    function GetPriorityLemming(out PriorityLem: TLemming;
                                  NewSkillOrig: TBasicLemmingAction;
                                  MousePos: TPoint;
                                  IsHighlight: Boolean = False): Integer;
    function DoSkillAssignment(L: TLemming; NewSkill: TBasicLemmingAction): Boolean;

    function MayAssignWalker(L: TLemming): Boolean;
    function MayAssignClimber(L: TLemming): Boolean;
    function MayAssignFloaterGlider(L: TLemming): Boolean;
    function MayAssignSwimmer(L: TLemming): Boolean;
    function MayAssignMechanic(L: TLemming): Boolean;
    function MayAssignBlocker(L: TLemming): Boolean;
    function MayAssignExploderStoner(L: TLemming): Boolean;
    function MayAssignBuilder(L: TLemming): Boolean;
    function MayAssignPlatformer(L: TLemming): Boolean;
    function MayAssignStacker(L: TLemming): Boolean;
    function MayAssignBasher(L: TLemming): Boolean;
    function MayAssignMiner(L: TLemming): Boolean;
    function MayAssignDigger(L: TLemming): Boolean;
    function MayAssignCloner(L: TLemming): Boolean;

    // procedure OnAssignSkill(Lemming1: TLemming; aSkill: TBasicLemmingAction);

    procedure SetOptions(const Value: TDosGameOptions);
    procedure SetSoundOpts(const Value: TGameSoundOptions);
  public
    MiniMap                    : TBitmap32; // minimap of world  
    GameResult                     : Boolean;
    GameResultRec                  : TGameResultsRec;
    SkillButtonsDisabledWhenPaused : Boolean; // this really should move somewere else
    fSelectDx                  : Integer;
    fXmasPal                   : Boolean;
    UseReplayPhotoFlashEffect      : Boolean;
    fAssignEnabled                    : Boolean;
    InstReleaseRate            : Integer;
    fActiveSkills              : array[0..7] of TSkillPanelButton;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  { iteration }
    procedure PrepareParams(aParams: TDosGameParams);
    procedure Start(aReplay: Boolean = False);
      procedure SetObjectInfos;
    procedure UpdateLemmings;

  { callable }
    procedure AdjustReleaseRate(Delta: Integer);
    procedure CreateLemmingAtCursorPoint;
    procedure Finish;
    procedure Cheat;
    procedure HitTest(Autofail: Boolean = false);
    procedure HyperSpeedBegin(PauseWhenDone: Boolean = False);
    procedure HyperSpeedEnd;
    function ProcessSkillAssignment: Boolean;
    function ProcessHighlightAssignment: Boolean;
    procedure RefreshAllPanelInfo;
    procedure RegainControl;
    procedure Save(TestModeName: Boolean = false);
    procedure SetGameResult;
    procedure SetSelectedSkill(Value: TSkillPanelButton; MakeActive: Boolean = True; RightClick: Boolean = False);
    procedure SaveGameplayImage(Filename: String);
    function GetSelectedSkill: Integer;
    function Checkpass: Boolean;

  { properties }
    property CurrentCursor: Integer read fCurrentCursor;
    property CurrentIteration: Integer read fCurrentIteration;
    property ClockFrame: Integer read fClockFrame;
    property CursorPoint: TPoint read fCursorPoint write fCursorPoint;
    property DrawLemmingPixel: Boolean read fDrawLemmingPixel write fDrawLemmingPixel;
    property Fading: Boolean read fFading;
    property FastForward: Boolean read fFastForward write fFastForward;
    property GameFinished: Boolean read fGameFinished;
    property HyperSpeed: Boolean read fHyperSpeed;
    property InfoPainter: IGameToolbar read fInfoPainter write fInfoPainter;
    property LeavingHyperSpeed: Boolean read fLeavingHyperSpeed;
    property Level: TLevel read fLevel write fLevel;
    property CurrentScreenPosition: TPoint read fCurrentScreenPosition write fCurrentScreenPosition;
    property Options: TDosGameOptions read fOptions write SetOptions default DOSORIG_GAMEOPTIONS;
    property Paused: Boolean read fPaused write fPaused;
    property Playing: Boolean read fPlaying write fPlaying;
    property Renderer: TRenderer read fRenderer;
    property Replaying: Boolean read fReplaying;
    property ReplayManager: TReplay read fReplayManager;
    property RightMouseButtonHeldDown: Boolean read fRightMouseButtonHeldDown write fRightMouseButtonHeldDown;
    property ShiftButtonHeldDown: Boolean read fShiftButtonHeldDown write fShiftButtonHeldDown;
    property AltButtonHeldDown: Boolean read fAltButtonHeldDown write fAltButtonHeldDown;
    property CtrlButtonHeldDown: Boolean read fCtrlButtonHeldDown write fCtrlButtonHeldDown;
    property SlowingDownReleaseRate: Boolean read fSlowingDownReleaseRate;
    property SoundOpts: TGameSoundOptions read fSoundOpts write SetSoundOpts;
    property SpeedingUpReleaseRate: Boolean read fSpeedingUpReleaseRate;
    property TargetIteration: Integer read fTargetIteration write fTargetIteration;
    property CancelReplayAfterSkip: Boolean read fCancelReplayAfterSkip write fCancelReplayAfterSkip;
    property DoTimePause: Boolean read fDoTimePause write fDoTimePause;
    property HitTestAutoFail: Boolean read fHitTestAutoFail write fHitTestAutoFail;
    property LastReplayDir: String read fLastReplayDir write fLastReplayDir;

    property RenderInterface: TRenderInterface read fRenderInterface;

    function GetLevelWidth: Integer;
    function GetLevelHeight: Integer;

  { save / load state }
    procedure CreateSavedState(aState: TLemmingGameSavedState);
    function LoadSavedState(aState: TLemmingGameSavedState; SkipTargetBitmap: Boolean = false): Boolean;

  { events }
    property OnDebugLemming: TLemmingEvent read fOnDebugLemming write fOnDebugLemming;
    property OnFinish: TNotifyEvent read fOnFinish write fOnFinish;
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
  UFastStrings,
  LemDosStyle;

const
  LEMMIX_REPLAY_VERSION    = 105;
  MAX_REPLAY_RECORDS       = 32768;
  MAX_FALLDISTANCE         = 62;

const
  // Values for DOM_TRIGGERTYPE are defined in LemObjects.pas!
  // Here only for refence.
(*DOM_NOOBJECT         = 65535;
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
  DOM_SECRET           = 16; // no longer used!!
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
  DOM_TRAPONCE         = 31;  *)

  // removal modes
  RM_NEUTRAL           = 0;
  RM_SAVE              = 1;
  RM_KILL              = 2;
  RM_ZOMBIE            = 3;

  HEAD_MIN_Y = -7;
  //LEMMING_MIN_X = 0;
  //LEMMING_MAX_X = 1647;
  LEMMING_MAX_Y = 9;

  PARTICLE_FRAMECOUNT = 52;
  PARTICLE_FINISH_FRAMECOUNT = 52;

const
  // Order is important, because fTalismans[i].SkillLimit uses the corresponding integers!!!
  // THIS IS NOT THE ORDER THE PICKUP-SKILLS ARE NUMBERED!!!
  ActionListArray: array[0..15] of TBasicLemmingAction =
            (baToWalking, baClimbing, baSwimming, baFloating, baGliding, baFixing,
             baExploding, baStoning, baBlocking, baPlatforming, baBuilding,
             baStacking, baBashing, baMining, baDigging, baCloning);



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
  ObjectInfos := TInteractiveObjectInfoList.Create(true);
  TargetBitmap := TBitmap32.Create;
  World := TBitmap32.Create;
  //SteelWorld := TBitmap32.Create;
  PhysicsMap := TBitmap32.Create;
  ObjectMap := TByteMap.Create;
  BlockerMap := TByteMap.Create;
  //SpecialMap := TByteMap.Create;
  WaterMap := TByteMap.Create;
  ZombieMap := TByteMap.Create;
end;

destructor TLemmingGameSavedState.Destroy;
begin
  LemmingList.Free;
  ObjectInfos.Free;
  TargetBitmap.Free;
  World.Free;
  //SteelWorld.Free;
  PhysicsMap.Free;
  ObjectMap.Free;
  BlockerMap.Free;
  //SpecialMap.Free;
  WaterMap.Free;
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
  // What we want to save:
  // -- Last minute: One save every 10 seconds
  // -- Last 3 minutes: One save every 30 seconds
  // -- Beyond that: One save every minute
  // -- Additionally, a save immediately after the level is initially rendered
  // This will result in 11 saved states, plus one more for every minute taken
  // that isn't in the most recent 3 minutes. This should be manageable.
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
procedure TLemmingGame.UpdateLemmingCounts;
begin
  // Set Lemmings in Hatch, Lemmings Alive and Lemmings Saved
  InfoPainter.SetInfoLemHatch((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsOut + LemmingsRemoved), false);
  InfoPainter.SetInfoLemAlive((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsRemoved), CheckLemmingBlink);
  InfoPainter.SetInfoLemIn(LemmingsIn - Level.Info.RescueCount, False);
end;

procedure TLemmingGame.UpdateTimeLimit;
var
  TimeMinutes, TimeSeconds: Integer;
begin
  // Keep TimeSeconds and TimeMinues as separate variables!
  // Otherwise weird visual glitches occur when framestepping 10 seconds
  TimeMinutes := abs(TimePlay) div 60;
  TimeSeconds := abs(TimePlay) mod 60;
  InfoPainter.SetInfoMinutes(TimeMinutes, CheckTimerBlink);
  InfoPainter.SetInfoSeconds(TimeSeconds, CheckTimerBlink);
end;

procedure TLemmingGame.UpdateOneSkillCount(aSkill: TSkillPanelButton);
begin
  if aSkill = spbSlower then
    InfoPainter.DrawSkillCount(spbSlower, Level.Info.ReleaseRate)
  else if aSkill = spbFaster then
    InfoPainter.DrawSkillCount(spbFaster, CurrReleaseRate)
  else if aSkill in [spbWalker..spbCloner] then
    InfoPainter.DrawSkillCount(aSkill, CurrSkillCount[SkillPanelButtonToAction[aSkill]]);
end;

procedure TLemmingGame.UpdateAllSkillCounts;
var
  i: TSkillPanelButton;
begin
  for i := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    UpdateOneSkillCount(i);
end;

procedure TLemmingGame.CreateSavedState(aState: TLemmingGameSavedState);
var
  i: Integer;
begin
  // Simple stuff
  aState.SelectedSkill := fSelectedSkill;
  aState.TargetBitmap.Assign(fTargetBitmap);
  aState.World.Assign(fRenderer.TerrainLayer);
  //aState.SteelWorld.Assign(SteelWorld);
  aState.PhysicsMap.Assign(PhysicsMap);
  aState.ObjectMap.Assign(ObjectMap);
  aState.BlockerMap.Assign(BlockerMap);
  //aState.SpecialMap.Assign(SpecialMap);
  aState.WaterMap.Assign(WaterMap);
  aState.ZombieMap.Assign(ZombieMap);
  aState.CurrentIteration := fCurrentIteration;
  aState.ClockFrame := fClockFrame;
  aState.ButtonsRemain := ButtonsRemain;
  aState.LemmingsReleased := LemmingsReleased;
  aState.LemmingsCloned := LemmingsCloned;
  aState.LemmingsOut := LemmingsOut;
  aState.SpawnedDead := SpawnedDead;
  aState.LemmingsIn := LemmingsIn;
  aState.LemmingsRemoved := LemmingsRemoved;
  aState.NextLemmingCountdown := NextLemmingCountdown;
  aState.DelayEndFrames := DelayEndFrames;
  aState.TimePlay := TimePlay;
  aState.EntriesOpened := EntriesOpened;
  aState.LowestReleaseRate := LowestReleaseRate;
  aState.HighestReleaseRate := HighestReleaseRate;
  aState.CurrReleaseRate := CurrReleaseRate;
  aState.LastReleaseRate := LastReleaseRate;

  for i := 0 to 15 do
  begin
    aState.CurrSkillCount[ActionListArray[i]] := CurrSkillCount[ActionListArray[i]];
    aState.UsedSkillCount[ActionListArray[i]] := UsedSkillCount[ActionListArray[i]];
  end;

  aState.UserSetNuking := UserSetNuking;
  aState.Index_LemmingToBeNuked := Index_LemmingToBeNuked;
  aState.LastRecordedRR := fLastRecordedRR;

  // Lemmings.
  aState.LemmingList.Clear;
  for i := 0 to LemmingList.Count-1 do
  begin
    aState.LemmingList.Add(TLemming.Create);
    aState.LemmingList[i].Assign(LemmingList[i]);
  end;

  // Objects.
  aState.ObjectInfos.Clear;
  for i := 0 to ObjectInfos.Count-1 do
  begin
    aState.ObjectInfos.Add(TInteractiveObjectInfo.Create);
    ObjectInfos[i].AssignTo(aState.ObjectInfos[i]);
  end;
end;

function TLemmingGame.LoadSavedState(aState: TLemmingGameSavedState; SkipTargetBitmap: Boolean = false): Boolean;
var
  i: Integer;
begin
  // Let's check if we can use this state. If a skill was assigned on the frame, we should mark this one
  // unusable. Code in TGameWindow will then delete it. (This is kludgy, but easier to implement over the
  // current setup than not creating the state in the first place would be.)
  Result := true;
  if fReplayManager.HasAnyActionAt(aState.CurrentIteration) then Result := false;
  if not Result then Exit;

  // First, some preparation, eg. undraw the selection rectangle for the selected skill
  InfoPainter.DrawButtonSelector(fSelectedSkill, false);

  // Simple stuff
  (*if not fGameParams.IgnoreReplaySelection then
    fSelectedSkill := aState.SelectedSkill;*)
  if not SkipTargetBitmap then  // We don't need to bother with this one if we're not loading the exact frame we want to go to
    fTargetBitmap.Assign(aState.TargetBitmap);
  fRenderer.TerrainLayer.Assign(aState.World);
  //SteelWorld.Assign(aState.SteelWorld);
  PhysicsMap.Assign(aState.PhysicsMap);
  ObjectMap.Assign(aState.ObjectMap);
  BlockerMap.Assign(aState.BlockerMap);
  //SpecialMap.Assign(aState.SpecialMap);
  WaterMap.Assign(aState.WaterMap);
  ZombieMap.Assign(aState.ZombieMap);
  fCurrentIteration := aState.CurrentIteration;
  fClockFrame := aState.ClockFrame;
  ButtonsRemain := aState.ButtonsRemain;
  LemmingsReleased := aState.LemmingsReleased;
  LemmingsCloned := aState.LemmingsCloned;
  LemmingsOut := aState.LemmingsOut;
  SpawnedDead := aState.SpawnedDead;
  LemmingsIn := aState.LemmingsIn;
  LemmingsRemoved := aState.LemmingsRemoved;
  NextLemmingCountdown := aState.NextLemmingCountdown;
  DelayEndFrames := aState.DelayEndFrames;
  TimePlay := aState.TimePlay;
  EntriesOpened := aState.EntriesOpened;
  LowestReleaseRate := aState.LowestReleaseRate;
  HighestReleaseRate := aState.HighestReleaseRate;
  CurrReleaseRate := aState.CurrReleaseRate;
  LastReleaseRate := aState.LastReleaseRate;

  for i := 0 to 15 do
  begin
    CurrSkillCount[ActionListArray[i]] := aState.CurrSkillCount[ActionListArray[i]];
    UsedSkillCount[ActionListArray[i]] := aState.UsedSkillCount[ActionListArray[i]];
  end;

  UserSetNuking := aState.UserSetNuking;
  Index_LemmingToBeNuked := aState.Index_LemmingToBeNuked;
  fLastRecordedRR := aState.LastRecordedRR;

  // Lemmings.
  LemmingList.Clear;
  for i := 0 to aState.LemmingList.Count-1 do
  begin
    LemmingList.Add(TLemming.Create);
    LemmingList[i].Assign(aState.LemmingList[i]);
    LemmingList[i].LemIndex := i;
    if fHighlightLemmingID = i then
      fHighlightLemming := LemmingList[i];
  end;

  // Objects
  for i := 0 to ObjectInfos.Count-1 do
  begin
    aState.ObjectInfos[i].AssignTo(ObjectInfos[i]);
  end;

  // When loading, we must update the info panel. But if we're just using the state
  // for an approximate location, we don't need to do this, it just results in graphical
  // glitching as the values from load time are shown for a split second.
  if not SkipTargetBitmap then
    RefreshAllPanelInfo;

  // And we must get the replay index to the right point and activate replay mode
  fReplaying := true;
  //fReplayIndex := fRecorder.FindIndexForFrame(fCurrentIteration);
  InfoPainter.SetReplayMark(true);

  // And, update the minimap. Probably easier to redo this from scratch.
  InitializeMiniMap;
end;

procedure TLemmingGame.RefreshAllPanelInfo;
begin
  InfoPainter.DrawButtonSelector(fSelectedSkill, true);
  UpdateLemmingCounts;
  UpdateTimeLimit;
  UpdateAllSkillCounts;
end;

procedure TLemmingGame.DoTalismanCheck;
var
  i, i2, j: Integer;
  TotalSkillUsed: Integer;
  FoundIssue: Boolean;
  UsedSkillLems: Integer;
  GetTalisman: Boolean;
begin
  for i := 0 to fTalismans.Count-1 do
  begin
    if fGameParams.SaveSystem.CheckTalisman(fTalismans[i].Signature) then Continue;
    with fTalismans[i] do
    begin

      if    (LemmingsIn < SaveRequirement)
         or ((SaveRequirement = 0) and (LemmingsIn < fGameParams.Level.Info.RescueCount)) then Continue;

      if    ((TimeLimit <> 0) and (CurrentIteration > TimeLimit))
         or ((TimeLimit = 0) and (CurrentIteration > Level.Info.TimeLimit * 17)) then Continue;
      if LowestReleaseRate < RRMin then Continue;
      if HighestReleaseRate > RRMax then Continue;

      TotalSkillUsed := 0;
      GetTalisman := True;
      for j := 0 to 15 do
      begin
        if (UsedSkillCount[ActionListArray[j]] > SkillLimit[j]) and (SkillLimit[j] <> -1) then GetTalisman := False;
        TotalSkillUsed := TotalSkillUsed + UsedSkillCount[ActionListArray[j]];
      end;
      if not GetTalisman then Continue;

      if (TotalSkillUsed > TotalSkillLimit) and (TotalSkillLimit <> -1) then Continue;

      FoundIssue := false;
      if tmOneSkill in MiscOptions then
        for i2 := 0 to LemmingList.Count-1 do
          with LemmingList[i2] do
           if (LemUsedSkillCount > 1) then FoundIssue := true;
      if FoundIssue then Continue;

      UsedSkillLems := 0;
      if tmOneLemming in MiscOptions then
        for i2 := 0 to LemmingList.Count-1 do
          with LemmingList[i2] do
            if (LemUsedSkillCount > 0) then Inc(UsedSkillLems);
      if UsedSkillLems > 1 then Continue;

      // Award Talisman
      fGameParams.SaveSystem.GetTalisman(Signature);
      if TalismanType <> 0 then fTalismanReceived := True;

    end;
  end;
end;

function TLemmingGame.Checkpass: Boolean;
begin
  Result := fGameCheated or (LemmingsIn >= Level.Info.RescueCount);
end;

function TLemmingGame.GetLevelWidth: Integer;
begin
  Result := fGameParams.Level.Info.Width;
end;

function TLemmingGame.GetLevelHeight: Integer;
begin
  Result := fGameParams.Level.Info.Height;
end;

constructor TLemmingGame.Create(aOwner: TComponent);
var
  P: string;
begin
  inherited Create(aOwner);

  fRenderInterface := TRenderInterface.Create;

  LemmingList    := TLemmingList.Create;
  //World          := TBitmap32.Create;
  //SteelWorld     := TBitmap32.Create;
  ExplodeMaskBmp := TBitmap32.Create;
  ObjectInfos    := TInteractiveObjectInfoList.Create;
  Entries        := TInteractiveObjectInfoList.Create;
  ObjectMap      := TByteMap.Create;
  BlockerMap     := TByteMap.Create;
  //SpecialMap     := TByteMap.Create;
  ZombieMap      := TByteMap.Create;
  WaterMap       := TByteMap.Create;
  MiniMap        := TBitmap32.Create;
  //fRecorder      := TRecorder.Create(Self);
  fReplayManager := TReplay.Create;
  fOptions       := DOSORIG_GAMEOPTIONS;
  SoundMgr       := TSoundMgr.Create;
  fTalismans     := TTalismans.Create;

  fRenderInterface.LemmingList := LemmingList;
  fRenderInterface.ObjectList := ObjectInfos;
  fRenderInterface.SetSelectedSkillPointer(fSelectedSkill);
  fRenderInterface.SelectedLemming := nil;
  fRenderInterface.HighlitLemming := nil;
  fRenderInterface.ReplayLemming := nil;

  LemmingMethods[baNone]       := nil;
  LemmingMethods[baWalking]    := HandleWalking;
  LemmingMethods[baJumping]    := HandleJumping;
  LemmingMethods[baDigging]    := HandleDigging;
  LemmingMethods[baClimbing]   := HandleClimbing;
  LemmingMethods[baDrowning]   := HandleDrowning;
  LemmingMethods[baHoisting]   := HandleHoisting;
  LemmingMethods[baBuilding]   := HandleBuilding;
  LemmingMethods[baBashing]    := HandleBashing;
  LemmingMethods[baMining]     := HandleMining;
  LemmingMethods[baFalling]    := HandleFalling;
  LemmingMethods[baFloating]   := HandleFloating;
  LemmingMethods[baSplatting]  := HandleSplatting;
  LemmingMethods[baExiting]    := HandleExiting;
  LemmingMethods[baVaporizing] := HandleVaporizing;
  LemmingMethods[baBlocking]   := HandleBlocking;
  LemmingMethods[baShrugging]  := HandleShrugging;
  LemmingMethods[baOhnoing]    := HandleOhNoing;
  LemmingMethods[baExploding]  := HandleExploding;
  LemmingMethods[baToWalking]  := HandleWalking; //should never happen anyway
  LemmingMethods[baPlatforming] := HandlePlatforming;
  LemmingMethods[baStacking]   := HandleStacking;
  LemmingMethods[baStoning]    := HandleOhNoing; // same behavior!
  LemmingMethods[baStoneFinish] := HandleExploding; // same behavior, except applied mask!
  LemmingMethods[baSwimming]   := HandleSwimming;
  LemmingMethods[baGliding]    := HandleGliding;
  LemmingMethods[baFixing]     := HandleFixing;

  NewSkillMethods[baNone]         := nil;
  NewSkillMethods[baWalking]      := nil;
  NewSkillMethods[baJumping]      := nil;
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
  NewSkillMethods[baBlocking]     := MayAssignBlocker;
  NewSkillMethods[baShrugging]    := nil;
  NewSkillMethods[baOhnoing]      := nil;
  NewSkillMethods[baExploding]    := MayAssignExploderStoner;
  NewSkillMethods[baToWalking]    := MayAssignWalker;
  NewSkillMethods[baPlatforming]  := MayAssignPlatformer;
  NewSkillMethods[baStacking]     := MayAssignStacker;
  NewSkillMethods[baStoning]      := MayAssignExploderStoner;
  NewSkillMethods[baSwimming]     := MayAssignSwimmer;
  NewSkillMethods[baGliding]      := MayAssignFloaterGlider;
  NewSkillMethods[baFixing]       := MayAssignMechanic;
  NewSkillMethods[baCloning]      := MayAssignCloner;


  fFallLimit := MAX_FALLDISTANCE;

  P := AppPath;
  fLastReplayDir := '';

  with SoundMgr do
  begin
    SFX_BUILDER_WARNING := AddSoundFromFileName(P + 'sounds\win\' + 'ting.wav');
    SFX_ASSIGN_SKILL    := AddSoundFromFileName(P + 'sounds\win\' + 'mousepre.wav');
    SFX_YIPPEE          := AddSoundFromFileName(P + 'sounds\win\' + 'yippee.wav');
    SFX_SPLAT           := AddSoundFromFileName(P + 'sounds\win\' + 'splat.wav');
    SFX_LETSGO          := AddSoundFromFileName(P + 'sounds\win\' + 'letsgo.wav');
    SFX_ENTRANCE        := AddSoundFromFileName(P + 'sounds\win\' + 'door.wav');
    SFX_VAPORIZING      := AddSoundFromFileName(P + 'sounds\win\' + 'fire.wav');
    SFX_DROWNING        := AddSoundFromFileName(P + 'sounds\win\' + 'glug.wav');
    SFX_EXPLOSION       := AddSoundFromFileName(P + 'sounds\win\' + 'explode.wav');
    SFX_HITS_STEEL      := AddSoundFromFileName(P + 'sounds\win\' + 'chink.wav');
    SFX_OHNO            := AddSoundFromFileName(P + 'sounds\win\' + 'ohno.wav');
    SFX_SKILLBUTTON     := AddSoundFromFileName(P + 'sounds\win\' + 'changeop.wav');
    SFX_ROPETRAP        := AddSoundFromFileName(P + 'sounds\win\' + 'chain.wav');
    SFX_TENTON          := AddSoundFromFileName(P + 'sounds\win\' + 'tenton.wav');
    SFX_BEARTRAP        := AddSoundFromFileName(P + 'sounds\win\' + 'thunk.wav');
    SFX_ELECTROTRAP     := AddSoundFromFileName(P + 'sounds\win\' + 'electric.wav');
    SFX_SPINNINGTRAP    := AddSoundFromFileName(P + 'sounds\win\' + 'chain.wav');
    SFX_SQUISHINGTRAP   := AddSoundFromFileName(P + 'sounds\win\' + 'thud.wav');
    SFX_PICKUP          := AddSoundFromFileName(P + 'sounds\win\' + 'oing2.wav');
    SFX_MECHANIC        := AddSoundFromFileName(P + 'sounds\win\' + 'ting.wav');
    SFX_VACCUUM         := AddSoundFromFileName(P + 'sounds\win\' + 'vacuusux.wav');
    SFX_SLURP           := AddSoundFromFileName(P + 'sounds\win\' + 'slurp.wav');
    SFX_WEED            := AddSoundFromFileName(P + 'sounds\win\' + 'weedgulp.wav');
    SFX_SWIMMING        := AddSoundFromFileName(P + 'sounds\win\' + 'splash.wav');
    SFX_FALLOUT         := AddSoundFromFileName(P + 'sounds\win\' + 'die.wav');
    SFX_FIXING          := AddSoundFromFileName(P + 'sounds\win\' + 'wrench.wav');

    SoundMgr.BrickSound := SFX_BUILDER_WARNING;
  end;

  ButtonsRemain := 0;
  fHitTestAutoFail := false;
  fAssignedSkillThisFrame := false;

end;

destructor TLemmingGame.Destroy;
begin
  LemmingList.Free;
  ObjectInfos.Free;
  //World.Free;
  //SteelWorld.Free;
  Entries.Free;
  ObjectMap.Free;
  BlockerMap.Free;
  //SpecialMap.Free;
  ZombieMap.Free;
  WaterMap.Free;
  MiniMap.Free;
  fReplayManager.Free;
  SoundMgr.Free;
  ExplodeMaskBmp.Free;
  fTalismans.Free;
  fRenderInterface.Free;
  inherited Destroy;
end;

function TLemmingGame.GetMusicFileName: String;
var
  TempStream: TMemoryStream;
  SL: TStringList;
  MusicNumber: Integer;
begin
  if (Level.Info.MusicFile <> '')
  and (LeftStr(Level.Info.MusicFile, 1) <> '?')
  and (LeftStr(Level.Info.MusicFile, 1) <> '*') then
  begin
    Result := Level.Info.MusicFile;
    Exit;
  end;

  SL := TStringList.Create;
  TempStream := CreateDataStream('music.txt', ldtLemmings); // It's a text file, but should be loaded more similarly to data files.
  if TempStream = nil then
  begin
    TempStream := TMemoryStream.Create;
    TempStream.LoadFromFile(AppPath + 'data\music.nxmi');
  end;
  SL.LoadFromStream(TempStream);
  TempStream.Free;

  MusicNumber := -1;
  if LeftStr(Level.Info.MusicFile, 1) = '?' then
    MusicNumber := StrToIntDef(MidStr(Level.Info.MusicFile, 2, Length(Level.Info.MusicFile)-1), -1) - 1;

  if SL.Count = 0 then
    Result := ''
  else begin
    if MusicNumber < 0 then
      if fGameParams.fTestMode then
      begin
        Randomize;
        MusicNumber := Random(SL.Count);
      end else
        MusicNumber := fGameParams.Info.dLevel mod SL.Count;
    Result := SL[MusicNumber];
  end;

  SL.Free;
end;

procedure TLemmingGame.PrepareParams(aParams: TDosGameParams);
var
  //Inf: TRenderInfoRec;
  Ani: TBaseDosAnimationSet;
  i: Integer;
  Bmp: TBitmap32;
  LowPal, HiPal, Pal: TArrayOfColor32;

  //LemBlack: TColor32;
  S: TStream;


  procedure PrepareMusic;
  var
    MS: TMemoryStream;
    MusicSys: TBaseMusicSystem;
    MusicFileName: String;
  begin
    MS := nil;
    try
      MusicSys := fGameParams.Style.MusicSystem;
      if MusicSys = nil then Exit;

      MusicFileName := GetMusicFileName;
      MS := CreateDataStream(MusicFileName, ldtMusic);
      if MS = nil then
      begin
        Level.Info.MusicFile := '';
        MusicFileName := GetMusicFileName;
        MS := CreateDataStream(MusicFileName, ldtMusic);
      end;

      if MS <> nil then
        SoundMgr.AddMusicFromStream(MS);

    finally
      MS.Free;
    end;
  end;
begin

  fGameParams := aParams;
  fXmasPal := fGameParams.SysDat.Options2 and 2 <> 0;

  fStartupMusicAfterEntry := True;

  fSoundOpts := fGameParams.SoundOptions;
  fUseGradientBridges := true;

  fRenderer := fGameParams.Renderer; // set ref
  fTargetBitmap := fGameParams.TargetBitmap;
  Level := fGameParams.Level;
  Style := fGameParams.Style;

  {-------------------------------------------------------------------------------
    Initialize the palette of AnimationSet.
    Low part is the fixed palette
    Hi part comes from the graphicset.
    After that let the AnimationSet read the animations
  -------------------------------------------------------------------------------}
  LowPal := DosPaletteToArrayOfColor32(DosInLevelPalette);
  if fXmasPal then
  begin
    LowPal[1] := $D02020;
    LowPal[4] := $F0F000;
    LowPal[5] := $4040E0;
  end;
  SetLength(HiPal, 8);
  for i := 0 to 7 do
    HiPal[i] := PARTICLE_COLORS[i];
  LowPal[7] := Renderer.Theme.Colors[MASK_COLOR]; // copy the brickcolor
  SetLength(Pal, 16);
  for i := 0 to 7 do
    Pal[i] := LowPal[i];
  for i := 8 to 15 do
    Pal[i] := HiPal[i - 8];

  Ani := Style.AnimationSet as TBaseDosAnimationSet;
  Ani.AnimationPalette := Copy(Pal);
  Ani.ClearData;
  if (fGameParams.SysDat.Options3 and 128) <> 0 then
    Ani.LemmingPrefix := 'lemming'
  else if (fGameParams.SysDat.Options3 and 64) <> 0 then
    Ani.LemmingPrefix := 'xlemming'
  else
    Ani.LemmingPrefix := Renderer.Theme.Lemmings;
  Ani.ReadData;

  // initialize explosion particle colors
  for i := 0 to 15 do
    fParticleColors[i] := Pal[ParticleColorIndices[i]];

  // prepare masks for drawing
  CntDownBmp := Ani.CountDownDigitsBitmap;
  CntDownBmp.DrawMode := dmCustom;
  CntDownBmp.OnPixelCombine := TRecolorImage.CombineDefaultPixels;

  HighlightBmp := Ani.HighlightBitmap;
  HighlightBmp.DrawMode := dmCustom;
  HighlightBmp.OnPixelCombine := TRecolorImage.CombineDefaultPixels;

  ExplodeMaskBmp.Assign(Ani.ExplosionMaskBitmap);
  ExplodeMaskBmp.DrawMode := dmCustom;
  ExplodeMaskBmp.OnPixelCombine := CombineMaskPixelsNeutral;

  fHighlightLemmingID := -1;

  BashMasks := Ani.BashMasksBitmap;
  BashMasks.DrawMode := dmCustom;
  BashMasks.OnPixelCombine := CombineMaskPixelsRight;

  BashMasksRTL := Ani.BashMasksRTLBitmap;
  BashMasksRTL.DrawMode := dmCustom;
  BashMasksRTL.OnPixelCombine := CombineMaskPixelsLeft;

  MineMasks := Ani.MineMasksBitmap;
  MineMasks.DrawMode := dmCustom;
  MineMasks.OnPixelCombine := CombineMaskPixelsDownRight;

  MineMasksRTL := Ani.MineMasksRTLBitmap;
  MineMasksRTL.DrawMode := dmCustom;
  MineMasksRTL.OnPixelCombine := CombineMaskPixelsDownLeft;

  // prepare animationbitmaps for drawing (set eventhandlers)
  with Ani.LemmingAnimations do
    for i := 0 to Count - 1 do
    begin
      Bmp := List^[i];
      Bmp.DrawMode := dmCustom;
      if i in [BRICKLAYING, BRICKLAYING_RTL, PLATFORMING, PLATFORMING_RTL] then
        Bmp.OnPixelCombine := CombineBuilderPixels
      else
        Bmp.OnPixelCombine := TRecolorImage.CombineDefaultPixels;
    end;

  StoneLemBmp := Ani.LemmingAnimations.Items[STONED];
  StoneLemBmp.DrawMode := dmCustom;
  StoneLemBmp.OnPixelCombine := CombineNoOverwriteStoner;

  //World.SetSize(Level.Info.Width, Level.Info.Height);
  //SteelWorld.SetSize(Level.Info.Width, Level.Info.Height);

  //Renderer.RenderPhysicsMap;
  PhysicsMap := Renderer.PhysicsMap;
  RenderInterface.PhysicsMap := PhysicsMap;

  PrepareMusic;

  fTalismans.Clear;

  for i := 0 to fGameParams.Talismans.Count-1 do
  begin
    if (fGameParams.Talismans[i].RankNumber = fGameParams.Info.dSection)
    and (fGameParams.Talismans[i].LevelNumber = fGameParams.Info.dLevel) then
      fTalismans.Add.Assign(fGameParams.Talismans[i]);
  end;

end;

procedure TLemmingGame.Start(aReplay: Boolean = False);
{-------------------------------------------------------------------------------
  part of the initialization is still in FGame. bad programming
  (i.e: renderer.levelbitmap, level, infopainter)
-------------------------------------------------------------------------------}
var
  i, i2, i3: Integer;
  Inf: TInteractiveObjectInfo;
  numEntries:integer;
begin
  Assert(InfoPainter <> nil);

  Playing := False;

  if moChallengeMode in fGameParams.MiscOptions then
  begin
    fGameParams.Level.Info.ClimberCount    := 0;
    fGameParams.Level.Info.FloaterCount    := 0;
    fGameParams.Level.Info.BomberCount     := 0;
    fGameParams.Level.Info.BlockerCount    := 0;
    fGameParams.Level.Info.BuilderCount    := 0;
    fGameParams.Level.Info.BasherCount     := 0;
    fGameParams.Level.Info.MinerCount      := 0;
    fGameParams.Level.Info.DiggerCount     := 0;
    fGameParams.Level.Info.WalkerCount     := 0;
    fGameParams.Level.Info.SwimmerCount    := 0;
    fGameParams.Level.Info.GliderCount     := 0;
    fGameParams.Level.Info.MechanicCount   := 0;
    fGameParams.Level.Info.StonerCount     := 0;
    fGameParams.Level.Info.PlatformerCount := 0;
    fGameParams.Level.Info.StackerCount    := 0;
    fGameParams.Level.Info.ClonerCount     := 0;
  end;

  // hyperspeed things
  fTargetIteration := 0;
  fHyperSpeedCounter := 0;
  fHyperSpeed := False;
  fLeavingHyperSpeed := False;
  fPauseOnHyperSpeedExit := False;
  fEntranceAnimationCompleted := False;

  fFastForward := False;

  //Inc(fStartCalls); // this is used for music, we do not want to restart music each start
  fGameFinished := False;
  fGameCheated := False;
  LemmingsReleased := 0;
  LemmingsCloned := 0;
  fHighlightLemming := nil;
  //World.OuterColor := 0;
  TimePlay := Level.Info.TimeLimit;
  if (TimePlay > 5999) or (moTimerMode in fGameParams.MiscOptions) then
    TimePlay := 0; // infinite time

  Options := DOSOHNO_GAMEOPTIONS;

  SkillButtonsDisabledWhenPaused := False;

  FillChar(GameResultRec, SizeOf(GameResultRec), 0);
  GameResultRec.gCount  := Level.Info.LemmingsCount;
  GameResultRec.gToRescue := Level.Info.RescueCount;


  LemmingsReleased := 0;
  LemmingsOut := 0;
  SpawnedDead := Level.Info.ZombieGhostCount;
  LemmingsIn := 0;
  LemmingsRemoved := 0;
  fHighlightLemming := nil;
  DelayEndFrames := 0;
  fRightMouseButtonHeldDown := False;
  fShiftButtonHeldDown := False;
  fAltButtonHeldDown := False;
  fCtrlButtonHeldDown := False;
  fCurrentIteration := 0;
  fLastCueSoundIteration := 0;
  fClockFrame := 0;
  fFading := False;
  EntriesOpened := False;
  Entries.Clear;


  SetLength(DosEntryTable, 0);

  fSlowingDownReleaseRate := False;
  fSpeedingUpReleaseRate := False;
  fPaused := False;
  UserSetNuking := False;
  ExploderAssignInProgress := False;
  Index_LemmingToBeNuked := 0;
  fCurrentCursor := 0;
  fParticleFinishTimer := 0;
  LemmingList.Clear;
  LastNPLemming := nil;
  SoundMgr.ClearQueue;
  if Level.Info.LevelID <> fReplayManager.LevelID then //not aReplay then
  begin
    fReplayManager.Clear(true);
    fReplayManager.LevelName := Level.Info.Title;
    fReplayManager.LevelAuthor := Level.Info.Author;
    fReplayManager.LevelGame := Trim(fGameParams.SysDat.PackName);
    fReplayManager.LevelRank := Trim(fGameParams.Info.dSectionName);
    fReplayManager.LevelPosition := fGameParams.Info.dLevel+1;
    fReplayManager.LevelID := Level.Info.LevelID;
    fReplaying := false;
  end else
    fReplaying := true;

  fExplodingGraphics := False;


  with Level.Info do
  begin
    MaxNumLemmings := LemmingsCount;

    currReleaseRate    := ReleaseRate  ;
    lastReleaseRate    := ReleaseRate  ;

    // Set available skills
    CurrSkillCount[baDigging]      := DiggerCount;
    CurrSkillCount[baClimbing]     := ClimberCount;
    CurrSkillCount[baBuilding]     := BuilderCount;
    CurrSkillCount[baBashing]      := BasherCount;
    CurrSkillCount[baMining]       := MinerCount;
    CurrSkillCount[baFloating]     := FloaterCount;
    CurrSkillCount[baBlocking]     := BlockerCount;
    CurrSkillCount[baExploding]    := BomberCount;
    CurrSkillCount[baToWalking]    := WalkerCount;
    CurrSkillCount[baPlatforming]  := PlatformerCount;
    CurrSkillCount[baStacking]     := StackerCount;
    CurrSkillCount[baStoning]      := StonerCount;
    CurrSkillCount[baSwimming]     := SwimmerCount;
    CurrSkillCount[baGliding]      := GliderCount;
    CurrSkillCount[baFixing]       := MechanicCount;
    CurrSkillCount[baCloning]      := ClonerCount;
    // Initialize used skills
    for i := 0 to 15 do
      UsedSkillCount[ActionListArray[i]] := 0;
  end;

  LowestReleaseRate := CurrReleaseRate;
  HighestReleaseRate := CurrReleaseRate;

  fLastRecordedRR := CurrReleaseRate;

  NextLemmingCountDown := 20;

  numEntries := 0;
  ButtonsRemain := 0;

  // Create the list of interactive objects
  ObjectInfos.Clear;
  fRenderer.CreateInteractiveObjectList(ObjectInfos);

  // SetObjectInfos;

  with Level do
  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos[i];

    // Update number of hatches
    if Inf.TriggerEffect = DOM_WINDOW then
    begin
      SetLength(dosEntryTable, numEntries + 1);
      dosentrytable[numEntries] := i;
      Inc(numEntries);
    end;

    // Update number of buttons
    if Inf.TriggerEffect = DOM_BUTTON then
      Inc(ButtonsRemain);
  end;

  // can't fix it in the previous loop tidily, so this will fix the locked exit
  // displaying as locked when it isn't issue on levels with no buttons
  if ButtonsRemain = 0 then
    for i := 0 to ObjectInfos.Count-1 do
      if (ObjectInfos[i].TriggerEffect = DOM_LOCKEXIT) then
        ObjectInfos[i].CurrentFrame := 0;

  ApplyLevelEntryOrder;
  InitializeBrickColors(Renderer.Theme.Colors[MASK_COLOR]);
  InitializeObjectMap;
  InitializeBlockerMap;
  InitializeMiniMap;
  ApplyAutoSteel;

  //ShowMessage(IntToStr(Level.Info.LevelID));

  fTargetBitmap.SetSize(PhysicsMap.Width, PhysicsMap.Height);
  DrawAnimatedObjects; // first draw needed

  //if Entries.Count = 0 then raise exception.Create('no entries');

  with InfoPainter do
  begin
    UpdateTimeLimit;
    UpdateLemmingCounts;
    SetReplayMark(Replaying);
    SetTimeLimit(Level.Info.TimeLimit < 6000);
  end;

  InfoPainter.DrawButtonSelector(fSelectedSkill, False);
  // force update
  fSelectedSkill := spbNone;
  i2 := -1;
  i3 := 0;
  for i := 0 to 7 do
    fActiveSkills[i] := spbNone;
  for i := 0 to 15 do
  begin
    if Level.Info.SkillTypes and Trunc(IntPower(2, (15-i))) <> 0 then
    begin
      if i2 = -1 then i2 := i;
      Self.fActiveSkills[i3] := TSkillPanelButton(i);
      inc(i3);
    end;
  end;
  SetSelectedSkill(TSkillPanelButton(i2), True); // default

  UpdateAllSkillCounts;

  AddPreplacedLemming;

  fFallLimit := MAX_FALLDISTANCE;

  fTalismanReceived := false;

  //Renderer.DrawLevel(fTargetBitmap);

  SoundMgr.ClearQueue;

  Playing := True;
end;

procedure TLemmingGame.SetObjectInfos;
var
  i: Integer;
  Inf: TInteractiveObjectInfo;
  MO: TMetaObjectInterface;
begin
  ObjectInfos.Clear;

  for i := 0 to Level.InteractiveObjects.Count - 1 do
  begin
    MO := fRenderer.FindMetaObject(Level.InteractiveObjects[i]);
    Inf := TInteractiveObjectInfo.Create(Level.InteractiveObjects[i], MO);

    ObjectInfos.Add(Inf);

    // Check whether trigger area intersects the level area
    if    (Inf.TriggerRect.Top > Level.Info.Height)
       or (Inf.TriggerRect.Bottom < 0)
       or (Inf.TriggerRect.Right < 0)
       or (Inf.TriggerRect.Left > Level.Info.Width) then
      Inf.IsDisabled := True;
  end;

  // Get ReceiverID for all Teleporters
  ObjectInfos.FindReceiverID;
end;




procedure TLemmingGame.AddPreplacedLemming;
var
  L: TLemming;
  Lem: TPreplacedLemming;
  i: Integer;
begin
  for i := 0 to fGameParams.Level.PreplacedLemmings.Count-1 do
  begin
    Lem := fGameParams.Level.PreplacedLemmings[i];
    L := TLemming.Create;
    with L do
    begin
      LemIndex := LemmingList.Add(L);
      SetFromPreplaced(Lem);

      if not HasPixelAt(L.LemX, L.LemY) then
        Transition(L, baFalling)
      else if Lem.IsBlocker then
        Transition(L, baBlocking)
      else
        Transition(L, baWalking);

      if Lem.IsZombie then
      begin
        RemoveLemming(L, RM_ZOMBIE);
        Dec(SpawnedDead);
      end;
      
      if LemIndex = fHighlightLemmingID then fHighlightLemming := L;
    end;
    Inc(LemmingsReleased);
    Inc(LemmingsOut);
  end;
end;

procedure TLemmingGame.CombineBuilderPixels(F: TColor32; var B: TColor32; M: TColor32);
{-------------------------------------------------------------------------------
  This trusts the CurrentlyDrawnLemming variable.
  Therefore it has to stay here instead of being moved to LemRecolorSprites.pas
-------------------------------------------------------------------------------}
begin
  if F = BrickPixelColor then
    B := BrickPixelColors[12 - fCurrentlyDrawnLemming.LemNumberOfBricksLeft]
  else if F <> 0 then
    B := F;
end;

procedure TLemmingGame.CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32; E: TColor32);
// copy masks to world
begin
  if (F <> 0) and (B and E = 0) then B := B and not PM_TERRAIN;
end;

procedure TLemmingGame.CombineMaskPixelsLeft(F: TColor32; var B: TColor32; M: TColor32);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYRIGHT or PM_ONEWAYDOWN;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsRight(F: TColor32; var B: TColor32; M: TColor32);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYLEFT or PM_ONEWAYDOWN;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsDownLeft(F: TColor32; var B: TColor32; M: TColor32);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYRIGHT;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsDownRight(F: TColor32; var B: TColor32; M: TColor32);
var
  E: TColor32;
begin
  E := PM_STEEL or PM_ONEWAYLEFT;
  CombineMaskPixels(F, B, M, E);
end;

procedure TLemmingGame.CombineMaskPixelsNeutral(F: TColor32; var B: TColor32; M: TColor32);
var
  E: TColor32;
begin
  E := PM_STEEL;
  CombineMaskPixels(F, B, M, E);
end;



procedure TLemmingGame.CombineNoOverwriteStoner(F: TColor32; var B: TColor32; M: TColor32);
// copy Stoner to world
begin
  if (B and PM_SOLID = 0) and (F <> 0) then B := (B or PM_SOLID);
end;



function TLemmingGame.HasPixelAt(X, Y: Integer): Boolean;
{-------------------------------------------------------------------------------
  Read value from world.
  The function returns True when the value at (x, y) is terrain
-------------------------------------------------------------------------------}
begin
  Result := (Y < 0);
  If Result = False then
    Result := (Y < PhysicsMap.Height) and (X >= 0) and (X < PhysicsMap.Width)
                   and (PhysicsMap.Pixel[X, Y] and PM_SOLID <> 0);

  (*// Code for solid sides!
  with World do
  begin
    Result := not ((X >= 0) and (Y >= 0) and (X < Width));
    if Result = False then Result := (Y < Height) and (Pixel[X, Y] and ALPHA_TERRAIN <> 0);
  end;  *)
end;


procedure TLemmingGame.RemovePixelAt(X, Y: Integer);
begin
  PhysicsMap.PixelS[X, Y] := PhysicsMap.PixelS[X, Y] and not PM_TERRAIN;
end;

procedure TLemmingGame.MoveLemToReceivePoint(L: TLemming; oid: Byte);
var
  Inf, Inf2: TInteractiveObjectInfo;
begin
  Inf := ObjectInfos[oid];
  Assert(Inf.ReceiverId <> 65535, 'Telerporter used without receiver');
  Inf2 := ObjectInfos[Inf.ReceiverId];

  if Inf.IsFlipPhysics then TurnAround(L);

  // Mirror trigger area, if Upside-Down Flag is valid for exactly one object
  if Inf.IsUpsideDown xor Inf2.IsUpsideDown then
    L.LemY := (Inf2.TriggerRect.Bottom - 1) - (L.LemY - Inf.TriggerRect.Top)
  else
    L.LemY := Inf2.TriggerRect.Top + (L.LemY - Inf.TriggerRect.Top);

  // Mirror trigger area, if FlipLem Flag is valid for exactly one object
  // The FlipImage Flag is already taken care of when computing trigger areas.
  if Inf.IsFlipPhysics xor Inf2.IsFlipPhysics then
    L.LemX := (Inf2.TriggerRect.Right - 1) - (L.LemX - Inf.TriggerRect.Left)
  else
    L.LemX := Inf2.TriggerRect.Left + (L.LemX - Inf.TriggerRect.Left);
end;


function TLemmingGame.ReadObjectMap(X, Y: Integer): Word;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := (ObjectMap.Value[2*X, Y] shl 8) + ObjectMap.Value[2*X + 1, Y]
  else
    Result := DOM_NOOBJECT; // whoops, important
end;

function TLemmingGame.ReadObjectMapType(X, Y: Integer): Byte;
var
  ObjID: Word;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
  begin
    ObjID := ReadObjectMap(X, Y);
    if ObjID = DOM_NOOBJECT then
      Result := DOM_NONE
    else
      Result := ObjectInfos[ObjID].TriggerEffect;
  end
  else
    Result := DOM_NONE; // whoops, important
end;

function TLemmingGame.ReadBlockerMap(X, Y: Integer): Byte;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := BlockerMap.Value[X, Y]
  else
    Result := DOM_NONE; // whoops, important
end;

function TLemmingGame.ReadZombieMap(X, Y: Integer): Byte;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := ZombieMap.Value[X, Y]
  else
    Result := DOM_NONE; // whoops, important
end;

{function TLemmingGame.ReadSpecialMap(X, Y: Integer): Byte;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := SpecialMap.Value[X, Y]
  else
    Result := DOM_NONE; // whoops, important

  if X < 0 then Result := DOM_NONE; // Old version: DOM_STEEL;
  if X >= PhysicsMap.Width then Result := DOM_NONE; // Old version: DOM_STEEL;
  if Y < 0 then Result := DOM_STEEL;
end;}

function TLemmingGame.ReadWaterMap(X, Y: Integer): Byte;
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    Result := WaterMap.Value[X, Y]
  else
    Result := DOM_NONE; // whoops, important
end;

procedure TLemmingGame.WriteBlockerMap(X, Y: Integer; aValue: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    BlockerMap.Value[X, Y] := aValue;
end;

procedure TLemmingGame.WriteZombieMap(X, Y: Integer; aValue: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    ZombieMap.Value[X, Y] := ZombieMap.Value[X, Y] or aValue
end;

procedure TLemmingGame.WriteWaterMap(X, Y: Integer; aValue: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    WaterMap.Value[X, Y] := aValue;
end;


{procedure TLemmingGame.WriteSpecialMap(X, Y: Integer; aValue: Byte);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
    SpecialMap.Value[X, Y] := aValue;
end;}


procedure TLemmingGame.WriteObjectMap(X, Y: Integer; aValue: Word; Advance: Boolean = false);
begin
  if (X >= 0) and (X < PhysicsMap.Width) and (Y >= 0) and (Y < PhysicsMap.Height) then
  begin
    ObjectMap.Value[2*X, Y] := aValue div 256;
    ObjectMap.Value[2*X + 1, Y] := aValue mod 256;
  end;
end;


procedure TLemmingGame.RestoreMap;
var
  i: Integer;
begin
  BlockerMap.Clear(0);
  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i].LemHasBlockerField and not LemmingList[i].LemRemoved then
      SetBlockerField(LemmingList[i]);
end;

procedure TLemmingGame.SetBlockerField(L: TLemming);
var
  X, Y, Step: Integer;
begin
  X := L.LemX - 6;
  if L.LemDx = 1 then Inc(X);

  for Step := 0 to 11 do
    for Y := L.LemY - 6 to L.LemY + 4 do
      case Step of
        0..3: WriteBlockerMap(X + Step, Y, DOM_FORCELEFT);
        4..7: WriteBlockerMap(X + Step, Y, DOM_BLOCKER);
        8..11: WriteBlockerMap(X + Step, Y, DOM_FORCERIGHT);
      end;
(*
  with L do
  begin
    for X := LemX - 5 to LemX - 3 do
    for Y := LemY - 6 to LemY + 4 do
      WriteBlockerMap(X, Y, DOM_FORCELEFT);
    for X := LemX - 2 to LemX + 2 do
      for Y := LemY - 6 to LemY + 4 do
        WriteBlockerMap(X, Y, DOM_BLOCKER);
    for X := LemX + 3 to LemX + 5 do
      for Y := LemY - 6 to LemY + 4 do
        WriteBlockerMap(X, Y, DOM_FORCERIGHT);

    for Y := LemY - 6 to LemY + 4 do
      if L.LemRTL then
        WriteBlockerMap(LemX-6, Y, DOM_FORCELEFT)
      else
        WriteBlockerMap(LemX+6, Y, DOM_FORCERIGHT);

  end;                                                *)
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
begin
  // Check only the vertices of the new blocker field
  Result :=    HasTriggerAt(L.LemX - 5, L.LemY - 6, trBlocker)
            or HasTriggerAt(L.LemX + 5, L.LemY - 6, trBlocker)
            or HasTriggerAt(L.LemX - 5, L.LemY + 4, trBlocker)
            or HasTriggerAt(L.LemX + 5, L.LemY + 4, trBlocker);
end;


procedure TLemmingGame.Transition(L: TLemming; NewAction: TBasicLemmingAction; DoTurn: Boolean = False);
{-------------------------------------------------------------------------------
  Handling of a transition and/or turnaround
-------------------------------------------------------------------------------}
var
  i: Integer;
  TempMetaAnim: TMetaLemmingAnimation;
begin
  if DoTurn then TurnAround(L);

  //Swith from baToWalking to baWalking
  if NewAction = baToWalking then NewAction := baWalking;

  if L.LemHasBlockerField and not (NewAction in [baOhNoing, baStoning]) then
  begin
    L.LemHasBlockerField := False;
    RestoreMap;
  end;

  // Transition to faller instead walker, if no pixel below lemming
  if (not HasPixelAt(L.LemX, L.LemY)) and (NewAction = baWalking) then
    NewAction := baFalling;

  // Should not happen, except for assigning walkers to walkers
  if L.LemAction = NewAction then Exit;

  // Set initial fall heights according to previous skill
  if (NewAction = baFalling) then
  begin
    L.LemFallen := 1;
    if L.LemAction in [baWalking, baBashing] then L.LemFallen := 3;
    if L.LemAction in [baMining, baDigging] then L.LemFallen := 0;
    L.LemTrueFallen := L.LemFallen;
  end;

  // Change Action
  L.LemAction := NewAction;
  L.LemFrame := 0;
  L.LemEndOfAnimation := False;
  L.LemNumberOfBricksLeft := 0;

  // New animation
  i := AnimationIndices[NewAction, (L.LemDx = -1)];
  TempMetaAnim := Style.AnimationSet.MetaLemmingAnimations[i];
  L.LemMaxFrame := TempMetaAnim.FrameCount - 1;
  L.LemAnimationType := TempMetaAnim.AnimationType;
  L.FrameTopDy  := TempMetaAnim.FootY; // ccexplore compatible
  L.FrameLeftDx := TempMetaAnim.FootX; // ccexplore compatible

  // some things to do when entering state
  case L.LemAction of
    baJumping    : L.LemJumped := 0;
    baClimbing   : L.LemIsNewClimbing := True;
    baSplatting  : begin
                     L.LemExplosionTimer := 0;
                     CueSoundEffect(SFX_SPLAT, L.Position)
                   end;
    baBlocking   : begin
                     L.LemHasBlockerField := True;
                     SetBlockerField(L);
                   end;
    baExiting    : begin
                     L.LemExplosionTimer := 0;
                     CueSoundEffect(SFX_YIPPEE, L.Position);
                   end;
    baDigging    : L.LemIsNewDigger := True;
    baBuilding   : L.LemNumberOfBricksLeft := 12;
    baPlatforming: L.LemNumberOfBricksLeft := 12;
    baStacking   : L.LemNumberOfBricksLeft := 8;
    baOhnoing    : CueSoundEffect(SFX_OHNO, L.Position);
    baStoning    : CueSoundEffect(SFX_OHNO, L.Position);
    baExploding  : begin
                     if fHighlightLemming = L then fHighlightLemming := nil;
                     CueSoundEffect(SFX_EXPLOSION, L.Position);
                   end;
    baStoneFinish: begin
                     if fHighlightLemming = L then fHighlightLemming := nil;
                     CueSoundEffect(SFX_EXPLOSION, L.Position);
                   end;
    baSwimming   : begin // If possible, float up 4 pixels when starting
                     i := 0;
                     while (i < 4) and HasTriggerAt(L.LemX, L.LemY - i - 1, trWater)
                                   and not HasPixelAt(L.LemX, L.LemY - i - 1) do
                       Inc(i);
                     Dec(L.LemY, i);
                   end;
    baFixing     : L.LemMechanicFrames := 42;

  end;
end;

procedure TLemmingGame.TurnAround(L: TLemming);
// we assume that the mirrored animations at least have the same framecount
var
  i: Integer;
  TempMetaAnim: TMetaLemmingAnimation;
begin
  with L do
  begin
    LemDX := -LemDX;
    i := AnimationIndices[LemAction, (LemDx = -1)];
    TempMetaAnim := Style.AnimationSet.MetaLemmingAnimations[i];
    LemMaxFrame := TempMetaAnim.FrameCount - 1;
    LemAnimationType := TempMetaAnim.AnimationType;
    FrameTopDy  := -TempMetaAnim.FootY; // ccexplore compatible
    FrameLeftDx := -TempMetaAnim.FootX; // ccexplore compatible
  end;
end;


function TLemmingGame.UpdateExplosionTimer(L: TLemming): Boolean;
begin
  Result := False;

  Dec(L.LemExplosionTimer);
  if L.LemExplosionTimer = 0 then
  begin
    if L.LemAction in [baVaporizing, baDrowning, baFloating, baGliding, baFalling, baSwimming] then
    begin
      if L.LemTimerToStone then
        Transition(L, baStoneFinish)
      else
        Transition(L, baExploding);
      end
    else begin
      if L.LemTimerToStone then
        Transition(L, baStoning)
      else
        Transition(L, baOhnoing);
    end;
    Result := True;
  end;
end;


procedure TLemmingGame.CheckForGameFinished;
begin
  if fGameFinished then
    Exit;

  if (TimePlay <= 0) and not ((moTimerMode in fGameParams.MiscOptions) or (fGameParams.Level.Info.TimeLimit > 5999)) then
  begin
    fGameFinished := True;
    GameResultRec.gTimeIsUp := True;
    Finish;
    Exit;
  end;

  if fParticleFinishTimer > 0 then
    Exit;

  if (LemmingsIn >= MaxNumLemmings + LemmingsCloned) and (DelayEndFrames = 0) then
  begin
    Finish;
    Exit;
  end;

  if (LemmingsRemoved >= MaxNumLemmings + LemmingsCloned) and (DelayEndFrames = 0) then
  begin
    Finish;
    Exit;
  end;

  if UserSetNuking and (LemmingsOut = 0) and (DelayEndFrames = 0) then
  begin
    Finish;
    Exit;
  end;

end;

procedure TLemmingGame.InitializeBlockerMap; //ZombieMap too
begin
  BlockerMap.SetSize(Level.Info.Width, Level.Info.Height);
  BlockerMap.Clear(DOM_NONE);

  ZombieMap.SetSize(Level.Info.Width, Level.Info.Height);
  ZombieMap.Clear(0);
end;

procedure TLemmingGame.ApplyLevelEntryOrder;
var
  i, oid, eid: Integer;
begin
  eid := 0;
  for i := 0 to Length(Level.Info.WindowOrder)-1 do
  begin
    oid := Level.Info.WindowOrder[i];
    if not (ObjectInfos[oid].TriggerEffect = DOM_WINDOW) then Continue;
    SetLength(DosEntryTable, eid+1);
    DosEntryTable[eid] := oid;
    Inc(eid);
  end;
end;

procedure TLemmingGame.InitializeObjectMap;
{-------------------------------------------------------------------------------

  In one of the previous e-mails I said the DOS Lemmings object map has an
  x range from -16 to 1647 and a y range from 0 to 159.
  I think to provide better safety margins, let's extend the y range a bit,
  say from -16 to 175 (I added 16 in both directions).
  This is probably slightly on the excessive side but memory is cheap these days,
  and you can always reduce the x range since DOS Lemmings
  doesn't let you scroll to anywhere near x=1647
  (I think the max visible x range is like 1580 or something).

  Nepster: The maps now have the very same size as the level itself.

-------------------------------------------------------------------------------}
var
  x, y: Integer;
  i: Integer;
  S: TSteel;
  V: Byte;
begin

  ObjectMap.SetSize(2*Level.Info.Width, Level.Info.Height);
  ObjectMap.Clear(255);

  //SpecialMap.SetSize(Level.Info.Width, Level.Info.Height);
  //SpecialMap.Clear(DOM_NONE);

  WaterMap.SetSize(Level.Info.Width, Level.Info.Height);
  WaterMap.Clear(DOM_NONE);

  for i := 0 to ObjectInfos.Count - 1 do
  begin
    V := ObjectInfos[i].TriggerEffect;
    if not (V in [DOM_NONE, DOM_LEMMING, DOM_RECEIVER, DOM_WINDOW, DOM_HINT, DOM_BACKGROUND]) then
    begin
      for Y := ObjectInfos[i].TriggerRect.Top to ObjectInfos[i].TriggerRect.Bottom - 1 do
      for X := ObjectInfos[i].TriggerRect.Left to ObjectInfos[i].TriggerRect.Right - 1 do
      begin
        {if (V in [DOM_STEEL, DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN]) then
        begin
          if (V = DOM_STEEL) or (PhysicsMap.PixelS[X, Y] and PM_ONEWAY <> 0) then
            WriteSpecialMap(X, Y, V)
        end
        else} if V = DOM_WATER then
          WriteWaterMap(X, Y, V)
        else if V = DOM_BLOCKER then
          WriteBlockerMap(X, Y, V)
        else
          WriteObjectMap(X, Y, i); // traps --> object_id
      end;
    end;
  end; // for i


  // map steel
  (*if ((Level.Info.LevelOptions and 4) = 0)
     and (fGameParams.SysDat.Options and 64 = 0) then
  begin
    with Level.Steels, HackedList do
    begin
      for i := 0 to Count - 1 do
      begin
        S := List^[i];
        with S do
          for y := Top to Top + Height - 1 do //SteelY to SteelY + SteelHeight - 1 do
          for x := Left to Left + Width - 1 do //SteelX to SteelX + SteelWidth - 1 do
            case S.fType of
              0: WriteSpecialMap(x, y, DOM_STEEL);
              // 1: WriteSpecialMap(x, y, DOM_EXIT);  // no longer needed
              2: WriteSpecialMap(x, y, DOM_ONEWAYLEFT);
              3: WriteSpecialMap(x, y, DOM_ONEWAYRIGHT);
              4: WriteSpecialMap(x, y, DOM_ONEWAYDOWN);
            end;

      end;
    end;
  end;*)
end;


procedure TLemmingGame.ApplyAutoSteel;
var
  X, Y: Integer;
  DoAutoSteel : Boolean;
begin
  // The renderer should have already handled this now

  (*DoAutoSteel := (((Level.Info.LevelOptions and 2) = 2) or
          (fGameParams.SysDat.Options and 64 <> 0));

  with PhysicsMap do
  begin
    for x := 0 to (Width-1) do
    for y := 0 to (Height-1) do
    begin
      if DoAutoSteel then
      begin
        if (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height)
                    and (Pixel[X, Y] and PM_STEEL <> 0)
                    and (ReadSpecialMap(X, Y) = DOM_NONE) then
          WriteSpecialMap(X, Y, DOM_STEEL);
      end;

      if (ReadSpecialMap(X, Y) = DOM_STEEL) and (PhysicsMap.Pixel[X, Y] and PM_SOLID = 0) then
        WriteSpecialMap(X, Y, DOM_NONE);

      if (ReadSpecialMap(X, Y) = DOM_STEEL) then
        PhysicsMap.Pixel[X, Y] := PhysicsMap.Pixel[X, Y] and not PM_ONEWAY;

      if     (ReadSpecialMap(X, Y) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN])
         and (PhysicsMap.Pixel[X, Y] and PM_ONEWAY = 0) then
        WriteSpecialMap(X, Y, DOM_NONE);

    end;
  end;*)
end;


function TLemmingGame.AssignNewSkill(Skill: TBasicLemmingAction;
                                     IsHighlight: Boolean = False): Boolean;
var
  L: TLemming;
begin
  Result := False;

  // Just to be safe, though this should always return in fLemSelected
  GetPriorityLemming(L, Skill, CursorPoint, IsHighlight);

  if not Assigned(L) then Exit;

  Result := DoSkillAssignment(L, Skill);

  if Result then CueSoundEffect(SFX_ASSIGN_SKILL, L.Position);
end;

{
procedure TLemmingGame.OnAssignSkill(Lemming1: TLemming; aSkill: TBasicLemmingAction);
begin
  // This function only was used for gimmicks, but it might be useful so let's leave it
  // here as an empty function just in case.
end;
}

function TLemmingGame.DoSkillAssignment(L: TLemming; NewSkill: TBasicLemmingAction): Boolean;
begin

  Result := False;

  // We check first, whether the skill is available at all
  if not CheckSkillAvailable(NewSkill) then Exit;

  // Have to ask namida what fCheckWhichLemmingOnly actually does!!
  if fCheckWhichLemmingOnly then WhichLemming := L
  else
  begin
    UpdateSkillCount(NewSkill);
    RecordSkillAssignment(L, NewSkill);

    // Get starting position for stacker
    if (Newskill = baStacking) then L.LemStackLow := not HasPixelAt(L.LemX + L.LemDx, L.LemY);

    // Important! If a builder just placed a brick and part of the previous brick
    // got removed, he should not fall if turned into a walker!
    if     (NewSkill = baToWalking) and (L.LemAction = baBuilding)
       and HasPixelAt(L.LemX, L.LemY - 1) and not HasPixelAt(L.LemX + L.LemDx, L.LemY) then
      L.LemY := L.LemY - 1;

    // Turn around walking lem, if assigned a walker
    if (NewSkill = baToWalking) and (L.LemAction = baWalking) then
    begin
      TurnAround(L);

      // Special treatment if in one-way-field facing the wrong direction
      // see http://www.lemmingsforums.net/index.php?topic=2640.0
      if    (HasTriggerAt(L.LemX, L.LemY, trForceRight) and (L.LemDx = -1))
         or (HasTriggerAt(L.LemX, L.LemY, trForceLeft) and (L.LemDx = 1)) then
      begin
        // Go one back to cancel the Inc(L.LemX, L.LemDx) in HandleWalking
        // unless the Lem will fall down (which is handles already in Transition)
        if HasPixelAt(L.LemX, L.LemY) then Dec(L.LemX, L.LemDx);
      end;
    end;

    // Special behavior of permament skills.
    if (NewSkill = baClimbing) then L.LemIsClimber := True
    else if (NewSkill = baFloating) then L.LemIsFloater := True
    else if (NewSkill = baGliding) then L.LemIsGlider := True
    else if (NewSkill = baFixing) then L.LemIsMechanic := True
    else if (NewSkill = baSwimming) then
    begin
      L.LemIsSwimmer := True;
      if L.LemAction = baDrowning then Transition(L, baSwimming);
    end
    else if (NewSkill = baExploding) then
    begin
      L.LemExplosionTimer := 1;
      L.LemTimerToStone := False;
    end
    else if (NewSkill = baStoning) then
    begin
      L.LemExplosionTimer := 1;
      L.LemTimerToStone := True;
    end
    else if (NewSkill = baCloning) then
    begin
      Inc(LemmingsCloned);
      GenerateClonedLem(L);
    end
    else Transition(L, NewSkill);

    Result := True;

    // OnAssignSkill currently does nothing. So unless this changes,
    // the following line stays as a comment:
    // if not fFreezeSkillCount then OnAssignSkill(L, NewSkill);
  end;
end;


procedure TLemmingGame.GenerateClonedLem(L: TLemming);
var
  NewL: TLemming;
begin
  Assert(not L.LemIsZombie, 'cloner assigned to zombie');

  NewL := TLemming.Create;
  NewL.Assign(L);
  NewL.LemIndex := LemmingList.Count;
  LemmingList.Add(NewL);
  TurnAround(NewL);
  NewL.LemUsedSkillCount := 0;
  Inc(LemmingsOut);

  // Avoid moving into terrain, see http://www.lemmingsforums.net/index.php?topic=2575.0
  if NewL.LemAction = baMining then
  begin
    if NewL.LemFrame = 2 then
      ApplyMinerMask(NewL, 1, 0, 0)
    else if (NewL.LemFrame >= 3) and (NewL.LemFrame < 15) then
      ApplyMinerMask(NewL, 1, -2*NewL.LemDx, -1);
  end
  // Required for turned builders not to walk into air
  // For platformers, see http://www.lemmingsforums.net/index.php?topic=2530.0
  else if (NewL.LemAction in [baBuilding, baPlatforming]) and (NewL.LemFrame >= 9) then
    LayBrick(NewL);
end;


function TLemmingGame.GetPriorityLemming(out PriorityLem: TLemming;
                                          NewSkillOrig: TBasicLemmingAction;
                                          MousePos: TPoint;
                                          IsHighlight: Boolean = False): Integer;
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

  function LemIsInCursor(L: TLemming; MousePos: TPoint): Boolean;
  var
    X, Y: Integer;
  begin
    X := L.LemX - 8;
    Y := L.LemY - 10;
    Result := PtInRect(Rect(X, Y, X + 13, Y + 13), MousePos);
  end;


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
      Perm    : Result :=     (L.LemIsClimber or L.LemIsSwimmer or L.LemIsFloater
                                    or L.LemIsGlider or L.LemIsMechanic);
      NonPerm : Result :=     (L.LemAction in [baBashing, baMining, baDigging, baBuilding,
                                               baPlatforming, baStacking, baBlocking]);
      Walk    : Result :=     (L.LemAction in [baWalking, baJumping]);
      NonWalk : Result := not (L.LemAction in [baWalking, baJumping]);
    end;
  end;

begin
  PriorityLem := nil;
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
    L := LemmingList.List^[i];

    // Check if we only look for highlighted Lems
    if IsHighlight and not (L = fHighlightLemming) then Continue;
    // Does Lemming exist
    if L.LemRemoved or L.LemTeleporting then Continue;
    // Is the Lemming a Zombie (remove unless we haven't yet had any lem under the cursor)
    if L.LemIsZombie and Assigned(PriorityLem) then Continue;
    // Is Lemming inside cursor (only check if we are not using Hightlightning!)
    if (not LemIsInCursor(L, MousePos)) and (not IsHighlight) then Continue;
    // Directional select
    if (fSelectDx <> 0) and (fSelectDx <> L.LemDx) then Continue;
    // Select unassigned lemming
    if ShiftButtonHeldDown and (L.LemUsedSkillCount > 0) then Continue;
    // Select only walkers
    if RightMouseButtonHeldDown and (L.LemAction <> baWalking) then Continue;

    // Increase number of lemmings in cursor (if not a zombie)
    if not L.LemIsZombie then Inc(NumLemInCursor);

    // Determine priority class of current lemming
    if ShiftButtonHeldDown or RightMouseButtonHeldDown then
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
    if L.LemIsZombie then CurPriorityBox := 9;

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

function TLemmingGame.MayAssignWalker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBlocking, baPlatforming, baBuilding,
               baStacking, baBashing, baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignClimber(L: TLemming): Boolean;
const
  ActionSet = [baOhnoing, baStoning, baExploding, baStoneFinish, baDrowning,
               baVaporizing, baSplatting, baExiting];
begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsClimber;
end;

function TLemmingGame.MayAssignFloaterGlider(L: TLemming): Boolean;
const
  ActionSet = [baOhnoing, baStoning, baExploding, baStoneFinish, baDrowning,
               baVaporizing, baSplatting, baExiting];
begin
  Result := (not (L.LemAction in ActionSet)) and not (L.LemIsFloater or L.LemIsGlider);
end;

function TLemmingGame.MayAssignSwimmer(L: TLemming): Boolean;
const
  ActionSet = [baOhnoing, baStoning, baExploding, baStoneFinish, baVaporizing,
               baSplatting, baExiting];   // Does NOT contain baDrowning!
begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsSwimmer;
end;

function TLemmingGame.MayAssignMechanic(L: TLemming): Boolean;
const
  ActionSet = [baOhnoing, baStoning, baExploding, baStoneFinish, baDrowning,
               baVaporizing, baSplatting, baExiting];
begin
  Result := (not (L.LemAction in ActionSet)) and not L.LemIsMechanic;
end;

function TLemmingGame.MayAssignBlocker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking,
               baBashing, baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet) and not CheckForOverlappingField(L);
end;

function TLemmingGame.MayAssignExploderStoner(L: TLemming): Boolean;
const
  ActionSet = [baOhnoing, baStoning, baDrowning, baExploding, baStoneFinish,
               baVaporizing, baSplatting, baExiting];
begin
  Result := not (L.LemAction in ActionSet);
end;


function TLemmingGame.MayAssignBuilder(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baStacking, baBashing,
               baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet) and not (L.LemY <= 1);
end;

function TLemmingGame.MayAssignPlatformer(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBuilding, baStacking, baBashing,
               baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet) and LemCanPlatform(L);
end;

function TLemmingGame.MayAssignStacker(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baBashing,
               baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet);
end;

function TLemmingGame.MayAssignBasher(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking,
               baMining, baDigging];
begin
  Result := (L.LemAction in ActionSet)
            and not HasIndestructibleAt(L.LemX + 4 * L.LemDx, L.LemY - 5, L.LemDx, baBashing);
end;

function TLemmingGame.MayAssignMiner(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking,
               baBashing, baDigging];
begin
  Result := (L.LemAction in ActionSet)
            and not HasIndestructibleAt(L.LemX, L.LemY, L.LemDx, baMining)
end;

function TLemmingGame.MayAssignDigger(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking,
               baBashing, baMining];
begin
  Result := (L.LemAction in ActionSet) and not HasSteelAt(L.LemX, L.LemY);
end;

function TLemmingGame.MayAssignCloner(L: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking,
               baBashing, baMining, baDigging, baJumping, baFalling, baFloating,
               baSwimming, baGliding, baFixing];
begin
  Result := (L.LemAction in ActionSet);
end;


procedure TLemmingGame.InitializeMiniMap;
begin
  // The renderer handles most of the work here now.
  Minimap.SetSize(PhysicsMap.Width div 16, PhysicsMap.Height div 8);
  fRenderer.RenderMinimap(Minimap, LemmingList);
end;

function TLemmingGame.GetTrapSoundIndex(aDosSoundEffect: Integer): Integer;
begin
  if SFX_CUSTOM[aDosSoundEffect] <> 0 then
  begin
    Result := SFX_CUSTOM[aDosSoundEffect];
    Exit;
  end;
  case aDosSoundEffect of
    ose_RopeTrap             : Result := SFX_ROPETRAP;
    ose_SquishingTrap        : Result := SFX_SQUISHINGTRAP;
    ose_TenTonTrap           : Result := SFX_TENTON;
    ose_BearTrap             : Result := SFX_BEARTRAP;
    ose_ElectroTrap          : Result := SFX_ELECTROTRAP;
    ose_SpinningTrap         : Result := SFX_SPINNINGTRAP;
    ose_FireTrap             : Result := SFX_VAPORIZING;
    ose_Vaccuum              : Result := SFX_VACCUUM;
    ose_Slurp                : Result := SFX_SLURP;
    ose_Weed                 : Result := SFX_WEED;
  else
    Result := -1;
  end;
end;



procedure TLemmingGame.CheckTriggerArea(L: TLemming);
// For intermediate pixels, we call the trigger function according to trigger area
var
  CheckPosX, CheckPosY: array[0..10] of Integer; // List of positions where to check
  i: Integer;
  ObjectID: Word;
  AbortChecks: Boolean;

  procedure GetObjectCheckPositions(L: TLemming);
  // This function is a big mess! The intermediate checks are made according to:
  // http://www.lemmingsforums.net/index.php?topic=2604.7
  var
    CurrPosX, CurrPosY: Integer;
    n: Integer;

    procedure SaveCheckPos;
    begin
      CheckPosX[n] := CurrPosX;
      CheckPosY[n] := CurrPosY;
      Inc(n);
    end;

    procedure MoveHoizontal;
    begin
      while CurrPosX <> L.LemX do
      begin
        Inc(CurrPosX, sign(L.LemX - L.LemXOld));
        SaveCheckPos;
      end;
    end;

    procedure MoveVertical;
    begin
      while CurrPosY <> L.LemY do
      begin
        Inc(CurrPosY, sign(L.LemY - L.LemYOld));
        SaveCheckPos;
      end;
    end;

  begin
    n := 0;
    CurrPosX := L.LemXOld;
    CurrPosY := L.LemYOld;
    // no movement
    if (L.LemX = L.LemXOld) and (L.LemY = L.LemYOld) then
      SaveCheckPos

    // special treatment of miners!
    else if L.LemActionOld = baMining then
    begin
      // First move one pixel down, if Y-coordinate changed
      if L.LemYOld < L.LemY then
      begin
        Inc(CurrPosY);
        SaveCheckPos;
      end;
      MoveHoizontal;
      MoveVertical;
    end

    // lem moves up or is faller; exception is made for builders!
    else if ((L.LemY < L.LemYOld) or (L.LemAction = baFalling)) and not (L.LemActionOld = baBuilding) then
    begin
      MoveHoizontal;
      MoveVertical;
    end

    // lem moves down (or straight) and is no faller; alternatively lem is a builder!
    else
    begin
      MoveVertical;
      MoveHoizontal;
    end;
  end;

begin
  // special treatment for blockers: Check only for (locked) exit
  if L.LemAction = baBlocking then
  begin
    if HasTriggerAt(L.LemX, L.LemY, trExit) then HandleExit(L, False);
    Exit;
  end;

  // Get positions to check for trigger areas
  GetObjectCheckPositions(L);

  // Now move through the values in CheckPosX/Y and check for trigger areas
  i := -1;
  AbortChecks := False;
  repeat
    Inc(i);
    // Check for interactive objects

    if HasTriggerAt(CheckPosX[i], CheckPosY[i], trTrap) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trTrap);
      if ObjectID <> 65535 then
        if ObjectInfos[ObjectID].TriggerEffect = DOM_TRAP then
          AbortChecks := HandleTrap(L, ObjectID)
        else
          AbortChecks := HandleTrapOnce(L, ObjectID);
    end
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trAnimation) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trAnimation);
      if ObjectID <> 65535 then
        AbortChecks := HandleObjAnimation(L, ObjectID);
    end
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trTeleport) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trTeleport);
      if ObjectID <> 65535 then
        if ObjectInfos[ObjectID].TriggerEffect = DOM_SINGLETELE then
          AbortChecks := HandleTelepSingle(L, ObjectID)
        else
          AbortChecks := HandleTeleport(L, ObjectID);
    end
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trPickup) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trPickup);
      if ObjectID <> 65535 then
        AbortChecks := HandlePickup(L, ObjectID)
    end
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trButton) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trButton);
      if ObjectID <> 65535 then
        AbortChecks := HandleButton(L, ObjectID)
    end
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trExit) then
      AbortChecks := HandleExit(L, False)
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trRadiation) then
      AbortChecks := HandleRadiation(L, False)
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trSlowfreeze) then
      AbortChecks := HandleRadiation(L, True)
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trFire) then
      AbortChecks := HandleFire(L)
    else if HasTriggerAt(CheckPosX[i], CheckPosY[i], trFlipper) then
    begin
      ObjectID := FindObjectID(CheckPosX[i], CheckPosY[i], trFlipper);
      if ObjectID <> 65535 then
        AbortChecks := HandleFlipper(L, ObjectID);
    end;
    
    // Check only for drowning here!
    if HasTriggerAt(CheckPosX[i], CheckPosY[i], trWater) then
      AbortChecks := HandleWaterDrown(L) or AbortChecks;

    // If the lem was required stop, move him there!
    if AbortChecks then
    begin
      L.LemX := CheckPosX[i];
      L.LemY := CheckPosY[i];
    end;

    // Set L.LemInFlipper correctly
    if not HasTriggerAt(CheckPosX[i], CheckPosY[i], trFlipper) then
      L.LemInFlipper := DOM_NOOBJECT;
  until [CheckPosX[i], CheckPosY[i]] = [L.LemX, L.LemY] (*or AbortChecks*);

  // Check for water to transition to swimmer only at final position
  if HasTriggerAt(L.LemX, L.LemY, trWater) then
    HandleWaterSwim(L);

  // Check for blocker fields and force-fields
  // but not for miners removing terrain, see http://www.lemmingsforums.net/index.php?topic=2710.0
  if (L.LemAction <> baMining) or not (L.LemFrame in [1, 2]) then
  begin
    if HasTriggerAt(L.LemX, L.LemY, trForceLeft) then
      HandleForceField(L, -1)
    else if HasTriggerAt(L.LemX, L.LemY, trForceRight) then
      HandleForceField(L, 1);
  end;
end;

function TLemmingGame.HasTriggerAt(X, Y: Integer; TriggerType: TTriggerTypes): Boolean;
// Checks whether the trigger area TriggerType occurs at position (X, Y)
begin
  Result := False;

  case TriggerType of
    trExit:       Result :=     (ReadObjectMapType(X, Y) = DOM_EXIT)
                            or ((ReadObjectMapType(X, Y) = DOM_LOCKEXIT) and (ButtonsRemain = 0));
    trForceLeft:  Result :=     (ReadObjectMapType(X, Y) = DOM_FORCELEFT)
                            or ((ReadBlockerMap(X, Y) = DOM_FORCELEFT) and not (ReadObjectMapType(X, Y) = DOM_FORCERIGHT));
    trForceRight: Result :=     (ReadObjectMapType(X, Y) = DOM_FORCERIGHT)
                            or ((ReadBlockerMap(X, Y) = DOM_FORCERIGHT) and not (ReadObjectMapType(X, Y) = DOM_FORCELEFT));
    trTrap:       Result :=     (ReadObjectMapType(X, Y) = DOM_TRAP)
                            or  (ReadObjectMapType(X, Y) = DOM_TRAPONCE);
    trWater:      Result :=     (ReadWaterMap(X, Y) = DOM_WATER);
    trFire:       Result :=     (ReadObjectMapType(X, Y) = DOM_FIRE);
    trOWLeft:     Result :=     (PhysicsMap.Pixel[X, Y] and PM_ONEWAYLEFT <> 0);
    trOWRight:    Result :=     (PhysicsMap.Pixel[X, Y] and PM_ONEWAYRIGHT <> 0);
    trOWDown:     Result :=     (PhysicsMap.Pixel[X, Y] and PM_ONEWAYDOWN <> 0);
    trSteel:      Result :=     (PhysicsMap.Pixel[X, Y] and PM_STEEL <> 0);
    trBlocker:    Result :=     (ReadBlockerMap(X, Y) = DOM_BLOCKER)
                            or  (ReadBlockerMap(X, Y) = DOM_FORCERIGHT)
                            or  (ReadBlockerMap(X, Y) = DOM_FORCELEFT);
    trTeleport:   Result :=     (ReadObjectMapType(X, Y) = DOM_SINGLETELE)
                            or  (ReadObjectMapType(X, Y) = DOM_TELEPORT);
    trPickup:     Result :=     (ReadObjectMapType(X, Y) = DOM_PICKUP);
    trButton:     Result :=     (ReadObjectMapType(X, Y) = DOM_BUTTON);
    trRadiation:  Result :=     (ReadObjectMapType(X, Y) = DOM_RADIATION);
    trSlowfreeze: Result :=     (ReadObjectMapType(X, Y) = DOM_SLOWFREEZE);
    trUpdraft:    Result :=     (ReadObjectMapType(X, Y) = DOM_UPDRAFT);
    trFlipper:    Result :=     (ReadObjectMapType(X, Y) = DOM_FLIPPER);
    trSplat:      Result :=     (ReadObjectMapType(X, Y) = DOM_SPLAT);
    trNoSplat:    Result :=     (ReadObjectMapType(X, Y) = DOM_NOSPLAT);
    trZombie:     Result :=     (ReadZombieMap(X, Y) and 1 <> 0);
    trAnimation:  Result :=     (ReadObjectMapType(X, Y) = DOM_ANIMATION);
  end;
end;

function TLemmingGame.FindObjectID(X, Y: Integer; TriggerType: TTriggerTypes): Word;
// finds a suitable object that has the correct trigger type and is not currently active.
var
  ObjectID: Word;
  ObjectFound: Boolean;
  Inf: TInteractiveObjectInfo;
begin
  // Because ObjectTypeToTrigger defaults to trZombie, looking for this trigger type is nonsense!
  Assert(TriggerType <> trZombie, 'FindObjectId called for trZombie');

  ObjectID := ObjectInfos.Count;
  ObjectFound := False;
  repeat
    Dec(ObjectID);
    Inf := ObjectInfos[ObjectID];
    // Check correct TriggerType
    if (ObjectTypeToTrigger[Inf.TriggerEffect] = TriggerType)
       and not Inf.IsDisabled then   // shouldn't be necessary, but to be sure, it stays here
    begin
      // Check trigger areas for this object
      if PtInRect(Inf.TriggerRect, Point(X, Y)) then
        ObjectFound := True;
    end;

    // Additional checks for locked exit
    if (Inf.TriggerEffect = DOM_LOCKEXIT) and not (ButtonsRemain = 0) then
      ObjectFound := False;
    // Additional checks for triggered traps, triggered animations, teleporters
    if Inf.Triggered then
      ObjectFound := False;
    // ignore already used buttons, one-shot traps and pick-up skills
    if     (Inf.TriggerEffect in [DOM_BUTTON, DOM_TRAPONCE, DOM_PICKUP])
       and (Inf.CurrentFrame = 0) then  // other objects have always CurrentFrame = 0, so the first check is needed!
      ObjectFound := False;
    // Additional check, that the corresponding receiver is inactive
    if     (Inf.TriggerEffect = DOM_TELEPORT)
       and (ObjectInfos[Inf.ReceiverId].Triggered or ObjectInfos[Inf.ReceiverId].HoldActive) then
      ObjectFound := False;

  until ObjectFound or (ObjectID = 0);

  if ObjectFound then
    Result := ObjectID
  else
    Result := 65535;
end;


function TLemmingGame.HandleTrap(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := True;

  if     L.LemIsMechanic and HasPixelAt(L.LemX, L.LemY)
     and not (L.LemAction in [baClimbing, baHoisting, baSwimming]) then
  begin
    ObjectInfos[ObjectID].IsDisabled := True;
    Transition(L, baFixing);
  end
  else
  begin
    Inf := ObjectInfos[ObjectID];
    // trigger
    Inf.Triggered := True;
    Inf.ZombieMode := L.LemIsZombie;
    // Make sure to remove the blocker field!
    L.LemHasBlockerField := False;
    RestoreMap;
    RemoveLemming(L, RM_KILL);
    CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
    DelayEndFrames := MaxIntValue([DelayEndFrames, Inf.AnimationFrameCount]);
  end;
end;

function TLemmingGame.HandleTrapOnce(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := True;

  if     L.LemIsMechanic and HasPixelAt(L.LemX, L.LemY)
     and not (L.LemAction in [baClimbing, baHoisting, baSwimming]) then
  begin
    ObjectInfos[ObjectID].IsDisabled := True;
    Transition(L, baFixing);
  end
  else
  begin
    Inf := ObjectInfos[ObjectID];
    // trigger
    Inf.IsDisabled := True;
    Inf.Triggered := True;
    Inf.ZombieMode := L.LemIsZombie;
    // Make sure to remove the blocker field!
    L.LemHasBlockerField := False;
    RestoreMap;
    RemoveLemming(L, RM_KILL);
    CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
    DelayEndFrames := MaxIntValue([DelayEndFrames, Inf.AnimationFrameCount]);
  end;
end;

function TLemmingGame.HandleObjAnimation(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := False;
  Inf := ObjectInfos[ObjectID];
  Inf.Triggered := True;
  CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
end;

function TLemmingGame.HandleTelepSingle(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := True;

  Inf := ObjectInfos[ObjectID];

  Inf.Triggered := True;
  Inf.ZombieMode := L.LemIsZombie;
  CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
  L.LemTeleporting := True;
  Inf.TeleLem := L.LemIndex;
  // Make sure to remove the blocker field!
  L.LemHasBlockerField := False;
  RestoreMap;
  MoveLemToReceivePoint(L, ObjectID);
end;

function TLemmingGame.HandleTeleport(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := True;

  Inf := ObjectInfos[ObjectID];

  Inf.Triggered := True;
  Inf.ZombieMode := L.LemIsZombie;
  CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
  L.LemTeleporting := True;
  Inf.TeleLem := L.LemIndex;
  Inf.TwoWayReceive := false;
  // Make sure to remove the blocker field!
  L.LemHasBlockerField := False;
  RestoreMap;

  ObjectInfos[Inf.ReceiverID].HoldActive := True;
end;

function TLemmingGame.HandlePickup(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := False;

  if not L.LemIsZombie then
  begin
    Inf := ObjectInfos[ObjectID];
    Inf.CurrentFrame := 0;
    CueSoundEffect(SFX_PICKUP, L.Position);
    case Inf.SkillType of
      0 : UpdateSkillCount(baClimbing, true);
      1 : UpdateSkillCount(baFloating, true);
      2 : UpdateSkillCount(baExploding, true);
      3 : UpdateSkillCount(baBlocking, true);
      4 : UpdateSkillCount(baBuilding, true);
      5 : UpdateSkillCount(baBashing, true);
      6 : UpdateSkillCount(baMining, true);
      7 : UpdateSkillCount(baDigging, true);
      8 : UpdateSkillCount(baToWalking, true);
      9 : UpdateSkillCount(baSwimming, true);
      10 : UpdateSkillCount(baGliding, true);
      11 : UpdateSkillCount(baFixing, true);
      12 : UpdateSkillCount(baStoning, true);
      13 : UpdateSkillCount(baPlatforming, true);
      14 : UpdateSkillCount(baStacking, true);
      15 : UpdateSkillCount(baCloning, true);
    end;
  end;
end;


function TLemmingGame.HandleButton(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
  n: Integer;
begin
  Result := False;

  if not L.LemIsZombie then
  begin
    Inf := ObjectInfos[ObjectID];
    CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), L.Position);
    Inf.Triggered := True;
    Dec(ButtonsRemain);

    if ButtonsRemain = 0 then
    begin
      for n := 0 to (ObjectInfos.Count - 1) do
        if ObjectInfos[n].TriggerEffect = DOM_LOCKEXIT then
        begin
          Inf := ObjectInfos[n];
          Inf.Triggered := True;
          CueSoundEffect(GetTrapSoundIndex(Inf.SoundEffect), Inf.Center);
        end;
    end;
  end;
end;

function TLemmingGame.HandleExit(L: TLemming; IsLocked: Boolean): Boolean;
begin
  Result := False; // only see exit trigger area, if it actually used

  if (not L.LemIsZombie) and not (L.LemAction in [baFalling, baSplatting]) then
  begin
    Result := True;
    Transition(L, baExiting);
    CueSoundEffect(SFX_YIPPEE, L.Position);
  end;
end;

function TLemmingGame.HandleRadiation(L: TLemming; Stoning: Boolean): Boolean;
begin
  Result := False;

  if (L.LemExplosionTimer = 0) and not (L.LemAction in [baOhnoing, baStoning]) then
  begin
    L.LemExplosionTimer := 152;
    L.LemTimerToStone := Stoning;
  end;
end;

function TLemmingGame.HandleForceField(L: TLemming; Direction: Integer): Boolean;
(*var
  dy, NewY: Integer; *)
begin
  Result := False;
  if (L.LemDx = -Direction) and not (L.LemAction = baHoisting) then
  begin
    Result := True;

    (*dy := 0;
    NewY := L.LemY;
    while (dy <= 8) and HasPixelAt(L.LemX + Direction, NewY + 1) do
    begin
      Inc(dy);
      Dec(NewY);
    end;
    if dy < 9 then *)
    TurnAround(L);

    // Avoid moving into terrain, see http://www.lemmingsforums.net/index.php?topic=2575.0
    if L.LemAction = baMining then
    begin
      if L.LemFrame = 2 then
        ApplyMinerMask(L, 1, 0, 0)
      else if (L.LemFrame >= 3) and (L.LemFrame < 15) then
        ApplyMinerMask(L, 1, -2*L.LemDx, -1);
    end
    // Required for turned builders not to walk into air
    // For platformers, see http://www.lemmingsforums.net/index.php?topic=2530.0
    else if (L.LemAction in [baBuilding, baPlatforming]) and (L.LemFrame >= 9) then
      LayBrick(L)
    else if L.LemAction = baClimbing then
    begin
      Inc(L.LemX, L.LemDx); // Move out of the wall
      if not L.LemIsNewClimbing then Inc(L.LemY); // Don't move below original position
      Transition(L, baWalking);
    end;
  end;
end;

function TLemmingGame.HandleFire(L: TLemming): Boolean;
begin
  Result := True;

  Transition(L, baVaporizing);
  CueSoundEffect(SFX_VAPORIZING, L.Position);
end;

function TLemmingGame.HandleFlipper(L: TLemming; ObjectID: Word): Boolean;
var
  Inf: TInteractiveObjectInfo;
begin
  Result := False;

  Inf := ObjectInfos[ObjectID];
  if not (L.LemInFlipper = ObjectID) then
  begin
    L.LemInFlipper := ObjectID;
    if (Inf.CurrentFrame = 1) xor (L.LemDX < 0) then
    begin
      TurnAround(L);
      Result := True;
    end;

    Inf.CurrentFrame := 1 - Inf.CurrentFrame // swap the possible values 0 and 1
  end;
end;

function TLemmingGame.HandleWaterDrown(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baExploding, baStoneFinish, baVaporizing, baExiting, baSplatting];
begin
  Result := False;
  if not L.LemIsSwimmer then
  begin
    Result := True;

    if not (L.LemAction in ActionSet) then
    begin
      Transition(L, baDrowning);
      CueSoundEffect(SFX_DROWNING, L.Position);
    end;
  end;
end;

function TLemmingGame.HandleWaterSwim(L: TLemming): Boolean;
const
  ActionSet = [baSwimming, baClimbing, baHoisting, baOhnoing, baExploding,
                baStoning, baStoneFinish, baVaporizing, baExiting, baSplatting];
begin
  Result := True;
  if L.LemIsSwimmer and not (L.LemAction in ActionSet) then
  begin
    Transition(L, baSwimming);
    CueSoundEffect(SFX_SWIMMING, L.Position);
  end;
end;



procedure TLemmingGame.ApplyStoneLemming(L: TLemming);
var
  X: Integer;
begin
  X := L.LemX;
  if L.LemDx = 1 then Inc(X);

  StoneLemBmp.DrawTo(PhysicsMap, X - 8, L.LemY -10);
  fRenderInterface.AddTerrain(di_Stoner, X - 8, L.LemY -10);

  InitializeMinimap;
end;


procedure TLemmingGame.ApplyExplosionMask(L: TLemming);
var
  X1, Y1: Integer;
  PosX, PosY: Integer;
begin
  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);
  PosY := L.LemY;

  ExplodeMaskBmp.DrawTo(PhysicsMap, PosX - 8, PosY - 14);

  // Delete these pixels from the terrain layer
  fRenderInterface.RemoveTerrain(PosX - 8, PosY - 14, ExplodeMaskBmp.Width, ExplodeMaskBmp.Height);

  InitializeMinimap;
end;

procedure TLemmingGame.ApplyBashingMask(L: TLemming; MaskFrame: Integer);
var
  Bmp: TBitmap32;
  S, D: TRect;
  X1, Y1: Integer;
begin
  // dos bashing mask = 16 x 10

  if L.LemDx = 1 then
    Bmp := BashMasks
  else
    Bmp := BashMasksRTL;

  S := CalcFrameRect(Bmp, 4, MaskFrame);
  D.Left := L.LemX - 8;
  D.Top := L.LemY - 10;
  D.Right := D.Left + 16;
  D.Bottom := D.Top + 10;

  Assert(CheckRectCopy(D, S), 'bash rect err');

  Bmp.DrawTo(PhysicsMap, D, S);

  // Delete these pixels from the terrain layer
  fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);

  InitializeMinimap;
end;

procedure TLemmingGame.ApplyMinerMask(L: TLemming; MaskFrame, AdjustX, AdjustY: Integer);
// The miner mask is usually centered at the feet of L
// AdjustX, AdjustY lets one adjust the position of the miner mask relative to this
var
  Bmp: TBitmap32;
  MaskX, MaskY: Integer;
  S, D: TRect;
  X1, Y1: Integer;
begin
  Assert((MaskFrame >=0) and (MaskFrame <= 1), 'miner mask error');

  MaskX := L.LemX + L.LemDx - 8 + AdjustX;
  MaskY := L.LemY + MaskFrame - 12 + AdjustY;

  if L.LemDx = 1 then
    Bmp := MineMasks
  else
    Bmp := MineMasksRTL;

  S := CalcFrameRect(Bmp, 2, MaskFrame);

  D.Left := MaskX;
  D.Top := MaskY;
  D.Right := MaskX + RectWidth(S) - 1; // whoops: -1 is important to avoid stretching
  D.Bottom := MaskY + RectHeight(S) - 1; // whoops: -1 is important to avoid stretching

  Assert(CheckRectCopy(D, S), 'miner rect error');

  Bmp.DrawTo(PhysicsMap, D, S);

  // Delete these pixels from the terrain layer
  fRenderInterface.RemoveTerrain(D.Left, D.Top, D.Right - D.Left, D.Bottom - D.Top);

  InitializeMinimap;
end;


procedure TLemmingGame.DrawParticles(L: TLemming; DoErase: Boolean);
// if DoErase = False, then draw the explosion particles,
// if DoErase = True, then erase them.
//var
//  i, X, Y: Integer;
begin

(*  for i := 0 to 79 do
  begin
    X := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DX;
    Y := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DY;
    if (X <> -128) and (Y <> -128) then
    begin
      X := L.LemX + X;
      Y := L.LemY + Y;
      fRenderer.ParticleLayer.PixelS[X, Y] := fRenderer.Theme.ParticleColors[i];
    end;
  end;

  fExplodingGraphics := True;*)
end;


procedure TLemmingGame.DrawAnimatedObjects;
var
  i, f: Integer;
  Inf : TInteractiveObjectInfo;
begin

  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect = DOM_BACKGROUND then
    begin
      Inf.Left := Inf.Left + Inf.Movement(True, CurrentIteration); // x-movement
      Inf.Top := Inf.Top + Inf.Movement(False, CurrentIteration); // y-movement

      // Check level borders:
      // Don't need f any more, so we can store arbitrary values in it
      // The additional "+f" are necessary! Delphi's definition of mod for negative numbers is totally absurd!
      // The following code works only if the coordinates are not too negative, so Asserts are added
      f := Level.Info.Width + Inf.Width;
      Assert(Inf.Left + Inf.Width + f >= 0, 'Animation Object too far left');
      Inf.Left := ((Inf.Left + Inf.Width + f) mod f) - Inf.Width;

      f := Level.Info.Height + Inf.Height;
      Assert(Inf.Top + Inf.Height + f >= 0, 'Animation Object too far above');
      Inf.Top := ((Inf.Top + Inf.Height + f) mod f) - Inf.Height;
    end;
  end;

  if HyperSpeed then
    Exit;

  // Main stuff comes here!!!
  //Renderer.DrawAllObjects(fTargetBitmap, ObjectInfos, CursorPoint);
end;

procedure TLemmingGame.EraseLemmings;
{-------------------------------------------------------------------------------
  Erase the lemming from the targetbitmap by copying it's rect from the world
  bitmap.
-------------------------------------------------------------------------------}
var
  iLemming: Integer;
  CurrentLemming: TLemming;
  DstRect, TempRect: TRect;
begin
  // Don't need to erase lemmings anymore!
end;

(*procedure TLemmingGame.DrawLemmings;
var
  iLemming: Integer;
  L: TLemming;
  Xo : Integer;
begin
  if HyperSpeed then
    Exit;

  //fRenderer.DrawLemmings(LemmingList, fLemSelected);
  //if not fHyperSpeed then InitializeMinimap;

  // If paused, update screen
  //if Paused then
  //  fRenderer.DrawLevel(fTargetBitmap);
end;*)

(*procedure TLemmingGame.DrawThisLemming(L: TLemming; IsSelected: Boolean = False);
var
  LemLayer: TBitmap32;
  SrcRect, DstRect, DigRect: TRect;
  OldCombine: TPixelCombineEvent;
  TempBmp : TBitmap32;
  Digit: Integer;
  IsPermenent: Boolean;
begin
  LemLayer := fRenderer.LemmingLayer;

  with L do
  begin
    fCurrentlyDrawnLemming := L;
    SrcRect := GetFrameBounds;
    DstRect := GetLocationBounds;
    LemEraseRect := DstRect;

    OldCombine := LAB.OnPixelCombine;

    // Get color scheme for lemming sprite
    IsPermenent := LemIsClimber or LemIsFloater or LemIsGlider or LemIsSwimmer or LemIsMechanic;
    LAB.OnPixelCombine := TRecolorImage.GetLemColorScheme(LemIsZombie, IsPermenent, IsSelected, LemHighlightReplay);

    LAB.DrawTo(LemLayer, DstRect, SrcRect);

    // Always reset LemHighlightReplay to false
    LemHighlightReplay := False;

    if DrawLemmingPixel then
      LemLayer.FillRectS(LemX, LemY, LemX + 1, LemY + 1, clRed32);

    if (LemExplosionTimer > 0) or (L = fHighlightLemming) then
    begin
      SrcRect := Rect(0, 0, 8, 8);
      DigRect := GetCountDownDigitBounds;
      LemEraseRect.Top := DigRect.Top;
      Assert(CheckRectCopy(SrcRect, DigRect), 'digit rect copy');

      Digit := (LemExplosionTimer div 17) + 1;

      TempBmp := TBitmap32.Create;
      TempBmp.SetSize(8, 8);

      if (L = fHighlightLemming) and (LemExplosionTimer mod 17 < 8) then
      begin
        HighlightBmp.DrawTo(TempBmp);
        TempBmp.DrawMode := HighlightBmp.DrawMode;
        TempBmp.OnPixelCombine := HighlightBmp.OnPixelCombine;
      end else begin
        RectMove(SrcRect, 0, (9 - Digit) * 8); // get "frame"
        CntDownBmp.DrawTo(TempBmp, TempBmp.BoundsRect, SrcRect);
        TempBmp.DrawMode := CntDownBmp.DrawMode;
        TempBmp.OnPixelCombine := CntDownBmp.OnPixelCombine;
      end;

      if LemDx = -1 then RectMove(DigRect, -1, 0);

      TempBmp.DrawTo(LemLayer, DigRect);

      TempBmp.Free;
    end;

    // Reverse change on OnPixelCombine
    LAB.OnPixelCombine := OldCombine;
  end;
end;*)


procedure TLemmingGame.CheckForNewShadow;
const
  ShadowSkillSet = [spbPlatformer, spbBuilder, spbStacker,
                    spbDigger, spbMiner, spbBasher, spbExplode];
begin
  if fHyperSpeed then Exit;

  // Check whether we have to redraw the Shadow (if lem or skill changed)
  if (not fExistShadow) or (not (fLemWithShadow = fLemSelected))
                        or (not (fLemWithShadowButton = fSelectedSkill)) then
  begin
    if fExistShadow then // false if coming from UpdateLemming
    begin
      // erase existing ShadowBridge
      fRenderer.ClearShadows;
      fExistShadow := false;
    end;

    // Draw the new ShadowBridge
    try
      if not Assigned(fLemSelected) then Exit;
      if not (fSelectedSkill in ShadowSkillSet) then Exit;

      // Draw the shadows
      fRenderer.DrawShadows(fLemSelected, fSelectedSkill, GetShadowEndPos);

      // remember stats for lemming with shadow
      fLemWithShadow := fLemSelected;
      fLemWithShadowButton := fSelectedSkill;
      fExistShadow := True;
    except
      // Reset existing shadows
      fLemWithShadow := nil;
      fLemWithShadowButton := fSelectedSkill;
      fExistShadow := False;
    end;
  end;
end;

function TLemmingGame.GetShadowEndPos: Integer;
var
  j: Integer;
  L: TLemming;
begin
  j := 0;
  L := fLemSelected;
  case fSelectedSkill of
  spbDigger: // Get number of pixels we have to move down
    begin
      while (   HasPixelAt(L.LemX - 3, L.LemY + j) or HasPixelAt(L.LemX - 2, L.LemY + j)
             or HasPixelAt(L.LemX - 1, L.LemY + j) or HasPixelAt(L.LemX, L.LemY + j)
             or HasPixelAt(L.LemX + 1, L.LemY + j) or HasPixelAt(L.LemX + 2, L.LemY + j)
             or HasPixelAt(L.LemX + 3, L.LemY + j))
            and not HasSteelAt(L.LemX, L.LemY + j) do
      begin
        Inc(j);
      end;
    end;

  spbMiner: // Get number of pixels we have to move down
    begin
      while     HasPixelAt(L.LemX + (2*j+1)*L.LemDx, L.LemY + j + 1)
            and HasPixelAt(L.LemX + (2*j+2)*L.LemDx, L.LemY + j + 1)
            and not HasIndestructibleAt(L.LemX + (2*j)*L.LemDx, L.LemY + j, L.LemDx, baMining)
            and not HasIndestructibleAt(L.LemX + (2*j+1)*L.LemDx, L.LemY + j, L.LemDx, baMining)
            and not HasIndestructibleAt(L.LemX + (2*j+2)*L.LemDx, L.LemY + j, L.LemDx, baMining) do
      begin
        Inc(j);
      end;
    end;

  spbBasher: // Get number of pixels we have to move horizontally
    begin
      repeat
        Inc(j, 5);
      until    (FindGroundPixel(L.LemX + (j-1)*L.LemDx, L.LemY) > 2)
            or (FindGroundPixel(L.LemX + (j-2)*L.LemDx, L.LemY) > 2)
            or (FindGroundPixel(L.LemX + (j-3)*L.LemDx, L.LemY) > 2)
            or (FindGroundPixel(L.LemX + (j-4)*L.LemDx, L.LemY) > 2)
            or (FindGroundPixel(L.LemX + (j-5)*L.LemDx, L.LemY) > 2)
            or (not (   HasPixelAt(L.LemX + (j+2)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+3)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+4)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+5)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+6)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+7)*L.LemDx, L.LemY - 5)
                     or HasPixelAt(L.LemX + (j+8)*L.LemDx, L.LemY - 5)))
            or HasIndestructibleAt(L.LemX + j*L.LemDx, L.LemY - 3, L.LemDx, baBashing)
            or HasIndestructibleAt(L.LemX + j*L.LemDx, L.LemY - 3, L.LemDx, baBashing)
            or HasIndestructibleAt(L.LemX + j*L.LemDx, L.LemY - 3, L.LemDx, baBashing);

      // end always with three additional pixels
      Inc(j, 3);
    end;

  spbStacker: // 0 or 1, depending on starting position
    begin
      if HasPixelAt(L.LemX + L.LemDx, L.LemY) then j := 1;
    end;

  spbExplode: // 0 or 1, depending on direction of Lemming
    begin
      if L.LemDx = 1 then j := 1;
    end;
  end;

  Result := j;
end;


procedure TLemmingGame.LayBrick(L: TLemming);
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  BrickPosY, n: Integer;
  BrickColor: TColor32;
begin
  Assert((L.LemNumberOfBricksLeft > 0) and (L.LemNumberOfBricksLeft < 13),
            'Number bricks out of bounds');

  BrickColor := BrickPixelColors[12 - L.LemNumberOfBricksLeft] or $FF000000;

  If L.LemAction = baBuilding then BrickPosY := L.LemY - 1
  else BrickPosY := L.LemY; // for platformers

  for n := 0 to 5 do
    AddConstructivePixel(L.LemX + n*L.LemDx, BrickPosY);

  InitializeMinimap;
end;

function TLemmingGame.LayStackBrick(L: TLemming): Boolean;
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  BrickPosY, n: Integer;
  PixPosX: Integer;
  BrickColor: TColor32;
begin
  Assert((L.LemNumberOfBricksLeft > 0) and (L.LemNumberOfBricksLeft < 13),
            'Number stacker bricks out of bounds');

  BrickColor := BrickPixelColors[12 - L.LemNumberOfBricksLeft] or $FF000000;

  BrickPosY := L.LemY - 9 + L.LemNumberOfBricksLeft;
  if L.LemStackLow then Inc(BrickPosY);

  Result := False;

  for n := 1 to 3 do
  begin
    PixPosX := L.LemX + n*L.LemDx;
    if not HasPixelAt(PixPosX, BrickPosY) then
    begin
      AddConstructivePixel(PixPosX, BrickPosY);
      Result := true;
    end;
  end;

  InitializeMinimap;
end;

procedure TLemmingGame.AddConstructivePixel(X, Y: Integer);
begin
  PhysicsMap.PixelS[X, Y] := PhysicsMap.PixelS[X, Y] or PM_SOLID;
  fRenderInterface.AddTerrain(di_ConstructivePixel, X, Y);
end;


function TLemmingGame.DigOneRow(PosX, PosY: Integer): Boolean;
// The central pixel of the removed row lies at (PosX, PosY)
var
  n: Integer;
begin
  Result := False;

  Assert(PosY >=0, 'Digging at negative Y-coordinate');

  For n := -4 to 4 do
  begin
    if HasPixelAt(PosX + n, PosY) and not HasTriggerAt(PosX + n, PosY, trSteel) then
    begin
      RemovePixelAt(PosX + n, PosY);
      if (n > -4) and (n < 4) then Result := True;
    end;

    // Delete these pixels from the terrain layer
    fRenderInterface.RemoveTerrain(PosX - 4, PosY, 9, 1);
  end;

  InitializeMinimap;
end;

function TLemmingGame.HandleLemming(L: TLemming): Boolean;
{-------------------------------------------------------------------------------
  This is the main lemming method, called by CheckLemmings().
  The return value should return true if the lemming has to be checked by
  interactive objects.
  o Increment lemming animationframe
  o Call specialized action-method
  o Do *not* call this method for a removed lemming
-------------------------------------------------------------------------------}
begin
  // Remember old position and action for CheckTriggerArea
  L.LemXOld := L.LemX;
  L.LemYOld := L.LemY;
  L.LemActionOld := L.LemAction;

  Inc(L.LemFrame);

  if L.LemFrame > L.LemMaxFrame then
  begin
    L.LemFrame := 0;
    // Floater and Glider start cycle at frame 9!
    if L.LemAction in [baFloating, baGliding] then L.LemFrame := 9;
    if L.LemAnimationType = lat_Once then L.LemEndOfAnimation := True;
  end;

  // Do Lem action
  Result := LemmingMethods[L.LemAction](L);

  if L.LemIsZombie then SetZombieField(L);
end;

function TLemmingGame.CheckLevelBoundaries(L: TLemming) : Boolean;
// Check for both sides and the bottom
begin
  Result := True;
  // Bottom
  if L.LemY > LEMMING_MAX_Y + PhysicsMap.Height then
  begin
    RemoveLemming(L, RM_NEUTRAL);
    Result := False;
  end;
  // Sides
  if (L.LemX < 0) or (L.LemX >= PhysicsMap.Width) then
  begin
    RemoveLemming(L, RM_NEUTRAL);
    Result := False;
  end;
end;


function TLemmingGame.HandleWalking(L: TLemming): Boolean;
var
  LemDy: Integer;
begin
  Result := True;

  Inc(L.LemX, L.LemDx);
  LemDy := FindGroundPixel(L.LemX, L.LemY);

  if (LemDy < -6) then
  begin
    if L.LemIsClimber then
      Transition(L, baClimbing)
    else
    begin
      TurnAround(L);
      Inc(L.LemX, L.LemDx);
    end;
  end
  else if (LemDy < -2) then
  begin
    Transition(L, baJumping);
    Inc(L.LemY, -2);
  end
  else if (LemDy < 1) then
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
end;



function TLemmingGame.HandleSwimming(L: TLemming): Boolean;
var
  LemDy: Integer;

  function LemDive(L: TLemming): Integer;
    // Returns 0 if the lem may not dive down
    // Otherwise return the amount of pixels the lem dives
  var
    DiveDepth: Integer;
  begin
    if L.LemIsClimber then DiveDepth := 3
    else DiveDepth := 4;

    Result := 1;
    while HasPixelAt(L.LemX, L.LemY + Result) and (Result <= DiveDepth) do
    begin
      Inc(Result);
      if L.LemY + Result >= PhysicsMap.Height then Result := DiveDepth + 1; // End while loop!
    end;

    // do not dive, when there is no more water
    //if not (ReadWaterMap(L.LemX, L.LemY + Result) = DOM_WATER) then Result := 0;
    if not HasTriggerAt(L.LemX, L.LemY + Result, trWater) then Result := 0;

    if Result > DiveDepth then Result := 0; // too much terrain to dive
  end;

begin
  Result := True;

  Inc(L.LemX, L.LemDx);

  if HasTriggerAt(L.LemX, L.LemY, trWater) or HasPixelAt(L.LemX, L.LemY) then // original check only ReadWaterMap(L.LemX - L.LemDx, L.LemY)
  begin
    // This is not completely the same as in V1.43. There a check
    // for the pixel (L.LemX, L.LemY) is omitted.
    LemDy := FindGroundPixel(L.LemX, L.LemY);

    // Rise if there is water above the lemming
    if (LemDy >= -1) and HasTriggerAt(L.LemX, L.LemY -1, trWater)
                     and not HasPixelAt(L.LemX, L.LemY - 1) then   // original check at -2!
      Dec(L.LemY)

    else if LemDy < -6 then
    begin
      if LemDive(L) > 0 then
        Inc(L.LemY, LemDive(L)) // Dive below the terrain
      else if L.LemIsClimber then
        Transition(L, baClimbing)
      else
      begin
        TurnAround(L);
        Inc(L.LemX, L.LemDx); // Move lemming back
      end
    end

    else if LemDy <= -3 then
    begin
      Transition(L, baJumping);
      Dec(L.LemY, 2);
    end

    else if LemDy <= -1 then
    begin
      Transition(L, baWalking);
      Inc(L.LemY, LemDy);
    end;
  end

  else // if no water or terrain on current position
  begin
    LemDy := FindGroundPixel(L.LemX, L.LemY);
    If LemDy > 1 then
    begin
      Inc(L.LemY);
      Transition(L, baFalling);
    end
    else // if LemDy = 0 or 1
    begin
      Inc(L.LemY, LemDy);
      Transition(L, baWalking);
    end;
  end;

end;



function TLemmingGame.HandleJumping(L: TLemming): Boolean;
var
  dy: Integer;
begin
  Result := True;
  with L do
  begin
    dy := 0;
    while (dy < 2) and (LemJumped < 5) and (HasPixelAt(LemX, LemY-1)) do
    begin
      Inc(dy);
      Dec(LemY);
      Inc(LemJumped);
    end;

    if (dy < 2) and not HasPixelAt(LemX, LemY-1) then
    begin
      Transition(L, baWalking);
    end else if ((LemJumped = 4) and HasPixelAt(LemX, LemY-1) and HasPixelAt(LemX, LemY-2)) or ((LemJumped >= 5) and HasPixelAt(LemX, LemY-1)) then
    begin
      Dec(LemX, LemDx);
      Transition(L, baFalling, true); // turn around as well
    end;
  end;
end;

function TLemmingGame.HandleDigging(L: TLemming): Boolean;
var
  ContinueWork: Boolean;
begin
  Result := True;

  if L.LemIsNewDigger then
  begin
    L.LemIsNewDigger := False;
    DigOneRow(L.LemX, L.LemY - 1);
    // The first digger cycle is one frame longer!
    // So we need to artificially cancel the very first frame advancement.
    Dec(L.LemFrame);
  end;

  if L.LemFrame in [0, 8] then
  begin
    Inc(L.LemY);

    ContinueWork := DigOneRow(L.LemX, L.LemY - 1);

    if HasSteelAt(L.LemX, L.LemY) then
    begin
      CueSoundEffect(SFX_HITS_STEEL, L.Position);
      Transition(L, baWalking);
    end

    else if not ContinueWork then
      Transition(L, baFalling);
  end;
end;


function TLemmingGame.HandleClimbing(L: TLemming): Boolean;
// Be very careful when changing the terrain/hoister checks for climbers!
// See http://www.lemmingsforums.net/index.php?topic=2506.0 first!
var
  FoundClip: Boolean;
begin
  Result := True;

  if L.LemFrame <= 3 then
  begin
    FoundClip := (HasPixelAt(L.LemX - L.LemDx, L.LemY - 6 - L.LemFrame))
              or (HasPixelAt(L.LemX - L.LemDx, L.LemY - 5 - L.LemFrame) and (not L.LemIsNewClimbing));

    if L.LemFrame = 0 then // first triggered after 8 frames!
      FoundClip := FoundClip and HasPixelAt(L.LemX - L.LemDx, L.LemY - 7);

    if FoundClip then
    begin
      // Don't fall below original position on hitting terrain in first cycle
      if not L.LemIsNewClimbing then L.LemY := L.LemY - L.LemFrame + 3;
      Dec(L.LemX, L.LemDx);
      Transition(L, baFalling, True); // turn around as well
    end
    else if not HasPixelAt(L.LemX, L.LemY - 7 - L.LemFrame) then
    begin
      // if-case prevents too deep bombing, see http://www.lemmingsforums.net/index.php?topic=2620.0
      if not (L.LemIsNewClimbing and (L.LemFrame = 1)) then
      begin
        L.LemY := L.LemY - L.LemFrame + 2;
        L.LemIsNewClimbing := False;
      end;
      Transition(L, baHoisting);
    end;
  end

  else
  begin
    Dec(L.LemY);
    L.LemIsNewClimbing := False;

    FoundClip := HasPixelAt(L.LemX - L.LemDx, L.LemY - 7);

    if L.LemFrame = 7 then
      FoundClip := FoundClip and HasPixelAt(L.LemX, L.LemY - 7);

    if FoundClip then
    begin
      Inc(L.LemY);
      Dec(L.LemX, L.LemDx);
      Transition(L, baFalling, True); // turn around as well
    end;
  end;
end;


function TLemmingGame.HandleDrowning(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;


function TLemmingGame.HandleFixing(L: TLemming): Boolean;
begin
  Result := False;
  Dec(L.LemMechanicFrames);
  if L.LemMechanicFrames <= 0 then
    Transition(L, baWalking)
  else if L.LemFrame mod 8 = 0 then
    CueSoundEffect(SFX_FIXING, L.Position);
end;


function TLemmingGame.HandleHoisting(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
    Transition(L, baWalking)
  // special case due to http://www.lemmingsforums.net/index.php?topic=2620.0
  else if (L.LemFrame = 1) and L.LemIsNewClimbing then
    Dec(L.LemY, 1)
  else if L.LemFrame <= 4 then
    Dec(L.LemY, 2);
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

  if L.LemFrame = 9 then
  begin
    L.LemPlacedBrick := LemCanPlatform(L);
    LayBrick(L);
  end

  else if (L.LemFrame = 10) and (L.LemNumberOfBricksLeft <= 3) then
    CueSoundEffect(SFX_BUILDER_WARNING, L.Position)

  else if L.LemFrame = 15 then
  begin
    if not L.LemPlacedBrick then
      Transition(L, baWalking, True) // turn around as well

    else if PlatformerTerrainCheck(L.LemX + 2*L.LemDx, L.LemY) then
    begin
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True);  // turn around as well
    end

    else
      Inc(L.LemX, L.LemDx);
  end

  else if L.LemFrame = 0 then
  begin
    if PlatformerTerrainCheck(L.LemX + 2*L.LemDx, L.LemY) and (L.LemNumberOfBricksLeft > 1) then
    begin
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True);  // turn around as well
    end

    else if PlatformerTerrainCheck(L.LemX + 3*L.LemDx, L.LemY) and (L.LemNumberOfBricksLeft > 1) then
    begin
      Inc(L.LemX, 2*L.LemDx);
      Transition(L, baWalking, True);  // turn around as well
    end

    else
    begin
      Inc(L.LemX, 2*L.LemDx);
      Dec(L.LemNumberOfBricksLeft); // Why are we doing this here, instead at the beginning of frame 15??
      if L.LemNumberOfBricksLeft = 0 then
      begin
        // stalling if there are pixels in the way:
        if HasPixelAt(L.LemX, L.LemY - 1) then Dec(L.LemX, L.LemDx);
        Transition(L, baShrugging);
      end;
    end;
  end
end;



function TLemmingGame.HandleBuilding(L: TLemming): Boolean;
begin
  Result := True;

  if L.LemFrame = 9 then
    LayBrick(L)

  else if (L.LemFrame = 10) and (L.LemNumberOfBricksLeft <= 3) then
    CueSoundEffect(SFX_BUILDER_WARNING, L.Position)

  else if L.LemFrame = 0 then
  begin
    Dec(L.LemNumberOfBricksLeft);

    if HasPixelAt(L.LemX + L.LemDx, L.LemY - 2) then
      Transition(L, baWalking, True)  // turn around as well

    else if (     HasPixelAt(L.LemX + L.LemDx, L.LemY - 3)
              or  HasPixelAt(L.LemX + 2*L.LemDx, L.LemY - 2)
              or (HasPixelAt(L.LemX + 2*L.LemDx, L.LemY - 10) and (L.LemNumberOfBricksLeft > 0))
            ) then
    begin
      Dec(L.LemY);
      Inc(L.LemX, L.LemDx);
      Transition(L, baWalking, True)  // turn around as well
    end

    else
    begin
      Dec(L.LemY);
      Inc(L.LemX, 2*L.LemDx);

      if (     HasPixelAt(L.LemX, L.LemY - 2)
           or  HasPixelAt(L.LemX, L.LemY - 3)
           or  HasPixelAt(L.LemX + L.LemDx, L.LemY - 3)
           or (HasPixelAt(L.LemX + L.LemDx, L.LemY - 9) and (L.LemNumberOfBricksLeft > 0))
         ) then
         Transition(L, baWalking, True)  // turn around as well

      else if L.LemNumberOfBricksLeft = 0 then
         Transition(L, baShrugging);
    end;
  end;
end;


function TLemmingGame.HandleStacking(L: TLemming): Boolean;
begin
  Result := True;

  if L.LemFrame = 7 then
    L.LemPlacedBrick := LayStackBrick(L)

  else if L.LemFrame = 0 then
  begin
    Dec(L.LemNumberOfBricksLeft);

    // sound on last three bricks
    if L.LemNumberOfBricksLeft < 3 then CueSoundEffect(SFX_BUILDER_WARNING, L.Position);

    if not L.LemPlacedBrick then
      Transition(L, baWalking, True) // Even on the last brick???  // turn around as well
    else if L.LemNumberOfBricksLeft = 0 then
      Transition(L, baShrugging);
  end;
end;



function TLemmingGame.HandleBashing(L: TLemming): Boolean;
var
  LemDy, AdjustedFrame, n: Integer;
  ContinueWork: Boolean;

  function BasherIndestructibleCheck(x, y, Direction: Integer): Boolean;
  begin
    // check for indestructible terrain 3, 4 and 5 pixels above (x, y)
    Result := (    (HasIndestructibleAt(x, y - 3, Direction, baBashing))
                or (HasIndestructibleAt(x, y - 4, Direction, baBashing))
                or (HasIndestructibleAt(x, y - 5, Direction, baBashing))
              );
  end;

  procedure BasherTurn(L: TLemming; SteelSound: Boolean);
  begin
    // Turns basher around an transitions to walker
    Dec(L.LemX, L.LemDx);
    Transition(L, baWalking, True); // turn around as well
    if SteelSound then CueSoundEffect(SFX_HITS_STEEL, L.Position);
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

begin
  Result := True;

  // The basher graphics have a cycle length of 32
  // However the mechanics have only a cycle of 16
  AdjustedFrame := L.LemFrame mod 16;

  // Remove terrain
  if AdjustedFrame in [2, 3, 4, 5] then
    ApplyBashingMask(L, AdjustedFrame - 2);

  // Check for enough terrain to continue working
  if AdjustedFrame = 5 then
  begin
    ContinueWork := False;
    For n := 1 to 14 do
    begin
      if (     HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 6)
           and not HasIndestructibleAt(L.LemX + n*L.LemDx, L.LemY - 6, L.LemDx, baBashing)
         ) then ContinueWork := True;
      if HasPixelAt(L.LemX + n*L.LemDx, L.LemY - 5) then ContinueWork := True;
    end;

    if ContinueWork = False then
    begin
      if HasPixelAt(L.LemX, L.LemY) then
        Transition(L, baWalking)
      else
        Transition(L, baFalling);
    end;
  end;

  // Basher movement
  if AdjustedFrame in [11, 12, 13, 14, 15] then
  begin
    Inc(L.LemX, L.LemDx);

    LemDy := FindGroundPixel(L.LemX, L.LemY);

    If LemDy = 4 then
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
          //stall basher
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

function TLemmingGame.FindGroundPixel(x, y: Integer): Integer;
begin
  // Find the new ground pixel
  // If Result = 4, then at least 4 pixels are air below (X, Y)
  // If Result = -7, then at least 7 pixels are terrain above (X, Y)
  Result := 0;
  if HasPixelAt(x, y) then
  begin
    while HasPixelAt(x, y + Result - 1) and (Result > -7) do
      Dec(Result);
  end
  else
  begin
    Inc(Result);
    while (not HasPixelAt(x, y + Result)) and (Result < 4) do
      Inc(Result);
  end;
end;


function TLemmingGame.HasIndestructibleAt(x, y, Direction: Integer;
                                          Skill: TBasicLemmingAction): Boolean;
begin
  // check for indestructible terrain at position (x, y), depending on skill.
  Result := (    ( PhysicsMap.PixelS[X, Y] and PM_STEEL <> 0)
              or ((PhysicsMap.PixelS[X, Y] and PM_ONEWAYDOWN <> 0) and (Skill = baBashing))
              or ((PhysicsMap.PixelS[X, Y] and PM_ONEWAYLEFT <> 0) and (Direction = 1) and (Skill in [baBashing, baMining]))
              or ((PhysicsMap.PixelS[X, Y] and PM_ONEWAYRIGHT <> 0) and (Direction = -1) and (Skill in [baBashing, baMining]))
            );
end;

function TLemmingGame.HasSteelAt(X, Y: Integer): Boolean;
begin
  //Result := (ReadSpecialMap(X, Y) = DOM_STEEL);
  Result := PhysicsMap.PixelS[X, Y] and PM_STEEL <> 0;
end;



function TLemmingGame.HandleMining(L: TLemming): Boolean;
  procedure MinerTurn(L: TLemming; X, Y: Integer);
  begin
    if HasSteelAt(X, Y) then CueSoundEffect(SFX_HITS_STEEL, L.Position);
    // Independently of (X, Y) this check is always made at Lem position
    // No longer check at Lem position, due to http://www.lemmingsforums.net/index.php?topic=2547.0
    if HasPixelAt(L.LemX, L.LemY-1) then Dec(L.LemY);
    Transition(L, baWalking, True);  // turn around as well
  end;

begin
  Result := True;

  if L.LemFrame in [1, 2] then
    ApplyMinerMask(L, L.LemFrame - 1, 0, 0)

  else if L.LemFrame in [3, 15] then
  begin
    Inc(L.LemX, 2*L.LemDx);
    Inc(L.LemY);

    // Note that all if-checks are relative to the end position!

    // Lem cannot go down, so turn; see http://www.lemmingsforums.net/index.php?topic=2547.0
    if     HasIndestructibleAt(L.LemX - L.LemDx, L.LemY - 1, L.LemDx, baMining)
       and HasIndestructibleAt(L.LemX, L.LemY - 1, L.LemDx, baMining) then
    begin
      Dec(L.LemX, 2*L.LemDx);
      MinerTurn(L, L.LemX + 2*L.LemDx, L.LemY - 1);
    end

    // This first check is only relevant during the very first cycle.
    // Otherwise the pixel was already checked in frame 15 of the previous cycle
    else if (L.LemFrame = 3) and HasIndestructibleAt(L.LemX - L.LemDx, L.LemY - 2, L.LemDx, baMining) then
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
begin
  Result := True;

  if L.LemIsFloater and (L.LemTrueFallen > 16) then
    // Depending on updrafts, this happens on the 6th-8th frame
    Transition(L, baFloating)

  else if L.LemIsGlider and (L.LemTrueFallen > 6) then
    // This always happens on the 4th frame
    Transition(L, baGliding)

  else
  begin
    CurrFallDist := 0;
    MaxFallDist := 3;
    if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then MaxFallDist := 2;

    // Move lem until hitting ground
    while (CurrFallDist < MaxFallDist) and not HasPixelAt(L.LemX, L.LemY) do
    begin
      Inc(L.LemY);
      Inc(CurrFallDist);
      Inc(L.LemFallen);
      Inc(L.LemTrueFallen);
      if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then L.LemFallen := 0;
    end;

    if CurrFallDist < MaxFallDist then
    begin
      // Object checks at hitting ground
      if ReadObjectMapType(L.LemX, L.LemY) = DOM_SPLAT then
        Transition(L, baSplatting)
      else if ReadObjectMapType(L.LemX, L.LemY) = DOM_NOSPLAT then
        Transition(L, baWalking)
      else if L.LemFallen > fFallLimit then
        Transition(L, baSplatting)
      else
        Transition(L, baWalking);
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

  MaxFallDist := FloaterFallTable[L.LemFrame];
  if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then Dec(MaxFallDist);

  if MaxFallDist > MaxIntValue([FindGroundPixel(L.LemX, L.LemY), 0]) then
  begin
    // Lem has found solid terrain
    Inc(L.LemY, MaxIntValue([FindGroundPixel(L.LemX, L.LemY), 0]));
    Transition(L, baWalking);
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
      // bug-fix for http://www.lemmingsforums.net/index.php?topic=2693
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
  begin
    // Move upwards if in updraft
    LemYDir := 1;
    if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then LemYDir := -1;

    if    ((FindGroundPixel(L.LemX + L.LemDx, L.LemY) < -4) and DoTurnAround(L, True))
       or (     HasPixelAt(L.LemX + L.LemDx, L.LemY + 1)
            and HasPixelAt(L.LemX + L.LemDx, L.LemY + 2)
            and HasPixelAt(L.LemX + L.LemDx, L.LemY + 3)) then
    begin
      if HasPixelAt(L.LemX, L.LemY) and (LemYDir = 1) then
        Transition(L, baWalking)
      else if HasPixelAt(L.LemX, L.LemY - 2) and (LemYDir = -1) then
        // Do nothing
      else
        Inc(L.LemY, LemYDir);
    end;
  end;

  function HeadCheck(LemX, Lemy: Integer): Boolean; // returns False if lemming hits his head
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
  MaxFallDist := GliderFallTable[L.LemFrame];

  if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then
  begin
    Dec(MaxFallDist);
    // Rise a pixel every second frame
    if (L.LemFrame >= 9) and (L.LemFrame mod 2 = 1)
       and (not HasPixelAt(L.LemX + L.LemDx, L.LemY + MaxFallDist - 1))
       and HeadCheck(L.LemX, L.LemY - 1) then
      Dec(MaxFallDist);
  end;

  Inc(L.LemX, L.LemDx);

  // Do upwards movement right away
  if MaxFallDist < 0 then Inc(L.LemY, MaxFallDist);

  GroundDist := FindGroundPixel(L.LemX, L.LemY);

  if GroundDist < -4 then // pushed down or turn around
  begin
    if DoTurnAround(L, false) then
    begin
      // move back and turn around
      Dec(L.LemX, L.LemDx);
      TurnAround(L);
      CheckOnePixelShaft(L);
    end
    else
    begin
      // move down
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
    Transition(L, baWalking);
  end

  else if MaxFallDist > 0 then // no pixel above current location; not checked if one has moved upwards
  begin // same algorithm as for faller!
    if MaxFallDist > GroundDist then
    begin
      // Lem has found solid terrain
      Assert(GroundDist >= 0, 'glider GroundDist negative');
      Inc(L.LemY, GroundDist);
      Transition(L, baWalking);
    end
    else
      Inc(L.LemY, MaxFallDist);
  end

  else if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then // head check for pushing down in updraft
  begin
    // move down at most 2 pixels until the HeadCheck passes
    LemDy := -1;
    while (not HeadCheck(L.LemX, L.LemY)) and (LemDy < 2) do
    begin
      Inc(L.LemY);
      Inc(LemDy);
      // Check whether the glider has reached the ground
      if HasPixelAt(L.LemX, L.LemY) then
      begin
        Transition(L, baWalking);
        LemDy := 4;
      end;
    end;
  end;
end;


function TLemmingGame.HandleSplatting(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleExiting(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_SAVE);
end;

function TLemmingGame.HandleVaporizing(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleBlocking(L: TLemming): Boolean;
begin
  Result := True;
  if not HasPixelAt(L.LemX, L.LemY) then Transition(L, baFalling);
end;

function TLemmingGame.HandleShrugging(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then Transition(L, baWalking);
end;

function TLemmingGame.HandleOhNoing(L: TLemming): Boolean;
begin
  Result := True;
  if L.LemEndOfAnimation then
  begin
    if L.LemAction = baOhNoing then
      Transition(L, baExploding)
    else // if L.LemAction = baStoning then
      Transition(L, baStoneFinish);
    L.LemHasBlockerField := False; // remove blocker field
    RestoreMap;
    Result := False;
  end
  else if not HasPixelAt(L.LemX, L.LemY) then
  begin
    L.LemHasBlockerField := False; // remove blocker field
    RestoreMap;
    // let lemming fall
    if ReadObjectMapType(L.LemX, L.LemY) = DOM_UPDRAFT then
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 2]))
    else
      Inc(L.LemY, MinIntValue([FindGroundPixel(L.LemX, L.LemY), 3]));
  end;
end;


function TLemmingGame.HandleExploding(L: TLemming): Boolean;
begin
  Result := False;

  if L.LemAction = baExploding then
    ApplyExplosionMask(L)
  else // if L.LemAction = baStoneFinish
    ApplyStoneLemming(L);

  RemoveLemming(L, RM_KILL);
  L.LemExploded := True;
  L.LemParticleTimer := PARTICLE_FRAMECOUNT;
  fParticleFinishTimer := PARTICLE_FINISH_FRAMECOUNT;
end;


procedure TLemmingGame.RemoveLemming(L: TLemming; RemMode: Integer = 0);
begin
  if L.LemIsZombie then
  begin
    Assert(RemMode <> RM_SAVE, 'Zombie removed with RM_SAVE removal type!');
    Assert(RemMode <> RM_ZOMBIE, 'Zombie removed with RM_ZOMBIE removal type!');
    L.LemRemoved := True;
  end

  else if not L.LemRemoved then // usual and living lemming
  begin
    Inc(LemmingsRemoved);
    Dec(LemmingsOut);
    if (fHighlightLemming = L) then fHighlightLemming := nil;
    L.LemRemoved := True;

    case RemMode of
    RM_SAVE : begin
                Inc(LemmingsIn);
                GameResultRec.gLastRescueIteration := fCurrentIteration;
              end;
    RM_NEUTRAL: CueSoundEffect(SFX_FALLOUT, L.Position);
    RM_ZOMBIE: begin
                 L.LemIsZombie := True;
                 L.LemRemoved := False;
               end;
    end;           
  end;

  DoTalismanCheck;

  UpdateLemmingCounts;
  InfoPainter.SetReplayMark(Replaying);
end;


procedure TLemmingGame.UpdateLemmings;
{-------------------------------------------------------------------------------
  The main method: handling a single frame of the game.
-------------------------------------------------------------------------------}
begin
  if fGameFinished then
    Exit;
  CheckForGameFinished;

  fAssignedSkillThisFrame := false;

  // do not move this!
  if not Paused then // paused is handled by the GUI
    CheckAdjustReleaseRate;

  if fLastRecordedRR <> CurrReleaseRate then
  begin
    RecordReleaseRate(raf_StopChangingRR);
    fLastRecordedRR := CurrReleaseRate;

    if LemmingsReleased < Level.Info.LemmingsCount - 1 then
    begin
      if CurrReleaseRate < LowestReleaseRate then LowestReleaseRate := CurrReleaseRate;
      if CurrReleaseRate > HighestReleaseRate then HighestReleaseRate := CurrReleaseRate;
    end;

    if CurrentIteration < 20 then
    begin
      LowestReleaseRate := CurrReleaseRate;
      HighestReleaseRate := CurrReleaseRate;
    end;
  end;

  CheckForReplayAction(true);

  // erase existing ShadowBridge
  if fExistShadow then
  begin
    fRenderer.ClearShadows;
    fExistShadow := false;
    //DrawShadowBridge(true);
    //fExplodingGraphics := True; // Redraw everything later on
  end;

  // just as a warning: do *not* mess around with the order here
  IncrementIteration;
  EraseLemmings;
  CheckReleaseLemming;
  CheckLemmings;
  CheckUpdateNuking;
  UpdateInteractiveObjects;

  // when hyperspeed is terminated then copy world back into targetbitmap
  if fLeavingHyperSpeed then
  begin
    fHyperSpeed := False;
    fLeavingHyperSpeed := False;
    if fPauseOnHyperSpeedExit and not Paused then
      SetSelectedSkill(spbPause);
    InfoPainter.ClearSkills;
    InfoPainter.DrawButtonSelector(fSelectedSkill, true);
  end;

  // Get highest priority lemming under cursor
  GetPriorityLemming(fLemSelected, SkillPanelButtonToAction[fSelectedSkill], CursorPoint);

  DrawAnimatedObjects;

  //DrawLemmings;
  fRenderInterface.SelectedLemming := fLemSelected;

  // Check lemmings under cursor
  HitTest;

  if InfoPainter <> nil then
  begin
    UpdateLemmingCounts;
    InfoPainter.SetReplayMark(Replaying);
    UpdateTimeLimit;
  end;


  CheckForReplayAction(false);

  if fReplaying and (fCurrentIteration > fReplayManager.LastActionFrame) then
    RegainControl;

  // force update if raw explosion pixels drawn (or shadowstuff)
  //if fExplodingGraphics and (not HyperSpeed) then
  //  fTargetBitmap.Changed;

  // Just always redraw. We can change this later if there's perfomance issues.
  //if not HyperSpeed then
    //fRenderer.DrawLevel(fTargetBitmap);

  CheckForPlaySoundEffect;
end;


procedure TLemmingGame.IncrementIteration;
var
  i: Integer;
const
  OID_ENTRY = 1;
begin
  Inc(fCurrentIteration);
  Inc(fClockFrame);
  if DelayEndFrames > 0 then Dec(DelayEndFrames);

  if fParticleFinishTimer > 0 then
    Dec(fParticleFinishTimer);

  if fClockFrame = 17 then
  begin
    fClockFrame := 0;
    if TimePlay > -5999 then Dec(TimePlay);
  end
  else if fClockFrame = 1 then
    if InfoPainter <> nil then UpdateTimeLimit;

  // hard coded dos frame numbers
  case CurrentIteration of
    15:
      begin
        CueSoundEffect(SFX_LETSGO);
      end;
    35:
      begin
        EntriesOpened := False;
        for i := 0 to ObjectInfos.Count - 1 do
          if ObjectInfos[i].TriggerEffect = DOM_WINDOW then
          begin
            ObjectInfos[i].Triggered := True;
            ObjectInfos[i].CurrentFrame := 1;
            EntriesOpened := true;
            CueSoundEffect(SFX_ENTRANCE, ObjectInfos[i].Center);
          end;
        if fStartupMusicAfterEntry and not EntriesOpened then begin
          if gsoMusic in fSoundOpts then
            SoundMgr.PlayMusic(0);
          fStartupMusicAfterEntry := False;
        end;
        EntriesOpened := True;
      end;
    55:
      begin
        if fStartupMusicAfterEntry then
        begin
          if gsoMusic in fSoundOpts then
            SoundMgr.PlayMusic(0);
          fStartupMusicAfterEntry := False;
        end;
      end;
  end;

end;


procedure TLemmingGame.HitTest(Autofail: Boolean = false);
var
  HitCount: Integer;
  L, OldLemSelected: TLemming;
  S: string;
  i: integer;
  fAltOverride: Boolean;
begin
  if Autofail then fHitTestAutoFail := true;

  OldLemSelected := fLemSelected;
  // Shadow stuff for updated selected lemming
  GetPriorityLemming(fLemSelected, SkillPanelButtonToAction[fSelectedSkill], CursorPoint);
  CheckForNewShadow;

  // Get new priority lemming including lems that cannot receive the skill
  HitCount := GetPriorityLemming(L, baNone, CursorPoint);

  if L <> OldLemSelected then
  begin
    fLemSelected := L;
    fRenderInterface.SelectedLemming := L;
  end;

  if Assigned(L) and not fHitTestAutofail then
  begin
    // get highlight text
    fAltOverride := false;
    if (L.LemIsClimber or L.LemIsFloater or L.LemIsGlider or L.LemIsSwimmer or L.LemIsMechanic)
        and L.LemIsZombie then
      fAltOverride := true;

    if fAltButtonHeldDown or fAltOverride then
    begin
      S := '-----';
      if L.LemIsClimber then S[1] := 'C';
      if L.LemIsSwimmer then S[2] := 'S';
      if L.LemIsFloater then S[3] := 'F';
      if L.LemIsGlider then S[3] := 'G';
      if L.LemIsMechanic then S[4] := 'D';
      if L.LemIsZombie then S[5] := 'Z';
    end else begin
      S := LemmingActionStrings[L.LemAction];

      if not (L.LemAction in [baBuilding, baPlatforming, baStacking, baBashing, baMining, baDigging, baBlocking]) then
      begin
        i := 0;
        if L.LemIsClimber then inc(i);
        if L.LemIsSwimmer then inc(i);
        if L.LemIsFloater then inc(i);
        if L.LemIsGlider then inc(i);
        if L.LemIsMechanic then inc(i);

        case i of
          5: S := SQuadathlete;
          4: S := SQuadathlete;
          3: S := STriathlete;
          2: S := SAthlete;
          1: begin
               if L.LemIsClimber then S := SClimber;
               if L.LemIsSwimmer then S := SSwimmer;
               if L.LemIsFloater then S := SFloater;
               if L.LemIsGlider  then S := SGlider;
               if L.LemIsMechanic then S := SMechanic;
             end;
        end;
      end;

      if L.LemIsZombie then S := SZombie;
    end;

    InfoPainter.SetInfoCursorLemming(S, HitCount);
    DrawDebugString(L);
    fCurrentCursor := 2;
  end
  else begin
    InfoPainter.SetInfoCursorLemming('', 0);
    fCurrentCursor := 1;
  end;
end;

function TLemmingGame.ProcessSkillAssignment: Boolean;
var
  Sel: TBasicLemmingAction;
begin
  Result := False;
  if fAssignedSkillThisFrame then Exit;

  // convert buttontype to skilltype
  Sel := SkillPanelButtonToAction[fSelectedSkill];
  Assert(Sel <> baNone);

  Result := AssignNewSkill(Sel);

  fCheckWhichLemmingOnly := False;
  if Result then
  begin
    fAssignedSkillThisFrame := True;
    CheckForNewShadow;
  end;
end;

function TLemmingGame.ProcessHighlightAssignment: Boolean;
var
  L, OldHighlightLemming: TLemming;
  i: Integer;
begin
  Result := False;
  OldHighlightLemming := fHighlightLemming;
  if GetPriorityLemming(L, baNone, CursorPoint) > 0 then
    fHighlightLemming := L
  else
    fHighlightLemming := nil;

  if fHighlightLemming <> OldHighlightLemming then
  begin
    CueSoundEffect(SFX_SKILLBUTTON);
    for i := 0 to LemmingList.Count-1 do
      if LemmingList[i] = fHighlightLemming then
      begin
        fHighlightLemmingID := i;
        Break;
      end else
        fHighlightLemmingID := -1;
    if (Paused) then
    begin
      if OldHighlightLemming <> nil then
      begin
        EraseLemmings; //so the old highlight marker if any disappears
        DrawAnimatedObjects; // not sure why this one. Might be to fix graphical glitches, I guess?
      end;
      //DrawLemmings;  // so the highlight marker shows up
      //fRenderer.DrawLevel(fTargetBitmap);
    end;
  end;

  fRenderInterface.HighlitLemming := fHighlightLemming;


end;

procedure TLemmingGame.ReplaySkillAssignment(aReplayItem: TReplaySkillAssignment);
var
  L: TLemming;
  ass: TBasicLemmingAction;
  OldHighlightLem: TLemming;
begin
  if fAssignedSkillThisFrame then Exit;
  with aReplayItem do
  begin
    if (LemmingIndex < 0) or (LemmingIndex >= LemmingList.Count) then
    begin
      RegainControl;
//      ShowMessage('invalid replay, replay ended');
//          fRecorder.SaveToTxt(apppath+'inv.txt');
      infopainter.SetInfoCursorLemming('invalid', 0);

      Exit;
    end;
    L := LemmingList.List^[LemmingIndex];
    ass := Skill;

    if not (ass in AssignableSkills) then
      raise exception.create(i2s(integer(ass)) + ' ' + i2s(currentiteration));

    if ass in AssignableSkills then
    begin
      // for antiques but nice
      //if (ActionToSkillPanelButton[ass] <> fSelectedSkill) and not fGameParams.IgnoreReplaySelection then
      //  SetSelectedSkill(ActionToSkillPanelButton[ass], True);

      // In order to preserve old replays, we have to check if the skill assignments are still possible
      // As the priority of lemmings has changed, we have to hightlight this lemming
      // After having done the assignment, revert the hightlightning.
      OldHighlightLem := fHighlightLemming;
      fHighlightLemming := L;
      if AssignNewSkill(ass, True) then
        fAssignedSkillThisFrame := true;
      fHighlightLemming := OldHighlightLem;

      // if DoSkillAssignment(L, ass) then
      //  fAssignedSkillThisFrame := true;

      if not HyperSpeed then
        L.LemHighlightReplay := True;
    end;
  end;
end;

(*procedure TLemmingGame.ReplaySkillSelection(aReplayItem: TReplaySelectSkill);
var
  bs: TSkillPanelButton;
begin
  if fGameParams.IgnoreReplaySelection then Exit;
  bs := aReplayItem.Skill;
  setselectedskill(bs, true);
end;*)

function TLemmingGame.GetSelectedSkill: Integer;
var
  i: Integer;
begin
  Result := 8;
  for i := 0 to 7 do
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
    for i := 0 to 7 do
      if fActiveSkills[i] = Value then Result := true;
  end;
begin
  if (fRightMouseButtonHeldDown and fGameParams.ClickHighlight)
  or (fCtrlButtonHeldDown and not fGameParams.ClickHighlight) then RightClick := true;
  if RightClick and (fHighlightLemming <> nil) and (SkillPanelButtonToAction[Value] <> baNone) then
  begin
    // Try assigning skill to highlighted Lem
    if AssignNewSkill(SkillPanelButtonToAction[Value], True) and Paused then
      UpdateLemmings;

    (* if AssignSkill(fHighlightLemming, fHighlightLemming, SkillPanelButtonToAction[Value]) then
      if Paused then UpdateLemmings; *)
  end;
  case Value of
    spbFaster:
      begin
        fSpeedingUpReleaseRate := MakeActive;
        if MakeActive then
          fSlowingDownReleaseRate := False;
        if RightClick and fSpeedingUpReleaseRate then InstReleaseRate := 1;
      end;
    spbSlower:
      begin
        fSlowingDownReleaseRate := MakeActive;
        if MakeActive then
          fSpeedingUpReleaseRate := False;
        if RightClick and fSlowingDownReleaseRate then InstReleaseRate := -1;
      end;
    spbPause:
      begin
        Paused := not Paused;
        FastForward := False;
      end;
    spbNuke:
      begin
        UserSetNuking := True;
        ExploderAssignInProgress := True;
        RecordNuke;
      end;
    spbNone: ; // Do Nothing
    else // all skill buttons
      begin
        if (not CheckSkillInSet(Value)) or (fSelectedSkill = Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);  // unselect old skill
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);   // select new skill
        CueSoundEffect(SFX_SKILLBUTTON);
        //RecordSkillSelection(Value);
        CheckForNewShadow;
      end;
  end;
end;

procedure TLemmingGame.CheckReleaseLemming;
var
  NewLemming: TLemming;
  ix, EntranceIndex: Integer;
begin

  if not EntriesOpened then
    Exit;
  if UserSetNuking then
    Exit;

  // NextLemmingCountdown is initialized to 20 before start of a level
  if NextLemmingCountdown > 0 then Dec(NextLemmingCountdown);

  if NextLemmingCountdown = 0 then
  begin
    NextLemmingCountdown := CalculateNextLemmingCountdown;
    if (LemmingsReleased < MaxNumLemmings) and (Length(DosEntryTable) > 0) then
    begin
      EntranceIndex := LemmingsReleased mod Length(DosEntryTable);
      ix := DosEntryTable[EntranceIndex];
      if ix >= 0 then
      begin
        NewLemming := TLemming.Create;
        with NewLemming do
        begin
          LemIndex := LemmingList.Add(NewLemming);
          Transition(NewLemming, baFalling);

          LemX := ObjectInfos[ix].TriggerRect.Left;
          LemY := ObjectInfos[ix].TriggerRect.Top;
          LemDX := 1;
          if ObjectInfos[ix].IsFlipPhysics then TurnAround(NewLemming);

          LemUsedSkillCount := 0;

          if (ObjectInfos[ix].PreAssignedSkills and 1) <> 0 then LemIsClimber := true;
          if (ObjectInfos[ix].PreAssignedSkills and 2) <> 0 then LemIsSwimmer := true;
          if (ObjectInfos[ix].PreAssignedSkills and 4) <> 0 then LemIsFloater := true
          else if (ObjectInfos[ix].PreAssignedSkills and 8) <> 0 then LemIsGlider := true;
          if (ObjectInfos[ix].PreAssignedSkills and 16) <> 0 then LemIsMechanic := true;
          if (ObjectInfos[ix].PreAssignedSkills and 64) <> 0 then RemoveLemming(NewLemming, RM_ZOMBIE);
          if NewLemming.LemIsZombie then Dec(SpawnedDead);
          if LemIndex = fHighlightLemmingID then fHighlightLemming := NewLemming;
        end;
        Inc(LemmingsReleased);
        Inc(LemmingsOut);
      end;
    end;
  end;
end;

procedure TLemmingGame.CheckUpdateNuking;
var
  CurrentLemming: TLemming;
begin

  if UserSetNuking and ExploderAssignInProgress then
  begin

    // find first following non removed lemming
    while     (Index_LemmingToBeNuked < LemmingsReleased + LemmingsCloned)
          and (LemmingList[Index_LemmingToBeNuked].LemRemoved) do
      Inc(Index_LemmingToBeNuked);

    if (Index_LemmingToBeNuked > LemmingsReleased + LemmingsCloned - 1) then
      ExploderAssignInProgress := FALSE
    else
    begin
      CurrentLemming := LemmingList[Index_LemmingToBeNuked];
      with CurrentLemming do
      begin
        if     (LemExplosionTimer = 0)
           and not (LemAction in [baSplatting, baExploding])
           and not LemIsZombie then
          LemExplosionTimer := 84;
      end;
      Inc(Index_LemmingToBeNuked);

    end;

  end;

end;

procedure TLemmingGame.CreateLemmingAtCursorPoint;
{-------------------------------------------------------------------------------
  debugging procedure: click and create lemming
-------------------------------------------------------------------------------}
var
  NewLemming: TLemming;
begin
  if not EntriesOpened then
    Exit;
  if UserSetNuking then
    Exit;
  if LemmingsReleased < MaxNumLemmings then
  begin
    NewLemming := TLemming.Create;
    with NewLemming do
    begin
      LemIndex := LemmingList.Add(NewLemming);
      Transition(NewLemming, baFalling);
      LemX := CursorPoint.X;
      LemY := CursorPoint.Y;
      LemDX := 1;
    end;
    Inc(LemmingsReleased);
    Inc(LemmingsOut);
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
  Result := 99 - currReleaseRate;
  if (Result < 0) then
    Inc(Result, 256);
  Result := Result div 2 + 4
end;

procedure TLemmingGame.CueSoundEffect(aSoundId: Integer);
begin
  SoundMgr.QueueSound(aSoundId);

  if Paused then
    CheckForPlaySoundEffect;
end;

procedure TLemmingGame.CueSoundEffect(aSoundId: Integer; aOrigin: TPoint);
{-------------------------------------------------------------------------------
  Save last sound.
-------------------------------------------------------------------------------}
var
  i: Integer;
  Bal: Single;
  MidX: Integer; // we don't need MidY because we can't adjust the "height" of a sound anyway
  SrcX: Integer;
begin
  MidX := fRenderInterface.ScreenPos.X + 160;
  SrcX := aOrigin.X;

  Bal := (SrcX - MidX) / 320;
  if Bal < -1 then Bal := -1;
  if Bal > 1 then Bal := 1;

  SoundMgr.QueueSound(aSoundId, Bal);

  if Paused then
    CheckForPlaySoundEffect;
end;

procedure TLemmingGame.DrawDebugString(L: TLemming);
begin
  if Assigned(fOnDebugLemming) then
    fOnDebugLemming(L);
end;

(*
procedure TLemmingGame.DrawError(const S: string; aCode: Integer);
{-------------------------------------------------------------------------------
  this procedure
  o sets the errorcountdown to 48
  o shows the error + code at the place of the hittest
-------------------------------------------------------------------------------}
begin
  if aCode > 0 then
    aCode := -aCode;
  if fInfoPainter <> nil then
    fInfoPainter.SetInfoCursorLemming(S, aCode);
end;
*)

procedure TLemmingGame.AdjustReleaseRate(Delta: Integer);
var
  N: Integer;
  MaxRR: Integer;
begin
  N := CurrReleaseRate + Delta;
  if Level.Info.ReleaseRateLocked then
    MaxRR := Level.Info.ReleaseRate
  else
    MaxRR := 99;
  Restrict(N, Level.Info.ReleaseRate, MaxRR);
  if N <> currReleaseRate then
  begin
    currReleaseRate := N;
    LastReleaseRate := N;
    InfoPainter.DrawSkillCount(spbFaster, currReleaseRate);
  end;
end;


procedure TLemmingGame.RecordNuke;
{-------------------------------------------------------------------------------
  Easy one: Record nuking. Always add new record.
-------------------------------------------------------------------------------}
var
  E: TReplayNuke;
begin
  if not fPlaying or fReplaying then
    Exit;
  E := TReplayNuke.Create;
  E.Frame := fCurrentIteration;
  fReplayManager.Add(E);
end;

procedure TLemmingGame.RecordReleaseRate(aActionFlag: Byte);
var
  E: TReplayChangeReleaseRate;
  NewRec: Boolean;
  RecIteration: Integer;
begin
  if not fPlaying or fReplaying then
    Exit;

  E := TReplayChangeReleaseRate.Create;
  E.Frame := fCurrentIteration;
  E.NewReleaseRate := CurrReleaseRate;
  E.SpawnedLemmingCount := LemmingList.Count;

  fReplayManager.Add(E);
end;

procedure TLemmingGame.RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
{-------------------------------------------------------------------------------
  Always add new record.
-------------------------------------------------------------------------------}
var
  E: TReplaySkillAssignment;
begin
  L.LemUsedSkillCount := L.LemUsedSkillCount + 1;   // this is probably NOT where this should be

  if fFreezeRecording then Exit;
  if not fPlaying or fReplaying then
    Exit;

  E := TReplaySkillAssignment.Create;
  E.Skill := aSkill;
  E.SetInfoFromLemming(L, (L = fHighlightLemming));
  E.Frame := fCurrentIteration;

  fReplayManager.Add(E);
end;

(*procedure TLemmingGame.RecordSkillSelection(aSkill: TSkillPanelButton);
var
  E: TReplaySelectSkill;
begin
  if not fPlaying then Exit;
  if fReplaying then Exit;

  E := TReplaySelectSkill.Create;
  E.Skill := aSkill;
  E.Frame := fCurrentIteration;

  fReplayManager.Add(E);
end;*)


procedure TLemmingGame.CheckForReplayAction(RRCheck: Boolean);
var
  R: TBaseReplayItem;

  procedure ApplySkillAssign;
  var
    E: TReplaySkillAssignment absolute R;
  begin
    ReplaySkillAssignment(E);
  end;

  procedure ApplyReleaseRate;
  var
    E: TReplayChangeReleaseRate absolute R;
  begin
    AdjustReleaseRate(E.NewReleaseRate - CurrReleaseRate);
  end;

  (*procedure ApplySkillSelect;
  var
    E: TReplaySelectSkill absolute R;
  begin
    ReplaySkillSelection(E);
  end;*)

  procedure ApplyNuke;
  var
    E: TReplayNuke absolute R;
  begin
    SetSelectedSkill(spbNuke, true);
  end;

  procedure Handle;
  begin
    if R = nil then Exit;

    if R is TReplaySkillAssignment then
      ApplySkillAssign;

    if R is TReplayChangeReleaseRate then
      ApplyReleaseRate;

    (*if R is TReplaySelectSkill then
      ApplySkillSelect;*)

    if R is TReplayNuke then
      ApplyNuke;
  end;
begin
  if not fReplaying then
    Exit;

  fReplayCommanding := True;

  try
    // Note - the fReplayManager getters can return nil, and often will!
    // The "Handle" procedure ensures this does not lead to errors.
    if RRCheck then
    begin
      R := fReplayManager.ReleaseRateChange[fCurrentIteration];
      Handle;
    end else begin
      R := fReplayManager.Assignment[fCurrentIteration];
      Handle;
      R := fReplayManager.InterfaceAction[fCurrentIteration];
      Handle;
    end;
  finally
    fReplayCommanding := False;
  end;

end;

procedure TLemmingGame.CheckLemmings;
var
  i: Integer;
  CurrentLemming: TLemming;
  HandleInteractiveObjects: Boolean; // wrong name: This just remembers whether we should stop checking more of the lemming
begin

  ZombieMap.Clear(0);

  for i := 0 to LemmingList.Count - 1 do
  begin
    CurrentLemming := LemmingList.List^[i];

    with CurrentLemming do
    begin
      HandleInteractiveObjects := True;
      // @particles
      if LemParticleTimer >= 0 then
        Dec(LemParticleTimer);

      if LemRemoved then
        Continue;

      // Put lemming out of receiver if teleporting is finished.
      if LemTeleporting then
        HandleInteractiveObjects := CheckLemTeleporting(CurrentLemming);

      // Explosion-Countdown
      if HandleInteractiveObjects and (LemExplosionTimer <> 0) then
        HandleInteractiveObjects := not UpdateExplosionTimer(CurrentLemming);

      // HERE COME THE MAIN THREE LINES !!!
      // Let lemmings move
      if HandleInteractiveObjects then
        HandleInteractiveObjects := HandleLemming(CurrentLemming);
      // Check whether the lem is still on screen
      if HandleInteractiveObjects then
        HandleInteractiveObjects := CheckLevelBoundaries(CurrentLemming);
      // Check whether the lem has moved over trigger areas
      if HandleInteractiveObjects then
        CheckTriggerArea(CurrentLemming);
    end;

  end;

  // Check for lemmings meeting zombies
  // Need to do this in separate loop, because the ZombieMap gets only set during HandleLemming!
  for i := 0 to LemmingList.Count - 1 do
  begin
    CurrentLemming := LemmingList.List^[i];
    with CurrentLemming do
    begin
      // Zombies //
      if     (ReadZombieMap(LemX, LemY) and 1 <> 0)
         and (LemAction <> baExiting)
         and not CurrentLemming.LemIsZombie then
        RemoveLemming(CurrentLemming, RM_ZOMBIE);
    end;
  end;

end;


function TLemmingGame.CheckLemTeleporting(L: TLemming): Boolean;
// This function checks, whether a lemming appears out of a receiver
var
  ObjInfo: TInteractiveObjectInfo;
  ObjID: Integer;
begin
  Result := False;

  Assert(L.LemTeleporting = True, 'CheckLemTeleporting called for non-teleporting lemming');

  // Search for Teleporter, the lemming is in
  ObjID := -1;
  repeat
    Inc(ObjID);
    ObjInfo := ObjectInfos[ObjID];
  until (L.LemIndex = ObjInfo.TeleLem) or (ObjID > ObjectInfos.Count - 1);

  Assert(ObjID < ObjectInfos.Count, 'Teleporter associated to teleporting lemming not found');

  if     (ObjInfo.TriggerEffect = DOM_RECEIVER)
     or ((ObjInfo.TriggerEffect = DOM_TWOWAYTELE) and (ObjInfo.TwoWayReceive = True))
     or  (ObjInfo.TriggerEffect = DOM_SINGLETELE) then
  begin
    if    ((ObjInfo.CurrentFrame + 1 >= ObjInfo.AnimationFrameCount) and (ObjInfo.MetaObj.KeyFrame = 0))
       or ((ObjInfo.CurrentFrame + 1 = ObjInfo.MetaObj.KeyFrame) and (ObjInfo.MetaObj.KeyFrame <> 0)) then
    begin
      L.LemTeleporting := False; // Let lemming reappear
      ObjInfo.TeleLem := -1;
      Result := True;
    end;
  end;
end;


procedure TLemmingGame.SetGameResult;
{-------------------------------------------------------------------------------
  We will not, I repeat *NOT* simulate the original Nuke-error.

  (ccexplore: sorry, code added to implement the nuke error by popular demand)
  (Nepster: sorry, namida removed the code long ago again by popular demand)
-------------------------------------------------------------------------------}
var
  gLemCap : Integer;
begin
  with GameResultRec do
  begin
    gCount              := Level.Info.LemmingsCount;
    gToRescue           := Level.Info.RescueCount;
    gRescued            := LemmingsIn;
    gLemCap             := Level.Info.LemmingsCount;

    gGotTalisman        := fTalismanReceived;

    if gLemCap = 0 then
      gTarget := 0
    else
      gTarget := (gToRescue * 100) div gLemCap;

    if Level.Info.DisplayPercent > 0 then gTarget := Level.Info.DisplayPercent;

    if not fGameCheated then
    begin
      if gCount = 0 then
        gDone := 0
      else
        gDone := (gRescued * 100) div gLemCap;   //gCount
    end else begin
      gRescued := gCount;
      if (Level.Info.SkillTypes and $1) <> 0 then gRescued := gRescued + Level.Info.ClonerCount;
      gDone := (gRescued * 100) div gLemCap;
    end;

    GameResult          := gRescued >= gToRescue;
    gSuccess            := GameResult;
    gCheated            := fGameCheated;

  end;
end;

procedure TLemmingGame.CheckForPlaySoundEffect;
var
  i: Integer;
begin
  if HyperSpeed then
  begin
    SoundMgr.ClearQueue;
    Exit;
  end;

  SoundMgr.FlushQueue;
end;

procedure TLemmingGame.RegainControl;
{-------------------------------------------------------------------------------
  This is a very important routine. It jumps from replay into usercontrol.
-------------------------------------------------------------------------------}
begin
  if fReplaying then
  begin
    fReplaying := False;

    fReplayManager.Cut(fCurrentIteration);
  end;

  InfoPainter.SetReplayMark(false); 
end;

procedure TLemmingGame.SetOptions(const Value: TDosGameOptions);
begin
  fOptions := Value;
  Include(fOptions, dgoObsolete);
end;

procedure TLemmingGame.HyperSpeedBegin(PauseWhenDone: Boolean = False);
begin
  Inc(fHyperSpeedCounter);
  fHyperSpeed := True;
  FastForward := False;
  if PauseWhenDone then
    fPauseOnHyperSpeedExit := True
  else
    fPauseOnHyperSpeedExit := False;
end;

procedure TLemmingGame.HyperSpeedEnd;
begin
  if fHyperSpeedCounter > 0 then
  begin
    Dec(fHyperSpeedCounter);
    if fHyperSpeedCounter = 0 then
    begin
      fLeavingHyperSpeed := True;
      if CancelReplayAfterSkip then
      begin
        RegainControl;
        CancelReplayAfterSkip := false;
      end;
      RefreshAllPanelInfo;
    end;
  end;
end;


procedure TLemmingGame.UpdateInteractiveObjects;
{-------------------------------------------------------------------------------
  This method handles the updating of the moving interactive objects:
  o Entrances moving
  o Continuously moving objects like water
  o Triggered objects (traps)
  NB: It does not handle the drawing
-------------------------------------------------------------------------------}
var
  Inf, Inf2: TInteractiveObjectInfo;
  i: Integer;
const
  OID_ENTRY = 1;
begin
  for i := ObjectInfos.Count - 1 downto 0 do
  begin
    Inf := ObjectInfos[i];

    if     (Inf.Triggered or (Inf.MetaObj.TriggerEffect in AlwaysAnimateObjects))
       and (Inf.TriggerEffect <> DOM_PICKUP) then
      Inc(Inf.CurrentFrame);

    if     (Inf.TriggerEffect = DOM_TELEPORT)
       or ((Inf.TriggerEffect = DOM_TWOWAYTELE) and (Inf.TwoWayReceive = false)) then
    begin
      if    ((Inf.CurrentFrame >= Inf.AnimationFrameCount) and (Inf.MetaObj.KeyFrame = 0))
         or ((Inf.CurrentFrame = Inf.MetaObj.KeyFrame) and (Inf.MetaObj.KeyFrame <> 0)) then
      begin
        MoveLemToReceivePoint(LemmingList.List^[Inf.TeleLem], i);
        Inf2 := ObjectInfos[Inf.ReceiverId];
        Inf2.TeleLem := Inf.TeleLem;
        Inf2.Triggered := True;
        Inf2.ZombieMode := Inf.ZombieMode;
        Inf2.TwoWayReceive := true;
        // Reset TeleLem for Teleporter
        Inf.TeleLem := -1;
      end;
    end;

    if Inf.CurrentFrame >= Inf.AnimationFrameCount then
    begin
      Inf.CurrentFrame := 0;
      Inf.Triggered := False;
      Inf.HoldActive := False;
      Inf.ZombieMode := False;
      if Inf.TriggerEffect = DOM_WINDOW then
        fEntranceAnimationCompleted := True;
    end;

  end;

end;

procedure TLemmingGame.CheckAdjustReleaseRate;
begin
  if SpeedingUpReleaseRate then
  begin
    //if not (Replaying and Paused) then
    AdjustReleaseRate(1)
  end
  else if SlowingDownReleaseRate then
  begin
    //if not (Replaying and Paused) then
    AdjustReleaseRate(-1)
  end;
  if InstReleaseRate = -1 then
    AdjustReleaseRate(-100)
  else if InstReleaseRate = 1 then
    AdjustReleaseRate(100);
  InstReleaseRate := 0;
end;

procedure TLemmingGame.SetSoundOpts(const Value: TGameSoundOptions);
begin
  if fSoundOpts = Value then
    Exit;
  fSoundOpts := Value;
  if not (gsoMusic in fSoundOpts) then
    SoundMgr.StopMusic(0)
  else if not fStartupMusicAfterEntry then
    SoundMgr.PlayMusic(0);
end;

procedure TLemmingGame.Finish;
begin
  fGameFinished := True;
  SoundMgr.StopMusic(0);
  SoundMgr.Musics.Clear;
  if Assigned(fOnFinish) then
    fOnFinish(Self);
end;

procedure TLemmingGame.Cheat;
begin
  fGameCheated := True;   // IN-LEVEL CHEAT // just uncomment these two lines to reverse
  SetGameResult;
  Finish;
end;

procedure TLemmingGame.Save(TestModeName: Boolean = false);
var
  SaveNameLrb, SaveNameTxt : String;
  SaveText: Boolean;
  UnpauseAfterDlg: Boolean;

  function GetReplayFileName: String;
  begin
    if fGameParams.fTestMode then
      Result := Trim(fGameParams.Level.Info.Title)
    else
      Result := fGameParams.Info.dSectionName + '_' + LeadZeroStr(fGameParams.Info.dLevel + 1, 2);
    if TestModeName or fGameParams.AlwaysTimestamp then
      Result := Result + '__' + FormatDateTime('yyyy"-"mm"-"dd"_"hh"-"nn"-"ss', Now);
    Result := FastReplace(Result, '<', '_');
    Result := FastReplace(Result, '>', '_');
    Result := FastReplace(Result, ':', '_');
    Result := FastReplace(Result, '"', '_');
    Result := FastReplace(Result, '/', '_');
    Result := FastReplace(Result, '\', '_');
    Result := FastReplace(Result, '|', '_');
    Result := FastReplace(Result, '?', '_');
    Result := FastReplace(Result, '*', '_');
    Result := Result + '.nxrp';
  end;

  function GetDefaultSavePath: String;
  begin
    if fGameParams.fTestMode then
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\'
    else
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\';
    if TestModeName then Result := Result + 'Auto\';
  end;

  function GetInitialSavePath: String;
  begin
    if (fLastReplayDir <> '') and not TestModeName then
      Result := fLastReplayDir
    else
      Result := GetDefaultSavePath;
  end;

  function GetSavePath(DefaultFileName: String): String;
  var
    Dlg : TSaveDialog;
  begin
    Dlg := TSaveDialog.Create(self);
    Dlg.Filter := 'NeoLemmix Replay (*.nxrp)|*.nxrp';
    Dlg.FilterIndex := 1;
    Dlg.InitialDir := GetInitialSavePath;
    Dlg.DefaultExt := '.lrb';
    Dlg.Options := [ofOverwritePrompt];
    Dlg.FileName := DefaultFileName;
    if Dlg.Execute then
    begin
      fLastReplayDir := ExtractFilePath(Dlg.FileName);
      SaveText := (dlg.FilterIndex = 2);
      Result := Dlg.FileName;
    end else
      Result := '';
    Dlg.Free;
  end;

  function GetReplayTypeCase: Integer;
  begin
    // Wouldn't need this if I bothered to merge the boolean options into a single
    // integer value... xD
    Result := 0;
    if TestModeName then Exit;
    if not fGameParams.AutoReplayNames then
      Result := 2
    else if fGameParams.ConfirmOverwrite and FileExists(GetInitialSavePath + SaveNameLrb) then
      Result := 1;
    // Don't need to handle AlwaysTimestamp here; it's handled in GetReplayFileName above.
  end;

begin
  SaveText := false;

  SaveNameLrb := GetReplayFileName;

  case GetReplayTypeCase of
    0: SaveNameLrb := GetDefaultSavePath + SaveNameLrb;
    1: begin
         UnpauseAfterDlg := not Paused; // Game keeps running during the MessageDlg otherwise.
         Paused := true;
         if MessageDlg('Replay already exists. Overwrite?', mtCustom, [mbYes, mbNo], 0) = mrNo then
           SaveNameLrb := GetSavePath(SaveNameLrb)
         else
           SaveNameLrb := GetDefaultSavePath + SaveNameLrb;
         if UnpauseAfterDlg then Paused := false;
       end;
    2:  SaveNameLrb := GetSavePath(SaveNameLrb);
  end;

  if SaveNameLrb <> '' then
  begin
    ForceDirectories(ExtractFilePath(SaveNameLrb));
    fReplayManager.SaveToFile(SaveNameLrb);
  end;

end;

function TLemmingGame.CheckLemmingBlink: Boolean;
var
  i, pcc: Integer;
begin
  Result := false;
  pcc := 0;
  if not (fGameParams.LemmingBlink) then Exit;
  if (fGameParams.ChallengeMode) and ((Level.Info.SkillTypes and 1) <> 0) then Exit;
  for i := 0 to ObjectInfos.Count-1 do
    if (ObjectInfos[i].TriggerEffect = DOM_PICKUP) and (ObjectInfos[i].SkillType = 15) then pcc := pcc + 1;


  if (LemmingsOut + LemmingsIn + (Level.Info.LemmingsCount - LemmingsReleased - SpawnedDead) +
      ((Level.Info.SkillTypes and 1) * CurrSkillCount[baCloning]) + pcc
     < Level.Info.RescueCount)
  and (CurrentIteration mod 17 > 8) then
    Result := true;
end;

function TLemmingGame.CheckTimerBlink: Boolean;
begin
  Result := false;
  if not (fGameParams.TimerBlink) then Exit; 
  if ((fGameParams.TimerMode) or (fGameParams.Level.Info.TimeLimit > 5999)) then Exit;
  if (TimePlay < 30) and (TimePlay >= 0) and (CurrentIteration mod 17 > 8) then
    Result := true;
end;


function TLemmingGame.CheckSkillAvailable(aAction: TBasicLemmingAction): Boolean;
var
  sc, i: Integer;
  CheckButton: TSkillPanelButton;
begin
  Result := fFreezeSkillCount;
  if fFreezeSkillCount then Exit;

  Assert(aAction in AssignableSkills, 'CheckSkillAvailable for not assignable skill');

  sc := CurrSkillCount[aAction];

  if sc > 0 then Result := true;

  CheckButton := ActionToSkillPanelButton[aAction];
  for i := 0 to 7 do
    if fActiveSkills[i] = CheckButton then Exit;

  Result := false;

end;


procedure TLemmingGame.UpdateSkillCount(aAction: TBasicLemmingAction; Rev : Boolean = false);
var
  sc, sc2: ^Integer;
begin
  if Rev and fGameParams.ChallengeMode then Exit;
  if fFreezeSkillCount then Exit;

  Assert(aAction in AssignableSkills, 'UpdateSkillCount for not assignable skill');

  sc := @CurrSkillCount[aAction];
  sc2 := @UsedSkillCount[aAction];

  if sc^ > 99 then Exit;

  if Rev then
    Inc(sc^)
  else
    Dec(sc^);

  if not Rev then Inc(sc2^);

  if sc^ < 0 then sc^ := 0;
  if sc^ > 99 then sc^ := 99;

  InfoPainter.DrawSkillCount(ActionToSkillPanelButton[aAction], sc^);
end;

procedure TLemmingGame.SaveGameplayImage(Filename: String);
begin
  TPngInterface.SavePngFile(Filename, fTargetBitmap, true);
end;

{ TReplayItem }

procedure TLemmingGame.InitializeBrickColors(aBrickPixelColor: TColor32);
var
  i: Integer;
  aR, aG, aB: Integer;
  P: PColor32Entry;
begin
  BrickPixelColor := aBrickPixelColor;
//  FillChar(BrickPixelColors, sizeof(BrickPixelColors), 0);


(* testing
  for i := 0 to 11 do
    if Odd(i) then
    BrickPixelColors[i] := clyellow32
  else
    BrickPixelColors[i] := clred32;

    exit; *)


  for i := 0 to 11 do
    BrickPixelColors[i] := aBrickPixelColor;

  if not fUseGradientBridges then
    Exit;

  P := @BrickPixelColor;

  with p^ do
  begin
    ar:=r;
    ag:=g;
    ab:=b;
  end;

  // lighter
  for i := 7 to 11 do
  begin
    P := @BrickPixelColors[i];
    with P^ do
    begin
      if aR < 252  then inc(ar,4);
      if ag < 252 then inc(ag,4);
      if ab < 252 then inc(ab,4);
      r:=ar; g:=ag; b:=ab;
    end;
  end;


  P := @BrickPixelColor;

  with p^ do
  begin
    ar:=r;
    ag:=g;
    ab:=b;
  end;


  // darker
  for i := 5 downto 0 do
  begin
    P := @BrickPixelColors[i];
    with P^ do
    begin
      if aR > 3 then dec(ar,4);
      if ag > 3 then dec(ag,4);
      if ab > 3 then dec(ab,4);
      r:=ar; g:=ag; b:=ab;
    end;
  end;

end;

end.
