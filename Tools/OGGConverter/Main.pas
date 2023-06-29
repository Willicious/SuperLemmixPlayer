unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtDlgs, Vcl.Buttons;

type
  TForm1 = class(TForm)
    btnConvert: TBitBtn;
    pbProgress: TProgressBar;
    lblStatus: TLabel;
    Open: TOpenDialog;
    Save: TSaveDialog;
    btnOpen: TButton;
    btnSave: TButton;
    procedure btnConvertClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
    FSourceFile: string;
    FTargetFile: string;
    procedure ConvertToOGG(const SourceFile, TargetFile: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  Bass, Bassenc, Bassenc_OGG;

type
  TProgressData = record
    StreamHandle: HSTREAM;
    Progress: Single;
  end;
  PProgressData = ^TProgressData;

const
  BASS_ACTIVE_ENCODE = 1;

procedure TForm1.btnConvertClick(Sender: TObject);
begin
  if FSourceFile = '' then
  begin
    ShowMessage('Please select a source file.');
    Exit;
  end;

  if FTargetFile = '' then
  begin
    ShowMessage('Please select a target file.');
    Exit;
  end;

  // Call the conversion procedure
  ConvertToOGG(FSourceFile, FTargetFile);
end;

procedure TForm1.btnOpenClick(Sender: TObject);
begin
  // Show the Open dialog to select the input file
  if Open.Execute then
  begin
    FSourceFile := Open.FileName;
    lblStatus.Caption := FSourceFile;
  end;
end;

procedure TForm1.btnSaveClick(Sender: TObject);
begin
  // Show the Save dialog to specify the output file
  Save.Filter := 'OGG files|*.ogg';
  Save.DefaultExt := 'ogg';

  // Show the Save dialog to select the output file
  if Save.Execute then
  begin
    FTargetFile := Save.FileName;
    lblStatus.Caption := FTargetFile;
  end;
end;

//procedure TForm1.ConvertToOGG(const SourceFile, TargetFile: string);
//var
//  StreamHandle: HSTREAM;
//  ProgressData: TProgressData;
//  ErrorCode: Integer;
//
//  procedure UpdateProgressCallback(handle: HENCODE; progress: DWORD; user: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
//  begin
//    ProgressData.Progress := progress / 100;
//    pbProgress.Position := Round(pbProgress.Max * ProgressData.Progress);
//  end;
//
//begin
//  // Initialize the BASS library
//  if not BASS_Init(-1, 44100, 0, Handle, nil) then
//  begin
//    ShowMessage('BASS initialization failed!');
//    Exit;
//  end;
//
//  // Load the source audio file
//  StreamHandle := BASS_StreamCreateFile(False, PChar(SourceFile), 0, 0, BASS_UNICODE);
//  ErrorCode := BASS_ErrorGetCode;
//  if StreamHandle = 0 then
//  begin
//    ShowMessageFmt('Error loading source audio file! Error code: %d', [ErrorCode]);
//    Exit;
//  end else
//    ShowMessage('File loaded successfully');
//
//  // Start the conversion process
//  if BASS_Encode_OGG_StartFile(StreamHandle, nil, BASS_ENCODE_AUTOFREE or BASS_UNICODE, PChar(TargetFile)) = 0 then
//  begin
//    ErrorCode := BASS_ErrorGetCode;
//    ShowMessageFmt('Error starting the conversion! Error code: %d', [ErrorCode]);
//    BASS_StreamFree(StreamHandle);
//    Exit;
//  end;
//
//  // Conversion in progress
//  lblStatus.Caption := 'Converting...';
//  btnConvert.Enabled := False;
//
//  // Set progress bar properties
//  pbProgress.Min := 0;
//  pbProgress.Max := 100;
//  pbProgress.Position := 0;
//
//  // Update the progress bar while the conversion is in progress
//  while BASS_Encode_IsActive(StreamHandle) = DWORD(BASS_ACTIVE_ENCODE) do
//  begin
//    Application.ProcessMessages;
//  end;
//
//  // Conversion completed
//  lblStatus.Caption := 'Conversion completed!';
//  btnConvert.Enabled := True;
//
//  // Cleanup
//  BASS_Encode_Stop(StreamHandle);
//  BASS_StreamFree(StreamHandle);
//  BASS_Free;
//end;

procedure TForm1.ConvertToOGG(const SourceFile, TargetFile: string);
var
  StreamHandle: HSTREAM;
  ProgressData: TProgressData;
  ErrorCode: Integer;

  procedure UpdateProgressCallback(handle: HENCODE; progress: DWORD; user: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  begin
    ProgressData.Progress := progress / 100;
    pbProgress.Position := Round(pbProgress.Max * ProgressData.Progress);
  end;

begin
  // Initialize the BASS library
  if not BASS_Init(-1, 44100, 0, Handle, nil) then
  begin
    ShowMessage('BASS initialization failed!');
    Exit;
  end;

  // Load the source audio file with the BASS_STREAM_DECODE flag
  StreamHandle := BASS_StreamCreateFile(False, PChar(SourceFile), 0, 0, BASS_UNICODE or BASS_STREAM_DECODE);
  ErrorCode := BASS_ErrorGetCode;
  if StreamHandle = 0 then
  begin
    ShowMessageFmt('Error loading source audio file! Error code: %d', [ErrorCode]);
    Exit;
  end else
    ShowMessage('File loaded successfully');

  // Start the conversion process
  if BASS_Encode_OGG_StartFile(StreamHandle, nil, BASS_ENCODE_AUTOFREE or BASS_UNICODE, PChar(TargetFile)) = 0 then
  begin
    ErrorCode := BASS_ErrorGetCode;
    ShowMessageFmt('Error starting the conversion! Error code: %d', [ErrorCode]);
    BASS_StreamFree(StreamHandle);
    Exit;
  end;

  // Conversion in progress
  lblStatus.Caption := 'Converting...';
  btnConvert.Enabled := False;

// Set progress bar properties
  pbProgress.Min := 0;
  pbProgress.Max := 100; //Bass_ChannelGetLength(Chan,BASS_POS_BYTE);
  pbProgress.Position := 0;

  // Update the progress bar
  while BASS_ChannelIsActive(StreamHandle) = BASS_ACTIVE_PLAYING do
  begin
    BASS_ChannelGetLevel(StreamHandle); // process the stream (decode and encode)
    //pbProgress.Position := BASS_ChannelGetPosition(Chan, BASS_POS_BYTE);
    Application.ProcessMessages;
  end;

  // Conversion completed
  lblStatus.Caption := 'Conversion completed!';
  btnConvert.Enabled := True;

  // Cleanup
  BASS_Encode_Stop(StreamHandle);
  BASS_StreamFree(StreamHandle);
  BASS_Free;
end;

end.
