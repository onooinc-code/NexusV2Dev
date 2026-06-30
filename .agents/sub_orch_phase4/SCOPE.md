# Scope: Phase 4 - Backend Routes & Intelligence

## Architecture
- Backend: Laravel 11, PHP 8.2 (`Nexus-backend/`)
- References `NexusV2_Docs/01 - LastDocumentations/contact-hub-complete/tasks.md` Task 6

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Missing Routes | Add routes and basic analytics (6.1, 6.2) | none | PLANNED |
| 2 | Topic Mentions | Implement topic mentions and relation (6.3) | M1 | PLANNED |
| 3 | Intelligence | Refactor intelligence endpoint and extraction pipeline (6.4, 6.5) | M2 | PLANNED |
| 4 | Tests | Write tests for Phase 4 (6.6) | M3 | PLANNED |

## Interface Contracts
### `Contact Hub API`
- New routes for analytics, conflicts, stale-memory, memory-maintenance runs, and topic mentions.
- Refactored intelligence route returns structured objects: `persona`, `talkSpecs`, `emotionalBaseline`.
