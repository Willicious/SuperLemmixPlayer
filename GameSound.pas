unit GameSound;

// Entire rewrite, as this is more efficient (or at least less tedious) than tidying up the existing unit.


{ To load a sound:
   SoundManager.LoadSoundFromFile(<path relative to "sounds\" folder>);
      (it'ss also possible to load from streams)

   As of SLX 2.8.5, it's now possible for sound files placed into a level pack to replace
   the default sounds on a per-pack basis.
   It's also possible to specify sounds per-theme using a style's theme.nxtm
      (see  TNeoTheme.ValidateThemeSounds and TNeoTheme.SetSoundsFromTheme ) }

{ To play a sound (if not already loaded, will attempt to load it):
   SoundManager.PlaySound(<path relative to "sounds\" folder>, <balance>);
   (For <balance>, -100 is fully left, 0 is center, +100 is fully right) }

{ To unload all sounds except the default ones:
   SoundManager.PurgeNonDefaultSounds; }

{ To load a music track:
   SoundManager.LoadMusicFromFile(<path relative to "music\" folder);
   (this too can be loaded from streams. Only one music track can be loaded at a time) }

   { To play or stop music:
   SoundManager.PlayMusic;
   SoundManager.StopMusic; }

   { This new sound manager will handle not loading music if music is muted. }

interface

uses
  Dialogs,
  Bass,
  LemTypes, // Only uses AppPath in new-formats but uses other stuff from LemTypes in backwards-compatible
  LemStrings, Contnrs, Classes, SysUtils,
  SharedGlobals;

type
  TSoundEffectOrigin = (seoStyle, seoDefault, seoPack);

  TSoundEffect = class
    private
      fName: String;
      fBassSample: LongWord;
      fStream: TMemoryStream;
      fOrigin: TSoundEffectOrigin;
      procedure FreeBassSample;
      procedure ObtainBassSample;
    public
      constructor Create;
      destructor Destroy; override;
      procedure LoadFromFile(aFile: String);
      procedure LoadFromStream(aStream: TStream; aName: String);

      property Name: String read fName;
      property BassSample: LongWord read fBassSample;
      property Origin: TSoundEffectOrigin read fOrigin write fOrigin;
  end;

  TSoundEffects = class(TObjectList)
    private
      function GetItem(Index: Integer): TSoundEffect;
    public
      constructor Create;
      function Add: TSoundEffect;
      property Items[Index: Integer]: TSoundEffect read GetItem; default;
      property List;
  end;

  TSoundManager = class
    private
      fSoundVolume: Integer;
      fMusicVolume: Integer;
      fMuteSound: Boolean;
      fMuteMusic: Boolean;

      fSoundEffects: TSoundEffects;

      fMusicName: String;
      fMusicStream: TMemoryStream;
      fMusicChannel: LongWord;
      fMusicPlaying: Boolean;

      fIsBassLoaded: Boolean;

      procedure ObtainMusicBassChannel;

      procedure SetSoundVolume(aValue: Integer);
      procedure SetMusicVolume(aValue: Integer);
      procedure SetMusicMute(aValue: Boolean);

      function FindSoundIndex(aName: String): Integer;

      procedure InternalPlaySound(aIndex: Integer; aBalance: Integer; aFrequency: Single);
    public
      constructor Create;
      destructor Destroy; override;

      procedure GetDefaultSounds;
      procedure LoadDefaultSounds;
      function LoadSoundFromFile(aName: String; aOrigin: TSoundEffectOrigin; aLoadPath: String = ''): Integer;
      function LoadSoundFromStream(aStream: TStream; aName: String; aOrigin: TSoundEffectOrigin): Integer;
      procedure PurgeNonDefaultSounds;
      procedure PurgePackSounds;
      procedure RemoveSoundFromStream(aName: String);

      procedure LoadMusicFromFile(aName: String);
      procedure LoadMusicFromStream(aStream: TStream; aName: String);

      procedure PlaySound(aName: String; aBalance: Integer = 0; aFrequency: Single = 0); // -100 = fully left, +100 = fully right
      procedure PlayMusic;
      procedure StopMusic;
      procedure FreeMusic;

      function FindExtension(const aName: String; aIsMusic: Boolean): String; overload;
      function FindExtension(const aName: String; aBasePath: String; aIsMusic: Boolean): String; overload;
      function DoesSoundExist(const aName: String): Boolean;
      function ValidateSoundFile(const aName: String): Boolean;

      property SoundVolume: Integer read fSoundVolume write SetSoundVolume;
      property MusicVolume: Integer read fMusicVolume write SetMusicVolume;
      property MuteSound: Boolean read fMuteSound write fMuteSound;
      property MuteMusic: Boolean read fMuteMusic write SetMusicMute;
  end;

var
  SoundManager: TSoundManager;

const
  VALID_AUDIO_EXTS: array[0..11] of string = (
                  '.ogg',
                  '.wav',
                  '.aiff',
                  '.aif',
                  '.mp3',
                  '.mo3',
                  '.it',
                  '.mod',
                  '.xm',
                  '.s3m',
                  '.mtm',
                  '.umx'
                  );
  LAST_SOUND_EXT = '.mp3'; // Anything beyond this entry can only be used for music, not sfx

implementation

uses
GameControl, LemNeoLevelPack;

(* --- TSoundManager --- *)

constructor TSoundManager.Create;
begin
  inherited;
  fSoundEffects := TSoundEffects.Create;
  fMusicStream := TMemoryStream.Create;
  fMusicChannel := $FFFFFFFF;

  if FileExists(AppPath + 'bass.dll') then
  begin
    Load_BASSDLL(AppPath + 'bass.dll');
    fIsBassLoaded := BASS_Init(-1, 44100, BASS_DEVICE_NOSPEAKER, 0, nil);
    if not fIsBassLoaded then
    ShowMessage('BASS.DLL could not initialize. SuperLemmix will run but music and sound will not play.'
                + #13#10 + 'Please try restarting SuperLemmix to fix this issue.');
  end else begin
    ShowMessage('BASS.DLL not found. SuperLemmix will run but music and sound will not play.');
    fIsBassLoaded := False;
  end;
end;

destructor TSoundManager.Destroy;
begin
  FreeMusic;
  fMusicStream.Free;
  fSoundEffects.Free;
  if fIsBassLoaded then
  begin
    BASS_Free;
    Unload_BASSDLL;
  end;
  inherited;
end;

procedure TSoundManager.FreeMusic;
begin
  if not fIsBassLoaded then Exit;
  if fMusicChannel = $FFFFFFFF then Exit;
  BASS_StreamFree(fMusicChannel);
  fMusicPlaying := False;
  fMusicChannel := $FFFFFFFF;
  fMusicStream.Clear;
  fMusicName := '';
end;

procedure TSoundManager.ObtainMusicBassChannel;
begin
  if not fIsBassLoaded then Exit;

  CustomAssert(fMusicChannel = $FFFFFFFF, 'TSoundManager.ObtainMusicBassChannel: A channel already exists!');

  fMusicChannel := BASS_StreamCreateFile(True, fMusicStream.Memory, 0, fMusicStream.Size, BASS_SAMPLE_LOOP);

  if fMusicChannel = 0 then // This means we have a module-based file
  begin
    fMusicChannel := BASS_MusicLoad(True, fMusicStream.Memory, 0, fMusicStream.Size, BASS_SAMPLE_LOOP, 0);
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_MUSIC_AMPLIFY, fMusicVolume / 2);
  end else begin
    BASS_LoadLoopData(fMusicChannel); // Yay, this was added to the BASS unit rather than GameSound
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_VOL, (fMusicVolume / 100));
  end;
end;

procedure TSoundManager.SetSoundVolume(aValue: Integer);
begin
  if aValue < 0 then aValue := 0;
  if aValue > 100 then aValue := 100;
  fSoundVolume := aValue;
end;

procedure TSoundManager.SetMusicVolume(aValue: Integer);
begin
  if aValue < 0 then aValue := 0;
  if aValue > 100 then aValue := 100;
  fMusicVolume := aValue;
  if not fIsBassLoaded then Exit;
  if fMusicChannel = $FFFFFFFF then Exit;
  BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_VOL, (fMusicVolume / 100));
  BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_MUSIC_AMPLIFY, fMusicVolume / 2);
end;

procedure TSoundManager.SetMusicMute(aValue: Boolean);
begin
  fMuteMusic := aValue;
  if not fIsBassLoaded then Exit;
  if fMuteMusic then
  begin
    if fMusicChannel <> $FFFFFFFF then
      BASS_ChannelStop(fMusicChannel);
  end else if fMusicPlaying then
    PlayMusic;
end;

function TSoundManager.FindExtension(const aName: String; aIsMusic: Boolean): String;
var
  BasePath: String;
begin
  if aIsMusic then
  begin
    BasePath := AppPath + SFMusic;
  end else
    BasePath := AppPath + SFSounds;

  Result := FindExtension(aName, BasePath, aIsMusic);
end;

function TSoundManager.FindExtension(const aName: String; aBasePath: String; aIsMusic: Boolean): String;
var
  i: Integer;
  LocalName: String;
begin
  Result := '';
  LocalName := ChangeFileExt(aName, '');

  for i := 0 to Length(VALID_AUDIO_EXTS) - 1 do
    if FileExists(aBasePath + LocalName + VALID_AUDIO_EXTS[i]) then
    begin
      Result := VALID_AUDIO_EXTS[i];
      Exit;
    end else if (not aIsMusic) and (VALID_AUDIO_EXTS[i] = LAST_SOUND_EXT) then
      Exit;
end;

function TSoundManager.LoadSoundFromFile(aName: String; aOrigin: TSoundEffectOrigin; aLoadPath: String = ''): Integer;
var
  F: TFileStream;
  Ext: String;
  BasePath, PackPath: String;
begin
  Result := -1;

  BasePath := '';
  PackPath := '';

  if (GameParams <> nil) then
  begin
    // Try loading from level pack first
    PackPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

    Ext := FindExtension(aName, PackPath, False);

    if (Ext <> '') then
    begin
      // Remove existing loaded sound so it can be replaced
      RemoveSoundFromStream(aName);
      BasePath := PackPath;
      aOrigin := seoPack;
    end;
  end;

  Result := FindSoundIndex(aName);

  // Don't reload already-loaded sounds
  if Result <> -1 then
    Exit;

  // Load from default sounds if no files are found in the level pack
  if (BasePath = '') then
    BasePath := AppPath + SFSounds
  else if (aLoadPath <> '') then
    BasePath := aLoadPath;

  Ext := FindExtension(aName, BasePath, False);

  if (Ext = '') then
    Exit;

  F := TFileStream.Create(BasePath + aName + Ext, fmOpenRead);
  try
    Result := LoadSoundFromStream(F, aName, aOrigin);
  finally
    F.Free;
  end;
end;

function TSoundManager.LoadSoundFromStream(aStream: TStream; aName: String; aOrigin: TSoundEffectOrigin): Integer;
begin
  if not fIsBassLoaded then
  begin
    Result := -1;
    Exit;
  end;

  Result := FindSoundIndex(aName);

  if Result <> -1 then
    Exit;

  Result := fSoundEffects.Count;

  with fSoundEffects.Add do
  begin
    LoadFromStream(aStream, aName);
    Origin := aOrigin;
  end;
end;

procedure TSoundManager.GetDefaultSounds;
begin
  SFX_AmigaDisk1 := 'amigadisk1';
  SFX_AmigaDisk2 := 'amigadisk2';
  SFX_AssignFail := 'assignfail';
  SFX_AssignSkill := 'assignskill';
  // SFX_BatHit = 'bathit';      // Batter
  // SFX_BatSwish = 'batswish';   // Batter
  SFX_BalloonInflate := 'balloon';
  SFX_BalloonPop := 'balloonpop';
  SFX_Boing := 'boing';
  SFX_Boop := 'boop';
  SFX_Brick := 'brick';
  SFX_Bye := 'bye';
  SFX_Collect := 'collect';
  SFX_CollectAll := 'applause';
  SFX_DisarmTrap := 'wrench';
  SFX_Drown := 'glug';
  SFX_Entrance := 'door';
  SFX_ExitUnlock := 'exitunlock';
  SFX_FailureJingle := 'failure';
  SFX_FallOff := 'falloff';
  SFX_Fire := 'fire';
  SFX_Freeze := 'ice';
  SFX_GrenadeThrow := 'grenade';
  SFX_Jump := 'jump';
  SFX_Laser := 'laser';
  SFX_LetsGo := 'letsgo';
  SFX_Normalize := 'normalize';
  SFX_OhNo := 'ohno';
  SFX_OK := 'OK';
  SFX_Pickup := 'pickup';
  SFX_Pop := 'pop';
  SFX_Portal := 'portal';
  // SFX_Propeller := 'propeller'; // Propeller
  SFX_ReleaseRate := 'changerr';
  SFX_SuccessJingle := 'success';
  SFX_SkillButton := 'changeskill';
  SFX_SpearHit := 'spearhit';
  SFX_SpearThrow := 'spearthrow';
  SFX_Splat := 'splat';
  SFX_Steel_OWW := 'clink';
  SFX_Swim := 'splash';
  SFX_TimeUp := 'timeup';
  SFX_Vinetrap := 'vinetrap';
  SFX_Yippee := 'Yippee';
  SFX_Zombie := 'zombie';
  SFX_ZombieFallOff := 'zombiefalloff';
  SFX_ZombieOhNo := 'zombieohno';
  SFX_ZombiePickup := 'zombiepickup';
  SFX_ZombieSplat := 'zombiesplat';
  SFX_ZombieExit := 'zombieyippee';
end;

procedure TSoundManager.LoadDefaultSounds;
  procedure Load(aName: String);
  begin
    LoadSoundFromFile(aName, seoDefault);
  end;
begin
  if not fIsBassLoaded then Exit;

  GetDefaultSounds;

  Load(SFX_AmigaDisk1);
  Load(SFX_AmigaDisk2);
  Load(SFX_AssignFail);
  Load(SFX_AssignSkill);
  // Load(SFX_BatHit);   // Batter
  // Load(SFX_BatSwish); // Batter
  Load(SFX_BalloonInflate);
  Load(SFX_BalloonPop);
  Load(SFX_Boing);
  Load(SFX_Boop);
  Load(SFX_Brick);
  Load(SFX_Bye);
  Load(SFX_Collect);
  Load(SFX_CollectAll);
  Load(SFX_DisarmTrap);
  Load(SFX_Drown);
  Load(SFX_Entrance);
  Load(SFX_ExitUnlock);
  Load(SFX_FailureJingle);
  Load(SFX_FallOff);
  Load(SFX_Fire);
  Load(SFX_Freeze);
  Load(SFX_GrenadeThrow);
  Load(SFX_Jump);
  Load(SFX_Laser);
  Load(SFX_LetsGo);
  Load(SFX_Normalize);
  Load(SFX_OhNo);
  Load(SFX_OK);
  Load(SFX_Pickup);
  Load(SFX_Pop);
  Load(SFX_Portal);
  // Load(SFX_Propeller); // Propeller
  Load(SFX_ReleaseRate);
  Load(SFX_SuccessJingle);
  Load(SFX_SkillButton);
  Load(SFX_SpearHit);
  Load(SFX_SpearThrow);
  Load(SFX_Splat);
  Load(SFX_Steel_OWW);
  Load(SFX_Swim);
  Load(SFX_TimeUp);
  Load(SFX_Vinetrap);
  Load(SFX_Yippee);
  Load(SFX_Zombie);
  Load(SFX_ZombieFallOff);
  Load(SFX_ZombieOhNo);
  Load(SFX_ZombiePickup);
  Load(SFX_ZombieSplat);
  Load(SFX_ZombieExit);
end;

function TSoundManager.FindSoundIndex(aName: String): Integer;
begin
  Result := -1;
  if not fIsBassLoaded then Exit;
  aName := Lowercase(aName);
  for Result := 0 to fSoundEffects.Count-1 do
    if fSoundEffects[Result].Name = aName then
      Exit;
  Result := -1;
end;

function TSoundManager.DoesSoundExist(const aName: String): Boolean;
begin
  if not fIsBassLoaded then
    Result := False
  else
    Result := FindSoundIndex(aName) <> -1;
end;

procedure TSoundManager.PurgeNonDefaultSounds;
var
  i: Integer;
begin
  if not fIsBassLoaded then Exit;

  for i := fSoundEffects.Count-1 downto 0 do
    if fSoundEffects[i].Origin <> seoDefault then
      fSoundEffects.Delete(i);
end;

procedure TSoundManager.PurgePackSounds;
var
  i: Integer;
begin
  if not fIsBassLoaded then Exit;

  for i := fSoundEffects.Count-1 downto 0 do
    if fSoundEffects[i].Origin = seoPack then
      fSoundEffects.Delete(i);
end;

procedure TSoundManager.RemoveSoundFromStream(aName: String);
var
  i: Integer;
begin
  if not fIsBassLoaded then Exit;

  for i := fSoundEffects.Count-1 downto 0 do
  if fSoundEffects[i].Name = aName then
    fSoundEffects.Delete(i);
end;

procedure TSoundManager.LoadMusicFromFile(aName: String);
var
  F: TFileStream;
  Ext: String;
begin
  if not fIsBassLoaded then Exit;

  aName := Lowercase(aName);
  if fMusicName = aName then Exit; // Saves some time

  Ext := FindExtension(aName, True);
  if Ext = '' then
  begin
    FreeMusic;
    Exit;
  end;

  F := TFileStream.Create(AppPath + SFMusic + aName + Ext, fmOpenRead);
  try
    LoadMusicFromStream(F, aName);
  finally
    F.Free;
  end;
end;

procedure TSoundManager.LoadMusicFromStream(aStream: TStream; aName: String);
begin
  if not fIsBassLoaded then Exit;

  aName := Lowercase(aName);
  if fMusicName = aName then Exit; // Saves some time

  FreeMusic;
  fMusicStream.Clear;

  fMusicStream.LoadFromStream(aStream);
  if not fMuteMusic then
    ObtainMusicBassChannel;
end;

procedure TSoundManager.PlayMusic;
begin
  if not fIsBassLoaded then Exit;

  fMusicPlaying := True;

  if fMuteMusic then
    Exit;

  if fMusicChannel = $FFFFFFFF then
    ObtainMusicBassChannel;

  BASS_ChannelPlay(fMusicChannel, False);
end;

procedure TSoundManager.StopMusic;
begin
  if not fIsBassLoaded then Exit;

  fMusicPlaying := False;
  BASS_ChannelStop(fMusicChannel);
end;

function TSoundManager.ValidateSoundFile(const aName: String): Boolean;
begin
  Result := False or (LoadSoundFromFile(aName, seoStyle) <> -1);
end;

procedure TSoundManager.PlaySound(aName: String; aBalance: Integer = 0; aFrequency: Single = 0);
var
  SoundIndex: Integer;
begin
  if not fIsBassLoaded then Exit;

  if fMuteSound then Exit;
  SoundIndex := FindSoundIndex(aName);

  if SoundIndex = -1 then
    SoundIndex := LoadSoundFromFile(aName, seoStyle);

  InternalPlaySound(SoundIndex, aBalance, aFrequency);
end;

procedure TSoundManager.InternalPlaySound(aIndex: Integer; aBalance: Integer; aFrequency: Single);
var
  SampleChannel: LongWord;
  tmpFrequency: Single;
begin
  if aBalance < -100 then aBalance := -100;
  if aBalance > 100 then aBalance := 100;

  if aIndex <> -1 then
  begin
    SampleChannel := BASS_SampleGetChannel(fSoundEffects[aIndex].BassSample, True);

    if aBalance <> 0 then
      BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_PAN, (aBalance / 100));
      BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_VOL, (fSoundVolume / 100));

    if aFrequency <> 0 then
    begin
      BASS_ChannelGetAttribute(SampleChannel, BASS_ATTRIB_FREQ, tmpFrequency);
      BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_FREQ, aFrequency);
    end;

    BASS_ChannelPlay(SampleChannel, True);
  end;
end;

(* --- TSoundEffect --- *)

constructor TSoundEffect.Create;
begin
  inherited;
  fBassSample := $FFFFFFFF;
  fStream := TMemoryStream.Create;
end;

destructor TSoundEffect.Destroy;
begin
  FreeBassSample;
  fStream.Free;
  inherited;
end;

procedure TSoundEffect.FreeBassSample;
begin
  if fBassSample = $FFFFFFFF then Exit;
  BASS_SampleFree(fBassSample);
  fBassSample := $FFFFFFFF;
end;

procedure TSoundEffect.ObtainBassSample;
begin
  FreeBassSample;
  fBassSample := BASS_SampleLoad(True, fStream.Memory, 0, fStream.Size, 65535, 0);
end;

procedure TSoundEffect.LoadFromFile(aFile: String);
var
  F: TFileStream;
  SoundName: String;
begin
  F := TFileStream.Create(aFile, fmOpenRead);
  try
    SoundName := ExtractFileName(aFile);
    SoundName := ChangeFileExt(aFile, '');
    LoadFromStream(F, SoundName);
  finally
    F.Free;
  end;
end;

procedure TSoundEffect.LoadFromStream(aStream: TStream; aName: String);
begin
  fStream.Clear;
  fStream.LoadFromStream(aStream);
  fName := Lowercase(aName);
  ObtainBassSample;
end;

(* --- TSoundEffects --- *)

constructor TSoundEffects.Create;
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := True;
  inherited Create(aOwnsObjects);
end;

function TSoundEffects.Add: TSoundEffect;
begin
  Result := TSoundEffect.Create;
  inherited Add(Result);
end;

function TSoundEffects.GetItem(Index: Integer): TSoundEffect;
begin
  Result := inherited Get(Index);
end;

end.
