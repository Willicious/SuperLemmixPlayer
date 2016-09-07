{$include lem_directives.inc}

unit GameLevelSelectScreen;

interface

uses
  Windows, Classes, Controls, Graphics, MMSystem, Forms,
  GR32, GR32_Image, GR32_Layers,
  UMisc,
  LemStrings, LemDosStructures, LemDosStyle,
  StrUtils,
  GameControl, GameBaseScreen;

type
  TGameLevelSelectScreen = class(TGameBaseScreen)
  private
    fSection: Integer;
    fSelectedLevel: Integer;
    fLevelSystem: TDosFlexiLevelSystem;
    fBasicState: TBitmap32;
    procedure DrawLevelList;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildScreen; override;
  end;

implementation

uses SysUtils, LemLevelSystem;

{ TGameLevelSelectScreen }

constructor TGameLevelSelectScreen.Create(aOwner: TComponent);
begin
  inherited;
  OnKeyDown := Form_KeyDown;
  fBasicState := TBitmap32.Create;
end;

destructor TGameLevelSelectScreen.Destroy;
begin
  fBasicState.Free;
  inherited;
end;

procedure TGameLevelSelectScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    InitializeImageSizeAndPosition(640, 350);
    ExtractBackGround;
    ExtractPurpleFont;
    TileBackgroundBitmap(0, 0);

    fSection := GameParams.Info.dSection;
    fLevelSystem := TDosFlexiLevelSystem(GameParams.Style.LevelSystem);

    DrawPurpleTextCentered(ScreenImg.Bitmap, SLevelSelect, 10);
    DrawPurpleTextCentered(ScreenImg.Bitmap, Trim(GameParams.SysDat.PackName) + ' - ' + fLevelSystem.GetRankName(fSection), 30);

    fBasicState.SetSize(ScreenImg.Bitmap.Width, ScreenImg.Bitmap.Height);
    ScreenImg.Bitmap.DrawTo(fBasicState); // save background

    fSelectedLevel := GameParams.Info.dLevel;

    DrawLevelList;
  finally
    ScreenImg.EndUpdate;
  end;
end;

procedure TGameLevelSelectScreen.DrawLevelList;
var
  i, Y: Integer;
  MinLv, MaxLv: Integer;
  S: String;
begin
  ScreenImg.Bitmap.BeginUpdate;
  try
    fBasicState.DrawTo(ScreenImg.Bitmap);
    MinLv := fSelectedLevel - 7;
    MaxLv := fSelectedLevel + 7;
    if MaxLv >= fLevelSystem.GetLevelCount(fSection) then MaxLv := fLevelSystem.GetLevelCount(fSection) - 1;
    if MinLv > MaxLv - 14 then MinLv := MaxLv - 14;
    if MinLv < 0 then MinLv := 0;
    if MaxLv < MinLv + 14 then MaxLv := MinLv + 14;
    if MaxLv >= fLevelSystem.GetLevelCount(fSection) then MaxLv := fLevelSystem.GetLevelCount(fSection) - 1;

    Y := 55;
    for i := MinLv to MaxLv do
    begin
      if i = fSelectedLevel then
        S := '>'
      else
        S := ' ';
      if i < 9 then
        S := S + ' ';
      if i < 99 then
        S := S + '  '; // just in case someone actually makes a rank this big
      S := S + IntToStr(i + 1) + '. ' + fLevelSystem.GetLevelName(fSection, i);

      if (i = MinLv) and (i <> 0) then
        S := '   .....';

      if (i = MaxLv) and (i <> fLevelSystem.GetLevelCount(fSection)-1) then
        S := '   .....';
        
      DrawPurpleText(ScreenImg.Bitmap, S, 15, Y);
      Inc(Y, 18);
    end;
  finally
    ScreenImg.Bitmap.EndUpdate;
    ScreenImg.Bitmap.Changed;
  end;
end;

procedure TGameLevelSelectScreen.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: CloseScreen(gstMenu);
    VK_RETURN: begin
                GameParams.WhichLevel := wlSame;
                GameParams.Info.dSection := fSection;
                GameParams.Info.dLevel := fSelectedLevel;
                fLevelSystem.FindLevel(GameParams.Info);
                CloseScreen(gstPreview);
              end;
    VK_UP: begin
             if fSelectedLevel > 0 then Dec(fSelectedLevel);
             DrawLevelList;
           end;
    VK_DOWN: begin
               if fSelectedLevel < fLevelSystem.GetLevelCount(fSection)-1 then Inc(fSelectedLevel);
               DrawLevelList;
             end;
  end;
end;

end.

