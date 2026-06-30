# Original User Request

## Initial Request — 2026-06-06T21:52:07Z

# Teamwork Project Prompt — Draft

> Status: Ready for launch — awaiting user approval
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

Complete the "contact-hub-complete" hub for the Nexus Project by eliminating missing implementations, architectural discrepancies, and logic bugs to make the system production-ready. 

Working directory: c:\Users\hedra\Desktop\Sourcecode\NexusV2
Integrity mode: development

## Requirements

### R1. Deep Analysis
Review and cross-reference the following files to ensure a complete understanding of the functional and technical scope:
- `NexusV2_Docs\01 - LastDocumentations\contact-hub-complete\design.md`
- `NexusV2_Docs\01 - LastDocumentations\contact-hub-complete\requirements.md`
- `NexusV2_Docs\01 - LastDocumentations\contact-hub-complete\tasks.md`

### R2. Implementation
Execute the technical tasks outlined in `tasks.md` across the Laravel backend and Next.js frontend codebases. Address all missing implementations, architectural discrepancies, and logic bugs.

### R3. Documentation Update
Update the `tasks.md` file to reflect progress and completed items.

### R4. Quality Assurance
Perform rigorous testing to ensure the implementation contains:
- No missing features or requirements.
- No discrepancies between the design and the actual code.
- No bugs or faulty logic.

### R5. Reporting
Provide a detailed report of all changes made, tasks completed, and verification results.

## Acceptance Criteria

### Verification & Quality
- [ ] Automated tests (if existing) pass for the modified features.
- [ ] No missing features or discrepancies between `design.md`, `requirements.md`, and the implemented code.
- [ ] `tasks.md` is accurately updated with the status of all tasks.
- [ ] A final detailed report is generated documenting changes, completed tasks, and verification results.

## Follow-up — 2026-06-21T10:06:07Z

Nexus V2 is a self-hosted, AI-powered personal digital assistant system built for a single power user. It includes a Laravel 11 monolithic backend (`Nexus-backend`) with a Blade/Bootstrap 5/jQuery frontend UI that must achieve **complete visual and functional parity** with the existing Next.js reference UI (`Nexus-Frontend`) — matching every design token, animation, hub feature, and real-time capability — while also completing missing backend logic described in the project documentation.

Working directory: `c:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-backend`
Reference UI directory: `c:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend`
Documentation directory: `c:\Users\hedra\Desktop\Sourcecode\NexusV2\NexusV2_Docs`

---

## Requirements

### R1. Global Design System Parity
The Laravel Blade layout (`resources/views/layouts/app.blade.php`) and its global CSS (`public/css/custom.css`) must implement **every visual token** from the Next.js design system:
- HSL color palette: `--bg-deep: hsl(224, 71%, 4%)`, `--nexus-blue: hsl(217, 91%, 60%)`, `--nexus-teal: hsl(174, 90%, 41%)`, etc.
- Glassmorphism panels: `backdrop-filter: blur(12px) saturate(160%)`, `border: 1px solid rgba(255,255,255,0.08)`.
- Google Fonts: Inter (UI), Outfit (display/headers), JetBrains Mono (terminal/code).
- Micro-animations: `breathing-glow`, `flash-warning`, `animate-fade-in`, hover scale transitions using `cubic-bezier(0.4,0,0.2,1)`.
- The sidebar must be styled as a dark glassmorphic navigation panel with the correct active-link indicator and hub icons (matching the Next.js `AppLayout`).
- The global StatusBar (fixed bottom) must display live system status: Agent online/offline, WAHA connection state, CPU %, Memory %, and a dynamic center task status updated via WebSocket events.

### R2. Hub-by-Hub Full UI Parity and Feature Implementation
Every hub must be re-implemented so that its **Blade template matches the Next.js page** in layout, components, interactions, and data bindings. Specifically:

**NexusHub (Dashboard)** — `hubs/dashboard.blade.php`
- Hero metrics cards (Contacts count, Active tasks, Agent executions, Memory entries) pulled from DB.
- Live system telemetry feed (scrolling log-style terminal showing recent system events from `activity_logs`).
- Central AI console chat (text input → AJAX POST → AI response rendered in chat bubble, streamed if possible).

**ContactsHub** — `hubs/contacts.blade.php`
- Full `NxContactCard3D` style: 3D CSS perspective cards with emotional baseline chip, profile confidence gauge (circular ring), reply-mode indicator (green=Autopilot, orange=Copilot, gray=Manual).
- `ContactHubTopbarControls`: Global Reply Mode segmented control (Manual / Copilot / Autopilot). Selecting Autopilot shows a flashing orange top-border warning banner: `⚠️ SYSTEM AUTOPILOT ENGAGED GLOBALLY`.
- Import Messages modal (drag-and-drop area, dry-run preview step showing total messages/duplicates, rollback history list).
- Memory Maintenance modal (checkboxes for maintenance actions, real-time progress bar wired to queue events via Echo).
- Grid / Table view toggle, paginated contact list, multi-field search/filter, Add Contact slide-in drawer.

**Contact Profile** — `hubs/contact-profile.blade.php`
- 3-column layout: Identity Details | Dynamic Tab Workspace (Overview, Conversations, Tasks, Workflows) | Intelligence panel (Emotional Baseline, ContactPersona, TalkSpecs, ReplyRules).
- Unified conversation timeline tab showing actual `contact_messages` records.
- Action buttons: Merge Contact, Export Profile, Hard Erase Profile.

**AgentsHub** — `hubs/agents.blade.php`
- Agent cards with pulse status indicator (Online=teal glow, Busy=amber, Offline=gray).
- Agent detail slide-in drawer with Temperature, MaxTokens, System Prompt, and custom Guidelines fields — saved via AJAX.
- Execute Agent action (dispatches an `AgentTask` job, shows live log terminal via Echo subscription).

**WorkflowsHub** — `hubs/workflows.blade.php`
- Visual node-based pipeline view (rendered in HTML/CSS as a connected node diagram, not necessarily a draggable canvas).
- Each node shows type icon, name, status indicator (Pending=gray, Running=teal breathing-glow animation, Success=green, Failed=red, Paused=amber blink).
- Real-time pipeline simulator: clicking "Run Workflow" dispatches a job and streams step-by-step status updates via Echo.

**TasksHub** — `hubs/tasks.blade.php`
- Kanban board: To Do, In Progress, Completed columns — each populated from `agent_tasks` table filtered by status.
- Each task card uses `nx-glass-panel` style with priority color left-border, a micro-progress bar, and action buttons (Execute, Edit, Cancel).
- "Execute Task" opens a terminal-style modal streaming live logs via `Echo.channel('task.{id}')`.
- New Task modal with all fields: Title, Description, Type (manual/agent/system), Priority, Due Date, Payload JSON editor.

**SchedulerHub** — `hubs/scheduler.blade.php`
- Scheduler cards from `workflow_schedules` table with cron expression display, next/last run timestamps, active/paused toggle.
- "Create Job" modal fully functional (POST to store a new `WorkflowSchedule`).
- Actual cron `next_run_at` computation on save using a PHP cron parser.

**MemoryHub** — `hubs/memory.blade.php`
- Three tabs: Semantic Memory (facts with confidence chip), Episodic Memory (event timeline), Working Memory (live context).
- Knowledge Synthesizer modal: inject a new memory fact via AJAX.
- Memory chips display confidence weights as color-coded badges.
- All three tabs render actual DB rows from `memory_facts`, `memory_episodes`, `memory_working` tables (or equivalent).

**HedrasSoulHub** — `hubs/hedra-soul.blade.php`
- Session list sidebar with dynamic data from `hedrasoul_sessions`.
- Full chat interface bound to `hedrasoul_messages` table (user + agent messages).
- Message composer → POST → save user message → trigger mock/real AI reply → render both.
- Session context panel showing task count, autonomy mode, session summary.

**ProactiveAIHub** — `hubs/proactive-ai.blade.php`
- ECA Rules tab: list of natural-language rules from `eca_rules` table (or static if not yet implemented) with pause/play/delete controls.
- Triggers tab: `proactive_triggers` table records with status and next-run time.
- Action Logs tab: `notification_logs` table records in a proper sortable table.
- Stats cards (Active Rules, Pending Triggers, Actions Taken, Failed Actions) computed from DB counts.

**WahaManageHub** — `hubs/waha.blade.php`
- Session status panel (WAHA API ping showing QR code if not authenticated, green status if connected).
- Sync Controls: "Sync Contacts", "Sync Messages" buttons → dispatch respective jobs → show real-time progress via Echo terminal.
- Message log feed showing recent WAHA API activity from logs.

**LogsHub** — `hubs/logs.blade.php`
- Live audit log console — auto-scrolling terminal with severity color-coding (Info=teal, Warning=amber, Error=red).
- Controls: Pause Feed, Resume Feed, Clear Screen, Raise Test Error.
- Feed is real-time via Echo `private('logs')` channel; fallback polls `/api/logs/latest` every 5 seconds.

**AIModelsHub** — `hubs/models.blade.php`
- Provider cards (OpenAI, Anthropic, Google) with endpoint, API key (masked), and enable/disable toggle.
- Ping/Test Endpoint button → AJAX → shows latency in ms.
- Performance chart area (placeholder chart.js bar chart for token usage per model).

**SettingsHub** — `hubs/settings.blade.php`
- Organized settings sections: System Config, WAHA Config, AI Provider Keys, Notification Preferences.
- All settings bound to `system_settings` table via AJAX save.
- Hard Factory Purge button (confirmation modal → clears cache and resets volatile settings).

**AdminHub** — `hubs/admin.blade.php`
- Laravel Horizon queue dashboard embed (`/horizon` iframe or native queue stats display).
- System health panel: DB connection status, Queue worker status, Redis status, Reverb status.
- User management table if multiple users exist.

### R3. Real-Time Infrastructure Integration
- All long-running actions (task execution, WAHA sync, AI analysis, memory maintenance) must:
  1. Dispatch a queued job via `php artisan queue:work`.
  2. Emit `JobProgressUpdated` events (or equivalent) at key milestones.
  3. Update the frontend via `window.Echo` subscriptions — progress bars, terminal log lines, and status badges must update in real time without page refresh.
- The global StatusBar center text must reflect the running job name and auto-clear to "Idle" when no jobs are active.

### R4. Documentation Review & Missing Backend Implementation
Review all documents in `NexusV2_Docs/` and identify missing backend implementations. At minimum:
- Fix the `AgentsHub` `McpServer` pivot relationship error identified in `HUB_IMPLEMENTATION_REVIEW_2026-05-30.md`.
- Fix the `TasksHub` log endpoint (fatal error on `/api/v1/tasks/{id}/logs`).
- Fix `due_at`/`due_date` field mismatch in `AgentTask` model and migration.
- Ensure all hub controller methods exist and return proper data to views.
- Ensure all named routes referenced in Blade views are defined in `routes/web.php`.

### R5. Production Readiness
- All pages must load without PHP parse errors or Blade syntax errors.
- All AJAX endpoints must return proper JSON with correct HTTP status codes.
- The application must start with `php artisan serve` and all hubs must be accessible and functional.
- Run `php artisan route:list` and ensure no missing route warnings.
- Run `php artisan view:cache` and ensure no Blade compilation errors.

---

## Acceptance Criteria

### Design Parity
- [ ] Global CSS variables (`--bg-deep`, `--nexus-blue`, `--nexus-teal`, etc.) are defined in `public/css/custom.css` and visually match the Next.js reference.
- [ ] All hub pages use glassmorphism card styling (`backdrop-filter: blur(12px)`, semi-transparent background).
- [ ] Google Fonts (Inter, Outfit, JetBrains Mono) are loaded and applied to the correct elements.
- [ ] Hover animations and micro-transitions are present and visible on interactive elements.
- [ ] The sidebar shows the correct active link highlight for the current page.
- [ ] The StatusBar (fixed bottom) shows at least 3 live data points and updates dynamically.

### Hub Feature Completeness
- [ ] ContactsHub: Contact cards display emotional baseline chip and profile confidence gauge.
- [ ] ContactsHub: Autopilot mode selection shows the flashing orange warning banner.
- [ ] ContactsHub: Import Messages modal is present and functional (shows form/drag-drop area).
- [ ] TasksHub: Kanban board has 3 columns populated from the database.
- [ ] TasksHub: Executing a task dispatches a job and streams logs in the terminal modal.
- [ ] WorkflowsHub: Running a workflow shows step-by-step node status updates in real time.
- [ ] AgentsHub: Agent detail drawer opens, allows editing, and saves via AJAX.
- [ ] HedrasSoulHub: Chat interface renders DB messages and allows sending new messages.
- [ ] LogsHub: Live log console auto-scrolls and shows color-coded severity levels.
- [ ] WahaHub: WAHA session status is fetched from the WAHA API and displayed accurately.
- [ ] All other hubs render without errors and show at least their primary data list from the database.

### Real-Time
- [ ] After dispatching any queued job, the StatusBar center text updates within 3 seconds.
- [ ] Terminal-style log modals (Tasks, Waha, Workflows) receive and append log lines via Echo without page reload.

### Backend Correctness
- [ ] `php artisan route:list` returns no undefined controller methods.
- [ ] `php artisan view:cache` completes without errors.
- [ ] `php artisan serve` starts without exception and all sidebar routes return HTTP 200.
- [ ] The `AgentTask` log endpoint (`GET /hub/tasks/{id}/logs` or equivalent) returns valid JSON without fatal errors.
