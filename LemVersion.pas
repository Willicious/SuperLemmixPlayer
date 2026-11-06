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

function MakeVersionString(aFormat, aCore, aFeature, aHotfix: Integer): String;
function MakeVersionID(aFormat, aCore, aFeature, aHotfix: Integer): Int64;
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

function MakeVersionString(aFormat, aCore, aFeature, aHotfix: Integer): String;
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
  Result := IntToStr(aFormat);
  Result := Result + '.' + IntToStr(aCore);
  Result := Result + '.' + IntToStr(aFeature);
  {$ifdef rc}
  Result := Result + '-RC' + IntToStr(aHotfix);
  {$else}
  if aHotfix > 0 then
    Result := Result + '-' + NumberToLetters(aHotfix);
  {$endif}
end;

function MakeVersionID(aFormat, aCore, aFeature, aHotfix: Integer): Int64;
begin
  Result := aFormat;
  Result := (Result * 1000) + aCore;
  Result := (Result * 1000) + aFeature;
  Result := (Result * 1000) {$ifndef rc}+ aHotfix{$endif};
end;

function IsNewerVersion(const AvailableVersion: string): Boolean;
var
  Match: TMatch;
  FormatVersion, CoreVersion, FeatureVersion: Integer;
begin
  Match := TRegEx.Match(AvailableVersion, '^(\d+)\.(\d+)\.(\d+)$');

  if not Match.Success then
    raise Exception.Create(
      'Invalid release version: ' + AvailableVersion);

  FormatVersion := StrToInt(Match.Groups[1].Value);
  CoreVersion := StrToInt(Match.Groups[2].Value);
  FeatureVersion := StrToInt(Match.Groups[3].Value);

  Result := MakeVersionID(
    FormatVersion, CoreVersion, FeatureVersion, 0) > CurrentVersionID;
end;

end.
