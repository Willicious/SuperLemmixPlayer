{$include lem_directives.inc}

unit GameWindow;

interface

uses
  System.Types, Generics.Collections,
  PngInterface,
  LemmixHotkeys,
  Windows, Classes, Controls, Graphics, MMSystem, Forms, SysUtils, Dialogs, Math, ExtCtrls, StrUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  LemCore, LemLevel, LemRendering, LemRenderHelpers,
  LemGame, LemGameMessageQueue,
  GameSound, LemTypes, LemStrings, LemLemming,
  LemCursor,
  GameControl, GameBaseSkillPanel, GameSkillPanel, GameBaseScreenCommon,
  GameWindowInterface,
  SharedGlobals;

type
  // For TGameSpeed see unit GameWindowInterface

  TGameScroll = (
    gsNone,
    gsRight,
    gsLeft,
    gsUp,
    gsDown
  );

  TRedrawOption = (
   rdNone,    // No forced redraw is needed
   rdRefresh, // Needs to update (eg. from scrolling) but not fully redrawn
   rdRedraw   // Needs to redraw completely
  );

  THoldScrollData = record
    Active: Boolean;
    StartCursor: TPoint;
    //StartImg: TFloatPoint;
  end;

  TSuspendState = record
    OldSpeed: TGameSpeed;
    OldCanPlay: Boolean;
  end;

const
  CURSOR_TYPES = 24;

  // Special hyperspeed ends. usually only needed for forwards ones, backwards can often get the exact frame.
  SHE_SHRUGGER = 1;
  SHE_HIGHLIT = 2;

  SPECIAL_SKIP_MAX_DURATION = 17 * 60 * 2; // 2 minutes should be plenty.

  MAX_WIDTH_FOR_HQMAP = 1600;
  MAX_HEIGHT_FOR_HQMAP = 640;

type
  TGameWindow = class(TGameBaseScreen, IGameWindow)
  private
    fRanOneUpdate: Boolean;
    fSaveStateReplayStream: TMemoryStream;
    fCloseToScreen: TGameScreenType;
    fSuspendCursor: Boolean;
    fClearPhysics: Boolean;
    fProjectionType: Integer;
    fLastProjectionType: Integer;
    fRenderInterface: TRenderInterface;
    fRenderer: TRenderer;
    fNeedResetMouseTrap : Boolean;
    fMouseTrapped: Boolean;
    fSaveList: TLemmingGameSavedStateList;
    fReplayKilled: Boolean;

    fInternalZoom: Integer;
    fMaxZoom: Integer;
    fMinimapBuffer: TBitmap32;

  { detecting if redraw is needed. These are a bit kludgy but I'm strongly considering a full rewrite of TGameWindow }
    fNeedRedraw: TRedrawOption;
    fLastSelectedLemming: TLemming;
    fLastHighlightLemming: TLemming;
    fLastSelectedSkill: TSkillPanelButton;
    fLastHelperIcon: THelperIcon;
    fLastDrawPaused: Boolean;

  { current gameplay }
    fGameSpeed: TGameSpeed;               // Do NOT set directly, set via GameSpeed property
    fSpecialStartIteration: Integer;
    fHyperSpeedStopCondition: Integer;
    fHighlitStartCopyLemming: TLemming;
    fHyperSpeedTarget: Integer;
    fForceUpdateOneFrame: Boolean;        // Used when paused

    fHoldScrollData: THoldScrollData;

    fSuspensions: TList<TSuspendState>;
    HotkeyManager: TLemmixHotkeyManager;

  { game eventhandler}
    procedure Game_Finished;
  { Self eventhandlers }
    procedure Form_Activate(Sender: TObject);
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Form_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Form_MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  { app eventhandlers }
    procedure Application_Idle(Sender: TObject; var Done: Boolean);
  { gameimage eventhandlers }
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Img_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
  { skillpanel eventhandlers }
    procedure SkillPanel_MinimapClick(Sender: TObject; const P: TPoint);
  { internal }
    procedure ReleaseMouse(releaseInFullScreen: Boolean = False);
    procedure CheckResetCursor(aForce: Boolean = False);
    procedure ApplyScroll(dX, dY: Integer);
    function CheckScroll: Boolean;
    procedure AddSaveState;
    procedure CheckAdjustSpawnInterval;
    procedure SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
    procedure InitializeCursor;
    procedure CheckShifts(Shift: TShiftState);
    procedure CheckUserHelpers;
    procedure DoDraw;
    procedure OnException(E: Exception; aCaller: String = 'Unknown');
    procedure ExecuteReplayEdit;
    procedure SetClearPhysics(aValue: Boolean);
    function GetClearPhysics: Boolean;
    procedure SetProjectionType(aValue: Integer);
    procedure ProcessGameMessages;
    procedure SetMinimumWindowHeight(CurPanelHeight: Integer);
    procedure ApplyResize(NoRecenter: Boolean = False);
    procedure ChangeZoom(aNewZoom: Integer; NoRedraw: Boolean = False);
    procedure FreeCursors;
    procedure HandleSpecialSkip(aSkipType: Integer);
    procedure HandleInfiniteSkillsHotkey;
    procedure HandleInfiniteTimeHotkey;

    function GetLevelMusicName: String;
    function ProcessMusicPriorityOrder(aOptions: String; aIsFromRotation: Boolean): String;

    function GetIsHyperSpeed: Boolean;

    procedure SetGameSpeed(aValue: TGameSpeed);
    function GetGameSpeed: TGameSpeed;
    function GetDisplayWidth: Integer;  // To satisfy IGameWindow
    function GetDisplayHeight: Integer; // To satisfy IGameWindow
    function GetScrollSpeed: Integer;
    procedure SuspendGameplay;
    procedure ResumeGameplay;

    function CheckHighlitLemmingChange: Boolean;
    procedure SetRedraw(aRedraw: TRedrawOption);
  protected
    fGame                : TLemmingGame;      // Reference to globalgame gamemechanics
    Img                  : TImage32;          // The image in which the level is drawn (reference to inherited ScreenImg!)
    SkillPanel           : TBaseSkillPanel;   // Our good old dos skill panel (now improved!)
    fActivateCount       : Integer;           // Used when activating the form
    GameScroll           : TGameScroll;       // Scrollmode
    GameVScroll          : TGameScroll;
    IdealFrameTimeMS     : Cardinal;          // Normal frame speed in milliseconds
    IdealFrameTimeMSSlow : Cardinal;
    IdealFrameTimeSuper  : Cardinal;
    IdealScrollTimeMS    : Cardinal;          // Scroll speed in milliseconds
    RewindTimer          : TTimer;
    FastForwardTimer     : TTimer;
    TurboTimer           : TTimer;
    PrevCallTime         : Cardinal;          // Last time we did something in idle
    PrevScrollTime       : Cardinal;          // Last time we scrolled in idle
    PrevPausedRRTime     : Cardinal;          // Last time we updated RR in idle
    MouseClipRect        : TRect;             // We clip the mouse when there is more space
    CanPlay              : Boolean;           // Use in idle en set to False whenever we don't want to play
    Cursors              : array[1..CURSOR_TYPES] of TNLCursor;
    MinScroll            : Single;            // Scroll boundary for image
    MaxScroll            : Single;            // Scroll boundary for image
    MinVScroll           : Single;
    MaxVScroll           : Single;
    fSaveStateFrame      : Integer;      // List of savestates (only first is used)
    fLastNukeKeyTime     : Cardinal;
    fScrollSpeed         : Integer;
    fMouseClickFrameskip : Cardinal;
    fLastMousePress      : Cardinal;
  { overridden}
    procedure PrepareGameParams; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
    procedure SaveShot;
    function IsGameplayScreen: Boolean; override;
  { internal properties }
    property Game: TLemmingGame read fGame;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyMouseTrap;
    procedure GotoSaveState(aTargetIteration: Integer; PauseAfterSkip: Integer = 0; aForceBeforeIteration: Integer = -1);
    procedure SaveReplay;
    procedure RenderMinimap;
    procedure MainFormResized; override;
    procedure SetCurrentCursor(aCursor: Integer = 0); // 0 = autodetect correct graphic
    property HScroll: TGameScroll read GameScroll write GameScroll;
    property VScroll: TGameScroll read GameVScroll write GameVScroll;
    property ClearPhysics: Boolean read fClearPhysics write SetClearPhysics;
    property ProjectionType: Integer read fProjectionType write SetProjectionType;
    function DoSuspendCursor: Boolean;
    function ShouldDisplayHQMinimap: Boolean;

    procedure DoRewind(Sender: TObject);
    procedure DoFastForward(Sender: TObject);
    procedure DoTurbo(Sender: TObject);
    property GameSpeed: TGameSpeed read GetGameSpeed write SetGameSpeed;
    property HyperSpeedTarget: Integer read fHyperSpeedTarget write fHyperSpeedTarget;
    property IsHyperSpeed: Boolean read GetIsHyperSpeed;

    function ScreenImage: TImage32; // To satisfy IGameWindow, should be moved to TGameBaseScreen, but it causes bugs there.
    property DisplayWidth: Integer read GetDisplayWidth; // To satisfy IGameWindow
    property DisplayHeight: Integer read GetDisplayHeight; // To satisfy IGameWindow
    procedure SetForceUpdateOneFrame(aValue: Boolean);  // To satisfy IGameWindow
    procedure SetHyperSpeedTarget(aValue: Integer);     // To satisfy IGameWindow
    function MouseFrameSkip: Integer; // Performs repeated skips when mouse buttons are held
    function GetLemmingOffscreenEdge: Integer;
  end;

implementation

uses FBaseDosForm, FEditReplay, LemReplay, LemNeoLevelPack;

{ TGameWindow }

procedure TGameWindow.SetGameSpeed(aValue: TGameSpeed);
begin
  fGameSpeed := aValue;

  // Handle Pause, Rewind and FF button selectors
  SkillPanel.DrawButtonSelector(spbPause, GameSpeed = gspPause);
  SkillPanel.DrawButtonSelector(spbRewind, GameSpeed = gspRewind);
  SkillPanel.DrawButtonSelector(spbFastForward, GameSpeed = gspFF);
end;

function TGameWindow.GetGameSpeed: TGameSpeed;
begin
  Result := fGameSpeed;
end;

procedure TGameWindow.Form_MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  Key: Word;
begin
  Key := 0;
  if WheelDelta > 0 then
    Key := $05
  else if WheelDelta < 0 then
    Key := $06;

  if Key <> 0 then
    OnKeyDown(Sender, Key, Shift);

  Handled := True;
end;

procedure TGameWindow.MainFormResized;
begin
  ApplyResize;
  DoDraw;
end;

procedure TGameWindow.ChangeZoom(aNewZoom: Integer; NoRedraw: Boolean = False);
var
  Pivot: TPoint;
begin
  aNewZoom := Max(Min(fMaxZoom, aNewZoom), 1);
  if (aNewZoom = fInternalZoom) and not NoRedraw then
    Exit;

  SkillPanel.Image.BeginUpdate;
  try
    Pivot := Img.ScreenToClient(Mouse.CursorPos);
    Pivot := Img.ControlToBitmap(Pivot);
    Img.Zoom(aNewZoom, Pivot);

    fInternalZoom := aNewZoom;

    ApplyResize(False);

    SetRedraw(rdRedraw);
    CheckResetCursor(True);
  finally
    SkillPanel.Image.EndUpdate;
  end;
end;

procedure TGameWindow.SetMinimumWindowHeight(CurPanelHeight: Integer);
var
  LevelHeight, TaskbarBuffer: Integer;
begin
  { A cute method for calculating the minimum window size (for dynamic resizing purposes).
    It works well enough, but assumes that (a) the user has the Windows taskbar visible,
    and (b) that the taskbar is no more than 100px in height (depending on scaling).
    In the vast majority of use cases, this will absolutely suffice. }

  LevelHeight := GameParams.Level.Info.Height;
  TaskbarBuffer := 100; // A reasonable estimate in the absence of a foolproof way to get the user's taskbar height

  // Use displayed level height for levels that don't exceed the standard average of 160px
  if (LevelHeight <= 160) then
    GameParams.MinimumWindowHeight := (CurPanelHeight + LevelHeight * fInternalZoom * ResMod);

  // Fallback to default if the calculated size would exceed the top of the taskbar or be lower than the default
  if (GameParams.MinimumWindowHeight > Screen.Height - TaskbarBuffer)
    or (GameParams.MinimumWindowHeight < GameParams.DefaultMinHeight) then
      GameParams.MinimumWindowHeight := GameParams.DefaultMinHeight;
end;

procedure TGameWindow.ApplyResize(NoRecenter: Boolean = False);
var
  OSHorz, OSVert: Single;
  CurPanelHeight: Integer;
  VertOffset: Integer;
begin
  OSHorz := Img.OffsetHorz - (Img.Width / 2);
  OSVert := Img.OffsetVert - (Img.Height / 2);

  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;

  // Get skill panel height according to resize percentage
  SkillPanel.ResizePanelWithWindow;
  CurPanelHeight := SkillPanel.ResizedPanelHeight;

  // Calculate the minimum window height to see if we can continue resizing
  SetMinimumWindowHeight(CurPanelHeight);

  // Set the width, height, and position of the game image
  Img.Width := Min(ClientWidth, GameParams.Level.Info.Width * fInternalZoom * ResMod);
  Img.Height := Min(ClientHeight - CurPanelHeight, GameParams.Level.Info.Height * fInternalZoom * ResMod);

  // Offset the level to the vertical centre of the screen
  VertOffset := ((ClientHeight - CurPanelHeight - Img.Height) div 2);
  Img.Top := VertOffset;
  Img.Left := (ClientWidth - Img.Width) div 2;

  // Magnetize panel to bottom of window
  SkillPanel.Top := ClientHeight - CurPanelHeight;

  SkillPanel.ClientWidth := ClientWidth;
  SkillPanel.Height := Max(CurPanelHeight, ClientHeight - SkillPanel.Top);
  SkillPanel.Image.Left := (SkillPanel.ClientWidth - SkillPanel.Image.Width) div 2;
  SkillPanel.Image.Update;

  // Don't push the level above the top of the window when resizing
  if Img.Top <= 0 then Img.Top := 0;//Exit;

  MinScroll := -((GameParams.Level.Info.Width * fInternalZoom * ResMod) - Img.Width);
  MaxScroll := 0;

  MinVScroll := -((GameParams.Level.Info.Height * fInternalZoom * ResMod) - Img.Height);
  MaxVScroll := 0;

  if not NoRecenter then
  begin
    OSHorz := OSHorz + (Img.Width / 2);
    OSVert := OSVert + (Img.Height / 2);
    Img.OffsetHorz := Min(Max(OSHorz, MinScroll), MaxScroll);
    Img.OffsetVert := Min(Max(OSVert, MinVScroll), MaxVScroll);
  end;

  fMaxZoom := Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS;
end;


function TGameWindow.IsGameplayScreen: Boolean;
begin
  Result := True;
end;

function TGameWindow.GetLevelMusicName: String;
var
  MusicIndex: Integer;
  SL: TStringList;
begin
  Result := ProcessMusicPriorityOrder(GameParams.Level.Info.MusicFile, False);
  if Result = '' then
  begin
    SL := GameParams.CurrentLevel.Group.MusicList;

    if SL.Count > 0 then
    begin
      if (GameParams.TestModeLevel <> nil) or (GameParams.CurrentLevel.Group = GameParams.BaseLevelPack) then
        MusicIndex := Random(SL.Count)
      else
        MusicIndex := GameParams.CurrentLevel.MusicRotationIndex;

      Result := ProcessMusicPriorityOrder(SL[MusicIndex mod SL.Count], True);
    end;
  end;

  if LeftStr(Result, 1) = '*' then
    Result := '';
end;

function TGameWindow.ProcessMusicPriorityOrder(aOptions: String; aIsFromRotation: Boolean): String;
var
  SL: TStringList;
  ThisName: String;
  MusicIndex: Integer;
  i: Integer;
begin
  Result := '';

  if aOptions = '' then
    Exit;

  SL := TStringList.Create;
  try
    SL.Delimiter := ';';
    SL.StrictDelimiter := True;

    if aOptions[1] = '!' then
    begin
      SL.DelimitedText := RightStr(aOptions, Length(aOptions)-1);
      for i := 0 to SL.Count-2 do
        SL.Move(Random(SL.Count - i) + i, i); // This is essentially a single-list Fisher-Yates shuffle
    end else
      SL.DelimitedText := aOptions;

    for i := 0 to SL.Count-1 do
    begin
      ThisName := ChangeFileExt(Trim(SL[i]), '');

      if ThisName = '' then Continue;

      if (LeftStr(ThisName, 1) = '?') and not aIsFromRotation then
      begin
        if ThisName = '??' then
          MusicIndex := Random(GameParams.CurrentLevel.Group.MusicList.Count)
        else
          MusicIndex := StrToIntDef(RightStr(ThisName, Length(ThisName)-1), -1);

        if (MusicIndex >= 0) and (MusicIndex < GameParams.CurrentLevel.Group.MusicList.Count) then
        begin
          ThisName := ProcessMusicPriorityOrder(GameParams.CurrentLevel.Group.MusicList[MusicIndex], True);
          if ThisName <> '' then
          begin
            Result := ThisName;
            Exit;
          end;
        end;
      end else if SoundManager.FindExtension(ThisName, True) <> '' then
      begin
        Result := ThisName;
        Exit;
      end;
    end;
  finally
    SL.Free;
  end;
end;

procedure TGameWindow.SetClearPhysics(aValue: Boolean);
begin
  if fClearPhysics <> aValue then
    SetRedraw(rdRedraw);
  fClearPhysics := aValue;
  SkillPanel.DrawButtonSelector(spbSquiggle, fClearPhysics);
end;

function TGameWindow.GetClearPhysics: Boolean;
begin
  Result := fClearPhysics;
end;

function TGameWindow.ShouldDisplayHQMinimap: Boolean;
begin
  Result := False;

  if not GameParams.MinimapHighQuality then
    Exit;

  if GameParams.AmigaTheme
  or Game.IsSuperLemmingMode
  or (GameSpeed in [gspRewind, gspTurbo, gspFF])
  or (Game.Level.Info.Width > MAX_WIDTH_FOR_HQMAP)
  or (Game.Level.Info.Height > MAX_HEIGHT_FOR_HQMAP) then
    Exit;

  Result := True;
end;

procedure TGameWindow.RenderMinimap;
begin
  if not GameParams.ShowMinimap then Exit;

  if ShouldDisplayHQMinimap then
  begin
    fMinimapBuffer.Clear(0);
    Img.Bitmap.DrawTo(fMinimapBuffer);
    SkillPanel.Minimap.Clear(0);
    fMinimapBuffer.DrawTo(SkillPanel.Minimap, SkillPanel.Minimap.BoundsRect, fMinimapBuffer.BoundsRect);
    fRenderer.RenderMinimap(SkillPanel.Minimap, True);
  end else
    fRenderer.RenderMinimap(SkillPanel.Minimap, False);

  SkillPanel.DrawMinimap;
end;

procedure TGameWindow.ExecuteReplayEdit;
var
  F: TFReplayEditor;
  OldClearReplay: Boolean;
  ModalResult: Integer;
begin
  F := TFReplayEditor.Create(Self);
  SuspendGameplay;

  try
    F.SetReplay(Game.ReplayManager, Game.CurrentIteration);

    repeat
      ModalResult := F.ShowModal;

      if (ModalResult = mrRetry) then
      begin
        if (F.TargetFrame <> -1) then
          GoToSaveState(F.TargetFrame)
        else
          GoToSaveState(F.CurrentIteration);
      end else if (ModalResult = mrCancel) and (F.TargetFrame <> -1) then
        GoToSaveState(F.CurrentIteration);

      if (ModalResult = mrOk) and (F.EarliestChange <= Game.CurrentIteration) then
      begin
        OldClearReplay := not GameParams.ReplayAfterBackskip;
        fSaveList.ClearAfterIteration(0);
        GotoSaveState(Game.CurrentIteration);
        GameParams.ReplayAfterBackskip := not OldClearReplay;
      end;

    until ModalResult <> mrRetry;
  finally
    F.Free;
    ResumeGameplay;
  end;
end;

procedure TGameWindow.ApplyMouseTrap;
var
  ClientTopLeft, ClientBottomRight: TPoint;
begin
  // Only trap mouse if SLX is in the foreground
  if FindControl(GetForegroundWindow()) = nil then Exit;

  // For security check trapping the mouse again.
  if fSuspendCursor or not GameParams.EdgeScroll then Exit;

  fMouseTrapped := True;

  ClientTopLeft := ClientToScreen(Point(Min(SkillPanel.Image.Left, Img.Left), Img.Top));
  ClientBottomRight := ClientToScreen(Point(Max(Img.Left + Img.Width, SkillPanel.Image.Left + SkillPanel.Image.Width), SkillPanel.Top + SkillPanel.Image.Height));
  MouseClipRect := Rect(ClientTopLeft, ClientBottomRight);
  ClipCursor(@MouseClipRect);
end;

procedure TGameWindow.ReleaseMouse(releaseInFullScreen: Boolean = False);
begin
  if GameParams.FullScreen and not releaseInFullScreen then Exit;
  fMouseTrapped := False;
  ClipCursor(nil);
end;

procedure TGameWindow.DoRewind(Sender: TObject);
begin
  // Start-of-level check needs to give a few frames' grace to prevent infinite rewinding
  if Game.CurrentIteration <= 8 then
  begin
    RewindTimer.Enabled := False;
    Game.IsBackstepping := False;
    GameSpeed := gspNormal; // Return speed to Normal at start of game
    SkillPanel.DrawButtonSelector(spbRewind, False);
  end else begin
    Game.IsBackstepping := True;
    GoToSaveState(Game.CurrentIteration - 3);
  end;
end;

procedure TGameWindow.DoFastForward(Sender: TObject);
begin
  fHyperSpeedTarget := Game.CurrentIteration + 1;
end;

procedure TGameWindow.DoTurbo(Sender: TObject);
begin
  fHyperSpeedTarget := Game.CurrentIteration + 7
end;

procedure TGameWindow.Application_Idle(Sender: TObject; var Done: Boolean);
{-------------------------------------------------------------------------------
  � Main heartbeat of the program.
  � This method together with Game.UpdateLemmings() take care of most game-mechanics.
  � A bit problematic is the SpawnInterval handling:
    if the game is paused, RR is handled here. if not it is handled by
    Game.UpdateLemmings().
-------------------------------------------------------------------------------}
var
  i: Integer;
  ContinueHyper: Boolean;

  CurrTime: Cardinal;
  ForceOne, TimeForFrame, TimeForPausedRR, TimeForScroll, Hyper, Pause, Rewind, Fast, Turbo, Slow: Boolean;
  MouseClickFrameSkip: Integer;
begin
  if fCloseToScreen <> gstUnknown then
  begin
    // This allows any mid-processing code to finish, and averts access violations, compared to directly calling CloseScreen.
    CloseScreen(fCloseToScreen);
    Exit;
  end;

  // This makes sure this method is called very often :)
  Done := False;

  Game.MaybeExitToPostview;

  if not CanPlay or not Game.Playing or Game.GameFinished then
  begin
    ProcessGameMessages; // May still be some lingering, especially the GAMEMSG_FINISH message
    Exit;
  end;

  MouseClickFrameSkip := MouseFrameSkip;

  if not (GameParams.ClassicMode or Game.IsSuperLemmingMode) then

  if MouseClickFrameSkip < 0 then
  begin
    GotoSaveState(Max(Game.CurrentIteration-1, 0));

    if not GameParams.ReplayAfterBackskip then
      Game.RegainControl(True);
  end;

  ForceOne := fForceUpdateOneFrame or fRenderInterface.ForceUpdate;
  fForceUpdateOneFrame := (MouseClickFrameSkip > 0);
  CurrTime := TimeGetTime;

  Pause := GameSpeed = gspPause;
  Rewind := GameSpeed = gspRewind;
  Fast := GameSpeed = gspFF;
  Turbo := GameSpeed = gspTurbo;
  Slow := GameSpeed = gspSlowMo;

  if Slow then
    TimeForFrame := (not (Pause or Rewind)) and (CurrTime - PrevCallTime > IdealFrameTimeMSSlow)
  else
    TimeForFrame := (not (Pause or Rewind)) and (CurrTime - PrevCallTime > IdealFrameTimeMS); // Don't check for frame advancing when paused

  TimeForPausedRR := (Pause) and (CurrTime - PrevPausedRRTime > IdealFrameTimeMS);
  TimeForScroll := CurrTime - PrevScrollTime > IdealScrollTimeMS;
  Hyper := IsHyperSpeed;

  // Rewind mode
  if Rewind then
  begin
    // Ensures that rendering has caught up before the next backwards skip is performed
    if IsHyperSpeed then
      RewindTimer.Enabled := False
    else
      RewindTimer.Enabled := True;
  end else begin
    RewindTimer.Enabled := False;
    SkillPanel.RemoveHighlight(spbRewind);
  end;

  // Fast-forward
  if Fast then
    FastForwardTimer.Enabled := True
  else
    FastForwardTimer.Enabled := False;

  // Turbo mode
  if Turbo then
  begin
    TurboTimer.Enabled := True;
    SkillPanel.DrawTurboHighlight;
  end else begin
    TurboTimer.Enabled := False;
    SkillPanel.DrawTurboHighlight;
  end;

  // Superlemming mode
  if Game.IsSuperLemmingMode then
  begin
    TimeForFrame := (not Pause) and (CurrTime - PrevCallTime > IdealFrameTimeSuper);
    SkillPanel.DrawButtonSelector(spbRewind, True);
    SkillPanel.DrawButtonSelector(spbFastForward, True);
  end;

  if ForceOne or Hyper then TimeForFrame := True;

  // Relax CPU
  if not (Hyper or Fast or Game.IsSuperLemmingMode) then
    Sleep(1);

  if TimeForFrame or TimeForScroll or TimeForPausedRR then
  begin
    fRenderInterface.ForceUpdate := False;

    // Only in paused mode adjust RR. If not paused it's updated per frame.
    if TimeForPausedRR and not GameParams.ClassicMode then
    begin
      CheckAdjustSpawnInterval;
      PrevPausedRRTime := CurrTime;
    end;

    // Set new screen position
    if TimeForScroll then
    begin
      PrevScrollTime := CurrTime;
      if CheckScroll then
      begin
        if ShouldDisplayHQMinimap then
          SetRedraw(rdRefresh)
        else
          SetRedraw(rdRedraw);
      end;
    end;

    // Check whether we have to move the lemmings
    if (TimeForFrame and not (Pause or Rewind))
       or ForceOne
       or Hyper then
    begin
      // Reset time between physics updates
      PrevCallTime := CurrTime;
      // Let all lemmings move
      Game.UpdateLemmings;
      // Save current state every 10 seconds
      if (Game.CurrentIteration mod 170 = 0) then
      begin
        AddSaveState;
        fSaveList.TidyList(Game.CurrentIteration);
      end;

      fRanOneUpdate := True;
    end;

    if Hyper and (fHyperSpeedStopCondition <> 0) then
    begin
      ContinueHyper := False;

      if Game.CurrentIteration < fSpecialStartIteration + SPECIAL_SKIP_MAX_DURATION then
        case fHyperSpeedStopCondition of
          SHE_SHRUGGER: for i := 0 to fRenderInterface.LemmingList.Count-1 do
                        begin
                          if fRenderInterface.LemmingList[i].LemRemoved then Continue;

                          if fRenderInterface.LemmingList[i].LemAction = baShrugging then
                          begin
                            ContinueHyper := False;
                            Break;
                          end;

                          if fRenderInterface.LemmingList[i].LemAction in [baBuilding, baStacking, baPlatforming] then
                            ContinueHyper := True;
                        end;
          SHE_HIGHLIT: if not CheckHighlitLemmingChange then ContinueHyper := True;
        end;

      if not ContinueHyper then
      begin
        fHyperSpeedTarget := Game.CurrentIteration;
        fHyperSpeedStopCondition := 0;
      end else
        fHyperSpeedTarget := Game.CurrentIteration + 1;
    end;

    // Prevents large forward skips overshooting into unplayable state
    if Game.StateIsUnplayable and Hyper then
      fHyperSpeedTarget := Game.CurrentIteration;

    // Refresh panel if in usual or fast play mode
    if not Hyper then
    begin
      SkillPanel.RefreshInfo;
      CheckResetCursor;
    end else if (Game.CurrentIteration = fHyperSpeedTarget) then
    begin
      fHyperSpeedTarget := -1;
      SkillPanel.RefreshInfo;
      SetRedraw(rdRedraw);
      CheckResetCursor;
    end;
  end;

  if TimeForFrame then
    SetRedraw(rdRedraw);

  // Update drawing
  DoDraw;

  // Bookmark - use this logic for VisualSFX
  {$ifdef debug}
//  case GetLemmingOffscreenEdge of
//    0: Output('Lemming ' + IntToStr(i) + ' is onscreen');
//    1: Output('Lemming ' + IntToStr(i) + ' is offscreen to the top');
//    2: Output('Lemming ' + IntToStr(i) + ' is offscreen to the bottom');
//    3: Output('Lemming ' + IntToStr(i) + ' is offscreen to the left');
//    4: Output('Lemming ' + IntToStr(i) + ' is offscreen to the right');
//  end;
  {$endif}

  if TimeForFrame then
    ProcessGameMessages;
end;

function TGameWindow.GetIsHyperSpeed: Boolean;
begin
  Result := (fHyperSpeedTarget > Game.CurrentIteration) or (fHyperSpeedStopCondition <> 0);
end;

function TGameWindow.GetLemmingOffscreenEdge: Integer;
var
  i: Integer;
  LemPoint: TPoint;
  ViewportTop, ViewportBottom: Integer;
  ViewportLeft, ViewportRight: Integer;
begin
  Result := -1;

  if fRenderInterface = nil then Exit;

  ViewportTop    := Abs(Trunc(Img.OffsetVert) div fInternalZoom) div ResMod;
  ViewPortBottom := ((Img.Height - Trunc(Img.OffsetVert)) div fInternalZoom) div ResMod;
  ViewportLeft   := Abs(Trunc(Img.OffsetHorz) div fInternalZoom) div ResMod;
  ViewportRight  := ((Img.Width - Trunc(Img.OffsetHorz)) div fInternalZoom) div ResMod;

  for i := 0 to fRenderInterface.LemmingList.Count -1 do
  begin
    LemPoint := fRenderInterface.LemmingList[i].Position;

    if      (LemPoint.X > ViewportRight) then
      Result := 4
    else if (LemPoint.X < ViewportLeft) then
      Result := 3
    else if (LemPoint.Y > ViewportBottom) then
      Result := 2
    else if (LemPoint.Y < ViewportTop + 1) then
      Result := 1
    else
      Result := 0; // Onscreen
    Exit;
  end;
end;

procedure TGameWindow.ProcessGameMessages;
var
  Msg: TGameMessage;
begin
  while Game.MessageQueue.HasMessages do
  begin
    Msg := Game.MessageQueue.NextMessage;

    case Msg.MessageType of
      GAMEMSG_FINISH: Game_Finished;

      // Still need to implement sound
      GAMEMSG_SOUND: if not IsHyperSpeed then
                       SoundManager.PlaySound(Msg.MessageDataStr);
      GAMEMSG_SOUND_BAL: if not IsHyperSpeed then
                           SoundManager.PlaySound(Msg.MessageDataStr,
                           (Msg.MessageDataInt - Trunc(((Img.Width / 2) - Img.OffsetHorz) / Img.Scale)) div 2);
      GAMEMSG_MUSIC: SoundManager.PlayMusic;
    end;
  end;
end;

procedure TGameWindow.OnException(E: Exception; aCaller: String = 'Unknown');
var
  SL: TStringList;
  RIValid: Boolean;
begin
  fGameSpeed := gspPause;
  SL := TStringList.Create;

  // Attempt to load existing report so we can simply add to the end.
  // We don't want to trigger a second exception here, so be over-cautious with the try...excepts.
  // Performance probably doesn't matter if we end up here.
  try
    if FileExists(ExtractFilePath(ParamStr(0)) + 'SuperLemmixException.txt') then
    begin
      SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'SuperLemmixException.txt');
      SL.Add('');
      SL.Add('');
    end;
  except
    SL.Clear;
  end;

  SL.Add('Exception raised at ' + DateToStr(Now));
  SL.Add('  Happened in: ' + aCaller);
  SL.Add('  Class: ' + E.ClassName);
  SL.Add('  Message: ' + E.Message);

  RIValid := False;
  if fRenderInterface = nil then
    SL.Add('  fRenderInterface: nil')
  else
    try
      fRenderInterface.Null;
      SL.Add('  fRenderInterface: Valid');
      RIValid := True;
    except
      SL.Add('  fRenderInterface: Exception on access attempt');
    end;

  if RIValid then
  begin
    if fRenderInterface.LemmingList = nil then
      SL.Add('  fRenderInterface.LemmingList: nil')
    else
      try
        SL.Add('  fRenderInterface.LemmingList.Count: ' + IntToStr(fRenderInterface.LemmingList.Count));
      except
        SL.Add('  fRenderInterface.LemmingList: Exception on access attempt');
      end;

    if fRenderInterface.SelectedLemming = nil then
      SL.Add('  fRenderInterface.SelectedLemming: nil')
    else
      try
        fRenderInterface.SelectedLemming.LemX := 0;
        SL.Add('  fRenderInterface.SelectedLemming: Valid');
      except
        SL.Add('  fRenderInterface.SelectedLemming: Exception on access attempt');
      end;

    if fRenderInterface.HighlitLemming = nil then
      SL.Add('  fRenderInterface.HighlitLemming: nil')
    else
      try
        fRenderInterface.HighlitLemming.LemX := 0;
        SL.Add('  fRenderInterface.HighlitLemming: Valid');
      except
        SL.Add('  fRenderInterface.HighlitLemming: Exception on access attempt');
      end;

    if fRenderInterface.ReplayLemming = nil then
      SL.Add('  fRenderInterface.ReplayLemming: nil')
    else
      try
        fRenderInterface.ReplayLemming.LemX := 0;
        SL.Add('  fRenderInterface.ReplayLemming: Valid');
      except
        SL.Add('  fRenderInterface.ReplayLemming: Exception on access attempt');
      end;

    case fRenderInterface.SelectedSkill of
      spbWalker: SL.Add('  fRenderInterface.SelectedSkill: Walker');
      spbClimber: SL.Add('  fRenderInterface.SelectedSkill: Climber');
      spbSwimmer: SL.Add('  fRenderInterface.SelectedSkill: Swimmer');
      spbBallooner: SL.Add('  fRenderInterface.SelectedSkill: Ballooner');
      spbFloater: SL.Add('  fRenderInterface.SelectedSkill: Floater');
      spbGlider: SL.Add('  fRenderInterface.SelectedSkill: Glider');
      spbDisarmer: SL.Add('  fRenderInterface.SelectedSkill: Disarmer');
      spbTimebomber: SL.Add('  fRenderInterface.SelectedSkill: Timebomber');
      spbBomber: SL.Add('  fRenderInterface.SelectedSkill: Bomber');
      spbFreezer: SL.Add('  fRenderInterface.SelectedSkill: Freezer');
      spbBlocker: SL.Add('  fRenderInterface.SelectedSkill: Blocker');
      spbLadderer: SL.Add('  fRenderInterface.SelectedSkill: Ladderer');
      spbPlatformer: SL.Add('  fRenderInterface.SelectedSkill: Platformer');
      spbBuilder: SL.Add('  fRenderInterface.SelectedSkill: Builder');
      spbStacker: SL.Add('  fRenderInterface.SelectedSkill: Stacker');
      spbLaserer: SL.Add('  fRenderInterface.SelectedSkill: Laserer');
      //spbPropeller: SL.Add('  fRenderInterface.SelectedSkill: Propeller'); // Propeller
      spbBasher: SL.Add('  fRenderInterface.SelectedSkill: Basher');
      spbFencer: SL.Add('  fRenderInterface.SelectedSkill: Fencer');
      spbMiner: SL.Add('  fRenderInterface.SelectedSkill: Miner');
      spbDigger: SL.Add('  fRenderInterface.SelectedSkill: Digger');
      spbCloner: SL.Add('  fRenderInterface.SelectedSkill: Cloner');
      spbShimmier: SL.Add('  fRenderInterface.SelectedSkill: Shimmier');
      spbJumper: SL.Add('  fRenderInterface.SelectedSkill: Jumper');
      spbSpearer: SL.Add('  fRenderInterface.SelectedSkill: Spearer');
      spbGrenader: SL.Add('  fRenderInterface.SelectedSkill: Grenader');
      //spbBatter: SL.Add('  fRenderInterface.SelectedSkill: Batter'); // Batter
      spbSlider: SL.Add('  fRenderInterface.SelectedSkill: Slider');
      else SL.Add('  fRenderInterface.SelectedSkill: None or invalid');
    end;
  end;

  // Attempt to save report - we'd rather it just fail than crash and lose the replay data.
  try
    SL.SaveToFile(ExtractFilePath(ParamStr(0)) + 'SuperLemmixException.txt');
    RIValid := True;
  except
    // We can't do much here.
    RIValid := False; // Reuse is lazy. but I'm doing it anyway.
  end;

  if RIValid then
    ShowMessage('An exception has occurred. Details have been saved to SuperLemmixException.txt. Your current replay will be' + #13 +
                'saved to the "Auto" folder if possible, then you will be returned to the main menu.')
  else
    ShowMessage('An exception has occurred. Attempting to save details to a text file failed. Your current replay will be' + #13 +
                'saved to the "Auto" folder if possible, then you will be returned to the main menu.');

  try
    SL.Insert(0, Game.ReplayManager.GetSaveFileName(Self, rsoAuto));
    ForceDirectories(ExtractFilePath(SL[0]));
    Game.EnsureCorrectReplayDetails;
    Game.ReplayManager.SaveToFile(SL[0]);
    ShowMessage('Your replay was saved successfully. Returning to main menu now. Restarting SuperLemmix is recommended.');
  except
    ShowMessage('Unfortunately, your replay could not be saved.');
  end;

  fCloseToScreen := gstMenu;
end;

procedure TGameWindow.CheckUserHelpers;
begin
  if GameParams.ClassicMode then Exit;

  fRenderInterface.UserHelper := hpi_None;
  if GameParams.Hotkeys.CheckForKey(lka_FallDistance) then
    fRenderInterface.UserHelper := hpi_FallDist;
end;

procedure TGameWindow.DoDraw;
var
  DrawRect: TRect;
  DrawWidth, DrawHeight: Integer;
begin
  if IsHyperSpeed then Exit;

  Game.HitTest(not PtInRect(Img.BoundsRect, ScreenToClient(Mouse.CursorPos)));
  CheckUserHelpers;

  if (fRenderInterface.SelectedLemming <> fLastSelectedLemming)
  or (fRenderInterface.HighlitLemming <> fLastHighlightLemming)
  or (fRenderInterface.SelectedSkill <> fLastSelectedSkill)
  or (fRenderInterface.UserHelper <> fLastHelperIcon)
  or (fRenderInterface.UserHelper = hpi_FallDist)
  or (fClearPhysics)
  or (fProjectionType <> fLastProjectionType)
  or ((GameSpeed = gspPause) and not fLastDrawPaused) then
    SetRedraw(rdRedraw);

  if fNeedRedraw = rdRefresh then
  begin
    if GameParams.ShowMinimap then
      { rdRefresh currently always occurs as a result of scrolling without any change otherwise,
        so, minimap needs redrawing. }
      RenderMinimap;
    fNeedRedraw := rdNone;
  end;

  if fNeedRedraw = rdRedraw then
  begin
    try
      fRenderInterface.ScreenPos := Point(Trunc(Img.OffsetHorz / fInternalZoom) * -1, Trunc(Img.OffsetVert / fInternalZoom) * -1);
      fRenderInterface.MousePos := Game.CursorPoint;
      fRenderer.DrawAllGadgets(fRenderInterface.Gadgets, True, fClearPhysics);
      fRenderer.DrawLemmings(fClearPhysics);
      fRenderer.DrawProjectiles;

      if ShouldDisplayHQMinimap or (GameSpeed = gspPause) then
        DrawRect := Img.Bitmap.BoundsRect
      else begin
        DrawWidth := (ClientWidth div fInternalZoom) + 2; // Padding pixel on each side
        DrawHeight := (ClientHeight div fInternalZoom) + 2;
        DrawRect := Rect(fRenderInterface.ScreenPos.X - 1, fRenderInterface.ScreenPos.Y - 1, fRenderInterface.ScreenPos.X + DrawWidth, fRenderInterface.ScreenPos.Y + DrawHeight);
      end;

      fRenderer.DrawLevel(GameParams.TargetBitmap, DrawRect, fClearPhysics);

      if GameParams.ShowMinimap then
        RenderMinimap;

      SkillPanel.RefreshInfo;

      fLastSelectedLemming := fRenderInterface.SelectedLemming;
      fLastHighlightLemming := fRenderInterface.HighlitLemming;
      fLastSelectedSkill := fRenderInterface.SelectedSkill;
      fLastHelperIcon := fRenderInterface.UserHelper;
      fLastDrawPaused := GameSpeed = gspPause;
      fLastProjectionType := fProjectionType;

      fNeedRedraw := rdNone;
    except
      on E: Exception do
        OnException(E, 'TGameWindow.DoDraw');
    end;
  end;
end;

procedure TGameWindow.CheckShifts(Shift: TShiftState);
var
  SDir: Integer;
begin
  SDir := 0;

  if not GameParams.ClassicMode then
  begin
    // These two cancel each other out if both are pressed. Genius. :D
    if GameParams.Hotkeys.CheckForKey(lka_DirLeft) then SDir := SDir - 1;
    if GameParams.Hotkeys.CheckForKey(lka_DirRight) then SDir := SDir + 1;

    Game.IsSelectWalkerHotkey := GameParams.Hotkeys.CheckForKey(lka_ForceWalker);
    Game.IsHighlightHotkey := GameParams.Hotkeys.CheckForKey(lka_Highlight);
  end;

  Game.IsShowAthleteInfo := GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo);

  Game.fSelectDx := SDir;
end;

procedure TGameWindow.GotoSaveState(aTargetIteration: Integer; PauseAfterSkip: Integer = 0; aForceBeforeIteration: Integer = -1);
{-------------------------------------------------------------------------------
  Go in hyperspeed from the beginning to aTargetIteration
  PauseAfterSkip values:
    Negative: Always go to normal speed
    Zero:     Keep current speed
    Positive: Always pause
-------------------------------------------------------------------------------}
var
  UseSaveState: Integer;
begin
  if aForceBeforeIteration < 0 then
    aForceBeforeIteration := aTargetIteration;

  CanPlay := False;

  if not (GameSpeed = gspRewind) then
  begin
    if PauseAfterSkip < 0 then
    begin
      Game.IsBackstepping := False;
      GameSpeed := gspNormal;
    end else if ((aTargetIteration < Game.CurrentIteration) and GameParams.PauseAfterBackwardsSkip)
      or (PauseAfterSkip > 0) then
      begin
        if Game.IsBackstepping then GameSpeed := gspPause;
      end;
  end;

  if (aTargetIteration <> Game.CurrentIteration) or fRanOneUpdate then
  begin
    // Find correct save state
    if aTargetIteration > 0 then
      UseSaveState := fSaveList.FindNearestState(aForceBeforeIteration)
    else if fSaveList.Count = 0 then
      UseSaveState := -1
    else
      UseSaveState := 0;

    // Load save state or restart the level
    if UseSaveState >= 0 then
      Game.LoadSavedState(fSaveList[UseSaveState])
    else
      Game.Start(True);
  end;

  fSaveList.ClearAfterIteration(Game.CurrentIteration);

  if aTargetIteration = Game.CurrentIteration then
    SetRedraw(rdRedraw)
  else
    // Start hyperspeed to the desired interation
    fHyperSpeedTarget := aTargetIteration;

  CanPlay := True;
end;

procedure TGameWindow.CheckResetCursor(aForce: Boolean = False);
begin
  if not CanPlay then Exit;

  if FindControl(GetForegroundWindow()) = nil then
  begin
    fNeedResetMouseTrap := True;
    exit;
  end;

  SetCurrentCursor;

  if (fNeedResetMouseTrap or aForce) and fMouseTrapped and (not fSuspendCursor) and GameParams.EdgeScroll then
  begin
    ApplyMouseTrap;
    fNeedResetMouseTrap := False;
  end;
end;

procedure TGameWindow.SetCurrentCursor(aCursor: Integer = 0);
var
  NewCursor: Integer;
begin
  if DoSuspendCursor then Exit;

  if aCursor = 0 then
  begin
    if (fRenderInterface.SelectedLemming = nil) or not PtInRect(Img.BoundsRect, ScreenToClient(Mouse.CursorPos)) then
    begin
      if GameParams.PlaybackModeActive and not Game.Replaying then
        NewCursor := 7
      else if Game.ReplayInsert and Game.Replaying then
        NewCursor := 5
      else if Game.Replaying then
        NewCursor := 3
      else
        NewCursor := 1
    end else begin
      if GameParams.PlaybackModeActive and not Game.Replaying then
        NewCursor := 8
      else if Game.ReplayInsert and Game.Replaying then
        NewCursor := 6
      else if Game.Replaying then
        NewCursor := 4
      else
        NewCursor := 2;
    end;

    if Game.fSelectDx < 0 then
      NewCursor := NewCursor + 8
    else if Game.fSelectDx > 0 then
      NewCursor := NewCursor + 16;
  end else
    NewCursor := aCursor;

  NewCursor := NewCursor + ((fInternalZoom-1) * CURSOR_TYPES);

  if NewCursor <> Cursor then
  begin
    Cursor := NewCursor;
    Img.Cursor := NewCursor;
    Screen.Cursor := NewCursor;
    SkillPanel.SetCursor(NewCursor);
  end;
end;

function TGameWindow.DoSuspendCursor: Boolean;
begin
  Result := fSuspendCursor;
end;

procedure TGameWindow.ApplyScroll(dX, dY: Integer);
begin
  Img.OffsetHorz := Img.OffsetHorz - fInternalZoom * dX;
  Img.OffsetVert := Img.OffsetVert - fInternalZoom * dY;
  Img.OffsetHorz := Max(MinScroll, Img.OffsetHorz);
  Img.OffsetHorz := Min(MaxScroll, Img.OffsetHorz);
  Img.OffsetVert := Max(MinVScroll, Img.OffsetVert);
  Img.OffsetVert := Min(MaxVScroll, Img.OffsetVert);
end;

function TGameWindow.CheckScroll: Boolean;
  procedure Scroll(dX, dY: Integer);
  begin
    ApplyScroll(dX, dY);
    Result := (dX <> 0) or (dY <> 0) or Result; { Though it should never happen anyway,
                                                  a Scroll(0, 0) call after an earlier nonzero
                                                  call should not set Result to False }
  end;

  procedure HandleHeldScroll;
  var
    HDiff, VDiff: Integer;
  begin
    HDiff := (Mouse.CursorPos.X - fHoldScrollData.StartCursor.X) div fInternalZoom;
    VDiff := (Mouse.CursorPos.Y - fHoldScrollData.StartCursor.Y) div fInternalZoom;

    if Abs(HDiff) = 1 then
      fHoldScrollData.StartCursor.X := Mouse.CursorPos.X
    else
      fHoldScrollData.StartCursor.X := fHoldScrollData.StartCursor.X + (HDiff * 3 div 4);

    if Abs(VDiff) = 1 then
      fHoldScrollData.StartCursor.Y := Mouse.CursorPos.Y
    else
      fHoldScrollData.StartCursor.Y := fHoldScrollData.StartCursor.Y + (VDiff * 3 div 4);

    Img.BeginUpdate;
    Scroll(HDiff, VDiff);
    Img.EndUpdate;
  end;
begin
  Result := False;

  if fHoldScrollData.Active then
  begin
    if GameParams.Hotkeys.CheckForKey(lka_Scroll) then
      HandleHeldScroll
    else
      fHoldScrollData.Active := False;
  end else if fNeedResetMouseTrap or not fMouseTrapped then
  begin
    GameScroll := gsNone;
    GameVScroll := gsNone;
  end else if GameParams.EdgeScroll then begin
    if Mouse.CursorPos.X <= MouseClipRect.Left then
      GameScroll := gsLeft
    else if Mouse.CursorPos.X >= MouseClipRect.Right-1 then
      GameScroll := gsRight
    else
      GameScroll := gsNone;

    if Mouse.CursorPos.Y <= MouseClipRect.Top then
      GameVScroll := gsUp
    else if Mouse.CursorPos.Y >= MouseClipRect.Bottom-1 then
      GameVScroll := gsDown
    else
      GameVScroll := gsNone;

    Img.BeginUpdate;
    case GameScroll of
      gsRight:
        Scroll(fScrollSpeed * ResMod, 0);
      gsLeft:
        Scroll(-fScrollSpeed * ResMod, 0);
    end;
    case GameVScroll of
      gsUp:
        Scroll(0, -fScrollSpeed * ResMod);
      gsDown:
        Scroll(0, fScrollSpeed * ResMod);
    end;
    Img.EndUpdate;
  end;
end;

function TGameWindow.GetScrollSpeed: Integer;
begin
  Result := 8; // Default

  // Set speed according to user options
  if (GameParams.EdgeScrollSpeed >= 0) then
  begin
    if      GameParams.EdgeScrollSpeed = 0 then
      Result := Result div 4 // Slowest
    else if GameParams.EdgeScrollSpeed = 1 then
      Result := Result div 2 // Slow
    else if GameParams.EdgeScrollSpeed = 2 then
      Exit                   // Medium (Default)
    else if GameParams.EdgeScrollSpeed = 3 then
      Result := Result * 2   // Fast
    else if GameParams.EdgeScrollSpeed >= 4 then
      Result := Result * 4;  // Fastest
  end;
end;

constructor TGameWindow.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CurrentScreen := gstPlay;

  Color := $200020;

  fNeedResetMouseTrap := True;
  fSaveStateReplayStream := TMemoryStream.Create;

  // Create game
  fGame := GlobalGame; // Set ref to GlobalGame
  fScrollSpeed := GetScrollSpeed;
  fSaveStateFrame := -1;
  fHyperSpeedTarget := -1;

  Img := ScreenImg; // Set ref to inherited screenimg (just for a short name)
  Img.RepaintMode := rmOptimizer;
  Img.Color := clBlack;
  Img.BitmapAlign := baCustom;
  Img.ScaleMode := smScale;

  // Create panel
  SkillPanel := TSkillPanelStandard.CreateWithWindow(Self, Self);
  SkillPanel.Parent := Self;

  Self.KeyPreview := True;

  // Set eventhandlers
  Self.OnActivate := Form_Activate;
  Self.OnKeyDown := Form_KeyDown;
  Self.OnKeyUp := Form_KeyUp;
  Self.OnKeyPress := Form_KeyPress;
  Self.OnMouseMove := Form_MouseMove;
  Self.OnMouseUp := Form_MouseUp;
  Self.OnMouseWheel := Form_MouseWheel;

  Img.OnMouseDown := Img_MouseDown;
  Img.OnMouseMove := Img_MouseMove;
  Img.OnMouseUp := Img_MouseUp;

  RewindTimer := TTimer.Create(Self);
  RewindTimer.Interval := 60;
  RewindTimer.OnTimer := DoRewind;

  FastForwardTimer := TTimer.Create(Self);
  FastForwardTimer.Interval := 10;
  FastForwardTimer.OnTimer := DoFastForward;

  TurboTimer := TTimer.Create(Self);
  TurboTimer.Interval := 40;
  TurboTimer.OnTimer := DoTurbo;

  SkillPanel.SetGame(fGame);
  SkillPanel.SetOnMinimapClick(SkillPanel_MinimapClick);
  Application.OnIdle := Application_Idle;

  fSaveList := TLemmingGameSavedStateList.Create(True);
  fReplayKilled := False;
  fMinimapBuffer := TBitmap32.Create;
  TLinearResampler.Create(fMinimapBuffer);
  fSuspensions := TList<TSuspendState>.Create;
  fHighlitStartCopyLemming := TLemming.Create;
  HotkeyManager := TLemmixHotkeyManager.Create;
  fMouseClickFrameskip := GetTickCount;
end;

destructor TGameWindow.Destroy;
begin
  CanPlay := False;
  Application.OnIdle := nil;

  if SkillPanel <> nil then
    SkillPanel.SetGame(nil);

  fSaveList.Free;
  fSaveStateReplayStream.Free;
  FreeCursors;
  fMinimapBuffer.Free;
  fSuspensions.Free;
  fHighlitStartCopyLemming.Free;
  HotkeyManager.Free;
  RewindTimer.Free;
  FastForwardTimer.Free;
  TurboTimer.Free;
  inherited Destroy;
end;

procedure TGameWindow.FreeCursors;
var
  i: Integer;
begin
  for i := Low(Cursors) to High(Cursors) do
    Cursors[i].Free;
end;

procedure TGameWindow.Form_Activate(Sender: TObject);
// Activation eventhandler
begin
  if fActivateCount = 0 then
  begin
    fGame.Start;
    fGame.CreateSavedState(fSaveList.Add);
    CanPlay := True;
  end;
  Inc(fActivateCount);
end;

procedure TGameWindow.HandleInfiniteSkillsHotkey;
var
  i, n, TargetFrame: Integer;
  ReplayEvent: TBaseReplayItem;
begin
  if (Game.Level.Info.Skillset = []) then Exit;

  // Check for existing previous replay event
  for i := 0 to Game.CurrentIteration do
    if Game.ReplayManager.HasSkillCountChangeAt(i) then
    begin
      TargetFrame := i;

      Game.IsBackstepping := True;
      GotoSaveState(Max(TargetFrame, 0));

      // Delete all existing future Infinite Skills replay events
      for n := 0 to Game.ReplayManager.LastActionFrame do
      begin
        ReplayEvent := Game.ReplayManager.SkillCountChange[n, 0];
        Game.ReplayManager.Delete(ReplayEvent);
      end;

      Game.ResetSkillCount;
      Exit;
    end;

  // If no previous replay events found, set Infinite Skills and record replay event
  Game.SetSkillsToInfinite;
  Game.RecordInfiniteSkills;
end;

procedure TGameWindow.HandleInfiniteTimeHotkey;
var
  i, n, TargetFrame: Integer;
  ReplayEvent: TBaseReplayItem;
begin
  if not Game.Level.Info.HasTimeLimit then Exit;

  // Check for existing previous replay event
  for i := 0 to Game.CurrentIteration do
    if Game.ReplayManager.HasTimeChangeAt(i) then
    begin
      TargetFrame := i;

      Game.IsBackstepping := True;
      GotoSaveState(Max(TargetFrame, 0));

      // Delete all existing future Infinite Time replay events
      for n := 0 to Game.ReplayManager.LastActionFrame do
      begin
        ReplayEvent := Game.ReplayManager.TimeChange[n, 0];
        Game.ReplayManager.Delete(ReplayEvent);
      end;

      Game.IsInfiniteTimeMode := False;
      Exit;
    end;

  // If no previous replay events found, set Infinite Time and record replay event
  Game.IsInfiniteTimeMode := True;
  Game.RecordInfiniteTime;
end;

procedure TGameWindow.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CurrTime: Cardinal;
  sn: Integer;
  ButtonIndex: Integer;
  func: TLemmixHotkey;
  AssignToHighlit: Boolean;
  CursorPointForm: TPoint; // A point in coordinates relative to the main form
const
  NON_CANCELLING_KEYS = [lka_Null,
                         lka_ShowAthleteInfo,
                         lka_Exit,
                         lka_Pause,
                         lka_SaveState,
                         lka_LoadState,
                         lka_Highlight,
                         lka_DirLeft,
                         lka_DirRight,
                         lka_ForceWalker,
                         lka_InfiniteSkills,
                         lka_InfiniteTime,
                         lka_Cheat,
                         lka_Skip,
                         lka_SpecialSkip,
                         lka_FastForward,
                         lka_Rewind,
                         lka_SlowMotion,
                         lka_SaveImage,
                         lka_LoadReplay,
                         lka_SaveReplay,
                         lka_CancelReplay, // This does cancel. but the code should show why it's in this list. :)
                         lka_EditReplay,
                         lka_ReplayInsert,
                         lka_Music,
                         lka_Sound,
                         lka_Restart,
                         lka_ReleaseMouse,
                         lka_Nuke, // Nuke also cancels, but requires double-press to do so so handled elsewhere
                         lka_ClearPhysics,
                         lka_ShowUsedSkills,
                         lka_ZoomIn,
                         lka_ZoomOut,
                         lka_Scroll,
                         lka_NudgeUp,
                         lka_NudgeDown,
                         lka_NudgeLeft,
                         lka_NudgeRight];
  SKILL_KEYS = [lka_Skill, lka_SkillButton, lka_SkillLeft, lka_SkillRight];
begin
  func := GameParams.Hotkeys.CheckKeyEffect(Key);

  if func.Action = lka_Exit then
  begin
    Game.Finish(GM_FIN_TERMINATE);
    Exit;
  end;

  if not Game.Playing then Exit;

  { Although we don't want to attempt game control whilst in HyperSpeed,
   we do want the Rewind, FF and Turbo keys to respond }
  if IsHyperSpeed and not (GameSpeed in [gspRewind, gspFF, gspTurbo]) then
    Exit;

  with Game do
  begin
    if (func.Action = lka_CancelReplay) then
      Game.RegainControl(True); // Force the cancel even if in Replay Insert mode

    if (func.Action in [lka_ReleaseRateMax, lka_ReleaseRateDown, lka_ReleaseRateUp, lka_ReleaseRateMin]) then
      begin
        SkillPanel.RRIsPressed := True; // Prevents replay "R" being displayed when using RR hotkeys
        Game.IsBackstepping := False; // Ensures RR sound is cued properly
        Game.RegainControl; // We don't want to FORCE it in this case; Replay Insert mode should be respected here
      end;

    if func.Action = lka_Skill then
    begin
      AssignToHighlit := GameParams.Hotkeys.CheckForKey(lka_Highlight);
      SetSelectedSkill(TSkillPanelButton(func.Modifier), True, AssignToHighlit);
    end;

    case func.Action of
      lka_ReleaseMouse: ReleaseMouse;
      lka_ReleaseRateMax: if not GameParams.ClassicMode then
                          begin
                           SetSelectedSkill(spbFaster, True, True);
                          end;
      lka_ReleaseRateDown: SetSelectedSkill(spbSlower, True);
      lka_ReleaseRateUp: SetSelectedSkill(spbFaster, True);
      lka_ReleaseRateMin: if not GameParams.ClassicMode then
                          begin
                          SetSelectedSkill(spbSlower, True, True);
                          end;
      lka_Pause: begin
                   // 55 frames' grace at the start of the level (before music starts) for the NoPause talisman
                   if (Game.CurrentIteration > 55) then Game.PauseWasPressed := True;

                   // Cancel replay if pausing directly from Rewind in Classic Mode
                   if GameParams.ClassicMode and (GameSpeed = gspRewind) then
                     Game.RegainControl(True);

                   if GameSpeed = gspPause then
                   begin
                     Game.IsBackstepping := False;
                     GameSpeed := gspNormal;
                   end else begin
                     Game.IsBackstepping := True;
                     GameSpeed := gspPause;
                   end;
                 end;
      lka_InfiniteSkills: begin
                            HandleInfiniteSkillsHotkey;
                          end;
      lka_InfiniteTime: begin
                          HandleInfiniteTimeHotkey;
                        end;
      lka_Nuke: begin
                  // Double keypress needed to prevent accidently nuking
                  CurrTime := TimeGetTime;
                  if CurrTime - fLastNukeKeyTime < 250 then
                  begin
                    RegainControl;
                    SetSelectedSkill(spbNuke);
                  end else
                    fLastNukeKeyTime := CurrTime;
                end;
      lka_BypassNuke: begin
                        // Double keypress needed to prevent accidently nuking
                        CurrTime := TimeGetTime;
                        if CurrTime - fLastNukeKeyTime < 250 then
                        begin
                          RegainControl;
                          SetSelectedSkill(spbNuke, True, True);
                          GotoSaveState(Game.CurrentIteration, 0, Game.CurrentIteration - 85);
                        end else
                          fLastNukeKeyTime := CurrTime;
                      end;
      lka_CancelPlayback: begin
                            StopPlayback;
                            RegainControl(True);
                          end;
      lka_SaveState : if not GameParams.ClassicMode then
                      begin
                        fSaveStateFrame := fGame.CurrentIteration;
                        fSaveStateReplayStream.Clear;
                        Game.ReplayManager.SaveToStream(fSaveStateReplayStream, False, True);
                      end;
      lka_LoadState : if not GameParams.ClassicMode then
                      begin
                        if fSaveStateFrame <> -1 then
                        begin
                          fSaveList.ClearAfterIteration(0);
                          fSaveStateReplayStream.Position := 0;
                          Game.ReplayManager.LoadFromStream(fSaveStateReplayStream, True);
                          GotoSaveState(fSaveStateFrame, 1);

                          if not GameParams.ReplayAfterBackskip then
                            Game.RegainControl(True);
                        end;
                      end;
      lka_Cheat: begin
                   Game.Cheat;

                   if GameSpeed <> gspNormal then
                     GameSpeed := gspNormal;
                 end;
      lka_Turbo: begin
                   if Game.IsSuperLemmingMode then Exit;

                   Game.IsBackstepping := False;

                   if GameSpeed <> gspTurbo then
                     GameSpeed := gspTurbo
                   else
                     GameSpeed := gspNormal;
                 end;
      lka_FastForward: begin
                         if Game.IsSuperLemmingMode then Exit;

                         Game.IsBackstepping := False;

                         if GameSpeed <> gspFF then
                           GameSpeed := gspFF
                         else
                           GameSpeed := gspNormal;
                       end;
      lka_Rewind: begin
                    if Game.IsSuperLemmingMode then Exit;

                    // Cancel replay only when stopping Rewind in Classic Mode
                    if GameParams.ClassicMode and (GameSpeed = gspRewind) then
                      Game.RegainControl(True);

                    // Pressing Rewind fails the NoPause talisman (1 second grace at start of level)
                    if (Game.CurrentIteration > 17) then Game.PauseWasPressed := True;

                    if GameSpeed <> gspRewind then
                      GameSpeed := gspRewind
                    else
                      GameSpeed := gspNormal;
                  end;
      lka_SlowMotion: begin
                        if (GameParams.ClassicMode or Game.IsSuperLemmingMode) then Exit;

                        Game.IsBackstepping := False;

                        if GameSpeed <> gspSlowMo then
                          GameSpeed := gspSlowMo
                        else
                          GameSpeed := gspNormal;
                      end;
      lka_SaveImage: SaveShot;
      lka_LoadReplay: begin
                        if not (GameParams.ClassicMode or GameParams.PlaybackModeActive) then
                          LoadReplay;

                        if GlobalGame.ReplayManager.ReplayLoadSuccess then
                        begin
                          GameSpeed := gspNormal;
                          Game.IsBackstepping := False;
                          GotoSaveState(0, -1);
                          CanPlay := True;
                        end;
                      end;
      lka_Music: SoundManager.MuteMusic := not SoundManager.MuteMusic;
      lka_Restart: begin
                     SkillPanel.DrawButtonSelector(spbRestart, True);
                     GotoSaveState(0);

                     // Always reset these if user restarts
                     Game.PauseWasPressed := False;
                     Game.ReplayLoaded := False;

                     // Cancel replay if in Classic Mode or if Replay After Restart is deactivated
                     if GameParams.ClassicMode or not GameParams.ReplayAfterRestart then
                        Game.RegainControl(True);
                   end;
      lka_Sound: SoundManager.MuteSound := not SoundManager.MuteSound;
      lka_SaveReplay: if not GameParams.ClassicMode then SaveReplay;
      lka_SkillRight: begin
                        sn := GetSelectedSkill;
                        if (sn >= 0) and (sn < MAX_SKILL_TYPES_PER_LEVEL - 1) and (fActiveSkills[sn + 1] <> spbNone) then
                          SetSelectedSkill(fActiveSkills[sn + 1])
                        else if (sn > 0) then
                          SetSelectedSkill(fActiveSkills[0]);
                      end;
      lka_SkillLeft:  begin
                        sn := GetSelectedSkill;
                        if (sn > 0) and (fActiveSkills[sn - 1] <> spbNone) then
                          SetSelectedSkill(fActiveSkills[sn - 1])
                        else if (sn = 0) and (fActiveSkills[1] <> spbNone) then
                        begin
                          sn := MAX_SKILL_TYPES_PER_LEVEL - 1;
                          while fActiveSkills[sn] = spbNone do
                            Dec(sn);
                          SetSelectedSkill(fActiveSkills[sn]);
                        end;
                      end;
      lka_SkillButton: begin
                         ButtonIndex := func.Modifier -1;
                         AssignToHighlit := GameParams.Hotkeys.CheckForKey(lka_Highlight);

                         SetSelectedSkill(fActiveSkills[ButtonIndex], True, AssignToHighlit);
                       end;
      lka_Skip: if Game.Playing then
                  if not (GameParams.ClassicMode or Game.IsSuperLemmingMode) then
                  if func.Modifier < 0 then
                  begin
                    if CurrentIteration > (func.Modifier * -1) then
                    begin
                      Game.IsBackstepping := True;
                      GotoSaveState(CurrentIteration + func.Modifier);

                      if not GameParams.ReplayAfterBackskip then
                        Game.RegainControl(True);
                    end else begin
                      Game.IsBackstepping := False;
                      GotoSaveState(0);
                    end;
                  end else if func.Modifier > 1 then
                  begin
                    Game.IsBackstepping := False;
                    fHyperSpeedTarget := CurrentIteration + func.Modifier;
                  end else
                    if fGameSpeed = gspPause then fForceUpdateOneFrame := True;
      lka_SpecialSkip: HandleSpecialSkip(func.Modifier);
      lka_ClearPhysics: if not GameParams.ClassicMode then
              if func.Modifier = 0 then
                ClearPhysics := not ClearPhysics
              else
                ClearPhysics := True;
      lka_ShowUsedSkills: if func.Modifier = 0 then
                            SkillPanel.ShowUsedSkills := not SkillPanel.ShowUsedSkills
                          else
                            SkillPanel.ShowUsedSkills := True;
      lka_EditReplay: if not GameParams.ClassicMode then ExecuteReplayEdit;
      lka_ReplayInsert: if not GameParams.ClassicMode then Game.ReplayInsert := not Game.ReplayInsert;
      lka_ZoomIn: ChangeZoom(fInternalZoom + 1);
      lka_ZoomOut: ChangeZoom(fInternalZoom - 1);
      lka_Scroll: begin
                    CursorPointForm := ScreenToClient(Mouse.CursorPos);
                    if PtInRect(Img.BoundsRect, CursorPointForm) and not fHoldScrollData.Active then
                    begin
                      fHoldScrollData.Active := True;
                      fHoldScrollData.StartCursor := Mouse.CursorPos;
                    end;
                  end;
      lka_NudgeUp: ApplyScroll(0, -Abs(func.Modifier));
      lka_NudgeDown: ApplyScroll(0, Abs(func.Modifier));
      lka_NudgeLeft: ApplyScroll(-Abs(func.Modifier), 0);
      lka_NudgeRight: ApplyScroll(Abs(func.Modifier), 0);
    end;
  end;

  CheckShifts(Shift);

  // If ForceUpdateOneFrame is active, screen will be redrawn soon enough anyway
  if (fGameSpeed = gspPause) and not fForceUpdateOneFrame then
    DoDraw;
end;

procedure TGameWindow.HandleSpecialSkip(aSkipType: Integer);
var
  i: Integer;
  TargetFrame: Integer;
  HasSuitableSkill: Boolean;
begin
  if not (GameParams.ClassicMode or Game.IsSuperLemmingMode) then
  begin
    TargetFrame := 0; // Fallback
    fSpecialStartIteration := Game.CurrentIteration;

    case TSpecialSkipCondition(aSkipType) of
      ssc_LastAction: begin
                        if (Game.ReplayManager.LastActionFrame = -1) then Exit;

                        if Game.CurrentIteration > Game.ReplayManager.LastActionFrame then
                          TargetFrame := Game.ReplayManager.LastActionFrame
                        else
                          for i := 0 to Game.CurrentIteration do
                            if Game.ReplayManager.HasAnyActionAt(i) then
                              TargetFrame := i;

                        Game.IsBackstepping := True;
                        GotoSaveState(Max(TargetFrame, 0));

                        if not GameParams.ReplayAfterBackskip then
                          Game.RegainControl(True);
                     end;
      ssc_NextShrugger: begin
                          HasSuitableSkill := False;
                          for i := 0 to fRenderInterface.LemmingList.Count-1 do
                          begin
                            if fRenderInterface.LemmingList[i].LemRemoved then Continue;

                            if fRenderInterface.LemmingList[i].LemAction in [baBuilding, baPlatforming, baStacking] then
                            begin
                              HasSuitableSkill := True;
                              Break;
                            end;
                          end;
                          if not HasSuitableSkill then Exit;

                          fHyperSpeedStopCondition := SHE_SHRUGGER;
                          GameSpeed := gspPause;
                        end;
      ssc_HighlitStateChange: begin
                                if (fRenderInterface = nil) or (fRenderInterface.HighlitLemming = nil) then Exit;
                                fHighlitStartCopyLemming.Assign(fRenderInterface.HighlitLemming);
                                fHyperSpeedStopCondition := SHE_HIGHLIT;
                                GameSpeed := gspPause;
                              end;
    end;
  end;
end;

procedure TGameWindow.Form_KeyPress(Sender: TObject; var Key: Char);
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
      lka_ClearPhysics       : if func.Modifier <> 0 then
                                 ClearPhysics := False;
      lka_ShowUsedSkills     : if func.Modifier <> 0 then
                                 SkillPanel.ShowUsedSkills := False;
    end;
  end;

  CheckShifts(Shift);

  SkillPanel.RemoveButtonHighlights;
  SkillPanel.RRIsPressed := False;
end;

procedure TGameWindow.SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
{-------------------------------------------------------------------------------
  convert the normal hotspot to the hotspot the game uses (4,9 instead of 7,7)
-------------------------------------------------------------------------------}
var
  NewPoint: TPoint;
begin
  NewPoint := Point(BitmapPoint.X - 3, BitmapPoint.Y + 2);
  if GameParams.HighResolution then
  begin
    NewPoint.X := NewPoint.X div 2;
    NewPoint.Y := NewPoint.Y div 2;
  end;
  Game.CursorPoint := NewPoint;
end;

procedure TGameWindow.Img_MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
                        Main mouse input handling method
-------------------------------------------------------------------------------}
var
  PassKey: Word;
  OldHighlightLemming: TLemming;
  InTestMode: Boolean;
  RMBUnassigned, Paused, InClassicModes: Boolean;
  CtrlPressed, ShiftPressed, AltPressed: Boolean;
begin
  if (not fMouseTrapped) and (not fSuspendCursor) and GameParams.EdgeScroll then
    ApplyMouseTrap;

  // Interrupting hyperspeed can break the handling of savestates so we're not allowing it
  if Game.Playing and not IsHyperSpeed then
  begin
    SetAdjustedGameCursorPoint(Img.ControlToBitmap(Point(X, Y)));

    CheckShifts(Shift);

    { Middle or Right clicks get passed to the keyboard handler, because their
     handling has more in common with that than with mouse handling }
    PassKey := 0;
    if (Button = mbMiddle) then
      PassKey := $04
    else if (Button = mbRight) then
      PassKey := $02;

    if PassKey <> 0 then
      Form_KeyDown(Sender, PassKey, Shift);

    // Set conditions
    CtrlPressed    := ssCtrl in Shift;
    ShiftPressed   := ssShift in Shift;
    AltPressed     := ssAlt in Shift;
    RMBUnassigned  := HotkeyManager.CheckKeyAssigned(lka_Null, 2);
    Paused         := GameSpeed = gspPause;
    InClassicModes := GameParams.ClassicMode or Game.IsSuperlemmingMode;
    InTestMode     := {$ifdef debug} True {$else} GameParams.TestModeLevel <> nil {$endif};

    // ================== Left Mouse Button ===================== //
    if (Button = mbLeft) and not Game.IsHighlightHotkey then
    begin
      Game.RegainControl;

      // Hold Ctrl to generate a new lem at cursor (test/debug mode only)
      if CtrlPressed and InTestMode then
      begin
        Game.GenerateNewLemming(X, Y, True, ShiftPressed, AltPressed)
      end else
      // Assign skill
      begin
        if not (Paused and InClassicModes) then
          Game.ProcessSkillAssignment;
      end;

      // Step forward one frame
      if Paused and not InClassicModes then
        fForceUpdateOneFrame := True;
    end else

    // ================== Right Mouse Button ===================== //
    if (Button = mbRight) and not Game.IsHighlightHotkey then
    begin
      // Hold Ctrl to generate a new lem at cursor (test/debug mode only)
      if CtrlPressed and InTestMode then
      begin
        Game.GenerateNewLemming(X, Y, False, ShiftPressed, AltPressed)
      end else
      if RMBUnassigned and not InClassicModes then
      // Step backward one frame
      begin
        Game.IsBackstepping := True;
        GoToSaveState(Max(Game.CurrentIteration -1, 0));
      end;
    end;

    // Check for highlight hotkey to assign skills to highlit lemmings
    if Game.IsHighlightHotkey then
    begin
      OldHighlightLemming := fRenderInterface.HighlitLemming;

      // Assign skill to highlit lemming by clicking the skill button
      Game.ProcessHighlightAssignment;

      if fRenderInterface.HighlitLemming <> OldHighlightLemming then
        SoundManager.PlaySound(SFX_SkillButton);
    end;

    if Paused then
      DoDraw;

    fLastMousePress := GetTickCount;
  end;
end;

procedure TGameWindow.Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  SkillPanel.MinimapScrollFreeze := False;
end;

procedure TGameWindow.Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Game.Playing then
  begin
    CheckShifts(Shift);

    SetAdjustedGameCursorPoint(Img.ControlToBitmap(Point(X, Y)));

    if (fGameSpeed = gspPause) or (Game.HitTestAutoFail) then
    begin
      Game.HitTest;
      CheckResetCursor;
    end;

    Game.HitTestAutoFail := not PtInRect(Rect(0, 0, Img.Width, Img.Height), Point(X, Y));

    SkillPanel.MinimapScrollFreeze := False;

    if fGameSpeed = gspPause then
    begin
      if fRenderInterface.UserHelper <> hpi_None then
        SetRedraw(rdRedraw);
    end;
  end;
end;

procedure TGameWindow.Img_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  CheckShifts(Shift);
  fMouseClickFrameskip := GetTickCount;
end;

procedure TGameWindow.InitializeCursor;
var
  LocalMaxZoom: Integer;
  i, i2: Integer;
  TempBMP, TempBMP2: TBitmap32;
  SL: TStringList;
  CursorDir, FileExt: String;
const
  CURSOR_NAMES: array[1..CURSOR_TYPES] of String = (
    'standard',                               // 1
    'focused',                                // 2
    'standard_replay',                        // 3
    'focused_replay',                         // 4
    'standard_replay_insert',                 // 5
    'focused_replay_insert',                  // 6
    'standard_playback',                      // 7
    'focused_playback',                       // 8
    'standard|direction_left',                // 1 + 8
    'focused|direction_left',                 // 2 + 8
    'standard_replay|direction_left',         // 3 + 8
    'focused_replay|direction_left',          // 4 + 8
    'standard_replay_insert|direction_left',  // 5 + 8
    'focused_replay_insert|direction_left',   // 6 + 8
    'standard_playback|direction_left',       // 7 + 8
    'focused_playback|direction_left',        // 8 + 8
    'standard|direction_right',               // 1 + 16
    'focused|direction_right',                // 2 + 16
    'standard_replay|direction_right',        // 3 + 16
    'focused_replay|direction_right',         // 4 + 16
    'standard_replay_insert|direction_right', // 5 + 16
    'focused_replay_insert|direction_right',  // 6 + 16
    'standard_playback|direction_right',      // 7 + 16
    'focused_playback|direction_right'        // 8 + 16
  );
begin
  FreeCursors;

  LocalMaxZoom := Min(Screen.Width div 320, (Screen.Height - (80 * Round(SkillPanel.ResizePercentage))) div 160) + EXTRA_ZOOM_LEVELS;

  TempBMP := TBitmap32.Create;
  TempBMP2 := TBitmap32.Create;
  SL := TStringList.Create;
  try
    SL.Delimiter := '|';

    for i := 1 to CURSOR_TYPES do
    begin
      Cursors[i].Free;

      Cursors[i] := TNLCursor.Create(LocalMaxZoom);

      SL.DelimitedText := CURSOR_NAMES[i];

      // Get Amiga cursor for just the first 2 types only
      if GameParams.AmigaTheme and (i in [1, 2]) then
        CursorDir := SFGraphicsCursor + 'amiga/'
      else
        CursorDir := SFGraphicsCursor;

      if GameParams.HighResolution then
        FileExt := '-hr.png'
      else
        FileExt := '.png';

      TPngInterface.LoadPngFile(AppPath + CursorDir + SL[0] + FileExt, TempBMP);

      while SL.Count > 1 do
      begin
        SL.Delete(0);
        TPngInterface.LoadPngFile(AppPath + CursorDir + SL[0] + FileExt, TempBMP2);
        TempBMP2.DrawMode := dmBlend;
        TempBMP2.CombineMode := cmMerge;
        TempBMP.Draw(TempBMP.BoundsRect, TempBMP2.BoundsRect, TempBMP2);
      end;

      Cursors[i].LoadFromBitmap(TempBMP);

      for i2 := 0 to LocalMaxZoom-1 do
        Screen.Cursors[(i2 * CURSOR_TYPES) + i] := Cursors[i].GetCursor(i2 + 1);
    end;
  finally
    TempBMP.Free;
    TempBMP2.Free;
    SL.Free;
  end;
end;


procedure TGameWindow.PrepareGameParams;
{-------------------------------------------------------------------------------
  This method is called by the inherited ShowScreen
-------------------------------------------------------------------------------}
var
  Sca: Integer;
  HorzStart, VertStart: Integer;
begin
  inherited;

  fMaxZoom := Min(Screen.Width div 320 div ResMod, Screen.Height div 200 div ResMod) + EXTRA_ZOOM_LEVELS;

  if GameParams.IncreaseZoom then
  begin
    Sca := 2;
    while (Min(Sca, Round(SkillPanel.ResizePercentage)) * 80) + (Max(GameParams.Level.Info.Height, 160) * Sca * ResMod) <= ClientHeight do
      Inc(Sca);
    Dec(Sca);
    Sca := Max(Sca, GameParams.ZoomLevel);
  end else
    Sca := GameParams.ZoomLevel;

  Sca := Max(Min(Sca, fMaxZoom), 1);

  fInternalZoom := Sca;
  GameParams.TargetBitmap := Img.Bitmap;
  GameParams.TargetBitmap.SetSize(GameParams.Level.Info.Width * ResMod, GameParams.Level.Info.Height * ResMod);
  fGame.PrepareParams;

  // Set timers
  IdealScrollTimeMS := 15;
  IdealFrameTimeMS := 60; // Normal
  IdealFrameTimeMSSlow := 240;
  IdealFrameTimeSuper := 20;

  Img.Scale := Sca;

  SkillPanel.PrepareForGame;

  fMinimapBuffer.SetSize(GameParams.Level.Info.Width * ResMod, GameParams.Level.Info.Height * ResMod);

  ChangeZoom(Sca, True);

  if GameParams.Level.Info.ScreenStartAuto then
    GameParams.Level.CalculateAutoScreenStart(HorzStart, VertStart)
  else begin
    HorzStart := GameParams.Level.Info.ScreenStartX;
    VertStart := GameParams.Level.Info.ScreenStartY;
  end;

  HorzStart := (HorzStart * ResMod) - ((Img.Width div 2) div Sca);
  VertStart := (VertStart * ResMod) - ((Img.Height div 2) div Sca);

  HorzStart := HorzStart * Sca;
  VertStart := VertStart * Sca;
  Img.OffsetHorz := Min(Max(-HorzStart, MinScroll), MaxScroll);
  Img.OffsetVert := Min(Max(-VertStart, MinVScroll), MaxVScroll);

  InitializeCursor;
  if GameParams.EdgeScroll then ApplyMouseTrap;

  fRenderer := GameParams.Renderer;
  fRenderInterface := Game.RenderInterface;
  fRenderer.SetInterface(fRenderInterface);

  if FileExists(AppPath + SFMusic + GetLevelMusicName + SoundManager.FindExtension(GetLevelMusicName, True)) and
    not (GameParams.DisableMusicInTestplay and (GameParams.TestModeLevel <> nil)) then
    SoundManager.LoadMusicFromFile(GetLevelMusicName)
  else
    SoundManager.FreeMusic; // This is safe to call even if no music is loaded, but ensures we don't just get the previous level's music
end;

procedure TGameWindow.SkillPanel_MinimapClick(Sender: TObject; const P: TPoint);
{-------------------------------------------------------------------------------
  This method is an eventhandler (TSkillPanel.OnMiniMapClick),
  called when user clicks in the minimap-area of the skillpanel.
  Here we scroll the game-image.
-------------------------------------------------------------------------------}
var
  O: Single;
begin
  if not GameParams.ShowMinimap then Exit;

  O := -P.X * 8 * fInternalZoom;
  O :=  O + Img.Width div 2;
  if O < MinScroll then O := MinScroll;
  if O > MaxScroll then O := MaxScroll;
  Img.OffSetHorz := O;

  O := -P.Y * 8 * fInternalZoom;
  O :=  O + Img.Height div 2;
  if O < MinVScroll then O := MinVScroll;
  if O > MaxVScroll then O := MaxVScroll;
  Img.OffsetVert := O;

  SetRedraw(rdRefresh);
end;

procedure TGameWindow.Form_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  GameScroll := gsNone;
end;

procedure TGameWindow.CheckAdjustSpawnInterval;
{-------------------------------------------------------------------------------
  In the mainloop the decision is made if we really have to update
-------------------------------------------------------------------------------}
begin
  Game.CheckAdjustSpawnInterval;
end;

function TGameWindow.CheckHighlitLemmingChange: Boolean;
var
  aL, sL: TLemming; // "actual lemming", "start lemming"
  Act1, Act2: TBasicLemmingAction;
  n: Integer;
const
  COMPATIBLE_ACTIONS: array[0..8] of array[0..1] of TBasicLemmingAction =
    ((baWalking, baAscending),
     (baDehoisting, baSliding),
     (baClimbing, baHoisting),
     (baFalling, baFloating),
     (baFalling, baGliding),
     (baOhnoing, baExploding),
     (baTimebombing, baTimebombFinish),
     (baFreezing, baFreezerExplosion),
     (baReaching, baShimmying)
    );

  TREAT_AS_WALKING_ACTIONS = [baShrugging, baLooking, baToWalking, baCloning];
begin
  Result := True;

  if fRenderInterface = nil then Exit;

  sL := fHighlitStartCopyLemming;
  aL := fRenderInterface.HighlitLemming;

  if (sL = nil) or (aL = nil) then Exit; // Just in case

  if aL.LemRemoved then Exit;

  if sL.LemIsZombie <> aL.LemIsZombie then Exit;

  if (sL.LemAction <> aL.LemAction) then
  begin
    Result := True;

    Act1 := sL.LemAction;
    Act2 := aL.LemAction;

    if Act1 in TREAT_AS_WALKING_ACTIONS then Act1 := baWalking;
    if Act2 in TREAT_AS_WALKING_ACTIONS then Act2 := baWalking;

    for n := 0 to Length(COMPATIBLE_ACTIONS)-1 do
      if ((Act1 = COMPATIBLE_ACTIONS[n][0]) and (Act2 = COMPATIBLE_ACTIONS[n][1])) or
         ((Act2 = COMPATIBLE_ACTIONS[n][0]) and (Act1 = COMPATIBLE_ACTIONS[n][1])) then
    begin
      Result := False;
      Break;
    end;
  end else
    Result := False;
end;

procedure TGameWindow.SuspendGameplay;
var
  NewSuspendState: TSuspendState;
begin
  NewSuspendState.OldSpeed := GameSpeed;
  NewSuspendState.OldCanPlay := CanPlay;
  fSuspensions.Insert(0, NewSuspendState);

  GameSpeed := gspPause;
  CanPlay := False;
  fSuspendCursor := True;
  ReleaseMouse(True);
end;

procedure TGameWindow.ResumeGameplay;
var
  SuspendState: TSuspendState;
begin
  if fSuspensions.Count = 0 then Exit;
  SuspendState := fSuspensions[0];
  fSuspensions.Delete(0);

  GameSpeed := SuspendState.OldSpeed;
  CanPlay := SuspendState.OldCanPlay;

  if fSuspensions.Count = 0 then
  begin
    fSuspendCursor := False;
    ApplyMouseTrap;
  end;
end;

procedure TGameWindow.SaveReplay;
var
  s: String;
begin
  SuspendGameplay;
  try
    Game.EnsureCorrectReplayDetails;
    s := Game.ReplayManager.GetSaveFileName(Self, rsoIngame, Game.ReplayManager);
    if s = '' then Exit;
    Game.ReplayManager.SaveToFile(s);
  finally
    ResumeGameplay;
  end;
end;

procedure TGameWindow.SaveShot;
var
  Dlg : TSaveDialog;
  SaveName: String;
  BMP: TBitmap32;
begin
  SuspendGameplay;
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := 'PNG Image (*.png)|*.png';
    Dlg.FilterIndex := 1;
    Dlg.InitialDir := '"' + ExtractFilePath(Application.ExeName) + '/"';
    Dlg.DefaultExt := '.png';
    Dlg.Options := [ofOverwritePrompt, ofEnableSizing];
    if Dlg.Execute then
    begin
      SaveName := Dlg.FileName;
      BMP := TBitmap32.Create;
      BMP.SetSize(GameParams.Level.Info.Width * ResMod, GameParams.Level.Info.Height * ResMod);

      fRenderer.DrawAllGadgets(fRenderInterface.Gadgets, True, fClearPhysics);
      fRenderer.DrawLemmings(fClearPhysics);
      fRenderer.DrawProjectiles;
      fRenderer.DrawLevel(BMP, fClearPhysics);

      TPngInterface.SavePngFile(SaveName, BMP, True);

      BMP.Free;
    end;
  finally
    Dlg.Free;
    ResumeGameplay;
  end;
end;


procedure TGameWindow.Game_Finished;
begin
  SoundManager.StopMusic;

  if (Game.CheckPass and (Game.Level.PostText.Count > 0))
    and not (GameParams.PlaybackModeActive and GameParams.AutoSkipPreviewPostview) then
      fCloseToScreen := gstText
    else
      fCloseToScreen := gstPostview;
end;

procedure TGameWindow.CloseScreen(aNextScreen: TGameScreenType);
var
  S: String;
begin
  CanPlay := False;
  Application.OnIdle := nil;
  ClipCursor(nil);
  fSuspendCursor := True;
  Cursor := crNone;
  Screen.Cursor := crNone;
  Img.Cursor := crNone;
  SkillPanel.SetCursor(crNone);

  Game.SetGameResult;
  GameParams.GameResult := Game.GameResultRec;
  with GameParams, GameResult do
  begin
    if gCheated then
    begin
      GameParams.NextLevel(True);
      GameParams.ShownText := False;
      aNextScreen := gstPreview;
    end;

    if (GameParams.AutoSaveReplay) and (Game.ReplayManager.IsModified) and (GameParams.GameResult.gSuccess) and not (GameParams.GameResult.gCheated) then
    begin
      Game.EnsureCorrectReplayDetails;
      S := Game.ReplayManager.GetSaveFileName(Self, rsoAuto, Game.ReplayManager);
      ForceDirectories(ExtractFilePath(S));
      Game.ReplayManager.SaveToFile(S, True);
    end;
  end;

  inherited CloseScreen(aNextScreen);
end;

procedure TGameWindow.AddSaveState;
begin
  fGame.CreateSavedState(fSaveList.Add);
end;

function TGameWindow.ScreenImage: TImage32;
begin
  Result := ScreenImg;
end;

function TGameWindow.GetDisplayWidth: Integer;
begin
  Result := (Img.Width div fInternalZoom);
end;

function TGameWindow.GetDisplayHeight: Integer;
begin
  Result := Img.Height div fInternalZoom;
end;

procedure TGameWindow.SetForceUpdateOneFrame(aValue: Boolean);
begin
  fForceUpdateOneFrame := aValue;
end;

procedure TGameWindow.SetHyperSpeedTarget(aValue: Integer);
begin
  fHyperSpeedTarget := aValue;
end;


procedure TGameWindow.SetProjectionType(aValue: Integer);
begin
  if fProjectionType <> aValue then
  begin
    fProjectionType := aValue;
    if fRenderInterface <> nil then
      fRenderInterface.ProjectionType := aValue;

    Game.CheckForNewShadow(True);
  end;
end;

procedure TGameWindow.SetRedraw(aRedraw: TRedrawOption);
begin
  if (fNeedRedraw = rdNone) or (aRedraw = rdRedraw) then
    fNeedRedraw := aRedraw;
end;

// Mouse performs repeated forwards and backwards frameskips when held
function TGameWindow.MouseFrameSkip: Integer;
var
  RightMouseUnassigned: Boolean;
begin
  Result := 0;

  // Make sure the window is focused and the mouse is in the gameplay area
  if (FindControl(GetForegroundWindow()) = nil) or (fSuspendCursor)
    or (GameParams.EdgeScroll and not fMouseTrapped) then Exit;

  if (GameParams.ClassicMode or Game.IsSuperLemmingMode) then Exit;

  if GetTickCount - fMouseClickFrameskip < 650 then Exit;

  // We need to make sure the right mouse button is unassigned
  RightMouseUnassigned := HotkeyManager.CheckKeyAssigned(lka_Null, 2);

  if (GameSpeed = gspPause) and not SkillPanel.CursorOverClickableItem then
  begin
    if (GetKeyState(VK_LBUTTON) < 0) and (GetKeyState(VK_RBUTTON) >= 0) then
    begin
      if GetTickCount - fLastMousePress > 650 then
      begin
        Result := 1;
        fMouseClickFrameskip := GetTickCount - 500;
      end;
    end
    else if (GetKeyState(VK_RBUTTON) < 0) and (GetKeyState(VK_LBUTTON) >= 0)
    and RightMouseUnassigned then
    begin
      if GetTickCount - fLastMousePress > 650 then
      begin
        Result := -1;
        fMouseClickFrameskip := GetTickCount - 500;
      end;
    end;
  end;
end;

end.
