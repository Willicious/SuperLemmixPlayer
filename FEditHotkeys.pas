unit FEditHotkeys;

interface

uses
  LemmixHotkeys, LemCore,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Vcl.Buttons, Vcl.Samples.Spin,
  SharedGlobals;

type
  TFLemmixHotkeys = class(TForm)
    lvHotkeys: TListView;
    cbFunctions: TComboBox;
    btnSaveClose: TButton;
    cbSkill: TComboBox;
    lblSkill: TLabel;
    cbShowUnassigned: TCheckBox;
    lblDuration: TLabel;
    ebSkipDuration: TEdit;
    btnFindKey: TButton;
    lblFindKey: TLabel;
    cbHardcodedNames: TCheckBox;
    cbHoldKey: TCheckBox;
    cbSpecialSkip: TComboBox;
    lblSkip: TLabel;
    btnNeoLemmixLayout: TBitBtn;
    btnCancel: TBitBtn;
    btnReset: TBitBtn;
    lblSkillButton: TLabel;
    seSkillButton: TSpinEdit;
    lblNudgeAmount: TLabel;
    ebNudgeAmount: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure cbShowUnassignedClick(Sender: TObject);
    procedure lvHotkeysClick(Sender: TObject);
    procedure cbFunctionsChange(Sender: TObject);
    procedure cbSkillChange(Sender: TObject);
    procedure ebSkipDurationChange(Sender: TObject);
    procedure lvHotkeysSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnFindKeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnFindKeyClick(Sender: TObject);
    procedure cbHardcodedNamesClick(Sender: TObject);
    procedure cbHoldKeyClick(Sender: TObject);
    procedure SetVisibleModifier(aKeyType: TLemmixHotkeyAction);
    procedure cbSpecialSkipChange(Sender: TObject);
    procedure btnClassicLayoutClick(Sender: TObject);
    procedure btnAdvancedLayoutClick(Sender: TObject);
    procedure btnNeoLemmixLayoutClick(Sender: TObject);
    procedure btnClearAllKeysClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveCloseClick(Sender: TObject);
    procedure seSkillButtonChange(Sender: TObject);
    procedure ebNudgeAmountChange(Sender: TObject);
    procedure ebClick(Sender: TObject);
  private
    fKeyNames: TKeyNameArray;
    fHotkeys: TLemmixHotkeyManager;
    fEditingKey: Boolean;
    procedure SetWindowPosition;
    procedure RefreshList;
    procedure SetHotkeys(aValue: TLemmixHotkeyManager);
    function FindKeyFromList(aValue: Integer): Integer;
    procedure HandleCaptions(Sender: TObject);
  public
    property HotkeyManager: TLemmixHotkeyManager write SetHotkeys;
  end;

var
  FLemmixHotkeys: TFLemmixHotkeys;

implementation

{$R *.dfm}

procedure TFLemmixHotkeys.FormCreate(Sender: TObject);
begin
  SetWindowPosition;
  fKeyNames := TLemmixHotkeyManager.GetKeyNames(True);
  fEditingKey := False;
  HandleCaptions(Self);
end;

procedure TFLemmixHotkeys.HandleCaptions(Sender: TObject);
var
i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then
  begin
    btnFindKey.Caption := 'Find Key';
    lblFindKey.Caption := '';
    Exit;
  end;

  if fEditingKey then
  begin
    btnFindKey.Caption := 'Find Key';
    lblFindKey.Caption := 'Editing key: ' + fKeyNames[i];
  end else Exit;
end;

procedure TFLemmixHotkeys.lvHotkeysClick(Sender: TObject);
var
  i: Integer;
begin
  fEditingKey := True;
  HandleCaptions(Self);

  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then
  begin
    cbFunctions.ItemIndex := -1;
    cbSkill.ItemIndex := -1;
    seSkillButton.Value := 0;
    ebSkipDuration.Text := '';
    ebNudgeAmount.Text := '';
    cbFunctions.Enabled := False;
    cbSkill.Enabled := False;
    seSkillButton.Enabled := False;
    ebSkipDuration.Enabled := False;
    ebNudgeAmount.Enabled := False;
    Exit;
  end;
  cbFunctions.Enabled := True;
  cbFunctions.ItemIndex := Integer(fHotkeys.CheckKeyEffect(i).Action);
  case fHotkeys.CheckKeyEffect(i).Action of
    lka_Skill: cbSkill.ItemIndex := fHotkeys.CheckKeyEffect(i).Modifier;
    lka_SkillButton: seSkillButton.Value := fHotkeys.CheckKeyEffect(i).Modifier;
    lka_Skip: ebSkipDuration.Text := IntToStr(fHotkeys.CheckKeyEffect(i).Modifier);
    lka_NudgeUp,
    lka_NudgeDown,
    lka_NudgeLeft,
    lka_NudgeRight: ebNudgeAmount.Text := IntToStr(fHotkeys.CheckKeyEffect(i).Modifier);
    lka_ClearPhysics,
    lka_ShowUsedSkills: cbHoldKey.Checked := fHotkeys.CheckKeyEffect(i).Modifier = 1;
  end;

  // Scroll to selected key in the displayed list
  lvHotkeys.Selected.MakeVisible(False);
  cbFunctionsChange(Self);
end;


function TFLemmixHotkeys.FindKeyFromList(aValue: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if aValue = -1 then Exit;
  for i := 0 to MAX_KEY do
    if fKeyNames[i] = lvHotkeys.Items[aValue].Caption then
    begin
      Result := i;
      Exit;
    end;
end;

procedure TFLemmixHotkeys.btnFindKeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
  KeyName: String;
begin
  fEditingKey := True;
  HandleCaptions(Self);

  if Key = VK_SPACE then
  begin
    Key := 0;
    for i := 0 to lvHotkeys.Items.Count - 1 do
    begin
      if lvHotkeys.Items[i].Caption = 'Space' then
        begin
          lvHotkeys.SetFocus;
          lvHotkeys.ItemIndex := i;
          Exit;
        end;
    end;
  end;

  if Key > MAX_KEY then
  begin
    ShowMessage('This key is not supported.');
    Exit;
  end;
  KeyName := fKeyNames[Key];
  for i := 0 to lvHotkeys.Items.Count-1 do
    if KeyName = lvHotkeys.Items[i].Caption then
    begin
      lvHotkeys.SetFocus;
      lvHotkeys.ItemIndex := i;
      Exit;
    end;
  if cbShowUnassigned.Checked = False then
  begin
    cbShowUnassigned.Checked := True;
    btnFindKeyKeyDown(Sender, Key, Shift);
  end else
    ShowMessage('Could not find the key.');
end;

procedure TFLemmixHotkeys.btnFindKeyClick(Sender: TObject);
begin
  fEditingKey := False;
  btnFindKey.Caption := 'Finding Key...';
  lblFindKey.Caption := 'Press any key to edit...';
end;

procedure TFLemmixHotkeys.SetWindowPosition;
begin
  Left := (Screen.Width div 2) - (Width div 2);
  Top := (Screen.Height div 2) - (Height div 2);
end;

procedure TFLemmixHotkeys.RefreshList;
var
  i: Integer;
  e: Integer;
  Hotkey: TLemmixHotkey;
  s: String;
begin
  e := 0;
  for i := 0 to MAX_KEY do
  begin
    Hotkey := fHotkeys.CheckKeyEffect(i);
    if (Hotkey.Action = lka_Null) and not cbShowUnassigned.Checked then Continue;
    case Hotkey.Action of
      lka_Skill: begin
                   s := 'Select Skill: ';
                   case Hotkey.Modifier of
                     Integer(spbWalker):       s := s + 'Walker';      // 0
                     Integer(spbJumper):       s := s + 'Jumper';      // 1
                     Integer(spbShimmier):     s := s + 'Shimmier';    // 2
                     Integer(spbBallooner):    s := s + 'Ballooner';   // 3
                     Integer(spbSlider):       s := s + 'Slider';      // 4
                     Integer(spbClimber):      s := s + 'Climber';     // 5
                     Integer(spbSwimmer):      s := s + 'Swimmer';     // 6
                     Integer(spbFloater):      s := s + 'Floater';     // 7
                     Integer(spbGlider):       s := s + 'Glider';      // 8
                     Integer(spbDisarmer):     s := s + 'Disarmer';    // 9
                     Integer(spbTimebomber):   s := s + 'Timebomber';  // 10
                     Integer(spbBomber):       s := s + 'Bomber';      // 11
                     Integer(spbFreezer):      s := s + 'Freezer';     // 12
                     Integer(spbBlocker):      s := s + 'Blocker';     // 13
                     Integer(spbLadderer):     s := s + 'Ladderer';    // 14
                     Integer(spbPlatformer):   s := s + 'Platformer';  // 15
                     Integer(spbBuilder):      s := s + 'Builder';     // 16
                     Integer(spbStacker):      s := s + 'Stacker';     // 17
                     Integer(spbSpearer):      s := s + 'Spearer';     // 18
                     Integer(spbGrenader):     s := s + 'Grenader';    // 19
                     Integer(spbLaserer):      s := s + 'Laserer';     // 20
                     Integer(spbBasher):       s := s + 'Basher';      // 21
                     Integer(spbFencer):       s := s + 'Fencer';      // 22
                     Integer(spbMiner):        s := s + 'Miner';       // 23
                     Integer(spbDigger):       s := s + 'Digger';      // 24
                     //Integer(spbBatter):       s := s + 'Batter';    // Batter
                     //Integer(spbPropeller):    s := s + 'Propeller';   // Propeller
                     Integer(spbCloner):       s := s + 'Cloner';      // 25
                     else s := s + '???';
                   end;
                 end;
      lka_SkillButton: begin
                         s := 'Select Skill Button: ' + IntToStr(Hotkey.Modifier);
                       end;
      lka_Skip: begin
                  if Hotkey.Modifier < -1 then
                    s := 'Time Skip: Back ' + IntToStr(Hotkey.Modifier * -1) + ' Frames'
                  else if Hotkey.Modifier = -1 then
                    s := 'Time Skip: Back 1 Frame'
                  else if Hotkey.Modifier > 1 then
                    s := 'Time Skip: Forward ' + IntToStr(Hotkey.Modifier) + ' Frames'
                  else
                    s := 'Time Skip: Forward 1 Frame';
                end;
      lka_ClearPhysics: if Hotkey.Modifier = 0 then
                          s := 'Clear Physics Mode (toggle)'
                        else
                          s := 'Clear Physics Mode (hold)';
      lka_ShowUsedSkills: if Hotkey.Modifier = 0 then
                            s := 'Show Used Skills (toggle)'
                          else
                            s := 'Show Used Skills (hold)';
      lka_SpecialSkip: begin
                         s := 'Skip to ';
                         case TSpecialSkipCondition(Hotkey.Modifier) of
                           ssc_LastAction: s := s + 'Previous Assignment';
                           ssc_NextShrugger: s := s + 'Next Shrugger';
                           ssc_HighlitStateChange: s := s + 'Highlit Lemming State Change';
                         end;
                       end;
      lka_NudgeUp:    begin
                        s := 'Nudge viewport up ' + IntToStr(Abs(Hotkey.Modifier)) + ' pixels';
                      end;
      lka_NudgeDown:  begin
                        s := 'Nudge viewport down ' + IntToStr(Abs(Hotkey.Modifier)) + ' pixels';
                      end;
      lka_NudgeLeft:  begin
                        s := 'Nudge viewport left ' + IntToStr(Abs(Hotkey.Modifier)) + ' pixels';
                      end;
      lka_NudgeRight: begin
                        s := 'Nudge viewport right ' + IntToStr(Abs(Hotkey.Modifier)) + ' pixels';
                      end;
      else s := cbFunctions.Items[Integer(fHotkeys.CheckKeyEffect(i).Action)];
    end;
    if e < lvHotkeys.Items.Count then
      with lvHotkeys.Items[e] do
      begin
        Caption := fKeyNames[i];
        SubItems[0] := s;
      end
    else
      with lvHotkeys.Items.Add do
      begin
        Caption := fKeyNames[i];
        SubItems.Add(s);
      end;
    Inc(e);
  end;
  while lvHotkeys.Items.Count > e do
    lvHotkeys.Items.Delete(e);
end;

procedure TFLemmixHotkeys.SetHotkeys(aValue: TLemmixHotkeyManager);
begin
  fHotkeys := aValue;
  RefreshList;
end;

procedure TFLemmixHotkeys.btnResetClick(Sender: TObject);
begin
  fHotkeys.LoadFile; // Loads the previously saved hotkeys.ini file
  RefreshList;
end;

procedure TFLemmixHotkeys.btnSaveCloseClick(Sender: TObject);
begin
  fHotkeys.SaveFile; // Saves current layout to hotkeys.ini
  Close;
end;

procedure TFLemmixHotkeys.btnCancelClick(Sender: TObject);
begin
  fHotkeys.LoadFile; // Loads previous hotkeys.ini file to prevent saving changes
  RefreshList;
  Close;
end;

procedure TFLemmixHotkeys.cbShowUnassignedClick(Sender: TObject);
begin
  RefreshList;
end;

procedure TFLemmixHotkeys.SetVisibleModifier(aKeyType: TLemmixHotkeyAction);
begin
  lblSkill.Visible := False;
  cbSkill.Visible := False;
  cbSkill.Enabled := False;
  lblSkillButton.Visible := False;
  seSkillButton.Visible := False;
  seSkillButton.Enabled := False;
  lblDuration.Visible := False;
  ebSkipDuration.Visible := False;
  ebSkipDuration.Enabled := False;
  lblSkip.Visible := False;
  cbSpecialSkip.Visible := False;
  cbSpecialSkip.Enabled := False;
  lblNudgeAmount.Visible := False;
  ebNudgeAmount.Visible := False;
  ebNudgeAmount.Enabled := False;
  cbHoldKey.Visible := False;
  cbHoldKey.Enabled := False;

  case aKeyType of
    lka_Skill: begin
                 lblSkill.Visible := True;
                 cbSkill.Visible := True;
                 cbSkill.Enabled := True;
               end;
    lka_SkillButton: begin
                       lblSkillButton.Visible := True;
                       seSkillButton.Visible := True;
                       seSkillButton.Enabled := True;
                     end;
    lka_Skip: begin
                lblDuration.Visible := True;
                ebSkipDuration.Visible := True;
                ebSkipDuration.Enabled := True;
              end;
    lka_ClearPhysics,
    lka_ShowUsedSkills: begin
                          cbHoldKey.Visible := True;
                          cbHoldKey.Enabled := True;
                        end;
    lka_SpecialSkip: begin
                       lblSkip.Visible := True;
                       cbSpecialSkip.Visible := True;
                       cbSpecialSkip.Enabled := True;
                     end;
    lka_NudgeUp, lka_NudgeDown, lka_NudgeLeft, lka_NudgeRight:
                     begin
                       lblNudgeAmount.Visible := True;
                       ebNudgeAmount.Visible := True;
                       ebNudgeAmount.Enabled := True;
                     end;
  end;
end;

procedure TFLemmixHotkeys.cbFunctionsChange(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen
  case TLemmixHotkeyAction(cbFunctions.ItemIndex) of
    lka_Skill: begin
                 if cbSkill.ItemIndex = -1 then cbSkill.ItemIndex := 0;
                 fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex);
               end;
    lka_SkillButton: begin
                       if seSkillButton.Value <= 0 then seSkillButton.Value := 1;
                       if seSkillButton.Value >= 15 then seSkillButton.Value := 14;

                       fHotkeys.SetKeyFunction(i, lka_SkillButton, seSkillButton.Value);
                     end;
    lka_Skip: begin
                ebSkipDuration.Text := IntToStr(StrToIntDef(ebSkipDuration.Text, 0)); // Destroys non-numeric values
                fHotkeys.SetKeyFunction(i, lka_Skip, StrToInt(ebSkipDuration.Text));
              end;
    lka_SpecialSkip: begin
                       if cbSpecialSkip.ItemIndex = -1 then cbSpecialSkip.ItemIndex := 0;
                       fHotkeys.SetKeyFunction(i, lka_SpecialSkip, cbSpecialSkip.ItemIndex);
                     end;
    lka_ClearPhysics,
    lka_ShowUsedSkills: if cbHoldKey.Checked then
                          fHotkeys.SetKeyFunction(i, TLemmixHotkeyAction(cbFunctions.ItemIndex), 1)
                        else
                          fHotkeys.SetKeyFunction(i, TLemmixHotkeyAction(cbFunctions.ItemIndex), 0);
    lka_NudgeUp:    begin
                      ebNudgeAmount.Text := IntToStr(StrToIntDef(ebNudgeAmount.Text, 160));
                      fHotkeys.SetKeyFunction(i, lka_NudgeUp, StrToInt(ebNudgeAmount.Text));
                    end;
    lka_NudgeDown:  begin
                      ebNudgeAmount.Text := IntToStr(StrToIntDef(ebNudgeAmount.Text, 160));
                      fHotkeys.SetKeyFunction(i, lka_NudgeDown, StrToInt(ebNudgeAmount.Text));
                    end;
    lka_NudgeLeft:  begin
                      ebNudgeAmount.Text := IntToStr(StrToIntDef(ebNudgeAmount.Text, 160));
                      fHotkeys.SetKeyFunction(i, lka_NudgeLeft, StrToInt(ebNudgeAmount.Text));
                    end;
    lka_NudgeRight: begin
                      ebNudgeAmount.Text := IntToStr(StrToIntDef(ebNudgeAmount.Text, 160));
                      fHotkeys.SetKeyFunction(i, lka_NudgeRight, StrToInt(ebNudgeAmount.Text));
                    end;
    else fHotkeys.SetKeyFunction(i, TLemmixHotkeyAction(cbFunctions.ItemIndex));
  end;
  SetVisibleModifier(TLemmixHotkeyAction(cbFunctions.ItemIndex));
  RefreshList;
end;

procedure TFLemmixHotkeys.cbSkillChange(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_Skill then Exit;
  fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex);
  RefreshList;
end;

procedure TFLemmixHotkeys.seSkillButtonChange(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if (i = -1) then Exit; // Safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_SkillButton then Exit;

  fHotkeys.SetKeyFunction(i, lka_SkillButton, seSkillButton.Value);
  RefreshList;
end;

procedure TFLemmixHotkeys.ebSkipDurationChange(Sender: TObject);
var
  i: Integer;
  TextValue: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_Skip then Exit;

  if not TryStrToInt(ebSkipDuration.Text, TextValue) then
  begin
    // Allow a single "-" character as valid input
    if ebSkipDuration.Text = '-' then
      Exit
    else
    begin
      // Default to -1 for invalid cases with more than one "-"
      TextValue := -1;
      if ebSkipDuration.Text <> '' then ebSkipDuration.Text := '-1';
      ebSkipDuration.SelStart := Length(ebSkipDuration.Text); // Move caret to end
    end;
  end;

  fHotkeys.SetKeyFunction(i, lka_Skip, TextValue);
  RefreshList;
end;

procedure TFLemmixHotkeys.ebClick(Sender: TObject);
begin
  if Sender is TEdit then
    TEdit(Sender).SelectAll;
end;

procedure TFLemmixHotkeys.ebNudgeAmountChange(Sender: TObject);
var
  i: Integer;
  aAction: TLemmixHotkeyAction;
  TextValue: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen

  aAction := fHotkeys.CheckKeyEffect(i).Action;

  if not (aAction in [lka_NudgeUp, lka_NudgeDown,
                      lka_NudgeLeft, lka_NudgeRight]) then Exit;

  if not TryStrToInt(ebNudgeAmount.Text, TextValue) or (TextValue <= 0) then
  begin
    TextValue := 160;
    if ebNudgeAmount.Text <> '' then
    begin
      ebNudgeAmount.Text := '160';
      ebNudgeAmount.SelStart := Length(ebNudgeAmount.Text); // Move caret to the end
    end;
  end;

  fHotkeys.SetKeyFunction(i, aAction, TextValue);
  RefreshList;
end;

procedure TFLemmixHotkeys.lvHotkeysSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  // Just reuse the OnClick code.
  lvHotkeysClick(Sender);
end;

procedure TFLemmixHotkeys.btnClassicLayoutClick(Sender: TObject);
begin
  fHotkeys.ClearAllKeys;
  fHotkeys.SetDefaultsClassic;
  cbShowUnassigned.Checked := False;
  RefreshList;
end;

procedure TFLemmixHotkeys.btnAdvancedLayoutClick(Sender: TObject);
begin
  fHotkeys.ClearAllKeys;
  fHotkeys.SetDefaultsAdvanced;
  cbShowUnassigned.Checked := False;
  RefreshList;
end;

procedure TFLemmixHotkeys.btnNeoLemmixLayoutClick(Sender: TObject);
begin
  fHotkeys.ClearAllKeys;
  fHotkeys.SetDefaultsAlternative;
  cbShowUnassigned.Checked := False;
  RefreshList;
end;

procedure TFLemmixHotkeys.btnClearAllKeysClick(Sender: TObject);
begin
  fHotkeys.ClearAllKeys;
  cbShowUnassigned.Checked := True;
  RefreshList;
end;

procedure TFLemmixHotkeys.cbHardcodedNamesClick(Sender: TObject);
begin
  fKeyNames := TLemmixHotkeyManager.GetKeyNames(cbHardcodedNames.Checked);
  RefreshList;
end;

procedure TFLemmixHotkeys.cbHoldKeyClick(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen

  if not (fHotkeys.CheckKeyEffect(i).Action in [lka_ClearPhysics,
  lka_ShowUsedSkills]) then Exit;

  if cbHoldKey.Checked then
    fHotkeys.SetKeyFunction(i, fHotkeys.CheckKeyEffect(i).Action, 1)
  else
    fHotkeys.SetKeyFunction(i, fHotkeys.CheckKeyEffect(i).Action, 0);
  RefreshList;
end;

procedure TFLemmixHotkeys.cbSpecialSkipChange(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; // Safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_SpecialSkip then Exit;
  fHotkeys.SetKeyFunction(i, lka_SpecialSkip, cbSpecialSkip.ItemIndex);
  RefreshList;
end;

end.
