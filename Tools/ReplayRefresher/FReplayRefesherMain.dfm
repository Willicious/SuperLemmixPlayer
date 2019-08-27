object FNLReplayRefresher: TFNLReplayRefresher
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'NeoLemmix Replay Refresher'
  ClientHeight = 434
  ClientWidth = 250
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  DesignSize = (
    250
    434)
  PixelsPerInch = 96
  TextHeight = 13
  object lblUsername: TLabel
    Left = 16
    Top = 302
    Width = 52
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Username:'
    ExplicitTop = 312
  end
  object lblUsernameInfo: TLabel
    Left = 8
    Top = 334
    Width = 234
    Height = 43
    Anchors = [akLeft, akRight, akBottom]
    AutoSize = False
    Caption = 
      'Username will be added to replays that lack one. It will not ove' +
      'rride any existing username.'
    WordWrap = True
    ExplicitWidth = 224
  end
  object lbReplays: TListBox
    Left = 8
    Top = 8
    Width = 233
    Height = 247
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    MultiSelect = True
    Sorted = True
    TabOrder = 0
  end
  object btnAddReplay: TButton
    Left = 106
    Top = 261
    Width = 65
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Add'
    TabOrder = 1
    OnClick = btnAddReplayClick
    ExplicitLeft = 96
  end
  object btnRemoveReplay: TButton
    Left = 177
    Top = 261
    Width = 65
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Remove'
    TabOrder = 2
    OnClick = btnRemoveReplayClick
    ExplicitLeft = 167
  end
  object ebUsername: TEdit
    Left = 82
    Top = 299
    Width = 151
    Height = 21
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 3
    ExplicitTop = 309
  end
  object cbBackup: TCheckBox
    Left = 78
    Top = 382
    Width = 97
    Height = 17
    Anchors = [akBottom]
    Caption = 'Make Backups'
    Checked = True
    State = cbChecked
    TabOrder = 4
    ExplicitLeft = 73
  end
  object btnOK: TButton
    Left = 82
    Top = 401
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'OK'
    TabOrder = 5
    OnClick = btnOKClick
    ExplicitTop = 411
  end
end
