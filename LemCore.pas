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
    baStoning,
    baStoneFinish,
    baSwimming,
    baGliding,
    baFixing,
    baCloning,
    baFencing,
    baReaching,
    baShimmying,
    baJumping,
    baLasering,
    baSpearing,
    baGrenading,
    baDehoisting,
    baSliding
  );

const
  MAX_SKILL_TYPES_PER_LEVEL = 10;

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
    spbStoner,
    spbBlocker,
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
    spbNuke,

    spbFastForward,
    spbRestart,
    spbBackOneFrame,
    spbDirLeft,
    spbClearPhysics,

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
    'stoner',
    'blocker',
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
    'stoners',
    'blockers',
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
    'cloners');

type
  TTriggerTypes = (
    trExit,       // as well for locked exits, once all buttons are pressed
    trForceLeft,  // as well for blockers
    trForceRight, // as well for blockers
    trTrap,       // for triggered and one-time traps
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
    baStoning,
    baSwimming,
    baGliding,
    baFixing,
    baCloning,
    baFencing,
    baShimmying,
    baJumping,
    baLasering,
    baSpearing,
    baGrenading,
    baSliding
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
    spbStoner,
    spbNone,
    spbSwimmer,
    spbGlider,
    spbDisarmer,
    spbCloner,
    spbFencer,
    spbNone,
    spbShimmier,
    spbJumper,
    spbLaserer,
    spbSpearer,
    spbGrenader,
    spbNone,
    spbSlider
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
    baStoning,
    baBlocking,
    baPlatforming,
    baBuilding,
    baStacking,
    baSpearing,
    baGrenading,
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
  ObjectTypeToTrigger: array[-1..33] of TTriggerTypes = (
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
    trZombie,                 // triggered animation - unused
    trZombie,                 // hint
    trNoSplat,                // no-splat
    trSplat,                  // splat
    trTeleport,               // 2-way teleporter - unused
    trTeleport,               // single teleporter - unused
    trZombie,                 // background
    trTrap,                   // once trap
    trZombie,                 // background image - unused
    trOWUp                    // OWW up
  );

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

