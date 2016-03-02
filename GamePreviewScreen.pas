{$include lem_directives.inc}

unit GamePreviewScreen;

interface

uses
  PngInterface,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs,
  LemCore, LemStrings, LemDosStructures, LemRendering, LemLevelSystem, LemLevel, LemDosGraphicSet, LemNeoGraphicSet, LemDosStyle,
  LemTypes, GameControl, GameBaseScreen, GameWindow;

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
    procedure CheckLemmingCount(aLevel: TLevel; aGraphicSet: TBaseDosGraphicSet);
    procedure NextLevel;
    procedure PreviousLevel;
    procedure ShowRecords;
    //procedure SimulateSpawn;
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
end;

procedure TGamePreviewScreen.BuildScreen;
var
  Inf: TRenderInfoRec;
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
      Inf.Level:=Level;
      Lw := Level.Info.Width;
      Lh := Level.Info.Height;
      Inf.GraphicSet := Graphicset;
      CheckLemmingCount(Level, Graphicset);
      Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
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
      GameParams.Renderer.RenderWorld(W, True);
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
  GameParams.Renderer.RenderWorld(TempBitmap, True);
  TPngInterface.SavePngFile(SaveName, TempBitmap, true);
  TempBitmap.Free;

end;

procedure TGamePreviewScreen.BuildScreenInvis;
var
  Inf: TRenderInfoRec;
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
      Inf.Level:=Level;
      Inf.GraphicSet := Graphicset;
      CheckLemmingCount(Level, Graphicset);
      Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
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
begin
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
      wlNext: Style.LevelSystem.FindNextLevel(Info, GameResult.gSecretGoto, fLevelOverride);
      wlSame: Style.LevelSystem.FindLevel(Info);
      wlNextUnlocked: Style.LevelSystem.FindNextUnlockedLevel(Info, Params.CheatCodesEnabled);
      wlPreviousUnlocked: Style.LevelSystem.FindPreviousUnlockedLevel(Info, Params.CheatCodesEnabled);
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

    fLevelOverride := (Params.Level.Info.PostSecretRank shl 8) + Params.Level.Info.PostSecretLevel;

  end;
end;

end.

