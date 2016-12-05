unit GSCDebug;

interface

uses
  Classes, SysUtils;

var
  DebugSL: TStringList;

  procedure Log(aValue: String);

implementation

procedure Log(aValue: String);
var
  OldPath: String;
begin
  {$ifndef debug}Exit;{$endif}
  if DebugSL = nil then DebugSL := TStringList.Create;
  OldPath := GetCurrentDir;

  DebugSL.Add(aValue);
  DebugSL.SaveToFile(ChangeFileExt(ParamStr(0), '_log.txt'));

  SetCurrentDir(OldPath);
end;

end.