unit LemRecolorSprites;

interface

uses
  Dialogs,
  Classes, SysUtils,
  LemNeoParser,
  LemNeoTheme,
  LemLemming, LemTypes, LemStrings, LemPalette,
  GR32, GR32_Blend,
  SharedGlobals;

var
  PhysicsViewLemmingNormal: TColor32;
  PhysicsViewLemmingRival: TColor32;
  PhysicsViewLemmingAthleteNormal: TColor32;
  PhysicsViewLemmingAthleteRival: TColor32;
  PhysicsViewLemmingNeutral: TColor32;
  PhysicsViewLemmingZombie: TColor32;
  PhysicsViewLemmingInvincible: TColor32;
  PhysicsViewLemmingSelected: TColor32;

type
  TColorSwapType = (rcl_Selected,
                    rcl_Swimmer,
                    rcl_Athlete,
                    rcl_Zombie,
                    rcl_Neutral,
                    rcl_Rival,
                    rcl_Rival_Selected,
                    rcl_Rival_Athlete,
                    rcl_Invincible);

  TColorSwap = record
    Condition: TColorSwapType;
    SrcColor: TColor32;
    DstColor: TColor32;
  end;

  // Remember - highlight needs to be hardcoded

  TColorSwapArray = array of TColorSwap;
  TSwapProgressArray = array[Low(TColorSwapType)..High(TColorSwapType)] of Boolean;

  TRecolorImage = class
    private
      fLemming: TLemming;
      fDrawAsSelected: Boolean;
      fApplyPhysicsViewColors: Boolean;
      fSwaps: TColorSwapArray;

      procedure SwapColors(F: TColor32; var B: TColor32);
      procedure RegisterSwap(aSec: TParserSection; const aIteration: Integer; aData: Pointer);
      procedure AddSwap(aType: TColorSwapType; aSrc, aDst: TColor32);
    public
      constructor Create;

      procedure LoadSwaps(aName: String);
      procedure ApplyPaletteSwapping(aColorDict: TColorDict; aShadeDict: TShadeDict; aTheme: TNeoTheme);
      procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: Cardinal);
      procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: Cardinal);
      procedure LoadPhysicsViewShades;

      property Lemming: TLemming write fLemming;
      property DrawAsSelected: Boolean write fDrawAsSelected;
      property ApplyPhysicsViewColors: Boolean read fApplyPhysicsViewColors write fApplyPhysicsViewColors;

      class procedure CombineDefaultPixels(F: TColor32; var B: TColor32; M: Cardinal);
  end;

implementation

uses
  GameControl;

constructor TRecolorImage.Create;
begin
  inherited;

  LoadSwaps(SFDefaultStyle);
  LoadPhysicsViewShades;
end;

procedure TRecolorImage.SwapColors(F: TColor32; var B: TColor32);
var
  i: Integer;
begin
  B := F;

  if fLemming = nil then Exit;
  if (F and $FF000000) = 0 then Exit;

  if ApplyPhysicsViewColors then
  begin
    if fLemming.HasPermanentSkills then
    begin
      if fLemming.LemIsRival then
        B := ResolveColor(PhysicsViewLemmingAthleteRival)
      else
        B := ResolveColor(PhysicsViewLemmingAthleteNormal);
    end else begin
      if fLemming.LemIsRival then
        B := ResolveColor(PhysicsViewLemmingRival)
      else
        B := ResolveColor(PhysicsViewLemmingNormal);
    end;

    if fLemming.LemIsInvincible then
      B := ResolveColor(PhysicsViewLemmingInvincible);

    if fLemming.LemIsNeutral then
      B := ResolveColor(PhysicsViewLemmingNeutral);

    if fLemming.LemIsZombie then
      B := ResolveColor(PhysicsViewLemmingZombie);

    if fDrawAsSelected then
      B := ResolveColor(PhysicsViewLemmingSelected);
  end
  else
  begin
    for i := 0 to Length(fSwaps) - 1 do
    begin
      case fSwaps[i].Condition of
        rcl_Selected:
        begin
          // Don't apply regular Selected recoloring to Rivals
          if fLemming.LemIsRival then Continue;
          // Don't apply Selected recoloring in Classic Mode
          if GameParams.ClassicMode or not fDrawAsSelected then Continue;
        end;
        rcl_Swimmer:
        begin
          // Don't apply Swimmer recoloring to Rivals
          if fLemming.LemIsRival then Continue;
          if not fLemming.LemIsSwimmer then Continue;
        end;
        rcl_Athlete:
        begin
          // Don't apply regular Athlete recoloring to Rivals
          if fLemming.LemIsRival then Continue;
          if not fLemming.HasPermanentSkills then Continue;
        end;
        rcl_Zombie: if not fLemming.LemIsZombie then Continue;
        rcl_Neutral: if not fLemming.LemIsNeutral then Continue;
        rcl_Rival: if not fLemming.LemIsRival then Continue;
        rcl_Rival_Athlete: if not (fLemming.LemIsRival and fLemming.HasPermanentSkills) then Continue;
        rcl_Rival_Selected: if not (fLemming.LemIsRival and fDrawAsSelected) then Continue;
        rcl_Invincible: if not fLemming.LemIsInvincible then Continue;
        else raise Exception.Create('TRecolorImage.SwapColors encountered an unknown condition' + #13 + IntToStr(Integer(fSwaps[i].Condition)));
      end;
      if (F and $FFFFFF) = fSwaps[i].SrcColor then
        B := fSwaps[i].DstColor;
    end;
  end;
end;

procedure TRecolorImage.CombineLemmingPixels(F: TColor32; var B: TColor32; M: Cardinal);
var
  A: TColor32;
  TempColor: TColor32;
begin
  A := (F and $FF000000);
  if A = 0 then Exit;
  SwapColors(F, TempColor);
  TempColor := (TempColor and $FFFFFF) or A;
  MergeMem(TempColor, B);
end;

procedure TRecolorImage.CombineLemmingHighlight(F: TColor32; var B: TColor32; M: Cardinal);
begin
  // Photoflash
  if F <> 0 then B := clBlack32 else B := clWhite32;
end;

procedure TRecolorImage.RegisterSwap(aSec: TParserSection; const aIteration: Integer; aData: Pointer);
var
  Mode: ^TColorSwapType absolute aData;
begin
  AddSwap(Mode^, aSec.LineNumeric['from'], aSec.LineNumeric['to']);
end;

procedure TRecolorImage.LoadSwaps(aName: String);
var
  Parser: TParser;
  Mode: TColorSwapType;
begin
  SetLength(fSwaps, 0);
  Parser := TParser.Create;
  try
    if not FileExists(AppPath + SFStyles + aName + SFPiecesLemmings + 'scheme.nxmi') then
      aName := SFDefaultStyle;

    if FileExists(AppPath + SFStyles + aName + SFPiecesLemmings + 'scheme.nxmi') then
    begin
      Parser.LoadFromFile(AppPath + SFStyles + aName + SFPiecesLemmings + 'scheme.nxmi');

      if (Parser.MainSection.Section['state_recoloring'] <> nil) then
      begin
        Mode := rcl_Athlete;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('athlete', RegisterSwap, @Mode);

        Mode := rcl_Athlete;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('swimmer', RegisterSwap, @Mode);

        Mode := rcl_Invincible;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('invincible', RegisterSwap, @Mode);

        Mode := rcl_Neutral;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('neutral', RegisterSwap, @Mode);

        Mode := rcl_Rival;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('rival', RegisterSwap, @Mode);

        Mode := rcl_Rival_Athlete;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('rival_athlete', RegisterSwap, @Mode);

        Mode := rcl_Rival_Selected;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('rival_selected', RegisterSwap, @Mode);

        Mode := rcl_Zombie;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('zombie', RegisterSwap, @Mode);

        Mode := rcl_Selected;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('selected', RegisterSwap, @Mode);
      end;
    end;
  finally
    Parser.Free;
  end;
end;

procedure TRecolorImage.AddSwap(aType: TColorSwapType; aSrc, aDst: TColor32);
var
  i: Integer;
begin
  i := Length(fSwaps);
  SetLength(fSwaps, i+1);
  fSwaps[i].Condition := aType;
  fSwaps[i].SrcColor := aSrc;
  fSwaps[i].DstColor := aDst;
end;

procedure TRecolorImage.ApplyPaletteSwapping(aColorDict: TColorDict;
  aShadeDict: TShadeDict; aTheme: TNeoTheme);
var
  i, n: Integer;
  OrigSrc: TColor32;
  Pair: TColor32Pair;

  procedure MoveLastTo(aIndex: Integer);
  var
    TempSwap: TColorSwap;
    i: Integer;
  begin
    TempSwap := fSwaps[Length(fSwaps)-1];
    for i := Length(fSwaps)-1 downto aIndex+1 do
      fSwaps[i] := fSwaps[i-1];
    fSwaps[aIndex] := TempSwap;
  end;
begin
  i := 0;
  while i < Length(fSwaps) do
  begin
    OrigSrc := fSwaps[i].SrcColor;

    if aColorDict.ContainsKey(fSwaps[i].SrcColor) then
      if aTheme.DoesColorExist(aColorDict[fSwaps[i].SrcColor]) then
        fSwaps[i].SrcColor := aTheme.Colors[aColorDict[fSwaps[i].SrcColor]] and $FFFFFF;

    if aColorDict.ContainsKey(fSwaps[i].DstColor) then
      if aTheme.DoesColorExist(aColorDict[fSwaps[i].DstColor]) then
        fSwaps[i].DstColor := aTheme.Colors[aColorDict[fSwaps[i].DstColor]] and $FFFFFF;

    n := i;
    Inc(i);

    for Pair in aShadeDict do
      if (Pair.Value and $FFFFFF) = (OrigSrc and $FFFFFF) then
      begin
        AddSwap(fSwaps[n].Condition,
                ApplyColorShift(fSwaps[n].SrcColor, Pair.Value, Pair.Key),
                ApplyColorShift(fSwaps[n].DstColor, Pair.Value, Pair.Key));
        MoveLastTo(i);
        Inc(i);
      end;
  end;
end;

procedure TRecolorImage.LoadPhysicsViewShades;
var
  Nxmi: String;
  Parser: TParser;
  Sec: TParserSection;

  // Default colors, loaded if custom file doesn't exist
  procedure ResetColors;
  begin
    PhysicsViewLemmingNormal := $FF7777FF;
    PhysicsViewLemmingRival := $FFFF0077;
    PhysicsViewLemmingAthleteNormal := $FF00FFFF;
    PhysicsViewLemmingAthleteRival := $FFFF99FF;
    PhysicsViewLemmingNeutral := $FFAA00FF;
    PhysicsViewLemmingZombie := $FF777744;
    PhysicsViewLemmingInvincible := $FFFFFFFF;
    PhysicsViewLemmingSelected := $FFFFFF77;
  end;

begin
  ResetColors;

  Parser := TParser.Create;
  try
    Nxmi := 'SLXPhysicsViewColors.nxmi';

    if not FileExists(AppPath + SFSaveData + Nxmi) then
    begin
      with TStringList.Create do
      try
        Text := DEFAULT_PHYSICS_VIEW_COLORS;
        SaveToFile(AppPath + SFSaveData + Nxmi);
      finally
        Free;
      end;
    end;

    Parser.LoadFromFile(AppPath + SFSaveData + Nxmi);

    Sec := Parser.MainSection.Section['lemmings'];
    if Sec = nil then Exit;

    PhysicsViewLemmingNormal := ParseColor32(Sec, 'normal', $FF7777FF);
    PhysicsViewLemmingRival := ParseColor32(Sec, 'rival', $FFFF0077);
    PhysicsViewLemmingAthleteNormal := ParseColor32(Sec, 'athlete_normal', $FF00FFFF);
    PhysicsViewLemmingAthleteRival := ParseColor32(Sec, 'athlete_rival', $FFFF99FF);
    PhysicsViewLemmingNeutral := ParseColor32(Sec, 'neutral', $FFAA00FF);
    PhysicsViewLemmingZombie := ParseColor32(Sec, 'zombie', $FF777744);
    PhysicsViewLemmingInvincible := ParseColor32(Sec, 'invincible', $FFFFFFFF);
    PhysicsViewLemmingSelected := ParseColor32(Sec, 'selected', $FFFFFF77);
  finally
    Parser.Free;
  end;
end;

class procedure TRecolorImage.CombineDefaultPixels(F: TColor32; var B: TColor32; M: Cardinal);
begin
  if F <> 0 then B := F;
end;

end.
 