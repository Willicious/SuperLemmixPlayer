{$include lem_directives.inc}

unit GameWindow;

interface

uses
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, MMSystem, Forms, SysUtils, Dialogs, Math, ExtCtrls,
  GR32, GR32_Image, GR32_Layers,
  UMisc, UTools,
  LemCore, LemLevel, LemDosStyle, LemRendering, LemRenderHelpers,
  LemGame,
  GameControl, GameSkillPanel, GameBaseScreen;

type
  TGameScroll = (
    gsNone,
    gsRight,
    gsLeft,
    gsUp,
    gsDown
  );

  TGameWindow = class(TGameBaseScreen)
  private
    fRenderInterface: TRenderInterface;
    fRenderer: TRenderer;
    fNeedRedraw: Boolean;
    fNeedEndUpdate: Boolean;
    fNeedReset : Boolean;
    fMouseTrapped: Boolean;
    fSaveList: TLemmingGameSavedStateList;
    fLastReplayingIteration: Integer;
    fReplayKilled: Boolean;
  { game eventhandler}
    procedure Game_Finished(Sender: TObject);
  { self eventhandlers }
    procedure Form_Activate(Sender: TObject);
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Form_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  { app eventhandlers }
    procedure Application_Idle(Sender: TObject; var Done: Boolean);
  { gameimage eventhandlers }
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Img_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
  { skillpanel eventhandlers }
    procedure SkillPanel_MinimapClick(Sender: TObject; const P: TPoint);
  { internal }
    procedure CheckResetCursor;
    procedure CheckScroll;
    procedure AddSaveState;
    procedure GotoSaveState(aTargetIteration: Integer);
    procedure CheckAdjustReleaseRate;
    procedure LoadReplay;
    procedure SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
    procedure StartReplay;
    procedure StartReplay2(const aFileName: string);
    procedure InitializeCursor;
    procedure CheckShifts(Shift: TShiftState);
    procedure DoDraw;
  protected
    fGame                : TLemmingGame;      // reference to globalgame gamemechanics
    Img                  : TImage32;          // the image in which the level is drawn (reference to inherited ScreenImg!)
    SkillPanel           : TSkillPanelToolbar;// our good old dos skill panel
    fActivateCount       : Integer;           // used when activating the form
    ForceUpdateOneFrame  : Boolean;           // used when paused
    GameScroll           : TGameScroll;       // scrollmode
    GameVScroll          : TGameScroll;
    IdealFrameTimeMS     : Cardinal;          // normal frame speed in milliseconds
    IdealFrameTimeMSFast : Cardinal;          // fast forward framespeed in milliseconds
    IdealScrollTimeMS    : Cardinal;          // scroll speed in milliseconds
    PrevCallTime         : Cardinal;          // last time we did something in idle
    PrevScrollTime       : Cardinal;          // last time we scrolled in idle
    MouseClipRect        : TRect;             // we clip the mouse when there is more space
    CanPlay              : Boolean;           // use in idle en set to false whenever we don't want to play
    HCursor1             : HCURSOR;           // normal play cursor
    HCursor2             : HCURSOR;           // highlight play cursor
    LemCursorIconInfo    : TIconInfo;         // normal play cursor icon
    LemSelCursorIconInfo : TIconInfo;         // highlight play cursor icon
    MaxDisplayScale      : Integer;           // calculated in constructor
    DisplayScale         : Integer;           // what's the zoomfactor (mostly 2, 3 or 4)
    MinScroll            : Single;            // scroll boundary for image
    MaxScroll            : Single;            // scroll boundary for image
    MinVScroll           : Single;
    MaxVScroll           : Single;
    fSaveStateFrame      : Integer;      // list of savestates (only first is used)
    fLastNukeKeyTime     : Cardinal;
    fScrollSpeed         : Integer;
//    fSystemCursor        : Boolean;
  //  fMouseBmp            : TBitmap32;
//    fMouseLayer          : TBitmapLayer;
  { overridden}
    procedure PrepareGameParams(Params: TDosGameParams); override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
    procedure SaveShot;
  { internal properties }
    property Game: TLemmingGame read fGame;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyMouseTrap;
    //function CheckClickHighlight: Boolean; // for Skill Panel to use
    property HScroll: TGameScroll read GameScroll write GameScroll;
    property VScroll: TGameScroll read GameVScroll write GameVScroll;
    property GameParams; //need to promote for skill panel's use
  end;

implementation

uses FBaseDosForm;

{ TGameControllerForm }

//function TGameWindow.CheckClickHighlight: Boolean;
//begin
//  Result := GameParams.ClickHighlight;
//end;

procedure TGameWindow.ApplyMouseTrap;
begin
  fMouseTrapped := true;
  if (GameParams.ReplayCheckIndex <> -2) then Exit;
  ClipCursor(@MouseClipRect);
end;

procedure TGameWindow.Application_Idle(Sender: TObject; var Done: Boolean);
{-------------------------------------------------------------------------------
  • Main heartbeat of the program.
  • This method together with Game.UpdateLemmings() take care of most game-mechanics.
  • A bit problematic is the releaserate handling:
    if the game is paused it RR is handled here. if not it is handled by
    Game.UpdateLemmings().
-------------------------------------------------------------------------------}
var
  CurrTime: Cardinal;
  Fast, ForceOne, TimeForFrame, TimeForFastForwardFrame, TimeForScroll, Hyper, Pause: Boolean;
  DrawRect: TRect;
begin
  if not CanPlay or not Game.Playing or Game.GameFinished then
    Exit;

  // this makes sure this method is called very often :)
  Done := False;

  Pause := Game.Paused;
  Fast := Game.FastForward;
  ForceOne := ForceUpdateOneFrame;
  ForceUpdateOneFrame := False;
  CurrTime := TimeGetTime;
  TimeForFrame := CurrTime - PrevCallTime > IdealFrameTimeMS;
  TimeForFastForwardFrame := Fast and (CurrTime - PrevCallTime > IdealFrameTimeMSFast);
  TimeForScroll := CurrTime - PrevScrollTime > IdealScrollTimeMS;
  Hyper := Game.HyperSpeed;

  // relax CPU
  if not Hyper or Fast then
    Sleep(1);

  if ForceOne or Hyper or TimeForFastForwardFrame or TimeForFrame or TimeForScroll then
  begin
    Game.fAssignEnabled := true;
  //  PrevCallTime := CurrTime; --> line deleted and moved down

    // only in paused mode adjust RR. If not paused it's updated per frame.
    if Game.Paused then
      if (TimeForScroll and not Game.Replaying) or ForceOne then
        CheckAdjustReleaseRate;

    if TimeForScroll then
    begin
      PrevScrollTime := CurrTime;
      CheckScroll;
    end;

    //if ForceOne or not Game.Paused then THIS IS ORIGINAL BUT MAYBE WRONG
    if (TimeForFrame and not Pause)
    or (TimeForFastForwardFrame and not Pause)
    or (Forceone and Pause)
    or Hyper then
    begin
      PrevCallTime := CurrTime;
      Game.UpdateLemmings;
      if (Game.CurrentIteration mod 170 = 0) and (GameParams.ReplayCheckIndex = -2) then
      begin
        AddSaveState;
        fSaveList.TidyList(Game.CurrentIteration);
      end;
    end;

    if not Hyper then
    begin
      SkillPanel.RefreshInfo;
      SkillPanel.DrawMinimap(Game.Minimap);
      CheckResetCursor;
    end
    else begin
      if (Game.CurrentIteration >= Game.TargetIteration) and (GameParams.ReplayCheckIndex = -2) then
      begin
        Game.HyperSpeedEnd;
        SkillPanel.RefreshInfo;
        SkillPanel.DrawMinimap(Game.Minimap);
        CheckResetCursor;
      end;
    end;

    if (GameParams.ReplayCheckIndex <> -2) then
      if Game.Checkpass then
      begin
        Game.Finish;
      end else begin
        Game.TargetIteration := Game.CurrentIteration + 170; //keep it in hyperspeed mode
        if not Game.HyperSpeed then Game.HyperSpeedBegin;
        if Game.Replaying then
          fLastReplayingIteration := Game.CurrentIteration
        else if fLastReplayingIteration < Game.CurrentIteration - (5 * 60 * 17) then
        begin
          fReplayKilled := true;
          Game.Finish;
        end;
      end;

  end;

  // Update drawing
  if (TimeForFrame or TimeForFastForwardFrame or fNeedRedraw) and not Game.HyperSpeed then
  begin
    DoDraw;
  end;
end;

procedure TGameWindow.DoDraw;
var
  DrawRect: TRect;
begin
  fRenderInterface.ScreenPos := Point(Trunc(Img.OffsetHorz / DisplayScale) * -1, Trunc(Img.OffsetVert / DisplayScale) * -1);
  fRenderInterface.MousePos := Game.CursorPoint;
  fRenderer.DrawAllObjects;
  fRenderer.DrawLemmings;
  DrawRect := Rect(fRenderInterface.ScreenPos.X, fRenderInterface.ScreenPos.Y, fRenderInterface.ScreenPos.X + 319, fRenderInterface.ScreenPos.Y + 159);
  fRenderer.DrawLevel(GameParams.TargetBitmap, DrawRect);
  fNeedRedraw := false;
end;

procedure TGameWindow.CheckShifts(Shift: TShiftState);
var
  SDir: Integer;
begin
  //if GameParams.CtrlHighlight then
    {begin
      Game.RightMouseButtonHeldDown := ssRight in Shift;
      Game.CtrlButtonHeldDown := GameParams.Hotkeys.CheckForKey(lka_ForceWalker);
    end else begin}
      Game.RightMouseButtonHeldDown := GameParams.Hotkeys.CheckForKey(lka_ForceWalker);
      Game.CtrlButtonHeldDown := GameParams.Hotkeys.CheckForKey(lka_Highlight); {ssRight in Shift;}
    //end;
  Game.ShiftButtonHeldDown := GameParams.Hotkeys.CheckForKey(lka_SelectNewLem);
  Game.AltButtonHeldDown := GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo);

  SDir := 0;
  if GameParams.Hotkeys.CheckForKey(lka_DirLeft) then SDir := SDir - 1;
  if GameParams.Hotkeys.CheckForKey(lka_DirRight) then SDir := SDir + 1; // These two cancel each other out if both are pressed. Genius. :D
  Game.fSelectDx := SDir;  
end;

procedure TGameWindow.GotoSaveState(aTargetIteration: Integer);
{-------------------------------------------------------------------------------
  Go in hyperspeed from the beginning to aTargetIteration
-------------------------------------------------------------------------------}
var
  CurrentlyPaused: Boolean;
  UseSaveState: Integer;
  i: Integer;
begin
  //if aTargetIteration < 0 then Exit;
  CanPlay := False;
  CurrentlyPaused := Game.Paused;
  if aTargetIteration > 0 then
    UseSaveState := fSaveList.FindNearestState(aTargetIteration)
  else if fSaveList.Count = 0 then
    UseSaveState := -1
  else
    UseSaveState := 0;
  for i := UseSaveState downto -1 do
    if i >= 0 then
    begin
      if Game.LoadSavedState(fSaveList[i], true) then
        Break
      else
        fSaveList.Delete(i);
    end else
      Game.Start(true);
  fSaveList.ClearAfterIteration(aTargetIteration);
  Game.HyperSpeedBegin(CurrentlyPaused);
  Game.TargetIteration := aTargetIteration;
  CanPlay := True;
end;

procedure TGameWindow.CheckResetCursor;
begin
  if FindControl(GetForegroundWindow()) = nil then
  begin
    fNeedReset := true;
    exit;
  end;
  if Screen.Cursor <> Game.CurrentCursor then
  begin
    Img.Cursor := Game.CurrentCursor;
    Screen.Cursor := Game.CurrentCursor;
  end;
  if fNeedReset and fMouseTrapped then
  begin
    ApplyMouseTrap;
    fNeedReset := false;
  end;
  {if ** need proper clip check here**
  begin
    ClipCursor(@MouseClipRect);
  end;}
end;

procedure TGameWindow.CheckScroll;
  procedure Scroll(dx, dy: Integer);
  begin
    Img.OffsetHorz := Img.OffsetHorz - DisplayScale * dx * fScrollSpeed;
    Img.OffsetVert := Img.OffsetVert - DisplayScale * dy * fScrollSpeed;
    Img.OffsetHorz := Max(MinScroll * DisplayScale, Img.OffsetHorz);
    Img.OffsetHorz := Min(MaxScroll * DisplayScale, Img.OffsetHorz);
    Img.OffsetVert := Max(MinVScroll * DisplayScale, Img.OffsetVert);
    Img.OffsetVert := Min(MaxVScroll * DisplayScale, Img.OffsetVert);
  end;
begin
  Img.BeginUpdate;
  case GameScroll of
    gsRight:
      Scroll(8, 0);
    gsLeft:
      Scroll(-8, 0);
  end;
  case GameVScroll of
    gsUp:
      Scroll(0, -8);
    gsDown:
      Scroll(0, 8);
  end;

  DoDraw;
  Img.EndUpdate;

end;

constructor TGameWindow.Create(aOwner: TComponent);
var
  HScale, VScale: Integer;
begin
  inherited Create(aOwner);

  fNeedReset := true;

  // create game
  fGame := GlobalGame; // set ref to GlobalGame
  fGame.OnFinish := Game_Finished;
  fScrollSpeed := 1;

  fSaveStateFrame := -1;

  Img := ScreenImg; // set ref to inherited screenimg (just for a short name)
  Img.RepaintMode := rmOptimizer;
  Img.Color := clNone;
  Img.BitmapAlign := baCustom;
  Img.ScaleMode := smScale;

//  fMouseBmp := TBitmap32.create;

  // create toolbar
  SkillPanel := TSkillPanelToolbar.Create(Self);
  SkillPanel.Parent := Self;

//  IdealFrameTimeMS := 60;
//  IdealFrameTimeMSFast := 0;
//  IdealScrollTimeMS := 60;

  // calculate displayscale
  // This gets overridden later in windowed mode but is important for fullscreen.
  HScale := Screen.Width div 320;
  VScale := Screen.Height div 200;
  DisplayScale := HScale;
  if VScale < HScale then
    DisplayScale := VScale;
  MaxDisplayScale := DisplayScale;

  Self.KeyPreview := True;

  // set eventhandlers
  Self.OnActivate := Form_Activate;
  Self.OnKeyDown := Form_KeyDown;
  Self.OnKeyUp := Form_KeyUp;
  Self.OnKeyPress := Form_KeyPress;
  Self.OnMouseMove := Form_MouseMove;
  Self.OnMouseUp := Form_MouseUp;

  Img.OnMouseDown := Img_MouseDown;
  Img.OnMouseMove := Img_MouseMove;
  Img.OnMouseUp := Img_MouseUp;

  SkillPanel.Game := fGame; // this links the game to the infopainter interface as well
  SkillPanel.OnMinimapClick := SkillPanel_MinimapClick;
  Application.OnIdle := Application_Idle;

  fSaveList := TLemmingGameSavedStateList.Create(true);

  fReplayKilled := false;

end;

destructor TGameWindow.Destroy;
begin
  CanPlay := False;
  Application.OnIdle := nil;
  if SkillPanel <> nil then
    SkillPanel.Game := nil;
  if HCursor1 <> 0 then
    DestroyIcon(HCursor1);
  if HCursor2 <> 0 then
    DestroyIcon(HCursor2);
//  if fMouseBmp <> nil then
  //  fMouseBmp.Free;
  fSaveList.Free;
  inherited Destroy;
end;

procedure TGameWindow.Form_Activate(Sender: TObject);
// activation eventhandler
begin
  if fActivateCount = 0 then
  begin
    fGame.Start;
    fGame.CreateSavedState(fSaveList.Add); 
    CanPlay := True;
  end;
  Inc(fActivateCount);

  if GameParams.ReplayCheckIndex <> -2 then
  begin
    StartReplay2(GameParams.ReplayResultList[GameParams.ReplayCheckIndex]);
    Game.TargetIteration := 170;
    Game.HyperSpeedBegin;
  end;
end;

procedure TGameWindow.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CurrTime: Cardinal;
  sn: Integer;
  func: TLemmixHotkey;
const
  NON_CANCELLING_KEYS = [lka_Null,
                         lka_SelectNewLem,
                         lka_ShowAthleteInfo,
                         lka_Exit,
                         lka_Pause,
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
                         lka_CancelReplay,  // this one does cancel. but the code should show why it's in this list. :)
                         lka_Music,
                         lka_Sound,
                         lka_Restart,
                         lka_ReleaseMouse,
                         lka_Nuke];         // nuke also cancels, but requires double-press to do so so handled elsewhere
  SKILL_KEYS = [lka_Skill, lka_SkillLeft, lka_SkillRight];
begin
  func := GameParams.Hotkeys.CheckKeyEffect(Key);

  if func.Action = lka_Exit then
  begin
    Game.Finish; // OnFinish eventhandler does the rest
  end;

  if not Game.Playing then
    Exit;

  // this is quite important: no gamecontrol if going fast
  if Game.HyperSpeed then
     Exit;

  if ((func.Action in NON_CANCELLING_KEYS) or ((func.Action in SKILL_KEYS) and GameParams.IgnoreReplaySelection))
  or (not Game.Replaying)
  or (not GameParams.ExplicitCancel) then
    with Game do
    begin

        if (func.Action in [lka_CancelReplay, lka_ReleaseRateUp, lka_ReleaseRateDown, lka_SkillLeft, lka_SkillRight])
        or ((func.Action in SKILL_KEYS) and not GameParams.IgnoreReplaySelection) then
          Game.RegainControl; // for keys that interrupt replays inherently. Note that some others might have their own
                              // handling for it, instead of using this always-on one

        if func.Action = lka_Skill then
        begin
            case func.Modifier of
              0: SetSelectedSkill(spbWalker, True);
              1: SetSelectedSkill(spbClimber, True);
              2: SetSelectedSkill(spbSwimmer, True);
              3: SetSelectedSkill(spbUmbrella, True);
              4: SetSelectedSkill(spbGlider, True);
              5: SetSelectedSkill(spbMechanic, True);
              6: SetSelectedSkill(spbExplode, True);
              7: SetSelectedSkill(spbStoner, True);
              8: SetSelectedSkill(spbBlocker, True);
              9: SetSelectedSkill(spbPlatformer, True);
              10: SetSelectedSkill(spbBuilder, True);
              11: SetSelectedSkill(spbStacker, True);
              12: SetSelectedSkill(spbBasher, True);
              13: SetSelectedSkill(spbMiner, True);
              14: SetSelectedSkill(spbDigger, True);
              15: SetSelectedSkill(spbCloner, True);
            end
        end;

        case func.Action of
          lka_ReleaseMouse: if GameParams.ZoomLevel <> 0 then
                            begin
                              fMouseTrapped := false;
                              ClipCursor(nil);
                            end;
          lka_ReleaseRateDown: SetSelectedSkill(spbSlower, True);
          lka_ReleaseRateUp: SetSelectedSkill(spbFaster, True);
          lka_Pause: SetSelectedSkill(spbPause);
          lka_Nuke: begin
                      // double keypress needed to prevent accidently nuking
                      CurrTime := TimeGetTime;
                      if CurrTime - fLastNukeKeyTime < 250 then
                      begin
                        RegainControl;
                        SetSelectedSkill(spbNuke)
                      end else
                        fLastNukeKeyTime := CurrTime;
                    end;
          lka_SaveState : fSaveStateFrame := fGame.CurrentIteration;
          lka_LoadState : begin
                            GotoSaveState(fSaveStateFrame);
                            if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                          end;
          lka_Cheat: Game.Cheat;
          lka_FastForward: if not Paused then FastForward := not FastForward;
          lka_SaveImage: SaveShot;
          lka_LoadReplay: LoadReplay;
          lka_Music: if gsoMusic in SoundOpts then
                     begin
                       SoundOpts := SoundOpts - [gsoMusic];
                       GameParams.MusicEnabled := false;
                     end else begin
                       SoundOpts := SoundOpts + [gsoMusic];
                       GameParams.MusicEnabled := true;
                     end;
          lka_Restart: begin
                         Game.Paused := false;          
                         GotoSaveState(0);
                         if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                       end;
          lka_Sound: if gsoSound in SoundOpts then
                     begin
                       SoundOpts := SoundOpts - [gsoSound];
                       GameParams.SoundEnabled := false;
                     end else begin
                       SoundOpts := SoundOpts + [gsoSound];
                       GameParams.SoundEnabled := true;
                     end;
          lka_SaveReplay: Save;
          lka_SkillRight: begin
                            sn := GetSelectedSkill;
                            if (sn < 7) and (fActiveSkills[sn + 1] <> spbNone) then
                            begin
                              //RegainControl;
                              SetSelectedSkill(fActiveSkills[sn + 1]);
                            end;
                          end;
          lka_SkillLeft:  begin
                            sn := GetSelectedSkill;
                            if (sn > 0) and (fActiveSkills[sn - 1] <> spbNone) and (sn <> 8) then
                            begin
                              //RegainControl;
                              SetSelectedSkill(fActiveSkills[sn - 1]);
                            end;
                          end;
          lka_Skip: if Game.Playing then
                      if func.Modifier < 0 then
                      begin
                        if CurrentIteration > (func.Modifier * -1) then
                          GotoSaveState((CurrentIteration + func.Modifier) - 1)
                        else
                          GotoSaveState(0);
                        if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                      end else if func.Modifier > 1 then
                      begin
                        HyperSpeedBegin;
                        TargetIteration := CurrentIteration + func.Modifier;
                      end else
                        if Paused then ForceUpdateOneFrame := true;
        end;

    end;

  CheckShifts(Shift);

  if Game.Paused and not Game.HyperSpeed then
    DoDraw;
end;

procedure TGameWindow.Form_KeyPress(Sender: TObject; var Key: Char);
var
  sn : Integer;
begin

end;

procedure TGameWindow.Form_KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  func: TLemmixHotkey;
begin
  func := GameParams.Hotkeys.CheckKeyEffect(Key);

  if not Game.Playing then
    Exit;

  with Game do
  begin

    case func.Action of
      lka_ReleaseRateDown    : SetSelectedSkill(spbSlower, False);
      lka_ReleaseRateUp      : SetSelectedSkill(spbFaster, False);
    end;
  end;

  CheckShifts(Shift);

end;

procedure TGameWindow.SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
{-------------------------------------------------------------------------------
  convert the normal hotspot to the hotspot the game uses (4,9 instead of 7,7)
-------------------------------------------------------------------------------}
begin
  Game.CursorPoint := Point(BitmapPoint.X - 3, BitmapPoint.Y + 2);
end;

procedure TGameWindow.Img_MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
  mouse handling of the game
-------------------------------------------------------------------------------}

var
  HandleClick: Boolean;
  PassKey: Word;
begin
  if not fMouseTrapped then
    ApplyMouseTrap;
  // interrupting hyperspeed can break the handling of savestates
  // so we're not allowing it
  if Game.Playing and not Game.HyperSpeed then
  begin
    //Game.RegainControl;

    SetAdjustedGameCursorPoint(Img.ControlToBitmap(Point(X, Y)));

    CheckShifts(Shift);

    // Middle or Right clicks get passed to the keyboard handler, because their
    // handling has more in common with that than with mouse handling
    PassKey := 0;
    if (Button = mbMiddle) then
      PassKey := $04
    else if (Button = mbRight) then
      PassKey := $02;
    if PassKey <> 0 then
      Form_KeyDown(Sender, PassKey, Shift);
    if (Button <> mbLeft) and not (GameParams.ClickHighlight) then Exit;

    if (Button = mbLeft) and (not Game.CtrlButtonHeldDown)
    and not (Game.Replaying and GameParams.ExplicitCancel) then
    begin
      Game.RegainControl;
      HandleClick := true; //{not Game.Paused and} not Game.FastForward{ or UseClicksWhenPaused};
      if HandleClick then
      begin
        if Game.fAssignEnabled then
        Game.ProcessSkillAssignment;
        if Game.Paused then
            ForceUpdateOneFrame := True;
      end;
    end;

    if Game.CtrlButtonHeldDown then
    begin
      HandleClick := true; //not Game.FastForward;
      if HandleClick and Game.fAssignEnabled then
        Game.ProcessHighlightAssignment;
    end;

    if Game.Paused then
      DoDraw;

  end;
end;

procedure TGameWindow.Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Game.Playing then
  begin
    CheckShifts(Shift);
(*    if ssRight in Shift then
      fScrollSpeed := 2
    else
      fScrollSpeed := 1; *)

    SetAdjustedGameCursorPoint(Img.ControlToBitmap(Point(X, Y)));
    //Game.CursorPoint := Img.ControlToBitmap(Point(X, Y));

    //if (Y >= SkillPanel.Top) then Game.HitTestAutoFail := 1
    //else if Game.HitTestAutoFail = 1 then Game.HitTestAutoFail := 2;

    //Game.HitTestAutoFail := (Y >= SkillPanel.Top);

    if (Game.Paused) or (Game.HitTestAutoFail) then
    begin
      CheckResetCursor;
      Game.HitTest;
    end;

    Game.HitTestAutoFail := (Y >= SkillPanel.Top);

    if X >= Img.Width - 1 then
      GameScroll := gsRight
    else if X <= 0 then
      GameScroll := gsLeft
    else
      GameScroll := gsNone;

    {if Y >= Img.Height - 1 then
      GameVScroll := gsDown
    else} if Y <= 0 then
      GameVScroll := gsUp
    else
      GameVScroll := gsNone;

    if Game.Paused then
      DoDraw;
  end;

end;

procedure TGameWindow.Img_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  CheckShifts(Shift);
end;

procedure TGameWindow.InitializeCursor;
const
  PLAYCURSOR_DEFAULT = 1;
  PLAYCURSOR_LEMMING = 2;
var
  bmpMask : TBitmap;
  bmpColor : TBitmap;

    procedure scalebmp(bmp:tbitmap; ascale:integer);
    var                         //bad code but it works for now
      b: tbitmap32;
      src,dst:trect;

    begin
      if ascale=1 then exit;
      b:=tbitmap32.create;
      src:=rect(0,0,bmp.width,bmp.height);
      dst:=rect(0,0,bmp.width * ascale, bmp.height*ascale);
      b.setsize(bmp.width*ascale, bmp.height*ascale);
      b.Draw(dst,src, bmp.canvas.handle);
      bmp.Width := b.width;
      bmp.height:=b.height;
      b.drawto(bmp.canvas.handle, 0, 0);// gr32
      b.free;
    end;


begin
  bmpMask := TBitmap.Create;
  bmpColor := TBitmap.Create;

  bmpMask.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_DEFAULT_MASK');
  bmpColor.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_DEFAULT');
//  bmpcolor.canvas.pixels[3,8]:=clred;

  ScaleBmp(bmpMask, DisplayScale);
  ScaleBmp(bmpColor, DisplayScale);

  (*
  if not fSystemCursor then
  begin
    fMouseBmp.Assign(bmpColor);
    fMouseBmp.DrawMode := dmTransparent;
    fMouseLayer := TBitmapLayer.Create(Img.Layers);
    fMouseLayer.LayerOptions := LOB_VISIBLE;
    fMouseLayer.Location := FloatRect(0, 0, fMouseBmp.Width, fMouseBmp.Height)
  end;     *)

  with LemCursorIconInfo do
  begin
    fIcon := false;
    xHotspot := 7 * DisplayScale; //4 * displayscale;//7 * DisplayScale;//bmpmask.width div 2+displayscale;
    yHotspot := 7 * DisplayScale; //9 * displayscale;//7 * DisplayScale;//bmpmask.Height div 2+displayscale;
    hbmMask := bmpMask.Handle;
    hbmColor := bmpColor.Handle;
  end;

  HCursor1 := CreateIconIndirect(LemCursorIconInfo);
  Screen.Cursors[PLAYCURSOR_DEFAULT] := HCursor1;

  img.Cursor := PLAYCURSOR_DEFAULT;
  SkillPanel.img.cursor := PLAYCURSOR_DEFAULT;
  Self.Cursor := PLAYCURSOR_DEFAULT;

  bmpMask.Free;
  bmpColor.Free;

  //////////

  bmpMask := TBitmap.Create;
  bmpColor := TBitmap.Create;

  bmpMask.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_HIGHLIGHT_MASK');
  bmpColor.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_HIGHLIGHT');

  scalebmp(bmpmask, DisplayScale);
  scalebmp(bmpcolor, DisplayScale);


  with LemSelCursorIconInfo do
  begin
    fIcon := false;
    xHotspot := 7 * DisplayScale; //4 * DisplayScale;//}bmpmask.width div 2+displayscale;
    yHotspot := 7 * DisplayScale; //9 * DisplayScale;//}bmpmask.Height div 2+displayscale;
//    xHotspot := 7 * 3;////5;
//    yHotspot := 7 * 3;//15;
    hbmMask := bmpMask.Handle;
    hbmColor := bmpColor.Handle;
  end;

  HCursor2 := CreateIconIndirect(LemSelCursorIconInfo);
  Screen.Cursors[PLAYCURSOR_LEMMING] := HCursor2;

//  Screen.Cursor := MyCursor;
//  Self.Cursor := HCursor1;

  bmpMask.Free;
  bmpColor.Free;
end;


procedure TGameWindow.PrepareGameParams(Params: TDosGameParams);
{-------------------------------------------------------------------------------
  This method is called by the inherited ShowScreen
-------------------------------------------------------------------------------}
var
  HScale, VScale: Integer;
  Sca: Integer;
  StoredScale: Integer; // scale as stored in ini-file
  CenterPoint: TPoint;
begin
  inherited;
  StoredScale := 0;
//  fSystemCursor := GameParams.UseSystemCursor;

  // set the final displayscale
  if GameParams.ZoomLevel = 0 then
    Sca := DisplayScale
  else begin
    Sca := GameParams.ZoomLevel;
    DisplayScale := Sca;
  end;

  {Sca := MaxDisplayScale;
  if (StoredScale > 0) and (StoredScale <= MaxDisplayScale) then
  begin
     Sca := StoredScale;
     DisplayScale := Sca;
  end;}

  // correct if wrong zoomfactor in inifile
//  if (StoredScale <> 0) and (StoredScale > MaxDisplayScale) then
 //   Params.ZoomFactor := Sca;

  GameParams.TargetBitmap := Img.Bitmap;
  fGame.PrepareParams(Params);

  // set timers
  IdealFrameTimeMSFast := 10;
  IdealScrollTimeMS := 60;
  IdealFrameTimeMS := 60;

  Img.Width := 320 * Sca;
  Img.Height := 160 * Sca;
  Img.Scale := Sca;
  Img.OffsetHorz := -GameParams.Level.Info.ScreenPosition * Sca;
  Img.OffsetVert := -GameParams.Level.Info.ScreenYPosition * Sca;
  if GameParams.ZoomLevel = 0 then
  begin
    Img.Left := (Screen.Width - Img.Width) div 2;
    Img.Top := (Screen.Height - 200 * Sca) div 2;
  end else begin
    Img.Left := 0;
    Img.Top := 0;
  end;

  SkillPanel.Top := Img.Top + Img.Height;
  SkillPanel.left := Img.Left;
  SkillPanel.Width := Img.Width;
  SkillPanel.Height := 40 * Sca;

  if GameParams.ZoomLevel = 0 then
    MouseClipRect := Rect(Img.Left, Img.Top, Img.Left + Img.Width,
                          SkillPanel.Top + SkillPanel.Height)
  else
    MouseClipRect := Rect(ClientToScreen(Point(0, 0)), ClientToScreen(Point(Img.Width, Img.Height + SkillPanel.Height)));

  SkillPanel.GameParams := GameParams;
  SkillPanel.SetStyleAndGraph(Gameparams.Style, Sca);

  SkillPanel.Level := GameParams.Level;
  SkillPanel.SetSkillIcons;

  MinScroll := -(GameParams.Level.Info.Width - 320);
  MaxScroll := 0;

  MinVScroll := -(GameParams.Level.Info.Height - 160);
  MaxVScroll := 0;

  InitializeCursor;
  CenterPoint := ClientToScreen(Point(Width div 2, Height div 2));
  if (GameParams.ReplayCheckIndex = -2) then
    SetCursorPos(CenterPoint.X, CenterPoint.Y);
  ApplyMouseTrap;

  if ((Params.SysDat.Options2 and $4) <> 0) then SkillPanel.ActivateCenterDigits;

  fRenderer := Params.Renderer;
  fRenderInterface := Game.RenderInterface;
  fRenderer.SetInterface(fRenderInterface);

end;

procedure TGameWindow.SkillPanel_MinimapClick(Sender: TObject; const P: TPoint);
{-------------------------------------------------------------------------------
  This method is an eventhandler (TSkillPanel.OnMiniMapClick),
  called when user clicks in the minimap-area of the skillpanel.
  Here we scroll the game-image.
-------------------------------------------------------------------------------}
var
//  N: TPoint;
  O: Single;
begin
//  Game.CurrentScreenPosition := Point(P.X, 0);
  O := -P.X * DisplayScale;
  O :=  O + Img.Width div 2;
  {if Game.Level.Info.Width < 1664 then
  begin
  end else begin
  end;}
  if O < MinScroll * DisplayScale then O := MinScroll * DisplayScale;
  if O > MaxScroll * DisplayScale then O := MaxScroll * DisplayScale;
  Img.OffSetHorz := O;
  O := (P.Y - 60) div 4;
  O := -P.Y * DisplayScale;
  O :=  O + Img.Height div 2;
  if O < MinVScroll * DisplayScale then O := MinVScroll * DisplayScale;
  if O > MaxVScroll * DisplayScale then O := MaxVScroll * DisplayScale;
  Img.OffsetVert := O;
  DoDraw;
end;



procedure TGameWindow.Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  with MouseClipRect do
  begin
    if (Y >= Img.Top) and (Y <= Img.Top + Img.Height - 1) then
    begin
      if X <= Img.Left + DisplayScale then
        GameScroll := gsLeft
      else if X >= Img.Left + Img.Width - 1 + DisplayScale then
        GameScroll := gsRight
      else
        GameScroll := gsNone;
    end
    else
      GameScroll := gsNone;
  end;

end;

procedure TGameWindow.Form_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  GameScroll := gsNone;
end;

procedure TGameWindow.CheckAdjustReleaseRate;
{-------------------------------------------------------------------------------
  In the mainloop the decision is made if we really have to update
-------------------------------------------------------------------------------}
begin
  with Game do
  begin
    if SpeedingUpReleaseRate then
    begin
//        if not (Replaying and Paused) then
      AdjustReleaseRate(1);
      if InstReleaseRate = 1 then AdjustReleaseRate(100);
      InstReleaseRate := 0;
    end
    else if SlowingDownReleaseRate then
    begin
//      if not (Replaying and Paused) then
      AdjustReleaseRate(-1);
      if InstReleaseRate = -1 then AdjustReleaseRate(-100);
      InstReleaseRate := 0;
    end;
  end;
end;

procedure TGameWindow.StartReplay;
begin
  CanPlay := False;
  Game.SetGameResult;
  Game.Start(True);
  SkillPanel.RefreshInfo;
  CanPlay := True;
end;

procedure TGameWindow.StartReplay2(const aFileName: string);
var
  ext: String;
begin
  CanPlay := False;
  ext := Lowercase(ExtractFileExt(aFilename));
  if ext = '.nxrp' then
    Game.ReplayManager.LoadFromFile(aFilename)
  else if ext = '.lrb' then
    Game.ReplayManager.LoadFromFile(aFilename)
  else
    try
      Game.ReplayManager.LoadFromFile(aFilename);
    except
      Game.ReplayManager.LoadOldReplayFile(aFilename);
    end;

  Game.Paused := False;
  GotoSaveState(0);
  //Game.Start(True);
  //SkillPanel.RefreshInfo;
  CanPlay := True;
end;


procedure TGameWindow.LoadReplay;
var
  OldCanPlay: Boolean;
  IsOld: Boolean;
  Dlg : TOpenDialog;
  s: string;
begin
  OldCanPlay := CanPlay;
  CanPlay := False;
  s:='';
  dlg:=topendialog.create(nil);
  try
//    dlg.DefaultExt := '*.lrb';
    dlg.Filter := 'NeoLemmix Replay (*.nxrp)|*.nxrp|Old NeoLemmix Replay (*.lrb)|*.lrb';
    dlg.FilterIndex := 1;
    if Game.LastReplayDir = '' then
    begin
      dlg.InitialDir := ExtractFilePath(ParamStr(0)) + 'Replay\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\';
      if not DirectoryExists(dlg.InitialDir) then
        dlg.InitialDir := ExtractFilePath(ParamStr(0)) + 'Replay\';
      if not DirectoryExists(dlg.InitialDir) then
        dlg.InitialDir := ExtractFilePath(ParamStr(0));
    end else
      dlg.InitialDir := Game.LastReplayDir;
    dlg.Options := [ofFileMustExist, ofHideReadOnly];
    if dlg.execute then
    begin
      s:=dlg.filename;
      Game.LastReplayDir := ExtractFilePath(s);
    end;
  finally
    dlg.free;
  end;
  if s <> '' then
  begin
    StartReplay2(s);
    exit;
  end;
  CanPlay := OldCanPlay;
end;

procedure TGameWindow.SaveShot;
var
  Dlg : TSaveDialog;
  SaveName: String;
begin
  Dlg := TSaveDialog.Create(self);
  dlg.Filter := 'PNG Image (*.png)|*.png';
  dlg.FilterIndex := 1;
  dlg.InitialDir := '"' + ExtractFilePath(Application.ExeName) + '/"';
  dlg.DefaultExt := '.png';
  if dlg.Execute then
  begin
    SaveName := dlg.FileName;
    Game.SaveGameplayImage(SaveName); 
  end;
  Dlg.Free;
end;


procedure TGameWindow.Game_Finished(Sender: TObject);
var
  s: String;
begin
  if (GameParams.ReplayCheckIndex <> -2) then
  begin
    s := ExtractFileName(GameParams.ReplayResultList[GameParams.ReplayCheckIndex]) + ': ';
    if Game.CheckPass then
      s := s + 'PASSED'
    else if fReplayKilled then
      s := s + 'UNDETERMINED'
    else
      s := s + 'FAILED';
    GameParams.ReplayResultList[GameParams.ReplayCheckIndex] := s;
    CloseScreen(gstPreview);
  end;

  if (GameParams.fTestMode and (GameParams.QuickTestMode in [2, 3])) then
  begin
    if GameParams.QuickTestMode = 3 then Game.Save(true);
    CloseScreen(gstExit)
  end else
  begin
    GameParams.NextScreen2 := gstPostview;
    if Game.CheckPass then
      CloseScreen(gstText)
      else
      CloseScreen(gstPostview);
  end;
end;

procedure TGameWindow.CloseScreen(aNextScreen: TGameScreenType);
begin
  CanPlay := False;
  Application.OnIdle := nil;
  ClipCursor(nil);
  Cursor := crNone;
//  GameParams.NextScreen := gstPostview;
  Game.SetGameResult;
  GameParams.GameResult := Game.GameResultRec;
  with GameParams, GameResult do
  begin
    if (gSuccess or gCheated) and (not GameParams.fTestMode) then
      WhichLevel := wlNext;
  end;
  Img.RepaintMode := rmFull;

  inherited CloseScreen(aNextScreen);
end;

procedure TGameWindow.AddSaveState;
begin
  fGame.CreateSavedState(fSaveList.Add);
end;

{procedure TGameWindow.NextSaveState(Forwards: Boolean);
begin
  if fSaveStateFrame = -1 then Exit;
  fGame.LoadSavedState(fTestSave); 
end;}

end.

