object FReplayNaming: TFReplayNaming
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Replay Naming'
  ClientHeight = 195
  ClientWidth = 369
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
  object lblClassic: TLabel
    Left = 141
    Top = 152
    Width = 212
    Height = 13
    Caption = 'For "classic" behavior, just click "OK".'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object rgReplayKind: TRadioGroup
    Left = 8
    Top = 8
    Width = 121
    Height = 183
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
    Left = 135
    Top = 9
    Width = 225
    Height = 140
    Caption = 'Action for _______'
    TabOrder = 1
    object rbDoNothing: TRadioButton
      Left = 16
      Top = 16
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
      Top = 32
      Width = 113
      Height = 17
      Caption = 'Delete File'
      TabOrder = 1
      OnClick = rbReplayActionClick
    end
    object rbCopyTo: TRadioButton
      Left = 16
      Top = 48
      Width = 113
      Height = 17
      Caption = 'Copy To'
      TabOrder = 2
      OnClick = rbReplayActionClick
    end
    object rbMoveTo: TRadioButton
      Left = 16
      Top = 64
      Width = 113
      Height = 17
      Caption = 'Move To'
      TabOrder = 3
      OnClick = rbReplayActionClick
    end
    object cbNamingScheme: TComboBox
      Left = 16
      Top = 87
      Width = 193
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
    object cbRefresh: TCheckBox
      Left = 16
      Top = 114
      Width = 97
      Height = 17
      Caption = 'Refresh Replays'
      TabOrder = 5
      OnClick = cbRefreshClick
    end
  end
  object btnOK: TButton
    Left = 205
    Top = 166
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 286
    Top = 166
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
