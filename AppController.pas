{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  LemSystemMessages,
  LemTypes, LemRendering, LemLevel,
  LemStrings,
  GameControl, LemVersion,
  GameSound,          // initial creation
  LemNeoPieceManager, // initial creation
  FBaseDosForm, GameBaseScreen,
  CustomPopup,
  Classes, SysUtils, StrUtils, UMisc, Windows, Forms, Dialogs, Messages;

type
  {-------------------------------------------------------------------------------
    The main application screen logic is handled by this class.
    it's a kind of simple statemachine, which shows the appropriate screens.
    These screens must change the GameParams.NextScreen property, when closing.
  -------------------------------------------------------------------------------}

  // Compatibility flags. These are used by the CheckCompatible function.
  TNxCompatibility = (nxc_Compatible,
                      nxc_WrongFormat,
                      nxc_OldCore,
                      nxc_NewCore,
                      nxc_Error);

  TAppController = class(TComponent)
  private
    fLoadSuccess: Boolean;
    fActiveForm: TGameBaseScreen;
    procedure DoLevelConvert;
    procedure DoVersionInfo;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowMenuScreen;
    procedure ShowPreviewScreen;
    procedure ShowPlayScreen;
    procedure ShowPostviewScreen;
    procedure ShowTextScreen;
    procedure ShowTalismanScreen;
    procedure ShowReplayCheckScreen;
    function Execute: Boolean;
    procedure FreeScreen;

    property LoadSuccess: Boolean read fLoadSuccess; // currently unused!
  end;

implementation

uses
  FMain,
  GameMenuScreen,
  GamePreviewScreen,
  GamePostviewScreen,
  GameWindow,
  GameTextScreen,
  GameTalismanScreen,
  GameReplayCheckScreen;

{ TAppController }

constructor TAppController.Create(aOwner: TComponent);
var
  IsTestMode: Boolean;
begin
  inherited;

  // Set to true as default; change to false if any failure.
  fLoadSuccess := true;

  SoundManager := TSoundManager.Create;
  SoundManager.LoadDefaultSounds;  

  GameParams := TDosGameParams.Create;
  PieceManager := TNeoPieceManager.Create;

  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := TLevel.Create;
  GameParams.MainForm := TForm(aOwner);

  GameParams.NextScreen := gstMenu;

  GameParams.SoundOptions := [gsoSound, gsoMusic]; // This was to fix a glitch where an older version disabled them
                                                    // sometimes. Not sure if this still needs to be here but no harm
                                                    // in having it.

  GameParams.Load;

  IsTestMode := (Lowercase(ParamStr(1)) = 'test') or (Lowercase(ParamStr(1)) = 'convert');

  if UnderWine and not GameParams.DisableWineWarnings then
    if GameParams.FullScreen then
    begin
      case RunCustomPopup(nil, 'WINE Detected',
                               'You appear to be running NeoLemmix under WINE. Fullscreen mode may not work properly.' + #13 +
                               'Do you wish to change to windowed mode instead?', 'Yes|No|Never') of
        1: GameParams.FullScreen := false;
        3: GameParams.DisableWineWarnings := true;
      end;
    end;

  // Unless Zoom level is 0 (fullscreen), resize the main window
  if not GameParams.FullScreen then
  begin
    GameParams.MainForm.BorderStyle := bsSizeable;
    GameParams.MainForm.WindowState := wsNormal;
  end else begin
    GameParams.MainForm.Left := 0;
    GameParams.MainForm.Top := 0;
    GameParams.MainForm.BorderStyle := bsNone;
    GameParams.MainForm.WindowState := wsMaximized;

    GameParams.MainForm.ClientWidth := Screen.Width;
    GameParams.MainForm.ClientHeight := Screen.Height;
  end;

  GameParams.MainForm.Caption := 'NeoLemmix';
  Application.Title := GameParams.MainForm.Caption;

  GameParams.Renderer.BackgroundColor := $000000;

  if IsTestMode then
  begin
    GameParams.BaseLevelPack.EnableSave := false;
    GameParams.BaseLevelPack.Children.Clear;
    GameParams.BaseLevelPack.Levels.Clear;
    GameParams.TestModeLevel := GameParams.BaseLevelPack.Levels.Add;
    GameParams.TestModeLevel.Filename := ParamStr(2);
    if Pos(':', GameParams.TestModeLevel.Filename) = 0 then
      GameParams.TestModeLevel.Filename := AppPath + GameParams.TestModeLevel.Filename;
    GameParams.SetLevel(GameParams.TestModeLevel);
    GameParams.NextScreen := gstPreview;
  end else
    GameParams.TestModeLevel := nil;

  if Lowercase(ParamStr(1)) = 'convert' then
  begin
    DoLevelConvert;
    fLoadSuccess := false;
  end;

  if Lowercase(ParamStr(1)) = 'version' then
  begin
    DoVersionInfo;
    fLoadSuccess := false;
  end;

  if not fLoadSuccess then
  begin
    IsHalting := true;
    GameParams.NextScreen := gstExit;
  end;
end;

procedure TAppController.DoLevelConvert;
var
  DstFile: String;
begin
  DstFile := ParamStr(3);
  if DstFile = '' then
    DstFile := ChangeFileExt(GameParams.CurrentLevel.Path, '.nxlv')
  else if Pos(':', DstFile) = 0 then
    DstFile := AppPath + DstFile;

  GameParams.LoadCurrentLevel(true);
  GameParams.Level.SaveToFile(DstFile); 
end;

procedure TAppController.DoVersionInfo;
var
  SL: TStringList;

  Formats: String;
  Exts: String;

  procedure AddFormat(aDesc, aExt: String);
  begin
    if Formats <> '' then
      Formats := Formats + '|';
    if Exts <> '' then
      Exts := Exts + ';';
    Formats := Formats + aDesc + '|' + '*.' + aExt;
    Exts := Exts + '*.' + aExt;
  end;

  procedure WriteInfo;
  var
    i: Integer;
  begin
    for i := 0 to SL.Count-1 do
      WriteLn(SL[i]);
  end;
begin
  SL := TStringList.Create;
  try
    SL.Add('formats=' + IntToStr(FORMAT_VERSION));
    SL.Add('core=' + IntToStr(CORE_VERSION));
    SL.Add('features=' + IntToStr(FEATURES_VERSION));
    SL.Add('hotfix=' + IntToStr(HOTFIX_VERSION));
    SL.Add('commit=' + COMMIT_ID);

    Formats := '';
    Exts := '';
    AddFormat('Lemmix or old NeoLemmix level (*.lvl)', 'lvl');
    AddFormat('Lemmini or SuperLemmini level (*.ini)', 'ini');
    AddFormat('Lemmins level (*.lev)', 'lev');

    SL.Add('level_formats=' + Formats);
    SL.Add('level_format_exts=' + Exts);

    WriteInfo;

    if LowerCase(ParamStr(2)) <> 'silent' then
      SL.SaveToFile(AppPath + 'NeoLemmixVersion.ini');
  finally
    SL.Free;
  end;
end;

destructor TAppController.Destroy;
begin
  // It isn't too critical to free absolutely everything here, since the
  // game will be terminating after this procedure anyway.
  // More important is making sure all relevant data is saved.

  PieceManager.Free;

  GameParams.Save;

  GameParams.Renderer.Free;
  GameParams.Level.Free;
  GameParams.Free;

  SoundManager.Free; // must NOT be moved before GameParams.Save!
  inherited;
end;

procedure TAppController.FreeScreen;
begin
  TMainForm(GameParams.MainForm).ChildForm := nil;
  fActiveForm.Free;
  fActiveForm := nil;
end;

function TAppController.Execute: Boolean;
{-------------------------------------------------------------------------------
  Main screen-loop. Every screen returns its nextscreen (if he knows) in the
  GameParams
-------------------------------------------------------------------------------}
var
  NewScreen: TGameScreenType;
begin
  Result := true;

  //while GameParams.NextScreen <> gstExit do
  //begin
    // Save the data between screens. This way it's more up to date in case
    // game crashes at any point.
    GameParams.Save;

    // I don't remember why this part is written like this.
    // Might be so that after the text screen, the right screen out of
    // gstPlay or gstPostview is shown.
    NewScreen := GameParams.NextScreen;
    GameParams.NextScreen := GameParams.NextScreen2;
    GameParams.NextScreen2 := gstUnknown;

    case NewScreen of
      gstMenu      : ShowMenuScreen;
      gstPreview   : ShowPreviewScreen;
      gstPlay      : ShowPlayScreen;
      gstPostview  : ShowPostviewScreen;
      gstText      : ShowTextScreen;
      gstTalisman  : ShowTalismanScreen;
      gstReplayTest: ShowReplayCheckScreen;
      else Result := false;
    end;

  //end;
end;

procedure TAppController.ShowMenuScreen;
begin
  fActiveForm := TGameMenuScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowPlayScreen;
begin
  fActiveForm := TGameWindow.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowTextScreen;
var
  IsPreview: Boolean;
begin
  // This function is always called between gstPreview/gstGame, and
  // between gstGame/gstPostview (if successful). However, if there's
  // no text to show, it does nothing, and proceeds directly to the
  // next screen.
  IsPreview := not (GameParams.NextScreen = gstPostview);
  if (IsPreview and (GameParams.Level.PreText.Count = 0))
  or ((not IsPreview) and (GameParams.Level.PostText.Count = 0))
  or (IsPreview and GameParams.ShownText) then
  begin
    if IsPreview then
      ShowPlayScreen
    else
      ShowPostviewScreen;
  end else begin
    fActiveForm := TGameTextScreen.Create(nil);
    TGameTextScreen(fActiveForm).PreviewText := IsPreview;
    fActiveForm.ShowScreen;
  end;
end;

procedure TAppController.ShowPostviewScreen;
begin
  fActiveForm := TGamePostviewScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowTalismanScreen;
begin
  fActiveForm := TGameTalismanScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowReplayCheckScreen;
begin
  fActiveForm := TGameReplayCheckScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowPreviewScreen;
begin
  fActiveForm := TGamePreviewScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

end.
