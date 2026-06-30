# Scope: M1 (Phase 1 Bug Fixes)

## Architecture
- **Backend**: Laravel 11, PHP 8.2 (`Nexus-backend/`)
- **Frontend**: Next.js 14, TypeScript (`Nexus-Frontend/`)

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1.1 | Backend Fixes | Fix `clone` fatal error, delete zero-byte routes, fix `DELETE /erase`, fix `messages()` cache, fix `ContactStatsService`, add migrations | none | PLANNED |
| 1.2 | Frontend Fixes | `NxMessageViewer`, `NxRulesViewer`, `NxAiAnalysisModal`, Contact360 `activeTab`, `ContactHubTopbarControls` | none | PLANNED |
| 1.3 | Unit Tests | Phase 1 Backend/Frontend Unit Tests | 1.1, 1.2 | PLANNED |

## Interface Contracts
- Backend routes fixed: no conflicts in `api.php`.
- Migrations: `add_error_message_to_contact_analysis_runs`, `add_evidence_to_contact_analysis_findings`, `add_progress_columns_to_maintenance_runs`.
- Frontend: `apiClient` replaces `fetch()`.

## Code Layout
- Backend: `Nexus-backend/app/Http/Controllers/ContactImportController.php`, `Nexus-backend/routes/api.php`
- Frontend: `Nexus-Frontend/components/NxMessageViewer.tsx`, `Nexus-Frontend/components/NxRulesViewer.tsx`
