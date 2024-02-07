{$include lem_directives.inc}

unit LemStrings;

interface

uses
  LemCore;

const
  // Important paths
  SFGraphics = 'gfx\';
    SFGraphicsGame = SFGraphics + 'game\';
    SFGraphicsHelpers = SFGraphics + 'helpers\';
    SFGraphicsHelpersHighRes = SFGraphics + 'helpers-hr\';
    SFGraphicsMasks = SFGraphics + 'mask\';
    SFGraphicsMenu = SFGraphics + 'menu\';
    SFGraphicsPanel = SFGraphics + 'panel\';
    SFGraphicsPanelHighRes = SFGraphics + 'panel-hr\';

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
      SFTheme = 'theme.nxtm';

  SFLevels = 'levels\';

  SFSounds = 'sound\';
  SFMusic = 'music\';

  SFData = 'data\';
      SFDataTranslation = SFData + 'translation\';

  SFSaveData = 'settings\';

  SFTemp = 'temp\';

  // Sound effect files
  SFX_BUILDER_WARNING = 'ting';
  SFX_ASSIGN_SKILL = 'mousepre';
  SFX_ASSIGN_FAIL = 'assignfail';
  SFX_YIPPEE = 'yippee';
  SFX_OING = 'oing';
  SFX_SPLAT = 'splat';
  SFX_LETSGO = 'letsgo';
  SFX_ENTRANCE = 'door';
  SFX_EXIT_OPEN = 'exitopen';
  SFX_VAPORIZING = 'fire';
  SFX_FREEZING = 'ice';
  SFX_VINETRAPPING = 'weedgulp';
  SFX_DROWNING = 'glug';
  SFX_EXPLOSION = 'explode';
  SFX_HITS_STEEL = 'chink';
  SFX_OHNO = 'ohno';
  SFX_SKILLBUTTON = 'changeop';
  SFX_CHANGE_RR = 'changerr';
  SFX_PICKUP = 'oing2';
  SFX_SWIMMING = 'splash';
  SFX_FALLOUT = 'die';
  SFX_FIXING = 'wrench';
  SFX_ZOMBIE = 'zombie';
  SFX_ZOMBIE_OHNO = 'zombieohno';
  SFX_ZOMBIE_DIE = 'zombiedie';
  SFX_ZOMBIE_SPLAT = 'zombiesplat';
  SFX_ZOMBIE_PICKUP = 'zombiepickup';
  SFX_ZOMBIE_LAUGH = 'zombielaugh';
  SFX_ZOMBIE_LOLZ = 'zombielolz';
  SFX_ZOMBIE_EXIT = 'zombieyippee';
  SFX_TIMEUP = 'timeup';
  SFX_SPEAR_THROW = 'throw';
  SFX_GRENADE_THROW = 'grenade';
  SFX_SPEAR_HIT = 'spearhit';
  SFX_LASER = 'laser';
  SFX_BALLOON_INFLATE = 'balloon';
  SFX_BALLOON_POP = 'balloonpop';
  SFX_JUMP = 'jump';
  SFX_BYE = 'bye';
  SFX_OK = 'OK';

resourcestring
  SProgramName = 'SuperLemmix Player';
  SDummyString = '';



  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  //SPreviewLemmings = ' Lemmings'; // Bookmark - not currently used - remove?
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
  SExploder = 'Bomber';
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
  SJumper = 'Jumper';
  SDehoister = 'Dehoister';
  SSlider = 'Slider';
  SDangler = 'Dangler';
  SSpearer = 'Spearer';
  SGrenader = 'Grenader';
  SLooker = 'Looker';
  SLaserer = 'Laserer';
  SZombie = 'Zombie';
  SNeutral = 'Neutral';
  SNeutralZombie = 'N-Zombie';
  SBallooner = 'Ballooner';
  SDrifter = 'Drifter';
  SSleeper = 'Sleeper';


  {-------------------------------------------------------------------------------
    Postview Screen
  -------------------------------------------------------------------------------}
  SYourTimeIsUp =
    'Your time is up!';

  //SAllLemmingsAccountedFor =
    //'All lemmings accounted for.'; // Bookmark - not currently used - remove?

  STalismanUnlocked =
    'You unlocked a talisman!';

  SYouRescued = 'You rescued ';
  SYouNeeded =  'You needed  ';
  SYourRecord = 'Your record ';

  SYourTime =       'Your time taken is  ';
  SYourTimeRecord = 'Your record time is ';
  SYourFewestSkills = 'Your fewest total skills is ';

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
    SJumper,      // 38
    SDehoister,   // 39
    SSlider,      // 40
    SDangler,     // 41
    SSpearer,     // 42
    SGrenader,    // 43
    SLooker,      // 44
    SLaserer,     // 45
    SBallooner,   // 46
    SLadderer,    // 47
    SDrifter,     // 48
    SSleeper      // 49
  );

implementation

end.


