@echo off
TITLE NexusV2 - Start All Services with Redis Queue
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Start All Services (Redis)
echo ========================================
echo.
echo Starting all Nexus services with Redis:
echo   - Laravel API Server (port 8000)
echo   - Laravel Reverb (port 6001)
echo   - Vite Dev Server (port 5173)
echo   - Laravel Queue Worker (Redis)
echo   - Next.js Frontend (port 3000)
echo.
echo Redis Queue: redis://127.0.0.1:6379
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

REM Check if dependencies are installed
if not exist "%ROOT_DIR%\node_modules\" (
    echo [ERROR] Root node_modules not found. Please run setup.bat first.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-backend\vendor\" (
    echo [ERROR] Backend vendor not found. Please run setup.bat first.
    pause
    exit /b 1
)

if not exist "%ROOT_DIR%\Nexus-Frontend\node_modules\" (
    echo [ERROR] Frontend node_modules not found. Please run setup.bat first.
    pause
    exit /b 1
)

REM Check Redis
echo [CHECK] Verifying Redis is running...
docker exec redis-nexus redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Redis is not responding. Trying to start it...
    docker start redis-nexus >nul 2>&1
    timeout /t 2 /nobreak
    docker exec redis-nexus redis-cli ping >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Redis is not running. Please ensure Redis container is running.
        pause
        exit /b 1
    )
)
echo [OK] Redis is ready

echo.
echo [INFO] Starting all services...
echo.

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
