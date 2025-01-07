{$include lem_directives.inc}

unit GameControl;

{-------------------------------------------------------------------------------
  The gamecontrol class is in fact just a global var which is passed through as
  a parameter to all screens.
-------------------------------------------------------------------------------}

interface

uses
  LemNeoPieceManager,
  LemNeoLevelPack,
  LemmixHotkeys,
  Math,
  Dialogs, StdCtrls, SysUtils, StrUtils, IOUtils, Classes, Forms, GR32, Types,
  LemVersion,
  LemTypes, LemLevel,
  LemStrings, FLevelListDialog,
  LemRendering,
  SharedGlobals;

var
  IsHalting: Boolean; { ONLY used during AppController's init routines. Don't use this anywhere else.
                        Shouldn't even be used there really, but a kludgy fix is okay since that's gonna
                        be replaced once proper level select menus are introduced. }

type
  TGameResultsRec = record
    gSuccess            : Boolean; // Level played successfully
    gCheated            : Boolean; // Level cheated
    gCount              : Integer; // Number of lems
    gToRescue           : Integer; // Save requirement
    gRescued            : Integer; // Number of lems rescued
    gTimeIsUp           : Boolean; // Time up status
    gLastIteration      : Integer; // Final frame
    gLastRescueIteration: Integer; // Final rescue frame
    gGotTalisman        : Boolean; // Talisman achieved
    gGotNewTalisman     : Boolean; // New talisman achieved
  end;

type
  TGameScreenType = (
    gstUnknown,
    gstMenu,
    gstPreview,
    gstPlay,
    gstPostview,
    gstExit,
    gstText,
    gstReplayTest
  );

type
  TGameSoundOption = (
    gsoSound,
    gsoMusic
  );
  TGameSoundOptions = set of TGameSoundOption;

type
  TPlaybackOrder = (
    poByReplay,
    poByLevel,
    poRandom
  );

type
  TMiscOption = (
    moAutoReplaySave,
    moEnableOnline,
    moCheckUpdates,
    moLoadNextUnsolvedLevel,
    moAutoReplayMode,
    moReplayAfterRestart,
    moPauseAfterBackwards,
    moTurboFF,
    moNoBackgrounds,
    moColourCycle,
    moShowButtonHints,
    moClassicMode,
    moHideShadows,
    moHideHelpers,
    moHideSkillQ,
    moHighResolution,
    moLinearResampleMenu,
    moFullScreen,
    moMinimapHighQuality,
    moShowMinimap,
    moIncreaseZoom,
    moLoadedConfig,
    moMatchBlankReplayUsername,
    moCompactSkillPanel,
    moEdgeScroll,
    moSpawnInterval,
    moFileCaching,
    moPostviewJingles,
    moMenuSounds,
    moAmigaTheme,
    moDisableMusicInTestplay,
    moPreferYippee
  );

  TMiscOptions = set of TMiscOption;

const
  DEF_MISCOPTIONS = [
    moCheckUpdates,
    moAutoReplaySave,
    moLoadNextUnsolvedLevel,
    moPauseAfterBackwards,
    moLinearResampleMenu,
    moAutoReplayMode,
    moReplayAfterRestart,
    moFullScreen,
    moMinimapHighQuality,
    moShowMinimap,
    moColourCycle,
    moIncreaseZoom,
    moEdgeScroll,
    moPreferYippee,
    moMenuSounds
  ];

type
  TGameParamsSaveCriticality = ( scNone, scImportant, scCritical );

  TDosGameParams = class(TPersistent)
  private
    fDisableSaveOptions: Boolean;
    fSaveCriticality: TGameParamsSaveCriticality;

    fHotkeys: TLemmixHotkeyManager;
    fTalismanPage: Integer;
    fDirectory    : string;
    fDumpMode : Boolean;
    fShownText: Boolean;
    fOneLevelMode: Boolean;
    //fDoneUpdateCheck: Boolean;
    fCurrentLevel: TNeoLevelEntry;

    fShowLevelSelectOptions: Boolean;

    fEdgeScrollSpeed: Integer;
    fCursorResize: Double;
    fZoomLevel: Integer;
    fPanelZoomLevel: Integer;
    fWindowLeft: Integer;
    fWindowTop: Integer;
    fWindowWidth: Integer;
    fWindowHeight: Integer;
    fLoadedWindowLeft: Integer;
    fLoadedWindowTop: Integer;
    fLoadedWindowWidth: Integer;
    fLoadedWindowHeight: Integer;

    fUserName: String;

    fAutoSaveReplayPattern: String;
    fIngameSaveReplayPattern: String;
    fPostviewSaveReplayPattern: String;

    fMainForm: TForm; // Link to the FMain form

    MiscOptions           : TMiscOptions;

    // Playback Mode
    fPlaybackModeActive: Boolean;
    fPlaybackOrder: TPlaybackOrder;
    fPlaybackList: TStringList;
    fUnmatchedList: TStringList;
    fReplayVerifyList: TStringList;
    fPlaybackIndex: Integer;
    fAutoSkipPreviewPostview: Boolean;

    function GetOptionFlag(aFlag: TMiscOption): Boolean;
    procedure SetOptionFlag(aFlag: TMiscOption; aValue: Boolean);

    procedure LoadFromIniFile;
    procedure SaveToIniFile;

    function GetCurrentGroupName: String;

    procedure SetUserName(aValue: String);
  public
    OpenedViaReplay: Boolean;
    LoadedReplayFile: string;
    LoadedReplayID: string;

    SoundOptions : TGameSoundOptions;

    Level        : TLevel;
    Renderer     : TRenderer;

    LevelString: String;
    BaseLevelPack: TNeoLevelGroup;

    // This is initialized by the window in which the game will be played
    TargetBitmap : TBitmap32;

    // This is initialized by the game
    GameResult: TGameResultsRec;

    // This is set by the individual screens when closing (if they know)
    NextScreen     : TGameScreenType;
    IsPreTextScreen: Boolean;

    // Resource vars
    LemDataInResource   : Boolean;
    LemDataOnDisk       : Boolean;
    LemSoundsInResource : Boolean;
    LemSoundsOnDisk     : Boolean;
    LemMusicInResource  : Boolean;
    LemMusicOnDisk      : Boolean;

    fLevelOverride       : Integer;

    //SysDat               : TSysDatRec;
    ReplayCheckPath: String;

    TestModeLevel: TNeoLevelEntry;

    constructor Create;
    destructor Destroy; override;

    procedure Save(aCriticality: TGameParamsSaveCriticality);
    procedure Load;

    procedure SetCurrentLevelToBestMatch(aPattern: String);

    procedure CreateBasePack;

    procedure SetLevel(aLevel: TNeoLevelEntry);
    procedure NextLevel(aCanCrossRank: Boolean = False);
    procedure PrevLevel(aCanCrossRank: Boolean = False);
    procedure SetGroup(aGroup: TNeoLevelGroup);
    procedure NextGroup;
    procedure PrevGroup;
    procedure LoadCurrentLevel(NoOutput: Boolean = False); // Loads level specified by CurrentLevel into Level, and prepares renderer
    procedure ReloadCurrentLevel(NoOutput: Boolean = False); // Re-prepares using the existing TLevel in memory
    function FindLevelFileByID(LevelID: string): string;
    function LoadLevelByID(aID: Int64): Boolean;

    procedure ElevateSaveCriticality(aCriticality: TGameParamsSaveCriticality);

    property CurrentLevel: TNeoLevelEntry read fCurrentLevel;

    property AutoSaveReplay: Boolean Index moAutoReplaySave read GetOptionFlag write SetOptionFlag;
    property EnableOnline: boolean Index moEnableOnline read GetOptionFlag write SetOptionFlag;
    property CheckUpdates: boolean Index moCheckUpdates read GetOptionFlag write SetOptionFlag;
    property AutoReplayMode: boolean Index moAutoReplayMode read GetOptionFlag write SetOptionFlag;
    property LoadNextUnsolvedLevel: boolean Index moLoadNextUnsolvedLevel read GetOptionFlag write SetOptionFlag;
    property ReplayAfterRestart: boolean Index moReplayAfterRestart read GetOptionFlag write SetOptionFlag;
    property PauseAfterBackwardsSkip: boolean Index moPauseAfterBackwards read GetOptionFlag write SetOptionFlag;
    property TurboFF: boolean Index moTurboFF read GetOptionFlag write SetOptionFlag;
    property NoBackgrounds: boolean Index moNoBackgrounds read GetOptionFlag write SetOptionFlag;
    property ColourCycle: boolean Index moColourCycle read GetOptionFlag write SetOptionFlag;
    property ShowButtonHints: boolean Index moShowButtonHints read GetOptionFlag write SetOptionFlag;
    property ClassicMode: boolean Index moClassicMode read GetOptionFlag write SetOptionFlag;
    property HideShadows: boolean Index moHideShadows read GetOptionFlag write SetOptionFlag;
    property HideHelpers: boolean Index moHideHelpers read GetOptionFlag write SetOptionFlag;
    property HideSkillQ: boolean Index moHideSkillQ read GetOptionFlag write SetOptionFlag;
    property HighResolution: boolean Index moHighResolution read GetOptionFlag write SetOptionFlag;
    property LinearResampleMenu: boolean Index moLinearResampleMenu read GetOptionFlag write SetOptionFlag;
    property FullScreen: boolean Index moFullScreen read GetOptionFlag write SetOptionFlag;
    property MinimapHighQuality: boolean Index moMinimapHighQuality read GetOptionFlag write SetOptionFlag;
    property ShowMinimap: boolean Index moShowMinimap read GetOptionFlag write SetOptionFlag;
    property IncreaseZoom: boolean Index moIncreaseZoom read GetOptionFlag write SetOptionFlag;
    property LoadedConfig: boolean Index moLoadedConfig read GetOptionFlag write SetOptionFlag;
    property CompactSkillPanel: boolean Index moCompactSkillPanel read GetOptionFlag write SetOptionFlag;
    property EdgeScroll: boolean Index moEdgeScroll read GetOptionFlag write SetOptionFlag;
    property SpawnInterval: boolean Index moSpawnInterval read GetOptionFlag write SetOptionFlag;
    property DisableMusicInTestplay: boolean Index moDisableMusicInTestplay read GetOptionFlag write SetOptionFlag;
    property PreferYippee: Boolean Index moPreferYippee read GetOptionFlag write SetOptionFlag;
    property PostviewJingles: Boolean Index moPostviewJingles read GetOptionFlag write SetOptionFlag;
    property MenuSounds: Boolean Index moMenuSounds read GetOptionFlag write SetOptionFlag;
    property AmigaTheme: Boolean Index moAmigaTheme read GetOptionFlag write SetOptionFlag;
    property FileCaching: boolean Index moFileCaching read GetOptionFlag write SetOptionFlag;

    property PlaybackModeActive: Boolean read fPlaybackModeActive write fPlaybackModeActive;
    property PlaybackOrder: TPlaybackOrder read fPlaybackOrder write fPlaybackOrder;
    property PlaybackList: TStringList read fPlaybackList write fPlaybackList;
    property UnmatchedList: TStringList read fUnmatchedList write fUnmatchedList;
    property ReplayVerifyList: TStringList read fReplayVerifyList write fReplayVerifyList;
    property PlaybackIndex: Integer read fPlaybackIndex write fPlaybackIndex;
    property AutoSkipPreviewPostview: Boolean read fAutoSkipPreviewPostview write fAutoSkipPreviewPostview;

    property MatchBlankReplayUsername: boolean Index moMatchBlankReplayUsername read GetOptionFlag write SetOptionFlag;
    property DumpMode: boolean read fDumpMode write fDumpMode;
    property OneLevelMode: boolean read fOneLevelMode write fOneLevelMode;
    property ShownText: boolean read fShownText write fShownText;
    //property DoneUpdateCheck: Boolean read fDoneUpdateCheck write fDoneUpdateCheck;

    property Directory: string read fDirectory write fDirectory;

    property ShowLevelSelectOptions: Boolean read fShowLevelSelectOptions write fShowLevelSelectOptions;

    property CursorResize: Double read fCursorResize write fCursorResize;
    property EdgeScrollSpeed: Integer read fEdgeScrollSpeed write fEdgeScrollSpeed;
    property ZoomLevel: Integer read fZoomLevel write fZoomLevel;
    property PanelZoomLevel: Integer read fPanelZoomLevel write fPanelZoomLevel;
    property WindowLeft: Integer read fWindowLeft write fWindowLeft;
    property WindowTop: Integer read fWindowTop write fWindowTop;
    property WindowWidth: Integer read fWindowWidth write fWindowWidth;
    property WindowHeight: Integer read fWindowHeight write fWindowHeight;

    property LoadedWindowLeft: Integer read fLoadedWindowLeft;
    property LoadedWindowTop: Integer read fLoadedWindowTop;
    property LoadedWindowWidth: Integer read fLoadedWindowWidth;
    property LoadedWindowHeight: Integer read fLoadedWindowHeight;

    property MainForm: TForm read fMainForm write fMainForm;

    property TalismanPage: Integer read fTalismanPage write fTalismanPage;

    property Hotkeys: TLemmixHotkeyManager read fHotkeys;

    property CurrentGroupName: String read GetCurrentGroupName;

    property Username: String read fUsername write SetUsername;
    property AutoSaveReplayPattern: String read fAutoSaveReplayPattern write fAutoSaveReplayPattern;
    property IngameSaveReplayPattern: String read fIngameSaveReplayPattern write fIngameSaveReplayPattern;
    property PostviewSaveReplayPattern: String read fPostviewSaveReplayPattern write fPostviewSaveReplayPattern;
    property DisableSaveOptions: Boolean read fDisableSaveOptions write fDisableSaveOptions;
  published
  end;

var
  GameParams: TDosGameParams; // Easier to just globalize this than constantly pass it around everywhere


implementation

uses
  FMain,
  Controls, UITypes,
  GameBaseScreenCommon, // For EXTRA_ZOOM_LEVELS const
  GameSound;

const
  DEFAULT_REPLAY_PATTERN_INGAME = '{TITLE}__{TIMESTAMP}';
  DEFAULT_REPLAY_PATTERN_AUTO = '{TITLE}__{TIMESTAMP}';
  DEFAULT_REPLAY_PATTERN_POSTVIEW = '*{TITLE}__{TIMESTAMP}';

{ TDosGameParams }

procedure TDosGameParams.Save(aCriticality: TGameParamsSaveCriticality);
var
  i: Integer;
  Attempts: Integer;
  Success: Boolean;
begin
  ElevateSaveCriticality(aCriticality);

  if TestModeLevel <> nil then Exit;
  if fDisableSaveOptions then Exit;
  if not LoadedConfig then Exit;
  if IsHalting then Exit;

  Success := False;
  Attempts := 2;
  case fSaveCriticality of
    scImportant: Attempts := 5;
    scCritical: Attempts := 10;
  end;

  for i := 1 to Attempts do
  begin
    try
      SaveToIniFile;
      BaseLevelPack.SaveUserData;

      Success := True;
    except
      Sleep(50);
    end;

    if Success then Break;
  end;

  if Success then
    fSaveCriticality := scNone
  else begin
    if fSaveCriticality = scCritical then
      ShowMessage('An error occured while trying to save data.')
    else
      Inc(fSaveCriticality);
  end;
end;

procedure TDosGameParams.Load;
begin
  if IsHalting then Exit;
  LoadFromIniFile;
  // Hotkeys automatically load when the hotkey manager is created
end;

procedure TDosGameParams.SaveToIniFile;
var
  SL, SL2: TStringList;
  LevelSavePath: String;

  procedure SaveBoolean(aLabel: String; aValue: Boolean; aValue2: Boolean = False);
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

  procedure AddUnknowns;
  var
    i: Integer;
    RemoveLine: Boolean;
  begin
    for i := SL2.Count-1 downto 0 do
    begin
      RemoveLine := False;
      if SL2[i] = '' then RemoveLine := True;
      if LeftStr(SL2[i], 1) = '#' then RemoveLine := True;
      if SL.IndexOfName(SL2.Names[i]) > -1 then RemoveLine := True;

      if RemoveLine then SL2.Delete(i);
    end;

    if SL2.Count = 0 then Exit;

    SL.Add('');
    SL.Add('# Preserved unknown options');
    for i := 0 to SL2.Count-1 do
      SL.Add(SL2[i]);
  end;

  procedure SaveString(aLabel, aValue: String);
  begin
    SL.Add(aLabel + '=' + aValue);
  end;
begin
  SL := TStringList.Create;
  SL2 := TStringList.Create;
  try
    ForceDirectories(AppPath + SFSaveData);
    if FileExists(AppPath + SFSaveData + 'settings.ini') then
      SL2.LoadFromFile(AppPath + SFSaveData + 'settings.ini')
    else if FileExists(AppPath + 'SuperLemmix147Settings.ini') then
      SL2.LoadFromFile(AppPath + 'SuperLemmix147Settings.ini');

    SL.Add('LastVersion=' + IntToStr(CurrentVersionID));
    SL.Add('UserName=' + UserName);

    SL.Add('');
    SL.Add('# Interface Options');
    SaveBoolean('AutoSaveReplay', AutoSaveReplay);
    SL.Add('AutoSaveReplayPattern=' + AutoSaveReplayPattern);
    SL.Add('IngameSaveReplayPattern=' + IngameSaveReplayPattern);
    SL.Add('PostviewSaveReplayPattern=' + PostviewSaveReplayPattern);
    SaveBoolean('LoadNextUnsolvedLevel', LoadNextUnsolvedLevel);
    SaveBoolean('AutoReplay', AutoReplayMode);
    SaveBoolean('ReplayAfterRestart', ReplayAfterRestart);
    SaveBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
    SaveBoolean('TurboFastForward', TurboFF);
    SaveBoolean('NoBackgrounds', NoBackgrounds);
    SaveBoolean('ColourCycle', ColourCycle);
    SaveBoolean('ShowButtonHints', ShowButtonHints);
    SaveBoolean('ClassicMode', ClassicMode);
    SaveBoolean('HideShadows', HideShadows);
    SaveBoolean('HideHelpers', HideHelpers);
    SaveBoolean('HideSkillQ', HideSkillQ);
    SaveBoolean('HighQualityMinimap', MinimapHighQuality);
    SaveBoolean('ShowMinimap', ShowMinimap);
    SaveBoolean('UseSpawnInterval', SpawnInterval);

    SaveBoolean('ShowLevelSelectOptions', ShowLevelSelectOptions);

    SaveBoolean('EdgeScrolling', EdgeScroll);
    SL.Add('EdgeScrollSpeed=' + IntToStr(EdgeScrollSpeed));

    SL.Add('ZoomLevel=' + IntToStr(ZoomLevel));
    SL.Add('PanelZoomLevel=' + IntToStr(PanelZoomLevel));
    SL.Add('CursorResize=' + FloatToStr(CursorResize));
    SaveBoolean('IncreaseZoom', IncreaseZoom);
    SaveBoolean('FullScreen', FullScreen);

    if not FullScreen then
    begin
      SL.Add('WindowLeft=' + IntToStr(WindowLeft));
      SL.Add('WindowTop=' + IntToStr(WindowTop));
      SL.Add('WindowWidth=' + IntToStr(WindowWidth));
      SL.Add('WindowHeight=' + IntToStr(WindowHeight));
    end;

    SaveBoolean('HighResolution', HighResolution);
    SaveBoolean('LinearResampleMenu', LinearResampleMenu);

    LevelSavePath := CurrentLevel.Path;
    if Pos(AppPath + SFLevels, LevelSavePath) = 1 then
      LevelSavePath := RightStr(LevelSavePath, Length(LevelSavePath) - Length(AppPath + SFLevels));
    SL.Add('LastActiveLevel=' + LevelSavePath);

    SL.Add('');
    SL.Add('# Sound Options');
    SaveBoolean('MusicEnabled', not SoundManager.MuteMusic);
    SaveBoolean('SoundEnabled', not SoundManager.MuteSound);
    SL.Add('MusicVolume=' + IntToStr(SoundManager.MusicVolume));
    SL.Add('SoundVolume=' + IntToStr(SoundManager.SoundVolume));
    SaveBoolean('DisableTestplayMusic', DisableMusicInTestplay);
    SaveBoolean('PreferYippee', PreferYippee);
    SaveBoolean('PostviewJingles', PostviewJingles);
    SaveBoolean('MenuSounds', MenuSounds);
    SaveBoolean('AmigaTheme', AmigaTheme);

    SL.Add('');
    SL.Add('# Playback Options');
    SaveBoolean('AutoSkipPreviewPostview', AutoSkipPreviewPostview);

    if (PlaybackOrder = poByReplay) then
      SaveString('PlaybackOrder', 'ByReplay')
    else if (PlaybackOrder = poByLevel) then
      SaveString('PlaybackOrder', 'ByLevel')
    else if (PlaybackOrder = poRandom) then
      SaveString('PlaybackOrder', 'Random');

    SL.Add('');
    SL.Add('# Technical Options');
    SaveBoolean('FileCaching', FileCaching);

    AddUnknowns;

    SL.SaveToFile(AppPath + SFSaveData + 'settings.ini');
  finally
    SL.Free;
    SL2.Free;
  end;
end;

procedure TDosGameParams.LoadFromIniFile;
var
  SL: TStringList;

  function LoadBoolean(aLabel: String; aDefault: Boolean): Boolean;
  begin
    // CANNOT load multi-saved in one for obvious reasons, those must be handled manually
    if (SL.Values[aLabel] = '0') then
      Result := False
    else if (SL.Values[aLabel] = '') then
      Result := aDefault
    else
      Result := True;
  end;

  procedure EnsureValidWindowSize;
  begin
    // Older config files might specify a zoom level of zero, to represent fullscreen.
    if ZoomLevel < 1 then
    begin
      FullScreen := True;
      ZoomLevel := Min(Screen.Width div 320 div ResMod, Screen.Height div 200 div ResMod);
    end;

    if ZoomLevel < 1 then
      ZoomLevel := 1;

    { Set window size to screen size if fullscreen. This doesn't get used directly,
      and will be overwritten when the user changes zoom settings (unless done by
      editing INI manually), but it keeps this function tidier. }
    if FullScreen then
    begin
      WindowLeft := 0;
      WindowTop := 0;
      WindowWidth := Screen.Width;
      WindowHeight := Screen.Height;
    end;

    // If no WindowWidth or WindowHeight is specified, we set them so they match 444x200 x ZoomLevel exactly.
    if (WindowWidth = -1) or (WindowHeight = -1) then
    begin
      TMainForm(MainForm).RestoreDefaultSize;
      TMainForm(MainForm).RestoreDefaultPosition;
    end else begin
      if (WindowLeft = -9999) and (WindowTop = -9999) then
        TMainForm(MainForm).RestoreDefaultPosition;

      // Once we've got our window size, ensure it can fit on the screen
      if fWindowWidth > Screen.Width then
        fWindowWidth := Screen.Width;
      if fWindowHeight > Screen.Height then
        fWindowHeight := Screen.Height;
    end;

    // Disallow zoom levels that are too high
    if fZoomLevel > Min(Screen.Width div 320 div ResMod, Screen.Height div 200 div ResMod) + EXTRA_ZOOM_LEVELS then
      fZoomLevel := Min(Screen.Width div 320 div ResMod, Screen.Height div 200 div ResMod);

    // Now validate the panel zoom
    if fPanelZoomLevel < 0 then
      fPanelZoomLevel := fZoomLevel;

      if GameParams.ShowMinimap then
      begin
        fPanelZoomLevel := Min(Screen.Width div 444 div ResMod, fPanelZoomLevel);
      end else begin
        fPanelZoomLevel := Min(Screen.Width div 336 div ResMod, fPanelZoomLevel);
      end;

    if fPanelZoomLevel < 1 then
      fPanelZoomLevel := 1;
  end;

  procedure ValidateEdgeScrollSpeed;
  begin
    if fEdgeScrollSpeed < 0 then
      fEdgeScrollSpeed := 0
    else if fEdgeScrollSpeed > 4 then
      fEdgeScrollSpeed := 4;
  end;

  procedure LoadPlaybackOrderOptions;
  var
    sOption: String;
  begin
    sOption := SL.Values['PlaybackOrder'];

    if (sOption = 'Random') then
      PlaybackOrder := poRandom
    else if (sOption = 'ByReplay') then
      PlaybackOrder := poByReplay
    else // Set default if the string is anything else
      PlaybackOrder := poByLevel;
  end;
begin
  SL := TStringList.Create;
  try
    if FileExists(AppPath + SFSaveData + 'settings.ini') then
    begin
      SL.LoadFromFile(AppPath + SFSaveData + 'settings.ini');
      LoadedConfig := True;
    end else if UnderWine then
    begin
      // When running under WINE without an existing config, let's default to windowed.
      FullScreen := False;
      ZoomLevel := Max(Max((Screen.Width - 100) div 444 div ResMod, (Screen.Height - 100) div 200 div ResMod), 1);
      TMainForm(GameParams.MainForm).RestoreDefaultSize;
      TMainForm(GameParams.MainForm).RestoreDefaultPosition;
    end;

    UserName := SL.Values['UserName'];

    AutoSaveReplay := LoadBoolean('AutoSaveReplay', AutoSaveReplay);
    AutoSaveReplayPattern := SL.Values['AutoSaveReplayPattern'];
    IngameSaveReplayPattern := SL.Values['IngameSaveReplayPattern'];
    PostviewSaveReplayPattern := SL.Values['PostviewSaveReplayPattern'];

    if AutoSaveReplayPattern = '' then AutoSaveReplayPattern := DEFAULT_REPLAY_PATTERN_AUTO;
    if IngameSaveReplayPattern = '' then IngameSaveReplayPattern := DEFAULT_REPLAY_PATTERN_INGAME;
    if PostviewSaveReplayPattern = '' then PostviewSaveReplayPattern := DEFAULT_REPLAY_PATTERN_POSTVIEW;

    AutoReplayMode := LoadBoolean('AutoReplay', AutoReplayMode);
    LoadNextUnsolvedLevel := LoadBoolean('LoadNextUnsolvedLevel', LoadNextUnsolvedLevel);
    ReplayAfterRestart := LoadBoolean('ReplayAfterRestart', ReplayAfterRestart);
    PauseAfterBackwardsSkip := LoadBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
    TurboFF := LoadBoolean('TurboFastForward', TurboFF);
    NoBackgrounds := LoadBoolean('NoBackgrounds', NoBackgrounds);
    ColourCycle := LoadBoolean('ColourCycle', ColourCycle);
    ShowButtonHints := LoadBoolean('ShowButtonHints', ShowButtonHints);
    ClassicMode := LoadBoolean('ClassicMode', ClassicMode);
    HideShadows := LoadBoolean('HideShadows', HideShadows);
    HideHelpers := LoadBoolean('HideHelpers', HideHelpers);
    HideSkillQ := LoadBoolean('HideSkillQ', HideSkillQ);
    MinimapHighQuality := LoadBoolean('HighQualityMinimap', MinimapHighQuality);
    ShowMinimap := LoadBoolean('ShowMinimap', ShowMinimap);
    IncreaseZoom := LoadBoolean('IncreaseZoom', IncreaseZoom);
    SpawnInterval := LoadBoolean('UseSpawnInterval', SpawnInterval);
    PreferYippee := LoadBoolean('PreferYippee', PreferYippee);

    EdgeScroll := LoadBoolean('EdgeScrolling', EdgeScroll);
    EdgeScrollSpeed := StrToIntDef(SL.Values['EdgeScrollSpeed'], 2);
    ValidateEdgeScrollSpeed;

    LoadPlaybackOrderOptions;
    AutoSkipPreviewPostview := LoadBoolean('AutoSkipPreviewPostview', AutoSkipPreviewPostview);

    SetCurrentLevelToBestMatch(SL.Values['LastActiveLevel']);

    FileCaching := LoadBoolean('FileCaching', FileCaching);

    ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], -1);
    PanelZoomLevel := StrToIntDef(SL.Values['PanelZoomLevel'], -1);

    CursorResize := StrToFloatDef(SL.Values['CursorResize'], CursorResize);

    if (StrToIntDef(SL.Values['LastVersion'], 0) div 1000) mod 100 < 16 then
      FullScreen := ZoomLevel < 1;
    FullScreen := LoadBoolean('FullScreen', FullScreen);

    WindowLeft := StrToIntDef(SL.Values['WindowLeft'], -9999);
    WindowTop := StrToIntDef(SL.Values['WindowTop'], -9999);
    WindowWidth := StrToIntDef(SL.Values['WindowWidth'], -1);
    WindowHeight := StrToIntDef(SL.Values['WindowHeight'], -1);

    HighResolution := LoadBoolean('HighResolution', HighResolution);

    EnsureValidWindowSize;

    fLoadedWindowLeft := WindowLeft;
    fLoadedWindowTop := WindowTop;
    fLoadedWindowWidth := WindowWidth;
    fLoadedWindowHeight := WindowHeight;

    LinearResampleMenu := LoadBoolean('LinearResampleMenu', LinearResampleMenu);

    PostviewJingles := LoadBoolean('PostviewJingles', PostviewJingles);
    MenuSounds := LoadBoolean('MenuSounds', MenuSounds);
    AmigaTheme := LoadBoolean('AmigaTheme', AmigaTheme);

    ShowLevelSelectOptions := LoadBoolean('ShowLevelSelectOptions', ShowLevelSelectOptions);

    DisableMusicInTestplay := LoadBoolean('DisableTestplayMusic', DisableMusicInTestplay);

    SoundManager.MuteSound := not LoadBoolean('SoundEnabled', not SoundManager.MuteSound);
    SoundManager.SoundVolume := StrToIntDef(SL.Values['SoundVolume'], 50);
    SoundManager.MuteMusic := not LoadBoolean('MusicEnabled', not SoundManager.MuteMusic);
    SoundManager.MusicVolume := StrToIntDef(SL.Values['MusicVolume'], 50);
  except
    on E: Exception do
    begin
      fDisableSaveOptions := True;
      ShowMessage('Error during settings loading:' + #10 +
                   E.ClassName + ': ' + E.Message + #10 +
                   'Default settings have been loaded. Customizations to settings during this session will not be saved.');
    end;
  end;

  SL.Free;
end;

function TDosGameParams.LoadLevelByID(aID: Int64): Boolean;
var
  G: TNeoLevelGroup;

  function SearchGroup(aGroup: TNeoLevelGroup): Boolean;
  var
    i: Integer;
  begin
    Result := False;

    for i := 0 to aGroup.Children.Count-1 do
    begin
      Result := SearchGroup(aGroup.Children[i]);
      if Result then Exit;
    end;

    for i := 0 to aGroup.Levels.Count-1 do
      if aGroup.Levels[i].LevelID = aID then
      begin
        SetLevel(aGroup.Levels[i]);
        LoadCurrentLevel(True);
        Result := True;
      end;
  end;
begin
  G := GameParams.CurrentLevel.Group;
  while (G.Parent <> nil) and (not G.IsBasePack) do
    G := G.Parent;
  Result := SearchGroup(G);
end;

function TDosGameParams.FindLevelFileByID(LevelID: string): string;
var
  LevelFiles: TStringDynArray;
  RootDir, LevelsDir, RelativePath, FolderNames: string;
  MatchingFiles: TStringList;
  i, ListWidth, StringWidth: Integer;
  AdjustDialogWidth: Boolean;
  FileContent: TStringList;
  LevelDialog: TFLevelListDialog;
begin
  Result := '';

  // Get the directory containing the .exe and find the levels folder
  RootDir := ExtractFilePath(ParamStr(0));
  LevelsDir := TPath.Combine(RootDir, SFLevels);

  // Search for .nxlv files in the levels folder, or cancel if it doesn't exist
  if TDirectory.Exists(LevelsDir) then
    LevelFiles := TDirectory.GetFiles(LevelsDir, '*.nxlv', TSearchOption.soAllDirectories)
  else
  begin
    ShowMessage('Levels folder not found.');
    Exit;
  end;

  if Length(LevelFiles) > 0 then
  begin
    MatchingFiles := TStringList.Create;

    try
      // Check each .nxlv file for matching LevelID
      for i := 0 to Length(LevelFiles) - 1 do
      begin
        FileContent := TStringList.Create;
        try
          FileContent.LoadFromFile(LevelFiles[i]);

          if Pos('ID ' + LevelID, FileContent.Text) > 0 then
            MatchingFiles.Add(LevelFiles[i]);
        finally
          FileContent.Free;
        end;
      end;

      if MatchingFiles.Count = 0 then
      begin
        ShowMessage('No .nxlv files found with Level ID: ' + LevelID);
        Exit;
      // If only one matching file is found, load it directly
      end else if MatchingFiles.Count = 1 then
        Result := MatchingFiles[0]
      else begin
        // If multiple matching files are found, show level select dialog
        LevelDialog := TFLevelListDialog.Create(nil);
        try
          ListWidth := LevelDialog.MatchingLevelsList.Width;
          AdjustDialogWidth := False;

          for i := 0 to MatchingFiles.Count - 1 do
          begin
            // Extract the relative path starting after the 'levels' directory
            RelativePath := StringReplace(MatchingFiles[i], LevelsDir, '', [rfIgnoreCase]);

            // Extract the folder names and replace characters
            FolderNames := ExtractFileDir(RelativePath);
            FolderNames := StringReplace(FolderNames, '\', ' / ', [rfReplaceAll]);
            FolderNames := StringReplace(FolderNames, '_', ' ', [rfReplaceAll]);

            // Construct the display string and add it to the matching levels list
            var DisplayString := ExtractFileName(MatchingFiles[i]) + ' (' + FolderNames + ')';
            LevelDialog.MatchingLevelsList.Items.Add(DisplayString);

            // Measure the width of the string so the dialog can fully accomodate it
            StringWidth := LevelDialog.Canvas.TextWidth(DisplayString);

            if StringWidth > ListWidth then
            begin
              ListWidth := StringWidth;
              AdjustDialogWidth := True;
            end;
          end;

          // If necessary, adjust the width of the dialog (include padding)
          if AdjustDialogWidth then
          begin
            LevelDialog.ClientWidth := ListWidth + 40;
            LevelDialog.MatchingLevelsList.Width := ListWidth + 20;
          end;

          if LevelDialog.ShowModal = mrOk then
            Result := MatchingFiles[LevelDialog.MatchingLevelsList.ItemIndex]
          else
            Exit;
        finally
          LevelDialog.Free;
        end;
      end;
    finally
      MatchingFiles.Free;
    end;
  end else
    ShowMessage('No .nxlv files found in directory: ' + LevelsDir);
end;

procedure TDosGameParams.LoadCurrentLevel(NoOutput: Boolean = False);
begin
  if CurrentLevel = nil then Exit;

  if not FileExists(CurrentLevel.Path) then
  begin
    MessageDlg('Loading failed: No file at location: ' + CurrentLevel.Path, mtWarning, [mbOK], 0);
    Exit;
  end;

  Level.LoadFromFile(CurrentLevel.Path);
  PieceManager.Tidy;

  Renderer.PrepareGameRendering(Level, NoOutput);
end;

procedure TDosGameParams.ReloadCurrentLevel(NoOutput: Boolean = False);
begin
  PieceManager.Tidy;
  Renderer.PrepareGameRendering(Level, NoOutput);
end;

procedure TDosGameParams.SetLevel(aLevel: TNeoLevelEntry);
begin
  fCurrentLevel := aLevel;
end;

procedure TDosGameParams.NextLevel(aCanCrossRank: Boolean);
var
  CurLevel: TNeoLevelEntry;
  CurLevelGroup: TNeoLevelGroup;
  CurLevelIndex: Integer;
begin
  CurLevel := fCurrentLevel;
  CurLevelGroup := CurLevel.Group;
  CurLevelIndex := CurLevelGroup.LevelIndex[CurLevel];
  if CurLevelIndex = CurLevelGroup.Levels.Count-1 then
  begin
    if aCanCrossRank then
    begin
      NextGroup;
      CurLevelGroup := fCurrentLevel.Group;
    end;
    fCurrentLevel := CurLevelGroup.Levels[0];
  end else
    fCurrentLevel := CurLevelGroup.Levels[CurLevelIndex + 1];

  ShownText := False;
end;

procedure TDosGameParams.PrevLevel(aCanCrossRank: Boolean);
var
  CurLevel: TNeoLevelEntry;
  CurLevelGroup: TNeoLevelGroup;
  CurLevelIndex: Integer;
begin
  CurLevel := fCurrentLevel;
  CurLevelGroup := CurLevel.Group;
  CurLevelIndex := CurLevelGroup.LevelIndex[CurLevel];
  if CurLevelIndex = 0 then
  begin
    if aCanCrossRank then
    begin
      PrevGroup;
      CurLevelGroup := fCurrentLevel.Group;
    end;
    fCurrentLevel := CurLevelGroup.Levels[CurLevelGroup.Levels.Count-1];
  end else begin
    fCurrentLevel := CurLevelGroup.Levels[CurLevelIndex - 1];
  end;

  ShownText := False;
end;

procedure TDosGameParams.SetCurrentLevelToBestMatch(aPattern: String);
type
  TMatchType = (mtNone, mtPartial, mtFull);
var
  DeepestMatchGroup: TNeoLevelGroup;
  MatchGroup: TNeoLevelGroup;
  MatchLevel: TNeoLevelEntry;

  function GetLongestMatchIn(aPack: TNeoLevelGroup): TMatchType;
  var
    i: Integer;
  begin
    Result := mtNone;
    MatchGroup := nil;
    MatchLevel := nil;

    for i := 0 to aPack.Children.Count-1 do
      if ((MatchGroup = nil) or (Length(aPack.Children[i].Path) > Length(MatchGroup.Path))) and
         (LeftStr(aPattern, Length(aPack.Children[i].Path)) = aPack.Children[i].Path) then
      begin
        Result := mtPartial;
        MatchGroup := aPack.Children[i];
      end;

    for i := 0 to aPack.Levels.Count-1 do
      if aPack.Levels[i].Path = aPattern then
      begin
        Result := mtFull;
        MatchLevel := aPack.Levels[i];
        Exit;
      end;
  end;

  function RecursiveSearch(aPack: TNeoLevelGroup): TNeoLevelEntry;
  begin
    Result := nil;
    DeepestMatchGroup := aPack;

    case GetLongestMatchIn(aPack) of
      //mtNone: Result of "nil" sticks
      mtPartial: Result := RecursiveSearch(MatchGroup);
      mtFull: Result := MatchLevel;
    end;
  end;
begin
  // Tries to set the exact level. If the level is missing, try to set to the rank it's supposedly in;
  // If that fails, the pack the rank is in, etc. If there's no sane result whatsoever, do nothing.
  // This is used for the LastActiveLevel setting in settings.ini, and the -shortcut command line parameter.

  if not TPath.IsPathRooted(aPattern) then
    aPattern := AppPath + SFLevels + aPattern;

  MatchLevel := RecursiveSearch(BaseLevelPack);

  if (MatchLevel <> nil) then
    SetLevel(MatchLevel)
  else if (DeepestMatchGroup <> nil) then
    SetLevel(DeepestMatchGroup.FirstUnbeatenLevelRecursive);
end;

procedure TDosGameParams.SetGroup(aGroup: TNeoLevelGroup);
begin
  try
    if aGroup.Levels.Count = 0 then
      SetLevel(aGroup.FirstUnbeatenLevelRecursive)
    else
      SetLevel(aGroup.FirstUnbeatenLevel);
  except
    // We don't have levels in this group
    On E : EAccessViolation do
      SetLevel(nil);
  end;
end;

procedure TDosGameParams.NextGroup;
begin
  SetLevel(CurrentLevel.Group.NextGroup.FirstUnbeatenLevel);
end;

procedure TDosGameParams.PrevGroup;
begin
  SetLevel(CurrentLevel.Group.PrevGroup.FirstUnbeatenLevel);
end;


constructor TDosGameParams.Create;
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;

  UserName := 'Player 1';

  SoundManager.MusicVolume := 50;
  SoundManager.SoundVolume := 50;
  fDumpMode := False;
  fShownText := False;
  fOneLevelMode := False;
  fTalismanPage := 0;
  fZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);
  fPanelZoomLevel := Min(fZoomLevel, Screen.Width div 444);
  fEdgeScrollSpeed := 2;
  fCursorResize := 1;
  fShowLevelSelectOptions := True;

  PlaybackOrder := poByLevel;
  fAutoSkipPreviewPostview := True;

  LemDataInResource := True;
  LemSoundsInResource := True;
  LemMusicInResource := True;

  try
    fHotkeys := TLemmixHotkeyManager.Create;
  except
    on E: Exception do
      ShowMessage('Error during hotkey loading:' + #10 +
                   E.ClassName + ': ' + E.Message + #10 +
                   'Default hotkeys have been loaded. Customizations to hotkeys during this session will not be saved.');
  end;

  PlaybackList := TStringList.Create;
  UnmatchedList := TStringList.Create;
  ReplayVerifyList := TStringList.Create;
end;

procedure TDosGameParams.CreateBasePack;
var
  buttonSelected: Integer;
begin
  if not DirectoryExists(AppPath + SFLevels) then
  begin
    buttonSelected := MessageDlg('Could not find any levels in the folder levels\. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  try
    BaseLevelPack := TNeoLevelGroup.Create(nil, AppPath + SFLevels);
  except
    on E: Exception do
      ShowMessage('Error loading level packs and/or progression. Progress will not be saved during this session.');
  end;

  try
    SetLevel(BaseLevelPack.FirstUnbeatenLevelRecursive);
  except
    on E : EAccessViolation do
      SetLevel(nil);
  end;
end;

destructor TDosGameParams.Destroy;
begin
  fHotkeys.Free;
  BaseLevelPack.Free;
  PlaybackList.Free;
  UnmatchedList.Free;
  ReplayVerifyList.Free;
  inherited Destroy;
end;

procedure TDosGameParams.ElevateSaveCriticality(aCriticality: TGameParamsSaveCriticality);
begin
  if fSaveCriticality < aCriticality then
    fSaveCriticality := aCriticality;
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

procedure TDosGameParams.SetUserName(aValue: String);
begin
  if aValue = '' then
    fUsername := 'Player 1'
  else
    fUsername := aValue;
end;

function TDosGameParams.GetCurrentGroupName: String;
begin
  Result := CurrentLevel.Group.Name;
end;

end.

