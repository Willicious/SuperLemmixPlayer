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

    procedure GeneratePlaybackList;
    procedure StartPlayback(aIndex: Integer);
    procedure StopPlayback;
    procedure DelayPlayback(mS: Cardinal);
    function GetReplayID(Index: Integer; UsePlaybackList: Boolean = False): Int64;

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

function TGameBaseScreen.GetReplayID(Index: Integer; UsePlaybackList: Boolean): Int64;
var
  i: Integer;
  ReplayContent: TStringList;
  ReplayFile: string;
begin
  Result := -1;
  ReplayContent := TStringList.Create;
  try
    if UsePlaybackList then
      ReplayFile := GameParams.PlaybackList[Index]
    else
      ReplayFile := GameParams.ReplayVerifyList[Index];

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

procedure TGameBaseScreen.GeneratePlaybackList;
var
  ReplayID: Int64;
  LevelID: Int64;

  procedure SearchReplayVerifyListForMatchingID(LevelID: Int64);
  var
    i: Integer;
    CurrentReplayID: Int64;
  begin
    for i := GameParams.ReplayVerifyList.Count - 1 downto 0 do
    begin
      CurrentReplayID := GetReplayID(i);
      if LevelID = CurrentReplayID then
      begin
        GameParams.PlaybackList.Add(GameParams.ReplayVerifyList[i]);
        GameParams.ReplayVerifyList.Delete(i); // Remove replay so it isn't processed again
      end;
    end;
  end;

  procedure ProcessReplaysByLevel;
  var
    LevelsChecked: Integer;
  begin
    LevelsChecked := 0;

    // Loop until we have checked all levels
    while GameParams.CurrentLevel <> nil do
    begin
      try
        // Load current level and store ID
        GameParams.LoadCurrentLevel();
        LevelID := GameParams.CurrentLevel.LevelID;
        SearchReplayVerifyListForMatchingID(LevelID);

        // Move to the next level
        GameParams.NextLevel(True);
        Inc(LevelsChecked);

        // If we have checked all levels, exit the loop
        if LevelsChecked >= GameParams.CurrentLevel.Group.ParentBasePack.LevelCount then
          Break;
      except
        on E: Exception do
        begin
          ShowMessage('Error during replay search: ' + E.Message);
          Exit;
        end;
      end;
    end;

    // Add any remaining replays to UnmatchedList
    GameParams.UnmatchedList.AddStrings(GameParams.ReplayVerifyList);
    GameParams.ReplayVerifyList.Clear;
  end;

  procedure ProcessReplaysByReplay;
  var
    i: Integer;
    ReplayID: Int64;
  begin
    i := 0;
    while i < GameParams.ReplayVerifyList.Count do
    begin
      ReplayID := GetReplayID(i);
      if GameParams.LoadLevelByID(ReplayID) then
      begin
        GameParams.PlaybackList.Add(GameParams.ReplayVerifyList[i]);
      end else
      begin
        GameParams.UnmatchedList.Add(GameParams.ReplayVerifyList[i]);
      end;

      GameParams.ReplayVerifyList.Delete(i); // Remove replay so it isn't processed again
    end;
  end;

  procedure ProcessReplaysRandomly;
  var
    RandomIndex: Integer;
  begin
    Randomize;
    while GameParams.ReplayVerifyList.Count > 0 do
    begin
      RandomIndex := Random(GameParams.ReplayVerifyList.Count);
      ReplayID := GetReplayID(RandomIndex);

      if GameParams.LoadLevelByID(ReplayID) then
        GameParams.PlaybackList.Add(GameParams.ReplayVerifyList[RandomIndex])
      else
        GameParams.UnmatchedList.Add(GameParams.ReplayVerifyList[RandomIndex]);

      GameParams.ReplayVerifyList.Delete(RandomIndex); // Remove replay so it isn't processed again
    end;
  end;


  ///////////////////// Bookmark - This procedure can be removed after testing  ///////////////////////////
  procedure ShowLists;                                                                                   //
  // Show resulting playback list and unmatched list in a dialog                                         //
  var
    PlaybackListStr, UnmatchedListStr: string;                                                           //
    i: Integer;
  begin                                                                                                  //
    PlaybackListStr := 'Playback List:' + sLineBreak;
    for i := 0 to GameParams.PlaybackList.Count - 1 do                                                   //
      PlaybackListStr := PlaybackListStr + GameParams.PlaybackList[i] + sLineBreak;
                                                                                                         //
    UnmatchedListStr := 'Unmatched List:' + sLineBreak;  // Bookmark - Add this logic to postview and show unmatched levels at the end of playback
    for i := 0 to GameParams.UnmatchedList.Count - 1 do                                                  //
      UnmatchedListStr := UnmatchedListStr + GameParams.UnmatchedList[i] + sLineBreak;
                                                                                                          //
    ShowMessage(PlaybackListStr + sLineBreak + UnmatchedListStr);                                         //
  end;
  //////////////////////////////////////////////////////////////////////////////////////////////////////////

begin
  if GameParams.PlaybackList <> nil then GameParams.PlaybackList.Clear;
  if GameParams.UnmatchedList <> nil then GameParams.UnmatchedList.Clear;

  if GameParams.PlaybackOrder = poByLevel then
    ProcessReplaysByLevel
  else if GameParams.PlaybackOrder = poByReplay then
    ProcessReplaysByReplay
  else if GameParams.PlaybackOrder = poRandom then
    ProcessReplaysRandomly;

  // ShowLists; // Bookmark - remove after testing - add UnmatchedList logic to postview for showing when playback has finished

  if GameParams.PlaybackList.Count > 0 then
  begin
    GameParams.PlaybackIndex := 0;
    StartPlayback(GameParams.PlaybackIndex);
  end else begin
    StopPlayback;
    ShowMessage('No matching replays found.' + #13 + 'Playback Mode cannot start.')
  end;
end;

procedure TGameBaseScreen.StopPlayback;
begin
  GameParams.PlaybackModeActive := False;
  GameParams.PlaybackList.Clear;
  GameParams.UnmatchedList.Clear;
  GameParams.ReplayVerifyList.Clear;
  GameParams.PlaybackIndex := -1;
end;

procedure TGameBaseScreen.StartPlayback(aIndex: Integer);
begin
  // Extract the ID from the replay at the current index and load the matching level
  if not GameParams.LoadLevelByID(GetReplayID(aIndex, True)) then
  begin
    // Bookmark - we probably want to do something better in this situation
    StopPlayback;
    ShowMessage('Error playing back level. Playback Mode will now quit.');
    Exit;
  end;

  // Load the replay at the current index
  GameParams.LoadedReplayFile := GameParams.PlaybackList[aIndex];
  LoadReplay;

  // Go to preview screen if playback has just started or if autoskip is active
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

  if GameParams.PlaybackModeActive and GameParams.AutoSkipPreviewPostview then
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
    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level.' + #13 +
                  'SuperLemmix will attempt to play the replay anyway.');
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

