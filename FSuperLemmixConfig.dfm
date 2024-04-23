object FormNXConfig: TFormNXConfig
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Configuration'
  ClientHeight = 470
  ClientWidth = 276
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
    276
    470)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TButton
    Left = 11
    Top = 441
    Width = 80
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 97
    Top = 441
    Width = 80
    Height = 25
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnApply: TButton
    Left = 183
    Top = 441
    Width = 80
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Apply'
    TabOrder = 2
    OnClick = btnApplyClick
  end
  object NXConfigPages: TPageControl
    Left = 0
    Top = 0
    Width = 276
    Height = 439
    ActivePage = TabSheet2
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object TabSheet1: TTabSheet
      Caption = 'General'
      object lblUserName: TLabel
        Left = 13
        Top = 25
        Width = 56
        Height = 13
        Caption = 'Your name:'
      end
      object gbReplayNamingOptions: TGroupBox
        Left = 3
        Top = 142
        Width = 261
        Height = 167
        Caption = 'Replay Naming Options'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        object lblIngameSaveReplay: TLabel
          Left = 13
          Top = 71
          Width = 45
          Height = 13
          Caption = 'In-game:'
        end
        object lblPostviewSaveReplay: TLabel
          Left = 13
          Top = 115
          Width = 48
          Height = 13
          Caption = 'Postview:'
        end
        object cbAutoSaveReplay: TCheckBox
          Left = 13
          Top = 22
          Width = 72
          Height = 17
          Caption = 'Auto-save:'
          TabOrder = 0
          OnClick = cbAutoSaveReplayClick
        end
        object cbAutoSaveReplayPattern: TComboBox
          Left = 13
          Top = 44
          Width = 238
          Height = 21
          ItemIndex = 1
          TabOrder = 1
          Text = 'Title + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp'
            'Username + Position + Timestamp'
            'Username + Title + Timestamp'
            'Username + Position + Title + Timestamp')
        end
        object cbIngameSaveReplayPattern: TComboBox
          Left = 13
          Top = 88
          Width = 238
          Height = 21
          TabOrder = 2
          Text = 'Position + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp'
            'Username + Position + Timestamp'
            'Username + Title + Timestamp'
            'Username + Position + Title + Timestamp'
            '(Show file selector)')
        end
        object cbPostviewSaveReplayPattern: TComboBox
          Left = 13
          Top = 131
          Width = 238
          Height = 21
          TabOrder = 3
          Text = 'Position + Timestamp'
          OnChange = OptionChanged
          OnEnter = cbReplayPatternEnter
          Items.Strings = (
            'Position + Timestamp'
            'Title + Timestamp'
            'Position + Title + Timestamp'
            'Username + Position + Timestamp'
            'Username + Title + Timestamp'
            'Username + Position + Title + Timestamp'
            '(Show file selector)')
        end
      end
      object btnHotkeys: TButton
        Left = 16
        Top = 66
        Width = 238
        Height = 52
        Caption = 'Configure Hotkeys'
        TabOrder = 1
        OnClick = btnHotkeysClick
      end
      object ebUserName: TEdit
        Left = 75
        Top = 22
        Width = 178
        Height = 21
        TabOrder = 0
      end
      object rgGameLoading: TRadioGroup
        Left = 15
        Top = 315
        Width = 230
        Height = 72
        Caption = 'Game Loading Options'
        Items.Strings = (
          'Always Load Next Unsolved Level'
          'Always Load Most Recently Active Level')
        TabOrder = 3
        OnClick = OptionChanged
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Gameplay'
      ImageIndex = 4
      object cbEdgeScrolling: TCheckBox
        Left = 15
        Top = 12
        Width = 234
        Height = 17
        Caption = 'Activate Edge Scrolling and Trap Cursor'
        TabOrder = 0
        OnClick = OptionChanged
      end
      object cbPauseAfterBackwards: TCheckBox
        Left = 15
        Top = 35
        Width = 205
        Height = 17
        Caption = 'Pause After Backwards Frameskip'
        TabOrder = 1
        OnClick = OptionChanged
      end
      object gbClassicMode: TGroupBox
        Left = 3
        Top = 269
        Width = 256
        Height = 124
        Caption = 'Classic Mode Options'
        TabOrder = 2
        object cbClassicMode: TCheckBox
          Left = 16
          Top = 26
          Width = 156
          Height = 17
          Caption = 'Activate Classic Mode'
          TabOrder = 3
          OnClick = cbClassicModeClick
        end
        object cbHideShadows: TCheckBox
          Left = 16
          Top = 49
          Width = 190
          Height = 17
          Caption = 'Deactivate Skill Shadows'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbHideHelpers: TCheckBox
          Left = 16
          Top = 72
          Width = 190
          Height = 17
          Caption = 'Deactivate Helper Overlays'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbHideSkillQ: TCheckBox
          Left = 16
          Top = 95
          Width = 190
          Height = 17
          Caption = 'Deactivate Skill Queueing'
          TabOrder = 2
          OnClick = OptionChanged
        end
      end
      object gbReplayOptions: TGroupBox
        Left = 3
        Top = 74
        Width = 256
        Height = 75
        Caption = 'Replay Options'
        TabOrder = 4
        object cbReplayAfterRestart: TCheckBox
          Left = 12
          Top = 20
          Width = 217
          Height = 17
          Caption = 'Auto-Replay After Restarting Level'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbAutoReplay: TCheckBox
          Left = 12
          Top = 43
          Width = 234
          Height = 17
          Caption = 'Auto-Replay After Backwards Frameskip'
          TabOrder = 0
          OnClick = OptionChanged
        end
      end
      object gbSkillPanelOptions: TGroupBox
        Left = 3
        Top = 170
        Width = 256
        Height = 75
        Caption = 'Skill Panel Options'
        TabOrder = 3
        object cbTurboFF: TCheckBox
          Left = 12
          Top = 22
          Width = 177
          Height = 17
          Caption = 'Activate Turbo Fast-Forward'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbSpawnInterval: TCheckBox
          Left = 12
          Top = 45
          Width = 205
          Height = 17
          Caption = 'Activate Spawn Interval Display'
          TabOrder = 1
          OnClick = OptionChanged
        end
      end
    end
    object Graphics: TTabSheet
      Caption = 'Graphics'
      ImageIndex = 3
      object Label1: TLabel
        Left = 66
        Top = 20
        Width = 32
        Height = 13
        Caption = 'Zoom:'
      end
      object Label2: TLabel
        Left = 67
        Top = 47
        Width = 31
        Height = 13
        Caption = 'Panel:'
      end
      object cbZoom: TComboBox
        Left = 104
        Top = 17
        Width = 81
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 3
        Text = '1x Zoom'
        OnChange = OptionChanged
        Items.Strings = (
          '1x Zoom')
      end
      object cbPanelZoom: TComboBox
        Left = 104
        Top = 44
        Width = 81
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
        Left = 24
        Top = 80
        Width = 205
        Height = 17
        Caption = 'Full Screen'
        TabOrder = 2
        OnClick = cbFullScreenClick
      end
      object cbHighResolution: TCheckBox
        Left = 24
        Top = 103
        Width = 205
        Height = 17
        Caption = 'High Resolution'
        TabOrder = 6
        OnClick = OptionChanged
      end
      object cbIncreaseZoom: TCheckBox
        Left = 24
        Top = 126
        Width = 205
        Height = 17
        Caption = 'Increase Zoom On Small Levels'
        TabOrder = 4
        OnClick = OptionChanged
      end
      object cbLinearResampleMenu: TCheckBox
        Left = 24
        Top = 149
        Width = 205
        Height = 17
        Caption = 'Use Smooth Resampling In Menus'
        TabOrder = 5
        OnClick = OptionChanged
      end
      object gbMinimapOptions: TGroupBox
        Left = 24
        Top = 240
        Width = 219
        Height = 48
        Caption = 'Minimap Options'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        object cbMinimapHighQuality: TCheckBox
          Left = 117
          Top = 20
          Width = 90
          Height = 17
          Caption = 'High Quality'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbShowMinimap: TCheckBox
          Left = 14
          Top = 20
          Width = 97
          Height = 17
          Caption = 'Show Minimap'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnClick = cbShowMinimapClick
        end
      end
      object cbNoBackgrounds: TCheckBox
        Left = 24
        Top = 172
        Width = 205
        Height = 17
        Caption = 'Deactivate Background Images'
        TabOrder = 7
        OnClick = OptionChanged
      end
      object ResetWindow: TGroupBox
        Left = 24
        Top = 322
        Width = 219
        Height = 49
        TabOrder = 9
        object cbResetWindowPosition: TCheckBox
          Left = 14
          Top = 21
          Width = 97
          Height = 17
          Caption = 'Reset Position'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbResetWindowSize: TCheckBox
          Left = 117
          Top = 21
          Width = 90
          Height = 17
          Caption = 'Reset Size'
          TabOrder = 1
          OnClick = OptionChanged
        end
      end
      object btnResetWindow: TButton
        Left = 65
        Top = 306
        Width = 135
        Height = 34
        Caption = 'Reset Window'
        TabOrder = 8
        OnClick = btnResetWindowClick
      end
      object cbColourCycle: TCheckBox
        Left = 24
        Top = 195
        Width = 235
        Height = 17
        Caption = 'Use Colour Cycle For Fall Distance Ruler'
        TabOrder = 10
        OnClick = OptionChanged
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Audio'
      ImageIndex = 3
      DesignSize = (
        268
        411)
      object Label3: TLabel
        Left = 17
        Top = 32
        Width = 34
        Height = 13
        Caption = 'Sound'
      end
      object Label5: TLabel
        Left = 21
        Top = 75
        Width = 30
        Height = 13
        Caption = 'Music'
      end
      object tbSoundVol: TTrackBar
        Left = 51
        Top = 28
        Width = 206
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 0
        OnChange = SliderChange
      end
      object tbMusicVol: TTrackBar
        Left = 51
        Top = 71
        Width = 206
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 1
        OnChange = SliderChange
      end
      object cbDisableTestplayMusic: TCheckBox
        Left = 37
        Top = 124
        Width = 193
        Height = 17
        Caption = 'Disable Music When Testplaying'
        TabOrder = 2
        OnClick = OptionChanged
      end
      object rgExitSound: TRadioGroup
        Left = 72
        Top = 168
        Width = 113
        Height = 65
        Anchors = []
        Caption = 'Choose Exit Sound'
        Items.Strings = (
          'Yippee!'
          'Boing!')
        TabOrder = 3
        OnClick = OptionChanged
      end
      object gbMenuSounds: TGroupBox
        Left = 37
        Top = 256
        Width = 185
        Height = 81
        Caption = 'Menu Sounds'
        TabOrder = 4
        object cbPostviewJingles: TCheckBox
          Left = 14
          Top = 24
          Width = 155
          Height = 17
          Caption = 'Activate Postview Jingles'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbMenuSounds: TCheckBox
          Left = 14
          Top = 47
          Width = 155
          Height = 17
          Caption = 'Activate Menu Sounds'
          TabOrder = 1
          OnClick = OptionChanged
        end
      end
    end
  end
end
