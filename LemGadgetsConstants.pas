unit LemGadgetsConstants;

interface

const
  DOM_NOOBJECT         = 65535;
  DOM_NONE             = 0;
  DOM_EXIT             = 1;
  DOM_FORCELEFT        = 2; // left arm of blocker
  DOM_FORCERIGHT       = 3; // right arm of blocker
  DOM_TRAP             = 4; // triggered trap
  DOM_WATER            = 5; // causes drowning
  DOM_FIRE             = 6; // causes vaporizing
  DOM_ONEWAYLEFT       = 7;
  DOM_ONEWAYRIGHT      = 8;
  // 9 = unused, formerly steel
  DOM_BLOCKER          = 10; // the middle part of blocker
  DOM_TELEPORT         = 11;
  DOM_RECEIVER         = 12;
  // 13 = unused, formerly preplaced lemming
  DOM_PICKUP           = 14;
  DOM_LOCKEXIT         = 15;
  // 16 = unused; formerly sketch, and before that secret level trigger
  DOM_BUTTON           = 17;
  DOM_RADIATION        = 18;
  DOM_ONEWAYDOWN       = 19;
  DOM_UPDRAFT          = 20;
  DOM_FLIPPER          = 21;
  DOM_SLOWFREEZE       = 22;
  DOM_WINDOW           = 23;
  DOM_ANIMATION        = 24;
  // 25 = unused, formerly placeholder for hint but never actually implemented
  DOM_NOSPLAT          = 26;
  DOM_SPLAT            = 27;
  // 28 = unused, formerly two-way teleporter
  // 29 = unused, formerly single-object teleporter
  DOM_BACKGROUND       = 30;
  DOM_TRAPONCE         = 31;
  // 32 = unused, formerly background image
  DOM_ONEWAYUP         = 33;
  DOM_PAINT            = 34;
  DOM_ANIMONCE         = 35;
  DOM_BLASTICINE       = 36;
  DOM_VINEWATER        = 37;
  DOM_POISON           = 38;

implementation

end.