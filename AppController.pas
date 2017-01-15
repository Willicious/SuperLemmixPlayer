{$include lem_directives.inc}
unit AppController;

interface

uses
  SharedGlobals,
  LemTypes, LemRendering, LemLevel, LemDosStyle,
  TalisData, LemDosMainDAT, LemStrings, LemNeoParserOld,
  GameControl, GameSound, LemVersion,
  LemNeoPieceManager, // to initially create it
  FBaseDosForm,
  Classes, SysUtils, StrUtils, UMisc, Windows, Forms, Dialogs;

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
    procedure Execute;

    property LoadSuccess: Boolean read fLoadSuccess; // currently unused!
  end;

implementation

uses
  GameMenuScreen,
  GameLevelSelectScreen,
  GameLevelCodeScreen,
  GamePreviewScreen,
  GamePostviewScreen,
  GameWindow,
  GameTextScreen,
  GameTalismanScreen;

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
  Result := nxc_Error;
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

  GameParams.SaveSystem.SetCodeSeed(GameParams.SysDat.CodeSeed);


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

  if GameParams.fTestMode and (ParamStr(6) <> '') then
  begin
    // Very old editor versions didn't specify a testplay mode in the commandline, it had to be
    // configured in the game's settings. I doubt anyone still uses versions this old, but...
    // (Actually, are editor versions that old even compatible with player versions this recent?)
    if DoSingleLevel then
      GameParams.QuickTestMode := 0
    else
      GameParams.QuickTestMode := StrToInt(ParamStr(6));
  end;

  // Unless Zoom level is 0 (fullscreen), resize the main window
  if GameParams.ZoomLevel <> 0 then
  begin
    if GameParams.ZoomLevel > Screen.Width div 320 then
      GameParams.ZoomLevel := Screen.Width div 320;
    if GameParams.ZoomLevel > Screen.Height div 200 then
      GameParams.ZoomLevel := Screen.Height div 200;
    GameParams.MainForm.BorderStyle := bsToolWindow;
    GameParams.MainForm.WindowState := wsNormal;
    GameParams.MainForm.ClientWidth := 320 * GameParams.ZoomLevel;
    GameParams.MainForm.ClientHeight := 200 * GameParams.ZoomLevel;
    GameParams.MainForm.Left := (Screen.Width - GameParams.MainForm.Width) div 2;
    GameParams.MainForm.Top := (Screen.Height - GameParams.MainForm.Height) div 2;
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
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).LookForLVL := GameParams.LookForLVLFiles;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fTestMode := GameParams.fTestMode;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fTestLevel := GameParams.fTestLevelFile;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).SysDat := GameParams.SysDat;
    TDosFlexiLevelSystem(GameParams.Style.LevelSystem).SysDat := GameParams.SysDat;
    TDosFlexiMusicSystem(GameParams.Style.MusicSystem).MusicCount := GameParams.SysDat.TrackCount;
    TBaseDosLevelSystem(GameParams.Style.LevelSystem).fDefaultSectionCount := TBaseDosLevelSystem(GameParams.Style.LevelSystem).GetSectionCount;
  end;

  if GameParams.SysDat.Options and 1 = 0 then GameParams.LookForLVLFiles := false;
  if GameParams.SysDat.Options and 32 = 0 then
  begin
    // This is a setting that disables these options.
    GameParams.ChallengeMode := false;
    GameParams.TimerMode := false;
    GameParams.ForceSkillset := 0;
  end;

  if GameParams.fTestMode then
  begin
    // These options should never be enabled when using testplay mode.
    // (Maybe they should when manually loading a single level? But probably not. Anyway,
    // I don't think they actually /can/ be enabled in such modes anymore due to how the
    // saving of settings works now...)
    GameParams.ChallengeMode := false;
    GameParams.TimerMode := false;
    GameParams.ForceSkillset := 0;
  end;

  GameParams.WhichLevel := wlLastUnlocked;

  if not fLoadSuccess then
    GameParams.NextScreen := gstExit;

end;

destructor TAppController.Destroy;
begin
  // It isn't too critical to free absolutely everything here, since the
  // game will be terminating after this procedure anyway.
  // More important is making sure all relevant data is saved.

  GameParams.Save;

  GameParams.Renderer.Free;
  GameParams.Level.Free;
  GameParams.Style.Free;
  GameParams.Free;
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
  while GameParams.NextScreen <> gstExit do
  begin
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
      else Break;
    end;
  end;
end;

procedure TAppController.ShowLevelSelectScreen;
var
  F: TGameLevelSelectScreen;
begin
  F := TGameLevelSelectScreen.Create(nil);
  try
    F.ShowScreen;
  finally
    F.Free;
  end;
end;

procedure TAppController.ShowLevelCodeScreen;
var
  F: TGameLevelCodeScreen;
begin
  F := TGameLevelCodeScreen.Create(nil);
  try
    F.ShowScreen;
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
    F.ShowScreen;
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
    F.ShowScreen;
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
  HasTextToShow := F.HasScreenText;
  try
    if HasTextToShow then F.ShowScreen;
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
    F.ShowScreen;
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
    F.ShowScreen;
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

          S := Trim(MidStr(S, 4, 9));
          if LeftStr(S, 1) <> 'X' then
            S := 'x' + S;
          n := StrToInt(S);

          dS := GameParams.Info.dSection;
          dL := GameParams.Info.dLevel;
          // attempt to use levelID to match
          while dS < Length(LevelIDArray) do
          begin
            while dL < Length(LevelIDArray[dS]) do
            begin
              if LevelIDArray[dS][dL] = n then
              begin
                GameParams.Info.dSection := dS;
                GameParams.Info.dLevel := dL;
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
      GameParams.WhichLevel := wlSame;
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

          dS := GameParams.Info.dSection;
          dL := GameParams.Info.dLevel;
          // attempt to use levelID to match
          while dS < Length(LevelIDArray) do
          begin
            while dL < Length(LevelIDArray[dS]) do
            begin
              if LevelIDArray[dS][dL] = lw then
              begin
                GameParams.Info.dSection := dS;
                GameParams.Info.dLevel := dL;
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
        GameParams.Info.dSection := b;

        if IsReallyOld then
          TempStream.Position := 28
        else
          TempStream.Position := 22;
        TempStream.Read(b, 1);
        GameParams.Info.dLevel := b;

        Result := (GameParams.Info.dSection < Length(LevelIDArray)) and (GameParams.Info.dLevel < Length(LevelIDArray[GameParams.Info.dSection]));

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
    Result := ' <<' + Trim(GameParams.SysDat.RankNames[GameParams.Info.dSection]) + ' ' + LeadZeroStr(GameParams.Info.dLevel+1, 2) + '>>';
  end;

  function TryLevelInfoFile: Boolean;
  var
    LS: TBaseDosLevelSystem;
    DataStream: TMemoryStream;
    Parser: TNeoLemmixParser;
    Line: TParserLine;
    R, L: Integer;
  begin
    Result := false;
    DataStream := CreateDataStream('levels.nxmi', ldtLemmings);

    LS := TBaseDosLevelSystem(GameParams.Style.LevelSystem);

    Parser := TNeoLemmixParser.Create;
    try
      Parser.LoadFromStream(DataStream);

      SetLength(LevelIDArray, LS.GetSectionCount);
      for R := 0 to LS.GetSectionCount-1 do
        SetLength(LevelIDArray[R], LS.GetLevelCount(R));

      R := -1;
      repeat
        Line := Parser.NextLine;
        if (Line.Keyword <> 'LEVEL') and (R = -1) then Continue;

        if Line.Keyword = 'LEVEL' then
        begin
          if Line.Numeric > 9999 then
          begin
            R := Line.Numeric div 1000;
            L := Line.Numeric mod 1000;
          end else begin
            R := Line.Numeric div 100;
            L := Line.Numeric mod 100;
          end;

          if (R > LS.GetSectionCount) or (L > LS.GetLevelCount(R)) then
            R := -1;
        end;

        if Line.Keyword = 'ID' then
          LevelIDArray[R][L] := StrToIntDef('x' + Line.Value, 0);

      until (Line.Keyword = '');

      Result := true;
    finally
      Parser.Free;
    end;
  end;

begin
  // This one has a lot of code. Some code run on the preview screen is critical to preparing
  // for in-game, so in testplay mode with preview screen disabled, it still needs to create a
  // TGamePreviewScreen and run it invisibly. Because this code relates to rendering the level,
  // it also needs to be invoked when dumping images; this is both why the image dumping is slow,
  // and why some of its code is here. This seriously needs to be improved.
  F := TGamePreviewScreen.Create(nil);
  try
    if (GameParams.fTestMode and (GameParams.QuickTestMode <> 0)) then
    begin
      // Test play, with preview screen disabled. Do the screen prep routines without actually showing
      // anything, then move directly to play screen.
      F.PrepareGameParams;
      F.BuildScreenInvis;
      GameParams.NextScreen := gstPlay;
    end else
    if GameParams.DumpMode then
    begin
      // This is for IMAGE DUMPING (level dumping does not require preview screen to be invoked).
      // Invisibly creates the preview screen, renders the level, saves image, closes, continues.
      // Very kludgey and should be replaced, but for now it works.
      for dS := 0 to TBaseDosLevelSystem(GameParams.Style.LevelSystem).fDefaultSectionCount - 1 do
        for dL := 0 to TBaseDosLevelSystem(GameParams.Style.LevelSystem).GetLevelCount(dS) - 1 do
        begin
          GameParams.WhichLevel := wlSame;
          GameParams.Info.dSection := dS;
          GameParams.Info.dLevel := dL;
          F.PrepareGameParams;
          F.BuildScreenInvis;
        end;
      GameParams.Info.dSection := 0;
      GameParams.WhichLevel := wlLastUnlocked;
      GameParams.NextScreen := gstMenu;
      GameParams.DumpMode := false;
    end else if GameParams.ReplayCheckIndex <> -2 then
    begin
       TempSL := TStringList.Create;
       OldSound := SoundVolume;
       OldMusic := MusicVolume;
       SoundVolume := 0;
       MusicVolume := 0;
       if not TryLevelInfoFile then
         raise Exception.Create('Couldn''t get Level IDs from info file.');
       for i := 0 to GameParams.ReplayResultList.Count-1 do
       begin
         FoundMatch := false;
         GameParams.ReplayCheckIndex := i;
         GameParams.Info.dSection := 0;
         GameParams.Info.dLevel := 0;
         while SetParamsLevel(GameParams.ReplayResultList[i], true) do
         begin
           FoundMatch := true;
           TempString := GameParams.ReplayResultList[i];
           try
             F.PrepareGameParams;
             F.BuildScreenInvis;
             ShowPlayScreen;
           except
             GameParams.ReplayResultList[i] := ExtractFileName(GameParams.ReplayResultList[i]) + ': ERROR';
           end;
           TempSL.Add(GameParams.ReplayResultList[i] + GetRankAndNumber + ' (By Level ID)');
           GameParams.ReplayResultList[i] := TempString;
           GameParams.Info.dLevel := GameParams.Info.dLevel + 1;
         end;

         if not FoundMatch then
         begin
           // no need to preserve the ReplayResultList entry as this will be the last time the replay
           // in question is referenced here
           if SetParamsLevel(GameParams.ReplayResultList[i], false) then
           try
             F.PrepareGameParams;
             F.BuildScreenInvis;
             ShowPlayScreen;
           except
             GameParams.ReplayResultList[i] := ExtractFileName(GameParams.ReplayResultList[i]) + ': ERROR';
           end else
             GameParams.ReplayResultList[i] := ExtractFileName(GameParams.ReplayResultList[i]) + ': CANNOT FIND LEVEL';

           TempSL.Add(GameParams.ReplayResultList[i] + GetRankAndNumber + ' (By Position)');
         end;
       end;
       GameParams.ReplayCheckIndex := -2;
       GameParams.NextScreen := gstMenu;
       GameParams.Info.dSection := 0;
       GameParams.Info.dLevel := 0;
       ProduceReplayCheckResults;
       SoundVolume := OldSound;
       MusicVolume := OldMusic;
       TempSL.Free;
    end else begin
      // In the case of loading a single level file, menu screen will never be displayed.
      // Therefore, bringing to front must be done here.
      if not DoneBringToFront then BringToFront;
      F.ShowScreen;
    end;
  finally
    F.Free;
  end;
end;

end.
