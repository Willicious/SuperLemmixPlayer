object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Level Select'
  ClientHeight = 528
  ClientWidth = 1057
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
    Top = 8
    Width = 621
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
    Width = 621
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
    Width = 621
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
    Width = 621
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
  object lblAdvancedOptions: TLabel
    Left = 949
    Top = 17
    Width = 105
    Height = 13
    Caption = 'Advanced Options'
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
    OnClick = tvLevelSelectClick
  end
  object btnCancel: TButton
    Left = 945
    Top = 495
    Width = 105
    Height = 25
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 300
    Top = 495
    Width = 621
    Height = 25
    Caption = 'Play'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 300
    Top = 122
    Width = 629
    Height = 369
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 3
  end
  object btnMakeShortcut: TButton
    Left = 945
    Top = 65
    Width = 105
    Height = 25
    Caption = 'Create Shortcut'
    TabOrder = 4
    OnClick = btnMakeShortcutClick
  end
  object sbAdvancedOptions: TScrollBox
    Left = 945
    Top = 94
    Width = 110
    Height = 117
    VertScrollBar.Visible = False
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 5
    object btnSaveImage: TButton
      Left = 0
      Top = 0
      Width = 105
      Height = 25
      Caption = 'Screenshot'
      TabOrder = 0
      OnClick = btnSaveImageClick
    end
    object btnMassReplay: TButton
      Left = 0
      Top = 29
      Width = 105
      Height = 25
      Caption = 'Mass Replay Check'
      TabOrder = 1
      OnClick = btnMassReplayClick
    end
    object btnCleanseLevels: TButton
      Left = 0
      Top = 58
      Width = 105
      Height = 25
      Caption = 'Cleanse All Levels'
      TabOrder = 2
      OnClick = btnCleanseLevelsClick
    end
    object btnCleanseOne: TButton
      Left = 0
      Top = 87
      Width = 105
      Height = 25
      Caption = 'Cleanse This Level'
      TabOrder = 3
      OnClick = btnCleanseOneClick
    end
  end
  object btnClearRecords: TButton
    Left = 945
    Top = 36
    Width = 105
    Height = 25
    Caption = 'Clear Records'
    TabOrder = 6
    OnClick = btnClearRecordsClick
  end
  object ilStatuses: TImageList
  end
end
