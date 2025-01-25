object FReplayEditor: TFReplayEditor
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Replay Editor'
  ClientHeight = 525
  ClientWidth = 273
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblLevelName: TLabel
    Left = 8
    Top = 8
    Width = 77
    Height = 13
    Caption = '<Level Name>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblFrame: TLabel
    Left = 8
    Top = 27
    Width = 257
    Height = 13
    AutoSize = False
    Caption = '<Current Frame>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object stFocus: TStaticText
    Left = 25
    Top = 176
    Width = 216
    Height = 89
    Caption = 'Focus'
    TabOrder = 6
  end
  object btnOK: TButton
    Left = 25
    Top = 480
    Width = 106
    Height = 36
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 137
    Top = 480
    Width = 104
    Height = 36
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object lbReplayActions: TListBox
    Left = 8
    Top = 54
    Width = 257
    Height = 302
    Style = lbOwnerDrawVariable
    DoubleBuffered = True
    ItemHeight = 13
    MultiSelect = True
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = lbReplayActionsClick
    OnDblClick = lbReplayActionsDblClick
    OnDrawItem = lbReplayActionsDrawItem
    OnKeyDown = lbReplayActionsKeyDown
  end
  object btnDelete: TButton
    Left = 25
    Top = 396
    Width = 216
    Height = 36
    Caption = 'Delete Selected Replay Events'
    Enabled = False
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object btnGoToReplayEvent: TButton
    Left = 25
    Top = 438
    Width = 216
    Height = 36
    Caption = 'Skip To Selected Replay Event'
    TabOrder = 4
    OnClick = btnGoToReplayEventClick
  end
  object cbSelectFutureEvents: TCheckBox
    Left = 25
    Top = 370
    Width = 240
    Height = 17
    Caption = 'Select All Future Events For Lemming XYZ'
    TabOrder = 5
    Visible = False
    OnClick = cbSelectFutureEventsClick
  end
end
