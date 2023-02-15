object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Level Select'
  ClientHeight = 480
  ClientWidth = 849
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
    Left = 304
    Top = 16
    Width = 321
    Height = 13
    AutoSize = False
    Caption = '<Name>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblPosition: TLabel
    Left = 304
    Top = 40
    Width = 321
    Height = 13
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
    Left = 304
    Top = 56
    Width = 321
    Height = 13
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
    Left = 304
    Top = 80
    Width = 321
    Height = 13
    AutoSize = False
    Caption = '<Completion>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblAdvancedOptions: TLabel
    Left = 720
    Top = 8
    Width = 95
    Height = 13
    Caption = 'Advanced Options'
  end
  object tvLevelSelect: TTreeView
    Left = 8
    Top = 8
    Width = 273
    Height = 465
    Images = ilStatuses
    Indent = 19
    MultiSelectStyle = []
    ReadOnly = True
    TabOrder = 0
    OnClick = tvLevelSelectClick
  end
  object btnCancel: TButton
    Left = 629
    Top = 446
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 575
    Top = 446
    Width = 48
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 296
    Top = 128
    Width = 408
    Height = 313
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 3
  end
  object btnMakeShortcut: TButton
    Left = 467
    Top = 446
    Width = 85
    Height = 25
    Caption = 'Create Shortcut'
    TabOrder = 4
    OnClick = btnMakeShortcutClick
  end
  object sbAdvancedOptions: TScrollBox
    Left = 712
    Top = 24
    Width = 129
    Height = 448
    VertScrollBar.Visible = False
    TabOrder = 5
    object btnSaveImage: TButton
      Left = 3
      Top = 3
      Width = 118
      Height = 25
      Caption = 'Save Image'
      TabOrder = 0
      OnClick = btnSaveImageClick
    end
    object btnMassReplay: TButton
      Left = 3
      Top = 30
      Width = 118
      Height = 25
      Caption = 'Mass Replay Check'
      TabOrder = 1
      OnClick = btnMassReplayClick
    end
    object btnCleanseLevels: TButton
      Left = 3
      Top = 57
      Width = 118
      Height = 25
      Caption = 'Cleanse All Levels'
      TabOrder = 2
      OnClick = btnCleanseLevelsClick
    end
    object btnCleanseOne: TButton
      Left = 3
      Top = 84
      Width = 118
      Height = 25
      Caption = 'Cleanse This Level'
      TabOrder = 3
      OnClick = btnCleanseOneClick
    end
  end
  object btnClearRecords: TButton
    Left = 296
    Top = 447
    Width = 85
    Height = 25
    Caption = 'Clear Records'
    TabOrder = 6
    OnClick = btnClearRecordsClick
  end
  object ilStatuses: TImageList
  end
end
