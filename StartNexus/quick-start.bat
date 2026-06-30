@echo off
TITLE NexusV2 - Quick Start (with Redis)
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Quick Start
echo ========================================
echo.

REM Check if this is first time setup
if not exist "%ROOT_DIR%\node_modules\" (
    echo [INFO] First time setup detected!
    echo [INFO] Running full setup...
    echo.
    call "%SCRIPT_DIR%setup.bat"
    if %errorlevel% neq 0 (
        echo [ERROR] Setup failed!
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Starting NexusV2 with Redis Support...
echo ========================================
echo.

call "%SCRIPT_DIR%start-with-redis.bat"

endlocal
