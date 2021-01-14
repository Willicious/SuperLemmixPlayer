object FQuickmodMain: TFQuickmodMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'NL QuickMod'
  ClientHeight = 303
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
    303)
  PixelsPerInch = 96
  TextHeight = 13
  object lblPack: TLabel
    Left = 8
    Top = 11
    Width = 22
    Height = 13
    Caption = 'Pack'
  end
  object cbPack: TComboBox
    Left = 48
    Top = 8
    Width = 195
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    ExplicitWidth = 217
  end
  object gbStats: TGroupBox
    Left = 8
    Top = 43
    Width = 235
    Height = 156
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Level Stats'
    TabOrder = 1
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
  end
  object gbSkillset: TGroupBox
    Left = 8
    Top = 207
    Width = 235
    Height = 57
    Anchors = [akLeft, akTop, akRight]
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
    Left = 83
    Top = 270
    Width = 75
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
  end
end
