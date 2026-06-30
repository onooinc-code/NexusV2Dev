# Admin Dashboard (admin)

## Overview
The Admin Dashboard handles System Monitoring & Server Management. It provides visibility into the system's performance, background services, build controls, logs, and Dead Letter Queues (DLQs).

## Design Details
- **Background**: `bg-gradient-to-br from-slate-950 via-slate-900 to-slate-850`.
- **Header**: Sticky top with blur effect (`backdrop-blur-xl`). Contains title, description, Auto-Refresh toggle, and a manual Refresh button.
- **Tabs Navigation**: Border-bottom style tabs with icons:
  1. Overview (Activity icon)
  2. Services (Network icon)
  3. Build Control (Package icon)
  4. DLQ Management (AlertCircle icon)
  5. Logs (HardDrive icon)

## Core Features

### 1. Auto-refresh Mechanism
- Toggles an interval (e.g., every 5 seconds) to fetch system status from `/admin/system/status`.

### 2. Overview Tab (`SystemStatus`)
- Displays overall system metrics (CPU, RAM, Disk usage, etc.).

### 3. Services Tab (`ServiceManager`)
- Lists background services (e.g., database, redis, background workers, waha).
- Probably allows restarting or viewing service status.

### 4. Build Control Tab (`BuildControl`)
- Interface for triggering cache clears, config caching, or frontend build steps if applicable.

### 5. DLQ Management Tab (`DlqManager`)
- Dead Letter Queue management.
- Shows failed background jobs, with options to retry or purge them.

### 6. Logs Tab (`LogsViewer`)
- Real-time or paginated log viewer for the application logs.
