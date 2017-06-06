{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  LemSystemMessages,
  LemTypes, LemRendering, LemLevel,
  TalisData, LemStrings,
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
    DoneBringToFront: Boolean; // We don't want to steal focus all the time. This is just to fix the
                               // bug where it doesn't initially come to front.
    //function CheckCompatible(var Target: String): TNxCompatibility;
    procedure BringToFront;
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

(*
function TAppController.CheckCompatible(var Target: String): TNxCompatibility;
var
  SL: TStringList;
  TS: TMemoryStream;
  Format, Core: Integer;

  function TestFor148Compatible: Boolean;
  var
    TempStream: TMemoryStream;
  begin
    TempStream := CreateDataStream('levels.nxmi', ldtText); // ldtText only checks the NXP, nothing else
    Result := (TempStream <> nil);
    TempStream.Free;
  end;
begin
  SL := TStringList.Create;

  try
    TS := CreateDataStream('version.txt', ldtText);
    SL.LoadFromStream(TS);

    if SL.Values['format'] = '' then  // Backwards compatibility
    begin
      if not TestFor148Compatible then
      begin
        Result := nxc_WrongFormat;
        if SL[1] = '47' then
          Target := '1.47n-D'
        else
          Target := '1.43n-F';
        Exit;
      end;

      Format := 10;
      Core := 10;
    end else begin
      Format := StrToIntDef(SL.Values['format'], 0);
      Core := StrToIntDef(SL.Values['core'], 0);
    end;

    // if Format doesn't match, treat as incompatible
    if Format <> FORMAT_VERSION then
    begin
      Result := nxc_WrongFormat;
      Target := IntToStr(Format) + '.xxx.xxx';
    end else if Core < CORE_VERSION then
    begin
      Result := nxc_OldCore;
      Target := IntToStr(Format) + '.' + LeadZeroStr(Core, 3) + '.xxx';
    end else if Core > CORE_VERSION then
    begin
      Result := nxc_NewCore;
      Target := IntToStr(Format) + '.' + LeadZeroStr(Core, 3) + '.xxx';
    end else
      Result := nxc_Compatible;
  except
    Result := nxc_Error;
  end;

  SL.Free;
end;
*)

procedure TAppController.BringToFront;
var
  Input: TInput;
begin
  // This is borderline-exploit behaviour; it sends an input to this window so that it qualifies
  // as "last application to receive input", which then allows it to control which window is brought
  // to front. Reason for this is that for some reason application gets put behind all other windows
  // after selecting a file in the initial dialog box; so this code is used to bring it to front.

  ZeroMemory(@Input, SizeOf(Input));
  SendInput(1, Input, SizeOf(Input)); // don't send anyting actually to another app..
  SetForegroundWindow(Application.Handle);
  DoneBringToFront := true;
end;

constructor TAppController.Create(aOwner: TComponent);
begin
  inherited;

  // Set to true as default; change to false if any failure.
  fLoadSuccess := true;

  DoneBringToFront := false;

  SoundManager := TSoundManager.Create;
  SoundManager.LoadDefaultSounds;  

  GameParams := TDosGameParams.Create;
  PieceManager := TNeoPieceManager.Create;

  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := TLevel.Create;
  GameParams.MainForm := TForm(aOwner);

  Application.Title := GameParams.BaseLevelPack.Name;

  GameParams.NextScreen := gstMenu;

  GameParams.SoundOptions := [gsoSound, gsoMusic]; // This was to fix a glitch where an older version disabled them
                                                    // sometimes. Not sure if this still needs to be here but no harm
                                                    // in having it.

  GameParams.Load;

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
    GameParams.MainForm.ClientWidth := GameParams.WindowWidth;
    GameParams.MainForm.ClientHeight := GameParams.WindowHeight;
    GameParams.MainForm.Left := (Screen.Width - GameParams.MainForm.Width) div 2;
    GameParams.MainForm.Top := (Screen.Height - GameParams.MainForm.Height) div 2;
  end else begin
    GameParams.MainForm.Left := 0;
    GameParams.MainForm.Top := 0;
    GameParams.MainForm.BorderStyle := bsNone;
    GameParams.MainForm.WindowState := wsMaximized;

    GameParams.MainForm.ClientWidth := Screen.Width;
    GameParams.MainForm.ClientHeight := Screen.Height;
  end;

  if GameParams.fTestMode then
    GameParams.MainForm.Caption := 'NeoLemmix - Single Level'
  else
    GameParams.MainForm.Caption := GameParams.BaseLevelPack.Name;

  Application.Title := GameParams.MainForm.Caption;

  GameParams.Renderer.BackgroundColor := $000000;

  if not fLoadSuccess then
    GameParams.NextScreen := gstExit;

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
  if not DoneBringToFront then BringToFront;
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
  if not DoneBringToFront then BringToFront;
  fActiveForm.ShowScreen;
end;

end.
