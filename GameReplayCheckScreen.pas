{$include lem_directives.inc}

unit GameReplayCheckScreen;

interface

uses
  Dialogs, // debug
  LemRendering, LemLevel, LemRenderHelpers, LemNeoPieceManager, SharedGlobals,
  Windows, Classes, SysUtils, StrUtils, Controls, Contnrs,
  UMisc,
  Gr32, Gr32_Layers,
  LemTypes, LemStrings, LemGame, LemGameMessageQueue,
  GameControl, GameBaseScreen;

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

type
  TReplayCheckEntry = class
    public
      ReplayFile: String;
      ReplayLevelID: Cardinal;
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

      procedure SaveToFile;
  end;

  TGameReplayCheckScreen = class(TGameBaseScreen)
  private
    fScreenText: TStringList;
    fReplays: TReplayCheckEntries;

    fProcessing: Boolean;

    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure HandleMouseClick(Button: TMouseButton);

    procedure OutputText;

    procedure RunTests;

    procedure Application_Idle(Sender: TObject; var Done: Boolean);
  protected
    procedure BuildScreen; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

implementation

uses Forms, LemStyle, LemDosStyle, LemNeoParserOld, CustomPopup; // old parser used because levels.nxmi is still based on it, no true new-format equivalent exists yet

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
  RenderInfo: TRenderInfoRec;
  RenderInterface: TRenderInterface;
  Game: TLemmingGame;
  Level: TLevel;
  LevelIDArray: array of array of Cardinal;
  LevelSys: TBaseDosLevelSystem;
  i: Integer;
  LR, LL: Integer;

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
    Get('lrb');
  end;

  function TryLevelInfoFile: Boolean;
  var
    LS: TBaseDosLevelSystem;
    DataStream: TMemoryStream;
    Parser: TNeoLemmixParser;
    Line: TParserLine;
    R, L: Integer;
  begin
    Result := false;
    DataStream := CreateDataStream('levels.nxmi', ldtLemmings);

    LS := TBaseDosLevelSystem(GameParams.Style.LevelSystem);

    Parser := TNeoLemmixParser.Create;
    try
      Parser.LoadFromStream(DataStream);

      SetLength(LevelIDArray, LS.GetSectionCount);
      for R := 0 to LS.GetSectionCount-1 do
        SetLength(LevelIDArray[R], LS.GetLevelCount(R));

      R := -1;
      repeat
        Line := Parser.NextLine;
        if (Line.Keyword <> 'LEVEL') and (R = -1) then Continue;

        if Line.Keyword = 'LEVEL' then
        begin
          if Line.Numeric > 9999 then
          begin
            R := Line.Numeric div 1000;
            L := Line.Numeric mod 1000;
          end else begin
            R := Line.Numeric div 100;
            L := Line.Numeric mod 100;
          end;

          if (R > LS.GetSectionCount) or (L > LS.GetLevelCount(R)) then
            R := -1;
        end;

        if Line.Keyword = 'ID' then
          LevelIDArray[R][L] := StrToIntDef('x' + Line.Value, 0);

      until (Line.Keyword = '');

      Result := true;
    finally
      Parser.Free;
    end;
  end;

  function LoadLevel(aID: Cardinal): Boolean;
  var
    R, L: Integer;
  begin
    Result := false;
    for R := 0 to Length(LevelIDArray)-1 do
      for L := 0 to Length(LevelIDArray[R])-1 do
        if LevelIDArray[R][L] = aID then
        begin
          LR := R;
          LL := L;
          LevelSys.LoadSingleLevel(0, R, L, Level);
          Result := true;
          Exit;
        end;
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
        if LowerCase(ExtractFileExt(fReplays[i].ReplayFile)) = '.lrb' then
        begin
          S.Position := 30;
          S.Read(fReplays[i].ReplayLevelID, 4);
        end else begin
          SL.Clear;
          S.Position := 0;
          SL.LoadFromStream(S);
          for i2 := 0 to SL.Count-1 do
            if UpperCase(LeftStr(Trim(SL[i2]), 2)) = 'ID' then
            begin
              fReplays[i].ReplayLevelID := StrToIntDef('x' + RightStr(Trim(SL[i2]), 8), 0);
              Break;
            end;
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
      CR_PASS: Result := 'PASSED';
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
    while fScreenText.Count < 24 do
      fScreenText.Add('');
    fScreenText.Add('Click mouse to exit');
  end;

  TryLevelInfoFile;
  GetReplayLevelIDs;
  LevelSys := TBaseDosLevelSystem(GameParams.Style.LevelSystem);

  Game := GlobalGame;        // shortcut
  Level := GameParams.Level; // shortcut
  Renderer := GameParams.Renderer; // shortcut
  Renderer.SetInterface(Game.RenderInterface);

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

      RenderInfo.Level := Level;

      fReplays[i].ReplayLevelText := Trim(LevelSys.SysDat.RankNames[LR]) + ' ' + IntToStr(LL + 1);
      fReplays[i].ReplayLevelTitle := Trim(Level.Info.Title);

      Renderer.PrepareGameRendering(RenderInfo);
      Game.PrepareParams;

      if LowerCase(ExtractFileExt(fReplays[i].ReplayFile)) = '.lrb' then
        Game.ReplayManager.LoadOldReplayFile(fReplays[i].ReplayFile)
      else
        Game.ReplayManager.LoadFromFile(fReplays[i].ReplayFile);

      fReplays[i].ReplayResult := CR_UNDETERMINED;

      Game.Start;
      Game.HyperSpeedBegin;
      Game.TargetIteration := 170;
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
        while Game.MessageQueue.HasMessages do
          if Game.MessageQueue.NextMessage.MessageType in [GAMEMSG_FINISH, GAMEMSG_TIMEUP] then
          begin
            if Game.GameResultRec.gSuccess then
              fReplays[i].ReplayResult := CR_PASS
            else
              fReplays[i].ReplayResult := CR_FAIL;
          end;
        if fReplays[i].ReplayResult <> CR_UNDETERMINED then Break;

        Game.TargetIteration := Game.TargetIteration + 1; // never actually allow it to reach the targetiteration
      until Game.CurrentIteration > Game.ReplayManager.LastActionFrame + (5 * 60 * 17);

      fReplays[i].ReplayDuration := Game.CurrentIteration;
    except
      fReplays[i].ReplayResult := CR_ERROR;
    end;

    if fProcessing then
    begin
      fScreenText.Delete(fScreenText.Count-1);

      fScreenText.Add(fReplays[i].ReplayLevelText + ' ' + fReplays[i].ReplayLevelTitle);
      if fReplays[i].ReplayResult in [CR_PASS, CR_FAIL, CR_UNDETERMINED] then
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
    fReplays.SaveToFile;

    fScreenText.Add('Results saved to');
    fScreenText.Add(ExtractFileName(ChangeFileExt(GameFile, '')) + ' Replay Results.txt');
    while fScreenText.Count < 23 do
      fScreenText.Add('');
    fScreenText.Add('Click mouse to exit');

    OutputText;
  end;
end;

procedure TGameReplayCheckScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    InitializeImageSizeAndPosition(640, 400);
    ExtractBackGround;
    ExtractPurpleFont;

    TileBackgroundBitmap(0, 0, ScreenImg.Bitmap);
    DrawPurpleTextCentered(ScreenImg.Bitmap, 'Preparing replay check. Please wait.', 192);
  finally
    ScreenImg.EndUpdate;
  end;

  PieceManager.DisableTidy := true;

  Application.OnIdle := Application_Idle; // this delays processing until the form is visible
end;

procedure TGameReplayCheckScreen.OutputText;
var
  i: Integer;
begin
  while fScreenText.Count > 24 do
    fScreenText.Delete(0);

  ScreenImg.BeginUpdate;
  try
    TileBackgroundBitmap(0, 0, ScreenImg.Bitmap);
    for i := 0 to fScreenText.Count-1 do
      DrawPurpleTextCentered(ScreenImg.Bitmap, fScreenText[i], (i * 16) + 8);
  finally
    ScreenImg.EndUpdate;
  end;

  ScreenImg.Bitmap.Changed;
  Update;
end;

procedure TGameReplayCheckScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  PieceManager.DisableTidy := false;
  inherited;
end;

constructor TGameReplayCheckScreen.Create(aOwner: TComponent);
begin
  inherited;
  Stretched := True;
  OnKeyDown := Form_KeyDown;
  OnKeyPress := Form_KeyPress;
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;

  fScreenText := TStringList.Create;
  fReplays := TReplayCheckEntries.Create;
end;

destructor TGameReplayCheckScreen.Destroy;
begin
  fScreenText.Free;
  fReplays.Free;

  inherited;
end;

procedure TGameReplayCheckScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN: if not fProcessing then CloseScreen(gstMenu);
    VK_ESCAPE: if not fProcessing then
                 CloseScreen(gstMenu)
               else
                 if RunCustomPopup(self, 'Terminate replay test?', 'Do you wish to terminate mass replay testing?', 'Yes|No') = 1 then
                 begin
                   fProcessing := false;
                   Exit;
                 end;
  end;
end;

procedure TGameReplayCheckScreen.Form_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  HandleMouseClick(Button);
end;

procedure TGameReplayCheckScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  HandleMouseClick(Button);
end;

procedure TGameReplayCheckScreen.HandleMouseClick(Button: TMouseButton);
begin
  if fProcessing then Exit;
  CloseScreen(gstMenu);
end;

procedure TGameReplayCheckScreen.Form_KeyPress(Sender: TObject; var Key: Char);
begin

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

procedure TReplayCheckEntries.SaveToFile;
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
    SL.SaveToFile(ChangeFileExt(GameFile, '') + ' Replay Results.txt');
  finally
    SL.Free;
  end;
end;

end.

