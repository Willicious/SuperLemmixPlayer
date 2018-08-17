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
      ExplicitHeight = 163
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
        Width = 342
        Height = 13
        Caption = 
          'Please select the desired options. You can always change them la' +
          'ter on.'
      end
      object Label4: TLabel
        Left = 24
        Top = 107
        Width = 76
        Height = 13
        Caption = 'Hotkey settings:'
      end
      object Label5: TLabel
        Left = 24
        Top = 134
        Width = 79
        Height = 13
        Caption = 'Graphic settings:'
      end
      object cbHotkey: TComboBox
        Left = 128
        Top = 104
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'Grouped by function'
        Items.Strings = (
          'Grouped by function'
          'Traditional layout')
      end
      object cbGraphics: TComboBox
        Left = 128
        Top = 131
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 1
        Text = 'Normal quality (for standard computers)'
        Items.Strings = (
          'High quality (for fast computers)'
          'Normal quality (for standard computers)')
      end
    end
  end
  object btnNext: TButton
    Left = 384
    Top = 224
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOKClick
  end
  object btnExit: TButton
    Left = 304
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Exit'
    TabOrder = 2
    OnClick = btnExitClick
  end
end
