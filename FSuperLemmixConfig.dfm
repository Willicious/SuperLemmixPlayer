object FormNXConfig: TFormNXConfig
  Left = 192
  Top = 125
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'SuperLemmix Configuration'
  ClientHeight = 378
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
    378)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TButton
    Left = 24
    Top = 345
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 104
    Top = 345
    Width = 65
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnApply: TButton
    Left = 184
    Top = 345
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
    Height = 339
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object TabSheet1: TTabSheet
      Caption = 'General'
      object lblUserName: TLabel
        Left = 11
        Top = 27
        Width = 56
        Height = 13
        Caption = 'Your name:'
      end
      object GroupBox4: TGroupBox
        Left = 11
        Top = 115
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
        Left = 11
        Top = 59
        Width = 249
        Height = 42
        Caption = 'Configure Hotkeys'
        TabOrder = 1
        OnClick = btnHotkeysClick
      end
      object ebUserName: TEdit
        Left = 75
        Top = 24
        Width = 185
        Height = 21
        TabOrder = 0
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Interface'
      ImageIndex = 4
      object cbClassicMode: TCheckBox
        Left = 72
        Top = 11
        Width = 135
        Height = 17
        Caption = 'Activate Classic Mode'
        TabOrder = 0
        OnClick = cbClassicModeClick
      end
      object GroupBox5: TGroupBox
        Left = 32
        Top = 34
        Width = 205
        Height = 152
        TabOrder = 2
        object cbHideShadows: TCheckBox
          Left = 12
          Top = 11
          Width = 190
          Height = 17
          Caption = 'Deactivate Skill Shadows'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbHideClearPhysics: TCheckBox
          Left = 12
          Top = 34
          Width = 190
          Height = 17
          Caption = 'Deactivate Clear Physics'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbHideAdvancedSelect: TCheckBox
          Left = 12
          Top = 57
          Width = 190
          Height = 17
          Caption = 'Deactivate Advanced Select'
          TabOrder = 2
          OnClick = OptionChanged
        end
        object cbHideFrameskipping: TCheckBox
          Left = 12
          Top = 80
          Width = 190
          Height = 17
          Caption = 'Deactivate Frameskipping'
          TabOrder = 3
          OnClick = OptionChanged
        end
        object cbHideHelpers: TCheckBox
          Left = 12
          Top = 103
          Width = 190
          Height = 17
          Caption = 'Deactivate Helper Overlays'
          TabOrder = 5
          OnClick = OptionChanged
        end
        object cbHideSkillQ: TCheckBox
          Left = 12
          Top = 126
          Width = 190
          Height = 17
          Caption = 'Deactivate Skill Queueing'
          TabOrder = 4
          OnClick = OptionChanged
        end
      end
      object GroupBox3: TGroupBox
        Left = 15
        Top = 192
        Width = 242
        Height = 105
        TabOrder = 1
        object cbEdgeScrolling: TCheckBox
          Left = 12
          Top = 11
          Width = 234
          Height = 17
          Caption = 'Activate Edge Scrolling and Trap Cursor'
          TabOrder = 0
          OnClick = OptionChanged
        end
        object cbNoAutoReplay: TCheckBox
          Left = 12
          Top = 34
          Width = 234
          Height = 17
          Caption = 'Replay After Backwards Frameskip'
          TabOrder = 1
          OnClick = OptionChanged
        end
        object cbPauseAfterBackwards: TCheckBox
          Left = 12
          Top = 57
          Width = 205
          Height = 17
          Caption = 'Pause After Backwards Frameskip'
          TabOrder = 2
          OnClick = OptionChanged
        end
        object cbNoBackgrounds: TCheckBox
          Left = 12
          Top = 80
          Width = 205
          Height = 17
          Caption = 'Deactivate Background Images'
          TabOrder = 3
          OnClick = OptionChanged
        end
      end
    end
    object Graphics: TTabSheet
      Caption = 'Graphics'
      ImageIndex = 3
      object Label1: TLabel
        Left = 62
        Top = 22
        Width = 32
        Height = 13
        Caption = 'Zoom:'
      end
      object Label2: TLabel
        Left = 62
        Top = 49
        Width = 31
        Height = 13
        Caption = 'Panel:'
      end
      object cbZoom: TComboBox
        Left = 100
        Top = 19
        Width = 97
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
        Left = 99
        Top = 46
        Width = 98
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
        Left = 30
        Top = 81
        Width = 205
        Height = 17
        Caption = 'Full Screen'
        TabOrder = 2
        OnClick = cbFullScreenClick
      end
      object cbResetWindowPosition: TCheckBox
        Left = 30
        Top = 104
        Width = 205
        Height = 17
        Caption = 'Reset Window Position'
        TabOrder = 3
        OnClick = OptionChanged
      end
      object cbResetWindowSize: TCheckBox
        Left = 30
        Top = 127
        Width = 205
        Height = 17
        Caption = 'Reset Window Size'
        TabOrder = 4
        OnClick = OptionChanged
      end
      object cbHighResolution: TCheckBox
        Left = 30
        Top = 150
        Width = 205
        Height = 17
        Caption = 'High Resolution'
        TabOrder = 5
        OnClick = OptionChanged
      end
      object cbIncreaseZoom: TCheckBox
        Left = 30
        Top = 173
        Width = 205
        Height = 17
        Caption = 'Increase Zoom On Small Levels'
        TabOrder = 6
        OnClick = OptionChanged
      end
      object cbLinearResampleMenu: TCheckBox
        Left = 30
        Top = 196
        Width = 205
        Height = 17
        Caption = 'Use Smooth Resampling In Menus'
        TabOrder = 7
        OnClick = OptionChanged
      end
      object cbLinearResampleGame: TCheckBox
        Left = 30
        Top = 219
        Width = 205
        Height = 17
        Caption = 'Use Smooth Resampling In Game'
        TabOrder = 8
        OnClick = OptionChanged
      end
      object cbMinimapHighQuality: TCheckBox
        Left = 30
        Top = 242
        Width = 153
        Height = 17
        Caption = 'High Quality Minimap'
        TabOrder = 9
        OnClick = OptionChanged
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Audio'
      ImageIndex = 3
      object Label3: TLabel
        Left = 28
        Top = 53
        Width = 34
        Height = 13
        Caption = 'Sound'
      end
      object Label5: TLabel
        Left = 28
        Top = 83
        Width = 30
        Height = 13
        Caption = 'Music'
      end
      object Label6: TLabel
        Left = 20
        Top = 24
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
        Left = 68
        Top = 48
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 0
        OnChange = SliderChange
      end
      object tbMusicVol: TTrackBar
        Left = 68
        Top = 78
        Width = 177
        Height = 33
        Max = 100
        Frequency = 10
        TabOrder = 1
        OnChange = SliderChange
      end
      object cbDisableTestplayMusic: TCheckBox
        Left = 28
        Top = 117
        Width = 193
        Height = 17
        Caption = 'Disable Music When Testplaying'
        TabOrder = 2
        OnClick = OptionChanged
      end
    end
  end
end
