unit FBaseDosForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  UMisc, Gr32,
  GameControl;

const
  WM_AFTERSHOW = WM_USER + $1;

type
  {-------------------------------------------------------------------------------
    abstract black, fullscreen, ancestor form
  -------------------------------------------------------------------------------}
  TBaseDosForm = class(TForm)
  private
    procedure HideMainForm(var msg : TMessage); message WM_AFTERSHOW;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure BuildScreen; virtual;
    procedure PrepareGameParams; virtual; // always call inherited
  public
    constructor Create(aOwner: TComponent); override;
    function ShowScreen: Integer; virtual;

  end;

implementation

{$R *.dfm}

{ TBaseDosForm }

procedure TBaseDosForm.BuildScreen;
begin
  //
end;



constructor TBaseDosForm.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  Caption := 'NeoLemmix';
  Color := clBlack;
  BorderStyle := {bsSizeable} bsNone;
  BorderIcons := [{biSystemMenu, biMinimize, biMaximize}];
  WindowState := {wsNormal} wsMaximized;
  Cursor := crNone;
end;

procedure TBaseDosForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
  begin
    Style := Style or CS_OWNDC; // maybe faster screen output
  end;
end;

procedure TBaseDosForm.PrepareGameParams;
begin
  if GameParams.fTestMode then
    Caption := 'NeoLemmix - Single Level'
  else
    Caption := Trim(GameParams.SysDat.PackName);

  if GameParams.ZoomLevel <> 0 then
  begin
    BorderStyle := bsToolWindow;
    WindowState := wsNormal;
    ClientWidth := 320 * GameParams.ZoomLevel;
    ClientHeight := 200 * GameParams.ZoomLevel;
    Left := GameParams.MainForm.Left;
    Top := GameParams.MainForm.Top;
  end;

end;

function TBaseDosForm.ShowScreen: Integer;
begin
  PrepareGameParams;
  BuildScreen;
  Result := ShowModal;
end;

procedure TBaseDosForm.HideMainForm(var msg : TMessage);
begin
  // Tried a hundred different ways to prevent the between-screen flickering in windowed mode.
  // Nothing seems to work, but this way seems to have the least-noticable flickering.
  if (GameParams <> nil) and (GameParams.ZoomLevel <> 0) and (GameParams.MainForm <> self) then
  begin
    GameParams.MainForm.Visible := false;
  end;
end;

end.

