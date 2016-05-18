unit LemNeoLevelLoader;

interface

uses
  LemNeoParser,
  LemTerrain, LemInteractiveObject, LemSteel,
  LemLevel, LemStrings,
  Classes, SysUtils;

type
  TNeoLevelLoader = class
    public
      class procedure LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
      class procedure StoreLevelInStream(aLevel: TLevel; aStream: TStream);
  end;

implementation

class procedure TNeoLevelLoader.LoadLevelFromStream(aStream: TStream; aLevel: TLevel; OddLoad: Byte = 0);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  O: TInteractiveObject;
  T: TTerrain;
  S: TSteel;

  function NewPiece: Boolean;
  begin
    Result := false;
    if Line.Keyword = 'OBJECT' then Result := true;
    if Line.Keyword = 'TERRAIN' then Result := true;
    if Line.Keyword = 'AREA' then Result := true;
    if Line.Keyword = '' then Result := true; // Detect end of file as well
  end;

begin
  aLevel.ClearLevel;
  O := nil;
  T := nil;
  S := nil;
  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromStream(aStream);

    // Stage 1. Anything that comes before an OBJECT, TERRAIN or AREA definition
    repeat
      Line := Parser.NextLine;

      with aLevel.Info do
      begin
        // There are a lot of keywords we can encounter here.

        if Line.Keyword = 'TITLE' then
          Title := Line.Value;

        if Line.Keyword = 'AUTHOR' then
          Author := Line.Value;

        if Line.Keyword = 'MUSIC' then
          MusicFile := Line.Value;

        if Line.Keyword = 'ID' then
          LevelID := StrToIntDef('x' + Line.Value, 0);

        if Line.Keyword = 'WIDTH' then
          Width := Line.Numeric;

        if Line.Keyword = 'HEIGHT' then
          Height := Line.Numeric;

        if Line.Keyword = 'START_X' then
          ScreenPosition := Line.Numeric;

        if Line.Keyword = 'START_Y' then
          ScreenYPosition := Line.Numeric;

        if Line.Keyword = 'THEME' then
          GraphicSetName := Line.Value;

        if Line.Keyword = 'LEMMINGS' then
          LemmingsCount := Line.Numeric;

        if Line.Keyword = 'REQUIREMENT' then
          RescueCount := Line.Numeric;

        if Line.Keyword = 'TIME_LIMIT' then
          TimeLimit := Line.Numeric;

        if Line.Keyword = 'MIN_RR' then
          ReleaseRate := Line.Numeric;

        // MAX_RR support needs to be implemented in-game first

        if Line.Keyword = 'AUTOSTEEL' then
          if Uppercase(Line.Value) = 'OFF' then
            LevelOptions := LevelOptions and not $0A
          else if Uppercase(Line.Value) = 'SIMPLE' then
            LevelOptions := LevelOptions or $0A
          else if Uppercase(Line.Value) = 'ON' then
            LevelOptions := (LevelOptions or $02) and not $08;

        if Line.Keyword = 'WALKER' then
        begin
          SkillTypes := SkillTypes or $8000;
          WalkerCount := Line.Numeric;
        end;

        if Line.Keyword = 'CLIMBER' then
        begin
          SkillTypes := SkillTypes or $4000;
          ClimberCount := Line.Numeric;
        end;

        if Line.Keyword = 'SWIMMER' then
        begin
          SkillTypes := SkillTypes or $2000;
          SwimmerCount := Line.Numeric;
        end;

        if Line.Keyword = 'FLOATER' then
        begin
          SkillTypes := SkillTypes or $1000;
          FloaterCount := Line.Numeric;
        end;

        if Line.Keyword = 'GLIDER' then
        begin
          SkillTypes := SkillTypes or $0800;
          GliderCount := Line.Numeric;
        end;

        if Line.Keyword = 'DISARMER' then
        begin
          SkillTypes := SkillTypes or $0400;
          MechanicCount := Line.Numeric;
        end;

        if Line.Keyword = 'BOMBER' then
        begin
          SkillTypes := SkillTypes or $0200;
          BomberCount := Line.Numeric;
        end;

        if Line.Keyword = 'STONER' then
        begin
          SkillTypes := SkillTypes or $0100;
          StonerCount := Line.Numeric;
        end;

        if Line.Keyword = 'BLOCKER' then
        begin
          SkillTypes := SkillTypes or $0080;
          BlockerCount := Line.Numeric;
        end;

        if Line.Keyword = 'PLATFORMER' then
        begin
          SkillTypes := SkillTypes or $0040;
          PlatformerCount := Line.Numeric;
        end;

        if Line.Keyword = 'BUILDER' then
        begin
          SkillTypes := SkillTypes or $0020;
          BuilderCount := Line.Numeric;
        end;

        if Line.Keyword = 'STACKER' then
        begin
          SkillTypes := SkillTypes or $0010;
          StackerCount := Line.Numeric;
        end;

        if Line.Keyword = 'BASHER' then
        begin
          SkillTypes := SkillTypes or $0008;
          BasherCount := Line.Numeric;
        end;

        if Line.Keyword = 'MINER' then
        begin
          SkillTypes := SkillTypes or $0004;
          MinerCount := Line.Numeric;
        end;

        if Line.Keyword = 'DIGGER' then
        begin
          SkillTypes := SkillTypes or $0002;
          DiggerCount := Line.Numeric;
        end;

        if Line.Keyword = 'CLONER' then
        begin
          SkillTypes := SkillTypes or $0001;
          ClonerCount := Line.Numeric;
        end;

        if Line.Keyword = 'SPAWN' then
        begin
          SetLength(WindowOrder, Length(WindowOrder)+1);
          WindowOrder[Length(WindowOrder)-1] := Line.Numeric;
        end;
      end;

    until (NewPiece) or (Line.Keyword = '');

    repeat
      if Line.Keyword = 'OBJECT' then
      begin
        O := aLevel.InteractiveObjects.Add;
        repeat
          Line := Parser.NextLine;

          if Line.Keyword = 'SET' then
            O.GS := Lowercase(Line.Value);

          if Line.Keyword = 'PIECE' then
            O.Piece := Lowercase(Line.Value);

          if Line.Keyword = 'X' then
            O.Left := Line.Numeric;

          if Line.Keyword = 'Y' then
            O.Top := Line.Numeric;

          if Line.Keyword = 'L' then
            O.TarLev := Line.Numeric;

          if Line.Keyword = 'S' then
            O.Skill := Line.Numeric;

          if Line.Keyword = 'NO_OVERWRITE' then
            O.DrawingFlags := O.DrawingFlags or odf_NoOverwrite;

          if Line.Keyword = 'ONLY_ON_TERRAIN' then
            O.DrawingFlags := O.DrawingFlags or odf_OnlyOnTerrain;

          if Line.Keyword = 'FLIP_HORIZONTAL' then
            O.DrawingFlags := O.DrawingFlags or odf_Flip;

          if Line.Keyword = 'FLIP_VERTICAL' then
            O.DrawingFlags := O.DrawingFlags or odf_UpsideDown;

          if Line.Keyword = 'FACE_LEFT' then
            O.DrawingFlags := O.DrawingFlags or odf_FlipLem;

          if Line.Keyword = 'FAKE' then
            O.IsFake := true;

          if Line.Keyword = 'INVISIBLE' then
            O.DrawingFlags := O.DrawingFlags or odf_Invisible;

        until NewPiece;
      end;

      if Line.Keyword = 'TERRAIN' then
      begin
        T := aLevel.Terrains.Add;
        T.DrawingFlags := tdf_NoOneWay;
        repeat
          Line := Parser.NextLine;

          if Line.Keyword = 'SET' then
            T.GS := Lowercase(Line.Value);

          if Line.Keyword = 'PIECE' then
            T.Piece := Lowercase(Line.Value);

          if Line.Keyword = 'X' then
            T.Left := Line.Numeric;

          if Line.Keyword = 'Y' then
            T.Top := Line.Numeric;

          if Line.Keyword = 'NO_OVERWRITE' then
            T.DrawingFlags := T.DrawingFlags or tdf_NoOverwrite;

          if Line.Keyword = 'ERASE' then
            T.DrawingFlags := T.DrawingFlags or tdf_Erase;

          if Line.Keyword = 'ROTATE' then
            T.DrawingFlags := T.DrawingFlags or tdf_Rotate;

          if Line.Keyword = 'FLIP_HORIZONTAL' then
            T.DrawingFlags := T.DrawingFlags or tdf_Flip;

          if Line.Keyword = 'FLIP_VERTICAL' then
            T.DrawingFlags := T.DrawingFlags or tdf_Invert;

          if Line.Keyword = 'ONE_WAY' then
            T.DrawingFlags := T.DrawingFlags and not tdf_NoOneWay;

        until NewPiece;
      end;

      if Line.Keyword = 'AREA' then
      begin
        S := aLevel.Steels.Add;
        repeat
          Line := Parser.NextLine;

          if Line.Keyword = 'NEGATIVE_STEEL' then S.fType := 1;
          if Line.Keyword = 'ONE_WAY_LEFT' then S.fType := 2;
          if Line.Keyword = 'ONE_WAY_RIGHT' then S.fType := 3;
          if Line.Keyword = 'ONE_WAY_DOWN' then S.fType := 4;

          if Line.Keyword = 'X' then
            S.Left := Line.Numeric;

          if Line.Keyword = 'Y' then
            S.Top := Line.Numeric;

          if Line.Keyword = 'W' then
            S.Width := Line.Numeric;

          if Line.Keyword = 'H' then
            S.Height := Line.Numeric;

        until NewPiece;
      end;

    until Line.Keyword = '';
  finally
    Parser.Free;
  end;
end;

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
    Add('# NeoLemmix Level');
    Add('# Dumped from NeoLemmix Player V' + PVersion);
    Add;

    // Statics
    with aLevel.Info do
    begin
      Add('# Level info');
      Add(' TITLE ' + Title);
      Add(' AUTHOR ' + Author);
      if MusicFile <> '' then
        Add(' MUSIC ' + MusicFile);
      Add(' ID ' + IntToHex(LevelID, 8));
      Add;

      Add('# Level dimensions');
      Add(' WIDTH ' + IntToStr(Width));
      Add(' HEIGHT ' + IntToStr(Height));
      Add(' START_X ' + IntToStr(ScreenPosition));
      Add(' START_Y ' + IntToStr(ScreenYPosition));
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
      if (SkillTypes and $0400 <> 0) then Add('   DISARMER ' + IntToStr(MechanicCount));
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
        Add('  SET ' + O.GS);
        Add('  PIECE ' + O.Piece);
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
        Add('  PIECE ' + Info.VgaspecFile);
        Add('  X ' + IntToStr(Info.VgaspecX));
        Add('  Y ' + IntToStr(Info.VgaspecY));
        Add;
      end;

      for i := 0 to Terrains.Count-1 do
      begin
        T := Terrains[i];
        Add(' TERRAIN');
        Add('  SET ' + T.GS);
        Add('  PIECE ' + T.Piece);
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
      if (Steels.Count > 0) and ((Info.LevelOptions and $04) = 0) then
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
          Add;
        end;
      end;
    end;

    SL.SaveToStream(aStream);
  finally
    SL.Free;
  end;
end;

end.