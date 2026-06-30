# Frontend Missing Requirements (Next.js/React)

This document outlines all the missing capabilities, UI components, and API integration gaps currently present in the NexusV2 Frontend.

## 1. Hub-Specific API Contracts & Alignments
- **TasksHub**: 
  - Update task API client to send the backend's canonical priority format (either numeric `0..10` or enum `low|medium|high|urgent`).
  - Send `due_date` correctly and ensure DatePicker formats match the backend expectations.
  - Implement real backend `update/delete` endpoints instead of relying on local-only state mutations.
  - Align UI filters with canonical statuses.
- **AiProviderHub / AIModelsHub**:
  - Show provider state clearly: `active`, `inactive`, `draft`, `failing`.
  - Display credential-required states without leaking sensitive values.
  - Show sync status and last error messages.
  - Prevent "ready" UI when provider sync or text generation is actively failing.
- **AgentsHub**:
  - Distinguish and label simulated execution vs. real execution clearly in the UI.
  - Show real-time execution state, trace logs, and detailed error messages for failed executions.
- **WorkflowsHub**:
  - Visually disable unsupported step types (e.g., Code steps if no sandbox exists).
  - Fetch and display execution progress directly from runtime logs instead of simulating progress.
  - Show "waiting-for-task" state when a workflow pauses for human/agent input.
  - Link workflow runs to newly created TasksHub tasks.
- **SettingsHub**:
  - Properly display validation errors returned from settings update API routes.
  - Hide workspace controls if the `WorkspaceHub` is not fully implemented on the backend.
- **SchedulerHub**:
  - Show `next_run`, `last_run`, run history, and failed runs with error traces.
  - Disable unsupported schedule types in the dropdowns.
- **ProactiveAIHub**:
  - Show parser confidence levels.
  - Preview rule triggers and actions before saving.
  - Display "approval-required" states for risky automated actions.
  - Render evaluation history and action run history.
- **ContactsHub**:
  - Add disabled states for planned vNext controls if the backend is not ready.
  - Avoid showing simulated AI memory or enrichment behavior; clearly label basic data vs. AI-analyzed data.

## 2. General UI/UX & Architecture Gaps
- **API Clients**: Need to create or consolidate strictly typed API clients (using Axios/Fetch) for each hub to ensure type safety between Frontend and Backend.
- **Error Handling**: Add global and local loading, empty, error, and permission-disabled states across all Hub pages.
- **Form Validation**: Add frontend validation logic (Zod/Yup) that perfectly matches backend rules to prevent unnecessary 422 API errors.
- **Responsive Design**: Ensure mobile-UI specifics are respected, particularly for complex data tables in TasksHub and SchedulerHub.
