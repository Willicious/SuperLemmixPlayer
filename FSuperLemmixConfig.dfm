object FormNXConfig: TFormNXConfig
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Configuration'
  ClientHeight = 335
  ClientWidth = 279
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    279
    335)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TButton
    Left = 24
    Top = 302
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 104
    Top = 302
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnApply: TButton
    Left = 184
    Top = 302
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Apply'
    TabOrder = 2
    OnClick = btnApplyClick
  end
  object NXConfigPages: TPageControl
    Left = 0
    Top = 0
    Width = 279
    Height = 296
    ActivePage = TabSheet5
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object TabSheet1: TTabSheet
      Caption = 'General'
      object lblUserName: TLabel
        Left = 7
        Top = 16
        Width = 56
        Height = 13
        Caption = 'Your name:'
      end
      object GroupBox4: TGroupBox
        Left = 7
        Top = 104
        Width = 249
        Height = 106
        Caption = 'Replay Options'
        TabOrder = 2
        object lblIngameSaveReplay: TLabel
          Left = 28
          Top = 48
          Width = 45
          Height = 13
          Caption = 'In-game:'
        end
        object lblPostviewSaveReplay: TLabel
          Left = 28
          Top = 75
          Width = 48
          Height = 13
          Caption = 'Postview:'
        end
        object cbAutoSaveReplay: TCheckBox
          Left = 12
          Top = 19
          Width = 72
          Height = 17
          Caption = 'Auto-save:'
          TabOrder = 0
          OnClick = cbAutoSaveReplayClick
        end
        object cbAutoSaveReplayPattern: TComboBox
          Left = 90
          Top = 16
          Width = 145
          Height = 21
          ItemIndex = 1
          TabOrder = 1
          Text = 'Title + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp')
        end
        object cbIngameSaveReplayPattern: TComboBox
          Left = 90
          Top = 43
          Width = 145
          Height = 21
          TabOrder = 2
          Text = 'Position + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp'
            '(Show file selector)')
        end
        object cbPostviewSaveReplayPattern: TComboBox
          Left = 90
          Top = 70
          Width = 145
          Height = 21
          TabOrder = 3
          Text = 'Position + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp'
            '(Show file selector)')
        end
      end
      object btnHotkeys: TButton
        Left = 7
        Top = 48
        Width = 249
        Height = 42
        Caption = 'Configure Hotkeys'
        TabOrder = 1
        OnClick = btnHotkeysClick
      end
      object ebUserName: TEdit
        Left = 71
        Top = 13
        Width = 185
        Height = 21
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Interface'
      ImageIndex = 4
      object GroupBox3: TGroupBox
        Left = 12
        Top = 7
        Width = 249
        Height = 135
        TabOrder = 0
        object cbEdgeScrolling: TCheckBox
          Left = 12
          Top = 11
          Width = 221
          Height = 17
          Caption = 'Enable Edge Scrolling and Trap Cursor'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbNoAutoReplay: TCheckBox
          Left = 12
          Top = 34
          Width = 234
          Height = 17
          Caption = 'Don'#39't Replay After Backwards Frameskips'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbPauseAfterBackwards: TCheckBox
          Left = 12
          Top = 57
          Width = 173
          Height = 17
          Caption = 'Pause After Backwards Skip'
          TabOrder = 2
          OnClick = OptionChanged
        end
        object cbNoBackgrounds: TCheckBox
          Left = 12
          Top = 80
          Width = 153
          Height = 17
          Caption = 'Disable Background Images'
          TabOrder = 3
          OnClick = OptionChanged
        end
        object cbForceDefaultLemmings: TCheckBox
          Left = 12
          Top = 103
          Width = 173
          Height = 17
          Caption = 'Force Default Lemming Sprites'
          TabOrder = 4
          OnClick = OptionChanged
        end
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Input'
      ImageIndex = 4
      object cbClassicMode: TCheckBox
        Left = 64
        Top = 18
        Width = 135
        Height = 17
        Caption = 'Enable Classic Mode'
        TabOrder = 0
        OnClick = cbClassicModeClick
      end
      object GroupBox5: TGroupBox
        Left = 20
        Top = 49
        Width = 238
        Height = 72
        TabOrder = 1
        object cbHideShadows: TCheckBox
          Left = 12
          Top = 11
          Width = 153
          Height = 17
          Caption = 'Hide Skill Shadows'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbHideClearPhysics: TCheckBox
          Left = 12
          Top = 34
          Width = 125
          Height = 17
          Caption = 'Hide Clear Physics'
          TabOrder = 1
        end
      end
    end
    object Graphics: TTabSheet
      Caption = 'Graphics'
      ImageIndex = 3
      object GroupBox6: TGroupBox
        Left = 12
        Top = 6
        Width = 249
        Height = 254
        TabOrder = 0
        object Label1: TLabel
          Left = 11
          Top = 14
          Width = 32
          Height = 13
          Caption = 'Zoom:'
        end
        object Label2: TLabel
          Left = 11
          Top = 41
          Width = 31
          Height = 13
          Caption = 'Panel:'
        end
        object cbZoom: TComboBox
          Left = 56
          Top = 10
          Width = 177
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 0
          Text = '1x Zoom'
          OnChange = OptionChanged
          Items.Strings = (
            '1x Zoom')
        end
        object cbPanelZoom: TComboBox
          Left = 56
          Top = 37
          Width = 177
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 1
          Text = '1x Zoom'
          OnChange = OptionChanged
          Items.Strings = (
            '1x Zoom')
        end
        object cbFullScreen: TCheckBox
          Left = 12
          Top = 65
          Width = 205
          Height = 17
          Caption = 'Full Screen'
          TabOrder = 2
          OnClick = cbFullScreenClick
        end
        object cbResetWindowPosition: TCheckBox
          Left = 12
          Top = 88
          Width = 205
          Height = 17
          Caption = 'Reset Window Position'
          TabOrder = 3
          OnClick = OptionChanged
        end
        object cbResetWindowSize: TCheckBox
          Left = 12
          Top = 111
          Width = 205
          Height = 17
          Caption = 'Reset Window Size'
          TabOrder = 4
          OnClick = OptionChanged
        end
        object cbHighResolution: TCheckBox
          Left = 12
          Top = 134
          Width = 205
          Height = 17
          Caption = 'High Resolution'
          TabOrder = 5
          OnClick = OptionChanged
        end
        object cbIncreaseZoom: TCheckBox
          Left = 12
          Top = 157
          Width = 205
          Height = 17
          Caption = 'Increase Zoom On Small Levels'
          TabOrder = 6
          OnClick = OptionChanged
        end
        object cbLinearResampleMenu: TCheckBox
          Left = 12
          Top = 180
          Width = 205
          Height = 17
          Caption = 'Use Smooth Resampling In Menus'
          TabOrder = 7
          OnClick = OptionChanged
        end
        object cbLinearResampleGame: TCheckBox
          Left = 12
          Top = 203
          Width = 205
          Height = 17
          Caption = 'Use Smooth Resampling In Game'
          TabOrder = 8
          OnClick = OptionChanged
        end
        object cbMinimapHighQuality: TCheckBox
          Left = 12
          Top = 226
          Width = 153
          Height = 17
          Caption = 'High Quality Minimap'
          TabOrder = 9
          OnClick = OptionChanged
        end
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Audio'
      ImageIndex = 3
      object Label3: TLabel
        Left = 24
        Top = 45
        Width = 34
        Height = 13
        Caption = 'Sound'
      end
      object Label5: TLabel
        Left = 24
        Top = 75
        Width = 30
        Height = 13
        Caption = 'Music'
      end
      object Label6: TLabel
        Left = 16
        Top = 16
        Width = 39
        Height = 13
        Caption = 'Volume'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object tbSoundVol: TTrackBar
        Left = 64
        Top = 40
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 0
        OnChange = SliderChange
      end
      object tbMusicVol: TTrackBar
        Left = 64
        Top = 70
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 1
        OnChange = SliderChange
      end
      object cbDisableTestplayMusic: TCheckBox
        Left = 24
        Top = 109
        Width = 193
        Height = 17
        Caption = 'Disable Music When Testplaying'
        TabOrder = 2
        OnClick = OptionChanged
      end
    end
  end
end
