# Nexus Layout and Styling Parity Analysis

This document provides a comprehensive audit and implementation plan to achieve 100% visual and functional parity between the Next.js reference UI layout and the Laravel Blade layout for **Milestone 1: Global Layout & Design Parity**.

---

## 1. CSS & Styling Alignment (`custom.css`)

To match the Tailwind CSS utility-first framework and configuration in `Nexus-Frontend`, the following custom CSS variables, class utilities, and keyframe animations must be added to `Nexus-backend/public/css/custom.css`.

### A. Root Variable Declarations
We must expand the `:root` pseudo-class in `custom.css` to define the fonts, exact Next.js brand colors, states, and borders:

```css
:root {
    /* Font Families */
    --font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    --font-mono: 'JetBrains Mono', 'Fira Code', Menlo, Monaco, Consolas, monospace;

    /* Base Palette */
    --nexus-bg: #0b0e14;         /* deep-space */
    --nexus-panel: #161b22;      /* surface-dark */
    --nexus-border: rgba(255, 255, 255, 0.08); /* Soft glass border */

    /* Brand Gradients & Accents */
    --nexus-primary: #007AFF;    /* nexus-blue */
    --nexus-secondary: #6366F1;  /* hedral-purple */

    /* Functional Colors */
    --nexus-success: #10b981;    /* success */
    --nexus-warning: #f59e0b;    /* warning */
    --nexus-error: #ef4444;      /* error */
    --nexus-info: #3b82f6;       /* info */

    /* Typography Colors */
    --nexus-text: #f8fafc;
    --nexus-text-muted: #94a3b8;
}
```

### B. Global Font Styles
To match Next.js typography defaults:
```css
body {
    background-color: var(--nexus-bg);
    color: var(--nexus-text);
    font-family: var(--font-sans);
    overflow-x: hidden;
    background-image: radial-gradient(circle at 15% 50%, rgba(99, 102, 241, 0.05), transparent 25%),
                      radial-gradient(circle at 85% 30%, rgba(0, 122, 255, 0.05), transparent 25%);
}

code, pre, .font-mono, #nexus-statusbar {
    font-family: var(--font-mono) !important;
}
```

### C. Glassmorphism Utilities
The current card styling does not exactly match Next.js's `.glass` specifications. We define the utility class and map it to structural wrappers:
```css
/* Glassmorphic Core Utility */
.glass {
    background: rgba(22, 27, 34, 0.7) !important;
    backdrop-filter: blur(12px) !important;
    -webkit-backdrop-filter: blur(12px) !important;
    border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

/* Application to layout components */
.navbar, #sidebar-wrapper, #nexus-statusbar, .card {
    background: rgba(22, 27, 34, 0.7) !important;
    backdrop-filter: blur(12px) !important;
    -webkit-backdrop-filter: blur(12px) !important;
    border: 1px solid var(--nexus-border) !important;
}
```

### D. Layout Background Grid
The Next.js layout has a subtle background grid pattern. Add the `.bg-grid` utility:
```css
.bg-grid {
    background-image:
        linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
    background-size: 32px 32px;
}
```

### E. Animations and 3D Transformations
We must add the exact horizontal/vertical flow lines and value flash keyframes used in the Next.js frontend:
```css
/* Flow line animations (for status loading and active job visuals) */
@keyframes flow-horizontal {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(300%); }
}

@keyframes flow-vertical {
    0% { transform: translateY(-100%); }
    100% { transform: translateY(300%); }
}

.animate-flow-horizontal {
    animation: flow-horizontal 2s linear infinite;
}

.animate-flow-vertical {
    animation: flow-vertical 2s linear infinite;
}

/* Perspective utilities for 3D card layout effects */
.perspective-1000 {
    perspective: 1000px;
}

.preserve-3d {
    transform-style: preserve-3d;
}

/* Flash animation for telemetry metric updates */
@keyframes value-flash {
    0%   { background-color: rgba(0, 122, 255, 0.2); }
    100% { background-color: transparent; }
}

.animate-value-flash {
    animation: value-flash 600ms ease-out forwards;
}

/* Brand gradient background helper */
.bg-gradient-nexus {
    background: linear-gradient(135deg, var(--nexus-primary) 0%, var(--nexus-secondary) 100%);
}
```

---

## 2. Navigation Rail & Sidebar (`app.blade.php`)

To achieve complete parity with `<NxNavRail />`:

### A. Sidebar Header logo
The header must be reformatted to use the brand gradient box and typography:
```html
<div class="sidebar-heading d-flex align-items-center justify-content-center border-bottom border-white/10 shrink-0" style="height: 64px; padding: 0 16px;">
    <div class="bg-gradient-nexus d-flex align-items-center justify-content-center rounded-3 shrink-0" style="width: 32px; height: 32px;">
        <span class="text-white fw-bold" style="font-family: var(--font-sans); font-size: 1.1rem; line-height: 1;">N</span>
    </div>
    <span class="ms-3 fw-semibold text-light fs-5 tracking-tight" style="font-family: var(--font-sans);">Nexus</span>
</div>
```

### B. Mapped Navigation Items (Ordered list with Icon Parity)
The navigation rail links must be sorted, styled, and mapped to FontAwesome icons that represent the Lucide icons in `<NxNavRail />`.

Here is the exact mapping:

| Order | Next.js Item | Next.js Path | Laravel Path | FontAwesome Icon | active checking (Blade) |
|---|---|---|---|---|---|
| 1 | Dashboard | `/` | `/hub/dashboard` | `fa-solid fa-gauge-high` | `request()->is('hub/dashboard*')` |
| 2 | People Connect | `/people-connect` | `/hub/people-connect` | `fa-solid fa-comments` | `request()->is('hub/people-connect*')` |
| 3 | Conversations | `/conversations` | `/hub/conversations` | `fa-solid fa-message` | `request()->is('hub/conversations*')` |
| 4 | Contacts | `/contacts` | `/hub/contacts` | `fa-solid fa-address-book` | `request()->is('hub/contacts*')` |
| 5 | Agents | `/agents` | `/hub/agents` | `fa-solid fa-robot` | `request()->is('hub/agents*')` |
| 6 | Workflows | `/workflows` | `/hub/workflows` | `fa-solid fa-diagram-project` | `request()->is('hub/workflows*')` |
| 7 | AI Models | `/ai-models` | `/hub/models` | `fa-solid fa-wand-magic-sparkles` | `request()->is('hub/models*')` |
| 8 | Proactive AI | `/proactive-ai` | `/hub/proactive-ai` | `fa-solid fa-bolt` | `request()->is('hub/proactive-ai*')` |
| 9 | HedraSoul | `/hedra-soul` | `/hub/hedra-soul` | `fa-solid fa-ghost` | `request()->is('hub/hedra-soul*')` |
| 10 | Tasks | `/tasks` | `/hub/tasks` | `fa-solid fa-list-check` | `request()->is('hub/tasks*')` |
| 11 | Scheduler | `/scheduler` | `/hub/scheduler` | `fa-solid fa-clock` | `request()->is('hub/scheduler*')` |
| 12 | Memory | `/memory` | `/hub/memory` | `fa-solid fa-brain` | `request()->is('hub/memory*')` |
| 13 | APIs | `/apis` | `/hub/apis` | `fa-solid fa-network-wired` | `request()->is('hub/apis*')` |
| 14 | Notifications | `/notifications` | `/hub/notifications` | `fa-solid fa-bell` | `request()->is('hub/notifications*')` |
| 15 | Admin | `/admin` | `/hub/admin` | `fa-solid fa-server` | `request()->is('hub/admin*')` |
| 16 | Logs | `/logs` | `/hub/logs` | `fa-solid fa-terminal` | `request()->is('hub/logs*')` |
| 17 | WAHA Manage * | `/hub/waha` | `/hub/waha` | `fa-brands fa-whatsapp` | `request()->is('hub/waha*')` |

*\* Note: WAHA Manage is a legacy route present in Laravel but not in the Next.js sidebar. It should be retained at the bottom of the list for functional backward compatibility.*

### C. Bottom Settings & Logout Block
To achieve parity with `NxNavRail` layout, the sidebar should be split into a flex layout `flex-column h-screen`. The bottom wrapper contains Settings and Logout inside a `p-3 border-t border-white/10 shrink-0` container:

```html
<!-- Bottom Actions -->
<div class="p-3 border-t border-secondary shrink-0 d-flex flex-column gap-1">
    <a href="{{ url('/hub/settings') }}" class="list-group-item list-group-item-action {{ request()->is('hub/settings*') ? 'active' : '' }} border-0 py-2.5">
        <i class="fa-solid fa-gear"></i> Settings
    </a>
    
    <form method="POST" action="{{ route('logout') }}" id="logout-form" style="display: none;">
        @csrf
    </form>
    <a href="#" onclick="event.preventDefault(); document.getElementById('logout-form').submit();" class="list-group-item list-group-item-action text-danger border-0 py-2.5 logout-button">
        <i class="fa-solid fa-right-from-bracket"></i> Logout
    </a>
</div>
```

Modify the logout hover effect in `custom.css` to match Next.js styling (`text-gray-400 hover:text-red-400 hover:bg-red-500/10`):
```css
#sidebar-wrapper .list-group-item.logout-button {
    color: var(--nexus-text-muted) !important;
}
#sidebar-wrapper .list-group-item.logout-button:hover {
    color: #ef4444 !important;
    background-color: rgba(239, 68, 68, 0.1) !important;
}
#sidebar-wrapper .list-group-item.logout-button:hover i {
    color: #ef4444 !important;
}
```

---

## 3. Global Status Bar Connection & Telemetry (`app.blade.php`)

The status bar must be replaced with the exact dynamic interface of `NxStatusBar.tsx`.

### A. Layout Structure Replacement
Replace the current static `#nexus-statusbar` markup with the following structure:

```html
<!-- Footer Status Bar -->
<div id="nexus-statusbar" class="fixed-bottom d-flex align-items-center justify-content-between px-4 text-gray-400 shrink-0 relative overflow-hidden" style="height: 40px; z-index: 1050; font-size: 11px;">
    <!-- Navigation Progress Indicator (Underlay) -->
    <div id="nexus-statusbar-progress" class="position-absolute top-0 start-0 h-100 bg-primary bg-opacity-10 transition-all z-0" style="width: 0%; display: none;"></div>

    <div class="d-flex align-items-center justify-content-between w-100 relative z-10">
        <!-- Left Section: Page & Backend App Health -->
        <div class="d-flex align-items-center gap-3" style="min-width: 280px;">
            <span id="status-backend-dot" class="connection-dot status-unknown"></span>
            <div class="min-w-0 text-start">
                <div class="text-light fw-semibold truncate" style="font-size: 11px; line-height: 1.2;">
                    <span id="status-page-name">NexusHub</span> · <span id="status-app-name">Nexus Backend</span>
                </div>
                <div id="status-health-desc" class="text-secondary truncate" style="font-size: 10px; line-height: 1.2;">
                    Connecting to services...
                </div>
            </div>
        </div>

        <!-- Middle Section: Dynamic Status Indicators -->
        <div class="d-none d-sm-flex align-items-center gap-3 justify-content-center">
            <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1">
                <span id="dot-indicator-backend" class="connection-dot status-unknown"></span>
                <span class="text-secondary" style="font-size: 10px;">Backend</span>
            </div>
            <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1">
                <span id="dot-indicator-reverb" class="connection-dot status-unknown"></span>
                <span class="text-secondary" style="font-size: 10px;">Reverb</span>
            </div>
            <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1">
                <span id="dot-indicator-queue" class="connection-dot status-unknown"></span>
                <span class="text-secondary" style="font-size: 10px;">Queue</span>
            </div>
            <div class="d-flex align-items-center gap-2 rounded-pill border border-secondary bg-black bg-opacity-20 px-3 py-1">
                <span id="dot-indicator-auth" class="connection-dot status-unknown"></span>
                <span class="text-secondary" style="font-size: 10px;">Auth</span>
            </div>
        </div>

        <!-- Right Section: Details, Logs, Jobs, Notifications Action Toggles -->
        <div class="d-flex align-items-center gap-2">
            <button class="btn btn-status-bar" data-bs-toggle="modal" data-bs-target="#nexus-details-modal">Details</button>
            <button class="btn btn-status-bar" data-bs-toggle="modal" data-bs-target="#nexus-logs-modal" id="btn-open-logs">Logs</button>
            <button class="btn btn-status-bar" onclick="window.location.href='/hub/tasks'">Jobs</button>
            <button class="btn btn-status-bar" onclick="window.location.href='/hub/notifications'"><i class="fa-solid fa-bell me-1"></i> Notifications</button>
        </div>
    </div>
</div>
```

### B. Supporting Styling in `custom.css`
```css
/* Connection Dot Colors and Glows */
.connection-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    display: inline-block;
    transition: background-color 0.3s ease, box-shadow 0.3s ease;
}

.status-online {
    background-color: var(--nexus-success) !important;
    box-shadow: 0 0 8px var(--nexus-success);
}

.status-offline {
    background-color: var(--nexus-error) !important;
    box-shadow: 0 0 8px var(--nexus-error);
}

.status-connecting {
    background-color: var(--nexus-warning) !important;
    box-shadow: 0 0 8px var(--nexus-warning);
    animation: dot-pulse 1s infinite alternate;
}

.status-unknown {
    background-color: var(--nexus-text-muted) !important;
}

@keyframes dot-pulse {
    from { opacity: 0.5; }
    to { opacity: 1; }
}

/* Status Bar Action Button */
.btn-status-bar {
    background-color: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--nexus-border);
    border-radius: 6px;
    padding: 2px 10px;
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    color: var(--nexus-text);
    transition: all 0.2s ease;
}

.btn-status-bar:hover {
    background-color: rgba(255, 255, 255, 0.1);
    color: #fff;
    border-color: rgba(255, 255, 255, 0.2);
}
```

### C. Telemetry Logic and Event Binding
Add this script block to `app.blade.php` to fetch live data and map WebSocket states dynamically:

```javascript
document.addEventListener('DOMContentLoaded', function() {
    // 1. Pathname Mapping to Update Page Title
    const pathNameMap = {
        '/hub/dashboard': 'NexusHub',
        '/hub/people-connect': 'PeopleConnectHub',
        '/hub/conversations': 'ConversationsHub',
        '/hub/contacts': 'ContactsHub',
        '/hub/agents': 'AgentsHub',
        '/hub/workflows': 'WorkflowsHub',
        '/hub/models': 'AIModelsHub',
        '/hub/proactive-ai': 'Proactive AI',
        '/hub/hedra-soul': 'HedraSoulHub',
        '/hub/tasks': 'TasksHub',
        '/hub/scheduler': 'SchedulerHub',
        '/hub/memory': 'MemoryHub',
        '/hub/apis': 'APIsHub',
        '/hub/logs': 'LogsHub',
        '/hub/settings': 'SettingsHub',
        '/hub/admin': 'AdminHub'
    };

    const currentPath = window.location.pathname;
    const matchingTitle = Object.keys(pathNameMap).find(key => currentPath.startsWith(key)) || 'Nexus Workspace';
    document.getElementById('status-page-name').textContent = pathNameMap[matchingTitle] || matchingTitle;

    // Local Variables
    let systemHealth = { status: 'unknown', app: 'Nexus Backend', timestamp: '--', details: {} };
    let taskStats = null;

    // Helper functions to update state indicators
    function updateIndicator(id, status) {
        const dot = document.getElementById(id);
        if (!dot) return;
        dot.className = 'connection-dot';
        if (status === 'online') dot.classList.add('status-online');
        else if (status === 'offline') dot.classList.add('status-offline');
        else if (status === 'connecting') dot.classList.add('status-connecting');
        else dot.classList.add('status-unknown');
    }

    // 2. Real-Time Reverb WebSocket Connection Binding
    function bindReverbStatus() {
        if (window.Echo && window.Echo.connector && window.Echo.connector.pusher) {
            const pusher = window.Echo.connector.pusher;
            
            const handleStateChange = (state) => {
                let status = 'unknown';
                if (state.current === 'connected') status = 'online';
                else if (state.current === 'connecting') status = 'connecting';
                else if (['disconnected', 'unavailable', 'failed'].includes(state.current)) status = 'offline';
                
                updateIndicator('dot-indicator-reverb', status);
            };

            pusher.connection.bind('state_change', handleStateChange);
            // Trigger initial state
            handleStateChange({ current: pusher.connection.state });
        } else {
            // Reverb not loaded
            updateIndicator('dot-indicator-reverb', 'offline');
        }
    }

    // 3. Telemetry Fetching Loop (30-second interval)
    async function refreshTelemetry() {
        // A. Backend Health (hitting v1 monitoring endpoint)
        try {
            const response = await fetch('/api/v1/monitoring/health');
            if (response.ok) {
                const resData = await response.json();
                systemHealth.status = resData.status || 'healthy';
                systemHealth.timestamp = resData.timestamp || new Date().toISOString();
                systemHealth.details = resData.checks || resData;

                document.getElementById('status-app-name').textContent = resData.app || 'Nexus Backend';
                document.getElementById('status-health-desc').textContent = 'All systems nominal · ' + systemHealth.timestamp;

                updateIndicator('status-backend-dot', 'online');
                updateIndicator('dot-indicator-backend', 'online');
            } else {
                throw new Error('Health check API responded with failure');
            }
        } catch (error) {
            systemHealth.status = 'unhealthy';
            document.getElementById('status-health-desc').textContent = 'Health error: ' + error.message;
            updateIndicator('status-backend-dot', 'offline');
            updateIndicator('dot-indicator-backend', 'offline');
        }

        // B. Queue Metrics
        try {
            const response = await fetch('/api/v1/tasks/stats');
            if (response.ok) {
                const resData = await response.json();
                taskStats = resData.data || null;

                if (taskStats) {
                    const pending = taskStats.pending || 0;
                    const running = taskStats.running || 0;
                    const status = (pending > 0 || running > 0) ? 'online' : 'offline';
                    updateIndicator('dot-indicator-queue', status);
                } else {
                    updateIndicator('dot-indicator-queue', 'offline');
                }
            } else {
                updateIndicator('dot-indicator-queue', 'offline');
            }
        } catch (error) {
            updateIndicator('dot-indicator-queue', 'unknown');
        }

        // C. Auth Session Check (since blade renders post-session validation)
        updateIndicator('dot-indicator-auth', 'online');

        // Update Modals if Open
        updateDetailsModalContent();
    }

    // 4. Modal Event Listeners
    function updateDetailsModalContent() {
        const detailsContainer = document.getElementById('details-modal-body');
        if (!detailsContainer) return;

        let checksHtml = '';
        if (systemHealth.details && typeof systemHealth.details === 'object') {
            checksHtml = Object.entries(systemHealth.details).map(([key, check]) => {
                const ok = check.ok || false;
                const statusColor = ok ? 'text-success' : 'text-danger';
                return `<div class="d-flex justify-content-between py-1 border-bottom border-white/5">
                    <span class="text-capitalize text-light">${key}</span>
                    <span class="${statusColor} fw-semibold">${ok ? 'ONLINE' : 'OFFLINE'}</span>
                </div>`;
            }).join('');
        }

        detailsContainer.innerHTML = `
            <div class="row g-3">
                <div class="col-6">
                    <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-secondary">
                        <div class="text-secondary text-uppercase tracking-wider mb-2" style="font-size: 9px;">Backend Health</div>
                        <div class="fs-6 fw-bold text-white text-capitalize">${systemHealth.status}</div>
                        <div class="text-secondary mt-1" style="font-size: 11px;">Timestamp: ${systemHealth.timestamp}</div>
                    </div>
                </div>
                <div class="col-6">
                    <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-secondary">
                        <div class="text-secondary text-uppercase tracking-wider mb-2" style="font-size: 9px;">Queue Metrics</div>
                        <div class="fs-6 fw-bold text-white">${taskStats ? taskStats.running : '—'} Active</div>
                        <div class="text-secondary mt-1" style="font-size: 11px;">${taskStats ? taskStats.pending : '—'} Pending / ${taskStats ? taskStats.failed : '—'} Failed</div>
                    </div>
                </div>
            </div>
            <div class="mt-3">
                <div class="text-secondary text-uppercase tracking-wider mb-2" style="font-size: 9px;">Sub-Systems Scorecard</div>
                <div class="bg-black bg-opacity-50 p-3 rounded-3 border border-secondary font-mono" style="font-size: 11px;">
                    ${checksHtml || 'No telemetry checklist data.'}
                </div>
            </div>
        `;
    }

    // 5. Logs Statistics Dynamic Retrieval
    document.getElementById('btn-open-logs').addEventListener('click', async function() {
        const body = document.getElementById('logs-modal-body');
        body.innerHTML = '<div class="text-center py-4 text-secondary"><i class="fa-solid fa-spinner fa-spin me-2"></i>Loading logs analytics...</div>';
        
        try {
            const response = await fetch('/api/v1/logs/stats');
            if (response.ok) {
                const resData = await response.json();
                const data = resData.data || {};
                
                let levelBarsHtml = '';
                if (data.by_level) {
                    levelBarsHtml = Object.entries(data.by_level).map(([level, count]) => {
                        const total = data.total || 1;
                        const percentage = ((count / total) * 100).toFixed(1);
                        let barColor = 'bg-primary';
                        if (['error', 'critical', 'alert', 'emergency'].includes(level)) barColor = 'bg-danger';
                        else if (level === 'warning') barColor = 'bg-warning';
                        else if (level === 'info') barColor = 'bg-info';
                        else if (level === 'debug') barColor = 'bg-success';

                        return `<div class="mb-2">
                            <div class="d-flex justify-content-between mb-1" style="font-size: 10px;">
                                <span class="text-capitalize text-light">${level}</span>
                                <span class="text-secondary">${count} (${percentage}%)</span>
                            </div>
                            <div class="progress bg-dark" style="height: 6px;">
                                <div class="progress-bar ${barColor}" role="progressbar" style="width: ${percentage}%"></div>
                            </div>
                        </div>`;
                    }).join('');
                }

                body.innerHTML = `
                    <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-secondary mb-3">
                        <div class="text-secondary text-uppercase tracking-wider" style="font-size: 9px;">Total Log Accumulation</div>
                        <div class="fs-4 fw-bold text-primary">${data.total || 0} Entries</div>
                    </div>
                    <div class="row g-3 mb-3">
                        <div class="col-6">
                            <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-secondary">
                                <div class="text-secondary text-uppercase tracking-wider" style="font-size: 9px;">Today's Entries</div>
                                <div class="fs-5 fw-bold text-white">${data.today || 0}</div>
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-danger border-opacity-30">
                                <div class="text-danger text-uppercase tracking-wider" style="font-size: 9px;">Critical Errors Today</div>
                                <div class="fs-5 fw-bold text-danger">${data.errors_today || 0}</div>
                            </div>
                        </div>
                    </div>
                    <div class="bg-black bg-opacity-40 p-3 rounded-3 border border-secondary mb-3">
                        <div class="text-secondary text-uppercase tracking-wider mb-2" style="font-size: 9px;">Volume By Severity Level</div>
                        ${levelBarsHtml || '<div class="text-secondary">No log levels captured.</div>'}
                    </div>
                `;
            } else {
                body.innerHTML = '<div class="text-center py-4 text-danger">Failed to fetch log statistics.</div>';
            }
        } catch (error) {
            body.innerHTML = '<div class="text-center py-4 text-danger">Connection failure loading log stats.</div>';
        }
    });

    // Start Processes
    bindReverbStatus();
    refreshTelemetry();
    setInterval(refreshTelemetry, 30000);
});
```

---

## 4. Modal Implementations (HTML Injection for `app.blade.php`)

Inject these Bootstrap 5 modals at the bottom of the body of `app.blade.php` before loading scripts:

```html
<!-- Details Modal -->
<div class="modal fade" id="nexus-details-modal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content glass border border-secondary rounded-4 shadow-lg text-light">
            <div class="modal-header border-bottom border-white/10 py-3">
                <h6 class="modal-title fw-bold text-white">System Status Details</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="details-modal-body" style="font-size: 12px;">
                <div class="text-center py-4 text-secondary"><i class="fa-solid fa-spinner fa-spin me-2"></i>Loading health metrics...</div>
            </div>
        </div>
    </div>
</div>

<!-- Logs Modal -->
<div class="modal fade" id="nexus-logs-modal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content glass border border-secondary rounded-4 shadow-lg text-light">
            <div class="modal-header border-bottom border-white/10 py-3">
                <h6 class="modal-title fw-bold text-white">System Log Analytics</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="logs-modal-body" style="font-size: 12px;">
                <div class="text-center py-4 text-secondary"><i class="fa-solid fa-spinner fa-spin me-2"></i>Loading log stats...</div>
            </div>
        </div>
    </div>
</div>
```
