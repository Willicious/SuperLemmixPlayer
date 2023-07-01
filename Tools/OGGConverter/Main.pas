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
    btnOpen: TButton;
    procedure btnConvertClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
  private
    { Private declarations }
    FSourceFiles: TStringList;
    procedure ConvertFilesToOGG;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Initialize the BASS library
  if not BASS_Init(-1, 44100, 0, Handle, nil) then
  begin
    ShowMessage('BASS initialization failed!');
    Exit;
  end;

  Application.Title := 'OGG Converter';
  FSourceFiles := TStringList.Create;
end;

destructor TForm1.Destroy;
begin
  BASS_Free;
  FSourceFiles.Free;
  inherited Destroy;
end;

procedure TForm1.btnConvertClick(Sender: TObject);
begin
  if FSourceFiles.Count = 0 then
  begin
    ShowMessage('Please select one or more source files.');
    Exit;
  end;

  // Disable the Convert button to prevent multiple clicks
  btnConvert.Enabled := False;

  // Reset the progress bar and caption
  pbProgress.Position := 0;

  // Call the conversion procedure for the selected files
  ConvertFilesToOGG;
end;

procedure TForm1.btnOpenClick(Sender: TObject);
var
  i: Integer;
begin
  // Show the Open dialog to select the input files
  if Open.Execute then
  begin
    FSourceFiles.Clear;
    for i := 0 to Open.Files.Count - 1 do
      FSourceFiles.Add(Open.Files[i]);
    lblStatus.Caption := 'Selected Files: ' + IntToStr(FSourceFiles.Count);
  end;
end;

procedure TForm1.ConvertFilesToOGG;
var
  i: Integer;
  n: Integer;
  FileExt, TargetFile: string;
  StreamHandle: HSTREAM;
  ProgressData: TProgressData;
  ErrorCode: Integer;
  ConversionDetails: TStringList;
  ErrorOccurred: Boolean;

  procedure UpdateProgressCallback(handle: HENCODE; progress: DWORD; user: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  begin
    ProgressData.Progress := progress / 100;
    pbProgress.Position := Round(pbProgress.Max * ProgressData.Progress);
  end;

  procedure ResetProgramState;
  begin
    lblStatus.Caption := 'Ready';
    btnConvert.Enabled := True;
    pbProgress.Position := 0;
  end;

begin
  ErrorOccurred := False;

  ConversionDetails := TStringList.Create;
  try
    // Process each selected source file
    for i := 0 to FSourceFiles.Count - 1 do
    begin
      FileExt := LowerCase(ExtractFileExt(FSourceFiles[i]));
      TargetFile := ChangeFileExt(FSourceFiles[i], '.ogg');

      // Load the source audio file with the BASS_STREAM_DECODE flag
      StreamHandle := BASS_StreamCreateFile(False, PChar(FSourceFiles[i]), 0, 0, BASS_UNICODE or BASS_STREAM_DECODE);
      if StreamHandle = 0 then
      begin
        ErrorOccurred := True;
        ErrorCode := BASS_ErrorGetCode;
        if (FileExt = '.mod') or (FileExt = '.it') then
          ConversionDetails.Add(Format('Unsupported format: "%s" Error code: %d', [ExtractFileName(FSourceFiles[i]), ErrorCode]))
        else
          ConversionDetails.Add(Format('Error loading source audio file: "%s" Error code: %d', [ExtractFileName(FSourceFiles[i]), ErrorCode]));
        Continue; // Move to the next file
      end;

      try
        // Start the conversion process
        if BASS_Encode_OGG_StartFile(StreamHandle, nil, BASS_ENCODE_AUTOFREE or BASS_UNICODE, PChar(TargetFile)) = 0 then
        begin
          ErrorOccurred := True;
          ErrorCode := BASS_ErrorGetCode;
          ConversionDetails.Add(Format('Error starting the conversion for file "%s" Error code: %d', [ExtractFileName(FSourceFiles[i]), ErrorCode]));
          Continue; // Move to the next file
        end;

        // Conversion in progress
        lblStatus.Caption := 'Converting file ' + IntToStr(i + 1) + ' of ' + IntToStr(FSourceFiles.Count) + '...';
        btnConvert.Enabled := False;

        // Set progress bar properties
        pbProgress.Min := 0;
        pbProgress.Max := Bass_ChannelGetLength(StreamHandle, BASS_POS_BYTE);
        pbProgress.Position := 0;

        // Update the progress bar
        while BASS_ChannelIsActive(StreamHandle) = BASS_ACTIVE_PLAYING do
        begin
          BASS_ChannelGetLevel(StreamHandle); // process the stream (decode and encode)
          pbProgress.Position := BASS_ChannelGetPosition(StreamHandle, BASS_POS_BYTE);
          Application.ProcessMessages;
        end;

        // Conversion completed for the current file
        ConversionDetails.Add(Format('Conversion successful for file "%s" File saved as: %s', [ExtractFileName(FSourceFiles[i]), ExtractFileName(TargetFile)]));
      finally
        // Cleanup
        BASS_Encode_Stop(StreamHandle);
        BASS_StreamFree(StreamHandle);
      end;
    end;

    // Some files couldn't be converted
    if ErrorOccurred then
      ShowMessage('Some files could not be converted. See details below:' + sLineBreak + sLineBreak + ConversionDetails.Text)
    else
      // All files successfully converted
      ShowMessage('Files successfully converted!' + sLineBreak + sLineBreak + ConversionDetails.Text);
  finally
    ConversionDetails.Free;
    ResetProgramState;
  end;
end;

end.

