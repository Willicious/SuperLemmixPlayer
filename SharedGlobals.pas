unit SharedGlobals;

// For any global variables.

interface

uses
  {$ifdef logging}Dialogs,{$endif} Classes, SysUtils, Windows;

{$ifdef logging}
var
  DebugLog: TStringList;{$endif}

  // For writing to text log
  procedure DebugMsg(const aString: String);
  procedure Log(const aString: String);

  // For writing to Messages output
  procedure OutputMarker(aString: String);
  procedure Output(aString: String) overload;
  procedure Output(aString: String; i: Integer) overload;
  procedure Output(aString: String; aBool: Boolean) overload;

implementation

procedure Output(aString: String);
begin
  OutputDebugString(PChar(aString));
end;

procedure Output(aString: String; i: Integer);
begin
  OutputDebugString(PChar(aString + ' = ' + i.ToString));
end;

procedure Output(aString: String; aBool: Boolean);
var
  S: String;
begin
  if (aBool = True) then S := 'True' else S := 'False';
  OutputDebugString(PChar(aString + ' = ' + S));
end;

procedure OutputMarker(aString: String);
begin
  if aString = '' then aString := 'Marker';

  OutputDebugString(PChar('////////////////////////////////////////////////////////////////////'));
  OutputDebugString(PChar('///////////////////////////' + aString + '//////////////////////////'));
  OutputDebugString(PChar('////////////////////////////////////////////////////////////////////'));
end;

procedure Log(const aString: String);
begin
  {$ifdef logging}
  DebugLog.Add(aString);
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'superlemmix_logging.txt');
  {$endif}
end;

procedure DebugMsg(const aString: String);
begin
  {$ifdef logging}
  Log('DEBUG POPUP: ' + aString);
  ShowMessage(aString);
  {$endif}
end;

{$ifdef logging}
initialization
  DebugLog := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'superlemmix_logging.txt') then
    DebugLog.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'superlemmix_logging.txt');
  DebugLog.Add('** Begin session at ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now()));

finalization
  DebugLog.Add('----------------------------------------');
  DebugLog.Add('');
  DebugLog.SaveToFile(ExtractFilePath(ParamStr(0)) + 'superlemmix_logging.txt');
  DebugLog.Free;
{$endif}

end.