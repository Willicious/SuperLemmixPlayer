object FQuickmodMain: TFQuickmodMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'NL QuickMod'
  ClientHeight = 411
  ClientWidth = 251
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefault
  OnCreate = FormCreate
  DesignSize = (
    251
    411)
  PixelsPerInch = 96
  TextHeight = 13
  object lblPack: TLabel
    Left = 8
    Top = 11
    Width = 22
    Height = 13
    Caption = 'Pack'
  end
  object lblVersion: TLabel
    Left = 215
    Top = 390
    Width = 28
    Height = 13
    Alignment = taRightJustify
    Anchors = [akRight, akBottom]
    Caption = 'v0.03'
    ExplicitTop = 336
  end
  object cbPack: TComboBox
    Left = 48
    Top = 8
    Width = 195
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object gbStats: TGroupBox
    Left = 8
    Top = 43
    Width = 235
    Height = 264
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Level Stats'
    TabOrder = 1
    ExplicitHeight = 210
    object cbLemCount: TCheckBox
      Left = 16
      Top = 24
      Width = 130
      Height = 17
      Caption = 'Set Lemming Count:'
      TabOrder = 0
      OnClick = cbStatCheckboxClicked
    end
    object ebLemCount: TEdit
      Left = 152
      Top = 22
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 1
      Text = '50'
    end
    object cbSaveRequirement: TCheckBox
      Left = 16
      Top = 51
      Width = 130
      Height = 17
      Caption = 'Set Save Requirement:'
      TabOrder = 2
      OnClick = cbStatCheckboxClicked
    end
    object ebSaveRequirement: TEdit
      Left = 152
      Top = 49
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 3
      Text = '50'
    end
    object cbReleaseRate: TCheckBox
      Left = 16
      Top = 78
      Width = 130
      Height = 17
      Caption = 'Set Release Rate:'
      TabOrder = 4
      OnClick = cbStatCheckboxClicked
    end
    object ebReleaseRate: TEdit
      Left = 152
      Top = 76
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 5
      Text = '50'
    end
    object cbLockRR: TCheckBox
      Left = 32
      Top = 103
      Width = 81
      Height = 17
      Caption = 'Lock All RR'#39's'
      TabOrder = 6
      OnClick = cbLockRRClick
    end
    object cbUnlockRR: TCheckBox
      Left = 119
      Top = 103
      Width = 90
      Height = 17
      Caption = 'Unlock All RR'#39's'
      TabOrder = 7
      OnClick = cbLockRRClick
    end
    object cbTimeLimit: TCheckBox
      Left = 16
      Top = 128
      Width = 130
      Height = 17
      Caption = 'Set Time Limit:'
      TabOrder = 8
      OnClick = cbStatCheckboxClicked
    end
    object ebTimeLimit: TEdit
      Left = 152
      Top = 126
      Width = 57
      Height = 21
      Enabled = False
      NumbersOnly = True
      TabOrder = 9
      Text = '0'
    end
    object cbRemoveTalismans: TCheckBox
      Left = 16
      Top = 155
      Width = 130
      Height = 17
      Caption = 'Remove Talismans'
      TabOrder = 10
      OnClick = cbStatCheckboxClicked
    end
    object cbChangeID: TCheckBox
      Left = 16
      Top = 236
      Width = 130
      Height = 17
      Caption = 'Change Level IDs'
      TabOrder = 11
      OnClick = cbStatCheckboxClicked
    end
    object cbRemoveSpecialLemmings: TCheckBox
      Left = 16
      Top = 209
      Width = 201
      Height = 17
      Caption = 'Remove Zombies, Neutrals, Lem Caps'
      TabOrder = 12
      OnClick = cbStatCheckboxClicked
    end
    object cbRemovePreplaced: TCheckBox
      Left = 16
      Top = 182
      Width = 161
      Height = 17
      Caption = 'Remove Preplaced Lemmings'
      TabOrder = 13
      OnClick = cbStatCheckboxClicked
    end
  end
  object gbSkillset: TGroupBox
    Left = 8
    Top = 315
    Width = 235
    Height = 57
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Level Skillset'
    TabOrder = 2
    ExplicitTop = 261
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
    Left = 83
    Top = 378
    Width = 75
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
    ExplicitTop = 324
  end
end
