object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Level Select'
  ClientHeight = 528
  ClientWidth = 1142
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblName: TLabel
    Left = 389
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
    Left = 389
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
    Left = 389
    Top = 62
    Width = 592
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
    Left = 389
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
    Left = 1021
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
    Left = 1016
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
    Left = 1021
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
    Width = 353
    Height = 512
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    Images = ilStatuses
    Indent = 16
    MultiSelectStyle = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    OnChange = tvLevelSelectChange
    OnExpanded = tvLevelSelectExpanded
    OnKeyDown = tvLevelSelectKeyDown
  end
  object btnOK: TButton
    Left = 375
    Top = 495
    Width = 606
    Height = 25
    Caption = 'Play'
    TabOrder = 1
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 381
    Top = 122
    Width = 600
    Height = 369
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 11
  end
  object btnClearRecords: TButton
    Left = 996
    Top = 36
    Width = 134
    Height = 25
    Hint = 'Reset all user records for the selected level pack'
    Caption = 'Clear Records'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = btnClearRecordsClick
  end
  object btnCleanseOne: TButton
    Left = 996
    Top = 233
    Width = 134
    Height = 25
    Hint = 'Save a copy of this level in the latest SuperLemmix format'
    Caption = 'Cleanse This Level'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 6
    OnClick = btnCleanseOneClick
  end
  object btnCleanseLevels: TButton
    Left = 996
    Top = 202
    Width = 134
    Height = 25
    Hint = 
      'Save a copy of all levels in the selected pack in the latest Sup' +
      'erLemmix format'
    Caption = 'Cleanse All Levels'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 5
    OnClick = btnCleanseLevelsClick
  end
  object btnReplayManager: TButton
    Left = 996
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
    Left = 996
    Top = 171
    Width = 134
    Height = 25
    Caption = 'Screenshot Level'
    TabOrder = 10
    OnClick = btnSaveImageClick
  end
  object btnMakeShortcut: TButton
    Left = 996
    Top = 138
    Width = 134
    Height = 25
    Hint = 
      'Create a shortcut which opens SuperLemmix to the selected level ' +
      'pack'
    Caption = 'Create Shortcut'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
    OnClick = btnMakeShortcutClick
  end
  object btnResetTalismans: TBitBtn
    Left = 996
    Top = 67
    Width = 134
    Height = 25
    Caption = 'Reset Talismans'
    TabOrder = 3
    OnClick = btnResetTalismansClick
  end
  object btnPlaybackMode: TButton
    Left = 996
    Top = 338
    Width = 134
    Height = 25
    Caption = 'Playback Mode'
    TabOrder = 8
    OnClick = btnPlaybackModeClick
  end
  object btnShowHideOptions: TButton
    Left = 996
    Top = 495
    Width = 134
    Height = 25
    Caption = '< Hide Options'
    TabOrder = 9
    OnClick = btnShowHideOptionsClick
  end
  object ilStatuses: TImageList
    AllocBy = 8
    Height = 24
    Width = 24
  end
end
