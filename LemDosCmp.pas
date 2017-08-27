{-------------------------------------------------------------------------------
  This unit contains:
  o the dos decompression algorithm, based on the c-code of ccexplore.
  o a dos compression algorithm, based on free basic code of Mindless
-------------------------------------------------------------------------------}

unit LemDosCmp;

interface

uses
  Classes, SysUtils;

  procedure DecompressDat(aSrc: TStream; aDst: TStream);

implementation

type
  TCompressionHeaderRec = packed record
    BitCnt            : Byte;
    Checksum          : Byte;
    DecompressedSize  : LongWord; // Note: These are in big endian, need to be reversed!
    CompressedSize    : LongWord;
  end;

procedure DecompressDat(aSrc: TStream; aDst: TStream);
var
  CurBit: Integer;
  MaxBit: Integer;
  CurByte: PByte;

    InTempStream, OutTempStream: TMemoryStream;

  procedure Error;
  begin
    raise Exception.Create('DecompressDat encountered an unexpected end of data.');
  end;

  procedure DoByteOrderSwap(var aLongword: LongWord);
  var
    P1, P2: ^Byte;
    TempLW: LongWord;
    i: Integer;
  begin
    TempLW := aLongword;
    P1 := @aLongword;
    for i := 0 to 2 do
      Inc(P1);
    P2 := @TempLW;
    for i := 0 to 3 do
    begin
      P1^ := P2^;
      Dec(P1);
      Inc(P2);
    end;
  end;

  function GetValue(aBits: Integer): Cardinal;
  var
    Flag: Byte;
  begin
    Result := 0;
    while aBits > 0 do
    begin
      Dec(aBits);
      Flag := 1 shl CurBit;
      if CurByte^ and Flag <> 0 then
        Inc(Result, 1 shl aBits);
      Inc(CurBit);
      if CurBit > MaxBit then
      begin
        CurBit := 0;
        Dec(CurByte);
        MaxBit := 7;
      end;
    end;
  end;
var
  Header: TCompressionHeaderRec;
  DstByte, SrcByte: PByte;
  CopyCount: Integer;
  ReadCount: Integer;

 // InTempStream, OutTempStream: TMemoryStream;

  Operation: Integer;
begin
  if aSrc.Read(Header, SizeOf(TCompressionHeaderRec)) <> SizeOf(TCompressionHeaderRec) then
    Error;

  DoByteOrderSwap(Header.DecompressedSize);
  DoByteOrderSwap(Header.CompressedSize);
  Dec(Header.CompressedSize, 10);

  InTempStream := TMemoryStream.Create;
  OutTempStream := TMemoryStream.Create;
  try
    if InTempStream.CopyFrom(aSrc, Header.CompressedSize) <> Header.CompressedSize then
      Error;

    OutTempStream.Size := Header.DecompressedSize;

    DstByte := OutTempStream.Memory;
    Inc(DstByte, OutTempStream.Size-1);
    CurByte := InTempStream.Memory;
    Inc(CurByte, InTempStream.Size-1);

    CurBit := 0;
    if Header.BitCnt = 0 then
    begin
      Dec(CurByte);
      MaxBit := 7;
    end else
      MaxBit := Header.BitCnt - 1;
    while Integer(CurByte) >= Integer(InTempStream.Memory) do
    begin
      if GetValue(1) = 0 then
        Operation := GetValue(1)
      else
        Operation := GetValue(2) + 4;

      CopyCount := 0;
      ReadCount := 0;
      SrcByte := DstByte;

      case Operation of
        0: ReadCount := GetValue(3) + 1;
        1: begin
             CopyCount := 2;
             Inc(SrcByte, GetValue(8) + 1);
           end;
        4: begin
             CopyCount := 3;
             Inc(SrcByte, GetValue(9) + 1);
           end;
        5: begin
             CopyCount := 4;
             Inc(SrcByte, GetValue(10) + 1);
           end;
        6: begin
             CopyCount := GetValue(8) + 1;
             Inc(SrcByte, GetValue(12) + 1);
           end;
        7: ReadCount := GetValue(8) + 9;
      end;

      while CopyCount > 0 do
      begin
        DstByte^ := SrcByte^;
        Dec(DstByte);
        Dec(SrcByte);
        Dec(CopyCount);
      end;

      while ReadCount > 0 do
      begin
        DstByte^ := GetValue(8);
        Dec(DstByte);
        Dec(ReadCount);
      end;
    end;

    OutTempStream.Position := 0; // just in case
    aDst.CopyFrom(OutTempStream, OutTempStream.Size);
  finally
    InTempStream.Free;
    OutTempStream.Free;
  end;
end;

end.

