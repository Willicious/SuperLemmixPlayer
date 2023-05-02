object FManageStyles: TFManageStyles
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSizeToolWin
  Caption = 'Style Manager'
  ClientHeight = 302
  ClientWidth = 401
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    401
    302)
  PixelsPerInch = 96
  TextHeight = 13
  object btnExit: TButton
    Left = 318
    Top = 271
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Exit'
    ModalResult = 2
    TabOrder = 0
    OnClick = btnExitClick
  end
  object lvStyles: TListView
    Left = 8
    Top = 8
    Width = 385
    Height = 233
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Style'
        Width = 156
      end
      item
        Caption = 'Installed'
        Width = 73
      end
      item
        Caption = 'Available'
        Width = 73
      end>
    ColumnClick = False
    GridLines = True
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnCustomDrawSubItem = lvStylesCustomDrawSubItem
  end
  object btnGetSelected: TButton
    Left = 8
    Top = 271
    Width = 105
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Download Selected'
    TabOrder = 2
    OnClick = btnGetSelectedClick
  end
  object btnUpdateAll: TButton
    Left = 230
    Top = 271
    Width = 82
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Update All'
    TabOrder = 3
    OnClick = btnUpdateAllClick
  end
  object pbDownload: TProgressBar
    Left = 8
    Top = 248
    Width = 385
    Height = 17
    Anchors = [akBottom]
    Max = 1000
    MarqueeInterval = 25
    TabOrder = 4
    Visible = False
  end
  object btnDownloadAll: TButton
    Left = 119
    Top = 271
    Width = 105
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Download All'
    TabOrder = 5
    OnClick = btnDownloadAllClick
  end
  object tmContinueDownload: TTimer
    Enabled = False
    Interval = 75
    OnTimer = tmContinueDownloadTimer
    Top = 240
  end
end
