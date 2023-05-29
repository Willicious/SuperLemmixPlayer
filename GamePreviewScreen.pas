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
  GR32, GR32_Layers, GR32_Resamplers,
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

      function GetTextLineInfoArray: TextLineArray;

      procedure NextLevel;
      procedure PreviousLevel;
      procedure NextRank;
      procedure PreviousRank;

      procedure BeginPlay;
      procedure ExitToMenu;

      procedure SaveLevelImage;
      procedure TryLoadReplay;

      procedure MakeTalismanOptions;
      procedure HandleTalismanClick;
    protected
      procedure DoAfterConfig; override;
      function GetBackgroundSuffix: String; override;

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
  CustomPopup, FBaseDosForm, FLevelInfo, FStyleManager;

const
  TALISMAN_PADDING = 8;

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
  GameParams.Renderer.RenderWorld(nil, not GameParams.NoBackgrounds); // some necessary prep work is done in here
end;

procedure TGamePreviewScreen.BeginPlay;
begin
  CloseScreen(gstPlay);
end;

procedure TGamePreviewScreen.OnMouseClick(aPoint: TPoint;
  aButton: TMouseButton);
begin
  inherited;
  case aButton of
    mbLeft: BeginPlay;
    mbRight: ExitToMenu;
    mbMiddle: begin GameParams.ShownText := false; BeginPlay; end;
  end;
end;

procedure TGamePreviewScreen.BuildScreen;
var
  W: TBitmap32;
  DstRect: TRect;
  Lw, Lh : Integer;
  LevelScale: Double;
  NewRegion: TClickableRegion;
  Lines: TextLineArray;
const
  TEXT_Y_POSITION = 170;
begin
  fClickableRegions.Clear;
  Assert(GameParams <> nil);

  W := TBitmap32.Create;
  ScreenImg.BeginUpdate;
  try
    ////puts a black border either side of the level preview - see if we can do without it
    //ScreenImg.Bitmap.FillRect(0, 0, 864, 160, $FF000000);   //bookmark

    Lw := GameParams.Level.Info.Width;
    Lh := GameParams.Level.Info.Height;

    // draw level preview
    W.SetSize(Lw, Lh);
    W.Clear(0);

    GameParams.Renderer.RenderWorld(W, not GameParams.NoBackgrounds);
    TLinearResampler.Create(W);
    W.DrawMode := dmBlend;
    W.CombineMode := cmMerge;

    //Draw the level preview
    if GameParams.ShowMinimap and not GameParams.FullScreen then
      LevelScale := MM_INTERNAL_SCREEN_WIDTH / lw;
    if GameParams.FullScreen then
      LevelScale := FS_INTERNAL_SCREEN_WIDTH / lw;
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      LevelScale := INTERNAL_SCREEN_WIDTH / lw;

    if LevelScale > 160 / lh then LevelScale := 160 / lh;
    DstRect := Rect(0, 0, Trunc(lw * LevelScale), Trunc(lh * LevelScale));

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      OffsetRect(DstRect, (MM_INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2));
    if GameParams.FullScreen then
      OffsetRect(DstRect, (FS_INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2));
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      OffsetRect(DstRect, (INTERNAL_SCREEN_WIDTH div 2) - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2));

    W.DrawTo(ScreenImg.Bitmap, DstRect, W.BoundsRect);

    // draw text
    Lines := GetTextLineInfoArray;
        MenuFont.DrawTextLines(Lines, ScreenImg.Bitmap, TEXT_Y_POSITION);

    //// I don't think we need to show "Continue" any more
    //if GameParams.ShowMinimap and not GameParams.FullScreen then
      //NewRegion := MakeClickableText(Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    //if GameParams.FullScreen then
      //NewRegion := MakeClickableText(Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    //if not GameParams.ShowMinimap and not GameParams.FullScreen then
      //NewRegion := MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    //NewRegion.ShortcutKeys.Add(VK_RETURN);
    //NewRegion.ShortcutKeys.Add(VK_SPACE);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_RIGHT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionToMenu, ExitToMenu);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_MID, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLevelSelect, DoLevelSelect);
    NewRegion.ShortcutKeys.Add(VK_F3);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    NewRegion.AddKeysFromFunction(lka_LoadReplay);

    MakeHiddenOption(VK_SPACE, BeginPlay);
    MakeHiddenOption(VK_RETURN, BeginPlay);
    MakeHiddenOption(VK_F2, ShowConfigMenu);
    MakeHiddenOption(VK_LEFT, PreviousLevel);
    MakeHiddenOption(VK_RIGHT, NextLevel);
    MakeHiddenOption(VK_DOWN, PreviousRank);
    MakeHiddenOption(VK_UP, NextRank);
    MakeHiddenOption(lka_SaveImage, SaveLevelImage);

    MakeTalismanOptions;

    DrawAllClickables;
  finally
    W.Free;
    ScreenImg.EndUpdate;
  end;
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
  // Pretty much just because LoadReplay is a function, not a procedure, so this
  // needs to be here as a wraparound.
  LoadReplay;
end;

procedure TGamePreviewScreen.DoAfterConfig;
begin
  inherited;
  CloseScreen(gstPreview);
end;

function TGamePreviewScreen.GetBackgroundSuffix: String;
begin
  Result := 'preview';
end;

procedure TGamePreviewScreen.ExitToMenu;
begin
  if GameParams.TestModeLevel <> nil then
    CloseScreen(gstExit)
  else
    CloseScreen(gstMenu);
end;

function TGamePreviewScreen.GetTextLineInfoArray: TextLineArray;
const
  TITLE_SHIFT = 0.600;
  GROUP_SHIFT = 0.600;
  NUM_LEMS_SHIFT = 0.250;
  RESCUE_LEMS_SHIFT = 0;
  RELEASE_RATE_SHIFT = 0.800;
  TIME_LIMIT_SHIFT = 0.150;
  AUTHOR_SHIFT = 0.500;

  LINE_Y_SPACING = 28;
var
  HueShift: TColorDiff;
  Entry: TNeoLevelEntry;
  Level: TLevel;
begin
  Entry := GameParams.CurrentLevel;
  Level := GameParams.Level;
  FillChar(HueShift, SizeOf(TColorDiff), 0);

  SetLength(Result, 7);

  HueShift.HShift := TITLE_SHIFT;
  Result[0].Line := Entry.Title;
  Result[0].ColorShift := HueShift;
  Result[0].yPos := 168;//hotbookmark

  HueShift.HShift := GROUP_SHIFT;
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

  HueShift.HShift := NUM_LEMS_SHIFT;
  Result[2].yPos := Result[1].yPos + LINE_Y_SPACING;
  if (Level.Info.NeutralCount > 0) or (Level.Info.ZombieCount > 0) then
  begin
    if Level.Info.LemmingsCount = 1 then
    Result[2].Line := Result[2].Line + IntToStr(Level.Info.LemmingsCount
                                     - Level.Info.ZombieCount - Level.Info.NeutralCount)
                                     + ' ' + GameParams.Renderer.Theme.LemNamesSingular
    else if Level.Info.LemmingsCount > 1 then
    Result[2].Line := Result[2].Line + IntToStr(Level.Info.LemmingsCount
                                     - Level.Info.ZombieCount - Level.Info.NeutralCount)
                                     + ' ' + GameParams.Renderer.Theme.LemNamesPlural;

    if (Level.Info.NeutralCount = 1) then
    Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.NeutralCount) + ' Neutral'
    else if (Level.Info.NeutralCount > 1) then
    Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.NeutralCount) + ' Neutrals';

    if (Level.Info.ZombieCount = 1) then
    Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.ZombieCount) + ' Zombie'
    else if (Level.Info.ZombieCount > 1) then
    Result[2].Line := Result[2].Line + ', ' + IntToStr(Level.Info.ZombieCount) + ' Zombies';
  end else if Level.Info.LemmingsCount = 1 then
  Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + GameParams.Renderer.Theme.LemNamesSingular
  else
  Result[2].Line := IntToStr(Level.Info.LemmingsCount) + ' ' + GameParams.Renderer.Theme.LemNamesPlural;
  Result[2].ColorShift := HueShift;

  HueShift.HShift := RESCUE_LEMS_SHIFT;
  Result[3].yPos := Result[2].yPos + LINE_Y_SPACING;
  Result[3].Line := IntToStr(Level.Info.RescueCount) + SPreviewSave;
  Result[3].ColorShift := HueShift;

  HueShift.HShift := RELEASE_RATE_SHIFT;
  Result[4].yPos := Result[3].yPos + LINE_Y_SPACING;
  if Level.Info.SpawnIntervalLocked then
  begin
    Result[4].Line := SPreviewReleaseRate + IntToStr(103 - Level.Info.SpawnInterval) + SPreviewRRLocked;
  end else
  Result[4].Line := SPreviewReleaseRate + IntToStr(103 - Level.Info.SpawnInterval);
  Result[4].ColorShift := HueShift;

  HueShift.HShift := TIME_LIMIT_SHIFT;
  Result[5].yPos := Result[4].yPos + LINE_Y_SPACING;
  if Level.Info.HasTimeLimit then
  begin
    Result[5].Line := SPreviewTimeLimit + IntToStr(Level.Info.TimeLimit div 60) + ':'
                    + LeadZeroStr(Level.Info.TimeLimit mod 60, 2);
  end else
  Result[5].Line := 'Infinite Time';
  Result[5].ColorShift := HueShift;

  HueShift.HShift := AUTHOR_SHIFT;
  Result[6].yPos := Result[5].yPos + LINE_Y_SPACING;
  if Level.Info.Author <> '' then
  begin
    Result[6].Line := SPreviewAuthor + Level.Info.Author;
  end else
  Result[6].Line := SPreviewAuthor + ' Anonymous';
  Result[6].ColorShift := HueShift;
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

procedure TGamePreviewScreen.MakeTalismanOptions;
var
  NewRegion: TClickableRegion;
  Temp: TBitmap32;
  Tal: TTalisman;
  i: Integer;

  LoadPath: String;
  SrcRect: TRect;

  TotalTalWidth: Integer;
  TalPoint: TPoint;

  KeepTalismans: Boolean;
const
  TALISMANS_Y_POSITION = 408;
begin
  if GameParams.Level.Talismans.Count = 0 then
    Exit;

  KeepTalismans := false;

  if fTalismanImage = nil then
    fTalismanImage := TBitmap32.Create;

  Temp := TBitmap32.Create;
  try
    LoadPath := GameParams.CurrentLevel.Group.FindFile('talismans.png');
    if LoadPath = '' then
      LoadPath := AppPath + SFGraphicsMenu + 'talismans.png'
    else
      KeepTalismans := true;

    TPngInterface.LoadPngFile(LoadPath, fTalismanImage);
    fTalismanImage.DrawMode := dmOpaque;

    Temp.SetSize(fTalismanImage.Width div 2, fTalismanImage.Height div 3);

    TotalTalWidth := (GameParams.Level.Talismans.Count * (Temp.Width + TALISMAN_PADDING)) - TALISMAN_PADDING;
    TalPoint := Point(
      (ScreenImg.Bitmap.Width - TotalTalWidth + Temp.Width) div 2,
      TALISMANS_Y_POSITION
      );

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

      Temp.Clear(0);
      fTalismanImage.DrawTo(Temp, 0, 0, SrcRect);

      NewRegion := MakeClickableImageAuto(TalPoint, Temp.BoundsRect, HandleTalismanClick, Temp);
      fTalRects.Add(NewRegion.ClickArea);

      TalPoint.X := TalPoint.X + Temp.Width + TALISMAN_PADDING;
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
      Raise; // yet again, to be caught on TBaseDosForm
    end;
  end;
  if GameParams.ClassicMode or not GameParams.ReplayAfterRestart then
    GlobalGame.ReplayManager.Clear(true);
    // this clears the current-replay-in-memory when the level loads
end;

end.

