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
    ItemHeight = 13
    TabOrder = 1
    OnChange = cbFunctionsChange
    Items.Strings = (
      'Nothing'
      'Select Skill'
      'Select Unused Lemming'
      'Show Athlete Info'
      'Quit'
      'Increase Release Rate'
      'Decrease Release Rate'
      'Pause'
      'Nuke'
      'Save State'
      'Load State'
      'Highlight Lemming'
      'Directional Select Left'
      'Directional Select Right'
      'Select Walker'
      'Cheat'
      'Time Skip'
      'Fast Forward'
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
      'Fall Distance Template')
  end
  object Button1: TButton
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
    ItemHeight = 13
    TabOrder = 3
    Visible = False
    OnChange = cbSkillChange
    Items.Strings = (
      'Walker'
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
  object Button2: TButton
    Left = 296
    Top = 216
    Width = 121
    Height = 25
    Caption = 'Find Key'
    TabOrder = 6
    OnClick = Button2Click
    OnKeyDown = Button2KeyDown
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
    Top = 176
    Width = 97
    Height = 17
    Caption = 'Hold Key'
    TabOrder = 8
    Visible = False
    OnClick = cbHoldKeyClick
  end
end
