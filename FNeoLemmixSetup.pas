unit FNeoLemmixSetup;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TFNLSetup = class(TForm)
    SetupPages: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btnNext: TButton;
    btnBack: TButton;
    rbConfigDefault: TRadioButton;
    rbConfigDefaultLix: TRadioButton;
    rbConfigCustom: TRadioButton;
    rbConfigCustomLix: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure rbConfigDefaultClick(Sender: TObject);
  private
    procedure SetClassicHotkeys;
    procedure SetLixHotkeys;
  public
    { Public declarations }
  end;

implementation

uses
  GameControl, LemmixHotkeys;

{$R *.dfm}

{ Misc Functions }

procedure TFNLSetup.FormCreate(Sender: TObject);
begin
  SetupPages.TabIndex := 0;
end;

procedure TFNLSetup.SetClassicHotkeys;
begin
  with GameParams.Hotkeys do
  begin
    ClearAllKeys;

    // Here's the simple ones that don't need further settings.
    SetKeyFunction($02, lka_Highlight);
    SetKeyFunction($04, lka_Pause);
    SetKeyFunction($05, lka_ZoomIn);
    SetKeyFunction($06, lka_ZoomOut);
    SetKeyFunction($08, lka_LoadState);
    SetKeyFunction($0D, lka_SaveState);
    SetKeyFunction($10, lka_SelectNewLem);
    SetKeyFunction($11, lka_ForceWalker);
    SetKeyFunction($12, lka_ShowAthleteInfo);
    SetKeyFunction($19, lka_ForceWalker);
    SetKeyFunction($1B, lka_Exit);
    SetKeyFunction($25, lka_DirLeft);
    SetKeyFunction($27, lka_DirRight);
    SetKeyFunction($31, lka_Cheat);
    SetKeyFunction($43, lka_CancelReplay);
    SetKeyFunction($44, lka_FallDistance);
    SetKeyFunction($45, lka_EditReplay);
    SetKeyFunction($46, lka_FastForward);
    SetKeyFunction($49, lka_SaveImage);
    SetKeyFunction($4C, lka_LoadReplay);
    SetKeyFunction($4D, lka_Music);
    SetKeyFunction($50, lka_Pause);
    SetKeyFunction($52, lka_Restart);
    SetKeyFunction($53, lka_Sound);
    SetKeyFunction($55, lka_SaveReplay);
    SetKeyFunction($57, lka_ReplayInsert);
    SetKeyFunction($58, lka_SkillRight);
    SetKeyFunction($5A, lka_SkillLeft);
    SetKeyFunction($70, lka_ReleaseRateDown);
    SetKeyFunction($71, lka_ReleaseRateUp);
    SetKeyFunction($7A, lka_Pause);
    SetKeyFunction($7B, lka_Nuke);
    SetKeyFunction($C0, lka_ReleaseMouse);

    // Misc ones that need other details set
    SetKeyFunction($54, lka_ClearPhysics, 1);

    // Here's the frameskip ones; these need a number of *frames* to skip (forwards or backwards), or other extra details.
    SetKeyFunction($20, lka_Skip, 17 * 10);
    SetKeyFunction($42, lka_Skip, -1);
    SetKeyFunction($4E, lka_Skip, 1);
    SetKeyFunction($6D, lka_Skip, -17);
    SetKeyFunction($BC, lka_Skip, -17 * 5);
    SetKeyFunction($BD, lka_Skip, -17);
    SetKeyFunction($BE, lka_Skip, 17 * 5);
    SetKeyFunction($DB, lka_SpecialSkip, 0);
    SetKeyFunction($DD, lka_SpecialSkip, 1);

    // And here's the skill ones; these ones need the skill specified seperately
    SetKeyFunction($32, lka_Skill, 0);
    SetKeyFunction($33, lka_Skill, 2);
    SetKeyFunction($34, lka_Skill, 4);
    SetKeyFunction($35, lka_Skill, 5);
    SetKeyFunction($36, lka_Skill, 7);
    SetKeyFunction($37, lka_Skill, 9);
    SetKeyFunction($38, lka_Skill, 11);
    SetKeyFunction($39, lka_Skill, 13);
    SetKeyFunction($30, lka_Skill, 16);
    SetKeyFunction($72, lka_Skill, 1);
    SetKeyFunction($73, lka_Skill, 3);
    SetKeyFunction($74, lka_Skill, 6);
    SetKeyFunction($75, lka_Skill, 8);
    SetKeyFunction($76, lka_Skill, 10);
    SetKeyFunction($77, lka_Skill, 12);
    SetKeyFunction($78, lka_Skill, 14);
    SetKeyFunction($79, lka_Skill, 15);
  end;
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
    SetKeyFunction($7B, lka_Nuke);
    SetKeyFunction($02, lka_ForceWalker);
    SetKeyFunction($75, lka_SaveReplay);
    SetKeyFunction($76, lka_LoadReplay);
    SetKeyFunction($C0, lka_ReleaseMouse);
    SetKeyFunction($11, lka_Highlight);
    SetKeyFunction($12, lka_ShowAthleteInfo);
    SetKeyFunction($4D, lka_Music);
    SetKeyFunction($4E, lka_Sound);
    SetKeyFunction($BC, lka_SkillRight);
    SetKeyFunction($BE, lka_SkillLeft);
    SetKeyFunction($73, lka_ReleaseRateDown);
    SetKeyFunction($74, lka_ReleaseRateUp);
    SetKeyFunction($49, lka_FallDistance);
    SetKeyFunction($50, lka_EditReplay);
    SetKeyFunction($4F, lka_ReplayInsert);
    SetKeyFunction($55, lka_SelectNewLem);
    SetKeyFunction($0D, lka_SaveImage);

    // Misc ones that need other details set
    SetKeyFunction($BF, lka_ClearPhysics, 1);

    // Skips
    SetKeyFunction($31, lka_Skip, -17);
    SetKeyFunction($32, lka_Skip, -1);
    SetKeyFunction($33, lka_Skip, 1);
    SetKeyFunction($36, lka_Skip, 170);
    SetKeyFunction($37, lka_SpecialSkip, 0);
    SetKeyFunction($38, lka_SpecialSkip, 1);

    // Skills
    SetKeyFunction($44, lka_Skill, 0);  // walker, D
    SetKeyFunction($5A, lka_Skill, 1);  // climber, Z
    SetKeyFunction($10, lka_Skill, 2);  // swimmer, shift
    SetKeyFunction($51, lka_Skill, 3);  // floater, Q
    SetKeyFunction($09, lka_Skill, 4);  // glider, tab
    SetKeyFunction($52, lka_Skill, 5);  // disarmer, R
    SetKeyFunction($56, lka_Skill, 6);  // bomber, V
    SetKeyFunction($42, lka_Skill, 7);  // stoner, B
    SetKeyFunction($58, lka_Skill, 8);  // blocker, X
    SetKeyFunction($54, lka_Skill, 9);  // platformer, T
    SetKeyFunction($41, lka_Skill, 10); // builder, A
    SetKeyFunction($59, lka_Skill, 11); // stacker, Y
    SetKeyFunction($45, lka_Skill, 12); // basher, E
    SetKeyFunction($43, lka_Skill, 13); // fencer, C
    SetKeyFunction($47, lka_Skill, 14); // miner, G
    SetKeyFunction($57, lka_Skill, 15); // digger, W
    SetKeyFunction($48, lka_Skill, 16); // cloner, H
  end;
end;

{ Page Control }

procedure TFNLSetup.btnBackClick(Sender: TObject);
begin
  SetupPages.TabIndex := SetupPages.TabIndex - 1;
  if SetupPages.ActivePageIndex = 0 then btnBack.Enabled := false;
end;

procedure TFNLSetup.btnNextClick(Sender: TObject);
begin
  btnBack.Enabled := true;
  if SetupPages.ActivePageIndex = SetupPages.PageCount-1 then
    Close
  else
    SetupPages.ActivePageIndex := SetupPages.ActivePageIndex + 1;
end;

procedure TFNLSetup.rbConfigDefaultClick(Sender: TObject);
begin
  case TComponent(Sender).Tag of
    0, 2: SetClassicHotkeys;
    1, 3: SetLixHotkeys;
  end;
end;

end.
