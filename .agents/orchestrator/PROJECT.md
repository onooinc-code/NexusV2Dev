# Project: Nexus Blade & Logic Parity

## Architecture
- Two main codebases: `Nexus-backend` (Laravel 11, Blade/Bootstrap 5/jQuery UI) and `Nexus-Frontend` (Next.js reference UI).
- Real-time updates via Laravel Reverb (WebSockets) and Laravel Echo.
- Queued jobs for heavy tasks (import, maintenance, syncs, task execution).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Global Layout & Design Parity | Global Blade layout & CSS to match Next.js styling & StatusBar | none | PLANNED |
| 2 | Backend Correctness & Fixes | Pivot relations, log endpoints, due date mismatches, provider auth key replacement, event registration | none | PLANNED |
| 3 | Core Hubs Blade/API Parity | Dashboard, Agents, AIModels, Settings, Admin hubs parity | M1, M2 | PLANNED |
| 4 | Advanced Interactive Hubs | Tasks, Scheduler, HedrasSoul hubs parity & missing logic | M3 | PLANNED |
| 5 | Complex Integrations Parity | Contacts, Workflows, Waha, Logs hubs parity & real-time tracking | M4 | PLANNED |

## Interface Contracts
### Blade ↔ Backend APIs / Controllers
- AJAX requests to local Laravel endpoints (under `routes/web.php` or `routes/api.php`) return standard JSON envelopes with success/error indicators and relevant data.
- Live telemetry streams via `window.Echo` channel subscriptions.

## Code Layout
- Backend Code: `Nexus-backend/`
- Hub Views: `Nexus-backend/resources/views/hubs/`
- App Layout: `Nexus-backend/resources/views/layouts/app.blade.php`
- Custom CSS: `Nexus-backend/public/css/custom.css`
- Controllers: `Nexus-backend/app/Http/Controllers/`
- Models: `Nexus-backend/app/Models/`
- Jobs: `Nexus-backend/app/Jobs/`
