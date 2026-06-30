# Nexus Project: Phase 2 Unified Requirements

## 1. Overview
This document outlines the unified functional requirements for Phase 2 of the Nexus Project, derived from the Phase 1 Audit Report. The priority is resolving critical logic bugs, addressing technical debt, and implementing missing Phase 1 and Phase 8 objectives across the 10 functional hubs.

## 2. Bug Fixes & Logic Corrections (Critical Priority)
- **Contact Hub:** 
  - Resolve the PHP fatal syntax error (`clone` keyword on integer return) in `ContactImportController.php`.
  - Restore the corrupted 0-byte files: `routes/ContactImportController.php` and `ContactMessage.php`.
- **People Connect Hub:** 
  - Fix the `WebhookController.php` entry point to properly handle webhook routing, correctly process `conversation_id` validation, and dispatch the correct `ProcessWahaWebhookJob` instead of the incorrect `ProcessAiInferenceJob`.
- **Tasks Hub:** 
  - Update the priority mapping logic in `Nexus-Frontend/store/index.ts`. Replace the incorrect exact equality ternary (`t.priority === 10`) with range-based logic.
- **Workflows Hub:** 
  - Fix the modal `onClose` handler in `Nexus-Frontend/app/workflows/page.tsx` to properly reset the `newName` and `newTrigger` form fields when the modal is closed.

## 3. Technical Debt Resolution
- **Contact Hub:** 
  - Refactor `NxMessageViewer.tsx` to use the standard `apiClient` instead of raw `fetch()`.
  - Refactor `NxRulesViewer.tsx` to fetch live data instead of using mock `setTimeout`.
- **Settings Hub:** 
  - Fix the masked credential re-fetch guard.

## 4. Missing Phase 1 & Phase 8 Implementations
- **Agents Hub:**
  - Add the `guidelines` field to the `Agent` interface in `store/index.ts`.
  - Implement the `updateAgent` action in `store/index.ts`.
  - Add inline editing (`<NxDrawer>`) and the quarantine action button to `AgentsTab.tsx`.
  - Fix `PersonasTab.tsx` to correctly render the `Edit2` icon and implement the edit form mode.
- **AI Models Hub:**
  - Execute Phase 1 refactoring to break down the monolithic 1400-line `page.tsx` into extracted components inside the `components/` directory.
- **Hedra Soul Hub:**
  - Implement the missing backend logic (`app/Models`, `app/Services`, `app/Http/Controllers`).
  - Develop the required frontend components.
- **Nexus Dashboard:**
  - Implement the required API routes (`/api/v1/dashboard/*`) in `api.php`.
  - Create the `components/dashboard` directory and implement the production `DashboardGrid` and sub-panels, replacing old prototype components in `page.tsx`.
- **Memory Hub:**
  - Create the missing Phase 1 database migrations (schema updates for extraction fields, contact memory versions).
  - Execute Phase 8 frontend migration: replace mock data via Zustand in `page.tsx` with React Query hooks.
- **Settings Hub:**
  - Extract shared types to `types.ts`.
  - Break down the 30KB monolith `page.tsx` by extracting components like `SettingControl.tsx` and `GeneralTab.tsx`.
- **Tasks Hub:**
  - Extract the `priorityFromInt` and `priorityToInt` helper functions.
- **Workflows Hub:**
  - Extract `mapNodeType` and `mapNodeStatus` to `utils.ts`.
  - Add the missing `.bg-grid` CSS class to `globals.css`.

## 5. Testing Infrastructure Requirements
- Establish a standardized frontend and backend testing infrastructure.
- Implement missing test suites for **Settings Hub**, **Tasks Hub**, and **Workflows Hub**.
