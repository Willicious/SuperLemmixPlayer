unit LemNeoTheme;

// A simple unit for management of themes. These are basically just the remnants
// of graphic sets onces the terrain and objects are taken out. They define which
// lemming graphics to use, and the key colors.

interface

uses
  Dialogs,
  GR32, LemTypes, LemStrings, PngInterface,
  StrUtils, Classes, SysUtils,
  LemNeoParser;

const
  MASK_COLOR = 'mask';
  MINIMAP_COLOR = 'minimap';
  BACKGROUND_COLOR = 'background';
  FALLBACK_COLOR = MASK_COLOR;

  DEFAULT_COLOR = $FF808080;

type
  TNeoThemeColor = record
    Name: String;
    Color: TColor32;
  end;

  TNeoTheme = class
    private
      fColors: array of TNeoThemeColor;
      fLemmings: String; // Which lemming graphics to use
      fLemNamesPlural: String; // What to call the lemmings in menu screens
      fLemNamesSingular: String;
      function GetColor(Name: String): TColor32;
      function FindColorIndex(Name: String): Integer;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure Load(aSet: String);

      function DoesColorExist(Name: String): Boolean;

      property Lemmings: String read fLemmings write fLemmings;
      property LemNamesPlural: String read fLemNamesPlural write fLemNamesPlural;
      property LemNamesSingular: String read fLemNamesSingular write fLemNamesSingular;
      property Colors[Name: String]: TColor32 read GetColor;
  end;

implementation

constructor TNeoTheme.Create;
begin
  inherited;
  Clear;
end;

destructor TNeoTheme.Destroy;
begin
  inherited;
end;

function TNeoTheme.DoesColorExist(Name: String): Boolean;
begin
  Result := FindColorIndex(Name) >= 0;
end;

procedure TNeoTheme.Clear;
begin
  fLemmings := 'default';
  SetLength(fColors, 0);
end;

procedure TNeoTheme.Load(aSet: String);
var
  Parser: TParser;
  Sec: TParserSection;
  i: Integer;
begin
  Clear;
  SetCurrentDir(AppPath + SFStyles + aSet + '\');
  if not FileExists('theme.nxtm') then Exit;

  Parser := TParser.Create;
  try
    Parser.LoadFromFile('theme.nxtm');

    fLemmings := Parser.MainSection.LineString['lemmings'];
    if fLemmings = '' then fLemmings := 'default';

    fLemNamesPlural := Parser.MainSection.LineString['names_plural'];
    if fLemNamesPlural = '' then fLemNamesPlural := 'Lemmings';

    fLemNamesSingular := Parser.MainSection.LineString['names_singular'];
    if fLemNamesSingular = '' then fLemNamesSingular := 'Lemming';

    Sec := Parser.MainSection.Section['colors'];
    if Sec = nil then
      SetLength(fColors, 0)
    else begin
      SetLength(fColors, Sec.LineList.Count);
      for i := 0 to Sec.LineList.Count-1 do
      begin
        fColors[i].Name := Sec.LineList[i].Keyword;
        fColors[i].Color := Sec.LineList[i].ValueNumeric or $FF000000;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

function TNeoTheme.GetColor(Name: String): TColor32;
var
  i: Integer;
begin
  i := FindColorIndex(Name);

  // Special exception
  if (i = -1) and (Lowercase(Name) = BACKGROUND_COLOR) then
  begin
    Result := $FF000000;
    Exit;
  end;

  if i = -1 then i := FindColorIndex(FALLBACK_COLOR);

  if i = -1 then
    Result := DEFAULT_COLOR
  else
    Result := fColors[i].Color;
end;

function TNeoTheme.FindColorIndex(Name: String): Integer;
begin
  Name := Lowercase(Name);
  for Result := 0 to Length(fColors)-1 do
    if Name = fColors[Result].Name then Exit;
  Result := -1;
end;

end.