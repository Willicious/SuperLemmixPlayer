unit FEditReplay;

// Bookmark - Known issue - clicking Cancel destroys all replay data
// (should just revert to the state of data before opening dialog) - check if this is is still an issue

interface

uses
  LemReplay, UMisc, LemCore,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TFReplayEditor = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    lbReplayActions: TListBox;
    lblLevelName: TLabel;
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
    fCurrentIteration: Integer;

    procedure ListReplayActions(aSelect: TBaseReplayItem = nil; SelectNil: Boolean = false);
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

procedure TFReplayEditor.ListReplayActions(aSelect: TBaseReplayItem = nil; SelectNil: Boolean = false);
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
            baToWalking:     Result := 'Walker';
            baJumping:       Result := 'Jumper';
            baShimmying:     Result := 'Shimmier';
            baBallooning:    Result := 'Ballooner';
            baSliding:       Result := 'Slider';
            baClimbing:      Result := 'Climber';
            baSwimming:      Result := 'Swimmer';
            baFloating:      Result := 'Floater';
            baGliding:       Result := 'Glider';
            baFixing:        Result := 'Disarmer';
            baTimebombing:   Result := 'Timebomber';
            baExploding:     Result := 'Bomber';
            baFreezing:      Result := 'Freezer';
            baBlocking:      Result := 'Blocker';
            baLaddering:     Result := 'Ladderer';
            baPlatforming:   Result := 'Platformer';
            baBuilding:      Result := 'Builder';
            baStacking:      Result := 'Stacker';
            baSpearing:      Result := 'Spearer';
            baGrenading:     Result := 'Grenader';
            baLasering:      Result := 'Laserer';
            baBashing:       Result := 'Basher';
            baFencing:       Result := 'Fencer';
            baMining:        Result := 'Miner';
            baDigging:       Result := 'Digger';
            baCloning:       Result := 'Cloner';
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
      if GameParams.SpawnInterval and not GameParams.ClassicMode then
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
  if (aSelect <> nil) or SelectNil then
    Selected := aSelect
  else if lbReplayActions.ItemIndex = -1 then
    Selected := nil
  else begin
    Selected := lbReplayActions.Items.Objects[lbReplayActions.ItemIndex];
    SelectNil := (Selected = nil); // ItemIndex is not -1 if we reached here
  end;
  lbReplayActions.OnClick := nil;
  lbReplayActions.Items.BeginUpdate;
  try
    lbReplayActions.Items.Clear;
    for i := 0 to fReplay.LastActionFrame do
    begin
      if i = fCurrentIteration then
        lbReplayActions.AddItem('--- CURRENT FRAME ---', nil);

      Action := fReplay.SpawnIntervalChange[i, 0];
      if Action <> nil then
        AddAction(Action);

      Action := fReplay.Assignment[i, 0];
      if Action <> nil then
        AddAction(Action);
    end;
  finally
    for i := 0 to lbReplayActions.Items.Count-1 do
      if (lbReplayActions.Items.Objects[i] = Selected) and
         (SelectNil or (Selected <> nil)) then
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
  fCurrentIteration := aIteration;
  fSavedReplay.Clear;
  fReplay.SaveToStream(fSavedReplay, false, true);
  lblLevelName.Caption := Trim(fReplay.LevelName);
  if fCurrentIteration <> -1 then
    lblFrame.Caption := 'Current frame: ' + IntToStr(fCurrentIteration);
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
  fReplay.LoadFromStream(fSavedReplay, true);
end;

procedure TFReplayEditor.lbReplayActionsClick(Sender: TObject);
begin
  btnDelete.Enabled := (lbReplayActions.ItemIndex <> -1) and
                       (lbReplayActions.Items.Objects[lbReplayActions.ItemIndex] <> nil);
end;

procedure TFReplayEditor.lbReplayActionsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Action: TBaseReplayItem;

  IsLatest: Boolean;
  IsInsert: Boolean;
begin
  Action := TBaseReplayItem(lbReplayActions.Items.Objects[Index]);

  try
    if Action = nil then
    begin
      lbReplayActions.Canvas.Font.Color := $007F00;
    end else begin
      IsLatest := fReplay.IsThisLatestAction(Action);
      IsInsert := Action.AddedByInsert;

      if IsLatest then lbReplayActions.Canvas.Font.Style := [fsBold];
      if IsInsert then lbReplayActions.Canvas.Font.Color := $FF0000; // BGR, bleurgh
    end;

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
  if I = nil then Exit;

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
