object FNLSetup: TFNLSetup
  Left = 794
  Top = 419
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Setup'
  ClientHeight = 283
  ClientWidth = 427
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  DesignSize = (
    427
    283)
  PixelsPerInch = 96
  TextHeight = 13
  object SetupPages: TPageControl
    Left = 0
    Top = 0
    Width = 427
    Height = 238
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      TabVisible = False
      object lblWelcome: TLabel
        Left = 103
        Top = 3
        Width = 206
        Height = 21
        Caption = 'Welcome to SuperLemmix!'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = lblWelcomeClick
      end
      object lblOptionsText1: TLabel
        Left = 63
        Top = 40
        Width = 287
        Height = 26
        Caption = 
          'It appears that this is your first time using SuperLemmix,'#13#10'or t' +
          'hat your configuration file is missing.'
      end
      object lblOptionsText2: TLabel
        Left = 23
        Top = 83
        Width = 366
        Height = 13
        Caption = 
          'Please select the desired options. You can always change them la' +
          'ter on.'
      end
      object lblGraphics: TLabel
        Left = 31
        Top = 141
        Width = 93
        Height = 13
        Caption = 'Graphics Settings:'
      end
      object lblUsername: TLabel
        Left = 31
        Top = 111
        Width = 57
        Height = 13
        Caption = 'Your Name:'
      end
      object lblGameplay: TLabel
        Left = 31
        Top = 171
        Width = 98
        Height = 13
        Caption = 'Gameplay Options:'
      end
      object lblHotkeys: TLabel
        Left = 31
        Top = 201
        Width = 84
        Height = 13
        Caption = 'Hotkey Options:'
      end
      object cbGraphics: TComboBox
        Left = 135
        Top = 138
        Width = 240
        Height = 21
        Style = csDropDownList
        ItemIndex = 3
        TabOrder = 1
        Text = 'High-resolution, enhancements'
        Items.Strings = (
          'Low-resolution, no enhancements'
          'Low-resolution, enhancements'
          'High-resolution, no enhancements'
          'High-resolution, enhancements')
      end
      object cbGameplay: TComboBox
        Left = 135
        Top = 168
        Width = 240
        Height = 21
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 3
        Text = 'Modern Mode'
        Items.Strings = (
          'Classic Mode'
          'Modern Mode')
      end
      object cbHotkeys: TComboBox
        Left = 136
        Top = 198
        Width = 240
        Height = 21
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 2
        Text = 'Advanced Hotkeys'
        Items.Strings = (
          'Classic Hotkeys'
          'Advanced Hotkeys')
      end
      object ebUserName: TEdit
        Left = 136
        Top = 108
        Width = 240
        Height = 21
        TabOrder = 0
        Text = 'Anonymous'
      end
    end
  end
  object btnNext: TButton
    Left = 107
    Top = 244
    Width = 151
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Save && Continue'
    Default = True
    TabOrder = 2
    OnClick = btnOKClick
  end
  object btnExit: TButton
    Left = 264
    Top = 244
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Exit'
    TabOrder = 1
    OnClick = btnExitClick
  end
end
