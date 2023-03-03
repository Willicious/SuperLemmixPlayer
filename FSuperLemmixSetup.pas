unit FSuperLemmixSetup;

interface

uses
  Math,
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
    lblGraphics: TLabel;
    cbGraphics: TComboBox;
    lblUsername: TLabel;
    ebUserName: TEdit;
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

  //case cbHotkey.ItemIndex of
    //0: GameParams.Hotkeys.SetDefaultsClassic;
  //end;

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
  if GameParams.HighResolution then
    GameParams.ZoomLevel := Max(GameParams.ZoomLevel div 2, 1);

  //GameParams.EnableOnline := cbOnline.ItemIndex >= 1;
  //GameParams.CheckUpdates := cbOnline.ItemIndex >= 2;

  Close;
end;

end.
