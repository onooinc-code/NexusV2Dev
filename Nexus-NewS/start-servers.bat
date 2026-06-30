@echo off
TITLE NexusV2 Services Control Center
setlocal enabledelayedexpansion

echo ========================================================
echo   NexusV2 Service Initialization ^& Management
echo ========================================================
echo.

REM Get the base directories
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "BACKEND_DIR=%PROJECT_ROOT%\Nexus-backend"

REM Normalise paths
pushd "%BACKEND_DIR%"
set "BACKEND_DIR=%CD%"
popd

echo [INFO] Project Directory: %PROJECT_ROOT%
echo [INFO] Laravel Directory: %BACKEND_DIR%
echo.

REM --- STEP 1: STOP & KILL OLD SERVERS ---
echo ========================================================
echo [1/4] Stopping and killing old servers/ports...
echo ========================================================

REM Ports to clean: 8000 (Serve), 6001 (Reverb), 5173 (Vite), 3000 (Old Next.js)
set "PORTS_TO_KILL=8000 6001 5173 3000"

for %%p in (%PORTS_TO_KILL%) do (
    echo [KILL] Checking for processes on port %%p...
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%%p " ^| findstr "LISTENING"') do (
        echo [KILL] Found PID %%a listening on port %%p. Terminating process...
        taskkill /F /PID %%a >nul 2>&1
    )
)
echo [SUCCESS] Ports cleared.
echo.

REM --- STEP 2: VERIFY ENVIRONMENT & REQUIREMENTS ---
echo ========================================================
echo [2/4] Verifying requirements...
echo ========================================================

REM Verify PHP
where php >nul 2>nul
if !errorlevel! neq 0 (
    if exist "C:\xampp2\php\php.exe" (
        echo [INFO] Found PHP in C:\xampp2\php. Adding to PATH.
        set "PATH=C:\xampp2\php;%PATH%"
        set "PHPRC=C:\xampp2\php"
    ) else (
        echo [ERROR] PHP is not found on your system or in PATH.
        echo         Please install PHP 8.4 or configure XAMPP.
        pause
        exit /b 1
    )
)

REM Verify Node
where node >nul 2>nul
if !errorlevel! neq 0 (
    echo [ERROR] Node.js is not found. Please install Node.js.
    pause
    exit /b 1
)

REM Check Database Connectivity (MySQL)
echo [CHECK] Checking MySQL status (Port 3306)...
netstat -aon | findstr ":3306 " | findstr "LISTENING" >nul
if !errorlevel! neq 0 (
    echo [WARNING] MySQL database does not seem to be running on port 3306.
    echo           Please start MySQL from XAMPP Control Panel if you experience DB errors.
) else (
    echo [OK] MySQL is active.
)

REM Check Redis Cache/Queue Status
echo [CHECK] Checking Redis status (Port 6379)...
netstat -aon | findstr ":6379 " | findstr "LISTENING" >nul
if !errorlevel! neq 0 (
    echo [WARNING] Redis does not seem to be running on port 6379.
    echo           Since queues and sessions use Redis, please make sure Redis is started.
) else (
    echo [OK] Redis is active.
)
echo.

REM --- STEP 3: START THE SERVERS ---
echo ========================================================
echo [3/4] Launching Laravel Monolith Services...
echo ========================================================

echo [START] Launching Laravel Web Server (Port 8000)...
start "Nexus Laravel Serve" /min cmd /c "cd /d \"%BACKEND_DIR%\" && php artisan serve --no-reload"

echo [START] Launching Laravel Reverb WebSockets (Port 6001)...
start "Nexus Laravel Reverb" /min cmd /c "cd /d \"%BACKEND_DIR%\" && php artisan reverb:start"

echo [START] Launching Vite Asset Compiler (Port 5173)...
start "Nexus Vite Dev" /min cmd /c "cd /d \"%BACKEND_DIR%\" && npm run dev -- --port 5173"

echo [START] Launching Queue Worker (default ^& contacts queues)...
start "Nexus Queue Worker" /min cmd /c "cd /d \"%BACKEND_DIR%\" && php artisan queue:work --queue=default,contacts --tries=3 --timeout=600"

echo.
echo [SUCCESS] All backend servers have been triggered!
echo.

REM --- STEP 4: MONITOR & STATUS UPDATES ---
echo ========================================================
echo [4/4] Starting Server Status Monitor (Updates every 10s)
echo ========================================================
echo.
echo Server URLs:
echo --------------------------------------------------------
echo   - Web Application:   http://127.0.0.1:8000
echo   - Horizon Dashboard: http://127.0.0.1:8000/horizon
echo   - Reverb WebSocket:  http://127.0.0.1:6001
echo   - Vite Asset Dev:    http://127.0.0.1:5173
echo   - WAHA API Console:  http://127.0.0.1:3333 (if running)
echo --------------------------------------------------------
echo.
echo Press Ctrl+C in this window to stop monitoring (the servers will remain running).
echo To stop servers, re-run this script to clear their ports.
echo.
pause

:MONITOR_LOOP
cls
echo ========================================================
echo           NEXUS V2 SERVER MONITOR STATUS
echo ========================================================
echo   Last Updated: %DATE% %TIME%
echo   Update Interval: 10 Seconds
echo ========================================================
echo.
echo   [SERVICE]               [PORT]      [STATUS]
echo   ------------------------------------------------------

REM Check Laravel App Server
set "PORT_8000=OFFLINE"
netstat -aon | findstr ":8000 " | findstr "LISTENING" >nul && set "PORT_8000=ONLINE"
echo    Laravel Web Serve       8000        !PORT_8000!

REM Check Reverb WebSockets
set "PORT_6001=OFFLINE"
netstat -aon | findstr ":6001 " | findstr "LISTENING" >nul && set "PORT_6001=ONLINE"
echo    Laravel Reverb (WS)     6001        !PORT_6001!

REM Check Vite Server
set "PORT_5173=OFFLINE"
netstat -aon | findstr ":5173 " | findstr "LISTENING" >nul && set "PORT_5173=ONLINE"
echo    Vite Assets Server      5173        !PORT_5173!

REM Check Redis Cache
set "PORT_6379=OFFLINE"
netstat -aon | findstr ":6379 " | findstr "LISTENING" >nul && set "PORT_6379=ONLINE"
echo    Redis Cache/Queue       6379        !PORT_6379!

REM Check MySQL DB
set "PORT_3306=OFFLINE"
netstat -aon | findstr ":3306 " | findstr "LISTENING" >nul && set "PORT_3306=ONLINE"
echo    MySQL Database          3306        !PORT_3306!

REM Check WAHA WhatsApp API
set "PORT_3333=OFFLINE"
netstat -aon | findstr ":3333 " | findstr "LISTENING" >nul && set "PORT_3333=ONLINE"
echo    WAHA WhatsApp API       3333        !PORT_3333!

echo.
echo ========================================================
echo   Useful Suggestions:
echo   1. To view live HTTP requests, Laravel logs, and events,
echo      run the 'live-logs.bat' script in this folder.
echo   2. Run 'php artisan route:clear' and 'php artisan config:clear'
echo      if you make changes to environment files (.env) or routing.
echo   3. Access Horizon at http://127.0.0.1:8000/horizon to view
echo      detailed job queues, throughput, and error metrics.
echo ========================================================
echo.
echo Press [Ctrl+C] to exit monitor.

timeout /t 10 >nul
goto MONITOR_LOOP
