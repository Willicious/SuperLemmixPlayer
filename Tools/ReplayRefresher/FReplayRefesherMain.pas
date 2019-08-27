unit FReplayRefesherMain;

interface

uses
  LemTypes, LemStrings, LemReplay,
  Math,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFNLReplayRefresher = class(TForm)
    lbReplays: TListBox;
    btnAddReplay: TButton;
    btnRemoveReplay: TButton;
    lblUsername: TLabel;
    ebUsername: TEdit;
    lblUsernameInfo: TLabel;
    cbBackup: TCheckBox;
    btnOK: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure btnRemoveReplayClick(Sender: TObject);
    procedure btnAddReplayClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    fInitialWidth: Integer;
    fInitialHeight: Integer;
  public
    { Public declarations }
  end;

var
  FNLReplayRefresher: TFNLReplayRefresher;

implementation

{$R *.dfm}

procedure TFNLReplayRefresher.btnAddReplayClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  i: Integer;
begin
  OpenDlg := TOpenDialog.Create(self);
  try
    OpenDlg.Title := 'Select NeoLemmix replays';
    OpenDlg.Filter := 'NeoLemmix Replays (*.nxrp, *.lrb)|*.nxrp;*.lrb';
    OpenDlg.Options := [ofHideReadOnly, ofAllowMultiSelect];
    OpenDlg.InitialDir := AppPath;

    if not OpenDlg.Execute then Exit;

    lbReplays.Items.BeginUpdate;
    try
      for i := 0 to OpenDlg.Files.Count-1 do
        lbReplays.Items.Add(OpenDlg.Files[i]);
    finally
      lbReplays.Items.EndUpdate;
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TFNLReplayRefresher.btnOKClick(Sender: TObject);
var
  i: Integer;
  Replay: TReplay;
begin
  if ebUsername.Text = '' then
  begin
    ShowMessage('Please enter a username.');
    Exit;
  end;

  for i := 0 to lbReplays.Items.Count-1 do
  try
    Replay := TReplay.Create;
    try
      if Lowercase(ExtractFileExt(lbReplays.Items[i])) = '.lrb'  then
        Replay.LoadOldReplayFile(lbReplays.Items[i])
      else
        Replay.LoadFromFile(lbReplays.Items[i]);

      if cbBackup.Checked then
      begin
        if FileExists(lbReplays.Items[i] + '.bak') then
          DeleteFile(lbReplays.Items[i] + '.bak');
        RenameFile(lbReplays.Items[i], lbReplays.Items[i] + '.bak');
      end else
        DeleteFile(lbReplays.Items[i]);

      if Replay.PlayerName = '' then
        Replay.PlayerName := ebUsername.Text;
      Replay.SaveToFile(ChangeFileExt(lbReplays.Items[i], '.nxrp'));
    finally
      Replay.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Exception when refreshing ' + ExtractFileName(lbReplays.Items[i]) + #10 + E.Message);
  end;

  ShowMessage('Refresh complete.');
  Close;
end;

procedure TFNLReplayRefresher.btnRemoveReplayClick(Sender: TObject);
begin
  lbReplays.DeleteSelected;
end;

procedure TFNLReplayRefresher.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  NewWidth := Max(NewWidth, fInitialWidth);
  NewHeight := Max(NewHeight, fInitialHeight);
end;

procedure TFNLReplayRefresher.FormCreate(Sender: TObject);
var
  SL: TStringList;
begin
  if FileExists(AppPath + SFSaveData + 'settings.ini') then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(AppPath + SFSaveData + 'settings.ini');
      ebUsername.Text := SL.Values['UserName'];
    finally
      SL.Free;
    end;
  end;

  fInitialWidth := Width;
  fInitialHeight := Height;
end;

end.
