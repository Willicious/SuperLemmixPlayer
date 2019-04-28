object FNLContentPacker: TFNLContentPacker
  Left = 0
  Top = 0
  Caption = 'NeoLemmix Content Packer'
  ClientHeight = 404
  ClientWidth = 584
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    584
    404)
  PixelsPerInch = 96
  TextHeight = 13
  object lblContentList: TLabel
    Left = 16
    Top = 8
    Width = 58
    Height = 13
    Caption = 'Content List'
  end
  object lbContent: TListBox
    Left = 8
    Top = 27
    Width = 294
    Height = 338
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 0
  end
  object gbLevelPack: TGroupBox
    Left = 317
    Top = 16
    Width = 257
    Height = 154
    Anchors = [akTop, akRight]
    Caption = 'Add Level Pack'
    TabOrder = 1
    object cbLevelPack: TComboBox
      Left = 16
      Top = 24
      Width = 225
      Height = 21
      Sorted = True
      TabOrder = 0
    end
    object rgPackGraphicSets: TRadioGroup
      Left = 16
      Top = 51
      Width = 114
      Height = 86
      Caption = 'Auto Add Tilesets?'
      ItemIndex = 2
      Items.Strings = (
        'Add Full Set'
        'Add Used Pieces'
        'Do Not Add'
        'Per-Tileset')
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
        'Per-Track')
      TabOrder = 2
    end
    object Button2: TButton
      Left = 175
      Top = 125
      Width = 62
      Height = 21
      Caption = 'Add'
      TabOrder = 3
    end
  end
  object gbStyle: TGroupBox
    Left = 317
    Top = 176
    Width = 257
    Height = 133
    Anchors = [akTop, akRight]
    Caption = 'Add Graphic Set'
    TabOrder = 2
    object cbGraphicSet: TComboBox
      Left = 16
      Top = 24
      Width = 225
      Height = 21
      Sorted = True
      TabOrder = 0
    end
    object rgSetFull: TRadioGroup
      Left = 16
      Top = 51
      Width = 121
      Height = 70
      Caption = 'Which Pieces?'
      ItemIndex = 0
      Items.Strings = (
        'All'
        'Used In Packs'
        'Exclude')
      TabOrder = 1
    end
    object Button1: TButton
      Left = 175
      Top = 99
      Width = 62
      Height = 21
      Caption = 'Add'
      TabOrder = 2
    end
  end
  object gbFile: TGroupBox
    Left = 317
    Top = 315
    Width = 257
    Height = 81
    Anchors = [akTop, akRight]
    Caption = 'Add File'
    TabOrder = 3
    object ebFilePath: TEdit
      Left = 16
      Top = 24
      Width = 225
      Height = 21
      TabOrder = 0
    end
    object btnBrowse: TButton
      Left = 107
      Top = 51
      Width = 62
      Height = 21
      Caption = 'Browse'
      TabOrder = 1
    end
    object btnFileAdd: TButton
      Left = 175
      Top = 51
      Width = 62
      Height = 21
      Caption = 'Add'
      TabOrder = 2
    end
  end
  object btnDelete: TButton
    Left = 227
    Top = 371
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Delete'
    TabOrder = 4
  end
  object btnItemOptions: TButton
    Left = 136
    Top = 371
    Width = 85
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Item Options'
    TabOrder = 5
  end
  object btnGlobalOptions: TButton
    Left = 45
    Top = 371
    Width = 85
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Global Options'
    TabOrder = 6
  end
  object MainMenu1: TMainMenu
    Left = 176
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
