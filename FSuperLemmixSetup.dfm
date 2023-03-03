object FNLSetup: TFNLSetup
  Left = 794
  Top = 419
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Setup'
  ClientHeight = 283
  ClientWidth = 473
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
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
      TabVisible = False
      object lblWelcome: TLabel
        Left = 16
        Top = 16
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
        Left = 24
        Top = 48
        Width = 500
        Height = 17
        Caption = 
          'It appears that this is your first time using SuperLemmix, or th' +
          'at your configuration file is missing.'
      end
      object lblOptionsText2: TLabel
        Left = 24
        Top = 80
        Width = 366
        Height = 13
        Caption = 
          'Please select the desired options. You can always change them la' +
          'ter on.'
      end
      object lblGraphics: TLabel
        Left = 24
        Top = 150
        Width = 87
        Height = 13
        Caption = 'Graphic settings:'
      end
      object lblUsername: TLabel
        Left = 24
        Top = 118
        Width = 56
        Height = 13
        Caption = 'Your name:'
      end
      object cbGraphics: TComboBox
        Left = 128
        Top = 147
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 1
        Text = 'Low-resolution, enhancements'
        Items.Strings = (
          'Low-resolution, no enhancements'
          'Low-resolution, enhancements'
          'High-resolution, no enhancements'
          'High-resolution, enhancements')
      end
      object ebUserName: TEdit
        Left = 128
        Top = 115
        Width = 217
        Height = 21
        TabOrder = 0
        Text = 'Anonymous'
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
  end
end
