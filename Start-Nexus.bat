@echo off
TITLE NexusV2 Development Environment
setlocal enabledelayedexpansion

echo ========================================
echo   NexusV2 Development Environment
echo ========================================
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo [CHECK] Verifying Node.js is installed...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH. Please install Node.js.
    pause
    exit /b 1
)

echo [CHECK] Verifying PHP 8.4 is installed...
where php >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\xampp2\php\php.exe" (
        echo [INFO] Found PHP 8.4 in C:\xampp2\php. Adding to temporary PATH.
        set "PATH=C:\xampp2\php;%PATH%"
        set "PHPRC=C:\xampp2\php"
    ) else (
        echo [ERROR] PHP not found. Please ensure C:\xampp2\php exists.
        pause
        exit /b 1
    )
)

if "%1"=="--install" (
    echo [INFO] Running full installation of all dependencies...
    call npm run install:all
    if errorlevel 1 (
        echo [ERROR] Installation failed.
        pause
        exit /b 1
    )
    echo [SUCCESS] Installation complete!
    echo.
) else (
    if not exist "node_modules\" (
        echo [INFO] Root dependencies missing. Installing concurrently...
        call npm install
    )
)

echo.
echo [INFO] Booting up all services...
echo [INFO] Press Ctrl+C at any time to cleanly stop all servers.
echo ========================================
echo.

call npm start

if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Services terminated with an error.
    echo ========================================
    pause
    exit /b 1
)

pause
endlocal
