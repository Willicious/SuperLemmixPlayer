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
  LemGame, LemTypes,
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
    procedure FormShow(Sender: TObject);
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  private
    Started: Boolean;
    AppController: TAppController;
    fChildForm: TForm;
    procedure LMStart(var Msg: TMessage); message LM_START;
    procedure LMNext(var Msg: TMessage); message LM_NEXT;
    procedure LMExit(var Msg: TMessage); message LM_EXIT;
    procedure OnMove(var Msg: TWMMove); message WM_MOVE;
    procedure PlayGame;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property ChildForm: TForm read fChildForm write fChildForm;

    procedure RestoreDefaultSize;
    procedure RestoreDefaultPosition;
  end;

var
  MainForm: TMainForm;

implementation

uses
  SharedGlobals, // debug
  Math,
  GameControl, GameBaseScreenCommon;

{$R *.dfm}

procedure TMainForm.CNKeyDown(var Message: TWMKeyDown);
var
  AssignedEventHandler: TKeyEvent;
begin
  AssignedEventHandler := OnKeyDown;
  if Message.CharCode = vk_tab then
    if Assigned(AssignedEventHandler) then
      OnKeyDown(Self, Message.CharCode, KeyDataToShiftState(Message.KeyData));
  inherited;
end;

procedure TMainForm.LMStart(var Msg: TMessage);
begin
  PlayGame;
end;

procedure TMainForm.OnMove(var Msg: TWMMove);
begin
  inherited;

  if GameParams <> nil then
  begin
    GameParams.WindowLeft := Left;
    GameParams.WindowTop := Top;
  end;
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

procedure TMainForm.RestoreDefaultPosition;
begin
  Left := (Screen.WorkAreaWidth div 2) - (Width div 2);
  Top := (Screen.WorkAreaHeight div 2) - (Height div 2);
end;

procedure TMainForm.RestoreDefaultSize;
var
  WindowScale: Integer;
begin
  WindowScale := Min(Screen.Width div 444, Screen.Height div 200);
  WindowScale := Min(WindowScale, GameParams.ZoomLevel * ResMod);

  if WindowScale < ResMod then
    WindowScale := ResMod;

  if GameParams.ShowMinimap then
  begin
    ClientWidth := Max(WindowScale * 444, 444 * ResMod);     //1776
    ClientHeight := ClientWidth * 50 div 111;                //800
  end else begin
    ClientWidth := Max(WindowScale * 340, 340 * ResMod);
    ClientHeight := ClientWidth * 10 div 17;
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

procedure TMainForm.FormShow(Sender: TObject);
begin
  inherited;
  // Unless fullscreen, resize the main window
  if not GameParams.FullScreen then
  begin
    GameParams.MainForm.BorderStyle := bsSizeable;
    GameParams.MainForm.WindowState := wsNormal;
    GameParams.MainForm.Left := GameParams.LoadedWindowLeft;
    GameParams.MainForm.Top := GameParams.LoadedWindowTop;
    GameParams.MainForm.ClientWidth := GameParams.LoadedWindowWidth;
    GameParams.MainForm.ClientHeight := GameParams.LoadedWindowHeight;
  end else begin
    GameParams.MainForm.Left := 0;
    GameParams.MainForm.Top := 0;
    GameParams.MainForm.BorderStyle := bsNone;
    GameParams.MainForm.WindowState := wsMaximized;

    GameParams.MainForm.ClientWidth := Screen.Width;
    GameParams.MainForm.ClientHeight := Screen.Height;
  end;
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

  NewCW := Max(444 * ResMod, NewCW);
  NewCH := Max(200 * ResMod, NewCH);

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

