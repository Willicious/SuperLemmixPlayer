{$include lem_directives.inc}

unit LemGadgetsMeta;

interface

uses
  GR32, LemTypes,
  PngInterface, LemStrings, LemNeoTheme,
  Classes, SysUtils, StrUtils,
  Contnrs, LemNeoParser,
  LemGadgetAnimation;

const
  // Object Animation Types
  oat_None                     = 0;    // the object is not animated
  oat_Triggered                = 1;    // the object is triggered by a lemming
  oat_Continuous               = 2;    // the object is always moving
  oat_Once                     = 3;    // the object is animated once at the beginning (entrance only)

  ALIGNMENT_COUNT = 8; // 4 possible combinations of Flip + Invert + Rotate

type

  TGadgetMetaAccessor = class;  // predefinition so it can be used in TMetaObject despite being defined later

  TGadgetMetaSizeSetting = (mos_None, mos_Horizontal, mos_Vertical, mos_Both);

  TGadgetVariableProperties = record // For properties that vary based on flip / invert
    Animations: TGadgetAnimations;
    TriggerLeft:      Integer;
    TriggerTop:       Integer;
    TriggerWidth:     Integer;
    TriggerHeight:    Integer;
    Resizability:   TGadgetMetaSizeSetting;
  end;
  PGadgetVariableProperties = ^TGadgetVariableProperties;

  TGadgetMetaProperty = (ov_Frames, ov_Width, ov_Height,
                         ov_TriggerLeft, ov_TriggerTop, ov_TriggerWidth,
                         ov_TriggerHeight, ov_TriggerEffect, ov_KeyFrame);
                         // Integer properties only.

  TGadgetMetaInfo = class
  protected
    fGS    : String;
    fPiece  : String;
    fVariableInfo: array[0..ALIGNMENT_COUNT-1] of TGadgetVariableProperties;
    fGeneratedVariableInfo: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fGeneratedVariableImage: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fInterfaces: array[0..ALIGNMENT_COUNT-1] of TGadgetMetaAccessor;
    fFrameCount                   : Integer; // number of animations
    fWidth                        : Integer; // the width of the bitmap
    fHeight                       : Integer; // the height of the bitmap
    fTriggerLeft                  : Integer; // x-offset of triggerarea (if triggered)
    fTriggerTop                   : Integer; // y-offset of triggerarea (if triggered)
    fTriggerWidth                 : Integer; // width of triggerarea (if triggered)
    fTriggerHeight                : Integer; // height of triggerarea (if triggered)
    fTriggerEffect                : Integer; // ote_xxxx see dos doc
    fKeyFrame                     : Integer;
    fPreviewFrameIndex            : Integer; // index of preview (previewscreen)
    fSoundEffect                  : String;  // filename of sound to play

    fResizability                 : TGadgetMetaSizeSetting;
    fCyclesSinceLastUse: Integer; // to improve TNeoPieceManager.Tidy

    function GetIdentifier: String;
    function GetCanResize(Flip, Invert, Rotate: Boolean; aDir: TGadgetMetaSizeSetting): Boolean;
    function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
    function GetVariableInfo(Flip, Invert, Rotate: Boolean): TGadgetVariableProperties;
    procedure EnsureVariationMade(Flip, Invert, Rotate: Boolean);
    procedure DeriveVariation(Flip, Invert, Rotate: Boolean);
    function GetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty): Integer;
    procedure SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty; aValue: Integer);
    function GetResizability(Flip, Invert, Rotate: Boolean): TGadgetMetaSizeSetting;
    procedure SetResizability(Flip, Invert, Rotate: Boolean; aValue: TGadgetMetaSizeSetting);
    function GetAnimations(Flip, Invert, Rotate: Boolean): TGadgetAnimations;
    procedure ClearImages;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load(aCollection, aPiece: String; aTheme: TNeoTheme);

    function GetInterface(Flip, Invert, Rotate: Boolean): TGadgetMetaAccessor;

    procedure Assign(Source: TGadgetMetaInfo);

    procedure MarkAllUnmade;
    procedure MarkMetaDataUnmade;

    property Identifier : String read GetIdentifier;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;

    property Animations[Flip, Invert, Rotate: Boolean]: TGadgetAnimations read GetAnimations;

    property Width[Flip, Invert, Rotate: Boolean]        : Integer index ov_Width read GetVariableProperty;
    property Height[Flip, Invert, Rotate: Boolean]       : Integer index ov_Height read GetVariableProperty;
    property TriggerLeft[Flip, Invert, Rotate: Boolean]  : Integer index ov_TriggerLeft read GetVariableProperty write SetVariableProperty;
    property TriggerTop[Flip, Invert, Rotate: Boolean]   : Integer index ov_TriggerTop read GetVariableProperty write SetVariableProperty;
    property TriggerWidth[Flip, Invert, Rotate: Boolean] : Integer index ov_TriggerWidth read GetVariableProperty write SetVariableProperty;
    property TriggerHeight[Flip, Invert, Rotate: Boolean]: Integer index ov_TriggerHeight read GetVariableProperty write SetVariableProperty;
    property TriggerEffect: Integer read fTriggerEffect write fTriggerEffect; // used by level loading / saving code
    
    property Resizability[Flip, Invert, Rotate: Boolean]: TGadgetMetaSizeSetting read GetResizability write SetResizability;
    property CanResizeHorizontal[Flip, Invert, Rotate: Boolean]: Boolean index mos_Horizontal read GetCanResize;
    property CanResizeVertical[Flip, Invert, Rotate: Boolean]: Boolean index mos_Vertical read GetCanResize;

    property CyclesSinceLastUse: Integer read fCyclesSinceLastUse write fCyclesSinceLastUse;
  end;

  TGadgetMetaAccessor = class
    // This is basically an abstraction layer for the flip, invert, rotate seperations. Instead of having to
    // specify them every time the TMetaObject is referenced, a TMetaObjectInterface created for that specific
    // combination of TMetaObject and orientation settings can be used, making the code tidier.
    private
      fGadgetMetaInfo: TGadgetMetaInfo;
      fFlip: Boolean;
      fInvert: Boolean;
      fRotate: Boolean;
      function GetIntegerProperty(aProp: TGadgetMetaProperty): Integer;
      procedure SetIntegerProperty(aProp: TGadgetMetaProperty; aValue: Integer);
      function GetResizability: TGadgetMetaSizeSetting;
      procedure SetResizability(aValue: TGadgetMetaSizeSetting);
      function GetCanResize(aDir: TGadgetMetaSizeSetting): Boolean;
      function GetAnimations: TGadgetAnimations;
      function GetSoundEffect: String;
      procedure SetSoundEffect(aValue: String);
    public
      constructor Create(aMetaObject: TGadgetMetaInfo; Flip, Invert, Rotate: Boolean);

      property Animations: TGadgetAnimations read GetAnimations;

      property FrameCount: Integer index ov_Frames read GetIntegerProperty write SetIntegerProperty;
      property Width: Integer index ov_Width read GetIntegerProperty;
      property Height: Integer index ov_Height read GetIntegerProperty;
      property TriggerLeft: Integer index ov_TriggerLeft read GetIntegerProperty write SetIntegerProperty;
      property TriggerTop: Integer index ov_TriggerTop read GetIntegerProperty write SetIntegerProperty;
      property TriggerWidth: Integer index ov_TriggerWidth read GetIntegerProperty write SetIntegerProperty;
      property TriggerHeight: Integer index ov_TriggerHeight read GetIntegerProperty write SetIntegerProperty;
      property TriggerEffect: Integer index ov_TriggerEffect read GetIntegerProperty write SetIntegerProperty;
      property KeyFrame: Integer index ov_KeyFrame read GetIntegerProperty write SetIntegerProperty;
      property SoundEffect: String read GetSoundEffect write SetSoundEffect;

      property Resizability             : TGadgetMetaSizeSetting read GetResizability write SetResizability;
      property CanResizeHorizontal      : Boolean index mos_Horizontal read GetCanResize;
      property CanResizeVertical        : Boolean index mos_Vertical read GetCanResize;
  end;

  TGadgetMetaInfoList = class(TObjectList)
    private
      function GetItem(Index: Integer): TGadgetMetaInfo;
    public
      constructor Create;
      function Add: TGadgetMetaInfo; overload;
      procedure Add(MO: TGadgetMetaInfo); overload;
      function Insert(Index: Integer): TGadgetMetaInfo;
      property Items[Index: Integer]: TGadgetMetaInfo read GetItem; default;
      property List;
  end;

implementation

constructor TGadgetMetaInfo.Create;
var
  i: Integer;
begin
  inherited;
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fVariableInfo[i].Animations := TGadgetAnimations.Create;
    fInterfaces[i] := nil;
  end;
end;

destructor TGadgetMetaInfo.Destroy;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fVariableInfo[i].Animations.Free;
    fInterfaces[i].Free;
  end;
  inherited;
end;

procedure TGadgetMetaInfo.Assign(Source: TGadgetMetaInfo);
var
  M: TGadgetMetaInfo absolute Source;
begin

  raise exception.Create('TMetaObject.Assign is not implemented!');

end;

procedure TGadgetMetaInfo.ClearImages;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
    fVariableInfo[i].Animations.Clear;
end;

procedure TGadgetMetaInfo.Load(aCollection,aPiece: String; aTheme: TNeoTheme);
var
  Parser: TParser;
  Sec, NewSec: TParserSection;

  GadgetAccessor: TGadgetMetaAccessor;
  NewAnim: TGadgetAnimation;
begin
  fGS := Lowercase(aCollection);
  fPiece := Lowercase(aPiece);
  GadgetAccessor := GetInterface(false, false, false);

  Parser := TParser.Create;
  try
    ClearImages;

    if not DirectoryExists(AppPath + SFStyles + aCollection + SFPiecesObjects) then
      raise Exception.Create('TMetaObject.Load: Collection "' + aCollection + '" does not exist or does not have objects. (' + aPiece + ')');
    SetCurrentDir(AppPath + SFStyles + aCollection + SFPiecesObjects);

    Parser.LoadFromFile(aPiece + '.nxmo');
    Sec := Parser.MainSection;

    // Trigger effects
    if Sec.Line['exit'] <> nil then fTriggerEffect := 1;
    if Sec.Line['force_left'] <> nil then fTriggerEffect := 2;
    if Sec.Line['force_right'] <> nil then fTriggerEffect := 3;
    if Sec.Line['trap'] <> nil then fTriggerEffect := 4;
    if Sec.Line['water'] <> nil then fTriggerEffect := 5;
    if Sec.Line['fire'] <> nil then fTriggerEffect := 6;
    if Sec.Line['one_way_left'] <> nil then fTriggerEffect := 7;
    if Sec.Line['one_way_right'] <> nil then fTriggerEffect := 8;
    // 9, 10 are unused
    if Sec.Line['teleporter'] <> nil then fTriggerEffect := 11;
    if Sec.Line['receiver'] <> nil then fTriggerEffect := 12;
    // 13 is unused
    if Sec.Line['pickup_skill'] <> nil then fTriggerEffect := 14;
    if Sec.Line['locked_exit'] <> nil then fTriggerEffect := 15;
    // 16 is unused
    if Sec.Line['button'] <> nil then fTriggerEffect := 17;
    // 18 is unused
    if Sec.Line['one_way_down'] <> nil then fTriggerEffect := 19;
    if Sec.Line['updraft'] <> nil then fTriggerEffect := 20;
    if Sec.Line['splitter'] <> nil then fTriggerEffect := 21;
    // 22 is unused
    if Sec.Line['window'] <> nil then fTriggerEffect := 23;
    // 24, 25, 26 are unused
    if Sec.Line['splatpad'] <> nil then fTriggerEffect := 27;
    // 28, 29 are unused
    if Sec.Line['moving_background'] <> nil then fTriggerEffect := 30;
    if Sec.Line['single_use_trap'] <> nil then fTriggerEffect := 31;
    // 32 is unused
    if Sec.Line['one_way_up'] <> nil then fTriggerEffect := 33;

    if Sec.Section['PRIMARY_ANIMATION'] = nil then
    begin
      // Translate older format, then load it normally.
      NewSec := Sec.SectionList.Add('PRIMARY_ANIMATION');

      NewSec.AddLine('frames', Sec.LineNumeric['frames']);

      if Sec.Line['horizontal_strip'] <> nil then
        NewSec.AddLine('horizontal_strip');

      if Sec.Line['random_start_frame'] <> nil then
        NewSec.AddLine('initial_frame', -1)
      else if Sec.Line['initial_frame'] = nil then
        NewSec.AddLine('initial_frame', Sec.LineNumeric['preview_frame'])  // backwards-compatible
      else
        NewSec.AddLine('initial_frame', Sec.LineNumeric['initial_frame']); // more accurate name, and it's what animations use

      NewSec.AddLine('cut_top', Sec.LineNumeric['cut_top']);
      NewSec.AddLine('cut_right', Sec.LineNumeric['cut_right']);
      NewSec.AddLine('cut_bottom', Sec.LineNumeric['cut_bottom']);
      NewSec.AddLine('cut_left', Sec.LineNumeric['cut_left']);
    end;

    NewAnim := TGadgetAnimation.Create(0, 0);
    GadgetAccessor.Animations.AddPrimary(NewAnim);
    NewAnim.Load(aCollection, aPiece, Sec.Section['PRIMARY_ANIMATION'], aTheme);

    Sec.DoForEachSection('ANIMATION',
      procedure (aSection: TParserSection; const aIteration: Integer)
      begin
        NewAnim := TGadgetAnimation.Create(GadgetAccessor.Animations.PrimaryAnimation.Width, GadgetAccessor.Animations.PrimaryAnimation.Height);
        GadgetAccessor.Animations.Add(NewAnim);
        NewAnim.Load(aCollection, aPiece, aSection, aTheme);
      end
    );

    GadgetAccessor.TriggerLeft := Sec.LineNumeric['trigger_x'];
    GadgetAccessor.TriggerTop := Sec.LineNumeric['trigger_y'];
    GadgetAccessor.TriggerWidth := Sec.LineNumeric['trigger_width'];
    GadgetAccessor.TriggerHeight := Sec.LineNumeric['trigger_height'];

    if fTriggerEffect = 12 then // Receiver  /// Is the width / height even used anymore?
    begin
      if GadgetAccessor.TriggerWidth < 1 then
        GadgetAccessor.TriggerWidth := 1;
      if GadgetAccessor.TriggerHeight < 1 then
        GadgetAccessor.TriggerHeight := 1;
    end;

    fSoundEffect := Sec.LineTrimString['sound'];

    fKeyFrame := Sec.LineNumeric['key_frame']; // this is almost purely a physics property, so should not go under animations

    if Sec.Line['resize_both'] <> nil then
      GadgetAccessor.Resizability := mos_Both
    else if Sec.Line['resize_horizontal'] <> nil then // This is messy. Should probably take Nepster's advice and split these properly into two Boolean values.
    begin
      if Sec.Line['resize_vertical'] <> nil then
        GadgetAccessor.Resizability := mos_Both
      else
        GadgetAccessor.Resizability := mos_Horizontal;
    end else begin
      if Sec.Line['resize_vertical'] <> nil then
        GadgetAccessor.Resizability := mos_Vertical
      else
        GadgetAccessor.Resizability := mos_None;
    end;
  finally
    Parser.Free;
  end;
end;

function TGadgetMetaInfo.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

function TGadgetMetaInfo.GetCanResize(Flip, Invert, Rotate: Boolean; aDir: TGadgetMetaSizeSetting): Boolean;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  if fVariableInfo[i].Resizability = mos_none then
    Result := false
  else
    Result := (aDir = fVariableInfo[i].Resizability) or (fVariableInfo[i].Resizability = mos_Both);
end;

function TGadgetMetaInfo.GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
begin
  Result := 0;
  if Flip then Inc(Result, 1);
  if Invert then Inc(Result, 2);
  if Rotate then Inc(Result, 4);
end;

function TGadgetMetaInfo.GetVariableInfo(Flip, Invert, Rotate: Boolean): TGadgetVariableProperties;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  Result := fVariableInfo[GetImageIndex(Flip, Invert, Rotate)];
end;

procedure TGadgetMetaInfo.MarkAllUnmade;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fGeneratedVariableInfo[i] := false;
    fGeneratedVariableImage[i] := false;
  end;
end;

procedure TGadgetMetaInfo.MarkMetaDataUnmade;
var
  i: Integer;
begin
  // There may be times where we want to wipe the metadata without wiping the images.
  for i := 0 to ALIGNMENT_COUNT-1 do
    fGeneratedVariableInfo[i] := false;
end;

procedure TGadgetMetaInfo.EnsureVariationMade(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if not (fGeneratedVariableInfo[i] and fGeneratedVariableImage[i]) then
    DeriveVariation(Flip, Invert, Rotate);
end;

procedure TGadgetMetaInfo.DeriveVariation(Flip, Invert, Rotate: Boolean);
var
  Index: Integer;

  SrcRec: TGadgetVariableProperties;
  DstRec: PGadgetVariableProperties;
const
  NO_POSITION_ADJUST = [7, 8, 19]; // OWL, OWR, OWD arrows

  procedure Clone(Src, Dst: PGadgetVariableProperties);
  var
    AnimRef: TGadgetAnimations;
  begin
    AnimRef := Dst.Animations;
    Dst^ := Src^;
    Dst.Animations := AnimRef;

    Dst.Animations.Clone(Src.Animations);
  end;
begin
  Index := GetImageIndex(Flip, Invert, Rotate);

  fGeneratedVariableImage[Index] := true;
  fGeneratedVariableInfo[Index] := true;

  if Index = 0 then Exit;

  SrcRec := fVariableInfo[0];
  DstRec := @fVariableInfo[Index];

  Clone(@SrcRec, @DstRec);

  if Rotate then
  begin
    DstRec.Animations.Rotate90;

    // Swap and adjust trigger area coordinates / dimensions
    DstRec.TriggerLeft := SrcRec.Animations.PrimaryAnimation.Height - SrcRec.TriggerTop - SrcRec.TriggerHeight;
    DstRec.TriggerTop := SrcRec.TriggerLeft {- SrcRec.TriggerWidth};
    if not (fTriggerEffect in NO_POSITION_ADJUST) then
    begin
      DstRec.TriggerLeft := DstRec.TriggerLeft + 4;
      DstRec.TriggerTop := DstRec.TriggerTop + 5;
    end;
    DstRec.TriggerWidth := SrcRec.TriggerHeight;
    DstRec.TriggerHeight := SrcRec.TriggerWidth;

    if SrcRec.Resizability = mos_Horizontal then
      DstRec.Resizability := mos_Vertical
    else if SrcRec.Resizability = mos_Vertical then
      DstRec.Resizability := mos_Horizontal;
  end;

  if Flip then
  begin
    DstRec.Animations.Flip;

    // Flip trigger area X coordinate
    DstRec.TriggerLeft := DstRec.Animations.PrimaryAnimation.Width - DstRec.TriggerLeft - DstRec.TriggerWidth;
  end;

  if Invert then
  begin
    DstRec.Animations.Invert;

    // Flip and adjust trigger area Y coordinate
    DstRec.TriggerTop := DstRec.Animations.PrimaryAnimation.Height - DstRec.TriggerTop - DstRec.TriggerHeight;
    if not (fTriggerEffect in NO_POSITION_ADJUST) then
      DstRec.TriggerTop := DstRec.TriggerTop + 10;
  end;
end;

function TGadgetMetaInfo.GetInterface(Flip, Invert, Rotate: Boolean): TGadgetMetaAccessor;
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if fInterfaces[i] = nil then
    fInterfaces[i] := TGadgetMetaAccessor.Create(self, Flip, Invert, Rotate);
  Result := fInterfaces[i];
end;

function TGadgetMetaInfo.GetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty): Integer;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  with fVariableInfo[i] do
    case aProp of
      ov_Width: Result := Animations.PrimaryAnimation.Width;
      ov_Height: Result := Animations.PrimaryAnimation.Height;
      ov_TriggerLeft: Result := TriggerLeft;
      ov_TriggerTop: Result := TriggerTop;
      ov_TriggerWidth: Result := TriggerWidth;
      ov_TriggerHeight: Result := TriggerHeight;
      else raise Exception.Create('TMetaObject.GetVariableProperty called for an invalid property!');
    end;
end;

procedure TGadgetMetaInfo.SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty; aValue: Integer);
var
  i: Integer;
begin
  // In practice we should only ever write to the standard orientation. But here isn't the place
  // to restrict that.
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  with fVariableInfo[i] do
    case aProp of
      ov_TriggerLeft: TriggerLeft := aValue;
      ov_TriggerTop: TriggerTop := aValue;
      ov_TriggerWidth: TriggerWidth := aValue;
      ov_TriggerHeight: TriggerHeight := aValue;
      else raise Exception.Create('TMetaObject.SetVariableProperty called for an invalid property!');
    end;
  MarkMetaDataUnmade;
end;

function TGadgetMetaInfo.GetResizability(Flip, Invert, Rotate: Boolean): TGadgetMetaSizeSetting;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].Resizability;
end;

procedure TGadgetMetaInfo.SetResizability(Flip, Invert, Rotate: Boolean; aValue: TGadgetMetaSizeSetting);
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  fVariableInfo[i].Resizability := aValue;
end;

function TGadgetMetaInfo.GetAnimations(Flip, Invert, Rotate: Boolean): TGadgetAnimations;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].Animations;
end;

{ TMetaObjectInterface }

constructor TGadgetMetaAccessor.Create(aMetaObject: TGadgetMetaInfo; Flip, Invert, Rotate: Boolean);
begin
  inherited Create;
  fGadgetMetaInfo := aMetaObject;
  fFlip := Flip;
  fInvert := Invert;
  fRotate := Rotate;
end;

function TGadgetMetaAccessor.GetIntegerProperty(aProp: TGadgetMetaProperty): Integer;
begin
  // Access via properties where these exist to discriminate orientations (after all, that's the whole
  // point of the TMetaObjectInterface abstraction layer :P ). Otherwise, access the fields directly.
  case aProp of
    ov_Frames: Result := fGadgetMetaInfo.fFrameCount;
    ov_Width: Result := fGadgetMetaInfo.Width[fFlip, fInvert, fRotate];
    ov_Height: Result := fGadgetMetaInfo.Height[fFlip, fInvert, fRotate];
    ov_TriggerLeft: Result := fGadgetMetaInfo.TriggerLeft[fFlip, fInvert, fRotate];
    ov_TriggerTop: Result := fGadgetMetaInfo.TriggerTop[fFlip, fInvert, fRotate];
    ov_TriggerWidth: Result := fGadgetMetaInfo.TriggerWidth[fFlip, fInvert, fRotate];
    ov_TriggerHeight: Result := fGadgetMetaInfo.TriggerHeight[fFlip, fInvert, fRotate];
    ov_TriggerEffect: Result := fGadgetMetaInfo.fTriggerEffect;
    ov_KeyFrame: Result := fGadgetMetaInfo.fKeyFrame;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

procedure TGadgetMetaAccessor.SetIntegerProperty(aProp: TGadgetMetaProperty; aValue: Integer);
begin
  case aProp of
    ov_TriggerLeft: fGadgetMetaInfo.TriggerLeft[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerTop: fGadgetMetaInfo.TriggerTop[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerWidth: fGadgetMetaInfo.TriggerWidth[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerHeight: fGadgetMetaInfo.TriggerHeight[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerEffect: fGadgetMetaInfo.fTriggerEffect := aValue;
    ov_KeyFrame: fGadgetMetaInfo.fKeyFrame := aValue;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

function TGadgetMetaAccessor.GetSoundEffect: String;
begin
  Result := fGadgetMetaInfo.fSoundEffect;
end;

procedure TGadgetMetaAccessor.SetSoundEffect(aValue: String);
begin
  fGadgetMetaInfo.fSoundEffect := aValue;
end;

function TGadgetMetaAccessor.GetResizability: TGadgetMetaSizeSetting;
begin
  Result := fGadgetMetaInfo.Resizability[fFlip, fInvert, fRotate];
end;

procedure TGadgetMetaAccessor.SetResizability(aValue: TGadgetMetaSizeSetting);
begin
  fGadgetMetaInfo.Resizability[fFlip, fInvert, fRotate] := aValue;
end;

function TGadgetMetaAccessor.GetCanResize(aDir: TGadgetMetaSizeSetting): Boolean;
begin
  Result := false;
  case aDir of
    mos_Horizontal: Result := fGadgetMetaInfo.CanResizeHorizontal[fFlip, fInvert, fRotate];
    mos_Vertical: Result := fGadgetMetaInfo.CanResizeVertical[fFlip, fInvert, fRotate];
  end;
end;

function TGadgetMetaAccessor.GetAnimations: TGadgetAnimations;
begin
  Result := fGadgetMetaInfo.Animations[fFlip, fInvert, fRotate];
end;

{ TMetaObjects }

constructor TGadgetMetaInfoList.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);
end;

function TGadgetMetaInfoList.Add: TGadgetMetaInfo;
begin
  Result := TGadgetMetaInfo.Create;
  inherited Add(Result);
end;

procedure TGadgetMetaInfoList.Add(MO: TGadgetMetaInfo);
begin
  inherited Add(MO);
end;

function TGadgetMetaInfoList.Insert(Index: Integer): TGadgetMetaInfo;
begin
  Result := TGadgetMetaInfo.Create;
  inherited Insert(Index, Result);
end;

function TGadgetMetaInfoList.GetItem(Index: Integer): TGadgetMetaInfo;
begin
  Result := inherited Get(Index);
end;

end.


