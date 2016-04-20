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
  LemDosBmp, LemDosStructures,
  LemTypes,
  LemTerrain,
  LemObjects, LemInteractiveObject,   LemMetaObject,
  LemSteel,
  LemDosAnimationSet,
  LemGraphicSet,
  LemLevel;

  // we could maybe use the alpha channel for rendering, ok thats working!
  // create gamerenderlist in order of rendering

type
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


type
  // temp solution
  TRenderInfoRec = record
//    World        : TBitmap32; // the actual bitmap
    TargetBitmap : TBitmap32; // the visual bitmap
    Level        : TLevel;
    GraphicSet   : TBaseGraphicSet;
  end;

  TRenderer = class
  private
    TempBitmap         : TBitmap32;
    ObjectRenderList   : TDrawList; // list to accelerate object drawing
    Inf                : TRenderInfoRec;
    fXmasPal : Boolean;

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

    procedure PrepareGameRendering(const Info: TRenderInfoRec; XmasPal: Boolean = false);

    procedure DrawTerrain(Dst: TBitmap32; T: TTerrain; SteelOnly: Boolean = false);
    procedure DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer;
      aOriginal: TBitmap32 = nil); Overload;
    procedure DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo; aOriginal: TBitmap32 = nil); Overload;
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

{ TRenderer }

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
  else begin
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
begin
  Src := Inf.GraphicSet.TerrainBitmaps.List^[T.Identifier];
  UDf := T.DrawingFlags;
  IsSteel := ((Inf.GraphicSet.MetaTerrains[T.Identifier].Unknown and $01) = 1);
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
begin
  Assert(ObjectRenderList[O.Identifier] is TObjectAnimation);
  Item := TObjectAnimation(ObjectRenderList[O.Identifier]);
  MO := Inf.GraphicSet.MetaObjects[o.identifier];
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

procedure TRenderer.DrawObject(Dst: TBitmap32; O: TInteractiveObject; aFrame: Integer; aOriginal: TBitmap32 = nil);
{-------------------------------------------------------------------------------
  Draws a interactive object
  • Dst = the targetbitmap
  • O = the object
  • aOriginal = if specified then first a part of this bitmap (world when playing)
    is copied to Dst to restore
-------------------------------------------------------------------------------}
var
  SrcRect, DstRect, R: TRect;
  Item: TObjectAnimation;// TDrawItem;
  Src: TBitmap32;
  MO: TMetaObject;
begin
  Assert(ObjectRenderList[O.Identifier] is TObjectAnimation);
  Item := TObjectAnimation(ObjectRenderList[O.Identifier]);
  MO := Inf.GraphicSet.MetaObjects[o.identifier];
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

  if aOriginal <> nil then
  begin
    IntersectRect(R, DstRect, aOriginal.BoundsRect); // oops important!
    aOriginal.DrawTo(Dst, R, R);
  end;
  Src.DrawTo(Dst, DstRect, SrcRect);
  Src.Free;

  O.LastDrawX := O.Left;
  O.LastDrawY := O.Top;
end;

procedure TRenderer.DrawObject(Dst: TBitmap32; Gadget: TInteractiveObjectInfo; aOriginal: TBitmap32 = nil);
var
  SrcRect, DstRect, R: TRect;
  Item: TObjectAnimation;
  Src: TBitmap32;
  DrawFrame: Integer;
begin
  Assert(ObjectRenderList[Gadget.Obj.Identifier] is TObjectAnimation);
  Item := TObjectAnimation(ObjectRenderList[Gadget.Obj.Identifier]);

  if Gadget.IsInvisible then Exit;
  if Gadget.TriggerEffect = DOM_HINT then Exit;

  DrawFrame := MinIntValue([Gadget.CurrentFrame, Gadget.AnimationFrameCount - 1]);

  Src := TBitmap32.Create;

  if Gadget.IsUpsideDown then Src.Assign(Item.Inverted)
  else Src.Assign(Item.Original);

  if Gadget.IsFlipImage then Src.FlipHorz;   

  PrepareObjectBitmap(Src, Gadget.Obj.DrawingFlags, Gadget.ZombieMode);

  SrcRect := Item.CalcFrameRect(DrawFrame);
  // DstRect := SrcRect;
  DstRect := ZeroTopLeftRect(SrcRect);
  OffsetRect(DstRect, Gadget.Left, Gadget.Top);

  if aOriginal <> nil then
  begin
    IntersectRect(R, DstRect, aOriginal.BoundsRect); // oops important!
    aOriginal.DrawTo(Dst, R, R);
  end;
  Src.DrawTo(Dst, DstRect, SrcRect);
  Src.Free;

  Gadget.Obj.LastDrawX := Gadget.Left;
  Gadget.Obj.LastDrawY := Gadget.Top;
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
  MO := Inf.GraphicSet.MetaObjects[o.identifier];
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
begin
  if aOriginal = nil then
    Exit;

  Assert(ObjectRenderList[O.Identifier] is TObjectAnimation);
  Item := TObjectAnimation(ObjectRenderList[O.Identifier]);
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
  ObjectRenderList := TDrawList.Create;
  //fAni := TBaseDosAnimationSet.Create;
  fBgColor := $00000000;
end;

destructor TRenderer.Destroy;
begin
  TempBitmap.Free;
  ObjectRenderList.Free;
  if fAni <> nil then fAni.Free;
  inherited Destroy;
end;

procedure TRenderer.RenderWorld(World: TBitmap32; DoObjects: Boolean; SteelOnly: Boolean = false; SOX: Boolean = false);
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
begin
  World.Clear(fBgColor);

  if Inf.level=nil then exit;
  if Inf.graphicset=nil then exit;

  with Inf do
  begin

    if Inf.GraphicSet.GraphicSetIdExt > 0 then
    begin
      //Bmp := Inf.GraphicSet.SpecialBitmaps[0];
      DrawSpecialBitmap(World, Inf.GraphicSet.SpecialBitmaps, (Inf.Level.Info.LevelOptions and $80 = 0));
    end;

    mtn := Level.Terrains.HackedList.Count - 1;

    with Level.Terrains.HackedList do
      for i := 0 to mtn do
      begin
        Ter := List^[i];
        if (((SOX = false) or ((Ter.DrawingFlags and tdf_Erase) <> 0))
        or ((Inf.GraphicSet.MetaTerrains[Ter.Identifier].Unknown and $01) <> 0)) then
          DrawTerrain(World, Ter, SteelOnly);
      end;


    // Find the one way objects
    with Inf.GraphicSet.MetaObjects.HackedList do
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
          Bmp := GraphicSet.ObjectBitmaps[DoOWW];
          for x := Stl.Left to (Stl.Left + Stl.Width - 1) do
            for y := Stl.Top to (Stl.Top + Stl.Height - 1) do
            begin
              if (x mod GraphicSet.MetaObjects[DoOWW].TriggerWidth < Bmp.Width)
              and (y mod GraphicSet.MetaObjects[DoOWW].TriggerHeight < Bmp.Height)
              and ((World[x, y] and ALPHA_ONEWAY) <> 0)
              and ((Bmp[x mod GraphicSet.MetaObjects[DoOWW].TriggerWidth, y mod GraphicSet.MetaObjects[DoOWW].TriggerHeight] and $FFFFFF) <> 0) then
                World[x, y] := (Bmp[x mod GraphicSet.MetaObjects[DoOWW].TriggerWidth, y mod GraphicSet.MetaObjects[DoOWW].TriggerHeight] and $FFFFFF) or (World[x, y] and $FF000000);
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
        MO := Inf.GraphicSet.MetaObjects[obj.identifier];
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
        MO := Inf.GraphicSet.MetaObjects[obj.identifier];
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
        MO := Inf.GraphicSet.MetaObjects[obj.identifier];

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
//  R: TRect;
begin

  Inf := Info;

  // create cache to draw from
  ObjectRenderList.Clear;

  with Inf, GraphicSet do
    for i := 0 to ObjectBitmaps.Count - 1 do
    begin
      MO := MetaObjects[i];
      Bmp := ObjectBitmaps.List^[i];

      Item := TObjectAnimation.Create(Bmp, MO.AnimationFrameCount, MO.Width, MO.Height);
      ObjectRenderList.Add(Item);

    end;

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

