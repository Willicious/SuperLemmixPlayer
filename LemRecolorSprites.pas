unit LemRecolorSprites;

interface

uses
  Dialogs,
  Classes, SysUtils,
  LemNeoParserOld,
  LemDosStructures, LemLemming, LemTypes,
  GR32, GR32_Blend{, GR32_OrdinalMaps, GR32_Layers};

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
      fSwaps: TColorSwapArray;

      procedure SwapColors(F: TColor32; var B: TColor32);

      (*procedure CombineLemmingPixelsZombie(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsAthlete(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsSelected(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsSelectedZombie(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsSelectedAthlete(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingPixelsSelectedZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);*)
    public
      constructor Create;

      procedure LoadSwaps(aName: String);
      procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
      procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);

      property Lemming: TLemming write fLemming;
      property DrawAsSelected: Boolean write fDrawAsSelected;

      (*class function GetLemColorScheme(IsZombie, IsPermenent, IsSelected, IsHighlight: Boolean): TPixelCombineEvent;*)
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
  Progress: TSwapProgressArray;
begin
  B := F;

  if fLemming = nil then Exit;
  if (F and $FF000000) = 0 then Exit;

  FillChar(Progress, SizeOf(TSwapProgressArray), 0);

  for i := 0 to Length(fSwaps)-1 do
  begin
    if Progress[fSwaps[i].Condition] then Continue;
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

procedure TRecolorImage.LoadSwaps(aName: String);
var
  Parser: TNeoLemmixParser;
  Line: TParserLine;
  Mode: TColorSwapType;
  SwapCount: Integer;

  procedure CheckExpand;
  begin
    if Length(fSwaps) = SwapCount then
      SetLength(fSwaps, Length(fSwaps)+64);
  end;
begin
  SetLength(fSwaps, 0);
  SwapCount := 0;
  Parser := TNeoLemmixParser.Create;
  Mode := rcl_Selected;
  try
    Parser.LoadFromFile(AppPath + 'gfx/sprites/' + aName + '/scheme.nxmi');
    repeat
      Line := Parser.NextLine;
      if Line.Keyword = 'SELECTED' then Mode := rcl_Selected;
      if Line.Keyword = 'ZOMBIE' then Mode := rcl_Zombie;
      if Line.Keyword = 'ATHLETE' then Mode := rcl_Athlete;
      if StrToIntDef('x' + Line.Keyword, -1) <> -1 then
      begin
        CheckExpand;
        fSwaps[SwapCount].Condition := Mode;
        fSwaps[SwapCount].SrcColor := StrToInt('x' + Line.Keyword);
        fSwaps[SwapCount].DstColor := StrToInt('x' + Line.Value);
        Inc(SwapCount);
      end;
    until Line.Keyword = '';
  finally
    SetLength(fSwaps, SwapCount);
    Parser.Free;
  end;
end;

(*class function TRecolorImage.GetLemColorScheme(IsZombie, IsPermenent, IsSelected, IsHighlight: Boolean): TPixelCombineEvent;
begin
  if IsHighlight then
    Result := TRecolorImage.CombineLemmingHighlight
  else if IsSelected and IsPermenent and IsZombie then
    Result := TRecolorImage.CombineLemmingPixelsSelectedZombieAthlete
  else if IsSelected and IsPermenent then
    Result := TRecolorImage.CombineLemmingPixelsSelectedAthlete
  else if IsSelected and IsZombie then
    Result := TRecolorImage.CombineLemmingPixelsSelectedZombie
  else if IsSelected then
    Result := TRecolorImage.CombineLemmingPixelsSelected
  else if IsPermenent and IsZombie then
    Result := TRecolorImage.CombineLemmingPixelsZombieAthlete
  else if IsPermenent then
    Result := TRecolorImage.CombineLemmingPixelsAthlete
  else if IsZombie then
    Result := TRecolorImage.CombineLemmingPixelsZombie
  else
    Result := TRecolorImage.CombineDefaultPixels;
end;

procedure ChangeSkinColor(out F: TColor32);
begin
  // color white skin gray
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[3]) and $FFFFFF) then
    F := DosVgaColorToColor32(DosInLevelPalette[6]);
end;

procedure ChangeSelected(out F: TColor32);
begin
  // recolor body red
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[1]) and $FFFFFF) then
    F := DosVgaColorToColor32(DosInLevelPalette[5]);
end;

procedure SwapHairBody(out F: TColor32);
begin
  // interchange blue and green
  if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[2]) and $FFFFFF) then
    F := DosVgaColorToColor32(DosInLevelPalette[1])
  else if (F and $FFFFFF) = (DosVgaColorToColor32(DosInLevelPalette[1]) and $FFFFFF) then
    F := DosVgaColorToColor32(DosInLevelPalette[2]);
end;

class procedure TRecolorImage.CombineLemmingPixelsZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSkinColor(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingPixelsAthlete(F: TColor32; var B: TColor32; M: TColor32);
begin
  SwapHairBody(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingPixelsZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSkinColor(F);
  SwapHairBody(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingPixelsSelected(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSelected(F);
  if F <> 0 then B := F;
end;


class procedure TRecolorImage.CombineLemmingPixelsSelectedZombie(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSelected(F);
  ChangeSkinColor(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingPixelsSelectedAthlete(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSelected(F);
  SwapHairBody(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingPixelsSelectedZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
begin
  ChangeSelected(F);
  SwapHairBody(F);
  ChangeSkinColor(F);
  if F <> 0 then B := F;
end;

class procedure TRecolorImage.CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
begin
  // photoflash
  if F <> 0 then B := clBlack32 else B := clWhite32;
end;*)


class procedure TRecolorImage.CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
end;

end.
 