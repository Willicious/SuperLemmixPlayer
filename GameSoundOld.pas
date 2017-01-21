{$include lem_directives.inc}

unit GameSoundOld;

interface

uses
  Windows, Classes, Contnrs, SysUtils,
  Bass,
  Dialogs,
  LemTypes;

const
  DEFAULT_CHANNELS = 16;

type
  TAbstractSound = class
  private
    fStream: TMemoryStream;
    fResourceDataType: TLemDataType;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFileName(aFileName: string; aTestMode: Boolean = false);
    procedure LoadFromStream(aStream: TStream);
  end;
  (*
  TSound = class(TAbstractSound)
  private
  protected
  public
    constructor Create;
  end;
  *)
  TMusic = class(TAbstractSound)
  private
  protected
  public
    constructor Create;
  end;
  (*
  TSoundList = class(TObjectList)
  private
    function GetItem(Index: Integer): TSound;
  protected
  public
    function Add(Item: TSound): Integer;
    procedure Insert(Index: Integer; Item: TSound);
    property Items[Index: Integer]: TSound read GetItem; default;
  published
  end;
  *)

  TMusicList = class(TObjectList)
  private
    function GetItem(Index: Integer): TMusic;
  protected
  public
    function Add(Item: TMusic): Integer;
    procedure Insert(Index: Integer; Item: TMusic);
    property Items[Index: Integer]: TMusic read GetItem; default;
  published
  end;

  TSoundQueueEntry = class
  public
    Index: Integer;
    Balance: Single;
    constructor Create;
  end;

  TSoundMgr = class
  private
    fMusics: TMusicList;
    fSounds: TList;

    fQueue: TObjectList;

    fAvailableChannels : Integer;
    fBrickSound : Integer;
    fActiveSounds  : array[0..255] of Boolean;
    fPlayingSounds : array[0..255] of Integer;
  protected
  public
    constructor Create;
    destructor Destroy; override;
  { sounds }
    function AddSoundFromFileName(const aFileName: string; FromNXP: Boolean = false): Integer;
    function AddSoundFromStream(aStream: TMemoryStream): Integer;
    procedure FreeSound(aIndex: Integer);
    procedure PlaySound(Index: Integer; Balance: Integer); overload;
    procedure PlaySound(Index: Integer; Balance: Single = 0); overload;
    procedure StopSound(Index: Integer);

    procedure QueueSound(Index: Integer; Balance: Integer); overload;
    procedure QueueSound(Index: Integer; Balance: Single = 0); overload;
    procedure FlushQueue;
    procedure ClearQueue;
  { musics }
    function AddMusicFromFileName(const aFileName: string; aTestMode: Boolean): Integer;
    function AddMusicFromStream(aStream: TStream): Integer;
    procedure PlayMusic(Index: Integer);
    procedure StopMusic(Index: Integer);
    procedure CheckFreeChannels;

    property Musics: TMusicList read fMusics;
    property Sounds: TList read fSounds;

    property AvailableChannels: Integer read fAvailableChannels write fAvailableChannels;
    property BrickSound: Integer read fBrickSound write fBrickSound;
  end;

  TSoundSystem = class
  private
    fMusicRef : HMUSIC;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitWav;
    function PlayWav(S: TMemoryStream): Integer;
    procedure StopWav(S: TMemoryStream);

    procedure PlayMusic(S: TMemoryStream);
    procedure StopMusic(S: TMemoryStream);
  end;

var
  SoundVolume, MusicVolume: Integer; // using global vars for now. Will implement a better-practice system later (even though I don't see what can go wrong with this)
  SavedSoundVol, SavedMusicVol: Integer;

implementation

uses
  MMSystem;

var
  _SoundSystem: TSoundSystem;

function SoundSystem: TSoundSystem;
begin
  if _SoundSystem = nil then
    _SoundSystem := TSoundSystem.Create;
  Result := _SoundSystem;
end;

{ TSoundQueueEntry }

constructor TSoundQueueEntry.Create;
begin
  Index := -1;
end;

{ TAbstractSound }

constructor TAbstractSound.Create;
begin
  inherited Create;
  fStream := TMemoryStream.Create;
end;

destructor TAbstractSound.Destroy;
begin
  fStream.Free;
  inherited;
end;

procedure TAbstractSound.LoadFromFileName(aFileName: string; aTestMode: Boolean = false);
{-------------------------------------------------------------------------------
  Loads from file or archive file in resource
-------------------------------------------------------------------------------}
var
  F: TMemoryStream;
begin
  F := CreateDataStream(aFileName, fResourceDataType, aTestMode);

  try
    if F <> nil then LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TAbstractSound.LoadFromStream(aStream: TStream);
begin
  fStream.LoadFromStream(aStream);
end;

(*
{ TSound }

constructor TSound.Create;
begin
  inherited Create;
  fResourceDataType := ldtSound;
end;
*)

{ TMusic }

constructor TMusic.Create;
begin
  inherited;
  fResourceDataType := ldtMusic;
end;

(*
{ TSoundList }

function TSoundList.Add(Item: TSound): Integer;
begin
  Result := inherited Add(Item);
end;

function TSoundList.GetItem(Index: Integer): TSound;
begin
  Result := inherited Get(Index);
end;

procedure TSoundList.Insert(Index: Integer; Item: TSound);
begin
  inherited Insert(Index, Item);
end;
*)

{ TMusicList }

function TMusicList.Add(Item: TMusic): Integer;
begin
  Result := inherited Add(Item);
end;

function TMusicList.GetItem(Index: Integer): TMusic;
begin
  Result := inherited Get(Index);
end;

procedure TMusicList.Insert(Index: Integer; Item: TMusic);
begin
  inherited Insert(Index, Item);
end;

{ TSoundMgr }

function TSoundMgr.AddMusicFromFileName(const aFileName: string; aTestMode: Boolean): Integer;
var
  M: TMusic;
begin
  M := TMusic.Create;
  Result := Musics.Add(M);
  M.LoadFromFileName(aFileName, aTestMode);
end;

function TSoundMgr.AddMusicFromStream(aStream: TStream): Integer;
var
  M: TMusic;
begin
  M := TMusic.Create;
  Result := Musics.Add(M);
  M.LoadFromStream(aStream);
end;

function TSoundMgr.AddSoundFromFileName(const aFileName: string; FromNXP: Boolean = false): Integer;
var
  S: TMemoryStream;
begin
  if FromNXP then
    S := CreateDataStream(aFileName, ldtLemmings)
  else
    S := CreateDataStream(aFileName, ldtSound);
  Result := Sounds.Add(Pointer(BASS_SampleLoad(true, S.Memory, 0, S.Size, 65535, 0)));
end;

function TSoundMgr.AddSoundFromStream(aStream: TMemoryStream): Integer;
begin
  Result := Sounds.Add(Pointer(BASS_SampleLoad(true, aStream.Memory, 0, aStream.Size, 65535, 0)));
end;

procedure TSoundMgr.FreeSound(aIndex: Integer);
begin
  BASS_SampleFree(LongWord(Sounds[aIndex]));
end;

constructor TSoundMgr.Create;
var
  i: Integer;
begin
  inherited Create;
  if not BASS_Init(-1, 44100, BASS_DEVICE_NOSPEAKER, 0, nil) then
    BASS_Free
  else
    BASS_SetConfig(BASS_CONFIG_VISTA_SPEAKERS, 1);
  fSounds := TList.Create;
  fMusics := TMusicList.Create;
  fAvailableChannels := DEFAULT_CHANNELS;
  for i := 0 to 255 do
    fPlayingSounds[i] := -1;
  fQueue := TObjectList.Create(true);
end;

destructor TSoundMgr.Destroy;
begin
  StopSound(0);
  StopMusic(0);
  fSounds.Free;
  fMusics.Free;
  fQueue.Free;
  inherited Destroy;
end;

procedure TSoundMgr.CheckFreeChannels;
var
  i : integer;
begin
  for i := 0 to fAvailableChannels-1 do
  begin
    if (BASS_ChannelIsActive(fPlayingSounds[i]) <> BASS_ACTIVE_PLAYING)
    or (BASS_ChannelGetPosition(fPlayingSounds[i], BASS_POS_BYTE) >= BASS_ChannelGetLength(fPlayingSounds[i], BASS_POS_BYTE)) then
    begin
      fActiveSounds[i] := false;
      fPlayingSounds[i] := -1;
      Continue;
    end;
    if BASS_ChannelGetPosition(fPlayingSounds[i], BASS_POS_BYTE) >= BASS_ChannelSeconds2Bytes(fPlayingSounds[i], 0.5) then
      fActiveSounds[i] := false;
  end;
end;

procedure TSoundMgr.PlaySound(Index: Integer; Balance: Integer);
begin
  if Balance < -100 then Balance := -100;
  if Balance > 100 then Balance := 100;
  PlaySound(Index, Balance / 100);
end;

procedure TSoundMgr.PlaySound(Index: Integer; Balance: Single = 0);
var
  i : Integer;
  c : HCHANNEL;
begin

  CheckFreeChannels;

  if Index = fBrickSound then
  begin
    if fPlayingSounds[0] >= 0 then
      BASS_ChannelStop(fPlayingSounds[0]);
    c := BASS_SampleGetChannel(Integer(Sounds[Index]), true);
    BASS_ChannelSetAttribute(c, BASS_ATTRIB_PAN, Balance);
    BASS_ChannelSetAttribute(c, BASS_ATTRIB_VOL, SoundVolume / 100);

    BASS_ChannelPlay(c, true);

    fPlayingSounds[0] := c;
    fActiveSounds[0] := true;
    Exit;
  end;

  if Index >= 0 then
    if Index < Sounds.Count then
      for i := 1 to (fAvailableChannels - 1) do
      begin
        if not fActiveSounds[i] then
        begin
          if fPlayingSounds[i] >= 0 then
            BASS_ChannelStop(fPlayingSounds[i]);
          c := BASS_SampleGetChannel(Integer(Sounds[Index]), true);
          BASS_ChannelSetAttribute(c, BASS_ATTRIB_PAN, Balance);
          BASS_ChannelSetAttribute(c, BASS_ATTRIB_VOL, SoundVolume / 100);
          BASS_ChannelPlay(c, true);

          fPlayingSounds[i] := c;
          fActiveSounds[i] := true;
          Exit;
        end;
      end;
end;

procedure TSoundMgr.PlayMusic(Index: Integer);
begin
  if Index >= 0 then
    if Index < Musics.Count then
      SoundSystem.PlayMusic(Musics[Index].fStream)
end;

procedure TSoundMgr.StopSound(Index: Integer);
begin
  SoundSystem.StopWav(nil);
end;

procedure TSoundMgr.StopMusic(Index: Integer);
begin
  if Index >= 0 then
    if Index < Musics.Count then
      SoundSystem.StopMusic(nil);
end;

procedure TSoundMgr.QueueSound(Index: Integer; Balance: Integer);
begin
  if Balance < -100 then Balance := -100;
  if Balance > 100 then Balance := 100;
  QueueSound(Index, Balance / 100);
end;

procedure TSoundMgr.QueueSound(Index: Integer; Balance: Single = 0);
var
  i: Integer;
  S: TSoundQueueEntry;
begin
  for i := 0 to fQueue.Count-1 do
  begin
    S := TSoundQueueEntry(fQueue[i]);
    if (S.Index = Index) and (S.Balance = Balance) then Exit;
  end;

  S := TSoundQueueEntry.Create;
  fQueue.Add(S);
  S.Index := Index;
  S.Balance := Balance;
end;

procedure TSoundMgr.FlushQueue;
var
  i: Integer;
  S: TSoundQueueEntry;
begin
  for i := 0 to fQueue.Count-1 do
  begin
    S := TSoundQueueEntry(fQueue[i]);
    PlaySound(S.Index, S.Balance);
  end;

  ClearQueue;
end;

procedure TSoundMgr.ClearQueue;
begin
  fQueue.Clear;
end;

{ TSoundSystem }

constructor TSoundSystem.Create;
begin
  inherited Create;
  InitWav;
end;

destructor TSoundSystem.Destroy;
begin
  BASS_Free;
  inherited;
end;

procedure TSoundSystem.InitWav;
begin
  PlaySound(nil, HINSTANCE, SND_ASYNC + SND_MEMORY);
end;

procedure TSoundSystem.PlayMusic(S: TMemoryStream);
const
  MusicFlags = BASS_MUSIC_LOOP or BASS_MUSIC_RAMPS or BASS_MUSIC_SURROUND or
               BASS_MUSIC_POSRESET or BASS_SAMPLE_SOFTWARE;
var
  V: Single;
begin
  BASS_StreamFree(fMusicRef);
  BASS_MusicFree(fMusicRef);
  fMusicRef := 0;
  if S.Size > 0 then
    fMusicRef := BASS_StreamCreateFile(true, S.Memory, 0, S.Size, MusicFlags);

  if fMusicRef = 0 then
  begin
    fMusicRef := BASS_MusicLoad(true, S.Memory, 0, S.Size, MusicFlags, 1);
    BASS_ChannelGetAttribute(fMusicRef, BASS_ATTRIB_MUSIC_VOL_GLOBAL, V);
    V := V * MusicVolume / 100;
    BASS_ChannelSetAttribute(fMusicRef, BASS_ATTRIB_MUSIC_VOL_GLOBAL, V);
  end else begin
    BASS_ChannelSetAttribute(fMusicRef, BASS_ATTRIB_VOL, MusicVolume / 100);
    BASS_LoadLoopData(fMusicRef);
  end;

  if fMusicRef <> 0 then
  begin
    BASS_ChannelPlay(fMusicRef, false);
  end;

end;

function TSoundSystem.PlayWav(S: TMemoryStream): Integer;
begin
  PlaySound(S.Memory, HINSTANCE, SND_ASYNC + SND_MEMORY);
  Result := 0;
end;

procedure TSoundSystem.StopMusic(S: TMemoryStream);
begin
  BASS_ChannelStop(fMusicRef);
end;

procedure TSoundSystem.StopWav(S: TMemoryStream);
begin
  PlaySound(nil, HINSTANCE, SND_ASYNC + SND_MEMORY);
end;

initialization
finalization
  _SoundSystem.Free;
  _SoundSystem := nil;
end.


