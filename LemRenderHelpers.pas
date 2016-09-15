unit LemRenderHelpers;

// Moved some stuff here from LemRendering so that I can reference it in
// LemNeoGraphicSet without circular dependancy.

interface

uses
  LemTypes, LemObjects, LemLemming, LemCore,
  UMisc,
  GR32, GR32_Blend, GR32_LowLevel, GR32_Resamplers,
  Contnrs, Classes, SysUtils;

const
  PARTICLE_FRAMECOUNT = 52;
  PARTICLE_COLORS: array[0..7] of TColor32 = ($FF4040E0, $FF00B000, $FFF0D0D0, $FFF02020,
                                              $C04040E0, $C000B000, $C0F0D0D0, $C0F02020);

  PM_SOLID       = $00000001;
  PM_STEEL       = $00000002;
  PM_ONEWAY      = $00000004;
  PM_ONEWAYLEFT  = $00000008;
  PM_ONEWAYRIGHT = $00000010;
  PM_ONEWAYDOWN  = $00000020; // Yes, I know they're mutually incompatible, but it's easier to do this way
  PM_NOCANCELSTEEL = $00000040;

  PM_TERRAIN   = $000000FF;


  SHADOW_COLOR = $80202020;
  ALPHA_CUTOFF = $FF000000; // if (TColor32) and ALPHA_CUTOFF <> 0 then not solid

type

  TDrawableItem = (di_ConstructivePixel, di_Stoner);
  TDrawRoutine = procedure(X, Y: Integer) of object;
  TDrawRoutines = array[Low(TDrawableItem)..High(TDrawableItem)] of TDrawRoutine;
  TRemoveRoutine = procedure(X, Y, Width, Height: Integer) of object;
  TSimulateLemRoutine = function(L: TLemming; DoCheckObjects: Boolean = True): TArrayArrayInt of object;
  TGetLemmingRoutine = function: TLemming of object;

  TRenderLayer = (rlBackground,
                  rlBackgroundObjects,
                  rlObjectsLow,
                  rlLowShadows,
                  rlTerrain,
                  rlOnTerrainObjects,
                  rlOneWayArrows,
                  rlObjectsHigh,
                  rlTriggers,
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
    procedure CombineTriggerLayer(F: TColor32; var B: TColor32; M: TColor32);

    procedure DrawClearPhysicsTerrain(aDst: TBitmap32; aRegion: TRect);
  protected
  public
    fIsEmpty: array[TRenderLayer] of Boolean;

    constructor Create;
    procedure Prepare(aWidth, aHeight: Integer);
    procedure CombineTo(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false); overload;
    procedure CombineTo(aDst: TBitmap32; aClearPhysics: Boolean = false); overload;
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

  THelperIcon = (hpi_A, hpi_B, hpi_C, hpi_D, hpi_E, hpi_F, hpi_G, hpi_H, hpi_I, hpi_J, hpi_K, hpi_L, hpi_M,
                 hpi_N, hpi_O, hpi_P, hpi_Q, hpi_R, hpi_S, hpi_T, hpi_U, hpi_V, hpi_W, hpi_X, hpi_Y, hpi_Z,
                 hpi_ArrowLeft, hpi_ArrowRight, hpi_ArrowUp, hpi_ArrowDown, hpi_Exclamation);

  THelperImages = array[Low(THelperIcon)..High(THelperIcon)] of TBitmap32;

  TRenderInterface = class // Used for communication between GameWindow, LemGame and LemRendering.
    private
      fLemmingList: TLemmingList;
      fObjectList: TInteractiveObjectInfoList;
      fPSelectedSkill: ^TSkillPanelButton;
      fSelectedLemming: TLemming;
      fReplayLemming: TLemming;
      fPhysicsMap: TBitmap32;
      fTerrainMap: TBitmap32;
      fScreenPos: TPoint;
      fMousePos: TPoint;
      fDrawRoutines: TDrawRoutines;
      fRemoveRoutine: TRemoveRoutine;
      fSimulateLemRoutine: TSimulateLemRoutine;
      fGetHighlitLemRoutine: TGetLemmingRoutine;
      function GetSelectedSkill: TSkillPanelButton;
      function GetHighlitLemming: TLemming;
    public
      constructor Create;
      procedure SetSelectedSkillPointer(var aButton: TSkillPanelButton);
      procedure SetDrawRoutine(aItem: TDrawableItem; aRoutine: TDrawRoutine);
      procedure SetRemoveRoutine(aRoutine: TRemoveRoutine);
      procedure SetSimulateLemRoutine(aRoutine: TSimulateLemRoutine);
      procedure SetgetHighlitRoutine(aRoutine: TGetLemmingRoutine);
      procedure AddTerrain(aAddType: TDrawableItem; X, Y: Integer);
      procedure RemoveTerrain(X, Y, Width, Height: Integer);
      function SimulateLem(L: TLemming): TArrayArrayInt;
      property LemmingList: TLemmingList read fLemmingList write fLemmingList;
      property ObjectList: TInteractiveObjectInfoList read fObjectList write fObjectList;
      property SelectedSkill: TSkillPanelButton read GetSelectedSkill;
      property SelectedLemming: TLemming read fSelectedLemming write fSelectedLemming;
      property HighlitLemming: TLemming read GetHighlitLemming;
      property ReplayLemming: TLemming read fReplayLemming write fReplayLemming;
      property PhysicsMap: TBitmap32 read fPhysicsMap write fPhysicsMap;
      property TerrainMap: TBitmap32 read fTerrainMap write fTerrainMap;
      property ScreenPos: TPoint read fScreenPos write fScreenPos;
      property MousePos: TPoint read fMousePos write fMousePos;
  end;

const
  HelperImageFilenames: array[Low(THelperIcon)..High(THelperIcon)] of String =
                             ('ltr_a.png',
                              'ltr_b.png',
                              'ltr_c.png',
                              'ltr_d.png',
                              'ltr_e.png',
                              'ltr_f.png',
                              'ltr_g.png',
                              'ltr_h.png',
                              'ltr_i.png',
                              'ltr_j.png',
                              'ltr_k.png',
                              'ltr_l.png',
                              'ltr_m.png',
                              'ltr_n.png',
                              'ltr_o.png',
                              'ltr_p.png',
                              'ltr_q.png',
                              'ltr_r.png',
                              'ltr_s.png',
                              'ltr_t.png',
                              'ltr_u.png',
                              'ltr_v.png',
                              'ltr_w.png',
                              'ltr_x.png',
                              'ltr_y.png',
                              'ltr_z.png',
                              'left_arrow.png',
                              'right_arrow.png',
                              'up_arrow.png',
                              'down_arrow.png',
                              'exclamation.png');

implementation

uses
  UTools;

{ TRenderInterface }

constructor TRenderInterface.Create;
var
  i: TDrawableItem;
begin
  for i := Low(TDrawableItem) to High(TDrawableItem) do
    fDrawRoutines[i] := nil;
end;

procedure TRenderInterface.SetDrawRoutine(aItem: TDrawableItem; aRoutine: TDrawRoutine);
begin
  fDrawRoutines[aItem] := aRoutine;
end;

procedure TRenderInterface.SetRemoveRoutine(aRoutine: TRemoveRoutine);
begin
  fRemoveRoutine := aRoutine;
end;

procedure TRenderInterface.SetSimulateLemRoutine(aRoutine: TSimulateLemRoutine);
begin
  fSimulateLemRoutine := aRoutine;
end;

procedure TRenderInterface.SetGetHighlitRoutine(aRoutine: TGetLemmingRoutine);
begin
  fGetHighlitLemRoutine := aRoutine;
end;

procedure TRenderInterface.AddTerrain(aAddType: TDrawableItem; X, Y: Integer);
begin
  // TLemmingGame is expected to handle modifications to the physics map.
  // This is to pass to TRenderer for on-screen drawing.
  if Assigned(fDrawRoutines[aAddType]) then
    fDrawRoutines[aAddType](X, Y);
end;

procedure TRenderInterface.RemoveTerrain(X, Y, Width, Height: Integer);
begin
  // This removes terrain from the layer rlTerrain accoding to the physics map
  // within the rectange defined defined by (X, Y, Width, Height)
  // Whenever LemGame removes some terrain, it is expected to call this method!
  fRemoveRoutine(X, Y, Width, Height);
end;

function TRenderInterface.SimulateLem(L: TLemming): TArrayArrayInt;
begin
  Result := fSimulateLemRoutine(L);
end;

function TRenderInterface.GetHighlitLemming: TLemming;
begin
  Result := fGetHighlitLemRoutine;
end;


procedure TRenderInterface.SetSelectedSkillPointer(var aButton: TSkillPanelButton);
begin
  fPSelectedSkill := @aButton;
end;

function TRenderInterface.GetSelectedSkill: TSkillPanelButton;
begin
  Result := fPSelectedSkill^;
end;

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
    (*end else if i = rlTriggers then
    begin
      BMP.DrawMode := dmCustom;
      BMP.OnPixelCombine := CombineTriggerLayer;*)
    end else begin
      BMP.DrawMode := dmBlend;
      BMP.CombineMode := cmBlend;
    end;
    //TLinearResampler.Create(BMP);
    Add(BMP);

    fIsEmpty[i] := True;
  end;

  // Always draw rlBackground, rlTerrain and rlLemmings
  fIsEmpty[rlBackground] := False;
  fIsEmpty[rlTerrain] := False;
  fIsEmpty[rlLemmings] := False;
  // Always set rlObjectHelpers to be non-empty - this needs to be changed when moving this to another layer.
  fIsEmpty[rlObjectHelpers] := False;
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

procedure TRenderBitmaps.CombineTriggerLayer(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F = 0 then Exit;
  if B = 0 then
    B := F
  else
    B := B and $FFFF00FF;
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

procedure TRenderBitmaps.CombineTo(aDst: TBitmap32; aClearPhysics: Boolean = false);
begin
  CombineTo(aDst, fPhysicsMap.BoundsRect, aClearPhysics);
end;

procedure TRenderBitmaps.CombineTo(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false);
var
  i: TRenderLayer;
begin
  aDst.BeginUpdate;
  aDst.Clear($FF000000);
  //aDst.SetSize(Width, Height); //not sure if we really want to do this

  // Tidy up the Only On Terrain and One Way Walls layers
  if fPhysicsMap <> nil then
  begin
    fPhysicsMap.DrawMode := dmCustom;
    // Delete Only-On-Terrain Objects not on terrain
    if not fIsEmpty[rlOnTerrainObjects] then
    begin
      fPhysicsMap.OnPixelCombine := CombinePhysicsMapOnlyOnTerrain;
      fPhysicsMap.DrawTo(Items[rlOnTerrainObjects], aRegion, aRegion);
    end;

    // Delete One-Way-Arrows not on non-steel terrain
    if not fIsEmpty[rlOneWayArrows] then
    begin
      fPhysicsMap.OnPixelCombine := CombinePhysicsMapOneWays;
      fPhysicsMap.DrawTo(Items[rlOneWayArrows], aRegion, aRegion);
    end;
  end;

  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    if (not aClearPhysics) and (i = rlTriggers) then
      Continue; // we only want to draw triggers when Clear Physics Mode is enabled

    if aClearPhysics and (i in [rlBackground, rlOnTerrainObjects, rlObjectsHigh]) then
      Continue; // we don't want to draw the first two in Clear Physics mode; while the latter has special handling

    if aClearPhysics and (i = rlTerrain) then
    begin // we want to draw based on physics map, not graphical map, in this case
      Items[rlObjectsHigh].DrawTo(aDst, aRegion, aRegion); // we want it behind terrain
      DrawClearPhysicsTerrain(aDst, aRegion);
      Continue;
    end;

    if not fIsEmpty[i] then
      Items[i].DrawTo(aDst, aRegion, aRegion);
  end;
  aDst.EndUpdate;
  aDst.Changed;
end;

procedure TRenderBitmaps.DrawClearPhysicsTerrain(aDst: TBitmap32; aRegion: TRect);
var
  x, y: Integer;
  PSrc,PDst: PColor32;
  C: TColor32;
begin
  // It's very messy to track position in a custom pixelcombine, hence using an entirely
  // custom procedure instead.
  for y := aRegion.Top to aRegion.Bottom-1 do
  begin
    PSrc := fPhysicsMap.PixelPtr[aRegion.Left, y];
    PDst := aDst.PixelPtr[aRegion.Left, y];
    Dec(PSrc); // so we can put Inc(P) at the start of the next loop rather than having to use lots of if statements
    Dec(PDst);
    for x := aRegion.Left to aRegion.Right-1 do
    begin
      Inc(PSrc);
      Inc(PDst);
      if PSrc^ and PM_SOLID = 0 then
        Continue
      else if PSrc^ and PM_STEEL = 0 then
        C := $FFB0B0B0
      else
        C := $FF606060;
      if (x mod 2) <> (y mod 2) then
        C := C - $00202020;
      PDst^ := C;
    end;
  end;
end;

end.
