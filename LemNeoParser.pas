unit LemNeoParser;

interface

uses
  Contnrs, StrUtils, Classes, SysUtils;

const
  INDENT_PER_SECTION = 2;

type
  // Exceptions
  EParserNumericError = class(Exception);

  // Classes
  TParser = class;
  TParserSection = class;
  TParserLine = class;
  TParserSectionList = class;
  TParserLineList = class;

  TForEachLineProcedure = procedure(aLine: TParserLine) of object;
  TForEachSectionProcedure = procedure(aSection: TParserSection) of object;

  TParser = class
    private
      fMainSection: TParserSection;
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadFromFile(aFile: String);
      procedure LoadFromStream(aStream: TStream);
      procedure LoadFromStrings(aStrings: TStrings);

      procedure SaveToFile(aFile: String);
      procedure SaveToStream(aStream: TStream);
      procedure SaveToStrings(aStrings: TStrings);

      property MainSection: TParserSection read fMainSection;
  end;

  TParserSection = class
    private
      fIterator: Integer;
      fKeyword: String;
      fSections: TParserSectionList;
      fLines: TParserLineList;
      function GetKeyword: String;
      procedure SetKeyword(aValue: String);

      procedure LoadFromStrings(aStrings: TStrings; var aPos: Integer);
      procedure SaveToStrings(aStrings: TStrings; aIndent: Integer);
    public
      constructor Create(aKeyword: String);

      function DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure): Integer;
      function DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure): Integer;

      property Keyword: String read GetKeyword write SetKeyword;
      property KeywordDirect: String read fKeyword write SetKeyword;

      property Sections: TParserSectionList read fSections;
      property Lines: TParserLineList read fLines;
  end;

  TParserLine = class
    private
      fKeyword: String;
      fValue: String;
      function GetTrimmedValue: String;
      procedure SetTrimmedValue(aValue: String);
      function GetIntegerValue: Int64;
      procedure SetIntegerValue(aValue: Int64);
      function GetKeyword: String;
      procedure SetKeyword(aValue: String);
    public
      constructor Create(aLine: String); overload;
      constructor Create(aKeyword: String; aValue: String); overload;
      constructor Create(aKeyword: String; aValue: Int64); overload;
      function GetAsLine(aLeadingSpaces: Integer = 0): String;
      property Keyword: String read GetKeyword write SetKeyword;                // Reading converts to lowercase. Writing trims whitespace.
      property KeywordDirect: String read fKeyword;                             // Reading is unfiltered. Writing acts same as Keyword property to prevent invalid values.
      property Value: String read fValue write fValue;                          // Reading and writing are unfiltered.
      property ValueTrimmed: String read GetTrimmedValue write SetTrimmedValue; // Reading and writing both trim whitespace.
      property ValueNumeric: Int64 read GetIntegerValue write SetIntegerValue;  // Reading and writing both convert to/from Int64 type.
  end;

  TParserSectionList = class(TObjectList)
    private
      function GetItem(Index: Integer): TParserSection;
    public
      constructor Create;
      function Add(Item: TParserSection): Integer;
      procedure Insert(Index: Integer; Item: TParserSection);
      property Items[Index: Integer]: TParserSection read GetItem; default;
      property List;
  end;

  TParserLineList = class(TObjectList)
    private
      function GetItem(Index: Integer): TParserLine;
    public
      constructor Create;
      function Add(Item: TParserLine): Integer;
      procedure Insert(Index: Integer; Item: TParserLine);
      property Items[Index: Integer]: TParserLine read GetItem; default;
      property List;
  end;

implementation

{ --- TParser --- }

constructor TParser.Create;
begin
  inherited;
  fMainSection := TParserSection.Create('main');
end;

destructor TParser.Destroy;
begin
  fMainSection.Free;
  inherited;
end;

procedure TParser.LoadFromFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmOpenRead);
  try
    F.Position := 0;
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TParser.LoadFromStream(aStream: TStream);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromStream(aStream);
    LoadFromStrings(SL);
  finally
    SL.Free;
  end;
end;

procedure TParser.LoadFromStrings(aStrings: TStrings);
var
  i: Integer;

  procedure TrimStrings;
  var
    i: Integer;
  begin
    for i := aStrings.Count-1 downto 0 do
      if Trim(aStrings[i]) = '' then
        aStrings.Delete(i);
  end;
begin
  TrimStrings;
  i := 0;
  fMainSection.LoadFromStrings(aStrings, i);
end;

procedure TParser.SaveToFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmCreate);
  try
    F.Position := 0;
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

procedure TParser.SaveToStream(aStream: TStream);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SaveToStrings(SL);
    SL.SaveToStream(aStream);
  finally
    SL.Free;
  end;
end;

procedure TParser.SaveToStrings(aStrings: TStrings);
begin
  fMainSection.SaveToStrings(aStrings, 0);
end;

{ --- TParserLine --- }

constructor TParserLine.Create(aLine: String);
var
  SplitPos: Integer;
begin
  inherited Create;
  aLine := TrimLeft(aLine);
  SplitPos := Pos(' ', aLine);
  fKeyword := MidStr(aLine, 1, SplitPos-1);
  fValue := MidStr(aLine, SplitPos+1, Length(aLine)-SplitPos);
end;

constructor TParserLine.Create(aKeyword: String; aValue: String);
begin
  inherited Create;
  Keyword := aKeyword;
  Value := aValue;
end;

constructor TParserLine.Create(aKeyword: String; aValue: Int64);
begin
  inherited Create;
  Keyword := aKeyword;
  Value := IntToStr(aValue);
end;

function TParserLine.GetTrimmedValue: String;
begin
  Result := Trim(fValue);
end;

procedure TParserLine.SetTrimmedValue(aValue: String);
begin
  fValue := Trim(aValue);
end;

function TParserLine.GetIntegerValue: Int64;
begin
  if not TryStrToInt64(fValue, Result) then
    raise EParserNumericError.Create('TParserLine.GetIntegerValue: "' + fValue + '" cannot be converted to an Int64');
end;

procedure TParserLine.SetIntegerValue(aValue: Int64);
begin
  fValue := IntToStr(aValue);
end;

function TParserLine.GetKeyword: String;
begin
  Result := Lowercase(fKeyword);
end;

procedure TParserLine.SetKeyword(aValue: String);
begin
  fKeyword := Trim(aValue);
end;

function TParserLine.GetAsLine(aLeadingSpaces: Integer = 0): String;
begin
  Result := StringOfChar(' ', aLeadingSpaces);
  Result := Result + fKeyword;
  if fValue = '' then Exit;
  Result := Result + ' ';
  Result := Result + fValue;
end;

{ --- TParserSection --- }

constructor TParserSection.Create(aKeyword: String);
begin
  inherited Create;
  fIterator := -1;
  Keyword := aKeyword;
end;

function TParserSection.GetKeyword: String;
begin
  Result := Lowercase(fKeyword);
end;

procedure TParserSection.SetKeyword(aValue: String);
begin
  fKeyword := Trim(aValue);
end;

procedure TParserSection.LoadFromStrings(aStrings: TStrings; var aPos: Integer);
var
  S: String;
begin
  while aPos < aStrings.Count do
  begin
    S := aStrings[aPos];
    Inc(aPos);
    if Trim(Lowercase(S)) = '$end' then
      Break
    else if LeftStr(Trim(Lowercase(S)), 1) = '$' then
      with TParserSection.Create(RightStr(Trim(Lowercase(S)), Length(Trim(S)) - 1)) do
        LoadFromStrings(aStrings, aPos)
    else
      fLines.Add(TParserLine.Create(S));
  end;
end;

procedure TParserSection.SaveToStrings(aStrings: TStrings; aIndent: Integer);
var
  i: Integer;
  Base: String;
begin
  for i := 0 to fLines.Count-1 do
    aStrings.Add(fLines[i].GetAsLine(aIndent));

  Base := StringOfChar(' ', aIndent);

  for i := 0 to fSections.Count-1 do
  begin
    aStrings.Add(Base + '$' + fSections[i].KeywordDirect);
    fSections[i].SaveToStrings(aStrings, aIndent + INDENT_PER_SECTION);
    aStrings.Add(Base + '$END');
    aStrings.Add('');
  end;

  aStrings.Add('');
end;

function TParserSection.DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fLines.Count-1 do
    if fLines[i].Keyword = aKeyword then
    begin
      aMethod(fLines[i]);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fSections.Count-1 do
    if fSections[i].Keyword = aKeyword then
    begin
      aMethod(fSections[i]);
      Inc(Result);
    end;
end;

{ --- TParserSectionList --- }

constructor TParserSectionList.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TParserSectionList.Add(Item: TParserSection): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TParserSectionList.Insert(Index: Integer; Item: TParserSection);
begin
  inherited Insert(Index, Item);
end;

function TParserSectionList.GetItem(Index: Integer): TParserSection;
begin
  Result := inherited Get(Index);
end;

{ --- TParserLineList --- }

constructor TParserLineList.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TParserLineList.Add(Item: TParserLine): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TParserLineList.Insert(Index: Integer; Item: TParserLine);
begin
  inherited Insert(Index, Item);
end;

function TParserLineList.GetItem(Index: Integer): TParserLine;
begin
  Result := inherited Get(Index);
end;


end.
