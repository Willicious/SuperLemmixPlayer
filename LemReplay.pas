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
  Dialogs,
  LemLevel,
  LemLemming, LemCore, LemVersion,
  Contnrs, Classes, SysUtils, StrUtils, Windows,
  LemNeoParser;

const
  SKILL_REPLAY_NAME_COUNT = 24;
  SKILL_REPLAY_NAMES: array[0..SKILL_REPLAY_NAME_COUNT-1] of String =
                                               ('WALKER', 'JUMPER', 'SHIMMIER',
                                                'SLIDER', 'CLIMBER', 'SWIMMER',
                                                'FLOATER', 'GLIDER', 'DISARMER',
                                                'TIMEBOMBER', 'BOMBER', 'FREEZER',
                                                'BLOCKER', 'PLATFORMER', 'BUILDER',
                                                'STACKER', 'SPEARER', 'GRENADER',
                                                'LASERER', 'BASHER', 'FENCER',
                                                'MINER', 'DIGGER', 'CLONER');


type
  TReplaySaveOccasion = (rsoAuto, rsoIngame, rsoPostview);

  TBaseReplayItem = class
    private
      fFrame: Integer;
      fAddedByInsert: Boolean;
      fAddTime: Int64;
    protected
      procedure DoLoadSection(Sec: TParserSection); virtual;    // Return TRUE if the line is understood. Should start with "if inherited then Exit".
      procedure DoSave(Sec: TParserSection); virtual;  // Should start with a call to inherited.
      procedure InitializeValues(); virtual; // we cannot guarantee that all values will be set, so make sure that there is nothing null and nothing that will crash the game!!!
    public
      constructor Create; // NEVER call this from this base class - only instanciate children!
      procedure Load(Sec: TParserSection);
      procedure Save(Sec: TParserSection);
      property AddedByInsert: Boolean read fAddedByInsert write fAddedByInsert;
      property AddTime: Int64 read fAddTime write fAddTime;
      property Frame: Integer read fFrame write fFrame;
  end;

  TBaseReplayLemmingItem = class(TBaseReplayItem)
    private
      fLemmingIndex: Integer;
      fLemmingIdentifier: String;
      fLemmingX: Integer;
      fLemmingDx: Integer;
      fLemmingY: Integer;
      fLemmingHighlit: Boolean;
    protected
      procedure DoLoadSection(Sec: TParserSection); override;
      procedure DoSave(Sec: TParserSection); override;
      procedure InitializeValues(); override;
    public
      procedure SetInfoFromLemming(aLemming: TLemming; aHighlit: Boolean);
      property LemmingIndex: Integer read fLemmingIndex write fLemmingIndex;
      property LemmingIdentifier: String read fLemmingIdentifier write fLemmingIdentifier;
      property LemmingX: Integer read fLemmingX write fLemmingX;
      property LemmingDx: Integer read fLemmingDx write fLemmingDx;
      property LemmingY: Integer read fLemmingY write fLemmingY;
      property LemmingHighlit: Boolean read fLemmingHighlit write fLemmingHighlit;
  end;

  TReplaySkillAssignment = class(TBaseReplayLemmingItem)
    private
      fSkill: TBasicLemmingAction;
    protected
      procedure DoLoadSection(Sec: TParserSection); override;
      procedure DoSave(Sec: TParserSection); override;
      procedure InitializeValues(); override; // THIS IS VERY IMPORTANT HERE!!! Null-Actions will crash the game!!!
    public
      property Skill: TBasicLemmingAction read fSkill write fSkill;
  end;

  TReplayChangeSpawnInterval = class(TBaseReplayItem)
    private
      fNewSpawnInterval: Integer;
      fSpawnedLemmingCount: Integer;
    protected
      procedure DoLoadSection(Sec: TParserSection); override;
      procedure DoSave(Sec: TParserSection); override;
      procedure InitializeValues(); override;
    public
      property NewSpawnInterval: Integer read fNewSpawnInterval write fNewSpawnInterval;
      property SpawnedLemmingCount: Integer read fSpawnedLemmingCount write fSpawnedLemmingCount;
  end;

  TReplayNuke = class(TBaseReplayItem)
    protected
      procedure DoLoadSection(Sec: TParserSection); override;
      procedure DoSave(Sec: TParserSection); override;
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
      fIsModified: Boolean;

      fAssignments: TReplayItemList;        // nuking is also included here
      fSpawnIntervalChanges: TReplayItemList;
      fPlayerName: String;
      fLevelName: String;
      fLevelAuthor: String;
      fLevelGame: String;
      fLevelRank: String;
      fLevelPosition: Integer;
      fLevelID: Int64;
      fLevelVersion: Int64;

      fExpectedCompletionIteration: Integer;

      function GetIsThisUsersReplay: Boolean;
      function GetLastActionFrame: Integer;
      function GetItemByFrame(aFrame: Integer; aIndex: Integer; aItemType: Integer): TBaseReplayItem;
      procedure SaveReplayList(aList: TReplayItemList; Sec: TParserSection);
      procedure UpdateFormat(SL: TStringList);
      procedure HandleLoadSection(aSection: TParserSection; const aIteration: Integer);
    public
      constructor Create;
      destructor Destroy; override;
      class function EvaluateReplayNamePattern(aPattern: String; aReplay: TReplay = nil): String;
      class function GetSaveFileName(aOwner: TComponent; aSaveOccasion: TReplaySaveOccasion; aReplay: TReplay = nil): String;
      procedure Add(aItem: TBaseReplayItem);
      procedure Clear(EraseLevelInfo: Boolean = false);
      procedure Delete(aItem: TBaseReplayItem);
      procedure LoadFromFile(aFile: String);
      procedure SaveToFile(aFile: String; aMarkAsUnmodified: Boolean = false);
      procedure LoadFromStream(aStream: TStream; aInternal: Boolean = false);
      procedure SaveToStream(aStream: TStream; aMarkAsUnmodified: Boolean = false; aInternal: Boolean = false);
      procedure Cut(aLastFrame: Integer; aExpectedSpawnInterval: Integer);
      function HasAnyActionAt(aFrame: Integer): Boolean;
      function HasRRChangeAt(aFrame: Integer): Boolean;
      function IsThisLatestAction(aAction: TBaseReplayItem): Boolean;
      property PlayerName: String read fPlayerName write fPlayerName;
      property LevelName: String read fLevelName write fLevelName;
      property LevelAuthor: String read fLevelAuthor write fLevelAuthor;
      property LevelGame: String read fLevelGame write fLevelGame;
      property LevelRank: String read fLevelRank write fLevelRank;
      property LevelPosition: Integer read fLevelPosition write fLevelPosition;
      property LevelID: Int64 read fLevelID write fLevelID;
      property LevelVersion: Int64 read fLevelVersion write fLevelVersion;
      property Assignment[aFrame: Integer; aIndex: Integer]: TBaseReplayItem Index 1 read GetItemByFrame;
      property SpawnIntervalChange[aFrame: Integer; aIndex: Integer]: TBaseReplayItem Index 2 read GetItemByFrame;
      property LastActionFrame: Integer read GetLastActionFrame;
      property ExpectedCompletionIteration: Integer read fExpectedCompletionIteration write fExpectedCompletionIteration;

      property IsModified: Boolean read fIsModified;
      property IsThisUsersReplay: Boolean read GetIsThisUsersReplay;
  end;

  function GetSkillReplayName(aButton: TSkillPanelButton): String; overload;
  function GetSkillReplayName(aAction: TBasicLemmingAction): String; overload;
  function GetSkillButton(aName: String): TSkillPanelButton;
  function GetSkillAction(aName: String): TBasicLemmingAction;

// Until a more permanent measure is found, LastReplayDir is implemented as a global variable.
var
  LastReplayDir: String;

implementation

uses
  CustomPopup, LemNeoLevelPack, LemTypes, GameControl, uMisc, SharedGlobals; // in TReplay.GetSaveFileName

var
  IncludeInternalInfo: Boolean;

// Standalone functions

function GetSkillReplayName(aButton: TSkillPanelButton): String;
begin
  Result := Lowercase(SKILL_REPLAY_NAMES[Integer(aButton)]);
end;

function GetSkillReplayName(aAction: TBasicLemmingAction): String;
begin
  Result := GetSkillReplayName(ActionToSkillPanelButton[aAction]);
end;

function GetSkillButton(aName: String): TSkillPanelButton;
var
  i: Integer;
begin
  Result := TSkillPanelButton(0); // to avoid compiler warning
  aName := Uppercase(aName);
  for i := 0 to SKILL_REPLAY_NAME_COUNT-1 do
    if aName = SKILL_REPLAY_NAMES[i] then
    begin
      Result := TSkillPanelButton(i);
      Exit;
    end;
end;

function GetSkillAction(aName: String): TBasicLemmingAction;
begin
  Result := SkillPanelButtonToAction[GetSkillButton(aName)];
end;

{ TReplay }

constructor TReplay.Create;
begin
  inherited;
  fAssignments := TReplayItemList.Create;
  fSpawnIntervalChanges := TReplayItemList.Create;
  Clear(true);
end;

destructor TReplay.Destroy;
begin
  fAssignments.Free;
  fSpawnIntervalChanges.Free;
  inherited;
end;

class function TReplay.EvaluateReplayNamePattern(aPattern: String; aReplay: TReplay = nil): String;
var
  SplitPos: Integer;
  NeedAddExt: Boolean;
const
  TAG_TITLE = '{TITLE}';
  TAG_GROUP = '{GROUP}';
  TAG_GROUPPOS = '{GROUPPOS}';
  TAG_TIMESTAMP = '{TIMESTAMP}';
  TAG_PACK = '{PACK}';
  TAG_USERNAME = '{USERNAME}';
  TAG_VERSION = '{VERSION}';
begin
  SplitPos := Pos('|', aPattern);
  if SplitPos > 0 then
  begin
    if (GameParams.TestModeLevel <> nil) or (GameParams.CurrentLevel.Group = GameParams.BaseLevelPack) or
       (not GameParams.CurrentLevel.Group.IsOrdered) then
      aPattern := MidStr(aPattern, SplitPos + 1, Length(aPattern) - SplitPos)
    else
      aPattern := LeftStr(aPattern, SplitPos - 1);
  end;

  NeedAddExt := (Pos('.', aPattern) = 0);

  Result := aPattern;

  if aReplay = nil then
  begin
    Result := StringReplace(Result, TAG_TITLE, MakeSafeForFilename(GameParams.CurrentLevel.Title), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_GROUP, MakeSafeForFilename(GameParams.CurrentLevel.Group.Name), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_GROUPPOS, LeadZeroStr(GameParams.CurrentLevel.GroupIndex + 1, 2), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_PACK, MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_USERNAME, MakeSafeForFilename(GameParams.Username), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_VERSION, IntToStr(GameParams.Level.Info.LevelVersion), [rfReplaceAll]);
  end else begin
    Result := StringReplace(Result, TAG_TITLE, MakeSafeForFilename(aReplay.LevelName), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_GROUP, MakeSafeForFilename(aReplay.LevelRank), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_GROUPPOS, LeadZeroStr(aReplay.LevelPosition, 2), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_PACK, MakeSafeForFilename(aReplay.LevelGame), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_USERNAME, MakeSafeForFilename(aReplay.PlayerName), [rfReplaceAll]);
    Result := StringReplace(Result, TAG_VERSION, IntToStr(aReplay.LevelVersion), [rfReplaceAll]);
  end;

  // The rest are the same whether aReplay is nil or not.
  Result := StringReplace(Result, TAG_TIMESTAMP, FormatDateTime('yyyy"-"mm"-"dd"_"hh"-"nn"-"ss', Now), [rfReplaceAll]);

  if NeedAddExt then
    Result := Result + '.nxrp';
end;

class function TReplay.GetSaveFileName(aOwner: TComponent; aSaveOccasion: TReplaySaveOccasion; aReplay: TReplay = nil): String;
  function GetDefaultSavePath: String;
  begin
    if (GameParams.TestModeLevel <> nil) or (GameParams.CurrentLevel.Group = GameParams.BaseLevelPack) then
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\'
    else
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\' + MakeSafeForFilename(GameParams.CurrentLevel.Group.ParentBasePack.Name) + '\';
    if aSaveOccasion = rsoAuto then Result := Result + 'Auto\';
  end;

  function GetInitialSavePath: String;
  begin
    if LastReplayDir <> '' then
      Result := LastReplayDir
    else
      Result := GetDefaultSavePath;
  end;

  function GetSavePath(DefaultFileName: String): String;
  var
    Dlg : TSaveDialog;
  begin
    Dlg := TSaveDialog.Create(aOwner);
    Dlg.Title := 'Save replay file (' + GameParams.CurrentLevel.Group.Name + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + GameParams.CurrentLevel.Title + ')';
    Dlg.Filter := 'SuperLemmix Replay (*.nxrp)|*.nxrp';
    Dlg.FilterIndex := 1;
    Dlg.InitialDir := GetInitialSavePath;
    Dlg.DefaultExt := '.nxrp';
    Dlg.Options := [ofOverwritePrompt, ofEnableSizing];
    Dlg.FileName := DefaultFileName;
    if Dlg.Execute then
    begin
      LastReplayDir := ExtractFilePath(Dlg.FileName);
      Result := Dlg.FileName;
    end else
      Result := '';
    Dlg.Free;
  end;

var
  SaveName: String;
  UseDialog: Boolean;
begin
  case aSaveOccasion of
    rsoAuto: SaveName := EvaluateReplayNamePattern(GameParams.AutoSaveReplayPattern, aReplay);
    rsoIngame: SaveName := EvaluateReplayNamePattern(GameParams.IngameSaveReplayPattern, aReplay);
    rsoPostview: SaveName := EvaluateReplayNamePattern(GameParams.PostviewSaveReplayPattern, aReplay);
    else raise Exception.Create('Invalid replay save occasion');
  end;

  UseDialog := false;
  if LeftStr(SaveName, 1) = '*' then
  begin
    SaveName := RightStr(SaveName, Length(SaveName) - 1);
    if aSaveOccasion <> rsoAuto then
      UseDialog := true;
  end;

  if UseDialog then
    Result := GetSavePath(SaveName)
  else
    Result := GetDefaultSavePath + SaveName;
end;

procedure TReplay.Add(aItem: TBaseReplayItem);
var
  Dst: TReplayItemList;
  i: Integer;
begin
  Dst := nil;

  if aItem is TReplaySkillAssignment then Dst := fAssignments;
  if aItem is TReplayChangeSpawnInterval then Dst := fSpawnIntervalChanges;
  if aItem is TReplayNuke then Dst := fAssignments;

  if Dst = nil then
    raise Exception.Create('Unknown type passed to TReplay.Add!');

  for i := Dst.Count-1 downto 0 do
    if (Dst[i].Frame = aItem.Frame) and (Dst[i].ClassName = aItem.ClassName) then
      Dst.Delete(i);
  Dst.Add(aItem);

  aItem.AddTime := GetTickCount64;
  fIsModified := true;
end;

procedure TReplay.Delete(aItem: TBaseReplayItem);
var
  Dst: TReplayItemList;
  i: Integer;
begin
  Dst := nil;
  if aItem is TReplaySkillAssignment then Dst := fAssignments;
  if aItem is TReplayChangeSpawnInterval then Dst := fSpawnIntervalChanges;
  if aItem is TReplayNuke then Dst := fAssignments;

  if Dst = nil then Exit;

  for i := Dst.Count-1 downto 0 do
    if Dst[i] = aItem then
      Dst.Delete(i);

  fIsModified := true;
end;

procedure TReplay.Clear(EraseLevelInfo: Boolean = false);
begin
  fAssignments.Clear;
  fSpawnIntervalChanges.Clear;
  fIsModified := true;
  if not EraseLevelInfo then Exit;
  fPlayerName := '';
  fLevelName := '';
  fLevelAuthor := '';
  fLevelGame := '';
  fLevelRank := '';
  fLevelPosition := 0;
  fLevelID := 0;
  fLevelVersion := 0;
  fExpectedCompletionIteration := 0;
end;

procedure TReplay.Cut(aLastFrame: Integer; aExpectedSpawnInterval: Integer);
var
  NextSI: TReplayChangeSpawnInterval;

  procedure DoCut(aList: TReplayItemList; aLastFrameLocal: Integer);
  var
    i: Integer;
  begin
    for i := aList.Count-1 downto 0 do
      if aList[i].Frame >= aLastFrameLocal then aList.Delete(i);
  end;
begin
  DoCut(fAssignments, aLastFrame);

  NextSI := TReplayChangeSpawnInterval(SpawnIntervalChange[aLastFrame, 0]);
  if (NextSI <> nil) and (NextSI.NewSpawnInterval <> aExpectedSpawnInterval) then
    DoCut(fSpawnIntervalChanges, aLastFrame)
  else
    DoCut(fSpawnIntervalChanges, aLastFrame + 1);

  if fExpectedCompletionIteration > aLastFrame then
    fExpectedCompletionIteration := 0;

  fIsModified := true;
end;

function TReplay.HasAnyActionAt(aFrame: Integer): Boolean;

  function CheckForAction(aList: TReplayItemList): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to aList.Count-1 do
      if aList[i].Frame = aFrame then
      begin
        Result := true;
        Exit;
      end;
  end;
begin
  Result := CheckForAction(fAssignments)
         or CheckForAction(fSpawnIntervalChanges);
end;

function TReplay.HasRRChangeAt(aFrame: Integer): Boolean;

  function CheckForRRChange(aList: TReplayItemList): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to aList.Count-1 do
      if aList[i].Frame = aFrame then
      begin
        Result := true;
        Exit;
      end;
  end;
begin
  Result := CheckForRRChange(fSpawnIntervalChanges);
end;

function TReplay.IsThisLatestAction(aAction: TBaseReplayItem): Boolean;
var
  i: Integer;
begin
  Result := false;

  if aAction.AddTime <= 0 then Exit;

  if aAction is TReplayChangeSpawnInterval then
  begin
    for i := 0 to fSpawnIntervalChanges.Count-1 do
      if (fSpawnIntervalChanges[i] <> aAction) and (fSpawnIntervalChanges[i].AddTime >= aAction.AddTime) then Exit;
  end else begin
    for i := 0 to fAssignments.Count-1 do
      if (fAssignments[i] <> aAction) and (fAssignments[i].AddTime >= aAction.AddTime) then Exit;
  end;

  Result := true;
end;

function TReplay.GetLastActionFrame: Integer;
// We could assume that the last action in the list is the last one in order,
// but let's not, just in case.
  procedure CheckForAction(aList: TReplayItemList);
  var
    i: Integer;
  begin
    for i := 0 to aList.Count-1 do
      if aList[i].Frame > Result then Result := aList[i].Frame;
  end;
begin
  Result := -1;
  CheckForAction(fAssignments);
  CheckForAction(fSpawnIntervalChanges);
end;

procedure TReplay.LoadFromStream(aStream: TStream; aInternal: Boolean = false);
var
  Parser: TParser;
  Sec: TParserSection;
  SL: TStringList;
begin
  IncludeInternalInfo := aInternal;
  Clear(true);

  SL := TStringList.Create;
  Parser := TParser.Create;
  try
    SL.LoadFromStream(aStream);
    UpdateFormat(SL);
    Parser.LoadFromStrings(SL);
    Sec := Parser.MainSection;

    fPlayerName := Sec.LineString['user'];
    fLevelName := Sec.LineString['title'];
    fLevelAuthor := Sec.LineString['author'];
    fLevelGame := Sec.LineString['game'];
    fLevelRank := Sec.LineString['group'];
    fLevelPosition := Sec.LineNumeric['level'];
    fLevelID := Sec.LineNumeric['id'];
    fLevelVersion := Sec.LineNumeric['version'];
    fExpectedCompletionIteration := Sec.LineNumeric['completion_frame'];

    Sec.DoForEachSection('assignment', HandleLoadSection);
    Sec.DoForEachSection('spawn_interval', HandleLoadSection);
    Sec.DoForEachSection('nuke', HandleLoadSection);

    fIsModified := false;
  finally
    Parser.Free;
    SL.Free
  end;
end;

procedure TReplay.HandleLoadSection(aSection: TParserSection; const aIteration: Integer);
var
  Item: TBaseReplayItem;
begin
  Item := nil;
  if aSection.Keyword = 'assignment' then Item := TReplaySkillAssignment.Create;
  if aSection.Keyword = 'spawn_interval' then Item := TReplayChangeSpawnInterval.Create;
  if aSection.Keyword = 'nuke' then Item := TReplayNuke.Create;

  if Item = nil then Exit;

  Item.Load(aSection);

  if Item is TReplayChangeSpawnInterval then
    fSpawnIntervalChanges.Add(Item)
  else
    fAssignments.Add(Item);
end;

procedure TReplay.SaveToFile(aFile: String; aMarkAsUnmodified: Boolean = false);
var
  FS: TFileStream;
begin
  ForceDirectories(ExtractFilePath(aFile));
  FS := TFileStream.Create(aFile, fmCreate);
  try
    FS.Position := 0;
    SaveToStream(FS, aMarkAsUnmodified);
  finally
    FS.Free;
  end;
end;

procedure TReplay.LoadFromFile(aFile: String);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(aFile, fmOpenRead);
  try
    FS.Position := 0;
    LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TReplay.SaveToStream(aStream: TStream; aMarkAsUnmodified: Boolean = false; aInternal: Boolean = false);
var
  Parser: TParser;
  Sec: TParserSection;
begin
  IncludeInternalInfo := aInternal;

  Parser := TParser.Create;
  try
    Sec := Parser.MainSection;

    if fIsModified then
    begin
      fPlayerName := GameParams.UserName; // If modified, treat it as this user's.
      fLevelVersion := GameParams.Level.Info.LevelVersion; // And as the up to date version.
    end;

    Sec.AddLine('USER', fPlayerName);

    Sec.AddLine('TITLE', fLevelName);
    Sec.AddLine('AUTHOR', fLevelAuthor);
    if Trim(fLevelGame) <> '' then
    begin
      Sec.AddLine('GAME', fLevelGame);
      Sec.AddLine('GROUP', fLevelRank);
      Sec.AddLine('LEVEL', fLevelPosition);
    end;
    Sec.AddLine('ID', fLevelID, 16);
    Sec.AddLine('VERSION', fLevelVersion);

    if fExpectedCompletionIteration > 0 then
      Sec.AddLine('COMPLETION_FRAME', fExpectedCompletionIteration);

    SaveReplayList(fAssignments, Sec);
    SaveReplayList(fSpawnIntervalChanges, Sec);

    Parser.SaveToStream(aStream);

    if aMarkAsUnmodified then
      fIsModified := false;
  finally
    Parser.Free;
  end;
end;

procedure TReplay.SaveReplayList(aList: TReplayItemList; Sec: TParserSection);
var
  i: Integer;
begin
  for i := 0 to aList.Count-1 do
    aList[i].Save(Sec);
end;

procedure TReplay.UpdateFormat(SL: TStringList);
var
  i: Integer;
  NeedUpdate: Boolean;
  S: String;

  function ModLine(aLine: String): String;
  begin
    Result := Lowercase(Trim(aLine));
  end;
begin
  // First, verify if it NEEDS to be updated. There's a few things we can check for, though we don't have anything 100% reliable.
  // (These tests are 100% reliable on SuperLemmix-generated files, but possibly not on user-edited ones.)
  NeedUpdate := false;
  for i := 0 to SL.Count-1 do
  begin
    if ModLine(SL[0]) = 'force_update' then // panic button
    begin
      SL.Delete(0);
      NeedUpdate := true;
      Break;
    end;

    if LeftStr(ModLine(SL[i]), 1) = '$' then Exit; // Almost a surefire sign of a new format replay
    if ModLine(SL[i]) = 'actions' then NeedUpdate := true; // The presence is almost surefire sign of old format, and absence almost surefire sign of new

    if NeedUpdate then Break;
  end;

  if not NeedUpdate then Exit;

  SL.Add('$END');
  for i := SL.Count-1 downto 0 do
  begin
    S := ModLine(SL[i]);

    if (S = '') or (S = 'actions') then
    begin
      SL.Delete(i);
      Continue;
    end;

    if (LeftStr(S, 12) = 'release_rate') or (LeftStr(S, 4) = 'nuke') or (LeftStr(S, 10) = 'assignment') then
    begin
      SL[i] := '$' + Trim(SL[i]);
      SL.Insert(i, '');
      SL.Insert(i, '$END');
    end;

    if LeftStr(S, 3) = 'id ' then
    begin
      S := RightStr(S, 8);
      SL[i] := 'ID x' + S;
    end;
  end;

  for i := 0 to SL.Count-1 do
  begin
    if ModLine(SL[i]) = '$end' then
    begin
      SL.Delete(i);
      Break;
      // This is to remove the extra $END added before the first action
    end;
  end;
end;

function TReplay.GetIsThisUsersReplay: Boolean;
begin
  if (fPlayerName = GameParams.UserName)
  or ((Trim(fPlayerName) = '') and GameParams.MatchBlankReplayUsername) then
    Result := true
  else if fIsModified then
  begin
    Result := true;
    fPlayerName := GameParams.UserName;
  end else
    Result := false;
end;

function TReplay.GetItemByFrame(aFrame: Integer; aIndex: Integer; aItemType: Integer): TBaseReplayItem;
var
  i: Integer;
  n: Integer;
  L: TReplayItemList;
begin
  Result := nil;
  case aItemType of
    1: L := fAssignments;
    2: L := fSpawnIntervalChanges;
    else Exit;
  end;

  n := 0;
  for i := 0 to L.Count-1 do
    if L[i].Frame = aFrame then
    begin
      if n = aIndex then
      begin
        Result := L[i];
        Exit;
      end else
        Inc(n);
    end;
end;

{ TBaseReplayItem }

constructor TBaseReplayItem.Create;
begin
  inherited Create();
  InitializeValues();
end;

procedure TBaseReplayItem.InitializeValues();
begin
  Frame := 17 * 60 * 99; // try corrupt values only after 99 minutes.
end;

procedure TBaseReplayItem.Load(Sec: TParserSection);
begin
  DoLoadSection(Sec);
end;

procedure TBaseReplayItem.Save(Sec: TParserSection);
begin
  DoSave(Sec);
end;

procedure TBaseReplayItem.DoLoadSection(Sec: TParserSection);
begin
  fFrame := Sec.LineNumeric['frame'];

  if IncludeInternalInfo then
  begin
    fAddedByInsert := Sec.Line['inserted'] <> nil;
    fAddTime := Sec.LineNumeric['addtime'];
  end;
end;

procedure TBaseReplayItem.DoSave(Sec: TParserSection);
begin
  Sec.AddLine('FRAME', fFrame);

  if IncludeInternalInfo then
  begin
    if fAddedByInsert then Sec.AddLine('inserted');
    Sec.AddLine('ADDTIME', fAddTime);
  end;
end;

{ TBaseReplayLemmingItem }

procedure TBaseReplayLemmingItem.InitializeValues();
begin
  inherited InitializeValues();
  fLemmingIndex := 0;
  fLemmingIdentifier := '';
  fLemmingX := 0;
  fLemmingDx := 0;
  fLemmingY := 0;
  fLemmingHighlit := False;
end;

procedure TBaseReplayLemmingItem.SetInfoFromLemming(aLemming: TLemming; aHighlit: Boolean);
begin
  fLemmingIndex := aLemming.LemIndex;
  fLemmingIdentifier := aLemming.LemIdentifier;
  fLemmingX := aLemming.LemX;
  fLemmingDx := aLemming.LemDX;
  fLemmingY := aLemming.LemY;
  fLemmingHighlit := aHighlit;
end;

procedure TBaseReplayLemmingItem.DoLoadSection(Sec: TParserSection);
var
  S: String;
begin
  inherited DoLoadSection(Sec);

  fLemmingIndex := Sec.LineNumeric['lem_index'];
  fLemmingIdentifier := Uppercase(Sec.LineTrimString['lem_identifier']);
  fLemmingX := Sec.LineNumeric['lem_x'];
  fLemmingY := Sec.LineNumeric['lem_y'];

  S := LeftStr(Lowercase(Sec.LineString['lem_dir']), 1);
  if S = 'l' then
    fLemmingDx := -1
  else if S = 'r' then
    fLemmingDx := 1
  else
    fLemmingDx := 0;

  fLemmingHighlit := Sec.Line['highlit'] <> nil;
end;

procedure TBaseReplayLemmingItem.DoSave(Sec: TParserSection);
begin
  inherited;
  Sec.AddLine('LEM_INDEX', fLemmingIndex);
  Sec.AddLine('LEM_IDENTIFIER', fLemmingIdentifier);
  Sec.AddLine('LEM_X', fLemmingX);
  Sec.AddLine('LEM_Y', fLemmingY);
  if fLemmingDx < 0 then
    Sec.AddLine('LEM_DIR', 'left')
  else
    Sec.AddLine('LEM_DIR', 'right');
  if fLemmingHighlit then
    Sec.AddLine('HIGHLIT');
end;

{ TReplaySkillAssignment }

procedure TReplaySkillAssignment.InitializeValues();
begin
  inherited InitializeValues();
  Skill := baNone;
end;

procedure TReplaySkillAssignment.DoLoadSection(Sec: TParserSection);
begin
  inherited DoLoadSection(Sec);

  Skill := GetSkillAction(Sec.LineTrimString['action']);
end;

procedure TReplaySkillAssignment.DoSave(Sec: TParserSection);
begin
  Sec := Sec.SectionList.Add('ASSIGNMENT');
  inherited DoSave(Sec);
  Sec.AddLine('ACTION', GetSkillReplayName(Skill));
end;

{ TReplaySpawnIntervalChange }
procedure TReplayChangeSpawnInterval.InitializeValues();
begin
  inherited InitializeValues();
  NewSpawnInterval := 1;
  SpawnedLemmingCount := 0;
end;

procedure TReplayChangeSpawnInterval.DoLoadSection(Sec: TParserSection);
begin
  inherited DoLoadSection(Sec);

  fNewSpawnInterval := Sec.LineNumeric['rate'];

  if Sec.Line['interval'] <> nil then
    fNewSpawnInterval := Sec.LineNumeric['interval'];
  fSpawnedLemmingCount := Sec.LineNumeric['spawned'];
end;

procedure TReplayChangeSpawnInterval.DoSave(Sec: TParserSection);
begin
  Sec := Sec.SectionList.Add('SPAWN_INTERVAL');
  inherited DoSave(Sec);
  Sec.AddLine('RATE', fNewSpawnInterval);
  Sec.AddLine('SPAWNED', fSpawnedLemmingCount);
end;

{ TReplayNuke }

procedure TReplayNuke.DoLoadSection(Sec: TParserSection);
begin
  inherited DoLoadSection(Sec);
end;

procedure TReplayNuke.DoSave(Sec: TParserSection);
begin
  Sec := Sec.SectionList.Add('NUKE');
  inherited DoSave(Sec);
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
