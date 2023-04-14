unit GameMenuScreen;

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
  TGameMenuPositionData = record
    LogoY: Integer;

    CardSpacingHorz: Integer;
    CardSpacingVert: Integer;
    CardsCenterY: Integer;

    GroupArrowsOffsetX: Integer;
    GroupArrowUpOffsetY: Integer;
    GroupArrowDownOffsetY: Integer;

    GroupGraphicOffsetX: Integer;
    GroupGraphicOffsetY: Integer;
    GroupGraphicAutoMaxWidth: Integer;
    GroupGraphicAutoMaxHeight: Integer;

    FooterTextY: Integer;

    ScrollerY: Integer;
    ScrollerWidth: Integer;
    ScrollerLemmingFrames: Integer;
  end;

  TGameMenuScreen = class(TGameBaseMenuScreen)
    private
      LayoutInfo: TGameMenuPositionData;

      ScrollerEraseBuffer: TBitmap32;

      ScrollerLemmings: TBitmap32;
      ScrollerReel: TBitmap32;
      ScrollerReelSegmentWidth: Integer;
      ScrollerText: TBitmap32;

      fDisableScroller: Boolean;
      fLastReelUpdateTickCount: UInt64;
      fReelFrame: Integer;
      fReelTextPos: Integer;
      fReelTextIndex: Integer;
      fReelFreezeIterations: Integer;

      fSwitchedTextSinceForce: Boolean;
      fReelForceDirection: Integer;

      fCleanInstallFail: Boolean;
      fUpdateCheckThread: TDownloadThread;
      fVersionInfo: TStringList;

      fGroupSignCenter: TPoint;
      fGroupGraphic: TBitmap32;

      fScrollerTextList: TStringList;

      fFinishedMakingSigns: Boolean;

      procedure MakeAutoSectionGraphic(Dst: TBitmap32);

      procedure CleanupIngameStuff;

      procedure DrawLogo;
      procedure MakePanels;
      procedure MakeFooterText;

      procedure LoadScrollerGraphics;
      procedure PrepareScrollerTextList;
      procedure DrawScroller;
      procedure DrawReel;
      procedure DrawReelText;
      procedure DrawWorkerLemmings;
      function GetWorkerLemmingRect(aRightLemming: Boolean): TRect;

      procedure UpdateReel;
      procedure UpdateReelIteration;
      procedure PrepareNextReelText;

      procedure BeginGame;
      procedure ExitGame;

      procedure PrevGroup;
      procedure NextGroup;
      procedure UpdateGroupSign(aRedraw: Boolean = true);
      procedure RedrawGroupSign;

      procedure ShowSetupMenu;
      procedure DoCleanInstallCheck;
      procedure InitiateUpdateCheck;
      //procedure HandleUpdateCheckResult;

      procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
      procedure DisableIdle;
      procedure EnableIdle;

      procedure LoadLayoutData;
    protected
      procedure BuildScreen; override;
      procedure CloseScreen(aNextScreen: TGameScreenType); override;
      procedure AfterRedrawClickables; override;

      procedure DoAfterConfig; override;

      function GetBackgroundSuffix: String; override;
      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
  end;

implementation

uses
  LemMenuFont, // for size const
  CustomPopup,
  FStyleManager,
  FSuperLemmixSetup,
  LemGame, // to clear replay
  LemVersion,
  PngInterface;

{ TGameMenuScreen }

constructor TGameMenuScreen.Create(aOwner: TComponent);
begin
  inherited;

  ScrollerEraseBuffer := TBitmap32.Create;

  ScrollerLemmings := TBitmap32.Create;
  ScrollerReel := TBitmap32.Create;
  ScrollerText := TBitmap32.Create;

  fVersionInfo := TStringList.Create;

  fGroupGraphic := TBitmap32.Create;

  fScrollerTextList := TStringList.Create;
end;

destructor TGameMenuScreen.Destroy;
begin
  ScrollerEraseBuffer.Free;

  ScrollerLemmings.Free;
  ScrollerReel.Free;
  ScrollerText.Free;

  fVersionInfo.Free;

  fGroupGraphic.Free;

  fScrollerTextList.Free;

  inherited;
end;

procedure TGameMenuScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
var
  OldForceDir: Integer;
begin
  inherited;

  OldForceDir := fReelForceDirection;

  if Types.PtInRect(GetWorkerLemmingRect(false), aPoint) then
    fReelForceDirection := 1
  else if Types.PtInRect(GetWorkerLemmingRect(true), aPoint) then
    fReelForceDirection := -1
  else
    BeginGame;

  if fReelForceDirection <> OldForceDir then
  begin
    fReelFreezeIterations := 0;
    fSwitchedTextSinceForce := false;
  end;
end;

procedure TGameMenuScreen.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  if fCleanInstallFail then
  begin
    DisableIdle;

    fCleanInstallFail := false;
    ShowMessage('It appears you have installed this version of SuperLemmix over ' +
                'an older major version. It is recommended that you perform a ' +
                'clean install of SuperLemmix whenever updating to a new major ' +
                'version. If you encounter any bugs, especially relating to ' +
                'styles, please test with a fresh install before reporting them.');
    fLastReelUpdateTickCount := GetTickCount64;

    EnableIdle;
  end else if not GameParams.LoadedConfig then
  begin
    DisableIdle;

    GameParams.LoadedConfig := true;
    ShowSetupMenu;

    EnableIdle;
  //end else if (fUpdateCheckThread <> nil) and (fUpdateCheckThread.Complete) then
  //begin
    //DisableIdle;

    //if fUpdateCheckThread.Success then
      //HandleUpdateCheckResult;

    //fUpdateCheckThread.Free;
    //fUpdateCheckThread := nil;

    //EnableIdle;
  end else if not fDisableScroller then
    UpdateReel;

  Done := false;
  Sleep(1);
end;

procedure TGameMenuScreen.DisableIdle;
begin
  Application.OnIdle := nil;
end;

procedure TGameMenuScreen.EnableIdle;
begin
  Application.OnIdle := ApplicationIdle;
  fLastReelUpdateTickCount := GetTickCount64;
end;

procedure TGameMenuScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  if fUpdateCheckThread <> nil then
  begin
    fUpdateCheckThread.Kill;
    FreeAndNil(fUpdateCheckThread);
  end;

  inherited;
end;

procedure TGameMenuScreen.BuildScreen;
begin
  inherited;

  CleanUpIngameStuff;

  LoadLayoutData;

  UpdateGroupSign(false);

  DrawLogo;
  MakePanels;
  MakeFooterText;

  LoadScrollerGraphics;
  DrawScroller;
  PrepareScrollerTextList;

  DoCleanInstallCheck;

  if not GameParams.DoneUpdateCheck then
    InitiateUpdateCheck;

  if (GameParams.CurrentLevel <> nil) and
     (fScrollerTextList.Count > 0) then
  begin
    fReelTextIndex := -1;
    PrepareNextReelText;
  end else
    fDisableScroller := true;

  EnableIdle;
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
begin
  LogoBMP := TBitmap32.Create;
  try
    GetGraphic('logo.png', LogoBMP);
    LogoBMP.DrawTo(ScreenImg.Bitmap, (ScreenImg.Bitmap.Width - LogoBMP.Width) div 2, LayoutInfo.LogoY - LogoBMP.Height div 2);
  finally
    LogoBMP.Free;
  end;
end;

procedure TGameMenuScreen.MakePanels;
  function MakePosition(aHorzOffset: Single; aVertOffset: Single): TPoint;
  begin
    Result.X := (ScreenImg.Bitmap.Width div 2) + Round(aHorzOffset * LayoutInfo.CardSpacingHorz);
    Result.Y := LayoutInfo.CardsCenterY + Round(aVertOffset * LayoutInfo.CardSpacingVert);
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

    // Group sign
    fGroupSignCenter := MakePosition(0.5, 0.5);
    GetGraphic('sign_group.png', BMP);
    NewRegion := MakeClickableImageAuto(fGroupSignCenter, BMP.BoundsRect, NextGroup, BMP);
    NewRegion.DrawInFrontWhenHighlit := false;

    DrawAllClickables(true); // for the next step's sake

    // Group sign buttons
    GetGraphic('sign_group_up.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupSignCenter.X + LayoutInfo.GroupArrowsOffsetX, fGroupSignCenter.Y + LayoutInfo.GroupArrowUpOffsetY),
                                        BMP.BoundsRect, NextGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_UP);

    GetGraphic('sign_group_down.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupSignCenter.X + LayoutInfo.GroupArrowsOffsetX, fGroupSignCenter.Y + LayoutInfo.GroupArrowDownOffsetY),
                                        BMP.BoundsRect, PrevGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_DOWN);

    // Config
    GetGraphic('sign_config.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-0.5, 0.5), BMP.BoundsRect, ShowConfigMenu, BMP);
    NewRegion.ShortcutKeys.Add(VK_F3);

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

procedure TGameMenuScreen.MakeFooterText;
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

  MenuFont.DrawTextCentered(ScreenImg.Bitmap, PackInfoText, LayoutInfo.FooterTextY);
  MenuFont.DrawTextCentered(ScreenImg.Bitmap, NLInfoText, LayoutInfo.FooterTextY + (3 * CHARACTER_HEIGHT));
end;

procedure TGameMenuScreen.LoadLayoutData;
var
  Parser: TParser;

  procedure ReadPositionData;
  var
    Sec: TParserSection;
  begin
    // May be called twice - first to load defaults from data/title.nxmi, second to load pack settings.
    Sec := Parser.MainSection;

    LayoutInfo.LogoY := Sec.LineNumericDefault['LOGO_CENTER_Y', LayoutInfo.LogoY];

    LayoutInfo.CardSpacingHorz := Sec.LineNumericDefault['CARDS_SPACING_X', LayoutInfo.CardSpacingHorz];
    LayoutInfo.CardSpacingVert := Sec.LineNumericDefault['CARDS_SPACING_Y', LayoutInfo.CardSpacingVert];
    LayoutInfo.CardsCenterY := Sec.LineNumericDefault['CARDS_CENTER_Y', LayoutInfo.CardsCenterY];

    LayoutInfo.GroupArrowsOffsetX := Sec.LineNumericDefault['GROUP_ARROWS_OFFSET_X', LayoutInfo.GroupArrowsOffsetX];
    LayoutInfo.GroupArrowUpOffsetY := Sec.LineNumericDefault['GROUP_ARROWS_UP_OFFSET_Y', LayoutInfo.GroupArrowUpOffsetY];
    LayoutInfo.GroupArrowDownOffsetY := Sec.LineNumericDefault['GROUP_ARROWS_DOWN_OFFSET_Y', LayoutInfo.GroupArrowDownOffsetY];

    LayoutInfo.GroupGraphicOffsetX := Sec.LineNumericDefault['GROUP_GRAPHIC_OFFSET_X', LayoutInfo.GroupGraphicOffsetX];
    LayoutInfo.GroupGraphicOffsetY := Sec.LineNumericDefault['GROUP_GRAPHIC_OFFSET_Y', LayoutInfo.GroupGraphicOffsetY];
    LayoutInfo.GroupGraphicAutoMaxWidth := Sec.LineNumericDefault['GROUP_GRAPHIC_AUTO_WIDTH_LIMIT', LayoutInfo.GroupGraphicAutoMaxWidth];
    LayoutInfo.GroupGraphicAutoMaxHeight := Sec.LineNumericDefault['GROUP_GRAPHIC_AUTO_HEIGHT_LIMIT', LayoutInfo.GroupGraphicAutoMaxHeight];

    LayoutInfo.FooterTextY := Sec.LineNumericDefault['FOOTER_TEXT_TOP_Y', LayoutInfo.FooterTextY];

    LayoutInfo.ScrollerY := Sec.LineNumericDefault['SCROLLER_TOP_Y', LayoutInfo.ScrollerY];
    LayoutInfo.ScrollerWidth := Sec.LineNumericDefault['SCROLLER_LENGTH', LayoutInfo.ScrollerWidth div CHARACTER_WIDTH] * CHARACTER_WIDTH;
    LayoutInfo.ScrollerLemmingFrames := Sec.LineNumericDefault['SCROLLER_LEMMING_FRAMES', LayoutInfo.ScrollerLemmingFrames];
  end;
begin
  Parser := TParser.Create;
  try
    FillChar(LayoutInfo, SizeOf(TGameMenuPositionData), 0);

    Parser.LoadFromFile(AppPath + SFData + 'title.nxmi');
    ReadPositionData;

    if GameParams.CurrentLevel.Group.FindFile('title.nxmi') <> '' then
    begin
      Parser.LoadFromFile(GameParams.CurrentLevel.Group.FindFile('title.nxmi'));
      ReadPositionData;
    end;
  finally
    Parser.Free;
  end;
end;

procedure TGameMenuScreen.LoadScrollerGraphics;
var
  BMP: TBitmap32;
  x: Integer;
  EraseSrcRect: TRect;
  MaxHeight: Integer;
begin
  BMP := TBitmap32.Create;
  try
    GetGraphic('scroller_lemmings.png', ScrollerLemmings);
    GetGraphic('scroller_segment.png', BMP);

    ScrollerReelSegmentWidth := BMP.Width;
    ScrollerReel.SetSize(LayoutInfo.ScrollerWidth + ScrollerReelSegmentWidth, BMP.Height);

    x := 0;
    while x < ScrollerReel.Width do
    begin
      BMP.DrawTo(ScrollerReel, x, 0);
      x := x + BMP.Width;
    end;

    MaxHeight := Max(BMP.Height, ScrollerLemmings.Height div LayoutInfo.ScrollerLemmingFrames);
    MaxHeight := Max(MaxHeight, CHARACTER_HEIGHT);

    EraseSrcRect := Rect(0, LayoutInfo.ScrollerY, ScreenImg.Width, LayoutInfo.ScrollerY + MaxHeight);
    ScrollerEraseBuffer.SetSize(EraseSrcRect.Width, EraseSrcRect.Height);
    ScreenImg.Bitmap.DrawTo(ScrollerEraseBuffer, 0, 0, EraseSrcRect);
  finally
    BMP.Free;
  end;
end;

procedure TGameMenuScreen.PrepareScrollerTextList;
var
  i: Integer;
  Parser: TParser;
begin
  fScrollerTextList.Clear;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile(AppPath + SFData + 'scroller.nxmi');
    Parser.MainSection.DoForEachLine('LINE', procedure(aLine: TParserLine; const aIteration: Integer)
    begin
      fScrollerTextList.Add(aLine.ValueTrimmed);
    end);
  finally
    Parser.Free;
  end;

  if (GameParams.CurrentLevel <> nil) and (GameParams.CurrentLevel.Group <> nil) then
    for i := 0 to GameParams.CurrentLevel.Group.ScrollerList.Count-1 do
      fScrollerTextList.Insert(i, GameParams.CurrentLevel.Group.ScrollerList[i]);
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
      if (fReelForceDirection <> 0) and (fReelFreezeIterations = 0) then
        UpdateReelIteration;
    end;

    DrawScroller;
  end;
end;

procedure TGameMenuScreen.UpdateReelIteration;
const
  TEXT_FREEZE_BASE_ITERATIONS = 333;
  TEXT_FREEZE_WIDTH_DIV = 3;
  TEXT_FREEZE_END_FORCE_EXTRA = 222;
begin
  if fReelFreezeIterations > 0 then
    Dec(fReelFreezeIterations)
  else begin
    if fReelForceDirection < 0 then
    begin
      Dec(fReelFrame);
      Inc(fReelTextPos);

      if fReelFrame < 0 then
        fReelFrame := fReelFrame + (LayoutInfo.ScrollerLemmingFrames * 2);
    end else begin
      Inc(fReelFrame);
      Dec(fReelTextPos);
    end;

    if (ScrollerText.Width <= LayoutInfo.ScrollerWidth) and (fReelTextPos = (LayoutInfo.ScrollerWidth - ScrollerText.Width) div 2) then
      if fReelForceDirection = 0 then
        fReelFreezeIterations := TEXT_FREEZE_BASE_ITERATIONS + (ScrollerText.Width div TEXT_FREEZE_WIDTH_DIV)
      else if fSwitchedTextSinceForce then
      begin
        fReelFreezeIterations := TEXT_FREEZE_BASE_ITERATIONS + TEXT_FREEZE_END_FORCE_EXTRA + (ScrollerText.Width div TEXT_FREEZE_WIDTH_DIV);
        fReelForceDirection := 0;
      end;


    if (fReelTextPos <= -ScrollerText.Width) or (fReelTextPos >= LayoutInfo.ScrollerWidth) then
      PrepareNextReelText;
  end;
end;

procedure TGameMenuScreen.PrepareNextReelText;
const
  HUE_SHIFT = 0.250;
var
  i, realI: Integer;
  S: String;

  SizeRect: TRect;
  HueShift: TColorDiff;
  x, y: Integer;
begin
  FillChar(HueShift, SizeOf(TColorDiff), 0);
  HueShift.HShift := HUE_SHIFT;

  for i := 1 to fScrollerTextList.Count do
  begin
    if i = fScrollerTextList.Count then
    begin
      fDisableScroller := true;
      Exit;
    end;

    if fReelForceDirection < 0 then
    begin
      realI := (fReelTextIndex - i);
      if realI < 0 then
        realI := realI + fScrollerTextList.Count;
    end else
      realI := (fReelTextIndex + i) mod fScrollerTextList.Count;

    if Trim(fScrollerTextList[realI]) <> '' then
    begin
      S := Trim(fScrollerTextList[realI]);
      fReelTextIndex := realI;
      Break;
    end;
  end;

  SizeRect := MenuFont.GetTextSize(S);
  ScrollerText.SetSize(SizeRect.Width, SizeRect.Height + 4);
  ScrollerText.Clear(0);
  ScrollerText.DrawMode := dmBlend;
  MenuFont.DrawText(ScrollerText, S, 0, 4);

  for y := 0 to ScrollerText.Height-1 do
  for x := 0 to ScrollerText.Width-1 do
       begin
          ScrollerText[x, y] := ApplyColorShift(ScrollerText[x, y], HueShift);
        end;

  if (fReelForceDirection < 0) then
    fReelTextPos := -ScrollerText.Width
  else
    fReelTextPos := LayoutInfo.ScrollerWidth;

  fLastReelUpdateTickCount := GetTickCount64;
  fSwitchedTextSinceForce := true;
end;

procedure TGameMenuScreen.DrawScroller;
begin
  ScrollerEraseBuffer.DrawTo(ScreenImg.Bitmap, 0, LayoutInfo.ScrollerY);

  DrawReel;
  DrawReelText;
  DrawWorkerLemmings;
end;

procedure TGameMenuScreen.DrawReel;
var
  SrcRect: TRect;
begin
  SrcRect := SizedRect(fReelFrame mod ScrollerReelSegmentWidth, 0, LayoutInfo.ScrollerWidth, ScrollerReel.Height);
  ScrollerReel.DrawTo(ScreenImg.Bitmap, (ScreenImg.Bitmap.Width - LayoutInfo.ScrollerWidth) div 2, LayoutInfo.ScrollerY, SrcRect);
end;

procedure TGameMenuScreen.DrawReelText;
var
  SrcRect, DstRect: TRect;
  SizeDiff: Integer;
begin
  SrcRect := ScrollerText.BoundsRect;
  DstRect := SrcRect;

  Types.OffsetRect(DstRect, ((ScreenImg.Bitmap.Width - LayoutInfo.ScrollerWidth) div 2) + fReelTextPos, LayoutInfo.ScrollerY);

  if DstRect.Left < (ScreenImg.Bitmap.Width - LayoutInfo.ScrollerWidth) div 2 then
  begin
    SizeDiff := ((ScreenImg.Bitmap.Width - LayoutInfo.ScrollerWidth) div 2) - DstRect.Left;
    DstRect.Left := DstRect.Left + SizeDiff;
    SrcRect.Left := SrcRect.Left + SizeDiff;
  end;

  if DstRect.Right >= (ScreenImg.Bitmap.Width + LayoutInfo.ScrollerWidth) div 2 then
  begin
    SizeDiff := DstRect.Right - ((ScreenImg.Bitmap.Width + LayoutInfo.ScrollerWidth) div 2);
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
begin
  Frame := (fReelFrame div 4) mod LayoutInfo.ScrollerLemmingFrames;

  SrcRect := Rect(0, 0, ScrollerLemmings.Width div 2, ScrollerLemmings.Height div LayoutInfo.ScrollerLemmingFrames);
  Types.OffsetRect(SrcRect, 0, SrcRect.Height * Frame);

  DstRect := GetWorkerLemmingRect(false);
  ScrollerLemmings.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);

  Types.OffsetRect(SrcRect, SrcRect.Width, 0);
  DstRect := GetWorkerLemmingRect(true);
  ScrollerLemmings.DrawTo(ScreenImg.Bitmap, DstRect, SrcRect);
end;

function TGameMenuScreen.GetWorkerLemmingRect(aRightLemming: Boolean): TRect;
begin
  if aRightLemming then
    Result := SizedRect((ScreenImg.Bitmap.Width + LayoutInfo.ScrollerWidth) div 2, LayoutInfo.ScrollerY,
                        ScrollerLemmings.Width div 2, ScrollerLemmings.Height div LayoutInfo.ScrollerLemmingFrames)
  else
    Result := SizedRect((ScreenImg.Bitmap.Width - LayoutInfo.ScrollerWidth) div 2 - (ScrollerLemmings.Width div 2), LayoutInfo.ScrollerY,
                        ScrollerLemmings.Width div 2, ScrollerLemmings.Height div LayoutInfo.ScrollerLemmingFrames);
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

procedure TGameMenuScreen.PrevGroup;
begin
  GameParams.PrevGroup;
  UpdateGroupSign;
end;

procedure TGameMenuScreen.NextGroup;
begin
  GameParams.NextGroup;
  UpdateGroupSign;
end;

procedure TGameMenuScreen.UpdateGroupSign(aRedraw: Boolean);
var
  TempBmp: TBitmap32;
  Sca: Double;
begin
  if not GetGraphic('group_graphic.png', fGroupGraphic, true, true) then
    if not GetGraphic('rank_graphic.png', fGroupGraphic, true, true) then
    begin
      TempBmp := TBitmap32.Create;
      try
        MakeAutoSectionGraphic(TempBmp);

        if (TempBmp.Width <= LayoutInfo.GroupGraphicAutoMaxWidth) and (TempBmp.Height < LayoutInfo.GroupGraphicAutoMaxHeight) then
          Sca := 1
        else
          Sca := Min(LayoutInfo.GroupGraphicAutoMaxWidth / TempBmp.Width, LayoutInfo.GroupGraphicAutoMaxHeight / TempBmp.Height);

        fGroupGraphic.SetSize(Round(TempBmp.Width * Sca), Round(TempBmp.Height * Sca));
        fGroupGraphic.Clear(0);

        if Sca <> 1 then
          TLinearResampler.Create(TempBmp);

        TempBmp.DrawTo(fGroupGraphic, fGroupGraphic.BoundsRect);
      finally
        TempBmp.Free;
      end;
    end;

  if aRedraw then
    DrawAllClickables;
end;

procedure TGameMenuScreen.RedrawGroupSign;
begin
  fGroupGraphic.DrawTo(ScreenImg.Bitmap,
                       fGroupSignCenter.X + LayoutInfo.GroupGraphicOffsetX - (fGroupGraphic.Width div 2),
                       fGroupSignCenter.Y + LayoutInfo.GroupGraphicOffsetY - (fGroupGraphic.Height div 2));
end;

procedure TGameMenuScreen.AfterRedrawClickables;
begin
  inherited;

  if fFinishedMakingSigns then
    RedrawGroupSign;
end;

function TGameMenuScreen.GetBackgroundSuffix: String;
begin
  Result := 'menu';
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

procedure TGameMenuScreen.ShowSetupMenu;
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

procedure TGameMenuScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor;
end;

procedure TGameMenuScreen.DoCleanInstallCheck;
var
  SL: TStringList;
  FMVer, CVer: Integer;
begin
  SL := TStringList.Create;
  try
    if FileExists(AppPath + 'styles\version.ini') then
    begin
      SL.LoadFromFile(AppPath + 'styles\version.ini');
      if SL.Count >= 4 then
      begin
        FMVer := StrToIntDef(SL[0], -1);
        CVer := StrToIntDef(SL[1], -1);

        if (FMVer < FORMAT_VERSION) or
           ((FMVer = FORMAT_VERSION) and (CVer < CORE_VERSION)) then
          fCleanInstallFail := true;
      end;
    end;

    SL.Clear;
    SL.Add(IntToStr(FORMAT_VERSION));
    SL.Add(IntToStr(CORE_VERSION));
    SL.Add(IntToStr(FEATURES_VERSION));
    SL.Add(IntToStr(HOTFIX_VERSION));
    {$ifdef rc}
      SL.Add('RC');
    {$else}
      {$ifdef exp}
        SL.Add('EXP');
      {$else}
        SL.Add('STABLE');
      {$endif}
    {$endif}

    ForceDirectories(AppPath + 'styles\');
    SL.SaveToFile(AppPath + 'styles\version.ini');
  finally
    SL.Free;
  end;
end;

procedure TGameMenuScreen.InitiateUpdateCheck;
begin
  GameParams.DoneUpdateCheck := true;
  if not GameParams.CheckUpdates then Exit;

  fUpdateCheckThread := DownloadInThread(VERSION_FILE, fVersionInfo);
end;

//procedure TGameMenuScreen.HandleUpdateCheckResult;
//var
  //NewVersionStr, OrigVersionStr: String;
  //SL: TStringList;
  //n: Integer;
  //NewestID: Int64;
  //URL: String;
  //F: TFManageStyles;
//begin
  //NewVersionStr := fVersionInfo.Values['game'];
  //if LeftStr(NewVersionStr, 1) = 'V' then
    //NewVersionStr := RightStr(NewVersionStr, Length(NewVersionStr)-1);

  //OrigVersionStr := NewVersionStr;
  //NewVersionStr := StringReplace(NewVersionStr, '-', '.', [rfReplaceAll]);

  //SL := TStringList.Create;
  //try
    //try
      //SL.Delimiter := '.';
      //SL.StrictDelimiter := true;
      //SL.DelimitedText := NewVersionStr;

      //if SL.Count < 4 then
        //SL.Add('A');

      //SL[3] := Char(Ord(SL[3][1]) - 65);

      //NewestID := 0;
      //for n := 0 to 3 do
        //NewestID := (NewestID * 1000) + StrToIntDef(SL[n], 0);

      //if (NewestID > CurrentVersionID){$ifdef exp} or (NewestID = CurrentVersionID){$endif} then
      //begin
        //case RunCustomPopup(self, 'Update', 'A SuperLemmix update, V' + OrigVersionStr + ', is available. Do you want to download it?',
          //'Go to SuperLemmix website|Remind me later') of
          //1: begin
               //URL := 'https://www.neolemmix.com/?page=neolemmix';
               //ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
               //CloseScreen(gstExit);
             //end;
           //// 2: do nothing;
        //end;
      //end else if CheckStyleUpdates then
      //begin
        //// Add cursor stuff here

        //case RunCustomPopup(self, 'Styles Update', 'Styles updates are available. Do you want to download them?',
          //'Open Style Manager|Remind me later') of
          //1: begin
               //F := TFManageStyles.Create(self);
               //try
                 //F.ShowModal;
               //finally
                 //F.Free;
               //end;
             //end;
          //// 2: do nothing;
        //end;
      //end;

    //except
      //// Fail silently.
    //end;
  //finally
    //SL.Free;
  //end;
//end;

end.
