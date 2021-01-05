object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Replay Naming'
  ClientHeight = 182
  ClientWidth = 329
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object rgReplayKind: TRadioGroup
    Left = 8
    Top = 8
    Width = 121
    Height = 170
    Caption = 'Replay Kind'
    Items.Strings = (
      'All'
      'All Passed'
      'All Failed'
      'Passed'
      'Passed (Talisman)'
      'Undetermined'
      'Failed'
      'Level Not Found'
      'Other Error')
    TabOrder = 0
  end
  object GroupBox1: TGroupBox
    Left = 135
    Top = 9
    Width = 185
    Height = 140
    Caption = 'Action for _______'
    TabOrder = 1
    object rbDoNothing: TRadioButton
      Left = 16
      Top = 16
      Width = 145
      Height = 17
      Caption = 'Keep Existing Filename'
      TabOrder = 0
    end
    object rbDeleteFile: TRadioButton
      Left = 16
      Top = 32
      Width = 113
      Height = 17
      Caption = 'Delete File'
      TabOrder = 1
    end
    object rbCopyTo: TRadioButton
      Left = 16
      Top = 48
      Width = 113
      Height = 17
      Caption = 'Copy To'
      TabOrder = 2
    end
    object rbMoveTo: TRadioButton
      Left = 16
      Top = 64
      Width = 113
      Height = 17
      Caption = 'Move To'
      TabOrder = 3
    end
    object cbNamingScheme: TComboBox
      Left = 16
      Top = 87
      Width = 145
      Height = 21
      TabOrder = 4
      Text = 'cbNamingScheme'
    end
    object cbRefresh: TCheckBox
      Left = 16
      Top = 114
      Width = 97
      Height = 17
      Caption = 'Refresh Replays'
      TabOrder = 5
    end
  end
  object btnOK: TButton
    Left = 165
    Top = 153
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 246
    Top = 153
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
