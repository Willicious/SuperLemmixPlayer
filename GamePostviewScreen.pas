{$include lem_directives.inc}

unit GamePostviewScreen;

interface

uses
  Types,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Classes, SysUtils, StrUtils, Controls,
  UMisc,
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
  ScreenImg.BeginUpdate;
  try
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 16);

    if GameParams.GameResult.gSuccess then
    begin
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionToMenu, ExitToMenu);
      NewRegion.ShortcutKeys.Add(VK_ESCAPE);

      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionNextLevel, NextLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);

      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_ONE_ROW_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end else begin
      NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionToMenu, ExitToMenu);
      NewRegion.ShortcutKeys.Add(VK_ESCAPE);

      NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionRetryLevel, ReplaySameLevel);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);
      NewRegion.AddKeysFromFunction(lka_Restart);
    end;

    MakeHiddenOption(VK_F2, DoLevelSelect);
    MakeHiddenOption(VK_F3, ShowConfigMenu);

    MakeHiddenOption(lka_SaveReplay, SaveReplay);

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

    procedure LF(aCount: Integer);
    begin
      Result := Result + StringOfChar(#13, aCount);
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
          if GameParams.Level.InteractiveObjects[i].Skill = Integer(spbCloner) then Inc(AdjLemCount);
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
      Result := IntToStr(aFrames div (17 * 60));
      Result := Result + ':' + LeadZeroStr((aFrames mod (17 * 60)) div 17, 2);
      Result := Result + '.' + CENTISECONDS[aFrames mod 17];
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

    if (not gCheated) and (GlobalGame.ReplayManager.IsThisUsersReplay) then
      with CurrentLevel do
      begin
        if gRescued > CurrentLevel.Records.LemmingsRescued then
          CurrentLevel.Records.LemmingsRescued := gRescued;

        if gSuccess then
        begin
          Status := lst_Completed;
          if (CurrentLevel.Records.TimeTaken = 0) or (gLastRescueIteration < CurrentLevel.Records.TimeTaken) then
            CurrentLevel.Records.TimeTaken := gLastRescueIteration;
        end else if Status = lst_None then
          Status := lst_Attempted;
      end;

    if gRescued >= Level.Info.RescueCount then
    begin
      if PostLevelVictorySound then
        SoundManager.PlaySound('success');
    end else begin
      if PostLevelFailureSound then
        SoundManager.PlaySound('failure');
    end;

    // init some local strings
    STarget := PadL(IntToStr(gToRescue), 4);
    SDone := PadL(IntToStr(gRescued), 4);

    // top text
    if gGotTalisman then
        Add(STalismanUnlocked)
    else if gTimeIsUp then
        Add(SYourTimeIsUp)
    else
        Add(SAllLemmingsAccountedFor);

    LF(2);

    Add(SYouRescued + SDone);
    Add(SYouNeeded + STarget);

    if GameParams.TestModeLevel <> nil then
      LF(1)
    else
      Add(SYourRecord + PadL(IntToStr(GameParams.CurrentLevel.Records.LemmingsRescued), 4));

    LF(1);

    Add(SYourTime + PadL(MakeTimeString(gLastRescueIteration), 8));
    if (GameParams.TestModeLevel <> nil) or not gSuccess then
      LF(1)
    else
      Add(SYourTimeRecord + PadL(MakeTimeString(GameParams.CurrentLevel.Records.TimeTaken), 8));

    LF(2);

    WhichText := GameParams.CurrentLevel.Group.PostviewTexts[GetResultIndex];
    for i := 0 to 6 do
    begin
      if i < WhichText.Text.Count then
        Add(WhichText.Text[i]);
    end;
  end;
end;

end.

