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

    property LoadSuccess: Boolean read fLoadSuccess; // Bookmark - currently unused! - remove?
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
  fLoadSuccess := true;

  SoundManager := TSoundManager.Create;
  SoundManager.LoadDefaultSounds;  

  GameParams := TDosGameParams.Create;
  PieceManager := TNeoPieceManager.Create;
  GameParams.CreateBasePack;

  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := TLevel.Create;
  GameParams.MainForm := TForm(aOwner);

  GameParams.NextScreen := gstMenu;

  // Bookmark - This was to fix a glitch where an older version disabled them sometimes.
  // Not sure if this still needs to be here - remove?
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

  // Bookmark - should this be commented back in???
  //while GameParams.NextScreen <> gstExit do
  //begin
    // Save the data between screens. This way it's more up to date in case game crashes
    GameParams.Save(TGameParamsSaveCriticality.scNone); // Compiler throws a fit without the type specifier here

    // I don't remember why this part is written like this.
    // Might be so that after the text screen, the right screen out of gstPlay or gstPostview is shown.
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
// Always called between gstPreview/gstGame, and between gstGame/gstPostview (if successful).
// However, if there's no text to show, it does nothing, and proceeds directly to the next screen.
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
