@echo off
TITLE NexusV2 - Install All Dependencies
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Install All Dependencies
echo ========================================
echo.

REM Check Node.js
echo [CHECK] Verifying Node.js is installed...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH. Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check PHP
echo [CHECK] Verifying PHP is installed...
where php >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] PHP not found in PATH. Checking C:\xampp2\php...
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

REM Check Composer
echo [CHECK] Verifying Composer is installed...
where composer >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Composer is not installed or not in PATH. Please install Composer from https://getcomposer.org/
    pause
    exit /b 1
)

echo.
echo [INFO] Installing root dependencies...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install root dependencies
    pause
    exit /b 1
)

echo.
echo [INFO] Installing Nexus-backend dependencies...
cd /d "%ROOT_DIR%\Nexus-backend"
echo [INFO] Running composer install...
call composer install --ignore-platform-reqs
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install backend composer dependencies
    pause
    exit /b 1
)

echo [INFO] Running npm install for backend...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install backend npm dependencies
    pause
    exit /b 1
)

echo.
echo [INFO] Installing Nexus-Frontend dependencies...
cd /d "%ROOT_DIR%\Nexus-Frontend"
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install frontend dependencies
    pause
    exit /b 1
)

echo.
echo ========================================
echo [SUCCESS] All dependencies installed successfully!
echo ========================================
echo.
pause

endlocal
