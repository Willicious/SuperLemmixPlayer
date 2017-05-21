{$include lem_directives.inc}
unit GameSkillPanel;

interface

uses
  Classes, GR32,
  GameWindowInterface, GameBaseSkillPanel;

type
  TSkillPanelToolbar = class(TBaseSkillPanel)
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
    constructor Create(aOwner: TComponent; aGameWindow: IGameWindow); override;
    destructor Destroy; override;
  end;

implementation

uses
  GameControl, LemCore;

constructor TSkillPanelToolbar.Create(aOwner: TComponent; aGameWindow: IGameWindow);
begin
  inherited Create(aOwner, aGameWindow);
end;

destructor TSkillPanelToolbar.Destroy;
begin
  inherited;
end;

function TSkillPanelToolbar.PanelWidth: Integer;
begin
  if GameParams.CompactSkillPanel then
    Result := 320
  else
    Result := 416;
end;

function TSkillPanelToolbar.PanelHeight: Integer;
begin
  if GameParams.CompactSkillPanel then
    Result := 40
  else
    Result := 40;
end;


function TSkillPanelToolbar.DrawStringLength: Integer;
begin
  Result := 38;
end;

function TSkillPanelToolbar.DrawStringTemplate: string;
begin
  Result := '............' + '.' + ' ' + #92 + '_...' + ' ' + #93 + '_...' + ' '
                           + #94 + '_...' + ' ' + #95 +  '_.-..';
end;

procedure TSkillPanelToolbar.CreateNewInfoString;
begin
  SetInfoCursorLemming(1);
  SetReplayMark(13);
  SetInfoLemHatch(16);
  SetInfoLemAlive(22);
  SetInfoLemIn(28);
  SetTimeLimit(33);
  SetInfoTime(34, 37);
end;

function TSkillPanelToolbar.GetButtonList: TPanelButtonArray;
var
  ButtonList: TPanelButtonArray;
  i : Integer;
begin
  if GameParams.CompactSkillPanel then
  begin
    SetLength(ButtonList, 13);
    ButtonList[0] := spbSlower;
    ButtonList[1] := spbFaster;
    for i := 2 to 9 do
      ButtonList[i] := spbWalker; // placeholder for any skill
    ButtonList[10] := spbPause;
    ButtonList[11] := spbNuke;
    ButtonList[12] := spbFastForward;
  end
  else
  begin
    SetLength(ButtonList, 19);
    ButtonList[0] := spbSlower;
    ButtonList[1] := spbFaster;
    for i := 2 to 9 do
      ButtonList[i] := spbWalker; // placeholder for any skill
    ButtonList[10] := spbPause;
    ButtonList[11] := spbNuke;
    ButtonList[12] := spbFastForward;
    ButtonList[13] := spbRestart;
    ButtonList[14] := spbBackOneFrame;
    ButtonList[15] := spbForwardOneFrame;
    ButtonList[16] := spbClearPhysics;
    ButtonList[17] := spbDirLeft; // includes spbDirRight
    ButtonList[18] := spbLoadReplay;
  end;

  Result := ButtonList;
end;

procedure TSkillPanelToolbar.ResizeMinimapRegion(MinimapRegion: TBitmap32);
var
  TempBmp: TBitmap32;
begin
  TempBmp := TBitmap32.Create;
  TempBmp.Assign(MinimapRegion);

  if (MinimapRegion.Height <> 38) and not GameParams.CompactSkillPanel then
  begin
    MinimapRegion.SetSize(111, 38);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 14);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 16));
  end;

  if (MinimapRegion.Height <> 24) and GameParams.CompactSkillPanel then
  begin
    MinimapRegion.SetSize(111, 24);
    MinimapRegion.Clear($FF000000);
    TempBmp.DrawTo(MinimapRegion, 0, 0, Rect(0, 0, 112, 12));
    TempBmp.DrawTo(MinimapRegion, 0, 12, Rect(0, 26, 112, 38));
  end;

  TempBmp.Free;
end;

function TSkillPanelToolbar.MinimapRect: TRect;
begin
  if GameParams.CompactSkillPanel then
    Result := Rect(212, 18, 316, 38)
  else
    Result := Rect(308, 3, 412, 37);
end;

end.

