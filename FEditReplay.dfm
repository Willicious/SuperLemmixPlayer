object FReplayEditor: TFReplayEditor
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Replay Editor'
  ClientHeight = 554
  ClientWidth = 327
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
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
  object lblSelectEvents: TLabel
    Left = 8
    Top = 27
    Width = 257
    Height = 13
    AutoSize = False
    Caption = 'Select one or more events to edit'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblReplayInsertExplanation: TLabel
    Left = 8
    Top = 46
    Width = 283
    Height = 13
    Caption = 'Events in blue have been added via Replay Insert Mode'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Visible = False
  end
  object stFocus: TStaticText
    Left = 25
    Top = 176
    Width = 34
    Height = 17
    Caption = 'Focus'
    TabOrder = 6
  end
  object btnOK: TButton
    Left = 25
    Top = 510
    Width = 136
    Height = 36
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 167
    Top = 510
    Width = 130
    Height = 36
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object lbReplayActions: TListBox
    Left = 8
    Top = 72
    Width = 311
    Height = 306
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
    Left = 27
    Top = 412
    Width = 272
    Height = 36
    Caption = 'Delete Selected Replay Events'
    Enabled = False
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object btnGoToReplayEvent: TButton
    Left = 27
    Top = 454
    Width = 272
    Height = 36
    Caption = 'Skip To Selected Replay Event'
    TabOrder = 4
    OnClick = btnGoToReplayEventClick
  end
  object cbSelectFutureEvents: TCheckBox
    Left = 25
    Top = 384
    Width = 240
    Height = 17
    Caption = 'Select All Future Events For Lemming XYZ'
    TabOrder = 5
    Visible = False
    OnClick = cbSelectFutureEventsClick
  end
  object btnReplayInsertExplanation: TButton
    Left = 297
    Top = 41
    Width = 21
    Height = 25
    Caption = '?'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
    Visible = False
    OnClick = btnReplayInsertExplanationClick
  end
end
