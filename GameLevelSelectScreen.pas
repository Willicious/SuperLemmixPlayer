{$include lem_directives.inc}

unit GameLevelSelectScreen;

interface

uses
  LemNeoLevelPack,
  Windows, Classes, Controls, Graphics, MMSystem, Forms,
  GR32, GR32_Image, GR32_Layers,
  LemStrings, LemDosStructures,
  StrUtils,
  GameControl, GameBaseScreen,
  PngInterface, LemTypes;

const
  MAX_VIEWABLE_ROWS = 18; // Code probably won't handle an even number correctly, stick to odd.

type
  TGameLevelSelectScreen = class(TGameBaseScreen)
  private
    fPack: TNeoLevelGroup;
    fSection: Integer;
    fSelectedLevel: Integer;
    fBasicState: TBitmap32;
    fTick: TBitmap32;
    procedure DrawLevelList;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildScreen; override;
  end;

implementation

uses SysUtils;

{ TGameLevelSelectScreen }

constructor TGameLevelSelectScreen.Create(aOwner: TComponent);
begin
  inherited;
  OnKeyDown := Form_KeyDown;
  fBasicState := TBitmap32.Create;
  fTick := TBitmap32.Create;

  fTick.DrawMode := dmBlend;
end;

destructor TGameLevelSelectScreen.Destroy;
begin
  fBasicState.Free;
  fTick.Free;
  inherited;
end;

procedure TGameLevelSelectScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    InitializeImageSizeAndPosition(640, 400);
    ExtractBackGround;
    ExtractPurpleFont;
    TileBackgroundBitmap(0, 0);

    fPack := GameParams.BaseLevelPack;
    fSection := GameParams.CurrentLevel.dRank;

    DrawPurpleTextCentered(ScreenImg.Bitmap, SLevelSelect, 10);
    DrawPurpleTextCentered(ScreenImg.Bitmap, fPack.Name + ' - ' + fPack.Children[fSection].Name, 30);

    fBasicState.SetSize(ScreenImg.Bitmap.Width, ScreenImg.Bitmap.Height);
    ScreenImg.Bitmap.DrawTo(fBasicState); // save background

    fSelectedLevel := GameParams.Info.dLevel;

    TPngInterface.LoadPngFile(AppPath + SFGraphicsMenu + 'tick.png', fTick);

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
  MaxViewableRounded: Integer;
begin
  ScreenImg.Bitmap.BeginUpdate;
  try
    fBasicState.DrawTo(ScreenImg.Bitmap);

    MaxViewableRounded := (MAX_VIEWABLE_ROWS div 2) * 2;

    MinLv := fSelectedLevel - (MAX_VIEWABLE_ROWS div 2);
    MaxLv := fSelectedLevel + (MAX_VIEWABLE_ROWS div 2);
    if MaxLv >= fPack.Children[fSection].LevelCount then MaxLv := fPack.Children[fSection].LevelCount - 1;
    if MinLv > MaxLv - MaxViewableRounded then MinLv := MaxLv - MaxViewableRounded;
    if MinLv < 0 then MinLv := 0;
    if MaxLv < MinLv + MaxViewableRounded then MaxLv := MinLv + MaxViewableRounded;
    if MaxLv >= fPack.Children[fSection].LevelCount then MaxLv := fPack.Children[fSection].LevelCount - 1;

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
      S := S + IntToStr(i + 1) + '.  ' + fPack.Children[fSection].Levels[i].Title;

      if (i = MinLv) and (i <> 0) then
        S := '   .....';

      if (i = MaxLv) and (i <> fPack.Children[fSection].LevelCount) then
        S := '   .....';
        
      DrawPurpleText(ScreenImg.Bitmap, S, 10, Y);

      if GameParams.SaveSystem.CheckCompleted(fSection, i) and (S <> '   .....') then
        fTick.DrawTo(ScreenImg.Bitmap, 110, Y);

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
                GameParams.CurrentLevel.dRank := fSection;
                GameParams.CurrentLevel.dLevel := fSelectedLevel;
                CloseScreen(gstPreview);
              end;
    VK_UP: if fSelectedLevel > 0 then
           begin
             Dec(fSelectedLevel);
             DrawLevelList;
           end;
    VK_DOWN: if fSelectedLevel < GameParams.BaseLevelPack.Children[fSection].LevelCount-1 then
             begin
               Inc(fSelectedLevel);
               DrawLevelList;
             end;
    VK_LEFT: if fSection > 0 then
             begin
               Dec(GameParams.CurrentLevel.dRank);
               GameParams.CurrentLevel.dLevel := 0;
               CloseScreen(gstLevelSelect);
             end;
    VK_RIGHT: if fSection < GameParams.BaseLevelPack.Children.Count-1 then
              begin
                Inc(GameParams.CurrentLevel.dRank);
                GameParams.CurrentLevel.dLevel := 0;
                CloseScreen(gstLevelSelect);
              end;
  end;
end;

end.

