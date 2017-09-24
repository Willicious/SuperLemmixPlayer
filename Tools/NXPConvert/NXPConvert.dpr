program NXPConvert;

{$APPTYPE CONSOLE}

uses
  LemRes,
  UZip,
  LemTalisman,
  TalisData,
  SharedGlobals,
  LemDosStructures,
  LemLVLLoader,
  LemCore,
  GameSound, GameControl, LemRendering, LemNeoPieceManager, LemLevel,
  Classes, SysUtils,
  LemNeoParser,
  LemStrings;

var
  SrcFile: String;

  procedure Write(aText: String);
  begin
    if ParamStr(2) = 'silent' then Exit; // to allow silent batch conversion via a BAT file cause i'm lazy
    WriteLn(aText);
  end;

  procedure ClearInvalidPieces(aLevel: TLevel);
  var
    i: Integer;

    function IsInsideLevel(X, Y, W, H: Integer): Boolean;
    var
      EffectiveSize: Integer;
    begin
      if H > W then
        EffectiveSize := H
      else
        EffectiveSize := W;

      Result := (X > 0-EffectiveSize) and (X < aLevel.Info.Width)
            and (Y > 0-EffectiveSize) and (Y < aLevel.Info.Height);

      if not Result then
      begin
        Write('    Removed piece: ' + IntToStr(X) + ',' + IntToStr(Y) + ' : ' + IntToStr(W) + 'x' + IntToStr(H));
      end;
    end;
  begin
    Write('  Removing invalid pieces');

    for i := aLevel.InteractiveObjects.Count-1 downto 0 do
      if not IsInsideLevel(aLevel.InteractiveObjects[i].Left, aLevel.InteractiveObjects[i].Top,
                           PieceManager.Objects[aLevel.InteractiveObjects[i].Identifier].Width[false, false, false],
                           PieceManager.Objects[aLevel.InteractiveObjects[i].Identifier].Height[false, false, false]) then
        aLevel.InteractiveObjects.Delete(i);

    for i := aLevel.Terrains.Count-1 downto 0 do
      if not IsInsideLevel(aLevel.Terrains[i].Left, aLevel.Terrains[i].Top,
                           PieceManager.Terrains[aLevel.Terrains[i].Identifier].GraphicImage[false, false, false].Width,
                           PieceManager.Terrains[aLevel.Terrains[i].Identifier].GraphicImage[false, false, false].Height) then
        aLevel.Terrains.Delete(i);
  end;

  function DoesFileExist(aName: String; aZip: TArchive = nil): Boolean;
  var
    Zip: TArchive;
  begin
    if aZip = nil then
      Zip := TArchive.Create
    else
      Zip := aZip;

    try
      if aZip = nil then
        Zip.OpenArchive(SrcFile, amOpen);
      Result := Zip.CheckIfFileExists(aName);
    finally
      if aZip = nil then
        Zip.Free;
    end;
  end;

  function CreateDataStream(aName: String; aStream: TMemoryStream = nil): TMemoryStream;
  var
    Zip: TArchive;
    Dst: TMemoryStream;
  begin
    Result := nil;
    Dst := nil;
    Zip := TArchive.Create;
    try
      Zip.OpenArchive(SrcFile, amOpen);
      if not DoesFileExist(aName, Zip) then Exit;
      try
        if aStream = nil then
          Dst := TMemoryStream.Create
        else begin
          Dst := aStream;
          Dst.Clear;
        end;
        Zip.ExtractFile(aName, Dst);
        Dst.Position := 0;
        Result := Dst;
      except
        Dst.Free;
      end;
    finally
      Zip.Free;
    end;
  end;

  function MakeSafeForFilename(const aString: String): String;
  var
    i, i2: Integer;
  const
    FORBIDDEN_CHARS = '<>:"/\|?* ';
  begin
    Result := aString;
    for i := 1 to Length(aString) do
      for i2 := 1 to Length(FORBIDDEN_CHARS) do
        if Result[i] = FORBIDDEN_CHARS[i2] then
          Result[i] := '_';
    if Length(Result) = 0 then
      Result := '_';
  end;

  function LeadZeroStr(aValue: Integer; aLen: Integer): String;
  begin
    Result := IntToStr(aValue);
    while Length(Result) < aLen do
      Result := '0' + Result;
  end;

  procedure DirectExtract(aName: String; aOutName: String = '');
  var
    TempStream: TMemoryStream;
  begin
    if aOutName = '' then aOutName := aName;
    TempStream := CreateDataStream(aName);
    try
      if TempStream <> nil then
        TempStream.SaveToFile(aOutName);
    finally
      TempStream.Free;
    end;
  end;

const
  POSTVIEW_CONDITIONS: array[0..8] of String = ('0', '-50%', '-10%', '-2', '-1', '+0', '+1', '+20%', '100%');

var
  Dummy: String;
  SysDat: TSysDatRec;
  MS: TMemoryStream;
  SL: TStringList;
  Parser: TParser;
  MainSec: TParserSection;
  i: Integer;
  Rank, Level: Integer;

  NewTal: LemTalisman.TTalisman;
  OldTal: TalisData.TTalisman;
  Talismans: TTalismans;

  DstBasePath: String;

  RankFoldername: String;
  RankFoldernames: array of String;
  LevelFilename: String;
  n: Integer;
  s: TSkillPanelButton;

begin
  if ParamStr(1) = '' then
  begin
    WriteLn('Drag and drop an NXP file onto ' + ExtractFileName(ParamStr(0)) + ' to convert it.');
    ReadLn(Dummy);
    Exit;
    //SrcFile := ExtractFilePath(ParamStr(0)) + 'NepsterLems.nxp';
  end;

  SrcFile := ParamStr(1);
  if Pos(':', SrcFile) = 0 then
    SrcFile := ExtractFilePath(ParamStr(0)) + SrcFile;

  DstBasePath := ExtractFilePath(ParamStr(0)) + 'levels\' + ExtractFileName(ChangeFileExt(SrcFile, '')) + '\';
  ForceDirectories(DstBasePath); // others are created as needed

  Write('Please note that this tool only converts the level data,');
  Write('talisman data, system texts, and menu graphics. Custom');
  Write('skill panels or lemming sprites are not currently handled.');
  Write('These must be imported manually, and graphic sets must');
  Write('be converted with GSConvert.exe *before* attempting to');
  Write('convert the NXP.');
  Write('');
  Write('Press enter to continue with conversion of ' + ExtractFileName(SrcFile) + '.');
  if ParamStr(2) <> 'silent' then ReadLn(Dummy);

  try
    SoundManager := TSoundManager.Create;
    GameParams := TDosGameParams.Create;
    PieceManager := TNeoPieceManager.Create;
    GameParams.Renderer := TRenderer.Create;
    GameParams.Level := TLevel.Create;
    Talismans := TTalismans.Create;

    Parser := TParser.Create;
    SL := TStringList.Create;
  except
    on E: Exception do
    begin
      Write('An error occured while creating game objects:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  try
    MS := CreateDataStream('system.dat');
    MS.Read(SysDat, SizeOf(TSysDatRec));
  except
    on E: Exception do
    begin
      Write('An error occured while extracting the system.dat:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  try
    if DoesFileExist('talisman.dat') then
    begin
      CreateDataStream('talisman.dat', MS);
      Talismans.LoadFromStream(MS);
    end;
  except
    on E: Exception do
    begin
      Write('An error occured while extracting the talismans:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;


  try
    { Logo and Menu Signs}
    SetCurrentDir(DstBasePath); // just to be safe
    DirectExtract('logo.png');
    DirectExtract('background.png');
    DirectExtract('menu_font.png');
    DirectExtract('scroller_lemmings.png');
    DirectExtract('scroller_segment.png');
    DirectExtract('sign_play.png');
    DirectExtract('sign_code.png');
    DirectExtract('sign_rank.png');
    DirectExtract('sign_config.png');
    DirectExtract('sign_talisman.png');
    DirectExtract('sign_quit.png');
    DirectExtract('talismans.png');
    DirectExtract('tick.png');
  except
    on E: Exception do
    begin
      Write('An error occured while extracting sprites:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;


  { Level Files }
  SetLength(RankFolderNames, SysDat.RankCount);
  for Rank := 0 to SysDat.RankCount-1 do
  begin
    try
      Write('Rank ' + IntToStr(Rank+1));
      n := 0;
      RankFoldername := MakeSafeForFilename(Trim(SysDat.RankNames[Rank]));
      while DirectoryExists(DstBasePath + RankFoldername) do
      begin
        Inc(n);
        RankFoldername := MakeSafeForFilename(Trim(SysDat.RankNames[Rank])) + '(' + IntToStr(n) + ')';
      end;
      RankFoldernames[Rank] := RankFoldername;
      ForceDirectories(DstBasePath + RankFoldername + '\');
      MainSec := Parser.MainSection;
    except
      on E: Exception do
      begin
        Write('An error occured while loading a new rank:');
        Write(E.Message);
        ReadLn(Dummy);
        Exit;
      end;
    end;

    for Level := 0 to 255 do
    begin
      try
        if not DoesFileExist(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl') then
          Break;
        Write('  Level ' + IntToStr(Level+1));
        CreateDataStream(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl', MS);
        TLVLLoader.LoadLevelFromStream(MS, GameParams.Level, lfLemmix);
        GameParams.Level.Sanitize;
        if CreateDataStream('i' + LeadZeroStr(Rank+1, 2) + LeadZeroStr(Level+1, 2) + '.txt', MS) <> nil then
          GameParams.Level.PreText.LoadFromStream(MS);
        if CreateDataStream('p' + LeadZeroStr(Rank+1, 2) + LeadZeroStr(Level+1, 2) + '.txt', MS) <> nil then
          GameParams.Level.PostText.LoadFromStream(MS);
        //ClearInvalidPieces(GameParams.Level);
      except
        on E: Exception do
        begin
          Write('An error occured while loading a new level:');
          Write(E.Message);
          ReadLn(Dummy);
          Exit;
        end;
      end;

      try
        for i := 0 to Talismans.Count-1 do
          if (Talismans[i].RankNumber = Rank) and (Talismans[i].LevelNumber = Level) then
          begin
            //Write('    Trying to convert talisman...');
            OldTal := Talismans[i];
            NewTal := LemTalisman.TTalisman.Create;

            NewTal.Title := OldTal.Description;
            NewTal.ID := i;
            case OldTal.TalismanType of
              0: begin
                   Write('    Removed a talisman due to being of "Hidden" type');
                   NewTal.Free;
                   Continue;
                 end;
              2: NewTal.Color := tcSilver;
              3: NewTal.Color := tcGold;
              else NewTal.Color := tcBronze;
            end;

            if OldTal.SaveRequirement <> GameParams.Level.Info.RescueCount then
              NewTal.RescueCount := OldTal.SaveRequirement;
            if (OldTal.TimeLimit > 0) and (OldTal.TimeLimit <> GameParams.Level.Info.TimeLimit * 17) then
              NewTal.TimeLimit := OldTal.TimeLimit;

            if    (OldTal.RRMin > (53 - GameParams.Level.Info.SpawnInterval) * 2)
               or ((OldTal.RRMax < 99) and not GameParams.Level.Info.SpawnIntervalLocked) then
            begin
              Write('    Removed a talisman due to using no-longer-supported feature: Release rate limits');
              NewTal.Free;
              Continue;
            end;

            if OldTal.TotalSkillLimit >= 0 then NewTal.TotalSkillLimit := OldTal.TotalSkillLimit;

            if OldTal.SkillLimit[0] >= 0 then NewTal.SkillLimit[spbWalker] := OldTal.SkillLimit[0];
            if OldTal.SkillLimit[1] >= 0 then NewTal.SkillLimit[spbClimber] := OldTal.SkillLimit[1];
            if OldTal.SkillLimit[2] >= 0 then NewTal.SkillLimit[spbSwimmer] := OldTal.SkillLimit[2];
            if OldTal.SkillLimit[3] >= 0 then NewTal.SkillLimit[spbFloater] := OldTal.SkillLimit[3];
            if OldTal.SkillLimit[4] >= 0 then NewTal.SkillLimit[spbGlider] := OldTal.SkillLimit[4];
            if OldTal.SkillLimit[5] >= 0 then NewTal.SkillLimit[spbDisarmer] := OldTal.SkillLimit[5];
            if OldTal.SkillLimit[6] >= 0 then NewTal.SkillLimit[spbBomber] := OldTal.SkillLimit[6];
            if OldTal.SkillLimit[7] >= 0 then NewTal.SkillLimit[spbStoner] := OldTal.SkillLimit[7];
            if OldTal.SkillLimit[8] >= 0 then NewTal.SkillLimit[spbBlocker] := OldTal.SkillLimit[8];
            if OldTal.SkillLimit[9] >= 0 then NewTal.SkillLimit[spbPlatformer] := OldTal.SkillLimit[9];
            if OldTal.SkillLimit[10] >= 0 then NewTal.SkillLimit[spbBuilder] := OldTal.SkillLimit[10];
            if OldTal.SkillLimit[11] >= 0 then NewTal.SkillLimit[spbStacker] := OldTal.SkillLimit[11];
            if OldTal.SkillLimit[12] >= 0 then NewTal.SkillLimit[spbBasher] := OldTal.SkillLimit[12];
            if OldTal.SkillLimit[13] >= 0 then NewTal.SkillLimit[spbMiner] := OldTal.SkillLimit[13];
            if OldTal.SkillLimit[14] >= 0 then NewTal.SkillLimit[spbDigger] := OldTal.SkillLimit[14];
            if OldTal.SkillLimit[15] >= 0 then NewTal.SkillLimit[spbCloner] := OldTal.SkillLimit[15];
            if OldTal.SkillLimit[16] >= 0 then NewTal.SkillLimit[spbFencer] := OldTal.SkillLimit[16];

            for s := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
              if (NewTal.SkillLimit[s] = GameParams.Level.Info.SkillCount[s]) or not (s in GameParams.Level.Info.Skillset) then
                NewTal.SkillLimit[s] := -1;

            if OldTal.MiscOptions * [tmOneSkill, tmOneLemming, tmFindSecret] <> [] then
            begin
              Write('    Removed a talisman due to using a miscellaneous no-longer-supported feature');
              NewTal.Free;
              Continue;
            end;

            GameParams.Level.Talismans.Add(NewTal);
          end;
      except
        on E: Exception do
        begin
          Write('An error occured while updating the talisman to that level:');
          Write(E.Message);
          ReadLn(Dummy);
          Exit;
        end;
      end;

      try
        LevelFilename := MakeSafeForFilename(Trim(GameParams.Level.Info.Title));
        n := 0;
        while FileExists(DstBasePath + RankFoldername + '\' + LevelFilename + '.nxlv') do
        begin
          Inc(n);
          LevelFilename := MakeSafeForFilename(Trim(GameParams.Level.Info.Title)) + '(' + IntToStr(n) + ')';
        end;
        GameParams.Level.SaveToFile(DstBasePath + RankFoldername + '\' + LevelFilename + '.nxlv');
        MainSec.AddLine('level', LevelFilename + '.nxlv');
        PieceManager.Tidy;
      except
        on E: Exception do
        begin
          Write('An error occured while saving the new-formats version of the level:');
          Write(E.Message);
          ReadLn(Dummy);
          Exit;
        end;
      end;
    end;

    try
      DirectExtract('rank_' + LeadZeroStr(Rank+1, 2) + '.png', DstBasePath + RankFolderName + '\rank_graphic.png');
      Parser.SaveToFile(DstBasePath + RankFoldername + '\levels.nxmi');
      Parser.Clear;
    except
      on E: Exception do
      begin
        Write('An error occured while saving the level list:');
        Write(E.Message);
        ReadLn(Dummy);
        Exit;
      end;
    end;
  end;

  try
    { Ranks }
    Write('Rank metainfo');
    for Rank := 0 to SysDat.RankCount-1 do
    begin
      MainSec := Parser.MainSection.SectionList.Add('rank');
      MainSec.AddLine('name', Trim(SysDat.RankNames[Rank]));
      MainSec.AddLine('folder', RankFoldernames[Rank]);
    end;
    Parser.MainSection.AddLine('base');
    Parser.SaveToFile(DstBasePath + 'levels.nxmi');
    Parser.Clear;
  except
    on E: Exception do
    begin
      Write('An error occured while saving the rank meta-data:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  try
    { Music Tracks }
    Write('Music rotation');
    CreateDataStream('music.txt', MS);
    SL.LoadFromStream(MS);

    MainSec := Parser.MainSection;

    for i := 0 to SL.Count-1 do
      MainSec.AddLine('TRACK', SL[i]);

    Parser.SaveToFile(DstBasePath + 'music.nxmi');

    SL.Clear;
    Parser.Clear;
  except
    on E: Exception do
    begin
      Write('An error occured while saving the music rotation:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  try
    { Postview Texts }
    Write('Postview texts');
    MainSec := Parser.MainSection;

    for i := 0 to 8 do
    begin
      MainSec.SectionList.Add('result');
      MainSec.SectionList[i].AddLine('condition', POSTVIEW_CONDITIONS[i]);
      MainSec.SectionList[i].AddLine('line', Trim(SysDat.SResult[i][0]));
      MainSec.SectionList[i].AddLine('line', Trim(SysDat.SResult[i][1]));
    end;

    Parser.SaveToFile(DstBasePath + 'postview.nxmi');
    Parser.Clear;
  except
    on E: Exception do
    begin
      Write('An error occured while saving the result strings:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  try
    { Basic Metainfo }
    Write('General metainfo');
    MainSec := Parser.MainSection;

    MainSec.AddLine('TITLE', Trim(SysDat.PackName));
    MainSec.AddLine('AUTHOR', Trim(SysDat.SecondLine));

    MainSec := MainSec.SectionList.Add('scroller');
    for i := 0 to 15 do
      if Trim(SysDat.ScrollerTexts[i]) <> '' then
        MainSec.AddLine('line', Trim(SysDat.ScrollerTexts[i]));
    if MainSec.LineList.Count = 0 then
      Parser.MainSection.SectionList.Delete(1);

    Parser.SaveToFile(DstBasePath + 'info.nxmi');
    Parser.Clear
  except
    on E: Exception do
    begin
      Write('An error occured while saving the general meta-data:');
      Write(E.Message);
      ReadLn(Dummy);
      Exit;
    end;
  end;

  Write('Conversion finished! Press enter to exit.');
  if ParamStr(2) <> 'silent' then ReadLn(Dummy);
end.
