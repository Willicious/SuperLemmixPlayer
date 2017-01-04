{$include lem_directives.inc}

unit LemAnimationSet;

interface

uses
  Classes, GR32,
  LemTypes, LemMetaAnimation;

type
  {-------------------------------------------------------------------------------
    base class animationset
  -------------------------------------------------------------------------------}
  TBaseAnimationSet = class(TPersistent)
  private
    procedure SetMetaLemmingAnimations(Value: TMetaLemmingAnimations);
  protected
    fMetaLemmingAnimations : TMetaLemmingAnimations; // meta data lemmings
    fMetaMaskAnimations    : TMetaAnimations; // meta data masks (for bashing etc.)
    fLemmingAnimations     : TBitmaps; // the list of lemmings bitmaps
    fMaskAnimations        : TBitmaps; // the list of masks (for bashing etc.)
    fBrickColor            : TColor32;
  { new virtuals }
    function DoCreateMetaLemmingAnimations: TMetaLemmingAnimations; virtual;
    function DoCreateMetaMaskAnimations: TMetaAnimations; virtual;
  { internals }
    procedure DoReadMetaData(XmasPal : Boolean = false); virtual; abstract;
    procedure DoReadData; virtual; abstract;
    procedure DoClearData; virtual; abstract;
  public
    constructor Create; virtual; // watch out, it's virtual!
    destructor Destroy; override;

    procedure ReadMetaData(XmasPal : Boolean = false);
    procedure ReadData;
    procedure ClearData;

    property BrickColor: TColor32 read fBrickColor write fBrickColor;

    property LemmingAnimations: TBitmaps read fLemmingAnimations;
    property MaskAnimations: TBitmaps read fMaskAnimations;
  published
    property MetaLemmingAnimations: TMetaLemmingAnimations read fMetaLemmingAnimations write SetMetaLemmingAnimations;
  end;

implementation

{ TBaseAnimationSet }

constructor TBaseAnimationSet.Create;
begin
  inherited Create;
  fMetaLemmingAnimations := DoCreateMetaLemmingAnimations;
  fMetaMaskAnimations := DoCreateMetaMaskAnimations;
  fLemmingAnimations := TBitmaps.Create;
  fMaskAnimations := TBitmaps.Create;
end;

destructor TBaseAnimationSet.Destroy;
begin
  fMetaLemmingAnimations.Free;
  fMetaMaskAnimations.Free;
  fMaskAnimations.Free;
  fLemmingAnimations.Free;
  inherited Destroy;
end;

procedure TBaseAnimationSet.ReadMetaData(XmasPal : Boolean = false);
begin
  DoReadMetaData(XmasPal);
end;

procedure TBaseAnimationSet.ReadData;
begin
  DoReadData;
end;

procedure TBaseAnimationSet.ClearData;
begin
  DoClearData;
end;


function TBaseAnimationSet.DoCreateMetaLemmingAnimations: TMetaLemmingAnimations;
begin
  Result := TMetaLemmingAnimations.Create(TMetaLemmingAnimation);
end;

function TBaseAnimationSet.DoCreateMetaMaskAnimations: TMetaAnimations;
begin
  Result := TMetaAnimations.Create(TMetaAnimation);
end;

procedure TBaseAnimationSet.SetMetaLemmingAnimations(Value: TMetaLemmingAnimations);
begin
  fMetaLemmingAnimations.Assign(Value);
end;


end.

