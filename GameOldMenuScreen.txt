{ TGameOldMenuScreen }

// CLEAN INSTALL CHECK

(*
procedure TGameOldMenuScreen.PerformCleanInstallCheck;
var
  SL: TStringList;
  FMVer, CVer: Integer;
begin
  DoneCleanInstallCheck := true;

  SL := TStringList.Create;
  try
    if FileExists(AppPath + 'styles\version.ini') then
    begin
      SL.LoadFromFile(AppPath + 'styles\version.ini');
      if SL.Count >= 4 then
      begin
        FMVer := StrToIntDef(SL[0], -1);
        CVer := StrToIntDef(SL[1], -1);

        if (FMVer < FORMAT_VERSION) or
           ((FMVer = FORMAT_VERSION) and (CVer < CORE_VERSION)) then
        ShowMessage('It appears you have installed this version of NeoLemmix over an older major version. This is not recommended. ' +
                    'It is recommended that you perform a fresh, clean install of NeoLemmix whenever updating between major versions. ' +
                    'If you encounter any bugs, especially relating to styles, please test with a fresh install before reporting them.');
      end;
    end;

    SL.Clear;
    SL.Add(IntToStr(FORMAT_VERSION));
    SL.Add(IntToStr(CORE_VERSION));
    SL.Add(IntToStr(FEATURES_VERSION));
    SL.Add(IntToStr(HOTFIX_VERSION));
    {$ifdef rc}
      SL.Add('RC');
    {$else}
      {$ifdef exp}
        SL.Add('EXP');
      {$else}
        SL.Add('STABLE');
      {$endif}
    {$endif}

    SL.SaveToFile(AppPath + 'styles\version.ini');
  finally
    SL.Free;
  end;
end;
*)



// UPDATE CHECK

(*
procedure TGameOldMenuScreen.PerformUpdateCheck;
begin
  // Checks if the latest version according to NeoLemmix Website is more recent than the
  // one currently running. If running an experimental version, also checks if it's the
  // exact same version (as it would be a stable release).
  GameParams.DoneUpdateCheck := true;

  if not GameParams.CheckUpdates then Exit;

  fUpdateCheckThread := DownloadInThread(VERSION_FILE, fVersionInfo,
    procedure
    var
      NewVersionStr, OrigVersionStr: String;
      SL: TStringList;
      n: Integer;
      NewestID: Int64;
      URL: String;
      F: TFManageStyles;
    begin
      NewVersionStr := fVersionInfo.Values['game'];
      if LeftStr(NewVersionStr, 1) = 'V' then
        NewVersionStr := RightStr(NewVersionStr, Length(NewVersionStr)-1);

      OrigVersionStr := NewVersionStr;
      NewVersionStr := StringReplace(NewVersionStr, '-', '.', [rfReplaceAll]);

      SL := TStringList.Create;
      try
        try
          SL.Delimiter := '.';
          SL.StrictDelimiter := true;
          SL.DelimitedText := NewVersionStr;

          if SL.Count < 4 then
            SL.Add('A');

          SL[3] := Char(Ord(SL[3][1]) - 65);

          NewestID := 0;
          for n := 0 to 3 do
            NewestID := (NewestID * 1000) + StrToIntDef(SL[n], 0);

          if (NewestID > CurrentVersionID){$ifdef exp} or (NewestID = CurrentVersionID){$endif} then
          begin
            case RunCustomPopup(self, 'Update', 'A NeoLemmix update, V' + OrigVersionStr + ', is available. Do you want to download it?',
              'Go to NeoLemmix website|Remind me later') of
              1: begin
                   URL := 'https://www.neolemmix.com/?page=neolemmix';
                   ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
                   CloseScreen(gstExit);
                 end;
               // 2: do nothing;
            end;
          end else if CheckStyleUpdates then
          begin
            // Add cursor stuff here

            case RunCustomPopup(self, 'Styles Update', 'Styles updates are available. Do you want to download them?',
              'Open Style Manager|Remind me later') of
              1: begin
                   F := TFManageStyles.Create(self);
                   try
                     F.ShowModal;
                   finally
                     F.Free;
                   end;
                 end;
              // 2: do nothing;
            end;
          end;

        except
          // Fail silently.
        end;
      finally
        SL.Free;
      end;

      fUpdateCheckThread := nil;
    end
  );
end;
*)


// RANK SIGN

(*
procedure TGameOldMenuScreen.SetSection;
const
  MAX_AUTOGEN_WIDTH = 70;
  MAX_AUTOGEN_HEIGHT = 30;
var
  Bmp, TempBmp: TBitmap32;
  Sca: Double;
begin
  DrawBitmapElement(gmbSection); // This allows for transparency in the gmbGameSectionN bitmaps

  Bmp := BitmapElements[gmbGameSection];

  if not GetGraphic('rank_graphic.png', Bmp, true) then
  begin
    TempBmp := TBitmap32.Create;
    try
      //MakeAutoSectionGraphic(TempBmp);

      if (TempBmp.Width <= MAX_AUTOGEN_WIDTH) and (TempBmp.Height < MAX_AUTOGEN_HEIGHT) then
        Sca := 1
      else
        Sca := Min(MAX_AUTOGEN_WIDTH / TempBmp.Width, MAX_AUTOGEN_HEIGHT / TempBmp.Height);

      Bmp.SetSize(Round(TempBmp.Width * Sca), Round(TempBmp.Height * Sca));
      Bmp.Clear(0);

      if Sca <> 1 then
        TLinearResampler.Create(TempBmp);

      TempBmp.DrawTo(Bmp, Bmp.BoundsRect);
    finally
      TempBmp.Free;
    end;
  end;

  DrawBitmapElement(gmbGameSection);
end;
*)



// SETUP MENU

(*
procedure TGameOldMenuScreen.ShowSetupMenu;
var
  F: TFNLSetup;
begin
  F := TFNLSetup.Create(self);
  try
    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(true, false, false, false);
  finally
    F.Free;
  end;
end;
*)

