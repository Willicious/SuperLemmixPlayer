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
    procedure SetReplayMark(Status: Integer);
    procedure RefreshInfo;
    procedure ClearSkills;
  end;

implementation

end.

