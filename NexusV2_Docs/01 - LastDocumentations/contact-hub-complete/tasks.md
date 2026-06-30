# Implementation Plan: ContactHub Complete

## Overview

This plan implements the Nexus ContactHub from ~35% to production-ready across two codebases:
- **Nexus-backend** — Laravel 11, PHP 8.2 (`Nexus-backend/`)
- **Nexus-Frontend** — Next.js 14, TypeScript (`Nexus-Frontend/`)

Work is sequenced as: Phase 1 critical bug fixes → Phase 2 async import pipeline →
Phase 3 authorization & events → Phase 4 missing routes & intelligence → Phase 5 memory
maintenance & privacy → Phase 6-8 frontend features → Phase 9 property-based tests.

## Tasks

- [x] 1. Phase 1 — Backend: Critical Bug Fixes
  - [x] 1.1 Fix `clone` PHP fatal error in `ContactImportController::importMessages()`
    - In `app/Http/Controllers/ContactImportController.php`, remove the `clone` keyword
      from the line `clone $result['batch']->messages()->count()` — replace with plain
      `$result['batch']->messages()->count()`
    - Confirm the PHP file compiles without syntax errors (`php -l`)
    - _Requirements: 2.1, 2.2_

  - [x] 1.2 Delete zero-byte misplaced route files
    - Delete `routes/ContactImportController.php` and `routes/ContactMessage.php`
    - These files are zero bytes and are not valid route definitions; their presence
      can cause Laravel's route bootstrap to fail
    - _Requirements: 2.3_

  - [x] 1.3 Remove `DELETE /contacts/{id}/erase` route conflict
    - In `routes/api.php`, remove the `Route::delete('/contacts/{id}/erase', ...)` line
    - Keep only `Route::post('/contacts/{id}/erase', ...)` to avoid conflict with
      `Route::apiResource`'s own `DELETE /contacts/{id}` (destroy)
    - _Requirements: 2.4_

  - [x] 1.4 Fix `ContactController::messages()` cache key to use parameter whitelist
    - Replace the unbounded `md5(json_encode($request->query()))` cache key with a
      whitelist-filtered version using only `channel`, `search`, `page`, `per_page`,
      `date_from`, `date_to` keys
    - _Requirements: 18.1_

  - [x] 1.5 Fix `ContactStatsService` failed counts to read from database tables
    - In `app/Services/ContactStatsService.php`, update `failed_imports` to use
      `ContactImportBatch::where('status', 'failed')->count()` and `failed_analysis_runs`
      to use `ContactAnalysisRun::where('status', 'failed')->count()`
    - _Requirements: 18.8_

  - [x] 1.6 Add database migrations for missing columns
    - Create migration `add_error_message_to_contact_analysis_runs`: adds
      `error_message TEXT NULL` after `completed_at`
    - Create migration `add_evidence_to_contact_analysis_findings`: adds
      `evidence_references JSON NULL` and `source_message_ids JSON NULL` after
      `confidence_score`
    - Create migration `add_progress_columns_to_maintenance_runs`: ensures
      `processed_count`, `error_count`, and `completion_percentage DECIMAL(5,2)` exist
      on `contact_memory_maintenance_runs`
    - _Requirements: 5.3, 5.1_

  - [ ]* 1.7 Write unit tests for Phase 1 bug fixes
    - Test that `ContactStatsService::getStats()` reads from DB tables (Property 28)
    - Test that `messages()` cache key only uses whitelisted params (Property 24)
    - Test that no PHP fatal error occurs on `importMessages()` integer count path
    - _Requirements: 18.1, 18.8, 2.1_

- [x] 2. Phase 1 — Frontend: Critical Bug Fixes

  - [x] 2.1 Fix `NxMessageViewer` — replace raw `fetch()` with `apiClient`
    - In `components/NxMessageViewer.tsx`, replace the raw `fetch(...)` call (which uses
      a hardcoded `http://localhost:8000` base URL) with `apiClient.get(...)` from
      `@/lib/api/client`
    - Add a `channel` prop (`'whatsapp' | 'facebook_messenger' | 'all'`) and an
      `endpoint` prop so callers can specify the messages endpoint
    - Remove all hardcoded hostnames and ports
    - _Requirements: 1.1, 1.2_

  - [x] 2.2 Fix `NxRulesViewer` — replace mock data with real API calls
    - Replace the `setTimeout` mock in `components/NxRulesViewer.tsx` with a `useEffect`
      that calls `GET /api/v1/contacts/{contactId}/reply-rules` via `apiClient`
    - Implement `handleAddRule` to call `POST /api/v1/contacts/{contactId}/reply-rules`
    - Implement `handleRemoveRule` to call
      `DELETE /api/v1/contacts/{contactId}/reply-rules/{ruleId}`
    - Remove the `// eslint-disable-next-line react-hooks/set-state-in-effect` suppression
      and the unconditional `setIsLoading(true)` inside `useEffect`
    - On API error, display inline error and preserve previously loaded rules list
    - _Requirements: 1.3, 1.4, 1.5, 1.6_

  - [x] 2.3 Fix `NxAiAnalysisModal` — add `suggest_rules` checkbox and selectors
    - Add a visible, labelled checkbox for `suggest_rules` to the modal UI (currently
      the option is sent silently without user consent)
    - Add a scope `<select>` (All Messages, WhatsApp only, Facebook only, Date Range)
    - Add an agent/model selector using the existing `NxModelSelector` component pointing
      to `/api/v1/agents`
    - Update the payload sent to `POST /contacts/{id}/analysis-runs` to include `scope`
      and `agent_id` alongside the `options` object
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 2.4 Fix Contact360 `useEffect` tab switch — add `topics` and `audit` cases
    - In `app/contacts/[id]/page.tsx`, add `case 'topics': await loadTopics(); break;`
      and `case 'audit': await loadAuditEvents(); break;` to the `activeTab` switch
    - `loadTopics` calls `apiClient.get('/contacts/${contact.id}/topics')`
    - `loadAuditEvents` calls `apiClient.get('/contacts/${contact.id}/audit')`
    - _Requirements: 4.1, 4.2, 4.3_

  - [x] 2.5 Fix `ContactHubTopbarControls` triple-nested `.data.data.data` accessor
    - In `components/ContactHubTopbarControls.tsx`, replace the fragile
      `contactsResp.data?.data?.data` chain with a typed `ApiResponse` accessor
    - Define a typed `ContactListResponse` interface and use it on the `apiClient.get`
      call to eliminate triple-nesting
    - _Requirements: 15.4_

  - [ ]* 2.6 Write unit/component tests for Phase 1 frontend fixes
    - `NxMessageViewer`: assert no raw `fetch()` in source; assert `apiClient.get` called
      with correct URL and params (Property 10)
    - `NxRulesViewer`: assert GET on mount; assert POST on add; assert DELETE on remove;
      assert rules preserved on error
    - `NxAiAnalysisModal`: assert 4 checkboxes rendered; assert payload matches all
      checkbox states (Property 1); assert scope selector and agent selector present
    - _Requirements: 1.1, 1.3, 3.1, 3.3_

- [ ] 3. Checkpoint — Phase 1 complete
  - Ensure all Phase 1 backend and frontend fixes compile and pass tests.
  - Run `php artisan migrate` to verify migrations apply cleanly.
  - Ask the user if questions arise before proceeding to Phase 2.

- [x] 4. Phase 2 — Backend: Async Import Pipeline — Services and Jobs

  - [x] 4.1 Create `ContactImportPreviewService` standalone service
    - Create `app/Services/Contact/ContactImportPreviewService.php`
    - Extract preview logic from `ContactImportPipeline::preview()` into this injectable
      service; it must parse the import content in memory using `WhatsAppImportParser`,
      `FacebookImportParser`, and `ContactMessageNormalizer` without any DB writes
    - Accepts: `Contact`, `string $source`, `string $content`, `string $format`,
      `string $timezone`; returns preview array with message counts, date ranges, senders,
      and potential contact matches
    - _Requirements: 6.3, 6.8_

  - [x] 4.2 Create `ContactImportRollbackService` standalone service
    - Create `app/Services/Contact/ContactImportRollbackService.php`
    - Extract rollback logic from `ContactImportPipeline::rollback()` into this service;
      wraps operations in a DB transaction; deletes all messages for the given
      `ContactImportBatch`, sets status to `rolled_back`, dispatches
      `ContactImportCompleted` with outcome `rolled_back`
    - Accepts `ContactImportBatch $batch`
    - _Requirements: 6.5, 6.9_

  - [x] 4.3 Create async import queue jobs
    - Create `app/Jobs/ImportContactMessagesJob.php` — calls
      `ContactImportPipeline::commit()` for a pre-created batch; dispatched to `contacts`
      queue
    - Create `app/Jobs/NormalizeContactImportBatchJob.php` — deduplication pass using
      source ID + content hash; dispatched to `contacts` queue
    - Create `app/Jobs/ResolveContactImportIdentitiesJob.php` — identity resolution for
      imported participants; dispatched to `contacts` queue
    - Create `app/Jobs/RollbackContactImportBatchJob.php` — delegates to
      `ContactImportRollbackService`; dispatched to `contacts` queue
    - All jobs extend `App\Jobs\BaseJob` and implement `failed(Throwable $e)` to update
      the run record status to `failed` and write a `ContactAuditEvent`
    - _Requirements: 6.1, 6.2, 6.4, 6.5, 18.4_

  - [x] 4.4 Update import controller endpoints to dispatch async jobs
    - Update `ContactImportController::importWhatsApp()` and `::importFacebook()`:
      1. Create a `ContactImportBatch` record with `status = 'queued'`
      2. Dispatch `ImportContactMessagesJob` with the batch, content, format, timezone
      3. Dispatch `ContactImportStarted` event
      4. Return `response()->json(['data' => ['batch_id' => $batch->id, 'status' => 'queued']], 202)`
    - Add `'file' => ['nullable', 'file', 'max:51200']` validation to both endpoints
      (50 MB limit); return HTTP 422 on violation
    - Add cache invalidation call after import batch commit: invalidate the message cache
      for the contact using tag-based or SCAN-based Redis delete
    - _Requirements: 6.1, 6.2, 6.6, 12.5, 18.2_

  - [ ]* 4.5 Write feature tests for async import pipeline
    - `ContactImportTest`: assert `POST /import/whatsapp` returns 202 with `batch_id`
      and `status=queued`; assert `ImportContactMessagesJob` dispatched (Property 5)
    - Assert `POST /import/facebook` returns 202 (Property 5)
    - Assert file > 50 MB returns 422
    - Assert preview endpoint returns parsed data without persisting rows (Property 6)
    - `ContactImportRollbackServiceTest`: assert rollback sets status and deletes messages
      (Property 8)
    - Assert deduplication: importing same file twice yields same message count (Property 7)
    - Assert error rows recorded without aborting: `imported + failed == total` (Property 9)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [x] 5. Phase 3 & 4 — Backend: Authorization Policy and Hub Events

  - [x] 5.1 Create `ContactPolicy` and register it
    - Create `app/Policies/ContactPolicy.php` with methods: `viewAny`, `view`, `create`,
      `update`, `delete`, `importMessages`, `runAnalysis`, `applyAnalysis`,
      `runMaintenance`, `export`, `erase`
    - Register in `AuthServiceProvider::$policies`:
      `\App\Models\Contact::class => \App\Policies\ContactPolicy::class`
    - Add `$this->authorize(action, $contact)` calls at the top of every ContactHub
      controller method
    - _Requirements: 12.1, 12.2_

  - [x] 5.2 Add rate limiting to import and analysis endpoints
    - In `routes/api.php`, add `->middleware('throttle:5,1')` to both import endpoints
    - Add `->middleware('throttle:10,1')` to `POST /contacts/{id}/analysis-runs`
    - In `AppServiceProvider::boot()`, register a named `RateLimiter::for('analysis', ...)`
      that limits per user ID (not just IP)
    - _Requirements: 12.3, 12.4, 8.9_

  - [x] 5.3 Create the 6 missing Laravel event classes
    - Create `app/Events/ContactImportStarted.php` — payload: `Contact $contact,
      ContactImportBatch $batch`
    - Create `app/Events/ContactMemoryMaintenanceStarted.php` — payload:
      `ContactMemoryMaintenanceRun $run, ?Contact $contact`
    - Create `app/Events/ContactMemoryMaintenanceCompleted.php` — same payload
    - Create `app/Events/ContactReplyModeChanged.php` — payload: `Contact $contact,
      string $previousMode, string $newMode, int $actorId`
    - Create `app/Events/ContactMessageImported.php` — payload: `Contact $contact,
      ContactMessage $message`
    - Create `app/Events/ContactIdentityConflictDetected.php` — payload: `Contact $contact,
      array $conflictingContactIds`
    - _Requirements: 11.1_

  - [x] 5.4 Wire events in `EventServiceProvider` and dispatch event call-sites
    - Register `ContactImportCompleted`, `ContactAnalysisCompleted`,
      `ContactIdentityConflictDetected`, `ContactReplyModeChanged` to their listener
      classes in `EventServiceProvider::$listen`
    - Ensure `ContactImportStarted` is dispatched in the import controller (task 4.4)
    - Dispatch `ContactMemoryMaintenanceStarted` and `ContactMemoryMaintenanceCompleted`
      in the maintenance pipeline (wired in Phase 5)
    - Dispatch `ContactReplyModeChanged` in `ContactReplyModeService` when mode is updated
    - Dispatch `ContactIdentityConflictDetected` in the identity resolver
    - _Requirements: 11.2, 11.3, 11.4, 11.5, 11.6_

  - [ ]* 5.5 Write `ContactPolicyTest` and `ContactRateLimitTest`
    - `ContactPolicyTest`: assert users without required roles receive HTTP 403 on
      protected routes before any business logic runs (Property 16)
    - `ContactRateLimitTest`: assert 6th import request from same user within 60s returns
      429; assert 11th analysis request returns 429
    - _Requirements: 12.2, 12.3, 12.4_

  - [x] 5.5 Update Backend Routes (`api.php`)nd erase controller endpoints to dispatch async jobs
    - Update `POST /contacts/{id}/export` to dispatch `ExportContactDataJob` and return
      a job reference ID (do not process synchronously)
    - Update `POST /contacts/{id}/erase` to dispatch `EraseContactDataJob` and return
      a job reference ID
    - _Requirements: 13.1, 13.3, 17.1, 18.1_

  - [x] 5.6 Fix Intelligence Route Data Structured objects from analysis findings
    - Refactor `ContactController::intelligence($id)` to assemble structured objects from
      `contact_analysis_findings` instead of reading raw `metadata` JSON
    - Implement `assemblePersona()`, `assembleTalkSpecs()`, `assembleEmotionalBaseline()`
      private methods reading findings by `finding_type`
    - Each assembled object includes `confidence`, `evidence_references`,
      `last_validated_at` fields
    - _Requirements: 14.6, 10.8_

- [ ] 6. Phase 4 — Backend: Missing Routes and Intelligence Endpoint

  - [ ] 6.1 Add missing analytics and operational routes to `api.php`
    - Add before `Route::apiResource('contacts')`:
      - `GET /contacts/analytics` → `ContactController::hubAnalytics()`
      - `GET /contacts/conflicts` → `ContactController::conflicts()`
      - `GET /contacts/stale-memory` → `ContactController::staleMemory()`
      - `GET /contacts/{id}/memory-maintenance/runs` →
        `ContactController::contactMaintenanceRuns()`
      - `GET /contacts/{id}/topics/{topic}/mentions` →
        `ContactController::topicMentions()`
    - _Requirements: 10.1, 10.2, 10.3, 9.7, 16.3_

  - [ ] 6.2 Implement `hubAnalytics()`, `conflicts()`, `staleMemory()`, and
    `contactMaintenanceRuns()` controller methods
    - `hubAnalytics()`: aggregate contact counts by type, channel distribution from
      `contact_messages`, reply mode distribution, import rates, analysis cost totals
    - `conflicts()`: return contacts with `conflict_detected = true` identifiers or
      low-confidence aliases, paginated
    - `staleMemory()`: return contacts where `memory_freshness < now()-30d` or NULL,
      paginated
    - `contactMaintenanceRuns()`: return `ContactMemoryMaintenanceRun` records scoped
      by `contact_id` from the route parameter, paginated
    - _Requirements: 10.1, 10.2, 10.3, 9.7_

  - [ ] 6.3 Implement `topicMentions()` and update `topics()` with eager-loaded mentions
    - Implement `topicMentions($id, $topicId)`: load `ContactTopic`, return paginated
      `mentions()->with('message')` collection
    - Update `topics()` to eager-load mentions with count:
      `ContactTopic::withCount('mentions')->with(['mentions' => fn($q) => $q->limit(3)])`
    - _Requirements: 16.2, 16.3_

  - [ ] 6.4 Refactor `intelligence()` to return structured objects from analysis findings
    - Refactor `ContactController::intelligence($id)` to assemble structured objects from
      `contact_analysis_findings` instead of reading raw `metadata` JSON
    - Implement `assemblePersona()`, `assembleTalkSpecs()`, `assembleEmotionalBaseline()`
      private methods reading findings by `finding_type`
    - Each assembled object includes `confidence`, `evidence_references`,
      `last_validated_at` fields
    - _Requirements: 14.6, 10.8_

  - [ ] 6.5 Fix `ContactIntelligenceExtractionPipeline` — remove mock fallback, add evidence
    - Replace the AI-failure catch block that writes fabricated findings with a clean
      failure path: `$run->update(['status' => 'failed', 'error_message' => $e->getMessage()])`
      and return without writing any findings
    - Before calling the AI gateway, collect all message IDs used in the context window
    - After receiving AI response, map each finding to source messages and populate
      `evidence_references` and `source_message_ids` on each `ContactAnalysisFinding`
    - _Requirements: 5.1, 5.2_

  - [ ]* 6.6 Write `ContactIntelligenceTest` and pipeline unit tests
    - Feature test: `GET /contacts/{id}/intelligence` returns `persona`, `talkSpecs`,
      `emotionalBaseline` as structured objects, not raw metadata JSON (Property 21)
    - Unit test: assert AI failure writes no findings and sets run to `failed` (Property 4)
    - Unit test: assert success populates `evidence_references` and `source_message_ids`
      on every finding (Property 3)
    - _Requirements: 5.1, 5.2, 14.6_

- [ ] 7. Checkpoint — Backend Phases 2–4 complete
  - Ensure all backend tests pass. Run `php artisan route:list` to verify new routes
    are registered. Verify migrations apply cleanly.
  - Ask the user if questions arise before proceeding to Phase 5.

- [x] 7. Phase 5 — Backend: Memory Maintenance and Privacy

  - [x] 7.1 Enable Global Maintenance Pipeline `ContactMemoryMaintenancePipeline`
    - In `app/Services/Contact/ContactMemoryMaintenancePipeline.php`, replace the
      `throw new Exception("Global maintenance runs are currently disabled.")` block
      with a full global implementation that queries contacts by scope filter
      (`all` / `stale` / `conflicted`), chunks by 100, and applies the requested
      operation per contact within a DB transaction
    - Dispatch `ContactMemoryMaintenanceStarted` before processing and
      `ContactMemoryMaintenanceCompleted` after
    - Update the run record's `processed_count`, `error_count`, and
      `completion_percentage` fields as processing proceeds
    - _Requirements: 9.4, 9.5, 11.2_

  - [x] 7.2 Implement standalone privacy jobs
    - Create `app/Jobs/ExportContactDataJob.php` dispatched to `contacts-privacy` queue:
      builds export archive (profile + messages + memories + findings + audit events),
      stores it on S3/local disk, writes download URL to audit record
    - Create `app/Jobs/EraseContactDataJob.php` dispatched to `contacts-privacy` queue:
      deletes messages/memories/identifiers/vectors within a DB transaction, writes
      `ContactAuditEvent` tombstone with `action = 'erased'`
    - Both implement `failed(Throwable $e)` to write audit event with failure outcome
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 18.4_

  - [x] 7.3 Implement remaining maintenance jobs
    - Create `app/Jobs/RebuildContactMemoryJob.php` → `contacts-maintenance` queue
    - Create `app/Jobs/RecomputeContactEmbeddingsJob.php` → `contacts-maintenance` queue
    - Create `app/Jobs/DetectContactMemoryConflictsJob.php` → `contacts-maintenance` queue
    - Create `app/Jobs/RecalculateContactBaselineJob.php` → `contacts-maintenance` queue
    - Create `app/Jobs/PruneContactMemoryJob.php` → `contacts-maintenance` queue
    - All extend `App\Jobs\BaseJob` and implement `failed(Throwable $e)` to update run
      status to `failed` and create a `ContactAuditEvent`
    - _Requirements: 9.3, 18.4_

  - [ ]* 8.5 Write `ContactPrivacyTest` and `ContactMaintenanceTest`
    - `ContactPrivacyTest`: assert `POST /export` dispatches `ExportContactDataJob` and
      returns job ID (Property 17); assert `POST /erase` dispatches `EraseContactDataJob`
      (Property 18); assert erase job leaves tombstone and clears messages/memories
      (Property 19); assert privacy jobs write audit events on success and failure
      (Property 20)
    - `ContactMaintenanceTest`: assert `dry_run=true` modifies nothing (Property 14);
      assert `contactMaintenanceRuns` returns only runs scoped to the requested contact
      (Property 15); assert global maintenance pipeline runs without exception
    - `ContactMemoryMaintenancePipelineTest`: assert DB transaction rollback on failure
      (Property 26); assert `failed()` hook updates status and writes audit event
      (Property 27)
    - _Requirements: 9.2, 9.4, 9.7, 13.1, 13.3, 13.4, 18.3, 18.4_

- [x] 9. Phase 6 — Frontend: New Contact360 Tabs

  - [x] 9.1 Add WhatsApp and Facebook tabs to Contact360
    - In `app/contacts/[id]/page.tsx`, add `whatsapp` and `facebook` entries to the
      `tabs` array with appropriate icons
    - Render `<NxMessageViewer endpoint={...} channel="whatsapp" />` for the WhatsApp
      tab and `<NxMessageViewer endpoint={...} channel="facebook_messenger" />` for
      Facebook tab using the fixed `NxMessageViewer` from task 2.1
    - _Requirements: 7.1, 7.2_

  - [x] 9.2 Create `NxConversationsViewer` component and add Conversations tab
    - Create `components/NxConversationsViewer.tsx` with props
      `{ contactId: number; contactName: string }`
    - Implement group-by segmented control (Thread / Channel / Topic / Date), search bar,
      date range picker, and message stream using `NxMessageBubble`
    - Fetch from `GET /api/v1/contacts/{contactId}/messages` via `apiClient` with the
      selected grouping parameter
    - Implement loading state (`NxSkeleton`), error state with retry, and empty state
      (`NxEmptyState` with import CTA)
    - Add `conversations` tab to Contact360 tabs array
    - _Requirements: 7.3, 7.4, 7.5, 7.7, 18.7_

  - [x] 9.3 Create `NxMemoriesViewer` component and add Memories tab
    - Create `components/NxMemoriesViewer.tsx` with props `{ contactId: number }`
    - Fetch `GET /api/v1/contacts/{contactId}/memory` via `apiClient`
    - Render each memory record with: content summary, confidence, `created_at`, version
      indicator; clicking expands to show version history and evidence
    - Implement loading, error, and empty states (empty state prompts to run AI analysis)
    - Add `memories` tab to Contact360
    - _Requirements: 9.6, 18.7_

  - [x] 9.4 Create `NxIntelligencePanel` component and add Intelligence tab
    - Create `components/NxIntelligencePanel.tsx` with props `{ contactId: number }`
    - Fetch `GET /api/v1/contacts/{contactId}/intelligence` via `apiClient`
    - Render three structured cards: ContactPersona, ContactTalkSpecs, EmotionalBaseline
    - Each field shows confidence badge and `last_validated_at`; evidence links open a
      `NxSourceCitation` popover
    - Empty state: `NxEmptyState` with "Run AI Analysis" `NxActionButton`
    - Add `intelligence` tab to Contact360
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [x] 9.5 Create `NxAnalysisFindingsReview` component and wire into AI Analysis tab
    - Create `components/NxAnalysisFindingsReview.tsx` with props
      `{ contactId: number; runId: number; onClose: () => void }`
    - Fetch `GET /api/v1/contacts/{contactId}/analysis-runs/{runId}` via `apiClient`
    - Render each finding with type badge, content summary, confidence (`NxConfidenceBadge`),
      source evidence citations (`NxSourceCitation`), and three action buttons:
      Apply → `POST /analysis-runs/{run}/apply`; Rollback → `POST /analysis-runs/{run}/rollback`;
      Ignore → local state only
    - Wire into Contact360 AI Analysis tab: when a run reaches `status = 'completed'`,
      automatically render this component
    - _Requirements: 8.4, 8.5, 8.6_

  - [ ]* 9.6 Write component tests for new Contact360 tab components
    - `NxIntelligencePanel`: assert persona, talkSpecs, emotionalBaseline sections render;
      assert empty state when data is null (Property 2 — all tab values trigger data load)
    - `NxAnalysisFindingsReview`: assert per-finding Apply/Ignore/Rollback controls present
    - Assert `NxConversationsViewer` renders group-by controls and calls `apiClient`
    - _Requirements: 7.3, 8.6, 14.1, 14.5_

- [x] 10. Phase 7 — Frontend: Contact Cards, Topbar, and Import Modal

  - [x] 10.1 Update `NxContactCard3D` with all required fields and 7 quick actions
    - Extended props to include: `gender`, `tags`, `emotional_baseline`, `conflict_count`, `last_interaction_at`
    - Added all 7 quick action callback props and rendered icon buttons in collapsible hover row
    - All data fields rendered when present including whatsapp_number, contact_type, gender, reply mode, etc.
    - _Requirements: 15.1, 15.2_

  - [x] 10.2 Wire `ContactHubTopbarControls` Maintain button to global maintenance modal
    - `isMaintenanceModalOpen` state added to `app/contacts/page.tsx`
    - `NxMemoryMaintenanceModal` rendered with `scope="global"` on contacts page
    - _Requirements: 9.1, 15.3_

  - [x] 10.3 Wire `ContactHubTopbarControls` Import button to `NxImportModal`
    - `isImportModalOpen` state added to `app/contacts/page.tsx`
    - `NxImportModal` rendered with full source selector and file upload flow
    - _Requirements: 15.6, F-M-08_

  - [x] 10.4 Extend queue/progress indicator to cover import and maintenance jobs
    - `ContactHubTopbarControls` extended with `active_import_jobs` and `active_maintenance_jobs` stat fields
    - Three distinct indicators rendered for analysis, import, and maintenance job counts
    - _Requirements: 15.5_

  - [ ]* 10.5 Write component tests for contact card and topbar
    - `NxContactCard3D`: assert all 13 required fields render when populated (Property 22);
      assert all 7 quick action buttons present
    - `ContactHubTopbarControls`: assert Maintain button opens modal (not toast); assert
      Import button opens `NxImportModal`
    - _Requirements: 15.1, 15.2, 15.3, 15.6_

- [x] 11. Phase 8 — Frontend: Topics Evidence and Relationship Graph

  - [x] 11.1 Update `NxTopicsViewer` to expand topics with evidence citations
    - `NxTopicsViewer` already calls `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions`
      on expand and renders each mention as `NxSourceCitation` with message excerpt, sender, timestamp
    - Confidence badge displayed in topic header when `analysis_run_id` present
    - _Requirements: 16.2, 16.4_

  - [x] 11.2 Install `react-force-graph-2d` and create `NxRelationshipGraph` component
    - `react-force-graph-2d` installed via npm
    - `components/NxRelationshipGraph.tsx` created using dynamic import with `ssr: false`
    - Props: `{ contactId, contactName, relationships, onNodeClick }` fully implemented
    - Edges colored by relationship type (work=blue, family=pink, social=green, vendor=amber, partner=purple)
    - Edge width scaled by confidence score; directional particles added for depth
    - Empty state rendered when fewer than 2 relationships
    - _Requirements: 17.1, 17.2, 17.3, 17.4_

  - [x] 11.3 Add graph view toggle to Relationships tab in Contact360
    - `[List view] | [Graph view]` segmented toggle added to Relationships tab header
    - Graph view renders `NxRelationshipGraph` with the already-loaded relationships data
    - List view renders existing flat list
    - _Requirements: 17.1_

  - [ ]* 11.4 Write component tests for topics evidence and relationship graph
    - `NxTopicsViewer`: expanding a topic calls the mentions endpoint; renders correct
      number of citations (Property 23)
    - `NxRelationshipGraph`: renders graph with 2+ relationships; shows empty state with
      < 2 relationships; graph view toggle switches between views
    - _Requirements: 16.2, 17.1, 17.4_

- [ ] 12. Checkpoint — Frontend Phases 6–8 complete
  - Ensure all frontend tests pass (`npm run test -- --run`). Verify the Next.js build
    compiles without TypeScript errors (`next build`).
  - Ask the user if questions arise before proceeding to Phase 9.

- [ ] 13. Phase 9 — Property-Based Tests: Backend (Pest)

  - [ ] 13.1 Write PBT for import pipeline properties (Properties 5–9)
    - **Property 5: Import is always asynchronous**
    - Generate 100+ random valid WhatsApp/Facebook payloads; assert each returns HTTP 202
      with `batch_id` and `status=queued`; assert response time < 2s
    - **Validates: Requirements 6.1, 6.2**

  - [ ] 13.2 Write PBT for preview and deduplication properties (Properties 6–7)
    - **Property 6: Preview never persists data**
    - Generate 100+ random import content strings; assert `contact_messages` count
      is identical before and after each preview call
    - **Property 7: Deduplication idempotence**
    - Generate 100+ random import contents; import each twice; assert final message
      count equals single-import count
    - **Validates: Requirements 6.3, 6.4**

  - [ ] 13.3 Write PBT for rollback and error-row properties (Properties 8–9)
    - **Property 8: Rollback removes all batch messages**
    - For 100+ committed batches, assert that after rollback the `contact_messages`
      count for that batch is exactly zero
    - **Property 9: Error rows recorded without aborting import**
    - Generate 100+ import contents with varying numbers of malformed rows M out of N;
      assert `imported + failed == total` and error_report has exactly M entries
    - **Validates: Requirements 6.5, 6.7**

  - [ ] 13.4 Write PBT for analysis run properties (Properties 3–4, 11–13)
    - **Property 3: Analysis findings always carry evidence**
    - For 100+ successful analysis runs (using fake AI gateway), assert every finding
      has non-null, non-empty `evidence_references` and `source_message_ids`
    - **Validates: Requirements 5.1, 8.3**
    - **Property 4: AI failure produces no findings**
    - For 100+ runs where AI gateway throws, assert finding count == 0 and
      `run.status == 'failed'`
    - **Validates: Requirements 5.2**
    - **Property 11: Analysis run creation always returns `status=queued`**
    - For 100+ valid POST requests, assert response contains `status=queued` and exactly
      one `AnalyzeContactMessagesJob` dispatched
    - **Validates: Requirements 8.1**
    - **Property 12: Batch analysis dispatches one job per contact**
    - For 100+ arrays of N contact IDs, assert exactly N jobs dispatched
    - **Validates: Requirements 8.8**

  - [ ] 13.5 Write PBT for cache, maintenance, and stats properties (Properties 14–15, 24–28)
    - **Property 14: Maintenance dry-run writes nothing** — 100+ dry-run calls; assert
      all table counts unchanged (Req 9.2)
    - **Property 15: Maintenance run history is contact-scoped** — assert all returned
      runs have matching `contact_id` (Req 9.7)
    - **Property 24: Cache keys use only whitelisted parameters** — for 100+ request
      param sets differing only in non-whitelisted keys, assert identical cache key
      (Req 18.1)
    - **Property 25: Import commit invalidates message cache** — assert cache miss after
      batch commit (Req 18.2)
    - **Property 26: Maintenance pipeline uses transactions** — assert no partial writes
      on exception (Req 18.3)
    - **Property 27: Failed jobs update status and write audit events** — assert run
      status = `failed` and audit event exists after job exhausts retries (Req 18.4)
    - **Property 28: StatsService counts reflect DB state** — for 100+ DB states with
      random failed batch counts, assert `getStats()` returns exact DB counts (Req 18.8)

  - [ ] 13.6 Write PBT for privacy, intelligence, and policy properties (Properties 13, 16–23)
    - **Property 13: Applied run sets status and updates profile** — for 100+ completed
      runs with findings, assert `run.status == 'applied'` and contact record updated
      (Req 8.4)
    - **Property 16: Routes return 403 for unauthorized users** — for 100+ random
      role/endpoint combinations lacking required permission, assert HTTP 403 (Req 12.2)
    - **Property 17: Export is always asynchronous** — assert `ExportContactDataJob`
      dispatched and response received before archive built (Req 13.1)
    - **Property 18: Erase is always asynchronous** — assert `EraseContactDataJob`
      dispatched before deletion occurs (Req 13.3)
    - **Property 19: Erase removes data and leaves tombstone** — after erase job:
      messages==0, memories==0, audit tombstone exists (Req 13.4)
    - **Property 20: Privacy jobs write audit events** — success and failure both create
      audit event (Req 13.5)
    - **Property 21: Intelligence endpoint returns structured objects** — for 100+
      contacts with findings, assert response has `persona`, `talkSpecs`,
      `emotionalBaseline` each with `confidence`, `evidence_references`,
      `last_validated_at` (Req 14.6)

- [ ] 14. Phase 9 — Property-Based Tests: Frontend (fast-check)

  - [ ] 14.1 Write PBT for `NxAiAnalysisModal` checkbox payload (Property 1)
    - Install `fast-check` if not already present in `Nexus-Frontend/package.json`
    - **Property 1: Analysis options payload mirrors checkbox state**
    - Use `fc.record({ extract_topics: fc.boolean(), infer_persona: fc.boolean(),
      detect_emotion: fc.boolean(), suggest_rules: fc.boolean() })` with 100 runs
    - Assert the payload sent to `apiClient.post` exactly matches the checkbox state
    - **Validates: Requirements 3.3**

  - [ ] 14.2 Write PBT for Contact360 tab data-loading coverage (Property 2)
    - **Property 2: All valid tab values trigger their data-loading function**
    - Use `fc.constantFrom(...validTabValues)` with 100 runs; for each tab value, assert
      the corresponding data-loading function is invoked exactly once in the `useEffect`
    - **Validates: Requirements 4.1, 4.2, 4.3**

  - [ ] 14.3 Write PBT for message filter parameter propagation (Property 10)
    - **Property 10: Message filter params propagate to API**
    - Use `fc.record({ search: fc.string(), date_from: fc.option(fc.string()),
      date_to: fc.option(fc.string()) })` with 100 runs
    - Assert `apiClient` request params contain exactly the entered filters, nothing more
    - **Validates: Requirements 7.4, 7.5**

  - [ ] 14.4 Write PBT for analysis run queue dispatching (Properties 11–12)
    - **Property 11: Analysis run creation returns `status=queued`**
    - Mock `apiClient.post`; for 100+ random valid payloads, assert response `status ==
      'queued'`
    - **Validates: Requirements 8.1**
    - **Property 12: Batch analysis dispatches one job per contact**
    - Use `fc.array(fc.integer({ min: 1 }), { minLength: 1, maxLength: 50 })` with 100
      runs; assert the number of dispatched job calls equals the array length
    - **Validates: Requirements 8.8**

  - [ ] 14.5 Write PBT for contact card field rendering (Property 22)
    - **Property 22: Contact card renders all fields when data is present**
    - Generate 100+ fully-populated contact objects using `fc.record(...)` with all
      required fields; assert all 13 required fields are present in the rendered output
    - **Validates: Requirements 15.1**

  - [ ] 14.6 Write PBT for topics evidence citations count (Property 23)
    - **Property 23: Topic mentions fully displayed on expand**
    - For 100+ topics with N `ContactTopicMention` records (using `fc.array` with random
      length), assert that expanding the topic renders exactly N source message citations
    - **Validates: Requirements 16.2**

- [ ] 15. Final Checkpoint — All tests pass
  - Run full backend test suite (`php artisan test`). Run full frontend test suite
    (`npm run test -- --run`). Confirm no TypeScript errors (`next build`).
  - Ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery.
- Phase 1 must complete before Phase 2; Phase 2 before Phase 3; Phase 3 before Phase 4.
  Frontend phases (6–8) can proceed in parallel with backend Phases 4–5 once Phase 1 and
  Phase 2 backend work is merged.
- All backend jobs must implement `failed(Throwable $e)` — this is a hard production
  requirement (Property 27).
- All frontend components use `apiClient` exclusively — no raw `fetch()`, no hardcoded
  hostnames (Property 10 validates this for message filters).
- Property-based tests in the backend use Pest's dataset generator pattern with Faker
  and custom generators; minimum 100 iterations per property.
- Property-based tests in the frontend use `fast-check`; minimum 100 runs per property.
- Backend migrations should be created in order: `error_message`, then `evidence columns`,
  then `maintenance progress columns`. Run `php artisan migrate` after task 1.6.
- The `react-force-graph-2d` package uses a dynamic import with `ssr: false` to avoid
  Next.js SSR incompatibility (task 11.2).

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "2.1", "2.2", "2.3", "2.4", "2.5"]
    },
    {
      "id": 1,
      "tasks": ["1.6", "2.6"]
    },
    {
      "id": 2,
      "tasks": ["1.7", "4.1", "4.2", "5.3"]
    },
    {
      "id": 3,
      "tasks": ["4.3", "5.1", "5.2", "5.4", "6.5"]
    },
    {
      "id": 4,
      "tasks": ["4.4", "5.5", "6.1", "6.4"]
    },
    {
      "id": 5,
      "tasks": ["4.5", "6.2", "6.3", "8.1", "8.4", "9.1"]
    },
    {
      "id": 6,
      "tasks": ["6.6", "8.2", "8.3", "9.2", "9.3", "9.4", "9.5"]
    },
    {
      "id": 7,
      "tasks": ["8.5", "9.6", "10.1", "11.1"]
    },
    {
      "id": 8,
      "tasks": ["10.2", "10.3", "10.4", "11.2"]
    },
    {
      "id": 9,
      "tasks": ["10.5", "11.3"]
    },
    {
      "id": 10,
      "tasks": ["11.4", "13.1", "13.2", "13.3", "14.1", "14.2", "14.3"]
    },
    {
      "id": 11,
      "tasks": ["13.4", "13.5", "13.6", "14.4", "14.5", "14.6"]
    }
  ]
}
```
