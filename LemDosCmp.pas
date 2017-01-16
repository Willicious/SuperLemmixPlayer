{-------------------------------------------------------------------------------
  This unit contains:
  o the dos decompression algorithm, based on the c-code of ccexplore.
  This unit NO LONGER contains:
  o a dos compression algorithm, based on free basic code of Mindless
  o an easy to use sectionlist
-------------------------------------------------------------------------------}
unit LemDosCmp;

interface

uses
  Classes, SysUtils, Math, UMisc;

type
  // Origianlly MaxInt div 4 was MaxListSize * 4, but MaxListSize is deprecated!!!
  PBytes = ^TBytes;
  TBytes = array[0..MaxInt div 4 - 1] of Byte;

type
  {-------------------------------------------------------------------------------
    This header is at each section of compressed data.
    o Watch out: the words are Big Endian so swap when reading or writing!!!
    o Compressed size includes this 10 bytes header
    o Never change this declaration
  -------------------------------------------------------------------------------}
  TCompressionHeaderRec = packed record
    BitCnt            : Byte;
    Checksum          : Byte;
    Unused1           : Word;
    DecompressedSize  : Word;
    Unused2           : Word;
    CompressedSize    : Word;
  end;

  {-------------------------------------------------------------------------------
    TDecompressorStateRec is internally used when decompressing
  -------------------------------------------------------------------------------}
type
  TDecompressorStateRec = record
    BitCnt     : Byte;
    CurBits    : Byte;
    Cdata      : PBytes;
    Cptr       : Integer;
    Ddata      : PBytes;
    Dptr       : Integer;
    Checksum   : Integer;
    CSize      : Integer; // added for read validation
    DSize      : Integer; // added for write validation
  end;

type
  TDosDatDecompressor = class
  private
    fSkipErrors: Boolean;
    function ValidSrc(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
    function ValidDst(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
    function CheckSrc(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
    function CheckDst(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
  protected
    function GetNextBits(n: integer; var State: TDecompressorStateRec): Integer;
    procedure CopyPrevData(aBlocklen, aOffsetSize: Integer; var State: TDecompressorStateRec);
    procedure DumpData(Numbytes: Integer; var State: TDecompressorStateRec);
    function Decompress(aCompData, aDecompData: PBytes; aBitCnt: Byte; aCompSize, aDecompSize: Integer): Integer;
  public
  { core routine }
    function DecompressSection(SrcStream, DstStream: TStream): Integer;
    property SkipErrors: Boolean read fSkipErrors write fSkipErrors;
  end;

const
  COMPRESSIONHEADER_SIZE = SizeOf(TCompressionHeaderRec);

type
  EDecompressError = class(Exception);

implementation

resourcestring
  SDecompressorSrcError_ddddddd = 'Decompress error. ' +
    'Attempt to read or write source data at index %d. ' +
    'BitCnt=%d, ' +
    'CurBits=%d, ' +
    'Cptr=%d, ' +
    'Dptr=%d, ' +
    'CSize=%d, '  +
    'DSize=%d';

  SDecompressorDstError_ddddddd = 'Decompress error. ' +
    'Attempt to read or write destination data at index %d. ' +
    'BitCnt=%d, ' +
    'CurBits=%d, ' +
    'Cptr=%d, ' +
    'Dptr=%d, ' +
    'CSize=%d, '  +
    'DSize=%d';

{ TDosDatDecompressor }

function TDosDatDecompressor.ValidSrc(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
begin
  Result := (aIndex < State.CSize) and (aIndex >= 0);
end;

function TDosDatDecompressor.ValidDst(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
begin
  Result := (aIndex < State.DSize) and (aIndex >= 0);
end;

function TDosDatDecompressor.CheckSrc(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
begin
  Result := ValidSrc(State, aIndex);
  if not Result and not SkipErrors then
    with State do
      raise EDecompressError.CreateFmt(SDecompressorSrcError_ddddddd,
        [aIndex, BitCnt, CurBits, Cptr, Dptr, CSize, DSize]);
end;

function TDosDatDecompressor.CheckDst(const State: TDecompressorStateRec; aIndex: Integer): Boolean;
begin
  Result := ValidDst(State, aIndex);
  if not Result and not SkipErrors then
    with State do
      raise EDecompressError.CreateFmt(SDecompressorDstError_ddddddd,
        [aIndex, BitCnt, CurBits, Cptr, Dptr, CSize, DSize]);
end;

function TDosDatDecompressor.GetNextBits(N: integer; var State: TDecompressorStateRec): Integer;
begin
  Result := 0;
  while n > 0 do
  begin
    Dec(State.BitCnt);
    if State.BitCnt = 0 then
    begin
      Dec(State.Cptr);
      CheckSrc(State, State.CPtr);
      State.CurBits := State.Cdata^[State.Cptr];
      State.Checksum := State.CheckSum xor State.Curbits;
      State.BitCnt := 8;
    end;
    Result := Result shl 1;
    Result := Result or (State.CurBits and 1);
    State.CurBits := State.CurBits shr 1;
    Dec(n);
  end;
end;

procedure TDosDatDecompressor.CopyPrevData(aBlocklen, aOffsetSize: Integer; var State: TDecompressorStateRec);
var
  i, Offset: Integer;
begin
  Offset := GetNextBits(aOffsetSize, State);
  for i := 0 to aBlockLen - 1 do
  begin
    Dec(State.Dptr);
    CheckDst(State, State.DPtr);
    CheckDst(State, State.DPtr + Offset + 1);
    State.Ddata^[State.Dptr] := State.Ddata^[State.Dptr + Offset + 1];
  end;
end;

procedure TDosDatDecompressor.DumpData(Numbytes: Integer; var State: TDecompressorStateRec);
var
  B: Byte;
begin
  while NumBytes > 0 do
  begin
    Dec(State.Dptr);
    B := Byte(GetNextBits(8, State));
    CheckDst(State, State.DPtr);
    State.Ddata^[State.Dptr] := B;
    Dec(NumBytes);
  end;
end;


function TDosDatDecompressor.Decompress(aCompData, aDecompData: PBytes;
  aBitCnt: Byte; aCompSize, aDecompSize: Integer): Integer;
var
  State: TDecompressorStateRec;
begin
  FillChar(State, SizeOf(State), 0);

  State.BitCnt := aBitCnt + 1;
  State.Cptr := aCompSize - 1;
  State.Dptr := aDecompSize;
  State.Cdata := aCompdata;
  State.Ddata := aDecompData;
  State.CurBits := aCompdata^[State.Cptr];
  State.Checksum := State.CurBits;
  State.CSize := aCompSize;
  State.DSize := aDecompSize;

  while State.Dptr > 0 do
  begin
    if (GetNextBits(1, State) = 1) then
    begin
      case GetNextBits(2, State) of
        0: CopyPrevData(3, 9, State);
        1: CopyPrevData(4, 10, State);
        2: CopyPrevData(GetNextBits(8, State) + 1, 12, State);
        3: DumpData(GetNextBits(8, State) + 9, State);
      end;
    end
    else begin
      case GetNextBits(1, State) of
        0: DumpData(GetNextBits(3, State) + 1, State);
        1: CopyPrevData(2, 8, State);
      end;
    end;
  end;
  Result := State.Checksum;
end;

function TDosDatDecompressor.DecompressSection(SrcStream, DstStream: TStream): Integer;
{-------------------------------------------------------------------------------
  Code for decompressing one section from source stream to destination stream.
  There can be more sections in a file of course
  o None of the positions of the streams is changed before decompression!
    So be sure you're at the right position.
  o Return value is the number of decompressed bytes.
  o The compression-header must be included in the SrcStream.
  o The data is read en written at the current positions of the streams.
-------------------------------------------------------------------------------}
var
  Rd: Integer;
  Header: TCompressionHeaderRec;
  SrcData, DstData: PBytes;
  ComputedChecksum: Integer;
  CSize, DSize: Integer;
begin
  Assert(COMPRESSIONHEADER_SIZE = 10, 'Program error DecompressSection');
  Result := 0;
  FillChar(Header, SizeOf(Header), 0);
  Rd := SrcStream.Read(Header, COMPRESSIONHEADER_SIZE);
  if Rd <> COMPRESSIONHEADER_SIZE then
    Exit;
  CSize := System.Swap(Header.CompressedSize) + (System.Swap(Header.Unused2) shl 16); // convert from bigendian
  Dec(CSize, COMPRESSIONHEADER_SIZE); // exclude the headersize which is included in this size
  DSize := System.Swap(Header.DecompressedSize) + (System.Swap(Header.Unused1) shl 16); // convert from bigendian

  GetMem(SrcData, CSize);
  GetMem(DstData, DSize);
  try
    FillChar(SrcData^, CSize, 0);
    FillChar(DstData^, DSize, 0);
    SrcStream.ReadBuffer(SrcData^, CSize);
    ComputedChecksum := Decompress(SrcData, DstData, Header.BitCnt, CSize, DSize);
    if ComputedCheckSum <> Header.Checksum then
      raise Exception.Create('Checksum error occurred during decompression');
    DstStream.WriteBuffer(DstData^, DSize);
    Result := DSize;
  finally
    FreeMem(SrcData);
    FreeMem(DstData);
  end;
end;

end.

