# Complete Execution Plan (Zero to Production)

This is the end-to-end plan to take the current NexusV2 codebase from its broken/incomplete state to a fully functional production deployment.

## Phase 1: Repository & Environment Setup
1. **Decouple the Monolith**: Extract `Nexus-Frontend` and `Nexus-backend` into independent git repositories. Add them as git submodules to the root `NexusV2` repo.
2. **IDE Workspace**: Setup VSCode/Cursor Multi-root Workspace (`Nexus.code-workspace`) to manage both repos without Git context confusion.
3. **Environment Standardization**: Ensure `.env.local`, `.env.testing`, and `.env.staging` exist for both frontend and backend. 

## Phase 2: Backend Core Stabilization (P0)
1. **Test DB Isolation**: Fix `.env.testing` and `phpunit.xml` so tests don't corrupt the dev database.
2. **Fix Migrations**: Resolve all duplicate-table/drop-table issues so `migrate:fresh` runs flawlessly.
3. **Resolve P0 Crashes**:
   - Fix AgentsHub MCP pivot relationship.
   - Fix AgentsHub Async Job dispatch parameters.
   - Fix TasksHub logs endpoint missing injections.
   - Fix AiProviderHub auth placeholders.
   - Register the missing `EventServiceProvider`.

## Phase 3: Hub API Completions (Backend)
1. **TasksHub**: Enforce canonical priority formats, fix date fields, and ensure API-only routes.
2. **AiProviderHub**: Add actual OpenAI/Gemini adapters and retry policies.
3. **AgentsHub**: Replace simulated execution with real AI traces, persisting inputs, outputs, and token costs.
4. **WorkflowsHub**: Build the task completion resume bridge (pausing and resuming workflows natively).
5. **SettingsHub**: Implement SSRF protections and standardize encryption.
6. **SchedulerHub**: Implement actual executor types (Commands, Jobs, Webhooks).
7. **ProactiveAIHub**: Connect AI parsers and action bridges.

## Phase 4: Frontend Contract Alignment
1. **API Clients**: Generate or manually write typed Axios/Fetch clients for all hub endpoints.
2. **Remove Fakes**: Rip out all simulated/local-only update & delete logic and connect to the real backend endpoints.
3. **Error States**: Add loading, error, and validation UIs matching backend 422 responses.
4. **Disable Incomplete Features**: Visually disable UI elements for features marked "vNext" or unsupported.

## Phase 5: Testing & Quality Assurance
1. **Backend Tests**: Write/fix smoke tests for all Hubs. Ensure `php artisan test` passes 100%.
2. **Frontend Tests**: Ensure build (`npm run build`) passes without TypeScript errors.
3. **E2E Smoke Tests**: Manually or programmatically test: Agent Execution, Workflow Resumption, Task Creation, and AI Provider Sync.

## Phase 6: Staging Deployment
1. **Provision Infrastructure**: Setup VPS/Cloud servers (e.g., Laravel Forge for Backend, Vercel for Frontend).
2. **Deploy Backend**: Configure Redis, MySQL, Queues (Horizon), and WebSockets (Reverb). Run migrations.
3. **Deploy Frontend**: Point environment variables to the staging API URL. Test CORS and CSRF configurations.

## Phase 7: Production Launch
1. **Freeze Code**: No new features.
2. **Monitoring**: Setup Sentry for error tracking and New Relic (or similar) for APM.
3. **Data Migration**: If required, import initial data.
4. **Go Live**: Swap DNS to point to the production frontend. Monitor logs intensely for 48 hours.
