unit LemProjectile;

interface

uses
  LemLemming,
  LemRenderHelpers,
  GR32,
  Classes, SysUtils, Math, Types;

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

      fIsSpear: Boolean;
      fIsGrenade: Boolean;

      constructor Create(aPhysicsMap: TBitmap32; aLemming: TLemming);
    public
      constructor CreateSpear(aPhysicsMap: TBitmap32; aLemming: TLemming);
      constructor CreateGrenade(aPhysicsMap: TBitmap32; aLemming: TLemming);

      procedure Fire;
      function Update: TProjectilePointArray;

      property X: Integer read fX;
      property Y: Integer read fY;

      property Hit: Boolean read fHit;
  end;

implementation

const
  PROJECTILE_HORIZONTAL_MOMENTUM = 9;

  Y_CHANGE_TO_NEXT_X: array[0..332] of Integer =
  (
     -1,  0, -1, -1,  0, -1, -1, // initial - slight up angle
      0, -1,  0, -1, -1,  0, -1,
      0, -1,  0, -1,  0, -1,  0,
     -1,  0, -1,  0, -1,  0,  0,
     -1,  0, -1,  0,  0, -1,  0,
      0, -1,  0,  0, -1,  0,  0, // 35 - set to horizontal graphic
      0, -1,  0,  0,  0, -1,  0,
      0,  0,  0, -1,  0,  0,  0,
      0,  0,  0, -1,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  1,  0,  0,  0,
      0,  0,  0,  1,  0,  0,  0,
      0,  1,  0,  0,  0,  1,  0,
      0,  0,  1,  0,  0,  1,  0,
      0,  1,  0,  0,  1,  0,  1, // 105 - set to slight down angle
      0,  0,  1,  0,  1,  0,  1,
      0,  1,  0,  1,  0,  1,  0,
      1,  0,  1,  1,  0,  1,  0,
      1,  1,  0,  1,  1,  0,  1,
      1,  0,  1,  1,  1,  0,  1,
      1,  1,  0,  1,  1,  1,  1, // 147 - set to 45 angle
      0,  1,  1,  1,  1,  1,  1,
      0,  1,  1,  1,  1,  1,  1,
      1,  1,  1,  1,  1,  1,  1,
      1,  1,  1,  1,  1,  1,  1,
      2,  1,  1,  1,  1,  1,  1,
      2,  1,  1,  1,  1,  2,  1,
      1,  1,  2,  1,  1,  1,  2,
      1,  1,  2,  1,  1,  2,  1,
      1,  2,  1,  2,  1,  1,  2,
      1,  2,  1,  2,  1,  2,  1,
      2,  1,  2,  1,  2,  1,  2,
      2,  1,  2,  1,  2,  2,  1,
      2,  2,  1,  2,  2,  1,  2, // 231 - set to strong down angle
      2,  2,  1,  2,  2,  2,  1,
      2,  2,  2,  2,  1,  2,  2,
      2,  2,  2,  2,  1,  2,  2,
      2,  2,  2,  2,  2,  2,  2,
      2,  2,  2,  2,  2,  2,  2,
      2,  2,  2,  2,  3,  2,  2,
      2,  2,  2,  2,  2,  3,  2,
      2,  2,  2,  3,  2,  2,  2,
      3,  2,  2,  3,  2,  2,  3,
      2,  2,  3,  2,  2,  3,  2,
      3,  2,  2,  3,  2,  3,  2,
      3,  2,  3,  2,  3,  2,  3,
      2,  3,  2,  3
  );

{ TProjectile }

constructor TProjectile.Create(aPhysicsMap: TBitmap32; aLemming: TLemming);
begin
  fPhysicsMap := aPhysicsMap;
  fLemming := aLemming;
end;

constructor TProjectile.CreateGrenade(aPhysicsMap: TBitmap32;
  aLemming: TLemming);
begin
  fIsSpear := false;
  fIsGrenade := true;
  Create(aPhysicsMap, aLemming);
end;

constructor TProjectile.CreateSpear(aPhysicsMap: TBitmap32; aLemming: TLemming);
begin
  fIsSpear := true;
  fIsGrenade := false;
  Create(aPhysicsMap, aLemming);
end;

procedure TProjectile.Fire;
begin
  fFired := true;
end;

function TProjectile.Update: TProjectilePointArray;
var
  i: Integer;

  PosCount: Integer;

  procedure AddPos(dX, dY: Integer);
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
    end;
  end;
begin
  if fHit then
    raise Exception.Create('TProjectile.Update called for a projectile after it collides with terrain');

  if fFired then
  begin
    SetLength(Result, PROJECTILE_HORIZONTAL_MOMENTUM * 2); // it'll be expanded if need be
    Result[0] := Point(fX, fY);
    PosCount := 1;

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

      case Y_CHANGE_TO_NEXT_X[fOffsetX] of
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

      if (fOffsetX < Length(Y_CHANGE_TO_NEXT_X) - 1) then
        Inc(fOffsetX);

      if fHit then
        Break;
    end;

    SetLength(Result, PosCount);
  end else begin
    // Move with lemming's hand
    SetLength(Result, 0);
  end;
end;

end.
