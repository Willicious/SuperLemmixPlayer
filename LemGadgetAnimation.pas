unit LemGadgetAnimation;

interface

uses
  LemNeoTheme,
  LemStrings,
  Generics.Collections, Generics.Defaults,
  PngInterface,
  UMisc,
  LemTypes,
  LemNeoParser,
  GR32,
  Classes,
  SysUtils;

type
  TGadgetAnimationState = (gasPlay, gasPause, gasLoopToZero, gasStop, gasMatchPrimary);

  TGadgetAnimationTriggerCondition = (gatcUnconditional, gatcReady, gatcBusy, gatcDisabled,
                                      gatcDisarmed, gatcLeft, gatcRight);
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


  OBJECT TYPE     | gatcUnconditional
  ----------------|-----------------------------------
  GENERAL RULE    | Always true, for all objects
  Anything        | Always true


  OBJECT TYPE     | gatcReady
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true if the object would able to interact with a lemming at this moment
  DOM_NONE        | Always false (?)
  DOM_TRAP        | True when the trap is idle (but not disabled)
  DOM_TELEPORT    | True when the teleporter and its paired receiver (if any) are idle
  DOM_RECEIVER    | True when the receiver and its paired teleporter (if any) are idle
  DOM_PICKUP      | True when the skill has not been picked up
  DOM_LOCKEXIT    | True when the exit is open (not just opening - must be fully open)
  DOM_BUTTON      | True when the button has not been pressed
  DOM_WINDOW      | True when the window is open (not just opening - must be fully open)
  DOM_BACKGROUND  | Always false (?)
  DOM_TRAPONCE    | True when the trap has not yet been triggered (or disabled)
  All others      | Always true


  OBJECT TYPE     | gatcBusy
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true when the object is transitioning between states, or currently in use
  DOM_TRAP        | True when the trap is mid-kill
  DOM_TELEPORT    | True when the teleporter, or its paired receiver, are mid-operation
  DOM_RECEIVER    | True when the receiver, or its paired teleporter, are mid-operation
  DOM_LOCKEXIT    | True when the exit is in the process of opening
  DOM_WINDOW      | True when the window is in the process of opening
  DOM_TRAPONCE    | True when the trap is mid-kill
  All others      | Always false


  OBJECT TYPE     | gatcDisabled
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true when the object is unable to interact with a lemming, either permanently or
                  | until some external condition is fulfilled.
  DOM_NONE        | Always true (?)
  DOM_TRAP        | True if the trap has been disabled (most likely by a disarmer)
  DOM_TELEPORT    | True if no receiver exists on the level
  DOM_RECEIVER    | True if no teleporter exists on the level
  DOM_PICKUP      | True if the skill has been picked up
  DOM_LOCKEXIT    | True while the exit is in a locked state
  DOM_BUTTON      | True when the button has been pressed
  DOM_WINDOW      | Always false (? - maybe, "true when no more lemmings are to be released")
  DOM_BACKGROUND  | Always true (?)
  DOM_TRAPONCE    | True when the trap has been disabled (most likely by a disarmer) or used
  All others      | Always false


  OBJECT TYPE     | gatcDisarmed
  ----------------|-----------------------------------
  GENERAL RULE    | The condition will be true if a Disarmer has deactivated the object. Exists as a separate condition
                  | from Disabled for the purpose of single-use traps, which may want to differentiate between disarmed
                  | and used.
  DOM_TRAP        | True if the trap has been disarmed
  DOM_TRAPONCE    | True if the trap has been disarmed
  All others      | Always false


  OBJECT TYPE     | gatcLeft
  ----------------|-----------------------------------
  GENERAL RULE    | True if a direction-sensitive object is currently facing left.
  DOM_FLIPPER     | True if the splitter will turn the next lemming to the left
  DOM_WINDOW      | True if the window releases lemmings facing left
  All others      | Always false


  OBJECT TYPE     | gatcRight
  ----------------|-----------------------------------
  GENERAL RULE    | True if a direction-sensitive object is currently facing left.
  DOM_FLIPPER     | True if the splitter will turn the next lemming to the left
  DOM_WINDOW      | True if the window releases lemmings facing left
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
      fTempOutBitmap: TBitmap32;
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

      function MakeFrameBitmaps: TBitmaps;
      procedure CombineBitmaps(aBitmaps: TBitmaps);
      function GetCutRect: TRect;
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

      function GetFrameBitmap(aFrame: Integer; aPersistent: Boolean = false): TBitmap32;
      procedure GetFrame(aFrame: Integer; aBitmap: TBitmap32);

      procedure Draw(Dst: TBitmap32; X, Y: Integer; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil); overload;
      procedure Draw(Dst: TBitmap32; DstRect: TRect; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil); overload;

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
    fTempOutBitmap := TBitmap32.Create;
  Inc(fTempBitmapUsageCount);
end;

destructor TGadgetAnimation.Destroy;
begin
  Dec(fTempBitmapUsageCount);
  if (fTempBitmapUsageCount = 0) then
    fTempoutBitmap.Free;

  fTriggers.Free;
  fSourceImage.Free;
  fSourceImageMasked.Free;
  inherited;
end;

procedure TGadgetAnimation.Remask(aTheme: TNeoTheme);
begin
  fNeedRemask := false;

  if aTheme <> nil then
  begin
    if aTheme.Colors[fColor] = fMaskColor then
      Exit;

    fMaskColor := aTheme.Colors[fColor];
  end;

  fSourceImageMasked.Assign(fSourceImage);

  if fColor <> '' then
    TPngInterface.MaskImageFromImage(fSourceImageMasked, fSourceImageMasked, fMaskColor);
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; X, Y, aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil);
begin
  Draw(Dst, SizedRect(X, Y, fWidth, fHeight), aFrame, aPixelCombine);
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; DstRect: TRect; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil);
var
  SrcRect: TRect;
begin
  if fNeedRemask then
    Remask(nil);

  if not Assigned(aPixelCombine) then
  begin
    fSourceImageMasked.DrawMode := dmBlend;
    fSourceImageMasked.CombineMode := cmMerge;
  end else begin
    fSourceImageMasked.DrawMode := dmCustom;
    fSourceImageMasked.OnPixelCombine := aPixelCombine;
  end;

  if fHorizontalStrip then
    SrcRect := SizedRect(aFrame * fWidth, 0, fWidth, fHeight)
  else
    SrcRect := SizedRect(0, aFrame * fHeight, fWidth, fHeight);

  fSourceImageMasked.DrawTo(Dst, DstRect, SrcRect);
end;

function TGadgetAnimation.GetFrameBitmap(aFrame: Integer; aPersistent: Boolean = false): TBitmap32;
begin
  if aPersistent then
    Result := TBitmap32.Create(fWidth, fHeight)
  else
    Result := fTempOutBitmap;

  Result.DrawMode := dmBlend;
  Result.CombineMode := cmMerge;

  GetFrame(aFrame, Result);
end;

procedure TGadgetAnimation.GetFrame(aFrame: Integer; aBitmap: TBitmap32);
begin
  aBitmap.SetSize(fWidth, fHeight);
  aBitmap.Clear(0);
  Draw(aBitmap, 0, 0, aFrame);
end;

function TGadgetAnimation.GetCutRect: TRect;
begin
  Result := Rect(fCutLeft, fCutTop, fCutRight, fCutBottom);
end;

procedure TGadgetAnimation.Load(aCollection, aPiece: String; aSegment: TParserSection; aTheme: TNeoTheme);
var
  BaseTrigger: TGadgetAnimationTrigger;
  LoadPath: String;
begin
  Clear;

  fFrameCount := aSegment.LineNumeric['frames'];
  fName := UpperCase(aSegment.LineTrimString['name']);
  fColor := UpperCase(aSegment.LineTrimString['color']);

  LoadPath := AppPath + SFStyles + aCollection + '\objects\' + aPiece;
  if fName <> '' then
    LoadPath := LoadPath + '_' + fName; // for backwards-compatible or simply unnamed primaries
  LoadPath := LoadPath + '.png';

  TPngInterface.LoadPngFile(LoadPath, fSourceImage);

  // fPrimary is only set by TGadgetAnimations
  fHorizontalStrip := aSegment.Line['horizontal_strip'] <> nil;

  if fPrimary and (aSegment.Line['z_index'] = nil) then
    fZIndex := 1
  else
    fZIndex := aSegment.LineNumeric['z_index'];

  fStartFrameIndex := aSegment.LineNumeric['initial_frame'];

  if fHorizontalStrip then
  begin
    fWidth := fSourceImage.Width div fFrameCount;
    fHeight := fSourceImage.Height;
  end else begin
    fWidth := fSourceImage.Width;
    fHeight := fSourceImage.Height div fFrameCount;
  end;

  if fPrimary then
  begin
    fMainObjectWidth := fWidth;
    fMainObjectHeight := fHeight;
  end;

  fOffsetX := aSegment.LineNumeric['offset_x'];
  fOffsetY := aSegment.LineNumeric['offset_y'];

  fCutTop := aSegment.LineNumeric['cut_top'];
  fCutRight := aSegment.LineNumeric['cut_right'];
  fCutBottom := aSegment.LineNumeric['cut_bottom'];
  fCutLeft := aSegment.LineNumeric['cut_left'];

  BaseTrigger := TGadgetAnimationTrigger.Create;

  if (aSegment.Line['pause'] <> nil) or fPrimary then
    BaseTrigger.fState := gasPause
  else if (aSegment.Line['stop'] <> nil) then
    BaseTrigger.fState := gasStop
  else if (aSegment.Line['loop_to_zero'] <> nil) then
    BaseTrigger.fState := gasLoopToZero
  else if (aSegment.Line['match_primary_frame'] <> nil) then
    BaseTrigger.fState := gasMatchPrimary
  else if (aSegment.Line['hide'] <> nil) then
    BaseTrigger.fState := gasStop
  else
    BaseTrigger.fState := gasPlay;

  if (aSegment.Line['hide'] = nil) or fPrimary then
    BaseTrigger.fVisible := true
  else
    BaseTrigger.fVisible := false;

  fTriggers.Add(BaseTrigger);

  if not fPrimary then
  begin
    // No triggers on primary
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
end;

procedure TGadgetAnimation.Clear;
begin
  fSourceImage.SetSize(1, 1);
  fSourceImage.Clear(0);
  fMaskColor := $00000000;

  fTriggers.Clear;

  fFrameCount := 1;
  fName := '';
  fColor := '';

  // leave fPrimary unaffected
  fHorizontalStrip := false;

  fZIndex := 0;
  fStartFrameIndex := 0;

  fWidth := 1;
  fHeight := 1;

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

  fNeedRemask := true;
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

  fNeedRemask := true;
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

  fNeedRemask := true;
end;

function TGadgetAnimation.MakeFrameBitmaps: TBitmaps;
var
  i: Integer;
  TempBMP: TBitmap32;

  OldColor: String;
  OldMaskColor: TColor32;
begin
  OldColor := fColor;
  OldMaskColor := fMaskColor;
  try
    fColor := '';
    fMaskColor := $FFFFFFFF;
    Remask(nil);

    Result := TBitmaps.Create;
    for i := 0 to fFrameCount-1 do
    begin
      TempBMP := TBitmap32.Create(fWidth, fHeight);
      TempBMP.Clear(0);
      Draw(TempBMP, 0, 0, i);

      Result.Add(TempBMP);
    end;
  finally
    fColor := OldColor;
    fMaskColor := OldMaskColor;
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
  fSourceImage.Clear;

  for i := 0 to aBitmaps.Count-1 do
    aBitmaps[i].DrawTo(fSourceImage, 0, fHeight * i);

  aBitmaps.Free;

  fNeedRemask := true;
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

  function ParseConditionState(aValue: String): TGadgetAnimationTriggerState;
  begin
    S := Uppercase(aSegment.LineTrimString[aValue]);
    if S = 'TRUE' then
      Result := gatsTrue
    else if S = 'FALSE' then
      Result := gatsFalse
    else
      Result := gatsDontCare;
  end;
begin
  S := Uppercase(aSegment.LineTrimString['CONDITION']);

  if      S = 'READY' then fCondition := gatcReady
  else if S = 'BUSY' then fCondition := gatcBusy
  else if S = 'DISABLED' then fCondition := gatcDisabled
  else if S = 'DISARMED' then fCondition := gatcDisarmed
  else if S = 'LEFT' then fCondition := gatcLeft
  else if S = 'RIGHT' then fCondition := gatcRight
  else fCondition := gatcUnconditional;

  fVisible := aSegment.Line['hide'] = nil;

  if (not fVisible) and (aSegment.Line['state'] = nil) then
    fState := gasStop
  else begin
    S := Uppercase(aSegment.LineTrimString['state']);

    if S = 'PAUSE' then
      fState := gasPause
    else if S = 'STOP' then
      fState := gasStop
    else if S = 'LOOP_TO_ZERO' then
      fState := gasLoopToZero
    else if S = 'MATCH_PRIMARY_FRAME' then
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