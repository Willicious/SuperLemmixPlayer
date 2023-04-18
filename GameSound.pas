unit GameSound;

// Entire rewrite, as this is more efficient (or at least less tedious) than tidying up
// the existing unit.


// To load a sound:
//   SoundManager.LoadSoundFromFile(<path relative to "sound\" folder>);
//   (is also possible to load from streams, but this is mostly for backwards-compatible's use)
//
// To play a sound (if not already loaded, will attempt to load it):
//   SoundManager.PlaySound(<path relative to "sound\" folder>, <balance>);  -- -100 is fully left, 0 is center, +100 is fully right
//
// To unload all sounds except the default ones:
//   SoundManager.PurgeNonDefaultSounds;
//   (Currently, the sounds used by objects in official sets are included in the default sounds. Once backwards-compatible is a thing
//    of the past, this should be changed so that only game-wide sounds are considered default.)
//
// To load a music:
//   SoundManager.LoadMusicFromFile(<path relative to "music\" folder);
//   (this too can be loaded from streams. Only one music can be loaded at a time)
//
// To play or stop music:
//   SoundManager.PlayMusic;
//   SoundManager.StopMusic;
//
// This new sound manager will handle not loading music if music is muted. With that being said, it currently still loads the file
// into memory, but doesn't load it into BASS. This is to simplify integration into backwards-compatible; and it can be changed to
// not load the file at all once backwards-compatible is no longer a thing.

interface

uses
  Dialogs,
  Bass,
  LemTypes, // only uses AppPath in new-formats but uses other stuff from LemTypes in backwards-compatible
  LemStrings, Contnrs, Classes, SysUtils;

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

      procedure InternalPlaySound(aIndex: Integer; aBalance: Integer);
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadDefaultSounds;
      function LoadSoundFromFile(aName: String; aOrigin: TSoundEffectOrigin; aLoadPath: String = ''): Integer;
      function LoadSoundFromStream(aStream: TStream; aName: String; aOrigin: TSoundEffectOrigin): Integer;
      procedure PurgeNonDefaultSounds;
      procedure PurgePackSounds;

      procedure LoadMusicFromFile(aName: String);
      procedure LoadMusicFromStream(aStream: TStream; aName: String);

      procedure PlaySound(aName: String; aBalance: Integer = 0); // -100 = fully left, +100 = fully right
      procedure PlayPackSound(aName: String; aLoadPath: String; aBalance: Integer = 0);
      procedure PlayMusic;
      procedure StopMusic;
      procedure FreeMusic;

      function FindExtension(const aName: String; aIsMusic: Boolean): String; overload;
      function FindExtension(const aName: String; aBasePath: String; aIsMusic: Boolean): String; overload;
      function DoesSoundExist(const aName: String): Boolean;

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
  LAST_SOUND_EXT = '.mp3'; // anything beyond this entry can only be used for music, not sfx

implementation

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
    ShowMessage('BASS.DLL could not initialize. SuperLemmix will run but music and sound will not play.');
  end else begin
    ShowMessage('BASS.DLL not found. SuperLemmix will run but music and sound will not play.');
    fIsBassLoaded := false;
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
  fMusicPlaying := false;
  fMusicChannel := $FFFFFFFF;
  fMusicStream.Clear;
  fMusicName := '';
end;

procedure TSoundManager.ObtainMusicBassChannel;
begin
  if not fIsBassLoaded then Exit;

  Assert(fMusicChannel = $FFFFFFFF, 'TSoundManager.ObtainMusicBassChannel: A channel already exists!');
  fMusicChannel := BASS_StreamCreateFile(true, fMusicStream.Memory, 0, fMusicStream.Size, BASS_SAMPLE_LOOP);
  if fMusicChannel = 0 then // this means we have a module-based file
  begin
    fMusicChannel := BASS_MusicLoad(true, fMusicStream.Memory, 0, fMusicStream.Size, BASS_SAMPLE_LOOP, 0);
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_MUSIC_AMPLIFY, fMusicVolume / 2);
  end else begin
    BASS_LoadLoopData(fMusicChannel); // yay, this was added to the BASS unit rather than GameSound
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_VOL, (fMusicVolume / 100));
  end;
end;

//procedure TSoundManager.AdjustPitch(aValue: Integer);
//begin
  //BASS_ChannelSetAttribute({sound channel goes here}, BASS_ATTRIB_FREQ, 0.25: Single);
//end;      //bookmark - this needs to adjust pitch

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
    BasePath := AppPath + SFMusic
  else
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
  BasePath: String;
begin
  Result := FindSoundIndex(aName);

  if Result <> -1 then
    Exit;

  if aLoadPath = '' then
    BasePath := AppPath + SFSounds
  else
    BasePath := aLoadPath;

  Ext := FindExtension(aName, BasePath, false);

  if Ext = '' then
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

procedure TSoundManager.LoadDefaultSounds;
  procedure Get(aName: String);
  begin
    LoadSoundFromFile(aName, seoDefault);
  end;
begin
  if not fIsBassLoaded then Exit;

  Get('boop');
  Get('chain');
  Get('changeop');
  Get('chink');
  Get('die');
  Get('door');
  Get('electric');
  Get('explode');
  Get('fire');
  Get('glug');
  Get('letsgo');
  Get('mousepre');
  Get('ohno');
  Get('oing');
  Get('oing2');
  Get('slurp');
  Get('splash');
  Get('splat');
  Get('tenton');
  Get('thud');
  Get('thunk');
  Get('timeup');
  Get('ting');
  Get('vacuusux');
  Get('weedgulp');
  Get('wrench');
  Get('yippee');
  Get('zombie');
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
    Result := false
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

procedure TSoundManager.LoadMusicFromFile(aName: String);
var
  F: TFileStream;
  Ext: String;
begin
  if not fIsBassLoaded then Exit;

  aName := Lowercase(aName);
  if fMusicName = aName then Exit; // saves some time

  Ext := FindExtension(aName, true);
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
  if fMusicName = aName then Exit; // saves some time

  FreeMusic;
  fMusicStream.Clear;

  fMusicStream.LoadFromStream(aStream);
  if not fMuteMusic then
    ObtainMusicBassChannel;
end;

procedure TSoundManager.PlayMusic;
begin
  if not fIsBassLoaded then Exit;

  fMusicPlaying := true;

  if fMuteMusic then
    Exit;

  if fMusicChannel = $FFFFFFFF then
    ObtainMusicBassChannel;

  BASS_ChannelPlay(fMusicChannel, false);
end;

procedure TSoundManager.StopMusic;
begin
  if not fIsBassLoaded then Exit;

  fMusicPlaying := false;
  BASS_ChannelStop(fMusicChannel);
end;

procedure TSoundManager.PlaySound(aName: String; aBalance: Integer = 0);
var
  SoundIndex: Integer;
begin
  if not fIsBassLoaded then Exit;

  if fMuteSound then Exit;
  SoundIndex := FindSoundIndex(aName);

  if SoundIndex = -1 then
    SoundIndex := LoadSoundFromFile(aName, seoStyle);

  InternalPlaySound(SoundIndex, aBalance);
end;

procedure TSoundManager.PlayPackSound(aName, aLoadPath: String; aBalance: Integer = 0);
var
  SoundIndex: Integer;
begin
  if not fIsBassLoaded then Exit;

  if fMuteSound then Exit;
  SoundIndex := FindSoundIndex(aName);

  if SoundIndex = -1 then
    SoundIndex := LoadSoundFromFile(aName, seoPack, aLoadPath);

  InternalPlaySound(SoundIndex, aBalance);
end;

procedure TSoundManager.InternalPlaySound(aIndex: Integer; aBalance: Integer);
var
  SampleChannel: LongWord;
begin
  if aBalance < -100 then aBalance := -100;
  if aBalance > 100 then aBalance := 100;

  if aIndex <> -1 then
  begin
    SampleChannel := BASS_SampleGetChannel(fSoundEffects[aIndex].BassSample, true);
    if aBalance <> 0 then
      BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_PAN, (aBalance / 100));
    BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_VOL, (fSoundVolume / 100));
    BASS_ChannelPlay(SampleChannel, true);
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
  fBassSample := BASS_SampleLoad(true, fStream.Memory, 0, fStream.Size, 65535, 0);
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
  aOwnsObjects := true;
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
