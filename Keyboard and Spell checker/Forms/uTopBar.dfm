object TopBar: TTopBar
  Left = 256
  Top = 260
  AlphaBlend = True
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 240
  ClientWidth = 533
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001001010000001002000680400001600000028000000100000002000
    0000010020000000000040040000000000000000000000000000000000000000
    00007415376081173DDD83193EFC891B43FE94244CFF99234DFFA02653FFA729
    57FFAD2959FFB52E60FFBA2A5FFEC32C64FCD0306BDDCC2F6A60000000007715
    385E82183EFF891B43FF891640FF9C3258FFE3C1CEFFCD88A1FFD9A3B7FFE1AB
    BEFFD586A3FFECC5D3FFCB4677FFC92963FFD73470FFE23675FFDE33745E821A
    3FE68C1C44FF8F1C45FC961F4AFF9E234FFFAB325EFFAF2E5DFFB73464FFBE37
    69FFC33569FFCD3B70FFCF326CFFD5326EFFDB3472FCEA387AFFE83979E68C1D
    45FF93214AFF9A234EFFA0214FFFA72453FFAC2254FFB5285BFFBC2C61FFC32C
    63FFCA2E67FFC63369FFD4336EFFE03574FFE73778FFEB3E7CFFEA4278FF951E
    49FE9C204DFFA42654FFAB2858FFB12759FFB92E61FFC13266FFC63067FFCD2E
    68FFD8467BFFDDA5BAFFD93270FFEC3A7CFFEB417CFFE74575FFE3496DFE9F21
    4FFFA62353FFAD2657FFB5295CFFBC2E62FFC33167FFCC2F69FFD2336DFFD52C
    6AFFE45187FFE9B9CBFFE13372FFEC447BFFE54671FFE24C6BFFDE5467FFAB2A
    59FFB1285AFFB7285CFFBE2C62FFC63067FFCB2F68FFC52C64FFD42F6BFFE437
    77FFEB4B87FFE8B3C6FFDE3C6EFFE6496FFFE0516BFFDD5A68FFDA6163FFB429
    5CFFBC3063FFC23065FFC83068FFCF2E69FFDB3A76FFE8C1CFFFC56B8CFFDF25
    69FFF3558AFFE4AFBDFFD94766FFE2576CFFDC5D66FFD8615EFFD4685AFFBD2A
    60FFC42D64FFCC336BFFD3336EFFD63D75FFC82B65FFEEA6C1FFF9FEFEFFC563
    81FFDA5376FFE7C4CAFFD34E5EFFDC5F63FFD6645CFFD36B57FFCF6F50FFC72E
    66FFCE306AFFD5346FFFDB2D6DFFEB81A8FFEBE5E7FFD77F9BFFEC6388FFF1E1
    E3FFE3CBD1FFE2BCBEFFCF5352FFD7685CFFD16E56FFCD714DFFC97848FFD234
    6EFFD83470FFE03A77FFE63577FFED4E86FFFEEAF1FFD9AFBCFFC55F77FFEBC8
    CFFFEDABABFFDAABABFFBE6C60FFD07052FFCB744BFFC77B45FFC48140FFDB38
    74FEE33978FFE9397AFFEB3F7BFFE74172FFE45073FFEFA2AEFFECB9BBFFDF82
    81FFD35D54FFEDD8D3FFD49E86FFC87243FFC77F45FFC3853FFFC08C3CFEE638
    79FFEA3C7BFFEA4279FFE64872FFE24E6DFFDE5164FFD84C56FFD55350FFD15C
    4BFFD47B62FFCF8E6FFFC6713BFFC68445FFC2893FFFBD8E39FFBA9432FFE93B
    78E6EE4378FFE3486EFCE04F69FFDD5664FFD95D60FFD6655CFFD26C57FFCE71
    50FFCA764AFFC77D44FFC38440FFBF8939FFBB8F34FCBD9B2FFFB49C29E6E346
    715EEB4F71FFE45569FFDA5961FFD75F5DFFD46657FFD06C52FFCC734CFFC979
    47FFC58042FFC1863DFFBE8D37FFBA9331FFBB9E2DFFB9A728FFB0A2235E0000
    0000DC526460E35E64DDD8635BFCD26855FECE6F50FFCB754AFFC77C45FFC482
    3FFFC0893AFFBC8F35FFB8952FFEB79D2AFCB8A826DDACA41F6000000000C003
    0000800100000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000080010000C0030000}
  KeyPreview = True
  Position = poDesigned
  Scaled = False
  ScreenSnap = True
  SnapBuffer = 32
  OnClose = FormClose
  OnCreate = FormCreate
  OnHide = FormHide
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 13
  object ImgMain: TImage
    Left = 24
    Top = 16
    Width = 361
    Height = 41
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
  end
  object ImgAppIcon: TImage
    Left = 24
    Top = 72
    Width = 33
    Height = 33
    Cursor = crMultiDrag
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgAppIconDblClick
    OnMouseDown = ImgAppIconMouseDown
    OnMouseEnter = ImgAppIconMouseEnter
    OnMouseLeave = ImgAppIconMouseLeave
    OnMouseUp = ImgAppIconMouseUp
  end
  object ImgButtonMode: TImage
    Left = 63
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonModeDblClick
    OnMouseDown = ImgButtonModeMouseDown
    OnMouseEnter = ImgButtonModeMouseEnter
    OnMouseLeave = ImgButtonModeMouseLeave
    OnMouseUp = ImgButtonModeMouseUp
  end
  object ImgButtonLayoutDown: TImage
    Left = 104
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonLayoutDownDblClick
    OnMouseDown = ImgButtonLayoutDownMouseDown
    OnMouseEnter = ImgButtonLayoutDownMouseEnter
    OnMouseLeave = ImgButtonLayoutDownMouseLeave
    OnMouseUp = ImgButtonLayoutDownMouseUp
  end
  object ImgButtonLayout: TImage
    Left = 137
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonLayoutDblClick
    OnMouseDown = ImgButtonLayoutMouseDown
    OnMouseEnter = ImgButtonLayoutMouseEnter
    OnMouseLeave = ImgButtonLayoutMouseLeave
    OnMouseUp = ImgButtonLayoutMouseUp
  end
  object ImgButtonMouse: TImage
    Left = 192
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonMouseDblClick
    OnMouseDown = ImgButtonMouseMouseDown
    OnMouseEnter = ImgButtonMouseMouseEnter
    OnMouseLeave = ImgButtonMouseMouseLeave
    OnMouseUp = ImgButtonMouseMouseUp
  end
  object ImgButtonTools: TImage
    Left = 232
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonToolsDblClick
    OnMouseDown = ImgButtonToolsMouseDown
    OnMouseEnter = ImgButtonToolsMouseEnter
    OnMouseLeave = ImgButtonToolsMouseLeave
    OnMouseUp = ImgButtonToolsMouseUp
  end
  object ImgButtonWWW: TImage
    Left = 272
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    Visible = False
    OnDblClick = ImgButtonWWWDblClick
    OnMouseDown = ImgButtonWWWMouseDown
    OnMouseEnter = ImgButtonWWWMouseEnter
    OnMouseLeave = ImgButtonWWWMouseLeave
    OnMouseUp = ImgButtonWWWMouseUp
  end
  object ImgButtonHelp: TImage
    Left = 312
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonHelpDblClick
    OnMouseDown = ImgButtonHelpMouseDown
    OnMouseEnter = ImgButtonHelpMouseEnter
    OnMouseLeave = ImgButtonHelpMouseLeave
    OnMouseUp = ImgButtonHelpMouseUp
  end
  object ImgButtonMinimize: TImage
    Left = 352
    Top = 72
    Width = 33
    Height = 33
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    ParentShowHint = False
    ShowHint = True
    OnDblClick = ImgButtonMinimizeDblClick
    OnMouseDown = ImgButtonMinimizeMouseDown
    OnMouseEnter = ImgButtonMinimizeMouseEnter
    OnMouseLeave = ImgButtonMinimizeMouseLeave
    OnMouseUp = ImgButtonMinimizeMouseUp
  end
  object TmrAppIcon: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrAppIconTimer
    Left = 24
    Top = 104
  end
  object TmrButtonMode: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonModeTimer
    Left = 64
    Top = 104
  end
  object TmrButtonLayoutDown: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonLayoutDownTimer
    Left = 104
    Top = 104
  end
  object TmrButtonLayout: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonLayoutTimer
    Left = 144
    Top = 104
  end
  object TmrButtonMouse: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonMouseTimer
    Left = 192
    Top = 104
  end
  object TmrButtonTools: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonToolsTimer
    Left = 232
    Top = 104
  end
  object TmrButtonWWW: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonWWWTimer
    Left = 272
    Top = 104
  end
  object TmrButtonHelp: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonHelpTimer
    Left = 312
    Top = 104
  end
  object TmrButtonMinimize: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TmrButtonMinimizeTimer
    Left = 352
    Top = 104
  end
  object TransparencyTimer: TTimer
    Enabled = False
    Interval = 10
    OnTimer = TransparencyTimerTimer
    Left = 480
    Top = 192
  end
  object HintTimer: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = HintTimerTimer
    Left = 448
    Top = 192
  end
  object BalloonHint1: TBalloonHint
    HideAfter = 5000
    Left = 200
    Top = 184
  end
end
