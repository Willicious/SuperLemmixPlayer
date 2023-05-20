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
    SFVisualSFX = SFGraphics + 'visualsfx\';
    SFVisualSFXHighRes = SFGraphics + 'visualsfx-hr\';

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
  SFX_YIPPEE = 'yippee';
  SFX_OING = 'oing';
  SFX_SPLAT = 'splat';
  SFX_LETSGO = 'letsgo';
  SFX_ENTRANCE = 'door';
  SFX_EXIT_OPEN = 'exitopen';
  SFX_VAPORIZING = 'fire';
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
  SFX_TIMEUP = 'timeup';

resourcestring
  SProgramName = 'SuperLemmix Player';
  SDummyString = '';



  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  SPreviewLemmings = ' Lemmings';
  SPreviewSave = ' To Be Saved';
  SPreviewReleaseRate = 'Release Rate ';
  SPreviewSpawnInterval = 'Spawn Interval ';
  SPreviewRRLocked = ' (Locked)';
  SPreviewTimeLimit = 'Time Limit ';
  SPreviewGroup = 'Group: ';
  SPreviewAuthor = 'Author: ';

  {-------------------------------------------------------------------------------
    Game Screen Info Panel
  -------------------------------------------------------------------------------}

  SAthlete = 'Athlete';
  STriathlete = 'Triathlete';
  SQuadathlete = 'X-Athlete';
  SQuintathlete = 'Jock';

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

  SAllLemmingsAccountedFor =
    'All lemmings accounted for.';

  STalismanUnlocked =
    'You unlocked a talisman!';

  SYouRescued = 'You rescued ';
  SYouNeeded =  'You needed  ';
  SYourRecord = 'Your record ';

  SYourTime =       'Your time taken is  ';
  SYourTimeRecord = 'Your record time is ';

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
    SSwimmer,     //28
    SGlider,      //29
    SDisarmer,    //30
    SCloner,      //31
    SFencer,      //32
    SReacher,     //33
    SShimmier,    //34
    SJumper,      //35
    SDehoister,   //36
    SSlider,      //37
    SDangler,     //38
    SSpearer,     //39
    SGrenader,    //40
    SLooker,      //41
    SLaserer,     //42
    SSleeper      //43
  );

implementation

end.


