{$include lem_directives.inc}

unit LemMetaObject;

interface

uses
  GR32, LemTypes,
  Classes, SysUtils,
  Contnrs, UTools;

const
  // Object Animation Types
  oat_None                     = 0;    // the object is not animated
  oat_Triggered                = 1;    // the object is triggered by a lemming
  oat_Continuous               = 2;    // the object is always moving
  oat_Once                     = 3;    // the object is animated once at the beginning (entrance only)

  // Object Sound Effects
  ose_None                     = 0;     // no sound effect
  ose_SkillSelect              = 1;     // the sound you get when you click on one of the skill icons at the bottom of the screen
  ose_Entrance                 = 2;     // entrance opening (sounds like "boing")
  ose_LevelIntro               = 3;     // level intro (the "let's go" sound)
  ose_SkillAssign              = 4;     // the sound you get when you assign a skill to lemming
  ose_OhNo                     = 5;     // the "oh no" sound when a lemming is about to explode
  ose_ElectroTrap              = 6;     // sound effect of the electrode trap and zap trap,
  ose_SquishingTrap            = 7;     // sound effect of the rock squishing trap, pillar squishing trap, and spikes trap
  ose_Splattering              = 8;     // the "aargh" sound when the lemming fall down too far and splatters
  ose_RopeTrap                 = 9;     // sound effect of the rope trap and slicer trap
  ose_HitsSteel                = 10;    // sound effect when a basher/miner/digger hits steel
  ose_Unknown                  = 11;    // ? (not sure where used in game)
  ose_Explosion                = 12;    // sound effect of a lemming explosion
  ose_SpinningTrap             = 13;    // sound effect of the spinning-trap-of-death, coal pits, and fire shooters (when a lemming touches the object and dies)
  ose_TenTonTrap               = 14;    // sound effect of the 10-ton trap
  ose_BearTrap                 = 15;    // sound effect of the bear trap
  ose_Exit                     = 16;    // sound effect of a lemming exiting
  ose_Drowning                 = 17;    // sound effect of a lemming dropping into water and drowning
  ose_BuilderWarning           = 18;    // sound effect for the last 3 bricks a builder is laying down
  ose_FireTrap                 = 19;
  ose_Slurp                    = 20;
  ose_Vaccuum                  = 21;
  ose_Weed                     = 22;

  ALIGNMENT_COUNT = 8; // 4 possible combinations of Flip + Invert + Rotate

type
  {-------------------------------------------------------------------------------
    This class describes interactive objects
  -------------------------------------------------------------------------------}
  TMetaObjectSizeSetting = (mos_None, mos_Horizontal, mos_Vertical, mos_Both);

  TObjectVariableProperties = record // For properties that vary based on flip / invert
    Image:         TBitmaps;
    Width:         Integer;
    Height:        Integer;
    TriggerLeft:   Integer;
    TriggerTop:    Integer;
    TriggerWidth:  Integer;
    TriggerHeight: Integer;
    Resizability:  TMetaObjectSizeSetting;
  end;

  TMetaObject = class
  private
  protected
    fGS    : String;
    fPiece  : String;
    fVariableInfo: array[0..ALIGNMENT_COUNT-1] of TObjectVariableProperties;
    fGeneratedVariableInfo: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fAnimationFrameCount          : Integer; // number of animations
    fWidth                        : Integer; // the width of the bitmap
    fHeight                       : Integer; // the height of the bitmap
    fTriggerLeft                  : Integer; // x-offset of triggerarea (if triggered)
    fTriggerTop                   : Integer; // y-offset of triggerarea (if triggered)
    fTriggerWidth                 : Integer; // width of triggerarea (if triggered)
    fTriggerHeight                : Integer; // height of triggerarea (if triggered)
    fTriggerEffect                : Integer; // ote_xxxx see dos doc
    fTriggerNext                  : Integer;
    fPreviewFrameIndex            : Integer; // index of preview (previewscreen)
    fSoundEffect                  : Integer; // ose_xxxx what sound to play
    fRandomStartFrame             : Boolean;
    fResizability                 : TMetaObjectSizeSetting;
    function GetIdentifier: String;
    function GetCanResize(aDir: TMetaObjectSizeSetting): Boolean;
    function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
    function GetVariableInfo(Flip, Invert, Rotate: Boolean): TObjectVariableProperties;
    procedure EnsureVariationMade(Flip, Invert, Rotate: Boolean);
    procedure DeriveVariation(Flip, Invert, Rotate: Boolean);
    procedure MarkAllUnmade;
  public
    procedure Assign(Source: TMetaObject);
    constructor Create;
    destructor Destroy; override;
  published
    property Identifier : String read GetIdentifier;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;
    property AnimationFrameCount      : Integer read fAnimationFrameCount write fAnimationFrameCount;
    property Width                    : Integer read fWidth write fWidth;
    property Height                   : Integer read fHeight write fHeight;
    property TriggerLeft              : Integer read fTriggerLeft write fTriggerLeft;
    property TriggerTop               : Integer read fTriggerTop write fTriggerTop;
    property TriggerWidth             : Integer read fTriggerWidth write fTriggerWidth;
    property TriggerHeight            : Integer read fTriggerHeight write fTriggerHeight;
    property TriggerEffect            : Integer read fTriggerEffect write fTriggerEffect;
    property TriggerNext              : Integer read fTriggerNext write fTriggerNext;
    property PreviewFrameIndex        : Integer read fPreviewFrameIndex write fPreviewFrameIndex;
    property SoundEffect              : Integer read fSoundEffect write fSoundEffect;
    property RandomStartFrame         : Boolean read fRandomStartFrame write fRandomStartFrame;
    property Resizability             : TMetaObjectSizeSetting read fResizability write fResizability;
    property CanResizeHorizontal      : Boolean index mos_Horizontal read GetCanResize;
    property CanResizeVertical        : Boolean index mos_Vertical read GetCanResize;
  end;

  TMetaObjects = class(TObjectList)
    private
      function GetItem(Index: Integer): TMetaObject;
    public
      constructor Create;
      function Add: TMetaObject;
      function Insert(Index: Integer): TMetaObject;
      property Items[Index: Integer]: TMetaObject read GetItem; default;
      property List;
  end;

implementation

constructor TMetaObject.Create;
var
  i: Integer;
begin
  inherited;
  for i := 0 to ALIGNMENT_COUNT-1 do
    fVariableInfo[i].Image := TBitmaps.Create(true);
end;

destructor TMetaObject.Destroy;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
    fVariableInfo[i].Image.Free;
  inherited;
end;

procedure TMetaObject.Assign(Source: TMetaObject);
var
  M: TMetaObject absolute Source;
begin

  raise exception.Create('TMetaObject.Assign is not implemented!');

end;

function TMetaObject.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

function TMetaObject.GetCanResize(aDir: TMetaObjectSizeSetting): Boolean;
begin
  if fResizability = mos_none then
    Result := false
  else
    Result := (aDir = fResizability) or (fResizability = mos_Both);
end;

function TMetaObject.GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
begin
  Result := 0;
  if Flip then Inc(Result, 1);
  if Invert then Inc(Result, 2);
  if Rotate then Inc(Result, 4);
end;

function TMetaObject.GetVariableInfo(Flip, Invert, Rotate: Boolean): TObjectVariableProperties;
begin
  Result := fVariableInfo(GetImageIndex(Flip, Invert, Rotate));
end;

procedure TMetaObject.MarkAllUnmade;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
    fGeneratedVariableInfo[i] := false;
end;

procedure TMetaObject.EnsureVariationMade(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if not fGeneratedVariableInfo[i] then
    DeriveVariation(Flip, Invert, Rotate);
end;

procedure TMetaObject.DeriveVariation(Flip, Invert, Rotate: Boolean);
var
  Index: Integer;
  i: Integer;

  Src, Dst: TBitmap32;

  procedure Reset;
  begin
    i := 0;
  end;

  function SetImages: Boolean;
  var
    n: Integer;
  begin
    Result := i < fVariableInfo.Image[0].Count;
    if Result then
    begin
      Src := fVariableInfo.Image[0][i];
      if i < fVariableInfo.Image[Index].Count then
        Dst := fVariableInfo.Image[Index].Add
      else
        Dst := fVariableInfo.Image[Index][i];
      Inc(i);
    end else begin
      for n := fVariableInfo.Image[Index].Count-1 downto i do
        fVariableInfo.Image[Index].Delete(n);
    end;
  end;
begin
  Index := GetImageIndex(Flip, Invert, Rotate);

  Reset;
  while SetImages do
    Dst.Assign(Src);

  if Rotate then
  begin
    Reset;
    while SetImages do
      Dst.Rotate90;
  end;

  if Flip then
  begin
    Reset;
    while SetImages do
      Dst.FlipHorz;
  end;

  if Invert then
  begin
    Reset;
    while SetImages do
      Dst.FlipVert;
  end;
end;

{ TMetaObjects }

constructor TMetaObjects.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TMetaObjects.Add: TMetaObject;
begin
  Result := TMetaObject.Create;
  inherited Add(Result);
end;

function TMetaObjects.Insert(Index: Integer): TMetaObject;
begin
  Result := TMetaObject.Create;
  inherited Insert(Index, Result);
end;

function TMetaObjects.GetItem(Index: Integer): TMetaObject;
begin
  Result := inherited Get(Index);
end;

end.


