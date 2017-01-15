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
  TArrayArrayInt = array of array of Integer;
  TArrayArrayBoolean = array of array of Boolean;

  TBitmaps = class(TObjectList)
  private
    function GetItem(Index: Integer): TBitmap32;
  protected
  public
    function Add(Item: TBitmap32): Integer;
    procedure Insert(Index: Integer; Item: TBitmap32);
    procedure Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
    property Items[Index: Integer]: TBitmap32 read GetItem; default;
    property List;
  published
  end;

  // lemlowlevel
procedure ReplaceColor(B: TBitmap32; FromColor, ToColor: TColor32);
function CalcFrameRect(Bmp: TBitmap32; FrameCount, FrameIndex: Integer): TRect;
function AppPath: string;
function MakeSuitableForFilename(const aInput: String): String;
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

function MakeSuitableForFilename(const aInput: String): String;
const
  FORBIDDEN_CHARS = '<>:"/\|?*';
  REPLACEMENT_CHAR = '_';
var
  i: Integer;
  CharPos: Integer;
begin
  Result := aInput;
  for i := 1 to Length(FORBIDDEN_CHARS) do
  begin
    CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    while CharPos <> 0 do
    begin
      Result[CharPos] := REPLACEMENT_CHAR;
      CharPos := Pos(FORBIDDEN_CHARS[i], Result);
    end;
  end;
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

  Result.Left := 0;
  Result.Top := Y;
  Result.Right := W;
  Result.Bottom := Y + H;
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
                    aFilename := ChangeFileExt(aFilename, '');
                    if FileExists(AppPath + 'sound\' + aFilename + '.ogg') then
                      aFilename := aFilename + '.ogg'
                    else if FileExists(AppPath + 'sound\' + aFilename + '.wav') then
                      aFileName := aFilename + '.wav'
                    else begin
                      FreeAndNil(Result);
                      Exit;
                    end;

                    Result.LoadFromFile(AppPath + 'sound\' + aFilename);
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
                       if FileInArchive then
                         Arc.ExtractFile(aFilename, Result)
                       else
                         FreeAndNil(Result);
                     end;
        ldtStyle: begin
                    // ldtStyle is used for graphic sets. This is similar to ldtLemmings, but also
                    // checks the /styles/ folder if all else fails.
                    if not IsSingleLevelMode then Arc.OpenArchive(GameFile, amOpen);
                    if not FileInArchive then Arc.OpenResource(HINSTANCE, 'lemdata', 'archive');
                    if FileInArchive then
                      Arc.ExtractFile(aFilename, Result)
                    else begin
                      if not FileExists(AppPath + 'styles/' + aFilename) then
                        FreeAndNil(Result)
                      else
                        Result.LoadFromFile(AppPath + 'styles/' + aFilename);
                    end;
                  end;
        ldtText: begin
                   // ldtText is for text files, which should never be loaded from lemdata (except music.txt,
                   // but that's why it's loaded via ldtLemmings). So it only checks the NXP.
                   if IsSingleLevelMode then
                     FreeAndNil(Result)
                   else begin
                     Arc.OpenArchive(GameFile, amOpen);
                     if FileInArchive then
                       Arc.ExtractFile(aFilename, Result)
                     else
                       FreeAndNil(Result);
                   end;
                 end;
        ldtMusic: begin
                    if FormatDateTime('mmdd', Now) = '0401' then
                      aFilename := 'orig_00'; // April fools prank. "orig_00" is a rickroll.

                    if FindInMusicFolder = '' then
                      FreeAndNil(Result)
                    else
                      Result.LoadFromFile(AppPath + 'music/' + FindInMusicFolder);
                  end;
      end;
      if Result <> nil then Result.Position := 0;
    except
      Result.Free;
      Result := nil;
    end;
    Arc.Free;
  end;
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

procedure TBitmaps.Generate(Src: TBitmap32; Frames: Integer; Horizontal: Boolean = false);
var
  BMP: TBitmap32;
  i: Integer;
  w, h: Integer;
  sx, sy: Integer;
begin
  Clear;
  w := Src.Width;
  h := Src.Height div Frames;
  sx := 0;
  sy := 0;
  for i := 0 to Frames-1 do
  begin
    BMP := TBitmap32.Create;
    Add(BMP);
    BMP.SetSize(w, h);
    BMP.Clear(0);
    Src.DrawTo(BMP, Rect(0, 0, w, h), Rect(sx, sy, sx+w, sy+h));
    if Horizontal then
      Inc(sx, w)
    else
      Inc(sy, h);
  end;
end;


end.

