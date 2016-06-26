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

const
  MASK_COLOR = 'mask';
  MINIMAP_COLOR = 'minimap';
  BACKGROUND_COLOR = 'background';
  FALLBACK_COLOR = MASK_COLOR;

type
  TNeoThemeColor = record
    Name: String;
    Color: TColor32;
  end;

  TNeoTheme = class
    private
      fColors: array of TNeoThemeColor;
      fLemmings: String;          // Which lemming graphics to use
      //fMaskColor: TColor32;       // Used for masking on the skill panel, lemming sprites, and bridges
      //fMapColor: TColor32;        // Used for the minimap
      //fBackgroundColor: TColor32; // Used for the background
      function GetColor(Name: String): TColor32;
      function FindColorIndex(Name: String): Integer;
    public
      constructor Create;
      procedure Clear;
      procedure Load(aSet: String);

      property Lemmings: String read fLemmings write fLemmings;
      property Colors[Name: String]: TColor32 read GetColor;
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
  SetLength(fColors, 0);
end;

procedure TNeoTheme.Load(aSet: String);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  i: Integer;
  RealColorCount: Integer;
  TempColor: TNeoThemeColor;

  procedure ExpandArray;
  begin
    if Length(fColors) <= RealColorCount then
      SetLength(fColors, RealColorCount+50);
  end;

  procedure TrimArray;
  begin
    SetLength(fColors, RealColorCount);
  end;

  procedure AddColor(aColor: TNeoThemeColor);
  begin
    ExpandArray;
    fColors[RealColorCount] := aColor;
    Inc(RealColorCount);
  end;
begin
  Clear;
  SetCurrentDir(AppPath + SFStylesThemes);
  if not FileExists(aSet + '.nxtm') then Exit;

  Parser := TNeoLemmixParser.Create;
  try
    Parser.LoadFromFile(aSet + '.nxtm');
    repeat
      Line := Parser.NextLine;

      if Line.Keyword = 'LEMMINGS' then
        fLemmings := Line.Value;

    until (Line.Keyword = '') or (Line.Keyword = 'COLORS');

    RealColorCount := 0;
    SetLength(fColors, 0);
    repeat
      Line := Parser.NextLine;

      TempColor.Name := Line.Keyword;
      TempColor.Color := StrToIntDef('x' + Line.Value, $808080) or $FF000000;
      AddColor(TempColor);
    until Line.Keyword = '';

    TrimArray;
  finally
    Parser.Free;
  end;
end;

function TNeoTheme.GetColor(Name: String): TColor32;
var
  i: Integer;
begin
  i := FindColorIndex(Name);
  if i = -1 then i := FindColorIndex(FALLBACK_COLOR);

  if i = -1 then
    Result := $FF808080
  else
    Result := fColors[i].Color;

  // Special exception
  if (i = -1) and (Lowercase(Name) = BACKGROUND_COLOR) then
    Result := $FF000000;
end;

function TNeoTheme.FindColorIndex(Name: String): Integer;
begin
  Name := Uppercase(Name);
  for Result := 0 to Length(fColors)-1 do
    if Name = fColors[Result].Name then Exit;
  Result := -1;
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