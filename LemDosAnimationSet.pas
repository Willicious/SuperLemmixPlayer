{$include lem_directives.inc}
unit LemDosAnimationSet;

interface

uses
  Dialogs,
  Classes, SysUtils,
  UMisc, GR32,
  StrUtils,
  PngInterface,
  LemCore,
  LemTypes,
  LemDosStructures,
  LemDosCmp,
  LemDosBmp,
  LemDosMainDat,
  LemMetaAnimation,
  LemAnimationSet,
  LemNeoParser,
  LemStrings;

const
  LTR = False;
  RTL = True;

const
{-------------------------------------------------------------------------------
  dos animations ordered by their appearance in main.dat
  the constants below show the exact order
-------------------------------------------------------------------------------}
  WALKING             = 0;
  WALKING_RTL         = 1;
  JUMPING             = 2;
  JUMPING_RTL         = 3;
  DIGGING             = 4;
  DIGGING_RTL         = 5;
  CLIMBING            = 6;
  CLIMBING_RTL        = 7;
  DROWNING            = 8;
  DROWNING_RTL        = 9;
  HOISTING            = 10;
  HOISTING_RTL        = 11;
  BRICKLAYING         = 12;
  BRICKLAYING_RTL     = 13;
  BASHING             = 14;
  BASHING_RTL         = 15;
  MINING              = 16;
  MINING_RTL          = 17;
  FALLING             = 18;
  FALLING_RTL         = 19;
  UMBRELLA            = 20;
  UMBRELLA_RTL        = 21;
  SPLATTING           = 22;
  SPLATTING_RTL       = 23;
  EXITING             = 24;
  EXITING_RTL         = 25;
  FRIED               = 26;
  FRIED_RTL           = 27;
  BLOCKING            = 28;
  BLOCKING_RTL        = 29;
  SHRUGGING           = 30;
  SHRUGGING_RTL       = 31;
  OHNOING             = 32;
  OHNOING_RTL         = 33;
  EXPLOSION           = 34;
  EXPLOSION_RTL       = 35;
  PLATFORMING         = 36;
  PLATFORMING_RTL     = 37;
  STONEEXPLOSION      = 38;
  STONEEXPLOSION_RTL  = 39;
  SWIMMING            = 40;
  SWIMMING_RTL        = 41;
  GLIDING             = 42;
  GLIDING_RTL         = 43;
  FIXING              = 44;
  FIXING_RTL          = 45;
  STACKING            = 46;
  STACKING_RTL        = 47;
  STONED              = 48; // this one does NOT need an RTL form; in fact in needs to be moved to the Masks section

  // never made sense to me why it lists the right-facing on the left
  // and the left-facing on the right. Is this standard practice? Maybe
  // I should change it... at some point.
  AnimationIndices : array[TBasicLemmingAction, LTR..RTL] of Integer = (
    (0,0),
    (WALKING, WALKING_RTL),                   // baWalk,
    (JUMPING, JUMPING_RTL),                   // baJumping,
    (DIGGING, DIGGING_RTL),                       // baDigging,
    (CLIMBING, CLIMBING_RTL),                 // baClimbing,
    (DROWNING, DROWNING_RTL),                     // baDrowning,
    (HOISTING, HOISTING_RTL),                 // baHoisting,
    (BRICKLAYING, BRICKLAYING_RTL),           // baBricklaying,
    (BASHING, BASHING_RTL),                   // baBashing,
    (MINING, MINING_RTL),                     // baMining,
    (FALLING, FALLING_RTL),                   // baFalling,
    (UMBRELLA, UMBRELLA_RTL),                 // baUmbrella,
    (SPLATTING, SPLATTING_RTL),                   // baSplatting,
    (EXITING, EXITING_RTL),                       // baExiting,
    (FRIED, FRIED_RTL),                           // baFried,
    (BLOCKING, BLOCKING_RTL),                     // baBlocking,
    (SHRUGGING, SHRUGGING_RTL),               // baShrugging,
    (OHNOING, OHNOING_RTL),                       // baOhnoing,
    (EXPLOSION, EXPLOSION_RTL),                    // baExploding
    (0,0),                                     // baToWalking. Should never happen.
    (PLATFORMING, PLATFORMING_RTL),            // baPlatforming
    (STACKING, STACKING_RTL),                  // baStacking
    (OHNOING, OHNOING_RTL),                        // baStoneOhNoing <-- might be incorrect name so don't rely on this
    (STONEEXPLOSION, STONEEXPLOSION_RTL),          // baStoneFinish
    (SWIMMING, SWIMMING_RTL),                  // baSwimming
    (GLIDING, GLIDING_RTL),                    // baGliding
    (FIXING, FIXING_RTL),                          // baFixing
    (0,0)                                      // baCloning? Another that should never happen
  );


type
  {-------------------------------------------------------------------------------
    Basic animationset for dos.
  -------------------------------------------------------------------------------}
  TBaseDosAnimationSet = class(TBaseAnimationSet)
  private
    fMainDataFile           : string;
    fLemmingPrefix          : string;
    fAnimationPalette       : TArrayOfColor32;
    fExplosionMaskBitmap    : TBitmap32;
    fBashMasksBitmap        : TBitmap32;
    fBashMasksRTLBitmap     : TBitmap32;
    fMineMasksBitmap        : TBitmap32;
    fMineMasksRTLBitmap     : TBitmap32;
    fCountDownDigitsBitmap  : TBitmap32;
    fHighlightBitmap        : TBitmap32;
  protected
    procedure DoReadMetaData(XmasPal : Boolean = false); override;
    procedure DoReadData; override;
    procedure DoClearData; override;
  public
    constructor Create; override;
  { easy references, these point to the MaskAnimations[0..5] }
    property ExplosionMaskBitmap   : TBitmap32 read fExplosionMaskBitmap;
    property BashMasksBitmap       : TBitmap32 read fBashMasksBitmap;
    property BashMasksRTLBitmap    : TBitmap32 read fBashMasksRTLBitmap;
    property MineMasksBitmap       : TBitmap32 read fMineMasksBitmap;
    property MineMasksRTLBitmap    : TBitmap32 read fMineMasksRTLBitmap;
    property CountDownDigitsBitmap : TBitmap32 read fCountDownDigitsBitmap;
    property HighlightBitmap       : TBitmap32 read fHighlightBitmap;
    property AnimationPalette: TArrayOfColor32 read fAnimationPalette write fAnimationPalette;
    property LemmingPrefix: string write fLemmingPrefix;
  published
    property MainDataFile: string read fMainDataFile write fMainDataFile; // must be set by style
  end;

implementation

{ TBaseDosAnimationSet }

procedure TBaseDosAnimationSet.DoReadMetaData(XmasPal : Boolean = false);
{-------------------------------------------------------------------------------
  We dont have to read. It's fixed in this order in the main.dat.
  foot positions from ccexpore's emails, see lemming_mechanics pseudo code

  o make lemming animations
  o make mask animations metadata
-------------------------------------------------------------------------------}

    procedure Lem(aFrameCount, aAnimType: Integer);
    begin
      // Frame count:
      // If a value is specified, the animation must have exactly that many frames
      // If it's zero, any number of frames is allowed

      // Floater and Glider must have a minimum of 10 frames, but can have more. This is
      // handled when loading the animations.
      with fMetaLemmingAnimations.Add do
      begin
        FrameCount         := aFrameCount;
        AnimationType      := aAnimType;
      end;
    end;

    procedure Msk(aImageLocation: Integer; const aDescription: string;
      aFrameCount, aWidth, aHeight, aBPP: Integer);
    begin
      with fMetaMaskAnimations.Add do
      begin
        ImageLocation      := aImageLocation;
        Description        := aDescription;
        FrameCount         := aFrameCount;
        Width              := aWidth;
        Height             := aHeight;
        BitsPerPixel       := aBPP;
      end;
    end;

begin

  // Due to dynamic loading, only two values are needed here: Whether it's looping or
  // not, and the frame count. If the frame count is zero, even that can be dynamically
  // loaded; this is usually for animations where the graphic has no impact on the
  // physics (such as walkers).

  // Eventually, this should be changed so that even animations that do currently impact
  // physics can have a different number of frames without impact.

  // Note that currently, floater and glider have a minimum of 10 frames; this is handled
  // elsewhere.

  Lem(0, lat_Loop); //Rwalker
  Lem(0, lat_Loop); //Lwalker
  Lem(0, lat_Loop); //Rjumper
  Lem(0, lat_Loop); //Ljumper
  Lem(16, lat_Loop); //Rdigger
  Lem(16, lat_Loop); //Ldigger
  Lem(8, lat_Loop); //Rclimber
  Lem(8, lat_Loop); //Lclimber
  Lem(16, lat_Once); //Rdrowner
  Lem(16, lat_Once); //Ldrowner
  Lem(8, lat_Once); //Rhoister
  Lem(8, lat_Once); //Lhoister
  Lem(16, lat_Loop); //Rbuilder
  Lem(16, lat_Loop); //Lbuilder
  Lem(32, lat_Loop); //Rbasher
  Lem(32, lat_Loop); //Lbasher
  Lem(24, lat_Loop); //Rminer
  Lem(24, lat_Loop); //Lminer
  Lem(0, lat_Loop); //Rfaller
  Lem(0, lat_Loop); //Lfaller
  Lem(0, lat_Loop); //Rfloater
  Lem(0, lat_Loop); //Lfloater
  Lem(16, lat_Once); //Rsplatter
  Lem(16, lat_Once); //Lsplatter
  Lem(8, lat_Once); //Rexiter
  Lem(8, lat_Once); //Lexiter
  Lem(14, lat_Once); //Rburner
  Lem(14, lat_Once); //Lburner
  Lem(0, lat_Loop); //Rblocker
  Lem(0, lat_Loop); //Lblocker
  Lem(8, lat_Once); //Rshrugger
  Lem(8, lat_Once); //Lshrugger
  Lem(16, lat_Once); //Rohnoer
  Lem(16, lat_Once); //Lohnoer
  Lem(1, lat_Once); //Rbomber
  Lem(1, lat_Once); //Lbomber
  Lem(16, lat_Loop); //Rplatformer
  Lem(16, lat_Loop); //Lplatformer
  Lem(1, lat_Once); //Rstoner
  Lem(1, lat_Once); //Lstoner
  Lem(8, lat_Loop); //Rswimmer
  Lem(8, lat_Loop); //Lswimmer
  Lem(17, lat_Loop); //Rglider
  Lem(17, lat_Loop); //Lglider
  Lem(16, lat_Loop); //Rdisarmer
  Lem(16, lat_Loop); //Ldisarmer
  Lem(8, lat_Loop); //Rstacker
  Lem(8, lat_Loop); //Lstacker
  Lem(1, lat_Once); //  This one is a placeholder for the stoner mask, I can't remember why it's in here but it is. I need to fix that.

  if fMetaLemmingAnimations.Count <> 49 then
    ShowMessage('Missing an animation? Total: ' + IntToStr(fMetaLemmingAnimations.Count));

  with fMetaLemmingAnimations[48] do
  begin
    FootX := 8;
    FootY := 10;
    // not sure if these values are needed, but better safe than sorry until tested (and ideally, the dependancy on them resolved)
  end;

  //  place   description            F   W   H  BPP

  Msk($0000, 'Bashmasks'         ,   4, 16, 10,  19);
  Msk($05F0, 'Bashmasks (rtl)'   ,   4, 16, 10,  19);
  Msk($0BE0, 'Minemasks'         ,   2, 16, 13,  19);
  Msk($0FBC, 'Minemasks (rtl)'   ,   2, 16, 13,  19);
  Msk($1398, 'Explosionmask'     ,   1, 16, 22,  19);
  Msk($16DC, 'Countdown digits'  ,  10,  8,  8,  19); // 10 digits
  Msk($1CCC, 'Highlight icon'    ,   1,  8,  8,  19);
end;

procedure TBaseDosAnimationSet.DoReadData;
var
  Fn: string;
  Bmp: TBitmap32;
  TempBitmap: TBitmap32;
  iAnimation, i: Integer;
  MLA: TMetaLemmingAnimation;
  X: Integer;
  Pal: TArrayOfColor32;
  MainExtractor: TMainDatExtractor;

  procedure LoadPositionData;
  const
    // These match the order these are stored by this class. They do NOT have to be in this
    // order in "scheme.nxmi", they just have to all be there.

    ANIM_NAMES: array[0..23] of String =  ('WALKER', 'JUMPER', 'DIGGER', 'CLIMBER',
                                           'DROWNER', 'HOISTER', 'BUILDER', 'BASHER',
                                           'MINER', 'FALLER', 'FLOATER', 'SPLATTER',
                                           'EXITER', 'BURNER', 'BLOCKER', 'SHRUGGER',
                                           'OHNOER', 'BOMBER', 'PLATFORMER', 'STONER',
                                           'SWIMMER', 'GLIDER', 'DISARMER', 'STACKER');
    DIR_NAMES: array[0..1] of String = ('RIGHT', 'LEFT');
  var
    Parser: TParser;
    AnimSec: TParserSection;
    ThisAnimSec: TParserSection;
    DirSec: TParserSection;
    i: Integer;
    dx: Integer;

    Anim: TMetaLemmingAnimation;
  begin
    Parser := TParser.Create;
    try
      Parser.LoadFromFile('scheme.nxmi');
      AnimSec := Parser.MainSection.Section['animations'];
      for i := 0 to 23 do
      begin
        ThisAnimSec := AnimSec.Section[ANIM_NAMES[i]];
        for dx := 0 to 1 do
        begin
          DirSec := ThisAnimSec.Section[DIR_NAMES[dx]];
          Anim := fMetaLemmingAnimations[(i * 2) + dx];

          if Anim.FrameCount = 0 then Anim.FrameCount := ThisAnimSec.LineNumeric['frames'];
          Anim.FootX := DirSec.LineNumeric['foot_x'];
          Anim.FootY := DirSec.LineNumeric['foot_y'];
          Anim.Description := LeftStr(DIR_NAMES[dx], 1) + ANIM_NAMES[i];
        end;
      end;
    except
      raise Exception.Create('TBaseDosAnimationSet: Error loading lemming animation metadata for ' + ANIM_NAMES[i] + '.');
    end;
    Parser.Free;
  end;

begin
  // fried and or vaporizing has high color indices
  Assert(Length(AnimationPalette) >= 16);
  Pal := Copy(fAnimationPalette);

  Fn := MainDataFile;
  TempBitmap := TBitmap32.Create;
  MainExtractor := TMainDatExtractor.Create;

  // MEGA KLUDGY compatibility hack. This must be tidied later!
  if fLemmingPrefix = 'lemming' then fLemmingPrefix := 'default';
  if fLemmingPrefix = 'xlemming' then fLemmingPrefix := 'xmas';

  if fMetaLemmingAnimations.Count = 0 then
    ReadMetaData;

  SetCurrentDir(AppPath + SFStyles + fLemmingPrefix + SFPiecesLemmings);

  try
      LoadPositionData;

      with fMetaLemmingAnimations do
        for iAnimation := 0 to Count-2 do // -2 to leave out the stoner placeholder
        begin
          MLA := fMetaLemmingAnimations[iAnimation];
          Fn := RightStr(MLA.Description, Length(MLA.Description)-1);

          TPngInterface.LoadPngFile(Fn + '.png', TempBitmap);
          if FileExists(Fn + '_mask.png') then
            TPngInterface.MaskImageFromFile(TempBitmap, AppPath + 'gfx/sprites/' + fLemmingPrefix + '/' + Fn + '_mask.png', Pal[7]);

          MLA.Width := TempBitmap.Width div 2;
          MLA.Height := TempBitmap.height div MLA.FrameCount;

          if iAnimation mod 2 = 0 then
            X := 0
          else
            X := MLA.Width;

          Bmp := TBitmap32.Create;
          Bmp.SetSize(MLA.Width, MLA.Height * MLA.FrameCount);
          TempBitmap.DrawTo(Bmp, 0, 0, Rect(X, 0, X + MLA.Width, MLA.Height * MLA.FrameCount));
          fLemmingAnimations.Add(Bmp);
        end;

    // // // // // // // // // // // //
    // Extract masks / Digits / etc. //
    // // // // // // // // // // // //

      // refer the "easy access" bitmaps
      for i := 0 to 6 do
        fMaskAnimations.Add(TBitmap32.Create);
      fLemmingAnimations.Add(TBitmap32.Create); // for the Stoner
      fBashMasksBitmap := fMaskAnimations[0];
      fBashMasksRTLBitmap := fMaskAnimations[1];
      fMineMasksBitmap := fMaskAnimations[2];
      fMineMasksRTLBitmap := fMaskAnimations[3];
      fExplosionMaskBitmap := fMaskAnimations[4];
      fCountDownDigitsBitmap := fMaskAnimations[5];
      fCountdownDigitsBitmap.DrawMode := dmBlend;
      fHighlightBitmap := fMaskAnimations[6];
      fHighlightBitmap.DrawMode := dmBlend;

        // Stoner, Bomber and Highlight are a single frame each so easy enough
        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/bomber.png', fExplosionMaskBitmap);
        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/stoner.png', fLemmingAnimations[STONED]);
        with fMetaLemmingAnimations[STONED] do
        begin
          Width := fLemmingAnimations[STONED].Width;
          Height := fLemmingAnimations[STONED].Height;
        end;
        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/highlight.png', fHighlightBitmap);

        fLemmingAnimations[STONED].DrawMode := dmBlend;

        // Basher and miner are a tad more complicated
        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/basher.png', TempBitmap);
        fBashMasksRTLBitmap.SetSize(16, 40);
        fBashMasksBitmap.SetSize(16, 40);
        TempBitmap.DrawTo(fBashMasksRTLBitmap, 0, 0, Rect(0, 0, 16, 40));
        TempBitmap.DrawTo(fBashMasksBitmap, 0, 0, Rect(16, 0, 32, 40));

        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/miner.png', TempBitmap);
        fMineMasksRTLBitmap.SetSize(16, 26);
        fMineMasksBitmap.SetSize(16, 26);
        TempBitmap.DrawTo(fMineMasksRTLBitmap, 0, 0, Rect(0, 0, 16, 26));
        TempBitmap.DrawTo(fMineMasksBitmap, 0, 0, Rect(16, 0, 32, 26));

        // And countdown digits are the most complicated of all (or not, anymore...)
        TPngInterface.LoadPngFile(AppPath + 'gfx/mask/countdown.png', fCountdownDigitsBitmap);
        (*fCountdownDigitsBitmap.SetSize(8, 80);
        fCountdownDigitsBitmap.Clear(0);
        for i := 0 to 9 do
          TempBitmap.DrawTo(fCountdownDigitsBitmap, 0, (9-i)*8, Rect(i*4, 0, (i+1)*4, 8));*)

  finally
    TempBitmap.Free;
    MainExtractor.Free;
  end;
end;


procedure TBaseDosAnimationSet.DoClearData;
begin
  fLemmingAnimations.Clear;
  fMetaLemmingAnimations.Clear;
  fMaskAnimations.Clear;
  fExplosionMaskBitmap    := nil;
  fBashMasksBitmap        := nil;
  fBashMasksRTLBitmap     := nil;
  fMineMasksBitmap        := nil;
  fMineMasksRTLBitmap     := nil;
  fCountDownDigitsBitmap  := nil;
  fHighlightBitmap        := nil;
  fLemmingPrefix := 'lemming';
end;

constructor TBaseDosAnimationSet.Create;
begin
  inherited Create;
end;


end.

