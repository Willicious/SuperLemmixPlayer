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
  object ButtonAdd: TButton
    Left = 8
    Top = 69
    Width = 129
    Height = 25
    Caption = 'Add Colour'
    TabOrder = 0
    OnClick = ButtonAddClick
  end
  object ButtonGenerateStateRecoloring: TButton
    Left = 8
    Top = 38
    Width = 688
    Height = 25
    Caption = 
      'Generate State Recoloring (Copy-paste/replace the output text in' +
      'to scheme.nxmi'#39's $STATE_RECOLORING section)'
    TabOrder = 1
    OnClick = ButtonGenerateStateRecoloringClick
  end
  object ButtonGenerateSpritesetRecoloring: TButton
    Left = 8
    Top = 8
    Width = 688
    Height = 25
    Caption = 
      'Generate Spriteset Recoloring (Copy-paste/replace the output tex' +
      't into scheme.nxmi'#39's $SPRITESET_RECOLORING section)'
    TabOrder = 2
    OnClick = ButtonGenerateSpritesetRecoloringClick
  end
end
