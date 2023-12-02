unit PngInterface;

// Quick and shitty interface between TPngObject and TBitmap32.
// It does fix the differing color orders (TPngObject uses ABGR,
// TBitmap32 uses ARGB).
//
// Can either be called as:
//    <TBitmap32> = TPngInterface.LoadPngFile(<filename>); -- to create a new TBitmap32 and load a PNG to it
//    TPngInterface.LoadPngFile(<filename>, <TBitmap32>);  -- to load a PNG to an existing TBitmap32
//
// For saving:
//    TPngInterface.SavePngFile(<filename>, <TBitmap32>);  -- to save a TBitmap32 to a PNG file
//
// Loading and saving to streams is also possible, use:
//    TPngInterface.LoadPngStream
//    TPngInterface.SavePngStream
// These work the same way as the File equivalents; just use a TStream instead of a filename.
//
// These are all class procedures / functions; no need to create a TPngInterface object.

interface

uses
  Classes, SysUtils, Graphics, GR32, GR32_PNG, GR32_PortableNetworkGraphic;

type
  TPngInterface = class
    private
      class procedure RemoveAlpha(Dst: TBitmap32);
    public
      class procedure SplitBmp32(aSrc: TBitmap32; aDstImage, aDstMask: TBitmap);
      class procedure MaskImageFromFile(Bmp: TBitmap32; fn: String; C: TColor32);
      class procedure MaskImageFromImage(Bmp: TBitmap32; Mask: TBitmap32; C: TColor32);
      class procedure LoadPngFile(fn: String; Bmp: TBitmap32);
      class procedure LoadPngStream(aStream: TStream; Bmp: TBitmap32);
      class procedure SavePngFile(fn: String; Bmp: TBitmap32; NoAlpha: Boolean = false);
      class procedure SavePngStream(aStream: TStream; Bmp: TBitmap32; NoAlpha: Boolean = false);
  end;

implementation

uses
  GameControl,
  Generics.Collections;

type
  TCacheImageData = class
    private
      fWidth: Integer;
      fHeight: Integer;
      fData: array of TColor32;
    public
      constructor Create(aBitmap: TBitmap32);
      procedure Restore(aDst: TBitmap32);
  end;

  TCacheImageDict = TObjectDictionary<String, TCacheImageData>;

var
  ImgCache: TCacheImageDict;

class procedure TPngInterface.SplitBmp32(aSrc: TBitmap32; aDstImage, aDstMask: TBitmap);
var
  x, y: Integer;
  c: TColor32;
  a: Byte;
begin
  aDstImage.Width := aSrc.Width;
  aDstMask.Width := aSrc.Width;
  aDstImage.Height := aSrc.Height;
  aDstMask.Height := aSrc.Height;
  for y := 0 to aSrc.Height-1 do
    for x := 0 to aSrc.Width-1 do
    begin
      C := aSrc.Pixel[x, y];
      a := $FF - AlphaComponent(C);
      C :=  (BlueComponent(C) shl 16) + (GreenComponent(C) shl 8) + RedComponent(C);
      aDstImage.Canvas.Pixels[x, y] := C and $FFFFFF;
      aDstMask.Canvas.Pixels[x, y] := (a shl 16) or (a shl 8) or (a);
    end;
end;

class procedure TPngInterface.MaskImageFromFile(Bmp: TBitmap32; fn: String; C: TColor32);
var
  TempBmp: TBitmap32;
begin
  if not FileExists(fn) then Exit;
  TempBmp := TBitmap32.Create;
  LoadPngFile(fn, TempBmp);
  MaskImageFromImage(Bmp, TempBmp, C);
  TempBmp.Free;
end;

class procedure TPngInterface.MaskImageFromImage(Bmp: TBitmap32; Mask: TBitmap32; C: TColor32);
var
  x, y: Integer;
  McR, McG, McB: Byte;
  R, G, B, A: Byte;

  MaskBmp: TBitmap32;
begin
  McR := RedComponent(C);
  McG := GreenComponent(C);
  McB := BlueComponent(C);
  MaskBMP := TBitmap32.Create;
  MaskBMP.Assign(Mask);
  for y := 0 to MaskBMP.Height-1 do
    for x := 0 to MaskBMP.Width-1 do
    begin
      A := AlphaComponent(MaskBMP.Pixel[x, y]);
      R := RedComponent(MaskBMP.Pixel[x, y]);
      G := GreenComponent(MaskBMP.Pixel[x, y]);
      B := BlueComponent(MaskBMP.Pixel[x, y]);
      // Alpha is not modified.
      R := R * McR div 255;
      G := G * McG div 255;
      B := B * McB div 255;
      MaskBMP.Pixel[x, y] := (A shl 24) + (R shl 16) + (G shl 8) + B;
    end;

  MaskBMP.DrawMode := dmBlend;
  MaskBMP.CombineMode := cmMerge;
  MaskBMP.DrawTo(Bmp);
  MaskBMP.Free;
end;

class procedure TPngInterface.RemoveAlpha(Dst: TBitmap32);
var
  x, y: Integer;
begin
  for y := 0 to Dst.Height-1 do
    for x := 0 to Dst.Width-1 do
      if (Dst[x, y] and $FF000000) = 0 then
        Dst[x, y] := $FF000000
      else
        Dst[x, y] := $FF000000 or Dst[x, y];
end;

class procedure TPngInterface.LoadPngFile(fn: String; Bmp: TBitmap32);
begin
  if (not GameParams.FileCaching) or (not ImgCache.ContainsKey(fn)) then
  begin
    LoadBitmap32FromPng(Bmp, fn);
    if GameParams.FileCaching then
      ImgCache.Add(fn, TCacheImageData.Create(Bmp));
  end else
    ImgCache[fn].Restore(Bmp);
end;

class procedure TPngInterface.LoadPngStream(aStream: TStream; Bmp: TBitmap32);
begin
  LoadBitmap32FromPng(Bmp, aStream);
end;

class procedure TPngInterface.SavePngFile(fn: String; Bmp: TBitmap32; NoAlpha: Boolean = false);
var
  TempStream: TFileStream;
begin
  TempStream := TFileStream.Create(fn, fmCreate);
  try
    SavePngStream(TempStream, Bmp, NoAlpha);
  finally
    TempStream.Free;
  end;
end;

class procedure TPngInterface.SavePngStream(aStream: TStream; Bmp: TBitmap32; NoAlpha: Boolean = false);
var
  TempBmp: TBitmap32;
begin
  if not NoAlpha then
    SaveBitmap32ToPng(Bmp, aStream)
  else begin
    TempBmp := TBitmap32.Create;
    try
      TempBmp.Assign(Bmp);
      RemoveAlpha(Bmp);
      SaveBitmap32ToPng(TempBmp, aStream);
    finally
      TempBmp.Free;
    end;
  end;
end;

(*
class procedure TPngInterface.PngToBitmap32(Png: TPortableNetworkGraphic32; Bmp: TBitmap32);
var
  X, Y: Integer;
  r, g, b, a: Byte;
  ASL: pByteArray;
  Alpha: Boolean;
  XC: pByte;
  TRNS: TCHUNKtRNS;
  fWidth, fHeight, fBytesPerRow: Integer;
  Header: TChunkIHDR;
  BmpArrPtr: PColor32Array;
begin
  ASL := nil; { Just gets rid of a compile-time warning. ASL won't be referenced if it hasn't been initialized anyway, since
                the only line that references it has the same IF condition as the line that initializes it. }

  // Exit if image is not present
  if not Png.IsHeaderPresent then Exit;

  // Load everything into one Header
  Header := Png.Header;
  fBytesPerRow := Header.GetBytesPerRow;
  fWidth := Header.Width;
  fHeight := Header.Height;

  Bmp.SetSize(fWidth, fHeight);
  // Get pointer to array to TColor32
  BmpArrPtr := Bmp.Bits;

  Alpha := (Header.ColorType = COLOR_RGBALPHA);
  for Y := 0 to fHeight-1 do
  begin
    if Alpha then
      LongInt(ASL) := Longint(Header.GetImageAlpha) + (Y * fWidth);

    // Get Png.Scanline[Y] via the Header
    LongInt(XC) := LongInt(Header.GetImageData) + (fHeight - 1 - Y) * LongInt(fBytesPerRow);

    for X := 0 to fWidth-1 do
    begin
      r := pRGBLine(XC)^[X].rgbtRed;
      g := pRGBLine(XC)^[X].rgbtGreen;
      b := pRGBLine(XC)^[X].rgbtBlue;

      if Alpha then
        a := ASL^[X]
      else
        a := 255;

      if a = 0 then
        BmpArrPtr^[Y * fWidth + X] := 0
      else
        BmpArrPtr^[Y * fWidth + X] := (a shl 24) + (r shl 16) + (g shl 8) + b;
    end;
  end;


  // Handle 8 bit PNG files - fuck the 1/2/4 bit ones
  if (PNG.TransparencyMode = ptmBit) and (PNG.Header.BitDepth = 8) then
  begin
    if (Png.Header.ColorType = COLOR_PALETTE)  and (Png.Chunks.ItemFromClass(TChunktRNS) = nil) then
      Png.CreateAlpha;
    TRNS := Png.Chunks.ItemFromClass(TChunktRNS) as TChunktRNS;
    for y := 0 to fHeight-1 do
    begin
      XC := Png.Scanline[y];
      for x := 0 to fWidth-1 do
      begin
        if XC^ = TRNS.TransparentColor then
          Bmp.Pixel[x, y] := 0
        else
          Bmp.Pixel[x, y] := $FF000000 or (Bmp.Pixel[x, y] and $FFFFFF);
        Inc(XC);
      end;
    end;
  end;

end;

class function TPngInterface.Bitmap32ToPng(Bmp: TBitmap32; NoAlpha: Boolean): TPortableNetworkGraphic32;
var
  x, y: Integer;
  r, g, b, a: Byte;
  c: TColor32;
  ASL: pByteArray;
begin
  Result := TPortableNetworkGraphic32.CreateBlank(COLOR_RGBALPHA, 8, Bmp.Width, Bmp.Height);
  for y := 0 to Bmp.Height-1 do
  begin
    ASL := Result.AlphaScanline[y];
    for x := 0 to Bmp.Width-1 do
    begin
      c := Bmp.Pixel[x, y];
      r := (c and $FF0000) shr 16;
      g := (c and $FF00) shr 8;
      b := c and $FF;
      if NoAlpha then
        a := $FF
      else
        a := (c and $FF000000) shr 24;
      Result.Pixels[x, y] := (b shl 16)
                           + (g shl 8)
                           + r;
      ASL^[x] := a;
    end;
  end;
end;*)

{ TCacheImageData }

constructor TCacheImageData.Create(aBitmap: TBitmap32);
var
  PSrc, PDst: PColor32;
  i: Integer;
begin
  inherited Create;
  fWidth := aBitmap.Width;
  fHeight := aBitmap.Height;
  SetLength(fData, fWidth * fHeight);
  PSrc := aBitmap.PixelPtr[0, 0];
  PDst := @fData[0];
  for i := 0 to fWidth * fHeight - 1 do
  begin
    PDst^ := PSrc^;
    Inc(PSrc);
    Inc(PDst);
  end;
end;

procedure TCacheImageData.Restore(aDst: TBitmap32);
var
  PSrc, PDst: PColor32;
  i: Integer;
begin
  aDst.SetSize(fWidth, fHeight);
  PSrc := @fData[0];
  PDst := aDst.PixelPtr[0, 0];
  for i := 0 to fWidth * fHeight - 1 do
  begin
    PDst^ := PSrc^;
    Inc(PSrc);
    Inc(PDst);
  end;
end;

initialization
  ImgCache := TCacheImageDict.Create([doOwnsValues]);

finalization
  ImgCache.Free;

end.