unit LemRenderHelpers;

// Moved some stuff here from LemRendering so that I can reference it in
// LemNeoGraphicSet without circular dependancy.

interface

uses
  LemTypes,
  UMisc,
  GR32, GR32_Blend, GR32_LowLevel, GR32_Resamplers,
  Contnrs, Classes, SysUtils;

type

  TRenderLayer = (rlBackground,
                  rlBackgroundObjects,
                  rlObjectsLow,
                  rlLowShadows,
                  rlTerrain,
                  rlOnTerrainObjects,
                  rlOneWayArrows,
                  rlObjectsHigh,
                  rlHighShadows,
                  rlObjectHelpers,
                  rlParticles,
                  rlLemmings);

  TRenderBitmaps = class(TBitmaps)
  private
    fWidth: Integer;
    fHeight: Integer;
    fPhysicsMap: TBitmap32;
    function GetItem(Index: TRenderLayer): TBitmap32;
    procedure CombinePixelsShadow(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombinePhysicsMapOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombinePhysicsMapOneWays(F: TColor32; var B: TColor32; M: TColor32);
  protected
  public
    constructor Create;
    procedure Prepare(aWidth, aHeight: Integer);
    procedure CombineTo(aDst: TBitmap32);
    property Items[Index: TRenderLayer]: TBitmap32 read GetItem; default;
    property List;
    property Width: Integer read fWidth;
    property Height: Integer read fHeight;
    property PhysicsMap: TBitmap32 write fPhysicsMap;
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

  THelperIcon = (hpi_ArrowLeft, hpi_ArrowRight, hpi_ArrowUp, hpi_ArrowDown, hpi_Exclamation);

  THelperImages = array[Low(THelperIcon)..High(THelperIcon)] of TBitmap32;

const
  HelperImageFilenames: array[Low(THelperIcon)..High(THelperIcon)] of String =
                             ('left_arrow.png',
                              'right_arrow.png',
                              'up_arrow.png',
                              'down_arrow.png',
                              'exclamation.png');

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
    if i in [rlLowShadows, rlHighShadows] then
    begin
      BMP.DrawMode := dmCustom;
      BMP.OnPixelCombine := CombinePixelsShadow;
    end else begin
      BMP.DrawMode := dmBlend;
      BMP.CombineMode := cmBlend;
    end;
    //TLinearResampler.Create(BMP);
    Add(BMP);
  end;
end;

procedure TRenderBitmaps.CombinePixelsShadow(F: TColor32; var B: TColor32; M: TColor32);
var
  A, C: TColor32;
  Red: Integer;
  Green: Integer;
  Blue: Integer;

  procedure ModColor(var Component: Integer);
  begin
    if Component < $80 then
      Component := $C0
    else
      Component := $40;
  end;
begin
  A := F and $FF000000;
  if A = 0 then Exit;
  Red   := (B and $FF0000) shr 16;
  Green := (B and $00FF00) shr 8;
  Blue  := (B and $0000FF);
  ModColor(Red);
  ModColor(Green);
  ModColor(Blue);
  C := ($C0000000) or (Red shl 16) or (Green shl 8) or (Blue);
  BlendMem(C, B);
  //BlendReg(C, B);
end;

procedure TRenderBitmaps.CombinePhysicsMapOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $00000001) = 0 then B := 0;
end;

procedure TRenderBitmaps.CombinePhysicsMapOneWays(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $00000004) = 0 then B := 0;
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
  aDst.BeginUpdate;
  aDst.Clear;
  //aDst.SetSize(Width, Height); //not sure if we really want to do this

  // Tidy up the Only On Terrain and One Way Walls layers
  if fPhysicsMap <> nil then
  begin
    fPhysicsMap.DrawMode := dmCustom;
    fPhysicsMap.OnPixelCombine := CombinePhysicsMapOnlyOnTerrain;
    fPhysicsMap.DrawTo(Items[rlOnTerrainObjects]);
    fPhysicsMap.OnPixelCombine := CombinePhysicsMapOneWays;
    fPhysicsMap.DrawTo(Items[rlOneWayArrows]);
  end;

  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    {if i in [rlBackground,
                  rlBackgroundObjects,
                  rlObjectsLow,
                  rlLowShadows,
                  rlTerrain,
                  rlOneWayArrows,
                  rlObjectsHigh,
                  rlHighShadows,
                  rlParticles,
                  rlLemmings] then Continue;}
    Items[i].DrawTo(aDst, aDst.BoundsRect);
  end;
  aDst.EndUpdate;
  aDst.Changed;
end;

end.
