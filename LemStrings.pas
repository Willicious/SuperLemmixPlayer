{$include lem_directives.inc}

unit LemStrings;

interface

uses
  UMisc, SysUtils, LemCore;

  function NumericalVersionToStringVersion(Main, Sub, Minor: Integer): String;

const
  // Important paths
  SFGraphics = 'gfx\';
    SFGraphicsHelpers = SFGraphics + 'helpers\';
    SFGraphicsMasks = SFGraphics + 'mask\';
    SFGraphicsMenu = SFGraphics + 'menu\';
    SFGraphicsPanel = SFGraphics + 'panel\';

  SFStyles = 'styles\';
      SFDefaultStyle = 'default';
      SFPiecesTerrain = '\terrain\';
      SFPiecesObjects = '\objects\';
      SFPiecesBackgrounds = '\backgrounds\';
      SFPiecesLemmings = '\lemmings\';
      SFPiecesPanel = '\panel\';
      SFTheme = 'theme.nxtm';

  SFLevels = 'levels\';

  SFSounds = 'sound\';
  SFMusic = 'music\';

  SFData = 'data\';
      SFDataTranslation = SFData + 'translation\';

  SFSaveData = 'save\';

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

resourcestring
  SProgramName = 'NeoLemmix Player';
  SDummyString = '';


  SProgramText = 'Built on NeoLemmix Engine';
  SCredits = '';

  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  SPreviewString =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Saved'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13#13 +
    '     Press mouse button to continue';

  SPreviewStringAuth =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Saved'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13 +
    '          Author: %s'                   + #13#13 +
    '     Press mouse button to continue';


  {-------------------------------------------------------------------------------
    Game Screen Info Panel
  -------------------------------------------------------------------------------}
  SSkillPanelTemplate =
    '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' ' + #94 + '_...' + ' ' + #95 +  '_.-..';

  SAthlete = 'Athlete';
  STriathlete = 'Triathlete';
  SQuadathlete = 'X-Athlete';

  SWalker = 'Walker';

  SJumper = 'Jumper';

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

  SMechanic = 'Disarmer';

  SCloner = 'Cloner';

  SFencer = 'Fencer';

  SZombie = 'Zombie';

  SGhost = 'Ghost';

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
    SJumper,
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
    SMechanic,
    SCloner,
    SFencer
  );

implementation

function NumericalVersionToStringVersion(Main, Sub, Minor: Integer): String;
begin
  Result := IntToStr(Main) + '.' + LeadZeroStr(Sub, 2) + 'n';
  if Minor > 1 then
    Result := Result + '-' + Chr(Minor + 64);
end;

end.


