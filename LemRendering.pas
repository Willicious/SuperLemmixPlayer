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
  Classes, Contnrs, Math, Windows,
  GR32, GR32_LowLevel, GR32_Blend,
  UMisc,
  SysUtils,
  PngInterface,
  LemRecolorSprites,
  LemRenderHelpers, LemNeoPieceManager, LemNeoTheme,
  LemDosBmp, LemDosStructures,
  LemTypes,
  LemTerrain,
  LemObjects, LemInteractiveObject,   LemMetaObject,
  LemSteel,
  LemLemming,
  LemDosAnimationSet, LemMetaAnimation, LemCore,
  LemLevel;

  // we could maybe use the alpha channel for rendering, ok thats working!
  // create gamerenderlist in order of rendering

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

  PM_TERRAIN   = $000000FF;


  SHADOW_COLOR = $80202020;


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

    fWorld: TBitmap32;

    fAni: TBaseDosAnimationSet;

    fBgColor : TColor32;

    fParticles                 : TParticleTable; // all particle offsets

    // Add stuff
    procedure AddTerrainPixel(X, Y: Integer);
    procedure AddStoner(X, Y: Integer);

    // Graphical combines
    procedure CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);

    // Functional combines
    procedure PrepareTerrainFunctionBitmap(T: TTerrain; Dst: TBitmap32; Src: TTerrainRecord);
    procedure CombineTerrainFunctionDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionErase(F: TColor32; var B: TColor32; M: TColor32);

    procedure PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
    procedure PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);

    function GetTerrainLayer: TBitmap32;
    function GetParticleLayer: TBitmap32;
    procedure ApplyRemovedTerrain(X, Y, W, H: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetInterface(aInterface: TRenderInterface);

    procedure DrawLevel(aDst: TBitmap32); overload;
    procedure DrawLevel(aDst: TBitmap32; aRegion: TRect); overload;

    function FindMetaObject(O: TInteractiveObject): TObjectRecord;
    function FindMetaTerrain(T: TTerrain): TTerrainRecord;

    procedure PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);

    // Terrain rendering
    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain; SteelOnly: Boolean = false);

    // Object rendering
    procedure DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer);
    procedure DrawAllObjects;
    procedure DrawObjectHelpers(Dst: TBitmap32; Obj: TInteractiveObjectInfo);

    // Lemming rendering
    procedure DrawLemmings;
    procedure DrawThisLemming(aLemming: TLemming; Selected: Boolean = false);
    procedure DrawLemmingHelper(aLemming: TLemming);
    procedure DrawLemmingParticles(L: TLemming);

    procedure DrawLemming(Dst: TBitmap32; O: TInteractiveObject; Z: Boolean = false);

    function HasPixelAt(X, Y: Integer): Boolean;

    procedure ClearShadows;
    procedure SetLowShadowPixel(X, Y: Integer);
    procedure SetHighShadowPixel(X, Y: Integer);


    procedure RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);
    procedure RenderPhysicsMap(Dst: TBitmap32 = nil);

    // Minimap
    procedure RenderMinimap(Dst: TBitmap32; aLemmings: TLemmingList = nil);
    procedure CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);

    procedure Highlight(World: TBitmap32; M: TColor32);

    property PhysicsMap: TBitmap32 read fPhysicsMap;
    property BackgroundColor: TColor32 read fBgColor write fBgColor;
    property Theme: TNeoTheme read fTheme;

    property TerrainLayer: TBitmap32 read GetTerrainLayer; // for save state purposes
    property ParticleLayer: TBitmap32 read GetParticleLayer; // needs to be replaced with making TRenderer draw them
  end;

implementation

uses
  UTools;

{ TRenderer }

procedure TRenderer.SetInterface(aInterface: TRenderInterface);
begin
  fRenderInterface := aInterface;
  fRenderInterface.SetDrawRoutine(di_ConstructivePixel, AddTerrainPixel);
  fRenderInterface.SetDrawRoutine(di_Stoner, AddStoner);
end;

// Minimap drawing

procedure TRenderer.RenderMinimap(Dst: TBitmap32; aLemmings: TLemmingList = nil);
var
  OldCombine: TPixelCombineEvent;
  OldMode: TDrawMode;

  i: Integer;
  L: TLemming;
begin
  Dst.Clear(fTheme.BackgroundColor);
  OldCombine := fPhysicsMap.OnPixelCombine;
  OldMode := fPhysicsMap.DrawMode;

  fPhysicsMap.DrawMode := dmCustom;
  fPhysicsMap.OnPixelCombine := CombineMinimapPixels;

  fPhysicsMap.DrawTo(Dst, Dst.BoundsRect, fPhysicsMap.BoundsRect);

  fPhysicsMap.OnPixelCombine := OldCombine;
  fPhysicsMap.DrawMode := OldMode;

  if aLemmings = nil then Exit;

  for i := 0 to aLemmings.Count-1 do
  begin
    L := aLemmings[i];
    if L.LemRemoved then Continue;
    Dst.PixelS[L.LemX div 16, L.LemY div 8] := $FF00FF00;
  end;
end;

procedure TRenderer.CombineMinimapPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and PM_SOLID) <> 0 then
    B := fTheme.MapColor or $FF000000;
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

  for i := 0 to LemmingList.Count-1 do
    if LemmingList[i] <> fRenderInterface.SelectedLemming then DrawThisLemming(LemmingList[i]);

  if fRenderInterface.SelectedLemming <> nil then DrawThisLemming(fRenderInterface.SelectedLemming, true);

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

      // Compatibility kludges. These should be removed
      // and replaced with properly-modified animations.
      {if aLemming.LemAction in [baDigging, baFixing] then
      begin
        Inc(Left);
        Inc(Right);
      end;

      if aLemming.LemAction = baMining then
      begin
        Inc(Left, aLemming.LemDx);
        Inc(Right, aLemming.LemDx);

        if aLemming.LemFrame < 15 then
        begin
          Inc(Top);
          Inc(Bottom);
        end;
      end;}
    end;
  end;

begin
  if aLemming.LemRemoved then Exit;

  fRecolorer.Lemming := aLemming;
  fRecolorer.DrawAsSelected := Selected;

  // Get the animation and meta-animation
  if aLemming.LemDX > 0 then
    i := AnimationIndices[aLemming.LemAction, false]
  else
    i := AnimationIndices[aLemming.LemAction, true];
  SrcAnim := fAni.LemmingAnimations[i];
  SrcMetaAnim := fAni.MetaLemmingAnimations[i];

  // Now we want the frame
  i := aLemming.LemFrame mod SrcMetaAnim.FrameCount; // mod is probably unnessecary but doesn't hurt to be safe

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

  ShowCountdown := (aLemming.LemExplosionTimer > 0);
  ShowHighlight := (aLemming = fRenderInterface.HighlitLemming);

  if ShowCountdown and ShowHighlight then
    ShowCountdown := (GetTickCount mod 1000 < 500);

  if ShowCountdown then
  begin
    n := (aLemming.LemExplosionTimer div 17) + 1;
    SrcRect := Rect(n * 4, 0, ((n+1) * 4), 5);
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

procedure TRenderer.DrawLevel(aDst: TBitmap32);
begin
  DrawLevel(aDst, fPhysicsMap.BoundsRect);
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32; aRegion: TRect);
begin
  ApplyRemovedTerrain(0, 0, fPhysicsMap.Width, fPhysicsMap.Height);
  fLayers.PhysicsMap := fPhysicsMap;
  fLayers.CombineTo(aDst, aRegion);
end;

procedure TRenderer.ApplyRemovedTerrain(X, Y, W, H: Integer);
var
  cx, cy: Integer;
begin
  // Another somewhat kludgy thing. Eventually, TRenderer should probably handle
  // applying masks, thereby removing them from both the visual render and the
  // physics render at the same time.
  for cy := Y to (Y+H-1) do
    for cx := X to (X+W-1) do
      if PhysicsMap.Pixel[cx, cy] and PM_SOLID = 0 then
      begin
        // should we double-check all terrain bits are erased?
        fLayers[rlTerrain].Pixel[cx, cy] := 0;
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
  fLayers[rlLowShadows].Pixel[x, y] := SHADOW_COLOR;
  fLayers.fIsEmpty[rlLowShadows] := False;  // we do this too often, but it shouldn't matter much
end;

procedure TRenderer.SetHighShadowPixel(X, Y: Integer);
begin
  fLayers[rlHighShadows].Pixel[x, y] := SHADOW_COLOR;
  fLayers.fIsEmpty[rlHighShadows] := False;  // we do this too often, but it shouldn't matter much
end;

procedure TRenderer.AddTerrainPixel(X, Y: Integer);
var
  P: PColor32;
  C: TColor32;
begin
  P := fLayers[rlTerrain].PixelPtr[X, Y];
  if P^ and $FF000000 <> $FF000000 then
  begin
    C := Theme.MaskColor;
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

function TRenderer.FindMetaObject(O: TInteractiveObject): TObjectRecord;
var
  FindLabel: String;
begin
  FindLabel := O.GS + ':' + O.Piece;
  Result := fPieceManager.Objects[FindLabel];
end;

function TRenderer.FindMetaTerrain(T: TTerrain): TTerrainRecord;
var
  FindLabel: String;
begin
  FindLabel := T.GS + ':' + T.Piece;
  Result := fPieceManager.Terrains[FindLabel];
end;

// Functional combines

procedure TRenderer.PrepareTerrainFunctionBitmap(T: TTerrain; Dst: TBitmap32; Src: TTerrainRecord);
var
  x, y: Integer;
  PSrc, PDst: PColor32;
begin
  Dst.SetSizeFrom(Src.Image);
  Dst.Clear(0);
  for y := 0 to Src.Image.Height-1 do
  begin
    for x := 0 to Src.Image.Width-1 do
    begin
      PSrc := Src.Image.PixelPtr[x, y];
      PDst := Dst.PixelPtr[x, y];
      if (PSrc^ and $FF000000) <> 0 then
      begin
        PDst^ := PM_SOLID;
        if Src.Meta.Unknown and $01 <> 0 then
          PDst^ := PDst^ or PM_STEEL
        else if T.DrawingFlags and tdf_NoOneWay = 0 then
          PDst^ := PDst^ or PM_ONEWAY; 
      end else
        PDst^ := 0;
    end;
  end;

  if T.DrawingFlags and tdf_Rotate <> 0 then Dst.Rotate90;
  if T.DrawingFlags and tdf_Invert <> 0 then Dst.FlipVert;
  if T.DrawingFlags and tdf_Flip <> 0 then Dst.FlipHorz;

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
    B := F;
end;

procedure TRenderer.CombineTerrainFunctionNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and PM_SOLID = 0) then
    B := F;
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

(*procedure TRenderer.CombineObjectOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) {and (B and ALPHA_TERRAIN <> 0) and (B and ALPHA_ONEWAY <> 0)} then
  begin
    MergeMemEx(F, B, $FF);
  end;
end;*)

//prepareterrainbitmap was moved a bit further down, to make it easier to work on
//it and DrawTerrain at the same time

procedure TRenderer.PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);
begin
  if DrawingFlags and odf_OnlyOnTerrain <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
      Bmp.OnPixelCombine := CombineObjectDefault;
  end else begin
    Bmp.DrawMode := dmCustom;
    if Zombie then
      Bmp.OnPixelCombine := CombineObjectDefaultZombie
    else
      Bmp.OnPixelCombine := CombineObjectDefault;
  end;
end;

procedure TRenderer.DrawTerrain(Dst: TBitmap32; T: TTerrain; SteelOnly: Boolean = false);
var
  Src: TBitmap32;
  UDf: Byte;
  IsSteel: Boolean;
  IsNoOneWay: Boolean;

  TRec: TTerrainRecord;
begin

  TRec := FindMetaTerrain(T);
  Src := TRec.Image;

  UDf := T.DrawingFlags;
  IsSteel := ((TRec.Meta.Unknown and $01) = 1);
  IsNoOneWay := (UDf and tdf_NoOneWay <> 0);
  if (T.DrawingFlags and tdf_Invert = 0) and (T.DrawingFlags and tdf_Flip = 0) and (T.DrawingFlags and tdf_Rotate = 0) then
  begin
    PrepareTerrainBitmap(Src, UDf);
    Src.DrawTo(Dst, T.Left, T.Top);
  end
  else
  begin
    TempBitmap.Assign(Src);
    if (T.DrawingFlags and tdf_Rotate <> 0) then TempBitmap.Rotate90;
    if (T.DrawingFlags and tdf_Invert <> 0) then TempBitmap.FlipVert;
    if (T.DrawingFlags and tdf_Flip <> 0) then TempBitmap.FlipHorz;
    PrepareTerrainBitmap(TempBitmap, UDf);
    TempBitmap.DrawTo(Dst, T.Left, T.Top);
  end;
end;

procedure TRenderer.PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
begin
  if DrawingFlags and tdf_NoOverwrite <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainNoOverwrite;
  end else if DrawingFlags and tdf_Erase <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainErase;
  end else begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainDefault;
  end;
end;

procedure TRenderer.DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer);
{-------------------------------------------------------------------------------
  Draws a interactive object
  • Dst = the targetbitmap
  • O = the object
  • aOriginal = if specified then first a part of this bitmap (world when playing)
    is copied to Dst to restore
-------------------------------------------------------------------------------}
var
  SrcRect, DstRect: TRect;
  Src: TBitmap32;
  MO: TMetaObject;

  ORec: TObjectRecord;
begin

  ORec := FindMetaObject(O);
  MO := ORec.Meta;

  if O.DrawingFlags and odf_Invisible <> 0 then Exit;
  if MO.TriggerEffect = 25 then Exit;

  if aFrame > MO.AnimationFrameCount-1 then aFrame := MO.AnimationFrameCount-1; // for this one, it actually can matter sometimes

  Src := TBitmap32.Create;
  Src.Assign(ORec.Image[aFrame]);

  if odf_UpsideDown and O.DrawingFlags <> 0 then
    Src.FlipVert;

  if odf_Flip and O.DrawingFlags <> 0 then
    Src.FlipHorz;

  if MO.TriggerEffect in [7, 8, 19] then
  begin
    O.DrawingFlags := O.DrawingFlags and not odf_NoOverwrite;
    O.DrawingFlags := O.DrawingFlags or odf_OnlyOnTerrain;
  end;

  PrepareObjectBitmap(Src, O.DrawingFlags, O.DrawAsZombie);

  DstRect := Src.BoundsRect;
  DstRect := ZeroTopLeftRect(DstRect);
  OffsetRect(DstRect, O.Left, O.Top);

  Src.DrawTo(Dst, DstRect);
  Src.Free;

  O.LastDrawX := O.Left;
  O.LastDrawY := O.Top;
end;

procedure TRenderer.DrawObjectHelpers(Dst: TBitmap32; Obj: TInteractiveObjectInfo);
var
  O: TInteractiveObject;
  MO: TMetaObject;

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

procedure TRenderer.DrawAllObjects;
var
  SrcRect, DstRect: TRect;
  Inf: TInteractiveObjectInfo;
  Src: TBitmap32;
  DrawFrame: Integer;
  i, i2: Integer;
  UsePoint: Boolean;
  ObjectInfos: TInteractiveObjectInfoList;

  procedure ProcessDrawFrame(aLayer: TRenderLayer);
  begin
    if Inf.IsInvisible then Exit;
    if Inf.TriggerEffect in [13, 16, 25] then Exit;

    DrawFrame := Min(Inf.CurrentFrame, Inf.AnimationFrameCount-1);
    Src.Assign(Inf.Frames[DrawFrame]);

    if Inf.IsUpsideDown then
      Src.FlipVert;
    if Inf.IsFlipImage then
      Src.FlipHorz;

    PrepareObjectBitmap(Src, Inf.Obj.DrawingFlags, Inf.ZombieMode);

    SrcRect := Src.BoundsRect;
    DstRect := ZeroTopLeftRect(SrcRect);
    OffsetRect(DstRect, Inf.Left, Inf.Top);

    Src.DrawTo(fLayers[aLayer], DstRect, SrcRect);

    Inf.Obj.LastDrawX := Inf.Left;
    Inf.Obj.LastDrawY := Inf.Top;
  end;

  procedure FixLayer(Layer: TRenderLayer; Key: TColor32);
  var
    X, Y: Integer;
    PPhys, PLayer: PColor32;
  begin
    for y := 0 to fPhysicsMap.Height-1 do
      for x := 0 to fPhysicsMap.Width-1 do
      begin
        PPhys := PhysicsMap.PixelPtr[x, y];
        PLayer := fLayers[Layer].PixelPtr[x, y];
        if (PPhys^ and Key) = 0 then
          PLayer^ := 0;
      end;
  end;
begin
  Src := TBitmap32.Create;
  ObjectInfos := fRenderInterface.ObjectList;

  UsePoint := true; //PtInRect(Dst.BoundsRect, MousePoint);

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
  for i := ObjectInfos.Count-1 downto 0 do
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
  //FixLayer(rlOnTerrainObjects, PM_SOLID);

  // Draw one-way arrows
  if not fLayers.fIsEmpty[rlOneWayArrows] then fLayers[rlOneWayArrows].Clear(0);
  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if not (Inf.TriggerEffect in [7, 8, 19]) then Continue;

    ProcessDrawFrame(rlOneWayArrows);
    fLayers.fIsEmpty[rlOneWayArrows] := False;
  end;
  //FixLayer(rlOneWayArrows, PM_ONEWAY);

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

  // Draw object helpers
  fLayers[rlObjectHelpers].Clear(0);
  if UsePoint then
  begin
    for i := 0 to ObjectInfos.Count-1 do
    begin
      // Check if this object is relevant
      if not PtInRect(Rect(ObjectInfos[i].Left, ObjectInfos[i].Top,
                           ObjectInfos[i].Left + ObjectInfos[i].Width - 1, ObjectInfos[i].Top + ObjectInfos[i].Height - 1),
                      fRenderInterface.MousePos) then
        Continue;

      if ObjectInfos[i].IsDisabled then Continue;

      // otherwise, draw its helper
      DrawObjectHelpers(fLayers[rlObjectHelpers], ObjectInfos[i]);

      // if it's a teleporter or receiver, draw all paired helpers too
      if (ObjectInfos[i].TriggerEffect in [11, 12]) and (ObjectInfos[i].PairingId <> -1) then
        for i2 := 0 to ObjectInfos.Count-1 do
        begin
          if i = i2 then Continue;
          if (ObjectInfos[i2].PairingId = ObjectInfos[i].PairingId) then
            DrawObjectHelpers(fLayers[rlObjectHelpers], ObjectInfos[i2]);
        end;
    end;
  end;

  Src.Free;
end;



procedure TRenderer.DrawLemming(Dst: TBitmap32; O: TInteractiveObject; Z: Boolean = false);
var
  TempBmp: TBitmap32;
  tx, ty, dy: Integer;
  a: Integer;
  MO: TMetaObject;
  TempRect: TRect;
begin
  if O.IsFake then exit;
  tx := O.Left;
  ty := O.Top;
  MO := FindMetaObject(O).Meta;
  tx := tx + MO.TriggerLeft;
  ty := ty + MO.TriggerTop;

  if Inf.Level.Info.GimmickSet and 64 = 0 then
  begin
  if O.TarLev and 32 <> 0 then
  begin
    {while (ty <= Inf.Level.Info.Height-1) and (Dst.Pixel[tx, ty] and ALPHA_TERRAIN = 0) do
      inc(ty);}
  end else begin
    {dy := 0;
    while (dy < 3) and (ty + dy < Inf.Level.Info.Height) do
    begin
      if Dst.Pixel[tx, ty + dy] and ALPHA_TERRAIN <> 0 then
      begin
        ty := ty + dy;
        break;
      end;
      inc(dy);
    end;}
  end;
  end;

  {if ((ty > Inf.Level.Info.Height-1) or (Dst.Pixel[tx, ty] and ALPHA_TERRAIN = 0)) and (Inf.Level.Info.GimmickSet and 64 = 0) then
    a := FALLING
  else} if O.TarLev and 32 <> 0 then
    a := BLOCKING
  else
    a := WALKING;
  if O.DrawingFlags and 8 <> 0 then
  begin
    if a = FALLING then a := FALLING_RTL;
    if a = WALKING then a := WALKING_RTL;
  end;
  tx := tx - fAni.MetaLemmingAnimations[a].FootX;
  ty := ty - fAni.MetaLemmingAnimations[a].FootY;
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(fAni.LemmingAnimations[a]);
  //TempBmp.Height := TempBmp.Height div fAni.MetaLemmingAnimations[a].FrameCount;
  TempRect.Left := 0;
  TempRect.Top := 0;
  TempRect.Right := fAni.MetaLemmingAnimations[a].Width-1;
  TempRect.Bottom := fAni.MetaLemmingAnimations[a].Height;
  TempBmp.DrawMode := dmCustom;
  (*if Z then
    TempBmp.OnPixelCombine := CombineLemFrameZombie
    else
    TempBmp.OnPixelCombine := CombineLemFrame;*)
  TempBmp.DrawTo(Dst, tx, ty, TempRect);
  TempBmp.Free;
end;

(*procedure TRenderer.CombineLemFrame(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F and $FFFFFF <> 0 then
    B := F;
end;

procedure TRenderer.CombineLemFrameZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
  if F <> 0 then B := F;
end;*)

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
  for i := Low(THelperIcon) to High(THelperIcon) do
    fHelperImages[i].Free;
  inherited Destroy;
end;

procedure TRenderer.RenderPhysicsMap(Dst: TBitmap32 = nil);
var
  i: Integer;
  T: TTerrain;
  TRec: TTerrainRecord;
  O: TInteractiveObject;
  ORec: TObjectRecord;
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

  procedure ApplyOWW(O: TInteractiveObject; ORec: TObjectRecord);
  var
    C: TColor32;
  begin
    case ORec.Meta.TriggerEffect of
      7: C := PM_ONEWAYLEFT;
      8: C := PM_ONEWAYRIGHT;
      19: C := PM_ONEWAYDOWN;
      else Exit; // should never happen, but just in case
    end;

    SetRegion( Rect(O.Left + ORec.Meta.TriggerLeft,
                    O.Top + ORec.Meta.TriggerTop,
                    O.Left + ORec.Meta.TriggerLeft + ORec.Meta.TriggerWidth - 1,
                    O.Top + ORec.Meta.TriggerTop + ORec.Meta.TriggerHeight - 1),
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
      TRec := FindMetaTerrain(T);
      PrepareTerrainFunctionBitmap(T, Bmp, TRec);
      Bmp.DrawTo(Dst, T.Left, T.Top);
    end;

    for i := 0 to InteractiveObjects.Count-1 do
    begin
      O := InteractiveObjects[i];
      ORec := FindMetaObject(O);
      if not (ORec.Meta.TriggerEffect in [7, 8, 19]) then
        Continue;
      ApplyOWW(O, ORec);
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

procedure TRenderer.RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);
// DoObjects is only true if RenderWorld is called from the Preview Screen!
var
  i: Integer;
  dy: Integer;

  Bmp: TBitmap32;

  Obj: TInteractiveObject;
  ORec: TObjectRecord;

  Ter: TTerrain;
  TRec: TTerrainRecord;

  L: TLemming;
begin
  fBgColor := Theme.BackgroundColor and $FFFFFF;

  if Inf.Level = nil then Exit;

  RenderPhysicsMap;

  with Inf do
  begin

    // Prepare the bitmaps
    fLayers.Prepare(Level.Info.Width, Level.Info.Height);


    // Background layer
    with fLayers[rlBackground] do
    begin
      Clear($FF000000 or fBgColor);
    end;

    if DoObjects then
    begin
      with fLayers[rlBackgroundObjects] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect <> 30 then Continue;

          DrawObject(fLayers[rlBackgroundObjects], Obj, ORec.Meta.PreviewFrameIndex);
          fLayers.fIsEmpty[rlBackgroundObjects] := False;
        end;

      with fLayers[rlObjectsLow] do
        for i := Level.InteractiveObjects.Count-1 downto 0 do
        begin
          Obj := Level.InteractiveObjects[i];
          if Obj.DrawingFlags and odf_NoOverwrite = 0 then Continue;
          if Obj.DrawingFlags and odf_OnlyOnTerrain <> 0 then Continue;
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect in [7, 8, 13, 16, 19, 25, 30] then Continue;

          DrawObject(fLayers[rlObjectsLow], Obj, ORec.Meta.PreviewFrameIndex);
          fLayers.fIsEmpty[rlObjectsLow] := False;
        end;

      with fLayers[rlOnTerrainObjects] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          if Obj.DrawingFlags and odf_OnlyOnTerrain = 0 then Continue;
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect in [7, 8, 13, 16, 19, 25, 30] then Continue;

          DrawObject(fLayers[rlOnTerrainObjects], Obj, ORec.Meta.PreviewFrameIndex);
          fLayers.fIsEmpty[rlOnTerrainObjects] := False;
        end;

      with fLayers[rlOneWayArrows] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          ORec := FindMetaObject(Obj);
          if not (ORec.Meta.TriggerEffect in [7, 8, 19]) then Continue;

          DrawObject(fLayers[rlOneWayArrows], Obj, ORec.Meta.PreviewFrameIndex);
          fLayers.fIsEmpty[rlOneWayArrows] := False;
        end;

      with fLayers[rlObjectsHigh] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          if Obj.DrawingFlags and odf_NoOverwrite <> 0 then Continue;
          if Obj.DrawingFlags and odf_OnlyOnTerrain <> 0 then Continue;
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect in [7, 8, 13, 16, 19, 25, 30] then Continue;

          DrawObject(fLayers[rlObjectsHigh], Obj, ORec.Meta.PreviewFrameIndex);
          fLayers.fIsEmpty[rlObjectsHigh] := False;
        end;

      L := TLemming.Create;
      with fLayers[rlLemmings] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect <> 13 then Continue;

          with L do
          begin
            LemX := Obj.Left + ORec.Meta.TriggerLeft;
            LemY := Obj.Top + ORec.Meta.TriggerTop;
            if Obj.DrawingFlags and odf_FlipLem <> 0 then
              LemDx := -1
            else
              LemDx := 1;

            LemIsClimber  := (Obj.TarLev and $01 <> 0);
            LemIsSwimmer  := (Obj.TarLev and $02 <> 0);
            LemIsFloater  := (Obj.TarLev and $04 <> 0);
            LemIsGlider   := (Obj.TarLev and $08 <> 0);
            LemIsMechanic := (Obj.TarLev and $10 <> 0);
            LemIsZombie   := (Obj.TarLev and $40 <> 0);

            if (fPhysicsMap.PixelS[LemX, LemY] and PM_SOLID = 0) then
              LemAction := baFalling
            else if (Obj.TarLev and $20 <> 0) then
              LemAction := baBlocking
            else
              LemAction := baWalking;
          end;

          DrawThisLemming(L);
        end;
      L.Free;
    end;

    with fLayers[rlTerrain] do
      for i := 0 to Level.Terrains.Count-1 do
      begin
        Ter := Level.Terrains[i];
        TRec := FindMetaTerrain(Ter);
        if Ter.DrawingFlags and tdf_Erase = 0 then
          if SOX and (TRec.Meta.Unknown and $01 = 0) then
            Continue;
        DrawTerrain(fLayers[rlTerrain], Ter, SteelOnly);
      end;

  end; // with Inf

  World.SetSize(fLayers.Width, fLayers.Height);
  fLayers.PhysicsMap := fPhysicsMap;
  fLayers.CombineTo(World);

end;

procedure TRenderer.PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);
var
  i: Integer;
  Item: TObjectAnimation;
  Bmp: TBitmap32;
  MO: TMetaObject;
  LowPal, {HiPal,} Pal: TArrayOfColor32;
//  R: TRect;
begin

  Inf := Info;

  fPieceManager.Tidy;

  // create cache to draw from

  fXmasPal := XmasPal;

  fTheme.Load(Info.Level.Info.GraphicSetName);

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
  Pal[7] := fTheme.MaskColor;
  for i := 8 to 15 do
    Pal[i] := PARTICLE_COLORS[i mod 8];

  fAni.ClearData;
  fAni.LemmingPrefix := fTheme.Lemmings;
  fAni.AnimationPalette := Pal;
  fAni.MainDataFile := 'main.dat';
  fAni.ReadMetaData;
  fAni.ReadData;
end;

procedure TRenderer.Highlight(World: TBitmap32; M: TColor32);
var
  i: Integer;
  P: PColor32;
begin

  with World do
  begin
    P := PixelPtr[0, 0];
    for i := 0 to Width * Height - 1 do
    begin
      if P^ and M <> 0 then
        P^ := clRed32
      else
        P^ := 0;
      Inc(P);
    end;
  end;
end;

function TRenderer.HasPixelAt(X, Y: Integer): Boolean;
begin
  //Result := fWorld.PixelS[X, Y] and ALPHA_TERRAIN = 0;
  Result := true;
end;

end.

