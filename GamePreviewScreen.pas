unit GamePreviewScreen;

interface

uses
  System.Types,
  StrUtils,
  Generics.Collections,
  LemTypes,
  PngInterface,
  LemNeoLevelPack,
  LemmixHotkeys,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Layers, GR32_Resamplers, GR32_Image,
  UMisc, Dialogs,
  LemCore, LemStrings, LemRendering, LemLevel, LemNeoTheme, LemGame,
  LemGadgetsMeta, LemGadgets, LemMenuFont,
  LemTalisman,
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen, GameWindow,
  SharedGlobals;

type
  TGamePreviewScreen = class(TGameBaseMenuScreen)
    private
      function GetPreviewText: TextLineArray;
      procedure LoadPreviewTextColours;

      procedure NextLevel;
      procedure PreviousLevel;
      procedure NextRank;
      procedure PreviousRank;

      procedure BeginPlay;
      procedure ExitToMenu;

      procedure SaveLevelImage;
      procedure TryLoadReplay;

      procedure DrawLevelPreview;

      procedure MakeLoadReplayClickable;
      procedure MakeLevelSelectClickable;
      procedure MakeExitToMenuClickable;

      procedure SetWindowCaption;
    protected
      procedure DoAfterConfig; override;
      function GetWallpaperSuffix: String; override;

      procedure AfterCancelLevelSelect; override;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure BuildScreen; override;
      procedure PrepareGameParams; override;
      procedure CloseScreen(NextScreen: TGameScreenType); override;
  end;

implementation

uses
  CustomPopup, FBaseDosForm, FLevelInfo, GameSound, LemNeoParser;

var
  TitleShift: Extended;       // 0.600; - Red
  GroupShift: Extended;       // 0.600; - Red
  NumLemsShift: Extended;     // 0.250; - Blue
  RescueLemsShift: Extended;  // 0;     - Green (default)
  ReleaseRateShift: Extended; // 0.800; - Yellow
  TimeLimitShift: Extended;   // 0.150; - Teal
  AuthorShift: Extended;      // 0.500; - Violet

{ TGamePreviewScreen }

constructor TGamePreviewScreen.Create(aOwner: TComponent);
begin
  inherited;
end;

destructor TGamePreviewScreen.Destroy;
begin
  inherited;
end;

procedure TGamePreviewScreen.CloseScreen(NextScreen: TGameScreenType);
//var
  //F: TFManageStyles;
begin
  if NextScreen = gstPlay then
  begin
    if GameParams.Level.HasAnyFallbacks then
    begin
      //if GameParams.EnableOnline then
      //begin
        //case RunCustomPopup(self, 'Missing styles',
          //'Some pieces used by this level are missing. Do you want to attempt to download missing styles?',
          //'Yes|No|Open Style Manager') of
          //1:
            //begin
              //DownloadMissingStyles;
              //inherited CloseScreen(gstPreview);
            //end;
          //3:
            //begin
              //F := TFManageStyles.Create(self);
              //try
                //F.ShowModal;
              //finally
                //F.Free;
                //inherited CloseScreen(gstPreview);
              //end;
            //end;
        //end;
      //end else
        ShowMessage('This level contains pieces which are missing from the styles folder. ' +
                    'Please contact the level author or download the style manually ' +
                    'via www.lemmingsforums.net.');
    end else
      inherited CloseScreen(gstPlay);
  end else if NextScreen = gstText then
    inherited CloseScreen(gstText)
  else
    inherited;
end;

procedure TGamePreviewScreen.NextLevel;
begin
  if GameParams.CurrentLevel.Group.Levels.Count > 1 then
  begin
    GameParams.NextLevel;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.PreviousLevel;
begin
  if GameParams.CurrentLevel.Group.Levels.Count > 1 then
  begin
    GameParams.PrevLevel;
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePreviewScreen.NextRank;
begin
  GameParams.NextGroup;
  CloseScreen(gstPreview);
end;

procedure TGamePreviewScreen.PreviousRank;
begin
  GameParams.PrevGroup;
  CloseScreen(gstPreview);
end;

procedure TGamePreviewScreen.AfterCancelLevelSelect;
begin
  inherited;
  GameParams.LoadCurrentLevel;
  GameParams.Renderer.RenderWorld(nil, not GameParams.NoBackgrounds); // Some necessary prep work is done in here
end;

procedure TGamePreviewScreen.BeginPlay;
var
  CurLevel: TLevel;
  CurInfo: TLevelInfo;
  CurTheme: TNeoTheme;
begin
  CurLevel := GameParams.Level;
  CurInfo := CurLevel.Info;
  CurTheme := GameParams.Renderer.Theme;

  // See if we need to show the sprites fallback message
  if (CurTheme.SpriteFallbackMessage <> '') then
  begin
    ShowMessage(CurTheme.SpriteFallbackMessage);

    CurTheme.SpriteFallbackMessage := '';
  end;

  // See if we need to show the missing sounds message
  if (CurTheme.MissingSoundsList.Count > 0) then
  begin
    ShowMessage('Some sounds are missing for ' + CurTheme.Name + ':' + sLineBreak + sLineBreak +
                 CurTheme.MissingSoundsList.Text + sLineBreak +
                 'Falling back to default sounds.');

    CurTheme.MissingSoundsList.Clear;
  end;

  // Make sure there is at least one exit if we're not in test mode
  if (CurInfo.NormalExitCount + CurInfo.RivalExitCount <= 0) and (GameParams.TestModeLevel = nil) then
  begin
    ShowMessage('This level cannot be played as it doesn''t have an exit!');
    Exit;
  end;

  // Make sure there is at least one available lemming
  if (CurInfo.LemmingsCount <= 0) or (CurInfo.ZombieCount = CurInfo.LemmingsCount) then
  begin
    ShowMessage('This level cannot be played as it doesn''t have any lemmings!');
    Exit;
  end;

  // Check for preview text
  if (CurLevel.PreText.Count > 0)
    and not (GameParams.PlaybackModeActive and GameParams.AutoSkipPreviewPostview) then
    begin
      GameParams.IsPreTextScreen := True;
      CloseScreen(gstText);
    end else
      CloseScreen(gstPlay);
end;

procedure TGamePreviewScreen.OnMouseClick(aPoint: TPoint;
  aButton: TMouseButton);
begin
  inherited;
  case aButton of
    mbLeft: BeginPlay;
    mbRight: ExitToMenu;
    mbMiddle:
    begin
      GameParams.ShownText := false;
      BeginPlay;
    end;
  end;
end;

procedure TGamePreviewScreen.DrawLevelPreview;
var
  LevelPreviewImage: TBitmap32;
  DstRect: TRect;
  Lw, Lh : Integer;
  LevelScale: Double;
begin
  LevelPreviewImage := TBitmap32.Create;
  try
    Lw := GameParams.Level.Info.Width;
    Lh := GameParams.Level.Info.Height;

    LevelPreviewImage.SetSize(Lw, Lh);
    LevelPreviewImage.Clear(0);

    GameParams.Renderer.RenderWorld(LevelPreviewImage, not GameParams.NoBackgrounds);
    TLinearResampler.Create(LevelPreviewImage);
    LevelPreviewImage.DrawMode := dmBlend;
    LevelPreviewImage.CombineMode := cmMerge;

    // Draw the level preview
    if GameParams.ShowMinimap and not GameParams.FullScreen then
      LevelScale := MM_INTERNAL_SCREEN_WIDTH / lw
    else if GameParams.FullScreen then
      LevelScale := FS_INTERNAL_SCREEN_WIDTH / lw
    else
      LevelScale := INTERNAL_SCREEN_WIDTH / lw;

    if LevelScale > 160 / lh then LevelScale := 160 / lh;
    DstRect := Rect(0, 0, Trunc(lw * LevelScale), Trunc(lh * LevelScale));

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      OffsetRect(DstRect, (MM_INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2))
    else if GameParams.FullScreen then
      OffsetRect(DstRect, (FS_INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2))
    else
      OffsetRect(DstRect, (INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2));

    LevelPreviewImage.DrawTo(ScreenImg.Bitmap, DstRect, LevelPreviewImage.BoundsRect);
  finally
    LevelPreviewImage.Free;
  end;
end;

procedure TGamePreviewScreen.MakeLoadReplayClickable;
var
  R: TClickableRegion;
begin
  if GameParams.PlaybackModeActive then
    Exit;

  if GameParams.ShowMinimap and not GameParams.FullScreen then
    R := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay)
  else if GameParams.FullScreen then
    R := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay)
  else
    R := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);

  R.AddKeysFromFunction(lka_LoadReplay);
end;

procedure TGamePreviewScreen.MakeLevelSelectClickable;
var
  R: TClickableRegion;
begin
  if GameParams.PlaybackModeActive then
    Exit;

  if GameParams.ShowMinimap and not GameParams.FullScreen then
    R := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
  else if GameParams.FullScreen then
    R := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect)
  else
    R := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);

  R.ShortcutKeys.Add(VK_F3);
end;

procedure TGamePreviewScreen.MakeExitToMenuClickable;
var
  S: String;
  R: TClickableRegion;
  P: TPoint;
begin
  if GameParams.PlaybackModeActive then
  begin
    S := 'Cancel Playback Mode';

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else
      P := Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
  end else begin
    S := SOptionToMenu;

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      P := Point(MM_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else if GameParams.FullScreen then
      P := Point(FS_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
    else
      P := Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y)
  end;

  R := MakeClickableText(Point(P), S, ExitToMenu);
  R.ShortcutKeys.Add(VK_ESCAPE);
end;

procedure TGamePreviewScreen.BuildScreen;
var
  Lines: TextLineArray;
const
  TEXT_Y_POSITION = 170;
begin
  CurrentScreen := gstPreview;
  SetWindowCaption;

  fClickableRegions.Clear;
  CustomAssert(GameParams <> nil, 'GameParams not initialized correctly');

  ScreenImg.BeginUpdate;
  try
    DrawLevelPreview;

    // Draw text
    Lines := GetPreviewText;
    MenuFont.DrawTextLines(Lines, ScreenImg.Bitmap, TEXT_Y_POSITION);

    DrawClassicModeButton;

    MakeLoadReplayClickable;
    MakeLevelSelectClickable;
    MakeExitToMenuClickable;

    MakeHiddenOption(VK_SPACE, BeginPlay);
    MakeHiddenOption(VK_RETURN, BeginPlay);
    MakeHiddenOption(VK_F2, ShowConfigMenu);
    MakeHiddenOption(lka_SaveImage, SaveLevelImage);
    MakeHiddenOption(lka_CancelPlayback, CancelPlaybackMode);

    if not GameParams.PlaybackModeActive then
    begin
      MakeHiddenOption(VK_LEFT, PreviousLevel);
      MakeHiddenOption(VK_RIGHT, NextLevel);
      MakeHiddenOption(VK_DOWN, PreviousRank);
      MakeHiddenOption(VK_UP, NextRank);
    end;

    MakeTalismanOptions;

    if GameParams.PlaybackModeActive and GameParams.AutoSkipPreviewPostview then
      BeginPlay
    else
      DrawAllClickables;
  finally
    ScreenImg.EndUpdate;
  end;
end;

procedure TGamePreviewScreen.SetWindowCaption;
var
  s, Title: string;
  CurTheme: TNeoTheme;
  RescueCount, LemCount, CollectibleCount: Integer;
begin
  Title := GameParams.Level.Info.TItle;
  RescueCount := GameParams.Level.Info.RescueCount;
  LemCount := GameParams.Level.Info.LemmingsCount;
  CollectibleCount := GameParams.Level.Info.CollectibleCount;
  CurTheme := GameParams.Renderer.Theme;

  s := 'SuperLemmix - ' + Title + ' - Save ' + IntToStr(RescueCount)
       + ' of ' + IntToStr(LemCount) + ' ';

  if LemCount = 1 then
    s := s + CurTheme.LemNamesSingular
  else
    s := s + CurTheme.LemNamesPlural;

  if CollectibleCount <> 0 then
    s := s + ' - ' + IntToStr(CollectibleCount) + ' Diamonds to collect';

  GameParams.MainForm.Caption := s;
end;

procedure TGamePreviewScreen.SaveLevelImage;
var
  Dlg : TSaveDialog;
  SaveName: String;
  TempBitmap: TBitmap32;
begin
  Dlg := TSaveDialog.Create(self);
  Dlg.Filter := 'PNG Image (*.png)|*.png';
  Dlg.FilterIndex := 1;
  Dlg.DefaultExt := '.png';
  Dlg.Options := [ofOverwritePrompt, ofEnableSizing];
  if Dlg.Execute then
    SaveName := dlg.FileName
  else
    SaveName := '';
  Dlg.Free;

  if SaveName = '' then Exit;

  TempBitmap := TBitmap32.Create;
  TempBitmap.SetSize(GameParams.Level.Info.Width * ResMod, GameParams.Level.Info.Height * ResMod);
  GameParams.Renderer.RenderWorld(TempBitmap, not GameParams.NoBackgrounds);
  TPngInterface.SavePngFile(SaveName, TempBitmap, true);
  TempBitmap.Free;
end;

procedure TGamePreviewScreen.TryLoadReplay;
begin
  // LoadReplay is a function, not a procedure, so this needs to be here as a wraparound.
  LoadReplay;
end;

procedure TGamePreviewScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('menu');
end;

function TGamePreviewScreen.GetWallpaperSuffix: String;
begin
  Result := 'preview';
end;

procedure TGamePreviewScreen.ExitToMenu;
begin
  if GameParams.TestModeLevel <> nil then
    CloseScreen(gstExit)
  else begin
    GameParams.PlaybackModeActive := False;
    CloseScreen(gstMenu);
  end;
end;

function TGamePreviewScreen.GetPreviewText: TextLineArray;
const
  LINE_Y_SPACING = 28;
var
  HueShift: TColorDiff;
  Entry: TNeoLevelEntry;
  Level: TLevel;
  Theme: TNeoTheme;

  function HasSpecialLemmings: Boolean;
  begin
    Result := False or (Level.Info.NeutralCount > 0)
                    or (Level.Info.ZombieCount > 0)
                    or (Level.Info.RivalCount > 0);
  end;

  function RegularLemmingsCount: Integer;
  begin
    Result := (Level.Info.LemmingsCount - Level.Info.ZombieCount
                                        - Level.Info.NeutralCount
                                        - Level.Info.RivalCount);
  end;
begin
  Entry := GameParams.CurrentLevel;
  Level := GameParams.Level;
  Theme := GameParams.Renderer.Theme;

  FillChar(HueShift, SizeOf(TColorDiff), 0);

  SetLength(Result, 7);
  LoadPreviewTextColours;

  HueShift.HShift := TitleShift;
  Result[0].Line := Entry.Title;
  Result[0].ColorShift := HueShift;
  Result[0].yPos := 168;

  HueShift.HShift := GroupShift;
  Result[1].yPos := Result[0].yPos + 40;
  Result[1].Line := Entry.Group.Name;
  if Entry.Group.Parent = nil then
  begin
    Result[1].Line := 'Miscellaneous Levels'
  end else
  begin
    if Entry.Group.IsOrdered then
    Result[1].Line := Result[1].Line + ' ' + IntToStr(Entry.GroupIndex + 1);
  end;
  Result[1].ColorShift := HueShift;

  HueShift.HShift := NumLemsShift;
  Result[2].yPos := Result[1].yPos + LINE_Y_SPACING;

  if HasSpecialLemmings then
  begin
    if (Level.Info.LemmingsCount = 1) then
      Result[2].Line := Result[2].Line + IntToStr(RegularLemmingsCount) + ' '
                        + Theme.LemNamesSingular
    else if (Level.Info.LemmingsCount > 1) then
      Result[2].Line := Result[2].Line + IntToStr(RegularLemmingsCount) + ' '
                        + Theme.LemNamesPlural;

    if (Level.Info.RivalCount = 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.RivalCount) + ' Rival'
    else if (Level.Info.RivalCount > 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.RivalCount) + ' Rivals';

    if (Level.Info.NeutralCount = 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.NeutralCount) + ' Neutral'
    else if (Level.Info.NeutralCount > 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.NeutralCount) + ' Neutrals';

    if (Level.Info.ZombieCount = 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.ZombieCount) + ' Zombie'
    else if (Level.Info.ZombieCount > 1) then
      Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.ZombieCount) + ' Zombies';
  end else if (Level.Info.LemmingsCount = 1) then
    Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + Theme.LemNamesSingular
  else
    Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + Theme.LemNamesPlural;
  Result[2].ColorShift := HueShift;

  HueShift.HShift := RescueLemsShift;
  Result[3].yPos := Result[2].yPos + LINE_Y_SPACING;
  Result[3].Line := IntToStr(Level.Info.RescueCount) + SPreviewSave;
  Result[3].ColorShift := HueShift;

  HueShift.HShift := ReleaseRateShift;
  Result[4].yPos := Result[3].yPos + LINE_Y_SPACING;
  if Level.Info.SpawnIntervalLocked then
  begin
    Result[4].Line := SPreviewReleaseRate + IntToStr(103 - Level.Info.SpawnInterval) + SPreviewRRLocked;
  end else
  Result[4].Line := SPreviewReleaseRate + IntToStr(103 - Level.Info.SpawnInterval);
  Result[4].ColorShift := HueShift;

  HueShift.HShift := TimeLimitShift;
  Result[5].yPos := Result[4].yPos + LINE_Y_SPACING;
  if Level.Info.HasTimeLimit then
  begin
    Result[5].Line := SPreviewTimeLimit + IntToStr(Level.Info.TimeLimit div 60) + ':'
                    + LeadZeroStr(Level.Info.TimeLimit mod 60, 2);
  end else
  Result[5].Line := 'Infinite Time';
  Result[5].ColorShift := HueShift;

  HueShift.HShift := AuthorShift;
  Result[6].yPos := Result[5].yPos + LINE_Y_SPACING;
  if Level.Info.Author <> '' then
  begin
    Result[6].Line := SPreviewAuthor + Level.Info.Author;
  end else
  Result[6].Line := SPreviewAuthor + ' Anonymous';
  Result[6].ColorShift := HueShift;
end;

procedure TGamePreviewScreen.LoadPreviewTextColours;
var
  Parser: TParser;
  Sec: TParserSection;
  aPath: string;
  aFile: string;

  // Default SLX colours, loaded if custom files don't exist
  procedure ResetColours;
  begin
    TitleShift := 0.600;       // Red
    GroupShift := 0.600;       // Red
    NumLemsShift := 0.250;     // Blue
    RescueLemsShift := 0;      // Green (default)
    ReleaseRateShift := 0.800; // Yellow
    TimeLimitShift := 0.150;   // Teal
    AuthorShift := 0.500;      // Violet
  end;

begin
  ResetColours;

  aFile := 'textcolours.nxmi';
  aPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

  if aPath = '' then
  aPath := AppPath + SFLevels;

  if (GameParams.CurrentLevel = nil)
    or not (FileExists(aPath + aFile) or FileExists(AppPath + SFData + aFile))
      then Exit;

  Parser := TParser.Create;
  try
    if FileExists(aPath + aFile) then
      Parser.LoadFromFile(aPath + aFile)
    else if FileExists(AppPath + SFData + aFile) then
      Parser.LoadFromFile(AppPath + SFData + aFile);

    Sec := Parser.MainSection.Section['preview'];
    if Sec = nil then Exit;

    TitleShift := StrToFloatDef(Sec.LineString['title'], 0.600);
    GroupShift := StrToFloatDef(Sec.LineString['group'], 0.600);
    NumLemsShift := StrToFloatDef(Sec.LineString['lem_count'], 0);
    RescueLemsShift := StrToFloatDef(Sec.LineString['rescue_count'], 0);
    ReleaseRateShift := StrToFloatDef(Sec.LineString['release_rate'], 0.800);
    TimeLimitShift := StrToFloatDef(Sec.LineString['time_limit'], 0.150);
    AuthorShift := StrToFloatDef(Sec.LineString['author'], 0.500);
  finally
    Parser.Free;
  end;
end;

procedure TGamePreviewScreen.PrepareGameParams;
begin
  inherited;

  try
    if not GameParams.OneLevelMode then
      GameParams.LoadCurrentLevel;
  except
    on E : EAbort do
    begin
      ShowMessage(E.Message);
      CloseScreen(gstMenu);
      Raise; // Yet again, to be caught on TBaseDosForm
    end;
  end;

  // Clears the current-replay-in-memory when the level loads
  if (GameParams.ClassicMode and not (GameParams.PlaybackModeActive or GameParams.OpenedViaReplay))
    or not GameParams.ReplayAfterRestart then
      GlobalGame.ReplayManager.Clear(true);

  if GameParams.PlaybackModeActive or GameParams.OpenedViaReplay then
    GameParams.OpenedViaReplay := False; // Reset flag once replay has been successfully loaded
end;

end.

