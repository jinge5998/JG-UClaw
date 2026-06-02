@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"
echo Starting OpenClaw launcher...
echo.
del /q "%~dp0launcher_utf8_*.log" 2>nul
set "LOGFILE=%~dp0launcher_utf8_%random%.log"
echo [INFO] %date% %time% - launcher start >> "%LOGFILE%"

:rem detect PowerShell executable (prefer pwsh (Core) for UTF-8, fallback to system PowerShell)
set "PS_EXE="
for /f "usebackq delims=" %%I in (`where pwsh.exe 2^>nul`) do (
    set "PS_EXE=%%I"
    goto :FOUND_PS
)
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)
:FOUND_PS

if "%PS_EXE%"=="" (
    echo [ERROR] PowerShell not found. Please install PowerShell or add to PATH. > "%LOGFILE%"
    echo PowerShell not found. Please install PowerShell or add to PATH.
    pause
    exit /b 1
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Sta -File "%~dp0U-Claw-Launcher.ps1" > "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo Launcher failed. See log: %LOGFILE%
    echo ----------------- log start -----------------
    type "%LOGFILE%"
    echo ------------------ log end ------------------
    echo.
    pause
)