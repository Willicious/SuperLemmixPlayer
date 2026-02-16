unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
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
    procedure btnRunStyleZipperClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioButtonClick(Sender: TObject);
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

  if not (FileExists(AppPath + 'SuperLemmix.exe')) then
  begin
    rbSuperLemmix.Enabled := False;
    rbSuperLemmix.Caption := 'SuperLemmix (SuperLemmix.exe not detected in app folder)'
  end;

  if not (DirectoryExists(AppPath + 'resources\')) then
  begin
    rbRetroLemmini.Enabled := False;
    rbRetroLemmini.Caption := 'RetroLemmini (RetroLemmini resources not detected in app folder)'
  end;

  ChooseApp := 'Choose an app to initialize Style Zipper';
  lblProgress.Caption := ChooseApp;
  lblProgress.Font.Color := clBlue;
  btnRunStyleZipper.Enabled := False;
end;

procedure TFormStyleZipper.RadioButtonClick(Sender: TObject);
var
  StyleTimesDirectory, ZipChecksumsDirectory: String;
begin
  StylesDirectory := AppPath + 'styles\';
  OutputDirectory := AppPath + 'style_zips\';

  if (rbSuperLemmix.Checked) then
  begin
    StyleTimesDirectory := ExpandFileName(AppPath + '..\data\external\styles\');
    ZipChecksumsDirectory := ExpandFileName(AppPath + '..\data\');
  end else if (rbRetroLemmini.Checked) then
  begin
    StyleTimesDirectory := '..\src\resources\styles\';
    ZipChecksumsDirectory := '..\src\';
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

  lblProgress.Caption := 'All done!';
  btnRunStyleZipper.Enabled := True;
end;

end.
