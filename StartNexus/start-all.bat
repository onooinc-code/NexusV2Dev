@echo off
TITLE NexusV2 - Start All Services
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Start All Services
echo ========================================
echo.
echo Starting all Nexus services:
echo   - Laravel API Server (port 8000)
echo   - Laravel Reverb (port 6001)
echo   - Vite Dev Server (port 5173)
echo   - Laravel Queue Worker
echo   - Next.js Frontend (port 3000)
echo.
echo Press Ctrl+C to stop all servers
echo ========================================
echo.

REM Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH.
    pause
    exit /b 1
)

REM Check PHP 8.4
where php >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\xampp2\php\php.exe" (
        set "PATH=C:\xampp2\php;%PATH%"
        set "PHPRC=C:\xampp2\php"
    ) else (
        echo [ERROR] PHP not found. Please ensure C:\xampp2\php exists.
        pause
        exit /b 1
    )
)

REM Check if dependencies are installed
if not exist "%ROOT_DIR%\node_modules\" (
    echo [ERROR] Root node_modules not found. Please run install-all.bat first.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-backend\vendor\" (
    echo [ERROR] Backend vendor not found. Please run install-all.bat first.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-Frontend\node_modules\" (
    echo [ERROR] Frontend node_modules not found. Please run install-all.bat first.
    pause
    exit /b 1
)

cd /d "%ROOT_DIR%"
call npm start

if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Services terminated with an error.
    echo ========================================
    pause
    exit /b 1
)

endlocal
