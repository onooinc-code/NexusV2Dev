@echo off
TITLE NexusV2 - Start Frontend Only
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Start Frontend Only
echo ========================================
echo.
echo Starting frontend service:
echo   - Next.js Frontend (port 3000)
echo.
echo Backend services are NOT started.
echo Make sure backend is running on localhost:8000
echo Press Ctrl+C to stop
echo ========================================
echo.

REM Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-Frontend\node_modules\" (
    echo [ERROR] Frontend node_modules not found. Please run install-all.bat first.
    pause
    exit /b 1
)

cd /d "%ROOT_DIR%\Nexus-Frontend"
call npm run dev -- -p 3000

if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Frontend terminated with an error.
    echo ========================================
    pause
    exit /b 1
)

endlocal
