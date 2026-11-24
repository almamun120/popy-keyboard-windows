@echo off
rem  Popy Keyboard - builds BOTH editions from one Delphi build:
rem    dist\PopyKeyboard-<ver>-portable.zip   (unzip anywhere / USB stick; contains portable.txt)
rem    dist\setup_popykeyboard_<ver>.exe      (installer; needs Inno Setup 6, ISCC.exe)
rem  Usage:  make-release.bat 1.0.0
rem  Run after building WholeProject.groupproj in Release (see build-ce.bat) -> files are in build\
setlocal
set VER=%1
if "%VER%"=="" set VER=1.0.0
cd /d %~dp0

set DIST=dist\PopyKeyboard-%VER%
if exist dist rmdir /s /q dist
mkdir "%DIST%"

echo - Collecting files
copy "build\Popy_Keyboard.exe"       "%DIST%\Popy Keyboard.exe"        >nul || goto failed
copy "build\Avro_Spell_Checker.exe"  "%DIST%\Avro Spell Checker.exe"   >nul || goto failed
copy "build\LayoutEditor.exe"        "%DIST%\Layout Editor.exe"        >nul || goto failed
copy "build\SkinDesigner.exe"        "%DIST%\Skin Designer.exe"        >nul || goto failed
copy "build\Unicode_to_Bijoy.exe"    "%DIST%\Unicode to Bijoy.exe"     >nul || goto failed
copy "build\AvroSpell.dll"           "%DIST%"                          >nul || goto failed
xcopy assets "%DIST%\assets" /e /i /q >nul
copy docs\PopyLayout.md "%DIST%" >nul
copy LICENSE.txt "%DIST%" >nul

echo - Portable edition
mkdir "dist\portable-tmp\PopyKeyboard"
xcopy "%DIST%" "dist\portable-tmp\PopyKeyboard" /e /i /q >nul
rem  An empty portable.txt switches the program to portable mode: all data + Settings.xml stay in this folder
type nul > "dist\portable-tmp\PopyKeyboard\portable.txt"
powershell -NoProfile -Command "Compress-Archive -Path 'dist\portable-tmp\PopyKeyboard' -DestinationPath 'dist\PopyKeyboard-%VER%-portable.zip' -Force" || goto failed
rmdir /s /q dist\portable-tmp

echo - Setup edition
set ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe
if not exist "%ISCC%" set ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe
if not exist "%ISCC%" (
  echo Inno Setup 6 not found - skipping setup.exe  ^(install it from jrsoftware.org^)
) else (
  "%ISCC%" installer\PopyKeyboard.iss /DAppVersion=%VER% /DSourceDir=..\%DIST% || goto failed
)
echo.
echo Done:  dist\PopyKeyboard-%VER%-portable.zip   and   dist\setup_popykeyboard_%VER%.exe
exit /b 0

:failed
echo *** FAILED ***
exit /b 1
