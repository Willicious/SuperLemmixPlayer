object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Level Select'
  ClientHeight = 528
  ClientWidth = 1058
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblName: TLabel
    Left = 308
    Top = 9
    Width = 592
    Height = 25
    AutoSize = False
    Caption = '<Name>'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblPosition: TLabel
    Left = 308
    Top = 40
    Width = 592
    Height = 16
    AutoSize = False
    Caption = '<Position>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblAuthor: TLabel
    Left = 308
    Top = 62
    Width = 583
    Height = 16
    AutoSize = False
    Caption = '<Author>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblCompletion: TLabel
    Left = 308
    Top = 84
    Width = 592
    Height = 32
    AutoSize = False
    Caption = '<Completion>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblRecordsOptions: TLabel
    Left = 941
    Top = 17
    Width = 85
    Height = 13
    Caption = 'Records Options'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblAdvancedOptions: TLabel
    Left = 936
    Top = 119
    Width = 96
    Height = 13
    Caption = 'Advanced Options'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblReplayOptions: TLabel
    Left = 941
    Top = 288
    Width = 79
    Height = 13
    Caption = 'Replay Options'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object tvLevelSelect: TTreeView
    Left = 8
    Top = 8
    Width = 273
    Height = 513
    Images = ilStatuses
    Indent = 19
    MultiSelectStyle = []
    ReadOnly = True
    TabOrder = 0
    OnChange = tvLevelSelectChange
    OnExpanded = tvLevelSelectExpanded
    OnKeyDown = tvLevelSelectKeyDown
  end
  object btnCancel: TButton
    Left = 916
    Top = 495
    Width = 134
    Height = 25
    Cancel = True
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 2
  end
  object btnOK: TButton
    Left = 294
    Top = 495
    Width = 606
    Height = 25
    Caption = 'Play'
    TabOrder = 1
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 300
    Top = 122
    Width = 600
    Height = 369
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 10
  end
  object btnClearRecords: TButton
    Left = 916
    Top = 36
    Width = 134
    Height = 25
    Hint = 'Reset all user records for the selected level pack'
    Caption = 'Clear Records'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    OnClick = btnClearRecordsClick
  end
  object btnCleanseOne: TButton
    Left = 916
    Top = 233
    Width = 134
    Height = 25
    Hint = 'Save a copy of this level in the latest SuperLemmix format'
    Caption = 'Cleanse This Level'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
    OnClick = btnCleanseOneClick
  end
  object btnCleanseLevels: TButton
    Left = 916
    Top = 202
    Width = 134
    Height = 25
    Hint = 
      'Save a copy of all levels in the selected pack in the latest Sup' +
      'erLemmix format'
    Caption = 'Cleanse All Levels'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
    OnClick = btnCleanseLevelsClick
  end
  object btnReplayManager: TButton
    Left = 916
    Top = 307
    Width = 134
    Height = 25
    Hint = 'Perform a replay check for every level in the selected pack'
    Caption = 'Replay Manager'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 7
    OnClick = btnReplayManagerClick
  end
  object btnSaveImage: TButton
    Left = 916
    Top = 171
    Width = 134
    Height = 25
    Caption = 'Screenshot Level'
    TabOrder = 6
    OnClick = btnSaveImageClick
  end
  object btnMakeShortcut: TButton
    Left = 916
    Top = 138
    Width = 134
    Height = 25
    Hint = 
      'Create a shortcut which opens SuperLemmix to the selected level ' +
      'pack'
    Caption = 'Create Shortcut'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 5
    OnClick = btnMakeShortcutClick
  end
  object btnResetTalismans: TBitBtn
    Left = 916
    Top = 67
    Width = 134
    Height = 25
    Caption = 'Reset Talismans'
    TabOrder = 4
    OnClick = btnResetTalismansClick
  end
  object btnPlaybackMode: TButton
    Left = 916
    Top = 338
    Width = 134
    Height = 25
    Caption = 'Playback Mode'
    TabOrder = 11
    OnClick = btnPlaybackModeClick
  end
  object ilStatuses: TImageList
  end
end
