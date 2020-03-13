object FLemmixHotkeys: TFLemmixHotkeys
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Hotkeys'
  ClientHeight = 441
  ClientWidth = 445
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblSkill: TLabel
    Left = 304
    Top = 131
    Width = 22
    Height = 13
    Caption = 'Skill:'
    Visible = False
  end
  object lblDuration: TLabel
    Left = 284
    Top = 155
    Width = 43
    Height = 13
    Caption = 'Duration:'
    Visible = False
  end
  object Label3: TLabel
    Left = 280
    Top = 72
    Width = 5
    Height = 13
    Alignment = taCenter
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSkip: TLabel
    Left = 301
    Top = 179
    Width = 24
    Height = 13
    Caption = 'Skip:'
    Visible = False
  end
  object lvHotkeys: TListView
    Left = 8
    Top = 8
    Width = 257
    Height = 425
    Columns = <
      item
        Caption = 'Key'
        MaxWidth = 74
        MinWidth = 74
        Width = 74
      end
      item
        AutoSize = True
        Caption = 'Function'
      end>
    ReadOnly = True
    TabOrder = 0
    ViewStyle = vsReport
    OnClick = lvHotkeysClick
    OnSelectItem = lvHotkeysSelectItem
  end
  object cbFunctions: TComboBox
    Left = 280
    Top = 96
    Width = 153
    Height = 21
    Style = csDropDownList
    Enabled = False
    TabOrder = 1
    OnChange = cbFunctionsChange
    Items.Strings = (
      'Nothing'
      'Select Skill'
      'Show Athlete Info'
      'Quit'
      'Max Release Rate'
      'Increase Release Rate'
      'Decrease Release Rate'
      'Min Release Rate'
      'Pause'
      'Nuke'
      'Save State'
      'Load State'
      'Highlight Lemming'
      'Directional Select Left'
      'Directional Select Right'
      'Select Walking Lemming'
      'Cheat'
      'Time Skip'
      'Special Skip'
      'Fast Forward'
      'Slow Motion'
      'Save Image'
      'Load Replay'
      'Save Replay'
      'Cancel Replay'
      'Edit Replay'
      'Replay Insert Mode'
      'Toggle Music'
      'Toggle Sound'
      'Restart Level'
      'Previous Skill'
      'Next Skill'
      'Release Mouse'
      'Clear Physics Mode'
      'Fall Distance Template'
      'Zoom In'
      'Zoom Out'
      'Hold-To-Scroll')
  end
  object btnClose: TButton
    Left = 312
    Top = 408
    Width = 89
    Height = 25
    Caption = 'Close'
    ModalResult = 1
    TabOrder = 2
  end
  object cbSkill: TComboBox
    Left = 336
    Top = 128
    Width = 97
    Height = 21
    Style = csDropDownList
    Enabled = False
    TabOrder = 3
    Visible = False
    OnChange = cbSkillChange
    Items.Strings = (
      'Walker'
      'Shimmier'
      'Climber'
      'Swimmer'
      'Floater'
      'Glider'
      'Disarmer'
      'Bomber'
      'Stoner'
      'Blocker'
      'Platformer'
      'Builder'
      'Stacker'
      'Basher'
      'Fencer'
      'Miner'
      'Digger'
      'Cloner')
  end
  object cbShowUnassigned: TCheckBox
    Left = 280
    Top = 24
    Width = 145
    Height = 17
    Caption = 'Show Unassigned Keys'
    TabOrder = 4
    OnClick = cbShowUnassignedClick
  end
  object ebSkipDuration: TEdit
    Left = 336
    Top = 152
    Width = 97
    Height = 21
    Enabled = False
    TabOrder = 5
    Visible = False
    OnChange = ebSkipDurationChange
  end
  object btnFindKey: TButton
    Left = 296
    Top = 264
    Width = 121
    Height = 25
    Caption = 'Find Key'
    TabOrder = 6
    OnClick = btnFindKeyClick
    OnKeyDown = btnFindKeyKeyDown
  end
  object cbHardcodedNames: TCheckBox
    Left = 280
    Top = 48
    Width = 145
    Height = 17
    Caption = 'Use Hardcoded Names'
    Checked = True
    State = cbChecked
    TabOrder = 7
    OnClick = cbHardcodedNamesClick
  end
  object cbHoldKey: TCheckBox
    Left = 312
    Top = 208
    Width = 97
    Height = 17
    Caption = 'Hold Key'
    TabOrder = 8
    Visible = False
    OnClick = cbHoldKeyClick
  end
  object cbSpecialSkip: TComboBox
    Left = 336
    Top = 176
    Width = 97
    Height = 21
    Style = csDropDownList
    Enabled = False
    TabOrder = 9
    Visible = False
    OnChange = cbSpecialSkipChange
    Items.Strings = (
      'Previous Assignment'
      'Next Shrugger'
      'Highlit State Change')
  end
  object btnFunctionalLayout: TButton
    Left = 284
    Top = 312
    Width = 141
    Height = 25
    Caption = 'Set to Functional Layout'
    TabOrder = 10
    OnClick = btnFunctionalLayoutClick
  end
  object btnTraditionalLayout: TButton
    Left = 284
    Top = 343
    Width = 141
    Height = 25
    Caption = 'Set to Traditional Layout'
    TabOrder = 11
    OnClick = btnTraditionalLayoutClick
  end
  object btnMinimalLayout: TButton
    Left = 284
    Top = 374
    Width = 141
    Height = 25
    Caption = 'Set to Minimal Layout'
    TabOrder = 12
    OnClick = btnMinimalLayoutClick
  end
end
