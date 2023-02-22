unit LemProjectile;

interface

uses
  Generics.Collections,
  LemCore,
  LemLemming,
  GR32,
  Classes, SysUtils, Math, Types;

type
  TProjectileGraphic =
   (
     pgSpearFlat,
     pgSpearSlightTLBR, pgSpearSlightBLTR,
     pgSpear45TLBR, pgSpear45BLTR,
     pgSpearSteepTLBR, pgSpearSteepBLTR,
     pgGrenade, pgGrenadeExplode
   );

const
  PROJECTILE_FLIP: array[TProjectileGraphic] of TProjectileGraphic =
  (
    pgSpearFlat,
    pgSpearSlightBLTR, pgSpearSlightTLBR,
    pgSpear45BLTR, pgSpear45TLBR,
    pgSpearSteepBLTR, pgSpearSteepTLBR,
    pgGrenade, pgGrenadeExplode
  );

  PROJECTILE_GRAPHIC_RECTS: array[TProjectileGraphic] of TRect =
  (
    (Left: 11; Top: 20; Right: 25; Bottom: 22),
    (Left: 0; Top: 0; Right: 12; Bottom: 6),
    (Left: 13; Top: 0; Right: 25; Bottom: 6),
    (Left: 0; Top: 7; Right: 10; Bottom: 17),
    (Left: 0; Top: 18; Right: 10; Bottom: 28),
    (Left: 11; Top: 7; Right: 17; Bottom: 19),
    (Left: 18; Top: 7; Right: 24; Bottom: 19),
    (Left: 11; Top: 23; Right: 15; Bottom: 28),
    (Left: 0; Top: 29; Right: 32; Bottom: 61)
  );

type
  TProjectilePointArray = array of TPoint;

  TProjectile = class
    private
      fX: Integer;
      fY: Integer;

      fOffsetX: Integer;

      fDX: Integer;

      fFired: Boolean;
      fHit: Boolean;

      fPhysicsMap: TBitmap32;
      fLemming: TLemming;
      fLemmingIndex: Integer;

      fIsSpear: Boolean;
      fIsGrenade: Boolean;

      fSilentRemove: Boolean;

      constructor Create(aPhysicsMap: TBitmap32; aLemming: TLemming);

      procedure Fire;
      procedure Discard;
      procedure SetPositionFromLemming;

      function GetGraphic: TProjectileGraphic;
      function GetGraphicHotspot: TPoint;
    public
      constructor CreateAssign(aSrc: TProjectile);
      constructor CreateSpear(aPhysicsMap: TBitmap32; aLemming: TLemming);
      constructor CreateGrenade(aPhysicsMap: TBitmap32; aLemming: TLemming);
      constructor CreateForCloner(aPhysicsMap: TBitmap32; aNewLemming: TLemming; aOldProjectile: TProjectile);

      function Update: TProjectilePointArray;
      procedure Relink(aPhysicsMap: TBitmap32; aList: TLemmingList);

      procedure Assign(aSrc: TProjectile);

      property X: Integer read fX;
      property Y: Integer read fY;

      property Fired: Boolean read fFired;
      property Hit: Boolean read fHit;

      property Hotspot: TPoint read GetGraphicHotspot;
      property Graphic: TProjectileGraphic read GetGraphic;

      property IsSpear: Boolean read fIsSpear;
      property IsGrenade: Boolean read fIsGrenade;

      property SilentRemove: Boolean read fSilentRemove;
  end;

  TProjectileList = TObjectList<TProjectile>;

implementation

uses
  LemRenderHelpers;

const
  PROJECTILE_HORIZONTAL_MOMENTUM = 9;

  SPEAR_OFFSET: TPoint = (X: 2; Y: -3);

  // Spear angles
  SPEAR_SLIGHT_UP_BEGIN = 25;
  SPEAR_FLAT_BEGIN = 46;
  SPEAR_SLIGHT_DOWN_BEGIN = 102;
  SPEAR_45_DOWN_BEGIN = 138;
  SPEAR_STEEP_DOWN_BEGIN = 189;

{$REGION '  Y offset array'}
    Y_CHANGE_TO_NEXT_X: array[0..265] of Integer =
    (
      -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1,  0, -1, -1, -1,
      -1, -1,  0, -1, -1, -1,  0,
      -1, -1,  0, -1, -1,  0, -1,
      -1,  0, -1,  0, -1,  0, -1,
      -1,  0,  0, -1,  0, -1,  0,
      -1,  0,  0, -1,  0,  0, -1,
       0,  0, -1,  0,  0,  0, -1,
       0,  0,  0,  0,  0, -1,  0,
       0,  0,  0,  0,  0,  0,  0,
       0,  0,  0,  0,  0,  0,  0,
       0,  1,  0,  0,  0,  0,  0,
       1,  0,  0,  0,  1,  0,  0,
       1,  0,  0,  1,  0,  0,  1,
       0,  1,  0,  1,  0,  0,  1,
       1,  0,  1,  0,  1,  0,  1,
       1,  0,  1,  1,  0,  1,  1,
       0,  1,  1,  1,  0,  1,  1,
       1,  1,  1,  0,  1,  1,  1,
       1,  1,  1,  1,  1,  1,  1,
       1,  1,  1,  1,  1,  1,  2,
       1,  1,  1,  1,  1,  2,  1,
       1,  1,  2,  1,  1,  2,  1,
       1,  2,  1,  1,  2,  1,  2,
       1,  1,  2,  1,  2,  1,  2,
       2,  1,  2,  1,  2,  2,  1,
       2,  1,  2,  2,  2,  1,  2,
       2,  2,  1,  2,  2,  2,  2,
       1,  2,  2,  2,  2,  2,  2,
       2,  2,  2,  2,  2,  2,  2,
       2,  2,  2,  2,  2,  3,  2,
       2,  2,  2,  3,  2,  2,  2,
       3,  2,  2,  2,  3,  2,  2,
       3,  2,  3,  2,  2,  3,  2,
       3,  2,  3,  2,  3,  2,  3,
       3,  2,  3,  2,  3,  3,  2,
       3,  3,  2,  3,  3,  3,  2,
       3,  3,  3,  3,  3,  2,  3
    );
{$ENDREGION}

{ TProjectile }

procedure TProjectile.Assign(aSrc: TProjectile);
begin
  fX := aSrc.fX;
  fY := aSrc.fY;

  fOffsetX := aSrc.fOffsetX;

  fDX := aSrc.fDX;

  fFired := aSrc.fFired;
  fHit := aSrc.fHit;

  // don't assign physicsmap or lemming
  fLemmingIndex := aSrc.fLemmingIndex;

  fIsSpear := aSrc.fIsSpear;
  fIsGrenade := aSrc.fIsGrenade;

  fSilentRemove := aSrc.fSilentRemove;
end;

constructor TProjectile.Create(aPhysicsMap: TBitmap32; aLemming: TLemming);
begin
  fPhysicsMap := aPhysicsMap;
  fLemming := aLemming;

  if fLemming <> nil then
  begin
    fLemmingIndex := fLemming.LemIndex;
    fDX := fLemming.LemDX;
  end else
    fLemmingIndex := -1;
end;

constructor TProjectile.CreateAssign(aSrc: TProjectile);
begin
  Create(nil, nil);
  Assign(aSrc);
end;

constructor TProjectile.CreateForCloner(aPhysicsMap: TBitmap32; aNewLemming: TLemming; aOldProjectile: TProjectile);
begin
  Create(aPhysicsMap, aNewLemming);
  Assign(aOldProjectile);
  fLemmingIndex := aNewLemming.LemIndex;
  SetPositionFromLemming;
end;

constructor TProjectile.CreateGrenade(aPhysicsMap: TBitmap32;
  aLemming: TLemming);
begin
  fIsSpear := false;
  fIsGrenade := true;
  Create(aPhysicsMap, aLemming);
  SetPositionFromLemming;
end;

constructor TProjectile.CreateSpear(aPhysicsMap: TBitmap32; aLemming: TLemming);
begin
  fIsSpear := true;
  fIsGrenade := false;
  Create(aPhysicsMap, aLemming);
  SetPositionFromLemming;
end;

procedure TProjectile.Discard;
begin
  fSilentRemove := true;
  fLemming.LemHoldingProjectileIndex := -1;
end;

procedure TProjectile.Fire;
begin
  fFired := true;
  fLemming.LemHoldingProjectileIndex := -1;
end;

function TProjectile.GetGraphic: TProjectileGraphic;
begin
  if fIsGrenade then
  begin
    if fHit then
      Result := pgGrenadeExplode
    else
      Result := pgGrenade;
  end else begin
    if not fFired then
      case fLemming.LemPhysicsFrame of
        0..3: Result := pgSpearSteepBLTR;
        4: Result := pgSpear45BLTR;
        5: Result := pgSpearSlightBLTR;

        else Result := pgSpearFlat; // shouldn't happen
      end
    else
      case fOffsetX of
        SPEAR_SLIGHT_UP_BEGIN   .. SPEAR_FLAT_BEGIN-1:         Result := pgSpearSlightBLTR;
        SPEAR_FLAT_BEGIN        .. SPEAR_SLIGHT_DOWN_BEGIN-1:  Result := pgSpearFlat;
        SPEAR_SLIGHT_DOWN_BEGIN .. SPEAR_45_DOWN_BEGIN-1:      Result := pgSpearSlightTLBR;
        SPEAR_45_DOWN_BEGIN     .. SPEAR_STEEP_DOWN_BEGIN-1:   Result := pgSpear45TLBR;
        else if fOffsetX < SPEAR_SLIGHT_UP_BEGIN then Result := pgSpear45BLTR
        else Result := pgSpearSteepTLBR;
      end;

    if fDX < 0 then
      Result := PROJECTILE_FLIP[Result];
  end;
end;

function TProjectile.GetGraphicHotspot: TPoint;
var
  CurGraphic: TProjectileGraphic;
  ImgRect: TRect;
  AtTop: Boolean;
begin
  CurGraphic := Graphic;
  ImgRect := PROJECTILE_GRAPHIC_RECTS[CurGraphic];

  if CurGraphic in [pgGrenade, pgGrenadeExplode] then
  begin
    Result := Point(ImgRect.Width div 2, ImgRect.Height div 2);
    Exit;
  end;

  case CurGraphic of
    pgSpearFlat: AtTop := false; // Counterintuitively (due to small height of this one) it DOES put it at the top pixel

    pgSpearSlightTLBR,
    pgSpear45TLBR,
    pgSpearSteepTLBR:
      AtTop := fDX < 0;

    pgSpearSlightBLTR,
    pgSpear45BLTR,
    pgSpearSteepBLTR:
      AtTop := fDX > 0;

    else AtTop := false; // should never happen
  end;

  if fDX < 0 then
    Result.X := 1
  else
    Result.X := ImgRect.Width - 2;

  if AtTop then
    Result.Y := 1
  else
    Result.Y := ImgRect.Height - 2;
end;

procedure TProjectile.Relink(aPhysicsMap: TBitmap32; aList: TLemmingList);
begin
  fLemming := aList[fLemmingIndex];
  fPhysicsMap := aPhysicsMap;
  if not fFired then
    SetPositionFromLemming;
end;

procedure TProjectile.SetPositionFromLemming;
begin
  fDX := fLemming.LemDX;

  case fLemming.LemPhysicsFrame of
    0..3: begin
            fX := fLemming.LemX - (4 * fLemming.LemDX);
            fY := fLemming.LemY - 4;
          end;
    4: begin
         fX := fLemming.LemX - (3 * fLemming.LemDX);
         fY := fLemming.LemY - 7;
       end;
    5: begin
         fX := fLemming.LemX + (1 * fLemming.LemDX);
         fY := fLemming.LemY - 9;
       end;
  end;

  if fIsSpear then
  begin
    fX := fX + (SPEAR_OFFSET.X * fLemming.LemDX);
    fY := fY + SPEAR_OFFSET.Y;
  end;
end;

function TProjectile.Update: TProjectilePointArray;
var
  PosCount: Integer;

  procedure AddPos(dX, dY: Integer);
  var
    n: Integer;
  begin
    if not fHit then
    begin
      if PosCount = Length(Result) then
        SetLength(Result, PosCount * 2);

      fX := fX + (dX * fDX);
      fY := fY + dY;
      Result[PosCount] := Point(fX, fY);
      Inc(PosCount);

      if (fPhysicsMap.PixelS[fX, fY] and PM_SOLID) <> 0 then
        fHit := true;

      if fIsSpear and ((fPhysicsMap.PixelS[fX, fY + 1] and PM_SOLID) <> 0) then
        fHit := true;

      if (fX = fLemming.LemX) and (dX <> 0) then
        for n := fY + 1 to fLemming.LemY - 5 do
          if (fPhysicsMap.PixelS[fX, n] and PM_SOLID) <> 0 then
          begin
            fHit := true;
            Break;
          end;

      if fHit then
      begin
        if ((fDX < 0) and (fX > fLemming.LemX)) or
           ((fDX > 0) and (fX < fLemming.LemX)) then
          fHit := false;
      end;
    end;
  end;

var
  i: Integer;
  YChange: Integer;
begin
  if fHit then
    raise Exception.Create('TProjectile.Update called for a projectile after it collides with terrain');

  SetLength(Result, PROJECTILE_HORIZONTAL_MOMENTUM * 2); // it'll be expanded if need be
  Result[0] := Point(fX, fY);
  PosCount := 1;

  if fFired then
  begin

    for i := 0 to PROJECTILE_HORIZONTAL_MOMENTUM-1 do
    begin
      // AddPos handles:
      //  - Adding to Result
      //  - Adjusting for fDX
      //  - Updating fX and fY
      //  - Expanding Result as needed
      //  - Updating PosCount
      //  - Checking for collision and setting fHit
      // Additionally, AddPos does nothing if fHit has already been set.

      // AddPos does NOT handle trimming length of Result!

      YChange := Y_CHANGE_TO_NEXT_X[fOffsetX];

      if (fOffsetX < Length(Y_CHANGE_TO_NEXT_X) - 1) then
        Inc(fOffsetX);

      case YChange of
        -1: begin
              AddPos( 1,  0);
              AddPos( 0, -1);
            end;
         0: begin
              AddPos( 1,  0);
            end;
         1: begin
              AddPos( 0,  1);
              AddPos( 1,  0);
            end;
         2: begin
              AddPos( 0,  1);
              AddPos( 0,  1);
              AddPos( 1,  0);
            end;
         3: begin
              AddPos( 0,  1);
              AddPos( 0,  1);
              AddPos( 1,  0);
              AddPos( 0,  1);
            end;
      end;

      if fHit then
        Break;
    end;
  end else if (fLemming.LemRemoved) or not (fLemming.LemAction in [baSpearing, baGrenading]) then
    Discard
  else begin
    // Move with lemming's hand

    if fDX <> fLemming.LemDX then
    begin
      fDX := fLemming.LemDX;
      SetPositionFromLemming;
      if (fLemming.LemPhysicsFrame >= 4) then
      begin
        PosCount := 0;
        AddPos(0, 0);
      end;
    end else
      case fLemming.LemPhysicsFrame of
        4: begin
             AddPos(0, -1);
             AddPos(1, 0);
             AddPos(0, -1);
             AddPos(0, -1);
           end;
        5: begin
             AddPos(1, 0);
             AddPos(1, 0);
             AddPos(0, -1);
             AddPos(1, 0);
             AddPos(1, 0);
             AddPos(0, -1);
           end;
      end;

    if fHit or (fLemming.LemPhysicsFrame = 5) then
      Fire;
  end;

  SetLength(Result, PosCount);
end;

end.
