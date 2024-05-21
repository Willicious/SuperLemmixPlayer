object FPlaybackMode: TFPlaybackMode
  Left = 0
  Top = 0
  Caption = 'Playback Mode'
  ClientHeight = 257
  ClientWidth = 411
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblSelectedFolder: TLabel
    Left = 57
    Top = 80
    Width = 90
    Height = 13
    Caption = 'Selected Folder:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblPlaybackCancelHotkey: TLabel
    Left = 176
    Top = 153
    Width = 138
    Height = 13
    Caption = 'Playback Cancel Hotkey:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object btnBrowse: TButton
    Left = 152
    Top = 43
    Width = 105
    Height = 31
    Caption = 'Browse'
    TabOrder = 0
    OnClick = btnBrowseClick
  end
  object stSelectedFolder: TStaticText
    Left = 157
    Top = 80
    Width = 212
    Height = 17
    Caption = '(Click Browse to choose a folder of replays)'
    TabOrder = 1
  end
  object rgPlaybackOrder: TRadioGroup
    Left = 41
    Top = 119
    Width = 97
    Height = 96
    Caption = 'Playback Order'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Items.Strings = (
      'By Replay'
      'By Level'
      'Random')
    ParentFont = False
    TabOrder = 2
  end
  object cbAutoskip: TCheckBox
    Left = 176
    Top = 119
    Width = 209
    Height = 17
    Caption = 'Auto-skip Preview && Postview Screens'
    TabOrder = 3
  end
  object stPlaybackCancelHotkey: TStaticText
    Left = 324
    Top = 153
    Width = 45
    Height = 17
    Caption = '(hotkey)'
    TabOrder = 4
  end
  object btnOK: TButton
    Left = 128
    Top = 224
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 209
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
  object stPackName: TStaticText
    AlignWithMargins = True
    Left = 0
    Top = 14
    Width = 409
    Height = 23
    Alignment = taCenter
    AutoSize = False
    Caption = '(pack name)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
  end
end
