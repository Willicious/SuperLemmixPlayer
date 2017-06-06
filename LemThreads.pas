unit LemThreads;

// Provides for a simple thread interface. This doesn't go to the full extent
// that multithreading could provide, but just provides an easier way to split
// up functions across multiple threads with minimal mess in the main code.

interface

uses
  Contnrs, Classes, SysUtils;

type
  TNeoLemmixThreadMethod = procedure(aPointer: Pointer = nil) of object;

  TNeoLemmixThread = class(TThread)
    private
      fActive: Boolean;
      fEnding: Boolean;
      fPointer: Pointer;
      fMethod: TNeoLemmixThreadMethod;
      procedure Log(aText: String); // debug
    protected
      procedure Execute; override;
    public
      constructor Create(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer);
      property Active: Boolean read fActive write fActive;
      property Ending: Boolean read fEnding write fEnding;
      property Method: TNeoLemmixThreadMethod read fMethod write fMethod;
      property Data: Pointer read fPointer write fPointer;
  end;

  TNeoLemmixThreads = class(TObjectList)
    private
      function GetItem(Index: Integer): TNeoLemmixThread;
    public
      constructor Create;
      destructor Destroy; override;
      function Add(Item: TNeoLemmixThread): Integer;
      procedure ActivateAll;
      procedure TerminateAll;
      property Items[Index: Integer]: TNeoLemmixThread read GetItem; default;
      property List;
  end;

  procedure CreateThread(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer = nil);

implementation

uses
  Windows, // debug
  GameControl;

procedure CreateThread(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer = nil);
begin
  if GameParams.MultiThreading then
    with TNeoLemmixThread.Create(aMethod, aPointer) do
    begin
      Active := true;
      FreeOnTerminate := true;
    end
  else
    aMethod(aPointer); // if multithreading disabled, do it in the main thread
end;

constructor TNeoLemmixThread.Create(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer);
begin
  inherited Create(true);
  fMethod := aMethod;
  fPointer := aPointer;
  fActive := false;
  fEnding := false;
  Priority := tpNormal;
  Resume;
end;

procedure TNeoLemmixThread.Execute;
begin
  repeat
    if not fActive then
    begin
      Sleep(1);
      Continue;
    end;
    Log('Begin at ' + IntToStr(GetTickCount));
    fMethod(fPointer);
    Log('End at ' + IntToStr(GetTickCount));
    fActive := false;
  until fEnding or FreeOnTerminate;
  Terminate;
end;

procedure TNeoLemmixThread.Log(aText: string);
var
  SL: TStringList;
begin
  (*SL := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + IntToHex(Integer(@fMethod), 16) + '.txt') then
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + IntToHex(Integer(@fMethod), 16) + '.txt');
  SL.Add(aText);
  SL.SaveToFile(ExtractFilePath(ParamStr(0)) + IntToHex(Integer(@fMethod), 16) + '.txt');*)
end;

{ TNeoLemmixThreads }

constructor TNeoLemmixThreads.Create;
begin
  inherited Create(true);
end;

destructor TNeoLemmixThreads.Destroy;
begin
  TerminateAll;
  inherited;
end;

function TNeoLemmixThreads.Add(Item: TNeoLemmixThread): Integer;
begin
  Result := inherited Add(Item);
end;

function TNeoLemmixThreads.GetItem(Index: Integer): TNeoLemmixThread;
begin
  Result := inherited Get(Index);
end;

procedure TNeoLemmixThreads.ActivateAll;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    if GameParams.MultiThreading then
      Items[i].Active := true
    else begin
      Items[i].Log('Begin at ' + IntToStr(GetTickCount));
      Items[i].Method(Items[i].Data);
      Items[i].Log('End at ' + IntToStr(GetTickCount));
    end;
end;

procedure TNeoLemmixThreads.TerminateAll;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Items[i].Ending := true;

  i := 0;
  while i < Count do
    if Items[i].Terminated then
      Inc(i)
    else
      Sleep(1);

end;


end.
