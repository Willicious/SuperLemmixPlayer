unit LemTerrainGroup;

interface

uses
  Generics.Collections,
  SysUtils,
  LemTerrain;

type
  TTerrainGroup = class
    private
      fName: String;
      fTerrains: TTerrains;

      procedure SetName(aValue: String);
    public
      property Name: String read fName write SetName;
      property Terrains: TTerrains read fTerrains;
  end;

  TTerrainGroups = TObjectList<TTerrainGroup>;

implementation

procedure TTerrainGroup.SetName(aValue: string);
begin
  fName := Trim(Uppercase(aValue));
end;

end.