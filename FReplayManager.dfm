object FReplayManager: TFReplayManager
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Replay Manager'
  ClientHeight = 243
  ClientWidth = 510
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object rgReplayKind: TRadioGroup
    Left = 8
    Top = 8
    Width = 121
    Height = 227
    Caption = 'Replay Kind'
    ItemIndex = 0
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
    OnClick = rgReplayKindClick
  end
  object gbAction: TGroupBox
    Left = 144
    Top = 8
    Width = 358
    Height = 185
    Caption = 'Action for _______'
    TabOrder = 1
    object rbDoNothing: TRadioButton
      Left = 16
      Top = 24
      Width = 145
      Height = 17
      Caption = 'Keep Existing Filename'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbReplayActionClick
    end
    object rbDeleteFile: TRadioButton
      Left = 16
      Top = 47
      Width = 113
      Height = 17
      Caption = 'Delete File'
      TabOrder = 1
      OnClick = rbReplayActionClick
    end
    object rbCopyTo: TRadioButton
      Left = 152
      Top = 70
      Width = 145
      Height = 17
      Caption = 'Rename New Copy As:'
      TabOrder = 2
      OnClick = rbReplayActionClick
    end
    object rbMoveTo: TRadioButton
      Left = 16
      Top = 70
      Width = 113
      Height = 17
      Caption = 'Rename As:'
      TabOrder = 3
      OnClick = rbReplayActionClick
    end
    object cbNamingScheme: TComboBox
      Left = 16
      Top = 95
      Width = 321
      Height = 21
      TabOrder = 4
      OnChange = cbNamingSchemeChange
      OnEnter = cbNamingSchemeEnter
      Items.Strings = (
        'Position + Timestamp'
        'Title + Timestamp'
        'Position + Title + Timestamp'
        'Username + Position + Timestamp'
        'Username + Title + Timestamp'
        'Username + Position + Title + Timestamp')
    end
    object cbUpdateVersion: TCheckBox
      Left = 16
      Top = 145
      Width = 289
      Height = 17
      Caption = 'Update version number if Passed'
      TabOrder = 5
      OnClick = cbUpdateVersionClick
    end
    object cbAppendResult: TCheckBox
      Left = 16
      Top = 122
      Width = 185
      Height = 17
      Caption = 'Append replay result to filename'
      TabOrder = 6
      OnClick = cbAppendResultClick
    end
  end
  object btnOK: TButton
    Left = 207
    Top = 210
    Width = 124
    Height = 25
    Caption = 'Run Replay Check'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 337
    Top = 210
    Width = 88
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
