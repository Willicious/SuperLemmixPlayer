{$include lem_directives.inc}

unit GameLevelCodeScreen;

interface

uses
  Windows, Classes, MMSystem, Forms, GR32,
  LemDosStyle,
  GameControl, GameBaseScreen;

const
  BlinkSpeedMS = 240;
  XPos = (640 - (10 * 16)) div 2;
  YPositions: array[0..3] of Integer = (120, 152, 184, 216);

type
  TGameLevelCodeScreen = class(TGameBaseScreen)
  private
    LevelCode      : string[10];
    CursorPosition : Integer;
    ValidLevelCode: Boolean;
    PrevBlinkTime: Cardinal;
    Blinking: Boolean;
    Typing: Boolean;
    LastMessage: string;
    LastCheatMessage: string;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_Close(Sender: TObject; var Action: TCloseAction );
    procedure Application_Idle(Sender: TObject; var Done: Boolean);
    function CheckLevelCode: Boolean;
    procedure DrawChar(aCursorPos: Integer; aBlink: Boolean = False);
    procedure DrawMessage(const S: string);
    procedure UpdateCheatMessage;
  protected
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildScreen; override;
  end;

implementation

uses SysUtils;

{ TGameLevelCodeScreen }

procedure TGameLevelCodeScreen.Application_Idle(Sender: TObject; var Done: Boolean);
var
  CurrTime: Cardinal;
begin
  if ScreenIsClosing or Typing then
    Exit;

  Done := False;
  Sleep(1); // relax CPU
  CurrTime := TimeGetTime;
  if CurrTime >= PrevBlinkTime + BlinkSpeedMS then
  begin
    PrevBlinkTime := CurrTime;
    Blinking := not Blinking;
    DrawChar(CursorPosition, Blinking);
  end;
end;

procedure TGameLevelCodeScreen.BuildScreen;
begin
  ScreenImg.BeginUpdate;
  try
    InitializeImageSizeAndPosition(640, 350);
    ExtractBackGround;
    ExtractPurpleFont;
    TileBackgroundBitmap(0, 0);
    BackBuffer.Assign(ScreenImg.Bitmap); // save background

    DrawPurpleText(ScreenImg.Bitmap, 'Enter Code', XPos, 120);
    DrawPurpleText(ScreenImg.Bitmap, LevelCode, XPos, YPositions[1]);

    UpdateCheatMessage;

    Application.OnIdle := Application_Idle;
  finally
    ScreenImg.EndUpdate;
  end;
end;

function TGameLevelCodeScreen.CheckLevelCode: Boolean;
var
  Sys: TBaseDosLevelSystem;
  Txt: string;
begin
  Sys := GameParams.Style.LevelSystem as TBaseDosLevelSystem;

  try
    Result := Sys.FindLevelCode(LevelCode, GameParams.Info)
           or Sys.FindCheatCode(LevelCode, GameParams.Info);

    if Result then
    begin
      GameParams.ShownText := false;
      Txt := GameParams.Info.dSectionName + ' ' + IntToStr(GameParams.Info.dLevel + 1);
      DrawPurpleTextCentered(ScreenImg.Bitmap, Txt, YPositions[2], BackBuffer);
      DrawMessage(Txt);
    end
    else
    begin
      DrawPurpleTextCentered(ScreenImg.Bitmap, 'Invalid code', YPositions[2], BackBuffer);
      DrawMessage('Invalid code');
    end;
  except
    Result := false;
  end;
end;

constructor TGameLevelCodeScreen.Create(aOwner: TComponent);
begin
  inherited;
  LevelCode := '..........';
  CursorPosition := 1;
  ScreenImg.Enabled := False;

  OnKeyDown := Form_KeyDown;
  OnKeyPress := Form_KeyPress;
  OnClose := Form_Close;
end;

destructor TGameLevelCodeScreen.Destroy;
begin
  Application.OnIdle := nil;
  inherited;
end;

procedure TGameLevelCodeScreen.DrawChar(aCursorPos: Integer; aBlink: Boolean);
var
  C: Char;
begin
  if aBlink then
    C := '_'
  else
    C := LevelCode[CursorPosition];
  DrawPurpleText(ScreenImg.Bitmap, C, XPos + CursorPosition * 16 - 16, YPositions[1], BackBuffer);
end;

procedure TGameLevelCodeScreen.DrawMessage(const S: string);
begin
  if LastMessage <> '' then
    DrawPurpleTextCentered(ScreenImg.Bitmap, LastMessage, YPositions[2], BackBuffer, True);

  LastMessage := S;

  if S <> '' then
    DrawPurpleTextCentered(ScreenImg.Bitmap, S, YPositions[2]);
end;

procedure TGameLevelCodeScreen.UpdateCheatMessage;
begin
  Assert(GameParams <> nil);

  if LastCheatMessage <> '' then
    DrawPurpleTextCentered(ScreenImg.Bitmap, LastCheatMessage, 330- 20, BackBuffer, True);

  LastCheatMessage := 'All Levels Unlocked';
  DrawPurpleTextCentered(ScreenImg.Bitmap, LastCheatMessage, 330 - 20);
end;


procedure TGameLevelCodeScreen.Form_Close(Sender: TObject; var Action: TCloseAction);
begin
  Application.OnIdle := nil;
  if ValidLevelCode then
    GameParams.WhichLevel := wlLevelCode;
end;

procedure TGameLevelCodeScreen.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if ScreenIsClosing or (Shift <> []) then
    Exit;

  case Key of
    VK_ESCAPE: CloseScreen(gstMenu);
    VK_RETURN:
      begin
        if CheckLevelCode then
        begin
          ValidLevelCode := True;
          CloseDelay := 1000;
          DrawChar(CursorPosition, False);
          CloseScreen(gstPreview);
        end;
      end;
  end;
end;

procedure TGameLevelCodeScreen.Form_KeyPress(Sender: TObject; var Key: Char);
var
  OldC, C: Char;
  OldPos: Integer;
begin
  if ScreenIsClosing then
    Exit;

  Typing := True;
  try

    C := UpCase(Key);
    if C in ['A'..'Z', '0'..'9'] then
    begin
      DrawMessage('');
      OldC := LevelCode[CursorPosition];
      OldPos := CursorPosition;

      LevelCode[CursorPosition] := C;

      if CursorPosition < 10 then
      begin
        DrawChar(CursorPosition, False);
        Inc(CursorPosition);
      end;

      if (OldPos <> CursorPosition) or (OldC <> C) then
      begin
        DrawChar(CursorPosition);
      end;

      ValidLevelCode := False;
    end
    else if C = Chr(8) then begin
      DrawMessage('');
      if CursorPosition > 1 then
      begin
        if LevelCode[CursorPosition] = '.' then
        begin
          DrawChar(CursorPosition, False);
          Dec(CursorPosition);
        end;

        LevelCode[CursorPosition] := '.';
        DrawChar(CursorPosition, False);
        ValidLevelCode := False;
      end;
    end;

  finally
    Typing := False;
  end;
end;

end.

