{$include lem_directives.inc}

unit GameControl;

{-------------------------------------------------------------------------------
  The gamecontrol class is in fact just a global var which is passed through as
  a parameter to all screens.
-------------------------------------------------------------------------------}

interface

uses
  LemmixHotkeys,
  Math,
  Dialogs, SysUtils, Classes, Forms, GR32,
  LemVersion,
  LemTypes, LemLevel, LemDosStyle,
  LemDosStructures,
  LemNeoSave, TalisData,
  LemLevelSystem, LemRendering;

var
  IsHalting: Boolean; // ONLY used during AppController's init routines. Don't use this anywhere else.
                      // Shouldn't even be used there really, but a kludgy fix is okay since that's gonna
                      // be replaced once proper level select menus are introduced. 

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
    gstTalisman,
    gstReplayTest
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
    moLookForLVLFiles,
    moChallengeMode,
    moTimerMode,
    moAutoReplayNames,
    moLemmingBlink,
    moTimerBlink,
    moAutoReplaySave,
    moAlwaysTimestamp,
    moConfirmOverwrite,
    moExplicitCancel,
    moBlackOutZero,
    moEnableOnline,
    moCheckUpdates,
    moNoAutoReplayMode,
    moPauseAfterBackwards,
    moNoBackgrounds,
    moNoShadows,
    moDisableWineWarnings,
    moLinearResampleMenu,
    moLinearResampleGame,
    moFullScreen,
    moMinimapHighQuality,
    moIncreaseZoom
  );

  TMiscOptions = set of TMiscOption;

  TPostLevelSoundOption = (plsVictory, plsFailure);
  TPostLevelSoundOptions = set of TPostLevelSoundOption;

const
  DEF_MISCOPTIONS = [
    moAutoReplayNames,
    moTimerBlink,
    moAlwaysTimestamp,
    moAutoReplaySave,
    moBlackOutZero,
    moPauseAfterBackwards,
    moLinearResampleMenu,
    moFullScreen,
    moMinimapHighQuality,
    moIncreaseZoom
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
    fWindowWidth: Integer;
    fWindowHeight: Integer;

    fMainForm: TForm; // link to the FMain form

    MiscOptions           : TMiscOptions;
    PostLevelSoundOptions : TPostLevelSoundOptions;

    function GetOptionFlag(aFlag: TMiscOption): Boolean;
    procedure SetOptionFlag(aFlag: TMiscOption; aValue: Boolean);

    function GetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption): Boolean;
    procedure SetPostLevelSoundOptionFlag(aFlag: TPostLevelSoundOption; aValue: Boolean);

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
    ReplayCheckPath: String;

    constructor Create;
    destructor Destroy; override;
    property SaveSystem: TNeoSave read fSaveSystem;

    procedure Save;
    procedure Load;

    property LookForLVLFiles: Boolean Index moLookForLVLFiles read GetOptionFlag write SetOptionFlag;
    property ChallengeMode: Boolean Index moChallengeMode read GetOptionFlag write SetOptionFlag;
    property TimerMode: Boolean Index moTimerMode read GetOptionFlag write SetOptionFlag;
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
    property NoShadows: boolean Index moNoShadows read GetOptionFlag write SetOptionFlag;
    property DisableWineWarnings: boolean Index moDisableWineWarnings read GetOptionFlag write SetOptionFlag;
    property LinearResampleMenu: boolean Index moLinearResampleMenu read GetOptionFlag write SetOptionFlag;
    property LinearResampleGame: boolean Index moLinearResampleGame read GetOptionFlag write SetOptionFlag;
    property FullScreen: boolean Index moFullScreen read GetOptionFlag write SetOptionFlag;
    property MinimapHighQuality: boolean Index moMinimapHighQuality read GetOptionFlag write SetOptionFlag;
    property IncreaseZoom: boolean Index moIncreaseZoom read GetOptionFlag write SetOptionFlag;

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
    property WindowWidth: Integer read fWindowWidth write fWindowWidth;
    property WindowHeight: Integer read fWindowHeight write fWindowHeight;

    property MainForm: TForm read fMainForm write fMainForm;

    property Talismans: TTalismans read fTalismans;
    property TalismanPage: Integer read fTalismanPage write fTalismanPage;

    property Hotkeys: TLemmixHotkeyManager read fHotkeys;
  published
  end;

var
  GameParams: TDosGameParams; // Easier to just globalize this than constantly pass it around everywhere


implementation

uses
  GameWindow, //for EXTRA_ZOOM_LEVELS const
  GameSound;

{ TDosGameParams }

procedure TDosGameParams.Save;
begin
  if IsHalting then Exit;
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
  if IsHalting then Exit;
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

  SL.Add('LastVersion=' + IntToStr(CurrentVersionID));

  SL.Add('');
  SL.Add('# Interface Options');
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
  SaveBoolean('NoShadows', NoShadows);
  SaveBoolean('HighQualityMinimap', MinimapHighQuality);

  SL.Add('ZoomLevel=' + IntToStr(ZoomLevel));
  SaveBoolean('IncreaseZoom', IncreaseZoom);
  SaveBoolean('FullScreen', FullScreen);

  SL.Add('WindowWidth=' + IntToStr(WindowWidth));
  SL.Add('WindowHeight=' + IntToStr(WindowHeight));

  SaveBoolean('LinearResampleMenu', LinearResampleMenu);
  SaveBoolean('LinearResampleGame', LinearResampleGame);

  SL.Add('');
  SL.Add('# Sound Options');
  SaveBoolean('MusicEnabled', not SoundManager.MuteMusic);
  SaveBoolean('SoundEnabled', not SoundManager.MuteSound);
  SL.Add('MusicVolume=' + IntToStr(SoundManager.MusicVolume));
  SL.Add('SoundVolume=' + IntToStr(SoundManager.SoundVolume));
  SaveBoolean('VictoryJingle', PostLevelVictorySound);
  SaveBoolean('FailureJingle', PostLevelFailureSound);

  SL.Add('');
  SL.Add('# Online Options');
  SaveBoolean('EnableOnline', EnableOnline);
  SaveBoolean('UpdateCheck', CheckUpdates);

  if UnderWine then
  begin
    SL.Add('');
    SL.Add('# WINE Options');
    SaveBoolean('DisableWineWarnings', DisableWineWarnings);
  end;


  SL.SaveToFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini');

  SL.Free;
end;

procedure TDosGameParams.LoadFromIniFile;
var
  SL: TStringList;

  function LoadBoolean(aLabel: String; aDefault: Boolean): Boolean;
  begin
    // CANNOT load multi-saved in one for obvious reasons, those must be handled manually
    if (SL.Values[aLabel] = '0') then
      Result := false
    else if (SL.Values[aLabel] = '') then
      Result := aDefault
    else
      Result := true;
  end;

  procedure EnsureValidWindowSize;
  begin
    // Older config files might specify a zoom level of zero, to represent fullscreen.
    if ZoomLevel < 1 then
    begin
      FullScreen := true;
      ZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);
    end;

    if ZoomLevel < 1 then
      ZoomLevel := 1;

    // Set window size to screen size if fullscreen. This doesn't get used directly,
    // and will be overwritten when the user changes zoom settings (unless done by
    // editing INI manually), but it keeps this function tidier.
    if FullScreen then
    begin
      WindowWidth := Screen.Width;
      WindowHeight := Screen.Height;
    end;

    // If no WindowWidth or WindowHeight is specified, we want to set them so that they
    // match 416x200 x ZoomLevel exactly.
    if (WindowWidth = -1) or (WindowHeight = -1) then
    begin
      WindowWidth := ZoomLevel * 416;
      WindowHeight := ZoomLevel * 200;
    end;

    // Once we've got our window size, ensure it can fit on the screen
    if fWindowWidth > Screen.Width then
      fWindowWidth := Screen.Width;
    if fWindowHeight > Screen.Height then
      fWindowHeight := Screen.Height;

    // Disallow zoom levels that are too high
    if fZoomLevel > Min(Screen.Width div 320, Screen.Height div 200) then
      fZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);

    // Finally, we must make sure the window size is an integer multiple of the zoom level
    WindowWidth := (WindowWidth div ZoomLevel) * ZoomLevel;
    WindowHeight := (WindowHeight div ZoomLevel) * ZoomLevel;
  end;

begin
  if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini') then
    if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini') then
    begin
      if UnderWine then
      begin
        // When running under WINE without an existing config, let's default to windowed.
        FullScreen := false;
        ZoomLevel := Max(Max((Screen.Width - 100) div 416, (Screen.Height - 100) div 200), 1);
        WindowWidth := 416 * ZoomLevel;
        WindowHeight := 200 * ZoomLevel;
      end;
      Exit;
    end;

  SL := TStringList.Create;

  if not FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini') then
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixSettings.ini')
  else
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmix147Settings.ini');

  AutoReplayNames := LoadBoolean('AutoReplayNames', AutoReplayNames);
  AutoSaveReplay := LoadBoolean('AutoSaveReplay', AutoSaveReplay);
  LemmingBlink := LoadBoolean('LemmingCountBlink', LemmingBlink);
  TimerBlink := LoadBoolean('TimerBlink', TimerBlink);
  AlwaysTimestamp := LoadBoolean('AlwaysTimestampReplays', AlwaysTimestamp);
  ConfirmOverwrite := LoadBoolean('ConfirmReplayOverwrite', ConfirmOverwrite);
  ExplicitCancel := LoadBoolean('ExplicitReplayCancel', ExplicitCancel);
  NoAutoReplayMode := LoadBoolean('NoAutoReplay', NoAutoReplayMode);
  PauseAfterBackwardsSkip := LoadBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
  BlackOutZero := LoadBoolean('BlackOutZero', BlackOutZero);
  NoBackgrounds := LoadBoolean('NoBackgrounds', NoBackgrounds);
  NoShadows := LoadBoolean('NoShadows', NoShadows);
  MinimapHighQuality := LoadBoolean('HighQualityMinimap', MinimapHighQuality);
  IncreaseZoom := LoadBoolean('IncreaseZoom', IncreaseZoom);
  EnableOnline := LoadBoolean('EnableOnline', EnableOnline);
  CheckUpdates := LoadBoolean('UpdateCheck', CheckUpdates);

  DisableWineWarnings := LoadBoolean('DisableWineWarnings', DisableWineWarnings);

  FullScreen := LoadBoolean('FullScreen', FullScreen);

  ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], -1);

  WindowWidth := StrToIntDef(SL.Values['WindowWidth'], -1);
  WindowHeight := StrToIntDef(SL.Values['WindowHeight'], -1);

  EnsureValidWindowSize;

  LinearResampleMenu := LoadBoolean('LinearResampleMenu', LinearResampleMenu);
  LinearResampleGame := LoadBoolean('LinearResampleGame', LinearResampleGame);


  PostLevelVictorySound := LoadBoolean('VictoryJingle', PostLevelVictorySound);
  PostLevelFailureSound := LoadBoolean('FailureJingle', PostLevelFailureSound);

  SoundManager.MuteSound := not LoadBoolean('SoundEnabled', not SoundManager.MuteSound);
  SoundManager.SoundVolume := StrToIntDef(SL.Values['SoundVolume'], 50);
  SoundManager.MuteMusic := not LoadBoolean('MusicEnabled', not SoundManager.MuteMusic);
  SoundManager.MusicVolume := StrToIntDef(SL.Values['MusicVolume'], 50);

  SL.Free;
end;


constructor TDosGameParams.Create;
var
  TempStream: TMemoryStream; //for loading talisman data
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;
  PostLevelSoundOptions := [plsVictory, plsFailure];

  SoundManager.MusicVolume := 50;
  SoundManager.SoundVolume := 50;
  fForceSkillset := 0;
  fDumpMode := false;
  fTestScreens := 0;
  fShownText := false;
  fOneLevelMode := false;
  fTalismanPage := 0;
  fZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);

  LemDataInResource := True;
  LemSoundsInResource := True;
  LemMusicInResource := True;

  fSaveSystem := TNeoSave.Create;
  fTalismans := TTalismans.Create;


  TempStream := CreateDataStream('talisman.dat', ldtLemmings);
  if TempStream <> nil then
  begin
    fTalismans.LoadFromStream(TempStream);
    TempStream.Free;
  end;

  fTalismans.SortTalismans;

  fSaveSystem.SetTalismans(fTalismans);

  fHotkeys := TLemmixHotkeyManager.Create;
end;

destructor TDosGameParams.Destroy;
begin
  fSaveSystem.Free;
  fTalismans.Free;
  fHotkeys.Free;
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

end.

