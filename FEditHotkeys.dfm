object FLemmixHotkeys: TFLemmixHotkeys
  Left = 300
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Hotkeys'
  ClientHeight = 425
  ClientWidth = 513
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblSkill: TLabel
    Left = 347
    Top = 261
    Width = 24
    Height = 13
    Caption = 'Skill:'
    Visible = False
  end
  object lblDuration: TLabel
    Left = 327
    Top = 285
    Width = 49
    Height = 13
    Caption = 'Duration:'
    Visible = False
  end
  object Label3: TLabel
    Left = 320
    Top = 216
    Width = 3
    Height = 13
    Alignment = taCenter
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblSkip: TLabel
    Left = 344
    Top = 309
    Width = 25
    Height = 13
    Caption = 'Skip:'
    Visible = False
  end
  object lvHotkeys: TListView
    Left = 0
    Top = 0
    Width = 311
    Height = 425
    Columns = <
      item
        Caption = 'Key'
        MaxWidth = 140
        MinWidth = 140
        Width = 140
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
    Left = 316
    Top = 236
    Width = 197
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
      'Nuke (Timer Bypass)'
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
      'Rewind'
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
      'Show Used Skill Counts'
      'Fall Distance Template'
      'Zoom In'
      'Zoom Out'
      'Hold-To-Scroll')
  end
  object btnClose: TButton
    Left = 343
    Top = 374
    Width = 138
    Height = 41
    Caption = 'Save && Close'
    ModalResult = 1
    TabOrder = 2
  end
  object cbSkill: TComboBox
    Left = 379
    Top = 258
    Width = 129
    Height = 21
    Style = csDropDownList
    Enabled = False
    TabOrder = 3
    Visible = False
    OnChange = cbSkillChange
    Items.Strings = (
      'Walker'
      'Jumper'
      'Shimmier'
      'Slider'
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
      'Laserer'
      'Basher'
      'Fencer'
      'Miner'
      'Digger'
      'Cloner')
  end
  object cbShowUnassigned: TCheckBox
    Left = 345
    Top = 158
    Width = 145
    Height = 17
    Caption = 'Show Unassigned Keys'
    TabOrder = 4
    OnClick = cbShowUnassignedClick
  end
  object ebSkipDuration: TEdit
    Left = 379
    Top = 282
    Width = 129
    Height = 21
    Enabled = False
    TabOrder = 5
    Visible = False
    OnChange = ebSkipDurationChange
  end
  object btnFindKey: TButton
    Left = 347
    Top = 114
    Width = 138
    Height = 41
    Caption = 'Find Key'
    TabOrder = 6
    OnClick = btnFindKeyClick
    OnKeyDown = btnFindKeyKeyDown
  end
  object cbHardcodedNames: TCheckBox
    Left = 345
    Top = 181
    Width = 145
    Height = 17
    Caption = 'Use Hardcoded Names'
    Checked = True
    State = cbChecked
    TabOrder = 7
    OnClick = cbHardcodedNamesClick
  end
  object cbHoldKey: TCheckBox
    Left = 379
    Top = 342
    Width = 97
    Height = 17
    Caption = 'Hold Key'
    TabOrder = 8
    Visible = False
    OnClick = cbHoldKeyClick
  end
  object cbSpecialSkip: TComboBox
    Left = 379
    Top = 306
    Width = 129
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
  object btnClassicLayout: TButton
    Left = 347
    Top = 37
    Width = 138
    Height = 25
    Caption = 'Set to Classic Layout'
    TabOrder = 10
    OnClick = btnClassicLayoutClick
  end
  object btnAdvancedLayout: TButton
    Left = 347
    Top = 68
    Width = 138
    Height = 25
    Caption = 'Set to Advanced Layout'
    TabOrder = 11
    OnClick = btnAdvancedLayoutClick
  end
  object btnClearAllKeys: TButton
    Left = 347
    Top = 6
    Width = 138
    Height = 25
    Caption = 'Clear All Keys'
    TabOrder = 12
    OnClick = btnClearAllKeysClick
  end
end
