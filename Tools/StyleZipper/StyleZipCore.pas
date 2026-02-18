unit StyleZipCore;

interface

uses
  Vcl.Forms,
  GR32,
  GR32_Png,
  GR32_PortableNetworkGraphic,
  Zip,
  Classes,
  StrUtils,
  SysUtils,
  SZChecksummer;

  procedure RunStyleZipper;
  function AppPath: String;

  var
    DeleteUnchanged: Boolean;
    MakeAllStyles: Boolean;
    RepackPNG: Boolean;
    RepackPNGList: String;

    StylesDirectory: String;
    OutputDirectory: String;

    StyleTimesINI: String;
    ZipChecksumsINI: String;

implementation

  uses
    Main;

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
    Checksum := CalculateChecksum(OutputDirectory + aZipFilename);

    if ChecksumList.Values[aZipFilename] = '' then
      ChecksumReport.Add('      NEW: ' + aZipFilename)
    else if ChecksumList.Values[aZipFilename] = Checksum then
      ChecksumReport.Add('UNCHANGED: ' + aZipFilename)
    else
      ChecksumReport.Add('  CHANGED: ' + aZipFilename);

    ChecksumList.Values[aZipFilename] := Checksum;
  end;

  procedure ZipStyle(aName: String);
  var
    Zip: TZipFile;
    Base: String;
    BMP: TBitmap32;
    PngStream: TMemoryStream;
    RepackStyles: TStringList;

    procedure AddRecursive(aRelPath: String);
    var
      SearchRec: TSearchRec;
      RepackPNGMode: Boolean;
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

            if RepackPNG then
            begin
              if RepackStyles.Count = 0 then
                RepackPNGMode := True // no list = repack everything
              else
                RepackPNGMode := RepackStyles.IndexOf(LowerCase(aName)) >= 0;
            end else
              RepackPNGMode := False;

            if RepackPNGMode and (Lowercase(ExtractFileExt(SearchRec.Name)) = '.png') then
            begin
              LoadBitmap32FromPng(BMP, Base + aRelPath + SearchRec.Name);
              PngStream.Clear;
              SaveBitmap32ToPng(BMP, PngStream);
              if PngStream.Size < SearchRec.Size then
                PngStream.SaveToFile(Base + aRelPath + SearchRec.Name);
            end;

            Zip.Add(Base + aRelPath + SearchRec.Name, aRelPath + SearchRec.Name);
          end else
            AddRecursive(aRelPath + SearchRec.Name + '\');
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;
  begin
    Zip := TZipFile.Create;
    BMP := TBitmap32.Create;
    PngStream := TMemoryStream.Create;
    RepackStyles := TStringList.Create;
    try
      RepackStyles.CommaText := RepackPNGList;

      if FileExists(OutputDirectory + aName + '.zip') then
        DeleteFile(OutputDirectory + aName + '.zip');

      Zip.Open(OutputDirectory + aName + '.zip', zmWrite);
      Base := StylesDirectory + aName + '\';
      AddRecursive('');

      Zip.Close;

      HandleChecksum(aName + '.zip');
    finally
      Zip.Free;
      BMP.Free;
      PngStream.Free;
      RepackStyles.Free;
    end;
  end;

  procedure ZipStyles;
  var
    SearchRec: TSearchRec;
    TotalStyles, StyleIndex: Integer;
  begin
    TotalStyles := 0;
    if FindFirst(StylesDirectory + '*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '..') and (SearchRec.Name <> '.') and ((SearchRec.Attr and faDirectory) <> 0) then
          Inc(TotalStyles);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    StyleIndex := 0;
    if FindFirst(StylesDirectory + '*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name = '..') or (SearchRec.Name = '.') or ((SearchRec.Attr and faDirectory) = 0) then Continue;

        Inc(StyleIndex);
        FormStyleZipper.lblProgress.Caption :=
          'Zipping style ' + IntToStr(StyleIndex) + ' of ' + IntToStr(TotalStyles) + ': ' + SearchRec.Name;
        Application.ProcessMessages;

        ZipStyle(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure MakeDirectoryZip(aZipFilename: String);
  var
    SearchRec: TSearchRec;
    Base: String;
    Zip: TZipFile;
    StyleCount: Integer;

    procedure AddRecursive(const Base, aRelPath: String);
    var
      SearchRec: TSearchRec;
    begin
      if FindFirst(Base + aRelPath + '*', faAnyFile, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;

          if (SearchRec.Attr and faDirectory) = 0 then
            Zip.Add(Base + aRelPath + SearchRec.Name, SearchRec.Name)
          else
            AddRecursive(Base, aRelPath + SearchRec.Name + '\');
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;
  begin
    Zip := TZipFile.Create;
    try
      if FileExists(OutputDirectory + aZipFilename) then
        DeleteFile(OutputDirectory + aZipFilename);

      Zip.Open(OutputDirectory + aZipFilename, zmWrite);

      StyleCount := 0;
      if FindFirst(StylesDirectory + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          Inc(StyleCount);
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;

      if FindFirst(StylesDirectory + '*', faDirectory, SearchRec) = 0 then
      begin
        repeat
          if (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;

          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            Base := StylesDirectory + SearchRec.Name + '\';

            FormStyleZipper.lblProgress.Caption := IntToStr(StyleCount) + ' - Adding style to "styles.zip": ' + SearchRec.Name;
            Application.ProcessMessages;
            Dec(StyleCount);

            AddRecursive(Base, '');
          end;
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;

      Zip.Close;
    finally
      Zip.Free;
    end;
  end;

  procedure DeleteUnchangedZips;
  var
    i, UnchangedStyles: Integer;
    ZipName: String;
  begin
    UnchangedStyles := 0;
    for i := 0 to ChecksumReport.Count-1 do
    begin
      if Pos('UNCHANGED:', ChecksumReport[i]) = 1 then
        Inc(UnchangedStyles);
    end;

    if UnchangedStyles = 0 then Exit;

    for i := 0 to ChecksumReport.Count-1 do
    begin
      if Pos('UNCHANGED:', ChecksumReport[i]) = 1 then
      begin
        ZipName := Trim(Copy(ChecksumReport[i], Length('UNCHANGED:') + 1, MaxInt));

        FormStyleZipper.lblProgress.Caption := IntToStr(UnchangedStyles) + ' - Deleting unchanged zip: ' + ZipName;
        Application.ProcessMessages;
        Dec(UnchangedStyles);

        if FileExists(OutputDirectory + ZipName) then
          DeleteFile(OutputDirectory + ZipName);
      end;
    end;
  end;

  procedure DeleteAllZips;
  var
    SearchRec: TSearchRec;
    ZipCount, i: Integer;
  begin
    ZipCount := 0;
    if FindFirst(OutputDirectory + '*.zip', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        Inc(ZipCount);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    if ZipCount = 0 then Exit;

    i := ZipCount;
    if FindFirst(OutputDirectory + '*.zip', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        FormStyleZipper.lblProgress.Caption := IntToStr(i) + ' - Deleting zip: ' + SearchRec.Name;
        Application.ProcessMessages;
        Dec(i);

        DeleteFile(OutputDirectory + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure UpdateChecksumListForStyleTimes;
  var
    StyleTimesList: TStringList;
    i: Integer;
    Key, Value: string;
  begin
    StyleTimesList := TStringList.Create;
    try
      for i := 0 to ChecksumList.Count - 1 do
      begin
        Key := ChecksumList.Names[i];
        Value := ChecksumList.ValueFromIndex[i];

        if Key.EndsWith('.zip', True) then
          Key := Copy(Key, 1, Length(Key) - 4);

        StyleTimesList.Add(Key + '=' + Value);
      end;

      StyleTimesList.Sorted := True;
      StyleTimesList.SaveToFile(StyleTimesINI);
    finally
      StyleTimesList.Free;
    end;
  end;

  procedure RunStyleZipper;
  begin
    ChecksumList := TStringList.Create;
    ChecksumReport := TStringList.Create;
    try
      ForceDirectories(OutputDirectory);

      if FileExists(ZipChecksumsINI) then
        ChecksumList.LoadFromFile(ZipChecksumsINI);

      ZipStyles;

      if DeleteUnchanged then
        DeleteUnchangedZips;

      if MakeAllStyles then
        MakeDirectoryZip('styles.zip');

      ChecksumList.Sorted := true;
      ChecksumList.SaveToFile(ZipChecksumsINI);

      UpdateChecksumListForStyleTimes;

      ChecksumReport.Sort;
      ChecksumReport.SaveToFile(OutputDirectory + 'style_zip_report.txt');
    finally
      ChecksumList.Free;
      ChecksumReport.Free;
    end;
  end;
end.
