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
    Caption = 'Exit'
    TabOrder = 0
    OnClick = btnExitClick
    ExplicitLeft = 239
  end
  object lvStyles: TListView
    Left = 8
    Top = 8
    Width = 385
    Height = 257
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
    ExplicitWidth = 306
  end
  object btnGetSelected: TButton
    Left = 8
    Top = 271
    Width = 105
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Download Selected'
    TabOrder = 2
  end
  object btnUpdateAll: TButton
    Left = 119
    Top = 271
    Width = 105
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Update All'
    TabOrder = 3
  end
end
