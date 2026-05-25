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
    object Label1: TLabel
      Left = 1
      Top = 125
      Width = 183
      Height = 15
      Align = alTop
      Alignment = taCenter
      Caption = 'Label1'
      ExplicitTop = 94
      ExplicitWidth = 34
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
      ExplicitTop = 35
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
      ExplicitTop = 4
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
      ExplicitTop = 35
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
