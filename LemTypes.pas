{$include lem_directives.inc}
unit LemTypes;

interface

uses
  LemNeoOnline,
  Dialogs,
  SharedGlobals,
  Classes, SysUtils, Contnrs,
  GR32, GR32_LowLevel,
  UZip,
  UTools;

const
  MUSIC_EXT_COUNT = 12;
  MUSIC_EXTENSIONS: array[0..MUSIC_EXT_COUNT-1] of string = (
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
                    '.umx');

  ORIG_LEMMINGS_RANDSEED = 47;
  OHNO_LEMMINGS_RANDSEED = 48;
  H94_LEMMINGS_RANDSEED = 49;
  LPDOS_LEMMINGS_RANDSEED = 45;
  LPII_LEMMINGS_RANDSEED = 46;
  LP2B_LEMMINGS_RANDSEED = 44;
  CUST_LEMMINGS_RANDSEED = 50;
  COVOX_LEMMINGS_RANDSEED = 51;
  PRIMA_LEMMINGS_RANDSEED = 53;
  XMAS_LEMMINGS_RANDSEED = 54;
  EXTRA_LEMMINGS_RANDSEED = 55;

  LPIII_LEMMINGS_RANDSEED = 52;
  LP3B_LEMMINGS_RANDSEED = 60;
  LPIV_LEMMINGS_RANDSEED = 68; //12; DEMOCODE
  LPZ_LEMMINGS_RANDSEED = 67;

  LPH_LEMMINGS_RANDSEED = 63;
  LPC_LEMMINGS_RANDSEED = 64;
  LPCII_LEMMINGS_RANDSEED = 73;

  ZOMBIE_LEMMINGS_RANDSEED = 72;

  COPYCAT_LEMMINGS_RANDSEED = 100;

  LEMMINGS_RANDSEED = CUST_LEMMINGS_RANDSEED;

type
  TLemDataType = (
    ldtNone,
    ldtLemmings,  // NXP or resource
    ldtSound,     // in a resource
    ldtMusic,     // NXP, music packs, resource... there are a few places this looks
    ldtParticles, // is in a resource
    ldtText,      // NXP
    ldtStyle      // NXP, resource, 'styles' directory
  );

type


  TBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmap32;
  protected
  public
    function Add(Item: TBitmap32): Integer;
    procedure Insert(Index: Integer; Item: TBitmap32);
    property Items[Index: Integer]: TBitmap32 read GetItem; default;
    property List;
  published
  end;

  TBasicWrapper = class(TComponent)
  private
    fPersistentObject: TPersistent;
  protected
  public
  published
    property PersistentObject: TPersistent read fPersistentObject write fPersistentObject;
  end;

  // lemlowlevel
procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
procedure PrepareFramedBitmap(Bmp: TBitmap32; FrameCount, FrameWidth, FrameHeight: Integer);
procedure InsertFrame(Dst, Src: TBitmap32; FrameCount, FrameIndex: Integer);
function AppPath: string;
function LemmingsPath: string;
function MusicsPath: string;

function CreateDataStream(aFileName: string; aType: TLemDataType; aAllowExternal: Boolean = false): TMemoryStream;

implementation

var
  _AppPath: string;

function AppPath: string;
begin
  if _AppPath = '' then
    _AppPath := ExtractFilePath(ParamStr(0));
  Result := _AppPath;
end;

function LemmingsPath: string;
begin

    Result := AppPath;

end;

function MusicsPath: string;
begin

    Result := AppPath;

end;

procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
var
  P: PColor32;
  i: Integer;
begin
  P := B.PixelPtr[0, 0];
  for i := 0 to B.Height * B.Width - 1 do
    begin
      if P^ = FromColor then
        P^ := ToColor;
      Inc(P);
    end;
end;

function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
var
  Y, H, W: Integer;
begin
  W := Bmp.Width;
  H := Bmp.Height div FrameCount;
  Y := H * FrameIndex;
//  Assert(Bmp.Height mod FrameCount = 0)
  Result.Left := 0;
  Result.Top := Y;
  Result.Right := W;
  Result.Bottom := Y + H;
end;

procedure PrepareFramedBitmap(Bmp: TBitmap32; FrameCount, FrameWidth, FrameHeight: Integer);
begin
  Bmp.SetSize(FrameWidth, FrameCount * FrameHeight);
  Bmp.ResetAlpha(0);
end;

procedure InsertFrame(Dst, Src: TBitmap32; FrameCount, FrameIndex: Integer);
var
  H, Y: Integer;
  W: Integer;
  SrcP, DstP: PColor32;
begin
  Assert(FrameCount > 0);
  Assert(Dst.Height = FrameCount * Src.Height);
  Assert(Dst.Width = Src.Width);

  H := Dst.Height div FrameCount;
  Y := H * FrameIndex;

  SrcP := Src.PixelPtr[0, 0];
  DstP := Dst.PixelPtr[0, Y];
  W := Dst.Width;

  for Y := 0 to H - 1 do
    begin
      MoveLongWord(SrcP^, DstP^, W);
      Inc(SrcP, W);
      Inc(DstP, W);
    end;

end;


function CreateDataStream(aFileName: string; aType: TLemDataType; aAllowExternal: Boolean = false): TMemoryStream;
{-------------------------------------------------------------------------------
  We always return a TMemoryStream as some files require it. This also allows
  modifying the files while running, although this is not really recommended.

  A nil result is returned if the file cannot be found.
-------------------------------------------------------------------------------}
var
  Arc: TArchive;
  IsSingleLevelMode: Boolean;

  procedure Fail;
  begin
    // Exceptions are silenced anyway by the try...except clause, so this message will
    // never show. It's basically just a shorthand way to say "return nil, do usual tidyup".
    raise Exception.Create('The FAIL procedure was called.');
  end;

  function FileInArchive: Boolean;
  begin
    // Uses Arc and aFileName from the main CreateDataStream function.
    if Arc.IsOpen then
      Result := Arc.ArchiveList.IndexOf(aFileName) <> -1
    else
      Result := false;
  end;

  function MusicFileInArchive(aStream: TMemoryStream = nil): Boolean;
  var
    i: Integer;
  begin
    i := 0;
    repeat
      aFilename := ChangeFileExt(aFilename, MUSIC_EXTENSIONS[i]);
      Result := FileInArchive;
      Inc(i);
    until Result or (i = MUSIC_EXT_COUNT);

    if Result and (aStream <> nil) then
      Arc.ExtractFile(aFilename, aStream);
  end;

  function FindExternalMusicFile(aStream: TMemoryStream = nil): Boolean;
    var
    i: Integer;
  begin
    i := 0;
    repeat
      aFilename := ChangeFileExt(aFilename, MUSIC_EXTENSIONS[i]);
      Result := FileExists(AppPath + aFilename);
      Inc(i);
    until Result or (i = MUSIC_EXT_COUNT);

    if Result and (aStream <> nil) then
      aStream.LoadFromFile(AppPath + aFilename);
  end;

  function FindInMusicFolder: String;
  var
    i: Integer;
  begin
    Result := '';
    aFilename := ChangeFileExt(aFilename, '');
    for i := 0 to MUSIC_EXT_COUNT-1 do
      if FileExists(AppPath + 'music/' + aFilename + MUSIC_EXTENSIONS[i]) then
      begin
        Result := aFilename + MUSIC_EXTENSIONS[i];
        Exit;
      end;
  end;
begin

  aFilename := ExtractFileName(aFilename); // there should never be a call to this with a path;
                                           // but just in case.

  IsSingleLevelMode := LowerCase(ExtractFileExt(GameFile)) <> '.nxp'; // need a tidier way, but this does work

  { //   ldtNone,
    // ldtLemmings,  // NXP or resource
    // ldtSound,     // in a resource
    // ldtMusic,     // NXP, music packs, resource... there are a few places this looks
    // ldtParticles, // is in a resource
    // ldtText,      // NXP
    ldtStyle}

  Result := TMemoryStream.Create;

  // When external files are allowed, they override everything else.
  if aAllowExternal then
  begin
    if aType = ldtMusic then
    begin
      FindExternalMusicFile(Result);
    end else
      if FileExists(AppPath + aFilename) then
        Result.LoadFromFile(AppPath + aFilename);
    Result.Position := 0; // this code is harmless if nothing was found here, and desired if something was found
  end;

  if Result.Size = 0 then
  begin
    Arc := TArchive.Create;
    try
      case aType of
        // Handle the simple ones first - those that generally only look in one place.
        ldtNone: Fail; // hm... why does ldtNone even exist? Better not remove until I'm sure it's not needed.
        ldtSound: begin
                    Result := TMemoryStream.Create;
                    Arc.OpenResource(HINSTANCE, 'lemsounds', 'archive');
                    Arc.ExtractFile(aFilename, Result);
                  end;
        ldtParticles: begin
                        Arc.OpenResource(HINSTANCE, 'lemparticles', 'archive');
                        Arc.ExtractFile(aFilename, Result);
                      end;
        // Now the more complicated stuff.
        ldtLemmings: begin
                       // ldtLemmings is the general method for Lemmings data. It should look
                       // in the NXP first, then in lemdata if the NXP comes up blank.
                       if not IsSingleLevelMode then Arc.OpenArchive(GameFile, amOpen);
                       if not FileInArchive then Arc.OpenResource(HINSTANCE, 'lemdata', 'archive');
                       Arc.ExtractFile(aFilename, Result);
                     end;
        ldtStyle: begin
                    // ldtStyle is used for graphic sets. This is similar to ldtLemmings, but also
                    // checks the /styles/ folder if all else fails.
                    if not IsSingleLevelMode then Arc.OpenArchive(GameFile, amOpen);
                    if not FileInArchive then Arc.OpenResource(HINSTANCE, 'lemdata', 'archive');
                    if FileInArchive then
                      Arc.ExtractFile(aFilename, Result)
                    else begin
                      if not FileExists(AppPath + 'styles/' + aFilename) then Fail;
                      Result.LoadFromFile(AppPath + 'styles/' + aFilename);
                    end;
                  end;
        ldtText: begin
                   // ldtText is for text files, which should never be loaded from lemdata (except music.txt,
                   // but that's why it's loaded via ldtLemmings). So it only checks the NXP.
                   if IsSingleLevelMode then Fail;
                   Arc.OpenArchive(GameFile, amOpen);
                   Arc.ExtractFile(aFilename, Result);
                 end;
        ldtMusic: begin
                    // ldtMusic is the most complicated one. We search in several places until we find it.
                    // We also must check for various formats; so any extension passed is ignored. Parts
                    // of this are implemented in MusicFileInArchive and TryMusicPacks subfunctions.

                    // First place: The pack's associated music pack.
                    // Second place: The NXP.
                    // Third place: Music folder.
                    // Final place: lemdata
                    if FormatDateTime('mmdd', Now) = '0401' then
                      aFilename := 'orig_00'; // April fools prank. "orig_00" is a rickroll.

                    if not IsSingleLevelMode then
                    begin
                      if FileExists(ChangeFileExt(GameFile, '_Music.dat')) then
                        Arc.OpenArchive(ChangeFileExt(GameFile, '_Music.dat'), amOpen);
                    end;
                    if MusicFileInArchive then
                    begin
                      Arc.ExtractFile(aFilename, Result);
                    end else
                      if FindInMusicFolder = '' then
                      begin
                        if not (MusicFileInArchive or IsSingleLevelMode) then Arc.OpenArchive(GameFile, amOpen);
                        if not MusicFileInArchive then Arc.OpenResource(HINSTANCE, 'lemdata', 'archive');
                        if MusicFileInArchive then // Sets aFilename to the one that actually exists.
                          Arc.ExtractFile(aFilename, Result);
                      end else begin
                        Result.LoadFromFile(AppPath + 'music/' + FindInMusicFolder);
                      end;
                  end;
      end;
      Result.Position := 0;
    except
      Result.Free;
      Result := nil;
    end;
    Arc.Free;
  end;

  Exit;

  (*
  ============= OLD CODE =========

  //ShowMessage('load: ' + aFileName);

  case aType of
    ldtLemmings:
      begin

        Result := TMemoryStream.Create;
        Arc := TArchive.Create;
        try
          if ParamStr(1) = 'testmode' then
            Arc.OpenResource(HINSTANCE, 'lemdata', 'archive')
          else
            try
              Arc.OpenArchive(GameFile, amOpen);
            except
              Arc.OpenResource(HINSTANCE, 'lemdata', 'archive')
            end;

          try
            Arc.ExtractFile(ExtractFileName(aFileName), Result);
          except
            Arc.OpenResource(HINSTANCE, 'lemdata', 'archive');
            Arc.ExtractFile(ExtractFileName(aFileName), Result);
          end;
        finally
          Arc.Free;
        end;

      end;
    ldtText:  // A routine using ldtText MUST be prepared to handle a "nil" result
      begin

        Result := TMemoryStream.Create;
        Arc := TArchive.Create;
        try

          if ParamStr(1) = 'testmode' then
            Arc.OpenResource(HINSTANCE, 'lemdata', 'archive')
          else
            try
              Arc.OpenArchive(GameFile, amOpen);
            except
              Arc.OpenResource(HINSTANCE, 'lemdata', 'archive')
            end;

          if Arc.ArchiveList.IndexOf(ExtractFileName(aFileName)) = -1 then
          begin
            Result.Free;
            Result := nil;
          end else
            Arc.ExtractFile(ExtractFileName(aFileName), Result);
        finally
          Arc.Free;
        end;

      if Result <> nil then Result.Seek(0, soFromBeginning);
      Exit;
      end;
    ldtSound:
      begin

        Result := TMemoryStream.Create;
        Arc := TArchive.Create;
        try

          Arc.OpenResource(HINSTANCE, 'lemsounds', 'archive');

          Arc.ExtractFile(ExtractFileName(aFileName), Result);
        finally
          Arc.Free;
        end;

      end;
    ldtMusic:
      begin

        Result := TMemoryStream.Create;
        Arc := TArchive.Create;
        try
          if FormatDateTime('mmdd', Now) = '0401' then
          begin
            // If you've worked out what this code is for, but the date it triggers hasn't come yet,
            // please don't spoil the prank. :P
            Arc.OpenResource(HINSTANCE, 'lemmusic', 'archive');
            Arc.ExtractFile('orig_00.it', Result);
          end else begin

            // Step 1 - Look for a music pack, and try that.
            if (ParamStr(1) = 'testmode') or (GameFile = 'Single Levels') then //need a better way to pass single level mode to this...
              tk := 'NeoLemmix_MUSIC.DAT'
            else
              tk := ChangeFileExt(GameFile, '') + '_MUSIC.DAT';

            if FileExists(tk) then
            begin
              Arc.OpenArchive(tk, amOpen);
              tk := ChangeFileExt(aFileName, '') + '.ogg';
              if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) = -1 then tk := ChangeFileExt(aFileName, '') + '.it';
              if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) <> -1 then
              begin
                Arc.ExtractFile(ExtractFileName(tk), Result);
                Exit;
              end;
            end;

            // Not found? Search the global music packs.
            if FindFirst(ExtractFilePath(ParamStr(0)) + 'NeoLemmix_Music_*.dat', faAnyFile, SearchRec) = 0 then
            begin
              repeat
                Arc.OpenArchive(ExtractFilePath(ParamStr(0)) + SearchRec.Name, amOpen);
                tk := ChangeFileExt(aFileName, '') + '.ogg';
                if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) = -1 then tk := ChangeFileExt(aFileName, '') + '.it';
                if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) <> -1 then
                begin
                  Arc.ExtractFile(ExtractFileName(tk), Result);
                  FindClose(SearchRec);
                  Exit;
                end;
              until FindNext(SearchRec) <> 0;
              FindClose(SearchRec);
            end;

            // Not found? Try the game's data itself.
            if (ParamStr(1) <> 'testmode') and (GameFile <> 'Single Levels') then
            begin
              Arc.OpenArchive(GameFile, amOpen);
              tk := ChangeFileExt(aFileName, '') + '.ogg';
              if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) = -1 then tk := ChangeFileExt(aFileName, '') + '.it';
              if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) <> -1 then
              begin
                Arc.ExtractFile(ExtractFileName(tk), Result);
                Exit;
              end;
            end;

            // Still not found? Try defaults.
            Arc.OpenResource(HINSTANCE, 'lemmusic', 'archive');
            tk := ChangeFileExt(aFileName, '') + '.ogg';
            if Arc.ArchiveList.IndexOf(ExtractFileName(tk)) = -1 then tk := ChangeFileExt(aFileName, '') + '.it';
            Arc.ExtractFile(ExtractFileName(tk), Result);
          end;
        finally
          Arc.Free;
        end;

      end;
    ldtParticles:
      begin

        Result := TMemoryStream.Create;
        Arc := TArchive.Create;
        try
          Arc.OpenResource(HINSTANCE, 'lemparticles', 'archive');
          Arc.ExtractFile(ExtractFileName(aFileName), Result);
        finally
          Arc.Free;
        end;

      end;
  else
    Result := nil;

  end;


  Assert(Result <> nil);

  Result.Seek(0, soFromBeginning);
  *)
end;


{ TBitmaps }

function TBitmaps.Add(Item: TBitmap32): Integer;
begin
  Result := inherited Add(Item);
end;

function TBitmaps.GetItem(Index: Integer): TBitmap32;
begin
  Result := inherited Get(Index);
end;

procedure TBitmaps.Insert(Index: Integer; Item: TBitmap32);
begin
  inherited Insert(Index, Item);
end;

end.

