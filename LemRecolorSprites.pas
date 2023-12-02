unit LemRecolorSprites;

interface

uses
  Dialogs,
  Classes, SysUtils,
  LemNeoParser,
  LemNeoTheme,
  LemLemming, LemTypes, LemStrings,
  GR32, GR32_Blend;

const
  CPM_LEMMING_NORMAL = $FF0000FF;    // Used for a non-athlete
  CPM_LEMMING_ATHLETE = $FF00FFFF;   // Used for an athlete
  CPM_LEMMING_SELECTED = $007F0000;  // OR'd to base value for selected lemming
  CPM_LEMMING_ZOMBIE_OR = $00007F00; // OR'd to base value for zombies
  CPM_LEMMING_ZOMBIE_NOT = $000000C0;// AND-NOT'd to base value for zombies
  CPM_LEMMING_NEUTRAL = $00FFFFFF;   // XOR'd to base value for neutrals

type
  TColorSwapType = (rcl_Selected,
                    rcl_Athlete,
                    rcl_Zombie,
                    rcl_Neutral);

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
      fClearPhysics: Boolean;
      fSwaps: TColorSwapArray;

      procedure SwapColors(F: TColor32; var B: TColor32);
      procedure RegisterSwap(aSec: TParserSection; const aIteration: Integer; aData: Pointer);
      procedure AddSwap(aType: TColorSwapType; aSrc, aDst: TColor32);
    public
      constructor Create;

      procedure LoadSwaps(aName: String);
      procedure ApplyPaletteSwapping(aColorDict: TColorDict; aShadeDict: TShadeDict; aTheme: TNeoTheme);
      procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);

      property Lemming: TLemming write fLemming;
      property DrawAsSelected: Boolean write fDrawAsSelected;
      property ClearPhysics: Boolean write fClearPhysics;

      class procedure CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
  end;

implementation

uses
  GameControl;

constructor TRecolorImage.Create;
begin
  inherited;

  // Until proper loading exists
  LoadSwaps('default');
end;

procedure TRecolorImage.SwapColors(F: TColor32; var B: TColor32);
var
  i: Integer;
begin
  B := F;

  if fLemming = nil then Exit;
  if (F and $FF000000) = 0 then Exit;

  if fClearPhysics then
  begin
    if fLemming.HasPermanentSkills then
      B := CPM_LEMMING_ATHLETE
    else
      B := CPM_LEMMING_NORMAL;

    if fDrawAsSelected then
      B := B or CPM_LEMMING_SELECTED;

    if fLemming.LemIsNeutral then
      B := B xor CPM_LEMMING_NEUTRAL;

    if fLemming.LemIsZombie then
      B := (B or CPM_LEMMING_ZOMBIE_OR) and not CPM_LEMMING_ZOMBIE_NOT;
  end else
    for i := 0 to Length(fSwaps)-1 do
    begin
      case fSwaps[i].Condition of
        rcl_Selected: if not fDrawAsSelected then Continue;
        rcl_Zombie: if not fLemming.LemIsZombie then Continue;
        rcl_Athlete: if not fLemming.HasPermanentSkills then Continue;
        rcl_Neutral: if not fLemming.LemIsNeutral then Continue;
        else raise Exception.Create('TRecolorImage.SwapColors encountered an unknown condition' + #13 + IntToStr(Integer(fSwaps[i].Condition)));
      end;
      if (F and $FFFFFF) = fSwaps[i].SrcColor then B := fSwaps[i].DstColor;
    end;
end;

procedure TRecolorImage.CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
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

procedure TRecolorImage.CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
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
      aName := 'default';

    if FileExists(AppPath + SFStyles + aName + SFPiecesLemmings + 'scheme.nxmi') then
    begin
      Parser.LoadFromFile(AppPath + SFStyles + aName + SFPiecesLemmings + 'scheme.nxmi');

      if (Parser.MainSection.Section['state_recoloring'] <> nil) then
      begin
        Mode := rcl_Athlete;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('athlete', RegisterSwap, @Mode);

        Mode := rcl_Neutral;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('neutral', RegisterSwap, @Mode);

        Mode := rcl_Zombie;
        Parser.MainSection.Section['state_recoloring'].DoForEachSection('zombie', RegisterSwap, @Mode);

        // Selected lems are not highlighted in ClassicMode
        Mode := rcl_Selected;
        if not GameParams.ClassicMode then
        begin
          Parser.MainSection.Section['state_recoloring'].DoForEachSection('selected', RegisterSwap, @Mode);
        end;
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

class procedure TRecolorImage.CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
end;

end.
 