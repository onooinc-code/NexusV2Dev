# Backend Missing Requirements (Laravel / Python / FastAPI)

This document outlines all critical missing features, bugs, and API gaps in the backend architecture.

## 1. P0 Runtime Crashes & Blockers
- **AgentsHub MCP Pivot**: 
  - `Agent::mcpServers()` currently infers `m_c_p_server_id`, but the migration uses `mcp_server_id`. Needs explicit pivot keys defined in the relationship.
- **AgentsHub Async Job Dispatch**: 
  - `AgentExecutionService::runAsync()` dispatches `ExecuteAgentTaskJob` incorrectly. It expects an `AgentTask` but receives an agent ID, input, and trace ID.
- **TasksHub Logs Endpoint**: 
  - `TaskController::logs()` references `$request` without receiving it, and calls `$this->taskLogService` without dependency injection.
- **AiProviderHub Auth**: 
  - Placeholder replacement only supports `{KEY}` and `{API_KEY}`, failing when default format uses `{key}`.
- **Event Service Provider**: 
  - `EventServiceProvider` exists but is not registered in `bootstrap/providers.php`, causing model and domain events to fail silently.

## 2. Test & Database Infrastructure Stabilization
- The test database is not fully isolated from development data.
- Migration order causes duplicate-table/drop-table issues during `php artisan migrate:fresh`.
- Missing CI-style script or commands for automated hub smoke tests.

## 3. Hub-Specific Implementations Needed
- **TasksHub**:
  - Standardize date fields (`due_date` vs `due_at`), priorities (`0-10` or enum), and status lifecycles.
  - Replace `Route::resource('tasks')` with `Route::apiResource('tasks')` and ensure endpoints are strictly API-only.
- **AiProviderHub**:
  - Add real OpenAI and Gemini compatible adapters.
  - Build retry/backoff mechanisms for transient HTTP failures.
  - Fix the `sync-models` 500 server error.
- **AgentsHub (Real Execution)**:
  - Separate simulated execution from real execution services.
  - Implement full persistence for traces: input, output, model/provider used, tool calls, token costs, and errors.
- **WorkflowsHub**:
  - Implement the "task completion resume bridge". Workflows need to pause when a task is created and resume when the task is completed.
  - Store workflow/task correlation data.
- **SettingsHub**:
  - **Security**: Fix arbitrary API proxy SSRF risk (block private IPs, loopback, link-local, require allowlists).
  - Standardize credential encryption and key naming.
- **SchedulerHub**:
  - Compute `next_run_at` on create/update based on cron expressions and timezone.
  - Implement actual executor types: Commands, Queued Jobs, Webhooks (with SSRF protection), Agent triggers.
- **ProactiveAIHub**:
  - Build AI-assisted parsing (and multilingual/Arabic parsing) through AiModelsHub.
  - Add an approval queue for risky actions.
  - Connect actions directly to NotificationHub, ContactHub (reply rules), and WorkflowsHub.
