{$include lem_directives.inc}

unit LemRendering;

interface

uses
  Classes, Math, Windows,
  GR32, GR32_Blend,
  UMisc, SysUtils, StrUtils,
  PngInterface,
  LemRecolorSprites,
  LemRenderHelpers, LemNeoPieceManager, LemNeoTheme,
  LemDosStructures,
  LemTypes,
  LemTerrain, LemMetaTerrain,
  LemObjects, LemInteractiveObject, LemMetaObject,
  LemSteel,
  LemLemming,
  LemDosAnimationSet, LemMetaAnimation, LemCore,
  LemLevel, LemStrings;

type
  TParticleRec = packed record
    DX, DY: ShortInt
  end;
  TParticleArray = packed array[0..79] of TParticleRec;
  TParticleTable = packed array[0..50] of TParticleArray;

  // temp solution
  TRenderInfoRec = record
    TargetBitmap : TBitmap32; // the visual bitmap
    Level        : TLevel;
  end;

  TRenderer = class
  private
    fObjectInfos: TInteractiveObjectInfoList;
    fDrawingHelpers: Boolean;
    fUsefulOnly: Boolean;

    fRenderInterface: TRenderInterface;

    fDisableBackground: Boolean;

    fRecolorer: TRecolorImage;

    fPhysicsMap: TBitmap32;
    fLayers: TRenderBitmaps;

    TempBitmap         : TBitmap32;
    Inf                : TRenderInfoRec;
    fTheme: TNeoTheme;
    fHelperImages: THelperImages;
    fAni: TBaseDosAnimationSet;
    fBgColor : TColor32;
    fParticles                 : TParticleTable; // all particle offsets
    fObjectInfoList: TInteractiveObjectInfoList; // For rendering from Preview screen
    fDoneBackgroundDraw: Boolean;

    // Add stuff
    procedure AddTerrainPixel(X, Y: Integer; Color: TColor32);
    procedure AddStoner(X, Y: Integer);
    // Remove stuff
    procedure ApplyRemovedTerrain(X, Y, W, H: Integer);

    // Graphical combines
    procedure CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);

    // Functional combines
    procedure PrepareTerrainFunctionBitmap(T: TTerrain; Dst: TBitmap32; Src: TMetaTerrain);
    procedure TerrainBitmapAutosteelMod(aBmp: TBitmap32; AutoSteel, SimpleSteel: Boolean);
    procedure CombineTerrainFunctionDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionErase(F: TColor32; var B: TColor32; M: TColor32);

    procedure PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
    procedure PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);

    procedure DrawTriggerAreaRectOnLayer(TriggerRect: TRect);

    function GetTerrainLayer: TBitmap32;
    function GetParticleLayer: TBitmap32;

    // Were sub-procedures, or part, of DrawAllObjects
    procedure DrawObjectsOnLayer(aLayer: TRenderLayer);
    procedure ProcessDrawFrame(aInf: TInteractiveObjectInfo; Dst: TBitmap32; TempBitmap: TBitmap32 = nil);
    procedure DrawTriggerArea(aInf: TInteractiveObjectInfo);
    procedure DrawUserHelper;
    function IsUseful(aInf: TInteractiveObjectInfo): Boolean;

  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetInterface(aInterface: TRenderInterface);

    procedure DrawLevel(aDst: TBitmap32; aClearPhysics: Boolean = false); overload;
    procedure DrawLevel(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false); overload;

    function FindMetaObject(O: TInteractiveObject): TMetaObjectInterface;
    function FindMetaTerrain(T: TTerrain): TMetaTerrain;

    procedure PrepareGameRendering(aLevel: TLevel; NoOutput: Boolean = false);

    // Terrain rendering
    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain);

    // Object rendering
    procedure DrawAllObjects(ObjectInfos: TInteractiveObjectInfoList; DrawHelper: Boolean = True; UsefulOnly: Boolean = false);
    procedure DrawObjectHelpers(Dst: TBitmap32; Obj: TInteractiveObjectInfo);
    procedure DrawLemmingHelpers(Dst: TBitmap32; L: TLemming);

    // Lemming rendering
    procedure DrawLemmings(UsefulOnly: Boolean = false);
    procedure DrawThisLemming(aLemming: TLemming; Selected: Boolean = false; UsefulOnly: Boolean = false);
    procedure DrawLemmingCountdown(aLemming: TLemming);
    procedure DrawLemmingParticles(L: TLemming);

    procedure DrawShadows(L: TLemming; SkillButton: TSkillPanelButton);
    procedure DrawGliderShadow(L: TLemming);
    procedure DrawBuilderShadow(L: TLemming);
    procedure DrawPlatformerShadow(L: TLemming);
    procedure DrawStackerShadow(L: TLemming);
    procedure DrawBasherShadow(L: TLemming);
    procedure DrawFencerShadow(L: TLemming);
    procedure DrawMinerShadow(L: TLemming);
    procedure DrawDiggerShadow(L: TLemming);
    procedure DrawExploderShadow(L: TLemming);
    procedure ClearShadows;
    procedure SetLowShadowPixel(X, Y: Integer);
    procedure SetHighShadowPixel(X, Y: Integer);


    procedure RenderWorld(World: TBitmap32; DoBackground: Boolean);
    procedure RenderPhysicsMap(Dst: TBitmap32 = nil);

    procedure CreateInteractiveObjectList(var ObjInfList: TInteractiveObjectInfoList);

    // Minimap
    procedure RenderMinimap(Dst: TBitmap32; LemmingsOnly: Boolean);
    procedure CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);

    property PhysicsMap: TBitmap32 read fPhysicsMap;
    property BackgroundColor: TColor32 read fBgColor write fBgColor;
    property Theme: TNeoTheme read fTheme;
    property LemmingAnimations: TBaseDosAnimationSet read fAni;

    property TerrainLayer: TBitmap32 read GetTerrainLayer; // for save state purposes
    property ParticleLayer: TBitmap32 read GetParticleLayer; // needs to be replaced with making TRenderer draw them
  end;

implementation

{ TRenderer }

procedure TRenderer.SetInterface(aInterface: TRenderInterface);
begin
  fRenderInterface := aInterface;
  fRenderInterface.SetDrawRoutineBrick(AddTerrainPixel);
  fRenderInterface.SetDrawRoutineStoner(AddStoner);
  fRenderInterface.SetRemoveRoutine(ApplyRemovedTerrain);
end;

// Minimap drawing

procedure TRenderer.RenderMinimap(Dst: TBitmap32; LemmingsOnly: Boolean);
var
  OldCombine: TPixelCombineEvent;
  OldMode: TDrawMode;

  i: Integer;
  L: TLemming;
begin
  if fRenderInterface.DisableDrawing then Exit;

  if not LemmingsOnly then
  begin
    Dst.Clear(fTheme.Colors[BACKGROUND_COLOR]);
    OldCombine := fPhysicsMap.OnPixelCombine;
    OldMode := fPhysicsMap.DrawMode;

    fPhysicsMap.DrawMode := dmCustom;
    fPhysicsMap.OnPixelCombine := CombineMinimapPixels;

    fPhysicsMap.DrawTo(Dst, Dst.BoundsRect, fPhysicsMap.BoundsRect);

    fPhysicsMap.OnPixelCombine := OldCombine;
    fPhysicsMap.DrawMode := OldMode;
  end;

  if fRenderInterface = nil then Exit;
  if fRenderInterface.LemmingList = nil then Exit;

  for i := 0 to fRenderInterface.LemmingList.Count-1 do
  begin
    L := fRenderInterface.LemmingList[i];
    if L.LemRemoved then Continue;
    if L.LemIsZombie then
      Dst.PixelS[L.LemX div 8, L.LemY div 8] := $FFFF0000
    else
      Dst.PixelS[L.LemX div 8, L.LemY div 8] := $FF00FF00;
  end;
end;

procedure TRenderer.CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and PM_SOLID) <> 0 then
    B := fTheme.Colors[MINIMAP_COLOR] or $FF000000;
end;

// Lemming Drawing

procedure TRenderer.DrawLemmings(UsefulOnly: Boolean = false);
var
  i: Integer;
  LemmingList: TLemmingList;
begin
  if not fLayers.fIsEmpty[rlParticles] then fLayers[rlParticles].Clear(0);
  fLayers[rlLemmings].Clear(0);

  LemmingList := fRenderInterface.LemmingList;

  // Draw all lemmings, except the one below the cursor
  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i] <> fRenderInterface.SelectedLemming then DrawThisLemming(LemmingList[i]);

  // Draw the lemming below the cursor
  if fRenderInterface.SelectedLemming <> nil then
    DrawThisLemming(fRenderInterface.SelectedLemming, true, UsefulOnly);

  // Draw particles for exploding lemmings
  fLayers.fIsEmpty[rlParticles] := True;
  for i := 0 to LemmingList.Count-1 do
  begin
    if LemmingList[i].LemParticleTimer > 0 then
    begin
      DrawLemmingParticles(LemmingList[i]);
      fLayers.fIsEmpty[rlParticles] := False;
    end;
    DrawLemmingCountdown(LemmingList[i]);
  end;
end;

procedure TRenderer.DrawThisLemming(aLemming: TLemming; Selected: Boolean = false; UsefulOnly: Boolean = false);
var
  SrcRect, DstRect: TRect;
  SrcAnim: TBitmap32;
  SrcMetaAnim: TMetaLemmingAnimation;
  TriggerRect: TRect;
  TriggerLeft, TriggerTop: Integer;
  i: Integer;

  function GetFrameBounds: TRect;
  begin
    with Result do
    begin
      Left := 0;
      Top := aLemming.LemFrame * SrcMetaAnim.Height;
      Right := SrcMetaAnim.Width;
      Bottom := Top + SrcMetaAnim.Height;
    end;
  end;

  function GetLocationBounds: TRect;
  begin
    with Result do
    begin
      Left := aLemming.LemX - SrcMetaAnim.FootX;
      Top := aLemming.LemY - SrcMetaAnim.FootY;
      Right := Left + SrcMetaAnim.Width;
      Bottom := Top + SrcMetaAnim.Height;
    end;
  end;

begin
  if aLemming.LemRemoved then Exit;
  if aLemming.LemTeleporting then Exit;

  fRecolorer.Lemming := aLemming;
  fRecolorer.DrawAsSelected := Selected;

  // Get the animation and meta-animation
  if aLemming.LemDX > 0 then
    i := AnimationIndices[aLemming.LemAction, false]
  else
    i := AnimationIndices[aLemming.LemAction, true];
  SrcAnim := fAni.LemmingAnimations[i];
  SrcMetaAnim := fAni.MetaLemmingAnimations[i];

  if aLemming.LemMaxFrame = -1 then
  begin
    aLemming.LemMaxFrame := SrcMetaAnim.FrameCount - 1;
    aLemming.LemFrameDiff := SrcMetaAnim.FrameDiff;
  end;

  while aLemming.LemFrame > aLemming.LemMaxFrame do
    Dec(aLemming.LemFrame, aLemming.LemFrameDiff);

  SrcRect := GetFrameBounds;
  DstRect := GetLocationBounds;
  SrcAnim.DrawMode := dmCustom;
  SrcAnim.OnPixelCombine := fRecolorer.CombineLemmingPixels;
  SrcAnim.DrawTo(fLayers[rlLemmings], DstRect, SrcRect);

  // Helper for selected blockers
  if UsefulOnly and Selected and (aLemming.LemAction = baBlocking) then
  begin
    DrawLemmingHelpers(fLayers[rlObjectHelpers], aLemming);
    fLayers.fIsEmpty[rlObjectHelpers] := false;
  end;

  // Draw blocker areas on the triggerLayer
  if (aLemming.LemAction = baBlocking) then
  begin
    TriggerLeft := aLemming.LemX - 6;
    if (aLemming.LemDX = 1) then Inc(TriggerLeft);
    TriggerTop := aLemming.LemY - 6;
    TriggerRect := Rect(TriggerLeft, TriggerTop, TriggerLeft + 4, TriggerTop + 11);
    DrawTriggerAreaRectOnLayer(TriggerRect);
    TriggerRect := Rect(TriggerLeft + 8, TriggerTop, TriggerLeft + 12, TriggerTop + 11);
    DrawTriggerAreaRectOnLayer(TriggerRect);
  end;

  // Draw lemming
  if Selected then
  begin
    fLayers[rlTriggers].PixelS[aLemming.LemX, aLemming.LemY] := $FFFFD700;
    fLayers[rlTriggers].PixelS[aLemming.LemX + 1, aLemming.LemY] := $FFFF4500;
    fLayers[rlTriggers].PixelS[aLemming.LemX - 1, aLemming.LemY] := $FFFF4500;
    fLayers[rlTriggers].PixelS[aLemming.LemX, aLemming.LemY + 1] := $FFFF4500;
    fLayers[rlTriggers].PixelS[aLemming.LemX, aLemming.LemY - 1] := $FFFF4500;
  end;
end;

procedure TRenderer.DrawLemmingCountdown(aLemming: TLemming);
var
  ShowCountdown, ShowHighlight: Boolean;
  SrcRect: TRect;
  n: Integer;
begin
  if aLemming.LemRemoved then Exit;

  ShowCountdown := (aLemming.LemExplosionTimer > 0) and not aLemming.LemHideCountdown;
  ShowHighlight := (aLemming = fRenderInterface.HighlitLemming);

  if ShowCountdown and ShowHighlight then
    ShowCountdown := (GetTickCount mod 1000 < 500);

  if ShowCountdown then
  begin
    n := (aLemming.LemExplosionTimer div 17) + 1;
    SrcRect := Rect(n * 4, 0, ((n+1) * 4), 5);
    if aLemming.LemDX < 0 then
      fAni.CountDownDigitsBitmap.DrawTo(fLayers[rlLemmings], aLemming.LemX - 2, aLemming.LemY - 17, SrcRect)    
    else
      fAni.CountDownDigitsBitmap.DrawTo(fLayers[rlLemmings], aLemming.LemX - 1, aLemming.LemY - 17, SrcRect);
  end else if ShowHighlight then
    fAni.HighlightBitmap.DrawTo(fLayers[rlLemmings], aLemming.LemX - 2, aLemming.LemY - 20);
end;

procedure TRenderer.DrawLemmingParticles(L: TLemming);
var
  i, X, Y: Integer;
begin

  for i := 0 to 79 do
  begin
    X := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DX;
    Y := fParticles[PARTICLE_FRAMECOUNT - L.LemParticleTimer][i].DY;
    if (X <> -128) and (Y <> -128) then
    begin
      X := L.LemX + X;
      Y := L.LemY + Y;
      fLayers[rlParticles].PixelS[X, Y] := PARTICLE_COLORS[i mod 8];
    end;
  end;

end;

function TRenderer.GetTerrainLayer: TBitmap32;
begin
  Result := fLayers[rlTerrain];
end;

function TRenderer.GetParticleLayer: TBitmap32;
begin
  Result := fLayers[rlParticles];
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32; aClearPhysics: Boolean = false);
begin
  DrawLevel(aDst, fPhysicsMap.BoundsRect, aClearPhysics);
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false);
begin
  fLayers.PhysicsMap := fPhysicsMap; // can we assign this just once somewhere? very likely.
  fLayers.CombineTo(aDst, aRegion, aClearPhysics);
end;

procedure TRenderer.ApplyRemovedTerrain(X, Y, W, H: Integer);
var
  PhysicsArrPtr, TerrLayerArrPtr: PColor32Array;
  cx, cy: Integer;
  MapWidth: Integer; // Width of the total PhysicsMap
begin
  // This has two applications:
  // - Removing all non-solid pixels from rlTerrain (possibly created by blending)
  // - Removed pixels from PhysicsMap copied to rlTerrain (called when applying a mask from LemGame via RenderInterface)

  PhysicsArrPtr := PhysicsMap.Bits;
  TerrLayerArrPtr := fLayers[rlTerrain].Bits;

  MapWidth := PhysicsMap.Width;

  for cy := Y to (Y+H-1) do
  begin
    if cy < 0 then Continue;
    if cy >= PhysicsMap.Height then Break;
    for cx := X to (X+W-1) do
    begin
      if cx < 0 then Continue;
      if cx >= MapWidth then Break;
      
      if PhysicsArrPtr[cy * MapWidth + cx] and PM_SOLID = 0 then
      begin
        // should we double-check all terrain bits are erased?
        TerrLayerArrPtr[cy * MapWidth + cx] := 0;
      end;
    end;
  end;
end;


procedure TRenderer.DrawShadows(L: TLemming; SkillButton: TSkillPanelButton);
var
  CopyL: TLemming;
begin
  // Copy L to simulate the path
  CopyL := TLemming.Create;
  CopyL.Assign(L);

  case SkillButton of
  spbBuilder:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baBuilding);
      DrawBuilderShadow(CopyL);
    end;

  spbPlatformer:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baPlatforming);
      DrawPlatformerShadow(CopyL);
    end;

  spbStacker:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baStacking);
      DrawStackerShadow(CopyL);
    end;

  spbDigger:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baDigging);
      DrawDiggerShadow(CopyL);
    end;

  spbMiner:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baMining);
      DrawMinerShadow(CopyL);
    end;

  spbBasher:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baBashing);
      DrawBasherShadow(CopyL);
    end;

  spbFencer:
    begin
      fRenderInterface.SimulateTransitionLem(CopyL, baFencing);
      DrawFencerShadow(CopyL);
    end;

  spbBomber:
    begin
      DrawExploderShadow(CopyL);
    end;

  spbGlider:
    begin
      CopyL.LemIsGlider := True;
      DrawGliderShadow(CopyL);
    end;

  spbCloner:
    begin
      CopyL.LemDX := -CopyL.LemDX;
      DrawShadows(CopyL, ActionToSkillPanelButton[CopyL.LemAction]);
    end;
  end;

  CopyL.Free;
end;

procedure TRenderer.DrawGliderShadow(L: TLemming);
var
  FrameCount: Integer; // counts number of frames we have simulated, because glider paths can be infinitely long
  MaxFrameCount: Integer;
  LemPosArray: TArrayArrayInt;
  i: Integer;
begin
  // Set ShadowLayer to be drawn
  fLayers.fIsEmpty[rlLowShadows] := False;
  // Initialize FrameCount
  FrameCount := 0;
  MaxFrameCount := 2000; // enough to fill the current screen, which should be sufficient
  // Initialize LemPosArray
  LemPosArray := nil;

  // Draw first pixel at lemming position
  SetLowShadowPixel(L.LemX, L.LemY - 1);

  // We simulate as long as the lemming is gliding, but allow for a falling period at the beginning
  while     (FrameCount < MaxFrameCount)
        and Assigned(L)
        and ((L.LemAction = baGliding) or ((FrameCount < 10) and (L.LemAction = baFalling))) do
  begin
    Inc(FrameCount);

    // Print shadow pixel of previous movement
    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
      begin
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);
        if (L.LemX = LemPosArray[0, i]) and (L.LemY = LemPosArray[1, i]) then Break;
      end;

    // Simulate next frame advance for lemming
    LemPosArray := fRenderInterface.SimulateLem(L);
  end;
end;

procedure TRenderer.DrawBuilderShadow(L: TLemming);
var
  i: Integer;
begin
  fLayers.fIsEmpty[rlLowShadows] := False;

  while Assigned(L) and (L.LemAction = baBuilding) do
  begin
    // draw shadow for placed brick
    if L.LemPhysicsFrame + 1 = 9 then  // why not just "if L.LemPhysicsFrame = 8"?
      for i := 0 to 5 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY - 1);

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;
end;

procedure TRenderer.DrawPlatformerShadow(L: TLemming);
var
  i: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlLowShadows] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  while Assigned(L) and (L.LemAction = baPlatforming) do
  begin
    // draw shadow for placed brick
    if L.LemPhysicsFrame + 1 = 9 then
      for i := 0 to 5 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY);

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawStackerShadow(L: TLemming);
var
  BrickPosY, i: Integer;
begin
  fLayers.fIsEmpty[rlLowShadows] := False;

  // Set correct Y-position for first brick
  BrickPosY := L.LemY - 9 + L.LemNumberOfBricksLeft;
  if L.LemStackLow then Inc(BrickPosY);

  while Assigned(L) and (L.LemAction = baStacking) do
  begin
    // draw shadow for placed brick
    if L.LemPhysicsFrame + 1 = 7 then
    begin
      for i := 1 to 3 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, BrickPosY);

      Dec(BrickPosY); // for the next brick
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;
end;

procedure TRenderer.DrawBasherShadow(L: TLemming);
const
  BasherEnd: array[0..10, 0..1] of Integer = (
     (6, -1), (6, -2), (7, -2), (7, -3), (7, -4),
     (7, -5), (7, -6), (7, -7), (6, -7), (6, -8),
     (5, -8)
   );
var
  i: Integer;
  BashPosX, BashPosY, BashPosDx: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlHighShadows] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  BashPosDx := L.LemDx;
  BashPosX := L.LemX;
  BashPosY := L.LemY;

  while Assigned(L) and (L.LemAction = baBashing) do
  begin
    // draw shadow for basher tunnel
    if (L.LemPhysicsFrame + 1) mod 16 = 2 then
    begin
      BashPosX := L.LemX;
      BashPosY := L.LemY;
      BashPosDx := L.LemDx;

      for i := 0 to 5 do
      begin
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 1);
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 9);
      end;
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(BasherEnd) - 1 do
    SetHighShadowPixel(BashPosX + BasherEnd[i, 0] * BashPosDx, BashPosY + BasherEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawFencerShadow(L: TLemming);
// Like with the Fencer code itself, this is an almost exact copy of the Basher shadow code,
// and probably needs some work.
const
  FencerEnd: array[0..5, 0..1] of Integer = (
     (6, -4), (6, -5), (6, -6), (6, -7), (6, -8),
     (6, -9)
   );
var
  i: Integer;
  FencePosX, FencePosY, FencePosDx: Integer;
  DrawDY: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlHighShadows] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  FencePosDx := L.LemDx;
  FencePosX := L.LemX;
  FencePosY := L.LemY;

  while Assigned(L) and (L.LemAction = baFencing) do
  begin
    // draw shadow for fencer tunnel
    if (L.LemPhysicsFrame + 1) mod 16 = 2 then
    begin
      FencePosX := L.LemX;
      FencePosY := L.LemY;
      FencePosDx := L.LemDx;

      DrawDY := 0;
      for i := 0 to 5 do
      begin
        if i > 0 then
          SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 2 - DrawDy); // slightly more consistent graphics with this If here
        if i in [2, 4] then
          Inc(DrawDY); // putting it between the SetHighShadowPixel's is not a mistake; it reflects the mask 100% accurately ;)
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 8 - DrawDy);
      end;
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(FencerEnd) - 1 do
    SetHighShadowPixel(FencePosX + FencerEnd[i, 0] * FencePosDx, FencePosY + FencerEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawMinerShadow(L: TLemming);
const
  MinerTurn: array[0..11, 0..1] of Integer = (
     (1, -1), (1, 0), (2, 0), (3, 0), (3, 1), (4, 1),             // bottom border
     (3, -12), (4, -12), (5, -12), (5, -11), (6, -11), (6, -10)   // top border
   );

  MinerEnd: array[0..15, 0..1] of Integer = (
     (5, 1), (6, 1), (6, 0), (7, 0), (7, -1),
     (8, -1), (8, -2), (8, -3), (8, -4), (8, -5),
     (8, -6), (8, -7), (7, -7), (7, -8), (7, -9),
     (7, -10)
   );
var
  i: Integer;
  MinePosX, MinePosY, MinePosDx: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlHighShadows] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  MinePosDx := L.LemDx;
  MinePosX := L.LemX;
  MinePosY := L.LemY;

  while Assigned(L) and (L.LemAction = baMining) do
  begin
    // draw shadow for miner tunnel
    if L.LemPhysicsFrame + 1 = 1 then
    begin
      MinePosX := L.LemX;
      MinePosY := L.LemY;
      MinePosDx := L.LemDx;

      for i := 0 to Length(MinerTurn) - 1 do
        SetHighShadowPixel(MinePosX + MinerTurn[i, 0] * MinePosDx, MinePosY + MinerTurn[i, 1]);
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  // Draw end of the tunnel
  for i := 0 to Length(MinerEnd) - 1 do
    SetHighShadowPixel(MinePosX + MinerEnd[i, 0] * MinePosDx, MinePosY + MinerEnd[i, 1]);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawDiggerShadow(L: TLemming);
var
  i: Integer;
  DigPosX, DigPosY: Integer;
  SavePhysicsMap: TBitmap32;
begin
  fLayers.fIsEmpty[rlHighShadows] := False;

  // Make a deep copy of the PhysicsMap
  SavePhysicsMap := TBitmap32.Create;
  SavePhysicsMap.Assign(PhysicsMap);

  DigPosX := L.LemX;
  DigPosY := L.LemY;

  while Assigned(L) and (L.LemAction = baDigging) do
  begin
    // draw shadow for dug row
    if (L.LemPhysicsFrame + 1) mod 8 = 0 then
    begin
      SetHighShadowPixel(DigPosX - 4, DigPosY - 1);
      SetHighShadowPixel(DigPosX + 4, DigPosY - 1);

      Inc(DigPosY);
    end;

    // Simulate next frame advance for lemming
    fRenderInterface.SimulateLem(L);
  end;

  // Draw bottom line of digger tunnel
  SetHighShadowPixel(DigPosX - 4, DigPosY - 1);
  SetHighShadowPixel(DigPosX + 4, DigPosY - 1);
  for i := -4 to 4 do
    SetHighShadowPixel(DigPosX + i, DigPosY);

  PhysicsMap.Assign(SavePhysicsMap);
  SavePhysicsMap.Free;
end;

procedure TRenderer.DrawExploderShadow(L: TLemming);
const
  // This encodes only the right half of the bomber mask. The rest is obtained by mirroring it
  BomberShadow: array[0..35, 0..1] of Integer = (
     (0, 7), (1, 7), (2, 7), (2, 6), (3, 6),
     (4, 6), (4, 5), (5, 5), (5, 4), (6, 4),
     (6, 3), (6, 2), (6, 1), (7, 1), (7, 0),
     (7, -1), (7, -2), (7, -3), (7, -4), (6, -4),
     (6, -5), (6, -6), (6, -7), (6, -8), (5, -8),
     (5, -9), (5, -10), (5, -10), (4, -11), (4, -12),
     (3, -12), (3, -13), (2, -13), (2, -14), (1, -14),
     (0, -14)
   );
var
  PosX, i: Integer;
begin
  fLayers.fIsEmpty[rlHighShadows] := False;

  PosX := L.LemX;
  if L.LemDx = 1 then Inc(PosX);

  for i := 0 to Length(BomberShadow) - 1 do
  begin
    SetHighShadowPixel(PosX + BomberShadow[i, 0], L.LemY + BomberShadow[i, 1]);
    SetHighShadowPixel(PosX - BomberShadow[i, 0] - 1, L.LemY + BomberShadow[i, 1]);
  end;
end;



procedure TRenderer.ClearShadows;
begin
  if not fLayers.fIsEmpty[rlLowShadows] then
  begin
    fLayers[rlLowShadows].Clear(0);
    fLayers.fIsEmpty[rlLowShadows] := True;
  end;
  if not fLayers.fIsEmpty[rLHighShadows] then
  begin
    fLayers[rLHighShadows].Clear(0);
    fLayers.fIsEmpty[rLHighShadows] := True;
  end;
end;

procedure TRenderer.SetLowShadowPixel(X, Y: Integer);
begin
  if (X >= 0) and (X < fPhysicsMap.Width) and (Y >= 0) and (Y < fPhysicsMap.Height) then
    fLayers[rlLowShadows].Pixel[X, Y] := SHADOW_COLOR;
end;

procedure TRenderer.SetHighShadowPixel(X, Y: Integer);
begin
  if (X >= 0) and (X < fPhysicsMap.Width) and (Y >= 0) and (Y < fPhysicsMap.Height) then
    fLayers[rlHighShadows].Pixel[X, Y] := SHADOW_COLOR;
end;

procedure TRenderer.AddTerrainPixel(X, Y: Integer; Color: TColor32);
var
  P: PColor32;
  C: TColor32;
begin
  if not PtInRect(fLayers[rlTerrain].BoundsRect, Point(X, Y)) then Exit;
  
  P := fLayers[rlTerrain].PixelPtr[X, Y];
  if P^ and $FF000000 <> $FF000000 then
  begin
    C := Color; //Theme.Colors[MASK_COLOR];
    BlendMem(P^, C);
    P^ := C;
  end;
end;

procedure TRenderer.AddStoner(X, Y: Integer);
begin
  fAni.LemmingAnimations[STONED].DrawMode := dmCustom;
  fAni.LemmingAnimations[STONED].OnPixelCombine := CombineTerrainNoOverwrite;
  fAni.LemmingAnimations[STONED].DrawTo(fLayers[rlTerrain], X, Y);
end;

function TRenderer.FindMetaObject(O: TInteractiveObject): TMetaObjectInterface;
var
  FindLabel: String;
  MO: TMetaObject;
  df: Integer;
begin
  FindLabel := O.GS + ':' + O.Piece;
  MO := PieceManager.Objects[FindLabel];
  df := O.DrawingFlags;
  Result := MO.GetInterface(df and odf_Flip <> 0, df and odf_UpsideDown <> 0, df and odf_Rotate <> 0);
end;

function TRenderer.FindMetaTerrain(T: TTerrain): TMetaTerrain;
var
  FindLabel: String;
begin
  FindLabel := T.GS + ':' + T.Piece;
  Result := PieceManager.Terrains[FindLabel];
end;

// Functional combines

procedure TRenderer.TerrainBitmapAutosteelMod(aBmp: TBitmap32; AutoSteel, SimpleSteel: Boolean);
var
  x, y: Integer;
begin
  if AutoSteel and not SimpleSteel then Exit; //no modifications needed
  if not AutoSteel then
  begin
    for y := 0 to aBmp.Height-1 do
      for x := 0 to aBmp.Width-1 do
        if aBmp.Pixel[x, y] and PM_STEEL <> 0 then
          aBmp.Pixel[x, y] := aBmp.Pixel[x, y] and not PM_STEEL;
  end else begin
    for y := 0 to aBmp.Height-1 do
      for x := 0 to aBmp.Width-1 do
        if aBmp.Pixel[x, y] and PM_SOLID <> 0 then
          aBmp.Pixel[x, y] := aBmp.Pixel[x, y] or PM_NOCANCELSTEEL;
  end;
end;

procedure TRenderer.PrepareTerrainFunctionBitmap(T: TTerrain; Dst: TBitmap32; Src: TMetaTerrain);
var
  x, y: Integer;
  PDst: PColor32;
  Flip, Invert, Rotate: Boolean;
begin
  Rotate := T.DrawingFlags and tdf_Rotate <> 0;
  Invert := T.DrawingFlags and tdf_Invert <> 0;
  Flip := T.DrawingFlags and tdf_Flip <> 0;

  Dst.Assign(Src.PhysicsImage[Flip, Invert, Rotate]);

  for y := 0 to Dst.Height-1 do
  for x := 0 to Dst.Width-1 do
  begin
    PDst := Dst.PixelPtr[x, y];
    // Set One-way-arrow flag
    if (not Src.IsSteel) and (T.DrawingFlags and tdf_NoOneWay = 0) then
      PDst^ := PDst^ or PM_ONEWAY;
    // Remove non-sold pixels
    if (PDst^ and PM_SOLID) = 0 then
      PDst^ := 0;
  end;

  Dst.DrawMode := dmCustom;
  if T.DrawingFlags and tdf_NoOverwrite <> 0 then
    Dst.OnPixelCombine := CombineTerrainFunctionNoOverwrite
  else if T.DrawingFlags and tdf_Erase <> 0 then
    Dst.OnPixelCombine := CombineTerrainFunctionErase
  else
    Dst.OnPixelCombine := CombineTerrainFunctionDefault;
end;

procedure TRenderer.CombineTerrainFunctionDefault(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
    if F and PM_NOCANCELSTEEL = 0 then
      B := F
    else
      B := (B and PM_STEEL) or F;
end;

procedure TRenderer.CombineTerrainFunctionNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
    if B and PM_NOCANCELSTEEL = 0 then
    begin
      if (B and PM_SOLID = 0) then
        B := F;
    end else begin
      B := B or (F and PM_STEEL);
    end;
end;

procedure TRenderer.CombineTerrainFunctionErase(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
    B := 0;
end;

// Graphical combines

procedure TRenderer.CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    BlendMem(F, B);
  end;
end;

procedure TRenderer.CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and $FF000000 <> $FF000000) then
  begin
    BlendMem(B, F);
    B := F;
  end;
end;

procedure TRenderer.CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
    B := 0;
end;

procedure TRenderer.CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    BlendMem(F, B);
  end;
end;

procedure TRenderer.CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
    BlendMem(F, B);
  end;
end;


procedure TRenderer.PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);
begin
  Bmp.DrawMode := dmCustom;

  if DrawingFlags and odf_OnlyOnTerrain <> 0 then
    Bmp.OnPixelCombine := CombineObjectDefault
  else if Zombie then
    Bmp.OnPixelCombine := CombineObjectDefaultZombie
  else
    Bmp.OnPixelCombine := CombineObjectDefault;
end;

procedure TRenderer.DrawTerrain(Dst: TBitmap32; T: TTerrain);
var
  Src: TBitmap32;
  Flip, Invert, Rotate: Boolean;
  MT: TMetaTerrain;
begin

  MT := FindMetaTerrain(T);
  Rotate := (T.DrawingFlags and tdf_Rotate <> 0);
  Invert := (T.DrawingFlags and tdf_Invert <> 0);
  Flip := (T.DrawingFlags and tdf_Flip <> 0);

  Src := MT.GraphicImage[Flip, Invert, Rotate];
  PrepareTerrainBitmap(Src, T.DrawingFlags);
  Src.DrawTo(Dst, T.Left, T.Top);
end;

procedure TRenderer.PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
begin
  Bmp.DrawMode := dmCustom;

  if DrawingFlags and tdf_NoOverwrite <> 0 then
    Bmp.OnPixelCombine := CombineTerrainNoOverwrite
  else if DrawingFlags and tdf_Erase <> 0 then
    Bmp.OnPixelCombine := CombineTerrainErase
  else
    Bmp.OnPixelCombine := CombineTerrainDefault;
end;


procedure TRenderer.DrawObjectHelpers(Dst: TBitmap32; Obj: TInteractiveObjectInfo);
var
  O: TInteractiveObject;
  MO: TMetaObjectInterface;

  DrawX, DrawY: Integer;
begin
  Assert(Dst = fLayers[rlObjectHelpers], 'Object Helpers not written on their layer');

  O := Obj.Obj;
  MO := Obj.MetaObj;

  // We don't question here whether the conditions are met to draw the helper or
  // not. We assume the calling routine has already done this, and we just draw it.
  // We do, however, determine which ones to draw here.

  DrawX := (Obj.TriggerRect.Left + Obj.TriggerRect.Right) div 2; // Obj.Left + Obj.Width div 2 - 4;
  DrawY := Obj.Top - 9; // much simpler
  if DrawY < 0 then DrawY := Obj.Top + Obj.Height + 1; // Draw below instead above the level border

  case MO.TriggerEffect of
    DOM_WINDOW:
      begin
        if (O.TarLev and $68) <> 0 then DrawX := DrawX - 4;

        if (O.DrawingFlags and odf_FlipLem) = 0 then
          fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX - 4, DrawY)
        else
          fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX - 4, DrawY);

        if (O.TarLev and $68) <> 0 then
          fHelperImages[hpi_Exclamation].DrawTo(Dst, DrawX + 8, DrawY);
      end;

    DOM_TELEPORT:
      begin
        fHelperImages[THelperIcon(Obj.PairingID + 1)].DrawTo(Dst, DrawX - 8, DrawY);
        fHelperImages[hpi_ArrowUp].DrawTo(Dst, DrawX, DrawY - 1);
      end;

    DOM_RECEIVER:
      begin
        fHelperImages[THelperIcon(Obj.PairingID + 1)].DrawTo(Dst, DrawX - 8, DrawY);
        fHelperImages[hpi_ArrowDown].DrawTo(Dst, DrawX, DrawY);
      end;

    DOM_EXIT, DOM_LOCKEXIT:
      begin
        fHelperImages[hpi_Exit].DrawTo(Dst, DrawX - 13, DrawY);
      end;

    DOM_FIRE:
      begin
        fHelperImages[hpi_Fire].DrawTo(Dst, DrawX - 13, DrawY);
      end;

    DOM_TRAP:
      begin
        if not Obj.IsDisabled then
        begin
          fHelperImages[hpi_Num_Inf].DrawTo(Dst, DrawX - 17, DrawY);
          fHelperImages[hpi_Trap].DrawTo(Dst, DrawX - 10, DrawY);
        end;
      end;

    DOM_TRAPONCE:
      begin
        if not Obj.IsDisabled then
        begin
          fHelperImages[hpi_Num_1].DrawTo(Dst, DrawX - 17, DrawY);
          fHelperImages[hpi_Trap].DrawTo(Dst, DrawX - 10, DrawY);
        end;
      end;

    DOM_RADIATION:
      begin
        fHelperImages[hpi_Radiation].DrawTo(Dst, DrawX - 4, DrawY);
      end;

    DOM_SLOWFREEZE:
      begin
        fHelperImages[hpi_Slowfreeze].DrawTo(Dst, DrawX - 4, DrawY);
      end;

    DOM_FLIPPER:
      begin
        fHelperImages[hpi_Flipper].DrawTo(Dst, DrawX - 13, DrawY);
      end;

    DOM_BUTTON:
      begin
        fHelperImages[hpi_Button].DrawTo(Dst, DrawX - 19, DrawY);
      end;

    DOM_FORCELEFT:
      begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19, DrawY);
        fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX + 13, DrawY);
      end;

    DOM_FORCERIGHT:
      begin
        fHelperImages[hpi_Force].DrawTo(Dst, DrawX - 19, DrawY);
        fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX + 12, DrawY);
      end;

    DOM_SPLAT:
      begin
        fHelperImages[hpi_Splat].DrawTo(Dst, DrawX - 16, DrawY);
      end;

    DOM_NOSPLAT:
      begin
        fHelperImages[hpi_NoSplat].DrawTo(Dst, DrawX - 16, DrawY);
      end;

    DOM_WATER:
      begin
        fHelperImages[hpi_Water].DrawTo(Dst, DrawX - 16, DrawY);
      end;
  end;
end;

procedure TRenderer.DrawLemmingHelpers(Dst: TBitmap32; L: TLemming);
var
  DrawX, DrawY: Integer;
begin
  Assert(Dst = fLayers[rlObjectHelpers], 'Object Helpers not written on their layer');

  DrawX := L.LemX;
  DrawY := L.LemY - 10 - 9; // much simpler

  Assert(L.LemAction = baBlocking, 'Lemming helper called for non-blocker');

  if (L.LemDX = 1) then fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX - 4, DrawY)
  else fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX - 4, DrawY);
end;

procedure TRenderer.ProcessDrawFrame(aInf: TInteractiveObjectInfo; Dst: TBitmap32; TempBitmap: TBitmap32 = nil);
var
  CountX, CountY, iX, iY: Integer;
  MO: TMetaObjectInterface;
  DrawFrame: Integer;
  TempBitmapRect, DstRect: TRect;
  IsOwnBitmap: Boolean;
begin
  if aInf.IsInvisible then Exit;
  if aInf.TriggerEffect in [DOM_LEMMING, DOM_HINT, DOM_BGIMAGE] then Exit;

  if TempBitmap = nil then
  begin
    TempBitmap := TBitmap32.Create;
    IsOwnBitmap := true;
  end else
    IsOwnBitmap := false;

  try


    DrawFrame := Min(aInf.CurrentFrame, aInf.AnimationFrameCount-1);
    TempBitmap.Assign(aInf.Frames[DrawFrame]);

    PrepareObjectBitmap(TempBitmap, aInf.Obj.DrawingFlags, aInf.ZombieMode);

    MO := aInf.MetaObj;
    CountX := (aInf.Width-1) div MO.Width;
    CountY := (aInf.Height-1) div MO.Height;

    for iY := 0 to CountY do
    begin
      // (re)size rectangles correctly
      TempBitmapRect := TempBitmap.BoundsRect;
      // Move to leftmost X-coordinate and correct Y-coordinate
      DstRect := Rect(0, 0, RectWidth(TempBitmapRect), RectHeight(TempBitmapRect));
      OffsetRect(DstRect, aInf.Left, aInf.Top + (MO.Height * iY));
      // shrink sizes of rectange to draw on bottom row
      if (iY = CountY) and (aInf.Height mod MO.Height <> 0) then
      begin
        Dec(DstRect.Bottom, MO.Height - (aInf.Height mod MO.Height));
        Dec(TempBitmapRect.Bottom, MO.Height - (aInf.Height mod MO.Height));
      end;

      for iX := 0 to CountX do
      begin
        // shrink size of rectangle to draw on rightmost column
        if (iX = CountX) and (aInf.Width mod MO.Width <> 0) then
        begin
          Dec(DstRect.Right, MO.Width - (aInf.Width mod MO.Width));
          Dec(TempBitmapRect.Right, MO.Width - (aInf.Width mod MO.Width));
        end;
        // Draw copy of object onto alayer at this place
        TempBitmap.DrawTo(Dst, DstRect, TempBitmapRect);
        // Move to next row
        OffsetRect(DstRect, MO.Width, 0);
      end;
    end;

    aInf.Obj.LastDrawX := aInf.Left;  // is this still needed?
    aInf.Obj.LastDrawY := aInf.Top;
  finally
    if IsOwnBitmap then
      TempBitmap.Free;
  end;
end;

procedure TRenderer.DrawTriggerArea(aInf: TInteractiveObjectInfo);
const
  DO_NOT_DRAW: set of 0..255 =
        [DOM_NONE, DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_STEEL, DOM_BLOCKER,
         DOM_LEMMING, DOM_ONEWAYDOWN, DOM_WINDOW, DOM_HINT, DOM_BACKGROUND, DOM_BGIMAGE, DOM_ONEWAYUP];
begin
  if not (aInf.Obj.IsFake or aInf.IsDisabled or (aInf.TriggerEffect in DO_NOT_DRAW)) then
    DrawTriggerAreaRectOnLayer(aInf.TriggerRect);
end;

procedure TRenderer.DrawUserHelper;
var
  BMP: TBitmap32;
  DrawPoint: TPoint;
begin
  BMP := fHelperImages[fRenderInterface.UserHelper];
  DrawPoint := fRenderInterface.MousePos;
  DrawPoint.X := DrawPoint.X - (BMP.Width div 2);
  DrawPoint.Y := DrawPoint.Y - (BMP.Height div 2);
  BMP.DrawTo(fLayers[rlObjectHelpers], DrawPoint.X, DrawPoint.Y);
  fLayers.fIsEmpty[rlObjectHelpers] := false;
end;

function TRenderer.IsUseful(aInf: TInteractiveObjectInfo): Boolean;
begin
  Result := true;
  if not fUsefulOnly then Exit;

  if aInf.Obj.IsFake
  or aInf.IsDisabled
  or (aInf.TriggerEffect in [DOM_NONE, DOM_ANIMATION, DOM_HINT, DOM_BACKGROUND]) then
    Result := false;
end;

procedure TRenderer.DrawObjectsOnLayer(aLayer: TRenderLayer);
var
  Dst: TBitmap32;

  function IsValidForLayer(aInf: TInteractiveObjectInfo): Boolean;
  begin
    if aInf.TriggerEffect = DOM_BACKGROUND then
      Result := aLayer = rlBackgroundObjects
    else if aInf.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN, DOM_ONEWAYUP] then
      Result := aLayer = rlOneWayArrows
    else case aLayer of
           rlObjectsLow: Result := aInf.IsNoOverwrite and not aInf.IsOnlyOnTerrain;
           rlOnTerrainObjects: Result := aInf.IsOnlyOnTerrain and not aInf.IsNoOverwrite;
           rlObjectsHigh: Result := not (aInf.IsNoOverwrite xor aInf.IsOnlyOnTerrain);
           else Result := false;
         end;
  end;

  procedure HandleObject(aIndex: Integer);
  var
    Inf: TInteractiveObjectInfo;
  begin
    Inf := fObjectInfos[aIndex];
    if not (IsValidForLayer(Inf) and IsUseful(Inf)) then Exit;

    if (aLayer = rlBackgroundObjects) and (Inf.CanDrawToBackground) then
      ProcessDrawFrame(Inf, fLayers[rlBackground])
    else begin
      ProcessDrawFrame(Inf, Dst);
      fLayers.fIsEmpty[aLayer] := false;
      //DrawTriggerArea(Inf); // commented out due to potential conflicts
    end;
  end;
var
  i: Integer;
begin
  fLayers[aLayer].Lock;
  fLayers[aLayer].BeginUpdate;
  Dst := fLayers[aLayer];
  try
    //Dst.Assign(fLayers[aLayer]);
    if not fLayers.fIsEmpty[aLayer] then Dst.Clear(0);
    // Special conditions
    if (aLayer = rlBackgroundObjects) and (fUsefulOnly or fDisableBackground) then Exit;
    if (aLayer = rlObjectsLow) then
      for i := fObjectInfos.Count-1 downto 0 do
        HandleObject(i)
    else
      for i := 0 to fObjectInfos.Count-1 do
        HandleObject(i);

    //fLayers[aLayer].Assign(Dst);
  finally
    fLayers[aLayer].EndUpdate;
    fLayers[aLayer].Unlock;
    //Dst.Free;
  end;
end;

procedure TRenderer.DrawAllObjects(ObjectInfos: TInteractiveObjectInfoList; DrawHelper: Boolean = True; UsefulOnly: Boolean = false);
var
  Inf: TInteractiveObjectInfo;
  i, i2: Integer;
begin
  fObjectInfos := ObjectInfos;
  fDrawingHelpers := DrawHelper;
  fUsefulOnly := UsefulOnly;

  if not fLayers.fIsEmpty[rlTriggers] then fLayers[rlTriggers].Clear(0);

  DrawObjectsOnLayer(rlBackgroundObjects);
  DrawObjectsOnLayer(rlObjectsLow);
  DrawObjectsOnLayer(rlOnTerrainObjects);
  DrawObjectsOnLayer(rlOneWayArrows);
  DrawObjectsOnLayer(rlObjectsHigh);

  if fRenderInterface = nil then Exit; // otherwise, some of the remaining code may cause an exception on first rendering

  // Draw object helpers
  if not fLayers.fIsEmpty[rlObjectHelpers] then fLayers[rlObjectHelpers].Clear(0);
  if DrawHelper and UsefulOnly then
  begin
    for i := 0 to ObjectInfos.Count-1 do
    begin
      Inf := ObjectInfos[i];

      // Check if this object is relevant
      if Inf.IsDisabled then Continue;

      // Magic numbers are needed due to some offset of MousePos wrt. the center of the cursor.
      if not PtInRect(Rect(Inf.Left - 4, Inf.Top + 1, Inf.Left + Inf.Width - 2, Inf.Top + Inf.Height + 3),
                      fRenderInterface.MousePos) then
        Continue;

      // otherwise, draw its helper
      DrawObjectHelpers(fLayers[rlObjectHelpers], Inf);
      fLayers.fIsEmpty[rlObjectHelpers] := false;

      // if it's a teleporter or receiver, draw all paired helpers too
      if (Inf.TriggerEffect in [DOM_TELEPORT, DOM_RECEIVER]) and (Inf.PairingId <> -1) then
        for i2 := 0 to ObjectInfos.Count-1 do
        begin
          if i = i2 then Continue;
          if (ObjectInfos[i2].PairingId = Inf.PairingId) then
            DrawObjectHelpers(fLayers[rlObjectHelpers], ObjectInfos[i2]);
        end;
    end;
  end;

  if fRenderInterface.UserHelper <> hpi_None then
      DrawUserHelper;

end;

procedure TRenderer.DrawTriggerAreaRectOnLayer(TriggerRect: TRect);
var
  x, y: Integer;
  PPhys, PDst: PColor32;
  DrawRect: TRect;

  procedure DrawTriggerPixel();
  begin
    if PPhys^ and PM_SOLID = 0 then
      PDst^ := $FFFF00FF
    else if PPhys^ and PM_STEEL <> 0 then
      PDst^ := $FF400040
    else
      PDst^ := $FFA000A0;

    if (x - y) mod 2 <> 0 then
      PDst^ := PDst^ - $00200020;
  end;

begin
  if    (TriggerRect.Right <= 0) or (TriggerRect.Left > fPhysicsMap.Width)
     or (TriggerRect.Bottom <= 0) or (TriggerRect.Top > fPhysicsMap.Height) Then
    Exit;

  DrawRect := Rect(Max(TriggerRect.Left, 0), Max(TriggerRect.Top, 0),
                   Min(TriggerRect.Right, fPhysicsMap.Width), Min(TriggerRect.Bottom, fPhysicsMap.Height));

  for y := DrawRect.Top to DrawRect.Bottom - 1 do
  begin
    PDst := fLayers[rlTriggers].PixelPtr[DrawRect.Left, y];
    PPhys := fPhysicsMap.PixelPtr[DrawRect.Left, y];

    for x := DrawRect.Left to DrawRect.Right - 1 do
    begin
      DrawTriggerPixel();

      Inc(PDst);
      Inc(PPhys);
    end;
  end;

  fLayers.fIsEmpty[rlTriggers] := false;
end;


constructor TRenderer.Create;
var
  i: THelperIcon;
  S: TMemoryStream;
begin
  inherited Create;

  TempBitmap := TBitmap32.Create;
  fTheme := TNeoTheme.Create;
  fLayers := TRenderBitmaps.Create;
  fPhysicsMap := TBitmap32.Create;
  fBgColor := $00000000;
  fAni := TBaseDosAnimationSet.Create;
  fRecolorer := TRecolorImage.Create;
  fObjectInfoList := TInteractiveObjectInfoList.Create;
  for i := Low(THelperIcon) to High(THelperIcon) do
  begin
    if i = hpi_None then Continue;
    fHelperImages[i] := TBitmap32.Create;
    TPngInterface.LoadPngFile(AppPath + SFGraphicsHelpers + HelperImageFilenames[i], fHelperImages[i]);
    fHelperImages[i].DrawMode := dmBlend;
  end;

  FillChar(fParticles, SizeOf(TParticleTable), $80);
  S := TMemoryStream.Create;
  try
    S.LoadFromFile(AppPath + SFData + 'particles.dat');
    S.Seek(0, soFromBeginning);
    S.Read(fParticles, S.Size);
  finally
    S.Free;
  end;
end;

destructor TRenderer.Destroy;
var
  i: Integer;
  iIcon: THelperIcon;
begin
  TempBitmap.Free;
  fTheme.Free;
  fLayers.Free;
  fPhysicsMap.Free;
  fRecolorer.Free;
  fAni.Free;
  fObjectInfoList.Free;
  for iIcon := Low(THelperIcon) to High(THelperIcon) do
    fHelperImages[iIcon].Free;

  inherited Destroy;
end;

procedure TRenderer.RenderPhysicsMap(Dst: TBitmap32 = nil);
var
  i: Integer;
  T: TTerrain;
  MT: TMetaTerrain;
  O: TInteractiveObjectInfo;
  S: TSteel;
  Bmp: TBitmap32;

  procedure SetRegion(aRegion: TRect; C, AntiC: TColor32);
  var
    X, Y: Integer;
    P: PColor32;
  begin
    for y := aRegion.Top to aRegion.Bottom-1 do
    begin
      if (y < 0) or (y >= Dst.Height) then Continue;
      for x := aRegion.Left to aRegion.Right-1 do
      begin
        if (x < 0) or (x >= Dst.Width) then Continue;
        P := Dst.PixelPtr[x, y];
        P^ := (P^ or C) and (not AntiC);
      end;
    end;
  end;

  procedure ApplyOWW(Inf: TInteractiveObjectInfo);
  var
    C: TColor32;

    TW, TH: Integer;

    procedure HandleRotate;
    var
      Temp: Integer;
    begin
      Temp := TW;
      TW := TH;
      TH := Temp;

      case C of
        PM_ONEWAYLEFT: C := PM_ONEWAYUP;
        PM_ONEWAYUP: C := PM_ONEWAYRIGHT;
        PM_ONEWAYRIGHT: C := PM_ONEWAYDOWN;
        PM_ONEWAYDOWN: C := PM_ONEWAYLEFT;
      end;
    end;

    procedure HandleFlip;
    begin
      case C of
        PM_ONEWAYLEFT: C := PM_ONEWAYRIGHT;
        PM_ONEWAYRIGHT: C := PM_ONEWAYLEFT;
      end;
    end;

    procedure HandleInvert;
    begin
      case C of
        PM_ONEWAYUP: C := PM_ONEWAYDOWN;
        PM_ONEWAYDOWN: C := PM_ONEWAYUP;
      end;
    end;
  begin
    case Inf.TriggerEffect of
      DOM_ONEWAYLEFT: C := PM_ONEWAYLEFT;
      DOM_ONEWAYRIGHT: C := PM_ONEWAYRIGHT;
      DOM_ONEWAYDOWN: C := PM_ONEWAYDOWN;
      DOM_ONEWAYUP: C := PM_ONEWAYUP;
      else Exit;
    end;

    SetRegion( Inf.TriggerRect, C, 0);
  end;

  procedure ApplyArea(S: TSteel);
  var
    C, AntiC: TColor32;
  begin
    C := 0;
    AntiC := 0;
    case S.fType of
      0: C := PM_STEEL;
      1: AntiC := PM_STEEL;
      2: C := PM_ONEWAYLEFT;
      3: C := PM_ONEWAYRIGHT;
      4: C := PM_ONEWAYDOWN;
      else Exit;
    end;

    SetRegion( Rect(S.Left, S.Top, S.Left + S.Width, S.Top + S.Height),
               C, AntiC);
  end;

  procedure Validate;
  var
    X, Y: Integer;
    P: PColor32;
  begin
    for y := 0 to Dst.Height-1 do
      for x := 0 to Dst.Width-1 do
      begin
        P := Dst.PixelPtr[x, y];

        // Remove all terrain markings if it's nonsolid
        if P^ and PM_SOLID = 0 then P^ := P^ and (not PM_TERRAIN);

        // Remove one-way markings if it's steel
        if P^ and PM_STEEL <> 0 then P^ := P^ and not PM_ONEWAY;

        // Remove one-way markings if it's not one-way capable
        if P^ and PM_ONEWAY = 0 then P^ := P^ and not (PM_ONEWAYLEFT or PM_ONEWAYRIGHT or PM_ONEWAYDOWN or PM_ONEWAYUP);

        P^ := P^ and not PM_NOCANCELSTEEL;
      end;
  end;

begin
  if Dst = nil then Dst := fPhysicsMap; // should it ever not be to here? Maybe during debugging we need it elsewhere
  Bmp := TBitmap32.Create;

  fPhysicsMap.Clear(0);

  with Inf.Level do
  begin
    Dst.SetSize(Info.Width, Info.Height);

    for i := 0 to Terrains.Count-1 do
    begin
      T := Terrains[i];
      MT := FindMetaTerrain(T);
      PrepareTerrainFunctionBitmap(T, Bmp, MT);
      TerrainBitmapAutosteelMod(Bmp, Info.LevelOptions and $02 <> 0, Info.LevelOptions and $08 <> 0);
      Bmp.DrawTo(Dst, T.Left, T.Top);
    end;

    for i := 0 to fObjectInfoList.Count-1 do
    begin
      O := fObjectInfoList[i];
      ApplyOWW(O); // ApplyOWW takes care of ignoring non-OWW objects, no sense duplicating the check
    end;

    for i := 0 to Steels.Count-1 do
    begin
      S := Steels[i];
      ApplyArea(S);
    end;
  end;

  Validate;

  Bmp.Free;
end;

procedure TRenderer.RenderWorld(World: TBitmap32; DoBackground: Boolean); // Called only from Preview Screen
var
  i: Integer;
  x, y: Integer;

  Lem: TPreplacedLemming;
  L: TLemming;
  BgImg: TBitmap32;

  procedure CheckLockedExits;
  var
    i: Integer;
    HasButtons: Boolean;
  begin
    HasButtons := False;
    // Check whether buttons exist
    for i := 0 to fObjectInfoList.Count - 1 do
    begin
      if fObjectInfoList[i].TriggerEffect = DOM_BUTTON then
        HasButtons := True;
    end;
    if not HasButtons then
    begin
      // Set all exits to open exits
      for i := 0 to fObjectInfoList.Count - 1 do
      begin
        if fObjectInfoList[i].TriggerEffect in [DOM_EXIT, DOM_LOCKEXIT] then
          fObjectInfoList[i].CurrentFrame := 0
      end;
    end
  end;

  procedure LoadBackgroundImage;
  var
    Collection, Piece: String;
    SplitPos: Integer;
  begin
    SplitPos := pos(':', Inf.Level.Info.Background);
    Collection := LeftStr(Inf.Level.Info.Background, SplitPos-1);
    Piece := RightStr(Inf.Level.Info.Background, Length(Inf.Level.Info.Background)-SplitPos);

    if FileExists(AppPath + SFStyles + Collection + '\backgrounds\' + Piece + '.png') then
      TPngInterface.LoadPngFile((AppPath + SFStyles + Collection + '\backgrounds\' + Piece + '.png'), BgImg)
    else begin
      BgImg.SetSize(320, 160);
      BgImg.Clear(fTheme.Colors['background']);
    end;
  end;
begin
  if Inf.Level = nil then Exit;

  fDisableBackground := not DoBackground;
  fDoneBackgroundDraw := false;

  // Background layer
  fBgColor := Theme.Colors[BACKGROUND_COLOR] and $FFFFFF;
  fLayers[rlBackground].Clear($FF000000 or fBgColor);

  if DoBackground and (Inf.Level.Info.Background <> '') then
  begin
    BgImg := TBitmap32.Create;
    try
      LoadBackgroundImage;
      for y := 0 to Inf.Level.Info.Height div BgImg.Height do
        for x := 0 to Inf.Level.Info.Width div BgImg.Width do
          BgImg.DrawTo(fLayers[rlBackground], x * BgImg.Width, y * BgImg.Height);
    finally
      BgImg.Free;
    end;
  end;

  // Check whether there are no buttons to display open exits
  CheckLockedExits;

  // Draw all objects (except ObjectHelpers)
  DrawAllObjects(fObjectInfoList, False);

  // Draw preplaced lemmings
  L := TLemming.Create;
  for i := 0 to Inf.Level.PreplacedLemmings.Count-1 do
  begin
    Lem := Inf.Level.PreplacedLemmings[i];

    L.SetFromPreplaced(Lem);
    L.LemIsZombie := Lem.IsZombie;

    if (fPhysicsMap.PixelS[L.LemX, L.LemY] and PM_SOLID = 0) then
      L.LemAction := baFalling
    else if Lem.IsBlocker then
      L.LemAction := baBlocking
    else
      L.LemAction := baWalking;

    DrawThisLemming(L);
  end;
  L.Free;

  // Draw all terrain pieces
  for i := 0 to Inf.Level.Terrains.Count-1 do
  begin
    DrawTerrain(fLayers[rlTerrain], Inf.Level.Terrains[i]);
  end;

  // remove non-solid pixels from rlTerrain (possible coming from alpha-blending)
  ApplyRemovedTerrain(0, 0, fPhysicsMap.Width, fPhysicsMap.Height);

  // Combine all layers to the WorldMap
  World.SetSize(fLayers.Width, fLayers.Height);
  fLayers.PhysicsMap := fPhysicsMap;
  fLayers.CombineTo(World);
end;


procedure TRenderer.CreateInteractiveObjectList(var ObjInfList: TInteractiveObjectInfoList);
var
  i: Integer;
  ObjInf: TInteractiveObjectInfo;
  MO: TMetaObjectInterface;
begin
  for i := 0 to Inf.Level.InteractiveObjects.Count - 1 do
  begin
    MO := FindMetaObject(Inf.Level.InteractiveObjects[i]);
    ObjInf := TInteractiveObjectInfo.Create(Inf.Level.InteractiveObjects[i], MO);

    // Check whether trigger area intersects the level area, except for moving backgrounds
    if    (ObjInf.TriggerRect.Top > Inf.Level.Info.Height)
       or (ObjInf.TriggerRect.Bottom < 0)
       or (ObjInf.TriggerRect.Right < 0)
       or (ObjInf.TriggerRect.Left > Inf.Level.Info.Width) then
    begin
      if ObjInf.TriggerEffect <> DOM_BACKGROUND then ObjInf.IsDisabled := True;
    end;

    ObjInfList.Add(ObjInf);
  end;

  // Get ReceiverID for all Teleporters
  ObjInfList.FindReceiverID;
end;


procedure TRenderer.PrepareGameRendering(aLevel: TLevel; NoOutput: Boolean = false);
begin

  Inf.Level := aLevel;

  if not NoOutput then
  begin
    fTheme.Load(aLevel.Info.GraphicSetName);
    PieceManager.SetTheme(fTheme);

    fAni.ClearData;
    fAni.LemmingPrefix := fTheme.Lemmings;
    fAni.MaskingColor := fTheme.Colors[MASK_COLOR];
    fAni.MainDataFile := 'main.dat';
    fAni.ReadData;

    fRecolorer.LoadSwaps(fTheme.Lemmings);

    // Prepare the bitmaps
    fLayers.Prepare(Inf.Level.Info.Width, Inf.Level.Info.Height);
  end;

  // Creating the list of all interactive objects.
  fObjectInfoList.Clear;
  CreateInteractiveObjectList(fObjectInfoList);

  if fRenderInterface <> nil then
  begin
    fRenderInterface.UserHelper := hpi_None;
    fRenderInterface.DisableDrawing := NoOutput;
  end;

  // Draw the PhysicsMap
  RenderPhysicsMap;
end;

end.

