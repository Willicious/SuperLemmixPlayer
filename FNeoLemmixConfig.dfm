object FormNXConfig: TFormNXConfig
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Configuration'
  ClientHeight = 385
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
    Height = 345
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'General Options'
      object GroupBox2: TGroupBox
        Left = 8
        Top = 8
        Width = 249
        Height = 57
        Caption = 'Input Options'
        TabOrder = 0
        object cbOneClickHighlight: TCheckBox
          Left = 12
          Top = 16
          Width = 129
          Height = 17
          Caption = 'One-Click Highlighting'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object btnHotkeys: TButton
          Left = 168
          Top = 18
          Width = 73
          Height = 25
          Caption = 'Set Hotkeys'
          TabOrder = 1
          OnClick = btnHotkeysClick
        end
        object cbPauseAfterBackwards: TCheckBox
          Left = 12
          Top = 32
          Width = 153
          Height = 17
          Caption = 'Pause After Backwards Skip'
          TabOrder = 2
          OnClick = OptionChanged
        end
      end
      object GroupBox3: TGroupBox
        Left = 8
        Top = 72
        Width = 249
        Height = 113
        Caption = 'Interface Options'
        TabOrder = 1
        object Label1: TLabel
          Left = 11
          Top = 88
          Width = 30
          Height = 13
          Caption = 'Zoom:'
        end
        object cbLemmingBlink: TCheckBox
          Left = 12
          Top = 16
          Width = 129
          Height = 17
          Caption = 'Lemming Count Blink'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbTimerBlink: TCheckBox
          Left = 12
          Top = 32
          Width = 129
          Height = 17
          Caption = 'Timer Blink'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbZoom: TComboBox
          Left = 56
          Top = 84
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
        object cbBlackOut: TCheckBox
          Left = 12
          Top = 48
          Width = 153
          Height = 17
          Caption = 'Black-Out Zero Skill Count'
          TabOrder = 3
          OnClick = OptionChanged
        end
        object cbNoBackgrounds: TCheckBox
          Left = 12
          Top = 64
          Width = 153
          Height = 17
          Caption = 'Disable Background Images'
          TabOrder = 4
          OnClick = OptionChanged
        end
      end
      object GroupBox4: TGroupBox
        Left = 8
        Top = 192
        Width = 249
        Height = 113
        Caption = 'Replay Options'
        TabOrder = 2
        object Label2: TLabel
          Left = 16
          Top = 64
          Width = 154
          Height = 13
          Caption = 'Manually-Saved Replay Naming:'
        end
        object cbAutoSaveReplay: TCheckBox
          Left = 12
          Top = 16
          Width = 217
          Height = 17
          Caption = 'Save Successful Replays Automatically'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbReplayNaming: TComboBox
          Left = 32
          Top = 80
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
          Left = 12
          Top = 32
          Width = 217
          Height = 17
          Caption = 'Only Cancel Replay On Cancel Key'
          TabOrder = 2
          OnClick = OptionChanged
        end
        object cbNoAutoReplay: TCheckBox
          Left = 12
          Top = 48
          Width = 225
          Height = 17
          Caption = 'Don'#39't Replay After Backwards Frameskips'
          TabOrder = 3
        end
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Audio Options'
      ImageIndex = 3
      object Label3: TLabel
        Left = 24
        Top = 45
        Width = 31
        Height = 13
        Caption = 'Sound'
      end
      object Label5: TLabel
        Left = 24
        Top = 75
        Width = 28
        Height = 13
        Caption = 'Music'
      end
      object Label6: TLabel
        Left = 16
        Top = 16
        Width = 42
        Height = 13
        Caption = 'Volume'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label7: TLabel
        Left = 16
        Top = 112
        Width = 104
        Height = 13
        Caption = 'Post-Level Jingles'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object tbSoundVol: TTrackBar
        Left = 64
        Top = 40
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 0
        OnChange = SliderChange
      end
      object tbMusicVol: TTrackBar
        Left = 64
        Top = 70
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 1
        OnChange = SliderChange
      end
      object cbSuccessJingle: TCheckBox
        Left = 28
        Top = 136
        Width = 129
        Height = 17
        Caption = 'Success'
        TabOrder = 2
        OnClick = OptionChanged
      end
      object cbFailureJingle: TCheckBox
        Left = 28
        Top = 160
        Width = 129
        Height = 17
        Caption = 'Failure'
        TabOrder = 3
        OnClick = OptionChanged
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
        OnClick = OptionChanged
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
    Top = 352
    Width = 65
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 104
    Top = 352
    Width = 65
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object btnApply: TButton
    Left = 184
    Top = 352
    Width = 65
    Height = 25
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
  end
end
