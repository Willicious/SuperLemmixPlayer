unit LemNeoLevelLoader;

interface

uses
  LemNeoParser,
  LemTerrain, LemInteractiveObject, LemSteel,
  LemLevelLoad, LemLevel, LemStrings,
  Classes, SysUtils;

type
  TNeoLevelLoader = class(TLevelLoader)
    public
      class procedure LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0); override;
      class procedure StoreLevelInStream(aLevel: TLevel; aStream: TStream); override;
  end;

implementation

class procedure TNeoLevelLoader.StoreLevelInStream(aLevel: TLevel; aStream: TStream);
var
  SL: TStringList;
  i: Integer;
  O: TInteractiveObject;
  T: TTerrain;
  S: TSteel;

  procedure Add(const aString: String = '');
  begin
    SL.Add(aString);
  end;
begin
  SL := TStringList.Create;
  try
    {Buf.ReleaseRate   := ReleaseRate;
      Buf.LemmingsCount := LemmingsCount;
      Buf.RescueCount   := RescueCount;
      Buf.TimeLimit     := TimeLimit;
      Buf.Skillset      := SkillTypes;}
    Add('# NeoLemmix Level')
    Add('# Dumped from NeoLemmix Player V' + PVersion);
    Add;

    // Statics
    with aLevel.Info do
    begin
      Add('# Level info');
      Add(' TITLE ' + Title);
      Add(' AUTHOR ' + Author);
      if MusicName <> '' then
        Add(' MUSIC ' + MusicName);
      Add(' ID ' + IntToHex(LevelID, 8));
      Add;

      Add('# Level dimensions');
      Add(' WIDTH ' + Width);
      Add(' HEIGHT ' + Height);
      Add(' START_X ' + ScreenPosition);
      Add(' START_Y ' + ScreenYPosition);
      Add(' THEME ' + GraphicSetName);
      Add;

      Add('# Level stats');
      Add(' LEMMINGS ' + IntToStr(LemmingsCount));
      Add(' REQUIREMENT ' + IntToStr(RescueCount));
      if TimeLimit < 6000 then
        Add(' TIME_LIMIT ' + IntToStr(TimeLimit));
      Add(' MIN_RR ' + IntToStr(ReleaseRate));
      Add(' MAX_RR 99');
      if (LevelOptions and $02) = 0 then
        Add(' AUTOSTEEL OFF')
      else if (LevelOptions and $08) <> 0 then
        Add(' AUTOSTEEL SIMPLE'); // Don't need to add "AUTOSTEEL ON", it's default.
      Add;

      Add('# Level skillset');
      if (SkillTypes and $8000 <> 0) then Add('     WALKER ' + IntToStr(WalkerCount));
      if (SkillTypes and $4000 <> 0) then Add('    CLIMBER ' + IntToStr(ClimberCount));
      if (SkillTypes and $2000 <> 0) then Add('    SWIMMER ' + IntToStr(SwimmerCount));
      if (SkillTypes and $1000 <> 0) then Add('    FLOATER ' + IntToStr(FloaterCount));
      if (SkillTypes and $0800 <> 0) then Add('     GLIDER ' + IntToStr(GliderCount));
      if (SkillTypes and $0400 <> 0) then Add('   DISARMER ' + IntToStr(DisarmerCount));
      if (SkillTypes and $0200 <> 0) then Add('     BOMBER ' + IntToStr(BomberCount));
      if (SkillTypes and $0100 <> 0) then Add('     STONER ' + IntToStr(StonerCount));
      if (SkillTypes and $0080 <> 0) then Add('    BLOCKER ' + IntToStr(BlockerCount));
      if (SkillTypes and $0040 <> 0) then Add(' PLATFORMER ' + IntToStr(PlatformerCount));
      if (SkillTypes and $0020 <> 0) then Add('    BUILDER ' + IntToStr(BuilderCount));
      if (SkillTypes and $0010 <> 0) then Add('    STACKER ' + IntToStr(StackerCount));
      if (SkillTypes and $0008 <> 0) then Add('     BASHER ' + IntToStr(BasherCount));
      if (SkillTypes and $0004 <> 0) then Add('      MINER ' + IntToStr(MinerCount));
      if (SkillTypes and $0002 <> 0) then Add('     DIGGER ' + IntToStr(DiggerCount));
      if (SkillTypes and $0001 <> 0) then Add('     CLONER ' + IntToStr(ClonerCount));
      Add;

      if Length(WindowOrder) <> 0 then
      begin
        Add('# Window order');
        for i := 0 to Length(WindowOrder)-1 do
          Add(' SPAWN ' + IntToStr(WindowOrder[i]));
        Add;
      end;
    end;

    with aLevel do
    begin
      // Interactive Objects
      Add('# Interactive objects');
      for i := 0 to InteractiveObjects.Count-1 do
      begin
        O := InteractiveObjects[i];
        Add(' OBJECT');
        Add('  SET ' + Info.GraphicSetName);
        Add('  PIECE ' + IntToStr(O.Identifier));
        Add('  X ' + IntToStr(O.Left));
        Add('  Y ' + IntToStr(O.Top));
        if O.TarLev <> 0 then Add('  L ' + IntToStr(O.TarLev));
        if O.Skill <> 0 then Add('  S ' + IntToStr(O.Skill));
        if O.DrawingFlags and odf_NoOverwrite <> 0 then
          Add('  NO_OVERWRITE');
        if O.DrawingFlags and odf_OnlyOnTerrain <> 0 then
          Add('  ONLY_ON_TERRAIN');
        if O.DrawingFlags and odf_Flip <> 0 then
          Add('  FLIP_HORIZONTAL');
        if O.DrawingFlags and odf_UpsideDown <> 0 then
          Add('  FLIP_VERTICAL');
        if O.DrawingFlags and odf_FlipLem <> 0 then
          Add('  FACE_LEFT');
        if O.IsFake then
          Add('  FAKE');
        if O.DrawingFlags and odf_Invisible <> 0 then
          Add('  INVISIBLE');
        Add;
      end;
      Add;

      // Terrains
      Add('# Terrains');

      if Info.VgaspecFile <> '' then
      begin
        Add(' TERRAIN');
        Add('  SET SPECIAL');
        Add('  PIECE ' + VgaspecFile);
        Add('  X ' + IntToStr(Info.VgaspecX));
        Add('  Y ' + IntToStr(Info.VgaspecY));
        Add;
      end;

      for i := 0 to Terrains.Count-1 do
      begin
        T := Terrains[i];
        Add(' TERRAIN');
        Add('  SET ' + Info.GraphicSetName);
        Add('  PIECE ' + IntToStr(T.Identifier));
        Add('  X ' + IntToStr(T.Left));
        Add('  Y ' + IntToStr(T.Top));
        if T.DrawingFlags and tdf_NoOverwrite <> 0 then
          Add('  NO_OVERWRITE');
        if T.DrawingFlags and tdf_Erase <> 0 then
          Add('  ERASE');
        if T.DrawingFlags and tdf_Rotate <> 0 then
          Add('  ROTATE');
        if T.DrawingFlags and tdf_Flip <> 0 then
          Add('  FLIP_HORIZONTAL');
        if T.DrawingFlags and tdf_Invert <> 0 then
          Add('  FLIP_VERTICAL');
        if Info.LevelOptions and $80 = 0 then
        begin
          if T.DrawingFlags and tdf_NoOneWay <> 0 then
            Add('  ONE_WAY');
        end else begin
          if T.DrawingFlags and tdf_NoOneWay = 0 then
            Add('  ONE_WAY');
        end;
        Add;
      end;

      // Steels
      if Steels.Count > 0 then
      begin
        Add('# Steel areas');
        for i := 0 to Steels.Count-1 do
        begin
          S := Steels[i];
          if S.fType = 5 then Continue;
          Add(' AREA');
          case S.fType of
            1: Add('  NEGATIVE_STEEL');
            2: Add('  ONE_WAY_LEFT');
            3: Add('  ONE_WAY_RIGHT');
            4: Add('  ONE_WAY_DOWN');
            else Add('  STEEL');
          end;
          Add('  X ' + IntToStr(S.Left));
          Add('  Y ' + IntToStr(S.Top));
          Add('  W ' + IntToStr(S.Width));
          Add('  H ' + IntToStr(S.Height));
        end;
        Add;
      end;
    end;
  finally
    SL.Free;
  end;
end;

end.