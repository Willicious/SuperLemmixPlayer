unit FStyleManager;

interface

uses
  LemTypes,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ValEdit, ComCtrls;

type
  TFManageStyles = class(TForm)
    btnExit: TButton;
    lvStyles: TListView;
    procedure btnExitClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
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

  for ThisStyle in PieceManager.NeedCheckStyles do
    if fLocalList.IndexOfName(ThisStyle) < 0 then
      fLocalList.Add(ThisStyle + '=-2');

  fWebList.Clear;
  TInternet.DownloadToStringList(STYLES_BASE_DIRECTORY + STYLE_VERSION + STYLES_PHP_FILE, fWebList);
end;

procedure TFManageStyles.ResizeListColumns;
var
  BaseWidth: Integer;
begin
  BaseWidth := (lvStyles.Width - 4) * 2 div 7;

  lvStyles.Columns[0].MaxWidth := lvStyles.Width - 4 - (BaseWidth * 2);
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
