object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Level Select'
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
  object lblAdvancedOptions: TLabel
    Left = 935
    Top = 17
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
  object tvLevelSelect: TTreeView
    Left = 8
    Top = 8
    Width = 273
    Height = 513
    Images = ilStatuses
    Indent = 19
    MultiSelectStyle = []
    ReadOnly = True
    TabOrder = 9
    OnChange = tvLevelSelectChange
    OnClick = tvLevelSelectClick
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
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 294
    Top = 495
    Width = 606
    Height = 25
    Caption = 'Play'
    TabOrder = 0
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 300
    Top = 122
    Width = 600
    Height = 369
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 8
  end
  object btnClearRecords: TButton
    Left = 916
    Top = 36
    Width = 134
    Height = 25
    Caption = 'Clear Records'
    TabOrder = 2
    OnClick = btnClearRecordsClick
  end
  object btnCleanseOne: TButton
    Left = 916
    Top = 193
    Width = 134
    Height = 25
    Caption = 'Cleanse This Level'
    TabOrder = 7
    OnClick = btnCleanseOneClick
  end
  object btnCleanseLevels: TButton
    Left = 916
    Top = 162
    Width = 134
    Height = 25
    Caption = 'Cleanse All Levels'
    TabOrder = 6
    OnClick = btnCleanseLevelsClick
  end
  object btnMassReplay: TButton
    Left = 916
    Top = 131
    Width = 134
    Height = 25
    Caption = 'Mass Replay Check'
    TabOrder = 5
    OnClick = btnMassReplayClick
  end
  object btnSaveImage: TButton
    Left = 916
    Top = 100
    Width = 134
    Height = 25
    Caption = 'Screenshot'
    TabOrder = 4
    OnClick = btnSaveImageClick
  end
  object btnMakeShortcut: TButton
    Left = 916
    Top = 67
    Width = 134
    Height = 25
    Caption = 'Create Shortcut'
    TabOrder = 3
    OnClick = btnMakeShortcutClick
  end
  object ilStatuses: TImageList
  end
end
