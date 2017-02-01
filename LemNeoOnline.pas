unit LemNeoOnline;

{
Contains online functions. No - no multiplayer, no plans for that.
But it can download files from a server. Currently, this is only used
to obtain missing graphic sets; but hopefully in the future it'll be
expanded to directly access some kind of content database. :)
}

interface

uses
  Dialogs, LemVersion,
  URLMon, Wininet, Classes, ActiveX, Axctrls, SysUtils; // I can only guess why IStream and others are in the ActiveX units...

const
  NX_BASE_URL = 'http://www.neolemmix.com/';
  NX_VERSIONS_URL = NX_BASE_URL + 'version.php';
  NX_STYLES_URL   = NX_BASE_URL + 'styles.php';

type
  TNxAppType = (NxaPlayer, NxaEditor, NxaFlexi, NxaGS, NxaTalisman);

  // Core functions
  function DownloadToFile(aURL: String; aFilename: String): Boolean;
  function DownloadToStream(aURL: String; aStream: TStream): Boolean;
  function DownloadToStringList(aURL: String; aStringList: TStringList): Boolean;

  // Specialty functions
  function GetLatestNeoLemmixVersion(const aApp: TNxAppType; var aFormat, aCore, aFeature, aHotfix: Integer): Boolean;

implementation

function GetLatestNeoLemmixVersion(const aApp: TNxAppType; var aFormat, aCore, aFeature, aHotfix: Integer): Boolean;
var
  SL: TStringList;
  TempString: String;
begin
  SL := TStringList.Create;
  try
    Result := DownloadToStringList(NX_VERSIONS_URL, SL);
  except
    Result := false;
    SL.Free;
    Exit;
  end;

  case aApp of
    NxaPlayer: TempString := 'game';
    NxaEditor: TempString := 'editor';
    NxaFlexi: TempString := 'flexi';
    NxaGS: TempString := 'gstool';
    NxaTalisman: TempString := 'talisman';
  end;

  TempString := SL.Values[TempString];
  if TempString = '' then
  begin
    Result := false;
    SL.Free;
    Exit;
  end;

  SL.Delimiter := '.';
  SL.DelimitedText := TempString;

  aFormat := StrToIntDef(SL[0], 0);
  aCore := StrToIntDef(SL[1], 0);
  aFeature := StrToIntDef(SL[2], 0);
  aHotfix := StrToIntDef(SL[3], 0);

  SL.Free;
end;

function DownloadToFile(aURL: String; aFilename: String): Boolean;
begin
  // Simple enough.
  try
    ForceDirectories(ExtractFilePath(aFilename));
    DeleteUrlCacheEntry(PChar(aURL));
    Result := UrlDownloadToFile(nil, PChar(aURL), PChar(aFilename), 0, nil) = 0;
  except
    Result := False;
  end;
end;

function DownloadToStream(aURL: String; aStream: TStream): Boolean;
var  hrResult:   HRESULT;
     ppStream:   IStream;
     statstg:    TStatStg;
     lpBuffer:   Pointer;
     dwRead:     Integer;
begin
  // Very complicated. I found this code (or very similar) in several places,
  // so I doubt the true original author can be found. So, thanks whoever you are.

  // Set default result
  result:=False;

  // Make sure stream is assigned
  if not(Assigned(aStream)) then exit;

  DeleteUrlCacheEntry(PChar(aURL));

  // Open blocking stream
  hrResult:=URLOpenBlockingStream(nil, PChar(aURL), ppStream, 0, nil);
  if (hrResult = S_OK) then
  begin
     // Get the stat from the IStream interface
     if (ppStream.Stat(statstg, STATFLAG_NONAME) = S_OK) then
     begin
        // Make sure size is greater than zero
        if (statstg.cbSize > 0) then
        begin
           // Allocate buffer for the read
           lpBuffer:=AllocMem(statstg.cbSize);
           // Read from the stream
           if (ppStream.Read(lpBuffer, statstg.cbSize, @dwRead) = S_OK) then
           begin
              // Write to delphi stream
              aStream.Write(lpBuffer^, dwRead);
              // Success
              result:=True;
           end;
           // Free the buffer
           FreeMem(lpBuffer);
        end;
     end;
     // Release the IStream interface
     ppStream:=nil;
  end;

end;

function DownloadToStringList(aURL: String; aStringList: TStringList): Boolean;
var
  TempStream: TMemoryStream;
begin
  // We just go via DownloadToStream for this one. Easier that way.
  TempStream := TMemoryStream.Create;
  try
    Result := DownloadToStream(aURL, TempStream);
    TempStream.Position := 0;
    aStringList.LoadFromStream(TempStream);
  finally
    TempStream.Free;
  end;
end;

end.