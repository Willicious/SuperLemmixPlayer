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
    Left = 11
    Top = 8
    Width = 197
    Height = 13
  end
  object btnOK: TButton
    Left = 32
    Top = 392
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 120
    Top = 392
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
end
