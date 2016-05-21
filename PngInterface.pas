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
  Classes, SysUtils, GR32, PngImage;

type
  TPngInterface = class
    private
      class procedure PngToBitmap32(Png: TPngObject; Bmp: TBitmap32);
      class function Bitmap32ToPng(Bmp: TBitmap32; NoAlpha: Boolean): TPngObject;
    public
      class function LoadPngFile(fn: String): TBitmap32; overload;
      class procedure LoadPngFile(fn: String; Bmp: TBitmap32); overload;
      class function LoadPngStream(aStream: TStream): TBitmap32; overload;
      class procedure LoadPngStream(aStream: TStream; Bmp: TBitmap32); overload;
      class procedure SavePngFile(fn: String; Bmp: TBitmap32; NoAlpha: Boolean = false);
      class procedure SavePngStream(aStream: TStream; Bmp: TBitmap32; NoAlpha: Boolean = false); overload;
  end;

implementation

class function TPngInterface.LoadPngFile(fn: String): TBitmap32;
begin
  Result := TBitmap32.Create;
  LoadPngFile(fn, Result);
end;

class function TPngInterface.LoadPngStream(aStream: TStream): TBitmap32;
begin
  Result := TBitmap32.Create;
  LoadPngStream(aStream, Result);
end;

class procedure TPngInterface.LoadPngFile(fn: String; Bmp: TBitmap32);
var
  TempStream: TFileStream;
begin
  TempStream := TFileStream.Create(fn, fmOpenRead);
  try
    LoadPngStream(TempStream, Bmp);
  finally
    TempStream.Free;
  end;
end;

class procedure TPngInterface.LoadPngStream(aStream: TStream; Bmp: TBitmap32);
var
  TempPng: TPngObject;
begin
  TempPng := TPngObject.Create;
  try
    TempPng.LoadFromStream(aStream);
    PngToBitmap32(TempPng, Bmp);
  finally
    TempPng.Free;
  end;
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
  TempPng: TPngObject;
begin
  TempPng := Bitmap32ToPng(Bmp, NoAlpha);
  TempPng.SaveToStream(aStream);
  TempPng.Free;
end;

class procedure TPngInterface.PngToBitmap32(Png: TPngObject; Bmp: TBitmap32);
var
  x, y: Integer;
  c: TColor32;
  r, g, b, a: Byte;
  ASL: pByteArray;
  Alpha: Boolean;
  XC: pByte;
  TRNS: TCHUNKtRNS;
  fWidth, fHeight, fBytesPerRow: Integer;

  Header: TChunkIHDR;
begin
  ASL := nil; // Just gets rid of a compile-time warning. ASL won't be referenced if it hasn't been initialized anyway, since
              // the only line that references it has the same IF condition as the line that initializes it.

  // exit if image is not present
  if not Png.IsHeaderPresent then Exit;

  // Load everything into one Header
  Header := Png.Header;
  fBytesPerRow := Header.GetBytesPerRow;
  fWidth := Header.Width;
  fHeight := Header.Height;

  Bmp.SetSize(fWidth, fHeight);

  Alpha := (Png.AlphaScanline[0] <> nil);
  for y := 0 to fHeight-1 do
  begin
    if Alpha then
      ASL := Png.AlphaScanline[y];

    // XC := Png.Scanline[y];
    // Get Png.Scanline[y] via the header
    LongInt(XC) := LongInt(Header.GetImageData) + (fHeight - 1 - y) * LongInt(fBytesPerRow);

    for x := 0 to fWidth-1 do
    begin
      r := pRGBLine(XC)^[X].rgbtRed;
      g := pRGBLine(XC)^[X].rgbtGreen;
      b := pRGBLine(XC)^[X].rgbtBlue;

      if Alpha then
        a := ASL^[x]
      else
        a := 255;

      if a = 0 then
        Bmp.Pixel[x, y] := 0
      else
        Bmp.Pixel[x, y] := (a shl 24)
                         + (r shl 16)
                         + (g shl 8)
                         + b;
    end;
  end;


  // handle 8 bit PNG files - fuck the 1/2/4 bit ones
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

class function TPngInterface.Bitmap32ToPng(Bmp: TBitmap32; NoAlpha: Boolean): TPngObject;
var
  x, y: Integer;
  r, g, b, a: Byte;
  c: TColor32;
  ASL: pByteArray;
begin
  Result := TPngObject.CreateBlank(COLOR_RGBALPHA, 8, Bmp.Width, Bmp.Height);
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
end;

end.