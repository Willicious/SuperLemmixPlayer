object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'OGG Converter'
  ClientHeight = 186
  ClientWidth = 418
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lblStatus: TLabel
    Left = 136
    Top = 141
    Width = 75
    Height = 13
    Caption = 'Current Status:'
  end
  object btnConvert: TBitBtn
    Left = 160
    Top = 16
    Width = 105
    Height = 41
    Caption = 'Convert'
    TabOrder = 0
    OnClick = btnConvertClick
  end
  object pbProgress: TProgressBar
    Left = 40
    Top = 104
    Width = 337
    Height = 17
    TabOrder = 1
  end
  object btnOpen: TButton
    Left = 64
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 2
    OnClick = btnOpenClick
  end
  object btnSave: TButton
    Left = 288
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Save'
    TabOrder = 3
    OnClick = btnSaveClick
  end
  object Open: TOpenDialog
    Left = 16
    Top = 24
  end
  object Save: TSaveDialog
    Left = 376
    Top = 24
  end
end
