unit LemVersion;

// Contains constants and functions relating to version numbers.

interface

uses
  UMisc, Classes, SysUtils, RegularExpressions,
  SharedGlobals;

const
  MAJOR_VERSION = 3;
  MINOR_VERSION = 0;
  HOTFIX_VERSION = 4;
  RC_VERSION = 0;

  function COMMIT_ID: String;

function MakeVersionString(aMajor, aMinor, aHotfix, aRC: Integer): String;
function MakeVersionID(aMajor, aMinor, aHotfix, aRC: Integer): Int64;
function CurrentVersionString: String;
function CurrentVersionID: Int64;
function IsNewerVersion(const AvailableVersion: string): Boolean;

implementation

uses
  LemVersionCommitID;

function COMMIT_ID: String;
begin
  Result := LemVersionCommitID.COMMIT_ID;
end;

function CurrentVersionString: String;
begin
  Result := MakeVersionString(MAJOR_VERSION, MINOR_VERSION, HOTFIX_VERSION, RC_VERSION);
end;

function CurrentVersionID: Int64;
begin
  Result := MakeVersionID(MAJOR_VERSION, MINOR_VERSION, HOTFIX_VERSION, RC_VERSION);
end;

function MakeVersionString(aMajor, aMinor, aHotfix, aRC: Integer): String;
  function NumberToLetters(aValue: Integer): String;
  var
    n: Integer;
  begin
    Result := '';
    repeat
      n := aValue mod 26;
      Result := Char(n + 64) + Result;
      aValue := aValue div 26;
    until aValue = 0;
  end;
begin
  Result := IntToStr(aMajor);
  Result := Result + '.' + IntToStr(aMinor);

  if aHotfix <> 0 then
    Result := Result + '.' + IntToStr(aHotfix);

  {$ifdef rc}
  Result := Result + '-RC' + IntToStr(aRC);
  {$endif}
end;

function MakeVersionID(aMajor, aMinor, aHotfix, aRC: Integer): Int64;
begin
  Result := aMajor;
  Result := (Result * 1000) + aMinor;
  Result := (Result * 1000) + aHotfix;
  Result := (Result * 1000) {$ifndef rc}+ aRC{$endif};
end;

function IsNewerVersion(const AvailableVersion: string): Boolean;
var
  Match: TMatch;
  Major, Minor, Hotfix: Integer;
begin
  Match := TRegEx.Match(AvailableVersion, '^(\d+)\.(\d+)\.(\d+)$');

  if not Match.Success then
    raise Exception.Create(
      'Invalid release version: ' + AvailableVersion);

  Major := StrToInt(Match.Groups[1].Value);
  Minor := StrToInt(Match.Groups[2].Value);
  Hotfix := StrToInt(Match.Groups[3].Value);

  Result := MakeVersionID(Major, Minor, Hotfix, 0) > CurrentVersionID;
end;

end.
