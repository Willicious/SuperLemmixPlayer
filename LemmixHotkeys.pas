unit LemmixHotkeys;

// A quick and shitty unit to allow for customizable hotkeys.

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
                         lka_ReleaseRateUp,
                         lka_ReleaseRateDown,
                         lka_Pause,
                         lka_Nuke,
                         lka_SaveState,
                         lka_LoadState,
                         lka_Highlight,
                         lka_DirLeft,
                         lka_DirRight,
                         lka_ForceWalker,
                         lka_Cheat,
                         lka_Skip,
                         lka_SpecialSkip,
                         lka_FastForward,
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

      procedure LoadFile;
      function DoCheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer; CheckMod: Boolean): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      procedure ClearAllKeys;
      procedure SaveFile;
      procedure SetDefaults;
      procedure SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
      function CheckKeyEffect(aKey: Word): TLemmixHotkey;
      function CheckForKey(aFunc: TLemmixHotkeyAction): Boolean; overload;
      function CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean; overload;

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

procedure TLemmixHotkeyManager.SetDefaults;
begin
  // Hardcoded defaults. Used when a custom file can't be loaded (or doesn't exist).

  // Here's the simple ones that don't need further settings.
  fKeyFunctions[$02].Action := lka_Highlight;
  fKeyFunctions[$04].Action := lka_Pause;
  fKeyFunctions[$05].Action := lka_ZoomIn;
  fKeyFunctions[$06].Action := lka_ZoomOut;
  fKeyFunctions[$08].Action := lka_LoadState;
  fKeyFunctions[$0D].Action := lka_SaveState;
  fKeyFunctions[$11].Action := lka_ForceWalker;
  fKeyFunctions[$12].Action := lka_ShowAthleteInfo;
  fKeyFunctions[$19].Action := lka_ForceWalker;
  fKeyFunctions[$1B].Action := lka_Exit;
  fKeyFunctions[$25].Action := lka_DirLeft;
  fKeyFunctions[$27].Action := lka_DirRight;
  fKeyFunctions[$41].Action := lka_Scroll;
  fKeyFunctions[$43].Action := lka_CancelReplay;
  fKeyFunctions[$44].Action := lka_FallDistance;
  fKeyFunctions[$45].Action := lka_EditReplay;
  fKeyFunctions[$46].Action := lka_FastForward;
  fKeyFunctions[$49].Action := lka_SaveImage;
  fKeyFunctions[$4C].Action := lka_LoadReplay;
  fKeyFunctions[$4D].Action := lka_Music;
  fKeyFunctions[$50].Action := lka_Pause;
  fKeyFunctions[$52].Action := lka_Restart;
  fKeyFunctions[$53].Action := lka_Sound;
  fKeyFunctions[$55].Action := lka_SaveReplay;
  fKeyFunctions[$57].Action := lka_ReplayInsert;
  fKeyFunctions[$58].Action := lka_SkillRight;
  fKeyFunctions[$5A].Action := lka_SkillLeft;
  fKeyFunctions[$70].Action := lka_ReleaseRateDown;
  fKeyFunctions[$71].Action := lka_ReleaseRateUp;
  fKeyFunctions[$7A].Action := lka_Pause;
  fKeyFunctions[$7B].Action := lka_Nuke;
  fKeyFunctions[$C0].Action := lka_ReleaseMouse;

  // Misc ones that need other details set
  fKeyFunctions[$54].Action := lka_ClearPhysics;
  fKeyFunctions[$54].Modifier := 1;

  // Here's the frameskip ones; these need a number of *frames* to skip (forwards or backwards).
  fKeyFunctions[$20].Action := lka_Skip;
  fKeyFunctions[$20].Modifier := 17 * 10;
  fKeyFunctions[$42].Action := lka_Skip;
  fKeyFunctions[$42].Modifier := -1;
  fKeyFunctions[$4E].Action := lka_Skip;
  fKeyFunctions[$4E].Modifier := 1;
  fKeyFunctions[$54].Action := lka_ClearPhysics;
  fKeyFunctions[$54].Modifier := 1;
  fKeyFunctions[$6D].Action := lka_Skip;
  fKeyFunctions[$6D].Modifier := -17;
  fKeyFunctions[$BC].Action := lka_Skip;
  fKeyFunctions[$BC].Modifier := -17 * 5;
  fKeyFunctions[$BD].Action := lka_Skip;
  fKeyFunctions[$BD].Modifier := -17;
  fKeyFunctions[$BE].Action := lka_Skip;
  fKeyFunctions[$BE].Modifier := 17 * 5;
  fKeyFunctions[$DB].Action := lka_SpecialSkip;
  fKeyFunctions[$DB].Modifier := 0;
  fKeyFunctions[$DD].Action := lka_SpecialSkip;
  fKeyFunctions[$DD].Modifier := 1;
  fKeyFunctions[$DC].Action := lka_SpecialSkip;
  fKeyFunctions[$DC].Modifier := 2;

  // And here's the skill ones; these ones need the skill specified seperately
  fKeyFunctions[$31].Action := lka_Skill;
  fKeyFunctions[$31].Modifier := Integer(spbWalker);
  fKeyFunctions[$32].Action := lka_Skill;
  fKeyFunctions[$32].Modifier := Integer(spbShimmier);
  fKeyFunctions[$33].Action := lka_Skill;
  fKeyFunctions[$33].Modifier := Integer(spbSwimmer);
  fKeyFunctions[$34].Action := lka_Skill;
  fKeyFunctions[$34].Modifier := Integer(spbGlider);
  fKeyFunctions[$35].Action := lka_Skill;
  fKeyFunctions[$35].Modifier := Integer(spbDisarmer);
  fKeyFunctions[$36].Action := lka_Skill;
  fKeyFunctions[$36].Modifier := Integer(spbStoner);
  fKeyFunctions[$37].Action := lka_Skill;
  fKeyFunctions[$37].Modifier := Integer(spbPlatformer);
  fKeyFunctions[$38].Action := lka_Skill;
  fKeyFunctions[$38].Modifier := Integer(spbStacker);
  fKeyFunctions[$39].Action := lka_Skill;
  fKeyFunctions[$39].Modifier := Integer(spbFencer);
  fKeyFunctions[$30].Action := lka_Skill;
  fKeyFunctions[$30].Modifier := Integer(spbCloner);
  fKeyFunctions[$72].Action := lka_Skill;
  fKeyFunctions[$72].Modifier := Integer(spbClimber);
  fKeyFunctions[$73].Action := lka_Skill;
  fKeyFunctions[$73].Modifier := Integer(spbFloater);
  fKeyFunctions[$74].Action := lka_Skill;
  fKeyFunctions[$74].Modifier := Integer(spbBomber);
  fKeyFunctions[$75].Action := lka_Skill;
  fKeyFunctions[$75].Modifier := Integer(spbBlocker);
  fKeyFunctions[$76].Action := lka_Skill;
  fKeyFunctions[$76].Modifier := Integer(spbBuilder);
  fKeyFunctions[$77].Action := lka_Skill;
  fKeyFunctions[$77].Modifier := Integer(spbBasher);
  fKeyFunctions[$78].Action := lka_Skill;
  fKeyFunctions[$78].Modifier := Integer(spbMiner);
  fKeyFunctions[$79].Action := lka_Skill;
  fKeyFunctions[$79].Modifier := Integer(spbDigger);
end;

class function TLemmixHotkeyManager.InterpretMain(s: String): TLemmixHotkeyAction;
begin
  s := LowerCase(s);
  Result := lka_Null;
  if s = 'skill' then Result := lka_Skill;
  if s = 'athlete_info' then Result := lka_ShowAthleteInfo;
  if s = 'quit' then Result := lka_Exit;
  if s = 'rr_up' then Result := lka_ReleaseRateUp;
  if s = 'rr_down' then Result := lka_ReleaseRateDown;
  if s = 'pause' then Result := lka_Pause;
  if s = 'nuke' then Result := lka_Nuke;
  if s = 'save_state' then Result := lka_SaveState;
  if s = 'load_state' then Result := lka_LoadState;
  if s = 'dir_select_left' then Result := lka_DirLeft;
  if s = 'dir_select_right' then Result := lka_DirRight;
  if s = 'force_walker' then Result := lka_ForceWalker;
  if s = 'cheat' then Result := lka_Cheat;
  if s = 'skip' then Result := lka_Skip;
  if s = 'special_skip' then Result := lka_SpecialSkip;
  if s = 'fastforward' then Result := lka_FastForward;
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
    else if s = 'shimmier' then Result := Integer(spbShimmier)
    else if s = 'climber' then Result := Integer(spbClimber)
    else if s = 'swimmer' then Result := Integer(spbSwimmer)
    else if s = 'floater' then Result := Integer(spbFloater)
    else if s = 'glider' then Result := Integer(spbGlider)
    else if s = 'disarmer' then Result := Integer(spbDisarmer)
    else if s = 'bomber' then Result := Integer(spbBomber)
    else if s = 'stoner' then Result := Integer(spbStoner)
    else if s = 'blocker' then Result := Integer(spbBlocker)
    else if s = 'platformer' then Result := Integer(spbPlatformer)
    else if s = 'builder' then Result := Integer(spbBuilder)
    else if s = 'stacker' then Result := Integer(spbStacker)
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
        // a lot of secondaries will be actually numeric
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
    else if FileExists(AppPath + 'NeoLemmixHotkeys.ini') then
      StringList.LoadFromFile(AppPath + 'NeoLemmixHotkeys.ini')
    else begin
      SetDefaults;
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
      SetDefaults;
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
      lka_ReleaseRateUp:    Result := 'RR_Up';
      lka_ReleaseRateDown:  Result := 'RR_Down';
      lka_Pause:            Result := 'Pause';
      lka_Nuke:             Result := 'Nuke';
      lka_SaveState:        Result := 'Save_State';
      lka_LoadState:        Result := 'Load_State';
      lka_DirLeft:          Result := 'Dir_Select_Left';
      lka_DirRight:         Result := 'Dir_Select_Right';
      lka_ForceWalker:      Result := 'Force_Walker';
      lka_Cheat:            Result := 'Cheat';
      lka_Skip:             Result := 'Skip';
      lka_SpecialSkip:      Result := 'Special_Skip';
      lka_FastForward:      Result := 'FastForward';
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
                    Integer(spbWalker):     Result := 'Walker';
                    Integer(spbShimmier):   Result := 'Shimmier';
                    Integer(spbClimber):    Result := 'Climber';
                    Integer(spbSwimmer):    Result := 'Swimmer';
                    Integer(spbFloater):    Result := 'Floater';
                    Integer(spbGlider):     Result := 'Glider';
                    Integer(spbDisarmer):   Result := 'Disarmer';
                    Integer(spbBomber):     Result := 'Bomber';
                    Integer(spbStoner):     Result := 'Stoner';
                    Integer(spbBlocker):    Result := 'Blocker';
                    Integer(spbPlatformer): Result := 'Platformer';
                    Integer(spbBuilder):    Result := 'Builder';
                    Integer(spbStacker):    Result := 'Stacker';
                    Integer(spbBasher):     Result := 'Basher';
                    Integer(spbFencer):     Result := 'Fencer';
                    Integer(spbMiner):      Result := 'Miner';
                    Integer(spbDigger):     Result := 'Digger';
                    Integer(spbCloner):     Result := 'Cloner';
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
    if fKeyFunctions[i].Action in [lka_Skill, lka_Skip, lka_SpecialSkip, lka_ClearPhysics] then
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

  // Too lazy to include them in an interally-included file. So I just
  // coded them in here. xD
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
    for i := 0 to 9 do
      Result[$30 + i] := IntToStr(i);
    for i := 0 to 25 do
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

procedure TLemmixHotkeyManager.SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
begin
  fKeyFunctions[aKey].Action := aFunc;
  fKeyFunctions[aKey].Modifier := aMod;end;

end.