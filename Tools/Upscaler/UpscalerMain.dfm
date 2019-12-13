object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'NeoLemmix Upscaler'
  ClientHeight = 513
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object panSource: TPanel
    Left = 136
    Top = 8
    Width = 483
    Height = 185
    TabOrder = 0
    DesignSize = (
      483
      185)
    object imgSource: TImage32
      Left = 8
      Top = 8
      Width = 465
      Height = 169
      Anchors = [akLeft, akTop, akRight, akBottom]
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baCenter
      Scale = 2.000000000000000000
      ScaleMode = smResize
      TabOrder = 0
    end
  end
  object panDest: TPanel
    Left = 136
    Top = 320
    Width = 483
    Height = 185
    TabOrder = 1
    DesignSize = (
      483
      185)
    object imgDest: TImage32
      Left = 8
      Top = 8
      Width = 465
      Height = 169
      Anchors = [akLeft, akTop, akRight, akBottom]
      Bitmap.ResamplerClassName = 'TNearestResampler'
      BitmapAlign = baCenter
      Scale = 2.000000000000000000
      ScaleMode = smResize
      TabOrder = 0
    end
  end
  object rgUpscaleType: TRadioGroup
    Left = 8
    Top = 8
    Width = 121
    Height = 73
    Caption = 'Upscale Type'
    ItemIndex = 0
    Items.Strings = (
      'Zoom-In'
      'Pixel Art Upscaler'
      'Resampler')
    TabOrder = 2
    OnClick = rgUpscaleTypeClick
  end
  object rgLeftEdgeBehaviour: TRadioGroup
    Left = 8
    Top = 87
    Width = 121
    Height = 73
    Caption = 'Left Edge'
    ItemIndex = 2
    Items.Strings = (
      'Repeat'
      'Mirror'
      'Blank')
    TabOrder = 3
    OnClick = rgUpscaleTypeClick
  end
  object rgTopEdgeBehaviour: TRadioGroup
    Left = 8
    Top = 166
    Width = 121
    Height = 73
    Caption = 'Top Edge'
    ItemIndex = 2
    Items.Strings = (
      'Repeat'
      'Mirror'
      'Blank')
    TabOrder = 4
    OnClick = rgUpscaleTypeClick
  end
  object rgRightEdgeBehaviour: TRadioGroup
    Left = 8
    Top = 245
    Width = 121
    Height = 73
    Caption = 'Right Edge'
    ItemIndex = 2
    Items.Strings = (
      'Repeat'
      'Mirror'
      'Blank')
    TabOrder = 5
    OnClick = rgUpscaleTypeClick
  end
  object rgBottomEdgeBehaviour: TRadioGroup
    Left = 8
    Top = 324
    Width = 121
    Height = 73
    Caption = 'Bottom Edge'
    ItemIndex = 2
    Items.Strings = (
      'Repeat'
      'Mirror'
      'Blank')
    TabOrder = 6
    OnClick = rgUpscaleTypeClick
  end
  object gbFrames: TGroupBox
    Left = 8
    Top = 403
    Width = 121
    Height = 73
    Caption = 'Frames'
    TabOrder = 7
    object lblFramesTimes: TLabel
      Left = 55
      Top = 35
      Width = 6
      Height = 13
      Caption = 'x'
    end
    object ebFramesHorz: TEdit
      Left = 11
      Top = 32
      Width = 38
      Height = 21
      Alignment = taCenter
      NumbersOnly = True
      TabOrder = 0
      Text = '1'
      OnChange = ebFramesHorzChange
    end
    object ebFramesVert: TEdit
      Left = 67
      Top = 32
      Width = 38
      Height = 21
      Alignment = taCenter
      NumbersOnly = True
      TabOrder = 1
      Text = '1'
      OnChange = ebFramesHorzChange
    end
  end
  object btnLoadImage: TButton
    Left = 8
    Top = 482
    Width = 57
    Height = 25
    Caption = 'Load'
    TabOrder = 8
    OnClick = btnLoadImageClick
  end
  object btnSaveImage: TButton
    Left = 72
    Top = 482
    Width = 57
    Height = 25
    Caption = 'Save'
    TabOrder = 9
    OnClick = btnSaveImageClick
  end
end
