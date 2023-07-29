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
    baZombieWalking,   //3
    baAscending,       //4
    baDigging,         //5
    baClimbing,        //6
    baDrowning,        //7
    baHoisting,        //8
    baBuilding,        //9
    baBashing,         //10
    baMining,          //11
    baFalling,         //12
    baFloating,        //13
    baSplatting,       //14
    baExiting,         //15
    baVaporizing,      //16
    baVinetrapping,    //17
    baBlocking,        //18
    baShrugging,       //19
    baTimebombing,     //20
    baTimebombFinish,  //21
    baOhnoing,         //22
    baExploding,       //23
    baToWalking,       //24
    baPlatforming,     //25
    baStacking,        //26
    baFreezing,        //27
    baFreezerExplosion,//28
    baFrozen,          //29
    baUnfreezing,      //30
    baSwimming,        //31
    baGliding,         //32
    baFixing,          //33
    baCloning,         //34
    baFencing,         //35
    baReaching,        //36
    baShimmying,       //37
    baJumping,         //38
    baDehoisting,      //39
    baSliding,         //40
    baDangling,        //41
    baSpearing,        //42
    baGrenading,       //43
    baLooking,         //44
    baLasering,        //45
    baBallooning,      //46
    baDrifting,        //47
    baSleeping         //48
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
    baBallooning
  ];

const
  ActionToSkillPanelButton: array[TBasicLemmingAction] of TSkillPanelButton = (
    spbNone,        //1   baNone
    spbWalker,      //2   baWalking
    spbNone,        //3   baZombieWalking
    spbNone,        //4   baAscending
    spbDigger,      //5   baDigging
    spbClimber,     //6   baClimbing
    spbNone,        //7   baHoisting
    spbNone,        //8   baDrowning
    spbBuilder,     //9   baBricklaying
    spbBasher,      //10  baBashing
    spbMiner,       //11  baMining
    spbNone,        //12  baFalling
    spbFloater,     //13  baUmbrella
    spbNone,        //14  baSplatting
    spbNone,        //15  baExiting
    spbNone,        //16  baVaporizing
    spbNone,        //17  baVinetrapping
    spbBlocker,     //18  baBlocking
    spbNone,        //19  baShrugging
    spbTimebomber,  //20  baTimebombing
    spbNone,        //21  baTimebombFinish
    spbNone,        //22  baOhNoing
    spbBomber,      //23  baExploding
    spbWalker,      //24  baToWalking
    spbPlatformer,  //25  baPlatforming
    spbStacker,     //26  baStacking
    spbFreezer,     //27  baFreezing
    spbNone,        //28  baFreezerExplosion
    spbNone,        //29  baFrozen
    spbNone,        //30  baUnfreezing
    spbSwimmer,     //31  baSwimming
    spbGlider,      //32  baGliding
    spbDisarmer,    //33  baFixing
    spbCloner,      //34  baCloning
    spbFencer,      //35  baFencing
    spbNone,        //36  baReaching
    spbShimmier,    //37  baShimmying
    spbJumper,      //38  baJumping
    spbNone,        //39  baDehoisting
    spbSlider,      //40  baGliding
    spbNone,        //41  baDangling
    spbSpearer,     //42  baSpearing
    spbGrenader,    //43  baGrenading
    spbNone,        //44  baLooking
    spbLaserer,     //45  baLasering
    spbBallooner,   //46  baBallooning
    spbNone,        //47  baDrifting
    spbNone         //48  baSleeping
  );

const
  SkillPanelButtonToAction: array[TSkillPanelButton] of TBasicLemmingAction = (

    //this needs to match the order of the skill on the panel
    baToWalking,    //1
    baJumping,      //2
    baShimmying,    //3
    baBallooning,   //4
    baSliding,      //5
    baClimbing,     //6
    baSwimming,     //7
    baFloating,     //8
    baGliding,      //9
    baFixing,       //10
    baTimebombing,  //11
    baExploding,    //12
    baFreezing,     //13
    baBlocking,     //14
    baPlatforming,  //15
    baBuilding,     //16
    baStacking,     //17
    baSpearing,     //18
    baGrenading,    //19
    baLasering,     //20
    baBashing,      //21
    baFencing,      //22
    baMining,       //23
    baDigging,      //24
    baCloning,      //25
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
  ObjectTypeToTrigger: array[-1..38] of TTriggerTypes = (
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
    trRadiation,              // radiation
    trOWDown,                 // OWW down
    trUpdraft,                // updraft
    trFlipper,                // flipper
    trSlowfreeze,             // slowfreeze
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
    trAnim,                   // once animation
    trBlasticine,             // lems become instabombers on contact
    trVinewater,              // triggers vinetrapper instead of drowner
    trPoison                  // turns lems into zombies
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

