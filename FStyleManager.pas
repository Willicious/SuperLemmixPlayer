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
    procedure ClearPieceManager;
    procedure ResizeListColumns;
  public
    { Public declarations }
  end;

implementation

uses
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
var
  SL: TStringList;
begin
  ResizeListColumns;

  SL := TStringList.Create;
  try
    TInternet.DownloadToStringList(STYLES_BASE_DIRECTORY + STYLE_VERSION + STYLES_PHP_FILE, SL);
    SL.SaveToFile(AppPath + 'blah.txt');
  finally
    SL.Free;
  end;
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
