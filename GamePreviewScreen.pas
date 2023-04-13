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
  LemGadgetsMeta, LemGadgets,
  LemTalisman,
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseMenuScreen)
    private
      fTalRects: TList<TRect>;
      fTalismanImage: TBitmap32;

      function GetScreenText: string;

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
  CustomPopup,
  FBaseDosForm,
  FLevelInfo,
  FStyleManager;

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
const
  TEXT_Y_POSITION = 170;
begin
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
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, TEXT_Y_POSITION);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_TWO_ROWS_HIGH_Y), SOptionContinue, BeginPlay);
    NewRegion.ShortcutKeys.Add(VK_RETURN);
    NewRegion.ShortcutKeys.Add(VK_SPACE);

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
    NewRegion.ShortcutKeys.Add(VK_F2);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(MM_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    if GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FS_FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    if not GameParams.ShowMinimap and not GameParams.FullScreen then
      NewRegion := MakeClickableText(Point(FOOTER_THREE_OPTIONS_X_LEFT, FOOTER_OPTIONS_TWO_ROWS_LOW_Y), SOptionLoadReplay, TryLoadReplay);
    NewRegion.AddKeysFromFunction(lka_LoadReplay);

    MakeHiddenOption(VK_F3, ShowConfigMenu);
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

function TGamePreviewScreen.GetScreenText: string;
begin
  Assert(GameParams <> nil);

  with GameParams.Level.Info do
  begin
    Result := Title + #13#12;

    if GameParams.CurrentLevel.Group.Parent <> nil then
    begin
      Result := Result + GameParams.CurrentLevel.Group.Name;
      if GameParams.CurrentLevel.Group.IsOrdered then
        Result := Result + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1);
    end;
    Result := Result + #13#13#13;

    if (NeutralCount > 0) or (ZombieCount > 0) then
    begin
      Result := Result + IntToStr(LemmingsCount - ZombieCount - NeutralCount) + ' Lemmings  + ';

      if NeutralCount > 0 then
        Result := Result + IntToStr(NeutralCount) + ' Neutrals';

      if (NeutralCount > 0) and (ZombieCount > 0) then
        Result := Result + ', ';

      if ZombieCount > 0 then
        Result := Result + IntToStr(ZombieCount) + ' Zombies';
    end else
      Result := Result + IntToStr(LemmingsCount) + SPreviewLemmings;

    Result := Result + #13#12;

    Result := Result + IntToStr(RescueCount) + SPreviewSave + #13#12;

    if HasTimeLimit then
      Result := Result + SPreviewTimeLimit + IntToStr(TimeLimit div 60) + ':' + LeadZeroStr(TimeLimit mod 60, 2) + #13 + #12;

    if Author <> '' then
      Result := Result + SPreviewAuthor + Author;
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
  TALISMANS_Y_POSITION = 400;
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
  GlobalGame.ReplayManager.Clear(true); // this code clears the current-replay-in-memory
                                        // when the level loads. A controversial decision to
                                        // have this happen Globally, it might need to be
                                        // optional
end;

end.

