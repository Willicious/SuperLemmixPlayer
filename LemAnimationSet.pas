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
  NUM_LEM_SPRITES     = 65;
  NUM_LEM_SPRITE_TYPE = 32;
  WALKING             = 0;
  WALKING_RTL         = 1;
  ASCENDING           = 2;
  ASCENDING_RTL       = 3;
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
  FREEZEREXPLOSION     = 38;
  FREEZEREXPLOSION_RTL = 39;
  SWIMMING            = 40;
  SWIMMING_RTL        = 41;
  GLIDING             = 42;
  GLIDING_RTL         = 43;
  FIXING              = 44;
  FIXING_RTL          = 45;
  STACKING            = 46;
  STACKING_RTL        = 47;
  FENCING             = 48;
  FENCING_RTL         = 49;
  REACHING            = 50;
  REACHING_RTL        = 51;
  SHIMMYING           = 52;
  SHIMMYING_RTL       = 53;
  JUMPING             = 54;
  JUMPING_RTL         = 55;
  DEHOISTING          = 56;
  DEHOISTING_RTL      = 57;
  SLIDING             = 58;
  SLIDING_RTL         = 59;
  THROWING            = 60;
  THROWING_RTL        = 61;
  LASERING            = 62;
  LASERING_RTL        = 63;
  FROZEN              = 64; // this one does NOT need an RTL form; in fact in needs to be moved to the Masks section

  // never made sense to me why it lists the right-facing on the left
  // and the left-facing on the right. Is this standard practice? Maybe
  // I should change it... at some point.
  AnimationIndices : array[TBasicLemmingAction, LTR..RTL] of Integer = (
    (0,0),
    (WALKING, WALKING_RTL),                   // 1 baWalk,
    (ASCENDING, ASCENDING_RTL),               // 2 baAscending,
    (DIGGING, DIGGING_RTL),                   // 3 baDigging,
    (CLIMBING, CLIMBING_RTL),                 // 4 baClimbing,
    (DROWNING, DROWNING_RTL),                 // 5 baDrowning,
    (HOISTING, HOISTING_RTL),                 // 6 baHoisting,
    (BRICKLAYING, BRICKLAYING_RTL),           // 7 baBricklaying,
    (BASHING, BASHING_RTL),                   // 8 baBashing,
    (MINING, MINING_RTL),                     // 9 baMining,
    (FALLING, FALLING_RTL),                   // 10 baFalling,
    (UMBRELLA, UMBRELLA_RTL),                 // 11 baUmbrella,
    (SPLATTING, SPLATTING_RTL),               // 12 baSplatting,
    (EXITING, EXITING_RTL),                   // 13 baExiting,
    (FRIED, FRIED_RTL),                       // 14 baFried,
    (BLOCKING, BLOCKING_RTL),                 // 15 baBlocking,
    (SHRUGGING, SHRUGGING_RTL),               // 16 baShrugging,
    (OHNOING, OHNOING_RTL),                   // 17 baOhnoing,
    (EXPLOSION, EXPLOSION_RTL),               // 18 baExploding
    (0,0),                                    // 19 baToWalking. Should never happen.
    (PLATFORMING, PLATFORMING_RTL),           // 20 baPlatforming
    (STACKING, STACKING_RTL),                 // 21 baStacking
    (OHNOING, OHNOING_RTL),                   // 22 baFreezeOhNoing <-- might be incorrect name so don't rely on this
    (FREEZEREXPLOSION, FREEZEREXPLOSION_RTL),     // 23 baFreezeFinish
    (SWIMMING, SWIMMING_RTL),                 // 24 baSwimming
    (GLIDING, GLIDING_RTL),                   // 25 baGliding
    (FIXING, FIXING_RTL),                     // 26 baFixing
    (0,0),                                    // 27 baCloning? Another that should never happen
    (FENCING, FENCING_RTL),                   // 28 baFencing
    (REACHING, REACHING_RTL),                 // 29 baReaching (for shimmier)
    (SHIMMYING, SHIMMYING_RTL),               // 30 baShimmying
    (JUMPING, JUMPING_RTL),                   // 31 baJumping
    (DEHOISTING, DEHOISTING_RTL),             // 32 baDehoisting
    (SLIDING, SLIDING_RTL),                   // 33 baSliding
    (THROWING, THROWING_RTL),                 // 35 baSpearing
    (THROWING, THROWING_RTL),                 // 35 baGrenading
    (LASERING, LASERING_RTL)                  // 34 baLasering
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
  // These match the order these are stored by this class. They do NOT have to be in this
  // order in "scheme.nxmi", they just have to all be there.
  ANIM_NAMES: array[0..31] of String =  ('WALKER', 'ASCENDER', 'DIGGER', 'CLIMBER',
                                         'DROWNER', 'HOISTER', 'BUILDER', 'BASHER',
                                         'MINER', 'FALLER', 'FLOATER', 'SPLATTER',
                                         'EXITER', 'BURNER', 'BLOCKER', 'SHRUGGER',
                                         'OHNOER', 'BOMBER', 'PLATFORMER', 'FREEZER',
                                         'SWIMMER', 'GLIDER', 'DISARMER', 'STACKER',
                                         'FENCER', 'REACHER', 'SHIMMIER', 'JUMPER',
                                         'DEHOISTER', 'SLIDER', 'THROWER', 'LASERER');
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
  with fMetaLemmingAnimations[FROZEN] do
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
  X: Integer;

  SrcFolder: String;
  ColorDict: TColorDict;
  ShadeDict: TShadeDict;

  MetaSrcFolder, ImgSrcFolder: String;

  Info: TUpscaleInfo;
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

        Info := PieceManager.GetUpscaleInfo(SrcFolder, rkLemmings);
        UpscaleFrames(TempBitmap, 2, MLA.FrameCount, Info.Settings);

        // I don't think it would EVER be useful to have the TileHorizontal / TileVertical on lemming sprites, but
        // let's keep support just for consistency.
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

    fHighlightBitmap.DrawMode := dmBlend;
    fHighlightBitmap.CombineMode := cmMerge;

    if GameParams.HighResolution then
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer-hr.png', fLemmingAnimations[FROZEN]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight-hr.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown-hr.png', fCountdownDigitsBitmap);
    end else begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'freezer.png', fLemmingAnimations[FROZEN]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown.png', fCountdownDigitsBitmap);
    end;

    fMetaLemmingAnimations[FROZEN].Width := fLemmingAnimations[FROZEN].Width;
    fMetaLemmingAnimations[FROZEN].Height := fLemmingAnimations[FROZEN].Height;
    fLemmingAnimations[FROZEN].DrawMode := dmBlend;
    fLemmingAnimations[FROZEN].CombineMode := cmMerge;
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
  fHighlightBitmap := TBitmap32.Create;
end;

destructor TBaseAnimationSet.Destroy;
begin
  fMetaLemmingAnimations.Free;
  fLemmingAnimations.Free;
  fCountDownDigitsBitmap.Free;
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

