unit FEditReplay;

// known issue - clicking Cancel destroys all replay data (should just revert to
//               the state of data before opening dialog)

interface

uses
  SharedGlobals,
  LemReplay, UMisc, LemCore,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TFReplayEditor = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    lbReplayActions: TListBox;
    lblLevelName: TLabel;
    Panel1: TPanel;
    Label1: TLabel;
    ebActionFrame: TEdit;
    btnDelete: TButton;
    lblFrame: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lbReplayActionsClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure lbReplayActionsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
  private
    fSavedReplay: TMemoryStream;
    fReplay: TReplay;
    fEarliestChange: Integer;

    procedure ListReplayActions(aSelect: TBaseReplayItem = nil);
    procedure NoteChangeAtFrame(aFrame: Integer);
  public
    procedure SetReplay(aReplay: TReplay; aIteration: Integer = -1);
    property EarliestChange: Integer read fEarliestChange;
  end;

var
  FReplayEditor: TFReplayEditor;

implementation

{$R *.dfm}

uses
  GameControl,
  UITypes;

procedure TFReplayEditor.NoteChangeAtFrame(aFrame: Integer);
begin
  if (fEarliestChange = -1) or (aFrame < fEarliestChange) then
    fEarliestChange := aFrame;
end;

procedure TFReplayEditor.ListReplayActions(aSelect: TBaseReplayItem = nil);
var
  Selected: TObject;
  i: Integer;
  Action: TBaseReplayItem;

  function GetString(aItem: TBaseReplayItem): String;
  var
    A: TReplaySkillAssignment absolute aItem;
    R: TReplayChangeSpawnInterval absolute aItem;
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
            baFencing:     Result := 'Fencer';
            baShimmying:   Result := 'Shimmier';
            baJumping:     Result := 'Jumper';
            baSliding:     Result := 'Slider';
            baLasering:    Result := 'Laserer';
        else Result := '(Invalid skill)';
      end;
    end;
  begin
    Result := LeadZeroStr(aItem.Frame, 5) + ': ';

    if aItem is TReplaySkillAssignment then
    begin
      Result := Result + 'Lemming #' + IntToStr(A.LemmingIndex);
      Result := Result + ', ' + GetSkillString(A.Skill);
    end else if aItem is TReplayChangeSpawnInterval then
    begin
      if GameParams.SpawnInterval then
        Result := Result + 'Spawn Interval ' + IntToStr(R.NewSpawnInterval)
      else
        Result := Result + 'Release Rate ' + IntToStr(103 - R.NewSpawnInterval);
    end else if aItem is TReplayNuke then
    begin
      Result := Result + 'Nuke';
    end else
      Result := 'Unknown replay action';
  end;

  procedure AddAction(aAction: TBaseReplayItem);
  begin
    lbReplayActions.AddItem(GetString(aAction), aAction);
  end;
begin
  if aSelect <> nil then
    Selected := aSelect
  else if lbReplayActions.ItemIndex = -1 then
    Selected := nil
  else
    Selected := lbReplayActions.Items.Objects[lbReplayActions.ItemIndex];
  lbReplayActions.OnClick := nil;
  lbReplayActions.Items.BeginUpdate;
  try
    lbReplayActions.Items.Clear;
    for i := 0 to fReplay.LastActionFrame do
    begin
      Action := fReplay.SpawnIntervalChange[i, 0];
      if Action <> nil then
        AddAction(Action);

      Action := fReplay.Assignment[i, 0];
      if Action <> nil then
        AddAction(Action);
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
    lbReplayActionsClick(lbReplayActions);
  end;
end;

procedure TFReplayEditor.SetReplay(aReplay: TReplay; aIteration: Integer = -1);
begin
  fReplay := aReplay;
  fSavedReplay.Clear;
  fReplay.SaveToStream(fSavedReplay);
  lblLevelName.Caption := Trim(fReplay.LevelName);
  if aIteration <> -1 then
    lblFrame.Caption := 'Current frame: ' + IntToStr(aIteration);
  ListReplayActions;
end;

procedure TFReplayEditor.FormCreate(Sender: TObject);
begin
  fSavedReplay := TMemoryStream.Create;
  fEarliestChange := -1;

  // Temporary stuff
  lbReplayActions.Height := lbReplayActions.Height + 96;
  btnDelete.Top := btnDelete.Top + 96;
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
var
  I: TBaseReplayItem;
  A: TReplaySkillAssignment absolute I;
  R: TReplayChangeSpawnInterval absolute I;
  N: TReplayNuke absolute I;
begin
  btnDelete.Enabled := lbReplayActions.ItemIndex <> -1;
  if lbReplayActions.ItemIndex = -1 then Exit;
  I := TBaseReplayItem(lbReplayActions.Items.Objects[lbReplayActions.ItemIndex]);
  ebActionFrame.Text := IntToStr(I.Frame);
end;

procedure TFReplayEditor.lbReplayActionsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Action: TBaseReplayItem;

  IsLatest: Boolean;
  IsInsert: Boolean;

  OldColor : TColor;
begin
  Action := TBaseReplayItem(lbReplayActions.Items.Objects[Index]);
  IsLatest := fReplay.IsThisLatestAction(Action);
  IsInsert := Action.AddedByInsert;

  try
    Log(lbReplayActions.Items[Index]);
    if IsLatest then Log('yes latest') else Log('no latest');
    if IsInsert then Log('yes insert') else Log('no insert');
    Log('');


    if IsLatest then lbReplayActions.Canvas.Font.Style := [fsBold];
    if IsInsert then lbReplayActions.Canvas.Font.Color := $FF0000; // BGR, bleurgh
    lbReplayActions.Canvas.TextOut(Rect.Left, Rect.Top, lbReplayActions.Items[Index]);
  finally
    lbReplayActions.Canvas.Font.Style := [];
    lbReplayActions.Canvas.Font.Color := $000000;
  end;
end;

procedure TFReplayEditor.btnDeleteClick(Sender: TObject);
var
  I: TBaseReplayItem;
  ApplyRRDelete: Boolean;

  function CheckConsecutiveRR: Boolean;
  var
    I2: TBaseReplayItem;
    R1: TReplayChangeSpawnInterval absolute I;
    R2: TReplayChangeSpawnInterval absolute I2;
  begin
    Result := false;
    I2 := fReplay.SpawnIntervalChange[I.Frame + 1, 0];
    if I2 = nil then Exit;
    if Abs(R1.NewSpawnInterval - R2.NewSpawnInterval) <= 1 then
      Result := true;
  end;

  procedure HandleRRDelete(StartFrame: Integer);
  var
    Frame: Integer;
  begin
    Frame := StartFrame;
    while CheckConsecutiveRR do
    begin
      fReplay.Delete(I);
      Inc(Frame);
      I := fReplay.SpawnIntervalChange[Frame, 0];
    end;
    fReplay.Delete(I);
  end;
begin
  ApplyRRDelete := false;

  if lbReplayActions.ItemIndex = -1 then Exit;
  I := TBaseReplayItem(lbReplayActions.Items.Objects[lbReplayActions.ItemIndex]);
  NoteChangeAtFrame(I.Frame);
  if I is TReplayChangeSpawnInterval then
    if CheckConsecutiveRR then
      ApplyRRDelete := MessageDlg('Delete consecutive Spawn Interval changes as well?', mtCustom, [mbYes, mbNo], 0) = mrYes;

  if ApplyRRDelete then
    HandleRRDelete(I.Frame)
  else
    fReplay.Delete(I);

  ListReplayActions;
end;

end.
