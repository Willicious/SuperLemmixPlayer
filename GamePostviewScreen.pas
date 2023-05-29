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
  LemStrings,
  LemGame,
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
      function GetScreenText: string;
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

uses Forms;

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

procedure TGamePostviewScreen.BuildScreen;
var
  NewRegion: TClickableRegion;
begin
  fClickableRegions.Clear;
  ScreenImg.BeginUpdate;
  try
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 16);

    if GameParams.GameResult.gSuccess then
    begin
      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel);
      if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel);
      if not GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionNextLevel, NextLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);

      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      if not GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end else begin
      if GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      if GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      if not GameParams.ShowMinimap and not GameParams.FullScreen then
        NewRegion := MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end;

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    NewRegion.ShortcutKeys.Add(VK_F3);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionSaveReplay, SaveReplay);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionSaveReplay, SaveReplay);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
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
  else
    CloseScreen(gstMenu);
end;

function TGamePostviewScreen.GetScreenText: string;
var
  WhichText: TPostviewText;
  i: Integer;
  STarget: string;
  SDone: string;

    procedure Add(const S: string);
    begin
      Result := Result + S + #13;
    end;

    procedure LF(aCount: Double);
    begin
      if aCount >= 1 then
        Result := Result + StringOfChar(#13, Floor(aCount));
      if Floor(aCount) <> Ceil(aCount) then
        Result := Result + #12;
    end;

    function GetResultIndex: Integer;
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
          NewMin := $7FFFFFFF; // avoid compiler warning
          case aText.ConditionType of
            pvc_Absolute: NewMin := aText.ConditionValue;
            pvc_Percent: NewMin := AdjLemCount * aText.ConditionValue div 100;
            pvc_Relative: NewMin := gToRescue + aText.ConditionValue;
            pvc_RelativePercent: NewMin := gToRescue + (gToRescue * aText.ConditionValue div 100);
          end;
          if (gRescued >= NewMin)
             and
            ((NewMin > CurrentMin)
             or
             ((aText.ConditionType in [pvc_Relative, pvc_RelativePercent]) and (aText.ConditionValue = 0))
             or
             ((aText.ConditionType = pvc_Percent) and (aText.ConditionValue = 100))
             ) then
          begin
            Result := true;
            CurrentMin := NewMin;
          end else
            Result := false;
        end;
      end;
    begin
      AdjLemCount := GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieCount;
      if spbCloner in GameParams.Level.Info.Skillset then AdjLemCount := AdjLemCount + GameParams.Level.Info.SkillCount[spbCloner];
      for i := 0 to GameParams.Level.InteractiveObjects.Count-1 do
        if GameParams.Renderer.FindGadgetMetaInfo(GameParams.Level.InteractiveObjects[i]).TriggerEffect = DOM_PICKUP then
          if GameParams.Level.InteractiveObjects[i].Skill = Integer(spbCloner) then Inc(AdjLemCount, Max(GameParams.Level.InteractiveObjects[i].TarLev, 1));
      Result := 0;
      CurrentMin := -1;
      for i := 0 to GameParams.CurrentLevel.Group.PostviewTexts.Count-1 do
        if ConditionMet(GameParams.CurrentLevel.Group.PostviewTexts[i]) then
          Result := i;
    end;

    function MakeTimeString(aFrames: Integer): String;
    const
      CENTISECONDS: array[0..16] of String = ('00', '06', '12', '18',
                                              '24', '29', '35', '41',
                                              '47', '53', '59', '65',
                                              '71', '76', '82', '88',
                                              '94');
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

  Result := '';
  with GameParams, GameResult do
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

    // init some local strings
    STarget := PadL(IntToStr(gToRescue), 4);
    SDone := PadL(IntToStr(gRescued), 4);

    // top text
    if gGotNewTalisman then
        Add(STalismanUnlocked)
    else if gTimeIsUp then
        Add(SYourTimeIsUp)
    else
        Add('All ' + GameParams.Renderer.Theme.LemNamesPlural + ' accounted for.');

    LF(2);

    Add(SYouRescued + SDone);
    LF(0.5);
    Add(SYouNeeded + STarget);
    LF(0.5);

    if GameParams.TestModeLevel <> nil then
      LF(1)
    else if GameParams.CurrentLevel.UserRecords.LemmingsRescued.Value < 0 then
      Add(SYourRecord + PadL('0', 4))
    else
      Add(SYourRecord + PadL(IntToStr(GameParams.CurrentLevel.UserRecords.LemmingsRescued.Value), 4));

    LF(2);

    WhichText := GameParams.CurrentLevel.Group.PostviewTexts[GetResultIndex];
    for i := 0 to 6 do
    begin
      if i < WhichText.Text.Count then
        Add(WhichText.Text[i]);
    end;

    if gSuccess then
    begin
      LF(2);

      Add(SYourTime + PadL(MakeTimeString(gLastRescueIteration), 8));
      LF(0.5);
      if (GameParams.TestModeLevel <> nil) then
        LF(1)
      else
        Add(SYourTimeRecord + PadL(MakeTimeString(GameParams.CurrentLevel.UserRecords.TimeTaken.Value), 8));
    end;
  end;
end;

procedure TGamePostviewScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor;
end;

end.

