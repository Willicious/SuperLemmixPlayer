unit LemNeoImage;

// This unit provides a few functions to quickly load NeoLemmix-format image
// data into TBitmap32s, and save TBitmap32s to NeoLemmix-format image data

// LoadNeoLemmixImage
// ------------------
// Can be used as either a procedure or a function. Either way, first argument
// is a stream containing the data. As a procedure, second argument is the TBitmap32
// to output to; as a function there is no second argument and it returns a newly
// created TBitmap32 with the desired image.

// SaveNeoLemmixImage
// ------------------
// Can only be used as a procedure. First argument is the TBitmap32 to save. Second
// argument is the stream to save it to. The procedure uses the generic TStream
// class, so most (all?) stream types can be used with it.

interface

uses
  SysUtils, Classes, Gr32;

type
  procedure LoadNeoLemmixImage(Src: TStream; Dst: TBitmap32); overload;
  function LoadNeoLemmixImage(Src: TStream): TBitmap32; overload;
  procedure SaveNeoLemmixImage(Src: TBitmap32; Dst: TStream); overload;

implementation

function LoadNeoLemmixImage(Src: TStream): TBitmap32;
begin
  Result := TBitmap32.Create;
  LoadNeoLemmixImage(Src, Result);
end;

procedure LoadNeoLemmixImage(Src: TStream; Dst: TBitmap32);
var
  wid, hei: LongWord;
  b: Byte;
  C: TColor32;
  x, y: Integer;
begin
  Src.Read(wid, 4);
  Src.Read(hei, 4);
  Dst.SetSize(wid, hei);
  for y := 0 to hei-1 do
    for x := 0 to wid-1 do
    begin
      C := 0;
      Src.Read(b, 1);
      if b <> 0 then
      begin
        C := b shl 24;
        Src.Read(b, 1);
        C := C + (b shl 16);
        Src.Read(b, 1);
        C := C + (b shl 8);
        Src.Read(b, 1);
        C := C + b;
      end;
      Dst.Pixel[x, y] := C;
    end;
end;

procedure SaveNeoLemmixImage(Src: TBitmap32; Dst: TStream);
var
  b: Byte;
  C: TColor32;
  x, y: Integer;
  lw: LongWord;
begin
  lw := Src.Width;
  Dst.Write(lw, 4);
  lw := Src.Height;
  Dst.Write(lw, 4);
  b := 0;
  for y := 0 to Src.Height-1 do
    for x := 0 to Src.Width-1 do
    begin
      C := Src.Pixel[x, y];
      b := (C and $FF000000) shr 24;
      Dst.Write(b, 1);
      if b <> 0 then
      begin
        b := (C and $FF0000) shr 16;
        Dst.Write(b, 1);
        b := (C and $FF00) shr 8;
        Dst.Write(b, 1);
        b := (C and $FF);
        Dst.Write(b, 1);
      end;
    end;
end;

end.
