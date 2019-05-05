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
procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; SrcCenterRect: TRect; Src: TBitmap32);
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

procedure DrawNineSlice(Dst: TBitmap32; DstRect: TRect; SrcRect: TRect; SrcCenterRect: TRect; Src: TBitmap32);
var
  VariableWidth, VariableHeight: Integer;

  procedure DrawTiled(TotalSrcRect, TotalDstRect: TRect);
    var
      CountX, CountY: Integer;
      iX, iY: Integer;
      SrcRect, DstRect: TRect;
    begin
      CountX := (TotalDstRect.Width - 1) div TotalSrcRect.Width;
      CountY := (TotalDstRect.Height - 1) div TotalSrcRect.Height;

      for iY := 0 to CountY do
      begin
        SrcRect := TotalSrcRect;
        DstRect := SizedRect(TotalDstRect.Left, TotalDstRect.Top + (iY * TotalSrcRect.Height), TotalSrcRect.Width, TotalSrcRect.Height);

        if iY = CountY then
          DstRect := SizedRect(DstRect.Left, DstRect.Top, DstRect.Width, ((TotalDstRect.Height - 1) mod TotalSrcRect.Height) + 1);

        for iX := 0 to CountX do
        begin
          if iX = CountX then
            DstRect := SizedRect(DstRect.Left, DstRect.Top, ((TotalDstRect.Width - 1) mod TotalSrcRect.Width) + 1, DstRect.Height);

          Src.DrawTo(Dst, DstRect, SrcRect);

          DstRect.Offset(TotalSrcRect.Width, 0);
        end;
      end;
    end;

begin

    if (DstRect.Width = SrcRect.Width) and (DstRect.Height = SrcRect.Height) then
      Src.DrawTo(Dst, DstRect.Left, DstRect.Top)
    else begin
      VariableWidth := DstRect.Width - SrcCenterRect.Left - SrcCenterRect.Right;
      VariableHeight := DstRect.Height - SrcCenterRect.Top - SrcCenterRect.Bottom;

      // This will need fixing.

      // Top left
      if (SrcCenterRect.Left > 0) and (SrcCenterRect.Top > 0) then
        Src.DrawTo(Dst, DstRect.Left, DstRect.Top, Rect(0, 0, SrcCenterRect.Left, SrcCenterRect.Top));

      // Top right
      if (SrcCenterRect.Right > 0) and (SrcCenterRect.Top > 0) then
        Src.DrawTo(Dst, DstRect.Left + DstRect.Width - SrcCenterRect.Right, DstRect.Top,
                   Rect(SrcRect.Width - SrcCenterRect.Right, 0, SrcRect.Width, SrcCenterRect.Top));

      // Bottom left
      if (SrcCenterRect.Left > 0) and (SrcCenterRect.Bottom > 0) then
        Src.DrawTo(Dst, DstRect.Left, DstRect.Top + DstRect.Height - SrcCenterRect.Bottom,
                   Rect(0, SrcRect.Height - SrcCenterRect.Bottom, SrcCenterRect.Left, SrcRect.Height));

      // Bottom right
      if (SrcCenterRect.Right > 0) and (SrcCenterRect.Bottom > 0) then
        Src.DrawTo(Dst, DstRect.Left + DstRect.Width - SrcCenterRect.Left,
                   DstRect.Top + DstRect.Height - SrcCenterRect.Bottom,
                   Rect(SrcRect.Width - SrcCenterRect.Right, SrcRect.Height - SrcCenterRect.Bottom,
                        SrcRect.Width, SrcRect.Height));

      // Top edge
      if (VariableWidth > 0) and (SrcCenterRect.Top > 0) then
        DrawTiled(SizedRect(SrcCenterRect.Left, 0, SrcRect.Width - SrcCenterRect.Left - SrcCenterRect.Right, SrcCenterRect.Top),
                  SizedRect(DstRect.Left + SrcCenterRect.Left, DstRect.Top, VariableWidth, SrcCenterRect.Top));

      // Left edge
      if (VariableHeight > 0) and (SrcCenterRect.Left > 0) then
        DrawTiled(SizedRect(0, SrcCenterRect.Top, SrcCenterRect.Left, SrcRect.Height - SrcCenterRect.Top - SrcCenterRect.Bottom),
                  SizedRect(DstRect.Left, DstRect.Top + SrcCenterRect.Top, SrcCenterRect.Left, VariableHeight));

      // Bottom edge
      if (VariableWidth > 0) and (SrcCenterRect.Bottom > 0) then
        DrawTiled(SizedRect(SrcCenterRect.Left, SrcRect.Height - SrcCenterRect.Bottom, SrcRect.Width - SrcCenterRect.Left - SrcCenterRect.Right, SrcCenterRect.Bottom),
                  SizedRect(DstRect.Left + SrcCenterRect.Left, DstRect.Top + DstRect.Height - SrcCenterRect.Bottom, VariableWidth, SrcCenterRect.Bottom));

      // Right edge
      if (VariableHeight > 0) and (SrcCenterRect.Right > 0) then
        DrawTiled(SizedRect(SrcRect.Width - SrcCenterRect.Right, SrcCenterRect.Top, SrcCenterRect.Right, SrcRect.Height - SrcCenterRect.Top - SrcCenterRect.Bottom),
                  SizedRect(DstRect.Left + DstRect.Width - SrcCenterRect.Right, DstRect.Top + SrcCenterRect.Top, SrcCenterRect.Right, VariableHeight));

      // Center
      if (VariableWidth > 0) and (VariableHeight > 0) then
        DrawTiled(SizedRect(SrcCenterRect.Left, SrcCenterRect.Top, SrcRect.Width - SrcCenterRect.Left - SrcCenterRect.Right, SrcRect.Height - SrcCenterRect.Top - SrcCenterRect.Bottom),
                  SizedRect(DstRect.Left + SrcCenterRect.Left, DstRect.Top + SrcCenterRect.Top, VariableWidth, VariableHeight));
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

