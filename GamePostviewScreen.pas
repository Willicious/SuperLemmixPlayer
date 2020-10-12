{$include lem_directives.inc}

unit GamePostviewScreen;

interface

uses
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
  protected
    procedure PrepareGameParams; override;
    procedure BuildScreen; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;

    procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    procedure OnKeyPress(aKey: Integer); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

implementation

uses Forms;

{ TDosGamePreview }

procedure TGamePostviewScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited CloseScreen(aNextScreen);
end;

procedure TGamePostviewScreen.PrepareGameParams;
begin
  inherited;
  fAdvanceLevel := GameParams.GameResult.gSuccess;
end;

procedure TGamePostviewScreen.NextLevel;
begin
  if fAdvanceLevel then
    GameParams.NextLevel(true);
  CloseScreen(gstPreview);
end;

procedure TGamePostviewScreen.ReplaySameLevel;
begin
  CloseScreen(gstPreview);
end;

procedure TGamePostviewScreen.BuildScreen;
var
  Temp: TBitmap32;
begin
  ScreenImg.BeginUpdate;
  try
    Temp := ScreenImg.Bitmap;

    Temp.SetSize(INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);
    Temp.Clear(0);
    DrawBackground;
    MenuFont.DrawTextCentered(Temp, GetScreenText, 16);

    if GameParams.LinearResampleMenu then
      TLinearResampler.Create(ScreenImg.Bitmap);
  finally
    ScreenImg.EndUpdate;
  end;
end;

constructor TGamePostviewScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
end;

destructor TGamePostviewScreen.Destroy;
begin
  inherited Destroy;
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
      if i >= WhichText.Text.Count then
        LF(1)
      else
        Add(WhichText.Text[i]);
    end;

    LF(2);

    // bottom text

    // different texts in different situations
    if (gCheated and not gSuccess) then
    begin
      Add(SPressMouseToContinue)
    end
    // default bottom text
    else begin
      if gSuccess then
      begin
        Add(SPressLeftMouseForNextLevel);
        Add(SPressMiddleMouseToReplayLevel);
      end else begin
        LF(1);
        Add(SPressLeftMouseToRetryLevel);
      end;
      Add(SPressRightMouseForMenu);
    end;
  end;
end;

procedure TGamePostviewScreen.OnKeyPress(aKey: Integer);
var
  S: String;
begin
  if GameParams.Hotkeys.CheckKeyEffect(aKey).Action = lka_SaveReplay then
  begin
    S := GlobalGame.ReplayManager.GetSaveFileName(self, GlobalGame.Level);
    if S = '' then Exit;
    GlobalGame.EnsureCorrectReplayDetails;
    GlobalGame.ReplayManager.SaveToFile(S);
    Exit;
  end;

  if GameParams.Hotkeys.CheckKeyEffect(aKey).Action = lka_Restart then
  begin
    ReplaySameLevel;
    Exit;
  end;

  case aKey of
    VK_ESCAPE : begin
                  if GameParams.TestModeLevel <> nil then
                    CloseScreen(gstExit)
                  else
                    CloseScreen(gstMenu);
                end;
    VK_RETURN : NextLevel;
    VK_F2     : DoLevelSelect;
    VK_F3     : ShowConfigMenu;
  end;
end;

procedure TGamePostviewScreen.OnMouseClick(aPoint: TPoint;
  aButton: TMouseButton);
begin
  if aButton = mbLeft then
    NextLevel
  else if aButton = mbMiddle then
    ReplaySameLevel
  else if aButton = mbRight then
  begin
    if GameParams.TestModeLevel <> nil then
      CloseScreen(gstExit)
    else
      CloseScreen(gstMenu);
  end;
end;

end.

