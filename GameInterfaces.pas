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
    procedure DrawMinimap(Map: TBitmap32);
    procedure SetInfoCursorLemming(const Lem: string; HitCount: Integer);
    procedure SetInfoLemmingsAlive(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemmingsOut(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoLemmingsIn(Num, Max: Integer; Blinking: Boolean = false);
    procedure SetInfoMinutes(Num: Integer; Blinking: Boolean = false);
    procedure SetInfoSeconds(Num: Integer; Blinking: Boolean = false);
    procedure SetReplayMark(Status: Boolean);
    procedure SetTimeLimit(Status: Boolean);
    procedure RefreshInfo;
    procedure ClearSkills;
  end;

implementation

end.

