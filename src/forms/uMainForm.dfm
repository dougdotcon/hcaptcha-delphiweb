object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'hCaptcha Solver'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 0
    object lblURL: TLabel
      Left = 8
      Top = 14
      Width = 23
      Height = 13
      Caption = 'URL:'
    end
    object edtURL: TEdit
      Left = 37
      Top = 11
      Width = 602
      Height = 21
      TabOrder = 0
    end
    object btnStart: TButton
      Left = 645
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Iniciar'
      TabOrder = 1
      OnClick = btnStartClick
    end
    object btnStop: TButton
      Left = 726
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Parar'
      TabOrder = 2
      OnClick = btnStopClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 441
    Width = 784
    Height = 120
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 1
    object mmLog: TMemo
      Left = 8
      Top = 8
      Width = 768
      Height = 85
      Align = alClient
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object StatusBar: TStatusBar
      Left = 8
      Top = 93
      Width = 768
      Height = 19
      Panels = <>
      SimplePanel = True
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 41
    Width = 784
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
  end
end 