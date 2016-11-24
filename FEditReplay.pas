unit FEditReplay;

// known issue - clicking Cancel destroys all replay data (should just revert to
//               the state of data before opening dialog)

interface

uses
  LemReplay, UMisc, LemCore,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TFReplayEditor = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    lbReplayActions: TListBox;
    lblLevelName: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lbReplayActionsClick(Sender: TObject);
  private
    fSavedReplay: TMemoryStream;
    fReplay: TReplay;

    procedure ListReplayActions;
  public
    procedure SetReplay(aReplay: TReplay);
  end;

var
  FReplayEditor: TFReplayEditor;

implementation

{$R *.dfm}

procedure TFReplayEditor.ListReplayActions;
var
  Selected: TObject;
  i: Integer;
  Action: TBaseReplayItem;

  function GetString(aItem: TBaseReplayItem): String;
  var
    A: TReplaySkillAssignment absolute aItem;
    R: TReplayChangeReleaseRate absolute aItem;
    N: TReplayNuke absolute aItem;

    function GetSkillString(aSkill: TBasicLemmingAction): String;
    begin
      case aSkill of
            baDigging:     Result := 'Digger';
            baClimbing:    Result := 'Climber';
            baBuilding:    Result := 'Builder';
            baBashing:     Result := 'Basher';
            baMining:      Result := 'Miner';
            baFloating:    Result := 'Floater';
            baBlocking:    Result := 'Blocker';
            baExploding:   Result := 'Bomber';
            baToWalking:   Result := 'Walker';
            baPlatforming: Result := 'Platformer';
            baStacking:    Result := 'Stacker';
            baStoning:     Result := 'Stoner';
            baSwimming:    Result := 'Swimmer';
            baGliding:     Result := 'Glider';
            baFixing:      Result := 'Disarmer';
            baCloning:     Result := 'Cloner';
        else Result := '(Invalid skill)';
      end;
    end;
  begin
    Result := LeadZeroStr(aItem.Frame, 5) + ': ';

    if aItem is TReplaySkillAssignment then
    begin
      Result := Result + 'Lemming #' + IntToStr(A.LemmingIndex);
      Result := Result + ', ' + GetSkillString(A.Skill);
    end else if aItem is TReplayChangeReleaseRate then
    begin
      Result := Result + 'Release Rate ' + IntToStr(R.NewReleaseRate);
    end else if aItem is TReplayNuke then
    begin
      Result := Result + 'Nuke';
    end else
      Result := 'Unknown replay action';
  end;
begin
  if lbReplayActions.ItemIndex = -1 then
    Selected := nil
  else
    Selected := lbReplayActions.Items.Objects[lbReplayActions.ItemIndex];
  lbReplayActions.OnClick := nil;
  lbReplayActions.Items.BeginUpdate;
  try
    for i := 0 to fReplay.LastActionFrame do
    begin
      Action := fReplay.ReleaseRateChange[i, 0];
      if Action <> nil then
        lbReplayActions.AddItem(GetString(Action), Action);
      Action := fReplay.Assignment[i, 0];
      if Action <> nil then
        lbReplayActions.AddItem(GetString(Action), Action);
    end;
  finally
    for i := 0 to lbReplayActions.Items.Count-1 do
      if lbReplayActions.Items.Objects[i] = Selected then
      begin
        lbReplayActions.ItemIndex := i;
        Break;
      end;
    lbReplayActions.Items.EndUpdate;
    lbReplayActions.OnClick := lbReplayActionsClick;
  end;
end;

procedure TFReplayEditor.SetReplay(aReplay: TReplay);
begin
  fReplay := aReplay;
  fSavedReplay.Clear;
  fReplay.SaveToStream(fSavedReplay);
  lblLevelName.Caption := fReplay.LevelName;
  ListReplayActions;
end;

procedure TFReplayEditor.FormCreate(Sender: TObject);
begin
  fSavedReplay := TMemoryStream.Create;
end;

procedure TFReplayEditor.FormDestroy(Sender: TObject);
begin
  fSavedReplay.Free;
end;

procedure TFReplayEditor.btnCancelClick(Sender: TObject);
begin
  fSavedReplay.Position := 0;
  fReplay.LoadFromStream(fSavedReplay);
end;

procedure TFReplayEditor.lbReplayActionsClick(Sender: TObject);
begin
  // placeholder
end;

end.
