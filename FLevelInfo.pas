unit FLevelInfo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Themes,
  LemLevel, LemTalisman, LemNeoLevelPack,
  LemTypes, LemStrings, LemCore,
  UMisc, Types, Math,
  GR32, GR32_Image, GR32_Resamplers, PngInterface;

const
  AS_PANEL_BASE_WIDTH = 600;
  AS_PANEL_BASE_HEIGHT = 369;
  MIN_PREVIEW_BASE_HEIGHT = 92;
  PADDING_BASE_SIZE = 6;
  NORMAL_BASE_SPACING = 42;
  COLUMN_BASE_SPACING = 92;
  COLUMN_LONGER_SPACING = 112;
  COLUMN_SMALLER_SPACING = 72;
  ICON_BASE_SIZE = 32;
  ICON_INTERNAL_SIZE = 32;

type
  TInfoPanelSizing = record
    AsPanelWidth: Integer;
    AsPanelHeight: Integer;
    MinPreviewHeight: Integer;
    PaddingSize: Integer;
    NormalSpacing: Integer;
    ColumnSpacing: Integer;
    ColumnLongerSpacing: Integer;
    ColumnSmallerSpacing: Integer;
    IconSize: Integer;
  end;

  TLevelInfoPanelMove = (pmNone,
                         pmNextColumnTop, pmNextColumnSame, pmNextColumnLongSame, pmNextColumnShortSame, pmMoveHorz,
                         pmNextRowLeft, pmNextRowSame, pmNextRowPadLeft, pmNextRowPadSame);

  TLevelInfoPanel = class(TForm)
    btnClose: TButton;
    private
      fCurrentPos: TPoint;
      fMinSize: TPoint;
      fIcons: TBitmap32;
      fOwnIcons: Boolean;

      fLevelImage: TBitmap32;
      fLastRenderLevelID: Int64;

      fLevel: TLevel;
      fTalisman: TTalisman;

      fAdjustedSizing: TInfoPanelSizing;

      procedure Add(aIcon: Integer; aText: Integer; aHintText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure Add(aIcon: Integer; aText: String; aHintText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
      procedure AddTalisman(aWrapWidth: Integer);
      procedure AddDummy(aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove);
      procedure AddPreview(aForceRedraw: Boolean);
      procedure AddClose;

      procedure Reposition(aMovement: TLevelInfoPanelMove);

      procedure ApplySize; overload;
      procedure ApplySize(aForcedMinWidth: Integer; aForcedMinHeight: Integer); overload;

      procedure DrawIcon(aIconIndex: Integer; aDst: TBitmap32);

      procedure DoTalismanOverride(aTalismanBMP: TBitmap32);

      procedure SetSizingInfo;
    public
      constructor Create(aOwner: TComponent; aIconBMP: TBitmap32; fTalismanOverrideBMP: TBitmap32 = nil); reintroduce;
      destructor Destroy; override;

      procedure ShowPopup;
      procedure ShowCollectiblePopup;
      procedure PrepareEmbed(aForceRedraw: Boolean);
      procedure PrepareEmbedRecords(aKind: TRecordDisplay);
      procedure PrepareEmbedCollectiblesRecords;

      procedure Wipe;

      property Level: TLevel read fLevel write fLevel;
      property Talisman: TTalisman read fTalisman write fTalisman;
  end;

implementation

uses
  FSuperLemmixLevelSelect,
  GameControl;

const
  COLOR_TALISMAN_RESTRICTION = $0050A0; // BBGGRR, because it's WinForms not GR32
  COLOR_RECORDS = $00A000;


{$R *.dfm}

{ TLevelInfoPanel }

constructor TLevelInfoPanel.Create(aOwner: TComponent; aIconBMP: TBitmap32; fTalismanOverrideBMP: TBitmap32 = nil);
var
IconsImg: String;
aStyle: String;
aStylePath: String;
aPath: String;
begin
  inherited Create(aOwner);

  SetSizingInfo;

  fLevelImage := TBitmap32.Create;

  if aIconBMP = nil then
  begin
    fIcons := TBitmap32.Create;

    IconsImg := 'levelinfo_icons.png';
    aStyle := GameParams.Level.Info.GraphicSetName;
    aStylePath := AppPath + SFStyles + aStyle + SFIcons;
    aPath := GameParams.CurrentLevel.Group.ParentBasePack.Path;

    if FileExists(aStylePath + IconsImg) then // Check styles folder first
      TPNGInterface.LoadPngFile(aStylePath + IconsImg, fIcons)
    else if FileExists(GameParams.CurrentLevel.Group.FindFile(IconsImg)) then // Then levelpack folder
      TPNGInterface.LoadPngFile(aPath + IconsImg, fIcons)
    else
      TPNGInterface.LoadPngFile(AppPath + SFGraphicsMenu + IconsImg, fIcons);
    fIcons.DrawMode := dmBlend;
    fOwnIcons := true;
  end else if fTalismanOverrideBMP <> nil then
  begin
    fIcons := TBitmap32.Create;
    fIcons.Assign(aIconBMP);
    fIcons.DrawMode := dmBlend;
    fOwnIcons := true;
  end else begin
    fIcons := aIconBMP;
    fOwnIcons := false;
  end;

  if fTalismanOverrideBMP <> nil then
    DoTalismanOverride(fTalismanOverrideBMP);

  fCurrentPos := Types.Point(fAdjustedSizing.PaddingSize, fAdjustedSizing.PaddingSize);
end;

destructor TLevelInfoPanel.Destroy;
begin
  fLevelImage.Free;

  if fOwnIcons then
    fIcons.Free;

  inherited;
end;

procedure TLevelInfoPanel.DoTalismanOverride(aTalismanBMP: TBitmap32);
var
  SrcRect, DstRect: TRect;
  Diff: Integer;
  BMP: TBitmap32;

  i: Integer;
const
  TALISMAN_TARGETS: array[0..5] of Integer =
    (ICON_BRONZE_TALISMAN + ICON_TALISMAN_UNOBTAINED_OFFSET, ICON_BRONZE_TALISMAN,
     ICON_SILVER_TALISMAN + ICON_TALISMAN_UNOBTAINED_OFFSET, ICON_SILVER_TALISMAN,
     ICON_GOLD_TALISMAN + ICON_TALISMAN_UNOBTAINED_OFFSET, ICON_GOLD_TALISMAN);
begin
  BMP := TBitmap32.Create;
  try
    BMP.Assign(aTalismanBMP);
    BMP.DrawMode := dmOpaque;
    TLinearResampler.Create(BMP);

    SrcRect := SizedRect(0, 0, BMP.Width div 2, BMP.Height div 3);

    Diff := Abs(SrcRect.Width - SrcRect.Height);

    if (SrcRect.Width > SrcRect.Height) then
    begin
      SrcRect.Width := SrcRect.Height;
      SrcRect.Offset(Diff div 2, 0);
    end;

    if (SrcRect.Height > SrcRect.Width) then
    begin
      SrcRect.Height := SrcRect.Width;
      SrcRect.Offset(0, Diff div 2);
    end;

    for i := 0 to Length(TALISMAN_TARGETS)-1 do
    begin
      DstRect := SizedRect((TALISMAN_TARGETS[i] mod 6) * ICON_INTERNAL_SIZE, (TALISMAN_TARGETS[i] div 6) * ICON_INTERNAL_SIZE, ICON_INTERNAL_SIZE, ICON_INTERNAL_SIZE);

      fIcons.FillRect(DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, $00000000);
      BMP.DrawTo(fIcons, DstRect, SrcRect);

      if i mod 2 = 0 then
        Types.OffsetRect(SrcRect, BMP.Width div 2, 0)
      else
        Types.OffsetRect(SrcRect, -BMP.Width div 2, BMP.Height div 3);
    end;
  finally
    BMP.Free;
  end;
end;

procedure TLevelInfoPanel.DrawIcon(aIconIndex: Integer; aDst: TBitmap32);
begin
  aDst.SetSize(ICON_INTERNAL_SIZE, ICON_INTERNAL_SIZE);
  aDst.Clear($FFF0F0F0);

  if aIconIndex >= 0 then
    fIcons.DrawTo(aDst, 0, 0, SizedRect((aIconIndex mod 6) * ICON_INTERNAL_SIZE, (aIconIndex div 6) * ICON_INTERNAL_SIZE, ICON_INTERNAL_SIZE, ICON_INTERNAL_SIZE));
end;

procedure TLevelInfoPanel.Wipe;
var
  i: Integer;
begin
  btnClose.Visible := false;

  for i := ControlCount-1 downto 0 do
    if (Controls[i] <> btnClose) then
      Controls[i].Free;

  fMinSize := Types.Point(fAdjustedSizing.PaddingSize * 2, fAdjustedSizing.PaddingSize * 2);
  fCurrentPos := Types.Point(fAdjustedSizing.PaddingSize, fAdjustedSizing.PaddingSize);
end;

procedure TLevelInfoPanel.Add(aIcon: Integer; aText: String; aHintText: String;
  aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer);
var
  NewImage: TImage32;
  NewLabel: TLabel;
begin
  NewImage := TImage32.Create(self);
  NewImage.Parent := self;
  NewImage.Width := fAdjustedSizing.IconSize;
  NewImage.Height := fAdjustedSizing.IconSize;
  NewImage.ScaleMode := smResize;
  TLinearResampler.Create(NewImage.Bitmap);

  NewLabel := TLabel.Create(self);
  NewLabel.Parent := self;
  NewLabel.Font.Style := [fsBold];

  DrawIcon(aIcon, NewImage.Bitmap);

  NewLabel.Caption := aText;
  if aColor >= 0 then NewLabel.Font.Color := aColor;

  if aHintText <> '' then
  begin
    NewLabel.Hint := aHintText;
    NewLabel.ShowHint := true;
    NewImage.Hint := aHintText;
    NewImage.ShowHint := true;
  end;

  if aTextOnRight then
  begin
    NewImage.Left := fCurrentPos.X;
    NewImage.Top := fCurrentPos.Y;
    NewLabel.Left := fCurrentPos.X + NewImage.Width + fAdjustedSizing.PaddingSize;
    NewLabel.Top := fCurrentPos.Y + ((NewImage.Height - NewLabel.Height) div 2);
  end else begin
    NewLabel.Left := fCurrentPos.X + ((NewImage.Width - NewLabel.Width) div 2);
    NewLabel.Top := fCurrentPos.Y;
    NewImage.Left := fCurrentPos.X;
    NewImage.Top := fCurrentPos.Y + NewLabel.Height + (fAdjustedSizing.PaddingSize div 2);
  end;

  fMinSize.X := Max(fMinSize.X, Max(NewImage.Left + NewImage.Width, NewLabel.Left + NewLabel.Width) + fAdjustedSizing.PaddingSize);
  fMinSize.Y := Max(fMinSize.Y, Max(NewImage.Top + NewImage.Height, NewLabel.Top + NewLabel.Height) + fAdjustedSizing.PaddingSize);

  NewLabel.Visible := true;
  NewImage.Visible := true;

  Reposition(aMovement);
end;

procedure TLevelInfoPanel.AddTalisman(aWrapWidth: Integer);
var
  Img: TImage32;
  LblTitle, LblRequirement: TLabel;

  IconIndex: Integer;

  LabelHeight: Integer;

  function MakeWrappedRequirementText: String;
  var
    WrapWidth: Integer;
  begin
    if LblTitle = nil then
      WrapWidth := aWrapWidth
    else
      WrapWidth := Max(aWrapWidth, LblTitle.Width);

    Result := BreakString(fTalisman.RequirementText, LblRequirement, WrapWidth);
  end;
begin
  // Components' LEFT is set during creation
  // Components' TOP is set at the end

  Img := TImage32.Create(self);
  Img.Parent := self;
  Img.Width := fAdjustedSizing.IconSize;
  Img.Height := fAdjustedSizing.IconSize;
  Img.Left := fCurrentPos.X;
  Img.ScaleMode := smResize;
  TLinearResampler.Create(Img.Bitmap);

  IconIndex := ICON_TALISMAN[fTalisman.Color];
  if not GameParams.CurrentLevel.TalismanStatus[fTalisman.ID] then
    IconIndex := IconIndex + ICON_TALISMAN_UNOBTAINED_OFFSET;

  DrawIcon(IconIndex, Img.Bitmap);

  LabelHeight := 0;

  if fTalisman.Title <> '' then
  begin
    LblTitle := TLabel.Create(self);
    LblTitle.Parent := self;
    LblTitle.Font.Style := [fsBold];
    LblTitle.Caption := fTalisman.Title;
    LblTitle.Left := fCurrentPos.X + Img.Width + fAdjustedSizing.PaddingSize;
    LabelHeight := LabelHeight + LblTitle.Height;
  end else
    LblTitle := nil;

  LblRequirement := TLabel.Create(self);
  LblRequirement.Parent := self;
  LblRequirement.Caption := MakeWrappedRequirementText;
  LblRequirement.Left := fCurrentPos.X + Img.Width + fAdjustedSizing.PaddingSize;
  LabelHeight := LabelHeight + LblRequirement.Height;

  fCurrentPos.X := fAdjustedSizing.PaddingSize;
  fMinSize.X := LblRequirement.Left + LblRequirement.Width;
  if LblTitle <> nil then
    fMinSize.X := Max(fMinSize.X, LblTitle.Left + LblTitle.Width);
  fMinSize.X := fMinSize.X + fAdjustedSizing.PaddingSize;

  if LabelHeight > Img.Height then
  begin
    Img.Top := fCurrentPos.Y + ((LabelHeight - Img.Height) div 2);

    if LblTitle = nil then
      LblRequirement.Top := fCurrentPos.Y
    else begin
      LblTitle.Top := fCurrentPos.Y;
      LblRequirement.Top := LblTitle.Top + LblTitle.Height;
    end;

    fMinSize.Y := LblRequirement.Top + LblRequirement.Height + fAdjustedSizing.PaddingSize;
    fCurrentPos.Y := fCurrentPos.Y + LabelHeight + fAdjustedSizing.PaddingSize;
  end else begin
    Img.Top := fCurrentPos.Y;

    if LblTitle = nil then
      LblRequirement.Top := fCurrentPos.Y + ((Img.Height - LabelHeight) div 2)
    else begin
      LblTitle.Top := fCurrentPos.Y + ((Img.Height - LabelHeight) div 2);
      LblRequirement.Top := LblTitle.Top + LblTitle.Height;
    end;

    fMinSize.Y := Img.Top + Img.Height + fAdjustedSizing.PaddingSize;
    fCurrentPos.Y := fCurrentPos.Y + Img.Height + fAdjustedSizing.PaddingSize;
  end;

end;

procedure TLevelInfoPanel.Add(aIcon, aText: Integer; aHintText: String; aTextOnRight: Boolean;
  aMovement: TLevelInfoPanelMove; aColor: Integer);
begin
  Add(aIcon, IntToStr(aText), aHintText, aTextOnRight, aMovement, aColor);
end;

procedure TLevelInfoPanel.AddClose;
var
  Diff: Integer;
  i: Integer;
begin
  btnClose.Top := fMinSize.Y;

  if fMinSize.X < btnClose.Width + (fAdjustedSizing.PaddingSize * 2) then
  begin
    Diff := (btnClose.Width + (fAdjustedSizing.PaddingSize * 2)) - fMinSize.X;
    btnClose.Left := fAdjustedSizing.PaddingSize;
    fMinSize.X := fMinSize.X + Diff;

    for i := 0 to ControlCount-1 do
      if Controls[i] <> btnClose then
        Controls[i].Left := Controls[i].Left + Diff div 2;
  end else
    btnClose.Left := (fMinSize.X - btnClose.Width) div 2;

  fMinSize.Y := btnClose.Top + btnClose.Height + fAdjustedSizing.PaddingSize;

  btnClose.Visible := true;
end;

procedure TLevelInfoPanel.AddDummy(aTextOnRight: Boolean;
  aMovement: TLevelInfoPanelMove);
begin
  Add(ICON_BLANK, '', '', aTextOnRight, aMovement);
end;

procedure TLevelInfoPanel.AddPreview(aForceRedraw: Boolean);
var
  AvailHeight: Integer;
  LevelImg: TImage32;

  i: Integer;
begin
  AvailHeight := fAdjustedSizing.AsPanelHeight - fMinSize.Y - fAdjustedSizing.PaddingSize;

  if AvailHeight < fAdjustedSizing.MinPreviewHeight then Exit;

  LevelImg := TImage32.Create(self);
  LevelImg.Parent := self;
  LevelImg.ScaleMode := smResize;
  LevelImg.BitmapAlign := baCenter;

  if (fLastRenderLevelID <> fLevel.Info.LevelID) or aForceRedraw then
  begin
    fLastRenderLevelID := fLevel.Info.LevelID;
    GameParams.Renderer.RenderWorld(fLevelImage, true);
  end;

  LevelImg.Bitmap.Assign(fLevelImage);

  TLinearResampler.Create(LevelImg.Bitmap);

  LevelImg.BoundsRect := Rect(0, 0, fAdjustedSizing.AsPanelWidth, AvailHeight);

  fMinSize := Types.Point(fAdjustedSizing.AsPanelWidth, fAdjustedSizing.AsPanelHeight);

  for i := 0 to ControlCount-1 do
    if Controls[i] <> LevelImg then
      Controls[i].Top := Controls[i].Top + LevelImg.Height + fAdjustedSizing.PaddingSize;
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
    pmNextColumnTop: begin fCurrentPos.X := fCurrentPos.X + fAdjustedSizing.ColumnSpacing; fCurrentPos.Y := fAdjustedSizing.PaddingSize; end;
    pmNextColumnSame: fCurrentPos.X := fCurrentPos.X + fAdjustedSizing.ColumnSpacing;
    pmNextColumnLongSame: fCurrentPos.X := fCurrentPos.X + fAdjustedSizing.ColumnLongerSpacing;
    pmNextColumnShortSame: fCurrentPos.X := fCurrentPos.X + fAdjustedSizing.ColumnSmallerSpacing;
    pmMoveHorz: fCurrentPos.X := fCurrentPos.X + fAdjustedSizing.NormalSpacing;
    pmNextRowLeft: begin fCurrentPos.X := fAdjustedSizing.PaddingSize; fCurrentPos.Y := fCurrentPos.Y + fAdjustedSizing.NormalSpacing; end;
    pmNextRowSame: fCurrentPos.Y := fCurrentPos.Y + fAdjustedSizing.NormalSpacing;
    pmNextRowPadLeft: begin fCurrentPos.X := fAdjustedSizing.PaddingSize; fCurrentPos.Y := fCurrentPos.Y + fAdjustedSizing.NormalSpacing + (fAdjustedSizing.PaddingSize * 2); end;
    pmNextRowPadSame: fCurrentPos.Y := fCurrentPos.Y + fAdjustedSizing.NormalSpacing + (fAdjustedSizing.PaddingSize * 2);
  end;
end;

procedure TLevelInfoPanel.SetSizingInfo;
var
  Factor: Double;
  function Adjust(aInput: Integer): Integer;
  begin
    Result := Round(aInput * Factor);
  end;
begin
  Factor := Screen.PixelsPerInch / 96;
  with fAdjustedSizing do
  begin
    AsPanelWidth := Adjust(AS_PANEL_BASE_WIDTH);
    AsPanelHeight := Adjust(AS_PANEL_BASE_HEIGHT);
    MinPreviewHeight := Adjust(MIN_PREVIEW_BASE_HEIGHT);
    PaddingSize := Adjust(PADDING_BASE_SIZE);
    NormalSpacing := Adjust(NORMAL_BASE_SPACING);
    ColumnSpacing := Adjust(COLUMN_BASE_SPACING);
    ColumnLongerSpacing := Adjust(COLUMN_LONGER_SPACING);
    ColumnSmallerSpacing := Adjust(COLUMN_SMALLER_SPACING);
    IconSize := Adjust(ICON_BASE_SIZE);
  end;
end;

procedure TLevelInfoPanel.ShowCollectiblePopup;

  function AddRequirements(aDry: Boolean): Integer;
  var
  Icon, aValue: Integer;
    procedure LocalAdd(aIcon: Integer; aText: Integer; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
    begin
      Inc(Result);
      if not aDry then
        Add(aIcon, aText, '', aTextOnRight, aMovement, aColor);
    end;

    procedure LocalAdd(aIcon: Integer; aText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
    begin
      Inc(Result);
      if not aDry then
        Add(aIcon, aText, '', aTextOnRight, aMovement, aColor);
    end;
  begin
    Result := 0;
    aValue := GameParams.CurrentLevel.UserRecords.CollectiblesGathered.Value;

    LocalAdd(ICON_COLLECTIBLE, 'Total collectibles: ' + IntToStr(fLevel.Info.CollectibleCount) + '  ', true, pmNextRowSame, 0);

    if aValue < fLevel.Info.CollectibleCount then
      Icon := ICON_COLLECTIBLE_UNOBTAINED
    else
      Icon := ICON_COLLECTIBLE;

    if aValue > 0 then
    LocalAdd(Icon, 'Your record is:     ' + IntToStr(aValue) + '  ', true, pmMoveHorz, 0);
  end;
var
  ReqCount: Integer;
  ReqWidth: Integer;
const
  MIN_CENTER_REQ_COUNT = 5;
begin
  if GameParams.Level.Info.CollectibleCount > 0 then
  begin
    BorderStyle := bsDialog;

    Wipe;

    ReqCount := AddRequirements(true);
    ReqWidth := fAdjustedSizing.NormalSpacing * ReqCount;

    if fMinSize.X > ReqWidth + (fAdjustedSizing.PaddingSize * 2) then
      fCurrentPos.X := (fMinSize.X - ReqWidth) div 2;

    AddRequirements(false);

    AddClose;
    ApplySize;

    Left := (Screen.Width - Width) div 2;
    Top := TForm(Owner).Top + ((TForm(Owner).Height - Height) div 2);

    ShowModal;
  end;
end;

procedure TLevelInfoPanel.ShowPopup;

  function AddRequirements(aDry: Boolean): Integer;
  var
    Skill: TSkillPanelButton;

    TalCount: Integer;
    BaseCount: Integer;
    PickupCount: Integer;

    procedure LocalAdd(aIcon: Integer; aText: Integer; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
    begin
      Inc(Result);
      if not aDry then
        Add(aIcon, aText, '', aTextOnRight, aMovement, aColor);
    end;

    procedure LocalAdd(aIcon: Integer; aText: String; aTextOnRight: Boolean; aMovement: TLevelInfoPanelMove; aColor: Integer = -1); overload;
    begin
      Inc(Result);
      if not aDry then
        Add(aIcon, aText, '', aTextOnRight, aMovement, aColor);
    end;
  begin
    Result := 0;

    if (Talisman.RescueCount > fLevel.Info.RescueCount) then
      LocalAdd(ICON_SAVE_REQUIREMENT, fTalisman.RescueCount, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    if (Talisman.TimeLimit > 0) and
       ((not fLevel.Info.HasTimeLimit) or (Talisman.TimeLimit < fLevel.Info.TimeLimit * 17)) then
      LocalAdd(ICON_TIME_LIMIT,
        IntToStr(Talisman.TimeLimit div (60 * 17)) + ':' + LeadZeroStr((Talisman.TimeLimit div 17) mod 60, 2) + '.' +
          LeadZeroStr(Round((Talisman.TimeLimit mod 17) / 17 * 100), 2),
          false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    if Talisman.TotalSkillLimit >= 0 then
      LocalAdd(ICON_MAX_SKILLS, IntToStr(Talisman.TotalSkillLimit), false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    if Talisman.SkillTypeLimit >= 0 then
      LocalAdd(ICON_MAX_SKILL_TYPES, IntToStr(Talisman.SkillTypeLimit), false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);

    for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
      if Skill in fLevel.Info.Skillset then
      begin
        BaseCount := Min(fLevel.Info.SkillCount[Skill], 100);
        PickupCount := fLevel.GetPickupSkillCount(Skill);

        if (Talisman <> nil) and (Talisman.SkillLimit[Skill] >= 0) then
        begin
          TalCount := Talisman.SkillLimit[Skill];

          if TalCount < BaseCount + PickupCount then
            LocalAdd(ICON_SKILLS[Skill], TalCount, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);
        end;
      end;

      if (Talisman.RequireKillZombies) then
        LocalAdd(ICON_KILL_ZOMBIES, '', false, pmMoveHorz);

      if (Talisman.RequireClassicMode) then
        LocalAdd(ICON_CLASSIC_MODE, '', false, pmMoveHorz);

      if (Talisman.RequireNoPause) then
        LocalAdd(ICON_NO_PAUSE, '', false, pmMoveHorz);
  end;

  procedure RepositionExistingControls(aNewWidth: Integer);
  var
    i: Integer;
    ExistingRect: TRect;

    Target, Offset: Integer;
  begin
    if ControlCount = 0 then
      Exit;

    ExistingRect := Controls[0].BoundsRect;
    for i := 1 to ControlCount-1 do
    begin
      ExistingRect.Left := Min(ExistingRect.Left, Controls[i].Left);
      ExistingRect.Top := Min(ExistingRect.Top, Controls[i].Top);
      ExistingRect.Right := Max(ExistingRect.Right, Controls[i].Left + Controls[i].Width);
      ExistingRect.Bottom := Max(ExistingRect.Bottom, Controls[i].Top + Controls[i].Height);
    end;

    if ExistingRect.Width >= aNewWidth then
      Exit;

    Target := (aNewWidth - ExistingRect.Width) div 2;
    Offset := Target - ExistingRect.Left;

    for i := 0 to ControlCount-1 do
      Controls[i].Left := Controls[i].Left + Offset;
  end;
var
  ReqCount: Integer;
  ReqWidth: Integer;
const
  MIN_CENTER_REQ_COUNT = 5;
begin
  if (fTalisman <> nil) then
  begin
    BorderStyle := bsDialog;

    Wipe;

    ReqCount := AddRequirements(true);
    ReqWidth := fAdjustedSizing.NormalSpacing * ReqCount - 8;

    AddTalisman(Max(ReqWidth, MIN_CENTER_REQ_COUNT * fAdjustedSizing.NormalSpacing - 8));

    if fMinSize.X > ReqWidth + (fAdjustedSizing.PaddingSize * 2) then
      fCurrentPos.X := (fMinSize.X - ReqWidth) div 2
    else
      RepositionExistingControls(ReqWidth + fAdjustedSizing.PaddingSize * 2);

    AddRequirements(false);

    AddClose;
    ApplySize;

    Left := (Screen.Width - Width) div 2;
    Top := TForm(Owner).Top + ((TForm(Owner).Height - Height) div 2);

    ShowModal;
  end;
end;

procedure TLevelInfoPanel.PrepareEmbed(aForceRedraw: Boolean);
var
  SIVal: Integer;
  SIHintText: String;

  Skill: TSkillPanelButton;
  SkillString, SkillName, SkillHintText: String;

  TalCount: Integer;
  BaseCount: Integer;
  PickupCount: Integer;

  IsTalismanLimit: Boolean;
begin
  Wipe;

  if fTalisman <> nil then
    if (GameParams.CurrentLevel.TalismanStatus[fTalisman.ID]) then
      Add(ICON_TALISMAN[fTalisman.Color], fTalisman.Title, 'Talisman completed - Well done!', true, pmNextRowPadLeft)
    else
      Add(ICON_TALISMAN[fTalisman.Color] + ICON_TALISMAN_UNOBTAINED_OFFSET, fTalisman.Title, 'Talisman not yet completed', true, pmNextRowPadLeft);

  Add(ICON_NORMAL_LEMMING, fLevel.Info.LemmingsCount - fLevel.Info.ZombieCount - fLevel.Info.NeutralCount - fLevel.Info.RivalCount
  , 'Number of Lemmings', true, pmNextColumnSame);

  if fLevel.Info.NeutralCount > 0 then
    Add(ICON_NEUTRAL_LEMMING, fLevel.Info.NeutralCount, 'Number of Neutrals', true, pmNextColumnSame);

  if fLevel.Info.RivalCount > 0 then
    Add(ICON_RIVAL_LEMMING, fLevel.Info.RivalCount, 'Number of Rivals', true, pmNextColumnSame);

  if (fLevel.Info.ZombieCount > 0) or ((fTalisman <> nil) and (fTalisman.RequireKillZombies)) then
  begin
    if (fTalisman <> nil) and (fTalisman.RequireKillZombies) then
      Add(ICON_KILL_ZOMBIES, fLevel.Info.ZombieCount, 'Kill All' + IntToStr(fLevel.Info.ZombieCount) + 'Zombies', true, pmNextColumnSame)
    else
      Add(ICON_ZOMBIE_LEMMING, fLevel.Info.ZombieCount, 'Number of Zombies', true, pmNextColumnSame);
  end;

  if (fLevel.Info.CollectibleCount <> 0) then
      Add(ICON_COLLECTIBLE, fLevel.Info.CollectibleCount, 'Number of Collectibles', true, pmNextColumnSame);

  if ((fTalisman <> nil) and (fTalisman.RequireClassicMode)) then
      Add(ICON_CLASSIC_MODE, '', 'Complete the level in Classic Mode', true, pmNextColumnSame);

  if ((fTalisman <> nil) and (fTalisman.RequireNoPause)) then
      Add(ICON_NO_PAUSE, '', 'Complete the level without pressing Pause', true, pmNextColumnSame);

  Reposition(pmNextRowLeft);

  if (fTalisman = nil) or (fTalisman.RescueCount <= fLevel.Info.RescueCount) then
    Add(ICON_SAVE_REQUIREMENT, fLevel.Info.RescueCount, 'Save requirement to complete the level', true, pmNextColumnSame)
  else
    Add(ICON_SAVE_REQUIREMENT, fTalisman.RescueCount, 'Save requirement to complete the Talisman', true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION);

  if GameParams.SpawnInterval and not GameParams.ClassicMode then
  begin
    SIVal := Level.Info.SpawnInterval;
    SIHintText := 'Spawn Interval';
  end else begin
    SIVal := SpawnIntervalToReleaseRate(Level.Info.SpawnInterval);
    SIHintText := 'Release Rate';
  end;

  if fLevel.Info.SpawnIntervalLocked or (fLevel.Info.SpawnInterval = 4) then
    Add(ICON_RELEASE_RATE_LOCKED, SIVal, 'Locked ' + SIHintText, true, pmNextColumnSame)
  else
    Add(ICON_RELEASE_RATE, SIVal, SIHintText, true, pmNextColumnSame);

  if (Talisman <> nil) and
     (Talisman.TimeLimit > 0) and
     ((not fLevel.Info.HasTimeLimit) or (Talisman.TimeLimit < fLevel.Info.TimeLimit * 17)) then
    Add(ICON_TIME_LIMIT,
      IntToStr(Talisman.TimeLimit div (60 * 17)) + ':' + LeadZeroStr((Talisman.TimeLimit div 17) mod 60, 2) + '.' +
        LeadZeroStr(Round((Talisman.TimeLimit mod 17) / 17 * 100), 2), 'Time Limit to complete Talisman',
        true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION)
  else if fLevel.Info.HasTimeLimit then
    Add(ICON_TIME_LIMIT, IntToStr(fLevel.Info.TimeLimit div 60) + ':' + LeadZeroStr(fLevel.Info.TimeLimit mod 60, 2), 'Time Limit', true, pmNextColumnSame);

  if (Talisman <> nil) then
  begin
    if (Talisman.TotalSkillLimit >= 0) then
      Add(ICON_MAX_SKILLS, IntToStr(Talisman.TotalSkillLimit), 'Maximum number of skills to oomplete Talisman', true, pmNextColumnShortSame, COLOR_TALISMAN_RESTRICTION);
    if (Talisman.SkillTypeLimit >= 0) then
      Add(ICON_MAX_SKILL_TYPES, IntToStr(Talisman.SkillTypeLimit), 'Maximum number of skill types to complete Talisman', true, pmNextColumnSame, COLOR_TALISMAN_RESTRICTION);
  end;

  Reposition(pmNextRowPadLeft);

  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if Skill in fLevel.Info.Skillset then
    begin
      SkillName := UpperCase(Copy(SKILL_NAMES[Skill], 1, 1)) + Copy(SKILL_NAMES[Skill], 2, MaxInt);
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
        begin
          SkillHintText := SkillName + ' limit to complete talisman: ' + SkillString;
          Add(ICON_SKILLS[Skill], SkillString, SkillHintText, false, pmMoveHorz, COLOR_TALISMAN_RESTRICTION);
        end;
      end;

      if not IsTalismanLimit then
      begin
        SkillString := IntToStr(BaseCount);
        SkillHintText := SkillName;

        if (PickupCount > 0) then
          SkillString := SkillString + ' (' + IntToStr(PickupCount) + ')';

        Add(ICON_SKILLS[Skill], SkillString, SkillHintText, false, pmMoveHorz);
      end;
    end;

  if fCurrentPos.X = fAdjustedSizing.PaddingSize then
    AddDummy(false, pmMoveHorz);

  AddPreview(aForceRedraw);

  ApplySize(fAdjustedSizing.AsPanelWidth, fAdjustedSizing.AsPanelHeight);
end;

procedure TLevelInfoPanel.PrepareEmbedCollectiblesRecords;
var
  UserValue, WorldValue, LevelValue: Integer;
  Records, WorldRecords: TLevelRecords;
  CollectibleIcon, TextColour: Integer;
begin
  Records := GameParams.CurrentLevel.UserRecords;
  WorldRecords := GameParams.CurrentLevel.WorldRecords;

  UserValue := Records.CollectiblesGathered.Value;
  WorldValue := WorldRecords.CollectiblesGathered.Value;
  LevelValue := fLevel.Info.CollectibleCount;

  if UserValue < LevelValue then
  begin
    if UserValue < 0 then UserValue := 0;
    CollectibleIcon := ICON_COLLECTIBLE_UNOBTAINED;
    TextColour := 0;
  end else begin
    CollectibleIcon := ICON_COLLECTIBLE;
    TextColour := COLOR_RECORDS;
  end;

  Add(CollectibleIcon, GameParams.Username + '''s record is '
      + IntToStr(UserValue) + '/' + IntToStr(LevelValue),
      Records.CollectiblesGathered.User, true, pmNextRowLeft, TextColour);

  if WorldValue < LevelValue then
  begin
    CollectibleIcon := ICON_COLLECTIBLE_UNOBTAINED;
    TextColour := 0;
  end else begin
    CollectibleIcon := ICON_COLLECTIBLE;
    TextColour := COLOR_RECORDS;
  end;

  if WorldValue > UserValue then
    Add(CollectibleIcon, 'World record is ' + IntToStr(WorldValue) + '/' + IntToStr(LevelValue),
        WorldRecords.CollectiblesGathered.User, true, pmNextRowLeft, TextColour)
  else
    AddDummy(false, pmNextRowLeft);
end;

procedure TLevelInfoPanel.PrepareEmbedRecords(aKind: TRecordDisplay);
var
  Records: TLevelRecords;
  Skill: TSkillPanelButton;
  Icon: Integer;
  SkillName: String;

  function PrepareHintName(aInput: String): String;
  begin
    if aKind = rdUser then
      Result := ''
    else if aInput = '' then
      Result := ': ' + GameParams.Username
    else
      Result := aInput;
  end;

  procedure AddLevelPreview;
  begin
    if fCurrentPos.X = fAdjustedSizing.PaddingSize then
      AddDummy(false, pmMoveHorz);

    AddPreview(false);
    ApplySize(fAdjustedSizing.AsPanelWidth, fAdjustedSizing.AsPanelHeight);
  end;
begin
  Wipe;

  if aKind = rdCollectibles then
  begin
    PrepareEmbedCollectiblesRecords;
    AddLevelPreview;
    Exit;
  end;

  if aKind = rdUser then
  begin
    Records := GameParams.CurrentLevel.UserRecords;
    Add(ICON_RECORDS, GameParams.Username + '''s Records', '', true, pmNextRowLeft);
  end else begin
    Records := GameParams.CurrentLevel.WorldRecords;
    Add(ICON_WORLD_RECORDS, 'World Records', '', true, pmNextRowLeft);
  end;

  if Records.LemmingsRescued.Value < 0 then
    Add(ICON_SAVE_REQUIREMENT, '~', '', true, pmNextColumnLongSame)
  else
    Add(ICON_SAVE_REQUIREMENT, IntToStr(Records.LemmingsRescued.Value) + ' / ' + IntToStr(fLevel.Info.LemmingsCount - fLevel.Info.ZombieCount),
        'Highest save count record' + PrepareHintName(Records.LemmingsRescued.User), true, pmNextColumnLongSame, COLOR_RECORDS);

  if Records.TimeTaken.Value < 0 then
    Add(ICON_TIMER, '~', '', true, pmNextColumnSame)
  else
    Add(ICON_TIMER,
      IntToStr(Records.TimeTaken.Value div (60 * 17)) + ':' + LeadZeroStr((Records.TimeTaken.Value div 17) mod 60, 2) + '.' +
        LeadZeroStr(Round((Records.TimeTaken.Value mod 17) / 17 * 100), 2), 'Fastest time record' +
          PrepareHintName(Records.TimeTaken.User), true, pmNextColumnSame, COLOR_RECORDS);

  if Records.TotalSkills.Value < 0 then
    Add(ICON_MAX_SKILLS, '~', '', true, pmNextColumnShortSame)
  else
    Add(ICON_MAX_SKILLS, Records.TotalSkills.Value, 'Fewest total skills record' +
        PrepareHintName(Records.TotalSkills.User), true, pmNextColumnShortSame, COLOR_RECORDS);

  if Records.SkillTypes.Value < 0 then
    Add(ICON_MAX_SKILL_TYPES, '~', '', true, pmNextColumnSame)
  else
    Add(ICON_MAX_SKILL_TYPES, Records.SkillTypes.Value, 'Fewest skill types record' +
        PrepareHintName(Records.SkillTypes.User), true, pmNextColumnShortSame, COLOR_RECORDS);

  // Only show collectibles records if a level has them
  if Level.Info.CollectibleCount > 0 then
  begin
    if Records.CollectiblesGathered.Value < 0 then
      Add(ICON_COLLECTIBLE_UNOBTAINED, '~', '', true, pmNextColumnSame)
    else begin
      if Records.CollectiblesGathered.Value < fLevel.Info.CollectibleCount then
        Icon := ICON_COLLECTIBLE_UNOBTAINED
      else
        Icon := ICON_COLLECTIBLE;

      Add(Icon, Records.CollectiblesGathered.Value, 'Most collectibles record' +
          PrepareHintName(Records.SkillTypes.User), true, pmNextColumnShortSame, COLOR_RECORDS);
    end;
  end;

  Reposition(pmNextRowPadLeft);

  for Skill := Low(TSkillPanelButton) to LAST_SKILL_BUTTON do
    if Skill in fLevel.Info.Skillset then
    begin
      SkillName := UpperCase(Copy(SKILL_NAMES[Skill], 1, 1)) + Copy(SKILL_NAMES[Skill], 2, MaxInt);

      if Records.SkillCount[Skill].Value < 0 then
        Add(ICON_SKILLS[Skill], '~', '', false, pmMoveHorz)
      else
        Add(ICON_SKILLS[Skill], Records.SkillCount[Skill].Value, 'Fewest '+ SkillName + 's record' +
            PrepareHintName(Records.SkillCount[Skill].User), false, pmMoveHorz, COLOR_RECORDS);
    end;

  AddLevelPreview;
end;

end.
