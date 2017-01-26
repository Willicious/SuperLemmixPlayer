{$include lem_directives.inc}

unit LemStrings;

interface

uses
  UMisc, SysUtils, LemCore;

// version 0.8.0.0 added optional overriding with LVL files
// version 0.8.0.1 added fixes to LemGame.pas:
//    1) fix incorrect entrance order for 3 entrances, non-original DOS
//    2) adds support for replaying the steel-digging glitch in replays
//    3) adds support for nuke glitch

  function NumericalVersionToStringVersion(Main, Sub, Minor: Integer): String;

const
  SPFirstText = '';

  SCheatCode = '';

  // Important paths
  SFGraphics = 'gfx\';
    SFGraphicsHelpers = SFGraphics + 'helpers\';
    SFGraphicsMasks = SFGraphics + 'mask\';
    SFGraphicsMenu = SFGraphics + 'menu\';
    SFGraphicsPanel = SFGraphics + 'panel\';

  SFStyles = 'styles\';
      SFPiecesTerrain = '\terrain\';
      SFPiecesObjects = '\objects\';
      SFPiecesBackgrounds = '\backgrounds\';
      SFPiecesLemmings = '\lemmings\';
      SFTheme = 'theme.nxtm';
      SFTranslation = 'translation.nxtt';

  SFLevels = 'levels\';

  SFSounds = 'sound\';
  SFMusic = 'music\';

  SFData = 'data\';

  // Sound effect files
  SFX_BUILDER_WARNING = 'ting';
  SFX_ASSIGN_SKILL = 'mousepre';
  SFX_YIPPEE = 'yippee';
  SFX_SPLAT = 'splat';
  SFX_LETSGO = 'letsgo';
  SFX_ENTRANCE = 'door';
  SFX_VAPORIZING = 'fire';
  SFX_DROWNING = 'glug';
  SFX_EXPLOSION = 'explode';
  SFX_HITS_STEEL = 'chink';
  SFX_OHNO = 'ohno';
  SFX_SKILLBUTTON = 'changeop';
  SFX_PICKUP = 'oing2';
  SFX_SWIMMING = 'splash';
  SFX_FALLOUT = 'die';
  SFX_FIXING = 'wrench';
  SFX_ZOMBIE = 'zombie';

resourcestring
  SProgramName = 'NeoLemmix Player';
  SDummyString = '';

  {-------------------------------------------------------------------------------
    Errors
  -------------------------------------------------------------------------------}
  SMetaPieceLoadError = 'MetaPiece LoadFromStream is not defined';
  SVgaSpecDimensionError_dd = 'Special Dos level graphics must be %d x %d pixels';

  {-------------------------------------------------------------------------------
    MenuScreen
  -------------------------------------------------------------------------------}
  //@styledef

  SProgramText = 'Built on NeoLemmix Engine';

  // max size for string that fits in the scrolling reel = 34
  // 1234567890123456789012345678901234

  SCredits = '';
    //'Running on NeoLemmix Engine' + #13 +
    //'Version ' + PVersion;

  {-------------------------------------------------------------------------------
    LevelSelectScreen
  -------------------------------------------------------------------------------}
  SLevelSelect = 'Level Selection';

  {-------------------------------------------------------------------------------
    PreviewScreen
  -------------------------------------------------------------------------------}
  SPreviewString =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Saved'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13#13 +
    '     Press mouse button to continue';

  SPreviewStringAuth =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Saved'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13 +
    '          Author: %s'                   + #13#13 +
    '     Press mouse button to continue';

  KPreviewString =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Killed'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13#13 +
    '     Press mouse button to continue';

  KPreviewStringAuth =
    'Level %d ' + '%s'                     + #13#13#13 +
    '          Number of Lemmings %d'      + #13#13 +
    '          %s To Be Killed'             + #13#13 +
    '          Release Rate %s'            + #13#13 +
    '          Time Limit  %s'            + #13#13 +
    '          Rating: %s'                 + #13#13 +
    '          Author: %s'                   + #13#13 +
    '     Press mouse button to continue';


  {-------------------------------------------------------------------------------
    Game Screen Info Panel
  -------------------------------------------------------------------------------}
  SSkillPanelTemplate =
    '..............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' ' + #94 + '_...' + ' ' + #95 +  '_.-..';

  SAthlete = 'Athlete';
  STriathlete = 'Triathlete';
  SQuadathlete = 'X-Athlete';

  SWalker = 'Walker';

  SJumper = 'Jumper';

  SDigger = 'Digger';

  SClimber = 'Climber';

  SDrowner = 'Drowner';

  SHoister = 'Hoister';

  SBuilder = 'Builder';

  SBasher = 'Basher';

  SMiner = 'Miner';

  SFaller = 'Faller';

  SFloater = 'Floater';

  SSplatter = 'Splatter';

  SExiter = 'Exiter';

  SVaporizer = 'Frier';

  SBlocker = 'Blocker';

  SShrugger = 'Shrugger';

  SOhnoer = 'Ohnoer';

  SExploder = 'Bomber';

  SPlatformer = 'Platformer';

  SStacker = 'Stacker';

  SStoner = 'Stoner';

  SSwimmer = 'Swimmer';

  SGlider = 'Glider';

  SMechanic = 'Disarmer';

  SCloner = 'Cloner';

  SFencer = 'Fencer';

  SZombie = 'Zombie';

  SGhost = 'Ghost';

  {-------------------------------------------------------------------------------
    Postview Screen
  -------------------------------------------------------------------------------}
  SYourTimeIsUp =
    'Your time is up!';

  SAllLemmingsAccountedFor =
    'All lemmings accounted for.';

  STalismanUnlocked =
    'You unlocked a talisman!';

  SYouRescued = 'You rescued ';
  SYouNeeded =  'You needed  ';
  SYourRecord = 'Your record ';

  SYourTime =       'Your time taken is  ';
  SYourTimeRecord = 'Your record time is ';

  SResult0 =
    'ROCK BOTTOM! I hope for your sake'      + #13 +
    'that you nuked that level.';

  SResult1 =
    'Better rethink your strategy before'    + #13 +
    'you try this level again!';

  SResult2 =
    'A little more practice on this level'   + #13 +
    'is definitely recommended.';

  SResult3 =
    'You got pretty close that time.'        + #13 +
    'Now try again for that few % extra.';

  SResult4 =
    'OH NO, So near and yet so far (teehee)' + #13 +
    'Maybe this time.....';

  SResult5 =
    'RIGHT ON. You can''t get much closer'   + #13 +
    'than that. Let''s try the next...';

  SResult6 =
    'That level seemed no problem to you on' + #13 +
    'that attempt. Onto the next....';

  SResult7 =
    'You totally stormed that level!'        + #13 +
    'Let''s see if you can storm the next...';

  SResult8 =
    'Superb! You rescued every lemmings on' + #13 +
    'that level. Can you do it again....';


  SCongratulationOrig =
    #13 + #13 +
    'Congratulations!' +
    #13 + #13 + #13 + #13 + #13 +
    'Everybody here at DMA Design salutes you' + #13 +
    'as a MASTER Lemmings player. Not many' + #13 +
    'people will complete the Mayhem levels,' + #13 +
    'you are definitely one of the elite' + #13 +
    #13 + #13 + #13 + #13 + #13 +
    'Now hold your breath for the data disk';

    SResultOhNo0 =
    'Oh dear, not even one poor Lemming'   + #13 +
    'saved. Try a little harder next time.';

  SResultOhNo1 =
    'Yes, well, err, erm, maybe that is' + #13 +
    'NOT the way to do this level.';

  SResultOhNo2 =
    'We are not too impressed with your' + #13 +
    'attempt at that level!';

  SResultOhNo3 =
    'Getting close. You are either pretty' + #13 +
    'good, or simply lucky.';

  SResultOhNo4 =
    'Shame, You were short by a tiny amount.' + #13 +
    'Go for it this time.';

  SResultOhNo5 =
    'Just made it by the skin of your' + #13 +
    'teeth. Time to progress..';

  SResultOhNo6 =
    'More than enough. You have the makings' + #13 +
    'of a master Lemmings player.';

  SResultOhNo7 =
    'What a fine display of Lemmings control.' + #13 +
    'Take a bow then carry on with the game.';

  SResultOhNo8 =
    'WOW! You saved every Lemming.' + #13 +
    'TOTALLY EXCELLENT!';

  SCongratulationOhNo =
    #13 + #13 +
    'Congratulations!' + #13 +
    #13 + #13 + #13 + #13 + #13 +
    'You are truly an Excellent' + #13 +
    'Lemmings player' + #13 +
    #13 +
    'The Lemmings Saga continues at a' + #13 +
    'later date, watch this space';

  SResultH940 =
    'Uh-oh!  Not a single lemming saved!' + #13 +
    'Try harder, the lemmings need you!';

  SResultH941 =
    'Umm, maybe you''d better rethink your' + #13 +
    'strategy a bit!';

  SResultH942 =
    'Try a bit harder...the lemmings are' + #13 +
    'depending on you!';

  SResultH943 =
    'Not bad, but you can certainly do a' + #13 +
    'bit better!';

  SResultH944 =
    'Just a tiny bit more effort will get' + #13 +
    'the lemmings home for the holidays!';

  SResultH945 =
    'Whew!  That was close, but you made it' + #13 +
    'On to the next challenge!';

  SResultH946 =
    'Well done.  You''ve made it with plenty' + #13 +
    'to spare.  Now onto the next...';

  SResultH947 =
    'Very impressive.  You''re well on your' +#13+
    'way to becoming a Lemmings Master!';

  SResultH948 =
    'Excellent!  You''ve managed to save them' + #13 +
    'all!  Can you do as well next time?';

  SCongratulationH94 =
    #13 + #13 +
    'Congratulations!' + #13 +
    #13 + #13 + #13 + #13 + #13 +
    'You are truly an Excellent' + #13 +
    'Lemmings player' + #13 +
    #13 +
    'The Lemmings Saga continues at a' + #13 +
    'later date, watch this space';

  SCongratulationLPDOS =
    #13 + #13 +
    'Congratulations!' +
    #13 + #13 + #13 +
    'You have successfully beaten all of' + #13 +
    'Lemmings Plus DOS Project. Go have a' + #13 +
    'beer or something. You deserve it.' + #13 +
    'That was not an easy task.' + #13 +
    #13 + #13 +
    'Extra special thanks to' + #13 +
    'EricLang and ccexplore' + #13 +
    'And the rest of Lemmings Forums' + #13 + #13 +
    'NeoLemmix Lemmings Plus II coming soon!';    


  SResultLPII0 =
    'You couldn''t even save one lemming.'      + #13 +
    'I hope you nuked that level.';

  SResultLPII1 =
    'You really suck. Maybe you should go'    + #13 +
    'back to Tame, it''d suit you!';

  SResultLPII2 =
    'Getting there, getting there...'   + #13 +
    'Maybe you can do this one.';

  SResultLPII3 =
    'So close. Very frustrate. Much annoy.'        + #13 +
    'Can you save a few more lemmings?';

  SResultLPII4 =
    'Just a couple of lemmings short...' + #13 +
    'You can do this!';

  SResultLPII5 =
    'Well, a clear victory there. Now,'   + #13 +
    'are you ready for the next level?';

  SResultLPII6 =
    'Nicely done. Made it with a few lemmings' + #13 +
    'to spare. Now, time for a new level...';

  SResultLPII7 =
    'That was an amazing performance! Great'        + #13 +
    'job! Now, try a new level!';

  SResultLPII8 =
    'PERFECT!!!' + #13 +
    'You rescued every lemming!!!';

  SCongratulationLPII =
    #13 +
    'Congratulations!' +
    #13 + #13 + #13 +
    'You have successfully beaten all of' + #13 +
    'Lemmings Plus II. Give yourself a' + #13 +
    'pat on the back. You deserve it.' + #13 +
    'That was not an easy task.' + #13 +
    #13 + #13 +
    'Extra special thanks to the following:' + #13 +
    'EricLang, ccexplore, DragonsLover' + #13 +
    'Akseli, mobius' + #13 + #13 +
    '...But...'    + #13 +
    '...are you sure you found everything?';

  SCongratulationLP2B =
    #13 +
    'Congratulations!' +
    #13 + #13 + #13 +
    'You have successfully beaten the' + #13 +
    'Lemmings Plus II bonus pack!' + #13 +
    'Have you completed LPDOS and LPII' + #13 +
    'too? If so, you are truly a great' + #13 +
    'Lemmings player!' + #13 +
    #13 + #13 +
    'Lemmings Plus III coming at' + #13 +
    'some point in the near future!';


  SResultLPIII0 =
    'What a tremendous display of epic fail.'      + #13 +
    'Let''s try not nuking it next time.';

  SResultLPIII1 =
    'That just wasn''t good enough. Surely'    + #13 +
    'you can save more lemmings than that.';

  SResultLPIII2 =
    'A decent performance, but not good'   + #13 +
    'enough. Keep trying, you can do it!';

  SResultLPIII3 =
    'Not far off! With a bit more effort,'        + #13 +
    'you should be able to get there...';

  SResultLPIII4 =
    'Ouch, you nearly had it that time.' + #13 +
    'Maybe you should try again...';

  SResultLPIII5 =
    'Nicely done! Those lemmings are sure'   + #13 +
    'glad they met you!';

  SResultLPIII6 =
    'A very impressive performance. Keep' + #13 +
    'up the good work!';

  SResultLPIII7 =
    'There is no doubt that you know'        + #13 +
    'exactly what you''re doing.';

  SResultLPIII8 =
    'Amazing, simply amazing! Not even' + #13 +
    'a single lemming lost! Well done!';

  SCongratulationLPIII =
    'CONGRATU-FREAKIN-LATIONS!!' +
    #13 + #13 +
    'Amazing, simply amazing.' + #13 + #13 +
    'You''ve overcome every obstacle, and' + #13 +
    'beaten even the legendary Fierce levels.' + #13 +
    'You are truly an exceptional master of' + #13 +
    'Lemmings, there is no doubt.' + #13 + #13 +
    'Thanks EricLang & ccexplore for Lemmix;' + #13 +
    'Akseli, DynaLem, minimac and Nepster' + #13 +
    'for pre-release testing; and to the' + #13 +
    'Lemmings Forums community in general' + #13 + #13 +
    '...But...'    + #13 +
    'Did you find all NINE secret levels? ;)';

  SCongratulationLP3B =
    'CONGRATU-FREAKIN-LATIONS!!' +
    #13 + #13 +
    'Amazing, simply amazing.' + #13 + #13 +
    'You''ve overcome every obstacle, and' + #13 +
    'beaten even more challenging levels.' + #13 +
    'You are truly an exceptional master of' + #13 +
    'Lemmings, there is no doubt.' + #13 + #13 +
    'Thanks EricLang & ccexplore for Lemmix;' + #13 +
    'and to the Lemmings Forums community' + #13 +
    'in general.' + #13 + #13 + #13 +
    'Look forward to a new entry in the'    + #13 +
    'Lemmings Plus series coming soon!';

  SCongratulationLPH =
    'Well done!' +
    #13 + #13 +
    'You did a great job and brought the' + #13 +
    'lemmings home for yet another holiday.' + #13 +
    #13 + #13 +
    'I hope you enjoyed this special entry' + #13 +
    'in the Lemmings Plus series!' + #13 +
    #13 + #13 +
    'Special thanks to DynaLem and minimac' + #13 +
    'for pre-release testing.' + #13 +
    #13 + #13 +
    'Look for to "Lemmings Plus Z Project"' + #13 +
    'coming at some point in the near future!';



  SResultLPZ0 =
    'Really, not even one puny lemming?'      + #13 +
    'Perhaps you''re not cut out for this...';

  SResultLPZ1 =
    'That wasn''t the slightest bit impressive.'    + #13 +
    'Come on, try harder!';

  SResultLPZ2 =
    'Well, that wasn''t completely terrible.'   + #13 +
    'Maybe if you keep trying, you''ll get it.';

  SResultLPZ3 =
    'You''re not far from the goal now!'        + #13 +
    'Come on, give it everything you''ve got!';

  SResultLPZ4 =
    'Wow, that was unbelievably close!' + #13 +
    'Just a little bit of improvement and...';

  SResultLPZ5 =
    'It seems you know what to do here.'   + #13 +
    'Time to try a different level.';

  SResultLPZ6 =
    'Nicely done! This level is clearly no' + #13 +
    'match for your skills!';

  SResultLPZ7 =
    'That was a very impressive performance.'        + #13 +
    'Can you keep that standard up?';

  SResultLPZ8 =
    'WOW, BRILLIANT! That was nothing short' + #13 +
    'of pure excellence!';

  SCongratulationLPZ =
    'And so, a legend ends.' + #13 +
    'Over the last few years, the Lemmings' + #13 +
    'Plus series has brought many various' + #13 +
    'challenges, introduced all kinds of' + #13 +
    'twists, and provided hours of fun to' + #13 +
    'Lemmings fans. But all good things' + #13 +
    'must come to an end, and this is the' + #13 +
    'end of Lemmings Plus.' + #13 + #13 +
    'You have just completed the final entry' + #13 +
    'in the Lemmings Plus series.' + #13 + #13 +
    'Thanks Akseli, DynaLem, mobius, Minim' + #13 +
    'and Nepster for pre-release testing.' + #13 + #13 +
    'I hope you enjoyed playing as much as' + #13 +
    'I enjoyed making them.';

  SCongratulationLPC =
    'Congratulations!' + #13 + #13 +
    'I hope you enjoyed playing this small' + #13 +
    'collection of levels from the Lemmings' + #13 +
    'Plus series.' + #13 + #13 +
    'If you haven''t already, why not give' + #13 +
    'the full versions of these packs a try?' + #13 + #13 +
    'And don''t forget, there''s also the' + #13 +
    'bonus packs of Lemmings Plus II and' + #13 +
    'Lemmings Plus III, and Holiday Lemmings' + #13 +
    'Plus, which weren''t included in here.' + #13 + #13 +
    'Lemmings Plus Omega coming soon!';


  SYourAccessCode_ds =
    'Your Password for Level %d' + #13 +
    'is %s';


  SPressLeftMouseForNextLevel =
    'Press left mouse button for next level';

  SPressLeftMouseToRetryLevel =
    'Press left mouse button to retry level';

  SPressMiddleMouseToReplayLevel =
    'Press middle mouse button to replay';

  SPressRightMouseForMenu =
    'Press right mouse button for menu';

  SPressMouseToContinue =
    'Press mouse button to continue';

const
  LemmingActionStrings: array[TBasicLemmingAction] of string = (
    SDummyString,
    SWalker,
    SJumper,
    SDigger,
    SClimber,
    SDrowner,
    SHoister,
    SBuilder,
    SBasher,
    SMiner,
    SFaller,
    SFloater,
    SSplatter,
    SExiter,
    SVaporizer,
    SBlocker,
    SShrugger,
    SOhnoer,
    SExploder,
    SDummyString,
    SPlatformer,
    SStacker,
    SStoner,
    SStoner,
    SSwimmer,
    SGlider,
    SMechanic,
    SCloner,
    SFencer
  );

 ResultStrings: array[0..8] of string = (
    SResultOhNo0,
    SResultOhNo1,
    SResultOhNo2,
    SResultOhNo3,
    SResultOhNo4,
    SResultOhNo5,
    SResultOhNo6,
    SResultOhNo7,
    SResultOhNo8
  );
  SCongrats: string = SCongratulationOhNo;

implementation

function NumericalVersionToStringVersion(Main, Sub, Minor: Integer): String;
begin
  Result := IntToStr(Main) + '.' + LeadZeroStr(Sub, 2) + 'n';
  if Minor > 1 then
    Result := Result + '-' + Chr(Minor + 64);
end;

end.


