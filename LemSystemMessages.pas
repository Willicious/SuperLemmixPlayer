unit LemSystemMessages;

// These will be needed even when SharedGlobals is no longer needed, hence the seperate unit.

interface

uses
  Messages,
  SharedGlobals;

const
  LM_START = WM_USER + 1;
  LM_NEXT = WM_USER + 2;
  LM_EXIT = WM_USER + 3;

var
  MainFormHandle: Integer;

implementation

end.