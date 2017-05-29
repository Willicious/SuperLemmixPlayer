program GSConvert;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, LemGSConvert, LemGraphicSet, GSLoadNeoLemmix, StrUtils, LemNeoParser;

var
  GS: TBaseGraphicSet;
  L: TNeoLemmixGraphicSet;
  SL: TStringList;
  SrcName: String;

  SearchRec: TSearchRec;

  procedure ConvertGraphicSet(aFile: String);
  begin
    GS := L.LoadGraphicSet(aFile);
    if FileExists(ChangeFileExt(aFile, '.txt')) then
    begin
      SL := TStringList.Create;
      SL.LoadFromFile(ChangeFileExt(aFile, '.txt'));
      Adjust(GS, SL);
      SL.Free;
    end;
    Prepare(GS);
    DoSave(GS, ExtractFileName(ChangeFileExt(aFile, '')));
    GS.Free;
  end;

  procedure HandleMatching(aInput: String);
  var
    Parser: TParser;
    MainSec: TParserSection;
    Sec: TParserSection;
    GS1Name, GS2Name: String;
    GS1, GS2: TBaseGraphicSet;
    SL: TStringList;

    i, i2: Integer;
    GS1Max, GS2Max: Integer;
  begin
    aInput := RightStr(aInput, Length(aInput) - Pos(' ', aInput));
    GS1Name := LeftStr(aInput, Pos(' ', aInput) - 1);
    GS2Name := RightStr(aInput, Length(aInput) - Pos(' ', aInput));

    GS1 := L.LoadGraphicSet(GS1Name);
    GS2 := L.LoadGraphicSet(GS2Name);
    Parser := TParser.Create;
    MainSec := Parser.MainSection;
    try
      if FileExists(ChangeFileExt(GS1Name, '.txt')) then
      begin
        SL := TStringList.Create;
        SL.LoadFromFile(ChangeFileExt(GS1Name, '.txt'));
        Parser.LoadFromStrings(SL);
        Adjust(GS1, SL);
        SL.Free;
      end;
      if FileExists(ChangeFileExt(GS2Name, '.txt')) then
      begin
        SL := TStringList.Create;
        SL.LoadFromFile(ChangeFileExt(GS2Name, '.txt'));
        Adjust(GS2, SL);
        SL.Free;
      end;

      Prepare(GS1);
      Prepare(GS2);

      GS1Name := ChangeFileExt(GS1Name, '');
      GS2Name := ChangeFileExt(GS2Name, '');

      for i := 0 to GS1.TerrainImages.Count-1 do
        for i2 := 0 to GS2.TerrainImages.Count-1 do
        begin
          if GS1.MetaTerrains[i].Steel <> GS2.MetaTerrains[i2].Steel then Continue;
          if not CheckHashMatch(GS1.TerrainImages[i], GS2.TerrainImages[i2]) then Continue;
          if not CheckImageMatch(GS1.TerrainImages[i], GS2.TerrainImages[i2]) then Continue;

          Sec := MainSec.SectionList.Add('TERRAIN');
          Sec.AddLine('INDEX', IntToStr(i));
          Sec.AddLine('REFERENCE', GS2Name + ':' + GS2.MetaTerrains[i2].Name);
        end;

      Parser.SaveToFile(GS1Name + '.txt');
    finally
      GS1.Free;
      GS2.Free;
    end;
  end;

begin
  L := TNeoLemmixGraphicSet.Create(nil);

  SrcName := ParamStr(1);

  repeat

    if (SrcName = '') then
    begin
      WriteLn('Enter filename to convert, or "*all" (without quotes) to convert all graphic sets in this folder.');
      ReadLn(SrcName);
    end;

    if (SrcName <> '') and (Lowercase(RightStr(SrcName, 4)) <> '*all') and (LeftStr(Lowercase(SrcName), 6) <> '*match') then
      if not FileExists(SrcName) then
      begin
        WriteLn('ERROR: File "' + SrcName + '" does not exist.');
        SrcName := '';
      end;

  until SrcName <> '';

  ForceDirectories(ExtractFilePath(ParamStr(0)) + 'data\translation\');

  if Lowercase(RightStr(SrcName, 4)) = '*all' then
  begin
    SrcName := LeftStr(SrcName, Length(SrcName) - 4);
    if Pos(':', SrcName) = 0 then
      SrcName := ExtractFilePath(ParamStr(0)) + SrcName;
    SetCurrentDir(SrcName);
    if FindFirst('*.dat', faAnyFile, SearchRec) = 0 then
      repeat
        SetCurrentDir(SrcName);
        WriteLn('Converting ' + SearchRec.Name + '...');
        ConvertGraphicSet(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    WriteLn('Conversions complete!');
  end else if LeftStr(Lowercase(SrcName), 6) = '*match' then
    HandleMatching(SrcName)
  else
    ConvertGraphicSet(SrcName);

  L.Free;
end.
