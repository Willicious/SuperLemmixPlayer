unit UClasses;

interface

uses
  Classes;

type
  TOwnedPersistent = class(TPersistent)
  private
    fOwner: TPersistent;
  protected
    function GetOwner: TPersistent; override;
    function FindOwner(aClass: TClass): TPersistent;
    function GetMaster: TPersistent;
  public
    constructor Create(aOwner: TPersistent);
    property Owner: TPersistent read fOwner;
  end;

implementation

uses
  UMisc;

{ TOwnedPersistent }

constructor TOwnedPersistent.Create(aOwner: TPersistent);
begin
  fOwner := aOwner;
end;

function TOwnedPersistent.GetOwner: TPersistent;
begin
  Result := fOwner;
end;

type
  THackedPersistent = class(TPersistent);

function TOwnedPersistent.FindOwner(aClass: TClass): TPersistent;
var
  O: TPersistent;
begin
  O := Self;
  Result := nil;
  while O <> nil do
  begin
    O := THackedPersistent(O).GetOwner;
    if O = nil then
      Exit;
    if O is aClass then
    begin
      Result := O;
      Exit;
    end;
  end;
end;

function TOwnedPersistent.GetMaster: TPersistent;
var
  O: TPersistent;
begin
  Result := nil;
  O := Self;
  while O <> nil do
  begin
    O := THackedPersistent(O).GetOwner;
    if O <> nil then
      Result := O
    else
      Exit;
  end;
  Result := nil;
end;


end.

