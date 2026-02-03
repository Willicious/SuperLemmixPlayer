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
  LemStrings,
  SharedGlobals;

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
  NUM_LEM_SPRITES     = 94;   // Num lem sprites
  NUM_LEM_SPRITE_TYPE = 47;         // Num lem sprite types
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
  TURNING             = 66;   // 67 // 34
  TURNING_RTL         = 67;   // 68
  JUMPING             = 68;   // 69 // 35
  JUMPING_RTL         = 69;   // 70
  DEHOISTING          = 70;   // 71 // 36
  DEHOISTING_RTL      = 71;   // 72
  SLIDING             = 72;   // 73 // 37
  SLIDING_RTL         = 73;   // 74
  DANGLING            = 74;   // 75 // 38
  DANGLING_RTL        = 75;   // 76
  THROWING            = 76;   // 77 // 39
  THROWING_RTL        = 77;   // 78
  LOOKING             = 78;   // 79 // 40
  LOOKING_RTL         = 79;   // 80
  LASERING            = 80;   // 81 // 41
  LASERING_RTL        = 81;   // 82
  BALLOONING          = 82;   // 83 // 42
  BALLOONING_RTL      = 83;   // 84
  LADDERING           = 84;   // 85 // 43
  LADDERING_RTL       = 85;   // 86
  DRIFTING            = 86;   // 87 // 44
  DRIFTING_RTL        = 87;   // 88
  PROPELLING          = 88;   // 89 // 45
  PROPELLING_RTL      = 89;   // 90
  BATTING             = 90;   // 91 // 46
  BATTING_RTL         = 91;   // 92
  SLEEPING            = 92;   // 93 // 47
  SLEEPING_RTL        = 93;   // 94
  // N.B. REMEMBER to change the numbers at the top!

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
    (TURNING, TURNING_RTL),                   // 38 baTurning
    (JUMPING, JUMPING_RTL),                   // 39 baJumping
    (DEHOISTING, DEHOISTING_RTL),             // 40 baDehoisting
    (SLIDING, SLIDING_RTL),                   // 41 baSliding
    (DANGLING, DANGLING_RTL),                 // 42 baDangling
    (THROWING, THROWING_RTL),                 // 43 baSpearing
    (THROWING, THROWING_RTL),                 // 44 baGrenading
    (LOOKING, LOOKING_RTL),                   // 45 baLooking
    (LASERING, LASERING_RTL),                 // 46 baLasering
    (BALLOONING, BALLOONING_RTL),             // 47 baBallooning
    (LADDERING, LADDERING_RTL),               // 48 baPlatforming
    (DRIFTING, DRIFTING_RTL),                 // 49 baDrifting
    (PROPELLING, PROPELLING_RTL),             // 50 baPropelling
    (BATTING, BATTING_RTL),                   // 51 baBatting
    (SLEEPING, SLEEPING_RTL)                  // 52 baSleeping
  );

type
  {-------------------------------------------------------------------------------
    Basic animationset for dos.
  -------------------------------------------------------------------------------}
  TBaseAnimationSet = class(TPersistent)
  private
    fMetaLemmingAnimations : TMetaLemmingAnimations; // Meta data lemmings
    fLemmingAnimations     : TBitmaps; // List of lemmings bitmaps

    fPortalWarpBitmap       : TBitmap32;
    fCountDownDigitsBitmap  : TBitmap32;
    fRadiationDigitsBitmap  : TBitmap32;
    fSlowfreezeDigitsBitmap : TBitmap32;
    fFreezingOverlay        : TBitmap32;
    fUnfreezingOverlay      : TBitmap32;
    fInvincibilityOverlay   : TBitmap32;
    fNumbersBitmap          : TBitmap32;
    fHighlightBitmap        : TBitmap32;
    fBalloonPopBitmap       : TBitmap32;
    fExitMarkerNormalBitmap : TBitmap32;
    fExitMarkerRivalBitmap  : TBitmap32;
    fExitMarkerZombieBitmap : TBitmap32;
    fGrenadeBitmap          : TBitmap32;
    fSpearBitmap            : TBitmap32;
    fIceCubeBitmap          : TBitmap32;
    fTheme                  : TNeoTheme;

    fHasZombieColor         : Boolean;
    fHasNeutralColor        : Boolean;
    fHasRivalColor        : Boolean;

    fRecolorer              : TRecolorImage;

    procedure ReadMetaData(aColorDict: TColorDict = nil; aShadeDict: TShadeDict = nil);
    procedure LoadMetaData(aColorDict: TColorDict; aShadeDict: TShadeDict);

    procedure HandleRecoloring(aColorDict: TColorDict; aShadeDict: TShadeDict);
  public
    constructor Create;
    destructor Destroy; override;

    procedure PrepareAnimations;
    procedure ClearData;

    property Theme                 : TNeoTheme read fTheme write fTheme;

    property LemmingAnimations     : TBitmaps read fLemmingAnimations;
    property MetaLemmingAnimations : TMetaLemmingAnimations read fMetaLemmingAnimations;
    property PortalWarpBitmap      : TBitmap32 read fPortalWarpBitmap;
    property CountDownDigitsBitmap : TBitmap32 read fCountDownDigitsBitmap;
    property RadiationDigitsBitmap : TBitmap32 read fRadiationDigitsBitmap;
    property SlowfreezeDigitsBitmap: TBitmap32 read fSlowfreezeDigitsBitmap;
    property FreezingOverlay       : TBitmap32 read fFreezingOverlay;
    property UnfreezingOverlay     : TBitmap32 read fUnfreezingOverlay;
    property InvincibilityOverlay  : TBitmap32 read fInvincibilityOverlay;
    property NumbersBitmap         : TBitmap32 read fNumbersBitmap;
    property HighlightBitmap       : TBitmap32 read fHighlightBitmap;
    property BalloonPopBitmap      : TBitmap32 read fBalloonPopBitmap;
    property ExitMarkerNormalBitmap: TBitmap32 read fExitMarkerNormalBitmap;
    property ExitMarkerRivalBitmap : TBitmap32 read fExitMarkerRivalBitmap;
    property ExitMarkerZombieBitmap: TBitmap32 read fExitMarkerZombieBitmap;
    property GrenadeBitmap         : TBitmap32 read fGrenadeBitmap;
    property SpearBitmap           : TBitmap32 read fSpearBitmap;
    property IceCubeBitmap         : TBitmap32 read fIceCubeBitmap;
    property Recolorer             : TRecolorImage read fRecolorer;

    property HasZombieColor: Boolean read fHasZombieColor;
    property HasNeutralColor: Boolean read fHasNeutralColor;
    property HasRivalColor: Boolean read fHasRivalColor;

    procedure LoadGrenadeImages(aBitmap: TBitmap32);
    procedure LoadSpearImages(aBitmap: TBitmap32);
    procedure DrawProjectilesToBitmap(Src, Dst: TBitmap32; dstX, dstY: Integer; SrcRect: TRect);
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
  ANIM_NAMES: array[0..46] of String =  (
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
  'TURNER',        // 34
  'JUMPER',        // 35
  'DEHOISTER',     // 36
  'SLIDER',        // 37
  'DANGLER',       // 38
  'THROWER',       // 39
  'LOOKER',        // 40
  'LASERER',       // 41
  'BALLOONER',     // 43
  'LADDERER',      // 44
  'DRIFTER',       // 45
  'PROPELLER',     // 46
  'BATTER',        // 46
  'SLEEPER'        // 47
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

    HasRequiredRecoloring := False;
    StateRecolorSec := Parser.MainSection.Section['state_recoloring'];
    if StateRecolorSec <> nil then
    begin
      HasRequiredRecoloring := (StateRecolorSec.Section['athlete'] <> nil) and (StateRecolorSec.Section['selected'] <> nil);
      fHasZombieColor := StateRecolorSec.Section['zombie'] <> nil;
      fHasNeutralColor := StateRecolorSec.Section['neutral'] <> nil;
      fHasRivalColor := StateRecolorSec.Section['rival'] <> nil;
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
        begin
          try
            aColorDict.Add(ColorSec.LineList[i].ValueNumeric, ColorSec.LineList[i].Keyword);
          except
            on E: Exception do
              raise Exception.CreateFmt('Invalid or duplicate color found in spriteset_recoloring: %s', [ColorSec.LineList[i].Keyword]);
          end;
        end;
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
                try
                  aShadeDict.Add(aLine.ValueNumeric and $FFFFFF, BaseColor);
                except
                  on E: Exception do
                    raise Exception.CreateFmt('Invalid or duplicate color found in shades section: PRIMARY=%d, alt=%d', [BaseColor, aLine.ValueNumeric and $FFFFFF]);
                end;
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
  // Add right- and left-facing version for all skills
  for AnimIndex := 0 to NUM_LEM_SPRITES - 1 do
  begin
    fMetaLemmingAnimations.Add;
  end;

  LoadMetaData(aColorDict, aShadeDict);
end;

procedure TBaseAnimationSet.PrepareAnimations;
var
  LemSprite: TMetaLemmingAnimation;
  SpriteName: string;
  iSprite, LemDXOffset: Integer;
  LemBitmap, TempBitmap: TBitmap32;
  ColorDict: TColorDict;
  ShadeDict: TShadeDict;
  UpscaleInfo: TUpscaleInfo;
  ThemeFolder: String;
  MetaSpritesFolder, LemSpritesFolder: String;
  MasksPath, EffectsPath, DefaultPath: String;

  procedure GetThemeFolder(aDirectory: String; UseLemSpritesTheme: Boolean);
  begin
    if (fTheme = nil) then
      ThemeFolder := SFDefaultStyle
    else if UseLemSpritesTheme then
      ThemeFolder := PieceManager.Dealias(fTheme.Lemmings, rkLemmings).Piece.GS
    else
      ThemeFolder := fTheme.Name;

    if ThemeFolder = '' then
      ThemeFolder := SFDefaultStyle;

    if not DirectoryExists(AppPath + SFStyles + ThemeFolder + aDirectory) then
      ThemeFolder := SFDefaultStyle;
  end;

  procedure UpscalePieces(Bitmap: TBitmap32);
  begin
    UpscaleInfo := PieceManager.GetUpscaleInfo(ThemeFolder, rkLemmings);
    UpscaleFrames(Bitmap, 2, LemSprite.FrameCount, UpscaleInfo.Settings);
  end;

  procedure LoadEffectsFromMasksFolder(const FileName, FileNameHR: string; Bitmap: TBitmap32);
  begin
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(MasksPath + FileNameHR, Bitmap)
    else
      TPngInterface.LoadPngFile(MasksPath + FileName, Bitmap);
  end;

  procedure LoadEffects(const FileName, FileNameHR: string; Bitmap: TBitmap32);
  begin
    if GameParams.HighResolution then // Try high-res first
    begin
      if FileExists(EffectsPath + FileNameHR) then
        TPngInterface.LoadPngFile(EffectsPath + FileNameHR, Bitmap)
      else if FileExists(EffectsPath + FileName) then
      begin // Fallback to upscaled low-res if high-res file not found
        TPngInterface.LoadPngFile(EffectsPath + FileName, Bitmap);
        UpscalePieces(Bitmap);
      end else begin // Fallback to the default path
        if FileExists(DefaultPath + FileNameHR) then
          TPngInterface.LoadPngFile(DefaultPath + FileNameHR, Bitmap)
        else begin
          TPngInterface.LoadPngFile(DefaultPath + FileName, Bitmap);
          UpscalePieces(Bitmap);
        end;
      end;
    end else begin // Then Low-res
      if FileExists(EffectsPath + FileName) then
        TPngInterface.LoadPngFile(EffectsPath + FileName, Bitmap)
      else
        TPngInterface.LoadPngFile(DefaultPath + FileName, Bitmap);
    end;
  end;
begin
  TempBitmap := TBitmap32.Create;
  ColorDict := TColorDict.Create;
  ShadeDict := TShadeDict.Create;

  try
    { ========================= Lemming sprites ============================== }

    GetThemeFolder(SFPiecesLemmings, True);
    SetCurrentDir(AppPath + SFStyles + ThemeFolder + SFPiecesLemmings);

    if (fMetaLemmingAnimations.Count = 0) then
      ReadMetaData(ColorDict, ShadeDict);

    MetaSpritesFolder := AppPath + SFStyles + ThemeFolder + SFPiecesLemmings;

    if GameParams.HighResolution then
      LemSpritesFolder := AppPath + SFStyles + ThemeFolder + SFPiecesLemmingsHighRes
    else
      LemSpritesFolder := MetaSpritesFolder;

    { Load all sprites }
    for iSprite := 0 to NUM_LEM_SPRITES - 1 do
    begin
      LemSprite := fMetaLemmingAnimations[iSprite];
      SpriteName := RightStr(LemSprite.Description, Length(LemSprite.Description) - 1);

      if FileExists(LemSpritesFolder + SpriteName + '.png') then
        TPngInterface.LoadPngFile(LemSpritesFolder + SpriteName + '.png', TempBitmap)
      else begin
        TPngInterface.LoadPngFile(MetaSpritesFolder + SpriteName + '.png', TempBitmap);
        UpscalePieces(TempBitmap);
      end;

      LemSprite.Width := TempBitmap.Width div 2;
      LemSprite.Height := TempBitmap.Height div LemSprite.FrameCount;

      if iSprite mod 2 = 1 then
        LemDXOffset := 0
      else
        LemDXOffset := LemSprite.Width;

      LemBitmap := TBitmap32.Create;
      LemBitmap.SetSize(LemSprite.Width, LemSprite.Height * LemSprite.FrameCount);
      TempBitmap.DrawTo(LemBitmap, 0, 0, Rect(
        LemDXOffset, 0, LemDXOffset + LemSprite.Width, LemSprite.Height * LemSprite.FrameCount));

      fLemmingAnimations.Add(LemBitmap);

      if GameParams.HighResolution then
      begin
        LemSprite.FootX := LemSprite.FootX * 2;
        LemSprite.FootY := LemSprite.FootY * 2;
      end;
    end;

    fRecolorer.LoadSwaps(ThemeFolder);
    HandleRecoloring(ColorDict, ShadeDict);

    { ==================== Effects (countdown digits, etc) =================== }

    fPortalWarpBitmap.DrawMode := dmBlend;
    fPortalWarpBitmap.CombineMode := cmMerge;

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

    fInvincibilityOverlay.DrawMode := dmBlend;
    fInvincibilityOverlay.CombineMode := cmMerge;

    fNumbersBitmap.DrawMode := dmBlend;
    fNumbersBitmap.CombineMode := cmMerge;

    fHighlightBitmap.DrawMode := dmBlend;
    fHighlightBitmap.CombineMode := cmMerge;

    fBalloonPopBitmap.DrawMode := dmBlend;
    fBalloonPopBitmap.CombineMode := cmMerge;

    fExitMarkerNormalBitmap.DrawMode := dmBlend;
    fExitMarkerNormalBitmap.CombineMode := cmMerge;

    fExitMarkerRivalBitmap.DrawMode := dmBlend;
    fExitMarkerRivalBitmap.CombineMode := cmMerge;

    fExitMarkerZombieBitmap.DrawMode := dmBlend;
    fExitMarkerZombieBitmap.CombineMode := cmMerge;

    fGrenadeBitmap.DrawMode := dmBlend;
    fGrenadeBitmap.CombineMode := cmMerge;

    fSpearBitmap.DrawMode := dmBlend;
    fSpearBitmap.CombineMode := cmMerge;

    fIceCubeBitmap.DrawMode := dmBlend;
    fIceCubeBitmap.CombineMode := cmMerge;

    { Non-customisable Effects - these are loaded from the Masks folder }
    MasksPath := AppPath + SFGraphicsMasks;

    LoadEffectsFromMasksFolder('spears.png', 'spears-hr.png', fSpearBitmap);
    LoadEffectsFromMasksFolder('freezer.png', 'freezer-hr.png', fIceCubeBitmap);

    { Customisable Effects - these are replaced with defaults if not present in the spriteset's effects folder }
    GetThemeFolder(SFPiecesEffects, False);
    EffectsPath := AppPath + SFStyles + ThemeFolder + SFPiecesEffects;
    DefaultPath := AppPath + SFStyles + SFDefaultStyle + SFPiecesEffects;

    LoadEffects('portalwarp.png', 'portalwarp-hr.png', fPortalWarpBitmap);
    LoadEffects('countdown.png', 'countdown-hr.png', fCountDownDigitsBitmap);
    LoadEffects('radiation.png', 'radiation-hr.png', fRadiationDigitsBitmap);
    LoadEffects('slowfreeze.png', 'slowfreeze-hr.png', fSlowfreezeDigitsBitmap);
    LoadEffects('numbers.png', 'numbers-hr.png', fNumbersBitmap);
    LoadEffects('highlight.png', 'highlight-hr.png', fHighlightBitmap);
    LoadEffects('grenades.png', 'grenades-hr.png', fGrenadeBitmap);
    LoadEffects('freezing_overlay.png', 'freezing_overlay-hr.png', fFreezingOverlay);
    LoadEffects('unfreezing_overlay.png', 'unfreezing_overlay-hr.png', fUnfreezingOverlay);
    LoadEffects('balloon_pop.png', 'balloon_pop-hr.png', fBalloonPopBitmap);
    LoadEffects('invincibility_overlay.png', 'invincibility_overlay-hr.png', fInvincibilityOverlay);
    LoadEffects('exit_marker_normal.png', 'exit_marker_normal-hr.png', fExitMarkerNormalBitmap);
    LoadEffects('exit_marker_rival.png', 'exit_marker_rival-hr.png', fExitMarkerRivalBitmap);
    LoadEffects('exit_marker_zombie.png', 'exit_marker_zombie-hr.png', fExitMarkerZombieBitmap);
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
  fPortalWarpBitmap.Clear;
  fCountDownDigitsBitmap.Clear;
  fRadiationDigitsBitmap.Clear;
  fSlowfreezeDigitsBitmap.Clear;
  fFreezingOverlay.Clear;
  fUnfreezingOverlay.Clear;
  fInvincibilityOverlay.Clear;
  fNumbersBitmap.Clear;
  fHighlightBitmap.Clear;
  fBalloonPopBitmap.Clear;
  fExitMarkerNormalBitmap.Clear;
  fExitMarkerRivalBitmap.Clear;
  fExitMarkerZombieBitmap.Clear;
  fGrenadeBitmap.Clear;
  fSpearBitmap.Clear;
  fIceCubeBitmap.Clear;
  fHasZombieColor := False;
  fHasNeutralColor := False;
  fHasRivalColor := False;
  fTheme := nil;
end;

constructor TBaseAnimationSet.Create;
begin
  inherited Create;
  fMetaLemmingAnimations := TMetaLemmingAnimations.Create(TMetaLemmingAnimation);
  fLemmingAnimations := TBitmaps.Create;
  fRecolorer := TRecolorImage.Create;
  fPortalWarpBitmap := TBitmap32.Create;
  fCountDownDigitsBitmap := TBitmap32.Create;
  fRadiationDigitsBitmap := TBitmap32.Create;
  fSlowfreezeDigitsBitmap := TBitmap32.Create;
  fFreezingOverlay := TBitmap32.Create;
  fUnfreezingOverlay := TBitmap32.Create;
  fInvincibilityOverlay := TBitmap32.Create;
  fNumbersBitmap := TBitmap32.Create;
  fHighlightBitmap := TBitmap32.Create;
  fBalloonPopBitmap := TBitmap32.Create;
  fExitMarkerNormalBitmap := TBitmap32.Create;
  fExitMarkerRivalBitmap := TBitmap32.Create;
  fExitMarkerZombieBitmap := TBitmap32.Create;
  fGrenadeBitmap := TBitmap32.Create;
  fSpearBitmap := TBitmap32.Create;
  fIceCubeBitmap := TBitmap32.Create;
end;

destructor TBaseAnimationSet.Destroy;
begin
  fMetaLemmingAnimations.Free;
  fLemmingAnimations.Free;
  fPortalWarpBitmap.Free;
  fCountDownDigitsBitmap.Free;
  fRadiationDigitsBitmap.Free;
  fSlowfreezeDigitsBitmap.Free;
  fFreezingOverlay.Free;
  fUnfreezingOverlay.Free;
  fInvincibilityOverlay.Free;
  fNumbersBitmap.Free;
  fHighlightBitmap.Free;
  fBalloonPopBitmap.Free;
  fExitMarkerNormalBitmap.Free;
  fExitMarkerRivalBitmap.Free;
  fExitMarkerZombieBitmap.Free;
  fGrenadeBitmap.Free;
  fSpearBitmap.Free;
  fIceCubeBitmap.Free;
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

{ Grenade and Spear images - for loading & drawing to skill panel & pickups only }

procedure TBaseAnimationSet.LoadGrenadeImages(aBitmap: TBitmap32);
var
  CustomStyle: String;
  CustomStylePath, DefaultStylePath: String;
  Grenades, GrenadesHR: String;
begin
  CustomStyle := GameParams.Renderer.Theme.Lemmings;
  CustomStylePath := AppPath + SFStyles + CustomStyle + SFPiecesEffects;
  DefaultStylePath := AppPath + SFStyles + SFDefaultStyle + SFPiecesEffects;
  Grenades := 'grenades.png';
  GrenadesHR := 'grenades-hr.png';

  if (FileExists(CustomStylePath + Grenades) and FileExists(CustomStylePath + GrenadesHR)) then
  begin
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(CustomStylePath + GrenadesHR, aBitmap)
    else
      TPngInterface.LoadPngFile(CustomStylePath + Grenades, aBitmap);
  end else
  if GameParams.HighResolution then
    TPngInterface.LoadPngFile(DefaultStylePath + GrenadesHR, aBitmap)
  else
    TPngInterface.LoadPngFile(DefaultStylePath + Grenades, aBitmap);
end;

procedure TBaseAnimationSet.LoadSpearImages(aBitmap: TBitmap32);
begin
  if GameParams.HighResolution then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'spears-hr.png', aBitmap)
  else
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'spears.png', aBitmap);
end;

procedure TBaseAnimationSet.DrawProjectilesToBitmap(Src, Dst: TBitmap32; dstX, dstY: Integer; SrcRect: TRect);
begin
  if GameParams.HighResolution then
  begin
    dstX := dstX * 2;
    dstY := dstY * 2;
    SrcRect.Left := SrcRect.Left * 2;
    SrcRect.Top := SrcRect.Top * 2;
    SrcRect.Right := SrcRect.Right * 2;
    SrcRect.Bottom := SrcRect.Bottom * 2;
  end;

  Src.DrawTo(Dst, dstX, dstY, SrcRect);
end;

end.

