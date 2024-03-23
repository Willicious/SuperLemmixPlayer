unit LemGadgetsConstants;

interface

const
  DOM_NOOBJECT         = 65535; // No object
  DOM_NONE             = 0;  // No trigger area
  DOM_WINDOW           = 1;  // Entrance hatch
  DOM_EXIT             = 2;  // Normal Exit
  DOM_LOCKEXIT         = 3;  // Locked Exit
  DOM_BUTTON           = 4;  // Opens locked exit
  DOM_FORCELEFT        = 5;  // Left arm of blocker / left-facing forcefield
  DOM_FORCERIGHT       = 6;  // Right arm of blocker / right-facing forcefield
  DOM_TRAP             = 7;  // Triggered trap
  DOM_TRAPONCE         = 8;  // Single-use trap
  DOM_WATER            = 9;  // Swimmers and Invincible lems swim, other lems drown
  DOM_BLASTICINE       = 10; // Invincible lems swim, other lems explode (no crater)
  DOM_VINEWATER        = 11; // Invincible lems swim, other lems vinetrap
  DOM_POISON           = 12; // Invincible lems swim, zombies drift, other lems become zombies
  DOM_LAVA             = 13; // Invincible lems swim, other lems vaporize
  DOM_FIRE             = 14; // Non-invincible lems vaporize
  DOM_ONEWAYLEFT       = 15; // Leftwards-only destructible
  DOM_ONEWAYRIGHT      = 16; // Rightwards-only destructible
  DOM_ONEWAYDOWN       = 17; // Downwards-only destructible
  DOM_ONEWAYUP         = 18; // Upwards-only destructible
  DOM_BLOCKER          = 19; // The middle part of a blocker
  // DOM_STEEL         = 20; // Steel
  DOM_TELEPORT         = 21; // Sends lems to receiver
  DOM_RECEIVER         = 22; // Receives lems from teleporter
  // DOM_LEMMING       = 23; // Pre-placed lemming
  DOM_PICKUP           = 24; // Pickup skills
  DOM_COLLECTIBLE      = 25; // Collectibles with optional effects
  DOM_UPDRAFT          = 26; // Slows falling lems, sends Gliders upwards, speeds up Ballooners
  DOM_SPLITTER         = 27; // Alternates direction of lemmings
  DOM_RADIATION        = 28; // Assigns timebomber with a variable countdown
  DOM_SLOWFREEZE       = 29; // Assigns freezer with a variable countdown
  DOM_NOSPLAT          = 30; // Makes any fall safe regardless of distance
  DOM_SPLAT            = 31; // Makes any fall deadly regardless of distance
  DOM_BACKGROUND       = 32; // Background graphics
  DOM_PAINT            = 33; // Paint-only graphics
  DOM_ANIMATION        = 34; // Animated graphics
  DOM_ANIMONCE         = 35; // Single-animated graphics
  // DOM_HINT          = 36; // No longer used
  // DOM_TWOWAYTELE    = 37; // No longer used
  // DOM_SINGLETELE    = 38; // No longer used
  // DOM_BGIMAGE       = 39; // No longer used

implementation

end.