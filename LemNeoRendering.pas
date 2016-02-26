// An entirely new rendering unit, to replace LemRendering.pas
// The original is, to be blunt, a fucking mess. The goal of this
// unit is to replace it with a more well-written, faster, and
// flexible rendering unit, based on the concept of using two
// seperate maps - one for physics, one for visuals.

// Eventually, all handling of graphic sets should be through
// TRenderer. For now, graphic sets might be double-loaded until
// the switch is fully implemented.

unit LemNeoRendering;

interface

uses
  Dialogs, PngInterface, //debug
  Gr32, Gr32_Blend,
  GameControl,                  // direct access to settings, stop requiring other units to pass them!
  LemLevel,
  LemNeoGraphicSet, LemTypes,    // for loading graphic sets
  LemTerrain, LemMetaTerrain,
  Classes, SysUtils;

const
  { Configuration }
  ALPHA_CUTOFF = $80; // Pixels with an alpha value below this will be considered non-solid

  { Magic numbers }
  PIXEL_SOLID =  $01;
  PIXEL_STEEL =  $02;
  PIXEL_ONEWAY = $04;

type
  // TRenderer is the main renderer unit.
  TRenderer = class
    private
      fGameParams: TDosGameParams;
      fLevel: TLevel;
      fGraphicSet: TBaseNeoGraphicSet;

      // Pixel combine procedures
      procedure CombineTerrainNormal(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);

      // General rendering procedures
      procedure RenderVisualMap(aMap: TBitmap32);
      procedure RenderPhysicsMap(aMap: TBitmap32);

      // Terrain rendering procedures
      procedure DrawTerrain(aMap: TBitmap32; aPiece: TTerrain);
    public
      constructor Create(aParams: TDosGameParams);
      destructor Destroy; override;
      procedure SetLevel(aLevel: TLevel);
      procedure LoadGraphicSet(aSetName: String);
      procedure RenderMaps(aVisualMap: TBitmap32; aPhysicsMap: TBitmap32 = nil);
  end;

implementation

{-----------}
{ TRenderer }
{-----------}

// Constructor and Destructor //

constructor TRenderer.Create(aParams: TDosGameParams);
begin
  inherited Create;
  fGameParams := aParams;
  fGraphicSet := TBaseNeoGraphicSet.Create;
end;

destructor TRenderer.Destroy;
begin
  fGraphicSet.Free;
  inherited;
end;

procedure TRenderer.SetLevel(aLevel: TLevel);
begin
  fLevel := aLevel;
  LoadGraphicSet(fLevel.Info.GraphicSetName);
end;

procedure TRenderer.LoadGraphicSet(aSetName: String);
var
  GraphicSetLoadStream: TMemoryStream;
begin
  GraphicSetLoadStream := CreateDataStream(aSetName + '.dat', ldtLemmings);
  try
    with fGraphicSet do
    begin
      // This code REALLY needs to be tidied up. But I think problems with LemNeoGraphicSet.pas
      // need to be addressed first, as they're what makes this messy code needed in the first place.
      ClearMetaData;
      ClearData;

      GraphicSetId := fLevel.Info.GraphicSet mod 256;
      GraphicSetFile := fGameParams.Directory + fLevel.Info.GraphicSetName + '.dat';

      GraphicSetIdExt := 0; // VGASPECs aren't handled yet
      GraphicExtFile := '';

      LoadFromStream(GraphicSetLoadStream);
      ReadMetaData;
      ReadData;
    end;
  finally
    GraphicSetLoadStream.Free;
  end;
end;

// Core Rendering Procedures //

procedure TRenderer.RenderMaps(aVisualMap: TBitmap32; aPhysicsMap: TBitmap32 = nil);
begin
  RenderVisualMap(aVisualMap);
  if aPhysicsMap <> nil then RenderPhysicsMap(aPhysicsMap);
end;

procedure TRenderer.RenderVisualMap(aMap: TBitmap32);
var
  i: Integer;
begin
  // Set the size of the bitmap and clear it
  aMap.SetSize(fLevel.Info.Width, fLevel.Info.Height);
  aMap.Clear($00000000);

  // Render terrain
  for i := 0 to fLevel.Terrains.Count-1 do
    DrawTerrain(aMap, fLevel.Terrains[i]);

  SavePngFile('testrender.png', aMap);
end;

procedure TRenderer.RenderPhysicsMap(aMap: TBitmap32);
begin
  raise Exception.Create('TRenderer.RenderPhysicsMap not yet implemented');
end;

// Terrain Rendering Procedures //

procedure TRenderer.CombineTerrainNormal(F: TColor32; var B: TColor32; M: TColor32);
begin
  // Standard combine procedure. Probably doesn't need to be explicitly made, but
  // more consistent if it's here.
  if (F shr 24) = 0 then Exit;
  MergeMem(F, B);
end;

procedure TRenderer.CombineTerrainNoOverwrite(F: TColor32; var B: TColor32; M: TColor32);
begin
  // Basically the inverse of the above.
  if ((F shr 24) = 0) or ((B shr 24) = $FF) then Exit;
  MergeMem(B, F);
  B := F;
end;

procedure TRenderer.CombineTerrainErase(F: TColor32; var B: TColor32; M: TColor32);
begin
  // This one's a tad trickier.
  if (F shr 24) = 0 then Exit;
  CombineMem(0, B, (F shr 24));
end;

procedure TRenderer.DrawTerrain(aMap: TBitmap32; aPiece: TTerrain);
var
  TerrainBMP: TBitmap32;
begin
  TerrainBMP := TBitmap32.Create;
  TerrainBMP.Assign(fGraphicSet.TerrainBitmaps[aPiece.Identifier]);

  // Apply flips and rotations
  if (aPiece.DrawingFlags and tdf_Rotate) <> 0 then
    TerrainBMP.Rotate90;
  if (aPiece.DrawingFlags and tdf_Invert) <> 0 then
    TerrainBMP.FlipVert;
  if (aPiece.DrawingFlags and tdf_Flip) <> 0 then
    TerrainBMP.FlipHorz;

  TerrainBMP.DrawMode := dmCustom;
  if (aPiece.DrawingFlags and tdf_NoOverwrite) <> 0 then
    TerrainBMP.OnPixelCombine := CombineTerrainNoOverwrite
  else if (aPiece.DrawingFlags and tdf_Erase) <> 0 then
    TerrainBMP.OnPixelCombine := CombineTerrainErase
  else
    TerrainBMP.OnPixelCombine := CombineTerrainNormal;

  TerrainBMP.DrawTo(aMap, aPiece.Left, aPiece.Top);

  TerrainBMP.Free;

  EMMS; // Needed after blend functions used in the pixel combine routines on certain CPUs.
end;

end.