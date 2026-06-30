@echo off
TITLE NexusV2 Real-Time Logs Console
setlocal enabledelayedexpansion

REM Get the base directories
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "LOGS_DIR=%PROJECT_ROOT%\Nexus-backend\storage\logs"

REM Normalise path
pushd "%LOGS_DIR%"
set "LOGS_DIR=%CD%"
popd

:MENU
cls
echo ========================================================
echo           NEXUS V2 REAL-TIME LOGS CONSOLE
echo ========================================================
echo.
echo Please select the log stream to monitor:
echo.
echo   [1] Laravel Application Logs (laravel.log)
echo   [2] Laravel Reverb WebSockets Logs (reverb.log)
echo   [3] Horizon Queue Logs (horizon.log)
echo   [4] Default Queue Worker Logs (worker.log)
echo   [5] Exit
echo.
echo ========================================================
set /p choice="Enter your choice (1-5) [Default is 1]: "

if "%choice%"=="" set choice=1
if "%choice%"=="1" goto LOG_LARAVEL
if "%choice%"=="2" goto LOG_REVERB
if "%choice%"=="3" goto LOG_HORIZON
if "%choice%"=="4" goto LOG_WORKER
if "%choice%"=="5" goto EXIT
echo [ERROR] Invalid choice. Try again.
timeout /t 2 >nul
goto MENU

:LOG_LARAVEL
set "LOG_FILE=%LOGS_DIR%\laravel.log"
set "LOG_TITLE=Laravel Application Logs"
goto START_TAIL

:LOG_REVERB
set "LOG_FILE=%LOGS_DIR%\reverb.log"
set "LOG_TITLE=Laravel Reverb Logs"
goto START_TAIL

:LOG_HORIZON
set "LOG_FILE=%LOGS_DIR%\horizon.log"
set "LOG_TITLE=Laravel Horizon Logs"
goto START_TAIL

:LOG_WORKER
set "LOG_FILE=%LOGS_DIR%\worker.log"
set "LOG_TITLE=Laravel Queue Worker Logs"
goto START_TAIL

:START_TAIL
if not exist "%LOG_FILE%" (
    echo [INFO] File does not exist yet. Creating empty log file at "%LOG_FILE%"...
    type nul > "%LOG_FILE%"
)

cls
echo ========================================================
echo   MONITORING: %LOG_TITLE%
echo   Path: %LOG_FILE%
echo --------------------------------------------------------
echo   Press [Ctrl+C] to stop tailing and return to menu.
echo ========================================================
echo.

REM Call PowerShell to tail the file efficiently using -Tail and -Wait
powershell -NoProfile -Command "Get-Content -Path '%LOG_FILE%' -Wait -Tail 30"

echo.
echo ========================================================
echo   Tailing stopped.
echo ========================================================
pause
goto MENU

:EXIT
echo Exiting Logs Console. Goodbye!
timeout /t 2 >nul
endlocal
