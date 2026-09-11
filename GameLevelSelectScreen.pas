unit GameLevelSelectScreen;

interface

uses
  StrUtils, Classes, SysUtils, Dialogs, Controls, ExtCtrls,
  Forms, Windows, ShellApi, Types, UMisc, Math, Graphics,
  GameBaseMenuScreen,
  GameControl,
  LemNeoLevelPack,
  LemNeoOnline,
  LemNeoParser,
  LemStrings,
  LemTypes,
  GR32, GR32_Resamplers,
  SharedGlobals;

type
  TGameLevelSelectScreen = class(TGameBaseMenuScreen)
    private
      procedure DrawLogoCropped(PanelX, PanelY: Integer);
      procedure DrawPanelText(const Text: String; PanelX, PanelY: Integer);
      procedure AddIcons(PanelX, PanelY: Integer);
      procedure MakePackPanels;

      procedure ShowSetupMenu;
      procedure BeginGame;
    protected
      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
      procedure OnKeyPress(var Key: Word); override;

      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;

      procedure AfterRedrawClickables; override;
      procedure DoAfterConfig; override;

      function GetWallpaperSuffix: String; override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

const
  PANEL_WIDTH = 320;
  PANEL_HEIGHT = 140;
  LOGO_HEIGHT = 70;

implementation

uses
  LemMenuFont, // For size const
  CustomPopup,
  FSuperLemmixSetup,
  GameSound,
  LemGame, // To clear replay
  LemVersion,
  PngInterface;

{ TGameMenuScreen }

constructor TGameLevelSelectScreen.Create(aOwner: TComponent);
begin
  inherited;

  GameParams.MainForm.Caption := 'SuperLemmix Level Pack Select';
end;

destructor TGameLevelSelectScreen.Destroy;
begin
  inherited;
end;

procedure TGameLevelSelectScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  inherited;

  BeginGame;
end;

procedure TGameLevelSelectScreen.OnKeyPress(var Key: Word);
begin
  inherited;

  case Key of
    VK_ESCAPE:
      CloseScreen(gstMenu);

    VK_SPACE, VK_RETURN, VK_F1:
      CloseScreen(gstPreview);

    VK_F2:
      ShowConfigMenu;

    VK_F3:
      DoLevelSelectModal;
  end;
end;

procedure TGameLevelSelectScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited;
end;

procedure TGameLevelSelectScreen.BuildScreen;
begin
  inherited;

  fClickableRegions.Clear;

  // Classic Mode
  DrawClassicModeButton;
  DrawAllClickables(true); // For the next step's sake // TODO - necessary here?
  DrawAllClickables;
  MakePackPanels;

  if (GameParams.CurrentLevel <> nil) then
  begin
    Exit; // TODO
  end;
end;

procedure TGameLevelSelectScreen.DrawLogoCropped(PanelX, PanelY: Integer);
var
  LogoBMP: TBitmap32;
  X, Y: Integer;
  MinX, MinY, MaxX, MaxY: Integer;
  DstRect, SrcRect: TRect;
  Scale: Double;
  Pixel: TColor32;
  LogoX, LogoY: Integer;
  LogoWidth, LogoHeight: Integer;
begin
  LogoBMP := TBitmap32.Create;
  try
    // Load logo
    GetGraphic('logo.png', LogoBMP);

    // Find the bounds of the visible part of the logo
    MinX := LogoBMP.Width;
    MinY := LogoBMP.Height;
    MaxX := -1;
    MaxY := -1;

    for Y := 0 to LogoBMP.Height - 1 do
      for X := 0 to LogoBMP.Width - 1 do
      begin
        Pixel := LogoBMP.Pixel[X, Y];

        if (Pixel shr 24) <> 0 then
        begin
          if X < MinX then MinX := X;
          if Y < MinY then MinY := Y;
          if X > MaxX then MaxX := X;
          if Y > MaxY then MaxY := Y;
        end;
      end;

    // Draw the cropped logo
    if MaxX >= MinX then
    begin
      SrcRect := Rect(MinX, MinY, MaxX + 1, MaxY + 1);

      // Scale proportionally to fit within the logo row
      Scale := Min(PANEL_WIDTH / (SrcRect.Right - SrcRect.Left), LOGO_HEIGHT /
        (SrcRect.Bottom - SrcRect.Top));

      LogoWidth := Round((SrcRect.Right - SrcRect.Left) * Scale);
      LogoHeight := Round((SrcRect.Bottom - SrcRect.Top) * Scale);

      // Centre the logo in the upper part of the panel
      LogoX := PanelX + (PANEL_WIDTH - LogoWidth) div 2;
      LogoY := PanelY + (LOGO_HEIGHT - LogoHeight) div 2 + 8;

      DstRect := Rect(LogoX, LogoY, LogoX + LogoWidth, LogoY + LogoHeight);

      LogoBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
    end;
  finally
    LogoBMP.Free;
  end;
end;

procedure TGameLevelSelectScreen.DrawPanelText(const Text: String; PanelX, PanelY: Integer);
var
  ProgressX, InfoX, Y: Integer;
begin
  ScreenImg.Bitmap.Font.Name := 'Tahoma';
  ScreenImg.Bitmap.Font.Size := 10;
  ScreenImg.Bitmap.Font.Quality := fqAntialiased;

  ProgressX := PanelX + 16;
  InfoX := ProgressX + 96;
  Y := PanelY + LOGO_HEIGHT + 24;

  ScreenImg.Bitmap.RenderText(ProgressX, Y, 'Progress: ', clCornflowerBlue32);
  ScreenImg.Bitmap.RenderText(InfoX, Y, Text, clLightGreen32);

  // TODO Remove this once the screen is fully implemented
  ScreenImg.Bitmap.RenderText(ProgressX - 40, Y + 100, 'This is a temporary screen', clWhite32);
  ScreenImg.Bitmap.RenderText(ProgressX - 80, Y + 140, 'Press F3 to open the Level Select dialog', clWhite32);
end;

procedure TGameLevelSelectScreen.AddIcons(PanelX, PanelY: Integer);
var
  TalBMP, ColBMP: TBitmap32;
  ImageX, ImageY, ImageSize, TalStart, ColStart: Integer;
  DstRect, SrcRect: TRect;
  Scale: Double;
  Pixel: TColor32;
  TalX, TalY, ColX, ColY: Integer;
  TalWidth, TalHeight, ColWidth, ColHeight: Integer;

  function AllTalismansCompleted: Boolean;
  var
    TalCount, TalsUnlocked: Integer;
  begin
    Result := True;

    TalCount := GameParams.CurrentLevel.Group.ParentBasePack.Talismans.Count;
    TalsUnlocked := GameParams.CurrentLevel.Group.ParentBasePack.TalismansUnlocked;

    if TalsUnlocked < TalCount then
      Result := False;
  end;

  function AllCollectiblesObtained: Boolean;
  var
    ColCount, ColsObtained: Integer;
  begin
    Result := True;

//    ColCount := GameParams.CurrentLevel.Group.ParentBasePack.Collectibles.Count;
//    ColsObtained := GameParams.CurrentLevel.Group.ParentBasePack.CollectiblesObtained;
//
//    if ColsObtained < ColCount then
//      Result := False;
  end;
begin
  TalBMP := TBitmap32.Create;
  try
    // Load talisman icons
    GetGraphic('talismans.png', TalBMP);
    ImageSize := 48;
    TalStart := 96;

    // Crop to the relevant part of the image
    ImageX := IfThen(AllTalismansCompleted, 48, 0);
    ImageY := TalStart;
    SrcRect := Rect(ImageX, ImageY, ImageX + ImageSize, ImageY + ImageSize);

//    // Scale proportionally to fit within the logo row
//    Scale := Min(PANEL_WIDTH / (SrcRect.Right - SrcRect.Left), LOGO_HEIGHT /
//      (SrcRect.Bottom - SrcRect.Top));

//    TalWidth := Round((SrcRect.Right - SrcRect.Left) * Scale);
//    TalHeight := Round((SrcRect.Bottom - SrcRect.Top) * Scale);

    TalWidth := ImageSize;
    TalHeight := ImageSize;

    // Add the talisman icon to the bottom right of the panel
    TalX := PanelX + PANEL_WIDTH - (TalWidth * 2);
    TalY := PanelY + LOGO_HEIGHT + 16;

    DstRect := Rect(TalX, TalY, TalX + TalWidth, TalY + TalHeight);

    TalBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
  finally
    TalBMP.Free;
  end;

  ColBMP := TBitmap32.Create;
    try
    // Load collectible icons
    GetGraphic('talismans.png', ColBMP);
    ImageSize := 48;
    ColStart := 144;

    // Crop to the relevant part of the image
    ImageX := IfThen(AllCollectiblesObtained, 48, 0);
    ImageY := ColStart;
    SrcRect := Rect(ImageX, ImageY, ImageX + ImageSize, ImageY + ImageSize);

//    // Scale proportionally to fit within the logo row
//    Scale := Min(PANEL_WIDTH / (SrcRect.Right - SrcRect.Left), LOGO_HEIGHT /
//      (SrcRect.Bottom - SrcRect.Top));

//    TalWidth := Round((SrcRect.Right - SrcRect.Left) * Scale);
//    TalHeight := Round((SrcRect.Bottom - SrcRect.Top) * Scale);

    ColWidth := ImageSize;
    ColHeight := ImageSize;

    // Add the talisman icon to the bottom right of the panel
    ColX := PanelX + PANEL_WIDTH - ColWidth;
    ColY := PanelY + LOGO_HEIGHT + 16;

    DstRect := Rect(ColX, ColY, ColX + ColWidth, ColY + ColHeight);

    ColBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
  finally
    ColBMP.Free;
  end;
end;

procedure TGameLevelSelectScreen.MakePackPanels;
var
  PanelBMP: TBitmap32;
  LogoBMP: TBitmap32;
  Pack: TNeoLevelGroup;
  PanelX, PanelY: Integer;
begin
  PanelBMP := TBitmap32.Create;
  LogoBMP := TBitmap32.Create;

  Pack := GameParams.CurrentLevel.Group.ParentBasePack; // TODO: Once we have a full list, get the currently-selected pack

  try
    // Create panel
    PanelBMP.SetSize(PANEL_WIDTH, PANEL_HEIGHT);
    PanelBMP.Clear($FF004A7F);

    // Centre the panel horizontally
    PanelX := (ScreenImg.Bitmap.Width - PanelBMP.Width) div 2;
    PanelY := 200;

    // Draw panel
    PanelBMP.DrawTo(ScreenImg.Bitmap, PanelX, PanelY);

    // Draw logo
    DrawLogoCropped(PanelX, PanelY);

    // Draw text
    DrawPanelText(IntToStr(Pack.LevelsCompleted) + ' / ' + IntToStr(Pack.LevelCount), PanelX, PanelY);

    // Add talisman and collectible icons
    AddIcons(PanelX, PanelY);
  finally
    LogoBMP.Free;
    PanelBMP.Free;
  end;
end;

procedure TGameLevelSelectScreen.BeginGame;
begin
  if GameParams.CurrentLevel <> nil then
  begin
    if GameParams.MenuSounds then SoundManager.PlaySound(SFX_OK);
    CloseScreen(gstPreview);
  end;
end;

procedure TGameLevelSelectScreen.AfterRedrawClickables;
begin
  inherited;
end;

function TGameLevelSelectScreen.GetWallpaperSuffix: String;
begin
  Result := 'menu';
end;

procedure TGameLevelSelectScreen.ShowSetupMenu;
var
  F: TFNLSetup;
  OldAmigaTheme, OldFullScreen, OldHighRes, OldShowMinimap: Boolean;
begin
  F := TFNLSetup.Create(Self);
  try
    OldAmigaTheme := GameParams.AmigaTheme;
    OldFullScreen := GameParams.FullScreen;
    OldHighRes := GameParams.HighResolution;
    OldShowMinimap := GameParams.ShowMinimap;

    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(OldAmigaTheme, OldFullScreen, OldHighRes, OldShowMinimap, False, False);
  finally
    F.Free;
  end;
end;

procedure TGameLevelSelectScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('amiga.png');
  MakePackPanels;
end;

end.
