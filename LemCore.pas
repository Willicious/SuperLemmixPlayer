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





//  GAME_BMPWIDTH = 1664; // this is too far I think, but now it fits with the minimap!

  { the original dos lemmings show pixels 0 through 1583 (so including pixel 1583)
    so the imagewidth should be 1584, which means 80 pixels less then 1664


  MiniMapBounds: TRect = (
    Left: 208;   // width =about 100
    Top: 18;
    Right: 311;  // height =about 20
    Bottom: 37
  );
  *)





  clMask32  = $00FF00FF; // color used for "shape-only" masks

{•}

type
  TBasicLemmingAction = (
    baNone,
    baWalking,
    baAscending,
    baDigging,
    baClimbing,
    baDrowning,
    baHoisting,
    baBuilding,
    baBashing,
    baMining,
    baFalling,
    baFloating,
    baSplatting,
    baExiting,
    baVaporizing,
    baBlocking,
    baShrugging,
    baOhnoing,
    baExploding,
    baToWalking,
    baPlatforming,
    baStacking,
    baFreezing,
    baFreezeFinish,
    baSwimming,
    baGliding,
    baFixing,
    baCloning,
    baFencing,
    baReaching,
    baShimmying,
    baJumping,
    baDehoisting,
    baSliding,
    baLasering
  );

const
  MAX_SKILL_TYPES_PER_LEVEL = 16;

type
  TSkillPanelButton = (


    spbWalker,
    spbJumper,
    spbShimmier,
    spbSlider,
    spbClimber,
    spbSwimmer,
    spbFloater,
    spbGlider,
    spbDisarmer,
    spbBomber,
    spbFreezer,
    spbBlocker,
    spbPlatformer,
    spbBuilder,
    spbStacker,
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
    spbNuke,

    spbFastForward,
    spbRestart,
    spbBackOneFrame,
    spbDirLeft,
    spbClearPhysics,
    spbSquiggle,

    // These three are the bottom part of a vertical split
    spbForwardOneFrame,
    spbDirRight,
    spbLoadReplay
  );

const
  LAST_SKILL_BUTTON = spbCloner;

  SKILL_NAMES: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of String = (
    'walker',
    'jumper',
    'shimmier',
    'slider',
    'climber',
    'swimmer',
    'floater',
    'glider',
    'disarmer',
    'bomber',
    'freezer',
    'blocker',
    'platformer',
    'builder',
    'stacker',
    'laserer',
    'basher',
    'fencer',
    'miner',
    'digger',
    'cloner');

  SKILL_PLURAL_NAMES: array[Low(TSkillPanelButton)..LAST_SKILL_BUTTON] of String = (
    'walkers',
    'jumpers',
    'shimmiers',
    'sliders',
    'climbers',
    'swimmers',
    'floaters',
    'gliders',
    'disarmers',
    'bombers',
    'freezers',
    'blockers',
    'platformers',
    'builders',
    'stackers',
    'laserers',
    'bashers',
    'fencers',
    'miners',
    'diggers',
    'cloners');

type
  TTriggerTypes = (
    trExit,       // as well for locked exits, once all buttons are pressed
    trForceLeft,  // as well for blockers
    trForceRight, // as well for blockers
    trTrap,       // for triggered and one-time traps
    trAnim,       // ditto for triggered animations
    trWater,
    trFire,
    trOWLeft,
    trOWRight,
    trOWDown,
    trOWUp,
    trSteel,
    trBlocker,    // total blocker area!
    trTeleport,
    trPickup,
    trButton,
    trUpdraft,
    trFlipper,
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
    baLasering
  ];

const
  ActionToSkillPanelButton: array[TBasicLemmingAction] of TSkillPanelButton = (
    spbNone,
    spbWalker,
    spbNone,
    spbDigger,
    spbClimber,
    spbNone,
    spbNone,
    spbBuilder,
    spbBasher,
    spbMiner,
    spbNone,
    spbFloater,
    spbNone,
    spbNone,
    spbNone,
    spbBlocker,
    spbNone,
    spbNone,
    spbBomber,
    spbWalker,
    spbPlatformer,
    spbStacker,
    spbFreezer,
    spbNone,
    spbSwimmer,
    spbGlider,
    spbDisarmer,
    spbCloner,
    spbFencer,
    spbNone,
    spbShimmier,
    spbJumper,
    spbNone,
    spbSlider,
    spbLaserer
  );

const
  SkillPanelButtonToAction: array[TSkillPanelButton] of TBasicLemmingAction = (

    baToWalking,
    baJumping,
    baShimmying,
    baSliding,
    baClimbing,
    baSwimming,
    baFloating,
    baGliding,
    baFixing,
    baExploding,
    baFreezing,
    baBlocking,
    baPlatforming,
    baBuilding,
    baStacking,
    baLasering,
    baBashing,
    baFencing,
    baMining,
    baDigging,
    baCloning,
    baNone, //Null
    baNone, //RR-
    baNone, //RR+
    baNone, //Pause
    baNone,  //Nuke
    baNone,  // FF
    baNone,  // Restart
    baNone,  // Squiggle
    baNone,  // -1f
    baNone,  // +1f
    baNone,  // Clear Physics
    baNone,  // Dir Sel Left
    baNone,  // Load Replay
    baNone   // Dir Sel Right
  );

const
  // All objects that don't have trigger areas got mapped to trZombie
  // This only works as long as there are no object types that create Zombie fields!!!
  ObjectTypeToTrigger: array[-1..35] of TTriggerTypes = (
    trZombie,                 // no-object
    trZombie,                 // no trigger area
    trExit,                   // exit
    trForceLeft,              // force-field left
    trForceRight,             // force-field right
    trTrap,                   // triggered trap
    trWater,                  // water
    trFire,                   // continuous trap
    trOWLeft,                 // OWW left
    trOWRight,                // OWW right
    trSteel,                  // steel
    trZombie,                 // blocker (there is no blocker OBJECT!!)
    trTeleport,               // teleporter
    trZombie,                 // receiver
    trZombie,                 // preplaced lemming
    trPickup,                 // pickup skill
    trExit,                   // locked exit
    trZombie,                 // sketch item
    trButton,                 // button
    trZombie,                 // radiation - unused
    trOWDown,                 // OWW down
    trUpdraft,                // updraft
    trFlipper,                // flipper
    trZombie,                 // slowfreeze - unused
    trZombie,                 // hatch
    trAnim,                   // triggered animation
    trZombie,                 // hint
    trNoSplat,                // no-splat
    trSplat,                  // splat
    trTeleport,               // 2-way teleporter - unused
    trTeleport,               // single teleporter - unused
    trZombie,                 // background
    trTrap,                   // once trap
    trZombie,                 // background image - unused
    trOWUp,                   // OWW up
    trZombie,                 // paint
    trAnim                    // once animation
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

