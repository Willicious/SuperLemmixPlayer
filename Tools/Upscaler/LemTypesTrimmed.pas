unit LemTypesTrimmed;

interface

uses
  Generics.Collections,
  Dialogs,
  Classes, SysUtils, Contnrs,
  Math,
  GR32, GR32_LowLevel, GR32_Blend, GR32_Resamplers,
  Windows;

type
  TUpscaleMode = (umNearest, umPixelArt, umFullColor);
  TUpscaleEdgeBehaviour = (uebRepeat, uebMirror, uebTransparent);

  TUpscaleSettings = record
    Mode: TUpscaleMode;
    LeftSide: TUpscaleEdgeBehaviour;
    TopSide: TUpscaleEdgeBehaviour;
    RightSide: TUpscaleEdgeBehaviour;
    BottomSide: TUpscaleEdgeBehaviour;
  end;

  TBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmap32;
  protected
  public
    function Add(Item: TBitmap32): Integer;
    procedure Insert(Index: Integer; Item: TBitmap32);
    procedure Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
    property Items[Index: Integer]: TBitmap32 read GetItem; default;
    property List;
  end;

procedure UpscaleFrames(Src: TBitmap32; FramesHorz, FramesVert: Integer; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);
procedure Upscale(Src: TBitmap32; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);


implementation

procedure UpscaleFrames(Src: TBitmap32; FramesHorz, FramesVert: Integer; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);
var
  TempBMP, LocalDst: TBitmap32;
  iX, iY: Integer;
  FW, FH: Integer;
  OldMode: TDrawMode;
begin
  if Dst = nil then
  begin
    LocalDst := TBitmap32.Create;
    Dst := LocalDst;
  end else
    LocalDst := nil;

  TempBMP := TBitmap32.Create;
  OldMode := Src.DrawMode;

  try
    FW := Src.Width div FramesHorz;
    FH := Src.Height div FramesVert;
    Src.DrawMode := dmOpaque;

    Dst.SetSize(FramesHorz * FW * 2, FramesVert * FH * 2);

    for iY := 0 to FramesVert-1 do
      for iX := 0 to FramesHorz-1 do
      begin
        TempBMP.SetSize(FW, FH);
        Src.DrawTo(TempBMP, 0, 0, Rect(iX * FW, iY * FH, (iX + 1) * FW, (iY + 1) * FH));
        Upscale(TempBMP, Settings);
        TempBMP.DrawTo(Dst, iX * FW * 2, iY * FH * 2);
      end;

    if LocalDst <> nil then
    begin
      Src.SetSize(LocalDst.Width, LocalDst.Height);
      LocalDst.DrawTo(Src);
    end;
  finally
    TempBMP.Free;
    Src.DrawMode := OldMode;
    if LocalDst <> nil then
      LocalDst.Free;
  end;
end;

procedure Upscale(Src: TBitmap32; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);
var
  OrigSrc: TBitmap32;
  OldDrawMode: TDrawMode;

  procedure UpscalePixelArt;
  var
    ResBMP: TBitmap32;

    function IsTransparentInSrc(x, y: Integer): Boolean;
    begin
      Result := (Src.PixelS[x, y] and $FF000000) = 0;
    end;

    procedure MakeResBMP;
    var
      x, y: Integer;
      cX, cY: Integer;

      function MayBeTransparentDiagonal(x, y, dx, dy: Integer): Boolean;
      var
        TranspAdj: Integer;
      begin
        TranspAdj := 0;
        if IsTransparentInSrc(x + dx, y) then Inc(TranspAdj);
        if IsTransparentInSrc(x, y + dy) then Inc(TranspAdj);
        if IsTransparentInSrc(x + dx, y + dy) then Inc(TranspAdj);
        Result := TranspAdj >= 2;
      end;

      function MayBeTransparentAdjacent(x, y, dx, dy: Integer): Boolean;
      begin
        Result := false;

        dx := Min(1, Max(dx, -1));
        dy := Min(1, Max(dy, -1));

        if IsTransparentInSrc(x + dX, y + dY) then
          Result := true;

        if (not Result) then
          if IsTransparentInSrc(x + dX + dY, y + dY + dX) then
            if not (IsTransparentInSrc(x + dX * 2 + dY, y + dY * 2 + dX) and IsTransparentInSrc(x + dX * 3 + dY, y + dY * 3 + dX)) then
              Result := true;

        if (not Result) then
          if IsTransparentInSrc(x + dX - dY, y + dY - dX) then
            if not (IsTransparentInSrc(x + dX * 2 - dY, y + dY * 2 - dX) and IsTransparentInSrc(x + dX * 3 - dY, y + dY * 3 - dX)) then
              Result := true;
      end;

      function PickMostCommon(aFallback, aColorAdjA, aColorAdjB, aColorDiag: TColor32): TColor32;
      begin
        Result := aFallback;
        if (aColorAdjA = aFallback) or (aColorAdjB = aFallback) then Exit;
        if (aColorAdjA = aColorAdjB) or (aColorAdjA = aColorDiag) then Result := aColorAdjA;
        if (aColorAdjB = aColorDiag) then Result := aColorAdjB;
      end;
    begin
      ResBMP.SetSize(Src.Width * 3 + 2, Src.Height * 3 + 2);
      ResBMP.Clear(0);
      Src.OuterColor := $00000000;

      for y := -1 to Src.Height do
      begin
        cY := (y * 3) + 2;

        for x := -1 to Src.Width do
        begin
          cX := (x * 3) + 2;

          if not IsTransparentInSrc(x, y) then
          begin
            ResBMP.FillRectS(cX - 1, cY - 1, cX + 2, cY + 2, Src.PixelS[x, y]);
          end else begin
            ResBMP.PixelS[cX, cY] := Src.PixelS[x, y];

            if not MayBeTransparentAdjacent(x, y, -1,  0) then ResBMP.PixelS[cX - 1, cY] := Src.PixelS[x - 1, y];
            if not MayBeTransparentAdjacent(x, y,  1,  0) then ResBMP.PixelS[cX + 1, cY] := Src.PixelS[x + 1, y];
            if not MayBeTransparentAdjacent(x, y,  0, -1) then ResBMP.PixelS[cX, cY - 1] := Src.PixelS[x, y - 1];
            if not MayBeTransparentAdjacent(x, y,  0,  1) then ResBMP.PixelS[cX, cY + 1] := Src.PixelS[x, y + 1];

            if not MayBeTransparentDiagonal(x, y, -1, -1) then ResBMP.PixelS[cX - 1, cY - 1] :=
              PickMostCommon(Src.PixelS[x, y], Src.PixelS[x-1, y], Src.PixelS[x, y-1], Src.PixelS[x-1, y-1]);
            if not MayBeTransparentDiagonal(x, y,  1, -1) then ResBMP.PixelS[cX + 1, cY - 1] :=
              PickMostCommon(Src.PixelS[x, y], Src.PixelS[x+1, y], Src.PixelS[x, y-1], Src.PixelS[x+1, y-1]);
            if not MayBeTransparentDiagonal(x, y, -1,  1) then ResBMP.PixelS[cX - 1, cY + 1] :=
              PickMostCommon(Src.PixelS[x, y], Src.PixelS[x-1, y], Src.PixelS[x, y+1], Src.PixelS[x-1, y+1]);
            if not MayBeTransparentDiagonal(x, y,  1,  1) then ResBMP.PixelS[cX + 1, cY + 1] :=
              PickMostCommon(Src.PixelS[x, y], Src.PixelS[x+1, y], Src.PixelS[x, y+1], Src.PixelS[x+1, y+1]);
          end;
        end;
      end;
      for y := 0 to ResBMP.Height-1 do
        for x := 0 to ResBMP.Width-1 do
          if (ResBMP[x, y] and $FF000000) = 0 then
            ResBMP[x, y] := $00000000;
    end;

    procedure MakeDstFromRes;
    var
      x, y: Integer;
      rX, rY: Integer;

      procedure HandleStandard(dstX, dstY, aDX, aDY: Integer);
      begin
        aDX := Min(1, Max(aDX, -1));
        aDY := Min(1, Max(aDY, -1));

        if IsTransparentInSrc(dstX div 2 + aDX, dstY div 2) and
           IsTransparentInSrc(dstX div 2, dstY div 2 + aDY) and
           IsTransparentInSrc(dstX div 2 + aDX, dstY div 2 + aDY) and
           (
             ((ResBMP.PixelS[rX + aDX * 2, rY] and $FF000000) = 0) or
             ((ResBMP.PixelS[rX, rY + aDY * 2] and $FF000000) = 0)
           ) then
          Dst[dstX, dstY] := $00000000
        else if (ResBMP.PixelS[rX + aDX * 2, rY] = ResBMP.PixelS[rX, rY + aDY * 2]) then
          Dst[dstX, dstY] := ResBMP.PixelS[rX + aDX * 2, rY]
        else
          Dst[dstX, dstY] := ResBMP.PixelS[rX, rY];
      end;
    begin
      for y := 0 to Src.Height-1 do
      begin
        rY := (y * 3) + 2;

        for x := 0 to Src.Width-1 do
        begin
          rX := (x * 3) + 2;

          HandleStandard(x * 2, y * 2, -1, -1);
          HandleStandard(x * 2 + 1, y * 2, 1, -1);
          HandleStandard(x * 2, y * 2 + 1, -1, 1);
          HandleStandard(x * 2 + 1, y * 2 + 1, 1, 1);

          if ((Src[x, y] and $FF000000) <> 0) and
             ((Dst[x * 2, y * 2] and $FF000000) = 0) and
             ((Dst[x * 2 + 1, y * 2] and $FF000000) = 0) and
             ((Dst[x * 2, y * 2 + 1] and $FF000000) = 0) and
             ((Dst[x * 2 + 1, y * 2 + 1] and $FF000000) = 0) then
          begin
            Dst[x * 2, y * 2] := Src[x, y];
            Dst[x * 2 + 1, y * 2] := Src[x, y];
            Dst[x * 2, y * 2 + 1] := Src[x, y];
            Dst[x * 2 + 1, y * 2 + 1] := Src[x, y];
          end else if (Dst[x * 2, y * 2] <> Src[x, y]) and
                      (Dst[x * 2 + 1, y * 2] <> Src[x, y]) and
                      (Dst[x * 2, y * 2 + 1] <> Src[x, y]) and
                      (Dst[x * 2 + 1, y * 2 + 1] <> Src[x, y]) then
          begin
            if (Dst[x * 2, y * 2] and $FF000000) <> 0 then Dst[x * 2, y * 2] := Src[x, y];
            if (Dst[x * 2 + 1, y * 2] and $FF000000) <> 0 then Dst[x * 2 + 1, y * 2] := Src[x, y];
            if (Dst[x * 2, y * 2 + 1] and $FF000000) <> 0 then Dst[x * 2, y * 2 + 1] := Src[x, y];
            if (Dst[x * 2 + 1, y * 2 + 1] and $FF000000) <> 0 then Dst[x * 2 + 1, y * 2 + 1] := Src[x, y];
          end;
        end;
      end;
    end;
  begin
    ResBMP := TBitmap32.Create;
    try
      MakeResBMP;
      MakeDstFromRes;
    finally
      ResBMP.Free;
    end;
  end;

  procedure UpscaleFullColor;
  var
    ShapeBMP, ColorBMP: TBitmap32;

    n: Integer;
    PBmp, PShape, PColor: PColor32;
    a: Byte;

    PixelArtSettings: TUpscaleSettings;
  begin
    FillChar(PixelArtSettings, SizeOf(TUpscaleSettings), 0);
    PixelArtSettings.Mode := umPixelArt;

    ShapeBMP := TBitmap32.Create;
    ColorBMP := TBitmap32.Create;
    try
      ShapeBMP.SetSize(Src.Width, Src.Height);
      ColorBMP.SetSize(Src.Width * 2, Src.Height * 2);

      PBmp := Src.PixelPtr[0, 0];
      PShape := ShapeBMP.PixelPtr[0, 0];

      for n := 0 to (Src.Width * Src.Height)-1 do
      begin
        if (PBmp^ and $FF000000) = 0 then
          PShape^ := $00000000
        else
          PShape^ := $FFFFFFFF;
        Inc(PBmp);
        Inc(PShape);
      end;

      Upscale(ShapeBMP, PixelArtSettings);

      TLinearResampler.Create(Src);
      Src.DrawTo(ColorBMP, Dst.BoundsRect, Src.BoundsRect);

      TNearestResampler.Create(Src);
      Src.DrawTo(Dst, Dst.BoundsRect, Src.BoundsRect);

      PBmp := Dst.PixelPtr[0, 0];
      PColor := ColorBMP.PixelPtr[0, 0];

      for n := 0 to (Src.Width * Src.Height * 4)-1 do
      begin
        a := (((PBmp^ and $FF000000) shr 24) + ((PColor^ and $FF000000) shr 24)) div 2;
        PBmp^ := (a shl 24) or (PColor^ and $FFFFFF); //(MergeReg(PColor^, PBmp^) and $FFFFFF);
        Inc(PBmp);
        Inc(PColor);
      end;

      PBmp := Dst.PixelPtr[0, 0];
      PShape := ShapeBMP.PixelPtr[0, 0];

      for n := 0 to (Src.Width * Src.Height * 4)-1 do
      begin
        PBmp^ := PBmp^ and PShape^;
        Inc(PBmp);
        Inc(PShape);
      end;
    finally
      ShapeBMP.Free;
      ColorBMP.Free;
    end;
  end;

  procedure ApplyEdges;
  var
    x, y: Integer;
  begin
    for y := 1 to Src.Height-2 do
    begin
      case Settings.LeftSide of
        uebRepeat: Src[0, y] := Src[Src.Width-2, y];
        uebMirror: Src[0, y] := Src[1, y];
        uebTransparent: Src[0, y] := $00000000;
      end;
      case Settings.RightSide of
        uebRepeat: Src[Src.Width-1, y] := Src[1, y];
        uebMirror: Src[Src.Width-1, y] := Src[Src.Width-2, y];
        uebTransparent: Src[Src.Width-1, y] := $00000000;
      end;
    end;

    for x := 1 to Src.Width-2 do
    begin
      case Settings.TopSide of
        uebRepeat: Src[x, 0] := Src[x, Src.Height-2];
        uebMirror: Src[x, 0] := Src[x, 1];
        uebTransparent: Src[x, 0] := $00000000;
      end;
      case Settings.BottomSide of
        uebRepeat: Src[x, Src.Height-1] := Src[x, 1];
        uebMirror: Src[x, Src.Height-1] := Src[x, Src.Height-2];
        uebTransparent: Src[x, Src.Height-1] := $00000000;
      end;
    end;

    if Src[0, 1] = Src[1, 0] then Src[0, 0] := Src[1, 0];
    if Src[Src.Width-2, 0] = Src[Src.Width-1, 1] then Src[Src.Width-1, 0] := Src[Src.Width-2, 0];
    if Src[0, Src.Height-2] = Src[1, Src.Height-1] then Src[0, Src.Height-1] := Src[1, Src.Height-1];
    if Src[Src.Width-2, Src.Height-1] = Src[Src.Width-1, Src.Height-2] then Src[Src.Width-1, Src.Height-1] := Src[Src.Width-2, Src.Height-1];
  end;
begin
  OrigSrc := Src;
  OldDrawMode := Src.DrawMode;
  try
    if Dst = nil then
      Dst := Src;

    Src := TBitmap32.Create;
    Src.SetSize(OrigSrc.Width + 2, OrigSrc.Height + 2);
    Src.Clear(0);

    OrigSrc.DrawTo(Src, 1, 1);
    ApplyEdges;

    Dst.SetSize(Src.Width * 2, Src.Height * 2);
    Dst.Clear($00000000);

    Src.DrawMode := dmOpaque;
    Dst.DrawMode := dmOpaque;

    case Settings.Mode of
      umNearest: Src.DrawTo(Dst, Dst.BoundsRect, Src.BoundsRect);
      umPixelArt: UpscalePixelArt;
      umFullColor: UpscaleFullColor;
    end;

    Src.Assign(Dst);
    Dst.SetSize(Src.Width - 4, Src.Height - 4);
    Dst.Clear(0);
    Src.DrawTo(Dst, -2, -2);
  finally
    Src.Free;
    OrigSrc.DrawMode := OldDrawMode;
  end;
end;

{ TBitmaps }

function TBitmaps.Add(Item: TBitmap32): Integer;
begin
  Result := inherited Add(Item);
end;

function TBitmaps.GetItem(Index: Integer): TBitmap32;
begin
  Result := inherited Get(Index);
end;

procedure TBitmaps.Insert(Index: Integer; Item: TBitmap32);
begin
  inherited Insert(Index, Item);
end;

procedure TBitmaps.Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
var
  BMP: TBitmap32;
  i: Integer;
  w, h: Integer;
  sx, sy: Integer;
begin
  Clear;

  if (Src.Width = 0) or (Src.Height = 0) or (Frames = 0) then
    Exit;

  w := Src.Width;
  h := Src.Height div Frames;
  sx := 0;
  sy := 0;
  for i := 0 to Frames-1 do
  begin
    BMP := TBitmap32.Create;
    Add(BMP);
    BMP.SetSize(w, h);
    BMP.Clear(0);
    Src.DrawTo(BMP, Rect(0, 0, w, h), Rect(sx, sy, sx+w, sy+h));
    if Horizontal then
      Inc(sx, w)
    else
      Inc(sy, h);
  end;
end;

end.

