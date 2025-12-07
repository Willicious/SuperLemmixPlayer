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
  DOM_TELEPORT         = 20; // Sends lems to receiver
  DOM_RECEIVER         = 21; // Receives lems from teleporter
  DOM_PORTAL           = 22; // Two-way teleporter, essentially
  DOM_PICKUP           = 23; // Pickup skills
  DOM_COLLECTIBLE      = 24; // Collectibles with optional effects
  DOM_UPDRAFT          = 25; // Slows falling lems, sends Gliders upwards, speeds up Ballooners
  DOM_SPLITTER         = 26; // Alternates direction of lemmings
  DOM_RADIATION        = 27; // Assigns timebomber with a variable countdown
  DOM_SLOWFREEZE       = 28; // Assigns freezer with a variable countdown
  DOM_NOSPLAT          = 29; // Makes any fall safe regardless of distance
  DOM_SPLAT            = 30; // Makes any fall deadly regardless of distance
  DOM_NORMALIZER       = 31; // Normalizes neutrals and rivals
  DOM_DECORATION       = 32; // Decoration-only graphics, can move at a set direction & speed if specified
  DOM_ANIMATION        = 33; // Animated graphics
  DOM_ANIMONCE         = 34; // Single-animated graphics
  // DOM_STEEL         = 35; // Steel
  // DOM_LEMMING       = 36; // Pre-placed lemming

implementation

end.