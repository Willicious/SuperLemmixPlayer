object FormStyleUpdater: TFormStyleUpdater
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Style Updater'
  ClientHeight = 442
  ClientWidth = 545
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblHint: TLabel
    Left = 13
    Top = 368
    Width = 178
    Height = 13
    Caption = 'This is for displaying hints to the user'
  end
  object lvAvailableUpdates: TListView
    Left = 277
    Top = 13
    Width = 255
    Height = 340
    Columns = <
      item
        AutoSize = True
        Caption = 'Available Updates'
      end>
    MultiSelect = True
    ReadOnly = True
    TabOrder = 0
    ViewStyle = vsReport
    OnSelectItem = lvAvailableUpdatesSelectItem
  end
  object lvLocalStyles: TListView
    Left = 13
    Top = 13
    Width = 247
    Height = 340
    Columns = <
      item
        AutoSize = True
        Caption = 'Local Styles'
      end>
    ReadOnly = True
    TabOrder = 1
    ViewStyle = vsReport
  end
  object btnDownloadSelected: TButton
    Left = 226
    Top = 394
    Width = 202
    Height = 37
    Caption = 'Download Selected Styles'
    TabOrder = 2
    OnClick = btnDownloadSelectedClick
  end
  object btnDownloadAll: TButton
    Left = 13
    Top = 394
    Width = 207
    Height = 37
    Caption = 'Download All Available Styles'
    TabOrder = 3
    OnClick = btnDownloadAllClick
  end
  object btnClose: TButton
    Left = 434
    Top = 394
    Width = 98
    Height = 37
    Cancel = True
    Caption = 'Close'
    TabOrder = 4
    OnClick = btnCloseClick
  end
end
