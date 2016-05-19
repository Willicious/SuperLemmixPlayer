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
  GR32, GR32_LowLevel,
  UMisc,
  SysUtils,
  LemRenderHelpers,
  LemDosBmp, LemDosStructures,
  LemTypes,
  LemTerrain,
  LemObjects, LemInteractiveObject,   LemMetaObject,
  LemSteel,
  LemDosAnimationSet,
  LemGraphicSet, LemNeoGraphicSet,
  LemLevel;

  // we could maybe use the alpha channel for rendering, ok thats working!
  // create gamerenderlist in order of rendering


type
  // temp solution
  TRenderInfoRec = record
//    World        : TBitmap32; // the actual bitmap
    TargetBitmap : TBitmap32; // the visual bitmap
    Level        : TLevel;
    (*GraphicSet   : TBaseGraphicSet;*)
  end;

  TRenderer = class
  private
    TempBitmap         : TBitmap32;
    Inf                : TRenderInfoRec;
    fXmasPal : Boolean;

    fGraphicSets: TNeoLemmixGraphicSets;

    fWorld: TBitmap32;

    fAni: TBaseDosAnimationSet;

    fBgColor : TColor32;

    procedure CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainDefaultNoOneWay(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwriteNoOneWay(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainDefaultSteel(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainNoOverwriteSteel(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineObjectNoOverwriteZombie(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemFrame(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemFrameZombie(F: TColor32; var B: TColor32; M: TColor32);

    procedure CombineSpecTerrainSteel(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineSpecTerrainOWW(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineSpecTerrainOWWInvert(F: TColor32; var B: TColor32; M: TColor32);

    procedure PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte; SteelOnly: Boolean = false; IsSteel: Boolean = false; IsNoOneWay: Boolean = false);
    procedure PrepareObjectBitmap(Bmp: TBitmap32; DrawingFlags: Byte; Zombie: Boolean = false);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    function FindMetaObject(O: TInteractiveObject): TMetaObject;
    function FindGraphicSet(aName: String): TBaseGraphicSet;

    procedure PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);

    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain; SteelOnly: Boolean = false);
    procedure DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer); Overload;
    procedure DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo); Overload;
    procedure DrawAllObjects(Dst: TBitmap32; ObjectInfos: TInteractiveObjectInfoList);

    procedure DrawObjectBottomLine(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer;
      aOriginal: TBitmap32 = nil);
    procedure DrawLemming(Dst: TBitmap32; O: TInteractiveObject; Z: Boolean = false);
    procedure EraseObject(Dst: TBitmap32; O: TInteractiveObject;
      aOriginal: TBitmap32 = nil);
    procedure DrawSpecialBitmap(Dst: TBitmap32; Spec: TBitmaps; Inv: Boolean = false);

    function HasPixelAt(X, Y: Integer): Boolean;


    procedure RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);

    procedure Highlight(World: TBitmap32; M: TColor32);

    property BackgroundColor: TColor32 read fBgColor write fBgColor;
  end;

const
  COLOR_MASK    = $80FFFFFF; // transparent black flag is included!
  ALPHA_MASK    = $FF000000;

  ALPHA_TERRAIN          = $01000000;
  ALPHA_OBJECT           = $02000000; // not really needed, but used
  ALPHA_STEEL            = $04000000;
  ALPHA_ONEWAY           = $08000000;

  // to enable black terrain. bitmaps with transparent black should include
  // this bit
  ALPHA_TRANSPARENTBLACK = $80000000;

implementation

uses
  UTools;



{ TRenderer }

function TRenderer.FindMetaObject(O: TInteractiveObject): TMetaObject;
var
  GS: TBaseGraphicSet;
begin
  GS := FindGraphicSet(O.GS);
  Result := GS.MetaObjects[StrToIntDef(O.Piece, 0)];
end;

function TRenderer.FindGraphicSet(aName: String): TBaseGraphicSet;
var
  i: Integer;
  GS: TBaseNeoGraphicSet;

  MO: TMetaObject;
  Bmp: TBitmap32;
  Item: TObjectAnimation;
begin
  for i := 0 to fGraphicSets.Count-1 do
    if Lowercase(aName) = Lowercase(fGraphicSets[i].GraphicSetName) then
    begin
      Result := fGraphicSets[i];
      Exit;
    end;

  GS := fGraphicSets.Add;
  GS.GraphicSetName := aName;
  GS.OnlineEnabled := true; // until we have a way to pass to here whether it is or not, just always set it to true
  GS.GraphicSetFile := aName + '.dat';
  GS.ReadMetaData;
  GS.ReadData;

    with GS do
    for i := 0 to ObjectBitmaps.Count - 1 do
    begin
      MO := MetaObjects[i];
      Bmp := ObjectBitmaps.List^[i];

      Item := TObjectAnimation.Create(Bmp, MO.AnimationFrameCount, MO.Width, MO.Height);
      ObjectRenderList.Add(Item);

    end;

  Result := GS;
end;

procedure TRenderer.CombineTerrainDefault(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    //B := F ;
    B := B and not COLOR_MASK; // erase color
    B := B and not ALPHA_STEEL;
    B := B or ALPHA_TERRAIN or ALPHA_ONEWAY; // put terrain bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineSpecTerrainSteel(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $FF000000) <> 0 then
    B := B or ALPHA_STEEL;
end;

procedure TRenderer.CombineSpecTerrainOWW(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $FF000000) <> 0 then
    B := B or ALPHA_ONEWAY;
end;

procedure TRenderer.CombineSpecTerrainOWWInvert(F: TColor32; var B: TColor32; M: TColor32);
begin
  if ((F and $FF000000) = 0) and ((B and ALPHA_TERRAIN) <> 0) then
    B := B or ALPHA_ONEWAY;
end;

procedure TRenderer.CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_TERRAIN = 0) then
  begin
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_TERRAIN or ALPHA_ONEWAY; // put terrain bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineTerrainDefaultNoOneWay(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    //B := F ;
    B := B and not COLOR_MASK; // erase color
    B := B and not ALPHA_STEEL;
    B := B or ALPHA_TERRAIN; // put terrain bit
    B := B or (F and COLOR_MASK); // copy color
    B := B and not ALPHA_ONEWAY;
  end;
end;

procedure TRenderer.CombineTerrainNoOverwriteNoOneWay(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_TERRAIN = 0) then
  begin
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_TERRAIN; // put terrain bit
    B := B or (F and COLOR_MASK); // copy color
    B := B and not ALPHA_ONEWAY;
  end;
end;

procedure TRenderer.CombineTerrainDefaultSteel(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    //B := F ;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_TERRAIN or ALPHA_STEEL; // put terrain bit
    B := B or (F and COLOR_MASK); // copy color
    B := B and not ALPHA_ONEWAY;
  end;
end;

procedure TRenderer.CombineTerrainNoOverwriteSteel(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_TERRAIN = 0) then
  begin
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_TERRAIN or ALPHA_STEEL; // put terrain bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;


procedure TRenderer.CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
    B := fBgColor;
end;

procedure TRenderer.CombineObjectDefault(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_OBJECT; // put object bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineObjectNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_MASK = 0) then
  begin
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_OBJECT; // put object bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineObjectDefaultZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then
  begin

    if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_OBJECT; // put object bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineObjectNoOverwriteZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_MASK = 0) then
  begin

    if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := ((((F shr 16) mod 256) div 2) shl 16) + ((((F shr 8) mod 256) div 3 * 2) shl 8) + ((F mod 256) div 2);
    
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_OBJECT; // put object bit
    B := B or (F and COLOR_MASK) // copy color
  end;
end;

procedure TRenderer.CombineObjectOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F <> 0) and (B and ALPHA_TERRAIN <> 0) and (B and ALPHA_ONEWAY <> 0) then
  begin
    //B := F;
    B := B and not COLOR_MASK; // erase color
    B := B or ALPHA_OBJECT; // put object bit
    B := B or (F and COLOR_MASK) // copy color
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
  end
  else if DrawingFlags and odf_NoOverwrite <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
    if Zombie then
      Bmp.OnPixelCombine := CombineObjectNoOverwriteZombie
    else
      Bmp.OnPixelCombine := CombineObjectNoOverwrite;
  end
  else
  begin
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
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  PieceID := StrToIntDef(T.Piece, 0);
  GS := FindGraphicSet(T.GS);
  Src := GS.TerrainBitmaps.List^[PieceID];
  UDf := T.DrawingFlags;
  IsSteel := ((GS.MetaTerrains[PieceID].Unknown and $01) = 1);
  IsNoOneWay := (UDf and tdf_NoOneWay <> 0);
  if (T.DrawingFlags and tdf_Invert = 0) and (T.DrawingFlags and tdf_Flip = 0) and (T.DrawingFlags and tdf_Rotate = 0) then
  begin
    PrepareTerrainBitmap(Src, UDf, SteelOnly, IsSteel, IsNoOneWay);
    Src.DrawTo(Dst, T.Left, T.Top);
  end
  else
  begin
    TempBitmap.Assign(Src);
    if (T.DrawingFlags and tdf_Rotate <> 0) then TempBitmap.Rotate90;
    if (T.DrawingFlags and tdf_Invert <> 0) then TempBitmap.FlipVert;
    if (T.DrawingFlags and tdf_Flip <> 0) then TempBitmap.FlipHorz;
    PrepareTerrainBitmap(TempBitmap, UDf, SteelOnly, IsSteel, IsNoOneWay);
    TempBitmap.DrawTo(Dst, T.Left, T.Top);
  end;
end;

procedure TRenderer.PrepareTerrainBitmap(Bmp: TBitmap32; DrawingFlags: Byte; SteelOnly: Boolean = false; IsSteel: Boolean = false; IsNoOneWay: Boolean = false);
begin
  if DrawingFlags and tdf_NoOverwrite <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainNoOverwrite;
    if IsNoOneWay then Bmp.OnPixelCombine := CombineTerrainNoOverwriteNoOneWay;
    if IsSteel then Bmp.OnPixelCombine := CombineTerrainNoOverwriteSteel;
  end
  else if DrawingFlags and tdf_Erase <> 0 then
  begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainErase;
  end
  else begin
    Bmp.DrawMode := dmCustom;
    Bmp.OnPixelCombine := CombineTerrainDefault;
    if IsNoOneWay then Bmp.OnPixelCombine := CombineTerrainDefaultNoOneWay;
    if IsSteel then Bmp.OnPixelCombine := CombineTerrainDefaultSteel;
  end;
end;

procedure TRenderer.DrawSpecialBitmap(Dst: TBitmap32; Spec: TBitmaps; Inv: Boolean = false);
begin
  Spec[0].DrawMode := dmCustom;
  Spec[0].OnPixelCombine := CombineTerrainDefaultNoOneWay;
  Spec[0].DrawTo(Dst, Inf.Level.Info.VgaspecX, Inf.Level.Info.VgaspecY);
  if Spec.Count = 1 then exit;

  Spec[1].DrawMode := dmCustom;
  Spec[1].OnPixelCombine := CombineSpecTerrainSteel;
  Spec[1].DrawTo(Dst, Inf.Level.Info.VgaspecX, Inf.Level.Info.VgaspecY);
  if Spec.Count = 2 then exit;

  Spec[2].DrawMode := dmCustom;
  if Inv then
    Spec[2].OnPixelCombine := CombineSpecTerrainOWWInvert
  else
    Spec[2].OnPixelCombine := CombineSpecTerrainOWW;
  Spec[2].DrawTo(Dst, Inf.Level.Info.VgaspecX, Inf.Level.Info.VgaspecY);
end;

procedure TRenderer.DrawObjectBottomLine(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer; aOriginal: TBitmap32 = nil);
var
  SrcRect, DstRect, R: TRect;
  Item: TObjectAnimation;// TDrawItem;
  Src: TBitmap32;
  MO: TMetaObject;
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  PieceID := StrToIntDef(O.Piece, 0);
  GS := FindGraphicSet(O.GS);
  Assert(GS.ObjectRenderList[PieceID] is TObjectAnimation);
  Item := TObjectAnimation(GS.ObjectRenderList[PieceID]);
  MO := GS.MetaObjects[PieceID];
  //ObjectBitmapItems.List^[O.Identifier];

  if aFrame > MO.AnimationFrameCount-1 then aFrame := MO.AnimationFrameCount-1; // just in case

  if O.DrawingFlags and odf_Invisible <> 0 then Exit;

  Src := TBitmap32.Create;

  if odf_UpsideDown and O.DrawingFlags = 0
  then Src.Assign(Item.Original)
  else Src.Assign(Item.Inverted);

  if odf_Flip and O.DrawingFlags <> 0
  then Src.FlipHorz;

  if MO.TriggerEffect in [7, 8, 19] then
  begin
    O.DrawingFlags := O.DrawingFlags and not odf_NoOverwrite;
    O.DrawingFlags := O.DrawingFlags or odf_OnlyOnTerrain;
  end;

  PrepareObjectBitmap(Src, O.DrawingFlags);

  SrcRect := Item.CalcFrameRect(aFrame);
  DstRect := SrcRect;
  DstRect := ZeroTopLeftRect(DstRect);
  OffsetRect(DstRect, O.Left, O.Top);

  SrcRect.Top := SrcRect.Bottom - 1;
  DstRect.Top := DstRect.Bottom - 1;

  if aOriginal <> nil then
  begin
    IntersectRect(R, DstRect, aOriginal.BoundsRect); // oops important!
    aOriginal.DrawTo(Dst, R, R);
  end;
  Src.DrawTo(Dst, DstRect, SrcRect);
  Src.Free;
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
  Item: TObjectAnimation;// TDrawItem;
  Src: TBitmap32;
  MO: TMetaObject;
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  PieceID := StrToIntDef(O.Piece, 0);
  GS := FindGraphicSet(O.GS);
  Assert(GS.ObjectRenderList[PieceID] is TObjectAnimation);
  Item := TObjectAnimation(GS.ObjectRenderList[PieceID]);
  MO := GS.MetaObjects[PieceID];
  //ObjectBitmapItems.List^[O.Identifier];

  if O.DrawingFlags and odf_Invisible <> 0 then Exit;
  if MO.TriggerEffect = 25 then Exit;

  if aFrame > MO.AnimationFrameCount-1 then aFrame := MO.AnimationFrameCount-1; // for this one, it actually can matter sometimes

  Src := TBitmap32.Create;

  if odf_UpsideDown and O.DrawingFlags = 0
  then Src.Assign(Item.Original)
  else Src.Assign(Item.Inverted);

  if odf_Flip and O.DrawingFlags <> 0
  then Src.FlipHorz;

  if MO.TriggerEffect in [7, 8, 19] then
  begin
    O.DrawingFlags := O.DrawingFlags and not odf_NoOverwrite;
    O.DrawingFlags := O.DrawingFlags or odf_OnlyOnTerrain;
  end;

  PrepareObjectBitmap(Src, O.DrawingFlags, O.DrawAsZombie);

  SrcRect := Item.CalcFrameRect(aFrame);
  DstRect := SrcRect;
  DstRect := ZeroTopLeftRect(DstRect);
  OffsetRect(DstRect, O.Left, O.Top);

  Src.DrawTo(Dst, DstRect, SrcRect);
  Src.Free;

  O.LastDrawX := O.Left;
  O.LastDrawY := O.Top;
end;

procedure TRenderer.DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo);
var
  SrcRect, DstRect, R: TRect;
  Item: TObjectAnimation;
  Src: TBitmap32;
  DrawFrame: Integer;
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  GS := FindGraphicSet(Gadget.Obj.GS);
  PieceID := StrToIntDef(Gadget.Obj.Piece, 0);
  Assert(GS.ObjectRenderList[PieceID] is TObjectAnimation);
  Item := TObjectAnimation(GS.ObjectRenderList[PieceID]);

  if Gadget.IsInvisible then Exit;
  if Gadget.TriggerEffect = DOM_HINT then Exit;

  DrawFrame := MinIntValue([Gadget.CurrentFrame, Gadget.AnimationFrameCount - 1]);

  Src := TBitmap32.Create;

  if Gadget.IsUpsideDown then Src.Assign(Item.Inverted)
  else Src.Assign(Item.Original);

  if Gadget.IsFlipImage then Src.FlipHorz;   

  PrepareObjectBitmap(Src, Gadget.Obj.DrawingFlags, Gadget.ZombieMode);

  SrcRect := Item.CalcFrameRect(DrawFrame);
  DstRect := ZeroTopLeftRect(SrcRect);
  OffsetRect(DstRect, Gadget.Left, Gadget.Top);

  Src.DrawTo(Dst, DstRect, SrcRect);
  Src.Free;

  Gadget.Obj.LastDrawX := Gadget.Left;
  Gadget.Obj.LastDrawY := Gadget.Top;
end;

procedure TRenderer.DrawAllObjects(Dst: TBitmap32; ObjectInfos: TInteractiveObjectInfoList);
var
  SrcRect, DstRect: TRect;
  Inf: TInteractiveObjectInfo;
  Item: TObjectAnimation;
  Src: TBitmap32;
  DrawFrame, i: Integer;
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  Src := TBitmap32.Create;

  for i := 0 to ObjectInfos.Count - 1 do
  begin
    Inf := ObjectInfos[i];
    if Inf.TriggerEffect <> DOM_LEMMING then
    begin
      GS := FindGraphicSet(Inf.Obj.GS);
      PieceID := StrToIntDef(Inf.Obj.Piece, 0);
      Assert(GS.ObjectRenderList[PieceID] is TObjectAnimation);
      Item := TObjectAnimation(GS.ObjectRenderList[PieceID]);

      if Inf.IsInvisible then Continue;
      if Inf.TriggerEffect = DOM_HINT then Continue;

      DrawFrame := MinIntValue([Inf.CurrentFrame, Inf.AnimationFrameCount - 1]);

      if Inf.IsUpsideDown then Src.Assign(Item.Inverted)
      else Src.Assign(Item.Original);

      if Inf.IsFlipImage then Src.FlipHorz;

      PrepareObjectBitmap(Src, Inf.Obj.DrawingFlags, Inf.ZombieMode);

      SrcRect := Item.CalcFrameRect(DrawFrame);
      DstRect := ZeroTopLeftRect(SrcRect);
      OffsetRect(DstRect, Inf.Left, Inf.Top);

      Src.DrawTo(Dst, DstRect, SrcRect);

      Inf.Obj.LastDrawX := Inf.Left;
      Inf.Obj.LastDrawY := Inf.Top;
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
  GS: TBaseGraphicSet;
begin
  GS := FindGraphicSet(O.GS);
  if O.IsFake then exit;
  tx := O.Left;
  ty := O.Top;
  MO := GS.MetaObjects[StrToIntDef(O.Piece, 0)];
  tx := tx + MO.TriggerLeft;
  ty := ty + MO.TriggerTop;

  if Inf.Level.Info.GimmickSet and 64 = 0 then
  begin
  if O.TarLev and 32 <> 0 then
  begin
    while (ty <= Inf.Level.Info.Height-1) and (Dst.Pixel[tx, ty] and ALPHA_TERRAIN = 0) do
      inc(ty);
  end else begin
    dy := 0;
    while (dy < 3) and (ty + dy < Inf.Level.Info.Height) do
    begin
      if Dst.Pixel[tx, ty + dy] and ALPHA_TERRAIN <> 0 then
      begin
        ty := ty + dy;
        break;
      end;
      inc(dy);
    end;
  end;
  end;

  if ((ty > Inf.Level.Info.Height-1) or (Dst.Pixel[tx, ty] and ALPHA_TERRAIN = 0)) and (Inf.Level.Info.GimmickSet and 64 = 0) then
    a := FALLING
  else if O.TarLev and 32 <> 0 then
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
  Item: TObjectAnimation;// TDrawItem;
  //Src: TBitmap32;
  PieceID: Integer;
  GS: TBaseGraphicSet;
begin
  if aOriginal = nil then
    Exit;

  PieceID := StrToIntDef(O.Piece, 0);
  GS := FindGraphicSet(O.GS);
  Assert(GS.ObjectRenderList[PieceID] is TObjectAnimation);
  Item := TObjectAnimation(GS.ObjectRenderList[PieceID]);
  //ObjectBitmapItems.List^[O.Identifier];

  SrcRect := Item.CalcFrameRect(0);
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
  fGraphicSets := TNeoLemmixGraphicSets.Create(true);
  //fAni := TBaseDosAnimationSet.Create;
  fBgColor := $00000000;
end;

destructor TRenderer.Destroy;
begin
  TempBitmap.Free;
  fGraphicSets.Free;
  if fAni <> nil then fAni.Free;
  inherited Destroy;
end;

procedure TRenderer.RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);
// DoObjects is only true if RenderWorld is called from the Preview Screen!
var
  i: Integer;
  Ter: TTerrain;
  Bmp: TBitmap32;
  Obj: TInteractiveObject;
  MO: TMetaObject;
  Stl: TSteel;
  fi: Integer;
  mtn: Integer;
  TZ: Boolean;
  OWL, OWR, OWD, DoOWW: Integer;
  x, y: Integer;
  GS: TBaseGraphicSet;
begin
  World.Clear(fBgColor);

  GS := FindGraphicSet(Inf.Level.Info.GraphicSetName);

  if Inf.Level = nil then Exit;
  //if Inf.GraphicSet = nil then Exit;

  with Inf do
  begin

    if GS.GraphicSetIdExt > 0 then
    begin
      //Bmp := Inf.GraphicSet.SpecialBitmaps[0];
      DrawSpecialBitmap(World, GS.SpecialBitmaps, (Inf.Level.Info.LevelOptions and $80 = 0));
    end;

    // mtn := Level.Terrains.HackedList.Count - 1;

    with Level.Terrains.HackedList do
      for i := 0 to Level.Terrains.HackedList.Count - 1 do
      begin
        Ter := List^[i];
        GS := FindGraphicSet(Ter.GS);
        if (((SOX = false) or ((Ter.DrawingFlags and tdf_Erase) <> 0))
        or ((GS.MetaTerrains[StrToIntDef(Ter.Piece, 0)].Unknown and $01) <> 0)) then
          DrawTerrain(World, Ter, SteelOnly);
      end;


    // Find the one way objects
    GS := FindGraphicSet(Inf.Level.Info.GraphicSetName);
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
    end;


    if DoObjects then
    with Level.InteractiveObjects.HackedList do
    begin

      TZ := Level.Info.GimmickSet and $4000000 <> 0;

      for i := 0 to Count - 1 do
      begin
        Obj := List^[i];
        GS := FindGraphicSet(Obj.GS);
        MO := GS.MetaObjects[StrToIntDef(obj.Piece, 0)];
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
        GS := FindGraphicSet(Obj.GS);
        MO := GS.MetaObjects[StrToIntDef(obj.Piece, 0)];
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
        GS := FindGraphicSet(Obj.GS);
        MO := GS.MetaObjects[StrToIntDef(Obj.Piece, 0)];

        if MO.TriggerEffect = 13 then
        begin
          if (not TZ) or (Obj.TarLev and 64 = 0) then
            DrawLemming(World, Obj)
            else
            DrawLemming(World, Obj, true);
        end;
      end;

    end;
  end;
end;

procedure TRenderer.PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);
var
  i: Integer;
  Item: TObjectAnimation;
  Bmp: TBitmap32;
  MO: TMetaObject;
  LowPal, {HiPal,} Pal: TArrayOfColor32;
  GS: TBaseGraphicSet;
//  R: TRect;
begin

  Inf := Info;

  // create cache to draw from

  GS := FindGraphicSet(Inf.Level.Info.GraphicSetName);

  fXmasPal := XmasPal;

  LowPal := DosPaletteToArrayOfColor32(DosInLevelPalette);
  if fXmasPal then
  begin
    LowPal[1] := $D02020;
    LowPal[4] := $F0F000;
    LowPal[5] := $4040E0;
  end;
  //LowPal[7] := Graph.BrickColor; // copy the brickcolor
  SetLength(Pal, 16);
  for i := 0 to 7 do
    Pal[i] := LowPal[i];
  for i := 8 to 15 do
    Pal[i] := 0;

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
  Result := fWorld.PixelS[X, Y] and ALPHA_TERRAIN = 0;
end;

end.

