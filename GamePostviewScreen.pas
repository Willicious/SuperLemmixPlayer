{$include lem_directives.inc}

unit GamePostviewScreen;

interface

uses
  LemmixHotkeys,
  Windows, Classes, SysUtils, Controls,
  UMisc,
  Gr32, Gr32_Image, Gr32_Layers,
  LemCore,
  LemTypes,
  LemStrings,
  LemLevelSystem,
  LemGame,
  GameControl,
  GameBaseScreen;
//  LemCore, LemGame, LemDosFiles, LemDosStyles, LemControls,
  //LemDosScreen;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGamePostviewScreen = class(TGameBaseScreen)
  private
    fSameLevelInfo: TDosGamePlayInfoRec;
    function GetScreenText: string;
    function BuildText(intxt: Array of char): string;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure HandleMouseClick(Button: TMouseButton);
    procedure ReplaySameLevel;
  protected
    procedure PrepareGameParams(Params: TDosGameParams); override;
    procedure BuildScreen; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

implementation

uses Forms, LemStyle;

(*
const
  // results from worst to best
  OrigResultStrings: array[0..8] of string = (
    'ROCK BOTTOM! I hope for your sake'      + #13 + 'that you nuked that level.',
    'Better rethink your strategy before'    + #13 + 'you try this level again!',
    'A little more practice on this level'   + #13 + 'is definitely recommended.',
    'You got pretty close that time.'        + #13 + 'Now try again for that few % extra.',
    'OH NO, So near and yet so far (teehee)' + #13 + 'Maybe this time.....',
    'RIGHT ON. You can''t get much closer'   + #13 + 'than that. Let''s try the next...',
    'That level seemed no problem to you on' + #13 + 'that attempt. Onto the next....',
    'You totally stormed that level!'        + #13 + 'Let''s see if you can storm the next...',
    'Superb! You rescued every lemmings on'  + #13 +  'that level. Can you do it again....'
  );
*)

{ TDosGamePreview }

procedure TGamePostviewScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited CloseScreen(aNextScreen);
end;

procedure TGamePostviewScreen.PrepareGameParams(Params: TDosGameParams);
begin
  inherited;
  if (GameParams.AutoSaveReplay) and (GameParams.GameResult.gSuccess) and not (GameParams.GameResult.gCheated) then GlobalGame.Save(true);
  fSameLevelInfo := GameParams.Info;
end;

procedure TGamePostviewScreen.ReplaySameLevel;
begin
  GameParams.Info := fSameLevelInfo;
  GameParams.WhichLevel := wlSame;
  CloseScreen(gstPreview);
end;

procedure TGamePostviewScreen.BuildScreen;
var
  Temp: TBitmap32;
//  DstRect: TRect;
begin
  //fSection := aSection;
  //fLevelNumber := aLevelNumber;
  //fGameResult := aResult;

  ScreenImg.BeginUpdate;
  Temp := TBitmap32.Create;
  try
    InitializeImageSizeAndPosition(640, 350);
    ExtractBackGround;
    ExtractPurpleFont;

    Temp.SetSize(640, 350);
    Temp.Clear(0);
    TileBackgroundBitmap(0, 0, Temp);
    DrawPurpleTextCentered(Temp, GetScreenText, 16);
    ScreenImg.Bitmap.Assign(Temp);
  finally
    ScreenImg.EndUpdate;
    Temp.Free;
  end;
end;

function TGamePostviewScreen.BuildText(intxt: Array of char): String;
var
  tstr : String;
  x : byte;
begin
  Result := '';
  tstr := '';
  for x := 0 to 35 do
  begin
    if (tstr <> '') or (intxt[x] <> ' ') then
    begin
      tstr := tstr + intxt[x];
    end;
  end;
  Result := Trim(tstr);
end;

constructor TGamePostviewScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  Stretched := True;
  OnKeyDown := Form_KeyDown;
  OnKeyPress := Form_KeyPress; 
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;
end;

destructor TGamePostviewScreen.Destroy;
begin
  inherited Destroy;
end;

function TGamePostviewScreen.GetScreenText: string;
var
  i: Integer;
  STarget: string;
  SDone: string;

    procedure Add(const S: string);
    begin
      Result := Result + S + #13;
    end;

    procedure LF(aCount: Integer);
    begin
      Result := Result + StringOfChar(#13, aCount);
    end;

    function GetResultIndex: Integer;
    var
      i: Integer;
      AdjLemCount: Integer;
    begin
//      i := 0;
      AdjLemCount := GameParams.Level.Info.LemmingsCount;
      if (GameParams.Level.Info.SkillTypes and 1) <> 0 then AdjLemCount := AdjLemCount + GameParams.Level.Info.ClonerCount;
      for i := 0 to GameParams.Level.InteractiveObjects.Count-1 do
        if GameParams.Renderer.FindMetaObject(GameParams.Level.InteractiveObjects[i]).TriggerEffect = 14 then
          if GameParams.Level.InteractiveObjects[i].Skill = 15 then Inc(AdjLemCount);
      with GameParams.GameResult do
      begin
        // result text
        if gRescued >= AdjLemCount then
          i := 8
        else if gRescued = 0 then
          i := 0
        else if gRescued < gToRescue div 2 then
          i := 1
        else if gDone < gTarget - 10 then
          i := 2
        else if gRescued <= gToRescue - 2 then
          i := 3
        else if gRescued = gToRescue - 1 then
          i := 4
        else if gRescued = gToRescue then
          i := 5
        else if gDone < gTarget + 20 then
          i := 6
        else if gDone >= gTarget + 20 then
          i := 7
        else
          raise exception.Create('leveltext error');
      end;
      Result := i;
    end;

    function GetNext(var NextInfo: TDosGamePlayInfoRec): Boolean;
    begin
      with GameParams do
      begin
        NextInfo := Info;
        Result := Style.LevelSystem.FindNextLevel(NextInfo);
      end;
    end;

var
  FinalInfo: TDosGamePlayInfoRec;
begin

  Result := '';
  with GameParams, GameResult do
  begin
    if GameParams.OneLevelMode then
    begin
     gSuccess := false;
     gCheated := false;
     fLevelOverride := $0000;
    end;

    if fTestMode then
    begin
      gSuccess := false;
      gCheated := false;
      fLevelOverride := $0000;
    end;

    Style.LevelSystem.FindFinalLevel(FinalInfo);

    if (gSuccess and not gCheated)
    and not (ChallengeMode or TimerMode)
    and (ForceSkillset = 0) then
    with SaveSystem, Info do
    begin
      CompleteLevel(dSection, dLevel);
      SetLemmingRecord(dSection, dLevel, gRescued);
      SetTimeRecord(dSection, dLevel, gLastRescueIteration);
    end;


      // init some local strings
        STarget := PadL(i2s(gToRescue), 4);
        SDone := PadL(i2s(gRescued), 4);

      // top text
      if gGotTalisman then
          Add(STalismanUnlocked)
      else if gTimeIsUp then
          Add(SYourTimeIsUp)
      else
          Add(SAllLemmingsAccountedFor);

      LF(1);

      Add(Format(SYouRescuedYouNeeded_ss, [SDone, STarget]));

      LF(1);

      i := GetResultIndex;
      Add(BuildText(SysDat.SResult[i][0]) + #13 + BuildText(SysDat.SResult[i][1]));

      LF(6); // gap 2 + score space 1 + gap 3

      LF(4);



    // force bottomtext to a fixed position
    LF(17 - CountChars(#13, Result));

    // bottom text

    // different texts in different situations
    if (gCheated and not gSuccess) then
    begin
      Add(SPressMouseToContinue)
    end
    // default bottom text
    else begin
      if gSuccess then
      begin
        Add(SPressLeftMouseForNextLevel);
        Add(SPressMiddleMouseToReplayLevel);
      end else begin
        LF(1);
        Add(SPressLeftMouseToRetryLevel);
      end;
      Add(SPressRightMouseForMenu);
    end;


  end;

end;
procedure TGamePostviewScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_SaveReplay then
  begin
    GlobalGame.Save;
    Exit;
  end;

  if GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_Restart then
  begin
    ReplaySameLevel;
    Exit;
  end;

  case Key of
    VK_ESCAPE: begin
                 if GameParams.fTestMode then
                   CloseScreen(gstExit)
                 else
                   CloseScreen(gstMenu);
               end;
    VK_RETURN: begin
                 CloseScreen(gstPreview);
               end;
  end;
end;

procedure TGamePostviewScreen.Form_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  HandleMouseClick(Button);
end;

procedure TGamePostviewScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  HandleMouseClick(Button);
end;

procedure TGamePostviewScreen.HandleMouseClick(Button: TMouseButton);
begin
  if Button = mbLeft then
    CloseScreen(gstPreview)
  else if Button = mbMiddle then
    ReplaySameLevel
  else if Button = mbRight then
  begin
    if GameParams.fTestMode then
      CloseScreen(gstExit)
    else
      CloseScreen(gstMenu);
  end;
end;

procedure TGamePostviewScreen.Form_KeyPress(Sender: TObject; var Key: Char);
begin

end;

end.

