unit FStyleManager;

interface

uses
  LemTypes, DateUtils,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ValEdit, ComCtrls;

type
  TFManageStyles = class(TForm)
    btnExit: TButton;
    lvStyles: TListView;
    btnGetSelected: TButton;
    btnUpdateAll: TButton;
    procedure btnExitClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fClearedPieceManager: Boolean;
    fLocalList: TStringList;
    fWebList: TStringList;

    procedure ClearPieceManager;
    procedure ResizeListColumns;
    procedure MakeStyleList;
  public
    { Public declarations }
  end;

implementation

uses
  LemStrings,
  LemNeoOnline,
  LemVersion,
  LemNeoPieceManager;

{$R *.dfm}

procedure TFManageStyles.btnExitClick(Sender: TObject);
begin
  Close;
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
  if (fLocalList.Count > 1) or FileExists(AppPath + SFSaveData + 'styletimes.ini') then
    fLocalList.SaveToFile(AppPath + SFSaveData + 'styletimes.ini');
end;

procedure TFManageStyles.FormCreate(Sender: TObject);
begin
  fLocalList := TStringList.Create;
  fWebList := TStringList.Create;
  fLocalList.Sorted := true;
  fWebList.Sorted := true;
end;

procedure TFManageStyles.FormDestroy(Sender: TObject);
begin
  fLocalList.Free;
  fWebList.Free;
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
  TInternet.DownloadToStringList(STYLES_BASE_DIRECTORY + STYLE_VERSION + STYLES_PHP_FILE, fWebList);

  StyleList := TStringList.Create;
  try
    for n := 0 to fLocalList.Count-1 do
      StyleList.Add(fLocalList.Names[n]);

    for n := 0 to fWebList.Count-1 do
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

end.
