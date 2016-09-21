{$include lem_directives.inc}

unit GameControl;

{-------------------------------------------------------------------------------
  The gamecontrol class is in fact just a global var which is passed through as
  a parameter to all screens.
-------------------------------------------------------------------------------}

interface

uses
  LemmixHotkeys,
  Dialogs, SysUtils,
  Classes, Forms,
  GR32, GR32_Image,
  UTools,
  LemStrings, GameSound,
  LemCore, LemTypes, LemLevel, LemDosStyle,
  LemDosStructures,
  LemNeoSave, TalisData,
  LemLevelSystem, LemRendering,
  UZip; // only for checking whether some files actually exist

type
  TGameResultsRec = record
    gSuccess            : Boolean; // level played successfully?
    gCheated            : Boolean; // level cheated?
    gCount              : Integer; // number
    gToRescue           : Integer;
    gRescued            : Integer;
    gTarget             : Integer;
    gDone               : Integer;
    gTimeIsUp           : Boolean;
    gLastRescueIteration: Integer;
    gGotTalisman        : Boolean;
  end;

type
  TGameScreenType = (
    gstUnknown,
    gstMenu,
    gstPreview,
    gstPlay,
    gstPostview,
    gstLevelSelect,
    gstLevelCode,
    gstSounds,
    gstExit,
    gstText,
    gstTalisman
  );

type
  // how do we load the level
  TWhichLevel = (
    wlFirst,
    wlFirstSection,
    wlLevelCode,
    wlNext,
    wlSame,
    wlCongratulations,
    wlNextUnlocked,
    wlPreviousUnlocked,
    wlLastUnlocked
  );

type
  TGameSoundOption = (
    gsoSound,
    gsoMusic
  );
  TGameSoundOptions = set of TGameSoundOption;

type
  TMiscOption = (
    moLookForLVLFiles,  // 6
    moDebugSteel,
    moChallengeMode,
    moTimerMode,
    moAutoReplayNames,
    moLemmingBlink,
    moTimerBlink,
    moAutoReplaySave,
    moClickHighlight,
    moAlwaysTimestamp,
    moConfirmOverwrite,
    moExplicitCancel,
    moBlackOutZero,
    moEnableOnline,
    moCheckUpdates,
    moNoAutoReplayMode,
    moPauseAfterBackwards,
    moNoBackgrounds
  );

  TMiscOptions = set of TMiscOption;

  TPostLevelSoundOption = (plsVictory, plsFailure);
  TPostLevelSoundOptions = set of TPostLevelSoundOption;

const
  DEF_MISCOPTIONS = [
    moAutoReplayNames,
    moTimerBlink,
    moAlwaysTimestamp,
    moClickHighlight,
    moAutoReplaySave,
    moBlackOutZero,
    moPauseAfterBackwards
  ];

type

  TDosGameParams = class(TPersistent)
  private
    fHotkeys: TLemmixHotkeyManager;
    fTalismans : TTalismans;
    fTalismanPage: Integer;
    fDirectory    : string;
    fDumpMode : Boolean;
    fShownText: Boolean;
    fSaveSystem : TNeoSave;
    fOneLevelMode: Boolean;
    fDoneUpdateCheck: Boolean;
    fZoomLevel: Integer;
    fMainForm: TForm; // link to the FMain form

    MiscOptions           : TMiscOptions;
    PostLevelSoundOptions : TPostLevelSoundOptions;

    function GetOptionFlag(aFlag: TMiscOption): Boolean;
    procedure SetOptionFlag(aFlag: TMiscOption; aValue: Boolean);

    function GetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption): Boolean;
    procedure SetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption; aValue: Boolean);

    function GetSoundFlag(aFlag: TGameSoundOption): Boolean;
    //procedure SetSoundFlag(aFlag: TGameSoundOption; aValue: Boolean);

    procedure LoadFromIniFile;
    procedure SaveToIniFile;

  public
    // this is initialized by appcontroller
    MainDatFile  : string;

    Info         : TDosGamePlayInfoRec;
    WhichLevel   : TWhichLevel;

    SoundOptions : TGameSoundOptions;

    Level        : TLevel;
    Style        : TBaseDosLemmingStyle;
    Renderer     : TRenderer;

    LevelString : String;

    // this is initialized by the window in which the game will be played
    TargetBitmap : TBitmap32;

    // this is initialized by the game
    GameResult: TGameResultsRec;

    // this is set by the individual screens when closing (if they know)
    NextScreen: TGameScreenType;
    NextScreen2: TGameScreenType;

    // resource vars
    LemDataInResource   : Boolean;
    LemDataOnDisk       : Boolean;
    LemSoundsInResource : Boolean;
    LemSoundsOnDisk     : Boolean;
    LemMusicInResource  : Boolean;
    LemMusicOnDisk      : Boolean;

    // cheat
//    Cheatmode: Boolean; // levelcode screen

    fZoomFactor          : Integer;
    fForceSkillset       : Word;
    fLevelOverride       : Integer;

    fTestMode : Boolean;
    fTestGroundFile : String;
    fTestVgagrFile : String;
    fTestVgaspecFile : String;
    fTestLevelFile : String;

    fTestScreens: Integer;

    SysDat               : TSysDatRec;

    // mass replay check stuff
    ReplayResultList: TStringList;
    ReplayCheckIndex: Integer; // This is always -2, unless we are mass replay checking

    constructor Create;
    destructor Destroy; override;
    property SaveSystem: TNeoSave read fSaveSystem;

    procedure Save;
    procedure Load;

    property MusicEnabled: Boolean Index gsoMusic read GetSoundFlag;
    property SoundEnabled: Boolean Index gsoSound read GetSoundFlag;

    property LookForLVLFiles: Boolean Index moLookForLVLFiles read GetOptionFlag write SetOptionFlag;
    property DebugSteel: Boolean Index moDebugSteel read GetOptionFlag write SetOptionFlag;
    property ChallengeMode: Boolean Index moChallengeMode read GetOptionFlag write SetOptionFlag;
    property TimerMode: Boolean Index moTimerMode read GetOptionFlag write SetOptionFlag;
    property ClickHighlight: Boolean Index moClickHighlight read GetOptionFlag write SetOptionFlag;
    property AutoReplayNames: Boolean Index moAutoReplayNames read GetOptionFlag write SetOptionFlag;
    property AutoSaveReplay: Boolean Index moAutoReplaySave read GetOptionFlag write SetOptionFlag;
    property LemmingBlink: Boolean Index moLemmingBlink read GetOptionFlag write SetOptionFlag;
    property TimerBlink: Boolean Index moTimerBlink read GetOptionFlag write SetOptionFlag;
    property AlwaysTimestamp: boolean Index moAlwaysTimestamp read GetOptionFlag write SetOptionFlag;
    property ConfirmOverwrite: boolean Index moConfirmOverwrite read GetOptionFlag write SetOptionFlag;
    property ExplicitCancel: boolean Index moExplicitCancel read GetOptionFlag write SetOptionFlag;
    property BlackOutZero: boolean Index moBlackOutZero read GetOptionFlag write SetOptionFlag;
    property EnableOnline: boolean Index moEnableOnline read GetOptionFlag write SetOptionFlag;
    property CheckUpdates: boolean Index moCheckUpdates read GetOptionFlag write SetOptionFlag;
    property NoAutoReplayMode: boolean Index moNoAutoReplayMode read GetOptionFlag write SetOptionFlag;
    property PauseAfterBackwardsSkip: boolean Index moPauseAfterBackwards read GetOptionFlag write SetOptionFlag;
    property NoBackgrounds: boolean Index moNoBackgrounds read GetOptionFlag write SetOptionFlag;

    property PostLevelVictorySound: Boolean Index plsVictory read GetPostLevelSoundOptionFlag write SetPostLevelSoundOptionFlag;
    property PostLevelFailureSound: Boolean Index plsFailure read GetPostLevelSoundOptionFlag write SetPostLevelSoundOptionFlag;

    property DumpMode: boolean read fDumpMode write fDumpMode;
    property OneLevelMode: boolean read fOneLevelMode write fOneLevelMode;
    property ShownText: boolean read fShownText write fShownText;
    property DoneUpdateCheck: Boolean read fDoneUpdateCheck write fDoneUpdateCheck;

    property Directory: string read fDirectory write fDirectory;
    property ForceSkillset: Word read fForceSkillset write fForceSkillset;
    property QuickTestMode: Integer read fTestScreens write fTestScreens;
    property ZoomLevel: Integer read fZoomLevel write fZoomLevel;
    {property WindowX: Integer read fWindowX write fWindowX;
    property WindowY: Integer read fWindowY write fWindowY;}
    property MainForm: TForm read fMainForm write fMainForm;

    property Talismans: TTalismans read fTalismans;
    property TalismanPage: Integer read fTalismanPage write fTalismanPage;

    property Hotkeys: TLemmixHotkeyManager read fHotkeys;
  published
  end;


implementation

{ TDosGameParams }

procedure TDosGameParams.Save;
begin
  try
    SaveToIniFile;
    Hotkeys.SaveFile;
    SaveSystem.SaveFile(@self);
  except
    ShowMessage('An error occured while trying to save data.');
  end;
end;

procedure TDosGameParams.Load;
begin
  SaveSystem.LoadFile(@self);
  LoadFromIniFile;
  // Hotkeys automatically load when the hotkey manager is created
end;

procedure TDosGameParams.SaveToIniFile;
var
  SL: TStringList;

  procedure SaveBoolean(aLabel: String; aValue: Boolean; aValue2: Boolean = false);
  var
    NumValue: Integer;
  begin
    if aValue then
      NumValue := 1
    else
      NumValue := 0;
    if aValue2 then NumValue := NumValue + 2;
    SL.Add(aLabel + '=' + IntToStr(NumValue));
  end;
begin
  //if fTestMode then Exit;
  SL := TStringList.Create;

  SL.Add('LastVersion=' + IntToStr(Cur_MainVer) + IntToStr(Cur_SubVer) + IntToStr(Cur_MinorVer));

  SL.Add('');
  SL.Add('# Interface Options');
  SaveBoolean('ClickHighlight', ClickHighlight);
  SaveBoolean('AutoReplayNames', AutoReplayNames);
  SaveBoolean('AutoSaveReplay', AutoSaveReplay);
  SaveBoolean('AlwaysTimestampReplays', AlwaysTimestamp);
  SaveBoolean('ConfirmReplayOverwrite', ConfirmOverwrite);
  SaveBoolean('ExplicitReplayCancel', ExplicitCancel);
  SaveBoolean('NoAutoReplay', NoAutoReplayMode);
  SaveBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
  SaveBoolean('LemmingCountBlink', LemmingBlink);
  SaveBoolean('TimerBlink', TimerBlink);
  SaveBoolean('BlackOutZero', BlackOutZero);
  SaveBoolean('NoBackgrounds', NoBackgrounds);
  SL.Add('ZoomLevel=' + IntToStr(ZoomLevel));

  SL.Add('');
  SL.Add('# Sound Options');
  SL.Add('MusicVolume=' + IntToStr(MusicVolume));
  SL.Add('SoundVolume=' + IntToStr(SoundVolume));
  SaveBoolean('VictoryJingle', PostLevelVictorySound);
  SaveBoolean('FailureJingle', PostLevelFailureSound);

  SL.Add('');
  SL.Add('# Online Options');
  SaveBoolean('EnableOnline', EnableOnline);
  SaveBoolean('UpdateCheck', CheckUpdates);


  SL.SaveToFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini');

  SL.Free;
end;

procedure TDosGameParams.LoadFromIniFile;
var
  SL: TStringList;
  LastVer: Integer;

  function LoadBoolean(aLabel: String): Boolean;
  begin
    // CANNOT load multi-saved in one for obvious reasons, those must be handled manually
    if (SL.Values[aLabel] = '0') or (SL.Values[aLabel] = '') then
      Result := false
    else
      Result := true;
  end;

begin
  if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini') then
    if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini') then
      Exit;

  SL := TStringList.Create;

  if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini') then
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini')
  else
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini');

  MusicVolume := StrToIntDef(SL.Values['MusicVolume'], 100);
  SoundVolume := StrToIntDef(SL.Values['SoundVolume'], 100);
  ClickHighlight := LoadBoolean('ClickHighlight');
  AutoReplayNames := LoadBoolean('AutoReplayNames');
  AutoSaveReplay := LoadBoolean('AutoSaveReplay');
  LemmingBlink := LoadBoolean('LemmingCountBlink');
  TimerBlink := LoadBoolean('TimerBlink');
  AlwaysTimestamp := LoadBoolean('AlwaysTimestampReplays');
  ConfirmOverwrite := LoadBoolean('ConfirmReplayOverwrite');
  ExplicitCancel := LoadBoolean('ExplicitReplayCancel');
  NoAutoReplayMode := LoadBoolean('NoAutoReplay');
  PauseAfterBackwardsSkip := LoadBoolean('PauseAfterBackwardsSkip');
  BlackOutZero := LoadBoolean('BlackOutZero');
  NoBackgrounds := LoadBoolean('NoBackgrounds');
  EnableOnline := LoadBoolean('EnableOnline');
  CheckUpdates := LoadBoolean('UpdateCheck');

  ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], 0);

  PostLevelVictorySound := LoadBoolean('VictoryJingle');
  PostLevelFailureSound := LoadBoolean('FailureJingle');

  LastVer := StrToIntDef(SL.Values['LastVersion'], 0);

  if LastVer < 1441 then
    BlackOutZero := true;

  if LastVer < 1471 then
  begin
    if LoadBoolean('SoundEnabled') then
      SoundVolume := 100
    else
      SoundVolume := 0;
    if LoadBoolean('MusicEnabled') then
      MusicVolume := 100
    else
      MusicVolume := 0;

    PauseAfterBackwardsSkip := true;
  end;

  if LastVer < 1474 then
  begin
    PostLevelVictorySound := true;
    PostLevelFailureSound := true;
  end;

  SL.Free;
end;


constructor TDosGameParams.Create;
var
  TempStream: TMemoryStream; //for loading talisman data
  Arc: TArchive; // for checking whether talisman.dat exists
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;
  PostLevelSoundOptions := [plsVictory, plsFailure];

  MusicVolume := 100;
  SoundVolume := 100;
  fForceSkillset := 0;
  fDumpMode := false;
  fTestScreens := 0;
  fShownText := false;
  fOneLevelMode := false;
  fTalismanPage := 0;
  fZoomLevel := 0;

  LemDataInResource := True;
  LemSoundsInResource := True;
  LemMusicInResource := True;

  fSaveSystem := TNeoSave.Create;
  fTalismans := TTalismans.Create;


  Arc := TArchive.Create;

  TempStream := CreateDataStream('talisman.dat', ldtLemmings);
  if TempStream <> nil then
  begin
    fTalismans.LoadFromStream(TempStream);
    TempStream.Free;
  end;

  fTalismans.SortTalismans;

  Arc.Free;

  fSaveSystem.SetTalismans(fTalismans);

  fHotkeys := TLemmixHotkeyManager.Create;

  ReplayCheckIndex := -2;
  ReplayResultList := TStringList.Create;

end;

destructor TDosGameParams.Destroy;
begin
  fSaveSystem.Free;
  fTalismans.Free;
  fHotkeys.Free;
  ReplayResultList.Free;
  inherited Destroy;
end;

function TDosGameParams.GetOptionFlag(aFlag: TMiscOption): Boolean;
begin
  Result := aFlag in MiscOptions;
end;

procedure TDosGameParams.SetOptionFlag(aFlag: TMiscOption; aValue: Boolean);
begin
  if aValue then
    Include(MiscOptions, aFlag)
  else
    Exclude(MiscOptions, aFlag);
end;

function TDosGameParams.GetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption): Boolean;
begin
  Result := aFlag in PostLevelSoundOptions;
end;

procedure TDosGameParams.SetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption; aValue: Boolean);
begin
  if aValue then
    Include(PostLevelSoundOptions, aFlag)
  else
    Exclude(PostLevelSoundOptions, aFlag);
end;

function TDosGameParams.GetSoundFlag(aFlag: TGameSoundOption): Boolean;
begin
  if aFlag = gsoMusic then
    Result := MusicVolume <> 0
  else
    Result := SoundVolume <> 0;
end;

(*procedure TDosGameParams.SetSoundFlag(aFlag: TGameSoundOption; aValue: Boolean);
begin
  if aValue then
    Include(SoundOptions, aFlag)
  else
    Exclude(SoundOptions, aFlag);
end;*)

end.

