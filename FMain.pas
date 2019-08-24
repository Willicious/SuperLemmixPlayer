{$include lem_directives.inc}

unit FMain;

{-------------------------------------------------------------------------------
  This is the main form which does almost nothing.
-------------------------------------------------------------------------------}

interface

uses
  LemSystemMessages,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  StdCtrls,
  FBaseDosForm,
  LemNeoLevelPack, // compile test
  LemGame,
  AppController;

type
  TMainForm = class(TBaseDosForm)
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
  private
    Started: Boolean;
    AppController: TAppController;
    fChildForm: TForm;
    procedure LMStart(var Msg: TMessage); message LM_START;
    procedure LMNext(var Msg: TMessage); message LM_NEXT;
    procedure LMExit(var Msg: TMessage); message LM_EXIT;
    procedure PlayGame;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property ChildForm: TForm read fChildForm write fChildForm;
  end;

var
  MainForm: TMainForm;

implementation

uses
  SharedGlobals, // debug
  Math,
  GameControl, GameBaseScreen;

{$R *.dfm}

procedure TMainForm.LMStart(var Msg: TMessage);
begin
  PlayGame;
end;

procedure TMainForm.LMNext(var Msg: TMessage);
begin
  AppController.FreeScreen;
  PlayGame;
end;

procedure TMainForm.LMExit(var Msg: TMessage);
begin
  AppController.FreeScreen;
  Close;
end;

constructor TMainForm.Create(aOwner: TComponent);
begin
  inherited;
  GlobalGame := TLemmingGame.Create(nil);
  AppController := TAppController.Create(self);
end;

destructor TMainForm.Destroy;
begin
  GlobalGame.Free;
  AppController.Free;
  inherited;
end;

procedure TMainForm.PlayGame;
begin
  try
    if not AppController.Execute then
    begin
      Close;
    end else if Assigned(ChildForm.OnActivate) then
      ChildForm.OnActivate(ChildForm); 
  except
    on E: Exception do
    begin
      Application.ShowException(E);
      Close;
    end;
  end;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if Started then
    Exit;

  Started := True;
  MainFormHandle := Handle;
  PostMessage(Handle, LM_START, 0, 0);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if fChildForm = nil then Exit;
  if not Assigned(fChildForm.OnKeyDown) then Exit;
  fChildForm.OnKeyDown(Sender, Key, Shift);
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if fChildForm = nil then Exit;
  if not Assigned(fChildForm.OnKeyUp) then Exit;
  fChildForm.OnKeyUp(Sender, Key, Shift);
end;

procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if fChildForm = nil then Exit;
  if not Assigned(fChildForm.OnMouseDown) then Exit;
  fChildForm.OnMouseDown(Sender, Button, Shift, X, Y);
end;

procedure TMainForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if fChildForm = nil then Exit;
  if not Assigned(fChildForm.OnMouseUp) then Exit;
  fChildForm.OnMouseUp(Sender, Button, Shift, X, Y);
end;

procedure TMainForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if fChildForm = nil then Exit;
  if not Assigned(fChildForm.OnMouseMove) then Exit;
  fChildForm.OnMouseMove(Sender, Shift, X, Y);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if GameParams = nil then Exit;
  if not (fChildForm is TGameBaseScreen) then Exit;
  TGameBaseScreen(fChildForm).MainFormResized;
  GameParams.WindowWidth := ClientWidth;
  GameParams.WindowHeight := ClientHeight;
  // Seems pointless? Yes. But apparently, changing between maximized and not maximized
  // causes the handle to change, which was causing the fullscreen-windowed change glitch.
  MainFormHandle := Handle;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
var
  CWDiff, CHDiff: Integer;
  NewCW, NewCH: Integer;
begin
  if GameParams = nil then Exit;

  if GameParams.FullScreen then
  begin
    NewWidth := Screen.Width;
    NewHeight := Screen.Height;
    Exit;
  end;

  CWDiff := Width - ClientWidth;
  CHDiff := Height - ClientHeight;

  NewCW := NewWidth - CWDiff;
  NewCH := NewHeight - CHDiff;

  if GameParams.CompactSkillPanel then
    NewCW := Max(320, NewCW)
  else
    NewCW := Max(416, NewCW);
  NewCH := Max(200, NewCH);

  NewCW := Min(NewCW, Screen.Width - CWDiff);
  NewCH := Min(NewCH, Screen.Height - CHDiff);

  NewWidth := NewCW + CWDiff;
  NewHeight := NewCH + CHDiff;
end;

procedure TMainForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(fChildForm.OnMouseWheel) then
    fChildForm.OnMouseWheel(Sender, Shift, WheelDelta, MousePos, Handled);
end;

end.
//system
