{$include lem_directives.inc}
unit LemDosMainDat;

interface

uses
  Dialogs,
  Classes, SysUtils, GR32, UMisc, PngInterface,
  LemTypes, LemDosStructures, LemDosCmp, LemDosBmp,
  LemStrings;

type
  {-------------------------------------------------------------------------------
    Tool to extract data from the dos main dat file
  -------------------------------------------------------------------------------}
  TMainDatExtractor = class
  private
    fFileName: string;
    fSysDat: TSysDatRec;
    fSysDatLoaded: Boolean;
    fPositions: array[0..7] of Integer; // for compatibility with code that relied on current MAIN.DAT position, obviously needs to be
                                        // removed at some point, but works for now
    function GetImageFileName(aSection, aPosition: Integer): String;
    procedure SetDrawModes(Bmp: TBitmap32; aSection, aPosition: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExtractBrownBackGround(Bmp: TBitmap32);
    procedure ExtractLogo(Bmp: TBitmap32);
    procedure ExtractBitmapByName(Bmp: TBitmap32; aName: String; aMaskColor: TColor32 = $00000000);
    procedure ExtractBitmap(Bmp: TBitmap32; aSection, aPosition,
      aWidth, aHeight, BPP: Integer; aPal: TArrayOfColor32);
    procedure SetSectionPosition(aSection: Integer; aPosition: Integer);

    function GetSysData: TSysDatRec;
    procedure LoadSysData;

    property FileName: string read fFileName write fFileName;
  end;

implementation

{ TMainDatExtractor }

constructor TMainDatExtractor.Create;
begin
  inherited Create;
  fFileName := 'MAIN.DAT';
  FillChar(fPositions, SizeOf(fPositions), 0);
end;

destructor TMainDatExtractor.Destroy;
begin
  inherited;
end;

procedure TMainDatExtractor.SetSectionPosition(aSection: Integer; aPosition: Integer);
begin
  fPositions[aSection] := aPosition;
end;


function TMainDatExtractor.GetImageFileName(aSection, aPosition: Integer): String;
begin
  // Inefficient, but works for now.
  Result := '';
  case aSection of
    3: case aPosition of
         $000000: Result := 'background';
         $0134C0: Result := 'logo';
         $035BE6: Result := 'sign_play';
         $039FCF: Result := 'sign_code';
         $03E3B8: Result := 'sign_config';
         $0427A1: Result := 'sign_rank';
         $046B8A: Result := 'sign_quit';
         $04AF73: Result := 'sign_talisman';
       end;
    5: Result := 'rank_' + LeadZeroStr((aPosition div $1209) + 1, 2);
  end;
  if Result <> '' then Result := Result + '.png';
end;

procedure TMainDatExtractor.SetDrawModes(Bmp: TBitmap32; aSection, aPosition: Integer);
var
  DoChangeMode: Boolean;
begin
  // Only need to be specified here if they're different from default
  DoChangeMode := false;
  case aSection of
    3: if aPosition <> 0 then DoChangeMode := true;
    4: DoChangeMode := true;
    5: DoChangeMode := true;
  end;
  if DoChangeMode then
  begin
    Bmp.DrawMode := dmBlend;
    Bmp.CombineMode := cmMerge;
  end;
end;

procedure TMainDatExtractor.ExtractBitmapByName(Bmp: TBitmap32; aName: String; aMaskColor: TColor32 = $00000000);
var
  LoadImageStream: TMemoryStream;
  MaskBMP: TBitmap32;

  procedure PrepareMaskImage;
  var
    x, y: Integer;
    McR, McG, McB: Byte;
    R, G, B, A: Byte;
  begin
    McR := RedComponent(aMaskColor);
    McG := GreenComponent(aMaskColor);
    McB := BlueComponent(aMaskColor);
    MaskBMP.BeginUpdate;
    for y := 0 to MaskBMP.Height-1 do
      for x := 0 to MaskBMP.Width-1 do
      begin
        A := AlphaComponent(MaskBMP.Pixel[x, y]);
        R := RedComponent(MaskBMP.Pixel[x, y]);
        G := GreenComponent(MaskBMP.Pixel[x, y]);
        B := BlueComponent(MaskBMP.Pixel[x, y]);
        // Alpha is not modified.
        R := R * McR div 255;
        G := G * McG div 255;
        B := B * McB div 255;
        MaskBMP.Pixel[x, y] := (A shl 24) + (R shl 16) + (G shl 8) + B;
      end;
    MaskBMP.EndUpdate;
  end;

begin
  LoadSysData;

  // Does NOT configure any draw modes, ever! This must be handled from the calling unit! //
  LoadImageStream := CreateDataStream(aName, ldtLemmings);
  TPngInterface.LoadPngStream(LoadImageStream, Bmp);
  LoadImageStream.Free;

  if (aMaskColor <> $00000000) then
  try
    LoadImageStream := CreateDataStream(ChangeFileExt(aName, '_mask.png'), ldtLemmings);
    if LoadImageStream <> nil then
    begin
      MaskBMP := TPngInterface.LoadPngStream(LoadImageStream);
      PrepareMaskImage;
      MaskBMP.DrawMode := dmBlend;
      MaskBMP.CombineMode := cmMerge;
      MaskBMP.DrawTo(Bmp);
      MaskBMP.Free;
    end;
  except
    // another silent fail
  end;
end;

procedure TMainDatExtractor.ExtractBitmap(Bmp: TBitmap32; aSection,
  aPosition, aWidth, aHeight, BPP: Integer; aPal: TArrayOfColor32);
begin
  LoadSysData;

  if aPosition = -1 then
    aPosition := fPositions[aSection];

  if GetImageFileName(aSection, aPosition) <> '' then
  begin
    fPositions[aSection] := aPosition;
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + GetImageFileName(aSection, aPosition), Bmp);
    SetDrawModes(Bmp, aSection, aPosition);
    fPositions[aSection] := fPositions[aSection] + ((aWidth * aHeight * BPP) div 8); // compatibility with those using relative positions
  end;
end;

procedure TMainDatExtractor.ExtractBrownBackGround(Bmp: TBitmap32);
{-------------------------------------------------------------------------------
  Extract hte brown background, used in several screens
-------------------------------------------------------------------------------}
begin
  TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'background.png', BMP);
end;

procedure TMainDatExtractor.ExtractLogo(Bmp: TBitmap32);
{-------------------------------------------------------------------------------
  Extract the LemmingLogo
-------------------------------------------------------------------------------}
begin
  TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'logo.png', BMP);
end;

function TMainDatExtractor.GetSysData(): TSysDatRec;
begin
  LoadSysData;
  Result := fSysDat;
end;

procedure TMainDatExtractor.LoadSysData;
var
  TempStream : TMemoryStream;
begin
  if fSysDatLoaded then exit;
  TempStream := CreateDataStream('system.dat', ldtLemmings);
  TempStream.Seek(0, soFromBeginning);
  TempStream.ReadBuffer(fSysDat, SYSDAT_SIZE);
  TempStream.Free;
  fSysDatLoaded := true;
end;

end.

