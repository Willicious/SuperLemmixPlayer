unit GamePreviewScreen;

interface

uses
  System.Types,
  StrUtils,
  PngInterface,
  LemNeoLevelPack,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs,
  LemCore, LemStrings, LemDosStructures, LemRendering, LemLevel,
  LemMetaObject, LemObjects,
  LemTalisman,
  GameControl, GameBaseScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseScreen)
  private
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure VGASpecPrep;
    procedure SaveLevelImage;
    function GetScreenText: string;
    procedure NextLevel;
    procedure PreviousLevel;
    procedure NextRank;
    procedure PreviousRank;
  protected
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildScreen; override;
    procedure PrepareGameParams; override;
    procedure CloseScreen(NextScreen: TGameScreenType); override;
  end;

implementation

uses FBaseDosForm;

{ TGamePreviewScreen }

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

procedure TGamePreviewScreen.BuildScreen;
var
  Mainpal: TArrayOfColor32;
  Temp, W: TBitmap32;
  DstRect: TRect;
  Lw, Lh : Integer;
  LevelScale: Double;
begin
  Assert(GameParams <> nil);

  ScreenImg.BeginUpdate;
  try
    MainPal := GetDosMainMenuPaletteColors32;
    InitializeImageSizeAndPosition(640, 400);
    ExtractBackGround;
    ExtractPurpleFont;

    // prepare the renderer, this is a little bit shaky (wrong place)
    with GameParams do
    begin
      Lw := Level.Info.Width;
      Lh := Level.Info.Height;
      Renderer.PrepareGameRendering(Level);
    end;

    Temp := TBitmap32.Create;
    W := TBitmap32.Create;
    try
      Temp.SetSize(640, 400);
      Temp.Clear(0);
      // draw level preview
      W.SetSize(Lw, Lh);
      W.Clear(0);

      GameParams.Renderer.RenderWorld(W, not GameParams.NoBackgrounds);
      TLinearResampler.Create(W);
      W.DrawMode := dmBlend;
      W.CombineMode := cmMerge;

      // We have a 640x128 area in which to draw the level preview
      LevelScale := 640 / lw;
      if LevelScale > 128 / lh then LevelScale := 128 / lh;

      DstRect := Rect(0, 0, Trunc(lw * LevelScale), Trunc(lh * LevelScale));
      OffsetRect(DstRect, 320 - (DstRect.Right div 2), 64 - (DstRect.Bottom div 2));

      W.DrawTo(Temp, DstRect, W.BoundsRect);
      // draw background
      TileBackgroundBitmap(0, 128, Temp);
      // draw text
      DrawPurpleTextCentered(Temp, GetScreenText, 130);
      ScreenImg.Bitmap.Assign(Temp);

      if GameParams.LinearResampleMenu then
        TLinearResampler.Create(ScreenImg.Bitmap);
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
    SaveName := ExtractFilePath(ParamStr(0)) + 'Dump\' + ChangeFileExt(ExtractFileName(GameFile), '') + '\';
    if not ForceDirectories(SaveName) then Exit;
    SaveName := SaveName + LeadZeroStr(GameParams.CurrentLevel.Group.ParentGroupIndex + 1, 2) + LeadZeroStr(GameParams.CurrentLevel.GroupIndex + 1, 2) + '.png'
  end else begin
    Dlg := TSaveDialog.Create(self);
    Dlg.Filter := 'PNG Image (*.png)|*.png';
    Dlg.FilterIndex := 1;
    Dlg.DefaultExt := '.png';
    if Dlg.Execute then
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
                 if GameParams.TestModeLevel <> nil then
                   CloseScreen(gstExit)
                 else
                   CloseScreen(gstMenu);
               end;
    VK_RETURN: begin VGASpecPrep; CloseScreen(gstPlay); end;
    VK_LEFT: PreviousLevel;
    VK_RIGHT: NextLevel;
    VK_DOWN: PreviousRank;
    VK_UP: NextRank;
  end;
end;

procedure TGamePreviewScreen.Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
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
  ExtraNewLines: Integer;

  function GetTalismanText: String;
  var
    Talisman: TTalisman;
    Lines: array[0..2] of String;
    MaxLen: Integer;
    i: Integer;

    procedure MakeReqString;
    var
      CurLine: Integer;
      S: String;
      i: Integer;
    begin
      S := Trim(Talisman.RequirementText);
      CurLine := 1;
      while (S <> '') and (CurLine < Length(Lines)) do
      begin
        if Length(S) > 36 then
        begin
          for i := 37 downto 1 do
            if S[i] = ' ' then
              Break;

          if i <= 1 then i := 37;
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

    Lines[0] := Lines[0] + LeftStr(Talisman.Title, 36);

    MakeReqString;

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
  ExtraNewLines := 1;

  with GameParams.Level.Info do
  begin
    Result := Title + #13;

    if GameParams.CurrentLevel.Group.Parent <> nil then
    begin
      Result := Result + GameParams.CurrentLevel.Group.Name;
      if GameParams.CurrentLevel.Group.IsOrdered then
        Result := Result + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1);
    end;
    Result := Result + #13#13#13#13;

    Result := Result + IntToStr(LemmingsCount - ZombieCount) + SPreviewLemmings + #13;
    Result := Result + IntToStr(RescueCount) + SPreviewSave + #13;

    if GameParams.SpawnInterval then
      Result := Result + SPreviewSpawnInterval + IntToStr(SpawnInterval)
    else
      Result := Result + SPreviewReleaseRate + IntToStr(SpawnIntervalToReleaseRate(SpawnInterval));
    if SpawnIntervalLocked then
      Result := Result + SPreviewRRLocked;
    Result := Result + #13;

    if HasTimeLimit then
      Result := Result + SPreviewTimeLimit + IntToStr(TimeLimit div 60) + ':' + LeadZeroStr(TimeLimit mod 60, 2) + #13
    else
      Inc(ExtraNewLines);

    if Author <> '' then
      Result := Result + SPreviewAuthor + Author + #13
    else
      Inc(ExtraNewLines);

    Result := Result + #13 + GetTalismanText + #13;

    Result := Result + StringOfChar(#13, ExtraNewLines);

    Result := Result + SPressMouseToContinue;

    Log(Result);
  end;
end;

procedure TGamePreviewScreen.PrepareGameParams;
begin
  inherited;

  if not GameParams.OneLevelMode then
  begin
    GameParams.LoadCurrentLevel;
  end else begin
    (*TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := GameParams.LevelString;
    Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);*)
  end;

end;

end.

