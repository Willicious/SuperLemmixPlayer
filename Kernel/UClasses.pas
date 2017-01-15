unit UClasses;

interface

uses
  Classes;

type
  TOwnedPersistent = class(TPersistent)
  private
    fOwner: TPersistent;
  protected
  public
    constructor Create(aOwner: TPersistent);
    property Owner: TPersistent read fOwner;
  end;

implementation

{ TOwnedPersistent }

constructor TOwnedPersistent.Create(aOwner: TPersistent);
begin
  fOwner := aOwner;
end;



end.

