unit FEditReplay;

interface

uses
  LemReplay, UMisc, LemCore,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, StrUtils,
  SharedGlobals;

type
  TFReplayEditor = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    lbReplayActions: TListBox;
    lblLevelName: TLabel;
    btnDelete: TButton;
    lblSelectEvents: TLabel;
    btnGoToReplayEvent: TButton;
    cbSelectFutureEvents: TCheckBox;
    stFocus: TStaticText;
    lblReplayInsertExplanation: TLabel;
    btnReplayInsertExplanation: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lbReplayActionsClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure lbReplayActionsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbReplayActionsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnGoToReplayEventClick(Sender: TObject);
    procedure lbReplayActionsDblClick(Sender: TObject);
    procedure cbSelectFutureEventsClick(Sender: TObject);
    procedure btnReplayInsertExplanationClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
private
    fSavedReplay: TMemoryStream;
    fReplay: TReplay;
    fEarliestChange: Integer;
    fCurrentIteration: Integer;
    fTargetFrame: Integer;
    fOriginalSkillEvent: Integer;

    procedure ListReplayActions(aSelect: TBaseReplayItem = nil; SelectNil: Boolean = False);
    procedure NoteChangeAtFrame(aFrame: Integer);
    procedure DeleteSelectedReplayEvents;
    procedure GoToSelectedReplayEvent;
    procedure SelectFutureEvents;
    procedure SetControls;
    procedure ShowReplayInsertExplanationPopup;

    function SFrame: String;
    procedure AddCurrentFrameString;
    procedure AddTargetFrameString;
  public
    procedure SetReplay(aReplay: TReplay; aIteration: Integer = -1);
    property EarliestChange: Integer read fEarliestChange;
    property CurrentIteration: Integer read fCurrentIteration write fCurrentIteration;
    property TargetFrame: Integer read fTargetFrame write fTargetFrame;
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

function TFReplayEditor.SFrame: String;
begin
  if (fTargetFrame <> -1) then
    Result := 'Starting Frame: '
  else
    Result := 'Current Frame: ';
end;

procedure TFReplayEditor.AddCurrentFrameString;
var
  S: String;
begin
  S := '--- ' + SFrame + IntToStr(fCurrentIteration) +  ' ---';

  lbReplayActions.AddItem(S, nil);
end;

procedure TFReplayEditor.AddTargetFrameString;
var
  S: String;
begin
  S := '--- Target Frame: ' + IntToStr(fTargetFrame) +  ' ---';

  lbReplayActions.AddItem(S, nil);
end;

procedure TFReplayEditor.ListReplayActions(aSelect: TBaseReplayItem = nil; SelectNil: Boolean = False);
var
  Selected: TObject;
  i: Integer;
  Action: TBaseReplayItem;
  CurrentFrameAdded: Boolean;

  function GetString(aItem: TBaseReplayItem): String;
  var
    A: TReplaySkillAssignment absolute aItem;
    R: TReplayChangeSpawnInterval absolute aItem;
    N: TReplayNuke absolute aItem;
    F: TReplayInfiniteSkills absolute aItem;
    T: TReplayInfiniteTime absolute aItem;

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
            //baPropelling:    Result := 'Propeller'; // Propeller
            baLasering:      Result := 'Laserer';
            baBashing:       Result := 'Basher';
            baFencing:       Result := 'Fencer';
            baMining:        Result := 'Miner';
            baDigging:       Result := 'Digger';
            baBatting:       Result := 'Batter';
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
    end else if aItem is TReplayInfiniteSkills then
    begin
      Result := Result + 'Infinite Skills';
    end else if aItem is TReplayInfiniteTime then
    begin
      Result := Result + 'Infinite Time';
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
    CurrentFrameAdded := False;

    for i := 0 to fReplay.LastActionFrame do
    begin
      if (fTargetFrame <> -1) and (i = fTargetFrame) then
        AddTargetFrameString;

      if i = fCurrentIteration then
      begin
        AddCurrentFrameString;
        CurrentFrameAdded := True;
      end;

      Action := fReplay.SpawnIntervalChange[i, 0];
      if Action <> nil then
        AddAction(Action);

      Action := fReplay.Assignment[i, 0];
      if Action <> nil then
        AddAction(Action);

      Action := fReplay.SkillCountChange[i, 0];
      if Action <> nil then
        AddAction(Action);

      Action := fReplay.TimeChange[i, 0];
      if Action <> nil then
        AddAction(Action);
    end;

    // Always add the current frame string, even if the list is empty
    if not CurrentFrameAdded then
      AddCurrentFrameString;
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
  end;
end;

procedure TFReplayEditor.SetReplay(aReplay: TReplay; aIteration: Integer = -1);
begin
  fReplay := aReplay;
  fCurrentIteration := aIteration;
  fSavedReplay.Clear;
  fReplay.SaveToStream(fSavedReplay, False, True);
  lblLevelName.Caption := Trim(fReplay.LevelName);

  ListReplayActions;
end;

procedure TFReplayEditor.FormCreate(Sender: TObject);
begin
  fSavedReplay := TMemoryStream.Create;
  fEarliestChange := -1;
  fTargetFrame := -1;
  fOriginalSkillEvent := -1;

  SetControls;
end;

procedure TFReplayEditor.FormDestroy(Sender: TObject);
begin
  fSavedReplay.Free;
end;

procedure TFReplayEditor.FormShow(Sender: TObject);
begin
  btnCancel.SetFocus;
end;

procedure TFReplayEditor.btnCancelClick(Sender: TObject);
begin
  fSavedReplay.Position := 0;
  fReplay.LoadFromStream(fSavedReplay, True);
end;

procedure TFReplayEditor.lbReplayActionsClick(Sender: TObject);
begin
  SetControls;
  stFocus.SetFocus;
end;

procedure TFReplayEditor.lbReplayActionsDblClick(Sender: TObject);
begin
  GoToSelectedReplayEvent;
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
     if ContainsText(lbReplayActions.Items[Index], 'Target Frame') then
        lbReplayActions.Canvas.Font.Color := clBlue
      else
        lbReplayActions.Canvas.Font.Color := clGreen;
    end else begin
      IsLatest := fReplay.IsThisLatestAction(Action);
      IsInsert := Action.AddedByInsert;

      if IsLatest then lbReplayActions.Canvas.Font.Style := [fsBold];
      if IsInsert then lbReplayActions.Canvas.Font.Color := clBlue;

      if IsInsert then
      begin
        lblReplayInsertExplanation.Visible := True;
        btnReplayInsertExplanation.Visible := True;
      end;
    end;

    lbReplayActions.Canvas.TextOut(Rect.Left, Rect.Top, lbReplayActions.Items[Index]);
  finally
    lbReplayActions.Canvas.Font.Style := [];
    lbReplayActions.Canvas.Font.Color := $000000;
  end;
end;

procedure TFReplayEditor.lbReplayActionsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN, VK_SPACE: GoToSelectedReplayEvent;
    VK_DELETE: DeleteSelectedReplayEvents;
  end;
end;

procedure TFReplayEditor.btnDeleteClick(Sender: TObject);
begin
  DeleteSelectedReplayEvents;
end;

procedure TFReplayEditor.btnGoToReplayEventClick(Sender: TObject);
begin
  GoToSelectedReplayEvent;
end;

procedure TFReplayEditor.cbSelectFutureEventsClick(Sender: TObject);
begin
  SelectFutureEvents;
end;

procedure TFReplayEditor.btnReplayInsertExplanationClick(Sender: TObject);
begin
  ShowReplayInsertExplanationPopup;
end;

procedure TFReplayEditor.SetControls;
var
  CurrentItem: TBaseReplayItem;
  CurrentLemmingIndex: Integer;
  ItemSelected, SkillEventSelected: Boolean;
begin
  // Set variables
  ItemSelected := (lbReplayActions.ItemIndex <> -1) and lbReplayActions.Selected[lbReplayActions.ItemIndex] and
                  (lbReplayActions.Items.Objects[lbReplayActions.ItemIndex] <> nil);

  SkillEventSelected := ItemSelected and (not (lbReplayActions.SelCount > 1)) and
                        (lbReplayActions.Items.Objects[lbReplayActions.ItemIndex] is TReplaySkillAssignment);

  if ItemSelected then
    CurrentItem := TBaseReplayItem(lbReplayActions.Items.Objects[lbReplayActions.ItemIndex])
  else if (lbReplayActions.Items.Count > 0) then
    CurrentItem := TBaseReplayItem(lbReplayActions.Items.Objects[0])
  else
    CurrentItem := nil;

  // Update controls
  btnDelete.Enabled := ItemSelected;
  btnGoToReplayEvent.Enabled := ItemSelected and not (lbReplayActions.SelCount > 1);

  if CurrentItem <> nil then
  begin
    if (fTargetFrame <> -1) and (CurrentItem.Frame = fTargetFrame) then
      btnGoToReplayEvent.Caption := 'Return To Starting Frame'
    else
      btnGoToReplayEvent.Caption := 'Skip To Selected Replay Event';
  end;

  if SkillEventSelected then
  begin
    fOriginalSkillEvent := lbReplayActions.ItemIndex;

    CurrentLemmingIndex := TReplaySkillAssignment(CurrentItem).LemmingIndex;

    cbSelectFutureEvents.Visible := True;
    cbSelectFutureEvents.Checked := False;
    cbSelectFutureEvents.Caption := 'Select All Future Events for Lemming ' + IntToStr(CurrentLemmingIndex);
  end else begin
    cbSelectFutureEvents.Visible := False;
    cbSelectFutureEvents.Caption := 'Select All Future Events';
  end;

  lblReplayInsertExplanation.Visible := False;
  btnReplayInsertExplanation.Visible := False;
end;


procedure TFReplayEditor.SelectFutureEvents;
var
  I: Integer;
  CurrentItem: TBaseReplayItem;
  FutureItem: TBaseReplayItem;
  CurrentLemmingIndex: Integer;

  procedure ResetSelection;
  begin
    lbReplayActions.ClearSelection;
    lbReplayActions.Selected[fOriginalSkillEvent] := True;
  end;
begin
  // Check if the current item is a skill assignment
  if not ((lbReplayActions.ItemIndex <> -1) and
         (lbReplayActions.Items.Objects[lbReplayActions.ItemIndex] is TReplaySkillAssignment)) then
            Exit;

  CurrentItem := TBaseReplayItem(lbReplayActions.Items.Objects[lbReplayActions.ItemIndex]);
  CurrentLemmingIndex := TReplaySkillAssignment(CurrentItem).LemmingIndex;

  if cbSelectFutureEvents.Checked then
  begin
    ResetSelection;

    // Select any future items with the same lem index
    for I := lbReplayActions.ItemIndex + 1 to lbReplayActions.Count - 1 do
    begin
      FutureItem := TBaseReplayItem(lbReplayActions.Items.Objects[I]);
      if (FutureItem is TReplaySkillAssignment) and
         (TReplaySkillAssignment(FutureItem).LemmingIndex = CurrentLemmingIndex) then
      begin
        lbReplayActions.Selected[I] := True;
      end;
    end;
  end else
    ResetSelection;
end;

procedure TFReplayEditor.GoToSelectedReplayEvent;
var
  I: Integer;
  ReplayItem: TBaseReplayItem;
begin
  // Find the first selected item
  I := lbReplayActions.ItemIndex;

  if (I <> -1) then
  begin
    ReplayItem := TBaseReplayItem(lbReplayActions.Items.Objects[I]);

    if ReplayItem <> nil then
    begin
      if (fTargetFrame <> -1) and (ReplayItem.Frame = fTargetFrame) then
      begin
        fTargetFrame := -1;

        ListReplayActions;
        lbReplayActions.ClearSelection;
      end else begin
        fTargetFrame := ReplayItem.Frame;

        ListReplayActions;

        if ContainsText(lbReplayActions.Items[I], 'Target Frame') and (I + 1 < lbReplayActions.Count) then
          lbReplayActions.Selected[I + 1] := True
        else
          lbReplayActions.Selected[I] := True;
      end;

      SetControls;
      ModalResult := mrRetry;
    end;
  end;
end;


procedure TFReplayEditor.DeleteSelectedReplayEvents;
var
  I: Integer;
  CurrentItem: TBaseReplayItem;
  ApplyRRDelete: Boolean;

  procedure HandleRRDelete(StartFrame: Integer);
  var
    Frame: Integer;
    Item: TBaseReplayItem;
  begin
    Frame := StartFrame;
    Item := fReplay.SpawnIntervalChange[Frame, 0];

    if Item <> nil then
      fReplay.Delete(Item);
  end;
begin
  if lbReplayActions.ItemIndex = -1 then Exit;

  for I := lbReplayActions.Count - 1 downto 0 do
  begin
    if not lbReplayActions.Selected[I] then Continue;

    CurrentItem := TBaseReplayItem(lbReplayActions.Items.Objects[I]);
    if CurrentItem = nil then Continue;

    NoteChangeAtFrame(CurrentItem.Frame);

    ApplyRRDelete := False;
    if CurrentItem is TReplayChangeSpawnInterval then
    begin
      if ApplyRRDelete then
      begin
        HandleRRDelete(CurrentItem.Frame);
        Continue;
      end;
    end;

    fReplay.Delete(CurrentItem);
  end;

  ListReplayActions;
end;

procedure TFReplayEditor.ShowReplayInsertExplanationPopup;
var
  Popup: TForm;
  Memo: TMemo;
  BtnOK: TButton;
  P: String;
begin
  Popup := TForm.Create(Self);
  try
    Popup.BorderStyle := bsDialog;
    Popup.Caption := 'Replay Insert Mode';
    Popup.Position := poOwnerFormCenter;
    Popup.ClientWidth := 560;
    Popup.ClientHeight := 440;

    // Invisible button to allow closing via ESC
    BtnOK := TButton.Create(Popup);
    BtnOK.Parent := Popup;
    BtnOK.Cancel := True;
    BtnOK.ModalResult := mrCancel;

    Memo := TMemo.Create(Popup);
    Memo.Parent := Popup;
    Memo.Align := alClient;
    Memo.ReadOnly := True;
    Memo.TabStop := False;
    Memo.Enabled := False;
    Memo.BorderStyle := bsNone;
    Memo.Font.Name := 'Segoe UI';
    Memo.Font.Size := 10;
    P := '       '; // Padding for Memo text
    Memo.Text := sLineBreak +
                 P + 'Replay Insert Mode allows you to add skill assignments' + sLineBreak +
                 P + 'and/or release rate changes without disrupting any' + sLineBreak +
                 P + 'existing replay events.' + sLineBreak +
                 sLineBreak +
                 P + 'Any action already in the replay will remain intact,' + sLineBreak +
                 P + 'and - importantly - will occur at the frame upon' + sLineBreak +
                 P + 'which it was originally inputted.' + sLineBreak +
                 sLineBreak +
                 P + 'Replay Insert Mode is indicated by changing the color' + sLineBreak +
                 P + 'of the "R" replay icon in the skill panel from' + sLineBreak +
                 P + 'red to blue.' + sLineBreak +
                 sLineBreak +
                 P + 'Press ESC or close the window when ready.';

    Popup.ShowModal;
  finally
    Popup.Free;
  end;
end;

end.
