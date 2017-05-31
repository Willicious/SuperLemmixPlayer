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
  Contnrs, Classes, SysUtils, StrUtils,
  LemNeoParser;

const
  SKILL_REPLAY_NAME_COUNT = 17;
  SKILL_REPLAY_NAMES: array[0..SKILL_REPLAY_NAME_COUNT-1] of String =
                                               ('WALKER', 'CLIMBER', 'SWIMMER',
                                                'FLOATER', 'GLIDER', 'DISARMER',
                                                'BOMBER', 'STONER', 'BLOCKER',
                                                'PLATFORMER', 'BUILDER', 'STACKER',
                                                'BASHER', 'FENCER', 'MINER',
                                                'DIGGER', 'CLONER');


type
  TReplayAction = (ra_None, ra_AssignSkill, ra_ChangeReleaseRate, ra_Nuke,
                   ra_SelectSkill, ra_HighlightLemming);

  TBaseReplayItem = class
    private
      fFrame: Integer;
    protected
      procedure DoLoadSection(Sec: TParserSection); virtual;    // Return TRUE if the line is understood. Should start with "if inherited then Exit".
      procedure DoSave(Sec: TParserSection); virtual;  // Should start with a call to inherited.
      procedure InitializeValues(); virtual; // we cannot guarantee that all values will be set, so make sure that there is nothing null and nothing that will crash the game!!!
    public
      constructor Create; // NEVER call this from this base class - only instanciate children!
      procedure Load(Sec: TParserSection);
      procedure Save(Sec: TParserSection);
      property Frame: Integer read fFrame write fFrame;
  end;

  TBaseReplayLemmingItem = class(TBaseReplayItem)
    private
      fLemmingIndex: Integer;
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

  TReplayChangeReleaseRate = class(TBaseReplayItem)
    private
      fNewReleaseRate: Integer;
      fSpawnedLemmingCount: Integer;
    protected
      procedure DoLoadSection(Sec: TParserSection); override;
      procedure DoSave(Sec: TParserSection); override;
      procedure InitializeValues(); override;
    public
      property NewReleaseRate: Integer read fNewReleaseRate write fNewReleaseRate;
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
      fReleaseRateChanges: TReplayItemList;
      fPlayerName: String;
      fLevelName: String;
      fLevelAuthor: String;
      fLevelGame: String;
      fLevelRank: String;
      fLevelPosition: Integer;
      fLevelID: Int64;
      function GetLastActionFrame: Integer;
      function GetItemByFrame(aFrame: Integer; aIndex: Integer; aItemType: Integer): TBaseReplayItem;
      procedure SaveReplayList(aList: TReplayItemList; Sec: TParserSection);
      procedure UpdateFormat(SL: TStringList);
      procedure HandleLoadSection(aSection: TParserSection; const aIteration: Integer);
    public
      constructor Create;
      destructor Destroy; override;
      class function GetSaveFileName(aOwner: TComponent; aLevel: TLevel; TestModeName: Boolean = false): String;
      procedure Add(aItem: TBaseReplayItem);
      procedure Clear(EraseLevelInfo: Boolean = false);
      procedure Delete(aItem: TBaseReplayItem);
      procedure LoadFromFile(aFile: String);
      procedure SaveToFile(aFile: String);
      procedure LoadFromStream(aStream: TStream);
      procedure SaveToStream(aStream: TStream);
      procedure LoadOldReplayFile(aFile: String);
      procedure Cut(aLastFrame: Integer);
      function HasAnyActionAt(aFrame: Integer): Boolean;
      property PlayerName: String read fPlayerName write fPlayerName;
      property LevelName: String read fLevelName write fLevelName;
      property LevelAuthor: String read fLevelAuthor write fLevelAuthor;
      property LevelGame: String read fLevelGame write fLevelGame;
      property LevelRank: String read fLevelRank write fLevelRank;
      property LevelPosition: Integer read fLevelPosition write fLevelPosition;
      property LevelID: Int64 read fLevelID write fLevelID;
      property Assignment[aFrame: Integer; aIndex: Integer]: TBaseReplayItem Index 1 read GetItemByFrame;
      property ReleaseRateChange[aFrame: Integer; aIndex: Integer]: TBaseReplayItem Index 2 read GetItemByFrame;
      property LastActionFrame: Integer read GetLastActionFrame;
      property IsModified: Boolean read fIsModified;
  end;

  function GetSkillReplayName(aButton: TSkillPanelButton): String; overload;
  function GetSkillReplayName(aAction: TBasicLemmingAction): String; overload;
  function GetSkillButton(aName: String): TSkillPanelButton;
  function GetSkillAction(aName: String): TBasicLemmingAction;

implementation

uses
  CustomPopup, GameControl, uMisc, SharedGlobals; // in TReplay.GetSaveFileName

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
    ReplayOpt         : Byte;

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
    ReleaseRate    : Integer;      //  4 bytes  - 13
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
	raf_StartIncreaseRR   = $0008;
	raf_StartDecreaseRR   = $0010;
	raf_StopChangingRR    = $0020;
	raf_SkillSelection    = $0040;
	raf_SkillAssignment   = $0080;
	raf_Nuke              = $0100;

  BUTTON_TABLE: array[0..20] of TSkillPanelButton =
                 (spbNone, spbNone, spbNone,
                  spbClimber,
                  spbFloater,
                  spbBomber,
                  spbBlocker,
                  spbBuilder,
                  spbBasher,
                  spbMiner,
                  spbDigger,
                  spbNone, spbNone,
                  spbWalker,
                  spbSwimmer,
                  spbGlider,
                  spbDisarmer,
                  spbStoner,
                  spbPlatformer,
                  spbStacker,
                  spbCloner);

{ TReplay }

constructor TReplay.Create;
begin
  inherited;
  fAssignments := TReplayItemList.Create;
  fReleaseRateChanges := TReplayItemList.Create;
  Clear(true);
end;

destructor TReplay.Destroy;
begin
  fAssignments.Free;
  fReleaseRateChanges.Free;
  inherited;
end;

// Until a more permanent measure is found, LastReplayDir is implemented as a global variable.
var
  LastReplayDir: String;
class function TReplay.GetSaveFileName(aOwner: TComponent; aLevel: TLevel; TestModeName: Boolean = false): String;
var
  RankName: String;
  SaveNameLrb: String;
  SaveText: Boolean;

  function GetReplayFileName(TestModeName: Boolean): String;
  begin
    if GameParams.fTestMode then
      Result := Trim(aLevel.Info.Title)
    else
      Result := RankName + '_' + LeadZeroStr(GameParams.CurrentLevel.GroupIndex + 1, 2);
    if TestModeName or GameParams.AlwaysTimestamp then
      Result := Result + '__' + FormatDateTime('yyyy"-"mm"-"dd"_"hh"-"nn"-"ss', Now);
    Result := StringReplace(Result, '<', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '>', '_', [rfReplaceAll]);
    Result := StringReplace(Result, ':', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '"', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '\', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '|', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '?', '_', [rfReplaceAll]);
    Result := StringReplace(Result, '*', '_', [rfReplaceAll]);
    Result := Result + '.nxrp';
  end;

  function GetDefaultSavePath: String;
  begin
    if GameParams.fTestMode then
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\'
    else
      Result := ExtractFilePath(ParamStr(0)) + 'Replay\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\';
    if TestModeName then Result := Result + 'Auto\';
  end;

  function GetInitialSavePath: String;
  begin
    if (LastReplayDir <> '') and not TestModeName then
      Result := LastReplayDir
    else
      Result := GetDefaultSavePath;
  end;

  function GetSavePath(DefaultFileName: String): String;
  var
    Dlg : TSaveDialog;
  begin
    Dlg := TSaveDialog.Create(aOwner);
    Dlg.Title := 'Save replay file (' + RankName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(aLevel.Info.Title) + ')';
    Dlg.Filter := 'NeoLemmix Replay (*.nxrp)|*.nxrp';
    Dlg.FilterIndex := 1;
    Dlg.InitialDir := GetInitialSavePath;
    Dlg.DefaultExt := '.lrb';
    Dlg.Options := [ofOverwritePrompt];
    Dlg.FileName := DefaultFileName;
    if Dlg.Execute then
    begin
      LastReplayDir := ExtractFilePath(Dlg.FileName);
      SaveText := (dlg.FilterIndex = 2);
      Result := Dlg.FileName;
    end else
      Result := '';
    Dlg.Free;
  end;

  function GetReplayTypeCase: Integer;
  begin
    // Wouldn't need this if I bothered to merge the boolean options into a single
    // integer value... xD
    Result := 0;
    if TestModeName then Exit;
    if not GameParams.AutoReplayNames then
      Result := 2
    else if GameParams.ConfirmOverwrite and FileExists(GetInitialSavePath + SaveNameLrb) then
      Result := 1;
    // Don't need to handle AlwaysTimestamp here; it's handled in GetReplayFileName above.
  end;
begin
  SaveText := false;

  RankName := GameParams.CurrentGroupName;

  SaveNameLrb := GetReplayFileName(TestModeName);

  case GetReplayTypeCase of
    0: SaveNameLrb := GetDefaultSavePath + SaveNameLrb;
    1: begin
         case RunCustomPopup(aOwner, 'File Already Exists', 'A file with the default filename "' + SaveNameLrb + '" already exists. ' + #13 + 'What would you like to do?', 'Overwrite|Add Timestamp|Pick Filename|Cancel') of
           1: SaveNameLrb := GetInitialSavePath + SaveNameLrb;
           2: SaveNameLrb := GetInitialSavePath + GetReplayFilename(true);
           3: SaveNameLrb := GetSavePath(SaveNameLrb);
           4: SaveNameLrb := '';
         end;
       end;
    2:  SaveNameLrb := GetSavePath(SaveNameLrb);
  end;

  Result := SaveNameLrb;
end;

procedure TReplay.Add(aItem: TBaseReplayItem);
var
  Dst: TReplayItemList;
  i: Integer;
begin
  Dst := nil;

  if aItem is TReplaySkillAssignment then Dst := fAssignments;
  if aItem is TReplayChangeReleaseRate then Dst := fReleaseRateChanges;
  if aItem is TReplayNuke then Dst := fAssignments;

  if Dst = nil then
    raise Exception.Create('Unknown type passed to TReplay.Add!');

  for i := Dst.Count-1 downto 0 do
    if (Dst[i].Frame = aItem.Frame) and (Dst[i].ClassName = aItem.ClassName) then
      Dst.Delete(i);
  Dst.Add(aItem);

  fIsModified := true;
end;

procedure TReplay.Delete(aItem: TBaseReplayItem);
var
  Dst: TReplayItemList;
  i: Integer;
begin
  Dst := nil;
  if aItem is TReplaySkillAssignment then Dst := fAssignments;
  if aItem is TReplayChangeReleaseRate then Dst := fReleaseRateChanges;
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
  fReleaseRateChanges.Clear;
  if not EraseLevelInfo then Exit;
  fPlayerName := '';
  fLevelName := '';
  fLevelAuthor := '';
  fLevelGame := '';
  fLevelRank := '';
  fLevelPosition := 0;
  fLevelID := 0;
  fIsModified := true;
end;

procedure TReplay.Cut(aLastFrame: Integer);

  procedure DoCut(aList: TReplayItemList);
  var
    i: Integer;
  begin
    for i := aList.Count-1 downto 0 do
      if aList[i].Frame > aLastFrame then aList.Delete(i);
  end;
begin
  DoCut(fAssignments);
  DoCut(fReleaseRateChanges);
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
         or CheckForAction(fReleaseRateChanges);
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
  CheckForAction(fReleaseRateChanges);
end;

procedure TReplay.LoadFromStream(aStream: TStream);
var
  Parser: TParser;
  Sec: TParserSection;
  SL: TStringList;
begin
  Clear(true);

  fIsModified := false;

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
    fLevelRank := Sec.LineString['rank'];
    fLevelPosition := Sec.LineNumeric['level'];
    fLevelID := Sec.LineNumeric['id'];
    if Length(Sec.LineTrimString['id']) = 9 then
      fLevelID := fLevelID or (fLevelID shl 32);

    Sec.DoForEachSection('assignment', HandleLoadSection);
    Sec.DoForEachSection('release_rate', HandleLoadSection);
    Sec.DoForEachSection('nuke', HandleLoadSection);
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
  if aSection.Keyword = 'release_rate' then Item := TReplayChangeReleaseRate.Create;
  if aSection.Keyword = 'nuke' then Item := TReplayNuke.Create;

  if Item = nil then Exit;

  Item.Load(aSection);

  if Item is TReplayChangeReleaseRate then
    fReleaseRateChanges.Add(Item)
  else
    fAssignments.Add(Item);
end;

procedure TReplay.SaveToFile(aFile: String);
var
  FS: TFileStream;
begin
  ForceDirectories(ExtractFilePath(aFile));
  FS := TFileStream.Create(aFile, fmCreate);
  try
    FS.Position := 0;
    SaveToStream(FS);
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

procedure TReplay.SaveToStream(aStream: TStream);
var
  Parser: TParser;
  Sec: TParserSection;
begin
  Parser := TParser.Create;
  try
    Sec := Parser.MainSection;

    Sec.AddLine('USER', fPlayerName);
    Sec.AddLine('TITLE', fLevelName);
    Sec.AddLine('AUTHOR', fLevelAuthor);
    if Trim(fLevelGame) <> '' then
    begin
      Sec.AddLine('GAME', fLevelGame);
      Sec.AddLine('RANK', fLevelRank);
      Sec.AddLine('LEVEL', fLevelPosition);
    end;
    Sec.AddLine('ID', fLevelID, 16);

    SaveReplayList(fAssignments, Sec);
    SaveReplayList(fReleaseRateChanges, Sec);

    Parser.SaveToStream(aStream);
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
  // (These tests are 100% reliable on NeoLemmix-generated files, but possibly not on user-edited ones.)
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

procedure TReplay.LoadOldReplayFile(aFile: String);
var
  MS: TMemoryStream;
  Header: TReplayFileHeaderRec;
  Item: TReplayRec;
  LastReleaseRate: Integer;

  procedure CreateAssignEntry;
  var
    E: TReplaySkillAssignment;
  begin
    E := TReplaySkillAssignment.Create;
    E.Skill := TBasicLemmingAction(Item.AssignedSkill);
    E.LemmingIndex := Item.LemmingIndex;
    E.LemmingX := Item.LemmingX;
    E.LemmingDx := Item.SelectDir; // it's the closest we've got
    E.LemmingHighlit := false; // we can't tell for old replays
    E.Frame := Item.Iteration;
    Add(E);
  end;

  procedure CreateNukeEntry;
  var
    E: TReplayNuke;
  begin
    E := TReplayNuke.Create;
    E.Frame := Item.Iteration;
    Add(E);
  end;

  procedure CreateReleaseRateEntry;
  var
    E: TReplayChangeReleaseRate;
  begin
    E := TReplayChangeReleaseRate.Create;
    E.NewReleaseRate := Item.ReleaseRate;
    E.SpawnedLemmingCount := -1; // we don't know
    E.Frame := Item.Iteration;
    Add(E);
  end;

begin
  Clear(true);
  MS := TMemoryStream.Create;
  try
    MS.LoadFromFile(aFile);
    MS.Position := 0;
    MS.Read(Header, SizeOf(TReplayFileHeaderRec));

    fLevelID := Header.ReplayLevelID or (Header.ReplayLevelID shl 32);

    MS.Position := Header.FirstRecordPos;
    LastReleaseRate := 0;

    while MS.Read(Item, SizeOf(TReplayRec)) = SizeOf(TReplayRec) do
    begin
      if Item.ReleaseRate <> LastReleaseRate then
      begin
        CreateReleaseRateEntry;
        LastReleaseRate := Item.ReleaseRate;
        if Item.ActionFlags and $38 <> 0 then Continue;
      end;

      if Item.ActionFlags and raf_SkillAssignment <> 0 then
        CreateAssignEntry;

      if Item.ActionFlags and raf_Nuke <> 0 then
        CreateNukeEntry;
    end;
  finally
    MS.Free;
  end;
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
    2: L := fReleaseRateChanges;
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
end;

procedure TBaseReplayItem.DoSave(Sec: TParserSection);
begin
  Sec.AddLine('FRAME', fFrame);
end;

{ TBaseReplayLemmingItem }

procedure TBaseReplayLemmingItem.InitializeValues();
begin
  inherited InitializeValues();
  fLemmingIndex := 0;
  fLemmingX := 0;
  fLemmingDx := 0;
  fLemmingY := 0;
  fLemmingHighlit := False;
end;

procedure TBaseReplayLemmingItem.SetInfoFromLemming(aLemming: TLemming; aHighlit: Boolean);
begin
  fLemmingIndex := aLemming.LemIndex;
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

{ TReplayReleaseRateChange }

procedure TReplayChangeReleaseRate.InitializeValues();
begin
  inherited InitializeValues();
  NewReleaseRate := 1;
  SpawnedLemmingCount := 0;
end;

procedure TReplayChangeReleaseRate.DoLoadSection(Sec: TParserSection);
begin
  inherited DoLoadSection(Sec);

  fNewReleaseRate := Sec.LineNumeric['rate'];
  fSpawnedLemmingCount := Sec.LineNumeric['spawned'];
end;

procedure TReplayChangeReleaseRate.DoSave(Sec: TParserSection);
begin
  Sec := Sec.SectionList.Add('RELEASE_RATE');
  inherited DoSave(Sec);
  Sec.AddLine('RATE', fNewReleaseRate);
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
