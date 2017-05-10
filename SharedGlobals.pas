unit SharedGlobals;

// For any global variables.

interface

uses
  Classes, SysUtils;

var
  GameFile: String;
  {$ifdef logging}DebugLog: TStringList;

  procedure Log(aString: String);{$endif}

implementation

{$ifdef logging}
procedure Log(aString: String);
begin
  DebugLog.Add(aString);
end;
{$endif}

initialization
{$ifdef logging}
  DebugLog := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt') then
    DebugLog.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
  DebugLog.Add('** Begin session at ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now()));
{$endif}

finalization
{$ifdef logging}
  DebugLog.Add('----------------------------------------');
  DebugLog.Add('');
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
  DebugLog.Free;
{$endif}

end.