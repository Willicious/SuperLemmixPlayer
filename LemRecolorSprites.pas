unit LemRecolorSprites;

interface

uses
  Dialogs,
  Classes, SysUtils,
  LemNeoParser,
  LemDosStructures, LemLemming, LemTypes, LemStrings,
  GR32, GR32_Blend;

const
  CPM_LEMMING_NORMAL = $FF0000FF;  // used for a non-athlete
  CPM_LEMMING_ATHLETE = $FF00FFFF; // used for an athlete
  CPM_LEMMING_SELECTED = $007F0000; // OR'd to base value for selected lemming
  CPM_LEMMING_ZOMBIE = $00808080; // AND-NOT'd to base value for zombies

type
  TColorSwapType = (rcl_Selected,
                    rcl_Athlete,
                    rcl_Zombie);

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

    public
      constructor Create;

      procedure LoadSwaps(aName: String);
      procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);

      property Lemming: TLemming write fLemming;
      property DrawAsSelected: Boolean write fDrawAsSelected;
      property ClearPhysics: Boolean write fClearPhysics;

      class procedure CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
  end;

implementation

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

    if fLemming.LemIsZombie then
      B := B and not CPM_LEMMING_ZOMBIE;
  end else
    for i := 0 to Length(fSwaps)-1 do
    begin
      case fSwaps[i].Condition of
        rcl_Selected: if not fDrawAsSelected then Continue;
        rcl_Zombie: if not fLemming.LemIsZombie then Continue;
        rcl_Athlete: if not fLemming.HasPermanentSkills then Continue;
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
  BlendMem(TempColor, B);
end;

procedure TRecolorImage.CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
begin
  // photoflash
  if F <> 0 then B := clBlack32 else B := clWhite32;
end;

procedure TRecolorImage.RegisterSwap(aSec: TParserSection; const aIteration: Integer; aData: Pointer);
var
  Mode: ^TColorSwapType absolute aData;
  i: Integer;
begin
  i := Length(fSwaps);
  SetLength(fSwaps, i+1);
  fSwaps[i].Condition := Mode^;
  fSwaps[i].SrcColor := aSec.LineNumeric['from'];
  fSwaps[i].DstColor := aSec.LineNumeric['to'];
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

      Mode := rcl_Athlete;
      Parser.MainSection.Section['recoloring'].DoForEachSection('athlete', RegisterSwap, @Mode);

      Mode := rcl_Zombie;
      Parser.MainSection.Section['recoloring'].DoForEachSection('zombie', RegisterSwap, @Mode);

      Mode := rcl_Selected;
      Parser.MainSection.Section['recoloring'].DoForEachSection('selected', RegisterSwap, @Mode);
    end;
  finally
    Parser.Free;
  end;
end;

class procedure TRecolorImage.CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
end;

end.
 