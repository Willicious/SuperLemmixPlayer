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
  GameControl, GameBaseScreenCommon, GameBaseMenuScreen;

{-------------------------------------------------------------------------------
   The dos postview screen, which shows you how you've done it.
-------------------------------------------------------------------------------}
type
  TGameTextScreen = class(TGameBaseMenuScreen)
  private
    fPreviewText: Boolean;
    function GetScreenText: string;
  protected
    procedure BuildScreen; override;

    procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    procedure OnKeyPress(aKey: Integer); override;
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
begin
  ScreenImg.BeginUpdate;
  try
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 16);

    if PreviewText then
      GameParams.ShownText := true;
  finally
    ScreenImg.EndUpdate;
  end;
end;

constructor TGameTextScreen.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
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

procedure TGameTextScreen.OnKeyPress(aKey: Integer);
var
  S: String;
begin
  if (GameParams.Hotkeys.CheckKeyEffect(aKey).Action = lka_SaveReplay) and (GameParams.NextScreen = gstPostview) then
  begin
    S := GlobalGame.ReplayManager.GetSaveFileName(self, GlobalGame.Level);
    if S = '' then Exit;
    GlobalGame.EnsureCorrectReplayDetails;
    GlobalGame.ReplayManager.SaveToFile(S);
  end else if (GameParams.Hotkeys.CheckKeyEffect(aKey).Action = lka_LoadReplay) and (GameParams.NextScreen = gstPlay) then
    LoadReplay
  else
    case aKey of
      VK_RETURN: CloseScreen(GameParams.NextScreen);
      VK_ESCAPE: if GameParams.TestModeLevel <> nil then
                   CloseScreen(gstExit)
                 else
                   CloseScreen(gstMenu);
    end;
end;

procedure TGameTextScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  if aButton = mbLeft then
    CloseScreen(GameParams.NextScreen);
end;

end.

