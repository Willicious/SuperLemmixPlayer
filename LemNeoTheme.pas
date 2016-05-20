unit LemNeoTheme;

// A simple unit for management of themes. These are basically just the remnants
// of graphic sets onces the terrain and objects are taken out. They define which
// lemming graphics to use, and the key colors.

interface

uses
  Dialogs,
  LemNeoParser,
  GR32, LemTypes, LemStrings,
  StrUtils, Classes, SysUtils;

type
  TNeoTheme = class
    private
      fLemmings: String;          // Which lemming graphics to use
      fMaskColor: TColor32;       // Used for masking on the skill panel, lemming sprites, and bridges
      fMapColor: TColor32;        // Used for the minimap
      fBackgroundColor: TColor32; // Used for the background
      fParticleColors: array of TColor32;

      function GetParticleColor(Index: Integer): TColor32;
      procedure SetParticleColor(Index: Integer; aColor: TColor32);
    public
      constructor Create;
      procedure Clear;
      procedure Load(aSet: String);

      property Lemmings: String read fLemmings write fLemmings;
      property MaskColor: TColor32 read fMaskColor write fMaskColor;
      property MapColor: TColor32 read fMapColor write fMapColor;
      property BackgroundColor: TColor32 read fBackgroundColor write fBackgroundColor;
      property ParticleColors[Index: Integer]: TColor32 read GetParticleColor write SetParticleColor;
  end;

implementation

constructor TNeoTheme.Create;
begin
  inherited;
  Clear;
end;

procedure TNeoTheme.Clear;
begin
  fLemmings := 'lemming';
  fMaskColor := $FF7F7F7F;
  fMapColor := $FF7F7F7F;
  fBackgroundColor := $FF000000;
  SetLength(fParticleColors, 0);
end;

function TNeoTheme.GetParticleColor(Index: Integer): TColor32;
begin
  if Length(fParticleColors) = 0 then
    Result := $FF7F7F7F
  else
    Result := fParticleColors[Index mod Length(fParticleColors)];
end;

procedure TNeoTheme.SetParticleColor(Index: Integer; aColor: TColor32);
begin
  if Length(fParticleColors) < (Index + 1) then
    SetLength(fParticleColors, Index + 1);
  fParticleColors[Index] := aColor;
end;

procedure TNeoTheme.Load(aSet: String);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  i: Integer;
begin
  Clear;
  SetCurrentDir(AppPath + SFStyles + '\' + aSet + '\');
  if not FileExists('theme.nxtm') then Exit;

  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromFile('theme.nxtm');
    repeat
      Line := Parser.NextLine;

      if Line.Keyword = 'LEMMINGS' then
        fLemmings := Line.Value;

      if Line.Keyword = 'COLOR_MASK' then
        fMaskColor := StrToIntDef('x' + Line.Value, $FF7F7F7F);

      if Line.Keyword = 'COLOR_MAP' then
        fMapColor := StrToIntDef('x' + Line.Value, $FF7F7F7F);

      if Line.Keyword = 'COLOR_BG' then
        fBackgroundColor := StrToIntDef('x' + Line.Value, $FF000000);

      if LeftStr(Line.Keyword, 16) = 'COLOR_PARTICLES_' then
      begin
        i := StrToIntDef(MidStr(Line.Keyword, 17, Length(Line.Keyword)), 0);
        ParticleColors[i] := StrToIntDef('x' + Line.Value, $FF000000);
      end;
      
    until Line.Keyword = '';
  finally
    Parser.Free;
  end;
end;

{LEMMINGS lemming
COLOR_MASK FFD08020
COLOR_MAP FFD08020
COLOR_BG 000000
COLOR_PARTICLES_0 FFD08020
COLOR_PARTICLES_1 FFC05010
COLOR_PARTICLES_2 FF902010
COLOR_PARTICLES_3 FF600010
COLOR_PARTICLES_4 FF404050
COLOR_PARTICLES_5 FF606070
COLOR_PARTICLES_6 FF709000
COLOR_PARTICLES_7 FF206020}

end.