{$include lem_directives.inc}

unit GameWindow;

interface

uses
  PngInterface,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, MMSystem, Forms, SysUtils, Dialogs, Math, ExtCtrls, StrUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  LemCore, LemLevel, LemDosStyle, LemRendering, LemRenderHelpers,
  LemGame, LemGameMessageQueue,
  GameSound, LemTypes, LemStrings, LemLemming,
  GameControl, GameSkillPanel, GameBaseScreen;

type
  TGameScroll = (
    gsNone,
    gsRight,
    gsLeft,
    gsUp,
    gsDown
  );

const
  CURSOR_TYPES = 2;

type
  TGameWindow = class(TGameBaseScreen)
  private
    fCloseToScreen: TGameScreenType;
    fSuspendCursor: Boolean;
    fClearPhysics: Boolean;
    fRenderInterface: TRenderInterface;
    fRenderer: TRenderer;
    fNeedRedraw: Boolean;
    fNeedReset : Boolean;
    fMouseTrapped: Boolean;
    fSaveList: TLemmingGameSavedStateList;
    fReplayKilled: Boolean;
    fInternalZoom: Integer;
    fMinimapBuffer: TBitmap32;
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
    procedure CheckResetCursor(aForce: Boolean = false);
    function CheckScroll: Boolean;
    procedure AddSaveState;
    procedure CheckAdjustReleaseRate;
    procedure SetAdjustedGameCursorPoint(BitmapPoint: TPoint);
    procedure StartReplay2(const aFileName: string);
    procedure InitializeCursor;
    procedure CheckShifts(Shift: TShiftState);
    procedure CheckUserHelpers;
    procedure DoDraw;
    procedure OnException(E: Exception; aCaller: String = 'Unknown');
    procedure ExecuteReplayEdit;
    procedure SetClearPhysics(aValue: Boolean);
    procedure ProcessGameMessages;
    procedure ApplyResize(NoRecenter: Boolean = false);
    procedure ChangeZoom(aNewZoom: Integer);
    procedure ReleaseCursors;

    function GetLevelMusicName: String;
  protected
    fGame                : TLemmingGame;      // reference to globalgame gamemechanics
    Img                  : TImage32;          // the image in which the level is drawn (reference to inherited ScreenImg!)
    SkillPanel           : TSkillPanelToolbar;// our good old dos skill panel
    fActivateCount       : Integer;           // used when activating the form
    //ForceUpdateOneFrame  : Boolean;           // used when paused -- MOVED TO PUBLIC FOR SKILL PANEL'S USE
    GameScroll           : TGameScroll;       // scrollmode
    GameVScroll          : TGameScroll;
    IdealFrameTimeMS     : Cardinal;          // normal frame speed in milliseconds
    IdealFrameTimeMSFast : Cardinal;          // fast forward framespeed in milliseconds
    IdealScrollTimeMS    : Cardinal;          // scroll speed in milliseconds
    PrevCallTime         : Cardinal;          // last time we did something in idle
    PrevScrollTime       : Cardinal;          // last time we scrolled in idle
    MouseClipRect        : TRect;             // we clip the mouse when there is more space
    CanPlay              : Boolean;           // use in idle en set to false whenever we don't want to play
    HCursors             : array of array[1..CURSOR_TYPES] of HCURSOR; // 0 = normal, 1 = on lemming
    LemCursorIconInfo    : TIconInfo;         // normal play cursor icon
    LemSelCursorIconInfo : TIconInfo;         // highlight play cursor icon
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
    ForceUpdateOneFrame  : Boolean;           // used when paused
    SkillPanelSelectDx: Integer; //for skill panel dir select buttons
    
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyMouseTrap;
    procedure GotoSaveState(aTargetIteration: Integer; IsRestart: Boolean = false);
    procedure LoadReplay;
    procedure RenderMinimap;
    procedure MainFormResized; override;
    procedure SetCurrentCursor(aCursor: Integer = 0); // 0 = autodetect correct graphic
    property HScroll: TGameScroll read GameScroll write GameScroll;
    property VScroll: TGameScroll read GameVScroll write GameVScroll;
    property ClearPhysics: Boolean read fClearPhysics write SetClearPhysics;
    property SuspendCursor: Boolean read fSuspendCursor;
  end;

implementation

uses FBaseDosForm, FEditReplay;

{ TGameWindow }

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

procedure TGameWindow.ChangeZoom(aNewZoom: Integer);
var
  OSHorz, OSVert: Single;
begin
  if aNewZoom < 1 then Exit;
  if aNewZoom > Min(GameParams.MainForm.Width div 320, GameParams.MainForm.Height div 200) + 2 then Exit;

  Img.BeginUpdate;
  SkillPanel.Img.BeginUpdate;
  try
    OSHorz := Img.OffsetHorz - (Img.Width / 2);
    OSVert := Img.OffsetVert - (Img.Height / 2);
    OSHorz := (OSHorz * aNewZoom) / fInternalZoom;
    OSVert := (OSVert * aNewZoom) / fInternalZoom;

    Img.Scale := aNewZoom;

    if (aNewZoom >= GameParams.ZoomLevel) and (aNewZoom <= SkillPanel.MaxZoom) then
      SkillPanel.SetZoom(aNewZoom);

    fInternalZoom := aNewZoom;

    ApplyResize;
    //InitializeCursor;

    OSHorz := OSHorz + (Img.Width / 2);
    OSVert := OSVert + (Img.Height / 2);
    Img.OffsetHorz := Min(Max(OSHorz, MinScroll), MaxScroll);
    Img.OffsetVert := Min(Max(OSVert, MinVScroll), MaxVScroll);

    DoDraw;
    CheckResetCursor(true);
  finally
    Img.EndUpdate;
    SkillPanel.Img.EndUpdate;
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
  Img.Width := Min(ClientWidth, GameParams.Level.Info.Width * fInternalZoom);
  Img.Height := Min(ClientHeight - SkillPanel.Height, GameParams.Level.Info.Height * fInternalZoom);
  Img.Left := (ClientWidth div 2) - (Img.Width div 2);
  //Img.Top := ClientHeight - (SkillPanel.Height + Img.Height);
  SkillPanel.Left := (ClientWidth div 2) - (SkillPanel.Width div 2);
  //SkillPanel.Top := ClientHeight - SkillPanel.Height;

  SkillPanel.DisplayWidth := Img.Width div fInternalZoom;
  SkillPanel.DisplayHeight := Img.Height div fInternalZoom;

  VertOffset := (ClientHeight - (SkillPanel.Height + Img.Height)) div 2;
  Img.Top := VertOffset;
  SkillPanel.Top := Img.Top + Img.Height;

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

  SkillPanel.DoHorizontalScroll := (ClientWidth = SkillPanel.Width);
end;

function TGameWindow.IsGameplayScreen: Boolean;
begin
  Result := true;
end;

function TGameWindow.GetLevelMusicName: String;
var
  MusicName: String;
  MusicIndex: Integer;
  TempStream: TMemoryStream;
  SL: TStringList;
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

  SL := TStringList.Create;
  TempStream := CreateDataStream('music.txt', ldtLemmings); // It's a text file, but should be loaded more similarly to data files.
  if TempStream = nil then
    SL.LoadFromFile(AppPath + SFData + 'music.nxmi')
  else begin
    SL.LoadFromStream(TempStream);
    TempStream.Free;
  end;

  if MusicIndex = -1 then
    if GameParams.fTestMode then
      MusicIndex := Random(SL.Count)
    else
      MusicIndex := GameParams.Info.dLevel;

  if SL.Count > 0 then
    Result := SL[MusicIndex mod SL.Count];
end;

procedure TGameWindow.SetClearPhysics(aValue: Boolean);
begin
  fClearPhysics := aValue;
  if Game.Paused then
    fNeedRedraw := true;
  SkillPanel.DrawButtonSelector(spbClearPhysics, fClearPhysics);
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
  OldPaused := Game.Paused;
  Game.Paused := true;
  F := TFReplayEditor.Create(self);
  F.SetReplay(Game.ReplayManager);
  fSuspendCursor := true;
  try
    if (F.ShowModal = mrOk) and (F.EarliestChange <= Game.CurrentIteration) then
    begin
      OldClearReplay := GameParams.NoAutoReplayMode;
      fSaveList.ClearAfterIteration(0);
      GotoSaveState(Game.CurrentIteration);
      //ForceUpdateOneFrame := true;
      GameParams.NoAutoReplayMode := OldClearReplay;
    end;
  finally
    fSuspendCursor := false;
    Game.Paused := OldPaused;
    F.Free;
  end;
end;

procedure TGameWindow.ApplyMouseTrap;
var
  ClientTopLeft, ClientBottomRight: TPoint;
begin
  fMouseTrapped := true;

  ClientTopLeft := ClientToScreen(Point(Min(SkillPanel.Left, Img.Left), Img.Top));
  ClientBottomRight := ClientToScreen(Point(Max(Img.Left + Img.Width, SkillPanel.Left + SkillPanel.Width), SkillPanel.Top + SkillPanel.Height));
  MouseClipRect := Rect(ClientTopLeft, ClientBottomRight);
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
begin
  if fCloseToScreen <> gstUnknown then
  begin
    CloseScreen(fCloseToScreen);
    Exit;
    // This allows any mid-processing code to finish, and averts access violations, compared to directly calling CloseScreen.
  end;

  // this makes sure this method is called very often :)
  Done := False;

  if not CanPlay or not Game.Playing or Game.GameFinished then
  begin
    ProcessGameMessages; // may still be some lingering, especially the GAMEMSG_FINISH message
    Exit;
  end;

  Pause := Game.Paused;
  Fast := Game.FastForward;
  ForceOne := ForceUpdateOneFrame or fRenderInterface.ForceUpdate;
  ForceUpdateOneFrame := False;
  CurrTime := TimeGetTime;
  TimeForFrame := (not Pause) and (CurrTime - PrevCallTime > IdealFrameTimeMS); // don't check for frame advancing when paused
  TimeForFastForwardFrame := Fast and (CurrTime - PrevCallTime > IdealFrameTimeMSFast);
  TimeForScroll := CurrTime - PrevScrollTime > IdealScrollTimeMS;
  Hyper := Game.HyperSpeed;

  if ForceOne or TimeForFastForwardFrame or Hyper then TimeForFrame := true;

  // relax CPU
  if not Hyper or Fast then
    Sleep(1);

  if TimeForFrame or TimeForScroll then
  begin
    fRenderInterface.ForceUpdate := false;

    // Check for user helpers
    CheckUserHelpers;

    // only in paused mode adjust RR. If not paused it's updated per frame.
    if Game.Paused then
      if TimeForScroll or ForceOne then
        CheckAdjustReleaseRate;

    // set new screen position
    if TimeForScroll then
    begin
      PrevScrollTime := CurrTime;
      if CheckScroll then fNeedRedraw := True;
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

    // Refresh panel if in usual or fast play mode
    if not Hyper then
    begin
      SkillPanel.RefreshInfo;
      CheckResetCursor;
    end
    // End hyperspeed if we have reached the TargetIteration and are not mass replay checking
    // Note that TargetIteration is 1 less than the actual target frame number,
    // because we only set Game.LeavingHyperSpeed=True here,
    // any only exit hyperspeed after calling Game.UpdateLemmings once more!
    else if (Game.CurrentIteration >= Game.TargetIteration) then
    begin
      Game.HyperSpeedEnd;
      SkillPanel.RefreshInfo;
      fNeedRedraw := true;
      CheckResetCursor;
    end;

  end;

  // Update drawing
  if TimeForFrame or fNeedRedraw then
  begin
    DoDraw;
  end;

  if TimeForFrame then
    ProcessGameMessages;
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
      GAMEMSG_TIMEUP: Game_Finished; // currently no distinction as it relies on reading LemGame's data

      // still need to implement sound
      GAMEMSG_SOUND: if not Game.HyperSpeed then
                       SoundManager.PlaySound(Msg.MessageDataStr);
      GAMEMSG_SOUND_BAL: if not Game.HyperSpeed then
                           SoundManager.PlaySound(Msg.MessageDataStr, Msg.MessageDataInt);
      GAMEMSG_MUSIC: SoundManager.PlayMusic;
    end;
  end;
end;

procedure TGameWindow.OnException(E: Exception; aCaller: String = 'Unknown');
var
  SL: TStringList;
  RIValid: Boolean;
begin
  Game.Paused := true;
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
    Game.Save(true);
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
  if Game.HyperSpeed then Exit;
  try
    fRenderInterface.ScreenPos := Point(Trunc(Img.OffsetHorz / fInternalZoom) * -1, Trunc(Img.OffsetVert / fInternalZoom) * -1);
    fRenderInterface.MousePos := Game.CursorPoint;
    fRenderer.DrawAllObjects(fRenderInterface.ObjectList, true, fClearPhysics);
    fRenderer.DrawLemmings(fClearPhysics);
    if GameParams.MinimapHighQuality then
      DrawRect := Img.Bitmap.BoundsRect
    else begin
      DrawWidth := ClientWidth div fInternalZoom;
      DrawHeight := ClientHeight div fInternalZoom;
      DrawRect := Rect(fRenderInterface.ScreenPos.X, fRenderInterface.ScreenPos.Y, fRenderInterface.ScreenPos.X + DrawWidth, fRenderInterface.ScreenPos.Y + DrawHeight);
    end;
    fRenderer.DrawLevel(GameParams.TargetBitmap, DrawRect, fClearPhysics);
    RenderMinimap;
    fNeedRedraw := false;
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
  Game.IsSelectUnassignedHotkey := GameParams.Hotkeys.CheckForKey(lka_SelectNewLem);
  Game.IsShowAthleteInfo := GameParams.Hotkeys.CheckForKey(lka_ShowAthleteInfo);

  SDir := 0;
  if GameParams.Hotkeys.CheckForKey(lka_DirLeft) then SDir := SDir - 1;
  if GameParams.Hotkeys.CheckForKey(lka_DirRight) then SDir := SDir + 1; // These two cancel each other out if both are pressed. Genius. :D
  if SDir = 0 then
  begin
    SDir := SkillPanelSelectDx;
    if (SDir = 0) and (Game.fSelectDx <> 0) then
    begin
      SkillPanel.DrawButtonSelector(spbDirLeft, false);
      SkillPanel.DrawButtonSelector(spbDirRight, false);
    end;
  end else begin
    SkillPanelSelectDx := 0;
    if (Game.fSelectDx <> SDir) then
    begin
      SkillPanel.DrawButtonSelector(spbDirLeft, (SDir = -1));
      SkillPanel.DrawButtonSelector(spbDirRight, (SDir = 1));
    end;
  end;

  Game.fSelectDx := SDir;
end;

procedure TGameWindow.GotoSaveState(aTargetIteration: Integer; IsRestart: Boolean = false);
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
  if (aTargetIteration < Game.CurrentIteration) and GameParams.PauseAfterBackwardsSkip then CurrentlyPaused := true;
  if IsRestart then
  begin
    Game.Paused := false;
    CurrentlyPaused := false;
  end;

  // Find correct save state
  if aTargetIteration > 0 then
    UseSaveState := fSaveList.FindNearestState(aTargetIteration)
  else if fSaveList.Count = 0 then
    UseSaveState := -1
  else
    UseSaveState := 0;

  // Load save state or restart the level
  for i := UseSaveState downto -1 do
  begin
    if i >= 0 then
    begin
      if Game.LoadSavedState(fSaveList[i], true) then
        Break
      else
        fSaveList.Delete(i);
    end else
      Game.Start(true);
  end;

  fSaveList.ClearAfterIteration(Game.CurrentIteration);

  if aTargetIteration = Game.CurrentIteration then
  begin
    // just redraw TargetImage to display the correct game state
    DoDraw;
    Game.RefreshAllPanelInfo;
    if Game.CancelReplayAfterSkip then
    begin
      Game.RegainControl;
      Game.CancelReplayAfterSkip := false;
    end;
  end else begin
    // start hyperspeed to the desired interation
    Game.HyperSpeedBegin(CurrentlyPaused);
    Game.TargetIteration := aTargetIteration;
  end;

  CanPlay := True;
end;

procedure TGameWindow.CheckResetCursor(aForce: Boolean = false);
begin
  if not CanPlay then Exit;

  if FindControl(GetForegroundWindow()) = nil then
  begin
    fNeedReset := true;
    exit;
  end;

  SetCurrentCursor;

  if (fNeedReset or aForce) and fMouseTrapped then
  begin
    ApplyMouseTrap;
    fNeedReset := false;
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

function TGameWindow.CheckScroll: Boolean;
  procedure Scroll(dx, dy: Integer);
  begin
    Img.OffsetHorz := Img.OffsetHorz - fInternalZoom * dx * fScrollSpeed;
    Img.OffsetVert := Img.OffsetVert - fInternalZoom * dy * fScrollSpeed;
    Img.OffsetHorz := Max(MinScroll, Img.OffsetHorz);
    Img.OffsetHorz := Min(MaxScroll, Img.OffsetHorz);
    Img.OffsetVert := Max(MinVScroll, Img.OffsetVert);
    Img.OffsetVert := Min(MaxVScroll, Img.OffsetVert);
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
  Img.EndUpdate;

  Result := (GameScroll in [gsRight, gsLeft]) or(GameVScroll in [gsUp, gsDown]);
end;

constructor TGameWindow.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  fNeedReset := true;

  // create game
  fGame := GlobalGame; // set ref to GlobalGame
  fScrollSpeed := 1;

  fSaveStateFrame := -1;

  Img := ScreenImg; // set ref to inherited screenimg (just for a short name)
  Img.RepaintMode := rmOptimizer;
  Img.Color := clNone;
  Img.BitmapAlign := baCustom;
  Img.ScaleMode := smScale;

  // create toolbar
  SkillPanel := TSkillPanelToolbar.Create(Self);
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

  SkillPanel.Game := fGame; // this links the game to the infopainter interface as well
  SkillPanel.OnMinimapClick := SkillPanel_MinimapClick;
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
    SkillPanel.Game := nil;

  fSaveList.Free;

  ReleaseCursors;

  fMinimapBuffer.Free;

  inherited Destroy;
end;

procedure TGameWindow.ReleaseCursors;
var
  i, i2: Integer;
begin
  for i := 0 to Length(HCursors)-1 do
    for i2 := 0 to 1 do
      if HCursors[i][i2] <> 0 then
        DestroyIcon(HCursors[i][i2]);
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
                         lka_EditReplay,
                         lka_ReplayInsert,
                         lka_Music,
                         lka_Sound,
                         lka_Restart,
                         lka_ReleaseMouse,
                         lka_Nuke,          // nuke also cancels, but requires double-press to do so so handled elsewhere
                         lka_ClearPhysics,
                         lka_ZoomIn,
                         lka_ZoomOut];
  SKILL_KEYS = [lka_Skill, lka_SkillLeft, lka_SkillRight];
begin
  func := GameParams.Hotkeys.CheckKeyEffect(Key);

  if func.Action = lka_Exit then
  begin
    Game.Finish;
    Exit;
  end;

  if not Game.Playing then
    Exit;

  // this is quite important: no gamecontrol if going fast
  if Game.HyperSpeed then
     Exit;

  if (func.Action in NON_CANCELLING_KEYS) or (func.Action in SKILL_KEYS)
  or ((not Game.Replaying) or Game.ReplayInsert)
  or (not GameParams.ExplicitCancel) then
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
            end
        end;

        case func.Action of
          lka_ReleaseMouse: if not GameParams.FullScreen then
                            begin
                              fMouseTrapped := false;
                              ClipCursor(nil);
                            end;
          lka_ReleaseRateDown: SetSelectedSkill(spbSlower, True);
          lka_ReleaseRateUp: SetSelectedSkill(spbFaster, True);
          lka_Pause: begin
                       SetSelectedSkill(spbPause);
                       SkillPanel.DrawButtonSelector(spbPause, Paused);
                       if Paused then SkillPanel.DrawButtonSelector(spbFastForward, false);
                     end;
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
          lka_LoadState : if fSaveStateFrame <> -1 then
                          begin
                            GotoSaveState(fSaveStateFrame);
                            if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                          end;
          lka_Cheat: Game.Cheat;
          lka_FastForward: begin
                             if not Paused then FastForward := not FastForward;
                             SkillPanel.DrawButtonSelector(spbFastForward, Game.FastForward);
                           end;
          lka_SaveImage: SaveShot;
          lka_LoadReplay: LoadReplay;
          lka_Music: SoundManager.MuteMusic := not SoundManager.MuteMusic;
          lka_Restart: begin
                         if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                         GotoSaveState(0, true); // the true prevents pausing afterwards
                       end;
          lka_Sound: SoundManager.MuteSound := not SoundManager.MuteSound;
          lka_SaveReplay: Save;
          lka_SkillRight: begin
                            sn := GetSelectedSkill;
                            if (sn < 7) and (fActiveSkills[sn + 1] <> spbNone) then
                              SetSelectedSkill(fActiveSkills[sn + 1]);
                          end;
          lka_SkillLeft:  begin
                            sn := GetSelectedSkill;
                            if (sn > 0) and (fActiveSkills[sn - 1] <> spbNone) and (sn <> 8) then
                              SetSelectedSkill(fActiveSkills[sn - 1]);
                          end;
          lka_Skip: if Game.Playing then
                      if func.Modifier < 0 then
                      begin
                        if GameParams.NoAutoReplayMode then Game.CancelReplayAfterSkip := true;
                        if CurrentIteration > (func.Modifier * -1) then
                          GotoSaveState(CurrentIteration + func.Modifier - 1)
                        else
                          GotoSaveState(0);
                      end else if func.Modifier > 1 then
                      begin
                        HyperSpeedBegin;
                        // We have to set TargetIteration one frame before the actual target frame number,
                        // because on TargetIteration, we only set Game.LeavingHyperSpeed=True,
                        // but exit hyperspeed only after calling Game.UpdateLemmings once more!
                        TargetIteration := CurrentIteration + func.Modifier - 1;
                      end else
                        if Paused then ForceUpdateOneFrame := true;
          lka_ClearPhysics: if func.Modifier = 0 then
                              ClearPhysics := not ClearPhysics
                            else
                              ClearPhysics := true;
          lka_EditReplay: ExecuteReplayEdit;
          lka_ReplayInsert: Game.ReplayInsert := not Game.ReplayInsert;
          lka_ZoomIn: ChangeZoom(fInternalZoom + 1);
          lka_ZoomOut: ChangeZoom(fInternalZoom - 1);
        end;

    end;

  CheckShifts(Shift);

  if Game.Paused and not ForceUpdateOneFrame then  // if ForceUpdateOneFrame is active, screen will be redrawn soon enough anyway
    DoDraw;
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
  if not fMouseTrapped then
    ApplyMouseTrap;
  // interrupting hyperspeed can break the handling of savestates
  // so we're not allowing it
  if Game.Playing and not Game.HyperSpeed then
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

    if (Button = mbLeft) and (not Game.IsHighlightHotkey)
       and not (Game.Replaying and GameParams.ExplicitCancel) then
    begin
      Game.RegainControl;
      Game.ProcessSkillAssignment;
      if Game.Paused then ForceUpdateOneFrame := True;
    end;

    if Game.IsHighlightHotkey and not (Game.Replaying and GameParams.ExplicitCancel) then
    begin
      OldHighlightLemming := fRenderInterface.HighlitLemming;
      Game.ProcessHighlightAssignment;
      if fRenderInterface.HighlitLemming <> OldHighlightLemming then
        SoundManager.PlaySound(SFX_SKILLBUTTON);
    end;

    if Game.Paused then
      DoDraw;

  end;
end;

procedure TGameWindow.Form_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if fSuspendCursor then Exit;

  SkillPanel.MinimapScrollFreeze := false;

  if X <= Img.Left then
    GameScroll := gsLeft
  else if X >= (Img.Left + Img.Width - 1) then
    GameScroll := gsRight
  else
    GameScroll := gsNone;

  if Y <= Img.Top then
    GameVScroll := gsUp
  else if Y >= (SkillPanel.Top + SkillPanel.Height - 1) then
    GameVScroll := gsDown
  else
    GameVScroll := gsNone;
end;

procedure TGameWindow.Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Game.Playing then
  begin
    CheckShifts(Shift);

    SetAdjustedGameCursorPoint(Img.ControlToBitmap(Point(X, Y)));

    if (Game.Paused) or (Game.HitTestAutoFail) then
    begin
      Game.HitTest;
      CheckResetCursor;
    end;

    Game.HitTestAutoFail := not PtInRect(Img.BoundsRect, Point(X, Y));

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

    SkillPanel.MinimapScrollFreeze := false;

    if Game.Paused then
      DoDraw; // probably causing major lag, can we detect if it's nessecary and only redraw if it is?
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
  i: Integer;
  n: Integer;

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
  ReleaseCursors;

  bmpMask := TBitmap.Create;
  bmpColor := TBitmap.Create;

  n := 0;

  for i := 0 to Length(HCursors)-1 do
  begin
    bmpMask.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_DEFAULT_MASK');
    bmpColor.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_DEFAULT');
    ScaleBmp(bmpMask, i+1);
    ScaleBmp(bmpColor, i+1);

    with LemCursorIconInfo do
    begin
      fIcon := false;
      xHotspot := bmpColor.Width div 2;
      yHotspot := bmpColor.Width div 2;
      hbmMask := bmpMask.Handle;
      hbmColor := bmpColor.Handle;
    end;

    HCursors[i][1] := CreateIconIndirect(LemCursorIconInfo);
    Inc(n);
    Screen.Cursors[n] := HCursors[i][1];

    bmpMask.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_HIGHLIGHT_MASK');
    bmpColor.LoadFromResourceName(HINSTANCE, 'GAMECURSOR_HIGHLIGHT');

    scalebmp(bmpmask, i+1);
    scalebmp(bmpcolor, i+1);


    with LemSelCursorIconInfo do
    begin
      fIcon := false;
      xHotspot := bmpColor.Width div 2;
      yHotspot := bmpColor.Width div 2;
      hbmMask := bmpMask.Handle;
      hbmColor := bmpColor.Handle;
    end;

    HCursors[i][2] := CreateIconIndirect(LemSelCursorIconInfo);
    Inc(n);
    Screen.Cursors[n] := HCursors[i][2];
  end;

  bmpMask.Free;
  bmpColor.Free;
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

  Sca := GameParams.ZoomLevel;
  fInternalZoom := Sca;
  GameParams.TargetBitmap := Img.Bitmap;
  GameParams.TargetBitmap.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);
  fGame.PrepareParams;

  // set timers
  IdealFrameTimeMSFast := 10;
  IdealScrollTimeMS := 60;
  IdealFrameTimeMS := 60; // slow motion

  Img.Scale := Sca;


  SkillPanel.SetZoom(Sca);
  SkillPanel.Minimap.SetSize(GameParams.Level.Info.Width div 8, GameParams.Level.Info.Height div 8);
  fMinimapBuffer.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);

  ApplyResize;

  HorzStart := GameParams.Level.Info.ScreenPosition - ((Img.Width div 2) div Sca);
  VertStart := GameParams.Level.Info.ScreenYPosition - ((Img.Height div 2) div Sca);
  HorzStart := HorzStart * Sca;
  VertStart := VertStart * Sca;
  Img.OffsetHorz := Min(Max(-HorzStart, MinScroll), MaxScroll);
  Img.OffsetVert := Min(Max(-VertStart, MinVScroll), MaxVScroll);

  SkillPanel.SetStyleAndGraph(Gameparams.Style, Sca);

  SkillPanel.Level := GameParams.Level;
  SkillPanel.SetSkillIcons;

  if GameParams.LinearResampleGame then
  begin
    TLinearResampler.Create(Img.Bitmap);
    TLinearResampler.Create(SkillPanel.Img.Bitmap);
  end;

  SetLength(HCURSORS, Min(Screen.Width div 320, Screen.Height div 200) + 2);
  InitializeCursor;
  CenterPoint := ClientToScreen(Point(ClientWidth div 2, ClientHeight div 2));
  SetCursorPos(CenterPoint.X, CenterPoint.Y);
  ApplyMouseTrap;

  fRenderer := GameParams.Renderer;
  fRenderInterface := Game.RenderInterface;
  fRenderer.SetInterface(fRenderInterface);

  if FileExists(AppPath + SFMusic + GetLevelMusicName + SoundManager.FindExtension(GetLevelMusicName, true)) then
    SoundManager.LoadMusicFromFile(GetLevelMusicName)
  else begin
    //ShowMessage('not found!' + #13 + AppPath + SFMusic + GetLevelMusicName + SoundManager.FindExtension(GetLevelMusicName, true));
    SoundManager.FreeMusic; // This is safe to call even if no music is loaded, but ensures we don't just get the previous level's music
  end;

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
  O := -P.X * fInternalZoom;
  O :=  O + Img.Width div 2;
  if O < MinScroll then O := MinScroll;
  if O > MaxScroll then O := MaxScroll;
  Img.OffSetHorz := O;

  O := -P.Y * fInternalZoom;
  O :=  O + Img.Height div 2;
  if O < MinVScroll then O := MinVScroll;
  if O > MaxVScroll then O := MaxVScroll;
  Img.OffsetVert := O;
  
  DoDraw;
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
  Game.CheckAdjustReleaseRate;
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

  Game.Paused := False;
  GotoSaveState(0);
  CanPlay := True;
end;


procedure TGameWindow.LoadReplay;
var
  OldCanPlay: Boolean;
  Dlg : TOpenDialog;
  s: string;
begin
  OldCanPlay := CanPlay;
  CanPlay := False;
  s:='';
  dlg:=topendialog.create(nil);
  try
    dlg.Title := 'Select a replay file to load (' + GameParams.Info.dSectionName + ' ' + IntToStr(GameParams.Info.dLevel + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
    dlg.Filter := 'All Compatible Replays (*.nxrp, *.lrb)|*.nxrp;*.lrb|NeoLemmix Replay (*.nxrp)|*.nxrp|Old NeoLemmix Replay (*.lrb)|*.lrb';
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

    fRenderer.DrawAllObjects(fRenderInterface.ObjectList, true, fClearPhysics);
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

  if (GameParams.fTestMode and (GameParams.QuickTestMode in [2, 3])) then
  begin
    if GameParams.QuickTestMode = 3 then Game.Save(true);
    fCloseToScreen := gstExit;
  end else
  begin
    GameParams.NextScreen2 := gstPostview;
    if Game.CheckPass then
      fCloseToScreen := gstText
    else
      fCloseToScreen := gstPostview;
  end;
end;

procedure TGameWindow.CloseScreen(aNextScreen: TGameScreenType);
begin
  CanPlay := False;
  Application.OnIdle := nil;
  ClipCursor(nil);
  fSuspendCursor := true;
  Cursor := crNone;
  Screen.Cursor := crNone;
  Img.Cursor := crNone;
  SkillPanel.SetCursor(crNone);

  Game.SetGameResult;
  GameParams.GameResult := Game.GameResultRec;
  with GameParams, GameResult do
  begin
    if (gSuccess or gCheated) and (not GameParams.fTestMode) then
      WhichLevel := wlNext;
    if gCheated then
    begin
      GameParams.ShownText := false;
      aNextScreen := gstPreview;
    end;
  end;
  Img.RepaintMode := rmFull;

  inherited CloseScreen(aNextScreen);
end;

procedure TGameWindow.AddSaveState;
begin
  fGame.CreateSavedState(fSaveList.Add);
end;

end.

