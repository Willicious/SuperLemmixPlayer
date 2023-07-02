object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'OGG Converter'
  ClientHeight = 173
  ClientWidth = 418
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    418
    173)
  PixelsPerInch = 96
  TextHeight = 13
  object lblStatus: TLabel
    Left = 0
    Top = 141
    Width = 417
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 
      'Welcome! Click "Select Files" to load the files you wish to conv' +
      'ert'
  end
  object btnConvert: TBitBtn
    Left = 160
    Top = 50
    Width = 105
    Height = 41
    Caption = 'Convert'
    TabOrder = 0
    OnClick = btnConvertClick
  end
  object pbProgress: TProgressBar
    Left = 32
    Top = 104
    Width = 361
    Height = 17
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object btnOpen: TButton
    Left = 160
    Top = 16
    Width = 105
    Height = 25
    Caption = 'Select Files'
    TabOrder = 2
    OnClick = btnOpenClick
  end
  object Open: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 32
    Top = 8
  end
end
