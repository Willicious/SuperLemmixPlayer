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
  TGameMenuScreen = class(TGameBaseMenuScreen)
    private
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
      procedure HandleUpdateCheckResult;

      procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
      procedure DisableIdle;
      procedure EnableIdle;
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
  CustomPopup,
  FStyleManager,
  FNeoLemmixSetup,
  LemGame, // to clear replay
  LemVersion,
  PngInterface;

const
  REEL_Y_POSITION = 456;
  REEL_WIDTH = 40 * 16; // does NOT include the lemmings

  SCROLLER_LEMMING_FRAME_COUNT = 16;

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
    fReelForceDirection := -1;

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
    ShowMessage('It appears you have installed this version of NeoLemmix over ' +
                'an older major version. It is recommended that you perform a ' +
                'clean install of NeoLemmix whenever updating to a new major ' +
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
  end else if (fUpdateCheckThread <> nil) and (fUpdateCheckThread.Complete) then
  begin
    DisableIdle;

    if fUpdateCheckThread.Success then
      HandleUpdateCheckResult;

    fUpdateCheckThread.Free;
    fUpdateCheckThread := nil;

    EnableIdle;
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
    FreeAndNil(fUpdateCheckThread);

  inherited;
end;

procedure TGameMenuScreen.BuildScreen;
begin
  inherited;

  CleanUpIngameStuff;

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

  GROUP_BUTTONS_OFFSET_X = -38;
  GROUP_BUTTON_UP_OFFSET_Y = 0;
  GROUP_BUTTON_DOWN_OFFSET_Y = 17;

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

    // Group sign
    fGroupSignCenter := MakePosition(1, -0.5);
    GetGraphic('sign_group.png', BMP);
    NewRegion := MakeClickableImageAuto(fGroupSignCenter, BMP.BoundsRect, NextGroup, BMP);
    NewRegion.DrawInFrontWhenHighlit := false;

    DrawAllClickables(true); // for the next step's sake

    // Group sign buttons
    GetGraphic('sign_group_up.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupSignCenter.X + GROUP_BUTTONS_OFFSET_X, fGroupSignCenter.Y + GROUP_BUTTON_UP_OFFSET_Y),
                                        BMP.BoundsRect, NextGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_UP);

    GetGraphic('sign_group_down.png', BMP);
    NewRegion := MakeClickableImageAuto(Types.Point(fGroupSignCenter.X + GROUP_BUTTONS_OFFSET_X, fGroupSignCenter.Y + GROUP_BUTTON_DOWN_OFFSET_Y),
                                        BMP.BoundsRect, PrevGroup, BMP, 3);
    NewRegion.ShortcutKeys.Add(VK_DOWN);

    // Config
    GetGraphic('sign_config.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(-0.5, 0.5), BMP.BoundsRect, ShowConfigMenu, BMP);
    NewRegion.ShortcutKeys.Add(VK_F3);

    // Exit
    GetGraphic('sign_quit.png', BMP);
    NewRegion := MakeClickableImageAuto(MakePosition(0.5, 0.5), BMP.BoundsRect, ExitGame, BMP);
    NewRegion.ShortcutKeys.Add(VK_ESCAPE);

    fFinishedMakingSigns := true;

    DrawAllClickables;
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
        fReelFrame := fReelFrame + 16;
    end else begin
      Inc(fReelFrame);
      Dec(fReelTextPos);
    end;

    if (ScrollerText.Width <= REEL_WIDTH) and (fReelTextPos = (REEL_WIDTH - ScrollerText.Width) div 2) then
      if fReelForceDirection = 0 then
        fReelFreezeIterations := TEXT_FREEZE_BASE_ITERATIONS + (ScrollerText.Width div TEXT_FREEZE_WIDTH_DIV)
      else if fSwitchedTextSinceForce then
      begin
        fReelFreezeIterations := TEXT_FREEZE_BASE_ITERATIONS + TEXT_FREEZE_END_FORCE_EXTRA + (ScrollerText.Width div TEXT_FREEZE_WIDTH_DIV);
        fReelForceDirection := 0;
      end;


    if (fReelTextPos <= -ScrollerText.Width) or (fReelTextPos >= REEL_WIDTH) then
      PrepareNextReelText;
  end;
end;

procedure TGameMenuScreen.PrepareNextReelText;
var
  i, realI: Integer;
  S: String;

  SizeRect: TRect;
begin
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
  ScrollerText.SetSize(SizeRect.Width, SizeRect.Height);
  ScrollerText.Clear(0);
  ScrollerText.DrawMode := dmBlend;
  MenuFont.DrawText(ScrollerText, S, 0, 0);

  if (fReelForceDirection < 0) then
    fReelTextPos := -ScrollerText.Width
  else
    fReelTextPos := REEL_WIDTH;

  fLastReelUpdateTickCount := GetTickCount64;
  fSwitchedTextSinceForce := true;
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
begin
  Frame := (fReelFrame div 2) mod SCROLLER_LEMMING_FRAME_COUNT;

  SrcRect := Rect(0, 0, ScrollerLemmings.Width div 2, ScrollerLemmings.Height div SCROLLER_LEMMING_FRAME_COUNT);
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
    Result := SizedRect((ScreenImg.Bitmap.Width + REEL_WIDTH) div 2, REEL_Y_POSITION,
                        ScrollerLemmings.Width div 2, ScrollerLemmings.Height div SCROLLER_LEMMING_FRAME_COUNT)
  else
    Result := SizedRect((ScreenImg.Bitmap.Width - REEL_WIDTH) div 2 - (ScrollerLemmings.Width div 2), REEL_Y_POSITION,
                        ScrollerLemmings.Width div 2, ScrollerLemmings.Height div SCROLLER_LEMMING_FRAME_COUNT);
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
const
  MAX_AUTOGEN_WIDTH = 70;
  MAX_AUTOGEN_HEIGHT = 30;
var
  TempBmp: TBitmap32;
  Sca: Double;
begin
  if not GetGraphic('group_graphic.png', fGroupGraphic, true) then
    if not GetGraphic('rank_graphic.png', fGroupGraphic, true) then
    begin
      TempBmp := TBitmap32.Create;
      try
        MakeAutoSectionGraphic(TempBmp);

        if (TempBmp.Width <= MAX_AUTOGEN_WIDTH) and (TempBmp.Height < MAX_AUTOGEN_HEIGHT) then
          Sca := 1
        else
          Sca := Min(MAX_AUTOGEN_WIDTH / TempBmp.Width, MAX_AUTOGEN_HEIGHT / TempBmp.Height);

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
const
  GROUP_GRAPHIC_OFFSET_X = 11;
  GROUP_GRAPHIC_OFFSET_Y = 8;
begin
  fGroupGraphic.DrawTo(ScreenImg.Bitmap,
                       fGroupSignCenter.X + GROUP_GRAPHIC_OFFSET_X - (fGroupGraphic.Width div 2),
                       fGroupSignCenter.Y + GROUP_GRAPHIC_OFFSET_Y - (fGroupGraphic.Height div 2));
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
begin
  F := TFNLSetup.Create(self);
  try
    OldFullScreen := GameParams.FullScreen;
    OldHighRes := GameParams.HighResolution;

    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(OldFullScreen, OldHighRes, false, false);
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

procedure TGameMenuScreen.HandleUpdateCheckResult;
var
  NewVersionStr, OrigVersionStr: String;
  SL: TStringList;
  n: Integer;
  NewestID: Int64;
  URL: String;
  F: TFManageStyles;
begin
  NewVersionStr := fVersionInfo.Values['game'];
  if LeftStr(NewVersionStr, 1) = 'V' then
    NewVersionStr := RightStr(NewVersionStr, Length(NewVersionStr)-1);

  OrigVersionStr := NewVersionStr;
  NewVersionStr := StringReplace(NewVersionStr, '-', '.', [rfReplaceAll]);

  SL := TStringList.Create;
  try
    try
      SL.Delimiter := '.';
      SL.StrictDelimiter := true;
      SL.DelimitedText := NewVersionStr;

      if SL.Count < 4 then
        SL.Add('A');

      SL[3] := Char(Ord(SL[3][1]) - 65);

      NewestID := 0;
      for n := 0 to 3 do
        NewestID := (NewestID * 1000) + StrToIntDef(SL[n], 0);

      if (NewestID > CurrentVersionID){$ifdef exp} or (NewestID = CurrentVersionID){$endif} then
      begin
        case RunCustomPopup(self, 'Update', 'A NeoLemmix update, V' + OrigVersionStr + ', is available. Do you want to download it?',
          'Go to NeoLemmix website|Remind me later') of
          1: begin
               URL := 'https://www.neolemmix.com/?page=neolemmix';
               ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
               CloseScreen(gstExit);
             end;
           // 2: do nothing;
        end;
      end else if CheckStyleUpdates then
      begin
        // Add cursor stuff here

        case RunCustomPopup(self, 'Styles Update', 'Styles updates are available. Do you want to download them?',
          'Open Style Manager|Remind me later') of
          1: begin
               F := TFManageStyles.Create(self);
               try
                 F.ShowModal;
               finally
                 F.Free;
               end;
             end;
          // 2: do nothing;
        end;
      end;

    except
      // Fail silently.
    end;
  finally
    SL.Free;
  end;
end;

end.
