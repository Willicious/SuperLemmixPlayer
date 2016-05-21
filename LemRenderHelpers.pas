unit LemRenderHelpers;

// Moved some stuff here from LemRendering so that I can reference it in
// LemNeoGraphicSet without circular dependancy.

interface

uses
  LemTypes,
  UMisc,
  GR32, GR32_LowLevel, GR32_Resamplers,
  Contnrs, Classes, SysUtils;

type

  TRenderLayer = (rlBackground,
                  rlBackgroundObjects,
                  rlObjectsLow,
                  rlLowShadows,
                  rlTerrain,
                  rlObjectsHigh,
                  rlHighShadows,
                  rlParticles,
                  rlLemmings);

  TRenderBitmaps = class(TBitmaps)
  private
    fWidth: Integer;
    fHeight: Integer;
    function GetItem(Index: TRenderLayer): TBitmap32;
  protected
  public
    constructor Create;
    procedure Prepare(aWidth, aHeight: Integer);
    procedure CombineTo(aDst: TBitmap32);
    property Items[Index: TRenderLayer]: TBitmap32 read GetItem; default;
    property List;
    property Width: Integer read fWidth;
    property Height: Integer read fHeight;
  published
  end;

  TDrawItem = class
  private
  protected
    fOriginal: TBitmap32; // reference
  public
    constructor Create(aOriginal: TBitmap32);
    destructor Destroy; override;
    property Original: TBitmap32 read fOriginal;
  end;

  TDrawList = class(TObjectList)
  private
    function GetItem(Index: Integer): TDrawItem;
  protected
  public
    function Add(Item: TDrawItem): Integer;
    procedure Insert(Index: Integer; Item: TDrawItem);
    property Items[Index: Integer]: TDrawItem read GetItem; default;
  published
  end;

  TAnimation = class(TDrawItem)
  private
    procedure Check;
    procedure CheckFrame(Bmp: TBitmap32);
  protected
    fFrameHeight: Integer;
    fFrameCount: Integer;
    fFrameWidth: Integer;
  public
    constructor Create(aOriginal: TBitmap32; aFrameCount, aFrameWidth, aFrameHeight: Integer);
    function CalcFrameRect(aFrameIndex: Integer): TRect;
    function CalcTop(aFrameIndex: Integer): Integer;
    procedure InsertFrame(Bmp: TBitmap32; aFrameIndex: Integer);
    procedure GetFrame(Bmp: TBitmap32; aFrameIndex: Integer);
    property FrameCount: Integer read fFrameCount default 1;
    property FrameWidth: Integer read fFrameWidth;
    property FrameHeight: Integer read fFrameHeight;
  end;

  TObjectAnimation = class(TAnimation)
  private
  protected
    fInverted: TBitmap32; // copy of original
    procedure Flip;
  public
    constructor Create(aOriginal: TBitmap32; aFrameCount, aFrameWidth, aFrameHeight: Integer);
    destructor Destroy; override;
    property Inverted: TBitmap32 read fInverted;
  end;

implementation

uses
  UTools;

{ TDrawItem }

constructor TDrawItem.Create(aOriginal: TBitmap32);
begin
  inherited Create;
  fOriginal := aOriginal;
end;

destructor TDrawItem.Destroy;
begin
  inherited Destroy;
end;

{ TDrawList }

function TDrawList.Add(Item: TDrawItem): Integer;
begin
  Result := inherited Add(Item);
end;

function TDrawList.GetItem(Index: Integer): TDrawItem;
begin
  Result := inherited Get(Index);
end;

procedure TDrawList.Insert(Index: Integer; Item: TDrawItem);
begin
  inherited Insert(Index, Item);
end;

{ TAnimation }

function TAnimation.CalcFrameRect(aFrameIndex: Integer): TRect;
begin
  with Result do
  begin
    Left := 0;
    Top := aFrameIndex * fFrameHeight;
    Right := Left + fFrameWidth;
    Bottom := Top + fFrameHeight;
  end;
end;

function TAnimation.CalcTop(aFrameIndex: Integer): Integer;
begin
  Result := aFrameIndex * fFrameHeight;
end;

procedure TAnimation.Check;
begin
  Assert(fFrameCount <> 0);
  Assert(Original.Width = fFrameWidth);
  Assert(fFrameHeight * fFrameCount = Original.Height);
end;

procedure TAnimation.CheckFrame(Bmp: TBitmap32);
begin
  Assert(Bmp.Width = Original.Width);
  Assert(Bmp.Height * fFrameCount = Original.Height);
end;

constructor TAnimation.Create(aOriginal: TBitmap32; aFrameCount, aFrameWidth, aFrameHeight: Integer);
begin
  inherited Create(aOriginal);
  fFrameCount := aFrameCount;
  fFrameWidth := aFrameWidth;
  fFrameHeight := aFrameHeight;
  Check;
end;

procedure TAnimation.GetFrame(Bmp: TBitmap32; aFrameIndex: Integer);
// unsafe
var
  Y, W: Integer;
  SrcP, DstP: PColor32;
begin
  Check;
  Bmp.SetSize(fFrameWidth, fFrameHeight);
  DstP := Bmp.PixelPtr[0, 0];
  SrcP := Original.PixelPtr[0, CalcTop(aFrameIndex)];
  W := fFrameWidth;
  for Y := 0 to fFrameHeight - 1 do
    begin
      MoveLongWord(SrcP^, DstP^, W);
      Inc(SrcP, W);
      Inc(DstP, W);
    end;
end;

procedure TAnimation.InsertFrame(Bmp: TBitmap32; aFrameIndex: Integer);
// unsafe
var
  Y, W: Integer;
  SrcP, DstP: PColor32;
begin
  Check;
  CheckFrame(Bmp);

  SrcP := Bmp.PixelPtr[0, 0];
  DstP := Original.PixelPtr[0, CalcTop(aFrameIndex)];
  W := fFrameWidth;

  for Y := 0 to fFrameHeight - 1 do
    begin
      MoveLongWord(SrcP^, DstP^, W);
      Inc(SrcP, W);
      Inc(DstP, W);
    end;
end;

{ TObjectAnimation }

constructor TObjectAnimation.Create(aOriginal: TBitmap32; aFrameCount,
  aFrameWidth, aFrameHeight: Integer);
begin
  inherited;
  fInverted := TBitmap32.Create;
  fInverted.Assign(aOriginal);
  Flip;
end;

destructor TObjectAnimation.Destroy;
begin
  fInverted.Free;
  inherited;
end;

procedure TObjectAnimation.Flip;
//unsafe, can be optimized by making a algorithm
var
  Temp: TBitmap32;
  i: Integer;

      procedure Ins(aFrameIndex: Integer);
      var
        Y, W: Integer;
        SrcP, DstP: PColor32;
      begin
//        Check;
        //CheckFrame(TEBmp);

        SrcP := Temp.PixelPtr[0, 0];
        DstP := Inverted.PixelPtr[0, CalcTop(aFrameIndex)];
        W := fFrameWidth;

        for Y := 0 to fFrameHeight - 1 do
          begin
            MoveLongWord(SrcP^, DstP^, W);
            Inc(SrcP, W);
            Inc(DstP, W);
          end;
      end;

begin
  if fFrameCount = 0 then
    Exit;
  Temp := TBitmap32.Create;
  try
    for i := 0 to fFrameCount - 1 do
    begin
      GetFrame(Temp, i);
      Temp.FlipVert;
      Ins(i);
    end;
  finally
    Temp.Free;
  end;
end;

{ TRenderBitmaps }

constructor TRenderBitmaps.Create;
var
  i: TRenderLayer;
  BMP: TBitmap32;
begin
  inherited Create(true);
  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    BMP := TBitmap32.Create;
    BMP.DrawMode := dmBlend;
    BMP.CombineMode := cmMerge;
    TLinearResampler.Create(BMP);
    Add(BMP);
  end;
end;

function TRenderBitmaps.GetItem(Index: TRenderLayer): TBitmap32;
begin
  Result := inherited Get(Integer(Index));
end;

procedure TRenderBitmaps.Prepare(aWidth, aHeight: Integer);
var
  i: TRenderLayer;
begin
  fWidth := aWidth;
  fHeight := aHeight;
  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    Items[i].SetSize(Width, Height);
    Items[i].Clear($00000000);
  end;
end;

procedure TRenderBitmaps.CombineTo(aDst: TBitmap32);
var
  i: TRenderLayer;
begin
  aDst.Clear;
  //aDst.SetSize(Width, Height); //not sure if we really want to do this
  for i := Low(TRenderLayer) to High(TRenderLayer) do
    Items[i].DrawTo(aDst, aDst.BoundsRect);
end;

end.
