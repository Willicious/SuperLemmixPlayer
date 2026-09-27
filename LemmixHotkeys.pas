unit LemmixHotkeys;

interface

uses
  Dialogs,
  LemTypes,
  LemStrings,
  LemCore,
  Windows, Classes, SysUtils,
  SharedGlobals;

const
  MAX_KEY = 255;
  MAX_KEY_LEN = 4;
  KEYSET_VERSION = 10;

type
  TLemmixHotkeyAction = (lka_Null,
                         lka_Skill,
                         lka_SkillButton,
                         lka_ShowAthleteInfo,
                         lka_Exit,
                         lka_ReleaseRateMax,
                         lka_ReleaseRateUp,
                         lka_ReleaseRateDown,
                         lka_ReleaseRateMin,
                         lka_Pause,
                         lka_Nuke,
                         lka_BypassNuke,
                         lka_CancelPlayback,
                         lka_SaveState,
                         lka_LoadState,
                         lka_Highlight,
                         lka_DirLeft,
                         lka_DirRight,
                         lka_ForceWalker,
                         lka_ForceUnassigned,
                         lka_InfiniteSkills,
                         lka_InfiniteTime,
                         lka_Cheat,
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
                         lka_PhysicsView,
                         lka_ShowUsedSkills,
                         lka_FallDistance,
                         lka_ZoomIn,
                         lka_ZoomOut,
                         lka_CycleZoom,
                         lka_Scroll,
                         lka_NudgeUp,
                         lka_NudgeDown,
                         lka_NudgeLeft,
                         lka_NudgeRight);
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

      procedure SetKeyByName(const aKeyName: String; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
      procedure SetKeyByCode(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
      function CheckKeyEffect(aKey: Word): TLemmixHotkey;
      function CheckForKey(aFunc: TLemmixHotkeyAction): Boolean; overload;
      function CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean; overload;
      function CheckKeyAssigned(aFunc: TLemmixHotkeyAction; aKey: Integer): Boolean;

      class function InterpretMain(s: String): TLemmixHotkeyAction;
      class function InterpretSecondary(s: String): Integer;
      class function GetKeyNames(aUseHardcoded: Boolean): TKeyNameArray;
      class function GetKeyCode(const aKeyName: String): Word;

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
  for i := 0 to MAX_KEY do
    fKeyFunctions[i].Action := lka_Null;
end;

procedure TLemmixHotkeyManager.SetDefaultsClassic;
begin
  ClearAllKeys;

  SetKeyByName('Middle-Click', lka_Pause);
  SetKeyByName('P', lka_Pause);
  SetKeyByName('N', lka_Nuke);
  SetKeyByName('R', lka_Restart);
  SetKeyByName('F', lka_FastForward);
  SetKeyByName('T', lka_Turbo);
  SetKeyByName('B', lka_Rewind);
  SetKeyByName('Esc', lka_Exit);
  SetKeyByName('Wheel Up', lka_ZoomIn);
  SetKeyByName('Wheel Down', lka_ZoomOut);
  SetKeyByName('M', lka_Music);
  SetKeyByName('S', lka_Sound);
  SetKeyByName('A', lka_ShowAthleteInfo);
  SetKeyByName('+', lka_ReleaseRateUp);
  SetKeyByName('-', lka_ReleaseRateDown);
  SetKeyByName('Left Arrow', lka_SkillLeft);
  SetKeyByName('Right Arrow', lka_SkillRight);
  SetKeyByName('Enter', lka_ReleaseMouse);
  SetKeyByName('Space', lka_ShowUsedSkills);
  SetKeyByName('NumPad *', lka_InfiniteSkills);
  SetKeyByName('NumPad /', lka_InfiniteTime);
  SetKeyByName('Y', lka_CancelPlayback);
  SetKeyByName('1', lka_Skill, Integer(spbClimber));
  SetKeyByName('2', lka_Skill, Integer(spbFloater));
  SetKeyByName('3', lka_Skill, Integer(spbTimebomber));
  SetKeyByName('4', lka_Skill, Integer(spbBlocker));
  SetKeyByName('5', lka_Skill, Integer(spbBuilder));
  SetKeyByName('6', lka_Skill, Integer(spbBasher));
  SetKeyByName('7', lka_Skill, Integer(spbMiner));
  SetKeyByName('8', lka_Skill, Integer(spbDigger));
  SetKeyByName('NumPad 8', lka_NudgeUp, 160);
  SetKeyByName('NumPad 2', lka_NudgeDown, 160);
  SetKeyByName('NumPad 4', lka_NudgeLeft, 160);
  SetKeyByName('NumPad 6', lka_NudgeRight, 160);
end;

procedure TLemmixHotkeyManager.SetDefaultsAdvanced;
begin
  ClearAllKeys;

  SetKeyByName('Middle-Click', lka_Pause);
  SetKeyByName('P', lka_Pause);
  SetKeyByName('N', lka_Nuke);
  SetKeyByName('R', lka_Restart);
  SetKeyByName('F', lka_FastForward);
  SetKeyByName('T', lka_Turbo);
  SetKeyByName('D', lka_Rewind);
  SetKeyByName('Esc', lka_Exit);
  SetKeyByName('Wheel Up', lka_ZoomIn);
  SetKeyByName('Wheel Down', lka_ZoomOut);
  SetKeyByName('M', lka_Music);
  SetKeyByName('X', lka_Sound);
  SetKeyByName('A', lka_ShowAthleteInfo);
  SetKeyByName('+', lka_ReleaseRateUp);
  SetKeyByName('-', lka_ReleaseRateDown);
  SetKeyByName('NumPad +', lka_ReleaseRateMax);
  SetKeyByName('NumPad -', lka_ReleaseRateMin);
  SetKeyByName('H', lka_Highlight);
  SetKeyByName('Ctrl (Right)', lka_ForceWalker);
  SetKeyByName('W', lka_ForceWalker);
  SetKeyByName('Left Arrow', lka_DirLeft);
  SetKeyByName('Right Arrow', lka_DirRight);
  SetKeyByName('Down Arrow', lka_SkillLeft);
  SetKeyByName('Up Arrow', lka_SkillRight);
  SetKeyByName('I', lka_FallDistance);
  SetKeyByName('Enter', lka_ReleaseMouse);
  SetKeyByName(';', lka_ShowUsedSkills);
  SetKeyByName('Backspace', lka_Skip, -25);
  SetKeyByName('J', lka_Skip, 20);
  SetKeyByName('NumPad 0', lka_Skip, 100);
  SetKeyByName('Space', lka_Skip, 1000);
  SetKeyByName('Z', lka_SpecialSkip, 0);
  SetKeyByName('Tab', lka_SpecialSkip, 1);
  SetKeyByName('Shift', lka_SpecialSkip, 1);
  SetKeyByName('0', lka_SlowMotion);
  SetKeyByName('.', lka_SlowMotion);
  SetKeyByName('Delete', lka_Cheat);
  SetKeyByName('NumPad *', lka_InfiniteSkills);
  SetKeyByName('NumPad /', lka_InfiniteTime);
  SetKeyByName('V', lka_PhysicsView, 1);
  SetKeyByName('Caps Lock', lka_PhysicsView, 0);
  SetKeyByName('L', lka_LoadReplay);
  SetKeyByName('S', lka_SaveReplay);
  SetKeyByName('C', lka_CancelReplay);
  SetKeyByName('E', lka_EditReplay);
  SetKeyByName('O', lka_ReplayInsert);
  SetKeyByName('F11', lka_SaveState);
  SetKeyByName('F12', lka_LoadState);
  SetKeyByName('Y', lka_CancelPlayback);
  SetKeyByName('F10', lka_SaveImage);
  SetKeyByName('1', lka_SkillButton, 1);
  SetKeyByName('2', lka_SkillButton, 2);
  SetKeyByName('3', lka_SkillButton, 3);
  SetKeyByName('4', lka_SkillButton, 4);
  SetKeyByName('5', lka_SkillButton, 5);
  SetKeyByName('6', lka_SkillButton, 6);
  SetKeyByName('7', lka_SkillButton, 7);
  SetKeyByName('8', lka_SkillButton, 8);
  SetKeyByName('9', lka_SkillButton, 9);
  SetKeyByName('0', lka_SkillButton, 10);
  SetKeyByName('F1', lka_SkillButton, 11);
  SetKeyByName('F2', lka_SkillButton, 12);
  SetKeyByName('F3', lka_SkillButton, 13);
  SetKeyByName('F4', lka_SkillButton, 14);
  SetKeyByName('NumPad 8', lka_NudgeUp, 160);
  SetKeyByName('NumPad 2', lka_NudgeDown, 160);
  SetKeyByName('NumPad 4', lka_NudgeLeft, 160);
  SetKeyByName('NumPad 6', lka_NudgeRight, 160);
end;

procedure TLemmixHotkeyManager.SetDefaultsAlternative;
begin
  ClearAllKeys;

  SetKeyByName('S', lka_DirLeft);
  SetKeyByName('F', lka_DirRight);
  SetKeyByName('Left Arrow', lka_DirLeft);
  SetKeyByName('Right Arrow', lka_DirRight);
  SetKeyByName('Space', lka_Pause);
  SetKeyByName('F1', lka_Restart);
  SetKeyByName('F2', lka_LoadState);
  SetKeyByName('F3', lka_SaveState);
  SetKeyByName('4', lka_FastForward);
  SetKeyByName('5', lka_Turbo);
  SetKeyByName('Middle-Click', lka_Pause);
  SetKeyByName('Wheel Up', lka_ZoomIn);
  SetKeyByName('Wheel Down', lka_ZoomOut);
  SetKeyByName('Esc', lka_Exit);
  SetKeyByName('F6', lka_SaveReplay);
  SetKeyByName('F7', lka_LoadReplay);
  SetKeyByName('Ctrl (Left)', lka_Highlight);
  SetKeyByName('Ctrl (Right)', lka_Highlight);
  SetKeyByName('M', lka_Music);
  SetKeyByName('N', lka_Sound);
  SetKeyByName('F4', lka_ReleaseRateDown);
  SetKeyByName('F5', lka_ReleaseRateUp);
  SetKeyByName('I', lka_FallDistance);
  SetKeyByName('P', lka_EditReplay);
  SetKeyByName('O', lka_ReplayInsert);
  SetKeyByName('Enter', lka_SaveImage);
  SetKeyByName('J', lka_Scroll);
  SetKeyByName('/', lka_PhysicsView, 1);
  SetKeyByName('1', lka_Skip, -17);
  SetKeyByName('2', lka_Skip, -1);
  SetKeyByName('3', lka_Skip, 1);
  SetKeyByName('6', lka_Skip, 170);
  SetKeyByName('7', lka_SpecialSkip, 0);
  SetKeyByName('8', lka_SpecialSkip, 1);
  SetKeyByName('9', lka_SpecialSkip, 2);
  SetKeyByName('Shift', lka_SkillLeft);
  SetKeyByName('B', lka_SkillRight);
  SetKeyByName('D', lka_Skill, Integer(spbWalker));
  SetKeyByName('R', lka_Skill, Integer(spbJumper));
  SetKeyByName('Alt', lka_Skill, Integer(spbShimmier));
  SetKeyByName('H', lka_Skill, Integer(spbSlider));
  SetKeyByName('Z', lka_Skill, Integer(spbClimber));
  SetKeyByName('Q', lka_Skill, Integer(spbFloater));
  SetKeyByName('Tab', lka_Skill, Integer(spbGlider));
  SetKeyByName('V', lka_Skill, Integer(spbBomber));
  SetKeyByName('X', lka_Skill, Integer(spbBlocker));
  SetKeyByName('L', lka_Skill, Integer(spbLadderer));
  SetKeyByName('T', lka_Skill, Integer(spbPlatformer));
  SetKeyByName('A', lka_Skill, Integer(spbBuilder));
  SetKeyByName('Y', lka_Skill, Integer(spbLaserer));
  SetKeyByName('E', lka_Skill, Integer(spbBasher));
  SetKeyByName('C', lka_Skill, Integer(spbFencer));
  SetKeyByName('G', lka_Skill, Integer(spbMiner));
  SetKeyByName('W', lka_Skill, Integer(spbDigger));
  SetKeyByName('NumPad *', lka_InfiniteSkills);
  SetKeyByName('NumPad /', lka_InfiniteTime);
  SetKeyByName('Y', lka_CancelPlayback);
  SetKeyByName('NumPad 8', lka_NudgeUp, 160);
  SetKeyByName('NumPad 2', lka_NudgeDown, 160);
  SetKeyByName('NumPad 4', lka_NudgeLeft, 160);
  SetKeyByName('NumPad 6', lka_NudgeRight, 160);
end;

class function TLemmixHotkeyManager.InterpretMain(s: String): TLemmixHotkeyAction;
begin
  s := LowerCase(s);
  Result := lka_Null;
  if s = 'skill' then Result := lka_Skill;
  if s = 'skill_button' then Result := lka_SkillButton;
  if s = 'athlete_info' then Result := lka_ShowAthleteInfo;
  if s = 'quit' then Result := lka_Exit;
  if s = 'rr_max' then Result := lka_ReleaseRateMax;
  if s = 'rr_up' then Result := lka_ReleaseRateUp;
  if s = 'rr_down' then Result := lka_ReleaseRateDown;
  if s = 'rr_min' then Result := lka_ReleaseRateMin;
  if s = 'pause' then Result := lka_Pause;
  if s = 'nuke' then Result := lka_Nuke;
  if s = 'bypass_nuke' then Result := lka_BypassNuke;
  if s = 'cancel_playback_mode' then Result := lka_CancelPlayback;
  if s = 'save_state' then Result := lka_SaveState;
  if s = 'load_state' then Result := lka_LoadState;
  if s = 'dir_select_left' then Result := lka_DirLeft;
  if s = 'dir_select_right' then Result := lka_DirRight;
  if s = 'force_walker' then Result := lka_ForceWalker;
  if s = 'force_unassigned' then Result := lka_ForceUnassigned;
  if s = 'cheat' then Result := lka_Cheat;
  if s = 'infinite_skills' then Result := lka_InfiniteSkills;
  if s = 'infinite_time' then Result := lka_InfiniteTime;
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
  if s = 'physics_view' then Result := lka_PhysicsView;
  if s = 'show_used_skills' then Result := lka_ShowUsedSkills;
  if s = 'fall_distance' then Result := lka_FallDistance;
  if s = 'edit_replay' then Result := lka_EditReplay;
  if s = 'replay_insert' then Result := lka_ReplayInsert;
  if s = 'zoom_in' then Result := lka_ZoomIn;
  if s = 'zoom_out' then Result := lka_ZoomOut;
  if s = 'cycle_zoom' then Result := lka_CycleZoom;
  if s = 'scroll' then Result := lka_Scroll;
  if s = 'nudge_up' then Result := lka_NudgeUp;
  if s = 'nudge_down' then Result := lka_NudgeDown;
  if s = 'nudge_left' then Result := lka_NudgeLeft;
  if s = 'nudge_right' then Result := lka_NudgeRight;
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
    //else if s = 'propeller' then Result := Integer(spbPropeller)
    //else if s = 'batter' then Result := Integer(spbBatter)
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
          FoundSplit := False;
          for i2 := 1 to Length(istr) do
          begin
            if istr[i2] = ':' then
            begin
              FoundSplit := True;
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
        fDisableSaving := True;
        SetDefaultsAdvanced;
        raise E;
      end;
    end;
  finally
    StringList.Free;
  end;
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
      lka_SkillButton:      Result := 'Skill_Button';
      lka_ShowAthleteInfo:  Result := 'Athlete_Info';
      lka_Exit:             Result := 'Quit';
      lka_ReleaseRateMax:   Result := 'RR_Max';
      lka_ReleaseRateUp:    Result := 'RR_Up';
      lka_ReleaseRateDown:  Result := 'RR_Down';
      lka_ReleaseRateMin:   Result := 'RR_Min';
      lka_Pause:            Result := 'Pause';
      lka_Nuke:             Result := 'Nuke';
      lka_BypassNuke:       Result := 'Bypass_Nuke';
      lka_CancelPlayback:   Result := 'Cancel_Playback_Mode';
      lka_SaveState:        Result := 'Save_State';
      lka_LoadState:        Result := 'Load_State';
      lka_DirLeft:          Result := 'Dir_Select_Left';
      lka_DirRight:         Result := 'Dir_Select_Right';
      lka_ForceWalker:      Result := 'Force_Walker';
      lka_ForceUnassigned:  Result := 'Force_Unassigned';
      lka_Cheat:            Result := 'Cheat';
      lka_InfiniteSkills:   Result := 'Infinite_Skills';
      lka_InfiniteTime:     Result := 'Infinite_Time';
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
      lka_PhysicsView:     Result := 'Physics_View';
      lka_ShowUsedSkills:   Result := 'Show_Used_Skills';
      lka_FallDistance:     Result := 'Fall_Distance';
      lka_EditReplay:       Result := 'Edit_Replay';
      lka_ReplayInsert:     Result := 'Replay_Insert';
      lka_ZoomIn:           Result := 'Zoom_In';
      lka_ZoomOut:          Result := 'Zoom_Out';
      lka_CycleZoom:        Result := 'Cycle_Zoom';
      lka_Scroll:           Result := 'Scroll';
      lka_NudgeUp:          Result := 'Nudge_Up';
      lka_NudgeDown:        Result := 'Nudge_Down';
      lka_NudgeLeft:        Result := 'Nudge_Left';
      lka_NudgeRight:       Result := 'Nudge_Right';
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
                    //Integer(spbPropeller):    Result := 'Propeller';
                    //Integer(spbBatter):       Result := 'Batter';
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
    if s = 'Null' then Continue;

    // Hotkey actions with secondary properties (modifiers)
    if fKeyFunctions[i].Action in [lka_Skill,
                                   lka_SkillButton,
                                   lka_Skip,
                                   lka_SpecialSkip,
                                   lka_PhysicsView,
                                   lka_ShowUsedSkills] then
      s := s + ':' + InterpretSecondary(fKeyFunctions[i].Modifier, fKeyFunctions[i].Action);

    // And, ensure these modifiers always have positive integers
    if fKeyFunctions[i].Action in [lka_NudgeUp,
                                   lka_NudgeDown,
                                   lka_NudgeLeft,
                                   lka_NudgeRight] then
      s := s + ':' + InterpretSecondary(Abs(fKeyFunctions[i].Modifier), fKeyFunctions[i].Action);

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
  Result := DoCheckForKey(aFunc, 0, False);
end;

function TLemmixHotkeyManager.CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean;
begin
  Result := DoCheckForKey(aFunc, aMod, True);
end;

function TLemmixHotkeyManager.DoCheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer; CheckMod: Boolean): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to MAX_KEY do
  begin
    if fKeyFunctions[i].Action <> aFunc then Continue;
    if CheckMod and (aMod <> fKeyFunctions[i].Modifier) then Continue;
    if (GetKeyState(i) < 0) then
    begin
      Result := True;
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
    // Shortcut time!
    for i := 0 to 9 do // Numbers
      Result[$30 + i] := IntToStr(i);
    for i := 0 to 8 do // ABCDEFGHI
      Result[$41 + i] := Char(i + 65);
    Result[$4A] := 'J';
    Result[$4B] := 'K';
    Result[$4C] := 'L';
    Result[$4D] := 'M';
    Result[$4E] := 'N';
    Result[$4F] := 'O';
    for i := 15 to 26 do // PQRSTUVWXYZ
      Result[$41 + i] := Char(i + 65);
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

class function TLemmixHotkeyManager.GetKeyCode(const aKeyName: String): Word;
var
  KeyNames: TKeyNameArray;
  i: Integer;
begin
  KeyNames := GetKeyNames(True);

  for i := 0 to MAX_KEY do
    if SameText(KeyNames[i], aKeyName) then
    begin
      Result := i;
      Exit;
    end;

  raise Exception.CreateFmt('Unknown key name: "%s"', [aKeyName]);
end;

procedure TLemmixHotkeyManager.SetKeyByName(const aKeyName: String; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
var
  KeyCode: Word;
begin
  KeyCode := GetKeyCode(aKeyName);
  fKeyFunctions[KeyCode].Action := aFunc;
  fKeyFunctions[KeyCode].Modifier := aMod;
end;

procedure TLemmixHotkeyManager.SetKeyByCode(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
begin
  fKeyFunctions[aKey].Action := aFunc;
  fKeyFunctions[aKey].Modifier := aMod;
end;

end.