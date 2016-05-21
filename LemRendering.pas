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
  Classes, Contnrs, Math,
  GR32, GR32_LowLevel, GR32_Blend,
  UMisc,
  SysUtils,
  LemRenderHelpers, LemNeoPieceManager, LemNeoTheme,
  LemDosBmp, LemDosStructures,
  LemTypes,
  LemTerrain,
  LemObjects, LemInteractiveObject,   LemMetaObject,
  LemSteel,
  LemDosAnimationSet,
  LemLevel;

  // we could maybe use the alpha channel for rendering, ok thats working!
  // create gamerenderlist in order of rendering

const
  PM_SOLID       = $00000001;
  PM_STEEL       = $00000002;
  PM_ONEWAY      = $00000004;
  PM_ONEWAYLEFT  = $00000008;
  PM_ONEWAYRIGHT = $00000010;
  PM_ONEWAYDOWN  = $00000020; // Yes, I know they're mutually incompatible, but it's easier to do this way

  PM_TERRAIN   = $000000FF;


  SHADOW_COLOR = $80202020;


type
  // temp solution
  TRenderInfoRec = record
    TargetBitmap : TBitmap32; // the visual bitmap
    Level        : TLevel;
  end;

  TRenderer = class
  private
    fPhysicsMap: TBitmap32;
    fLayers: TRenderBitmaps;

    TempBitmap         : TBitmap32;
    Inf                : TRenderInfoRec;
    fXmasPal : Boolean;

    fTheme: TNeoTheme;

    fPieceManager: TNeoPieceManager;

    fWorld: TBitmap32;

    fAni: TBaseDosAnimationSet;

    fBgColor : TColor32;

    // Graphical combines
    procedure CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);

    // Functional combines
    procedure PrepareTerrainFunctionBitmap(T: TTerrain; Dst: TBitmap32; Src: TTerrainRecord);
    procedure CombineTerrainFunctionDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainFunctionErase(F: TColor32; var B: TColor32; M: TColor32);

    procedure CombineLemFrame(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemFrameZombie(F: TColor32; var B: TColor32; M: TColor32);

    procedure PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte);
    procedure PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);

    function GetLemmingLayer: TBitmap32;
    function GetParticleLayer: TBitmap32;
    procedure ApplyRemovedTerrain(X, Y, W, H: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure DrawLevel(aDst: TBitmap32);

    function FindMetaObject(O: TInteractiveObject): TObjectRecord;
    function FindMetaTerrain(T: TTerrain): TTerrainRecord;

    procedure PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);

    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain; SteelOnly: Boolean = false);
    procedure DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer); Overload;
    procedure DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo); Overload;
    procedure DrawAllObjects(Dst: TBitmap32; ObjectInfos: TInteractiveObjectInfoList);

    procedure DrawLemming(Dst: TBitmap32; O: TInteractiveObject; Z: Boolean = false);
    procedure EraseObject(Dst: TBitmap32; O: TInteractiveObject;
      aOriginal: TBitmap32 = nil);
    procedure DrawSpecialBitmap(Dst: TBitmap32; Spec: TBitmaps; Inv: Boolean = false);

    function HasPixelAt(X, Y: Integer): Boolean;

    procedure ClearShadows;
    procedure SetLowShadowPixel(X, Y: Integer);
    procedure SetHighShadowPixel(X, Y: Integer);
    procedure AddTerrainPixel(X, Y: Integer; aColor: TColor32 = $00000000);


    procedure RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);
    procedure RenderPhysicsMap(Dst: TBitmap32 = nil);

    procedure Highlight(World: TBitmap32; M: TColor32);

    property PhysicsMap: TBitmap32 read fPhysicsMap;
    property BackgroundColor: TColor32 read fBgColor write fBgColor;
    property Theme: TNeoTheme read fTheme;

    property LemmingLayer: TBitmap32 read GetLemmingLayer; // this should be replaced with having TRenderer do the lemming drawing! But for now, this is a kludgy workaround
    property ParticleLayer: TBitmap32 read GetParticleLayer; // same
  end;

//const
  //COLOR_MASK    = $80FFFFFF; // transparent black flag is included!
  //ALPHA_MASK    = $FF000000;

  //ALPHA_TERRAIN          = $01000000;
  //ALPHA_OBJECT           = $02000000; // not really needed, but used
  //ALPHA_STEEL            = $04000000;
  //ALPHA_ONEWAY           = $08000000;

  // to enable black terrain. bitmaps with transparent black should include
  // this bit
  //ALPHA_TRANSPARENTBLACK = $80000000;

implementation

uses
  UTools;



{ TRenderer }

function TRenderer.GetLemmingLayer: TBitmap32;
begin
  Result := fLayers[rlLemmings];
end;

function TRenderer.GetParticleLayer: TBitmap32;
begin
  Result := fLayers[rlParticles];
end;

procedure TRenderer.DrawLevel(aDst: TBitmap32);
begin
  ApplyRemovedTerrain(0, 0, fPhysicsMap.Width, fPhysicsMap.Height);
  fLayers.CombineTo(aDst);
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
  fLayers[rlLowShadows].Clear(0);
  fLayers[rLHighShadows].Clear(0);
end;

procedure TRenderer.SetLowShadowPixel(X, Y: Integer);
begin
  fLayers[rlLowShadows].Pixel[x, y] := SHADOW_COLOR;
end;

procedure TRenderer.SetHighShadowPixel(X, Y: Integer);
begin
  fLayers[rlHighShadows].Pixel[x, y] := SHADOW_COLOR;
end;

procedure TRenderer.AddTerrainPixel(X, Y: Integer; aColor: TColor32 = $00000000);
var
  P: PColor32;
begin
  if aColor = 0 then aColor := Theme.MaskColor;
  P := fPhysicsMap.PixelPtr[X, Y];
  P^ := P^ or PM_SOLID;
  P := fLayers[rlTerrain].PixelPtr[X, Y];
  if P^ and $FF000000 <> $FF000000 then
  begin
    MergeMemEx(P^, aColor, $FF);
    P^ := aColor;
  end;
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
    MergeMemEx(F, B, $FF);
  end;
end;

procedure TRenderer.CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and $FF000000 <> $FF000000) then
  begin
    MergeMemEx(B, F, $FF);
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
    MergeMemEx(F, B, $FF);
  end;
end;

procedure TRenderer.CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
    MergeMemEx(F, B, $FF);
  end;
end;

procedure TRenderer.CombineObjectOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) {and (B and ALPHA_TERRAIN <> 0) and (B and ALPHA_ONEWAY <> 0)} then
  begin
    MergeMemEx(F, B, $FF);
  end;
end;

//prepareterrainbitmap was moved a bit further down, to make it easier to work on
//it and DrawTerrain at the same time

procedure TRenderer.PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);
begin
  if DrawingFlags and odf_OnlyOnTerrain <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
      Bmp.OnPixelCombine := CombineObjectOnlyOnTerrain;
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

procedure TRenderer.DrawSpecialBitmap(Dst: TBitmap32; Spec: TBitmaps; Inv: Boolean = false);
begin

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

procedure TRenderer.DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo);
var
  SrcRect, DstRect, R: TRect;
  Src: TBitmap32;
  DrawFrame: Integer;
begin

  if Gadget.IsInvisible then Exit;
  if Gadget.TriggerEffect = DOM_HINT then Exit;

  DrawFrame := MinIntValue([Gadget.CurrentFrame, Gadget.AnimationFrameCount - 1]);

  Src := TBitmap32.Create;
  Src.Assign(FindMetaObject(Gadget.Obj).Image[DrawFrame]);

  if Gadget.IsUpsideDown then
    Src.FlipVert;

  if Gadget.IsFlipImage then
    Src.FlipHorz;

  PrepareObjectBitmap(Src, Gadget.Obj.DrawingFlags, Gadget.ZombieMode);

  SrcRect := Src.BoundsRect;
  DstRect := ZeroTopLeftRect(SrcRect);
  OffsetRect(DstRect, Gadget.Left, Gadget.Top);

  Src.DrawTo(Dst, DstRect);
  Src.Free;

  Gadget.Obj.LastDrawX := Gadget.Left;
  Gadget.Obj.LastDrawY := Gadget.Top;
end;

procedure TRenderer.DrawAllObjects(Dst: TBitmap32; ObjectInfos: TInteractiveObjectInfoList);
var
  SrcRect, DstRect: TRect;
  Inf: TInteractiveObjectInfo;
  Src: TBitmap32;
  DrawFrame, i: Integer;

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
begin
  Src := TBitmap32.Create;

  // Draw moving backgrounds
  fLayers[rlBackgroundObjects].Clear(0);
  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos[i];
    if not Inf.TriggerEffect = 30 then Continue;
    ProcessDrawFrame(rlBackgroundObjects);
  end;

  // Draw no overwrite objects
  fLayers[rlObjectsLow].Clear(0);
  for i := ObjectInfos.Count-1 downto 0 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect = 30 then Continue;
    if not Inf.IsNoOverwrite then Continue;
    ProcessDrawFrame(rlObjectsLow);
  end;

  // Draw regular objects
  fLayers[rlObjectsHigh].Clear(0);
  for i := 0 to ObjectInfos.Count-1 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect = 30 then Continue;
    if Inf.IsNoOverwrite then Continue;
    ProcessDrawFrame(rlObjectsHigh);
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
  if Z then
    TempBmp.OnPixelCombine := CombineLemFrameZombie
    else
    TempBmp.OnPixelCombine := CombineLemFrame;
  TempBmp.DrawTo(Dst, tx, ty, TempRect);
  TempBmp.Free;
end;

procedure TRenderer.CombineLemFrame(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F and $FFFFFF <> 0 then
    B := F;
end;

procedure TRenderer.CombineLemFrameZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
  if F <> 0 then B := F;
end;

procedure TRenderer.EraseObject(Dst: TBitmap32; O: TInteractiveObject; aOriginal: TBitmap32);
{-------------------------------------------------------------------------------
  Draws a interactive object
  o Dst = the targetbitmap
  o O = the object
  o aOriginal = if specified then first a part of this bitmap (world when playing)
    is copied to Dst to restore
-------------------------------------------------------------------------------}
var
  SrcRect, DstRect, R: TRect;
  MO: TMetaObject;
  //Src: TBitmap32;
begin
  if aOriginal = nil then
    Exit;

  MO := FindMetaObject(O).Meta;
  //ObjectBitmapItems.List^[O.Identifier];

  SrcRect := Rect(0, 0, MO.Width, MO.Height);
  DstRect := SrcRect;
  DstRect := ZeroTopLeftRect(DstRect);
  OffsetRect(DstRect, O.LastDrawX, O.LastDrawY);

  IntersectRect(R, DstRect, aOriginal.BoundsRect); // oops important!
  aOriginal.DrawTo(Dst, R, R);
end;


constructor TRenderer.Create;
begin
  inherited Create;
  TempBitmap := TBitmap32.Create;
  fPieceManager := TNeoPieceManager.Create;
  fTheme := TNeoTheme.Create;
  fLayers := TRenderBitmaps.Create;
  fPhysicsMap := TBitmap32.Create;
  fBgColor := $00000000;
end;

destructor TRenderer.Destroy;
begin
  TempBitmap.Free;
  fPieceManager.Free;
  fTheme.Free;
  fLayers.Free;
  fPhysicsMap.Free;
  if fAni <> nil then fAni.Free;
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
      for x := aRegion.Left to aRegion.Right do
      begin
        P := BMP.PixelPtr[x, y];
        P^ := (P^ or C) and not AntiC;
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
    for y := 0 to BMP.Height-1 do
      for x := 0 to BMP.Width-1 do
      begin
        P := BMP.PixelPtr[x, y];

        // Remove all terrain markings if it's nonsolid
        if P^ and PM_SOLID = 0 then P^ := P^ and not PM_TERRAIN;

        // Remove one-way markings if it's steel
        if P^ and PM_STEEL <> 0 then P^ := P^ and not PM_ONEWAY;

        // Remove one-way markings if it's not one-way capable
        if P^ and PM_ONEWAY = 0 then P^ := P^ and not (PM_ONEWAYLEFT or PM_ONEWAYRIGHT or PM_ONEWAYDOWN);
      end;
  end;

begin
  if Dst = nil then Dst := fPhysicsMap; // should it ever not be to here? Maybe during debugging we need it elsewhere
  Bmp := TBitmap32.Create;

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

  Bmp: TBitmap32;

  Obj: TInteractiveObject;
  ORec: TObjectRecord;

  Ter: TTerrain;
  TRec: TTerrainRecord;
begin
  fBgColor := Theme.BackgroundColor and $FFFFFF;

  if Inf.Level = nil then Exit;

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
        end;

      with fLayers[rlObjectsLow] do
        for i := Level.InteractiveObjects.Count-1 downto 0 do
        begin
          Obj := Level.InteractiveObjects[i];
          if Obj.DrawingFlags and odf_NoOverwrite = 0 then Continue;
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect in [7, 8, 13, 16, 19, 25, 30] then Continue;

          DrawObject(fLayers[rlObjectsLow], Obj, ORec.Meta.PreviewFrameIndex);
        end;

      with fLayers[rlObjectsHigh] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          if Obj.DrawingFlags and odf_NoOverwrite <> 0 then Continue;
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect in [7, 8, 13, 16, 19, 25, 30] then Continue;

          DrawObject(fLayers[rlObjectsHigh], Obj, ORec.Meta.PreviewFrameIndex);
        end;

      with fLayers[rlLemmings] do
        for i := 0 to Level.InteractiveObjects.Count-1 do
        begin
          Obj := Level.InteractiveObjects[i];
          ORec := FindMetaObject(Obj);
          if ORec.Meta.TriggerEffect <> 13 then Continue;

          if Obj.TarLev and 64 = 0 then
            DrawLemming(fLayers[rlLemmings], Obj)
          else
            DrawLemming(fLayers[rlLemmings], Obj, true);
        end;
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
  fLayers.CombineTo(World);

  {with Inf do
  begin

    // mtn := Level.Terrains.HackedList.Count - 1;

    with Level.Terrains.HackedList do
      for i := 0 to Level.Terrains.HackedList.Count - 1 do
      begin
        Ter := List^[i];
        if (((SOX = false) or ((Ter.DrawingFlags and tdf_Erase) <> 0))
        or ((FindMetaTerrain(Ter).Meta.Unknown and $01) <> 0)) then
          DrawTerrain(World, Ter, SteelOnly);
      end;


    // Find the one way objects
    (*GS := FindGraphicSet(Inf.Level.Info.GraphicSetName);
    with GS.MetaObjects.HackedList do
    begin
      OWL := -1;
      OWR := -1;
      OWD := -1;
      for i := 0 to Count-1 do
      begin
        MO := List^[i];
        if MO.TriggerEffect = 7 then OWL := i;
        if MO.TriggerEffect = 8 then OWR := i;
        if MO.TriggerEffect = 19 then OWD := i;
      end;
    end;


    with Level.Steels.HackedList do
    begin
      for i := 0 to Count-1 do
      begin
        Stl := List^[i];
        DoOww := -1;
        case Stl.fType of
          2: if OWL <> -1 then
               DoOWW := OWL
             else
               Stl.fType := 5;
          3: if OWR <> -1 then
               DoOWW := OWR
             else
               Stl.fType := 5;
          4: if OWD <> -1 then
               DoOWW := OWD
             else
               Stl.fType := 5;
        end;
        if DoOWW <> -1 then
        begin
          Bmp := GS.ObjectBitmaps[DoOWW];
          for x := Stl.Left to (Stl.Left + Stl.Width - 1) do
            for y := Stl.Top to (Stl.Top + Stl.Height - 1) do
            begin
              if (x mod GS.MetaObjects[DoOWW].TriggerWidth < Bmp.Width)
              and (y mod GS.MetaObjects[DoOWW].TriggerHeight < Bmp.Height)
              and ((World[x, y] and ALPHA_ONEWAY) <> 0)
              and ((Bmp[x mod GS.MetaObjects[DoOWW].TriggerWidth, y mod GS.MetaObjects[DoOWW].TriggerHeight] and $FFFFFF) <> 0) then
                World[x, y] := (Bmp[x mod GS.MetaObjects[DoOWW].TriggerWidth, y mod GS.MetaObjects[DoOWW].TriggerHeight] and $FFFFFF) or (World[x, y] and $FF000000);
            end;
        end;

      end;
    end;*)
    // This code removed for now due to incompatibility with new graphic set handling


    if DoObjects then
    with Level.InteractiveObjects.HackedList do
    begin

      TZ := Level.Info.GimmickSet and $4000000 <> 0;

      for i := 0 to Count - 1 do
      begin
        Obj := List^[i];
        MO := FindMetaObject(Obj).Meta;
        if (Obj.DrawingFlags and odf_Invisible <> 0) or (MO.TriggerEffect in [13, 16]) then Continue;
        fi := MO.PreviewFrameIndex;
        if MO.TriggerEffect in [7, 8, 19] then
        begin
          Obj.DrawingFlags := Obj.DrawingFlags and not odf_NoOverwrite;
          Obj.DrawingFlags := Obj.DrawingFlags or odf_OnlyOnTerrain;
        end;
        if MO.TriggerEffect in [15, 17] then
          fi := 1;
        if (MO.TriggerEffect = 21) and (Obj.DrawingFlags and 8 <> 0) then fi := 1;
        if (MO.TriggerEffect = 14) then fi := Obj.Skill + 1;
        if (odf_OnlyOnTerrain and Obj.DrawingFlags <> 0) then DrawObject(World, Obj, fi);
      end;

      for i := 0 to Count - 1 do
      begin
        Obj := List^[i];
        MO := FindMetaObject(Obj).Meta;
        if (Obj.DrawingFlags and odf_Invisible <> 0) or (MO.TriggerEffect in [13, 16]) then Continue;
        fi := MO.PreviewFrameIndex;
        if MO.TriggerEffect in [15, 17] then
          fi := 1;
        if (MO.TriggerEffect = 21) and (Obj.DrawingFlags and 8 <> 0) then fi := 1;
        if (MO.TriggerEffect = 14) then fi := Obj.Skill + 1;
        if (odf_OnlyOnTerrain and Obj.DrawingFlags = 0) then DrawObject(World, Obj, fi);
      end;

      for i := 0 to Count - 1 do
      begin
        Obj := List^[i];
        MO := FindMetaObject(Obj).Meta;

        if MO.TriggerEffect = 13 then
        begin
          if (not TZ) or (Obj.TarLev and 64 = 0) then
            DrawLemming(World, Obj)
            else
            DrawLemming(World, Obj, true);
        end;
      end;

    end;
  end;}

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
    Pal[i] := fTheme.ParticleColors[i-8];

  if fAni <> nil then fAni.Free;
  fAni := TBaseDosAnimationSet.Create;
  fAni.ClearData;
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

