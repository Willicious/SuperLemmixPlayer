unit LemGraphicSet;

interface

uses
  Classes, SysUtils, Contnrs, GR32;


type

  TBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmap32;
  protected
  public
    function Add(Item: TBitmap32): Integer;
    procedure Insert(Index: Integer; Item: TBitmap32);
    property Items[Index: Integer]: TBitmap32 read GetItem; default;
    property List;
  published
  end;

  TObjectBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmaps;
  protected
  public
    function Add(Item: TBitmaps): Integer;
    procedure Insert(Index: Integer; Item: TBitmaps);
    property Items[Index: Integer]: TBitmaps read GetItem; default;
    property List;
  published
  end;

  TMetaObject = class
  private
    fName: String;
    fTriggerType:    Byte;
    fTriggerAnim:    Boolean;
    fPTriggerX:      Integer;
    fPTriggerY:      Integer;
    fPTriggerW:      Integer;
    fPTriggerH:      Integer;
    fSTriggerX:      Integer;
    fSTriggerY:      Integer;
    fSTriggerW:      Integer;
    fSTriggerH:      Integer;
    fOffsetL: Integer;
    fOffsetT: Integer;
    fOffsetR: Integer;
    fOffsetB: Integer;
    fConvertFlip: Boolean;
    fConvertInvert: Boolean;
    fTriggerSound:   Byte;
    fPreviewFrame:   Integer;
    fKeyFrame:       Integer;
    fRandomFrame:    Boolean;
    fResizeHorizontal: Boolean;
    fResizeVertical:   Boolean;
    fNoAutoResizeSettings: Boolean;
  public
    procedure Assign(aValue: TMetaObject);
    property TriggerType: Byte read fTriggerType write fTriggerType;
    property TriggerAnim: Boolean read fTriggerAnim write fTriggerAnim;
    property PTriggerX: Integer read fPTriggerX write fPTriggerX;
    property PTriggerY: Integer read fPTriggerY write fPTriggerY;
    property PTriggerW: Integer read fPTriggerW write fPTriggerW;
    property PTriggerH: Integer read fPTriggerH write fPTriggerH;
    property STriggerX: Integer read fSTriggerX write fSTriggerX;
    property STriggerY: Integer read fSTriggerY write fSTriggerY;
    property STriggerW: Integer read fSTriggerW write fSTriggerW;
    property STriggerH: Integer read fSTriggerH write fSTriggerH;
    property TriggerSound: Byte read fTriggerSound write fTriggerSound;
    property PreviewFrame: Integer read fPreviewFrame write fPreviewFrame;
    property KeyFrame: Integer read fKeyFrame write fKeyFrame;
    property RandomFrame: Boolean read fRandomFrame write fRandomFrame;
    property Name: String read fName write fName;
    property OffsetL: Integer read fOffsetL write fOffsetL;
    property OffsetT: Integer read fOffsetT write fOffsetT;
    property OffsetR: Integer read fOffsetR write fOffsetR;
    property OffsetB: Integer read fOffsetB write fOffsetB;
    property ConvertFlip: Boolean read fConvertFlip write fConvertFlip;
    property ConvertInvert: Boolean read fConvertInvert write fConvertInvert;
    property ResizeHorizontal: Boolean read fResizeHorizontal write fResizeHorizontal;
    property ResizeVertical: Boolean read fResizeVertical write fResizeVertical;
    property NoAutoResizeSettings: Boolean read fNoAutoResizeSettings write fNoAutoResizeSettings;
  end;

  TMetaTerrain = class
  private
    fSteel:    Boolean;
    fName: String;
    fOffsetL: Integer;
    fOffsetT: Integer;
    fOffsetR: Integer;
    fOffsetB: Integer;
    fConvertFlip: Boolean;
    fConvertInvert: Boolean;
    fConvertRotate: Boolean;
  public
    procedure Assign(aValue: TMetaTerrain);
    property Steel: Boolean read fSteel write fSteel;
    property Name: String read fName write fName;
    property OffsetL: Integer read fOffsetL write fOffsetL;
    property OffsetT: Integer read fOffsetT write fOffsetT;
    property OffsetR: Integer read fOffsetR write fOffsetR;
    property OffsetB: Integer read fOffsetB write fOffsetB;
    property ConvertFlip: Boolean read fConvertFlip write fConvertFlip;
    property ConvertInvert: Boolean read fConvertInvert write fConvertInvert;
    property ConvertRotate: Boolean read fConvertRotate write fConvertRotate;
  end;

  TMetaObjects = class(TObjectList)
  private
    function GetItem(Index: Integer): TMetaObject;
  protected
  public
    function Add(Item: TMetaObject): Integer;
    procedure Insert(Index: Integer; Item: TMetaObject);
    property Items[Index: Integer]: TMetaObject read GetItem; default;
    property List;
  published
  end;

  TSounds = array[0..255] of TMemoryStream;

  TMetaTerrains = class(TObjectList)
  private
    function GetItem(Index: Integer): TMetaTerrain;
  protected
  public
    function Add(Item: TMetaTerrain): Integer;
    procedure Insert(Index: Integer; Item: TMetaTerrain);
    property Items[Index: Integer]: TMetaTerrain read GetItem; default;
    property List;
  published
  end;

  TBaseGraphicSetClass = class of TBaseGraphicSet;
  TBaseGraphicSet = class(TPersistent)
    private
      fName: String;
      fResolution: Integer; // 8 = standard resolution (320x160 playing area)
      fLemmingSprites: String; // currently only uses "lemming" or "xlemming"
      function GetLemmingSprites: String;
    public
      KeyColors: Array[0..7] of TColor32;
      TerrainImages: TBitmaps;
      ObjectImages: TObjectBitmaps;
      MetaTerrains: TMetaTerrains;
      MetaObjects: TMetaObjects;
      Sounds: TSounds;
      constructor Create;
      destructor Destroy; override;
      procedure FixResolution;
      property Name: String read fName write fName;
      property Resolution: Integer read fResolution write fResolution;
      property LemmingSprites: String read GetLemmingSprites write fLemmingSprites;
  end;

implementation

//TBaseGraphicSet

constructor TBaseGraphicSet.Create;
begin
  inherited;
  TerrainImages := TBitmaps.Create;
  ObjectImages := TObjectBitmaps.Create;
  MetaTerrains := TMetaTerrains.Create;
  MetaObjects := TMetaObjects.Create;
  //Sounds := TSounds.Create;
  fResolution := 8; // this works well as a default
end;

destructor TBaseGraphicSet.Destroy;
var
  i: Integer;
begin
  TerrainImages.Free;
  ObjectImages.Free;
  MetaTerrains.Free;
  MetaObjects.Free;
  //Sounds.Free;
  for i := 0 to 255 do
    if Sounds[i] <> nil then Sounds[i].Free;
  inherited;
end;

function TBaseGraphicSet.GetLemmingSprites: String;
begin
  if fLemmingSprites = '' then
    Result := 'lemming'
  else
    Result := fLemmingSprites;
end;

procedure TBaseGraphicSet.FixResolution;
var
  TempBmp: TBitmap32;
  i, i2: Integer;

  procedure DoResize(aBmp: TBitmap32);
  begin
    TempBmp.SetSize(aBmp.Width div (fResolution div 8), aBmp.Height div (fResolution div 8));
    TempBmp.Clear(0);
    aBmp.DrawTo(TempBmp, TempBmp.BoundsRect, aBmp.BoundsRect);
    aBmp.Assign(TempBmp);
  end;
begin
  if fResolution in [0, 8] then Exit;
  TempBmp := TBitmap32.Create;

  for i := 0 to TerrainImages.Count-1 do
    DoResize(TerrainImages[i]);

  for i := 0 to ObjectImages.Count-1 do
    for i2 := 0 to ObjectImages[i].Count-1 do
      DoResize(ObjectImages[i][i2]);

  for i := 0 to MetaObjects.Count-1 do
    with MetaObjects[i] do
    begin
      PTriggerX := PTriggerX div (fResolution div 8);
      PTriggerY := PTriggerY div (fResolution div 8);
      PTriggerW := PTriggerW div (fResolution div 8);
      PTriggerH := PTriggerH div (fResolution div 8);
    end;

  // Older NeoLemmix versions used <value> * 8 div fResolution
  // Newer versions use <value> div (fResolution div 8), which generally gives the same result
  // but may be off by one pixel sometimes. For consistency with that, GSTool also uses this
  // new formula.

  fResolution := 8;

  TempBmp.Free;
end;

//TBitmaps

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

//TObjectBitmaps

function TObjectBitmaps.Add(Item: TBitmaps): Integer;
begin
  Result := inherited Add(Item);
end;

function TObjectBitmaps.GetItem(Index: Integer): TBitmaps;
begin
  Result := inherited Get(Index);
end;

procedure TObjectBitmaps.Insert(Index: Integer; Item: TBitmaps);
begin
  inherited Insert(Index, Item);
end;

//TMetaObjects

function TMetaObjects.Add(Item: TMetaObject): Integer;
begin
  Result := inherited Add(Item);
end;

function TMetaObjects.GetItem(Index: Integer): TMetaObject;
begin
  Result := inherited Get(Index);
end;

procedure TMetaObjects.Insert(Index: Integer; Item: TMetaObject);
begin
  inherited Insert(Index, Item);
end;

//TMetaTerrains

function TMetaTerrains.Add(Item: TMetaTerrain): Integer;
begin
  Result := inherited Add(Item);
end;

function TMetaTerrains.GetItem(Index: Integer): TMetaTerrain;
begin
  Result := inherited Get(Index);
end;

procedure TMetaTerrains.Insert(Index: Integer; Item: TMetaTerrain);
begin
  inherited Insert(Index, Item);
end;

// TMetaObject

procedure TMetaObject.Assign(aValue: TMetaObject);
begin
  fName := aValue.Name;
  fOffsetL := aValue.OffsetL;
  fOffsetT := aValue.OffsetT;
  fOffsetR := aValue.OffsetR;
  fOffsetB := aValue.OffsetB;
  fConvertFlip := aValue.ConvertFlip;
  fConvertInvert := aValue.ConvertInvert;
  fTriggerType := aValue.TriggerType;
  fTriggerAnim := aValue.TriggerAnim;
  fPTriggerX := aValue.PTriggerX;
  fPTriggerY := aValue.PTriggerY;
  fPTriggerW := aValue.PTriggerW;
  fPTriggerH := aValue.PTriggerH;
  fSTriggerX := aValue.STriggerX;
  fSTriggerY := aValue.STriggerY;
  fSTriggerW := aValue.STriggerW;
  fSTriggerH := aValue.STriggerH;
  fTriggerSound := aValue.TriggerSound;
  fPreviewFrame := aValue.PreviewFrame;
  fKeyFrame := aValue.KeyFrame;
  fRandomFrame := aValue.RandomFrame;
end;

// TMetaTerrain

procedure TMetaTerrain.Assign(aValue: TMetaTerrain);
begin
  fSteel := aValue.Steel;
  fName := aValue.Name;
  fConvertFlip := aValue.ConvertFlip;
  fConvertInvert := aValue.ConvertInvert;
  fConvertRotate := aValue.ConvertRotate;
  fOffsetL := aValue.OffsetL;
  fOffsetT := aValue.OffsetT;
  fOffsetR := aValue.OffsetR;
  fOffsetB := aValue.OffsetB;
end;

{//TSounds

function TSounds.Add(Item: TMemoryStream): Integer;
begin
  Result := inherited Add(Item);
end;

function TSounds.GetItem(Index: Integer): TMemoryStream;
begin
  Result := inherited Get(Index);
end;

procedure TSounds.Insert(Index: Integer; Item: TMemoryStream);
begin
  inherited Insert(Index, Item);
end;}

end.