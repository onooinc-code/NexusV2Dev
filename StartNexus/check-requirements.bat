@echo off
TITLE NexusV2 - Check Requirements
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   NexusV2 - Check System Requirements
echo ========================================
echo.

setlocal enabledelayedexpansion
set "ALL_GOOD=1"

REM Check Node.js
echo [CHECK] Node.js...
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('node --version') do set "NODE_VERSION=%%i"
    echo [OK] Node.js is installed: !NODE_VERSION!
) else (
    echo [ERROR] Node.js is NOT installed
    set "ALL_GOOD=0"
)

REM Check npm
echo [CHECK] npm...
where npm >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('npm --version') do set "NPM_VERSION=%%i"
    echo [OK] npm is installed: !NPM_VERSION!
) else (
    echo [ERROR] npm is NOT installed
    set "ALL_GOOD=0"
)

REM Check PHP
echo [CHECK] PHP...
where php >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('php --version ^| findstr /R "PHP"') do set "PHP_VERSION=%%i"
    echo [OK] PHP is installed: !PHP_VERSION!
) else (
    echo [WARNING] PHP is NOT in PATH
    if exist "C:\xampp2\php\php.exe" (
        echo [INFO] PHP found in C:\xampp2\php
    ) else (
        echo [ERROR] PHP not found anywhere
        set "ALL_GOOD=0"
    )
)

REM Check Composer
echo [CHECK] Composer...
where composer >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('composer --version') do set "COMPOSER_VERSION=%%i"
    echo [OK] Composer is installed: !COMPOSER_VERSION!
) else (
    echo [ERROR] Composer is NOT installed or not in PATH
    set "ALL_GOOD=0"
)

REM Check Git
echo [CHECK] Git...
where git >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('git --version') do set "GIT_VERSION=%%i"
    echo [OK] Git is installed: !GIT_VERSION!
) else (
    echo [WARNING] Git is NOT installed (optional but recommended)
)

echo.
if !ALL_GOOD! equ 1 (
    echo ========================================
    echo [SUCCESS] All required tools are installed!
    echo ========================================
) else (
    echo ========================================
    echo [ERROR] Some required tools are missing!
    echo Please install the missing tools and try again.
    echo ========================================
)

echo.
pause

endlocal
