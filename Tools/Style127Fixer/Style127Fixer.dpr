program Style127Fixer;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  Vcl.Forms,
  Fixes;

{$R *.res}

  procedure HandleStyle(StyleName: String);
  var
    SearchRec: TSearchRec;

    function StylePath: String;
    begin
      Result := AppPath;
      if StyleName <> '' then
        Result := Result + IncludeTrailingPathDelimiter(StyleName);
    end;
  begin
    if FileExists(StylePath + 'lemmings\scheme.nxmi') then
      HandleLemmings(StylePath + 'lemmings\');

    if FindFirst(StylePath + 'objects\*.nxmo', 0, SearchRec) = 0 then
    begin
      repeat
        HandleObject(StylePath + 'objects\' + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

  end;

var
  StyleSearchRec: TSearchRec;

begin
  try
    if ParamStr(1) = '-all' then
    begin
      if FindFirst(AppPath + '*', faDirectory, StyleSearchRec) = 0 then
      begin
        repeat
          HandleStyle(StyleSearchRec.Name);
        until FindNext(StyleSearchRec) <> 0;
        FindClose(StyleSearchRec);
      end;
    end else
      HandleStyle('');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
