unit LemMetaConstruct;

// Constructs are a special kind of terrain piece made up of other pieces.
// Constructs need to be able to access a TRenderer in order to generate
// their image. It is possible to use an existing renderer, which will give
// the best performance. However, if nessecary, they will create their own.

interface

uses
  Dialogs,
  LemMetaTerrain, LemTerrain, LemRendering, LemRenderHelpers, LemNeoParserOld,
  LemTypes, LemStrings, GR32, Classes, SysUtils;

type
  TConstructSteelOption = (cst_Normal, cst_None, cst_Simple);

  TMetaConstruct = class(TMetaTerrain)
    private
      fUsingOwnRenderer: Boolean;
      fRenderer: TRenderer;
      fPieceList: TTerrains;
      fSteelMode: TConstructSteelOption;
      function GetRenderer: TRenderer;
      property Renderer: TRenderer read GetRenderer;
    protected
      procedure GenerateGraphicImage; override;
      procedure GeneratePhysicsImage; override;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Load(aCollection, aPiece: String); override;
      procedure SetRenderer(aRenderer: TRenderer);
  end;

implementation

constructor TMetaConstruct.Create;
begin
  inherited;
  fPieceList := TTerrains.Create;
  fRenderer := nil;
  fUsingOwnRenderer := false;
end;

destructor TMetaConstruct.Destroy;
begin
  fPieceList.Free;
  if fUsingOwnRenderer then fRenderer.Free;
  inherited;
end;

procedure TMetaConstruct.SetRenderer(aRenderer: TRenderer);
begin
  if fUsingOwnRenderer then
    fRenderer.Free;
  fRenderer := aRenderer;
  fUsingOwnRenderer := false;
end;

function TMetaConstruct.GetRenderer: TRenderer;
begin
  if fRenderer = nil then
  begin
    fRenderer := TRenderer.Create;
    fUsingOwnRenderer := true;
  end;
  Result := fRenderer;
end;

procedure TMetaConstruct.Load(aCollection, aPiece: String);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  T: TTerrain;
begin
  Parser := TNeoLemmixParser.Create;
  try
    ClearImages;
    fPieceList.Clear;
    fSteelMode := cst_Normal;

    if not DirectoryExists(AppPath + SFStylesPieces + aCollection) then
    raise Exception.Create('TMetaConstruct.Load: Collection "' + aCollection + '" does not exist.');
    SetCurrentDir(AppPath + SFStylesPieces + aCollection + SFPiecesTerrain);

    GS := Lowercase(aCollection);
    Piece := Lowercase(aPiece);

    Parser.LoadFromFile(Piece + '.nxcs');
    repeat
      Line := Parser.NextLine;

      if Line.Keyword = 'WIDTH' then
        Width := Line.Numeric;

      if Line.Keyword = 'HEIGHT' then
        Height := Line.Numeric;

      if Line.Keyword = 'STEEL' then
      begin
        Line.Value := Lowercase(Line.Value);
        if Line.Value = 'auto' then
          fSteelMode := cst_Normal;
        if Line.Value = 'simple' then
          fSteelMode := cst_Simple;
        if Line.Value = 'none' then
          fSteelMode := cst_None;
      end;

      if Line.Keyword = 'TERRAIN' then
      begin
        T := fPieceList.Add;

        T.DrawingFlags := tdf_NoOneWay;
        T.GS := '';
        T.Piece := '';
        T.Left := 0;
        T.Top := 0;

        repeat
          Line := Parser.NextLine;
          T.EvaluateParserLine(Line);
        until (Line.Keyword = '') or (Line.Keyword = 'TERRAIN') or (Line.Keyword = 'STEEL');
        Parser.Back;
      end;
    until Line.Keyword = '';
  finally
    Parser.Free;
  end;
end;

procedure TMetaConstruct.GenerateGraphicImage;
var
  TempBMP: TBitmap32;
  i: Integer;
begin
  TempBMP := TBitmap32.Create;
  try
    TempBMP.SetSize(Width, Height);
    for i := 0 to fPieceList.Count-1 do
      Renderer.DrawTerrain(TempBmp, fPieceList[i]);

    SetGraphic(TempBMP);
  finally
    TempBMP.Free;
  end;
end;

procedure TMetaConstruct.GeneratePhysicsImage;
var
  Src: TBitmap32;
  Dst: TBitmap32;
  T: TTerrain;
  MT: TMetaTerrain;
  i, x, y: Integer;
begin
  Src := TBitmap32.Create;
  Dst := fPhysicsImages[0];
  try
    Dst.SetSize(Width, Height);
    Src.SetSize(Width, Height);
    Dst.Clear(0);
    for i := 0 to fPieceList.Count-1 do
    begin
      Src.Clear(0);
      T := fPieceList[i];
      MT := fRenderer.FindMetaTerrain(T);
      MT.PhysicsImage[T.Flip, T.Invert, T.Rotate].DrawTo(Src, T.Left, T.Top);
      for y := 0 to Src.Height-1 do
        for x := 0 to Src.Width-1 do
        begin
          if Src.Pixel[x, y] and PM_SOLID = 0 then Continue; // never anything to do in this case

          if (T.DrawingFlags and tdf_Erase <> 0) then
            Dst.Pixel[x, y] := 0
          else if (T.DrawingFlags and tdf_NoOverwrite <> 0) and (Dst.Pixel[x, y] and PM_SOLID <> 0) then
          begin
            if (fSteelMode = cst_Simple) and (MT.IsSteel) then
              Dst.Pixel[x, y] := Dst.Pixel[x, y] or PM_STEEL;
          end else if (fSteelMode <> cst_None) and (MT.IsSteel) then
            Dst.Pixel[x, y] := PM_SOLID or PM_STEEL
          else if (T.DrawingFlags and tdf_NoOneWay = 0) then
            Dst.Pixel[x, y] := PM_SOLID or PM_ONEWAY
          else
            Dst.Pixel[x, y] := PM_SOLID;
        end;
    end;

    fGeneratedPhysicsImage[0] := true;
  finally
    Src.Free;
  end;
end;

end.
