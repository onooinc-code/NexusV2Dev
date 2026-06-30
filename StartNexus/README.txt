================================================================================
                    NexusV2 StartNexus - Quick Start Guide
================================================================================

This folder contains batch scripts to help you quickly set up and run the entire
NexusV2 development environment (backend + frontend).

================================================================================
                              SCRIPTS OVERVIEW
================================================================================

1. SETUP.BAT - FIRST TIME SETUP
   Purpose: Complete setup including dependency installation and environment
   When to use: First time setting up the project, or after cloning
   What it does:
     - Checks for required tools (Node.js, PHP, Composer)
     - Installs all dependencies
     - Creates .env files from examples
   How to use: Double-click setup.bat

2. INSTALL-ALL.BAT - INSTALL DEPENDENCIES
   Purpose: Install all npm and composer dependencies
   When to use: After adding new packages or if dependencies are missing
   What it does:
     - npm install (root)
     - composer install (backend)
     - npm install (backend)
     - npm install (frontend)
   How to use: Double-click install-all.bat

3. BUILD-ALL.BAT - BUILD PROJECTS
   Purpose: Build frontend for production
   When to use: Before deployment or when building for production
   What it does:
     - npm run build (frontend)
     - Generates optimized build files
   How to use: Double-click build-all.bat

4. START-ALL.BAT - START ALL SERVICES
   Purpose: Start all Nexus development servers
   When to use: When you want to run the complete development environment
   Services started:
     - Laravel API Server (http://localhost:8000)
     - Laravel Reverb (WebSocket on port 6001)
     - Vite Dev Server (http://localhost:5173)
     - Laravel Queue Worker
     - Next.js Frontend (http://localhost:3000)
   How to use: Double-click start-all.bat
   To stop: Press Ctrl+C in the terminal

4b. START-WITH-REDIS.BAT - START ALL SERVICES WITH REDIS QUEUE ⭐
   Purpose: Start all services with Redis-powered queue worker
   When to use: For production-ready environment with Redis
   Services started:
     - All services from START-ALL.BAT
     - Queue Worker using Redis (better performance)
   Queue Driver: Redis (redis://127.0.0.1:6379)
   How to use: Double-click start-with-redis.bat
   Requirements: Docker with Redis container running
   To stop: Press Ctrl+C in the terminal

5. START-BACKEND-ONLY.BAT - START BACKEND ONLY
   Purpose: Start only backend services without frontend
   When to use: When developing backend only or testing APIs
   Services started:
     - Laravel API Server (http://localhost:8000)
     - Laravel Reverb (WebSocket on port 6001)
     - Vite Dev Server (http://localhost:5173)
     - Laravel Queue Worker
   How to use: Double-click start-backend-only.bat
   To stop: Press Ctrl+C in the terminal

6. START-FRONTEND-ONLY.BAT - START FRONTEND ONLY
   Purpose: Start only frontend (Next.js) without backend
   When to use: When developing frontend only (requires backend running elsewhere)
   Services started:
     - Next.js Frontend (http://localhost:3000)
   How to use: Double-click start-frontend-only.bat
   To stop: Press Ctrl+C in the terminal

================================================================================
                            QUICK START GUIDE
================================================================================

FIRST TIME SETUP:
  1. Open command prompt or PowerShell in this StartNexus folder
  2. Run: setup.bat
  3. Wait for all dependencies to install
  4. Once complete, run: start-all.bat

AFTER FIRST SETUP:
  1. Run: start-all.bat
  2. Access the application at http://localhost:3000

================================================================================
                          REQUIREMENTS & PORTS
================================================================================

REQUIRED TOOLS:
  - Node.js (v18 or higher) - Download from https://nodejs.org/
  - PHP (v8.2 or higher) - Install via XAMPP or standalone
  - Composer - Download from https://getcomposer.org/
  - Docker Desktop - Download from https://www.docker.com/products/docker-desktop/
  - Git (recommended for version control)

SERVICES & PORTS:
  - Frontend (Next.js):        http://localhost:3000
  - Backend API (Laravel):     http://localhost:8000
  - Vite Dev Server:           http://localhost:5173
  - WebSocket (Reverb):        ws://localhost:6001
  - Redis Cache:               redis://localhost:6379

================================================================================
                            TROUBLESHOOTING
================================================================================

ERROR: "Node.js is not installed or not in PATH"
  Solution: Install Node.js from https://nodejs.org/
            Restart your command prompt or computer

ERROR: "PHP is not installed or not in PATH"
  Solution: 1. Install XAMPP from https://www.apachefriends.org/
            2. Or install PHP standalone and add to PATH
            3. Scripts will auto-detect XAMPP installations

ERROR: "Composer is not installed or not in PATH"
  Solution: Download Composer from https://getcomposer.org/
            Install and add to PATH

ERROR: "port X is already in use"
  Solution: Change the port in the respective .bat file
            Or stop the application using that port

ERROR: "node_modules not found"
  Solution: Run install-all.bat to install dependencies

ERROR: "Redis is not running"
  Solution: 1. Install Docker Desktop from https://www.docker.com/products/docker-desktop/
            2. Run: docker run -d -p 6379:6379 --name redis-nexus redis:latest
            3. Or double-click check-redis.bat

================================================================================
                          DIRECTORY STRUCTURE
================================================================================

NexusV2/
├── StartNexus/          (This folder - scripts)
│   ├── setup.bat
│   ├── install-all.bat
│   ├── build-all.bat
│   ├── start-all.bat
│   ├── start-backend-only.bat
│   ├── start-frontend-only.bat
│   └── README.txt (this file)
├── Nexus-backend/       (Laravel backend)
├── Nexus-Frontend/      (Next.js frontend)
└── package.json         (Root configuration)

================================================================================
                            DEVELOPMENT TIPS
================================================================================

1. Use start-backend-only.bat and start-frontend-only.bat separately for
   faster debugging and reduced resource usage

2. Always run setup.bat after pulling new changes from git

3. Check that all required ports (3000, 8000, 5173, 6001) are available

4. Use npm install instead of install-all.bat when adding individual packages

5. Check browser console (F12) for frontend errors

6. Check command prompt/terminal for backend errors

================================================================================
                             USEFUL COMMANDS
================================================================================

From backend folder (Nexus-backend):
  php artisan migrate           - Run database migrations
  php artisan tinker            - Interactive shell for testing
  php artisan queue:work        - Start queue worker
  php artisan optimize          - Optimize application

From frontend folder (Nexus-Frontend):
  npm run test                  - Run tests
  npm run lint                  - Run linter
  npm run build                 - Build for production

================================================================================
                         For More Information
================================================================================

Backend: See Nexus-backend/README.md
Frontend: See Nexus-Frontend/README.md
Main: See README.md in the root directory

================================================================================
