{$include lem_directives.inc}

unit LemCursor;

interface

uses
  GameControl,
  Windows,
  GR32,
  Graphics;

type
  TNLCursor = class
    private
      fLoaded: Boolean;
      fMaxZoom: Integer;
      fCursors: array of HCURSOR;
    public
      constructor Create(aMaxZoom: Integer);
      destructor Destroy; override;
      procedure LoadFromBitmap(aBitmap: TBitmap32);

      function GetCursor(aZoom: Integer): HCURSOR;

      property MaxZoom: Integer read fMaxZoom;
  end;

implementation

constructor TNLCursor.Create(aMaxZoom: Integer);
begin
  inherited Create;
  fMaxZoom := aMaxZoom;
  SetLength(fCursors, aMaxZoom);
end;

destructor TNLCursor.Destroy;
var
  i: Integer;
begin
  if fLoaded then
    for i := 0 to fMaxZoom-1 do
      DestroyIcon(fCursors[i]);
end;

function TNLCursor.GetCursor(aZoom: Integer): HCURSOR;
begin
  Result := fCursors[aZoom - 1];
end;

procedure TNLCursor.LoadFromBitmap(aBitmap: TBitmap32);
var
  TempBitmap32: TBitmap32;
  TempBitmapImage, TempBitmapMask: TBitmap;
  TempInfo: TIconInfo;
  BaseScale: Double;

  i: Integer;
  Zoom: Integer;

  procedure MaskTempBitmap;
  var
    x, y: Integer;
    c: TColor32;
    a: byte;
  begin
    for y := 0 to TempBitmap32.Height-1 do
      for x := 0 to TempBitmap32.Width-1 do
      begin
        a := AlphaComponent(TempBitmap32[x, y]);
        c := $FF000000 or (a shl 16) or (a shl 8) or (a);
        TempBitmap32[x, y] := c;
      end;
  end;
begin
  BaseScale := GameParams.CursorResize;

  TempBitmap32 := TBitmap32.Create();
  TempBitmapImage := TBitmap.Create();
  TempBitmapMask := TBitmap.Create();
  try
    for i := 0 to fMaxZoom-1 do
    begin
      Zoom := i + 1;

      TempBitmap32.SetSize(Round(aBitmap.Width * Zoom * BaseScale), Round(aBitmap.Height * Zoom * BaseScale));
      TempBitmap32.Clear(0);
      TempBitmap32.Draw(TempBitmap32.BoundsRect, aBitmap.BoundsRect, aBitmap);
      TempBitmapImage.Assign(TempBitmap32);
      MaskTempBitmap;
      TempBitmapMask.Assign(TempBitmap32);

      with TempInfo do
      begin
        fIcon := false;
        xHotspot := TempBitmap32.Width div 2;
        yHotspot := TempBitmap32.Height div 2;
        hbmMask := TempBitmapMask.Handle;
        hbmColor := TempBitmapImage.Handle;
      end;

      fCursors[i] := CreateIconIndirect(TempInfo);
    end;

    fLoaded := true;
  finally
    TempBitmap32.Free;
    TempBitmapImage.Free;
    TempBitmapMask.Free;
  end;
end;

end.
