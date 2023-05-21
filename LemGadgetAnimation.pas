unit LemGadgetAnimation;

interface

uses
  LemNeoTheme,
  LemAnimationSet, LemMetaAnimation,
  LemCore,
  LemStrings,
  Generics.Collections, Generics.Defaults,
  PngInterface,
  UMisc,
  LemTypes,
  LemNeoParser,
  GR32,
  Classes,
  StrUtils,
  SysUtils;

const
  PICKUP_AUTO_GFX_SIZE = 24;

type
  TGadgetAnimationState = (gasPlay, gasPause, gasLoopToZero, gasStop, gasMatchPrimary);

  TGadgetAnimationTriggerCondition = (gatcUnconditional, gatcReady, gatcBusy, gatcDisabled,
                                      gatcExhausted);

  TGadgetAnimationTriggerState = (gatsDontCare, gatsTrue, gatsFalse);
  TGadgetAnimationTriggerConditionArray = array[TGadgetAnimationTriggerCondition] of TGadgetAnimationTriggerState;

  {
  Triggers can be used to define when a secondary animation is visible. Certain
  objects support certain trigger conditions. All objects can support
  unconditional secondary animations, so even those with no triggers can still
  make use of secondaries.



  The "gatsDontCare" state is not returned by tests (they will return gatFalse
  where not supported). It is only used when defining conditions, and usually,
  only internally.


  The basic animation states are Play and Pause. Others will eventually change
  to one of these, except gasMatchPrimary which is a special case where the
  frame will match the primary animation.

  gasLoopToZero - Changes to gasPause when frame 0 is reached
  gasStop - Sets frame to 0 then changes to gasPause

  Animations are visible regardless of the visibility tag while they are
  animating; they must be stopped to hide them. However, loading code will
  automatically add a setting of state to gasStop if a trigger defines invisible
  but doesn't indicate any animation state change. gasMatchPrimary is treated
  as animating for the purpose of this rule.


  OBJECT TYPE     | gatcUnconditional (no condition)
  ----------------|-----------------------------------
  GENERAL RULE    | Always true, for all objects
  Anything        | Always true


  OBJECT TYPE     | gatcReady (READY)
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true if the object would able to interact with a lemming at this moment
  DOM_EXIT        | True when the exit's lemming limit has not been reached, or if the exit has no limit
  DOM_TRAP        | True when the trap is idle (but not disabled)
  DOM_TELEPORT    | True when the teleporter and its paired receiver (if any) are idle
  DOM_RECEIVER    | True when the receiver and its paired teleporter (if any) are idle
  DOM_PICKUP      | True when the skill has not been picked up
  DOM_LOCKEXIT    | True when the exit is fully open and the lemming limit has not been reached, or it doesn't have one
  DOM_BUTTON      | True when the button has not been pressed
  DOM_WINDOW      | True when the window is fully open, and if it has a lemming limit, hasn't yet reached it
  DOM_TRAPONCE    | True when the trap has not yet been triggered (or disabled)
  DOM_ANIMATION   | True when the animation is idle
  DOM_ANIMONCE    | True when the animation has not yet been triggered
  All others      | Always true


  OBJECT TYPE     | gatcBusy (BUSY)
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true when the object is transitioning between states, or currently in use
  DOM_TRAP        | True when the trap is mid-kill
  DOM_TELEPORT    | True when the teleporter, or its paired receiver, are mid-operation
  DOM_RECEIVER    | True when the receiver, or its paired teleporter, are mid-operation
  DOM_LOCKEXIT    | True when the exit is in the process of opening
  DOM_WINDOW      | True when the window is in the process of opening
  DOM_TRAPONCE    | True when the trap is mid-kill
  DOM_ANIMATION   | True when the animation is playing
  DOM_ANIMONCE    | True when the animation is playing
  All others      | Always false


  OBJECT TYPE     | gatcDisabled (DISABLED)
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true when the object is unable to interact with a lemming, either permanently or
                  | until some external condition is fulfilled.
  DOM_EXIT        | True if the exit has a lemming limit and it has been reached
  DOM_TRAP        | True if the trap has been disabled (most likely by a disarmer)
  DOM_TELEPORT    | True if no receiver exists on the level
  DOM_RECEIVER    | True if no teleporter exists on the level
  DOM_PICKUP      | True if the skill has been picked up
  DOM_LOCKEXIT    | True while the exit is in a locked state, or if the exit has a lemming limit and it has been reached
  DOM_BUTTON      | True when the button has been pressed
  DOM_WINDOW      | True if the window has a lemming limit and it has been reached
  DOM_TRAPONCE    | True when the trap has been disabled (most likely by a disarmer) or used
  DOM_ANIMONCE    | True when the animation has completed
  All others      | Always false


  OBJECT TYPE     | gatcExhausted
  ----------------|-----------------------------------
  GENERAL RULE    | True if an object with limited uses has been used up.
  DOM_EXIT        | True if the exit is limited-use and has zero remaining uses
  DOM_PICKUP      | True if the skill has been picked up
  DOM_LOCKEXIT    | True if the exit is limited-use and has zero remaining uses
  DOM_BUTTON      | True when the button has been pressed
  DOM_WINDOW      | True if the window is limited-use and has released all lemmings
  DOM_TRAPONCE    | True when the trap has been used
  DOM_ANIMONCE    | True when the animation has completed
  All others      | Always false

  }

  TGadgetAnimationTrigger = class
    private
      fCondition: TGadgetAnimationTriggerCondition;
      fState: TGadgetAnimationState;
      fVisible: Boolean;
    public
      procedure Load(aSegment: TParserSection);
      procedure Clone(aSrc: TGadgetAnimationTrigger);

      property Condition: TGadgetAnimationTriggerCondition read fCondition;
      property State: TGadgetAnimationState read fState;
      property Visible: Boolean read fVisible;
  end;

  TGadgetAnimationTriggers = class(TObjectList<TGadgetAnimationTrigger>)
    public
      procedure Clone(aSrc: TGadgetAnimationTriggers);
  end;

  TGadgetAnimation = class
    private class var
      fTempBitmap: TBitmap32;
      fTempBitmapUsageCount: Integer;
    private
      fNeedRemask: Boolean;

      fMainObjectWidth: Integer;
      fMainObjectHeight: Integer;

      fFrameCount: Integer;
      fName: String;
      fColor: String;

      fPrimary: Boolean;
      fHorizontalStrip: Boolean;

      fZIndex: Integer;
      fStartFrameIndex: Integer;

      fWidth: Integer;
      fHeight: Integer;

      fOffsetX: Integer;
      fOffsetY: Integer;

      fCutTop: Integer;
      fCutRight: Integer;
      fCutBottom: Integer;
      fCutLeft: Integer;

      fSourceImage: TBitmap32;
      fTriggers: TGadgetAnimationTriggers;

      fSourceImageMasked: TBitmap32;
      fMaskColor: TColor32;

      function MakeFrameBitmaps(aForceLowRes: Boolean = false): TBitmaps;
      procedure CombineBitmaps(aBitmaps: TBitmaps);
      function GetCutRect: TRect;
      function GetCutRectHighRes: TRect;

      procedure PickupSkillEraseCombine(F: TColor32; var B: TColor32; M: TColor32);
    public
      constructor Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
      destructor Destroy; override;

      procedure Load(aCollection, aPiece: String; aSegment: TParserSection; aTheme: TNeoTheme);
      procedure Remask(aTheme: TNeoTheme);
      procedure Clone(aSrc: TGadgetAnimation);
      procedure Clear;

      procedure Rotate90;
      procedure Flip;
      procedure Invert;

      procedure GeneratePickupSkills(aTheme: TNeoTheme; aAni: TBaseAnimationSet; aErase: TGadgetAnimation);

      function GetFrameBitmap(aFrame: Integer; aPersistent: Boolean = false): TBitmap32;
      procedure GetFrame(aFrame: Integer; aBitmap: TBitmap32);

      procedure Draw(Dst: TBitmap32; X, Y: Integer; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil; aRaw: Boolean = false); overload;
      procedure Draw(Dst: TBitmap32; DstRect: TRect; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil; aRaw: Boolean = false); overload;

      property Name: String read fName write fName;
      property Color: String read fColor write fColor;

      property FrameCount: Integer read fFrameCount;
      property HorizontalStrip: Boolean read fHorizontalStrip;

      property Width: Integer read fWidth;
      property Height: Integer read fHeight;

      property OffsetX: Integer read fOffsetX write fOffsetX;
      property OffsetY: Integer read fOffsetY write fOffsetY;

      property StartFrameIndex: Integer read fStartFrameIndex write fStartFrameIndex;
      property ZIndex: Integer read fZIndex write fZIndex;
      property Primary: Boolean read fPrimary write fPrimary;

      property CutRect: TRect read GetCutRect;
      property CutRectHighRes: TRect read GetCutRectHighRes;
      property CutTop: Integer read fCutTop write fCutTop;
      property CutRight: Integer read fCutRight write fCutRight;
      property CutBottom: Integer read fCutBottom write fCutBottom;
      property CutLeft: Integer read fCutLeft write fCutLeft;

      property Triggers: TGadgetAnimationTriggers read fTriggers;
  end;

  TGadgetAnimations = class(TObjectList<TGadgetAnimation>)
    private
      fPrimaryAnimation: TGadgetAnimation;
      function GetAnimation(aIdentifier: String): TGadgetAnimation;
      function GetAnyMasked: Boolean;
    public
      procedure AddPrimary(aAnimation: TGadgetAnimation);

      procedure SortByZIndex;

      procedure Remask(aTheme: TNeoTheme);
      procedure Clone(aSrc: TGadgetAnimations);
      procedure Rotate90;
      procedure Flip;
      procedure Invert;

      property PrimaryAnimation: TGadgetAnimation read fPrimaryAnimation;
      property Animations[Identifier: String]: TGadgetAnimation read GetAnimation; default;
      property AnyMasked: Boolean read GetAnyMasked;
  end;

implementation

uses
  LemProjectile,
  LemNeoPieceManager,
  GameControl;

// TGadgetAnimation

constructor TGadgetAnimation.Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
begin
  inherited Create;
  fSourceImage := TBitmap32.Create;
  fSourceImageMasked := TBitmap32.Create;
  fTriggers := TGadgetAnimationTriggers.Create;

  fMainObjectWidth := aMainObjectWidth;
  fMainObjectHeight := aMainObjectHeight;

  if (fTempBitmapUsageCount = 0) then
    fTempBitmap := TBitmap32.Create;
  Inc(fTempBitmapUsageCount);

  fNeedRemask := true;
  fMaskColor := $FFFFFFFF;
end;

destructor TGadgetAnimation.Destroy;
begin
  Dec(fTempBitmapUsageCount);
  if (fTempBitmapUsageCount = 0) then
    fTempBitmap.Free;

  fTriggers.Free;
  fSourceImage.Free;
  fSourceImageMasked.Free;
  inherited;
end;

procedure TGadgetAnimation.Remask(aTheme: TNeoTheme);
begin
  if aTheme <> nil then
  begin
    fNeedRemask := false;

    if aTheme.Colors[fColor] and $FFFFFF = fMaskColor then
      Exit;

    fMaskColor := aTheme.Colors[fColor] and $FFFFFF;
  end;

  fSourceImageMasked.Assign(fSourceImage);

  if fColor <> '' then
    TPngInterface.MaskImageFromImage(fSourceImageMasked, fSourceImageMasked, fMaskColor);
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; X, Y, aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil; aRaw: Boolean = false);
begin
  Draw(Dst, SizedRect(X, Y, fWidth * ResMod, fHeight * ResMod), aFrame, aPixelCombine, aRaw);
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; DstRect: TRect; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil; aRaw: Boolean = false);
var
  SrcRect: TRect;
  SrcBmp: TBitmap32;
begin
  if fNeedRemask and not aRaw then
    Remask(nil);

  if aRaw then
    SrcBmp := fSourceImage
  else
    SrcBmp := fSourceImageMasked;

  if not Assigned(aPixelCombine) then
  begin
    SrcBmp.DrawMode := dmBlend;
    SrcBmp.CombineMode := cmMerge;
  end else begin
    SrcBmp.DrawMode := dmCustom;
    SrcBmp.OnPixelCombine := aPixelCombine;
  end;

  if fHorizontalStrip then
    SrcRect := SizedRect(aFrame * fWidth * ResMod, 0, fWidth * ResMod, fHeight * ResMod)
  else
    SrcRect := SizedRect(0, aFrame * fHeight * ResMod, fWidth * ResMod, fHeight * ResMod);

  SrcBmp.DrawTo(Dst, DstRect, SrcRect);
end;

function TGadgetAnimation.GetFrameBitmap(aFrame: Integer; aPersistent: Boolean = false): TBitmap32;
begin
  if aPersistent then
    Result := TBitmap32.Create
  else
    Result := fTempBitmap;

  Result.DrawMode := dmBlend;
  Result.CombineMode := cmMerge;

  GetFrame(aFrame, Result);
end;

procedure TGadgetAnimation.GetFrame(aFrame: Integer; aBitmap: TBitmap32);
begin
  aBitmap.SetSize(fWidth * ResMod, fHeight * ResMod);
  aBitmap.Clear(0);
  Draw(aBitmap, 0, 0, aFrame);
end;

procedure TGadgetAnimation.PickupSkillEraseCombine(F: TColor32; var B: TColor32; M: TColor32);
begin
  B := (((Round(
          ((B shr 24) / 255) *
          (1 - ((F shr 24) / 255))
         ) * 255) and $FF) shl 24)
       or (B and $00FFFFFF);
end;

procedure TGadgetAnimation.GeneratePickupSkills(aTheme: TNeoTheme; aAni: TBaseAnimationSet; aErase: TGadgetAnimation);
var
  BrickColor: TColor32;
  SkillIcons: TBitmaps;
  NewBmp: TBitmap32;
  i: Integer;

  procedure DrawAnimationFrame(dst: TBitmap32; aAnimationIndex: Integer; aFrame: Integer; footX, footY: Integer);
  var
    Ani: TBaseAnimationSet;
    Meta: TMetaLemmingAnimation;
    SrcRect: TRect;
    OldDrawMode: TDrawMode;
  begin
    Ani := GameParams.Renderer.LemmingAnimations;
    Meta := Ani.MetaLemmingAnimations[aAnimationIndex];

    SrcRect := Ani.LemmingAnimations[aAnimationIndex].BoundsRect;
    SrcRect.Bottom := SrcRect.Bottom div Meta.FrameCount;
    SrcRect.Offset(0, SrcRect.Height * aFrame);

    OldDrawMode := Ani.LemmingAnimations[aAnimationIndex].DrawMode;
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := dmBlend;
    Ani.LemmingAnimations[aAnimationIndex].DrawTo(dst, (footX * ResMod) - Meta.FootX, (footY * ResMod) - Meta.FootY, SrcRect);
    Ani.LemmingAnimations[aAnimationIndex].DrawMode := OldDrawMode;
  end;

  procedure DrawBrick(dst: TBitmap32; X, Y: Integer; W: Integer = 2);
  var
    oX: Integer;
  begin
    for oX := 0 to W-1 do
      if GameParams.HighResolution then
      begin
        dst.PixelS[(X + oX) * ResMod, Y * ResMod] := BrickColor;
        dst.PixelS[(X + oX) * ResMod + 1, Y * ResMod] := BrickColor;
        dst.PixelS[(X + oX) * ResMod, Y * ResMod + 1] := BrickColor;
        dst.PixelS[(X + oX) * ResMod + 1, Y * ResMod + 1] := BrickColor;
      end else
        dst.PixelS[X + oX, Y] := BrickColor;
  end;

  procedure DrawMiscBmp(Src, Dst: TBitmap32; dstX, dstY: Integer; SrcRect: TRect);
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

const
  PICKUP_MID = (PICKUP_AUTO_GFX_SIZE div 2) - 1;
  PICKUP_BASELINE = (PICKUP_AUTO_GFX_SIZE div 2) + 7;
begin
  fFrameCount := (Integer(LAST_SKILL_BUTTON) + 1) * 2;
  BrickColor := aTheme.Colors['PICKUP_BRICKS'] or $FF000000;
  if BrickColor = aTheme.Colors['MASK'] or $FF000000 then
    BrickColor := $FFFFFFFF;

  ////////////////////////////////////////////////////////////
  ///  This code is mostly copied from GameBaseSkillPanel. ///
  ////////////////////////////////////////////////////////////

  SkillIcons := TBitmaps.Create;

  for i := 0 to (fFrameCount div 2) - 1 do
  begin
    NewBmp := TBitmap32.Create;
    NewBmp.SetSize(PICKUP_AUTO_GFX_SIZE * ResMod, PICKUP_AUTO_GFX_SIZE * ResMod);
    NewBmp.Clear(0);
    SkillIcons.Add(NewBmp);
  end;

  // Walker, Jumper, Shimmier, Slider, Climber, Swimmer, Floater, Glider, Disarmer - all simple
  DrawAnimationFrame(SkillIcons[Integer(spbWalker)], WALKING, 1, PICKUP_MID, PICKUP_BASELINE - 1);
  DrawAnimationFrame(SkillIcons[Integer(spbJumper)], JUMPING, 0, PICKUP_MID, PICKUP_BASELINE - 3);
  DrawAnimationFrame(SkillIcons[Integer(spbShimmier)], SHIMMYING, 1, PICKUP_MID, PICKUP_BASELINE - 4);
  DrawAnimationFrame(SkillIcons[Integer(spbSlider)], SLIDING_RTL, 0, PICKUP_MID - 2, PICKUP_BASELINE - 2);
  DrawAnimationFrame(SkillIcons[Integer(spbClimber)], CLIMBING, 3, PICKUP_MID + 3, PICKUP_BASELINE - 1);
  DrawAnimationFrame(SkillIcons[Integer(spbSwimmer)], SWIMMING, 2, PICKUP_MID + 1, PICKUP_BASELINE - 6);
  DrawAnimationFrame(SkillIcons[Integer(spbFloater)], UMBRELLA, 4, PICKUP_MID - 1, PICKUP_BASELINE + 6);
  DrawAnimationFrame(SkillIcons[Integer(spbGlider)], GLIDING, 4, PICKUP_MID - 1, PICKUP_BASELINE + 6);
  DrawAnimationFrame(SkillIcons[Integer(spbDisarmer)], FIXING, 6, PICKUP_MID - 2, PICKUP_BASELINE - 3);

  // Bomber, freezer and blocker are simple. Unlike the skill panel, we use the Ohnoer animation for timebomber and bomber here.
  DrawAnimationFrame(SkillIcons[Integer(spbTimebomber)], OHNOING, 7, PICKUP_MID, PICKUP_BASELINE - 3);  //bookmark - might use the timebomber-specific graphic for this one
  DrawAnimationFrame(SkillIcons[Integer(spbBomber)], OHNOING, 7, PICKUP_MID, PICKUP_BASELINE - 3);
  DrawAnimationFrame(SkillIcons[Integer(spbFreezer)], ICECUBE, 0, PICKUP_MID + 1, PICKUP_BASELINE - 1);
  DrawAnimationFrame(SkillIcons[Integer(spbBlocker)], BLOCKING, 0, PICKUP_MID, PICKUP_BASELINE - 1);

  // Platformer, Builder and Stacker have bricks drawn to clarify the direction of building.
  // Platformer additionally has some extra black pixels drawn in to make the outline nicer.
  DrawAnimationFrame(SkillIcons[Integer(spbPlatformer)], PLATFORMING, 1, PICKUP_MID, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbPlatformer)], PICKUP_MID - 5, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbPlatformer)], PICKUP_MID - 3, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbPlatformer)], PICKUP_MID - 1, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbPlatformer)], PICKUP_MID + 1, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbPlatformer)], PICKUP_MID + 3, PICKUP_BASELINE - 4);

  DrawAnimationFrame(SkillIcons[Integer(spbBuilder)], BRICKLAYING, 1, PICKUP_MID, PICKUP_BASELINE - 3);
  DrawBrick(SkillIcons[Integer(spbBuilder)], PICKUP_MID - 3, PICKUP_BASELINE - 2);
  DrawBrick(SkillIcons[Integer(spbBuilder)], PICKUP_MID - 1, PICKUP_BASELINE - 3);
  DrawBrick(SkillIcons[Integer(spbBuilder)], PICKUP_MID + 1, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbBuilder)], PICKUP_MID + 3, PICKUP_BASELINE - 5);

  DrawAnimationFrame(SkillIcons[Integer(spbStacker)], STACKING, 0, PICKUP_MID, PICKUP_BASELINE - 2);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 2);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 3);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 4);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 5);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 6);
  DrawBrick(SkillIcons[Integer(spbStacker)], PICKUP_MID + 2, PICKUP_BASELINE - 7);

 // Projectiles are messy.
  NewBMP := TBitmap32.Create;
  try
    if GameParams.HighResolution then
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'projectiles-hr.png', NewBMP)
    else
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMasks + 'projectiles.png', NewBMP);

    DoProjectileRecolor(NewBMP, $FFFFFFFF);

    DrawMiscBmp(NewBMP, SkillIcons[Integer(spbSpearer)], PICKUP_MID - 8, PICKUP_BASELINE - 10, PROJECTILE_GRAPHIC_RECTS[pgSpearSlightBLTR]);
    DrawMiscBmp(NewBMP, SkillIcons[Integer(spbGrenader)], PICKUP_MID - 3, PICKUP_BASELINE - 10, PROJECTILE_GRAPHIC_RECTS[pgGrenade]);
  finally
    NewBMP.Free;
  end;

  DrawAnimationFrame(SkillIcons[Integer(spbSpearer)], THROWING, 1, PICKUP_MID + 2, PICKUP_BASELINE);
  DrawAnimationFrame(SkillIcons[Integer(spbGrenader)], THROWING, 1, PICKUP_MID + 2, PICKUP_BASELINE);

  // Laserer, Basher, Fencer, Miner are all simple - we do have to take care to avoid frames with destruction particles.
  // For the Digger, we don't have a choice - we have to accept the presence of some destruction particles.
  DrawAnimationFrame(SkillIcons[Integer(spbLaserer)], LASERING, 0, PICKUP_MID + 1, PICKUP_BASELINE - 2);
  DrawAnimationFrame(SkillIcons[Integer(spbBasher)], BASHING, 0, PICKUP_MID + 1, PICKUP_BASELINE - 2);
  DrawAnimationFrame(SkillIcons[Integer(spbFencer)], FENCING, 1, PICKUP_MID, PICKUP_BASELINE - 2);
  DrawAnimationFrame(SkillIcons[Integer(spbMiner)], MINING, 12, PICKUP_MID - 3, PICKUP_BASELINE - 2);
  DrawAnimationFrame(SkillIcons[Integer(spbDigger)], DIGGING, 4, PICKUP_MID + 1, PICKUP_BASELINE - 4);

  // Cloner is drawn as two back-to-back walkers.
  DrawAnimationFrame(SkillIcons[Integer(spbCloner)], WALKING_RTL, 1, PICKUP_MID - 1, PICKUP_BASELINE - 1);
  DrawAnimationFrame(SkillIcons[Integer(spbCloner)], WALKING, 1, PICKUP_MID + 2, PICKUP_BASELINE - 1);

  if aErase <> nil then
  begin
    aErase.fSourceImage.DrawMode := dmCustom;
    aErase.fSourceImage.OnPixelCombine := PickupSkillEraseCombine;
  end;

  // Now we need to duplicate each frame then apply the respective erasers
  for i := 0 to (fFrameCount div 2) - 1 do
  begin
    NewBmp := TBitmap32.Create;
    NewBmp.Assign(SkillIcons[i * 2]);
    SkillIcons.Insert(i * 2, NewBmp);

    if aErase <> nil then
    begin
      aErase.fSourceImage.DrawTo(SkillIcons[i * 2], 0, 0, Rect(0, 0, PICKUP_AUTO_GFX_SIZE * ResMod, PICKUP_AUTO_GFX_SIZE * ResMod));
      aErase.fSourceImage.DrawTo(SkillIcons[(i * 2) + 1], 0, 0, Rect(0, PICKUP_AUTO_GFX_SIZE * ResMod, PICKUP_AUTO_GFX_SIZE * ResMod, PICKUP_AUTO_GFX_SIZE * ResMod * 2));
    end else
      SkillIcons[i * 2].Clear(0);
  end;

  CombineBitmaps(SkillIcons);
end;

function TGadgetAnimation.GetCutRect: TRect;
begin
  Result := Rect(fCutLeft, fCutTop, fCutRight, fCutBottom);
end;

function TGadgetAnimation.GetCutRectHighRes: TRect;
begin
  Result := Rect(fCutLeft * 2, fCutTop * 2, fCutRight * 2, fCutBottom * 2);
end;

procedure TGadgetAnimation.Load(aCollection, aPiece: String; aSegment: TParserSection; aTheme: TNeoTheme);
var
  BaseTrigger: TGadgetAnimationTrigger;
  LoadPath: String;
  S: String;

  NeedUpscale: Boolean;
  Bitmaps: TBitmaps;
  i: Integer;

  Info: TUpscaleInfo;
begin
  Clear;

  fFrameCount := aSegment.LineNumeric['frames'];
  fName := UpperCase(aSegment.LineTrimString['name']);
  fColor := UpperCase(aSegment.LineTrimString['color']);

  if LeftStr(fName, 1) <> '*' then
  begin
    if GameParams.HighResolution then
      LoadPath := AppPath + SFStyles + aCollection + SFPiecesObjectsHighRes + aPiece
    else
      LoadPath := AppPath + SFStyles + aCollection + SFPiecesObjects + aPiece;

    if fName <> '' then
      LoadPath := LoadPath + '_' + fName; // for backwards-compatible or simply unnamed primaries
    LoadPath := LoadPath + '.png';

    if GameParams.HighResolution and not FileExists(LoadPath) then
    begin
      LoadPath := AppPath + SFStyles + aCollection + SFPiecesObjects + aPiece;

      if fName <> '' then
        LoadPath := LoadPath + '_' + fName; // for backwards-compatible or simply unnamed primaries
      LoadPath := LoadPath + '.png';

      NeedUpscale := true;
    end else
      NeedUpscale := false;

    fHorizontalStrip := aSegment.Line['horizontal_strip'] <> nil;

    TPngInterface.LoadPngFile(LoadPath, fSourceImage);

    if fHorizontalStrip then
    begin
      fWidth := fSourceImage.Width div fFrameCount;
      fHeight := fSourceImage.Height;
    end else begin
      fWidth := fSourceImage.Width;
      fHeight := fSourceImage.Height div fFrameCount;
    end;

    if NeedUpscale then
    begin
      Bitmaps := MakeFrameBitmaps(true);
      Info := PieceManager.GetUpscaleInfo(aCollection + ':' + aPiece, rkGadget);
      for i := 0 to Bitmaps.Count-1 do
        Upscale(Bitmaps[i], Info.Settings);
      CombineBitmaps(Bitmaps);
    end else if GameParams.HighResolution then
    begin
      fWidth := fWidth div 2;
      fHeight := fHeight div 2;
    end;
  end else begin
    fHorizontalStrip := false;

    if Lowercase(fName) = '*blank' then
    begin
      fWidth := aSegment.LineNumeric['WIDTH'];
      fHeight := aSegment.LineNumeric['HEIGHT'];
      // Preserve previously-loaded frame count.

      fSourceImage.SetSize(fWidth * ResMod, fHeight * ResMod * fFrameCount);
      fSourceImage.Clear(0);
    end else begin
      // Fallback behaviour. This may mean it's unrecognized, but it could also just
      // mean that it's handled elsewhere (eg. "*PICKUP").
      fSourceImage.SetSize(ResMod, ResMod);
      fSourceImage.Clear(0);
      fFrameCount := 1;
      fWidth := 1;
      fHeight := 1;
    end;
  end;

  // fPrimary is only set by TGadgetAnimations

  if fPrimary and (aSegment.Line['z_index'] = nil) then
    fZIndex := 1
  else
    fZIndex := aSegment.LineNumeric['z_index'];

  if Uppercase(aSegment.LineTrimString['initial_frame']) = 'RANDOM' then
    fStartFrameIndex := -1
  else
    fStartFrameIndex := aSegment.LineNumeric['initial_frame'];



  if fPrimary then
  begin
    fMainObjectWidth := fWidth;
    fMainObjectHeight := fHeight;
  end;

  fOffsetX := aSegment.LineNumeric['offset_x'];
  fOffsetY := aSegment.LineNumeric['offset_y'];

  fCutTop := aSegment.LineNumeric['nine_slice_top'];
  fCutRight := aSegment.LineNumeric['nine_slice_right'];
  fCutBottom := aSegment.LineNumeric['nine_slice_bottom'];
  fCutLeft := aSegment.LineNumeric['nine_slice_left'];

  BaseTrigger := TGadgetAnimationTrigger.Create;

  S := Lowercase(aSegment.LineTrimString['state']);

  if (S = 'pause') then
    BaseTrigger.fState := gasPause
  else if (S = 'stop') then
    BaseTrigger.fState := gasStop
  else if (S = 'looptozero') then
    BaseTrigger.fState := gasLoopToZero
  else if (S = 'matchphysics') then
    BaseTrigger.fState := gasMatchPrimary
  else if (aSegment.Line['hide'] <> nil) then
    BaseTrigger.fState := gasPause
  else
    BaseTrigger.fState := gasPlay;

  if (aSegment.Line['hide'] = nil) then
    BaseTrigger.fVisible := true
  else
    BaseTrigger.fVisible := false;

  fTriggers.Add(BaseTrigger);

  if fPrimary then
  begin
    // Some properties are overridden / hardcoded for primary
    BaseTrigger.fState := gasPause; // physics control the current frame
    BaseTrigger.fVisible := true;   // never hide the primary - if it's needed as an effect, make the graphic blank
  end else begin
    // If NOT primary - load triggers
    aSegment.DoForEachSection('trigger',
      procedure(aSec: TParserSection; const aCount: Integer)
      var
        NewTrigger: TGadgetAnimationTrigger;
      begin
        NewTrigger := TGadgetAnimationTrigger.Create;
        NewTrigger.Load(aSec);
        fTriggers.Add(NewTrigger);
      end
    );
  end;

  fNeedRemask := true;
  fMaskColor := $FFFFFFFF;
end;

procedure TGadgetAnimation.Clear;
begin
  fSourceImage.SetSize(ResMod, ResMod);
  fSourceImage.Clear(0);
  fMaskColor := $FFFFFFFF;

  fTriggers.Clear;

  fFrameCount := 1;
  fName := '';
  fColor := '';

  // leave fPrimary unaffected
  fHorizontalStrip := false;

  fZIndex := 0;
  fStartFrameIndex := 0;

  fWidth := ResMod;
  fHeight := ResMod;

  fOffsetX := 0;
  fOffsetY := 0;

  fCutTop := 0;
  fCutRight := 0;
  fCutBottom := 0;
  fCutLeft := 0;
end;

procedure TGadgetAnimation.Clone(aSrc: TGadgetAnimation);
begin
  fSourceImage.Assign(aSrc.fSourceImage);
  fTriggers.Clone(aSrc.fTriggers);

  fSourceImageMasked.Assign(aSrc.fSourceImageMasked);
  fMaskColor := aSrc.fMaskColor;
  fNeedRemask := aSrc.fNeedRemask;

  fFrameCount := aSrc.fFrameCount;
  fName := aSrc.fName;
  fColor := aSrc.fColor;

  fPrimary := aSrc.fPrimary; // This is one case where we DO want to copy it
  fHorizontalStrip := aSrc.fHorizontalStrip;

  fZIndex := aSrc.fZIndex;
  fStartFrameIndex := aSrc.fStartFrameIndex;

  fWidth := aSrc.fWidth;
  fHeight := aSrc.fHeight;

  fOffsetX := aSrc.fOffsetX;
  fOffsetY := aSrc.fOffsetY;

  fCutTop := aSrc.fCutTop;
  fCutRight := aSrc.fCutRight;
  fCutBottom := aSrc.fCutBottom;
  fCutLeft := aSrc.fCutLeft;
end;

procedure TGadgetAnimation.Rotate90;
var
  Bitmaps: TBitmaps;
  i: Integer;

  Temp: Integer;
begin
  Bitmaps := MakeFrameBitmaps;
  for i := 0 to Bitmaps.Count-1 do
    Bitmaps[i].Rotate90;
  CombineBitmaps(Bitmaps);

  // Rotate mainobject dimensions
  Temp := fMainObjectWidth;
  fMainObjectWidth := fMainObjectHeight;
  fMainObjectHeight := Temp;

  // Rotate offset
  Temp := fOffsetY;
  fOffsetY := fOffsetX;
  fOffsetX := fMainObjectWidth - Temp - fWidth;

  // Rotate edge cuts
  Temp := fCutTop;
  fCutTop := fCutLeft;
  fCutLeft := fCutBottom;
  fCutBottom := fCutRight;
  fCutRight := Temp;
end;

procedure TGadgetAnimation.Flip;
var
  Bitmaps: TBitmaps;
  i: Integer;

  Temp: Integer;
begin
  Bitmaps := MakeFrameBitmaps;
  for i := 0 to Bitmaps.Count-1 do
    Bitmaps[i].FlipHorz;
  CombineBitmaps(Bitmaps);

  // Flip offset
  fOffsetX := fMainObjectWidth - fOffsetX - fWidth;

  // Flip edge cuts
  Temp := fCutLeft;
  fCutLeft := fCutRight;
  fCutRight := Temp;
end;

procedure TGadgetAnimation.Invert;
var
  Bitmaps: TBitmaps;
  i: Integer;

  Temp: Integer;
begin
  Bitmaps := MakeFrameBitmaps;
  for i := 0 to Bitmaps.Count-1 do
    Bitmaps[i].FlipVert;
  CombineBitmaps(Bitmaps);

  // Flip offset
  fOffsetY := fMainObjectHeight - fOffsetY - fHeight;

  // Flip edge cuts
  Temp := fCutBottom;
  fCutBottom := fCutTop;
  fCutTop := Temp;
end;

function TGadgetAnimation.MakeFrameBitmaps(aForceLowRes: Boolean = false): TBitmaps;
var
  i: Integer;
  TempBMP: TBitmap32;
  SrcRect: TRect;
begin
  Result := TBitmaps.Create;
  for i := 0 to fFrameCount-1 do
  begin
    if aForceLowRes then
      TempBMP := TBitmap32.Create(fWidth, fHeight)
    else
      TempBMP := TBitmap32.Create(fWidth * ResMod, fHeight * ResMod);

    TempBMP.Clear(0);

    if fHorizontalStrip then
      SrcRect := SizedRect(TempBMP.Width * i, 0, TempBMP.Width, TempBMP.Height)
    else
      SrcRect := SizedRect(0, TempBMP.Height * i, TempBMP.Width, TempBMP.Height);

    fSourceImage.DrawTo(TempBMP, 0, 0, SrcRect);

    Result.Add(TempBMP);
  end;
end;

procedure TGadgetAnimation.CombineBitmaps(aBitmaps: TBitmaps);
var
  i: Integer;
begin
  fFrameCount := aBitmaps.Count;
  fWidth := aBitmaps[0].Width;
  fHeight := aBitmaps[0].Height;
  fHorizontalStrip := false;

  fSourceImage.SetSize(fWidth, fFrameCount * fHeight);
  fSourceImage.Clear(0);

  for i := 0 to aBitmaps.Count-1 do
    aBitmaps[i].DrawTo(fSourceImage, 0, fHeight * i);

  aBitmaps.Free;

  fNeedRemask := true;
  fMaskColor := $FFFFFFFF;

  fWidth := fWidth div ResMod;
  fHeight := fHeight div ResMod;
end;

// TGadgetAnimations

procedure TGadgetAnimations.AddPrimary(aAnimation: TGadgetAnimation);
begin
  Add(aAnimation);
  if fPrimaryAnimation <> nil then
    fPrimaryAnimation.fPrimary := false;
  fPrimaryAnimation := aAnimation;
  aAnimation.fPrimary := true;
end;

procedure TGadgetAnimations.Clone(aSrc: TGadgetAnimations);
var
  i: Integer;
  NewAnim: TGadgetAnimation;
begin
  Clear;

  NewAnim := TGadgetAnimation.Create(aSrc.PrimaryAnimation.fMainObjectWidth, aSrc.PrimaryAnimation.fMainObjectHeight);
  NewAnim.Clone(aSrc.PrimaryAnimation);
  AddPrimary(NewAnim);

  for i := 0 to aSrc.Count-1 do
  begin
    if aSrc.Items[i].Primary then
      Continue;

    NewAnim := TGadgetAnimation.Create(aSrc.Items[i].fMainObjectWidth, aSrc.Items[i].fMainObjectHeight);
    NewAnim.Clone(aSrc.Items[i]);

    Add(NewAnim);
  end;

  SortByZIndex;
end;

procedure TGadgetAnimations.Remask(aTheme: TNeoTheme);
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Remask(aTheme);
end;

procedure TGadgetAnimations.Rotate90;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Rotate90;
end;

procedure TGadgetAnimations.Flip;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Flip;
end;

function TGadgetAnimations.GetAnimation(aIdentifier: String): TGadgetAnimation;
var
  i: Integer;
begin
  if aIdentifier = '' then
  begin
    Result := fPrimaryAnimation;
    Exit;
  end;

  aIdentifier := Uppercase(Trim(aIdentifier));

  for i := 0 to Count-1 do
    if Items[i].Name = aIdentifier then
    begin
      Result := Items[i];
      Exit;
    end;

  Result := nil;
end;

function TGadgetAnimations.GetAnyMasked: Boolean;
var
  i: Integer;
begin
  Result := true;
  for i := 0 to Count-1 do
    if Items[i].fColor <> '' then
      Exit;
  Result := false;
end;

procedure TGadgetAnimations.Invert;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Invert;
end;

procedure TGadgetAnimations.SortByZIndex;
begin
  Sort(TComparer<TGadgetAnimation>.Construct(
    function (const L, R: TGadgetAnimation): Integer
    begin
      Result := L.fZIndex - R.fZIndex;
    end
    ));
end;

// TGadgetAnimationTrigger

procedure TGadgetAnimationTrigger.Clone(aSrc: TGadgetAnimationTrigger);
begin
  fCondition := aSrc.fCondition;
  fState := aSrc.fState;
  fVisible := aSrc.fVisible;
end;

procedure TGadgetAnimationTrigger.Load(aSegment: TParserSection);
var
  S: String;
begin
  S := Uppercase(aSegment.LineTrimString['CONDITION']);

  if      S = 'READY' then fCondition := gatcReady
  else if S = 'BUSY' then fCondition := gatcBusy
  else if S = 'DISABLED' then fCondition := gatcDisabled
  else if S = 'EXHAUSTED' then fCondition := gatcExhausted
  else fCondition := gatcUnconditional;

  fVisible := aSegment.Line['hide'] = nil;

  if (not fVisible) and (aSegment.Line['state'] = nil) then
    fState := gasPause
  else begin
    S := Uppercase(aSegment.LineTrimString['state']);

    if S = 'PAUSE' then
      fState := gasPause
    else if S = 'STOP' then
      fState := gasStop
    else if S = 'LOOPTOZERO' then
      fState := gasLoopToZero
    else if S = 'MATCHPHYSICS' then
      fState := gasMatchPrimary   
    else
      fState := gasPlay;
  end;
end;

// TGadgetAnimationTriggers

procedure TGadgetAnimationTriggers.Clone(aSrc: TGadgetAnimationTriggers);
var
  i: Integer;
  NewTrigger: TGadgetAnimationTrigger;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    NewTrigger := TGadgetAnimationTrigger.Create;
    NewTrigger.Clone(aSrc[i]);
    Add(NewTrigger);
  end;
end;

end.