@echo off
TITLE NexusV2 - Clean All
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
cd /d "%ROOT_DIR%"

echo.
echo ========================================
echo   NexusV2 - Clean All
echo ========================================
echo.
echo This will delete:
echo   - Root node_modules
echo   - Backend node_modules
echo   - Backend vendor
echo   - Frontend node_modules
echo   - Frontend .next build cache
echo.
echo WARNING: This cannot be undone!
echo.
set /p CONFIRM="Are you sure? (yes/no): "
if /i not "%CONFIRM%"=="yes" (
    echo Cancelled.
    exit /b 0
)

echo.
echo [INFO] Cleaning root node_modules...
if exist "%ROOT_DIR%\node_modules" (
    rmdir /s /q "%ROOT_DIR%\node_modules" >nul 2>&1
    echo [OK] Deleted
) else (
    echo [OK] Already clean
)

echo [INFO] Cleaning backend node_modules...
if exist "%ROOT_DIR%\Nexus-backend\node_modules" (
    rmdir /s /q "%ROOT_DIR%\Nexus-backend\node_modules" >nul 2>&1
    echo [OK] Deleted
) else (
    echo [OK] Already clean
)

echo [INFO] Cleaning backend vendor...
if exist "%ROOT_DIR%\Nexus-backend\vendor" (
    rmdir /s /q "%ROOT_DIR%\Nexus-backend\vendor" >nul 2>&1
    echo [OK] Deleted
) else (
    echo [OK] Already clean
)

echo [INFO] Cleaning frontend node_modules...
if exist "%ROOT_DIR%\Nexus-Frontend\node_modules" (
    rmdir /s /q "%ROOT_DIR%\Nexus-Frontend\node_modules" >nul 2>&1
    echo [OK] Deleted
) else (
    echo [OK] Already clean
)

echo [INFO] Cleaning frontend .next cache...
if exist "%ROOT_DIR%\Nexus-Frontend\.next" (
    rmdir /s /q "%ROOT_DIR%\Nexus-Frontend\.next" >nul 2>&1
    echo [OK] Deleted
) else (
    echo [OK] Already clean
)

echo.
echo ========================================
echo [SUCCESS] Cleanup complete!
echo ========================================
echo.
echo You can now run setup.bat to reinstall everything.
echo.
pause

endlocal
