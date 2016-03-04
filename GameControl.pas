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
  LemLevelSystem, LemRendering;

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
    gSecretGoto         : Integer;
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
    moCheatCodes,       // 4
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
    moWhiteOutZero,
    moIgnoreReplaySelection,
    moEnableOnline,
    moCheckUpdates,
    mo30, mo31
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

    function GetCheatCodesEnabled: Boolean;
    procedure SetCheatCodesEnabled(Value: Boolean);
    function GetMusicEnabled: Boolean;
    function GetSoundEnabled: Boolean;
    procedure SetMusicEnabled(Value: Boolean);
    procedure SetSoundEnabled(Value: Boolean);
    function GetLookForLVLFiles: Boolean;
    procedure SetLookForLVLFiles(Value: Boolean);
    function GetDebugSteel: Boolean;
    procedure SetDebugSteel(Value: Boolean);
    function GetChallengeMode: Boolean;
    procedure SetChallengeMode(Value: Boolean);
    function GetTimerMode: Boolean;
    procedure SetTimerMode(Value: Boolean);
    function GetAutoReplayNames: Boolean;
    procedure SetAutoReplayNames(Value: Boolean);
    function GetLemmingBlink: Boolean;
    procedure SetLemmingBlink(Value: Boolean);
    function GetTimerBlink: Boolean;
    procedure SetTimerBlink(Value: Boolean);
    function GetAutoReplaySave: Boolean;
    procedure SetAutoReplaySave(Value: Boolean);
    function GetClickHighlight: Boolean;
    procedure SetClickHighlight(Value: Boolean);
    function GetAlwaysTimestamp: Boolean;
    procedure SetAlwaysTimestamp(Value: Boolean);
    function GetConfirmOverwrite: Boolean;
    procedure SetConfirmOverwrite(Value: Boolean);
    function GetExplicitCancel: Boolean;
    procedure SetExplicitCancel(Value: Boolean);
    function GetWhiteOutZero: Boolean;
    procedure SetWhiteOutZero(Value: Boolean);
    function GetIgnoreReplaySelection: Boolean;
    procedure SetIgnoreReplaySelection(Value: Boolean);
    function GetEnableOnline: Boolean;
    procedure SetEnableOnline(Value: Boolean);
    function GetCheckUpdates: Boolean;
    procedure SetCheckUpdates(Value: Boolean);
  public
    // this is initialized by appcontroller
    MainDatFile  : string;

    Info         : TDosGamePlayInfoRec;
    WhichLevel   : TWhichLevel;

    SoundOptions : TGameSoundOptions;

    Level        : TLevel;
    Style        : TBaseDosLemmingStyle;
    GraphicSet   : TBaseNeoGraphicSet;
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
    fLevelPack           : String;
    fExternalPrefix      : String;
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
    property CheatCodesEnabled: Boolean read GetCheatCodesEnabled write SetCheatCodesEnabled;
    property LookForLVLFiles: Boolean read GetLookForLVLFiles write SetLookForLVLFiles;
    property DebugSteel: Boolean read GetDebugSteel write SetDebugSteel;
    property ChallengeMode: Boolean read GetChallengeMode write SetChallengeMode;
    property TimerMode: Boolean read GetTimerMode write SetTimerMode;
    property ForceSkillset: Word read fForceSkillset write fForceSkillset;
    property Directory: string read fDirectory write fDirectory;
    property DumpMode: boolean read fDumpMode write fDumpMode;
    property QuickTestMode: Integer read fTestScreens write fTestScreens;
    property MusicEnabled: Boolean read GetMusicEnabled write SetMusicEnabled;
    property SoundEnabled: Boolean read GetSoundEnabled write SetSoundEnabled;
    property ClickHighlight: Boolean read GetClickHighlight write SetClickHighlight;
    property AutoReplayNames: Boolean read GetAutoReplayNames write SetAutoReplayNames;
    property AutoSaveReplay: Boolean read GetAutoReplaySave write SetAutoReplaySave;
    property LemmingBlink: Boolean read GetLemmingBlink write SetLemmingBlink;
    property TimerBlink: Boolean read GetTimerBlink write SetTimerBlink;
    property ShownText: boolean read fShownText write fShownText;
    property OneLevelMode: boolean read fOneLevelMode write fOneLevelMode;
    property AlwaysTimestamp: boolean read GetAlwaysTimestamp write SetAlwaysTimestamp;
    property ConfirmOverwrite: boolean read GetConfirmOverwrite write SetConfirmOverwrite;
    property ExplicitCancel: boolean read GetExplicitCancel write SetExplicitCancel;
    property WhiteOutZero: boolean read GetWhiteOutZero write SetWhiteOutZero;
    property IgnoreReplaySelection: boolean read GetIgnoreReplaySelection write SetIgnoreReplaySelection;
    property EnableOnline: boolean read GetEnableOnline write SetEnableOnline;
    property CheckUpdates: boolean read GetCheckUpdates write SetCheckUpdates;

    property DoneUpdateCheck: Boolean read fDoneUpdateCheck write fDoneUpdateCheck;

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
  SaveBoolean('LemmingCountBlink', LemmingBlink);
  SaveBoolean('TimerBlink', TimerBlink);
  SaveBoolean('WhiteOutZero', WhiteOutZero);
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
  WhiteOutZero := LoadBoolean('WhiteOutZero');
  IgnoreReplaySelection := LoadBoolean('IgnoreReplaySelection');
  EnableOnline := LoadBoolean('EnableOnline');
  CheckUpdates := LoadBoolean('UpdateCheck');

  ZoomLevel := StrToIntDef(SL.Values['ZoomLevel'], 0);

  if StrToIntDef(SL.Values['LastVersion'], 0) < 1421 then
    EnableOnline := true;

  SL.Free;
end;


constructor TDosGameParams.Create;
var
  TempStream: TMemoryStream; //for loading talisman data
begin
  inherited Create;

  MiscOptions := DEF_MISCOPTIONS;
  fLevelPack := 'LEVELPAK.DAT';
  fExternalPrefix := '';
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


  try
    TempStream := CreateDataStream('talisman.dat', ldtLemmings);
    fTalismans.LoadFromStream(TempStream);
    TempStream.Free;
  except
    // Silent fail. It's okay - and in fact common - for this file to be missing.
  end;

  fTalismans.SortTalismans;

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

function TDosGameParams.GetCheatCodesEnabled: Boolean;
begin
  Result := moCheatCodes in MiscOptions;
end;

function TDosGameParams.GetMusicEnabled: Boolean;
begin
  Result := gsoMusic in SoundOptions;
end;

function TDosGameParams.GetSoundEnabled: Boolean;
begin
  Result := gsoSound in SoundOptions;
end;

function TDosGameParams.GetLookForLVLFiles: Boolean;
begin
  Result := moLookForLVLFiles in MiscOptions;
end;

function TDosGameParams.GetDebugSteel: Boolean;
begin
  Result := moDebugSteel in MiscOptions;
end;

function TDosGameParams.GetChallengeMode: Boolean;
begin
  Result := moChallengeMode in MiscOptions;
end;

function TDosGameParams.GetTimerMode: Boolean;
begin
  Result := moTimerMode in MiscOptions;
end;

function TDosGameParams.GetAutoReplayNames: Boolean;
begin
  Result := moAutoReplayNames in MiscOptions;
end;

function TDosGameParams.GetAutoReplaySave: Boolean;
begin
  Result := moAutoReplaySave in MiscOptions;
end;

function TDosGameParams.GetLemmingBlink: Boolean;
begin
  Result := moLemmingBlink in MiscOptions;
end;

function TDosGameParams.GetTimerBlink: Boolean;
begin
  Result := moTimerBlink in MiscOptions;
end;

function TDosGameParams.GetClickHighlight: Boolean;
begin
  Result := moClickHighlight in MiscOptions;
end;

function TDosGameParams.GetAlwaysTimestamp: Boolean;
begin
  Result := moAlwaysTimestamp in MiscOptions;
end;

function TDosGameParams.GetConfirmOverwrite: Boolean;
begin
  Result := moConfirmOverwrite in MiscOptions;
end;

function TDosGameParams.GetExplicitCancel: Boolean;
begin
  Result := moExplicitCancel in MiscOptions;
end;

procedure TDosGameParams.SetLemmingBlink(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moLemmingBlink);
    True:  Include(MiscOptions, moLemmingBlink);
  end;
end;

procedure TDosGameParams.SetTimerBlink(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moTimerBlink);
    True:  Include(MiscOptions, moTimerBlink);
  end;
end;

procedure TDosGameParams.SetAutoReplayNames(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moAutoReplayNames);
    True:  Include(MiscOptions, moAutoReplayNames);
  end;
end;

procedure TDosGameParams.SetAutoReplaySave(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moAutoReplaySave);
    True:  Include(MiscOptions, moAutoReplaySave);
  end;
end;

procedure TDosGameParams.SetCheatCodesEnabled(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moCheatCodes);
    True:  Include(MiscOptions, moCheatCodes);
  end;
end;

procedure TDosGameParams.SetMusicEnabled(Value: Boolean);
begin
  case Value of
    False: Exclude(SoundOptions, gsoMusic);
    True:  Include(SoundOptions, gsoMusic);
  end;
end;

procedure TDosGameParams.SetSoundEnabled(Value: Boolean);
begin
  case Value of
    False: Exclude(SoundOptions, gsoSound);
    True:  Include(SoundOptions, gsoSound);
  end;
end;

procedure TDosGameParams.SetLookForLVLFiles(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moLookForLVLFiles);
    True:  Include(MiscOptions, moLookForLVLFiles);
  end;
end;

procedure TDosGameParams.SetDebugSteel(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moDebugSteel);
    True:  Include(MiscOptions, moDebugSteel);
  end;
end;

procedure TDosGameParams.SetTimerMode(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moTimerMode);
    True:  Include(MiscOptions, moTimerMode);
  end;
end;

procedure TDosGameParams.SetChallengeMode(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moChallengeMode);
    True:  Include(MiscOptions, moChallengeMode);
  end;
end;

procedure TDosGameParams.SetClickHighlight(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moClickHighlight);
    True:  Include(MiscOptions, moClickHighlight);
  end;
end;

procedure TDosGameParams.SetAlwaysTimestamp(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moAlwaysTimestamp);
    True:  Include(MiscOptions, moAlwaysTimestamp);
  end;
end;

procedure TDosGameParams.SetConfirmOverwrite(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moConfirmOverwrite);
    True:  Include(MiscOptions, moConfirmOverwrite);
  end;
end;

procedure TDosGameParams.SetExplicitCancel(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moExplicitCancel);
    True:  Include(MiscOptions, moExplicitCancel);
  end;
end;

function TDosGameParams.GetWhiteOutZero: Boolean;
begin
  Result := moWhiteOutZero in MiscOptions;
end;

procedure TDosGameParams.SetWhiteOutZero(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moWhiteOutZero);
    True:  Include(MiscOptions, moWhiteOutZero);
  end;
end;

function TDosGameParams.GetIgnoreReplaySelection: Boolean;
begin
  Result := moIgnoreReplaySelection in MiscOptions;
end;

procedure TDosGameParams.SetIgnoreReplaySelection(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moIgnoreReplaySelection);
    True:  Include(MiscOptions, moIgnoreReplaySelection);
  end;
end;

function TDosGameParams.GetEnableOnline: Boolean;
begin
  Result := moEnableOnline in MiscOptions;
end;

procedure TDosGameParams.SetEnableOnline(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moEnableOnline);
    True:  Include(MiscOptions, moEnableOnline);
  end;
end;

function TDosGameParams.GetCheckUpdates: Boolean;
begin
  Result := moCheckUpdates in MiscOptions;
end;

procedure TDosGameParams.SetCheckUpdates(Value: Boolean);
begin
  case Value of
    False: Exclude(MiscOptions, moCheckUpdates);
    True:  Include(MiscOptions, moCheckUpdates);
  end;
end;

end.

