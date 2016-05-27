unit LemRecolorSprites;

interface

uses
  Windows, Classes,
  LemDosStructures,
  GR32, GR32_OrdinalMaps, GR32_Layers;

type
  TRecolorImage = class
  public
    class function GetLemColorScheme(IsZombie, IsPermenent, IsSelected, IsHighlight: Boolean): TPixelCombineEvent;
    (*
     procedure CombineDefaultPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineBuilderPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineMaskPixels(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineNoOverwriteStoner(F: TColor32; var B: TColor32; M: TColor32);
    procedure CombineMinimapWorldPixels(F: TColor32; var B: TColor32; M: TColor32);
    *)
  private
    class procedure CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsZombie(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsAthlete(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsSelected(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsSelectedZombie(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsSelectedAthlete(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingPixelsSelectedZombieAthlete(F: TColor32; var B: TColor32; M: TColor32);
    class procedure CombineLemmingHighlight(F: TColor32; var B: TColor32; M: TColor32);
  end;



implementation

class function TRecolorImage.GetLemColorScheme(IsZombie, IsPermenent, IsSelected, IsHighlight: Boolean): TPixelCombineEvent;
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
    Result := TRecolorImage.CombineLemmingPixels;
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


class procedure TRecolorImage.CombineLemmingPixels(F: TColor32; var B: TColor32; M: TColor32);
begin
  if F <> 0 then B := F;
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
end;


end.
 