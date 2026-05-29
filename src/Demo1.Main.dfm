object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'qu3e Physics by Randy Gaul - Delphi version by Paul TOTH'
  ClientHeight = 560
  ClientWidth = 769
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 560
    Align = alLeft
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 0
    object lbAwake: TLabel
      Left = 1
      Top = 155
      Width = 183
      Height = 15
      Align = alTop
      Alignment = taCenter
      Caption = 'awakeCount'
      ExplicitWidth = 66
    end
    object lbIslands: TLabel
      Left = 1
      Top = 140
      Width = 183
      Height = 15
      Align = alTop
      Alignment = taCenter
      Caption = 'islandCount'
      ExplicitWidth = 64
    end
    object lbBodies: TLabel
      Left = 1
      Top = 125
      Width = 183
      Height = 15
      Align = alTop
      Alignment = taCenter
      Caption = 'bodyCount'
      ExplicitWidth = 60
    end
    object btTest: TButton
      Tag = 3
      AlignWithMargins = True
      Left = 4
      Top = 97
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'Test'
      TabOrder = 2
      OnClick = btTestClick
    end
    object btRayCast: TButton
      Tag = 1
      AlignWithMargins = True
      Left = 4
      Top = 35
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'RayPush'
      TabOrder = 1
      OnClick = btTestClick
    end
    object btDropBoxes: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'DropBoxes'
      TabOrder = 0
      OnClick = btTestClick
    end
    object btBoxStack: TButton
      Tag = 2
      AlignWithMargins = True
      Left = 4
      Top = 66
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'BoxStack'
      TabOrder = 3
      OnClick = btTestClick
    end
    object cbShowAABB: TCheckBox
      AlignWithMargins = True
      Left = 4
      Top = 539
      Width = 177
      Height = 17
      Align = alBottom
      Caption = 'show AABB'
      TabOrder = 4
      OnClick = cbShowAABBClick
    end
    object cbShowContact: TCheckBox
      AlignWithMargins = True
      Left = 4
      Top = 516
      Width = 177
      Height = 17
      Align = alBottom
      Caption = 'show Contacts'
      TabOrder = 5
      OnClick = cbShowContactClick
    end
    object cbShowLinks: TCheckBox
      AlignWithMargins = True
      Left = 4
      Top = 493
      Width = 177
      Height = 17
      Align = alBottom
      Caption = 'show Links'
      TabOrder = 6
      OnClick = cbShowLinksClick
    end
    object Panel2: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 173
      Width = 177
      Height = 32
      Align = alTop
      Caption = 'Panel2'
      ShowCaption = False
      TabOrder = 7
      object Label1: TLabel
        Left = 25
        Top = 8
        Width = 43
        Height = 15
        Caption = 'Freq: 1 /'
      end
      object seDT: TSpinEdit
        Left = 76
        Top = 5
        Width = 53
        Height = 24
        MaxValue = 120
        MinValue = 30
        TabOrder = 0
        Value = 60
        OnChange = seDTChange
      end
    end
    object Panel3: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 211
      Width = 177
      Height = 32
      Align = alTop
      Caption = 'Panel2'
      ShowCaption = False
      TabOrder = 8
      object Label2: TLabel
        Left = 18
        Top = 8
        Width = 49
        Height = 15
        Caption = 'Iterations'
      end
      object seIter: TSpinEdit
        Left = 76
        Top = 5
        Width = 53
        Height = 24
        MaxValue = 100
        MinValue = 1
        TabOrder = 0
        Value = 20
        OnChange = seIterChange
      end
    end
    object btSetup1: TButton
      Tag = 6020
      AlignWithMargins = True
      Left = 4
      Top = 249
      Width = 177
      Height = 25
      Align = alTop
      Caption = '1/60 x 20'
      TabOrder = 9
      OnClick = btSetup1Click
    end
    object dtSetup2: TButton
      Tag = 3002
      AlignWithMargins = True
      Left = 4
      Top = 280
      Width = 177
      Height = 25
      Align = alTop
      Caption = '1/30 x 2'
      TabOrder = 10
      OnClick = btSetup1Click
    end
    object Button1: TButton
      AlignWithMargins = True
      Left = 4
      Top = 311
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'Reload'
      TabOrder = 11
      OnClick = btSetup1Click
    end
  end
  inline GLPanel: TGLPanel
    Left = 185
    Top = 0
    Width = 584
    Height = 560
    Align = alClient
    TabOrder = 1
    ExplicitLeft = 185
    ExplicitWidth = 584
    ExplicitHeight = 560
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 376
    Top = 288
  end
end
