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

{•}

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
    baCloning
  );

  {TSkillPanelButton = (
    spbNone,
    spbSlower,
    spbFaster,
    spbClimber,
    spbUmbrella,
    spbExplode,
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
    spbUmbrella,
    spbGlider,
    spbMechanic,
    spbExplode,
    spbStoner,
    spbBlocker,
    spbPlatformer,
    spbBuilder,
    spbStacker,
    spbBasher,
    spbMiner,
    spbDigger,
    spbCloner,

    spbNone,
    spbSlower,
    spbFaster,
    spbPause,
    spbNuke
  );


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
    trBlockMiddle,
    trTeleport,
    trPickup,
    trButton,
    trRadiation,
    trSlowfreeze,
    trUpdraft,
    trFlipper,
    trSplat,
    trNoSplat,
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
    baCloning
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
    spbUmbrella,
    spbNone,
    spbNone,
    spbNone,
    spbBlocker,
    spbNone,
    spbNone,
    spbExplode,
    spbWalker,
    spbPlatformer,
    spbStacker,
    spbStoner,
    spbNone,
    spbSwimmer,
    spbGlider,
    spbMechanic,
    spbCloner
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
    baMining,
    baDigging,
    baCloning,
    baNone, //Null
    baNone, //RR-
    baNone, //RR+
    baNone, //Pause
    baNone  //Nuke
  );

implementation

end.

