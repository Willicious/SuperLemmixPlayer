object FReplayEditor: TFReplayEditor
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Replay Editor'
  ClientHeight = 441
  ClientWidth = 225
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
  PixelsPerInch = 96
  TextHeight = 13
  object lblLevelName: TLabel
    Left = 14
    Top = 8
    Width = 3
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold, fsUnderline]
    ParentFont = False
  end
  object lblFrame: TLabel
    Left = 14
    Top = 24
    Width = 195
    Height = 13
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold, fsUnderline]
    ParentFont = False
  end
  object btnOK: TButton
    Left = 32
    Top = 400
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 113
    Top = 400
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object lbReplayActions: TListBox
    Left = 8
    Top = 43
    Width = 209
    Height = 289
    Style = lbOwnerDrawVariable
    ItemHeight = 13
    TabOrder = 0
    OnClick = lbReplayActionsClick
    OnDblClick = lbReplayActionsDblClick
    OnDrawItem = lbReplayActionsDrawItem
    OnKeyDown = lbReplayActionsKeyDown
  end
  object btnDelete: TButton
    Left = 72
    Top = 338
    Width = 83
    Height = 25
    Caption = 'Delete'
    Enabled = False
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object btnGoToReplayEvent: TButton
    Left = 48
    Top = 369
    Width = 129
    Height = 25
    Caption = 'Go To Replay Event'
    TabOrder = 4
    OnClick = btnGoToReplayEventClick
  end
end
