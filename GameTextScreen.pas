{$include lem_directives.inc}

unit GameTextScreen;

interface

uses
  Types,
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
      procedure ToNextScreen;
      procedure ExitToMenu;
      procedure TryLoadReplay;
    protected
      procedure BuildScreen; override;
      function GetBackgroundSuffix: String; override;

      procedure OnMouseClick(aPoint: TPoint; aButton: TMouseButton); override;
    public
      constructor Create(aOwner: TComponent); override;
      property PreviewText: Boolean read fPreviewText;
  end;

implementation

uses Forms;

{ TDosGamePreview }

procedure TGameTextScreen.BuildScreen;
var
  NewOption: TClickableRegion;
begin
  ScreenImg.BeginUpdate;
  try
    MenuFont.DrawTextCentered(ScreenImg.Bitmap, GetScreenText, 16);

    if GameParams.ShowMinimap and not GameParams.FullScreen then
      NewOption := MakeClickableText(Point(MM_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_ONE_ROW_Y), SOptionContinue, ToNextScreen)
    else if GameParams.FullScreen then
      NewOption := MakeClickableText(Point(FS_FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_ONE_ROW_Y), SOptionContinue, ToNextScreen)
    else
      NewOption := MakeClickableText(Point(FOOTER_ONE_OPTION_X, FOOTER_OPTIONS_ONE_ROW_Y), SOptionContinue, ToNextScreen);
    NewOption.ShortcutKeys.Add(VK_RETURN);
    NewOption.ShortcutKeys.Add(VK_SPACE);

    MakeHiddenOption(VK_ESCAPE, ExitToMenu);

    if PreviewText then
      MakeHiddenOption(lka_LoadReplay, TryLoadReplay)
    else
      MakeHiddenOption(lka_SaveReplay, SaveReplay);

    DrawAllClickables;

    if PreviewText then
      GameParams.ShownText := true;
  finally
    ScreenImg.EndUpdate;
  end;
end;

function TGameTextScreen.GetBackgroundSuffix: String;
begin
  if PreviewText then
    Result := 'pretext'
  else
    Result := 'posttext';
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
  lfc := 0;

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
end;

procedure TGameTextScreen.OnMouseClick(aPoint: TPoint; aButton: TMouseButton);
begin
  inherited;
  ToNextScreen;
end;

constructor TGameTextScreen.Create(aOwner: TComponent);
begin
  fPreviewText := (GameParams.NextScreen = gstPlay);
  inherited Create(aOwner);
end;

procedure TGameTextScreen.ExitToMenu;
begin
  if GameParams.TestModeLevel <> nil then
    CloseScreen(gstExit)
  else
    CloseScreen(gstMenu);
end;

procedure TGameTextScreen.ToNextScreen;
begin
  CloseScreen(GameParams.NextScreen);
end;

procedure TGameTextScreen.TryLoadReplay;
begin
  // See comment on TGamePreviewScreen.TryLoadReplay.
  LoadReplay;
end;

end.

