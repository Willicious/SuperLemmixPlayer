unit Fixes;

interface

uses
  Classes, GR32, GR32_Png, GR32_PortableNetworkGraphic, SysUtils, StrUtils, Math;

  function AppPath: String;
  procedure HandleLemmings(LemmingsFolder: String);
  procedure HandleObject(ObjectNXMOFile: String);

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

  Line := StringReplace(Line, #9, '  ', [rfReplaceAll]);

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

procedure HandleObject(ObjectNXMOFile: String);
var
  SL: TStringList;
  SLPrimary: TStringList;
  i: Integer;
  n: Integer;
  FoundEffect: Boolean;
  RemoveLine: Boolean;
  PrimaryStart: Integer;

  procedure AddToPrimary(LineWithoutIndentation: String);
  begin
    if (SLPrimary = nil) then
      SLPrimary := TStringList.Create;

    SLPrimary.Add('  ' + LineWithoutIndentation);
    RemoveLine := true;
  end;
const
  NAME_PAIRINGS_COUNT = 22;
  OLD_NAMES: array[0..NAME_PAIRINGS_COUNT-1] of String =
    ( 'EXIT', 'FORCE_LEFT', 'FORCE_RIGHT', 'TRAP', 'WATER', 'FIRE', 'ONE_WAY_LEFT', 'ONE_WAY_RIGHT',
      'TELEPORTER', 'RECEIVER', 'PICKUP_SKILL', 'LOCKED_EXIT', 'BUTTON', 'ONE_WAY_DOWN', 'UPDRAFT',
      'SPLITTER', 'WINDOW', 'ANTISPLATPAD', 'SPLATPAD', 'MOVING_BACKGROUND', 'SINGLE_USE_TRAP',
      'ONE_WAY_UP' );
  NEW_NAMES: array[0..NAME_PAIRINGS_COUNT-1] of String =
    ( 'EXIT', 'FORCELEFT', 'FORCERIGHT', 'TRAP', 'WATER', 'FIRE', 'ONEWAYLEFT', 'ONEWAYRIGHT',
      'TELEPORTER', 'RECEIVER', 'PICKUPSKILL', 'LOCKEDEXIT', 'UNLOCKBUTTON', 'ONEWAYDOWN', 'UPDRAFT',
      'SPLITTER', 'ENTRANCE', 'ANTISPLATPAD', 'SPLATPAD', 'BACKGROUND', 'TRAPONCE', 'ONEWAYUP'
    );
var
  Split: TLineDivided;
  Level: Integer;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(ObjectNXMOFile);
    SLPrimary := nil;
    FoundEffect := false;
    PrimaryStart := -1;
    Level := 0;

    for i := 0 to SL.Count-1 do
    begin
      Split := SplitLine(SL[i]);
      RemoveLine := false;

      if Level = 0 then
      begin
        if not FoundEffect then
          for n := 0 to NAME_PAIRINGS_COUNT-1 do
            if CompareText(Split.Keyword, OLD_NAMES[n]) = 0 then
            begin
              Split.Keyword := 'EFFECT';
              Split.Value := NEW_NAMES[n];
              FoundEffect := true;
              Break;
            end;

        if CompareText(Split.Keyword, 'frames') = 0 then AddToPrimary('FRAMES ' + Split.Value);
        if CompareText(Split.Keyword, 'horizontal_strip') = 0 then AddToPrimary('HORIZONTAL_STRIP');
        if CompareText(Split.Keyword, 'initial_frame') = 0 then AddToPrimary('INITIAL_FRAME ' + Split.Value);
        if CompareText(LeftStr(Split.Keyword, 10), 'nine_slice') = 0 then AddToPrimary(Split.Keyword + ' ' + Split.Value);

        if CompareText(Split.Keyword, '$PRIMARY_ANIMATION') = 0 then PrimaryStart := i;
      end;

      if CompareText(Split.Keyword, 'STATE') = 0 then
      begin
        if CompareText(Split.Value, 'LOOP_TO_ZERO') = 0 then Split.Value := 'LOOPTOZERO';
        if CompareText(Split.Value, 'MATCH_PRIMARY_FRAME') = 0 then Split.Value := 'MATCHPHYSICS';
      end;

      if CompareText(Split.Keyword, '$END') = 0 then Dec(Level)
      else if LeftStr(Split.Keyword, 1) = '$' then Inc(Level);

      if RemoveLine then
        SL[i] := '*#'
      else
        SL[i] := CombineLine(Split);
    end;

    if (SLPrimary <> nil) then
    begin
      if (PrimaryStart < 0) then
      begin
        if Trim(SL[SL.Count - 1]) <> '' then
          SL.Add('');

        PrimaryStart := SL.Count;
        SL.Add('$PRIMARY_ANIMATION');
        SL.Add('$END');
      end;

      for i := 0 to SLPrimary.Count-1 do
        SL.Insert(PrimaryStart + 1 + i, SLPrimary[i]);
    end;

    for i := SL.Count-1 downto 0 do
      if SL[i] = '*#' then
        SL.Delete(i);

    SL.SaveToFile(ObjectNXMOFile);
  finally
    SL.Free;
    if (SLPrimary <> nil) then
      SLPrimary.Free;
  end;
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

        LoadBitmap32FromPng(BMP, LemmingsFolder + SearchRec.Name);
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
  StartRecolors: Integer;
begin
  SL := TStringList.Create;
  BMP := TBitmap32.Create;
  BMP2 := TBitmap32.Create;
  try
    MaskColor := $00000000;
    StartRecolors := -1;

    if FindFirst(LemmingsFolder + '*_mask.png', 0, SearchRec) = 0 then
    begin
      FindClose(SearchRec);
      MaskColor := FindNewMaskColor or $FF000000;

      FindFirst(LemmingsFolder + '*_mask.png', 0, SearchRec);
      repeat
        CopyMask(LemmingsFolder + SearchRec.Name);
        DeleteFile(LemmingsFolder + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    SL.LoadFromFile(LemmingsFolder + 'scheme.nxmi');

    for i := 0 to SL.Count-1 do
    begin
      Split := SplitLine(SL[i]);
      if CompareText(Split.Keyword, 'keyframe') = 0 then Split.Keyword := 'LOOP_TO_FRAME';
      if CompareText(Split.Keyword, '$recoloring') = 0 then Split.Keyword := '$STATE_RECOLORING';
      if CompareText(Split.Keyword, '$spriteset_recoloring') = 0 then StartRecolors := i;

      SL[i] := CombineLine(Split);
    end;

    if (MaskColor and $FF000000) <> 0 then
    begin
      if StartRecolors < 0 then
      begin
        SL.Insert(0, '$SPRITESET_RECOLORING');
        SL.Insert(1, '  MASK x' + IntToHex((MaskColor and $FFFFFF), 6));
        SL.Insert(2, '$END');
        SL.Insert(3, '');
      end else
        SL.Insert(StartRecolors + 1, '  MASK x' + IntToHex((MaskColor and $FFFFFF), 6));
    end;

    SL.SaveToFile(LemmingsFolder + 'scheme.nxmi');
  finally
    SL.Free;
    BMP.Free;
    BMP2.Free;
  end;
end;

end.
