unit FEditHotkeys;

interface

uses
  LemmixHotkeys,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TFLemmixHotkeys = class(TForm)
    lvHotkeys: TListView;
    cbFunctions: TComboBox;
    Button1: TButton;
    cbSkill: TComboBox;
    lblSkill: TLabel;
    cbShowUnassigned: TCheckBox;
    lblDuration: TLabel;
    ebSkipDuration: TEdit;
    Button2: TButton;
    Label3: TLabel;
    cbHardcodedNames: TCheckBox;
    cbHoldKey: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure cbShowUnassignedClick(Sender: TObject);
    procedure lvHotkeysClick(Sender: TObject);
    procedure cbFunctionsChange(Sender: TObject);
    procedure cbSkillChange(Sender: TObject);
    procedure ebSkipDurationChange(Sender: TObject);
    procedure lvHotkeysSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure Button2KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button2Click(Sender: TObject);
    procedure cbHardcodedNamesClick(Sender: TObject);
    procedure cbHoldKeyClick(Sender: TObject);
    procedure SetVisibleModifier(aKeyType: TLemmixHotkeyAction);
    procedure cbShowUnassignedKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    fShownFindInfo: Boolean;
    fKeyNames: Array [0..MAX_KEY] of String; //MAX_KEY defined in unit LemmixHotkeys
    fHotkeys: TLemmixHotkeyManager;
    procedure SetWindowPosition;
    procedure RefreshList;
    procedure SetKeyNames;
    procedure SetHotkeys(aValue: TLemmixHotkeyManager);
    function FindKeyFromList(aValue: Integer): Integer;
  public
    property HotkeyManager: TLemmixHotkeyManager write SetHotkeys;
  end;

var
  FLemmixHotkeys: TFLemmixHotkeys;

implementation

{$R *.dfm}

procedure TFLemmixHotkeys.FormCreate(Sender: TObject);
begin
  fShownFindInfo := false;
  SetWindowPosition;
  SetKeyNames;
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
                     0: s := s + 'Walker';
                     1: s := s + 'Climber';
                     2: s := s + 'Swimmer';
                     3: s := s + 'Floater';
                     4: s := s + 'Glider';
                     5: s := s + 'Disarmer';
                     6: s := s + 'Bomber';
                     7: s := s + 'Stoner';
                     8: s := s + 'Blocker';
                     9: s := s + 'Platformer';
                     10: s := s + 'Builder';
                     11: s := s + 'Stacker';
                     12: s := s + 'Basher';
                     13: s := s + 'Fencer';
                     14: s := s + 'Miner';
                     15: s := s + 'Digger';
                     16: s := s + 'Cloner';
                     else s := s + '???';
                   end;
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

procedure TFLemmixHotkeys.SetKeyNames;
var
  i: Integer;
  P: PChar;
  ScanCode: UInt;
begin
  for i := 0 to MAX_KEY do
    fKeyNames[i] := '';
    
  // Too lazy to include them in an interally-included file. So I just
  // coded them in here. xD
  if cbHardcodedNames.Checked then
  begin
  fKeyNames[$02] := 'Right-Click';
  fKeyNames[$04] := 'Middle-Click';
  fKeyNames[$08] := 'Backspace';
  fKeyNames[$09] := 'Tab';
  fKeyNames[$0D] := 'Enter';
  fKeyNames[$10] := 'Shift';
  fKeyNames[$11] := 'Ctrl (Left)';
  fKeyNames[$12] := 'Alt';
  fKeyNames[$13] := 'Pause';
  fKeyNames[$14] := 'Caps Lock';
  fKeyNames[$19] := 'Ctrl (Right)';
  fKeyNames[$1B] := 'Esc';
  fKeyNames[$20] := 'Space';
  fKeyNames[$21] := 'Page Up';
  fKeyNames[$22] := 'Page Down';
  fKeyNames[$23] := 'End';
  fKeyNames[$24] := 'Home';
  fKeyNames[$25] := 'Left Arrow';
  fKeyNames[$26] := 'Up Arrow';
  fKeyNames[$27] := 'Right Arrow';
  fKeyNames[$28] := 'Down Arrow';
  fKeyNames[$2D] := 'Insert';
  fKeyNames[$2E] := 'Delete';
  // Shortcut time!
  for i := 0 to 9 do
    fKeyNames[$30 + i] := IntToStr(i);
  for i := 0 to 25 do
    fKeyNames[$41 + i] := Char(i + 65);
  fKeyNames[$5B] := 'Windows';
  for i := 0 to 9 do
    fKeyNames[$60 + i] := 'NumPad ' + IntToStr(i);
  fKeyNames[$6A] := 'NumPad *';
  fKeyNames[$6B] := 'NumPad +';
  fKeyNames[$6D] := 'NumPad -';
  fKeyNames[$6E] := 'NumPad .';
  fKeyNames[$6F] := 'NumPad /';
  for i := 0 to 11 do
    fKeyNames[$70 + i] := 'F' + IntToStr(i+1);
  fKeyNames[$90] := 'NumLock';
  fKeyNames[$91] := 'Scroll Lock';
  fKeyNames[$BA] := ';';
  fKeyNames[$BB] := '+';
  fKeyNames[$BC] := ',';
  fKeyNames[$BD] := '-';
  fKeyNames[$BE] := '.';
  fKeyNames[$BF] := '/';
  fKeyNames[$C0] := '~';
  fKeyNames[$DB] := '[';
  fKeyNames[$DC] := '\';
  fKeyNames[$DD] := ']';
  fKeyNames[$DE] := '''';
  end;

  P := StrAlloc(20);
  for i := 0 to MAX_KEY do
  begin
    ScanCode := MapVirtualKeyEx(i, 0, GetKeyboardLayout(0)) shl 16;
    if (GetKeyNameText(ScanCode, P, 20) > 0) and (not cbHardcodedNames.Checked) then
      fKeyNames[i] := StrPas(P)
    else if fKeyNames[i] = '' then
      fKeyNames[i] := IntToHex(i, 4);
  end;
  StrDispose(P);
end;

procedure TFLemmixHotkeys.cbShowUnassignedClick(Sender: TObject);
begin
  RefreshList;
end;

procedure TFLemmixHotkeys.SetVisibleModifier(aKeyType: TLemmixHotkeyAction);
begin
  lblSkill.Visible := false;
  cbSkill.Visible := false;
  cbSkill.Enabled := false;
  lblDuration.Visible := false;
  ebSkipDuration.Visible := false;
  ebSkipDuration.Enabled := false;
  cbHoldKey.Visible := false;
  cbHoldKey.Enabled := false;

  case aKeyType of
    lka_Skill: begin
                 lblSkill.Visible := true;
                 cbSkill.Visible := true;
                 cbSkill.Enabled := true;
               end;
    lka_Skip: begin
                lblDuration.Visible := true;
                ebSkipDuration.Visible := true;
                ebSkipDuration.Enabled := true;
              end;
    lka_ClearPhysics: begin
                        cbHoldKey.Visible := true;
                        cbHoldKey.Enabled := true;
                      end;  
  end;
end;

procedure TFLemmixHotkeys.lvHotkeysClick(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then
  begin
    cbFunctions.ItemIndex := -1;
    cbSkill.ItemIndex := -1;
    ebSkipDuration.Text := '';
    cbFunctions.Enabled := false;
    cbSkill.Enabled := false;
    ebSkipDuration.Enabled := false;
    Label3.Caption := '';
    Exit;
  end;
  cbFunctions.Enabled := true;
  cbFunctions.ItemIndex := Integer(fHotkeys.CheckKeyEffect(i).Action);
  case fHotkeys.CheckKeyEffect(i).Action of
    lka_Skill: case fHotkeys.CheckKeyEffect(i).Modifier of
                 0..12: cbSkill.ItemIndex := fHotkeys.CheckKeyEffect(i).Modifier;
                 13: begin
                       if cbSkill.Items.Count = 16 then cbSkill.Items.Insert(13, 'Fencer');
                       cbSkill.ItemIndex := 13;
                     end;
                 14..16: if cbSkill.Items.Count = 16 then
                           cbSkill.ItemIndex := fHotkeys.CheckKeyEffect(i).Modifier - 1
                         else
                           cbSkill.ItemIndex := fHotkeys.CheckKeyEffect(i).Modifier;
               end;
    lka_Skip: ebSkipDuration.Text := IntToStr(fHotkeys.CheckKeyEffect(i).Modifier);
  end;
  Label3.Caption := 'Editing key: ' + fKeyNames[i];
  cbFunctionsChange(self);
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

procedure TFLemmixHotkeys.cbFunctionsChange(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; //safety; should never happen
  case TLemmixHotkeyAction(cbFunctions.ItemIndex) of
    lka_Skill: begin
                 if cbSkill.ItemIndex = -1 then cbSkill.ItemIndex := 0;
                 if (cbSkill.Items.Count = 17) or (cbSkill.ItemIndex < 13) then
                   fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex)
                 else
                   fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex + 1);
               end;
    lka_Skip: begin
                ebSkipDuration.Text := IntToStr(StrToIntDef(ebSkipDuration.Text, 0)); // not redundant; destroys non-numeric values
                fHotkeys.SetKeyFunction(i, lka_Skip, StrToInt(ebSkipDuration.Text));
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
  if i = -1 then Exit; //safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_Skill then Exit;
  if (cbSkill.Items.Count = 17) or (cbSkill.ItemIndex < 13) then
    fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex)
  else
    fHotkeys.SetKeyFunction(i, lka_Skill, cbSkill.ItemIndex + 1);  
  RefreshList;
end;

procedure TFLemmixHotkeys.ebSkipDurationChange(Sender: TObject);
var
  i: Integer;
begin
  if (ebSkipDuration.Text <> '') and (ebSkipDuration.Text <> '-') then
    try
      StrToInt(ebSkipDuration.Text);
    except
      ebSkipDuration.Text := '0';
    end; // Is there a tidier way to detect if something can be StrToInt'd, without relying on StrToIntDef and an unlikely value?

  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; //safety; should never happen
  if fHotkeys.CheckKeyEffect(i).Action <> lka_Skip then Exit;
  fHotkeys.SetKeyFunction(i, lka_Skip, StrToIntDef(ebSkipDuration.Text, 1)); // StrToIntDef is fine here
  RefreshList;
end;

{procedure TFLemmixHotkeys.lvHotkeysKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
  KeyName: String;
begin
  KeyName := fKeyNames[Key];
  for i := 0 to lvHotkeys.Items.Count-1 do
    if KeyName = lvHotkeys.Items[i].Caption then
    begin
      lvHotkeys.ItemIndex := i;
      Exit;
    end;
end;}

procedure TFLemmixHotkeys.lvHotkeysSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  // Just reuse the OnClick code.
  lvHotkeysClick(Sender);
end;

procedure TFLemmixHotkeys.Button2KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
  KeyName: String;
begin
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
  if cbShowUnassigned.Checked = false then
  begin
    cbShowUnassigned.Checked := true;
    Button2KeyDown(Sender, Key, Shift);
  end else
    ShowMessage('Could not find the key.');
end;

procedure TFLemmixHotkeys.Button2Click(Sender: TObject);
begin
  if not fShownFindInfo then
  begin
    fShownFindInfo := true;
    ShowMessage('After clicking Find Key, press any key to jump to that key in the list.');
  end;
end;

procedure TFLemmixHotkeys.cbHardcodedNamesClick(Sender: TObject);
begin
  SetKeyNames;
  RefreshList;
end;

procedure TFLemmixHotkeys.cbHoldKeyClick(Sender: TObject);
var
  i: Integer;
begin
  i := FindKeyFromList(lvHotkeys.ItemIndex);
  if i = -1 then Exit; //safety; should never happen

  if fHotkeys.CheckKeyEffect(i).Action <> lka_ClearPhysics then Exit;

  if cbHoldKey.Checked then
    fHotkeys.SetKeyFunction(i, lka_ClearPhysics, 1)
  else
    fHotkeys.SetKeyFunction(i, lka_ClearPhysics, 0);
  RefreshList;
end;

procedure TFLemmixHotkeys.cbShowUnassignedKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F1) and (cbSkill.Items.Count = 16) then
    cbSkill.Items.Insert(13, 'Fencer');
end;

end.
