# ContactHub Complete Implementation

## Audit Report

This section documents the current state of the ContactHub implementation across both
Nexus-Frontend (Next.js/TypeScript) and Nexus-backend (Laravel/PHP), identifying all gaps,
discrepancies, and defects that must be resolved before ContactHub can be considered complete.

---

## 🛑 Missing Implementations

### Backend — Missing Implementations

**B-M-01** No `ContactReplyRuleController` exists. Reply rule operations are handled inline
inside `ContactController` rather than as a dedicated, testable controller class. Full CRUD
for reply rules (`POST`, `PATCH`, `DELETE` per rule) is not properly structured.

**B-M-02** No `ContactTopicController` exists. The topics endpoints (`GET /contacts/{id}/topics`)
are present as a single read method in `ContactController` but there is no dedicated controller
exposing full topic CRUD or topic-mention evidence retrieval.

**B-M-03** `GET /api/v1/contacts/analytics` (batch/hub-level analytics endpoint) does not exist.
Only per-contact analytics (`GET /contacts/{id}/analytics`) is implemented.

**B-M-04** `GET /api/v1/contacts/conflicts` route does not exist. There is no endpoint
exposing contacts with active identity conflicts, which is required for the topbar stats strip.

**B-M-05** `GET /api/v1/contacts/stale-memory` route does not exist. There is no endpoint
for listing contacts with stale memory, required for memory maintenance scoping.


**B-M-06** Six Laravel events required by the spec are not defined:
`ContactImportStarted`, `ContactMemoryMaintenanceStarted`, `ContactMemoryMaintenanceCompleted`,
`ContactReplyModeChanged`, `ContactMessageImported`, `ContactIdentityConflictDetected`.

**B-M-07** `EventServiceProvider` does not register ContactHub events to their listeners.
`ContactImportCompleted`, `ContactAnalysisCompleted`, and related events are defined but not
mapped to any listener in `EventServiceProvider`, so no downstream reactions fire.

**B-M-08** No rate limiting is applied to analysis-run creation endpoints. A single client
can flood the queue with unlimited analysis requests.

**B-M-09** No `ContactImportPreviewService` or `ContactImportRollbackService` exists as
standalone services. Preview and rollback logic is embedded inline inside the pipeline, making
it untestable independently and preventing reuse.

**B-M-10** Four queue jobs required for asynchronous import processing do not exist:
`ImportContactMessagesJob`, `NormalizeContactImportBatchJob`,
`ResolveContactImportIdentitiesJob`, `RollbackContactImportBatchJob`. The current import
pipeline processes synchronously, which will time out on large files.

**B-M-11** `ExportContactDataJob` and `EraseContactDataJob` do not exist. Privacy operations
run synchronously in the request cycle, which is unsafe for large data sets and violates the
spec's requirement that all privacy operations be queued and verifiable.


**B-M-12** Five standalone jobs for memory maintenance operations do not exist as separate,
dispatchable classes: `RecomputeContactEmbeddingsJob`, `RecalculateContactBaselineJob`,
`DetectContactMemoryConflictsJob`, `PruneContactMemoryJob`, `RebuildContactMemoryJob`.

**B-M-13** No authorization `Policy` exists for ContactHub routes. `ContactController` and
all supporting controllers lack granular `authorize()` calls, meaning any authenticated user
can perform any ContactHub operation regardless of role.

**B-M-14** No file size limit validation exists on any import endpoint. Uploading arbitrarily
large files can exhaust memory or disk space.

**B-M-15** `GET /api/v1/contacts/{contact}/memory-maintenance/runs` (per-contact maintenance
run history) route does not exist. Only global maintenance run routes are present.

**B-M-16** Global memory maintenance scope is explicitly disabled in
`ContactMemoryMaintenancePipeline::process()` with the comment
"Global maintenance runs are currently disabled." The spec requires global scope to work.

**B-M-17** No `ContactAnalysisFindingController` exists for applying or rolling back
individual analysis findings. The methods `apply` and `rollback` on analysis runs exist as
stubs in `ContactController` but contain no real implementation logic.

**B-M-18** Two misplaced zero-byte files exist in the `routes/` directory:
`routes/ContactImportController.php` and `routes/ContactMessage.php`. These are not route
files and serve no purpose in that location.


### Frontend — Missing Implementations

**F-M-01** No dedicated WhatsApp tab exists in Contact360. The spec requires a separate
WhatsApp-specific message view with its own import action, search, date range filter, sender
filter, and attachment filter. Currently only a unified Messages tab is present.

**F-M-02** No dedicated Facebook tab exists in Contact360. The spec requires a Facebook-specific
message view with a thread selector, date range filter, and import action.

**F-M-03** No Conversations tab exists in Contact360. The spec requires a unified cross-channel
timeline with group-by controls (thread, channel, topic, date), AI-generated summaries,
extracted decisions, promises, and open loops.

**F-M-04** No Memories tab exists in Contact360. There is no UI to view, version-diff, or
manage `contact_memories` records from the frontend.

**F-M-05** No Intelligence panel or tab exists in Contact360 to display `ContactPersona`,
`ContactTalkSpecs`, and `emotional_baseline` as structured, evidence-backed sections.

**F-M-06** No global Memory Maintenance modal is wired from `ContactHubTopbarControls`.
The "Maintain" button falls back to a toast notification instead of opening a hub-scope modal.

**F-M-07** `NxContactCard3D` quick actions are incomplete. The spec requires: Start AI Analysis,
Import Messages, View Conversations, Edit Reply Mode, Merge, and Archive. These actions are
absent from the card.

**F-M-08** The contacts list page import entry point is an inline drawer, not the rich
`NxImportModal` component (which has the source selector, file upload, preview step,
contact-matching step, progress tracking, and rollback).

**F-M-09** No analysis run findings review UI exists. After an analysis run completes,
there is no UI for a user to review extracted findings and choose to apply, ignore, or
roll back each finding individually.


**F-M-10** No `ContactTopicMention` evidence viewer exists in the Topics tab. The spec requires
source message citations to be visible for each extracted topic.

**F-M-11** No relationship graph visualization exists. The spec requires a graph view showing
contact-to-contact relationships, not only a flat list.

**F-M-12** No queue/job progress drawer is implemented on the ContactHub main page. The spec
requires a visible progress indicator showing active import, analysis, and maintenance jobs.

---

## ⚠️ Discrepancies & Incorrect Implementations

### Backend — Discrepancies

**B-D-01** `ContactImportController::importMessages()` uses `clone $result['batch']->messages()->count()`.
PHP's `clone` keyword operates on objects, not integers. Calling `messages()->count()` returns
an integer, so `clone` will throw a fatal error. This is a critical syntax violation.

**B-D-02** `ContactController::messages()` builds cache keys from all request query parameters
without a length or parameter whitelist. Cache keys can grow unbounded if callers pass arbitrary
query strings. Additionally, there is no cache invalidation when a new import batch is committed
for that contact.

**B-D-03** The spec defines `ContactPersona` and `ContactTalkSpecs` as separate structured
model entities with evidence, confidence, and version history. The current `persona()` and
`talkSpecs()` endpoints simply return unstructured JSON from the contact's `metadata` field
with no schema, no confidence, and no evidence references.

**B-D-04** `ContactController::emotional-baseline` returns `contact.metadata.emotional_baseline`
directly from the metadata field. The spec requires this value to be computed from
`contact_analysis_findings` over time, not read from a freeform metadata JSON blob.


**B-D-05** `contact_analysis_findings` records are missing `evidence_references` and
`source_message_ids` fields. `ContactIntelligenceExtractionPipeline` does not populate
evidence or source citations when writing findings, violating the spec's evidence-backed
intelligence requirement.

**B-D-06** The `ContactAnalysisRun` model references an `error_message` column, but this
column may not exist in the `contact_analysis_runs` migration. The service attempts to update
`error_message` on failure, which will silently fail or throw a database error.

**B-D-07** `ContactStatsService` counts `failed_imports` and `failed_analysis_runs` in the
stats response, but the counting logic may not accurately reflect failed job states stored in
the database versus failed Laravel queue job records.

**B-D-08** The erase operation has both `DELETE /contacts/{id}/erase` and
`POST /contacts/{id}/erase` routes pointing to the same `erase()` method. The spec defines
erase as a `POST` with a privacy workflow. The `DELETE` variant conflicts with standard
resource semantics and with `Route::apiResource`'s own `DELETE /contacts/{id}` route.

**B-D-09** `ContactIntelligenceExtractionPipeline` uses hardcoded fallback mock data when
AI services are unavailable. This mock data is silently written to the database as if it were
real AI output, with no indicator that the findings are fabricated. This must be clearly flagged
or the fallback must be replaced with a proper error state.

### Frontend — Discrepancies

**F-D-01** `NxAiAnalysisModal` has `suggest_rules: true` in its `options` state but renders
no corresponding checkbox label in the UI. The "Suggest Rules" option is silently sent to the
backend in every request without user consent or awareness.

**F-D-02** `ContactHubTopbarControls` accesses `contactsResp.data?.data?.data` (triple `.data`)
when fetching contact IDs for batch analysis. This depends on a fragile, triple-nested response
shape and will silently return `undefined` if the API shape changes even slightly.


---

## 🐛 Bugs & Faulty Logic

### Backend — Bugs

**B-BUG-01 [CRITICAL]** `ContactImportController::importMessages()` — the expression
`clone $result['batch']->messages()->count()` applies PHP's `clone` operator to the integer
result of `->count()`. This causes a PHP fatal error on every WhatsApp and Facebook import
commit. All message imports are currently broken.

**B-BUG-02** `ContactMemoryMaintenancePipeline::process()` throws a runtime exception
("Global maintenance runs are currently disabled") whenever the `contact_id` scope is absent.
Since the Memory Maintenance modal supports a hub-wide scope selector, any attempt to run a
global maintenance operation will fail with an uncaught exception.

**B-BUG-03** `ContactController::exportBundle` references `$contact->analysisFindings` and
`$contact->auditEvents` as relationship accessors. If the actual Eloquent relationship names
on the `Contact` model differ (e.g., `analysis_findings` vs `analysisFindings`), these
accessors will return `null` silently, producing an incomplete export bundle without error.

**B-BUG-04** Both `Route::delete('/contacts/{id}/erase', ...)` and
`Route::post('/contacts/{id}/erase', ...)` are registered. Laravel's `Route::apiResource`
also registers `DELETE /contacts/{id}` pointing to `destroy()`. This creates a routing
conflict where a `DELETE` to `/contacts/{id}/erase` is ambiguous between the erase route
and the resource destroy route, depending on route registration order.

**B-BUG-05** The two files `routes/ContactImportController.php` and `routes/ContactMessage.php`
are empty (zero bytes) and are located inside the `routes/` directory. PHP will attempt to
autoload or include these as route definitions, potentially causing parse errors or silent
failures if the routes bootstrap process loads all files in the `routes/` directory.

### Frontend — Bugs

**F-BUG-01 [CRITICAL]** `NxMessageViewer.tsx` uses a raw `fetch()` call with a hardcoded
`http://localhost:8000` base URL and does not attach any authentication headers. This will
fail in every environment other than the developer's local machine. No Bearer token is sent,
so the backend returns 401 on protected endpoints. All message loading is broken outside
local development.


**F-BUG-02** `NxRulesViewer.tsx` loads rules from a hardcoded `setTimeout` with mock data
instead of calling `GET /api/v1/contacts/{id}/reply-rules`. Rules added or removed in the UI
are stored only in local React state and are never persisted to the backend. Every page reload
loses all user-managed rules.

**F-BUG-03** `NxRulesViewer.tsx` contains `setIsLoading(true)` inside a `useEffect` with
an ESLint disable comment `// eslint-disable-next-line react-hooks/set-state-in-effect`,
indicating the component was known to have a React hooks compliance issue at the time of
writing. Setting state unconditionally on every effect render causes unnecessary re-renders
and the lint suppression hides the underlying design issue.

**F-BUG-04** The Contact360 page `[id]/page.tsx` defines `activeTab` to include `'topics'`
and `'audit'` as valid values, but the `useEffect` switch that loads data per tab has no
`case 'topics'` and no `case 'audit'`. When a user switches to either of these tabs, no
data-loading function is invoked from the central switch — data loading is delegated entirely
to the child components, which is inconsistent with how every other tab works and makes
the tab-switching behavior non-uniform.

**F-BUG-05** `NxAiAnalysisModal.tsx` renders only three checkboxes (`extract_topics`,
`infer_persona`, `detect_emotion`) in its UI but sends four options to the backend
(`suggest_rules: true` is always included). The "Suggest Rules" option is silently enabled
on every analysis run with no user visibility or control.

---

## Requirements Document


## Introduction

ContactHub Complete covers all work required to bring the Nexus ContactHub from its current
~35% completion state to a fully production-ready feature. The work spans both the
Nexus-backend (Laravel 11 / PHP) and Nexus-Frontend (Next.js 14 / TypeScript) codebases.

The scope includes: fixing all critical bugs, completing the asynchronous import pipeline,
building the full message and conversation views inside Contact360, implementing AI analysis
with evidence-backed findings and a review UI, enabling global and per-contact memory
maintenance as queued operations, wiring all hub integration events and listeners, and
hardening both codebases for production use with authorization policies, rate limiting,
proper error states, and complete test coverage.

## Glossary

- **ContactHub**: The Nexus module that owns contact profiles, identity, message history,
  AI intelligence, reply rules, memory, and privacy operations.
- **Contact360**: The contact detail page showing all tabs and intelligence for one contact.
- **ContactImportBatch**: A database record representing a single import operation (file or
  sync). All imported messages link back to their batch for rollback support.
- **ContactAnalysisRun**: A database record representing one execution of the AI intelligence
  pipeline for a contact.
- **ContactAnalysisFinding**: A single AI-extracted fact or suggestion produced by an analysis
  run, including evidence references and a confidence score.
- **ContactMemory**: A versioned, structured knowledge record about a contact derived from
  messages, notes, or AI analysis.
- **ContactMemoryMaintenanceRun**: A database record representing one execution of a
  maintenance pipeline (rebuild, prune, deduplicate, re-embed, erase, export).
- **ContactPersona**: A structured AI-assisted profile describing a contact's stable
  communication traits, interests, and relationship context.
- **ContactTalkSpecs**: Operational reply guidance per contact including language, formality,
  message length, emoji tolerance, and topics to avoid.
- **EmotionalBaseline**: A longitudinal estimate of a contact's usual emotional range computed
  from message sentiment over time.
- **ReplyMode**: One of `manual`, `copilot`, or `autopilot` — controls how autonomously Nexus
  may respond to a contact.
- **apiClient**: The centralized Axios-based HTTP client at `@/lib/api/client` used by all
  frontend components for authenticated API calls.
- **ImportPipeline**: The backend service chain that parses, normalizes, deduplicates, and
  persists messages from a WhatsApp or Facebook export file.
- **AgentsHub**: The Nexus hub responsible for AI model execution and agent tracing. ContactHub
  must not call AI providers directly; it delegates to AgentsHub.


## Requirements

---

### Requirement 1: Fix Critical Frontend API Client Bugs

**User Story:** As a developer, I want all frontend components to use the centralized apiClient
for backend calls, so that authentication tokens are sent correctly and the app works in every
environment.

#### Acceptance Criteria

1. WHEN `NxMessageViewer` fetches messages, THE `MessageViewer` SHALL use `apiClient` from
   `@/lib/api/client` instead of raw `fetch()`, and SHALL NOT contain any hardcoded hostnames
   or ports.
2. WHEN `NxMessageViewer` sends a request, THE `MessageViewer` SHALL rely on `apiClient`'s
   configured base URL and authentication interceptors so that a valid Bearer token is
   included in every request.
3. WHEN the `NxRulesViewer` component mounts, THE `RulesViewer` SHALL call
   `GET /api/v1/contacts/{contactId}/reply-rules` via `apiClient` to load rules from the
   backend, replacing the current `setTimeout` mock.
4. WHEN a user adds a rule in `NxRulesViewer`, THE `RulesViewer` SHALL call
   `POST /api/v1/contacts/{contactId}/reply-rules` and persist the new rule to the backend
   before updating local state.
5. WHEN a user removes a rule in `NxRulesViewer`, THE `RulesViewer` SHALL call
   `DELETE /api/v1/contacts/{contactId}/reply-rules/{ruleId}` and remove it from the backend
   before removing it from local state.
6. IF a rules API call fails, THEN THE `RulesViewer` SHALL display an inline error message
   and SHALL NOT lose the previously loaded rules from the UI.

---

### Requirement 2: Fix Backend PHP Fatal Errors

**User Story:** As a user, I want WhatsApp and Facebook message imports to complete without
server errors, so that I can reliably import my conversation history.

#### Acceptance Criteria

1. WHEN `ContactImportController::importMessages()` commits an import batch, THE
   `ImportController` SHALL NOT apply the PHP `clone` keyword to the integer result of
   `->count()`, and SHALL compile and execute without a PHP fatal error.
2. WHEN a message count is needed after batch commit, THE `ImportController` SHALL read
   the count via a valid Eloquent call such as `$batch->messages()->count()` without cloning.
3. WHEN the zero-byte files `routes/ContactImportController.php` and `routes/ContactMessage.php`
   are present in the routes directory, THE `System` SHALL have these files deleted so that the
   Laravel routes bootstrap does not attempt to parse them.
4. WHEN both `DELETE /contacts/{id}/erase` and `POST /contacts/{id}/erase` routes are
   registered alongside `Route::apiResource`, THE `Router` SHALL resolve requests
   unambiguously with no route conflict, and the erase operation SHALL only be accessible via
   `POST /contacts/{id}/erase`.


---

### Requirement 3: Fix AI Analysis Modal Option Visibility

**User Story:** As a user, I want to see and control every analysis option before running AI
analysis, so that I am not unknowingly triggering operations I did not choose.

#### Acceptance Criteria

1. THE `NxAiAnalysisModal` SHALL render a visible, labelled checkbox for every option included
   in the `options` object sent to `POST /contacts/{id}/analysis-runs`, including `suggest_rules`.
2. WHEN a user opens the AI Analysis modal, THE `NxAiAnalysisModal` SHALL display at minimum
   four labelled checkboxes: Extract Topics, Infer Persona, Detect Emotion, and Suggest Rules.
3. WHEN a user unchecks `suggest_rules`, THE `NxAiAnalysisModal` SHALL send `suggest_rules: false`
   in the request payload, not `suggest_rules: true`.
4. WHEN a user opens the AI Analysis modal, THE `NxAiAnalysisModal` SHALL include a model or
   agent selector that allows the user to choose which AgentsHub agent or AI provider to use
   for the run.

---

### Requirement 4: Fix Contact Detail Tab Data Loading

**User Story:** As a user, I want every tab in the Contact360 detail page to load its data
correctly when I switch to it, so that I never see stale or empty content due to a missing
data-load trigger.

#### Acceptance Criteria

1. WHEN a user activates the `topics` tab in Contact360, THE `ContactDetailPage` SHALL invoke
   the appropriate data-loading function for topics within its `activeTab` effect.
2. WHEN a user activates the `audit` tab in Contact360, THE `ContactDetailPage` SHALL invoke
   the appropriate data-loading function for audit events within its `activeTab` effect.
3. THE `ContactDetailPage` tab-switching `useEffect` SHALL handle all valid `activeTab` values
   including `messages`, `rules`, `topics`, and `audit` without relying on incomplete switch
   fallthrough.

---

### Requirement 5: Fix Analysis Findings Mock Data and Evidence Storage

**User Story:** As a user, I want AI-generated findings to reflect real analysis output with
source evidence, so that I can trust and audit each extracted fact.

#### Acceptance Criteria

1. WHEN `ContactIntelligenceExtractionPipeline` writes analysis findings, THE `Pipeline` SHALL
   populate `evidence_references` and `source_message_ids` fields on each `ContactAnalysisFinding`
   record with references to the actual messages or inputs used.
2. IF the AI service is unavailable, THEN THE `Pipeline` SHALL record the analysis run as
   `failed` with an error message and SHALL NOT write any mock or fabricated findings to the
   `contact_analysis_findings` table.
3. THE `contact_analysis_runs` migration SHALL include an `error_message` column of type `text`
   (nullable) so that the service can record failure reasons without a database error.
4. WHEN `ContactController::exportBundle` loads relationship data, THE `ExportController`
   SHALL use the verified Eloquent relationship names from the `Contact` model (e.g.,
   `analysisFindings()`, `auditEvents()`) and SHALL produce a complete, valid export bundle.


---

### Requirement 6: Asynchronous Message Import Pipeline

**User Story:** As a user, I want to import WhatsApp and Facebook message history with a
preview step, progress tracking, and the ability to roll back, so that I can safely bring
in large conversation archives without risk.

#### Acceptance Criteria

1. WHEN a user submits a WhatsApp JSON or TXT export file to `POST /api/v1/contacts/import/whatsapp`,
   THE `ImportPipeline` SHALL dispatch `ImportContactMessagesJob` to the queue and return a
   batch ID immediately, without processing synchronously in the HTTP request.
2. WHEN a user submits a Facebook JSON export to `POST /api/v1/contacts/import/facebook`,
   THE `ImportPipeline` SHALL dispatch `ImportContactMessagesJob` to the queue and return a
   batch ID immediately.
3. WHEN `POST /api/v1/contacts/import/preview` is called, THE `ImportPreviewService` SHALL
   parse the file in memory, return a preview of detected messages, participants, and potential
   contact matches, and SHALL NOT persist any data.
4. WHEN an import job processes messages, THE `NormalizeContactImportBatchJob` SHALL deduplicate
   messages using source ID and content hash, so that re-importing the same file does not
   create duplicate message records.
5. WHEN `POST /api/v1/contacts/imports/{batch}/rollback` is called, THE `RollbackService`
   SHALL dispatch `RollbackContactImportBatchJob` which deletes all messages belonging to the
   specified batch and sets the batch status to `rolled_back`.
6. WHEN an import file exceeds 50 MB, THE `ImportController` SHALL return HTTP 422 with a
   descriptive error message and SHALL NOT accept the upload.
7. WHEN an import job encounters a parse error on a message row, THE `ImportJob` SHALL record
   the row number and error reason in the batch's `error_report` field and SHALL continue
   processing remaining messages.
8. THE `ContactImportPreviewService` SHALL be a standalone injectable service class with its
   own unit tests, separate from the full `ContactImportPipeline`.
9. THE `ContactImportRollbackService` SHALL be a standalone injectable service class with its
   own unit tests, separate from the full `ContactImportPipeline`.

---

### Requirement 7: Message Views and Conversations Tab

**User Story:** As a user, I want to browse imported messages per channel and in a unified
timeline inside the Contact360 profile, so that I can review conversation history without
leaving the contact page.

#### Acceptance Criteria

1. THE Contact360 profile SHALL include a WhatsApp tab that displays messages filtered to
   `channel = 'whatsapp'` via `GET /api/v1/contacts/{contact}/messages/whatsapp`.
2. THE Contact360 profile SHALL include a Facebook tab that displays messages filtered to
   `channel = 'facebook_messenger'` via `GET /api/v1/contacts/{contact}/messages/facebook`.
3. THE Contact360 profile SHALL include a Conversations tab that displays a unified
   cross-channel timeline with controls to group messages by thread, channel, topic, or date.
4. WHEN a user searches messages in any message tab, THE `MessageViewer` SHALL filter results
   by the search query using `GET /api/v1/contacts/{contact}/messages?search={query}`.
5. WHEN a user applies a date range filter, THE `MessageViewer` SHALL pass `date_from` and
   `date_to` parameters to the messages endpoint.
6. THE `GET /api/v1/contacts/{contact}/messages` backend route SHALL support `search`,
   `channel`, `date_from`, `date_to`, `sender`, `direction`, and `has_attachment` filter
   parameters with cursor-based pagination.
7. WHEN a message list contains more than 50 messages, THE `MessageViewer` SHALL implement
   pagination or infinite scroll rather than loading all messages at once.


---

### Requirement 8: AI Analysis with Evidence-Backed Findings and Review UI

**User Story:** As a user, I want to run AI analysis on a contact's messages through AgentsHub
and then review, apply, or dismiss each extracted finding before it affects the contact profile,
so that I remain in control of AI-generated data.

#### Acceptance Criteria

1. WHEN `POST /api/v1/contacts/{contact}/analysis-runs` is called, THE `AnalysisController`
   SHALL dispatch `AnalyzeContactMessagesJob` to the queue and return the new run record with
   `status = 'queued'`.
2. WHEN an analysis job executes, THE `ContactIntelligenceExtractionPipeline` SHALL call
   AgentsHub / AiModelsHub for AI execution and SHALL NOT call any AI provider SDK directly.
3. WHEN an analysis run completes, THE `Pipeline` SHALL write `ContactAnalysisFinding` records
   each containing `fact_type`, `value`, `confidence`, `evidence_references`, and
   `source_message_ids`.
4. WHEN a user calls `POST /api/v1/contacts/analysis-runs/{run}/apply`, THE `AnalysisController`
   SHALL apply the run's findings to the contact profile — updating memories, persona, talk-specs,
   topics, and reply rules as appropriate — and SHALL set `status = 'applied'` on the run.
5. WHEN a user calls `POST /api/v1/contacts/analysis-runs/{run}/rollback`, THE `AnalysisController`
   SHALL revert all profile changes made by that run and SHALL set `status = 'rolled_back'`.
6. THE Contact360 AI Analysis tab SHALL display a findings review panel after a run completes,
   listing each finding with its confidence score and source evidence, and providing per-finding
   Apply, Ignore, and Rollback actions.
7. THE `NxAiAnalysisModal` SHALL include a scope selector (all messages, WhatsApp only, Facebook
   only, date range, specific import batch) and a model/agent selector connected to AgentsHub.
8. WHEN `POST /api/v1/contacts/analysis-runs/batch` is called, THE `AnalysisController`
   SHALL accept a `contact_ids` array and queue one `AnalyzeContactMessagesJob` per contact.
9. WHEN more than 10 analysis run requests are received from a single IP within 60 seconds,
   THE `AnalysisController` SHALL return HTTP 429.

---

### Requirement 9: Global and Per-Contact Memory Maintenance

**User Story:** As a user, I want to run memory maintenance operations across all contacts or
a specific contact from a dedicated modal, so that I can keep profiles accurate and clean
without manual intervention.

#### Acceptance Criteria

1. WHEN a user clicks "Maintain" in `ContactHubTopbarControls`, THE `TopbarControls` SHALL
   open a global Memory Maintenance modal with a scope selector: all contacts, stale only,
   conflicted only, or selected contacts.
2. WHEN `POST /api/v1/contacts/memory-maintenance` is called with `dry_run: true`, THE
   `MaintenanceController` SHALL estimate the number of records affected and return a preview
   report without modifying any data.
3. WHEN `POST /api/v1/contacts/memory-maintenance` is called with `dry_run: false`, THE
   `MaintenanceController` SHALL dispatch the appropriate maintenance jobs to the queue and
   return a maintenance run ID.
4. THE `ContactMemoryMaintenancePipeline` SHALL support `global` scope (no `contact_id`), so
   that hub-wide operations such as prune-stale, resolve-duplicates, and re-embed can run
   across all contacts without throwing an exception.
5. WHEN a maintenance job runs, THE `System` SHALL update the `ContactMemoryMaintenanceRun`
   record's progress fields so that polling `GET /api/v1/contacts/memory-maintenance/runs/{run}`
   returns current completion percentage, processed count, and error count.
6. THE Contact360 profile SHALL include a Memories tab displaying all `contact_memories` records
   for the contact with version history, confidence, and evidence.
7. WHEN a user navigates to `GET /api/v1/contacts/{contact}/memory-maintenance/runs`, THE
   `MaintenanceController` SHALL return the maintenance run history scoped to that contact.


---

### Requirement 10: Missing Backend Routes

**User Story:** As a developer, I want all ContactHub API routes defined in the spec to exist
and return meaningful responses, so that the frontend can implement all planned features.

#### Acceptance Criteria

1. THE backend SHALL expose `GET /api/v1/contacts/analytics` returning aggregated hub-level
   analytics including contact counts by type, channel distribution, reply mode distribution,
   import success/failure rates, and analysis cost totals.
2. THE backend SHALL expose `GET /api/v1/contacts/conflicts` returning a paginated list of
   contacts that have active, unresolved identity conflicts.
3. THE backend SHALL expose `GET /api/v1/contacts/stale-memory` returning a paginated list
   of contacts whose memory freshness score is below the configured staleness threshold.
4. THE backend SHALL expose `GET /api/v1/contacts/{contact}/messages/whatsapp` returning
   messages for the contact filtered to `channel = 'whatsapp'`.
5. THE backend SHALL expose `GET /api/v1/contacts/{contact}/messages/facebook` returning
   messages for the contact filtered to `channel = 'facebook_messenger'`.
6. THE backend SHALL expose `GET /api/v1/contacts/{contact}/threads` returning message thread
   summaries for the contact.
7. THE backend SHALL expose `GET /api/v1/contacts/{contact}/threads/{thread}` returning all
   messages in the specified thread.
8. THE backend SHALL expose `GET /api/v1/contacts/{contact}/intelligence` returning the
   assembled `ContactPersona`, `ContactTalkSpecs`, and `EmotionalBaseline` as structured
   objects, each with `confidence`, `evidence_references`, and `last_validated_at` fields.

---

### Requirement 11: Hub Event System Wiring

**User Story:** As a developer, I want all ContactHub events to be defined, dispatched, and
registered to listeners, so that downstream hubs (TasksHub, WorkflowsHub, ProactiveAIHub)
can react to ContactHub activity.

#### Acceptance Criteria

1. THE `System` SHALL define the following Laravel event classes:
   `ContactImportStarted`, `ContactImportCompleted`, `ContactAnalysisCompleted`,
   `ContactMemoryMaintenanceStarted`, `ContactMemoryMaintenanceCompleted`,
   `ContactReplyModeChanged`, `ContactMessageImported`, `ContactIdentityConflictDetected`.
2. WHEN an import batch is dispatched to the queue, THE `ImportController` SHALL dispatch the
   `ContactImportStarted` event.
3. WHEN an import job completes successfully, THE `ImportJob` SHALL dispatch the
   `ContactImportCompleted` event with the batch ID and message count.
4. WHEN a contact's reply mode is changed via `PATCH /contacts/{contact}/reply-mode` or
   `PATCH /contacts/reply-mode`, THE `ReplyModeService` SHALL dispatch the
   `ContactReplyModeChanged` event with actor, previous mode, and new mode.
5. WHEN an identity conflict is detected during import or identity resolution, THE
   `IdentityResolver` SHALL dispatch the `ContactIdentityConflictDetected` event with the
   conflicting contact IDs.
6. THE `EventServiceProvider` SHALL register all ContactHub events to their corresponding
   listeners so that event dispatch triggers listener execution.


---

### Requirement 12: Authorization Policies and Rate Limiting

**User Story:** As a system administrator, I want all ContactHub routes to enforce
authorization policies and rate limits, so that users can only perform operations they
are permitted to, and the queue cannot be flooded.

#### Acceptance Criteria

1. THE `System` SHALL define a `ContactPolicy` Laravel policy class and register it for
   the `Contact` model in `AuthServiceProvider`.
2. WHEN a request reaches any ContactHub controller method, THE `Controller` SHALL call
   `$this->authorize()` with the appropriate policy action before processing.
3. WHEN `POST /api/v1/contacts/import/whatsapp` or `POST /api/v1/contacts/import/facebook`
   receives more than 5 requests from the same user within 60 seconds, THE `ImportController`
   SHALL return HTTP 429.
4. WHEN `POST /api/v1/contacts/{contact}/analysis-runs` receives more than 10 requests per
   user per minute, THE `AnalysisController` SHALL return HTTP 429.
5. IF an uploaded import file exceeds 50 MB, THEN THE `ImportController` SHALL return HTTP 422
   with a validation error message before dispatching any job.

---

### Requirement 13: Privacy — Queued Export and Erase

**User Story:** As a user, I want contact export and erasure operations to run safely as
background jobs with audit records, so that large privacy requests do not time out and every
operation is verifiable.

#### Acceptance Criteria

1. WHEN `POST /api/v1/contacts/{contact}/export` is called, THE `PrivacyController` SHALL
   dispatch `ExportContactDataJob` to the queue and return a job reference ID.
2. WHEN `ExportContactDataJob` completes, THE `ExportJob` SHALL produce a downloadable archive
   containing the contact's profile, messages, memories, AI-derived findings, and audit events,
   and SHALL store a download URL in the audit record.
3. WHEN `POST /api/v1/contacts/{contact}/erase` is called, THE `PrivacyController` SHALL
   dispatch `EraseContactDataJob` to the queue and return a job reference ID.
4. WHEN `EraseContactDataJob` runs, THE `EraseJob` SHALL delete the contact's personal
   messages, memories, identifiers, vectors, and AI-derived findings, and SHALL retain an
   audit tombstone record indicating when erasure occurred and by whom.
5. WHEN an erase or export job completes or fails, THE `Job` SHALL write an audit event to
   `contact_audit_events` with actor, timestamp, and outcome.

---

### Requirement 14: Contact360 Intelligence Panel

**User Story:** As a user, I want to view a contact's AI-derived intelligence — persona,
talk specs, and emotional baseline — as structured, evidence-backed panels inside the contact
profile, so that I can make informed decisions about how to communicate.

#### Acceptance Criteria

1. THE Contact360 profile SHALL include an Intelligence section displaying `ContactPersona`
   fields (relationship context, interests, communication style, boundaries, trust level).
2. THE Contact360 Intelligence section SHALL display `ContactTalkSpecs` fields (preferred
   language, formality, message length, emoji tolerance, topics to avoid).
3. THE Contact360 Intelligence section SHALL display the `EmotionalBaseline` computed from
   analysis findings, showing sentiment range, common mood markers, and recent deviation.
4. WHEN the Intelligence section is displayed, THE `IntelligencePanel` SHALL show the
   `confidence` score, `last_validated_at` timestamp, and at least one `evidence_reference`
   for each structured field.
5. IF no intelligence data exists for a contact, THEN THE `IntelligencePanel` SHALL show an
   empty state with a prompt to run AI analysis.
6. THE `GET /api/v1/contacts/{contact}/intelligence` endpoint SHALL return `ContactPersona`,
   `ContactTalkSpecs`, and `EmotionalBaseline` as separate structured objects, not raw metadata
   JSON.


---

### Requirement 15: Contact Cards and Topbar Completeness

**User Story:** As a user, I want the ContactHub main page and contact cards to surface all
operational data defined in the spec, so that I can act on contacts without opening their
full profile.

#### Acceptance Criteria

1. THE `NxContactCard3D` component SHALL render the following fields when data is available:
   WhatsApp number, contact type badge, gender badge, main identifier, tags, reply mode
   indicator, per-contact override indicator, last interaction time, emotional baseline chip,
   AI profile confidence, memory freshness indicator, and open conflicts indicator.
2. THE `NxContactCard3D` component SHALL include quick action controls for: Open Profile,
   Start AI Analysis, Import Messages, View Conversations, Edit Reply Mode, Merge, and Archive.
3. WHEN a user clicks "Maintain" in `ContactHubTopbarControls` with no specific contact open,
   THE `TopbarControls` SHALL open a global Memory Maintenance modal (scope: all contacts),
   not display a toast notification.
4. THE `ContactHubTopbarControls` batch-analyze handler SHALL access the contacts list response
   using a typed response accessor that is not dependent on triple-nested `.data.data.data`
   chaining.
5. THE ContactHub main page SHALL include a Queue/progress indicator that shows the count and
   status of active import, analysis, and maintenance jobs.
6. WHEN the `ContactHubTopbarControls` component is using the import function via its topbar,
   THE `TopbarControls` SHALL open the `NxImportModal` component with its full source selector,
   file upload, and multi-step flow, not an inline drawer.

---

### Requirement 16: Topics Tab with Evidence

**User Story:** As a user, I want to browse topics extracted from a contact's messages and
see which messages support each topic, so that I can understand the basis for AI-extracted
insights.

#### Acceptance Criteria

1. THE Contact360 Topics tab SHALL fetch and display topics via
   `GET /api/v1/contacts/{contact}/topics`.
2. WHEN a user expands a topic, THE `TopicsViewer` SHALL display the source message
   citations (`ContactTopicMention` records) that contributed to that topic's extraction.
3. THE backend SHALL expose topic-mention evidence through the topics response or a nested
   `GET /api/v1/contacts/{contact}/topics/{topic}/mentions` route.
4. IF a topic was generated by an AI analysis run, THEN THE `TopicsViewer` SHALL display
   the confidence score and the analysis run ID as a clickable reference.

---

### Requirement 17: Relationship Graph Visualization

**User Story:** As a user, I want to see a contact's relationships visualized as a graph in
addition to a list, so that I can understand the network of connections at a glance.

#### Acceptance Criteria

1. THE Contact360 Relationships tab SHALL include a graph view that renders relationship
   edges between the current contact and related contacts using node-link visualization.
2. WHEN a user clicks a node in the relationship graph, THE `RelationshipGraph` SHALL navigate
   to the related contact's Contact360 profile page or display a mini-profile popover.
3. THE relationship graph SHALL encode relationship type by edge color or label and SHALL encode
   relationship strength by edge weight or thickness.
4. WHEN fewer than 2 relationships exist for a contact, THE `RelationshipGraph` SHALL show an
   empty state message rather than rendering an empty canvas.


---

### Requirement 18: Production Hardening

**User Story:** As a developer, I want ContactHub to handle edge cases, failures, and load
gracefully, so that the feature is stable under real-world usage.

#### Acceptance Criteria

1. THE `ContactController::messages()` method SHALL build cache keys using only a fixed,
   whitelisted set of query parameters (channel, search, page, per_page, date_from, date_to)
   to prevent unbounded cache key growth.
2. WHEN a new import batch is committed for a contact, THE `ImportJob` SHALL invalidate the
   message cache for that contact so that subsequent message list requests return fresh data.
3. THE `ContactMemoryMaintenancePipeline` SHALL use database transactions for all write
   operations within a maintenance run so that a partial failure does not leave data in an
   inconsistent state.
4. WHEN a queue job fails after all retries, THE `Job` SHALL update the associated batch,
   analysis run, or maintenance run status to `failed` and SHALL write an audit event.
5. THE Contact360 detail page SHALL display loading skeleton states for all tab content while
   data is being fetched, and SHALL display inline error states if a data fetch fails.
6. THE ContactHub main contacts list page SHALL display an empty state with import and add
   contact call-to-actions when no contacts exist.
7. THE Contact360 WhatsApp tab, Facebook tab, Conversations tab, and Memories tab SHALL each
   display a clear empty state with an import prompt when no messages or memories exist.
8. WHEN `ContactStatsService` counts failed imports and failed analysis runs, THE
   `StatsService` SHALL query the `contact_import_batches` table for `status = 'failed'`
   and the `contact_analysis_runs` table for `status = 'failed'` to produce accurate counts.

