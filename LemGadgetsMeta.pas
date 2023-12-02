{$include lem_directives.inc}

unit LemGadgetsMeta;

interface

uses
  Dialogs,
  GR32, LemTypes, UMisc,
  PngInterface, LemStrings, LemNeoTheme,
  Classes, SysUtils, StrUtils,
  Contnrs, LemNeoParser,
  LemAnimationSet,
  LemGadgetAnimation, LemGadgetsConstants;

const
  // Object Animation Types
  oat_None                     = 0;    // The object is not animated
  oat_Triggered                = 1;    // The object is triggered by a lemming
  oat_Continuous               = 2;    // The object is always moving
  oat_Once                     = 3;    // The object is animated once at the beginning (entrance only)

  ALIGNMENT_COUNT = 8; // 4 possible combinations of Flip + Invert + Rotate

type

  TGadgetMetaAccessor = class;  // Predefinition so it can be used in TMetaObject despite being defined later

  TGadgetVariableProperties = record // For properties that vary based on flip / invert
    Animations: TGadgetAnimations;
    TriggerLeft:      Integer;
    TriggerTop:       Integer;
    TriggerWidth:     Integer;
    TriggerHeight:    Integer;
    DefaultWidth:     Integer;
    DefaultHeight:    Integer;
    ResizeHorizontal: Boolean;
    ResizeVertical:   Boolean;
    DigitX:           Integer;
    DigitY:           Integer;
    DigitAlign:       Integer;
  end;
  PGadgetVariableProperties = ^TGadgetVariableProperties;

  TGadgetMetaProperty = (ov_Frames, ov_Width, ov_Height,
                         ov_TriggerLeft, ov_TriggerTop, ov_TriggerWidth,
                         ov_TriggerHeight, ov_DefaultWidth, ov_DefaultHeight,
                         ov_TriggerEffect, ov_KeyFrame, ov_DigitX,
                         ov_DigitY, ov_DigitAlign, ov_DigitMinLength);
                         // Integer properties only.

  TGadgetMetaInfo = class
  protected
    fGS    : String;
    fPiece  : String;
    fVariableInfo: array[0..ALIGNMENT_COUNT-1] of TGadgetVariableProperties;
    fGeneratedVariableInfo: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fGeneratedVariableImage: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fInterfaces: array[0..ALIGNMENT_COUNT-1] of TGadgetMetaAccessor;
    fFrameCount                   : Integer; // Number of animations
    fTriggerEffect                : Integer; // N.B. ote_xxxx see DOS doc
    fKeyFrame                     : Integer;
    fPreviewFrameIndex            : Integer; // Index of preview (previewscreen)
    fDigitMinLength               : Integer;

    fSoundActivate  : String;
    fSoundExhaust   : String;

    fCyclesSinceLastUse: Integer; // To improve TNeoPieceManager.Tidy

    function GetIdentifier: String;
    function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
    function GetVariableInfo(Flip, Invert, Rotate: Boolean): TGadgetVariableProperties;
    procedure EnsureAllVariationsMade;
    procedure EnsureVariationMade(Flip, Invert, Rotate: Boolean);
    procedure DeriveVariation(Flip, Invert, Rotate: Boolean);
    function GetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty): Integer;
    procedure SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty; aValue: Integer);
    function GetCanResizeHorizontal(Flip, Invert, Rotate: Boolean): Boolean;
    procedure SetCanResizeHorizontal(Flip, Invert, Rotate: Boolean; aValue: Boolean);
    function GetCanResizeVertical(Flip, Invert, Rotate: Boolean): Boolean;
    procedure SetCanResizeVertical(Flip, Invert, Rotate: Boolean; aValue: Boolean);
    function GetAnimations(Flip, Invert, Rotate: Boolean): TGadgetAnimations;
    procedure ClearImages;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load(aCollection, aPiece: String; aTheme: TNeoTheme);

    function GetInterface(Flip, Invert, Rotate: Boolean): TGadgetMetaAccessor;

    procedure Assign(Source: TGadgetMetaInfo);

    procedure Remask(aTheme: TNeoTheme);
    procedure RegenerateAutoAnims(aTheme: TNeoTheme; aAni: TBaseAnimationSet);

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
    property DefaultWidth[Flip, Invert, Rotate: Boolean]: Integer index ov_DefaultWidth read GetVariableProperty write SetVariableProperty;
    property DefaultHeight[Flip, Invert, Rotate: Boolean]: Integer index ov_DefaultHeight read GetVariableProperty write SetVariableProperty;
    property DigitX[Flip, Invert, Rotate: Boolean]       : Integer index ov_DigitX read GetVariableProperty write SetVariableProperty;
    property DigitY[Flip, Invert, Rotate: Boolean]       : Integer index ov_DigitY read GetVariableProperty write SetVariableProperty;
    property DigitAlign[Flip, Invert, Rotate: Boolean]   : Integer index ov_DigitAlign read GetVariableProperty write SetVariableProperty;
    property TriggerEffect: Integer read fTriggerEffect write fTriggerEffect; // Used by level loading / saving code

    property CanResizeHorizontal[Flip, Invert, Rotate: Boolean]: Boolean read GetCanResizeHorizontal write SetCanResizeHorizontal;
    property CanResizeVertical[Flip, Invert, Rotate: Boolean]: Boolean read GetCanResizeVertical write SetCanResizeVertical;

    property CyclesSinceLastUse: Integer read fCyclesSinceLastUse write fCyclesSinceLastUse;
  end;

  TGadgetMetaAccessor = class
    { This is basically an abstraction layer for the flip, invert, rotate seperations. Instead of having to
      specify them every time the TMetaObject is referenced, a TMetaObjectInterface created for that specific
      combination of TMetaObject and orientation settings can be used, making the code tidier. }
    private
      fGadgetMetaInfo: TGadgetMetaInfo;
      fFlip: Boolean;
      fInvert: Boolean;
      fRotate: Boolean;
      function GetIntegerProperty(aProp: TGadgetMetaProperty): Integer;
      procedure SetIntegerProperty(aProp: TGadgetMetaProperty; aValue: Integer);
      function GetCanResizeHorizontal: Boolean;
      procedure SetCanResizeHorizontal(const aValue: Boolean);
      function GetCanResizeVertical: Boolean;
      procedure SetCanResizeVertical(const aValue: Boolean);
      function GetAnimations: TGadgetAnimations;
      function GetSoundEffectActivate: String;
      procedure SetSoundEffectActivate(aValue: String);
      function GetSoundEffectExhaust: String;
      procedure SetSoundEffectExhaust(aValue: String);
      function GetDigitAnimation: TGadgetAnimation;
    public
      constructor Create(aMetaObject: TGadgetMetaInfo; Flip, Invert, Rotate: Boolean);

      procedure GetBoundsInfo(var aImageBounds: TRect; var aPhysicsBounds: TRect);

      property Animations: TGadgetAnimations read GetAnimations;

      property FrameCount: Integer index ov_Frames read GetIntegerProperty write SetIntegerProperty;
      property Width: Integer index ov_Width read GetIntegerProperty;
      property Height: Integer index ov_Height read GetIntegerProperty;
      property TriggerLeft: Integer index ov_TriggerLeft read GetIntegerProperty write SetIntegerProperty;
      property TriggerTop: Integer index ov_TriggerTop read GetIntegerProperty write SetIntegerProperty;
      property TriggerWidth: Integer index ov_TriggerWidth read GetIntegerProperty write SetIntegerProperty;
      property TriggerHeight: Integer index ov_TriggerHeight read GetIntegerProperty write SetIntegerProperty;
      property TriggerEffect: Integer index ov_TriggerEffect read GetIntegerProperty write SetIntegerProperty;
      property DefaultWidth: Integer index ov_DefaultWidth read GetIntegerProperty write SetIntegerProperty;
      property DefaultHeight: Integer index ov_DefaultHeight read GetIntegerProperty write SetIntegerProperty;
      property DigitX: Integer index ov_DigitX read GetIntegerProperty write SetIntegerProperty;
      property DigitY: Integer index ov_DigitY read GetIntegerProperty write SetIntegerProperty;
      property DigitAlign: Integer index ov_DigitAlign read GetIntegerProperty write SetIntegerProperty;
      property DigitMinLength: Integer index ov_DigitMinLength read GetIntegerProperty write SetIntegerProperty;
      property KeyFrame: Integer index ov_KeyFrame read GetIntegerProperty write SetIntegerProperty;
      property SoundEffectActivate: String read GetSoundEffectActivate write SetSoundEffectActivate;
      property SoundEffectExhaust: String read GetSoundEffectExhaust write SetSoundEffectExhaust;

      property CanResizeHorizontal      : Boolean read GetCanResizeHorizontal write SetCanResizeHorizontal;
      property CanResizeVertical        : Boolean read GetCanResizeVertical write SetCanResizeVertical;

      property DigitAnimation: TGadgetAnimation read GetDigitAnimation;
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

var
  LastWarningStyle: String;

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
  Sec: TParserSection;

  GadgetAccessor: TGadgetMetaAccessor;
  NewAnim: TGadgetAnimation;
  PrimaryWidth: Integer;
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
    if Lowercase(Sec.LineTrimString['effect']) = 'exit' then fTriggerEffect := DOM_EXIT;
    if Lowercase(Sec.LineTrimString['effect']) = 'forceleft' then fTriggerEffect := DOM_FORCELEFT;
    if Lowercase(Sec.LineTrimString['effect']) = 'forceright' then fTriggerEffect := DOM_FORCERIGHT;
    if Lowercase(Sec.LineTrimString['effect']) = 'trap' then fTriggerEffect := DOM_TRAP;
    if Lowercase(Sec.LineTrimString['effect']) = 'water' then fTriggerEffect := DOM_WATER;
    if Lowercase(Sec.LineTrimString['effect']) = 'fire' then fTriggerEffect := DOM_FIRE;
    if Lowercase(Sec.LineTrimString['effect']) = 'onewayleft' then fTriggerEffect := DOM_ONEWAYLEFT;
    if Lowercase(Sec.LineTrimString['effect']) = 'onewayright' then fTriggerEffect := DOM_ONEWAYRIGHT;
    if Lowercase(Sec.LineTrimString['effect']) = 'teleporter' then fTriggerEffect := DOM_TELEPORT;
    if Lowercase(Sec.LineTrimString['effect']) = 'receiver' then fTriggerEffect := DOM_RECEIVER;
    if Lowercase(Sec.LineTrimString['effect']) = 'pickupskill' then fTriggerEffect := DOM_PICKUP;
    if Lowercase(Sec.LineTrimString['effect']) = 'lockedexit' then fTriggerEffect := DOM_LOCKEXIT;
    if Lowercase(Sec.LineTrimString['effect']) = 'unlockbutton' then fTriggerEffect := DOM_BUTTON;
    if Lowercase(Sec.LineTrimString['effect']) = 'onewaydown' then fTriggerEffect := DOM_ONEWAYDOWN;
    if Lowercase(Sec.LineTrimString['effect']) = 'updraft' then fTriggerEffect := DOM_UPDRAFT;
    if Lowercase(Sec.LineTrimString['effect']) = 'splitter' then fTriggerEffect := DOM_FLIPPER;
    if Lowercase(Sec.LineTrimString['effect']) = 'entrance' then fTriggerEffect := DOM_WINDOW;
    if Lowercase(Sec.LineTrimString['effect']) = 'antisplatpad' then fTriggerEffect := DOM_NOSPLAT;
    if Lowercase(Sec.LineTrimString['effect']) = 'splatpad' then fTriggerEffect := DOM_SPLAT;
    if Lowercase(Sec.LineTrimString['effect']) = 'background' then fTriggerEffect := DOM_BACKGROUND;
    if Lowercase(Sec.LineTrimString['effect']) = 'traponce' then fTriggerEffect := DOM_TRAPONCE;
    if Lowercase(Sec.LineTrimString['effect']) = 'onewayup' then fTriggerEffect := DOM_ONEWAYUP;
    if Lowercase(Sec.LineTrimString['effect']) = 'paint' then fTriggerEffect := DOM_PAINT;
    if Lowercase(Sec.LineTrimString['effect']) = 'animation' then fTriggerEffect := DOM_ANIMATION;
    if Lowercase(Sec.LineTrimString['effect']) = 'animationonce' then fTriggerEffect := DOM_ANIMONCE;
    if Lowercase(Sec.LineTrimString['effect']) = 'blasticine' then fTriggerEffect := DOM_BLASTICINE;
    if Lowercase(Sec.LineTrimString['effect']) = 'vinewater' then fTriggerEffect := DOM_VINEWATER;
    if Lowercase(Sec.LineTrimString['effect']) = 'poison' then fTriggerEffect := DOM_POISON;
    if Lowercase(Sec.LineTrimString['effect']) = 'radiation' then fTriggerEffect := DOM_RADIATION;
    if Lowercase(Sec.LineTrimString['effect']) = 'slowfreeze' then fTriggerEffect := DOM_SLOWFREEZE;

    if Sec.Section['PRIMARY_ANIMATION'] = nil then
    begin
      if LastWarningStyle <> fGS then
      begin
        ShowMessage('Gadget ' + fGS + ':' + fPiece + ' is in pre-12.7 format. Please update your copy of this style, or if up to date, ask the style creator to fix.');
        LastWarningStyle := fGS;
      end;
      raise Exception.Create('Gadget ' + fGS + ':' + fPiece + ' is in pre-12.7 format. Please update your copy of this style, or if up to date, ask the style creator to fix.');
    end;

    NewAnim := TGadgetAnimation.Create(0, 0);
    GadgetAccessor.Animations.AddPrimary(NewAnim);
    NewAnim.Load(aCollection, aPiece, Sec.Section['PRIMARY_ANIMATION'], aTheme);

    fFrameCount := NewAnim.FrameCount;
    PrimaryWidth := NewAnim.Width; // Used later

    Sec.DoForEachSection('ANIMATION',
      procedure (aSection: TParserSection; const aIteration: Integer)
      begin
        NewAnim := TGadgetAnimation.Create(GadgetAccessor.Animations.PrimaryAnimation.Width, GadgetAccessor.Animations.PrimaryAnimation.Height);
        GadgetAccessor.Animations.Add(NewAnim);
        NewAnim.Load(aCollection, aPiece, aSection, aTheme);
      end
    );

    GadgetAccessor.Animations.SortByZIndex;

    GadgetAccessor.TriggerLeft := Sec.LineNumeric['trigger_x'];
    GadgetAccessor.TriggerTop := Sec.LineNumeric['trigger_y'];
    GadgetAccessor.TriggerWidth := Sec.LineNumeric['trigger_width'];
    GadgetAccessor.TriggerHeight := Sec.LineNumeric['trigger_height'];

    GadgetAccessor.DefaultWidth := Sec.LineNumeric['default_width'];
    GadgetAccessor.DefaultHeight := Sec.LineNumeric['default_height'];

    GadgetAccessor.DigitX := Sec.LineNumericDefault['digit_x', PrimaryWidth div 2];
    GadgetAccessor.DigitY := Sec.LineNumericDefault['digit_y', -6];

    if LeftStr(Lowercase(Sec.LineTrimString['digit_alignment']), 1) = 'l' then
      GadgetAccessor.DigitAlign := -1
    else if LeftStr(Lowercase(Sec.LineTrimString['digit_alignment']), 1) = 'r' then
      GadgetAccessor.DigitAlign := 1
    else
      GadgetAccessor.DigitAlign := 0;

    fDigitMinLength := Sec.LineNumericDefault['digit_length', 1];

    if Sec.Line['sound_activate'] = nil then
      fSoundActivate := Sec.LineTrimString['sound']
    else
      fSoundActivate := Sec.LineTrimString['sound_activate'];
    fSoundExhaust := Sec.LineTrimString['sound_exhaust'];

    fKeyFrame := Sec.LineNumeric['key_frame']; // This is almost purely a physics property, so should not go under animations

    if Sec.Line['resize_both'] <> nil then
    begin
      GadgetAccessor.CanResizeHorizontal := true;
      GadgetAccessor.CanResizeVertical := true;
    end else begin
      GadgetAccessor.CanResizeHorizontal := Sec.Line['resize_horizontal'] <> nil;
      GadgetAccessor.CanResizeVertical := Sec.Line['resize_vertical'] <> nil;
    end;

    if fTriggerEffect in [DOM_NONE, DOM_BACKGROUND, DOM_PAINT] then // No trigger area
    begin
      GadgetAccessor.TriggerWidth := 0;
      GadgetAccessor.TriggerHeight := 0;
    end;

    if fTriggerEffect in [DOM_RECEIVER, DOM_WINDOW] then // Trigger point only
    begin
      GadgetAccessor.TriggerWidth := 1;
      GadgetAccessor.TriggerHeight := 1;
    end;
  finally
    Parser.Free;
  end;
end;

function TGadgetMetaInfo.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
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

procedure TGadgetMetaInfo.RegenerateAutoAnims(aTheme: TNeoTheme;
  aAni: TBaseAnimationSet);
var
  SrcAnim: TGadgetAnimation;
  AnyChanged: Boolean;
  NameUpper: String;

  procedure GeneratePickupSkillIcons;
  var
    EraseAnim: TGadgetAnimation;
  begin
    if fVariableInfo[0].Animations['skill_mask'] = nil then
      EraseAnim := nil
    else
      EraseAnim := fVariableInfo[0].Animations['skill_mask'];

    SrcAnim.GeneratePickupSkills(aTheme, aAni, EraseAnim);
    AnyChanged := true;
  end;
begin
  AnyChanged := false;
  for SrcAnim in fVariableInfo[0].Animations do
  begin
    NameUpper := Uppercase(Trim(SrcAnim.Name));
    if NameUpper = '*PICKUP' then GeneratePickupSkillIcons;
  end;

  if AnyChanged then
    MarkAllUnmade;
end;

procedure TGadgetMetaInfo.Remask(aTheme: TNeoTheme);
var
  i: Integer;
begin
  if not fVariableInfo[0].Animations.AnyMasked then
    Exit;

  EnsureAllVariationsMade;

  for i := 0 to ALIGNMENT_COUNT-1 do
    fVariableInfo[i].Animations.Remask(aTheme);
end;

procedure TGadgetMetaInfo.EnsureAllVariationsMade;
var
  Flip, Invert, Rotate: Boolean;
begin
  for Flip in [true, false] do
    for Invert in [true, false] do
      for Rotate in [true, false] do
        EnsureVariationMade(Flip, Invert, Rotate);
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
  NO_POSITION_ADJUST = [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN, DOM_ONEWAYUP];

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

  Clone(@SrcRec, DstRec);

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

    DstRec.DefaultWidth := SrcRec.DefaultHeight;
    DstRec.DefaultHeight := SrcRec.DefaultWidth;

    DstRec.ResizeHorizontal := SrcRec.ResizeVertical;
    DstRec.ResizeVertical := SrcRec.ResizeHorizontal;

    // I can't imagine digits will work well rotated (at least without a vertical display option), but better at least try
    DstRec.DigitAlign := 0; // Not that any value really makes sense for this
    DstRec.DigitX := SrcRec.Animations.PrimaryAnimation.Height - SrcRec.DigitY - 1;
    DstRec.DigitY := SrcRec.DigitX;
  end;

  if Flip then
  begin
    DstRec.Animations.Flip;

    // Flip trigger area X coordinate
    DstRec.TriggerLeft := DstRec.Animations.PrimaryAnimation.Width - DstRec.TriggerLeft - DstRec.TriggerWidth;

    // Flip digit X coordinate and alignment
    DstRec.DigitX := DstRec.Animations.PrimaryAnimation.Width - DstRec.DigitX - 1;
    DstRec.DigitAlign := -DstRec.DigitAlign;
  end;

  if Invert then
  begin
    DstRec.Animations.Invert;

    // Flip and adjust trigger area Y coordinate
    DstRec.TriggerTop := DstRec.Animations.PrimaryAnimation.Height - DstRec.TriggerTop - DstRec.TriggerHeight;
    if not (fTriggerEffect in NO_POSITION_ADJUST) then
      DstRec.TriggerTop := DstRec.TriggerTop + 10;

    // Flip digit Y coordinate
    DstRec.DigitY := DstRec.Animations.PrimaryAnimation.Height - DstRec.DigitY - 1;
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
      ov_DefaultWidth: Result := DefaultWidth;
      ov_DefaultHeight: Result := DefaultHeight;
      ov_DigitX: Result := DigitX;
      ov_DigitY: Result := DigitY;
      ov_DigitAlign: Result := DigitAlign;
      else raise Exception.Create('TMetaObject.GetVariableProperty called for an invalid property!');
    end;
end;

procedure TGadgetMetaInfo.SetCanResizeHorizontal(Flip, Invert, Rotate,
  aValue: Boolean);
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  fVariableInfo[GetImageIndex(Flip, Invert, Rotate)].ResizeHorizontal := aValue;
end;

procedure TGadgetMetaInfo.SetCanResizeVertical(Flip, Invert, Rotate,
  aValue: Boolean);
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  fVariableInfo[GetImageIndex(Flip, Invert, Rotate)].ResizeVertical := aValue;
end;

procedure TGadgetMetaInfo.SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TGadgetMetaProperty; aValue: Integer);
var
  i: Integer;
begin
  // We should only ever write to the standard orientation, but here isn't the place to restrict that.
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  with fVariableInfo[i] do
    case aProp of
      ov_TriggerLeft: TriggerLeft := aValue;
      ov_TriggerTop: TriggerTop := aValue;
      ov_TriggerWidth: TriggerWidth := aValue;
      ov_TriggerHeight: TriggerHeight := aValue;
      ov_DefaultWidth: DefaultWidth := aValue;
      ov_DefaultHeight: DefaultHeight := aValue;
      ov_DigitX: DigitX := aValue;
      ov_DigitY: DigitY := aValue;
      ov_DigitAlign: DigitAlign := aValue;
      else raise Exception.Create('TMetaObject.SetVariableProperty called for an invalid property!');
    end;
  MarkMetaDataUnmade;
end;

function TGadgetMetaInfo.GetAnimations(Flip, Invert, Rotate: Boolean): TGadgetAnimations;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].Animations;
end;

function TGadgetMetaInfo.GetCanResizeHorizontal(Flip, Invert,
  Rotate: Boolean): Boolean;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  Result := fVariableInfo[GetImageIndex(Flip, Invert, Rotate)].ResizeHorizontal;
end;

function TGadgetMetaInfo.GetCanResizeVertical(Flip, Invert,
  Rotate: Boolean): Boolean;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  Result := fVariableInfo[GetImageIndex(Flip, Invert, Rotate)].ResizeVertical;
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
  { Access via properties where these exist to discriminate orientations (after all, that's the whole
    point of the TMetaObjectInterface abstraction layer :P ). Otherwise, access the fields directly. }
  case aProp of
    ov_Frames: Result := fGadgetMetaInfo.fFrameCount;
    ov_Width: Result := fGadgetMetaInfo.Width[fFlip, fInvert, fRotate];
    ov_Height: Result := fGadgetMetaInfo.Height[fFlip, fInvert, fRotate];
    ov_TriggerLeft: Result := fGadgetMetaInfo.TriggerLeft[fFlip, fInvert, fRotate];
    ov_TriggerTop: Result := fGadgetMetaInfo.TriggerTop[fFlip, fInvert, fRotate];
    ov_TriggerWidth: Result := fGadgetMetaInfo.TriggerWidth[fFlip, fInvert, fRotate];
    ov_TriggerHeight: Result := fGadgetMetaInfo.TriggerHeight[fFlip, fInvert, fRotate];
    ov_TriggerEffect: Result := fGadgetMetaInfo.fTriggerEffect;
    ov_DefaultWidth: Result := fGadgetMetaInfo.DefaultWidth[fFlip, fInvert, fRotate];
    ov_DefaultHeight: Result := fGadgetMetaInfo.DefaultHeight[fFlip, fInvert, fRotate];
    ov_DigitX: Result := fGadgetMetaInfo.DigitX[fFlip, fInvert, fRotate];
    ov_DigitY: Result := fGadgetMetaInfo.DigitY[fFlip, fInvert, fRotate];
    ov_DigitAlign: Result := fGadgetMetaInfo.DigitAlign[fFlip, fInvert, fRotate];
    ov_DigitMinLength: Result := fGadgetMetaInfo.fDigitMinLength;
    ov_KeyFrame: Result := fGadgetMetaInfo.fKeyFrame;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

procedure TGadgetMetaAccessor.SetCanResizeHorizontal(const aValue: Boolean);
begin
  fGadgetMetaInfo.CanResizeHorizontal[fFlip, fInvert, fRotate] := aValue;
end;

procedure TGadgetMetaAccessor.SetCanResizeVertical(const aValue: Boolean);
begin
  fGadgetMetaInfo.CanResizeVertical[fFlip, fInvert, fRotate] := aValue;
end;

procedure TGadgetMetaAccessor.SetIntegerProperty(aProp: TGadgetMetaProperty; aValue: Integer);
begin
  case aProp of
    ov_TriggerLeft: fGadgetMetaInfo.TriggerLeft[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerTop: fGadgetMetaInfo.TriggerTop[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerWidth: fGadgetMetaInfo.TriggerWidth[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerHeight: fGadgetMetaInfo.TriggerHeight[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerEffect: fGadgetMetaInfo.fTriggerEffect := aValue;
    ov_DefaultWidth: fGadgetMetaInfo.DefaultWidth[fFlip, fInvert, fRotate] := aValue;
    ov_DefaultHeight: fGadgetMetaInfo.DefaultHeight[fFlip, fInvert, fRotate] := aValue;
    ov_DigitX: fGadgetMetaInfo.DigitX[fFlip, fInvert, fRotate] := aValue;
    ov_DigitY: fGadgetMetaInfo.DigitY[fFlip, fInvert, fRotate] := aValue;
    ov_DigitAlign: fGadgetMetaInfo.DigitAlign[fFlip, fInvert, fRotate] := aValue;
    ov_DigitMinLength: fGadgetMetaInfo.fDigitMinLength := aValue;
    ov_KeyFrame: fGadgetMetaInfo.fKeyFrame := aValue;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

function TGadgetMetaAccessor.GetSoundEffectActivate: String;
begin
  Result := fGadgetMetaInfo.fSoundActivate;
end;

procedure TGadgetMetaAccessor.SetSoundEffectActivate(aValue: String);
begin
  fGadgetMetaInfo.fSoundActivate := aValue;
end;

function TGadgetMetaAccessor.GetSoundEffectExhaust: String;
begin
  Result := fGadgetMetaInfo.fSoundExhaust;
end;

procedure TGadgetMetaAccessor.SetSoundEffectExhaust(aValue: String);
begin
  fGadgetMetaInfo.fSoundExhaust := aValue;
end;

function TGadgetMetaAccessor.GetDigitAnimation: TGadgetAnimation;
begin
  Result := fGadgetMetaInfo.Animations[false, false, false]['DIGITS'];
end;

function TGadgetMetaAccessor.GetAnimations: TGadgetAnimations;
begin
  Result := fGadgetMetaInfo.Animations[fFlip, fInvert, fRotate];
end;

procedure TGadgetMetaAccessor.GetBoundsInfo(var aImageBounds, aPhysicsBounds: TRect);
var
  AnimRect: TRect;
  i: Integer;
begin
  aPhysicsBounds := SizedRect(0, 0, Animations.PrimaryAnimation.Width, Animations.PrimaryAnimation.Height);
  aImageBounds := aPhysicsBounds;

  for i := 0 to Animations.Count-1 do
  begin
    AnimRect := SizedRect(Animations.Items[i].OffsetX, Animations.Items[i].OffsetY, Animations.Items[i].Width, Animations.Items[i].Height);
    aImageBounds := TRect.Union(aImageBounds, AnimRect);
  end;

  aPhysicsBounds.SetLocation(-aImageBounds.Left, -aImageBounds.Top);
  aImageBounds.SetLocation(0, 0);
end;

function TGadgetMetaAccessor.GetCanResizeHorizontal: Boolean;
begin
  Result := fGadgetMetaInfo.CanResizeHorizontal[fFlip, fInvert, fRotate];
end;

function TGadgetMetaAccessor.GetCanResizeVertical: Boolean;
begin
  Result := fGadgetMetaInfo.CanResizeVertical[fFlip, fInvert, fRotate];
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


