unit GameMenuScreen;

interface

uses
  GameBaseMenuScreen,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  GR32,
  Classes, SysUtils, Dialogs, Controls, Forms, Windows;

type
  TGameMenuScreen = class(TGameBaseMenuScreen)
    private
      function GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = false): Boolean;
      procedure MakeAutoSectionGraphic(Dst: TBitmap32);

      procedure DrawLogo;
      procedure MakePanels;
      procedure MakeFooterText;

      procedure BeginGame;
      procedure ExitGame;

      procedure DumpImages;
      procedure CleanseLevels;

      procedure ShowTalismanScreen; // Temporary
    protected
      procedure BuildScreen; override;
  end;

implementation

uses
  LemVersion,
  PngInterface,
  GameControl;

{ TGameMenuScreen }

function TGameMenuScreen.GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = false): Boolean;
begin
  Result := true;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile(aName)) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile(aName), aDst)
  else if FileExists(AppPath + SFGraphicsMenu + aName) then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + aName, aDst)
  else begin
    if not aAcceptFailure then
      raise Exception.Create('Could not find gfx\menu\' + aName + '.');

    Result := false;
  end;

  aDst.DrawMode := dmBlend;
end;

procedure TGameMenuScreen.BuildScreen;
begin
  inherited;

  DrawLogo;
  MakePanels;
  MakeFooterText;
end;

procedure TGameMenuScreen.DrawLogo;
var
  LogoBMP: TBitmap32;
const
  LOGO_CENTER_X = 432;
  LOGO_CENTER_Y = 72;
begin
  LogoBMP := TBitmap32.Create;
  try
    GetGraphic('logo.png', LogoBMP);
    LogoBMP.DrawTo(ScreenImg.Bitmap, LOGO_CENTER_X - LogoBMP.Width div 2, LOGO_CENTER_Y - LogoBMP.Height div 2);
  finally
    LogoBMP.Free;
  end;
end;

procedure TGameMenuScreen.MakePanels;
const
  CARD_SPACING_HORZ = 160;
  CARD_SPACING_VERT = 104;

  CARD_AREA_CENTER_X = 432;
  CARD_AREA_CENTER_Y = 248;

  function MakePosition(aHorzOffset: Single; aVertOffset: Single): TPoint;
  begin
    Result.X := CARD_AREA_CENTER_X + Round(aHorzOffset * CARD_SPACING_HORZ);
    Result.Y := CARD_AREA_CENTER_Y + Round(aVertOffset * CARD_SPACING_VERT);
  end;

var
  NewRegion: TClickableRegion;
  BMP: TBitmap32;
begin
  BMP := TBitmap32.Create;
  try
    // Play
    GetGraphic('sign_play.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-1, -0.5), BMP.BoundsRect, BeginGame, BMP);
    NewRegion.ShortcutKeys.Add(VK_RETURN);
    NewRegion.ShortcutKeys.Add(VK_F1);

    // Level select
    if not GetGraphic('sign_code.png', BMP, true) then // Deprecated
      GetGraphic('sign_level_select.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(0, -0.5), BMP.BoundsRect, DoLevelSelect, BMP);
    NewRegion.ShortcutKeys.Add(VK_F2);

    // Insert group sign here

    // Config
    GetGraphic('sign_config.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-0.5, 0.5), BMP.BoundsRect, ShowConfigMenu, BMP);
    NewRegion.ShortcutKeys.Add(VK_F3);

    // Exit
    GetGraphic('sign_quit.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(0.5, 0.5), BMP.BoundsRect, ExitGame, BMP);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    // Hidden options
    MakeHiddenOption(VK_F4, ShowTalismanScreen);
    MakeHiddenOption(VK_F6, DumpImages);
    MakeHiddenOption(VK_F7, DoMassReplayCheck);
    MakeHiddenOption(VK_F8, CleanseLevels);
  finally
    BMP.Free;
  end;
end;

procedure TGameMenuScreen.MakeFooterText;
const
  FOOTER_START_Y_POSITION = 364;
  NL_INFO_Y_POSITION = FOOTER_START_Y_POSITION + (3 * 19);
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

  NLInfoText := 'NeoLemmix Player V' + CurrentVersionString;
  {$ifdef exp}if COMMIT_ID <> '' then NLInfoText := NLInfoText + ':' + Uppercase(COMMIT_ID);{$endif}

  MenuFont.DrawTextCentered(ScreenImg.Bitmap, PackInfoText, FOOTER_START_Y_POSITION);
  MenuFont.DrawTextCentered(ScreenImg.Bitmap, NLInfoText, NL_INFO_Y_POSITION);
end;

procedure TGameMenuScreen.BeginGame;
begin
  if GameParams.CurrentLevel <> nil then
    CloseScreen(gstPreview);
end;

procedure TGameMenuScreen.ExitGame;
begin
  CloseScreen(gstExit);
end;

procedure TGameMenuScreen.ShowTalismanScreen;
begin
  if (GameParams.CurrentLevel <> nil) and
     (GameParams.CurrentLevel.Group.ParentBasePack.Talismans.Count <> 0) then
    CloseScreen(gstTalisman);
end;

procedure TGameMenuScreen.DumpImages;
var
  BasePack: TNeoLevelGroup;
begin
  BasePack := GameParams.CurrentLevel.Group.ParentBasePack;
  BasePack.DumpImages(AppPath + 'Dump\' + MakeSafeForFilename(BasePack.Name) + '\');
  {$ifdef exp}
  BasePack.DumpNeoLemmixWebsiteMetaInfo(AppPath + 'Dump\' + MakeSafeForFilename(BasePack.Name) + '\');
  {$endif}
end;

procedure TGameMenuScreen.CleanseLevels;
var
  BasePack: TNeoLevelGroup;
begin
  BasePack := GameParams.CurrentLevel.Group.ParentBasePack;

  if DirectoryExists(AppPath + 'Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\') then
    ShowMessage('Output directory "Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\" already exists. Please delete this first.')
  else
    BasePack.CleanseLevels(AppPath + 'Cleanse\' + MakeSafeForFilename(BasePack.Name) + '\');
end;

procedure TGameMenuScreen.MakeAutoSectionGraphic(Dst: TBitmap32);
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

end.
