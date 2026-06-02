@echo off
TITLE NexusV2 Development Server
setlocal enabledelayedexpansion

echo ========================================
echo Starting NexusV2 Build and Server Script
echo ========================================
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Run the PowerShell script with proper execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%build-fixed.ps1'"

REM Check if the script failed
if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Script execution failed!
    echo ========================================
    pause
    exit /b 1
) else (
    echo.
    echo ========================================
    echo Script completed successfully
    echo ========================================
)

endlocal
pause
