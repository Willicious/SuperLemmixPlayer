{$include lem_directives.inc}

{-------------------------------------------------------------------------------
  Some source code notes:

  • Places with optional mechanics are marked with a comment
  :
    "// @Optional Game Mechanic"

  • Note that a lot of routines start with "Result := False". I removed
    redundant code, so if you see just an "Exit" call then it is always
    to be interpreted as "Return False".

  • Transition() method: It has a default parameter. So if you see a
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
  LemCore, LemTypes, LemDosBmp, LemDosStructures, LemStrings, LemMetaAnimation,
  LemMetaObject, LemInteractiveObject, LemSteel, LemLevel, LemStyle,
  LemGraphicSet, LemDosGraphicSet, LemNeoGraphicSet, LemRendering, LemDosAnimationSet,
  LemMusicSystem, LemDosMainDat,
  GameInterfaces, GameControl, GameSound;

type
  TParticleRec = packed record
    DX, DY: ShortInt
  end;
  TParticleArray = packed array[0..79] of TParticleRec;
  TParticleTable = packed array[0..50] of TParticleArray;

const
  ParticleColorIndices: array[0..15] of Byte = (
    4, 15, 14, 13, 12, 11, 10, 9, 8, 11, 10, 9, 8, 7, 6, 2
  );

type
  tFloatParameterRec = record
    Dy: Integer;
    AnimationFrameIndex: Integer;
  end;

const
  {-------------------------------------------------------------------------------
    So what's this: A table which describes what to do when floating.
    The floaters animation has 8 frames: 0..3 is opening the umbrella
    and 4..7 is the actual floating.
    This table "fakes" 16 frames of floating and what should happen with
    the Y-position of the lemming each frame. Frame zero is missing, because that's
    automatically frame zero.
    Additionally: after 15 go back to 8
  -------------------------------------------------------------------------------}
  FloatParametersTable: array[0..15] of TFloatParameterRec = (
    (Dy:     3; AnimationFrameIndex:   1),
    (Dy:     3; AnimationFrameIndex:   2),
    (Dy:     3; AnimationFrameIndex:   3),
    (Dy:     3; AnimationFrameIndex:   5),
    (Dy:    -1; AnimationFrameIndex:   5),
    (Dy:     0; AnimationFrameIndex:   5),
    (Dy:     1; AnimationFrameIndex:   5),
    (Dy:     1; AnimationFrameIndex:   5),
    (Dy:     2; AnimationFrameIndex:   5),
    (Dy:     2; AnimationFrameIndex:   6),
    (Dy:     2; AnimationFrameIndex:   7),
    (Dy:     2; AnimationFrameIndex:   7),
    (Dy:     2; AnimationFrameIndex:   6),
    (Dy:     2; AnimationFrameIndex:   5),
    (Dy:     2; AnimationFrameIndex:   4),
    (Dy:     2; AnimationFrameIndex:   4)
  );

type
  TLemming = class
  private
    function GetLocationBounds(Nuclear: Boolean = false): TRect; // rect in world
    function GetFrameBounds(Nuclear: Boolean = false): TRect; // rect from animation bitmap
    function GetCountDownDigitBounds: TRect; // countdown
    function GetLemRTL: Boolean; // direction rtl?
    function GetLemHint: string;
  public
  { misc sized }
    LemEraseRect                  : TRect; // the rectangle of the last drawaction (can include space for countdown digits)
  { integer sized fields }
    LemIndex                      : Integer;        // index in the lemminglist
    LemX                          : Integer;        // the "main" foot x position
    LemY                          : Integer;        // the "main" foot y position
    LemParticleX                  : Integer;        // lemming position when particles triggered
    LemParticleY                  : Integer;
    LemDX                         : Integer;        // x speed (1 if left to right, -1 if right to left)
    LemJumped                     : Integer;
    LemFallen                     : Integer;        // number of pixels a faller has fallen
    LemTrueFallen                 : Integer;
    LemOldFallen                  : Integer;
    LemFloated                    : Integer;
    LemClimbed                    : Integer;
    LemClimbStartY                : Integer;
    LemFirstClimb                 : Boolean;
    LemExplosionTimer             : Integer;        // 79 downto 0
    LemMechanicFrames             : Integer;
    LMA                           : TMetaLemmingAnimation; // ref to Lemming Meta Animation
    LAB                           : TBitmap32;      // ref to Lemming Animation Bitmap
    LemFrame                      : Integer;        // current animationframe
    LemMaxFrame                   : Integer;        // copy from LMA
    LemAnimationType              : Integer;        // copy from LMA
    LemParticleTimer              : Integer;        // @particles, 52 downto 0, after explosion
    LemParticleFrame              : Integer;        // the "frame" of the particle drawing algorithm
    FrameTopDy                    : Integer;        // = -LMA.FootY (ccexplore compatible)
    FrameLeftDx                   : Integer;        // = -LMA.FootX (ccexplore compatible)
    LemFloatParametersTableIndex  : Integer;        // index for floaters
    LemNumberOfBricksLeft         : Integer;        // for builder
    LemBorn                       : Integer;        // game iteration the lemming is created
  { byte sized fields }
    LemAction                     : TBasicLemmingAction; // current action of the lemming
    LemObjectBelow                : Byte;
    LemObjectIDBelow              : Word;
    LemSpecialBelow               : Byte;
    LemObjectInFront              : Byte;
    LemRemoved                    : Boolean; // the lemming is not in the level anymore
    LemTeleporting                : Boolean;
    LemEndOfAnimation             : Boolean;
    LemIsClimber                  : Boolean;
    LemIsSwimmer                  : Boolean;
    LemIsFloater                  : Boolean;
    LemIsGlider                   : Boolean;
    LemIsMechanic                 : Boolean;
    LemIsZombie                   : Boolean;
    LemIsGhost                    : Boolean;
    LemCouldPlatform              : Boolean;
    LemInFlipper                  : Integer;
    LemIsBlocking                 : Integer; // not always exactly in sync with the action
    LemBecomeBlocker              : Boolean;
    LemIsNewDigger                : Boolean;
    LemHighlightReplay            : Boolean;
    LemExploded                   : Boolean; // @particles, set after a Lemming actually exploded, used to control particles-drawing
    LemUsedSkillCount             : Integer;
    LemIsClone                    : Boolean;
    LemTimerToStone               : Boolean;
    LemStackLow                   : Boolean;
    LemRTLAdjust                  : Boolean;
    LemInTrap                     : Integer;

    procedure Assign(Source: TLemming);
  { properties }
    property LemRTL: Boolean read GetLemRTL; // direction rtl?
    property LemHint: string read GetLemHint;
  end;

  TLemmingList = class(TObjectList)
  private
    function GetItem(Index: Integer): TLemming;
  protected
  public
    function Add(Item: TLemming): Integer;
    procedure Insert(Index: Integer; Item: TLemming);
    property Items[Index: Integer]: TLemming read GetItem; default;
    property List; // for fast access
  end;

  // internal object used by game
  TInteractiveObjectInfo = class
  private
    function GetBounds: TRect;
  public
    MetaObj        : TMetaObject;
    Obj            : TInteractiveObject;
    CurrentFrame   : Integer;
    Triggered      : Boolean;
    TeleLem        : Integer;
    HoldActive     : Boolean;
    ZombieMode     : Boolean;
    TwoWayReceive  : Boolean;
    OffsetX        : Integer; // these are NOT used directly from TInteractiveObjectInfo
    OffsetY        : Integer; // They're only used to back it up in save states!
    Left           : Integer; // Same here
    Top            : Integer; // And here
    TotalFactor    : Integer; //faster way to handle the movement
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
    rpoSecret,
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

  TReplayRec = packed record
    Check          : Char;         //  1 byte  -  1
    Iteration      : Integer;      //  4 bytes -  5
    ActionFlags    : Word;         //  2 bytes -  7
    AssignedSkill  : Byte;         //  1 byte  -  8
    SelectedButton : Byte;         //  1 byte  -  9
    ReleaseRate    : Integer;      //  1 byte  - 13
    LemmingIndex   : Integer;      //  4 bytes - 17
    LemmingX       : Integer;      //  4 bytes - 21
    LemmingY       : Integer;      //  4 bytes - 25
    CursorX        : SmallInt;     //  2 bytes - 27
    CursorY        : SmallInt;     //  2 bytes - 29
    SelectDir      : ShortInt;
    Reserved2      : Byte;
    Reserved3      : Byte;         // 32
  end;

  TReplayItem = class
  private
    fIteration      : Integer;
    fActionFlags    : Word;
    fAssignedSkill  : Byte;
    fSelectedButton : Byte;
    fReleaseRate    : Byte;
    fLemmingIndex   : Integer;
    fLemmingX       : Integer;
    fLemmingY       : Integer;
    fCursorY        : Integer;
    fCursorX        : Integer;
    fSelectDir       : Integer;
  protected
  public
    property Iteration: Integer read fIteration write fIteration;
    property ActionFlags: Word read fActionFlags write fActionFlags;
    property AssignedSkill: Byte read fAssignedSkill write fAssignedSkill;
    property SelectedButton: Byte read fSelectedButton write fSelectedButton;
    property ReleaseRate: Byte read fReleaseRate write fReleaseRate;
    property LemmingIndex: Integer read fLemmingIndex write fLemmingIndex;
    property LemmingX: Integer read fLemmingX write fLemmingX;
    property LemmingY: Integer read fLemmingY write fLemmingY;
    property CursorX: Integer read fCursorX write fCursorX;
    property CursorY: Integer read fCursorY write fCursorY;
    property SelectDir: Integer read fSelectDir write fSelectDir;
  end;

  TRecorder = class
  private
    fGame : TLemmingGame; // backlink to game
    List  : TObjectList;
    fLevelID: LongWord;
    function GetNumItems: Integer;
  protected
  public
    constructor Create(aGame: TLemmingGame);
    destructor Destroy; override;

    function FindIndexForFrame(aFrame: Integer): Integer;
    function Add: TReplayItem;
    procedure Clear;
    procedure Truncate(aCount: Integer);
    procedure SaveToFile(const aFileName: string);
    procedure SaveToStream(S: TStream);
    procedure SaveToTxt(const aFileName: string);
    procedure LoadFromFile(const aFileName: string; IgnoreProblems: Boolean = false);
    procedure LoadFromOldTxt(const aFileName: string); // antique
    procedure LoadFromStream(S: TStream; IgnoreProblems: Boolean = false);
    property LevelID: LongWord read fLevelID write fLevelID;
    property Count: Integer read GetNumItems;
  end;


  TLemmingGameSavedState = class
    public
      LemmingList: TLemmingList;
      SelectedSkill: TSkillPanelButton;
      TargetBitmap: TBitmap32;
      World: TBitmap32;
      SteelWorld: TBitmap32;
      ObjectMap: TByteMap;
      BlockerMap: TByteMap;
      SpecialMap: TByteMap;
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
      Minutes: Integer;
      Seconds: Integer;
      EntriesOpened: Boolean;
      ObjectInfos: TInteractiveObjectInfoList;
      LowestReleaseRate: Integer;
      HighestReleaseRate: Integer;
      CurrReleaseRate: Integer;
      LastReleaseRate: Integer;
      CurrWalkerCount            : Integer;
      CurrClimberCount           : Integer;
      CurrSwimmerCount           : Integer;
      CurrFloaterCount           : Integer;
      CurrGliderCount            : Integer;
      CurrMechanicCount          : Integer;
      CurrBomberCount            : Integer;
      CurrStonerCount            : Integer;
      CurrBlockerCount           : Integer;
      CurrPlatformerCount        : Integer;
      CurrBuilderCount           : Integer;
      CurrStackerCount           : Integer;
      CurrBasherCount            : Integer;
      CurrMinerCount             : Integer;
      CurrDiggerCount            : Integer;
      CurrClonerCount            : Integer;
      UsedWalkerCount            : Integer;
      UsedClimberCount           : Integer;
      UsedSwimmerCount           : Integer;
      UsedFloaterCount           : Integer;
      UsedGliderCount            : Integer;
      UsedMechanicCount          : Integer;
      UsedBomberCount            : Integer;
      UsedStonerCount            : Integer;
      UsedBlockerCount           : Integer;
      UsedPlatformerCount        : Integer;
      UsedBuilderCount           : Integer;
      UsedStackerCount           : Integer;
      UsedBasherCount            : Integer;
      UsedMinerCount             : Integer;
      UsedDiggerCount            : Integer;
      UsedClonerCount            : Integer;
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
  TSkillMethod = function (Lemming1, Lemming2: TLemming): Boolean of object;
  TSkillMethodArray = array[TBasicLemmingAction] of TSkillMethod;
  TLemmingEvent = procedure (L: TLemming) of object;

  TLemmingGame = class(TComponent)
  private
    fTalismans                 : TTalismans;
    fTalismanReceived          : Boolean;

    fLastReplayDir             : String;

    fTargetBitmap              : TBitmap32; // reference to the drawing bitmap on the gamewindow
    fSelectedSkill             : TSkillPanelButton; // TUserSelectedSkill; // currently selected skill restricted by F3-F9
    fOptions                   : TDosGameOptions; // mechanic options
    fParticles                 : TParticleTable; // all particle offsets
    fParticleColors            : array[0..15] of TColor32;

  { internal objects }
    LemmingList                : TLemmingList; // the list of lemmings
    World                      : TBitmap32; // actual bitmap that is changed by the lemmings
    SteelWorld                 : TBitmap32; // backup bitmap for steel purposes
    ObjectMap                  : TByteMap;
    BlockerMap                 : TByteMap; // for blockers
    SpecialMap                 : TByteMap; // for steel and oneway
    WaterMap                   : TByteMap; // for water, so that other objects can be on it for swimmers etc to use
    ZombieMap                  : TByteMap;
    MiniMap                    : TBitmap32; // minimap of world
    fMinimapBuffer             : TBitmap32; // drawing buffer minimap
    fRecorder                  : TRecorder;

  { reference objects, mostly for easy access in the mechanics-code }
    fGameParams                : TDosGameParams; // ref
    fRenderer                  : TRenderer; // ref to gameparams.renderer
    fInfoPainter               : IGameToolbar; // ref to interface to enable this component to draw to skillpanel
    fLevel                     : TLevel; // ref to gameparams.level
    Style                      : TBaseLemmingStyle; // ref to gameparams.style
    Graph                      : TBaseDosGraphicSet; // ref to gameparams.graph
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
    TimeScoreAdjust            : Integer;
    fCursorPoint               : TPoint;
    fRightMouseButtonHeldDown  : Boolean;
    fShiftButtonHeldDown       : Boolean;
    fAltButtonHeldDown         : Boolean;
    fCtrlButtonHeldDown        : Boolean;
    Minutes                    : Integer; // minutes left
    Seconds                    : Integer; // seconds left
    fPlaying                   : Boolean; // game in active playing mode?
    EntriesOpened              : Boolean;
    LemmingMethods             : TLemmingMethodArray; // a method for each basic lemming state
    SkillMethods               : TSkillMethodArray; // a method for assigning jobs (including dummies)
    fCheckWhichLemmingOnly     : Boolean; // use during replays only, to signal the AssignSkill methods
                                          // to only indicate which Lemming gets the assignment, without
                                          // actually doing the assignment
    fFreezeSkillCount          : Boolean; // used when skill count should be frozen, for example when
                                          // calling assign routines that should assign the skill for free
                                          // note that this also overrides the test for if skills are available
    fFreezeRecording           : Boolean;
    WhichLemming               : TLemming; // see above
    LastNPLemming              : TLemming; // for emulation of right-click bug
    ObjectInfos                : TInteractiveObjectInfoList; // list of objects excluding entrances
    Entries                    : TInteractiveObjectInfoList; // list of entrances (NOT USED ANYMORE)
    DosEntryTable              : array of Integer; // table for entrance release order
    fSlowingDownReleaseRate    : Boolean;
    fSpeedingUpReleaseRate     : Boolean;
    fPaused             : Boolean;
    MaxNumLemmings             : Integer;
    LowestReleaseRate          : Integer;
    HighestReleaseRate         : Integer;
    CurrReleaseRate            : Integer;
    LastReleaseRate            : Integer;
    CurrWalkerCount            : Integer;
    CurrClimberCount           : Integer;
    CurrSwimmerCount           : Integer;
    CurrFloaterCount           : Integer;
    CurrGliderCount            : Integer;
    CurrMechanicCount          : Integer;
    CurrBomberCount            : Integer;
    CurrStonerCount            : Integer;
    CurrBlockerCount           : Integer;
    CurrPlatformerCount        : Integer;
    CurrBuilderCount           : Integer;
    CurrStackerCount           : Integer;
    CurrBasherCount            : Integer;
    CurrMinerCount             : Integer;
    CurrDiggerCount            : Integer;
    CurrClonerCount            : Integer;
    UsedWalkerCount            : Integer;
    UsedClimberCount           : Integer;
    UsedSwimmerCount           : Integer;
    UsedFloaterCount           : Integer;
    UsedGliderCount            : Integer;
    UsedMechanicCount          : Integer;
    UsedBomberCount            : Integer;
    UsedStonerCount            : Integer;
    UsedBlockerCount           : Integer;
    UsedPlatformerCount        : Integer;
    UsedBuilderCount           : Integer;
    UsedStackerCount           : Integer;
    UsedBasherCount            : Integer;
    UsedMinerCount             : Integer;
    UsedDiggerCount            : Integer;
    UsedClonerCount            : Integer;
    Gimmick                    : Integer;
    GimmickSet                 : LongWord;
    GimmickSet2                : LongWord;
    GimmickSet3                : LongWord;
    UserSetNuking              : Boolean;
    ExploderAssignInProgress   : Boolean;
    Index_LemmingToBeNuked     : Integer;
    fCurrentCursor             : Integer; // normal or highlight
    BrickPixelColor            : TColor32;
    BrickPixelColors           : array[0..11] of TColor32; // gradient steps
    fGameFinished              : Boolean;
    fGameCheated               : Boolean;
    fSecretGoto                : Integer;
    LevSecretGoto              : Integer;
    NextLemmingCountDown       : Integer;
    fDrawLemmingPixel          : Boolean;
    fFastForward               : Boolean;
    fReplaying                 : Boolean;
    fReplayIndex               : Integer;
    fCurrentScreenPosition     : TPoint; // for minimap, this really sucks but works ok for the moment
    fLastCueSoundIteration     : Integer;
    fSoundToPlay               : array of Integer;
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
    procedure UpdateLemmingsHatch;
    procedure UpdateLemmingsAlive;
    procedure UpdateLemmingsSaved;
    procedure UpdateTimeLimit;
    procedure UpdateOneSkillCount(aSkill: TSkillPanelButton);
    procedure UpdateAllSkillCounts;
  { pixel combine eventhandlers }
    procedure DoTalismanCheck(SecretTrigger: Boolean = false);
    procedure CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineBuilderPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingPixelsZombie(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingPixelsGhost(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineBuilderPixelsGhost(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineNoOverwriteStoner(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineMinimapWorldPixels(F: TColor32; var B: TColor32; M: TColor32);
    function CheckGimmick(GType: Integer): Boolean;
  { internal methods }
    procedure ApplyBashingMask(L: TLemming; MaskFrame: Integer; Redo: Integer = 0);
    procedure ApplyExplosionMask(L: TLemming; Redo: Integer = 0);
    procedure ApplyStoneLemming(L: TLemming; Redo: Integer = 0);
    procedure ApplyMinerMask(L: TLemming; MaskFrame, X, Y: Integer; Redo: Integer = 0);
    procedure ApplyAutoSteel;
    procedure ApplyLevelEntryOrder;
    function CalculateNextLemmingCountdown: Integer;
    procedure CheckAdjustReleaseRate;
    procedure CheckForGameFinished;
    procedure CheckForInteractiveObjects(L: TLemming; HandleAllObjects: Boolean = true);
    function CheckForLevelTopBoundary(L: TLemming; LocalFrameTopDy: Integer = 0): Boolean;
    function CheckForOverlappingField(L: TLemming): Boolean;
    procedure CheckForPlaySoundEffect;
    procedure CheckForReplayAction(RRCheck: Boolean);
    procedure CheckLemmings;
    procedure CheckReleaseLemming;
    procedure CheckUpdateNuking;
    procedure CueSoundEffect(aSoundId: Integer);
    function DigOneRow(L: TLemming; Y: Integer): Boolean;
    procedure DrawAnimatedObjects;
    procedure DrawDebugString(L: TLemming);
    procedure DrawLemmings;
    procedure DrawParticles(L: TLemming);
    procedure DrawStatics;
    procedure EraseLemmings;
    procedure EraseParticles(L: TLemming);
    function GetTrapSoundIndex(aDosSoundEffect: Integer): Integer;
    function GetMusicFileName: String;
    function HasPixelAt(X, Y: Integer; SwimTest: Boolean = false): Boolean;
    function HasPixelAt_ClipY(X, Y, minY: Integer; SwimTest: Boolean = false): Boolean;
    procedure IncrementIteration;
    procedure InitializeBrickColors(aBrickPixelColor: TColor32);
    procedure InitializeMiniMap;
    procedure InitializeObjectMap;
    procedure InitializeBlockerMap;
    procedure LayBrick(L: TLemming; o: Integer = 0);
    procedure LayStackBrick(L: TLemming; o: Integer);
    function PrioritizedHitTest(out Lemming1, Lemming2: TLemming;
                                MousePos: TPoint;
                                CheckRightMouseButton: Boolean = True): Integer;
    function FindReceiver(oid: Byte; sval: Byte): Byte;
    procedure MoveLemToReceivePoint(L: TLemming; oid: Byte);
    function ReadObjectMap(X, Y: Integer; Advance: Boolean = True): Word;
    function ReadObjectMapType(X, Y: Integer): Byte;
    function ReadBlockerMap(X, Y: Integer): Byte;
    function ReadSpecialMap(X, Y: Integer): Byte;
    function ReadWaterMap(X, Y: Integer): Byte;
    function ReadZombieMap(X, Y: Integer): Byte;
    procedure RecordStartPause;
    procedure RecordEndPause;
    procedure RecordNuke;
    procedure RecordReleaseRate(aActionFlag: Byte);
    procedure RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
    procedure RecordSkillSelection(aSkill: TSkillPanelButton);
    procedure RemoveLemming(L: TLemming; RemMode: Integer = 0);
    procedure RemovePixelAt(X, Y: Integer);
    procedure ReplaySkillAssignment(aReplayItem: TReplayItem);
    procedure ReplaySkillSelection(aReplayItem: TReplayItem);
    procedure RestoreMap(L: TLemming);
    procedure SaveMap(L: TLemming);
    procedure SetBlockerField(L: TLemming);
    procedure SetZombieField(L: TLemming);
    procedure SetGhostField(L: TLemming);
    procedure SpawnLemming;
    procedure Transition(L: TLemming; aAction: TBasicLemmingAction; DoTurn: Boolean = False);
    procedure TurnAround(L: TLemming);
    function UpdateExplosionTimer(L: TLemming): Boolean;
    procedure UpdateInteractiveObjects;
    procedure UpdateLemmingsIn(Num, Max: Integer);
    procedure WriteObjectMap(X, Y: Integer; aValue: Word; Advance: Boolean = False);
    procedure WriteBlockerMap(X, Y: Integer; aValue: Byte);
    procedure WriteSpecialMap(X, Y: Integer; aValue: Byte);
    procedure WriteWaterMap(X, Y: Integer; aValue: Byte);
    procedure WriteZombieMap(X, Y: Integer; aValue: Byte);

    function CheckLemmingBlink: Boolean;
    function CheckRescueBlink: Boolean;
    function CheckTimerBlink: Boolean;

    function CheckSkillAvailable(aAction: TBasicLemmingAction): Boolean;
    procedure UpdateSkillCount(aAction: TBasicLemmingAction; Rev: Boolean = false);

    procedure ApplyWaterRise;

  { lemming actions }
    function HandleLemming(L: TLemming): Boolean;
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
    function HandleStoneOhNoing(L: TLemming): Boolean;
    function HandleStoneFinish(L: TLemming): Boolean;
    function HandleSwimming(L: TLemming): Boolean;
    function HandleGliding(L: TLemming): Boolean;
    function HandleFixing(L: TLemming): Boolean;

  { interaction }
    function AssignSkill(Lemming1, Lemming2: TLemming; aSkill: TBasicLemmingAction): Boolean; // key method

    function AssignWalker(Lemming1, Lemming2: TLemming): Boolean;
    function AssignClimber(Lemming1, Lemming2: TLemming): Boolean;
    function AssignSwimmer(Lemming1, Lemming2: TLemming): Boolean;
    function AssignFloater(Lemming1, Lemming2: TLemming): Boolean;
    function AssignGlider(Lemming1, Lemming2: TLemming): Boolean;
    function AssignMechanic(Lemming1, Lemming2: TLemming): Boolean;
    function AssignBomber(Lemming1, Lemming2: TLemming): Boolean;
    function AssignStoner(Lemming1, Lemming2: TLemming): Boolean;
    function AssignBlocker(Lemming1, Lemming2: TLemming): Boolean;
    function AssignPlatformer(Lemming1, Lemming2: TLemming): Boolean;
    function AssignBuilder(Lemming1, Lemming2: TLemming): Boolean;
    function AssignStacker(Lemming1, Lemming2: TLemming): Boolean;
    function AssignBasher(Lemming1, Lemming2: TLemming): Boolean;
    function AssignMiner(Lemming1, Lemming2: TLemming): Boolean;
    function AssignDigger(Lemming1, Lemming2: TLemming): Boolean;
    function AssignCloner(Lemming1, Lemming2: TLemming): Boolean;

    procedure OnAssignSkill(Lemming1: TLemming; aSkill: TBasicLemmingAction);

    procedure SetOptions(const Value: TDosGameOptions);
    procedure SetSoundOpts(const Value: TGameSoundOptions);
  public
    GameResult                     : Boolean;
    GameResultRec                  : TGameResultsRec;
    SkillButtonsDisabledWhenPaused : Boolean; // this really should move somewere else
    fSelectDx                  : Integer;
    fXmasPal                   : Boolean;
    UseReplayPhotoFlashEffect      : Boolean;
    fAssignEnabled                    : Boolean;
    InstReleaseRate            : Integer;
    fActiveSkills              : array[0..7] of TSkillPanelButton;
    fInfiniteTime               : Boolean;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  { iteration }
    procedure PrepareParams(aParams: TDosGameParams);
    procedure Start(aReplay: Boolean = False);
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
    property MiniMapBuffer: TBitmap32 read fMiniMapBuffer;
    property Options: TDosGameOptions read fOptions write SetOptions default DOSORIG_GAMEOPTIONS;
    property Paused: Boolean read fPaused write fPaused;
    property Playing: Boolean read fPlaying write fPlaying;
    property Renderer: TRenderer read fRenderer;
    property Replaying: Boolean read fReplaying;
    property Recorder: TRecorder read fRecorder;
    property RightMouseButtonHeldDown: Boolean read fRightMouseButtonHeldDown write fRightMouseButtonHeldDown;
    property ShiftButtonHeldDown: Boolean read fShiftButtonHeldDown write fShiftButtonHeldDown;
    property AltButtonHeldDown: Boolean read fAltButtonHeldDown write fAltButtonHeldDown;
    property CtrlButtonHeldDown: Boolean read fCtrlButtonHeldDown write fCtrlButtonHeldDown;
    property SlowingDownReleaseRate: Boolean read fSlowingDownReleaseRate;
    property SoundOpts: TGameSoundOptions read fSoundOpts write SetSoundOpts;
    property SpeedingUpReleaseRate: Boolean read fSpeedingUpReleaseRate;
    property TargetIteration: Integer read fTargetIteration write fTargetIteration;
    property DoTimePause: Boolean read fDoTimePause write fDoTimePause;
    property HitTestAutoFail: Boolean read fHitTestAutoFail write fHitTestAutoFail;
    property LastReplayDir: String read fLastReplayDir write fLastReplayDir;

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
  OBJMAPOFFSET = 16;
  OBJMAPADD = OBJMAPOFFSET;

const
  LEMMIX_REPLAY_VERSION    = 105;
  MAX_REPLAY_RECORDS       = 32768;
  MAX_FALLDISTANCE         = 62;
  MAX_LONGFALLDISTANCE     = 75;

  BOMBER_TIME = 1;

const
  // values for the (4 pixel resolution) Dos Object Map (for triggereffects)
  DOM_OFFSET           = 0; //192; // is this really needed anymore? probably not.
  DOM_NOOBJECT         = 65535;
  DOM_NONE             = DOM_OFFSET + 0;
  DOM_EXIT             = DOM_OFFSET + 1;
  DOM_FORCELEFT        = DOM_OFFSET + 2; // left arm of blocker
  DOM_FORCERIGHT       = DOM_OFFSET + 3; // right arm of blocker
  DOM_TRAP             = DOM_OFFSET + 4; // triggered trap
  DOM_WATER            = DOM_OFFSET + 5; // causes drowning
  DOM_FIRE             = DOM_OFFSET + 6; // causes vaporizing
  DOM_ONEWAYLEFT       = DOM_OFFSET + 7;
  DOM_ONEWAYRIGHT      = DOM_OFFSET + 8;
  DOM_STEEL            = DOM_OFFSET + 9;
  DOM_BLOCKER          = DOM_OFFSET + 10; // the middle part of blocker
  DOM_TELEPORT         = DOM_OFFSET + 11;
  DOM_RECEIVER         = DOM_OFFSET + 12;
  DOM_LEMMING          = DOM_OFFSET + 13;
  DOM_PICKUP           = DOM_OFFSET + 14;
  DOM_LOCKEXIT         = DOM_OFFSET + 15;
  DOM_SECRET           = DOM_OFFSET + 16;
  DOM_BUTTON           = DOM_OFFSET + 17;
  DOM_RADIATION        = DOM_OFFSET + 18;
  DOM_ONEWAYDOWN       = DOM_OFFSET + 19;
  DOM_UPDRAFT          = DOM_OFFSET + 20;
  DOM_FLIPPER          = DOM_OFFSET + 21;
  DOM_SLOWFREEZE       = DOM_OFFSET + 22;
  DOM_WINDOW           = DOM_OFFSET + 23;
  DOM_ANIMATION        = DOM_OFFSET + 24;
  DOM_HINT             = DOM_OFFSET + 25;
  DOM_NOSPLAT          = DOM_OFFSET + 26;
  DOM_SPLAT            = DOM_OFFSET + 27;
  DOM_TWOWAYTELE       = DOM_OFFSET + 28;
  DOM_SINGLETELE       = DOM_OFFSET + 29;
  DOM_BACKGROUND       = DOM_OFFSET + 30;
  DOM_TRAPONCE         = DOM_OFFSET + 31;

  // gimmick values. these do NOT always correspond to the order in the gimmick flags!
  // these numbers are just used as constants to identify them
  GIM_ANY              = 0;
  GIM_FRENZY           = 1;
  GIM_REVERSE          = 2;
  GIM_KAROSHI          = 3;
  GIM_UNALTERABLE      = 4;
  GIM_OVERFLOW         = 5;
  GIM_NOGRAVITY        = 6;
  GIM_HARDWORK         = 7;
  GIM_SUPERLEMMING     = 8;
  GIM_BACKWARDS        = 9;
  GIM_LAZY             = 10;
  GIM_EXHAUSTION       = 11;
  GIM_SURVIVOR         = 12;
  GIM_INVINCIBLE       = 13;
  GIM_ONESKILL         = 14;
  GIM_INVERTSTEEL      = 15;
  GIM_SOLIDFLOOR       = 16;
  GIM_NONPERMANENT     = 17;
  GIM_DISOBEDIENT      = 18;
  GIM_NUCLEAR          = 19;
  GIM_TURNAROUND       = 20;
  GIM_OTHERSKILL       = 21;
  GIM_ASSIGNALL        = 22;
  GIM_WRAP_HOR         = 23;
  GIM_WRAP_VER         = 24;
  GIM_RISING_WATER     = 25;
  GIM_ZOMBIES          = 26;
  GIM_OLDZOMBIES       = 27;
  GIM_DEADLYSIDES      = 28;
  GIM_GHOSTS           = 29;
  GIM_CHEAPOMODE       = 30;
  GIM_DEATHGHOST       = 31;
  GIM_INVERTFALL       = 32;
  GIM_CLONEASSIGN      = 33;
  GIM_INSTANTPICKUP    = 34;
  GIM_DEATHZOMBIE      = 35;
  GIM_PERMANENTBLOCK   = 36;
  GIM_RRFLUC           = 37; 

  // removal modes
  RM_NEUTRAL           = 0;
  RM_SAVE              = 1;
  RM_KILL              = 2;
  RM_ZOMBIE            = 3;
  RM_GHOST             = 4;

  FRENZY_MUSIC         = 'frenzy';
  GIMMICK_MUSIC        = 'gimmick';

  HEAD_MIN_Y = -7;
  //LEMMING_MIN_X = 0;
  //LEMMING_MAX_X = 1647;
  LEMMING_MAX_Y = 9;

  PARTICLE_FRAMECOUNT = 52;
  PARTICLE_FINISH_FRAMECOUNT = 52;

function CheckRectCopy(const A, B: TRect): Boolean;
begin
  Result := (RectWidth(A) = RectWidth(B))
            and (Rectheight(A) = Rectheight(B));
end;

{ TLemming }

function TLemming.GetCountDownDigitBounds: TRect;
begin
  with Result do
  begin
    Left := LemX - 1;
    Top := LemY + FrameTopDy - 12;
    Right := Left + 8;
    Bottom := Top + 8;
  end;
end;



function TLemming.GetFrameBounds(Nuclear: Boolean = false): TRect;
begin
  Assert(LAB <> nil, 'getframebounds error');
  with Result do
  begin
    Left := 0;
    Top := LemFrame * LMA.Height;
    Right := LMA.Width;
    Bottom := Top + LMA.Height;
    if (LemAction in [baExploding]) and Nuclear then
    begin
      Right := Right + 32;
      Bottom := Bottom + 32;
    end;
  end;
end;

function TLemming.GetLocationBounds(Nuclear: Boolean = false): TRect;
begin
  Assert(LMA <> nil, 'meta animation error');
  with Result do
  begin
    Left := LemX - LMA.FootX;
    Top := LemY - LMA.FootY;
    Right := Left + LMA.Width;
    Bottom := Top + LMA.Height;
    {if (LemDX = -1) and (LemAction in [baWalking, baBuilding, baPlatforming, baStacking]) then
      begin
      Dec(Left);
      Dec(Right);
      end;}
    //if LemRTLAdjust then
    //begin
    //  Dec(Left);
    //  Dec(Right);
    //end;
    if (LemAction in [baDigging, baFixing]) and LemRTL then
    begin
      Inc(Left);
      Inc(Right);
    end;
    if (LemAction in [baExploding]) and Nuclear then
    begin
      Left := Left - 16;
      Top := Top - 16;
      Right := Right + 16;
      Bottom := Bottom + 16;
    end;        // Easier to do here than a seperate anim just for nukers
    if (LemAction = baMining) then
      begin
        if LemRTL then
        begin
          Dec(Left);
          Dec(Right);
        end else begin
          Inc(Left);
          Inc(Right);
        end;
        if (LemFrame < 15) then
          begin
          Inc(Top);
          Inc(Bottom);
          end;
      end;  // Seems to be glitchy if the animations themself are altered
  end;
end;

function TLemming.GetLemRTL: Boolean;
begin
  Result := LemDx < 0;
end;

function TLemming.GetLemHint: string;
const
  BoolStrings: array[Boolean] of string = ('false', 'true');
begin
  Result := 'Action=' + CutLeft(GetEnumName(TypeInfo(TBasicLemmingAction), Integer(LemAction)), 2) + ', ' +
            'Index=' + i2s(LemIndex) + ', ' +
            'X=' + i2s(LemX) + ', ' +
            'Y=' + i2s(LemY) + ', ' +
            'Dx=' + i2s(LemDX) + ', ' +
            'Fallen=' + i2s(LemFallen) + ', ' +
            'ExplosionTimer=' + i2s(LemExplosionTimer) + ', ' +
            'Frame=' + i2s(LemFrame) + ', ' +
            'MaxFrame=' + i2s(LemMaxFrame) + ', ' +
            'FrameLeftDx=' + i2s(FrameLeftDx) + ', ' +
            'FrameTopDy=' + i2s(FrameTopDy) + ', ' +
            'FloatParamTableIndex=' + i2s(LemFloatParametersTableIndex) + ', ' +
            'NumberOfBricksLeft=' + i2s(LemNumberOfBricksLeft) + ', ' +
            'Born=' + i2s(LemBorn) + ', ' +
            'ObjBelow=' + i2s(LemObjectBelow) + ', ' +
            'ObjInFront=' + i2s(LemObjectInFront) + ', ' +
            'IsNewDigger=' + BoolStrings[LemIsNewDigger] + ', ' +
            'IsBlocking=' + i2s(LemIsBlocking) + ', ' +
            'CanClimb=' + BoolStrings[LemIsClimber] + ', ' +
            'CanFloat=' + BoolStrings[LemIsFloater];

// LemSavedMap, LemObjectBelow, LemObjectInFront
end;

procedure TLemming.Assign(Source: TLemming);
begin

  // does NOT copy LemIndex! This is intentional //
  LemEraseRect := Source.LemEraseRect;
  LemX := Source.LemX;
  LemY := Source.LemY;
  LemDX := Source.LemDX;
  LemParticleX := Source.LemParticleX;
  LemParticleY := Source.LemParticleY;
  LemJumped := Source.LemJumped;
  LemFallen := Source.LemFallen;
  LemTrueFallen := Source.LemTrueFallen;
  LemOldFallen := Source.LemOldFallen;
  LemFloated := Source.LemFloated;
  LemClimbed := Source.LemClimbed;
  LemClimbStartY := Source.LemClimbStartY;
  LemFirstClimb := Source.LemFirstClimb;
  LemExplosionTimer := Source.LemExplosionTimer;
  LemMechanicFrames := Source.LemMechanicFrames;
  LMA := Source.LMA;
  LAB := Source.LAB;
  LemFrame := Source.LemFrame;
  LemMaxFrame := Source.LemMaxFrame;
  LemAnimationType := Source.LemAnimationType;
  LemParticleTimer := Source.LemParticleTimer;
  LemParticleFrame := Source.LemParticleFrame;
  FrameTopDy := Source.FrameTopDy;
  FrameLeftDx := Source.FrameLeftDx;
  LemFloatParametersTableIndex := Source.LemFloatParametersTableIndex;
  LemNumberOfBricksLeft := Source.LemNumberOfBricksLeft;
  LemBorn := Source.LemBorn;

  LemAction := Source.LemAction;
  LemObjectBelow := Source.LemObjectBelow;
  LemObjectIDBelow := Source.LemObjectIDBelow;
  LemSpecialBelow := Source.LemSpecialBelow;
  LemObjectInFront := Source.LemObjectInFront;
  LemRemoved := Source.LemRemoved;
  LemTeleporting := Source.LemTeleporting;
  LemEndOfAnimation := Source.LemEndOfAnimation;
  LemIsClimber := Source.LemIsClimber;
  LemIsSwimmer := Source.LemIsSwimmer;
  LemIsFloater := Source.LemIsFloater;
  LemIsGlider := Source.LemIsGlider;
  LemIsMechanic := Source.LemIsMechanic;
  LemIsZombie := Source.LemIsZombie;
  LemIsGhost := Source.LemIsGhost;
  LemCouldPlatform := Source.LemCouldPlatform;
  LemInFlipper := Source.LemInFlipper;
  LemIsBlocking := Source.LemIsBlocking;
  LemBecomeBlocker := Source.LemBecomeBlocker;
  LemIsNewDigger := Source.LemIsNewDigger;
  LemHighlightReplay := Source.LemHighlightReplay;
  LemExploded := Source.LemExploded;
  LemUsedSkillCount := Source.LemUsedSkillCount;
  LemIsClone := Source.LemIsClone;
  LemTimerToStone := Source.LemTimerToStone;
  LemStackLow := Source.LemStackLow;
  LemRTLAdjust := Source.LemRTLAdjust;
  LemInTrap := Source.LemInTrap;
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

{ TLemmingGameSavedState }

constructor TLemmingGameSavedState.Create;
begin
  inherited;
  LemmingList := TLemmingList.Create(true);
  ObjectInfos := TInteractiveObjectInfoList.Create(true);
  TargetBitmap := TBitmap32.Create;
  World := TBitmap32.Create;
  SteelWorld := TBitmap32.Create;
  ObjectMap := TByteMap.Create;
  BlockerMap := TByteMap.Create;
  SpecialMap := TByteMap.Create;
  WaterMap := TByteMap.Create;
  ZombieMap := TByteMap.Create;
end;

destructor TLemmingGameSavedState.Destroy;
begin
  LemmingList.Free;
  ObjectInfos.Free;
  TargetBitmap.Free;
  World.Free;
  SteelWorld.Free;
  ObjectMap.Free;
  BlockerMap.Free;
  SpecialMap.Free;
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

procedure TLemmingGame.UpdateLemmingsHatch;
begin
  InfoPainter.SetInfoLemmingsAlive((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsOut + LemmingsRemoved), false);
end;

procedure TLemmingGame.UpdateLemmingsAlive;
begin
  InfoPainter.SetInfoLemmingsOut((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsRemoved), CheckLemmingBlink);
end;

procedure TLemmingGame.UpdateLemmingsSaved;
begin
  UpdateLemmingsIn(LemmingsIn, 0);
end;

procedure TLemmingGame.UpdateTimeLimit;
begin
  if (Minutes >= 0) and (Seconds >= 0) then
  begin
    InfoPainter.SetInfoMinutes(Minutes, CheckTimerBlink);
    InfoPainter.SetInfoSeconds(Seconds, CheckTimerBlink);
  end else begin
    if Seconds > 0 then
      InfoPainter.SetInfoMinutes(abs(Minutes + 1), CheckTimerBlink)
    else
      InfoPainter.SetInfoMinutes(abs(Minutes), CheckTimerBlink);
    InfoPainter.SetInfoSeconds((60 - Seconds) mod 60, CheckTimerBlink);
  end;
end;

procedure TLemmingGame.UpdateOneSkillCount(aSkill: TSkillPanelButton);
begin
  case aSkill of
    spbWalker: InfoPainter.DrawSkillCount(spbWalker, CurrWalkerCount);
    spbClimber: InfoPainter.DrawSkillCount(spbClimber, CurrClimberCount);
    spbSwimmer: InfoPainter.DrawSkillCount(spbSwimmer, CurrSwimmerCount);
    spbUmbrella: InfoPainter.DrawSkillCount(spbUmbrella, CurrFloaterCount);
    spbGlider: InfoPainter.DrawSkillCount(spbGlider, CurrGliderCount);
    spbMechanic: InfoPainter.DrawSkillCount(spbMechanic, CurrMechanicCount);
    spbExplode: InfoPainter.DrawSkillCount(spbExplode, CurrBomberCount);
    spbStoner: InfoPainter.DrawSkillCount(spbStoner, CurrStonerCount);
    spbBlocker: InfoPainter.DrawSkillCount(spbBlocker, CurrBlockerCount);
    spbPlatformer: InfoPainter.DrawSkillCount(spbPlatformer, CurrPlatformerCount);
    spbBuilder: InfoPainter.DrawSkillCount(spbBuilder, CurrBuilderCount);
    spbStacker: InfoPainter.DrawSkillCount(spbStacker, CurrStackerCount);
    spbBasher: InfoPainter.DrawSkillCount(spbBasher, CurrBasherCount);
    spbMiner: InfoPainter.DrawSkillCount(spbMiner, CurrMinerCount);
    spbDigger: InfoPainter.DrawSkillCount(spbDigger, CurrDiggerCount);
    spbCloner: InfoPainter.DrawSkillCount(spbCloner, CurrClonerCount);
    spbSlower: InfoPainter.DrawSkillCount(spbSlower, Level.Info.ReleaseRate);
    spbFaster: InfoPainter.DrawSkillCount(spbFaster, CurrReleaseRate);
  end;
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
  CheckItem: TReplayItem;
begin
  // Simple stuff
  aState.SelectedSkill := fSelectedSkill;
  aState.TargetBitmap.Assign(fTargetBitmap);
  aState.World.Assign(World);
  aState.SteelWorld.Assign(SteelWorld);
  aState.ObjectMap.Assign(ObjectMap);
  aState.BlockerMap.Assign(BlockerMap);
  aState.SpecialMap.Assign(SpecialMap);
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
  aState.Minutes := Minutes;
  aState.Seconds := Seconds;
  aState.EntriesOpened := EntriesOpened;
  aState.LowestReleaseRate := LowestReleaseRate;
  aState.HighestReleaseRate := HighestReleaseRate;
  aState.CurrReleaseRate := CurrReleaseRate;
  aState.LastReleaseRate := LastReleaseRate;
  aState.CurrWalkerCount := CurrWalkerCount;
  aState.UsedWalkerCount := UsedWalkerCount;
  aState.CurrClimberCount := CurrClimberCount;
  aState.UsedClimberCount := UsedClimberCount;
  aState.CurrSwimmerCount := CurrSwimmerCount;
  aState.UsedSwimmerCount := UsedSwimmerCount;
  aState.CurrFloaterCount := CurrFloaterCount;
  aState.UsedFloaterCount := UsedFloaterCount;
  aState.CurrGliderCount := CurrGliderCount;
  aState.UsedGliderCount := UsedGliderCount;
  aState.CurrMechanicCount := CurrMechanicCount;
  aState.UsedMechanicCount := UsedMechanicCount;
  aState.CurrBomberCount := CurrBomberCount;
  aState.UsedBomberCount := UsedBomberCount;
  aState.CurrStonerCount := CurrStonerCount;
  aState.UsedStonerCount := UsedStonerCount;
  aState.CurrBlockerCount := CurrBlockerCount;
  aState.UsedBlockerCount := UsedBlockerCount;
  aState.CurrPlatformerCount := CurrPlatformerCount;
  aState.UsedPlatformerCount := UsedPlatformerCount;
  aState.CurrBuilderCount := CurrBuilderCount;
  aState.UsedBuilderCount := UsedBuilderCount;
  aState.CurrStackerCount := CurrStackerCount;
  aState.UsedStackerCount := UsedStackerCount;
  aState.CurrBasherCount := CurrBasherCount;
  aState.UsedBasherCount := UsedBasherCount;
  aState.CurrMinerCount := CurrMinerCount;
  aState.UsedMinerCount := UsedMinerCount;
  aState.CurrDiggerCount := CurrDiggerCount;
  aState.UsedDiggerCount := UsedDiggerCount;
  aState.CurrClonerCount := CurrClonerCount;
  aState.UsedClonerCount := UsedClonerCount;
  aState.UserSetNuking := UserSetNuking;
  aState.Index_LemmingToBeNuked := Index_LemmingToBeNuked;
  aState.LastRecordedRR := fLastRecordedRR;

  // Lemmings. Thank fuck for their Assign method.
  aState.LemmingList.Clear;
  for i := 0 to LemmingList.Count-1 do
  begin
    aState.LemmingList.Add(TLemming.Create);
    aState.LemmingList[i].Assign(LemmingList[i]);
  end;

  // Objects. This doesn't have an Assign so have to do it manually. (Or write one...)
  aState.ObjectInfos.Clear;
  for i := 0 to ObjectInfos.Count-1 do
  begin
    aState.ObjectInfos.Add(TInteractiveObjectInfo.Create);
    aState.ObjectInfos[i].MetaObj := ObjectInfos[i].MetaObj;
    aState.ObjectInfos[i].Obj := ObjectInfos[i].Obj;
    aState.ObjectInfos[i].CurrentFrame := ObjectInfos[i].CurrentFrame;
    aState.ObjectInfos[i].Triggered := ObjectInfos[i].Triggered;
    aState.ObjectInfos[i].TeleLem := ObjectInfos[i].TeleLem;
    aState.ObjectInfos[i].HoldActive := ObjectInfos[i].HoldActive;
    aState.ObjectInfos[i].ZombieMode := ObjectInfos[i].ZombieMode;
    aState.ObjectInfos[i].TwoWayReceive := ObjectInfos[i].TwoWayReceive;
    aState.ObjectInfos[i].TotalFactor := ObjectInfos[i].TotalFactor;
    aState.ObjectInfos[i].OffsetX := ObjectInfos[i].Obj.OffsetX;
    aState.ObjectInfos[i].OffsetY := ObjectInfos[i].Obj.OffsetY;
    aState.ObjectInfos[i].Left := ObjectInfos[i].Obj.Left;
    aState.ObjectInfos[i].Top := ObjectInfos[i].Obj.Top;
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
  for i := 0 to fRecorder.Count-1 do
    if TReplayItem(fRecorder.List[i]).Iteration = aState.CurrentIteration then Result := false;
  if not Result then Exit;

  // First, some preparation, eg. undraw the selection rectangle for the selected skill
  InfoPainter.DrawButtonSelector(fSelectedSkill, false);

  // Simple stuff
  if not fGameParams.IgnoreReplaySelection then
    fSelectedSkill := aState.SelectedSkill;
  if not SkipTargetBitmap then  // We don't need to bother with this one if we're not loading the exact frame we want to go to
    fTargetBitmap.Assign(aState.TargetBitmap);
  World.Assign(aState.World);
  SteelWorld.Assign(aState.SteelWorld);
  ObjectMap.Assign(aState.ObjectMap);
  BlockerMap.Assign(aState.BlockerMap);
  SpecialMap.Assign(aState.SpecialMap);
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
  Minutes := aState.Minutes;
  Seconds := aState.Seconds;
  EntriesOpened := aState.EntriesOpened;
  LowestReleaseRate := aState.LowestReleaseRate;
  HighestReleaseRate := aState.HighestReleaseRate;
  CurrReleaseRate := aState.CurrReleaseRate;
  LastReleaseRate := aState.LastReleaseRate;
  CurrWalkerCount := aState.CurrWalkerCount;
  UsedWalkerCount := aState.UsedWalkerCount;
  CurrClimberCount := aState.CurrClimberCount;
  UsedClimberCount := aState.UsedClimberCount;
  CurrSwimmerCount := aState.CurrSwimmerCount;
  UsedSwimmerCount := aState.UsedSwimmerCount;
  CurrFloaterCount := aState.CurrFloaterCount;
  UsedFloaterCount := aState.UsedFloaterCount;
  CurrGliderCount := aState.CurrGliderCount;
  UsedGliderCount := aState.UsedGliderCount;
  CurrMechanicCount := aState.CurrMechanicCount;
  UsedMechanicCount := aState.UsedMechanicCount;
  CurrBomberCount := aState.CurrBomberCount;
  UsedBomberCount := aState.UsedBomberCount;
  CurrStonerCount := aState.CurrStonerCount;
  UsedStonerCount := aState.UsedStonerCount;
  CurrBlockerCount := aState.CurrBlockerCount;
  UsedBlockerCount := aState.UsedBlockerCount;
  CurrPlatformerCount := aState.CurrPlatformerCount;
  UsedPlatformerCount := aState.UsedPlatformerCount;
  CurrBuilderCount := aState.CurrBuilderCount;
  UsedBuilderCount := aState.UsedBuilderCount;
  CurrStackerCount := aState.CurrStackerCount;
  UsedStackerCount := aState.UsedStackerCount;
  CurrBasherCount := aState.CurrBasherCount;
  UsedBasherCount := aState.UsedBasherCount;
  CurrMinerCount := aState.CurrMinerCount;
  UsedMinerCount := aState.UsedMinerCount;
  CurrDiggerCount := aState.CurrDiggerCount;
  UsedDiggerCount := aState.UsedDiggerCount;
  CurrClonerCount := aState.CurrClonerCount;
  UsedClonerCount := aState.UsedClonerCount;
  UserSetNuking := aState.UserSetNuking;
  Index_LemmingToBeNuked := aState.Index_LemmingToBeNuked;
  fLastRecordedRR := aState.LastRecordedRR;

  // Lemmings. Thank fuck for their Assign method.
  LemmingList.Clear;
  for i := 0 to aState.LemmingList.Count-1 do
  begin
    LemmingList.Add(TLemming.Create);
    LemmingList[i].Assign(aState.LemmingList[i]);
    LemmingList[i].LemIndex := i;
    if fHighlightLemmingID = i then
      fHighlightLemming := LemmingList[i];
  end;

  // Objects. This doesn't have an Assign so have to do it manually. (Or write one...)
  //ObjectInfos.Clear;
  for i := 0 to ObjectInfos.Count-1 do
  begin
    //ObjectInfos.Add(TInteractiveObjectInfo.Create);
    ObjectInfos[i].MetaObj := aState.ObjectInfos[i].MetaObj;
    ObjectInfos[i].Obj := aState.ObjectInfos[i].Obj;
    ObjectInfos[i].CurrentFrame := aState.ObjectInfos[i].CurrentFrame;
    ObjectInfos[i].Triggered := aState.ObjectInfos[i].Triggered;
    ObjectInfos[i].TeleLem := aState.ObjectInfos[i].TeleLem;
    ObjectInfos[i].HoldActive := aState.ObjectInfos[i].HoldActive;
    ObjectInfos[i].ZombieMode := aState.ObjectInfos[i].ZombieMode;
    ObjectInfos[i].TwoWayReceive := aState.ObjectInfos[i].TwoWayReceive;
    ObjectInfos[i].TotalFactor := aState.ObjectInfos[i].TotalFactor;
    ObjectInfos[i].Obj.OffsetX := aState.ObjectInfos[i].OffsetX;
    ObjectInfos[i].Obj.OffsetY := aState.ObjectInfos[i].OffsetY;
    ObjectInfos[i].Obj.Left := aState.ObjectInfos[i].Left;
    ObjectInfos[i].Obj.Top := aState.ObjectInfos[i].Top;
  end;

  // When loading, we must update the info panel. But if we're just using the state
  // for an approximate location, we don't need to do this, it just results in graphical
  // glitching as the values from load time are shown for a split second.
  if not SkipTargetBitmap then
    RefreshAllPanelInfo;

  // And we must get the replay index to the right point and activate replay mode
  fReplaying := true;
  fReplayIndex := fRecorder.FindIndexForFrame(fCurrentIteration);
  InfoPainter.SetReplayMark(true);
end;

procedure TLemmingGame.RefreshAllPanelInfo;
begin
  InfoPainter.DrawButtonSelector(fSelectedSkill, true);
  UpdateLemmingsHatch;
  UpdateLemmingsAlive;
  UpdateLemmingsSaved;
  UpdateTimeLimit;
  UpdateAllSkillCounts;
end;

procedure TLemmingGame.DoTalismanCheck(SecretTrigger: Boolean = false);
var
  i, i2: Integer;
  ts: Integer;
  FoundIssue: Boolean;
  UsedSkillLems: Integer;
begin
  //if fGameParams.LookForLVLFiles or (StrToIntDef('0x' + fGameParams.ForceGimmick, 0) <> 0) then Exit; // no talismans if gimmick-forcing or using LookForLVLFiles
  for i := 0 to fTalismans.Count-1 do
  begin
    if fGameParams.SaveSystem.CheckTalisman(fTalismans[i].Signature) then Continue;
    with fTalismans[i] do
    begin
      if not SecretTrigger then
        if ((LemmingsIn < SaveRequirement) or ((SaveRequirement = 0) and (LemmingsIn < fGameParams.Level.Info.RescueCount))) then Continue;

      if ((CurrentIteration > TimeLimit) and (TimeLimit <> 0)) or ((TimeLimit = 0) and (CurrentIteration > Level.Info.TimeLimit * 17)) then Continue;
      if LowestReleaseRate < RRMin then Continue;
      if HighestReleaseRate > RRMax then Continue;

      if (UsedWalkerCount > SkillLimit[0]) and (SkillLimit[0] <> -1) then Continue;
      if (UsedClimberCount > SkillLimit[1]) and (SkillLimit[1] <> -1) then Continue;
      if (UsedSwimmerCount > SkillLimit[2]) and (SkillLimit[2] <> -1) then Continue;
      if (UsedFloaterCount > SkillLimit[3]) and (SkillLimit[3] <> -1) then Continue;
      if (UsedGliderCount > SkillLimit[4]) and (SkillLimit[4] <> -1) then Continue;
      if (UsedMechanicCount > SkillLimit[5]) and (SkillLimit[5] <> -1) then Continue;
      if (UsedBomberCount > SkillLimit[6]) and (SkillLimit[6] <> -1) then Continue;
      if (UsedStonerCount > SkillLimit[7]) and (SkillLimit[7] <> -1) then Continue;
      if (UsedBlockerCount > SkillLimit[8]) and (SkillLimit[8] <> -1) then Continue;
      if (UsedPlatformerCount > SkillLimit[9]) and (SkillLimit[9] <> -1) then Continue;
      if (UsedBuilderCount > SkillLimit[10]) and (SkillLimit[10] <> -1) then Continue;
      if (UsedStackerCount > SkillLimit[11]) and (SkillLimit[11] <> -1) then Continue;
      if (UsedBasherCount > SkillLimit[12]) and (SkillLimit[12] <> -1) then Continue;
      if (UsedMinerCount > SkillLimit[13]) and (SkillLimit[13] <> -1) then Continue;
      if (UsedDiggerCount > SkillLimit[14]) and (SkillLimit[14] <> -1) then Continue;
      if (UsedClonerCount > SkillLimit[15]) and (SkillLimit[15] <> -1) then Continue;

      ts := UsedWalkerCount + UsedClimberCount + UsedSwimmerCount + UsedFloaterCount
          + UsedGliderCount + UsedMechanicCount + UsedBomberCount + UsedStonerCount
          + UsedBlockerCount + UsedPlatformerCount + UsedBuilderCount + UsedStackerCount
          + UsedBasherCount + UsedMinerCount + UsedDiggerCount + UsedClonerCount;

      if (ts > TotalSkillLimit) and (TotalSkillLimit <> -1) then Continue;

      if SecretTrigger and not (tmFindSecret in MiscOptions) then Continue;

      FoundIssue := false;
      if tmOneSkill in MiscOptions then
        for i2 := 0 to LemmingList.Count-1 do
          with LemmingList[i2] do
           if (LemUsedSkillCount > 1) {and not LemIsClone} then FoundIssue := true;
      if FoundIssue then Continue;

      UsedSkillLems := 0;
      if tmOneLemming in MiscOptions then
        for i2 := 0 to LemmingList.Count-1 do
          with LemmingList[i2] do
          begin
            if (LemUsedSkillCount > 0) and not LemIsClone then Inc(UsedSkillLems);
            if (LemUsedSkillCount > 1) and LemIsClone then Inc(UsedSkillLems);
          end;
      if UsedSkillLems > 1 then Continue;

      fGameParams.SaveSystem.GetTalisman(Signature);
      if TalismanType <> 0 then fTalismanReceived := true;
    end;
  end;
end;

function TLemmingGame.Checkpass: Boolean;
begin
  Result := (fGameCheated or (LemmingsIn >= Level.Info.RescueCount))
            and (fSecretGoto = -1);
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

  LemmingList    := TLemmingList.Create;
  World          := TBitmap32.Create;
  SteelWorld     := TBitmap32.Create;
  ExplodeMaskBmp := TBitmap32.Create;
  ObjectInfos    := TInteractiveObjectInfoList.Create;
  Entries        := TInteractiveObjectInfoList.Create;
  ObjectMap      := TByteMap.Create;
  BlockerMap     := TByteMap.Create;
  SpecialMap     := TByteMap.Create;
  ZombieMap      := TByteMap.Create;
  WaterMap       := TByteMap.Create;
  MiniMap        := TBitmap32.Create;
  fMinimapBuffer := TBitmap32.Create;
  fRecorder      := TRecorder.Create(Self);
  fOptions       := DOSORIG_GAMEOPTIONS;
  SoundMgr       := TSoundMgr.Create;
  fTalismans     := TTalismans.Create;

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
  LemmingMethods[baStoning]    := HandleStoneOhNoing;
  LemmingMethods[baStoneFinish] := HandleStoneFinish;
  LemmingMethods[baSwimming]   := HandleSwimming;
  LemmingMethods[baGliding]    := HandleGliding;
  LemmingMethods[baFixing]     := HandleFixing;

  SkillMethods[baNone]         := nil;
  SkillMethods[baWalking]      := nil;
  SkillMethods[baJumping]      := nil;
  SkillMethods[baDigging]      := AssignDigger;
  SkillMethods[baClimbing]     := AssignClimber;
  SkillMethods[baDrowning]     := nil;
  SkillMethods[baHoisting]     := nil;
  SkillMethods[baBuilding]     := AssignBuilder;
  SkillMethods[baBashing]      := AssignBasher;
  SkillMethods[baMining]       := AssignMiner;
  SkillMethods[baFalling]      := nil;
  SkillMethods[baFloating]     := AssignFloater;
  SkillMethods[baSplatting]    := nil;
  SkillMethods[baExiting]      := nil;
  SkillMethods[baVaporizing]   := nil;
  SkillMethods[baBlocking]     := AssignBlocker;
  SkillMethods[baShrugging]    := nil;
  SkillMethods[baOhnoing]      := nil;
  SkillMethods[baExploding]    := AssignBomber;
  SkillMethods[baToWalking]    := AssignWalker;
  SkillMethods[baPlatforming]  := AssignPlatformer;
  SkillMethods[baStacking]     := AssignStacker;
  SkillMethods[baStoning]      := AssignStoner;
  SkillMethods[baSwimming]     := AssignSwimmer;
  SkillMethods[baGliding]      := AssignGlider;
  SkillMethods[baFixing]       := AssignMechanic;
  SkillMethods[baCloning]      := AssignCloner;

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
  World.Free;
  SteelWorld.Free;
  Entries.Free;
  ObjectMap.Free;
  BlockerMap.Free;
  SpecialMap.Free;
  ZombieMap.Free;
  WaterMap.Free;
  MiniMap.Free;
  fMinimapBuffer.Free;
  fRecorder.Free;
  SoundMgr.Free;
  ExplodeMaskBmp.Free;
  fTalismans.Free;
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
  SL.LoadFromStream(TempStream); //conveniently, if the above returns nil, this throws an exception, triggering the special handling :D
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
  Bmp, Bmp2: TBitmap32;
  LowPal, HiPal, Pal: TArrayOfColor32;
  MusicSys: TBaseMusicSystem;
  //LemBlack: TColor32;
  S: TStream;
  MusicFileName: String;
  x, y: Integer;
begin
  fGameParams := aParams;
  fXmasPal := fGameParams.SysDat.Options2 and 2 <> 0;

  fStartupMusicAfterEntry := True;

  fSoundOpts := fGameParams.SoundOptions;
  fUseGradientBridges := moGradientBridges in fGameParams.MiscOptions;

  fRenderer := fGameParams.Renderer; // set ref
  fTargetBitmap := fGameParams.TargetBitmap;
  Level := fGameParams.Level;
  Style := fGameParams.Style;
  Graph := fGameParams.GraphicSet;

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
    HiPal[i] := Graph.Palette[i+8];
  LowPal[7] := Graph.BrickColor; // copy the brickcolor
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
    Ani.LemmingPrefix := Graph.LemmingSprites;
  Ani.ReadData;

  // initialize explosion particle colors
  for i := 0 to 15 do
    fParticleColors[i] := Pal[ParticleColorIndices[i]];

  // prepare masks for drawing
  CntDownBmp := Ani.CountDownDigitsBitmap;
  CntDownBmp.DrawMode := dmCustom;
  CntDownBmp.OnPixelCombine := CombineDefaultPixels;

  HighlightBmp := Ani.HighlightBitmap;
  HighlightBmp.DrawMode := dmCustom;
  HighlightBmp.OnPixelCombine := CombineDefaultPixels;

  ExplodeMaskBmp.Assign(Ani.ExplosionMaskBitmap);
  ExplodeMaskBmp.DrawMode := dmCustom;
  ExplodeMaskBmp.OnPixelCombine := CombineMaskPixels;

  if not fGameParams.NoAdjustBomberMask then
  begin
    with ExplodeMaskBmp do
    begin
      for y := 21 downto 0 do
        for x := 7 downto 0 do
        begin
          PixelS[15-x, y] := PixelS[x, y];
          {PixelS[x+1, y] := PixelS[x, y];}
        end;
      {for y := 0 to 21 do
        PixelS[0, y] := 0;}
    end;
  end;

  if (fGameParams.Level.Info.GimmickSet and $40000) <> 0 then
  begin
    with ExplodeMaskBmp do
    begin
      Width := 48;//Width * 3;
      Height := 66;//Height * 3;
      for y := 65 downto 0 do
        for x := 23 downto 0 do
        begin
          PixelS[x, y] := Ani.ExplosionMaskBitmap.PixelS[x div 3, y div 3];
          PixelS[47-x, y] := Ani.ExplosionMaskBitmap.PixelS[x div 3, y div 3];
        end;
    end;
    Bmp := TBitmap32.Create;
    Bmp.Assign(ExplodeMaskBmp);
    for y := 0 to 65 do
      for x := 0 to 23 do
      begin
        i := 0;
        with ExplodeMaskBmp do
        begin
          if (PixelS[x+1,y+1]) <> 0 then Inc(i);
          if (PixelS[x+1,y-1]) <> 0 then Inc(i);
          if (PixelS[x-1,y+1]) <> 0 then Inc(i);
          if (PixelS[x-1,y-1]) <> 0 then Inc(i);
        end;
        if i >= 2 then
        begin
          Bmp.PixelS[x, y] := $FFFFFFFF;
          Bmp.PixelS[47-x, y] := $FFFFFFFF;
        end;
      end;
    ExplodeMaskBmp.Assign(Bmp);
    Bmp.Free;
  end;

  fHighlightLemmingID := -1;

  BashMasks := Ani.BashMasksBitmap;
  BashMasks.DrawMode := dmCustom;
  BashMasks.OnPixelCombine := CombineMaskPixels;

  BashMasksRTL := Ani.BashMasksRTLBitmap;
  BashMasksRTL.DrawMode := dmCustom;
  BashMasksRTL.OnPixelCombine := CombineMaskPixels;

  MineMasks := Ani.MineMasksBitmap;
  MineMasks.DrawMode := dmCustom;
  MineMasks.OnPixelCombine := CombineMaskPixels;

  MineMasksRTL := Ani.MineMasksRTLBitmap;
  MineMasksRTL.DrawMode := dmCustom;
  MineMasksRTL.OnPixelCombine := CombineMaskPixels;

  // prepare animationbitmaps for drawing (set eventhandlers)
  with Ani.LemmingAnimations do
    for i := 0 to Count - 1 do
    begin
      Bmp := List^[i];
      Bmp.DrawMode := dmCustom;
      if i in [BRICKLAYING, BRICKLAYING_RTL, PLATFORMING, PLATFORMING_RTL] then
        Bmp.OnPixelCombine := CombineBuilderPixels
      else
        Bmp.OnPixelCombine := CombineLemmingPixels;
      if (i = Explosion) and ((fGameParams.Level.Info.GimmickSet and $40000) <> 0) then
      With Bmp do
      begin
        Bmp2 := TBitmap32.Create;
        Bmp2.Assign(Bmp);
        Width := 64;//Width * 3;
        Height := 64;//Height * 3;
        for y := Height-1 downto 0 do
          for x := Width-1 downto 0 do
            PixelS[x, y] := Bmp2.PixelS[x div 2, y div 2];
        Bmp2.Free;
      end;
    end;

  StoneLemBmp := Ani.LemmingAnimations.Items[STONED];
  StoneLemBmp.DrawMode := dmCustom;
  StoneLemBmp.OnPixelCombine := CombineNoOverwriteStoner;

  World.SetSize(Level.Info.Width, Level.Info.Height);
  SteelWorld.SetSize(Level.Info.Width, Level.Info.Height);

  //if StrToInt('x' + fGameParams.ForceGimmick) <> 0 then Level.Info.SuperLemming := StrToInt('x' + fGameParams.ForceGimmick);

  Gimmick := Level.Info.SuperLemming;
  GimmickSet := Level.Info.GimmickSet;
  GimmickSet2 := Level.Info.GimmickSet2;
  GimmickSet3 := Level.Info.GimmickSet3;

  MusicSys := fGameParams.Style.MusicSystem;
  MusicFileName := GetMusicFileName;
  if (MusicSys <> nil) and (MusicFileName <> '') then
    try
      SoundMgr.AddMusicFromFileName(MusicFileName, fGameParams.fTestMode);
    except
      SoundMgr.Musics.Clear;
      Level.Info.MusicFile := '';
      try
        MusicFileName := GetMusicFileName;
        SoundMgr.AddMusicFromFileName(MusicFileName, fGameParams.fTestMode);
      except
        // silent fail, just play no music
      end;
    end;

  S := CreateDataStream('explode.dat', ldtParticles);
  S.Seek(0, soFromBeginning);
  S.Read(fParticles, S.Size);
  S.Free;

  with fGameParams.GraphicSet do
    for i := 0 to 255 do
      if CustSounds[i].Size <> 0 then
      begin
        if SFX_CUSTOM[i] <> 0 then
        begin
          SoundMgr.FreeSound(SFX_CUSTOM[i]);
        end;
        SFX_CUSTOM[i] := SoundMgr.AddSoundFromStream(CustSounds[i]);
      end;

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
  i,i2,i3:integer;
  O: TInteractiveObject;
  MO: TMetaObject;
  Inf: TInteractiveObjectInfo;
  numEntries:integer;
//  Bmp: TBitmap32;
const
  OID_EXIT                  = 0;
  OID_ENTRY                 = 1;
begin
  Assert(InfoPainter <> nil);

  Playing := False;

  if moChallengeMode in fGameParams.MiscOptions then
    begin
    fGameParams.Level.Info.ClimberCount   := 0 ;
    fGameParams.Level.Info.FloaterCount   := 0 ;
    fGameParams.Level.Info.BomberCount    := 0 ;
    fGameParams.Level.Info.BlockerCount   := 0 ;
    fGameParams.Level.Info.BuilderCount   := 0 ;
    fGameParams.Level.Info.BasherCount    := 0 ;
    fGameParams.Level.Info.MinerCount     := 0 ;
    fGameParams.Level.Info.DiggerCount    := 0 ;
    fGameParams.Level.Info.WalkerCount := 0;
    fGameParams.Level.Info.SwimmerCount := 0;
    fGameParams.Level.Info.GliderCount := 0;
    fGameParams.Level.Info.MechanicCount := 0;
    fGameParams.Level.Info.StonerCount := 0;
    fGameParams.Level.Info.PlatformerCount := 0;
    fGameParams.Level.Info.StackerCount := 0;
    fGameParams.Level.Info.ClonerCount := 0;
    end;

  fRenderer.RenderWorld(World, False, (moDebugSteel in fGameParams.MiscOptions));

  if ((Level.Info.LevelOptions and 8) = 0)
  and (fGameParams.SysDat.Options and 128 = 0) then
    fRenderer.RenderWorld(SteelWorld, False, True)
    else begin
    fRenderer.RenderWorld(SteelWorld, False, True, True);
      for i := 0 to SteelWorld.Width - 1 do
        for i2 := 0 to SteelWorld.Height - 1 do
          if SteelWorld.PixelS[i, i2] and ALPHA_STEEL <> 0 then
            World.PixelS[i, i2] := World.PixelS[i, i2] and not ALPHA_ONEWAY;
    end;

  //fTargetBitmap.Assign(World);

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
  fSecretGoto := -1;
  LevSecretGoto := -1;
  LemmingsReleased := 0;
  LemmingsCloned := 0;
  fHighlightLemming := nil;
//  fTargetBitmap := Renderer.LevelBitmap;
  //World.Assign(fTargetBitmap);
  World.OuterColor := 0;
  Minutes := Level.Info.TimeLimit div 60;
  Seconds := Level.Info.TimeLimit mod 60;
  if Minutes > 99 then
  begin
    Minutes := 99;
    Seconds := 59;
    fInfiniteTime := true;
  end else
    fInfiniteTime := false;
  if (moTimerMode in fGameParams.MiscOptions) or (fGameParams.Level.Info.TimeLimit > 5999) then
  begin
    Minutes := 0;
    Seconds := 0;
    fInfiniteTime := false;
  end;
  ButtonsRemain := 0;
//  Style := Level.Style;
//  Graph := Level.Graph;

  //if Style is TDosOrigStyle then
  //  Options := DOSORIG_GAMEOPTIONS
  //else
    Options := DOSOHNO_GAMEOPTIONS;

  SkillButtonsDisabledWhenPaused := False;

  FillChar(GameResultRec, SizeOf(GameResultRec), 0);
  GameResultRec.gCount  := Level.Info.LemmingsCount;
  GameResultRec.gToRescue := Level.Info.RescueCount;


  fReplayIndex := 0;
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
  ObjectInfos.Clear;
  Entries.Clear;

  // below not accurate emulation, but not likely to find levels out there
  // with 0 entrances.
  // We'll use -1 to represent "no entrance".
  {for i := 0 to 31 do
  begin
    DosEntryTable[i] := -1;
  end;
  DosEntryTable[i] := 0;}
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
  SetLength(fSoundToPlay, 0);
  if Level.Info.LevelID <> fRecorder.LevelID then //not aReplay then
  begin
    fRecorder.Clear;
    fRecorder.LevelID := Level.Info.LevelID;
    fReplaying := false;
  end else
    fReplaying := true;

  //fReplaying := aReplay;
  // fReplayedLemmingIndex := -1;

  fExplodingGraphics := False;


  with Level.Info do
  begin
    MaxNumLemmings := LemmingsCount;

    currReleaseRate    := ReleaseRate  ;
    lastReleaseRate    := ReleaseRate  ;
    currClimberCount   := ClimberCount ;
    currFloaterCount   := FloaterCount ;
    currBomberCount    := BomberCount  ;
    currBlockerCount   := BlockerCount ;
    currBuilderCount   := BuilderCount ;
    currBasherCount    := BasherCount  ;
    currMinerCount     := MinerCount   ;
    currDiggerCount    := DiggerCount  ;

    currWalkerCount := WalkerCount;
    currSwimmerCount := SwimmerCount;
    currGliderCount := GliderCount;
    currMechanicCount := MechanicCount;
    currStonerCount := StonerCount;
    currPlatformerCount := PlatformerCount;
    currStackerCount := StackerCount;
    currClonerCount := ClonerCount;

    UsedWalkerCount := 0;
    UsedClimberCount := 0;
    UsedSwimmerCount := 0;
    UsedFloaterCount := 0;
    UsedGliderCount := 0;
    UsedMechanicCount := 0;
    UsedBomberCount := 0;
    UsedStonerCount := 0;
    UsedBlockerCount := 0;
    UsedPlatformerCount := 0;
    UsedBuilderCount := 0;
    UsedStackerCount := 0;
    UsedBasherCount := 0;
    UsedMinerCount := 0;
    UsedDiggerCount := 0;
    UsedClonerCount := 0;

    Gimmick            := SuperLemming ;
  end;

  LowestReleaseRate := CurrReleaseRate;
  HighestReleaseRate := CurrReleaseRate;

  fLastRecordedRR := CurrReleaseRate;

  NextLemmingCountDown := 20;

  ObjectInfos.Clear;
  numEntries := 0;

  with Level do
  for i := 0 to InteractiveObjects.Count - 1 do
  begin
    O := InteractiveObjects[i];
    MO := Graph.MetaObjects[O.Identifier];

    Inf := TInteractiveObjectInfo.Create;
    Inf.Obj := O;
    Inf.MetaObj := MO;

    Inf.Obj.Left := Inf.Obj.Left - Inf.Obj.OffsetX;
    Inf.Obj.Top := Inf.Obj.Top - Inf.Obj.OffsetY;

    Inf.Obj.OffsetX := 0;
    Inf.Obj.OffsetY := 0;

    Inf.TotalFactor := 0;

    if Inf.MetaObj.RandomStartFrame then
      Inf.CurrentFrame := ((((Abs(Inf.Obj.Left) + 1) * (Abs(Inf.Obj.Top) + 1)) + ((Inf.Obj.Skill + 1) * (Inf.Obj.TarLev + 1))) + i) mod Inf.MetaObj.AnimationFrameCount
    else if MO.TriggerEffect = 14 then
      Inf.CurrentFrame := O.Skill + 1
    else if MO.TriggerEffect in [15, 17, 23, 31] then
      Inf.CurrentFrame := 1
    else
      Inf.CurrentFrame := MO.PreviewFrameIndex;

    if (MO.TriggerEffect = 21) then
      if ((O.DrawingFlags and odf_FlipLem) <> 0) then
        Inf.CurrentFrame := 1
      else
        Inf.CurrentFrame := 0;

    Inf.ZombieMode := false;



(*    // add to the right list (entries or other objects)
    if O.Identifier = OID_ENTRY then     //lemcore
      Entries.Add(Inf)
    else*)
    if ((MO.TriggerEffect = 23)) and (O.IsFake = false) and (O.Left + MO.Width >= 0) then
    begin
      SetLength(dosEntryTable, numEntries + 1);
      dosentrytable[numEntries] := i;
      numEntries := numEntries + 1;
    end;

    if MO.TriggerEffect = 17 then Inc(ButtonsRemain);
    //if MO.TriggerEffect = 14 then O.Skill := O.Skill mod 8;
    ObjectInfos.Add(Inf);
  end;

  ApplyLevelEntryOrder;
  InitializeBrickColors(Graph.BrickColor);
  InitializeObjectMap;
  InitializeBlockerMap;
  InitializeMiniMap;
  ApplyAutoSteel;

  //ShowMessage(IntToStr(Level.Info.LevelID));

  fTargetBitmap.Assign(World);
  DrawAnimatedObjects; // first draw needed

  //if Entries.Count = 0 then raise exception.Create('no entries');

  with InfoPainter do
  begin
    if (Minutes >= 0) and (Seconds >= 0) then
    begin
      SetInfoMinutes(Minutes, CheckTimerBlink);
      SetInfoSeconds(Seconds, CheckTimerBlink);
    end else begin
      if Seconds > 0 then
        SetInfoMinutes(abs(Minutes + 1), CheckTimerBlink)
      else
        SetInfoMinutes(abs(Minutes), CheckTimerBlink);
      SetInfoSeconds((60 - Seconds) mod 60, CheckTimerBlink);
    end;
    SetInfoLemmingsAlive((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsOut + LemmingsRemoved), false);
    SetInfoLemmingsOut((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsRemoved), CheckLemmingBlink);
    UpdateLemmingsIn(0, 1);
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


  DrawStatics;

  SteelWorld.Assign(World);
  SpawnLemming; // instantly-spawning lemmings (object type 13)

  if CheckGimmick(GIM_CHEAPOMODE) then
    fFallLimit := MAX_LONGFALLDISTANCE
    else
    fFallLimit := MAX_FALLDISTANCE;

  fTalismanReceived := false;

  Playing := True;
end;

procedure TLemmingGame.SpawnLemming;
var
  NewLemming : TLemming;
  i, c: Integer;
begin

for i := 0 to ObjectInfos.Count - 1 do
begin
  c := ObjectInfos[i].MetaObj.TriggerEffect;
  if (c = 13) and (ObjectInfos[i].Obj.IsFake = false) then
  begin
    NewLemming := TLemming.Create;
    with NewLemming do
    begin
      LemIndex := LemmingList.Add(NewLemming);
      LemBorn := CurrentIteration;
      Transition(NewLemming, baFalling);
      LemY := ObjectInfos[i].Obj.Top + ObjectInfos[i].MetaObj.TriggerTop;
      LemX := ObjectInfos[i].Obj.Left + ObjectInfos[i].MetaObj.TriggerLeft;
      LemDX := 1;
      if (ObjectInfos[i].Obj.DrawingFlags and 8) <> 0 then
        TurnAround(NewLemming);
      if (ObjectInfos[i].Obj.TarLev and 1) <> 0 then LemIsClimber := true;
      if (ObjectInfos[i].Obj.TarLev and 2) <> 0 then LemIsSwimmer := true;
      if (ObjectInfos[i].Obj.TarLev and 4) <> 0 then LemIsFloater := true
      else if (ObjectInfos[i].Obj.TarLev and 8) <> 0 then LemIsGlider := true;
      if (ObjectInfos[i].Obj.TarLev and 16) <> 0 then LemIsMechanic := true;
      if (ObjectInfos[i].Obj.TarLev and 32) <> 0 then
      begin
        if not CheckGimmick(GIM_NOGRAVITY) then
          while (LemY <= LEMMING_MAX_Y + World.Height) and (HasPixelAt(LemX, LemY) = false) do
            Inc(LemY);
        Transition(NewLemming, baBlocking);
      end;
      if ((ObjectInfos[i].Obj.TarLev and 64) <> 0) and CheckGimmick(GIM_ZOMBIES) then RemoveLemming(NewLemming, RM_ZOMBIE);
      if ((ObjectInfos[i].Obj.TarLev and 128) <> 0) and CheckGimmick(GIM_GHOSTS) then RemoveLemming(NewLemming, RM_GHOST);
      if NewLemming.LemIsZombie or NewLemming.LemIsGhost then Dec(SpawnedDead);
      LemObjectInFront := DOM_NONE;
      LemObjectBelow := DOM_NONE;
      LemObjectIDBelow := DOM_NOOBJECT;
      LemInFlipper := -1;
      LemParticleTimer := -1;
      LemUsedSkillCount := 0;
      LemIsClone := false;
      if LemIndex = fHighlightLemmingID then fHighlightLemming := NewLemming;
    end;
    Inc(LemmingsReleased);
    Inc(LemmingsOut);
  end else if (c = 14) then ObjectInfos[i].CurrentFrame := ObjectInfos[i].Obj.Skill + 1
      else if ((c = 15) and (ButtonsRemain > 0)) or (c = 17) or (c = 31) then ObjectInfos[i].CurrentFrame := 1
      else if (c = 21) and (ObjectInfos[i].Obj.DrawingFlags and 8 <> 0) then ObjectInfos[i].CurrentFrame := 1;
end;
end;

procedure TLemmingGame.CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
end;

procedure TLemmingGame.CombineLemmingPixelsZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
  if F <> 0 then B := F;
end;

procedure TLemmingGame.CombineLemmingPixelsGhost(F: TColor32; var B: TColor32; M: TColor32);
var
  n, r, g, bl: byte; //bl because b is already in use here
begin
  r := f shr 16;
  g := f shr 8;
  bl := f;
  n := ((r * 5) + (g * 6) + (bl * 4) + (255 * 5)) div 20;
  if F <> 0 then
  begin
    F := (F and $FF000000) + (n shl 16) + (n shl 8) + n;
    B := F;
  end;
end;

procedure TLemmingGame.CombineBuilderPixelsGhost(F: TColor32; var B: TColor32; M: TColor32);
var
  n, r, g, bl: byte; //bl because b is already in use here
begin
  if F = BrickPixelColor then
  begin
    B := BrickPixelColors[12 - fCurrentlyDrawnLemming.LemNumberOfBricksLeft];
    Exit;
  end;

  r := f shr 16;
  g := f shr 8;
  bl := f;
  n := ((r * 5) + (g * 6) + (bl * 4) + (255 * 5)) div 20;
  if F <> 0 then
  begin
    F := (F and $FF000000) + (n shl 16) + (n shl 8) + n;
    B := F;
  end;
end;

procedure TLemmingGame.CombineBuilderPixels(F: TColor32; var B: TColor32; M: TColor32);
{-------------------------------------------------------------------------------
  This trusts the CurrentlyDrawnLemming variable.
-------------------------------------------------------------------------------}
begin
  if F = BrickPixelColor then
    B := BrickPixelColors[12 - fCurrentlyDrawnLemming.LemNumberOfBricksLeft]
  else if F <> 0 then
    B := F;
end;

procedure TLemmingGame.CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
end;

procedure TLemmingGame.CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
begin
  // photoflash
  if F <> 0 then B := clBlack32 else B := clWhite32;
//  if F <> 0 then B := clYellow32;
end;


procedure TLemmingGame.CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32);
// copy masks to world
begin
  if F <> 0 then B := Renderer.BackgroundColor;
end;

procedure TLemmingGame.CombineNoOverwriteStoner(F: TColor32; var B: TColor32; M: TColor32);
// copy Stoner to world
begin
  if (B and ALPHA_TERRAIN = 0) and (F <> 0) then B := ((F and $FFFFFF) or ALPHA_TERRAIN);
end;

procedure TLemmingGame.CombineMinimapWorldPixels(F: TColor32; var B: TColor32; M: TColor32);
// copy world to minimap
begin
  if F and ALPHA_TERRAIN <> 0 then B := BrickPixelColor
    else B := Renderer.BackgroundColor;
end;

function TLemmingGame.HasPixelAt(X, Y: Integer; SwimTest: Boolean = false): Boolean;
{-------------------------------------------------------------------------------
  Read value from world.
  The function returns True when the value at (x, y) is terrain
-------------------------------------------------------------------------------}
begin
  {if Y < 0 then
    begin
    Result := true;
    exit;
    end;}
  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X >= World.Width then X := X - World.Width;
    if X < 0 then X := X + World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y >= World.Height then Y := Y - World.Height;
    if Y < 0 then Y := Y + World.Height;
  end;

  with World do
  begin
    if CheckGimmick(GIM_DEADLYSIDES) then
    begin
      Result := (Y < 0);
      if CheckGimmick(GIM_SOLIDFLOOR) and (Y >= World.Height) then Result := true;
      if not ((X >= 0) and (X < Width)) then Exit;
    end else
      Result := not ((X >= 0) and (Y >= 0) and (X < Width));
    if Result = false then Result := (Y < Height) and (Pixel[X, Y] and ALPHA_TERRAIN <> 0);
    if (CheckGimmick(GIM_SOLIDFLOOR) or SwimTest) and (Y >= Height) then Result := true;
  end;

//  with World do
  //  Result := (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height)
    //          and (Pixel[X, Y] and COLOR_MASK <> 0);
end;

function TLemmingGame.HasPixelAt_ClipY(X, Y, minY: Integer; SwimTest: Boolean = false): Boolean;
begin
  Result := HasPixelAt(X, Y, SwimTest);
  // need to remove this function; NeoLemmix doesn't ever clip Y in solidity tests
end;

procedure TLemmingGame.RemovePixelAt(X, Y: Integer);
begin
  World.PixelS[x, y] := Renderer.BackgroundColor;
  if not fHyperSpeed then
    fTargetBitmap.PixelS[x, y] := Renderer.BackgroundColor;
end;

function TLemmingGame.CheckGimmick(GType: Integer): Boolean;
begin
  Result := False;
  if GType = GIM_ANY then
    begin
      if ((Gimmick shr 8) = $42) then Result := True;
      if Gimmick = $FFFF then Result := True;
      if GimmickSet and $3FFFFFFF <> 0 then Result := True;
      if GimmickSet2 <> 0 then Result := True;
      if GimmickSet3 <> 0 then Result := True;
    end;
  if GType = GIM_FRENZY then
    begin
    if Gimmick = $4201 then Result := True;
    if Gimmick = $4202 then Result := True;
    if Gimmick = $4209 then Result := True;
    if Gimmick = $420E then Result := True;
    if (GimmickSet and 2) <> 0 then Result := True;
    end;
  if GType = GIM_REVERSE then
    begin
    if moChallengeMode in fGameParams.MiscOptions then Result := True;
    if Gimmick = $4203 then Result := True;
    if (GimmickSet and 4) <> 0 then Result := True;
    end;
  if GType = GIM_KAROSHI then // Code for Karoshi also exists elsewhere
    begin
    if Gimmick = $4204 then Result := True;
    if Gimmick = $4209 then Result := True;
    if (GimmickSet and 8) <> 0 then Result := True;
    end;
  if GType = GIM_UNALTERABLE then
    begin
    if Gimmick = $4205 then Result := True;
    if Gimmick = $4209 then Result := True;
    if (GimmickSet and 16) <> 0 then Result := True;
    end;
  if GType = GIM_OVERFLOW then
    begin
    if moChallengeMode in fGameParams.MiscOptions then Result := True;
    if Gimmick = $4206 then Result := True;
    if (GimmickSet and 32) <> 0 then Result := True;
    end;
  if GType = GIM_NOGRAVITY then
    begin
    if Gimmick = $4207 then Result := True;
    if Gimmick = $4210 then Result := True;
    if (GimmickSet and 64) <> 0 then Result := True;
    end;
  if GType = GIM_HARDWORK then
    begin
    if Gimmick = $4208 then Result := True;
    if Gimmick = $4210 then Result := True;
    if (GimmickSet and 128) <> 0 then Result := True;
    end;
  if GType = GIM_SUPERLEMMING then  // Code for SuperLemming also exists elsewhere
    begin
    if Gimmick = $4201 then Result := True;
    if Gimmick = $420A then Result := True;
    if Gimmick = $4209 then Result := True;
    if Gimmick = $FFFF then Result := True;
    if (GimmickSet and 1) <> 0 then Result := True;
    end;
  if GType = GIM_BACKWARDS then
    begin
    if Gimmick = $420B then Result := True;
    if (GimmickSet and 256) <> 0 then Result := True;
    end;
  if GType = GIM_LAZY then
    begin
    if Gimmick = $420C then Result := True;
    if Gimmick = $420F then Result := True;
    if (GimmickSet and 512) <> 0 then Result := True;
    end;
  if GType = GIM_EXHAUSTION then
    begin
    if Gimmick = $420D then Result := True;
    if Gimmick = $420E then Result := True;
    if Gimmick = $420F then Result := True;
    if (GimmickSet and 1024) <> 0 then Result := True;
    end;
  if GType = GIM_SURVIVOR then
    begin
    if Gimmick = $4211 then Result := True;
    if (GimmickSet and 2048) <> 0 then Result := True;
    end;
  if GType = GIM_INVINCIBLE then
    begin
    if Gimmick = $4212 then Result := True;
    if (GimmickSet and 4096) <> 0 then Result := True;
    end;
  if GType = GIM_ONESKILL then
    begin
    if Gimmick = $4213 then Result := True;
    if (GimmickSet and 8192) <> 0 then Result := True;
    end;
  if GType = GIM_INVERTSTEEL then
    begin
    if (GimmickSet and 16384) <> 0 then Result := True;
    end;
  if GType = GIM_SOLIDFLOOR then
    begin
    if ((GimmickSet and 32768) <> 0) and not ((GimmickSet and $800000) <> 0)
    or (CheckGimmick(GIM_NOGRAVITY) and not (CheckGimmick(GIM_DEADLYSIDES))) then Result := True;
    // Wrap Vertical and Solid Floor are incompatible, so Solid Floor doesn't trigger if Wrap Vertical is also set
    // Likewise, lemmings shouldn't be able to fall out the bottom in a No Gravity level
    end;
  if GType = GIM_NONPERMANENT then
    begin
    if (GimmickSet and 65536) <> 0 then Result := True;
    end;
  if GType = GIM_DISOBEDIENT then
    begin
    if (GimmickSet and $20000) <> 0 then Result := True;
    end;
  if GType = GIM_NUCLEAR then
    begin
    if (GimmickSet and $40000) <> 0 then Result := True;
    end;
  if GType = GIM_TURNAROUND then
    begin
    if (GimmickSet and $80000) <> 0 then Result := True;
    end;
  if GType = GIM_OTHERSKILL then
    begin
    if (GimmickSet and $100000) <> 0 then Result := True;
    end;
  if GType = GIM_ASSIGNALL then
    begin
    if (GimmickSet and $200000) <> 0 then Result := True;
    end;
  if GType = GIM_WRAP_HOR then
    begin
    if (GimmickSet and $400000) <> 0 then Result := True;
    end;
  if GType = GIM_WRAP_VER then
    begin
    if (GimmickSet and $800000) <> 0 then Result := True;
    end;
  if GType = GIM_RISING_WATER then
    begin
    if (GimmickSet and $1000000) <> 0 then Result := True;
    end;
  // Timer gimmick is coded elsewhere (Rendering unit)
  if GType = GIM_ZOMBIES then
    begin
    if (GimmickSet and $4000000) <> 0 then Result := True;
    end;
  if GType = GIM_OLDZOMBIES then
    begin
    if ((GimmickSet and $8000000) <> 0) and CheckGimmick(GIM_ZOMBIES) then Result := True;
    end;
  if GType = GIM_DEADLYSIDES then
    begin
    if ((GimmickSet and $10000000) <> 0) then Result := True;
    end;
  if GType = GIM_INVERTFALL then
    begin
    if ((GimmickSet and $20000000) <> 0) then Result := True;
    end;
  if GType = GIM_CHEAPOMODE then
    begin
    if (GimmickSet and $40000000) <> 0 then Result := True;
    end;
  // Rickroll gimmick is coded elsewhere (Preview screen)


  // Gimmick Flags 2
  if GType = GIM_CLONEASSIGN then
    begin
    if ((GimmickSet2 and $1) <> 0) then Result := True;
    end;

  if GType = GIM_INSTANTPICKUP then
    begin
    if ((GimmickSet2 and $2) <> 0) then Result := True;
    end;

  if GType = GIM_DEATHZOMBIE then
    begin
    if ((GimmickSet2 and $4) <> 0) then Result := True;
    end;

  if GType = GIM_PERMANENTBLOCK then
    begin
    if ((GimmickSet2 and $8) <> 0) then Result := True;
    end;

  if GType = GIM_RRFLUC then
    begin
    if ((GimmickSet2 and $10) <> 0) then Result := true;
    end;

  if GType = GIM_GHOSTS then
    begin
    if ((GimmickSet2 and $20) <> 0) then Result := True;
    end;

  if GType = GIM_DEATHGHOST then
    begin
    if ((GimmickSet2 and $40) <> 0) and not (CheckGimmick(GIM_ZOMBIES) and CheckGimmick(GIM_DEATHZOMBIE)) then Result := True;
    end;
end;

procedure TLemmingGame.MoveLemToReceivePoint(L: TLemming; oid: Byte);
var
  Inf, Inf2: TInteractiveObjectInfo;
  dpx, dpy, tlx, tly: Integer;
begin

with L do
begin
  Inf := ObjectInfos[oid];
  Inf2 := ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)];

  if Inf.Obj.DrawingFlags and 8 <> 0 then TurnAround(L);

  if Inf2.MetaObj.TriggerEffect = 12 then
  begin
    dpx := Inf2.MetaObj.TriggerLeft;
    dpy := Inf2.MetaObj.TriggerTop;
  end else begin
    dpx := Inf2.MetaObj.TriggerPointX;
    dpy := Inf2.MetaObj.TriggerPointY;
  end;

  if CheckGimmick(GIM_CHEAPOMODE) or (Inf2.MetaObj.TriggerEffect <> 12) then
  begin

    tlx := 0;
    tly := 0;
    if Inf.Obj.DrawingFlags and 8 <> 0 then
      tlx := Inf.MetaObj.TriggerWidth - tlx - 1;

    if Inf2.Obj.DrawingFlags and 2 <> 0 then
      tly := tly + Inf2.Obj.Top + (Inf2.MetaObj.Height - 1) - (dpy)
    else
      tly := tly + Inf2.Obj.Top + dpy;
    if Inf2.Obj.DrawingFlags and 64 <> 0 then
      tlx := tlx + Inf2.Obj.Left + (Inf2.MetaObj.Width - 1) - (dpx)
    else
      tlx := tlx + Inf2.Obj.Left + dpx;

  end else begin

    if Inf.Obj.DrawingFlags and 2 <> 0 then
      tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop) - (Inf.MetaObj.TriggerHeight - 1)
    else
      tly := Inf.Obj.Top + Inf.MetaObj.TriggerTop;
    if Inf.Obj.DrawingFlags and 64 <> 0 then
      tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft) - (Inf.MetaObj.TriggerWidth - 1)
    else
      tlx := Inf.Obj.Left + Inf.MetaObj.TriggerLeft;

    tlx := LemX - tlx;
    tly := LemY - tly;

    if Inf.Obj.DrawingFlags and 8 <> 0 then
      tlx := Inf.MetaObj.TriggerWidth - tlx - 1;

    if Inf2.Obj.DrawingFlags and 2 <> 0 then
      tly := tly + Inf2.Obj.Top + (Inf2.MetaObj.Height - 1) - (Inf2.MetaObj.TriggerTop) - (Inf2.MetaObj.TriggerHeight - 1)
    else
      tly := tly + Inf2.Obj.Top + Inf2.MetaObj.TriggerTop;
    if Inf2.Obj.DrawingFlags and 64 <> 0 then
      tlx := tlx + Inf2.Obj.Left + (Inf2.MetaObj.Width - 1) - (Inf2.MetaObj.TriggerLeft) - (Inf2.MetaObj.TriggerWidth - 1)
    else
      tlx := tlx + Inf2.Obj.Left + Inf2.MetaObj.TriggerLeft;

  end;

  LemX := tlx;
  LemY := tly;

end;

end; 

function TLemmingGame.FindReceiver(oid: Byte; sval: Byte): Byte;
var
  t: Byte;
begin
        Result := oid;

        if ObjectInfos[oid].MetaObj.TriggerEffect = 29 then Exit;

        if CheckGimmick(GIM_CHEAPOMODE) then oid := ObjectInfos.Count-1;
        for t := oid+1 to oid+ObjectInfos.Count do
        begin
          if (ObjectInfos[t mod ObjectInfos.Count].MetaObj.TriggerEffect in [12, 28])
          and (ObjectInfos[t mod ObjectInfos.Count].Obj.IsFake = false)
          and (ObjectInfos[t mod ObjectInfos.Count].Obj.Skill = sval)
          and (t mod ObjectInfos.Count <> Result) then
          begin
            Result := t mod ObjectInfos.Count;
            break;
          end;
        end;
end;

function TLemmingGame.ReadObjectMap(X, Y: Integer; Advance: Boolean = true): Word;
// original dos objectmap has a resolution of 4
begin
  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  // the "and not 3" ensures rounding down when
  // operand is negative (eg. -0.25 -> -1)
  if not Advance then
  begin
    ShowMessage('Advance check failed. Please report.');
    x := x * 4;
    y := y * 4;
    // this should NEVER be triggered these days
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  x := x * 2;

  with ObjectMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      Result := (ObjectMap.Bits^[X + Y * Width] shl 8) + ObjectMap.Bits^[X + 1 + Y * Width]
    else
      Result := DOM_NOOBJECT; // whoops, important
  end;
end;

function TLemmingGame.ReadObjectMapType(X, Y: Integer): Byte;
var
  ObjID: Word;
begin

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  if CheckGimmick(GIM_DEADLYSIDES) then
  begin
    if (X < 0) or (X >= World.Width) or (((Y <= 8) or ((Y >= World.Height) and not CheckGimmick(GIM_SOLIDFLOOR))) and not CheckGimmick(GIM_WRAP_VER)) then
    begin
      Result := DOM_FIRE;
      Exit;
    end;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  x := x * 2;

  with ObjectMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    begin
      ObjID := (ObjectMap.Bits^[X + Y * Width] shl 8) + ObjectMap.Bits^[X + 1 + Y * Width];
      if ObjID = DOM_NOOBJECT then
        Result := DOM_NONE
        else
        Result := ObjectInfos[ObjID].MetaObj.TriggerEffect + DOM_OFFSET;
    end else
      Result := DOM_NONE; // whoops, important
  end;

  if Result = DOM_TWOWAYTELE then Result := DOM_TELEPORT;   // so kludgy, but it works very well
end;

function TLemmingGame.ReadBlockerMap(X, Y: Integer): Byte;
// original dos objectmap has a resolution of 4
begin
  // the "and not 3" ensures rounding down when
  // operand is negative (eg. -0.25 -> -1)

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with BlockerMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      Result := BlockerMap.Bits^[X + Y * Width]
    else
      Result := DOM_NONE; // whoops, important
  end;
end;

function TLemmingGame.ReadZombieMap(X, Y: Integer): Byte;
// original dos objectmap has a resolution of 4
begin
  // the "and not 3" ensures rounding down when
  // operand is negative (eg. -0.25 -> -1)

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with ZombieMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      Result := ZombieMap.Bits^[X + Y * Width]
    else
      Result := DOM_NONE; // whoops, important
  end;
end;

function TLemmingGame.ReadSpecialMap(X, Y: Integer): Byte;
// original dos objectmap has a resolution of 4
begin
  // the "and not 3" ensures rounding down when
  // operand is negative (eg. -0.25 -> -1)

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with SpecialMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      Result := SpecialMap.Bits^[X + Y * Width]
    else
      Result := DOM_NONE; // whoops, important

    if not (CheckGimmick(GIM_WRAP_HOR) or CheckGimmick(GIM_DEADLYSIDES)) then
    begin
      if X < OBJMAPADD then Result := DOM_STEEL;
      if X >= World.Width + OBJMAPADD then Result := DOM_STEEL;
    end;

    if (Y < OBJMAPADD) and not (CheckGimmick(GIM_WRAP_VER) or CheckGimmick(GIM_DEADLYSIDES)) then Result := DOM_STEEL;

    if (Y >= World.Height + OBJMAPADD) and CheckGimmick(GIM_SOLIDFLOOR) then Result := DOM_STEEL;
  end;

end;

function TLemmingGame.ReadWaterMap(X, Y: Integer): Byte;
// original dos objectmap has a resolution of 4
begin
  // the "and not 3" ensures rounding down when
  // operand is negative (eg. -0.25 -> -1)

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with WaterMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      Result := Bits^[X + Y * Width]
    else
      Result := DOM_NONE; // whoops, important
  end;

end;



procedure TLemmingGame.WriteBlockerMap(X, Y: Integer; aValue: Byte);
//var
  //x1, y1: Integer;
begin

  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with BlockerMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      BlockerMap.Bits^[X + Y * Width] := aValue;
  end;

end;

procedure TLemmingGame.WriteZombieMap(X, Y: Integer; aValue: Byte);
//var
//  x1, y1: Integer;
begin
  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;
  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);
  with ZombieMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      ZombieMap.Bits^[X + Y * Width] := ZombieMap.Bits^[X + Y * Width] or aValue;
  end;

end;

procedure TLemmingGame.WriteWaterMap(X, Y: Integer; aValue: Byte);
//var
//  x1, y1: Integer;
begin
  if CheckGimmick(GIM_WRAP_HOR) then
  begin
    if X < 0 then X := X + World.Width;
    if X >= World.Width then X := X - World.Width;
  end;
  if CheckGimmick(GIM_WRAP_VER) then
  begin
    if Y < 0 then Y := Y + World.Height;
    if Y >= World.Height then Y := Y - World.Height;
  end;
  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);
  with WaterMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      WaterMap.Bits^[X + Y * Width] := aValue;
  end;

end;


procedure TLemmingGame.WriteSpecialMap(X, Y: Integer; aValue: Byte);
//var
//  x1, y1: Integer;
begin

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  with SpecialMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
      SpecialMap.Bits^[X + Y * Width] := aValue;
  end;

end;


procedure TLemmingGame.WriteObjectMap(X, Y: Integer; aValue: Word; Advance: Boolean = false);
//var
//  x1, y1: Integer;
begin

  Inc(X, OBJMAPADD);
  Inc(Y, OBJMAPADD);

  x := x * 2;

  with ObjectMap do
  begin
    if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    begin
      ObjectMap.Bits^[X + Y * Width] := aValue div 256;
      ObjectMap.Bits^[X + 1 + Y * Width] := aValue mod 256;
    end;
  end;

end;

procedure TLemmingGame.SaveMap(L: TLemming);
{var
  X, Y, Q: Integer;
  Offset: Integer;}
begin
  {Q := 0;
  if L.LemRTL then Offset := -1
  else Offset := 0;
  with L do
  begin
    for X := LemX - 5 to LemX + 6 do
    for Y := LemY - 6 to LemY + 4 do
    begin
      LemSavedMap[Q] := ReadBlockerMap(X+Offset, Y);
      Inc(Q);
    end;
    LemSavedMapX := LemX+Offset;
    LemSavedMapY := LemY;
  end;}
end;

procedure TLemmingGame.RestoreMap(L: TLemming);
{var
  X, Y, Q: Integer;}
var
  i: Integer;
begin
  {Q := 0;
  with L do
  begin
    for X := LemSavedMapX - 5 to LemSavedMapX + 6 do
    for Y := LemSavedMapY - 6 to LemSavedMapY + 4 do
    begin
      WriteBlockerMap(X, Y, LemSavedMap[Q]);
      Inc(Q);
    end;
    LemSavedMapX := 0;
    LemSavedMapY := 0;
  end;}
  BlockerMap.Clear(0);
  for i := 0 to LemmingList.Count-1 do
    if (LemmingList[i].LemIsBlocking > 0) and not LemmingList[i].LemRemoved then SetBlockerField(LemmingList[i]);
end;

procedure TLemmingGame.SetBlockerField(L: TLemming);
var
  X, Y: Integer;
begin
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

  end;
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

procedure TLemmingGame.SetGhostField(L: TLemming);
var
  X, Y: Integer;
  o: Integer;
begin
  with L do
  begin
    if LemDx < 0 then o := -1
    else o := 0;
    for X := ((LemX - 8) + o) to ((LemX) + o) do
      for Y := LemY - 10 to LemY + 6 do
        WriteZombieMap(X, Y, 2);
    for X := ((LemX + 1) + o) to ((LemX + 9) + o) do
      for Y := LemY - 10 to LemY + 6 do
        WriteZombieMap(X, Y, 4);
  end;
end;

function TLemmingGame.CheckForOverlappingField(L: TLemming): Boolean;
const
  BytesToCheck = [DOM_FORCELEFT, DOM_BLOCKER, DOM_FORCERIGHT];
var
  X, Y: Integer;
begin
  Result := false;
  with L do
    for X := LemX - 5 to LemX + 5 do
    for Y := LemY - 6 to LemY + 4 do
      Result := Result or (ReadBlockerMap(X, Y) in BytesToCheck)
end;


procedure TLemmingGame.Transition(L: TLemming; aAction: TBasicLemmingAction; DoTurn: Boolean = False);
{-------------------------------------------------------------------------------
  Handling of a transition and/or turnaround
-------------------------------------------------------------------------------}
var
  i: Integer;
begin

  with L do
  begin
    // check if any change

    if (aAction = baToWalking) then
    begin
      if (LemAction = baBuilding) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY) then
        LemY := LemY - 1;
      if LemAction = baWalking then DoTurn := true;
      aAction := baWalking;
      if LemIsBlocking > 0 then
      begin
        LemIsBlocking := 0;
        RestoreMap(L);
      end;
    end;

    if {(aAction = baShrugging) and }(LemIsBlocking > 0)
    and not (aAction in [baBlocking, baOhNoing, baStoning]) then
    begin
      LemIsBlocking := 0;
      RestoreMap(L);
    end;

    if (not ((HasPixelAt(LemX, LemY)) or (CheckGimmick(GIM_NOGRAVITY))))
    and (aAction = baWalking) then aAction := baFalling;

    if LemBecomeBlocker and (aAction = baWalking) and CheckGimmick(GIM_PERMANENTBLOCK) then
      aAction := baBlocking;

    {if (((HasPixelAt(LemX, LemY-1)) or (CheckGimmick(GIM_NOGRAVITY))))
    and (aAction = baFalling) then aAction := baWalking;}

    if (LemAction = aAction) and not DoTurn then
      Exit;

    if DoTurn then
      LemDx := -LemDx;

    // *always* new animation
    i := AnimationIndices[aAction, LemRTL]; // watch out: here use the aAction parameter!
    LMA := Style.AnimationSet.MetaLemmingAnimations[i];
    LAB := Style.AnimationSet.LemmingAnimations.List^[i];
    LemMaxFrame := LMA.FrameCount - 1;
    LemAnimationType := LMA.AnimationType;
    FrameTopDy  := -LMA.FootY; // ccexplore compatible
    FrameLeftDx := -LMA.FootX; // ccexplore compatible

    if (AnimationIndices[aAction, false] = AnimationIndices[aAction, true]) and (LemRTL = true) and (LemAction <> baDigging) then
      LemRTLAdjust := True
      else
      LemRTLAdjust := False;  //usually needs a position adjust in non-directional animations but digger is exception                                                                                         

    // transition
    if CheckGimmick(GIM_SURVIVOR) and (aAction = baExploding) then LemOldFallen := LemFallen;
    if (aAction = baFalling) then
      begin
      {if (HasPixelAt(LemX, LemY)) or (CheckGimmick(GIM_NOGRAVITY)) then
      begin
        Transition(L, baWalking);
        Exit;
      end; }
      LemFallen := -2;
      if LemAction in [baWalking] then LemFallen := 0;
      if LemAction in [baBashing] then LemFallen := -1;
      if LemAction in [baMining, baDigging] then LemFallen := -3;
      if CheckGimmick(GIM_SURVIVOR) and (LemAction = baExploding) then LemFallen := LemOldFallen;
      end;
    if (LemOldFallen <> 0) and not (LemAction in [baFalling, baGliding, baFloating, baExploding]) then
      LemOldFallen := 0;
    {if CheckGimmick(GIM_SURVIVOR) and (LemAction = baExploding) and (aAction = baFalling) then
    begin
      LemFallen := LemOldFallen;
      LemOldFallen := 0;
    end else begin
      if not (aAction = baExploding) then LemOldFallen := 0;
    end;}
    if LemAction = aAction then
      Exit;
    if ((LemAction = baClimbing) and (aAction <> baHoisting)) then
      if LemY > LemClimbStartY then LemY := LemClimbStartY;
    if not (aAction in [baFalling, baFloating]) then LemFloated := 0;
    LemAction := aAction;
    LemFrame := 0;
    LemClimbed := 0;
    LemEndOfAnimation := False;
    LemNumberOfBricksLeft := 0;

    // Remove permanent skills if nonpermanent gimmick
    if CheckGimmick(GIM_NONPERMANENT) then
    begin
      if LemAction = baClimbing then LemIsClimber := false;
      if LemAction = baSwimming then LemIsSwimmer := false;
      if LemAction = baFloating then LemIsFloater := false;
      if LemAction = baGliding then LemIsGlider := false;
      if LemAction = baFixing then LemIsMechanic := false;
    end;

    // some things to do when entering state
    case LemAction of
      baJumping:
        LemJumped := 0;
      baClimbing:
        begin
          LemClimbStartY := LemY;
          LemFirstClimb := true;
        end;
      baSplatting:
        begin
          LemExplosionTimer := 0;
          //LemDX := 0;
          CueSoundEffect(SFX_SPLAT)
        end;
      baBlocking:
        begin
          LemIsBlocking := 1;
          SaveMap(L);
          SetBlockerField(L);
          if CheckGimmick(GIM_PERMANENTBLOCK) then
            LemBecomeBlocker := true;
        end;
      baExiting    :
        begin
        LemExplosionTimer := 0;
        CueSoundEffect(SFX_YIPPEE);
        end;
      baDigging    : LemIsNewDigger := True;
      baFalling    :
        begin
          // @Optional Game Mechanic
          if dgoFallerStartsWith3 in Options then
            Inc(LemFallen, 3);
          LemTrueFallen := LemFallen;
        end;
      baBuilding   : LemNumberOfBricksLeft := 12;
      baPlatforming: LemNumberOfBricksLeft := 12;
      baStacking   : LemNumberOfBricksLeft := 8;
      //baDrowning   : CueSoundEffect(SFX_DROWNING);
      //baVaporizing : CueSoundEffect(SFX_VAPORIZING);
      baOhnoing    : {if (not UserSetNuking)
                     or (CheckGimmick(GIM_SURVIVOR)) then} CueSoundEffect(SFX_OHNO);
      baStoning    : CueSoundEffect(SFX_OHNO);
      baExploding  : begin
                       if fHighlightLemming = L then fHighlightLemming := nil;
                       CueSoundEffect(SFX_EXPLOSION);
                     end;
      baStoneFinish: begin
                       if fHighlightLemming = L then fHighlightLemming := nil;
                       CueSoundEffect(SFX_EXPLOSION);
                     end;
      baFloating   : LemFloatParametersTableIndex := 0;
      baGliding    : LemFloatParametersTableIndex := 0;
      baMining     : Inc(LemY);
      baSwimming   : for i := 1 to 4 do
                     begin
                       if (ReadWaterMap(LemX, LemY-1) = DOM_WATER)
                       and (not (HasPixelAt(LemX, LemY-1))) then
                         Dec(LemY)
                         else
                         break;
                     end;
      baFixing     : LemMechanicFrames := 42;

    end;
  end;
end;

procedure TLemmingGame.TurnAround(L: TLemming);
// we assume that the mirrored animations at least have the same
// framecount
var
  i: Integer;
begin
  with L do
  begin
    LemDX := -LemDX;
    i := AnimationIndices[LemAction, LemRTL];
    LMA := Style.AnimationSet.MetaLemmingAnimations[i];
    LAB := Style.AnimationSet.LemmingAnimations[i];
    LemMaxFrame := LMA.FrameCount - 1;
    LemAnimationType := LMA.AnimationType;
    FrameTopDy  := -LMA.FootY; // ccexplore compatible
    FrameLeftDx := -LMA.FootX; // ccexplore compatible
    if (LemAction = baBuilding) and (LemFrame >= 9) then LayBrick(L);
  end;
end;


function TLemmingGame.AssignSkill(Lemming1, Lemming2: TLemming; aSkill: TBasicLemmingAction): Boolean;
var
  Method: TSkillMethod;
  Proceed: Boolean;
begin
  Result := False;
  Proceed := True;
  Method := Skillmethods[aSkill];
  if Lemming2 = nil then Lemming2 := Lemming1;
  if Assigned(Method) then
  begin
    if CheckGimmick(GIM_DISOBEDIENT) and not fCheckWhichLemmingOnly then
    begin
      WhichLemming := nil;
      fCheckWhichLemmingOnly := true;
      {Result := }Method(Lemming1, Lemming2);
      {if Result then
      begin}
      if not (WhichLemming = nil) then
      begin
        if not (WhichLemming.LemAction in [baJumping, baClimbing, baHoisting, baFalling, baFloating, baShrugging, baSwimming, baGliding, baFixing]) then
        begin
          Proceed := false;
          if (WhichLemming.LemAction in [baWalking, baDigging, baBuilding, baBashing, baMining, baBlocking, baPlatforming, baStacking])
          and not (WhichLemming.LemIsZombie) then
          begin
            Transition(WhichLemming, baShrugging);
            RecordSkillAssignment(WhichLemming, aSkill);
            if not fFreezeSkillCount then OnAssignSkill(WhichLemming, aSkill);
          end;
        end;
      end;
      {end else
        Proceed := false;}
      fCheckWhichLemmingOnly := false;
    end;
    if Lemming2.LemIsZombie then Lemming2 := Lemming1;
    if Lemming1.LemIsZombie then Lemming1 := Lemming2;
    if Lemming1.LemIsZombie and Lemming2.LemIsZombie then Proceed := false;
    if Proceed then Result := Method(Lemming1, Lemming2);
    if Result then
    begin
      CueSoundEffect(SFX_ASSIGN_SKILL);
      if CheckGimmick(GIM_RRFLUC) then
      begin
        if CurrReleaseRate = 99 then
          InstReleaseRate := -99
        else
          InstReleaseRate := 99;
        AdjustReleaseRate(InstReleaseRate);
      end;
    end;
  end;
end;

procedure TLemmingGame.OnAssignSkill(Lemming1: TLemming; aSkill: TBasicLemmingAction);
var
  i: Integer;
begin
  if CheckGimmick(GIM_TURNAROUND) then TurnAround(Lemming1);
  if CheckGimmick(GIM_OTHERSKILL) then
  begin
    UpdateSkillCount(aSkill, true);
    UpdateSkillCount(baWalking);
    UpdateSkillCount(baClimbing);
    UpdateSkillCount(baSwimming);
    UpdateSkillCount(baFloating);
    UpdateSkillCount(baGliding);
    UpdateSkillCount(baFixing);
    UpdateSkillCount(baExploding);
    UpdateSkillCount(baStoning);
    UpdateSkillCount(baBlocking);
    UpdateSkillCount(baPlatforming);
    UpdateSkillCount(baBuilding);
    UpdateSkillCount(baStacking);
    UpdateSkillCount(baBashing);
    UpdateSkillCount(baMining);
    UpdateSkillCount(baDigging);
    UpdateSkillCount(baCloning);
    UpdateSkillCount(aSkill, true);
  end;
  if CheckGimmick(GIM_ASSIGNALL) and (aSkill <> baCloning) then
  begin
    fFreezeSkillCount := true;
    for i := 0 to (LemmingList.Count - 1) do
      if (LemmingList[i] <> Lemming1) and not (LemmingList[i].LemRemoved or LemmingList[i].LemTeleporting) then
      begin
        if not (CheckGimmick(GIM_ONESKILL) and (LemmingList[i].LemUsedSkillCount > 0)) then
        begin
          if AssignSkill(LemmingList[i], LemmingList[i], aSkill) and CheckGimmick(GIM_TURNAROUND) then
            TurnAround(LemmingList[i]);
        end;
      end;
    fFreezeSkillCount := false;
  end;
  if CheckGimmick(GIM_CLONEASSIGN)
  and not (aSkill in [baExploding, baStoning, baBlocking, baDigging, baCloning]) then
  begin
    fFreezeSkillCount := true;
    AssignCloner(Lemming1, nil);
    fFreezeSkillCount := false;
  end;
end;


function TLemmingGame.AssignWalker(Lemming1, Lemming2: TLemming): Boolean;
var
  SelectedLemming: TLemming;
const
  ActionSet = [baWalking, baShrugging, baBlocking, baPlatforming, baBuilding, baStacking, baBashing, baMining, baDigging];
begin
  Result := False;

  {if (CurrWalkerCount = 0) and (CheckGimmick(GIM_OVERFLOW)) and (not (CheckGimmick(GIM_REVERSE))) then
    CurrWalkerCount := 100;}

  if not CheckSkillAvailable(baToWalking) then
    Exit
  else if (Lemming1.LemAction in ActionSet) then
    SelectedLemming := Lemming1
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) then
    SelectedLemming := Lemming2
  else
    Exit;


    if (fCheckWhichLemmingOnly) then
      WhichLemming := SelectedLemming
    else
      begin
        SelectedLemming.LemBecomeBlocker := false;
        Transition(SelectedLemming, baToWalking);
        {if not CheckGimmick(GIM_REVERSE) then
          begin
          if (currWalkerCount <> 200) then Dec(CurrWalkerCount);
          end
        else
          Inc(CurrWalkerCount);
        InfoPainter.DrawSkillCount(spbWalker, CurrWalkerCount);}
        UpdateSkillCount(baToWalking);
        Result := True;
        RecordSkillAssignment(SelectedLemming, baToWalking);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(SelectedLemming, baToWalking);
        end;
      end;

end;


function TLemmingGame.AssignCloner(Lemming1, Lemming2: TLemming): Boolean;
var
  SelectedLemming: TLemming;
  NewL: TLemming;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baBashing, baMining, baDigging,
               baJumping, baFalling, baFloating, baSwimming, baGliding, baFixing];
begin
  Result := False;

  if not CheckSkillAvailable(baCloning) then
    Exit
  else if Lemming1.LemAction in ActionSet then
    SelectedLemming := Lemming1
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) then
    SelectedLemming := Lemming2
  else
    Exit;


    if (fCheckWhichLemmingOnly) then
      WhichLemming := SelectedLemming
    else
      begin
//        Transition(SelectedLemming, baToWalking);
        NewL := TLemming.Create;
        NewL.Assign(SelectedLemming);
        NewL.LemIndex := LemmingList.Count;
        LemmingList.Add(NewL);
        TurnAround(NewL);
        Inc(LemmingsCloned);
        if ((not NewL.LemIsZombie) or CheckGimmick(GIM_OLDZOMBIES)) and (not NewL.LemIsGhost) then Inc(LemmingsOut)
        else Inc(LemmingsRemoved);
        UpdateSkillCount(baCloning);
        Result := True;
        RecordSkillAssignment(SelectedLemming, baCloning);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(SelectedLemming, baCloning);
        end;
        //if CheckGimmick(GIM_ONESKILL) then
          NewL.LemUsedSkillCount := 1{SelectedLemming.LemUsedSkillCount};
        NewL.LemIsClone := true;
      end;

end;



function TLemmingGame.AssignClimber(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if CheckSkillAvailable(baClimbing)
  and not Lemming1.LemIsClimber
  and not (Lemming1.LemAction in [baOhnoing, baStoning, baExploding, baDrowning, baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Lemming1.LemIsClimber := True;
        UpdateSkillCount(baClimbing);
        { TODO : double check if this bug emulation is safe }
        // @Optional Game Mechanics
        if dgoAssignClimberShruggerActionBug in Options then
          if (Lemming1.LemAction = baShrugging) then
            Lemming1.LemAction := baWalking;
        Result := True;
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baClimbing);
        end;
        RecordSkillAssignment(Lemming1, baClimbing);
      end;
  end
end;


function TLemmingGame.AssignSwimmer(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if CheckSkillAvailable(baSwimming)
  and not Lemming1.LemIsSwimmer
  and not (Lemming1.LemAction in [baOhnoing, baStoning, baExploding, {baDrowning,} baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Lemming1.LemIsSwimmer := True;
        if Lemming1.LemAction = baDrowning then Transition(Lemming1, baSwimming);
        UpdateSkillCount(baSwimming);
        Result := True;
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baSwimming);
        end;
        RecordSkillAssignment(Lemming1, baSwimming);
      end;
  end
end;



function TLemmingGame.AssignFloater(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if CheckSkillAvailable(baFloating)
  and not (Lemming1.LemIsFloater or Lemming1.LemIsGlider)
  and not (Lemming1.LemAction in [baOhnoing, baStoning, baExploding, baDrowning, baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Lemming1.LemIsFloater := True;
        UpdateSkillCount(baFloating);
        Result := True;
        RecordSkillAssignment(Lemming1, baFloating);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baFloating);
        end;
      end;
  end
end;


function TLemmingGame.AssignGlider(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if CheckSkillAvailable(baGliding)
  and not (Lemming1.LemIsFloater or Lemming1.LemIsGlider)
  and not (Lemming1.LemAction in [baOhnoing, baStoning, baExploding, baDrowning, baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Lemming1.LemIsGlider := True;
        UpdateSkillCount(baGliding);
        Result := True;
        RecordSkillAssignment(Lemming1, baGliding);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baGliding);
        end;
      end;
  end
end;


function TLemmingGame.AssignMechanic(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;


  if CheckSkillAvailable(baFixing)
  and not Lemming1.LemIsMechanic
  and not (Lemming1.LemAction in [baOhnoing, baStoning, baExploding, baDrowning, baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Lemming1.LemIsMechanic := True;
        UpdateSkillCount(baFixing);
        Result := True;
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baFixing);
        end;
        RecordSkillAssignment(Lemming1, baFixing);
      end;
  end
end;


function TLemmingGame.AssignBomber(Lemming1, Lemming2: TLemming): Boolean;
var
  mbt: Integer;
begin
  Result := False;

  if CheckSkillAvailable(baExploding)
  and not (lemming1.lemAction in [baOhnoing, baStoning, baDrowning, baExploding, baVaporizing, baSplatting, baExiting]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        //if fGameParams.SysDat.Options and 16 = 0 then
        mbt := 1;
        //  else
        //  mbt := 79;
        if (mbt > 1) and (Lemming1.LemExplosionTimer > 0) then Exit;
        Lemming1.LemExplosionTimer := mbt;

        Lemming1.LemTimerToStone := false;
        UpdateSkillCount(baExploding);
        Result := True;
        RecordSkillAssignment(Lemming1, baExploding);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baExploding);
        end;
      end;
  end
end;

function TLemmingGame.AssignStoner(Lemming1, Lemming2: TLemming): Boolean;
var
  //InstantStone : Boolean;
  mbt: Integer;
begin
  Result := False;

  if CheckSkillAvailable(baStoning)
  and (not (lemming1.lemAction in [baOhnoing, baStoning, baDrowning, baExploding, baVaporizing, baSplatting, baExiting])) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        //if fGameParams.SysDat.Options and 16 = 0 then
        mbt := 1;
        //  else
        //  mbt := 79;
        if (mbt > 1) and (Lemming1.LemExplosionTimer > 0) then Exit;
        Lemming1.LemExplosionTimer := mbt;

        Lemming1.LemTimerToStone := true;
        UpdateSkillCount(baStoning);

        Result := True;
        RecordSkillAssignment(Lemming1, baStoning);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baStoning);
        end;
      end;
  end;
end;

function TLemmingGame.AssignBlocker(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if CheckSkillAvailable(baBlocking)
  and (lemming1.LemAction in [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baBashing, baMining, baDigging])
  and (CheckForOverlappingField(Lemming1) = FALSE) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        UpdateSkillCount(baBlocking);
        Transition(Lemming1, baBlocking);
        Result := True;
        RecordSkillAssignment(Lemming1, baBlocking);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baBlocking);
        end;
      end;
  end;
end;


function TLemmingGame.AssignPlatformer(Lemming1, Lemming2: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baBuilding, baStacking, baBashing, baMining, baDigging];
begin
  Result := False;

  if not CheckSkillAvailable(baPlatforming)
  {or ((Lemming1.LemY + Lemming1.FrameTopdy < HEAD_MIN_Y) and not CheckGimmick(GIM_WRAP_VER))} then
    Exit;

  if (Lemming1.LemAction in ActionSet) and LemCanPlatform(Lemming1) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Transition(Lemming1, baPlatforming);
        UpdateSkillCount(baPlatforming);
        Result := True;
        RecordSkillAssignment(Lemming1, baPlatforming);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baPlatforming);
        end;
      end;
  end
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) and LemCanPlatform(Lemming2) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming2
    else
      begin
        Transition(Lemming2, baPlatforming);
        UpdateSkillCount(baPlatforming);
        Result := True;
        RecordSkillAssignment(Lemming2, baPlatforming);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming2, baPlatforming);
        end;
      end;
  end;

end;


function TLemmingGame.AssignBuilder(Lemming1, Lemming2: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baStacking, baBashing, baMining, baDigging];
begin
  Result := False;

  if not CheckSkillAvailable(baBuilding)
  or ((Lemming1.LemY <= 1) and not CheckGimmick(GIM_WRAP_VER)) then
    Exit;

  if (Lemming1.LemAction in ActionSet) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Transition(Lemming1, baBuilding);
        UpdateSkillCount(baBuilding);
        Result := True;
        RecordSkillAssignment(Lemming1, baBuilding);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baBuilding);
        end;
      end;
  end
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming2
    else
      begin
        Transition(Lemming2, baBuilding);
        UpdateSkillCount(baBuilding);
        Result := True;
        RecordSkillAssignment(Lemming2, baBuilding);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming2, baBuilding);
        end;
      end;
  end;

end;


function TLemmingGame.Assignstacker(Lemming1, Lemming2: TLemming): Boolean;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baBashing, baMining, baDigging];
begin
  Result := False;

  if not CheckSkillAvailable(baStacking)
  {or ((Lemming1.LemY + Lemming1.FrameTopdy < HEAD_MIN_Y) and not CheckGimmick(GIM_WRAP_VER))} then
    Exit;

  if (Lemming1.LemAction in ActionSet) {and HasPixelAt(Lemming1.LemX+Lemming1.LemDx, Lemming1.LemY)} then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming1
    else
      begin
        Transition(Lemming1, bastacking);
        UpdateSkillCount(baStacking);
        Result := True;
        RecordSkillAssignment(Lemming1, bastacking);
        Lemming1.LemStackLow := not HasPixelAt(Lemming1.LemX+Lemming1.LemDx, Lemming1.LemY);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baStacking);
        end;
      end;
  end
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) {and HasPixelAt(Lemming2.LemX+Lemming2.LemDx, Lemming2.LemY)} then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := Lemming2
    else
      begin
        Transition(Lemming2, bastacking);
        UpdateSkillCount(baStacking);
        Result := True;
        RecordSkillAssignment(Lemming2, bastacking);
        Lemming2.LemStackLow := not HasPixelAt(Lemming2.LemX+Lemming2.LemDx, Lemming2.LemY);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(Lemming1, baStacking);
        end;
      end;
  end;

end;



function TLemmingGame.AssignBasher(Lemming1, Lemming2: TLemming): Boolean;
var
  SelectedLemming: TLemming;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baMining, baDigging];
begin
  Result := False;

  // selectedLemming := nil; not needed, this var is not used
  if not CheckSkillAvailable(baBashing) then
    Exit
  else if Lemming1.LemAction in ActionSet then
    SelectedLemming := Lemming1
  else if (Lemming2 <> nil) and (Lemming2.LemAction in ActionSet) then
    SelectedLemming := Lemming2
  else
    Exit;

  if (SelectedLemming.LemObjectInFront = DOM_STEEL) then
  begin
    if (not fCheckWhichLemmingOnly) then
      CueSoundEffect(SFX_HITS_STEEL);
    Exit;
  end
  else if ((SelectedLemming.LemObjectInFront = DOM_ONEWAYLEFT) and (SelectedLemming.LemDx <> -1)) or
          ((SelectedLemming.LemObjectInFront = DOM_ONEWAYRIGHT) and (SelectedLemming.LemDx <> 1)) or
          (SelectedLemming.LemObjectInFront = DOM_ONEWAYDOWN) then
    Exit
  else begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := SelectedLemming
    else
      begin
        Transition(SelectedLemming, baBashing);
        UpdateSkillCount(baBashing);
        Result := True;
        RecordSkillAssignment(SelectedLemming, baBashing);
        if not fFreezeSkillCount then
        begin
          OnAssignSkill(SelectedLemming, baBashing);
        end;
      end;
  end;
end;

function TLemmingGame.AssignMiner(Lemming1, Lemming2: TLemming): Boolean;
var
  SelectedLemming: TLemming;
const
  ActionSet = [baWalking, baShrugging, baPlatforming, baBuilding, baStacking, baBashing, baDigging];
begin
  Result := False;

  if not CheckSkillAvailable(baMining) then
    Exit
  else if lemming1.LemAction in ActionSet then
    SelectedLemming := Lemming1
  else if Assigned(Lemming2) and (lemming2.LemAction in ActionSet) then
    SelectedLemming := Lemming2
  else
    Exit;

  with SelectedLemming do
  begin

    if (LemSpecialBelow = DOM_STEEL) then
    begin
      if (not fCheckWhichLemmingOnly) then
        CueSoundEffect(SFX_HITS_STEEL);
      Exit;
    end
    else if ((LemobjectInFront = DOM_ONEWAYLEFT) and (LemDx <> -1))
    or ((LemobjectInFront = DOM_ONEWAYRIGHT) and (LemDx <> 1)) then
      Exit
    else begin
      if (fCheckWhichLemmingOnly) then
        WhichLemming := SelectedLemming
      else
        begin
          Dec(LemY);
          Transition(SelectedLemming, baMining);
          UpdateSkillCount(baMining);
          Result := True;
          RecordSkillAssignment(SelectedLemming, baMining);
          if not fFreezeSkillCount then
          begin
            OnAssignSkill(SelectedLemming, baMining);
          end;
        end;
    end;

  end;
end;

function TLemmingGame.AssignDigger(Lemming1, Lemming2: TLemming): Boolean;
begin
  Result := False;

  if not CheckSkillAvailable(baDigging)
  or (lemming1.LemSpecialBelow = DOM_STEEL) then
    Exit
  else if (lemming1.lemAction in [baWALKING, baSHRUGGING, baPlatforming, baBUILDING, baStacking, baBASHING, baMINING]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := lemming1
    else begin
      Transition(lemming1, baDigging);
      UpdateSkillCount(baDigging);
      Result := True;
      RecordSkillAssignment(Lemming1, baDigging);
      if not fFreezeSkillCount then
      begin
        OnAssignSkill(Lemming1, baDigging);
      end;
    end
  end
  else if Assigned(lemming2) and (not (lemming2.LemSpecialBelow = DOM_STEEL)) and (lemming2.lemAction in [baWALKING, baSHRUGGING, baPlatforming, baBUILDING, baStacking, baBASHING, baMINING]) then
  begin
    if (fCheckWhichLemmingOnly) then
      WhichLemming := lemming2
    else begin
      Transition(lemming2, baDigging);
      UpdateSkillCount(baDigging);
      Result := True;
      RecordSkillAssignment(Lemming2, baDigging);
      if not fFreezeSkillCount then
      begin
        OnAssignSkill(Lemming2, baDigging);
      end;
    end
  end;

end;


function TLemmingGame.UpdateExplosionTimer(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    Dec(LemExplosionTimer);
    //deb([lemexplosiontimer, lemdigit]);
    if LemExplosionTimer > 0 then
      Exit
    else begin
      if LemAction in [baVaporizing, baDrowning, baFloating, baGliding, baFalling, baSwimming] then
      begin
        if LemTimerToStone then
          Transition(L, baStoneFinish)
          else
          Transition(L, baExploding);
        //call CueSoundEffect(EXPLOSION)
      end
      else begin
        if LemTimerToStone then
          Transition(L, baStoning)
          else
          Transition(L, baOhnoing);
        //call CueSoundEffect(OHNO)
      end;
      Result := True;
    end;
  end;
end;

procedure TLemmingGame.CheckForGameFinished;

    (*
    procedure doevent;
    begin

      fTargetIteration := 0;
      fHyperSpeedCounter := 0;
      if HyperSpeed then
        fLeavingHyperSpeed := True;

      SoundMgr.StopMusic(0);

      if assigned(fonfinish) then
        fonfinish(self);
    end; *)

begin

  if fGameFinished then
    Exit;

  if (Minutes <= 0) and (Seconds <= 0) and not ((moTimerMode in fGameParams.MiscOptions) or (fGameParams.Level.Info.TimeLimit > 5999)) then
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
  BlockerMap.SetSize((Level.Info.Width + (OBJMAPOFFSET * 2)), (Level.Info.Height + (OBJMAPOFFSET * 2)));
  BlockerMap.Clear(DOM_NONE);

  ZombieMap.SetSize((Level.Info.Width + (OBJMAPOFFSET * 2)), (Level.Info.Height + (OBJMAPOFFSET * 2)));
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
    if (ObjectInfos[oid].MetaObj.TriggerEffect <> 23) or (ObjectInfos[oid].Obj.IsFake) then Continue;
    SetLength(DosEntryTable, eid+1);
    DosEntryTable[eid] := oid;
    Inc(eid);
    //DosEntryTable[32] := eid;
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

-------------------------------------------------------------------------------}
var
  x, y, x1, y1, i: Integer;
  Inf : TInteractiveObjectInfo;
  S: TSteel;
  Eff, V: Byte;
  //MaxO: Integer;
begin

  ObjectMap.SetSize((Level.Info.Width + (OBJMAPOFFSET * 2)) * 2, (Level.Info.Height + (OBJMAPOFFSET * 2))); //1647, 175
  ObjectMap.Clear(255);

  SpecialMap.SetSize((Level.Info.Width + (OBJMAPOFFSET * 2)), (Level.Info.Height + (OBJMAPOFFSET * 2)));
  SpecialMap.Clear(DOM_NONE);

  WaterMap.SetSize((Level.Info.Width + (OBJMAPOFFSET * 2)), (Level.Info.Height + (OBJMAPOFFSET * 2)));
  WaterMap.Clear(DOM_NONE);

  with ObjectInfos do
  begin

{    // @Optional Game Mechanic
    if dgoDisableObjectsAfter15 in fOptions
    then MaxO := Min(Count - 1, 15)
    else MaxO := Count - 1;
}


    for i := 0 to {MaxO}Count - 1 do
    begin
      Inf := List^[i];
      with Inf, Obj, MetaObj do
      // @Optional Game Mechanic
      if (not (TriggerEffect = 0)) and (not (Obj.IsFake)) then
      begin
        // 0..127   = triggered trap index ()
        // 128..255 = triggereffect (128 is DOM_NONE)
        Eff := TriggerEffect;
        {if Eff = ote_TriggeredTrap then //TEX_TRIGGEREDTRAP then
          V := i
        else if Eff = 11 then
          V := i + 32
        else if Eff = 14 then
          V := i + 64
        else if Eff = 17 then
          V := i + 96
        else}
          V := Eff + DOM_OFFSET;
        if not (V in [DOM_LEMMING, DOM_RECEIVER, DOM_WINDOW, DOM_HINT, DOM_BACKGROUND]) then
        begin
//        if V = DOM_SECRET then LevSecretGoto := (Skill * 256) + TarLev;
          y1 := Top;
          x1 := Left;
          if (DrawingFlags and odf_Flip) <> 0 then
            x1 := x1 + (Width - 1) - TriggerLeft - (TriggerWidth - 1)
          else
            x1 := x1 + TriggerLeft;
          if (DrawingFlags and odf_UpsideDown) <> 0 then
          begin
            y1 := y1 + (Height - 1) - TriggerTop - (TriggerHeight - 1);
            if not (TriggerEffect in [7, 8, 9, 19]) then y1 := y1 + 9;
          end else
            y1 := y1 + TriggerTop;

          for y := y1 to y1 + TriggerHeight - 1 do
            for x := x1 to x1 + TriggerWidth - 1 do
            begin
              if (V in [DOM_STEEL, DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN]) then
              begin
                if (V = DOM_STEEL) or (World.PixelS[x, y] and ALPHA_ONEWAY <> 0) then
                WriteSpecialMap(x, y, V);
              end else if (V in [DOM_WATER]) then
              begin
                WriteWaterMap(x, y, V);
              end else if (V in [DOM_BLOCKER]) then
                WriteBlockerMap(x, y, V)
              else begin
                WriteObjectMap(x, y, i); // traps --> object_id
              end;
            end;
          end;
        end;
      //end;
    end; // for i

  end;

  // map steel
  if ((Level.Info.LevelOptions and 4) = 0)
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
              1: WriteSpecialMap(x, y, DOM_EXIT);
              2: WriteSpecialMap(x, y, DOM_ONEWAYLEFT);
              3: WriteSpecialMap(x, y, DOM_ONEWAYRIGHT);
              4: WriteSpecialMap(x, y, DOM_ONEWAYDOWN);
            end;

    end;
  end;
  end;
end;

procedure TLemmingGame.ApplyAutoSteel;
var
  X, Y: Integer;
  DoAutoSteel : Boolean;
begin
  DoAutoSteel := (((Level.Info.LevelOptions and 2) = 2) or
          (fGameParams.SysDat.Options and 64 <> 0)) and
          (fGameParams.GraphicSet.AutoSteelEnabled);

    with SteelWorld do
    begin
      for x := 0 to (width-1) do
        for y := 0 to (height-1) do
        begin
          if DoAutoSteel then
          begin
            if (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height)
            and (Pixel[X, Y] and ALPHA_STEEL <> 0)
            and (ReadSpecialMap(X, Y) = DOM_NONE) then WriteSpecialMap(X, Y, DOM_STEEL);
          end;
          if ReadSpecialMap(X, Y) = DOM_EXIT then WriteSpecialMap(X, Y, DOM_NONE);
          if CheckGimmick(GIM_INVERTSTEEL) then
          begin
            if ReadSpecialMap(X, Y) = DOM_STEEL then WriteSpecialMap(X, Y, DOM_NONE)
            else if ReadSpecialMap(X, Y) = DOM_NONE then WriteSpecialMap(X, Y, DOM_STEEL);
          end;
          if (ReadSpecialMap(X, Y) = DOM_STEEL) and (World.Pixel[X, Y] and ALPHA_TERRAIN = 0) then WriteSpecialMap(X, Y, DOM_NONE);
          if (ReadSpecialMap(X, Y) = DOM_STEEL) then World.PixelS[X, Y] := World.PixelS[X, Y] and not ALPHA_ONEWAY;
          if (ReadSpecialMap(X, Y) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN]) and (World.Pixel[X, Y] and ALPHA_ONEWAY = 0) then WriteSpecialMap(X, Y, DOM_NONE);
          if (moDebugSteel in fGameParams.MiscOptions) then
          begin
            if ReadSpecialMap(X, Y) <> DOM_STEEL then
              if SteelWorld.Pixel[X, Y] and ALPHA_TERRAIN = 0 then
              begin
                World.Pixel[X, Y] := $00FF00FF;
                SteelWorld.Pixel[X, Y] := $00FF00FF;
              end else begin
                World.Pixel[X, Y] := $01FFFFFF;
                SteelWorld.Pixel[X, Y] := $01FFFFFF;
              end;
          end;
        end;
      fTargetBitmap.Assign(World);
    end;

end;

function TLemmingGame.PrioritizedHitTest(out Lemming1, Lemming2: TLemming;
                                         MousePos: TPoint;
                                         CheckRightMouseButton: Boolean = True): Integer;
{-------------------------------------------------------------------------------
  meant for both prioritized processskillassignment and hittest.
  returns number of hits.
-------------------------------------------------------------------------------}
var
  L, PrioritizedLemming, NonPrioritizedLemming, LowestPriorityLemming: TLemming;
  i, x, y: Integer;
  CP: TPoint;
  CanPrioritize, DoPrioritize, DoAtAll: Boolean;
const
  PrioActions =
    [baBlocking, baPlatforming, baBuilding, baStacking, baShrugging, baBashing, baMining, baDigging];
const
  Sca = 0;
begin
  Result := 0;
  PrioritizedLemming := nil;
  NonPrioritizedLemming := nil;
  Lemming1 := nil;
  Lemming2 := nil;
  CP := MousePos;

  //if fHitTestAutoFail then exit;

  for i := 0 to LemmingList.Count - 1 do
  begin
    L := LemmingList.List^[i];
    with L do
    begin
      if LemRemoved or LemTeleporting
      or ((fSelectDx <> 0) and (fSelectDx <> LemDx))
      or (CheckGimmick(GIM_ONESKILL) and (LemUsedSkillCount > 0))
      or ((ShiftButtonHeldDown and CheckRightMouseButton) and (LemUsedSkillCount > 0))
      or ((RightMouseButtonHeldDown and CheckRightMouseButton) and (LemAction <> baWalking)) then
        Continue;

      CanPrioritize := true;
      DoPrioritize := false;
      DoAtAll := false;

      // Set CanPrioritize to false if the skill cannot be assigned. Need tidier code, but this works
      // for now.
      case fSelectedSkill of
            spbWalker: if L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                          baFalling, baFloating, baSplatting, baExiting,
                                          baVaporizing, baOhnoing, baExploding, baStoning,
                                          baStoneFinish, baSwimming, baGliding, baFixing]
                       then CanPrioritize := false;
            spbClimber: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                            baOhnoing, baExploding, baStoning, baStoneFinish])
                        or (L.LemIsClimber) then CanPrioritize := false;
            spbSwimmer: if (L.LemAction in [{baDrowning,} baSplatting, baExiting, baVaporizing, // we don't want to deprioritize drowners
                                            baOhnoing, baExploding, baStoning, baStoneFinish])  // for assigning the Swimmer skill!
                        or (L.LemIsSwimmer or L.LemIsGhost) then CanPrioritize := false;
            spbUmbrella: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                             baOhnoing, baExploding, baStoning, baStoneFinish])
                         or (L.LemIsFloater or L.LemIsGlider) then CanPrioritize := false;
            spbGlider: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                           baOhnoing, baExploding, baStoning, baStoneFinish])
                       or (L.LemIsFloater or L.LemIsGlider) then CanPrioritize := false;
            spbMechanic: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                             baOhnoing, baExploding, baStoning, baStoneFinish])
                         or (L.LemIsMechanic or L.LemIsGhost) then CanPrioritize := false;
            spbExplode: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                            baOhnoing, baExploding, baStoning, baStoneFinish])
                        then CanPrioritize := false;
            spbStoner: if (L.LemAction in [baDrowning, baSplatting, baExiting, baVaporizing,
                                           baOhnoing, baExploding, baStoning, baStoneFinish])
                       then CanPrioritize := false;
            spbBlocker: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing])
                        then CanPrioritize := false;
            spbPlatformer: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baPlatforming])
                           then CanPrioritize := false;
            spbBuilder: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baBuilding])
                        then CanPrioritize := false;
            spbStacker: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baStacking])
                        then CanPrioritize := false;
            spbBasher: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baBashing])
                       then CanPrioritize := false;
            spbMiner: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baMining])
                      then CanPrioritize := false;
            spbDigger: if (L.LemAction in [baJumping, baClimbing, baDrowning, baHoisting,
                                            baFalling, baFloating, baSplatting, baExiting,
                                            baVaporizing, baBlocking, baOhnoing, baExploding,
                                            baStoning, baStoneFinish, baSwimming, baGliding,
                                            baFixing, baDigging])
                        then CanPrioritize := false;
            spbCloner: if (L.LemAction in [baJumping, baDigging, baClimbing, baDrowning, baHoisting,
                                           baSplatting, baExiting, baVaporizing, baBlocking, baOhnoing,
                                           baExploding, baStoning, baStoneFinish, baFixing])
                       then CanPrioritize := false;
      end;
      if L.LemIsZombie then CanPrioritize := false;

      x := LemX + FrameLeftDx;
      y := LemY + FrameTopDy;
      if (x <= CP.X) and (CP.X <= x + 12) and (y <= CP.Y) and (CP.Y <= y + 12) then
      begin
        Inc(Result);
        DoAtAll := true;
        DoPrioritize := (LemAction in PrioActions);
        //Continue;
      end;

      if CheckGimmick(GIM_WRAP_HOR) and not DoAtAll then //don't duplicate effort
      begin
        if x < 0 then x := x + World.Width
        else if x + 12 >= World.Width then x := x - World.Width;
        if (x <= CP.X) and (CP.X <= x + 12) and (y <= CP.Y) and (CP.Y <= y + 12) then
        begin
          Inc(Result);
          DoAtAll := true;
          DoPrioritize := (LemAction in PrioActions);
          //Continue;
        end;
      end;

      if CheckGimmick(GIM_WRAP_VER) and not DoAtAll then
      begin
        if y < 0 then y := y + World.Height
        else if y + 12 >= World.Height then y := y - World.Height;
        if (x <= CP.X) and (CP.X <= x + 12) and (y <= CP.Y) and (CP.Y <= y + 12) then
        begin
          Inc(Result);
          DoAtAll := true;
          DoPrioritize := (LemAction in PrioActions);
          //Continue;
        end;

        if CheckGimmick(GIM_WRAP_HOR) and not DoAtAll then
        begin
          if x < World.Width div 2 then x := x + World.Width
          else if x + 12 >= World.Width div 2 then x := x - World.Width;
          if (x <= CP.X) and (CP.X <= x + 12) and (y <= CP.Y) and (CP.Y <= y + 12) then
          begin
            Inc(Result);
            DoAtAll := true;
            DoPrioritize := (LemAction in PrioActions);
            //Continue;
          end;
        end;
      end;

      if DoAtAll then
      begin
        if (CanPrioritize and DoPrioritize) then
          PrioritizedLemming := L
        else if CanPrioritize then
          NonPrioritizedLemming := L
        else
          LowestPriorityLemming := L;
      end;

    end;
  end; // for

  if NonPrioritizedLemming <> nil then
    LastNPLemming := NonPrioritizedLemming;

  if NonPrioritizedLemming = nil then NonPrioritizedLemming := LowestPriorityLemming;
  if PrioritizedLemming = nil then PrioritizedLemming := NonPrioritizedLemming;

  if (PrioritizedLemming = nil) then
    Lemming1 := NonPrioritizedLemming
  else
    Lemming1 := PrioritizedLemming;

  Lemming2 := NonPrioritizedLemming;
end;


procedure TLemmingGame.InitializeMiniMap;
{-------------------------------------------------------------------------------
  Put the terrainpixels in the minimap. Copy them (scaled) from the worldbitmap.
  During the game the minimap will be updated like the world-bitmap gets updated.
  The lemming-pixels are not drawn in the minimap: these are drawn in the
  MiniMapBuffer.
------------------------------------------------------------------------------}
var
  OldCombine: TPixelCombineEvent;
  OldMode: TDrawMode;
  SrcRect, DstRect: TRect;
begin
  //Minimap.SetSize(DOS_MINIMAP_WIDTH, DOS_MINIMAP_HEIGHT);
  Minimap.SetSize(World.Width div 16, World.Height div 8);
  Minimap.Clear(0);
  OldCombine := World.OnPixelCombine;
  OldMode := World.DrawMode;
  World.DrawMode := dmCustom;
  World.OnPixelCombine := CombineMinimapWorldPixels;
  SrcRect := World.BoundsRect;
  DstRect := Rect(0, 0, World.Width div 16, World.Height div 8);
//  OffsetRect(DstRect, 1, 0);
  World.DrawTo(Minimap, DstRect, SrcRect);
  World.OnPixelCombine := OldCombine;
  World.DrawMode := OldMode;
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

procedure TLemmingGame.UpdateLemmingsIn(Num, Max: Integer);
var
  i: Integer;
begin
  if (fGameParams.UsePercentages = 2) and ((Level.Info.SkillTypes and 1) <> 0) then
  begin
    Max := Max + Level.Info.ClonerCount;
    for i := 0 to ObjectInfos.Count-1 do
      if (ObjectInfos[i].MetaObj.TriggerEffect = 14) and (ObjectInfos[i].Obj.Skill = 15) then Max := Max + 1;
  end;
  {if fGameParams.ShowNeeded then} Num := Num - Level.Info.RescueCount;
  if fGameParams.UsePercentages <> 0 then
    InfoPainter.SetInfoLemmingsIn(Num, Max, CheckRescueBlink)
    else
    InfoPainter.SetInfoLemmingsIn(Num, 0, CheckRescueBlink);
end;

procedure TLemmingGame.CheckForInteractiveObjects(L: TLemming; HandleAllObjects: Boolean = true);
var
//  Dst: TRect;
  Inf: TInteractiveObjectInfo;
  BlockCheck: Byte;
  GhostCheck: Byte;
  ni, dy, NewY: Integer;
  mx, my: Integer;
  minmx, minmy: Integer;
  //tlx, tly: Integer;
  DoneAutoAssign: Boolean;
  AutoAssignSkill: TBasicLemmingAction;
begin
  with L do
  begin

    if (not HandleAllObjects) and (LemAction <> baBlocking) then Exit;

    LemObjectIDBelow := ReadObjectMap(LemX, LemY);
    LemObjectBelow := ReadObjectMapType(LemX, LemY);
    LemSpecialBelow := ReadSpecialMap(LemX, LemY);
    LemObjectInFront := ReadSpecialMap((LemX + 4 * LemDx), LemY - 5);
    BlockCheck := ReadBlockerMap(LemX, LemY);
    GhostCheck := ReadZombieMap(LemX, LemY) and 6;

    if (not LemIsGhost) and (GhostCheck <> 6) and not (BlockCheck in [DOM_FORCELEFT, DOM_FORCERIGHT]) then
    begin
      if (GhostCheck and 2) <> 0 then BlockCheck := DOM_FORCELEFT;
      if (GhostCheck and 4) <> 0 then BlockCheck := DOM_FORCERIGHT;
    end;

    if LemIsGhost then
    begin
      LemObjectBelow := DOM_NONE;
      LemObjectIDBelow := DOM_NOOBJECT;
      BlockCheck := DOM_NONE;
      //GhostCheck := 0;
      //if LemObjectInFront <> DOM_STEEL then LemObjectInFront := DOM_NONE;
    end;

    if (not LemObjectBelow in [DOM_TRAP, DOM_TRAPONCE]) and (LemInTrap = 1) then LemInTrap := 0;

    case LemObjectBelow of
      // DOM_NONE = 128 = nothing
     // DOM_NONE:
      //  Exit;
      // 0..127 triggered objects
      DOM_TRAP:
        if (LemIsMechanic) and (not (LemAction in [baClimbing, baHoisting, baSwimming])) and HasPixelAt(LemX, LemY) and HandleAllObjects then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          if not Inf.Triggered then
          begin
            minmx := (Inf.Obj.Left + Inf.MetaObj.TriggerLeft);
            minmy := (Inf.Obj.Top + Inf.MetaObj.TriggerTop);

            if Inf.Obj.DrawingFlags and odf_Flip <> 0 then
              minmx := minmx + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft * 2) - (Inf.MetaObj.TriggerWidth - 1);

            if Inf.Obj.DrawingFlags and odf_UpsideDown <> 0 then
              minmy := minmy + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop * 2) - (Inf.MetaObj.TriggerHeight - 1) + 9;

            for mx := minmx to (minmx + Inf.MetaObj.TriggerWidth - 1) do
              for my := minmy to (minmy + Inf.MetaObj.TriggerHeight - 1) do
                if ReadObjectMap(mx, my) = LemObjectIDBelow then
                  WriteObjectMap(mx, my, DOM_NOOBJECT);
            Transition(L, baFixing);
          end;
        end else
        if ((not CheckGimmick(GIM_INVINCIBLE)) and HandleAllObjects) and (LemInTrap = 0) then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          if not Inf.Triggered then
          begin
            // trigger
            Inf.Triggered := True;
            Inf.ZombieMode := L.LemIsZombie;
            LemInTrap := Inf.MetaObj.AnimationFrameCount;
            //Inc(Inf.CurrentFrame);
            //if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
            //begin
            //  Inf.CurrentFrame := 0;
            //  Inf.ZombieMode := false;
            //end;
            RemoveLemming(L, RM_KILL);
            CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
            if DelayEndFrames < Inf.MetaObj.AnimationFrameCount then DelayEndFrames := Inf.MetaObj.AnimationFrameCount;
          end;
        end;
     DOM_TRAPONCE:
        if (LemIsMechanic) and (not (LemAction in [baClimbing, baHoisting, baSwimming])) and HasPixelAt(LemX, LemY) and HandleAllObjects then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          if not Inf.Triggered then
          begin
            minmx := (Inf.Obj.Left + Inf.MetaObj.TriggerLeft);
            minmy := (Inf.Obj.Top + Inf.MetaObj.TriggerTop);

            if Inf.Obj.DrawingFlags and odf_Flip <> 0 then
              minmx := minmx + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft * 2) - (Inf.MetaObj.TriggerWidth - 1);

            if Inf.Obj.DrawingFlags and odf_UpsideDown <> 0 then
              minmy := minmy + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop * 2) - (Inf.MetaObj.TriggerHeight - 1) + 9;

            for mx := minmx to (minmx + Inf.MetaObj.TriggerWidth - 1) do
              for my := minmy to (minmy + Inf.MetaObj.TriggerHeight - 1) do
                if ReadObjectMap(mx, my) = LemObjectIDBelow then
                  WriteObjectMap(mx, my, DOM_NOOBJECT);
            Transition(L, baFixing);
          end;
        end else
        if ((not CheckGimmick(GIM_INVINCIBLE)) and HandleAllObjects) and (LemInTrap = 0) then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          if not (Inf.Triggered or (Inf.CurrentFrame = 0)) then
          begin
            // trigger
            Inf.Triggered := True;
            Inf.ZombieMode := L.LemIsZombie;
            LemInTrap := Inf.MetaObj.AnimationFrameCount;
            //Inc(Inf.CurrentFrame);
            //if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
            //begin
            //  Inf.CurrentFrame := 0;
            //  Inf.ZombieMode := false;
            //end;
            RemoveLemming(L, RM_KILL);
            CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
            if DelayEndFrames < Inf.MetaObj.AnimationFrameCount then DelayEndFrames := Inf.MetaObj.AnimationFrameCount;
          end;
        end;
     DOM_ANIMATION:
       if HandleAllObjects then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          if not Inf.Triggered then
          begin
            Inf.Triggered := True;
            //Inc(Inf.CurrentFrame);
            //if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
            //  Inf.CurrentFrame := 0;
            CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
          end;
        end;
     DOM_SINGLETELE:
       if HandleAllObjects then
       begin
         Inf := ObjectInfos[LemObjectIDBelow];
         if (not Inf.Triggered) then
         begin
           Inf.Triggered := True;
           Inf.ZombieMode := L.LemIsZombie;
           //Inc(Inf.CurrentFrame);
           CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
           LemTeleporting := True;
           Inf.TeleLem := L.LemIndex;

           {if Inf.Obj.DrawingFlags and 8 <> 0 then TurnAround(L);

           if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerPointY)
               else
               tly := Inf.Obj.Top + Inf.MetaObj.TriggerPointY;
           if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerPointX)
               else
               tlx := Inf.Obj.Left + Inf.MetaObj.TriggerPointX;

           LemX := tlx;
           LemY := tly;}

           MoveLemToReceivePoint(L, LemObjectIDBelow);

         end;
       end;
     DOM_TELEPORT:
       if (not (FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill) = (LemObjectIDBelow))) and HandleAllObjects then
       begin
         Inf := ObjectInfos[LemObjectIDBelow];
         if (not Inf.Triggered) and (not (ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)].Triggered
                                     or ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)].HoldActive) ) then
         begin
           Inf.Triggered := True;
           Inf.ZombieMode := L.LemIsZombie;
           //Inc(Inf.CurrentFrame);
           CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
           LemTeleporting := True;
           Inf.TeleLem := L.LemIndex;
           Inf.TwoWayReceive := false;
           ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)].HoldActive := True;
           //if Inf.Obj.DrawingFlags and 8 <> 0 then TurnAround(L);
           //if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
           //  begin
           //  Inf.CurrentFrame := 0;
           //  Inf.ZombieMode := false;
           //  Inf.Triggered := False;

             {if not CheckGimmick(GIM_CHEAPOMODE) then
             begin

             if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop) - (Inf.MetaObj.TriggerHeight - 1)
               else
               tly := Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft) - (Inf.MetaObj.TriggerWidth - 1)
               else
               tlx := Inf.Obj.Left + Inf.MetaObj.TriggerLeft;
             tlx := LemX - tlx;
             tly := LemY - tly;
             if Inf.Obj.DrawingFlags and 8 <> 0 then
               tlx := Inf.MetaObj.TriggerWidth - tlx - 1;
             Inf := ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)];
             if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := tly + Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop) - (Inf.MetaObj.TriggerHeight - 1)
               else
               tly := tly + Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := tlx + Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft) - (Inf.MetaObj.TriggerWidth - 1)
               else
               tlx := tlx + Inf.Obj.Left + Inf.MetaObj.TriggerLeft;

             end else begin

             {if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop)
               else
               tly := Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft)
               else
               tlx := Inf.Obj.Left + Inf.MetaObj.TriggerLeft;}
             {tlx := 0; //LemX - tlx;
             tly := 0; //LemY - tly;
             if Inf.Obj.DrawingFlags and 8 <> 0 then
               tlx := Inf.MetaObj.TriggerWidth - tlx - 1;
             Inf := ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)];
             if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := tly + Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop)
               else
               tly := tly + Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := tlx + Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft)
               else
               tlx := tlx + Inf.Obj.Left + Inf.MetaObj.TriggerLeft;

             end;

             LemX := tlx;
             LemY := tly;}
             //MoveLemToReceivePoint(L, LemObjectIDBelow);
             //Inf.TeleLem := L.LemIndex;
             //Inf.TwoWayReceive := true;
             //ObjectInfos[FindReceiver(LemObjectIDBelow, ObjectInfos[LemObjectIDBelow].Obj.Skill)].Triggered := True;
             //end;
         end;
       end;
     DOM_PICKUP:
       if HandleAllObjects and ((not L.LemIsZombie) or CheckGimmick(GIM_OLDZOMBIES)) then
       begin
         Inf := ObjectInfos[LemObjectIDBelow];
         if Inf.CurrentFrame <> 0 then
         begin
           Inf.CurrentFrame := 0;
           CueSoundEffect(SFX_PICKUP);
           if CheckGimmick(GIM_INSTANTPICKUP) then
           begin
             fFreezeSkillCount := true;
             fFreezeRecording := true;
             case Inf.Obj.Skill of
               0: AutoAssignSkill := baClimbing;
               1: AutoAssignSkill := baFloating; //if AssignSkill(L, nil, baFloating) = false then UpdateSkillCount(baFloating, true);
               2: AutoAssignSkill := baExploding; //if AssignSkill(L, nil, baExploding) = false then UpdateSkillCount(baExploding, true);
               3: AutoAssignSkill := baBlocking; //if AssignSkill(L, nil, baBlocking) = false then UpdateSkillCount(baBlocking, true);
               4: AutoAssignSkill := baBuilding; //if AssignSkill(L, nil, baBuilding) = false then UpdateSkillCount(baBuilding, true);
               5: AutoAssignSkill := baBashing; //if AssignSkill(L, nil, baBashing) = false then UpdateSkillCount(baBashing, true);
               6: AutoAssignSkill := baMining; //if AssignSkill(L, nil, baMining) = false then UpdateSkillCount(baMining, true);
               7: AutoAssignSkill := baDigging; //if AssignSkill(L, nil, baDigging) = false then UpdateSkillCount(baDigging, true);
               8: AutoAssignSkill := baToWalking; //if AssignSkill(L, nil, baToWalking) = false then UpdateSkillCount(baToWalking, true);
               9: AutoAssignSkill := baSwimming; //if AssignSkill(L, nil, baSwimming) = false then UpdateSkillCount(baSwimming, true);
               10: AutoAssignSkill := baGliding; //if AssignSkill(L, nil, baGliding) = false then UpdateSkillCount(baGliding, true);
               11: AutoAssignSkill := baFixing; //if AssignSkill(L, nil, baFixing) = false then UpdateSkillCount(baFixing, true);
               12: AutoAssignSkill := baStoning; //if AssignSkill(L, nil, baStoning) = false then UpdateSkillCount(baStoning, true);
               13: AutoAssignSkill := baPlatforming; //if AssignSkill(L, nil, baPlatforming) = false then UpdateSkillCount(baPlatforming, true);
               14: AutoAssignSkill := baStacking; //if AssignSkill(L, nil, baStacking) = false then UpdateSkillCount(baStacking, true);
               15: AutoAssignSkill := baCloning; //if AssignSkill(L, nil, baCloning) = false then UpdateSkillCount(baCloning, true);
               else raise Exception.Create('Pickup skill refers to invalid skill!');
             end;
             DoneAutoAssign := AssignSkill(L, nil, AutoAssignSkill);
             fFreezeRecording := false;
             fFreezeSkillCount := false;
             if not DoneAutoAssign then UpdateSkillCount(AutoAssignSkill, true);
             if DoneAutoAssign and (AutoAssignSkill in [baExploding, baStoning]) then
               UpdateExplosionTimer(L);
           end else
             case Inf.Obj.Skill of
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
     DOM_BUTTON:
       if HandleAllObjects and ((not L.LemIsZombie) or CheckGimmick(GIM_OLDZOMBIES)) then
       begin
         Inf := ObjectInfos[LemObjectIDBelow];
         if (Inf.CurrentFrame = 1) and not (Inf.Triggered) then
         begin
           CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
           Inf.Triggered := true;
           Dec(ButtonsRemain);
           if ButtonsRemain = 0 then
           begin
             CueSoundEffect(SFX_ENTRANCE);
             for ni := 0 to (ObjectInfos.Count - 1) do
             begin
               if ObjectInfos[ni].MetaObj.TriggerEffect = 15 then ObjectInfos[ni].Triggered := true;
             end;
           end;
         end;
       end;
      // 128 + n (continuous objects, staticobjects, steel, oneway wall)
      DOM_EXIT:
      if not (L.LemAction in [baFalling, baSplatting]) then
      begin
        Inf := ObjectInfos[LemObjectIDBelow];
        if not LemIsZombie then
        begin

          if Inf.MetaObj.AnimationType in [0, 2] then
          begin
            Transition(L, baExiting);
            CueSoundEffect(SFX_YIPPEE);
          end else begin
            if not Inf.Triggered then
            begin
              RemoveLemming(L, RM_SAVE);
              Inf.Triggered := True;
              Inf.ZombieMode := L.LemIsZombie;
              if Inf.MetaObj.SoundEffect = 0 then
                CueSoundEffect(SFX_YIPPEE)
              else
                CueSoundEffect(GetTrapSoundIndex(Inf.MetaObj.SoundEffect));
              if DelayEndFrames < Inf.MetaObj.AnimationFrameCount then DelayEndFrames := Inf.MetaObj.AnimationFrameCount;
            end;
          end;
        end;
      end;
      DOM_LOCKEXIT:
      if not (L.LemAction in [baFalling, baSplatting]) then
        if not LemIsZombie then
        begin
          //if LemAction <> baFalling then
          //begin
          if ButtonsRemain = 0 then
            begin
            Transition(L, baExiting);
            CueSoundEffect(SFX_YIPPEE);
            end;
          //end;
        end;
      DOM_RADIATION:
        begin
          if (L.LemExplosionTimer = 0) and not (L.LemAction in [baOhnoing, baStoning]) then
          begin
           L.LemExplosionTimer := 143;
          end;
        end;
      DOM_SLOWFREEZE:
        begin
          if (L.LemExplosionTimer = 0) and not (L.LemAction in [baOhnoing, baStoning]) then
          begin
            L.LemExplosionTimer := 143;
            L.LemTimerToStone := true;
          end;
        end;
      DOM_FORCELEFT:
        if (((LemDx > 0) and (not CheckGimmick(GIM_BACKWARDS))) or
           ((LemDx > 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction <> baWalking))) or
           ((LemDx < 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction = baWalking))))
           and HandleAllObjects
           and not (LemAction in [baClimbing, baHoisting]) then
          begin
          dy := 0;
          NewY := LemY;
          while (dy <= 8) and (HasPixelAt_ClipY(LemX-1, NewY + 1, -dy - 1) = TRUE) do
          begin
            Inc(dy);
            Dec(NewY);
          end;
          if dy < 9 then
            TurnAround(L);
          end;
      DOM_FORCERIGHT:
        if (((LemDx < 0) and (not CheckGimmick(GIM_BACKWARDS))) or
           ((LemDx < 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction <> baWalking))) or
           ((LemDx > 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction = baWalking))))
           and HandleAllObjects
           and not (LemAction in [baClimbing, baHoisting]) then
          begin
          dy := 0;
          NewY := LemY;
          while (dy <= 8) and (HasPixelAt_ClipY(LemX+1, NewY + 1, -dy - 1) = TRUE) do
          begin
            Inc(dy);
            Dec(NewY);
          end;
          if dy < 9 then
            TurnAround(L);
          end;
      DOM_FIRE:
        if not CheckGimmick(GIM_INVINCIBLE) then
        begin
          Transition(L, baVaporizing);
          CueSoundEffect(SFX_VAPORIZING);
        end;
      DOM_SECRET:
        if not L.LemIsZombie then
        begin
          Inf := ObjectInfos[LemObjectIDBelow];
          LevSecretGoto := (Inf.Obj.Skill * 256) + Inf.Obj.TarLev;
          fSecretGoto := LevSecretGoto;
          DoTalismanCheck(true);
          Finish;
        end;
      DOM_FLIPPER:
        if HandleAllObjects then
        begin
          if not (LemInFlipper = LemObjectIDBelow) then
          begin
            Inf := ObjectInfos[LemObjectIDBelow];
            if (Inf.CurrentFrame = 1) xor (LemDX < 0) then TurnAround(L);
            if (Inf.CurrentFrame = 1) then
            begin
              //Inf.Obj.DrawingFlags := Inf.Obj.DrawingFlags and not 8;
              Inf.CurrentFrame := 0;
            end else begin
              //Inf.Obj.DrawingFlags := Inf.Obj.DrawingFlags or 8;
              Inf.CurrentFrame := 1;
            end;
            LemInFlipper := LemObjectIDBelow;
          end;
        end;
    end;

    if LemObjectBelow <> DOM_FLIPPER then LemInFlipper := DOM_NOOBJECT;

    if (ReadWaterMap(LemX, LemY) = DOM_WATER) and not LemIsGhost then
    begin
      if (LemY > World.Height) and not CheckGimmick(GIM_WRAP_VER) then
        if ReadWaterMap(LemX, World.Height-1) = DOM_WATER then LemY := World.Height-1;
      if LemY < World.Height then
      begin
        if L.LemIsSwimmer then
        begin
          if not (L.LemAction in [baSwimming, baClimbing, baHoisting, baOhnoing, baExploding, baStoning, baStoneFinish, baVaporizing, baExiting, baSplatting]) then
          begin               
            LemBecomeBlocker := false;
            Transition(L, baSwimming);
            CueSoundEffect(SFX_SWIMMING);
          end;
        end else begin
          if not (CheckGimmick(GIM_INVINCIBLE) or (L.LemAction in [baSwimming, baExploding, baStoneFinish, baVaporizing, baExiting, baSplatting])) then
          begin
            Transition(L, baDrowning);
            CueSoundEffect(SFX_DROWNING);
          end;
        end;
      end;
    end;

    case BlockCheck of   
      DOM_FORCELEFT:
        if (((LemDx > 0) and (not CheckGimmick(GIM_BACKWARDS))) or
           ((LemDx > 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction <> baWalking))) or
           ((LemDx < 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction = baWalking))))
           and not (LemAction in [baClimbing, baHoisting])then
        begin
          dy := 0;
          NewY := LemY;
          while (dy <= 8) and (HasPixelAt_ClipY(LemX-1, NewY + 1, -dy - 1) = TRUE) do
          begin
            Inc(dy);
            Dec(NewY);
          end;
          if dy < 9 then
            TurnAround(L);
        end;
      DOM_FORCERIGHT:
        if (((LemDx < 0) and (not CheckGimmick(GIM_BACKWARDS))) or
           ((LemDx < 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction <> baWalking))) or
           ((LemDx > 0) and ((CheckGimmick(GIM_BACKWARDS)) and (LemAction = baWalking))))
           and not (LemAction in [baClimbing, baHoisting]) then
        begin
          dy := 0;
          NewY := LemY;
          while (dy <= 8) and (HasPixelAt_ClipY(LemX+1, NewY + 1, -dy - 1) = TRUE) do
          begin
            Inc(dy);
            Dec(NewY);
          end;
          if dy < 9 then
            TurnAround(L);
        end;
      end;
  end;

end;


procedure TLemmingGame.ApplyStoneLemming(L: TLemming; Redo: Integer = 0);
var
  {X, Y,} X1, Y1: Integer;
  //T: TColor32;
begin

  if L.LemDx = 1 then Inc(L.LemX);

  StoneLemBmp.DrawTo(World, L.LemX - 8, L.LemY -10);
  if not HyperSpeed then
    StoneLemBmp.DrawTo(fTargetBitmap, L.LemX - 8, L.LemY -10);

if CheckGimmick(GIM_INVERTSTEEL) then
begin
  for X1 := L.LemX - 8 to L.LemX + 7 do
  for Y1 := L.LemY - 14 to L.LemY + 7 do
  begin
    if (X1 >= 0) and (Y1 >= 0)
    and (X1 < World.Width) and (Y1 < World.Height) then
      if World[X1, Y1] <> SteelWorld[X1, Y1] then
        WriteSpecialMap(X1, Y1, DOM_STEEL);
  end;
end;

  if L.LemDx = 1 then Dec(L.LemX);

  if CheckGimmick(GIM_WRAP_HOR) and (Redo <> 1) then
  begin
    L.LemX := L.LemX - World.Width;
    ApplyStoneLemming(L, 1);
    L.LemX := L.LemX + (World.Width * 2);
    ApplyStoneLemming(L, 1);
    L.LemX := L.LemX - World.Width;
  end;

  if CheckGimmick(GIM_WRAP_VER) and (Redo = 0) then
  begin
    L.LemY := L.LemY - World.Height;
    ApplyStoneLemming(L, 2);
    L.LemY := L.LemY + (World.Height * 2);
    ApplyStoneLemming(L, 2);
    L.LemY := L.LemY - World.Height;
  end;

  if redo = 0 then
  begin
    SteelWorld.Assign(World);
    InitializeMinimap;
  end;

end;


procedure TLemmingGame.ApplyExplosionMask(L: TLemming; Redo: Integer = 0);
var
  {X, Y,} X1, Y1: Integer;
  Px, Py: Integer;
  //T: TColor32;
begin
  // dos explosion mask 16 x 22

  if not L.LemRTL then L.LemX := L.LemX + 1;

  if CheckGimmick(GIM_NUCLEAR) then
  begin
    px := L.LemX - 24;
    py := L.LemY - 36;
  end else begin
    px := L.LemX - 8;
    py := L.LemY - 14;
  end;

  ExplodeMaskBmp.DrawTo(World, px, py);
  if not HyperSpeed then
    ExplodeMaskBmp.DrawTo(fTargetBitmap, px, py);


  for X1 := L.LemX - 24 to L.LemX + 23 do
  for Y1 := L.LemY - 36 to L.LemY + 35 do
  begin
    if (X1 >= 0) and (X1 < World.Width) and (Y1 >= 0) and (Y1 < World.Height) then
    begin
      if ReadSpecialMap(X1, Y1) = DOM_STEEL then
      begin
        World[X1, Y1] := SteelWorld[X1, Y1];
        fTargetBitmap[X1, Y1] := SteelWorld[X1, Y1];
      end;
      if (ReadSpecialMap(X1, Y1) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN])
         and (World[X1, Y1] <> SteelWorld[X1, Y1]) then
        WriteSpecialMap(X1, Y1, DOM_NONE);
    end;
  end;

  if not L.LemRTL then L.LemX := L.LemX - 1;


  if CheckGimmick(GIM_WRAP_HOR) and (Redo <> 1) then
  begin
    L.LemX := L.LemX - World.Width;
    ApplyExplosionMask(L, 1);
    L.LemX := L.LemX + (World.Width * 2);
    ApplyExplosionMask(L, 1);
    L.LemX := L.LemX - World.Width;
  end;

  if CheckGimmick(GIM_WRAP_VER) and (Redo = 0) then
  begin
    L.LemY := L.LemY - World.Height;
    ApplyExplosionMask(L, 2);
    L.LemY := L.LemY + (World.Height * 2);
    ApplyExplosionMask(L, 2);
    L.LemY := L.LemY - World.Height;
  end;

  if redo = 0 then
  begin
    SteelWorld.Assign(World);
    InitializeMinimap;
  end;

end;

procedure TLemmingGame.ApplyBashingMask(L: TLemming; MaskFrame: Integer; Redo: Integer = 0);
var
  Bmp: TBitmap32;
  S, D: TRect;
  {X, Y,} X1, Y1: Integer;
begin

  // dos bashing mask = 16 x 10

  if not L.LemRTL then
    Bmp := BashMasks
  else
    Bmp := BashMasksRTL;

  S := CalcFrameRect(Bmp, 4, MaskFrame);
  D.Left := L.LemX - 8;
  D.Top := L.LemY - 10;
  D.Right := D.Left + 16;
  D.Bottom := D.Top + 10;

  Assert(CheckRectCopy(D, S), 'bash rect err');

  Bmp.DrawTo(World, D, S);
  if not HyperSpeed then
    Bmp.DrawTo(fTargetBitmap, D, S);

  for X1 := D.Left to D.Right do
  for Y1 := D.Top to D.Bottom do
  if (X1 >= 0) and (X1 < World.Width) and (Y1 >= 0) and (Y1 < World.Height) then
  begin
    if ReadSpecialMap(X1, Y1) = DOM_STEEL then
    begin
      {T := SteelWorld.Pixel[X1, Y1];
      World.SetPixelTS(X1, Y1, T);
      fTargetBitmap.SetPixelTS(X1, Y1, T);}
      World[X1, Y1] := SteelWorld[X1, Y1];
      fTargetBitmap[X1, Y1] := SteelWorld[X1, Y1];
    end;
    if {(not L.LemIsGhost) and}
       (((ReadSpecialMap(X1, Y1) = DOM_ONEWAYLEFT) and (L.LemDX > 0)) or
       ((ReadSpecialMap(X1, Y1) = DOM_ONEWAYRIGHT) and (L.LemDX < 0)) or
       (ReadSpecialMap(X1, Y1) = DOM_ONEWAYDOWN)) then
    begin
      World[X1, Y1] := SteelWorld[X1, Y1];
      fTargetBitmap[X1, Y1] := SteelWorld[X1, Y1];
    end;
    if (World[X1, Y1] <> SteelWorld[X1, Y1])
    and (ReadSpecialMap(X1, Y1) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN]) then
      WriteSpecialMap(X1, Y1, DOM_NONE);
  end;

  if CheckGimmick(GIM_WRAP_HOR) and (Redo <> 1) then
  begin
    L.LemX := L.LemX - World.Width;
    ApplyBashingMask(L, MaskFrame, 1);
    L.LemX := L.LemX + (World.Width * 2);
    ApplyBashingMask(L, MaskFrame, 1);
    L.LemX := L.LemX - World.Width;
  end;

  if CheckGimmick(GIM_WRAP_VER) and (Redo = 0) then
  begin
    L.LemY := L.LemY - World.Height;
    ApplyBashingMask(L, MaskFrame, 2);
    L.LemY := L.LemY + (World.Height * 2);
    ApplyBashingMask(L, MaskFrame, 2);
    L.LemY := L.LemY - World.Height;
  end;

  if redo = 0 then
  begin
    SteelWorld.Assign(World);
    InitializeMinimap;
  end;

end;

procedure TLemmingGame.ApplyMinerMask(L: TLemming; MaskFrame, X, Y: Integer; Redo: Integer = 0);
// x,y is topleft
var
  Bmp: TBitmap32;
  S, D: TRect;
//  C: TColor32;
  //iX, iY,
  {aX, aY,} X1, Y1: Integer;
begin
  Assert((MaskFrame >=0) and (MaskFrame <= 1), 'miner mask error');

  if not L.LemRTL then
    Bmp := MineMasks
  else
    Bmp := MineMasksRTL;

  S := CalcFrameRect(Bmp, 2, MaskFrame);
//  D := S;
//  ZeroTopLeftRect(D);
//  RectMove(D, X, Y);

  D.Left := X;
  D.Top := Y;
  D.Right := X + RectWidth(S) - 1; // whoops: -1 is important to avoid stretching
  D.Bottom := Y + RectHeight(S) - 1; // whoops: -1 is important to avoid stretching

//  deb([rectwidth(d), rectwidth(s)]);
  Assert(CheckRectCopy(D, S), 'miner rect error');

  Bmp.DrawTo(World, D, S);
  if not HyperSpeed then
    Bmp.DrawTo(fTargetBitmap, D, S);

  for X1 := D.Left to D.Right do
  for Y1 := D.Top to D.Bottom do
  if (X1 >= 0) and (X1 < World.Width) and (Y1 >= 0) and (Y1 < World.Height) then
  begin
    if ReadSpecialMap(X1, Y1) = DOM_STEEL then
    begin
      {T := SteelWorld.Pixel[X1, Y1];
      World.SetPixelTS(X1, Y1, T);
      fTargetBitmap.SetPixelTS(X1, Y1, T);}
      World[X1, Y1] := SteelWorld[X1, Y1];
      fTargetBitmap[X1, Y1] := SteelWorld[X1, Y1];
    end;
    if  {(not L.LemIsGhost)
    and} (((ReadSpecialMap(X1, Y1) = DOM_ONEWAYLEFT) and (L.LemDX > 0))
    or ((ReadSpecialMap(X1, Y1) = DOM_ONEWAYRIGHT) and (L.LemDX < 0))) then
    begin
      World[X1, Y1] := SteelWorld[X1, Y1];
      fTargetBitmap[X1, Y1] := SteelWorld[X1, Y1];
    end;
    if (World[X1, Y1] <> SteelWorld[X1, Y1])
    and (ReadSpecialMap(X1, Y1) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN]) then
      WriteSpecialMap(X1, Y1, DOM_NONE);
  end;

  if CheckGimmick(GIM_WRAP_HOR) and (Redo <> 1) then
  begin
    ApplyMinerMask(L, MaskFrame, X - World.Width, Y, 1);
    ApplyMinerMask(L, MaskFrame, X + World.Width, Y, 1);
  end;

  if CheckGimmick(GIM_WRAP_VER) and (Redo = 0) then
  begin
    ApplyMinerMask(L, MaskFrame, X, Y - World.Height, 2);
    ApplyMinerMask(L, MaskFrame, X, Y + World.Height, 2);
  end;

  if redo = 0 then
  begin
    SteelWorld.Assign(World);
    InitializeMinimap;
  end;

end;

procedure TLemmingGame.EraseParticles(L: TLemming);
{-------------------------------------------------------------------------------
  Erase the previously drawn particles of an exploded lemming
-------------------------------------------------------------------------------}
var
  i, X, Y: Integer;
  //DstRect: TRect;
  Drawn: Boolean;
begin

  if not (moShowParticles in fGameParams.MiscOptions) then
    Exit;

  Drawn := False;

  with L do
    if LemParticleFrame <= 50 then
    begin
      if LemParticleFrame = 0 then
      begin
        LemParticleX := LemX;
        LemParticleY := LemY;
      end;
      for i := 0 to 79 do
      begin
        X := fParticles[LemParticleFrame][i].DX;
        Y := fParticles[LemParticleFrame][i].DY;
        if (X <> -128) and (Y <> -128) then
        begin
          X := LemParticleX + X;
          Y := LemParticleY + Y;
          fTargetBitmap.PixelS[X, Y] := World.PixelS[X, Y];
          Drawn := True;
          (*
          DstRect := Rect(X, Y, X + 1, Y + 1);
          if IntersectRect(DstRect, DstRect, World.BoundsRect) then
            World.DrawTo(fTargetBitmap, DstRect, DstRect);
          *)
        end;
      end;
    end;

  fExplodingGraphics := Drawn;


  (*
  with L do
  begin
    for i := 0 to 12 do
    begin
      X := LemX + i * 2;
      Y := LemY - LemParticleFrame - i * 3;
      DstRect := Rect(X, Y, X + 1, Y + 1);
      // important to intersect the rects!
      if IntersectRect(DstRect, DstRect, World.BoundsRect) then
        World.DrawTo(fTargetBitmap, DstRect, DstRect);
    end;
  end;
  *)
end;

procedure TLemmingGame.DrawParticles(L: TLemming);
var
  i, X, Y: Integer;
  //DstRect: TRect;
  Drawn: Boolean;
const
  Colors: array[0..2] of TColor32 = (clYellow32, clRed32, clBlue32);
begin

  if not (moShowParticles in fGameParams.MiscOptions) then
    Exit;
                                    
  Drawn := False;

  with L do
    if LemParticleFrame <= 50 then
    begin
      if LemParticleFrame = 0 then
      begin
        LemParticleX := LemX;
        LemParticleY := LemY;
      end;
      for i := 0 to 79 do
      begin
        X := fParticles[LemParticleFrame][i].DX;
        Y := fParticles[LemParticleFrame][i].DY;
        if (X <> -128) and (Y <> -128) then
        begin
          X := LemParticleX + X;
          Y := LemParticleY + Y;
          Drawn := True;
          fTargetBitmap.PixelS[X, Y] := fParticleColors[i mod 16]//Colors[i mod 3]
        end;
      end;
    end;

  fExplodingGraphics := Drawn;

  (*
  with L do
  begin
    for i := 0 to 12 do
    begin
      X := LemX + i * 2;
      Y := LemY - LemParticleFrame - i * 3;
      fTargetBitmap.FillRectS(X, Y, X + 1, Y + 1, Colors[i mod 3]{clYellow32});
    end;
  end;
  *)

end;


procedure TLemmingGame.DrawAnimatedObjects;
var
  i: Integer;
  Inf : TInteractiveObjectInfo;

  f, mx, my: Integer;
  //Cnt: Integer;
//  R: TRect;
const
  RESET_FRAME = 17;

  function GetDistanceFactor(LV: Integer; Iter: Integer): Integer;
//  var
//    li: Integer;
  begin
    Result := 0;
    if Iter = 0 then Exit;
    Result := ((LV * Iter * 2) div 17);
    {for li := Iter-1 downto 0 do
      Result := Result - GetDistanceFactor(LV, li);}
  end;
begin



(*  // we have to erase first
  // erase entries
  for i := 0 to Entries.Count - 1 do
  begin
    Inf := Entries.List^[i];
    Renderer.EraseObject(fTargetBitmap, Inf.Obj, World);
  end;
*)
  // erase other objects
  if (not HyperSpeed) then
    for i := 0 to ObjectInfos.Count - 1 do
    begin
      Inf := ObjectInfos.List^[i];
      if (Inf.MetaObj.TriggerEffect <> 13) and (Inf.MetaObj.TriggerEffect <> 16) then Renderer.EraseObject(fTargetBitmap, Inf.Obj, World);
    end;

  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos.List^[i];
    if (Inf.MetaObj.TriggerEffect = 30) and (Inf.Obj.TarLev <> 0) then
    begin
      // moving background objects yay!
      // 0 =  0:-2
      // 1 =  1:-2
      // 2 =  2:-2
      // 3 =  2:-1
      // 4 =  2: 0
      // etc

      mx := 0;
      my := 0;

      if Inf.Obj.Skill in [14, 13, 12, 11, 10] then mx := -2;
      if Inf.Obj.Skill in [15, 9] then mx := -1;
      if Inf.Obj.Skill in [1, 7] then mx := 1;
      if Inf.Obj.Skill in [2, 3, 4, 5, 6] then mx := 2;

      if Inf.Obj.Skill in [14, 15, 0, 1, 2] then my := -2;
      if Inf.Obj.Skill in [13, 3] then my := -1;
      if Inf.Obj.Skill in [11, 5] then my := 1;
      if Inf.Obj.Skill in [10, 9, 8, 7, 6] then my := 2;

      // L value = pixels moved per 17 frames (in directions marked by mx or my of 2)

      if (CurrentIteration mod RESET_FRAME) = 0 then Inf.TotalFactor := 0;

      f := GetDistanceFactor(Inf.Obj.TarLev, (CurrentIteration mod RESET_FRAME)+1) - Inf.TotalFactor;
      Inf.TotalFactor := Inf.TotalFactor + f;

      mx := (mx * f) div 2;
      my := (my * f) div 2;

      Inf.Obj.Left := Inf.Obj.Left + mx;
      Inf.Obj.Top := Inf.Obj.Top + my;
      Inf.Obj.OffsetX := Inf.Obj.OffsetX + mx;
      Inf.Obj.OffsetY := Inf.Obj.OffsetY + my;

      with Inf.Obj do
      begin
        while Left < 0 - Inf.MetaObj.Width do
        begin
          Left := Left + (Level.Info.Width + Inf.MetaObj.Width);
          OffsetX := OffsetX + (Level.Info.Width + Inf.MetaObj.Width);
        end;

        while Left >= Level.Info.Width do
        begin
          Left := Left - (Level.Info.Width + Inf.MetaObj.Width);
          OffsetX := OffsetX - (Level.Info.Width + Inf.MetaObj.Width);
        end;

        while Top < 0 - Inf.MetaObj.Height do
        begin
          Top := Top + (Level.Info.Height + Inf.MetaObj.Height);
          OffsetY := OffsetY + (Level.Info.Height + Inf.MetaObj.Height);
        end;

        while Top >= Level.Info.Height do
        begin
          Top := Top - (Level.Info.Height + Inf.MetaObj.Height);
          OffsetY := OffsetY - (Level.Info.Height + Inf.MetaObj.Height);
        end;
      end;
    end;
  end;

  if HyperSpeed then
    Exit;

(*  // entrances
  // only on terrain
  for i := 0 to Entries.Count - 1 do
  begin
    Inf := Entries.List^[i];
    if odf_OnlyOnTerrain and Inf.Obj.DrawingFlags <> 0 then
      Renderer.DrawObject(fTargetBitmap, Inf.Obj, Inf.CurrentFrame, nil{World});
  end;
*)

  // other objects
  // only on terrain
  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos.List^[i];
    Inf.Obj.DrawAsZombie := Inf.ZombieMode;

    if odf_OnlyOnTerrain and Inf.Obj.DrawingFlags <> 0 then
      if (Inf.MetaObj.TriggerEffect <> 13) and (Inf.MetaObj.TriggerEffect <> 16) then
      Renderer.DrawObject(fTargetBitmap, Inf.Obj, Inf.CurrentFrame, nil{World});
  end;


(*  // entrances
  // rest
  for i := 0 to Entries.Count - 1 do
  begin
    Inf := Entries.List^[i];
    if odf_OnlyOnTerrain and Inf.Obj.DrawingFlags = 0 then
      Renderer.DrawObject(fTargetBitmap, Inf.Obj, Inf.CurrentFrame, nil{World});
  end;
*)
  // other objects
  // rest
  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos.List^[i];
    Inf.Obj.DrawAsZombie := Inf.ZombieMode;
    if odf_OnlyOnTerrain and Inf.Obj.DrawingFlags = 0 then
      if (Inf.MetaObj.TriggerEffect <> 13) and (Inf.MetaObj.TriggerEffect <> 16) then
      Renderer.DrawObject(fTargetBitmap, Inf.Obj, Inf.CurrentFrame, nil{World});
  end;

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
  if HyperSpeed then
    Exit;

  with LemmingList do
    for iLemming := 0 to Count - 1 do
    begin
      CurrentLemming := List^[iLemming];
      with CurrentLemming do
      begin
        if not LemRemoved then
        begin
          DstRect := LemEraseRect;
          InflateRect(DstRect, 2, 2);
          // important to intersect the rects!
          if IntersectRect(TempRect, DstRect, World.BoundsRect) then
            World.DrawTo(fTargetBitmap, TempRect, TempRect);
          if CheckGimmick(GIM_WRAP_HOR) then
          begin
            if DstRect.Left < 0 then
            begin
              DstRect.Left := DstRect.Left + World.Width;
              DstRect.Right := DstRect.Right + World.Width;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end else if DstRect.Right > World.Width then
            begin
              DstRect.Left := DstRect.Left - World.Width;
              DstRect.Right := DstRect.Right - World.Width;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end;
          end;
          if CheckGimmick(GIM_WRAP_VER) then
          begin
            if DstRect.Top < 0 then
            begin
              DstRect.Top := DstRect.Top + World.Height;
              DstRect.Bottom := DstRect.Bottom + World.Height;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end else if DstRect.Bottom > World.Height then
            begin
              DstRect.Top := DstRect.Top - World.Height;
              DstRect.Bottom := DstRect.Bottom - World.Height;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end;

            if CheckGimmick(GIM_WRAP_HOR) then
          begin
            if DstRect.Left < 0 then
            begin
              DstRect.Left := DstRect.Left + World.Width;
              DstRect.Right := DstRect.Right + World.Width;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end else if DstRect.Right > World.Width then
            begin
              DstRect.Left := DstRect.Left - World.Width;
              DstRect.Right := DstRect.Right - World.Width;
              if IntersectRect(TempRect, DstRect, World.BoundsRect) then
                World.DrawTo(fTargetBitmap, TempRect, TempRect);
            end;
          end;

          end;
        end;
        // @particles (erase) if lem is removed
        if LemParticleTimer > 0 then
        begin
          EraseParticles(CurrentLemming);
        end;
      end;
    end;
end;

procedure TLemmingGame.DrawLemmings;
var
  iLemming: Integer;
  CurrentLemming: TLemming;
  SrcRect, DstRect, DigRect: TRect;
  Digit: Integer;
  OldCombine, OldCombineZ: TPixelCombineEvent;
  Xo : Integer;
  TempBmp : TBitmap32;
begin
  if HyperSpeed then
    Exit;

  if Minimap.Width < DOS_MINIMAP_WIDTH then
  begin
    fMinimapBuffer.SetSize(DOS_MINIMAP_WIDTH, Minimap.Height);
    fMinimapBuffer.Clear(Renderer.BackgroundColor);
    Xo := 52-(Minimap.Width div 2);
    Minimap.DrawTo(fMinimapBuffer, Xo, 0);
  end else begin
    Xo := 0;
    fMinimapBuffer.Assign(Minimap);
  end;

  with LemmingList do
    for iLemming := 0 to Count - 1 do
    begin

      CurrentLemming := List^[iLemming];
      with CurrentLemming do
      begin
        if not (LemRemoved or LemTeleporting) then
        begin
          //if LemRTLAdjust then LemX := LemX - 1;
          fCurrentlyDrawnLemming := CurrentLemming;
          SrcRect := GetFrameBounds(CheckGimmick(GIM_NUCLEAR));
          DstRect := GetLocationBounds(CheckGimmick(GIM_NUCLEAR));
          LemEraseRect := DstRect;

          fMinimapBuffer.PixelS[(LemX div 16) + Xo, LemY div 8] :=
            Color32(0, 255{176}, 000);

          OldCombineZ := LAB.OnPixelCombine;

          if LemIsZombie then
            LAB.OnPixelCombine := CombineLemmingPixelsZombie
          else if LemIsGhost then
          begin
            if LemAction in [baBuilding, baPlatforming, baStacking] then
              LAB.OnPixelCombine := CombineBuilderPixelsGhost
            else
              LAB.OnPixelCombine := CombineLemmingPixelsGhost;
          end;

          if not LemHighlightReplay then
          begin
            LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
            if CheckGimmick(GIM_WRAP_HOR) then
            begin
              if (DstRect.Right >= World.Width) then
              begin
                DstRect.Left := DstRect.Left - World.Width;
                DstRect.Right := DstRect.Right - World.Width;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end else if (DstRect.Left < 0) then
              begin
                DstRect.Left := DstRect.Left + World.Width;
                DstRect.Right := DstRect.Right + World.Width;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end;
            end;
            if CheckGimmick(GIM_WRAP_VER) then
            begin
              if (DstRect.Bottom >= World.Height) then
              begin
                DstRect.Top := DstRect.Top - World.Height;
                DstRect.Bottom := DstRect.Bottom - World.Height;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end else if (DstRect.Top < 0) then
              begin
                DstRect.Top := DstRect.Top + World.Height;
                DstRect.Bottom := DstRect.Bottom + World.Height;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end;

              if CheckGimmick(GIM_WRAP_HOR) then
              begin
                if (DstRect.Right >= World.Width) then
                begin
                  DstRect.Left := DstRect.Left - World.Width;
                  DstRect.Right := DstRect.Right - World.Width;
                  LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
                end else if (DstRect.Left < 0) then
                begin
                  DstRect.Left := DstRect.Left + World.Width;
                  DstRect.Right := DstRect.Right + World.Width;
                  LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
                end;
              end;

            end;
          end else begin
            // replay assign job highlight fotoflash effect
            OldCombine := LAB.OnPixelCombine;
            LAB.OnPixelCombine := CombineLemmingHighlight;
            LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
            if CheckGimmick(GIM_WRAP_HOR) then
            begin
              if (DstRect.Right >= World.Width) then
              begin
                DstRect.Left := DstRect.Left - World.Width;
                DstRect.Right := DstRect.Right - World.Width;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end else if (DstRect.Left < 0) then
              begin
                DstRect.Left := DstRect.Left + World.Width;
                DstRect.Right := DstRect.Right + World.Width;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end;
            end;
            if CheckGimmick(GIM_WRAP_VER) then
            begin
              if (DstRect.Bottom >= World.Height) then
              begin
                DstRect.Top := DstRect.Top - World.Height;
                DstRect.Bottom := DstRect.Bottom - World.Height;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end else if (DstRect.Top < 0) then
              begin
                DstRect.Top := DstRect.Top + World.Height;
                DstRect.Bottom := DstRect.Bottom + World.Height;
                LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
              end;

              if CheckGimmick(GIM_WRAP_HOR) then
              begin
                if (DstRect.Right >= World.Width) then
                begin
                  DstRect.Left := DstRect.Left - World.Width;
                  DstRect.Right := DstRect.Right - World.Width;
                  LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
                end else if (DstRect.Left < 0) then
                begin
                  DstRect.Left := DstRect.Left + World.Width;
                  DstRect.Right := DstRect.Right + World.Width;
                  LAB.DrawTo(fTargetBitmap, DstRect, SrcRect);
                end;
              end;

            end;
            LAB.OnPixelCombine := OldCombine;
            LemHighlightReplay := False;
          end;

          if DrawLemmingPixel then
            fTargetBitmap.FillRectS(LemX, LemY, LemX + 1, LemY + 1, clRed32);

          if (LemExplosionTimer > 0) or (CurrentLemming = fHighlightLemming) then
          begin
            SrcRect := Rect(0, 0, 8, 8);
            DigRect := GetCountDownDigitBounds;
            LemEraseRect.Top := DigRect.Top;
            Assert(CheckRectCopy(SrcRect, DigRect), 'digit rect copy');

            case LemExplosionTimer of
              113..128 : Digit := 8;
              97..112 : Digit := 7;
              81..96  : Digit := 6;
              65..80  : Digit := 5;
              49..64  : Digit := 4;
              33..48  : Digit := 3;
              17..32  : Digit := 2;
              00..16  : Digit := 1;
            else Digit := 9;
            end;

            TempBmp := TBitmap32.Create;
            TempBmp.SetSize(8, 8);

            if (CurrentLemming = fHighlightLemming) and (LemExplosionTimer mod 17 < 8) then
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

            TempBmp.DrawTo(fTargetBitmap, DigRect);

            if CheckGimmick(GIM_WRAP_HOR) then
            begin
              if (DigRect.Right >= World.Width) then
              begin
                DigRect.Left := DigRect.Left - World.Width;
                DigRect.Right := DigRect.Right - World.Width;
                TempBmp.DrawTo(fTargetBitmap, DigRect);
              end else if (DigRect.Left < 0) then
              begin
                DigRect.Left := DigRect.Left + World.Width;
                DigRect.Right := DigRect.Right + World.Width;
                TempBmp.DrawTo(fTargetBitmap, DigRect);
              end;
            end;
            if CheckGimmick(GIM_WRAP_VER) then
            begin
              if (DigRect.Bottom >= World.Height) then
              begin
                DigRect.Top := DigRect.Top - World.Height;
                DigRect.Bottom := DigRect.Bottom - World.Height;
                TempBmp.DrawTo(fTargetBitmap, DigRect);
              end else if (DigRect.Top < 0) then
              begin
                DigRect.Top := DigRect.Top + World.Height;
                DigRect.Bottom := DigRect.Bottom + World.Height;
                TempBmp.DrawTo(fTargetBitmap, DigRect);
              end;

              if CheckGimmick(GIM_WRAP_HOR) then
              begin
                if (DigRect.Right >= World.Width) then
                begin
                  DigRect.Left := DigRect.Left - World.Width;
                  DigRect.Right := DigRect.Right - World.Width;
                  TempBmp.DrawTo(fTargetBitmap, DigRect);
                end else if (DigRect.Left < 0) then
                begin
                  DigRect.Left := DigRect.Left + World.Width;
                  DigRect.Right := DigRect.Right + World.Width;
                  TempBmp.DrawTo(fTargetBitmap, DigRect);
                end;
              end;

            end;

            TempBmp.Free;

          end;

          //if LemRTLAdjust then LemX := LemX + 1;

          LAB.OnPixelCombine := OldCombineZ;

        end; // not LemmingRemoved
        // @particles, check explosiondrawing if the lemming is dead
        if LemParticleTimer > 1 then begin
          DrawParticles(CurrentLemming);
        end;
      end; // with CurrentLemming

    end; // for i...

  HitTest;

  if InfoPainter <> nil then
  begin
    InfoPainter.SetInfoLemmingsOut((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsRemoved), CheckLemmingBlink);
    InfoPainter.SetInfoLemmingsAlive((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsOut + LemmingsRemoved), false);
    UpdateLemmingsIn(LemmingsIn, MaxNumLemmings);
    InfoPainter.SetReplayMark(Replaying);
    if (Minutes >= 0) and (Seconds >= 0) then
    begin
      InfoPainter.SetInfoMinutes(Minutes, CheckTimerBlink);
      InfoPainter.SetInfoSeconds(Seconds, CheckTimerBlink);
    end else begin
      if Seconds > 0 then
        InfoPainter.SetInfoMinutes(abs(Minutes + 1), CheckTimerBlink)
      else
        InfoPainter.SetInfoMinutes(abs(Minutes), CheckTimerBlink);
      InfoPainter.SetInfoSeconds((60 - Seconds) mod 60, CheckTimerBlink);
    end;
    //InfoPainter.DrawMinimap(fMinimapBuffer)
  end;

end;

procedure TLemmingGame.LayBrick(L: TLemming; O: Integer = 0);
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  i, x, y: Integer;
  NumPixelsFilled: Integer;
  C: TColor32;
begin
  NumPixelsFilled := 0;

  with L do
  begin
    if (LemDx = 1) then
      x := LemX
    else
      x := LemX - 5;

    i := 12 - L.LemNumberOfBricksLeft;
    if i < 0 then i := 0;
    if i > 11 then i := 11;
    C := BrickPixelColors[i];
    C := C or ALPHA_TERRAIN;
    y := LemY - 1 + o;

    if CheckGimmick(GIM_WRAP_VER) then
    begin
      if y < 0 then y := y + World.Height
      else if y >= World.Height then y := y - World.Height;
    end;

//    C := BrickPixelColor or ALPHA_TERRAIN;


    repeat
      if CheckGimmick(GIM_WRAP_HOR) then
      begin
        if x < 0 then x := x + World.Width
        else if x >= World.Width then x := x - World.Width;
      end;
      if World.PixelS[x, y] and ALPHA_TERRAIN = 0 then
      begin
        World.PixelS[x, y] := C;
        if not fHyperSpeed then fTargetBitmap.PixelS[x, y] := C;
        if CheckGimmick(GIM_INVERTSTEEL) then WriteSpecialMap(x, y, DOM_STEEL);
      end;
      Inc(NumPixelsFilled);
      Inc(X);
    until NumPixelsFilled = 6;
  end;

  SteelWorld.Assign(World);
  InitializeMinimap;

end;

procedure TLemmingGame.LayStackBrick(L: TLemming; O: Integer);
{-------------------------------------------------------------------------------
  bricks are in the lemming area so will automatically be copied to the screen
  during drawlemmings
-------------------------------------------------------------------------------}
var
  i, x, y: Integer;
  NumPixelsFilled: Integer;
  C: TColor32;
begin
  NumPixelsFilled := 0;

  with L do
  begin
    if (LemDx = 1) then
      x := LemX+1
    else
      x := LemX - 3;

    i := 12 - L.LemNumberOfBricksLeft;
    if i < 0 then i := 0;
    if i > 11 then i := 11;
    C := BrickPixelColors[i];
    C := C or ALPHA_TERRAIN;
    if LemStackLow then Inc(o);
    Y := LemY - 9 + o;


    if CheckGimmick(GIM_WRAP_VER) then
    begin
      if y < 0 then y := y + World.Height
      else if y >= World.Height then y := y - World.Height;
    end;

//    C := BrickPixelColor or ALPHA_TERRAIN;



    repeat
      if CheckGimmick(GIM_WRAP_HOR) then
      begin
        if x < 0 then x := x + World.Width
        else if x >= World.Width then x := x - World.Width;
      end;
      if World.PixelS[x, y] and ALPHA_TERRAIN = 0 then
      begin
        World.PixelS[x, y] := C;
        if not fHyperSpeed then fTargetBitmap.PixelS[x, y] := C;
        if CheckGimmick(GIM_INVERTSTEEL) then WriteSpecialMap(x, y, DOM_STEEL);
      end;
      Inc(NumPixelsFilled);
      Inc(X);
    until NumPixelsFilled = 3;
  end;

  SteelWorld.Assign(World);
  InitializeMinimap;

end;


function TLemmingGame.DigOneRow(L: TLemming; Y: Integer): Boolean;
var
  yy, N, X: Integer;
  //mX, mY: Integer;
begin
  Result := FALSE;

  with L do
  begin

    n := 1;
    x := LemX - 4;

    if CheckGimmick(GIM_WRAP_VER) then
    begin
      if Y < 0 then Y := Y + World.Height;
      if Y >= World.Height then Y := Y - World.Height;
    end;

    yy := Y;

    if (yy < 0) then yy := 0;

    while (n <= 9) do
    begin
      if CheckGimmick(GIM_WRAP_HOR) then
      begin
        if x < 0 then x := x + World.Width;
        if x >= World.Width then x := x - World.Width;
      end;
      if (HasPixelAt(x,yy) = TRUE) and (ReadSpecialMap(x, yy) <> DOM_STEEL) then
      begin
        if not CheckGimmick(GIM_UNALTERABLE) then
        begin
          RemovePixelAt(x,yy);
          if ReadSpecialMap(x, yy) in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN] then
            WriteSpecialMap(x, yy, DOM_NONE);
        end;
        if (n > 1) and (n < 9) then
        Result := TRUE;
      end;
      inc(n);
      inc(x);
    end;// while

    SteelWorld.Assign(World);

  end;

  // fake draw mask in minimap
  {mX := L.LemX div 16;
  mY := L.LemY div 8;
  MiniMap.PixelS[mX, mY] := Renderer.BackgroundColor;}

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
var
  Method: TLemmingMethod;
begin
  //Result := False;

  with L do
  begin
    // next frame (except floating and digging which are handled differently)
    if not (LemAction in [baFloating, baDigging]) then
    begin
      if not ((CheckGimmick(GIM_BACKWARDS)) and (LemAction = baWalking)) then
      begin
        if (LemFrame < LemMaxFrame) then
        begin
          LemEndOfAnimation := False;
          Inc(LemFrame);
        end
        else begin
          LemEndOfAnimation := True;
          if LemAnimationType = lat_Loop then
           LemFrame := 0;
        end;
      end else
        if (LemFrame > 0) then
        begin
          LemEndOfAnimation := False;
          Dec(LemFrame);
        end
        else begin
          LemEndOfAnimation := True;
          if LemAnimationType = lat_Loop then
           LemFrame := 7;
        end;
      end;

  end; // with

  Method := LemmingMethods[L.LemAction];
  Result := Method(L);

  with L do
  begin
    if CheckGimmick(GIM_WRAP_HOR) then
    begin
      if LemX < 0 then LemX := LemX + World.Width;
      if LemX >= World.Width then LemX := LemX - World.Width;
    end;
    if CheckGimmick(GIM_WRAP_VER) then
    begin
      if LemY < 0 then
      begin
        LemY := LemY + World.Height;
        LemClimbStartY := LemClimbStartY + World.Height;
      end;
      if LemY >= World.Height then LemY := LemY - World.Height;
    end;
  end;

  if L.LemIsZombie and CheckGimmick(GIM_ZOMBIES) then
    SetZombieField(L);

  //if (L.LemIsGhost and CheckGimmick(GIM_GHOSTS)) then
  //  SetGhostField(L);

end;

function TLemmingGame.HandleWalking(L: TLemming): Boolean;
var
  dy, NewY: Integer;
begin
  Result := False;

  with L do
  begin
    if CheckGimmick(GIM_BACKWARDS) then
      Dec(LemX, LemDx)
      else
      Inc(LemX, LemDx);

    {if (LemX >= LEMMING_MIN_X) and (LemX <= LEMMING_MAX_X) then
    begin}
      if (HasPixelAt_ClipY(LemX, LemY, 0) = TRUE) or (CheckGimmick(GIM_NOGRAVITY))
      or ((HasPixelAt_ClipY(LemX, LemY-1, 0) = TRUE) and CheckGimmick(GIM_CHEAPOMODE)) then
      begin
        // walk, jump, climb, or turn around
        dy := 0;
        NewY := LemY;
        //if CheckGimmick(GIM_CHEAPOMODE) then Dec(NewY);
        while (dy <= 6) and (HasPixelAt_ClipY(LemX, NewY - 1, -dy - 1) = TRUE) do
        begin
          Inc(dy);
          Dec(NewY);
        end;

        if dy > 6 then
        begin
          if (LemIsClimber) then
            begin
            if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
            Transition(L, baClimbing);
            end
          else
          begin
            if CheckGimmick(GIM_NOGRAVITY) then
            begin
              dy := 0;
              while (dy < 4) do
              begin
                Inc(dy);
                if HasPixelAt(LemX, LemY + dy - 1) = FALSE then
                begin
                  LemY := LemY + dy;
                  Result := true;
                  exit;
                end;
              end;
            end;

            TurnAround(L);

            if CheckGimmick(GIM_BACKWARDS) then
              Dec(LemX, LemDx)
              else
              Inc(LemX, LemDx);

            if HasPixelAt(LemX, LemY) = FALSE then
            begin

      if not CheckGimmick(GIM_NOGRAVITY) then
        begin
        dy := 1;
        while dy <= 3 do
        begin
          Inc(LemY);
          if HasPixelAt_ClipY(LemX, LemY, dy) = TRUE then
            Break;
          Inc(Dy);
        end;

        if dy > 3 then
        begin
          // in this case, lemming becomes a faller
          Inc(LemY);
          Transition(L, baFalling);
        end;
        end;

        if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
        begin
          RemoveLemming(L, RM_NEUTRAL);
          Exit;
        end
        else begin
          Result := True;
          Exit;
        end;

            end;
          end;
          Result := True;
          Exit;
        end
        else begin
          if dy >= 3 then
          begin
            if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
            Transition(L, baJumping);
            NewY := LemY - 2;
          end;
          LemY := NewY;
          CheckForLevelTopBoundary(L);
          Result := True;
          Exit;
        end
      end
      else begin // no pixel at feet
        // walk or fall downwards
        if not CheckGimmick(GIM_NOGRAVITY) then
        begin
        dy := 1;
        while dy <= 3 do
        begin
          Inc(LemY);
          if HasPixelAt_ClipY(LemX, LemY, dy) = TRUE then
            Break;
          Inc(Dy);
        end;

        if dy > 3 then
        begin
          // in this case, lemming becomes a faller
          Inc(LemY);
          Transition(L, baFalling);
        end;
        end;

        if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
        begin
          RemoveLemming(L, RM_NEUTRAL);
          Exit;
        end
        else begin
          Result := True;
          Exit;
        end;

      end;

    {end
    else begin
      TurnAround(L);
      if CheckGimmick(GIM_BACKWARDS) then
        Dec(LemX, LemDx)
        else
        Inc(LemX, LemDx);
      Result := True;
      Exit;
    end;}
  end; // with L

end;



function TLemmingGame.HandleSwimming(L: TLemming): Boolean;
var
  dy, NewY: Integer;
  LocalLemObjectBelow: Byte;
begin
  Result := False;

  with L do
  begin
    LocalLemObjectBelow := ReadWaterMap(LemX, LemY);
    if CheckGimmick(GIM_BACKWARDS) then
      Dec(LemX, LemDx)
      else
      Inc(LemX, LemDx);

    if (ReadWaterMap(LemX, LemY-2) = DOM_WATER)
    and (not (HasPixelAt(LemX, LemY-2))) then dec(LemY);

    {if (LemX >= LEMMING_MIN_X) and (LemX <= LEMMING_MAX_X) then
    begin}
      if (LocalLemObjectBelow = DOM_WATER) then
      begin
        // walk, jump, climb, or turn around
        dy := 0;
        NewY := LemY;
        while (dy <= 6) and (HasPixelAt_ClipY(LemX, NewY - 1, -dy - 1) = TRUE) do
        begin
          Inc(dy);
          Dec(NewY);
        end;

        if dy > 6 then
        begin
          if (LemIsClimber) then
          begin
            dy := 0;
            while (dy < 3) do
            begin
              Inc(dy);
              if HasPixelAt(LemX, LemY + dy, true) = FALSE then // special treatment in the swimmer pixel test
              begin
                LemY := LemY + dy;
                Result := ReadWaterMap(LemX, LemY) = DOM_WATER;
                if Result = false then Transition(L, baFalling);
                exit;
              end;
            end;
            if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
            Transition(L, baClimbing);
          end
          else begin
            dy := 0;
            while (dy < 4) do
            begin
              Inc(dy);
              if HasPixelAt(LemX, LemY + dy - 1, true) = FALSE then // special treatment here too
              begin
                LemY := LemY + dy;
                Result := ReadWaterMap(LemX, LemY) = DOM_WATER;
                if Result = false then Transition(L, baFalling);
                exit;
              end;
            end;
            TurnAround(L);
            if CheckGimmick(GIM_BACKWARDS) then
              Dec(LemX, LemDx)
              else
              Inc(LemX, LemDx);
          end;
          Result := True;
          Exit;
        end
        else begin
          if dy >= 3 then
          begin
            if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
            Transition(L, baJumping);
            NewY := LemY - 2;
          end else
            if dy >= 1 then Transition(L, baWalking);
          LemY := NewY;
          CheckForLevelTopBoundary(L);
          Result := True;
          Exit;
        end
      end
      else begin // no water at feet
        // walk or fall downwards
        if not CheckGimmick(GIM_NOGRAVITY) then
        begin
        dy := 1;
        while dy <= 3 do
        begin
          Inc(LemY);
          if HasPixelAt_ClipY(LemX, LemY, dy) = TRUE then
            Break;
          Inc(Dy);
        end;

        if dy > 3 then
        begin
          // in this case, lemming becomes a faller
          Inc(LemY);
          Transition(L, baFalling);
        end
        else
          Transition(L, baWalking);

        end else begin
          Result := True;
          Exit;
        end;

      end;

    {end
    else begin
      {TurnAround(L);
      if CheckGimmick(GIM_BACKWARDS) then
        Dec(LemX, LemDx)
        else
        Inc(LemX, LemDx);
      Result := True;
      Exit;
    end;}
  end; // with L

end;



function TLemmingGame.HandleJumping(L: TLemming): Boolean;
var
  dy: Integer;
  //NewY: Integer;
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
      if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
      Transition(L, baWalking);
    end else if ((LemJumped = 4) and HasPixelAt(LemX, LemY-1) and HasPixelAt(LemX, LemY-2)) or ((LemJumped >= 5) and HasPixelAt(LemX, LemY-1)) then
    begin
      //TurnAround(L);
      Dec(LemX, LemDx);
      Transition(L, baFalling, true);
    end;



    {dy := 0;
    while (dy < 2) and (HasPixelAt_ClipY(LemX, LemY - 1, -dy - 1) = TRUE) do
    begin
      Inc(Dy);
      Dec(LemY);
    end;

    if dy < 2 then
      begin
      if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
      Transition(L, baWalking);
      end;

    dy := 0;
    NewY := LemY;
    while (dy <= 6) and (HasPixelAt_ClipY(LemX, NewY - 1, -dy - 1) = TRUE) do
    begin
      Inc(dy);
      Dec(NewY);
    end;

    if dy = 7 then
    begin
      if not CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
      Transition(L, baFalling);
    end;

    CheckForLevelTopBoundary(L);
    Result := True;}
  end;
end;

function TLemmingGame.HandleDigging(L: TLemming): Boolean;
// returns FALSE if there are no terrain pixels to remove (??? did I write this?)
var
  Y: Integer;
begin
  Result := False;

  with L do
  begin

    if LemIsNewDigger then
    begin
      if not CheckGimmick(GIM_UNALTERABLE) then
      begin
      //DigOneRow(L, LemY - 2);
      DigOneRow(L, LemY - 1);
      end;
      LemIsNewDigger := FALSE;
    end
    else begin
      Inc(lemFrame);
      if (lemFrame >= 16) then
        begin
        lemFrame := lemFrame - 16;
        if CheckGimmick(GIM_LAZY) then
          begin
            if CheckGimmick(GIM_NOGRAVITY) then
              begin
              if not CheckGimmick(GIM_HARDWORK) then Transition(L, baWalking);
              end
              else
              Transition(L, baFalling);
              end;
          end;
      end;

    if LemFrame in [0, 8] then
    begin
      y := lemy;
      Inc(lemY);

      if (lemy > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        { TODO : Probably a small bug here: We should call RemoveLemming! }
        //lemRemoved := TRUE;
        //Result := FALSE;
        RemoveLemming(L, RM_NEUTRAL);
        Exit;
      end;

      if (DigOneRow(L, y) = FALSE) then
        begin
        if CheckGimmick(GIM_NOGRAVITY) then
          begin
          if not CheckGimmick(GIM_HARDWORK) then Transition(L, baWalking);
          end
        else
          Transition(L, baFalling);
        end;
      if (ReadSpecialMap(LemX,lemy) = DOM_STEEL) then
      begin
        CueSoundEffect(SFX_HITS_STEEL);
        Transition(L, baWalking);
      end;

      Result := TRUE;
    end
    else begin
      Result := FALSE
    end;

  end;
end;

function TLemmingGame.HandleClimbing(L: TLemming): Boolean;
var
  FoundClip: Boolean;
begin

  with L do
  begin

    if (LemFrame <= 3) then
    begin
      // check if we approached the top
      //if (HasPixelAt_ClipY(LemX, LemY - 7 - LemFrame, 0) = FALSE) then
      begin
        FoundClip := (HasPixelAt(LemX - LemDx, LemY - 6 - Lemframe))
                  or (HasPixelAt(LemX - LemDx, LemY - 5 - Lemframe) and ((LemClimbed > 0){ or (LemFrame > 0)}));

        if (LemClimbed = 0) and (LemFrame = 0) then
          FoundClip := false;

        if (LemClimbed = 0) and (LemFrame = 3) then
          FoundClip := FoundClip or (HasPixelAt(LemX - LemDx, LemY - 4 - LemFrame));

        if (LemClimbed > 0) and (LemFrame = 0) then
          FoundClip := FoundClip and HasPixelAt(LemX - LemDx, LemY - 7);



        if FoundClip then
        begin
          LemY := LemY - LemFrame + 2;
          if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
          if not CheckGimmick(GIM_NOGRAVITY) then
          begin
            LemY := LemY + 1;
            Transition(L, baFalling, TRUE)
          end else
            Transition(L, baWalking, TRUE);

          if CheckGimmick(GIM_BACKWARDS) then
            Dec(LemX, LemDx)
          else
            Inc(LemX, LemDx);
          Result := True;
          Exit;
        end else if (HasPixelAt_ClipY(LemX, LemY - 7 - LemFrame, 0) = FALSE) then
        begin
          LemY := LemY - LemFrame + 2;
          LemClimbed := 0;
          Transition(L, baHoisting);
        end;

      end;
      Result := True;
      Exit;
    end
    else begin
      Dec(LemY);
      Inc(LemClimbed);
      // check for overhang or level top boundary
      FoundClip := HasPixelAt_ClipY(LemX - LemDx, LemY - 7, -8);

      if LemFrame = 7 then
        FoundClip := FoundClip and HasPixelAt(LemX, LemY - 7);

      FoundClip := FoundClip
        or ((LemClimbed = 1) and HasPixelAt_ClipY(LemX - LemDx, LemY - 6, -8))
        or ((ReadObjectMapType(LemX, LemY) = DOM_FORCELEFT) and (LemDx > 0)) or ((ReadObjectMapType(LemX, LemY) = DOM_FORCERIGHT) and (LemDx < 0))
        or ((ReadBlockerMap(LemX, LemY) = DOM_FORCELEFT) and (LemDx > 0)) or ((ReadBlockerMap(LemX, LemY) = DOM_FORCERIGHT) and (LemDx < 0))
        or ((CheckGimmick(GIM_EXHAUSTION)) and (LemClimbed >= fFallLimit));

      if FoundClip then
      begin
        if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
        if not CheckGimmick(GIM_NOGRAVITY) then
          begin
          LemY := LemY + 1;
          Transition(L, baFalling, TRUE);
          end
        else
          Transition(L, baWalking, TRUE);
        if CheckGimmick(GIM_BACKWARDS) then
          Dec(LemX, LemDx)
          else
          Inc(LemX, LemDx);
      end;
      Result := True;
      Exit;
    end;

  end;
end;

function TLemmingGame.HandleDrowning(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    // here the use of HasPixelAt rather than HasPixelAt_ClipY
    // is correct

    if LemEndOfAnimation then RemoveLemming(L, RM_KILL);
    //else if HasPixelAt(LemX + 8 * LemDx, LemY) = FALSE then
      //Inc(LemX, LemDx);
  end;
end;

function TLemmingGame.HandleFixing(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    Dec(LemMechanicFrames);
    if LemMechanicFrames <= 0 then
      Transition(L, baWalking)
      else
      if LemFrame mod 8 = 0 then CueSoundEffect(SFX_FIXING);
  end;
end;

function TLemmingGame.HandleHoisting(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if LemFrame <= 4 then
    begin
      Dec(LemY, 2);
      CheckForLevelTopBoundary(L);
      Result := True;
      Exit;
    end
    else if (LemEndOfAnimation) then // LemFrame = 7
    begin
      if CheckGimmick(GIM_BACKWARDS) then TurnAround(L);
      Transition(L, baWalking);
      CheckForLevelTopBoundary(L);
      Result := True;
      Exit;
    end
//    else
  //    Result := False;
  end;
end;

function TLemmingGame.LemCanPlatform(L: TLemming): Boolean;
var
  x, x2: Integer;
  c2: Boolean;
begin
  with L do
  begin
    x := LemX;
    if LemDX < 0 then Dec(x, 5);
    Result := false;
    c2 := true;
    for x2 := x to x+5 do
      if not HasPixelAt(x2, LemY) then
      begin
        if x2 < 3 then c2 := false;
        Result := true;
      end;
    if LemDX < 0 then Inc(x, 2);
    if c2 and Result then
      for x2 := x+1 to x+2 do
        if HasPixelAt(x2, LemY-1) {and HasPixelAt(x2, LemY-2)} then
          Result := false;
  end;
end;


function TLemmingGame.HandlePlatforming(L: TLemming): Boolean;
//var
//  tcheck : Integer;
begin
  Result := False;

  with L do
  begin
    // sound
    if (LemFrame = 10) and (LemNumberOfBricksLeft <= 3) then
      CueSoundEffect(SFX_BUILDER_WARNING);

    // lay brick
    if (LemFrame = 9)
    {or ( (LemFrame = 10) and (LemNumberOfBricksLeft = 9) )} then
    begin
      LemCouldPlatform := LemCanPlatform(L);
      if not CheckGimmick(GIM_UNALTERABLE) then
      LayBrick(L, 1);
      //Result := False;
      if CheckGimmick(GIM_HARDWORK) then
        LemNumberOfBricksLeft := 11;
      if (CheckGimmick(GIM_LAZY)) and (LemNumberOfBricksLeft > 4) then
        LemNumberOfBricksLeft := 4;
      Exit;
    end
    else if (LemFrame = 15) and not (LemCouldPlatform) then
    begin
      Transition(L, baWalking, TRUE);
      if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
      if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
          Inc(LemX, LemDx);
      CheckForLevelTopBoundary(L);
      Result := True;
      Exit;
    end
    else if (LemFrame = 0) or (LemFrame = 15) then
    begin

      Inc(LemX, LemDx);
      if {(LemX <= LEMMING_MIN_X) or (LemX > LEMMING_MAX_X)
      or} (((HasPixelAt_ClipY(LemX+LemDx, LemY - 1, -1) = TRUE)
      or (HasPixelAt_ClipY(LemX+LemDx, LemY - 2, -1) = TRUE))
      and ((LemNumberOfBricksLeft > 1) or (LemFrame = 15)))
      {or (not LemCanPlatform(L))} then
      begin
        //TurnAround(L);
        Transition(L, baWalking, TRUE);  // turn around as well
        //Inc(LemX, LemDx);
        if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
        if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
          Inc(LemX, LemDx);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      if LemFrame = 0 then
      begin

      Inc(LemX, LemDx);
      if {(LemX <= LEMMING_MIN_X) or (LemX > LEMMING_MAX_X)
      or} (((HasPixelAt_ClipY(LemX+LemDx, LemY - 1, -1) = TRUE)
      or (HasPixelAt_ClipY(LemX+LemDx, LemY - 2, -1) = TRUE))) then
      begin
        if (LemNumberOfBricksLeft > 1) then
        begin
          Transition(L, baWalking, TRUE);  // turn around as well
          if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
          if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
            Inc(LemX, LemDx);
          CheckForLevelTopBoundary(L);
          Result := True;
          Exit;
        end else if HasPixelAt_ClipY(LemX, LemY - 1, -1) then
          Dec(LemX, LemDx);
      end;

      Dec(LemNumberOfBricksLeft);
      if (LemNumberOfBricksLeft = 0) then
      begin
        Transition(L, baShrugging);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;
      end;

      Result := True;
      Exit;
    end
    else begin
      Result := True;
      Exit;
    end;

  end; // with L
end;



function TLemmingGame.HandleBuilding(L: TLemming): Boolean;
//var
//  tcheck : Integer;
begin
  Result := False;

  with L do
  begin
    // sound
    if (LemFrame = 10) and (LemNumberOfBricksLeft <= 3) then
      CueSoundEffect(SFX_BUILDER_WARNING);

    // lay brick
    if (LemFrame = 9)
    {or ( (LemFrame = 10) and (LemNumberOfBricksLeft = 9) )} then
    begin
      if not CheckGimmick(GIM_UNALTERABLE) then
      LayBrick(L);
      //Result := False;
      if CheckGimmick(GIM_HARDWORK) then
        LemNumberOfBricksLeft := 11;
      if (CheckGimmick(GIM_LAZY)) and (LemNumberOfBricksLeft > 4) then
        LemNumberOfBricksLeft := 4;
      Exit;
    end
    else if (LemFrame = 0) then
    begin

      Dec(LemY);
      {if not HasPixelAt_ClipY(LemX + LemDx, LemY - 1, -1) then} Inc(LemX, LemDx);
      if {(LemX <= LEMMING_MIN_X) or (LemX > LEMMING_MAX_X)
      or} (HasPixelAt_ClipY(LemX, LemY - 1, -1) = TRUE)
      or (HasPixelAt_ClipY(LemX, LemY - 2, -1) = TRUE)
      {or (HasPixelAt_ClipY(LemX, LemY - 3, -1) = TRUE)} 
      {or (HasPixelAt_ClipY(LemX + LemDx, LemY - 1, -1) = TRUE)}
      or ((HasPixelAt_ClipY(LemX + LemDx, LemY - 9, -9) = TRUE) and (LemNumberOfBricksLeft > 1))
      {or ((HasPixelAt_ClipY(LemX + LemDx + LemDx, LemY - 9, -9) = TRUE) and (LemNumberOfBricksLeft > 1))} then
      begin
        //TurnAround(L);
        Transition(L, baWalking, TRUE);  // turn around as well
        //Inc(LemX, LemDx);
        if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
        if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
          Inc(LemX, LemDx);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      Inc(LemX, LemDx);
      if (HasPixelAt_ClipY(LemX, LemY - 1, -1) = TRUE) {or (HasPixelAt_ClipY(LemX + LemDx, LemY - 1, -1) = TRUE)}
      or (HasPixelAt_ClipY(LemX, LemY - 2, -1) = TRUE)
      or (HasPixelAt_ClipY(LemX, LemY - 3, -1) = TRUE)
      or ((HasPixelAt_ClipY(LemX + LemDx, LemY - 3, -1) = TRUE) and (LemNumberOfBricksLeft > 0)) then
      begin
        //TurnAround(L);
        Transition(L, baWalking, TRUE);  // turn around as well
        if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
        if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
          Inc(LemX, LemDx);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      Dec(LemNumberOfBricksLeft);
      if (LemNumberOfBricksLeft = 0) then
      begin
        Transition(L, baShrugging);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      if (HasPixelAt_ClipY(LemX + LemDx, LemY - 9, -9) = TRUE)
      {or (HasPixelAt_ClipY(LemX + LemDx + LemDx, LemY - 9, -9) = TRUE)}
      {or (LemX <= LEMMING_MIN_X)
      or (LemX > LEMMING_MAX_X)} then
      begin
        //TurnAround(L);
        Transition(L, baWalking, TRUE);  // turn around as well
        //Inc(LemX, LemDx);
        if (CheckGimmick(GIM_UNALTERABLE)) then Transition(L, baShrugging);
        if CheckGimmick(GIM_BACKWARDS) and HasPixelAt(LemX, LemY-1) and not HasPixelAt(LemX + LemDx, LemY - 1) then
          Inc(LemX, LemDx);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      {-------------------------------------------------------------------------------
        if builder too high he becomes a walker. will *not* turn around
        although it seems he should, but the CheckForLevelTop fails because
        of a changed FrameTopDy
      -------------------------------------------------------------------------------}
      {if (LemY + FrameTopDy < HEAD_MIN_Y) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        Transition(L, baWalking);
        CheckForLevelTopBoundary(L);
      end;}

      Result := True;
      Exit;
    end
    else begin
      Result := True;
      Exit;
    end;

  end; // with L
end;


function TLemmingGame.HandleStacking(L: TLemming): Boolean;
var
  //tcheck : Integer;
  oy: Integer;
begin
  //Result := False;

  with L do
  begin
    // sound
    if (LemFrame = 0) then
      begin
      if (LemNumberOfBricksLeft <= 3) or CheckGimmick(GIM_LAZY) then CueSoundEffect(SFX_BUILDER_WARNING);
      //LemFrame := 0
      end;

    // lay brick
    if (LemFrame = 7) then
    begin
      if not CheckGimmick(GIM_UNALTERABLE) then
      if CheckGimmick(GIM_LAZY) and (LemNumberOfBricksLeft < 3) then
        LayStackBrick(L, LemNumberOfBricksLeft + 5)
        else
        LayStackBrick(L, LemNumberOfBricksLeft);
      Inc(LemFrame);
      //Result := False;
    end;

    if (LemFrame = 0) then
    begin
      {if CheckGimmick(GIM_HARDWORK) then
        LemNumberOfBricksLeft := 11;}
      if (CheckGimmick(GIM_LAZY)) and (LemNumberOfBricksLeft > 3) then
        LemNumberOfBricksLeft := 3;

      oy := LemY - 10 + LemNumberOfBricksLeft;

      if LemStackLow then Inc(oy);

      if CheckGimmick(GIM_LAZY) and (LemNumberOfBricksLeft < 3) then oy := oy + 5;

      if (HasPixelAt(LemX+LemDx, oy)) then
      begin
        //TurnAround(L);
        Transition(L, baWalking, true);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      Dec(LemNumberOfBricksLeft);
      if (LemNumberOfBricksLeft = 0) then
      begin
        Transition(L, baShrugging);
        CheckForLevelTopBoundary(L);
        Result := True;
        Exit;
      end;

      Result := True;
      Exit;
    end
    else begin
      Result := True;
      Exit;
    end;

  end; // with L
end;



function TLemmingGame.HandleBashing(L: TLemming): Boolean;
var
  n, x, y, dy{, x1, y1}, Index: Integer;
  fs, fa: Boolean;
  FrontObj: Byte;
begin
  Result := False;

  with L do
  begin
    index := lemFrame;
    if index >= 16 then
      Dec(index, 16);

    if (11 <= index) and (index <= 15) then
    begin
      Inc(LemX, LemDx);

      {if (LemX < LEMMING_MIN_X) or (LemX > LEMMING_MAX_X) then
      begin
        // outside leftside or outside rightside?
        //TurnAround(L);
        Transition(L, baWalking, TRUE);  // turn around as well
      end;}

        // check 3 pixels above the new position
        if (HasPixelAt(LemX, LemY)) then
        begin
        dy := 0;
        while (dy <= 3) do
        begin
          if (HasPixelAt(LemX, LemY - dy)) and not (HasPixelAt(LemX, LemY - dy - 1)) then
            begin
            LemY := LemY - dy;
            break;
            end
            else if (dy = 3) and (not CheckGimmick(GIM_UNALTERABLE)) and (HasPixelAt(LemX, LemY - dy)) then
            begin
            if (ReadSpecialMap(LemX, LemY - dy - 1) = DOM_STEEL)
            or ({(not LemIsGhost) and}
            ((ReadSpecialMap(LemX, LemY - dy - 1) = DOM_ONEWAYDOWN)
            or ((ReadSpecialMap(LemX, LemY - dy - 1) = DOM_ONEWAYLEFT) and (lemdx = 1))
            or ((ReadSpecialMap(LemX, LemY - dy - 1) = DOM_ONEWAYRIGHT) and (lemdx = -1)))) then
              Transition(L, baWalking, TRUE)
              else
              Dec(LemX, lemdx);
            exit;
            end;
          Inc(dy);
        end;
        end;
        // check 3 pixels below the new position
        dy := 0;
        if not CheckGimmick(GIM_NOGRAVITY) then
          begin
            while (dy < 3) and (HasPixelAt_ClipY(LemX, LemY, dy) = FALSE) do
            begin
              Inc(dy);
              Inc(LemY);
            end;
          end;

        if dy = 3 then
          begin
          if HasPixelAt_ClipY(LemX, LemY, dy) then
            Transition(L, baWalking)
            else
            Transition(L, baFalling);
          end
        else begin
          // check steel or one way digging
          FrontObj := ReadSpecialMap(LemX + LemDx * 3, LemY - 5);

          //if LemIsGhost and (FrontObj <> DOM_STEEL) then FrontObj := DOM_NONE;

          // NEED TO IMPROVE CODE HERE //
          if (FrontObj = DOM_STEEL) then
            CueSoundEffect(SFX_HITS_STEEL);

          if (FrontObj = DOM_STEEL)
          or (FrontObj = DOM_ONEWAYDOWN)
          or ( (FrontObj = DOM_ONEWAYLEFT) and (LemDx <> -1) )
          or ( (FrontObj = DOM_ONEWAYRIGHT) and (LemDx <> 1) ) then
          begin
            //TurnAround(L);
            Transition(L, baWalking, TRUE);  // turn around as well
          end;

          FrontObj := ReadSpecialMap(LemX + LemDx * 4, LemY - 4);
          if FrontObj <> ReadSpecialMap(LemX + LemDx * 5, LemY - 5) then FrontObj := 0;
          //if LemIsGhost and (FrontObj <> DOM_STEEL) then FrontObj := DOM_NONE;

          // NEED TO IMPROVE CODE HERE //
          if (FrontObj = DOM_STEEL) then
            CueSoundEffect(SFX_HITS_STEEL);

          if (FrontObj = DOM_STEEL)
          or (FrontObj = DOM_ONEWAYDOWN)
          or ( (FrontObj = DOM_ONEWAYLEFT) and (LemDx <> -1) )
          or ( (FrontObj = DOM_ONEWAYRIGHT) and (LemDx <> 1) ) then
          begin
            //TurnAround(L);
            Transition(L, baWalking, TRUE);  // turn around as well
          end;
        end;
        
      Result := True;
      Exit;
    end
    else begin

      if (2 <= index) and (index <= 5) then
      begin
        // frame 2..5 and 18..21 or used for masking
        if not CheckGimmick(GIM_UNALTERABLE) then
        ApplyBashingMask(L, index - 2);

        // special treatment frame 5 (see txt)
        if (LemFrame = 5) or (LemFrame = 21) then
        begin
          n := 0;
          x := LemX + lemdx * 8;
          y := LemY - 6;
          fs := false;
          fa := false;

          if (CheckGimmick(GIM_UNALTERABLE)) then
            begin
              Dec(x, LemDx * 8);
              n := -8;
            end;

          // here the use of HasPixelAt rather than HasPixelAt_ClipY
          // is correct
          while (n < 7)
            and ((HasPixelAt(x,y) = FALSE)
                 or (ReadSpecialMap(x, y) = DOM_STEEL)
                 or ( {(not LemIsGhost)
                 and} (((ReadSpecialMap(x, y) = DOM_ONEWAYLEFT) and (LemDx = 1))
                 or ((ReadSpecialMap(x, y) = DOM_ONEWAYRIGHT) and (LemDx = -1))
                 or (ReadSpecialMap(x, y) = DOM_ONEWAYDOWN))))
            and ((HasPixelAt(x,y+1) = FALSE)
                 or (ReadSpecialMap(x, y+1) = DOM_STEEL)
                 or ( {(not LemIsGhost)
                 and} (((ReadSpecialMap(x, y+1) = DOM_ONEWAYLEFT) and (LemDx = 1))
                 or ((ReadSpecialMap(x, y+1) = DOM_ONEWAYRIGHT) and (LemDx = -1))
                 or (ReadSpecialMap(x, y+1) = DOM_ONEWAYDOWN)))) do
          begin
            if (HasPixelAt(x, y)) or (HasPixelAt(x, y+1)) then fa := true;
            Inc(n);
            Inc(x, LemDx);
          end;

          if ((n = 7) and fa) then


          begin

            n := 0;
            x := LemX + lemdx * 8;
            if (CheckGimmick(GIM_UNALTERABLE)) then
            begin
              Dec(x, LemDx * 8);
              n := -8;
            end;

            fa := false;
            Inc(y, 2);

            while (n < 7)
            and ((HasPixelAt(x,y) = FALSE) or (ReadSpecialMap(x, y) = DOM_STEEL)
                 or ( {(not LemIsGhost)
                 and} (((ReadSpecialMap(x, y) = DOM_ONEWAYLEFT) and (LemDx = 1))
                 or ((ReadSpecialMap(x, y) = DOM_ONEWAYRIGHT) and (LemDx = -1))
                 or (ReadSpecialMap(x, y) = DOM_ONEWAYDOWN)))) do
          begin
            if (ReadSpecialMap(x, y) = DOM_STEEL) or (ReadSpecialMap(x, y+3) = DOM_STEEL) then fs := true;
            if (HasPixelAt(x, y)) or (HasPixelAt(x, y+3)) then fa := true;
            Inc(n);
            Inc(x, LemDx);
          end;


          end;


          if ((n = 7) and (not CheckGimmick(GIM_HARDWORK))) or (CheckGimmick(GIM_LAZY)) then
            begin
            if fs then CueSoundEffect(SFX_HITS_STEEL);
            if HasPixelAt(LemX, LemY) then
              Transition(L, baWalking, fa)
              else
              Transition(L, baFalling, fa);
            end;
        end;
      end;
      //Result := FALSE;

    end;

  end; // with
end;

function TLemmingGame.HandleMining(L: TLemming): Boolean;
var
  BelowObj: Byte;
  //Bug: Boolean;
begin
  Result := False;

  with L do
  begin

    if LemFrame = 1 then
    begin
      if not CheckGimmick(GIM_UNALTERABLE) then
      ApplyMinerMask(L, 0, LemX + lemdx - 8, LemY + 1 - 13);
      Exit;
    end
    else if lemFrame = 2 then
    begin
      if not CheckGimmick(GIM_UNALTERABLE) then
      ApplyMinerMask(L, 1, LemX + lemdx - 8, LemY + 2 - 13);
      Exit;

      //
      Inc(LemY);
      if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        RemoveLemming(L, RM_NEUTRAL);
        Exit;
      end
      else begin
        Result := True;
        Exit;
      end;
      //
    end
    else if LemFrame in [3, 15] then
    begin



      Inc(LemY);

      if (HasPixelAt_ClipY(LemX+LemDx, LemY-2, 0)) and (lemFrame = 3) and (not CheckGimmick(GIM_UNALTERABLE)) and (not CheckGimmick(GIM_NOGRAVITY)) then
        begin
        if ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL then
          CueSoundEffect(SFX_HITS_STEEL);
        if (ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL)
        or  ({(not LemIsGhost)
        and} (((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYLEFT) and (LemDx > 0))
        or ((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYRIGHT) and (LemDx < 0)))) then
        begin
          if HasPixelAt(LemX, LemY) and HasPixelAt(LemX, LemY-1) then Dec(LemY);
          Transition(L, baWalking, TRUE);
          Result := True;
          Exit;
        end;
        end;

      Inc(LemX, LemDx);
      {if (LemX < LEMMING_MIN_X) or (LemX > LEMMING_MAX_X) then
      begin
        Transition(L, baWalking, TRUE); // turn around as well
        Result := True;
        Exit;
      end;}

      if (HasPixelAt_ClipY(LemX, LemY, 0) = FALSE) and (HasPixelAt_ClipY(LemX, LemY + 1, 0) = FALSE) and (not CheckGimmick(GIM_NOGRAVITY)) then
      begin
        Inc(LemY);
        Transition(L, baFalling);
        L.LemFallen := L.LemFallen + 1;
        Result := True;
        Exit;
      end;

      if (HasPixelAt_ClipY(LemX+LemDx, LemY-2, 0)) and (not CheckGimmick(GIM_UNALTERABLE)) then
        begin
        if ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL then
          CueSoundEffect(SFX_HITS_STEEL);
        if (ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL)
        or ({(not LemIsGhost)
        and} (((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYLEFT) and (LemDx > 0))
        or ((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYRIGHT) and (LemDx < 0)))) then
        begin
          if HasPixelAt(LemX, LemY) and HasPixelAt(LemX, LemY-1) then Dec(LemY);
        Transition(L, baWalking, TRUE);
        Result := True;
        Exit;
        end;
        end;

      Inc(LemX, lemdx);
      {if (LemX < LEMMING_MIN_X) or (LemX > LEMMING_MAX_X) then
      begin
        Transition(L, baWalking, TRUE);  // turn around as well
        //TurnAround(L);
        Result := True;
        Exit;
      end;}

      //if (lemFrame = 3) then
      //begin
        //Inc(LemY);
        if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
        begin
          RemoveLemming(L, RM_NEUTRAL);
          Result := False;
          Exit;
        end;
      //end;

      if (HasPixelAt_ClipY(LemX, LemY, 0) = FALSE) then
      begin
        if CheckGimmick(GIM_NOGRAVITY) then
          begin
          if not CheckGimmick(GIM_HARDWORK) then Transition(L, baWalking);
          end
        else
          begin
          Inc(LemY);
          Transition(L, baFalling);
          end;
        Result := True;
        Exit;
      end;

      if (HasPixelAt_ClipY(LemX+LemDx, LemY-2, 0)) and (not CheckGimmick(GIM_UNALTERABLE)) then
        begin
        if ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL then
          CueSoundEffect(SFX_HITS_STEEL);
        if (ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_STEEL)
        or ({(not LemIsGhost)
        and} (((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYLEFT) and (LemDx > 0))
        or ((ReadSpecialMap(LemX+LemDx, LemY-2) = DOM_ONEWAYRIGHT) and (LemDx < 0)))) then
        begin
          if HasPixelAt(LemX, LemY) and HasPixelAt(LemX, LemY-1) then Dec(LemY);
        Transition(L, baWalking, TRUE);
        Result := True;
        Exit;
        end;
        end;



      belowObj := ReadSpecialMap(LemX, LemY);
      if (belowObj = DOM_STEEL) then
      begin
        CueSoundEffect(SFX_HITS_STEEL);
      end;

        if (belowObj = DOM_STEEL)
        or ({(not LemIsGhost)
        and} (( (belowObj = DOM_ONEWAYLEFT) and (LemDx <> -1) )
        or ( (belowObj = DOM_ONEWAYRIGHT) and (LemDx <> 1) ))) then // complete check
          begin
            if HasPixelAt(LemX, LemY) and HasPixelAt(LemX, LemY-1) then Dec(LemY);
          Transition(L, baWalking, TRUE);  // turn around as well
          end;

      if CheckGimmick(GIM_LAZY) then
        begin
        Transition(L, baWalking);
        Result := True;
        Exit;
        end;

      Result := True;
      Exit;
    end

    else if (lemFrame = 0) then
    begin
      //Inc(LemY);
      if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        RemoveLemming(L, RM_NEUTRAL);
        Exit;
      end
      else begin
        Result := True;
        Exit;
      end;
    end
    else
      Result := False

  end; // with
end;

function TLemmingGame.HandleFalling(L: TLemming): Boolean;
var
  dy: Integer;
begin
  Result := False;

  if CheckGimmick(GIM_NOGRAVITY) then
    begin
          Transition(L, baWalking);
          Result := True;
          Exit;
    end;

  with L do
  begin

    if (LemTrueFallen > 16) and LemIsFloater and ((not CheckGimmick(GIM_EXHAUSTION)) or (LemFloated = 0)) then
    begin
      Transition(L, baFloating);
      Result := True;
      Exit;
    end
    else if (LemTrueFallen > 6) and LemIsGlider and ((not CheckGimmick(GIM_EXHAUSTION)) or (LemFloated = 0)) then
    begin
      Transition(L, baGliding);
      Result := True;
      Exit;
    end
    else begin
      dy := 0;
      if LemObjectBelow = DOM_UPDRAFT then
      begin
        dy := 1;
        //Dec(LemFallen, 2);
        //if LemFallen < 0 then LemFallen := 0;
      end;
      while (dy < 3) and (HasPixelAt_ClipY(LemX,LemY,dy) = FALSE) do
      begin
        Inc(Dy);
        Inc(LemY);
        if (LemObjectBelow = DOM_UPDRAFT) then
          LemFallen := 0
        else
          Inc(LemFallen);
        Inc(LemTrueFallen);
        if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
        begin
          RemoveLemming(L, RM_NEUTRAL); //LemRemoved := TRUE;
          //Result := False;
          Exit;
        end;
      end;// while

      if (dy = 3) then
      begin
        //Inc(LemFallen, 3);
        Result := True;
        Exit;
      end
      else begin
        if (((LemFallen > fFallLimit) and not CheckGimmick(GIM_INVERTFALL)) or ((LemFallen <= fFallLimit) and CheckGimmick(GIM_INVERTFALL)))
         and not CheckGimmick(GIM_INVINCIBLE)
         and not ((LemObjectBelow = DOM_UPDRAFT) or (LemObjectBelow = DOM_NOSPLAT) or ((ReadWaterMap(LemX, LemY) = DOM_WATER) and not LemIsGhost)) then
        begin
          Transition(L, baSplatting);
          { ccexplore:
          However, the "return true" after call lemming.SetToSplattering()
          is actually correct.  It is in fact the bug in DOS Lemmings that
          I believe enables the "direct drop to exit":
          by returning TRUE, it gives a chance for lemming.CheckForInteractiveObjects()
          to be called immediately afterwards, which ultimately results in the
          lemming's action turning from SPLATTERING to EXITING.
          }
          Result := True;
          Exit;
        end
        else begin
          LemFloated := 0;
          if LemObjectBelow = DOM_SPLAT then
            Transition(L, baSplatting)
          else
            Transition(L, baWalking);
          Result := True;
          Exit;
        end;
      end;
    end

  end; // with

end;

function TLemmingGame.HandleFloating(L: TLemming): Boolean;
var
  dy, minY: Integer;
begin
  with L do
  begin

  if CheckGimmick(GIM_NOGRAVITY) then
    begin
          Transition(L, baWalking);
          Result := True;
          Exit;
    end;

    LemFrame := FloatParametersTable[LemFloatParametersTableIndex].AnimationFrameIndex;
    dy := FloatParametersTable[LemFloatParametersTableIndex].dy;

    if LemObjectBelow = DOM_UPDRAFT then Dec(dy);

    Inc(LemFloatParametersTableIndex);
    if LemFloatParametersTableIndex >= 16 then
      LemFloatParametersTableIndex := 8;

    if (dy <= 0) then
      begin
      Inc(LemY, dy);
      Inc(LemFloated);
      end
    else begin
      minY := 0;
      while (dy > 0) do
      begin
        if (HasPixelAt_ClipY(LemX, LemY, minY) = TRUE) then
        begin
          LemFloated := 0;
          Transition(L, baWalking);
          Result := True;
          Exit;
        end else if ((CheckGimmick(GIM_EXHAUSTION)) and (LemFloated >= 45)) then
          begin
          //Result := True;
          Transition(L, baFalling);
          LemFloated := 1;
          LemFallen := trunc(fFallLimit / 3);
          end
        else begin
          Inc(LemY);
          Dec(dy);
          Inc(minY);
          Inc(LemFloated, 2);
        end;
      end; // while
    end;

    if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
    begin
      RemoveLemming(L, RM_NEUTRAL);
      Result := False;
      Exit;
    end
    else
      Result := True;

  end; // with
end;




function TLemmingGame.HandleGliding(L: TLemming): Boolean;
var
  dy, minY: Integer;
begin
  Result := false;
  with L do
  begin

  if CheckGimmick(GIM_NOGRAVITY) then
    begin
          Transition(L, baWalking);
          Result := True;
          Exit;
    end;

    LemFrame := FloatParametersTable[LemFloatParametersTableIndex].AnimationFrameIndex;
    dy := FloatParametersTable[LemFloatParametersTableIndex].dy;

    if (LemFloatParametersTableIndex >= 8) and (dy > 1) then Dec(dy);

    if LemObjectBelow = DOM_UPDRAFT then
    begin
      Dec(dy);
      if (LemFloatParametersTableIndex >= 8)
      and (LemFloatParametersTableIndex mod 2 = 0)
      and not (HasPixelAt(LemX+LemDx, LemY+dy-1)) then Dec(dy);
    end;

    Inc(LemFloatParametersTableIndex);
    if LemFloatParametersTableIndex >= 16 then
      LemFloatParametersTableIndex := 8;

    Inc(LemX, LemDx);

    if (dy < 0) then
      begin
      Inc(LemY, dy);
      Inc(LemFloated);
      CheckForLevelTopBoundary(L);
      end
    else begin

      if HasPixelAt(LemX, LemY) and HasPixelAt(LemX, LemY-1) then
        dy := 0;

      minY := 0;
      while (dy > 0) do
      begin
        if (HasPixelAt_ClipY(LemX, LemY, minY))
        and not (HasPixelAt_ClipY(LemX, LemY-1, minY)) then
        begin
          LemFloated := 0;
          Transition(L, baWalking);
          Result := True;
          Exit;
        end else if ((CheckGimmick(GIM_EXHAUSTION)) and (LemFloated >= 45)) then
          begin
          Result := True;
          Transition(L, baFalling);
          LemFloated := 1;
          LemFallen := trunc(fFallLimit / 3);
          end
        else begin
          Inc(LemY);
          Dec(dy);
          Inc(minY);
          Inc(LemFloated);
        end;
      end; // while
    end;

    if (HasPixelAt(LemX, LemY))
    and (HasPixelAt(LemX, LemY - 1)) then
    begin
      dy := 1;
      while dy < 6 do
        if not HasPixelAt(LemX{ + LemDx}, LemY - dy) then
        begin
          Dec(LemY, (dy-1));
          LemFloated := 0;
          Transition(L, baWalking);
          Result := true;
          Exit;
        end else
          Inc(dy);
      dy := 1;
      while dy < 4 do
        if not HasPixelAt(LemX, LemY + dy) then
        begin
          Inc(LemY, dy);
          Result := true;
          Exit;
        end else
          Inc(dy);
      Dec(LemX, LemDx);
      TurnAround(L);

      dy := 1;
      while dy < 4 do
        if HasPixelAt(LemX + LemDx, LemY + dy) then
          Inc(dy)
          else
          Exit;

      if HasPixelAt(LemX, LemY) then
      begin
          LemFloated := 0;
          Transition(L, baWalking);
          //Result := true;
      end else
        Inc(LemY);
    end;

    //end;

    if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
    begin
      RemoveLemming(L, RM_NEUTRAL);
      Result := False;
      Exit;
    end
    else
      Result := True;

  end; // with
end;





function TLemmingGame.HandleSplatting(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleExiting(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then RemoveLemming(L, RM_SAVE);
  end;
end;

function TLemmingGame.HandleVaporizing(L: TLemming): Boolean;
begin
  Result := False;
  if L.LemEndOfAnimation then RemoveLemming(L, RM_KILL);
end;

function TLemmingGame.HandleBlocking(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if (HasPixelAt_ClipY(LemX, LemY, 0) = FALSE) and (not CheckGimmick(GIM_NOGRAVITY))
    or ((LemIsBlocking > 170) and (CheckGimmick(GIM_EXHAUSTION))) then
    begin
      Transition(L, baWalking);
      LemIsBlocking := 0;
      RestoreMap(L);
    end else
      Inc(LemIsBlocking);
  end;
end;

function TLemmingGame.HandleShrugging(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then
    begin
      Transition(L, baWalking);
      Result := True;
    end
  end;
end;

function TLemmingGame.HandleOhNoing(L: TLemming): Boolean;
var
  dy: Integer;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then
    begin
      Transition(L, baExploding);
      Exit;
    end
    else begin
      dy := 0;

      if not CheckGimmick(GIM_NOGRAVITY) then
      begin
      while (dy < 3) and (HasPixelAt_ClipY(LemX, LemY, dy) = FALSE) do
      begin
        Inc(dy);
        Inc(LemY);
        if LemIsBlocking > 0 then
          begin
          LemIsBlocking := 0;
          RestoreMap(L);
          end;
      end;
      end;

      if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        RemoveLemming(L, RM_NEUTRAL);
        Exit;
      end
      else
        Result := True;
    end;
  end; // with

end;

function TLemmingGame.HandleExploding(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then
    begin
      if LemIsBlocking > 0 then
      begin
        LemIsBlocking := 0;
        RestoreMap(L);
      end;
      //if not (ReadWaterMap(LemX, LemY) in [DOM_WATER]) then
      //begin
      if not CheckGimmick(GIM_UNALTERABLE) then
        ApplyExplosionMask(L);
        //CreateParticles(L);
      //end;
      if not(CheckGimmick(GIM_SURVIVOR) or CheckGimmick(GIM_INVINCIBLE)) then
      begin
      RemoveLemming(L, RM_KILL);
      if not (( (LemIsZombie = false) and (CheckGimmick(GIM_DEATHZOMBIE)))
           or ( (LemIsGhost = false) and (CheckGimmick(GIM_DEATHGHOST)))) then
      begin
        LemExploded := True;
        LemParticleTimer := PARTICLE_FRAMECOUNT;
        LemParticleX := LemX;
        LemParticleY := LemY;
      end;
      if (moShowParticles in fGameParams.MiscOptions) then
        fParticleFinishTimer := PARTICLE_FINISH_FRAMECOUNT;
      end else Transition(L, baWalking);
    end;
  end;
end;


function TLemmingGame.HandleStoneOhNoing(L: TLemming): Boolean;
var
  dy: Integer;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then
    begin
      Transition(L, baStoneFinish);
      Exit;
    end
    else begin
      dy := 0;

      if not CheckGimmick(GIM_NOGRAVITY) then
      begin
      while (dy < 3) and (HasPixelAt_ClipY(LemX, LemY, dy) = FALSE) do
      begin
        Inc(dy);
        Inc(LemY);
        if LemIsBlocking > 0 then
          begin
          LemIsBlocking := 0;
          RestoreMap(L);
          end;
      end;
      end;

      if (LemY > LEMMING_MAX_Y + World.Height) and not CheckGimmick(GIM_WRAP_VER) then
      begin
        RemoveLemming(L, RM_NEUTRAL);
        Exit;
      end
      else
        Result := True;
    end;
  end; // with

end;


function TLemmingGame.HandleStoneFinish(L: TLemming): Boolean;
begin
  Result := False;
  with L do
  begin
    if LemEndOfAnimation then
    begin
      if LemIsBlocking > 0 then
      begin
        LemIsBlocking := 0;
        RestoreMap(L);
      end;

      if not CheckGimmick(GIM_UNALTERABLE) then
        ApplyStoneLemming(L);

      if not CheckGimmick(GIM_INVINCIBLE) then
      begin
        RemoveLemming(L, RM_KILL);
        LemExploded := True;
        LemParticleTimer := PARTICLE_FRAMECOUNT;
        LemParticleX := LemX;
        LemParticleY := LemY;
        if (moShowParticles in fGameParams.MiscOptions) then
          fParticleFinishTimer := PARTICLE_FINISH_FRAMECOUNT;
      end else Transition(L, baWalking);

      LemExploded := True;
      //LemParticleTimer := PARTICLE_FRAMECOUNT;
      //if (moShowParticles in fGameParams.MiscOptions) then
      //  fParticleFinishTimer := PARTICLE_FINISH_FRAMECOUNT;
      //end else Transition(L, baWalking);
    end;
  end;
end;


function TLemmingGame.CheckForLevelTopBoundary(L: TLemming; LocalFrameTopDy: Integer = 0): Boolean;
//var
//  dy: Integer;
begin

  {with L do
  begin
    Result := False;
    if LocalFrameTopDy = 0 then
      dy := FrameTopDy
    else
      dy := LocalFrameTopDy;
    if (LemY + dy < HEAD_MIN_Y)  and not CheckGimmick(GIM_WRAP_VER) then
    begin
      Result := True;
      LemY := HEAD_MIN_Y - 2 - dy;
      if LemAction <> baGliding then TurnAround(L);
      if LemAction = baJumping then
        Transition(L, baWalking);
    end;
  end;}

  Result := false;

end;


procedure TLemmingGame.RemoveLemming(L: TLemming; RemMode: Integer = 0);

begin

  if (CheckGimmick(GIM_ZOMBIES) and CheckGimmick(GIM_DEATHZOMBIE)) and (RemMode = RM_KILL) and not (L.LemIsZombie) and not (L.LemIsGhost) then
  begin
    if L.LemInTrap > 1 then L.LemRemoved := true;
    RemMode := RM_ZOMBIE;
    Transition(L, baWalking);
    if CheckGimmick(GIM_KAROSHI) and not CheckGimmick(GIM_OLDZOMBIES) then
    begin
      Inc(LemmingsIn);
      GameResultRec.gLastRescueIteration := fCurrentIteration;
    end;
  end;

  if L.LemIsZombie and (RemMode = RM_ZOMBIE) then Exit;
  if L.LemIsGhost and (RemMode = RM_GHOST) then Exit;
  if L.LemRemoved and (L.LemInTrap <= 1) then Exit;

  {if ((not L.LemIsZombie) and ((RemMode = RM_ZOMBIE) or (not (CheckGimmick(GIM_KAROSHI) and CheckGimmick(GIM_OLDZOMBIES)))))
  or ((L.LemIsZombie) and ((RemMode <> RM_ZOMBIE) and (CheckGimmick(GIM_KAROSHI) and CheckGimmick(GIM_OLDZOMBIES))))
  then}

  if ((L.LemIsZombie and (RemMode <> RM_ZOMBIE) and (CheckGimmick(GIM_KAROSHI) and CheckGimmick(GIM_OLDZOMBIES)))
  or ((not L.LemIsZombie) and (RemMode = RM_ZOMBIE) and (not (CheckGimmick(GIM_KAROSHI) and CheckGimmick(GIM_OLDZOMBIES))))
  or ((not L.LemIsZombie) and (RemMode <> RM_ZOMBIE))
  or (RemMode = RM_GHOST))
  and (not L.LemIsGhost)
  then
  begin
    Inc(LemmingsRemoved);
    if (fHighlightLemming = L) and not (RemMode = RM_GHOST) then fHighlightLemming := nil;
    Dec(LemmingsOut);
  end;

    if RemMode = RM_ZOMBIE then
      L.LemIsZombie := true
    else if RemMode = RM_GHOST then
      L.LemIsGhost := true
    else
      L.LemRemoved := True;

  case RemMode of
    RM_KILL : begin
                if CheckGimmick(GIM_KAROSHI) and ((not L.LemIsZombie) or CheckGimmick(GIM_OLDZOMBIES)) and (not L.LemIsGhost) then
                begin
                  Inc(LemmingsIn);
                  GameResultRec.gLastRescueIteration := fCurrentIteration;
                end;
                if CheckGimmick(GIM_DEATHGHOST) and CheckGimmick(GIM_GHOSTS) and not L.LemIsGhost and not L.LemIsZombie then
                begin
                  L.LemIsGhost := true;
                  if L.LemInTrap = 0 then L.LemRemoved := false;
                  Transition(L, baWalking);
                end else
                  L.LemInTrap := 0;
              end;
    RM_SAVE : begin
                if not CheckGimmick(GIM_KAROSHI) and ((not L.LemIsZombie) or CheckGimmick(GIM_OLDZOMBIES)) then
                begin
                  Inc(LemmingsIn);
                  GameResultRec.gLastRescueIteration := fCurrentIteration;
                end;
              end;
    RM_NEUTRAL: CueSoundEffect(SFX_FALLOUT);
  end;

  DoTalismanCheck;

  InfoPainter.SetInfoLemmingsOut((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsRemoved), CheckLemmingBlink);
  InfoPainter.SetInfoLemmingsAlive((Level.Info.LemmingsCount + LemmingsCloned - SpawnedDead) - (LemmingsOut + LemmingsRemoved), false);
  InfoPainter.SetReplayMark(Replaying);
  UpdateLemmingsIn(LemmingsIn, MaxNumLemmings);
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
    fTargetBitmap.Assign(World);
    if fPauseOnHyperSpeedExit and not Paused then
      SetSelectedSkill(spbPause);
    InfoPainter.ClearSkills;
    InfoPainter.DrawButtonSelector(fSelectedSkill, true);
  end;

  DrawAnimatedObjects;
  DrawLemmings;

  CheckForReplayAction(false);

  if fReplaying and (fReplayIndex = fRecorder.Count) then
    RegainControl;

  // force update if raw explosion pixels drawn
  if fExplodingGraphics and (not HyperSpeed) then
    fTargetBitmap.Changed;

  if CheckGimmick(GIM_RISING_WATER) then
    ApplyWaterRise;

  CheckForPlaySoundEffect;
end;

procedure TLemmingGame.ApplyWaterRise;
var
  i, x{, y} : integer;
  //O : TInteractiveObject;
  //MO : TMetaObject;
  Inf : TInteractiveObjectInfo;
begin
  for i := 0 to Level.InteractiveObjects.Count - 1 do
  begin
    Inf := ObjectInfos[i];
    //O := Level.InteractiveObjects[i];
    //MO := Graph.MetaObjects[O.Identifier];
    if (Inf.Obj.TarLev = 0) or not (Inf.MetaObj.TriggerEffect in [5, 6]) then Continue;
    if fCurrentIteration mod Inf.Obj.TarLev = 0 then
    begin
      Renderer.DrawObjectBottomLine(World, Inf.Obj, Inf.CurrentFrame);
      Inf.Obj.Top := Inf.Obj.Top - 1;
      Inf.Obj.OffsetY := Inf.Obj.OffsetY - 1;
      for x := Inf.MetaObj.TriggerLeft to (Inf.MetaObj.TriggerLeft + Inf.MetaObj.TriggerWidth - 1) do
        if Inf.MetaObj.TriggerEffect + DOM_OFFSET = DOM_WATER then
          WriteWaterMap(Inf.Obj.Left + x, Inf.Obj.Top + Inf.MetaObj.TriggerTop, DOM_WATER)
          else
          WriteObjectMap(Inf.Obj.Left + x, Inf.Obj.Top + Inf.MetaObj.TriggerTop, i);
    end;
  end;
end;

procedure TLemmingGame.IncrementIteration;
var
  i: Integer;
const
  OID_ENTRY                 = 1;
begin
  Inc(fCurrentIteration);
  Inc(fClockFrame);
  if DelayEndFrames > 0 then Dec(DelayEndFrames);

  if fParticleFinishTimer > 0 then
    Dec(fParticleFinishTimer);

  if fClockFrame = 17 then
  begin
    fClockFrame := 0;
    if not fInfiniteTime then Dec(Seconds);
    if Seconds < 0 then
    begin
      Dec(Minutes);
      Seconds := 59;
    end;
  end
  else if fClockFrame = 1 then
    if InfoPainter <> nil then
    begin
      if (Minutes >= 0) and (Seconds >= 0) then
    begin
      InfoPainter.SetInfoMinutes(Minutes, CheckTimerBlink);
      InfoPainter.SetInfoSeconds(Seconds, CheckTimerBlink);
    end else begin
      if Seconds > 0 then
        InfoPainter.SetInfoMinutes(abs(Minutes + 1), CheckTimerBlink)
      else
        InfoPainter.SetInfoMinutes(abs(Minutes), CheckTimerBlink);
      InfoPainter.SetInfoSeconds((60 - Seconds) mod 60, CheckTimerBlink);
    end;
    end;

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
          if ObjectInfos[i].MetaObj.TriggerEffect = 23 then
          begin
            ObjectInfos[i].Triggered := True;
            ObjectInfos[i].CurrentFrame := 1;
            EntriesOpened := True;
          end;
        if EntriesOpened then CueSoundEffect(SFX_ENTRANCE)
        else if fStartupMusicAfterEntry then begin
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

procedure TLemmingGame.DrawStatics;
begin
  if InfoPainter = nil then
    Exit;


  with InfoPainter, Level.Info do
  begin

    DrawSkillCount(spbSlower, ReleaseRate);
    DrawSkillCount(spbFaster, ReleaseRate);
    DrawSkillCount(spbClimber, ClimberCount);
    DrawSkillCount(spbUmbrella, FloaterCount);
    DrawSkillCount(spbExplode, BomberCount);
    DrawSkillCount(spbBlocker, BlockerCount);
    DrawSkillCount(spbBuilder, BuilderCount);
    DrawSkillCount(spbBasher, BasherCount);
    DrawSkillCount(spbMiner, MinerCount);
    DrawSkillCount(spbDigger, DiggerCount);
    DrawSkillCount(spbWalker, WalkerCount);
    DrawSkillCount(spbSwimmer, SwimmerCount);
    DrawSkillCount(spbGlider, GliderCount);
    DrawSkillCount(spbMechanic, MechanicCount);
    DrawSkillCount(spbStoner, StonerCount);
    DrawSkillCount(spbPlatformer, PlatformerCount);
    DrawSkillCount(spbStacker, StackerCount);
    DrawSkillCount(spbCloner, ClonerCount);
  end;
end;

procedure TLemmingGame.HitTest(Autofail: Boolean = false);
var
  HitCount: Integer;
  Lemming1, Lemming2: TLemming;
  S: string;
  i: integer;
  fAltOverride: Boolean;
begin
  if Autofail then fHitTestAutoFail := true;
  //if fHitTestAutoFail <> 0 then CursorPoint := Point(-50, -50);
  HitCount := PrioritizedHitTest(Lemming1, Lemming2, CursorPoint);
  if (HitCount > 0) and (Lemming1 <> nil) and not fHitTestAutofail then
  begin
    S := LemmingActionStrings[Lemming1.lemAction];
    // get highlight text

    if (Lemming1.LemIsZombie or Lemming1.LemIsGhost)
    and (Lemming1.LemIsClimber or Lemming1.LemIsFloater or Lemming1.LemIsGlider
         or Lemming1.LemIsSwimmer or Lemming1.LemIsMechanic)
      then fAltOverride := true
    else
      fAltOverride := false;

    if fAltButtonHeldDown or fAltOverride then
    begin
      S := '-----';
      if Lemming1.LemIsClimber then S[1] := 'C';
      if Lemming1.LemIsSwimmer then S[2] := 'S';
      if Lemming1.LemIsFloater then S[3] := 'F';
      if Lemming1.LemIsGlider then S[3] := 'G';
      if Lemming1.LemIsMechanic then S[4] := 'D';
      if Lemming1.LemIsZombie then S[5] := 'Z';
      if Lemming1.LemIsGhost then S[5] := 'G';
    end else begin
      i := 0;
      if Lemming1.LemIsClimber then inc(i);
      if Lemming1.LemIsSwimmer then inc(i);
      if Lemming1.LemIsFloater then inc(i);
      if Lemming1.LemIsGlider then inc(i);
      if Lemming1.LemIsMechanic then inc(i);

      case i of
        5: S := SQuadathlete;
        4: S := SQuadathlete;
        3: S := STriathlete;
        2: S := SAthlete;
        1: begin
             if Lemming1.LemIsClimber then S := SClimber;
             if Lemming1.LemIsSwimmer then S := SSwimmer;
             if Lemming1.LemIsFloater then S := SFloater;
             if Lemming1.LemIsGlider  then S := SGlider;
             if Lemming1.LemIsMechanic then S := SMechanic;
           end;
        else S := LemmingActionStrings[Lemming1.LemAction];
      end;

      if Lemming1.LemIsZombie then S := SZombie;
      if Lemming1.LemIsGhost then S := SGhost;
    end;

    {if i > 1 then
    begin
      S := S + ' ';
      //S := SAthlete;

      if Lemming1.LemIsClimber then
        S := S + 'C'
      else
        S := S + '-';

      if Lemming1.LemIsSwimmer then
        S := S + 'S'
      else
        S := S + '-';

      if Lemming1.LemIsFloater then
        S := S + 'F'
      else if Lemming1.LemIsGlider then
        S := S + 'G'
      else
        S := S + '-';

      if Lemming1.LemIsMechanic then
        S := S + 'D'
      else
        S := S + '-';

    end;}

    InfoPainter.SetInfoCursorLemming(S, HitCount);
    DrawDebugString(Lemming1);
    fCurrentCursor := 2;
  end
  else begin
    {if Replaying then
      InfoPainter.SetInfoCursorLemming('-REPLAY-', 0)
    else}
      InfoPainter.SetInfoCursorLemming('', 0);
    fCurrentCursor := 1;
  end;
  //if fHitTestAutoFail = 2 then fHitTestAutoFail := 0;
  //fHitTestAutofail := Autofail;
end;

function TLemmingGame.ProcessSkillAssignment: Boolean;
var
  Sel: TBasicLemmingAction;
  Lemming1, Lemming2: TLemming;
begin
  Result := False;
  if fAssignedSkillThisFrame then Exit;
  // convert buttontype to skilltype
  Sel := SkillPanelButtonToAction[fSelectedSkill];
  Assert(Sel <> baNone);
  if PrioritizedHitTest(Lemming1, Lemming2, CursorPoint) > 0 then
  begin
    //if Lemming1 = nil then
    //  Lemming1 := LastNPLemming;   // right-click bug emulation

    if Lemming1 <> nil then
    begin
      fCheckWhichLemmingOnly := False;
      Result := AssignSkill(Lemming1, Lemming2, Sel);
      if Result then fAssignedSkillThisFrame := true;
    end;
  end;
end;

function TLemmingGame.ProcessHighlightAssignment: Boolean;
var
  //Sel: TBasicLemmingAction;
  Lemming1, Lemming2, OldHighlightLemming: TLemming;
  i: Integer;
begin
  Result := False;
  OldHighlightLemming := fHighlightLemming;
  if PrioritizedHitTest(Lemming1, Lemming2, CursorPoint) > 0 then
    fHighlightLemming := Lemming1
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
        DrawAnimatedObjects;
      end;
      DrawLemmings;  // so the highlight marker shows up
    end;
  end;


end;

procedure TLemmingGame.ReplaySkillAssignment(aReplayItem: TReplayItem);
var
  L{, Lemming1, Lemming2}: TLemming;
  //ReplayMousePos: TPoint;
//  Res: Boolean;
  ass: TBasicLemmingAction;
  //Proceed: Boolean;
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
    assert(assignedskill > 0);
    assert(assignedskill < 19);
    ass := TBasicLemmingAction(assignedskill{ - 1});

//    assert(ass in AssignableSkills);
    if not (ass in AssignableSkills) then
      raise exception.create(i2s(integer(ass)) + ' ' + i2s(currentiteration));

    if ass in AssignableSkills then
    begin
      //Mouse.CursorPos := Point(Screen.Width div 2, Screen.Height div 2);
//      TestMouseOnLemming(L);
      {Res := }

      // for antiques but nice
      if (ActionToSkillPanelButton[ass] <> fSelectedSkill) and not fGameParams.IgnoreReplaySelection then
        SetSelectedSkill(ActionToSkillPanelButton[ass], True);

      {ReplayMousePos.X := CursorX;
      ReplayMousePos.Y := CursorY;

      fSelectDx := fSelectDir;

      if (fSelectDx < -1) or (fSelectDx > 1) then fSelectDx := 0;}

      {if PrioritizedHitTest(Lemming1, Lemming2, ReplayMousePos, False) > 0 then
      begin

        if Lemming1 <> nil then
          begin

            Proceed := true;
            if Proceed then
            begin
              fCheckWhichLemmingOnly := True;
              WhichLemming := nil;
              AssignSkill(Lemming1, Lemming2, ass);
              fCheckWhichLemmingOnly := False;
              if (WhichLemming = L) then
                AssignSkill(Lemming1, Lemming2, ass)
              else if (Lemming2 = L) then
                AssignSkill(Lemming2, Lemming2, ass);
              fAssignEnabled := false;
            end;
            
          end;
      end;



      fSelectDx := 0;}

//      AssignSkill(L, nil, ass);
//      if UseReplayPhotoFlashEffect then

      if AssignSkill(L, nil, ass) then fAssignedSkillThisFrame := true;

      if not HyperSpeed then
        L.LemHighlightReplay := True;
{      if fReplayedLemmingIndex = -1 then
        fReplayedLemmingIndex := LemmingIndex; }
//      if
      {if (LemmingX > 0) and (LemmingY > 0) then
      begin
        if (LemmingX <> l.lemx) or (LemmingY <> l.lemy) then
        begin
          infopainter.SetInfoCursorLemming('invalid', 0);
          RegainControl;
//          ShowMessage('invalid replay, replay ended');
        end;}

      //  Assert(LemmingX=l.lemx, 'replay x error' + ','+i2s(lemmingX) + ','+i2s(l.LemX));
        //Assert(LemmingY=l.lemy, 'replay y error' + ','+i2s(LemmingY) + ','+i2s(l.Lemy));
      {end
      else begin
        LemmingX := L.lemX;
        LemmingY := L.LemY;
      end;}
//      Mouse.
//      Assert(Res, 'replay error 1');
//      if xxx<>lemx then deb(['err', xxx,LemX])
    end;

  end;
end;

procedure TLemmingGame.ReplaySkillSelection(aReplayItem: TReplayItem);
var
  bs: TSkillPanelButton;
begin
  if fGameParams.IgnoreReplaySelection then Exit;
  case areplayitem.selectedbutton of
    rsb_walker: bs := spbWalker;
    rsb_climber: bs := spbClimber;
    rsb_swimmer: bs := spbSwimmer;
    rsb_umbrella: bs := spbUmbrella;
    rsb_glider: bs := spbGlider;
    rsb_mechanic: bs := spbMechanic;
    rsb_explode: bs := spbExplode;
    rsb_stoner: bs := spbStoner;
    rsb_stopper: bs := spbBlocker;
    rsb_platformer: bs := spbPlatformer;
    rsb_builder: bs := spbBuilder;
    rsb_stacker: bs := spbStacker;
    rsb_basher: bs := spbBasher;
    rsb_miner: bs := spbMiner;
    rsb_digger: bs := spbDigger;
    rsb_cloner: bs := spbCloner;
    else bs := spbNone;
    end;
  {bs := tSkillPanelButton(areplayitem.selectedbutton); // convert
    if bs in [
    spbClimber,
    spbUmbrella,
    spbExplode,
    spbBlocker,
    spbBuilder,
    spbBasher,
    spbMiner,
    spbDigger,
    spbWalker,
    spbSwimmer,
    spbGlider,
    spbStoner,
    spbPlatformer,
    spbStacker] then}
  setselectedskill(bs, true);
//  case aReplayItem
end;

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
    if AssignSkill(fHighlightLemming, fHighlightLemming, SkillPanelButtonToAction[Value]) then
      if Paused then UpdateLemmings;
  end;
  case Value of
    spbFaster:
      begin
        if CheckGimmick(GIM_RRFLUC) and MakeActive then
        begin
          CueSoundEffect(SFX_OHNO);
          Exit;
        end;
        {if fSpeedingUpReleaseRate <> MakeActive then
        case MakeActive of
          False: RecordReleaseRate(raf_StopChangingRR);
          True: case RightClick of
                  False: RecordReleaseRate(raf_StartIncreaseRR);
                  //True: RecordReleaseRate(raf_RR99);
                  end;
        end;}
        fSpeedingUpReleaseRate := MakeActive;
        if MakeActive then
          fSlowingDownReleaseRate := False;
        if RightClick and fSpeedingUpReleaseRate then InstReleaseRate := 1;
      end;
    spbSlower:
      begin
        if CheckGimmick(GIM_RRFLUC) and MakeActive then
        begin
          CueSoundEffect(SFX_OHNO);
          Exit;
        end;
        {if fSlowingDownReleaseRate <> MakeActive then
        case MakeActive of
          False: RecordReleaseRate(raf_StopChangingRR);
          True: case RightClick of
                  False: RecordReleaseRate(raf_StartDecreaseRR);
                  //True: RecordReleaseRate(raf_RRmin);
                  end;
        end;}
        fSlowingDownReleaseRate := MakeActive;
        if MakeActive then
          fSpeedingUpReleaseRate := False;
        if RightClick and fSlowingDownReleaseRate then InstReleaseRate := -1;
      end;
    spbWalker:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := spbWalker;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
        {if RightClick and (fHighlightLemming <> nil) then
          AssignSkill(fHighlightLemming, fHighlightLemming, SkillPanelButtonToAction[fSelectedSkill]);}
      end;
    spbClimber:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := spbClimber;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
        {if RightClick and (fHighlightLemming <> nil) then
          AssignSkill(fHighlightLemming, fHighlightLemming, SkillPanelButtonToAction[fSelectedSkill]);}
      end;
    spbSwimmer:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(Value, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbUmbrella:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbGlider:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbMechanic:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbExplode:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbStoner:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbBlocker:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbPlatformer:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbBuilder:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbStacker:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbBasher:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbMiner:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbDigger:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbCloner:
      begin
        if fSelectedSkill = Value then
          Exit;
        if not CheckSkillInSet(Value) then Exit;
        InfoPainter.DrawButtonSelector(fSelectedSkill, False);
        fSelectedSkill := Value;
        InfoPainter.DrawButtonSelector(fSelectedSkill, True);
        CueSoundEffect(SFX_SKILLBUTTON);
        RecordSkillSelection(Value);
      end;
    spbPause:
      //if not fHyperSpeed then
      begin
        if not CheckGimmick(GIM_FRENZY) then
          begin
          case Paused of
          False:
            begin
              // NOPAUSE GOES HERE //
              Paused := True;
              FastForward := False;
              RecordStartPause;
              //HyperSpeedEnd;
            end;
          True:
            begin
              Paused := False;
              FastForward := False;
              RecordEndPause;
            end;
          end;
          end else CueSoundEffect(SFX_OHNO);
      end;
    spbNuke:
      begin
        if not CheckGimmick(GIM_KAROSHI) then
        begin
        UserSetNuking := True;
        // next line of code is NUKE GLITCH
        // changing MaxNumLemmings also allows IN % to be calculated
        // and displayed in-game using the glitch calculation,
        // just like the actual game
        //MaxNumLemmings := LemmingsReleased;

        ExploderAssignInProgress := True;
        RecordNuke;
        end;
      end;
  end;
end;

procedure TLemmingGame.CheckReleaseLemming;
var
  NewLemming: TLemming;
//  MustCreate: Boolean;
//  Entry: TInteractiveObject;
  ix, EntranceIndex: Integer;
//  L:
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
          LemBorn := CurrentIteration;
          Transition(NewLemming, baFalling);
          LemX := ObjectInfos[ix].Obj.Left;
          LemY := ObjectInfos[ix].Obj.Top;
          if ((ObjectInfos[ix].MetaObj.TriggerTop = -4) or (ObjectInfos[ix].MetaObj.TriggerTop = 0)) and
             (ObjectInfos[ix].MetaObj.TriggerLeft = 0) then
          begin
            LemX := LemX + 24;
            LemY := LemY + 13;
          end else begin
            LemX := LemX + ObjectInfos[ix].MetaObj.TriggerLeft;
            LemY := LemY + ObjectInfos[ix].MetaObj.TriggerTop;
          end;
          LemDX := 1;
          if (ObjectInfos[ix].Obj.DrawingFlags and 8) <> 0 then
            TurnAround(NewLemming);

          // these must be initialized to nothing
          LemObjectInFront := DOM_NONE;
          LemObjectBelow := DOM_NONE;
          LemObjectIDBelow := 0;

          LemUsedSkillCount := 0;
          LemIsClone := false;

          if (ObjectInfos[ix].Obj.TarLev and 1) <> 0 then LemIsClimber := true;
          if (ObjectInfos[ix].Obj.TarLev and 2) <> 0 then LemIsSwimmer := true;
          if (ObjectInfos[ix].Obj.TarLev and 4) <> 0 then LemIsFloater := true
          else if (ObjectInfos[ix].Obj.TarLev and 8) <> 0 then LemIsGlider := true;
          if (ObjectInfos[ix].Obj.TarLev and 16) <> 0 then LemIsMechanic := true;
          if ((ObjectInfos[ix].Obj.TarLev and 64) <> 0) and CheckGimmick(GIM_ZOMBIES) then RemoveLemming(NewLemming, RM_ZOMBIE);
          if ((ObjectInfos[ix].Obj.TarLev and 128) <> 0) and CheckGimmick(GIM_GHOSTS) then RemoveLemming(NewLemming, RM_GHOST);
          if NewLemming.LemIsZombie or NewLemming.LemIsGhost then Dec(SpawnedDead);
          if LemIndex = fHighlightLemmingID then fHighlightLemming := NewLemming;
        end;
        Inc(LemmingsReleased);
        Inc(LemmingsOut);
      end;
    end;
  end;

  //if NextLemmingCountdown < 0 then NextLemmingCountdown := NextLemmingCountdown + CalculateNextLemmingCountdown;

end;

procedure TLemmingGame.CheckUpdateNuking;
var
  CurrentLemming: TLemming;
begin

  if UserSetNuking and ExploderAssignInProgress then
  begin

    // find first following non removed lemming
    while (Index_LemmingToBeNuked <{=} LemmingsReleased + LemmingsCloned)
    and (LemmingList[Index_LemmingToBeNuked].LemRemoved) do
      Inc(Index_LemmingToBeNuked);

    if (Index_LemmingToBeNuked > LemmingsReleased + LemmingsCloned - 1) then // added - 1
      ExploderAssignInProgress := FALSE
    else begin
      CurrentLemming := LemmingList[Index_LemmingToBeNuked];
      with CurrentLemming do
      begin
        if (LemExplosionTimer = 0)
        and not (LemAction in [baSplatting, baExploding])
        and not LemIsZombie then
          LemExplosionTimer := 79;
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
      LemBorn := CurrentIteration;
      Transition(NewLemming, baFalling);
//      Transition(NewLemming, baJumping);
      LemX := CursorPoint.X;
      LemY := CursorPoint.Y;
      LemDX := 1;

      // these must be initialized to nothing
      LemObjectInFront := DOM_NONE;
      LemObjectBelow := DOM_NONE;
      LemObjectIDBelow := 0;
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
{-------------------------------------------------------------------------------
  Save last sound.
-------------------------------------------------------------------------------}
var
  i: Integer;
begin
  if HyperSpeed or not Playing or not (gsoSound in fSoundOpts) then
    Exit;

  if {(fSoundToPlay = SFX_ASSIGN_SKILL) or} (aSoundId < 0) then
    Exit;

  for i := 0 to Length(fSoundToPlay)-1 do
    if fSoundToPlay[i] = aSoundId then Exit;

  SetLength(fSoundToPlay, Length(fSoundToPlay)+1);
  fSoundToPlay[Length(fSoundToPlay) - 1] := aSoundId;

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
begin
  N := CurrReleaseRate + Delta;
  Restrict(N, Level.Info.ReleaseRate, 99);
  if N <> currReleaseRate then
  begin
    currReleaseRate := N;
    LastReleaseRate := N;
    InfoPainter.DrawSkillCount(spbFaster, currReleaseRate);
  end;
end;

procedure TLemmingGame.RecordStartPause;
{-------------------------------------------------------------------------------
  Records the start of a pause session.
  Just in case: when the previous record is raf_Pausing or raf_StartPause
  we do *not* record it.
-------------------------------------------------------------------------------}

// NeoLemmix: We do not record this at all.

{    function PrevOk: Boolean;
    var
      R: TReplayItem;
    begin
      Result := True;
      with fRecorder.List do
      begin
        if Count = 0 then
          Exit;
        R := TReplayItem(List^[Count - 1]);
        Result := R.ActionFlags and (raf_Pausing or raf_StartPause) = 0;
      end;
    end;

var
  R: TReplayItem;}
begin
  {if not fPlaying or fReplaying or not PrevOk then
    Exit;
  R := fRecorder.Add;
  R.Iteration := CurrentIteration;
  R.ActionFlags := raf_StartPause;
  R.ReleaseRate := currReleaseRate;}
end;

procedure TLemmingGame.RecordEndPause;
{-------------------------------------------------------------------------------
  Recording the end of a pause.
  Just in case: this is only allowed if there is a startpause-counterpart.
  if there is a previous record then this previous record has to
  have a flag raf_Pausing or raf_StartPause.
  In all other cases EndPause is *not* recorded.
-------------------------------------------------------------------------------}

// NeoLemmix: We do not record this at all.

{    function PrevOk: Boolean;
    var
      R: TReplayItem;
    begin
      Result := False;
      with fRecorder.List do
      begin
        if Count = 0 then
          Exit;
        R := TReplayItem(List^[Count - 1]);
        Result := R.ActionFlags and (raf_Pausing or raf_StartPause) <> 0;
      end;
    end;

var
  R: TReplayItem;}

begin
  {if not fPlaying or fReplaying or not PrevOk then
    Exit;
  R := fRecorder.Add;
  R.Iteration := CurrentIteration;
  R.ActionFlags := raf_EndPause;
  R.ReleaseRate := currReleaseRate;}
end;

procedure TLemmingGame.RecordNuke;
{-------------------------------------------------------------------------------
  Easy one: Record nuking. Always add new record.
-------------------------------------------------------------------------------}
var
  R: TReplayItem;
begin
  if not fPlaying or fReplaying then
    Exit;
  R := fRecorder.Add;
  R.Iteration := CurrentIteration;
  R.ActionFlags := R.ActionFlags or raf_Nuke;
  // Just in case: nuking is normally not possible when pausing.
  // but it does no harm setting the raf_Pause flag
  //if Paused then
  //  R.ActionFlags := R.ActionFlags or raf_Pausing;
  R.ReleaseRate := currReleaseRate;
end;

procedure TLemmingGame.RecordReleaseRate(aActionFlag: Byte);
{-------------------------------------------------------------------------------
  This is a tricky one. It can be done when pausing and when not pausing.
  Records a releaserate change command so the only valid parameters are:
    o raf_StartIncreaseRR,
    o raf_StartDecreaseRR,
    o raf_StopChangingRR
-------------------------------------------------------------------------------}
{ TODO : This whole "NewRec" thing can be deleted, we do not need the variable }
var
  R: TReplayItem;
  NewRec: Boolean;
  RecIteration: Integer;
begin
  if not fPlaying or fReplaying then
    Exit;

  Assert(aActionFlag in [raf_StartIncreaseRR, raf_StartDecreaseRR, raf_StopChangingRR]);

  if aActionFlag <> raf_StopChangingRR then Exit;

  RecIteration := CurrentIteration;

  NewRec := False;
  if Paused then
  begin
    Assert(Recorder.List.Count > 0);
    // get last record
    R := Recorder.List.List^[Recorder.List.Count - 1];

    // some records are not safe to overwrite
    // we must begin a new one then
    if {(R.ActionFlags and raf_StartPause <> 0) or}
       (R.Iteration <> RecIteration) or
       (R.ActionFlags and raf_SkillAssignment <> 0) then
    begin
      R := Recorder.add;
      NewRec := True;
    end;
  end
  else begin
    // not paused, always create new record
    R := Recorder.Add;
    NewRec := True;
  end;

  R.Iteration := RecIteration;
  R.ReleaseRate := CurrReleaseRate;

  { TODO : Just use the "or" statement }
  if NewRec then
  begin
    R.ActionFlags := aActionFlag;
  end
  else begin
    R.ActionFlags := R.ActionFlags or aActionFlag;
    //if Paused then
    //  R.ActionFlags := R.ActionFlags or raf_Pausing;
  end;

end;

procedure TLemmingGame.RecordSkillAssignment(L: TLemming; aSkill: TBasicLemmingAction);
{-------------------------------------------------------------------------------
  Always add new record.
-------------------------------------------------------------------------------}
var
  R: TReplayItem;
begin
  L.LemUsedSkillCount := L.LemUsedSkillCount + 1;
  if fFreezeRecording then Exit;
  if not fPlaying or fReplaying then
    Exit;

  R := Recorder.Add;

  R.Iteration := CurrentIteration;
  R.ActionFlags := raf_SkillAssignment;

  // this is possible in debugmode but don't know if I keep it that way
  //if Paused then
  //  R.ActionFlags := R.ActionFlags or raf_Pausing;

  R.LemmingIndex := L.LemIndex;
  R.ReleaseRate := CurrReleaseRate;
  R.AssignedSkill := Byte(aSkill){ + 1}; // the byte is "compatible" for now
  R.LemmingX := L.LemX;
  R.LemmingY := L.LemY;
  R.CursorX := CursorPoint.X;
  R.CursorY := CursorPoint.Y;
  R.SelectDir := fSelectDx;
end;

procedure TLemmingGame.RecordSkillSelection(aSkill: TSkillPanelButton);
var
  R: TReplayItem;
  NewRec: Boolean;
begin
//  Assert(aSkill)
  if not fPlaying then Exit;
  if fReplaying then
    Exit;
  assert(askill in [    spbClimber,
    spbUmbrella, spbExplode, spbBlocker, spbBuilder, spbBasher,
    spbMiner, spbDigger, spbWalker, spbSwimmer, spbGlider, spbMechanic,
    spbStoner, spbPlatformer, spbStacker, spbCloner]);
//  if ReplayList.Count = 0 then

  (*NewRec := False;
  if Paused then
  begin
    Assert(Recorder.List.Count > 0);
    R := Recorder.List.List^[Recorder.List.Count - 1];

    // some records are not safe to overwrite
    // we must begin a new one then
    if {(R.ActionFlags and raf_StartPause <> 0) or}
       (R.Iteration <> CurrentIteration) or
       (R.ActionFlags and raf_SkillAssignment <> 0) then
    begin
      R := Recorder.Add;
      NewRec := True;
    end;


   // if R.Iteration = CurrentIteration then
     // if R.ActionFlags and raf}
  end
  else begin*)
    R := Recorder.Add;
    NewRec := True;
  //end;

  R.Iteration := CurrentIteration;
  if NewRec then
    R.ActionFlags := raf_SkillSelection
  else
    R.ActionFlags := R.ActionFlags or raf_SkillSelection;

  //if Paused then R.ActionFlags := R.ActionFlags or raf_Pausing;

  R.ReleaseRate := CurrReleaseRate;

  { TODO : make a table for this }
  case aSkill of
    spbWalker:r.SelectedButton := rsb_Walker;
    spbClimber:r.SelectedButton := rsb_Climber;
    spbSwimmer:r.SelectedButton := rsb_Swimmer;
    spbUmbrella:r.SelectedButton := rsb_Umbrella;
    spbGlider:r.SelectedButton := rsb_Glider;
    spbMechanic:r.SelectedButton := rsb_Mechanic;
    spbExplode:r.SelectedButton := rsb_Explode;
    spbStoner:r.SelectedButton := rsb_Stoner;
    spbBlocker:r.SelectedButton := rsb_Stopper;
    spbPlatformer:r.SelectedButton := rsb_Platformer;
    spbBuilder:r.SelectedButton := rsb_Builder;
    spbStacker:r.SelectedButton := rsb_Stacker;
    spbBasher:r.SelectedButton := rsb_Basher;
    spbMiner:r.SelectedButton := rsb_Miner;
    spbDigger:r.SelectedButton := rsb_Digger;
    spbCloner:r.Selectedbutton := rsb_Cloner;
  // make sure of nothing else
  end;
end;


procedure TLemmingGame.CheckForReplayAction(RRCheck: Boolean);
// this is bad code but works for now

// all records with the same iterationnumber must be
// handled here in one atomic moment
var
  R: TReplayItem;
  Last: Integer;
  PrevReplayIndex: Integer;
  //RRChange: Boolean;
begin
  if not fReplaying then
    Exit;

  Last := fRecorder.List.Count - 1;

  fReplayCommanding := True;

{  if CurrentIteration > 2366 then
  begin
  fReplayCommanding := True;

  end;
}

  PrevReplayIndex := fReplayIndex;

  try

  // although it may not be possible to have 2 replay-actions at one
  // iteration we use a while loop: it's the safest method

  while fReplayIndex <= Last do
  begin
    R := fRecorder.List.List^[fReplayIndex];


    if (R.Iteration <> CurrentIteration) then
      Break;

    if not RRCheck then
    begin
      if raf_Nuke and r.actionflags <> 0 then
        SetSelectedSkill(spbNuke, True);
      if raf_skillassignment and r.actionflags <> 0 then
        ReplaySkillAssignment(R);
      if raf_skillselection and r.actionflags <> 0 then
        ReplaySkillSelection(R);
    end;

    if RRCheck then
    begin
      //RRChange := false;
      if raf_stopchangingRR and r.actionflags <> 0 then
      begin
        SetSelectedSkill(spbFaster, False);
        SetSelectedSkill(spbSlower, False);
        if (R.ReleaseRate <> CurrReleaseRate) and not CheckGimmick(GIM_RRFLUC) then
          if R.ReleaseRate > 0 then
            //fRRPending := R.ReleaseRate;
            AdjustReleaseRate(R.ReleaseRate - currReleaseRate);
        //RRChange := true;
      end
      else if raf_startincreaserr and r.actionflags <> 0 then
      begin
        SetSelectedSkill(spbFaster, True);
        //fRRPending := 100;
        //RRChange := true;
      end else if raf_startdecreaserr and r.actionflags <> 0 then
      begin
        SetSelectedSkill(spbSlower, True);
        //fRRPending := -1;
        //RRChange := true;
      end;

      //if RRChange then CheckAdjustReleaseRate;
    end;

    // check for changes (error)
    if not fReplaying then
      Exit;

    // double check
    if (R.ReleaseRate <> CurrReleaseRate) and RRCheck then
      if R.ReleaseRate > 0 then
        AdjustReleaseRate(R.ReleaseRate - currReleaseRate);

    Inc(fReplayIndex);



    if fReplayIndex >= fRecorder.List.Count then
      Break;
    if fReplayIndex < 0 then
      Break;
  end;

  finally
    if not RRCheck then fReplayIndex := PrevReplayIndex;
    fReplayCommanding := False;
  end;

end;

procedure TLemmingGame.CheckLemmings;
var
  i: Integer;
  CurrentLemming: TLemming;
  HandleInteractiveObjects: Boolean;
  CountDownReachedZero: Boolean;
begin

  ZombieMap.Clear(0);

  if CheckGimmick(GIM_GHOSTS) then
    for i := 0 to LemmingList.Count-1 do
    begin
      CurrentLemming := LemmingList.List^[i];
      if CurrentLemming.LemRemoved then Continue;
      if CurrentLemming.LemIsGhost then SetGhostField(CurrentLemming);
    end;

  for i := 0 to LemmingList.Count - 1 do
  begin
    CurrentLemming := LemmingList.List^[i];

    with CurrentLemming do
    begin
      CountDownReachedZero := False;
      // @particles
      if LemParticleTimer > 0 then
      begin
        Dec(LemParticleTimer);
        Inc(LemParticleFrame);
      end else if LemParticleTimer = 0 then
        begin
          //EraseParticles(CurrentLemming);
          Dec(LemParticleTimer);
        end;
      if LemInTrap > 1 then
      begin
        Dec(LemInTrap);
        if LemInTrap = 1 then LemRemoved := false;
      end;
      if LemRemoved or LemTeleporting then
        Continue;
      if LemExplosionTimer <> 0 then
        CountDownReachedZero := UpdateExplosionTimer(CurrentLemming);
      if CountDownReachedZero then
        Continue;
      HandleInteractiveObjects := HandleLemming(CurrentLemming);
      //if HandleInteractiveObjects then
        CheckForInteractiveObjects(CurrentLemming, HandleInteractiveObjects);
    end;

  end;

  if CheckGimmick(GIM_ZOMBIES) then
    for i := 0 to LemmingList.Count - 1 do
    begin
      CurrentLemming := LemmingList.List^[i];
      with CurrentLemming do
      begin
        // Zombies //
        if (ReadZombieMap(LemX, LemY) and 1 <> 0)
        and (LemAction <> baExiting)
        and not CheckGimmick(GIM_INVINCIBLE)
        and not CurrentLemming.LemIsZombie
        and not CurrentLemming.LemIsGhost then RemoveLemming(CurrentLemming, RM_ZOMBIE);
      end;
    end;

end;

procedure TLemmingGame.SetGameResult;
{-------------------------------------------------------------------------------
  We will not, I repeat *NOT* simulate the original Nuke-error.

  (ccexplore: sorry, code added to implement the nuke error by popular demand)
-------------------------------------------------------------------------------}
var
  gLemCap : Integer;
  i: Integer;
begin
  with GameResultRec do
  begin
    gCount              := Level.Info.LemmingsCount;
    gToRescue           := Level.Info.RescueCount;
    gRescued            := LemmingsIn;
    gLemCap             := Level.Info.LemmingsCount;
    if (fGameParams.UsePercentages = 2) and ((Level.Info.SkillTypes and $1) <> 0) then
    begin
     gLemCap            := gLemCap + Level.Info.ClonerCount;
     for i := 0 to Level.InteractiveObjects.Count-1 do
       if Graph.MetaObjects[Level.InteractiveObjects[i].Identifier].TriggerEffect = 14 then
         if Level.InteractiveObjects[i].Skill = 15 then Inc(gLemCap);
    end;
    gSecretGoto         := fSecretGoto;

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

    if (gSecretGoto >= 0) then   // old secret level code
    begin
      gSuccess := True;
      gDone := 100;
      gRescued := gCount;
    end;
  end;
end;

procedure TLemmingGame.CheckForPlaySoundEffect;
var
  i: Integer;
begin
  if HyperSpeed then
    Exit;
  if Length(fSoundToPlay) <> 0 then
    for i := 0 to Length(fSoundToPlay)-1 do
      SoundMgr.PlaySound(fSoundToPlay[i]);
  SetLength(fSoundToPlay, 0);
end;

procedure TLemmingGame.RegainControl;
{-------------------------------------------------------------------------------
  This is a very important routine. It jumps from replay into usercontrol.
-------------------------------------------------------------------------------}
//var
  //LastBeforeBeginPause: Integer;

    {function FindBeforePause: Integer; //=findbeginpause
    var
      R: TReplayItem;
    begin

      Result := fReplayIndex;

      if fReplayIndex >= Recorder.List.Count then
      begin
        Result := Recorder.List.Count - 1;
        Exit;
      end;


      while Result >= 0 do
      begin
        R := Recorder.List.List^[Result];
        if R.ActionFlags and (raf_Pausing or raf_EndPause or raf_StartPause) = 0 then
          Break;
        Dec(Result);
      end;
    end;}

    (*
    function FindPoint: Integer; //=findbeginpause
    var
      R: TReplayItem;
    begin

      Result := fReplayIndex;

      if fReplayIndex >= Recorder.List.Count then
      begin
        Result := Recorder.List.Count - 1;
        Exit;
      end;


      while Result >= 0 do
      begin
        R := Recorder.List.List^[Result];
        if R.ActionFlags and (raf_Pausing or raf_EndPause{ or raf_StartPause}) = 0 then
          Break;
        Dec(Result);
      end;
    end;*)


begin
  if fReplaying then
  begin
    //cuesoundeffect()
    // there is a bug here when regaining...
    fReplaying := False;

    //LastBeforeBeginPause := FindBeforePause;
    //fRecorder.Truncate(Max(LastBeforeBeginPause, 0));

    // Don't erase the current frame.
    fReplayIndex := 0;
    while fReplayIndex < fRecorder.List.Count do
    begin
      if TReplayItem(fRecorder.List[fReplayIndex]).fIteration > fCurrentIteration then Break;
      Inc(fReplayIndex);
    end;

    fRecorder.Truncate(fReplayIndex);

    // special case: if the game is paused
    // and the control is regained we have to insert a
    // startpause record.
    //if Paused then
    //  RecordStartPause;

    fReplayIndex := 0;//Recorder.List.Count - 1;
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
//  fSoundToPlay := -1;
end;

procedure TLemmingGame.HyperSpeedEnd;
begin
  if fHyperSpeedCounter > 0 then
  begin
    Dec(fHyperSpeedCounter);
    if fHyperSpeedCounter = 0 then
    begin
      fLeavingHyperSpeed := True;
      RefreshAllPanelInfo;
      //fHyperSpeed := False;
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
  i, {t,} xi: Integer;
  //tlx, tly: Integer;
  L: TLemming;
const
  OID_ENTRY                 = 1;
begin
(*  // moving entrances?
  if not fEntranceAnimationCompleted
  and (CurrentIteration >= 35) then
  begin
    for i := 0 to Entries.Count - 1 do
    begin
      Inf := Entries.List^[i];
      if Inf.Triggered then
      begin
        Inc(Inf.CurrentFrame);
        if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
        begin
          Inf.CurrentFrame := 0;
          Inf.Triggered := False;
          fEntranceAnimationCompleted := True;
        end;
      end;
    end;
  end;
*)
  // other objects
//  with ObjectInfos do
  for i := ObjectInfos.Count - 1 downto 0 do
  begin
    Inf := ObjectInfos.List^[i];

    if (Inf.Triggered or (Inf.MetaObj.AnimationType = oat_Continuous)) and (Inf.MetaObj.TriggerEffect <> 14) then
      Inc(Inf.CurrentFrame);
    if (Inf.MetaObj.TriggerEffect = 11) or ((Inf.MetaObj.TriggerEffect = 28) and (Inf.TwoWayReceive = false)) then
        begin
        if ((Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount) and (Inf.MetaObj.TriggerNext = 0))
        or ((Inf.CurrentFrame = Inf.MetaObj.TriggerNext) and (Inf.MetaObj.TriggerNext <> 0)) then
        begin
        L := LemmingList.List^[Inf.TeleLem];
        xi := FindReceiver(i, Inf.Obj.Skill);
        if xi <> i then
        begin

          {if not CheckGimmick(GIM_CHEAPOMODE) then
          begin

             if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop) - (Inf.MetaObj.TriggerHeight - 1)
               else
               tly := Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft) - (Inf.MetaObj.TriggerWidth - 1)
               else
               tlx := Inf.Obj.Left + Inf.MetaObj.TriggerLeft;
             tlx := L.LemX - tlx;
             tly := L.LemY - tly;
             if Inf.Obj.DrawingFlags and 8 <> 0 then
               tlx := Inf.MetaObj.TriggerWidth - tlx - 1;
             Inf2 := ObjectInfos[xi];
             if Inf2.Obj.DrawingFlags and 2 <> 0 then
               tly := tly + Inf2.Obj.Top + (Inf2.MetaObj.Height - 1) - (Inf2.MetaObj.TriggerTop) - (Inf2.MetaObj.TriggerHeight - 1)
               else
               tly := tly + Inf2.Obj.Top + Inf2.MetaObj.TriggerTop;
             if Inf2.Obj.DrawingFlags and 64 <> 0 then
               tlx := tlx + Inf2.Obj.Left + (Inf2.MetaObj.Width - 1) - (Inf2.MetaObj.TriggerLeft) - (Inf2.MetaObj.TriggerWidth - 1)
               else
               tlx := tlx + Inf2.Obj.Left + Inf2.MetaObj.TriggerLeft;

          end else begin

             {if Inf.Obj.DrawingFlags and 2 <> 0 then
               tly := Inf.Obj.Top + (Inf.MetaObj.Height - 1) - (Inf.MetaObj.TriggerTop)
               else
               tly := Inf.Obj.Top + Inf.MetaObj.TriggerTop;
             if Inf.Obj.DrawingFlags and 64 <> 0 then
               tlx := Inf.Obj.Left + (Inf.MetaObj.Width - 1) - (Inf.MetaObj.TriggerLeft)
               else
               tlx := Inf.Obj.Left + Inf.MetaObj.TriggerLeft;}
             {tlx := 0; //L.LemX - tlx;
             tly := 0; //L.LemY - tly;
             if Inf.Obj.DrawingFlags and 8 <> 0 then
               tlx := Inf.MetaObj.TriggerWidth - tlx - 1;
             Inf2 := ObjectInfos[xi];
             if Inf2.Obj.DrawingFlags and 2 <> 0 then
               tly := tly + Inf2.Obj.Top + (Inf2.MetaObj.Height - 1) - (Inf2.MetaObj.TriggerTop)
               else
               tly := tly + Inf2.Obj.Top + Inf2.MetaObj.TriggerTop;
             if Inf2.Obj.DrawingFlags and 64 <> 0 then
               tlx := tlx + Inf2.Obj.Left + (Inf2.MetaObj.Width - 1) - (Inf2.MetaObj.TriggerLeft)
               else
               tlx := tlx + Inf2.Obj.Left + Inf2.MetaObj.TriggerLeft;

          end;

             L.LemX := tlx;
             L.LemY := tly;}

        //L.LemX := ObjectInfos[xi].Obj.Left + ObjectInfos[xi].MetaObj.TriggerLeft + (L.LemX - Inf.Obj.Left - Inf.MetaObj.TriggerLeft);
        //L.LemY := ObjectInfos[xi].Obj.Top + ObjectInfos[xi].MetaObj.TriggerTop + (L.LemY - Inf.Obj.Top - Inf.MetaObj.TriggerTop);
        MoveLemToReceivePoint(L, i);
        Inf2 := ObjectInfos[xi];
        Inf2.TeleLem := Inf.TeleLem;
        Inf2.Triggered := True;
        Inf2.ZombieMode := Inf.ZombieMode;
        Inf2.TwoWayReceive := true;
        end;
        end;
        end;
    if (Inf.MetaObj.TriggerEffect = 12) or ((Inf.MetaObj.TriggerEffect = 28) and (Inf.TwoWayReceive = true)) then
    begin
      if ((Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount) and (Inf.MetaObj.TriggerNext = 0))
      or ((Inf.CurrentFrame = Inf.MetaObj.TriggerNext) and (Inf.MetaObj.TriggerNext <> 0)) then
      begin
        L := LemmingList.List^[Inf.TeleLem];
        L.LemTeleporting := false;
        HandleLemming(L);
        //Transition(LemmingList[Inf.TeleLem], baWalking);
      end;
    end;
    If Inf.MetaObj.TriggerEffect = 29 then
    begin
      if ((Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount) and (Inf.MetaObj.TriggerNext = 0))
      or ((Inf.CurrentFrame = Inf.MetaObj.TriggerNext) and (Inf.MetaObj.TriggerNext <> 0)) then
      begin
        L := LemmingList.List^[Inf.TeleLem];
        L.LemTeleporting := false;
        HandleLemming(L);
      end;
    end;
    if Inf.CurrentFrame >= Inf.MetaObj.AnimationFrameCount then
    begin
      Inf.CurrentFrame := 0;
      Inf.Triggered := False;
      Inf.HoldActive := False;
      Inf.ZombieMode := False;
      if (Inf.Obj.Identifier = OID_ENTRY) then
        fEntranceAnimationCompleted := True;
    end;

  end;

end;

procedure TLemmingGame.CheckAdjustReleaseRate;
begin
//exit;
  {if fRRPending = -1 then
    SetSelectedSkill(spbSlower, True)
  else if fRRPending = 100 then
    SetSelectedSkill(spbFaster, True)
  else if fRRPending <> 0 then
  begin
    SetSelectedSkill(spbFaster, False);
    SetSelectedSkill(spbSlower, False);
    AdjustReleaseRate(fRRPending - CurrReleaseRate);
  end;
  fRRPending := 0;}

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
  else
    SoundMgr.PlayMusic(0)
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
  fGameCheated := True;      // IN-LEVEL CHEAT // just uncomment these two lines to reverse
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
    Result := Result + '.lrb';
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
    Dlg.Filter := 'Lemmix Replay (*.lrb)|*.lrb|Replay + Text File (*.lrb)|*.lrb';
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
    // Don't need to hande AlwaysTimestamp here; it's handled in GetReplayFileName above.
  end;

begin
  SaveText := false;

  SaveNameLrb := GetReplayFileName;

  case GetReplayTypeCase of
    0: SaveNameLrb := GetDefaultSavePath + SaveNameLrb;
    1: begin
         UnpauseAfterDlg := not Paused; // Game keeps running during the MessageDlg otherwise. And yes, the code here
                                        // bypasses the no-pause in Frenzy levels. ;P
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
    Recorder.SaveToFile(SaveNameLrb);
    if SaveText then
    begin
      SaveNameTxt := ChangeFileExt(SaveNameLrb, '.txt');
      Recorder.SaveToTxt(SaveNameTxt);
    end;
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
    if (ObjectInfos[i].MetaObj.TriggerEffect = 14) and (ObjectInfos[i].Obj.Skill = 15) then pcc := pcc + 1;
  if (LemmingsOut + LemmingsIn + (Level.Info.LemmingsCount - LemmingsReleased - SpawnedDead) +
      ((Level.Info.SkillTypes and 1) * CurrClonerCount) + pcc
     < Level.Info.RescueCount)
  and (CurrentIteration mod 17 > 8) {and (CurrentIteration mod 34 < 27)} then
    Result := true;
end;

function TLemmingGame.CheckRescueBlink: Boolean;
begin
  Result := false;
  if not (fGameParams.RescueBlink) then Exit;
  if (((LemmingsIn < Level.Info.RescueCount) and not fGameParams.AltRescueBlink)
  or ((LemmingsIn >= Level.Info.RescueCount) and fGameParams.AltRescueBlink))
  and (CurrentIteration mod 17 > 8) {and (CurrentIteration mod 34 < 27)} then
    Result := true;
end;

function TLemmingGame.CheckTimerBlink: Boolean;
begin
  Result := false;
  if not (fGameParams.TimerBlink) then Exit; 
  if ((fGameParams.TimerMode) or (fGameParams.Level.Info.TimeLimit > 5999)) then Exit;
  if (Minutes = 0) and (Seconds < 30)
  and (CurrentIteration mod 17 > 8) {and (CurrentIteration mod 34 < 27)} then
    Result := true;
end;


function TLemmingGame.CheckSkillAvailable(aAction: TBasicLemmingAction): Boolean;
var
  sc, i: Integer;
  CheckButton: TSkillPanelButton;
begin
  Result := fFreezeSkillCount;
  if fFreezeSkillCount then Exit;

  case aAction of
    baToWalking  : sc := CurrWalkerCount;
    baClimbing   : sc := CurrClimberCount;
    baSwimming   : sc := CurrSwimmerCount;
    baFloating   : sc := CurrFloaterCount;
    baGliding    : sc := CurrGliderCount;
    baFixing     : sc := CurrMechanicCount;
    baExploding  : sc := CurrBomberCount;
    baStoning    : sc := CurrStonerCount;
    baBlocking   : sc := CurrBlockerCount;
    baPlatforming: sc := CurrPlatformerCount;
    baBuilding   : sc := CurrBuilderCount;
    baStacking   : sc := CurrStackerCount;
    baBashing    : sc := CurrBasherCount;
    baMining     : sc := CurrMinerCount;
    baDigging    : sc := CurrDiggerCount;
    baCloning    : sc := CurrClonerCount;
    else Exit;
  end;

  if sc > 99 then Result := true;
  if CheckGimmick(GIM_OVERFLOW) then Result := true;
  if CheckGimmick(GIM_REVERSE) and (sc < 99) then Result := true;
  if (sc > 0) and not CheckGimmick(GIM_REVERSE) then Result := true;

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
  case aAction of
    baToWalking  : begin sc := @CurrWalkerCount; sc2 := @UsedWalkerCount; end;
    baClimbing   : begin sc := @CurrClimberCount; sc2 := @UsedClimberCount; end;
    baSwimming   : begin sc := @CurrSwimmerCount; sc2 := @UsedSwimmerCount; end;
    baFloating   : begin sc := @CurrFloaterCount; sc2 := @UsedFloaterCount; end;
    baGliding    : begin sc := @CurrGliderCount; sc2 := @UsedGliderCount; end;
    baFixing     : begin sc := @CurrMechanicCount; sc2 := @UsedMechanicCount; end;
    baExploding  : begin sc := @CurrBomberCount; sc2 := @UsedBomberCount; end;
    baStoning    : begin sc := @CurrStonerCount; sc2 := @UsedStonerCount; end;
    baBlocking   : begin sc := @CurrBlockerCount; sc2 := @UsedBlockerCount; end;
    baPlatforming: begin sc := @CurrPlatformerCount; sc2 := @UsedPlatformerCount; end;
    baBuilding   : begin sc := @CurrBuilderCount; sc2 := @UsedBuilderCount; end;
    baStacking   : begin sc := @CurrStackerCount; sc2 := @UsedStackerCount; end;
    baBashing    : begin sc := @CurrBasherCount; sc2 := @UsedBasherCount; end;
    baMining     : begin sc := @CurrMinerCount; sc2 := @UsedMinerCount; end;
    baDigging    : begin sc := @CurrDiggerCount; sc2 := @UsedDiggerCount; end;
    baCloning    : begin sc := @CurrClonerCount; sc2 := @UsedClonerCount; end;
    else Exit;
  end;

  if sc^ > 99 then Exit;

  if Rev xor CheckGimmick(GIM_REVERSE) then // Because both combined should act as normal
    Inc(sc^)
    else
    Dec(sc^);

  if not Rev then Inc(sc2^);

  if CheckGimmick(GIM_OVERFLOW) then
  begin
    if sc^ < 0 then sc^ := 99;
    if sc^ > 99 then sc^ := 0;
  end else begin
    if sc^ < 0 then sc^ := 0;
    if sc^ > 99 then sc^ := 99;
  end;

  case aAction of
    baToWalking  : InfoPainter.DrawSkillCount(spbWalker, sc^);
    baClimbing   : InfoPainter.DrawSkillCount(spbClimber, sc^);
    baSwimming   : InfoPainter.DrawSkillCount(spbSwimmer, sc^);
    baFloating   : InfoPainter.DrawSkillCount(spbUmbrella, sc^);
    baGliding    : InfoPainter.DrawSkillCount(spbGlider, sc^);
    baFixing     : InfoPainter.DrawSkillCount(spbMechanic, sc^);
    baExploding  : InfoPainter.DrawSkillCount(spbExplode, sc^);
    baStoning    : InfoPainter.DrawSkillCount(spbStoner, sc^);
    baBlocking   : InfoPainter.DrawSkillCount(spbBlocker, sc^);
    baPlatforming: InfoPainter.DrawSkillCount(spbPlatformer, sc^);
    baBuilding   : InfoPainter.DrawSkillCount(spbBuilder, sc^);
    baStacking   : InfoPainter.DrawSkillCount(spbStacker, sc^);
    baBashing    : InfoPainter.DrawSkillCount(spbBasher, sc^);
    baMining     : InfoPainter.DrawSkillCount(spbMiner, sc^);
    baDigging    : InfoPainter.DrawSkillCount(spbDigger, sc^);
    baCloning    : InfoPainter.DrawSkillCount(spbCloner, sc^);
  end;

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
//  with P^ do
    //deb([r,g,b]);
//  deb(['---------']);

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
  //    deb([r,g,b]);
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
//      deb([r,g,b]);
    end;
  end;

end;

{ TRecorder }

function TRecorder.Add: TReplayItem;
begin
  Result := TReplayItem.create;
  List.Add(Result);
end;

function TRecorder.GetNumItems: Integer;
begin
  Result := List.Count;
end;

function TRecorder.FindIndexForFrame(aFrame: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to List.Count-1 do
  begin
    Result := i;
    if TReplayItem(List[i]).Iteration >= aFrame then Exit;
  end;
end;

procedure TRecorder.Clear;
begin
  List.Clear;
  fLevelID := 0;
end;

constructor TRecorder.Create(aGame: TLemmingGame);
begin
  fGame := aGame;
  List := TObjectlist.Create;
  fLevelID := 0;
end;

destructor TRecorder.Destroy;
begin
  List.Free;
  inherited;
end;

procedure TRecorder.LoadFromFile(const aFileName: string; IgnoreProblems: Boolean = false);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFileName, fmOpenRead{Write}); // needed for silent conversion
  try
    LoadFromStream(F, IgnoreProblems);
  finally
    F.Free;
  end;
end;

procedure TRecorder.LoadFromStream(S: TStream; IgnoreProblems: Boolean = false);
var
//  i: Integer;
  H: TReplayFileHeaderRec;
  R: TReplayRec;
  It: TReplayItem;
  Iter, RR, Parity: Integer;
  ErrorID: Integer;
  ErrorStr: String;
  HasCheck: Boolean;
begin
  S.ReadBuffer(H, SizeOf(H));
  ErrorID := 0;


  if (H.Signature <> 'NEO') and (H.Signature <> 'LRB') then
    ErrorID := ErrorID or $1;

  //if H.Version <> 1 then
    //raise Exception.Create('invalid replay header version, must be 1');

  if H.Version = 103 then   //compatibility with old versions
  begin
    H.Version := 104;
    H.ReplaySec := H.ReplayTime;
    H.ReplayLev := H.ReplaySaved;
    H.ReplayOpt := [];
    H.ReplayTime := 0;
    H.ReplaySaved := 0;
    HasCheck := false;
  end else
    HasCheck := true;

  if H.Version = 104 then
  begin
    H.Version := 105;
    H.ReplayLevelID := 0;
    FillChar(H.Reserved, SizeOf(H.Reserved), 0);
  end;

  if H.FileSize <> S.Size then
    ErrorID := ErrorID or $2;

  if H.HeaderSize <> SizeOf(TReplayFileHeaderRec) then
    ErrorID := ErrorID or $4;

  {if H.Mechanics - [dgoObsolete] <> fGame.Options - [dgoObsolete] then
  begin
    MessageDlg('Invalid replay signature.',mtCustom, [mbOK], 0);
    Exit;
  end;}

  if H.FirstRecordPos < H.HeaderSize then
    ErrorID := ErrorID or $8;

  if H.ReplayRecordSize <> SizeOf(TReplayFileHeaderRec) then
    ErrorID := ErrorID or $10;


  // we added this silent conversion in replay version 2, Lemmix 0.0.8.0
(*  if H.Version = 1 then
  begin
    H.Version := LEMMIX_REPLAY_VERSION;
    Include(H.Mechanics, dgoMinerOneWayRightBug);
    S.Seek(0, soFromBeginning);
    S.Write(H, H.HeaderSize);
  end; *)
{  if H.Version = 1 then
    ShowMessage('This replay file contains obsolete mechanics, please upgrade it');
 }



  if H.Version <> LEMMIX_REPLAY_VERSION then
    ErrorID := ErrorID or $20;

  if fgame.fGameParams.SysDat.Options and 8 = 0 then
  begin

  if (H.ReplayGame <> 0) or (H.ReplaySec <> 0) or (H.ReplayLev <> 0) then HasCheck := true;

  if (H.ReplayGame <> fgame.fGameParams.SysDat.CodeSeed) and (HasCheck) then
    ErrorID := ErrorID or $40;

  if (H.ReplaySec <> fgame.fGameParams.Info.dSection) and (HasCheck) then
    ErrorID := ErrorID or $80;

  if (H.ReplayLev <> fgame.fGameParams.Info.dLevel) and (HasCheck) then
    ErrorID := ErrorID or $100;

  if (H.ReplayLevelID <> fGame.fGameParams.Level.Info.LevelID) then
  begin
    if (H.ReplayLevelID <> 0) then
      ErrorID := ErrorID or $400;
  end else
    ErrorID := ErrorID and not $1C0;
  end;

  if (ErrorID <> 0) then
  begin
    ErrorStr := IntToHex(ErrorId, 4);
    if (ErrorID and $20) <> 0 then ErrorStr := ErrorStr + #13 + 'Doesn''t appear to be a NeoLemmix replay.';
    if (ErrorID and $40) <> 0 then ErrorStr := ErrorStr + #13 + 'Incorrect game.';
    if (ErrorID and $80) <> 0 then ErrorStr := ErrorStr + #13 + 'Incorrect rank.';
    if (ErrorID and $100) <> 0 then ErrorStr := ErrorStr + #13 + 'Incorrect level.';
    if (ErrorID and $400) <> 0 then ErrorStr := ErrorStr + #13 + 'Incorrect level unique ID.';
    if (ErrorID and (not $5E0)) <> 0 then ErrorStr := ErrorStr + #13 + 'Misc errors.';
    if (ErrorID and (not $5C0)) <> 0 then
    begin
      ErrorStr := 'Replay error: #' + ErrorStr;
      if not IgnoreProblems then
        ShowMessage(ErrorStr);
      Exit;
    end else begin
      ErrorStr := 'Replay warning: #' + ErrorStr;
      if not IgnoreProblems then
        ShowMessage(ErrorStr);
    end;
  end;


  Parity := 0;
  List.Clear;
  List.Capacity := H.ReplayRecordCount;
  S.Seek(H.FirstRecordPos, soFromBeginning);

  while True do
  begin
    if S.Read(R, SizeOf(TReplayRec)) <> SizeOf(TReplayRec) then
      Break;
    if R.Check <> 'R' then
    begin
      ShowMessage('Replay error: #0200' + #13 + 'at ' + i2s(List.Count));
      List.Clear;
      Exit;
    end;
    It := Add;
    It.Iteration := R.Iteration;
    It.ActionFlags := R.ActionFlags;
    It.AssignedSkill := R.AssignedSkill;
    It.SelectedButton := R.SelectedButton;
    It.ReleaseRate := R.ReleaseRate;
    It.LemmingIndex := R.LemmingIndex;
    It.LemmingX := R.LemmingX;
    It.LemmingY := R.LemmingY;
    It.CursorX := R.CursorX;
    It.CursorY := R.CursorY;
    It.fSelectDir := R.SelectDir;

    {if R.ActionFlags = raf_StartPause then
      Inc(Parity)
    else if R.ActionFlags = raf_Endpause then
      Dec(Parity);}

    RR := R.Releaserate;
    Iter := R.Iteration;

    // add fake paused record if unpaired startpuase
    // this happens when this file is saved in paused mode!
    {if List.Count = H.ReplayRecordCount then
      if Parity = 1 then
//      if R.ActionFlags = raf_StartPause then
      begin
        It := Add;
        It.Iteration := Iter;
        It.ReleaseRate := RR;
        It.ActionFlags := raf_EndPause;
        Break;
      end;}

    if List.Count >= H.ReplayRecordCount then
      Break;
  end;
end;

procedure TRecorder.SaveToFile(const aFileName: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFileName, fmCreate);
  try
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

procedure TRecorder.SaveToStream(S: TStream);
var
  i: Integer;
  H: TReplayFileHeaderRec;
  R: TReplayRec;
  It: TReplayItem;
//  RecCount: Integer;
  //Parity: Integer;

  (*
    // a little #$% selfprotection against an isolated startpause when saving
    function GetRecordableCount: Integer;
    var
      It: TReplayItem;
      Ix: Integer;
    begin
//      with fRecorder do
      begin
        Ix := List.Count - 1;
        Result := List.Count;
        while Ix >= 0 do
        begin
          It := List.List^[ix];
          if It.ActionFlags and raf_StartPause = 0 then
            Break;
          Dec(Result);
          Dec(Ix);
        end;

      end;
    end;
*)

begin

  FillChar(H, SizeOf(TReplayFileHeaderRec), 0);
//  Parity := 0;

  H.Signature := 'NEO';
  H.Version := LEMMIX_REPLAY_VERSION;
  H.FileSize := SizeOf(TReplayFileHeaderRec) +
                SizeOf(TReplayRec) * List.Count;
  H.HeaderSize := SizeOf(TReplayFileHeaderRec);
  H.Mechanics := fGame.Options; // compatible for now
  Include(H.Mechanics, dgoObsolete);
  H.FirstRecordPos := H.HeaderSize;
  H.ReplayRecordSize := SizeOf(TReplayFileHeaderRec);
  H.ReplayRecordCount := List.Count;

  H.ReplayGame := fgame.fGameParams.SysDat.CodeSeed;
  H.ReplaySec := fgame.fGameParams.Info.dSection;
  H.ReplayLev := fgame.fGameParams.Info.dLevel;

  //H.ReplayOpt
  with fGame do
  begin
    if LemmingsIn >= fGameParams.Level.Info.RescueCount then
      Include(H.ReplayOpt, rpoLevelComplete);
    if not (
       (fGameParams.ChallengeMode or fGameParams.TimerMode)
       or (fGameParams.ForceGimmick <> 0)
       or (fGameParams.ForceGimmick2 <> 0)
       or (fGameParams.ForceGimmick3 <> 0)
       or (fGameParams.ForceSkillset <> 0)
       ) then
      Include(H.ReplayOpt, rpoNoModes);
    if fSecretGoto <> -1 then
      Include(H.ReplayOpt, rpoSecret);
  end;

  H.ReplayTime := fGame.GameResultRec.gLastRescueIteration;
  H.ReplaySaved := fGame.LemmingsIn;

  H.ReplayLevelID := fGame.fGameParams.Level.Info.LevelID;


  // bad programming
  {
  if fGameMechanics.Paused then
  begin
    Inc(H.ReplayRecordCount);
    parity := 1;
  end;
  }

  FillChar(H.Reserved, SizeOf(H.Reserved), 0);

  S.WriteBuffer(H, SizeOf(TReplayFileHeaderRec));

  for i := 0 to List.Count - 1 do
  begin
    It := List.List^[i];

    (*
    if It.ActionFlags = raf_Startpause then
      Inc(Parity)
    else if It.ActionFlags = raf_EndPause then
      Dec(Parity);

    if Parity > 1 then
      raise Exception.Create('too much start pauses');

    if Parity < - 1 then
      raise Exception.Create('too much end pauses'); *)

    R.Check := 'R';
    R.Iteration := It.fIteration;
    R.ActionFlags := It.fActionFlags;
    R.AssignedSkill := It.AssignedSkill;
    R.SelectedButton := It.fSelectedButton;
    R.ReleaseRate := It.fReleaseRate;
    R.LemmingIndex := It.fLemmingIndex;
    R.LemmingX := It.fLemmingX;
    R.LemmingY := It.fLemmingY;
    R.CursorX := It.CursorX;
    R.CursorY := It.CursorY;
    R.SelectDir := It.SelectDir;

    //It.WriteToRec(R);
    S.WriteBuffer(R, SizeOf(TReplayRec));
  end;
   (*

  //windlg(
  // this is the case when saving in paused mode, we add a pause record
  // to the stream
  if Parity = 1 then
  begin
    R.Check := 'R';
    R.Iteration := fGameMechanics.CurrentIteration;
    R.ActionFlags := raf_EndPause;
    S.WriteBuffer(R, SizeOf(TReplayRec));
  end;
//  else if Parity <> 0 then
  //  raise Exception.Create('invalid save');
  *)

end;

procedure TRecorder.SaveToTxt(const aFileName: string);

var
  i: Integer;
  l:tstringlist;
  m: TDosGameOptions;
  it:TReplayItem;

const skillstrings: array[rla_none..rla_exploding] of string =
(   '-',
    'Walk',
    'Jump (not allowed)',
    'Dig',
    'Climb',
    'Drown (not allowed)',
    'Hoist (not allowed)',
    'Build',
    'Bash',
    'Mine',
    'Fall (not allowed)',
    'Float',
    'Splat (not allowed)',
    'Exit (not allowed)',
    'Vaporize (not allowed)',
    'Block',
    'Shrug (not allowed)',
    'Ohno (not allowed)',
    'Explode'
);

const selstrings: array[rsb_none..rsb_cloner] of string = (
  '-',
  'Slower',
  'Faster',
  'Climber',
  'Umbrella',
  'Explode',
  'Stopper',
  'Builder',
  'Basher',
  'Miner',
  'Digger',
  'Pause',
  'Nuke',
  'Walker',
  'Swimmer',
  'Glider',
  'Mechanic',
  'Stoner',
  'Platformer',
  'Stacker',
  'Cloner');


    procedure ads(const s:string);
    begin
      l.add(s);
    end;

    function bs(b:boolean): string;
    begin
      if b then result := 'yes' else result := 'no';
    end;

    function lz(i,c:integer):string;
    begin
      result:=padl(i2s(i), c, ' ');
//      LeadZeroStr(i,c);
    end;

    function actionstr(af: word): string;
    begin
      {result := '?';
      if raf_StartPause and af <> 0  then
        result := 'Begin Pause'
      else if raf_EndPause and af <> 0  then
        result := 'End Pause'
      else if raf_StartIncreaseRR and af <> 0  then
        result := 'Start RR+'
      else if raf_StartDecreaseRR and af <> 0  then
        result := 'Start RR-'
      else if raf_StopChangingRR and af <> 0  then
        result := 'Stop RR'
      else if raf_SkillSelection and af <> 0  then
        result := 'Select'
      else if raf_SkillAssignment and af <> 0  then
        result := 'Assign'
      else if raf_Nuke and af <> 0  then
        result := 'Nuke';}

      Result := '........';
      {if raf_StartPause and af <> 0  then
        result[1] := 'B';
      if raf_EndPause and af <> 0  then
        result[2] := 'E';}
      if raf_StartIncreaseRR and af <> 0  then
        result[3] := '+';
      if raf_StartDecreaseRR and af <> 0  then
        result[4] := '-';
      if raf_StopChangingRR and af <> 0  then
        result[5] := '*';
      if raf_SkillSelection and af <> 0  then
        result[6] := 'S';
      if raf_SkillAssignment and af <> 0  then
        result[7] := 'A';
      if raf_Nuke and af <> 0  then
        result[8] := 'N';
    end;


begin
  l:=tstringlist.create;
  m:=fGame.Options;

  ads('NeoLemmix V' + PVersion + ' Replay Textfile');
  ads('Game: ' + Trim(fGame.fGameParams.SysDat.PackName));
  ads('------------------------------------------');
  ads('Title: ' + Trim(fgame.level.info.title));
  ads('Position: ' + fgame.fGameParams.Info.dSectionName + ' ' + inttostr(fgame.fGameParams.Info.dLevel + 1));
  ads('Replay fileversion: ' + i2s(LEMMIX_REPLAY_VERSION));
  ads('Number of records: ' + i2s(List.count));
  ads('------------------------------------------');
  if moChallengeMode in fGame.fGameParams.MiscOptions then
  begin
    ads('Challenge mode: Enabled');
    if fGame.Level.Info.SkillTypes and $8000 <> 0 then ads('>> Walkers used:     ' + i2s(fGame.UsedWalkerCount));
    if fGame.Level.Info.SkillTypes and $4000 <> 0 then ads('>> Climbers used:    ' + i2s(fGame.UsedClimberCount));
    if fGame.Level.Info.SkillTypes and $2000 <> 0 then ads('>> Swimmers used:    ' + i2s(fGame.UsedSwimmerCount));
    if fGame.Level.Info.SkillTypes and $1000 <> 0 then ads('>> Floaters used:    ' + i2s(fGame.UsedFloaterCount));
    if fGame.Level.Info.SkillTypes and $0800 <> 0 then ads('>> Gliders used:     ' + i2s(fGame.UsedGliderCount));
    if fGame.Level.Info.SkillTypes and $0400 <> 0 then ads('>> Disarmers used:   ' + i2s(fGame.UsedMechanicCount));
    if fGame.Level.Info.SkillTypes and $0200 <> 0 then ads('>> Bombers used:     ' + i2s(fGame.UsedBomberCount));
    if fGame.Level.Info.SkillTypes and $0100 <> 0 then ads('>> Stoners used:     ' + i2s(fGame.UsedStonerCount));
    if fGame.Level.Info.SkillTypes and $0080 <> 0 then ads('>> Blockers used:    ' + i2s(fGame.UsedBlockerCount));
    if fGame.Level.Info.SkillTypes and $0040 <> 0 then ads('>> Platformers used: ' + i2s(fGame.UsedPlatformerCount));
    if fGame.Level.Info.SkillTypes and $0020 <> 0 then ads('>> Builders used:    ' + i2s(fGame.UsedBuilderCount));
    if fGame.Level.Info.SkillTypes and $0010 <> 0 then ads('>> Stackers used:    ' + i2s(fGame.UsedStackerCount));
    if fGame.Level.Info.SkillTypes and $0008 <> 0 then ads('>> Bashers used:     ' + i2s(fGame.UsedBasherCount));
    if fGame.Level.Info.SkillTypes and $0004 <> 0 then ads('>> Miners used:      ' + i2s(fGame.UsedMinerCount));
    if fGame.Level.Info.SkillTypes and $0002 <> 0 then ads('>> Diggers used:     ' + i2s(fGame.UsedDiggerCount));
    if fGame.Level.Info.SkillTypes and $0001 <> 0 then ads('>> Cloners used:     ' + i2s(fGame.UsedClonerCount));
  end else ads('Challenge mode: Disabled');
  if moTimerMode in fGame.fGameParams.MiscOptions then
  begin
    ads('Timer mode: Enabled');
    if fGame.Minutes = 0 then
      ads('>> Replay saved at: 0:00')
      else ads('>> Replay saved at: ' + i2s(abs(fGame.Minutes + 1)) + ':' + LeadZeroStr((60 - fGame.Seconds) mod 60, 2));
    ads('>> Lemmings saved:  ' + i2s(fGame.LemmingsIn));
  end else ads('Timer mode: Disabled');
  if (fGame.fGameParams.ForceGimmick <> 0) or (fGame.fGameParams.ForceGimmick2 <> 0) or (fGame.fGameParams.ForceGimmick3 <> 0) then
    ads('Forced gimmick: ' + IntToHex(fGame.fGameParams.ForceGimmick, 8) + ':' + IntToHex(fGame.fGameParams.ForceGimmick2, 8) + ':' + IntToHex(fGame.fGameParams.ForceGimmick3, 8))
  else
    ads('Forced gimmick: Disabled');
  ads('------------------------------------------');
  ads('');

  ads(' Rec   Frame  Action        Skill     Button     RR   lem   x    y   mx   my   sd');
  ads('-----------------------------------------------------------------------------------');

  for i:=0 to list.count-1 do
  begin
    it:=list.list^[i];
    ads(
        lz(i, 4) + '  ' +
        lz(it.iteration, 6) + '  ' +
        //padr(bs(it.ActionFlags and raf_pausing <> 0), 7) + ' ' +
        padr(actionstr(it.actionflags), 12) + '  ' +
        padr(skillstrings[it.assignedskill], 8) + '  ' +
        padr(selstrings[it.selectedbutton], 8) + '  ' +
        lz(it.ReleaseRate, 3) + ' ' +
        lz(it.LemmingIndex,4) + ' ' +
        lz(it.lemmingx, 4) + ' ' +
        lz(it.lemmingy, 4) + ' ' +
        lz(it.CursorX, 4) + ' ' +
        lz(it.CursorY, 4) + ' ' +
        lz(it.SelectDir, 4)
    );
  end;

  l.savetofile(afilename);
  l.free;

end;

procedure TRecorder.Truncate(aCount: Integer);
begin
  List.Count := aCount;
end;

procedure TRecorder.LoadFromOldTxt(const aFileName: string);
(*

19, rrStartIncrease, 1
19, rrStop, 85
19, rrStartIncrease, 85
19, rrStop, 86
55, raSkillAssignment, baClimbing, 0
58, rrStartDecrease, 86
58, rrStop, 1
66, raSkillAssignment, baClimbing, 1
77, raSkillAssignment, baExplosion, 0
85, raSkillAssignment, baFloating, 0
96, raSkillAssignment, baFloating, 1
118, raSkillAssignment, baFloating, 2
184, raSkillAssignment, baBuilding, 1
202, raSkillAssignment, baBuilding, 1
219, raSkillAssignment, baBashing, 1
226, raSkillAssignment, baBuilding, 1
243, raSkillAssignment, baBashing, 1
249, raSkillAssignment, baBuilding, 1
412, rrStartIncrease, 1
412, rrStop, 99
518, raSkillAssignment, baBlocking, 1

*)


(*

  TRecordedAction = (
    raNone,
    raSkillAssignment,
    raNuke
  );

  TReleaseRateAction = (
    rrNone,
    rrStop,
    rrStartIncrease,
    rrStartDecrease
  );


*)
var
  L: TStringList;
  i,j: integer;
  s,t: string;

  Cnt: integer;
  RR, ITER: integer;
  TYP: Word;
  SKILL: TBasicLemmingAction;
  LIX: Integer;
  It: TReplayItem;

begin


  L:= TStringList.create;
  try
    l.loadfromfile(aFileName);
    for i := 0 to l.count-1 do
    begin
      s := l[i];
      cnt := SplitStringCount(s, ',');
      if cnt < 3 then
        continue;

      RR := 0;
      ITER:=-1;
      TYP:=0;//rtNone;
      SKILL:=baWalking;
      LIX:=0;

      for j := 0 to cnt - 1 do
      begin


        t:=SplitString(s, j, ',');

        case j of
          0: // currentiteration     umisc
            begin
            ITER := StrToIntDef(t, -1)
            end;
          1: // typ
            begin
              if comparetext(t, 'raNone') = 0 then
                TYP := 0//rtNone
              else if comparetext(t, 'raSkillAssignment') = 0 then
                TYP := raf_SkillAssignment// rtAssignSkill
              else if comparetext(t, 'raNuke') = 0 then
                TYP := raf_Nuke //rtNuke
              else if comparetext(t, 'rrNone') = 0 then
                TYP := 0 //rtNone
              else if comparetext(t, 'rrStop') = 0 then
                TYP := raf_StopChangingRR //rtStopChangingRR
              else if comparetext(t, 'rrStartDecrease') = 0 then
                TYP := raf_StartDecreaseRR //rtStartDecreaseRR
              else if comparetext(t, 'rrStartIncrease') = 0 then
                TYP := raf_StartIncreaseRR; //rtStartIncreaseRR;
            end;
          2: // assign of RR
            begin
             if Cnt = 3 then
             begin
               RR := StrToIntDef(t, -1);
             end
             else begin
               SKILL := TBasiclemmingaction(GetEnumValue(typeinfo(tbasiclemmingaction), t));
             end;
            end;

          3: // lemming index
            begin
              LIX := StrToIntDef(t, -1);
            end;
        end;

      end;

      if (ITER<>-1) and (TYP<>0) then
      begin
        //deb(['item:', iter]);
        It := Add;
         it.Iteration := ITER;
         it.actionflags := TYP;//RecTyp := TYP;
        if Skill > baWalking then
          it.AssignedSkill := Byte(Skill) + 1;
//        It.Skill := SKILL;
        It.LemmingIndex :=LIX;
        It.ReleaseRate  := RR;
      end;



    end;
  finally
    l.free;
  end;


end;


end.
