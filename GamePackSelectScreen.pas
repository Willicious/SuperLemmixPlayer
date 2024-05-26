unit GamePackSelectScreen;

interface

uses
  StrUtils, Classes, SysUtils, Dialogs, Controls, ExtCtrls, Forms, Windows, ShellApi,
  Types, UMisc, Math,
  GameBaseMenuScreen,
  GameControl,
  LemNeoLevelPack,
  LemNeoOnline,
  LemNeoParser,
  LemStrings,
  LemTypes,
  GR32, GR32_Resamplers;

type
  TGamePackSelectScreen = class(TGameBaseMenuScreen)
    private
      fGroupCardCenter: TPoint;
      fGroupCardGraphic: TBitmap32;

      fFinishedMakingSigns: Boolean;

      procedure MakeAutoSectionGraphic(Dst: TBitmap32);

      procedure DrawLogo;
      procedure MakePackPanels;
      procedure MakeFooterText;

      procedure BeginGame;
      procedure ExitGame;
      procedure PrevGroup;
      procedure NextGroup;
    procedure RedrawGroupSign;
    procedure UpdateGroupSign(aRedraw: Boolean);
    procedure ShowSetupMenu;

    protected
      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;
      procedure AfterRedrawClickables; override;

      procedure DoAfterConfig; override;

      function GetWallpaperSuffix: String; override;
      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

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

constructor TGamePackSelectScreen.Create(aOwner: TComponent);
begin
  inherited;
  fGroupCardGraphic := TBitmap32.Create;

  GameParams.MainForm.Caption := 'SuperLemmix Level Pack Select';
end;

destructor TGamePackSelectScreen.Destroy;
begin
  fGroupCardGraphic.Free;

  inherited;
end;

procedure TGamePackSelectScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  inherited;

  BeginGame;
end;

procedure TGamePackSelectScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited;
end;

procedure TGamePackSelectScreen.BuildScreen;
begin
  inherited;

  DrawLogo;
  MakePackPanels;
  MakeFooterText;

  if (GameParams.CurrentLevel <> nil) then
  begin

  end;
end;

procedure TGamePackSelectScreen.DrawLogo;
var
  LogoBMP: TBitmap32;
begin
  LogoBMP := TBitmap32.Create;
  try
    GetGraphic('logo.png', LogoBMP);
    LogoBMP.DrawTo(ScreenImg.Bitmap, (ScreenImg.Bitmap.Width - LogoBMP.Width) div 2, 180 - LogoBMP.Height div 2);
  finally
    LogoBMP.Free;
  end;
end;

procedure TGamePackSelectScreen.MakePackPanels;
  function MakePosition(aHorzOffset: Single; aVertOffset: Single): TPoint;
  begin
    Result.X := (ScreenImg.Bitmap.Width div 2) + Round(aHorzOffset * 5);
    Result.Y := 200 + Round(aVertOffset * 5);
  end;

var
  NewRegion: TClickableRegion;
  BMP: TBitmap32;
begin
  BMP := TBitmap32.Create;
  try
    fClickableRegions.Clear;

    // Classic Mode
    DrawClassicModeButton;

    // Play
    GetGraphic('sign_play.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-1, -0.5), BMP.BoundsRect, BeginGame, BMP);
    NewRegion.ShortcutKeys.Add(VK_RETURN);
    NewRegion.ShortcutKeys.Add(VK_F1);

    // Level select
    if not GetGraphic('sign_code.png', BMP, true) then // Deprecated
      GetGraphic('sign_level_select.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(0, -0.5), BMP.BoundsRect, DoLevelSelect, BMP);
    NewRegion.ShortcutKeys.Add(VK_F3);

    // Group sign
    fGroupCardCenter := MakePosition(0.5, 0.5);
    GetGraphic('sign_group.png', BMP);
    NewRegion := MakeClickableImageAuto(fGroupCardCenter, BMP.BoundsRect, NextGroup, BMP);
    NewRegion.DrawInFrontWhenHighlit := false;

    DrawAllClickables(true); // For the next step's sake

    // Group sign buttons
    GetGraphic('sign_group_up.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupCardCenter.X + 3, fGroupCardCenter.Y + 10),
                                        BMP.BoundsRect, NextGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_UP);

    GetGraphic('sign_group_down.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupCardCenter.X + 3, fGroupCardCenter.Y + 15),
                                        BMP.BoundsRect, PrevGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_DOWN);

    // Config
    GetGraphic('sign_config.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-0.5, 0.5), BMP.BoundsRect, ShowConfigMenu, BMP);
    NewRegion.ShortcutKeys.Add(VK_F2);

    // Exit
    GetGraphic('sign_quit.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(1, -0.5), BMP.BoundsRect, ExitGame, BMP);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    fFinishedMakingSigns := true;

    DrawAllClickables;
  finally
    BMP.Free;
  end;
end;

procedure TGamePackSelectScreen.MakeFooterText;
var
  PackInfoText: String;
  NLInfoText: String;

  HasAuthor: Boolean;
begin
  if GameParams.CurrentLevel <> nil then
  begin
    PackInfoText := GameParams.CurrentLevel.Group.PackTitle + #13;

    HasAuthor := GameParams.CurrentLevel.Group.Author <> '';
    if HasAuthor then
      PackInfoText := PackInfoText + GameParams.CurrentLevel.Group.PackAuthor;

    if GameParams.CurrentLevel.Group.PackVersion <> '' then
    begin
      if HasAuthor then
        PackInfoText := PackInfoText + ' | ';

      PackInfoText := PackInfoText + 'Version ' + GameParams.CurrentLevel.Group.PackVersion;
    end;
  end else if GameParams.BaseLevelPack <> nil then
    PackInfoText := #13 + 'No Levels Found'
  else
    PackInfoText := #13 + 'No Pack';

  NLInfoText := 'SuperLemmix Player V' + CurrentVersionString;
  {$ifdef exp}if COMMIT_ID <> '' then NLInfoText := NLInfoText + ':' + Uppercase(COMMIT_ID);{$endif}

  MenuFont.DrawTextCentered(ScreenImg.Bitmap, PackInfoText, 250);
  MenuFont.DrawTextCentered(ScreenImg.Bitmap, NLInfoText, 250 + (3 * CHARACTER_HEIGHT));
end;

procedure TGamePackSelectScreen.BeginGame;
begin
  if GameParams.CurrentLevel <> nil then
  begin
    if GameParams.MenuSounds then SoundManager.PlaySound(SFX_OK);
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePackSelectScreen.ExitGame;
begin
  if GameParams.MenuSounds then SoundManager.PlaySound(SFX_BYE);
  CloseScreen(gstExit);
end;

procedure TGamePackSelectScreen.PrevGroup;
begin
  if not GameParams.CurrentLevel.Group.IsLowestGroup then
  begin
    GameParams.PrevGroup;
    if GameParams.MenuSounds then SoundManager.PlaySound(SFX_SKILLBUTTON);
    UpdateGroupSign(True);
  end;
end;

procedure TGamePackSelectScreen.NextGroup;
begin
  if not GameParams.CurrentLevel.Group.IsHighestGroup then
  begin
    GameParams.NextGroup;
    if GameParams.MenuSounds then SoundManager.PlaySound(SFX_SKILLBUTTON);
    UpdateGroupSign(True);
  end;
end;

procedure TGamePackSelectScreen.UpdateGroupSign(aRedraw: Boolean);
var
  TempBmp: TBitmap32;
  Sca: Double;
begin
  if not GetGraphic('group_graphic.png', fGroupCardGraphic, true, true) then
    if not GetGraphic('rank_graphic.png', fGroupCardGraphic, true, true) then
    begin
      TempBmp := TBitmap32.Create;
      try
        MakeAutoSectionGraphic(TempBmp);

        if (TempBmp.Width <= 50) and (TempBmp.Height < 80) then
          Sca := 1
        else
          Sca := Min(50 / TempBmp.Width, 80 / TempBmp.Height);

        fGroupCardGraphic.SetSize(Round(TempBmp.Width * Sca), Round(TempBmp.Height * Sca));
        fGroupCardGraphic.Clear(0);

        if Sca <> 1 then
          TLinearResampler.Create(TempBmp);

        TempBmp.DrawTo(fGroupCardGraphic, fGroupCardGraphic.BoundsRect);
      finally
        TempBmp.Free;
      end;
    end;

  if aRedraw then
    DrawAllClickables;
end;

procedure TGamePackSelectScreen.RedrawGroupSign;
begin
  fGroupCardGraphic.DrawTo(ScreenImg.Bitmap,
                       30 + 10 - (fGroupCardGraphic.Width div 2),
                       fGroupCardCenter.Y + 80 - (fGroupCardGraphic.Height div 2));
end;

procedure TGamePackSelectScreen.AfterRedrawClickables;
begin
  inherited;

  if fFinishedMakingSigns then
    RedrawGroupSign;
end;

function TGamePackSelectScreen.GetWallpaperSuffix: String;
begin
  Result := 'menu';
end;

procedure TGamePackSelectScreen.MakeAutoSectionGraphic(Dst: TBitmap32);
var
  S: String;
  n: Integer;
  BestMatch: Integer;
  SizeRect: TRect;
begin
  S := GameParams.CurrentLevel.Group.Name;
  if S = '' then
    S := 'N/A';

  if (Length(S) > 5) and (Pos(' ', S) > 0) then
  begin
    BestMatch := -1;
    for n := 1 to Length(S) do
      if S[n] = ' ' then
        if Abs((Length(S) / 2) - n) < Abs((Length(S) / 2) - BestMatch) then
          BestMatch := n
        else
          Break;

    if BestMatch > 0 then
      S[BestMatch] := #13;
  end;

  SizeRect := MenuFont.GetTextSize(S);
  Dst.SetSize(SizeRect.Width, SizeRect.Height);
  MenuFont.DrawTextCentered(Dst, S, 0);
end;

procedure TGamePackSelectScreen.ShowSetupMenu;
var
  F: TFNLSetup;
  OldFullScreen: Boolean;
  OldHighRes: Boolean;
  OldShowMinimap: Boolean;
begin
  F := TFNLSetup.Create(self);
  try
    OldFullScreen := GameParams.FullScreen;
    OldHighRes := GameParams.HighResolution;
    OldShowMinimap := GameParams.ShowMinimap;

    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(OldFullScreen, OldHighRes, OldShowMinimap, false, false);
  finally
    F.Free;
  end;
end;

procedure TGamePackSelectScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('amiga.png');
  MakePackPanels;
end;

end.
