unit LemMenuFont;

interface

uses
  Types, UITypes,
  LemTypes, LemStrings,
  Dialogs, Controls, Forms,
  GR32,
  Classes, SysUtils;

const
  MENU_FONT_COUNT = ord(#132) - ord('!') + 1;
  MenuFontCharSet = [#26..#126] - [#32];

  CHARACTER_WIDTH = 16;
  CHARACTER_HEIGHT = 19;
  HALF_LINE_FEED = 10;
  TALISMAN_SIZE = 48;

type
  TMenuFont = class
    private
      function GetBitmapOfChar(Ch: Char): TBitmap32;
      procedure Combine(F: TColor32; var B: TColor32; M: TColor32);
      procedure MakeList(const S: string; aList: TStrings);
    public
      fBitmaps: array[0..MENU_FONT_COUNT - 1] of TBitmap32;

      constructor Create;
      destructor Destroy; override;

      procedure Load;

      procedure DrawText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
      procedure DrawTextCentered(Dst: TBitmap32; const S: string; Y: Integer; aRestoreBuffer: TBitmap32 = nil; EraseOnly: Boolean = false);
      function GetTextSize(const S: String): TRect;

      property BitmapOfChar[Ch: Char]: TBitmap32 read GetBitmapOfChar;
  end;

implementation

uses
  PngInterface,
  GameControl;

procedure TMenuFont.Combine(F: TColor32; var B: TColor32; M: TColor32);
// just show transparent
begin
  if F <> 0 then B := F;
end;

constructor TMenuFont.Create;
var
  i: Integer;
{-------------------------------------------------------------------------------
  The purple font has it's own internal pixelcombine.
  I don't think this ever has to be different.
-------------------------------------------------------------------------------}
begin
  inherited;
  for i := 0 to MENU_FONT_COUNT - 1 do
  begin
    fBitmaps[i] := TBitmap32.Create;
    fBitmaps[i].OnPixelCombine := Combine;
    fBitmaps[i].DrawMode := dmCustom;
  end;
end;

destructor TMenuFont.Destroy;
var
  i: Integer;
begin
  for i := 0 to MENU_FONT_COUNT - 1 do
    fBitmaps[i].Free;
  inherited;
end;

function TMenuFont.GetBitmapOfChar(Ch: Char): TBitmap32;
var
  Idx: Integer;
  ACh: AnsiChar;
begin
  ACh := AnsiChar(Ch);
  // Ignore any character not supported by the purple font
  //Assert((ACh in [#26..#126]) and (ACh <> ' '), 'Assertion failure on GetBitmapOfChar, character 0x' + IntToHex(Ord(ACh), 2));
  if (not (ACh in [#26..#126])) and (ACh <> ' ') then
    Idx := 0
  else if Ord(ACh) > 32 then
    Idx := Ord(ACh) - 33
  else
    Idx := 94 + Ord(ACh) - 26;
  Result := fBitmaps[Idx];
end;

function TMenuFont.GetTextSize(const S: string): TRect;
var
  C: Char;
  CX, i: Integer;
begin
  CX := 0;
  FillChar(Result, SizeOf(Result), 0);
  if S <> '' then
    Result.Bottom := CHARACTER_HEIGHT;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    case C of
      #12:
        begin
          Inc(Result.Bottom, HALF_LINE_FEED);
          CX := 0;
        end;
      #13:
        begin
          Inc(Result.Bottom, CHARACTER_HEIGHT);
          CX := 0;
        end;
      #26..#126:
        begin
          Inc(CX, CHARACTER_WIDTH);
          if CX > Result.Right then
            Result.Right := CX;
        end;
    end;
  end;
end;

procedure TMenuFont.DrawText(Dst: TBitmap32; const S: string; X, Y: Integer; aRestoreBuffer: TBitmap32 = nil);
var
  C: Char;
  CX, CY, i: Integer;
  R: TRect;
begin
  if aRestoreBuffer <> nil then
  begin
    R := GetTextSize(S);
    Types.OffsetRect(R, X, Y);
    Types.IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
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
          Inc(CY, HALF_LINE_FEED);
          CX := X;
        end;
      #13:
        begin
          Inc(CY, CHARACTER_HEIGHT);
          CX := X;
        end;
      ' ':
        begin
          Inc(CX, CHARACTER_WIDTH);
        end;
      #26..#31, #33..#132:
        begin
          BitmapOfChar[C].DrawTo(Dst, CX, CY);
          Inc(CX, CHARACTER_WIDTH);
        end;
    end;
  end;
end;

procedure TMenuFont.DrawTextCentered(Dst: TBitmap32; const S: string; Y: Integer; aRestoreBuffer: TBitmap32 = nil;
  EraseOnly: Boolean = False);
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
    R := GetTextSize(S);
    Types.OffsetRect(R, (Dst.Width - (R.Right - R.Left)) div 2, Y);
    Types.IntersectRect(R, R, aRestoreBuffer.BoundsRect); // oops, again watch out for sourceretangle!
    aRestoreBuffer.DrawTo(Dst, R, R);
  end;

  if not EraseOnly then
    for i := 0 to List.Count - 1 do
    begin
      H := List[i]; // <= 40 characters!!!
      X := (Dst.Width - CHARACTER_WIDTH * Length(H)) div 2;
      if (H <> #13) and (H <> #12) then
        DrawText(Dst, H, X, Y)
      else if H = #13 then
        Inc(Y, CHARACTER_HEIGHT)
      else
        Inc(Y, HALF_LINE_FEED);
    end;

  List.Free;
end;

procedure TMenuFont.MakeList(const S: string; aList: TStrings);
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
          Break;
        end;
      end;

    end;

    Inc(P);
    if P = #0 then Break;

  until False;
end;

procedure TMenuFont.Load;
var
  i: Integer;
  TempBMP: TBitmap32;
  buttonSelected: Integer;
begin
  TempBMP := TBitmap32.Create;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('menu_font.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('menu_font.png'), TempBMP)
  else if FileExists(AppPath + SFGraphicsMenu + 'menu_font.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'menu_font.png', TempBMP)
  else
  begin
    buttonSelected := MessageDlg('Could not find the menu font gfx\menu\menu_font.png. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  for i := 0 to MENU_FONT_COUNT-7 do
  begin
    fBitmaps[i].SetSize(CHARACTER_WIDTH, CHARACTER_HEIGHT);
    fBitmaps[i].Clear(0);
    TempBMP.DrawTo(fBitmaps[i], 0, 0, Rect(i*CHARACTER_WIDTH, 0, (i+1)*CHARACTER_WIDTH, CHARACTER_HEIGHT));
    fBitmaps[i].DrawMode := dmBlend;
    fBitmaps[i].CombineMode := cmMerge;
  end;

  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('talismans.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('talismans.png'), TempBMP)
  else if FileExists(AppPath + SFGraphicsMenu + 'talismans.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'talismans.png', TempBMP)
  else
  begin
    buttonSelected := MessageDlg('Could not find the talisman graphics gfx\menu\talismans.png. Try to continue?',
                                 mtWarning, mbOKCancel, 0);
    if buttonSelected = mrCancel then Application.Terminate();
  end;

  for i := 0 to 5 do
  begin
    fBitmaps[MENU_FONT_COUNT-6+i].SetSize(TALISMAN_SIZE, TALISMAN_SIZE);
    fBitmaps[MENU_FONT_COUNT-6+i].Clear(0);
    TempBMP.DrawTo(fBitmaps[MENU_FONT_COUNT-6+i], 0, 0, Rect(TALISMAN_SIZE * (i mod 2), TALISMAN_SIZE * (i div 2),
                                                             TALISMAN_SIZE * ((i mod 2) + 1), TALISMAN_SIZE * ((i div 2) + 1)));
    fBitmaps[MENU_FONT_COUNT-6+i].DrawMode := dmBlend;
    fBitmaps[MENU_FONT_COUNT-6+i].CombineMode := cmMerge;
  end;

  TempBMP.Free;
end;

end.
