@echo off
setlocal
set "VC=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
set "ROOT=%~dp0"

call "%VC%" x86 >nul || exit /b 1
if not exist "%ROOT%build" mkdir "%ROOT%build"
cd /d "%ROOT%build"

cl /nologo /O2 /MT /Fe:RA2Video.exe "%ROOT%ra2video.cpp" /link user32.lib gdi32.lib comctl32.lib /SUBSYSTEM:WINDOWS || exit /b 1

copy /y RA2Video.exe "%ROOT%..\_dist\RA2Video.exe" >nul
echo RA2Video.exe -^> _dist
