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
  dos animations ordered by their appearance in main.dat
  the constants below show the exact order
-------------------------------------------------------------------------------}
  //MUST MATCH BELOW (not the next list, the one after that)
  //And don't forget to update the numbers! ;P
  NUM_LEM_SPRITES     = 81;   //num lem sprites
  NUM_LEM_SPRITE_TYPE = 40;        //num lem sprite types
  WALKING             = 0;    //1  //1
  WALKING_RTL         = 1;    //2
  ASCENDING           = 2;    //3  //2
  ASCENDING_RTL       = 3;    //4
  DIGGING             = 4;    //5  //3
  DIGGING_RTL         = 5;    //6
  CLIMBING            = 6;    //7  //4
  CLIMBING_RTL        = 7;    //8
  DROWNING            = 8;    //9  //5
  DROWNING_RTL        = 9;    //10
  HOISTING            = 10;   //11 //6
  HOISTING_RTL        = 11;   //12
  BRICKLAYING         = 12;   //13 //7
  BRICKLAYING_RTL     = 13;   //14
  BASHING             = 14;   //15 //8
  BASHING_RTL         = 15;   //16
  MINING              = 16;   //17 //9
  MINING_RTL          = 17;   //18
  FALLING             = 18;   //19 //10
  FALLING_RTL         = 19;   //20
  UMBRELLA            = 20;   //21 //11
  UMBRELLA_RTL        = 21;   //22
  SPLATTING           = 22;   //23 //12
  SPLATTING_RTL       = 23;   //24
  EXITING             = 24;   //25 //13
  EXITING_RTL         = 25;   //26
  VAPORIZING          = 26;   //27 //14
  VAPORIZING_RTL      = 27;   //28
  VINETRAPPING        = 28;   //29 //15
  VINETRAPPING_RTL    = 29;   //30
  BLOCKING            = 30;   //31 //16
  BLOCKING_RTL        = 31;   //32
  SHRUGGING           = 32;   //33 //17
  SHRUGGING_RTL       = 33;   //34
  TIMEBOMBEXPLOSION   = 34;   //35 //18
  TIMEBOMBEXPLOSION_RTL= 35;  //36
  OHNOING             = 36;   //37 //19
  OHNOING_RTL         = 37;   //38
  EXPLOSION           = 38;   //39 //20
  EXPLOSION_RTL       = 39;   //40
  PLATFORMING         = 40;   //41 //21
  PLATFORMING_RTL     = 41;   //42
  FREEZING            = 42;   //43 //22
  FREEZING_RTL        = 43;   //44
  FREEZEREXPLOSION    = 44;   //45 //23
  FREEZEREXPLOSION_RTL= 45;   //46
  FROZEN              = 46;   //47 //24
  FROZEN_RTL          = 47;   //48
  UNFREEZING          = 48;   //49 //25
  UNFREEZING_RTL      = 49;   //50
  SWIMMING            = 50;   //51 //26
  SWIMMING_RTL        = 51;   //52
  GLIDING             = 52;   //53 //27
  GLIDING_RTL         = 53;   //54
  FIXING              = 54;   //55 //28
  FIXING_RTL          = 55;   //56
  STACKING            = 56;   //57 //29
  STACKING_RTL        = 57;   //58
  FENCING             = 58;   //59 //30
  FENCING_RTL         = 59;   //60
  REACHING            = 60;   //61 //31
  REACHING_RTL        = 61;   //62
  SHIMMYING           = 62;   //63 //32
  SHIMMYING_RTL       = 63;   //64
  JUMPING             = 64;   //65 //33
  JUMPING_RTL         = 65;   //66
  DEHOISTING          = 66;   //67 //34
  DEHOISTING_RTL      = 67;   //68
  SLIDING             = 68;   //69 //35
  SLIDING_RTL         = 69;   //70
  DANGLING            = 70;   //71 //36
  DANGLING_RTL        = 71;   //72
  THROWING            = 72;   //73 //37
  THROWING_RTL        = 73;   //74
  LOOKING             = 74;   //75 //38
  LOOKING_RTL         = 75;   //76
  LASERING            = 76;   //77 //39
  LASERING_RTL        = 77;   //78
  SLEEPING            = 78;   //79 //40
  SLEEPING_RTL        = 79;   //80
  ICECUBE             = 80;   //81 this one does NOT need an RTL form;
                              //in fact in needs to be moved to the Masks section
                              //also, it's not counted as a "sprite type"

  //This one must match TBasicLemmingAction in LemCore / LemStrings
  AnimationIndices : array[TBasicLemmingAction, LTR..RTL] of Integer = (
    (0,0),                                    // 1 baNone
    (WALKING, WALKING_RTL),                   // 2 baWalk,
    (ASCENDING, ASCENDING_RTL),               // 3 baAscending,
    (DIGGING, DIGGING_RTL),                   // 4 baDigging,
    (CLIMBING, CLIMBING_RTL),                 // 5 baClimbing,
    (DROWNING, DROWNING_RTL),                 // 6 baDrowning,
    (HOISTING, HOISTING_RTL),                 // 7 baHoisting,
    (BRICKLAYING, BRICKLAYING_RTL),           // 8 baBricklaying,
    (BASHING, BASHING_RTL),                   // 9 baBashing,
    (MINING, MINING_RTL),                     // 10 baMining,
    (FALLING, FALLING_RTL),                   // 11 baFalling,
    (UMBRELLA, UMBRELLA_RTL),                 // 12 baUmbrella,
    (SPLATTING, SPLATTING_RTL),               // 13 baSplatting,
    (EXITING, EXITING_RTL),                   // 14 baExiting,
    (VAPORIZING, VAPORIZING_RTL),             // 15 baVaporizing,
    (VINETRAPPING, VINETRAPPING_RTL),         // 16 baVinetrapping,
    (BLOCKING, BLOCKING_RTL),                 // 17 baBlocking,
    (SHRUGGING, SHRUGGING_RTL),               // 18 baShrugging,
    (OHNOING, OHNOING_RTL),                   // 19 baTimebombing,
    (TIMEBOMBEXPLOSION, TIMEBOMBEXPLOSION_RTL), // 20 baTimebombFinish,
    (OHNOING, OHNOING_RTL),                   // 21 baOhnoing,
    (EXPLOSION, EXPLOSION_RTL),               // 22 baExploding,
    (0,0),                                    // 23 baToWalking. Should never happen.
    (PLATFORMING, PLATFORMING_RTL),           // 24 baPlatforming
    (STACKING, STACKING_RTL),                 // 25 baStacking
    (FREEZING, FREEZING_RTL),                 // 26 baFreezing
    (FREEZEREXPLOSION, FREEZEREXPLOSION_RTL), // 27 baFreezerExplosion
    (FROZEN, FROZEN_RTL),                     // 28 baFrozen
    (UNFREEZING, UNFREEZING_RTL),             // 29 baUnfreezing
    (SWIMMING, SWIMMING_RTL),                 // 30 baSwimming
    (GLIDING, GLIDING_RTL),                   // 31 baGliding
    (FIXING, FIXING_RTL),                     // 32 baFixing
    (0,0),                                    // 33 baCloning? Another that should never happen
    (FENCING, FENCING_RTL),                   // 34 baFencing
    (REACHING, REACHING_RTL),                 // 35 baReaching (for shimmier)
    (SHIMMYING, SHIMMYING_RTL),               // 36 baShimmying
    (JUMPING, JUMPING_RTL),                   // 37 baJumping
    (DEHOISTING, DEHOISTING_RTL),             // 38 baDehoisting
    (SLIDING, SLIDING_RTL),                   // 39 baSliding
    (DANGLING, DANGLING_RTL),                 // 40 baDangling
    (THROWING, THROWING_RTL),                 // 41 baSpearing
    (THROWING, THROWING_RTL),                 // 42 baGrenading
    (LOOKING, LOOKING_RTL),                   // 43 baLooking
    (LASERING, LASERING_RTL),                 // 44 baLasering
    (SLEEPING, SLEEPING_RTL)                  // 45 baSleeping
  );

type
  {-------------------------------------------------------------------------------
    Basic animationset for dos.
  -------------------------------------------------------------------------------}
  TBaseAnimationSet = class(TPersistent)
  private
    fMetaLemmingAnimations : TMetaLemmingAnimations; // meta data lemmings
    fLemmingAnimations     : TBitmaps; // the list of lemmings bitmaps

    fCountDownDigitsBitmap  : TBitmap32;
    fFreezingOverlay        : TBitmap32;
    fUnfreezingOverlay      : TBitmap32;
    fHatchNumbersBitmap     : TBitmap32;
    fHighlightBitmap        : TBitmap32;
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
    property FreezingOverlay       : TBitmap32 read fFreezingOverlay;
    property UnfreezingOverlay     : TBitmap32 read fUnfreezingOverlay;
    property HatchNumbersBitmap    : TBitmap32 read fHatchNumbersBitmap;
    property HighlightBitmap       : TBitmap32 read fHighlightBitmap;
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
  ANIM_NAMES: array[0..39] of String =  (
  'WALKER',        //1
  'ASCENDER',      //2
  'DIGGER',        //3
  'CLIMBER',       //4
  'DROWNER',       //5
  'HOISTER',       //6
  'BUILDER',       //7
  'BASHER',        //8
  'MINER',         //9
  'FALLER',        //10
  'FLOATER',       //11
  'SPLATTER',      //12
  'EXITER',        //13
  'BURNER',        //14 //aka Vaporizer
  'VINETRAPPER',   //15
  'BLOCKER',       //16
  'SHRUGGER',      //17
  'TIMEBOMBER',    //18
  'OHNOER',        //19
  'BOMBER',        //20
  'PLATFORMER',    //21
  'FREEZING',      //22
  'FREEZER',       //23
  'FROZEN',        //24
  'UNFREEZING',    //25
  'SWIMMER',       //26
  'GLIDER',        //27
  'DISARMER',      //28
  'STACKER',       //29
  'FENCER',        //30
  'REACHER',       //31
  'SHIMMIER',      //32
  'JUMPER',        //33
  'DEHOISTER',     //34
  'SLIDER',        //35
  'DANGLER',       //36
  'THROWER',       //37
  'LOOKER',        //38
  'LASERER',       //39
  'SLEEPER'        //40
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
  Freeze, Unfreeze: String;
  FreezingOverlay, CustomFreezingOverlay: String;
  UnfreezingOverlay, CustomUnfreezingOverlay: String;
  X: Integer;

  SrcFolder: String;
  ColorDict: TColorDict;
  ShadeDict: TShadeDict;

  MetaSrcFolder, ImgSrcFolder: String;

  Info: TUpscaleInfo;

  procedure UpscalePieces;
  begin
    Info := PieceManager.GetUpscaleInfo(SrcFolder, rkLemmings);
    UpscaleFrames(TempBitmap, 2, MLA.FrameCount, Info.Settings);
  end;
begin
  TempBitmap := TBitmap32.Create;
  ColorDict := TColorDict.Create;
  ShadeDict := TShadeDict.Create;

  try
    if (fTheme = nil) then //or (GameParams.ForceDefaultLemmings) then
      SrcFolder := 'default'
    else
      SrcFolder := PieceManager.Dealias(fTheme.Lemmings, rkLemmings).Piece.GS;

    if SrcFolder = '' then SrcFolder := 'default';
    if not DirectoryExists(AppPath + SFStyles + SrcFolder + SFPiecesLemmings) then
      SrcFolder := 'default';

    SetCurrentDir(AppPath + SFStyles + SrcFolder + SFPiecesLemmings);

    if fMetaLemmingAnimations.Count = 0 then // not entirely sure why it would ever NOT be 0
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
        UpscalePieces;
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

    fLemmingAnimations.Add(TBitmap32.Create); // for the Freezer

    // // // // // // // // // // // //
    // Extract masks / Digits / etc. //
    // // // // // // // // // // // //

    fCountDownDigitsBitmap.DrawMode := dmBlend;
    fCountDownDigitsBitmap.CombineMode := cmMerge;

    fFreezingOverlay.DrawMode := dmBlend;
    fFreezingOverlay.CombineMode := cmMerge;

    fUnfreezingOverlay.DrawMode := dmBlend;
    fUnfreezingOverlay.CombineMode := cmMerge;

    fHatchNumbersBitmap.DrawMode := dmBlend;
    fHatchNumbersBitmap.CombineMode := cmMerge;

    fHighlightBitmap.DrawMode := dmBlend;
    fHighlightBitmap.CombineMode := cmMerge;

    if GameParams.HighResolution then
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer-hr.png', fLemmingAnimations[ICECUBE]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight-hr.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown-hr.png', fCountdownDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'numbers-hr.png', fHatchNumbersBitmap);
    end else begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer.png', fLemmingAnimations[ICECUBE]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown.png', fCountdownDigitsBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'numbers.png', fHatchNumbersBitmap);
    end;

    // Load the freezing & unfreezing overlays
    Freeze := 'freezing_overlay.png';
    Unfreeze := 'unfreezing_overlay.png';
    FreezingOverlay := MetaSrcFolder + Freeze;
    CustomFreezingOverlay := ImgSrcFolder + Freeze;
    UnfreezingOverlay := MetaSrcFolder + Unfreeze;
    CustomUnfreezingOverlay := ImgSrcFolder + Unfreeze;

    if FileExists(CustomFreezingOverlay) then
      TPngInterface.LoadPngFile(CustomFreezingOverlay, fFreezingOverlay)
    else begin
      TPngInterface.LoadPngFile(FreezingOverlay, fFreezingOverlay);
      UpscalePieces;
    end;

    if FileExists(CustomUnfreezingOverlay) then
      TPngInterface.LoadPngFile(CustomUnfreezingOverlay, fUnfreezingOverlay)
    else begin
      TPngInterface.LoadPngFile(UnfreezingOverlay, fUnfreezingOverlay);
      UpscalePieces;
    end;

    fMetaLemmingAnimations[ICECUBE].Width := fLemmingAnimations[ICECUBE].Width;
    fMetaLemmingAnimations[ICECUBE].Height := fLemmingAnimations[ICECUBE].Height;
    fLemmingAnimations[ICECUBE].DrawMode := dmBlend;
    fLemmingAnimations[ICECUBE].CombineMode := cmMerge;
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
  fFreezingOverlay.Clear;
  fUnfreezingOverlay.Clear;
  fHatchNumbersBitmap.Clear;
  fHighlightBitmap.Clear;
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
  fFreezingOverlay := TBitmap32.Create;
  fUnfreezingOverlay := TBitmap32.Create;
  fHatchNumbersBitmap := TBitmap32.Create;
  fHighlightBitmap := TBitmap32.Create;
end;

destructor TBaseAnimationSet.Destroy;
begin
  fMetaLemmingAnimations.Free;
  fLemmingAnimations.Free;
  fCountDownDigitsBitmap.Free;
  fFreezingOverlay.Free;
  fUnfreezingOverlay.Free;
  fHatchNumbersBitmap.Free;
  fHighlightBitmap.Free;
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
  if aColorDict = nil then Exit; // this one shouldn't happen but just in case

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

