unit FNeoLemmixSetup;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TFNLSetup = class(TForm)
    SetupPages: TPageControl;
    TabSheet1: TTabSheet;
    lblWelcome: TLabel;
    lblOptionsText1: TLabel;
    lblOptionsText2: TLabel;
    btnNext: TButton;
    btnExit: TButton;
    lblHotkeys: TLabel;
    cbHotkey: TComboBox;
    lblGraphics: TLabel;
    cbGraphics: TComboBox;
    lblUsername: TLabel;
    ebUserName: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure SetClassicHotkeys;
    procedure SetLixHotkeys;
    procedure SetMinimalHotkeys;
  public
    NameOnly: Boolean;
  end;

implementation

uses
  GameControl, LemmixHotkeys, LemCore;

{$R *.dfm}

{ Misc Functions }

procedure TFNLSetup.FormCreate(Sender: TObject);
begin
  SetupPages.TabIndex := 0;
end;

procedure TFNLSetup.FormShow(Sender: TObject);
begin
  if NameOnly then
  begin
    cbHotkey.Visible := false;
    lblHotkeys.Visible := false;
    cbGraphics.Visible := false;
    lblGraphics.Visible := false;
    lblOptionsText1.Caption := 'This version of NeoLemmix requires a username.';
    lblOptionsText2.Caption := 'This name will be saved in your replay files. You may enter "Anonymous".';
  end;
end;

procedure TFNLSetup.SetClassicHotkeys;
begin
  GameParams.Hotkeys.ClearAllKeys;
  GameParams.Hotkeys.SetDefaults;
end;

procedure TFNLSetup.SetLixHotkeys;
begin
  with GameParams.Hotkeys do
  begin
    ClearAllKeys;

    // Here's the simple ones that don't need further settings.
    SetKeyFunction($53, lka_DirLeft);
    SetKeyFunction($46, lka_DirRight);
    SetKeyFunction($25, lka_DirLeft);
    SetKeyFunction($27, lka_DirRight);
    SetKeyFunction($20, lka_Pause);
    SetKeyFunction($70, lka_Restart);
    SetKeyFunction($71, lka_LoadState);
    SetKeyFunction($72, lka_SaveState);
    SetKeyFunction($34, lka_FastForward);
    SetKeyFunction($35, lka_FastForward);
    SetKeyFunction($04, lka_Pause);
    SetKeyFunction($05, lka_ZoomIn);
    SetKeyFunction($06, lka_ZoomOut);
    SetKeyFunction($1B, lka_Exit);
    SetKeyFunction($02, lka_Scroll);
    SetKeyFunction($75, lka_SaveReplay);
    SetKeyFunction($76, lka_LoadReplay);
    SetKeyFunction($11, lka_Highlight);
    SetKeyFunction($4D, lka_Music);
    SetKeyFunction($4E, lka_Sound);
    SetKeyFunction($73, lka_ReleaseRateDown);
    SetKeyFunction($74, lka_ReleaseRateUp);
    SetKeyFunction($49, lka_FallDistance);
    SetKeyFunction($50, lka_EditReplay);
    SetKeyFunction($4F, lka_ReplayInsert);
    SetKeyFunction($0D, lka_SaveImage);
    SetKeyFunction($4A, lka_Scroll);

    // Misc ones that need other details set
    SetKeyFunction($BF, lka_ClearPhysics, 1);

    // Skips
    SetKeyFunction($31, lka_Skip, -17);
    SetKeyFunction($32, lka_Skip, -1);
    SetKeyFunction($33, lka_Skip, 1);
    SetKeyFunction($36, lka_Skip, 170);
    SetKeyFunction($37, lka_SpecialSkip, 0);
    SetKeyFunction($38, lka_SpecialSkip, 1);
    SetKeyFunction($39, lka_SpecialSkip, 2);

    // Skills
    SetKeyFunction($44, lka_Skill, Integer(spbWalker));  // walker, D
    SetKeyFunction($12, lka_Skill, Integer(spbShimmier)); // shimmier, alt
    SetKeyFunction($5A, lka_Skill, Integer(spbClimber));  // climber, Z
    SetKeyFunction($10, lka_Skill, Integer(spbSwimmer));  // swimmer, shift
    SetKeyFunction($51, lka_Skill, Integer(spbFloater));  // floater, Q
    SetKeyFunction($09, lka_Skill, Integer(spbGlider));  // glider, tab
    SetKeyFunction($52, lka_Skill, Integer(spbDisarmer));  // disarmer, R
    SetKeyFunction($56, lka_Skill, Integer(spbBomber));  // bomber, V
    SetKeyFunction($42, lka_Skill, Integer(spbStoner));  // stoner, B
    SetKeyFunction($58, lka_Skill, Integer(spbBlocker));  // blocker, X
    SetKeyFunction($54, lka_Skill, Integer(spbPlatformer));  // platformer, T
    SetKeyFunction($41, lka_Skill, Integer(spbBuilder)); // builder, A
    SetKeyFunction($59, lka_Skill, Integer(spbStacker)); // stacker, Y
    SetKeyFunction($45, lka_Skill, Integer(spbBasher)); // basher, E
    SetKeyFunction($43, lka_Skill, Integer(spbFencer)); // fencer, C
    SetKeyFunction($47, lka_Skill, Integer(spbMiner)); // miner, G
    SetKeyFunction($57, lka_Skill, Integer(spbDigger)); // digger, W
    SetKeyFunction($48, lka_Skill, Integer(spbCloner)); // cloner, H
  end;
end;

procedure TFNLSetup.SetMinimalHotkeys;
begin
  with GameParams.Hotkeys do
  begin
    ClearAllKeys;

    SetKeyFunction($04, lka_Pause);
    SetKeyFunction($05, lka_ZoomIn);
    SetKeyFunction($06, lka_ZoomOut);
    SetKeyFunction($02, lka_Scroll);
    SetKeyFunction($1B, lka_Exit);
  end;
end;

{ Page Control }

procedure TFNLSetup.btnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFNLSetup.btnOKClick(Sender: TObject);
begin
  // Set desired default settings
  if ebUserName.Text <> '' then
    GameParams.UserName := ebUserName.Text;

  if not NameOnly then
  begin
    case cbHotkey.ItemIndex of
      0: SetLixHotkeys;
      1: SetClassicHotkeys;
      2: SetMinimalHotkeys;
    end;

    case cbGraphics.ItemIndex of
      1, 3: begin
           GameParams.MinimapHighQuality := true;
           GameParams.LinearResampleMenu := true;
           GameParams.LinearResampleGame := false;
         end;
      0, 2: begin
           GameParams.MinimapHighQuality := false;
           GameParams.LinearResampleMenu := false;
           GameParams.LinearResampleGame := false;
         end;
    end;

    GameParams.HighResolution := cbGraphics.ItemIndex >= 2;
  end;

  Close;
end;

end.
