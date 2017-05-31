object FLevelSelect: TFLevelSelect
  Left = 366
  Top = 210
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Level Select'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
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
    Font.Name = 'MS Sans Serif'
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
    Font.Name = 'MS Sans Serif'
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
    Font.Name = 'MS Sans Serif'
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
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
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
    Left = 560
    Top = 448
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 477
    Top = 447
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object pnLevelInfo: TPanel
    Left = 296
    Top = 128
    Width = 329
    Height = 313
    BevelOuter = bvNone
    Caption = '<placeholder for level info>'
    TabOrder = 3
  end
  object btnAddContent: TButton
    Left = 288
    Top = 448
    Width = 161
    Height = 25
    Caption = 'Add Content To List'
    TabOrder = 4
    OnClick = btnAddContentClick
  end
  object ilStatuses: TImageList
  end
end
