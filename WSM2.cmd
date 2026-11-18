@echo off
rem WSM2 - Wreckfest 2 Server Manager launcher
setlocal
set "SCRIPTDIR=%~dp0"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPTDIR%WSM2.ps1"
endlocal
