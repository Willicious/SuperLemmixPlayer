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
  SysUtils;

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
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property ScreenIsClosing: Boolean read fScreenIsClosing;

  public
    function LoadReplay: Boolean;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowScreen; override;

    procedure StartPlayback(Index: Integer);
    procedure Delay(mS: Cardinal);

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

procedure TGameBaseScreen.Delay(mS: Cardinal);
var
  startTime, elapsedTime: Cardinal;
begin
  startTime := GetTickCount;
  repeat
    elapsedTime := GetTickCount - startTime;
  until elapsedTime >= mS;
end;

procedure TGameBaseScreen.StartPlayback(Index: Integer);
var
  ReplayContent: TStringList;
  ReplayFile: string;
  ReplayID: Int64;
  LevelID: Int64;
  MatchIndex, RandomIndex: Integer;

  function ValidatePlaybackList: Boolean;
  begin
    Result := True;

    if ((GameParams.PlaybackOrder = poByLevel) and (GameParams.PlaybackList.Count <= 0))

    or ((GameParams.PlaybackOrder = poByReplay)
      and ((Index < 0) or (Index >= GameParams.PlaybackList.Count)))

    or ((GameParams.PlaybackOrder = poRandom)
      and ((RandomIndex < 0) or (RandomIndex >= GameParams.PlaybackList.Count))) then

    begin
      GameParams.PlaybackModeActive := False;
      GameParams.PlaybackList.Clear;
      Result := False;
    end;
  end;

  function GetReplayID(Index: Integer): Int64;
  var
    i: Integer;
  begin
    Result := -1;
    ReplayContent := TStringList.Create;
    try
      ReplayFile := GameParams.PlaybackList[Index];
      try
        ReplayContent.LoadFromFile(ReplayFile);
      except
        on E: Exception do
        begin
          ShowMessage('Failed to load replay file: ' + E.Message);
          Exit;
        end;
      end;

      for i := 0 to ReplayContent.Count - 1 do
      begin
        if Pos('ID ', ReplayContent[i]) = 1 then
        begin
          try
            Result := StrToInt64(Copy(ReplayContent[i], 4, Length(ReplayContent[i]) - 3));
          except
            on E: Exception do
            begin
              ShowMessage('Invalid Replay ID format in file ' + ReplayFile + ': ' + E.Message);
              Exit;
            end;
          end;
          Break;
        end;
      end;
      if Result = -1 then
        ShowMessage('No valid Replay ID found in file ' + ReplayFile);
    finally
      ReplayContent.Free;
    end;
  end;

  procedure SearchPlaybackListForMatchingID;
  var
    i: Integer;
    CurrentReplayID: Int64;
  begin
    MatchIndex := -1;
    for i := 0 to GameParams.PlaybackList.Count - 1 do
    begin
      CurrentReplayID := GetReplayID(i);
      if LevelID = CurrentReplayID then
      begin
        MatchIndex := i;
        Exit;
      end;
    end;
  end;

  procedure LoadLevelAndFindMatchingReplay;
  begin
    // Loop until we find a matching ReplayID
    while GameParams.CurrentLevel <> nil do
    begin
      try
        // Load current level and store ID
        GameParams.LoadCurrentLevel();
        LevelID := GameParams.CurrentLevel.LevelID;
        SearchPlaybackListForMatchingID;

        if MatchIndex >= 0 then
          Break // Exit loop if a match is found
        else
          GameParams.NextLevel(True); // Move on to next level if no match found
      except
        on E: Exception do
        begin
          ShowMessage('Error during replay search: ' + E.Message);
          Exit;
        end;
      end;
    end;
  end;

  function GetRandomIndex: Integer;
  begin
    Randomize;
    Result := Random(GameParams.PlaybackList.Count);
  end;

begin
  if not GameParams.PlaybackModeActive then Exit; // Just in case

  {============================================================================}
  {============================== Playback by Level ===========================}
  {============================================================================}
  if GameParams.PlaybackOrder = poByLevel then
  begin
    if not ValidatePlaybackList then
      Exit;

    LoadLevelAndFindMatchingReplay;

    // Set ReplayFile to match index and delete from the PlaybackList so it isn't loaded again
    ReplayFile := GameParams.PlaybackList[MatchIndex];
    GameParams.PlaybackList.Delete(MatchIndex);

    // Load the level again to ensure it is the correct one
    GameParams.LoadLevelByID(LevelID);

  {============================================================================}
  {============================== Playback by Replay ==========================}
  {============================================================================}
  end else if GameParams.PlaybackOrder = poByReplay then
  begin
    if not ValidatePlaybackList then
      Exit;

    // Get the Replay ID of the current item in PlaybackList
    ReplayID := GetReplayID(Index);

    if not GameParams.LoadLevelByID(ReplayID) then // Find and load the matching level
    begin
      ShowMessage('No matching level found for Replay ID: ' + IntToHex(ReplayID, 16));

      // Delete replay item from PlaybackList and move on to the next item if no match found
      GameParams.PlaybackList.Delete(Index);
      GameParams.PlaybackIndex := Index + 1;
      Exit;
    end else
      GameParams.PlaybackIndex := Index;

    ReplayFile := GameParams.PlaybackList[Index];

  {============================================================================}
  {============================= Randomized Playback ==========================}
  {============================================================================}
  end else if GameParams.PlaybackOrder = poRandom then
  begin
    // Get a random item from PlaybackList and find its ID
    RandomIndex := GetRandomIndex;

    if not ValidatePlaybackList then
      Exit;

    ReplayID := GetReplayID(RandomIndex);

    if not GameParams.LoadLevelByID(ReplayID) then // Find and load the matching level
    begin
      ShowMessage('No matching level found for Replay ID: ' + IntToHex(ReplayID, 16));

      // Delete replay item from PlaybackList and move on to the next item if no match found
      GameParams.PlaybackList.Delete(RandomIndex);
      Exit;
    end;

    // Set ReplayFile to match index and delete from the PlaybackList so it isn't loaded again
    ReplayFile := GameParams.PlaybackList[RandomIndex];
    GameParams.PlaybackList.Delete(RandomIndex);
  end;

  GameParams.LoadedReplayFile := ReplayFile;
  LoadReplay;

  if GameParams.AutoSkipPreAndPostview then
    CloseScreen(gstPreview)
  else
    GameParams.ShownText := False;
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

  if GameParams.PlaybackModeActive and GameParams.AutoSkipPreAndPostview then
  begin
    Delay(800);
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

  Application.ProcessMessages;
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
        Result := MakeSafeForFilename(G.Name, false) + '\';
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

  if GameParams.OpenedViaReplay or GameParams.PlaybackModeActive then
  begin
    Result := true; // Return true if opened by replay
    s := GameParams.LoadedReplayFile;
  end else begin
    Dlg := TOpenDialog.Create(self);
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
        Result := true; // Return true if the file was successfully selected
      end else
        Result := false; // Return false if the user canceled the dialog
    finally
      Dlg.Free;
    end;
  end;

  if s <> '' then
  begin
    GlobalGame.ReplayManager.LoadFromFile(s);
    GlobalGame.ReplayWasLoaded := True;
    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level.' + #13 +
                  'SuperLemmix will attempt to play the replay anyway.');
  end;
end;

procedure TGameBaseScreen.ShowScreen;
begin
  ScreenImg.Bitmap.MasterAlpha := 0;

  inherited; // Form is made visible here

  if GameParams.NextScreen <> gstPlay then
    FadeIn;
end;

end.

