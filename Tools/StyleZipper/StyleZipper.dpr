program StyleZipper;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Zip,
  Classes,
  StrUtils,
  SysUtils,
  IdHash,
  IdHashMessageDigest;

const
  DEFAULT_SOUNDS: array[0..27] of string =
   ('chain',
    'changeop',
    'chink',
    'die',
    'door',
    'electric',
    'explode',
    'failure',
    'fire',
    'glug',
    'letsgo',
    'mousepre',
    'ohno',
    'oing2',
    'slurp',
    'splash',
    'splat',
    'success',
    'tenton',
    'thud',
    'thunk',
    'timeup',
    'ting',
    'vacuusux',
    'weedgulp',
    'wrench',
    'yippee',
    'zombie');

  SOUND_EXTS: array[0..4] of string = ('.ogg', '.wav', '.aiff', '.aif', '.mp3');

var
  MD5List, MD5Report: TStringList;

  function AppPath: String;
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  end;

  function CalculateMD5(aFilename: String): String;
  var
    IDMD5: TIdHashMessageDigest5;
    FS: TFileStream;
  begin
    IDMD5 := TIdHashMessageDigest5.Create;
    FS := TFileStream.Create(aFilename, fmOpenRead);
    try
      Result := IDMD5.HashStreamAsHex(FS);
    finally
      FS.Free;
      IDMD5.Free;
    end;
  end;

  procedure HandleMD5(aZipFilename: String);
  var
    MD5: String;
  begin
    MD5 := CalculateMD5(AppPath + 'style_zips\' + aZipFilename);

    if MD5List.Values[aZipFilename] = '' then
      MD5Report.Add('      NEW: ' + aZipFilename)
    else if MD5List.Values[aZipFilename] = MD5 then
      MD5Report.Add('UNCHANGED: ' + aZipFilename)
    else
      MD5Report.Add('  CHANGED: ' + aZipFilename);

    MD5List.Values[aZipFilename] := MD5;
  end;

  function IsDefaultSound(aName: String): Boolean;
  var
    i: Integer;
  begin
    Result := true;
    for i := 0 to Length(DEFAULT_SOUNDS)-1 do
      if DEFAULT_SOUNDS[i] = aName then Exit;

    Result := false;
  end;

  procedure ZipStyle(aName: String);
  var
    Zip: TZipFile;
    Base: String;
    Sounds: TStringList;
    ObjSL: TStringList;
    i: Integer;

    procedure AddRecursive(aRelPath: String);
    var
      SearchRec: TSearchRec;
      i: Integer;
      Line: String;
    begin
      if FindFirst(Base + aRelPath + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Name = '..') or (SearchRec.Name = '.') then Continue;

          if (SearchRec.Attr and faDirectory) = 0 then
          begin
            Zip.Add(Base + aRelPath + SearchRec.Name, 'styles/' + aName + '/' + aRelPath + SearchRec.Name);
            if CompareText(ExtractFileExt(SearchRec.Name), '.nxmo') = 0 then
            begin
              ObjSL.LoadFromFile(Base + aRelPath + SearchRec.Name);
              for i := 0 to ObjSL.Count-1 do
              begin
                Line := TrimLeft(ObjSL[i]);
                if CompareText(LeftStr(Line, 5), 'SOUND') = 0 then
                  Sounds.Add(RightStr(Line, Length(Line) - 6));
              end;
            end;
          end else
            AddRecursive(aRelPath + SearchRec.Name + '\');
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;

    procedure AddSound(aName: String);
    var
      i: Integer;
    begin
      for i := 0 to Length(SOUND_EXTS) - 1 do
        if FileExists(AppPath + 'sound\' + aName + SOUND_EXTS[i]) then
        begin
          Zip.Add(AppPath + 'sound\' + aName + SOUND_EXTS[i], 'sound\' + aName + SOUND_EXTS[i]);
          Break;
        end;
    end;
  begin
    Zip := TZipFile.Create;
    Sounds := TStringList.Create;
    ObjSL := TStringList.Create;
    try
      if FileExists(AppPath + 'style_zips\' + aName + '.zip') then
        DeleteFile(AppPath + 'style_zips\' + aName + '.zip');

      Zip.Open(AppPath + 'style_zips\' + aName + '.zip', zmWrite);
      Base := AppPath + 'styles\' + aName + '\';
      AddRecursive('');

      for i := 0 to Sounds.Count-1 do
        if not IsDefaultSound(Sounds[i]) then
          AddSound(Sounds[i]);

      if aName = 'default' then
        for i := 0 to Length(DEFAULT_SOUNDS)-1 do
          AddSound(DEFAULT_SOUNDS[i]);

      Zip.Close;

      HandleMD5(aName + '.zip');
    finally
      Zip.Free;
      Sounds.Free;
      ObjSL.Free;
    end;
  end;

  procedure ZipStyles;
  var
    SearchRec: TSearchRec;
  begin
    if FindFirst(AppPath + 'styles\*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name = '..') or (SearchRec.Name = '.') or ((SearchRec.Attr and faDirectory) = 0) then Continue;

        WriteLn('Zipping style: ' + SearchRec.Name);
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

    Zip := TZipFile.Create;
    SL := TStringList.Create;
    try
      if FileExists(AppPath + 'style_zips\' + aZipFilename) then
        DeleteFile(AppPath + 'style_zips\' + aZipFilename);

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

      HandleMD5(aZipFilename);
    finally
      Zip.Free;
      SL.Free;
    end;
  end;

begin
  MD5List := TStringList.Create;
  MD5Report := TStringList.Create;
  try
    try
      ForceDirectories(AppPath + 'style_zips\');

      if FileExists(AppPath + 'style_zips\styles_md5s.ini') then
        MD5List.LoadFromFile(AppPath + 'style_zips\styles_md5s.ini');

      ZipStyles;

      WriteLn('Making all-styles zip.');
      MakeDirectoryZip('styles|sound', '_all_styles.zip');

      MD5List.SaveToFile(AppPath + 'style_zips\styles_md5s.ini');

      MD5Report.Sort;
      MD5Report.SaveToFile(AppPath + 'style_zip_report.txt');

      WriteLn('Done.');
      WriteLn('');
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    MD5List.Free;
    MD5Report.Free;
  end;
end.
