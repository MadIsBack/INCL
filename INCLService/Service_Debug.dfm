object Form1: TForm1
  Left = 623
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'INCLService'
  ClientHeight = 491
  ClientWidth = 485
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 286
    Top = 79
    Width = 41
    Height = 16
    Caption = 'Label1'
  end
  object lblInfo: TLabel
    Left = 256
    Top = 15
    Width = 21
    Height = 16
    Caption = 'Info'
  end
  object CheckBox1: TCheckBox
    Left = 10
    Top = 10
    Width = 172
    Height = 21
    Caption = 'Connected'
    Enabled = False
    TabOrder = 0
    Visible = False
  end
  object Button4: TButton
    Left = 10
    Top = 39
    Width = 173
    Height = 31
    Caption = 'Recalc'
    TabOrder = 1
    OnClick = Button4Click
  end
  object Button3: TButton
    Left = 10
    Top = 79
    Width = 173
    Height = 31
    Caption = 'Zusatz'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button1: TButton
    Left = 10
    Top = 118
    Width = 173
    Height = 31
    Caption = 'Start Service'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 10
    Top = 158
    Width = 173
    Height = 30
    Caption = 'shift recalculation'
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button5: TButton
    Left = 197
    Top = 98
    Width = 123
    Height = 41
    Caption = 'Schichtwechsel'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Backup: TButton
    Left = 197
    Top = 158
    Width = 123
    Height = 30
    Caption = 'Backup'
    TabOrder = 6
    OnClick = BackupClick
  end
  object StartDT: TDateTimePicker
    Left = 197
    Top = 49
    Width = 123
    Height = 24
    CalAlignment = dtaLeft
    Date = 39640.3882067361
    Time = 39640.3882067361
    DateFormat = dfShort
    DateMode = dmComboBox
    Kind = dtkDate
    ParseInput = False
    TabOrder = 7
  end
  object ListBox1: TListBox
    Left = 15
    Top = 236
    Width = 459
    Height = 386
    ItemHeight = 16
    TabOrder = 8
  end
  object btn1: TButton
    Left = 331
    Top = 22
    Width = 133
    Height = 30
    Caption = 'AddOns Debug'
    TabOrder = 9
    OnClick = btn1Click
  end
  object Button6: TButton
    Left = 331
    Top = 62
    Width = 143
    Height = 30
    Caption = 'Schicht Debug'
    TabOrder = 10
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 335
    Top = 108
    Width = 139
    Height = 31
    Caption = 'SingleCycle'
    TabOrder = 11
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 335
    Top = 158
    Width = 70
    Height = 30
    Caption = 'A-Daten-X'
    TabOrder = 12
    OnClick = Button8Click
  end
  object CO_SpinEdit1: TCO_SpinEdit
    Left = 414
    Top = 158
    Width = 60
    Height = 70
    BevelOuter = bvNone
    Caption = 'CO_SpinEdit1'
    Color = clWhite
    TabOrder = 13
    Increment = 1
    MaxValue = 100
    MinValue = 0
    Value = 10
    Text = '10'
    ReadOnly = False
    MaxLength = 0
    DesignSize = (
      60
      70)
  end
  object Button9: TButton
    Left = 276
    Top = 197
    Width = 129
    Height = 31
    Caption = 'ProdStat X days ab'
    TabOrder = 14
    OnClick = Button9Click
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = Timer1Timer
    Left = 156
    Top = 4
  end
  object MemTimer: TTimer
    Interval = 30000
    OnTimer = MemTimerTimer
    Left = 240
  end
end
