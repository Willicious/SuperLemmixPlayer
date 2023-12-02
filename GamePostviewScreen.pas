{$include lem_directives.inc}

unit GamePostviewScreen;

interface

uses
  Types,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Classes, SysUtils, StrUtils, Controls,
  UMisc, Math,
  Gr32, Gr32_Image, Gr32_Layers, GR32_Resamplers,
  LemCore,
  LemTypes,
  LemStrings, LemMenuFont,
  LemLevel, LemGame,
  LemGadgetsConstants,
  GameControl,
  GameSound,
  GameBaseScreenCommon, GameBaseMenuScreen;

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
    protected
      procedure PrepareGameParams; override;
      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;
      function GetBackgroundSuffix: String; override;

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

function TGamePostviewScreen.GetBackgroundSuffix: String;
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
  GameParams.NextLevel(true);
  GlobalGame.fReplayWasLoaded := False;
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
  if GameParams.ReplayAfterRestart then
    GlobalGame.fReplayWasLoaded := True;
end;

procedure TGamePostviewScreen.BuildScreen;
var
  NewRegion: TClickableRegion;
  Lines: TextLineArray;
const
  TEXT_Y_POSITION = 28;
begin
  fClickableRegions.Clear;
  ScreenImg.BeginUpdate;
  try
    // Draw text
    Lines := GetPostviewText;
    MenuFont.DrawTextLines(Lines, ScreenImg.Bitmap, TEXT_Y_POSITION);

    // MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 16);

    if GameParams.GameResult.gSuccess then
    begin
      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel)
      else if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel)
      else
        NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);

      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel)
      else if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel)
      else
        NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end else begin
      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel)
      else if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel)
      else
        NewRegion := MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end;

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu)
    else if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu)
    else
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
    else if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
    else
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    NewRegion.ShortcutKeys.Add(VK_F3);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionSaveReplay, SaveReplay)
    else if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionSaveReplay, SaveReplay)
    else
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionSaveReplay, SaveReplay);
    NewRegion.AddKeysFromFunction(lka_SaveReplay);

    MakeHiddenOption(VK_F2, ShowConfigMenu);

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
    if GameParams.LastActiveLevel then
      GameParams.NextUnsolvedLevel := False
    else if GameParams.GameResult.gSuccess and GameParams.NextUnsolvedLevel then
      GameParams.NextLevel(true);

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
  STarget: string;
  SDone: string;

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
  SetLength(Result, 9);
  LoadPostviewTextColours;

  STarget := IntToStr(Results.gToRescue);
  SDone := IntToStr(Results.gRescued);

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

    if GameParams.PostviewJingles then
    begin
      SoundManager.PurgePackSounds;

      if gRescued >= Level.Info.RescueCount then
        SoundManager.PlayPackSound('success', ExtractFilePath(GameParams.CurrentLevel.Group.FindFile('success.ogg')))
      else
        SoundManager.PlayPackSound('failure', ExtractFilePath(GameParams.CurrentLevel.Group.FindFile('failure.ogg')));
    end;
  end;

  // Top text
  HueShift.HShift := TopTextShift;
  if Results.gGotTalisman then
    Result[0].Line := STalismanUnlocked
  else if Results.gTimeIsUp then
    Result[0].Line := SYourTimeIsUp
  else
    Result[0].Line := 'All ' + GameParams.Renderer.Theme.LemNamesPlural + ' accounted for.';
  Result[0].ColorShift := HueShift;
  Result[0].yPos := 0 + LINE_Y_SPACING;

  // Rescue result rescued
  HueShift.HShift := RescueRecordShift;
  Result[1].Line := SYouRescued + SDone;
  Result[1].yPos := Result[0].yPos + (LINE_Y_SPACING * 2);
  Result[1].ColorShift := HueShift;

  // Rescue result needed
  Result[2].Line := SYouNeeded + STarget;
  Result[2].yPos := Result[1].yPos + LINE_Y_SPACING;
  Result[2].ColorShift := HueShift;

  // Rescue result record
  if Results.gSuccess and (Entry.UserRecords.LemmingsRescued.Value > 0)
  and (not Results.gToRescue <= 0) then
    Result[3].Line := SYourRecord + IntToStr(GameParams.CurrentLevel.UserRecords.LemmingsRescued.Value)
  else
    Result[3].Line := '';
  Result[3].yPos := Result[2].yPos + LINE_Y_SPACING;
  Result[3].ColorShift := HueShift;

  // Comment - we allocate 2 lines for this
  HueShift.HShift := CommentShift;
  WhichText := Entry.Group.PostviewTexts[GetResultIndex];
  Result[4].Line := WhichText.Text[0];
  Result[5].Line := WhichText.Text[1];
  Result[4].yPos := Result[3].yPos + (LINE_Y_SPACING * 2);
  Result[5].yPos := Result[4].yPos + LINE_Y_SPACING;
  Result[4].ColorShift := HueShift;
  Result[5].ColorShift := HueShift;

  // Time taken
  HueShift.HShift := TimeRecordShift;
  if (Results.gSuccess and not (Results.gToRescue <= 0))
  or ((GameParams.TestModeLevel <> nil) and (Results.gRescued >= Results.gToRescue)) then
    Result[6].Line := SYourTime + MakeTimeString(Results.gLastRescueIteration)
  else
    Result[6].Line := '';
  Result[6].yPos := Result[5].yPos + (LINE_Y_SPACING * 2);
  Result[6].ColorShift := HueShift;

  // Time record
  if (Results.gSuccess and (Entry.UserRecords.TimeTaken.Value > 0))
  and (not Results.gToRescue <= 0) then
    Result[7].Line := SYourTimeRecord + MakeTimeString(Entry.UserRecords.TimeTaken.Value)
  else
    Result[7].Line := '';
  Result[7].yPos := Result[6].yPos + LINE_Y_SPACING;
  Result[7].ColorShift := HueShift;

  // Skills record
  HueShift.HShift := SkillsRecordShift;
  if Results.gSuccess and (Entry.UserRecords.TotalSkills.Value >= 0)
  and (not Results.gToRescue <= 0) then
    Result[8].Line := SYourFewestSkills + IntToStr(Entry.UserRecords.TotalSkills.Value)
  else
    Result[8].Line := '';
  Result[8].yPos := Result[7].yPos + (LINE_Y_SPACING * 2);
  Result[8].ColorShift := HueShift;
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
  ReloadCursor;
end;

end.

