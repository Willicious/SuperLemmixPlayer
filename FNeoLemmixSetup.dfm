object FNLSetup: TFNLSetup
  Left = 794
  Top = 419
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'NeoLemmix Setup'
  ClientHeight = 257
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
  PixelsPerInch = 96
  TextHeight = 13
  object SetupPages: TPageControl
    Left = 0
    Top = 0
    Width = 473
    Height = 217
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      TabVisible = False
      object Label1: TLabel
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
      object Label2: TLabel
        Left = 24
        Top = 48
        Width = 436
        Height = 13
        Caption = 
          'It appears that this is your first time using NeoLemmix, or that' +
          ' your configuration file is missing.'
      end
      object Label3: TLabel
        Left = 24
        Top = 80
        Width = 113
        Height = 13
        Caption = 'Please select an option:'
      end
      object rbConfigDefault: TRadioButton
        Left = 56
        Top = 104
        Width = 321
        Height = 17
        Caption = 'Use Default Configuration'
        Checked = True
        TabOrder = 0
        TabStop = True
        OnClick = rbConfigDefaultClick
      end
      object rbConfigDefaultLix: TRadioButton
        Tag = 1
        Left = 56
        Top = 128
        Width = 321
        Height = 17
        Caption = 'Use Default Configuration With Lix-Like Hotkey Setup'
        TabOrder = 1
        OnClick = rbConfigDefaultClick
      end
      object rbConfigCustom: TRadioButton
        Tag = 2
        Left = 56
        Top = 152
        Width = 321
        Height = 17
        Caption = 'Custom Configuration (not yet implemented)'
        Enabled = False
        TabOrder = 2
        OnClick = rbConfigDefaultClick
      end
      object rbConfigCustomLix: TRadioButton
        Tag = 3
        Left = 56
        Top = 176
        Width = 385
        Height = 17
        Caption = 
          'Custom Configuration With Lix-Like Hotkey Setup (not yet impleme' +
          'nted)'
        Enabled = False
        TabOrder = 3
        OnClick = rbConfigDefaultClick
      end
    end
  end
  object btnNext: TButton
    Left = 384
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Next'
    TabOrder = 1
    OnClick = btnNextClick
  end
  object btnBack: TButton
    Left = 304
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Back'
    Enabled = False
    TabOrder = 2
    OnClick = btnBackClick
  end
end
