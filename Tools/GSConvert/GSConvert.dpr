program GSConvert;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, LemGSConvert, LemGraphicSet, GSLoadNeoLemmix;

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

begin
  L := TNeoLemmixGraphicSet.Create(nil);

  SrcName := ParamStr(1);

  repeat

    if (SrcName = '') then
    begin
      WriteLn('Enter filename to convert, or "*all" (without quotes) to convert all graphic sets in this folder.');
      ReadLn(SrcName);
    end;

    if (SrcName <> '') and (Lowercase(SrcName) <> '*all') then
      if not FileExists(SrcName) then
      begin
        WriteLn('ERROR: File "' + SrcName + '" does not exist.');
        SrcName := '';
      end;

  until SrcName <> '';

  if Lowercase(SrcName) = '*all' then
  begin
    if FindFirst('*.dat', faAnyFile, SearchRec) = 0 then
      repeat
        SetCurrentDir(ExtractFilePath(ParamStr(0)));
        WriteLn('Converting ' + SearchRec.Name + '...');
        ConvertGraphicSet(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
    WriteLn('Conversions complete!');
  end else
    ConvertGraphicSet(SrcName);

  L.Free;
end.
