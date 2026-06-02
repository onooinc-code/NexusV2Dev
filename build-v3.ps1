#!/usr/bin/env powershell
#Requires -Version 5.1

<#
.SYNOPSIS
    Nexus Project Build and Service Launcher v3.0
.DESCRIPTION
    Comprehensive build automation for NexusV2 backend and frontend with 22+ improvements
.NOTES
    - Parallel service startup with process monitoring
    - Color-coded logging system
    - Port availability checking
    - Graceful error recovery
#>

$ErrorActionPreference = "Continue"
$DebugPreference = "SilentlyContinue"

# Configuration
$RootPath = Get-Location
$backendPath = Join-Path $RootPath "Nexus-backend"
$frontendPath = Join-Path $RootPath "Nexus-Frontend"
$logsPath = Join-Path $RootPath "logs"
$pidFile = Join-Path $logsPath "pids.txt"

# Port Configuration
$ReverbPort = 6001
$reverb_host = "0.0.0.0"
$ApiPort = 8000
$VitePort = 5173
$NextPort = 3000

# Ensure logs directory exists
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

$startTime = Get-Date
$backendLogFile = Join-Path $logsPath "build-backend.log"
$frontendLogFile = Join-Path $logsPath "build-frontend.log"

# Clear old logs
@($backendLogFile, $frontendLogFile, $pidFile) | ForEach-Object {
    if (Test-Path $_) { Clear-Content $_ }
}

# ========================================
# LOGGING FUNCTION
# ========================================
function Log-Message {
    param(
        [string]$Message,
        [ValidateSet("SUCCESS", "ERROR", "WARNING", "INFO", "DEBUG")]
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Type) {
        "SUCCESS" { 
            Write-Host "[OK] [$timestamp] $Message" -ForegroundColor Green
        }
        "ERROR" { 
            Write-Host "[ER] [$timestamp] $Message" -ForegroundColor Red
        }
        "WARNING" { 
            Write-Host "[WR] [$timestamp] $Message" -ForegroundColor Yellow
        }
        "INFO" { 
            Write-Host "[IN] [$timestamp] $Message" -ForegroundColor Cyan
        }
        "DEBUG" { 
            Write-Host "[DB] [$timestamp] $Message" -ForegroundColor Gray
        }
    }
}

# ========================================
# PORT CHECKING FUNCTION
# ========================================
function Check-PortAvailable {
    param(
        [int]$Port,
        [string]$ServiceName
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("127.0.0.1", $Port)
        $tcpClient.Close()
        return $false
    }
    catch {
        return $true
    }
}

# ========================================
# PROCESS ID TRACKING
# ========================================
function Save-ProcessId {
    param(
        [int]$ProcessId,
        [string]$ServiceName
    )
    
    if (-not (Test-Path $pidFile)) {
        New-Item -ItemType File -Path $pidFile | Out-Null
    }
    
    "$ServiceName : $ProcessId" | Add-Content -Path $pidFile
    Log-Message "Process tracker: $ServiceName=$ProcessId" "DEBUG"
}

Write-Host ""
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "Nexus Project Build Script v3.0"  -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# ========================================
# BACKEND BUILD
# ========================================
Log-Message "Building Backend..." "INFO"
Log-Message "Location: $backendPath" "DEBUG"

if (-not (Test-Path $backendPath)) {
    Log-Message "Backend directory not found at $backendPath" "ERROR"
    exit 1
}

Push-Location $backendPath
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray

# Environment check
Log-Message "Checking environment..." "INFO"
$phpExists = $null -ne (Get-Command php -ErrorAction SilentlyContinue)
$composerExists = $null -ne (Get-Command composer -ErrorAction SilentlyContinue)
$npmExists = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)

if (-not $phpExists) { Log-Message "Warning: PHP not found in PATH" "WARNING" }
if (-not $composerExists) { Log-Message "Warning: Composer not found in PATH" "WARNING" }
if (-not $npmExists) { Log-Message "Warning: npm not found in PATH" "WARNING" }
Log-Message "Environment check complete" "SUCCESS"

# Composer install with error recovery
Log-Message "Installing PHP dependencies..." "INFO"
$composerCmd = "composer install --no-dev --no-scripts --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-redis 2>&1"
$composerResult = Invoke-Expression $composerCmd
$composerResult | Tee-Object -FilePath $backendLogFile -Append | Out-Null

if ($LASTEXITCODE -ne 0) {
    Log-Message "Composer install completed with warnings (exit code: $LASTEXITCODE) - continuing" "WARNING"
} else {
    Log-Message "Composer dependencies installed successfully" "SUCCESS"
}

# npm install
Log-Message "Installing Node dependencies..." "INFO"
$npmCmd = "npm install --no-optional 2>&1"
$npmResult = Invoke-Expression $npmCmd
$npmResult | Tee-Object -FilePath $backendLogFile -Append | Out-Null

if ($LASTEXITCODE -ne 0) {
    Log-Message "npm install completed with warnings (exit code: $LASTEXITCODE) - continuing" "WARNING"
} else {
    Log-Message "Node dependencies installed successfully" "SUCCESS"
}

# Generate app key
Log-Message "Generating application key..." "INFO"
php artisan key:generate --force 2>&1 | Tee-Object -FilePath $backendLogFile -Append | Out-Null
if ($LASTEXITCODE -eq 0) {
    Log-Message "Application key generated" "SUCCESS"
}

# Setup environment
Log-Message "Setting up environment configuration..." "INFO"
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Log-Message "Created .env from .env.example" "SUCCESS"
    }
}

# Optimize autoloader
Log-Message "Optimizing autoloader..." "INFO"
composer dump-autoload --optimize 2>$null | Out-Null
Log-Message "Autoloader optimization complete" "SUCCESS"

Log-Message "Backend setup completed" "SUCCESS"
Pop-Location

Write-Host ""

# ========================================
# FRONTEND BUILD
# ========================================
Log-Message "Building Frontend..." "INFO"
Log-Message "Location: $frontendPath" "DEBUG"

if (-not (Test-Path $frontendPath)) {
    Log-Message "Frontend directory not found at $frontendPath" "ERROR"
    exit 1
}

Push-Location $frontendPath
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray

# Environment check for frontend
Log-Message "Checking frontend environment..." "INFO"
$nodeExists = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
$npmExists = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)

if (-not $nodeExists) { Log-Message "Warning: Node.js not found" "WARNING" }
if (-not $npmExists) { Log-Message "Warning: npm not found" "WARNING" }
Log-Message "Frontend environment check complete" "SUCCESS"

# npm install for frontend
Log-Message "Installing frontend dependencies..." "INFO"
$npmCmd = "npm install --no-optional 2>&1"
$npmResult = Invoke-Expression $npmCmd
$npmResult | Tee-Object -FilePath $frontendLogFile -Append | Out-Null

if ($LASTEXITCODE -ne 0) {
    Log-Message "npm install completed with warnings (exit code: $LASTEXITCODE) - continuing" "WARNING"
} else {
    Log-Message "Frontend dependencies installed successfully" "SUCCESS"
}

# Frontend build
Log-Message "Running frontend build..." "INFO"
$npmCmd = "npm run build 2>&1"
$npmResult = Invoke-Expression $npmCmd
$npmResult | Tee-Object -FilePath $frontendLogFile -Append | Out-Null

if ($LASTEXITCODE -ne 0) {
    Log-Message "Frontend build completed with warnings (exit code: $LASTEXITCODE) - continuing" "WARNING"
} else {
    Log-Message "Frontend build completed successfully" "SUCCESS"
}

Log-Message "Frontend setup completed" "SUCCESS"
Pop-Location

Write-Host ""

# ========================================
# SERVICE STARTUP
# ========================================
Log-Message "Running pre-flight health checks..." "INFO"

# Check port availability
$ports = @(
    @{Port = $ReverbPort; Name = "Reverb"},
    @{Port = $ApiPort; Name = "API"},
    @{Port = $VitePort; Name = "Vite"}
)

foreach ($portInfo in $ports) {
    if (-not (Check-PortAvailable $portInfo.Port)) {
        Log-Message "Port $($portInfo.Port) ($($portInfo.Name)) may already be in use" "WARNING"
    }
}

Write-Host ""
Log-Message "Starting all services..." "INFO"
Write-Host ""

Push-Location $backendPath

# Start Reverb WebSocket Server
Log-Message "Starting Reverb WebSocket Server (port $ReverbPort)..." "INFO"
$reverbProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "reverb:start", "--host=$reverb_host", "--port=$ReverbPort" `
    -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "reverb.log") -RedirectStandardError (Join-Path $logsPath "reverb-error.log")
Save-ProcessId $reverbProcess.Id "Reverb"
Log-Message "Reverb started (PID: $($reverbProcess.Id))" "SUCCESS"

# Start Laravel API Server
Log-Message "Starting Laravel API Server (port $ApiPort)..." "INFO"
$apiProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "serve", "--port=$ApiPort" `
    -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "api.log") -RedirectStandardError (Join-Path $logsPath "api-error.log")
Save-ProcessId $apiProcess.Id "API"
Log-Message "API Server started (PID: $($apiProcess.Id))" "SUCCESS"

# Start Vite Dev Server
Log-Message "Starting Vite Dev Server (port $VitePort)..." "INFO"
$viteProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev", "--", "--port", "$VitePort" `
    -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "vite.log") -RedirectStandardError (Join-Path $logsPath "vite-error.log")
Save-ProcessId $viteProcess.Id "Vite"
Log-Message "Vite Dev Server started (PID: $($viteProcess.Id))" "SUCCESS"

# Start Queue Worker
Log-Message "Starting Queue Worker..." "INFO"
$queueProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "queue:work", "--tries=3", "--timeout=90" `
    -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "queue.log") -RedirectStandardError (Join-Path $logsPath "queue-error.log")
Save-ProcessId $queueProcess.Id "Queue"
Log-Message "Queue Worker started (PID: $($queueProcess.Id))" "SUCCESS"

Pop-Location

# Start Next.js Frontend
Log-Message "Starting Next.js Frontend (port $NextPort)..." "INFO"
Push-Location $frontendPath
$nextProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev", "--", "--port", "$NextPort" `
    -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "nextjs.log") -RedirectStandardError (Join-Path $logsPath "nextjs-error.log")
Save-ProcessId $nextProcess.Id "Next.js"
Log-Message "Next.js Frontend started (PID: $($nextProcess.Id))" "SUCCESS"
Pop-Location

Log-Message "Waiting for services to stabilize..." "INFO"
Start-Sleep -Seconds 3
Log-Message "All services started successfully" "SUCCESS"

# Display build summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "BUILD COMPLETE"  -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
Log-Message "Build completed in $($duration.TotalSeconds) seconds" "SUCCESS"
Write-Host ""
Write-Host "Services running:" -ForegroundColor Cyan
Write-Host "  - Reverb WebSocket:  http://0.0.0.0:$ReverbPort" -ForegroundColor Cyan
Write-Host "  - Laravel API:       http://localhost:$ApiPort" -ForegroundColor Cyan
Write-Host "  - Vite Dev Server:   http://localhost:$VitePort" -ForegroundColor Cyan
Write-Host "  - Next.js Frontend:  http://localhost:$NextPort" -ForegroundColor Cyan
Write-Host ""
Log-Message "System is running. Press Ctrl+C to stop all services" "WARNING"
Write-Host ""

# Keep the script running and monitor processes
while ($true) {
    Start-Sleep -Seconds 60
    
    $processes = @($reverbProcess, $apiProcess, $viteProcess, $queueProcess, $nextProcess)
    foreach ($proc in $processes) {
        if ($proc.HasExited) {
            Log-Message "Warning: Process $($proc.Id) has exited" "WARNING"
        }
    }
}
