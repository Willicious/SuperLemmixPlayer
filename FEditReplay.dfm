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
  Font.Name = 'MS Sans Serif'
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
    Width = 5
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
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
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 120
    Top = 400
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object lbReplayActions: TListBox
    Left = 8
    Top = 32
    Width = 209
    Height = 225
    ItemHeight = 13
    TabOrder = 2
    OnClick = lbReplayActionsClick
  end
  object Panel1: TPanel
    Left = 8
    Top = 288
    Width = 209
    Height = 97
    BevelOuter = bvLowered
    Enabled = False
    TabOrder = 3
    Visible = False
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 32
      Height = 13
      Caption = 'Frame:'
    end
    object ebActionFrame: TEdit
      Left = 48
      Top = 5
      Width = 73
      Height = 21
      TabOrder = 0
    end
  end
  object btnDelete: TButton
    Left = 72
    Top = 260
    Width = 83
    Height = 25
    Caption = 'Delete'
    Enabled = False
    TabOrder = 4
    OnClick = btnDeleteClick
  end
end
