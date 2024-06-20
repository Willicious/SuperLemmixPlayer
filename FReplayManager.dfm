object FReplayManager: TFReplayManager
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Replay Manager'
  ClientHeight = 449
  ClientWidth = 571
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
  object lblSelectedFolder: TLabel
    Left = 220
    Top = 44
    Width = 90
    Height = 13
    Caption = 'Selected Folder:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object rgReplayKind: TRadioGroup
    Left = 8
    Top = 79
    Width = 129
    Height = 329
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
    Left = 143
    Top = 79
    Width = 420
    Height = 177
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
      Left = 12
      Top = 95
      Width = 389
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
  object btnRunReplayCheck: TButton
    Left = 143
    Top = 414
    Width = 216
    Height = 25
    Caption = 'Run Replay Check'
    TabOrder = 2
    OnClick = btnRunReplayCheckClick
  end
  object btnCancel: TButton
    Left = 365
    Top = 414
    Width = 84
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object gbActionsList: TGroupBox
    Left = 143
    Top = 262
    Width = 420
    Height = 146
    Caption = 'Actions List'
    TabOrder = 4
    object lblDoForPassed: TLabel
      Left = 130
      Top = 23
      Width = 266
      Height = 13
      Caption = 'Keep Existing Filename, Append Result, Update Version'
    end
    object lblDoForTalisman: TLabel
      Left = 130
      Top = 42
      Width = 109
      Height = 13
      Caption = 'Keep Existing Filename'
    end
    object lblDoForUndetermined: TLabel
      Left = 130
      Top = 61
      Width = 109
      Height = 13
      Caption = 'Keep Existing Filename'
    end
    object lblDoForFailed: TLabel
      Left = 130
      Top = 80
      Width = 109
      Height = 13
      Caption = 'Keep Existing Filename'
    end
    object lblDoForLevelNotFound: TLabel
      Left = 130
      Top = 99
      Width = 109
      Height = 13
      Caption = 'Keep Existing Filename'
    end
    object lblDoForError: TLabel
      Left = 130
      Top = 118
      Width = 109
      Height = 13
      Caption = 'Keep Existing Filename'
    end
    object stDoForPassed: TStaticText
      Left = 16
      Top = 23
      Width = 47
      Height = 17
      Caption = 'Passed:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object stDoForTalisman: TStaticText
      Left = 16
      Top = 42
      Width = 111
      Height = 17
      Caption = 'Passed (Talisman):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object stDoForUndetermined: TStaticText
      Left = 16
      Top = 61
      Width = 88
      Height = 17
      Caption = 'Undetermined:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object stDoForFailed: TStaticText
      Left = 16
      Top = 80
      Width = 40
      Height = 17
      Caption = 'Failed:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object stDoForLevelNotFound: TStaticText
      Left = 16
      Top = 99
      Width = 96
      Height = 17
      Caption = 'Level Not Found:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object stDoForError: TStaticText
      Left = 16
      Top = 118
      Width = 35
      Height = 17
      Caption = 'Error:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
  end
  object stPackName: TStaticText
    AlignWithMargins = True
    Left = 0
    Top = 7
    Width = 577
    Height = 24
    Alignment = taCenter
    AutoSize = False
    Caption = '(pack name)'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Hobo Std'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object stSelectedFolder: TStaticText
    Left = 320
    Top = 44
    Width = 212
    Height = 17
    Caption = '(Click Browse to choose a folder of replays)'
    TabOrder = 6
  end
  object btnBrowse: TButton
    Left = 113
    Top = 39
    Width = 98
    Height = 25
    Caption = 'Browse'
    TabOrder = 7
    OnClick = btnBrowseClick
  end
end
