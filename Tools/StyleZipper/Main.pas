unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  StyleZipCore;

type
  TFormStyleZipper = class(TForm)
    btnRunStyleZipper: TButton;
    rbSuperLemmix: TRadioButton;
    rbRetroLemmini: TRadioButton;
    lblStyles: TLabel;
    lblStylesDirectory: TLabel;
    cbDeleteUnchanged: TCheckBox;
    cbMakeAllStylesZip: TCheckBox;
    cbRepackPNG: TCheckBox;
    edRepackPNGs: TEdit;
    lblRepackPNG: TLabel;
    lblZIPOutput: TLabel;
    lblOutputDirectory: TLabel;
    lblStyleTimesPath: TLabel;
    lblChecksums: TLabel;
    lblZIPChecksumsPath: TLabel;
    lblProgress: TLabel;
    btnUpdateStyleManager: TButton;
    btnClose: TButton;
    procedure btnRunStyleZipperClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioButtonClick(Sender: TObject);
    procedure btnUpdateStyleManagerClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormStyleZipper: TFormStyleZipper;

implementation

{$R *.dfm}

procedure TFormStyleZipper.FormCreate(Sender: TObject);
  var
    ChooseApp: String;
begin
  ChooseApp := 'Choose an app to set the directory';
  lblStylesDirectory.Caption := ChooseApp;
  lblOutputDirectory.Caption := ChooseApp;
  lblStyleTimesPath.Caption := ChooseApp;
  lblZIPChecksumsPath.Caption := ChooseApp;

  ChooseApp := 'Choose an app to initialize Style Zipper';
  lblProgress.Caption := ChooseApp;
  lblProgress.Font.Color := clBlue;
  btnRunStyleZipper.Enabled := False;
  btnUpdateStyleManager.Enabled := False;

  if not (DirectoryExists(AppPath + 'resources\')) then
  begin
    rbRetroLemmini.Enabled := False;
    rbRetroLemmini.Caption := 'RetroLemmini (RetroLemmini resources not detected in app folder)'
  end else
    rbRetroLemmini.Checked := True;

  if not (FileExists(AppPath + 'SuperLemmix.exe')) then
  begin
    rbSuperLemmix.Enabled := False;
    rbSuperLemmix.Caption := 'SuperLemmix (SuperLemmix.exe not detected in app folder)'
  end else
    rbSuperLemmix.Checked := True;
end;

procedure TFormStyleZipper.RadioButtonClick(Sender: TObject);
var
  StyleTimesDirectory, ZipChecksumsDirectory: String;
begin
  if (rbSuperLemmix.Checked) then
  begin
    StylesDirectory := AppPath + 'styles\';
    OutputDirectory := AppPath + 'style_zips\';
    StyleTimesDirectory := ExpandFileName(AppPath + '..\data\external\styles\');
    ZipChecksumsDirectory := ExpandFileName(AppPath + '..\data\');
  end else if (rbRetroLemmini.Checked) then
  begin
    StylesDirectory := ExpandFileName(AppPath + '..\src\resources\styles\');
    OutputDirectory := AppPath + 'style_zips\';
    StyleTimesDirectory := StylesDirectory;
    ZipChecksumsDirectory := ExpandFileName(AppPath + '..\src\');

    cbMakeAllStylesZip.Checked := True;
  end;

  StyleTimesINI := StyleTimesDirectory + 'styletimes.ini';
  ZipChecksumsINI := ZipChecksumsDirectory + 'styles_checksums.ini';

  lblStylesDirectory.Caption := StylesDirectory;
  lblOutputDirectory.Caption := OutputDirectory;
  lblStyleTimesPath.Caption := StyleTimesINI;
  lblZIPChecksumsPath.Caption := ZIPChecksumsINI;

  lblProgress.Caption := 'Choose settings and click "Run Style Zipper" when ready';
  lblProgress.Font.Color := clGreen;
  btnRunStyleZipper.Enabled := True;
end;

procedure TFormStyleZipper.btnCloseClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFormStyleZipper.btnRunStyleZipperClick(Sender: TObject);
begin
  btnRunStyleZipper.Enabled := False;

  try
    DeleteUnchanged := cbDeleteUnchanged.Checked;
    MakeAllStyles := cbMakeAllStylesZip.Checked;
    RepackPNG := cbRepackPNG.Checked;
    RepackPNGList := edRepackPNGs.Text;

    RunStyleZipper;
  except
    on E: Exception do
      ShowMessage(E.ClassName + ': ' + E.Message);
  end;

  lblProgress.Caption := 'All done! Style Manager can now be updated';
  btnUpdateStyleManager.Enabled := True;
end;

procedure TFormStyleZipper.btnUpdateStyleManagerClick(Sender: TObject);
var
  S, Bat, StylesZip, TargetZip, TargetPath: String;

  function GetSuperParent(const Dir: string): string;
  begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(ExcludeTrailingPathDelimiter(Dir)))));
  end;
begin
  btnUpdateStyleManager.Enabled := False;
  S := 'Style Manager updated - check styles.zip and commit to repo. StyleZipper can now be closed.';

  Bat := AppPath + 'UpdateStyleManager.bat';

  if not FileExists(AppPath + 'UpdateStyleManager.bat') then
  begin
    if (rbRetroLemmini.Checked) then
    begin
      TargetPath := GetSuperParent(OutputDirectory);
      TargetZip := TargetPath + 'styles.zip';
      StylesZip := OutputDirectory + 'styles.zip';

      if FileExists(StylesZip) then
      begin
        if FileExists(TargetZip) then
          DeleteFile(TargetZip);

        RenameFile(StylesZip, TargetZip);

        if FileExists(TargetZip) then
        begin
          lblProgress.Caption := S;
          Exit;
        end;
      end;
    end;

    lblProgress.Caption := 'Batch file not found: ' + AppPath + 'UpdateStyleManager.bat';
    lblProgress.Font.Color := clBlue;
    Exit;
  end;

  ShellExecute(Handle, 'open', PChar(Bat), nil, nil, SW_SHOWNORMAL);
  lblProgress.Caption := S;
end;

end.
