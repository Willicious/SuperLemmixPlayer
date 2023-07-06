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
    //SFVisualSFX = SFGraphics + 'visualsfx\';
    //SFVisualSFXHighRes = SFGraphics + 'visualsfx-hr\';

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
      SFPiecesGrenades = '\grenades\';
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
  SFX_ZOMBIE_DIE = 'zombiedie';
  SFX_TIMEUP = 'timeup';
  SFX_SPEAR_HIT = 'spearhit';
  SFX_LASER = 'laser';

resourcestring
  SProgramName = 'SuperLemmix Player';
  SDummyString = '';



  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  //SPreviewLemmings = ' Lemmings'; //not currently used
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
  SSleeper = 'Sleeper';


  {-------------------------------------------------------------------------------
    Postview Screen
  -------------------------------------------------------------------------------}
  SYourTimeIsUp =
    'Your time is up!';

  //SAllLemmingsAccountedFor =
    //'All lemmings accounted for.'; //not currently used

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
  LemmingActionStrings: array[TBasicLemmingAction] of string = (    //needs to match TBasicLemmingAction in LemCore
    SDummyString, //1
    SWalker,      //2
    SAscender,    //3
    SDigger,      //4
    SClimber,     //5
    SDrowner,     //6
    SHoister,     //7
    SBuilder,     //8
    SBasher,      //9
    SMiner,       //10
    SFaller,      //11
    SFloater,     //12
    SSplatter,    //13
    SExiter,      //14
    SVaporizer,   //15
    SVinetrapper, //16
    SBlocker,     //17
    SShrugger,    //18
    STimebomber,  //19
    STimebomber,  //20
    SExploder,    //21
    SExploder,    //22
    SDummyString, //23
    SPlatformer,  //24
    SStacker,     //25
    SFreezer,     //26
    SFreezer,     //27
    SFreezer,     //28
    SFreezer,     //29
    SSwimmer,     //30
    SGlider,      //31
    SDisarmer,    //32
    SCloner,      //33
    SFencer,      //34
    SReacher,     //35
    SShimmier,    //36
    SJumper,      //37
    SDehoister,   //38
    SSlider,      //39
    SDangler,     //40
    SSpearer,     //41
    SGrenader,    //42
    SLooker,      //43
    SLaserer,     //44
    SSleeper      //45
  );

implementation

end.


