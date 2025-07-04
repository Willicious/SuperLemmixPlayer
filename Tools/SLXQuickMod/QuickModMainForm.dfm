object FQuickmodMain: TFQuickmodMain
  Left = 0
  Top = 0
  Anchors = []
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SuperLemmix QuickMod'
  ClientHeight = 508
  ClientWidth = 902
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClick = FormClick
  OnCreate = FormCreate
  DesignSize = (
    902
    508)
  PixelsPerInch = 96
  TextHeight = 13
  object lblPack: TLabel
    Left = 12
    Top = 10
    Width = 22
    Height = 13
    Caption = 'Pack'
  end
  object cbPack: TComboBox
    Left = 40
    Top = 7
    Width = 854
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 64
    TabOrder = 0
  end
  object gbStats: TGroupBox
    Left = 8
    Top = 34
    Width = 497
    Height = 435
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Level Stats'
    TabOrder = 1
    object cbLemCount: TCheckBox
      Left = 16
      Top = 53
      Width = 130
      Height = 17
      Caption = 'Set Lemming Count:'
      TabOrder = 0
      OnClick = cbStatCheckboxClicked
    end
    object ebLemCount: TEdit
      Left = 152
      Top = 51
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 1
      Text = '50'
    end
    object cbSaveRequirement: TCheckBox
      Left = 16
      Top = 80
      Width = 130
      Height = 17
      Caption = 'Set Save Requirement:'
      TabOrder = 2
      OnClick = cbStatCheckboxClicked
    end
    object ebSaveRequirement: TEdit
      Left = 152
      Top = 78
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 3
      Text = '50'
    end
    object cbTimeLimit: TCheckBox
      Left = 16
      Top = 108
      Width = 130
      Height = 17
      Caption = 'Set Time Limit:'
      TabOrder = 5
      OnClick = cbStatCheckboxClicked
    end
    object ebTimeLimit: TEdit
      Left = 152
      Top = 106
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 7
      Text = '0'
    end
    object cbChangeID: TCheckBox
      Left = 324
      Top = 20
      Width = 129
      Height = 17
      Caption = 'Change All Level IDs'
      TabOrder = 9
      OnClick = cbStatCheckboxClicked
    end
    object cbRemoveSpecialLemmings: TCheckBox
      Left = 16
      Top = 162
      Width = 217
      Height = 17
      Caption = 'Remove Zombies, Neutrals, Lem Caps'
      TabOrder = 11
      OnClick = cbStatCheckboxClicked
    end
    object cbRemovePreplaced: TCheckBox
      Left = 16
      Top = 139
      Width = 161
      Height = 17
      Caption = 'Remove Preplaced Lemmings'
      TabOrder = 6
      OnClick = cbStatCheckboxClicked
    end
    object gbReleaseRate: TGroupBox
      Left = 244
      Top = 57
      Width = 237
      Height = 76
      Caption = 'Release Rate'
      TabOrder = 8
      object cbReleaseRate: TCheckBox
        Left = 16
        Top = 21
        Width = 130
        Height = 17
        Caption = 'Set Release Rate:'
        TabOrder = 0
        OnClick = cbStatCheckboxClicked
      end
      object ebReleaseRate: TEdit
        Left = 152
        Top = 19
        Width = 57
        Height = 21
        Enabled = False
        NumbersOnly = True
        TabOrder = 1
        Text = '50'
      end
      object cbLockRR: TCheckBox
        Left = 32
        Top = 44
        Width = 81
        Height = 17
        Caption = 'Lock All RR'#39's'
        TabOrder = 2
        OnClick = cbLockRRClick
      end
      object cbUnlockRR: TCheckBox
        Left = 119
        Top = 44
        Width = 90
        Height = 17
        Caption = 'Unlock All RR'#39's'
        TabOrder = 3
        OnClick = cbLockRRClick
      end
    end
    object gbSuperlemming: TGroupBox
      Left = 244
      Top = 139
      Width = 237
      Height = 48
      Caption = 'Superlemming Mode'
      TabOrder = 4
      object cbActivateSuperlemming: TCheckBox
        Left = 16
        Top = 21
        Width = 73
        Height = 17
        Caption = 'Activate'
        TabOrder = 0
        OnClick = cbSuperlemmingClick
      end
      object cbDeactivateSuperlemming: TCheckBox
        Left = 95
        Top = 21
        Width = 90
        Height = 17
        Caption = 'Deactivate'
        TabOrder = 1
        OnClick = cbSuperlemmingClick
      end
    end
    object gbTalismans: TGroupBox
      Left = 16
      Top = 193
      Width = 465
      Height = 151
      Caption = 'Talismans'
      TabOrder = 10
      object cbRemoveTalismans: TCheckBox
        Left = 16
        Top = 23
        Width = 145
        Height = 17
        Caption = 'Remove All Talismans'
        TabOrder = 0
        OnClick = cbStatCheckboxClicked
      end
      object cbAddKillZombiesTalisman: TCheckBox
        Left = 16
        Top = 100
        Width = 369
        Height = 17
        Caption = 'Add '#39'Kill All Zombies'#39' Talisman to all levels with Zombies'
        TabOrder = 1
      end
      object cbAddClassicModeTalisman: TCheckBox
        Left = 16
        Top = 54
        Width = 206
        Height = 17
        Caption = 'Add '#39'Play in Classic Mode'#39' Talisman'
        TabOrder = 2
      end
      object cbAddSaveAllTalisman: TCheckBox
        Left = 16
        Top = 77
        Width = 369
        Height = 17
        Caption = 'Add '#39'Save All Lemmings'#39' Talisman to all levels without Zombies'
        TabOrder = 3
      end
    end
    object cbChangeAuthor: TCheckBox
      Left = 16
      Top = 20
      Width = 97
      Height = 17
      Caption = 'Change Author:'
      TabOrder = 12
    end
    object ebAuthor: TEdit
      Left = 119
      Top = 18
      Width = 186
      Height = 21
      TabOrder = 13
    end
    object gbCrossPlatformConversions: TGroupBox
      Left = 16
      Top = 350
      Width = 465
      Height = 75
      Caption = 'Cross-Platform OG Style Swap'
      TabOrder = 14
      object lblConversionInfo: TLabel
        Left = 16
        Top = 21
        Width = 429
        Height = 13
        Caption = 
          'Swap between Orig/OhNo and SLX styles (auto-corrects water objec' +
          'ts and exit positions)'
      end
      object cbSwapStyles: TCheckBox
        Left = 16
        Top = 45
        Width = 97
        Height = 17
        Caption = 'Swap OG Styles'
        TabOrder = 0
        OnClick = cbSwapStylesClick
      end
      object rbNeoToSuper: TRadioButton
        Left = 119
        Top = 45
        Width = 161
        Height = 17
        Caption = 'NeoLemmix to SuperLemmix'
        Enabled = False
        TabOrder = 1
      end
      object rbSuperToNeo: TRadioButton
        Left = 286
        Top = 45
        Width = 161
        Height = 17
        Caption = 'SuperLemmix to NeoLemmix'
        Enabled = False
        TabOrder = 2
      end
    end
  end
  object btnApply: TButton
    Left = 40
    Top = 475
    Width = 815
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Apply Changes To All Levels in Selected Pack'
    TabOrder = 3
    OnClick = btnApplyClick
  end
  object gbSkills: TGroupBox
    Left = 504
    Top = 34
    Width = 390
    Height = 435
    Caption = 'Skills'
    TabOrder = 2
    OnClick = gbSkillsClick
    DesignSize = (
      390
      435)
    object gbCustomSkillset: TGroupBox
      Left = 13
      Top = 57
      Width = 366
      Height = 287
      Anchors = [akLeft, akRight, akBottom]
      Caption = 'Custom Skillset'
      TabOrder = 0
      object cbCustomSkillset: TCheckBox
        Left = 16
        Top = 21
        Width = 185
        Height = 17
        Caption = 'Apply Custom Skillset to All Levels'
        TabOrder = 0
        OnClick = cbCustomSkillsetClick
      end
    end
    object gbSkillConversions: TGroupBox
      Left = 13
      Top = 350
      Width = 366
      Height = 75
      Caption = 'Skill Conversions'
      TabOrder = 1
      object cbTimebomberToBomber: TCheckBox
        Left = 172
        Top = 22
        Width = 152
        Height = 17
        Caption = 'Timebombers to Bombers'
        TabOrder = 0
        OnClick = cbTimebomberChangeClick
      end
      object cbBomberToTimebomber: TCheckBox
        Left = 11
        Top = 22
        Width = 155
        Height = 17
        Caption = 'Bombers to Timebombers'
        TabOrder = 1
        OnClick = cbTimebomberChangeClick
      end
      object cbStonerToFreezer: TCheckBox
        Left = 11
        Top = 45
        Width = 129
        Height = 17
        Caption = 'Stoners to Freezers'
        TabOrder = 2
        OnClick = cbFreezerChangeClick
      end
      object cbFreezerToStoner: TCheckBox
        Left = 172
        Top = 45
        Width = 129
        Height = 17
        Caption = 'Freezers to Stoners'
        TabOrder = 3
        OnClick = cbFreezerChangeClick
      end
    end
    object cbSetAllSkillCounts: TCheckBox
      Left = 29
      Top = 24
      Width = 188
      Height = 17
      Caption = 'Set Skill Counts For All Levels To:'
      TabOrder = 2
      OnClick = cbSetAllSkillCountsClick
    end
    object seSkillCounts: TSpinEdit
      Left = 229
      Top = 24
      Width = 74
      Height = 22
      MaxValue = 100
      MinValue = 1
      TabOrder = 3
      Value = 20
      OnChange = seSkillCountsChange
      OnKeyDown = seSkillCountsKeyDown
    end
  end
end
