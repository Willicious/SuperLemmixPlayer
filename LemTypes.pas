{$include lem_directives.inc}
unit LemTypes;

interface

uses
  Generics.Collections,
  UMisc,
  LemNeoOnline,
  Dialogs,
  SharedGlobals,
  Classes, SysUtils, Contnrs,
  Math,
  GR32, GR32_LowLevel, GR32_Blend, GR32_Resamplers, PngInterface,
  Windows;

const
  MUSIC_EXT_COUNT = 12;
  MUSIC_EXTENSIONS: array[0..MUSIC_EXT_COUNT-1] of string = (
                    '.ogg',
                    '.wav',
                    '.aiff',
                    '.aif',
                    '.mp3',
                    '.mo3',
                    '.it',
                    '.mod',
                    '.xm',
                    '.s3m',
                    '.mtm',
                    '.umx');

type
  TColorDict = TDictionary<TColor32, String>;
  TShadeDict = TDictionary<TColor32, TColor32>; { Shade, Base  - NOT the other way around! }
  TColor32Pair = TPair<TColor32, TColor32>;

  TUpscaleMode = (umNearest, umPixelArt, umFullColor);
  TUpscaleEdgeBehaviour = (uebRepeat, uebMirror, uebTransparent);

  TUpscaleSettings = record
    Mode: TUpscaleMode;
    LeftSide: TUpscaleEdgeBehaviour;
    TopSide: TUpscaleEdgeBehaviour;
    RightSide: TUpscaleEdgeBehaviour;
    BottomSide: TUpscaleEdgeBehaviour;
  end;

  TColorDiff = record
    HShift: Single;
    SShift: Single;
    VShift: Single;
    RAdj: Integer;
    GAdj: Integer;
    BAdj: Integer;
  end;

type
  TLemDataType = (
    ldtNone,
    ldtLemmings,  // NXP or resource
    ldtSound,     // in a resource
    ldtMusic,     // NXP, music packs, resource... there are a few places this looks
    ldtParticles, // is in a resource
    ldtText,      // NXP
    ldtStyle      // NXP, resource, 'styles' directory
  );

type
  TArrayArrayInt = array of array of Integer;
  TArrayArrayBoolean = array of array of Boolean;

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
  published
  end;

  // lemlowlevel
procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; Margins: TRect; Src: TBitmap32);
function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
function AppPath: string;
function MakeSuitableForFilename(const aInput: String): String;
function LemmingsPath: string;
function MusicsPath: string;
procedure MoveRect(var aRect: TRect; const DeltaX, DeltaY: Integer);

function UnderWine: Boolean;
function MakeSafeForFilename(const aString: String; DisallowSpaces: Boolean = true): String;

procedure UpscaleFrames(Src: TBitmap32; FramesHorz, FramesVert: Integer; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);
procedure Upscale(Src: TBitmap32; Settings: TUpscaleSettings; Dst: TBitmap32 = nil);
function ResMod: Integer; // Returns 1 when in low-res, 2 when in high-res

function CalculateColorShift(aPrimary, aAlt: TColor32): TColorDiff;
function ApplyColorShift(aBase: TColor32; aDiff: TColorDiff): TColor32; overload;
function ApplyColorShift(aBase, aPrimary, aAlt: TColor32): TColor32; overload;
procedure ApplyColorShift(bmp: TBitmap32; aDiff: TColorDiff); overload;

procedure DoProjectileRecolor(aProjectileBmp: TBitmap32; aMaskColor: TColor32);

function EvaluateResizable(aSpecified: Integer; aDefault: Integer; aBase: Integer; aIsResizable: Boolean): Integer;

function GetTemporaryFilename: String;

implementation

uses
  LemStrings,
  GameControl;

var
  _AppPath: string;
  _UnderWine: Integer;

function AppPath: string;
begin
  if _AppPath = '' then
    _AppPath := ExtractFilePath(ParamStr(0));
  Result := _AppPath;
end;

function GetTemporaryFilename: String;
begin
  repeat
    Result := AppPath + SFTemp + IntToHex(Random($10000), 4) + IntToHex(Random($10000), 4);
  until not FileExists(Result);
end;

function MakeSafeForFilename(const aString: String; DisallowSpaces: Boolean = true): String;
var
  i, i2: Integer;
const
  FORBIDDEN_CHARS = '<>:"/\|?* ';
begin
  Result := aString;
  for i := 1 to Length(aString) do
  begin
    if (not DisallowSpaces) and (Result[i] = ' ') then
      Continue;
    for i2 := 1 to Length(FORBIDDEN_CHARS) do
      if Result[i] = FORBIDDEN_CHARS[i2] then
        Result[i] := '_';
  end;
  if Length(Result) = 0 then
    Result := '_';
end;

function UnderWine: Boolean;
var
  H: cardinal;
begin
  Result := false;

  if _UnderWine = 2 then Result := true;
  if _UnderWine > 0 then Exit;

  H := LoadLibrary('ntdll.dll');
  if H > HINSTANCE_ERROR then
    begin
      Result := Assigned(GetProcAddress(H, 'wine_get_version'));
      FreeLibrary(H);
    end;

  if Result then
    _UnderWine := 2
  else
    _UnderWine := 1;
end;

procedure MoveRect(var aRect: TRect; const DeltaX, DeltaY: Integer);
begin
  aRect.Right := aRect.Right + DeltaX;
  aRect.Left := aRect.Left + DeltaX;
  aRect.Bottom := aRect.Bottom + DeltaY;
  aRect.Top := aRect.Top + DeltaY;
end;

function MakeSuitableForFilename(const aInput: String): String;
const
  FORBIDDEN_CHARS = '<>:"/\|?*';
  REPLACEMENT_CHAR = '_';
var
  i: Integer;
  CharPos: Integer;
begin
  Result := aInput;
  for i := 1 to Length(FORBIDDEN_CHARS) do
  begin
    CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    while CharPos <> 0 do
    begin
      Result[CharPos] := REPLACEMENT_CHAR;
      CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    end;
  end;
end;

function LemmingsPath: string;
begin
    Result := AppPath;
end;

function MusicsPath: string;
begin
    Result := AppPath;
end;

procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
var
  P: PColor32;
  i: Integer;
begin
  P := B.PixelPtr[0, 0];
  for i := 0 to B.Height * B.Width - 1 do
    begin
      if P^ = FromColor then
        P^ := ToColor;
      Inc(P);
    end;
end;

procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; Margins: TRect; Src: TBitmap32);
type
  TNineSliceRects = array[0..8] of TRect;
var
  SrcRects, DstRects: TNineSliceRects;
  i: Integer;

  function VerifyInput: Boolean;
  var
    CenterRect: TRect;
  begin
    // We need to ensure:
    // - Horizontal size is <= the margin sizes, if Left Margin + Right Margin = Total Source Width
    // - Equivalent for height

    CenterRect := Rect(Margins.Left, Margins.Top, SrcRect.Width - Margins.Right, SrcRect.Height - Margins.Bottom);
    Result := false;

    if (CenterRect.Width <= 0) and (DstRect.Width > Margins.Left + Margins.Right) then Exit;
    if (CenterRect.Height <= 0) and (DstRect.Height > Margins.Top + Margins.Bottom) then Exit;

    Result := true;
  end;

  procedure TrimMargins(var LeftMargin, RightMargin: Integer; dstSize: Integer);
  var
    Overlap: Integer;
  begin
    Overlap := (LeftMargin + RightMargin) - dstSize;
    if Overlap <= 0 then Exit;
    LeftMargin := LeftMargin - (Overlap div 2);
    RightMargin := RightMargin - (Overlap div 2);

    if Overlap mod 2 = 1 then
    begin
      if LeftMargin >= RightMargin then
        LeftMargin := LeftMargin - 1
      else
        RightMargin := RightMargin - 1;
    end;

    if LeftMargin < 0 then
    begin
      RightMargin := RightMargin + LeftMargin;
      LeftMargin := 0;
    end;

    if RightMargin < 0 then
    begin
      LeftMargin := LeftMargin + RightMargin;
      RightMargin := 0;
    end;
  end;

  function MakeNineSliceRects(aInput: TRect): TNineSliceRects;
  var
    VarWidth, VarHeight: Integer; // stores the non-margin width and height
    i: Integer;
  begin
    VarWidth := aInput.Width - (Margins.Left + Margins.Right);
    VarHeight := aInput.Height - (Margins.Top + Margins.Bottom);

    Result[0] := SizedRect(0, 0, Margins.Left, Margins.Top);
    Result[1] := SizedRect(Margins.Left, 0, VarWidth, Margins.Top);
    Result[2] := SizedRect(Margins.Left + VarWidth, 0, Margins.Right, Margins.Top);

    Result[3] := SizedRect(0, Margins.Top, Margins.Left, VarHeight);
    Result[4] := SizedRect(Margins.Left, Margins.Top, VarWidth, VarHeight);
    Result[5] := SizedRect(Margins.Left + VarWidth, Margins.Top, Margins.Right, VarHeight);

    Result[6] := SizedRect(0, Margins.Top + VarHeight, Margins.Left, Margins.Bottom);
    Result[7] := SizedRect(Margins.Left, Margins.Top + VarHeight, VarWidth, Margins.Bottom);
    Result[8] := SizedRect(Margins.Left + VarWidth, Margins.Top + VarHeight, Margins.Right, Margins.Bottom);

    for i := 0 to 8 do
      Result[i].Offset(aInput.Left, aInput.Top);
  end;

  procedure DrawTiled(TotalSrcRect, TotalDstRect: TRect);
  var
    CountX, CountY: Integer;
    iX, iY: Integer;
    SrcRect, DstRect: TRect;
  begin
    if (TotalSrcRect.Width <= 0) or (TotalSrcRect.Height <= 0) or
       (TotalDstRect.Width <= 0) or (TotalDstRect.Height <= 0) then
      Exit;

    CountX := (TotalDstRect.Width - 1) div TotalSrcRect.Width;
    CountY := (TotalDstRect.Height - 1) div TotalSrcRect.Height;

    for iY := 0 to CountY do
    begin
      SrcRect := TotalSrcRect;
      DstRect := SizedRect(TotalDstRect.Left, TotalDstRect.Top + (iY * TotalSrcRect.Height), TotalSrcRect.Width, TotalSrcRect.Height);

      if iY = CountY then
      begin
        DstRect := SizedRect(DstRect.Left, DstRect.Top, DstRect.Width, ((TotalDstRect.Height - 1) mod TotalSrcRect.Height) + 1);
        SrcRect := SizedRect(SrcRect.Left, SrcRect.Top, DstRect.Width, DstRect.Height);
      end;

      for iX := 0 to CountX do
      begin
        if iX = CountX then
        begin
          DstRect := SizedRect(DstRect.Left, DstRect.Top, ((TotalDstRect.Width - 1) mod TotalSrcRect.Width) + 1, DstRect.Height);
          SrcRect := SizedRect(SrcRect.Left, SrcRect.Top, DstRect.Width, DstRect.Height);
        end;

        Src.DrawTo(Dst, DstRect, SrcRect);

        DstRect.Offset(TotalSrcRect.Width, 0);
      end;
    end;
  end;

begin
  if (DstRect.Width = SrcRect.Width) and (DstRect.Height = SrcRect.Height) then
    Src.DrawTo(Dst, DstRect.Left, DstRect.Top) // save processing time
  else begin
    //Assert(VerifyInput, 'Invalid input passed to LemTypes.DrawNineSlice');

    TrimMargins(Margins.Left, Margins.Right, DstRect.Width);
    TrimMargins(Margins.Top, Margins.Bottom, DstRect.Height);

    SrcRects := MakeNineSliceRects(SrcRect);
    DstRects := MakeNineSliceRects(DstRect);

    for i := 0 to 8 do
      DrawTiled(SrcRects[i], DstRects[i]);
  end;
end;

function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
var
  Y, H, W: Integer;
begin
  W := Bmp.Width;
  H := Bmp.Height div FrameCount;
  Y := H * FrameIndex;

  Result.Left := 0;
  Result.Top := Y;
  Result.Right := W;
  Result.Bottom := Y + H;
end;

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


function ResMod: Integer;
begin
  if GameParams.HighResolution then
    ResMod := 2
  else
    ResMod := 1;
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

function CalculateColorShift(aPrimary, aAlt: TColor32): TColorDiff;
var
  H1, H2: Single;
  S1, S2: Single;
  V1, V2: Single;

  C: TColor32;
begin
  RGBToHSV(aPrimary, H1, S1, V1);
  RGBToHSV(aAlt, H2, S2, V2);

  Result.HShift := H2 - H1;
  Result.SShift := S2 - S1;
  Result.VShift := V2 - V1;
  Result.RAdj := 0;
  Result.GAdj := 0;
  Result.BAdj := 0;

  C := ApplyColorShift(aPrimary, Result);
  Result.RAdj := RedComponent(aAlt) - RedComponent(C);
  Result.GAdj := GreenComponent(aAlt) - GreenComponent(C);
  Result.BAdj := BlueComponent(aAlt) - BlueComponent(C);
end;

function ApplyColorShift(aBase: TColor32; aDiff: TColorDiff): TColor32;
var
  H, S, V: Single;
begin
  RGBToHSV(aBase, H, S, V);
  H := H + aDiff.HShift;
  S := S + aDiff.SShift;
  V := V + aDiff.VShift;

  while H >= 1 do
    H := H - 1;
  while H < 0 do
    H := H + 1;

  S := Max(0, Min(S, 1));
  V := Max(0, Min(V, 1));

  Result := (HSVToRGB(H, S, V) and $FFFFFF) or (aBase and $FF000000);

  Result := TColor32(Integer(Result) + (aDiff.RAdj * $10000) + (aDiff.GAdj * $100) + (aDiff.BAdj));
  // The typecasts avoid compiler warnings.
end;

function ApplyColorShift(aBase, aPrimary, aAlt: TColor32): TColor32;
begin
  Result := ApplyColorShift(aBase, CalculateColorShift(aPrimary, aAlt));
end;

procedure ApplyColorShift(bmp: TBitmap32; aDiff: TColorDiff);
var
  y, x: Integer;
  Color: TColor32;
begin
  for y := 0 to bmp.Height - 1 do
    for x := 0 to bmp.Width do begin
      Color := bmp.Pixel[x, y];
      Color := ApplyColorShift(Color, aDiff);
      bmp.Pixel[x, y] := Color;
    end;
end;

procedure DoProjectileRecolor(aProjectileBmp: TBitmap32; aMaskColor: TColor32);
const
  LIGHT_COLOR = $FFFF00FF;
  DARK_COLOR = $FFC000C0;
var
  NewLight, NewDark: TColor32;
  R, G, B: Cardinal;
  Multiplier: Double;
  x, y: Integer;
begin
  NewLight := aMaskColor;

  R := RedComponent(NewLight);
  G := GreenComponent(NewLight);
  B := BlueComponent(NewLight);

  if (R = 0) and (G = 0) and (B = 0) then
  begin
    NewDark := $FF000000;
    NewLight := $FF404040;
  end else if (R <= $40) and (G <= $40) and (B < $40) then
  begin
    Multiplier := $40;
    if R > 0 then Multiplier := Min($40 / R, Multiplier);
    if G > 0 then Multiplier := Min($40 / G, Multiplier);
    if B > 0 then Multiplier := Min($40 / B, Multiplier);

    NewDark := NewLight;
    NewLight := $FF000000 or (Round(R * Multiplier) shl 16) or (Round(G * Multiplier) shl 8) or Round(B * Multiplier);
  end else
    NewDark := $FF000000 or ((R div 2) shl 16) or ((G div 2) shl 8) or (B div 2);

  for y := 0 to aProjectileBmp.Height-1 do
    for x := 0 to aProjectileBmp.Width-1 do
      if aProjectileBmp[x, y] = LIGHT_COLOR then
        aProjectileBmp[x, y] := NewLight
      else if aProjectileBmp[x, y] = DARK_COLOR then
        aProjectileBmp[x, y] := NewDark;
end;

function EvaluateResizable(aSpecified: Integer; aDefault: Integer; aBase: Integer; aIsResizable: Boolean): Integer;
begin
  Result := aBase;
  if aIsResizable then
  begin
    if aSpecified > 0 then
      Result := aSpecified
    else if aDefault > 0 then
      Result := aDefault;
  end;
end;

end.

