object FQuickmodMain: TFQuickmodMain
  Left = 0
  Top = 0
  Anchors = []
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SuperLemmix QuickMod'
  ClientHeight = 451
  ClientWidth = 870
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
    870
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
  object cbPack: TComboBox
    Left = 40
    Top = 7
    Width = 822
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 64
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
      Width = 225
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
      Width = 225
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
      Width = 453
      Height = 94
      Caption = 'Talismans'
      TabOrder = 10
      object cbRemoveTalismans: TCheckBox
        Left = 260
        Top = 22
        Width = 145
        Height = 17
        Caption = 'Remove All Talismans'
        TabOrder = 0
        OnClick = cbStatCheckboxClicked
      end
      object cbAddKillZombiesTalisman: TCheckBox
        Left = 16
        Top = 68
        Width = 369
        Height = 17
        Caption = 'Add '#39'Kill All Zombies'#39' Talisman to all levels with Zombies'
        TabOrder = 1
      end
      object cbAddClassicModeTalisman: TCheckBox
        Left = 16
        Top = 22
        Width = 206
        Height = 17
        Caption = 'Add '#39'Play in Classic Mode'#39' Talisman'
        TabOrder = 2
      end
      object cbAddSaveAllTalisman: TCheckBox
        Left = 16
        Top = 45
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
    object gbNLConversions: TGroupBox
      Left = 16
      Top = 293
      Width = 453
      Height = 76
      Caption = 'For NeoLemmix-to-SuperLemmix Conversions'
      TabOrder = 14
      object cbUpdateWater: TCheckBox
        Left = 16
        Top = 22
        Width = 425
        Height = 17
        Caption = 
          'Replace Water Objects (orig_fire | orig_marble | ohno_bubble | o' +
          'hno_rock)'
        TabOrder = 0
      end
      object cbUpdateExitPositions: TCheckBox
        Left = 16
        Top = 45
        Width = 425
        Height = 17
        Caption = 
          'Update Orig/OhNo Exit Positions (NOTE - this should only be done' +
          ' ONCE per pack)'
        TabOrder = 1
      end
    end
  end
  object gbSkillset: TGroupBox
    Left = 503
    Top = 34
    Width = 359
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
    object gbSkillConversions: TGroupBox
      Left = 9
      Top = 293
      Width = 342
      Height = 76
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
      end
    end
  end
  object btnApply: TButton
    Left = 40
    Top = 418
    Width = 783
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Apply Changes To All Levels in Selected Pack'
    TabOrder = 3
    OnClick = btnApplyClick
  end
end
