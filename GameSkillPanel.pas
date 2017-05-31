{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
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
  public
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

  TSkillPanelCompact = class(TBaseSkillPanel)
  protected
    function GetButtonList: TPanelButtonArray; override;

    function PanelWidth: Integer; override;
    function PanelHeight: Integer; override;

    procedure ResizeMinimapRegion(MinimapRegion: TBitmap32); override;
    function MinimapRect: TRect; override;

    procedure CreateNewInfoString; override;
    function DrawStringLength: Integer; override;
    function DrawStringTemplate: string; override;
  public
    constructor CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

implementation

uses
  GameControl, LemCore;

{ TSkillPanelStandard }

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
  Result := 416;
end;

function TSkillPanelStandard.PanelHeight: Integer;
begin
  Result := 40;
end;

function TSkillPanelStandard.DrawStringLength: Integer;
begin
  Result := 38;
end;

function TSkillPanelStandard.DrawStringTemplate: string;
begin
  Result := '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;

function TSkillPanelStandard.MinimapRect: TRect;
begin
  Result := Rect(308, 3, 412, 37);
end;

procedure TSkillPanelStandard.CreateNewInfoString;
begin
  SetInfoCursorLemming(1);
  SetReplayMark(13);
  SetInfoLemHatch(16);
  SetInfoLemAlive(22);
  SetInfoLemIn(28);
  SetTimeLimit(33);
  SetInfoTime(34, 37);
end;

function TSkillPanelStandard.GetButtonList: TPanelButtonArray;
var
  i : Integer;
begin
  SetLength(Result, 19);
  Result[0] := spbSlower;
  Result[1] := spbFaster;
  for i := 2 to 9 do
    Result[i] := spbWalker; // placeholder for any skill
  Result[10] := spbPause;
  Result[11] := spbNuke;
  Result[12] := spbFastForward;
  Result[13] := spbRestart;
  Result[14] := spbBackOneFrame;
  Result[15] := spbForwardOneFrame;
  Result[16] := spbClearPhysics;
  Result[17] := spbDirLeft; // includes spbDirRight
  Result[18] := spbLoadReplay;
end;

procedure TSkillPanelStandard.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(MinimapRegion);

  if (MinimapRegion.Height <> 38) then
  begin
    MinimapRegion.SetSize(111, 38);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 14);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 16));
  end;

  TempBmp.Free;
end;


{ TSkillPanelCompact }

constructor TSkillPanelCompact.CreateWithWindow(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited;
end;

destructor TSkillPanelCompact.Destroy;
begin
  inherited;
end;

function TSkillPanelCompact.PanelWidth: Integer;
begin
  Result := 320
end;

function TSkillPanelCompact.PanelHeight: Integer;
begin
  Result := 40;
end;

function TSkillPanelCompact.DrawStringLength: Integer;
begin
  Result := 38;
end;

function TSkillPanelCompact.DrawStringTemplate: string;
begin
  Result := '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;

function TSkillPanelCompact.MinimapRect: TRect;
begin
  Result := Rect(212, 18, 316, 38)
end;

procedure TSkillPanelCompact.CreateNewInfoString;
begin
  SetInfoCursorLemming(1);
  SetReplayMark(13);
  SetInfoLemHatch(16);
  SetInfoLemAlive(22);
  SetInfoLemIn(28);
  SetTimeLimit(33);
  SetInfoTime(34, 37);
end;

function TSkillPanelCompact.GetButtonList: TPanelButtonArray;
var
  i : Integer;
begin
  SetLength(Result, 13);
  Result[0] := spbSlower;
  Result[1] := spbFaster;
  for i := 2 to 9 do
    Result[i] := spbWalker; // placeholder for any skill
  Result[10] := spbPause;
  Result[11] := spbNuke;
  Result[12] := spbFastForward;
end;

procedure TSkillPanelCompact.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(MinimapRegion);

  if (MinimapRegion.Height <> 24) then
  begin
    MinimapRegion.SetSize(111, 24);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 12));
    TempBmp.DrawTo(MinimapRegion, 0, 12, Rect(0, 26, 112, 38));
  end;

  TempBmp.Free;
end;


end.

