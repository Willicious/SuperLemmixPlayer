unit GamePackSelectScreen;

interface

uses
  StrUtils, Classes, SysUtils, Dialogs, Controls, ExtCtrls, Forms, Windows, ShellApi,
  Types, UMisc, Math,
  GameBaseMenuScreen,
  GameControl,
  LemNeoLevelPack,
  LemNeoOnline,
  LemNeoParser,
  LemStrings,
  LemTypes,
  GR32, GR32_Resamplers;

type
  TGamePackSelectScreen = class(TGameBaseMenuScreen)
  private
    procedure BeginGame;
    procedure ExitToMainMenu;
    procedure ShowSetupMenu;
    procedure OnKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
  protected
    procedure BuildScreen; override;
    procedure CloseScreen(aNextScreen: TGameScreenType); override;
    procedure AfterRedrawClickables; override;
    procedure DoAfterConfig; override;
    function GetWallpaperSuffix: String; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  LemMenuFont, // For size const
  CustomPopup,
  FSuperLemmixSetup,
  GameSound,
  LemGame, // To clear replay
  LemVersion,
  PngInterface;

{ TGamePackSelectScreen }

constructor TGamePackSelectScreen.Create(aOwner: TComponent);
begin
  inherited;

  GameParams.MainForm.Caption := 'SuperLemmix Level Pack Select';
  GameParams.MainForm.OnKeyDown := OnKeyDown;
end;

destructor TGamePackSelectScreen.Destroy;
begin
  inherited;
end;

procedure TGamePackSelectScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  inherited;

  BeginGame;
end;

procedure TGamePackSelectScreen.OnKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN, VK_SPACE: // Enter or Space
      BeginGame;
    VK_ESCAPE: // Escape
      ExitToMainMenu;
  end;
end;

procedure TGamePackSelectScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited;
end;

procedure TGamePackSelectScreen.BuildScreen;
begin
  inherited;

  if (GameParams.CurrentLevel <> nil) then
  begin
    // Build the screen with the necessary components
  end;
end;

procedure TGamePackSelectScreen.BeginGame;
begin
  if GameParams.CurrentLevel <> nil then
  begin
    if GameParams.MenuSounds then SoundManager.PlaySound(SFX_OK);
    CloseScreen(gstPreview);
  end;
end;

procedure TGamePackSelectScreen.ExitToMainMenu;
begin
  CloseScreen(gstMenu);
end;

procedure TGamePackSelectScreen.AfterRedrawClickables;
begin
  inherited;
end;

function TGamePackSelectScreen.GetWallpaperSuffix: String;
begin
  Result := 'menu';
end;

procedure TGamePackSelectScreen.ShowSetupMenu;
var
  F: TFNLSetup;
  OldFullScreen: Boolean;
  OldHighRes: Boolean;
  OldShowMinimap: Boolean;
begin
  F := TFNLSetup.Create(self);
  try
    OldFullScreen := GameParams.FullScreen;
    OldHighRes := GameParams.HighResolution;
    OldShowMinimap := GameParams.ShowMinimap;

    F.ShowModal;

    // And apply the settings chosen
    ApplyConfigChanges(OldFullScreen, OldHighRes, OldShowMinimap, false, false);
  finally
    F.Free;
  end;
end;

procedure TGamePackSelectScreen.DoAfterConfig;
begin
  inherited;
  ReloadCursor('amiga.png');
end;

end.
