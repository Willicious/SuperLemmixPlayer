{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  LemSystemMessages,
  LemTypes, LemRendering, LemLevel, LemDosStyle,
  TalisData, LemDosMainDAT, LemStrings, LemNeoParserOld,
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
    function CheckCompatible(var Target: String): TNxCompatibility;
    procedure BringToFront;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowMenuScreen;
    procedure ShowPreviewScreen;
    procedure ShowPlayScreen;
    procedure ShowPostviewScreen;
    procedure ShowLevelSelectScreen;
    procedure ShowLevelCodeScreen;
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
  GameLevelSelectScreen,
  GameLevelCodeScreen,
  GamePreviewScreen,
  GamePostviewScreen,
  GameWindow,
  GameTextScreen,
  GameTalismanScreen,
  GameReplayCheckScreen;

{ TAppController }

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
var
  OpenDlg: TOpenDialog;
  DoSingleLevel: Boolean;
  fMainDatExtractor : TMainDatExtractor;
  Target: String;
  ShowWarning: Boolean;

  function CheckIfWarningNeeded: Boolean;
  var
    SL: TStringList;
  begin
    Result := true;
    SL := TStringList.Create;
    try
      SL.LoadFromFile(ChangeFileExt(GameFile, '.nxsv'));
      if SL.Count < 2 then Exit;
      if Lowercase(Trim(SL[0])) <> '[version]' then Exit;
      if (CurrentVersionID div 1000000) <> (StrToInt64Def(Trim(SL[1]), 0) div 1000000) then Exit;
      Result := false;
    finally
      SL.Free;
    end;
  end;
begin
  inherited;

  // Set to true as default; change to false if any failure.
  fLoadSuccess := true;

  // Unless command line starts with "testmode" (sent by editor when launching test mode),
  // we need to get which file to run. The command line may have already specified it in which
  // case we can just get it from that; otherwise, we need to promt the user to select an
  // NXP or LVL file.
  DoSingleLevel := false;
  if ParamStr(1) <> 'testmode' then
  begin
    if FileExists(ParamStr(1)) then
      GameFile := ParamStr(1)
    else begin
      OpenDlg := TOpenDialog.Create(self);
      OpenDlg.Options := [ofHideReadOnly, ofFileMustExist];
      OpenDlg.Title := 'Select Level Pack';
      OpenDlg.Filter := 'NeoLemmix Levels or Packs (*.nxp, *.lvl, *.nxlv)|*.nxp;*.lvl;*.nxlv|NeoLemmix Level Pack (*.nxp)|*.nxp|NeoLemmix Level (*.lvl, *.nxlv)|*.lvl;*.nxlv';
      OpenDlg.InitialDir := ExtractFilePath(ParamStr(0));
      if not OpenDlg.Execute then
        fLoadSuccess := false;
      GameFile := OpenDlg.FileName;
      OpenDlg.Free;
    end;

    if LowerCase(ExtractFileExt(GameFile)) = '.nxp' then
    begin
      DoSingleLevel := false;
      Target := '';
      IsHalting := false;
      case CheckCompatible(Target) of
        nxc_WrongFormat: begin
                           ShowMessage('This pack''s data is in the wrong format for this version of NeoLemmix.' + #13 +
                                       'Please use NeoLemmix V' + Target + ' to play this pack.');
                           IsHalting := true;
                           Application.Terminate();
                         end;
        nxc_OldCore: begin
                       if FileExists(ChangeFileExt(GameFile, '.nxsv')) then
                         ShowWarning := CheckIfWarningNeeded
                       else
                         ShowWarning := true;

                       if ShowWarning then
                         ShowMessage('This pack is designed for older versions of NeoLemmix. It should be compatible,' + #13 +
                                     'but please be aware that it may not have been tested against this version. For' + #13 +
                                     'optimal results, use NeoLemmix V' + Target + ' to play this pack.');
                       // don't need to exit the application
                     end;
        nxc_NewCore: begin
                       ShowMessage('This pack is designed for newer versions of NeoLemmix. Please upgrade to' + #13 +
                                   'NeoLemmix V' + Target + ' to play this pack.');
                       // only exit if file formats changed, i.e there is a change to FORMAT_VERSION
                       if LeftStr(Target, 3) <> LeftStr(CurrentVersionString, 3) then
                       begin
                         IsHalting := true;
                         Application.Terminate();
                       end;
                     end;
        nxc_Error: begin
                     ShowMessage('The NXP file could not be loaded. It may be corrupt or an invalid file.');
                     IsHalting := true;
                     Application.Terminate();
                   end;
      end;
    end else begin
      // If it's not an NXP file, treat it as a LVL file. This may not always be the case (eg. could be an NXP file with a wrong
      // extension, or a non-supported file), but aside from wrong extensions, this would mean an unsupported file anyway. The
      // only drawback of not explicitly checking, therefore, is a non-user-friendly crash message, rather than a user-friendly one.
      DoSingleLevel := true;
    end;
  end;

  DoneBringToFront := false;

  SoundManager := TSoundManager.Create;
  SoundManager.LoadDefaultSounds;  

  GameParams := TDosGameParams.Create;
  PieceManager := TNeoPieceManager.Create;

  GameParams.Directory := LemmingsPath;
  GameParams.MainDatFile := LemmingsPath + 'main.dat';
  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := Tlevel.Create;
  GameParams.MainForm := TForm(aOwner);

  // fMainDatExtractor currently has a convenient routine for loading SYSTEM.DAT. This is a relic
  // from when SYSTEM.DAT was embedded in MAIN.DAT in very early versions of Flexi.
  fMainDatExtractor := TMainDatExtractor.Create;
  fMainDatExtractor.FileName := LemmingsPath + 'main.dat';
  GameParams.SysDat := fMainDatExtractor.GetSysData;
  Application.Title := Trim(GameParams.SysDat.PackName);
  fMainDatExtractor.free;

  GameParams.Style := AutoCreateStyle(GameParams.Directory, GameParams.SysDat);
  GameParams.NextScreen := gstMenu;

  if ParamStr(1) = 'testmode' then
  begin
    GameParams.fTestMode := true;
    GameParams.fTestLevelFile := ExtractFilePath(Application.ExeName) + ParamStr(2);
    GameParams.fTestGroundFile := ExtractFilePath(Application.ExeName) + ParamStr(3);
    GameParams.fTestVgagrFile := ExtractFilePath(Application.ExeName) + ParamStr(4);
    GameParams.fTestVgaspecFile := ExtractFilePath(Application.ExeName) + ParamStr(5);
    if GameParams.fTestVgaspecFile = 'none' then GameParams.fTestVgaspecFile := '';
    GameParams.NextScreen := gstPreview;
    GameParams.SaveSystem.DisableSave := true;
  end;

  if DoSingleLevel then
  begin
    // Simply putting the player into testplay mode, with a workaround to use normal methods
    // to load graphic sets, is a kludgey way of enabling single-level loading. Tidier code
    // is needed.
    GameParams.fTestMode := true;
    GameParams.fTestLevelFile := GameFile;
    GameParams.fTestGroundFile := '*';
    GameParams.fTestVgagrFile := '*';
    GameParams.fTestVgaspecFile := '*';

    GameFile := 'Single Levels';

    GameParams.NextScreen := gstPreview;
    GameParams.SaveSystem.DisableSave := true;
  end;

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
    GameParams.MainForm.BorderStyle := bsNone;
    GameParams.MainForm.WindowState := wsMaximized;

    if UnderWine then
    begin
      GameParams.MainForm.Left := 0;
      GameParams.MainForm.Top := 0;
    end;

    GameParams.MainForm.ClientWidth := Screen.Width;
    GameParams.MainForm.ClientHeight := Screen.Height;
  end;

  if GameParams.fTestMode then
    GameParams.MainForm.Caption := 'NeoLemmix - Single Level'
  else
    GameParams.MainForm.Caption := Trim(GameParams.SysDat.PackName);

  Application.Title := GameParams.MainForm.Caption;

  // Background color is not supported as a user option anymore. I intend to support it in the
  // future as a graphic set option. So let's just make it inaccessible for now rather than fully
  // removing it.
  GameParams.Renderer.BackgroundColor := $000000;

  GameParams.Style.LevelSystem.SetSaveSystem(@GameParams.SaveSystem);

  if GameParams.Style.LevelSystem is TBaseDosLevelSystem then  // which it should always be
  begin
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fTestMode := GameParams.fTestMode;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fTestLevel := GameParams.fTestLevelFile;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).SysDat := GameParams.SysDat;
    TDosFlexiLevelSystem(GameParams.Style.LevelSystem).SysDat := GameParams.SysDat;
    TDosFlexiMusicSystem(GameParams.Style.MusicSystem).MusicCount := GameParams.SysDat.TrackCount;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fDefaultSectionCount := TBaseDosLevelSystem(GameParams.Style.LevelSystem).GetSectionCount;
  end;

  GameParams.WhichLevel := wlLastUnlocked;

  if not fLoadSuccess then
    GameParams.NextScreen := gstExit;

  if ParamStr(2) = 'replaytest' then
  begin
    GameParams.ReplayCheckPath := ParamStr(3);
    GameParams.NextScreen := gstReplayTest;
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
  GameParams.Style.Free;
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
      gstLevelSelect : ShowLevelSelectScreen;
      gstLevelCode: ShowLevelCodeScreen;
      gstText      : ShowTextScreen;
      gstTalisman  : ShowTalismanScreen;
      gstReplayTest: ShowReplayCheckScreen;
      else Result := false;
    end;

  //end;
end;

procedure TAppController.ShowLevelSelectScreen;
begin
  fActiveForm := TGameLevelSelectScreen.Create(nil);
  fActiveForm.ShowScreen;
end;

procedure TAppController.ShowLevelCodeScreen;
begin
  fActiveForm := TGameLevelCodeScreen.Create(nil);
  fActiveForm.ShowScreen;
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
  HasTextToShow: Boolean;
begin
  // This function is always called between gstPreview/gstGame, and
  // between gstGame/gstPostview (if successful). However, if there's
  // no text to show, it does nothing, and proceeds directly to the
  // next screen.
  fActiveForm := TGameTextScreen.Create(nil);
  HasTextToShow := TGameTextScreen(fActiveForm).HasScreenText;
  if HasTextToShow then
    fActiveForm.ShowScreen
  else
    SendMessage(MainFormHandle, LM_NEXT, 0, 0);
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
