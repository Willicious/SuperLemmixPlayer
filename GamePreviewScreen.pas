{$include lem_directives.inc}

unit GamePreviewScreen;

interface

uses
  PngInterface,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs,
  LemCore, LemStrings, LemDosStructures, LemRendering, LemLevelSystem, LemLevel,
  LemDosStyle, LemTypes, LemMetaObject,
  LemObjects,
  GameControl, GameBaseScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseScreen)
  private
    //fRickrolling : Boolean;
    fCanDump: Boolean;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure VGASpecPrep;
    procedure SaveLevelImage;
    function GetScreenText: string;
    procedure CheckLemmingCount(aLevel: TLevel);
    procedure FilterSkillset(aLevel: TLevel);
    procedure NextLevel;
    procedure PreviousLevel;
    procedure NextRank;
    procedure PreviousRank;
    procedure ShowRecords;
    procedure SimulateSpawn;
  protected
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildScreen; override;
    procedure BuildScreenInvis;
    procedure PrepareGameParams(Params: TDosGameParams); override;
    procedure CloseScreen(NextScreen: TGameScreenType); override;
  end;

implementation

uses FBaseDosForm;

{ TGamePreviewScreen }

procedure TGamePreviewScreen.SimulateSpawn;
var
  i: Integer;
  LemsSpawned: Integer;
  CompareVal: Byte;

  procedure FindNextWindow;
  begin
    if Length(GameParams.Level.Info.WindowOrder) = 0 then
    begin
      repeat
        i := i + 1;
        if i = GameParams.Level.InteractiveObjects.Count then i := 0;
      until GameParams.Renderer.FindMetaObject(GameParams.Level.InteractiveObjects[i]).TriggerEffect = 23;
    end else begin
      i := GameParams.Level.Info.WindowOrder[LemsSpawned mod Length(GameParams.Level.Info.WindowOrder)];
    end;
  end;

begin
  // A full blown simulation of lemming spawning is the only way to
  // check how many Zombies and Ghosts the level has.
  GameParams.Level.Info.ZombieGhostCount := 0;
  LemsSpawned := 0;

  // Trigger effect 13: Preplaced lemming
  // Trigger effect 23: Window

  with GameParams.Level do
  begin

    CompareVal := 64;
    //if CheckZombies then CompareVal := CompareVal + 64;
    //if CheckGhosts then CompareVal := CompareVal + 128;

    for i := 0 to PreplacedLemmings.Count-1 do
    begin
      LemsSpawned := LemsSpawned + 1; // to properly emulate the spawn order glitch, since no decision on how to fix it has been reached
      if PreplacedLemmings[i].IsZombie then Info.ZombieGhostCount := Info.ZombieGhostCount + 1;
    end;

    i := -1;
    while LemsSpawned < Info.LemmingsCount do
    begin
      FindNextWindow;
      if GameParams.Renderer.FindMetaObject(InteractiveObjects[i]).TriggerEffect <> 23 then Continue;
      LemsSpawned := LemsSpawned + 1;
      if (InteractiveObjects[i].TarLev and CompareVal) <> 0 then Info.ZombieGhostCount := Info.ZombieGhostCount + 1;
    end;
  end;
end;

procedure TGamePreviewScreen.FilterSkillset(aLevel: TLevel);
var
  i, SkillCount: Integer;
  Key: Word;
  NeedClear: Boolean;
const
  BIT_TO_SV: array[0..15] of Integer = (15, 7, 6, 5, 14, 4, 13, 3, 12, 2, 11, 10, 1, 9, 0, 8);
  function FindPickupSkill(aSkillSValue: Integer): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to aLevel.InteractiveObjects.Count-1 do
      if GameParams.Renderer.FindMetaObject(aLevel.InteractiveObjects[i]).TriggerEffect = 14 then
        if aLevel.InteractiveObjects[i].Skill = aSkillSValue then
        begin
          Result := true;
          Exit;
        end;
  end;
begin
  for i := 0 to 15 do
  begin
    Key := 1 shl i;
    if (aLevel.Info.SkillTypes and Key) <> Key then Continue;
    case i of
      0: SkillCount := aLevel.Info.ClonerCount;
      1: SkillCount := aLevel.Info.DiggerCount;
      2: SkillCount := aLevel.Info.MinerCount;
      3: SkillCount := aLevel.Info.BasherCount;
      4: SkillCount := aLevel.Info.StackerCount;
      5: SkillCount := aLevel.Info.BuilderCount;
      6: SkillCount := aLevel.Info.PlatformerCount;
      7: SkillCount := aLevel.Info.BlockerCount;
      8: SkillCount := aLevel.Info.StonerCount;
      9: SkillCount := aLevel.Info.BomberCount;
      10: SkillCount := aLevel.Info.MechanicCount;
      11: SkillCount := aLevel.Info.GliderCount;
      12: SkillCount := aLevel.Info.FloaterCount;
      13: SkillCount := aLevel.Info.SwimmerCount;
      14: SkillCount := aLevel.Info.ClimberCount;
      15: SkillCount := aLevel.Info.WalkerCount;
      else SkillCount := 0; // just to avoid compiler warning
    end;
    if SkillCount = 0 then
      NeedClear := not FindPickupSkill(BIT_TO_SV[i])
    else
      NeedClear := false;
    if NeedClear then
      aLevel.Info.SkillTypes := aLevel.Info.SkillTypes and (not Key);
  end;
end;

procedure TGamePreviewScreen.ShowRecords;
var
  maxlem, mintime: Integer;
  beaten: Boolean;
  mins, secs, frms: Integer;
  outstring: String;
begin

  with GameParams.SaveSystem do
  begin
    maxlem := GetLemmingRecord(GameParams.Info.dSection, GameParams.Info.dLevel);
    mintime := GetTimeRecord(GameParams.Info.dSection, GameParams.Info.dLevel);
    beaten := CheckCompleted(GameParams.Info.dSection, GameParams.Info.dLevel);
    frms := mintime mod 17;
    secs := (mintime div 17) mod 60;
    mins := (mintime div 17) div 60;
    outstring := GameParams.Info.dSectionName + ' ' + i2s(GameParams.Info.dLevel + 1) + #13 + #13;

    if beaten then
      outstring := outstring + 'Completed: Yes' + #13 +
                 'Most Lemmings Saved: ' + i2s(maxlem) + #13 +
                 'Best Time: ' + i2s(mins) + ':' + LeadZeroStr(secs, 2) + ' + ' + i2s(frms) + ' frames'
    else
      outstring := outstring + 'Completed: No';

    MessageDlg(outstring, mtcustom, [mbOk], 0);
  end;

end;

procedure TGamePreviewScreen.CloseScreen(NextScreen: TGameScreenType);
begin
  if NextScreen = gstPlay then
  begin
    GameParams.NextScreen2 := gstPlay;
    inherited CloseScreen(gstText);
  end else
    inherited;
end;

procedure TGamePreviewScreen.NextLevel;
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  GameParams.Style.LevelSystem.FindNextUnlockedLevel(FindInfo);
  if FindInfo.dLevel <> GameParams.Info.dLevel then
  begin
    GameParams.ShownText := false;
    GameParams.WhichLevel := wlNextUnlocked;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.PreviousLevel;
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  GameParams.Style.LevelSystem.FindPreviousUnlockedLevel(FindInfo);
  if FindInfo.dLevel <> GameParams.Info.dLevel then
  begin
    GameParams.ShownText := false;
    GameParams.WhichLevel := wlPreviousUnlocked;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.NextRank;
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  if FindInfo.dSection = TBaseDosLevelSystem(GameParams.Style.LevelSystem).GetSectionCount-1 then Exit;
  FindInfo.dSection := FindInfo.dSection + 1;
  GameParams.Style.LevelSystem.FindLastUnlockedLevel(FindInfo);
  GameParams.ShownText := false;
  GameParams.WhichLevel := wlLastUnlocked;
  GameParams.Info := FindInfo;
  CloseScreen(gstPreview);
end;

procedure TGamePreviewScreen.PreviousRank;
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  if FindInfo.dSection = 0 then Exit;
  FindInfo.dSection := FindInfo.dSection - 1;
  GameParams.Style.LevelSystem.FindLastUnlockedLevel(FindInfo);
  GameParams.ShownText := false;
  GameParams.WhichLevel := wlLastUnlocked;
  GameParams.Info := FindInfo;
  CloseScreen(gstPreview);
end;

procedure TGamePreviewScreen.CheckLemmingCount(aLevel: TLevel);
var
  i: Integer;
  MinCount : Integer;
  FoundWindow : Boolean;
  MO: TMetaObjectInterface;
begin
  FoundWindow := false;
  MinCount := aLevel.PreplacedLemmings.Count;
  for i := 0 to aLevel.InteractiveObjects.Count - 1 do
  begin
    //if aLevel.InteractiveObjects[i].Identifier = 1 then FoundWindow := true;
    MO := GameParams.Renderer.FindMetaObject(aLevel.InteractiveObjects[i]);
    if MO.TriggerEffect = 23 then FoundWindow := true;
  end;
  if (not FoundWindow) or (aLevel.Info.LemmingsCount < MinCount) then aLevel.Info.LemmingsCount := MinCount;

  SimulateSpawn;
end;

procedure TGamePreviewScreen.BuildScreen;
var
  Inf: TRenderInfoRec;
  Mainpal: TArrayOfColor32;
  Temp, W: TBitmap32;
  DstRect: TRect;
  Lw, Lh : Integer;
begin
  Assert(GameParams <> nil);

  ScreenImg.BeginUpdate;
  try
    MainPal := GetDosMainMenuPaletteColors32;
    InitializeImageSizeAndPosition(640, 350);
    ExtractBackGround;
    ExtractPurpleFont;

    // prepare the renderer, this is a little bit shaky (wrong place)
    with GameParams do
    begin
      Inf.Level:=Level;
      Lw := Level.Info.Width;
      Lh := Level.Info.Height;
      CheckLemmingCount(Level);
      FilterSkillset(Level);
      Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
    end;

    Temp := TBitmap32.Create;
    W := TBitmap32.Create;
    try
      Temp.SetSize(640, 350);
      Temp.Clear(0);
      // draw level preview
      W.SetSize(Lw, Lh);
      W.Clear(0);
//      W.ResamplerClassName := 'TLinearResampler';//DraftResampler';
//      W.ResamplerClassName := 'TDraftResampler';
      GameParams.Renderer.RenderWorld(W, not GameParams.NoBackgrounds);
      TLinearResampler.Create(W);
      W.DrawMode := dmBlend;
      W.CombineMode := cmMerge;
      DstRect := Rect(0, 0, (lw div 4), (lh div 4)); // div 4
      RectMove(DstRect, (120 + (200 - (lw div 8))), (20 + (20 - (lh div 8)))); // set location
      W.DrawTo(Temp, DstRect, W.BoundsRect);
      // draw background
      TileBackgroundBitmap(0, 78, Temp);
      // draw text
      DrawPurpleText(Temp, GetScreenText, 0, 80);
      ScreenImg.Bitmap.Assign(Temp);
    finally
      W.Free;
      Temp.Free;
    end;


  finally
    ScreenImg.EndUpdate;
  end;

end;

procedure TGamePreviewScreen.SaveLevelImage;
var
  Dlg : TSaveDialog;
  SaveName: String;
  TempBitmap: TBitmap32;
begin

  if GameParams.DumpMode then
  begin
    if not ForceDirectories(ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\') then Exit;
    SaveName := ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\' + LeadZeroStr(GameParams.Info.dSection + 1, 2) + LeadZeroStr(GameParams.Info.dLevel + 1, 2) + '.png'
  end else begin
    Dlg := TSaveDialog.Create(self);
    dlg.Filter := 'PNG Image (*.png)|*.png';
    dlg.FilterIndex := 1;
    //dlg.InitialDir := '"' + GameParams. + '/"';
    dlg.DefaultExt := '.png';
    if dlg.Execute then
      SaveName := dlg.FileName
    else
      SaveName := '';
    Dlg.Free;

    if SaveName = '' then Exit;
  end;

  TempBitmap := TBitmap32.Create;
  TempBitmap.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);
  GameParams.Renderer.RenderWorld(TempBitmap, not GameParams.NoBackgrounds);
  TPngInterface.SavePngFile(SaveName, TempBitmap, true);
  TempBitmap.Free;

end;

procedure TGamePreviewScreen.BuildScreenInvis;
var
  Inf: TRenderInfoRec;
  TempBmp: TBitmap32;
begin
  Assert(GameParams <> nil);
  TempBmp := TBitmap32.Create;

  //ScreenImg.BeginUpdate;
  try
    //MainPal := GetDosMainMenuPaletteColors32;
    //InitializeImageSizeAndPosition(640, 350);
    //ExtractBackGround;
    //ExtractPurpleFont;


    // prepare the renderer, this is a little bit shaky (wrong place)
    with GameParams do
    begin
      Inf.Level:=Level;
      CheckLemmingCount(Level);
      Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
      if ReplayCheckIndex <> -2 then
        Renderer.RenderWorld(TempBmp, not GameParams.NoBackgrounds); // because currently some important preparing code is here. it shouldn't be.
                                       // image dumping doesn't need this because it calls RenderWorld to render the output image      
    end;

    if GameParams.DumpMode and fCanDump then SaveLevelImage;


  finally
    TempBmp.Free;
  end;
end;


constructor TGamePreviewScreen.Create(aOwner: TComponent);
begin
  inherited;
  OnKeyDown := Form_KeyDown;
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;
end;

destructor TGamePreviewScreen.Destroy;
begin
  inherited;
end;

procedure TGamePreviewScreen.VGASpecPrep;
begin
end;

procedure TGamePreviewScreen.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_SaveImage then
  begin
    SaveLevelImage;
    Exit;
  end;
  case Key of
    VK_ESCAPE: begin
               if GameParams.fTestMode then
                   CloseScreen(gstExit)
                 else
                   CloseScreen(gstMenu);
               end;
    VK_RETURN: begin VGASpecPrep; CloseScreen(gstPlay); end;
          $52: ShowRecords;
    VK_F2: CloseScreen(gstLevelSelect);
    VK_LEFT: PreviousLevel;
    VK_RIGHT: NextLevel;
    VK_DOWN: PreviousRank;
    VK_UP: NextRank;
  end;
end;

procedure TGamePreviewScreen.Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    VGASpecPrep;
    CloseScreen(gstPlay);
    end;
end;

procedure TGamePreviewScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  if Button = mbLeft then
    begin
    VGASpecPrep;
    CloseScreen(gstPlay);
    end;
end;


function TGamePreviewScreen.GetScreenText: string;
var
  Perc, TL: string;
  RR: String;
begin
  Assert(GameParams <> nil);

//  with GameParams.Level.Info do
  begin

      Perc := i2s(GameParams.Level.Info.RescueCount) + ' Lemming';
      if GameParams.Level.Info.RescueCount <> 1 then Perc := Perc + 's';

      TL := i2s(GameParams.Level.Info.TimeLimit div 60) + ':' + LeadZeroStr(GameParams.Level.Info.TimeLimit mod 60,2);
      if GameParams.Level.Info.TimeLimit > 5999 then TL := '(Infinite)'; //99:59

      if GameParams.OneLevelMode then
      begin
        GameParams.Info.dSectionName := 'Single Level';
        GameParams.Info.dLevel := 0;
      end;


      if GameParams.fTestMode then
      begin
        GameParams.Info.dSectionName := 'TEST MODE';
        GameParams.Info.dLevel := 0;
      end;

      RR := IntToStr(GameParams.Level.Info.ReleaseRate);
      if GameParams.Level.Info.ReleaseRateLocked or (RR = '99') then
        RR := RR + ' (Locked)';


      if Trim(GameParams.Level.Info.Author) = '' then
        Result := Format(SPreviewString,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieGhostCount,
                 Perc,
                 RR,
                 TL,
                 GameParams.Info.dSectionName
               ])
      else
        Result := Format(SPreviewStringAuth,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieGhostCount,
                 Perc,
                 RR,
                 TL,
                 GameParams.Info.dSectionName,
                 GameParams.Level.Info.Author
               ]);

    if GameParams.ForceSkillset <> 0 then
      GameParams.Level.Info.SkillTypes := GameParams.ForceSkillset;
  end;
end;

procedure TGamePreviewScreen.PrepareGameParams(Params: TDosGameParams);
//var
  //Inf: TDosGamePlayInfoRec;
begin
  inherited;

  fCanDump := true;

  with Params, Info do
  begin

    case WhichLevel of
      wlFirst: Style.LevelSystem.FindFirstLevel(Info);
      wlFirstSection: Style.LevelSystem.FindFirstLevel(Info);
      wlLevelCode: Style.LevelSystem.FindLevel(Info);
      wlNext: Style.LevelSystem.FindNextLevel(Info);
      wlSame: Style.LevelSystem.FindLevel(Info);
      wlNextUnlocked: Style.LevelSystem.FindNextUnlockedLevel(Info);
      wlPreviousUnlocked: Style.LevelSystem.FindPreviousUnlockedLevel(Info);
      wlLastUnlocked: Style.LevelSystem.FindLastUnlockedLevel(Info);
    end;

    if not GameParams.OneLevelMode then
    begin
      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := '';

      try
        TBaseDosLevelSystem(Style.LevelSystem).ResetOddtableHistory;
        Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
      except
          fCanDump := false;
          Exit;
      end;

    end else begin

      TBaseDosLevelSystem(Style.LevelSystem).ResetOddtableHistory;
      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := GameParams.LevelString;
      Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
      
    end;

    WhichLevel := wlSame;

  end;
end;

end.

