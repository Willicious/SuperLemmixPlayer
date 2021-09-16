program StyleZipper;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  GR32, GR32_Png,
  Zip,
  Classes,
  StrUtils,
  SysUtils,
  SZChecksummer;

const
  DEFAULT_SOUNDS: array[0..28] of string =
   ('chain',
    'changeop',
    'chink',
    'die',
    'door',
    'electric',
    'exitopen',
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
  ChecksumList, ChecksumReport: TStringList;

  function AppPath: String;
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  end;

  function CalculateChecksum(aFilename: String): String;
  var
    FS: TFileStream;
  begin
    FS := TFileStream.Create(aFilename, fmOpenRead);
    try
      Result := MakeChecksum(FS);
    finally
      FS.Free;
    end;
  end;

  procedure HandleChecksum(aZipFilename: String);
  var
    Checksum: String;
  begin
    Checksum := CalculateChecksum(AppPath + 'style_zips\' + aZipFilename);

    if ChecksumList.Values[aZipFilename] = '' then
      ChecksumReport.Add('      NEW: ' + aZipFilename)
    else if ChecksumList.Values[aZipFilename] = Checksum then
      ChecksumReport.Add('UNCHANGED: ' + aZipFilename)
    else
      ChecksumReport.Add('  CHANGED: ' + aZipFilename);

    ChecksumList.Values[aZipFilename] := Checksum;
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
    BMP: TBitmap32;
    PngStream: TMemoryStream;

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
            if Lowercase(SearchRec.Name) = 'thumbs.db' then
            begin
              DeleteFile(Base + aRelPath + SearchRec.Name);
              Continue;
            end;

            if (ParamStr(1) <> '-d') and (Lowercase(ExtractFileExt(SearchRec.Name)) = '.png') then
            begin
              // This is because some people use really dumb image editors that create huge files.
              LoadBitmap32FromPng(BMP, Base + aRelPath + SearchRec.Name);

              PngStream.Clear;
              SaveBitmap32ToPng(BMP, PngStream);

              if PngStream.Size < SearchRec.Size then
                PngStream.SaveToFile(Base + aRelPath + SearchRec.Name);
            end;

            Zip.Add(Base + aRelPath + SearchRec.Name, 'styles/' + aName + '/' + aRelPath + SearchRec.Name);
            if CompareText(ExtractFileExt(SearchRec.Name), '.nxmo') = 0 then
            begin
              ObjSL.LoadFromFile(Base + aRelPath + SearchRec.Name);
              for i := 0 to ObjSL.Count-1 do
              begin
                Line := TrimLeft(ObjSL[i]);
                if CompareText(LeftStr(Line, 5), 'SOUND') = 0 then
                  Sounds.Add(RightStr(Line, Length(Line) - 6));
                if CompareText(LeftStr(Line, 14), 'SOUND_ACTIVATE') = 0 then
                  Sounds.Add(RightStr(Line, Length(Line) - 15));
                if CompareText(LeftStr(Line, 13), 'SOUND_EXHAUST') = 0 then
                  Sounds.Add(RightStr(Line, Length(Line) - 14));
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
    BMP := TBitmap32.Create;
    PngStream := TMemoryStream.Create;
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

      HandleChecksum(aName + '.zip');
    finally
      Zip.Free;
      Sounds.Free;
      ObjSL.Free;
      BMP.Free;
      PngStream.Free;
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

      //HandleChecksum(aZipFilename); // don't really need checksum for all-styles zip, just see if anything else has changed
    finally
      Zip.Free;
      SL.Free;
    end;
  end;

begin
  ChecksumList := TStringList.Create;
  ChecksumReport := TStringList.Create;
  try
    try
      ForceDirectories(AppPath + 'style_zips\');

      if FileExists(AppPath + '..\data\styles_checksums.ini') then
        ChecksumList.LoadFromFile(AppPath + '..\data\styles_checksums.ini');

      ZipStyles;

      WriteLn('Making all-styles zip.');
      MakeDirectoryZip('styles|sound', '_all_styles.zip');

      ChecksumList.Sorted := true;
      ChecksumList.SaveToFile(AppPath + '..\data\styles_checksums.ini');

      ChecksumReport.Sort;
      ChecksumReport.SaveToFile(AppPath + 'style_zip_report.txt');

      WriteLn('Done.');
      WriteLn('');
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    ChecksumList.Free;
    ChecksumReport.Free;
  end;
end.
