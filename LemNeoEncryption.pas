{$include lem_directives.inc}
unit LemNeoEncryption;

interface

uses
  Dialogs,
  Classes, SysUtils, LemTypes;

// NeoLemmix Encryption Header
type
  TNeoEncryptionHeader = packed record
    Key         : LongWord;
    Checksum    : LongWord;
    Checktext   : array[0..3] of Char;
    Blank       : LongWord;
  end;

const
  NEOENCHEADER_SIZE = 16; //SizeOf(TNeoEncryptionHeader);
  CHECKTEXT_STRING = 'NEO1';
  CHECKTEXT_OLD = 'NEO ';
  // This is semi-hardcoded. Probably shouldn't be changed.

type
  TNeoEncryption = class
  private
    fKeyNumber : Byte;
    fKeySet    : Boolean;
    fRepKey    : Byte;
    function CalculateChecksum(aStream: TMemoryStream): LongWord;
    procedure DecryptData(aStream: TMemoryStream);
    procedure DoDataShift(aStream: TMemoryStream; Decrypt: Boolean);
    procedure EncryptData(aStream: TMemoryStream);
    procedure PrepareHeader(var aHeader: TNeoEncryptionHeader);
    procedure SetChecksum(aStream: TMemoryStream);
    procedure SetKeyNumber(aKey: Byte);
  public
    constructor Create();
    function LoadFile(aStream: TMemoryStream; aFilename: String): Boolean;
    procedure SaveFile(aStream: TMemoryStream; aFilename: String);
    function LoadStream(aStream: TMemoryStream; aSrcStream: TMemoryStream): Boolean; overload;
    //function LoadStream(aStream: TStream): Boolean; overload;
    function LoadStream(aStream: TMemoryStream): Boolean; overload;
    procedure SaveStream(aStream: TMemoryStream; aDsTMemoryStream: TMemoryStream);
    function CheckEncrypted(aSrcStream: TMemoryStream): Boolean; overload;
    //function CheckEncrypted(aSrcStream: TStream): Boolean; overload;
    property KeyNumber: byte write SetKeyNumber;
    property RepKey: byte write fRepKey;
  end;

implementation

constructor TNeoEncryption.Create;
begin
  inherited Create;
  fKeyNumber := LEMMINGS_RANDSEED;
  fKeySet := true;
  fRepKey := 7;
end;

function TNeoEncryption.CalculateChecksum(aStream: TMemoryStream): LongWord;
var
  i : Integer;
  b : LongWord;
  oP : Int64;
begin
  oP := aStream.Position;
  Result := 0;
  for i := 16 to (aStream.Size - 4) do
  begin
    aStream.Seek(i, soFromBeginning);
    aStream.Read(b, 4);
    Result := Result xor b;
  end;
  aStream.Seek(0, soFromBeginning);
  aStream.Read(b, 4);
  Result := Result xor b;
  Result := Result + fKeyNumber;
  aStream.Position := oP;
end;

procedure TNeoEncryption.DecryptData(aStream: TMemoryStream);
begin
  DoDataShift(aStream, true);
end;

procedure TNeoEncryption.DoDataShift(aStream: TMemoryStream; Decrypt: Boolean);
var
  i : Integer;
  Rd : array[0..3] of byte;
  Mv, Mv2 : Byte;
  Pb : ^Byte;
  fStream : TMemoryStream;
  RepNum: Byte;

  function EvenBitCount(aValue: Byte): Boolean;
  var
    i: Byte;
    k: Byte;
  begin
    i := 1;
    k := 0;
    while i <> 0 do
    begin
      if i and aValue <> 0 then Inc(k);
      i := i * 2;
    end;
    Result := (k mod 2 = 0);
  end;

  procedure ApplyParityBit(var aValue: Byte);
  begin
    if not EvenBitCount(aValue) then aValue := aValue + 128;
  end;

begin
fStream := TMemoryStream.Create;
Mv2 := 0;
try
  Pb := nil;

  fStream.Seek(0, soFromBeginning);
  aStream.Seek(0, soFromBeginning);

  fStream.CopyFrom(aStream, 0);

  fStream.Seek(0, soFromBeginning);
  for i := 0 to 3 do
    fStream.Read(Rd[i], 1);

  Rd[0] := Rd[0] xor fKeyNumber;
  Mv := Rd[0];

  RepNum := 0;

  for i := 13 to (fStream.Size - 1) do
  begin
    if i = 16 then
    begin
      Pb := fStream.Memory;
      Inc(Pb, 16);
    end else if i < 16 then
      Pb := @Rd[i-12];

    if Decrypt and (i >= 16) then
      Mv2 := Pb^;

    Mv := Mv xor RepNum;
    Inc(RepNum, (fKeyNumber mod 16));
    RepNum := RepNum xor $FF;
    Inc(RepNum, (fKeyNumber div 16));
    RepNum := RepNum xor $FF;
    Inc(RepNum, fRepKey);

    case Mv of
      $00      : Pb^ := Pb^ xor fKeyNumber;
      $01..$7F : begin
                   ApplyParityBit(Mv);
                   Pb^ := Pb^ xor Mv;
                 end;
      $80..$EF : begin
                   if EvenBitCount(Mv) then
                     Mv := Mv xor $AA
                     else
                     Mv := Mv xor $55;
                   Pb^ := Pb^ xor Mv;
                 end;
      $F0..$FE : begin
                   Mv := (Mv mod 16) * $11;
                   Pb^ := Pb^ xor Mv;
                 end;
      $FF      : Pb^ := Pb^; //does nothing but just to stress that nothing is done in this case
    end;
    if (Decrypt = false) or (i < 16) then
      Mv2 := Pb^;

    Mv := Mv2;
    Inc(Pb);
  end;

  aStream.Seek(0, soFromBeginning);
  fStream.Seek(0, soFromBeginning);

  aStream.CopyFrom(fStream, 0);
finally
  fStream.Free;
end;
end;

procedure TNeoEncryption.EncryptData(aStream: TMemoryStream);
begin
  DoDataShift(aStream, false);
end;

procedure TNeoEncryption.PrepareHeader(var aHeader: TNeoEncryptionHeader);
begin
  Randomize;
  aHeader.Key := (Random(65536) shl 16) + Random(65536);
  aHeader.Checksum := 0;
  aHeader.Checktext := CHECKTEXT_STRING;
  aHeader.Blank := 0;
end;

procedure TNeoEncryption.SetChecksum(aStream: TMemoryStream);
var
  //i : Integer;
  Cs : LongWord;
begin
  Cs := CalculateChecksum(aStream);
  aStream.Seek(4, soFromBeginning);
  aStream.Write(Cs, 4);
end;

procedure TNeoEncryption.SetKeyNumber(aKey: Byte);
begin
  fKeyNumber := aKey;
  fKeySet := true;
end;

procedure TNeoEncryption.SaveFile(aStream: TMemoryStream; aFilename: String);
var
  fOutputMemoryStream: TMemoryStream;
begin
  fOutputMemoryStream := TMemoryStream.Create;
  try
    SaveStream(aStream, fOutputMemoryStream);
    fOutputMemoryStream.SaveToFile(aFilename);
  finally
    fOutputMemoryStream.Free;
  end;
end;

procedure TNeoEncryption.SaveStream(aStream: TMemoryStream; aDsTMemoryStream: TMemoryStream);
var
  fOutputHeader: TNeoEncryptionHeader;
begin
  Assert((fKeySet = true), 'ERROR: Encryption key has not been set.');

  PrepareHeader(fOutputHeader);
  aDsTMemoryStream.SetSize(aStream.Size + NEOENCHEADER_SIZE);
  aDsTMemoryStream.Seek(0, soFromBeginning);
  aDsTMemoryStream.WriteBuffer(fOutputHeader, NEOENCHEADER_SIZE);
  aDsTMemoryStream.CopyFrom(aStream, 0);
  EncryptData(aDsTMemoryStream);
  SetChecksum(aDsTMemoryStream);
end;

function TNeoEncryption.LoadFile(aStream: TMemoryStream; aFilename: String): Boolean;
var
  fInpuTMemoryStream: TMemoryStream;
begin
  //Result := false;
  fInputMemoryStream := TMemoryStream.Create;
  try
    fInputMemoryStream.LoadFromFile(aFileName);
    Result := LoadStream(aStream, fInputMemoryStream);
  finally
    fInputMemoryStream.Free;
  end;
end;

{function TNeoEncryption.LoadStream(aStream: TStream): Boolean;
var
  fTemp : TMemoryStream;
begin
  aStream.Seek(0, soFromBeginning);
  fTemp := TMemoryStream.Create;
  fTemp.SetSize(aStream.Size);
  fTemp.Seek(0, soFromBeginning);
  fTemp.CopyFrom(aStream, 0);
  Result := LoadStream(fTemp);
  aStream.Seek(0, soFromBeginning);
  fTemp.Seek(0, soFromBeginning);
  aStream.WriteBuffer(fTemp, fTemp.Size);
  aStream.Seek(0, soFromBeginning);
end;}

function TNeoEncryption.LoadStream(aStream: TMemoryStream; aSrcStream: TMemoryStream): Boolean;
begin
  Result := false;
  if not CheckEncrypted(aSrcStream) then Exit;
  DecryptData(aSrcStream);
  aStream.SetSize(aSrcStream.Size - NEOENCHEADER_SIZE);
  aSrcStream.Seek(16, soFromBeginning);
  aStream.Seek(0, soFromBeginning);
  aStream.CopyFrom(aSrcStream, aSrcStream.Size - 16);
  Result := true;
  aStream.Seek(0, soFromBeginning);
end;

function TNeoEncryption.LoadStream(aStream: TMemoryStream): Boolean;
var
  TempStream: TMemoryStream;
begin
  //Result := false;
  TempStream := TMemoryStream.Create;
try
  TempStream.LoadFromStream(aStream);
  Result := LoadStream(aStream, TempStream);
finally
  TempStream.Free;
end;
end;

{function TNeoEncryption.CheckEncrypted(aSrcStream: TStream): Boolean;
var
  fTemp : TMemoryStream;
begin
  fTemp := TMemoryStream.Create;
  fTemp.SetSize(aSrcStream.Size);
  fTemp.Seek(0, soFromBeginning);
  fTemp.CopyFrom(aSrcStream, 0);
  Result := CheckEncrypted(fTemp);
  fTemp.Free;
  aSrcStream.Seek(0, soFromBeginning);
end;}

function TNeoEncryption.CheckEncrypted(aSrcStream: TMemoryStream): Boolean;
var
  fInputHeader: TNeoEncryptionHeader;
  oP : Int64;
begin
  oP := aSrcStream.Position;
  Result := false;
  Assert((fKeySet = true), 'ERROR: Encryption key has not been set.');
  if aSrcStream.Size < 16 then Exit;
  aSrcStream.Seek(0, soFromBeginning);
  aSrcStream.ReadBuffer(fInputHeader, 16);
  aSrcStream.Seek(0, soFromBeginning);
  if (fInputHeader.Checktext <> CHECKTEXT_STRING) and (fInputHeader.Checktext <> CHECKTEXT_OLD) then Exit;
  if fInputHeader.Checktext = CHECKTEXT_OLD then
    fInputHeader.Checksum := fInputHeader.Checksum + fKeyNumber;
  if fInputHeader.Blank <> 0 then Exit;
  if CalculateChecksum(aSrcStream) <> fInputHeader.Checksum then
    Exit;
  Result := true;
  aSrcStream.Position := oP;
end;

end.
