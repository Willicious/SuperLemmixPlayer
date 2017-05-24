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
        Zip.OpenArchive(ParamStr(1), amOpen);
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
      Zip.OpenArchive(ParamStr(1), amOpen);
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

begin
  if ParamStr(1) = '' then
  begin
    WriteLn('Drag and drop an NXP file onto ' + ExtractFileName(ParamStr(0)) + ' to convert it.');
    ReadLn(Dummy);
    Exit;
  end;

  GameFile := ExtractFilePath(ParamStr(0));

  DstBasePath := GameFile + ExtractFileName(ChangeFileExt(ParamStr(1), '')) + '\';
  ForceDirectories(DstBasePath);
  ForceDirectories(DstBasePath + 'leveldata\'); // others are created as needed

  WriteLn('Please note that this tool only converts the level data,');
  WriteLn('talisman data and system texts. Custom music and images');
  WriteLn('must be added manually, and graphic sets converted with');
  WriteLn('a seperate tool.');
  WriteLn('');
  WriteLn('Press enter to continue with conversion of ' + ExtractFileName(ParamStr(1)) + '.');
  ReadLn(Dummy);

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
  for Rank := 0 to SysDat.RankCount-1 do
  begin
    WriteLn('Rank ' + IntToStr(Rank+1));
    ForceDirectories(DstBasePath + 'leveldata\' + MakeSafeForFilename(Trim(SysDat.RankNames[Rank])) + '\');
    SetCurrentDir(DstBasePath + 'leveldata\' + MakeSafeForFilename(Trim(SysDat.RankNames[Rank])) + '\');
    MainSec := Parser.MainSection;
    for Level := 0 to 255 do
    begin
      WriteLn('  Level ' + IntToStr(Level+1));
      if not DoesFileExist(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl') then
      begin
        WriteLn('    NOT FOUND');
        Break;
      end;
      CreateDataStream(LeadZeroStr(Rank, 2) + LeadZeroStr(Level, 2) + '.lvl', MS);
      TLvlLoader.LoadLevelFromStream(MS, GameParams.Level);
      GameParams.Level.SaveToFile(MakeSafeForFilename(Trim(GameParams.Level.Info.Title)) + '.nxlv');
      MainSec.AddLine('level', MakeSafeForFilename(Trim(GameParams.Level.Info.Title)) + '.nxlv');
      PieceManager.Tidy;
    end;
    Parser.SaveToFile('levels.nxmi');
    Parser.Clear;
  end;

  { Ranks }
  for Rank := 0 to SysDat.RankCount-1 do
  begin
    MainSec := Parser.MainSection.SectionList.Add('rank');
    MainSec.AddLine('name', Trim(SysDat.RankNames[Rank]));
    MainSec.AddLine('folder', MakeSafeForFilename(Trim(SysDat.RankNames[Rank])));
  end;
  Parser.SaveToFile(DstBasePath + 'leveldata\levels.nxmi');
  Parser.Clear;

  { Music Tracks }
  CreateDataStream('music.txt', MS);
  SL.LoadFromStream(MS);

  MainSec := Parser.MainSection;

  for i := 0 to SL.Count-1 do
    MainSec.AddLine('TRACK', SL[i]);

  Parser.SaveToFile(DstBasePath + 'leveldata\music.nxmi');
  Parser.Clear;

  { Postview Texts }
  MainSec := Parser.MainSection;

  for i := 0 to 8 do
  begin
    MainSec.SectionList.Add('result');
    MainSec.SectionList[i].AddLine('condition', POSTVIEW_CONDITIONS[i]);
    MainSec.SectionList[i].AddLine('line', Trim(SysDat.SResult[i][0]));
    MainSec.SectionList[i].AddLine('line', Trim(SysDat.SResult[i][1]));
  end;

  Parser.SaveToFile(DstBasePath + 'leveldata\postview.nxmi');
  Parser.Clear;

  { Basic Metainfo. We need to know about custom skill panels first. }
  MainSec := Parser.MainSection;

  MainSec.AddLine('TITLE', Trim(SysDat.PackName));
  MainSec.AddLine('AUTHOR', Trim(SysDat.SecondLine));

  MainSec := MainSec.SectionList.Add('scroller');
  for i := 0 to 15 do
    if Trim(SysDat.ScrollerTexts[i]) <> '' then
      MainSec.AddLine('line', Trim(SysDat.ScrollerTexts[i]));
  if MainSec.LineList.Count = 0 then
    Parser.MainSection.SectionList.Delete(1);

  Parser.SaveToFile(DstBasePath + 'leveldata\info.nxmi');
  Parser.Clear;
end.
