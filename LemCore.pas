{$include lem_directives.inc}

unit LemCore;

interface

const
  MINIMUM_SI = 4;
  MAXIMUM_SI = 102;

  clMask32  = $00FF00FF; // Color used for "shape-only" masks

type
  TBasicLemmingAction = (   // Needs to match TBasicLemmingAction in LemStrings
    baNone,            // 1
    baWalking,         // 2
    baZombieWalking,   // 3
    baAscending,       // 4
    baDigging,         // 5
    baClimbing,        // 6
    baDrowning,        // 7
    baHoisting,        // 8
    baBuilding,        // 9
    baBashing,         // 10
    baMining,          // 11
    baFalling,         // 12
    baFloating,        // 13
    baSplatting,       // 14
    baExiting,         // 15
    baVaporizing,      // 16
    baVinetrapping,    // 17
    baBlocking,        // 18
    baShrugging,       // 19
    baTimebombing,     // 20
    baTimebombFinish,  // 21
    baOhnoing,         // 22
    baExploding,       // 23
    baToWalking,       // 24
    baPlatforming,     // 25
    baStacking,        // 26
    baFreezing,        // 27
    baFreezerExplosion,// 28
    baFrozen,          // 29
    baUnfreezing,      // 30
    baSwimming,        // 31
    baGliding,         // 32
    baFixing,          // 33
    baCloning,         // 34
    baFencing,         // 35
    baReaching,        // 36
    baShimmying,       // 37
    baTurning,         // 38
    baJumping,         // 39
    baDehoisting,      // 40
    baSliding,         // 41
    baDangling,        // 42
    baSpearing,        // 43
    baGrenading,       // 44
    baLooking,         // 45
    baLasering,        // 46
    baBallooning,      // 47
    baLaddering,       // 48
    baDrifting,        // 49
    //baPropelling,      // 50
    //baBatting,         // 51
    baSleeping         // 52
  );

const
  MAX_SKILL_TYPES_PER_LEVEL = 14;

type
  TSkillPanelButton = (


    spbWalker,
    spbJumper,
    spbShimmier,
    spbBallooner,
    spbSlider,
    spbClimber,
    spbSwimmer,
    spbFloater,
    spbGlider,
    spbDisarmer,
    spbTimebomber,
    spbBomber,
    spbFreezer,
    spbBlocker,
    spbLadderer,
    spbPlatformer,
    spbBuilder,
    spbStacker,
    spbSpearer,
    spbGrenader,
    spbLaserer,
    spbBasher,
    spbFencer,
    spbMiner,
    spbDigger,
    //spbPropeller,
    //spbBatter,
    spbCloner,

    spbNone,
    spbSlower,
    spbFaster,
    spbPause,
    spbRewind,
    spbFastForward,
    spbRestart,
    spbNuke,
    spbSquiggle
  );

const
  LAST_SKILL_BUTTON = spbCloner;

  SKILL_NAMES: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of String = (
    'walker',
    'jumper',
    'shimmier',
    'ballooner',
    'slider',
    'climber',
    'swimmer',
    'floater',
    'glider',
    'disarmer',
    'timebomber',
    'bomber',
    'freezer',
    'blocker',
    'ladderer',
    'platformer',
    'builder',
    'stacker',
    'spearer',
    'grenader',
    'laserer',
    'basher',
    'fencer',
    'miner',
    'digger',
    //'propeller',
    //'batter',
    'cloner'
    );

  SKILL_PLURAL_NAMES: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of String = (
    'walkers',
    'jumpers',
    'shimmiers',
    'ballooners',
    'sliders',
    'climbers',
    'swimmers',
    'floaters',
    'gliders',
    'disarmers',
    'timebombers',
    'bombers',
    'freezers',
    'blockers',
    'ladderers',
    'platformers',
    'builders',
    'stackers',
    'spearers',
    'grenaders',
    'laserers',
    'bashers',
    'fencers',
    'miners',
    'diggers',
    //'propellers',
    //'batters',
    'cloners'
    );

const
  AssignableSkills = [
    baDigging,
    baClimbing,
    baBuilding,
    baBashing,
    baMining,
    baFloating,
    baBlocking,
    baTimebombing,
    baExploding,
    baToWalking,
    baPlatforming,
    baStacking,
    baFreezing,
    baSwimming,
    baGliding,
    baFixing,
    baCloning,
    baFencing,
    baShimmying,
    baJumping,
    baSliding,
    baSpearing,
    baGrenading,
    baLasering,
    baBallooning,
    //baPropelling,
    //baBatting,
    baLaddering
  ];

const
  ActionToSkillPanelButton: array[TBasicLemmingAction] of TSkillPanelButton = (
    spbNone,        // 1   baNone
    spbWalker,      // 2   baWalking
    spbNone,        // 3   baZombieWalking
    spbNone,        // 4   baAscending
    spbDigger,      // 5   baDigging
    spbClimber,     // 6   baClimbing
    spbNone,        // 7   baHoisting
    spbNone,        // 8   baDrowning
    spbBuilder,     // 9   baBricklaying
    spbBasher,      // 10  baBashing
    spbMiner,       // 11  baMining
    spbNone,        // 12  baFalling
    spbFloater,     // 13  baUmbrella
    spbNone,        // 14  baSplatting
    spbNone,        // 15  baExiting
    spbNone,        // 16  baVaporizing
    spbNone,        // 17  baVinetrapping
    spbBlocker,     // 18  baBlocking
    spbNone,        // 19  baShrugging
    spbTimebomber,  // 20  baTimebombing
    spbNone,        // 21  baTimebombFinish
    spbNone,        // 22  baOhNoing
    spbBomber,      // 23  baExploding
    spbWalker,      // 24  baToWalking
    spbPlatformer,  // 25  baPlatforming
    spbStacker,     // 26  baStacking
    spbFreezer,     // 27  baFreezing
    spbNone,        // 28  baFreezerExplosion
    spbNone,        // 29  baFrozen
    spbNone,        // 30  baUnfreezing
    spbSwimmer,     // 31  baSwimming
    spbGlider,      // 32  baGliding
    spbDisarmer,    // 33  baFixing
    spbCloner,      // 34  baCloning
    spbFencer,      // 35  baFencing
    spbNone,        // 36  baReaching
    spbShimmier,    // 37  baShimmying
    spbNone,        // 38  baTurning
    spbJumper,      // 39  baJumping
    spbNone,        // 40  baDehoisting
    spbSlider,      // 41  baGliding
    spbNone,        // 42  baDangling
    spbSpearer,     // 43  baSpearing
    spbGrenader,    // 44  baGrenading
    spbNone,        // 45  baLooking
    spbLaserer,     // 46  baLasering
    spbBallooner,   // 47  baBallooning
    spbLadderer,    // 48  baLaddering
    spbNone,        // 49  baDrifting
    //spbPropeller,   // 50  baPropelling
    //spbBatter,      // 51  baBatting
    spbNone         // 52  baSleeping
  );

const
  SkillPanelButtonToAction: array[TSkillPanelButton] of TBasicLemmingAction = (

    // This needs to match the order of the skill on the panel
    baToWalking,    // 1
    baJumping,      // 2
    baShimmying,    // 3
    baBallooning,   // 4
    baSliding,      // 5
    baClimbing,     // 6
    baSwimming,     // 7
    baFloating,     // 8
    baGliding,      // 9
    baFixing,       // 10
    baTimebombing,  // 11
    baExploding,    // 12
    baFreezing,     // 13
    baBlocking,     // 14
    baLaddering,    // 15
    baPlatforming,  // 16
    baBuilding,     // 17
    baStacking,     // 18
    baSpearing,     // 19
    baGrenading,    // 20
    baLasering,     // 21
    baBashing,      // 22
    baFencing,      // 23
    baMining,       // 24
    baDigging,      // 25
    //baPropelling,   // 26
    //baBatting,      // 27
    baCloning,      // 28
    baNone, // Null
    baNone, // RR-
    baNone, // RR+
    baNone, // Pause
    baNone, // Rewind
    baNone, // FF
    baNone, // Restart
    baNone, // Nuke
    baNone  // Squiggle
  );

type
  TTriggerTypes = (
    trNone,
    trExit,
    trButton,
    trForceLeft,
    trForceRight,
    trTrap,
    trAnim,
    trWater,
    trBlasticine,
    trVinewater,
    trPoison,
    trLava,
    trFire,
    trOWLeft,
    trOWRight,
    trOWUp,
    trOWDown,
    trBlocker,
    trSteel,
    trTeleport,
    trPortal,
    trPickup,
    trCollectible,
    trUpdraft,
    trSplitter,
    trRadiation,
    trSlowfreeze,
    trNoSplat,
    trSplat,
    trNormalizer,
    trSkillAssigner,
    trZombie
  );

const
  ObjectTypeToTrigger: array[-1..37] of TTriggerTypes = (
    trNone,                   // -1 DOM_NOOBJECT
    trNone,                   //  0 DOM_NONE
    trNone,                   //  1 DOM_WINDOW
    trExit,                   //  2 DOM_EXIT
    trExit,                   //  3 DOM_LOCKEXIT
    trButton,                 //  4 DOM_BUTTON
    trNone,                   //  5 DOM_BLOCKER
    trForceLeft,              //  6 DOM_FORCELEFT
    trForceRight,             //  7 DOM_FORCERIGHT
    trTrap,                   //  8 DOM_TRAP
    trTrap,                   //  9 DOM_TRAPONCE
    trWater,                  // 10 DOM_WATER
    trBlasticine,             // 11 DOM_BLASTICINE
    trVinewater,              // 12 DOM_VINEWATER
    trPoison,                 // 13 DOM_POISON
    trLava,                   // 14 DOM_LAVA
    trFire,                   // 15 DOM_FIRE
    trOWLeft,                 // 16 DOM_ONEWAYLEFT
    trOWRight,                // 17 DOM_ONEWAYRIGHT
    trOWUp,                   // 18 DOM_ONEWAYUP
    trOWDown,                 // 19 DOM_ONEWAYDOWN
    trTeleport,               // 20 DOM_TELEPORT
    trNone,                   // 21 DOM_RECEIVER
    trPortal,                 // 22 DOM_PORTAL
    trPickup,                 // 23 DOM_PICKUP
    trCollectible,            // 24 DOM_COLLECTIBLE
    trUpdraft,                // 25 DOM_UPDRAFT
    trSplitter,               // 26 DOM_SPLITTER
    trRadiation,              // 27 DOM_RADIATION
    trSlowfreeze,             // 28 DOM_SLOWFREEZE
    trNoSplat,                // 29 DOM_NOSPLAT
    trSplat,                  // 30 DOM_SPLAT
    trNormalizer,             // 31 DOM_NORMALIZER
    trSkillAssigner,          // 32 DOM_SKILLASSIGNER
    trNone,                   // 33 DOM_DECORATION
    trAnim,                   // 34 DOM_ANIMATION
    trAnim,                   // 35 DOM_ANIMONCE
    trSteel,                  // 36 DOM_STEEL
    trNone                    // 37 DOM_LEMMING
  );

type
  TRecordDisplay = (rdNone, rdUser, rdWorld, rdCollectibles);

  function ReleaseRateToSpawnInterval(aRR: Integer): Integer;
  function SpawnIntervalToReleaseRate(aSI: Integer): Integer;

implementation

function ReleaseRateToSpawnInterval(aRR: Integer): Integer;
begin
  Result := 103 - aRR;
end;

function SpawnIntervalToReleaseRate(aSI: Integer): Integer;
begin
  Result := 103 - aSI;
end;

end.

