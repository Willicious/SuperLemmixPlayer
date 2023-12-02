{$include lem_directives.inc}
unit LemAnimationSet;

interface

uses
  Classes, SysUtils, GR32,
  StrUtils,
  PngInterface,
  LemCore,
  LemTypes,
  LemRecolorSprites,
  LemNeoTheme,
  LemMetaAnimation,
  LemNeoParser,
  LemStrings;

const
  LTR = False;
  RTL = True;

const
{-------------------------------------------------------------------------------
  DOS animations ordered by their appearance in main.dat
  The constants below show the exact order
-------------------------------------------------------------------------------}
  // MUST MATCH BELOW (not the next list, the one after that)
  // And don't forget to update the numbers! ;P
  NUM_LEM_SPRITES     = 89;   // Num lem sprites
  NUM_LEM_SPRITE_TYPE = 44;         // Num lem sprite types
  WALKING             = 0;    // 1  // 1
  WALKING_RTL         = 1;    // 2
  ZOMBIEWALKING       = 2;    // 3  // 2
  ZOMBIEWALKING_RTL   = 3;    // 4
  ASCENDING           = 4;    // 5  // 3
  ASCENDING_RTL       = 5;    // 6
  DIGGING             = 6;    // 7  // 4
  DIGGING_RTL         = 7;    // 8
  CLIMBING            = 8;    // 9  // 5
  CLIMBING_RTL        = 9;    // 10
  DROWNING            = 10;   // 11 // 6
  DROWNING_RTL        = 11;   // 12
  HOISTING            = 12;   // 13 // 7
  HOISTING_RTL        = 13;   // 14
  BRICKLAYING         = 14;   // 15 // 8
  BRICKLAYING_RTL     = 15;   // 16
  BASHING             = 16;   // 17 // 9
  BASHING_RTL         = 17;   // 18
  MINING              = 18;   // 19 // 10
  MINING_RTL          = 19;   // 20
  FALLING             = 20;   // 21 // 11
  FALLING_RTL         = 21;   // 22
  UMBRELLA            = 22;   // 23 // 12
  UMBRELLA_RTL        = 23;   // 24
  SPLATTING           = 24;   // 25 // 13
  SPLATTING_RTL       = 25;   // 26
  EXITING             = 26;   // 27 // 14
  EXITING_RTL         = 27;   // 28
  VAPORIZING          = 28;   // 29 // 15
  VAPORIZING_RTL      = 29;   // 30
  VINETRAPPING        = 30;   // 31 // 16
  VINETRAPPING_RTL    = 31;   // 32
  BLOCKING            = 32;   // 33 // 17
  BLOCKING_RTL        = 33;   // 34
  SHRUGGING           = 34;   // 35 // 18
  SHRUGGING_RTL       = 35;   // 36
  TIMEBOMBEXPLOSION   = 36;   // 37 // 19
  TIMEBOMBEXPLOSION_RTL= 37;  // 38
  OHNOING             = 38;   // 39 // 20
  OHNOING_RTL         = 39;   // 40
  EXPLOSION           = 40;   // 41 // 21
  EXPLOSION_RTL       = 41;   // 42
  PLATFORMING         = 42;   // 43 // 22
  PLATFORMING_RTL     = 43;   // 44
  FREEZING            = 44;   // 45 // 23
  FREEZING_RTL        = 45;   // 46
  FREEZEREXPLOSION    = 46;   // 47 // 24
  FREEZEREXPLOSION_RTL= 47;   // 48
  FROZEN              = 48;   // 49 // 25
  FROZEN_RTL          = 49;   // 50
  UNFREEZING          = 50;   // 51 // 26
  UNFREEZING_RTL      = 51;   // 52
  SWIMMING            = 52;   // 53 // 27
  SWIMMING_RTL        = 53;   // 54
  GLIDING             = 54;   // 55 // 28
  GLIDING_RTL         = 55;   // 56
  FIXING              = 56;   // 57 // 29
  FIXING_RTL          = 57;   // 58
  STACKING            = 58;   // 59 // 30
  STACKING_RTL        = 59;   // 60
  FENCING             = 60;   // 61 // 31
  FENCING_RTL         = 61;   // 62
  REACHING            = 62;   // 63 // 32
  REACHING_RTL        = 63;   // 64
  SHIMMYING           = 64;   // 65 // 33
  SHIMMYING_RTL       = 65;   // 66
  JUMPING             = 66;   // 67 // 34
  JUMPING_RTL         = 67;   // 68
  DEHOISTING          = 68;   // 69 // 35
  DEHOISTING_RTL      = 69;   // 70
  SLIDING             = 70;   // 71 // 36
  SLIDING_RTL         = 71;   // 72
  DANGLING            = 72;   // 73 // 37
  DANGLING_RTL        = 73;   // 74
  THROWING            = 74;   // 75 // 38
  THROWING_RTL        = 75;   // 76
  LOOKING             = 76;   // 77 // 39
  LOOKING_RTL         = 77;   // 78
  LASERING            = 78;   // 79 // 40
  LASERING_RTL        = 79;   // 80
  BALLOONING          = 80;   // 81 // 41
  BALLOONING_RTL      = 81;   // 82
  LADDERING           = 82;   // 83 // 42
  LADDERING_RTL       = 83;   // 84
  DRIFTING            = 84;   // 85 // 43
  DRIFTING_RTL        = 85;   // 86
  SLEEPING            = 86;   // 87 // 44
  SLEEPING_RTL        = 87;   // 88
  ICECUBE             = 88;   // 89 Bookmark - this one does NOT need an RTL form;
                             // In fact in needs to be moved to the Masks section
                             // Also, it's not counted as a "sprite type"

  // This one must match TBasicLemmingAction in LemCore / LemStrings
  AnimationIndices : array[TBasicLemmingAction, LTR..RTL] of Integer = (
    (0,0),                                    // 1 baNone
    (WALKING, WALKING_RTL),                   // 2 baWalking,
    (ZOMBIEWALKING, ZOMBIEWALKING_RTL),       // 3 baZombieWalking
    (ASCENDING, ASCENDING_RTL),               // 4 baAscending,
    (DIGGING, DIGGING_RTL),                   // 5 baDigging,
    (CLIMBING, CLIMBING_RTL),                 // 6 baClimbing,
    (DROWNING, DROWNING_RTL),                 // 7 baDrowning,
    (HOISTING, HOISTING_RTL),                 // 8 baHoisting,
    (BRICKLAYING, BRICKLAYING_RTL),           // 9 baBricklaying,
    (BASHING, BASHING_RTL),                   // 10 baBashing,
    (MINING, MINING_RTL),                     // 11 baMining,
    (FALLING, FALLING_RTL),                   // 12 baFalling,
    (UMBRELLA, UMBRELLA_RTL),                 // 13 baUmbrella,
    (SPLATTING, SPLATTING_RTL),               // 14 baSplatting,
    (EXITING, EXITING_RTL),                   // 15 baExiting,
    (VAPORIZING, VAPORIZING_RTL),             // 16 baVaporizing,
    (VINETRAPPING, VINETRAPPING_RTL),         // 17 baVinetrapping,
    (BLOCKING, BLOCKING_RTL),                 // 18 baBlocking,
    (SHRUGGING, SHRUGGING_RTL),               // 19 baShrugging,
    (OHNOING, OHNOING_RTL),                   // 20 baTimebombing,
    (TIMEBOMBEXPLOSION, TIMEBOMBEXPLOSION_RTL), // 21 baTimebombFinish,
    (OHNOING, OHNOING_RTL),                   // 22 baOhnoing,
    (EXPLOSION, EXPLOSION_RTL),               // 23 baExploding,
    (0,0),                                    // 24 baToWalking. Should never happen.
    (PLATFORMING, PLATFORMING_RTL),           // 25 baPlatforming
    (STACKING, STACKING_RTL),                 // 26 baStacking
    (FREEZING, FREEZING_RTL),                 // 27 baFreezing
    (FREEZEREXPLOSION, FREEZEREXPLOSION_RTL), // 28 baFreezerExplosion
    (FROZEN, FROZEN_RTL),                     // 29 baFrozen
    (UNFREEZING, UNFREEZING_RTL),             // 30 baUnfreezing
    (SWIMMING, SWIMMING_RTL),                 // 31 baSwimming
    (GLIDING, GLIDING_RTL),                   // 32 baGliding
    (FIXING, FIXING_RTL),                     // 33 baFixing
    (0,0),                                    // 34 baCloning? Another that should never happen
    (FENCING, FENCING_RTL),                   // 35 baFencing
    (REACHING, REACHING_RTL),                 // 36 baReaching (for shimmier)
    (SHIMMYING, SHIMMYING_RTL),               // 37 baShimmying
    (JUMPING, JUMPING_RTL),                   // 38 baJumping
    (DEHOISTING, DEHOISTING_RTL),             // 39 baDehoisting
    (SLIDING, SLIDING_RTL),                   // 40 baSliding
    (DANGLING, DANGLING_RTL),                 // 41 baDangling
    (THROWING, THROWING_RTL),                 // 42 baSpearing
    (THROWING, THROWING_RTL),                 // 43 baGrenading
    (LOOKING, LOOKING_RTL),                   // 44 baLooking
    (LASERING, LASERING_RTL),                 // 45 baLasering
    (BALLOONING, BALLOONING_RTL),             // 46 baBallooning
    (LADDERING, LADDERING_RTL),               // 47 baPlatforming
    (DRIFTING, DRIFTING_RTL),                 // 48 baDrifting
    (SLEEPING, SLEEPING_RTL)                  // 49 baSleeping
  );

type
  {-------------------------------------------------------------------------------
    Basic animationset for dos.
  -------------------------------------------------------------------------------}
  TBaseAnimationSet = class(TPersistent)
  private
    fMetaLemmingAnimations : TMetaLemmingAnimations; // Meta data lemmings
    fLemmingAnimations     : TBitmaps; // List of lemmings bitmaps

    fCountDownDigitsBitmap  : TBitmap32;
    fRadiationDigitsBitmap  : TBitmap32;
    fSlowfreezeDigitsBitmap : TBitmap32;
    fFreezingOverlay        : TBitmap32;
    fUnfreezingOverlay      : TBitmap32;
    fHatchNumbersBitmap     : TBitmap32;
    fHighlightBitmap        : TBitmap32;
    fBalloonPopBitmap       : TBitmap32;
    fGrenadeBitmap          : TBitmap32;
    fSpearBitmap            : TBitmap32;
    fTheme                  : TNeoTheme;

    fHasZombieColor         : Boolean;
    fHasNeutralColor        : Boolean;

    fRecolorer              : TRecolorImage;

    procedure ReadMetaData(aColorDict: TColorDict = nil; aShadeDict: TShadeDict = nil);
    procedure LoadMetaData(aColorDict: TColorDict; aShadeDict: TShadeDict);

    procedure HandleRecoloring(aColorDict: TColorDict; aShadeDict: TShadeDict);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReadData;
    procedure ClearData;

    property Theme                 : TNeoTheme read fTheme write fTheme;

    property LemmingAnimations     : TBitmaps read fLemmingAnimations;
    property MetaLemmingAnimations : TMetaLemmingAnimations read fMetaLemmingAnimations;
    property CountDownDigitsBitmap : TBitmap32 read fCountDownDigitsBitmap;
    property RadiationDigitsBitmap : TBitmap32 read fRadiationDigitsBitmap;
    property SlowfreezeDigitsBitmap: TBitmap32 read fSlowfreezeDigitsBitmap;
    property FreezingOverlay       : TBitmap32 read fFreezingOverlay;
    property UnfreezingOverlay     : TBitmap32 read fUnfreezingOverlay;
    property HatchNumbersBitmap    : TBitmap32 read fHatchNumbersBitmap;
    property HighlightBitmap       : TBitmap32 read fHighlightBitmap;
    property BalloonPopBitmap      : TBitmap32 read fBalloonPopBitmap;
    property GrenadeBitmap         : TBitmap32 read fGrenadeBitmap;
    property SpearBitmap           : TBitmap32 read fSpearBitmap;
    property Recolorer             : TRecolorImage read fRecolorer;

    property HasZombieColor: Boolean read fHasZombieColor;
    property HasNeutralColor: Boolean read fHasNeutralColor;
  end;

implementation

uses
  LemNeoPieceManager,
  GameControl;

{ TBaseAnimationSet }

procedure TBaseAnimationSet.LoadMetaData(aColorDict: TColorDict; aShadeDict: TShadeDict);
const
// MUST MATCH ABOVE (not the next list, the one after that)
// They also need to appear in "scheme.nxmi", but the order doesn't matter there
  ANIM_NAMES: array[0..43] of String =  (
  'WALKER',        // 1
  'ZOMBIEWALKER',  // 2
  'ASCENDER',      // 3
  'DIGGER',        // 4
  'CLIMBER',       // 5
  'DROWNER',       // 6
  'HOISTER',       // 7
  'BUILDER',       // 8
  'BASHER',        // 9
  'MINER',         // 10
  'FALLER',        // 11
  'FLOATER',       // 12
  'SPLATTER',      // 13
  'EXITER',        // 14
  'BURNER',        // 15 - aka Vaporizer
  'VINETRAPPER',   // 16
  'BLOCKER',       // 17
  'SHRUGGER',      // 18
  'TIMEBOMBER',    // 19
  'OHNOER',        // 20
  'BOMBER',        // 21
  'PLATFORMER',    // 22
  'FREEZING',      // 23
  'FREEZER',       // 24
  'FROZEN',        // 25
  'UNFREEZING',    // 26
  'SWIMMER',       // 27
  'GLIDER',        // 28
  'DISARMER',      // 29
  'STACKER',       // 30
  'FENCER',        // 31
  'REACHER',       // 32
  'SHIMMIER',      // 33
  'JUMPER',        // 34
  'DEHOISTER',     // 35
  'SLIDER',        // 36
  'DANGLER',       // 37
  'THROWER',       // 38
  'LOOKER',        // 39
  'LASERER',       // 40
  'BALLOONER',     // 41
  'LADDERER',      // 42
  'DRIFTER',       // 43
  'SLEEPER'        // 44
  );
  DIR_NAMES: array[0..1] of String = ('RIGHT', 'LEFT');
var
  Parser: TParser;
  AnimSec: TParserSection;
  ThisAnimSec: TParserSection;
  ColorSec: TParserSection;
  ShadeSec: TParserSection;
  StateRecolorSec: TParserSection;
  DirSec: TParserSection;
  i: Integer;
  dx: Integer;

  Anim: TMetaLemmingAnimation;

  HasRequiredRecoloring: Boolean;
begin
  Parser := TParser.Create;
  try
    try
      Parser.LoadFromFile('scheme.nxmi');
      AnimSec := Parser.MainSection.Section['animations'];
    except
      raise Exception.Create('TBaseAnimationSet: Error while opening scheme.nxmi.');
    end;

    HasRequiredRecoloring := false;
    StateRecolorSec := Parser.MainSection.Section['state_recoloring'];
    if StateRecolorSec <> nil then
    begin
      HasRequiredRecoloring := (StateRecolorSec.Section['athlete'] <> nil) and (StateRecolorSec.Section['selected'] <> nil);
      fHasZombieColor := StateRecolorSec.Section['zombie'] <> nil;
      fHasNeutralColor := StateRecolorSec.Section['neutral'] <> nil;
    end;

    if not HasRequiredRecoloring then
      raise Exception.Create('TBaseAnimationSet: Athlete and/or Selected Lemming recoloring data missing.');

    for i := 0 to NUM_LEM_SPRITE_TYPE - 1 do
    begin
      try
        ThisAnimSec := AnimSec.Section[ANIM_NAMES[i]];
        for dx := 0 to 1 do
        begin
          DirSec := ThisAnimSec.Section[DIR_NAMES[dx]];
          Anim := fMetaLemmingAnimations[i * 2 + dx];

          Anim.FrameCount := ThisAnimSec.LineNumeric['frames'];

          if ThisAnimSec.Line['peak_frame'] <> nil then
            Anim.FrameDiff := Anim.FrameCount - ThisAnimSec.LineNumeric['peak_frame']
          else
            Anim.FrameDiff := Anim.FrameCount - ThisAnimSec.LineNumeric['loop_to_frame'];

          Anim.FootX := DirSec.LineNumeric['foot_x'];
          Anim.FootY := DirSec.LineNumeric['foot_y'];
          Anim.Description := LeftStr(DIR_NAMES[dx], 1) + ANIM_NAMES[i];
        end;
      except
        Parser.Free;
        raise EParserError.Create('TBaseAnimationSet: Error loading lemming animation metadata for ' + ANIM_NAMES[i] + '.')
      end;
    end;

    if aColorDict <> nil then
    begin
      ColorSec := Parser.MainSection.Section['spriteset_recoloring'];
      aColorDict.Clear;
      if ColorSec <> nil then
        for i := 0 to ColorSec.LineList.Count-1 do
          aColorDict.Add(ColorSec.LineList[i].ValueNumeric, ColorSec.LineList[i].Keyword);
    end;

    if aShadeDict <> nil then
    begin
      ShadeSec := Parser.MainSection.Section['shades'];
      aShadeDict.Clear;
      if ShadeSec <> nil then
        ShadeSec.DoForEachSection('shade',
          procedure (aSec: TParserSection; const aIteration: Integer)
          var
            BaseColor: TColor32;
          begin
            BaseColor := aSec.LineNumeric['PRIMARY'] and $FFFFFF;
            aSec.DoForEachLine('alt',
              procedure (aLine: TParserLine; const aIteration: Integer)
              begin
                aShadeDict.Add(aLine.ValueNumeric and $FFFFFF, BaseColor);
              end
            );
          end
        );
    end;
  finally
    Parser.Free;
  end;
end;


procedure TBaseAnimationSet.ReadMetaData(aColorDict: TColorDict = nil; aShadeDict: TShadeDict = nil);
{-------------------------------------------------------------------------------
  o make lemming animations
  o make mask animations metadata
-------------------------------------------------------------------------------}
var
  AnimIndex: Integer;
begin
  // Add right- and left-facing version for 25 skills and the one freezer mask
  for AnimIndex := 0 to NUM_LEM_SPRITES - 1 do
  begin
    fMetaLemmingAnimations.Add;
  end;

  // Setting the foot position of the freezer mask.
  // This should be irrelevant for the freezer mask, as the freezer mask is not positioned wrt. the lemming's foot.
  // For other sprites, the foot position is required though.
  with fMetaLemmingAnimations[ICECUBE] do
  begin
    FrameCount := 1;
    FootX := 8 * ResMod;
    FootY := 10 * ResMod;
  end;

  LoadMetaData(aColorDict, aShadeDict);
end;

procedure TBaseAnimationSet.ReadData;
var
  Fn: string;
  Bmp: TBitmap32;
  TempBitmap: TBitmap32;
  iAnimation: Integer;
  MLA: TMetaLemmingAnimation;
  BalloonPop, BalloonPopHR: String;
  FreezingOverlay, FreezingOverlayHR: String;
  UnfreezingOverlay, UnfreezingOverlayHR: String;
  Grenades, GrenadesHR: String;
  X: Integer;

  SrcFolder: String;
  ColorDict: TColorDict;
  ShadeDict: TShadeDict;

  MetaSrcFolder, ImgSrcFolder, EffectsSrcFolder: String;

  Info: TUpscaleInfo;

  procedure UpscalePieces(Bitmap: TBitmap32);
  begin
    Info := PieceManager.GetUpscaleInfo(SrcFolder, rkLemmings);
    UpscaleFrames(Bitmap, 2, MLA.FrameCount, Info.Settings);
  end;
begin
  TempBitmap := TBitmap32.Create;
  ColorDict := TColorDict.Create;
  ShadeDict := TShadeDict.Create;

  try                      // Bookmark - remove?
    if (fTheme = nil) then //or (GameParams.ForceDefaultLemmings) then
      SrcFolder := 'default'
    else
      SrcFolder := PieceManager.Dealias(fTheme.Lemmings, rkLemmings).Piece.GS;

    if SrcFolder = '' then SrcFolder := 'default';
    if not DirectoryExists(AppPath + SFStyles + SrcFolder + SFPiecesLemmings) then
      SrcFolder := 'default';

    SetCurrentDir(AppPath + SFStyles + SrcFolder + SFPiecesLemmings);

    if fMetaLemmingAnimations.Count = 0 then // Not entirely sure why it would ever NOT be 0
      ReadMetaData(ColorDict, ShadeDict);

    MetaSrcFolder := AppPath + SFStyles + SrcFolder + SFPiecesLemmings;

    if GameParams.HighResolution then
      ImgSrcFolder := AppPath + SFStyles + SrcFolder + SFPiecesLemmingsHighRes
    else
      ImgSrcFolder := MetaSrcFolder;

    for iAnimation := 0 to NUM_LEM_SPRITES - 2 do // -2 to leave out the freezer placeholder
    begin
      MLA := fMetaLemmingAnimations[iAnimation];
      Fn := RightStr(MLA.Description, Length(MLA.Description) - 1);

      if FileExists(ImgSrcFolder + Fn + '.png') then
        TPngInterface.LoadPngFile(ImgSrcFolder + Fn + '.png', TempBitmap)
      else begin
        TPngInterface.LoadPngFile(MetaSrcFolder + Fn + '.png', TempBitmap);
        UpscalePieces(TempBitmap);
      end;

      MLA.Width := TempBitmap.Width div 2;
      MLA.Height := TempBitmap.Height div MLA.FrameCount;

      if iAnimation mod 2 = 1 then
        X := 0
      else
        X := MLA.Width;

      Bmp := TBitmap32.Create;
      Bmp.SetSize(MLA.Width, MLA.Height * MLA.FrameCount);
      TempBitmap.DrawTo(Bmp, 0, 0, Rect(X, 0, X + MLA.Width, MLA.Height * MLA.FrameCount));

      fLemmingAnimations.Add(Bmp);

      if GameParams.HighResolution then
      begin
        MLA.FootX := MLA.FootX * 2;
        MLA.FootY := MLA.FootY * 2;
      end;
    end;

    fRecolorer.LoadSwaps(SrcFolder);

    HandleRecoloring(ColorDict, ShadeDict);

    fLemmingAnimations.Add(TBitmap32.Create); // For the Freezer

    // ------------------------------------- //
    // --- Extract masks / Digits / etc. --- //
    // ------------------------------------- //

    fCountDownDigitsBitmap.DrawMode := dmBlend;
    fCountDownDigitsBitmap.CombineMode := cmMerge;
    fRadiationDigitsBitmap.DrawMode := dmBlend;
    fRadiationDigitsBitmap.CombineMode := cmMerge;
    fSlowfreezeDigitsBitmap.DrawMode := dmBlend;
    fSlowfreezeDigitsBitmap.CombineMode := cmMerge;

    fFreezingOverlay.DrawMode := dmBlend;
    fFreezingOverlay.CombineMode := cmMerge;

    fUnfreezingOverlay.DrawMode := dmBlend;
    fUnfreezingOverlay.CombineMode := cmMerge;

    fHatchNumbersBitmap.DrawMode := dmBlend;
    fHatchNumbersBitmap.CombineMode := cmMerge;

    fHighlightBitmap.DrawMode := dmBlend;
    fHighlightBitmap.CombineMode := cmMerge;

    fBalloonPopBitmap.DrawMode := dmBlend;
    fBalloonPopBitmap.CombineMode := cmMerge;

    fGrenadeBitmap.DrawMode := dmBlend;
    fGrenadeBitmap.CombineMode := cmMerge;

    fSpearBitmap.DrawMode := dmBlend;
    fSpearBitmap.CombineMode := cmMerge;

    fMetaLemmingAnimations[ICECUBE].Width := fLemmingAnimations[ICECUBE].Width;
    fMetaLemmingAnimations[ICECUBE].Height := fLemmingAnimations[ICECUBE].Height;
    fLemmingAnimations[ICECUBE].DrawMode := dmBlend;
    fLemmingAnimations[ICECUBE].CombineMode := cmMerge;

    if GameParams.HighResolution then
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer-hr.png', fLemmingAnimations[ICECUBE]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'spears-hr.png', fSpearBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight-hr.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown-hr.png', fCountdownDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'radiation-hr.png', fRadiationDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'slowfreeze-hr.png', fSlowfreezeDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'numbers-hr.png', fHatchNumbersBitmap);
    end else begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer.png', fLemmingAnimations[ICECUBE]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'spears.png', fSpearBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown.png', fCountdownDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'radiation.png', fRadiationDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'slowfreeze.png', fSlowfreezeDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'numbers.png', fHatchNumbersBitmap);
    end;

    // Load the freezing & unfreezing overlays and balloon pop graphic
    EffectsSrcFolder := AppPath + SFStyles + SrcFolder + SFPiecesEffects;
    FreezingOverlay := 'freezing_overlay.png';
    FreezingOverlayHR := 'freezing_overlay-hr.png';
    UnfreezingOverlay := 'unfreezing_overlay.png';
    UnfreezingOverlayHR := 'unfreezing_overlay-hr.png';
    BalloonPop := 'balloon_pop.png';
    BalloonPopHR := 'balloon_pop-hr.png';
    Grenades := 'grenades.png';
    GrenadesHR := 'grenades-hr.png';

    if GameParams.HighResolution then
    begin
      if FileExists(EffectsSrcFolder + FreezingOverlayHR) then
        TPngInterface.LoadPngFile(EffectsSrcFolder + FreezingOverlayHR, fFreezingOverlay)
      else begin
        TPngInterface.LoadPngFile(EffectsSrcFolder + FreezingOverlay, fFreezingOverlay);
        UpscalePieces(fFreezingOverlay);
      end;

      if FileExists(EffectsSrcFolder + UnfreezingOverlayHR) then
        TPngInterface.LoadPngFile(EffectsSrcFolder + UnfreezingOverlayHR, fUnfreezingOverlay)
      else begin
        TPngInterface.LoadPngFile(EffectsSrcFolder + UnfreezingOverlay, fUnfreezingOverlay);
        UpscalePieces(fUnfreezingOverlay);
      end;

      if FileExists(EffectsSrcFolder + BalloonPopHR) then
        TPngInterface.LoadPngFile(EffectsSrcFolder + BalloonPopHR, fBalloonPopBitmap)
      else begin
        TPngInterface.LoadPngFile(EffectsSrcFolder + BalloonPop, fBalloonPopBitmap);
        UpscalePieces(fBalloonPopBitmap);
      end;

      if FileExists(EffectsSrcFolder + GrenadesHR) then
        TPngInterface.LoadPngFile(EffectsSrcFolder + GrenadesHR, fGrenadeBitmap)
      else begin
        TPngInterface.LoadPngFile(EffectsSrcFolder + Grenades, fGrenadeBitmap);
        UpscalePieces(fGrenadeBitmap);
      end;
    end else begin
      TPngInterface.LoadPngFile(EffectsSrcFolder + FreezingOverlay, fFreezingOverlay);
      TPngInterface.LoadPngFile(EffectsSrcFolder + UnfreezingOverlay, fUnfreezingOverlay);
      TPngInterface.LoadPngFile(EffectsSrcFolder + BalloonPop, fBalloonPopBitmap);
      TPngInterface.LoadPngFile(EffectsSrcFolder + Grenades, fGrenadeBitmap);
    end;
  finally
    TempBitmap.Free;
    ColorDict.Free;
    ShadeDict.Free;
  end;
end;


procedure TBaseAnimationSet.ClearData;
begin
  fLemmingAnimations.Clear;
  fMetaLemmingAnimations.Clear;
  fCountDownDigitsBitmap.Clear;
  fRadiationDigitsBitmap.Clear;
  fSlowfreezeDigitsBitmap.Clear;
  fFreezingOverlay.Clear;
  fUnfreezingOverlay.Clear;
  fHatchNumbersBitmap.Clear;
  fHighlightBitmap.Clear;
  fBalloonPopBitmap.Clear;
  fGrenadeBitmap.Clear;
  fSpearBitmap.Clear;
  fHasZombieColor := false;
  fHasNeutralColor := false;
  fTheme := nil;
end;

constructor TBaseAnimationSet.Create;
begin
  inherited Create;
  fMetaLemmingAnimations := TMetaLemmingAnimations.Create(TMetaLemmingAnimation);
  fLemmingAnimations := TBitmaps.Create;
  fRecolorer := TRecolorImage.Create;
  fCountDownDigitsBitmap := TBitmap32.Create;
  fRadiationDigitsBitmap := TBitmap32.Create;
  fSlowfreezeDigitsBitmap := TBitmap32.Create;
  fFreezingOverlay := TBitmap32.Create;
  fUnfreezingOverlay := TBitmap32.Create;
  fHatchNumbersBitmap := TBitmap32.Create;
  fHighlightBitmap := TBitmap32.Create;
  fBalloonPopBitmap := TBitmap32.Create;
  fGrenadeBitmap := TBitmap32.Create;
  fSpearBitmap := TBitmap32.Create;
end;

destructor TBaseAnimationSet.Destroy;
begin
  fMetaLemmingAnimations.Free;
  fLemmingAnimations.Free;
  fCountDownDigitsBitmap.Free;
  fRadiationDigitsBitmap.Free;
  fSlowfreezeDigitsBitmap.Free;
  fFreezingOverlay.Free;
  fUnfreezingOverlay.Free;
  fHatchNumbersBitmap.Free;
  fHighlightBitmap.Free;
  fBalloonPopBitmap.Free;
  fGrenadeBitmap.Free;
  fSpearBitmap.Free;
  fRecolorer.Free;
  inherited Destroy;
end;

procedure TBaseAnimationSet.HandleRecoloring(aColorDict: TColorDict; aShadeDict: TShadeDict);
var
  Template, ThisAnim: TBitmap32;
  i, x, y: Integer;
  C, BaseC, NewC: TColor32;
begin
  if fTheme = nil then Exit;
  if aColorDict = nil then Exit; // This one shouldn't happen but just in case

  Template := TBitmap32.Create;
  try
    Template.DrawMode := dmTransparent;

    for i := 0 to fLemmingAnimations.Count-1 do
    begin
      ThisAnim := fLemmingAnimations[i];
      Template.SetSize(ThisAnim.Width, ThisAnim.Height);
      Template.Clear($00000000);

      for y := 0 to ThisAnim.Height-1 do
        for x := 0 to ThisAnim.Width-1 do
        begin
          C := ThisAnim[x, y] and $FFFFFF;
          if aShadeDict.ContainsKey(C) then
          begin
            BaseC := aShadeDict[C];
            if not aColorDict.ContainsKey(BaseC) then Continue;
            if not fTheme.DoesColorExist(aColorDict[BaseC]) then Continue;

            NewC := (fTheme.Colors[aColorDict[BaseC]] and $FFFFFF) or
                    (ThisAnim[x,y] and $FF000000);

            Template[x, y] := ApplyColorShift(NewC, BaseC, C);
          end else begin
            if not aColorDict.ContainsKey(C) then Continue;
            if not fTheme.DoesColorExist(aColorDict[C]) then Continue; // We do NOT want to fall back to default color here.
            Template[x, y] := (fTheme.Colors[aColorDict[C]] and $FFFFFF) or
                              (ThisAnim[x,y] and $FF000000);
          end;
        end;

      Template.DrawTo(ThisAnim, 0, 0);
    end;

    fRecolorer.ApplyPaletteSwapping(aColorDict, aShadeDict, fTheme);
  finally
    Template.Free;
  end;
end;

end.

