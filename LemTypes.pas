{$include lem_directives.inc}
unit LemTypes;

interface

uses
  UMisc,
  LemNeoOnline,
  Dialogs,
  SharedGlobals,
  Classes, SysUtils, Contnrs,
  GR32, GR32_LowLevel,
  Windows;

const
  MUSIC_EXT_COUNT = 12;
  MUSIC_EXTENSIONS: array[0..MUSIC_EXT_COUNT-1] of string = (
                    '.ogg',
                    '.wav',
                    '.aiff',
                    '.aif',
                    '.mp3',
                    '.mo3',
                    '.it',
                    '.mod',
                    '.xm',
                    '.s3m',
                    '.mtm',
                    '.umx');

type
  TLemDataType = (
    ldtNone,
    ldtLemmings,  // NXP or resource
    ldtSound,     // in a resource
    ldtMusic,     // NXP, music packs, resource... there are a few places this looks
    ldtParticles, // is in a resource
    ldtText,      // NXP
    ldtStyle      // NXP, resource, 'styles' directory
  );

type
  TArrayArrayInt = array of array of Integer;
  TArrayArrayBoolean = array of array of Boolean;

  TBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmap32;
  protected
  public
    function Add(Item: TBitmap32): Integer;
    procedure Insert(Index: Integer; Item: TBitmap32);
    procedure Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
    property Items[Index: Integer]: TBitmap32 read GetItem; default;
    property List;
  published
  end;

  // lemlowlevel
procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; Margins: TRect; Src: TBitmap32);
function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
function AppPath: string;
function MakeSuitableForFilename(const aInput: String): String;
function LemmingsPath: string;
function MusicsPath: string;
procedure MoveRect(var aRect: TRect; const DeltaX, DeltaY: Integer);

function UnderWine: Boolean;
function MakeSafeForFilename(const aString: String; DisallowSpaces: Boolean = true): String;

implementation

var
  _AppPath: string;
  _UnderWine: Integer;

function AppPath: string;
begin
  if _AppPath = '' then
    _AppPath := ExtractFilePath(ParamStr(0));
  Result := _AppPath;
end;

function MakeSafeForFilename(const aString: String; DisallowSpaces: Boolean = true): String;
var
  i, i2: Integer;
const
  FORBIDDEN_CHARS = '<>:"/\|?* ';
begin
  Result := aString;
  for i := 1 to Length(aString) do
  begin
    if (not DisallowSpaces) and (Result[i] = ' ') then
      Continue;
    for i2 := 1 to Length(FORBIDDEN_CHARS) do
      if Result[i] = FORBIDDEN_CHARS[i2] then
        Result[i] := '_';
  end;
  if Length(Result) = 0 then
    Result := '_';
end;

function UnderWine: Boolean;
var
  H: cardinal;
begin
  Result := false;

  if _UnderWine = 2 then Result := true;
  if _UnderWine > 0 then Exit;

  H := LoadLibrary('ntdll.dll');
  if H > HINSTANCE_ERROR then
    begin
      Result := Assigned(GetProcAddress(H, 'wine_get_version'));
      FreeLibrary(H);
    end;

  if Result then
    _UnderWine := 2
  else
    _UnderWine := 1;
end;

procedure MoveRect(var aRect: TRect; const DeltaX, DeltaY: Integer);
begin
  aRect.Right := aRect.Right + DeltaX;
  aRect.Left := aRect.Left + DeltaX;
  aRect.Bottom := aRect.Bottom + DeltaY;
  aRect.Top := aRect.Top + DeltaY;
end;

function MakeSuitableForFilename(const aInput: String): String;
const
  FORBIDDEN_CHARS = '<>:"/\|?*';
  REPLACEMENT_CHAR = '_';
var
  i: Integer;
  CharPos: Integer;
begin
  Result := aInput;
  for i := 1 to Length(FORBIDDEN_CHARS) do
  begin
    CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    while CharPos <> 0 do
    begin
      Result[CharPos] := REPLACEMENT_CHAR;
      CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    end;
  end;
end;

function LemmingsPath: string;
begin
    Result := AppPath;
end;

function MusicsPath: string;
begin
    Result := AppPath;
end;

procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
var
  P: PColor32;
  i: Integer;
begin
  P := B.PixelPtr[0, 0];
  for i := 0 to B.Height * B.Width - 1 do
    begin
      if P^ = FromColor then
        P^ := ToColor;
      Inc(P);
    end;
end;

procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; Margins: TRect; Src: TBitmap32);
type
  TNineSliceRects = array[0..8] of TRect;
var
  SrcRects, DstRects: TNineSliceRects;
  i: Integer;

  function MakeNineSliceRects(aInput: TRect): TNineSliceRects;
  var
    VarWidth, VarHeight: Integer; // stores the non-margin width and height
    i: Integer;
  begin
    VarWidth := aInput.Width - (Margins.Left + Margins.Right);
    VarHeight := aInput.Height - (Margins.Top + Margins.Bottom);

    Result[0] := SizedRect(0, 0, Margins.Left, Margins.Top);
    Result[1] := SizedRect(Margins.Left, 0, VarWidth, Margins.Top);
    Result[2] := SizedRect(Margins.Left + VarWidth, 0, Margins.Right, Margins.Top);

    Result[3] := SizedRect(0, Margins.Top, Margins.Left, VarHeight);
    Result[4] := SizedRect(Margins.Left, Margins.Top, VarWidth, VarHeight);
    Result[5] := SizedRect(Margins.Left + VarWidth, Margins.Top, Margins.Right, VarHeight);

    Result[6] := SizedRect(0, Margins.Top + VarHeight, Margins.Left, Margins.Bottom);
    Result[7] := SizedRect(Margins.Left, Margins.Top + VarHeight, VarWidth, Margins.Bottom);
    Result[8] := SizedRect(Margins.Left + VarWidth, Margins.Top + VarHeight, Margins.Right, Margins.Bottom);

    for i := 0 to 8 do
      Result[i].Offset(aInput.Left, aInput.Top);
  end;

  procedure DrawTiled(TotalSrcRect, TotalDstRect: TRect);
  var
    CountX, CountY: Integer;
    iX, iY: Integer;
    SrcRect, DstRect: TRect;
  begin
    if (TotalSrcRect.Width <= 0) or (TotalSrcRect.Height <= 0) or
       (TotalDstRect.Width <= 0) or (TotalDstRect.Height <= 0) then
      Exit;

    CountX := (TotalDstRect.Width - 1) div TotalSrcRect.Width;
    CountY := (TotalDstRect.Height - 1) div TotalSrcRect.Height;

    for iY := 0 to CountY do
    begin
      SrcRect := TotalSrcRect;
      DstRect := SizedRect(TotalDstRect.Left, TotalDstRect.Top + (iY * TotalSrcRect.Height), TotalSrcRect.Width, TotalSrcRect.Height);

      if iY = CountY then
      begin
        DstRect := SizedRect(DstRect.Left, DstRect.Top, DstRect.Width, ((TotalDstRect.Height - 1) mod TotalSrcRect.Height) + 1);
        SrcRect := SizedRect(SrcRect.Left, SrcRect.Top, DstRect.Width, DstRect.Height);
      end;

      for iX := 0 to CountX do
      begin
        if iX = CountX then
        begin
          DstRect := SizedRect(DstRect.Left, DstRect.Top, ((TotalDstRect.Width - 1) mod TotalSrcRect.Width) + 1, DstRect.Height);
          SrcRect := SizedRect(SrcRect.Left, SrcRect.Top, DstRect.Width, DstRect.Height);
        end;

        Src.DrawTo(Dst, DstRect, SrcRect);

        DstRect.Offset(TotalSrcRect.Width, 0);
      end;
    end;
  end;

begin
  if (DstRect.Width = SrcRect.Width) and (DstRect.Height = SrcRect.Height) then
    Src.DrawTo(Dst, DstRect.Left, DstRect.Top) // save processing time
  else begin
    SrcRects := MakeNineSliceRects(SrcRect);
    DstRects := MakeNineSliceRects(DstRect);

    for i := 0 to 8 do
      DrawTiled(SrcRects[i], DstRects[i]);
  end;
end;

function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
var
  Y, H, W: Integer;
begin
  W := Bmp.Width;
  H := Bmp.Height div FrameCount;
  Y := H * FrameIndex;

  Result.Left := 0;
  Result.Top := Y;
  Result.Right := W;
  Result.Bottom := Y + H;
end;

{ TBitmaps }

function TBitmaps.Add(Item: TBitmap32): Integer;
begin
  Result := inherited Add(Item);
end;

function TBitmaps.GetItem(Index: Integer): TBitmap32;
begin
  Result := inherited Get(Index);
end;

procedure TBitmaps.Insert(Index: Integer; Item: TBitmap32);
begin
  inherited Insert(Index, Item);
end;

procedure TBitmaps.Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
var
  BMP: TBitmap32;
  i: Integer;
  w, h: Integer;
  sx, sy: Integer;
begin
  Clear;

  if (Src.Width = 0) or (Src.Height = 0) or (Frames = 0) then
    Exit;

  w := Src.Width;
  h := Src.Height div Frames;
  sx := 0;
  sy := 0;
  for i := 0 to Frames-1 do
  begin
    BMP := TBitmap32.Create;
    Add(BMP);
    BMP.SetSize(w, h);
    BMP.Clear(0);
    Src.DrawTo(BMP, Rect(0, 0, w, h), Rect(sx, sy, sx+w, sy+h));
    if Horizontal then
      Inc(sx, w)
    else
      Inc(sy, h);
  end;
end;


end.

