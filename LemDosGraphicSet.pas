{$include lem_directives.inc}
unit LemDosGraphicSet;

// Virtually all the code here has been stripped out, as this related to the
// loading of GROUND / VGAGR format graphic sets.

// The skeleton, and a few basic stuff that may be called via inherited;, are
// retained as TBaseNeoGraphicSet derives from this for compatibility reasons
// with existing code. Eventually, this will be tidied up and this unit (and
// the TBaseDosGraphicSet type) dropped altogether.

interface

uses
  Classes, SysUtils,
  GR32,
  UMisc,
  LemTypes,
  LemMetaObject,
  LemMetaTerrain,
  LemGraphicSet,
  LemDosStructures,
  LemDosBmp,
  LemDosCmp,
  LemDosMisc,
  LemNeoEncryption, Dialogs;

type
  TBaseDosGraphicSet = class(TBaseGraphicSet)
  private
  protected
    fMetaInfoFile    : string; // ground?.dat
    fGraphicFile     : string; // vgagr?.dat
    fGraphicExtFile  : string; // vgaspec?.dat
    fPaletteCustom   : TArrayOfColor32;
    fPaletteStandard : TArrayOfColor32;
    fPalettePreview  : TArrayOfColor32;
    fPalette         : TArrayOfColor32;
    fBrickColor      : TColor32;
    fExtPal          : Byte;
    fAdjTrig         : Boolean;
    fAutoSteel       : Boolean;
    fExtLoc          : Boolean;
    fFullColorVgaspec: Boolean;
    fMultiWin        : Boolean;
    fNeoEncrypt      : TNeoEncryption;
    procedure DoReadMetaData(XmasPal : Boolean = false); override;
    procedure DoReadData; override;
    procedure DoClearMetaData; override;
    procedure DoClearData; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    property PaletteCustom: TArrayOfColor32 read fPaletteCustom;
    property PaletteStandard: TArrayOfColor32 read fPaletteStandard;
    property PalettePreview: TArrayOfColor32 read fPalettePreview;
    property Palette: TArrayOfColor32 read fPalette;
    property BrickColor: TColor32 read fBrickCOlor;
    property AutoSteelEnabled: Boolean read fAutoSteel write fAutoSteel;
    property FullColorVgaspec: Boolean read fFullColorVgaspec write fFullColorVgaspec;
  published
    property MetaInfoFile: string read fMetaInfoFile write fMetaInfoFile;
    property GraphicFile: string read fGraphicFile write fGraphicFile;
    property GraphicExtFile: string read fGraphicExtFile write fGraphicExtFile;
  end;


implementation

{ TBaseDosGraphicSet }

constructor TBaseDosGraphicSet.Create;
begin
  inherited Create;
end;

destructor TBaseDosGraphicSet.Destroy;
begin
  inherited Destroy;
end;

procedure TBaseDosGraphicSet.DoReadMetaData(XmasPal : Boolean = false);
begin
end;

procedure TBaseDosGraphicSet.DoReadData;
begin
end;


procedure TBaseDosGraphicSet.DoClearData;
begin
  inherited DoClearData;
end;

procedure TBaseDosGraphicSet.DoClearMetaData;
begin
  inherited DoClearMetaData;
  fMetaInfoFile    := '';
  fGraphicFile     := '';
  fGraphicExtFile  := '';
  fPaletteCustom   := nil;
  fPaletteStandard := nil;
  fPalettePreview  := nil;
  fPalette         := nil;
  fBrickColor      := 0;
end;

end.

