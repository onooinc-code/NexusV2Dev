# AI Models Hub — Requirements

## Introduction

AIModelsHub is the central AI provider and model management interface for Nexus. It enables administrators to configure AI providers, manage model inventories, define intent-based routing rules, monitor provider health, track costs, and audit all AI routing executions.

## Glossary

| Term | Definition |
|------|-----------|
| Provider | An external AI service (OpenAI, Gemini, Ollama, etc.) with a configurable base URL and API key |
| Model | A specific AI model served by a provider (e.g., gpt-4o, gemini-pro) |
| Intent Routing | Mapping a system intent (e.g., "chat", "summarize") to a specific provider + model combination |
| Payload Format | The request/response shape expected by a provider (openai, anthropic, gemini, ollama, custom) |
| Health Scorecard | Aggregated latency and availability metrics per provider updated every 5 minutes |
| Cost Forecast | Monthly spend projection based on token usage and provider pricing |
| Audit Trail | A log of every AI routing execution including status, latency, and fallback usage |
| Sync Models | Fetching the live model list from a provider's models endpoint and persisting it |

---

## Requirement 1: Provider Management

**User Story:** As an administrator, I want to add, edit, and delete AI providers with full connection configuration, so that the system can route AI requests to different services.

### Acceptance Criteria

1. WHEN the user opens AIModelsHub, THE system SHALL load all configured AI providers from `/ai/providers` and display them as cards.
2. WHEN providers are loading, THE system SHALL render skeleton placeholder cards.
3. WHEN no providers are configured, THE system SHALL display an empty state with an "Add First Provider" call-to-action button.
4. THE provider card SHALL display: provider name, base URL (monospace), payload format badge, active/inactive status badge, models endpoint, generate endpoint, auth header format, latency (if tested), and count of synced models.
5. THE user SHALL be able to add a new provider via a modal form with fields: Provider Name (required), Base URL (required), Models Endpoint, Generate Endpoint, Test/Ping Endpoint, Auth Header Format, Payload Format (dropdown: openai, anthropic, gemini, ollama, custom), and API Key (password input).
6. WHEN the user edits an existing provider, THE API key field SHALL be optional and display a hint "Leave blank to keep existing key."
7. WHEN a provider is saved (add or edit), THE system SHALL call POST `/ai/providers` or PUT `/ai/providers/{id}` respectively and reflect the saved state without a full page reload.
8. WHEN the user deletes a provider, THE system SHALL display a confirmation modal warning that all associated models and API keys will be removed. Deletion SHALL call DELETE `/ai/providers/{id}`.
9. THE user SHALL be able to toggle a provider's `is_active` status via a toggle button, calling PATCH `/ai/providers/{id}/toggle-active`.
10. IF an action (save, delete, toggle) fails, THE system SHALL display an error toast message with the failure reason.
11. IF an action succeeds, THE system SHALL display a success toast message.

---

## Requirement 2: Model Sync

**User Story:** As an administrator, I want to sync the model list from a provider, so that I can see which models are available and use them for intent routing.

### Acceptance Criteria

1. EACH provider card SHALL display a "Sync Models" button that calls POST `/ai/providers/{id}/sync-models`.
2. WHILE syncing is in progress, THE button SHALL show a loading spinner and the card SHALL show a "Syncing models..." status text.
3. WHEN sync completes successfully, THE synced model chips SHALL update immediately on the card without a page reload, and the system SHALL show a success toast with the count of synced models.
4. WHEN sync fails, THE card SHALL show an error indicator and a toast with the failure message from the API.
5. WHEN a provider has synced models, THE card SHALL display model name chips (limited to 6 visible by default).
6. WHEN more than 6 models exist, THE card SHALL show a "show more / show less" toggle to expand the full model list.
7. THE last sync timestamp SHALL be visible on the card when available.

---

## Requirement 3: Provider Health Testing

**User Story:** As an administrator, I want to ping an AI provider to verify connectivity, so that I can quickly diagnose configuration issues.

### Acceptance Criteria

1. EACH provider card SHALL display a "Ping" button that calls POST `/ai/providers/{id}/test`.
2. WHILE the test is running, THE button SHALL show a spinner and the status text SHALL read "Pinging...".
3. WHEN the test succeeds, THE card SHALL show a green checkmark icon, the measured latency in milliseconds, and the status text "Connected."
4. WHEN the test fails, THE card SHALL show a red X icon and the status text "Unreachable."
5. THE header area SHALL include a "Verify All" button that triggers the ping sequence for all providers simultaneously.
6. THE test state SHALL reset to "idle" when the user navigates away or refreshes the provider list.

---

## Requirement 4: Intent Routing

**User Story:** As an administrator, I want to map system intents to specific providers and models, so that different AI tasks use the most appropriate model.

### Acceptance Criteria

1. THE Intent Routing tab SHALL load the routing matrix from GET `/ai/intents/routing`, which returns intents, providers (with their models), and current route assignments.
2. WHEN the matrix is loading, THE system SHALL display a loading spinner.
3. WHEN no intents are configured, THE system SHALL display an empty state.
4. EACH intent SHALL be displayed as a card with: intent name, provider selector dropdown, model selector dropdown (populated based on selected provider), and a "Save" button.
5. WHEN a provider is selected, THE model dropdown SHALL update to show only models belonging to that provider.
6. WHEN a route is already configured, THE card SHALL show a green "Configured" badge next to the intent name.
7. WHEN the user clicks "Save" for an intent route, THE system SHALL call PUT `/ai/intents/routing` with the intent, provider, model, and optional fallback values.
8. WHEN saving fails because no provider is selected, THE system SHALL display an error toast "Select a provider before saving."
9. IF a route is saved successfully, THE system SHALL display a success toast with the intent name.

---

## Requirement 5: Provider Health Monitoring

**User Story:** As an administrator, I want to see a live health scorecard for all AI providers, so that I can detect degraded or offline services.

### Acceptance Criteria

1. THE Health tab SHALL load the scorecard from GET `/ai/providers/health`.
2. WHEN health data is loading, THE system SHALL display a spinner with "Loading health data...".
3. WHEN the API fails, THE system SHALL display an empty state with a message explaining the scheduler must be running.
4. WHEN no data exists yet, THE system SHALL display an empty state noting that data appears after the first polling cycle (every 5 minutes).
5. EACH provider health record SHALL be displayed as a card showing: provider ID (truncated), status badge (healthy/degraded/offline with color coding), and average latency in ms.
6. THE health scorecard SHALL be updated every 5 minutes by the backend scheduler.

---

## Requirement 6: Cost Analytics

**User Story:** As an administrator, I want to track AI spending and set a monthly budget, so that I can control costs and receive warnings before limits are exceeded.

### Acceptance Criteria

1. THE Analytics tab SHALL load the cost forecast from GET `/ai/cost/forecast`.
2. WHEN the forecast is loading, THE system SHALL display a spinner.
3. THE forecast SHALL display four metric cards: Current Spend, Monthly Limit, Remaining Budget, and Forecasted Total (all in USD).
4. WHEN a monthly limit is set, THE system SHALL display a budget usage progress bar showing the percentage consumed, with color-coded states: green (≤70%), yellow (70–90%), red (>90%).
5. THE system SHALL display a banner indicating budget status: "Budget on track," "On track to exceed budget this month," or "Budget Exceeded — requests may be blocked."
6. THE user SHALL be able to set a monthly budget limit via a number input and "Save Budget" button, which calls POST `/ai/cost/budget`.
7. WHEN the budget is saved successfully, THE forecast SHALL reload and show the updated limit.

---

## Requirement 7: Audit Trail

**User Story:** As an administrator, I want to review all AI routing executions with their status, latency, and error details, so that I can debug failures and monitor system behavior.

### Acceptance Criteria

1. THE Audit Trail tab SHALL load entries from GET `/ai/audit-trail?limit=100`.
2. WHEN entries are loading, THE system SHALL display a spinner.
3. WHEN no entries exist, THE system SHALL display an empty state noting entries appear after the first routed request.
4. THE user SHALL be able to filter audit entries by: All, Success, Failed, or Fallback.
5. EACH audit entry SHALL display: intent name (or "—"), timestamp, status (color-coded: green=success, red=failed, yellow=other), latency in ms, a "FALLBACK" badge if `fallback_triggered` is true, and the error type if present.

---

## Requirement 8: Navigation & Layout

**User Story:** As an administrator, I want a clear tabbed interface to navigate between the different management areas of AIModelsHub.

### Acceptance Criteria

1. THE page SHALL render within `AppLayout` with the title "AI Model Gateway."
2. THE page SHALL provide five tabs: Providers & Models, Intent Routing, Health, Analytics, and Audit Trail.
3. WHEN the active tab is "Providers & Models," THE header SHALL show the "Verify All" and "Add Provider" action buttons.
4. THE tab navigation SHALL use a pill-style selector with the active tab highlighted in nexus-blue.
5. ALL toast notifications SHALL appear in the bottom-right corner with auto-dismiss after 4 seconds.
6. THE page SHALL support responsive layout, collapsing to a single column on mobile.
