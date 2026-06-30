@echo off
TITLE NexusV2 - Check Redis Status
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   NexusV2 - Check Redis Status
echo ========================================
echo.

REM Check if Docker is running
echo [CHECK] Verifying Docker is installed and running...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [OK] Docker is installed

REM Check if Redis container exists
echo [CHECK] Looking for Redis container...
docker ps -a | findstr redis >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] No Redis container found
    echo Starting Redis container...
    docker run -d -p 6379:6379 --name redis-nexus redis:latest
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to start Redis container
        pause
        exit /b 1
    )
    echo [OK] Redis container started
    timeout /t 2 /nobreak
) else (
    echo [OK] Redis container exists
)

REM Check if Redis is running
echo [CHECK] Checking if Redis is running...
docker exec redis-nexus redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Redis is not responding, starting it...
    docker start redis-nexus >nul 2>&1
    timeout /t 2 /nobreak
    docker exec redis-nexus redis-cli ping >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to start Redis
        pause
        exit /b 1
    )
)

echo [OK] Redis is running

REM Get more info
echo.
echo [INFO] Getting Redis info...
docker exec redis-nexus redis-cli INFO server | findstr redis_version

echo.
echo ========================================
echo [SUCCESS] Redis is ready!
echo ========================================
echo.
echo Redis server is running on:
echo   Host: 127.0.0.1
echo   Port: 6379
echo.
pause

endlocal
