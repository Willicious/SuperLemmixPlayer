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
      function Add: TBaseReplayItem;
      function Insert(Index: Integer): TBaseReplayItem;
      property Items[Index: Integer]: TBaseReplayItem read GetItem; default;
      property List;
  end;

  TReplay = class
    private
      fAssignments: TReplayItemList;        // nuking is also included here
      fReleaseRateChanges: TReplayItemList;
      fInterfaceActions: TReplayItemList;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure LoadOldReplayFile(aFile: String);
  end;

implementation

{ TReplay }

constructor TReplay.Create;
begin
  inherited;
  fAssignments := TReplayItemList.Create;
  fReleaseRateChanges := TReplayItemList.Create;
  fInterfaceActions := TReplayItemList.Create;
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
end;

procedure TReplay.LoadOldReplayFile(aFile: String);
var
  MS: TMemoryStream;
begin
  Clear;
  MS := TMemoryStream.Create;
  try

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

function TReplayItemList.Add: TBaseReplayItem;
begin
  Result := TBaseReplayItem.Create;
  inherited Add(Result);
end;

function TReplayItemList.Insert(Index: Integer): TBaseReplayItem;
begin
  Result := TBaseReplayItem.Create;
  inherited Insert(Index, Result);
end;

function TReplayItemList.GetItem(Index: Integer): TBaseReplayItem;
begin
  Result := inherited Get(Index);
end;

end.
