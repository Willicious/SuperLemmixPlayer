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
    //fDecompressor: TDosDatDecompressor;
    //fSections: TDosDatSectionList;
    //fPlanar: TDosPlanarBitmap;
    fSysDat: TSysDatRec;
    fSysDatLoaded: Boolean;
    fPositions: array[0..7] of Integer; // for compatibility with code that relied on current MAIN.DAT position, obviously needs to be
                                        // removed at some point, but works for now
    procedure EnsureLoaded;
    procedure EnsureDecompressed(aSection: Integer);
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
    procedure ExtractAnimation(Bmp: TBitmap32; aSection, aPos,
      aWidth, aHeight, aFrameCount: Integer; BPP: Byte; aPal: TArrayOfColor32);
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
  //fSections := TDosDatSectionList.Create;
  //fPlanar := TDosPlanarBitmap.Create;
  //fDecompressor := TDosDatDecompressor.Create;
  FillChar(fPositions, SizeOf(fPositions), 0);
end;

destructor TMainDatExtractor.Destroy;
begin
  //fSections.Free;
  //fPlanar.Free;
  //fDecompressor.Free;
  inherited;
end;

procedure TMainDatExtractor.SetSectionPosition(aSection: Integer; aPosition: Integer);
begin
  EnsureDecompressed(aSection);
  fPositions[aSection] := aPosition;
  //fSections[aSection].DecompressedData.Position := aPosition;
end;

procedure TMainDatExtractor.EnsureDecompressed(aSection: Integer);
//var
//  Sec: TDosDatSection;
begin
  EnsureLoaded;
  //Sec := fSections[aSection];
  //if Sec.DecompressedData.Size = 0 then
  //  fDecompressor.DecompressSection(Sec.CompressedData, Sec.DecompressedData)
end;

procedure TMainDatExtractor.EnsureLoaded;
begin

end;

procedure TMainDatExtractor.ExtractAnimation(Bmp: TBitmap32; aSection, aPos, aWidth,
  aHeight, aFrameCount: Integer; BPP: Byte; aPal: TArrayOfColor32);
begin
{  EnsureDecompressed(aSection);

  LoadSysData;
  if fSysDat.Options2 and 2 <> 0 then
  begin
    if (aSection = 0) or (aSection = 6) then
    begin
      aPal[1] := $D02020;
      aPal[4] := $F0F000;
      aPal[5] := $4040E0;
    end else if (aSection > 2) and (aSection < 6) then
    begin
      aPal := GetDosMainMenuPaletteColors32(true);
    end;
  end;

  fPlanar.LoadAnimationFromStream(fSections[aSection].DecompressedData,
    Bmp, aPos, aWidth, aHeight, aFrameCount, BPP, aPal);}
end;

function TMainDatExtractor.GetImageFileName(aSection, aPosition: Integer): String;
begin
  // Inefficient, but works for now.
  Result := '';
  //if (fSysDat.Options3 and 32) = 0 then Exit;
  case aSection of
    {2: case aPosition of  // Skill digits here
       end;}
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
{    4: case aPosition of
         $028D20: Result := 'talisman_bronze_inactive';
         $02A280: Result := 'talisman_bronze';
         $02B7E0: Result := 'talisman_silver_inactive';
         $02CD40: Result := 'talisman_silver';
         $02E2A0: Result := 'talisman_gold_inactive';
         $02F800: Result := 'talisman_gold';
       end;}
    5: Result := 'rank_' + LeadZeroStr((aPosition div $1209) + 1, 2);
  end;
  if Result <> '' then Result := Result + '.png';
  //if (aSection = 3) or (aSection = 5) then
  //  ShowMessage(IntToStr(aSection) + ':$' + IntToHex(aPosition, 8) + ':' + Result);
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
  //if fSysDat.Options3 and 32 = 0 then
  //  raise Exception.Create('Tried to load PNG graphics from a pre-PNG pack: ' + aName);

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

  //EnsureDecompressed(aSection);

  if aPosition = -1 then
    aPosition := fPositions[aSection];

  if GetImageFileName(aSection, aPosition) <> '' then
  begin
    //try
      fPositions[aSection] := aPosition;
      TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + GetImageFileName(aSection, aPosition), Bmp);
      SetDrawModes(Bmp, aSection, aPosition);
      fPositions[aSection] := fPositions[aSection] + ((aWidth * aHeight * BPP) div 8); // compatibility with those using relative positions
      Exit;
    //except
      // Continue with the rest of the code here if it fails.
    //end;
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
  //TempRec : TSysDatRec;
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

