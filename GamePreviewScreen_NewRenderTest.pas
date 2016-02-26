{$include lem_directives.inc}

unit GamePreviewScreen;

interface

uses
  PngInterface,
  LemNeoRendering,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  UMisc, PngImage, Dialogs,
  LemCore, LemStrings, LemDosStructures, {LemRendering,} LemLevelSystem, LemLevel, LemDosGraphicSet, LemNeoGraphicSet, LemDosStyle,
  LemTypes, GameControl, GameBaseScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseScreen)
  private
    fRickrolling : Boolean;
    fCanDump: Boolean;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure VGASpecPrep;
    procedure SaveLevelImage;
    function GetScreenText: string;
    procedure CheckLemmingCount(aLevel: TLevel; aGraphicSet: TBaseDosGraphicSet);
    procedure NextLevel;
    procedure PreviousLevel;
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

uses LemGraphicSet, {LemDosGraphicSet, LemLevel,} FBaseDosForm;

{ TGamePreviewScreen }

procedure TGamePreviewScreen.SimulateSpawn;
var
  i: Integer;
  IgnoreLemmings: Integer;
  LemsSpawned: Integer;
  CheckZombies: Boolean;
  CheckGhosts: Boolean;
  CompareVal: Byte;

  procedure FindNextWindow;
  begin
    if Length(GameParams.Level.Info.WindowOrder) = 0 then
    begin
      repeat
        i := i + 1;
        if i = GameParams.Level.InteractiveObjects.Count then i := 0;
      until GameParams.GraphicSet.MetaObjects[GameParams.Level.InteractiveObjects[i].Identifier].TriggerEffect = 23;
    end else begin
      i := LemsSpawned mod Length(GameParams.Level.Info.WindowOrder);
    end;
  end;

begin
  // A full blown simulation of lemming spawning is the only way to
  // check how many Zombies and Ghosts the level has.
  GameParams.Level.Info.ZombieGhostCount := 0;
  IgnoreLemmings := 0;
  LemsSpawned := 0;

  // Trigger effect 13: Preplaced lemming
  // Trigger effect 23: Window

  with GameParams.Level do
  begin
    CheckZombies := (Info.GimmickSet and $4000000) <> 0;
    CheckGhosts := (Info.GimmickSet2 and $20) <> 0;

    if not (CheckZombies or CheckGhosts) then Exit;

    CompareVal := 0;
    if CheckZombies then CompareVal := CompareVal + 64;
    if CheckGhosts then CompareVal := CompareVal + 128;

    for i := 0 to InteractiveObjects.Count-1 do
    begin
      if GameParams.GraphicSet.MetaObjects[InteractiveObjects[i].Identifier].TriggerEffect <> 13 then Continue;
      LemsSpawned := LemsSpawned + 1; // to properly emulate the spawn order glitch, since no decision on how to fix it has been reached
      if (InteractiveObjects[i].TarLev and CompareVal) <> 0 then Info.ZombieGhostCount := Info.ZombieGhostCount + 1;
    end;

    i := -1;
    while LemsSpawned < Info.LemmingsCount do
    begin
      FindNextWindow;
      if GameParams.GraphicSet.MetaObjects[InteractiveObjects[i].Identifier].TriggerEffect <> 23 then Continue;
      LemsSpawned := LemsSpawned + 1;
      if (InteractiveObjects[i].TarLev and CompareVal) <> 0 then Info.ZombieGhostCount := Info.ZombieGhostCount + 1;
    end;
  end;
end;

procedure TGamePreviewScreen.ShowRecords;
var
  maxlem, mintime, maxscore: Integer;
  beaten: Boolean;
  mins, secs, frms: Integer;
  outstring: String;
begin

  with GameParams.SaveSystem do
  begin
    maxlem := GetLemmingRecord(GameParams.Info.dSection, GameParams.Info.dLevel);
    mintime := GetTimeRecord(GameParams.Info.dSection, GameParams.Info.dLevel);
    maxscore := GetScoreRecord(GameParams.Info.dSection, GameParams.Info.dLevel);
    beaten := CheckCompleted(GameParams.Info.dSection, GameParams.Info.dLevel);
    frms := mintime mod 17;
    secs := (mintime div 17) mod 60;
    mins := (mintime div 17) div 60;
    outstring := GameParams.Info.dSectionName + ' ' + i2s(GameParams.Info.dLevel + 1) + #13 + #13;

    if beaten then
      outstring := outstring + 'Completed: Yes' + #13 +
                 'Most Lemmings Saved: ' + i2s(maxlem) + #13 +
                 'Best Time: ' + i2s(mins) + ':' + LeadZeroStr(secs, 2) + ' + ' + i2s(frms) + ' frames' + #13 +
                 'Best Score: ' + i2s(maxscore)
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
  GameParams.Style.LevelSystem.FindNextUnlockedLevel(FindInfo, GameParams.CheatCodesEnabled);
  if FindInfo.dLevel <> GameParams.Info.dLevel then
  begin
    GameParams.ShownText := false;
    GameParams.Rickrolled := false;
    GameParams.WhichLevel := wlNextUnlocked;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.PreviousLevel;
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  GameParams.Style.LevelSystem.FindPreviousUnlockedLevel(FindInfo, GameParams.CheatCodesEnabled);
  if FindInfo.dLevel <> GameParams.Info.dLevel then
  begin
    GameParams.ShownText := false;
    GameParams.Rickrolled := false;
    GameParams.WhichLevel := wlPreviousUnlocked;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.CheckLemmingCount(aLevel: TLevel; aGraphicSet: TBaseDosGraphicSet);
var
  i: Integer;
  MinCount : Integer;
  FoundWindow : Boolean;
begin
  MinCount := 0;
  FoundWindow := false;
  for i := 0 to aLevel.InteractiveObjects.Count - 1 do
  begin
    //if aLevel.InteractiveObjects[i].Identifier = 1 then FoundWindow := true;
    if aGraphicSet.MetaObjects[aLevel.InteractiveObjects[i].Identifier].TriggerEffect = 23 then FoundWindow := true;
    if aGraphicSet.MetaObjects[aLevel.InteractiveObjects[i].Identifier].TriggerEffect = 13 then Inc(MinCount);
  end;
  if (not FoundWindow) or (aLevel.Info.LemmingsCount < MinCount) then aLevel.Info.LemmingsCount := MinCount;

  SimulateSpawn; // to check for ghosts and zombies
end;

procedure TGamePreviewScreen.BuildScreen;
var
  //Inf: TRenderInfoRec;
  TestRenderer: TRenderer;
  Mainpal: TArrayOfColor32;
  Temp, W: TBitmap32;
  DstRect: TRect;
  epf : String;
  Lw, Lh : Integer;
  GSName: String;
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
      with GraphicSet do
      begin
        ClearMetaData;
        ClearData;
        GraphicSetId := Level.Info.GraphicSet mod 256;
        GraphicSetIdExt := Level.Info.GraphicSetEx;

        epf := '';

        GraphicSetFile := GameParams.Directory + Level.Info.GraphicSetName + '.dat';

        if (GameParams.fTestMode) and not (GameParams.fTestGroundFile = '*') then
          GraphicSetFile := GameParams.fTestGroundFile;

        if GraphicSetIdExt = 0 then
          begin
          GraphicExtFile := '';
          end
        else
          begin
          GraphicExtFile := GameParams.Directory + epf + Level.Info.VgaspecFile;
          if not FileExists(GraphicExtFile) then GraphicExtFile := GameParams.Directory + Level.Info.VgaspecFile;

          if GameParams.fTestMode and not (GameParams.fTestVgaspecFile = '*') then GraphicExtFile := GameParams.fTestVgaspecFile;

          end;

        ReadMetaData;
        ReadData;
      end;
      //Inf.Level:=Level;
      Lw := Level.Info.Width;
      Lh := Level.Info.Height;
      //Inf.GraphicSet := Graphicset;
      CheckLemmingCount(Level, Graphicset);
      //Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
    end;

    with GameParams.Info do
      GameParams.SaveSystem.UnlockLevel(dSection, dLevel);

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
      TestRenderer := TRenderer.Create(GameParams);
      TestRenderer.SetLevel(GameParams.Level);
      TestRenderer.RenderMaps(W);
      //GameParams.Renderer.RenderWorld(W, True);
      DstRect := Rect(0, 0, (lw div 4), (lh div 4)); // div 4
      RectMove(DstRect, (120 + (200 - (lw div 8))), (20 + (20 - (lh div 8)))); // set location
      TLinearResampler.Create(W);
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
  TestRenderer: TRenderer;
  Dlg : TSaveDialog;
  SaveName: String;
  TempBitmap: TBitmap32;
  OutImage: TPngObject;
  X, Y: Integer;
  C: TColor32;
  A, R, G, B: Byte;
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

try
  TempBitmap := TBitmap32.Create;
  TestRenderer := TRenderer.Create(GameParams);
  TestRenderer.SetLevel(GameParams.Level);
  TempBitmap.SetSize(GameParams.Level.Info.Width, GameParams.Level.Info.Height);
  TestRenderer.RenderMaps(TempBitmap);
  SavePngFile(SaveName, TempBitmap);
  {OutImage := TPngObject.CreateBlank(COLOR_RGB, 8, TempBitmap.Width, TempBitmap.Height);
  for Y := 0 to TempBitmap.Height - 1 do
    for X := 0 to TempBitmap.Width - 1 do
    begin
      C := TempBitmap.Pixel[X, Y];
      A := C shr 24;
      R := C shr 16;
      G := C shr 8;
      B := C;
      C := (A shl 24) + (B shl 16) + (G shl 8) + (R);
      OutImage.Pixels[X, Y] := C;
    end;
  OutImage.CompressionLevel := 9;
  OutImage.SaveToFile(SaveName);}
finally
  OutImage.Free;
  TempBitmap.Free;
  TestRenderer.Free;
end;
end;

procedure TGamePreviewScreen.BuildScreenInvis;
var
  //Inf: TRenderInfoRec;
  Mainpal: TArrayOfColor32;
  //Temp, W: TBitmap32;
  //DstRect: TRect;
  epf : String;
begin
  Assert(GameParams <> nil);

  //ScreenImg.BeginUpdate;
  try
    //MainPal := GetDosMainMenuPaletteColors32;
    //InitializeImageSizeAndPosition(640, 350);
    //ExtractBackGround;
    //ExtractPurpleFont;


    // prepare the renderer, this is a little bit shaky (wrong place)
    with GameParams do
    begin
      with GraphicSet do
      begin
        ClearMetaData;
        ClearData;
        GraphicSetId := Level.Info.GraphicSet mod 256;
        GraphicSetIdExt := Level.Info.GraphicSetEx;

        epf := '';

        GraphicSetFile := GameParams.Directory + Level.Info.GraphicSetName + '.dat';


        if GameParams.fTestMode and not (GameParams.fTestGroundFile = '*') then
          GraphicSetFile := GameParams.fTestGroundFile;


        if GraphicSetIdExt = 0 then
          begin
          GraphicExtFile := '';
          end
        else
          begin
          GraphicExtFile := GameParams.Directory + epf + Level.Info.VgaspecFile;
          if not FileExists(GraphicExtFile) then GraphicExtFile := GameParams.Directory + Level.Info.VgaspecFile;

          if GameParams.fTestMode and not (GameParams.fTestVgaspecFile = '*') then GraphicExtFile := GameParams.fTestVgaspecFile;

          end;
        ReadMetaData;
        ReadData;
      end;
      //Inf.Level:=Level;
      //Inf.GraphicSet := Graphicset;
      CheckLemmingCount(Level, Graphicset);
      //Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
    end;

    if GameParams.DumpMode and fCanDump then SaveLevelImage;


  finally
    
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
var
  //Inf: TRenderInfoRec;
  W: TBitmap32;
  Mainpal: TArrayOfColor32;
begin

    with GameParams.Info do
    if fRickrolling and (not GameParams.OneLevelMode) then
    begin
      GameParams.Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, GameParams.Level);
      Include(GameParams.MiscOptions, moRickrolled);
    end;

  if GameParams.Level.Info.GraphicSetEx > 0 then BuildScreenInvis;

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
    VK_LEFT: PreviousLevel;
    VK_RIGHT: NextLevel;
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
  tperc: Integer;
  tcount: Integer;
  i: Integer;
begin
  Assert(GameParams <> nil);

//  with GameParams.Level.Info do
  begin

    if GameParams.UsePercentages <> 0 then
      begin
      tcount := GameParams.Level.Info.LemmingsCount;
      if (GameParams.UsePercentages = 2) and ((GameParams.Level.Info.SkillTypes and $1) <> 0) then
      begin
        tcount := tcount + GameParams.Level.Info.ClonerCount;
        for i := 0 to GameParams.Level.InteractiveObjects.Count-1 do
          with GameParams.Level.InteractiveObjects[i] do
            if (GameParams.GraphicSet.MetaObjects[Identifier].TriggerEffect = 14)
            and (Skill = 15) then tcount := tcount + 1;
      end;
      tperc := Percentage(tcount,
                                GameParams.Level.Info.RescueCount);
      if GameParams.Level.Info.DisplayPercent <> 0 then tperc := GameParams.Level.Info.DisplayPercent;
      Perc := i2s(tperc) + '%';
      end else
      begin
      Perc := i2s(GameParams.Level.Info.RescueCount) + ' Lemming';
      if GameParams.Level.Info.RescueCount <> 1 then Perc := Perc + 's';
      end;

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


      if Trim(GameParams.Level.Info.Author) = '' then
        Result := Format(SPreviewString,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieGhostCount,
                 Perc,
                 GameParams.Level.Info.ReleaseRate,
                 TL,
                 GameParams.Info.dSectionName
               ])
      else
        Result := Format(SPreviewStringAuth,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieGhostCount,
                 Perc,
                 GameParams.Level.Info.ReleaseRate,
                 TL,
                 GameParams.Info.dSectionName,
                 GameParams.Level.Info.Author
               ]);

         if (GameParams.ForceGimmick <> 0) or (GameParams.ForceGimmick2 <> 0) or (GameParams.ForceGimmick3 <> 0) then
         begin
           GameParams.Level.Info.SuperLemming := 0;
           GameParams.Level.Info.GimmickSet := (GameParams.Level.Info.GimmickSet and $C0000000)
                                            or (GameParams.ForceGimmick and $3FFFFFFF);
           GameParams.Level.Info.GimmickSet2 := GameParams.ForceGimmick2;
           GameParams.Level.Info.GimmickSet3 := GameParams.ForceGimmick3;
           GameParams.Level.Info.fKaroshi := GameParams.Level.Info.GimmickSet and 8 <> 0;
           GameParams.Level.Info.fSuperlem := GameParams.Level.Info.GimmickSet and 1 <> 0;
         end;

    if GameParams.ForceSkillset <> 0 then
      GameParams.Level.Info.SkillTypes := GameParams.ForceSkillset;

    if (GameParams.Level.Info.SuperLemming = $4204) or (GameParams.Level.Info.SuperLemming = $4209) or GameParams.Level.Info.fKaroshi then
      if Trim(GameParams.Level.Info.Author) = '' then
        Result := Format(KPreviewString,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount,
                 Perc,
                 GameParams.Level.Info.ReleaseRate,
                 TL,
                 GameParams.Info.dSectionName
               ])
        else
          Result := Format(KPreviewStringAuth,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount,
                 Perc,
                 GameParams.Level.Info.ReleaseRate,
                 TL,
                 GameParams.Info.dSectionName,
                 GameParams.Level.Info.Author
               ]);
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
      wlNext: Style.LevelSystem.FindNextLevel(Info, GameResult.gSecretGoto, fLevelOverride);
      wlSame: Style.LevelSystem.FindLevel(Info);
      wlNextUnlocked: Style.LevelSystem.FindNextUnlockedLevel(Info, Params.CheatCodesEnabled);
      wlPreviousUnlocked: Style.LevelSystem.FindPreviousUnlockedLevel(Info, Params.CheatCodesEnabled);
      wlLastUnlocked: Style.LevelSystem.FindLastUnlockedLevel(Info);
    end;

    (*
    if not GameResult.gValid then
    begin
      if not Info.dValid then
        Style.LevelSystem.FindFirstLevel(Info)
      else
        Style.LevelSystem.FindLevel(Info) // used to fill sectionname
    end
    else if GameResult.gSuccess then
    begin
      Style.LevelSystem.FindNextLevel(Info);
    end;
    ClearGameResult;
      *)

    fRickrolling := false;

    if not GameParams.OneLevelMode then
    begin
      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := '';

    try
      Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
    except
      fCanDump := false;
      Exit;
    end;

    if ((GameParams.Level.Info.GimmickSet and $80000000) <> 0)
    and (not (moRickrolled in GameParams.MiscOptions))
    and (not (GameParams.SaveSystem.CheckCompleted(dSection, dLevel))) then
    begin
      Style.LevelSystem.LoadSingleLevel(dPack, GameParams.Level.Info.BnsRank, GameParams.Level.Info.BnsLevel, Level);
      fRickrolling := true;
    end;

    end else begin

      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := GameParams.LevelString;
      Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
      
    end;

    WhichLevel := wlSame;

    fLevelOverride := (Params.Level.Info.PostSecretRank shl 8) + Params.Level.Info.PostSecretLevel;

//    Style.LevelSystem.LoadSingleLevel(0, 3, 1, Level);

  end;
end;

end.

