unit FBaseDosForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Gr32,
  GameControl;

type
  {-------------------------------------------------------------------------------
    abstract black, fullscreen, ancestor form
  -------------------------------------------------------------------------------}
  TBaseDosForm = class(TForm)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure BuildScreen; virtual;
    procedure PrepareGameParams; virtual; // always call inherited

    function IsGameplayScreen: Boolean; virtual;
  public
    constructor Create(aOwner: TComponent); override;
    function ShowScreen: Integer; virtual;

  end;

implementation

uses
  FMain;

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
  WindowState := wsNormal {wsMaximized};
  Cursor := crNone;
  HorzScrollBar.Visible := False;
  VertScrollBar.Visible := False;
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
var
  Scale: Integer;
begin
  if GameParams.fTestMode then
    Caption := 'NeoLemmix - Single Level'
  else
    Caption := Trim(GameParams.SysDat.PackName);

  //if GameParams.ZoomLevel <> 0 then
  //begin
    //BorderStyle := bsToolWindow;
    //WindowState := wsNormal;
    Parent := GameParams.MainForm;
    ClientWidth := GameParams.MainForm.Width;
    ClientHeight := GameParams.MainForm.Height;
    Left := 0; //GameParams.MainForm.Left;
    Top := 0; //GameParams.MainForm.Top;
  //end;

end;

function TBaseDosForm.ShowScreen: Integer;
begin
  PrepareGameParams;
  BuildScreen;
  TMainForm(GameParams.MainForm).ChildForm := self;
  Cursor := crNone;
  Screen.Cursor := crNone;
  Show;
end;

function TBaseDosForm.IsGameplayScreen: Boolean;
begin
  Result := false;
end;

end.

