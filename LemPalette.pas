{$include lem_directives.inc}
unit LemPalette;

interface

uses
  System.SysUtils, Windows,
  LemNeoParser,
  GR32,
  SharedGlobals;

const
  COLOR_CYCLE = TColor32($00FFFFFF); // Fully transparent color treated as cycle

function IsCycleColor(Color: TColor32): Boolean;
function ResolveColor(aColor: TColor32): TColor32;
function MakeColorCycle: TColor32;
function ParseColor32(Sec: TParserSection; const Key: String; Default: TColor32): TColor32;

implementation

function IsCycleColor(Color: TColor32): Boolean;
begin
  Result := (Color and $FF000000) = 0;
end;

function ResolveColor(aColor: TColor32): TColor32;
begin
  if (aColor = COLOR_CYCLE) then
    Result := MakeColorCycle
  else
    Result := aColor;
end;

function MakeColorCycle: TColor32;
begin
  var H := GetTickCount mod 5000;
  Result := HSVToRGB(H / 5000, 1, 0.75);
end;

function ParseColor32(Sec: TParserSection; const Key: String; Default: TColor32): TColor32;
var
  Value: UInt32;
  S: String;
begin
  S := Trim(Sec.LineString[Key]);
  S := Trim(S);

  if SameText(S, 'CYCLE') or SameText(S, '$CYCLE') then
    Exit(COLOR_CYCLE);

  try
    Value := StrToUInt(S);

    if IsCycleColor(Value) then
      Exit(COLOR_CYCLE);

    Result := TColor32(Value);
  except
    Result := Default;
  end;
end;

end.

