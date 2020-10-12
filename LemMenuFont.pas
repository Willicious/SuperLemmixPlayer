unit LemMenuFont;

interface

uses
  GR32,
  Classes, SysUtils;

const
  PURPLEFONTCOUNT = ord(#132) - ord('!') + 1;
  PurpleFontCharSet = [#26..#126] - [#32];

type
  TPurpleFont = class
    private
      function GetBitmapOfChar(Ch: Char): TBitmap32;
      procedure Combine(F: TColor32; var B: TColor32; M: TColor32);
    public
      fBitmaps: array[0..PURPLEFONTCOUNT - 1] of TBitmap32;
      constructor Create;
      destructor Destroy; override;
      property BitmapOfChar[Ch: Char]: TBitmap32 read GetBitmapOfChar;
  end;

implementation

procedure TPurpleFont.Combine(F: TColor32; var B: TColor32; M: TColor32);
// just show transparent
begin
  if F <> 0 then B := F;
end;

constructor TPurpleFont.Create;
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

end.
