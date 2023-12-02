unit LemNeoParser;

(*

Handles parsing text-based data files.

--- General Format ---

Blank lines are ignored completely. Whitespace at the start of a line (before the first non-whitespace character)
is also ignored, but whitespace after this is NOT ignored.

A regular line is in the format of a keyword (not case-sensitive). This may optionally be followed by one space and
then a value, but if the keyword does not need a value, then none needs to be included (nor does the space).

A sub-section can also be declared. Lines within the sub-section are not found in the list (or iterators) of the main
section, and vice versa. To declare a subsection, a line should start with a $ symbol, followed by the keyword for the
sub-section (it cannot also have a value). The subsection should be ended with "$end" (not case-sensitive). Subsections
can be nested within each other if nessecary.

How to specifically interpret the lines / sections is dependant on the specific file; TParser simply provides a means
of parsing the file into keyword / value pairs and seperate subsections.

--- Usage Notes ---

>> General
Make sure that if StrUtils is used in the same unit as this, LemNeoParser comes AFTER StrUtils in the "Uses" clause. This
is because StrUtils also has a class called TParser. Why didn't I rename it? Because nowhere in the code is StrUtils' TParser
ever used, and for a frequently-used class like this, having a simple name is important.

>> Loading
Create a TParser object and load the file into it (can also load from a stream or TStringList). <TParser>.MainSection
holds the "main" section, which all lines that aren't in a sub-section are considered part of. <TParser>.MainSection
and any sub-sections of it are TParserSection objects - beyond existing as <TParser>.MainSection, the main section has
nothing special about it, although the keyword for it is never loaded or saved to a file, nor is there any guarantee
it will have a reliable value.
Although direct access is possible, the recommended ways to get lines or subsections are:
  In the case that only one occurance is expected within the section:
    Use <TParserSection>.Line[$$$$] (returns a TParserLine) where $$$$ is the keyword, to get a line (returns nil if not found)
    Use <TParserSection>.LineString[$$$$] (returns a String) where $$$$ is the keyword, to get the corresponding value (returns empty string if not found)
    Use <TParserSection>.LineTrimString[$$$$] (returns a String) where $$$$ is the keyword, for same as above but with leading / trailing whitespace removed
    Use <TParserSection>.LineNumeric[$$$$] (returns an Int64) where $$$$ is the keyword, to get the corresponding numeric value (returns 0 if not found)
    Use <TParserSection>.Section[$$$$] (returns a TParserSection) where $$$$ is the keyword, to get a section
    In the event that more than one line / section with the keyword exist, the LAST one in the file is returned.
  In the case that multiple occurances may be expected:
    Define a procedure (may be private) in the class that's loading the file, of the following format. This can
    either be a procedure of the object itself, or a sub-procedure of another method.
      procedure <name>(aLine: TParserLine; const aIteration: Integer);
      procedure <name>(aLine: TParserLine; const aIteration: Integer; aData: Pointer);
      procedure <name>(aSection: TParserSection; const aIteration: Integer);
      procedure <name>(aSection: TParserSection; const aIteration: Integer; aData: Pointer);
    You can then use the following calls to run this procedure once for each line:
      <TParserSection>.DoForEachLine($$$$, <name>[, <pointer>]);
      <TParserSection>.DoForEachSection($$$$, <name>[, <pointer>]);
    This effectively works like the following code would be expected to if it were valid:
      for each Item := TParserLine in <TParserSection>.LineList do
        <name>(Item, # of previous Item found[, <pointer>]);
    The pointer, if used, is not used by DoForEachXXXX itself, but simply passed to the function it calls.

>> Saving
Create a TParser object. The main section will be created, but empty, and can be accessed as <TParser>.MainSection.
You can add lines to a TParserSection as follows:
  <TParserSection>.AddLine($$$$);
  <TParserSection>.AddLine($$$$, $$$$);
    The first $$$$ is the keyword, the second is the value. Either a String or an Int64 is accepted for the value. If the
    value is an empty string, it will not be added; to add a line with no value specified, omit the value altogether rather
    than leaving it empty.
    When using a numeric value, you can also pass a third parameter (optional). If a positive nonzero value is passed, the
    value will be written to the file in hexidecimal with that many digits; if zero or blank, it will be written in decimal.
Adding a new section is a tiny bit trickier. First, the section must be created and assigned to a temporary variable:
  <TParserSection 2> := <TParserSection>.SectionList.Add($$$$);
    The $$$$ is the section's keyword.
  You can then manipluate <TParserSection 2> the same way as any other TParserSection.
Once all is done, simply call TParser.SaveToFile (or SaveToStream).

>> Modifying
Don't. Load the data into the actual class that's meant to use it, then re-save it.

*)

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

  TForEachLineProcedure1 = reference to procedure(aLine: TParserLine; const aIteration: Integer);
  TForEachLineProcedure2 = procedure(aLine: TParserLine; const aIteration: Integer) of object; // 1 & 2 is a kludge until I convert all code of this type to using anon methods
  TForEachSectionProcedure1 = reference to procedure(aSection: TParserSection; const aIteration: Integer);
  TForEachSectionProcedure2 = procedure(aSection: TParserSection; const aIteration: Integer) of object;
  TForEachLinePointerProcedure = procedure(aLine: TParserLine; const aIteration: Integer; aData: Pointer) of object;
  TForEachSectionPointerProcedure = procedure(aSection: TParserSection; const aIteration: Integer; aData: Pointer) of object;

  TParser = class
    private
      fMainSection: TParserSection;
      procedure LoadFromStreamInternal(aStream: TStream; aCacheName: String);
    public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

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
      function GetLine(aKeyword: String): TParserLine;
      function GetSection(aKeyword: String): TParserSection;

      function GetLineString(aKeyword: String): String;
      function GetLineTrimString(aKeyword: String): String;
      function GetLineNumeric(aKeyword: String): Int64;
      function GetLineNumericDefault(aKeyword: String; aDefault: Int64): Int64;

      procedure LoadFromStrings(aStrings: TStrings; var aPos: Integer);
      procedure SaveToStrings(aStrings: TStrings; aIndent: Integer);
    public
      constructor Create(aKeyword: String);
      destructor Destroy; override;

      function DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure1): Integer; overload;
      function DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure2): Integer; overload;
      function DoForEachLine(aKeyword: String; aMethod: TForEachLinePointerProcedure; aData: Pointer): Integer; overload;
      function DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure1): Integer; overload;
      function DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure2): Integer; overload;
      function DoForEachSection(aKeyword: String; aMethod: TForEachSectionPointerProcedure; aData: Pointer): Integer; overload;

      procedure AddLine(aKeyword: String); overload;
      procedure AddLine(aKeyword: String; aValue: String); overload;
      procedure AddLine(aKeyword: String; aValue: Int64; HexLength: Integer = 0); overload;

      property Keyword: String read GetKeyword write SetKeyword;
      property KeywordDirect: String read fKeyword write SetKeyword;

      property Section[Keyword: String]: TParserSection read GetSection;
      property Line[Keyword: String]: TParserLine read GetLine;

      property LineString[Keyword: String]: String read GetLineString;
      property LineTrimString[Keyword: String]: String read GetLineTrimString;
      property LineNumeric[Keyword: String]: Int64 read GetLineNumeric;
      property LineNumericDefault[Keyword: String; Default: Int64]: Int64 read GetLineNumericDefault;

      property SectionList: TParserSectionList read fSections;
      property LineList: TParserLineList read fLines;
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
      function Add(Item: TParserSection): Integer; overload;
      function Add(aKeyword: String): TParserSection; overload;
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

uses
  GameControl,
  Generics.Collections;

type
  TStringListCache = TObjectDictionary<string, TStringList>;

var
  SlCache: TStringListCache;

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

procedure TParser.Clear;
begin
  fMainSection.Free;
  fMainSection := TParserSection.Create('main');
end;

procedure TParser.LoadFromFile(aFile: String);
var
  F: TFileStream;
begin
  if (not GameParams.FileCaching) or (not SlCache.ContainsKey(aFile)) then
  begin
    F := TFileStream.Create(aFile, fmOpenRead);
    try
      F.Position := 0;
      if not GameParams.FileCaching then aFile := ''; // Prevents caching, see code of LoadFromStreamInternal
      LoadFromStreamInternal(F, aFile);
    finally
      F.Free;
    end;
  end else
    LoadFromStrings(SlCache[aFile]);
end;

procedure TParser.LoadFromStream(aStream: TStream);
begin
  LoadFromStreamInternal(aStream, '');
end;

procedure TParser.LoadFromStreamInternal(aStream: TStream; aCacheName: String);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromStream(aStream);
    LoadFromStrings(SL);
  finally
    if aCacheName = '' then
      SL.Free
    else
      SlCache.Add(aCacheName, SL);
  end;
end;

procedure TParser.LoadFromStrings(aStrings: TStrings);
var
  i: Integer;

  procedure TrimStrings;
  var
    i: Integer;
    S: String;
  begin
    for i := aStrings.Count-1 downto 0 do
    begin
      S := Trim(aStrings[i]);
      if (S = '') or (LeftStr(S, 1) = '#') then
        aStrings.Delete(i);
    end;
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
  if SplitPos = 0 then
    fKeyword := aLine
  else begin
    fKeyword := MidStr(aLine, 1, SplitPos-1);
    fValue := MidStr(aLine, SplitPos+1, Length(aLine)-SplitPos);
  end;
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
  fKeyword := Trim(Uppercase(aValue));
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
  fSections := TParserSectionList.Create;
  fLines := TParserLineList.Create;  
  Keyword := aKeyword;
end;

destructor TParserSection.Destroy;
begin
  fSections.Free;
  fLines.Free;
  inherited;
end;

function TParserSection.GetKeyword: String;
begin
  Result := Lowercase(fKeyword);
end;

procedure TParserSection.SetKeyword(aValue: String);
begin
  fKeyword := Trim(Uppercase(aValue));
end;

function TParserSection.GetLine(aKeyword: String): TParserLine;
var
  i: Integer;
begin
  Result := nil;
  for i := fLines.Count-1 downto 0 do
    if fLines[i].Keyword = Lowercase(aKeyword) then
    begin
      Result := fLines[i];
      Exit;
    end;
end;

function TParserSection.GetSection(aKeyword: String): TParserSection;
var
  i: Integer;
begin
  Result := nil;
  for i := fSections.Count-1 downto 0 do
    if fSections[i].Keyword = Lowercase(aKeyword) then
    begin
      Result := fSections[i];
      Exit;
    end;
end;

function TParserSection.GetLineString(aKeyword: String): String;
var
  Line: TParserLine;
begin
  Line := GetLine(aKeyword);
  if Line = nil then
    Result := ''
  else
    Result := Line.Value;
end;

function TParserSection.GetLineTrimString(aKeyword: String): String;
var
  Line: TParserLine;
begin
  Line := GetLine(aKeyword);
  if Line = nil then
    Result := ''
  else
    Result := Line.ValueTrimmed;
end;

function TParserSection.GetLineNumeric(aKeyword: string): Int64;
begin
  Result := GetLineNumericDefault(aKeyword, 0);
end;

function TParserSection.GetLineNumericDefault(aKeyword: String; aDefault: Int64): Int64;
var
  Line: TParserLine;
begin
  Line := GetLine(aKeyword);
  if Line = nil then
    Result := aDefault
  else
    Result := Line.ValueNumeric;
end;

procedure TParserSection.AddLine(aKeyword: String);
begin
  fLines.Add(TParserLine.Create(aKeyword, ''));
end;

procedure TParserSection.AddLine(aKeyword: String; aValue: String);
begin
  if aValue = '' then Exit;
  fLines.Add(TParserLine.Create(aKeyword, aValue));
end;

procedure TParserSection.AddLine(aKeyword: String; aValue: Int64; HexLength: Integer = 0);
begin
  if HexLength > 0 then
    fLines.Add(TParserLine.Create(aKeyword, 'x' + IntToHex(aValue, HexLength)))
  else
    fLines.Add(TParserLine.Create(aKeyword, aValue));
end;

procedure TParserSection.LoadFromStrings(aStrings: TStrings; var aPos: Integer);
var
  S: String;
  NewSection: TParserSection;
begin
  while aPos < aStrings.Count do
  begin
    S := aStrings[aPos];
    Inc(aPos);
    if Trim(Lowercase(S)) = '$end' then
      Break
    else if LeftStr(Trim(Lowercase(S)), 1) = '$' then
    begin
      NewSection := TParserSection.Create(RightStr(Trim(Lowercase(S)), Length(Trim(S)) - 1));
      NewSection.LoadFromStrings(aStrings, aPos);
      fSections.Add(NewSection);
    end else
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

  if fSections.Count > 0 then
    aStrings.Add('');

  Base := StringOfChar(' ', aIndent);

  for i := 0 to fSections.Count-1 do
  begin
    aStrings.Add(Base + '$' + fSections[i].KeywordDirect);
    fSections[i].SaveToStrings(aStrings, aIndent + INDENT_PER_SECTION);
    aStrings.Add(Base + '$END');
    aStrings.Add('');
  end;

end;

function TParserSection.DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure1): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fLines.Count-1 do
    if fLines[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fLines[i], Result);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachLine(aKeyword: String; aMethod: TForEachLineProcedure2): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fLines.Count-1 do
    if fLines[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fLines[i], Result);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachLine(aKeyword: String; aMethod: TForEachLinePointerProcedure; aData: Pointer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fLines.Count-1 do
    if fLines[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fLines[i], Result, aData);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure1): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fSections.Count-1 do
    if fSections[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fSections[i], Result);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachSection(aKeyword: String; aMethod: TForEachSectionProcedure2): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fSections.Count-1 do
    if fSections[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fSections[i], Result);
      Inc(Result);
    end;
end;

function TParserSection.DoForEachSection(aKeyword: String; aMethod: TForEachSectionPointerProcedure; aData: Pointer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to fSections.Count-1 do
    if fSections[i].Keyword = Lowercase(aKeyword) then
    begin
      aMethod(fSections[i], Result, aData);
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

function TParserSectionList.Add(aKeyword: String): TParserSection;
begin
  Result := TParserSection.Create(aKeyword);
  Add(Result);
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

initialization

  SlCache := TStringListCache.Create([doOwnsValues]);

finalization

  SlCache.Free;

end.
