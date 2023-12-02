unit CustomPopup;

// For maximum control, create a TCustomPopup, set Caption and Text properties, then use AddButton to add buttons to it.
// Call it via ShowModal, and the return value will be the tag assigned to whichever button was clicked.
// Due to how ShowModal works, a tag of 0 cannot be used.


// However, a quick version does exist:
// Use RunCustomPopup(aOwner, aCaption, aText, aButtons): Integer;
//       aOwner is a TComponent, which would usually be the calling class's "self"
//       aCaption and aText are strings which are used as-is
//       aButtons is a list of labels for the buttons, seperated by | characters
//       Result is the ***1-BASED*** index of the button that was clicked (because ModalResult doesn't like return values of 0)

interface

uses
  Forms, Controls, StdCtrls, Math, Contnrs, Classes, StrUtils, SysUtils;

const
  MIN_BUTTON_WIDTH = 75;
  MIN_FORM_WIDTH = 160;
  PADDING_SIZE = 12;

type
  TButtonList = class(TObjectList)
    private
      fOwner: TComponent;
      function GetItem(Index: Integer): TButton;
    public
      constructor Create(aOwner: TComponent);
      function Add: TButton;
      property Items[Index: Integer]: TButton read GetItem; default;
      property List;
  end;

  TCustomPopup = class(TForm)
    private
      fButtons: TButtonList;
      fText: String;
      procedure Build(Sender: TObject);
      procedure ButtonClick(Sender: TObject);
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
      procedure AddButton(aCaption: String; aTag: Integer);
      property Buttons: TButtonList read fButtons;
      property Text: String read fText write fText;
  end;

  function RunCustomPopup(aOwner: TComponent; aCaption, aText, aButtons: String): Integer;

implementation

function RunCustomPopup(aOwner: TComponent; aCaption, aText, aButtons: String): Integer;
var
  F: TCustomPopup;
  SplitPos: Integer;
  n: Integer;
begin
  F := TCustomPopup.Create(aOwner);
  try
    F.Caption := aCaption;
    F.Text := aText;

    aButtons := aButtons + '|';
    n := 1;

    SplitPos := Pos('|', aButtons);
    while SplitPos <> 0 do
    begin
      F.AddButton(LeftStr(aButtons, SplitPos-1), n);
      aButtons := RightStr(aButtons, Length(aButtons)-SplitPos);
      Inc(n);
      SplitPos := Pos('|', aButtons);
    end;

    Result := F.ShowModal;
  finally
    F.Free;
  end;
end;

{TCustomPopup}

constructor TCustomPopup.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
  fButtons := TButtonList.Create(self);

  { Since we aren't using a .dfm file here (to keep this unit as a single file),
    we must configure the properties that differ from default manually. }
  Name := 'POPUP_WINDOW';
  BorderStyle := bsToolWindow;
  Position := poOwnerFormCenter;
  OnShow := Build;
  BorderIcons := [];
end;

destructor TCustomPopup.Destroy;
begin
  fButtons.Free;
  inherited;
end;

procedure TCustomPopup.Build(Sender: TObject);
var
  Lbl: TLabel;
  i: Integer;
  TotalButtonWidth: Integer;
  x, y: Integer;

  CW, CH: Integer;

  procedure PrepareCaption;
  var
    i: Integer;
    Substr: String;
    Linebreaks: Integer;
  begin
   // Changes all line returns to just CRs, and detects actual width / height because
   // Canvas.TextWidth/TextHeight is not reliable in text that has linebreaks.

    fText := StringReplace(fText, #13 + #10, #13, [rfReplaceAll]); // Change all CRLF to just CR
    fText := StringReplace(fText, #10, #13, [rfReplaceAll]);       // Change any remaining lone LFs to CRs

    fText := fText + #13; // Put a dummy one at the end to make the loop easier

    LineBreaks := 0;
    Substr := '';
    CW := 0;
    CH := 0;
    for i := 1 to Length(fText) do
      if fText[i] <> #13 then
        SubStr := SubStr + fText[i]
      else begin
        if Canvas.TextWidth(SubStr) > CW then CW := Canvas.TextWidth(Substr);
        if LineBreaks = 0 then CH := Canvas.TextHeight(Substr);
        Inc(LineBreaks);
        SubStr := '';
      end;
    CH := CH * LineBreaks;

    fText := LeftStr(fText, Length(fText)-1); // Remove dummy CR
  end;

begin
  Lbl := TLabel.Create(self);

  PrepareCaption;

  with Lbl do
  begin
    AutoSize := true;
    Parent := self;
    Name := 'LABEL';
    Caption := fText;
    Left := PADDING_SIZE;
    Top := PADDING_SIZE;
    self.ClientWidth := CW + (PADDING_SIZE * 2);
    self.ClientHeight := CH + (PADDING_SIZE * 2);
  end;

  TotalButtonWidth := 0;
  for i := 0 to fButtons.Count-1 do
    Inc(TotalButtonWidth, fButtons[i].Width);
  Inc(TotalButtonWidth, (fButtons.Count-1) * PADDING_SIZE); // Padding

  if ClientWidth < (TotalButtonWidth + (PADDING_SIZE * 2)) then
    ClientWidth := TotalButtonWidth + (PADDING_SIZE * 2);

  if ClientWidth < MIN_FORM_WIDTH then
    ClientWidth := MIN_FORM_WIDTH;

  x := (ClientWidth - TotalButtonWidth) div 2;
  y := ClientHeight;
  ClientHeight := ClientHeight + 25 + PADDING_SIZE; // Button height is 25, + 10 for padding

  for i := 0 to fButtons.Count-1 do
  begin
    fButtons[i].Left := x;
    fButtons[i].Top := y;
    Inc(x, fButtons[i].Width + PADDING_SIZE);
  end;

  Lbl.Left := (ClientWidth - Lbl.Width) div 2;
end;

procedure TCustomPopup.AddButton(aCaption: String; aTag: Integer);
begin
  if aTag = 0 then
    raise Exception.Create('TCustomPopup tried to create a button with a tag of zero.');

  with fButtons.Add do
  begin
    Name := 'BUTTON_' + IntToStr(aTag);
    Parent := self;
    Caption := aCaption;
    Tag := aTag;
    Width := Max(Canvas.TextWidth(Caption) + PADDING_SIZE, MIN_BUTTON_WIDTH);
    OnClick := ButtonClick;
  end;
end;

procedure TCustomPopup.ButtonClick(Sender: TObject);
var
  Btn: TComponent absolute Sender;
begin
  if not (Sender is TComponent) then Exit;
  ModalResult := Btn.Tag;
end;

{ TButtonList }

constructor TButtonList.Create(aOwner: TComponent);
var
  aOwnsObjects: Boolean;
begin
  aOwnsObjects := true;
  inherited Create(aOwnsObjects);

  fOwner := aOwner;
end;

function TButtonList.Add: TButton;
begin
  Result := TButton.Create(fOwner);
  inherited Add(Result);
end;

function TButtonList.GetItem(Index: Integer): TButton;
begin
  Result := inherited Get(Index);
end;

end.
