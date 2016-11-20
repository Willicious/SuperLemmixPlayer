unit LemLemming;

// TLemming and TLemmingList were moved here so that both
// LemGame and LemRendering can use them.

interface

uses
  LemMetaAnimation, GR32, LemTypes, LemCore,
  Contnrs, Types, Classes, SysUtils;

type
  TPreplacedLemming = class
    private
      fX: Integer;
      fY: Integer;
      fDx: Integer;
      fIsClimber:  Boolean;
      fIsSwimmer:  Boolean;
      fIsFloater:  Boolean;
      fIsGlider:   Boolean;
      fIsDisarmer: Boolean;
      fIsBlocker:  Boolean;
      fIsZombie:   Boolean;
    public
      constructor Create;
      procedure Assign(aSrc: TPreplacedLemming);
      property X: Integer read fX write fX;
      property Y: Integer read fY write fY;
      property Dx: Integer read fDx write fDx;
      property IsClimber: Boolean read fIsClimber write fIsClimber;
      property IsSwimmer: Boolean read fIsSwimmer write fIsSwimmer;
      property IsFloater: Boolean read fIsFloater write fIsFloater;
      property IsGlider: Boolean read fIsGlider write fIsGlider;
      property IsDisarmer: Boolean read fIsDisarmer write fIsDisarmer;
      property IsBlocker: Boolean read fIsBlocker write fIsBlocker;
      property IsZombie: Boolean read fIsZombie write fIsZombie;
  end;

  TPreplacedLemmingList = class(TObjectList)
    private
      function GetItem(Index: Integer): TPreplacedLemming;
    public
      constructor Create(aOwnsObjects: Boolean = true);
      function Add: TPreplacedLemming;
      function Insert(Index: Integer): TPreplacedLemming;
      procedure Assign(aSrc: TPreplacedLemmingList);
      property Items[Index: Integer]: TPreplacedLemming read GetItem; default;
      property List;
  end;

  TLemming = class
  private
    function CheckForPermanentSkills: Boolean;
    function GetPosition: TPoint;
  public
  { misc sized }
    LemEraseRect                  : TRect; // the rectangle of the last drawaction (can include space for countdown digits)
  { integer sized fields }
    LemIndex                      : Integer; // index in the lemminglist
    LemX                          : Integer; // the "main" foot x position
    LemY                          : Integer; // the "main" foot y position
    LemDX                         : Integer; // x speed (1 if left to right, -1 if right to left)
    LemJumped                     : Integer; // number of pixels the lem jumped
    LemFallen                     : Integer; // number of fallen pixels after last updraft
    LemTrueFallen                 : Integer; // total number of fallen pixels
    LemExplosionTimer             : Integer; // 84 (before 79) downto 0
    LemMechanicFrames             : Integer;
    LemFrame                      : Integer; // current animationframe
    LemMaxFrame                   : Integer; // copy from LMA
    LemAnimationType              : Integer; // copy from LMA
    LemParticleTimer              : Integer; // @particles, 52 downto 0, after explosion
    FrameTopDy                    : Integer; // = -LMA.FootY (ccexplore compatible)
    FrameLeftDx                   : Integer; // = -LMA.FootX (ccexplore compatible)
    LemNumberOfBricksLeft         : Integer; // for builder, platformer, stacker
  { byte sized fields }
    LemAction                     : TBasicLemmingAction; // current action of the lemming
    LemRemoved                    : Boolean; // the lemming is not in the level anymore
    LemTeleporting                : Boolean;
    LemEndOfAnimation             : Boolean; // got to the end of non-looping animation
                                             // equal to (LemFrame > LemMaxFrame)
    LemIsClimber                  : Boolean;
    LemIsSwimmer                  : Boolean;
    LemIsFloater                  : Boolean;
    LemIsGlider                   : Boolean;
    LemIsMechanic                 : Boolean;
    LemIsZombie                   : Boolean;
    LemPlacedBrick                : Boolean; // placed useful brick during this cycle (plaformer and stacker)
    LemInFlipper                  : Integer;
    LemHasBlockerField            : Boolean; // for blockers, even during ohno
    LemIsNewDigger                : Boolean; // new digger removes one more row
    LemIsNewClimbing              : Boolean; // new climbing lem in first 4 frames
    LemHighlightReplay            : Boolean;
    LemExploded                   : Boolean; // @particles, set after a Lemming actually exploded, used to control particles-drawing
    LemUsedSkillCount             : Integer; // number of skills assigned to this lem, used for talisman
    LemTimerToStone               : Boolean;
    LemHideCountdown              : Boolean; // used to ensure countdown is not displayed when assigned Bomber / Stoner
    LemStackLow                   : Boolean; // Is the starting position one pixel below usual??
    // The next three values are only needed to determine intermediate trigger area checks
    // They are set in HandleLemming
    LemXOld                       : Integer; // position of previous frame
    LemYOld                       : Integer;
    LemActionOld                  : TBasicLemmingAction; // action in previous frame
    LemActionNew                  : TBasicLemmingAction; // new action after fixing a trap, see http://www.lemmingsforums.net/index.php?topic=3004.0
    LemQueueAction                : TBasicLemmingAction; // queued action to be assigned within the next few frames
    LemQueueFrame                 : Integer; // number of frames the skill is already queued

    constructor Create;
    procedure Assign(Source: TLemming);
    procedure SetFromPreplaced(Source: TPreplacedLemming);
    //function GetLocationBounds: TRect; // rect in world
    //function GetFrameBounds: TRect; // rect from animation bitmap
    //function GetCountDownDigitBounds: TRect; // countdown

    property Position          : TPoint read GetPosition;    
    property HasPermanentSkills: Boolean read CheckForPermanentSkills;
  end;

  TLemmingList = class(TObjectList)
  private
    function GetItem(Index: Integer): TLemming;
  protected
  public
    function Add(Item: TLemming): Integer;
    procedure Insert(Index: Integer; Item: TLemming);
    property Items[Index: Integer]: TLemming read GetItem; default;
    property List; // for fast access
  end;

implementation

{ TPreplacedLemming }

constructor TPreplacedLemming.Create;
begin
  inherited;
  fX := 0;
  fY := 0;
  fDx := 1;
  fIsClimber := false;
  fIsSwimmer := false;
  fIsFloater := false;
  fIsGlider := false;
  fIsDisarmer := false;
  fIsBlocker := false;
  fIsZombie := false;
end;

procedure TPreplacedLemming.Assign(aSrc: TPreplacedLemming);
begin
  X := aSrc.X;
  Y := aSrc.Y;
  Dx := aSrc.Dx;
  IsClimber := aSrc.IsClimber;
  IsSwimmer := aSrc.IsSwimmer;
  IsFloater := aSrc.IsFloater;
  IsGlider := aSrc.IsGlider;
  IsDisarmer := aSrc.IsDisarmer;
  IsBlocker := aSrc.IsBlocker;
  IsZombie := aSrc.IsZombie;
end;

{ TPreplacedLemmingList }

constructor TPreplacedLemmingList.Create(aOwnsObjects: Boolean = true);
begin
  inherited Create(aOwnsObjects);
end;

function TPreplacedLemmingList.Add: TPreplacedLemming;
begin
  Result := TPreplacedLemming.Create;
  inherited Add(Result);
end;

function TPreplacedLemmingList.Insert(Index: Integer): TPreplacedLemming;
begin
  Result := TPreplacedLemming.Create;
  inherited Insert(Index, Result);
end;

procedure TPreplacedLemmingList.Assign(aSrc: TPreplacedLemmingList);
var
  i: Integer;
  Item: TPreplacedLemming;
begin
  Clear;
  for i := 0 to aSrc.Count-1 do
  begin
    Item := Add;
    Item.Assign(aSrc[i]);
  end;
end;

function TPreplacedLemmingList.GetItem(Index: Integer): TPreplacedLemming;
begin
  Result := inherited Get(Index);
end;

{ TLemming }

constructor TLemming.Create;
begin
  inherited;
  LemInFlipper := -1;
  LemParticleTimer := -1;
end;

function TLemming.CheckForPermanentSkills: Boolean;
begin
  Result := (LemIsClimber or LemIsSwimmer or LemIsFloater or LemIsGlider or LemIsMechanic);
end;

procedure TLemming.SetFromPreplaced(Source: TPreplacedLemming);
begin
  LemX := Source.X;
  LemY := Source.Y;
  LemDx := Source.Dx;
  LemIsClimber := Source.IsClimber;
  LemIsSwimmer := Source.IsSwimmer;
  LemIsFloater := Source.IsFloater;
  LemIsGlider := Source.IsGlider;
  LemIsMechanic := Source.IsDisarmer;
  // Blocker and Zombie must be handled by the calling routine
end;

function TLemming.GetPosition: TPoint;
begin
  Result.X := LemX;
  Result.Y := LemY;
end;

(*function TLemming.GetCountDownDigitBounds: TRect;
begin
  with Result do
  begin
    Left := LemX - 1;
    Top := LemY + FrameTopDy - 12;
    Right := Left + 8;
    Bottom := Top + 8;
    if LemDx = 1 then
    begin
      Left := Left - 1;
      Right := Right - 1;
    end;
  end;
end;



function TLemming.GetFrameBounds: TRect;
begin
  Assert(LAB <> nil, 'getframebounds error');
  with Result do
  begin
    Left := 0;
    Top := LemFrame * LMA.Height;
    Right := LMA.Width;
    Bottom := Top + LMA.Height;
  end;
end;

function TLemming.GetLocationBounds: TRect;
begin
  Assert(LMA <> nil, 'meta animation error');
  with Result do
  begin
    Left := LemX - LMA.FootX;
    Top := LemY - LMA.FootY;
    Right := Left + LMA.Width;
    Bottom := Top + LMA.Height;

    if (LemAction in [baDigging, baFixing]) and (LemDx = -1) then
    begin
      Inc(Left);
      Inc(Right);
    end;

    if LemAction = baMining then
    begin
      if LemDx = -1 then
      begin
        Dec(Left);
        Dec(Right);
      end else begin
        Inc(Left);
        Inc(Right);
      end;
      if (LemFrame < 15) then
      begin
        Inc(Top);
        Inc(Bottom);
      end;
    end;  // Seems to be glitchy if the animations themself are altered
  end;
end;*)

procedure TLemming.Assign(Source: TLemming);
begin

  // does NOT copy LemIndex! This is intentional //
  LemEraseRect := Source.LemEraseRect;
  LemX := Source.LemX;
  LemY := Source.LemY;
  LemDX := Source.LemDX;
  LemJumped := Source.LemJumped;
  LemFallen := Source.LemFallen;
  LemTrueFallen := Source.LemTrueFallen;
  LemExplosionTimer := Source.LemExplosionTimer;
  LemMechanicFrames := Source.LemMechanicFrames;
  LemFrame := Source.LemFrame;
  LemMaxFrame := Source.LemMaxFrame;
  LemAnimationType := Source.LemAnimationType;
  LemParticleTimer := Source.LemParticleTimer;
  FrameTopDy := Source.FrameTopDy;
  FrameLeftDx := Source.FrameLeftDx;
  LemNumberOfBricksLeft := Source.LemNumberOfBricksLeft;

  LemAction := Source.LemAction;
  LemRemoved := Source.LemRemoved;
  LemTeleporting := Source.LemTeleporting;
  LemEndOfAnimation := Source.LemEndOfAnimation;
  LemIsClimber := Source.LemIsClimber;
  LemIsSwimmer := Source.LemIsSwimmer;
  LemIsFloater := Source.LemIsFloater;
  LemIsGlider := Source.LemIsGlider;
  LemIsMechanic := Source.LemIsMechanic;
  LemIsZombie := Source.LemIsZombie;
  LemPlacedBrick := Source.LemPlacedBrick;
  LemInFlipper := Source.LemInFlipper;
  LemHasBlockerField := Source.LemHasBlockerField;
  LemIsNewDigger := Source.LemIsNewDigger;
  LemIsNewClimbing := Source.LemIsNewClimbing;
  LemHighlightReplay := Source.LemHighlightReplay;
  LemExploded := Source.LemExploded;
  LemUsedSkillCount := Source.LemUsedSkillCount;
  LemTimerToStone := Source.LemTimerToStone;
  LemHideCountdown := Source.LemHideCountdown;
  LemStackLow := Source.LemStackLow;
  LemXOld := Source.LemXOld;
  LemYOld := Source.LemYOld;
  LemActionOld := Source.LemActionOld;
  LemActionNew := Source.LemActionNew;
  // does NOT copy LemQueueAction or LemQueueFrame! This is intentional, because we want to cancel queuing on backwards frameskips.
end;

{ TLemmingList }

function TLemmingList.Add(Item: TLemming): Integer;
begin
  Result := inherited Add(Item);
end;

function TLemmingList.GetItem(Index: Integer): TLemming;
begin
  Result := inherited Get(Index);
end;

procedure TLemmingList.Insert(Index: Integer; Item: TLemming);
begin
  inherited Insert(Index, Item);
end;

end.