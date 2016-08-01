{$include lem_directives.inc}

unit LemMetaObject;

interface

uses
  GR32, LemTypes, LemNeoParser,
  PngInterface, LemStrings, LemNeoTheme,
  Classes, SysUtils, StrUtils,
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

  TMetaObjectInterface = class;  // predefinition so it can be used in TMetaObject despite being defined later

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
  PObjectVariableProperties = ^TObjectVariableProperties;

  TMetaObjectProperty = (ov_Frames, ov_Width, ov_Height, ov_TriggerLeft, ov_TriggerTop,
                         ov_TriggerWidth, ov_TriggerHeight, ov_TriggerEffect,
                         ov_KeyFrame, ov_PreviewFrame, ov_SoundEffect);
                         // Integer properties only.

  TMetaObject = class
  protected
    fGS    : String;
    fPiece  : String;
    fVariableInfo: array[0..ALIGNMENT_COUNT-1] of TObjectVariableProperties;
    fGeneratedVariableInfo: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fGeneratedVariableImage: array[0..ALIGNMENT_COUNT-1] of Boolean;
    fInterfaces: array[0..ALIGNMENT_COUNT-1] of TMetaObjectInterface;
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
    fSoundEffect                  : Integer; // ose_xxxx what sound to play
    fRandomStartFrame             : Boolean;
    fResizability                 : TMetaObjectSizeSetting;
    function GetIdentifier: String;
    function GetCanResize(Flip, Invert, Rotate: Boolean; aDir: TMetaObjectSizeSetting): Boolean;
    function GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
    function GetVariableInfo(Flip, Invert, Rotate: Boolean): TObjectVariableProperties;
    procedure EnsureVariationMade(Flip, Invert, Rotate: Boolean);
    procedure DeriveVariation(Flip, Invert, Rotate: Boolean);
    function GetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TMetaObjectProperty): Integer;
    procedure SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TMetaObjectProperty; aValue: Integer);
    function GetResizability(Flip, Invert, Rotate: Boolean): TMetaObjectSizeSetting;
    procedure SetResizability(Flip, Invert, Rotate: Boolean; aValue: TMetaObjectSizeSetting);
    function GetImages(Flip, Invert, Rotate: Boolean): TBitmaps;
    procedure ClearImages;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load(aCollection, aPiece: String; aTheme: TNeoTheme);

    function GetInterface(Flip, Invert, Rotate: Boolean): TMetaObjectInterface;

    procedure Assign(Source: TMetaObject);

    procedure MarkAllUnmade;
    procedure MarkMetaDataUnmade;

    property Identifier : String read GetIdentifier;
    property GS     : String read fGS write fGS;
    property Piece  : String read fPiece write fPiece;

    property Images[Flip, Invert, Rotate: Boolean]: TBitmaps read GetImages;

    property Width[Flip, Invert, Rotate: Boolean]        : Integer index ov_Width read GetVariableProperty;
    property Height[Flip, Invert, Rotate: Boolean]       : Integer index ov_Height read GetVariableProperty;
    property TriggerLeft[Flip, Invert, Rotate: Boolean]  : Integer index ov_TriggerLeft read GetVariableProperty write SetVariableProperty;
    property TriggerTop[Flip, Invert, Rotate: Boolean]   : Integer index ov_TriggerTop read GetVariableProperty write SetVariableProperty;
    property TriggerWidth[Flip, Invert, Rotate: Boolean] : Integer index ov_TriggerWidth read GetVariableProperty write SetVariableProperty;
    property TriggerHeight[Flip, Invert, Rotate: Boolean]: Integer index ov_TriggerHeight read GetVariableProperty write SetVariableProperty;
    
    property Resizability[Flip, Invert, Rotate: Boolean]: TMetaObjectSizeSetting read GetResizability write SetResizability;
    property CanResizeHorizontal[Flip, Invert, Rotate: Boolean]: Boolean index mos_Horizontal read GetCanResize;
    property CanResizeVertical[Flip, Invert, Rotate: Boolean]: Boolean index mos_Vertical read GetCanResize;
  end;

  TMetaObjectInterface = class
    // This is basically an abstraction layer for the flip, invert, rotate seperations. Instead of having to
    // specify them every time the TMetaObject is referenced, a TMetaObjectInterface created for that specific
    // combination of TMetaObject and orientation settings can be used, making the code tidier.
    private
      fMetaObject: TMetaObject;
      fFlip: Boolean;
      fInvert: Boolean;
      fRotate: Boolean;
      function GetIntegerProperty(aProp: TMetaObjectProperty): Integer;
      procedure SetIntegerProperty(aProp: TMetaObjectProperty; aValue: Integer);
      function GetRandomStartFrame: Boolean;
      procedure SetRandomStartFrame(aValue: Boolean);
      function GetResizability: TMetaObjectSizeSetting;
      procedure SetResizability(aValue: TMetaObjectSizeSetting);
      function GetCanResize(aDir: TMetaObjectSizeSetting): Boolean;
      function GetImages: TBitmaps;
    public
      constructor Create(aMetaObject: TMetaObject; Flip, Invert, Rotate: Boolean);

      property Images: TBitmaps read GetImages;

      property FrameCount: Integer index ov_Frames read GetIntegerProperty write SetIntegerProperty;
      property Width: Integer index ov_Width read GetIntegerProperty;
      property Height: Integer index ov_Height read GetIntegerProperty;
      property TriggerLeft: Integer index ov_TriggerLeft read GetIntegerProperty write SetIntegerProperty;
      property TriggerTop: Integer index ov_TriggerTop read GetIntegerProperty write SetIntegerProperty;
      property TriggerWidth: Integer index ov_TriggerWidth read GetIntegerProperty write SetIntegerProperty;
      property TriggerHeight: Integer index ov_TriggerHeight read GetIntegerProperty write SetIntegerProperty;
      property TriggerEffect: Integer index ov_TriggerEffect read GetIntegerProperty write SetIntegerProperty;
      property KeyFrame: Integer index ov_KeyFrame read GetIntegerProperty write SetIntegerProperty;
      property PreviewFrame: Integer index ov_PreviewFrame read GetIntegerProperty write SetIntegerProperty;
      property RandomStartFrame: Boolean read GetRandomStartFrame write SetRandomStartFrame;
      property SoundEffect: Integer index ov_SoundEffect read GetIntegerProperty write SetIntegerProperty; // though sound effect shouldn't really be an integer, but we'll leave it as one until this new system works overall

      property Resizability             : TMetaObjectSizeSetting read GetResizability write SetResizability;
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

{uses
  LemObjects;} //for the DOM_ constants

constructor TMetaObject.Create;
var
  i: Integer;
begin
  inherited;
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fVariableInfo[i].Image := TBitmaps.Create(true);
    fInterfaces[i] := nil;
  end;
end;

destructor TMetaObject.Destroy;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fVariableInfo[i].Image.Free;
    fInterfaces[i].Free;
  end;
  inherited;
end;

procedure TMetaObject.Assign(Source: TMetaObject);
var
  M: TMetaObject absolute Source;
begin

  raise exception.Create('TMetaObject.Assign is not implemented!');

end;

procedure TMetaObject.ClearImages;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
    fVariableInfo[i].Image.Clear;
end;

procedure TMetaObject.Load(aCollection,aPiece: String; aTheme: TNeoTheme);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  O: TMetaObjectInterface;
  BMP: TBitmap32;
  MaskBMP: TBitmap32;

  DoHorizontal: Boolean;

  procedure LoadApplyMask;
  var
    MaskName, MaskColor: String;
  begin
    if aTheme = nil then Exit; // kludge, this situation should never arise in the first place
    MaskName := '';
    MaskColor := '';
    repeat
      Line := Parser.NextLine;

      if Line.Keyword = 'COLOR' then
        MaskColor := Line.Value;

      if Line.Keyword = 'NAME' then
        MaskName := Line.Value;
    until (Line.Keyword <> 'COLOR') and (Line.Keyword <> 'NAME');

    Parser.Back;

    if Lowercase(MaskName) = '*self' then
      TPngInterface.MaskImageFromImage(Bmp, Bmp, aTheme.Colors[MaskColor]) // yes, this works :D
    else
      TPngInterface.MaskImageFromFile(Bmp, aPiece + '_mask_' + MaskName + '.png', aTheme.Colors[MaskColor]);
  end;
begin
  fGS := Lowercase(aCollection);
  fPiece := Lowercase(aPiece);
  O := GetInterface(false, false, false);

  Parser := TNeoLemmixParser.Create;
  BMP := TBitmap32.Create;
  MaskBMP := nil; // only created if needed, but kept until procedure finishes in case its needed again
  try
    ClearImages;

    if not DirectoryExists(AppPath + SFStylesPieces + aCollection) then
    raise Exception.Create('TMetaObject.Load: Collection "' + aCollection + '" does not exist.');
    SetCurrentDir(AppPath + SFStylesPieces + aCollection + SFPiecesObjects);

    Parser.LoadFromFile(aPiece + '.nxob');
    TPngInterface.LoadPngFile(aPiece + '.png', BMP);

    DoHorizontal := false;

    repeat
      Line := Parser.NextLine;

      // Trigger effects
      if Line.Keyword = 'EXIT' then fTriggerEffect := 1;
      if Line.Keyword = 'OWL_FIELD' then fTriggerEffect := 2;
      if Line.Keyword = 'OWR_FIELD' then fTriggerEffect := 3;
      if Line.Keyword = 'TRAP' then fTriggerEffect := 4;
      if Line.Keyword = 'WATER' then fTriggerEffect := 5;
      if Line.Keyword = 'FIRE' then fTriggerEffect := 6;
      if Line.Keyword = 'OWL_ARROW' then fTriggerEffect := 7;
      if Line.Keyword = 'OWR_ARROW' then fTriggerEffect := 8;
      if Line.Keyword = 'TELEPORTER' then fTriggerEffect := 11;
      if Line.Keyword = 'RECEIVER' then fTriggerEffect := 12;
      if Line.Keyword = 'LEMMING' then fTriggerEffect := 13;
      if Line.Keyword = 'PICKUP' then fTriggerEffect := 14;
      if Line.Keyword = 'LOCKED_EXIT' then fTriggerEffect := 15;
      if Line.Keyword = 'BUTTON' then fTriggerEffect := 17;
      if Line.Keyword = 'RADIATION' then fTriggerEffect := 18;
      if Line.Keyword = 'OWD_ARROW' then fTriggerEffect := 19;
      if Line.Keyword = 'UPDRAFT' then fTriggerEffect := 20;
      if Line.Keyword = 'SPLITTER' then fTriggerEffect := 21;
      if Line.Keyword = 'SLOWFREEZE' then fTriggerEffect := 22;
      if Line.Keyword = 'WINDOW' then fTriggerEffect := 23;
      if Line.Keyword = 'ANIMATION' then fTriggerEffect := 24;
      if Line.Keyword = 'HINT' then fTriggerEffect := 25;
      if Line.Keyword = 'ANTISPLAT' then fTriggerEffect := 26;
      if Line.Keyword = 'SPLAT' then fTriggerEffect := 27;
      if Line.Keyword = 'BACKGROUND' then fTriggerEffect := 30;
      if Line.Keyword = 'TRAP_ONCE' then fTriggerEffect := 31;

      if Line.Keyword = 'FRAMES' then
        fFrameCount := Line.Numeric;

      if Line.Keyword = 'HORIZONTAL' then
        DoHorizontal := true;

      if Line.Keyword = 'TRIGGER_X' then
        O.TriggerLeft := Line.Numeric;

      if Line.Keyword = 'TRIGGER_Y' then
        O.TriggerTop := Line.Numeric;

      if Line.Keyword = 'TRIGGER_W' then
        O.TriggerWidth := Line.Numeric;

      if Line.Keyword = 'TRIGGER_H' then
        O.TriggerHeight := Line.Numeric;

      if Line.Keyword = 'SOUND' then
        fSoundEffect := Line.Numeric;

      if Line.Keyword = 'PREVIEW' then
        fPreviewFrameIndex := Line.Numeric;

      if Line.Keyword = 'KEYFRAME' then
        fKeyFrame := Line.Numeric;

      if Line.Keyword = 'RANDOM_FRAME' then
        fRandomStartFrame := true;

      if Line.Keyword = 'RESIZE' then
      begin
        if Lowercase(LeftStr(Line.Value, 3)) = 'hor' then  // kludgy, but allows both "horz" and "horizontal" and similar variations
          O.Resizability := mos_Horizontal;
        if Lowercase(LeftStr(Line.Value, 4)) = 'vert' then
          O.Resizability := mos_Vertical;
        if Lowercase(Line.Value) = 'both' then
          O.Resizability := mos_Both;
        if Lowercase(Line.Value) = 'none' then
          O.Resizability := mos_None;
      end;

      if Line.Keyword = 'MASK' then
        LoadApplyMask;
    until Line.Keyword = '';

    O.Images.Generate(BMP, fFrameCount, DoHorizontal);

    fVariableInfo[0].Width := O.Images[0].Width;   //TMetaObjectInterface's Width property is read-only
    fVariableInfo[0].Height := O.Images[0].Height;

  finally
    Parser.Free;
    BMP.Free;
    if MaskBMP <> nil then MaskBMP.Free;
  end;
end;

function TMetaObject.GetIdentifier: String;
begin
  Result := LowerCase(fGS + ':' + fPiece);
end;

function TMetaObject.GetCanResize(Flip, Invert, Rotate: Boolean; aDir: TMetaObjectSizeSetting): Boolean;
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

function TMetaObject.GetImageIndex(Flip, Invert, Rotate: Boolean): Integer;
begin
  Result := 0;
  if Flip then Inc(Result, 1);
  if Invert then Inc(Result, 2);
  if Rotate then Inc(Result, 4);
end;

function TMetaObject.GetVariableInfo(Flip, Invert, Rotate: Boolean): TObjectVariableProperties;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  Result := fVariableInfo[GetImageIndex(Flip, Invert, Rotate)];
end;

procedure TMetaObject.MarkAllUnmade;
var
  i: Integer;
begin
  for i := 0 to ALIGNMENT_COUNT-1 do
  begin
    fGeneratedVariableInfo[i] := false;
    fGeneratedVariableImage[i] := false;
  end;
end;

procedure TMetaObject.MarkMetaDataUnmade;
var
  i: Integer;
begin
  // There may be times where we want to wipe the metadata without wiping the images.
  for i := 0 to ALIGNMENT_COUNT-1 do
    fGeneratedVariableInfo[i] := false;
end;

procedure TMetaObject.EnsureVariationMade(Flip, Invert, Rotate: Boolean);
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if not (fGeneratedVariableInfo[i] and fGeneratedVariableImage[i]) then
    DeriveVariation(Flip, Invert, Rotate);
end;

procedure TMetaObject.DeriveVariation(Flip, Invert, Rotate: Boolean);
var
  Index: Integer;
  i: Integer;

  Src, Dst: TBitmap32;
  SrcRec: TObjectVariableProperties;
  DstRec: PObjectVariableProperties;

  TempInt: Integer;

  SkipImages: Boolean;

const
  NO_POSITION_ADJUST = [7, 8, 19]; // OWL, OWR, OWD arrows

  procedure CloneInfo(Src, Dst: PObjectVariableProperties);
  var
    BitmapRef: TBitmaps;
  begin
    BitmapRef := Dst.Image;
    Dst^ := Src^;
    Dst.Image := BitmapRef;
  end;

  procedure Reset;
  begin
    i := 0;
  end;

  function SetImages: Boolean;
  var
    n: Integer;
  begin
    if SkipImages then
    begin
      Result := false;
      Exit;
    end;

    Result := i < fVariableInfo[0].Image.Count;
    if Result then
    begin
      Src := fVariableInfo[0].Image[i];
      if i < fVariableInfo[Index].Image.Count then
        Dst := fVariableInfo[Index].Image[i]
      else begin
        Dst := TBitmap32.Create;
        fVariableInfo[Index].Image.Add(Dst);
      end;
      Inc(i);
    end else begin
      for n := fVariableInfo[Index].Image.Count-1 downto i do
        fVariableInfo[Index].Image.Delete(n);
    end;
  end;
begin
  Index := GetImageIndex(Flip, Invert, Rotate);

  SkipImages := fGeneratedVariableImage[Index];

  fGeneratedVariableImage[Index] := true;
  fGeneratedVariableInfo[Index] := true;

  if Index = 0 then Exit;

  SrcRec := fVariableInfo[0];
  DstRec := @fVariableInfo[Index];

  CloneInfo(@SrcRec, DstRec);

  Reset;
  while SetImages do
    Dst.Assign(Src);

  if Rotate then
  begin
    Reset;
    while SetImages do
      Dst.Rotate90;

    // Swap width / height
    DstRec.Width := SrcRec.Height;
    DstRec.Height := SrcRec.Width;

    // Swap and adjust trigger area coordinates / dimensions
    DstRec.TriggerLeft := SrcRec.Height - SrcRec.TriggerTop - SrcRec.TriggerHeight;
    DstRec.TriggerTop := SrcRec.TriggerLeft - SrcRec.TriggerWidth;
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
    Reset;
    while SetImages do
      Dst.FlipHorz;

    // Flip trigger area X coordinate
    DstRec.TriggerLeft := SrcRec.Width - SrcRec.TriggerLeft - SrcRec.TriggerWidth;
  end;

  if Invert then
  begin
    Reset;
    while SetImages do
      Dst.FlipVert;

    // Flip and adjust trigger area Y coordinate
    DstRec.TriggerTop := SrcRec.Height - SrcRec.TriggerTop - SrcRec.TriggerHeight;
    if not (fTriggerEffect in NO_POSITION_ADJUST) then
      DstRec.TriggerTop := DstRec.TriggerTop + 9;
  end;
end;

function TMetaObject.GetInterface(Flip, Invert, Rotate: Boolean): TMetaObjectInterface;
var
  i: Integer;
begin
  i := GetImageIndex(Flip, Invert, Rotate);
  if fInterfaces[i] = nil then
    fInterfaces[i] := TMetaObjectInterface.Create(self, Flip, Invert, Rotate);
  Result := fInterfaces[i];
end;

function TMetaObject.GetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TMetaObjectProperty): Integer;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  with fVariableInfo[i] do
    case aProp of
      ov_Width: Result := Width;
      ov_Height: Result := Height;
      ov_TriggerLeft: Result := TriggerLeft;
      ov_TriggerTop: Result := TriggerTop;
      ov_TriggerWidth: Result := TriggerWidth;
      ov_TriggerHeight: Result := TriggerHeight;
    end;
end;

procedure TMetaObject.SetVariableProperty(Flip, Invert, Rotate: Boolean; aProp: TMetaObjectProperty; aValue: Integer);
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
    end;
  MarkMetaDataUnmade;
end;

function TMetaObject.GetResizability(Flip, Invert, Rotate: Boolean): TMetaObjectSizeSetting;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].Resizability;
end;

procedure TMetaObject.SetResizability(Flip, Invert, Rotate: Boolean; aValue: TMetaObjectSizeSetting);
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  fVariableInfo[i].Resizability := aValue;
end;

function TMetaObject.GetImages(Flip, Invert, Rotate: Boolean): TBitmaps;
var
  i: Integer;
begin
  EnsureVariationMade(Flip, Invert, Rotate);
  i := GetImageIndex(Flip, Invert, Rotate);
  Result := fVariableInfo[i].Image;
end;

{ TMetaObjectInterface }

constructor TMetaObjectInterface.Create(aMetaObject: TMetaObject; Flip, Invert, Rotate: Boolean);
begin
  inherited Create;
  fMetaObject := aMetaObject;
  fFlip := Flip;
  fInvert := Invert;
  fRotate := Rotate;
end;

function TMetaObjectInterface.GetIntegerProperty(aProp: TMetaObjectProperty): Integer;
begin
  // Access via properties where these exist to discriminate orientations (after all, that's the whole
  // point of the TMetaObjectInterface abstraction layer :P ). Otherwise, access the fields directly.
  case aProp of
    ov_Frames: Result := fMetaObject.fFrameCount;
    ov_Width: Result := fMetaObject.Width[fFlip, fInvert, fRotate];
    ov_Height: Result := fMetaObject.Height[fFlip, fInvert, fRotate];
    ov_TriggerLeft: Result := fMetaObject.TriggerLeft[fFlip, fInvert, fRotate];
    ov_TriggerTop: Result := fMetaObject.TriggerTop[fFlip, fInvert, fRotate];
    ov_TriggerWidth: Result := fMetaObject.TriggerWidth[fFlip, fInvert, fRotate];
    ov_TriggerHeight: Result := fMetaObject.TriggerHeight[fFlip, fInvert, fRotate];
    ov_TriggerEffect: Result := fMetaObject.fTriggerEffect;
    ov_KeyFrame: Result := fMetaObject.fKeyFrame;
    ov_PreviewFrame: Result := fMetaObject.fPreviewFrameIndex;
    ov_SoundEffect: Result := fMetaObject.fSoundEffect;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

procedure TMetaObjectInterface.SetIntegerProperty(aProp: TMetaObjectProperty; aValue: Integer);
begin
  case aProp of
    ov_TriggerLeft: fMetaObject.TriggerLeft[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerTop: fMetaObject.TriggerTop[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerWidth: fMetaObject.TriggerWidth[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerHeight: fMetaObject.TriggerHeight[fFlip, fInvert, fRotate] := aValue;
    ov_TriggerEffect: fMetaObject.fTriggerEffect := aValue;
    ov_KeyFrame: fMetaObject.fKeyFrame := aValue;
    ov_PreviewFrame: fMetaObject.fPreviewFrameIndex := aValue;
    ov_SoundEffect: fMetaObject.fSoundEffect := aValue;
    else raise Exception.Create('TMetaObjectInterface.GetIntegerProperty called with invalid index!');
  end;
end;

function TMetaObjectInterface.GetRandomStartFrame: Boolean;
begin
  Result := fMetaObject.fRandomStartFrame;
end;

procedure TMetaObjectInterface.SetRandomStartFrame(aValue: Boolean);
begin
  fMetaObject.fRandomStartFrame := aValue;
end;

function TMetaObjectInterface.GetResizability: TMetaObjectSizeSetting;
begin
  Result := fMetaObject.Resizability[fFlip, fInvert, fRotate];
end;

procedure TMetaObjectInterface.SetResizability(aValue: TMetaObjectSizeSetting);
begin
  fMetaObject.Resizability[fFlip, fInvert, fRotate] := aValue;
end;

function TMetaObjectInterface.GetCanResize(aDir: TMetaObjectSizeSetting): Boolean;
begin
  Result := false;
  case aDir of
    mos_Horizontal: Result := fMetaObject.CanResizeHorizontal[fFlip, fInvert, fRotate];
    mos_Vertical: Result := fMetaObject.CanResizeVertical[fFlip, fInvert, fRotate];
  end;
end;

function TMetaObjectInterface.GetImages: TBitmaps;
begin
  Result := fMetaObject.Images[fFlip, fInvert, fRotate];
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


