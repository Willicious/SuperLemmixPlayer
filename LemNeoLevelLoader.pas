unit LemNeoLevelLoader;

interface

uses
  LemNeoParser,
  LemTerrain, LemInteractiveObject, LemSteel, LemLemming,
  LemLevel, {LemStrings,} LemVersion,
  Classes, SysUtils, StrUtils;

type
  TNeoLevelLoader = class
    private
      class procedure SanitizeInput(aLevel: TLevel);
    public
      class procedure LoadLevelFromStream(aStream: TStream; aLevel: TLevel);
      class procedure StoreLevelInStream(aLevel: TLevel; aStream: TStream);
  end;

implementation

class procedure TNeoLevelLoader.LoadLevelFromStream(aStream: TStream; aLevel: TLevel);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  O: TInteractiveObject;
  T: TTerrain;
  S: TSteel;
  L: TPreplacedLemming;

  function NewPiece: Boolean;
  begin
    Result := false;
    if Line.Keyword = 'OBJECT' then Result := true;
    if Line.Keyword = 'TERRAIN' then Result := true;
    if Line.Keyword = 'AREA' then Result := true;
    if Line.Keyword = 'LEMMING' then Result := true;
    if Line.Keyword = '' then Result := true; // Detect end of file as well
  end;

begin
  aLevel.ClearLevel;
  aLevel.Info.TimeLimit := 6000; // Default should be infinite, not 1 second
  aLevel.Info.LevelOptions := $02;
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
        begin
          ReleaseRate := Line.Numeric;
          ReleaseRateLocked := false;
        end;

        if Line.Keyword = 'FIXED_RR' then
        begin
          ReleaseRate := Line.Numeric;
          ReleaseRateLocked := true;
        end;

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

          if Line.Keyword = 'WIDTH' then
            O.Width := Line.Numeric;

          if Line.Keyword = 'HEIGHT' then
            O.Height := Line.Numeric;

          if Line.Keyword = 'L' then
            O.TarLev := Line.Numeric;

          if Line.Keyword = 'S' then
            O.Skill := Line.Numeric;

          if Line.Keyword = 'NO_OVERWRITE' then
            O.DrawingFlags := O.DrawingFlags or odf_NoOverwrite;

          if Line.Keyword = 'ONLY_ON_TERRAIN' then
            O.DrawingFlags := O.DrawingFlags or odf_OnlyOnTerrain;

          if Line.Keyword = 'ROTATE' then
            O.DrawingFlags := O.DrawingFlags or odf_Rotate;

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
        T.LoadFromParser(Parser);
        repeat
          Line := Parser.NextLine;
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

      if Line.Keyword = 'LEMMING' then
      begin
        L := aLevel.PreplacedLemmings.Add;
        repeat
          Line := Parser.NextLine;

          if Line.Keyword = 'X' then
            L.X := Line.Numeric;

          if Line.Keyword = 'Y' then
            L.Y := Line.Numeric;

          if Line.Keyword = 'FACE_LEFT' then
            L.Dx := -1;

          if Line.Keyword = 'CLIMBER' then
            L.IsClimber := true;

          if Line.Keyword = 'SWIMMER' then
            L.IsSwimmer := true;

          if Line.Keyword = 'FLOATER' then
            L.IsFloater := true;

          if Line.Keyword = 'GLIDER' then
            L.IsGlider := true;

          if Line.Keyword = 'DISARMER' then
            L.IsDisarmer := true;

          if Line.Keyword = 'BLOCKER' then
            L.IsBlocker := true;

          if Line.Keyword = 'ZOMBIE' then
            L.IsZombie := true;
        until NewPiece;
      end;

    until Line.Keyword = '';

    // Sanitize loaded level stats now
    SanitizeInput(aLevel);

  finally
    Parser.Free;
  end;
end;

class procedure TNeoLevelLoader.SanitizeInput(aLevel: TLevel);
begin
  with aLevel.Info do
  begin
    // Title: At most 32 characters
    if Length(Title) > 32 then Title := LeftStr(Title, 32);
    // Author: At most 16 characters
    if Length(Author) > 16 then Author := LeftStr(Author, 16);

    // Width of level: At least 320
    if Width < 320 then Width := 320;
    // Height of level: At least 160
    if Height < 160 then Height := 160;

    // Screen start: Between 0 and Widht-320 resp. Height-160
    if ScreenPosition < 0 then ScreenPosition := 0
    else if ScreenPosition > Width - 320 then ScreenPosition := Width - 320;

    if ScreenYPosition < 0 then ScreenYPosition := 0
    else if ScreenYPosition > Height - 160 then ScreenYPosition := Height - 160;

    // Lemmings: At least 0 lemmings
    // 0 lemmings is only allowed to let people spot their mistakes.
    if LemmingsCount < 0 then LemmingsCount := 0;

    // Requirement: At least 0 lemmings
    // Too hight requirements are only allowed to let people spot their mistakes.
    if RescueCount < 0 then RescueCount := 0;

    // Time Limit: Between 1 and 6000 (inclusive) (6000 = infinity)
    if TimeLimit < 1 then TimeLimit := 1
    else if TimeLimit > 6000 then TimeLimit := 6000;

    // Minimum RR is between 1 and 99
    if ReleaseRate < 1 then ReleaseRate := 1
    else if ReleaseRate > 99 then Releaserate := 99;

    // Skill Counts: Between 0 and 100 (inclusive) (100 = infinity)
    if WalkerCount < 0 then WalkerCount := 0
    else if WalkerCount > 100 then WalkerCount := 100;

    if ClimberCount < 0 then ClimberCount := 0
    else if ClimberCount > 100 then ClimberCount := 100;

    if SwimmerCount < 0 then SwimmerCount := 0
    else if SwimmerCount > 100 then SwimmerCount := 100;

    if FloaterCount < 0 then FloaterCount := 0
    else if FloaterCount > 100 then FloaterCount := 100;

    if GliderCount < 0 then GliderCount := 0
    else if GliderCount > 100 then GliderCount := 100;

    if MechanicCount < 0 then MechanicCount := 0
    else if MechanicCount > 100 then MechanicCount := 100;

    if BomberCount < 0 then BomberCount := 0
    else if BomberCount > 100 then BomberCount := 100;

    if BlockerCount < 0 then BlockerCount := 0
    else if BlockerCount > 100 then BlockerCount := 100;

    if PlatformerCount < 0 then PlatformerCount := 0
    else if PlatformerCount > 100 then PlatformerCount := 100;

    if BuilderCount < 0 then BuilderCount := 0
    else if BuilderCount > 100 then BuilderCount := 100;

    if StackerCount < 0 then StackerCount := 0
    else if StackerCount > 100 then StackerCount := 100;

    if BasherCount < 0 then BasherCount := 0
    else if BasherCount > 100 then BasherCount := 100;

    if MinerCount < 0 then MinerCount := 0
    else if MinerCount > 100 then MinerCount := 100;

    if DiggerCount < 0 then DiggerCount := 0
    else if DiggerCount > 100 then DiggerCount := 100;

    if ClonerCount < 0 then ClonerCount := 0
    else if ClonerCount > 100 then ClonerCount := 100;
  end;
end;



class procedure TNeoLevelLoader.StoreLevelInStream(aLevel: TLevel; aStream: TStream);
var
  SL: TStringList;
  i: Integer;
  O: TInteractiveObject;
  T: TTerrain;
  S: TSteel;
  L: TPreplacedLemming;

  procedure Add(const aString: String = '');
  begin
    SL.Add(aString);
  end;
begin
  SL := TStringList.Create;
  try
    Add('# NeoLemmix Level');
    Add('# Dumped from NeoLemmix Player V' + CurrentVersionString);
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
      if ReleaseRateLocked then
        Add(' FIXED_RR ' + IntToStr(ReleaseRate))
      else
        Add(' MIN_RR ' + IntToStr(ReleaseRate));
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
        if O.Width <> -1 then
          Add('  WIDTH ' + IntToStr(O.Width));
        if O.Height <> -1 then
          Add('  HEIGHT ' + IntToStr(O.Height));
        if O.TarLev <> 0 then Add('  L ' + IntToStr(O.TarLev));
        if O.Skill <> 0 then Add('  S ' + IntToStr(O.Skill));
        if O.DrawingFlags and odf_NoOverwrite <> 0 then
          Add('  NO_OVERWRITE');
        if O.DrawingFlags and odf_OnlyOnTerrain <> 0 then
          Add('  ONLY_ON_TERRAIN');
        if O.DrawingFlags and odf_Rotate <> 0 then
          Add('  ROTATE');
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
          if T.DrawingFlags and tdf_NoOneWay = 0 then
            Add('  ONE_WAY');
        end else begin
          if T.DrawingFlags and tdf_NoOneWay <> 0 then
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

      // Preplaced lemmings
      if (PreplacedLemmings.Count > 0) then
      begin
        Add('# Preplaced lemmings');
        for i := 0 to PreplacedLemmings.Count-1 do
        begin
          L := PreplacedLemmings[i];
          Add(' LEMMING');
          Add('  X ' + IntToStr(L.X));
          Add('  Y ' + IntToStr(L.Y));
          if L.Dx < 0 then
            Add('  FACE_LEFT');
          if L.IsClimber then
            Add('  CLIMBER');
          if L.IsSwimmer then
            Add('  SWIMMER');
          if L.IsFloater then
            Add('  FLOATER');
          if L.IsGlider then
            Add('  GLIDER');
          if L.IsDisarmer then
            Add('  DISARMER');
          if L.IsBlocker then
            Add('  BLOCKER');
          if L.IsZombie then
            Add('  ZOMBIE');
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