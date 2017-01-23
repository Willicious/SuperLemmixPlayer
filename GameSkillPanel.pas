{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  Classes, Controls, SysUtils, Math,
  GR32, GR32_Image, GR32_Layers,
  UMisc,
  LemmixHotkeys, LemStrings, LemTypes,
  LemDosBmp, LemDosStructures, LemDosStyle,
  LemCore, LemLevel, LemNeoTheme,
  GameInterfaces, GameControl,
  LemGame, LemRenderHelpers, //for PARTICLE_COLORS consts, not that i'm sure if it acutally needs them anymore
  GameSound,
  PngInterface;

  {-------------------------------------------------------------------------------
    maybe this must be handled by lemgame (just bitmap writing)

  // info positions types:
  // 1. BUILDER(23)             1/14
  // 2. OUT 28                  15/23
  // 3. IN 99%                  24/31
  // 4. TIME 2-31               32/40

  -------------------------------------------------------------------------------}

type
  TMinimapClickEvent = procedure(Sender: TObject; const P: TPoint) of object;
type
  TSkillPanelToolbar = class(TCustomControl, IGameToolbar)
  private
    fStyle         : TBaseDosLemmingStyle;

    fImg           : TImage32;

    fOriginal      : TBitmap32;
    fMinimapRegion : TBitmap32;
    fLevel         : TLevel;
    fSkillFont     : array['0'..'9', 0..1] of TBitmap32;
    fSkillCountErase : TBitmap32;
    fSkillLock     : TBitmap32;
    fSkillInfinite : TBitmap32;
    fSkillIcons    : array[0..16] of TBitmap32;
    fInfoFont      : array[0..44] of TBitmap32; {%} { 0..9} {A..Z} // make one of this!
    fGame          : TLemmingGame;
    { TODO : do something with this hardcoded shit }
    fButtonRects   : array[TSkillPanelButton] of TRect;
    fRectColor     : TColor32;

    fViewPortRect  : TRect;
    fOnMinimapClick            : TMinimapClickEvent; // event handler for minimap
    fCurrentScreenOffset : Integer;

    fHighlitSkill: TSkillPanelButton;
    fLastHighlitSkill: TSkillPanelButton; // to avoid sounds when shouldn't be played
    fSkillCounts: Array[TSkillPanelButton] of Integer; // includes "non-skill" buttons as error-protection, but also for the release rate




    procedure SetLevel(const Value: TLevel);

    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);

    procedure SetGame(const Value: TLemmingGame);
  protected
    procedure ReadBitmapFromStyle; virtual;
    procedure ReadFont;
    procedure SetButtonRects;
  public
    fLastDrawnStr: string[40];
    fNewDrawStr: string[40];
    RedrawnChars: Integer;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure DrawNewStr;
    procedure SetButtonRect(btn: TSkillPanelButton; bpos: Integer);
    procedure SetSkillIcons;
    property Img: TImage32 read fImg;

    procedure SetViewPort(const R: TRect);
    procedure RefreshInfo;

    procedure ClearSkills;

  { IGameInfoView support }
    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
    procedure DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
    procedure DrawMinimap(Map: TBitmap32);
    procedure SetInfoCursorLemming(const Lem: string; Num: Integer);
    procedure SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
    procedure SetReplayMark(Status: Integer);
    procedure SetTimeLimit(Status: Boolean);

    procedure SetCurrentScreenOffset(X: Integer);
    property OnMinimapClick: TMinimapClickEvent read fOnMinimapClick write fOnMinimapClick;
  published
    procedure SetStyleAndGraph(const Value: TBaseDosLemmingStyle; aScale: Integer);

    property Level: TLevel read fLevel write SetLevel;
    property Game: TLemmingGame read fGame write SetGame;
  end;


implementation

uses
  GameWindow;

function PtInRectEx(const Rect: TRect; const P: TPoint): Boolean;
begin
  Result := (P.X >= Rect.Left) and (P.X < Rect.Right) and (P.Y >= Rect.Top)
    and (P.Y < Rect.Bottom);
end;

{ TSkillPanelToolbar }

constructor TSkillPanelToolbar.Create(aOwner: TComponent);
var
  c: Char;
  i: Integer;
begin
  inherited Create(aOwner);
  fImg := TImage32.Create(Self);
  fImg.Parent := Self;
  fImg.RepaintMode := rmOptimizer;

  fMinimapRegion := TBitmap32.Create;

  fImg.OnMouseDown := ImgMouseDown;
  fImg.OnMouseMove := ImgMouseMove;
  fImg.OnMouseUp := ImgMouseUp;

  fRectColor := DosVgaColorToColor32(DosInLevelPalette[3]);

  fOriginal := TBitmap32.Create;

  for i := 0 to 44 do
    fInfoFont[i] := TBitmap32.Create;

  for i := 0 to 16 do
    fSkillIcons[i] := TBitmap32.Create;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i] := TBitmap32.Create;

  fSkillInfinite := TBitmap32.Create;
  fSkillCountErase := TBitmap32.Create;
  fSkillLock := TBitmap32.Create;


  // info positions types:
  // stringspositions=cursor,out,in,time=1,15,24,32
  // 1. BUILDER(23)             1/14               0..13      14
  // 2. OUT 28                  15/23              14..22      9
  // 3. IN 99%                  24/31              23..30      8
  // 4. TIME 2-31               32/40              31..39      9
                                                           //=40
  fLastDrawnStr := StringOfChar(' ', 40);
  fNewDrawStr := StringOfChar(' ', 40);
  fNewDrawStr := SSkillPanelTemplate;
//  '..............' + 'OUT_.....' + 'IN_.....' + '   T_.-..';

  Assert(length(fnewdrawstr) = 40, 'length error infostring');

  fHighlitSkill := spbNone;
  fLastHighlitSkill := spbNone;


end;

destructor TSkillPanelToolbar.Destroy;
var
  c: Char;
  i: Integer;
begin
  for i := 0 to 43 do
    fInfoFont[i].Free;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i].Free;

  for i := 0 to 16 do
    fSkillIcons[i].Free;

  fSkillInfinite.Free;
  fSkillCountErase.Free;
  fSkillLock.Free;

  fMinimapRegion.Free;

  fOriginal.Free;
  inherited;
end;

procedure TSkillPanelToolbar.ClearSkills;
var
  i: TSkillPanelButton;
begin
   for i := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do // standard skills
   begin
     DrawButtonSelector(i, false);
     DrawSkillCount(i, fSkillCounts[i]);
   end;
   DrawSkillCount(spbFaster, fSkillCounts[spbFaster]);
end;


procedure TSkillPanelToolbar.DrawButtonSelector(aButton: TSkillPanelButton; Highlight: Boolean);
var
  R: TRect;
  C: TColor32;
  A: TRect;
begin
  if Game.HyperSpeed then Exit;

  if (aButton = spbNone) or ((aButton = fHighlitSkill) and (Highlight = true)) then
    Exit;

  if fButtonRects[aButton].Left <= 0 then Exit;
  if (aButton > spbNuke) and GameParams.ShowMinimap then Exit;

  case Highlight of
    False :
      begin
        if aButton < spbNone then
        begin
          if fHighlitSkill = spbNone then Exit;
          R := fButtonRects[fHighlitSkill];
          fLastHighlitSkill := fHighlitSkill;
          fHighlitSkill := spbNone;
        end else
          R := fButtonRects[aButton];
        Inc(R.Right);
        Inc(R.Bottom, 2);

        // top
        A := R;
        A.Bottom := A.Top + 1;
        fOriginal.DrawTo(fImg.Bitmap, A, A);

        // left
        A := R;
        A.Right := A.Left + 1;
        fOriginal.DrawTo(fImg.Bitmap, A, A);

        // right
        A := R;
        A.Left := A.Right - 1;
        fOriginal.DrawTo(fImg.Bitmap, A, A);

        // bottom
        A := R;
        A.Top := A.Bottom - 1;
        fOriginal.DrawTo(fImg.Bitmap, A, A);
      end;
    True  :
      begin
        if aButton < spbNone then // we don't want to memorize this for eg. fast forward
        begin
          fHighlitSkill := aButton;
          R := fButtonRects[fHighlitSkill];
          if (fLastHighlitSkill <> spbNone) and (fLastHighlitSkill <> fHighlitSkill) then
            SoundManager.PlaySound(SFX_SKILLBUTTON);
        end else
          R := fButtonRects[aButton];
        Inc(R.Right);
        Inc(R.Bottom, 2);

        C := fRectColor;

        fImg.Bitmap.FrameRectS(R, C);
      end;
  end;
end;

procedure TSkillPanelToolbar.DrawNewStr;
var
  O, N: char;
  i, x, y, idx: integer;
  Changed: Integer;
begin

  Changed := 0;
  // optimze this by pre-drawing
     // - "OUT "
     // - "IN "
     // - "TIME "
     // - "-"

  // info positions types:
  // 1. BUILDER(23)             1/14               0..13
  // 2. OUT 28                  15/23              14..22
  // 3. IN 99%                  24/31              23..30
  // 4. TIME 2-31               32/40              31..39

  y := 0;
  x := 0;

  for i := 1 to 40 do
  begin
    idx := -1;
    O := fLastDrawnStr[i];
    N := fNewDrawStr[i];

    if O <> N then
    begin

      case N of
        '%':
          begin
            idx := 0;
          end;
        '0'..'9':
          begin
            idx := ord(n) - ord('0') + 1;
          end;
        '-':
          begin
            idx := 11;
          end;
        'A'..'Y':
          begin
            idx := ord(n) - ord('A') + 12;
          end;
        'Z':
          begin
            idx := ord(n) - ord('A') + 12;
          end;
        #91 .. #97:
          begin
            idx := ord(n) - ord('A') + 12;
          end;
      end;
      Inc(Changed);

      if idx >= 0 then
        fInfoFont[idx].DrawTo(fimg.Bitmap, x, 0)
      else
        fimg.Bitmap.FillRectS(x, y, x + 8, y + 16, 0);
    end;

    Inc(x, 8);

  end;

  RedrawnChars := Changed;
end;


procedure TSkillPanelToolbar.DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
var
  S: string;
  L, R: Char;
  BtnIdx: Integer;
  DstRect, SrcRect: TRect;
  aoNumber: Integer;

const
  FontYPos = 17;

begin
  // x = 3, 19, 35 etc. are the "black holes" for the numbers in the image
  // y = 17

  if (fButtonRects[aButton].Left < 0) then exit;

  fSkillCounts[aButton] := aNumber;

  if Game.HyperSpeed then exit;

  aoNumber := aNumber;
  aNumber := Math.Max(aNumber mod 100, 0);

  S := LeadZeroStr(aNumber, 2);
  L := S[1];
  R := S[2];

  BtnIdx := (fButtonRects[aButton].Left - 1) div 16;

  // If release rate locked, display as such
  if (aButton = spbFaster) and (fLevel.Info.ReleaseRateLocked or (fLevel.Info.ReleaseRate = 99)) then
  begin
    fSkillLock.DrawTo(fImg.Bitmap, BtnIdx * 16 + 4, 17);
    Exit;
  end;

  // White out if applicable
  fSkillCountErase.DrawTo(fImg.Bitmap, BtnIdx * 16 + 1, 16);
  if (aoNumber = 0) and (GameParams.BlackOutZero) then Exit;

  // Draw infinite symbol if, well, infinite.
  if (aoNumber > 99) then
  begin
    DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 8, 17 + 8);
    SrcRect := Rect(0, 0, 8, 8);
    fSkillInfinite.DrawTo(fImg.Bitmap, DstRect, SrcRect);
    Exit;
  end;

  // left
  DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 4, 17 + 8);
  SrcRect := Rect(0, 0, 4, 8);
  if (aoNumber >= 10) then fSkillFont[L, 1].DrawTo(fImg.Bitmap, DstRect, SrcRect); // 1 is left

  // right
  OffsetRect(DstRect, 2, 0);
  if (aoNumber >= 10) then OffsetRect(DstRect, 2, 0);
  SrcRect := Rect(4, 0, 8, 8);
  fSkillFont[R, 0].DrawTo(fImg.Bitmap, DstRect, SrcRect); // 0 is right

end;

procedure TSkillPanelToolbar.RefreshInfo;
begin
  DrawNewStr;
  fLastDrawnStr := fNewDrawStr;
end;



procedure TSkillPanelToolbar.ImgMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
{-------------------------------------------------------------------------------
  Mouse behaviour of toolbar.
  o Minimap scrolling
  o button clicks
-------------------------------------------------------------------------------}
var
  P: TPoint;
  i: TSkillPanelButton;
  R: PRect;
  SrcRect: TRect;
  q: Integer;
  Exec: Boolean;
begin
  P := Img.ControlToBitmap(Point(X, Y));
  TGameWindow(Parent).ApplyMouseTrap;

  // check minimap scroll
  if PtInRectEx(DosMiniMapCorners, P) and GameParams.ShowMinimap then
  begin
    Dec(P.X, DosMinimapCorners.Left);
    Dec(P.Y, DosMiniMapCorners.Top);
    if Game.Level.Info.Width < 1664 then
    begin
      Dec(P.X, 52 - (Game.Level.Info.Width div 32));
      q := Game.Level.Info.Width;
    end else
      q := 1664;
    if Game.Level.Info.Width < 1664 then
      P.X := Round(P.X * 16 * Game.Level.Info.Width / q);
      P.Y := Round(P.Y * 8 * Game.Level.Info.Height / 160);
    if Assigned(fOnMiniMapClick) then
      fOnMinimapClick(Self, P);

    Exit;
  end;

  if Game.HyperSpeed then
    Exit;

  for i := Low(TSkillPanelButton) to High(TSkillPanelButton) do // "ignore" spbNone
  begin
    R := @fButtonRects[i];
    if PtInRectEx(R^, P) then
    begin

      if GameParams.ExplicitCancel and (i in [spbSlower, spbFaster, spbNuke]) then Exit;

      if (Game.Replaying) and (i in [spbSlower, spbFaster]) and not (Game.Level.Info.ReleaseRateLocked) then
      begin
        if ((i = spbSlower) and (Game.CurrentReleaseRate > Level.Info.ReleaseRate))
        or ((i = spbFaster) and (Game.CurrentReleaseRate < 99)) then
          Game.RegainControl;
      end;

      Exec := true;
      if i = spbNuke then
        Exec := ssDouble in Shift;

      if Exec then
        if i < spbFastForward then // handled by TLemmingGame alone
        begin
          if i in [spbNuke] then
            Game.RegainControl;

          if i in [spbSlower, spbFaster] then
            Game.SetSelectedSkill(i, True, (Button = mbRight))
          else begin
            Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
            if (i = spbPause) then
            begin
              DrawButtonSelector(spbFastForward, false);
              DrawButtonSelector(spbPause, Game.Paused);
            end;
          end;
        end else begin // need special handling
          if GameParams.ShowMinimap and (i <> spbMinimap) then Exit;

          case i of
            spbFastForward: begin
                              Game.FastForward := not Game.FastForward;
                              DrawButtonSelector(spbFastForward, Game.FastForward);
                            end;
            spbRestart: TGameWindow(Parent).GotoSaveState(0, true);
            spbBackOneFrame: TGameWindow(Parent).GotoSaveState(Game.CurrentIteration - 2); // logically this should be -1, but -2 seems to give correct behaviour. should probably investigate this.
            spbForwardOneFrame: TGameWindow(Parent).ForceUpdateOneFrame := true;
            spbClearPhysics: TGameWindow(Parent).ClearPhysics := not TGameWindow(Parent).ClearPhysics;
            spbDirLeft: if TGameWindow(Parent).SkillPanelSelectDx = -1 then
                        begin
                          TGameWindow(Parent).SkillPanelSelectDx := 0;
                          DrawButtonSelector(spbDirLeft, false);
                        end else begin
                          TGameWindow(Parent).SkillPanelSelectDx := -1;
                          DrawButtonSelector(spbDirLeft, true);
                          DrawButtonSelector(spbDirRight, false);
                        end;
            spbDirRight: if TGameWindow(Parent).SkillPanelSelectDx = 1 then
                        begin
                          TGameWindow(Parent).SkillPanelSelectDx := 0;
                          DrawButtonSelector(spbDirRight, false);
                        end else begin
                          TGameWindow(Parent).SkillPanelSelectDx := 1;
                          DrawButtonSelector(spbDirLeft, false);
                          DrawButtonSelector(spbDirRight, true);
                        end;
            spbLoadReplay: TGameWindow(Parent).LoadReplay;
            spbMinimap: if GameParams.ShowMinimap then
                        begin
                          GameParams.ShowMinimap := false;
                          SrcRect := Rect(193, 16, 304, 48);
                          fOriginal.DrawTo(Img.Bitmap, SrcRect, SrcRect);
                          Img.Update;
                        end else begin
                          GameParams.ShowMinimap := true;
                          if Game.Paused then
                          begin
                            TGameWindow(Parent).ForceRenderMinimap;
                            DrawMinimap(Game.MiniMap);
                          end;
                        end;
          end;
        end;
      Exit;
    end;
  end;

end;

procedure TSkillPanelToolbar.ImgMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  P: TPoint;
  q: Integer;
begin

  Game.HitTestAutoFail := true;
  Game.HitTest;

  if ssLeft in Shift then
  begin
    P := Img.ControlToBitmap(Point(X, Y));

    if PtInRectEx(DosMiniMapCorners, P) and GameParams.ShowMinimap then
    begin
      Dec(P.X, DosMinimapCorners.Left);
      Dec(P.Y, DosMiniMapCorners.Top);
      if Game.Level.Info.Width < 1664 then
      begin
        Dec(P.X, 52 - (Game.Level.Info.Width div 32));
        q := Game.Level.Info.Width;
      end else
        q := 1664;
      P.X := Round(P.X * 16 * Game.Level.Info.Width / q);
      P.Y := Round(P.Y * 8 * Game.Level.Info.Height / 160);
      if Assigned(fOnMiniMapClick) then
        fOnMinimapClick(Self, P);
    end;
  end;
  if Y >= Img.Height - 1 then
    TGameWindow(Parent).VScroll := gsDown
  else
    TGameWindow(Parent).VScroll := gsNone;
  if X >= Img.Width - 1 then
    TGameWindow(Parent).HScroll := gsRight
  else if X <= 0 then
    TGameWindow(Parent).HScroll := gsLeft
  else
    TGameWindow(Parent).HScroll := gsNone;
end;

procedure TSkillPanelToolbar.ImgMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
   Game.SetSelectedSkill(spbSlower, False);
   Game.SetSelectedSkill(spbFaster, False);
end;




procedure TSkillPanelToolbar.ReadBitmapFromStyle;
var
  c: char; i: Integer;
  LemmixPal: TArrayOfColor32;
  HiPal: TArrayOfColor32;
  TempBmp, TempBmp2: TBitmap32;
  SrcRect: TRect;

  BlankPanels: TBitmap32;
  PanelIndex: Integer;
const
  SKILL_NAMES: array[0..16] of string = (
                 'walker',
                 'climber',
                 'swimmer',
                 'floater',
                 'glider',
                 'disarmer',
                 'bomber',
                 'stoner',
                 'blocker',
                 'platformer',
                 'builder',
                 'stacker',
                 'basher',
                 'fencer',
                 'miner',
                 'digger',
                 'cloner'
               );  

  procedure MakeWhiteoutImage;
  var
    x, y: Integer;
  begin
    fSkillCountErase.SetSize(16, 23);
    fSkillCountErase.Clear(0);
    fSkillCountErase.BeginUpdate;
    for x := 3 to 11 do
      for y := 1 to 8 do
        fSkillCountErase[x, y] := $FFF0D0D0;
    fSkillCountErase.EndUpdate;
  end;

  procedure GetGraphic(aName: String; aDst: TBitmap32);
  begin
    aName := AppPath + SFGraphicsPanel + aName;
    TPngInterface.LoadPngFile(aName, aDst);
    TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(aName, '_mask.png'), LemmixPal[7]);
  end;

  procedure DrawBlankPanel(aDst: TBitmap32; aDigitArea: Boolean);
  var
    SrcRect: TRect;
  begin
    SrcRect := Rect(PanelIndex * 16, 0, (PanelIndex+1) * 16, 23);
    aDst.SetSize(16, 23);
    aDst.Clear(0);
    BlankPanels.DrawTo(aDst, aDst.BoundsRect, SrcRect);
    if aDigitArea then
      fSkillCountErase.DrawTo(aDst);
    Inc(PanelIndex);
    if PanelIndex * 16 >= BlankPanels.Width then
      PanelIndex := 0;
  end;

  procedure MakePanel(aDst: TBitmap32; aImageFile: String; aDigitArea: Boolean);
  begin
    DrawBlankPanel(aDst, aDigitArea);
    GetGraphic(aImageFile, TempBmp2);
    TempBmp2.DrawTo(aDst);
  end;

begin


  if not (fStyle is TBaseDosLemmingStyle) then
    Exit;

  // try and concat palettes
  LemmixPal := DosPaletteToArrayOfColor32(DosInLevelPalette);
  if Game.fXmasPal then
  begin
    LemmixPal[1] := $D02020;
    LemmixPal[4] := $F0F000;
    LemmixPal[5] := $4040E0;
  end;
  SetLength(HiPal, 8);
  for i := 0 to 7 do
    HiPal[i] := PARTICLE_COLORS[i];

  {TODO: how o how is the palette constructed?????????}
  Assert(Length(HiPal) = 8, 'hipal error');
  SetLength(LemmixPal, 16);
  for i := 8 to 15 do
    LemmixPal[i] := HiPal[i - 8];
  LemmixPal[7] := GameParams.Renderer.Theme.Colors[MASK_COLOR];

  SetButtonRects;

    PanelIndex := 0;

    TempBmp := TBitmap32.Create;
    TempBmp.DrawMode := dmBlend;
    TempBmp.CombineMode := cmMerge;
    TempBmp2 := TBitmap32.Create;
    TempBmp2.DrawMode := dmBlend;
    TempBmp2.CombineMode := cmMerge;

    BlankPanels := TBitmap32.Create;
    BlankPanels.DrawMode := dmBlend;

    GetGraphic('skill_count_erase.png', fSkillCountErase);
    fSkillCountErase.DrawMode := dmBlend;
    fSkillCountErase.CombineMode := cmMerge;

    GetGraphic('skill_panels.png', BlankPanels);

    // Panel graphic
    fOriginal.SetSize(320, 40);
    fOriginal.Clear($FF000000);

    MakePanel(TempBmp, 'icon_rr_minus.png', true);
    TempBmp.DrawTo(fOriginal, 1, 16);
    MakePanel(TempBmp, 'icon_rr_plus.png', true);
    TempBmp.DrawTo(fOriginal, 17, 16);

    GetGraphic('minimap_region.png', fMinimapRegion);

    MakePanel(TempBmp, 'icon_ff.png', false);
    TempBmp.DrawTo(fOriginal, 193, 16);
    MakePanel(TempBmp, 'icon_restart.png', false);
    TempBmp.DrawTo(fOriginal, 209, 16);
    MakePanel(TempBmp, 'icon_1fb.png', false);
    TempBmp.DrawTo(fOriginal, 225, 16);
    MakePanel(TempBmp, 'icon_1ff.png', false);
    TempBmp.DrawTo(fOriginal, 241, 16);
    MakePanel(TempBmp, 'icon_clearphysics.png', false);
    TempBmp.DrawTo(fOriginal, 257, 16);
    MakePanel(TempBmp, 'icon_directional.png', false);
    TempBmp.DrawTo(fOriginal, 273, 16);
    MakePanel(TempBmp, 'icon_load_replay.png', false);
    TempBmp.DrawTo(fOriginal, 289, 16);
    MakePanel(TempBmp, 'icon_minimap.png', false);
    TempBmp.DrawTo(fOriginal, 305, 16);

    GetGraphic('empty_slot.png', TempBmp);
    for i := 0 to 7 do
      TempBmp.DrawTo(fOriginal, (i * 16) + 33, 16);

    MakePanel(TempBmp, 'icon_pause.png', false);
    TempBmp.DrawTo(fOriginal, 161, 16);
    MakePanel(TempBmp, 'icon_nuke.png', false);
    TempBmp.DrawTo(fOriginal, 177, 16);

    fImg.Bitmap.Assign(fOriginal);

    // Panel font
    GetGraphic('panel_font.png', TempBmp);
    SrcRect := Rect(0, 0, 8, 16);
    for i := 0 to 44 do
    begin
      if i = 38 then
      begin
        // switch to panel_icons.png file at this point
        GetGraphic('panel_icons.png', TempBmp);
        SrcRect := Rect(0, 0, 8, 16);
      end;
      fInfoFont[i].SetSize(8, 16);
      fInfoFont[i].Clear;
      TempBmp.DrawTo(fInfoFont[i], 0, 0, SrcRect);
      SrcRect.Right := SrcRect.Right + 8;
      SrcRect.Left := SrcRect.Left + 8;
    end;

    // Skill icons
    for i := 0 to 16 do
      MakePanel(fSkillIcons[i], 'icon_' + SKILL_NAMES[i] + '.png', true);

    // Skill counts
    GetGraphic('skill_count_digits.png', TempBmp);
    SrcRect := Rect(0, 0, 4, 8);
    for c := '0' to '9' do
    begin
      fSkillFont[c, 0].SetSize(8, 8);
      fSkillFont[c, 0].Clear(0);
      fSkillFont[c, 1].SetSize(8, 8);
      fSkillFont[c, 1].Clear(0);
      TempBmp.DrawTo(fSkillFont[c, 1], 0, 0, SrcRect);
      TempBmp.DrawTo(fSkillFont[c, 0], 4, 0, SrcRect);
      fSkillFont[c, 0].DrawMode := dmBlend;
      fSkillFont[c, 0].CombineMode := cmMerge;
      fSkillFont[c, 1].DrawMode := dmBlend;
      fSkillFont[c, 1].CombineMode := cmMerge;
      SrcRect.Right := SrcRect.Right + 4;
      SrcRect.Left := SrcRect.Left + 4;
    end;

    SrcRect.Right := SrcRect.Right + 4; // Position is correct at this point, but Infinite symbol is 8px wide not 4px
    fSkillInfinite.SetSize(8, 8);
    fSkillInfinite.Clear(0);
    TempBmp.DrawTo(fSkillInfinite, 0, 0, SrcRect);

    SrcRect.Right := SrcRect.Right + 8;
    SrcRect.Left := SrcRect.Left + 8;
    fSkillLock.SetSize(8, 8);
    fSkillLock.Clear(0);
    TempBmp.DrawTo(fSkillLock, 0, 0, SrcRect);

    fSkillInfinite.DrawMode := dmBlend;
    fSkillInfinite.CombineMode := cmMerge;
    fSkillLock.DrawMode := dmBlend;
    fSkillLock.CombineMode := cmMerge;

    TempBmp.Free;
    TempBmp2.Free;
    BlankPanels.Free;

end;

procedure TSkillPanelToolbar.ReadFont;
begin

end;

procedure TSkillPanelToolbar.SetSkillIcons;
var
  Org, R: TRect;
  Skill: TSkillPanelButton;
begin
  Org := Rect(33, 16, 47, 38); // exact position of first button
  R := Org;
  for Skill := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    if Skill in Level.Info.Skillset then
    begin
      fButtonRects[Skill] := R;

      fSkillIcons[Integer(Skill)].DrawTo(fImg.Bitmap, R.Left, R.Top{, SrcRect});
      fSkillIcons[Integer(Skill)].DrawTo(fOriginal, R.Left, R.Top{, SrcRect});

      OffsetRect(R, 16, 0);
    end;
  end;
end;

procedure TSkillPanelToolbar.SetButtonRects;
var
  R: TRect;
  iButton: TSkillPanelButton;
begin
  R := Rect(-1, -1, 0, 0); // exact position of first button

  for iButton := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    fButtonRects[iButton] := R;
  end;

  fButtonRects[spbSlower] := Rect(1, 16, 15, 38);
  fButtonRects[spbFaster] := Rect(17, 16, 31, 38);
  fButtonRects[spbPause]  := Rect(161, 16, 175, 38);
  fButtonRects[spbNuke]   := Rect(177, 16, 191, 38);

  R := Rect(193, 16, 207, 38);

  for iButton := spbFastForward to High(TSkillPanelButton) do
  begin
    fButtonRects[iButton] := R;
    OffsetRect(R, 16, 0);
  end;

  // special handling
  fButtonRects[spbDirLeft].Bottom := fButtonRects[spbDirLeft].Bottom - 12;
  fButtonRects[spbDirRight] := fButtonRects[spbDirLeft];
  OffsetRect(fButtonRects[spbDirRight], 0, 12);
end;

procedure TSkillPanelToolbar.SetButtonRect(btn: TSkillPanelButton; bpos: Integer);
var
  R: TRect;
begin
  R := Rect(1, 16, 15, 38);
  OffsetRect(R, 16 * (bpos - 1), 0);
  fButtonRects[btn] := R;
end;

procedure TSkillPanelToolbar.SetInfoCursorLemming(const Lem: string; Num: Integer);
var
  S: string;
begin
  S := Uppercase(Lem);
  if Lem <> '' then
  begin

    if Num = 0 then
      S := PadR(S, 14)
    else
      S := PadR(S + ' ' + IntToStr(Num), 14); //
    Move(S[1], fNewDrawStr[1], 14);
  end
  else begin
    S := '              ';
    Move(S[1], fNewDrawStr[1], 14);
  end;
end;

procedure TSkillPanelToolbar.SetReplayMark(Status: Integer);
var
  S: String;
begin
  if Status = 1 then
    S := #91
  else if Status = 2 then
    S := #97
  else
    S := ' ';
  Move(S[1], fNewDrawStr[15], 1);
end;

procedure TSkillPanelToolbar.SetTimeLimit(Status: Boolean);
var
  S: String;
begin
  if Status then
    S := #96
  else
    S := #95;
  Move(S[1], fNewDrawStr[35], 1);
end;


procedure TSkillPanelToolbar.SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  Assert(Num >= 0, 'Negative number of lemmings in hatch displayed');
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';  // probably will never blink, but let's have the option there for futureproofing
  Move(S[1], fNewDrawStr[18], 4);
end;


procedure TSkillPanelToolbar.SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  Assert(Num >= 0, 'Negative number of alive lemmings displayed');
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';
  Move(S[1], fNewDrawStr[24], 4);
end;

procedure TSkillPanelToolbar.SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  S := IntToStr(Num);
  if Length(S) < 4 then
  begin
    S := PadR(S, 3);
    S := PadL(S, 4);
  end;
  if Blinking then S := '    ';
  Move(S[1], fNewDrawStr[30], 4);
end;

procedure TSkillPanelToolbar.SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  if Blinking then
    S := '  '
  else
    S := PadL(IntToStr(Num), 2);
  Move(S[1], fNewDrawStr[36], 2);
end;

procedure TSkillPanelToolbar.SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
var
  S: string;
begin
  // stringspositions cursor,out,in,time = 1,15,24,32
  //fNewDrawStr := '..............' + 'OUT_.....' + 'IN_.....' + 'TIME_.-..';
  // Nepster: The two lines above are outdated and wrong!!
  if Blinking then
    S := '  '
  else
    S := LeadZeroStr(Num, 2);
  Move(S[1], fNewDrawStr[39], 2);
end;

procedure TSkillPanelToolbar.SetLevel(const Value: TLevel);
begin
  fLevel := Value;
end;

procedure TSkillPanelToolbar.SetStyleAndGraph(const Value: TBaseDosLemmingStyle;
      aScale: Integer);
begin
  fImg.BeginUpdate;
  fStyle := Value;
  if fStyle <> nil then
  begin
    ReadBitmapFromStyle;
    ReadFont;
  end;
  fImg.Scale := aScale;
  fImg.ScaleMode := smScale;

  fImg.Height := fOriginal.Height * aScale;
  fImg.Width := fOriginal.Width * aScale;
  Width := fImg.Width;
  Height := fImg.Height;

  fImg.EndUpdate;
  fImg.Changed;
  Invalidate;
end;

procedure TSkillPanelToolbar.SetViewPort(const R: TRect);
begin
  fViewPortRect := R;
end;

procedure TSkillPanelToolbar.DrawMinimap(Map: TBitmap32);
var
  X, Y: Integer;
  Dx : Integer;
  SrcRect : TRect;
begin
  if not GameParams.ShowMinimap then Exit;

  fMinimapRegion.DrawTo(Img.Bitmap, 193, 16);

  Dx := 196;
  if Map.Width < 104 then Dx := Dx + (52 - (Map.Width div 2));
  SrcRect := Rect(0, 0, 104, 20);

  if Parent <> nil then
  begin
    X := -Round(TGameWindow(Parent).ScreenImg.OffsetHorz/(16 * fImg.Scale));
    Y := -Round(TGameWindow(Parent).ScreenImg.OffsetVert/(8 * fImg.Scale));
    if Game.GetLevelWidth < 1664 then X := X + 52 - (Game.GetLevelWidth div 32);
    if Map.Width > 104 then
    begin
      OffsetRect(SrcRect, Round((Map.Width - 104) * X / (Map.Width - 22)), 0);
      X := X - SrcRect.Left;
    end;
    OffsetRect(SrcRect, 0, Y);
    if SrcRect.Bottom > Map.Height then OffsetRect(SrcRect, 0, -1);
  end else
    X := 0;

  Map.DrawTo(Img.Bitmap, Dx, 18, SrcRect);
  Img.Bitmap.FrameRectS(196 + X, 18, 196 + X + 20, 38, fRectColor);
end;

procedure TSkillPanelToolbar.SetGame(const Value: TLemmingGame);
begin
  if fGame <> nil then
    fGame.InfoPainter := nil;
  fGame := Value;
  if fGame <> nil then
    fGame.InfoPainter := Self;
end;



procedure TSkillPanelToolbar.SetCurrentScreenOffset(X: Integer);
begin
  fCurrentScreenOffset := X;
end;

end.

