unit FStyleManager;

interface

uses
  LemNeoOnline,
  Zip,
  LemTypes, DateUtils,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ValEdit, ComCtrls, Vcl.ExtCtrls;

type
  TFManageStyles = class(TForm)
    btnExit: TButton;
    lvStyles: TListView;
    btnGetSelected: TButton;
    btnUpdateAll: TButton;
    pbDownload: TProgressBar;
    tmContinueDownload: TTimer;
    procedure btnExitClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGetSelectedClick(Sender: TObject);
    procedure tmContinueDownloadTimer(Sender: TObject);
  private
    fClearedPieceManager: Boolean;
    fLocalList: TStringList;
    fWebList: TStringList;

    fDownloadThread: TDownloadThread;
    fDownloadList: TStringList;
    fDownloadIndex: Integer;

    fTimeForNextDownload: Boolean;

    procedure ClearPieceManager;
    procedure ResizeListColumns;
    procedure MakeStyleList;
    procedure SaveLocalList;

    procedure BeginDownloads;
    procedure BeginNextDownload;
    procedure EndDownloads;
  public
    { Public declarations }
  end;

implementation

uses
  GameControl,
  LemStrings,
  LemVersion,
  LemNeoPieceManager;

{$R *.dfm}

procedure TFManageStyles.BeginDownloads;
begin
  fDownloadIndex := 0;
  btnGetSelected.Enabled := false;
  btnUpdateAll.Enabled := false;
  btnExit.Caption := 'Cancel';
  pbDownload.Visible := true;
  tmContinueDownload.Enabled := true;
  fLocalList.Sorted := false;
  BeginNextDownload;
end;

procedure TFManageStyles.EndDownloads;
begin
  fDownloadIndex := -1;
  SaveLocalList;
  MakeStyleList;
  btnGetSelected.Enabled := true;
  btnUpdateAll.Enabled := true;
  btnExit.Caption := 'Exit';
  pbDownload.Visible := false;
  tmContinueDownload.Enabled := false;
  fLocalList.Sorted := true;
end;

procedure TFManageStyles.BeginNextDownload;
var
  S: TMemoryStream;
begin
  pbDownload.Position := fDownloadIndex * pbDownload.Max div fDownloadList.Count;

  if fDownloadIndex >= fDownloadList.Count then
  begin
    EndDownloads;
    Exit;
  end;

  S := TMemoryStream.Create;
  try
    fDownloadThread := DownloadInThread(STYLES_BASE_DIRECTORY + STYLE_VERSION + fDownloadList[fDownloadIndex] + '.zip', S,
    procedure
    var
      Zip: TZipFile;
    begin
      Zip := TZipFile.Create;
      try
        try
          S.Position := 0;
          Zip.Open(S, zmRead);
          Zip.ExtractAll(AppPath);
          Zip.Close;
        except
          on E: Exception do
            ShowMessage(E.ClassName + ': ' + E.Message);
        end;
        try
          fLocalList.Values[fDownloadList[fDownloadIndex]] := fWebList.Values[fDownloadList[fDownloadIndex]];
        except
          // Fail silently here.
        end;
      finally
        Zip.Free;
      end;

      fDownloadThread := nil;

      Inc(fDownloadIndex);
      fTimeForNextDownload := true;
    end
    );
  finally
    S.Free;
  end;
end;

procedure TFManageStyles.btnExitClick(Sender: TObject);
begin
  if fDownloadIndex < 0 then
    Close
  else begin
    if fDownloadThread <> nil then
      fDownloadThread.Terminate;
    EndDownloads;
  end;
end;

procedure TFManageStyles.btnGetSelectedClick(Sender: TObject);
var
  i: Integer;
begin
  fDownloadList.Clear;
  for i := 0 to lvStyles.Items.Count-1 do
    if lvStyles.Items[i].Selected then
      fDownloadList.Add(lvStyles.Items[i].Caption);

  BeginDownloads;
end;

procedure TFManageStyles.ClearPieceManager;
begin
  if not fClearedPieceManager then
  begin
    PieceManager.Clear;
    fClearedPieceManager := true;
  end;
end;

procedure TFManageStyles.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ClearPieceManager;
  SaveLocalList;
end;

procedure TFManageStyles.FormCreate(Sender: TObject);
begin
  fLocalList := TStringList.Create;
  fWebList := TStringList.Create;
  fDownloadList := TStringList.Create;

  fLocalList.Sorted := true;
  fWebList.Sorted := true;

  fDownloadList.Sorted := true;
  fDownloadList.Duplicates := dupIgnore;

  fDownloadIndex := -1;

  if not GameParams.EnableOnline then
  begin
    btnGetSelected.Enabled := false;
    btnUpdateAll.Enabled := false;
  end;
end;

procedure TFManageStyles.FormDestroy(Sender: TObject);
begin
  fLocalList.Free;
  fWebList.Free;
  fDownloadList.Free;
end;

procedure TFManageStyles.FormResize(Sender: TObject);
begin
  ResizeListColumns;
end;

procedure TFManageStyles.FormShow(Sender: TObject);
begin
  ResizeListColumns;
  MakeStyleList;
end;

procedure TFManageStyles.MakeStyleList;
var
  SearchRec: TSearchRec;
  ThisStyle: String;

  StyleList: TStringList;
  n: Integer;

  NewItem: TListItem;
  NewString: String;
begin
  if FileExists(AppPath + SFSaveData + 'styletimes.ini') then
    fLocalList.LoadFromFile(AppPath + SFSaveData + 'styletimes.ini')
  else
    fLocalList.Clear;

  if FindFirst(AppPath + SFStyles + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') or ((SearchRec.Attr and faDirectory) = 0) then Continue;

      if fLocalList.IndexOfName(SearchRec.Name) < 0 then
        fLocalList.Add(SearchRec.Name + '=-1');
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  fWebList.Clear;
  if GameParams.EnableOnline then
    TInternet.DownloadToStringList(STYLES_BASE_DIRECTORY + STYLE_VERSION + STYLES_PHP_FILE, fWebList);

  StyleList := TStringList.Create;
  try
    for n := 0 to fLocalList.Count-1 do
      if Trim(fLocalList.Names[n]) <> '' then
        StyleList.Add(fLocalList.Names[n]);

    for n := 0 to fWebList.Count-1 do
      if Trim(fWebList.Names[n]) <> '' then
        if StyleList.IndexOf(fWebList.Names[n]) < 0 then
          StyleList.Add(fWebList.Names[n]);

    StyleList.Sort;

    for n := 0 to PieceManager.NeedCheckStyles.Count-1 do
    begin
      ThisStyle := PieceManager.NeedCheckStyles[n];

      if StyleList.IndexOf(ThisStyle) < 0 then
        StyleList.Insert(n, ThisStyle)
      else
        StyleList.Move(StyleList.IndexOf(ThisStyle), n);
    end;

    lvStyles.Clear;

    for ThisStyle in StyleList do
    begin
      lvStyles.AddItem(ThisStyle, nil);
      NewItem := lvStyles.Items[lvStyles.Items.Count-1];

      NewString := '';
      if fLocalList.IndexOfName(ThisStyle) >= 0 then
        if fLocalList.Values[ThisStyle] = '-1' then
          NewString := 'Manual'
        else
          DateTimeToString(NewString, 'yyyy-mm-dd hh:nn', UnixToDateTime(StrToInt64Def(fLocalList.Values[ThisStyle], 0)));
      NewItem.SubItems.Add(NewString);

      NewString := '';
      if fWebList.IndexOfName(ThisStyle) >= 0 then
        DateTimeToString(NewString, 'yyyy-mm-dd hh:nn', UnixToDateTime(StrToInt64Def(fWebList.Values[ThisStyle], 0)));
      NewItem.SubItems.Add(NewString);
    end;
  finally
    StyleList.Free;
  end;
end;

procedure TFManageStyles.ResizeListColumns;
var
  BaseWidth: Integer;
begin
  BaseWidth := (lvStyles.Width - 22) * 2 div 7;

  lvStyles.Columns[0].MaxWidth := lvStyles.Width - 22 - (BaseWidth * 2);
  lvStyles.Columns[0].MinWidth := lvStyles.Columns[0].MaxWidth;
  lvStyles.Columns[0].Width := lvStyles.Columns[0].MaxWidth;

  lvStyles.Columns[1].MaxWidth := BaseWidth;
  lvStyles.Columns[1].MinWidth := lvStyles.Columns[1].MaxWidth;
  lvStyles.Columns[1].Width := lvStyles.Columns[1].MaxWidth;

  lvStyles.Columns[2].MaxWidth := BaseWidth;
  lvStyles.Columns[2].MinWidth := lvStyles.Columns[2].MaxWidth;
  lvStyles.Columns[2].Width := lvStyles.Columns[2].MaxWidth;
end;

procedure TFManageStyles.SaveLocalList;
begin
  if (fLocalList.Count > 1) or FileExists(AppPath + SFSaveData + 'styletimes.ini') then
    fLocalList.SaveToFile(AppPath + SFSaveData + 'styletimes.ini');
end;

procedure TFManageStyles.tmContinueDownloadTimer(Sender: TObject);
begin
  if fTimeForNextDownload then
  begin
    fTimeForNextDownload := false;
    BeginNextDownload;
  end;
end;

end.
