unit FSuperLemmixSetup;

interface

uses
  Math,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Vcl.ExtCtrls, Vcl.Imaging.pngimage;

type
  TFNLSetup = class(TForm)
    SetupPages: TPageControl;
    TabSheet1: TTabSheet;
    lblWelcome: TLabel;
    lblOptionsText1: TLabel;
    lblOptionsText2: TLabel;
    btnNext: TButton;
    btnExit: TButton;
    lblGraphics: TLabel;
    cbGraphics: TComboBox;
    lblUsername: TLabel;
    ebUserName: TEdit;
    lblGameplay: TLabel;
    cbGameplay: TComboBox;
    lblHotkeys: TLabel;
    cbHotkeys: TComboBox;
    Floater: TImage;
    L1Art: TImage;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure lblWelcomeClick(Sender: TObject);
  private
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

procedure TFNLSetup.lblWelcomeClick(Sender: TObject);
begin

end;

{ Page Control }

procedure TFNLSetup.btnExitClick(Sender: TObject);
begin
  GameParams.DisableSaveOptions := true;
  Application.Terminate;
end;

procedure TFNLSetup.btnOKClick(Sender: TObject);
begin
  // Set desired default settings
  GameParams.UserName := ebUserName.Text;

  case cbGraphics.ItemIndex of
    1, 3: begin
         GameParams.ShowMinimap := true;
         GameParams.MinimapHighQuality := true;
         GameParams.LinearResampleMenu := true;
         //GameParams.LinearResampleGame := false;
       end;
    0, 2: begin
         GameParams.ShowMinimap := true;
         GameParams.MinimapHighQuality := false;
         GameParams.LinearResampleMenu := false;
         //GameParams.LinearResampleGame := false;
       end;
  end;

  GameParams.HighResolution := cbGraphics.ItemIndex >= 2;
  if GameParams.HighResolution then
    GameParams.ZoomLevel := Max(GameParams.ZoomLevel div 2, 1);

  ////put these back when all online features are back in
  //GameParams.EnableOnline := cbOnline.ItemIndex >= 1;
  //GameParams.CheckUpdates := cbOnline.ItemIndex >= 2;

  case cbGameplay.ItemIndex of
    0: begin
         GameParams.ClassicMode := true;
         GameParams.HideShadows := true;
         GameParams.HideClearPhysics := true;
         GameParams.HideAdvancedSelect := true;
         GameParams.HideFrameskipping := true;
         GameParams.HideHelpers := true;
         GameParams.HideSkillQ := true;
       end;
    1: begin
         GameParams.ClassicMode := false;
         GameParams.HideShadows := false;
         GameParams.HideClearPhysics := false;
         GameParams.HideAdvancedSelect := false;
         GameParams.HideFrameskipping := false;
         GameParams.HideHelpers := false;
         GameParams.HideSkillQ := false;
       end;
  end;

  case cbHotkeys.ItemIndex of
    0: GameParams.Hotkeys.SetDefaultsClassic;
    1: GameParams.Hotkeys.SetDefaultsAdvanced;
    2: GameParams.Hotkeys.SetDefaultsAlternative;
  end;

  Close;
end;

end.
