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
  LemStrings,
  LemCore, LemTypes, LemLevel, LemDosStyle, LemGraphicSet, LemDosGraphicSet, LemNeoGraphicSet,
  LemDosStructures,
  LemNeoEncryption, LemNeoSave, TalisData,
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
    moRemoved0,  // 0
    moRemoved1,      // 1
    moRemoved2,        // 2
    moRemoved3,       // 3
    moRemoved4,       // 4
    moRemoved5,    // 5
    moLookForLVLFiles,  // 6
    moDebugSteel,
    moChallengeMode,
    moTimerMode,
    moRemoved10, //10
    moRemoved11,
    moRemoved12,
    moAutoReplayNames,
    moLemmingBlink,
    moTimerBlink,
    moAutoReplaySave,
    moRemoved17,
    moClickHighlight,
    moRemoved19,
    moRemoved20, //20
    moRemoved21,
    moRemoved22,
    moAlwaysTimestamp,
    moConfirmOverwrite,
    moExplicitCancel,
    moBlackOutZero,
    moIgnoreReplaySelection,
    moEnableOnline,
    moCheckUpdates,
    moNoAutoReplayMode,
    mo31
  );

  TMiscOptions = set of TMiscOption;

const
  DEF_MISCOPTIONS = [
    moAutoReplayNames,
    moTimerBlink,
    moAlwaysTimestamp,
    moClickHighlight,
    moEnableOnline
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

    function GetOptionFlag(aFlag: TMiscOption): Boolean;
    procedure SetOptionFlag(aFlag: TMiscOption; aValue: Boolean);

    function GetSoundFlag(aFlag: TGameSoundOption): Boolean;
    procedure SetSoundFlag(aFlag: TGameSoundOption; aValue: Boolean);

  public
    // this is initialized by appcontroller
    MainDatFile  : string;

    Info         : TDosGamePlayInfoRec;
    WhichLevel   : TWhichLevel;

    SoundOptions : TGameSoundOptions;

    Level        : TLevel;
    Style        : TBaseDosLemmingStyle;
    //GraphicSet   : TBaseNeoGraphicSet;
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
    MiscOptions         : TMiscOptions;

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
    ReplayCheckIndex: Integer;

    constructor Create;
    destructor Destroy; override;
    procedure LoadFromIniFile;
    procedure SaveToIniFile;
    property SaveSystem: TNeoSave read fSaveSystem;

    property MusicEnabled: Boolean Index gsoMusic read GetSoundFlag write SetSoundFlag;
    property SoundEnabled: Boolean Index gsoSound read GetSoundFlag write SetSoundFlag;

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
    property IgnoreReplaySelection: boolean Index moIgnoreReplaySelection read GetOptionFlag write SetOptionFlag;
    property EnableOnline: boolean Index moEnableOnline read GetOptionFlag write SetOptionFlag;
    property CheckUpdates: boolean Index moCheckUpdates read GetOptionFlag write SetOptionFlag;
    property NoAutoReplayMode: boolean Index moNoAutoReplayMode read GetOptionFlag write SetOptionFlag;

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

  SaveBoolean('MusicEnabled', MusicEnabled);
  SaveBoolean('SoundEnabled', SoundEnabled);
  SaveBoolean('ClickHighlight', ClickHighlight);
  SaveBoolean('IgnoreReplaySelection', IgnoreReplaySelection);
  SaveBoolean('AutoReplayNames', AutoReplayNames);
  SaveBoolean('AutoSaveReplay', AutoSaveReplay);
  SaveBoolean('AlwaysTimestampReplays', AlwaysTimestamp);
  SaveBoolean('ConfirmReplayOverwrite', ConfirmOverwrite);
  SaveBoolean('ExplicitReplayCancel', ExplicitCancel);
  SaveBoolean('NoAutoReplay', NoAutoReplayMode);
  SaveBoolean('LemmingCountBlink', LemmingBlink);
  SaveBoolean('TimerBlink', TimerBlink);
  SaveBoolean('BlackOutZero', BlackOutZero);
  SaveBoolean('EnableOnline', EnableOnline);
  SaveBoolean('UpdateCheck', CheckUpdates);

  SL.Add('ZoomLevel=' + IntToStr(ZoomLevel));


  SL.SaveToFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini');

  SL.Free;
end;

procedure TDosGameParams.LoadFromIniFile;
var
  SL: TStringList;

  function LoadBoolean(aLabel: String): Boolean;
  begin
    // CANNOT load multi-saved in one for obvious reasons, those must be handled manually
    if (SL.Values[aLabel] = '0') or (SL.Values[aLabel] = '') then
      Result := false
    else
      Result := true;
  end;

begin
  if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini') then Exit;
  SL := TStringList.Create;
  SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini');

  MusicEnabled := LoadBoolean('MusicEnabled');
  SoundEnabled := LoadBoolean('SoundEnabled');
  ClickHighlight := LoadBoolean('ClickHighlight');
  AutoReplayNames := LoadBoolean('AutoReplayNames');
  AutoSaveReplay := LoadBoolean('AutoSaveReplay');
  LemmingBlink := LoadBoolean('LemmingCountBlink');
  TimerBlink := LoadBoolean('TimerBlink');
  AlwaysTimestamp := LoadBoolean('AlwaysTimestampReplays');
  ConfirmOverwrite := LoadBoolean('ConfirmReplayOverwrite');
  ExplicitCancel := LoadBoolean('ExplicitReplayCancel');
  NoAutoReplayMode := LoadBoolean('NoAutoReplay');
  BlackOutZero := LoadBoolean('BlackOutZero');
  IgnoreReplaySelection := LoadBoolean('IgnoreReplaySelection');
  EnableOnline := LoadBoolean('EnableOnline');
  CheckUpdates := LoadBoolean('UpdateCheck');

  ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], 0);

  if StrToIntDef(SL.Values['LastVersion'], 0) < 1421 then
    EnableOnline := true;

  if StrToIntDef(SL.Values['LastVersion'], 0) < 1441 then
    BlackOutZero := true;

  SL.Free;
end;


constructor TDosGameParams.Create;
var
  TempStream: TMemoryStream; //for loading talisman data
  Arc: TArchive; // for checking whether talisman.dat exists
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;
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
  if Arc.CheckIfFileExists('talisman.dat') then
  begin

    try
      TempStream := CreateDataStream('talisman.dat', ldtLemmings);
      fTalismans.LoadFromStream(TempStream);
      TempStream.Free;
    except
      // Silent fail. It's okay - and in fact common - for this file to be missing.
    end;

    fTalismans.SortTalismans;
  end;
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

function TDosGameParams.GetSoundFlag(aFlag: TGameSoundOption): Boolean;
begin
  Result := aFlag in SoundOptions;
end;

procedure TDosGameParams.SetSoundFlag(aFlag: TGameSoundOption; aValue: Boolean);
begin
  if aValue then
    Include(SoundOptions, aFlag)
  else
    Exclude(SoundOptions, aFlag);
end;

end.

