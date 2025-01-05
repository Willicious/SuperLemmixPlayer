{$include lem_directives.inc}

unit GamePostviewScreen;

interface

uses
  Types,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Classes, SysUtils, StrUtils, Controls, Dialogs,
  UMisc, Math,
  Gr32, Gr32_Image, Gr32_Layers, GR32_Resamplers,
  LemCore,
  LemTypes,
  LemStrings, LemMenuFont,
  LemLevel, LemGame,
  LemGadgetsConstants,
  GameControl,
  GameSound,
  GameBaseScreenCommon, GameBaseMenuScreen,
  SharedGlobals;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGamePostviewScreen = class(TGameBaseMenuScreen)
    private
      fAdvanceLevel: Boolean;

      function GetPostviewText: TextLineArray;
      procedure LoadPostviewTextColours;

      function GetResultIndex: Integer;
      procedure NextLevel;
      procedure ReplaySameLevel;
      procedure ExitToMenu;

      procedure MakeNextLevelClickable;
      procedure MakePlaybackNextLevelClickable;
      procedure MakeRetryLevelClickable(LevelPassed: Boolean);
      procedure MakeSaveReplayClickable;
      procedure MakeLevelSelectClickable;
      procedure MakeExitToMenuClickable;
    protected
      procedure PrepareGameParams; override;
      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;
      function GetWallpaperSuffix: String; override;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
      procedure DoAfterConfig; override;
  end;

implementation

uses Forms, LemNeoParser;

var
  TopTextShift: Extended;      // 0.150; - Teal
  RescueRecordShift: Extended; // 0.500; - Violet
  CommentShift: Extended;      // 0.600; - Red
  TimeRecordShift: Extended;   // 0.800; - Yellow
  SkillsRecordShift: Extended; // 0;     - Green (default)

{ TDosGamePreview }

procedure TGamePostviewScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited CloseScreen(aNextScreen);
end;

function TGamePostviewScreen.GetWallpaperSuffix: String;
begin
  Result := 'postview';
end;

procedure TGamePostviewScreen.PrepareGameParams;
begin
  inherited;
  fAdvanceLevel := GameParams.GameResult.gSuccess;
end;

procedure TGamePostviewScreen.NextLevel;
begin
  if not GameParams.PlaybackModeActive then
    GameParams.NextLevel(true);

  CloseScreen(gstPreview);
end;

procedure TGamePostviewScreen.OnMouseClick(aPoint: TPoint;
  aButton: TMouseButton);
begin
  inherited;
  case aButton of
    mbLeft: if GameParams.GameResult.gSuccess then NextLevel else ReplaySameLevel;
    mbRight: ExitToMenu;
    mbMiddle: ReplaySameLevel;
  end;
end;

procedure TGamePostviewScreen.ReplaySameLevel;
begin
  CloseScreen(gstPreview);
end;

procedure TGamePostviewScreen.MakeExitToMenuClickable;
var
  S: String;
  R: TClickableRegion;
  P: TPoint;
begin
  if GameParams.PlaybackModeActive then
  begin
    S := 'Cancel Playback Mode';

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else
      P := Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y);
  end else begin
    S := SOptionToMenu;

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else
      P := Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
  end;

  R := MakeClickableText(Point(P), S, ExitToMenu);
  R.ShortcutKeys.Add(VK_ESCAPE);
end;

procedure TGamePostviewScreen.MakeNextLevelClickable;
var
  R: TClickableRegion;
begin
  if GameParams.PlaybackModeActive then
    Exit;

  if GameParams.ShowMinimap and not GameParams.FullScreen then
    R := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel)
  else if GameParams.FullScreen then
    R := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel)
  else
    R := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel);

  R.ShortcutKeys.Add(VK_RETURN);
  R.ShortcutKeys.Add(VK_SPACE);
end;

procedure TGamePostviewScreen.MakePlaybackNextLevelClickable;
var
  R: TClickableRegion;
  S: String;
begin
  S := 'Playback Next Level';

  if GameParams.ShowMinimap and not GameParams.FullScreen then
    R := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), S, NextLevel)
  else if GameParams.FullScreen then
    R := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), S, NextLevel)
  else
    R := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), S, NextLevel);

  R.ShortcutKeys.Add(VK_RETURN);
  R.ShortcutKeys.Add(VK_SPACE);
end;

procedure TGamePostviewScreen.MakeRetryLevelClickable(LevelPassed: Boolean);
var
  P: TPoint;
  R: TClickableRegion;
begin
  if GameParams.PlaybackModeActive then
    Exit;

  if LevelPassed then
  begin
    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else
      P := Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y);
  end else begin
    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y)
    else
      P := Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y);
  end;

  R := MakeClickableText(Point(P), SOptionRetryLevel, ReplaySameLevel);

  if not LevelPassed then
  begin
    R.ShortcutKeys.Add(VK_RETURN);
    R.ShortcutKeys.Add(VK_SPACE);
  end;

  R.AddKeysFromFunction(lka_Restart);
end;

procedure TGamePostviewScreen.MakeSaveReplayClickable;
var
  R: TClickableRegion;
  P: TPoint;
begin
  if GameParams.PlaybackModeActive then
  begin
    if not GlobalGame.ReplayManager.ActionAddedDuringPlayback then
      Exit;

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else
      P := Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y);
  end else begin
    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else
      P := Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y);
  end;

  R := MakeClickableText(P, SOptionSaveReplay, SaveReplay);
  R.AddKeysFromFunction(lka_SaveReplay);
end;

procedure TGamePostviewScreen.MakeLevelSelectClickable;
var
  R: TClickableRegion;
begin
  if GameParams.PlaybackModeActive then
    Exit;

  if GameParams.ShowMinimap and not GameParams.FullScreen then
    R := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
  else if GameParams.FullScreen then
    R := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
  else
    R := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);

  R.ShortcutKeys.Add(VK_F3);
end;

procedure TGamePostviewScreen.BuildScreen;
var
  Lines: TextLineArray;
const
  TEXT_Y_POSITION = 28;
begin
  CurrentScreen := gstPostview;
  fClickableRegions.Clear;
  ScreenImg.BeginUpdate;

  try
    // Draw text
    Lines := GetPostviewText;
    MenuFont.DrawTextLines(Lines, ScreenImg.Bitmap, TEXT_Y_POSITION);

    { This needs to be called before the next level+replay is loaded
      so that modified replays can be saved in Playback Mode }
    MakeSaveReplayClickable;

    // If in PlaybackMode, load the next level or stop playback if the list is empty
    if GameParams.PlaybackModeActive then
    begin
      if GameParams.PlaybackIndex >= GameParams.PlaybackList.Count -1 then
        StopPlayback
      else
        StartPlayback(GameParams.PlaybackIndex + 1);
    end;

    // Check again for PlaybackMode after call to StartPlayback
    if GameParams.PlaybackModeActive then
      MakePlaybackNextLevelClickable
    else
      MakeSaveReplayClickable;

    // Check for success result and prepare the relevant clickables
    if GameParams.GameResult.gSuccess then
    begin
      MakeTalismanOptions;
      MakeNextLevelClickable;
      MakeRetryLevelClickable(True);
    end else begin
      MakeRetryLevelClickable(False);
    end;

    // Prepare some more clickables and hotkey options
    MakeLevelSelectClickable;
    MakeExitToMenuClickable;

    MakeHiddenOption(VK_F2, ShowConfigMenu);
    MakeHiddenOption(lka_CancelPlayback, CancelPlaybackMode);

    ReloadCursor('postview');

    // Draw clickables only if (AutoSkip + PlaybackMode) isn't active
    if not (GameParams.AutoSkipPreviewPostview and GameParams.PlaybackModeActive) then
      DrawAllClickables;
  finally
    ScreenImg.EndUpdate;
  end;
end;

procedure TGamePostviewScreen.ExitToMenu;
begin
  if GameParams.TestModeLevel <> nil then
    CloseScreen(gstExit)
  else begin
    GameParams.PlaybackModeActive := False;
    CloseScreen(gstMenu);
  end;
end;

function TGamePostviewScreen.GetResultIndex: Integer;
var
  i: Integer;
  AdjLemCount: Integer;
  CurrentMin: Integer;

  function ConditionMet(aText: TPostviewText): Boolean;
  var
    NewMin: Integer;
      begin
        with GameParams.GameResult do
        begin
          NewMin := $7FFFFFFF; // Avoid compiler warning
          case aText.ConditionType of
            pvc_Absolute: NewMin := aText.ConditionValue;
            pvc_Percent: NewMin := AdjLemCount * aText.ConditionValue div 100;
            pvc_Relative: NewMin := gToRescue + aText.ConditionValue;
            pvc_RelativePercent: NewMin := gToRescue + (gToRescue * aText.ConditionValue div 100);
          end;
          if (gRescued >= NewMin) and
            ((NewMin > CurrentMin) or ((aText.ConditionType in [pvc_Relative, pvc_RelativePercent]) and (aText.ConditionValue = 0))
            or ((aText.ConditionType = pvc_Percent) and (aText.ConditionValue = 100))) then
          begin
            Result := true;
            CurrentMin := NewMin;
          end else
            Result := false;
        end;
      end;
begin
  AdjLemCount := GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieCount;

  if spbCloner in GameParams.Level.Info.Skillset then
    AdjLemCount := AdjLemCount + GameParams.Level.Info.SkillCount[spbCloner];

  for i := 0 to GameParams.Level.InteractiveObjects.Count-1 do
    if GameParams.Renderer.FindGadgetMetaInfo(GameParams.Level.InteractiveObjects[i]).TriggerEffect = DOM_PICKUP then
      if GameParams.Level.InteractiveObjects[i].Skill = Integer(spbCloner) then
        Inc(AdjLemCount, Max(GameParams.Level.InteractiveObjects[i].TarLev, 1));

  Result := 0;
  CurrentMin := -1;

  for i := 0 to GameParams.CurrentLevel.Group.PostviewTexts.Count-1 do
    if ConditionMet(GameParams.CurrentLevel.Group.PostviewTexts[i]) then
      Result := i;
end;

function TGamePostviewScreen.GetPostviewText: TextLineArray;
const
  LINE_Y_SPACING = 28;

var
  HueShift: TColorDiff;
  Results: TGameResultsRec;
  Entry: TNeoLevelEntry;
  WhichText: TPostviewText;
  STarget, SRescued, STimeSR, STimeTotal: string;
  SRescueRecord, STimeRecord, SSkillsRecord, SThisLine: string;
  InfiniteHotkeysUsed, LevelHasTalismans, ShowSavedRecord: Boolean;

  function MakeTimeString(aFrames: Integer): String;
  const
    CENTISECONDS: array[0..16] of String = ('00', '06', '12', '18', '24', '29', '35', '41', '47',
                                            '53', '59', '65', '71', '76', '82', '88', '94');
  begin
    if aFrames < 0 then
      Result := '0:00.00'
    else begin
      Result := IntToStr(aFrames div (17 * 60));
      Result := Result + ':' + LeadZeroStr((aFrames mod (17 * 60)) div 17, 2);
      Result := Result + '.' + CENTISECONDS[aFrames mod 17];
    end;
  end;

  function GetSkillRecordValue(aNewValue, aOldValue: Integer): Integer;
  begin
    if (aOldValue < 0) or (aNewValue < aOldValue) then
      Result := aNewValue
    else
      Result := aOldValue;
  end;
begin
  Results := GameParams.GameResult;
  Entry := GameParams.CurrentLevel;
  FillChar(HueShift, SizeOf(TColorDiff), 0);
  SetLength(Result, 10);
  LoadPostviewTextColours;

  STarget := IntToStr(Results.gToRescue);
  SRescued := IntToStr(Results.gRescued);

  STimeSR := MakeTimeString(Results.gLastRescueIteration);
  STimeTotal := MakeTimeString(Results.gLastIteration);

  SRescueRecord := IntToStr(Entry.UserRecords.LemmingsRescued.Value);
  STimeRecord := MakeTimeString(Entry.UserRecords.TimeTaken.Value);
  SSkillsRecord := IntToStr(Entry.UserRecords.TotalSkills.Value);

  InfiniteHotkeysUsed := GlobalGame.IsInfiniteSkillsMode or GlobalGame.IsInfiniteTimeMode;
  LevelHasTalismans := (Entry.Talismans.Count > 0) or (GameParams.Level.Info.CollectibleCount > 0);

  with GameParams, Results do
  begin
    if GameParams.OneLevelMode then
    begin
     gSuccess := false;
     gCheated := false;
     fLevelOverride := $0000;
    end;

    if TestModeLevel <> nil then
    begin
      gSuccess := false;
      gCheated := false;
      fLevelOverride := $0000;
    end;

    if GameParams.PostviewJingles or GameParams.AmigaTheme then
    begin
      SoundManager.PurgePackSounds;

      if gRescued >= Level.Info.RescueCount then
      begin
        if GameParams.AmigaTheme then
          SoundManager.PlaySound(SFX_AmigaDisk1)
        else
          SoundManager.PlayPackSound('success', ExtractFilePath(GameParams.CurrentLevel.Group.FindFile('success.ogg')))
      end else begin
        if GameParams.AmigaTheme then
          SoundManager.PlaySound(SFX_AmigaDisk2)
        else
          SoundManager.PlayPackSound('failure', ExtractFilePath(GameParams.CurrentLevel.Group.FindFile('failure.ogg')));
      end;
    end;
  end;

  // Top text
  HueShift.HShift := TopTextShift;

  if (Results.gGotNewTalisman or Results.gGotTalisman) and GlobalGame.ReplayManager.IsThisUsersReplay then
  begin
    if Results.gGotNewTalisman then
      Result[0].Line := STalismanUnlocked
    else
      Result[0].Line := STalismanAchieved;
  end else if Results.gTimeIsUp then
    Result[0].Line := SYourTimeIsUp
  else
    Result[0].Line := 'All ' + GameParams.Renderer.Theme.LemNamesPlural + ' accounted for.';
  Result[0].ColorShift := HueShift;
  Result[0].yPos := 0 + LINE_Y_SPACING;

  // Rescue result - needed
  HueShift.HShift := RescueRecordShift;
  if LevelHasTalismans and Results.gSuccess then
    Result[1].Line := ''
  else
    Result[1].Line := SYouNeeded + ' ' + STarget + StringOfChar(' ', 3 - STarget.Length);
  Result[1].yPos := Result[0].yPos + (LINE_Y_SPACING * 2);
  Result[1].ColorShift := HueShift;

  // Rescue result - rescued
  if LevelHasTalismans and Results.gSuccess then
    Result[2].Line := ''
  else
    Result[2].Line := SYouRescued + SRescued + StringOfChar(' ', 3 - SRescued.Length);
  Result[2].yPos := Result[1].yPos + LINE_Y_SPACING;
  Result[2].ColorShift := HueShift;

  // Rescue result - record
  ShowSavedRecord := Results.gSuccess
                     and (Entry.UserRecords.LemmingsRescued.Value > 0)
                     and (not Results.gToRescue <= 0)
                     and not InfiniteHotkeysUsed;

  if LevelHasTalismans and Results.gSuccess then
  begin
    SThisLine := SYouNeeded + STarget + ' | ' + SYouRescued + SRescued;

    if ShowSavedRecord then
      Result[3].Line := SThisLine + ' | ' + SYourRecord + SRescueRecord
    else
      Result[3].Line := SThisLine;
  end else if ShowSavedRecord then
    Result[3].Line := SYourRecord + SRescueRecord +
                      StringOfChar(' ', 3 - SRescueRecord.Length)
  else
    Result[3].Line := '';

  Result[3].yPos := Result[2].yPos + LINE_Y_SPACING;
  Result[3].ColorShift := HueShift;

  // Comment - we allocate 2 lines for this
  HueShift.HShift := CommentShift;
  if InfiniteHotkeysUsed then
  begin
    var S := '';

    if GlobalGame.IsInfiniteSkillsMode and GlobalGame.IsInfiniteTimeMode then
      S := 'skills and time'
    else if GlobalGame.IsInfiniteSkillsMode then
      S := 'skills'
    else
      S := 'time';

    Result[4].Line := 'You used infinite ' + S + ' to play this level';
    Result[5].Line := 'Try again sometime with the intended skillset';
  end else begin
    WhichText := Entry.Group.PostviewTexts[GetResultIndex];
    Result[4].Line := WhichText.Text[0];
    Result[5].Line := WhichText.Text[1];
  end;

  Result[4].yPos := Result[3].yPos + (LINE_Y_SPACING * 2);
  Result[5].yPos := Result[4].yPos + LINE_Y_SPACING;
  Result[4].ColorShift := HueShift;
  Result[5].ColorShift := HueShift;

  // Always show total time taken
  HueShift.HShift := TimeRecordShift;
  Result[6].Line := SYourTotalTime + STimeTotal;
  Result[6].yPos := Result[5].yPos + (LINE_Y_SPACING * 2);
  Result[6].ColorShift := HueShift;

  // Time taken to reach SR
  if (Results.gSuccess and not (Results.gToRescue <= 0))
  or ((GameParams.TestModeLevel <> nil) and (Results.gRescued >= Results.gToRescue)) then
    Result[7].Line := SYourTime + STimeSR
  else
    Result[7].Line := '';
  Result[7].yPos := Result[6].yPos + LINE_Y_SPACING;
  Result[7].ColorShift := HueShift;

  // Time record
  if (Results.gSuccess and (Entry.UserRecords.TimeTaken.Value > 0))
  and (not Results.gToRescue <= 0) and not InfiniteHotkeysUsed then
    Result[8].Line := SYourTimeRecord + STimeRecord
  else
    Result[8].Line := '';
  Result[8].yPos := Result[7].yPos + LINE_Y_SPACING;
  Result[8].ColorShift := HueShift;

  // Skills record
  HueShift.HShift := SkillsRecordShift;
  if (Results.gSuccess and (Entry.UserRecords.TotalSkills.Value >= 0))
  and (not Results.gToRescue <= 0) and not InfiniteHotkeysUsed then
    Result[9].Line := SYourFewestSkills + SSkillsRecord
  else
    Result[9].Line := '';
  Result[9].yPos := Result[8].yPos + (LINE_Y_SPACING * 2);
  Result[9].ColorShift := HueShift;
end;

procedure TGamePostviewScreen.LoadPostviewTextColours;
var
  Parser: TParser;
  Sec: TParserSection;
  aPath: string;
  aFile: string;

  // Default SLX colours, loaded if custom files don't exist
  procedure ResetColours;
  begin
    TopTextShift := 0.150;      // Teal
    RescueRecordShift := 0.500; // Violet
    CommentShift := 0.600;      // Red
    TimeRecordShift := 0.800;   // Yellow
    SkillsRecordShift := 0;     // Green (default)
  end;

begin
  ResetColours;

  aFile := 'textcolours.nxmi';
  aPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

  if aPath = '' then
  aPath := AppPath + SFLevels;

  if (GameParams.CurrentLevel = nil)
    or not (FileExists(aPath + aFile) or FileExists(AppPath + SFData + aFile))
      then Exit;

  Parser := TParser.Create;
  try
    if FileExists(aPath + aFile) then
      Parser.LoadFromFile(aPath + aFile)
    else if FileExists(AppPath + SFData + aFile) then
      Parser.LoadFromFile(AppPath + SFData + aFile);

    Sec := Parser.MainSection.Section['postview'];
    if Sec = nil then Exit;

    TopTextShift := StrToFloatDef(Sec.LineString['top_text'], 0.150);
    RescueRecordShift := StrToFloatDef(Sec.LineString['rescue_record'], 0.500);
    CommentShift := StrToFloatDef(Sec.LineString['comment'], 0.600);
    TimeRecordShift := StrToFloatDef(Sec.LineString['time_record'], 0.800);
    SkillsRecordShift := StrToFloatDef(Sec.LineString['skills_record'], 0);
  finally
    Parser.Free;
  end;
end;

procedure TGamePostviewScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('postview');
end;

end.

