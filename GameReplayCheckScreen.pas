{$include lem_directives.inc}

unit GameReplayCheckScreen;

interface

uses
  Types,
  LemRendering, LemLevel, LemRenderHelpers, LemNeoPieceManager, SharedGlobals,
  Windows, Classes, SysUtils, StrUtils, Controls, Contnrs,
  UMisc,
  Gr32, Gr32_Layers, GR32_Resamplers,
  LemTypes, LemStrings, LemGame, LemGameMessageQueue,
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen;

{-------------------------------------------------------------------------------
   New dedicated screen for replay checking. :)
-------------------------------------------------------------------------------}
const
  CR_UNKNOWN = 0;
  CR_PASS = 1;
  CR_FAIL = 2;
  CR_UNDETERMINED = 3;
  CR_NOLEVELMATCH = 4;
  CR_ERROR = 5;
  CR_PASS_OTHER_USER = 6;

type
  TReplayCheckEntry = class
    public
      ReplayFile: String;
      ReplayLevelID: Int64;
      ReplayResult: Integer;
      ReplayDuration: Int64;
      ReplayLevelText: String;
      ReplayLevelTitle: String;
  end;

  TReplayCheckEntries = class(TObjectList)
    private
      function GetItem(Index: Integer): TReplayCheckEntry;
    public
      constructor Create;
      function Add: TReplayCheckEntry;
      property Items[Index: Integer]: TReplayCheckEntry read GetItem; default;
      property List;

      procedure SaveToFile(aName: String);
  end;

  TGameReplayCheckScreen = class(TGameBaseMenuScreen)
    private
      fScreenText: TStringList;
      fReplays: TReplayCheckEntries;
      fProcessing: Boolean;
      fOldHighRes: Boolean;

      procedure OutputText;
      procedure RunTests;

      procedure ExitToMenu;

      procedure Application_Idle(Sender: TObject; var Done: Boolean);
    protected
      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

implementation

uses Forms, LemNeoLevelPack, CustomPopup;

{ TGameReplayCheckScreen }

procedure TGameReplayCheckScreen.Application_Idle(Sender: TObject; var Done: Boolean);
var
  Terminated: Boolean;
begin
  Application.OnIdle := nil;
  fProcessing := true;
  Terminated := false;
  try
    RunTests;
    if not fProcessing then
      Terminated := true;
  finally
    fProcessing := false;
  end;

  if Terminated then CloseScreen(gstMenu);
end;

procedure TGameReplayCheckScreen.RunTests;
var
  Renderer: TRenderer;
  Game: TLemmingGame;
  Level: TLevel;
  i: Integer;

  procedure BuildReplaysList;
    procedure Get(aExt: String);
    var
      SearchRec: TSearchRec;
    begin
      if FindFirst('*.' + aExt, 0, SearchRec) = 0 then
      begin
        repeat
          with fReplays.Add do
            ReplayFile := GameParams.ReplayCheckPath + SearchRec.Name;
        until FindNext(SearchRec) <> 0;
        FindClose(SearchRec);
      end;
    end;
  begin
    SetCurrentDir(GameParams.ReplayCheckPath);
    Get('nxrp');
  end;

  function GetPackName: String;
  var
    G: TNeoLevelGroup;
  begin
    G := GameParams.CurrentLevel.Group;
    while (not G.IsBasePack) and (G.Parent.Parent <> nil) do
      G := G.Parent;
    Result := G.Name;
  end;

  function LoadLevel(aID: Int64): Boolean;
  var
    G: TNeoLevelGroup;

    function SearchGroup(aGroup: TNeoLevelGroup): Boolean;
    var
      i: Integer;
    begin
      Result := false;

      for i := 0 to aGroup.Children.Count-1 do
      begin
        Result := SearchGroup(aGroup.Children[i]);
        if Result then Exit;
      end;

      for i := 0 to aGroup.Levels.Count-1 do
        if aGroup.Levels[i].LevelID = aID then
        begin
          GameParams.SetLevel(aGroup.Levels[i]);
          GameParams.LoadCurrentLevel(true);
          Result := true;
        end;
    end;
  begin
    G := GameParams.CurrentLevel.Group;
    while (G.Parent <> nil) and (not G.IsBasePack) do
      G := G.Parent;
    Result := SearchGroup(G);
  end;

  procedure GetReplayLevelIDs;
  var
    i, i2: Integer;
    S: TMemoryStream;
    SL: TStringList;
  begin
    S := TMemoryStream.Create;
    SL := TStringList.Create;
    try
      for i := 0 to fReplays.Count-1 do
      begin
        S.Clear;
        S.LoadFromFile(fReplays[i].ReplayFile);
        SL.Clear;
        S.Position := 0;
        SL.LoadFromStream(S);
        for i2 := 0 to SL.Count-1 do
          if UpperCase(LeftStr(Trim(SL[i2]), 2)) = 'ID' then
          begin
            fReplays[i].ReplayLevelID := StrToInt64Def('x' + RightStr(Trim(SL[i2]), 16), 0);
            Break;
          end;
      end;
    finally
      S.Free;
      SL.Free;
    end;
  end;

  function MakeResultText: String;
  begin
    Result := '';
    case fReplays[i].ReplayResult of
      CR_UNKNOWN: Result := 'UNKNOWN';
      CR_PASS, CR_PASS_OTHER_USER: Result := 'PASSED';
      CR_FAIL: Result := 'FAILED';
      CR_UNDETERMINED: Result := 'UNDETERMINED';
      CR_NOLEVELMATCH: Result := 'LEVEL NOT FOUND';
      CR_ERROR: Result := 'ERROR';
      else Result := 'UNDEFINED RESULT';
    end;
  end;

  function MakeTimeText: String;
  var
    m, s, f: Integer;
  begin
    m := fReplays[i].ReplayDuration div (60 * 17);
    s := (fReplays[i].ReplayDuration div 17) mod 60;
    f := fReplays[i].ReplayDuration mod 17;
    Result := IntToStr(m) + ':' + LeadZeroStr(s, 2);
    if f <> 0 then
      Result := Result + ' + ' + IntToStr(f) + ' frames';
  end;

begin
  BuildReplaysList;

  if fReplays.Count = 0 then
  begin
    fScreenText.Add('No valid replay files found.');
    while fScreenText.Count < 29 do
      fScreenText.Add('');
    fScreenText.Add('Click mouse to exit');
  end;

  GetReplayLevelIDs;

  Game := GlobalGame;        // shortcut
  Level := GameParams.Level; // shortcut
  Renderer := GameParams.Renderer; // shortcut
  Renderer.SetInterface(Game.RenderInterface);

  if ScreenImg.Bitmap.Resampler is TLinearResampler then
    TNearestResampler.Create(ScreenImg.Bitmap);

  for i := 0 to fReplays.Count-1 do
  begin
    fScreenText.Add(ExtractFileName(fReplays[i].ReplayFile));

    try
      fReplays[i].ReplayLevelText := '';
      fReplays[i].ReplayLevelTitle := '<no match>';

      if not LoadLevel(fReplays[i].ReplayLevelID) then
      begin
        fReplays[i].ReplayResult := CR_NOLEVELMATCH;
        Continue;
      end;

      if GameParams.Level.HasAnyFallbacks then
      begin
        fReplays[i].ReplayResult := CR_ERROR;
        Continue;
      end;

      fReplays[i].ReplayLevelText := GameParams.CurrentLevel.Group.Name + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1);
      fReplays[i].ReplayLevelTitle := Level.Info.Title;

      PieceManager.Tidy;
      Game.PrepareParams;

      Game.ReplayManager.LoadFromFile(fReplays[i].ReplayFile);

      fReplays[i].ReplayResult := CR_UNDETERMINED;

      Game.Start;
      repeat
        if Game.CurrentIteration mod 170 = 0 then
        begin
          if Game.CurrentIteration = 0 then
            fScreenText.Add('');
          fScreenText[fScreenText.Count-1] := 'Running for ' + IntToStr(Game.CurrentIteration div 17) + ' seconds (in-game time).';
          OutputText;

          Application.ProcessMessages;
          if not fProcessing then Break;
        end;

        Game.UpdateLemmings;

        if (Game.CurrentIteration > Game.ReplayManager.LastActionFrame + (5 * 60 * 17)) or
           Game.IsOutOfTime then
        begin
          Game.Finish(GM_FIN_TERMINATE);
          if Game.GameResultRec.gSuccess then
          begin
            if Game.ReplayManager.IsThisUsersReplay then
              fReplays[i].ReplayResult := CR_PASS
            else
              fReplays[i].ReplayResult := CR_PASS_OTHER_USER;
          end;
          Break;
        end;

        while Game.MessageQueue.HasMessages do
          if Game.MessageQueue.NextMessage.MessageType = GAMEMSG_FINISH then
          begin
            if Game.GameResultRec.gSuccess then
            begin
              if Game.ReplayManager.IsThisUsersReplay then
                fReplays[i].ReplayResult := CR_PASS
              else
                fReplays[i].ReplayResult := CR_PASS_OTHER_USER;
            end else
              fReplays[i].ReplayResult := CR_FAIL;
          end;
        if fReplays[i].ReplayResult <> CR_UNDETERMINED then Break;
      until false;

      fReplays[i].ReplayDuration := Game.CurrentIteration;

      // If appropriate, remember level as solved
      if fReplays[i].ReplayResult = CR_PASS then // We specifically do NOT want to do this on CR_PASS_OTHER_USER
        GameParams.CurrentLevel.Status := lst_Completed
      else if fReplays[i].ReplayResult = CR_PASS_OTHER_USER then
        fReplays[i].ReplayResult := CR_PASS; // but we DO want to group it with "Passed" in the report TXT file

    except
      fReplays[i].ReplayResult := CR_ERROR;
    end;

    if fProcessing then
    begin
      fScreenText.Delete(fScreenText.Count-1);

      fScreenText.Add(fReplays[i].ReplayLevelText + ' ' + fReplays[i].ReplayLevelTitle);
      if fReplays[i].ReplayResult in [CR_PASS, CR_PASS_OTHER_USER, CR_FAIL, CR_UNDETERMINED] then
        fScreenText.Add('Ran for ' + MakeTimeText);
      fScreenText.Add('*** ' + MakeResultText + ' ***');
      fScreenText.Add('');

      OutputText;
    end;

    Application.ProcessMessages;
    if not fProcessing then Break;
  end;

  if fProcessing then
  begin
    if ParamStr(2) <> 'replaytest' then
    begin
      fReplays.SaveToFile(MakeSafeForFilename(GetPackName, false) + ' Replay Results.txt');
      fScreenText.Add('Results saved to');
      fScreenText.Add(MakeSafeForFilename(GetPackName, false) + ' Replay Results.txt');
    end;

    if (ScreenImg.Bitmap.Resampler is TNearestResampler) and (GameParams.LinearResampleMenu) then
      TLinearResampler.Create(ScreenImg.Bitmap);

    OutputText;

    with MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_ONE_ROW_Y), SOptionToMenu, ExitToMenu) do
    begin
      ShortcutKeys.Add(VK_RETURN);
      ShortcutKeys.Add(VK_SPACE);
    end;
  end;
end;

procedure TGameReplayCheckScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    DrawBackground;
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, 'Preparing replay check. Please wait.', 192);

    fOldHighRes := GameParams.HighResolution;
    GameParams.HighResolution := false;
    PieceManager.Clear;

    MakeHiddenOption(VK_ESCAPE, ExitToMenu);
  finally
    ScreenImg.EndUpdate;
  end;

  Application.OnIdle := Application_Idle; // this delays processing until the form is visible
end;

procedure TGameReplayCheckScreen.OutputText;
var
  i: Integer;
begin
  while fScreenText.Count > 29 do
    fScreenText.Delete(0);

  ScreenImg.BeginUpdate;
  try
    DrawBackground;
    for i := 0 to fScreenText.Count-1 do
      MenuFont.DrawTextCentered(ScreenImg.Bitmap, fScreenText[i], (i * 16) + 8);
  finally
    ScreenImg.EndUpdate;
  end;

  ScreenImg.Bitmap.Changed;
  Update;
end;

procedure TGameReplayCheckScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  GameParams.HighResolution := fOldHighRes;
  PieceManager.Clear;

  if ParamStr(2) = 'replaytest' then
    inherited CloseScreen(gstExit)
  else
    inherited;
end;

constructor TGameReplayCheckScreen.Create(aOwner: TComponent);
begin
  inherited;

  fScreenText := TStringList.Create;
  fReplays := TReplayCheckEntries.Create;
end;

destructor TGameReplayCheckScreen.Destroy;
begin
  fScreenText.Free;
  fReplays.Free;

  inherited;
end;

procedure TGameReplayCheckScreen.ExitToMenu;
begin
  if not fProcessing then
   CloseScreen(gstMenu)
  else
    if RunCustomPopup(self, 'Terminate replay test?', 'Do you wish to terminate mass replay testing?', 'Yes|No') = 1 then
    begin
      fProcessing := false;
      Exit;
    end;
end;

{ TReplayCheckEntries }

constructor TReplayCheckEntries.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TReplayCheckEntries.Add: TReplayCheckEntry;
begin
  Result := TReplayCheckEntry.Create;
  inherited Add(Result);
end;

function TReplayCheckEntries.GetItem(Index: Integer): TReplayCheckEntry;
begin
  Result := inherited Get(Index);
end;

procedure TReplayCheckEntries.SaveToFile(aName: String);
var
  SL: TStringList;

  procedure SaveGroup(aGroupIndex: Integer; aGroupName: String);
  var
    i: Integer;
    FoundAny: Boolean;
  begin
    SL.Add('--== ' + aGroupName + ' ==--');
    SL.Add('');
    FoundAny := false;
    for i := 0 to Count-1 do
    begin
      if Items[i].ReplayResult <> aGroupIndex then Continue;
      SL.Add(Items[i].ReplayLevelText + ':  ' + ExtractFileName(Items[i].ReplayFile) + '   (' + IntToStr(Items[i].ReplayDuration) + ' frames)');
      FoundAny := true;
    end;

    if not FoundAny then
      SL.Add('(none)');

    SL.Add('');
  end;
begin
  SL := TStringList.Create;
  try
    SaveGroup(CR_FAIL, 'FAILED');
    SaveGroup(CR_UNDETERMINED, 'UNDETERMINED');
    SaveGroup(CR_PASS, 'PASSED');
    SaveGroup(CR_NOLEVELMATCH, 'LEVEL NOT FOUND');
    SaveGroup(CR_ERROR, 'ERROR');
    SL.SaveToFile(AppPath + aName);
  finally
    SL.Free;
  end;
end;

end.

