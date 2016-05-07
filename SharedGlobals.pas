unit SharedGlobals;

// For any global variables.

interface

uses
  Classes, SysUtils;

var
  GameFile: String;
  {$ifdef profile_parser}ProfilingList: TStringList;{$endif}

implementation


initialization
{$ifdef profile_parser}
  ProfilingList := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'neolemmix_profiling.txt') then
    ProfilingList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_profiling.txt');
  ProfilingList.Add('** Begin session at ' + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now()));
{$endif}

finalization
{$ifdef profile_parser}
  ProfilingList.Add('----------------------------------------');
  ProfilingList.Add('');
  ProfilingList.SaveToFile(ExtractFilePath(ParamStr(0)) + 'neolemmix_profiling.txt');
  ProfilingList.Free;
{$endif}

end.