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
    Top = 39
    Width = 129
    Height = 25
    Caption = 'Add Colour'
    TabOrder = 0
    OnClick = ButtonAddClick
  end
  object ButtonGenerate: TButton
    Left = 8
    Top = 8
    Width = 688
    Height = 25
    Caption = 'Generate Scheme'
    TabOrder = 1
    OnClick = ButtonGenerateClick
  end
end
