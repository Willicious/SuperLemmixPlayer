unit GameCommandLine;

// Some command line utilities. For use by external tools (and hopefully someday a level archive website).

interface

uses
  GR32, PngInterface,
  GameControl,
  LemNeoPieceManager,
  LemLevel,
  LemGadgetsMeta, LemGadgetsModel, LemGadgets, LemGadgetsConstants,
  LemTypes,
  LemVersion,
  Classes,
  IOUtils,
  StrUtils,
  SysUtils;

type
  TCommandLineResult = (clrContinue, clrHalt, clrToPreview);

  TCommandLineHandler = class
    private
      class procedure InitializeNoGuiMode;

      class procedure HandleRender;
      class procedure HandleVersionInfo;
      class procedure HandleConvert;
      class procedure HandleTestMode;
      class procedure HandleUpscale;
    public
      class function HandleCommandLine: TCommandLineResult;
  end;

implementation

{ TCommandLineHandler }

class function TCommandLineHandler.HandleCommandLine: TCommandLineResult;
var
  Param: String;
begin
  Param := Lowercase(ParamStr(1));
  Result := clrContinue;

  if Param = 'shortcut' then
  begin
    GameParams.SetCurrentLevelToBestMatch(ParamStr(2));
    Result := clrContinue;
  end;

  if Param = 'test' then
  begin
    HandleTestMode;
    Result := clrToPreview;
  end;

  if Param = 'convert' then
  begin
    HandleConvert;
    Result := clrHalt;
  end;

  if Param = 'version' then
  begin
    HandleVersionInfo;
    Result := clrHalt;
  end;

  if Param = 'render' then
  begin
    HandleRender;
    Result := clrHalt;
  end;

  if Param = 'upscale' then
  begin
    HandleUpscale;
    Result := clrHalt;
  end;

  if Param = '-match-blank-replay-username' then
    GameParams.MatchBlankReplayUsername := true;
end;

class procedure TCommandLineHandler.HandleConvert;
var
  DstFile: String;
begin
  InitializeNoGuiMode;
  GameParams.TestModeLevel.Filename := ParamStr(2);

  DstFile := ParamStr(3);
  if DstFile = '' then
    DstFile := ChangeFileExt(GameParams.CurrentLevel.Path, '.nxlv')
  else if Pos(':', DstFile) = 0 then
    DstFile := AppPath + DstFile;

  GameParams.LoadCurrentLevel(true);
  GameParams.Level.SaveToFile(DstFile);
end;

class procedure TCommandLineHandler.HandleRender;
var
  BasePath: String;
  SL: TStringList;
  i: Integer;

  LineValues: TStringList;
  DstFile: String;
  Dst: TBitmap32;

  function RootPath(aInput: String): String;
  begin
    Result := aInput;

    if Result = '' then
      Exit;

    if not TPath.IsPathRooted(Result) then
      Result := BasePath + Result;
  end;

  procedure DoRenderLevel;
  begin
    GameParams.TestModeLevel.Filename := RootPath(LineValues[1]);
    GameParams.LoadCurrentLevel(false);

    if DstFile = '' then
      DstFile := RootPath(ChangeFileExt(GameParams.TestModeLevel.Filename, '.png'));

    GameParams.Renderer.TransparentBackground := false;
    GameParams.Renderer.RenderWorld(Dst, true);

    ForceDirectories(ExtractFilePath(DstFile));
    TPngInterface.SavePngFile(DstFile, Dst);
  end;

  procedure DoRenderObject;
  var
    PieceIdentifier: String;
    Theme: String;
    Level: TLevel;

    AnimRect, PhysRect: TRect;
    NewGadget: TGadgetModel;

    Flip, Invert, Rotate: Boolean;

    Width, Height, ExtraWidth, ExtraHeight: Integer;
    Accessor: TGadgetMetaAccessor;
  begin
    PieceIdentifier := LineValues[1];
    Theme := LineValues.Values['THEME'];
    if Theme = '' then
      Theme := LeftStr(PieceIdentifier, Pos(':', PieceIdentifier) - 1);

    Level := GameParams.Level;

    Level.Clear;

    Level.Info.GraphicSetName := Theme;
    GameParams.ReloadCurrentLevel;

    Flip := Trim(Uppercase(LineValues.Values['FLIP'])) = 'TRUE';
    Invert := Trim(Uppercase(LineValues.Values['INVERT'])) = 'TRUE';
    Rotate := Trim(Uppercase(LineValues.Values['ROTATE'])) = 'TRUE';

    Width := StrToIntDef(LineValues.Values['WIDTH'], -1);
    Height := StrToIntDef(LineValues.Values['HEIGHT'], -1);

    AnimRect := Rect(0, 0, 0, 0); // Avoid compiler warning
    PhysRect := Rect(0, 0, 0, 0);
    Accessor := PieceManager.Objects[PieceIdentifier].GetInterface(Flip, Invert, Rotate);

    PieceManager.Objects[PieceIdentifier].GetInterface(Flip, Invert, Rotate).GetBoundsInfo(AnimRect, PhysRect);

    Width := EvaluateResizable(Width, Accessor.DefaultWidth, Accessor.Width, Accessor.CanResizeHorizontal);
    Height := EvaluateResizable(Height, Accessor.DefaultHeight, Accessor.Height, Accessor.CanResizeVertical);

    ExtraWidth := Width - PhysRect.Width;
    ExtraHeight := Height - PhysRect.Height;

    Level.Info.Width := AnimRect.Width + ExtraWidth;
    Level.Info.Height := AnimRect.Height + ExtraHeight;

    NewGadget := TGadgetModel.Create;
    NewGadget.GS := LeftStr(PieceIdentifier, Pos(':', PieceIdentifier) - 1);
    NewGadget.Piece := RightStr(PieceIdentifier, Length(PieceIdentifier) - Pos(':', PieceIdentifier));
    NewGadget.Left := PhysRect.Left;
    NewGadget.Top := PhysRect.Top;
    NewGadget.Flip := Flip;
    NewGadget.Invert := Invert;
    NewGadget.Rotate := Rotate;
    NewGadget.Skill := StrToIntDef(LineValues.Values['S'], 0);
    NewGadget.TarLev := StrToIntDef(LineValues.Values['L'], 0);
    NewGadget.Width := Width;
    NewGadget.Height := Height;
    Level.InteractiveObjects.Add(NewGadget);

    if Uppercase(Trim(LineValues.Values['CENTER_ONLY'])) = 'TRUE' then
    begin
      // I will need to improve this later to account for nine-slicing in secondary animations.
      NewGadget.Left := NewGadget.Left - Accessor.Animations.Items[0].CutLeft;
      NewGadget.Top := NewGadget.Top - Accessor.Animations.Items[0].CutTop;
      NewGadget.Width := NewGadget.Width + Accessor.Animations.Items[0].CutLeft + Accessor.Animations.Items[0].CutRight;
      NewGadget.Height := NewGadget.Height + Accessor.Animations.Items[0].CutTop + Accessor.Animations.Items[0].CutBottom;
    end;

    // Get ready for a really epic kludge! We generally want any teleporter/receiver to render as non-disabled.
    // So, we add a paired teleporter/receiver, and place it outside the "level".

    if not (Uppercase(Trim(LineValues.Values['ALLOW_DISABLED'])) = 'TRUE') then
    begin
      if Accessor.TriggerEffect = DOM_TELEPORT then
      begin
        NewGadget := TGadgetModel.Create;
        NewGadget.GS := 'orig_marble';
        NewGadget.Piece := 'receiver';
        NewGadget.Left := -100;
        NewGadget.Top := -100;
        Level.InteractiveObjects.Add(NewGadget);
      end;

      if Accessor.TriggerEffect = DOM_RECEIVER then
      begin
        NewGadget := TGadgetModel.Create;
        NewGadget.GS := 'orig_marble';
        NewGadget.Piece := 'teleporter';
        NewGadget.Left := -100;
        NewGadget.Top := -100;
        Level.InteractiveObjects.Add(NewGadget);
      end;

      if Accessor.TriggerEffect = DOM_TELEPORT then
      begin
        NewGadget := TGadgetModel.Create;
        NewGadget.GS := 'default';
        NewGadget.Piece := 'button';
        NewGadget.Left := -100;
        NewGadget.Top := -100;
        Level.InteractiveObjects.Add(NewGadget);
      end;
    end;

    GameParams.ReloadCurrentLevel;
    if DstFile = '' then
      DstFile := RootPath(MakeSafeForFilename(StringReplace(PieceIdentifier, ':', ' ', [rfReplaceAll])) + '.png');

    GameParams.Renderer.TransparentBackground := true;
    GameParams.Renderer.RenderWorld(Dst, true);

    ForceDirectories(ExtractFilePath(DstFile));
    TPngInterface.SavePngFile(DstFile, Dst);
  end;

begin
  InitializeNoGuiMode;

  SL := TStringList.Create;
  LineValues := TStringList.Create;
  Dst := TBitmap32.Create;
  try
    LineValues.Delimiter := '|';
    LineValues.StrictDelimiter := true;

    if ParamStr(2) = '-listfile' then
      SL.LoadFromFile(ParamStr(3))
    else begin
      i := 2;
      while ParamStr(i) <> '' do
      begin
        SL.Add(ParamStr(i));
        Inc(i);
      end;
    end;

    BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

    for i := 0 to SL.Count-1 do
    begin
      SetCurrentDir(BasePath);
      LineValues.DelimitedText := SL[i];
      if LineValues.Count = 0 then
        Continue;

      DstFile := RootPath(LineValues.Values['OUTPUT']); // Fallback must be implemented per-item!

      if Trim(Uppercase(LineValues[0])) = 'LEVEL' then DoRenderLevel;
      if Trim(Uppercase(LineValues[0])) = 'OBJECT' then DoRenderObject;

      PieceManager.Tidy;
    end;
  finally
    SL.Free;
    LineValues.Free;
    Dst.Free;
  end;
end;

class procedure TCommandLineHandler.HandleTestMode;
begin
  InitializeNoGuiMode; // Misleading in this case, because a GUI *is* used for testplay mode.
                       // But, it does the required things.

  GameParams.TestModeLevel.Filename := ParamStr(2);
  if Pos(':', GameParams.TestModeLevel.Filename) = 0 then
    GameParams.TestModeLevel.Filename := AppPath + GameParams.TestModeLevel.Filename;
end;

class procedure TCommandLineHandler.HandleUpscale;
var
  n: Integer;
  BMPIn, BMPOut: TBitmap32;
  Path: String;
  SL: TStringList;
  Settings: TUpscaleSettings;
begin
  n := 2;
  BMPIn := TBitmap32.Create;
  BMPOut := TBitmap32.Create;
  SL := TStringList.Create;
  try
    SL.Delimiter := '*';
    SL.StrictDelimiter := true;

    while ParamStr(n) <> '' do
    begin
      SL.DelimitedText := ParamStr(n);
      Inc(n);

      if SL.Count = 0 then Continue;

      while SL.Count < 3 do
        SL.Add('1');

      Path := SL[0];
      if not TPath.IsPathRooted(Path) then
        Path := AppPath + Path;

      TPngInterface.LoadPngFile(Path, BMPIn);

      FillChar(Settings, SizeOf(Settings), 0);
      Settings.Mode := umPixelArt;
      UpscaleFrames(BMPIn, StrToIntDef(SL[1], 1), StrToIntDef(SL[2], 1), Settings, BMPOut);
      TPngInterface.SavePngFile(ChangeFileExt(Path, '-pa.png'), BMPOut);

      FillChar(Settings, SizeOf(Settings), 0);
      Settings.Mode := umFullColor;
      UpscaleFrames(BMPIn, StrToIntDef(SL[1], 1), StrToIntDef(SL[2], 1), Settings, BMPOut);
      TPngInterface.SavePngFile(ChangeFileExt(Path, '-fc.png'), BMPOut);
    end;
  finally
    BMPIn.Free;
    BMPOut.Free;
    SL.Free;
  end;
end;

class procedure TCommandLineHandler.HandleVersionInfo;
var
  SL: TStringList;

  procedure WriteInfo;
  var
    i: Integer;
  begin
    for i := 0 to SL.Count-1 do
      WriteLn(SL[i]);
  end;
begin
  SL := TStringList.Create;
  try
    SL.Add('formats=' + IntToStr(FORMAT_VERSION));
    SL.Add('core=' + IntToStr(CORE_VERSION));
    SL.Add('features=' + IntToStr(FEATURES_VERSION));
    SL.Add('hotfix=' + IntToStr(HOTFIX_VERSION));
    SL.Add('commit=' + COMMIT_ID);

    SL.Add('level_formats=');
    SL.Add('level_format_exts=');

    SL.Add('object_render=true');
    SL.Add('level_render=true');

    WriteInfo;

    if LowerCase(ParamStr(2)) <> 'silent' then
      SL.SaveToFile(AppPath + 'SuperLemmixVersion.ini');
  finally
    SL.Free;
  end;
end;

class procedure TCommandLineHandler.InitializeNoGuiMode;
begin
  GameParams.BaseLevelPack.EnableSave := false;
  GameParams.BaseLevelPack.Children.Clear;
  GameParams.BaseLevelPack.Levels.Clear;
  GameParams.TestModeLevel := GameParams.BaseLevelPack.Levels.Add;
  GameParams.SetLevel(GameParams.TestModeLevel);
end;

end.
