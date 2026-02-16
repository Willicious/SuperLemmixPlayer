object FormStyleZipper: TFormStyleZipper
  Left = 0
  Top = 0
  Caption = 'Style Zipper'
  ClientHeight = 376
  ClientWidth = 587
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblStyles: TLabel
    Left = 24
    Top = 78
    Width = 38
    Height = 13
    Caption = 'Styles:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblStylesDirectory: TLabel
    Left = 129
    Top = 78
    Width = 79
    Height = 13
    Caption = 'styles\directory\'
  end
  object lblRepackPNG: TLabel
    Left = 25
    Top = 257
    Width = 397
    Height = 13
    Caption = 
      'Separate styles with a comma (,) Leave the field blank to repack' +
      ' PNGs for all styles'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object lblZIPOutput: TLabel
    Left = 24
    Top = 97
    Width = 64
    Height = 13
    Caption = 'ZIP Output:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblOutputDirectory: TLabel
    Left = 128
    Top = 97
    Width = 83
    Height = 13
    Caption = 'output\directory\'
  end
  object lblStyleTimes: TLabel
    Left = 25
    Top = 126
    Width = 69
    Height = 13
    Caption = 'Style Times:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblStyleTimesPath: TLabel
    Left = 129
    Top = 126
    Width = 74
    Height = 13
    Caption = 'styletimes\path'
  end
  object lblChecksums: TLabel
    Left = 25
    Top = 145
    Width = 89
    Height = 13
    Caption = 'ZIP Checksums:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblZIPChecksumsPath: TLabel
    Left = 129
    Top = 145
    Width = 94
    Height = 13
    Caption = 'zip\checksums\path'
  end
  object lblProgress: TLabel
    Left = 24
    Top = 288
    Width = 75
    Height = 13
    Caption = 'Progress info...'
  end
  object btnRunStyleZipper: TButton
    Left = 24
    Top = 317
    Width = 544
    Height = 49
    Caption = 'Run Style Zipper'
    TabOrder = 0
    OnClick = btnRunStyleZipperClick
  end
  object rbSuperLemmix: TRadioButton
    Left = 24
    Top = 23
    Width = 361
    Height = 17
    Caption = 'SuperLemmix'
    TabOrder = 1
    OnClick = RadioButtonClick
  end
  object rbRetroLemmini: TRadioButton
    Left = 25
    Top = 46
    Width = 361
    Height = 17
    Caption = 'RetroLemmini'
    TabOrder = 2
    OnClick = RadioButtonClick
  end
  object cbDeleteUnchanged: TCheckBox
    Left = 24
    Top = 174
    Width = 169
    Height = 17
    Caption = 'Delete unchanged zips'
    TabOrder = 3
  end
  object cbMakeAllStylesZip: TCheckBox
    Left = 24
    Top = 197
    Width = 265
    Height = 17
    Caption = 'Make full '#39'styles'#39' zip with all styles included'
    TabOrder = 4
  end
  object cbRepackPNG: TCheckBox
    Left = 24
    Top = 232
    Width = 113
    Height = 17
    Caption = 'Repack PNGs For:'
    TabOrder = 5
  end
  object edRepackPNGs: TEdit
    Left = 143
    Top = 230
    Width = 426
    Height = 21
    TabOrder = 6
  end
end
