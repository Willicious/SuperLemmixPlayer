{$include lem_directives.inc}

unit GameTextScreen;

interface

uses
  Dialogs, // debug
  LemmixHotkeys,
  Windows, Classes, SysUtils, Controls, StrUtils,
  UMisc,
  Gr32, Gr32_Layers,
  LemTypes, LemStrings, LemGame,
  GameControl, GameBaseScreen;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGameTextScreen = class(TGameBaseScreen)
  private
    fPreviewText: Boolean;
    function GetScreenText: string;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Form_KeyPress(Sender: TObject; var Key: Char);
    procedure Form_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure HandleMouseClick(Button: TMouseButton);
  protected
    procedure BuildScreen; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    property PreviewText: Boolean read fPreviewText write fPreviewText;
  published
  end;

implementation

uses Forms;

{ TDosGamePreview }

procedure TGameTextScreen.BuildScreen;
var
  Temp: TBitmap32;
begin
  ScreenImg.BeginUpdate;
  Temp := TBitmap32.Create;
  try
    InitializeImageSizeAndPosition(INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);
    ExtractBackGround;
    ExtractPurpleFont;

    Temp.SetSize(INTERNAL_SCREEN_WIDTH, INTERNAL_SCREEN_HEIGHT);
    Temp.Clear(0);
    TileBackgroundBitmap(0, 0, Temp);
    DrawPurpleTextCentered(Temp, GetScreenText, 16);
    ScreenImg.Bitmap.Assign(Temp);

    if PreviewText then
      GameParams.ShownText := true;
  finally
    ScreenImg.EndUpdate;
    Temp.Free;
  end;
end;

constructor TGameTextScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
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
  i: Integer;
  lfc: Integer;
  SL: TStringList;

  procedure HandleSubstitutions(var S: String);
  var
    KeyNames: TKeyNameArray;

    function MakeHotkeyText(const S: String): String;
    var
      Key: TLemmixHotkeyAction;
      Modifier: Integer;
      CheckMod: Boolean;
      ThisKey: TLemmixHotkey;

      n: Integer;
    begin
      Result := '';

      if Pos(':', S) = 0 then
      begin
        if Uppercase(S) = 'SKIP+' then
        begin
          Key := lka_Skip;
          Modifier := 1;
          CheckMod := false;
        end else if Uppercase(S) = 'SKIP-' then
        begin
          Key := lka_Skip;
          Modifier := -1;
          CheckMod := false;
        end else begin
          Key := TLemmixHotkeyManager.InterpretMain(S);
          Modifier := 0;
          CheckMod := false;
        end;
      end else begin
        Key := TLemmixHotkeyManager.InterpretMain(LeftStr(S, Pos(':', S) - 1));
        Modifier := TLemmixHotkeyManager.InterpretSecondary(RightStr(S, Length(S) - Pos(':', S)));
        CheckMod := true;
      end;

      if Key = lka_Null then
      begin
        Result := '## INVALID KEY ##';
        Exit;
      end;

      for n := 0 to MAX_KEY do
      begin
        ThisKey := GameParams.Hotkeys.CheckKeyEffect(n);
        if ThisKey.Action <> Key then Continue;
        if CheckMod and (ThisKey.Modifier <> Modifier) then Continue;
        if (not CheckMod) and (Key = lka_Skip) and (Modifier <> 0) then
          if (Modifier < 0) <> (ThisKey.Modifier < 0) then
            Continue;

        Result := Result + '{' + Keynames[n] + '}  ';
      end;

      if Length(Result) = 0 then
        Result := '{None}'
      else
        Result := LeftStr(Result, Length(Result) - 2); // remove the double-space at the end
    end;

  var
    FoundStartPos, FoundEndPos: Integer;
    SubSrcText: String;

    procedure Replace(const newText: String);
    begin
      S := LeftStr(S, FoundStartPos - 1) +
           newText +
           RightStr(S, Length(S) - FoundEndPos);
    end;
  begin
    KeyNames := TLemmixHotkeyManager.GetKeyNames(true);

    while Pos('[', S) <> 0 do
    begin
      FoundStartPos := Pos('[', S);
      FoundEndPos := Pos(']', S, FoundStartPos);

      SubSrcText := Uppercase(MidStr(S, FoundStartPos + 1, FoundEndPos - FoundStartPos - 1));

      if LeftStr(SubSrcText, 7) = 'HOTKEY:' then
        Replace(MakeHotkeyText(RightStr(SubSrcText, Length(SubSrcText) - 7)))
      else
        Break;
    end;
  end;

  procedure Add(S: string);
  begin
    HandleSubstitutions(S);
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

  if fPreviewText then
    SL := GameParams.Level.PreText
  else
    SL := GameParams.Level.PostText;

  for i := 0 to SL.Count-1 do
    if i > 20 then
      Break
    else
      Add(SL[i]);

  while lfc < 22 do
    if lfc mod 2 = 1 then
      PreLF(1)
    else
      LF(1);

  LF(1);
  Add(SPressMouseToContinue);
end;

procedure TGameTextScreen.Form_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  S: String;
begin
  if (GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_SaveReplay) and (GameParams.NextScreen = gstPostview) then
  begin
    S := GlobalGame.ReplayManager.GetSaveFileName(self, GlobalGame.Level);
    if S = '' then Exit;
    GlobalGame.EnsureCorrectReplayDetails;
    GlobalGame.ReplayManager.SaveToFile(S);
  end else if (GameParams.Hotkeys.CheckKeyEffect(Key).Action = lka_LoadReplay) and (GameParams.NextScreen = gstPlay) then
    LoadReplay
  else
    case Key of
      VK_RETURN: CloseScreen(GameParams.NextScreen);
      VK_ESCAPE: if GameParams.TestModeLevel <> nil then
                   CloseScreen(gstExit)
                 else
                   CloseScreen(gstMenu);
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

