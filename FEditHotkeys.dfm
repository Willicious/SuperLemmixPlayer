object FLemmixHotkeys: TFLemmixHotkeys
  Left = 300
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Hotkeys'
  ClientHeight = 474
  ClientWidth = 519
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
    Left = 341
    Top = 263
    Width = 24
    Height = 13
    Caption = 'Skill:'
    Visible = False
  end
  object lblDuration: TLabel
    Left = 321
    Top = 287
    Width = 49
    Height = 13
    Caption = 'Duration:'
    Visible = False
  end
  object lblSkip: TLabel
    Left = 338
    Top = 311
    Width = 25
    Height = 13
    Caption = 'Skip:'
    Visible = False
  end
  object lblFindKey: TLabel
    Left = 321
    Top = 212
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
  object btnFindKey: TButton
    Left = 342
    Top = 133
    Width = 138
    Height = 40
    Caption = 'Find Key'
    TabOrder = 6
    OnClick = btnFindKeyClick
    OnKeyDown = btnFindKeyKeyDown
  end
  object lvHotkeys: TListView
    Left = -3
    Top = 0
    Width = 311
    Height = 468
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
    Left = 314
    Top = 233
    Width = 197
    Height = 21
    Style = csDropDownList
    DropDownCount = 14
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
      'Turbo Forward'
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
  object btnSaveClose: TButton
    Left = 342
    Top = 390
    Width = 138
    Height = 40
    Caption = 'Save && Close'
    ModalResult = 1
    TabOrder = 2
    OnClick = btnSaveCloseClick
  end
  object cbSkill: TComboBox
    Left = 373
    Top = 260
    Width = 129
    Height = 21
    Style = csDropDownList
    DropDownCount = 12
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
      'Timebomber'
      'Bomber'
      'Freezer'
      'Blocker'
      'Platformer'
      'Builder'
      'Stacker'
      'Spearer'
      'Grenader'
      'Laserer'
      'Basher'
      'Fencer'
      'Miner'
      'Digger'
      'Cloner')
  end
  object cbShowUnassigned: TCheckBox
    Left = 343
    Top = 181
    Width = 145
    Height = 17
    Caption = 'Show Unassigned Keys'
    TabOrder = 4
    OnClick = cbShowUnassignedClick
  end
  object ebSkipDuration: TEdit
    Left = 373
    Top = 284
    Width = 129
    Height = 21
    Enabled = False
    TabOrder = 5
    Visible = False
    OnChange = ebSkipDurationChange
  end
  object cbHardcodedNames: TCheckBox
    Left = 343
    Top = 367
    Width = 145
    Height = 17
    Caption = 'Use Hardcoded Names'
    Checked = True
    Enabled = False
    State = cbChecked
    TabOrder = 7
    Visible = False
    OnClick = cbHardcodedNamesClick
  end
  object cbHoldKey: TCheckBox
    Left = 378
    Top = 342
    Width = 97
    Height = 17
    Caption = 'Hold Key'
    TabOrder = 8
    Visible = False
    OnClick = cbHoldKeyClick
  end
  object cbSpecialSkip: TComboBox
    Left = 373
    Top = 308
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
    Left = 322
    Top = 51
    Width = 178
    Height = 25
    Caption = 'Set to Classic Layout'
    TabOrder = 10
    OnClick = btnClassicLayoutClick
  end
  object btnAdvancedLayout: TButton
    Left = 322
    Top = 76
    Width = 178
    Height = 25
    Caption = 'Set to Advanced Layout'
    TabOrder = 11
    OnClick = btnAdvancedLayoutClick
  end
  object btnClearAllKeys: TButton
    Left = 342
    Top = 5
    Width = 138
    Height = 40
    Caption = 'Clear All Keys'
    TabOrder = 12
    OnClick = btnClearAllKeysClick
  end
  object btnAlternativeLayout: TBitBtn
    Left = 322
    Top = 102
    Width = 178
    Height = 25
    Caption = 'Set to Alternative Layout'
    TabOrder = 13
    OnClick = btnAlternativeLayoutClick
  end
  object btnCancel: TBitBtn
    Left = 415
    Top = 436
    Width = 65
    Height = 30
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 14
    OnClick = btnCancelClick
  end
  object btnReset: TBitBtn
    Left = 342
    Top = 436
    Width = 67
    Height = 30
    Caption = 'Reset'
    TabOrder = 15
    OnClick = btnResetClick
  end
end
