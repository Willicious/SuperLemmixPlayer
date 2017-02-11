{$include lem_directives.inc}

unit GameInterfaces;

{-------------------------------------------------------------------------------
  Unit with shared interfaces between game and it's controls
-------------------------------------------------------------------------------}

interface

uses
  GR32,
  LemCore;

type
  // drawing of info and toolbarbuttons
  IGameToolbar = interface
    procedure DrawSkillCount(aButton: TSkillPanelButton; aNumber: Integer);
    procedure DrawButtonSelector(aButton: TSkillPanelButton; SelectorOn: Boolean);
    procedure DrawMinimap;
    procedure SetInfoCursorLemming(const Lem: string; HitCount: Integer);
    procedure SetInfoLemHatch(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemAlive(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemIn(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
    procedure SetReplayMark(Status: Integer);
    procedure SetTimeLimit(Status: Boolean);
    procedure RefreshInfo;
    procedure ClearSkills;
  end;

implementation

end.

