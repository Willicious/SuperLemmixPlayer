unit FLevelInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  LemTypes, LemStrings, LemCore, LemTalisman, UMisc, Types, Math,
  GR32, GR32_Image, PngInterface;

type
  TLevelInfoPanelMove = (pmNextColumnTop, pmNextColumnSame, pmMoveHorz,
                         pmNextRowLeft, pmNextRowSame, pmNextRowPadLeft, pmNextRowPadSame);

  TLevelInfoPanel = class(TForm)
      btnClose: TButton;
      imgTemplate: TImage32;
      lblTemplate: TLabel;
    private
      fCurrentPos: TPoint;
      fMinSize: TPoint;
      fIcons: TBitmap32;

      procedure Add(aIcon: Integer; aText: Integer; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure Add(aIcon: Integer; aText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure AddClose;

      procedure Reposition(aMovement: TLevelInfoPanelMove);

      procedure ApplySize; overload;
      procedure ApplySize(aForcedMinWidth: Integer; aForcedMinHeight: Integer); overload;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure ShowPopup;
      procedure PrepareEmbed;
  end;

var
  LevelInfoPanel: TLevelInfoPanel;

implementation

const
  COLOR_TALISMAN_DIRECT_RESTRICTION = $D00000;
  COLOR_TALISMAN_INDIRECT_RESTRICTION = $D0D000;

  PADDING_SIZE = 8;

  NORMAL_SPACING = 36;

  COLUMN_SPACING = 96;


{$R *.dfm}

{ TLevelInfoPanel }

constructor TLevelInfoPanel.Create(aOwner: TComponent);
begin
  inherited;

  fIcons := TBitmap32.Create;
  TPNGInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'levelinfo_icons.png', fIcons);

  fCurrentPos := Types.Point(PADDING_SIZE, PADDING_SIZE);
end;

destructor TLevelInfoPanel.Destroy;
begin
  fIcons.Free;

  inherited;
end;

procedure TLevelInfoPanel.ShowPopup;
begin
  BorderStyle := bsToolWindow;
end;

procedure TLevelInfoPanel.Add(aIcon: Integer; aText: String;
  aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer);
var
  NewImage: TImage32;
  NewLabel: TLabel;
begin
  NewImage := TImage32.Create(self);
  NewImage.Assign(imgTemplate);

  NewLabel := TLabel.Create(self);
  NewLabel.Assign(lblTemplate);

  NewImage.Bitmap.SetSize(32, 32);
  NewImage.Bitmap.Clear;
  fIcons.DrawTo(NewImage.Bitmap, 0, 0, SizedRect((aIcon mod 4) * 32, (aIcon div 4) * 32, 32, 32));

  NewLabel.Caption := aText;
  if aColor >= 0 then NewLabel.Font.Color := aColor;

  if aTextOnRight then
  begin
    NewImage.Left := fCurrentPos.X;
    NewImage.Top := fCurrentPos.Y;
    NewLabel.Left := fCurrentPos.X + NewImage.Width + PADDING_SIZE;
    NewLabel.Top := fCurrentPos.Y + ((NewImage.Height - NewLabel.Height) div 2);
  end else begin
    NewLabel.Left := fCurrentPos.X + ((NewImage.Width - NewLabel.Width) div 2);
    NewLabel.Top := fCurrentPos.Y;
    NewImage.Left := fCurrentPos.X;
    NewImage.Top := fCurrentPos.Y + NewLabel.Height + PADDING_SIZE;
  end;

  fMinSize.X := Max(fMinSize.X, Max(NewImage.Left + NewImage.Width, NewLabel.Left + NewLabel.Width) + PADDING_SIZE);
  fMinSize.Y := Max(fMinSize.Y, Max(NewImage.Top + NewImage.Height, NewLabel.Top + NewLabel.Height) + PADDING_SIZE);

  Reposition(aMovement);
end;

procedure TLevelInfoPanel.Add(aIcon, aText: Integer; aTextOnRight: Boolean;
  aMovement: TLevelInfoPanelMove; aColor: Integer);
begin
  Add(aIcon, IntToStr(aText), aTextOnRight, aMovement, aColor);
end;

procedure TLevelInfoPanel.AddClose;
begin
  btnClose.Top := fMinSize.Y;

  if fMinSize.X < btnClose.Width + (PADDING_SIZE * 2) then
  begin
    btnClose.Left := PADDING_SIZE;
    fMinSize.X := btnClose.Width + (PADDING_SIZE * 2);
  end else
    btnClose.Left := (ClientWidth - btnClose.Width) div 2;

  fMinSize.Y := btnClose.Top + btnClose.Height + PADDING_SIZE;
end;

procedure TLevelInfoPanel.ApplySize(aForcedMinWidth, aForcedMinHeight: Integer);
var
  i: Integer;
  Diff: Integer;
begin
  if (aForcedMinWidth > fMinSize.X) then
  begin
    Diff := (aForcedMinWidth - fMinSize.X) div 2;

    for i := 0 to ControlCount-1 do
      Controls[i].Left := Controls[i].Left + Diff;

    fMinSize.X := aForcedMinWidth;
  end;

  if (aForcedMinHeight > fMinSize.Y) then
  begin
    Diff := (aForcedMinHeight - fMinSize.Y) div 2;

    for i := 0 to ControlCount-1 do
      Controls[i].Top := Controls[i].Top + Diff;

    fMinSize.Y := aForcedMinHeight;
  end;

  ClientWidth := fMinSize.X;
  ClientHeight := fMinSize.Y;
end;

procedure TLevelInfoPanel.ApplySize;
begin
  ApplySize(fMinSize.X, fMinSize.Y);
end;

procedure TLevelInfoPanel.Reposition(aMovement: TLevelInfoPanelMove);
begin
  case aMovement of
    pmNextColumnTop: begin fCurrentPos.X := fCurrentPos.X + COLUMN_SPACING; fCurrentPos.Y := PADDING_SIZE; end;
    pmNextColumnSame: fCurrentPos.X := fCurrentPos.X + COLUMN_SPACING;
    pmMoveHorz: fCurrentPos.X := fCurrentPos.X + NORMAL_SPACING;
    pmNextRowLeft: begin fCurrentPos.X := PADDING_SIZE; fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING; end;
    pmNextRowSame: fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING;
    pmNextRowPadLeft: begin fCurrentPos.X := PADDING_SIZE; fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING + PADDING_SIZE; end;
    pmNextRowPadSame: fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING + PADDING_SIZE;
  end;
end;

const // Icon indexes
  ICON_NORMAL_LEMMING = 0;
  ICON_ZOMBIE_LEMMING = 1;
  ICON_NEUTRAL_LEMMING = 2;

  ICON_SAVE_REQUIREMENT = 3;
  ICON_RELEASE_RATE = 4;
  ICON_TIME_LIMIT = 5;

  ICON_SKILLS: array[spbWalker..spbCloner] of Integer = (
    6, // Walker
    7, // Jumper
    8, // Shimmier
    9, // Climber
    10, // Swimmer
    11, // Floater
    12, // Glider
    13, // Disarmer
    14, // Bomber
    15, // Stoner
    16, // Blocker
    17, // Platformer
    18, // Builder
    19, // Stacker
    20, // Basher
    21, // Fencer
    22, // Miner
    23, // Digger
    24 // Cloner
  );

  ICON_TALISMAN: array[tcBronze..tcGold] of Integer =
    ( 25, 26, 27 );

  ICON_TALISMAN_UNOBTAINED_OFFSET = 3;

  ICON_MAX_SKILLS = 31;

procedure TLevelInfoPanel.PrepareEmbed;
begin


  ApplySize(377, 312);
end;

end.
