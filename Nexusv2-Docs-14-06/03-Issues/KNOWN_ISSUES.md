# Nexus v2 — Known Issues, Logic Bugs & Technical Gaps

> **Purpose:** This document tracks all known bugs, logic issues, missing features, incomplete implementations, and technical debt in the Nexus v2 codebase. Updated as of 2026-06-19.

---

## 0. Recently Resolved Issues (2026-06-19)

### 0.3 WAHA Manage & Synchronization Implementation
**Affected Component:** `/contacts/waha-manage`, `LiveMsgsSyncService`, `WahaManageController`
**Status:** **[RESOLVED] / [IMPLEMENTED]**
**Description:** A complete, state-managed background processing engine was needed to pull contacts and messages from the WAHA API without timing out, alongside AI analysis queues for large contact message histories.
**Implementation:** 
- Created `waha_sync_processes` table to track progress and allow pausing/resuming of background sync jobs.
- Implemented `/contacts/waha-manage` frontend page with real-time stats, AI Configuration Modals, Log terminals, and Pause/Resume controls.
- Contacts Hub top-bar updated with WAHA status badges and appropriate padding (`pt-20`, `pb-70`).

### 0.1 WAHA Integration Settings Not Saving
**Affected Component:** `SettingController@bulkUpdate`, `IntegrationsTab.tsx`
**Status:** **[RESOLVED]**
**Description:** WAHA credentials (`waha_url`, `waha_api_key`, `waha_webhook_secret`) were failing to save from the frontend because they were missing from the database, and `bulkUpdate` only updates existing keys.
**Fix:** Executed `SettingSeeder` to populate the default setting keys into the database.

### 0.2 Missing Global Toast Notification Listener
**Affected Component:** `NxToaster.tsx` (New), `app/layout.tsx`
**Status:** **[RESOLVED]**
**Description:** Action buttons (like "Test Connection" for WAHA) dispatched `nx:toast` events, but there was no global listener to render them, leading to silent failures/successes.
**Fix:** Created a new `NxToaster` container component to listen for `nx:toast` window events and display `NxToast` alerts, and injected it into `app/layout.tsx`.

---

## 1. Logic Bugs

### 1.1 Memory Deduplication — No Vector Similarity Check
**Affected Component:** `MemoryMaintenanceService`
**Severity:** Medium
**Description:** The memory deduplication logic currently performs **exact string matching** to find duplicates. Two memories with the same semantic meaning but different wording will NOT be detected as duplicates.

**Expected behavior:** Deduplication should use **cosine similarity on embeddings** (threshold ~0.92) to find near-duplicate memories.

**Current code path:** `MemoryMaintenanceService::deduplicate()`
**Impact:** Memory bloat over time; redundant data stored.

---

### 1.2 WorkflowExecutor — Parallel Step Execution Not Implemented
**Affected Component:** `WorkflowExecutor`
**Severity:** Medium
**Description:** The workflow engine processes steps **sequentially** even when steps have no dependency on each other and could run in parallel. The `depends_on` field on steps is parsed but parallel execution is not implemented.

**Expected behavior:** Steps without dependency relationships should execute concurrently via parallel jobs.

**Impact:** Slow workflow execution for multi-step workflows.

---

### 1.3 Contact Identity Resolution Race Condition
**Affected Component:** `ContactIdentityResolver`, `ContactController@store`, `PeopleConnectContactResolver`
**Severity:** High
**Status:** **[RESOLVED]** Concurrent incoming WAHA webhooks are now serialized using atomic Redis locks (`Cache::lock("contact_resolve_{$phone}")`) with a 5-second block wait in `PeopleConnectContactResolver` to prevent duplicate contact creation.
**Description:** If two requests arrive simultaneously for the same contact, both may pass the identity resolution check before either creates the contact, resulting in duplicate contacts.
**Suggested fix:** Add a database-level unique constraint on `ContactIdentifier.value + type` and handle the constraint violation gracefully.

---

### 1.4 HedraSoul Approval Flow — No Timeout Handling
**Affected Component:** `ApprovalInboxService`, `HedrasoulApprovalRequest`
**Severity:** Medium
**Description:** When HedraSoul creates an approval request, execution is blocked indefinitely waiting for a user decision. There is no timeout mechanism to auto-reject or auto-defer stale approval requests.

**Expected behavior:** Approval requests older than a configurable TTL (e.g., 24h) should auto-defer or auto-reject.

---

### 1.5 Working Memory — No Automatic Session Cleanup
**Affected Component:** `WorkingMemoryService`
**Severity:** Low-Medium
**Description:** Working memories have an `expires_at` field but there is no scheduled job that **automatically deletes** expired working memories. Manual maintenance must be triggered.

**Suggested fix:** Add a scheduled `SchedulerJob` or Laravel cron entry to run `WorkingMemoryService::clearExpired()` daily.

---

### 1.6 WAHA Webhook — No Signature Verification
**Affected Component:** `WebhookController@handleWahaWebhook`
**Severity:** High (Security)
**Status:** **[RESOLVED]** Webhook signature verification is now implemented in `WebhookController` supporting `X-Webhook-Hmac` (HMAC-SHA512), `X-WAHA-Signature` (HMAC-SHA256), `X-Hub-Signature-256` (HMAC-SHA256), and fallback credentials checking.
**Description:** The WAHA webhook endpoint did not verify an HMAC signature or shared secret to confirm the request originates from the legitimate WAHA server.
**Expected behavior:** Validate `X-WAHA-Signature` header against a shared `WAHA_WEBHOOK_SECRET`.

---

## 2. Missing Features / Incomplete Implementations

### 2.1 Semantic Search — Pinecone Integration Not Wired
**Affected Component:** `SemanticMemoryService`, `SaveToPineconeJob`, `VectorizeMemoryJob`
**Severity:** High
**Description:** The jobs for vectorizing memories and saving to Pinecone exist and are dispatched, but the actual **Pinecone API calls** in `SaveToPineconeJob` and semantic search queries are **not implemented**. They contain stub/placeholder code.

**Impact:** Semantic memory search falls back to full-text SQL search, which is significantly less effective.

---

### 2.2 MCP Tool Execution — Incomplete Implementation
**Affected Component:** `MCPIntegrationService`, `AgentToolExecutor`
**Severity:** Medium
**Description:** MCP server registration and tool listing are implemented. However, the actual **tool invocation** (`mcpService->callTool()`) makes HTTP calls but **error handling, streaming responses, and timeout management** are incomplete.

---

### 2.3 Workflow Canvas — Step Configuration Panels Not All Implemented
**Affected Component:** `app/workflows/page.tsx`
**Severity:** Medium
**Description:** The visual React Flow canvas is functional for placing nodes and connecting them. However, some step types (notably `loop`, `wait_for_event`, `condition`) do not have their **configuration side panels** fully implemented. The step config is saved as JSON but no UI exists to configure these step types.

---

### 2.4 Contact Import — Progress Tracking Not Real-Time
**Affected Component:** `ContactImportController`, `ContactImportBatch`
**Severity:** Low
**Description:** CSV import progress is stored in the `contact_import_batches` table, but the frontend **polls** via HTTP instead of receiving real-time WebSocket updates. Large imports (>1000 contacts) cause noticeable UX latency between UI refresh cycles.

**Expected fix:** Broadcast `ImportProgressUpdated` event via WebSocket during import.

---

### 2.5 ProactiveAIHub — Actions Partially Wired
**Affected Component:** `ProactiveAIController`, `ProactiveSchedulerCommand`
**Severity:** Medium
**Description:** Proactive trigger evaluation runs on schedule, but only `send_notification` and `create_task` action types are fully wired. The `execute_agent` and `update_contact` action types are defined in the schema but not yet connected to their service implementations.

---

### 2.6 Dashboard — Real-Time Stats Partially Incomplete
**Affected Component:** `NexusDashboardService`, `app/page.tsx`
**Severity:** Low
**Description:** The Nexus dashboard stats endpoint (`/api/dashboard`) returns data but some metrics (e.g., "AI Cost This Month", "Active Agent Count", "Memory Growth Rate") are returning placeholder zeroes or hardcoded values instead of actual aggregated data.

---

### 2.7 HedraSoul Clone Profile — Content Processing Stub
**Affected Component:** `HedraCloneProfileService`
**Severity:** Medium
**Description:** The clone source ingestion endpoint accepts documents but the actual AI processing that extracts `HedraProfileFacts` from the source content uses a **stub implementation** that simply copies text without actual LLM-based extraction.

---

## 3. Technical Debt & Code Quality Issues

### 3.1 ContactController — Oversized (42KB)
**File:** `app/Http/Controllers/ContactController.php`
**Issue:** This controller is too large (42KB, ~1400 lines). Many methods should be extracted to specialized sub-controllers or service layer methods.

---

### 3.2 MemoryController — Oversized (30KB)
**File:** `app/Http/Controllers/MemoryController.php`
**Issue:** Similar to ContactController, this controller handles too many concerns. The analysis run management, memory maintenance, and contact memory operations should be separate controllers.

---

### 3.3 SettingController — Oversized (29KB)
**File:** `app/Http/Controllers/SettingController.php`
**Issue:** Over 900 lines. Settings for different domains should use domain-specific controllers.

---

### 3.4 Missing API Resources for Consistent Response Format
**Issue:** Some controllers return `$model->toArray()` directly rather than going through an API Resource class. This means response shape can change with model changes and fields may be over-exposed.

**Affected:** Several sub-controllers in HedraSoul and PeopleConnect sections.

---

### 3.5 Frontend — Large `store/index.ts` (44KB)
**File:** `store/index.ts`
**Issue:** The Zustand store is a single 44KB file with all slices combined. Should be split into per-hub slice files and composed.

---

### 3.6 No End-to-End Tests for Critical Flows
**Issue:** While unit tests exist (PHPUnit, Vitest), there are no Playwright E2E tests covering the critical user flows:
- Complete contact creation → analysis → memory extraction
- HedraSoul conversation → approval gate → action execution
- Workflow creation → trigger → execution → result

---

### 3.7 Environment Variable Validation
**Issue:** There is no startup validation that required environment variables (AI provider keys, WAHA config, etc.) are present and valid. Missing config causes silent failures or cryptic errors.

**Suggested fix:** Add a `ValidateEnvironment` artisan command that runs on deployment.

---

## 4. Performance Concerns

### 4.1 N+1 Query Risk in Contact List
**Location:** `ContactController@index`
**Issue:** Contact listing may trigger N+1 queries when loading tags, identifiers, or latest message for each contact without proper eager loading in all code paths.

---

### 4.2 Large Import Jobs — No Chunking
**Location:** `ContactImportController`
**Issue:** CSV imports are processed in a single job. Files with >10,000 rows may cause memory exhaustion or job timeouts. Should be chunked into batches of 100-500 rows.

---

### 4.3 Settings Cache TTL Not Set
**Location:** `SettingCacheService`
**Issue:** Settings cached in Redis with no explicit TTL. In theory they persist indefinitely, but in practice Redis eviction policies under memory pressure can remove them without invalidation notification.

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
