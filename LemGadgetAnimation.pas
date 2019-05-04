unit LemGadgetAnimation;

interface

uses
  PngInterface,
  UMisc,
  LemTypes,
  LemNeoParser,
  GR32,
  SysUtils;

type
  TGadgetAnimation = class
    private
      fMainObjectWidth: Integer;
      fMainObjectHeight: Integer;

      fFrameCount: Integer;
      fName: String;

      fAlwaysAnimate: Boolean;
      fZIndex: Integer;
      fPrimary: Boolean;
      fInstantStop: Boolean;
      fHorizontalStrip: Boolean;

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
    public
      constructor Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
      destructor Destroy; override;

      procedure Load(aImageFile: String; aSegment: TParserSection);
      procedure Clone(aSrc: TGadgetAnimation);

      procedure Rotate90;
      procedure Flip;
      procedure Invert;

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

implementation

constructor TGadgetAnimation.Create(aMainObjectWidth: Integer; aMainObjectHeight: Integer);
begin
  inherited Create;
  fSourceImage := TBitmap32.Create;

  fMainObjectWidth := aMainObjectWidth;
  fMainObjectHeight := aMainObjectHeight;
end;

destructor TGadgetAnimation.Destroy;
begin
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

procedure TGadgetAnimation.Load(aImageFile: String; aSegment: TParserSection);
begin
  TPngInterface.LoadPngFile(aImageFile, fSourceImage);

  fName := UpperCase(aSegment.LineTrimString['name']);
  fFrameCount := aSegment.LineNumeric['frames'];

  fAlwaysAnimate := aSegment.Line['always_animate'] <> nil;
  fZIndex := aSegment.LineNumeric['z_index'];
  fInstantStop := aSegment.Line['instant_stop'] <> nil;
  fHorizontalStrip := aSegment.Line['horizontal'] <> nil;

  fOffsetX := aSegment.LineNumeric['offset_x'];
  fOffsetY := aSegment.LineNumeric['offset_y'];

  fCutTop := aSegment.LineNumeric['cut_top'];
  fCutRight := aSegment.LineNumeric['cut_right'];
  fCutBottom := aSegment.LineNumeric['cut_bottom'];
  fCutLeft := aSegment.LineNumeric['cut_left'];

  if fHorizontalStrip then
  begin
    fWidth := fSourceImage.Width div fFrameCount;
    fHeight := fSourceImage.Height;
  end else begin
    fWidth := fSourceImage.Width;
    fHeight := fSourceImage.Height div fFrameCount;
  end;
end;

procedure TGadgetAnimation.Clone(aSrc: TGadgetAnimation);
begin
  fSourceImage.Assign(aSrc.fSourceImage);

  fName := aSrc.fName;
  fFrameCount := aSrc.fFrameCount;

  fAlwaysAnimate := aSrc.fAlwaysAnimate;
  fZIndex := aSrc.fZIndex;
  fInstantStop := aSrc.fInstantStop;
  fHorizontalStrip := aSrc.fHorizontalStrip;

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

end.