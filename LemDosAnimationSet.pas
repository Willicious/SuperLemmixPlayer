{$include lem_directives.inc}
unit LemDosAnimationSet;

interface

uses
  Dialogs,
  Classes, SysUtils,
  UMisc, GR32,
  StrUtils,
  LemCore,
  LemTypes,
  LemDosStructures,
  LemDosCmp,
  LemDosBmp,
  LemDosMainDat,
  LemMetaAnimation,
  LemAnimationSet,
  LemNeoEncryption;

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

    procedure Lem(aImageLocation: Integer; const aDescription: string;
      aFrameCount, aWidth, aHeight, aBPP, aFootX, aFootY, aAnimType: Integer);
    begin
      with fMetaLemmingAnimations.Add do
      begin
        ImageLocation      := aImageLocation;
        Description        := aDescription;
        FrameCount         := aFrameCount;
        Width              := aWidth;
        Height             := aHeight;
        BitsPerPixel       := aBPP;
        FootX              := aFootX;
        FootY              := aFootY;
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

  // Description is used for new PNG system to identify the files.
  // First letter specifies the direction to load! The rest is the
  // filename without extension. Note that many left-facing ones are
  // currently unused; use of them will be implemented once MAIN.DAT
  // is completely dropped.
  // This doesn't apply to masks; they're hardcoded further down.
  //  place   description            F   W   H  BPP   FX   FY   animationtype

  Lem($0000, 'Rwalker'            ,   8, 16, 10,  19,   8,  10,   lat_Loop); // 0
  Lem($0D5C, 'Lwalker'            ,   8, 16, 10,  19,   9,  10,   lat_Loop);
  Lem($0BE0, 'Rjumper'            ,   1, 16, 10,  19,   8,  10,   lat_Loop);
  Lem($193C, 'Ljumper'            ,   1, 16, 10,  19,   9,  10,   lat_Loop);
  Lem($1AB8, 'Rdigger'            ,  16, 16, 14,  19,   8,  12,   lat_Loop);
  Lem($1AB8, 'Ldigger'            ,  16, 16, 14,  19,   9,  12,   lat_Loop);
  Lem($3BF8, 'Rclimber'           ,   8, 16, 12,  19,   8,  12,   lat_Loop);
  Lem($4A38, 'Lclimber'           ,   8, 16, 12,  19,   8,  12,   lat_Loop);
  Lem($5878, 'Rdrowner'           ,  16, 16, 10,  19,   8,  10,   lat_Once);
  Lem($5878, 'Ldrowner'           ,  16, 16, 10,  19,   9,  10,   lat_Once);
  Lem($7038, 'Rhoister'           ,   8, 16, 12,  19,   8,  12,   lat_Once);
  Lem($7E78, 'Lhoister'           ,   8, 16, 12,  19,   8,  12,   lat_Once);
  Lem($8CB8, 'Rbuilder'           ,  16, 16, 13,  19,   8,  13,   lat_Loop);
  Lem($AB98, 'Lbuilder'           ,  16, 16, 13,  19,   9,  13,   lat_Loop);
  Lem($CA78, 'Rbasher'            ,  32, 16, 10,  19,   8,  10,   lat_Loop);
  Lem($F9F8, 'Lbasher'            ,  32, 16, 10,  19,   7,  10,   lat_Loop);
  Lem($12978, 'Rminer'            ,  24, 16, 13,  19,   8,  13,   lat_Loop);
  Lem($157C8, 'Lminer'            ,  24, 16, 13,  19,   7,  13,   lat_Loop);
  Lem($18618, 'Rfaller'           ,   4, 16, 10,  19,   7,  10,   lat_Loop);
  Lem($18C08, 'Lfaller'           ,   4, 16, 10,  19,   9,  10,   lat_Loop);
  Lem($191F8, 'Rfloater'       ,  17, 16, 16,  19,   7,  16,   lat_Loop);
  Lem($1A4F8, 'Lfloater'       ,  17, 16, 16,  19,   9,  16,   lat_Loop);
  Lem($1B7F8, 'Rsplatter'         ,  16, 16, 10,  19,   7,  10,   lat_Once);
  Lem($1B7F8, 'Lsplatter'         ,  16, 16, 10,  19,   8,  10,   lat_Once);
  Lem($1CFB8, 'Rexiter'           ,   8, 16, 13,  19,   6,  13,   lat_Once);
  Lem($1CFB8, 'Lexiter'           ,   8, 16, 13,  19,   7,  13,   lat_Once);
  Lem($1DF28, 'Rburner'           ,  14, 16, 14,  19,   8,  14,   lat_Once);
  Lem($1DF28, 'Lburner'           ,  14, 16, 14,  19,   9,  14,   lat_Once);
  Lem($1FC40, 'Rblocker'          ,  16, 16, 10,  19,   8,  10,   lat_Loop);
  Lem($1FC40, 'Lblocker'          ,  16, 16, 10,  19,   9,  10,   lat_Loop);
  Lem($21400, 'Rshrugger'         ,   8, 16, 10,  19,   8,  10,   lat_Once);
  Lem($21FE0, 'Lshrugger'         ,   8, 16, 10,  19,   8,  10,   lat_Once);
  Lem($22BC0, 'Rohnoer'           ,  16, 16, 10,  19,   7,  10,   lat_Once);
  Lem($22BC0, 'Lohnoer'           ,  16, 16, 10,  19,   8,  10,   lat_Once);
  Lem($24380, 'Rbomber'           ,   1, 32, 32,  19,  16,  25,   lat_Once);
  Lem($24380, 'Lbomber'           ,   1, 32, 32,  19,  16,  25,   lat_Once);
  Lem($24D00, 'Rplatformer'       ,  16, 16, 14,  19,   8,  13,   lat_Loop);
  Lem($26E40, 'Lplatformer'       ,  16, 16, 14,  19,   9,  13,   lat_Loop);
  Lem($28F80, 'Rstoner'           ,   1, 32, 32,  19,  16,  25,   lat_Once); //30
  Lem($28F80, 'Lstoner'           ,   1, 32, 32,  19,  16,  25,   lat_Once); //30
  Lem($29AA2, 'Rswimmer'          ,   8, 16, 10,  19,   8,   8,   lat_Loop);
  Lem($2A682, 'Lswimmer'          ,   8, 16, 10,  19,   7,   8,   lat_Loop);
  Lem($2B262, 'Rglider'        ,  17, 16, 16,  19,   7,  16,   lat_Loop);
  Lem($2C562, 'Lglider'        ,  17, 16, 16,  19,   9,  16,   lat_Loop);
  Lem($2D862, 'Rdisarmer'         ,  16, 16, 14,  19,   8,  12,   lat_Loop);
  Lem($2D862, 'Ldisarmer'         ,  16, 16, 14,  19,   9,  12,   lat_Loop);
  Lem($8CB8, 'Rstacker'        ,   8, 16, 13,  19,   8,  13,   lat_Loop); // MAIN.DAT doesn't have seperate anims for builder and
  Lem($AB98, 'Lstacker'        ,   8, 16, 13,  19,   9,  13,   lat_Loop); // stacker; only PNG files support this
  Lem($29900, 'pass'              ,   1, 16, 11,  19,   8,  10,   lat_Once);   // Stoner terrain image; this is loaded among masks

  if fMetaLemmingAnimations.Count <> 49 then
    ShowMessage('Missing an animation? Total: ' + IntToStr(fMetaLemmingAnimations.Count)); 

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
  iAnimation, iFrame, i: Integer;
  MLA: TMetaLemmingAnimation;
  MA: TMetaAnimation;
  X, Y: Integer;
  Pal: TArrayOfColor32;
  MainExtractor: TMainDatExtractor;

begin
  // fried and or vaporizing has high color indices
  Assert(Length(AnimationPalette) >= 16);
  Pal := Copy(fAnimationPalette);

  Fn := MainDataFile;
  TempBitmap := TBitmap32.Create;
  MainExtractor := TMainDatExtractor.Create;

  if fMetaLemmingAnimations.Count = 0 then
    ReadMetaData;

  try

      with fMetaLemmingAnimations do
        for iAnimation := 0 to Count-1 do
        begin
          MLA := fMetaLemmingAnimations[iAnimation];
          if MLA.Description = 'pass' then Continue;          
          Fn := fLemmingPrefix + '_' + RightStr(MLA.Description, Length(MLA.Description)-1) + '.png';
          if MLA.Description[1] = 'L' then
            X := 0
          else
            X := MLA.Width;
          MainExtractor.ExtractBitmapByName(TempBitmap, Fn, Pal[7]);
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
      fHighlightBitmap := fMaskAnimations[6];

        // Stoner, Bomber and Highlight are a single frame each so easy enough
        MainExtractor.ExtractBitmapByName(fExplosionMaskBitmap, 'mask_bomber.png');
        MainExtractor.ExtractBitmapByName(fLemmingAnimations[STONED], 'mask_stoner.png');
        MainExtractor.ExtractBitmapByName(fHighlightBitmap, 'highlight.png');

        // Basher and miner are a tad more complicated
        MainExtractor.ExtractBitmapByName(TempBitmap, 'mask_basher.png');
        fBashMasksRTLBitmap.SetSize(16, 40);
        fBashMasksBitmap.SetSize(16, 40);
        TempBitmap.DrawTo(fBashMasksRTLBitmap, 0, 0, Rect(0, 0, 16, 40));
        TempBitmap.DrawTo(fBashMasksBitmap, 0, 0, Rect(16, 0, 32, 40));

        MainExtractor.ExtractBitmapByName(TempBitmap, 'mask_miner.png');
        fMineMasksRTLBitmap.SetSize(16, 26);
        fMineMasksBitmap.SetSize(16, 26);
        TempBitmap.DrawTo(fMineMasksRTLBitmap, 0, 0, Rect(0, 0, 16, 26));
        TempBitmap.DrawTo(fMineMasksBitmap, 0, 0, Rect(16, 0, 32, 26));

        // And countdown digits are the most complicated of all
        MainExtractor.ExtractBitmapByName(TempBitmap, 'countdown_digits.png');
        fCountdownDigitsBitmap.SetSize(8, 80);
        fCountdownDigitsBitmap.Clear(0);
        for i := 0 to 9 do
          TempBitmap.DrawTo(fCountdownDigitsBitmap, 0, (9-i)*8, Rect(i*4, 0, (i+1)*4, 8));

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

