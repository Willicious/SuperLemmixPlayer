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
  TBasicLemmingAction = (   //needs to match TBasicLemmingAction in LemStrings
    baNone,            //1
    baWalking,         //2
    baAscending,       //3
    baDigging,         //4
    baClimbing,        //5
    baDrowning,        //6
    baHoisting,        //7
    baBuilding,        //8
    baBashing,         //9
    baMining,          //10
    baFalling,         //11
    baFloating,        //12
    baSplatting,       //13
    baExiting,         //14
    baVaporizing,      //15
    baBlocking,        //16
    baShrugging,       //17
    baTimebombing,     //18
    baTimebombFinish,  //19
    baOhnoing,         //20
    baExploding,       //21
    baToWalking,       //22
    baPlatforming,     //23
    baStacking,        //24
    baFreezing,        //25
    baFreezeFinish,    //26
    baSwimming,        //27
    baGliding,         //28
    baFixing,          //29
    baCloning,         //30
    baFencing,         //31
    baReaching,        //32
    baShimmying,       //33
    baJumping,         //34
    baDehoisting,      //35
    baSliding,         //36
    baSpearing,        //37
    baGrenading,       //38
    baLasering         //39
  );

const
  MAX_SKILL_TYPES_PER_LEVEL = 14;

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
    spbTimebomber,
    spbBomber,
    spbFreezer,
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
    'platformer',
    'builder',
    'stacker',
    'laserer',
    'basher',
    'fencer',
    'miner',
    'digger',
    'spearer',
    'grenader',
    'cloner'
    );

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
    'timebombers',
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
    'spearers',
    'grenaders',
    'cloners'
    );

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
    baLasering
  ];

const
  ActionToSkillPanelButton: array[TBasicLemmingAction] of TSkillPanelButton = (
    spbNone,        //1   baNone
    spbWalker,      //2   baWalk
    spbNone,        //3   baAscending
    spbDigger,      //4   baDigging
    spbClimber,     //5   baClimbing
    spbNone,        //6   baHoisting
    spbNone,        //7   baDrowning
    spbBuilder,     //8   baBricklaying
    spbBasher,      //9   baBashing
    spbMiner,       //10  baMining
    spbNone,        //11  baFalling
    spbFloater,     //12  baUmbrella
    spbNone,        //13  baSplatting
    spbNone,        //14  baExiting
    spbNone,        //15  baFried
    spbBlocker,     //16  baBlocking
    spbNone,        //17  baShrugging
    spbTimebomber,  //18  baTimebombing
    spbNone,        //19  baTimebombFinish
    spbNone,        //20  baOhNoing
    spbBomber,      //21  baExploding
    spbWalker,      //22
    spbPlatformer,  //23
    spbStacker,     //24
    spbFreezer,     //25  baFreezing
    spbNone,        //26  baFreezeFinish
    spbSwimmer,     //27
    spbGlider,      //28
    spbDisarmer,    //29
    spbCloner,      //30
    spbFencer,      //31
    spbNone,        //32
    spbShimmier,    //33
    spbJumper,      //34
    spbNone,        //35
    spbSlider,      //36
    spbSpearer,     //37
    spbGrenader,    //38
    spbLaserer      //39
  );

const
  SkillPanelButtonToAction: array[TSkillPanelButton] of TBasicLemmingAction = (

    baToWalking, //1
    baJumping,   //2
    baShimmying, //3
    baSliding,   //4
    baClimbing,  //5
    baSwimming,  //6
    baFloating,  //7
    baGliding,   //8
    baFixing,    //9
    baTimebombing,  //10
    baExploding,    //11
    baFreezing,     //12
    baBlocking,     //13
    baPlatforming,  //14
    baBuilding,     //15
    baStacking,     //16
    baSpearing,     //17
    baGrenading,    //18
    baLasering,     //19
    baBashing,      //20
    baFencing,      //21
    baMining,       //22
    baDigging,      //23
    baCloning,      //24
    baNone, //Null
    baNone, //RR-
    baNone, //RR+
    baNone, //Pause
    baNone, //Rewind
    baNone, //FF
    baNone, //Restart
    baNone, //Nuke
    baNone  //Squiggle
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

