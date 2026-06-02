# Architecture, Details, and Integrations

## 1. WAHA API (WhatsApp HTTP API) Integration
- The current implementation relies on `waha-api.json` documentation.
- **Webhook Handlers**: Need robust webhook receivers for incoming messages and status updates to avoid direct API polling.
- **Rate Limiting & Backoff**: WAHA API endpoints must be protected with circuit breakers and queue-based rate limiters to prevent account banning or timeouts.
- **Sync Jobs**: Ensure background sync jobs for Contacts and Messages are correctly batched and utilize the 1-hour interval strategy effectively without causing memory leaks.

## 2. Database & Data Models
- **Migration Consistency**: Fix the Laravel migration order. Currently, `php artisan migrate:fresh` crashes due to foreign key constraints or duplicate tables.
- **NexusConnect Schema**: Formalize the database schema for the NexusConnect hub (as documented in `NexusConnectHub.md`) to handle cross-platform messaging natively.
- **Event Logging**: Ensure `task_logs`, `agent_traces`, and `workflow_runs` tables are optimized for high-volume writes and indexed by `trace_id` and `created_at`.

## 3. Documentation Gaps
- **API Documentation**: Swagger/OpenAPI spec must be kept in sync with the actual Laravel API routes. Route names and payload fields must match exactly.
- **Troubleshooting Guides**: Add documentation for debugging Queues, Laravel Reverb (WebSockets), Horizon, Redis, MySQL, and Pinecone.
- **Future Features**: Clearly mark unsupported or upcoming features in the docs to avoid confusing the AI or developers.

## 4. Security & Compliance
- **SSRF Mitigation**: Crucial fix needed in SettingsHub and SchedulerHub webhooks to prevent Server-Side Request Forgery.
- **Authentication**: Finalize CSRF/Session configurations between Next.js and Laravel (Sanctum) to eliminate 419 Authentication Timeout errors permanently.
