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
  AS_PANEL_WIDTH = 408;
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

      fLevelImage: TBitmap32;
      fLastRenderLevelID: Int64;

      fLevel: TLevel;
      fTalisman: TTalisman;

      procedure Add(aIcon: Integer; aText: Integer; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure Add(aIcon: Integer; aText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure AddClose;

      procedure Reposition(aMovement: TLevelInfoPanelMove);

      procedure ApplySize; overload;
      procedure ApplySize(aForcedMinWidth: Integer; aForcedMinHeight: Integer); overload;

      procedure AddPreview;

      procedure DrawIcon(aIconIndex: Integer; aDst: TBitmap32);
    public
      constructor Create(aOwner: TComponent; aIconBMP: TBitmap32); reintroduce;
      destructor Destroy; override;

      procedure ShowPopup;
      procedure PrepareEmbed;

      procedure Wipe;

      property Level: TLevel read fLevel write fLevel;
      property Talisman: TTalisman read fTalisman write fTalisman;
  end;

var
  LevelInfoPanel: TLevelInfoPanel;

implementation

uses
  FNeoLemmixLevelSelect,
  GameControl;

const
  COLOR_TALISMAN_RESTRICTION = $0050A0; // BBGGRR, because it's WinForms not GR32

  PADDING_SIZE = 8;

  NORMAL_SPACING = 40;

  COLUMN_SPACING = 92;


{$R *.dfm}

{ TLevelInfoPanel }

constructor TLevelInfoPanel.Create(aOwner: TComponent; aIconBMP: TBitmap32);
begin
  inherited Create(aOwner);

  fLevelImage := TBitmap32.Create;

  fIcons := aIconBMP;

  fCurrentPos := Types.Point(PADDING_SIZE, PADDING_SIZE);
end;

destructor TLevelInfoPanel.Destroy;
begin
  fLevelImage.Free;
  inherited;
end;

procedure TLevelInfoPanel.DrawIcon(aIconIndex: Integer; aDst: TBitmap32);
begin
  aDst.SetSize(32, 32);
  aDst.Clear($FFF0F0F0);
  fIcons.DrawTo(aDst, 0, 0, SizedRect((aIconIndex mod 4) * 32, (aIconIndex div 4) * 32, 32, 32));
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

  DrawIcon(aIcon, NewImage.Bitmap);

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
var
  Diff: Integer;
  i: Integer;
begin
  btnClose.Top := fMinSize.Y;

  if fMinSize.X < btnClose.Width + (PADDING_SIZE * 2) then
  begin
    Diff := (btnClose.Width + (PADDING_SIZE * 2)) - fMinSize.X;
    btnClose.Left := PADDING_SIZE;
    fMinSize.X := fMinSize.X + Diff;

    for i := 0 to ControlCount-1 do
      if Controls[i] <> btnClose then
        Controls[i].Left := Controls[i].Left + Diff div 2;
  end else
    btnClose.Left := (fMinSize.X - btnClose.Width) div 2;

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

  if fLastRenderLevelID <> fLevel.Info.LevelID then
  begin
    fLastRenderLevelID := fLevel.Info.LevelID;
    GameParams.Renderer.RenderWorld(fLevelImage, true);
  end;

  LevelImg.Bitmap.Assign(fLevelImage);

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

procedure TLevelInfoPanel.ShowPopup;
var
  Skill: TSkillPanelButton;

  TalCount: Integer;
  BaseCount: Integer;
  PickupCount: Integer;

  NewLabel: TLabel;
begin
  if (fTalisman <> nil) then
  begin
    BorderStyle := bsToolWindow;

    Wipe;

    if (GameParams.CurrentLevel.TalismanStatus[fTalisman.ID]) then
      Add(ICON_TALISMAN[fTalisman.Color], fTalisman.Title, true, pmNextRowPadLeft)
    else
      Add(ICON_TALISMAN[fTalisman.Color] + ICON_TALISMAN_UNOBTAINED_OFFSET, fTalisman.Title, true, pmNextRowPadLeft);

    if (fTalisman.RescueCount > fLevel.Info.RescueCount) then
      Add(ICON_SAVE_REQUIREMENT, fTalisman.RescueCount, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    if (Talisman.TimeLimit > 0) and
       ((not fLevel.Info.HasTimeLimit) or (Talisman.TimeLimit < fLevel.Info.TimeLimit * 17)) then
      Add(ICON_TIME_LIMIT,
        IntToStr(Talisman.TimeLimit div (60 * 17)) + ':' + LeadZeroStr((Talisman.TimeLimit div 17) mod 60, 2) + '.' +
          LeadZeroStr(Round((Talisman.TimeLimit mod 17) / 17 * 100), 2),
          false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    if Talisman.TotalSkillLimit >= 0 then
      Add(ICON_MAX_SKILLS, IntToStr(Talisman.TotalSkillLimit), false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    for Skill := spbWalker to spbCloner do
      if Skill in fLevel.Info.Skillset then
      begin
        BaseCount := Min(fLevel.Info.SkillCount[Skill], 100);
        PickupCount := fLevel.GetPickupSkillCount(Skill);

        if (Talisman <> nil) and (Talisman.SkillLimit[Skill] >= 0) then
        begin
          TalCount := Talisman.SkillLimit[Skill];

          if TalCount < BaseCount + PickupCount then
            Add(ICON_SKILLS[Skill], TalCount, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);
        end;
      end;

    // Special case
    if fCurrentPos.X = PADDING_SIZE then
    begin
      NewLabel := TLabel.Create(self);
      NewLabel.Parent := self;
      NewLabel.Font.Style := [fsBold];
      NewLabel.Caption := 'Complete the level.';

      if NewLabel.Width + (PADDING_SIZE * 2) < fMinSize.X then
      begin
        fMinSize.X := NewLabel.Width + (PADDING_SIZE * 2);
        NewLabel.Left := PADDING_SIZE;
      end else
        NewLabel.Left := (fMinSize.X - PADDING_SIZE) div 2;

      NewLabel.Top := fCurrentPos.Y;

      fMinSize.X := NewLabel.Width + (PADDING_SIZE * 2);
      fMinSize.Y := NewLabel.Height + (PADDING_SIZE * 2);
    end;

    AddClose;
    ApplySize;

    Left := TForm(Owner).Left + ((TForm(Owner).Width - Width) div 2);
    Top := TForm(Owner).Top + ((TForm(Owner).Height - Height) div 2);
    ShowModal;
  end;
end;

procedure TLevelInfoPanel.PrepareEmbed;
var
  SIVal: Integer;
  Skill: TSkillPanelButton;

  TalCount: Integer;
  BaseCount: Integer;
  PickupCount: Integer;
  SkillString: String;

  IsTalismanLimit: Boolean;
begin
  Wipe;

  if fTalisman <> nil then
    if (GameParams.CurrentLevel.TalismanStatus[fTalisman.ID]) then
      Add(ICON_TALISMAN[fTalisman.Color], fTalisman.Title, true, pmNextRowPadLeft)
    else
      Add(ICON_TALISMAN[fTalisman.Color] + ICON_TALISMAN_UNOBTAINED_OFFSET, fTalisman.Title, true, pmNextRowPadLeft);

  Add(ICON_NORMAL_LEMMING, fLevel.Info.LemmingsCount - fLevel.Info.ZombieCount - fLevel.Info.NeutralCount, true, pmNextColumnSame);

  if fLevel.Info.NeutralCount > 0 then
    Add(ICON_NEUTRAL_LEMMING, fLevel.Info.NeutralCount, true, pmNextColumnSame);

  if fLevel.Info.ZombieCount > 0 then
    Add(ICON_ZOMBIE_LEMMING, fLevel.Info.ZombieCount, true, pmNextColumnSame);

  Reposition(pmNextRowLeft);

  if (fTalisman = nil) or (fTalisman.RescueCount <= fLevel.Info.RescueCount) then
    Add(ICON_SAVE_REQUIREMENT, fLevel.Info.RescueCount, true, pmNextColumnSame)
  else
    Add(ICON_SAVE_REQUIREMENT, fTalisman.RescueCount, true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION);

  if GameParams.SpawnInterval then
    SIVal := Level.Info.SpawnInterval
  else
    SIVal := SpawnIntervalToReleaseRate(Level.Info.SpawnInterval);

  if fLevel.Info.SpawnIntervalLocked or (fLevel.Info.SpawnInterval = 4) then
    Add(ICON_RELEASE_RATE_LOCKED, SIVal, true, pmNextColumnSame)
  else
    Add(ICON_RELEASE_RATE, SIVal, true, pmNextColumnSame);

  if (Talisman <> nil) and
     (Talisman.TimeLimit > 0) and
     ((not fLevel.Info.HasTimeLimit) or (Talisman.TimeLimit < fLevel.Info.TimeLimit * 17)) then
    Add(ICON_TIME_LIMIT,
      IntToStr(Talisman.TimeLimit div (60 * 17)) + ':' + LeadZeroStr((Talisman.TimeLimit div 17) mod 60, 2) + '.' +
        LeadZeroStr(Round((Talisman.TimeLimit mod 17) / 17 * 100), 2),
        true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION)
  else if fLevel.Info.HasTimeLimit then
    Add(ICON_TIME_LIMIT, IntToStr(fLevel.Info.TimeLimit div 60) + ':' + LeadZeroStr(fLevel.Info.TimeLimit mod 60, 2), true, pmNextColumnSame);

  if (Talisman <> nil) and (Talisman.TotalSkillLimit >= 0) then
    Add(ICON_MAX_SKILLS, IntToStr(Talisman.TotalSkillLimit), true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION);

  Reposition(pmNextRowPadLeft);

  for Skill := spbWalker to spbCloner do
    if Skill in fLevel.Info.Skillset then
    begin
      BaseCount := Min(fLevel.Info.SkillCount[Skill], 100);
      PickupCount := fLevel.GetPickupSkillCount(Skill);

      IsTalismanLimit := false;

      if (Talisman <> nil) and (Talisman.SkillLimit[Skill] >= 0) then
      begin
        TalCount := Talisman.SkillLimit[Skill];

        if TalCount < BaseCount then
        begin
          IsTalismanLimit := true;
          SkillString := IntToStr(TalCount);
        end else if TalCount < BaseCount + PickupCount then
        begin
          IsTalismanLimit := true;
          SkillString := IntToStr(TalCount) + ' (' + IntToStr(BaseCount + PickupCount - TalCount) + ')';
        end;

        if IsTalismanLimit then
          Add(ICON_SKILLS[Skill], SkillString, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);
      end;

      if not IsTalismanLimit then
      begin
        SkillString := IntToStr(BaseCount);

        if (PickupCount > 0) then
          SkillString := SkillString + ' (' + IntToStr(PickupCount) + ')';

        Add(ICON_SKILLS[Skill], SkillString, false, pmMoveHorz);
      end;
    end;

  AddPreview;

  ApplySize(AS_PANEL_WIDTH, AS_PANEL_HEIGHT);
end;

end.
