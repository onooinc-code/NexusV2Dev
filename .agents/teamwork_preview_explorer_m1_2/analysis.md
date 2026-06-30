# Analysis Report: Milestone 1 - Global Layout & Design Parity

This analysis presents a comprehensive strategy to achieve complete visual and functional parity between the Laravel monolithic Blade views and the Next.js reference frontend for Milestone 1.

---

## 1. CSS & Design System Parity (to be added to `custom.css`)

### A. Core Fonts
Next.js imports `Inter` (sans-serif) and `JetBrains Mono` (monospace). To match, we must load these Google Fonts in the HTML head and define their CSS variables in `custom.css`:

```css
/* Google Fonts Import in HTML (head) */
/*
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
*/

/* CSS Variables */
:root {
    --font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    --font-mono: 'JetBrains Mono', SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    
    /* Theme Colors Parity */
    --nexus-bg: #0b0e14;         /* Next.js deep-space */
    --nexus-panel: #161b22;      /* Next.js surface-dark */
    --nexus-primary: #007AFF;    /* Next.js nexus-blue */
    --nexus-secondary: #6366F1;  /* Next.js hedral-purple */
    
    /* Status Colors */
    --nexus-success: #10b981;    /* Next.js emerald-500 success */
    --nexus-warning: #f59e0b;    /* Next.js amber-500 warning */
    --nexus-error: #ef4444;      /* Next.js rose-500 error */
    --nexus-info: #3b82f6;       /* Next.js blue-500 info */
}

/* Global Font Apply */
body {
    font-family: var(--font-sans);
    background-color: var(--nexus-bg);
}
code, pre, .font-mono {
    font-family: var(--font-mono);
}
```

### B. Glassmorphism & Background Grid Parity
Next.js applies a clean `.glass` border/background utility and a subtle grid pattern `.bg-grid`.

```css
/* Unified Glassmorphism Utility */
.glass {
    background: rgba(22, 27, 34, 0.7) !important;
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

/* Page Grid Background */
.bg-grid {
    background-image:
        linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
    background-size: 32px 32px;
}

/* Apply Glass to Cards to match Next.js card backgrounds (bg-black/70 or glass) */
.card {
    background-color: rgba(22, 27, 34, 0.7) !important;
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid var(--nexus-border) !important;
    border-radius: 12px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
}
```

### C. Perspective, 3D and Animations Parity
To support components such as the `ContactCard3D` or data loading indicators:

```css
/* 3D Transform Utilities */
.perspective-1000 {
    perspective: 1000px;
}
.preserve-3d {
    transform-style: preserve-3d;
}

/* Horizontal Flow Animation (Telemetric Teleporting Effect) */
@keyframes flow-horizontal {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(300%); }
}
.animate-flow-horizontal {
    animation: flow-horizontal 2s linear infinite;
}

/* Vertical Flow Animation */
@keyframes flow-vertical {
    0% { transform: translateY(-100%); }
    100% { transform: translateY(300%); }
}
.animate-flow-vertical {
    animation: flow-vertical 2s linear infinite;
}

/* Value Change Flash Indicator */
@keyframes value-flash {
    0%   { background-color: rgba(0, 122, 255, 0.2); }
    100% { background-color: transparent; }
}
.animate-value-flash {
    animation: value-flash 600ms ease-out forwards;
}

/* Status Indicator Pulse Animation */
@keyframes status-pulse {
    0% { opacity: 0.4; }
    100% { opacity: 1; }
}
```

---

## 2. Structural & Functional Parity (to be added to `app.blade.php`)

To reflect Next.js layout structures, the Laravel layout needs structural updates in the **Sidebar Navigation** and the **Global Status Bar**.

### A. Sidebar Navigation Parity (Expandable NavRail)
Next.js features an expandable/collapsible sidebar. On desktop, it collapses into a narrow icon-only "NavRail" (`80px`), rather than hiding offscreen. On mobile, it slides offscreen. 

We can achieve this in Laravel with the following adjustments:

#### 1. CSS for Collapsed Sidebar (Add to `custom.css`)
```css
/* Base Transition Rules */
#sidebar-wrapper {
    width: 260px;
    transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
#page-content-wrapper {
    transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.h-16 {
    height: 64px !important;
}
.bg-gradient-nexus {
    background: linear-gradient(135deg, var(--nexus-primary) 0%, var(--nexus-secondary) 100%);
}

/* Collapsed Sidebar Rail state */
body.sidebar-collapsed #sidebar-wrapper {
    width: 80px;
}
body.sidebar-collapsed #sidebar-wrapper .sidebar-text,
body.sidebar-collapsed #sidebar-wrapper .sidebar-link-text {
    display: none !important;
}
body.sidebar-collapsed #sidebar-wrapper .list-group-item {
    justify-content: center;
    padding-left: 0 !important;
    padding-right: 0 !important;
    margin: 4px 8px;
    text-align: center;
}
body.sidebar-collapsed #sidebar-wrapper .list-group-item i {
    margin-right: 0 !important;
    font-size: 1.2rem;
}
```

#### 2. Active Link Checks & Icon Mapping (Blade Templates)
Currently, Laravel does not dynamically mark active links. Add Blade conditionals on each item, map to the corrected FontAwesome icons, and wrap link text in `.sidebar-link-text` classes:

```html
<div class="list-group list-group-flush mt-3">
    <!-- Dashboard -->
    <a href="{{ url('/hub/dashboard') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.dashboard') ? 'active' : '' }}">
        <i class="fa-solid fa-table-columns me-3"></i>
        <span class="sidebar-link-text">NexusHub</span>
    </a>
    
    <!-- People Connect -->
    <a href="{{ url('/hub/people-connect') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.people-connect') ? 'active' : '' }}">
        <i class="fa-regular fa-comment-dots me-3"></i>
        <span class="sidebar-link-text">People Connect</span>
    </a>

    <!-- Conversations (Missing link to add for full parity) -->
    <a href="{{ url('/hub/conversations') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.conversations') ? 'active' : '' }}">
        <i class="fa-regular fa-message me-3"></i>
        <span class="sidebar-link-text">Conversations</span>
    </a>

    <!-- Contacts -->
    <a href="{{ url('/hub/contacts') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.contacts*') ? 'active' : '' }}">
        <i class="fa-solid fa-user-group me-3"></i>
        <span class="sidebar-link-text">ContactsHub</span>
    </a>

    <!-- Agents -->
    <a href="{{ url('/hub/agents') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.agents*') ? 'active' : '' }}">
        <i class="fa-solid fa-cpu me-3"></i>
        <span class="sidebar-link-text">AgentsHub</span>
    </a>

    <!-- Workflows -->
    <a href="{{ url('/hub/workflows') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.workflows*') ? 'active' : '' }}">
        <i class="fa-solid fa-code-merge me-3"></i>
        <span class="sidebar-link-text">WorkflowsHub</span>
    </a>

    <!-- AI Models -->
    <a href="{{ url('/hub/models') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.models*') ? 'active' : '' }}">
        <i class="fa-solid fa-wand-magic-sparkles me-3"></i>
        <span class="sidebar-link-text">AIModelsHub</span>
    </a>

    <!-- Proactive AI -->
    <a href="{{ url('/hub/proactive-ai') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.proactive-ai') ? 'active' : '' }}">
        <i class="fa-solid fa-robot me-3"></i>
        <span class="sidebar-link-text">Proactive AI</span>
    </a>

    <!-- Hedra Soul -->
    <a href="{{ url('/hub/hedra-soul') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.hedra-soul') ? 'active' : '' }}">
        <i class="fa-solid fa-brain me-3"></i>
        <span class="sidebar-link-text">Hedra Soul</span>
    </a>

    <!-- Tasks -->
    <a href="{{ url('/hub/tasks') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.tasks*') ? 'active' : '' }}">
        <i class="fa-regular fa-square-check me-3"></i>
        <span class="sidebar-link-text">Task Objectives</span>
    </a>

    <!-- Scheduler -->
    <a href="{{ url('/hub/scheduler') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.scheduler*') ? 'active' : '' }}">
        <i class="fa-regular fa-clock me-3"></i>
        <span class="sidebar-link-text">Scheduler</span>
    </a>

    <!-- Memory -->
    <a href="{{ url('/hub/memory') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.memory*') ? 'active' : '' }}">
        <i class="fa-solid fa-brain me-3"></i>
        <span class="sidebar-link-text">MemoryHub</span>
    </a>

    <!-- APIs -->
    <a href="{{ url('/hub/apis') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.apis*') ? 'active' : '' }}">
        <i class="fa-solid fa-network-wired me-3"></i>
        <span class="sidebar-link-text">API & MCP</span>
    </a>

    <!-- Logs -->
    <a href="{{ url('/hub/logs') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.logs*') ? 'active' : '' }}">
        <i class="fa-solid fa-file-lines me-3"></i>
        <span class="sidebar-link-text">LogsHub</span>
    </a>

    <!-- Waha Manage -->
    <a href="{{ url('/hub/waha') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.waha*') ? 'active' : '' }}">
        <i class="fa-brands fa-whatsapp me-3"></i>
        <span class="sidebar-link-text">Waha Manage</span>
    </a>

    <!-- Settings -->
    <a href="{{ url('/hub/settings') }}" class="list-group-item list-group-item-action d-flex align-items-center py-3 {{ request()->routeIs('hub.settings*') ? 'active' : '' }}">
        <i class="fa-solid fa-gear me-3"></i>
        <span class="sidebar-link-text">SettingsHub</span>
    </a>
</div>
```

#### 3. Menu Toggle Javascript Update
Replace the toggle function in `app.blade.php` to handle desktop (Rail Collapse) and mobile (overlay shift):
```javascript
$('#menu-toggle').click(function(e) {
    e.preventDefault();
    if ($(window).width() > 768) {
        $('body').toggleClass('sidebar-collapsed');
        window.dispatchEvent(new Event('resize'));
    } else {
        $('body').toggleClass('toggled');
    }
});
```

---

### B. Global Status Bar Parity & Live Metrics

The current status bar in `app.blade.php` is static. We must rewrite it structurally and back it with dynamic data fetching/listeners matching Next.js `NxStatusBar.tsx`.

#### 1. HTML Layout Replacement for Status Bar
```html
<div id="nexus-statusbar" class="fixed-bottom bg-surface-dark border-top border-secondary d-flex justify-content-between align-items-center px-3 py-1 font-mono position-relative overflow-hidden" style="height: 40px; z-index: 1050; font-size: 0.8rem; color: #94a3b8;">
    <!-- Telemetric loading progress bar overlay -->
    <div id="statusbar-loading-bar" class="position-absolute top-0 start-0 h-100 bg-primary opacity-10" style="width: 0%; transition: width 0.2s ease-out;"></div>
    
    <!-- Left side: Hub Info and health text -->
    <div class="d-flex align-items-center gap-3 position-relative z-3">
        <span class="status-dot-indicator unknown" id="statusbar-backend-dot"></span>
        <div>
            <div class="fw-semibold text-light text-truncate" style="font-size: 11px;">
                <span id="statusbar-hub-name">NexusHub</span> · <span id="statusbar-app-name">Nexus Backend</span>
            </div>
            <div class="text-secondary text-truncate" style="font-size: 10px;" id="statusbar-health-desc">
                Checking connection...
            </div>
        </div>
    </div>

    <!-- Middle side: Connection chips (Backend, Reverb, Queue, Auth) -->
    <div class="d-none d-md-flex align-items-center gap-3 position-relative z-3">
        <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1" style="font-size: 10px;">
            <span class="status-dot-indicator unknown" id="chip-backend-dot"></span>
            <span class="text-secondary">Backend</span>
        </div>
        <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1" style="font-size: 10px;">
            <span class="status-dot-indicator unknown" id="chip-reverb-dot"></span>
            <span class="text-secondary">Reverb</span>
        </div>
        <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1" style="font-size: 10px;">
            <span class="status-dot-indicator unknown" id="chip-queue-dot"></span>
            <span class="text-secondary">Queue</span>
        </div>
        <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1" style="font-size: 10px;">
            <span class="status-dot-indicator online" id="chip-auth-dot"></span>
            <span class="text-secondary">Auth</span>
        </div>
    </div>

    <!-- Right side: Action buttons -->
    <div class="d-flex align-items-center gap-2 position-relative z-3">
        <button class="btn btn-outline-secondary btn-sm px-3 py-0 uppercase tracking-widest font-mono text-light" style="font-size: 10px; border-color: rgba(255,255,255,0.1); background-color: rgba(255,255,255,0.05);" data-bs-toggle="modal" data-bs-target="#detailsModal">DETAILS</button>
        <button class="btn btn-outline-secondary btn-sm px-3 py-0 uppercase tracking-widest font-mono text-light" style="font-size: 10px; border-color: rgba(255,255,255,0.1); background-color: rgba(255,255,255,0.05);" id="statusbar-btn-logs">LOGS</button>
        <button class="btn btn-outline-secondary btn-sm px-3 py-0 uppercase tracking-widest font-mono text-light" style="font-size: 10px; border-color: rgba(255,255,255,0.1); background-color: rgba(255,255,255,0.05);" id="statusbar-btn-jobs">JOBS</button>
        <button class="btn btn-outline-secondary btn-sm px-3 py-0 uppercase tracking-widest font-mono text-light d-flex align-items-center gap-1" style="font-size: 10px; border-color: rgba(255,255,255,0.1); background-color: rgba(255,255,255,0.05);" id="statusbar-btn-notifications">
            <i class="fa-regular fa-bell" style="font-size: 10px;"></i> NOTIFICATIONS
        </button>
    </div>
</div>
```

#### 2. Modals Structure to Append to HTML Body
Add the dynamic Bootstrap 5 modals for "DETAILS" and "LOGS":

```html
<!-- Details Modal -->
<div class="modal fade" id="detailsModal" tabindex="-1" aria-labelledby="detailsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content glass border border-secondary" style="background-color: rgba(22, 27, 34, 0.95);">
            <div class="modal-header border-bottom border-secondary">
                <h5 class="modal-title text-light" id="detailsModalLabel">Status Details</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-light">
                <div class="row g-3 mb-4">
                    <div class="col-12 col-sm-6">
                        <div class="p-3 border border-secondary rounded bg-dark bg-opacity-50">
                            <div class="text-uppercase text-secondary mb-1" style="font-size: 10px; letter-spacing: 0.25em;">Backend Health</div>
                            <div class="fs-5 fw-bold text-light text-capitalize" id="modal-health-status">Unknown</div>
                            <div class="text-secondary mt-1" style="font-size: 11px;" id="modal-health-app">Nexus Backend</div>
                            <div class="text-muted" style="font-size: 10px;" id="modal-health-time">--</div>
                        </div>
                    </div>
                    <div class="col-12 col-sm-6">
                        <div class="p-3 border border-secondary rounded bg-dark bg-opacity-50">
                            <div class="text-uppercase text-secondary mb-1" style="font-size: 10px; letter-spacing: 0.25em;">Queue Metrics</div>
                            <div class="fs-5 fw-bold text-light"><span id="modal-queue-running">—</span> active</div>
                            <div class="text-secondary mt-1" style="font-size: 11px;"><span id="modal-queue-pending">—</span> queued</div>
                            <div class="text-muted" style="font-size: 10px;"><span id="modal-queue-failed">—</span> failed</div>
                        </div>
                    </div>
                </div>
                <div>
                    <div class="text-uppercase text-secondary mb-2" style="font-size: 10px; letter-spacing: 0.25em;">Service Snapshot</div>
                    <pre class="p-3 border border-secondary rounded text-light overflow-x-auto" style="background-color: rgba(0,0,0,0.7); font-size: 11px; max-height: 250px;" id="modal-snapshot-raw">{}</pre>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Logs Modal -->
<div class="modal fade" id="logsModal" tabindex="-1" aria-labelledby="logsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content glass border border-secondary" style="background-color: rgba(22, 27, 34, 0.95);">
            <div class="modal-header border-bottom border-secondary">
                <h5 class="modal-title text-light" id="logsModalLabel">System Log Statistics</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-light" id="modal-logs-body" style="font-size: 12px; max-height: 500px; overflow-y: auto;">
                <div class="text-center py-4 text-secondary">Loading system logs...</div>
            </div>
        </div>
    </div>
</div>
```

#### 3. Dynamic Javascript logic to initialize in `<script>` tags
Add the dynamic telemetry updates, path detection, WebSockets state listener, and log aggregation modals inside the footer:

```javascript
$(document).ready(function() {
    // 1. Dynamic Hub Page Title Mapping
    const pageNameMap = {
        '/hub/dashboard': 'NexusHub',
        '/hub/people-connect': 'ConversationsHub',
        '/hub/contacts': 'ContactsHub',
        '/hub/agents': 'AgentsHub',
        '/hub/workflows': 'WorkflowsHub',
        '/hub/tasks': 'TasksHub',
        '/hub/scheduler': 'SchedulerHub',
        '/hub/memory': 'MemoryHub',
        '/hub/apis': 'APIsHub',
        '/hub/logs': 'LogsHub',
        '/hub/models': 'AIModelsHub',
        '/hub/settings': 'SettingsHub',
        '/hub/hedra-soul': 'HedraSoulHub',
        '/hub/proactive-ai': 'Proactive AI',
        '/hub/admin': 'AdminHub',
        '/hub/waha': 'WahaHub'
    };
    
    const currentPath = window.location.pathname;
    let detectedHubName = 'Nexus Workspace';
    for (const [route, name] of Object.entries(pageNameMap)) {
        if (currentPath === route || currentPath.startsWith(route + '/')) {
            detectedHubName = name;
            break;
        }
    }
    $('#statusbar-hub-name').text(detectedHubName);

    // 2. Periodic Telemetry Data Polling (every 30 seconds)
    let healthData = { status: 'unknown', app: 'Nexus Backend', timestamp: '--', details: {} };
    let taskStatsData = null;

    async function pollStatus() {
        // Fetch /api/v1/health
        try {
            const res = await $.ajax({
                url: '/api/v1/health',
                method: 'GET',
                timeout: 10000
            });
            healthData.status = res.status || 'unhealthy';
            healthData.app = res.app || 'Nexus Backend';
            healthData.timestamp = res.timestamp || new Date().toISOString();
            healthData.details = res;
            
            updateIndicator('backend', healthData.status === 'healthy' ? 'online' : 'offline');
            $('#statusbar-app-name').text(healthData.app);
            $('#statusbar-health-desc').text('All systems nominal · ' + new Date(healthData.timestamp).toLocaleTimeString());
            
            // Update Details Modal Fields
            $('#modal-health-status').text(healthData.status).removeClass('text-danger text-success').addClass(healthData.status === 'healthy' ? 'text-success' : 'text-danger');
            $('#modal-health-app').text(healthData.app);
            $('#modal-health-time').text(healthData.timestamp);
        } catch (err) {
            updateIndicator('backend', 'error');
            $('#statusbar-health-desc').text('Health error: ' + (err.statusText || 'Offline'));
            
            $('#modal-health-status').text('Unhealthy').removeClass('text-success').addClass('text-danger');
        }

        // Fetch /api/v1/tasks/stats
        try {
            const res = await $.ajax({
                url: '/api/v1/tasks/stats',
                method: 'GET',
                timeout: 10000
            });
            taskStatsData = res.data || res || null;
            const pending = taskStatsData?.pending ?? 0;
            const running = taskStatsData?.running ?? 0;
            const failed = taskStatsData?.failed ?? 0;
            
            const queueState = (pending > 0 || running > 0) ? 'online' : 'offline';
            updateIndicator('queue', queueState);
            
            // Update Details Modal fields
            $('#modal-queue-running').text(running);
            $('#modal-queue-pending').text(pending);
            $('#modal-queue-failed').text(failed);
        } catch (err) {
            updateIndicator('queue', 'unknown');
            $('#modal-queue-running').text('—');
            $('#modal-queue-pending').text('—');
            $('#modal-queue-failed').text('—');
        }

        // Render Service Snapshot Pre tag
        $('#modal-snapshot-raw').text(JSON.stringify({ health: healthData.details, taskStats: taskStatsData }, null, 2));
    }

    function updateIndicator(target, state) {
        // target is 'backend' or 'queue' or 'reverb'
        const dotElement = target === 'backend' 
            ? $('#statusbar-backend-dot, #chip-backend-dot')
            : (target === 'queue' ? $('#chip-queue-dot') : $('#chip-reverb-dot'));
            
        dotElement.removeClass('online offline error unknown connecting').addClass(state);
    }

    // Run Polling
    pollStatus();
    setInterval(pollStatus, 30000);

    // 3. Reverb Websocket state hook
    function updateReverbStatus(state) {
        let chipState = 'unknown';
        if (state === 'connected') chipState = 'online';
        else if (state === 'connecting') chipState = 'connecting';
        else if (['disconnected', 'unavailable', 'failed'].includes(state)) chipState = 'offline';
        
        updateIndicator('reverb', chipState);
    }

    if (window.Echo && window.Echo.connector && window.Echo.connector.pusher) {
        window.Echo.connector.pusher.connection.bind('state_change', function(states) {
            updateReverbStatus(states.current);
        });
        updateReverbStatus(window.Echo.connector.pusher.connection.state);
    } else {
        updateReverbStatus('unknown');
    }

    // 4. Logs Modal Trigger & Aggregator
    const logsModal = new bootstrap.Modal(document.getElementById('logsModal'));
    $('#statusbar-btn-logs').click(async function() {
        logsModal.show();
        $('#modal-logs-body').html('<div class="text-center py-4"><div class="spinner-border text-primary" role="status"></div><div class="mt-2 text-secondary">Fetching system log metrics...</div></div>');
        
        try {
            const res = await $.ajax({
                url: '/api/v1/logs/stats',
                method: 'GET'
            });
            const data = res.data || res;
            
            // Build logs UI
            let htmlContent = `
                <div class="rounded bg-black bg-opacity-40 p-3 mb-3 border border-secondary">
                    <div class="text-uppercase text-secondary mb-1" style="font-size: 10px; letter-spacing: 0.15em;">Total Entries</div>
                    <div class="fs-4 fw-bold text-primary">${data.total || 0}</div>
                </div>
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <div class="rounded bg-black bg-opacity-40 p-3 border border-secondary">
                            <div class="text-uppercase text-secondary mb-1" style="font-size: 10px; letter-spacing: 0.15em;">Today</div>
                            <div class="fs-5 fw-bold text-light">${data.today || 0}</div>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="rounded bg-black bg-opacity-40 p-3 border ${data.errors_today > 0 ? 'border-danger' : 'border-secondary'}">
                            <div class="text-uppercase text-danger mb-1" style="font-size: 10px; letter-spacing: 0.15em;">Errors Today</div>
                            <div class="fs-5 fw-bold text-danger">${data.errors_today || 0}</div>
                        </div>
                    </div>
                </div>
            `;
            
            if (data.by_level && Object.keys(data.by_level).length > 0) {
                htmlContent += `
                    <div class="rounded bg-black bg-opacity-40 p-3 mb-3 border border-secondary">
                        <div class="text-uppercase text-secondary mb-2" style="font-size: 10px; letter-spacing: 0.15em;">Logs by Level</div>
                        <div class="space-y-2">
                `;
                for (const [level, count] of Object.entries(data.by_level)) {
                    const pct = ((count / (data.total || 1)) * 100).toFixed(0);
                    let colorClass = 'bg-success';
                    if (['error', 'critical', 'alert', 'emergency'].includes(level.toLowerCase())) colorClass = 'bg-danger';
                    else if (['warning', 'notice'].includes(level.toLowerCase())) colorClass = 'bg-warning';
                    else if (level.toLowerCase() === 'info') colorClass = 'bg-info';
                    
                    htmlContent += `
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <span class="text-capitalize text-secondary" style="width: 80px;">${level}</span>
                            <div class="progress flex-grow-1 mx-3 bg-dark" style="height: 6px;">
                                <div class="progress-bar ${colorClass}" role="progressbar" style="width: ${pct}%"></div>
                            </div>
                            <span class="fw-semibold text-light text-end" style="width: 40px;">${count}</span>
                        </div>
                    `;
                }
                htmlContent += `</div></div>`;
            }
            
            $('#modal-logs-body').html(htmlContent);
        } catch (err) {
            $('#modal-logs-body').html('<div class="text-center py-4 text-danger">Unable to retrieve logs statistics.</div>');
        }
    });

    // 5. Page navigation animation simulation
    // Track AJAX start and completion to fill statusbar loading bar
    $(document).ajaxStart(function() {
        $('#statusbar-loading-bar').css('width', '25%');
    });
    $(document).ajaxSend(function(event, xhr, settings) {
        $('#statusbar-loading-bar').css('width', '60%');
    });
    $(document).ajaxStop(function() {
        $('#statusbar-loading-bar').css('width', '100%');
        setTimeout(() => {
            $('#statusbar-loading-bar').css('width', '0%');
        }, 300);
    });
});
```

---

## 3. Parity Strategy Summary & Next Steps

| Domain | Next.js Reference | Current Laravel | Parity Gap | Recommendation |
|---|---|---|---|---|
| **Fonts** | Inter & JetBrains Mono | Sans-serif standard | Fallback fonts only | Link Google Fonts & define in `custom.css`. |
| **Grid** | `.bg-grid` grid background | None | Missing visual depth | Define `.bg-grid` CSS rules & apply to page wrapper. |
| **Sidebar Width** | Collapsible (80px to 260px) | Fixed (250px) | Fixed desktop spacing | Update Sidebar CSS and toggle scripts to support Desktop rail state. |
| **Active States** | Dynamic check + blue icon | Static markup | No active highlight | Inject Blade conditionals for classes; update icon colors. |
| **Telemetry** | Live status bar with chips | Hardcoded stats | No dynamic status / metrics | Replace status bar markup; add live polling + WebSockets listener. |
| **Detail Modals**| Details, Logs, Jobs, Notifications drawers | None | Missing operational diagnostics | Implement details and logs modals with dynamic API metrics. |
