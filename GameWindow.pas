{$include lem_directives.inc}

unit GameWindow;

interface

uses
  System.Types,
  PngInterface,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, MMSystem, Forms, SysUtils, Dialogs, Math, ExtCtrls, StrUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  LemCore, LemLevel, LemRendering, LemRenderHelpers,
  LemGame, LemGameMessageQueue,
  GameSound, LemTypes, LemStrings, LemLemming,
  LemCursor,
  GameControl, GameBaseSkillPanel, GameSkillPanel, GameBaseScreen,
  GameWindowInterface;

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
   rdNone,    // no forced redraw is needed
   rdRefresh, // needs to update (eg. from scrolling) but not fully redrawn
   rdRedraw   // needs to redraw completely
  );

  THoldScrollData = record
    Active: Boolean;
    StartCursor: TPoint;
    //StartImg: TFloatPoint;
  end;

const
  CURSOR_TYPES = 6;
  EXTRA_ZOOM_LEVELS = 4;

  // special hyperspeed ends. usually only needed for forwards ones, backwards can often get the exact frame.
  SHE_SHRUGGER = 1;

type
  TGameWindow = class(TGameBaseScreen, IGameWindow)
  private
    fSaveStateReplayStream: TMemoryStream;
    fCloseToScreen: TGameScreenType;
    fSuspendCursor: Boolean;
    fClearPhysics: Boolean;
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
    fGameSpeed: TGameSpeed;               // do NOT set directly, set via GameSpeed property
    fHyperSpeedStopCondition: Integer;
    fHyperSpeedTarget: Integer;
    fForceUpdateOneFrame: Boolean;        // used when paused
    fLastZombieSound: Cardinal;

    fHoldScrollData: THoldScrollData;

  { game eventhandler}
    procedure Game_Finished;
  { self eventhandlers }
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
    procedure ReleaseMouse;
    procedure CheckResetCursor(aForce: Boolean = false);
    function CheckScroll: Boolean;
    procedure AddSaveState;
    procedure CheckAdjustSpawnInterval;
    procedure SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
    procedure StartReplay2(const aFileName: string);
    procedure InitializeCursor;
    procedure CheckShifts(Shift: TShiftState);
    procedure CheckUserHelpers;
    procedure DoDraw;
    procedure OnException(E: Exception; aCaller: String = 'Unknown');
    procedure ExecuteReplayEdit;
    procedure SetClearPhysics(aValue: Boolean);
    function GetClearPhysics: Boolean;
    procedure ProcessGameMessages;
    procedure ApplyResize(NoRecenter: Boolean = false);
    procedure ChangeZoom(aNewZoom: Integer; NoRedraw: Boolean = false);
    procedure FreeCursors;
    procedure HandleSpecialSkip(aSkipType: Integer);

    function GetLevelMusicName: String;
    function GetIsHyperSpeed: Boolean;

    procedure SetGameSpeed(aValue: TGameSpeed);
    function GetGameSpeed: TGameSpeed;
    function GetDisplayWidth: Integer;  // to satisfy IGameWindow
    function GetDisplayHeight: Integer; // to satisfy IGameWindow
  protected
    fGame                : TLemmingGame;      // reference to globalgame gamemechanics
    Img                  : TImage32;          // the image in which the level is drawn (reference to inherited ScreenImg!)
    SkillPanel           : TBaseSkillPanel;   // our good old dos skill panel (now improved!)
    fActivateCount       : Integer;           // used when activating the form
    GameScroll           : TGameScroll;       // scrollmode
    GameVScroll          : TGameScroll;
    IdealFrameTimeMS     : Cardinal;          // normal frame speed in milliseconds
    IdealFrameTimeMSFast : Cardinal;          // fast forward framespeed in milliseconds
    IdealScrollTimeMS    : Cardinal;          // scroll speed in milliseconds
    PrevCallTime         : Cardinal;          // last time we did something in idle
    PrevScrollTime       : Cardinal;          // last time we scrolled in idle
    PrevPausedRRTime     : Cardinal;          // last time we updated RR in idle
    MouseClipRect        : TRect;             // we clip the mouse when there is more space
    CanPlay              : Boolean;           // use in idle en set to false whenever we don't want to play
    Cursors              : array[1..CURSOR_TYPES] of TNLCursor;
    MinScroll            : Single;            // scroll boundary for image
    MaxScroll            : Single;            // scroll boundary for image
    MinVScroll           : Single;
    MaxVScroll           : Single;
    fSaveStateFrame      : Integer;      // list of savestates (only first is used)
    fLastNukeKeyTime     : Cardinal;
    fScrollSpeed         : Integer;
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
    procedure GotoSaveState(aTargetIteration: Integer; PauseAfterSkip: Integer = 0);
    procedure LoadReplay;
    procedure SaveReplay;
    procedure RenderMinimap;
    procedure MainFormResized; override;
    procedure SetCurrentCursor(aCursor: Integer = 0); // 0 = autodetect correct graphic
    property HScroll: TGameScroll read GameScroll write GameScroll;
    property VScroll: TGameScroll read GameVScroll write GameVScroll;
    property ClearPhysics: Boolean read fClearPhysics write SetClearPhysics;
    function DoSuspendCursor: Boolean;

    property GameSpeed: TGameSpeed read GetGameSpeed write SetGameSpeed;
    property HyperSpeedTarget: Integer read fHyperSpeedTarget write fHyperSpeedTarget;
    property IsHyperSpeed: Boolean read GetIsHyperSpeed;

    function ScreenImage: TImage32; // to staisfy IGameWindow, should be moved to TGameBaseScreen, but it causes bugs there.
    property DisplayWidth: Integer read GetDisplayWidth; // to staisfy IGameWindow
    property DisplayHeight: Integer read GetDisplayHeight; // to staisfy IGameWindow
    procedure SetForceUpdateOneFrame(aValue: Boolean);  // to satisfy IGameWindow
    procedure SetHyperSpeedTarget(aValue: Integer);     // to satisfy IGameWindow

  end;

implementation

uses FBaseDosForm, FEditReplay, LemReplay, LemNeoLevelPack;

{ TGameWindow }

procedure TGameWindow.SetGameSpeed(aValue: TGameSpeed);
begin
  fGameSpeed := aValue;
  SkillPanel.DrawButtonSelector(spbPause, fGameSpeed = gspPause);
  SkillPanel.DrawButtonSelector(spbFastForward, fGameSpeed = gspFF);
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

  Handled := true;
end;

procedure TGameWindow.MainFormResized;
begin
  ApplyResize;
  DoDraw;
end;

procedure TGameWindow.ChangeZoom(aNewZoom: Integer; NoRedraw: Boolean = false);
var
  OSHorz, OSVert: Single;
  DoZoomOnCursor: Boolean;

  procedure SetCursorToCenter();
  var
    MousePos, ImgCenter: TPoint;
    ImgTopLeft, ImgBottomRight: TPoint;
  begin
    // Clip the Mouse position to the Image rectangle
    MousePos := Mouse.CursorPos;
    ImgTopLeft := Img.ClientToScreen(Point(0, 0));
    ImgBottomRight := Img.ClientToScreen(Point(Img.Width, Img.Height));
    MousePos.X := Max(Min(Mouse.CursorPos.X, ImgBottomRight.X), ImgTopLeft.X);
    MousePos.Y := Max(Min(Mouse.CursorPos.Y, ImgBottomRight.Y), ImgTopLeft.Y);
    // Get center of the image on the screen
    ImgCenter := Point(Trunc((ImgTopLeft.X + ImgBottomRight.X) / 2), Trunc((ImgTopLeft.Y + ImgBottomRight.Y) / 2));
    // Move the image location
    Img.OffsetHorz := Img.OffsetHorz - (MousePos.X - ImgCenter.X);
    Img.OffsetVert := Img.OffsetVert - (MousePos.Y - ImgCenter.Y);
  end;

  procedure ResetCenterToCursor();
  var
    MousePos, ImgCenter: TPoint;
    ImgTopLeft, ImgBottomRight: TPoint;
  begin
    // Clip the Mouse position to the Image rectangle
    MousePos := Mouse.CursorPos;
    ImgTopLeft := Img.ClientToScreen(Point(0, 0));
    ImgBottomRight := Img.ClientToScreen(Point(Img.Width, Img.Height));
    MousePos.X := Max(Min(Mouse.CursorPos.X, ImgBottomRight.X), ImgTopLeft.X);
    MousePos.Y := Max(Min(Mouse.CursorPos.Y, ImgBottomRight.Y), ImgTopLeft.Y);
    // Get center of the image on the screen
    ImgCenter := Point(Trunc((ImgTopLeft.X + ImgBottomRight.X) / 2), Trunc((ImgTopLeft.Y + ImgBottomRight.Y) / 2));
    // Move the image location
    Img.OffsetHorz := Img.OffsetHorz + (MousePos.X - ImgCenter.X);
    Img.OffsetVert := Img.OffsetVert + (MousePos.Y - ImgCenter.Y);
  end;

begin
  aNewZoom := Max(Min(fMaxZoom, aNewZoom), 1);
  if (aNewZoom = fInternalZoom) and not NoRedraw then
    Exit;

  DoZoomOnCursor := (aNewZoom > fInternalZoom);
  Img.BeginUpdate;
  SkillPanel.Image.BeginUpdate;
  try
    // If scrolling in, move the image to center on the cursor position.
    // We will ensure that this is a valid position later on.
    if DoZoomOnCursor then SetCursorToCenter;

    // Switch to top left coordinates, not the center of the image.
    OSHorz := Img.OffsetHorz - (Img.Width / 2);
    OSVert := Img.OffsetVert - (Img.Height / 2);
    OSHorz := (OSHorz * aNewZoom) / fInternalZoom;
    OSVert := (OSVert * aNewZoom) / fInternalZoom;

    Img.Scale := aNewZoom;

    if (aNewZoom >= GameParams.ZoomLevel) or NoRedraw then // NoRedraw is only true during the call at a start of gameplay
      SkillPanel.Zoom := aNewZoom;

    fInternalZoom := aNewZoom;

    // Change the Img size and update everything accordingly.
    ApplyResize(true);

    // If scrolling in, we wish to keep the pixel below the cursor constant.
    // Therefore we have to move the current center back to the cursor position
    if DoZoomOnCursor then ResetCenterToCursor;

    // Move back to center coordinates.
    OSHorz := OSHorz + (Img.Width / 2);
    OSVert := OSVert + (Img.Height / 2);
    // Ensure that the offset doesn't move part of the visible area outside of the level area.
    Img.OffsetHorz := Min(Max(OSHorz, MinScroll), MaxScroll);
    Img.OffsetVert := Min(Max(OSVert, MinVScroll), MaxVScroll);

    fNeedRedraw := rdRedraw;
    CheckResetCursor(true);
  finally
    Img.EndUpdate;
    SkillPanel.Image.EndUpdate;
  end;
end;

procedure TGameWindow.ApplyResize(NoRecenter: Boolean = false);
var
  OSHorz, OSVert: Single;

  VertOffset: Integer;
begin
  OSHorz := Img.OffsetHorz - (Img.Width / 2);
  OSVert := Img.OffsetVert - (Img.Height / 2);

  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;

  SkillPanel.Zoom := Max(SkillPanel.Zoom, fInternalZoom); // this checks for MaxZoom automatically.

  Img.Width := Min(ClientWidth, GameParams.Level.Info.Width * fInternalZoom);
  Img.Height := Min(ClientHeight - (SkillPanel.Zoom * 40), GameParams.Level.Info.Height * fInternalZoom);
  Img.Left := (ClientWidth - Img.Width) div 2;
  SkillPanel.Left := (ClientWidth - SkillPanel.Width) div 2;
  // tops are calculated later

  VertOffset := (ClientHeight - ((SkillPanel.Zoom * 40) + Img.Height)) div 2;
  Img.Top := VertOffset;
  SkillPanel.Top := Img.Top + Img.Height;
  SkillPanel.Height := Max(SkillPanel.Zoom * 40, ClientHeight - SkillPanel.Top);
  SkillPanel.Image.Left := (ClientWidth - SkillPanel.Image.Width) div 2;
  SkillPanel.Image.Update;

  MinScroll := -((GameParams.Level.Info.Width * fInternalZoom) - Img.Width);
  MaxScroll := 0;

  MinVScroll := -((GameParams.Level.Info.Height * fInternalZoom) - Img.Height);
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
  Result := true;
end;

function TGameWindow.GetLevelMusicName: String;
var
  MusicName: String;
  MusicIndex: Integer;
  SL: TStringList;
  i: Integer;
begin
  MusicName := ChangeFileExt(GameParams.Level.Info.MusicFile, '');

  if (MusicName <> '') and (LeftStr(MusicName, 1) <> '?') then
    if SoundManager.FindExtension(MusicName, true) <> '' then
    begin
      Result := MusicName;
      Exit;
    end;

  if LeftStr(MusicName, 1) = '?' then
    MusicIndex := StrToIntDef(RightStr(MusicName, Length(MusicName)-1), -1)
  else
    MusicIndex := -1;

  SL := GameParams.CurrentLevel.Group.MusicList;

  if MusicIndex = -1 then
    if GameParams.TestModeLevel <> nil then
      MusicIndex := Random(SL.Count)
    else begin
      MusicIndex := GameParams.CurrentLevel.GroupIndex;

      for i := 0 to GameParams.CurrentLevel.Group.ParentGroupIndex-1 do
        MusicIndex := MusicIndex + GameParams.CurrentLevel.Group.Parent.Children[i].LevelCount;
    end;

  if SL.Count > 0 then
    Result := SL[MusicIndex mod SL.Count];
end;

procedure TGameWindow.SetClearPhysics(aValue: Boolean);
begin
  fClearPhysics := aValue;
  if fGameSpeed = gspPause then
    fNeedRedraw := rdRedraw;
  SkillPanel.DrawButtonSelector(spbClearPhysics, fClearPhysics);
end;

function TGameWindow.GetClearPhysics: Boolean;
begin
  Result := fClearPhysics;
end;

procedure TGameWindow.RenderMinimap;
begin
  if GameParams.MinimapHighQuality then
  begin
    fMinimapBuffer.Clear(0);
    Img.Bitmap.DrawTo(fMinimapBuffer);
    SkillPanel.Minimap.Clear(0);
    fMinimapBuffer.DrawTo(SkillPanel.Minimap, SkillPanel.Minimap.BoundsRect, fMinimapBuffer.BoundsRect);
    fRenderer.RenderMinimap(SkillPanel.Minimap, true);
  end else
    fRenderer.RenderMinimap(SkillPanel.Minimap, false);
  SkillPanel.DrawMinimap;
end;

procedure TGameWindow.ExecuteReplayEdit;
var
  F: TFReplayEditor;
  OldPaused: Boolean;
  OldClearReplay: Boolean;
begin
  OldPaused := fGameSpeed = gspPause;
  GameSpeed := gspPause;
  F := TFReplayEditor.Create(self);
  F.SetReplay(Game.ReplayManager, Game.CurrentIteration);
  fSuspendCursor := true;
  ReleaseMouse;
  try
    if (F.ShowModal = mrOk) and (F.EarliestChange <= Game.CurrentIteration) then
    begin
      OldClearReplay := GameParams.NoAutoReplayMode;
      fSaveList.ClearAfterIteration(0);
      GotoSaveState(Game.CurrentIteration);
      GameParams.NoAutoReplayMode := OldClearReplay;
    end;
  finally
    fSuspendCursor := false;
    if not OldPaused then GameSpeed := gspNormal;
    F.Free;
  end;
end;

procedure TGameWindow.ApplyMouseTrap;
var
  ClientTopLeft, ClientBottomRight: TPoint;
begin
  // For security check trapping the mouse again.
  if fSuspendCursor or not GameParams.EdgeScroll then Exit;

  fMouseTrapped := true;

  ClientTopLeft := ClientToScreen(Point(Min(SkillPanel.Image.Left, Img.Left), Img.Top));
  ClientBottomRight := ClientToScreen(Point(Max(Img.Left + Img.Width, SkillPanel.Image.Left + SkillPanel.Image.Width), SkillPanel.Top + SkillPanel.Image.Height));
  MouseClipRect := Rect(ClientTopLeft, ClientBottomRight);
  ClipCursor(@MouseClipRect);
end;

procedure TGameWindow.ReleaseMouse;
begin
  if GameParams.FullScreen then Exit;
  fMouseTrapped := false;
  ClipCursor(nil);
end;

procedure TGameWindow.Application_Idle(Sender: TObject; var Done: Boolean);
{-------------------------------------------------------------------------------
  � Main heartbeat of the program.
  � This method together with Game.UpdateLemmings() take care of most game-mechanics.
  � A bit problematic is the SpawnInterval handling:
    if the game is paused it RR is handled here. if not it is handled by
    Game.UpdateLemmings().
-------------------------------------------------------------------------------}
var
  i: Integer;
  ContinueHyper: Boolean;

  CurrTime: Cardinal;
  Fast, ForceOne, TimeForFrame, TimeForPausedRR, TimeForFastForwardFrame, TimeForScroll, Hyper, Pause: Boolean;
  PanelFrameSkip: Integer;
begin
  if fCloseToScreen <> gstUnknown then
  begin
    // This allows any mid-processing code to finish, and averts access violations, compared to directly calling CloseScreen.
    CloseScreen(fCloseToScreen);
    Exit;
  end;

  // this makes sure this method is called very often :)
  Done := False;

  if not CanPlay or not Game.Playing or Game.GameFinished then
  begin
    ProcessGameMessages; // may still be some lingering, especially the GAMEMSG_FINISH message
    Exit;
  end;

  PanelFrameSkip := SkillPanel.FrameSkip;

  if PanelFrameSkip < 0 then
  begin
    if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
    GotoSaveState(Max(Game.CurrentIteration-1, 0));
  end;

  Pause := (fGameSpeed = gspPause);
  Fast := (fGameSpeed = gspFF);
  ForceOne := fForceUpdateOneFrame or fRenderInterface.ForceUpdate;
  fForceUpdateOneFrame := (PanelFrameSkip > 0);
  CurrTime := TimeGetTime;
  TimeForFrame := (not Pause) and (CurrTime - PrevCallTime > IdealFrameTimeMS); // don't check for frame advancing when paused
  TimeForPausedRR := (Pause) and (CurrTime - PrevPausedRRTime > IdealFrameTimeMS);
  TimeForFastForwardFrame := Fast and (CurrTime - PrevCallTime > IdealFrameTimeMSFast);
  TimeForScroll := CurrTime - PrevScrollTime > IdealScrollTimeMS;
  Hyper := IsHyperSpeed;

  if ForceOne or TimeForFastForwardFrame or Hyper then TimeForFrame := true;

  // relax CPU
  if not Hyper or Fast then
    Sleep(1);

  if TimeForFrame or TimeForScroll or TimeForPausedRR then
  begin
    fRenderInterface.ForceUpdate := false;

    // only in paused mode adjust RR. If not paused it's updated per frame.
    if TimeForPausedRR then
    begin
      CheckAdjustSpawnInterval;
      PrevPausedRRTime := CurrTime;
    end;

    // set new screen position
    if TimeForScroll then
    begin
      PrevScrollTime := CurrTime;
      if CheckScroll then
      begin
        if GameParams.MinimapHighQuality then
          fNeedRedraw := rdRefresh
        else
          fNeedRedraw := rdRedraw;
      end;
    end;

    // Check whether we have to move the lemmings
    if (TimeForFrame and not Pause)
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
    end;

    if Hyper and (fHyperSpeedStopCondition <> 0) then
    begin
      ContinueHyper := false;
      case fHyperSpeedStopCondition of
        SHE_SHRUGGER: for i := 0 to fRenderInterface.LemmingList.Count-1 do
                      begin
                        if fRenderInterface.LemmingList[i].LemRemoved then Continue;

                        if fRenderInterface.LemmingList[i].LemAction = baShrugging then
                        begin
                          ContinueHyper := false;
                          Break;
                        end;

                        if fRenderInterface.LemmingList[i].LemAction in [baBuilding, baStacking, baPlatforming] then
                          ContinueHyper := true;
                      end;
      end;

      if not ContinueHyper then
      begin
        fHyperSpeedTarget := Game.CurrentIteration;
        fHyperSpeedStopCondition := 0;
      end else
        fHyperSpeedTarget := Game.CurrentIteration + 1;
    end;

    // Refresh panel if in usual or fast play mode
    if not Hyper then
    begin
      SkillPanel.RefreshInfo;
      CheckResetCursor;
    end else if (Game.CurrentIteration = fHyperSpeedTarget) then
    begin
      if Game.CancelReplayAfterSkip then
      begin
        Game.RegainControl(true);
        Game.CancelReplayAfterSkip := false;
      end;
      fHyperSpeedTarget := -1;
      SkillPanel.RefreshInfo;
      fNeedRedraw := rdRedraw;
      CheckResetCursor;
    end;

  end;

  if TimeForFrame then
    fNeedRedraw := rdRedraw;

  // Update drawing
  DoDraw;

  if TimeForFrame then
    ProcessGameMessages;
end;

function TGameWindow.GetIsHyperSpeed: Boolean;
begin
  Result := (fHyperSpeedTarget > Game.CurrentIteration) or (fHyperSpeedStopCondition <> 0);
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

      // still need to implement sound
      GAMEMSG_SOUND: if not IsHyperSpeed then
                     begin
                       if CompareStr(Msg.MessageDataStr, 'zombie') = 0 then
                         if GetTickCount - fLastZombieSound > 1000 then
                           fLastZombieSound := GetTickCount
                         else
                           Exit;
                       SoundManager.PlaySound(Msg.MessageDataStr);
                     end;
      GAMEMSG_SOUND_BAL: if not IsHyperSpeed then
                           SoundManager.PlaySound(Msg.MessageDataStr,  (Msg.MessageDataInt - Trunc(((Img.Width / 2) - Img.OffsetHorz) / Img.Scale)) div 2);
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
  // We don't want to trigger a second exception here, so let's be over-cautious
  // with the try...excepts. Performance probably doesn't matter if we end up here.
  try
    if FileExists(ExtractFilePath(ParamStr(0)) + 'NeoLemmixException.txt') then
    begin
      SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixException.txt');
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

  RIValid := false;
  if fRenderInterface = nil then
    SL.Add('  fRenderInterface: nil')
  else
    try
      fRenderInterface.Null;
      SL.Add('  fRenderInterface: Valid');
      RIValid := true;
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
      spbFloater: SL.Add('  fRenderInterface.SelectedSkill: Floater');
      spbGlider: SL.Add('  fRenderInterface.SelectedSkill: Glider');
      spbDisarmer: SL.Add('  fRenderInterface.SelectedSkill: Disarmer');
      spbBomber: SL.Add('  fRenderInterface.SelectedSkill: Bomber');
      spbStoner: SL.Add('  fRenderInterface.SelectedSkill: Stoner');
      spbBlocker: SL.Add('  fRenderInterface.SelectedSkill: Blocker');
      spbPlatformer: SL.Add('  fRenderInterface.SelectedSkill: Platformer');
      spbBuilder: SL.Add('  fRenderInterface.SelectedSkill: Builder');
      spbStacker: SL.Add('  fRenderInterface.SelectedSkill: Stacker');
      spbBasher: SL.Add('  fRenderInterface.SelectedSkill: Basher');
      spbFencer: SL.Add('  fRenderInterface.SelectedSkill: Fencer');
      spbMiner: SL.Add('  fRenderInterface.SelectedSkill: Miner');
      spbDigger: SL.Add('  fRenderInterface.SelectedSkill: Digger');
      spbCloner: SL.Add('  fRenderInterface.SelectedSkill: Cloner');
      spbShimmier: SL.Add('  fRenderInterface.SelectedSkill: Shimmier');
      else SL.Add('  fRenderInterface.SelectedSkill: None or invalid');
    end;
  end;

  // Attempt to save report. Once again, we'd rather it just fail than crash
  // and lose the replay data.
  try
    SL.SaveToFile(ExtractFilePath(ParamStr(0)) + 'NeoLemmixException.txt');
    RIValid := true;
  except
    // We can't do much here.
    RIValid := false; // reuse is lazy. but I'm doing it anyway.
  end;

  if RIValid then
    ShowMessage('An exception has occurred. Details have been saved to NeoLemmixException.txt. Your current replay will be' + #13 +
                'saved to the "Auto" folder if possible, then you will be returned to the main menu.')
  else
    ShowMessage('An exception has occurred. Attempting to save details to a text file failed. Your current replay will be' + #13 +
                'saved to the "Auto" folder if possible, then you will be returned to the main menu.');

  try
    SL.Insert(0, Game.ReplayManager.GetSaveFileName(self, Game.Level, true));
    ForceDirectories(ExtractFilePath(SL[0]));
    Game.EnsureCorrectReplayDetails;
    Game.ReplayManager.SaveToFile(SL[0]);
    ShowMessage('Your replay was saved successfully. Returning to main menu now. Restarting NeoLemmix is recommended.');
  except
    ShowMessage('Unfortunately, your replay could not be saved.');
  end;

  fCloseToScreen := gstMenu;
end;

procedure TGameWindow.CheckUserHelpers;
begin
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
  or ((GameSpeed = gspPause) and not fLastDrawPaused) then
    fNeedRedraw := rdRedraw;

  if fNeedRedraw = rdRefresh then
  begin
    Img.Changed;
    RenderMinimap; //rdRefresh currently always occurs as a result of scrolling without any change otherwise, so minimap needs redrawing
    Exit;
  end;

  if fNeedRedraw <> rdRedraw then Exit;
  try
    fRenderInterface.ScreenPos := Point(Trunc(Img.OffsetHorz / fInternalZoom) * -1, Trunc(Img.OffsetVert / fInternalZoom) * -1);
    fRenderInterface.MousePos := Game.CursorPoint;
    fRenderer.DrawAllGadgets(fRenderInterface.Gadgets, true, fClearPhysics);
    fRenderer.DrawLemmings(fClearPhysics);
    if GameParams.MinimapHighQuality or (GameSpeed = gspPause) then
      DrawRect := Img.Bitmap.BoundsRect
    else begin
      DrawWidth := ClientWidth div fInternalZoom;
      DrawHeight := ClientHeight div fInternalZoom;
      DrawRect := Rect(fRenderInterface.ScreenPos.X, fRenderInterface.ScreenPos.Y, fRenderInterface.ScreenPos.X + DrawWidth, fRenderInterface.ScreenPos.Y + DrawHeight);
    end;
    fRenderer.DrawLevel(GameParams.TargetBitmap, DrawRect, fClearPhysics);
    RenderMinimap;
    SkillPanel.RefreshInfo;
    fNeedRedraw := rdNone;

    fLastSelectedLemming := fRenderInterface.SelectedLemming;
    fLastHighlightLemming := fRenderInterface.HighlitLemming;
    fLastSelectedSkill := fRenderInterface.SelectedSkill;
    fLastHelperIcon := fRenderInterface.UserHelper;
    fLastDrawPaused := (GameSpeed = gspPause);
  except
    on E: Exception do
      OnException(E, 'TGameWindow.DoDraw');
  end;
end;

procedure TGameWindow.CheckShifts(Shift: TShiftState);
var
  SDir: Integer;
begin
  Game.IsSelectWalkerHotkey := GameParams.Hotkeys.CheckForKey(lka_ForceWalker);
  Game.IsHighlightHotkey := GameParams.Hotkeys.CheckForKey(lka_Highlight);
  Game.IsShowAthleteInfo := GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo);

  SDir := 0;
  if GameParams.Hotkeys.CheckForKey(lka_DirLeft) then SDir := SDir - 1;
  if GameParams.Hotkeys.CheckForKey(lka_DirRight) then SDir := SDir + 1; // These two cancel each other out if both are pressed. Genius. :D
  if SDir = 0 then
  begin
    SDir := SkillPanel.SkillPanelSelectDx;
    if (SDir = 0) and (Game.fSelectDx <> 0) then
    begin
      SkillPanel.DrawButtonSelector(spbDirLeft, false);
      SkillPanel.DrawButtonSelector(spbDirRight, false);
    end;
  end else begin
    SkillPanel.SkillPanelSelectDx := 0;
    if (Game.fSelectDx <> SDir) then
    begin
      SkillPanel.DrawButtonSelector(spbDirLeft, (SDir = -1));
      SkillPanel.DrawButtonSelector(spbDirRight, (SDir = 1));
    end;
  end;

  Game.fSelectDx := SDir;
end;

procedure TGameWindow.GotoSaveState(aTargetIteration: Integer; PauseAfterSkip: Integer = 0);
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
  CanPlay := False;
  if PauseAfterSkip < 0 then
    GameSpeed := gspNormal
  else if ((aTargetIteration < Game.CurrentIteration) and GameParams.PauseAfterBackwardsSkip)
       or (PauseAfterSkip > 0) then
    GameSpeed := gspPause;

  // Find correct save state
  if aTargetIteration > 0 then
    UseSaveState := fSaveList.FindNearestState(aTargetIteration)
  else if fSaveList.Count = 0 then
    UseSaveState := -1
  else
    UseSaveState := 0;

  // Load save state or restart the level
  if UseSaveState >= 0 then
    Game.LoadSavedState(fSaveList[UseSaveState])
  else
    Game.Start(true);

  fSaveList.ClearAfterIteration(Game.CurrentIteration);

  if aTargetIteration = Game.CurrentIteration then
  begin
    fNeedRedraw := rdRedraw;
    if Game.CancelReplayAfterSkip then
    begin
      Game.RegainControl(true);
      Game.CancelReplayAfterSkip := false;
    end;
  end else begin
    // start hyperspeed to the desired interation
    fHyperSpeedTarget := aTargetIteration;
  end;

  CanPlay := True;
end;

procedure TGameWindow.CheckResetCursor(aForce: Boolean = false);
begin
  if not CanPlay then Exit;

  if FindControl(GetForegroundWindow()) = nil then
  begin
    fNeedResetMouseTrap := true;
    exit;
  end;

  SetCurrentCursor;

  if (fNeedResetMouseTrap or aForce) and fMouseTrapped and (not fSuspendCursor) and GameParams.EdgeScroll then
  begin
    ApplyMouseTrap;
    fNeedResetMouseTrap := false;
  end;
end;

procedure TGameWindow.SetCurrentCursor(aCursor: Integer = 0);
var
  NewCursor: Integer;
begin
  if aCursor = 0 then
  begin
    if (fRenderInterface.SelectedLemming = nil) or not PtInRect(Img.BoundsRect, ScreenToClient(Mouse.CursorPos)) then
      NewCursor := 1
    else
      NewCursor := 2;

    if Game.fSelectDx < 0 then
      NewCursor := NewCursor + 2
    else if Game.fSelectDx > 0 then
      NewCursor := NewCursor + 4;
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


function TGameWindow.CheckScroll: Boolean;
  procedure Scroll(dx, dy: Integer);
  begin
    Img.OffsetHorz := Img.OffsetHorz - fInternalZoom * dx * fScrollSpeed;
    Img.OffsetVert := Img.OffsetVert - fInternalZoom * dy * fScrollSpeed;
    Img.OffsetHorz := Max(MinScroll, Img.OffsetHorz);
    Img.OffsetHorz := Min(MaxScroll, Img.OffsetHorz);
    Img.OffsetVert := Max(MinVScroll, Img.OffsetVert);
    Img.OffsetVert := Min(MaxVScroll, Img.OffsetVert);
    Result := (dx <> 0) or (dy <> 0) or Result; // though it should never happen anyway, a Scroll(0, 0) call after an earlier nonzero call should not set Result to false 
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
  Result := false;

  if fHoldScrollData.Active then
  begin
    if GameParams.Hotkeys.CheckForKey(lka_Scroll) then
      HandleHeldScroll
    else
      fHoldScrollData.Active := false;
  end else if fNeedResetMouseTrap or not fMouseTrapped then // why are these two seperate variables anyway?
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
    Img.EndUpdate;
  end;
end;

constructor TGameWindow.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  Color := $202020;

  fNeedResetMouseTrap := true;

  fSaveStateReplayStream := TMemoryStream.Create;

  // create game
  fGame := GlobalGame; // set ref to GlobalGame
  fScrollSpeed := 1;

  fSaveStateFrame := -1;

  fHyperSpeedTarget := -1;

  Img := ScreenImg; // set ref to inherited screenimg (just for a short name)
  Img.RepaintMode := rmOptimizer;
  Img.Color := clNone;
  Img.BitmapAlign := baCustom;
  Img.ScaleMode := smScale;

  // create toolbar
  if GameParams.CompactSkillPanel then
    SkillPanel := TSkillPanelCompact.CreateWithWindow(Self, Self)
  else
    SkillPanel := TSkillPanelStandard.CreateWithWindow(Self, Self);

  SkillPanel.Parent := Self;

  Self.KeyPreview := True;

  // set eventhandlers
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

  SkillPanel.SetGame(fGame);
  SkillPanel.SetOnMinimapClick(SkillPanel_MinimapClick);
  Application.OnIdle := Application_Idle;

  fSaveList := TLemmingGameSavedStateList.Create(true);

  fReplayKilled := false;

  fMinimapBuffer := TBitmap32.Create;
  TLinearResampler.Create(fMinimapBuffer);

  DoubleBuffered := true;
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

  inherited Destroy;
end;

procedure TGameWindow.FreeCursors;
var
  i: Integer;
begin
  for i := 0 to Length(Cursors)-1 do
    Cursors[i].Free;
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
end;

procedure TGameWindow.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CurrTime: Cardinal;
  sn: Integer;
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
                         lka_Cheat,
                         lka_Skip,
                         lka_SpecialSkip,
                         lka_FastForward,
                         lka_SaveImage,
                         lka_LoadReplay,
                         lka_SaveReplay,
                         lka_CancelReplay,  // this one does cancel. but the code should show why it's in this list. :)
                         lka_EditReplay,
                         lka_ReplayInsert,
                         lka_Music,
                         lka_Sound,
                         lka_Restart,
                         lka_ReleaseMouse,
                         lka_Nuke,          // nuke also cancels, but requires double-press to do so so handled elsewhere
                         lka_ClearPhysics,
                         lka_ZoomIn,
                         lka_ZoomOut,
                         lka_Scroll];
  SKILL_KEYS = [lka_Skill, lka_SkillLeft, lka_SkillRight];
begin
  func := GameParams.Hotkeys.CheckKeyEffect(Key);

  if func.Action = lka_Exit then
  begin
    Game.Finish(GM_FIN_TERMINATE);
    Exit;
  end;

  // Allow changing options and selecting new levels, but pause level for that
  if ((Key = VK_F2) or (Key = VK_F3)) and (func.Action = lka_Null) then
  begin
    GameSpeed := gspPause;
    fSuspendCursor := true;
    ReleaseMouse;
    try
      if (Key = VK_F2) then DoLevelSelect(true)
      else if (Key = VK_F3) then ShowConfigMenu;
    finally
      fSuspendCursor := false;
    end;
    Exit;
  end;

  if not Game.Playing then
    Exit;

  // this is quite important: no gamecontrol if going fast
  if IsHyperSpeed then
     Exit;

  with Game do
  begin
    if (func.Action = lka_CancelReplay) then
      Game.RegainControl(true); // force the cancel even if in Replay Insert mode

    if (func.Action in [lka_ReleaseRateDown, lka_ReleaseRateUp]) then
      Game.RegainControl; // we do not want to FORCE it in this case; Replay Insert mode should be respected here

    if func.Action = lka_Skill then
    begin
      AssignToHighlit := GameParams.Hotkeys.CheckForKey(lka_Highlight);
        case func.Modifier of
          0: SetSelectedSkill(spbWalker, True, AssignToHighlit);
          1: SetSelectedSkill(spbClimber, True, AssignToHighlit);
          2: SetSelectedSkill(spbSwimmer, True, AssignToHighlit);
          3: SetSelectedSkill(spbFloater, True, AssignToHighlit);
          4: SetSelectedSkill(spbGlider, True, AssignToHighlit);
          5: SetSelectedSkill(spbDisarmer, True, AssignToHighlit);
          6: SetSelectedSkill(spbBomber, True, AssignToHighlit);
          7: SetSelectedSkill(spbStoner, True, AssignToHighlit);
          8: SetSelectedSkill(spbBlocker, True, AssignToHighlit);
          9: SetSelectedSkill(spbPlatformer, True, AssignToHighlit);
          10: SetSelectedSkill(spbBuilder, True, AssignToHighlit);
          11: SetSelectedSkill(spbStacker, True, AssignToHighlit);
          12: SetSelectedSkill(spbBasher, True, AssignToHighlit);
          13: SetSelectedSkill(spbFencer, True, AssignToHighlit);
          14: SetSelectedSkill(spbMiner, True, AssignToHighlit);
          15: SetSelectedSkill(spbDigger, True, AssignToHighlit);
          16: SetSelectedSkill(spbCloner, True, AssignToHighlit);
          17: SetSelectedSkill(spbShimmier, True, AssignToHighlit);
        end
    end;

    case func.Action of
      lka_ReleaseMouse: ReleaseMouse;
      lka_ReleaseRateDown: SetSelectedSkill(spbSlower, True);
      lka_ReleaseRateUp: SetSelectedSkill(spbFaster, True);
      lka_Pause: begin
                   if fGameSpeed = gspPause then
                     GameSpeed := gspNormal
                   else
                     GameSpeed := gspPause;
                 end;
      lka_Nuke: begin
                  // double keypress needed to prevent accidently nuking
                  CurrTime := TimeGetTime;
                  if CurrTime - fLastNukeKeyTime < 250 then
                  begin
                    RegainControl;
                    SetSelectedSkill(spbNuke);
                  end else
                    fLastNukeKeyTime := CurrTime;
                end;
      lka_SaveState : begin
                        fSaveStateFrame := fGame.CurrentIteration;
                        fSaveStateReplayStream.Clear;
                        Game.ReplayManager.SaveToStream(fSaveStateReplayStream);
                      end;
      lka_LoadState : if fSaveStateFrame <> -1 then
                      begin
                        fSaveList.ClearAfterIteration(0);
                        fSaveStateReplayStream.Position := 0;
                        Game.ReplayManager.LoadFromStream(fSaveStateReplayStream);
                        GotoSaveState(fSaveStateFrame, 1);
                        if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                      end;
      lka_Cheat: Game.Cheat;
      lka_FastForward: begin
                         case fGameSpeed of
                           gspNormal: GameSpeed := gspFF;
                           gspFF: GameSpeed := gspNormal;
                         end;
                       end;
      lka_SaveImage: SaveShot;
      lka_LoadReplay: LoadReplay;
      lka_Music: SoundManager.MuteMusic := not SoundManager.MuteMusic;
      lka_Restart: GotoSaveState(0, -1); // the -1 prevents pausing afterwards
      lka_Sound: SoundManager.MuteSound := not SoundManager.MuteSound;
      lka_SaveReplay: SaveReplay;
      lka_SkillRight: begin
                        sn := GetSelectedSkill;
                        if (sn >= 0) and (sn < MAX_SKILL_TYPES_PER_LEVEL - 1) and (fActiveSkills[sn + 1] <> spbNone) then
                          SetSelectedSkill(fActiveSkills[sn + 1]);
                      end;
      lka_SkillLeft:  begin
                        sn := GetSelectedSkill;
                        if (sn > 0) and (fActiveSkills[sn - 1] <> spbNone) then
                          SetSelectedSkill(fActiveSkills[sn - 1]);
                      end;
      lka_Skip: if Game.Playing then
                  if func.Modifier < 0 then
                  begin
                    if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                    if CurrentIteration > (func.Modifier * -1) then
                      GotoSaveState(CurrentIteration + func.Modifier)
                    else
                      GotoSaveState(0);
                  end else if func.Modifier > 1 then
                  begin
                    fHyperSpeedTarget := CurrentIteration + func.Modifier;
                  end else
                    if fGameSpeed = gspPause then fForceUpdateOneFrame := true;
      lka_SpecialSkip: HandleSpecialSkip(func.Modifier);
      lka_ClearPhysics: if func.Modifier = 0 then
                          ClearPhysics := not ClearPhysics
                        else
                          ClearPhysics := true;
      lka_EditReplay: ExecuteReplayEdit;
      lka_ReplayInsert: Game.ReplayInsert := not Game.ReplayInsert;
      lka_ZoomIn: ChangeZoom(fInternalZoom + 1);
      lka_ZoomOut: ChangeZoom(fInternalZoom - 1);
      lka_Scroll: begin
                    CursorPointForm := ScreenToClient(Mouse.CursorPos);
                    if PtInRect(Img.BoundsRect, CursorPointForm) and not fHoldScrollData.Active then
                    begin
                      fHoldScrollData.Active := true;
                      fHoldScrollData.StartCursor := Mouse.CursorPos;
                    end;
                  end;
      end;
    end;

  CheckShifts(Shift);

  // if ForceUpdateOneFrame is active, screen will be redrawn soon enough anyway
  if (fGameSpeed = gspPause) and not fForceUpdateOneFrame then
    DoDraw;
end;

procedure TGameWindow.HandleSpecialSkip(aSkipType: Integer);
var
  i: Integer;
  TargetFrame: Integer;
  HasSuitableSkill: Boolean;
begin
  TargetFrame := 0; // fallback
  case aSkipType of
    0: begin
         if (Game.ReplayManager.LastActionFrame = -1) then Exit;

         if Game.CurrentIteration > Game.ReplayManager.LastActionFrame then
           TargetFrame := Game.ReplayManager.LastActionFrame
         else
           for i := 0 to Game.CurrentIteration do
             if Game.ReplayManager.HasAnyActionAt(i) then
               TargetFrame := i;
         GotoSaveState(Max(TargetFrame - 1, 0));
       end;
    1: begin
         HasSuitableSkill := false;
         for i := 0 to fRenderInterface.LemmingList.Count-1 do
         begin
           if fRenderInterface.LemmingList[i].LemRemoved then Continue;

           if fRenderInterface.LemmingList[i].LemAction in [baBuilding, baPlatforming, baStacking] then
           begin
             HasSuitableSkill := true;
             Break;
           end;
         end;
         if not HasSuitableSkill then Exit;

         fHyperSpeedStopCondition := SHE_SHRUGGER;
         GameSpeed := gspPause;
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
                                 ClearPhysics := false;
    end;
  end;

  CheckShifts(Shift);

end;

procedure TGameWindow.SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
{-------------------------------------------------------------------------------
  convert the normal hotspot to the hotspot the game uses (4,9 instead of 7,7)
-------------------------------------------------------------------------------}
begin
  // todo: work out WHY this change is needed
  Game.CursorPoint := Point(BitmapPoint.X - 3, BitmapPoint.Y + 2);
end;

procedure TGameWindow.Img_MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
  mouse handling of the game
-------------------------------------------------------------------------------}

var
  PassKey: Word;
  OldHighlightLemming: TLemming;
begin
  if (not fMouseTrapped) and (not fSuspendCursor) and GameParams.EdgeScroll then
    ApplyMouseTrap;
  // interrupting hyperspeed can break the handling of savestates
  // so we're not allowing it
  if Game.Playing and not IsHyperSpeed then
  begin
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

    if (Button = mbLeft) and not Game.IsHighlightHotkey then
    begin
      Game.RegainControl;
      Game.ProcessSkillAssignment;
      if fGameSpeed = gspPause then fForceUpdateOneFrame := True;
    end;

    if Game.IsHighlightHotkey then
    begin
      OldHighlightLemming := fRenderInterface.HighlitLemming;
      Game.ProcessHighlightAssignment;
      if fRenderInterface.HighlitLemming <> OldHighlightLemming then
        SoundManager.PlaySound(SFX_SKILLBUTTON);
    end;

    if fGameSpeed = gspPause then
      DoDraw;

  end;
end;

procedure TGameWindow.Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  SkillPanel.MinimapScrollFreeze := false;
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

    SkillPanel.MinimapScrollFreeze := false;

    if fGameSpeed = gspPause then
    begin
      if fRenderInterface.UserHelper <> hpi_None then
        fNeedRedraw := rdRedraw;
    end;
  end;

end;

procedure TGameWindow.Img_MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  CheckShifts(Shift);
end;

procedure TGameWindow.InitializeCursor;
var
  LocalMaxZoom: Integer;
  i, i2: Integer;
  TempBMP, TempBMP2: TBitmap32;
  SL: TStringList;
const
  CURSOR_NAMES: array[1..CURSOR_TYPES] of String = (
    'standard',
    'focused',
    'standard|direction_left',
    'focused|direction_left',
    'standard|direction_right',
    'focused|direction_right'
  );
begin
  FreeCursors;

  LocalMaxZoom := Min(Screen.Width div 320, (Screen.Height - (40 * SkillPanel.MaxZoom)) div 160) + EXTRA_ZOOM_LEVELS;

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

      TPngInterface.LoadPngFile(AppPath + 'gfx/cursor/' + SL[0] + '.png', TempBMP);

      while SL.Count > 1 do
      begin
        SL.Delete(0);
        TPngInterface.LoadPngFile(AppPath + 'gfx/cursor/' + SL[0] + '.png', TempBMP2);
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
  CenterPoint: TPoint;
  HorzStart, VertStart: Integer;
begin
  inherited;

  fMaxZoom := Min(Screen.Width div 320, Screen.Height div 200) + EXTRA_ZOOM_LEVELS;

  if GameParams.IncreaseZoom then
  begin
    Sca := 2;
    while (Min(Sca, SkillPanel.MaxZoom) * 40) + (Max(GameParams.Level.Info.Height, 160) * Sca) <= ClientHeight do
      Inc(Sca);
    Dec(Sca);
    Sca := Max(Sca, GameParams.ZoomLevel);
  end else
    Sca := GameParams.ZoomLevel;

  Sca := Min(Sca, fMaxZoom);

  fInternalZoom := Sca;
  GameParams.TargetBitmap := Img.Bitmap;
  GameParams.TargetBitmap.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);
  fGame.PrepareParams;

  // set timers
  IdealFrameTimeMSFast := 10;
  IdealScrollTimeMS := 15;
  IdealFrameTimeMS := 60; // slow motion

  Img.Scale := Sca;

  SkillPanel.PrepareForGame;

  fMinimapBuffer.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);

  ChangeZoom(Sca, true);

  HorzStart := GameParams.Level.Info.ScreenPosition - ((Img.Width div 2) div Sca);
  VertStart := GameParams.Level.Info.ScreenYPosition - ((Img.Height div 2) div Sca);
  HorzStart := HorzStart * Sca;
  VertStart := VertStart * Sca;
  Img.OffsetHorz := Min(Max(-HorzStart, MinScroll), MaxScroll);
  Img.OffsetVert := Min(Max(-VertStart, MinVScroll), MaxVScroll);

  if GameParams.LinearResampleGame then
  begin
    TLinearResampler.Create(Img.Bitmap);
    TLinearResampler.Create(SkillPanel.Image.Bitmap);
  end;

  InitializeCursor;
  CenterPoint := ClientToScreen(Point(ClientWidth div 2, ClientHeight div 2));
  SetCursorPos(CenterPoint.X, CenterPoint.Y);
  if GameParams.EdgeScroll then ApplyMouseTrap;

  fRenderer := GameParams.Renderer;
  fRenderInterface := Game.RenderInterface;
  fRenderer.SetInterface(fRenderInterface);

  if FileExists(AppPath + SFMusic + GetLevelMusicName + SoundManager.FindExtension(GetLevelMusicName, true)) then
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

  fNeedRedraw := rdRefresh;
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

procedure TGameWindow.StartReplay2(const aFileName: string);
var
  ext: String;

  procedure LoadOldReplay(aName: String);
  begin
    with Game.ReplayManager do
      LoadOldReplayFile(aName);
  end;
begin
  CanPlay := False;
  ext := Lowercase(ExtractFileExt(aFilename));
  if ext = '.nxrp' then
    Game.ReplayManager.LoadFromFile(aFilename)
  else if ext = '.lrb' then
    LoadOldReplay(aFilename)
  else
    try
      Game.ReplayManager.LoadFromFile(aFilename);
    except
      LoadOldReplay(aFilename);
    end;

  if Game.ReplayManager.LevelID <> Game.Level.Info.LevelID then
    ShowMessage('Warning: This replay appears to be from a different level. NeoLemmix' + #13 +
                'will attempt to play the replay anyway.');

  GameSpeed := gspNormal;
  GotoSaveState(0, -1);
  CanPlay := True;
end;

procedure TGameWindow.SaveReplay;
var
  s: String;
  OldSpeed: TGameSpeed;
begin
  OldSpeed := fGameSpeed;
  try
    GameSpeed := gspPause;
    s := Game.ReplayManager.GetSaveFileName(self, Game.Level);
    if s = '' then Exit;
    Game.EnsureCorrectReplayDetails;
    Game.ReplayManager.SaveToFile(s);
  finally
    GameSpeed := OldSpeed;
  end;
end;

procedure TGameWindow.LoadReplay;
var
  OldCanPlay: Boolean;
  Dlg : TOpenDialog;
  s: string;

  function GetDefaultLoadPath: String;
    function GetGroupName: String;
    var
      G: TNeoLevelGroup;
    begin
      G := GameParams.CurrentLevel.Group;
      if G.Parent = nil then
        Result := ''
      else begin
        while not (G.IsBasePack or (G.Parent.Parent = nil)) do
          G := G.Parent;
        Result := MakeSafeForFilename(G.Name, false) + '\';
      end;
    end;
  begin
    Result := AppPath + 'Replay\' + GetGroupName;
  end;

  function GetInitialLoadPath: String;
  begin
    if (LastReplayDir <> '') then
      Result := LastReplayDir
    else
      Result := GetDefaultLoadPath;
  end;
begin
  OldCanPlay := CanPlay;
  CanPlay := False;
  s:='';
  dlg:=topendialog.create(nil);
  try
    dlg.Title := 'Select a replay file to load (' + GameParams.CurrentGroupName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
    dlg.Filter := 'All Compatible Replays (*.nxrp, *.lrb)|*.nxrp;*.lrb|NeoLemmix Replay (*.nxrp)|*.nxrp|Old NeoLemmix Replay (*.lrb)|*.lrb';
    dlg.FilterIndex := 1;
    if LastReplayDir = '' then
    begin
      dlg.InitialDir := AppPath + 'Replay\' + GetInitialLoadPath;
      if not DirectoryExists(dlg.InitialDir) then
        dlg.InitialDir := AppPath + 'Replay\';
      if not DirectoryExists(dlg.InitialDir) then
        dlg.InitialDir := AppPath;
    end else
      dlg.InitialDir := LastReplayDir;
    dlg.Options := [ofFileMustExist, ofHideReadOnly];
    if dlg.execute then
    begin
      s:=dlg.filename;
      LastReplayDir := ExtractFilePath(s);
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
  BMP: TBitmap32;
begin
  Dlg := TSaveDialog.Create(self);
  dlg.Filter := 'PNG Image (*.png)|*.png';
  dlg.FilterIndex := 1;
  dlg.InitialDir := '"' + ExtractFilePath(Application.ExeName) + '/"';
  dlg.DefaultExt := '.png';
  if dlg.Execute then
  begin
    SaveName := dlg.FileName;
    BMP := TBitmap32.Create;
    BMP.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);

    fRenderer.DrawAllGadgets(fRenderInterface.Gadgets, true, fClearPhysics);
    fRenderer.DrawLemmings(fClearPhysics);
    fRenderer.DrawLevel(BMP, fClearPhysics);

    TPngInterface.SavePngFile(SaveName, BMP, true);

    BMP.Free;
  end;
  Dlg.Free;
end;


procedure TGameWindow.Game_Finished;
begin
  SoundManager.StopMusic;

  GameParams.NextScreen2 := gstPostview;
  if Game.CheckPass then
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
  fSuspendCursor := true;
  Cursor := crNone;
  Screen.Cursor := crNone;
  Img.Cursor := crNone;
  SkillPanel.SetCursor(crNone);

  // We assume that we close the game for the main menu or the preview screen,
  // only via the level selection menu, and not in regular game play mode
  if not (aNextScreen in [gstMenu, gstPreview]) then
  begin
    Game.SetGameResult;
    GameParams.GameResult := Game.GameResultRec;
    with GameParams, GameResult do
    begin
      if gCheated then
      begin
        GameParams.NextLevel(true);
        GameParams.ShownText := false;
        aNextScreen := gstPreview;
      end;

      if (GameParams.AutoSaveReplay) and (Game.ReplayManager.IsModified) and (GameParams.GameResult.gSuccess) and not (GameParams.GameResult.gCheated) then
      begin
        S := Game.ReplayManager.GetSaveFileName(self, Game.Level, true);
        ForceDirectories(ExtractFilePath(S));
        Game.EnsureCorrectReplayDetails;
        Game.ReplayManager.SaveToFile(S);
      end;
    end;
  end;

  Img.RepaintMode := rmFull;

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
  Result := Img.Width div fInternalZoom;
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


end.


