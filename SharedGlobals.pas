unit SharedGlobals;

// For any global variables.

interface

uses
  {$ifdef logging}Dialogs,{$endif} Classes, SysUtils;

var
  GameFile: String;
  {$ifdef logging}DebugLog: TStringList;

  procedure Log(aString: String);
  procedure DebugMsg(aString: String);{$endif}

implementation

{$ifdef logging}
procedure Log(aString: String);
begin
  DebugLog.Add(aString);
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_logging.txt');
end;

procedure DebugMsg(aString: String);
begin
  DebugLog.Add('DEBUG POPUP: ' + aString);
  ShowMessage(aString);
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