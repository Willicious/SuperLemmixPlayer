unit LemmixHotkeys;

// A quick and shitty unit to allow for customizable hotkeys.

interface

uses
  Dialogs,
  Windows, Classes, SysUtils;

const
  MAX_KEY = 255;
  MAX_KEY_LEN = 4;
  KEYSET_VERSION = 6;

type
  TLemmixHotkeyAction = (lka_Null,
                         lka_Skill,
                         lka_SelectNewLem,
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
                         lka_FastForward,
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
                         lka_FallDistance);
  PLemmixHotkeyAction = ^TLemmixHotkeyAction;


  TLemmixHotkey = record
    Action: TLemmixHotkeyAction;
    Modifier: Integer;
  end;

  TLemmixHotkeyManager = class
    private
      fKeyFunctions: Array[0..MAX_KEY] of TLemmixHotkey;
      procedure SetDefaults;
      procedure LoadFile;
      function DoCheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer; CheckMod: Boolean): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      procedure SaveFile;
      procedure SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
      function CheckKeyEffect(aKey: Word): TLemmixHotkey;
      function CheckForKey(aFunc: TLemmixHotkeyAction): Boolean; overload;
      function CheckForKey(aFunc: TLemmixHotkeyAction; aMod: Integer): Boolean; overload;
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

procedure TLemmixHotkeyManager.SetDefaults;
begin
  // Hardcoded defaults. Used when a custom file can't be loaded (or doesn't exist).

  // Here's the simple ones that don't need further settings.
  fKeyFunctions[$02].Action := lka_Highlight;
  fKeyFunctions[$04].Action := lka_Pause;
  fKeyFunctions[$08].Action := lka_LoadState;
  fKeyFunctions[$0D].Action := lka_SaveState;
  fKeyFunctions[$10].Action := lka_SelectNewLem;
  fKeyFunctions[$11].Action := lka_ForceWalker;
  fKeyFunctions[$12].Action := lka_ShowAthleteInfo;
  fKeyFunctions[$19].Action := lka_ForceWalker;
  fKeyFunctions[$1B].Action := lka_Exit;
  fKeyFunctions[$25].Action := lka_DirLeft;
  fKeyFunctions[$27].Action := lka_DirRight;
  fKeyFunctions[$31].Action := lka_Cheat;
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

  // And here's the skill ones; these ones need the skill specified seperately
  fKeyFunctions[$33].Action := lka_Skill;
  fKeyFunctions[$33].Modifier := 0;
  fKeyFunctions[$34].Action := lka_Skill;
  fKeyFunctions[$34].Modifier := 2;
  fKeyFunctions[$35].Action := lka_Skill;
  fKeyFunctions[$35].Modifier := 4;
  fKeyFunctions[$36].Action := lka_Skill;
  fKeyFunctions[$36].Modifier := 5;
  fKeyFunctions[$37].Action := lka_Skill;
  fKeyFunctions[$37].Modifier := 7;
  fKeyFunctions[$38].Action := lka_Skill;
  fKeyFunctions[$38].Modifier := 9;
  fKeyFunctions[$39].Action := lka_Skill;
  fKeyFunctions[$39].Modifier := 11;
  fKeyFunctions[$30].Action := lka_Skill;
  fKeyFunctions[$30].Modifier := 15;
  fKeyFunctions[$72].Action := lka_Skill;
  fKeyFunctions[$72].Modifier := 1;
  fKeyFunctions[$73].Action := lka_Skill;
  fKeyFunctions[$73].Modifier := 3;
  fKeyFunctions[$74].Action := lka_Skill;
  fKeyFunctions[$74].Modifier := 6;
  fKeyFunctions[$75].Action := lka_Skill;
  fKeyFunctions[$75].Modifier := 8;
  fKeyFunctions[$76].Action := lka_Skill;
  fKeyFunctions[$76].Modifier := 10;
  fKeyFunctions[$77].Action := lka_Skill;
  fKeyFunctions[$77].Modifier := 12;
  fKeyFunctions[$78].Action := lka_Skill;
  fKeyFunctions[$78].Modifier := 13;
  fKeyFunctions[$79].Action := lka_Skill;
  fKeyFunctions[$79].Modifier := 14;
end;

procedure TLemmixHotkeyManager.LoadFile;
var
  StringList: TStringList;
  i, i2: Integer;
  istr: String;
  s0, s1: String;
  FoundSplit: Boolean;
  FixVersion: Integer;

  function InterpretMain(s: String): TLemmixHotkeyAction;
  begin
    s := LowerCase(s);
    Result := lka_Null;
    if s = 'skill' then Result := lka_Skill;
    if s = 'force_unused' then Result := lka_SelectNewLem;
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
    if s = 'fastforward' then Result := lka_FastForward;
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
  end;

  function InterpretSecondary(s: String): Integer;
  begin
    s := LowerCase(s);

    if s = 'walker' then Result := 0
    else if s = 'climber' then Result := 1
    else if s = 'swimmer' then Result := 2
    else if s = 'floater' then Result := 3
    else if s = 'glider' then Result := 4
    else if s = 'disarmer' then Result := 5
    else if s = 'mechanic' then Result := 5 // in case someone accidentally uses the old name
    else if s = 'bomber' then Result := 6
    else if s = 'stoner' then Result := 7
    else if s = 'blocker' then Result := 8
    else if s = 'platformer' then Result := 9
    else if s = 'builder' then Result := 10
    else if s = 'stacker' then Result := 11
    else if s = 'basher' then Result := 12
    else if s = 'miner' then Result := 13
    else if s = 'digger' then Result := 14
    else if s = 'cloner' then Result := 15
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

  procedure SetIfFree(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
  begin
    if fKeyFunctions[aKey].Action <> lka_Null then Exit;
    fKeyFunctions[aKey].Action := aFunc;
    fKeyFunctions[aKey].Modifier := aMod;
  end;
begin
  if FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmixHotkeys.ini') then
  begin
    StringList := TStringList.Create;
    try
      StringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixHotkeys.ini');
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

      FixVersion := StrToIntDef(StringList.Values['Version'], 0);
      
      if FixVersion < 1 then
        SetIfFree($C0, lka_ReleaseMouse);

      if FixVersion < 2 then
      begin
        SetIfFree($02, lka_Highlight);
        SetIfFree($04, lka_Pause);
      end;

      if FixVersion < 3 then
        SetIfFree($43, lka_CancelReplay);

      if FixVersion < 4 then
        SetIfFree($54, lka_ClearPhysics, 1);

      if FixVersion < 5 then
        SetIfFree($44, lka_FallDistance);

      if FixVersion < 6 then
      begin
        SetIfFree($45, lka_EditReplay);
        SetIfFree($57, lka_ReplayInsert);
      end;

    except
      SetDefaults;
    end;
    StringList.Free;
  end else
    SetDefaults;
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
      lka_SelectNewLem:     Result := 'Force_Unused';
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
      lka_FastForward:      Result := 'FastForward';
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
      else Result := 'Null';
    end;
  end;

  function InterpretSecondary(aValue: Integer): String;
  begin
    // Used only for skills!
    case aValue of
      0: Result := 'Walker';
      1: Result := 'Climber';
      2: Result := 'Swimmer';
      3: Result := 'Floater';
      4: Result := 'Glider';
      5: Result := 'Disarmer';
      6: Result := 'Bomber';
      7: Result := 'Stoner';
      8: Result := 'Blocker';
      9: Result := 'Platformer';
      10: Result := 'Builder';
      11: Result := 'Stacker';
      12: Result := 'Basher';
      13: Result := 'Miner';
      14: Result := 'Digger';
      15: Result := 'Cloner';
      else Result := IntToStr(aValue);
    end;
  end;
begin
  StringList := TStringList.Create;
  StringList.Add('Version=' + IntToStr(KEYSET_VERSION));
  for i := 0 to MAX_KEY do
  begin
    s := InterpretMain(fKeyFunctions[i].Action);
    if s = 'Null' then Continue;
    if fKeyFunctions[i].Action = lka_Skill then
      s := s + ':' + InterpretSecondary(fKeyFunctions[i].Modifier);
    if fKeyFunctions[i].Action = lka_Skip then
      s := s + ':' + IntToStr(fKeyFunctions[i].Modifier);
    if fKeyFunctions[i].Action = lka_ClearPhysics then
      s := s + ':' + IntToStr(fKeyFunctions[i].Modifier);
    StringList.Add(IntToHex(i, MAX_KEY_LEN) + '=' + s);
  end;
  try
    StringList.SaveToFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixHotkeys.ini')
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

procedure TLemmixHotkeyManager.SetKeyFunction(aKey: Word; aFunc: TLemmixHotkeyAction; aMod: Integer = 0);
begin
  fKeyFunctions[aKey].Action := aFunc;
  fKeyFunctions[aKey].Modifier := aMod;end;

end.