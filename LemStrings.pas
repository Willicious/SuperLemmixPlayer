{$include lem_directives.inc}

unit LemStrings;

interface

uses
  LemCore,
  SharedGlobals;

var
  SFX_AmigaDisk1,
  SFX_AmigaDisk2,
  SFX_AssignFail,
  SFX_AssignSkill,
  // SFX_BatHit, // Batter
  // SFX_BatSwish, // Batter
  SFX_BalloonInflate,
  SFX_BalloonPop,
  SFX_Boing,
  SFX_Boop,
  SFX_Brick,
  SFX_Bye,
  SFX_Collect,
  SFX_CollectAll,
  SFX_DisarmTrap,
  SFX_Drown,
  SFX_Entrance,
  SFX_ExitUnlock,
  SFX_FailureJingle,
  SFX_FallOff,
  SFX_Fire,
  SFX_Freeze,
  SFX_GrenadeThrow,
  SFX_Jump,
  SFX_Laser,
  SFX_LetsGo,
  SFX_OhNo,
  SFX_OK,
  SFX_Pickup,
  SFX_Pop,
  // SFX_Propeller, // Propeller
  SFX_ReleaseRate,
  SFX_SkillButton,
  SFX_SpearHit,
  SFX_SpearThrow,
  SFX_Splat,
  SFX_Steel_OWW,
  SFX_SuccessJingle,
  SFX_Swim,
  SFX_TimeUp,
  SFX_Vinetrap,
  SFX_Yippee,
  SFX_Zombie,
  SFX_ZombieFallOff,
  SFX_ZombieOhNo,
  SFX_ZombiePickup,
  SFX_ZombieSplat,
  SFX_ZombieExit
    : String;

const
  // Important paths
  SFGraphics = 'gfx\';
    SFGraphicsGame = SFGraphics + 'game\';
    SFGraphicsCursor = SFGraphics + 'cursor\';
    SFGraphicsHelpers = SFGraphics + 'helpers\';
    SFGraphicsHelpersHighRes = SFGraphics + 'helpers-hr\';
    SFGraphicsMasks = SFGraphics + 'mask\';
    SFGraphicsMenu = SFGraphics + 'menu\';
    SFGraphicsPanel = SFGraphics + 'panel\';

  SFStyles = 'styles\';
      SFDefaultStyle = 'default';
      SFPiecesTerrain = '\terrain\';
      SFPiecesTerrainHighRes = '\terrain-hr\';
      SFPiecesObjects = '\objects\';
      SFPiecesObjectsHighRes = '\objects-hr\';
      SFPiecesBackgrounds = '\backgrounds\';
      SFPiecesBackgroundsHighRes = '\backgrounds-hr\';
      SFPiecesLemmings = '\lemmings\';
      SFPiecesLemmingsHighRes = '\lemmings-hr\';
      SFPiecesEffects = '\effects\';
      SFIcons = '\icons\';
      SFTheme = 'theme.nxtm';

  SFLevels = 'levels\';
  SFReplays = 'replays\';

  SFSounds = 'sounds\';
  SFMusic = 'music\';

  SFData = 'data\';
  SFDataTranslation = SFData + 'translation\';
  SFSaveData = 'settings\';
  SFTemp = 'temp\';

resourcestring
  SProgramName = 'SuperLemmix';
  SDummyString = '';

  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  SPreviewSave = ' To Be Saved';
  SPreviewReleaseRate = 'Release Rate ';
  SPreviewSpawnInterval = 'Spawn Interval ';
  SPreviewRRLocked = ' (Locked)';
  SPreviewTimeLimit = 'Time Limit ';
  SPreviewGroup = 'Group: ';
  SPreviewAuthor = 'By ';

  {-------------------------------------------------------------------------------
    Game Screen Info Panel
  -------------------------------------------------------------------------------}

  SAthlete = 'Athlete';
  STriathlete = 'Triathlete';
  SQuadathlete = 'Superstar';
  SQuintathlete = 'Legend';

  SWalker = 'Walker';
  SAscender = 'Ascender';
  SDigger = 'Digger';
  SClimber = 'Climber';
  SDrowner = 'Drowner';
  SHoister = 'Hoister';
  SBuilder = 'Builder';
  SBasher = 'Basher';
  SMiner = 'Miner';
  SFaller = 'Faller';
  SFloater = 'Floater';
  SSplatter = 'Splatter';
  SExiter = 'Exiter';
  SVaporizer = 'Vaporizer';
  SVinetrapper = 'Vinetrapper';
  SBlocker = 'Blocker';
  SShrugger = 'Shrugger';
  STimebomber = 'Timebomber';
  SExploder = 'Exploder';
  SLadderer = 'Ladderer';
  SPlatformer = 'Platformer';
  SStacker = 'Stacker';
  SFreezer = 'Freezer';
  SSwimmer = 'Swimmer';
  SGlider = 'Glider';
  SDisarmer = 'Disarmer';
  SCloner = 'Cloner';
  SFencer = 'Fencer';
  SReacher = 'Reacher';
  SShimmier = 'Shimmier';
  STurner = 'Turner';
  SJumper = 'Jumper';
  SDehoister = 'Dehoister';
  SSlider = 'Slider';
  SDangler = 'Dangler';
  SSpearer = 'Spearer';
  SGrenader = 'Grenader';
  SLooker = 'Looker';
  SLaserer = 'Laserer';
  //SPropeller = 'Propeller'; // Propeller
  SZombie = 'Zombie';
  SNeutral = 'Neutral';
  SNeutralZombie = 'N-Zombie';
  SRival = 'Rival';
  SInvincible = 'Invincible';
  SBallooner = 'Ballooner';
  SDrifter = 'Drifter';
  //SBatter = 'Batter';  // Batter
  SSleeper = 'Sleeper';

  SRadiator = 'Radiator';
  SSlowfreezer = 'Slowfreezer';

  {-------------------------------------------------------------------------------
    Postview Screen
  -------------------------------------------------------------------------------}
  SYourTimeIsUp = 'Your time is up!';
  STalismanUnlocked = 'You unlocked a new talisman!';
  STalismanAchieved = 'You achieved a talisman!';

  SYouNeeded =  'You needed ';
  SYouRescued = 'You rescued ';
  SYourRecord = 'Your record ';

  SYourTime =       'Save requirement time ';
  SYourTotalTime =  'Total in-game time ';
  SYourTimeRecord = 'Your save time record ';
  SYourFewestSkills = 'Your fewest total skills record ';

  SOptionNextLevel = 'Next level';
  SOptionRetryLevel = 'Retry level';
  SOptionToMenu = 'Exit to menu';
  SOptionContinue = 'Continue';
  SOptionLevelSelect = 'Select level';
  SOptionLoadReplay = 'Load replay';
  SOptionSaveReplay = 'Save replay';

const
  // Needs to match TBasicLemmingAction in LemCore
  LemmingActionStrings: array[TBasicLemmingAction] of string = (
    SDummyString, // 1
    SWalker,      // 2
    SDummyString, // 3
    SAscender,    // 4
    SDigger,      // 5
    SClimber,     // 6
    SDrowner,     // 7
    SHoister,     // 8
    SBuilder,     // 9
    SBasher,      // 10
    SMiner,       // 11
    SFaller,      // 12
    SFloater,     // 13
    SSplatter,    // 14
    SExiter,      // 15
    SVaporizer,   // 16
    SVinetrapper, // 17
    SBlocker,     // 18
    SShrugger,    // 19
    STimebomber,  // 20
    STimebomber,  // 21
    SExploder,    // 22
    SExploder,    // 23
    SDummyString, // 24
    SPlatformer,  // 25
    SStacker,     // 26
    SFreezer,     // 27
    SFreezer,     // 28
    SFreezer,     // 29
    SFreezer,     // 30
    SSwimmer,     // 31
    SGlider,      // 32
    SDisarmer,    // 33
    SCloner,      // 34
    SFencer,      // 35
    SReacher,     // 36
    SShimmier,    // 37
    STurner,      // 38
    SJumper,      // 39
    SDehoister,   // 40
    SSlider,      // 41
    SDangler,     // 42
    SSpearer,     // 43
    SGrenader,    // 44
    SLooker,      // 45
    SLaserer,     // 46
    SBallooner,   // 47
    SLadderer,    // 48
    SDrifter,     // 49
    //SBatter,  // Batter
    SSleeper      // 50
    //SPropeller,   // 47  // Propeller
  );

implementation

end.


