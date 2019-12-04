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
  NUM_LEM_SPRITES     = 55;
  NUM_LEM_SPRITE_TYPE = 27;
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
  FENCING             = 48;
  FENCING_RTL         = 49;
  REACHING            = 50;
  REACHING_RTL        = 51;
  SHIMMYING           = 52;
  SHIMMYING_RTL       = 53;
  STONED              = 54; // this one does NOT need an RTL form; in fact in needs to be moved to the Masks section

  // never made sense to me why it lists the right-facing on the left
  // and the left-facing on the right. Is this standard practice? Maybe
  // I should change it... at some point.
  AnimationIndices : array[TBasicLemmingAction, LTR..RTL] of Integer = (
    (0,0),
    (WALKING, WALKING_RTL),                   // baWalk,
    (ASCENDING, ASCENDING_RTL),               // baAscending,
    (DIGGING, DIGGING_RTL),                   // baDigging,
    (CLIMBING, CLIMBING_RTL),                 // baClimbing,
    (DROWNING, DROWNING_RTL),                 // baDrowning,
    (HOISTING, HOISTING_RTL),                 // baHoisting,
    (BRICKLAYING, BRICKLAYING_RTL),           // baBricklaying,
    (BASHING, BASHING_RTL),                   // baBashing,
    (MINING, MINING_RTL),                     // baMining,
    (FALLING, FALLING_RTL),                   // baFalling,
    (UMBRELLA, UMBRELLA_RTL),                 // baUmbrella,
    (SPLATTING, SPLATTING_RTL),               // baSplatting,
    (EXITING, EXITING_RTL),                   // baExiting,
    (FRIED, FRIED_RTL),                       // baFried,
    (BLOCKING, BLOCKING_RTL),                 // baBlocking,
    (SHRUGGING, SHRUGGING_RTL),               // baShrugging,
    (OHNOING, OHNOING_RTL),                   // baOhnoing,
    (EXPLOSION, EXPLOSION_RTL),               // baExploding
    (0,0),                                    // baToWalking. Should never happen.
    (PLATFORMING, PLATFORMING_RTL),           // baPlatforming
    (STACKING, STACKING_RTL),                 // baStacking
    (OHNOING, OHNOING_RTL),                   // baStoneOhNoing <-- might be incorrect name so don't rely on this
    (STONEEXPLOSION, STONEEXPLOSION_RTL),     // baStoneFinish
    (SWIMMING, SWIMMING_RTL),                 // baSwimming
    (GLIDING, GLIDING_RTL),                   // baGliding
    (FIXING, FIXING_RTL),                     // baFixing
    (0,0),                                    // baCloning? Another that should never happen
    (FENCING, FENCING_RTL),                   // baFencing
    (REACHING, REACHING_RTL),                 // baReaching (for shimmier)
    (SHIMMYING, SHIMMYING_RTL)                // baShimmying
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

    fRecolorer              : TRecolorImage;

    procedure ReadMetaData(aColorDict: TColorDict = nil);
    procedure LoadMetaData(aColorDict: TColorDict);

    procedure HandleRecoloring(aColorDict: TColorDict);
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
  end;

implementation

uses
  LemNeoPieceManager,
  GameControl;

{ TBaseAnimationSet }

procedure TBaseAnimationSet.LoadMetaData(aColorDict: TColorDict);
const
  // These match the order these are stored by this class. They do NOT have to be in this
  // order in "scheme.nxmi", they just have to all be there.
  ANIM_NAMES: array[0..26] of String =  ('WALKER', 'ASCENDER', 'DIGGER', 'CLIMBER',
                                         'DROWNER', 'HOISTER', 'BUILDER', 'BASHER',
                                         'MINER', 'FALLER', 'FLOATER', 'SPLATTER',
                                         'EXITER', 'BURNER', 'BLOCKER', 'SHRUGGER',
                                         'OHNOER', 'BOMBER', 'PLATFORMER', 'STONER',
                                         'SWIMMER', 'GLIDER', 'DISARMER', 'STACKER',
                                         'FENCER', 'REACHER', 'SHIMMIER');
  DIR_NAMES: array[0..1] of String = ('RIGHT', 'LEFT');
var
  Parser: TParser;
  AnimSec: TParserSection;
  ThisAnimSec: TParserSection;
  ColorSec: TParserSection;
  DirSec: TParserSection;
  i: Integer;
  dx: Integer;

  Anim: TMetaLemmingAnimation;
begin
  Parser := TParser.Create;
  try
    try
      Parser.LoadFromFile('scheme.nxmi');
      AnimSec := Parser.MainSection.Section['animations'];
    except
      raise Exception.Create('TBaseAnimationSet: Error while opening scheme.nxmi.');
    end;

    for i := 0 to NUM_LEM_SPRITE_TYPE - 1 do
    begin
      try
        ThisAnimSec := AnimSec.Section[ANIM_NAMES[i]];
        for dx := 0 to 1 do
        begin
          DirSec := ThisAnimSec.Section[DIR_NAMES[dx]];
          Anim := fMetaLemmingAnimations[i * 2 + dx];

          Anim.FrameCount := ThisAnimSec.LineNumeric['frames'];

          if ThisAnimSec.Line['loop_to_frame'] = nil then
            Anim.FrameDiff := Anim.FrameCount - ThisAnimSec.LineNumeric['keyframe']
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
  finally
    Parser.Free;
  end;
end;


procedure TBaseAnimationSet.ReadMetaData(aColorDict: TColorDict = nil);
{-------------------------------------------------------------------------------
  o make lemming animations
  o make mask animations metadata
-------------------------------------------------------------------------------}
var
  AnimIndex: Integer;
begin
  // Add right- and left-facing version for 25 skills and the one stoner mask
  for AnimIndex := 0 to NUM_LEM_SPRITES - 1 do
  begin
    fMetaLemmingAnimations.Add;
  end;

  // Setting the foot position of the stoner mask.
  // This should be irrelevant for the stoner mask, as the stoner mask is not positioned wrt. the lemming's foot.
  // For other sprites, the foot position is required though.
  with fMetaLemmingAnimations[STONED] do
  begin
    FrameCount := 1;
    FootX := 8 * ResMod;
    FootY := 10 * ResMod;
  end;

  LoadMetaData(aColorDict);
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

  MetaSrcFolder, ImgSrcFolder: String;
begin
  TempBitmap := TBitmap32.Create;
  ColorDict := TColorDict.Create;


  try
    if fTheme = nil then
      SrcFolder := 'default'
    else
      SrcFolder := PieceManager.Dealias(fTheme.Lemmings, rkLemmings);

    if SrcFolder = '' then SrcFolder := 'default';
    if not DirectoryExists(AppPath + SFStyles + SrcFolder + SFPiecesLemmings) then
      SrcFolder := 'default';

    SetCurrentDir(AppPath + SFStyles + SrcFolder + SFPiecesLemmings);

    if fMetaLemmingAnimations.Count = 0 then // not entirely sure why it would ever NOT be 0
      ReadMetaData(ColorDict);

    MetaSrcFolder := AppPath + SFStyles + SrcFolder + SFPiecesLemmings;

    if GameParams.HighResolution then
      ImgSrcFolder := AppPath + SFStyles + SrcFolder + SFPiecesLemmingsHighRes
    else
      ImgSrcFolder := MetaSrcFolder;

    for iAnimation := 0 to NUM_LEM_SPRITES - 2 do // -2 to leave out the stoner placeholder
    begin
      MLA := fMetaLemmingAnimations[iAnimation];
      Fn := RightStr(MLA.Description, Length(MLA.Description) - 1);

      if FileExists(ImgSrcFolder + Fn + '.png') then
      begin
        TPngInterface.LoadPngFile(ImgSrcFolder + Fn + '.png', TempBitmap);

        // Backwards compatibility
        if FileExists(Fn + '_mask.png') and (fTheme <> nil) and not GameParams.HighResolution then
          TPngInterface.MaskImageFromFile(TempBitmap, Fn + '_mask.png', fTheme.Colors['MASK']);
      end else begin
        TPngInterface.LoadPngFile(MetaSrcFolder + Fn + '.png', TempBitmap);

        // Backwards compatibility
        if FileExists(Fn + '_mask.png') and (fTheme <> nil) then
          TPngInterface.MaskImageFromFile(TempBitmap, Fn + '_mask.png', fTheme.Colors['MASK']);

        UpscaleFrames(TempBitmap, 2, MLA.FrameCount, PieceManager.GetUpscaleKind(SrcFolder, rkLemmings));
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

    HandleRecoloring(ColorDict);

    fLemmingAnimations.Add(TBitmap32.Create); // for the Stoner

    // // // // // // // // // // // //
    // Extract masks / Digits / etc. //
    // // // // // // // // // // // //

    fCountDownDigitsBitmap := TBitmap32.Create;
    fCountDownDigitsBitmap.DrawMode := dmBlend;
    fCountDownDigitsBitmap.CombineMode := cmMerge;

    fHighlightBitmap := TBitmap32.Create;
    fHighlightBitmap.DrawMode := dmBlend;
    fHighlightBitmap.CombineMode := cmMerge;

    if GameParams.HighResolution then
    begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'stoner-hr.png', fLemmingAnimations[STONED]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight-hr.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown-hr.png', fCountdownDigitsBitmap);
    end else begin
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'stoner.png', fLemmingAnimations[STONED]);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'highlight.png', fHighlightBitmap);
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'countdown.png', fCountdownDigitsBitmap);
    end;

    fMetaLemmingAnimations[STONED].Width := fLemmingAnimations[STONED].Width;
    fMetaLemmingAnimations[STONED].Height := fLemmingAnimations[STONED].Height;
    fLemmingAnimations[STONED].DrawMode := dmBlend;
    fLemmingAnimations[STONED].CombineMode := cmMerge;
  finally
    TempBitmap.Free;
    ColorDict.Free;
  end;
end;


procedure TBaseAnimationSet.ClearData;
begin
  fLemmingAnimations.Clear;
  if Assigned(fMetaLemmingAnimations) then fMetaLemmingAnimations.Clear;
  if Assigned(fCountDownDigitsBitmap) then fCountDownDigitsBitmap.Clear;
  if Assigned(fHighlightBitmap) then fHighlightBitmap.Clear;
  fTheme := nil;
end;

constructor TBaseAnimationSet.Create;
begin
  inherited Create;
  fMetaLemmingAnimations := TMetaLemmingAnimations.Create(TMetaLemmingAnimation);
  fLemmingAnimations := TBitmaps.Create;
  fRecolorer := TRecolorImage.Create;
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

procedure TBaseAnimationSet.HandleRecoloring(aColorDict: TColorDict);
var
  Template, ThisAnim: TBitmap32;
  i, x, y: Integer;
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
          if not aColorDict.ContainsKey(ThisAnim[x, y] and $FFFFFF) then Continue;
          if not fTheme.DoesColorExist(aColorDict[ThisAnim[x,y] and $FFFFFF]) then Continue; // We do NOT want to fall back to default color here.
          Template[x, y] := (fTheme.Colors[aColorDict[ThisAnim[x,y] and $FFFFFF]] and $FFFFFF) or
                            (ThisAnim[x,y] and $FF000000);
        end;

      Template.DrawTo(ThisAnim, 0, 0);
    end;
  finally
    Template.Free;
  end;

  fRecolorer.ApplyPaletteSwapping(aColorDict, fTheme);
end;

end.

