unit LemTerrainGroup;

interface

uses
  Generics.Collections,
  SysUtils,
  LemTerrain,
  SharedGlobals;

type
  TTerrainGroup = class
    private
      fName: String;
      fTerrains: TTerrains;

      procedure SetName(aValue: String);
    public
      constructor Create;
      destructor Destroy; override;

      property Name: String read fName write SetName;
      property Terrains: TTerrains read fTerrains;
  end;

  TTerrainGroups = TObjectList<TTerrainGroup>;

implementation

constructor TTerrainGroup.Create;
begin
  inherited;
  fTerrains := TTerrains.Create;
end;

destructor TTerrainGroup.Destroy;
begin
  fTerrains.Free;
  inherited;
end;

procedure TTerrainGroup.SetName(aValue: string);
begin
  fName := Trim(Uppercase(aValue));
end;

end.