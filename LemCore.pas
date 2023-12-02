{$include lem_directives.inc}

unit LemCore;

interface

const
  MINIMUM_SI = 4;
  MAXIMUM_SI = 102;

(*
  { TODO : find good settings }
    we cannot get a nice minimapscale 1/16 so instead we chose the following:

    image width of game                 = 1584
    imagewidth of minimap               = 104
    width of white rectangle in minimap = 25





//  GAME_BMPWIDTH = 1664; // This is too far I think, but now it fits with the minimap!

  { the original dos lemmings show pixels 0 through 1583 (so including pixel 1583)
    so the imagewidth should be 1584, which means 80 pixels less then 1664


  MiniMapBounds: TRect = (
    Left: 208;   // Width =about 100
    Top: 18;
    Right: 311;  // Height =about 20
    Bottom: 37
  );
  *)





  clMask32  = $00FF00FF; // Color used for "shape-only" masks

{•}

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
    baJumping,         // 38
    baDehoisting,      // 39
    baSliding,         // 40
    baDangling,        // 41
    baSpearing,        // 42
    baGrenading,       // 43
    baLooking,         // 44
    baLasering,        // 45
    baBallooning,      // 46
    baLaddering,       // 47
    baDrifting,        // 48
    baSleeping         // 49
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
    'cloners'
    );

type
  TTriggerTypes = (
    trExit,       // As well for locked exits, once all buttons are pressed
    trForceLeft,  // As well for blockers
    trForceRight, // As well for blockers
    trTrap,       // For triggered and one-time traps
    trAnim,       // Ditto for triggered animations
    trWater,
    trFire,
    trOWLeft,
    trOWRight,
    trOWDown,
    trOWUp,
    trSteel,
    trBlocker,    // Total blocker area!
    trTeleport,
    trPickup,
    trButton,
    trUpdraft,
    trFlipper,
    trNoSplat,
    trSplat,
    trZombie,
    trBlasticine,
    trVinewater,
    trPoison,
    trRadiation,
    trSlowfreeze
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
    spbJumper,      // 38  baJumping
    spbNone,        // 39  baDehoisting
    spbSlider,      // 40  baGliding
    spbNone,        // 41  baDangling
    spbSpearer,     // 42  baSpearing
    spbGrenader,    // 43  baGrenading
    spbNone,        // 44  baLooking
    spbLaserer,     // 45  baLasering
    spbBallooner,   // 46  baBallooning
    spbLadderer,    // 47  baLaddering
    spbNone,        // 48  baDrifting
    spbNone         // 49  baSleeping
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
    baCloning,      // 26
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

const
  // All objects that don't have trigger areas got mapped to trZombie
  // This only works as long as there are no object types that create Zombie fields!!!
  ObjectTypeToTrigger: array[-1..38] of TTriggerTypes = (
    trZombie,                 // No-object
    trZombie,                 // No trigger area
    trExit,                   // Exit
    trForceLeft,              // Force-field left
    trForceRight,             // Force-field right
    trTrap,                   // Triggered trap
    trWater,                  // Water
    trFire,                   // Continuous trap
    trOWLeft,                 // OWW left
    trOWRight,                // OWW right
    trSteel,                  // Steel
    trZombie,                 // Blocker (there is no blocker OBJECT!!)
    trTeleport,               // Teleporter
    trZombie,                 // Receiver
    trZombie,                 // Preplaced lemming
    trPickup,                 // Pickup skill
    trExit,                   // Locked exit
    trZombie,                 // Sketch item
    trButton,                 // Button
    trRadiation,              // Radiation
    trOWDown,                 // OWW down
    trUpdraft,                // Updraft
    trFlipper,                // Flipper
    trSlowfreeze,             // Slowfreeze
    trZombie,                 // Hatch
    trAnim,                   // Triggered animation
    trZombie,                 // Hint // Bookmark - is this used?
    trNoSplat,                // No-splat
    trSplat,                  // Splat
    trTeleport,               // 2-way teleporter - unused // Bookmark - can this be removed?
    trTeleport,               // Single teleporter - unused // Bookmark - can this be removed?
    trZombie,                 // Background
    trTrap,                   // Once trap
    trZombie,                 // Background image - unused
    trOWUp,                   // OWW up
    trZombie,                 // Paint // Bookmark - is this used?
    trAnim,                   // Once animation
    trBlasticine,             // Lems become instabombers on contact
    trVinewater,              // Triggers vinetrapper instead of drowner
    trPoison                  // Turns lems into zombies
  );

type
  TRecordDisplay = (rdNone, rdUser, rdWorld);

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

