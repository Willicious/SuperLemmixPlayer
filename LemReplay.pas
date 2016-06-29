unit LemReplay;

// Handles replay files. Has backwards compatibility for loading old replay
// files, too.

// The replay items contain a lot of unnessecary information for normal
// usage. Only the type of action (inferred from which of TReplay's lists
// the item is stored in, and if nessecary, using an "if <var> is <class>"),
// the frame number, and if applicable the skill, release rate and/or lemming
// index are used in normal situations. The remaining data is intended to be
// used by a future "replay repair" code. (The main purpose of the seperation
// into three lists is due to the different timings of when they're acted on,
// more than being primarily intended to distinguish them. But the distinction
// may as well be taken advantage of.)

interface

uses
  LemNeoParser, LemLemming, LemCore,
  Contnrs, Classes, SysUtils;

type
  TReplayAction = (ra_None, ra_AssignSkill, ra_ChangeReleaseRate, ra_Nuke,
                   ra_SelectSkill, ra_HighlightLemming);

  TBaseReplayItem = class
    private
      fFrame: Integer;
    public
      property Frame: Integer read fFrame write fFrame;
  end;

  TBaseReplayLemmingItem = class(TBaseReplayItem)
    private
      fLemmingIndex: Integer;
      fLemmingX: Integer;
      fLemmingDx: Integer;
      fLemmingY: Integer;
      fLemmingHighlit: Boolean;
    public
      property LemmingIndex: Integer read fLemmingIndex write fLemmingIndex;
      property LemmingX: Integer read fLemmingX write fLemmingX;
      property LemmingDx: Integer read fLemmingDx write fLemmingDx;
      property LemmingY: Integer read fLemmingY write fLemmingY;
      property LemmingHighlit: Boolean read fLemmingHighlit write fLemmingHighlit;
  end;

  TReplaySkillAssignment = class(TBaseReplayLemmingItem)
    private
      fSkill: TBasicLemmingAction;
    public
      property Skill: TBasicLemmingAction read fSkill write fSkill;
  end;

  TReplayChangeReleaseRate = class(TBaseReplayItem)
    private
      fNewReleaseRate: Integer;
      fSpawnedLemmingCount: Integer;
    public
      property NewReleaseRate: Integer read fNewReleaseRate write fNewReleaseRate;
      property SpawnedLemmingCount: Integer read fSpawnedLemmingCount write fSpawnedLemmingCount;
  end;

  TReplayNuke = class(TBaseReplayItem)
  end;

  TReplaySelectSkill = class(TBaseReplayItem)
    private
      fSkill: TSkillPanelButton;
    public
      property Skill: TSkillPanelButton read fSkill;
  end;

  TReplayHighlightLemming = class(TBaseReplayLemmingItem)
  end;

  TReplayItemList = class(TObjectList)
    private
      function GetItem(Index: Integer): TBaseReplayItem;
    public
      constructor Create;
      function Add(Item: TBaseReplayItem): Integer;
      procedure Insert(Index: Integer; Item: TBaseReplayItem);
      property Items[Index: Integer]: TBaseReplayItem read GetItem; default;
      property List;
  end;

  TReplay = class
    private
      fAssignments: TReplayItemList;        // nuking is also included here
      fReleaseRateChanges: TReplayItemList;
      fInterfaceActions: TReplayItemList;
      fLevelID: Integer;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure LoadOldReplayFile(aFile: String);
      property LevelID: Integer read fLevelID write fLevelID;
  end;

implementation

// Stuff for the old LRB format
type
  TReplayFileHeaderRec = packed record
    Signature         : array[0..2] of Char;     //  3 bytes -  3
    Version           : Byte;                    //  1 byte  -  4
    FileSize          : Integer;                 //  4 bytes -  8
    HeaderSize        : Word;                    //  2 bytes - 10
    Mechanics         : Word;                    //  2 bytes - 12
    FirstRecordPos    : Integer;                 //  4 bytes - 16
    ReplayRecordSize  : Word;                    //  2 bytes - 18
    ReplayRecordCount : Word;                    //  2 bytes - 20

    ReplayGame        : Byte;
    ReplaySec         : Byte;
    ReplayLev         : Byte;
    ReplayOpt         : Word;

    ReplayTime        : LongWord;
    ReplaySaved       : Word;

    ReplayLevelID    : LongWord;

    Reserved        : array[0..29] of Char;
  end;

  TReplayRec = packed record
    Check          : Char;         //  1 byte  -  1
    Iteration      : Integer;      //  4 bytes -  5
    ActionFlags    : Word;         //  2 bytes -  7
    AssignedSkill  : Byte;         //  1 byte  -  8
    SelectedButton : Byte;         //  1 byte  -  9
    ReleaseRate    : Integer;      //  1 byte  - 13
    LemmingIndex   : Integer;      //  4 bytes - 17
    LemmingX       : Integer;      //  4 bytes - 21
    LemmingY       : Integer;      //  4 bytes - 25
    CursorX        : SmallInt;     //  2 bytes - 27
    CursorY        : SmallInt;     //  2 bytes - 29
    SelectDir      : ShortInt;
    Reserved2      : Byte;
    Reserved3      : Byte;         // 32
  end;

const
  //Recorded Action Flags
	raf_StartIncreaseRR   = $04;
	raf_StartDecreaseRR   = $08;
	raf_StopChangingRR    = $10;
	raf_SkillSelection    = $20;
	raf_SkillAssignment   = $40;
	raf_Nuke              = $80;

{ TReplay }

constructor TReplay.Create;
begin
  inherited;
  fAssignments := TReplayItemList.Create;
  fReleaseRateChanges := TReplayItemList.Create;
  fInterfaceActions := TReplayItemList.Create;
  Clear;
end;

destructor TReplay.Destroy;
begin
  fAssignments.Free;
  fReleaseRateChanges.Free;
  fInterfaceActions.Free;
  inherited;
end;

procedure TReplay.Clear;
begin
  fAssignments.Clear;
  fReleaseRateChanges.Clear;
  fInterfaceActions.Clear;
  fLevelID := 0;
end;

procedure TReplay.LoadOldReplayFile(aFile: String);
var
  MS: TMemoryStream;
  Header: TReplayFileHeaderRec;
  Item: TReplayRec;
  LastReleaseRate: Integer;
  LastSelectedSkill: TSkillPanelButton;

  procedure CreateAssignEntry;
  var
    E: TReplaySkillAssignment;
  begin
    E := TReplaySkillAssignment.Create;
    //E.Skill := // Need to make a conversion function
    E.LemmingIndex := Item.LemmingIndex;
    E.LemmingX := Item.LemmingX;
    E.LemmingDx := Item.SelectDir; // it's the closest we've got
    E.LemmingHighlit := false; // we can't tell for old replays
    E.Frame := Item.Iteration;
    fAssignments.Add(E);
  end;

  procedure CreateNukeEntry;
  var
    E: TReplayNuke;
  begin
    E := TReplayNuke.Create;
    E.Frame := Item.Iteration;
    fAssignments.Add(E);
  end;

  procedure CreateReleaseRateEntry;
  var
    E: TReplayChangeReleaseRate;
  begin
    E := TReplayChangeReleaseRate.Create;
    E.NewReleaseRate := Item.ReleaseRate;
    E.SpawnedLemmingCount := -1; // we don't know
    E.Frame := Item.Iteration;
    fReleaseRateChanges.Add(E);
  end;

  procedure CreateSelectSkillEntry;
  var
    E: TReplaySelectSkill;
  begin
    E := TReplaySelectSkill.Create;
    //E.Skill := //need to do
    E.Frame := Item.Iteration;
    fInterfaceActions.Add(E);
  end;

begin
  Clear;
  MS := TMemoryStream.Create;
  try
    MS.LoadFromFile(aFile);
    MS.Position := 0;
    MS.Read(Header, SizeOf(TReplayFileHeaderRec));

    MS.Position := Header.FirstRecordPos;

    while MS.Read(Item, SizeOf(TReplayRec)) = SizeOf(TReplayRec) do
    begin
    
    end;
  finally
    MS.Free;
  end;
end;

{ TReplayItemList }

constructor TReplayItemList.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TReplayItemList.Add(Item: TBaseReplayItem): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TReplayItemList.Insert(Index: Integer; Item: TBaseReplayItem);
begin
  inherited Insert(Index, Item);
end;

function TReplayItemList.GetItem(Index: Integer): TBaseReplayItem;
begin
  Result := inherited Get(Index);
end;

end.
