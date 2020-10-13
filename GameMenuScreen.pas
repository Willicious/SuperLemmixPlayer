unit GameMenuScreen;

{
  Still to do here:
  - Rank sign - GameParams.PrevGroup / GameParams.NextGroup exist, use them!
                Rank graphic center is offset from rank sign center by 10, 10.
  - Update check
  - Clean install check
  - First-time setup
}

interface

uses
  GameBaseMenuScreen,
  LemNeoLevelPack,
  LemStrings,
  LemTypes,
  GR32,
  Classes, SysUtils, Dialogs, Controls, ExtCtrls, Forms, Windows, Types, UMisc;

type
  TGameMenuScreen = class(TGameBaseMenuScreen)
    private
      ScrollerEraseBuffer: TBitmap32;
      ScrollerLemmings: TBitmap32;
      ScrollerReel: TBitmap32;
      ScrollerReelSegmentWidth: Integer;
      ScrollerText: TBitmap32;

      fLastReelUpdateTickCount: UInt64;
      fReelFrame: Integer;
      fReelTextPos: Integer;
      fReelTextIndex: Integer;
      fReelFreezeIterations: Integer;

      function GetGraphic(aName: String; aDst: TBitmap32; aAcceptFailure: Boolean = false): Boolean;
      procedure MakeAutoSectionGraphic(Dst: TBitmap32);

      procedure CleanupIngameStuff;

      procedure DrawLogo;
      procedure MakePanels;
      procedure MakeFooterText;

      procedure LoadScrollerGraphics;
      procedure DrawScroller;
      procedure DrawReel;
      procedure DrawReelText;
      procedure DrawWorkerLemmings;

      procedure UpdateReel;
      procedure UpdateReelIteration;
      procedure PrepareNextReelText;

      procedure BeginGame;
      procedure ExitGame;

      procedure DumpImages;
      procedure CleanseLevels;

      procedure ShowTalismanScreen; // Temporary

      procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    protected
      procedure BuildScreen; override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

implementation

uses
  LemGame, // to clear replay
  LemVersion,
  PngInterface,
  GameControl;

const
  REEL_Y_POSITION = 456;
  REEL_WIDTH = 40 * 16; // does NOT include the lemmings

{ TGameMenuScreen }

constructor TGameMenuScreen.Create(aOwner: TComponent);
begin
  inherited;
  ScrollerEraseBuffer := TBitmap32.Create;
  ScrollerLemmings := TBitmap32.Create;
  ScrollerReel := TBitmap32.Create;
  ScrollerText := TBitmap32.Create;
end;

destructor TGameMenuScreen.Destroy;
begin
  ScrollerEraseBuffer.Free;
  ScrollerLemmings.Free;
  ScrollerReel.Free;
  ScrollerText.Free;
  inherited;
end;

procedure TGameMenuScreen.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  UpdateReel;

  Done := false;
  Sleep(1);
end;

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

  LoadScrollerGraphics;
  DrawScroller;

  if (GameParams.CurrentLevel <> nil) and
     (GameParams.CurrentLevel.Group.ScrollerList.Count > 0) then
  begin
    Application.OnIdle := ApplicationIdle;

    fReelTextIndex := -1;
    PrepareNextReelText;
  end;
  fLastReelUpdateTickCount := GetTickCount64;
end;

procedure TGameMenuScreen.CleanupIngameStuff;
begin
  if Assigned(GlobalGame) then
    GlobalGame.ReplayManager.Clear(true);

  GameParams.ShownText := false;

  GameParams.SoundOptions := GameParams.SoundOptions; // Seems pointless, but this was (indirectly) in
                                                      // the old menu code, probably for a good reason.
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

procedure TGameMenuScreen.LoadScrollerGraphics;
var
  BMP: TBitmap32;
  x: Integer;
  EraseSrcRect: TRect;
begin
  BMP := TBitmap32.Create;
  try
    GetGraphic('scroller_lemmings.png', ScrollerLemmings);
    GetGraphic('scroller_segment.png', BMP);

    ScrollerReelSegmentWidth := BMP.Width;
    ScrollerReel.SetSize(REEL_WIDTH + ScrollerReelSegmentWidth, BMP.Height);

    x := 0;
    while x < ScrollerReel.Width do
    begin
      BMP.DrawTo(ScrollerReel, x, 0);
      x := x + BMP.Width;
    end;

    EraseSrcRect := Rect(0, REEL_Y_POSITION, ScreenImg.Width, REEL_Y_POSITION + BMP.Height);
    ScrollerEraseBuffer.SetSize(EraseSrcRect.Width, EraseSrcRect.Height);
    ScreenImg.Bitmap.DrawTo(ScrollerEraseBuffer, 0, 0, EraseSrcRect);
  finally
    BMP.Free;
  end;
end;

procedure TGameMenuScreen.UpdateReel;
const
  MS_PER_UPDATE = 6;
var
  Updates: Integer;
  n: Integer;
begin
  Updates := (GetTickCount64 - fLastReelUpdateTickCount) div MS_PER_UPDATE;

  if Updates > 0 then
  begin
    for n := 0 to Updates-1 do
    begin
      Inc(fLastReelUpdateTickCount, MS_PER_UPDATE);
      UpdateReelIteration;
    end;

    DrawScroller;
  end;
end;

procedure TGameMenuScreen.UpdateReelIteration;
const
  TEXT_FREEZE_BASE_ITERATIONS = 333;
  TEXT_FREEZE_WIDTH_DIV = 3;
begin
  if fReelFreezeIterations > 0 then
    Dec(fReelFreezeIterations)
  else begin
    Inc(fReelFrame);
    Dec(fReelTextPos);

    if (ScrollerText.Width <= REEL_WIDTH) and (fReelTextPos = (REEL_WIDTH - ScrollerText.Width) div 2) then
      fReelFreezeIterations := TEXT_FREEZE_BASE_ITERATIONS + (ScrollerText.Width div TEXT_FREEZE_WIDTH_DIV);

    if fReelTextPos = -ScrollerText.Width then
      PrepareNextReelText;
  end;
end;

procedure TGameMenuScreen.PrepareNextReelText;
var
  i, realI: Integer;
  S: String;

  SizeRect: TRect;

  StartTickCount: UInt64;
begin
  for i := 1 to GameParams.CurrentLevel.Group.ScrollerList.Count do
  begin
    if i = GameParams.CurrentLevel.Group.ScrollerList.Count then
    begin
      Application.OnIdle := nil;
      Exit;
    end;

    realI := (fReelTextIndex + i) mod GameParams.CurrentLevel.Group.ScrollerList.Count;

    if Trim(GameParams.CurrentLevel.Group.ScrollerList[realI]) <> '' then
    begin
      S := Trim(GameParams.CurrentLevel.Group.ScrollerList[realI]);
      fReelTextIndex := realI;
      Break;
    end;
  end;

  SizeRect := MenuFont.GetTextSize(S);
  ScrollerText.SetSize(SizeRect.Width, SizeRect.Height);
  ScrollerText.Clear(0);
  ScrollerText.DrawMode := dmBlend;
  MenuFont.DrawText(ScrollerText, S, 0, 0);

  fReelTextPos := REEL_WIDTH;
  fLastReelUpdateTickCount := GetTickCount64;
end;

procedure TGameMenuScreen.DrawScroller;
begin
  ScrollerEraseBuffer.DrawTo(ScreenImg.Bitmap, 0, REEL_Y_POSITION);

  DrawReel;
  DrawReelText;
  DrawWorkerLemmings;
end;

procedure TGameMenuScreen.DrawReel;
var
  SrcRect: TRect;
begin
  SrcRect := SizedRect(fReelFrame mod ScrollerReelSegmentWidth, 0, REEL_WIDTH, ScrollerReel.Height);
  ScrollerReel.DrawTo(ScreenImg.Bitmap, (ScreenImg.Bitmap.Width - REEL_WIDTH) div 2, REEL_Y_POSITION, SrcRect);
end;

procedure TGameMenuScreen.DrawReelText;
var
  SrcRect, DstRect: TRect;
  SizeDiff: Integer;
begin
  SrcRect := ScrollerText.BoundsRect;
  DstRect := SrcRect;

  Types.OffsetRect(DstRect, ((ScreenImg.Bitmap.Width - REEL_WIDTH) div 2) + fReelTextPos, REEL_Y_POSITION);

  if DstRect.Left < (ScreenImg.Bitmap.Width - REEL_WIDTH) div 2 then
  begin
    SizeDiff := ((ScreenImg.Bitmap.Width - REEL_WIDTH) div 2) - DstRect.Left;
    DstRect.Left := DstRect.Left + SizeDiff;
    SrcRect.Left := SrcRect.Left + SizeDiff;
  end;

  if DstRect.Right >= (ScreenImg.Bitmap.Width + REEL_WIDTH) div 2 then
  begin
    SizeDiff := DstRect.Right - ((ScreenImg.Bitmap.Width + REEL_WIDTH) div 2);
    DstRect.Right := DstRect.Right - SizeDiff;
    SrcRect.Right := SrcRect.Right - SizeDiff;
  end;

  if SrcRect.Width > 0 then
    ScrollerText.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
end;

procedure TGameMenuScreen.DrawWorkerLemmings;
var
  SrcRect, DstRect: TRect;
  Frame: Integer;
const
  SCROLLER_LEMMING_FRAME_COUNT = 16;
begin
  Frame := (fReelFrame div 2) mod SCROLLER_LEMMING_FRAME_COUNT;

  SrcRect := Rect(0, 0, ScrollerLemmings.Width div 2, ScrollerLemmings.Height div SCROLLER_LEMMING_FRAME_COUNT);
  Types.OffsetRect(SrcRect, 0, SrcRect.Height * Frame);

  DstRect := SizedRect((ScreenImg.Bitmap.Width - REEL_WIDTH) div 2 - SrcRect.Width, REEL_Y_POSITION, SrcRect.Width, SrcRect.Height);
  ScrollerLemmings.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);

  Types.OffsetRect(SrcRect, SrcRect.Width, 0);
  DstRect := SizedRect((ScreenImg.Bitmap.Width + REEL_WIDTH) div 2, REEL_Y_POSITION, SrcRect.Width, SrcRect.Height);
  ScrollerLemmings.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
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
