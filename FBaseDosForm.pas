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
    procedure PrepareGameParams; virtual; // Always call inherited

    function IsGameplayScreen: Boolean; virtual;
  public
    constructor Create(aOwner: TComponent); override;
    procedure ShowScreen; virtual;

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
  Caption := 'SuperLemmix';
  Color := clBlack;
  BorderStyle := bsNone;
  BorderIcons := [];
  WindowState := wsNormal;
  Cursor := crNone;
  HorzScrollBar.Visible := False;
  VertScrollBar.Visible := False;
end;

procedure TBaseDosForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
  begin
    Style := Style or CS_OWNDC; // Maybe faster screen output
  end;
end;

procedure TBaseDosForm.PrepareGameParams;
begin
  Parent := GameParams.MainForm;
  ClientWidth := GameParams.MainForm.ClientWidth;
  ClientHeight := GameParams.MainForm.ClientHeight;
  Left := 0;
  Top := 0;
end;

procedure TBaseDosForm.ShowScreen;
begin
  try
    PrepareGameParams;
    BuildScreen;
  except
    on E : EAbort do Exit; // Should only happen if some level piece is missing
  end;
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

