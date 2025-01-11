unit LemNeoOnline;

interface

// If GameParams.EnableOnline is False, TDownloadThread.DownloadToFile refuses to
// run. All other internet-based functionality eventually runs through that
// function, so this is a total killswitch.

uses
  URLMon, Windows, Wininet, ActiveX, Axctrls, // Don't ask. It's just where these are.
  Classes, SysUtils;

const
  BASE_URL = 'https://www.neolemmix.com/';
  VERSION_FILE = BASE_URL + 'installer/version.php';
  STYLES_BASE_DIRECTORY = BASE_URL + 'styles/';
  STYLES_PHP_FILE = 'styles.php';

implementation

//type
//  TDownloadThread = class(TThread)
//    private
//      fSourceURL: String;
//      fStream: TMemoryStream;
//      fTargetStream: TStream;
//      fStringList: TStringList;
//
//      fComplete: Boolean;
//      fSuccess: Boolean;
//      fTerminateRequested: Boolean;
//
//      fOnComplete: TProc;
//
//      //function DownloadToStream(aURL: String; aStream: TStream): Boolean;
//    protected
//      procedure Execute; override;
//    public
//      constructor Create(aSourceURL: String; aTargetStream: TStream); overload;
//      constructor Create(aSourceURL: String; aTargetStringList: TStringList); overload;
//      destructor Destroy; override;
//
//      procedure Kill;
//
//      property Complete: Boolean read fComplete;
//      property Success: Boolean read fSuccess;
//      property OnComplete: TProc read fOnComplete write fOnComplete;
//  end;
//
//  function DownloadInThread(aURL: String; aStream: TStream; aOnComplete: TProc = nil): TDownloadThread; overload;
//  function DownloadInThread(aURL: String; aStringList: TStringList; aOnComplete: TProc = nil): TDownloadThread; overload;
//
//implementation
//
//uses
//  GameControl, LemTypes;
//
//procedure SetupDownloadThread(aThread: TDownloadThread; aOnComplete: TProc);
//begin
//  aThread.OnComplete := aOnComplete;
//  aThread.FreeOnTerminate := Assigned(aOnComplete);
//  aThread.Start;
//end;
//
//function DownloadInThread(aURL: String; aStream: TStream; aOnComplete: TProc = nil): TDownloadThread;
//begin
//  Result := TDownloadThread.Create(aURL, aStream);
//  SetupDownloadThread(Result, aOnComplete);
//end;
//
//function DownloadInThread(aURL: String; aStringList: TStringList; aOnComplete: TProc = nil): TDownloadThread;
//begin
//  Result := TDownloadThread.Create(aURL, aStringList);
//  SetupDownloadThread(Result, aOnComplete);
//end;
//
//{ TDownloadThread }
//
//constructor TDownloadThread.Create(aSourceURL: String; aTargetStream: TStream);
//begin
//  inherited Create(True);
//  FreeOnTerminate := False;
//  fStream := TMemoryStream.Create;
//  fSourceURL := aSourceURL;
//  fTargetStream := aTargetStream;
//end;
//
//constructor TDownloadThread.Create(aSourceURL: String;
//  aTargetStringList: TStringList);
//begin
//  inherited Create(True);
//  FreeOnTerminate := False;
//  fStream := TMemoryStream.Create;
//  fSourceURL := aSourceURL;
//  fStringList := aTargetStringList;
//end;
//
//destructor TDownloadThread.Destroy;
//begin
//  fStream.Free;
//  inherited;
//end;
//
//procedure TDownloadThread.Execute;
//var
//  LoadToStringList: Boolean;
//begin
//  inherited;
//  try
//    if fTargetStream = nil then
//      LoadToStringList := (fStringList <> nil)
//    else
//      LoadToStringList := False;
//
//    if not DownloadToStream(fSourceURL, fStream) then
//    begin
//      fSuccess := False;
//      fComplete := True;
//      Exit;
//    end;
//
//    fStream.Position := 0;
//
//    if LoadToStringList then
//    begin
//      fStringList.Clear;
//      fStringList.LoadFromStream(fStream);
//    end else begin
//      fTargetStream.CopyFrom(fStream, fStream.Size);
//    end;
//
//    fSuccess := True;
//  except
//    fSuccess := False;
//  end;
//
//  fComplete := True;
//
//  if Assigned(fOnComplete) then
//    fOnComplete();
//end;
//
//procedure TDownloadThread.Kill;
//begin
//  fTerminateRequested := True;
//  fOnComplete := nil;
//end;

//function TDownloadThread.DownloadToStream(aURL: String; aStream: TStream): Boolean;
//const
//  BLOCK_SIZE = 1024;
//var
//  InetHandle: Pointer;
//  URLHandle: Pointer;
//  BytesRead: Cardinal;
//  DownloadBuffer: Pointer;
//  Buffer: array [1 .. BLOCK_SIZE] of byte;
//begin
//  if not GameParams.EnableOnline then
//  begin
//    Result := False;
//    Exit;
//  end;
//
//  try
//    InetHandle := InternetOpen(PWideChar(aURL), 0, nil, nil, 0);
//    if not Assigned(InetHandle) then RaiseLastOSError;
//    try
//      URLHandle := InternetOpenUrl(InetHandle, PWideChar(aURL), nil, 0, 0, 0);
//      if not Assigned(URLHandle) then RaiseLastOSError;
//      try
//        DownloadBuffer := @Buffer;
//        repeat
//          if (not InternetReadFile(URLHandle, DownloadBuffer, BLOCK_SIZE, BytesRead)) then
//            RaiseLastOSError;
//          aStream.Write(Buffer, BytesRead);
//        until (BytesRead = 0) or fTerminateRequested;
//      finally
//        InternetCloseHandle(URLHandle);
//      end;
//    finally
//      InternetCloseHandle(InetHandle);
//    end;
//
//    Result := not fTerminateRequested;
//  except
//    Result := False;
//  end;
//end;

end.
