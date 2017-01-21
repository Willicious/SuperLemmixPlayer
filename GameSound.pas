unit GameSoundNew;

// Entire rewrite, as this is more efficient (or at least less tedious) than tidying up
// the existing unit.

// NOTE: NOT YET TESTED. But it should work. Will test during integration into NL's code.

// USAGE:   (note to Nepster: unless you just want something to do, just leave it to me to integrate this)
//
// Need to add these lines to AppController or somewhere similar:
//   SoundManager := TSoundManager.Create;
//   SoundManager.LoadDefaultSounds;
//
// To load a sound:
//   SoundManager.LoadSoundFromFile(<path relative to "sound\" folder>);
//   (is also possible to load from streams, but this is mostly for backwards-compatible's use)
//
// To play a sound (must be loaded first):
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


// TODO: Instead of playing nothing when a non-loaded sound is attempted to be played, try to load the sound. This will be very
//       hard to integrate into backwards-compatible so maybe this should be left until backwards-compatible is no more.

interface

uses
  Bass,
  LemTypes, // only uses AppPath in new-formats but uses other stuff from LemTypes in backwards-compatible
  LemStrings, Contnrs, Classes, SysUtils;

type
  TSoundEffect = class
    private
      fName: String;
      fBassSample: LongWord;
      fStream: TMemoryStream;
      fIsDefaultSound: Boolean;
      procedure FreeBassSample;
      procedure ObtainBassSample;
    public
      constructor Create;
      destructor Destroy; override;
      procedure LoadFromFile(aFile: String);
      procedure LoadFromStream(aStream: TStream; aName: String);

      property Name: String read fName;
      property BassSample: LongWord read fBassSample;
      property IsDefaultSound: Boolean read fIsDefaultSound write fIsDefaultSound;
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

      procedure ObtainMusicBassChannel;
      procedure FreeMusic;

      procedure SetMusicVolume(aValue: Integer);
      procedure SetMusicMute(aValue: Boolean);

      function FindSoundIndex(aName: String): Integer;
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadDefaultSounds;
      procedure LoadSoundFromFile(aName: String; aDefault: Boolean = false);
      procedure LoadSoundFromStream(aStream: TStream; aName: String; aDefault: Boolean = false);
      procedure PurgeNonDefaultSounds;

      procedure LoadMusicFromFile(aName: String);
      procedure LoadMusicFromStream(aStream: TStream; aName: String);

      procedure PlaySound(aName: String; aBalance: Integer = 0); // -100 = fully left, +100 = fully right
      procedure PlayMusic;
      procedure StopMusic;

      property SoundVolume: Integer read fSoundVolume write fSoundVolume;
      property MusicVolume: Integer read fMusicVolume write SetMusicVolume;
      property MuteSound: Boolean read fMuteSound write fMuteSound;
      property MuteMusic: Boolean read fMuteMusic write SetMusicMute;
  end;

var
  SoundManager: TSoundManager;

implementation

(* --- TSoundManager --- *)

constructor TSoundManager.Create;
begin
  inherited;
  fSoundEffects := TSoundEffects.Create;
  fMusicStream := TMemoryStream.Create;
  fMusicChannel := $FFFFFFFF;
end;

destructor TSoundManager.Destroy;
begin
  FreeMusic;
  fMusicStream.Free;
  fSoundEffects.Free;
  inherited;
end;

procedure TSoundManager.FreeMusic;
begin
  if fMusicChannel = $FFFFFFFF then Exit;
  BASS_StreamFree(fMusicChannel);
  fMusicPlaying := false;
  fMusicChannel := $FFFFFFFF;
end;

procedure TSoundManager.ObtainMusicBassChannel;
begin
  Assert(fMusicChannel = $FFFFFFFF, 'TSoundManager.ObtainMusicBassChannel: A channel already exists!');
  fMusicChannel := BASS_StreamCreateFile(true, fMusicStream.Memory, 0, fMusicStream.Size, 0);
  if fMusicChannel = 0 then // this means we have a module-based file
  begin
    fMusicChannel := BASS_MusicLoad(true, fMusicStream.Memory, 0, fMusicStream.Size, 0, 0);
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_MUSIC_AMPLIFY, fMusicVolume);
  end else begin
    BASS_LoadLoopData(fMusicChannel); // yay, this was added to the BASS unit rather than GameSound
    BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_VOL, (fMusicVolume / 100));
  end;
end;

procedure TSoundManager.SetMusicVolume(aValue: Integer);
begin
  fMusicVolume := aValue;
  if fMusicChannel = $FFFFFFFF then Exit;
  BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_VOL, (fMusicVolume / 100));
  BASS_ChannelSetAttribute(fMusicChannel, BASS_ATTRIB_MUSIC_AMPLIFY, fMusicVolume);
end;

procedure TSoundManager.SetMusicMute(aValue: Boolean);
begin
  fMuteMusic := aValue;
  if fMusicChannel = $FFFFFFFF then Exit;
  if fMuteMusic then
    BASS_ChannelStop(fMusicChannel)
  else if fMusicPlaying then
    PlayMusic;
end;

procedure TSoundManager.LoadSoundFromFile(aName: String; aDefault: Boolean = false);
var
  F: TFileStream;

  function FindExt: String;
  var
    i: Integer;
    LocalName: String;
  const
    VALID_EXTS: array[0..1] of String = ('.ogg', '.wav');
  begin
    Result := '';
    LocalName := ChangeFileExt(aName, '');
    for i := 0 to Length(VALID_EXTS) - 1 do
      if FileExists(AppPath + SFSounds + LocalName + VALID_EXTS[i]) then
      begin
        Result := VALID_EXTS[i];
        Exit;
      end;
  end;
begin
  F := TFileStream.Create(AppPath + SFSounds + aName + FindExt, fmOpenRead);
  try
    LoadSoundFromStream(F, aName, aDefault);
  finally
    F.Free;
  end;
end;


procedure TSoundManager.LoadSoundFromStream(aStream: TStream; aName: String; aDefault: Boolean = false);
begin
  with fSoundEffects.Add do
  begin
    LoadFromStream(aStream, aName);
    IsDefaultSound := aDefault;
  end;
end;

procedure TSoundManager.LoadDefaultSounds;
  procedure Get(aName: String);
  begin
    LoadSoundFromFile(aName, true);
  end;
begin
  // Commented-out lines are sound files that existed since Lemmix, but don't appear to be referenced anywhere in the code.
  // Just in case, I haven't deleted these files, but put them in an "unused" subfolder of the sound folder.

  //Get('bang');
  //Get('bell');
  Get('chain');
  Get('changeop');
  Get('chink');
  Get('die');
  Get('door');
  Get('electric');
  Get('explode');
  Get('failure');
  Get('fire');
  Get('glug');
  Get('letsgo');
  //Get('mantrap');
  Get('mousepre');
  Get('ohno');
  //Get('oing');
  Get('oing2');
  //Get('scrape');
  //Get('slicer');
  Get('slurp');
  Get('splash');
  Get('splat');
  Get('success');
  Get('tenton');
  Get('thud');
  Get('thunk');
  Get('ting');
  Get('vacuusux');
  Get('weedgulp');
  Get('wrench');
  Get('yippee');
  Get('zombie');
end;

function TSoundManager.FindSoundIndex(aName: String): Integer;
begin
  aName := Lowercase(aName);
  for Result := 0 to fSoundEffects.Count-1 do
    if fSoundEffects[Result].Name = aName then
      Exit;
  Result := -1;
end;

procedure TSoundManager.PurgeNonDefaultSounds;
var
  i: Integer;
begin
  for i := fSoundEffects.Count-1 downto 0 do
    if not fSoundEffects[i].IsDefaultSound then
      fSoundEffects.Delete(i);
end;

procedure TSoundManager.LoadMusicFromFile(aName: String);
var
  F: TFileStream;

  function FindExt: String;
  var
    i: Integer;
    LocalName: String;
  const
    VALID_EXTS: array[0..11] of string = (
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
  begin
    Result := '';
    LocalName := ChangeFileExt(aName, '');
    for i := 0 to Length(VALID_EXTS) - 1 do
      if FileExists(AppPath + SFMusic + LocalName + VALID_EXTS[i]) then
      begin
        Result := VALID_EXTS[i];
        Exit;
      end;
  end;

begin
  aName := Lowercase(aName);
  if fMusicName = aName then Exit; // saves some time

  F := TFileStream.Create(AppPath + SFMusic + aName + FindExt, fmOpenRead);
  try
    LoadMusicFromStream(F, aName);
  finally
    F.Free;
  end;
end;

procedure TSoundManager.LoadMusicFromStream(aStream: TStream; aName: String);
begin
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
  fMusicPlaying := true;

  if fMuteMusic then
    Exit;

  if fMusicChannel = $FFFFFFFF then
    ObtainMusicBassChannel;
  BASS_ChannelPlay(fMusicChannel, false);
end;

procedure TSoundManager.StopMusic;
begin
  fMusicPlaying := false;
  BASS_ChannelStop(fMusicChannel);
end;

procedure TSoundManager.PlaySound(aName: String; aBalance: Integer = 0);
var
  SoundIndex: Integer;
  SampleChannel: LongWord;
begin
  SoundIndex := FindSoundIndex(aName);
  if SoundIndex <> -1 then
  begin
    SampleChannel := BASS_SampleGetChannel(fSoundEffects[SoundIndex].BassSample, true);
    BASS_ChannelSetAttribute(SampleChannel, BASS_ATTRIB_PAN, (aBalance / 100));
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
