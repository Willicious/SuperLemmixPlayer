object Form1: TForm1
  Left = 276
  Top = 181
  Width = 352
  Height = 124
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object BtnSoundsOrig: TButton
    Left = 8
    Top = 48
    Width = 321
    Height = 25
    Caption = 'Build Sounds Resource'
    TabOrder = 0
    OnClick = BtnSoundsOrigClick
  end
  object btnFlexiData: TButton
    Left = 8
    Top = 8
    Width = 321
    Height = 25
    Caption = 'Build Default Data Resource'
    TabOrder = 1
    OnClick = BtnDataClick
  end
end
