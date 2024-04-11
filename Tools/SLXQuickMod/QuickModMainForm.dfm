object FQuickmodMain: TFQuickmodMain
  Left = 0
  Top = 0
  Anchors = []
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SuperLemmix QuickMod'
  ClientHeight = 451
  ClientWidth = 827
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    827
    451)
  PixelsPerInch = 96
  TextHeight = 13
  object lblPack: TLabel
    Left = 12
    Top = 10
    Width = 22
    Height = 13
    Caption = 'Pack'
  end
  object lblVersion: TLabel
    Left = 797
    Top = 430
    Width = 22
    Height = 13
    Alignment = taRightJustify
    Anchors = [akRight, akBottom]
    Caption = 'v1.4'
  end
  object cbPack: TComboBox
    Left = 40
    Top = 7
    Width = 779
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object gbStats: TGroupBox
    Left = 8
    Top = 34
    Width = 481
    Height = 378
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Level Stats'
    TabOrder = 1
    object cbLemCount: TCheckBox
      Left = 16
      Top = 59
      Width = 130
      Height = 17
      Caption = 'Set Lemming Count:'
      TabOrder = 0
      OnClick = cbStatCheckboxClicked
    end
    object ebLemCount: TEdit
      Left = 152
      Top = 57
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 1
      Text = '50'
    end
    object cbSaveRequirement: TCheckBox
      Left = 16
      Top = 86
      Width = 130
      Height = 17
      Caption = 'Set Save Requirement:'
      TabOrder = 2
      OnClick = cbStatCheckboxClicked
    end
    object ebSaveRequirement: TEdit
      Left = 152
      Top = 84
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 3
      Text = '50'
    end
    object cbTimeLimit: TCheckBox
      Left = 16
      Top = 114
      Width = 130
      Height = 17
      Caption = 'Set Time Limit:'
      TabOrder = 5
      OnClick = cbStatCheckboxClicked
    end
    object ebTimeLimit: TEdit
      Left = 152
      Top = 112
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
      Top = 180
      Width = 217
      Height = 17
      Caption = 'Remove Zombies, Neutrals, Lem Caps'
      TabOrder = 11
      OnClick = cbStatCheckboxClicked
    end
    object cbRemovePreplaced: TCheckBox
      Left = 16
      Top = 157
      Width = 161
      Height = 17
      Caption = 'Remove Preplaced Lemmings'
      TabOrder = 6
      OnClick = cbStatCheckboxClicked
    end
    object gbReleaseRate: TGroupBox
      Left = 244
      Top = 55
      Width = 225
      Height = 78
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
      Top = 157
      Width = 225
      Height = 53
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
      Top = 236
      Width = 453
      Height = 133
      Caption = 'Talismans'
      TabOrder = 10
      object cbRemoveTalismans: TCheckBox
        Left = 168
        Top = 16
        Width = 145
        Height = 17
        Caption = 'Remove All Talismans'
        TabOrder = 0
        OnClick = cbStatCheckboxClicked
      end
      object cbAddKillZombiesTalisman: TCheckBox
        Left = 16
        Top = 85
        Width = 369
        Height = 17
        Caption = 'Add '#39'Kill All Zombies'#39' Talisman to all levels with Zombies'
        TabOrder = 1
      end
      object cbAddClassicModeTalisman: TCheckBox
        Left = 16
        Top = 39
        Width = 206
        Height = 17
        Caption = 'Add '#39'Play in Classic Mode'#39' Talisman'
        TabOrder = 2
      end
      object cbAddNoPauseTalisman: TCheckBox
        Left = 16
        Top = 108
        Width = 201
        Height = 17
        Caption = 'Add '#39'No Pressing Pause'#39' Talisman'
        TabOrder = 3
      end
      object cbAddSaveAllTalisman: TCheckBox
        Left = 16
        Top = 62
        Width = 369
        Height = 17
        Caption = 'Add '#39'Save All Lemmings'#39' Talisman to all levels without Zombies'
        TabOrder = 4
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
    object cbUpdateWater: TCheckBox
      Left = 16
      Top = 203
      Width = 149
      Height = 17
      Caption = 'Replace Water Objects'
      TabOrder = 14
    end
  end
  object gbSkillset: TGroupBox
    Left = 503
    Top = 34
    Width = 316
    Height = 378
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Level Skillset'
    TabOrder = 2
    object cbCustomSkillset: TCheckBox
      Left = 16
      Top = 20
      Width = 130
      Height = 17
      Caption = 'Apply Custom Skillset'
      TabOrder = 0
      OnClick = cbCustomSkillsetClick
    end
  end
  object btnApply: TButton
    Left = 40
    Top = 418
    Width = 740
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Apply Changes To All Levels in Selected Pack'
    TabOrder = 3
    OnClick = btnApplyClick
  end
end
