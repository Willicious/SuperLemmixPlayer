{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  LemTypes, LemRendering, LemLevel, LemDosStyle,
  TalisData, LemDosMainDAT, LemStrings,
  GameControl, GameSound,
  FBaseDosForm,
  Classes, SysUtils, StrUtils, UMisc, Windows, Forms, Dialogs;

type
  {-------------------------------------------------------------------------------
    The main application screen logic is handled by this class.
    it's a kind of simple statemachine, which shows the appropriate screens.
    These screens must change the GameParams.NextScreen property, when closing.
  -------------------------------------------------------------------------------}

  // Compatibility flags. These are used by the CheckCompatible function.
  TNxCompatibility = (nxc_Unknown,
                      nxc_VersionError,
                      nxc_Compatible,
                      nxc_Incompatible,
                      nxc_BC); //nxc_BC works but implements some backwards compatibility fixes

  TAppController = class(TComponent)
  private
    fLoadSuccess: Boolean;
    fGameParams: TDosGameParams; // instance
    DoneBringToFront: Boolean; // We don't want to steal focus all the time. This is just to fix the
                               // bug where it doesn't initially come to front.
    function CheckCompatible: TNxCompatibility;
    procedure BringToFront;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowMenuScreen;
    procedure ShowPreviewScreen;
    procedure ShowPlayScreen;
    procedure ShowPostviewScreen;
    procedure ShowLevelSelectScreen;
    procedure ShowTextScreen;
    procedure ShowTalismanScreen;
    procedure Execute;

    property LoadSuccess: Boolean read fLoadSuccess;
  end;

implementation

uses
  GameMenuScreen,
  GameLevelSelectScreen,
  GamePreviewScreen,
  GamePostviewScreen,
  //GameConfigScreen,
  GameWindow,
  GameTextScreen,
  GameTalismanScreen;

{ TAppController }

function TAppController.CheckCompatible: TNxCompatibility;
var
  SL: TStringList;
  TS: TMemoryStream;
  MainVer: Integer;   // The main version. EG. For V1.37n, this would be 1.
  SubVer: Integer;    // The sub-version. EG. For V1.37n, this would be 37.
  MinorVer: Integer;  // The minor version. EG: For V1.37n, this would be 1. (V1.37n-B, it would be 2, etc.)
  MaxSubVer: Integer; // Maximum sub-version.
  MaxMinorVer: Integer; // Maximum minor version.
const
  // Lowest version numbers that are compatible
  Min_MainVer = 1;    // 1.bb-c
  Min_SubVer = 47;    // a.37-c
  Min_MinorVer = 1;   // a.bb-A

  function GetTargetAsString(aMain, aSub, aMinor: Integer): String;
  begin
    Result := 'V';
    Result := Result + IntToStr(aMain);
    Result := Result + '.' + LeadZeroStr(aSub, 2) + 'n';
    if aMinor <> 1 then
      Result := Result + '-' + Char(aMinor + 64);
  end;

  function CombineTarget(aMain, aSub, aMinor: Integer): Integer;
  begin
    Result := (aMain * 10000) + (aSub * 100) + aMinor;
  end;
begin
  //Result := nxc_Unknown;
  SL := TStringList.Create;

  try
    TS := CreateDataStream('version.txt', ldtText);
    SL.LoadFromStream(TS);
    Result := nxc_Compatible; //preliminary - may change to nxc_VersionError, but if we can get version.txt from the archive,
                              //it's probably at least valid

    // Get the version info from the version.txt file. It is important to note - this lists the minimum version guaranteed to
    // be compatible with the file formats; there is no accounting for mechanics changes (as long as everything will still load)
    // and it does not specify an exact version and/or "newest version at the time the pack was made".
    // If there's a fourth line, it's a compatibility flag. This means that although the pack is marked as compatible with
    // the older versions, it's also marked as compatible with the newer ones.
    MainVer := StrToIntDef(SL[0], 0);
    SubVer := StrToIntDef(SL[1], 0);
    MinorVer := StrToIntDef(SL[2], 0);
    if SL.Count > 3 then
    begin
      MaxSubVer := StrToIntDef(SL[3], SubVer);
      MaxMinorVer := StrToIntDef(SL[4], SubVer);
    end else begin
      MaxSubVer := SubVer;
      MaxMinorVer := MinorVer;
    end;

    // If requirement is above the current version
    if CombineTarget(MainVer, SubVer, MinorVer) > CombineTarget(Cur_MainVer, Cur_SubVer, Cur_MinorVer) then
    begin
      ShowMessage('Warning: This pack may be incompatible with this version of NeoLemmix. Please use' + #13 +
                  'NeoLemmix ' + GetTargetAsString(MainVer, SubVer, MinorVer) + ' or higher.');
      Result := nxc_VersionError;
    end;

    // If requirement is below lowest supported version
    if CombineTarget(MainVer, MaxSubVer, MaxMinorVer) < CombineTarget(Cur_MainVer, Cur_SubVer, Cur_MinorVer) then
    begin
      if SubVer < 44 then
      begin
        //ShowMessage('This pack was built for an older version of NeoLemmix. Please be aware that' + #13 +
        //            'full compatibility cannot be guaranteed. Using V1.43n-F to play this pack' + #13 +
        //            'is recommended.');
        // commented out so it doesn't get annoying while testing. restore before release.
        Result := nxc_VersionError;
      end else if SubVer < 47 then
      begin
        // Not likely to ever happen. Just in case.
        ShowMessage('This pack may have compatibility issues.');
      end else begin
        // Fallback if there's no specific message. Should never happen but just in case.
        ShowMessage('Warning: This pack may be incompatible with this version of NeoLemmix. Please update to' + #13 +
                    'NeoLemmix ' + GetTargetAsString(MainVer, SubVer, MinorVer) + ' or higher.');
        Result := nxc_VersionError;
      end;
    end;

  except
    // Error would most likely result from either a. the file not being an archive in UZip.pas's format,
    // or b. a missing or invalid version.txt. In either case, this would indicate it's not a valid NXP file.
    Result := nxc_Incompatible;
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
      case CheckCompatible of
        nxc_Unknown, nxc_Incompatible: begin
                                         ShowMessage('ERROR: ' + ExtractFileName(GameFile) + ' is not a valid NeoLemmix data file.');
                                         Halt(0);
                                       end;
        //nxc_BC: OverrideDirectDrop := false;
      end;
    end else begin
      // If it's not an NXP file, treat it as a LVL file. This may not always be the case (eg. could be an NXP file with a wrong
      // extension, or a non-supported file), but aside from wrong extensions, this would mean an unsupported file anyway. The
      // only drawback of not explicitly checking, therefore, is a non-user-friendly crash message, rather than a user-friendly one.
      DoSingleLevel := true;
    end;
  end;

  DoneBringToFront := false;

  fGameParams := TDosGameParams.Create;
  fGameParams.Directory := LemmingsPath;
  fGameParams.MainDatFile := LemmingsPath + 'main.dat';
  fGameParams.Renderer := TRenderer.Create;
  fGameParams.Level := Tlevel.Create(nil);
  fGameParams.MainForm := TForm(aOwner);

  // fMainDatExtractor currently has a convenient routine for loading SYSTEM.DAT. This is a relic
  // from when SYSTEM.DAT was embedded in MAIN.DAT in very early versions of Flexi.
  fMainDatExtractor := TMainDatExtractor.Create;
  fMainDatExtractor.FileName := LemmingsPath + 'main.dat';
  fGameParams.SysDat := fMainDatExtractor.GetSysData;
  Application.Title := Trim(fGameParams.SysDat.PackName);
  fMainDatExtractor.free;

  fGameParams.SaveSystem.SetCodeSeed(fGameParams.SysDat.CodeSeed);


  fGameParams.Style := AutoCreateStyle(fGameParams.Directory, fGameParams.SysDat);
  fGameParams.NextScreen := gstMenu;

  if ParamStr(1) = 'testmode' then
  begin
    fGameParams.fTestMode := true;
    fGameParams.fTestLevelFile := ExtractFilePath(Application.ExeName) + ParamStr(2);
    fGameParams.fTestGroundFile := ExtractFilePath(Application.ExeName) + ParamStr(3);
    fGameParams.fTestVgagrFile := ExtractFilePath(Application.ExeName) + ParamStr(4);
    fGameParams.fTestVgaspecFile := ExtractFilePath(Application.ExeName) + ParamStr(5);
    if fGameParams.fTestVgaspecFile = 'none' then fGameParams.fTestVgaspecFile := '';
    fGameParams.NextScreen := gstPreview;
    fGameParams.SaveSystem.DisableSave := true;
  end;

  if DoSingleLevel then
  begin
    // Simply putting the player into testplay mode, with a workaround to use normal methods
    // to load graphic sets, is a kludgey way of enabling single-level loading. Tidier code
    // is needed.
    fGameParams.fTestMode := true;
    fGameParams.fTestLevelFile := GameFile;
    fGameParams.fTestGroundFile := '*';
    fGameParams.fTestVgagrFile := '*';
    fGameParams.fTestVgaspecFile := '*';

    GameFile := 'Single Levels';

    fGameParams.NextScreen := gstPreview;
    fGameParams.SaveSystem.DisableSave := true;
  end;

  fGameParams.SoundOptions := [gsoSound, gsoMusic]; // This was to fix a glitch where an older version disabled them
                                                    // sometimes. Not sure if this still needs to be here but no harm
                                                    // in having it.

  fGameParams.SaveSystem.LoadFile(@fGameParams);

  if fGameParams.fTestMode and (ParamStr(6) <> '') then
  begin
    // Very old editor versions didn't specify a testplay mode in the commandline, it had to be
    // configured in the game's settings. I doubt anyone still uses versions this old, but...
    // (Actually, are editor versions that old even compatible with player versions this recent?)
    if DoSingleLevel then
      fGameParams.QuickTestMode := 0
    else
      fGameParams.QuickTestMode := s2i(ParamStr(6));
  end;

  fGameParams.LoadFromIniFile;

  // Unless Zoom level is 0 (fullscreen), resize the main window
  if fGameParams.ZoomLevel <> 0 then
  begin
    if fGameParams.ZoomLevel > Screen.Width div 320 then
      fGameParams.ZoomLevel := Screen.Width div 320;
    if fGameParams.ZoomLevel > Screen.Height div 200 then
      fGameParams.ZoomLevel := Screen.Height div 200;
    fGameParams.MainForm.BorderStyle := bsToolWindow;
    fGameParams.MainForm.WindowState := wsNormal;
    fGameParams.MainForm.ClientWidth := 320 * fGameParams.ZoomLevel;
    fGameParams.MainForm.ClientHeight := 200 * fGameParams.ZoomLevel;
    fGameParams.MainForm.Left := (Screen.Width - fGameParams.MainForm.Width) div 2;
    fGameParams.MainForm.Top := (Screen.Height - fGameParams.MainForm.Height) div 2;
  end;

  if fGameParams.fTestMode then
    fGameParams.MainForm.Caption := 'NeoLemmix - Single Level'
  else
    fGameParams.MainForm.Caption := Trim(fGameParams.SysDat.PackName);

  Application.Title := fGameParams.MainForm.Caption;

  // Background color is not supported as a user option anymore. I intend to support it in the
  // future as a graphic set option. So let's just make it inaccessible for now rather than fully
  // removing it.
  fGameParams.Renderer.BackgroundColor := $000000;

  fGameParams.Style.LevelSystem.SetSaveSystem(@fGameParams.SaveSystem);

  if fGameParams.Style.LevelSystem is TBaseDosLevelSystem then  // which it should always be
  begin
    TBaseDosLevelSystem(fGameParams.Style.LevelSystem).LookForLVL := fGameParams.LookForLVLFiles;
    TBaseDosLevelSystem(fGameParams.Style.LevelSystem).fTestMode := fGameParams.fTestMode;
    TBaseDosLevelSystem(fGameParams.Style.LevelSystem).fTestLevel := fGameParams.fTestLevelFile;
    TBaseDosLevelSystem(fGameParams.Style.LevelSystem).SysDat := fGameParams.SysDat;
    TDosFlexiLevelSystem(fGameParams.Style.LevelSystem).SysDat := fGameParams.SysDat;
    TDosFlexiMusicSystem(fGameParams.Style.MusicSystem).MusicCount := fGameParams.SysDat.TrackCount;
    TBaseDosLevelSystem(fGameParams.Style.LevelSystem).fDefaultSectionCount := TBaseDosLevelSystem(fGameParams.Style.LevelSystem).GetSectionCount;
  end;

  if fGameParams.SysDat.Options and 1 = 0 then fGameParams.LookForLVLFiles := false;
  if fGameParams.SysDat.Options and 32 = 0 then
  begin
    // This is a setting that disables these options.
    fGameParams.DebugSteel := false;
    fGameParams.ChallengeMode := false;
    fGameParams.TimerMode := false;
    fGameParams.ForceSkillset := 0;
  end;

  if fGameParams.fTestMode then
  begin
    // These options should never be enabled when using testplay mode.
    // (Maybe they should when manually loading a single level? But probably not. Anyway,
    // I don't think they actually /can/ be enabled in such modes anymore due to how the
    // saving of settings works now...)
    fGameParams.ChallengeMode := false;
    fGameParams.TimerMode := false;
    fGameParams.ForceSkillset := 0;
    fGameParams.DebugSteel := false;
  end;

  fGameParams.WhichLevel := wlLastUnlocked;

  TBaseDosLevelSystem(fGameParams.Style.LevelSystem).InitSave;

  if not fLoadSuccess then
    fGameParams.NextScreen := gstExit;

end;

destructor TAppController.Destroy;
begin
  // It isn't too critical to free absolutely everything here, since the
  // game will be terminating after this procedure anyway.
  // More important is making sure all relevant data is saved.

  fGameParams.SaveSystem.SaveFile(@fGameParams);
  fGameParams.SaveToIniFile;
  fGameParams.Hotkeys.SaveFile;

  fGameParams.Renderer.Free;
  fGameParams.Level.Free;
  fGameParams.Style.Free;
  fGameParams.Free;
  inherited;
end;

procedure TAppController.Execute;
{-------------------------------------------------------------------------------
  Main screen-loop. Every screen returns its nextscreen (if he knows) in the
  GameParams
-------------------------------------------------------------------------------}
var
  NewScreen: TGameScreenType;
begin
  while fGameParams.NextScreen <> gstExit do
  begin
    // Save the data between screens. This way it's more up to date in case
    // game crashes at any point.
    fGameParams.SaveSystem.SaveFile(@fGameParams);
    fGameParams.SaveToIniFile;
    fGameParams.Hotkeys.SaveFile;

    // I don't remember why this part is written like this.
    // Might be so that after the text screen, the right screen out of
    // gstPlay or gstPostview is shown.
    NewScreen := fGameParams.NextScreen;
    fGameParams.NextScreen := fGameParams.NextScreen2;
    fGameParams.NextScreen2 := gstUnknown;

    case NewScreen of
      gstMenu      : ShowMenuScreen;
      gstPreview   : ShowPreviewScreen;
      gstPlay      : ShowPlayScreen;
      gstPostview  : ShowPostviewScreen;
      gstLevelSelect : ShowLevelSelectScreen;
      gstText      : ShowTextScreen;
      gstTalisman  : ShowTalismanScreen;
      else begin
             //fGameParams.SaveSystem.SaveFile(@fGameParams);
             //fGameParams.SaveToIniFile;
             //fGameParams.Hotkeys.SaveFile;
             Break;
           end;
    end;
  end;
end;

procedure TAppController.ShowLevelSelectScreen;
var
  F: TGameLevelSelectScreen;
begin
  F := TGameLevelSelectScreen.Create(nil);
  try
    F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowMenuScreen;
var
  F: TGameMenuScreen;
begin
  F := TGameMenuScreen.Create(nil);
  try
    if not DoneBringToFront then BringToFront;
    F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowPlayScreen;
var
  F: TGameWindow;
begin
  F := TGameWindow.Create(nil);
  try
    F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowTextScreen;
var
  F: TGameTextScreen;
  HasTextToShow: Boolean;
begin
  // This function is always called between gstPreview/gstGame, and
  // between gstGame/gstPostview (if successful). However, if there's
  // no text to show, it does nothing, and proceeds directly to the
  // next screen.
  F := TGameTextScreen.Create(nil);
  HasTextToShow := F.HasScreenText(fGameParams);
  try
    if HasTextToShow then F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowPostviewScreen;
var
  F: TGamePostviewScreen;
begin
  F := TGamePostviewScreen.Create(nil);
  try
    F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowTalismanScreen;
var
  F: TGameTalismanScreen;
begin
  F := TGameTalismanScreen.Create(nil);
  try
    F.ShowScreen(fGameParams);
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowPreviewScreen;
var
  F: TGamePreviewScreen;
  dS, dL: Integer;
  i: Integer;
  OldSound, OldMusic: Integer;
  LevelIDArray: array of array of LongWord;
  FoundMatch: Boolean;
  TempSL: TStringList;
  TempString: String;

  function SetParamsLevel(aReplay: String; DoByID: Boolean): Boolean;
  var
    TempStream: TMemoryStream;
    b: Byte;
    lw: LongWord;
    IsReallyOld: Boolean;

    procedure SetNewReplay;
    var
      SL: TStringList;
      S: String;
      i: Integer;
      n: LongWord;
    begin
      SL := TStringList.Create;
      try
        TempStream.Position := 0;
        SL.LoadFromStream(TempStream);
        for i := 0 to SL.Count-1 do
        begin
          S := Uppercase(Trim(SL[i]));
          if LeftStr(S, 2) <> 'ID' then Continue;

          S := 'x' + MidStr(S, 4, 8);
          n := StrToInt(S);

          //if Cont then
          //  Cont := MessageDlg(S, mtCustom, [mbYes, mbNo], 0) = 6;

          dS := fGameParams.Info.dSection;
          dL := fGameParams.Info.dLevel;
          // attempt to use levelID to match
          while dS < Length(LevelIDArray) do
          begin
            while dL < Length(LevelIDArray[dS]) do
            begin
              if LevelIDArray[dS][dL] = n then
              begin
                fGameParams.Info.dSection := dS;
                fGameParams.Info.dLevel := dL;
                Result := true;
                Exit;
              end;
              Inc(dL);
            end;
            dL := 0;
            Inc(dS);
          end;

        end;
      finally
        SL.Free;
      end;
    end;
  begin
    TempStream := TMemoryStream.Create;
    try
      fGameParams.WhichLevel := wlSame;
      TempStream.LoadFromFile(aReplay);

      Result := false;

      TempStream.Position := 3;
      TempStream.Read(b, 1);
      if (b = 104) or (b = 105) then
        IsReallyOld := false
      else if b = 103 then
        IsReallyOld := true
      else begin
        SetNewReplay;
        Exit;
      end;

      if DoByID then
      begin
        if (b = 105) then
        begin
          TempStream.Position := 30;
          TempStream.Read(lw, 4);

          dS := fGameParams.Info.dSection;
          dL := fGameParams.Info.dLevel;
          // attempt to use levelID to match
          while dS < Length(LevelIDArray) do
          begin
            while dL < Length(LevelIDArray[dS]) do
            begin
              if LevelIDArray[dS][dL] = lw then
              begin
                fGameParams.Info.dSection := dS;
                fGameParams.Info.dLevel := dL;
                Result := true;
                Exit;
              end;
              Inc(dL);
            end;
            dL := 0;
            Inc(dS);
          end;
        end;

      end else begin

        if IsReallyOld then
          TempStream.Position := 24 // from V1.27n-B or earlier
        else
          TempStream.Position := 21;
        TempStream.Read(b, 1);
        fGameParams.Info.dSection := b;

        if IsReallyOld then
          TempStream.Position := 28
        else
          TempStream.Position := 22;
        TempStream.Read(b, 1);
        fGameParams.Info.dLevel := b;

        Result := (fGameParams.Info.dSection < Length(LevelIDArray)) and (fGameParams.Info.dLevel < Length(LevelIDArray[fGameParams.Info.dSection]));

      end;
    finally
      TempStream.Free;
    end;
  end;

  procedure ProduceReplayCheckResults;
  var
    OutSL: TStringList;
    S: String;
    C: Integer;

    procedure AddByValue(aTarget: string; var Count: Integer);
    var
      i: Integer;
    begin
      Count := 0;
      for i := 0 to TempSL.Count-1 do
        if Pos(aTarget, TempSL[i]) <> 0 then
        begin
          Count := Count + 1;
          OutSL.Add(TempSL[i]);
        end;
    end;

    procedure AddSep;
    begin
      OutSL.Add('');
      OutSL.Add('------------');
      OutSL.Add('');
    end;

  begin
    OutSL := TStringList.Create;
    AddByValue('FAILED', C);
    S := 'Failed: ' + IntToStr(C);
    AddSep;
    AddByValue('UNDETERMINED', C);
    S := S + #13 + 'Undetermined: ' + IntToStr(C);
    AddSep;
    AddByValue('PASSED', C);
    S := S + #13 + 'Passed: ' + IntToStr(C);
    AddSep;
    AddByValue('ERROR', C);
    S := S + #13 + 'Error Occurred: ' + IntToStr(C);
    AddSep;
    AddByValue('CANNOT FIND LEVEL', C);
    S := S + #13 + 'Couldn''t Find Level: ' + IntToStr(C);
    OutSL.SaveToFile(ChangeFileExt(GameFile, '') + ' Replay Results.txt');
    OutSL.Free;

    S := S + #13 + #13 + 'Please check "' + ExtractFileName(ChangeFileExt(GameFile, '')) + ' Replay Results.txt" for full details.';

    ShowMessage(S);
  end;

  function GetRankAndNumber: String;
  begin
    Result := ' <<' + Trim(fGameParams.SysDat.RankNames[fGameParams.Info.dSection]) + ' ' + LeadZeroStr(fGameParams.Info.dLevel+1, 2) + '>>';
  end;

begin
  // This one has a lot of code. Some code run on the preview screen is critical to preparing
  // for in-game, so in testplay mode with preview screen disabled, it still needs to create a
  // TGamePreviewScreen and run it invisibly. Because this code relates to rendering the level,
  // it also needs to be invoked when dumping images; this is both why the image dumping is slow,
  // and why some of its code is here. This seriously needs to be improved.
  F := TGamePreviewScreen.Create(nil);
  try
    if (fGameParams.fTestMode and (fGameParams.QuickTestMode <> 0)) then
    begin
      // Test play, with preview screen disabled. Do the screen prep routines without actually showing
      // anything, then move directly to play screen.
      F.PrepareGameParams(fGameParams);
      F.BuildScreenInvis;
      fGameParams.NextScreen := gstPlay;
    end else
    if fGameParams.DumpMode then
    begin
      // This is for IMAGE DUMPING (level dumping does not require preview screen to be invoked).
      // Invisibly creates the preview screen, renders the level, saves image, closes, continues.
      // Very kludgey and should be replaced, but for now it works.
      for dS := 0 to TBaseDosLevelSystem(fGameParams.Style.LevelSystem).fDefaultSectionCount - 1 do
        for dL := 0 to TBaseDosLevelSystem(fGameParams.Style.LevelSystem).GetLevelCount(dS) - 1 do
        begin
          fGameParams.WhichLevel := wlSame;
          fGameParams.Info.dSection := dS;
          fGameParams.Info.dLevel := dL;
          F.PrepareGameParams(fGameParams);
          F.BuildScreenInvis;
        end;
      fGameParams.Info.dSection := 0;
      fGameParams.WhichLevel := wlLastUnlocked;
      fGameParams.NextScreen := gstMenu;
      fGameParams.DumpMode := false;
    end else if fGameParams.ReplayCheckIndex <> -2 then
    begin
       TempSL := TStringList.Create;
       OldSound := SoundVolume;
       OldMusic := MusicVolume;
       SoundVolume := 0;
       MusicVolume := 0;
       SetLength(LevelIDArray, TBaseDosLevelSystem(fGameParams.Style.LevelSystem).GetSectionCount);
       for dS := 0 to Length(LevelIDArray)-1 do
       begin
         SetLength(LevelIDArray[dS], TBaseDosLevelSystem(fGameParams.Style.LevelSystem).GetLevelCount(dS));
         for dL := 0 to Length(LevelIDArray[dS])-1 do
         begin
           TBaseDosLevelSystem(fGameParams.Style.LevelSystem).ResetOddtableHistory;
           fGameParams.Style.LevelSystem.LoadSingleLevel(fGameParams.Info.dPack, dS, dL, fGameParams.Level);
           LevelIDArray[dS][dL] := fGameParams.Level.Info.LevelID;
         end;
       end;
       for i := 0 to fGameParams.ReplayResultList.Count-1 do
       begin
         FoundMatch := false;
         fGameParams.ReplayCheckIndex := i;
         fGameParams.Info.dSection := 0;
         fGameParams.Info.dLevel := 0;
         while SetParamsLevel(fGameParams.ReplayResultList[i], true) do
         begin
           FoundMatch := true;
           TempString := fGameParams.ReplayResultList[i];
           try
             F.PrepareGameParams(fGameParams);
             F.BuildScreenInvis;
             ShowPlayScreen;
           except
             fGameParams.ReplayResultList[i] := ExtractFileName(fGameParams.ReplayResultList[i]) + ': ERROR';
           end;
           TempSL.Add(fGameParams.ReplayResultList[i] + GetRankAndNumber + ' (By Level ID)');
           fGameParams.ReplayResultList[i] := TempString;
           fGameParams.Info.dLevel := fGameParams.Info.dLevel + 1;
         end;

         if not FoundMatch then
         begin
           // no need to preserve the ReplayResultList entry as this will be the last time the replay
           // in question is referenced here
           if SetParamsLevel(fGameParams.ReplayResultList[i], false) then
           try
             F.PrepareGameParams(fGameParams);
             F.BuildScreenInvis;
             ShowPlayScreen;
           except
             fGameParams.ReplayResultList[i] := ExtractFileName(fGameParams.ReplayResultList[i]) + ': ERROR';
           end else
             fGameParams.ReplayResultList[i] := ExtractFileName(fGameParams.ReplayResultList[i]) + ': CANNOT FIND LEVEL';

           TempSL.Add(fGameParams.ReplayResultList[i] + GetRankAndNumber + ' (By Position)');
         end;
       end;
       fGameParams.ReplayCheckIndex := -2;
       fGameParams.NextScreen := gstMenu;
       fGameParams.Info.dSection := 0;
       fGameParams.Info.dLevel := 0;
       ProduceReplayCheckResults;
       SoundVolume := OldSound;
       MusicVolume := OldMusic;
       TempSL.Free;
    end else begin
      // In the case of loading a single level file, menu screen will never be displayed.
      // Therefore, bringing to front must be done here.
      if not DoneBringToFront then BringToFront;
      F.ShowScreen(fGameParams);
    end;
  finally
    F.Free;
  end;
end;

end.
