{$include lem_directives.inc}
unit AppController;

interface

uses
  GameCommandLine,
  GR32, PngInterface,
  LemSystemMessages,
  LemTypes, LemRendering, LemNeoLevelPack, LemLevel, LemGadgetsModel, LemGadgetsMeta,
  LemStrings,
  GameControl, LemVersion,
  GameSound,          // Initial creation
  LemNeoPieceManager, // Initial creation
  FBaseDosForm, GameBaseScreenCommon,
  CustomPopup,
  Classes, SysUtils, StrUtils, IOUtils, UMisc, Windows, Forms, Dialogs, Messages,
  SharedGlobals;

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
    procedure HandleOpenedViaReplay;

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

  // Set to True as default; change to False if any failure.
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

  GameParams.MainForm.Caption := SProgramName;
  Application.Title := GameParams.MainForm.Caption;

  GameParams.Renderer.BackgroundColor := $000000;

  case TCommandLineHandler.HandleCommandLine of
    clrContinue: ; // Don't need to do anything.
    clrHalt: fLoadSuccess := False;
    clrToPreview: GameParams.NextScreen := gstPreview;
  end;

  if not fLoadSuccess then
  begin
    IsHalting := True;
    GameParams.NextScreen := gstExit;
  end;

  GameParams.PlaybackModeActive := False;

  GameParams.OpenedViaReplay := False;
  CheckIfOpenedViaReplay;

  if GameParams.OpenedViaReplay then
    HandleOpenedViaReplay;
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
      TDirectory.Delete(AppPath + SFTemp, True);
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

// Check if the program was activated by opening an .nxrp file
procedure TAppController.CheckIfOpenedViaReplay;
  function GetLevelID(const nxrpFilePath: string): Int64;
  var
    S: TMemoryStream;
    SL: TStringList;
    i: Integer;
    Line: string;
  begin
    Result := 0;
    S := TMemoryStream.Create;
    SL := TStringList.Create;
    try
      S.LoadFromFile(nxrpFilePath);
      S.Position := 0;
      SL.LoadFromStream(S);

      for i := 0 to SL.Count - 1 do
      begin
        Line := Trim(SL[i]);
        if UpperCase(LeftStr(Line, 2)) = 'ID' then
        begin
          GameParams.LoadedReplayIDString := 'x' + RightStr(Line, 16);
          Result := StrToInt64Def(GameParams.LoadedReplayIDString, 0);
          Exit;
        end;
      end;
    finally
      SL.Free;
      S.Free;
    end;
  end;
var
  i: Integer;
  aReplayFile: string;
begin
  for i := 1 to ParamCount do
  begin
    aReplayFile := ParamStr(i);
    if LowerCase(ExtractFileExt(aReplayFile)) = '.nxrp' then
    begin
      GameParams.LoadedReplayID := GetLevelID(aReplayFile);
      GameParams.LoadedReplayFile := aReplayFile;
      GameParams.OpenedViaReplay := GameParams.LoadedReplayID <> 0;
      Break;
    end;
  end;
end;

procedure TAppController.HandleOpenedViaReplay;
var
  MatchedLevel: TNeoLevelEntry;
begin
  MatchedLevel := GameParams.FindLevelByID(GameParams.LoadedReplayID);

  if MatchedLevel = nil then
  begin
    ShowMessage('No match could be found for ID: ' + GameParams.LoadedReplayIDString);
    GameParams.NextScreen := gstMenu;
    GameParams.OpenedViaReplay := False;
    Exit;
  end;

  // Set the level in GameParams
  GameParams.SetLevel(MatchedLevel);
  GameParams.LoadCurrentLevel;

  // Reload settings to align GameParams with selected level
  GameParams.Save(scImportant);
  GameParams.Load;

  GameParams.NextScreen := gstPreview;
  fActiveForm.LoadReplay;
end;

function TAppController.Execute: Boolean;
{-------------------------------------------------------------------------------
  Main screen-loop.
-------------------------------------------------------------------------------}
var
  NewScreen: TGameScreenType;
begin
  Result := True;

  // Save data between screens so it's as up-to-date as possible
  GameParams.Save(TGameParamsSaveCriticality.scNone);

  // Every screen returns its NextScreen (if known)
  NewScreen := GameParams.NextScreen;

  case NewScreen of
    gstMenu      : ShowMenuScreen;
    gstPreview   : ShowPreviewScreen;
    gstPlay      : ShowPlayScreen;
    gstPostview  : ShowPostviewScreen;
    gstText      : ShowTextScreen;
    gstReplayTest: ShowReplayCheckScreen;
    else Result := False;
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

procedure TAppController.ShowTextScreen;
begin
  fActiveForm := TGameTextScreen.Create(nil);
  fActiveForm.ShowScreen;
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
