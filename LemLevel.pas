{$include lem_directives.inc}
unit LemLevel;

interface

uses
  Classes, SysUtils, StrUtils,
  UMisc,
  LemLemming,
  LemTerrain, LemMetaTerrain,
  LemInteractiveObject, LemMetaObject,
  LemNeoPieceManager,
  LemSteel,
  LemCore,
  LemNeoParser;

type
  TSkillset = set of TSkillPanelButton;
  TSkillCounts = array[Low(TSkillPanelButton)..High(TSkillPanelButton)] of Integer; // non-skill buttons are just unused

  TLevelInfo = class
  private
  protected
    fReleaseRateLocked : Boolean;
    fReleaseRate    : Integer;
    fLemmingsCount  : Integer;
    fZombieGhostCount: Integer;
    fRescueCount    : Integer;
    fTimeLimit      : Integer;

    fSkillset: TSkillset;
    fSkillCounts: TSkillCounts;

    fWidth : Integer;
    fHeight : Integer;

    fBackground: String;

    fLevelOptions   : Cardinal;

    fScreenPosition : Integer;
    fScreenYPosition: Integer;
    fTitle          : string;
    fAuthor         : string;

    fGraphicSetName : string;
    fMusicFile      : string;

    fLevelID        : LongWord;

    procedure SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
    function GetSkillCount(aSkill: TSkillPanelButton): Integer;
  protected
  public
    WindowOrder       : array of word;
    constructor Create;
    procedure Clear; virtual;

    property ReleaseRate    : Integer read fReleaseRate write fReleaseRate;
    property ReleaseRateLocked: Boolean read fReleaseRateLocked write fReleaseRateLocked;
    property LemmingsCount  : Integer read fLemmingsCount write fLemmingsCount;
    property ZombieGhostCount: Integer read fZombieGhostCount write fZombieGhostCount;
    property RescueCount    : Integer read fRescueCount write fRescueCount;
    property TimeLimit      : Integer read fTimeLimit write fTimeLimit;

    property Skillset: TSkillset read fSkillset write fSkillset;
    property SkillCount[Index: TSkillPanelButton]: Integer read GetSkillCount write SetSkillCount;

    property ScreenPosition : Integer read fScreenPosition write fScreenPosition;
    property ScreenYPosition : Integer read fScreenYPosition write fScreenYPosition;
    property Title          : string read fTitle write fTitle;
    property Author         : string read fAuthor write fAuthor;

    property LevelOptions   : Cardinal read fLevelOptions write fLevelOptions;

    property Width          : Integer read fWidth write fWidth;
    property Height         : Integer read fHeight write fHeight;

    property GraphicSetName : String read fGraphicSetName write fGraphicSetName;
    property MusicFile      : String read fMusicFile write fMusicFile;

    property Background: String read fBackground write fBackground;

    property LevelID: LongWord read fLevelID write fLevelID;
  end;

  TLevel = class
  private
    fLevelInfo       : TLevelInfo;
    fTerrains           : TTerrains;
    fInteractiveObjects : TInteractiveObjects;
    fSteels             : TSteels;
    fPreplacedLemmings  : TPreplacedLemmingList;

    // Loading routines
    procedure LoadGeneralInfo(aSection: TParserSection);
    procedure LoadSpawnOrderSection(aSection: TParserSection);
      procedure HandleSpawnEntry(aLine: TParserLine; const aIteration: Integer);
    procedure LoadSkillsetSection(aSection: TParserSection);
    procedure HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleAreaEntry(aSection: TParserSection; const aIteration: Integer);
    procedure HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
    procedure Sanitize;

    // Saving routines
    procedure SaveGeneralInfo(aSection: TParserSection);
    procedure SaveSpawnOrderSection(aSection: TParserSection);
    procedure SaveSkillsetSection(aSection: TParserSection);
    procedure SaveObjectSections(aSection: TParserSection);
    procedure SaveTerrainSections(aSection: TParserSection);
    procedure SaveAreaSections(aSection: TParserSection);
    procedure SaveLemmingSections(aSection: TParserSection);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadFromFile(aFile: String);
    procedure LoadFromStream(aStream: TStream);

    procedure SaveToFile(aFile: String);
    procedure SaveToStream(aStream: TStream);
  published
    property Info: TLevelInfo read fLevelInfo;
    property InteractiveObjects: TInteractiveObjects read fInteractiveObjects;
    property Terrains: TTerrains read fTerrains;
    property Steels: TSteels read fSteels;
    property PreplacedLemmings: TPreplacedLemmingList read fPreplacedLemmings;
  end;

implementation

uses
  LemLVLLoader; // for backwards compatibility

{ TLevelInfo }

procedure TLevelInfo.Clear;
var
  i : Integer;
begin
  ReleaseRate    := 1;
  ReleaseRateLocked := false;
  LemmingsCount  := 1;
  ZombieGhostCount := 0;
  RescueCount    := 1;
  TimeLimit      := 6000;

  fSkillset := [];
  FillChar(fSkillCounts, SizeOf(TSkillCounts), 0);

  LevelOptions   := 2;
  ScreenPosition := 0;
  ScreenYPosition := 0;
  Width := 320;
  Height := 160;
  Title          := '';
  Author         := '';
  fBackground := '';
  SetLength(WindowOrder, 0);

  GraphicSetName := '';
  MusicFile := '';
  LevelID := 0;
end;

constructor TLevelInfo.Create;
begin
  inherited Create;
  Clear;
end;

procedure TLevelInfo.SetSkillCount(aSkill: TSkillPanelButton; aCount: Integer);
begin
  fSkillCounts[aSkill] := aCount;
end;

function TLevelInfo.GetSkillCount(aSkill: TSkillPanelButton): Integer;
begin
  Result := fSkillCounts[aSkill];
end;

{ TLevel }

constructor TLevel.Create;
begin
  inherited;
  fLevelInfo := TLevelInfo.Create;
  fInteractiveObjects := TInteractiveObjects.Create;
  fTerrains := TTerrains.Create;
  fSteels := TSteels.Create;
  fPreplacedLemmings := TPreplacedLemmingList.Create;
end;

destructor TLevel.Destroy;
begin
  fLevelInfo.Free;
  fInteractiveObjects.Free;
  fTerrains.Free;
  fSteels.Free;
  fPreplacedLemmings.Free;
  inherited;
end;

procedure TLevel.Clear;
begin
  fLevelInfo.Clear;
  fInteractiveObjects.Clear;
  fTerrains.Clear;
  fSteels.Clear;
  fPreplacedLemmings.Clear;
end;

procedure TLevel.LoadFromFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmOpenRead);
  try
    F.Position := 0;
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TLevel.SaveToFile(aFile: String);
var
  F: TFileStream;
begin
  F := TFileStream.Create(aFile, fmCreate);
  try
    F.Position := 0;
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

// TLevel Loading Routines

procedure TLevel.LoadFromStream(aStream: TStream);
var
  Parser: TParser;
  Main: TParserSection;
  b: Byte;
begin
  aStream.Read(b, 1);
  aStream.Position := aStream.Position - 1;

  Clear;

  if b < 5 then
    TLVLLoader.LoadLevelFromStream(aStream, self); 

  Parser := TParser.Create;
  try
    Parser.LoadFromStream(aStream);
    Main := Parser.MainSection;

    LoadGeneralInfo(Main);
    LoadSpawnOrderSection(Main.Section['spawn_order']);
    LoadSkillsetSection(Main.Section['skillset']);

    Main.DoForEachSection('object', HandleObjectEntry);
    Main.DoForEachSection('terrain', HandleTerrainEntry);
    Main.DoForEachSection('area', HandleAreaEntry);
    Main.DoForEachSection('lemming', HandleLemmingEntry);

    Sanitize;
  finally
    Parser.Free;
  end;
end;

procedure TLevel.LoadGeneralInfo(aSection: TParserSection);

  function GetLevelOptionsValue(aString: String): Byte;
  begin
    aString := Lowercase(aString);
    if aString = 'simple' then
      Result := $0A
    else if aString = 'off' then
      Result := $00
    else
      Result := $02;
  end;

  function GetTimeLimitValue(aString: String): Integer;
  begin
    aString := Lowercase(aString);
    if (aString = '') or (aString = 'infinite') then
      Result := 6000
    else
      Result := StrToIntDef(aString, 6000);
  end;
begin
  // This procedure should receive the Parser's MAIN section
  with Info do
  begin
    Title := aSection.LineString['title'];
    Author := aSection.LineString['author'];
    GraphicSetName := aSection.LineTrimString['theme'];
    MusicFile := aSection.LineTrimString['music'];
    LevelID := aSection.LineNumeric['id'];

    LemmingsCount := aSection.LineNumeric['lemmings'];
    RescueCount := aSection.LineNumeric['requirement'];
    TimeLimit := GetTimeLimitValue(aSection.LineTrimString['time_limit']);
    ReleaseRate := aSection.LineNumeric['release_rate'];
    ReleaseRateLocked := (aSection.Line['release_rate_locked'] <> nil);

    Width := aSection.LineNumeric['width'];
    Height := aSection.LineNumeric['height'];
    ScreenPosition := aSection.LineNumeric['start_x'];
    ScreenYPosition := aSection.LineNumeric['start_y'];

    LevelOptions := GetLevelOptionsValue(aSection.LineTrimString['autosteel']);

    Background := aSection.LineTrimString['background'];
  end;
end;

procedure TLevel.LoadSpawnOrderSection(aSection: TParserSection);
var
  Count: Integer;
begin
  if aSection = nil then
  begin
    SetLength(Info.WindowOrder, 0);
    Exit;
  end;
  SetLength(Info.WindowOrder, aSection.LineList.Count);
  Count := aSection.DoForEachLine('object', HandleSpawnEntry);
  SetLength(Info.WindowOrder, Count);
end;

procedure TLevel.HandleSpawnEntry(aLine: TParserLine; const aIteration: Integer);
begin
  Info.WindowOrder[aIteration] := aLine.ValueNumeric;
end;

procedure TLevel.LoadSkillsetSection(aSection: TParserSection);
  procedure HandleSkill(aLabel: String; aFlag: TSkillPanelButton);
  var
    Line: TParserLine;
    Count: Integer;
  begin
    Line := aSection.Line[aLabel];
    if Line = nil then Exit;
    if Lowercase(Line.ValueTrimmed) = 'infinite' then
      Count := 100
    else
      Count := Line.ValueNumeric;
    Info.Skillset := Info.Skillset + [aFlag];
    Info.SkillCount[aFlag] := Count;
  end;
begin
  Info.Skillset := [];
  if aSection = nil then Exit;

  HandleSkill('walker', spbWalker);
  HandleSkill('climber', spbClimber);
  HandleSkill('swimmer', spbSwimmer);
  HandleSkill('floater', spbFloater);
  HandleSkill('glider', spbGlider);
  HandleSkill('disarmer', spbDisarmer);
  HandleSkill('bomber', spbBomber);
  HandleSkill('stoner', spbStoner);
  HandleSkill('blocker', spbBlocker);
  HandleSkill('platformer', spbPlatformer);
  HandleSkill('builder', spbBuilder);
  HandleSkill('stacker', spbStacker);
  HandleSkill('basher', spbBasher);
  HandleSkill('miner', spbMiner);
  HandleSkill('digger', spbDigger);
  HandleSkill('cloner', spbCloner);
end;

procedure TLevel.HandleObjectEntry(aSection: TParserSection; const aIteration: Integer);
var
  O: TInteractiveObject;
  MO: TMetaObject;

  procedure Flag(aValue: Integer);
  begin
    O.DrawingFlags := O.DrawingFlags or aValue;
  end;

  procedure GetTeleporterData;
  begin
    if (aSection.Line['flip_lemming'] <> nil) then Flag(odf_FlipLem);
    O.Skill := aSection.LineNumeric['pairing'];
  end;

  procedure GetReceiverData;
  begin
    O.Skill := aSection.LineNumeric['pairing'];
  end;

  procedure GetPickupData;
  var
    S: String;
  begin
    S := Lowercase(aSection.LineTrimString['skill']);

    if S = 'walker' then O.Skill := 8;
    if S = 'climber' then O.Skill := 0;
    if S = 'swimmer' then O.Skill := 9;
    if S = 'floater' then O.Skill := 1;
    if S = 'glider' then O.Skill := 10;
    if S = 'disarmer' then O.Skill := 11;
    if S = 'bomber' then O.Skill := 2;
    if S = 'stoner' then O.Skill := 12;
    if S = 'blocker' then O.Skill := 3;
    if S = 'platformer' then O.Skill := 13;
    if S = 'builder' then O.Skill := 4;
    if S = 'stacker' then O.Skill := 14;
    if S = 'basher' then O.Skill := 5;
    if S = 'miner' then O.Skill := 6;
    if S = 'digger' then O.Skill := 7;
    if S = 'cloner' then O.Skill := 15;
  end;

  procedure GetSplitterData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then
      Flag(odf_FlipLem);
  end;

  procedure GetWindowData;
  begin
    if LeftStr(Lowercase(aSection.LineTrimString['direction']), 1) = 'l' then Flag(odf_FlipLem);
    if (aSection.Line['climber'] <> nil) then O.TarLev := O.TarLev or 1;
    if (aSection.Line['swimmer'] <> nil) then O.TarLev := O.TarLev or 2;
    if (aSection.Line['floater'] <> nil) then O.TarLev := O.TarLev or 4;
    if (aSection.Line['glider'] <> nil) then O.TarLev := O.TarLev or 8;
    if (aSection.Line['disarmer'] <> nil) then O.TarLev := O.TarLev or 16;
    if (aSection.Line['zombie'] <> nil) then O.TarLev := O.TarLev or 64;
  end;

  procedure GetMovingBackgroundData;
  var
    Angle: Integer;
  begin
    Angle := aSection.LineNumeric['angle'];
    Angle := ((Angle * 10) + 113) div 225;
    O.Skill := Angle;
    O.TarLev := aSection.LineNumeric['speed'];
  end;
begin
  O := fInteractiveObjects.Add;

  O.GS := aSection.LineTrimString['collection'];
  O.Piece := aSection.LineTrimString['piece'];
  O.Left := aSection.LineNumeric['x'];
  O.Top := aSection.LineNumeric['y'];
  O.Width := aSection.LineNumeric['width'];
  O.Height := aSection.LineNumeric['height'];

  O.IsFake := (aSection.Line['fake'] <> nil);
  O.DrawingFlags := 0;
  if (aSection.Line['invisible'] <> nil) then Flag(odf_Invisible);
  if (aSection.Line['rotate'] <> nil) then Flag(odf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(odf_Flip);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(odf_UpsideDown);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(odf_NoOverwrite);
  if (aSection.Line['only_on_terrain'] <> nil) then Flag(odf_OnlyOnTerrain);

  MO := PieceManager.Objects[O.Identifier];
  case MO.TriggerEffect of
    11: GetTeleporterData;
    12: GetReceiverData;
    14: GetPickupData;
    21: GetSplitterData;
    23: GetWindowData;
    30: GetMovingBackgroundData;
  end;
end;

procedure TLevel.HandleTerrainEntry(aSection: TParserSection; const aIteration: Integer);
var
  T: TTerrain;

  procedure Flag(aValue: Integer);
  begin
    T.DrawingFlags := T.DrawingFlags or aValue;
  end;
begin
  T := fTerrains.Add;

  T.GS := aSection.LineTrimString['collection'];
  T.Piece := aSection.LineTrimString['piece'];
  T.Left := aSection.LineNumeric['x'];
  T.Top := aSection.LineNumeric['y'];

  T.DrawingFlags := tdf_NoOneWay;
  if (aSection.Line['one_way'] <> nil) then T.DrawingFlags := 0;
  if (aSection.Line['rotate'] <> nil) then Flag(tdf_Rotate);
  if (aSection.Line['flip_horizontal'] <> nil) then Flag(tdf_Flip);
  if (aSection.Line['flip_vertical'] <> nil) then Flag(tdf_Invert);
  if (aSection.Line['no_overwrite'] <> nil) then Flag(tdf_NoOverwrite);
  if (aSection.Line['erase'] <> nil) then Flag(tdf_Erase);
end;

procedure TLevel.HandleAreaEntry(aSection: TParserSection; const aIteration: Integer);
var
  S: TSteel;
begin
  S := fSteels.Add;

  S.Left := aSection.LineNumeric['x'];
  S.Top := aSection.LineNumeric['y'];
  S.Width := aSection.LineNumeric['width'];
  S.Height := aSection.LineNumeric['height'];

  if (aSection.Line['erase'] <> nil) then
    S.fType := 1
  else
    S.fType := 0;
end;

procedure TLevel.HandleLemmingEntry(aSection: TParserSection; const aIteration: Integer);
var
  L: TPreplacedLemming;
begin
  L := fPreplacedLemmings.Add;

  L.X := aSection.LineNumeric['x'];
  L.Y := aSection.LineNumeric['y'];

  if Lowercase(LeftStr(aSection.LineTrimString['direction'], 1)) = 'l' then
    L.Dx := -1
  else
    L.Dx := 1; // We use right as a "default", but we're also lenient - we accept just an L rather than the full word "left".
               // Side effects may include a left-facing lemming if user manually enters "DIRECTION LEMMING FACES IS RIGHT".

  L.IsClimber  := (aSection.Line['climber']  <> nil);
  L.IsSwimmer  := (aSection.Line['swimmer']  <> nil);
  L.IsFloater  := (aSection.Line['floater']  <> nil);
  L.IsGlider   := (aSection.Line['glider']   <> nil);
  L.IsDisarmer := (aSection.Line['disarmer'] <> nil);
  L.IsZombie   := (aSection.Line['zombie']   <> nil);
end;

procedure TLevel.Sanitize;
var
  SkillIndex: TSkillPanelButton;
begin
  // Nepster - I have removed certain parts of this as they are not needed in regards to longer-term plans
  with Info do
  begin
    if Width < 320 then Width := 320;
    if Height < 160 then Height := 160;

    if ScreenPosition < 0 then ScreenPosition := 0;
    if ScreenPosition > Width-320 then ScreenPosition := Width-320;

    if ScreenYPosition < 0 then ScreenYPosition := 0;
    if ScreenYPosition > Height-160 then ScreenYPosition := Height-160;

    if LemmingsCount < 0 then LemmingsCount := 0;
    if RescueCount < 0 then RescueCount := 0;

    if TimeLimit < 1 then TimeLimit := 1;
    if TimeLimit > 6000 then TimeLimit := 6000;

    if ReleaseRate < 1 then ReleaseRate := 1;
    if ReleaseRate > 99 then ReleaseRate := 99;

    for SkillIndex := Low(TSkillPanelButton) to High(TSkillPanelButton) do
    begin
      if SkillCount[SkillIndex] < 0 then SkillCount[SkillIndex] := 0;
      if SkillCount[SkillIndex] > 100 then SkillCount[SkillIndex] := 100;
      if not(SkillIndex in Skillset) then SkillCount[SkillIndex] := 0;
    end;
  end;
end;

// TLevel Saving Routines

procedure TLevel.SaveToStream(aStream: TStream);
var
  Parser: TParser;
begin
  Parser := TParser.Create;
  try
    SaveGeneralInfo(Parser.MainSection);
    SaveSpawnOrderSection(Parser.MainSection);
    SaveSkillsetSection(Parser.MainSection);
    SaveObjectSections(Parser.MainSection);
    SaveTerrainSections(Parser.MainSection);
    SaveAreaSections(Parser.MainSection);
    SaveLemmingSections(Parser.MainSection);
    Parser.SaveToStream(aStream);
  finally
    Parser.Free;
  end;
end;

procedure TLevel.SaveGeneralInfo(aSection: TParserSection);
  procedure MakeAutoSteelLine;
  var
    S: String;
  begin
    if (Info.LevelOptions and $0A) = $0A then
      S := 'simple'
    else if (Info.LevelOptions and $02) = 0 then
      S := 'off'
    else
      S := 'on'; // not strictly needed as "On" is default value

    aSection.AddLine('AUTOSTEEL', S);
  end;
begin
  with Info do
  begin
    aSection.AddLine('TITLE', Title);
    aSection.AddLine('AUTHOR', Author);
    aSection.AddLine('THEME', GraphicSetName);
    aSection.AddLine('MUSIC', MusicFile);
    aSection.AddLine('ID', 'x' + IntToHex(LevelID, 8));

    aSection.AddLine('LEMMINGS', LemmingsCount);
    aSection.AddLine('REQUIREMENT', RescueCount);

    if (TimeLimit > 0) and (TimeLimit < 6000) then
      aSection.AddLine('TIME_LIMIT', TimeLimit);

    aSection.AddLine('RELEASE_RATE', ReleaseRate);
    if ReleaseRateLocked then
      aSection.AddLine('RELEASE_RATE_LOCKED');

    aSection.AddLine('WIDTH', Width);
    aSection.AddLine('HEIGHT', Height);
    aSection.AddLine('START_X', ScreenPosition);
    aSection.AddLine('START_Y', ScreenYPosition);

    MakeAutosteelLine;

    aSection.AddLine('BACKGROUND', Background);
  end;
end;

procedure TLevel.SaveSpawnOrderSection(aSection: TParserSection);
var
  Sec: TParserSection;
  i: Integer;
begin
  if Length(Info.WindowOrder) = 0 then Exit;

  Sec := aSection.SectionList.Add('SPAWN_ORDER');
  for i := 0 to Length(Info.WindowOrder)-1 do
    Sec.AddLine('OBJECT', Info.WindowOrder[i]);
end; 

procedure TLevel.SaveSkillsetSection(aSection: TParserSection);
var
  Sec: TParserSection;

  procedure HandleSkill(aLabel: String; aFlag: TSkillPanelButton);
  begin
    if not (aFlag in Info.Skillset) then Exit;
    if Info.SkillCount[aFlag] > 99 then
      Sec.AddLine(aLabel, 'infinite')
    else
      Sec.AddLine(aLabel, Info.SkillCount[aFlag]);
  end;
begin
  if Info.Skillset = [] then Exit;
  Sec := aSection.SectionList.Add('SKILLSET');

  HandleSkill('WALKER', spbWalker);
  HandleSkill('CLIMBER', spbClimber);
  HandleSkill('SWIMMER', spbSwimmer);
  HandleSkill('FLOATER', spbFloater);
  HandleSkill('GLIDER', spbGlider);
  HandleSkill('DISARMER', spbDisarmer);
  HandleSkill('BOMBER', spbBomber);
  HandleSkill('STONER', spbStoner);
  HandleSkill('BLOCKER', spbBlocker);
  HandleSkill('PLATFORMER', spbPlatformer);
  HandleSkill('BUILDER', spbBuilder);
  HandleSkill('STACKER', spbStacker);
  HandleSkill('BASHER', spbBasher);
  HandleSkill('MINER', spbMiner);
  HandleSkill('DIGGER', spbDigger);
  HandleSkill('CLONER', spbCloner);
end;

procedure TLevel.SaveObjectSections(aSection: TParserSection);
var
  i: Integer;
  O: TInteractiveObject;
  MO: TMetaObject;
  Sec: TParserSection;

  function Flag(aValue: Integer): Boolean;
  begin
    Result := O.DrawingFlags and aValue = aValue;
  end;

  //if Flag(odf_FlipLem) then Sec.AddLine('FACE_LEFT');

  procedure SetTeleporterData;
  begin
    if Flag(odf_FlipLem) then Sec.AddLine('FLIP_LEMMING');
    Sec.AddLine('PAIRING', O.Skill);
  end;

  procedure SetReceiverData;
  begin
    Sec.AddLine('PAIRING', O.Skill);
  end;

  procedure SetPickupData;
  var
    S: String;
  begin
    case O.Skill of
      8: S := 'WALKER';
      0: S := 'CLIMBER';
      9: S := 'SWIMMER';
      1: S := 'FLOATER';
      10: S := 'GLIDER';
      11: S := 'DISARMER';
      2: S := 'BOMBER';
      12: S := 'STONER';
      3: S := 'BLOCKER';
      13: S := 'PLATFORMER';
      4: S := 'BUILDER';
      14: S := 'STACKER';
      5: S := 'BASHER';
      6: S := 'MINER';
      7: S := 'DIGGER';
      15: S := 'CLONER';
    end;

    Sec.AddLine(S);
  end;

  procedure SetSplitterData;
  begin
    if Flag(odf_FlipLem) then
      Sec.AddLine('DIRECTION', 'left')
    else
      Sec.AddLine('DIRECTION', 'right');
  end;

  procedure SetWindowData;
  begin
    if Flag(odf_FlipLem) then
      Sec.AddLine('DIRECTION', 'left')
    else
      Sec.AddLine('DIRECTION', 'right');

    if O.TarLev and 1 <> 0 then Sec.AddLine('CLIMBER');
    if O.TarLev and 2 <> 0 then Sec.AddLine('SWIMMER');
    if O.TarLev and 4 <> 0 then Sec.AddLine('FLOATER');
    if O.TarLev and 8 <> 0 then Sec.AddLine('GLIDER');
    if O.TarLev and 16 <> 0 then Sec.AddLine('DISARMER');
    if O.TarLev and 64 <> 0 then Sec.AddLine('ZOMBIE');
  end;

  procedure SetMovingBackgroundData;
  var
    Angle: Integer;
  begin
    Angle := (O.Skill * 225) div 10;

    Sec.AddLine('ANGLE', Angle);
    Sec.AddLine('SPEED', O.TarLev);
  end;
begin
  for i := 0 to fInteractiveObjects.Count-1 do
  begin
    O := fInteractiveObjects[i];
    Sec := aSection.SectionList.Add('OBJECT');

    Sec.AddLine('COLLECTION', O.GS);
    Sec.AddLine('PIECE', O.Piece);
    Sec.AddLine('X', O.Left);
    Sec.AddLine('Y', O.Top);
    if O.Width > 0 then Sec.AddLine('WIDTH', O.Width);
    if O.Height > 0 then Sec.AddLine('HEIGHT', O.Height);

    if O.IsFake then Sec.AddLine('FAKE');
    if Flag(odf_Invisible) then Sec.AddLine('INVISIBLE');
    if Flag(odf_Rotate) then Sec.AddLine('ROTATE');
    if Flag(odf_Flip) then Sec.AddLine('FLIP_HORIZONTAL');
    if Flag(odf_UpsideDown) then Sec.AddLine('FLIP_VERTICAL');
    if Flag(odf_NoOverwrite) then Sec.AddLine('NO_OVERWRITE');
    if Flag(odf_OnlyOnTerrain) then Sec.AddLine('ONLY_ON_TERRAIN');

    MO := PieceManager.Objects[O.Identifier];
    case MO.TriggerEffect of
      11: SetTeleporterData;
      12: SetReceiverData;
      14: SetPickupData;
      21: SetSplitterData;
      23: SetWindowData;
      30: SetMovingBackgroundData;
    end;
  end;
end;

procedure TLevel.SaveTerrainSections(aSection: TParserSection);
var
  i: Integer;
  T: TTerrain;
  Sec: TParserSection;

  function Flag(aValue: Integer): Boolean;
  begin
    Result := T.DrawingFlags and aValue = aValue;
  end;
begin
  for i := 0 to fTerrains.Count-1 do
  begin
    T := fTerrains[i];
    Sec := aSection.SectionList.Add('TERRAIN');

    Sec.AddLine('COLLECTION', T.GS);
    Sec.AddLine('PIECE', T.Piece);
    Sec.AddLine('X', T.Left);
    Sec.AddLine('Y', T.Top);

    if Flag(tdf_Rotate) then Sec.AddLine('ROTATE');
    if Flag(tdf_Flip) then Sec.AddLine('FLIP_HORIZONTAL');
    if Flag(tdf_Invert) then Sec.AddLine('FLIP_VERTICAL');
    if Flag(tdf_NoOverwrite) then Sec.AddLine('NO_OVERWRITE');
    if Flag(tdf_Erase) then Sec.AddLine('ERASE');
    if not Flag(tdf_NoOneWay) then Sec.AddLine('ONE_WAY');
  end;
end;

procedure TLevel.SaveAreaSections(aSection: TParserSection);
var
  i: Integer;
  S: TSteel;
  Sec: TParserSection;
begin
  for i := 0 to fSteels.Count-1 do
  begin
    S := fSteels[i];
    Sec := aSection.SectionList.Add('AREA');

    Sec.AddLine('X', S.Left);
    Sec.AddLine('Y', S.Top);
    Sec.AddLine('WIDTH', S.Width);
    Sec.AddLine('HEIGHT', S.Height);

    if S.fType = 1 then
      Sec.AddLine('ERASE');
  end;
end;

procedure TLevel.SaveLemmingSections(aSection: TParserSection);
var
  i: Integer;
  L: TPreplacedLemming;
  Sec: TParserSection;
begin
  for i := 0 to fPreplacedLemmings.Count-1 do
  begin
    L := fPreplacedLemmings[i];
    Sec := aSection.SectionList.Add('LEMMING');

    Sec.AddLine('X', L.X);
    Sec.AddLine('Y', L.Y);

    if L.Dx > 0 then
      Sec.AddLine('DIRECTION', 'right')
    else
      Sec.AddLine('DIRECTION', 'left');

    if L.IsClimber then Sec.AddLine('CLIMBER');
    if L.IsSwimmer then Sec.AddLine('SWIMMER');
    if L.IsFloater then Sec.AddLine('FLOATER');
    if L.IsGlider then Sec.AddLine('GLIDER');
    if L.IsDisarmer then Sec.AddLine('DISARMER');
    if L.IsZombie then Sec.AddLine('ZOMBIE');
  end;
end;

end.

