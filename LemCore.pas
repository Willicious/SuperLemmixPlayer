{$include lem_directives.inc}

unit LemCore;

interface

const
  GAME_BMPWIDTH = 1584;

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

{�}

type
  TBasicLemmingAction = (
    baNone,
    baWalking,
    baJumping,
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
    baFencing
  );

  {TSkillPanelButton = (
    spbNone,
    spbSlower,
    spbFaster,
    spbClimber,
    spbFloater,
    spbBomber,
    spbBlocker,
    spbBuilder,
    spbBasher,
    spbMiner,
    spbDigger,
    spbPause,
    spbNuke,
    spbWalker
  );}

  TSkillPanelButton = (


    spbWalker,
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
    spbForwardOneFrame,
    spbClearPhysics,
    spbDirLeft,
    spbLoadReplay,
    spbDirRight  // because of special handling to draw it, it's not immediately after spbDirLeft in the list
  );

const
  LAST_SKILL_BUTTON = spbCloner;

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
    trSteel,
    trBlocker,    // total blocker area!
    trTeleport,
    trPickup,
    trButton,
    trRadiation,
    trSlowfreeze,
    trUpdraft,
    trFlipper,
    trSplat,
    trNoSplat,
    trZombie,
    trAnimation
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
    baFencing
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
    spbFencer
  );

const
  SkillPanelButtonToAction: array[TSkillPanelButton] of TBasicLemmingAction = (

    baToWalking,
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
  ObjectTypeToTrigger: array[-1..31] of TTriggerTypes = (
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
    trZombie,                 // secret level trigger
    trButton,                 // button
    trRadiation,              // radiation
    trOWDown,                 // OWW down
    trUpdraft,                // updraft
    trFlipper,                // flipper
    trSlowfreeze,             // slowfreeze
    trZombie,                 // hatch
    trAnimation,              // triggered animation
    trZombie,                 // hint
    trNoSplat,                // no-splat
    trSplat,                  // splat
    trTeleport,               // 2-way teleporter
    trTeleport,               // single teleporter
    trZombie,                 // background
    trTrap                    // once trap
  );

implementation

end.

