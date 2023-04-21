unit LemGameMessageQueue;

// Why this unit? Ideally, LemGame should be purely a physics processor; interface stuff should be taken care of
// by TGameWindow or similar. But, there are some cases where the physics processor has to notify the interface
// of what to do, for example, to play a sound, or to exit gameplay. Some of these are currently handled by
// LemGame itself - not good! Others are communicated to TGameWindow, but via specialized methods in cases where
// something more generic like this could handle it. So, this TGameMessageQueue class is designed so that
// LemGame can add something here, and after the next physics update (or at any needed time), TGameWindow can
// check the queue and act on anything it needs to - or just discard messages it doesn't need. And if the LemGame
// is being run from something that doesn't give visual feedback, such as a hypothetical future dedicated replay
// tester that doesn't just have preview screen and TGameWindow kludges to run? Then the messages can be ignored
// entirely.

// This could even be implemented as a two-way thing - one for LemGame to send messages to TGameWindow, and another
// for TGameWindow to send messages to LemGame. I don't know how often this would be needed, though.

// It is not intended to be used as something to hold data for later usage. This is why it's been written so that
// when a message is read, it's deleted from the queue.

// Do not hardcode any values. Use the consts provided here. This way we can change their values if needed without breaking code.

// Correct usage is in a "while <TGameMessageQueue>.HasMessages do" loop. The queue will be reset when this is checked with no
// messages remaining. Attempting to read messages beyond the last one that exists will return a GAMEMSG_NIL and reset the queue,
// but this cannot be distinguished from a GAMEMSG_NIL that was intentionally inserted in the queue except via using HasMessages.

interface

uses
  Classes, SysUtils;

const
  GAMEMSG_NIL = 0;      // Does nothing.

  GAMEMSG_FINISH = 1;   // Signifies that gameplay has ended. DataInt: 0 = unknown reason, 1 = no lemmings left, 2 = <removed>, 3 = terminated
    GM_FIN_UNKNOWN = 0;
    GM_FIN_LEMMINGS = 1;
    //GM_FIN_TIME = 2;  // No longer used.
    GM_FIN_TERMINATE = 3;

  GAMEMSG_SOUND = 10;       // Plays a sound. DataStr: Filename of sound to play, without any extension.
  GAMEMSG_SOUND_BAL = 11;   // Plays a sound. DataStr: Filename of sound to play, without any extension. DataInt: X coordinate of origin.
  GAMEMSG_MUSIC = 12;       // Starts music if not already playing.
  GAMEMSG_SOUND_FREQ = 13;

type
  TGameMessage = record
    MessageType:    Integer;
    MessageDataStr:    String;
    MessageDataInt:    Int64;
  end;

  TGameMessageQueue = class
    private
      fCurrentReadEntry: Integer;
      fQueueEntryCount: Integer;
      fQueueEntries: array of TGameMessage;
      function GetMessage: TGameMessage;
      function GetHasMessages: Boolean;
    public
      constructor Create;
      // no special destructor needed due to using an array type rather than an object
      procedure Add(aType: Integer); overload;
      procedure Add(aType: Integer; aDataStr: String); overload;
      procedure Add(aType: Integer; aDataInt: Int64); overload;
      procedure Add(aType: Integer; aDataStr: String; aDataInt: Int64); overload;
      procedure Add(aType: Integer; aDataInt: Int64; aDataStr: String); overload;
      procedure Clear;
      property NextMessage: TGameMessage read GetMessage;
      property HasMessages: Boolean read GetHasMessages;
  end;

implementation

constructor TGameMessageQueue.Create;
begin
  inherited;
  Clear;
  SetLength(fQueueEntries, 50);
end;

procedure TGameMessageQueue.Add(aType: Integer);
begin
  Add(aType, '', 0);
end;

procedure TGameMessageQueue.Add(aType: Integer; aDataStr: String);
begin
  Add(aType, aDataStr, 0);
end;

procedure TGameMessageQueue.Add(aType: Integer; aDataInt: Int64);
begin
  Add(aType, '', aDataInt);
end;

procedure TGameMessageQueue.Add(aType: Integer; aDataInt: Int64; aDataStr: String);
begin
  Add(aType, aDataStr, aDataInt);
end;

procedure TGameMessageQueue.Add(aType: Integer; aDataStr: String; aDataInt: Int64);
begin
  if fQueueEntryCount = Length(fQueueEntries) then
    SetLength(fQueueEntries, fQueueEntryCount + 50); // avoids constant resizing, but does so if the need arises

  with fQueueEntries[fQueueEntryCount] do
  begin
    MessageType := aType;
    MessageDataStr := aDataStr;
    MessageDataInt := aDataInt;
  end;

  Inc(fQueueEntryCount);
end;

function TGameMessageQueue.GetMessage: TGameMessage;
begin
  if fQueueEntryCount > fCurrentReadEntry then
  begin
    Result := fQueueEntries[fCurrentReadEntry];
    Inc(fCurrentReadEntry);
  end else begin
    Result.MessageType := GAMEMSG_NIL;
    Clear;
  end;
end;

function TGameMessageQueue.GetHasMessages: Boolean;
begin
  Result := fCurrentReadEntry < fQueueEntryCount;
  if not Result then
    Clear;
end;

procedure TGameMessageQueue.Clear;
begin
  fCurrentReadEntry := 0;
  fQueueEntryCount := 0;
end;

end.
