object FNLSetup: TFNLSetup
  Left = 794
  Top = 419
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Setup'
  ClientHeight = 283
  ClientWidth = 473
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  DesignSize = (
    473
    283)
  PixelsPerInch = 96
  TextHeight = 13
  object SetupPages: TPageControl
    Left = 0
    Top = 0
    Width = 473
    Height = 238
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    ExplicitHeight = 217
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      TabVisible = False
      ExplicitHeight = 207
      object lblWelcome: TLabel
        Left = 16
        Top = 16
        Width = 197
        Height = 20
        Caption = 'Welcome to NeoLemmix!'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblOptionsText1: TLabel
        Left = 24
        Top = 48
        Width = 436
        Height = 13
        Caption = 
          'It appears that this is your first time using NeoLemmix, or that' +
          ' your configuration file is missing.'
      end
      object lblOptionsText2: TLabel
        Left = 24
        Top = 80
        Width = 342
        Height = 13
        Caption = 
          'Please select the desired options. You can always change them la' +
          'ter on.'
      end
      object lblHotkeys: TLabel
        Left = 24
        Top = 139
        Width = 76
        Height = 13
        Caption = 'Hotkey settings:'
      end
      object lblGraphics: TLabel
        Left = 24
        Top = 166
        Width = 79
        Height = 13
        Caption = 'Graphic settings:'
      end
      object lblUsername: TLabel
        Left = 24
        Top = 112
        Width = 54
        Height = 13
        Caption = 'Your name:'
      end
      object lblOnline: TLabel
        Left = 24
        Top = 193
        Width = 72
        Height = 13
        Caption = 'Online settings:'
      end
      object cbHotkey: TComboBox
        Left = 128
        Top = 136
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 1
        Text = 'Grouped by function'
        Items.Strings = (
          'Grouped by function'
          'Traditional layout'
          'Minimalist configuration')
      end
      object cbGraphics: TComboBox
        Left = 128
        Top = 163
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 2
        Text = 'Low-resolution, enhancements'
        Items.Strings = (
          'Low-resolution, no enhancements'
          'Low-resolution, enhancements'
          'High-resolution, no enhancements'
          'High-resolution, enhancements')
      end
      object ebUserName: TEdit
        Left = 128
        Top = 109
        Width = 217
        Height = 21
        TabOrder = 0
        Text = 'Anonymous'
      end
      object cbOnline: TComboBox
        Left = 128
        Top = 190
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 3
        Text = 'Online functions disabled'
        Items.Strings = (
          'Online functions disabled'
          'Online functions enabled'
          'Online + update check enabled')
      end
    end
  end
  object btnNext: TButton
    Left = 384
    Top = 245
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = btnOKClick
    ExplicitTop = 224
  end
  object btnExit: TButton
    Left = 304
    Top = 245
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Exit'
    TabOrder = 1
    OnClick = btnExitClick
    ExplicitTop = 224
  end
end
