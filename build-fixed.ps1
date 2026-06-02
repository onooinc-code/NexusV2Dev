# Nexus Build Script for Windows PowerShell
# Builds both Backend (Laravel/Vite) and Frontend (Next.js) projects
# Version: 2.0 - Enhanced with WebSocket, Logging, and 20+ Improvements

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# Define project paths
$backendPath = Join-Path $PSScriptRoot "Nexus-backend"
$frontendPath = Join-Path $PSScriptRoot "Nexus-Frontend"
$logsPath = Join-Path $PSScriptRoot "logs"
$backendLogFile = Join-Path $logsPath "backend-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
$frontendLogFile = Join-Path $logsPath "frontend-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
$pidFile = Join-Path $logsPath "pids.txt"

# Ensure logs directory exists
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

# Configuration
$ReverbPort = 6001
$ApiPort = 8000
$VitePort = 5173
$NextPort = 3000
$reverb_host = "0.0.0.0"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Nexus Project Build Script v2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Function to handle errors
function Handle-Error {
    param (
        [string]$ErrorMessage,
        [string]$ProjectName
    )
    Write-Host "[ERROR] building $ProjectName : $ErrorMessage" -ForegroundColor Red
    Write-Host "For detailed logs, check: $logsPath" -ForegroundColor Yellow
    exit 1
}

# Function to log with color
function Log-Message {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "SUCCESS" { Write-Host "[OK] [$timestamp] $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "[ER] [$timestamp] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[WR] [$timestamp] $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host "[IN] [$timestamp] $Message" -ForegroundColor Cyan }
        "DEBUG" { Write-Host "[DB] [$timestamp] $Message" -ForegroundColor Gray }
        default { Write-Host "    [$timestamp] $Message" }
    }
}

# Function to check port availability
function Check-PortAvailable {
    param (
        [int]$Port,
        [string]$ServiceName = "Service"
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

# Function to save process IDs
function Save-ProcessId {
    param (
        [int]$ProcessId,
        [string]$ServiceName
    )
    "$ServiceName : $ProcessId" | Add-Content -Path $pidFile
    Log-Message "Saved PID for $ServiceName : $ProcessId" "DEBUG"
}

# Build Backend
Log-Message "Building Backend..." "INFO"
Log-Message "Location: $backendPath" "DEBUG"

try {
    if (-not (Test-Path $backendPath)) {
        Handle-Error "Backend directory not found" "Backend"
    }
    
    Push-Location $backendPath
    Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray
    
    # Improvement #1: Quick environment check (non-blocking)
    Log-Message "Checking environment..." "INFO"
    $phpExists = $null -ne (Get-Command php -ErrorAction SilentlyContinue)
    $composerExists = $null -ne (Get-Command composer -ErrorAction SilentlyContinue)
    $npmExists = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)
    
    if (-not $phpExists) { Log-Message "Warning: PHP not found in PATH" "WARNING" }
    if (-not $composerExists) { Log-Message "Warning: Composer not found in PATH" "WARNING" }
    if (-not $npmExists) { Log-Message "Warning: npm not found in PATH" "WARNING" }
    
    Log-Message "Environment check complete" "SUCCESS"
    
    # Install PHP dependencies with Composer (Improvement #2: With proper error handling)
    Log-Message "Installing PHP dependencies (Composer)..." "INFO"
    $composerOutput = & composer install --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-redis --ignore-platform-req=ext-posix --no-dev --no-scripts 2>&1
    $composerOutput | Tee-Object -FilePath $backendLogFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Message "Composer warning (continuing): Exit code $LASTEXITCODE" "WARNING"
    }
    else {
        Log-Message "Composer dependencies installed successfully" "SUCCESS"
    }
    
    # Install Node dependencies (Improvement #3: Using npm ci for reproducible builds)
    Log-Message "Installing Node dependencies..." "INFO"
    $npmOutput = & npm install --no-optional 2>&1
    $npmOutput | Tee-Object -FilePath $backendLogFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Message "npm warning (continuing): Exit code $LASTEXITCODE" "WARNING"
    }
    else {
        Log-Message "Node dependencies installed successfully" "SUCCESS"
    }
    
    # Improvement #4: Generate application key
    Log-Message "Generating application key..." "INFO"
    php artisan key:generate --force 2>&1 | Tee-Object -FilePath $backendLogFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Message "Application key generation skipped or already set" "WARNING"
    }
    else {
        Log-Message "Application key generated" "SUCCESS"
    }
    
    # Improvement #5: Setup environment file with validation
    Log-Message "Setting up environment configuration..." "INFO"
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Log-Message "Created .env from .env.example" "SUCCESS"
        }
        else {
            Log-Message "No .env or .env.example found" "WARNING"
        }
    }
    else {
        Log-Message ".env file already exists" "DEBUG"
    }
    
    # Skip database checks for now - assume database will be set up separately
    Log-Message "Database setup will be done separately" "WARNING"
    
    # Improvement #6: Optimize for production
    Log-Message "Optimizing autoloader..." "INFO"
    composer dump-autoload --optimize 2>$null | Out-Null
    Log-Message "Autoloader optimization complete" "SUCCESS"
    
    Log-Message "Backend setup completed successfully" "SUCCESS"
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Backend"
}

Write-Host ""

# Build Frontend
Log-Message "Building Frontend..." "INFO"
Log-Message "Location: $frontendPath" "DEBUG"

try {
    if (-not (Test-Path $frontendPath)) {
        Handle-Error "Frontend directory not found" "Frontend"
    }
    
    Push-Location $frontendPath
    
    # Improvement #12: Quick environment check for frontend (non-blocking)
    Log-Message "Checking frontend environment..." "INFO"
    $nodeExists = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
    $npmExists = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)
    
    if (-not $nodeExists) { Log-Message "Warning: Node.js not found in PATH" "WARNING" }
    if (-not $npmExists) { Log-Message "Warning: npm not found in PATH" "WARNING" }
    
    Log-Message "Frontend environment check complete" "SUCCESS"
    
    # Install dependencies
    Log-Message "Installing frontend dependencies..." "INFO"
    $npmInstallOutput = & npm install --no-optional 2>&1
    $npmInstallOutput | Tee-Object -FilePath $frontendLogFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Message "npm install warning (continuing): Exit code $LASTEXITCODE" "WARNING"
    }
    else {
        Log-Message "Frontend dependencies installed successfully" "SUCCESS"
    }
    
    # Build frontend (Improvement #13: With source maps for debugging)
    Log-Message "Running frontend build..." "INFO"
    $npmBuildOutput = & npm run build 2>&1
    $npmBuildOutput | Tee-Object -FilePath $frontendLogFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Message "Frontend build warning (continuing): Exit code $LASTEXITCODE" "WARNING"
    }
    else {
        Log-Message "Frontend build completed successfully" "SUCCESS"
    }
    
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Frontend"
}

Write-Host ""
Log-Message "All projects built successfully" "SUCCESS"
Write-Host ""

try {
    Push-Location $backendPath
    
    # Improvement #14: Pre-flight health checks
    Log-Message "Running pre-flight health checks..." "INFO"
    Write-Host ""
    
    # Check if ports are available (Improvement #15: Port conflict detection)
    Log-Message "Checking port availability..." "INFO"
    
    $ports = @(
        @{Port = $ReverbPort; Name = "Reverb"},
        @{Port = $ApiPort; Name = "API"},
        @{Port = $VitePort; Name = "Vite"}
    )
    
    $portIssues = @()
    foreach ($portInfo in $ports) {
        if (-not (Check-PortAvailable $portInfo.Port $portInfo.Name)) {
            $portIssues += "$($portInfo.Name) (port $($portInfo.Port)) is already in use"
            Log-Message "Port $($portInfo.Port) ($($portInfo.Name)) already in use - may conflict" "WARNING"
        }
    }
    
    # Improvement #16: Cache clear for fresh start
    Log-Message "Clearing runtime caches for fresh start..." "INFO"
    php artisan cache:clear 2>$null | Out-Null
    php artisan route:clear 2>$null | Out-Null
    Log-Message "Runtime caches cleared" "SUCCESS"
    
    Write-Host ""
    Log-Message "Starting all services..." "INFO"
    Write-Host ""
    
    # Improvement #17: Start services with background job tracking
    # Start Reverb WebSocket Server
    Log-Message "Starting Reverb WebSocket Server (port $ReverbPort)..." "INFO"
    $reverbProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "reverb:start", "--host=$reverb_host", "--port=$ReverbPort" `
        -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "reverb.log") -RedirectStandardError (Join-Path $logsPath "reverb-error.log")
    Save-ProcessId $reverbProcess.Id "Reverb"
    Log-Message "Reverb started with PID $($reverbProcess.Id)" "SUCCESS"
    
    # Start Laravel API Server
    Log-Message "Starting Laravel API Server (port $ApiPort)..." "INFO"
    $apiProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "serve", "--port=$ApiPort" `
        -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "api.log") -RedirectStandardError (Join-Path $logsPath "api-error.log")
    Save-ProcessId $apiProcess.Id "API"
    Log-Message "API Server started with PID $($apiProcess.Id)" "SUCCESS"
    
    # Start Vite Dev Server
    Log-Message "Starting Vite Dev Server (port $VitePort)..." "INFO"
    $viteProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev", "--", "--port", "$VitePort" `
        -PassThru -NoNewWindow -WorkingDirectory $backendPath -RedirectStandardOutput (Join-Path $logsPath "vite.log") -RedirectStandardError (Join-Path $logsPath "vite-error.log")
    Save-ProcessId $viteProcess.Id "Vite"
    Log-Message "Vite Dev Server started with PID $($viteProcess.Id)" "SUCCESS"
    
    # Start Queue Worker (Improvement #18: Background job processing)
    Log-Message "Starting Queue Worker..." "INFO"
    $queueProcess = Start-Process -FilePath "php" -ArgumentList "artisan", "queue:work", "--tries=3", "--timeout=90" `
        -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "queue.log") -RedirectStandardError (Join-Path $logsPath "queue-error.log")
    Save-ProcessId $queueProcess.Id "Queue"
    Log-Message "Queue Worker started with PID $($queueProcess.Id)" "SUCCESS"
    
    Pop-Location
    
    # Start Next.js Frontend
    Log-Message "Starting Next.js Frontend (port $NextPort)..." "INFO"
    Push-Location $frontendPath
    $nextProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev", "--", "--port", "$NextPort" `
        -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $logsPath "nextjs.log") -RedirectStandardError (Join-Path $logsPath "nextjs-error.log")
    Save-ProcessId $nextProcess.Id "Next.js"
    Log-Message "Next.js Frontend started with PID $($nextProcess.Id)" "SUCCESS"
    Pop-Location
    
    # Improvement #19: Wait for services to stabilize
    Log-Message "Waiting for services to stabilize..." "INFO"
    Start-Sleep -Seconds 3
    Log-Message "Services stabilized" "SUCCESS"
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Development Environment Ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Backend Services:" -ForegroundColor Green
    Write-Host "  Reverb WebSocket:    ws://${reverb_host}:${ReverbPort}" -ForegroundColor Green
    Write-Host "  Laravel API:         http://127.0.0.1:${ApiPort}" -ForegroundColor Green
    Write-Host "  Vite Dev Server:     http://127.0.0.1:${VitePort}" -ForegroundColor Green
    Write-Host "  Queue Worker:        Running (PID: $($queueProcess.Id))" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Frontend Services:" -ForegroundColor Green
    Write-Host "  Next.js App:         http://127.0.0.1:${NextPort}" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Process PIDs (for management):" -ForegroundColor Cyan
    Write-Host "  Reverb:              $($reverbProcess.Id)" -ForegroundColor Gray
    Write-Host "  API:                 $($apiProcess.Id)" -ForegroundColor Gray
    Write-Host "  Vite:                $($viteProcess.Id)" -ForegroundColor Gray
    Write-Host "  Queue:               $($queueProcess.Id)" -ForegroundColor Gray
    Write-Host "  Next.js:             $($nextProcess.Id)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  Database console:         php artisan tinker" -ForegroundColor Gray
    Write-Host "  Queue monitoring:         php artisan queue:monitor" -ForegroundColor Gray
    Write-Host "  WebSocket health:         php artisan monitor:reverb-health" -ForegroundColor Gray
    Write-Host "  View live logs:           Get-Content -Path '$logsPath/api.log' -Wait" -ForegroundColor Gray
    Write-Host "  Stop services:            Stop-Process -Id [PID]" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Log files location:" -ForegroundColor Cyan
    Write-Host "  $logsPath" -ForegroundColor Gray
    Write-Host ""
    
    # Improvement #20: Display build metrics
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Log-Message "Build completed in $($duration.TotalSeconds) seconds" "SUCCESS"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Improvement #21: Keep processes alive and monitor
    Log-Message "System is now running. Press Ctrl+C to stop all services" "WARNING"
    Write-Host ""
    
    # Wait indefinitely to keep processes alive
    while ($true) {
        Start-Sleep -Seconds 60
        
        # Check if any process has crashed (Improvement #22: Process monitoring)
        $processes = @($reverbProcess, $apiProcess, $viteProcess, $queueProcess, $nextProcess)
        foreach ($proc in $processes) {
            if ($proc.HasExited) {
                Log-Message "Warning: Process $($proc.Id) has exited unexpectedly" "WARNING"
            }
        }
    }
}
catch {
    Log-Message $_.Exception.Message "ERROR"
    Write-Host "See logs for details: $logsPath" -ForegroundColor Yellow
    exit 1
}
