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
  SysUtils;

type
  TGadgetAnimationState = (gasPlay, gasPause, gasLoopToZero, gasStop);
  TGadgetAnimationVisibility = (gavVisible, gavHidden);

  TGadgetAnimationTrigger = (gatFrameZero, gatFrameOne, gatTriggered, gatDisabled);
  TGadgetAnimationTriggerState = (gatsDontCare, gatsTrue, gatsFalse);

  {
  Triggers can be used to define when a secondary animation is visible. Certain
  objects support certain trigger conditions. All objects can support
  unconditional secondary animations, so even those with no triggers can still
  make use of secondaries.

  gatFrameZero - TRUE on frame zero, if this is significant to the object.
  gatFrameOne - TRUE on frame one, if this is significant to the object.
  gatTriggered - TRUE when object is in triggered state. For teleporters / receivers, this includes the paired object's state.
  gatDisabled - Varies by object. Sometimes identical to another trigger.

  The "gatsDontCare" state is not returned by tests (they will return gatFalse
  where not supported). It is only used when defining conditions, and usually,
  only internally.


  The basic animation states are Play and Pause. Others will eventually change
  to one of these.

  gasLoopToZero - Changes to gasPause when frame 0 is reached
  gasStop - Sets frame to 0 then changes to gasPause

  The visibility state sets whether the animation is visible or not. It will
  be treated as gavVisible any time the animation is playing - it must be paused
  to hide the animation.


  OBJECT TYPE     | gatFrameZero | gatFrameOne | gatTriggered | gatDisabled
  ----------------|--------------|-------------|--------------|-------------
  DOM_NONE        | No           | No          | No           | No
  DOM_EXIT        | No           | No          | No           | No
  DOM_FORCExxxxx  | No           | No          | No           | No
  DOM_TRAP        | Yes          | No          | Yes          | Yes (when disarmed)
  DOM_WATER       | No           | No          | No           | No
  DOM_FIRE        | No           | No          | No           | No
  DOM_ONEWAYxxxxx | No           | No          | No           | No
  DOM_TELEPORT    | Yes          | No          | Yes (pair)   | Yes (when no pair exists)
  DOM_RECEIVER    | Yes          | No          | Yes (pair)   | Yes (when no pair exists)
  DOM_PICKUP      | Yes          | Yes*        | No           | equal to gatFrameZero    * gatFrameOne here triggers on frame != 0
  DOM_LOCKEXIT    | Yes          | Yes         | Yes          | equal to gatFrameOne
  DOM_BUTTON      | Yes          | Yes         | No           | No
  DOM_UPDRAFT     | No           | No          | No           | No
  DOM_FLIPPER     | Yes          | Yes         | No           | No
  DOM_WINDOW      | Yes          | Yes         | Yes          | No
  DOM_SPLAT       | No           | No          | No           | No
  DOM_BACKGROUND  | No           | No          | No           | No
  DOM_TRAPONCE    | Yes          | Yes         | Yes          | Yes (when disarmed - NOT when used!)

  }

  TGadgetAnimation = class
    private
      class var fTempOutBitmap: TBitmap32;
      class var fTempBitmapUsageCount: Integer;
    private
      fMainObjectWidth: Integer;
      fMainObjectHeight: Integer;

      fFrameCount: Integer;
      fName: String;
      fColor: String;

      fPrimary: Boolean;
      fHorizontalStrip: Boolean;

      fZIndex: Integer;

      fAlwaysAnimate: Boolean;
      fInstantStop: Boolean;
      fPreviewFrameIndex: Integer;

      fWidth: Integer;
      fHeight: Integer;

      fOffsetX: Integer;
      fOffsetY: Integer;

      fCutTop: Integer;
      fCutRight: Integer;
      fCutBottom: Integer;
      fCutLeft: Integer;

      fSourceImage: TBitmap32;

      function MakeFrameBitmaps: TBitmaps;
      procedure CombineBitmaps(aBitmaps: TBitmaps);

      function GetRandomStartFrame: Boolean;
    public
      constructor Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
      destructor Destroy; override;

      procedure Load(aCollection, aPiece: String; aSegment: TParserSection; aTheme: TNeoTheme);
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

      property FrameCount: Integer read fFrameCount;
      property HorizontalStrip: Boolean read fHorizontalStrip;

      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property OffsetX: Integer read fOffsetX write fOffsetX;
      property OffsetY: Integer read fOffsetY write fOffsetY;

      property AlwaysAnimate: Boolean read fAlwaysAnimate write fAlwaysAnimate;
      property ZIndex: Integer read fZIndex write fZIndex;
      property Primary: Boolean read fPrimary write fPrimary;
      property InstantStop: Boolean read fInstantStop write fInstantStop;

      property CutTop: Integer read fCutTop write fCutTop;
      property CutRight: Integer read fCutRight write fCutRight;
      property CutBottom: Integer read fCutBottom write fCutBottom;
      property CutLeft: Integer read fCutLeft write fCutLeft;
  end;

  TGadgetAnimations = class(TObjectList<TGadgetAnimation>)
    private
      fPrimaryAnimation: TGadgetAnimation;
    public
      procedure AddPrimary(aAnimation: TGadgetAnimation);

      procedure SortByZIndex;

      procedure Clone(aSrc: TGadgetAnimations);
      procedure Rotate90;
      procedure Flip;
      procedure Invert;

      property PrimaryAnimation: TGadgetAnimation read fPrimaryAnimation;
  end;

implementation

// TGadgetAnimation

constructor TGadgetAnimation.Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
begin
  inherited Create;
  fSourceImage := TBitmap32.Create;

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

  fSourceImage.Free;
  inherited;
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; X, Y, aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil);
begin
  Draw(Dst, SizedRect(X, Y, fWidth, fHeight), aFrame, aPixelCombine);
end;

procedure TGadgetAnimation.Draw(Dst: TBitmap32; DstRect: TRect; aFrame: Integer; aPixelCombine: TPixelCombineEvent = nil);
var
  SrcRect: TRect;
begin
  if not Assigned(aPixelCombine) then
    fSourceImage.DrawMode := dmBlend
  else begin
    fSourceImage.DrawMode := dmCustom;
    fSourceImage.OnPixelCombine := aPixelCombine;
  end;

  if fHorizontalStrip then
    SrcRect := SizedRect(aFrame * fWidth, 0, fWidth, fHeight)
  else
    SrcRect := SizedRect(0, aFrame * fHeight, fWidth, fHeight);

  fSourceImage.DrawTo(Dst, DstRect, SrcRect);
end;

function TGadgetAnimation.GetFrameBitmap(aFrame: Integer; aPersistent: Boolean = false): TBitmap32;
begin
  if aPersistent then
    Result := TBitmap32.Create(fWidth, fHeight)
  else
    Result := fTempOutBitmap;

  GetFrame(aFrame, Result);
end;

procedure TGadgetAnimation.GetFrame(aFrame: Integer; aBitmap: TBitmap32);
begin
  aBitmap.SetSize(fWidth, fHeight);
  aBitmap.Clear(0);
  Draw(aBitmap, 0, 0, aFrame);
end;

procedure TGadgetAnimation.Load(aCollection, aPiece: String; aSegment: TParserSection; aTheme: TNeoTheme);
begin
  fFrameCount := aSegment.LineNumeric['frames'];
  fName := UpperCase(aSegment.LineTrimString['name']);
  fColor := UpperCase(aSegment.LineTrimString['color']);

  TPngInterface.LoadPngFile(AppPath + SFStyles + aCollection + '\' + aPiece + '_' + fName + '.png', fSourceImage);
  if fColor <> '' then
    TPngInterface.MaskImageFromImage(fSourceImage, fSourceImage, aTheme.Colors[fColor]);

  // fPrimary is only set by TGadgetAnimations
  fHorizontalStrip := aSegment.Line['horizontal_strip'] <> nil;

  fZIndex := aSegment.LineNumeric['z_index'];

  fAlwaysAnimate := aSegment.Line['always_animate'] <> nil;
  fInstantStop := aSegment.Line['instant_stop'] <> nil;
  fPreviewFrameIndex := aSegment.LineNumeric['preview_frame'];
  // fIsMasked is set when loading masks

  if fHorizontalStrip then
  begin
    fWidth := fSourceImage.Width div fFrameCount;
    fHeight := fSourceImage.Height;
  end else begin
    fWidth := fSourceImage.Width;
    fHeight := fSourceImage.Height div fFrameCount;
  end;

  fOffsetX := aSegment.LineNumeric['offset_x'];
  fOffsetY := aSegment.LineNumeric['offset_y'];

  fCutTop := aSegment.LineNumeric['cut_top'];
  fCutRight := aSegment.LineNumeric['cut_right'];
  fCutBottom := aSegment.LineNumeric['cut_bottom'];
  fCutLeft := aSegment.LineNumeric['cut_left'];
end;

procedure TGadgetAnimation.Clear;
begin
  fSourceImage.SetSize(1, 1);
  fSourceImage.Clear(0);

  fFrameCount := 1;
  fName := '';
  fColor := '';

  // leave fPrimary unaffected
  fHorizontalStrip := false;

  fZIndex := 0;

  fAlwaysAnimate := false;
  fInstantStop := false;
  fPreviewFrameIndex := 0;

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

  fFrameCount := aSrc.fFrameCount;
  fName := aSrc.fName;
  fColor := aSrc.fColor;

  fPrimary := aSrc.fPrimary; // This is one case where we DO want to copy it
  fHorizontalStrip := aSrc.fHorizontalStrip;

  fZIndex := aSrc.fZIndex;

  fAlwaysAnimate := aSrc.fAlwaysAnimate;
  fInstantStop := aSrc.fInstantStop;
  fPreviewFrameIndex := aSrc.fPreviewFrameIndex;

  fWidth := aSrc.fWidth;
  fHeight := aSrc.fHeight;

  fOffsetX := aSrc.fOffsetX;
  fOffsetY := aSrc.fOffsetY;

  fCutTop := aSrc.fCutTop;
  fCutRight := aSrc.fCutRight;
  fCutBottom := aSrc.fCutBottom;
  fCutLeft := aSrc.fCutLeft;
end;

function TGadgetAnimation.GetRandomStartFrame: Boolean;
begin
  Result := fPreviewFrameIndex < 0;
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

function TGadgetAnimation.MakeFrameBitmaps: TBitmaps;
var
  i: Integer;
  TempBMP: TBitmap32;
begin
  Result := TBitmaps.Create;
  for i := 0 to fFrameCount-1 do
  begin
    TempBMP := TBitmap32.Create(fWidth, fHeight);
    TempBMP.Clear(0);
    Draw(TempBMP, 0, 0, i);

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
  fSourceImage.Clear;

  for i := 0 to aBitmaps.Count-1 do
    aBitmaps[i].DrawTo(fSourceImage, 0, fHeight * i);

  aBitmaps.Free;
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

  for i := 0 to aSrc.Count-1 do
  begin
    NewAnim := TGadgetAnimation.Create(aSrc[i].fMainObjectWidth, aSrc[i].fMainObjectHeight);
    NewAnim.Clone(aSrc[i]);

    Add(NewAnim);
  end;
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

end.