{$include lem_directives.inc}

program SuperLemmix;





uses
  Windows,
  LemRes,
  Forms,
  FMain in 'FMain.pas' {MainForm},
  AppController in 'AppController.pas',
  CustomPopup in 'CustomPopup.pas',
  FBaseDosForm in 'FBaseDosForm.pas' {BaseDosForm},
  FEditHotkeys in 'FEditHotkeys.pas' {FLemmixHotkeys},
  FEditReplay in 'FEditReplay.pas' {FReplayEditor},
  FSuperLemmixConfig in 'FSuperLemmixConfig.pas' {FormNXConfig},
  FSuperLemmixLevelSelect in 'FSuperLemmixLevelSelect.pas' {FLevelSelect},
  FSuperLemmixSetup in 'FSuperLemmixSetup.pas' {FNLSetup},
  GameBaseScreenCommon in 'GameBaseScreenCommon.pas',
  GameBaseSkillPanel in 'GameBaseSkillPanel.pas',
  GameCommandLine in 'GameCommandLine.pas',
  GameControl in 'GameControl.pas',
  GamePostviewScreen in 'GamePostviewScreen.pas',
  GamePreviewScreen in 'GamePreviewScreen.pas',
  GameReplayCheckScreen in 'GameReplayCheckScreen.pas',
  GameSkillPanel in 'GameSkillPanel.pas',
  GameSound in 'GameSound.pas',
  GameTextScreen in 'GameTextScreen.pas',
  GameWindow in 'GameWindow.pas',
  GameWindowInterface in 'GameWindowInterface.pas',
  LemAnimationSet in 'LemAnimationSet.pas',
  LemCore in 'LemCore.pas',
  LemCursor in 'LemCursor.pas',
  LemGadgetAnimation in 'LemGadgetAnimation.pas',
  LemGadgets in 'LemGadgets.pas',
  LemGadgetsConstants in 'LemGadgetsConstants.pas',
  LemGadgetsMeta in 'LemGadgetsMeta.pas',
  LemGadgetsModel in 'LemGadgetsModel.pas',
  LemGame in 'LemGame.pas',
  LemGameMessageQueue in 'LemGameMessageQueue.pas',
  LemLemming in 'LemLemming.pas',
  LemLevel in 'LemLevel.pas',
  LemMetaAnimation in 'LemMetaAnimation.pas',
  LemMetaTerrain in 'LemMetaTerrain.pas',
  LemmixHotkeys in 'LemmixHotkeys.pas',
  LemNeoLevelPack in 'LemNeoLevelPack.pas',
  LemNeoParser in 'LemNeoParser.pas',
  LemNeoPieceManager in 'LemNeoPieceManager.pas',
  LemNeoTheme in 'LemNeoTheme.pas',
  LemPalette in 'LemPalette.pas',
  LemPiece in 'LemPiece.pas',
  LemRecolorSprites in 'LemRecolorSprites.pas',
  LemRenderHelpers in 'LemRenderHelpers.pas',
  LemRendering in 'LemRendering.pas',
  LemReplay in 'LemReplay.pas',
  LemSettings in 'LemSettings.pas',
  LemStrings in 'LemStrings.pas',
  LemSystemMessages in 'LemSystemMessages.pas',
  LemTalisman in 'LemTalisman.pas',
  LemTerrain in 'LemTerrain.pas',
  LemTerrainGroup in 'LemTerrainGroup.pas',
  LemTypes in 'LemTypes.pas',
  LemVersion in 'LemVersion.pas',
  PngInterface in 'PngInterface.pas',
  SharedGlobals in 'SharedGlobals.pas',
  FStyleManager in 'FStyleManager.pas' {FManageStyles},
  LemMenuFont in 'LemMenuFont.pas',
  GameBaseMenuScreen in 'GameBaseMenuScreen.pas',
  GameMenuScreen in 'GameMenuScreen.pas',
  FLevelInfo in 'FLevelInfo.pas' {LevelInfoPanel},
  FReplayRename in 'FReplayRename.pas' {FReplayNaming},
  LemProjectile in 'LemProjectile.pas';

{$R *.res}

begin
  {$ifdef debug}
  ReportMemoryLeaksOnShutdown := True;
  {$endif}
  Application.Initialize;
  Application.Title := 'SuperLemmix';
  Application.CreateForm(TMainForm, MainForm);
  Application.HintHidePause := 100000;
  Application.Run;
end.
