; Popy Keyboard - Inno Setup 6 script (installed edition)
; Build:  ISCC.exe installer\PopyKeyboard.iss /DAppVersion=1.0.0 /DSourceDir=..\dist\PopyKeyboard-1.0.0
; SourceDir = the folder made by make-release.bat (exe files + assets), WITHOUT portable.txt.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\dist\PopyKeyboard-1.0.0"
#endif

[Setup]
AppId={{6B0D2F6C-3C51-4C73-8F0E-5B0A3F9E7A11}
AppName=Popy Keyboard
AppVersion={#AppVersion}
AppPublisher=Popy Keyboard
DefaultDirName={autopf}\Popy Keyboard
DefaultGroupName=Popy Keyboard
UninstallDisplayIcon={app}\Popy Keyboard.exe
SetupIconFile=..\assets\icons\Popy.ico
WizardImageFile=..\assets\images\installer-wizard-large.bmp
WizardSmallImageFile=..\assets\images\installer-wizard-small.bmp
OutputDir=..\dist
OutputBaseFilename=setup_popykeyboard_{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Shortcuts:"
Name: "startup"; Description: "Start Popy Keyboard with &Windows"; GroupDescription: "Options:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion; Excludes: "portable.txt"

[Icons]
Name: "{group}\Popy Keyboard"; Filename: "{app}\Popy Keyboard.exe"
Name: "{group}\Popy Layout guide"; Filename: "{app}\PopyLayout.md"
Name: "{group}\Uninstall Popy Keyboard"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Popy Keyboard"; Filename: "{app}\Popy Keyboard.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Popy Keyboard"; ValueData: """{app}\Popy Keyboard.exe"""; Tasks: startup; Flags: uninsdeletevalue

[Run]
Filename: "{app}\Popy Keyboard.exe"; Description: "Launch Popy Keyboard"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM ""Popy Keyboard.exe"""; Flags: runhidden; RunOnceId: "KillPopy"
