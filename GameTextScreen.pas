{$include lem_directives.inc}

unit GameTextScreen;

interface

uses
  LemmixHotkeys,
  Dialogs,
  Windows, Classes, SysUtils, Controls,
  UMisc,
  Gr32, Gr32_Image, Gr32_Layers,
  LemCore,
  LemTypes,
  LemStrings,
  LemLevelSystem,
  LemGame,
  GameControl,
  GameBaseScreen,
  UZip; // only for checking whether preview/postview text files exist
//  LemCore, LemGame, LemDosFiles, LemDosStyles, LemControls,
  //LemDosScreen;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGameTextScreen = class(TGameBaseScreen)
  private
    ScreenText: string;
    function GetScreenText: string;
    function BuildText(intxt: Array of char): string;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure HandleMouseClick(Button: TMouseButton);
  protected
    //procedure PrepareGameParams(Params: TDosGameParams); override;
    procedure BuildScreen; override;
    //procedure CloseScreen(aNextScreen: TGameScreenType); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    function HasScreenText(Params: TDosGameParams): Boolean;
  published
  end;

implementation

uses Forms, LemStyle;

{ TDosGamePreview }

{procedure TGameTextScreen.CloseScreen(aNextScreen: TGameScreenType);
begin
  inherited CloseScreen(aNextScreen);
end;}

{procedure TGameTextScreen.PrepareGameParams(Params: TDosGameParams);
begin
  inherited;

end;}

function TGameTextScreen.HasScreenText(Params: TDosGameParams): Boolean;
begin
  PrepareGameParams(Params);
  ScreenText := GetScreenText;
  if ScreenText = '' then
    Result := false
    else
    Result := true;
end;

procedure TGameTextScreen.BuildScreen;
var
  Temp: TBitmap32;
  st: String;
begin

  {st := GetScreenText;
  if st = '' then
  begin
    CloseScreen(GameParams.NextScreen);
    Exit;
  end;}

  ScreenImg.BeginUpdate;
  Temp := TBitmap32.Create;
  try
    InitializeImageSizeAndPosition(640, 350);
    ExtractBackGround;
    ExtractPurpleFont;

    Temp.SetSize(640, 350);
    Temp.Clear(0);
    TileBackgroundBitmap(0, 0, Temp);
    DrawPurpleTextCentered(Temp, ScreenText, 16);
    ScreenImg.Bitmap.Assign(Temp);
  finally
    ScreenImg.EndUpdate;
    Temp.Free;
  end;
end;

function TGameTextScreen.BuildText(intxt: Array of char): String;
var
  tstr : String;
  x : byte;
begin
  Result := '';
  tstr := '';
  for x := 0 to 35 do
  begin
    if (tstr <> '') or (intxt[x] <> ' ') then
    begin
      tstr := tstr + intxt[x];
    end;
  end;
  Result := Trim(tstr);
end;

constructor TGameTextScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  Stretched := True;
  OnKeyDown := Form_KeyDown;
  OnKeyPress := Form_KeyPress;
  OnMouseDown := Form_MouseDown;
  ScreenImg.OnMouseDown := Img_MouseDown;
end;

destructor TGameTextScreen.Destroy;
begin
  inherited Destroy;
end;

function TGameTextScreen.GetScreenText: string;
var
   TextFileStream: TMemoryStream;
   fn{, ts}: String;
   b: byte;
   lfc: byte;
   Arc: TArchive; // for checking whether files actually exist

    procedure Add(const S: string);
    begin
      Result := Result + S + #13;
      Inc(lfc);
    end;

    procedure LF(aCount: Integer);
    begin
      Result := Result + StringOfChar(#13, aCount);
      Inc(lfc, aCount);
    end;

    procedure PreLF(aCount: Integer);
    begin
      Result := StringOfChar(#13, aCount) +  Result;
      Inc(lfc, aCount);
    end;

begin

  Result := '';
  //ts := '';
  lfc := 0;
  TextFileStream := nil;

  if GameParams.NextScreen = gstPostview then
  begin
    GameParams.ShownText := false;
    fn := 'p'
  end else begin
    if GameParams.ShownText then Exit;
    GameParams.ShownText := true;
    fn := 'i';
  end;

  // fn := ExtractFilePath(ParamStr(0)) + fn + LeadZeroStr(GameParams.Info.dSection + 1, 2) + LeadZeroStr(GameParams.Info.dLevel + 1, 2) + '.txt';
  fn := fn + LeadZeroStr(GameParams.Info.dSection + 1, 2) + LeadZeroStr(GameParams.Info.dLevel + 1, 2) + '.txt';

  fn := ExtractFilePath(ParamStr(0)) + fn;

  TextFileStream := CreateDataStream(fn, ldtText);
  if TextFileStream = nil then Exit;

  while (TextFileStream.Read(b, 1) <> 0) and (lfc < 18) do
  begin
    if (b = 10) then LF(1);
    {begin
      Add(ts);
      ts := '';
    end;}
    if (b >= 32) and (b <= 126) then Result := Result + Chr(b); //ts := ts + Chr(b);
  end;

  while lfc < 18 do
  begin
    if lfc mod 2 = 1 then LF(1)
    else PreLF(1);
  end;

  LF(1);
  Add(SPressMouseToContinue);

  TextFileStream.Free;

  Arc.Free;
end;
procedure TGameTextScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_SaveReplay) and (GameParams.NextScreen = gstPostview) then
  begin
    GlobalGame.Save;
    Exit;
  end;
  case Key of
    VK_RETURN: CloseScreen(GameParams.NextScreen);
    VK_ESCAPE: CloseScreen(gstMenu);
  end;
end;

procedure TGameTextScreen.Form_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  HandleMouseClick(Button);
end;

procedure TGameTextScreen.Img_MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  HandleMouseClick(Button);
end;

procedure TGameTextScreen.HandleMouseClick(Button: TMouseButton);
begin
  if Button = mbLeft then
    CloseScreen(GameParams.NextScreen);
end;

procedure TGameTextScreen.Form_KeyPress(Sender: TObject; var Key: Char);
begin

end;

end.

