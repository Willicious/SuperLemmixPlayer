unit LemNeoTheme;

{ A simple unit for management of themes. These are basically just the remnants
  of graphic sets onces the terrain and objects are taken out. They define which
  lemming graphics to use, and the key colors. }

interface

uses
  Dialogs,
  GR32,
  GameSound, LemTypes, LemStrings, PngInterface,
  StrUtils, Classes, SysUtils,
  LemNeoParser,
  SharedGlobals;

const
  MASK_COLOR = 'mask';
  MINIMAP_COLOR = 'minimap';
  BACKGROUND_COLOR = 'background';
  FALLBACK_COLOR = MASK_COLOR;

  DEFAULT_COLOR = $FF888888;

type
  TNeoThemeColor = record
    Name: String;
    Color: TColor32;
  end;

  TNeoTheme = class
    private
      fName: String;
      fLemmings: String; // Which lemming graphics to use
      fLemNamesPlural: String; // What to call the lemmings in menu screens
      fLemNamesSingular: String;
      fExitMarkerFrames: Integer;
      fColors: array of TNeoThemeColor;

      fSoundsSetFromTheme: Boolean;
      fMissingSoundsList: TStringList;
      fSpriteFallbackMessage: String;

      function GetColor(Name: String): TColor32;
      function FindColorIndex(Name: String): Integer;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure Load(aSet: String);

      procedure SetSoundsFromTheme(aName: String; aSound: String);
      procedure ValidateThemeSounds(aSection: TParserSection);
      function DoesColorExist(Name: String): Boolean;

      property Name: String read fName write fName;
      property Lemmings: String read fLemmings write fLemmings;
      property LemNamesPlural: String read fLemNamesPlural write fLemNamesPlural;
      property LemNamesSingular: String read fLemNamesSingular write fLemNamesSingular;
      property ExitMarkerFrames: Integer read fExitMarkerFrames write fExitMarkerFrames;
      property Colors[Name: String]: TColor32 read GetColor;
      property SoundsSetFromTheme: Boolean read fSoundsSetFromTheme write fSoundsSetFromTheme;
      property MissingSoundsList: TStringList read fMissingSoundsList write fMissingSoundsList;
      property SpriteFallbackMessage: String read fSpriteFallbackMessage write fSpriteFallbackMessage;
  end;

implementation

constructor TNeoTheme.Create;
begin
  inherited;
  MissingSoundsList := TStringList.Create;
  Clear;
end;

destructor TNeoTheme.Destroy;
begin
  MissingSoundsList.Free;
  inherited;
end;

function TNeoTheme.DoesColorExist(Name: String): Boolean;
begin
  Result := FindColorIndex(Name) >= 0;
end;

procedure TNeoTheme.Clear;
begin
  fLemmings := 'default';
  SetLength(fColors, 0);
  MissingSoundsList.Clear;
  SpriteFallbackMessage := '';
end;

procedure TNeoTheme.Load(aSet: String);
var
  Parser: TParser;
  Sec: TParserSection;
  i: Integer;
begin
  Clear;
  SetCurrentDir(AppPath + SFStyles + aSet + '\');
  if not FileExists('theme.nxtm') then Exit;

  fName := aSet;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile('theme.nxtm');

    fLemmings := Parser.MainSection.LineString['lemmings'];
    if fLemmings = '' then fLemmings := 'default';

    fLemNamesPlural := Parser.MainSection.LineString['names_plural'];
    if fLemNamesPlural = '' then fLemNamesPlural := 'Lemmings';

    fLemNamesSingular := Parser.MainSection.LineString['names_singular'];
    if fLemNamesSingular = '' then fLemNamesSingular := 'Lemming';

    fExitMarkerFrames := Parser.MainSection.LineNumeric['exit_marker_frames'];

    Sec := Parser.MainSection.Section['colors'];
    if Sec = nil then
      SetLength(fColors, 0)
    else begin
      SetLength(fColors, Sec.LineList.Count);
      for i := 0 to Sec.LineList.Count-1 do
      begin
        fColors[i].Name := Sec.LineList[i].Keyword;
        fColors[i].Color := Sec.LineList[i].ValueNumeric or $FF000000;
      end;
    end;

    Sec := Parser.MainSection.Section['sounds'];
    if Sec = nil then
      SoundManager.GetDefaultSounds
    else
      ValidateThemeSounds(Sec);
  finally
    Parser.Free;
  end;
end;

procedure TNeoTheme.ValidateThemeSounds(aSection: TParserSection);
var
  Name, Sound: String;
  i: Integer;
begin
  for i := 0 to aSection.LineList.Count - 1 do
  begin
    Name := UpperCase(Trim(aSection.LineList[i].Keyword));
    Sound := Trim(aSection.LineList[i].Value);
    if not SoundManager.ValidateSoundFile(Sound) then
    begin
      MissingSoundsList.Add(UpperCase(Name) + ' ' + '[ ' + Sound + ' ]');
      SoundManager.GetDefaultSounds;
    end else begin
      SetSoundsFromTheme(Name, Sound);
      SoundsSetFromTheme := True;
    end;
  end;
end;

procedure TNeoTheme.SetSoundsFromTheme(aName: String; aSound: String);
begin
  if (aName = 'ASSIGN_FAIL') then SFX_AssignFail := aSound;
  if (aName = 'ASSIGN_SKILL') then SFX_AssignSkill := aSound;

//  if (aName = 'BAT_HIT') then  SFX_BatHit := aSound     // Batter
//  if (aName = 'BAT_SWISH') then  SFX_BatSwish := aSound // Batter

  if (aName = 'BALLOON_INFLATE') then SFX_BalloonInflate := aSound;
  if (aName = 'BALLOON_POP') then SFX_BalloonPop := aSound;
  if (aName = 'MENU_QUIT') then SFX_Bye := aSound;
  if (aName = 'EXIT') then SFX_Boing := aSound;
  if (aName = 'BRICK') then SFX_Brick := aSound;
  if (aName = 'COLLECT') then SFX_Collect := aSound;
  if (aName = 'COLLECT_ALL') then SFX_CollectAll := aSound;
  if (aName = 'DISARM_TRAP') then SFX_DisarmTrap := aSound;
  if (aName = 'DROWN') then SFX_Drown := aSound;
  if (aName = 'ENTRANCE') then SFX_Entrance := aSound;
  if (aName = 'EXIT_UNLOCK') then SFX_ExitUnlock := aSound;
  if (aName = 'FALL_OFF') then SFX_FallOff := aSound;
  if (aName = 'FIRE') then SFX_Fire := aSound;
  if (aName = 'FREEZE') then SFX_Freeze := aSound;
  if (aName = 'GRENADE_THROW') then SFX_GrenadeThrow := aSound;
  if (aName = 'JUMP') then SFX_Jump := aSound;
  if (aName = 'LASER') then SFX_Laser := aSound;
  if (aName = 'LETS_GO') then SFX_LetsGo := aSound;
  if (aName = 'OH_NO') then SFX_OhNo := aSound;
  if (aName = 'MENU_OK') then SFX_OK := aSound;
  if (aName = 'PICKUP') then SFX_Pickup := aSound;
  if (aName = 'EXPLODE') then SFX_Pop := aSound;

  //SFX_Propeller := aSound;  Propeller

  if (aName = 'RELEASE_RATE') then SFX_ReleaseRate := aSound;
  if (aName = 'SKILL_BUTTON') then SFX_SkillButton := aSound;
  if (aName = 'SPEAR_HIT') then SFX_SpearHit := aSound;
  if (aName = 'SPEAR_THROW') then SFX_SpearThrow := aSound;
  if (aName = 'SPLAT') then SFX_Splat := aSound;
  if (aName = 'STEEL_OWW') then SFX_Steel_OWW := aSound;
  if (aName = 'SWIM') then SFX_Swim := aSound;
  if (aName = 'TIME_UP') then SFX_TimeUp := aSound;
  if (aName = 'VINETRAP') then SFX_Vinetrap := aSound;
  if (aName = 'EXIT') then SFX_Yippee := aSound;
  if (aName = 'ZOMBIE') then SFX_Zombie := aSound;
  if (aName = 'ZOMBIE_FALL_OFF') then SFX_ZombieFallOff := aSound;
  if (aName = 'ZOMBIE_OH_NO') then SFX_ZombieOhNo := aSound;
  if (aName = 'ZOMBIE_PICKUP') then SFX_ZombiePickup := aSound;
  if (aName = 'ZOMBIE_SPLAT') then SFX_ZombieSplat := aSound;
  if (aName = 'ZOMBIE_EXIT') then SFX_ZombieExit := aSound;
end;

function TNeoTheme.GetColor(Name: String): TColor32;
var
  i: Integer;
begin
  i := FindColorIndex(Name);

  // Special exception
  if (i = -1) and (Lowercase(Name) = BACKGROUND_COLOR) then
  begin
    Result := $FF000000;
    Exit;
  end;

  if i = -1 then i := FindColorIndex(FALLBACK_COLOR);

  if i = -1 then
    Result := DEFAULT_COLOR
  else
    Result := fColors[i].Color;
end;

function TNeoTheme.FindColorIndex(Name: String): Integer;
begin
  Name := Lowercase(Name);
  for Result := 0 to Length(fColors)-1 do
    if Name = fColors[Result].Name then Exit;
  Result := -1;
end;

end.