{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  Classes, Controls, SysUtils, Math,
  GR32, GR32_Image, GR32_Layers,
  UMisc,
  Windows,
  LemmixHotkeys, LemStrings, LemTypes,
  LemLemming,
  LemDosStructures, LemDosStyle,
  LemCore, LemLevel, LemNeoTheme,
  GameControl,
  LemGame, LemRenderHelpers, //for PARTICLE_COLORS consts, not that i'm sure if it acutally needs them anymore
  GameSound,
  PngInterface,
  GameWindowInterface,
  GameBaseSkillPanel;

  {-------------------------------------------------------------------------------
    maybe this must be handled by lemgame (just bitmap writing)

  // info positions types:
  // 1. BUILDER(23)             1/14
  // 2. OUT 28                  15/23
  // 3. IN 99%                  24/31
  // 4. TIME 2-31               32/40

  -------------------------------------------------------------------------------}

type
  TSkillPanelToolbar = class(TBaseSkillPanel)
  private

  protected
    function GetButtonList: TPanelButtonArray; override;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    function MinimapRect: TRect; override;

    function DrawStringLength: Integer; override;
    function DrawStringTemplate: string; override;

    // The following stuff still needs to be updated


    //procedure SetInfoCursorLemming(const Lem: string; Num: Integer);
    procedure SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
    procedure SetReplayMark(Status: Integer);
    procedure SetTimeLimit(Status: Boolean); override;

  public
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;

    procedure RefreshInfo; override;
  end;

const
  PANEL_WIDTH = 416;
  PANEL_HEIGHT = 40;
  COMPACT_PANEL_WIDTH = 320;
  COMPACT_PANEL_HEIGHT = 40;

  MINIMAP_X = 308;
  MINIMAP_Y = 3;
  MINIMAP_WIDTH  = 104;
  MINIMAP_HEIGHT = 34;

  COMPACT_MINIMAP_X = 212;
  COMPACT_MINIMAP_Y = 18;
  COMPACT_MINIMAP_WIDTH = 104;
  COMPACT_MINIMAP_HEIGHT = 20;

const
  MiniMapCorners: TRect = (
    Left: MINIMAP_X + 2;
    Top: MINIMAP_Y + 2;
    Right: MINIMAP_X + MINIMAP_WIDTH;
    Bottom: MINIMAP_Y + MINIMAP_HEIGHT;
  );

  CompactMinimapCorners: TRect = (
    Left: COMPACT_MINIMAP_X + 2;
    Top: COMPACT_MINIMAP_Y + 2;
    Right: COMPACT_MINIMAP_X + COMPACT_MINIMAP_WIDTH;
    Bottom: COMPACT_MINIMAP_Y + COMPACT_MINIMAP_HEIGHT;
  );


implementation

uses
  LemReplay;

function PtInRectEx(const Rect: TRect; const P: TPoint): Boolean;
begin
  Result := (P.X >= Rect.Left) and (P.X < Rect.Right) and (P.Y >= Rect.Top)
    and (P.Y < Rect.Bottom);
end;

{ TSkillPanelToolbar }

constructor TSkillPanelToolbar.Create(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited Create(aOwner, aGameWindow);
end;

destructor TSkillPanelToolbar.Destroy;
begin
  inherited;
end;

function TSkillPanelToolbar.PanelWidth: Integer;
begin
  if GameParams.CompactSkillPanel then
    Result := COMPACT_PANEL_WIDTH
  else
    Result := PANEL_WIDTH;
end;

function TSkillPanelToolbar.PanelHeight: Integer;
begin
  if GameParams.CompactSkillPanel then
    Result := COMPACT_PANEL_HEIGHT
  else
    Result := PANEL_HEIGHT;
end;


function TSkillPanelToolbar.DrawStringLength: Integer;
begin
  Result := 38;
end;

function TSkillPanelToolbar.DrawStringTemplate: string;
begin
  Result := '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;






procedure TSkillPanelToolbar.RefreshInfo;
var
  i: TSkillPanelButton;
  TimeRemaining: Integer;
  IsBlinkFrame: Boolean;
  DoTimerBlink: Boolean;

  function GetSkillString(L: TLemming): String;
  var
    i: Integer;
    ShowAthleteInfo: Boolean;

    procedure DoInc(aText: String);
    begin
      Inc(i);
      case i of
        1: Result := aText;
        2: Result := SAthlete;
        3: Result := STriathlete;
        4: Result := SQuadathlete;
      end;
    end;
  begin
    if L = nil then
    begin
      Result := '';
      Exit;
    end;

    Result := LemmingActionStrings[L.LemAction];

    ShowAthleteInfo := L.LemIsZombie or GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo);

    if ShowAthleteInfo or (not (L.LemAction in [baBuilding, baPlatforming, baStacking, baBashing, baMining, baDigging, baBlocking])) then
    begin
      i := 0;
      if L.LemIsClimber then DoInc(SClimber);
      if L.LemIsSwimmer then DoInc(SSwimmer);
      if L.LemIsFloater then DoInc(SFloater);
      if L.LemIsGlider then DoInc(SGlider);
      if L.LemIsMechanic then DoInc(SMechanic);
      if L.LemIsZombie then Result := SZombie;

      if ShowAthleteInfo then
      begin
        Result := '-----';
        if L.LemIsClimber then Result[1] := 'C';
        if L.LemIsSwimmer then Result[2] := 'S';
        if L.LemIsFloater then Result[3] := 'F';
        if L.LemIsGlider then Result[3] := 'G';
        if L.LemIsMechanic then Result[4] := 'D';
        if L.LemIsZombie then Result[5] := 'Z';
      end;
    end;
  end;

begin
  IsBlinkFrame := (GetTickCount mod 1000) > 499;

  // hatch: (Count + Cloned - SpawnedDead) - (Out + Removed)
  // alive: (Count + Cloned - SpawnedDead) - Removed
  //    in: Saved - Requirement
  SetInfoLemHatch(Game.LemmingsToSpawn - Game.SpawnedDead);
  SetInfoLemAlive(Game.LemmingsToSpawn + Game.LemmingsActive - Game.SpawnedDead, ((Game.LemmingsToSpawn + Game.LemmingsActive + Game.SkillCount[spbCloner] - Game.SpawnedDead) < (Level.Info.RescueCount - Game.LemmingsSaved)) and IsBlinkFrame and GameParams.LemmingBlink);
  SetInfoLemIn(Game.LemmingsSaved - Level.Info.RescueCount);

  if Level.Info.HasTimeLimit then
  begin
    TimeRemaining := Level.Info.TimeLimit - (Game.CurrentIteration div 17);
    DoTimerBlink := IsBlinkFrame and (TimeRemaining <= 30) and GameParams.TimerBlink;
    SetInfoMinutes(TimeRemaining div 60, DoTimerBlink);
    SetInfoSeconds(TimeRemaining mod 60, DoTimerBlink);
  end else begin
    SetInfoMinutes(Game.CurrentIteration div (17 * 60));
    SetInfoSeconds((Game.CurrentIteration mod (17 * 60)) div 17);
  end;

  DrawNewStr;
  fLastDrawnStr := fNewDrawStr;

  for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    DrawSkillCount(i, Game.SkillCount[i]);

  DrawSkillCount(spbSlower, Level.Info.ReleaseRate);
  DrawSkillCount(spbFaster, Game.CurrentReleaseRate);

  if fHighlitSkill <> Game.RenderInterface.SelectedSkill then
  begin
    DrawButtonSelector(fHighlitSkill, false);
    DrawButtonSelector(Game.RenderInterface.SelectedSkill, true);
  end; // ugly code, but it's temporary

  DrawButtonSelector(spbNuke, (Game.UserSetNuking or (Game.ReplayManager.Assignment[Game.CurrentIteration, 0] is TReplayNuke)));

  SetInfoCursorLemming(1);
  //SetInfoCursorLemming(GetSkillString(Game.RenderInterface.SelectedLemming), Game.LastHitCount);

  if not Game.ReplayingNoRR[fGameWindow.GameSpeed = gspPause] then
    SetReplayMark(0)
  else if Game.ReplayInsert then
    SetReplayMark(2)
  else
    SetReplayMark(1);
end;

  (*
procedure TSkillPanelToolbar.SetInfoCursorLemming(const Lem: string; Num: Integer);
var
  S: string;
begin
  S := Uppercase(Lem);
  if Lem <> '' then
  begin

    if Num = 0 then
      S := PadR(S, 12)
    else
      S := PadR(S + ' ' + IntToStr(Num), 12); //
    Move(S[1], fNewDrawStr[1], 12);
  end
  else begin
    S := '             ';
    Move(S[1], fNewDrawStr[1], 12);
  end;
end;
   *)
procedure TSkillPanelToolbar.SetReplayMark(Status: Integer);
var
  S: String;
begin
  if Status = 1 then
    S := #91
  else if Status = 2 then
    S := #97
  else
    S := ' ';
  Move(S[1], fNewDrawStr[13], 1);
end;

procedure TSkillPanelToolbar.SetTimeLimit(Status: Boolean);
var
  S: String;
begin
  if Status then
    S := #96
  else
    S := #95;
  Move(S[1], fNewDrawStr[33], 1);
end;


procedure TSkillPanelToolbar.SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  Assert(Num >= 0, 'Negative number of lemmings in hatch displayed');
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';  // probably will never blink, but let's have the option there for futureproofing
  Move(S[1], fNewDrawStr[16], 4);
end;


procedure TSkillPanelToolbar.SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  Assert(Num >= 0, 'Negative number of alive lemmings displayed');
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';
  Move(S[1], fNewDrawStr[22], 4);
end;

procedure TSkillPanelToolbar.SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';
  Move(S[1], fNewDrawStr[28], 4);
end;

procedure TSkillPanelToolbar.SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  if Blinking then
    S := '  '
  else
    S := PadL(IntToStr(Num), 2);
  Move(S[1], fNewDrawStr[34], 2);
end;

procedure TSkillPanelToolbar.SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  if Blinking then
    S := '  '
  else
    S := LeadZeroStr(Num, 2);
  Move(S[1], fNewDrawStr[37], 2);
end;


function TSkillPanelToolbar.GetButtonList: TPanelButtonArray;
var
  ButtonList: TPanelButtonArray;
  i : Integer;
begin
  if GameParams.CompactSkillPanel then
  begin
    SetLength(ButtonList, 13);
    ButtonList[0] := spbSlower;
    ButtonList[1] := spbFaster;
    for i := 2 to 9 do
      ButtonList[i] := spbWalker; // placeholder for any skill
    ButtonList[10] := spbPause;
    ButtonList[11] := spbNuke;
    ButtonList[12] := spbFastForward;
  end
  else
  begin
    SetLength(ButtonList, 19);
    ButtonList[0] := spbSlower;
    ButtonList[1] := spbFaster;
    for i := 2 to 9 do
      ButtonList[i] := spbWalker; // placeholder for any skill
    ButtonList[10] := spbPause;
    ButtonList[11] := spbNuke;
    ButtonList[12] := spbFastForward;
    ButtonList[13] := spbRestart;
    ButtonList[14] := spbBackOneFrame;
    ButtonList[15] := spbForwardOneFrame;
    ButtonList[16] := spbClearPhysics;
    ButtonList[17] := spbDirLeft; // includes spbDirRight
    ButtonList[18] := spbLoadReplay;
  end;

  Result := ButtonList;
end;

procedure TSkillPanelToolbar.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(MinimapRegion);

  if (MinimapRegion.Height <> 38) and not GameParams.CompactSkillPanel then
  begin
    MinimapRegion.SetSize(111, 38);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 14);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 16));
  end;

  if (MinimapRegion.Height <> 24) and GameParams.CompactSkillPanel then
  begin
    MinimapRegion.SetSize(111, 24);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 12));
    TempBmp.DrawTo(MinimapRegion, 0, 12, Rect(0, 26, 112, 38));
  end;

  TempBmp.Free;
end;

function TSkillPanelToolbar.MinimapRect: TRect;
begin
  if GameParams.CompactSkillPanel then
    Result := Rect(212, 18, 316, 38)
  else
    Result := Rect(308, 3, 412, 37);
end;

end.

