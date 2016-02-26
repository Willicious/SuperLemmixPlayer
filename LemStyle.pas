{$include lem_directives.inc}

unit LemStyle;

interface

uses
  Classes,
  LemDosStructures,
  LemLevel, LemGraphicSet, LemAnimationSet, LemLevelSystem, LemMusicSystem;


type
  TBaseLemmingStyle = class(TPersistent)
  published
  private
  protected
    fStyleName        : string;
    fStyleDescription : string;
    fCommonPath       : string;
    fAnimationSet     : TBaseAnimationSet;
    fLevelSystem      : TBaseLevelSystem;
    fMusicSystem      : TBaseMusicSystem;
    function DoCreateAnimationSet: TBaseAnimationSet; virtual;
    function DoCreateLevelSystem: TBaseLevelSystem; virtual;
    function DoCreateMusicSystem: TBaseMusicSystem; virtual;
  public
    SysDat : TSysDatRec;
    constructor Create;
    destructor Destroy; override;
    function CreateGraphicSet: TBaseGraphicSet; virtual;
    property AnimationSet: TBaseAnimationSet read fAnimationSet;
    property LevelSystem: TBaseLevelSystem read fLevelSystem;
    property MusicSystem: TBaseMusicSystem read fMusicSystem;
  published
    property StyleName: string read fStyleName write fStyleName;
    property StyleDescription: string read fStyleDescription write fStyleDescription;
    property CommonPath: string read fCommonPath write fCommonPath;
  end;

implementation

{ TBaseLemmingStyle }

constructor TBaseLemmingStyle.Create;
begin
  inherited Create;
  fAnimationSet := DoCreateAnimationSet;
  fLevelSystem := DoCreateLevelSystem;
  fMusicSystem := DoCreateMusicSystem;
end;

function TBaseLemmingStyle.CreateGraphicSet: TBaseGraphicSet;
begin
  Result := nil;
end;

destructor TBaseLemmingStyle.Destroy;
begin
  fAnimationSet.Free;
  fLevelSystem.Free;
  fMusicSystem.Free;
  inherited;
end;

function TBaseLemmingStyle.DoCreateAnimationSet: TBaseAnimationSet;
begin
  Result := nil;
end;

function TBaseLemmingStyle.DoCreateLevelSystem: TBaseLevelSystem;
begin
  Result := nil;
end;

function TBaseLemmingStyle.DoCreateMusicSystem: TBaseMusicSystem;
begin
  Result := nil;
end;

end.



