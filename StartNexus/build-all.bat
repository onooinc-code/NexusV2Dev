@echo off
TITLE NexusV2 - Build All Projects
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Build All Projects
echo ========================================
echo.

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

echo [INFO] Building Nexus-Frontend...
cd /d "%ROOT_DIR%\Nexus-Frontend"
call npm run build
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build frontend
    pause
    exit /b 1
)

echo.
echo ========================================
echo [SUCCESS] All projects built successfully!
echo ========================================
echo.
pause

endlocal
