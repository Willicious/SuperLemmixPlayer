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
    fGameParams: TDosGameParams;
    procedure OnShowForm(Sender: TObject);
    procedure HideMainForm(var msg : TMessage); message WM_AFTERSHOW;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure BuildScreen; virtual;
    procedure PrepareGameParams(Params: TDosGameParams); virtual; // always call inherited
    property GameParams: TDosGameParams read fGameParams;
  public
    constructor Create(aOwner: TComponent); override;
    function ShowScreen(Params: TDosGameParams): Integer; virtual;

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
  //OnActivate := OnShowForm;
end;

procedure TBaseDosForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
  begin
    Style := Style or CS_OWNDC; // maybe faster screen output
  end;
end;

procedure TBaseDosForm.PrepareGameParams(Params: TDosGameParams);
begin
  fGameParams := Params;
  if fGameParams.fTestMode then
    Caption := 'NeoLemmix - Single Level'
  else
    Caption := Trim(fGameParams.SysDat.PackName);

  if fGameParams.ZoomLevel <> 0 then
  begin
    BorderStyle := bsToolWindow;
    WindowState := wsNormal;
    ClientWidth := 320 * fGameParams.ZoomLevel;
    ClientHeight := 200 * fGameParams.ZoomLevel;
    Left := fGameParams.MainForm.Left;
    Top := fGameParams.MainForm.Top;
  end;

end;

function TBaseDosForm.ShowScreen(Params: TDosGameParams): Integer;
begin
  PrepareGameParams(Params);
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

procedure TBaseDosForm.OnShowForm(Sender: TObject);
begin
  //HideMainForm;
  PostMessage(Handle, WM_AFTERSHOW, 0, 0);
end;

end.

