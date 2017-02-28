unit GamePreviewScreen;

interface

uses
  PngInterface,
  LemmixHotkeys, SharedGlobals,
  Windows, Classes, Controls, Graphics, SysUtils,
  GR32, GR32_Layers, GR32_Resamplers,
  UMisc, Dialogs,
  LemCore, LemStrings, LemDosStructures, LemRendering, LemLevelSystem, LemLevel,
  LemDosStyle, LemMetaObject, LemObjects,
  GameControl, GameBaseScreen, GameWindow;

type
  TGamePreviewScreen = class(TGameBaseScreen)
  private
    fCanDump: Boolean;
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
    procedure BuildScreenInvis;
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
var
  FindInfo: TDosGamePlayInfoRec;
begin
  FindInfo := GameParams.Info;
  GameParams.Style.LevelSystem.FindNextUnsolvedLevel(FindInfo);
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
  GameParams.Style.LevelSystem.FindPreviousUnsolvedLevel(FindInfo);
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
  GameParams.Style.LevelSystem.FindFirstUnsolvedLevel(FindInfo);
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
  GameParams.Style.LevelSystem.FindFirstUnsolvedLevel(FindInfo);
  GameParams.ShownText := false;
  GameParams.WhichLevel := wlLastUnlocked;
  GameParams.Info := FindInfo;
  CloseScreen(gstPreview);
end;

procedure TGamePreviewScreen.BuildScreen;
var
  Inf: TRenderInfoRec;
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
      Inf.Level:=Level;
      Lw := Level.Info.Width;
      Lh := Level.Info.Height;
      Renderer.PrepareGameRendering(Inf, (GameParams.SysDat.Options2 and 2 <> 0));
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
      DrawPurpleText(Temp, GetScreenText, 0, 130);
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
    SaveName := SaveName + LeadZeroStr(GameParams.Info.dSection + 1, 2) + LeadZeroStr(GameParams.Info.dLevel + 1, 2) + '.png'
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

procedure TGamePreviewScreen.BuildScreenInvis;
var
  Inf: TRenderInfoRec;
  TempBmp: TBitmap32;
begin
  Assert(GameParams <> nil);
  TempBmp := TBitmap32.Create;

  try
    // prepare the renderer, this is a little bit shaky (wrong place)
    with GameParams do
    begin
      Inf.Level := Level;
      Renderer.PrepareGameRendering(Inf, (SysDat.Options2 and 2 <> 0));
    end;
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
    VK_F2: CloseScreen(gstLevelSelect);
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
  Perc, TL: string;
  RR: String;
  i: Integer;
begin
  Assert(GameParams <> nil);

  Perc := IntToStr(GameParams.Level.Info.RescueCount) + ' Lemming';
  if GameParams.Level.Info.RescueCount <> 1 then Perc := Perc + 's';

  if GameParams.Level.Info.HasTimeLimit then
    TL := IntToStr(GameParams.Level.Info.TimeLimit div 60) + ':' + LeadZeroStr(GameParams.Level.Info.TimeLimit mod 60,2)
  else
    TL := '(Infinite)';

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
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieCount,
                 Perc,
                 RR,
                 TL,
                 GameParams.Info.dSectionName
                ])
  else
    Result := Format(SPreviewStringAuth,
                [GameParams.Info.dLevel + 1, // humans read 1-based
                 Trim(GameParams.Level.Info.Title),
                 GameParams.Level.Info.LemmingsCount - GameParams.Level.Info.ZombieCount,
                 Perc,
                 RR,
                 TL,
                 GameParams.Info.dSectionName,
                 GameParams.Level.Info.Author
                ]);

  if GameParams.ForceSkillset <> 0 then
  begin
    GameParams.Level.Info.Skillset := [];
    for i := 0 to 15 do
    begin
      if GameParams.ForceSkillset and (1 shl (15 - i)) <> 0 then
        GameParams.Level.Info.Skillset := GameParams.Level.Info.Skillset + [TSkillPanelButton(i)];
    end;
  end;
end;

procedure TGamePreviewScreen.PrepareGameParams;
begin
  inherited;

  fCanDump := true;

  with GameParams, Info do
  begin

    case WhichLevel of
      wlFirst: Style.LevelSystem.FindFirstLevel(Info);
      wlFirstSection: Style.LevelSystem.FindFirstLevel(Info);
      wlLevelCode: Style.LevelSystem.FindLevel(Info);
      wlNext: Style.LevelSystem.FindNextLevel(Info);
      wlSame: Style.LevelSystem.FindLevel(Info);
      wlNextUnlocked: Style.LevelSystem.FindNextUnsolvedLevel(Info);
      wlPreviousUnlocked: Style.LevelSystem.FindPreviousUnsolvedLevel(Info);
      wlLastUnlocked: Style.LevelSystem.FindFirstUnsolvedLevel(Info);
    end;

    if not GameParams.OneLevelMode then
    begin
      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := '';
      try
        Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
      except
        fCanDump := false;
        Exit;
      end;
    end else begin
      TBaseDosLevelSystem(Style.LevelSystem).fOneLvlString := GameParams.LevelString;
      Style.LevelSystem.LoadSingleLevel(dPack, dSection, dLevel, Level);
    end;

    WhichLevel := wlSame;
  end;
end;

end.

