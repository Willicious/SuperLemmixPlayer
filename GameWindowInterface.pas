{$include lem_directives.inc}

unit GameWindowInterface;

interface

uses
  GR32_Image,
  SharedGlobals;

type

  TGameSpeed = (
    gspNormal,
    gspPause,
    gspRewind,
    gspFF,
    gspTurbo,
    gspSlowMo
  );

  IGameWindow = Interface(IInterface)
    function ScreenImage: TImage32; 

    function GetDisplayWidth: Integer;
    function GetDisplayHeight: Integer;
    property DisplayWidth: Integer read GetDisplayWidth;
    property DisplayHeight: Integer read GetDisplayHeight;

    procedure SetForceUpdateOneFrame(aValue: Boolean);
    procedure SetHyperSpeedTarget(aValue: Integer);

    procedure SaveReplay;
    procedure GotoSaveState(aTargetIteration: Integer; PauseAfterSkip: Integer = 0; aForceBeforeIteration: Integer = -1);

    procedure ApplyMouseTrap;
    procedure SetCurrentCursor(aCursor: Integer = 0);
    function DoSuspendCursor: Boolean;

    function GetIsHyperSpeed: Boolean;
    property IsHyperSpeed: Boolean read GetIsHyperSpeed;

    procedure SetGameSpeed(aValue: TGameSpeed);
    function GetGameSpeed: TGameSpeed;
    property GameSpeed: TGameSpeed read GetGameSpeed write SetGameSpeed;

    procedure SetClearPhysics(aValue: Boolean);
    function GetClearPhysics: Boolean;
    property ClearPhysics: Boolean read GetClearPhysics write SetClearPhysics;
//    function GetInternalZoom: Integer;
//    property InternalZoom: Integer read GetInternalZoom;
  end;

implementation

end.
 