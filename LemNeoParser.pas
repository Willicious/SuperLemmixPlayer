unit LemNeoParser;

(*
Contains code for reading NeoLemmix text format files. These have various
four-letter extensions, always beginning with nx.

eg: .nxlv (Level)
    .nxli (Level item: eg terrain piece, object)
    .nxsv (Save file)

// // // Text file format // // //

The text format, at a generic level, is very simple. Each line consists
of a keyword (which may be preceeded by any number of spaces, these are
simply ignored). If extra data is nessecary, the keyword may be seperated
from it by a single space.

Any lines starting with # are treated as comments. Blank lines are also
ignored.

Keywords are converted to upper-case before being passed to the function
that retrieves a line. Values are not altered.

*)

interface

uses
  {$ifdef profile_parser}Dialogs, Windows, SharedGlobals,{$endif}
  Classes, SysUtils, StrUtils;

type
  TParserLine = record
    Keyword: String;
    Value: String;
    Numeric: Integer;
  end;

  TNeoLemmixParser = class
    private
      fCurrentLine: Integer;
      fStringList: TStringList;

      function GetNextLine: TParserLine;
      function ParseString(aString: String): TParserLine;

      procedure DoAfterLoad;
      procedure CleanStringList;
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadFromFile(const aFile: String);
      procedure LoadFromStream(aStream: TStream);
      procedure LoadFromStringList(aStringList: TStrings);

      procedure Reset;

      property NextLine: TParserLine read GetNextLine;
      property StringList: TStringList read fStringList;
  end;

implementation

constructor TNeoLemmixParser.Create;
begin
  inherited;
  fCurrentLine := 0;
  fStringList := TStringList.Create;
end;

destructor TNeoLemmixParser.Destroy;
begin
  fStringList.Free;
  inherited;
end;

procedure TNeoLemmixParser.LoadFromFile(const aFile: String);
begin
  fStringList.LoadFromFile(aFile);
  DoAfterLoad;
end;

procedure TNeoLemmixParser.LoadFromStream(aStream: TStream);
begin
  fStringList.LoadFromStream(aStream);
  DoAfterLoad;
end;

procedure TNeoLemmixParser.LoadFromStringList(aStringList: TStrings);
begin
  fStringList.Assign(aStringList);
  DoAfterLoad;
end;

procedure TNeoLemmixParser.DoAfterLoad;
begin
  fCurrentLine := 0;
  CleanStringList;
end;

procedure TNeoLemmixParser.Reset;
begin
  fCurrentLine := 0;
end;

function TNeoLemmixParser.GetNextLine: TParserLine;
begin
  if fCurrentLine >= fStringList.Count then
  begin
    Result.Keyword := '';
    Result.Value := '';
    Result.Numeric := 0;
  end else begin
    Result := ParseString(fStringList[fCurrentLine]);
    Inc(fCurrentLine);
  end;
end;

function TNeoLemmixParser.ParseString(aString: String): TParserLine;
var
  i: Integer;
  FinishedKeyword: Boolean;
begin
  Result.Keyword := '';
  Result.Value := '';
  Result.Numeric := 0;
  FinishedKeyword := false;
  for i := 1 to Length(aString) do
    if not FinishedKeyword then
    begin
      if aString[i] <> ' ' then
        Result.Keyword := Result.Keyword + aString[i]
      else
        FinishedKeyword := true;
    end else
      Result.Value := Result.Value + aString[i];

  Result.Keyword := Uppercase(Result.Keyword);

  if Result.Value <> '' then
    Result.Numeric := StrToIntDef(Result.Value, 0);
end;

procedure TNeoLemmixParser.CleanStringList;
var
  i, i2: Integer;
  {$ifdef profile_parser}StartTickCount: Cardinal;{$endif}
begin
  {$ifdef profile_parser}StartTickCount := GetTickCount;{$endif}
  for i := fStringList.Count-1 downto 0 do
    if (Trim(fStringList[i]) = '')
    or (Trim(fStringList[i])[1] = '#') then
      fStringList.Delete(i)
    else
      for i2 := 1 to Length(fStringList[i]) do
        if fStringList[i][i2] <> ' ' then
        begin
          fStringList[i] := MidStr(fStringList[i], i2, Length(fStringList[i]));
          Break;
        end;

  {$ifdef profile_parser}ShowMessage(IntToStr(GetTickCount-StartTickCount));{$endif}
end;

end.
