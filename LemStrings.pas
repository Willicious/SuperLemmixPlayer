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
      SFTheme = 'theme.nxtm';

  SFLevels = 'levels\';

  SFSounds = 'sound\';
  SFMusic = 'music\';

  SFData = 'data\';
      SFDataTranslation = SFData + 'translation\';

  SFSaveData = 'settings\';

  // Sound effect files
  SFX_BUILDER_WARNING = 'ting';
  SFX_ASSIGN_SKILL = 'mousepre';
  SFX_YIPPEE = 'yippee';
  SFX_SPLAT = 'splat';
  SFX_LETSGO = 'letsgo';
  SFX_ENTRANCE = 'door';
  SFX_VAPORIZING = 'fire';
  SFX_DROWNING = 'glug';
  SFX_EXPLOSION = 'explode';
  SFX_HITS_STEEL = 'chink';
  SFX_OHNO = 'ohno';
  SFX_SKILLBUTTON = 'changeop';
  SFX_PICKUP = 'oing2';
  SFX_SWIMMING = 'splash';
  SFX_FALLOUT = 'die';
  SFX_FIXING = 'wrench';
  SFX_ZOMBIE = 'zombie';
  SFX_TIMEUP = 'timeup';

resourcestring
  SProgramName = 'NeoLemmix Player';
  SDummyString = '';



  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  SPreviewLemmings = ' Lemmings';
  SPreviewSave = ' To Be Saved';
  SPreviewReleaseRate = 'Release Rate ';
  SPreviewSpawnInterval = 'Spawn Interval ';
  SPreviewRRLocked = '  (Locked)';
  SPreviewTimeLimit = 'Time Limit ';
  SPreviewGroup = 'Group: ';
  SPreviewAuthor = 'Author: ';

  {-------------------------------------------------------------------------------
    Game Screen Info Panel
  -------------------------------------------------------------------------------}

  SAthlete = 'Athlete';
  STriathlete = 'Triathlete';
  SQuadathlete = 'X-Athlete';

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
  SVaporizer = 'Frier';
  SBlocker = 'Blocker';
  SShrugger = 'Shrugger';
  SOhnoer = 'Ohnoer';
  SExploder = 'Bomber';
  SPlatformer = 'Platformer';
  SStacker = 'Stacker';
  SStoner = 'Stoner';
  SSwimmer = 'Swimmer';
  SGlider = 'Glider';
  SDisarmer = 'Disarmer';
  SCloner = 'Cloner';
  SFencer = 'Fencer';
  SReacher = 'Reacher';
  SShimmier = 'Shimmier';
  SJumper = 'Jumper';
  SZombie = 'Zombie';
  SNeutral = 'Neutral';
  SNeutralZombie = 'N-Zombie';


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

  SPressLeftMouseForNextLevel =
    'Press left mouse button for next level';

  SPressLeftMouseToRetryLevel =
    'Press left mouse button to retry level';

  SPressMiddleMouseToReplayLevel =
    'Press middle mouse button to replay';

  SPressRightMouseForMenu =
    'Press right mouse button for menu';

  SPressMouseToContinue =
    'Press mouse button to continue';

const
  LemmingActionStrings: array[TBasicLemmingAction] of string = (
    SDummyString,
    SWalker,
    SAscender,
    SDigger,
    SClimber,
    SDrowner,
    SHoister,
    SBuilder,
    SBasher,
    SMiner,
    SFaller,
    SFloater,
    SSplatter,
    SExiter,
    SVaporizer,
    SBlocker,
    SShrugger,
    SOhnoer,
    SExploder,
    SDummyString,
    SPlatformer,
    SStacker,
    SStoner,
    SStoner,
    SSwimmer,
    SGlider,
    SDisarmer,
    SCloner,
    SFencer,
    SReacher,
    SShimmier,
    SJumper
  );

implementation

end.


