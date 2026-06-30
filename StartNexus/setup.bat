@echo off
TITLE NexusV2 - Full Setup
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Full Setup
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
echo [OK] Node.js found

REM Check PHP 8.4
echo [CHECK] Verifying PHP 8.4 is installed...
where php >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] PHP not found in PATH. Checking C:\xampp2\php...
    if exist "C:\xampp2\php\php.exe" (
        echo [INFO] Found PHP 8.4 in C:\xampp2\php.
        set "PATH=C:\xampp2\php;%PATH%"
        set "PHPRC=C:\xampp2\php"
    ) else (
        echo [ERROR] PHP not found. Please ensure C:\xampp2\php exists.
        pause
        exit /b 1
    )
)
echo [OK] PHP found

REM Check Composer
echo [CHECK] Verifying Composer is installed...
where composer >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Composer is not installed or not in PATH. Please install Composer from https://getcomposer.org/
    pause
    exit /b 1
)
echo [OK] Composer found

REM Check Docker
echo [CHECK] Verifying Docker is installed...
docker --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed or not in PATH. Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [OK] Docker found

REM Check Redis
echo [CHECK] Verifying Redis container...
docker exec redis-nexus redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Redis container not running, starting it...
    docker run -d -p 6379:6379 --name redis-nexus redis:latest >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARNING] Could not start Redis container (may already exist)
        docker start redis-nexus >nul 2>&1
    )
    timeout /t 2 /nobreak
)
echo [OK] Redis is running

echo.
echo ========================================
echo SETUP PHASE 1: Installing Dependencies
echo ========================================
echo.

call "%SCRIPT_DIR%install-all.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo SETUP PHASE 2: Environment Configuration
echo ========================================
echo.

REM Copy .env files if they don't exist
if not exist "%ROOT_DIR%\Nexus-backend\.env" (
    echo [INFO] Creating .env file for backend from .env.example...
    if exist "%ROOT_DIR%\Nexus-backend\.env.example" (
        copy "%ROOT_DIR%\Nexus-backend\.env.example" "%ROOT_DIR%\Nexus-backend\.env" >nul
        echo [OK] .env file created
    ) else (
        echo [WARNING] .env.example not found, skipping .env creation
    )
)

if not exist "%ROOT_DIR%\Nexus-Frontend\.env.local" (
    echo [INFO] Creating .env.local file for frontend from .env.example...
    if exist "%ROOT_DIR%\Nexus-Frontend\.env.example" (
        copy "%ROOT_DIR%\Nexus-Frontend\.env.example" "%ROOT_DIR%\Nexus-Frontend\.env.local" >nul
        echo [OK] .env.local file created
    ) else (
        echo [INFO] No .env.example found for frontend, you may need to configure manually
    )
)

echo.
echo ========================================
echo [SUCCESS] Setup Complete!
echo ========================================
echo.
echo You can now:
echo   1. Run "start-all.bat" to start all services
echo   2. Run "build-all.bat" to build the frontend
echo   3. Run "install-all.bat" to reinstall dependencies
echo.
pause

endlocal
