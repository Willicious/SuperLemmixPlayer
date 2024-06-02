object FLevelListDialog: TFLevelListDialog
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Select Level'
  ClientHeight = 188
  ClientWidth = 428
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object MatchingLevelsList: TListBox
    Left = 8
    Top = 8
    Width = 412
    Height = 137
    ItemHeight = 13
    TabOrder = 0
  end
  object btnSelect: TButton
    Left = 176
    Top = 153
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 1
    OnClick = btnSelectClick
  end
end
