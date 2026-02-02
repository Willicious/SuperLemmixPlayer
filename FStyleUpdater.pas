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
  private
    { Private declarations }
    fChecksumsLocal: String;

    procedure UpdateControls;
    procedure LoadLocalStylesToList;
    procedure LoadAvailableUpdatesToList;
  public
    { Public declarations }
  end;

var
  FormStyleUpdater: TFormStyleUpdater;

const

  CHECKSUMS_URL = 'https://raw.githubusercontent.com/Willicious/SuperLemmix-Download/refs/heads/main/StyleManager/styles_checksums.ini';
  //STYLES_URL = '';

implementation

{$R *.dfm}

procedure TFormStyleUpdater.FormCreate(Sender: TObject);
begin
  fChecksumsLocal := AppPath + SFSaveData + 'styletimes.ini';

  LoadLocalStylesToList;
  LoadAvailableUpdatesToList;
  UpdateControls;

  lblHint.Caption := 'Welcome to SuperLemmix Style Updater. Select which styles you want to download or download all';
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
  LocalChecksums, OnlineChecksums: TStringList;
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
  OnlineChecksums := TStringList.Create;
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

    OnlineChecksums.Clear;

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

      OnlineChecksums.Values[key] := val;
    end;

    // ----------------------
    // 3) Compare
    // ----------------------
    for i := 0 to OnlineChecksums.Count - 1 do
    begin
      styleName := OnlineChecksums.Names[i];
      onlineChecksum := OnlineChecksums.ValueFromIndex[i];
      localChecksum := LocalChecksums.Values[styleName];

      if localChecksum <> onlineChecksum then
        lvAvailableUpdates.AddItem(styleName, nil);
    end;

    if lvAvailableUpdates.Items.Count = 0 then
      lblHint.Caption := 'All of your styles are up to date!';

  finally
    LocalChecksums.Free;
    OnlineChecksums.Free;
    ResponseLines.Free;
    Http.Free;
  end;
end;

//procedure ReplaceStyle(const StyleName: string);
//var
//  ZipURL, ZipFile, StyleDir: string;
//begin
//  ZipURL := STYLES_URL + StyleName + '.zip';
//  ZipFile := TPath.GetTempFileName;
//  StyleDir := TPath.Combine(AppPath + SFStyles, StyleName);
//
//  // 1) Download zip
//  // 2) Delete StyleDir
//  // 3) Extract zip to SFStyles
//end;

procedure TFormStyleUpdater.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFormStyleUpdater.btnDownloadAllClick(Sender: TObject);
begin
  lblHint.Caption := 'Downloading all styles...';
  Exit;
  // This should download only the styles which
  // have been determined as different by the checksum check
  // (and so are appearing in lvAvailableUpdates)
  // and extract them to AppPath + SFStyles
end;

procedure TFormStyleUpdater.btnDownloadSelectedClick(Sender: TObject);
begin
  lblHint.Caption := 'Downloading selected styles...';
  Exit;
  // This should download only the styles which
  // the user has selected (multi-select is possible)
end;

end.
