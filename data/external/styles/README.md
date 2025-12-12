--------------------------------------------------------------------------------

STYLES VERSION 3.0

--------------------------------------------------------------------------------

This folder contains all styles that are compatible with SuperLemmix.

Ensure that it is placed into the root folder of your SuperLemmix directory.

Please check compatibility before using any styles from NeoLemmix, particularly
any styles that use custom Lemmings sprites.

In any case, it's always worth including any styles you have used in your levels
along with the level pack itself, to ensure playability.

If you need any help, visit www.lemmingsforums.net and head to the dedicated
SuperLemmix board for support.

--------------------------------------------------------------------------------

Many thanks and kudos to ericderkovits for help maintaining these styles,
I absolutely couldn't have done this by myself

~ WillLem

--------------------------------------------------------------------------------

Changelog:

3.0
+ Changed orig_ and ohno_ styles to slx_
+ Re-added orig_ and ohno_ from NeoLemmix, but with some differences:
  + Backgrounds changed to Amiga Blue (tile also added to backgrounds)
  + Proxima's background tiles added to each style
  + Water objects changed to Blasticine (bubble), Vinewater (rock), Lava (fire) and Poison (marble)
  + Modified trap animations - see this post for a list of the differences:
    https://www.lemmingsforums.net/index.php?topic=5420.msg90074#msg90074
+ Removed deprecated pieces from slx_bubble, ohno_bubble and orig_sega
	
(No changes for 2.9)

2.8.9
+ Added 5 of Dex's sets (dex_brass, dex_grotto, dex_hoard, dex_jade, dex_lush)
  ~ Updated styles.ini to include these

(No changes for 2.8.4 - 2.8.8)

2.8.3
+ Updated all styles with custom sprites:
  ~ Platformer bricks are now 2px thick (updated sprites, scheme and levelinfo_icons accordingly)
- Removed psp_styles (Oscar's levels have not yet been added to DMA compilation, and this large style takes the folder over 100MB)

2.8
+ l2_beach updated (pieces added/modified, level templates added as backgrounds)
+ 5 new dex styles added (autumn, circuit, mosaic, palace, rust)
+ 3 new namida styles added (crypt, dungeon, organic)
+ 2 new glitchapp styles added (cavetileset, underwaterdiveBlue)
+ added new style eric_special
+ Portals added to willlem_special
+ psp_levels style added (required to play Oscar's PSP Lemmings)
+ Updates to several glitchapp styles (added fish, bubbles and single-use mine traps)
  ~ (fishcoralreef, fishfilletscity, underwaterdivingstyle)
+ Rival recolourings / other theme data added to the following styles:
  ~ (flopsy_soniclems, gigalem_millas & millas 2, xmas)
  ~ (strato_lems_arab, strato_lems_lix, strato_lems_soviet)
+ Exit markers added to jamie_techno
+ Pieces added to turrican_special
~ Sounds updated for objects in several styles
  ~ (davidz_persiapalace, flopsy_gigalem_labyrinth, gigalem_desertmd, gigalem_lagoon...)
  ~ (gigalem_purplemd, gigalem_relic, ohno_snow, plom_metro, plom_psychmd, plom_studio...)
  ~ (proxima_persia, ray_cyberspace, ray_eldorado, timfoxxy_gigalem_launchbase...)
  ~ (willlem_lemminas_slushworld, willlem_special, willlem_xmas)
~ 14 more gadgets updated from "Background" to "Decoration" in various styles

2.7.3
+ Added 5 new psp styles: psp_crystal, psp_dirt, psp_fire, psp_marble and psp_pillar
+ Various updates to the following styles:
  ~ ray_biolab, ray_circus, ray_cyberspace, ray_eldorado, ray_food, ray_sewer and ray_snow  

2.7.2
~ Corrected digits alignment for orig and ohno exits
~ Corrected digits alignment for default pickup

Changelog:

2.7 MAJOR UPDATE
+ Turner sprite added to the following styles:
  ~ default, flopsy_soniclems, gigalem_millas(1 & 2), all willlem_lemminas, xmas
+ Invincible lemming overlays added to "effects" folder of all styles with custom sprites
+ "levelinfo" folder (in styles with custom sprites) is now "icons" instead, and contains the following files:
  ~ levelinfo_icons.png, talismans.png, panel_icons.png
  ~ all of the above are now per-style (as well as per-pack) customisable
+ "Lava" is now its own water type
~ all water objects that have previously been assigned the "Fire" effect have been updated to "Lava" instead:
  ~ davidz_raymancave, flopsy_gigalem_chemical, flopsy_lavareef, flopsy_marblezones1,
  ~ insanesteve_isworld, insanesteve_smb, namida_martian, ray_eldorado
+ "Background" objects have been renamed to "Decoration" for code/design-side clarity
  ~ ALL STYLES featuring these objects have been updated accordingly (578 items in total!)
+ Default "Button", "Pickup" and "Updraft" objects have been given a new look/animation
+ Various water updates to the following styles:
  ~ davidz_marble_ex (renamings of various water/poison objects, and updated .nxmos),
  ~ johannes_droidlings_circuit (electrified_water is now poison instead of fire)
+ Radiation and Slowfreeze object added to the following styles:
  ~ NOTE: in most cases, these objects existed in the style previously and have been re-added from old formats
  ~ thanks to ericderkovits for diligently compiling these, and editing them where needed
  ~ davidz_glacier(re-purposed), gigalem_dread, gigalem_lagoon, gigalem_starport,
  ~ namida_desert, namida_lab, namida_psychedelic, namida_purple, namida_sky, namida_space,
  ~ orig_crystal, ohno_snow, ray_biolab, ray_cyberspace, ray_snow
+ Various objects/terrain pieces added to the following styles:
  ~ davidz_special (various new items), jaime_techno (exit from old formats), proxima_persia (new locked exit)

2.6.1
+ Added plom_gildedbayside and plom_godorrisisle
+ Updated several plom styles with Millas singular and plural names
+ Updated water objects in davidz_marble_ex, ray_gore and ray_spooky
  ~ (these are now poison objects instead)
+ Renamed ray_sewer acid to sewerwater and acidfall to sewerwaterfall (still water objects)
+ Updated fire objects in namida_horror, namida_lab and namida_wasteland
  ~ (these are now poison objects instead)
+ Renamed namida_martian water object to lava (it's now fire)
+ Updated namida_wasteland radiating_ball (it's now radiation instead of fire)

2.6 MAJOR UPDATE
+ Added wide_trigger_marble_exit to willlem_special
+ Added Ladderer and Ballooner sprites to the following styles:
  ~ default, xmas, willlem_lemminas (and variants), flopsy_soniclems, gigalem_millas (1 & 2)
~ updated levelinfo_icons for the following styles:
  ~ default, xmas, willlem_lemminas (and variants), flopsy_soniclems, gigalem_millas (1 & 2)

2.5 MAJOR UPDATE
~ zombiewalker and drifter sprites added to the following styles:
  ~ default, xmas, willlem_lemminas (and variants), flopsy_soniclems, gigalem_millas (1 & 2)
~ updated levelinfo_icons for the following styles:
  ~ default, xmas, willlem_lemminas (and variants), flopsy_soniclems, gigalem_millas (1 & 2)
~ ray_biolab and ray_spooky have had their water objects re-purposed as poison objects
~ ray_eldorado water (lava) object re-purposed as fire
~ Many of gigalem's and plom's styles which use the Millas sprites have had their theme.nxtm files
  ~ updated to include names_singular and names_plural, for displaying the names of the Millas in-game
~ updated default radiation and slowfreeze object animations

2.4 MAJOR UPDATE
+ Many styles added, bringing the total to 294
~ sms_fire water is now called "lava" and is a fire object (a water object has been added in its stead)
~ sms_marble water is now a "poison" object (a water object has been added in its stead)
~ gigalem_xmasbubble water is now a "blasticine" object (a water object has been added in its stead)
~ gigalem_xmasrock water is now a "vinewater" object (a water object has been added in its stead)
~ juanjo_machine water is now a "poison" object
  ~ the previously separate water images have also been combined now that vertical resizing is possible
~ SQron_turrican2wall water is now a "poison" object (a water object has been added in its stead)
~ willlem_lemminas_tealkingdom bubbles is now a "blasticine" object
~ willlem_special inverse water fire is now "inverse lava fire" and is a fire object
~ willlem_special inverse water marble is now "inverse poison marble" and is a poison object
~ radiation and slowfreeze objects added to default folder

2.3 MAJOR UPDATE
~ "Poison" is now a new object type which is swimmable, but turns lems into zombies
~ All water objects that have been previously repurposed as "poison" are now poison (rather than fire) objects

2.2
+ Added flopsy_soniclems, gigalem_millas and gigalem_millas2 (custom sprites)

2.1 MAJOR UPDATE (Default, Xmas and Lemminas styles from before this update will no longer work in SuperLemmix)
~ New sprites (Freezing, Frozen, Unfreezing, Sleeper & Vinetrapper) added to Default, Xmas, and Lemminas styles
~ ohno_bubble water is now called "blasticine" and is a new object type which explodes lems on contact
~ ohno_rock water is now called "vinewater" and is a new object type which triggers vinetrap animation
~ Improved Blocker sprites for Default, Xmas, and Lemminas styles
~ Updated backpack colours for low-res Builder, Platformer, Stacker

2.0.1
~ Fixed willlem_lemminas_laracroft so that they can be used in the Player
~ Added willlem_lemminas_laracroft to styles.ini file so that they can be used in the Editor
~ Updated scheme.nxmi in willlem_lemminas, willlem_lemminas_honeycomb and willlem_lemminas_laracroft

2.0
+ Added willlem_lemminas_laracroft
+ Updated default, xmas, willlem_lemminas and willlem_lemminas_honeycomb with new dangler & looker sprites,
  plus further refinements to other sprites in these sets
- Removed gigalem_millas (this one also needs the new sprites to be added before it can be included)

1.0.1
+ Added sprites to xmas and updated scheme.nxmi

1.0 MAJOR UPDATE
~ orig_fire water is now called "lava" and is a fire object (a water object has been added in its stead)
~ orig_marble water is now called "poison" and is a fire object (a water object has been added in its stead)
