program StyleZipper;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Zip,
  Classes,
  StrUtils,
  SysUtils;

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

  function AppPath: String;
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
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
    ForceDirectories(AppPath + 'style_zips\');

    Zip := TZipFile.Create;
    Sounds := TStringList.Create;
    ObjSL := TStringList.Create;
    try
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
    MakeDirectoryZip('styles|sound', '_all_styles.zip');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
