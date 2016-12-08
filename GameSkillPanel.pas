{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  Classes, Controls, SysUtils,
  GR32, GR32_Image, GR32_Layers,
  { TODO : get rid of UMisc }
  UMisc, Math,
  LemmixHotkeys,
  LemDosMainDat,
  LemStrings,
  LemTypes,
  LemDosBmp,
  LemDosCmp,
  LemDosStructures,
  LemCore,
  LemLevel,
  LemDosStyle,
  LemNeoTheme,
  GameInterfaces,
  GameControl,
  LemRenderHelpers, //for PARTICLE_COLORS consts, not that i'm sure if it acutally needs them anymore
  LemGame,
  PngInterface,
  UZip; // For checking whether files actually exist

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
    //fButtonHighlightLayer: TPositionedLayer;
    //fMinimapHighlightLayer: TPositionedLayer;

    fOriginal      : TBitmap32;
    fLevel         : TLevel;
    fSkillFont     : array['0'..'9', 0..1] of TBitmap32;
    fSkillWhiteout : TBitmap32;
    fSkillUnwhite  : TBitmap32;
    fSkillLock     : TBitmap32;
    fSkillInfinite : TBitmap32;
    fSkillIcons    : array[0..15] of TBitmap32;
    fInfoFont      : array[0..44] of TBitmap32; {%} { 0..9} {A..Z} // make one of this!
    fGame          : TLemmingGame;
    { TODO : do something with this hardcoded shit }
    //fActiveButtons : array[0..7] of TSkillPanelButton;
    fButtonRects   : array[TSkillPanelButton] of TRect;
    fRectColor     : TColor32;

    fViewPortRect  : TRect;
    fOnMinimapClick            : TMinimapClickEvent; // event handler for minimap
    fCurrentScreenOffset : Integer;

    (*fCenterDigits: Boolean;*)

    fHighlitSkill: TSkillPanelButton;
    fSkillCounts: Array[0..20] of Integer; // includes "non-skill" buttons as error-protection, but also for the release rate




    procedure SetLevel(const Value: TLevel);

    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);

    procedure SetGame(const Value: TLemmingGame);

  protected
    //procedure Paint; override;
    procedure ReadBitmapFromStyle; virtual;
    procedure ReadFont;
    procedure SetButtonRects;

//    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    fLastDrawnStr: string[40];
    fNewDrawStr: string[40];
    RedrawnChars: Integer;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
//    procedure DrawInfo(aType: TInfoType; const S: string);
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

    procedure ActivateCenterDigits;
    procedure SetCurrentScreenOffset(X: Integer);
    property OnMinimapClick: TMinimapClickEvent read fOnMinimapClick write fOnMinimapClick;
  published
    procedure SetStyleAndGraph(const Value: TBaseDosLemmingStyle; aScale: Integer);

    property Level: TLevel read fLevel write SetLevel;
    property Game: TLemmingGame read fGame write SetGame;
    //property FirstSkill: TSkillPanelButton read fActiveButtons[0];

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
//  fBitmap := TBitmap.Create;
  fImg := TImage32.Create(Self);
  fImg.Parent := Self;
  fImg.RepaintMode := rmOptimizer;

  fImg.OnMouseDown := ImgMouseDown;
  fImg.OnMouseMove := ImgMouseMove;
  fImg.OnMouseUp := ImgMouseUp;

  fRectColor := DosVgaColorToColor32(DosInLevelPalette[3]);

{  fButtonHighlightLayer := TPositionedLayer.Create(Img.Layers);
  fButtonHighlightLayer.MouseEvents := False;
  fButtonHighlightLayer.Scaled := True;
  fButtonHighlightLayer.OnPaint := ButtonHighlightLayer_Paint; }

{  fMinimapHighlightLayer := TPositionedLayer.Create(Img.Layers);
  fMinimapHighlightLayer.MouseEvents := False;
  fMinimapHighlightLayer.Scaled := True;
  fMinimapHighlightLayer.OnPaint := MinimapHighlightLayer_Paint; }

  fOriginal := TBitmap32.Create;

  for i := 0 to 44 do
    fInfoFont[i] := TBitmap32.Create;

  for i := 0 to 15 do
    fSkillIcons[i] := TBitmap32.Create;

  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i] := TBitmap32.Create;

  fSkillInfinite := TBitmap32.Create;
  fSkillWhiteout := TBitmap32.Create;
  fSkillUnwhite := TBitmap32.Create;
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
//  windlg([length(fnewDrawStr)]);

  Assert(length(fnewdrawstr) = 40, 'length error infostring');

  (*fCenterDigits := false;*)

  fHighlitSkill := spbNone;


end;

destructor TSkillPanelToolbar.Destroy;
var
  c: Char;
  i: Integer;
begin


  for i := 0 to 43 do
    fInfoFont[i].Free;

//  fBitmap.Free;
  for c := '0' to '9' do
    for i := 0 to 1 do
      fSkillFont[c, i].Free;

  for i := 0 to 15 do
    fSkillIcons[i].Free;

  fSkillInfinite.Free;
  fSkillWhiteout.Free;
  fSkillUnwhite.Free;
  fSkillLock.Free;

  fOriginal.Free;
  inherited;
end;

procedure TSkillPanelToolbar.ClearSkills;
var
  i: Integer;
begin
   for i := 0 to 15 do // standard skills
   begin
     DrawButtonSelector(TSkillPanelButton(i), false);
     DrawSkillCount(TSkillPanelButton(i), fSkillCounts[i]);
   end;
   DrawSkillCount(spbFaster, fSkillCounts[Integer(spbFaster)]);
end;

procedure TSkillPanelToolbar.ActivateCenterDigits;
begin
  (*fCenterDigits := true;*)
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

  case Highlight of
    False :
      begin
        if fHighlitSkill = spbNone then Exit;
        R := fButtonRects[fHighlitSkill];
        fHighlitSkill := spbNone;
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

  //      fOriginal.DrawTo(fImg.Bitmap, R, R);
    //    fOriginal.DrawTo(fImg.Bitmap, R, R);
      end;
    True  :
      begin
        fHighlitSkill := aButton;
        R := fButtonRects[fHighlitSkill];
        Inc(R.Right);
        Inc(R.Bottom, 2);
        { TODO : do something with this palettes }
        C := fRectColor;

        fImg.Bitmap.FrameRectS(R, C);
//        C := clWhite32;
        //fImg.Bitmap.FrameRectS(fButtonRects[aButton], clWhite);
      end;
  end;
end;

procedure TSkillPanelToolbar.DrawNewStr;
var
  O, N: char;
  i, x, y, idx: integer;
//  LocalS: string;
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

{  case aType of
    itCursor: x := 0;
    itOut: x := 14 * 8;
    itIn : x := 23 * 8;
    itTime: x := 31 * 8
  end; }
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

  //    finfoforn[idx]

      if idx >= 0 then
        fInfoFont[idx].DrawTo(fimg.Bitmap, x, 0)
      else
        fimg.Bitmap.FillRectS(x, y, x + 8, y + 16, 0);
    end;

    Inc(x, 8);

  end;

  RedrawnChars := Changed;


//  fImg.Bitmap.
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
//  Font

begin
  // x = 3, 19, 35 etc. are the "black holes" for the numbers in the image
  // y = 17

  if (fButtonRects[aButton].Left < 0) then exit;

  fSkillCounts[Integer(aButton)] := aNumber;

  if Game.HyperSpeed then exit;

//  if aNumber < 0 then
  //  aNumber
  aoNumber := aNumber;
  aNumber := aNumber mod 100;
  Restrict(aNumber, 0, 100);
//  Assert(Between(aNumber, 0, 99), 'skillpanel number error 1');

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
  fSkillUnwhite.DrawTo(fImg.Bitmap, BtnIdx * 16 + 1, 16);
  if (aoNumber = 0) and (GameParams.BlackOutZero) then Exit;

  // Draw infinite symbol if, well, infinite.
  if (aoNumber > 99) then
  begin
    DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 8, 17 + 8);
    SrcRect := Rect(0, 0, 8, 8);
    fSkillInfinite.DrawTo(fImg.Bitmap, DstRect, SrcRect);
    Exit;
  end;

  // Clear the area for numbers (to undo whiteouts / allow centering)
  // Best way to do this is just copy from original
  //fSkillIcons[Ord(aButton)].DrawTo(fImg.Bitmap, fButtonRects[aButton]);
  {DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 9, 17 + 8);
  c:=Color32(0, 0, 0);
  with DstRect do
    fImg.Bitmap.FillRect(Left, Top, Right, Bottom, c);}

  // left
  DstRect := Rect(BtnIdx * 16 + 4, 17, BtnIdx * 16 + 4 + 4, 17 + 8);
  SrcRect := Rect(0, 0, 4, 8);
  if (*(not fCenterDigits) or*) (aoNumber >= 10) then fSkillFont[L, 1].DrawTo(fImg.Bitmap, DstRect, SrcRect); // 1 is left

  // right
  RectMove(DstRect, 2, 0);
  if (*(fCenterDigits = false) or*) (aoNumber >= 10) then RectMove(DstRect, 2, 0);
  SrcRect := Rect(4, 0, 8, 8);
  fSkillFont[R, 0].DrawTo(fImg.Bitmap, DstRect, SrcRect); // 0 is right

//  with
//  fimg.Bitmap.FillRect(0, 0, 20, 20, clwhite32);
//  fSkillFont[R, 1].DrawTo(fImg.Bitmap, BtnIdx * 16 + 3, 17)
end;

procedure TSkillPanelToolbar.RefreshInfo;
begin
  DrawNewStr;
  fLastDrawnStr := fNewDrawStr;// := fLastDrawnStr;
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
  q: Integer;
  Exec: Boolean;
begin
//  Exec := False;
  P := Img.ControlToBitmap(Point(X, Y));
  TGameWindow(Parent).ApplyMouseTrap;

  // check minimap scroll
  if PtInRectEx(DosMiniMapCorners, P) then
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

    //Game.MiniMapClick(P);
    Exit;
  end;

  if Game.HyperSpeed {or Game.FastForward} then
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
      //if Exec then
        if i = spbNuke then
          Exec := ssDouble in Shift;

      if Exec then
      begin
        if i in [spbNuke] then
          Game.RegainControl;
          
        if i in [spbSlower, spbFaster] then
          Game.SetSelectedSkill(i, True, (Button = mbRight))
        else
          Game.SetSelectedSkill(i, True, GameParams.Hotkeys.CheckForKey(lka_Highlight));
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

    if PtInRectEx(DosMiniMapCorners, P) then
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
      //Game.MiniMapClick(P);
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
  TempBmp: TBitmap32;
  SrcRect: TRect;
const
  SKILL_NAMES: array[0..15] of string = (
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
                 'miner',
                 'digger',
                 'cloner'
               );  

  procedure MakeWhiteoutImage;
  var
    x, y: Integer;
  begin
    fSkillWhiteout.SetSize(16, 23);
    fSkillWhiteout.Clear(0);
    fSkillWhiteout.BeginUpdate;
    for x := 3 to 11 do
      for y := 1 to 8 do
        fSkillWhiteout[x, y] := $FFF0D0D0;
    fSkillWhiteout.EndUpdate;
  end;

  procedure MakeUnwhiteImage;
  var
    x, y: Integer;
  begin
    fSkillUnwhite.SetSize(16, 23);
    fSkillUnwhite.Clear(0);
    fSkillUnwhite.BeginUpdate;
    for x := 0 to 15 do
      for y := 0 to 22 do
        if (fSkillWhiteout[x, y] and $FF000000) <> 0 then fSkillUnwhite[x, y] := $FF000000;
    fSkillWhiteout.EndUpdate;
  end;

  procedure GetGraphic(aName: String; aDst: TBitmap32);
  begin
    aName := AppPath + SFGraphicsPanel + aName;
    TPngInterface.LoadPngFile(aName, aDst);
    TPngInterface.MaskImageFromFile(aDst, ChangeFileExt(aName, '_mask.png'), LemmixPal[7]);
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


    TempBmp := TBitmap32.Create;
    TempBmp.DrawMode := dmBlend;

    // Panel graphic
    GetGraphic('skill_panel.png', fOriginal);
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
    GetGraphic('skill_icons.png', TempBmp);
    SrcRect := Rect(0, 0, 16, 23);
    for i := 0 to 15 do
    begin
      fSkillIcons[i].SetSize(16, 23);
      fSkillIcons[i].Clear;
      TempBmp.DrawTo(fSkillIcons[i], 0, 0, SrcRect);
      SrcRect.Right := SrcRect.Right + 16;
      SrcRect.Left := SrcRect.Left + 16;

      if SrcRect.Left >= TempBmp.Width then
        SrcRect := Rect(0, 0, 16, 23);
    end;

    for i := 0 to 15 do
    begin
      GetGraphic('icon_' + SKILL_NAMES[i] + '.png', TempBmp);
      TempBmp.DrawTo(fSkillIcons[i]);
    end;

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

    GetGraphic('skill_count_erase.png', fSkillWhiteout);

    fSkillInfinite.DrawMode := dmBlend;
    fSkillInfinite.CombineMode := cmMerge;
    fSkillWhiteout.DrawMode := dmBlend;
    fSkillWhiteout.CombineMode := cmMerge;
    fSkillLock.DrawMode := dmBlend;
    fSkillLock.CombineMode := cmMerge;

    fSkillUnwhite.Assign(fSkillWhiteout);

    TempBmp.Free;

  fSkillUnwhite.DrawMode := dmBlend;
  fSkillUnwhite.CombineMode := cmMerge;


end;

procedure TSkillPanelToolbar.ReadFont;
begin

end;

procedure TSkillPanelToolbar.SetSkillIcons;
var
  Org, R, SrcRect: TRect;
  x : Integer;
begin
  Org := Rect(33, 16, 47, 38); // exact position of first button
  R := Org;
  for x := 0 to 15 do
  begin
    if Level.Info.SkillTypes and Trunc(IntPower(2, (15-x))) <> 0 then
    begin
      //fActiveButtons[i] := TSkillPanelButton(x);
      //Game.fActiveSkills[i] := TSkillPanelButton(x);
      fButtonRects[TSkillPanelButton(x)] := R;

      SrcRect := Rect(0, 0, 14, 22);
      fSkillIcons[x].DrawTo(fImg.Bitmap, R.Left, R.Top{, SrcRect});
      fSkillIcons[x].DrawTo(fOriginal, R.Left, R.Top{, SrcRect});

      RectMove(R, 16, 0);
    end;
  end;
end;

procedure TSkillPanelToolbar.SetButtonRects;
var
  Org, R: TRect;
  iButton: TSkillPanelButton;
//  Sca: Integer;

//    function ScaleRect(const ):

begin
//  Sca := 3;
  Org := Rect(-1, -1, 0, 0); // exact position of first button
  R := Org;
  {R.Left := R.Left * Sca;
  R.Right := R.Right * Sca;
  R.Top := R.Top * Sca;
  R.Bottom := R.Bottom * Sca; }

  for iButton := Low(TSkillPanelButton) to High(TSkillPanelButton) do
  begin
    fButtonRects[iButton] := R;
    //RectMove(R, 16, 0);
    
  end;

  fButtonRects[spbSlower] := Rect(1, 16, 15, 38);
  fButtonRects[spbFaster] := Rect(17, 16, 31, 38);
  fButtonRects[spbPause]  := Rect(161, 16, 175, 38);
  fButtonRects[spbNuke]   := Rect(177, 16, 191, 38);


end;

procedure TSkillPanelToolbar.SetButtonRect(btn: TSkillPanelButton; bpos: Integer);
var
  R: TRect;
begin
  R := Rect(1, 16, 15, 38);
  RectMove(R, 16 * (bpos - 1), 0);
  fButtonRects[btn] := R;
end;

procedure TSkillPanelToolbar.SetInfoCursorLemming(const Lem: string; Num: Integer);
var
  S: string;
begin
//exit;

  S := Uppercase(Lem);
  if Lem <> '' then
  begin

    if Num = 0 then
      S := PadR(S, 14)
    else
      S := PadR(S + ' ' + i2s(Num), 14); //
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
  S := i2s(Num);
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
  S := i2s(Num);
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
  S := i2s(Num);
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
    S := PadL(i2s(Num), 2);
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
//  Width := fBitmap.Width;
//  Height := fBitmap.Height;
  fImg.Scale := aScale;
  fImg.ScaleMode := smScale;
  //fImg.AutoSize := True;

  fImg.Height := fOriginal.Height * aScale;
  fImg.Width := fOriginal.Width * aScale;
  Width := fImg.Width;
  Height := fImg.Height;

//  AutoSize := True;
//  fImg.Width * fImg.Bitmap.Width

//  DrawNumber(bskClimber, 23);
//  DrawInfo('1234567890123456789012345678901234567890');


  fImg.EndUpdate;
  fImg.Changed;
  Invalidate;
end;

procedure TSkillPanelToolbar.SetViewPort(const R: TRect);
begin
  fViewPortRect := R;
//  fMinimapHighlightLayer.Changed;

end;

procedure TSkillPanelToolbar.DrawMinimap(Map: TBitmap32);
var
  X, Y: Integer;
  Dx : Integer;
  SrcRect : TRect;
begin
  Dx := 208;
  if Map.Width < 104 then Dx := Dx + (52 - (Map.Width div 2));
  SrcRect := Rect(0, 0, 104, 20);

  if Parent <> nil then
  begin
    X := -Round(TGameWindow(Parent).ScreenImg.OffsetHorz/(16 * fImg.Scale));
    Y := -Round(TGameWindow(Parent).ScreenImg.OffsetVert/(8 * fImg.Scale));
    if Game.GetLevelWidth < 1664 then X := X + 52 - (Game.GetLevelWidth div 32);
    if Map.Width > 104 then
    begin
      RectMove(SrcRect, Round((Map.Width - 104) * X / (Map.Width - 22)), 0);
      X := X - SrcRect.Left;
    end;
    RectMove(SrcRect, 0, Y);
    if SrcRect.Bottom > Map.Height then RectMove(SrcRect, 0, -1);
  end else
    X := 0;
  Map.DrawTo(Img.Bitmap, Dx, 18, SrcRect);
  Img.Bitmap.FrameRectS(208 + X, 18, 208 + X + 20, 38, fRectColor);
end;

procedure TSkillPanelToolbar.SetGame(const Value: TLemmingGame);
begin
  if fGame <> nil then
    fGame.InfoPainter := nil;
  fGame := Value;
  if fGame <> nil then
    fGame.InfoPainter := Self;

//  else
  //  fGame.InfoPainter := nil;  
end;



procedure TSkillPanelToolbar.SetCurrentScreenOffset(X: Integer);
begin
  fCurrentScreenOffset := X;
end;

end.

