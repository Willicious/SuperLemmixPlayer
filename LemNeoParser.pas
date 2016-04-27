unit LemNeoParser;

(*
Contains code for reading NeoLemmix text format files. These have various
four-letter extensions, always beginning with nx.

eg: .nxlv (Level)
    .nxli (Level item: eg terrain piece, object)
    .nxsv (Save file)

// // // Text file format // // //

The exact contents may differ between the specific uses, but the
general structure is as follows, with either CR+LF or LF newlines
being supported.

All lines are interpreted as a keyword (the first series of non-whitespace
characters in the line) and a number of parameters (every other series of
non-whitespace characters in the line). Parameters are seperated from the
keyword, and each other, by whitespace (either spaces or tabs).

"String mode" is invoked whenever a " is encountered, and lasts until another
" is encountered. In "string mode", whitespace is not treated as seperating
parameters. In other words, if we look at these two lines:

a. BLAH this has four parameters
b. BLAH "this has one parameter"

In the second, the entire contents of the "" marks is treated as a single
parameter. For the record, the "" marks themself are not considered to be
part of the parameter.

There are five special cases that can occur other than string mode. The first
two can occur anywhere, including inside a string delimited by " marks.
  ""  - This inserts a " character itself into the keyword / parameter
  "n  - This inserts a newline character into the keyword / parameter (not case-sensitive)

The other three only have an effect when they are the first non-whitespace character
of a line.
  ~   - The line will be appended to the previous line instead of acting as its own line
  #   - The line is treated as a comment, and is ignored
  $   - The line provides information used by the parser, and is not passed to the loading format

*)

interface

uses
  Classes, SysUtils, StrUtils;

type
  TNeoLoadableItem = class
    // All items likely to be loaded from these files should be descended from
    // this class. This is to ensure it has save and load routines available,
    // as well as to provide (without needing to re-code it each time) a mechanism
    // to store unknown lines from the file.

  end;

  TNeoFileLine = class
    private
      fKeyword: String;
      fParamList: array of String;
      fParamCount: Integer;
      //function GetParameterStr(aIndex: Integer): String;
      //function GetParameterInt(aIndex: Integer): Integer;
      //function GetLineText: String;
    protected
      procedure SetKeyword(const aKeyword: String);
    public
      constructor Create(const aKeyword: String);
      constructor CreateFromLine(const aLine: String);
      property Keyword: String read fKeyword;
      //property StrParameter[Index: Integer]: String read GetParameterStr;
      //property IntParameter[Index: Integer]: Integer read GetParameterInt;
      //property Text: String read GetLineText;
  end;

// Need to:
//  -- Provide a loading / reading class
  TNeoFileReader = class
    private
      fSrcPath: String;
      fSrcFile: String;
    public
      property SrcPath: String read fSrcPath;
      property SrcFile: String read fSrcFile;
  end;

// -- Provide a saving / writing class - is handled very differently
  TNeoFileWriter = class
    private
      fDstPath: String;
      fDstFile: String;
    public
      property DstPath: String read fDstPath write fDstPath;
      property DstFile: String read fDstFile write fDstFile;
  end;

  procedure RemoveFluff(aStringList: TStrings);

implementation

// // Standalone procedures // //

procedure RemoveFluff(aStringList: TStrings);
var
  i, i2: Integer;
  OldStr, NewStr: String;
  StringMode, JustHadSpace, SkipNext, FirstCharOfLine: Boolean;

  function NextLine: String;
  begin
    if i = aStringList.Count-1 then
      Result := ''
    else
      Result := aStringList[i+1];
  end;

begin

  // First step - strip out fluff spacing
  StringMode := false;
  for i := 0 to aStringList.Count-1 do
  begin
    OldStr := aStringList[i];
    NewStr := '';
    JustHadSpace := true; // start of line pretty much behaves the same way as far as tidyup is concerned
    SkipNext := false;
    FirstCharOfLine := false;
    for i2 := 1 to Length(OldStr) do
    begin
      if ((OldStr[i2] = ' ') or (OldStr[i2] = #9)) and (FirstCharOfLine or not StringMode) then
      begin
        if JustHadSpace then Continue;
        NewStr := NewStr + ' ';
        JustHadSpace := true;
        Continue;
      end;

      JustHadSpace := false;

      if FirstCharOfLine then
      begin
        if OldStr[i2] <> '~' then
          StringMode := false // Stringmode only carries over to a new line if it continues current line
        else begin
          NewStr := NewStr + '~ ';
          Continue;
        end;
        FirstCharOfLine := false;
      end;

      if OldStr[i2] = '"' then
      begin
        if (i2 = Length(OldStr)) or (LowerCase(OldStr[i2+1]) <> 'n') then
          StringMode := not StringMode;
        // What about special case "" ? Truth is - this gets covered automatically if you think about it!
        // So only "n needs to be coded for.
      end;

      NewStr := NewStr + OldStr[i2];

    end;
    if not StringMode then NewStr := Trim(NewStr); // Remove any spacing that may exist at the end
    aStringList[i] := NewStr;
  end;

  // Second step - combine multi-line statements into a single line
  i := 0;
  while i < aStringList.Count-1 do // -1 is correct - we never need to combine on the last line!
  begin
    if aStringList[i+1][1] = '~' then
    begin
      NewStr := aStringList[i+1];
      Delete(NewStr, 1, 1);
      aStringList[i] := aStringList[i] + NewStr;
      aStringList.Delete(i+1);
    end else
      Inc(i);
  end;

  // Third step - remove comments and blank lines
  i := 0;
  while i < aStringList.Count do // Here, we DO want to include the final line
  begin
    if (Length(aStringList[i]) = 0) or (aStringList[i][1] = '#') then
      aStringList.Delete(i)
    else
      Inc(i);
  end;

end;

// // TNeoFileLine // //

constructor TNeoFileLine.Create(const aKeyword: String);
begin
  inherited Create;
  SetKeyword(aKeyword);
  SetLength(fParamList, 0);
end;

constructor TNeoFileLine.CreateFromLine(const aLine: String);
var
  // Basic parsing control
  c: Char;
  p: PChar;
  i: Integer;
  s: String;
  InputLength: Integer;

  // For string parsing
  StringMode: Boolean;
  Skip: Boolean;

  procedure AddParameter(aParam: String);
  begin

  end;
begin
  // Main parsing code of lines goes here.
  InputLength := Length(aLine);
  p := @aLine[1];
  s := '';
  StringMode := false;
  Skip := false;
  for i := 1 to InputLength do
  begin
    try
      if Skip then Continue;
      c := p^;
      if (c in [#09, ' ']) and not StringMode then
      begin
        if s = '' then Continue;
        if fKeyword = '' then
          fKeyword := LowerCase(s)
        else
          AddParameter(s);
        s := '';
        Continue;
      end;
      if c = '"' then
      begin
        if not StringMode then
          StringMode := true
        else begin
          if (i < InputLength) and (aLine[i+1] = '"') then
          begin
            s := s + '"';
            Skip := true; // Skip the next character, we've just checked it
          end else
            StringMode := false;
        end;
        Continue;
      end;
      s := s + c;
    finally
      Inc(p);
    end;
  end;
end;

procedure TNeoFileLine.SetKeyword(const aKeyword: String);
begin
  // Strips out any spaces or tabs
  fKeyword := aKeyword;
  fKeyword := StringReplace(fKeyword, ' ', '', [rfReplaceAll]);
  fKeyword := StringReplace(fKeyword, #09, '', [rfReplaceAll]);
end;

end.
