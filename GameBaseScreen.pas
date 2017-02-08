{$include lem_directives.inc}
unit GameBaseScreen;

interface

uses
  Windows, Messages, Classes, Controls, Graphics, MMSystem, Forms, Dialogs,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  FBaseDosForm,
  GameControl,
  LemDosStructures,
  LemDosMainDat,
  LemSystemMessages,
  LemStrings, PngInterface, LemTypes;

const
  PURPLEFONTCOUNT = ord(#132) - ord('!') + 1;
  PurpleFontCharSet = ['!'..#132];

type
  TPurpleFont = class(TComponent)
  private
    function GetBitmapOfChar(Ch: Char): TBitmap32;
    procedure Combine(F: TColor32; var B: TColor32; M: TColor32);
  protected
  public
    fBitmaps: array[0..PURPLEFONTCOUNT - 1] of TBitmap32;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property BitmapOfChar[Ch: Char]: TBitmap32 read GetBitmapOfChar;
  published
  end;

type
  {-------------------------------------------------------------------------------
    This is the ancestor for all dos forms that are used in the program.
  -------------------------------------------------------------------------------}
  TGameBaseScreen = class(TBaseDosForm)
  private
    fMainDatExtractor    : TMainDatExtractor;
    fScreenImg           : TImage32;
    fBackGround          : TBitmap32;
    fBackBuffer          : TBitmap32; // general purpose buffer
    fPurpleFont          : TPurpleFont;
    fOriginalImageBounds : TRect;
    fScreenIsClosing     : Boolean;
    fCloseDelay          : Integer;
    procedure AdjustImage;
    procedure MakeList(const S: string; aList: TStrings);
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure PrepareGameParams; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property PurpleFont: TPurpleFont read fPurpleFont;
    property MainDatExtractor: TMainDatExtractor read fMainDatExtractor;
    property ScreenIsClosing: Boolean read fScreenIsClosing;
    property CloseDelay: Integer read fCloseDelay write fCloseDelay;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
    procedure ExtractBackGround;
    procedure ExtractPurpleFont;
    procedure DrawPurpleText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
    procedure DrawPurpleTextCentered(Dst: TBitmap32; const S: string;
      Y: Integer; aRestoreBuffer: TBitmap32 = nil; EraseOnly: Boolean = False);
    function CalcPurpleTextSize(const S: string): TRect;
    procedure FadeOut;
    procedure InitializeImageSizeAndPosition(aWidth, aHeight: Integer);

    procedure MainFormResized; virtual;

    property ScreenImg: TImage32 read fScreenImg;
    property BackGround: TBitmap32 read fBackGround;
    property BackBuffer: TBitmap32 read fBackBuffer;
  end;

implementation

{ TPurpleFont }

procedure TPurpleFont.Combine(F: TColor32; var B: TColor32; M: TColor32);
// just show transparent
begin
  if F <> 0 then B := F;
end;

constructor TPurpleFont.Create(aOwner: TComponent);
var
  i: Integer;
{-------------------------------------------------------------------------------
  The purple font has it's own internal pixelcombine.
  I don't think this ever has to be different.
-------------------------------------------------------------------------------}
begin
  inherited;
  for i := 0 to PURPLEFONTCOUNT - 1 do
  begin
    fBitmaps[i] := TBitmap32.Create;
    fBitmaps[i].OnPixelCombine := Combine;
    fBitmaps[i].DrawMode := dmCustom;
  end;
end;

destructor TPurpleFont.Destroy;
var
  i: Integer;
begin
  for i := 0 to PURPLEFONTCOUNT - 1 do
    fBitmaps[i].Free;
  inherited;
end;

function TPurpleFont.GetBitmapOfChar(Ch: Char): TBitmap32;
var
  Idx: Integer;
begin
  Assert(Ch in ['!'..#132]);
  Idx := Ord(Ch) - ord('!');
  Result := fBitmaps[Idx];
end;

{ TGameBaseScreen }

procedure TGameBaseScreen.CNKeyDown(var Message: TWMKeyDown);
var
  AssignedEventHandler: TKeyEvent;
begin
  AssignedEventHandler := OnKeyDown;
  if Message.CharCode = vk_tab then
    if Assigned(AssignedEventHandler) then
      OnKeyDown(Self, Message.CharCode, KeyDataToShiftState(Message.KeyData));
  inherited;
end;

procedure TGameBaseScreen.AdjustImage;
begin
  fScreenImg.Align := alClient;
  //if IsGameplayScreen then
    fScreenImg.ScaleMode := smResize;
  //else
  //  fScreenImg.ScaleMode := smStretch;
  fScreenImg.BitmapAlign := baCenter;

  Update;
  Changed;
end;

procedure TGameBaseScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  Self.OnKeyDown := nil;
  Self.OnKeyPress := nil;
  Self.OnClick := nil;
  Application.OnIdle := nil;
  fScreenIsClosing := True;
  if fCloseDelay > 0 then
  begin
    Update;
    Sleep(fCloseDelay);
  end;

  FadeOut;

  if GameParams <> nil then
  begin
    GameParams.NextScreen := aNextScreen;
    GameParams.MainForm.Cursor := crNone;
  end;

  Close;

  SendMessage(MainFormHandle, LM_NEXT, 0, 0);
end;

constructor TGameBaseScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fScreenImg := TImage32.Create(Self);
  fScreenImg.Parent := Self;

  fPurpleFont := TPurpleFont.Create(nil);

  fBackGround := TBitmap32.Create;
  fBackBuffer := TBitmap32.Create;
  fMainDatExtractor := TMainDatExtractor.Create;

  ScreenImg.Cursor := crNone;
end;

destructor TGameBaseScreen.Destroy;
begin
  fBackGround.Free;
  fMainDatExtractor.Free;
  fPurpleFont.Free;
  fBackBuffer.Free;
  inherited Destroy;
end;

function TGameBaseScreen.CalcPurpleTextSize(const S: string): TRect;
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  C: Char;
  CX, i: Integer;
begin
  CX := 0;
  FillChar(Result, SizeOf(Result), 0);
  if S <> '' then
    Result.Bottom := 16;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    case C of
      #12:
        begin
          Inc(Result.Bottom, 8);
          CX := 0;
        end;
      #13:
        begin
          Inc(Result.Bottom, 16);
          CX := 0;
        end;
      '!'..#132, ' ':
        begin
          Inc(CX, 16);
          if CX > Result.Right then
            Result.Right := CX;
        end;
    end;
  end;
end;

procedure TGameBaseScreen.DrawPurpleText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  C: Char;
  CX, CY, i: Integer;
  R: TRect;
begin
  Y := Y + 1; // accounts for moving graphic up by 1 pixel

  if aRestoreBuffer <> nil then
  begin
    R := CalcPurpleTextSize(S);
    OffsetRect(R, X, Y);
    IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
    aRestoreBuffer.DrawTo(Dst, R, R);
  end;

  CX := X;
  CY := Y;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    case C of
      #12:
        begin
          Inc(CY, 8);
          CX := X;
        end;
      #13:
        begin
          Inc(CY, 16);
          CX := X;
        end;
      ' ':
        begin
          Inc(CX, 16);
        end;
      '!'..#132:
        begin
          fPurpleFont.BitmapOfChar[C].DrawTo(Dst, CX, CY);
          Inc(CX, 16);
        end;
    end;
  end;

end;

procedure TGameBaseScreen.DrawPurpleTextCentered(Dst: TBitmap32; const S: string; Y: Integer; aRestoreBuffer: TBitmap32 = nil;
  EraseOnly: Boolean = False);
{-------------------------------------------------------------------------------
  Linefeeds increment 16 pixels
  Spaces increment 16 pixels
-------------------------------------------------------------------------------}
var
  X, i: Integer;
  R: TRect;
  List: TStringList;
  H: string;

begin

  List := TStringList.Create;
  MakeList(S, List);


  if aRestoreBuffer <> nil then
  begin
    R := CalcPurpleTextSize(S);
    OffsetRect(R, (Dst.Width - (R.Right - R.Left)) div 2, Y);
    IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
    aRestoreBuffer.DrawTo(Dst, R, R);
  end;

  if not EraseOnly then
  for i := 0 to List.Count - 1 do
  begin
    H := List[i]; // <= 40 characters!!!
    X := (Dst.Width - 16 * Length(H)) div 2;
    if (H <> #13) and (H <> #12) then
      DrawPurpleText(Dst, H, X, Y)
    else if H = #13 then
      Inc(Y, 16)
    else
      Inc(Y, 8);
  end;

  List.Free;
end;

procedure TGameBaseScreen.ExtractBackGround;
begin
  fMainDatExtractor.ExtractBrownBackGround(fBackGround);
end;

procedure TGameBaseScreen.ExtractPurpleFont;
var
  Pal: TArrayOfColor32;
  i: Integer;
  TempBMP: TBitmap32;
begin
  Pal := GetDosMainMenuPaletteColors32;
  with MainDatExtractor do
  begin
    TempBMP := TBitmap32.Create;

    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'menu_font.png', TempBMP);
    for i := 0 to PURPLEFONTCOUNT-7 do
    begin
      fPurpleFont.fBitmaps[i].SetSize(16, 16);
      fPurpleFont.fBitmaps[i].Clear(0);
      TempBMP.DrawTo(fPurpleFont.fBitmaps[i], 0, 0, Rect(i*16, 0, (i+1)*16, 16));
      fPurpleFont.fBitmaps[i].DrawMode := dmBlend;
      fPurpleFont.fBitmaps[i].CombineMode := cmMerge;
    end;

    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'talismans.png', TempBMP);
    for i := 0 to 5 do
    begin
      fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].SetSize(48, 48);
      fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].Clear(0);
      TempBMP.DrawTo(fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i], 0, 0, Rect(48 * (i mod 2), 48 * (i div 2), 48 * ((i mod 2) + 1), 48 * ((i div 2) + 1)));
      fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].DrawMode := dmBlend;
      fPurpleFont.fBitmaps[PURPLEFONTCOUNT-6+i].CombineMode := cmMerge;
    end;

    TempBMP.Free;
  end;
end;

procedure TGameBaseScreen.InitializeImageSizeAndPosition(aWidth, aHeight: Integer);
begin
  with fScreenImg do
  begin
    Bitmap.SetSize(aWidth, aHeight);

    with fOriginalImageBounds do
    begin
      {Left := (Screen.Width - aWidth) div 2;
      Top := (Screen.Height - aHeight) div 2;
      Right := Left + aWidth;
      Bottom := Top + aHeight;}
      Left := 0;
      Height := 0;
      Right := ClientWidth;
      Bottom := ClientHeight;
    end;

    BoundsRect := fOriginalImageBounds;

    AdjustImage;

    if GameParams.LinearResampleMenu and not IsGameplayScreen then
      TLinearResampler.Create(fScreenImg.Bitmap);
  end;
end;

procedure TGameBaseScreen.PrepareGameParams;
begin
  inherited;
  fMainDatExtractor.FileName := GameParams.MainDatFile;
end;

procedure TGameBaseScreen.TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
var
  aX, aY: Integer;
begin

  Assert(fBackground.Width > 0);
  Assert(fBackground.Height > 0);

  if Dst = nil then
    Dst := fScreenImg.Bitmap;

  aY := Y;
  aX := X;
  while aY <= Dst.Height do
  begin
    while aX <= Dst.Width do
    begin
      fBackground.DrawTo(Dst, aX, aY);
      Inc(aX, fBackground.Width);
    end;
    Inc(aY, fBackground.Height);
    aX := X;
  end;

end;


procedure TGameBaseScreen.MakeList(const S: string; aList: TStrings);
var
  StartP, P: PChar;
  NewS: string;
begin
  StartP := PChar(S);
  P := StartP;
  repeat
    case P^ of
    #12, #13 :
      begin
        if P >= StartP then
        begin
          SetString(NewS, StartP, P - StartP);
          aList.Add(NewS);

          while (P^ = #12) or (P^ = #13) do
          begin
            aList.Add(P^);
            Inc(P);
          end;
          if P^ = #0 then Break;

          StartP := P;
        end;

      end;

    #0:
      begin
        if P >= StartP then
        begin
          SetString(NewS, StartP, P - StartP);
          aList.Add(NewS);
          break;
        end;
      end;

    end;

    Inc(P);
    if P = #0 then Break;

  until False;
end;

procedure TGameBaseScreen.FadeOut;
var
  Steps: Integer; i: Integer;
  P: PColor32;
  StepStartTickCount: Cardinal;
begin
  Steps := 16;
  while Steps > 0 do
  begin
    with ScreenImg.Bitmap do
    begin
      P := PixelPtr[0, 0];
      for i := 0 to Width * Height - 1 do
      begin
        with TColor32Entry(P^) do
        begin
          if R > 8 then Dec(R, 8) else R := 0;
          if G > 8 then Dec(G, 8) else G := 0;
          if B > 8 then Dec(B, 8) else B := 0;
        end;
        Inc(P);
      end;
      StepStartTickCount := GetTickCount;
      Changed;
      Update;
      repeat
      until GetTickCount - StepStartTickCount >= 3; // changed Sleep(3) to this so that if Update takes a while, there isn't further delay on top of that
    end;

    Dec(Steps);
  end;

  Application.ProcessMessages;
end;

procedure TGameBaseScreen.MainFormResized;
begin
  // basic procedure. Special handling needed for in-game screen, hence why this procedure can be overridden.
  fScreenImg.Width := GameParams.MainForm.ClientWidth;
  fScreenImg.Height := GameParams.MainForm.ClientHeight;
  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;
end;


end.

