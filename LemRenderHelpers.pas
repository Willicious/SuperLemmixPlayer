{$include lem_directives.inc}
unit LemRenderHelpers;

// Moved some stuff here from LemRendering so that I can reference it in
// LemNeoGraphicSet without circular dependancy.

interface

uses
  LemTypes, LemGadgets, LemLemming, LemCore,
  GR32, GR32_Blend,
  Contnrs, Classes;

const
  PARTICLE_FRAMECOUNT = 51;
  PARTICLE_COLORS: array[0..7] of TColor32 = ($FF4040E0, $FF00B000, $FFF0D0D0, $FFF02020,
                                              $C04040E0, $C000B000, $C0F0D0D0, $C0F02020);

  PM_SOLID       = $00000001;
  PM_STEEL       = $00000002;
  PM_ONEWAY      = $00000004;
  PM_ONEWAYLEFT  = $00000008;
  PM_ONEWAYRIGHT = $00000010;
  PM_ONEWAYDOWN  = $00000020; // Yes, I know they're mutually incompatible, but it's easier to do this way
  PM_ONEWAYUP    = $00000040;
  PM_NOCANCELSTEEL = $00000080;

  PM_TERRAIN   = $000000FF;


  SHADOW_COLOR = $80202020;
  ALPHA_CUTOFF = $80000000; // if (TColor32) and ALPHA_CUTOFF = 0 then not solid

type

  TDrawableItem = (di_ConstructivePixel, di_Stoner);
  TDrawRoutine = procedure(X, Y: Integer) of object;
  TDrawRoutineWithColor = procedure(X, Y: Integer; Color: TColor32) of object;
  TRemoveRoutine = procedure(X, Y, Width, Height: Integer) of object;
  TSimulateTransitionRoutine = procedure(L: TLemming; NewAction: TBasicLemmingAction) of object;
  TSimulateLemRoutine = function(L: TLemming; DoCheckObjects: Boolean = True): TArrayArrayInt of object;
  TGetLemmingRoutine = function: TLemming of object;
  TIsStartingSecondsRoutine = function: Boolean of object;

  TRenderLayer = (rlBackground,
                  rlBackgroundObjects,
                  rlGadgetsLow,
                  rlLowShadows,
                  rlTerrain,
                  rlOnTerrainGadgets,
                  rlOneWayArrows,
                  rlGadgetsHigh,
                  rlTriggers,
                  rlHighShadows,
                  rlObjectHelpers,
                  rlParticles,
                  rlLemmings);

  TRenderBitmaps = class(TBitmaps)
  private
    fWidth: Integer;
    fHeight: Integer;
    fPhysicsMap: TBitmap32;

    function GetItem(Index: TRenderLayer): TBitmap32;
    procedure CombinePixelsShadow(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombinePhysicsMapOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombinePhysicsMapOneWays(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombinePhysicsMapOnlyDestructible(F: TColor32; var B: TColor32; M: TColor32);

    procedure DrawClearPhysicsTerrain(aDst: TBitmap32; aRegion: TRect);
  protected
  public
    fIsEmpty: array[TRenderLayer] of Boolean;

    constructor Create;
    procedure Prepare(aWidth, aHeight: Integer);
    procedure CombineTo(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false; aTransparentBackground: Boolean = false); overload;
    procedure CombineTo(aDst: TBitmap32; aClearPhysics: Boolean = false); overload;
    property Items[Index: TRenderLayer]: TBitmap32 read GetItem; default;
    property Width: Integer read fWidth;
    property Height: Integer read fHeight;
    property PhysicsMap: TBitmap32 write fPhysicsMap;
  published
  end;

  TDrawItem = class
  private
  protected
    fOriginal: TBitmap32; // reference
  public
    constructor Create(aOriginal: TBitmap32);
    destructor Destroy; override;
    property Original: TBitmap32 read fOriginal;
  end;

  TDrawList = class(TObjectList)
  private
    function GetItem(Index: Integer): TDrawItem;
  protected
  public
    function Add(Item: TDrawItem): Integer;
    procedure Insert(Index: Integer; Item: TDrawItem);
    property Items[Index: Integer]: TDrawItem read GetItem; default;
  published
  end;

  THelperIcon = (hpi_None,
                 hpi_A, hpi_B, hpi_C, hpi_D, hpi_E, hpi_F, hpi_G, hpi_H, hpi_I, hpi_J, hpi_K, hpi_L, hpi_M,
                 hpi_N, hpi_O, hpi_P, hpi_Q, hpi_R, hpi_S, hpi_T, hpi_U, hpi_V, hpi_W, hpi_X, hpi_Y, hpi_Z,
                 hpi_num_1, hpi_num_inf,
                 hpi_ArrowLeft, hpi_ArrowRight, hpi_ArrowUp, hpi_ArrowDown, hpi_Exclamation,
                 hpi_Exit, hpi_Fire, hpi_Trap, hpi_Trap_Disabled,
                 hpi_Flipper, hpi_Button, hpi_Force, hpi_Splat, hpi_Water,
                 hpi_FallDist,
                 hpi_Skill_Zombie, hpi_Skill_Neutral, hpi_Skill_Climber, hpi_Skill_Floater,
                 hpi_Skill_Glider, hpi_Skill_Swimmer, hpi_Skill_Disarmer);

  THelperImages = array[Low(THelperIcon)..High(THelperIcon)] of TBitmap32;

  TRenderInterface = class // Used for communication between GameWindow, LemGame and LemRendering.
    private
      fDisableDrawing: Boolean;
      fLemmingList: TLemmingList;
      fGadgets: TGadgetList;
      fPSelectedSkill: ^TSkillPanelButton;
      fSelectedLemmingID: Integer;
      fReplayLemmingID: Integer;
      fPhysicsMap: TBitmap32;
      fTerrainMap: TBitmap32;
      fScreenPos: TPoint;
      fMousePos: TPoint;
      fDrawRoutineBrick: TDrawRoutineWithColor;
      fDrawRoutineStoner: TDrawRoutine;
      fRemoveRoutine: TRemoveRoutine;
      fSimulateTransitionRoutine: TSimulateTransitionRoutine;
      fSimulateLemRoutine: TSimulateLemRoutine;
      fGetHighlitLemRoutine: TGetLemmingRoutine;
      fIsStartingSecondsRoutine: TIsStartingSecondsRoutine;
      fUserHelperIcon: THelperIcon;
      fForceUpdate: Boolean;
      function GetSelectedSkill: TSkillPanelButton;
      function GetHighlitLemming: TLemming;
      function GetSelectedLemming: TLemming;
      procedure SetSelectedLemming(aValue: TLemming);
      function GetReplayLemming: TLemming;
      procedure SetReplayLemming(aValue: TLemming);
    public
      constructor Create;
      procedure SetSelectedSkillPointer(var aButton: TSkillPanelButton);
      procedure SetDrawRoutineStoner(aRoutine: TDrawRoutine);
      procedure SetDrawRoutineBrick(aRoutine: TDrawRoutineWithColor);
      procedure SetRemoveRoutine(aRoutine: TRemoveRoutine);
      procedure SetSimulateLemRoutine(aLemRoutine: TSimulateLemRoutine; aTransRoutine: TSimulateTransitionRoutine);
      procedure SetGetHighlitRoutine(aRoutine: TGetLemmingRoutine);
      procedure SetIsStartingSecondsRoutine(aRoutine: TIsStartingSecondsRoutine);
      procedure AddTerrainBrick(X, Y: Integer; Color: TColor32);
      procedure AddTerrainStoner(X, Y: Integer);
      procedure RemoveTerrain(X, Y, Width, Height: Integer);
      procedure Null;
      procedure SimulateTransitionLem(L: TLemming; NewAction: TBasicLemmingAction);
      function SimulateLem(L: TLemming): TArrayArrayInt;
      function IsStartingSeconds: Boolean;
      property DisableDrawing: Boolean read fDisableDrawing write fDisableDrawing;
      property LemmingList: TLemmingList read fLemmingList write fLemmingList;
      property Gadgets: TGadgetList read fGadgets write fGadgets;
      property SelectedSkill: TSkillPanelButton read GetSelectedSkill;
      property SelectedLemming: TLemming read GetSelectedLemming write SetSelectedLemming;
      property HighlitLemming: TLemming read GetHighlitLemming;
      property ReplayLemming: TLemming read GetReplayLemming write SetReplayLemming;
      property PhysicsMap: TBitmap32 read fPhysicsMap write fPhysicsMap;
      property TerrainMap: TBitmap32 read fTerrainMap write fTerrainMap;
      property ScreenPos: TPoint read fScreenPos write fScreenPos;
      property MousePos: TPoint read fMousePos write fMousePos;
      property UserHelper: THelperIcon read fUserHelperIcon write fUserHelperIcon;
      property ForceUpdate: Boolean read fForceUpdate write fForceUpdate; //used after a assign-to-highlit while paused
  end;

const
  HelperImageFilenames: array[Low(THelperIcon)..High(THelperIcon)] of String =
                             ('ltr_a.png', // placeholder
                              'ltr_a.png',
                              'ltr_b.png',
                              'ltr_c.png',
                              'ltr_d.png',
                              'ltr_e.png',
                              'ltr_f.png',
                              'ltr_g.png',
                              'ltr_h.png',
                              'ltr_i.png',
                              'ltr_j.png',
                              'ltr_k.png',
                              'ltr_l.png',
                              'ltr_m.png',
                              'ltr_n.png',
                              'ltr_o.png',
                              'ltr_p.png',
                              'ltr_q.png',
                              'ltr_r.png',
                              'ltr_s.png',
                              'ltr_t.png',
                              'ltr_u.png',
                              'ltr_v.png',
                              'ltr_w.png',
                              'ltr_x.png',
                              'ltr_y.png',
                              'ltr_z.png',
                              'num_1.png',
                              'num_inf.png',
                              'left_arrow.png',
                              'right_arrow.png',
                              'up_arrow.png',
                              'down_arrow.png',
                              'exclamation.png',
                              'exit.png',
                              'fire.png',
                              'trap.png',
                              'trap_dis.png',
                              'flipper.png',
                              'button.png',
                              'force.png',
                              'splat.png',
                              'water.png',
                              'fall_distance.png',
                              'skill_zombie.png',
                              'skill_neutral.png',
                              'skill_climber.png',
                              'skill_floater.png',
                              'skill_glider.png',
                              'skill_swimmer.png',
                              'skill_disarmer.png');
implementation

uses
  Math;

{ TRenderInterface }

constructor TRenderInterface.Create;
begin
  fDrawRoutineBrick := nil;
  fDrawRoutineStoner := nil;
  fUserHelperIcon := hpi_None;
  fSelectedLemmingID := -1;
end;

procedure TRenderInterface.SetDrawRoutineStoner(aRoutine: TDrawRoutine);
begin
  fDrawRoutineStoner := aRoutine;
end;

procedure TRenderInterface.SetDrawRoutineBrick(aRoutine: TDrawRoutineWithColor);
begin
  fDrawRoutineBrick := aRoutine;
end;

procedure TRenderInterface.SetRemoveRoutine(aRoutine: TRemoveRoutine);
begin
  fRemoveRoutine := aRoutine;
end;

procedure TRenderInterface.SetSimulateLemRoutine(aLemRoutine: TSimulateLemRoutine; aTransRoutine: TSimulateTransitionRoutine);
begin
  fSimulateLemRoutine := aLemRoutine;
  fSimulateTransitionRoutine := aTransRoutine;
end;

procedure TRenderInterface.SetGetHighlitRoutine(aRoutine: TGetLemmingRoutine);
begin
  fGetHighlitLemRoutine := aRoutine;
end;

procedure TRenderInterface.SetIsStartingSecondsRoutine(aRoutine: TIsStartingSecondsRoutine);
begin
  fIsStartingSecondsRoutine := aRoutine;
end;

procedure TRenderInterface.AddTerrainBrick(X, Y: Integer; Color: TColor32);
begin
  // TLemmingGame is expected to handle modifications to the physics map.
  // This is to pass to TRenderer for on-screen drawing.
  if fDisableDrawing then Exit;
  if Assigned(fDrawRoutineBrick) then fDrawRoutineBrick(X, Y, Color);
end;

procedure TRenderInterface.AddTerrainStoner(X, Y: Integer);
begin
  // TLemmingGame is expected to handle modifications to the physics map.
  // This is to pass to TRenderer for on-screen drawing.
  if fDisableDrawing then Exit;
  if Assigned(fDrawRoutineStoner) then fDrawRoutineStoner(X, Y);
end;

procedure TRenderInterface.RemoveTerrain(X, Y, Width, Height: Integer);
begin
  // This removes terrain from the layer rlTerrain accoding to the physics map
  // within the rectange defined defined by (X, Y, Width, Height)
  // Whenever LemGame removes some terrain, it is expected to call this method!
  if fDisableDrawing then Exit;
  fRemoveRoutine(X, Y, Width, Height);
end;

procedure TRenderInterface.SimulateTransitionLem(L: TLemming; NewAction: TBasicLemmingAction);
begin
  fSimulateTransitionRoutine(L, NewAction);
end;

function TRenderInterface.SimulateLem(L: TLemming): TArrayArrayInt;
begin
  Result := fSimulateLemRoutine(L);
end;

function TRenderInterface.IsStartingSeconds: Boolean;
begin
  Result := fIsStartingSecondsRoutine;
end;

function TRenderInterface.GetHighlitLemming: TLemming;
begin
  Result := fGetHighlitLemRoutine;
end;

procedure TRenderInterface.SetSelectedLemming(aValue: TLemming);
begin
  if aValue = nil then
    fSelectedLemmingID := -1
  else
    fSelectedLemmingID := aValue.LemIndex;
end;

function TRenderInterface.GetSelectedLemming: TLemming;
begin
  if (fSelectedLemmingID < 0) or (fSelectedLemmingID >= fLemmingList.Count) then
    Result := nil
  else
    Result := fLemmingList[fSelectedLemmingID];
end;

procedure TRenderInterface.SetReplayLemming(aValue: TLemming);
begin
  if aValue = nil then
    fReplayLemmingID := -1
  else
    fReplayLemmingID := aValue.LemIndex;
end;

function TRenderInterface.GetReplayLemming: TLemming;
begin
  if (fReplayLemmingID < 0) or (fReplayLemmingID >= fLemmingList.Count) then
    Result := nil
  else
    Result := fLemmingList[fReplayLemmingID];
end;

procedure TRenderInterface.SetSelectedSkillPointer(var aButton: TSkillPanelButton);
begin
  fPSelectedSkill := @aButton;
end;

function TRenderInterface.GetSelectedSkill: TSkillPanelButton;
begin
  Result := fPSelectedSkill^;
end;

procedure TRenderInterface.Null;
var
  TempVar: Integer;
begin
  // This is a dummy procedure. We simply call it to ensure TRenderInterface exists
  // and can be accessed correctly during exception logging.
  TempVar := fScreenPos.X;
  fScreenPos.X := TempVar;
end;

{ TDrawItem }

constructor TDrawItem.Create(aOriginal: TBitmap32);
begin
  inherited Create;
  fOriginal := aOriginal;
end;

destructor TDrawItem.Destroy;
begin
  inherited Destroy;
end;

{ TDrawList }

function TDrawList.Add(Item: TDrawItem): Integer;
begin
  Result := inherited Add(Item);
end;

function TDrawList.GetItem(Index: Integer): TDrawItem;
begin
  Result := inherited Get(Index);
end;

procedure TDrawList.Insert(Index: Integer; Item: TDrawItem);
begin
  inherited Insert(Index, Item);
end;


{ TRenderBitmaps }

constructor TRenderBitmaps.Create;
var
  i: TRenderLayer;
  BMP: TBitmap32;
begin
  inherited Create(true);
  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    BMP := TBitmap32.Create;
    if i in [rlLowShadows, rlHighShadows] then
    begin
      BMP.DrawMode := dmCustom;
      BMP.OnPixelCombine := CombinePixelsShadow;
    end else begin
      BMP.DrawMode := dmBlend;
      BMP.CombineMode := cmMerge;
    end;
    Add(BMP);

    fIsEmpty[i] := True;
  end;

  // Always draw rlBackground, rlTerrain and rlLemmings
  fIsEmpty[rlBackground] := False;
  fIsEmpty[rlTerrain] := False;
  fIsEmpty[rlLemmings] := False;
end;

procedure TRenderBitmaps.CombinePixelsShadow(F: TColor32; var B: TColor32; M: TColor32);
var
  A, C: TColor32;
  Red: Cardinal;
  Green: Cardinal;
  Blue: Cardinal;

  procedure ModColor(var Component: Cardinal);
  begin
    if Component < $80 then
      Component := $C0
    else
      Component := $40;
  end;
begin
  A := F and $FF000000;
  if A = 0 then Exit;
  Red   := (B and $FF0000) shr 16;
  Green := (B and $00FF00) shr 8;
  Blue  := (B and $0000FF);
  ModColor(Red);
  ModColor(Green);
  ModColor(Blue);
  C := ($C0000000) or (Red shl 16) or (Green shl 8) or (Blue);
  MergeMem(C, B);
end;

procedure TRenderBitmaps.CombinePhysicsMapOnlyOnTerrain(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $00000001) = 0 then B := 0;
end;

procedure TRenderBitmaps.CombinePhysicsMapOneWays(F: TColor32; var B: TColor32; M: TColor32);
begin
  if (F and $00000004) = 0 then B := 0;
end;


procedure TRenderBitmaps.CombinePhysicsMapOnlyDestructible(F: TColor32; var B: TColor32; M: TColor32);
begin
  if ((F and PM_SOLID) = 0) or ((F and PM_STEEL) <> 0) then B := 0;
end;

function TRenderBitmaps.GetItem(Index: TRenderLayer): TBitmap32;
begin
  Result := inherited Get(Integer(Index));
end;


procedure TRenderBitmaps.Prepare(aWidth, aHeight: Integer);
var
  i: TRenderLayer;
begin
  fWidth := aWidth;
  fHeight := aHeight;
  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    Items[i].SetSize(Width, Height);
    Items[i].Clear($00000000);
  end;
end;

procedure TRenderBitmaps.CombineTo(aDst: TBitmap32; aClearPhysics: Boolean = false);
begin
  CombineTo(aDst, fPhysicsMap.BoundsRect, aClearPhysics);
end;

procedure TRenderBitmaps.CombineTo(aDst: TBitmap32; aRegion: TRect; aClearPhysics: Boolean = false; aTransparentBackground: Boolean = false);
var
  i: TRenderLayer;
begin
  aDst.BeginUpdate;

  if aTransparentBackground then
    aDst.Clear($00000000)
  else
    aDst.Clear($FF000000);

  // Tidy up the Only On Terrain and One Way Walls layers
  if fPhysicsMap <> nil then
  begin
    fPhysicsMap.DrawMode := dmCustom;
    // Delete Only-On-Terrain Objects not on terrain
    if not fIsEmpty[rlOnTerrainGadgets] then
    begin
      fPhysicsMap.OnPixelCombine := CombinePhysicsMapOnlyOnTerrain;
      fPhysicsMap.DrawTo(Items[rlOnTerrainGadgets], aRegion, aRegion);
    end;

    // Delete One-Way-Arrows not on non-steel terrain
    if not fIsEmpty[rlOneWayArrows] then
    begin
      fPhysicsMap.OnPixelCombine := CombinePhysicsMapOneWays;
      fPhysicsMap.DrawTo(Items[rlOneWayArrows], aRegion, aRegion);
    end;

    // Delete High Shadows not on non-steel terrain
    if not fIsEmpty[rlHighShadows] then
    begin
      fPhysicsMap.OnPixelCombine := CombinePhysicsMapOnlyDestructible;
      fPhysicsMap.DrawTo(Items[rlHighShadows], aRegion, aRegion);
    end;
  end;

  for i := Low(TRenderLayer) to High(TRenderLayer) do
  begin
    if (not aClearPhysics) and (i = rlTriggers) then
      Continue; // we only want to draw triggers when Clear Physics Mode is enabled

    if aClearPhysics and (i in [rlBackground, rlOnTerrainGadgets, rlGadgetsHigh]) then
      Continue; // we don't want to draw the first two in Clear Physics mode; while the latter has special handling

    if aClearPhysics and (i = rlTerrain) then
    begin // we want to draw based on physics map, not graphical map, in this case
      Items[rlGadgetsHigh].DrawTo(aDst, aRegion, aRegion); // we want it behind terrain
      DrawClearPhysicsTerrain(aDst, aRegion);
      Continue;
    end;

    if not fIsEmpty[i] then
      Items[i].DrawTo(aDst, aRegion, aRegion);
  end;
  aDst.EndUpdate;
  aDst.Changed;
end;

procedure TRenderBitmaps.DrawClearPhysicsTerrain(aDst: TBitmap32; aRegion: TRect);
var
  x, y: Integer;
  PSrc,PDst: PColor32;
  C: TColor32;

  function Redify(aColor: TColor32): TColor32;
  var
    R, G, B: Byte;
  begin
    R := RedComponent(aColor);
    G := GreenComponent(aColor);
    B := BlueComponent(aColor);
    R := Max((R + 255) div 2, $80);
    G := Max(G div 2, $20);
    B := Max(B div 2, $20);
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
  end;
begin
  // It's very messy to track position in a custom pixelcombine, hence using an entirely
  // custom procedure instead.
  IntersectRect(aRegion, aRegion, fPhysicsMap.BoundsRect);
  for y := aRegion.Top to aRegion.Bottom-1 do
  begin
    PSrc := fPhysicsMap.PixelPtr[aRegion.Left, y];
    PDst := aDst.PixelPtr[aRegion.Left, y];
    Dec(PSrc); // so we can put Inc(P) at the start of the next loop rather than having to use lots of if statements
    Dec(PDst);
    for x := aRegion.Left to aRegion.Right-1 do
    begin
      Inc(PSrc);
      Inc(PDst);

      if PSrc^ and PM_SOLID <> 0 then
      begin
        if PSrc^ and PM_STEEL = 0 then
          C := $FFB0B0B0
        else
          C := $FF606060;
      end else
        C := 0;

      if (x = 0) or (y = 0) or (x = fPhysicsMap.Width-1) or (y = fPhysicsMap.Height-1) then
        C := Redify(C);

      if C = 0 then Continue;

      if ((x mod 2) <> (y mod 2)) then
          C := C - $00202020;

      PDst^ := C;
    end;
  end;
end;

end.
