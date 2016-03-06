object FormNXConfig: TFormNXConfig
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Configuration'
  ClientHeight = 417
  ClientWidth = 273
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object NXConfigPages: TPageControl
    Left = 0
    Top = 0
    Width = 273
    Height = 377
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Global Options'
      object GroupBox1: TGroupBox
        Left = 8
        Top = 8
        Width = 249
        Height = 57
        Caption = 'Audio Options'
        TabOrder = 0
        object cbMusic: TCheckBox
          Left = 16
          Top = 16
          Width = 97
          Height = 17
          Caption = 'Enable Music'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbSound: TCheckBox
          Left = 16
          Top = 32
          Width = 97
          Height = 17
          Caption = 'Enable Sound'
          TabOrder = 1
          OnClick = OptionChanged
        end
      end
      object GroupBox2: TGroupBox
        Left = 8
        Top = 72
        Width = 249
        Height = 57
        Caption = 'Input Options'
        TabOrder = 1
        object cbOneClickHighlight: TCheckBox
          Left = 16
          Top = 16
          Width = 129
          Height = 17
          Caption = 'One-Click Highlighting'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object btnHotkeys: TButton
          Left = 176
          Top = 18
          Width = 57
          Height = 25
          Caption = 'Hotkeys'
          TabOrder = 1
          OnClick = btnHotkeysClick
        end
        object cbIgnoreReplaySelection: TCheckBox
          Left = 16
          Top = 32
          Width = 161
          Height = 17
          Caption = 'Ignore Replay Skill Selection'
          TabOrder = 2
          OnClick = OptionChanged
        end
      end
      object GroupBox3: TGroupBox
        Left = 8
        Top = 136
        Width = 249
        Height = 97
        Caption = 'Interface Options'
        TabOrder = 2
        object Label1: TLabel
          Left = 11
          Top = 72
          Width = 30
          Height = 13
          Caption = 'Zoom:'
        end
        object cbLemmingBlink: TCheckBox
          Left = 16
          Top = 16
          Width = 129
          Height = 17
          Caption = 'Lemming Count Blink'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbTimerBlink: TCheckBox
          Left = 16
          Top = 32
          Width = 129
          Height = 17
          Caption = 'Timer Blink'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbZoom: TComboBox
          Left = 56
          Top = 68
          Width = 177
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 2
          Text = 'Fullscreen'
          OnChange = OptionChanged
          Items.Strings = (
            'Fullscreen')
        end
        object cbWhiteOut: TCheckBox
          Left = 16
          Top = 48
          Width = 153
          Height = 17
          Caption = 'White-Out Zero Skill Count'
          TabOrder = 3
          OnClick = OptionChanged
        end
      end
      object GroupBox4: TGroupBox
        Left = 8
        Top = 240
        Width = 249
        Height = 97
        Caption = 'Replay Options'
        TabOrder = 3
        object Label2: TLabel
          Left = 16
          Top = 48
          Width = 154
          Height = 13
          Caption = 'Manually-Saved Replay Naming:'
        end
        object cbAutoSaveReplay: TCheckBox
          Left = 16
          Top = 16
          Width = 217
          Height = 17
          Caption = 'Save Successful Replays Automatically'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbReplayNaming: TComboBox
          Left = 32
          Top = 64
          Width = 177
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 1
          Text = 'Auto, Overwrite Old File'
          OnChange = OptionChanged
          Items.Strings = (
            'Auto, Overwrite Old File'
            'Auto, Confirm Overwrite'
            'Auto, Add Timestamp'
            'Ask For Filename')
        end
        object cbExplicitCancel: TCheckBox
          Left = 16
          Top = 32
          Width = 217
          Height = 17
          Caption = 'Only Cancel Replay On Cancel Key'
          TabOrder = 2
          OnClick = OptionChanged
        end
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Online Options'
      ImageIndex = 2
      object cbEnableOnline: TCheckBox
        Left = 16
        Top = 16
        Width = 153
        Height = 17
        Caption = 'Enable Online Features'
        TabOrder = 0
        OnClick = cbEnableOnlineClick
      end
      object cbUpdateCheck: TCheckBox
        Left = 16
        Top = 40
        Width = 153
        Height = 17
        Caption = 'Enable Update Check'
        TabOrder = 1
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Game Options'
      ImageIndex = 1
      object GroupBox5: TGroupBox
        Left = 8
        Top = 16
        Width = 249
        Height = 89
        Caption = 'Debugging Options'
        TabOrder = 0
        object cbLookForLVL: TCheckBox
          Left = 16
          Top = 16
          Width = 113
          Height = 17
          Caption = 'Look For LVL Files'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbSteelDebug: TCheckBox
          Left = 16
          Top = 32
          Width = 113
          Height = 17
          Caption = 'Steel Debug'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbChallengeMode: TCheckBox
          Left = 16
          Top = 48
          Width = 113
          Height = 17
          Caption = 'Challenge Mode'
          TabOrder = 2
          OnClick = OptionChanged
        end
        object cbTimerMode: TCheckBox
          Left = 16
          Top = 64
          Width = 113
          Height = 17
          Caption = 'Timer Mode'
          TabOrder = 3
          OnClick = OptionChanged
        end
      end
      object GroupBox7: TGroupBox
        Left = 8
        Top = 112
        Width = 249
        Height = 97
        Caption = 'Forced Skillset'
        TabOrder = 1
        object Label4: TLabel
          Left = 16
          Top = 16
          Width = 55
          Height = 13
          Caption = 'Select Skill:'
        end
        object cbSkillList: TComboBox
          Left = 80
          Top = 14
          Width = 145
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 0
          Text = 'Walker'
          OnChange = cbSkillListChange
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
        object cbForceSkill: TCheckBox
          Left = 40
          Top = 40
          Width = 97
          Height = 17
          Caption = 'Force This Skill'
          TabOrder = 1
          OnClick = cbForceSkillClick
        end
        object btnCheckSkills: TButton
          Left = 32
          Top = 64
          Width = 89
          Height = 25
          Caption = 'Check Skills'
          TabOrder = 2
          OnClick = btnCheckSkillsClick
        end
        object btnClearSkill: TButton
          Left = 128
          Top = 64
          Width = 89
          Height = 25
          Caption = 'Clear Skills'
          TabOrder = 3
          OnClick = btnClearSkillClick
        end
      end
    end
  end
  object btnOK: TButton
    Left = 24
    Top = 384
    Width = 65
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 104
    Top = 384
    Width = 65
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object btnApply: TButton
    Left = 184
    Top = 384
    Width = 65
    Height = 25
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
  end
end
