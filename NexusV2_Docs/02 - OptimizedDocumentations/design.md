# Nexus Project: Phase 2 System Design

## 1. Architectural Flaws & Refactoring Strategy

### 1.1 Breaking Down Monolithic Structures
The Phase 1 audit revealed severe monolithic structures that must be decoupled to ensure maintainability and scalability.

**AI Models Hub:**
- **Current State:** `Nexus-Frontend/app/ai-models/page.tsx` is a 1400-line monolithic file.
- **Refactoring Plan:** Extract UI components into `Nexus-Frontend/app/ai-models/components/`. Create distinct components for Model List, Configuration Panel, Metrics Viewer, and Model Settings. Move state management to custom hooks or Zustand store.

**Settings Hub:**
- **Current State:** `Nexus-Frontend/app/settings/page.tsx` is a 30KB monolith.
- **Refactoring Plan:** Extract components such as `SettingControl.tsx` and `GeneralTab.tsx`. Move shared type definitions to `Nexus-Frontend/app/settings/types.ts`.

### 1.2 Dashboard Architecture
- **Current State:** Missing production components and API integration. Relying on prototype components.
- **Refactoring Plan:** Implement `DashboardGrid` layout component. Create specialized sub-panels (`AgentStatusPanel`, `MemoryMetricsPanel`, etc.) in `Nexus-Frontend/components/dashboard/`.

## 2. Standard Testing Infrastructure

### 2.1 Frontend Testing
- **Framework:** Jest + React Testing Library (RTL).
- **Structure:** Co-locate tests in `__tests__` directories within each hub (e.g., `Nexus-Frontend/app/settings/__tests__`, `Nexus-Frontend/app/workflows/__tests__`, `Nexus-Frontend/tests/tasks`).
- **Standards:** Test component rendering, user interactions, state changes, and ensure hooks/utils are unit tested (e.g., `priorityFromInt`, `mapNodeType`).

### 2.2 Backend Testing
- **Framework:** PHPUnit / Pest.
- **Structure:** `tests/Feature` for API endpoints and integration tests, `tests/Unit` for business logic and isolated services.
- **Standards:** Implement tests for complex logic (e.g., webhook routing, data ingestion, logic priority mappings).

## 3. Cross-Hub Integration Interfaces

### 3.1 Gap A: Webhook Payload Routing (People Connect ↔ AI Models/Tasks)
- **Problem:** Improper routing of webhooks, validation errors, and incorrect job dispatches.
- **Design Interface:**
  - Standardize incoming webhook payload structure.
  - Create a robust `WebhookRouter` service.
  - Implement the `ProcessWahaWebhookJob` with clearly defined events that the AI Models and Tasks Hubs can subscribe to or be directly invoked with.
  - Ensure `conversation_id` resolution occurs gracefully before dispatching dependent processes.

### 3.2 Gap B: Dashboard Data Integration (Agents & Memory ↔ Dashboard)
- **Problem:** Dashboard lacks consolidated data from Agents and Memory hubs.
- **Design Interface:**
  - Create standard aggregation API endpoints under `/api/v1/dashboard/`.
  - The API will query the Agents domain for status/health and the Memory domain for ingestion/retrieval metrics.
  - Frontend will consume this unified data using React Query hooks in the new `DashboardGrid` components, fully deprecating mock data.

### 3.3 Gap C: Contact Hub Data Ingestion flows
- **Problem:** Corrupted files, fatal syntax errors, and missing standardized API usage for data ingestion.
- **Design Interface:**
  - Re-architect the `ContactImportController` to safely handle bulk imports without memory or syntax faults.
  - Define a strict `ContactMessage` schema for robust data validation.
  - Ensure frontend tools (like `NxMessageViewer` and `NxRulesViewer`) ingest data using the standardized `apiClient` instead of manual `fetch()` or mock `setTimeout()` functions.
