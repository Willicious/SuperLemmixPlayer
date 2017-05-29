program NXPConvert;

{$APPTYPE CONSOLE}
{$R bass.res}
{$R explode.res}

uses
  UZip,
  SharedGlobals,
  LemDosStructures,
  LemLVLLoader,
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

    for i := aLevel.Steels.Count-1 downto 0 do
      if not IsInsideLevel(aLevel.Steels[i].Left, aLevel.Steels[i].Top, aLevel.Steels[i].Width, aLevel.Steels[i].Height) then
        aLevel.Steels.Delete(i);
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
  HasCustomPanel: Boolean;
  Rank, Level: Integer;

  DstBasePath: String;

  RankFoldername: String;
  RankFoldernames: array of String;
  LevelFilename: String;
  n: Integer;

begin
  if ParamStr(1) = '' then
  begin
    WriteLn('Drag and drop an NXP file onto ' + ExtractFileName(ParamStr(0)) + ' to convert it.');
    ReadLn(Dummy);
    Exit;
  end;

  SrcFile := ParamStr(1);
  if Pos(':', SrcFile) = 0 then
    SrcFile := ExtractFilePath(ParamStr(0)) + SrcFile;
  GameFile := ExtractFilePath(ParamStr(0)) + 'data\';

  DstBasePath := ExtractFilePath(ParamStr(0)) + 'levels\' + ExtractFileName(ChangeFileExt(SrcFile, '')) + '\';
  ForceDirectories(DstBasePath); // others are created as needed

  Write('Please note that this tool only converts the level data,');
  Write('talisman data and system texts. Custom music and images');
  Write('must be added manually, and graphic sets converted with');
  Write('a seperate tool.');
  Write('');
  Write('Press enter to continue with conversion of ' + ExtractFileName(SrcFile) + '.');
  if ParamStr(2) <> 'silent' then ReadLn(Dummy);

  SoundManager := TSoundManager.Create;
  GameParams := TDosGameParams.Create;
  GameParams.fTestMode := true;
  PieceManager := TNeoPieceManager.Create;
  GameParams.Renderer := TRenderer.Create;
  GameParams.Level := TLevel.Create;

  Parser := TParser.Create;
  SL := TStringList.Create;

  MS := CreateDataStream('system.dat');
  MS.Read(SysDat, SizeOf(TSysDatRec));

  { Level Files }
  SetLength(RankFolderNames, SysDat.RankCount);
  for Rank := 0 to SysDat.RankCount-1 do
  begin
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
    for Level := 0 to 255 do
    begin
      if not DoesFileExist(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl') then
        Break;
      Write('  Level ' + IntToStr(Level+1));
      CreateDataStream(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl', MS);
      TLvlLoader.LoadLevelFromStream(MS, GameParams.Level);
      if CreateDataStream('i' + LeadZeroStr(Rank+1, 2) + LeadZeroStr(Level+1, 2) + '.txt', MS) <> nil then
        GameParams.Level.PreText.LoadFromStream(MS);
      if CreateDataStream('p' + LeadZeroStr(Rank+1, 2) + LeadZeroStr(Level+1, 2) + '.txt', MS) <> nil then
        GameParams.Level.PostText.LoadFromStream(MS);
      ClearInvalidPieces(GameParams.Level);
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
    end;
    Parser.SaveToFile(DstBasePath + RankFoldername + '\levels.nxmi');
    Parser.Clear;
  end;

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
  Parser.Clear;

  { Launcher file }
  SL.SaveToFile(DstBasePath + ChangeFileExt(ExtractFileName(SrcFile), '.nxlp'));
end.
