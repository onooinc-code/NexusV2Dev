# Nexus Project: Phase 2 Execution Roadmap

## Phase 2.1: Critical Logic Bugs & Corrupted Files Repair
**Goal:** Restore system stability and resolve fatal execution paths.
- [ ] **Contact Hub - File Restoration:** Recreate the corrupted (0-byte) `Nexus-backend/routes/ContactImportController.php` and `Nexus-backend/app/Models/ContactMessage.php`.
- [ ] **Contact Hub - Syntax Fix:** Fix the PHP fatal syntax error (`clone` keyword used on an integer return) in `Nexus-backend/app/Http/Controllers/ContactImportController.php`.
- [ ] **People Connect Hub - Webhook Routing:** Fix `Nexus-backend/app/Http/Controllers/WebhookController.php` to correctly handle `conversation_id` validation. Create and dispatch `ProcessWahaWebhookJob` instead of `ProcessAiInferenceJob`.
- [ ] **Tasks Hub - Logic Fix:** Update priority mapping in `Nexus-Frontend/store/index.ts` from exact equality (`t.priority === 10`) to the correct range-based logic.
- [ ] **Workflows Hub - State Bug:** Fix the modal `onClose` handler in `Nexus-Frontend/app/workflows/page.tsx` to properly reset the `newName` and `newTrigger` fields.

## Phase 2.2: Unblocking Phase 1 Missing Implementations
**Goal:** Complete features previously marked as missing.
- [ ] **Agents Hub:** Add `guidelines` field to `Agent` interface and `updateAgent` action in `Nexus-Frontend/store/index.ts`. Add inline editing (`<NxDrawer>`) and quarantine button in `AgentsTab.tsx`. Fix `Edit2` icon and edit form mode in `PersonasTab.tsx`.
- [ ] **Hedra Soul Hub:** Build the foundational backend logic (`app/Models`, `app/Services`, `app/Http/Controllers`) and necessary frontend components.
- [ ] **Memory Hub - DB Schema:** Create Phase 1 database migrations in `Nexus-backend/database/migrations/` (extraction fields, contact memory versions).
- [ ] **Settings Hub - Bug Fix:** Resolve the masked credential re-fetch guard issue.
- [ ] **Workflows Hub - CSS Fix:** Add the missing `.bg-grid` CSS class to `Nexus-Frontend/app/globals.css`.

## Phase 2.3: Component Extraction & De-monolithing
**Goal:** Improve code maintainability and prepare for testing.
- [ ] **AI Models Hub:** Break down the 1400-line `Nexus-Frontend/app/ai-models/page.tsx`. Create `Nexus-Frontend/app/ai-models/components/` and extract sub-components.
- [ ] **Settings Hub:** Extract shared types to `Nexus-Frontend/app/settings/types.ts`. Break down `page.tsx` (30KB monolith) by extracting `SettingControl.tsx` and `GeneralTab.tsx`.
- [ ] **Tasks Hub:** Extract `priorityFromInt` and `priorityToInt` helper functions.
- [ ] **Workflows Hub:** Extract `mapNodeType` and `mapNodeStatus` to `Nexus-Frontend/app/workflows/utils.ts`.

## Phase 2.4: Technical Debt & Phase 8 UI Integrations
**Goal:** Clean up hacky code and finalize dashboard/UI implementations.
- [ ] **Contact Hub - API Client:** Refactor `Nexus-Frontend/components/NxMessageViewer.tsx` to use `apiClient` instead of raw `fetch()`.
- [ ] **Contact Hub - Live Data:** Refactor `Nexus-Frontend/components/NxRulesViewer.tsx` to fetch live data instead of using mock `setTimeout`.
- [ ] **Memory Hub - State Migration:** Execute Phase 8 frontend migration in `Nexus-Frontend/app/memory/page.tsx` by replacing mock data via Zustand with React Query hooks.
- [x] **Hub 3: Dashboard**
  - **Objective:** Finalize real-time WebSocket orchestration and the Dashboard Hub implementation.
  - **Steps:**
    - [x] Consolidate `types.ts` to ensure strict typing across `DashboardGrid`.
    - [x] Resolve React slot injection patterns (`ActiveAgentsJobsPanel`, `SystemHealthStrip`, `MemoryHealthPanel`).
    - [x] Fix latency type handling in `SystemHealthStrip` (null guards).
    - [x] Repair memory confidence distribution typings in `MemoryHealthPanel`.

## Phase 2.5: Standardized Testing Implementation
**Goal:** Prevent regression and establish testing baseline.
- [ ] **Settings Hub Tests:** Create the `Nexus-Frontend/app/settings/__tests__` directory and write core tests.
- [ ] **Tasks Hub Tests:** Create the `Nexus-Frontend/tests/tasks` directory and write unit tests for state logic and helpers.
- [ ] **Workflows Hub Tests:** Create the `Nexus-Frontend/app/workflows/__tests__` directory and write unit/integration tests for components and utils.
