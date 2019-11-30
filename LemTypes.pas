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
  GR32, GR32_LowLevel, GR32_Resamplers,
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

  TUpscaleMode = (umNearest, umPixelArt, umFullColor);

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

procedure UpscaleFrames(Src: TBitmap32; FramesHorz, FramesVert: Integer; Mode: TUpscaleMode; Dst: TBitmap32 = nil);
procedure Upscale(Src: TBitmap32; Mode: TUpscaleMode; Dst: TBitmap32 = nil);
function ResMod: Integer; // Returns 1 when in low-res, 2 when in high-res

implementation

uses
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

procedure UpscaleFrames(Src: TBitmap32; FramesHorz, FramesVert: Integer; Mode: TUpscaleMode; Dst: TBitmap32 = nil);
var
  Frames: TBitmaps;
  TempBMP, LocalDst: TBitmap32;
  iX, iY, n: Integer;
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
        Upscale(TempBMP, Mode);
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

procedure Upscale(Src: TBitmap32; Mode: TUpscaleMode; Dst: TBitmap32 = nil);
var
  UsingLocalBitmap: Boolean;
  OldDrawMode: TDrawMode;

  procedure UpscalePixelArt;
  var
    x, y: Integer;
    dxb, dyb: Integer;
    c: TColor32;

    EffectiveRect: TRect;

    function GetSrcColor(x, y: Integer): TColor32;
      function IsInside(x, y: Integer): Boolean;
      begin
        Result := EffectiveRect.Contains(Point(x, y));
      end;

      procedure BringInside(var x, y: Integer);
      begin
        if x < EffectiveRect.Left then x := EffectiveRect.Left;
        if y < EffectiveRect.Top then y := EffectiveRect.Top;
        if x >= EffectiveRect.Right then x := EffectiveRect.Right - 1;
        if y >= EffectiveRect.Bottom then y := EffectiveRect.Bottom - 1;
      end;

      function IsTransparent(x, y: Integer): Boolean;
      begin
        Result := (Src.PixelS[x, y] and $FF000000) = 0;
      end;

      function MayBeTransparent: Boolean;
      var
        sX, sY, oX, oY: Integer;
        wideDirDX, wideDirDY: Integer;
        narrowDirDX, narrowDirDY: Integer;

        iWide, iNarrow: Integer;
        ThisTransparent: Boolean;
      begin
        Result := true;

        if IsInside(x, y) then
          Exit
        else if ((x < EffectiveRect.Left) or (x >= EffectiveRect.Right)) and
                ((y < EffectiveRect.Top) or (y >= EffectiveRect.Bottom)) then
          Exit;

        sX := x;
        sY := y;
        BringInside(sX, sY);

        oX := sX;
        oY := sY;

        wideDirDX := 0;
        wideDirDY := 0;
        narrowDirDX := 0;
        narrowDirDY := 0;

        if x < EffectiveRect.Left then
        begin
          wideDirDX := 0;
          wideDirDY := 1;
          narrowDirDX := 1;
          narrowDirDY := 0;
        end;

        if x >= EffectiveRect.Right then
        begin
          wideDirDX := 0;
          wideDirDY := 1;
          narrowDirDX := -1;
          narrowDirDY := 0;
        end;

        if y < EffectiveRect.Top then
        begin
          wideDirDX := 1;
          wideDirDY := 0;
          narrowDirDX := 0;
          narrowDirDY := 1;
        end;

        if y >= EffectiveRect.Bottom then
        begin
          wideDirDX := 1;
          wideDirDY := 0;
          narrowDirDX := 0;
          narrowDirDY := -1;
        end;

        if IsTransparent(sX - wideDirDX, sY - wideDirDY) then
          for iNarrow := 0 to 2 do
            if not IsTransparent(sX + (iNarrow * narrowDirDX) - wideDirDX, sY + (iNarrow * narrowDirDY) - wideDirDY) then Exit;

        if IsTransparent(sX + wideDirDX, sY + wideDirDY) then
          for iNarrow := 0 to 2 do
            if not IsTransparent(sX + (iNarrow * narrowDirDX) + wideDirDX, sY + (iNarrow * narrowDirDY) + wideDirDY) then Exit;

        Result := false;
      end;
    begin
      if (not IsInside(x, y)) and (not MayBeTransparent) then
        BringInside(x, y);

      if IsInside(x, y) then
        Result := Src.Pixel[x, y]
      else
        Result := $00000000;

      if (Result and $FF000000) = 0 then
        Result := $00000000;
    end;
  begin
    EffectiveRect.Right := 0;
    EffectiveRect.Bottom := 0;
    EffectiveRect.Left := Src.Width;
    EffectiveRect.Top := Src.Height;

    Src.OuterColor := $FF000000;

    for y := 0 to Src.Height-1 do
      for x := 0 to Src.Width-1 do
        if (Src[x, y] and $FF000000) <> 0 then
        begin
          if x < EffectiveRect.Left then EffectiveRect.Left := x;
          if y < EffectiveRect.Top then EffectiveRect.Top := y;
          if x >= EffectiveRect.Right then EffectiveRect.Right := x + 1;
          if y >= EffectiveRect.Bottom then EffectiveRect.Bottom := y + 1;
        end;

    for y := 0 to Src.Height-1 do
      for x := 0 to Src.Width-1 do
      begin
        if (x < EffectiveRect.Left) or (y < EffectiveRect.Top) or
           (x >= EffectiveRect.Right) or (y >= EffectiveRect.Bottom) then
          Continue;


        dxb := x * 2;
        dyb := y * 2;

        C := GetSrcColor(x, y);

        // Attempt 1
        if (GetSrcColor(x-1, y) = GetSrcColor(x, y-1)) then
          Dst[dxb, dyb] := GetSrcColor(x-1, y)
        else
          Dst[dxb, dyb] := C;

        if (GetSrcColor(x+1, y) = GetSrcColor(x, y-1)) then
          Dst[dxb+1, dyb] := GetSrcColor(x+1, y)
        else
          Dst[dxb+1, dyb] := C;

        if (GetSrcColor(x-1, y) = GetSrcColor(x, y+1)) then
          Dst[dxb, dyb+1] := GetSrcColor(x-1, y)
        else
          Dst[dxb, dyb+1] := C;

        if (GetSrcColor(x+1, y) = GetSrcColor(x, y+1)) then
          Dst[dxb+1, dyb+1] := GetSrcColor(x+1, y)
        else
          Dst[dxb+1, dyb+1] := C;

        // Attempt 2
        if (Dst[dxb, dyb] <> C) and
           (Dst[dxb+1, dyb] <> C) and
           (Dst[dxb, dyb+1] <> C) and
           (Dst[dxb+1, dyb+1] <> C) then
        begin
          if (GetSrcColor(x-1, y) = GetSrcColor(x, y-1)) and (GetSrcColor(x-1, y) = $00000000) then
            Dst[dxb, dyb] := GetSrcColor(x-1, y)
          else
            Dst[dxb, dyb] := C;

          if (GetSrcColor(x+1, y) = GetSrcColor(x, y-1)) and (GetSrcColor(x+1, y) = $00000000) then
            Dst[dxb+1, dyb] := GetSrcColor(x+1, y)
          else
            Dst[dxb+1, dyb] := C;

          if (GetSrcColor(x-1, y) = GetSrcColor(x, y+1)) and (GetSrcColor(x-1, y) = $00000000) then
            Dst[dxb, dyb+1] := GetSrcColor(x-1, y)
          else
            Dst[dxb, dyb+1] := C;

          if (GetSrcColor(x+1, y) = GetSrcColor(x, y+1)) and (GetSrcColor(x+1, y) = $00000000) then
            Dst[dxb+1, dyb+1] := GetSrcColor(x+1, y)
          else
            Dst[dxb+1, dyb+1] := C;
        end;

        // Attempt 3
        if (Dst[dxb, dyb] <> C) and
           (Dst[dxb+1, dyb] <> C) and
           (Dst[dxb, dyb+1] <> C) and
           (Dst[dxb+1, dyb+1] <> C) then
        begin
          Dst[dxb, dyb] := C;
          Dst[dxb+1, dyb] := C;
          Dst[dxb, dyb+1] := C;
          Dst[dxb+1, dyb+1] := C;
        end;
      end;
  end;
begin
  UsingLocalBitmap := false;
  OldDrawMode := Src.DrawMode;
  try
    if Dst = nil then
    begin
      Dst := Src;
      Src := nil; // extra safe
      UsingLocalBitmap := true;
      Src := TBitmap32.Create;
      Src.Assign(Dst);
    end;

    Dst.SetSize(Src.Width * 2, Src.Height * 2);
    Dst.Clear($00000000);
    Dst.DrawMode := dmOpaque;

    case Mode of
      umNearest: Src.DrawTo(Dst, Dst.BoundsRect, Src.BoundsRect);
      umPixelArt: UpscalePixelArt;
      umFullColor: begin
                     TKernelResampler.Create(Src).Kernel := TLanczosKernel.Create;
                     Src.DrawTo(Dst, Dst.BoundsRect, Src.BoundsRect);
                   end;
    end;
  finally
    if UsingLocalBitmap then
      Src.Free
    else if Src <> nil then
      Src.DrawMode := OldDrawMode;
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


end.

