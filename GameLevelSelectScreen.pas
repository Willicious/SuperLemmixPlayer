unit GameLevelSelectScreen;

interface

uses
  StrUtils, Classes, SysUtils, Dialogs, Controls, ExtCtrls, Forms, Windows, ShellApi,
  Types, UMisc, Math, Graphics, Generics.Collections,
  GameBaseMenuScreen, GameControl,
  LemNeoLevelPack, LemNeoOnline, LemNeoParser, LemStrings, LemTypes,
  GR32, GR32_Image, GR32_Resamplers,
  SharedGlobals;

type
  TGameLevelSelectScreen = class;

  TPackItem = class
    private
      fPack: TNeoLevelGroup;
      fArea: TRect;
    public
      constructor Create(aPack: TNeoLevelGroup; aArea: TRect);
      procedure DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
      property Pack: TNeoLevelGroup read fPack;
      property Area: TRect read fArea;
    end;

  TGroupItem = class
    private
      fGroup: TNeoLevelGroup;
      fArea: TRect;
    public
      constructor Create(aGroup: TNeoLevelGroup; aArea: TRect);
      procedure DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
      property Group: TNeoLevelGroup read fGroup;
      property Area: TRect read fArea;
    end;

  TLevelItem = class
    private
      fLevel: TNeoLevelEntry;
      fArea: TRect;
    public
      constructor Create(aLevel: TNeoLevelEntry; aArea: TRect);
      procedure DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
      property Level: TNeoLevelEntry read fLevel;
      property Area: TRect read fArea;
    end;

  TGameLevelSelectScreen = class(TGameBaseMenuScreen)
    private
      fPackList: TObjectList<TPackItem>;
      fGroupList: TObjectList<TGroupItem>;
      fLevelList: TObjectList<TLevelItem>;
      fWallpaper: TBitmap32;
    protected
      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
      procedure OnKeyPress(var Key: Word); override;

      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;

      procedure InitializeFont(aFont: String; aStyle: TFontStyle; aSize: Integer);
      procedure DrawTempText;

      procedure RestoreWallpaper(aRect: TRect);
      procedure OpenPack(Pack: TNeoLevelGroup);
      procedure DrawLogoPanel(Pack: TNeoLevelGroup);
      procedure DrawPackList;
      procedure DrawGroupList(Pack: TNeoLevelGroup);
      procedure DrawLevelList(Group: TNeoLevelGroup);
      procedure DrawLogoCropped(Pack: TNeoLevelGroup);
      procedure ShowLevelProgress(Pack: TNeoLevelGroup);
      procedure ShowTalismanProgress(Pack: TNeoLevelGroup);
      procedure ShowCollectibleProgress(Pack: TNeoLevelGroup);

      procedure AfterRedrawClickables; override;
      procedure DoAfterConfig; override;

      procedure BeginGame;

      function IsCompilationPack(Pack: TNeoLevelGroup): Boolean;
      function GetWallpaperSuffix: String; override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

const
  GLOBAL_COLUMN_TOP = 20;

  FIRST_COLUMN_LEFT = 20;
  FIRST_COLUMN_WIDTH = 280;

  SECOND_COLUMN_LEFT = 320;
  SECOND_COLUMN_WIDTH = 400;

  THIRD_COLUMN_LEFT = 720;

  PACK_INFO_HEIGHT = 180;
  LOGO_HEIGHT = 80;
  LEVEL_ICON_TOP = 100;
  TALISMAN_ICON_TOP = 130;
  COLLECTIBLE_ICON_TOP = 160;

  PACK_LIST_TOP = 200;
  PACK_ITEM_HEIGHT = 24;

  GROUP_ITEM_HEIGHT = 24;
  GROUP_ITEM_GAP = 16;

  LEVEL_LIST_TOP = 80;
  LEVEL_ITEM_HEIGHT = 20;
  LEVEL_LIST_HEIGHT = 420;

implementation

uses
  LemMenuFont, CustomPopup, FSuperLemmixSetup, GameSound, LemGame, LemVersion, PngInterface;

{ === TPackItem === }

constructor TPackItem.Create(aPack: TNeoLevelGroup; aArea: TRect);
begin
  fPack := aPack;
  fArea := aArea;
end;

procedure TPackItem.DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
begin
  aBitmap.Font.Assign(aFont);
  aBitmap.RenderText(fArea.Left, fArea.Top, fPack.Name, clWhite32);
end;

{ === TGroupItem === }

constructor TGroupItem.Create(aGroup: TNeoLevelGroup; aArea: TRect);
begin
  fGroup := aGroup;
  fArea := aArea;
end;

procedure TGroupItem.DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
begin
  aBitmap.Font.Assign(aFont);
  aBitmap.RenderText(fArea.Left, fArea.Top, fGroup.Name, clWhite32);
end;

{ === TLevelItem === }

constructor TLevelItem.Create(aLevel: TNeoLevelEntry; aArea: TRect);
begin
  fLevel := aLevel;
  fArea := aArea;
end;

procedure TLevelItem.DrawClickableText(aBitmap: TBitmap32; aFont: TFont);
begin
  aBitmap.Font.Assign(aFont);
  aBitmap.RenderText(fArea.Left, fArea.Top, fLevel.Title, clWhite32);
end;

{ === TGameLevelSelectScreen === }

constructor TGameLevelSelectScreen.Create(aOwner: TComponent);
begin
  inherited;
  fPackList := TObjectList<TPackItem>.Create;
  fGroupList := TObjectList<TGroupItem>.Create;
  fLevelList := TObjectList<TLevelItem>.Create;
  fWallpaper := TBitmap32.Create;
  GameParams.MainForm.Caption := SProgramName + ' Level Select';
end;

destructor TGameLevelSelectScreen.Destroy;
begin
  fWallpaper.Free;
  fLevelList.Free;
  fGroupList.Free;
  fPackList.Free;
  inherited;
end;

procedure TGameLevelSelectScreen.RestoreWallpaper(aRect: TRect);
begin
  ScreenImg.Bitmap.Draw(aRect, aRect, fWallpaper);
end;

procedure TGameLevelSelectScreen.OpenPack(Pack: TNeoLevelGroup);
begin
  DrawLogoPanel(Pack);

  if Pack.Children.Count > 0 then
  begin
    DrawGroupList(Pack);
    DrawLevelList(Pack.Children[0]);
  end else begin
    fGroupList.Clear;
    RestoreWallpaper(Rect(SECOND_COLUMN_LEFT,
      GLOBAL_COLUMN_TOP,
      SECOND_COLUMN_LEFT + SECOND_COLUMN_WIDTH,
      GLOBAL_COLUMN_TOP + GROUP_ITEM_HEIGHT * 2));

    DrawLevelList(Pack);
  end;
end;

procedure TGameLevelSelectScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
var
  PackItem: TPackItem;
  GroupItem: TGroupItem;
  LevelItem: TLevelItem;
begin
  inherited;

  for PackItem in fPackList do
    if System.Types.PtInRect(PackItem.Area, aPoint) then
    begin
      OpenPack(PackItem.Pack);
      Exit;
    end;

  for GroupItem in fGroupList do
    if System.Types.PtInRect(GroupItem.Area, aPoint) then
    begin
      DrawLevelList(GroupItem.Group);
      Exit;
    end;

  for LevelItem in fLevelList do
    if System.Types.PtInRect(LevelItem.Area, aPoint) then
    begin
      GameParams.SetLevel(LevelItem.Level);
      BeginGame; // TODO - Rather than loading straight to the game, display the level's info
      Exit;
    end;

  DoLevelSelectModal;
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
var
  Pack: TNeoLevelGroup;
begin
  inherited;

  if (GameParams <> nil) and (GameParams.CurrentLevel <> nil) then
  begin
    Pack := GameParams.CurrentLevel.Group.ParentBasePack
  end else begin
    Pack := nil;
    ShowMessage('Unable to load current level. Returning to Main Menu.');
    CloseScreen(gstMenu);
  end;

  ScreenImg.BeginUpdate;
  try
    fWallpaper.Assign(ScreenImg.Bitmap);
    fClickableRegions.Clear;

    InitializeFont('Tahoma', fsBold, 8);
    DrawTempText;

    DrawLogoPanel(Pack);
    DrawPackList;

    if Pack.Children.Count > 0 then
    begin
      DrawGroupList(Pack);
      DrawLevelList(Pack.Children[0]);
    end else
      DrawLevelList(Pack);

    // Classic Mode
    DrawClassicModeButton;
    DrawAllClickables;
  finally
    ScreenImg.EndUpdate;
  end;
end;

procedure TGameLevelSelectScreen.InitializeFont(aFont: String; aStyle: TFontStyle; aSize: Integer);
begin
  ScreenImg.Bitmap.Font.Name := aFont;
  ScreenImg.Bitmap.Font.Style := [aStyle];
  ScreenImg.Bitmap.Font.Size := aSize;
  ScreenImg.Bitmap.Font.Quality := fqAntialiased;
end;

// TODO Remove this once the screen is fully implemented
procedure TGameLevelSelectScreen.DrawTempText;
begin
  ScreenImg.Bitmap.RenderText(720, 400, 'Click here or Press F3', clWhite32);
  ScreenImg.Bitmap.RenderText(720, 440, 'to open the Level Select dialog', clWhite32);
end;

procedure TGameLevelSelectScreen.DrawLogoPanel(Pack: TNeoLevelGroup);
begin
  RestoreWallpaper(Rect(FIRST_COLUMN_LEFT, GLOBAL_COLUMN_TOP, SECOND_COLUMN_LEFT,
      GLOBAL_COLUMN_TOP + PACK_INFO_HEIGHT));

  DrawLogoCropped(Pack);
  ShowLevelProgress(Pack);
  ShowTalismanProgress(Pack);
  ShowCollectibleProgress(Pack);
end;

procedure TGameLevelSelectScreen.DrawLogoCropped(Pack: TNeoLevelGroup);
var
  LogoBMP: TBitmap32;
  X, Y, PosX, PosY: Integer;
  MinX, MinY, MaxX, MaxY: Integer;
  DstRect, SrcRect: TRect;
  Scale: Double;
  Pixel: TColor32;
  Level: TNeoLevelEntry;
  LogoWidth, LogoHeight: Integer;
begin
  LogoBMP := TBitmap32.Create;
  try
    // Load logo
    Level := GameParams.CurrentLevel;
    try
      GameParams.SetLevel(Pack.FirstLevelRecursive);
      GetGraphic('logo.png', LogoBMP);
    finally
      GameParams.SetLevel(Level);
    end;

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

      Scale := Min(
        FIRST_COLUMN_WIDTH / (SrcRect.Right - SrcRect.Left),
        LOGO_HEIGHT / (SrcRect.Bottom - SrcRect.Top)
      );

      LogoWidth := Round((SrcRect.Right - SrcRect.Left) * Scale);
      LogoHeight := Round((SrcRect.Bottom - SrcRect.Top) * Scale);

      PosX := FIRST_COLUMN_LEFT;
      PosY := GLOBAL_COLUMN_TOP;

      DstRect := Rect(PosX, PosY, PosX + LogoWidth, PosY + LogoHeight);
      LogoBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
    end;
  finally
    LogoBMP.Free;
  end;
end;

procedure TGameLevelSelectScreen.ShowLevelProgress(Pack: TNeoLevelGroup);
var
  TotalLevels, TotalLevelsCompleted: Integer;
  ProgressText: String;
  X, Y, ImageX, ImageY: Integer;
  LvlBMP: TBitmap32;
  SrcRect, DstRect: TRect;
begin
  TotalLevels := Pack.LevelCount;
  
  if TotalLevels <= 0 then
    Exit;

  TotalLevelsCompleted := Pack.LevelsCompleted;
  
  LvlBMP := TBitmap32.Create;
  try
    GetGraphic('levelinfo_icons.png', LvlBMP); // TODO - this should eventually be LoadIcons (see FSuperLemmixLevelSelect)

    X := FIRST_COLUMN_LEFT;
    Y := LEVEL_ICON_TOP;

    ImageX := 160;
    ImageY := IfThen(TotalLevelsCompleted = TotalLevels, 64, 96);

    SrcRect := Rect(ImageX, ImageY, ImageX + 32, ImageY + 32);
    DstRect := Rect(X, Y, X + 32, Y + 32);

    LvlBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
  finally
    LvlBMP.Free;
  end;

  InitializeFont('Tahoma', fsBold, 6);
  ProgressText := IntToStr(TotalLevelsCompleted) + ' / ' + IntToStr(TotalLevels) + ' Levels';

  X := FIRST_COLUMN_LEFT + 60;
  Y := LEVEL_ICON_TOP + 10;

  ScreenImg.Bitmap.RenderText(X, Y, ProgressText, clLightGreen32);
end;

procedure TGameLevelSelectScreen.ShowTalismanProgress(Pack: TNeoLevelGroup);
var
  TotalTalismans, TotalTalismansUnlocked: Integer;
  ProgressText: String;
  X, Y, ImageX, ImageY: Integer;
  TalBMP: TBitmap32;
  SrcRect, DstRect: TRect;
begin
  TotalTalismans := Pack.Talismans.Count;
  
  if TotalTalismans <= 0 then
    Exit;

  TotalTalismansUnlocked := Pack.TalismansUnlocked;
  
  TalBMP := TBitmap32.Create;
  try
    GetGraphic('talismans.png', TalBMP);

    X := FIRST_COLUMN_LEFT;
    Y := TALISMAN_ICON_TOP;

    ImageX := IfThen(TotalTalismansUnlocked = TotalTalismans, 48, 0);
    ImageY := 96;

    SrcRect := Rect(ImageX, ImageY, ImageX + 48, ImageY + 48);
    DstRect := Rect(X, Y, X + 30, Y + 30);

    TalBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
  finally
    TalBMP.Free;
  end;

  InitializeFont('Tahoma', fsBold, 6);
  ProgressText := IntToStr(TotalTalismansUnlocked) + ' / ' + IntToStr(TotalTalismans) + ' Talismans';

  X := FIRST_COLUMN_LEFT + 60;
  Y := TALISMAN_ICON_TOP + 10;

  ScreenImg.Bitmap.RenderText(X, Y, ProgressText, clLightGreen32);
end;

procedure TGameLevelSelectScreen.ShowCollectibleProgress(Pack: TNeoLevelGroup);
var
  TotalCollectibles, TotalCollectiblesGathered: Integer;
  ProgressText: String;
  X, Y, ImageX, ImageY: Integer;
  ColBMP: TBitmap32;
  SrcRect, DstRect: TRect;
begin
  TotalCollectibles := Pack.TotalCollectibles;
  
  if TotalCollectibles <= 0 then
    Exit;

  TotalCollectiblesGathered := Pack.TotalCollectiblesGathered;

  ColBMP := TBitmap32.Create;
  try
    GetGraphic('talismans.png', ColBMP);

    X := FIRST_COLUMN_LEFT;
    Y := COLLECTIBLE_ICON_TOP;

    ImageX := IfThen(TotalCollectiblesGathered = TotalCollectibles, 48, 0);
    ImageY := 144;

    SrcRect := Rect(ImageX, ImageY, ImageX + 48, ImageY + 48);
    DstRect := Rect(X, Y, X + 30, Y + 30);

    ColBMP.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
  finally
    ColBMP.Free;
  end;

  InitializeFont('Tahoma', fsBold, 6);
  ProgressText := IntToStr(TotalCollectiblesGathered) + ' / ' + IntToStr(TotalCollectibles) + ' Collectibles';

  X := FIRST_COLUMN_LEFT + 60;
  Y := COLLECTIBLE_ICON_TOP + 10;

  ScreenImg.Bitmap.RenderText(X, Y, ProgressText, clLightGreen32);
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

procedure TGameLevelSelectScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('amiga.png');
  DrawLogoPanel(GameParams.CurrentLevel.Group.ParentBasePack);
end;

function TGameLevelSelectScreen.IsCompilationPack(Pack: TNeoLevelGroup): Boolean;
var
  SubGroup, SubSubGroup: TNeoLevelGroup;
begin
  Result := False;

  if (Pack = nil) then
    Exit;

  // Parent Group must have no levels or at least one subgroup
  if (Pack.Levels.Count > 0) or (Pack.Children.Count = 0) then
    Exit;

  // Get the first subgroup
  SubGroup := Pack.Children[0];

  // SubGroup must also have no levels or at least one subgroup
  if (SubGroup.Levels.Count > 0) or (SubGroup.Children.Count = 0) then
    Exit;

  // Get the first sub-subgroup
  SubSubGroup := SubGroup.Children[0];

  // If the sub-subgroup has levels, it is *probably* a compilation
  // If it has at least one more subgroup, it is *definitely* a compilation
  if (SubSubGroup.Levels.Count > 0) or (SubSubGroup.Children.Count > 0) then
    Result := True;
end;

procedure TGameLevelSelectScreen.DrawPackList;
var
  i, j: Integer;
  Pack: TNeoLevelGroup;
  SubPack: TNeoLevelGroup;
  PackFont: TFont;
  Area: TRect;
begin
  PackFont := TFont.Create;
  try
    PackFont.Name := 'Tahoma';
    PackFont.Size := 8;

    fPackList.Clear;

    for i := 0 to GameParams.BaseLevelPack.Children.Count - 1 do
    begin
      Pack := GameParams.BaseLevelPack.Children[i];

      if IsCompilationPack(Pack) then
      begin
        for j := 0 to Pack.Children.Count - 1 do
        begin
          SubPack := Pack.Children[j];

          Area := Rect(FIRST_COLUMN_LEFT,
            PACK_LIST_TOP + fPackList.Count * PACK_ITEM_HEIGHT,
            FIRST_COLUMN_LEFT + FIRST_COLUMN_WIDTH,
            PACK_LIST_TOP + (fPackList.Count + 1) * PACK_ITEM_HEIGHT);

          fPackList.Add(TPackItem.Create(SubPack, Area));
          fPackList[fPackList.Count - 1].DrawClickableText(ScreenImg.Bitmap, PackFont);
        end;
      end else begin
        Area := Rect(FIRST_COLUMN_LEFT,
          PACK_LIST_TOP + fPackList.Count * PACK_ITEM_HEIGHT,
          FIRST_COLUMN_LEFT + FIRST_COLUMN_WIDTH,
          PACK_LIST_TOP + (fPackList.Count + 1) * PACK_ITEM_HEIGHT);

        fPackList.Add(TPackItem.Create(Pack, Area));
        fPackList[fPackList.Count - 1].DrawClickableText(ScreenImg.Bitmap, PackFont);
      end;
    end;
  finally
    PackFont.Free;
  end;
end;

procedure TGameLevelSelectScreen.DrawGroupList(Pack: TNeoLevelGroup);
var
  i: Integer;
  Group: TNeoLevelGroup;
  GroupFont: TFont;
  Area: TRect;
  TextSize: TSize;
  CurrentX, CurrentY: Integer;
  GroupAreaRight: Integer;
begin
  GroupFont := TFont.Create;
  try
    GroupFont.Name := 'Tahoma';
    GroupFont.Size := 8;

    InitializeFont('Tahoma', fsBold, 8);

    RestoreWallpaper(Rect(SECOND_COLUMN_LEFT,
      GLOBAL_COLUMN_TOP,
      SECOND_COLUMN_LEFT + SECOND_COLUMN_WIDTH,
      GLOBAL_COLUMN_TOP + GROUP_ITEM_HEIGHT * 2));

    fGroupList.Clear;

    CurrentX := SECOND_COLUMN_LEFT;
    CurrentY := GLOBAL_COLUMN_TOP;
    GroupAreaRight := SECOND_COLUMN_LEFT + SECOND_COLUMN_WIDTH;

    ScreenImg.Bitmap.Font.Assign(GroupFont);

    for i := 0 to Pack.Children.Count - 1 do
    begin
      Group := Pack.Children[i];

      TextSize := ScreenImg.Bitmap.TextExtent(Group.Name);
      TextSize.cx := TextSize.cx + ScreenImg.Bitmap.TextExtent(' ').cx;

      if (CurrentX + TextSize.cx > GroupAreaRight) and
         (CurrentX > SECOND_COLUMN_LEFT) then
      begin
        CurrentX := SECOND_COLUMN_LEFT;
        Inc(CurrentY, GROUP_ITEM_HEIGHT);
      end;

      Area := Rect(CurrentX, CurrentY, CurrentX + TextSize.cx, CurrentY + GROUP_ITEM_HEIGHT);

      fGroupList.Add(TGroupItem.Create(Group, Area));
      fGroupList[i].DrawClickableText(ScreenImg.Bitmap, GroupFont);

      Inc(CurrentX, TextSize.cx + GROUP_ITEM_GAP);
    end;
  finally
    GroupFont.Free;
  end;
end;

procedure TGameLevelSelectScreen.DrawLevelList(Group: TNeoLevelGroup);
var
  i: Integer;
  Level: TNeoLevelEntry;
  LevelFont: TFont;
  Area: TRect;
begin
  LevelFont := TFont.Create;
  try
    LevelFont.Name := 'Tahoma';
    LevelFont.Size := 8;

    RestoreWallpaper(Rect(SECOND_COLUMN_LEFT,
      LEVEL_LIST_TOP,
      SECOND_COLUMN_LEFT + SECOND_COLUMN_WIDTH,
      LEVEL_LIST_TOP + LEVEL_LIST_HEIGHT));

    fLevelList.Clear;

    for i := 0 to Group.Levels.Count - 1 do
    begin
      Level := Group.Levels[i];

      Area := Rect(SECOND_COLUMN_LEFT,
        LEVEL_LIST_TOP + i * LEVEL_ITEM_HEIGHT,
        SECOND_COLUMN_LEFT + SECOND_COLUMN_WIDTH,
        LEVEL_LIST_TOP + (i + 1) * LEVEL_ITEM_HEIGHT);

      fLevelList.Add(TLevelItem.Create(Level, Area));
      fLevelList[i].DrawClickableText(ScreenImg.Bitmap, LevelFont);
    end;
  finally
    LevelFont.Free;
  end;
end;

end.
