unit Metagen;

interface

uses
  Generics.Collections,
  StrUtils, Math,
  Classes, SysUtils;

type
  TStyleInfo = record
    InternalName: String;
    Name: String;
    Author: String;
    SortAuthor: String;
    OrderNumber: Double;
    FilledBySearchRec: Boolean;
  end;

  TStyleProcessor = class
    private
      fRawStyleData: TList<TStyleInfo>;
      fWarnings: TStringList;

      procedure LoadStyleIni;

      procedure FindOtherStyles;
      procedure HandleSearchStyle(aStyleName: String);
      procedure SortStyleList;
      procedure FixIndices;
      procedure GenerateMetaFiles;
      procedure GenerateCombineFile;
      procedure SaveWarningInfo;

      procedure HandleSpecialCases(var Rec: TStyleInfo);
    public
      constructor Create;
      destructor Destroy; override;

      procedure Execute;
  end;

implementation

function GetAuthor(aRec: TStyleInfo): String;
begin
  Result := aRec.SortAuthor;
  if Result = '' then
    Result := aRec.Author;
end;

{ TStyleProcessor }

constructor TStyleProcessor.Create;
begin
  fRawStyleData := TList<TStyleInfo>.Create;
  fWarnings := TStringList.Create;
end;

destructor TStyleProcessor.Destroy;
begin
  fRawStyleData.Free;
  fWarnings.Free;
  inherited;
end;

procedure TStyleProcessor.Execute;
begin
  LoadStyleIni;
  FindOtherStyles;
  SortStyleList;
  FixIndices;
  GenerateMetaFiles;
  GenerateCombineFile;
  SaveWarningInfo;
end;

procedure TStyleProcessor.SaveWarningInfo;
begin
  if fWarnings.Count = 0 then
    fWarnings.Add('No warnings to report.');

  fWarnings.SaveToFile('..\StyleMetaGen Warnings.txt');
end;

procedure TStyleProcessor.GenerateCombineFile;
var
  i: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    for i := 0 to fRawStyleData.Count-1 do
    begin
      SL.Add('[' + fRawStyleData[i].InternalName + ']');
      SL.Add('NAME ' + fRawStyleData[i].Name);
      SL.Add('AUTHOR ' + fRawStyleData[i].Author);
      if fRawStyleData[i].SortAuthor <> '' then
        SL.Add('SORT_AUTHOR ' + fRawStyleData[i].SortAuthor);
      SL.Add('ORDER ' + IntToStr(Round(fRawStyleData[i].OrderNumber)));
      SL.Add('');
    end;

    SL.SaveToFile('..\StyleMetaGen Combine.txt');
  finally
    SL.Free;
  end;
end;

procedure TStyleProcessor.GenerateMetaFiles;
var
  i: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    for i := 0 to fRawStyleData.Count-1 do
    begin
      SL.Clear;
      SL.Add('NAME ' + fRawStyleData[i].Name);
      SL.Add('AUTHOR ' + fRawStyleData[i].Author);
      if fRawStyleData[i].SortAuthor <> '' then
        SL.Add('SORT_AUTHOR ' + fRawStyleData[i].SortAuthor);
      SL.Add('ORDER ' + IntToStr(Round(fRawStyleData[i].OrderNumber)));

      SL.SaveToFile(fRawStyleData[i].InternalName + '\style.nxmi');

      if CompareText(fRawStyleData[i].Author, LeftStr(fRawStyleData[i].InternalName, Pos('_', fRawStyleData[i].InternalName) - 1)) <> 0 then
        fWarnings.Add('Potential author name error: ' + fRawStyleData[i].InternalName);
    end;
  finally
    SL.Free;
  end;
end;

procedure TStyleProcessor.FixIndices;
var
  i: Integer;
  LastAuthor: String;
  IndexCounter: Integer;
  Rec: TStyleInfo;
begin
  IndexCounter := 0;
  LastAuthor := '';

  for i := 0 to fRawStyleData.Count-1 do
  begin
    if CompareText(GetAuthor(fRawStyleData[i]), LastAuthor) <> 0 then
    begin
      LastAuthor := GetAuthor(fRawStyleData[i]);
      IndexCounter := 0;
    end;

    Rec := fRawStyleData[i];
    Rec.OrderNumber := IndexCounter;
    fRawStyleData[i] := Rec;
    Inc(IndexCounter);
  end;
end;

procedure TStyleProcessor.SortStyleList;
var
  i: Integer;
  Balance: Integer;
begin
  i := 1;
  while i < fRawStyleData.Count do
  begin
    if not DirectoryExists(fRawStyleData[i].InternalName) then
    begin
      fWarnings.Add('Style not found: ' + fRawStyleData[i].InternalName);
      fRawStyleData.Delete(i);
      Continue;
    end;

    Balance := CompareText(GetAuthor(fRawStyleData[i]), GetAuthor(fRawStyleData[i-1]));
    if Balance = 0 then
      Balance := Sign(fRawStyleData[i].OrderNumber - fRawStyleData[i-1].OrderNumber);
    if Balance = 0 then
      Balance := CompareText(fRawStyleData[i].Name, fRawStyleData[i-1].Name);

    if Balance < 0 then
    begin
      fRawStyleData.Move(i, i-1);
      Dec(i);
      if i = 0 then
        i := 1;
    end else
      Inc(i);
  end;
end;

procedure TStyleProcessor.FindOtherStyles;
var
  SearchRec: TSearchRec;
begin
  if FindFirst('', faDirectory, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
        Continue;

      if (SearchRec.Name = '..') or (SearchRec.Name = '.') then
        Continue;

      HandleSearchStyle(SearchRec.Name);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

procedure TStyleProcessor.HandleSearchStyle(aStyleName: String);
var
  NewStyleRec: TStyleInfo;
  NameMod: String;
  i: Integer;

  procedure Capitalize(aPos: Integer);
  begin
    NameMod[i] := Uppercase(NameMod[i])[1];
  end;
begin
  for i := 0 to fRawStyleData.Count-1 do
    if CompareText(fRawStyleData[i].InternalName, aStyleName) = 0 then
      Exit;

  NewStyleRec.InternalName := aStyleName;
  if Pos('_', aStyleName) = 0 then
  begin
    NewStyleRec.Name := aStyleName;
    NewStyleRec.Author := 'Unknown';
  end else begin
    NewStyleRec.Name := RightStr(aStyleName, Length(aStyleName) - Pos('_', aStyleName));
    NewStyleRec.Author := LeftStr(aStyleName, Pos('_', aStyleName) - 1);
  end;
  NewStyleRec.OrderNumber := 9999;
  NewStyleRec.FilledBySearchRec := True;

  for i := 0 to fRawStyleData.Count-1 do
    if CompareText(fRawStyleData[i].Author, NewStyleRec.Author) = 0 then
    begin
      NewStyleRec.Author := fRawStyleData[i].Author; // to match case
      Break;
    end;

  NameMod := StringReplace(NewStyleRec.Name, '_', ' ', [rfReplaceAll]);
  for i := 1 to Length(NameMod) do
    if (i = 1) or (NameMod[i-1] = ' ') or (NameMod[i-1] = '-') then
      Capitalize(i);
  NewStyleRec.Name := NameMod;

  NewStyleRec.SortAuthor := '';

  fRawStyleData.Add(NewStyleRec);
end;

procedure TStyleProcessor.HandleSpecialCases(var Rec: TStyleInfo);
begin
  if (Rec.Author = 'Orig') or (Rec.Author = 'OhNo') then
    Rec.Author := 'Official';

  if (Rec.Author = 'Genesis') then
  begin
    Rec.Name := 'Dirt-Genesis';
    Rec.Author := 'Official';
  end;

  if (Rec.Author = 'Arty') then
    Rec.Author := 'Colorful Arty';

  if (Rec.Author = 'Flo+Giga') then
  begin
    Rec.Author := 'Flopsy, GigaLem';
    Rec.SortAuthor := 'Flopsy';
  end;

  if (Rec.Author = 'Flopsy, namida') then
  begin
    Rec.Author := 'Flopsy, namida';
    Rec.SortAuthor := 'Flopsy';
  end;

  if LeftStr(Rec.Author, 14) = 'Freedom Planet' then
    Rec.SortAuthor := 'GigaLem';

  if (Rec.InternalName = 'ichotolot_pieuw_castle') then
  begin
    Rec.Author := 'IchoTolot, Pieuw';
    Rec.SortAuthor := 'IchoTolot';
  end;

  if (Rec.InternalName = 'ichotolot_jamie_city') then
  begin
    Rec.Author := 'IchoTolot, Jamie';
    Rec.SortAuthor := 'IchoTolot';
  end;

  if (Rec.Author = 'mikedailly+garytimmons') then
    Rec.Author := 'Mike Dailly, Gary Timmons';

  if RightStr(Rec.Name, 8) = ' Special' then
  begin
    Rec.Name := 'Special';
    Rec.Author := LeftStr(Rec.Name, Length(Rec.Name) - 8);
    Rec.OrderNumber := 99999;
  end;

  if (Rec.InternalName = 'examples') then
    Rec.OrderNumber := 100000;

  if CompareText(RightStr(Rec.Author, 5), ', Lix') = 0 then
    Rec.SortAuthor := LeftStr(Rec.Author, Length(Rec.Author) - 5);

  if (Rec.Author = 'Unknown Author') then
    Rec.Author := 'Unknown';

  if (Rec.InternalName = 'timfoxxy_gigalem_launchbase') then
  begin
    Rec.Author := 'timfoxxy, GigaLem';
    Rec.SortAuthor := 'timfoxxy';
  end;
end;

procedure TStyleProcessor.LoadStyleIni;
var
  IniFile: TStringList;
  NewStyleRec: TStyleInfo;
  RawName: String;
  i: Integer;
begin
  IniFile := TStringList.Create;
  try
    IniFile.LoadFromFile('styles.ini');

    for i := 0 to IniFile.Count-1 do
    begin
      if Length(IniFile[i]) > 0 then
      begin
        if IniFile[i][1] = '[' then
        begin
          if i > 0 then
            fRawStyleData.Add(NewStyleRec);

          NewStyleRec.InternalName := Copy(IniFile[i], 2, Length(IniFile[i])-2);
          NewStyleRec.Name := '';
          NewStyleRec.Author := '';
          NewStyleRec.SortAuthor := '';
          NewStyleRec.OrderNumber := 0;
          NewStyleRec.FilledBySearchRec := False;
        end;

        if LeftStr(IniFile[i], 5) = 'Name=' then
        begin
          RawName := RightStr(IniFile[i], Length(IniFile[i]) - 5);
          if Pos('(', RawName) = 0 then
          begin
            NewStyleRec.Name := RawName;
            NewStyleRec.Author := 'Official';
          end else begin
            NewStyleRec.Name := LeftStr(RawName, Pos('(', RawName) - 2);
            NewStyleRec.Author := Copy(RawName,
                                       Pos('(', RawName) + 1,
                                       Pos(')', RawName) - Pos('(', RawName) - 1);

            HandleSpecialCases(NewStyleRec);
          end;
        end;

        if LeftStr(IniFile[i], 6) = 'Order=' then
          NewStyleRec.OrderNumber := StrToFloatDef(RightStr(IniFile[i], Length(IniFile[i])-6), 0);
      end;
    end;

    fRawStyleData.Add(NewStyleRec); // otherwise the last one in the file won't get added
  finally
    IniFile.Free;
  end;
end;

end.
