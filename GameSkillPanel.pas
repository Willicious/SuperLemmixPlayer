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
    function GetButtonList: TStringArray; override;

    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    function MinimapRect: TRect; override;

    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;
    procedure ImgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;
    procedure ImgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;

    procedure MinimapMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;
    procedure MinimapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;
    procedure MinimapMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer); override;

    procedure SetZoom(aZoom: Integer); override;
    function GetZoom: Integer; override;

    procedure SetButtonRects; override;

    procedure DrawNewStr;

    procedure SetInfoCursorLemming(const Lem: string; Num: Integer);
    procedure SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
    procedure SetReplayMark(Status: Integer);
    procedure SetTimeLimit(Status: Boolean); override;

    property DoHorizontalScroll: Boolean read fDoHorizontalScroll write fDoHorizontalScroll;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

  public
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;

    procedure RefreshInfo; override;
    procedure SetCursor(aCursor: TCursor); override;

    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer); override;
    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean); override;
    procedure DrawMinimap; override;

    procedure SetStyleAndGraph(const Value: TBaseDosLemmingStyle; aScale: Integer); override;


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


destructor TSkillPanelToolbar.Destroy;
begin
  inherited;
end;

procedure TSkillPanelToolbar.SetZoom(aZoom: Integer);
begin
  aZoom := Max(Min(MaxZoom, aZoom), 1);

  Width := fGameWindow.GetWidth;
  Height := fGameWindow.GetHeight;

  if aZoom = Trunc(Image.Scale) then Exit;
  Image.Width := PanelWidth * aZoom;
  Image.Height := 40 * aZoom;
  Image.Left := (Width - Image.Width) div 2;
  Image.Scale := aZoom;
  if GameParams.CompactSkillPanel then
  begin
    fMinimapImage.Width := COMPACT_MINIMAP_WIDTH * aZoom;
    fMinimapImage.Height := COMPACT_MINIMAP_HEIGHT * aZoom;
    fMinimapImage.Left := (COMPACT_MINIMAP_X * aZoom) + Image.Left;
    fMinimapImage.Top := COMPACT_MINIMAP_Y * aZoom;
  end else begin
    fMinimapImage.Width := MINIMAP_WIDTH * aZoom;
    fMinimapImage.Height := MINIMAP_HEIGHT * aZoom;
    fMinimapImage.Left := (MINIMAP_X * aZoom) + Image.Left;
    fMinimapImage.Top := MINIMAP_Y * aZoom;
  end;
  fMinimapImage.Scale := aZoom;
end;

function TSkillPanelToolbar.GetZoom: Integer;
begin
  Result := Trunc(Image.Scale);
end;

procedure TSkillPanelToolbar.SetCursor(aCursor: TCursor);
begin
  Cursor := aCursor;
  Image.Cursor := aCursor;
  fMinimapImage.Cursor := aCursor;
end;


procedure TSkillPanelToolbar.DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
var
  R: TRect;
  C: TColor32;
  A: TRect;
begin
  if fGameWindow.IsHyperSpeed then Exit;

  if (aButton = spbNone) or ((aButton = fHighlitSkill) and (Highlight = true)) then
    Exit;

  if fButtonRects[aButton].Left <= 0 then Exit;

  case Highlight of
    False :
      begin
        if aButton < spbNone then
        begin
          if fHighlitSkill = spbNone then Exit;
          R := fButtonRects[fHighlitSkill];
          fLastHighlitSkill := fHighlitSkill;
          fHighlitSkill := spbNone;
        end else
          R := fButtonRects[aButton];
        Inc(R.Right);
        Inc(R.Bottom, 2);

        // top
        A := R;
        A.Bottom := A.Top + 1;
        fOriginal.DrawTo(Image.Bitmap, A, A);

        // left
        A := R;
        A.Right := A.Left + 1;
        fOriginal.DrawTo(Image.Bitmap, A, A);

        // right
        A := R;
        A.Left := A.Right - 1;
        fOriginal.DrawTo(Image.Bitmap, A, A);

        // bottom
        A := R;
        A.Top := A.Bottom - 1;
        fOriginal.DrawTo(Image.Bitmap, A, A);
      end;
    True  :
      begin
        if aButton < spbNone then // we don't want to memorize this for eg. fast forward
        begin
          fHighlitSkill := aButton;
          R := fButtonRects[fHighlitSkill];
          if (fLastHighlitSkill <> spbNone) and (fLastHighlitSkill <> fHighlitSkill) then
            SoundManager.PlaySound(SFX_SKILLBUTTON);
        end else
          R := fButtonRects[aButton];
        Inc(R.Right);
        Inc(R.Bottom, 2);

        C := fRectColor;

        Image.Bitmap.FrameRectS(R, C);
      end;
  end;
end;

procedure TSkillPanelToolbar.DrawNewStr;
var
  O, N: char;
  i, x, y, idx: integer;
begin
  // optimze this by pre-drawing
     // - "OUT "
     // - "IN "
     // - "TIME "
     // - "-"

  // info positions types:
  // 1. BUILDER(23)             1/14               0..13
  // 2. OUT 28                  15/23              14..22
  // 3. IN 99%                  24/31              23..30
  // 4. TIME 2-31               32/40              31..39

  y := 0;
  x := 0;

  for i := 1 to 38 do
  begin
    idx := -1;
    O := fLastDrawnStr[i];
    N := fNewDrawStr[i];

    if O <> N then
    begin

      case N of
        '%':
          begin
            idx := 0;
          end;
        '0'..'9':
          begin
            idx := ord(n) - ord('0') + 1;
          end;
        '-':
          begin
            idx := 11;
          end;
        'A'..'Y':
          begin
            idx := ord(n) - ord('A') + 12;
          end;
        'Z':
          begin
            idx := ord(n) - ord('A') + 12;
          end;
        #91 .. #97:
          begin
            idx := ord(n) - ord('A') + 12;
          end;
      end;

      if idx >= 0 then
        fInfoFont[idx].DrawTo(Image.Bitmap, x, 0)
      else
        Image.Bitmap.FillRectS(x, y, x + 8, y + 16, 0);
    end;

    Inc(x, 8);

  end;
end;


procedure TSkillPanelToolbar.DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
var
  S: string;
  L, R: Char;
  BtnIdx: Integer;
  DstRect, SrcRect: TRect;
  aoNumber: Integer;

const
  FontYPos = 17;

begin
  // x = 3, 19, 35 etc. are the "black holes" for the numbers in the image
  // y = 17

  if fButtonRects[aButton].Left < 0 then Exit;

  fSkillCounts[aButton] := aNumber;

  if fGameWindow.IsHyperSpeed then Exit;

  aoNumber := aNumber;
  aNumber := Math.Max(aNumber mod 100, 0);

  S := LeadZeroStr(aNumber, 2);
  L := S[1];
  R := S[2];

  BtnIdx := (fButtonRects[aButton].Left - 1) div 16;

  // If release rate locked, display as such
  if (aButton = spbFaster) and (Level.Info.ReleaseRateLocked or (Level.Info.ReleaseRate = 99)) then
  begin
    fSkillLock.DrawTo(Image.Bitmap, BtnIdx * 16 + 4, 17);
    Exit;
  end;

  // White out if applicable
  fSkillCountErase.DrawTo(Image.Bitmap, BtnIdx * 16 + 1, 16);
  if (aoNumber = 0) and (GameParams.BlackOutZero) then Exit;

  // Draw infinite symbol if, well, infinite.
  if (aoNumber > 99) then
  begin
    DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 8, 17 + 8);
    SrcRect := Rect(0, 0, 8, 8);
    fSkillInfinite.DrawTo(fImage.Bitmap, DstRect, SrcRect);
    Exit;
  end;

  // left
  DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 4, 17 + 8);
  SrcRect := Rect(0, 0, 4, 8);
  if (aoNumber >= 10) then fSkillFont[L, 1].DrawTo(fImage.Bitmap, DstRect, SrcRect); // 1 is left

  // right
  OffsetRect(DstRect, 2, 0);
  if (aoNumber >= 10) then OffsetRect(DstRect, 2, 0);
  SrcRect := Rect(4, 0, 8, 8);
  fSkillFont[R, 0].DrawTo(fImage.Bitmap, DstRect, SrcRect); // 0 is right

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

  SetInfoCursorLemming(GetSkillString(Game.RenderInterface.SelectedLemming), Game.LastHitCount);

  if not Game.ReplayingNoRR[fGameWindow.GameSpeed = gspPause] then
    SetReplayMark(0)
  else if Game.ReplayInsert then
    SetReplayMark(2)
  else
    SetReplayMark(1);
end;



procedure TSkillPanelToolbar.ImgMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
  Mouse behaviour of toolbar.
  o Minimap scrolling
  o button clicks
-------------------------------------------------------------------------------}
var
  P: TPoint;
  i: TSkillPanelButton;
  R: PRect;
  Exec: Boolean;
begin
  P := Image.ControlToBitmap(Point(X, Y));
  fGameWindow.ApplyMouseTrap;

  if fGameWindow.IsHyperSpeed then
    Exit;

  for i := Low(TSkillPanelButton) to High(TSkillPanelButton) do // "ignore" spbNone
  begin
    R := @fButtonRects[i];
    if PtInRectEx(R^, P) then
    begin

      if GameParams.ExplicitCancel and (i in [spbSlower, spbFaster, spbNuke]) then Exit;

      if (Game.Replaying) and (i in [spbSlower, spbFaster]) and not (Game.Level.Info.ReleaseRateLocked) then
      begin
        if ((i = spbSlower) and (Game.CurrentReleaseRate > Level.Info.ReleaseRate))
        or ((i = spbFaster) and (Game.CurrentReleaseRate < 99)) then
          Game.RegainControl;
      end;

      Exec := true;
      if i = spbNuke then
        Exec := ssDouble in Shift;

      if Exec then
        if i < spbFastForward then // handled by TLemmingGame alone
        begin
          if i in [spbNuke] then
            Game.RegainControl;

          if i in [spbSlower, spbFaster] then
            Game.SetSelectedSkill(i, True, (Button = mbRight))
          else begin
            if (i = spbPause) then
            begin
              if fGameWindow.GameSpeed = gspPause then
                fGameWindow.GameSpeed := gspNormal
              else
                fGameWindow.GameSpeed := gspPause;
            end else
              Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
          end;
        end else begin // need special handling
          case i of
            spbFastForward: case fGameWindow.GameSpeed of
                              gspNormal: fGameWindow.GameSpeed := gspFF;
                              gspFF: fGameWindow.GameSpeed := gspNormal;
                            end;
            spbRestart: fGameWindow.GotoSaveState(0, -1);
            spbBackOneFrame: if Button = mbLeft then
                             begin
                               fGameWindow.GotoSaveState(Game.CurrentIteration - 1);
                               fLastClickFrameskip := GetTickCount;
                             end else if Button = mbRight then
                               fGameWindow.GotoSaveState(Game.CurrentIteration - 17)
                             else if Button = mbMiddle then
                               fGameWindow.GotoSaveState(Game.CurrentIteration - 85);
            spbForwardOneFrame: if Button = mbLeft then
                                begin
                                  fGameWindow.SetForceUpdateOneFrame(True);
                                  fLastClickFrameskip := GetTickCount;
                                end else if Button = mbRight then
                                  fGameWindow.SetHyperSpeedTarget(Game.CurrentIteration + 17)
                                else if Button = mbMiddle then
                                  fGameWindow.SetHyperSpeedTarget(Game.CurrentIteration + 85);
            spbClearPhysics: fGameWindow.ClearPhysics := not fGameWindow.ClearPhysics;
            spbDirLeft: if fSelectDx = -1 then
                        begin
                          fSelectDx := 0;
                          DrawButtonSelector(spbDirLeft, false);
                        end else begin
                          fSelectDx := -1;
                          DrawButtonSelector(spbDirLeft, true);
                          DrawButtonSelector(spbDirRight, false);
                        end;
            spbDirRight: if fSelectDx = 1 then
                        begin
                          fSelectDx := 0;
                          DrawButtonSelector(spbDirRight, false);
                        end else begin
                          fSelectDx := 1;
                          DrawButtonSelector(spbDirLeft, false);
                          DrawButtonSelector(spbDirRight, true);
                        end;
            spbLoadReplay: fGameWindow.LoadReplay;
          end;
        end;
      Exit;
    end;
  end;

end;

procedure TSkillPanelToolbar.ImgMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := true;
  Game.HitTest;
  fGameWindow.SetCurrentCursor;

  MinimapScrollFreeze := false;
end;

procedure TSkillPanelToolbar.ImgMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
   Game.SetSelectedSkill(spbSlower, False);
   Game.SetSelectedSkill(spbFaster, False);
end;

procedure TSkillPanelToolbar.MinimapMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
  Mouse behaviour of toolbar.
  o Minimap scrolling
  o button clicks
-------------------------------------------------------------------------------}
var
  P: TPoint;
begin
  P := fMinimapImage.ControlToBitmap(Point(X, Y));
  P.X := P.X * 8;
  P.Y := P.Y * 8;
  fGameWindow.ApplyMouseTrap;

  fMinimapScrollFreeze := true;

  if Assigned(fOnMiniMapClick) then
    fOnMinimapClick(Self, P);
end;

procedure TSkillPanelToolbar.MinimapMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  P: TPoint;
begin
  if fGameWindow.DoSuspendCursor then Exit;

  Game.HitTestAutoFail := true;
  Game.HitTest;
  fGameWindow.SetCurrentCursor;

  if not fMinimapScrollFreeze then Exit;

  if ssLeft in Shift then
  begin
    P := fMinimapImage.ControlToBitmap(Point(X, Y));
    if not PtInRect(fMinimapImage.Bitmap.BoundsRect, P) then
    begin
      MinimapMouseUp(Sender, mbLeft, Shift, X, Y, Layer);
      Exit;
    end;

    P.X := P.X * 8;
    P.Y := P.Y * 8;
    if Assigned(fOnMiniMapClick) then
      fOnMinimapClick(Self, P);
  end;

end;

procedure TSkillPanelToolbar.MinimapMouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  fMinimapScrollFreeze := false;
  DrawMinimap;
end;





procedure TSkillPanelToolbar.SetButtonRects;
var
  R: TRect;
  iButton: TSkillPanelButton;
begin
  R := Rect(-1, -1, 0, 0); // exact position of first button

  for iButton := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    fButtonRects[iButton] := R;
  end;

  fButtonRects[spbSlower] := Rect(1, 16, 15, 38);
  fButtonRects[spbFaster] := Rect(17, 16, 31, 38);
  fButtonRects[spbPause]  := Rect(161, 16, 175, 38);
  fButtonRects[spbNuke]   := Rect(177, 16, 191, 38);

  R := Rect(193, 16, 207, 38);

  if not GameParams.CompactSkillPanel then
  begin
    for iButton := spbFastForward to High(TSkillPanelButton) do
    begin
      fButtonRects[iButton] := R;
      OffsetRect(R, 16, 0);
    end;

    fButtonRects[spbDirLeft].Bottom := fButtonRects[spbDirLeft].Bottom - 12;
    fButtonRects[spbDirRight] := fButtonRects[spbDirLeft];
    OffsetRect(fButtonRects[spbDirRight], 0, 12);
  end else
    fButtonRects[spbFastForward] := R; // others aren't used on compact panel

end;


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


procedure TSkillPanelToolbar.SetStyleAndGraph(const Value: TBaseDosLemmingStyle;
      aScale: Integer);
begin
  fImage.BeginUpdate;
  fStyle := Value;
  if fStyle <> nil then
  begin
    ReadBitmapFromStyle;
  end;

  fImage.ScaleMode := smScale;

  fMinimapImage.ScaleMode := smScale;
  fMinimapImage.BitmapAlign := baCustom;

  fImage.EndUpdate;
  fImage.Changed;
  Invalidate;
end;


procedure TSkillPanelToolbar.DrawMinimap;
var
  X, Y: Integer;
  OH, OV: Double;
  ViewRect: TRect;
  MMW, MMH: Integer;
begin
  if GameParams.CompactSkillPanel then
  begin
    MMW := COMPACT_MINIMAP_WIDTH;
    MMH := COMPACT_MINIMAP_HEIGHT;
  end else begin
    MMW := MINIMAP_WIDTH;
    MMH := MINIMAP_HEIGHT;
  end;

  // We want to add some space for when the viewport rect lies on the very edges
  fMinimapTemp.Width := fMinimap.Width + 2;
  fMinimapTemp.Height := fMinimap.Height + 2;
  fMinimapTemp.Clear(0);
  fMinimap.DrawTo(fMinimapTemp, 1, 1);

  if Parent <> nil then
  begin
    // We want topleft position for now, to draw the visible area frame
    X := -Round(fGameWindow.ScreenImage.OffsetHorz / fGameWindow.ScreenImage.Scale / 8);
    Y := -Round(fGameWindow.ScreenImage.OffsetVert / fGameWindow.ScreenImage.Scale / 8);

    ViewRect := Rect(0, 0, fDisplayWidth div 8 + 2, fDisplayHeight div 8 + 2);
    OffsetRect(ViewRect, X, Y);

    fMinimapTemp.FrameRectS(ViewRect, fRectColor);

    fMinimapImage.Bitmap.Assign(fMinimapTemp);

    if not fMinimapScrollFreeze then
    begin
      if fMinimapTemp.Width < MMW then
        OH := (((MMW - fMinimapTemp.Width) * fMinimapImage.Scale) / 2)
      else begin
        OH := fGameWindow.ScreenImage.OffsetHorz / fGameWindow.ScreenImage.Scale / 8;
        OH := OH + (MMW - RectWidth(ViewRect)) div 2;
        OH := OH * fMinimapImage.Scale;
        OH := Min(OH, 0);
        OH := Max(OH, -(fMinimapTemp.Width - MMW) * fMinimapImage.Scale);
      end;

      if fMinimapTemp.Height < MMH then
        OV := (((MMH - fMinimapTemp.Height) * fMinimapImage.Scale) / 2)
      else begin
        OV := fGameWindow.ScreenImage.OffsetVert / fGameWindow.ScreenImage.Scale / 8;
        OV := OV + (MMH - RectHeight(ViewRect)) div 2;
        OV := OV * fMinimapImage.Scale;
        OV := Min(OV, 0);
        OV := Max(OV, -(fMinimapTemp.Height - MMH) * fMinimapImage.Scale);
      end;

      fMinimapImage.OffsetHorz := OH;
      fMinimapImage.OffsetVert := OV;
    end;

    fMinimapImage.Changed;
  end;
end;

function TSkillPanelToolbar.GetButtonList: TStringArray;
var
  ButtonList: TStringArray;
  i : Integer;
begin
  if GameParams.CompactSkillPanel then
  begin
    SetLength(ButtonList, 13);
    ButtonList[0] := 'icon_rr_minus.png';
    ButtonList[1] := 'icon_rr_plus.png';
    for i := 2 to 9 do
      ButtonList[i] := 'empty_slot.png';
    ButtonList[10] := 'icon_pause.png';
    ButtonList[11] := 'icon_nuke.png';
    ButtonList[12] := 'icon_ff.png';
  end
  else
  begin
    SetLength(ButtonList, 19);
    ButtonList[0] := 'icon_rr_minus.png';
    ButtonList[1] := 'icon_rr_plus.png';
    for i := 2 to 9 do
      ButtonList[i] := 'empty_slot.png';
    ButtonList[10] := 'icon_pause.png';
    ButtonList[11] := 'icon_nuke.png';
    ButtonList[12] := 'icon_ff.png';
    ButtonList[13] := 'icon_restart.png';
    ButtonList[14] := 'icon_1fb.png';
    ButtonList[15] := 'icon_1ff.png';
    ButtonList[16] := 'icon_clearphysics.png';
    ButtonList[17] := 'icon_directional.png';
    ButtonList[18] := 'icon_load_replay.png';
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

