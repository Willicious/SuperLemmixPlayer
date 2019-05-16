unit LemNeoOnline;

interface

uses
  URLMon, Windows, Wininet, ActiveX, Axctrls, // Don't ask. It's just where these are.
  Classes, SysUtils;

type
  TInternet = class
    public
      class function DownloadToStream(aURL: String; aStream: TStream): Boolean;
      class function DownloadToStringList(aURL: String; aStringList: TStringList): Boolean;
  end;

  TDownloadThread = class(TThread)
    private
      fSourceURL: String;
      fStream: TStream;
      fStringList: TStringList;

      fCancel: Boolean;
      fComplete: Boolean;
      fSuccess: Boolean;
    protected
      procedure Execute; override;
    public
      constructor Create(aSourceURL: String; aTargetStream: TStream); overload;
      constructor Create(aSourceURL: String; aTargetStringList: TStringList); overload;
      destructor Destroy; override;

      procedure Cancel;
  end;

  // Download methods



implementation

{ TDownloadThread }

procedure TDownloadThread.Cancel;
begin
  fCancel := true;
end;

constructor TDownloadThread.Create(aSourceURL: String; aTargetStream: TStream);
begin
  fCancel := false;
  fSourceURL := aSourceURL;
  fStream := aTargetStream;
end;

constructor TDownloadThread.Create(aSourceURL: String;
  aTargetStringList: TStringList);
begin
  fCancel := false;
  fSourceURL := aSourceURL;
  fStringList := aTargetStringList;
end;

destructor TDownloadThread.Destroy;
begin

  inherited;
end;

procedure TDownloadThread.Execute;
var
  StreamPos: Int64;
  LocalStream: Boolean;
  LoadToStringList: Boolean;
begin
  inherited;
  try
    if fStream = nil then
    begin
      LoadToStringList := (fStringList <> nil);
      LocalStream := true;
      fStream := TMemoryStream.Create;
    end else begin
      LocalStream := false;
      LoadToStringList := false;
    end;

    try
      StreamPos := fStream.Position;
      TInternet.DownloadToStream(fSourceURL, fStream);
      if LoadToStringList then
      begin
        fStream.Position := StreamPos;
        fStringList.LoadFromStream(fStream);
      end;
    finally
      if LocalStream then
        fStream.Free;
    end;

    fSuccess := true;
  except
    fSuccess := false;
  end;

  fComplete := true;

  if fCancel then
    FreeOnTerminate := true; // Actually stopping the download is hard with current code. That's why
                             // we just let it silently continue, then discard it, instead.
end;

class function TInternet.DownloadToStream(aURL: String; aStream: TStream): Boolean;
var
  hrResult:   HRESULT;
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

class function TInternet.DownloadToStringList(aURL: String; aStringList: TStringList): Boolean;
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
