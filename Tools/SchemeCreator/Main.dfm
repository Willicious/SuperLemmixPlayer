object SchemeCreatorForm: TSchemeCreatorForm
  Left = 0
  Top = 0
  Caption = 'Scheme Creator'
  ClientHeight = 235
  ClientWidth = 704
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object LabelDuplicate: TLabel
    Left = 160
    Top = 74
    Width = 484
    Height = 13
    Caption = 
      'Duplicate hex code detected. Please ensure all codes are unique ' +
      'for the scheme to function correctly'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Visible = False
  end
  object ButtonAdd: TButton
    Left = 8
    Top = 69
    Width = 129
    Height = 25
    Caption = 'Add New Feature'
    TabOrder = 0
    OnClick = ButtonAddClick
  end
  object ButtonGenerateStateRecoloring: TButton
    Left = 8
    Top = 38
    Width = 688
    Height = 25
    Caption = 'Generate State Recoloring'
    TabOrder = 1
    OnClick = ButtonGenerateStateRecoloringClick
  end
  object ButtonGenerateSpritesetRecoloring: TButton
    Left = 8
    Top = 8
    Width = 688
    Height = 25
    Caption = 'Generate Spriteset Recoloring'
    TabOrder = 2
    OnClick = ButtonGenerateSpritesetRecoloringClick
  end
end
