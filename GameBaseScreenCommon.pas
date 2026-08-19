{$include lem_directives.inc}
unit GameBaseScreenCommon;

interface

uses
  Windows, Messages, Classes, Controls, Forms, Dialogs, Math,
  GR32, GR32_Image,
  FBaseDosForm,
  GameControl,
  LemSystemMessages,
  PngInterface, LemTypes,
  LemReplay, LemGame, LemStrings,
  SysUtils,
  SharedGlobals;

const
  EXTRA_ZOOM_LEVELS = 4;

type
  {-------------------------------------------------------------------------------
    This is the ancestor for all dos forms that are used in the program.
  -------------------------------------------------------------------------------}
  TGameBaseScreen = class(TBaseDosForm)
  private
    fScreenImg           : TImage32;
    fScreenIsClosing     : Boolean;
    fCurrentScreen       : TGameScreenType;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property ScreenIsClosing: Boolean read fScreenIsClosing;

  public
    function LoadReplay: Boolean;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowScreen; override;

    property CurrentScreen: TGameScreenType read fCurrentScreen write fCurrentScreen;

    procedure StartPlayback(aIndex: Integer);
    procedure StopPlayback(ExitToMenu: Boolean = False);
    procedure DelayPlayback(mS: Cardinal);

    procedure FadeIn;
    procedure FadeOut;

    procedure MainFormResized; virtual; abstract;

    property ScreenImg: TImage32 read fScreenImg;
  end;

implementation

uses
  LemNeoPieceManager, FMain,
  FSuperLemmixConfig, LemNeoLevelPack, FSuperLemmixLevelSelect, UITypes;

{ TGameBaseScreen }

procedure TGameBaseScreen.CNKeyDown(var Message: TWMKeyDown);
var
  AssignedEventHandler: TKeyEvent;
begin
  AssignedEventHandler := OnKeyDown;
  if Message.CharCode = vk_tab then
    if Assigned(AssignedEventHandler) then
      OnKeyDown(Self, Message.CharCode, KeyDataToShiftState(Message.KeyData));
  inherited;
end;

procedure TGameBaseScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  Self.OnKeyDown := nil;
  Self.OnKeyPress := nil;
  Self.OnClick := nil;
  Self.OnMouseDown := nil;
  Self.OnMouseMove := nil;
  ScreenImg.OnMouseDown := nil;
  ScreenImg.OnMouseMove := nil;
  Application.OnIdle := nil;
  fScreenIsClosing := True;

  FadeOut;

  if GameParams <> nil then
  begin
    GameParams.NextScreen := aNextScreen;
    GameParams.MainForm.Cursor := crNone;
  end;

  Close;

  PostMessage(MainFormHandle, LM_NEXT, 0, 0);
end;

constructor TGameBaseScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fScreenImg := TImage32.Create(Self);
  fScreenImg.Parent := Self;
  fScreenImg.RepaintMode := rmOptimizer;
  ScreenImg.Cursor := crNone;
end;

destructor TGameBaseScreen.Destroy;
begin
  inherited Destroy;
end;

procedure TGameBaseScreen.DelayPlayback(mS: Cardinal);
var
  startTime, elapsedTime: Cardinal;
begin
  startTime := GetTickCount;
  repeat
    elapsedTime := GetTickCount - startTime;
  until elapsedTime >= mS;
end;

procedure TGameBaseScreen.StopPlayback(ExitToMenu: Boolean);
begin
  GameParams.PlaybackModeActive := False;
  GameParams.PlaybackItems.Clear;
  GameParams.PlaybackIndex := -1;

  if ExitToMenu and (CurrentScreen <> gstMenu) then
    CloseScreen(gstMenu);
end;

procedure TGameBaseScreen.StartPlayback(aIndex: Integer);
var
  Item: TPlaybackItem;
begin
  // Skip unmatched items
  while aIndex < GameParams.PlaybackItems.Count do
  begin
    Item := GameParams.PlaybackItems[aIndex];
    if Item.Level <> nil then Break;
    Inc(aIndex);
  end;

  // No more playable replays - stop playback
  if aIndex >= GameParams.PlaybackItems.Count then
  begin
    StopPlayback;
    Exit;
  end;

  Item := GameParams.PlaybackItems[aIndex];

  // Load level
  GameParams.SetLevel(Item.Level);
  GameParams.LoadCurrentLevel(True);

  // Load replay
  GameParams.LoadedReplayFile := Item.ReplayFile;
  LoadReplay;
  GlobalGame.ReplayManager.ActionAddedDuringPlayback := False;

  // Continue to preview screen
  if (aIndex = 0) or GameParams.AutoSkipPreviewPostview then
    CloseScreen(gstPreview);

  GameParams.PlaybackIndex := aIndex;
end;

procedure TGameBaseScreen.FadeIn;
var
  EndTickCount: Cardinal;
  TickCount: Cardinal;
  Progress: Integer;
  Alpha, LastAlpha: integer;
const
  MAX_TIME = 240; // mS
begin
  ScreenImg.Bitmap.DrawMode := dmBlend; // So MasterAlpha is used to draw the bitmap

  TickCount := GetTickCount;
  EndTickCount := TickCount + MAX_TIME;
  LastAlpha := -1;

  while (TickCount <= EndTickCount) do
  begin
    Progress := Min(TickCount - (EndTickCount - MAX_TIME), MAX_TIME);

    Alpha := MulDiv(255, Progress, MAX_TIME);

    if (Alpha <> LastAlpha) then
    begin
      ScreenImg.Bitmap.MasterAlpha := Alpha;
      ScreenImg.Update;

      LastAlpha := Alpha;
    end else
      Sleep(1);

    TickCount := GetTickCount;
  end;

  ScreenImg.Bitmap.MasterAlpha := 255;

  if GameParams.PlaybackModeActive and GameParams.AutoSkipPreviewPostview and (CurrentScreen <> gstMenu) then
  begin
    DelayPlayback(800);
    FadeOut;
  end;

  Application.ProcessMessages;
end;

procedure TGameBaseScreen.FadeOut;
var
  RemainingTime: integer;
  OldRemainingTime: integer;
  EndTickCount: Cardinal;
const
  MAX_TIME = 320; // mS
begin
  EndTickCount := GetTickCount + MAX_TIME;
  OldRemainingTime := 0;
  RemainingTime := MAX_TIME;

  ScreenImg.Bitmap.DrawMode := dmBlend; // So MasterAlpha is used to draw the bitmap

  while (RemainingTime >= 0) do
  begin
    if (RemainingTime <> OldRemainingTime) then
    begin
      ScreenImg.Bitmap.MasterAlpha := MulDiv(255, RemainingTime, MAX_TIME);
      ScreenImg.Update;

      OldRemainingTime := RemainingTime;
    end else
      Sleep(1);

    if GetTickCount > EndTickCount then   // prevent integer overflow
      Break;

    RemainingTime := EndTickCount - GetTickCount;
  end;
end;


function TGameBaseScreen.LoadReplay: Boolean;
var
  Dlg: TOpenDialog;
  s: String;

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
        Result := MakeSafeForFilename(G.Name, False) + '\';
      end;
    end;
  begin
    Result := AppPath + SFReplays + GetGroupName;
  end;

  function GetInitialLoadPath: String;
  begin
    if (LastReplayDir <> '') then
      Result := LastReplayDir
    else
      Result := GetDefaultLoadPath;
  end;
begin
  s := '';
  GlobalGame.ReplayManager.ReplayLoadSuccess := False;

  if GameParams.OpenedViaReplay or GameParams.PlaybackModeActive or GameParams.IsPlaytesting then
  begin
    Result := True; // Return True if opened via replay or SLX is in Playback/Playtest Mode
    s := GameParams.LoadedReplayFile;
  end else begin
    Dlg := TOpenDialog.Create(Self);
    try
      Dlg.Title := 'Select a replay file to load (' + GameParams.CurrentGroupName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
      Dlg.Filter := 'SuperLemmix Replay File (*.nxrp)|*.nxrp';
      Dlg.FilterIndex := 1;
      if LastReplayDir = '' then
      begin
        Dlg.InitialDir := AppPath + SFReplays + GetInitialLoadPath;
        if not DirectoryExists(Dlg.InitialDir) then
          Dlg.InitialDir := AppPath + SFReplays;
        if not DirectoryExists(Dlg.InitialDir) then
          Dlg.InitialDir := AppPath;
      end else
        Dlg.InitialDir := LastReplayDir;

      Dlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
      if Dlg.execute then
      begin
        s := Dlg.filename;
        LastReplayDir := ExtractFilePath(s);
        Result := True; // Return True if the file was successfully selected
      end else
        Result := False; // Return False if the user cancelled the dialog
    finally
      Dlg.Free;
    end;
  end;

  if s <> '' then
  begin
    GlobalGame.ReplayManager.LoadFromFile(s);

    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level.' + #13 +
                  'SuperLemmix will attempt to play the replay anyway.');

    GlobalGame.ReplayManager.ReplayLoadSuccess := True;
  end;
end;

procedure TGameBaseScreen.ShowScreen;
begin
  ScreenImg.Bitmap.MasterAlpha := 0;

  inherited; // Form is made visible here

  if CurrentScreen <> gstPlay then
    FadeIn;
end;

end.

