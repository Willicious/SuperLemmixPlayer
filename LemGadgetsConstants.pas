unit LemGadgetsConstants;

interface

const
  DOM_NOOBJECT         = 65535; // No object
  DOM_NONE             = 0;  // No trigger area
  DOM_WINDOW           = 1;  // Entrance hatch
  DOM_EXIT             = 2;  // Normal Exit
  DOM_RIVALEXIT        = 3;  // Rival Exit
  DOM_LOCKEXIT         = 4;  // Locked Exit
  DOM_BUTTON           = 5;  // Opens locked exit
  DOM_FORCELEFT        = 6;  // Left arm of blocker / left-facing forcefield
  DOM_FORCERIGHT       = 7;  // Right arm of blocker / right-facing forcefield
  DOM_TRAP             = 8;  // Triggered trap
  DOM_TRAPONCE         = 9;  // Single-use trap
  DOM_WATER            = 10;  // Swimmers and Invincible lems swim, other lems drown
  DOM_BLASTICINE       = 11; // Invincible lems swim, other lems explode (no crater)
  DOM_VINEWATER        = 12; // Invincible lems swim, other lems vinetrap
  DOM_POISON           = 13; // Invincible lems swim, zombies drift, other lems become zombies
  DOM_LAVA             = 14; // Invincible lems swim, other lems vaporize
  DOM_FIRE             = 15; // Non-invincible lems vaporize
  DOM_ONEWAYLEFT       = 16; // Leftwards-only destructible
  DOM_ONEWAYRIGHT      = 17; // Rightwards-only destructible
  DOM_ONEWAYDOWN       = 18; // Downwards-only destructible
  DOM_ONEWAYUP         = 19; // Upwards-only destructible
  DOM_BLOCKER          = 20; // The middle part of a blocker
  DOM_TELEPORT         = 21; // Sends lems to receiver
  DOM_RECEIVER         = 22; // Receives lems from teleporter
  DOM_PICKUP           = 23; // Pickup skills
  DOM_COLLECTIBLE      = 24; // Collectibles with optional effects
  DOM_UPDRAFT          = 25; // Slows falling lems, sends Gliders upwards, speeds up Ballooners
  DOM_SPLITTER         = 26; // Alternates direction of lemmings
  DOM_RADIATION        = 27; // Assigns timebomber with a variable countdown
  DOM_SLOWFREEZE       = 28; // Assigns freezer with a variable countdown
  DOM_NOSPLAT          = 29; // Makes any fall safe regardless of distance
  DOM_SPLAT            = 30; // Makes any fall deadly regardless of distance
  DOM_DECORATION       = 31; // Decoration-only graphics, can move at a set direction & speed if specified
  DOM_ANIMATION        = 32; // Animated graphics
  DOM_ANIMONCE         = 33; // Single-animated graphics
  // DOM_STEEL         = 34; // Steel
  // DOM_LEMMING       = 35; // Pre-placed lemming

implementation

end.