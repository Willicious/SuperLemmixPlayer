unit SZChecksummer;

interface

uses
  GR32, GR32_Png, Classes, StrUtils, SysUtils, Zip;

  function MakeChecksum(aStream: TStream): String;

implementation

function GetBinaryChecksumMod(aStream: TStream): UInt64;
var
  InData: UInt64;
  ShiftLen: Integer;
begin
  Result := aStream.Size;
  while aStream.Position < aStream.Size do
  begin
    InData := 0;
    aStream.Read(InData, 8);

    Result := Result xor InData;

    ShiftLen := 0;
    while ((Result and $8000000000000000) = 0) and (ShiftLen < 13) do
    begin
      Result := Result shl 1;
      Inc(ShiftLen);
    end;
  end;
end;

function GetImageChecksumMod(aStream: TStream): UInt64;
var
  BMP: TBitmap32;
  NewStream: TMemoryStream;
  x, y: Integer;
  W, H: Integer;
  C: TColor32;
begin
  BMP := TBitmap32.Create;
  NewStream := TMemoryStream.Create;
  try
    NewStream.Read(aStream, aStream.Size);
    LoadBitmap32FromPng(BMP, aStream);

    W := BMP.Width;
    H := BMP.Height;
    NewStream.Write(W, 4);
    NewStream.Write(H, 4);

    for y := 0 to H-1 do
      for x := 0 to W-1 do
      begin
        C := BMP[x, y];
        if (C and $FF000000) = 0 then
          C := $00000000;

        NewStream.Write(C, 4);
      end;

    NewStream.Position := 0;
    Result := GetBinaryChecksumMod(NewStream);
  finally
    BMP.Free;
    NewStream.Free;
  end;
end;

function GetTextChecksumMod(aStream: TStream): UInt64;
var
  NewStream: TMemoryStream;
  SL: TStringList;
  i: Integer;
begin
  NewStream := TMemoryStream.Create;
  SL := TStringList.Create;
  try
    SL.LoadFromStream(aStream);

    for i := SL.Count-1 downto 0 do
    begin
      if (Trim(SL[i]) = '') or (LeftStr(Trim(SL[i]), 1) = '#') then
        SL.Delete(i)
      else
        SL[i] := TrimLeft(SL[i]);
    end;

    SL.LineBreak := #10;
    SL.SaveToStream(NewStream);
    NewStream.Position := 0;
    Result := GetBinaryChecksumMod(NewStream);
  finally
    NewStream.Free;
    SL.Free;
  end;
end;

function MakeChecksum(aStream: TStream): String;
// Text files - Ignore blank / begin with # lines, and leading space. Don't try to be smarter than that.
// Images - Only care about width, height, and each pixel. Also don't care about color of alpha=0 pixels.
// Everything else - Use actual file data.
var
  Zip: TZipFile;
  FileList: TStringList;
  ThisFileStream: TMemoryStream;
  Checksum: UInt64;
  i: Integer;
  ThisExt: String;
  NewData: TBytes;
begin
  Checksum := 0;
  Result := IntToHex(Checksum, 16);

  Zip := TZipFile.Create;
  FileList := TStringList.Create;
  ThisFileStream := TMemoryStream.Create;
  try
    Zip.Open(aStream, zmRead);
    FileList.Sorted := true;

    for i := 0 to Zip.FileCount-1 do
      FileList.Add(Zip.FileNames[i]);

    for i := 0 to FileList.Count-1 do
    begin
      Zip.Read(FileList[i], NewData);
      ThisFileStream.Size := Length(NewData);
      Move(NewData[0], ThisFileStream.Memory^, ThisFileStream.Size);
      ThisFileStream.Position := 0;

      ThisExt := Lowercase(ExtractFileExt(FileList[i]));

      if ThisExt = '.png' then
        Checksum := Checksum xor GetImageChecksumMod(ThisFileStream)
      else if (ThisExt = '.txt') or (LeftStr(ThisExt, 4) = '.nxm') or (ThisExt = '.nxtm') then
        Checksum := Checksum xor GetTextChecksumMod(ThisFileStream)
      else
        Checksum := Checksum xor GetBinaryChecksumMod(ThisFileStream);
    end;

    Result := IntToHex(Checksum, 16);
  finally
    Zip.Free;
    FileList.Free;
    ThisFileStream.Free;
  end;
end;

end.
