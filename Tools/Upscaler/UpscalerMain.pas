unit UpscalerMain;

interface

uses
  LemTypesTrimmed, Math, GR32, GR32_Png,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, GR32_Image;

type
  TForm1 = class(TForm)
    panSource: TPanel;
    panDest: TPanel;
    rgUpscaleType: TRadioGroup;
    rgLeftEdgeBehaviour: TRadioGroup;
    rgTopEdgeBehaviour: TRadioGroup;
    rgRightEdgeBehaviour: TRadioGroup;
    rgBottomEdgeBehaviour: TRadioGroup;
    gbFrames: TGroupBox;
    ebFramesHorz: TEdit;
    lblFramesTimes: TLabel;
    ebFramesVert: TEdit;
    btnLoadImage: TButton;
    btnSaveImage: TButton;
    imgSource: TImage32;
    imgDest: TImage32;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rgUpscaleTypeClick(Sender: TObject);
    procedure ebFramesHorzChange(Sender: TObject);
    procedure btnLoadImageClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
  private
    fLoadName: String;
    procedure SetPanelSizes;
    procedure RegenerateImage;
    procedure SetImageScale;
    function GetSettings: TUpscaleSettings;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnLoadImageClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Image file (BMP or PNG)|*.bmp;*.png|All files|*';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly];
    if OpenDlg.Execute then
    begin
      if IsValidPNG(OpenDlg.FileName) then
        LoadBitmap32FromPNG(ImgSource.Bitmap, OpenDlg.FileName)
      else
        ImgSource.Bitmap.LoadFromFile(OpenDlg.FileName);

      RegenerateImage;
      SetImageScale;

      fLoadName := OpenDlg.FileName;
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TForm1.btnSaveImageClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if imgDest.Bitmap.Width * imgDest.Bitmap.Height = 0 then Exit;  

  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'PNG Image|*.png|BMP Image|*.bmp';
    SaveDlg.Options := [ofOverwritePrompt];
    SaveDlg.FileName := ChangeFileExt(fLoadName, '.png');
    if SaveDlg.Execute then
    begin
      if SaveDlg.FilterIndex = 0 then
        SaveBitmap32ToPng(imgDest.Bitmap, SaveDlg.FileName)
      else
        imgDest.Bitmap.SaveToFile(SaveDlg.FileName);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TForm1.ebFramesHorzChange(Sender: TObject);
begin
  RegenerateImage;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  SetPanelSizes;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  SetPanelSizes;
end;

function TForm1.GetSettings: TUpscaleSettings;
begin
  Result.Mode := TUpscaleMode(rgUpscaleType.ItemIndex);
  Result.LeftSide := TUpscaleEdgeBehaviour(rgLeftEdgeBehaviour.ItemIndex);
  Result.TopSide := TUpscaleEdgeBehaviour(rgTopEdgeBehaviour.ItemIndex);
  Result.RightSide := TUpscaleEdgeBehaviour(rgRightEdgeBehaviour.ItemIndex);
  Result.BottomSide := TUpscaleEdgeBehaviour(rgBottomEdgeBehaviour.ItemIndex);
end;

procedure TForm1.RegenerateImage;
begin
  UpscaleFrames(imgSource.Bitmap,
                Max(1, StrToIntDef(ebFramesHorz.Text, 1)),
                Max(1, StrToIntDef(ebFramesVert.Text, 1)),
                GetSettings, imgDest.Bitmap);
end;

procedure TForm1.rgUpscaleTypeClick(Sender: TObject);
begin
  RegenerateImage;
end;

procedure TForm1.SetImageScale;
begin
  if imgDest.Bitmap.Width * imgDest.Bitmap.Height = 0 then Exit;

  if (imgDest.Bitmap.Width > imgDest.Width) or (imgDest.Bitmap.Height > imgDest.Height) then
    imgDest.Scale := 1 / Max(imgDest.Bitmap.Width div imgDest.Width, imgDest.Bitmap.Height div imgDest.Height)
  else
    imgDest.Scale := Min(imgDest.Width div imgDest.Bitmap.Width, imgDest.Height div imgDest.Bitmap.Height);

  imgSource.Scale := imgDest.Scale / 2;
end;

procedure TForm1.SetPanelSizes;
begin
  panSource.Width := ClientWidth - panSource.Left - 16;
  panSource.Height := (ClientHeight - 32) div 3;

  panDest.Width := panSource.Width;
  panDest.Height := panSource.Height * 2;
  panDest.Top := ClientHeight - panDest.Height - 8;

  SetImageScale;
end;

end.
