program imgspander;

{$APPTYPE CONSOLE}

uses
  GR32,
  PngInterface,
  Classes, Math, SysUtils;

var
  SL: TStringList;
  srcw, srch: Integer;
  dstw, dsth: Integer;
  minw, minh: Integer;
  i: Integer;
  SrcBmp, DstBmp: TBitmap32;
  HFrame, VFrame: Integer;
  x, y, fx, fy: Integer;
  SrcRect: TRect;

begin
  SL := TStringList.Create;

  SL.LoadFromFile('instructions.txt');

  srcw := StrToInt(SL[0]);
  srch := StrToInt(SL[1]);
  dstw := StrToInt(SL[2]);
  dsth := StrToInt(SL[3]);

  minw := Min(srcw, dstw);
  minh := Min(dstw, dsth);

  SrcBmp := TBitmap32.Create;
  DstBmp := TBitmap32.Create;

  SrcBmp.OuterColor := 0;


  for i := 4 to SL.Count-1 do
  begin
    TPngInterface.LoadPngFile(SL[i] + '.png', SrcBmp);

    HFrame := SrcBmp.Width div srcw;
    VFrame := SrcBmp.Height div srch;
    DstBmp.SetSize(HFrame * dstw, VFrame * dsth);

    for fy := 0 to VFrame-1 do
      for fx := 0 to HFrame-1 do
      begin
        SrcRect := Rect(fx * srcw, fy * srch, (fx * srcw) + minw, (fy * srch) + minh);
        SrcBmp.DrawTo(DstBmp, fx * dstw, fy * dsth, SrcRect);
      end;

    TPngInterface.SavePngFile(SL[i] + '.png.old', SrcBmp);
    TPngInterface.SavePngFile(SL[i] + '.png', DstBmp);
  end;

  SL.Free;
end.
