(* Originally by Eric Langedijk, but only CrLf, CountChars, StringToFile and
      GetApplicationPath still have their original code and are copyrighted by Eric.
   Nepster: But I wonder whether one can copyright such generic function that
            can be found everywhere on the internet.     *)

unit UMisc;

interface

uses
  StdCtrls, Windows, Classes, SysUtils, StrUtils;

const
  CrLf = Chr(13) + Chr(10);

// Counts the number of characters C in the string S
function CountChars(C: Char; const S: string): integer;

// Pads the string S to length aLen by adding PadChar to the left resp. right.
// If S is already longer than aLen, then it gets truncated.
function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;

// This is PadL(IntToStr(Int), Len, '0')
function LeadZeroStr(Int, Len: integer): string;

// Saves a string to a file
procedure StringToFile(const aString, aFileName: string);

// Create rect from origin / size
function SizedRect(const Left, Top, Width, Height: Integer): TRect;

// Computes the height resp. width of a rectangle.
function RectHeight(const aRect: TRect): integer;
function RectWidth(const aRect: TRect): integer;

// Same as AppPath, but callable from UMisc instead from LemTypes
function GetApplicationPath: string;

// Break string to wrap in a TLabel
function BreakString(S: String; aLabel: TLabel; aMaxWidth: Integer): String;

// Word-wrap a string
type
  TWordWrapArray = array of String;
function WordWrapString(const aString: String; const LineLen: Integer): TWordWrapArray;

implementation

function BreakString(S: String; aLabel: TLabel; aMaxWidth: Integer): String;
var
  ThisLine: String;
  PrevResult: String;
  SL: TStringList;
  n: Integer;
begin
  PrevResult := '';
  Result := '';

  SL := TStringList.Create;
  try
    SL.Delimiter := ' ';
    SL.StrictDelimiter := true;

    SL.DelimitedText := S;

    n := 0;
    ThisLine := '';

    while n < SL.Count do
    begin
      if n > 0 then
      begin
        ThisLine := ThisLine + ' ';
        Result := Result + ' ';
      end;

      ThisLine := ThisLine + SL[n];
      Result := Result + SL[n];

      if aLabel.Canvas.TextWidth(ThisLine) > aMaxWidth then
      begin
        Result := PrevResult + #13 + SL[n];
        ThisLine := SL[n];
      end;

      PrevResult := Result;

      Inc(n);
    end;
  finally
    SL.Free;
  end;
end;

function CountChars(C: Char; const S: string): integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then Inc(Result);
end;

function PadL(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  if Length(S) >= aLen then Result := RightStr(S, aLen)
  else Result := StringOfChar(PadChar, aLen - Length(S)) + S;
end;

function PadR(const S: string; aLen: integer; PadChar: char = ' '): string;
begin
  if Length(S) >= aLen then Result := LeftStr(S, aLen)
  else Result := S + StringOfChar(PadChar, aLen - Length(S));
end;

function LeadZeroStr(Int, Len: integer): string;
begin
  Result := IntToStr(Int);
  if Length(Result) < Len then
    Result := PadL(Result, Len, '0');
end;

procedure StringToFile(const aString, aFileName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add(aString);
    L.SaveToFile(aFileName);
  finally
    L.Free;
  end;
end;

function SizedRect(const Left, Top, Width, Height: Integer): TRect;
begin
  Result := Rect(Left, Top, Left+Width, Top+Height);
end;

function RectHeight(const aRect: TRect): integer;
begin
  Result := aRect.Bottom - aRect.Top;
end;

function RectWidth(const aRect: TRect): integer;
begin
  Result := aRect.Right - aRect.Left;
end;

function GetApplicationPath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function WordWrapString(const aString: String; const LineLen: Integer): TWordWrapArray;
var
  LineCount: Integer;
  CurrentPos: Integer;
  SplitPos: Integer;

  function FindSpace: Integer;
  begin
    if Length(aString) < CurrentPos + LineLen then
    begin
      Result := Length(aString) + 1;
      Exit;
    end;

    for Result := CurrentPos + LineLen downto CurrentPos + 1 do
      if aString[Result] = ' ' then
        Exit;
    Result := CurrentPos + LineLen;
  end;

  procedure CheckResultLength;
  begin
    if LineCount = Length(Result) then
      SetLength(Result, LineCount + 50);
  end;
begin
  LineCount := 0;
  CurrentPos := 1;

  repeat
    SplitPos := FindSpace;
    CheckResultLength;
    Result[LineCount] := Trim(MidStr(aString, CurrentPos, SplitPos - CurrentPos));
    CurrentPos := SplitPos + 1;
    Inc(LineCount);
  until CurrentPos > Length(aString);

  SetLength(Result, LineCount);
end;

end.


