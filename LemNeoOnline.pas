unit LemNeoOnline;

interface

uses
  Classes, SysUtils;

type
  TDownloadThread = class(TThread)
    private
      fSourceURL: String;
      fStream: TStream;

      fCancel: Boolean;
      fComplete: Boolean;
      fSuccess: Boolean;
    protected
      procedure Execute; override;
    public
      constructor Create(aSourceURL: String; aTargetStream: TStream);
      destructor Destroy; override;

      procedure Cancel;
  end;

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

destructor TDownloadThread.Destroy;
begin

  inherited;
end;

procedure TDownloadThread.Execute;
begin
  inherited;

end;

end.
