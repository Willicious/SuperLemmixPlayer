unit GameCommandLine;

// Some command line utilities. For use by external tools, and hopefully someday,
// a level archive website.

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

    SL: TStringList;
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

    AnimRect := Rect(0, 0, 0, 0); // avoid compiler warning
    PhysRect := Rect(0, 0, 0, 0);
    Accessor := PieceManager.Objects[PieceIdentifier].GetInterface(Flip, Invert, Rotate);

    PieceManager.Objects[PieceIdentifier].GetInterface(Flip, Invert, Rotate).GetBoundsInfo(AnimRect, PhysRect);

    if (Width < 0) or (not Accessor.CanResizeHorizontal) then
      Width := PhysRect.Width;

    if (Height < 0) or (not Accessor.CanResizeVertical) then
      Height := PhysRect.Height;

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

    // Get ready for a really epic kludge. We will generally want any teleporter
    // or receiver to render as non-disabled, and any locked exit to render in
    // locked state. So how do we do this? By adding a paired teleporter/receiver
    // or an unlock button respectively, and placing it outside the "level".

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

    if LineValues.Values['INFO_FILE'] <> '' then
    begin
      SL := TStringList.Create;
      try
        SL.Add('OFFSET_LEFT ' + IntToStr(PhysRect.Left));
        SL.Add('OFFSET_TOP ' + IntToStr(PhysRect.Top));
        SL.Add('OFFSET_RIGHT ' + IntToStr(AnimRect.Right - PhysRect.Right));
        SL.Add('OFFSET_BOTTOM ' + IntToStr(AnimRect.Bottom - PhysRect.Bottom));
        ForceDirectories(ExtractFilePath(RootPath(LineValues.Values['INFO_FILE'])));
        SL.SaveToFile(RootPath(LineValues.Values['INFO_FILE']));
      finally
        SL.Free;
      end;
    end;
  end;

  procedure AddEditorStyle(aStyleName: String);
  var
    SearchRec: TSearchRec;
    MetaInfo: TGadgetMetaInfo;
    Accessor: TGadgetMetaAccessor;
    OutputDst: String;
  begin
    if not DirectoryExists(AppPath + 'styles\' + aStyleName) then
      Exit;

    if FindFirst(AppPath + 'styles\' + aStyleName + '\objects\*.nxmo', 0, SearchRec) = 0 then
    begin
      repeat
        MetaInfo := PieceManager.Objects[aStyleName + ':' + ChangeFileExt(SearchRec.Name, '')];
        Accessor := MetaInfo.GetInterface(false, false, false);

        // Detect if the editor actually needs this object pre-rendered.
        if (Accessor.Animations.Count = 1) and
           (Accessor.Animations.PrimaryAnimation.Color = '') then
          Continue;

        // Detect pieces the editor doesn't support pre-rendering of.
        if (LowerCase(MetaInfo.Identifier) = 'default:pickup') or
           (MetaInfo.TriggerEffect in [DOM_ONEWAYLEFT, DOM_ONEWAYRIGHT, DOM_ONEWAYDOWN, DOM_ONEWAYUP]) or
           (Accessor.Animations.PrimaryAnimation.CutRect <> Rect(0, 0, 0, 0)) then
          Continue;

        OutputDst := AppPath + 'editor\render\' + aStyleName + '\objects\' + MetaInfo.Piece;
        SL.Add('OBJECT|' + MetaInfo.Identifier + '|OUTPUT=' + OutputDst + '.png|INFO_FILE=' + OutputDst + '.nxmo');
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure AddEditorAllStyles;
  var
    SearchRec: TSearchRec;
  begin
    if FindFirst(AppPath + 'styles\*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Attr and faDirectory = 0) or
           (SearchRec.Name = '..') or
           (SearchRec.Name = '.') then
          Continue;

        AddEditorStyle(SearchRec.Name);

        PieceManager.Tidy;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  end;

  procedure AddEditorParamStyles;
  var
    i: Integer;
  begin
    i := 3;
    while ParamStr(i) <> '' do
    begin
      AddEditorStyle(ParamStr(i));
      Inc(i);
    end;
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
    else if ParamStr(2) = '-editor' then
    begin
      if ParamStr(3) = '' then
        AddEditorAllStyles
      else
        AddEditorParamStyles;
    end else begin
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

      DstFile := RootPath(LineValues.Values['OUTPUT']); // fallback must be implemented per-item!

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
  InitializeNoGuiMode; // Misleading in this case, because a GUI *is* used for
                       // testplay mode. But it does the required things.

  GameParams.TestModeLevel.Filename := ParamStr(2);
  if Pos(':', GameParams.TestModeLevel.Filename) = 0 then
    GameParams.TestModeLevel.Filename := AppPath + GameParams.TestModeLevel.Filename;
end;

class procedure TCommandLineHandler.HandleVersionInfo;
var
  SL: TStringList;

  Formats: String;
  Exts: String;

  procedure AddFormat(aDesc, aExt: String);
  begin
    if Formats <> '' then
      Formats := Formats + '|';
    if Exts <> '' then
      Exts := Exts + ';';
    Formats := Formats + aDesc + '|' + '*.' + aExt;
    Exts := Exts + '*.' + aExt;
  end;

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

    Formats := '';
    Exts := '';
    AddFormat('Lemmix or old NeoLemmix level (*.lvl)', 'lvl');
    AddFormat('Lemmini or SuperLemmini level (*.ini)', 'ini');
    AddFormat('Lemmins level (*.lev)', 'lev');

    SL.Add('level_formats=' + Formats);
    SL.Add('level_format_exts=' + Exts);

    SL.Add('object_render=true');
    SL.Add('level_render=true');

    WriteInfo;

    if LowerCase(ParamStr(2)) <> 'silent' then
      SL.SaveToFile(AppPath + 'NeoLemmixVersion.ini');
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
