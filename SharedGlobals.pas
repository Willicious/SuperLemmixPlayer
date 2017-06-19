unit SharedGlobals;

// For any global variables.

interface

uses
  {$ifdef logging}Dialogs,{$endif} Classes, SysUtils;

{$ifdef logging}
var
  DebugLog: TStringList;{$endif}

  procedure DebugMsg(const aString: String);
  procedure Log(const aString: String);

implementation

procedure Log(const aString: String);
begin
  {$ifdef logging}
  DebugLog.Add(aString);
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
  {$endif}
end;

procedure DebugMsg(const aString: String);
begin
  {$ifdef logging}
  DebugLog.Add('DEBUG POPUP: ' + aString);
  ShowMessage(aString);
  {$endif}
end;

{$ifdef logging}
initialization
  DebugLog := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt') then
    DebugLog.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
  DebugLog.Add('** Begin session at ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now()));

finalization
  DebugLog.Add('----------------------------------------');
  DebugLog.Add('');
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
  DebugLog.Free;
{$endif}

end.