unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd,
  System.UITypes, System.Generics.Collections, System.Math, IniFiles;

// Define a record to store each TEdit for different states
type
  TColorControlPair = record
    LabelEdit: TEdit;  // TEdit for the feature name
    HexNormal: TEdit;  // TEdit for Hex value of Normal state
    HexAthlete: TEdit; // TEdit for Hex value of Athlete state
    HexSelected: TEdit; // TEdit for Hex value of Selected state
    HexRival: TEdit; // TEdit for Hex value of Rival state
    HexRivalAthlete: TEdit; // TEdit for Hex value of Rival Athlete state
    HexRivalSelected: TEdit; // TEdit for Hex value of Rival Selected state
    HexZombie: TEdit; // TEdit for Hex value of Zombie state
    HexNeutral: TEdit; // TEdit for Hex value of Neutral state
    HexInvincible: TEdit; // TEdit for Hex value of Invincible state
  end;

type
  // Define a record type for each state entry
  TStateEntry = record
    Name: string;
    FromEdit: TEdit;
    ToEdit: TEdit;
  end;

  TSchemeCreatorForm = class(TForm)
    LabelDuplicate: TLabel;
    ButtonAdd: TButton;
    ButtonGenerateStateRecoloring: TButton;
    ButtonGenerateSpritesetRecoloring: TButton;
    ButtonSave: TButton;
    ButtonLoad: TButton; // The "Add" button to create new items dynamically
    procedure FormCreate(Sender: TObject);
    procedure HexEditChange(Sender: TObject);
    procedure FeatureEditClick(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonGenerateStateRecoloringClick(Sender: TObject);
    procedure ButtonGenerateSpritesetRecoloringClick(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonLoadClick(Sender: TObject);
  private
    DisplayMemo: TMemo;
    CopyButton: TButton;
    FNextTop: Integer; // Keeps track of the next top position for new controls
    FColorControls: TList<TColorControlPair>; // List to hold TEdit and TShape pairs
    FLabelsCreated: Boolean; // Flag to check if labels have been created
    function HexToColor(const Hex: string): TColor;
    function IsValidHexCode(const Hex: string): Boolean;
    function SetDefaultEditTopPosition: Integer;
    procedure AddNewFeature;
    procedure CopyButtonClick(Sender: TObject);
    procedure LoadEditsFromIni(const FileName: string);
    procedure SaveEditsToIni(const FileName: string);
    procedure ClearFeatures;
  public
    { Public declarations }
  end;

var
  SchemeCreatorForm: TSchemeCreatorForm;

implementation

{$R *.dfm}

function GetApplicationVersion: string;
var
  InfoSize: DWORD;
  Info: PChar;
  VerInfo: PVSFixedFileInfo;
  VerInfoSize: UINT;
  Major, Minor, Release, Build: Word;
begin
  Result := '';

  InfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), InfoSize);
  if InfoSize > 0 then
  begin
    GetMem(Info, InfoSize);
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, InfoSize, Info) then
      begin
        if VerQueryValue(Info, '\', Pointer(VerInfo), VerInfoSize) then
        begin
          Major := HiWord(VerInfo^.dwFileVersionMS);
          Minor := LoWord(VerInfo^.dwFileVersionMS);
          Result := Format(' v%d.%d', [Major, Minor]);
        end;
      end;
    finally
      FreeMem(Info);
    end;
  end;
end;

procedure TSchemeCreatorForm.FormClick(Sender: TObject);
begin
  ButtonAdd.SetFocus;
end;

procedure TSchemeCreatorForm.FormCreate(Sender: TObject);
begin
  // Initialize the list of color control pairs
  FColorControls := TList<TColorControlPair>.Create;

  // Initialize the labels created flag
  FLabelsCreated := False;

  // Set FNextTop to just below the "Add" button
  FNextTop := SetDefaultEditTopPosition;
  AddNewFeature;

  Caption := 'Scheme Creator' + GetApplicationVersion;
end;

procedure TSchemeCreatorForm.AddNewFeature;
var
  FeatureEdit: TEdit;  // Edit for the feature name (e.g., Hair)
  NewPair: TColorControlPair; // Struct to hold references to the new controls
  BaseTop: Integer;   // Top position for the current feature row
  NextLeft: Integer;  // Left position for the next control in the current row
  HexLabel: TLabel;   // Label for hex edits
  SHexDefault: String; // Default string for hex edits
begin
  // Create the hex labels only once
  if not FLabelsCreated then
  begin
    NextLeft := 20 + 200 + 10; // Start position after the FeatureEdit

    // Create labels for each hex state
    HexLabel := TLabel.Create(Self);
    HexLabel.Parent := Self;
    HexLabel.Top := FNextTop - 25; // Position above the feature edits
    HexLabel.Left := 20;
    HexLabel.Caption := 'Sprite Feature';

    // Create headers for each hex edit state
    for var State in ['Normal', '-Athlete', '-Selected', 'Rival', '-Athlete', '-Selected', 'Zombie', 'Neutral', 'Invincible'] do
    begin
      HexLabel := TLabel.Create(Self);
      HexLabel.Parent := Self;
      HexLabel.Top := FNextTop - 25; // Same top position for all labels
      HexLabel.Left := NextLeft;
      HexLabel.Caption := State;

      // Check if the caption does not start with "-"
      if not State.StartsWith('-') then
        HexLabel.Font.Style := HexLabel.Font.Style + [fsBold]; // Make the label bold

      NextLeft := NextLeft + 80 + 10; // Move to the next position
    end;


    FLabelsCreated := True; // Set the flag to true after creating labels
  end;

  // Create a new TEdit for the feature name (e.g., Hair)
  FeatureEdit := TEdit.Create(Self);
  FeatureEdit.Parent := Self;
  FeatureEdit.Top := FNextTop;
  FeatureEdit.Left := 20;
  FeatureEdit.Width := 200;
  FeatureEdit.Text := 'e.g. LEMMING_HAIR'; // Default name, can be edited
  FeatureEdit.OnClick := FeatureEditClick;

  // Update the base top position for the current feature row
  BaseTop := FeatureEdit.Top;
  NextLeft := FeatureEdit.Left + FeatureEdit.Width + 10; // Position next to the feature edit

  // Create hex edit fields for each state and link them to NewPair
  NewPair.LabelEdit := FeatureEdit; // Associate with the feature name

  SHexDefault := 'e.g. x00BB00';

  // Create and setup each TEdit for different states
  NewPair.HexNormal := TEdit.Create(Self);
  NewPair.HexNormal.Parent := Self;
  NewPair.HexNormal.Top := BaseTop;
  NewPair.HexNormal.Left := NextLeft;
  NewPair.HexNormal.Width := 80;
  NewPair.HexNormal.Text := SHexDefault;
  NewPair.HexNormal.OnClick := FeatureEditClick;
  NewPair.HexNormal.OnChange := HexEditChange;
  NextLeft := NewPair.HexNormal.Left + NewPair.HexNormal.Width + 10;

  NewPair.HexAthlete := TEdit.Create(Self);
  NewPair.HexAthlete.Parent := Self;
  NewPair.HexAthlete.Top := BaseTop;
  NewPair.HexAthlete.Left := NextLeft;
  NewPair.HexAthlete.Width := 80;
  NewPair.HexAthlete.Text := SHexDefault;
  NewPair.HexAthlete.OnClick := FeatureEditClick;
  NewPair.HexAthlete.OnChange := HexEditChange;
  NextLeft := NewPair.HexAthlete.Left + NewPair.HexAthlete.Width + 10;

  NewPair.HexSelected := TEdit.Create(Self);
  NewPair.HexSelected.Parent := Self;
  NewPair.HexSelected.Top := BaseTop;
  NewPair.HexSelected.Left := NextLeft;
  NewPair.HexSelected.Width := 80;
  NewPair.HexSelected.Text := SHexDefault;
  NewPair.HexSelected.OnClick := FeatureEditClick;
  NewPair.HexSelected.OnChange := HexEditChange;
  NextLeft := NewPair.HexSelected.Left + NewPair.HexSelected.Width + 10;

  NewPair.HexRival := TEdit.Create(Self);
  NewPair.HexRival.Parent := Self;
  NewPair.HexRival.Top := BaseTop;
  NewPair.HexRival.Left := NextLeft;
  NewPair.HexRival.Width := 80;
  NewPair.HexRival.Text := SHexDefault;
  NewPair.HexRival.OnClick := FeatureEditClick;
  NewPair.HexRival.OnChange := HexEditChange;
  NextLeft := NewPair.HexRival.Left + NewPair.HexRival.Width + 10;

  NewPair.HexRivalAthlete := TEdit.Create(Self);
  NewPair.HexRivalAthlete.Parent := Self;
  NewPair.HexRivalAthlete.Top := BaseTop;
  NewPair.HexRivalAthlete.Left := NextLeft;
  NewPair.HexRivalAthlete.Width := 80;
  NewPair.HexRivalAthlete.Text := SHexDefault;
  NewPair.HexRivalAthlete.OnClick := FeatureEditClick;
  NewPair.HexRivalAthlete.OnChange := HexEditChange;
  NextLeft := NewPair.HexRivalAthlete.Left + NewPair.HexRivalAthlete.Width + 10;

  NewPair.HexRivalSelected := TEdit.Create(Self);
  NewPair.HexRivalSelected.Parent := Self;
  NewPair.HexRivalSelected.Top := BaseTop;
  NewPair.HexRivalSelected.Left := NextLeft;
  NewPair.HexRivalSelected.Width := 80;
  NewPair.HexRivalSelected.Text := SHexDefault;
  NewPair.HexRivalSelected.OnClick := FeatureEditClick;
  NewPair.HexRivalSelected.OnChange := HexEditChange;
  NextLeft := NewPair.HexRivalSelected.Left + NewPair.HexRivalSelected.Width + 10;

  NewPair.HexZombie := TEdit.Create(Self);
  NewPair.HexZombie.Parent := Self;
  NewPair.HexZombie.Top := BaseTop;
  NewPair.HexZombie.Left := NextLeft;
  NewPair.HexZombie.Width := 80;
  NewPair.HexZombie.Text := SHexDefault;
  NewPair.HexZombie.OnClick := FeatureEditClick;
  NewPair.HexZombie.OnChange := HexEditChange;
  NextLeft := NewPair.HexZombie.Left + NewPair.HexZombie.Width + 10;

  NewPair.HexNeutral := TEdit.Create(Self);
  NewPair.HexNeutral.Parent := Self;
  NewPair.HexNeutral.Top := BaseTop;
  NewPair.HexNeutral.Left := NextLeft;
  NewPair.HexNeutral.Width := 80;
  NewPair.HexNeutral.Text := SHexDefault;
  NewPair.HexNeutral.OnClick := FeatureEditClick;
  NewPair.HexNeutral.OnChange := HexEditChange;
  NextLeft := NewPair.HexNeutral.Left + NewPair.HexNeutral.Width + 10;

  NewPair.HexInvincible := TEdit.Create(Self);
  NewPair.HexInvincible.Parent := Self;
  NewPair.HexInvincible.Top := BaseTop;
  NewPair.HexInvincible.Left := NextLeft;
  NewPair.HexInvincible.Width := 80;
  NewPair.HexInvincible.OnClick := FeatureEditClick;
  NewPair.HexInvincible.Text := SHexDefault;
  NewPair.HexInvincible.OnChange := HexEditChange;

  // Add the new controls to the list
  FColorControls.Add(NewPair);

  // Update the next top position for the following controls
  FNextTop := BaseTop + NewPair.HexNormal.Height + 5; // Set the next top position after the last edit

  // Check if the new top position exceeds the form height
  if FNextTop > ClientHeight then
  begin
    // Increase the height of the form to accommodate new controls
    Height := Height + (NewPair.HexNormal.Height + 15);
  end;
end;

procedure TSchemeCreatorForm.FeatureEditClick(Sender: TObject);
begin
  (Sender as TEdit).SelectAll; // Select all text in the TEdit
end;

procedure TSchemeCreatorForm.ButtonAddClick(Sender: TObject);
begin
  AddNewFeature;
end;

procedure TSchemeCreatorForm.HexEditChange(Sender: TObject);
var
  EditControl: TEdit;
  ColorValue: TColor;
  R, G, B: Byte;
  Brightness: Integer;
  HexValues: TDictionary<string, TEdit>; // Dictionary to store hex codes and their TEdit reference
  IsDuplicate: Boolean;
begin
  EditControl := Sender as TEdit;

  // Update the background color of the TEdit based on the current hex code
  ColorValue := HexToColor(EditControl.Text);
  EditControl.Color := ColorValue;

  // Extract RGB values
  R := GetRValue(ColorValue);
  G := GetGValue(ColorValue);
  B := GetBValue(ColorValue);

  // Calculate perceived brightness
  Brightness := Round(0.299 * R + 0.587 * G + 0.114 * B);

  // Set text color to white if brightness is below a certain threshold
  if Brightness < 200 then
    EditControl.Font.Color := clWhite
  else
    EditControl.Font.Color := clBlack;

  // Initialize the dictionary and duplicate flag
  HexValues := TDictionary<string, TEdit>.Create;
  IsDuplicate := False;

  try
    // Loop through all color pairs to check for duplicates
    for var ColorPair in FColorControls do
    begin
      // Check each state's hex edit field in the color pair
      for var HexEdit in [ColorPair.HexNormal, ColorPair.HexAthlete, ColorPair.HexSelected, ColorPair.HexRival,
                          ColorPair.HexRivalAthlete, ColorPair.HexRivalSelected, ColorPair.HexNeutral,
                          ColorPair.HexZombie, ColorPair.HexInvincible] do
      begin
        if (Copy(HexEdit.Text, 1, 1) = 'x') and (Length(HexEdit.Text) = 7) then // Validate hex format
        begin
          // Check if hex code already exists in the dictionary
          if HexValues.ContainsKey(HexEdit.Text) then
          begin
            IsDuplicate := True; // Duplicate found
            Break;
          end
          else
            HexValues.Add(HexEdit.Text, HexEdit); // Add unique hex code to dictionary
        end;
      end;
      if IsDuplicate then
        Break;
    end;

    // Show or hide the duplicate label based on the duplicate check
    LabelDuplicate.Visible := IsDuplicate;
  finally
    HexValues.Free;
  end;
end;

function TSchemeCreatorForm.HexToColor(const Hex: string): TColor;
var
  R, G, B: Integer;
begin
  // Validate hex format strictly to be exactly 'xRRGGBB'
  if (Length(Hex) = 7) and (Hex[1] = 'x') and
     TryStrToInt('$' + Copy(Hex, 2, 2), R) and
     TryStrToInt('$' + Copy(Hex, 4, 2), G) and
     TryStrToInt('$' + Copy(Hex, 6, 2), B) then
  begin
    // Return RGB color if valid
    Result := RGB(Byte(R), Byte(G), Byte(B));
  end
  else
    Result := clWhite; // Default color if format is incorrect
end;

function TSchemeCreatorForm.IsValidHexCode(const Hex: string): Boolean;
var
  R, G, B: Integer;
begin
  // Valid hex code: "x" followed by exactly six hex characters (RRGGBB format)
  Result := (Length(Hex) = 7) and (Hex[1] = 'x') and
            TryStrToInt('$' + Copy(Hex, 2, 2), R) and
            TryStrToInt('$' + Copy(Hex, 4, 2), G) and
            TryStrToInt('$' + Copy(Hex, 6, 2), B);
end;

procedure TSchemeCreatorForm.ButtonGenerateSpritesetRecoloringClick(Sender: TObject);
var
  Output: TStringList;
  DisplayForm: TForm;
  Feature: string;
begin
  Output := TStringList.Create;
  try
//    // Start the output for the spriteset recoloring
//    Output.Add('$SPRITESET_RECOLORING');
    Output.Add('  MASK xFF00FF'); // Mandatory for all schemes

    // Loop through each ColorPair in the list of color controls
    for var ColorPair in FColorControls do
    begin
      Feature := ColorPair.LabelEdit.Text; // Get the feature name

      // Check and add the normal color
      if IsValidHexCode(ColorPair.HexNormal.Text) then
        Output.Add(Format('  %s %s', [Feature, ColorPair.HexNormal.Text]));

      // Check and add the athlete color
      if IsValidHexCode(ColorPair.HexAthlete.Text) then
        Output.Add(Format('  %s_ATHLETE %s', [Feature, ColorPair.HexAthlete.Text]));

      // Check and add the selected color
      if IsValidHexCode(ColorPair.HexSelected.Text) then
        Output.Add(Format('  %s_SELECTED %s', [Feature, ColorPair.HexSelected.Text]));

      // Check and add the rival color
      if IsValidHexCode(ColorPair.HexRival.Text) then
        Output.Add(Format('  %s_RIVAL %s', [Feature, ColorPair.HexRival.Text]));

      // Check and add the rival athlete color
      if IsValidHexCode(ColorPair.HexRivalAthlete.Text) then
        Output.Add(Format('  %s_RIVAL_ATHLETE %s', [Feature, ColorPair.HexRivalAthlete.Text]));

      // Check and add the rival selected color
      if IsValidHexCode(ColorPair.HexRivalSelected.Text) then
        Output.Add(Format('  %s_RIVAL_SELECTED %s', [Feature, ColorPair.HexRivalSelected.Text]));

      // Check and add the neutral color
      if IsValidHexCode(ColorPair.HexNeutral.Text) then
        Output.Add(Format('  %s_NEUTRAL %s', [Feature, ColorPair.HexNeutral.Text]));

      // Check and add the zombie color
      if IsValidHexCode(ColorPair.HexZombie.Text) then
        Output.Add(Format('  %s_ZOMBIE %s', [Feature, ColorPair.HexZombie.Text]));

      // Check and add the invincible color
      if IsValidHexCode(ColorPair.HexInvincible.Text) then
        Output.Add(Format('  %s_INVINCIBLE %s', [Feature, ColorPair.HexInvincible.Text]));
    end;

//    // End the output for the spriteset recoloring
//    Output.Add('$END');

    // Display the output in a modal form with a memo for easy copying
    DisplayForm := TForm.Create(Self);
    try
      DisplayForm.Caption := 'Spriteset Recoloring Output (Copy-paste/replace the output text into the $SPRITESET_RECOLORING section in scheme.nxmi)';
      DisplayForm.Width := 1400;
      DisplayForm.Height := 800;
      DisplayForm.Position := poScreenCenter;

      // Create and configure the memo for displaying the output
      DisplayMemo := TMemo.Create(DisplayForm);
      DisplayMemo.Parent := DisplayForm;
      DisplayMemo.Align := alClient;
      DisplayMemo.ReadOnly := True;
      DisplayMemo.ScrollBars := ssVertical;
      DisplayMemo.Lines.Text := Output.Text;
      DisplayMemo.Font.Size := 10;
      DisplayMemo.WordWrap := False; // Ensure lines maintain formatting

      // Create and configure the copy button
      CopyButton := TButton.Create(DisplayForm);
      CopyButton.Parent := DisplayForm;
      CopyButton.Caption := 'Copy to Clipboard';
      CopyButton.Align := alBottom;
      CopyButton.Height := 30;
      CopyButton.OnClick := CopyButtonClick;

      // Show the form modally
      DisplayForm.ShowModal;
    finally
      DisplayForm.Free;
    end;
  finally
    Output.Free;
  end;
end;

procedure TSchemeCreatorForm.ButtonGenerateStateRecoloringClick(Sender: TObject);
var
  Feature, FromColor, ToColor: string;
  Output: TStringList;
  DisplayForm: TForm;
  States: array[0..7] of TStateEntry; // Array for all states
begin
  Output := TStringList.Create;
  try
//    // Start the output for the state recoloring
//    Output.Add('$STATE_RECOLORING');

    // Loop through each ColorPair in the list of color controls
    for var ColorPair in FColorControls do
    begin
      Feature := ColorPair.LabelEdit.Text;  // Get the feature name

      // Set up each state transformation with Normal as the FROM and the specific state as TO
      States[0].Name := 'ATHLETE';
      States[0].FromEdit := ColorPair.HexNormal;
      States[0].ToEdit := ColorPair.HexAthlete;

      States[1].Name := 'SELECTED';
      States[1].FromEdit := ColorPair.HexNormal;
      States[1].ToEdit := ColorPair.HexSelected;

      States[2].Name := 'RIVAL';
      States[2].FromEdit := ColorPair.HexNormal;
      States[2].ToEdit := ColorPair.HexRival;

      States[3].Name := 'RIVAL_ATHLETE';
      States[3].FromEdit := ColorPair.HexNormal;
      States[3].ToEdit := ColorPair.HexRivalAthlete;

      States[4].Name := 'RIVAL_SELECTED';
      States[4].FromEdit := ColorPair.HexNormal;
      States[4].ToEdit := ColorPair.HexRivalSelected;

      States[5].Name := 'NEUTRAL';
      States[5].FromEdit := ColorPair.HexNormal;
      States[5].ToEdit := ColorPair.HexNeutral;

      States[6].Name := 'ZOMBIE';
      States[6].FromEdit := ColorPair.HexNormal;
      States[6].ToEdit := ColorPair.HexZombie;

      States[7].Name := 'INVINCIBLE';
      States[7].FromEdit := ColorPair.HexNormal;
      States[7].ToEdit := ColorPair.HexInvincible;

      // Add header for each feature for readability
      Output.Add(Format('# Feature: %s', [Feature]));

      // Generate formatted output for each state, with validation
      for var State in States do
      begin
        FromColor := State.FromEdit.Text;  // FROM color is always HexNormal
        ToColor := State.ToEdit.Text;      // TO color varies by state

        // Check if both colors are valid hex codes
        if IsValidHexCode(FromColor) and IsValidHexCode(ToColor) then
        begin
          // Add the formatted string for each valid state
          Output.Add(Format('  $%s', [State.Name]));
          Output.Add(Format('    FROM %s', [FromColor]));
          Output.Add(Format('    TO %s', [ToColor]));
          Output.Add('  $END');
          Output.Add(''); // Blank line between states for readability
        end else
          // Do nothing
      end;
    end;

//    // End the output for the state recoloring
//    Output.Add('$END');

    // Display the output in a modal form with a memo for easy copying
    DisplayForm := TForm.Create(Self);
    try
      DisplayForm.Caption := 'State Recoloring Output (Copy-paste/replace the output text into $STATE_RECOLORING section in scheme.nxmi)';
      DisplayForm.Width := 1400;
      DisplayForm.Height := 800;
      DisplayForm.Position := poScreenCenter;

      // Create and configure the memo for displaying the output
      DisplayMemo := TMemo.Create(DisplayForm);
      DisplayMemo.Parent := DisplayForm;
      DisplayMemo.Align := alClient;
      DisplayMemo.ReadOnly := True;
      DisplayMemo.ScrollBars := ssVertical;
      DisplayMemo.Lines.Text := Output.Text;
      DisplayMemo.Font.Size := 10;
      DisplayMemo.WordWrap := False; // Ensure lines maintain formatting

      // Create and configure the copy button
      CopyButton := TButton.Create(DisplayForm);
      CopyButton.Parent := DisplayForm;
      CopyButton.Caption := 'Copy to Clipboard';
      CopyButton.Align := alBottom;
      CopyButton.Height := 30;
      CopyButton.OnClick := CopyButtonClick;

      // Show the form modally
      DisplayForm.ShowModal;
    finally
      DisplayForm.Free;
    end;
  finally
    Output.Free;
  end;
end;

procedure TSchemeCreatorForm.ButtonLoadClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Filter := 'Scheme Files (*.ini)|*.ini|All Files (*.*)|*.*';
    OpenDialog.DefaultExt := 'ini';
    OpenDialog.Title := 'Load Scheme File';
    OpenDialog.InitialDir := ExtractFilePath(ParamStr(0));

    if OpenDialog.Execute then
    begin
      LoadEditsFromIni(OpenDialog.FileName);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TSchemeCreatorForm.ButtonSaveClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Filter := 'Scheme Files (*.ini)|*.ini|All Files (*.*)|*.*';
    SaveDialog.DefaultExt := 'ini';
    SaveDialog.Title := 'Save Scheme File';
    SaveDialog.InitialDir := ExtractFilePath(ParamStr(0));

    if SaveDialog.Execute then
    begin
      SaveEditsToIni(SaveDialog.FileName);
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TSchemeCreatorForm.CopyButtonClick(Sender: TObject);
begin
  Clipboard.AsText := DisplayMemo.Lines.Text; // Copy text to clipboard
  CopyButton.Caption := 'Copied!';
end;

procedure TSchemeCreatorForm.SaveEditsToIni(const FileName: string);
var
  IniFile: TIniFile;
  i: Integer;
  Pair: TColorControlPair;
  SectionName: string;
begin
  IniFile := TIniFile.Create(FileName);
  try
    for i := 0 to FColorControls.Count - 1 do
    begin
      Pair := FColorControls[i];
      SectionName := Format('Feature%d', [i + 1]); // Create unique section names (Feature1, Feature2, etc.)

      // Save the feature label and all hex values under the section
      IniFile.WriteString(SectionName, 'SpriteFeature', Pair.LabelEdit.Text);
      IniFile.WriteString(SectionName, 'Normal', Pair.HexNormal.Text);
      IniFile.WriteString(SectionName, '-Athlete', Pair.HexAthlete.Text);
      IniFile.WriteString(SectionName, '-Selected', Pair.HexSelected.Text);
      IniFile.WriteString(SectionName, 'Rival', Pair.HexRival.Text);
      IniFile.WriteString(SectionName, '-Athlete (Rival)', Pair.HexRivalAthlete.Text);
      IniFile.WriteString(SectionName, '-Selected (Rival)', Pair.HexRivalSelected.Text);
      IniFile.WriteString(SectionName, 'Zombie', Pair.HexZombie.Text);
      IniFile.WriteString(SectionName, 'Neutral', Pair.HexNeutral.Text);
      IniFile.WriteString(SectionName, 'Invincible', Pair.HexInvincible.Text);
    end;
  finally
    IniFile.Free;
  end;
end;

function TSchemeCreatorForm.SetDefaultEditTopPosition: Integer;
begin
  Result := ButtonAdd.Top + ButtonAdd.Height + 30;
end;

procedure TSchemeCreatorForm.LoadEditsFromIni(const FileName: string);
var
  IniFile: TIniFile;
  i: Integer;
  SectionName: string;
  FeatureName, Normal, Athlete, Selected, Rival, AthleteRival, SelectedRival, Zombie, Neutral, Invincible: string;
begin
  IniFile := TIniFile.Create(FileName);
  try
    // Clear any existing controls before loading new ones
    ClearFeatures;

    i := 1;
    while True do
    begin
      SectionName := Format('Feature%d', [i]);
      FeatureName := IniFile.ReadString(SectionName, 'SpriteFeature', '');
      if FeatureName = '' then
        Break; // Stop loading when no more sections are found

      // Read all the hex values from the section
      Normal := IniFile.ReadString(SectionName, 'Normal', '');
      Athlete := IniFile.ReadString(SectionName, '-Athlete', '');
      Selected := IniFile.ReadString(SectionName, '-Selected', '');
      Rival := IniFile.ReadString(SectionName, 'Rival', '');
      AthleteRival := IniFile.ReadString(SectionName, '-Athlete (Rival)', '');
      SelectedRival := IniFile.ReadString(SectionName, '-Selected (Rival)', '');
      Zombie := IniFile.ReadString(SectionName, 'Zombie', '');
      Neutral := IniFile.ReadString(SectionName, 'Neutral', '');
      Invincible := IniFile.ReadString(SectionName, 'Invincible', '');

      // Add a new feature row
      AddNewFeature;

      // Set the loaded values to the controls
      FColorControls.Last.LabelEdit.Text := FeatureName;
      FColorControls.Last.HexNormal.Text := Normal;
      FColorControls.Last.HexAthlete.Text := Athlete;
      FColorControls.Last.HexSelected.Text := Selected;
      FColorControls.Last.HexRival.Text := Rival;
      FColorControls.Last.HexRivalAthlete.Text := AthleteRival;
      FColorControls.Last.HexRivalSelected.Text := SelectedRival;
      FColorControls.Last.HexZombie.Text := Zombie;
      FColorControls.Last.HexNeutral.Text := Neutral;
      FColorControls.Last.HexInvincible.Text := Invincible;

      Inc(i);
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TSchemeCreatorForm.ClearFeatures;
var
  Pair: TColorControlPair;
begin
  for Pair in FColorControls do
  begin
    Pair.LabelEdit.Free;
    Pair.HexNormal.Free;
    Pair.HexAthlete.Free;
    Pair.HexSelected.Free;
    Pair.HexRival.Free;
    Pair.HexRivalAthlete.Free;
    Pair.HexRivalSelected.Free;
    Pair.HexZombie.Free;
    Pair.HexNeutral.Free;
    Pair.HexInvincible.Free;
  end;
  FColorControls.Clear;
  FNextTop := SetDefaultEditTopPosition; // Reset the top position for new controls
end;

end.

