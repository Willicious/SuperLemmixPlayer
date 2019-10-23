unit LemVersion;

// Contains constants and functions relating to version numbers.

interface

uses
  UMisc, Classes, SysUtils;

const
  FORMAT_VERSION = 12;
  CORE_VERSION = 7;
  FEATURES_VERSION = 0;
  HOTFIX_VERSION = 4; // or RC version

  function COMMIT_ID: String;

function MakeVersionString(aFormat, aCore, aFeature, aHotfix: Integer): String;
function MakeVersionID(aFormat, aCore, aFeature, aHotfix: Integer): Int64;
function CurrentVersionString: String;
function CurrentVersionID: Int64;

implementation

uses
  LemVersionCID;

function COMMIT_ID: String;
begin
  Result := LemVersionCID.COMMIT_ID;
end;

function CurrentVersionString: String;
begin
  Result := MakeVersionString(FORMAT_VERSION, CORE_VERSION, FEATURES_VERSION, HOTFIX_VERSION);
end;

function CurrentVersionID: Int64;
begin
  Result := MakeVersionID(FORMAT_VERSION, CORE_VERSION, FEATURES_VERSION, HOTFIX_VERSION);
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
  Result := Result + '.' + LeadZeroStr(aCore, 2);
  Result := Result + '.' + LeadZeroStr(aFeature, 2);
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

end.