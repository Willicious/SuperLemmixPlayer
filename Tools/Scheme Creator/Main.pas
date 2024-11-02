unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.UITypes, System.Generics.Collections,
  System.Math;

// Define a record to store each TEdit for different states
type
  TColorControlPair = record
    LabelEdit: TEdit;  // TEdit for the aspect name
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

  TSchemeCreatorForm = class(TForm)
    ButtonAdd: TButton;
    ButtonGenerate: TButton; // The "Add" button to create new items dynamically
    procedure FormCreate(Sender: TObject);
    procedure HexEditChange(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonGenerateClick(Sender: TObject);
  private
    FNextTop: Integer; // Keeps track of the next top position for new controls
    FColorControls: TList<TColorControlPair>; // List to hold TEdit and TShape pairs
    FLabelsCreated: Boolean; // Flag to check if labels have been created
    function HexToColor(const Hex: string): TColor;
  public
    { Public declarations }
  end;

var
  SchemeCreatorForm: TSchemeCreatorForm;

implementation

{$R *.dfm}

procedure TSchemeCreatorForm.FormCreate(Sender: TObject);
begin
  // Initialize the list of color control pairs
  FColorControls := TList<TColorControlPair>.Create;

  // Initialize the labels created flag
  FLabelsCreated := False;

  // Set FNextTop to just below the "Add" button
  FNextTop := ButtonAdd.Top + ButtonAdd.Height + 30;
  ButtonAddClick(Sender);
end;

procedure TSchemeCreatorForm.ButtonAddClick(Sender: TObject);
var
  AspectEdit: TEdit;  // Edit for the aspect name (e.g., Hair)
  NewPair: TColorControlPair; // Struct to hold references to the new controls
  BaseTop: Integer;   // Top position for the current aspect row
  NextLeft: Integer;  // Left position for the next control in the current row
  HexLabel: TLabel;   // Label for hex edits
begin
  // Create the hex labels only once
  if not FLabelsCreated then
  begin
    NextLeft := 20 + 200 + 10; // Start position after the AspectEdit

    // Create labels for each hex state
    HexLabel := TLabel.Create(Self);
    HexLabel.Parent := Self;
    HexLabel.Top := FNextTop - 25; // Position above the aspect edits
    HexLabel.Left := 20;
    HexLabel.Caption := 'Sprite Element';

    // Create headers for each hex edit state
    for var State in ['Normal', '-Athlete', '-Selected', 'Rival', '-Athlete', '-Selected', 'Zombie', 'Neutral', 'Invincible'] do
    begin
      HexLabel := TLabel.Create(Self);
      HexLabel.Parent := Self;
      HexLabel.Top := FNextTop - 25; // Same top position for all labels
      HexLabel.Left := NextLeft;
      HexLabel.Caption := State;
      NextLeft := NextLeft + 80 + 10; // Move to the next position
    end;

    FLabelsCreated := True; // Set the flag to true after creating labels
  end;

  // Create a new TEdit for the aspect name (e.g., Hair)
  AspectEdit := TEdit.Create(Self);
  AspectEdit.Parent := Self;
  AspectEdit.Top := FNextTop;
  AspectEdit.Left := 20;
  AspectEdit.Width := 200;
  AspectEdit.Text := 'e.g. LEMMING_HAIR'; // Default name, can be edited

  // Update the base top position for the current aspect row
  BaseTop := AspectEdit.Top;
  NextLeft := AspectEdit.Left + AspectEdit.Width + 10; // Position next to the aspect edit

  // Create hex edit fields for each state and link them to NewPair
  NewPair.LabelEdit := AspectEdit; // Associate with the aspect name

  // Create and setup each TEdit for different states
  NewPair.HexNormal := TEdit.Create(Self);
  NewPair.HexNormal.Parent := Self;
  NewPair.HexNormal.Top := BaseTop;
  NewPair.HexNormal.Left := NextLeft;
  NewPair.HexNormal.Width := 80;
  NewPair.HexNormal.Text := 'xFFFFFF'; // Default color
  NewPair.HexNormal.OnChange := HexEditChange;
  NextLeft := NewPair.HexNormal.Left + NewPair.HexNormal.Width + 10;

  NewPair.HexAthlete := TEdit.Create(Self);
  NewPair.HexAthlete.Parent := Self;
  NewPair.HexAthlete.Top := BaseTop;
  NewPair.HexAthlete.Left := NextLeft;
  NewPair.HexAthlete.Width := 80;
  NewPair.HexAthlete.Text := 'xFFFFFF'; // Default color
  NewPair.HexAthlete.OnChange := HexEditChange;
  NextLeft := NewPair.HexAthlete.Left + NewPair.HexAthlete.Width + 10;

  NewPair.HexSelected := TEdit.Create(Self);
  NewPair.HexSelected.Parent := Self;
  NewPair.HexSelected.Top := BaseTop;
  NewPair.HexSelected.Left := NextLeft;
  NewPair.HexSelected.Width := 80;
  NewPair.HexSelected.Text := 'xFFFFFF'; // Default color
  NewPair.HexSelected.OnChange := HexEditChange;
  NextLeft := NewPair.HexSelected.Left + NewPair.HexSelected.Width + 10;

  NewPair.HexRival := TEdit.Create(Self);
  NewPair.HexRival.Parent := Self;
  NewPair.HexRival.Top := BaseTop;
  NewPair.HexRival.Left := NextLeft;
  NewPair.HexRival.Width := 80;
  NewPair.HexRival.Text := 'xFFFFFF'; // Default color
  NewPair.HexRival.OnChange := HexEditChange;
  NextLeft := NewPair.HexRival.Left + NewPair.HexRival.Width + 10;

  NewPair.HexRivalAthlete := TEdit.Create(Self);
  NewPair.HexRivalAthlete.Parent := Self;
  NewPair.HexRivalAthlete.Top := BaseTop;
  NewPair.HexRivalAthlete.Left := NextLeft;
  NewPair.HexRivalAthlete.Width := 80;
  NewPair.HexRivalAthlete.Text := 'xFFFFFF'; // Default color
  NewPair.HexRivalAthlete.OnChange := HexEditChange;
  NextLeft := NewPair.HexRivalAthlete.Left + NewPair.HexRivalAthlete.Width + 10;

  NewPair.HexRivalSelected := TEdit.Create(Self);
  NewPair.HexRivalSelected.Parent := Self;
  NewPair.HexRivalSelected.Top := BaseTop;
  NewPair.HexRivalSelected.Left := NextLeft;
  NewPair.HexRivalSelected.Width := 80;
  NewPair.HexRivalSelected.Text := 'xFFFFFF'; // Default color
  NewPair.HexRivalSelected.OnChange := HexEditChange;
  NextLeft := NewPair.HexRivalSelected.Left + NewPair.HexRivalSelected.Width + 10;

  NewPair.HexZombie := TEdit.Create(Self);
  NewPair.HexZombie.Parent := Self;
  NewPair.HexZombie.Top := BaseTop;
  NewPair.HexZombie.Left := NextLeft;
  NewPair.HexZombie.Width := 80;
  NewPair.HexZombie.Text := 'xFFFFFF'; // Default color
  NewPair.HexZombie.OnChange := HexEditChange;
  NextLeft := NewPair.HexZombie.Left + NewPair.HexZombie.Width + 10;

  NewPair.HexNeutral := TEdit.Create(Self);
  NewPair.HexNeutral.Parent := Self;
  NewPair.HexNeutral.Top := BaseTop;
  NewPair.HexNeutral.Left := NextLeft;
  NewPair.HexNeutral.Width := 80;
  NewPair.HexNeutral.Text := 'xFFFFFF'; // Default color
  NewPair.HexNeutral.OnChange := HexEditChange;
  NextLeft := NewPair.HexNeutral.Left + NewPair.HexNeutral.Width + 10;

  NewPair.HexInvincible := TEdit.Create(Self);
  NewPair.HexInvincible.Parent := Self;
  NewPair.HexInvincible.Top := BaseTop;
  NewPair.HexInvincible.Left := NextLeft;
  NewPair.HexInvincible.Width := 80;
  NewPair.HexInvincible.Text := 'xFFFFFF'; // Default color
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

procedure TSchemeCreatorForm.HexEditChange(Sender: TObject);
var
  EditControl: TEdit;
  ColorValue: TColor;
  R, G, B: Byte;
  Brightness: Integer;
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
  // Using the formula: 0.299*R + 0.587*G + 0.114*B
  Brightness := Round(0.299 * R + 0.587 * G + 0.114 * B);

  // Set text color to white if the brightness is below a certain threshold (e.g., 128)
  if Brightness < 200 then
    EditControl.Font.Color := clWhite
  else
    EditControl.Font.Color := clBlack; // Change to black for lighter colors
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

// This will write everything to a text file eventually
procedure TSchemeCreatorForm.ButtonGenerateClick(Sender: TObject);
var
  Aspect: string;
  Output: TStringList;
begin
  Output := TStringList.Create;
  try
    for var ColorPair in FColorControls do
    begin
      Aspect := ColorPair.LabelEdit.Text; // Get the aspect name

      // Collect hex values for all states
      Output.Add(Format('%s: Normal: %s, Athlete: %s, Selected: %s, Rival: %s, Rival Athlete: %s, Rival Selected: %s, Zombie: %s, Neutral: %s, Invincible: %s',
        [Aspect,
         ColorPair.HexNormal.Text,
         ColorPair.HexAthlete.Text,
         ColorPair.HexSelected.Text,
         ColorPair.HexRival.Text,
         ColorPair.HexRivalAthlete.Text,
         ColorPair.HexRivalSelected.Text,
         ColorPair.HexZombie.Text,
         ColorPair.HexNeutral.Text,
         ColorPair.HexInvincible.Text]));
    end;

    ShowMessage(Output.Text);
  finally
    Output.Free;
  end;
end;

end.

