object FPlaybackMode: TFPlaybackMode
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Playback Mode'
  ClientHeight = 334
  ClientWidth = 421
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
    Top = 167
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
    Top = 229
    Width = 138
    Height = 13
    Hint = 
      'Press this hotkey at any time during playback to cancel playback' +
      ' mode.'#13#10'This hotkey can be changed in Settings > Configure Hotke' +
      'ys.'
    Caption = 'Playback Cancel Hotkey:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
  end
  object lblWelcome: TLabel
    Left = 33
    Top = 55
    Width = 352
    Height = 52
    Alignment = taCenter
    Caption = 
      'Welcome to Playback Mode!'#13#10'This feature automatically plays thro' +
      'ugh all replays in the selected folder.'#13#10#13#10'To begin, choose a fo' +
      'lder of replays to be played back.'
  end
  object btnBrowse: TButton
    Left = 153
    Top = 126
    Width = 105
    Height = 31
    Caption = 'Browse'
    TabOrder = 0
    OnClick = btnBrowseClick
  end
  object stSelectedFolder: TStaticText
    Left = 157
    Top = 167
    Width = 212
    Height = 17
    Caption = '(Click Browse to choose a folder of replays)'
    TabOrder = 1
  end
  object rgPlaybackOrder: TRadioGroup
    Left = 50
    Top = 196
    Width = 97
    Height = 96
    Hint = 
      'This setting orders the replays into a playlist.'#13#10#13#10'By Replay: P' +
      'lays the replays in the order that they appear in the folder.'#13#10'B' +
      'y Level: Plays the replays in the order that the levels appear i' +
      'n the selected pack.'#13#10'Random: Randomizes playback.'
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
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
  end
  object cbAutoskip: TCheckBox
    Left = 176
    Top = 196
    Width = 209
    Height = 17
    Hint = 
      'Check this to automatically skip past preview and postview scree' +
      'ns during playback.'
    Caption = 'Auto-skip Preview && Postview Screens'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
  end
  object stPlaybackCancelHotkey: TStaticText
    Left = 324
    Top = 229
    Width = 45
    Height = 17
    Hint = 
      'Press this hotkey at any time during playback to cancel playback' +
      ' mode.'#13#10'This hotkey can be changed in Settings > Configure Hotke' +
      'ys.'
    Caption = '(hotkey)'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
  end
  object btnBeginPlayback: TButton
    Left = 102
    Top = 300
    Width = 123
    Height = 25
    Caption = 'Begin Playback'
    ModalResult = 1
    TabOrder = 5
    OnClick = btnBeginPlaybackClick
  end
  object btnCancel: TButton
    Left = 231
    Top = 300
    Width = 96
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
  object stPackName: TStaticText
    AlignWithMargins = True
    Left = 0
    Top = 15
    Width = 409
    Height = 24
    Alignment = taCenter
    AutoSize = False
    Caption = '(pack name)'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Hobo Std'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
  end
end
