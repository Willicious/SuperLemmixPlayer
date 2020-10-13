unit GamePreviewScreen;

interface

uses
  System.Types,
  StrUtils,
  LemTypes,
  PngInterface,
  LemNeoLevelPack,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs,
  LemCore, LemStrings, LemRendering, LemLevel,
  LemGadgetsMeta, LemGadgets,
  LemTalisman,
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseMenuScreen)
    private
      function GetScreenText: string;

      procedure NextLevel;
      procedure PreviousLevel;
      procedure NextRank;
      procedure PreviousRank;

      procedure BeginPlay;
      procedure ExitToMenu;

      procedure SaveLevelImage;
      procedure TryLoadReplay;
    protected
      procedure DoAfterConfig; override;
    public
      procedure BuildScreen; override;
      procedure PrepareGameParams; override;
      procedure CloseScreen(NextScreen: TGameScreenType); override;
  end;

implementation

uses
  CustomPopup,
  FBaseDosForm,
  FStyleManager;

{ TGamePreviewScreen }

procedure TGamePreviewScreen.CloseScreen(NextScreen: TGameScreenType);
var
  F: TFManageStyles;
begin
  if NextScreen = gstPlay then
  begin
    if GameParams.Level.HasAnyFallbacks then
    begin
      if GameParams.EnableOnline then
      begin
        case RunCustomPopup(self, 'Missing styles',
          'Some pieces used by this level are missing. Do you want to attempt to download missing styles?',
          'Yes|No|Open Style Manager') of
          1:
            begin
              DownloadMissingStyles;
              inherited CloseScreen(gstPreview);
            end;
          3:
            begin
              F := TFManageStyles.Create(self);
              try
                F.ShowModal;
              finally
                F.Free;
                inherited CloseScreen(gstPreview);
              end;
            end;
        end;
      end else
        ShowMessage('Some pieces used by this level are missing. You will not be able to play this level. ' +
                    'Download the missing styles manually, or enable online features in NeoLemmix config to try to auto-download them.');
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

procedure TGamePreviewScreen.BeginPlay;
begin
  CloseScreen(gstPlay);
end;

procedure TGamePreviewScreen.BuildScreen;
var
  W: TBitmap32;
  DstRect: TRect;
  Lw, Lh : Integer;
  LevelScale: Double;
  NewRegion: TClickableRegion;
begin
  Assert(GameParams <> nil);

  ScreenImg.BeginUpdate;
  try
    // prepare the renderer, this is a little bit shaky (wrong place)
    try
      with GameParams do
      begin
        Lw := Level.Info.Width;
        Lh := Level.Info.Height;
        Renderer.PrepareGameRendering(Level);
      end;
    except
      on E : Exception do
      begin
        ShowMessage(E.Message);
        CloseScreen(gstMenu);
        Exit;
      end;
    end;

    W := TBitmap32.Create;
    try
      ScreenImg.Bitmap.FillRect(0, 0, 864, 160, $FF000000);

      // draw level preview
      W.SetSize(Lw, Lh);
      W.Clear(0);

      GameParams.Renderer.RenderWorld(W, not GameParams.NoBackgrounds);
      TLinearResampler.Create(W);
      W.DrawMode := dmBlend;
      W.CombineMode := cmMerge;

      // We have a 864x160 area in which to draw the level preview
      LevelScale := 864 / lw;
      if LevelScale > 160 / lh then LevelScale := 160 / lh;

      DstRect := Rect(0, 0, Trunc(lw * LevelScale), Trunc(lh * LevelScale));
      OffsetRect(DstRect, 432 - (DstRect.Right div 2), 80 - (DstRect.Bottom div 2));

      W.DrawTo(ScreenImg.Bitmap, DstRect, W.BoundsRect);
      // draw text
      MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 164);

      NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_LEFT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionContinue, BeginPlay);
      NewRegion.ShortcutKeys.Add(VK_RETURN);
      NewRegion.ShortcutKeys.Add(VK_SPACE);

      NewRegion := MakeClickableText(Point(FOOTER_TWO_OPTIONS_X_RIGHT, FOOTER_OPTIONS_ONE_ROW_Y), SOptionToMenu, ExitToMenu);
      NewRegion.ShortcutKeys.Add(VK_ESCAPE);

      MakeHiddenOption(VK_F2, DoLevelSelect);
      MakeHiddenOption(VK_F3, ShowConfigMenu);
      MakeHiddenOption(VK_LEFT, PreviousLevel);
      MakeHiddenOption(VK_RIGHT, NextLevel);
      MakeHiddenOption(VK_DOWN, PreviousRank);
      MakeHiddenOption(VK_UP, NextRank);
      MakeHiddenOption(lka_LoadReplay, TryLoadReplay);
      MakeHiddenOption(lka_SaveImage, SaveLevelImage);

      DrawAllClickables;
    finally
      W.Free;
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

procedure TGamePreviewScreen.ExitToMenu;
begin
  if GameParams.TestModeLevel <> nil then
    CloseScreen(gstExit)
  else
    CloseScreen(gstMenu);
end;

function TGamePreviewScreen.GetScreenText: string;
  function GetTalismanText: String;
  var
    Talisman: TTalisman;
    Lines: array[0..2] of String;
    MaxLen: Integer;
    i: Integer;

    procedure MakeReqString(CurLine: Integer);
    var
      S: String;
      i: Integer;
    begin
      S := Trim(Talisman.RequirementText);
      while (S <> '') and (CurLine < Length(Lines)) do
      begin
        if Length(S) > 48 then
        begin
          for i := 49 downto 1 do
            if S[i] = ' ' then
              Break;

          if i <= 1 then i := 49;
        end else
          i := Length(S) + 1;

        Lines[CurLine] := Lines[CurLine] + Trim(LeftStr(S, i-1));
        S := Trim(RightStr(S, Length(S) - i + 1));
        Inc(CurLine);
      end;
    end;
  begin
    Talisman := nil;
    with GameParams.CurrentLevel do
      for i := 0 to Talismans.Count-1 do
        if not TalismanStatus[Talismans[i].ID] then
        begin
          Talisman := Talismans[i];
          Break;
        end;

    if Talisman = nil then
    begin
      Result := #13#13;
      Exit;
    end;

    // #127 = bronze non-unlocked
    case Talisman.Color of
      tcBronze: Lines[0] := #26 + '   ';
      tcSilver: Lines[0] := #28 + '   ';
      tcGold: Lines[0] := #30 + '   ';
    end;
    Lines[1] := '    ';
    Lines[2] := '    ';

    if Trim(Talisman.Title).Length > 0 then
    begin
      Lines[0] := Lines[0] + LeftStr(Talisman.Title, 36);
      MakeReqString(1);
    end
    else
      MakeReqString(0);

    MaxLen := 0;
    for i := 0 to 2 do
    begin
      Lines[i] := TrimRight(Lines[i]);
      if Length(Lines[i]) > MaxLen then MaxLen := Length(Lines[i]);
    end;
    for i := 0 to 2 do
      if Length(Lines[i]) < MaxLen then
        Lines[i] := Lines[i] + StringOfChar(' ', MaxLen - Length(Lines[i]));

    Result := Lines[0] + #13 +
              Lines[1] + #13 +
              Lines[2];
  end;
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

    Result := Result + IntToStr(LemmingsCount - ZombieCount) + SPreviewLemmings + #13#12;
    Result := Result + IntToStr(RescueCount) + SPreviewSave + #13#12;

    if HasTimeLimit then
      Result := Result + SPreviewTimeLimit + IntToStr(TimeLimit div 60) + ':' + LeadZeroStr(TimeLimit mod 60, 2) + #13 + #12;

    if Author <> '' then
      Result := Result + SPreviewAuthor + Author + #13;

    Result := Result + #13 + GetTalismanText;
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
end;

end.

