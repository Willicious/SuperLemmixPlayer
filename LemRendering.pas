{$include lem_directives.inc}

unit LemRendering;

{-------------------------------------------------------------------------------
  Some notes on the rendering here...

  Levels consist of terrains and objects.
  1) Objects kan animate and terrain can be changed.
  2) Lemmings only have collisions with terrain

  The alpha channel of the pixels is used to put information about the pixels
  in the bitmap:
  Bit0 = there is terrain in this pixel
  Bit1 = there is interactive object in this pixel (maybe this makes no sense)

  This is done to optimize the drawing of (funny enough) static and triggered
  objects. mmm how are we going to do that????

  (Other ideas: pixel builder-brick, pixel erased by basher/miner/digger, triggerarea)
-------------------------------------------------------------------------------}

interface

uses
  Dialogs,
  Classes, {Contnrs,} Math, Windows,
  GR32, GR32_LowLevel, GR32_Blend,
  UMisc,
  SysUtils,
  PngInterface,
  LemRecolorSprites,
  LemRenderHelpers, LemNeoPieceManager, LemNeoTheme,
  LemDosBmp, LemDosStructures,
  LemTypes,
  LemTerrain, LemMetaTerrain,
  LemObjects, LemInteractiveObject, LemMetaObject,
  LemSteel,
  LemLemming,
  LemDosAnimationSet, LemMetaAnimation, LemCore,
  LemLevel;

  // we could maybe use the alpha channel for rendering, ok thats working!
  // create gamerenderlist in order of rendering

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
    fRenderInterface: TRenderInterface;

    fRecolorer: TRecolorImage;

    fPhysicsMap: TBitmap32;
    fLayers: TRenderBitmaps;

    TempBitmap         : TBitmap32;
    Inf                : TRenderInfoRec;
    fXmasPal : Boolean;

    fTheme: TNeoTheme;

    fPieceManager: TNeoPieceManager;

    fHelperImages: THelperImages;

    {fWorld: TBitmap32;}

    fAni: TBaseDosAnimationSet;

    fBgColor : TColor32;

    fParticles                 : TParticleTable; // all particle offsets

    fObjectInfoList: TInteractiveObjectInfoList; // For rendering from Preview screen

    // Add stuff
    procedure AddTerrainPixel(X, Y: Integer);
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

    function GetTerrainLayer: TBitmap32;
    function GetParticleLayer: TBitmap32;

  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetInterface(aInterface: TRenderInterface);

    procedure DrawLevel(aDst: TBitmap32; aClearPhysics: Boolean = false); overload;
    procedure DrawLevel(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false); overload;

    function FindMetaObject(O: TInteractiveObject): TMetaObjectInterface;
    function FindMetaTerrain(T: TTerrain): TMetaTerrain;

    procedure PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);

    // Terrain rendering
    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain);

    // Object rendering
    procedure DrawAllObjects(ObjectInfos: TInteractiveObjectInfoList; DrawHelper: Boolean = True);
    procedure DrawObjectHelpers(Dst: TBitmap32; Obj: TInteractiveObjectInfo);

    // Lemming rendering
    procedure DrawLemmings;
    procedure DrawThisLemming(aLemming: TLemming; Selected: Boolean = false);
    procedure DrawLemmingHelper(aLemming: TLemming);
    procedure DrawLemmingParticles(L: TLemming);

    procedure DrawShadows(L: TLemming; SkillButton: TSkillPanelButton; PosMarker: Integer);
    procedure DrawGliderShadow(L: TLemming);
    procedure ClearShadows;
    procedure SetLowShadowPixel(X, Y: Integer);
    procedure SetHighShadowPixel(X, Y: Integer);


    procedure RenderWorld(World: TBitmap32; DoBackground: Boolean);
    procedure RenderPhysicsMap(Dst: TBitmap32 = nil);

    procedure CreateInteractiveObjectList(var ObjInfList: TInteractiveObjectInfoList);

    // Minimap
    procedure RenderMinimap(Dst: TBitmap32);
    procedure CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);

    property PhysicsMap: TBitmap32 read fPhysicsMap;
    property BackgroundColor: TColor32 read fBgColor write fBgColor;
    property Theme: TNeoTheme read fTheme;

    property TerrainLayer: TBitmap32 read GetTerrainLayer; // for save state purposes
    property ParticleLayer: TBitmap32 read GetParticleLayer; // needs to be replaced with making TRenderer draw them
  end;

implementation

uses
  LemMetaConstruct, UTools;

{ TRenderer }

procedure TRenderer.SetInterface(aInterface: TRenderInterface);
begin
  fRenderInterface := aInterface;
  fRenderInterface.SetDrawRoutine(di_ConstructivePixel, AddTerrainPixel);
  fRenderInterface.SetDrawRoutine(di_Stoner, AddStoner);
  fRenderInterface.SetRemoveRoutine(ApplyRemovedTerrain);
end;

// Minimap drawing

procedure TRenderer.RenderMinimap(Dst: TBitmap32);
var
  OldCombine: TPixelCombineEvent;
  OldMode: TDrawMode;

  i: Integer;
  L: TLemming;
begin
  Dst.Clear(fTheme.Colors[BACKGROUND_COLOR]);
  OldCombine := fPhysicsMap.OnPixelCombine;
  OldMode := fPhysicsMap.DrawMode;

  fPhysicsMap.DrawMode := dmCustom;
  fPhysicsMap.OnPixelCombine := CombineMinimapPixels;

  fPhysicsMap.DrawTo(Dst, Dst.BoundsRect, fPhysicsMap.BoundsRect);

  fPhysicsMap.OnPixelCombine := OldCombine;
  fPhysicsMap.DrawMode := OldMode;

  if fRenderInterface = nil then Exit;
  if fRenderInterface.LemmingList = nil then Exit;

  for i := 0 to fRenderInterface.LemmingList.Count-1 do
  begin
    L := fRenderInterface.LemmingList[i];
    if L.LemRemoved then Continue;
    Dst.PixelS[L.LemX div 16, L.LemY div 8] := $FF00FF00;
  end;
end;

procedure TRenderer.CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and PM_SOLID) <> 0 then
    B := fTheme.Colors[MINIMAP_COLOR] or $FF000000;
end;

// Lemming Drawing

procedure TRenderer.DrawLemmings;
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
  if fRenderInterface.SelectedLemming <> nil then DrawThisLemming(fRenderInterface.SelectedLemming, true);

  // Draw particles for exploding lemmings
  fLayers.fIsEmpty[rlParticles] := True;
  for i := 0 to LemmingList.Count-1 do
  begin
    if LemmingList[i].LemParticleTimer > 0 then
    begin
      DrawLemmingParticles(LemmingList[i]);
      fLayers.fIsEmpty[rlParticles] := False;
    end;
    DrawLemmingHelper(LemmingList[i]);
  end;
end;

procedure TRenderer.DrawThisLemming(aLemming: TLemming; Selected: Boolean = false);
var
  SrcRect, DstRect: TRect;
  SrcAnim: TBitmap32;
  SrcMetaAnim: TMetaLemmingAnimation;
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

  SrcRect := GetFrameBounds;
  DstRect := GetLocationBounds;
  SrcAnim.DrawMode := dmCustom;
  SrcAnim.OnPixelCombine := fRecolorer.CombineLemmingPixels;
  SrcAnim.DrawTo(fLayers[rlLemmings], DstRect, SrcRect);
end;

procedure TRenderer.DrawLemmingHelper(aLemming: TLemming);
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


procedure TRenderer.DrawShadows(L: TLemming; SkillButton: TSkillPanelButton; PosMarker: Integer);
const
  // This encodes only the right half of the bomber mask. The rest is obtained by mirroring it
  BomberShadowPos: array[0..35, 0..1] of Integer = (
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
  i, j: Integer;
begin
  case SkillButton of
  spbPlatformer:
    begin
      fLayers.fIsEmpty[rlLowShadows] := False;
      for i := 0 to 38 do // Yes, platforms are 39 pixels long!
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY);
    end;

  spbBuilder:
    begin
      fLayers.fIsEmpty[rlLowShadows] := False;
      for j := 1 to 12 do
      for i := 2*j - 3 to 2*j + 3 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY - j);
    end;

  spbStacker: // PosMarker adapts the starting position for the first brick
    begin
      fLayers.fIsEmpty[rlLowShadows] := False;
      for j := PosMarker to PosMarker + 7 do
      for i := 0 to 3 do
        SetLowShadowPixel(L.LemX + i*L.LemDx, L.LemY - j);
    end;

  spbDigger: // PosMarker gives the number of pixels to move vertically
    begin
      fLayers.fIsEmpty[rlHighShadows] := False;
      for j := 1 to PosMarker do
      begin
        SetHighShadowPixel(L.LemX - 4, L.LemY + j - 1);
        SetHighShadowPixel(L.LemX + 4, L.LemY + j - 1);
      end;
    end;

  spbMiner: // PosMarker gives the number of pixels to move vertically
    begin
      fLayers.fIsEmpty[rlHighShadows] := False;

      // Three starting top pixels
      for j := 0 to 2 do
        SetHighShadowPixel(L.LemX + j*L.LemDx, L.LemY - 12);

      for j := 0 to PosMarker do
      begin
        // Bottom border of tunnel
        SetHighShadowPixel(L.LemX + (2*j+1)*L.LemDx, L.LemY + j - 1);
        SetHighShadowPixel(L.LemX + (2*j+1)*L.LemDx, L.LemY + j);
        SetHighShadowPixel(L.LemX + (2*j+2)*L.LemDx, L.LemY + j);
        // Top border of tunnel
        if j mod 2 = 0 then
        begin
          SetHighShadowPixel(L.LemX + (2*j+3)*L.LemDx, L.LemY + j - 12);
          SetHighShadowPixel(L.LemX + (2*j+4)*L.LemDx, L.LemY + j - 12);
          SetHighShadowPixel(L.LemX + (2*j+5)*L.LemDx, L.LemY + j - 12);
          SetHighShadowPixel(L.LemX + (2*j+5)*L.LemDx, L.LemY + j - 11);
          SetHighShadowPixel(L.LemX + (2*j+6)*L.LemDx, L.LemY + j - 11);
          SetHighShadowPixel(L.LemX + (2*j+6)*L.LemDx, L.LemY + j - 10);
        end;
      end;
    end;

  spbBasher: // PosMarker gives the number of pixels to move horizontally
    begin
      fLayers.fIsEmpty[rlHighShadows] := False;
      for i := 3 to PosMarker do
      begin
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 1);
        SetHighShadowPixel(L.LemX + i*L.LemDx, L.LemY - 9);
      end;
    end;

  spbExplode: // PosMarker adapts the starting position horizontally
    begin
      fLayers.fIsEmpty[rlHighShadows] := False;
      for i := 0 to 35 do
      begin
        SetHighShadowPixel(L.LemX + PosMarker + BomberShadowPos[i, 0], L.LemY + BomberShadowPos[i, 1]);
        SetHighShadowPixel(L.LemX + PosMarker - BomberShadowPos[i, 0] - 1, L.LemY + BomberShadowPos[i, 1]);
      end;
    end;


  spbGlider: DrawGliderShadow(L);

  end;
end;

procedure TRenderer.DrawGliderShadow(L: TLemming);
var
  CopyL: TLemming;
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
  // Copy L to simulate the path
  CopyL := TLemming.Create;
  CopyL.Assign(L);
  // and make sure the copied lemming is a glider
  CopyL.LemIsGlider := True;

  // Draw first pixel at lemming position
  SetLowShadowPixel(CopyL.LemX, CopyL.LemY - 1);

  // We simulate as long as the lemming is gliding, but allow for a falling period at the beginning
  while     (FrameCount < MaxFrameCount)
        and Assigned(CopyL)
        and ((CopyL.LemAction = baGliding) or ((FrameCount < 10) and (CopyL.LemAction = baFalling))) do
  begin
    Inc(FrameCount);

    // Print shadow pixel of previous movement
    if Assigned(LemPosArray) then
      for i := 0 to Length(LemPosArray[0]) do
        SetLowShadowPixel(LemPosArray[0, i], LemPosArray[1, i] - 1);

    // Simulate next frame advance for lemming
    LemPosArray := fRenderInterface.SimulateLem(CopyL);
  end;

  CopyL.Free;
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
    // Only draw this on terrain, but not on steel
    if (fPhysicsMap.Pixel[X, Y] and PM_SOLID <> 0) and (fPhysicsMap.Pixel[X, Y] and PM_STEEL = 0) then
      fLayers[rlHighShadows].Pixel[X, Y] := SHADOW_COLOR;
end;

procedure TRenderer.AddTerrainPixel(X, Y: Integer);
var
  P: PColor32;
  C: TColor32;
begin
  P := fLayers[rlTerrain].PixelPtr[X, Y];
  if P^ and $FF000000 <> $FF000000 then
  begin
    C := Theme.Colors[MASK_COLOR];
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
  MO := fPieceManager.Objects[FindLabel];
  df := O.DrawingFlags;
  Result := MO.GetInterface(df and odf_Flip <> 0, df and odf_UpsideDown <> 0, df and odf_Rotate <> 0);
end;

function TRenderer.FindMetaTerrain(T: TTerrain): TMetaTerrain;
var
  FindLabel: String;
begin
  FindLabel := T.GS + ':' + T.Piece;
  Result := fPieceManager.Terrains[FindLabel];
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

  if Src is TMetaConstruct then
    TMetaConstruct(Src).SetRenderer(Self);

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

  if MT is TMetaConstruct then
    TMetaConstruct(MT).SetRenderer(Self);

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
  Dst := fLayers[rlObjectHelpers]; // for now

  O := Obj.Obj;
  MO := Obj.MetaObj;

  // We don't question here whether the conditions are met to draw the helper or
  // not. We assume the calling routine has already done this, and we just draw it.
  // We do, however, determine which ones to draw here.

  DrawX := O.Left + (MO.Width div 2) - 4;
  DrawY := O.Top - 9; // much simpler

  // Windows
  if MO.TriggerEffect = 23 then
  begin
    if (O.TarLev and $68) <> 0 then DrawX := DrawX - 4;

    if (O.DrawingFlags and odf_FlipLem) = 0 then
      fHelperImages[hpi_ArrowRight].DrawTo(Dst, DrawX, DrawY)
    else
      fHelperImages[hpi_ArrowLeft].DrawTo(Dst, DrawX, DrawY);

    if (O.TarLev and $68) <> 0 then
      fHelperImages[hpi_Exclamation].DrawTo(Dst, DrawX+8, DrawY);
  end;

  // Teleporters and Receivers
  if MO.TriggerEffect = 11 then
    fHelperImages[THelperIcon(Obj.PairingID)].DrawTo(Dst, DrawX, DrawY);
  if MO.TriggerEffect = 12 then
    fHelperImages[THelperIcon(Obj.PairingID)].DrawTo(Dst, DrawX, DrawY);
end;

procedure TRenderer.DrawAllObjects(ObjectInfos: TInteractiveObjectInfoList; DrawHelper: Boolean = True);
var
  TempBitmapRect, DstRect: TRect;
  Inf: TInteractiveObjectInfo;
  DrawFrame: Integer;
  i, i2: Integer;

  procedure ProcessDrawFrame(aLayer: TRenderLayer);
  var
    CountX, CountY, iX, iY: Integer;
    MO: TMetaObjectInterface;
  begin
    if Inf.IsInvisible then Exit;
    if Inf.TriggerEffect in [13, 16, 25, 32] then Exit;

    DrawFrame := Min(Inf.CurrentFrame, Inf.AnimationFrameCount-1);
    TempBitmap.Assign(Inf.Frames[DrawFrame]);

    PrepareObjectBitmap(TempBitmap, Inf.Obj.DrawingFlags, Inf.ZombieMode);

    MO := Inf.MetaObj;
    CountX := (Inf.Width-1) div MO.Width;
    CountY := (Inf.Height-1) div MO.Height;    

    for iY := 0 to CountY do
    begin
      // (re)size rectangles correctly
      TempBitmapRect := TempBitmap.BoundsRect;
      DstRect := TempBitmap.BoundsRect;
      // Move to leftmost X-coordinate and correct Y-coordinate
      DstRect := ZeroTopLeftRect(DstRect);
      OffsetRect(DstRect, Inf.Left, Inf.Top + (MO.Height * iY));
      // shrink sizes of rectange to draw on bottom row
      if iY = CountY then
      begin
        Dec(DstRect.Bottom, Inf.Height mod MO.Height);
        Dec(TempBitmapRect.Bottom, Inf.Height mod MO.Height);
      end;

      for iX := 0 to CountX do
      begin
        // shrink size of rectangle to draw on rightmost column
        if iX = CountX then
        begin
          Dec(DstRect.Right, Inf.Width mod MO.Width);
          Dec(TempBitmapRect.Right, Inf.Width mod MO.Width);
        end;
        // Draw copy of object onto alayer at this place
        TempBitmap.DrawTo(fLayers[aLayer], DstRect, TempBitmapRect);
        // Move to next row
        OffsetRect(DstRect, MO.Width, 0);
      end;
    end;

    Inf.Obj.LastDrawX := Inf.Left;
    Inf.Obj.LastDrawY := Inf.Top;
  end;

begin
  // Draw moving backgrounds
  if not fLayers.fIsEmpty[rlBackgroundObjects] then fLayers[rlBackgroundObjects].Clear(0);
  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos[i];
    if not (Inf.TriggerEffect = 30) then Continue;

    ProcessDrawFrame(rlBackgroundObjects);
    fLayers.fIsEmpty[rlBackgroundObjects] := False;
  end;

  // Draw no overwrite objects
  if not fLayers.fIsEmpty[rlObjectsLow] then fLayers[rlObjectsLow].Clear(0);
  for i := ObjectInfos.Count - 1 downto 0 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect in [7, 8, 19, 30] then Continue;
    if Inf.IsOnlyOnTerrain then Continue;
    if not Inf.IsNoOverwrite then Continue;

    ProcessDrawFrame(rlObjectsLow);
    fLayers.fIsEmpty[rlObjectsLow] := False;
  end;

  // Draw only-on-terrain
  if not fLayers.fIsEmpty[rlOnTerrainObjects] then fLayers[rlOnTerrainObjects].Clear(0);
  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect in [7, 8, 19, 30] then Continue;
    if not Inf.IsOnlyOnTerrain then Continue;

    ProcessDrawFrame(rlOnTerrainObjects);
    fLayers.fIsEmpty[rlOnTerrainObjects] := False;
  end;

  // Draw one-way arrows
  if not fLayers.fIsEmpty[rlOneWayArrows] then fLayers[rlOneWayArrows].Clear(0);
  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if not (Inf.TriggerEffect in [7, 8, 19]) then Continue;

    ProcessDrawFrame(rlOneWayArrows);
    fLayers.fIsEmpty[rlOneWayArrows] := False;
  end;

  // Draw regular objects
  if not fLayers.fIsEmpty[rlObjectsHigh] then fLayers[rlObjectsHigh].Clear(0);
  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect in [7, 8, 19, 30] then Continue;
    if Inf.IsOnlyOnTerrain then Continue;
    if Inf.IsNoOverwrite then Continue;

    ProcessDrawFrame(rlObjectsHigh);
    fLayers.fIsEmpty[rlObjectsHigh] := False;
  end;

  if DrawHelper then
  begin
    // Draw object helpers
    fLayers[rlObjectHelpers].Clear(0);
    for i := 0 to ObjectInfos.Count-1 do
    begin
      Inf := ObjectInfos[i];

      // Check if this object is relevant
      if not PtInRect(Rect(Inf.Left, Inf.Top, Inf.Left + Inf.Width - 1, Inf.Top + Inf.Height - 1),
                      fRenderInterface.MousePos) then
        Continue;

      if Inf.IsDisabled then Continue;

      // otherwise, draw its helper
      DrawObjectHelpers(fLayers[rlObjectHelpers], Inf);

      // if it's a teleporter or receiver, draw all paired helpers too
      if (Inf.TriggerEffect in [11, 12]) and (Inf.PairingId <> -1) then
        for i2 := 0 to ObjectInfos.Count-1 do
        begin
          if i = i2 then Continue;
          if (ObjectInfos[i2].PairingId = Inf.PairingId) then
            DrawObjectHelpers(fLayers[rlObjectHelpers], ObjectInfos[i2]);
        end;
    end;
  end;

end;


constructor TRenderer.Create;
var
  i: THelperIcon;
  S: TMemoryStream;
begin
  inherited Create;
  TempBitmap := TBitmap32.Create;
  fPieceManager := TNeoPieceManager.Create;
  fTheme := TNeoTheme.Create;
  fLayers := TRenderBitmaps.Create;
  fPhysicsMap := TBitmap32.Create;
  fBgColor := $00000000;
  fAni := TBaseDosAnimationSet.Create;
  fRecolorer := TRecolorImage.Create;
  fObjectInfoList := TInteractiveObjectInfoList.Create;
  for i := Low(THelperIcon) to High(THelperIcon) do
    fHelperImages[i] := TPngInterface.LoadPngFile(AppPath + 'gfx/helpers/' + HelperImageFilenames[i]);

  S := CreateDataStream('explode.dat', ldtParticles);
  S.Seek(0, soFromBeginning);
  S.Read(fParticles, S.Size);
  S.Free;
end;

destructor TRenderer.Destroy;
var
  i: THelperIcon;
begin
  TempBitmap.Free;
  fPieceManager.Free;
  fTheme.Free;
  fLayers.Free;
  fPhysicsMap.Free;
  fRecolorer.Free;
  fAni.Free;
  fObjectInfoList.Free;
  for i := Low(THelperIcon) to High(THelperIcon) do
    fHelperImages[i].Free;
  inherited Destroy;
end;

procedure TRenderer.RenderPhysicsMap(Dst: TBitmap32 = nil);
var
  i: Integer;
  T: TTerrain;
  MT: TMetaTerrain;
  O: TInteractiveObject;
  MO: TMetaObjectInterface;
  S: TSteel;
  Bmp: TBitmap32;

  procedure SetRegion(aRegion: TRect; C, AntiC: TColor32);
  var
    X, Y: Integer;
    P: PColor32;
  begin
    for y := aRegion.Top to aRegion.Bottom do
    begin
      if (y < 0) or (y >= Dst.Height) then Continue;
      for x := aRegion.Left to aRegion.Right do
      begin
        if (x < 0) or (x >= Dst.Width) then Continue;
        P := Dst.PixelPtr[x, y];
        P^ := (P^ or C) and (not AntiC);
      end;
    end;
  end;

  procedure ApplyOWW(O: TInteractiveObject; MO: TMetaObjectInterface);
  var
    C: TColor32;

    TW, TH: Integer;
  begin
    case MO.TriggerEffect of
      7: C := PM_ONEWAYLEFT;
      8: C := PM_ONEWAYRIGHT;
      19: C := PM_ONEWAYDOWN;
      else Exit; // should never happen, but just in case
    end;

    TW := MO.TriggerWidth;
    TH := MO.TriggerHeight;

    if MO.CanResizeHorizontal then
      TW := TW + (O.Width - MO.Width);
    if MO.CanResizeVertical then
      TH := TH + (O.Height - MO.Height);

    SetRegion( Rect(O.Left + MO.TriggerLeft,
                    O.Top + MO.TriggerTop,
                    O.Left + MO.TriggerLeft + TW - 1,
                    O.Top + MO.TriggerTop + TH - 1),
               C, 0);
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

    SetRegion( Rect(S.Left, S.Top, S.Left + S.Width - 1, S.Top + S.Height - 1),
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
        if P^ and PM_ONEWAY = 0 then P^ := P^ and not (PM_ONEWAYLEFT or PM_ONEWAYRIGHT or PM_ONEWAYDOWN);

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

    for i := 0 to InteractiveObjects.Count-1 do
    begin
      O := InteractiveObjects[i];
      MO := FindMetaObject(O);
      if not (MO.TriggerEffect in [7, 8, 19]) then
        Continue;
      ApplyOWW(O, MO);
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
begin
  if Inf.Level = nil then Exit;

  // Draw the PhysicsMap
  RenderPhysicsMap;

  // Prepare the bitmaps
  fLayers.Prepare(Inf.Level.Info.Width, Inf.Level.Info.Height);

  // Background layer
  fBgColor := Theme.Colors[BACKGROUND_COLOR] and $FFFFFF;
  fLayers[rlBackground].Clear($FF000000 or fBgColor);

  if fTheme.HasImageBackground and DoBackground then
  begin
    for y := 0 to Inf.Level.Info.Height div fTheme.Background.Height do
    for x := 0 to Inf.Level.Info.Width div fTheme.Background.Width do
      fTheme.Background.DrawTo(fLayers[rlBackground], x * fTheme.Background.Width, y * fTheme.Background.Height);
  end;


  // Creating the list of all interactive objects.
  fObjectInfoList.Clear;
  CreateInteractiveObjectList(fObjectInfoList);

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

    // Check whether trigger area intersects the level area
    if    (ObjInf.TriggerRect.Top > Inf.Level.Info.Height)
       or (ObjInf.TriggerRect.Bottom < 0)
       or (ObjInf.TriggerRect.Right < 0)
       or (ObjInf.TriggerRect.Left > Inf.Level.Info.Width) then
      ObjInf.IsDisabled := True;

    ObjInfList.Add(ObjInf);
  end;

  // Get ReceiverID for all Teleporters
  ObjInfList.FindReceiverID;
end;


procedure TRenderer.PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);
var
  i: Integer;
  LowPal, Pal: TArrayOfColor32;
begin

  Inf := Info;

  fPieceManager.Tidy;

  // create cache to draw from

  fXmasPal := XmasPal;

  fTheme.Load(Info.Level.Info.GraphicSetName);
  fPieceManager.SetTheme(fTheme);

  LowPal := DosPaletteToArrayOfColor32(DosInLevelPalette);
  if fXmasPal then
  begin
    LowPal[1] := $D02020;
    LowPal[4] := $F0F000;
    LowPal[5] := $4040E0;
  end;
  //LowPal[7] := Graph.BrickColor; // copy the brickcolor
  SetLength(Pal, 16);
  for i := 0 to 6 do
    Pal[i] := LowPal[i];
  Pal[7] := fTheme.Colors[MASK_COLOR];
  for i := 8 to 15 do
    Pal[i] := PARTICLE_COLORS[i mod 8];

  fAni.ClearData;
  fAni.LemmingPrefix := fTheme.Lemmings;
  fAni.AnimationPalette := Pal;
  fAni.MainDataFile := 'main.dat';
  fAni.ReadMetaData;
  fAni.ReadData;

  fRecolorer.LoadSwaps(fTheme.Lemmings);
end;

end.

