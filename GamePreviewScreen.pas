unit GamePreviewScreen;

interface

uses
  System.Types,
  StrUtils,
  Generics.Collections,
  LemTypes,
  PngInterface,
  LemNeoLevelPack,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Layers, GR32_Resamplers, GR32_Image,
  UMisc, Dialogs,
  LemCore, LemStrings, LemRendering, LemLevel, LemGame,
  LemGadgetsMeta, LemGadgets, LemMenuFont,
  LemTalisman,
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseMenuScreen)
    private
      fTalRects: TList<TRect>;
      fTalismanImage: TBitmap32;

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

      procedure MakeTalismanOptions;
      procedure HandleTalismanClick;
      procedure HandleCollectibleClick;

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

const
  TALISMAN_PADDING = 8;

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
  fTalRects := TList<TRect>.Create;
  fTalismanImage := nil;
end;

destructor TGamePreviewScreen.Destroy;
begin
  fTalRects.Free;

  if fTalismanImage <> nil then
    fTalismanImage.Free;

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
    end else begin
      GameParams.NextScreen2 := gstPlay;
      inherited CloseScreen(gstText);
    end;
  end else
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
begin
  if GameParams.ShouldShowFallbackMessage then
  begin
    ShowMessage(GameParams.FallbackMessage);

    GameParams.FallbackMessage := '';
    GameParams.ShouldShowFallbackMessage := False;
  end;

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
  SetWindowCaption;

  fClickableRegions.Clear;
  Assert(GameParams <> nil);

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
  RescueCount, LemCount, CollectibleCount: Integer;
begin
  Title := GameParams.Level.Info.TItle;
  RescueCount := GameParams.Level.Info.RescueCount;
  LemCount := GameParams.Level.Info.LemmingsCount;
  CollectibleCount := GameParams.Level.Info.CollectibleCount;

  s := 'SuperLemmix - ' + Title + ' - Save ' + IntToStr(RescueCount)
       + ' of ' + IntToStr(LemCount) + ' ';

  if LemCount = 1 then
    s := s + GameParams.Renderer.Theme.LemNamesSingular
  else
    s := s + GameParams.Renderer.Theme.LemNamesPlural;

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
  ReloadCursor('amiga.png');
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
    GameParams.OpenedViaReplay := False;

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
                        + GameParams.Renderer.Theme.LemNamesSingular
    else if (Level.Info.LemmingsCount > 1) then
      Result[2].Line := Result[2].Line + IntToStr(RegularLemmingsCount) + ' '
                        + GameParams.Renderer.Theme.LemNamesPlural;

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
    Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + GameParams.Renderer.Theme.LemNamesSingular
  else
    Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + GameParams.Renderer.Theme.LemNamesPlural;
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

procedure TGamePreviewScreen.HandleCollectibleClick;
var
  P: TPoint;
  i: Integer;
  F: TLevelInfoPanel;
begin
  P := GetInternalMouseCoordinates;
  for i := 0 to fTalRects.Count-1 do
    if PtInRect(fTalRects[i], P) then
    begin
      F := TLevelInfoPanel.Create(self, nil, fTalismanImage);
      try
        F.Level := GameParams.Level;
        F.ShowCollectiblePopup;
      finally
        F.Free;
      end;
      Break;
    end;
end;

procedure TGamePreviewScreen.HandleTalismanClick;
var
  P: TPoint;
  i: Integer;
  F: TLevelInfoPanel;
begin
  P := GetInternalMouseCoordinates;
  for i := 0 to fTalRects.Count-1 do
    if PtInRect(fTalRects[i], P) then
    begin
      F := TLevelInfoPanel.Create(self, nil, fTalismanImage);
      try
        F.Level := GameParams.Level;
        F.Talisman := GameParams.Level.Talismans[i];
        F.ShowPopup;
      finally
        F.Free;
      end;
      Break;
    end;
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

procedure TGamePreviewScreen.MakeTalismanOptions;
var
  NewRegion: TClickableRegion;
  Temp: TBitmap32;
  Tal: TTalisman;
  i: Integer;
  LoadPath, aImage: String;
  SrcRect: TRect;
  TalCount: Integer;
  TotalTalWidth: Integer;
  TalPoint: TPoint;
  KeepTalismans, HasCollectibles, AllCollectiblesGathered: Boolean;

  procedure DrawButtons(IsCollectible: Boolean = False);
  begin
    Temp.Clear(0);
    fTalismanImage.DrawTo(Temp, 0, 0, SrcRect);

    if IsCollectible then
      NewRegion := MakeClickableImageAuto(TalPoint, Temp.BoundsRect, HandleCollectibleClick, Temp)
    else
      NewRegion := MakeClickableImageAuto(TalPoint, Temp.BoundsRect, HandleTalismanClick, Temp);

    fTalRects.Add(NewRegion.ClickArea);
    TalPoint.X := TalPoint.X + Temp.Width + TALISMAN_PADDING;
  end;
const
  TALISMANS_Y_POSITION = 408;
begin
  if (GameParams.Level.Talismans.Count = 0) and
     (GameParams.Level.Info.CollectibleCount = 0) then
        Exit;

  KeepTalismans := False;
  HasCollectibles := GameParams.Level.Info.CollectibleCount > 0;

  if fTalismanImage = nil then
    fTalismanImage := TBitmap32.Create;

  Temp := TBitmap32.Create;
  try
    aImage := 'talismans.png';

    // Try styles folder first
    LoadPath := AppPath + SFStyles + GameParams.Level.Info.GraphicSetName + SFIcons + aImage;

    if not FileExists(LoadPath) then
    begin
      // Then level pack folder
      LoadPath := GameParams.CurrentLevel.Group.FindFile(aImage);
      // Then default
      if LoadPath = '' then
        LoadPath := AppPath + SFGraphicsMenu + aImage
      else
        KeepTalismans := true;
    end;

    TPngInterface.LoadPngFile(LoadPath, fTalismanImage);
    fTalismanImage.DrawMode := dmOpaque;

    Temp.SetSize(fTalismanImage.Width div 2, fTalismanImage.Height div 4);

    TalCount := GameParams.Level.Talismans.Count;
    if HasCollectibles then TalCount := TalCount + 1;

    TotalTalWidth := (TalCount * (Temp.Width + TALISMAN_PADDING)) - TALISMAN_PADDING;
    TalPoint := Point((ScreenImg.Bitmap.Width - TotalTalWidth + Temp.Width) div 2, TALISMANS_Y_POSITION);

    for i := 0 to GameParams.Level.Talismans.Count-1 do
    begin
      Tal := GameParams.Level.Talismans[i];
      case Tal.Color of
        tcBronze: SrcRect := SizedRect(0, 0, Temp.Width, Temp.Height);
        tcSilver: SrcRect := SizedRect(0, Temp.Height, Temp.Width, Temp.Height);
        tcGold: SrcRect := SizedRect(0, Temp.Height * 2, Temp.Width, Temp.Height);
      end;

      if GameParams.CurrentLevel.TalismanStatus[Tal.ID] then
        OffsetRect(SrcRect, Temp.Width, 0);

      DrawButtons;
    end;

    if (GameParams.Level.Info.CollectibleCount > 0) then
    begin
      AllCollectiblesGathered := (GameParams.CurrentLevel.UserRecords.CollectiblesGathered.Value
                               = GameParams.Level.Info.CollectibleCount);

      SrcRect := SizedRect(0, Temp.Height * 3, Temp.Width, Temp.Height);

      if AllCollectiblesGathered then
        OffsetRect(SrcRect, Temp.Width, 0);

      DrawButtons(True);
    end;
  finally
    Temp.Free;

    if not KeepTalismans then
    begin
      fTalismanImage.Free;
      fTalismanImage := nil;
    end;
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

