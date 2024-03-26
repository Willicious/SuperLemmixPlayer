{$include lem_directives.inc}
unit GameBaseScreenCommon;

interface

uses
  Windows, Messages, Classes, Controls, Forms, Dialogs,
  GR32, GR32_Image,
  FBaseDosForm,
  GameControl,
  LemSystemMessages,
  PngInterface, LemTypes,
  LemReplay, LemGame, LemStrings,
  SysUtils;

const
  EXTRA_ZOOM_LEVELS = 4;

type
  {-------------------------------------------------------------------------------
    This is the ancestor for all dos forms that are used in the program.
  -------------------------------------------------------------------------------}
  TGameBaseScreen = class(TBaseDosForm)
  private
    fScreenImg           : TImage32;
    fScreenIsClosing     : Boolean;
    fCloseDelay          : Integer;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
  protected
    procedure CloseScreen(aNextScreen: TGameScreenType); virtual;
    property ScreenIsClosing: Boolean read fScreenIsClosing;
    property CloseDelay: Integer read fCloseDelay write fCloseDelay;

  public
    function LoadReplay: Boolean;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure FadeOut;

    procedure MainFormResized; virtual; abstract;

    property ScreenImg: TImage32 read fScreenImg;
  end;

implementation

uses
  LemNeoPieceManager, FMain,
  FSuperLemmixConfig, LemNeoLevelPack, FSuperLemmixLevelSelect, UITypes;

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

  PostMessage(MainFormHandle, LM_NEXT, 0, 0);
end;

constructor TGameBaseScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fScreenImg := TImage32.Create(Self);
  fScreenImg.Parent := Self;
  ScreenImg.Cursor := crNone;
end;

destructor TGameBaseScreen.Destroy;
begin
  inherited Destroy;
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
  STEP_DELAY = 12;
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
    Result := AppPath + SFReplays + GetGroupName;
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

  if OpenedViaReplay then
  begin
    Result := true; // Return true if opened by replay
    s := LoadedReplayFile;

  end else begin
    Dlg := TOpenDialog.Create(self);
    try
      Dlg.Title := 'Select a replay file to load (' + GameParams.CurrentGroupName + ' ' + IntToStr(GameParams.CurrentLevel.GroupIndex + 1) + ', ' + Trim(GameParams.Level.Info.Title) + ')';
      Dlg.Filter := 'SuperLemmix Replay File (*.nxrp)|*.nxrp';
      Dlg.FilterIndex := 1;
      if LastReplayDir = '' then
      begin
        Dlg.InitialDir := AppPath + SFReplays + GetInitialLoadPath;
        if not DirectoryExists(Dlg.InitialDir) then
          Dlg.InitialDir := AppPath + SFReplays;
        if not DirectoryExists(Dlg.InitialDir) then
          Dlg.InitialDir := AppPath;
      end else
        Dlg.InitialDir := LastReplayDir;

      Dlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
      if Dlg.execute then
      begin
        s := Dlg.filename;
        LastReplayDir := ExtractFilePath(s);
        Result := true; // Return true if the file was successfully selected
      end else
        Result := false; // Return false if the user canceled the dialog
    finally
      Dlg.Free;
    end;
  end;

  if s <> '' then
  begin
    GlobalGame.ReplayManager.LoadFromFile(s);
    GlobalGame.ReplayWasLoaded := True;
    if GlobalGame.ReplayManager.LevelID <> GameParams.Level.Info.LevelID then
      ShowMessage('Warning: This replay appears to be from a different level. SuperLemmix' + #13 +
                  'will attempt to play the replay anyway.');
  end;
end;

end.

