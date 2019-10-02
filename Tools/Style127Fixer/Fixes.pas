unit Fixes;

interface

uses
  Classes, GR32, GR32_Png, GR32_PortableNetworkGraphic, SysUtils, StrUtils, Math;

  function AppPath: String;
  procedure HandleLemmings(LemmingsFolder: String);

implementation

type
  TLineDivided = record
    StartSpaces: Integer;
    Keyword: String;
    Value: String;
  end;

function AppPath: String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function SplitLine(Line: String): TLineDivided;
var
  n: Integer;
begin
  Result.StartSpaces := 0;
  Result.Keyword := '';
  Result.Value := '';

  for n := 1 to Length(Line) do
    if Line[n] = ' ' then
      Inc(Result.StartSpaces)
    else
      Break;

  for n := Result.StartSpaces + 1 to Length(Line) do
    if Line[n] = ' ' then
      Break
    else
      Result.Keyword := Result.Keyword + Line[n];

  for n := Result.StartSpaces + Length(Result.Keyword) + 2 to Length(Line) do
    Result.Value := Result.Value + Line[n];
end;

function CombineLine(Line: TLineDivided): String;
begin
  Result := StringOfChar(' ', Line.StartSpaces) + Line.Keyword;
  if Line.Value <> '' then
    Result := Result + ' ' + Line.Value;
end;

procedure HandleLemmings(LemmingsFolder: String);
var
  SL: TStringList;
  BMP, BMP2: TBitmap32;
  SearchRec: TSearchRec;
  MaskColor: TColor32;

  function FindNewMaskColor: TColor32;
  const
    COLOR_COUNT = 15;
    CANDIDATES: array[0..COLOR_COUNT-1] of TColor32 =
     ($FF00FF, $FFFF00, $00FFFF, $000000, $FF0000, $00FF00, $0000FF, $FFFFFF,
      $800080, $808000, $008080, $800000, $008000, $000080, $808080);

    function TestColor(Color: TColor32): Boolean;
    var
      x, y: Integer;
    begin
      FindFirst(LemmingsFolder + '*.png', 0, SearchRec); // We already know this will find at least one file.
      repeat
        if CompareText(RightStr(SearchRec.Name, 9), '_mask.png') = 0 then Continue;

        LoadBitmap32FromPng(BMP, SearchRec.Name);
        for y := 0 to BMP.Height-1 do
          for x := 0 to BMP.Width-1 do
            if (BMP[x, y] and $00FFFFFF) = Color then
            begin
              Result := false;
              Exit;
            end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);

      Result := true;
    end;
  var
    i: Integer;
  begin
    for i := 0 to COLOR_COUNT-1 do
      if TestColor(CANDIDATES[i]) then
      begin
        Result := CANDIDATES[i];
        Exit;
      end;

    for Result := $000000 to $FFFFFF do
      if TestColor(Result) then Exit;

    raise Exception.Create('Could not find a suitable color to replace masking.');
  end;

  procedure CopyMask(MaskFilename: String);
  var
    x, y: Integer;
    a: Byte;
  begin
    LoadBitmap32FromPng(BMP, MaskFilename);
    LoadBitmap32FromPng(BMP2, StringReplace(MaskFilename, '_mask.png', '.png', [rfReplaceAll, rfIgnoreCase]));

    for y := 0 to BMP.Height-1 do
      for x := 0 to BMP.Width-1 do
        if (BMP.Pixel[x, y] and $FF000000) <> 0 then
        begin
          a := Max(AlphaComponent(BMP.Pixel[x, y]), AlphaComponent(BMP2.Pixel[x, y]));
          BMP2.Pixel[x, y] := (a shl 24) or MaskColor;
        end;

    SaveBitmap32ToPng(BMP2, StringReplace(MaskFilename, '_mask.png', '.png', [rfReplaceAll, rfIgnoreCase]));
  end;

var
  i: Integer;
  Split: TLineDivided;
begin
  SL := TStringList.Create;
  BMP := TBitmap32.Create;
  BMP2 := TBitmap32.Create;
  try
    MaskColor := $00000000;

    if FindFirst(LemmingsFolder + '*_mask.png', 0, SearchRec) = 0 then
    begin
      FindClose(SearchRec);
      MaskColor := FindNewMaskColor or $FF000000;

      FindFirst(LemmingsFolder + '*_mask.png', 0, SearchRec);
      repeat
        CopyMask(SearchRec.Name);
        DeleteFile(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    SL.LoadFromFile(LemmingsFolder + 'scheme.nxmi');

    for i := 0 to SL.Count-1 do
    begin
      Split := SplitLine(SL[i]);
      if CompareText(Split.Keyword, 'keyframe') = 0 then Split.Keyword := 'LOOP_TO_FRAME';
      if CompareText(Split.Keyword, '$recoloring') = 0 then Split.Keyword := 'STATE_RECOLORING';
      SL[i] := CombineLine(Split);
    end;

    if (MaskColor and $FF000000) <> 0 then
    begin
      SL.Insert(0, '$SPRITESET_RECOLORING');
      SL.Insert(1, '  MASK x' + IntToHex((MaskColor and $FFFFFF), 6));
      SL.Insert(2, '$END');
      SL.Insert(3, '');
    end;
  finally
    SL.Free;
    BMP.Free;
    BMP2.Free;
  end;
end;

end.
