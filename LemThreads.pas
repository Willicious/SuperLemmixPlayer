unit LemThreads;

// Provides for a simple thread interface. This doesn't go to the full extent
// that multithreading could provide, but just provides an easier way to split
// up functions across multiple threads with minimal mess in the main code.

interface

uses
  Classes, SysUtils;

type
  TNeoLemmixThreadMethod = procedure(aPointer: Pointer = nil) of object;

  procedure CreateThread(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer = nil);

implementation

uses
  GameControl;

type
  TNeoLemmixThread = class(TThread)
    private
      fPointer: Pointer;
      fMethod: TNeoLemmixThreadMethod;
    protected
      procedure Execute; override;
    public
      constructor Create(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer);
  end;

procedure CreateThread(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer = nil);
begin
  if GameParams.MultiThreading then
    TNeoLemmixThread.Create(aMethod, aPointer)
  else
    aMethod(aPointer); // if multithreading disabled, do it in the main thread
end;

constructor TNeoLemmixThread.Create(aMethod: TNeoLemmixThreadMethod; aPointer: Pointer);
begin
  inherited Create(true);
  fMethod := aMethod;
  fPointer := aPointer;
  FreeOnTerminate := true;
  Resume;
end;

procedure TNeoLemmixThread.Execute;
begin
  fMethod(fPointer);
  Terminate;
end;

end.
