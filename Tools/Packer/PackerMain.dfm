object FNLContentPacker: TFNLContentPacker
  Left = 0
  Top = 0
  Caption = 'NeoLemmix Content Packer'
  ClientHeight = 424
  ClientWidth = 499
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblContentList: TLabel
    Left = 16
    Top = 8
    Width = 58
    Height = 13
    Caption = 'Content List'
  end
  object ListBox1: TListBox
    Left = 8
    Top = 27
    Width = 209
    Height = 348
    ItemHeight = 13
    TabOrder = 0
  end
  object gbLevelPack: TGroupBox
    Left = 232
    Top = 16
    Width = 257
    Height = 130
    Caption = 'Add Level Pack'
    TabOrder = 1
    object cbLevelPack: TComboBox
      Left = 16
      Top = 24
      Width = 225
      Height = 21
      TabOrder = 0
    end
    object rgPackGraphicSets: TRadioGroup
      Left = 16
      Top = 51
      Width = 105
      Height = 68
      Caption = 'Auto Add Tilesets?'
      ItemIndex = 2
      Items.Strings = (
        'Yes'
        'No'
        'Interactive')
      TabOrder = 1
    end
    object rgPackMusic: TRadioGroup
      Left = 136
      Top = 51
      Width = 105
      Height = 68
      Caption = 'Auto Add Music?'
      ItemIndex = 0
      Items.Strings = (
        'Yes'
        'No'
        'Interactive')
      TabOrder = 2
    end
  end
  object gbStyle: TGroupBox
    Left = 232
    Top = 152
    Width = 257
    Height = 130
    Caption = 'Add Graphic Set'
    TabOrder = 2
  end
  object GroupBox2: TGroupBox
    Left = 232
    Top = 288
    Width = 257
    Height = 128
    Caption = 'Add File'
    TabOrder = 3
  end
  object btnDelete: TButton
    Left = 70
    Top = 381
    Width = 75
    Height = 25
    Caption = 'Delete'
    TabOrder = 4
  end
  object MainMenu1: TMainMenu
    Left = 8
    Top = 384
    object msFile: TMenuItem
      Caption = 'File'
      object miNew: TMenuItem
        Caption = '&New'
      end
      object miOpen: TMenuItem
        Caption = '&Open'
      end
      object miSave: TMenuItem
        Caption = '&Save'
      end
      object miSaveAs: TMenuItem
        Caption = 'Save &As'
      end
      object miFileSep1: TMenuItem
        Caption = '-'
      end
      object miExport: TMenuItem
        Caption = '&Export'
      end
      object miFileSep2: TMenuItem
        Caption = '-'
      end
      object miQuit: TMenuItem
        Caption = '&Quit'
      end
    end
  end
end
