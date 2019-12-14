program StyleZipper;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Zip,
  Classes,
  System.SysUtils;

  function AppPath: String;
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  end;

  procedure ZipStyle(aName: String);
  var
    Zip: TZipFile;
    Base: String;

    procedure AddRecursive(aRelPath: String);
    var
      SearchRec: TSearchRec;
    begin
      if FindFirst(Base + aRelPath + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Name = '..') or (SearchRec.Name = '.') then Continue;

          if (SearchRec.Attr and faDirectory) = 0 then
            Zip.Add(Base + aRelPath + SearchRec.Name, 'styles/' + aName + '/' + aRelPath + SearchRec.Name)
          else
            AddRecursive(aRelPath + SearchRec.Name + '\');
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;
  begin
    ForceDirectories(AppPath + 'style_zips\');

    Zip := TZipFile.Create;
    try
      Zip.Open(AppPath + 'style_zips\' + aName + '.zip', zmWrite);
      Base := AppPath + 'styles\' + aName + '\';
      AddRecursive('');
      Zip.Close;
    finally
      Zip.Free;
    end;
  end;

  procedure ZipStyles;
  var
    SearchRec: TSearchRec;
  begin
    if FindFirst(AppPath + 'styles\*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name = '..') or (SearchRec.Name = '.') then Continue;

        ZipStyle(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure MakeDirectoryZip(aDirectory: String; aZipFilename: String);
  var
    SL: TStringList;
    n: Integer;

    Base: String;
    Zip: TZipFile;

    procedure AddRecursive(aRelPath: String);
    var
      SearchRec: TSearchRec;
    begin
      if FindFirst(Base + aRelPath + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Name = '..') or (SearchRec.Name = '.') then Continue;

          if (SearchRec.Attr and faDirectory) = 0 then
            Zip.Add(Base + aRelPath + SearchRec.Name, SL[n] + '\' + aRelPath + SearchRec.Name)
          else
            AddRecursive(aRelPath + SearchRec.Name + '\');
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;
  begin
    ForceDirectories(AppPath + 'style_zips\');

    Zip := TZipFile.Create;
    SL := TStringList.Create;
    try
      Zip.Open(AppPath + 'style_zips\' + aZipFilename, zmWrite);

      SL.Delimiter := '|';
      SL.StrictDelimiter := true;
      SL.DelimitedText := aDirectory;

      for n := 0 to SL.Count-1 do
      begin
        Base := AppPath + SL[n] + '\';
        AddRecursive('');
      end;

      Zip.Close;
    finally
      Zip.Free;
      SL.Free;
    end;
  end;

begin
  try
    ZipStyles;
    MakeDirectoryZip('styles|sound', 'nx_all_styles.zip');
    MakeDirectoryZip('sound', 'nx_sounds.zip');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
