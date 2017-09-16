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
  Dialogs, SysUtils, StrUtils, Classes, Forms, GR32,
  LemVersion,
  LemTypes, LemLevel,
  LemDosStructures,
  LemStrings,
  LemRendering;

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
    gstSounds,
    gstExit,
    gstText,
    gstTalisman,
    gstReplayTest
  );

type
  TGameSoundOption = (
    gsoSound,
    gsoMusic
  );
  TGameSoundOptions = set of TGameSoundOption;

type
  TMiscOption = (
    moLemmingBlink,
    moTimerBlink,
    moAutoReplaySave,
    moReplayAutoName,
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
    moIncreaseZoom,
    moLoadedConfig,
    moCompactSkillPanel,
    moEdgeScroll,
    moSpawnInterval
  );

  TMiscOptions = set of TMiscOption;

  TPostLevelSoundOption = (plsVictory, plsFailure);
  TPostLevelSoundOptions = set of TPostLevelSoundOption;

const
  DEF_MISCOPTIONS = [
    moTimerBlink,
    moAutoReplaySave,
    moReplayAutoName,
    moBlackOutZero,
    moPauseAfterBackwards,
    moLinearResampleMenu,
    moFullScreen,
    moMinimapHighQuality,
    moIncreaseZoom,
    moEdgeScroll
  ];

type

  TDosGameParams = class(TPersistent)
  private
    fHotkeys: TLemmixHotkeyManager;
    fTalismanPage: Integer;
    fDirectory    : string;
    fDumpMode : Boolean;
    fShownText: Boolean;
    fOneLevelMode: Boolean;
    fDoneUpdateCheck: Boolean;
    fCurrentLevel: TNeoLevelEntry;

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

    function GetCurrentGroupName: String;
  public
    // this is initialized by appcontroller
    MainDatFile  : string;

    SoundOptions : TGameSoundOptions;

    Level        : TLevel;
    Renderer     : TRenderer;

    LevelString: String;
    BaseLevelPack: TNeoLevelGroup;


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
    fLevelOverride       : Integer;

    //SysDat               : TSysDatRec;
    ReplayCheckPath: String;

    TestModeLevel: TNeoLevelEntry;

    constructor Create;
    destructor Destroy; override;

    procedure Save;
    procedure Load;

    procedure SetLevel(aLevel: TNeoLevelEntry);
    procedure NextLevel(aCanCrossRank: Boolean = false);
    procedure PrevLevel(aCanCrossRank: Boolean = false);
    procedure SetGroup(aGroup: TNeoLevelGroup);
    procedure NextGroup;
    procedure PrevGroup;
    procedure LoadCurrentLevel(NoOutput: Boolean = false); // loads level specified by CurrentLevel into Level, and prepares renderer

    property CurrentLevel: TNeoLevelEntry read fCurrentLevel;

    property AutoSaveReplay: Boolean Index moAutoReplaySave read GetOptionFlag write SetOptionFlag;
    property ReplayAutoName: Boolean Index moReplayAutoName read GetOptionFlag write SetOptionFlag;
    property LemmingBlink: Boolean Index moLemmingBlink read GetOptionFlag write SetOptionFlag;
    property TimerBlink: Boolean Index moTimerBlink read GetOptionFlag write SetOptionFlag;
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
    property LoadedConfig: boolean Index moLoadedConfig read GetOptionFlag write SetOptionFlag;
    property CompactSkillPanel: boolean Index moCompactSkillPanel read GetOptionFlag write SetOptionFlag;
    property EdgeScroll: boolean Index moEdgeScroll read GetOptionFlag write SetOptionFlag;
    property SpawnInterval: boolean Index moSpawnInterval read GetOptionFlag write SetOptionFlag;

    property PostLevelVictorySound: Boolean Index plsVictory read GetPostLevelSoundOptionFlag write SetPostLevelSoundOptionFlag;
    property PostLevelFailureSound: Boolean Index plsFailure read GetPostLevelSoundOptionFlag write SetPostLevelSoundOptionFlag;

    property DumpMode: boolean read fDumpMode write fDumpMode;
    property OneLevelMode: boolean read fOneLevelMode write fOneLevelMode;
    property ShownText: boolean read fShownText write fShownText;
    property DoneUpdateCheck: Boolean read fDoneUpdateCheck write fDoneUpdateCheck;

    property Directory: string read fDirectory write fDirectory;

    property ZoomLevel: Integer read fZoomLevel write fZoomLevel;
    property WindowWidth: Integer read fWindowWidth write fWindowWidth;
    property WindowHeight: Integer read fWindowHeight write fWindowHeight;

    property MainForm: TForm read fMainForm write fMainForm;

    property TalismanPage: Integer read fTalismanPage write fTalismanPage;

    property Hotkeys: TLemmixHotkeyManager read fHotkeys;

    property CurrentGroupName: String read GetCurrentGroupName;
  published
  end;

var
  GameParams: TDosGameParams; // Easier to just globalize this than constantly pass it around everywhere


implementation

uses
  SharedGlobals, Controls, UITypes,
  GameWindow, //for EXTRA_ZOOM_LEVELS const
  GameSound;

{ TDosGameParams }

procedure TDosGameParams.Save;
begin
  if IsHalting then Exit;
  try
    SaveToIniFile;
    BaseLevelPack.SaveUserData;
    Hotkeys.SaveFile;
  except
    ShowMessage('An error occured while trying to save data.');
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

  procedure AddUnknowns;
  var
    i: Integer;
    RemoveLine: Boolean;
  begin
    for i := SL2.Count-1 downto 0 do
    begin
      RemoveLine := false;
      if SL2[i] = '' then RemoveLine := true;
      if LeftStr(SL2[i], 1) = '#' then RemoveLine := true;
      if SL.IndexOfName(SL2.Names[i]) > -1 then RemoveLine := true;

      if RemoveLine then SL2.Delete(i);
    end;

    if SL2.Count = 0 then Exit;

    SL.Add('');
    SL.Add('# Preserved unknown options');
    for i := 0 to SL2.Count-1 do
      SL.Add(SL2[i]);
  end;
begin
  //if fTestMode then Exit;
  SL := TStringList.Create;
  SL2 := TStringList.Create;

  ForceDirectories(AppPath + SFSaveData);
  if FileExists(AppPath + SFSaveData + 'settings.ini') then
    SL2.LoadFromFile(AppPath + SFSaveData + 'settings.ini')
  else if FileExists(AppPath + 'NeoLemmix147Settings.ini') then
    SL2.LoadFromFile(AppPath + 'NeoLemmix147Settings.ini');

  SL.Add('LastVersion=' + IntToStr(CurrentVersionID));

  SL.Add('');
  SL.Add('# Interface Options');
  SaveBoolean('AutoSaveReplay', AutoSaveReplay);
  SaveBoolean('NoAutoReplay', NoAutoReplayMode);
  SaveBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
  SaveBoolean('LemmingCountBlink', LemmingBlink);
  SaveBoolean('TimerBlink', TimerBlink);
  SaveBoolean('BlackOutZero', BlackOutZero);
  SaveBoolean('NoBackgrounds', NoBackgrounds);
  SaveBoolean('NoShadows', NoShadows);
  SaveBoolean('CompactSkillPanel', CompactSkillPanel);
  SaveBoolean('HighQualityMinimap', MinimapHighQuality);
  SaveBoolean('EdgeScrolling', EdgeScroll);
  SaveBoolean('UseSpawnInterval', SpawnInterval);

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
    SL.Add('# Technical Options');
    SaveBoolean('DisableWineWarnings', DisableWineWarnings);
  end;

  AddUnknowns;

  SL.SaveToFile(AppPath + SFSaveData + 'settings.ini');

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
      if CompactSkillPanel then
        WindowWidth := ZoomLevel * 320
      else
        WindowWidth := ZoomLevel * 416;
      WindowHeight := ZoomLevel * 200;
    end;

    // Once we've got our window size, ensure it can fit on the screen
    if fWindowWidth > Screen.Width then
      fWindowWidth := Screen.Width;
    if fWindowHeight > Screen.Height then
      fWindowHeight := Screen.Height;

    // Disallow zoom levels that are too high
    if fZoomLevel > Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS then
      fZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);
  end;

begin
  SL := TStringList.Create;

  if FileExists(AppPath + SFSaveData + 'settings.ini') then
  begin
    SL.LoadFromFile(AppPath + SFSaveData + 'settings.ini');
    LoadedConfig := true;
  end else if FileExists(AppPath + 'NeoLemmix147Settings.ini') then
  begin
    SL.LoadFromFile(AppPath + 'NeoLemmix147Settings.ini');
    LoadedConfig := true;
  end else if UnderWine then
  begin
    // When running under WINE without an existing config, let's default to windowed.
    FullScreen := false;
    ZoomLevel := Max(Max((Screen.Width - 100) div 416, (Screen.Height - 100) div 200), 1);
    WindowWidth := 416 * ZoomLevel;
    WindowHeight := 200 * ZoomLevel;
  end;

  AutoSaveReplay := LoadBoolean('AutoSaveReplay', AutoSaveReplay);
  LemmingBlink := LoadBoolean('LemmingCountBlink', LemmingBlink);
  TimerBlink := LoadBoolean('TimerBlink', TimerBlink);
  NoAutoReplayMode := LoadBoolean('NoAutoReplay', NoAutoReplayMode);
  PauseAfterBackwardsSkip := LoadBoolean('PauseAfterBackwardsSkip', PauseAfterBackwardsSkip);
  BlackOutZero := LoadBoolean('BlackOutZero', BlackOutZero);
  NoBackgrounds := LoadBoolean('NoBackgrounds', NoBackgrounds);
  NoShadows := LoadBoolean('NoShadows', NoShadows);
  CompactSkillPanel := LoadBoolean('CompactSkillPanel', CompactSkillPanel);
  MinimapHighQuality := LoadBoolean('HighQualityMinimap', MinimapHighQuality);
  EdgeScroll := LoadBoolean('EdgeScrolling', EdgeScroll);
  IncreaseZoom := LoadBoolean('IncreaseZoom', IncreaseZoom);
  SpawnInterval := LoadBoolean('UseSpawnInterval', SpawnInterval);

  EnableOnline := LoadBoolean('EnableOnline', EnableOnline);
  CheckUpdates := LoadBoolean('UpdateCheck', CheckUpdates);

  DisableWineWarnings := LoadBoolean('DisableWineWarnings', DisableWineWarnings);

  ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], -1);

  if (StrToIntDef(SL.Values['LastVersion'], 0) div 1000) mod 100 < 16 then
    FullScreen := ZoomLevel < 1;
  FullScreen := LoadBoolean('FullScreen', FullScreen);

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

procedure TDosGameParams.LoadCurrentLevel(NoOutput: Boolean = false);
begin
  if CurrentLevel = nil then Exit;
  Level.LoadFromFile(CurrentLevel.Path);
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
  end else begin
    fCurrentLevel := CurLevelGroup.Levels[CurLevelIndex + 1];
  end;

  ShownText := false;
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

  ShownText := false;
end;

procedure TDosGameParams.SetGroup(aGroup: TNeoLevelGroup);
begin
  if aGroup.Levels.Count = 0 then
    SetLevel(aGroup.FirstUnbeatenLevelRecursive)
  else
    SetLevel(aGroup.FirstUnbeatenLevel);
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
var
  buttonSelected: Integer;
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;
  PostLevelSoundOptions := [plsVictory, plsFailure];

  if not DirectoryExists(AppPath + SFLevels) then
  begin
    buttonSelected := MessageDlg('Could not find any levels in the folder levels\. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  try
    BaseLevelPack := TNeoLevelGroup.Create(nil, AppPath + SFLevels);
    SetLevel(BaseLevelPack.FirstUnbeatenLevelRecursive);
  except
    BaseLevelPack := nil;
    SetLevel(nil);
  end;
  
  SoundManager.MusicVolume := 50;
  SoundManager.SoundVolume := 50;
  fDumpMode := false;
  fShownText := false;
  fOneLevelMode := false;
  fTalismanPage := 0;
  fZoomLevel := Min(Screen.Width div 320, Screen.Height div 200);

  LemDataInResource := True;
  LemSoundsInResource := True;
  LemMusicInResource := True;


  (*
  TempStream := CreateDataStream('talisman.dat', ldtLemmings);
  if TempStream <> nil then
  begin
    fTalismans.LoadFromStream(TempStream);
    TempStream.Free;
  end;
  *)

  fHotkeys := TLemmixHotkeyManager.Create;
end;

destructor TDosGameParams.Destroy;
begin
  fHotkeys.Free;
  BaseLevelPack.Free;
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

function TDosGameParams.GetCurrentGroupName: String;
begin
  Result := CurrentLevel.Group.Name;
end;

end.

