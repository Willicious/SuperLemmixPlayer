{$include lem_directives.inc}
unit LemGraphicSet;

interface

uses
  Classes,
  GR32,
  LemRenderHelpers,
  LemTypes,
  LemGadgetsMeta,
  LemMetaTerrain;

type
  TBaseGraphicSetClass = class of TBaseGraphicSet;
  TBaseGraphicSet = class(TPersistent)
  private
  protected
    fGraphicSetId    : Integer; // number identifier
    fGraphicSetIdExt : Integer; // extended graphics identifier
    fGraphicSetName  : string; // string identifier
    fDescription     : string; // displayname
    fLemmingSprites  : string;
    fMetaObjects     : TMetaObjects;
    fMetaTerrains    : TMetaTerrains;
    fTerrainBitmaps  : TBitmaps;            
    fObjectBitmaps   : TBitmaps;
    fSpecialBitmaps   : TBitmaps;
    procedure SetMetaObjects(Value: TMetaObjects); virtual;
    procedure SetMetaTerrains(Value: TMetaTerrains); virtual;
    function GetLemmingSprites: String;
  { dynamic creation }
    function DoCreateMetaObjects: TMetaObjects; dynamic;
    function DoCreateMetaTerrains: TMetaTerrains; dynamic;
  { these must be overridden }
    procedure DoReadMetaData(XmasPal : Boolean = false); dynamic; abstract;
    procedure DoReadData; dynamic; abstract;
    procedure DoClearMetaData; dynamic;
    procedure DoClearData; dynamic;
  public
    ObjectRenderList   : TDrawList; // list to accelerate object drawing
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ReadMetaData(XmasPal: Boolean = false);
    procedure ReadData;
    procedure ClearMetaData;
    procedure ClearData;
    property TerrainBitmaps: TBitmaps read fTerrainBitmaps;
    property ObjectBitmaps: TBitmaps read fObjectBitmaps;
    property SpecialBitmaps: TBitmaps read fSpecialBitmaps;
    property LemmingSprites: String read GetLemmingSprites;
  published
    property Description: string read fDescription write fDescription;
    property GraphicSetId: Integer read fGraphicSetId write fGraphicSetId;
    property GraphicSetIdExt: Integer read fGraphicSetIdExt write fGraphicSetIdExt;
    property GraphicSetName: string read fGraphicSetName write fGraphicSetName;
    property MetaObjects: TMetaObjects read fMetaObjects write SetMetaObjects;
    property MetaTerrains: TMetaTerrains read fMetaTerrains write SetMetaTerrains;
  end;

implementation

{ TBaseGraphicSet }

function TBaseGraphicSet.GetLemmingSprites: String;
begin
  if fLemmingSprites = '' then
    Result := 'lemming'
  else
    Result := fLemmingSprites;
end;

procedure TBaseGraphicSet.ClearData;
begin
  DoClearData;
end;

procedure TBaseGraphicSet.ClearMetaData;
begin
  DoClearMetaData;
end;

constructor TBaseGraphicSet.Create;
begin
  inherited Create;
  fMetaObjects := DoCreateMetaObjects;
  fMetaTerrains := DoCreateMetaTerrains;
  fTerrainBitmaps := TBitmaps.Create;
  fObjectBitmaps := TBitmaps.Create;
  fSpecialBitmaps := TBitmaps.Create;
  ObjectRenderList := TDrawList.Create;
end;

destructor TBaseGraphicSet.Destroy;
begin
  fMetaObjects.Free;
  fMetaTerrains.Free;
  fTerrainBitmaps.Free;
  fObjectBitmaps.Free;
  fSpecialBitmaps.Free;
  ObjectRenderList.Free;
  inherited Destroy;
end;

procedure TBaseGraphicSet.DoClearData;
begin
  fGraphicSetId    := 0;
  fGraphicSetIdExt := 0;
  fGraphicSetName  := '';
  fDescription     := '';
  fLemmingSprites := '';
  fTerrainBitmaps.Clear;
  fObjectBitmaps.Clear;
  fSpecialBitmaps.Clear;
  ObjectRenderList.Clear;
end;

procedure TBaseGraphicSet.DoClearMetaData;
begin
  fMetaObjects.Clear;
  fMetaTerrains.Clear;
end;

function TBaseGraphicSet.DoCreateMetaObjects: TMetaObjects;
begin
  Result := TMetaObjects.Create;
end;

function TBaseGraphicSet.DoCreateMetaTerrains: TMetaTerrains;
begin
  Result := TMetaTerrains.Create;
end;

procedure TBaseGraphicSet.ReadData;
begin
  DoReadData;
end;

procedure TBaseGraphicSet.ReadMetaData(XmasPal : Boolean = False);
begin
  DoReadMetaData(XmasPal);
end;

procedure TBaseGraphicSet.SetMetaObjects(Value: TMetaObjects);
begin
  fMetaObjects.Assign(Value);
end;

procedure TBaseGraphicSet.SetMetaTerrains(Value: TMetaTerrains);
begin
  fMetaTerrains.Assign(Value);
end;

end.

