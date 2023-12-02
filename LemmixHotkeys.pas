unit LemmixHotkeys;

interface

uses
  Dialogs,
  LemTypes,
  LemStrings,
  LemCore,
  Windows, Classes, SysUtils;

const
  MAX_KEY = 255;
  MAX_KEY_LEN = 4;
  KEYSET_VERSION = 10;

type
  TLemmixHotkeyAction = (lka_Null,
                         lka_Skill,
                         lka_ShowAthleteInfo,
                         lka_Exit,
                         lka_ReleaseRateMax,
                         lka_ReleaseRateUp,
                         lka_ReleaseRateDown,
                         lka_ReleaseRateMin,
                         lka_Pause,
                         lka_Nuke,
                         lka_BypassNuke,
                         lka_SaveState,
                         lka_LoadState,
                         lka_Highlight,
                         lka_DirLeft,
                         lka_DirRight,
                         lka_ForceWalker,
                         lka_Cheat,
                         //lka_InfiniteSkills,
                         lka_Skip,
                         lka_SpecialSkip,
                         lka_FastForward,
                         lka_Turbo,
                         lka_Rewind,
                         lka_SlowMotion,
                         lka_SaveImage,
                         lka_LoadReplay,
                         lka_SaveReplay,
                         lka_CancelReplay,
                         lka_EditReplay,
                         lka_ReplayInsert,
                         lka_Music,
                         lka_Sound,
                         lka_Restart,
                         lka_SkillLeft,
                         lka_SkillRight,
                         lka_ReleaseMouse,
                         lka_ClearPhysics,
                         //lka_ToggleShadows, // Bookmark - remove?
                         //lka_Projection,
                         //lka_SkillProjection,
                         lka_ShowUsedSkills,
                         lka_FallDistance,
                         lka_ZoomIn,
                         lka_ZoomOut,
                         lka_Scroll);
  PLemmixHotkeyAction = ^TLemmixHotkeyAction;

  TSpecialSkipCondition = (ssc_LastAction,
                           ssc_NextShrugger,
                           ssc_HighlitStateChange);

  TKeyNameArray = Array [0..MAX_KEY] of String;

  TLemmixHotkey = record
    Action: TLemmixHotkeyAction;
    Modifier: Integer;
  end;

  TLemmixHotkeyManager = class
    private
      fKeyFunctions: Array[0..MAX_KEY] of TLemmixHotkey;
      fDisableSaving: Boolean;

      function DoCheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer; CheckMod: Boolean): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      procedure ClearAllKeys;
      procedure LoadFile;
      procedure SaveFile;

      procedure SetDefaultsClassic;
      procedure SetDefaultsAdvanced;
      procedure SetDefaultsAlternative;

      procedure SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
      function CheckKeyEffect(aKey: Word): TLemmixHotkey;
      function CheckForKey(aFunc: TLemmixHotkeyAction): Boolean; overload;
      function CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean; overload;
      function CheckKeyAssigned(aFunc: TLemmixHotkeyAction; aKey: Integer): Boolean;

      class function InterpretMain(s: String): TLemmixHotkeyAction;
      class function InterpretSecondary(s: String): Integer;
      class function GetKeyNames(aUseHardcoded: Boolean): TKeyNameArray;

  end;

implementation

constructor TLemmixHotkeyManager.Create;
begin
  inherited;
  LoadFile;
end;

destructor TLemmixHotkeyManager.Destroy;
begin
  inherited;
end;

procedure TLemmixHotkeyManager.ClearAllKeys;
var
  i: Integer;
begin
  for i := 0 to MAX_KEY-1 do
    fKeyFunctions[i].Action := lka_Null;
end;

procedure TLemmixHotkeyManager.SetDefaultsClassic;
begin
  ClearAllKeys;

  SetKeyFunction($04, lka_Pause);
  SetKeyFunction($50, lka_Pause);
  SetKeyFunction($4E, lka_Nuke);
  SetKeyFunction($52, lka_Restart);
  SetKeyFunction($46, lka_FastForward);
  SetKeyFunction($54, lka_Turbo);
  SetKeyFunction($42, lka_Rewind);
  SetKeyFunction($1B, lka_Exit);
  SetKeyFunction($05, lka_ZoomIn);
  SetKeyFunction($06, lka_ZoomOut);
  SetKeyFunction($4D, lka_Music);
  SetKeyFunction($53, lka_Sound);
  SetKeyFunction($41, lka_ShowAthleteInfo);
  SetKeyFunction($BB, lka_ReleaseRateUp);
  SetKeyFunction($BD, lka_ReleaseRateDown);
  SetKeyFunction($25, lka_SkillLeft);
  SetKeyFunction($27, lka_SkillRight);
  SetKeyFunction($0D, lka_ReleaseMouse);
  SetKeyFunction($20, lka_ShowUsedSkills);
  SetKeyFunction($31, lka_Skill, Integer(spbClimber));
  SetKeyFunction($32, lka_Skill, Integer(spbFloater));
  SetKeyFunction($33, lka_Skill, Integer(spbTimebomber));
  SetKeyFunction($34, lka_Skill, Integer(spbBlocker));
  SetKeyFunction($35, lka_Skill, Integer(spbBuilder));
  SetKeyFunction($36, lka_Skill, Integer(spbBasher));
  SetKeyFunction($37, lka_Skill, Integer(spbMiner));
  SetKeyFunction($38, lka_Skill, Integer(spbDigger));
end;

procedure TLemmixHotkeyManager.SetDefaultsAdvanced;
begin
  ClearAllKeys;

  SetKeyFunction($04, lka_Pause);
  SetKeyFunction($50, lka_Pause);
  SetKeyFunction($4E, lka_Nuke);
  SetKeyFunction($52, lka_Restart);
  SetKeyFunction($46, lka_FastForward);
  SetKeyFunction($54, lka_Turbo);
  SetKeyFunction($44, lka_Rewind);
  SetKeyFunction($1B, lka_Exit);
  SetKeyFunction($05, lka_ZoomIn);
  SetKeyFunction($06, lka_ZoomOut);
  SetKeyFunction($4D, lka_Music);
  SetKeyFunction($58, lka_Sound);
  SetKeyFunction($41, lka_ShowAthleteInfo);
  SetKeyFunction($BB, lka_ReleaseRateUp);
  SetKeyFunction($BD, lka_ReleaseRateDown);
  SetKeyFunction($6B, lka_ReleaseRateMax);
  SetKeyFunction($6D, lka_ReleaseRateMin);
  SetKeyFunction($55, lka_Highlight);
  SetKeyFunction($19, lka_ForceWalker);
  SetKeyFunction($57, lka_ForceWalker);
  SetKeyFunction($25, lka_DirLeft);
  SetKeyFunction($27, lka_DirRight);
  SetKeyFunction($28, lka_SkillLeft);
  SetKeyFunction($26, lka_SkillRight);
  SetKeyFunction($49, lka_FallDistance);
  SetKeyFunction($0D, lka_ReleaseMouse);
  SetKeyFunction($BA, lka_ShowUsedSkills);
  SetKeyFunction($08, lka_Skip, -25);
  SetKeyFunction($4A, lka_Skip, 20);
  SetKeyFunction($60, lka_Skip, 100);
  SetKeyFunction($20, lka_Skip, 1000);
  SetKeyFunction($5A, lka_SpecialSkip, 0);
  SetKeyFunction($09, lka_SpecialSkip, 1);
  SetKeyFunction($10, lka_SpecialSkip, 1);
  SetKeyFunction($30, lka_SlowMotion);
  SetKeyFunction($BE, lka_SlowMotion);
  SetKeyFunction($2E, lka_Cheat);
  //SetKeyFunction($2D, lka_InfiniteSkills);
  SetKeyFunction($56, lka_ClearPhysics, 1);
  SetKeyFunction($14, lka_ClearPhysics, 0);
  SetKeyFunction($4C, lka_LoadReplay);
  SetKeyFunction($53, lka_SaveReplay);
  SetKeyFunction($43, lka_CancelReplay);
  SetKeyFunction($45, lka_EditReplay);
  SetKeyFunction($4F, lka_ReplayInsert);
  SetKeyFunction($47, lka_SaveState);
  SetKeyFunction($48, lka_LoadState);
  SetKeyFunction($79, lka_SaveImage);
  SetKeyFunction($31, lka_Skill, Integer(spbClimber));
  SetKeyFunction($32, lka_Skill, Integer(spbFloater));
  SetKeyFunction($33, lka_Skill, Integer(spbTimebomber));
  SetKeyFunction($34, lka_Skill, Integer(spbBlocker));
  SetKeyFunction($35, lka_Skill, Integer(spbBuilder));
  SetKeyFunction($36, lka_Skill, Integer(spbBasher));
  SetKeyFunction($37, lka_Skill, Integer(spbMiner));
  SetKeyFunction($38, lka_Skill, Integer(spbDigger));
  SetKeyFunction($70, lka_Skill, Integer(spbClimber));
  SetKeyFunction($71, lka_Skill, Integer(spbFloater));
  SetKeyFunction($72, lka_Skill, Integer(spbTimebomber));
  SetKeyFunction($73, lka_Skill, Integer(spbBlocker));
  SetKeyFunction($74, lka_Skill, Integer(spbBuilder));
  SetKeyFunction($75, lka_Skill, Integer(spbBasher));
  SetKeyFunction($76, lka_Skill, Integer(spbMiner));
  SetKeyFunction($77, lka_Skill, Integer(spbDigger));
end;

procedure TLemmixHotkeyManager.SetDefaultsAlternative;
begin
  ClearAllKeys;
  SetKeyFunction($53, lka_DirLeft);
  SetKeyFunction($46, lka_DirRight);
  SetKeyFunction($25, lka_DirLeft);
  SetKeyFunction($27, lka_DirRight);
  SetKeyFunction($20, lka_Pause);
  SetKeyFunction($70, lka_Restart);
  SetKeyFunction($71, lka_LoadState);
  SetKeyFunction($72, lka_SaveState);
  SetKeyFunction($34, lka_FastForward);
  SetKeyFunction($35, lka_Turbo);
  SetKeyFunction($04, lka_Pause);
  SetKeyFunction($05, lka_ZoomIn);
  SetKeyFunction($06, lka_ZoomOut);
  SetKeyFunction($1B, lka_Exit);
  SetKeyFunction($75, lka_SaveReplay);
  SetKeyFunction($76, lka_LoadReplay);
  SetKeyFunction($11, lka_Highlight);
  SetKeyFunction($19, lka_Highlight);
  SetKeyFunction($4D, lka_Music);
  SetKeyFunction($4E, lka_Sound);
  SetKeyFunction($73, lka_ReleaseRateDown);
  SetKeyFunction($74, lka_ReleaseRateUp);
  SetKeyFunction($49, lka_FallDistance);
  SetKeyFunction($50, lka_EditReplay);
  SetKeyFunction($4F, lka_ReplayInsert);
  SetKeyFunction($0D, lka_SaveImage);
  SetKeyFunction($4A, lka_Scroll);
  SetKeyFunction($BF, lka_ClearPhysics, 1);
  SetKeyFunction($31, lka_Skip, -17);
  SetKeyFunction($32, lka_Skip, -1);
  SetKeyFunction($33, lka_Skip, 1);
  SetKeyFunction($36, lka_Skip, 170);
  SetKeyFunction($37, lka_SpecialSkip, 0);
  SetKeyFunction($38, lka_SpecialSkip, 1);
  SetKeyFunction($39, lka_SpecialSkip, 2);
  SetKeyFunction($10, lka_SkillLeft);
  SetKeyFunction($42, lka_SkillRight);
  SetKeyFunction($44, lka_Skill, Integer(spbWalker));
  SetKeyFunction($52, lka_Skill, Integer(spbJumper));
  SetKeyFunction($12, lka_Skill, Integer(spbShimmier));
  SetKeyFunction($48, lka_Skill, Integer(spbSlider));
  SetKeyFunction($5A, lka_Skill, Integer(spbClimber));
  SetKeyFunction($51, lka_Skill, Integer(spbFloater));
  SetKeyFunction($09, lka_Skill, Integer(spbGlider));
  SetKeyFunction($56, lka_Skill, Integer(spbBomber));
  SetKeyFunction($58, lka_Skill, Integer(spbBlocker));
  SetKeyFunction($54, lka_Skill, Integer(spbLadderer));
  SetKeyFunction($54, lka_Skill, Integer(spbPlatformer));
  SetKeyFunction($41, lka_Skill, Integer(spbBuilder));
  SetKeyFunction($59, lka_Skill, Integer(spbLaserer));
  SetKeyFunction($45, lka_Skill, Integer(spbBasher));
  SetKeyFunction($43, lka_Skill, Integer(spbFencer));
  SetKeyFunction($47, lka_Skill, Integer(spbMiner));
  SetKeyFunction($57, lka_Skill, Integer(spbDigger));
end;

class function TLemmixHotkeyManager.InterpretMain(s: String): TLemmixHotkeyAction;
begin
  s := LowerCase(s);
  Result := lka_Null;
  if s = 'skill' then Result := lka_Skill;
  if s = 'athlete_info' then Result := lka_ShowAthleteInfo;
  if s = 'quit' then Result := lka_Exit;
  if s = 'rr_max' then Result := lka_ReleaseRateMax;
  if s = 'rr_up' then Result := lka_ReleaseRateUp;
  if s = 'rr_down' then Result := lka_ReleaseRateDown;
  if s = 'rr_min' then Result := lka_ReleaseRateMin;
  if s = 'pause' then Result := lka_Pause;
  if s = 'nuke' then Result := lka_Nuke;
  if s = 'bypass_nuke' then Result := lka_BypassNuke;
  if s = 'save_state' then Result := lka_SaveState;
  if s = 'load_state' then Result := lka_LoadState;
  if s = 'dir_select_left' then Result := lka_DirLeft;
  if s = 'dir_select_right' then Result := lka_DirRight;
  if s = 'force_walker' then Result := lka_ForceWalker;
  if s = 'cheat' then Result := lka_Cheat;
  //if s = 'infinite_skills' then Result := lka_InfiniteSkills;
  if s = 'skip' then Result := lka_Skip;
  if s = 'special_skip' then Result := lka_SpecialSkip;
  if s = 'fastforward' then Result := lka_FastForward;
  if s = 'turboforward' then Result := lka_Turbo;
  if s = 'rewind' then Result := lka_Rewind;
  if s = 'slow_motion' then Result := lka_SlowMotion;
  if s = 'save_image' then Result := lka_SaveImage;
  if s = 'load_replay' then Result := lka_LoadReplay;
  if s = 'save_replay' then Result := lka_SaveReplay;
  if s = 'cancel_replay' then Result := lka_CancelReplay;
  if s = 'toggle_music' then Result := lka_Music;
  if s = 'toggle_sound' then Result := lka_Sound;
  if s = 'restart' then Result := lka_Restart;
  if s = 'previous_skill' then Result := lka_SkillLeft;
  if s = 'next_skill' then Result := lka_SkillRight;
  if s = 'release_mouse' then Result := lka_ReleaseMouse;
  if s = 'highlight' then Result := lka_Highlight;
  if s = 'clear_physics' then Result := lka_ClearPhysics;
  //if s = 'toggle_shadows' then Result := lka_ToggleShadows; // Bookmark - remove?
  //if s = 'projection' then Result := lka_Projection;
  //if s = 'skill_projection' then Result := lka_SkillProjection;
  if s = 'show_used_skills' then Result := lka_ShowUsedSkills;
  if s = 'fall_distance' then Result := lka_FallDistance;
  if s = 'edit_replay' then Result := lka_EditReplay;
  if s = 'replay_insert' then Result := lka_ReplayInsert;
  if s = 'zoom_in' then Result := lka_ZoomIn;
  if s = 'zoom_out' then Result := lka_ZoomOut;
  if s = 'scroll' then Result := lka_Scroll;
end;

class function TLemmixHotkeyManager.InterpretSecondary(s: String): Integer;
  begin
    s := LowerCase(s);

    if s = 'walker' then Result := Integer(spbWalker)
    else if s = 'jumper' then Result := Integer(spbJumper)
    else if s = 'shimmier' then Result := Integer(spbShimmier)
    else if s = 'ballooner' then Result := Integer(spbBallooner)
    else if s = 'slider' then Result := Integer(spbSlider)
    else if s = 'climber' then Result := Integer(spbClimber)
    else if s = 'swimmer' then Result := Integer(spbSwimmer)
    else if s = 'floater' then Result := Integer(spbFloater)
    else if s = 'glider' then Result := Integer(spbGlider)
    else if s = 'disarmer' then Result := Integer(spbDisarmer)
    else if s = 'timebomber' then Result := Integer(spbTimebomber)
    else if s = 'bomber' then Result := Integer(spbBomber)
    else if s = 'freezer' then Result := Integer(spbFreezer)
    else if s = 'blocker' then Result := Integer(spbBlocker)
    else if s = 'ladderer' then Result := Integer(spbLadderer)
    else if s = 'platformer' then Result := Integer(spbPlatformer)
    else if s = 'builder' then Result := Integer(spbBuilder)
    else if s = 'stacker' then Result := Integer(spbStacker)
    else if s = 'spearer' then Result := Integer(spbSpearer)
    else if s = 'grenader' then Result := Integer(spbGrenader)
    else if s = 'laserer' then Result := Integer(spbLaserer)
    else if s = 'basher' then Result := Integer(spbBasher)
    else if s = 'fencer' then Result := Integer(spbFencer)
    else if s = 'miner' then Result := Integer(spbMiner)
    else if s = 'digger' then Result := Integer(spbDigger)
    else if s = 'cloner' then Result := Integer(spbCloner)
    else if s = 'lastskill' then Result := 0
    else if s = 'nextshrug' then Result := 1
    else if s = 'highlitstate' then Result := 2
    else if s = '' then Result := 0
    else
    begin
      try
        // A lot of secondaries will be actually numeric
        Result := StrToInt(s);
      except
        Result := 0;
      end;
    end;
  end;

procedure TLemmixHotkeyManager.LoadFile;
var
  StringList: TStringList;
  i, i2: Integer;
  istr: String;
  s0, s1: String;
  FoundSplit: Boolean;
begin
  StringList := TStringList.Create;
  try
    if FileExists(AppPath + SFSaveData + 'hotkeys.ini') then
      StringList.LoadFromFile(AppPath + SFSaveData + 'hotkeys.ini')
    else if FileExists(AppPath + 'SuperLemmixHotkeys.ini') then
      StringList.LoadFromFile(AppPath + 'SuperLemmixHotkeys.ini')
    else begin
      SetDefaultsAdvanced;
      Exit;
    end;
    for i := 0 to MAX_KEY do
    begin
      istr := StringList.Values[IntToHex(i, MAX_KEY_LEN)];
      if istr = '' then
      begin
        fKeyFunctions[i].Action := lka_Null;
        fKeyFunctions[i].Modifier := 0;
      end else begin
        s0 := '';
        s1 := '';
        FoundSplit := false;
        for i2 := 1 to Length(istr) do
        begin
          if istr[i2] = ':' then
          begin
            FoundSplit := true;
            Continue;
          end;
          if FoundSplit then
            s1 := s1 + istr[i2]
          else
            s0 := s0 + istr[i2];
        end;
        fKeyFunctions[i].Action := InterpretMain(s0);
        fKeyFunctions[i].Modifier := InterpretSecondary(s1);
      end;
    end;
  except
    on E: Exception do
    begin
      fDisableSaving := true;
      SetDefaultsAdvanced;
      raise E;
    end;
  end;
  StringList.Free;
end;

procedure TLemmixHotkeyManager.SaveFile;
var
  StringList: TStringList;
  i: Integer;
  s: String;

  function InterpretMain(aValue: TLemmixHotkeyAction): String;
  begin
    case aValue of
      lka_Skill:            Result := 'Skill';
      lka_ShowAthleteInfo:  Result := 'Athlete_Info';
      lka_Exit:             Result := 'Quit';
      lka_ReleaseRateMax:   Result := 'RR_Max';
      lka_ReleaseRateUp:    Result := 'RR_Up';
      lka_ReleaseRateDown:  Result := 'RR_Down';
      lka_ReleaseRateMin:   Result := 'RR_Min';
      lka_Pause:            Result := 'Pause';
      lka_Nuke:             Result := 'Nuke';
      lka_BypassNuke:       Result := 'Bypass_Nuke';
      lka_SaveState:        Result := 'Save_State';
      lka_LoadState:        Result := 'Load_State';
      lka_DirLeft:          Result := 'Dir_Select_Left';
      lka_DirRight:         Result := 'Dir_Select_Right';
      lka_ForceWalker:      Result := 'Force_Walker';
      lka_Cheat:            Result := 'Cheat';
      //lka_InfiniteSkills:   Result := 'Infinite_Skills';
      lka_Skip:             Result := 'Skip';
      lka_SpecialSkip:      Result := 'Special_Skip';
      lka_FastForward:      Result := 'FastForward';
      lka_Turbo:            Result := 'TurboForward';
      lka_Rewind:           Result := 'Rewind';
      lka_SlowMotion:       Result := 'Slow_Motion';
      lka_SaveImage:        Result := 'Save_Image';
      lka_LoadReplay:       Result := 'Load_Replay';
      lka_SaveReplay:       Result := 'Save_Replay';
      lka_CancelReplay:     Result := 'Cancel_Replay';
      lka_Music:            Result := 'Toggle_Music';
      lka_Sound:            Result := 'Toggle_Sound';
      lka_Restart:          Result := 'Restart';
      lka_SkillLeft:        Result := 'Previous_Skill';
      lka_SkillRight:       Result := 'Next_Skill';
      lka_ReleaseMouse:     Result := 'Release_Mouse';
      lka_Highlight:        Result := 'Highlight';
      lka_ClearPhysics:     Result := 'Clear_Physics';
      //lka_ToggleShadows:    Result := 'Toggle_Shadows'; // Bookmark - remove?
      //lka_Projection:       Result := 'Projection';
      //lka_SkillProjection:  Result := 'Skill_Projection';
      lka_ShowUsedSkills:   Result := 'Show_Used_Skills';
      lka_FallDistance:     Result := 'Fall_Distance';
      lka_EditReplay:       Result := 'Edit_Replay';
      lka_ReplayInsert:     Result := 'Replay_Insert';
      lka_ZoomIn:           Result := 'Zoom_In';
      lka_ZoomOut:          Result := 'Zoom_Out';
      lka_Scroll:           Result := 'Scroll';
      else Result := 'Null';
    end;
  end;

  function InterpretSecondary(aValue: Integer; aMain: TLemmixHotkeyAction): String;
  begin
    case aMain of
      lka_Skill:  case aValue of
                    Integer(spbWalker):       Result := 'Walker';
                    Integer(spbJumper):       Result := 'Jumper';
                    Integer(spbShimmier):     Result := 'Shimmier';
                    Integer(spbBallooner):    Result := 'Ballooner';
                    Integer(spbSlider):       Result := 'Slider';
                    Integer(spbClimber):      Result := 'Climber';
                    Integer(spbSwimmer):      Result := 'Swimmer';
                    Integer(spbFloater):      Result := 'Floater';
                    Integer(spbGlider):       Result := 'Glider';
                    Integer(spbDisarmer):     Result := 'Disarmer';
                    Integer(spbTimebomber):   Result := 'Timebomber';
                    Integer(spbBomber):       Result := 'Bomber';
                    Integer(spbFreezer):      Result := 'Freezer';
                    Integer(spbBlocker):      Result := 'Blocker';
                    Integer(spbLadderer):     Result := 'Ladderer';
                    Integer(spbPlatformer):   Result := 'Platformer';
                    Integer(spbBuilder):      Result := 'Builder';
                    Integer(spbStacker):      Result := 'Stacker';
                    Integer(spbSpearer):      Result := 'Spearer';
                    Integer(spbGrenader):     Result := 'Grenader';
                    Integer(spbLaserer):      Result := 'Laserer';
                    Integer(spbBasher):       Result := 'Basher';
                    Integer(spbFencer):       Result := 'Fencer';
                    Integer(spbMiner):        Result := 'Miner';
                    Integer(spbDigger):       Result := 'Digger';
                    Integer(spbCloner):       Result := 'Cloner';
                  end;
      lka_SpecialSkip:  case aValue of
                          0: Result := 'LastSkill';
                          1: Result := 'NextShrug';
                          2: Result := 'HighlitState';
                        end;
      else Result := IntToStr(aValue);
    end;
  end;
begin
  if fDisableSaving then Exit;
  
  StringList := TStringList.Create;
  StringList.Add('Version=' + IntToStr(KEYSET_VERSION));
  for i := 0 to MAX_KEY do
  begin
    s := InterpretMain(fKeyFunctions[i].Action);
    if s = 'Null' then Continue;                                                           // Bookmark - remove?
    if fKeyFunctions[i].Action in [lka_Skill, lka_Skip, lka_SpecialSkip, lka_ClearPhysics, //lka_Projection, lka_SkillProjection,
    lka_ShowUsedSkills] then
      s := s + ':' + InterpretSecondary(fKeyFunctions[i].Modifier, fKeyFunctions[i].Action);
    StringList.Add(IntToHex(i, MAX_KEY_LEN) + '=' + s);
  end;
  try
    ForceDirectories(AppPath + SFSaveData);
    StringList.SaveToFile(AppPath + SFSaveData + 'hotkeys.ini')
  finally
    StringList.Free;
  end;
end;

function TLemmixHotkeyManager.CheckKeyAssigned(aFunc: TLemmixHotkeyAction; aKey: Integer): Boolean;
begin
  Result := (fKeyFunctions[aKey].Action = lka_Null);
end;


function TLemmixHotkeyManager.CheckKeyEffect(aKey: Word): TLemmixHotkey;
begin
  if aKey > MAX_KEY then
  begin
    Result.Action := lka_Null;
    Result.Modifier := 0;
  end else
    Result := fKeyFunctions[aKey];
end;

function TLemmixHotkeyManager.CheckForKey(aFunc: TLemmixHotkeyAction): Boolean;
begin
  Result := DoCheckForKey(aFunc, 0, false);
end;

function TLemmixHotkeyManager.CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean;
begin
  Result := DoCheckForKey(aFunc, aMod, true);
end;

function TLemmixHotkeyManager.DoCheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer; CheckMod: Boolean): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to MAX_KEY do
  begin
    if fKeyFunctions[i].Action <> aFunc then Continue;
    if CheckMod and (aMod <> fKeyFunctions[i].Modifier) then Continue;
    if (GetKeyState(i) < 0) then
    begin
      Result := true;
      Exit;
    end;
  end;
end;

class function TLemmixHotkeyManager.GetKeyNames(aUseHardcoded: Boolean): TKeyNameArray;
var
  i: Integer;
  P: PChar;
  ScanCode: UInt;
begin
  for i := 0 to MAX_KEY do
    Result[i] := '';

  // This list shows which characters correspond to which keys
  // Whoever wrote it got it slightly wrong though!!!
  if aUseHardcoded then
  begin
    Result[$02] := 'Right-Click';
    Result[$04] := 'Middle-Click';
    Result[$05] := 'Wheel Up';
    Result[$06] := 'Wheel Down';
    Result[$08] := 'Backspace';
    Result[$09] := 'Tab';
    Result[$0D] := 'Enter';
    Result[$10] := 'Shift';
    Result[$11] := 'Ctrl (Left)';
    Result[$12] := 'Alt';
    Result[$13] := 'Pause';
    Result[$14] := 'Caps Lock';
    Result[$19] := 'Ctrl (Right)';
    Result[$1B] := 'Esc';
    Result[$20] := 'Space';
    Result[$21] := 'Page Up';
    Result[$22] := 'Page Down';
    Result[$23] := 'End';
    Result[$24] := 'Home';
    Result[$25] := 'Left Arrow';
    Result[$26] := 'Up Arrow';
    Result[$27] := 'Right Arrow';
    Result[$28] := 'Down Arrow';
    Result[$2D] := 'Insert';
    Result[$2E] := 'Delete';
    // Shortcut time!   // Yeah, you should have written it all out properly tbh!!!
    for i := 0 to 9 do
      Result[$30 + i] := IntToStr(i);
    for i := 0 to 25 do                  // Bookmark - put all this in properly at some point
      Result[$41 + i] := Char(i + 65);   // No, this doesn't work: J - O are 4A - 4F
    Result[$5B] := 'Windows';
    for i := 0 to 9 do
      Result[$60 + i] := 'NumPad ' + IntToStr(i);
    Result[$6A] := 'NumPad *';
    Result[$6B] := 'NumPad +';
    Result[$6D] := 'NumPad -';
    Result[$6E] := 'NumPad .';
    Result[$6F] := 'NumPad /';
    for i := 0 to 11 do
      Result[$70 + i] := 'F' + IntToStr(i+1);
    Result[$90] := 'NumLock';
    Result[$91] := 'Scroll Lock';
    Result[$BA] := ';';
    Result[$BB] := '+';
    Result[$BC] := ',';
    Result[$BD] := '-';
    Result[$BE] := '.';
    Result[$BF] := '/';
    Result[$C0] := '~';
    Result[$DB] := '[';
    Result[$DC] := '\';
    Result[$DD] := ']';
    Result[$DE] := '''';
  end;

  P := StrAlloc(20);
  for i := 0 to MAX_KEY do
  begin
    ScanCode := MapVirtualKeyEx(i, 0, GetKeyboardLayout(0)) shl 16;
    if (GetKeyNameText(ScanCode, P, 20) > 0) and (not aUseHardcoded) then
      Result[i] := StrPas(P)
    else if Result[i] = '' then
      Result[i] := IntToHex(i, 4);
  end;
  StrDispose(P);
end;

procedure TLemmixHotkeyManager.SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
begin
  fKeyFunctions[aKey].Action := aFunc;
  fKeyFunctions[aKey].Modifier := aMod;end;

end.