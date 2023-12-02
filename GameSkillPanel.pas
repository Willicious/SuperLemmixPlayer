{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  LemTypes,
  Classes, GR32,
  GameWindowInterface, GameBaseSkillPanel;

type
  TSkillPanelStandard = class(TBaseSkillPanel)
  protected
    function GetButtonList: TPanelButtonArray; override;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    function MinimapRect: TRect; override;

    procedure CreateNewInfoString; override;
    function DrawStringLength: Integer; override;
    function DrawStringTemplate: string; override;
    function TimeLimitStartIndex: Integer; override;
    function LemmingCountStartIndex: Integer; override;
    function LemmingSavedStartIndex: Integer; override;
  public
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

implementation

uses
  GameControl, LemCore;

constructor TSkillPanelStandard.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited;
end;

destructor TSkillPanelStandard.Destroy;
begin
  inherited;
end;

function TSkillPanelStandard.PanelWidth: Integer;
begin
if GameParams.ShowMinimap then
  begin
    Result := 444 * ResMod;
  end else begin
    Result := 336 * ResMod;
  end;
end;

function TSkillPanelStandard.PanelHeight: Integer;
begin
  Result := 40 * ResMod;
end;

function TSkillPanelStandard.DrawStringLength: Integer;
begin
  Result := 42;
end;

function TSkillPanelStandard.DrawStringTemplate: string;
begin
  Result := '...............' + '.' + '  ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;

function TSkillPanelStandard.TimeLimitStartIndex: Integer;
begin
  Result := 37;
end;

// First set of digits adust left & top pos of minimap frame
// Second set of digits adjusts width & height of minimap itself
function TSkillPanelStandard.MinimapRect: TRect;
begin
//if GameParams.ShowMinimap then //Bookmark - why is this commented out?
  begin
    Result := Rect(355 * ResMod, 2 * ResMod, 440 * ResMod, 36 * ResMod);
  end;
end;

procedure TSkillPanelStandard.CreateNewInfoString;
begin
  SetInfoCursorLemming(1);
  SetReplayMark(16);
  SetInfoLemHatch(20);
  SetInfoLemAlive(26);
  SetInfoLemIn(32);
  SetTimeLimit(37);
  SetInfoTime(38, 41);
end;

function TSkillPanelStandard.GetButtonList: TPanelButtonArray;
var
  i : Integer;
begin
  SetLength(Result, 24);
  Result[0] := spbSlower;
  Result[1] := spbFaster;
  for i := 2 to (0 + MAX_SKILL_TYPES_PER_LEVEL -1) do
    Result[i] := Low(TSkillPanelButton); // Placeholder for any skill
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL] := spbPause;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 1] := spbRewind;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 2] := spbFastForward;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 3] := spbRestart;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 4] := spbNuke;
  Result[2 + MAX_SKILL_TYPES_PER_LEVEL + 5] := spbSquiggle;
end;

function TSkillPanelStandard.LemmingCountStartIndex: Integer;
begin
  Result := 26;
end;

function TSkillPanelStandard.LemmingSavedStartIndex: Integer;
begin
  Result := 32;
end;

procedure TSkillPanelStandard.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
if GameParams.ShowMinimap then
  begin
    TempBmp := TBitmap32.Create;
    TempBmp.Assign(MinimapRegion);

  // Changing the first digit changes the right side of the minimap frame
    if (MinimapRegion.Width <> 91 * ResMod) or (MinimapRegion.Height <> 39 * ResMod) then
    begin
      MinimapRegion.SetSize(91 * ResMod, 39 * ResMod);
      MinimapRegion.Clear($FF000000);
      DrawNineSlice(MinimapRegion, MinimapRegion.BoundsRect, TempBmp.BoundsRect,
                  Rect(8 * ResMod, 8 * ResMod, 8 * ResMod, 8 * ResMod), TempBmp);
    end;

    TempBmp.Free;
  end;
end;

end.

