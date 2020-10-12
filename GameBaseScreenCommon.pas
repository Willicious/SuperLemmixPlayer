{$include lem_directives.inc}
unit GameBaseScreenCommon;

interface

uses
  System.Types,
  Windows, Messages, Classes, Controls, Graphics, MMSystem, Forms, Dialogs, Math,
  GR32, GR32_Image, GR32_Layers, GR32_Resamplers,
  FBaseDosForm,
  GameControl,
  LemSystemMessages,
  LemStrings, PngInterface, LemTypes,
  LemReplay, LemGame,
  LemCursor,
  LemMenuFont,
  SysUtils;

const
  INTERNAL_SCREEN_WIDTH = 864;
  INTERNAL_SCREEN_HEIGHT = 486;

const
  EXTRA_ZOOM_LEVELS = 4;

type
  {-------------------------------------------------------------------------------
    This is the ancestor for all dos forms that are used in the program.
  -------------------------------------------------------------------------------}
  TGameBaseScreen = class(TBaseDosForm)
  private
    fScreenImg           : TImage32;
    fBackGround          : TBitmap32;
    fBackBuffer          : TBitmap32; // general purpose buffer
    fOriginalImageBounds : TRect;
    fScreenIsClosing     : Boolean;
    fCloseDelay          : Integer;

    procedure AdjustImage;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure PrepareGameParams; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property ScreenIsClosing: Boolean read fScreenIsClosing;
    property CloseDelay: Integer read fCloseDelay write fCloseDelay;

    function LoadReplay: Boolean;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
    procedure ExtractBackGround;
    procedure FadeOut;
    procedure InitializeImageSizeAndPosition(aWidth, aHeight: Integer);

    procedure MainFormResized; virtual; abstract;

    property ScreenImg: TImage32 read fScreenImg;
    property BackGround: TBitmap32 read fBackGround;
    property BackBuffer: TBitmap32 read fBackBuffer;
  end;

implementation

uses
  LemNeoPieceManager, FMain,
  FNeoLemmixConfig, LemNeoLevelPack, FNeoLemmixLevelSelect, UITypes;

{ TGameBaseScreen }

procedure TGameBaseScreen.CNKeyDown(var Message: TWMKeyDown);
var
  AssignedEventHandler: TKeyEvent;
begin
  AssignedEventHandler := OnKeyDown;
  if Message.CharCode = vk_tab then
    if Assigned(AssignedEventHandler) then
      OnKeyDown(Self, Message.CharCode, KeyDataToShiftState(Message.KeyData));
  inherited;
end;

procedure TGameBaseScreen.AdjustImage;
begin
  fScreenImg.Align := alClient;
  fScreenImg.ScaleMode := smResize;
  fScreenImg.BitmapAlign := baCenter;

  Update;
  Changed;
end;

procedure TGameBaseScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  Self.OnKeyDown := nil;
  Self.OnKeyPress := nil;
  Self.OnClick := nil;
  Self.OnMouseDown := nil;
  Self.OnMouseMove := nil;
  ScreenImg.OnMouseDown := nil;
  ScreenImg.OnMouseMove := nil;
  Application.OnIdle := nil;
  fScreenIsClosing := True;
  if fCloseDelay > 0 then
  begin
    Update;
    Sleep(fCloseDelay);
  end;

  FadeOut;

  if GameParams <> nil then
  begin
    GameParams.NextScreen := aNextScreen;
    GameParams.MainForm.Cursor := crNone;
  end;

  Close;

  SendMessage(MainFormHandle, LM_NEXT, 0, 0);
end;

constructor TGameBaseScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fScreenImg := TImage32.Create(Self);
  fScreenImg.Parent := Self;

  fBackGround := TBitmap32.Create;
  fBackBuffer := TBitmap32.Create;

  ScreenImg.Cursor := crNone;
end;

destructor TGameBaseScreen.Destroy;
begin
  fBackGround.Free;
  fBackBuffer.Free;
  inherited Destroy;
end;

procedure TGameBaseScreen.ExtractBackground;
begin
  if (not (GameParams.CurrentLevel = nil))
     and FileExists(GameParams.CurrentLevel.Group.FindFile('background.png')) then
    TPngInterface.LoadPngFile(GameParams.CurrentLevel.Group.FindFile('background.png'), fBackground)
  else if FileExists(AppPath + SFGraphicsMenu + 'background.png') then
    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'background.png', fBackground);
end;

procedure TGameBaseScreen.InitializeImageSizeAndPosition(aWidth, aHeight: Integer);
begin
  with fScreenImg do
  begin
    Bitmap.SetSize(aWidth, aHeight);

    with fOriginalImageBounds do
    begin
      Left := 0;
      Height := 0;
      Right := ClientWidth;
      Bottom := ClientHeight;
    end;

    BoundsRect := fOriginalImageBounds;

    AdjustImage;

    if GameParams.LinearResampleMenu and not IsGameplayScreen then
      TLinearResampler.Create(fScreenImg.Bitmap);
  end;
end;

procedure TGameBaseScreen.PrepareGameParams;
begin
  inherited;
end;

procedure TGameBaseScreen.TileBackgroundBitmap(X, Y: Integer; Dst: TBitmap32 = nil);
var
  aX, aY: Integer;
begin
  if Dst = nil then Dst := fScreenImg.Bitmap;
  if (fBackground.Width = 0) or (fBackground.Height = 0) then Exit;

  aY := Y;
  aX := X;
  while aY <= Dst.Height do
  begin
    while aX <= Dst.Width do
    begin
      fBackground.DrawTo(Dst, aX, aY);
      Inc(aX, fBackground.Width);
    end;
    Inc(aY, fBackground.Height);
    aX := X;
  end;

end;

procedure TGameBaseScreen.FadeOut;
var
  Steps: Cardinal;
  i: Integer;
  P: PColor32;
  StartTickCount: Cardinal;
  IterationDiff: Integer;
  RGBDiff: Integer;
const
  TOTAL_STEPS = 32;
  STEP_DELAY = 6;
begin
  Steps := 0;
  StartTickCount := GetTickCount;
  while Steps < TOTAL_STEPS do
  begin
    IterationDiff := ((GetTickCount - StartTickCount) div STEP_DELAY) - Steps;

    if IterationDiff = 0 then
      Continue;

    RGBDiff := IterationDiff * 8;

    with ScreenImg.Bitmap do
    begin
      P := PixelPtr[0, 0];
      for i := 0 to Width * Height - 1 do
      begin
        with TColor32Entry(P^) do
        begin
          if R > RGBDiff then Dec(R, RGBDiff) else R := 0;
          if G > RGBDiff then Dec(G, RGBDiff) else G := 0;
          if B > RGBDiff then Dec(B, RGBDiff) else B := 0;
        end;
        Inc(P);
      end;
    end;
    Inc(Steps, IterationDiff);

    ScreenImg.Bitmap.Changed;
    Changed;
    Update;
  end;

  Application.ProcessMessages;
end;

function TGameBaseScreen.LoadReplay: Boolean;
var
  Dlg: TOpenDialog;
  s: String;

  function GetDefaultLoadPath: String;
    function GetGroupName: String;
    var
      G: TNeoLevelGroup;
    begin
      G := GameParams.CurrentLevel.Group;
      if G.Parent = nil then
        Result := ''
      else begin
        while not (G.IsBasePack or (G.Parent.Parent = nil)) do
          G := G.Parent;
        Result := MakeSafeForFilename(G.Name, false) + '\';
      end;
    end;
  begin
    Result := AppPath + 'Replay\' + GetGroupName;
  end;

  function GetInitialLoadPath: String;
  begin
    if (LastReplayDir <> '') then
      Result := LastReplayDir
    else
      Result := GetDefaultLoadPath;
  end;
begin
  s := '';
  Dlg := TOpenDialog.Create(self);
  try
    Dlg.Title := 'Select a replay file to load (' + GameParams.CurrentGroupName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
    Dlg.Filter := 'NeoLemmix Replay File (*.nxrp)|*.nxrp';
    Dlg.FilterIndex := 1;
    if LastReplayDir = '' then
    begin
      Dlg.InitialDir := AppPath + 'Replay\' + GetInitialLoadPath;
      if not DirectoryExists(Dlg.InitialDir) then
        Dlg.InitialDir := AppPath + 'Replay\';
      if not DirectoryExists(Dlg.InitialDir) then
        Dlg.InitialDir := AppPath;
    end else
      Dlg.InitialDir := LastReplayDir;
    Dlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    if Dlg.execute then
    begin
      s:=Dlg.filename;
      LastReplayDir := ExtractFilePath(s);
      Result := true;
    end else
      Result := false;
  finally
    Dlg.Free;
  end;

  if s <> '' then
  begin
    GlobalGame.ReplayManager.LoadFromFile(s);
    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level. NeoLemmix' + #13 +
                  'will attempt to play the replay anyway.');
  end;
end;

end.

