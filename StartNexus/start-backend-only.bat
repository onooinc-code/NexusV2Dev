@echo off
TITLE NexusV2 - Start Backend Services Only
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Start Backend Only
echo ========================================
echo.
echo Starting backend services:
echo   - Laravel API Server (port 8000)
echo   - Laravel Reverb (port 6001)
echo   - Vite Dev Server (port 5173)
echo   - Laravel Queue Worker
echo.
echo Frontend (Next.js) is NOT started.
echo Press Ctrl+C to stop servers
echo ========================================
echo.

REM Check PHP
where php >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] PHP not found in PATH. Checking C:\xampp2\php...
    if exist "C:\xampp2\php\php.exe" (
        set "PATH=C:\xampp2\php;%PATH%"
        set "PHPRC=C:\xampp2\php"
    ) else (
        echo [ERROR] PHP is not installed or not in PATH.
        pause
        exit /b 1
    )
)

REM Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-backend\vendor\" (
    echo [ERROR] Backend vendor not found. Please run install-all.bat first.
    pause
    exit /b 1
)

cd /d "%ROOT_DIR%\Nexus-backend"

REM Start using concurrently for multiple services
call npx concurrently -n "API,REVERB,VITE,QUEUE" -c "bgMagenta.bold,bgBlue.bold,bgGreen.bold,bgYellow.bold" ^
    "php artisan serve --port=8000" ^
    "php artisan reverb:start --host=0.0.0.0 --port=6001" ^
    "npm run dev -- --port 5173" ^
    "php artisan queue:work --tries=3 --timeout=90"

if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Backend services terminated with an error.
    echo ========================================
    pause
    exit /b 1
)

endlocal
