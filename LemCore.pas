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
    //baBatting,       // Batter
    baSleeping         // 50
    //baPropelling,      // // Propeller
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
    //spbPropeller,  // Propeller
    spbLaserer,
    spbBasher,
    spbFencer,
    spbMiner,
    spbDigger,
    //spbBatter, // Batter
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
    //'propeller',  // Propeller
    'laserer',
    'basher',
    'fencer',
    'miner',
    'digger',
    //'batter',  // Batter
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
    //'propellers', // Propeller
    'laserers',
    'bashers',
    'fencers',
    'miners',
    'diggers',
    //'batters', // Batter
    'cloners'
    );

type
  TTriggerTypes = (
    trExit,       // As well for locked exits, once all buttons are pressed
    trButton,
    trForceLeft,  // As well for blockers
    trForceRight, // As well for blockers
    trTrap,       // For triggered and one-time traps
    trAnim,       // Ditto for triggered animations
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
    trBlocker,    // Total blocker area!
    trSteel,
    trTeleport,
    trPickup,
    trCollectible,
    trUpdraft,
    trSplitter,
    trRadiation,
    trSlowfreeze,
    trNoSplat,
    trSplat,
    trZombie
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
    //baPropelling, // Propeller
    baBallooning,
    //baBatting, // Batter
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
    //spbBatter,    // Batter
    spbNone         // 50  baSleeping

    //spbPropeller,   // 47  baPropelling // Propeller
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
    //baBatting,    // Batter
    baCloning,      // 26
    //baPropelling,   // 21 // Propeller
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
  // All objects that don't have trigger areas get mapped to trZombie
  // This only works as long as there are no object types that create Zombie fields!!!
  ObjectTypeToTrigger: array[-1..35] of TTriggerTypes = (
    trZombie,                 // -1 No-object
    trZombie,                 // 0  No trigger area
    trZombie,                 // 1  Hatch
    trExit,                   // 2  Exit
    trExit,                   // 3  Locked exit
    trButton,                 // 4  Button
    trForceLeft,              // 5  Force-field left
    trForceRight,             // 6  Force-field right
    trTrap,                   // 7  Triggered trap
    trTrap,                   // 8  Once trap
    trWater,                  // 9  Water
    trBlasticine,             // 10 Blasticine
    trVinewater,              // 11 Vinewater
    trPoison,                 // 12 Poison
    trLava,                   // 13 Lava
    trFire,                   // 14 Triggers burner
    trOWLeft,                 // 15 OWW left
    trOWRight,                // 16 OWW right
    trOWDown,                 // 17 OWW down
    trOWUp,                   // 18 OWW up
    trZombie,                 // 19 Blocker (note - there is no blocker object!)
    trTeleport,               // 20 Teleporter
    trZombie,                 // 21 Receiver
    trPickup,                 // 22 Pickup skill
    trCollectible,            // 23 Collectible
    trUpdraft,                // 24 Updraft
    trSplitter,               // 25 Splitter
    trRadiation,              // 26 Radiation
    trSlowfreeze,             // 27 Slowfreeze
    trNoSplat,                // 28 No-splat
    trSplat,                  // 29 Splat
    trZombie,                 // 30 Decoration
    trAnim,                   // 31 Triggered animation
    trAnim,                   // 32 Once animation
    trSteel,                  // 33 Steel
    trZombie                  // 34 Preplaced lemming
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

