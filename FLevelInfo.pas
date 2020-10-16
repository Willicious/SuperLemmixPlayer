unit FLevelInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Themes,
  LemLevel, LemTalisman,
  LemTypes, LemStrings, LemCore,
  UMisc, Types, Math,
  GR32, GR32_Image, GR32_Resamplers, PngInterface;

const
  AS_PANEL_WIDTH = 377;
  AS_PANEL_HEIGHT = 312;

  MIN_PREVIEW_HEIGHT = 32;

type
  TLevelInfoPanelMove = (pmNone,
                         pmNextColumnTop, pmNextColumnSame, pmMoveHorz,
                         pmNextRowLeft, pmNextRowSame, pmNextRowPadLeft, pmNextRowPadSame);

  TLevelInfoPanel = class(TForm)
      btnClose: TButton;
    private
      fCurrentPos: TPoint;
      fMinSize: TPoint;
      fIcons: TBitmap32;

      fLevel: TLevel;

      procedure Add(aIcon: Integer; aText: Integer; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure Add(aIcon: Integer; aText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure AddClose;

      procedure Reposition(aMovement: TLevelInfoPanelMove);

      procedure ApplySize; overload;
      procedure ApplySize(aForcedMinWidth: Integer; aForcedMinHeight: Integer); overload;

      procedure AddPreview;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      procedure ShowPopup;
      procedure PrepareEmbed;

      procedure Wipe;

      property Level: TLevel read fLevel write fLevel;
  end;

var
  LevelInfoPanel: TLevelInfoPanel;

implementation

uses
  GameControl;

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
  fIcons.DrawMode := dmBlend;

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

procedure TLevelInfoPanel.Wipe;
var
  i: Integer;
begin
  btnClose.Visible := false;

  for i := ControlCount-1 downto 0 do
    if (Controls[i] <> btnClose) then
      Controls[i].Free;

  fMinSize := Types.Point(PADDING_SIZE * 2, PADDING_SIZE * 2);
  fCurrentPos := Types.Point(PADDING_SIZE, PADDING_SIZE);
end;

procedure TLevelInfoPanel.Add(aIcon: Integer; aText: String;
  aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer);
var
  NewImage: TImage32;
  NewLabel: TLabel;
begin
  NewImage := TImage32.Create(self);
  NewImage.Parent := self;
  NewImage.Width := 32;
  NewImage.Height := 32;

  NewLabel := TLabel.Create(self);
  NewLabel.Parent := self;
  NewLabel.Font.Style := [fsBold];

  NewImage.Bitmap.SetSize(32, 32);
  NewImage.Bitmap.Clear($FFF0F0F0);
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
    NewImage.Top := fCurrentPos.Y + NewLabel.Height + (PADDING_SIZE div 2);
  end;

  fMinSize.X := Max(fMinSize.X, Max(NewImage.Left + NewImage.Width, NewLabel.Left + NewLabel.Width) + PADDING_SIZE);
  fMinSize.Y := Max(fMinSize.Y, Max(NewImage.Top + NewImage.Height, NewLabel.Top + NewLabel.Height) + PADDING_SIZE);

  NewLabel.Visible := true;
  NewImage.Visible := true;

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

  btnClose.Visible := true;
end;

procedure TLevelInfoPanel.AddPreview;
var
  AvailHeight: Integer;
  LevelImg: TImage32;

  i: Integer;
begin
  AvailHeight := AS_PANEL_HEIGHT - fMinSize.Y - PADDING_SIZE;

  if AvailHeight < MIN_PREVIEW_HEIGHT then Exit;

  LevelImg := TImage32.Create(self);
  LevelImg.Parent := self;
  LevelImg.ScaleMode := smResize;
  LevelImg.BitmapAlign := baCenter;

  TLinearResampler.Create(LevelImg.Bitmap);

  LevelImg.Bitmap.BeginUpdate;
  try
    GameParams.Renderer.RenderWorld(LevelImg.Bitmap, true);
  finally
    LevelImg.Bitmap.EndUpdate;
    LevelImg.Bitmap.Changed;
  end;

  LevelImg.BoundsRect := Rect(0, 0, AS_PANEL_WIDTH, AvailHeight);

  fMinSize := Types.Point(AS_PANEL_WIDTH, AS_PANEL_HEIGHT);

  for i := 0 to ControlCount-1 do
    if Controls[i] <> LevelImg then
      Controls[i].Top := Controls[i].Top + LevelImg.Height + PADDING_SIZE;
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
    pmNextRowPadLeft: begin fCurrentPos.X := PADDING_SIZE; fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING + (PADDING_SIZE * 2); end;
    pmNextRowPadSame: fCurrentPos.Y := fCurrentPos.Y + NORMAL_SPACING + (PADDING_SIZE * 2);
  end;
end;

const // Icon indexes
  ICON_NORMAL_LEMMING = 0;
  ICON_ZOMBIE_LEMMING = 1;
  ICON_NEUTRAL_LEMMING = 2;

  ICON_SAVE_REQUIREMENT = 3;
  ICON_RELEASE_RATE = 4;
  ICON_RELEASE_RATE_LOCKED = 33;
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

  ICON_SELECTED_TALISMAN = 31;

  ICON_MAX_SKILLS = 32;

procedure TLevelInfoPanel.PrepareEmbed;
var
  SIVal: Integer;
  Skill: TSkillPanelButton;
  S: String;
begin
  Wipe;

  Add(ICON_NORMAL_LEMMING, fLevel.Info.LemmingsCount - fLevel.Info.ZombieCount - fLevel.Info.NeutralCount, true, pmNextColumnSame);

  if fLevel.Info.NeutralCount > 0 then
    Add(ICON_NEUTRAL_LEMMING, fLevel.Info.NeutralCount, true, pmNextColumnSame);

  if fLevel.Info.ZombieCount > 0 then
    Add(ICON_ZOMBIE_LEMMING, fLevel.Info.ZombieCount, true, pmNextColumnSame);

  Reposition(pmNextRowLeft);

  Add(ICON_SAVE_REQUIREMENT, fLevel.Info.RescueCount, true, pmNextColumnSame);

  if GameParams.SpawnInterval then
    SIVal := Level.Info.SpawnInterval
  else
    SIVal := SpawnIntervalToReleaseRate(Level.Info.SpawnInterval);

  if fLevel.Info.SpawnIntervalLocked or (fLevel.Info.SpawnInterval = 4) then
    Add(ICON_RELEASE_RATE_LOCKED, SIVal, true, pmNextColumnSame)
  else
    Add(ICON_RELEASE_RATE, SIVal, true, pmNextColumnSame);

  if fLevel.Info.HasTimeLimit then
    Add(ICON_TIME_LIMIT, IntToStr(fLevel.Info.TimeLimit div 60) + ':' + IntToStr(fLevel.Info.TimeLimit mod 60), true, pmNextRowPadLeft)
  else
    Reposition(pmNextRowPadLeft);

  for Skill := spbWalker to spbCloner do
    if Skill in fLevel.Info.Skillset then
    begin
      if fLevel.Info.SkillCount[Skill] < 100 then
        S := IntToStr(fLevel.Info.SkillCount[Skill])
      else
        S := 'Inf';

      Add(ICON_SKILLS[Skill], S, false, pmMoveHorz);
    end;

  AddPreview;

  ApplySize(AS_PANEL_WIDTH, AS_PANEL_HEIGHT);
end;

end.
