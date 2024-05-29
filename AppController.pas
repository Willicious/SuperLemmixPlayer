{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  GameCommandLine,
  GR32, PngInterface,
  LemSystemMessages,
  LemTypes, LemRendering, LemLevel, LemGadgetsModel, LemGadgetsMeta,
  LemStrings,
  GameControl, LemVersion,
  GameSound,          // Initial creation
  LemNeoPieceManager, // Initial creation
  FBaseDosForm, GameBaseScreenCommon,
  CustomPopup,
  Classes, SysUtils, StrUtils, IOUtils, UMisc, Windows, Forms, Dialogs, Messages;

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
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowMenuScreen;
    procedure ShowPreviewScreen;
    procedure ShowPlayScreen;
    procedure ShowPostviewScreen;
    procedure ShowTextScreen;
    procedure ShowReplayCheckScreen;
    function Execute: Boolean;
    procedure FreeScreen;
    procedure CheckIfOpenedViaReplay;

    property LoadSuccess: Boolean read fLoadSuccess;
  end;

implementation

uses
  FMain,
  GameMenuScreen,
  GamePreviewScreen,
  GamePostviewScreen,
  GameWindow,
  GameTextScreen,
  GameReplayCheckScreen;

{ TAppController }

constructor TAppController.Create(aOwner: TComponent);
begin
  inherited;

  // Set to true as default; change to false if any failure.
  fLoadSuccess := True;

  SoundManager := TSoundManager.Create;
  SoundManager.LoadDefaultSounds;  

  GameParams := TDosGameParams.Create;
  PieceManager := TNeoPieceManager.Create;
  GameParams.CreateBasePack;

  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := TLevel.Create;
  GameParams.MainForm := TForm(aOwner);

  GameParams.NextScreen := gstMenu;

  GameParams.SoundOptions := [gsoSound, gsoMusic];

  GameParams.Load;
  GameParams.BaseLevelPack.LoadUserData;

 { Some pieces may have been loaded before the user's settings, which would result
   in the high-res graphics for them not being loaded, causing errors later. }
  PieceManager.Clear;

  if UnderWine and not GameParams.DisableWineWarnings then
    if GameParams.FullScreen then
    begin
      case RunCustomPopup(nil, 'WINE Detected',
                               'You appear to be running SuperLemmix under WINE. Fullscreen mode may not work properly.' + #13 +
                               'Do you wish to change to windowed mode instead?', 'Yes|No|Never') of
        1: GameParams.FullScreen := false;
        3: GameParams.DisableWineWarnings := true;
      end;
    end;

  GameParams.MainForm.Caption := 'SuperLemmix';
  Application.Title := GameParams.MainForm.Caption;

  GameParams.Renderer.BackgroundColor := $000000;

  case TCommandLineHandler.HandleCommandLine of
    clrContinue: ; // Don't need to do anything.
    clrHalt: fLoadSuccess := false;
    clrToPreview: GameParams.NextScreen := gstPreview;
  end;

  if not fLoadSuccess then
  begin
    IsHalting := true;
    GameParams.NextScreen := gstExit;
  end;

  GameParams.PlaybackModeActive := False;
  OpenedViaReplay := False;
  CheckIfOpenedViaReplay;

  if OpenedViaReplay then
  begin
    //GameParams.LoadLevelByID(StrToInt64(LoadedReplayID));
    GameParams.FindLevelByID(LoadedReplayID);

    if not GameParams.MatchFound then
    begin
      GameParams.NextScreen := gstMenu;
      OpenedViaReplay := False;
      Exit;
    end;

    GameParams.LoadCurrentLevel();

    // Reload settings to align GameParams with current level
    GameParams.Save(scImportant);
    GameParams.Load;

    GameParams.NextScreen := gstPreview;
    fActiveForm.LoadReplay;
    OpenedViaReplay := False;
  end;
end;

destructor TAppController.Destroy;
begin
// No need to free absolutely everything here, since the game terminates after this procedure anyway.
// More important is making sure all relevant data is saved.

  PieceManager.Free;

  GameParams.Save(scCritical);

  GameParams.Renderer.Free;
  GameParams.Level.Free;
  GameParams.Free;

  SoundManager.Free; // Must NOT be moved before GameParams.Save!

  try
    if DirectoryExists(AppPath + SFTemp) then
      TDirectory.Delete(AppPath + SFTemp, true);
  except
    // Do nothing - this is a "if it fails it fails" situation.
  end;

  inherited;
end;

// Check if the program was activated by opening an .nxrp file
procedure TAppController.CheckIfOpenedViaReplay;
    // Find and extract the level ID within the replay file
    function GetLevelID(const nxrpFilePath: string): string;
    var
      nxrpFileContent: TStringList;
      line: string;
      idPos: Integer;
    begin
      Result := '';

      nxrpFileContent := TStringList.Create;
      try
        nxrpFileContent.LoadFromFile(nxrpFilePath);

        for line in nxrpFileContent do
        begin
          if Pos('ID', line) = 1 then
          begin
            idPos := Pos(' ', line);
            if idPos > 0 then
            begin
              Result := Trim(Copy(line, idPos + 1, Length(line)));
              Break;
            end;
          end;
        end;
      finally
        nxrpFileContent.Free;
      end;
    end;
var
  CommandLine: string;
  i: Integer;
  aReplayFile: string;
  ID: string;
begin
  CommandLine := GetCommandLine;
  if Pos('.nxrp', CommandLine) > 0 then
  begin
    for i := 1 to ParamCount do
    begin
      aReplayFile := ParamStr(i);
      if LowerCase(ExtractFileExt(aReplayFile)) = '.nxrp' then
      begin
        ID := GetLevelID(aReplayFile);

        if ID <> '' then
        begin
          LoadedReplayID := ID;
          LoadedReplayFile := aReplayFile;
          OpenedViaReplay := True;
        end else
          ShowMessage('Level ID not found');
        Break;
      end;
    end;
  end;
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

  // Save the data between screens. This way it's more up to date in case game crashes
  GameParams.Save(TGameParamsSaveCriticality.scNone);

  // This might be so that after the text screen, the correct screen out of gstPlay or gstPostview is shown
  NewScreen := GameParams.NextScreen;
  GameParams.NextScreen := GameParams.NextScreen2;
  GameParams.NextScreen2 := gstUnknown;

  case NewScreen of
    gstMenu      : ShowMenuScreen;
    gstPreview   : ShowPreviewScreen;
    gstPlay      : ShowPlayScreen;
    gstPostview  : ShowPostviewScreen;
    gstText      : ShowTextScreen;
    gstReplayTest: ShowReplayCheckScreen;
    else Result := false;
  end;
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

procedure TAppController.ShowTextScreen; // BookmarkPlayback - this needs to be completely refactored for Playback Mode
var
  IsPreview: Boolean;
begin
// Always called between gstPreview/gstGame, and between gstGame/gstPostview (if successful).
// However, if there's no text to show, it does nothing, and proceeds directly to the next screen.
  IsPreview := not (GameParams.NextScreen = gstPostview);

  if (IsPreview and (GameParams.Level.PreText.Count = 0))
  or ((not IsPreview) and (GameParams.Level.PostText.Count = 0))
  or (IsPreview and GameParams.ShownText)
  or (GameParams.PlaybackModeActive and GameParams.AutoSkipPreAndPostview) then
  begin
    if IsPreview then
      ShowPlayScreen
    else
      ShowPostviewScreen;
  end else begin
    fActiveForm := TGameTextScreen.Create(nil);
    fActiveForm.ShowScreen;
  end;
end;

procedure TAppController.ShowPostviewScreen;
begin
  fActiveForm := TGamePostviewScreen.Create(nil);
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
