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
  object lblSearchLevels: TLabel
    Left = 8
    Top = 9
    Width = 72
    Height = 13
    Caption = 'Search Levels:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblEditingOptions: TLabel
    Left = 1021
    Top = 388
    Width = 81
    Height = 13
    Caption = 'Editing Options'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSearchResultsInfo: TLabel
    Left = 8
    Top = 42
    Width = 311
    Height = 13
    Caption = 'Single-click a search result to load the level into the preview:'
    Visible = False
  end
  object tvLevelSelect: TTreeView
    Left = 8
    Top = 35
    Width = 353
    Height = 485
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
    TabOrder = 14
    OnClick = tvLevelSelectClick
    OnExpanded = tvLevelSelectExpanded
    OnKeyDown = tvLevelSelectKeyDown
    OnKeyUp = tvLevelSelectKeyUp
  end
  object btnOK: TButton
    Left = 521
    Top = 495
    Width = 469
    Height = 25
    Caption = 'Play'
    TabOrder = 15
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 381
    Top = 120
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
    Hint = 'Save an image of the current level as a .png file'
    Caption = 'Screenshot Level'
    ParentShowHint = False
    ShowHint = True
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
    Hint = 
      'Reset completion status of all talismans for the current level t' +
      'o unobtained'
    Caption = 'Reset Talismans'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    OnClick = btnResetTalismansClick
  end
  object btnPlaybackMode: TButton
    Left = 996
    Top = 338
    Width = 134
    Height = 25
    Hint = 
      'Play a full collection of replays for the currently-selected pac' +
      'k as a continuous playlist'
    Caption = 'Playback Mode'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
    OnClick = btnPlaybackModeClick
  end
  object btnShowHideOptions: TButton
    Left = 381
    Top = 495
    Width = 134
    Height = 25
    Caption = '< Hide Options'
    TabOrder = 9
    OnClick = btnShowHideOptionsClick
  end
  object sbSearchLevels: TSearchBox
    Left = 90
    Top = 8
    Width = 271
    Height = 21
    TabOrder = 12
    OnKeyDown = sbSearchLevelsKeyDown
    OnInvokeSearch = sbSearchLevelsInvokeSearch
  end
  object pbSearchProgress: TProgressBar
    Left = 8
    Top = 35
    Width = 353
    Height = 17
    TabOrder = 13
    Visible = False
  end
  object lbSearchResults: TListBox
    Left = 8
    Top = 61
    Width = 353
    Height = 319
    Cursor = crHandPoint
    ItemHeight = 13
    TabOrder = 0
    Visible = False
    OnClick = lbSearchResultsClick
  end
  object btnCloseSearch: TButton
    Left = 144
    Top = 386
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 1
    Visible = False
    OnClick = btnCloseSearchClick
  end
  object btnEditLevel: TButton
    Left = 996
    Top = 407
    Width = 134
    Height = 25
    Hint = 
      'Open the current level in the Super/NeoLemmix Editor (whichever ' +
      'is present in the root folder)'
    Caption = 'Edit Level'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 16
    OnClick = btnEditLevelClick
  end
  object btnClose: TButton
    Left = 996
    Top = 495
    Width = 134
    Height = 25
    Caption = 'Close'
    TabOrder = 17
    OnClick = btnCloseClick
  end
  object pbUIProgress: TProgressBar
    Left = 8
    Top = 503
    Width = 353
    Height = 17
    TabOrder = 18
    Visible = False
  end
  object ilStatuses: TImageList
    AllocBy = 8
    Height = 24
    Width = 24
  end
end
