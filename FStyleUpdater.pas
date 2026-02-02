unit FStyleUpdater;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.Hash, System.Net.HttpClient, System.Zip,
  System.Types, System.Generics.Collections, System.NetEncoding,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls,
  LemTypes,
  LemStrings,
  SharedGlobals;

type
  TFormStyleUpdater = class(TForm)
    lvAvailableUpdates: TListView;
    lvLocalStyles: TListView;
    btnDownloadSelected: TButton;
    btnDownloadAll: TButton;
    btnClose: TButton;
    pbProgress: TProgressBar;
    lblHint: TLabel;
    procedure btnCloseClick(Sender: TObject);
    procedure btnDownloadAllClick(Sender: TObject);
    procedure btnDownloadSelectedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvAvailableUpdatesSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    fChecksumsLocal: String;
    fOnlineChecksums: TStringList;

    procedure UpdateControls;
    procedure LoadLocalStylesToList;
    procedure LoadAvailableUpdatesToList;
    procedure UpdateLocalChecksum(const StyleName, NewChecksum: string);
    procedure DownloadAndInstallStyle(const StyleName: string);
  public
    { Public declarations }
  end;

var
  FormStyleUpdater: TFormStyleUpdater;

const

  CHECKSUMS_URL = 'https://raw.githubusercontent.com/Willicious/SuperLemmix-Download/refs/heads/main/StyleManager/styles_checksums.ini';
  STYLES_URL = 'https://github.com/Willicious/SuperLemmix-Download/raw/refs/heads/main/StyleManager/';

implementation

{$R *.dfm}

procedure TFormStyleUpdater.FormCreate(Sender: TObject);
begin
  fChecksumsLocal := AppPath + SFSaveData + 'styletimes.ini';
  fOnlineChecksums := TStringList.Create;

  LoadLocalStylesToList;
  LoadAvailableUpdatesToList;
  UpdateControls;

  lblHint.Caption := 'Welcome to SuperLemmix Style Updater. Select which styles you want to download or download all';
end;

procedure TFormStyleUpdater.FormDestroy(Sender: TObject);
begin
  fOnlineChecksums.Free;
end;

procedure TFormStyleUpdater.UpdateControls;
begin
  btnDownloadSelected.Enabled :=  Assigned(lvAvailableUpdates.Selected);
  btnDownloadAll.Enabled := lvAvailableUpdates.Items.Count > 0;
end;

procedure TFormStyleUpdater.LoadLocalStylesToList;
var
  Dir: string;
  Dirs: TStringDynArray;
  Item: TListItem;
begin
  lvLocalStyles.Items.Clear;

  Dir := TPath.Combine(AppPath, SFStyles);
  if not TDirectory.Exists(Dir) then
    Exit;

  Dirs := TDirectory.GetDirectories(Dir);

  for Dir in Dirs do
  begin
    Item := lvLocalStyles.Items.Add;
    Item.Caption := TPath.GetFileName(Dir);
  end;
end;

procedure TFormStyleUpdater.lvAvailableUpdatesSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  UpdateControls;
end;

procedure TFormStyleUpdater.LoadAvailableUpdatesToList;
var
  LocalChecksums: TStringList;
  StyleFolders: TArray<string>;
  ResponseLines: TStringList;
  ResponseStream: TStringStream;
  Http: THttpClient;
  Msg: string; // temporary message to inspect lists
  styleName, localChecksum, onlineChecksum: string;
  ZipPath, StyleFolder: string;
  i, posEq: Integer;
  line, key, val: string;
  styleKey: string;
  Zip: TZipFile;
begin
  lvAvailableUpdates.Items.Clear;

  LocalChecksums := TStringList.Create;
  ResponseLines := TStringList.Create;
  Http := THttpClient.Create;
  try
    // ----------------------
    // 1) Local checksums
    // ----------------------
    if FileExists(fChecksumsLocal) then
      LocalChecksums.LoadFromFile(fChecksumsLocal)
    else
      lblHint.Caption := 'Style timestamp data unavailable. It is recommended that you download all available styles.';

    // Get all style folders first
    StyleFolders := TDirectory.GetDirectories(AppPath + SFStyles);

    for i := 0 to Length(StyleFolders) - 1 do
    begin
      StyleFolder := StyleFolders[i];
      styleKey := ExtractFileName(StyleFolder);

      if LocalChecksums.Values[styleKey] = '' then
      begin
        LocalChecksums.Values[styleKey] := '0'; // Default value
        LocalChecksums.SaveToFile(fChecksumsLocal);
      end;
    end;

    // ----------------------
    // 2) Online checksums
    // ----------------------
    ResponseStream := TStringStream.Create('', TEncoding.UTF8);
    try
      Http.Get(CHECKSUMS_URL, ResponseStream);
      ResponseStream.Position := 0;
      ResponseLines.Text := ResponseStream.DataString;
    finally
      ResponseStream.Free;
    end;

    fOnlineChecksums.Clear;

    for i := 0 to ResponseLines.Count - 1 do
    begin
      line := Trim(ResponseLines[i]);
      if line = '' then
        Continue;

      posEq := Pos('=', line);
      if posEq = 0 then
        Continue;

      key := Copy(line, 1, posEq - 1); // left of =
      // Remove trailing ".zip" safely
      if (Length(key) > 4) and (LowerCase(Copy(key, Length(key)-3, 4)) = '.zip') then
        key := Copy(key, 1, Length(key) - 4);

      val := Copy(line, posEq + 1, MaxInt);

      fOnlineChecksums.Values[key] := val;
    end;

    // ----------------------
    // 3) Compare
    // ----------------------
    for i := 0 to fOnlineChecksums.Count - 1 do
    begin
      styleName := fOnlineChecksums.Names[i];
      onlineChecksum := fOnlineChecksums.ValueFromIndex[i];
      localChecksum := LocalChecksums.Values[styleName];

      if localChecksum <> onlineChecksum then
        lvAvailableUpdates.AddItem(styleName, nil);
    end;

    if lvAvailableUpdates.Items.Count = 0 then
      lblHint.Caption := 'All of your styles are up to date!';

  finally
    LocalChecksums.Free;
    ResponseLines.Free;
    Http.Free;
  end;
end;

procedure TFormStyleUpdater.UpdateLocalChecksum(const StyleName, NewChecksum: string);
var
  Checksums: TStringList;
begin
  Checksums := TStringList.Create;
  try
    if FileExists(fChecksumsLocal) then
      Checksums.LoadFromFile(fChecksumsLocal);

    Checksums.Values[StyleName] := NewChecksum;

    Checksums.SaveToFile(fChecksumsLocal);
  finally
    Checksums.Free;
  end;
end;

procedure TFormStyleUpdater.DownloadAndInstallStyle(const StyleName: string);
var
  ZipURL, TempZipFile, StyleDir: string;
  Zip: TZipFile;
  Http: THttpClient;
  FileStream: TFileStream;
begin
  ZipURL := STYLES_URL + StyleName + '.zip';
  TempZipFile := TPath.GetTempFileName;
  StyleDir := TPath.Combine(AppPath + SFStyles, StyleName);

  Http := THttpClient.Create;
  Zip := TZipFile.Create;
  try
    // Download the zip
    pbProgress.Position := 0;
    pbProgress.Max := 100;
    lblHint.Caption := 'Downloading ' + StyleName + '...';
    Application.ProcessMessages;

    FileStream := TFileStream.Create(TempZipFile, fmCreate);
    try
      Http.Get(ZipURL, FileStream);
    finally
      FileStream.Free;
    end;

    // Delete old style folder if it exists
    if TDirectory.Exists(StyleDir) then
      TDirectory.Delete(StyleDir, True);

    // Extract zip to style folder
    Zip.Open(TempZipFile, zmRead);
    try
      Zip.ExtractAll(StyleDir);
    finally
      Zip.Close;
    end;

  finally
    Zip.Free;
    Http.Free;
    if TFile.Exists(TempZipFile) then
      TFile.Delete(TempZipFile);
  end;

  if fOnlineChecksums.Values[StyleName] <> '' then
    UpdateLocalChecksum(StyleName, fOnlineChecksums.Values[StyleName]);

  lblHint.Caption := StyleName + ' installed!';
end;

procedure TFormStyleUpdater.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFormStyleUpdater.btnDownloadSelectedClick(Sender: TObject);
var
  i: Integer;
  Item: TListItem;
begin
  lblHint.Caption := 'Downloading selected styles...';

  for i := 0 to lvAvailableUpdates.Items.Count - 1 do
  begin
    Item := lvAvailableUpdates.Items[i];
    if Assigned(Item) and Item.Selected then
      DownloadAndInstallStyle(Item.Caption);
  end;

  // Refresh lists after download
  LoadLocalStylesToList;
  LoadAvailableUpdatesToList;
  UpdateControls;

  lblHint.Caption := 'Selected styles installed successfully!';
end;

procedure TFormStyleUpdater.btnDownloadAllClick(Sender: TObject);
var
  i: Integer;
  Item: TListItem;
begin
  lblHint.Caption := 'Downloading all styles...';

  for i := 0 to lvAvailableUpdates.Items.Count - 1 do
  begin
    Item := lvAvailableUpdates.Items[i];
    if Assigned(Item) then
      DownloadAndInstallStyle(Item.Caption);
  end;

  // Refresh lists after download
  LoadLocalStylesToList;
  LoadAvailableUpdatesToList;
  UpdateControls;

  lblHint.Caption := 'All styles installed successfully!';
end;

end.
