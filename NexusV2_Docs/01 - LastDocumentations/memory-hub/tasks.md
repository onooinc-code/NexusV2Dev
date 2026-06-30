# Implementation Plan: MemoryHub

## Overview

This plan completes the Nexus MemoryHub from its current skeleton state to a fully
production-ready feature set across two codebases:

- **Nexus-backend** — Laravel 11, PHP 8.2 (`Nexus-backend/`)
- **Nexus-Frontend** — Next.js 14, TypeScript (`Nexus-Frontend/`)

Work is sequenced as:
- Phase 1 — Database schema migrations
- Phase 2 — Backend service layer completions
- Phase 3 — MemoryController API surface
- Phase 4 — Async jobs and extraction pipeline
- Phase 5 — Confidence scoring, decay, and consolidation
- Phase 6 — Version history, rollback, and GDPR erasure
- Phase 7 — Domain events and hub integration
- Phase 8 — Frontend: Memory Bank Explorer rewire
- Phase 9 — Frontend: Structured & Graph tabs + advanced UI
- Phase 10 — Frontend: Contact Memory Panel

---

## Tasks

- [ ] 1. Phase 1 — Database Schema Migrations

  - [ ] 1.1 Add source_type and is_extracted columns to memories table
    - Create migration `add_extraction_fields_to_memories_table`
    - Add `source_type VARCHAR(50) NULLABLE` after `source` column
    - Add `is_extracted BOOLEAN DEFAULT FALSE` after `source_type`
    - Add index on `(contact_id, is_extracted)` to support dedup gate queries
    - _Requirements: 6.7_

  - [ ] 1.2 Add confidence, status, last_reinforced_at, and softDeletes to structured_memories
    - Create migration `add_confidence_to_structured_memories`
    - Add `confidence DECIMAL(5,2) DEFAULT 0.80` after `metadata` column
    - Add `status VARCHAR(30) DEFAULT 'active'` after `confidence`
    - Add `last_reinforced_at TIMESTAMP NULLABLE` after `status`
    - Add `deleted_at TIMESTAMP NULLABLE` for soft deletes
    - Add composite indexes: `(contact_id, confidence)` and `(contact_id, fact_type, status)`
    - _Requirements: 7.1, 7.4, 7.5_

  - [ ] 1.3 Create contact_memory_versions table
    - Create migration `create_contact_memory_versions_table`
    - Columns: `id`, `memory_id BIGINT UNSIGNED`, `memory_type VARCHAR(50) DEFAULT 'structured'`,
      `contact_id BIGINT UNSIGNED NULLABLE`, `version INT DEFAULT 1`,
      `previous_content JSON NULLABLE`, `new_content JSON NULLABLE`, `diff JSON NULLABLE`,
      `old_confidence DECIMAL(5,2) NULLABLE`, `new_confidence DECIMAL(5,2) NULLABLE`,
      `source VARCHAR(50) NULLABLE`, `actor_id BIGINT UNSIGNED NULLABLE`, `created_at TIMESTAMP`
    - Add indexes: `(memory_id, memory_type)`, `(contact_id, created_at)`
    - _Requirements: 10.1, 7.6_

  - [ ]* 1.4 Verify migrations apply cleanly and run schema tests
    - Run `php artisan migrate` and assert no errors
    - Write a schema assertion test: assert `structured_memories` has `confidence` column
      with default 0.80; assert `contact_memory_versions` table exists with all required columns
    - _Requirements: 7.1, 10.1_

- [ ] 2. Phase 2 — Backend Service Layer Completions

  - [ ] 2.1 Add paginate() method to EpisodicMemoryService
    - In `app/Services/Memory/EpisodicMemoryService.php`, add `paginate(int $contactId = null, int $perPage = 25, string $sort = 'created_at'): array`
    - Returns standard Laravel paginator array with `data`, `current_page`, `total`, `per_page`, `last_page`
    - When `contact_id` is null, returns all episodic memories across contacts
    - Excludes records where `expires_at` is not null and in the past
    - _Requirements: 1.1, 1.5_

  - [ ] 2.2 Add paginate() method to StructuredMemoryService plus confidence methods
    - Add `paginate(int $contactId = null, int $perPage = 25, string $sort = 'confidence'): array`
    - By default excludes `status = 'expired'` records; include them only when `include_expired=true` flag is passed
    - Add `reinforceConfidence(int $id): void` — increments confidence by 0.05 (capped 1.00), updates `last_reinforced_at`, writes a `contact_memory_versions` row
    - Add `applyDecay(int $daysThreshold = 30, float $decayAmount = 0.05): int` — chunks 200, updates confidence + status, writes version rows, returns count affected
    - Add `recordVersion(int $memoryId, float $oldConf, float $newConf, string $source, ?array $previousContent = null, ?array $newContent = null): void` — inserts into `contact_memory_versions`
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 1.8_

  - [ ] 2.3 Add paginate() and deleteNamespace() to SemanticMemoryService
    - Add `paginate(int $contactId = null, int $perPage = 25): array` — queries Pinecone metadata for a contact's vectors and returns paginated list
    - Add `deleteNamespace(string $contactId): void` — deletes the entire Pinecone namespace for a contact (used by GDPR erasure)
    - _Requirements: 1.1, 13.2_

  - [ ] 2.4 Add paginate() and path-finding to GraphMemoryService
    - Add `paginate(int $contactId = null, int $perPage = 25): array` — returns paginated graph nodes for a related contact
    - Add `getEdges(int $nodeId): array` — returns all inbound and outbound edges for a node with their `label` and related node data
    - Add `shortestPath(int $fromNodeId, int $toNodeId, int $maxDepth = 10): array` — BFS traversal returning ordered array of node ids; returns empty array if no path within depth
    - _Requirements: 11.3, 11.4, 11.7_

  - [ ] 2.5 Rewrite MemoryMaintenanceService::runConsolidation()
    - Replace naive string similarity with AiModelsHub call to `identifyMemoryConflicts(array $memories): array`
    - Implement `mergeRecords(int $keepId, int $removeId): void` — merges data, retains higher confidence, soft-deletes redundant record, dispatches VectorizeMemoryJob for kept record
    - Implement `supersede(int $keepId, int $removeId): void` — marks older record `superseded` in metadata, soft-deletes it
    - Implement `runDecay(): int` — calls `StructuredMemoryService::applyDecay()` and returns count
    - Only processes records with `updated_at < now()-24h` (Req 8.7)
    - Logs every consolidation action to LogsHub
    - _Requirements: 8.1, 8.2, 8.3, 8.6, 8.7_

  - [ ] 2.6 Implement MemorySummaryService::summarize()
    - In `app/Services/Memory/MemorySummaryService.php`, implement `summarize(int $contactId): ?int`
    - Count episodic memories for contact in last 30 days; if count > 50, call AiModelsHub with all episodic content to produce a summary paragraph
    - Store summary as structured memory with `fact_type = 'episode_summary'`
    - Dispatch VectorizeMemoryJob for the new summary record
    - Return the new structured memory id, or null if no summary was needed
    - _Requirements: 8.4, 8.5_

  - [ ] 2.7 Add listPaginated() to MemoryRouter
    - Add `listPaginated(?string $type, ?int $contactId, int $perPage = 25, string $sort = 'created_at'): array`
    - Fans out to each type-specific `paginate()` method for the requested type(s)
    - Merges results and returns a combined pagination envelope
    - Excludes `working` and `semantic` types from the "all types" default listing; they are only returned when explicitly filtered
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ]* 2.8 Write unit tests for service layer additions
    - `StructuredMemoryServiceTest`: assert `reinforceConfidence` caps at 1.00; assert `applyDecay` sets status to `low_confidence` at 0.15 and `expired` at 0.03; assert version row is created on each confidence change
    - `MemoryMaintenanceServiceTest`: assert `runConsolidation` does not touch records updated within 24h; assert soft-delete on merged/superseded records
    - `MemorySummaryServiceTest`: assert summary is not created when episodic count ≤ 50; assert summary is stored with correct `fact_type`
    - `GraphMemoryServiceTest`: assert `shortestPath` returns empty array when no path exists within maxDepth
    - _Requirements: 7.1–7.6, 8.1–8.7_

- [ ] 3. Phase 3 — MemoryController API Surface

  - [ ] 3.1 Implement MemoryController::index() — unified paginated listing
    - Validate query params: `type` (optional, enum), `contact_id` (optional, exists:contacts,id),
      `per_page` (optional, 1–100), `sort` (optional, in:confidence,created_at), `cursor` (optional)
    - Call `MemoryRouter::listPaginated()` and return standard pagination envelope
    - Return 422 if `type` is not one of the five valid values
    - Respond within 500ms target (add query-time logging via LogsHub)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_

  - [ ] 3.2 Implement MemoryController::contactMemories()
    - Route: `GET /api/v1/contacts/{id}/memories`
    - Return 404 if contact does not exist
    - Call each type-specific service to retrieve memories for the contact
    - Group results by type in the response body
    - Include a `counts` summary object: `{ episodic: N, semantic: N, structured: N, graph: N, working: N }`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ] 3.3 Complete MemoryController::show() — type-aware single record retrieval
    - Require `type` query param; return 422 if missing
    - Dispatch to the correct type-specific service based on `type`
    - For working memory: return 404 with `reason: expired` if the key has expired in Redis
    - _Requirements: 3.2, 12.3_

  - [ ] 3.4 Complete MemoryController::store() — add validation and SyncMemoryJob dispatch
    - Fix existing store() to add type-specific required field validation returning 422 on missing fields
    - After successful structured memory creation, dispatch `SyncMemoryJob` within 1 second
    - Return 201 with new record `id` and `type`; log audit entry to LogsHub
    - _Requirements: 3.1, 3.5, 3.7, 3.8_

  - [ ] 3.5 Complete MemoryController::update() — add version recording for structured
    - When updating a structured memory, call `StructuredMemoryService::recordVersion()` before updating
    - For working memory updates, reset TTL to the provided value or default
    - Return 501 for semantic and graph updates (document as not supported in this release)
    - Log audit entry to LogsHub on successful update
    - _Requirements: 3.3, 3.7, 10.1, 12.6_

  - [ ] 3.6 Complete MemoryController::destroy() — type-aware deletion
    - Require `type` query param; return 422 if missing
    - Dispatch to the correct type-specific delete method
    - For graph type: call `GraphMemoryService` which cascades edges in a transaction
    - Return 404 if record not found; log audit entry to LogsHub on success
    - _Requirements: 3.4, 3.6, 3.7, 11.5_

  - [ ] 3.7 Implement MemoryController::search() — semantic search with MySQL fallback
    - Validate: `query` required (return 422 if empty), `contact_id` optional, `types` optional array,
      `limit` optional 1–100
    - Call `SemanticMemoryService::retrieve()` with the query embedding via AiModelsHub
    - Scope to contact's Pinecone namespace when `contact_id` is provided
    - If Pinecone is unavailable, fall back to MySQL LIKE/FULLTEXT search and include `fallback: true` in meta
    - Return results sorted by `score` descending; include `score` on each item
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

  - [ ] 3.8 Implement MemoryController::stats()
    - Route: `GET /api/v1/memories/stats`
    - Accept optional `contact_id` query param to scope counts
    - Return: `total`, `by_type` (counts per type), `low_confidence` count, `expired` count,
      `last_maintenance_run_at` (from settings table), `maintenance_status` (idle/running/scheduled)
    - Cache response in Redis for 60 seconds; invalidate cache key on any memory write operation
    - _Requirements: 9.4, 9.5, 17.5_

  - [ ] 3.9 Implement graph endpoints in MemoryController
    - `POST /api/v1/memories/graph/edges` → validate `from_node_id`, `to_node_id`, `label`; return 422 if either node does not exist; call `GraphMemoryService`
    - `GET /api/v1/memories/graph/nodes` → accept `related_id` and `related_type` params; return paginated nodes with edge counts
    - `GET /api/v1/memories/graph/edges/{nodeId}` → call `GraphMemoryService::getEdges()`
    - `GET /api/v1/memories/graph/path` → accept `from_node_id`, `to_node_id`; call `GraphMemoryService::shortestPath()`; return 404 if no path found
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.6, 11.7_

  - [ ] 3.10 Implement working memory session endpoints
    - `GET /api/v1/memories/working/session/{session_key}` → call `WorkingMemoryService` to list all Redis keys matching the prefix pattern
    - `DELETE /api/v1/memories/working/flush` → validate `session_key` param; flush matching Redis keys; return count of deleted keys
    - _Requirements: 12.4, 12.5_

  - [ ] 3.11 Implement maintenance and version endpoints
    - `POST /api/v1/memories/maintenance` → validate optional `contact_id`; if contact is provided check for already-running job (return 409 if so); dispatch `RunContactMemoryMaintenanceJob`; return 202 with job id
    - `GET /api/v1/memories/maintenance/preview` → return estimated impact counts without modifying data
    - `GET /api/v1/memories/{id}/versions` → return version history from `contact_memory_versions` ordered by version desc
    - `POST /api/v1/memories/{id}/rollback` → validate `version` param; restore content from version row; create new version entry with `source: rollback`; return 404 if version not found
    - `DELETE /api/v1/contacts/{id}/memories` → dispatch `EraseContactMemoryJob`; return 202 with job id; return 404 if contact not found
    - _Requirements: 9.1, 9.2, 9.3, 9.8, 10.2, 10.3, 10.4, 10.5, 13.1, 13.6_

  - [ ]* 3.12 Write feature tests for MemoryController API surface
    - `MemoryListingTest`: assert GET /memories returns paginated envelope; assert type filter works; assert contact_id filter works; assert 422 on invalid type
    - `MemoryContactTest`: assert GET /contacts/{id}/memories returns grouped response with counts; assert 404 for non-existent contact
    - `MemorySearchTest`: assert empty query returns 422; assert results include score field sorted desc; assert fallback:true when Pinecone is mocked as unavailable
    - `MemoryStatsTest`: assert stats response includes all required keys; assert contact_id scopes counts
    - `MemoryMaintenanceTest`: assert 409 when job already running for same contact; assert 202 otherwise
    - `MemoryVersionTest`: assert version row created on update; assert rollback restores content and creates new version; assert 404 on non-existent version
    - _Requirements: 1.1–1.7, 2.1–2.5, 3.5–3.7, 4.8, 9.8, 10.5_

- [ ] 4. Phase 4 — Async Jobs and Extraction Pipeline

  - [ ] 4.1 Fix ExtractMemoryJob to use AiModelsHub and write structured + episodic records
    - Replace the current regex-based extraction logic with an AiModelsHub call using an extraction prompt
    - Write extracted facts as structured memory records in `structured_memories` table (not `memories`) with `conversation_id` in metadata
    - Write extracted events as episodic memory records in `memories` with `source = 'extraction'` and `is_extracted = true`
    - Implement idempotency check: before dispatching, query `memories` for any record with `conversation_id = X` and `is_extracted = true`; skip if found
    - On no extractable facts: log `no_facts_extracted` info to LogsHub and complete without error
    - On AiModelsHub error: retry up to 3 times with exponential backoff; log final failure with conversation_id
    - _Requirements: 6.1, 6.2, 6.3, 6.5, 6.6, 6.7_

  - [ ] 4.2 Fix VectorizeMemoryJob to dispatch SaveToPineconeJob with full metadata
    - After generating the embedding via AiModelsHub gateway, dispatch `SaveToPineconeJob` passing `contact_id`, `memory_id`, `memory_type`, and `created_at` as metadata fields
    - Retry up to 3 times with exponential backoff on AiModelsHub embedding failure
    - Log error to LogsHub on final failure with memory_id
    - _Requirements: 5.2, 5.3, 5.5_

  - [ ] 4.3 Fix SaveToPineconeJob to upsert into contact namespace
    - Update `SaveToPineconeJob` to call `SemanticMemoryService::store()` with contact_id as the Pinecone namespace key
    - Retry up to 3 times with exponential backoff on Pinecone failure
    - Log error to LogsHub on final failure
    - _Requirements: 5.4, 5.6_

  - [ ] 4.4 Create EraseContactMemoryJob
    - Create `app/Jobs/EraseContactMemoryJob.php` dispatched to `memory-maintenance` queue
    - Delete all `memories` records for contact; delete all `structured_memories` records; delete all `contact_memory_versions` records; cascade-delete `graph_nodes` (edges cascade via FK)
    - Flush all Redis keys matching `working_memory:contact_{id}:*` pattern
    - Call `SemanticMemoryService::deleteNamespace()` to erase Pinecone namespace
    - Write `memory_erased` audit entry to LogsHub with per-type deletion counts
    - On partial failure: log partial erasure details; mark job as `failed`
    - _Requirements: 13.2, 13.3, 13.4, 13.5_

  - [ ] 4.5 Update RunContactMemoryMaintenanceJob to run full pipeline
    - After running `MemoryMaintenanceService::runMaintenance()`, also call `MemoryMaintenanceService::runDecay()` and `MemorySummaryService::summarize()`
    - On completion: upsert `memory.last_maintenance_run_at` setting in `settings` table via `SettingCacheService`
    - Log result summary (merged, pruned, decayed, summarized) to LogsHub
    - Dispatch `MemoryMaintenanceCompleted` event after completion
    - _Requirements: 9.6, 9.7_

  - [ ]* 4.6 Write job tests
    - `ExtractMemoryJobTest`: assert AiModelsHub is called (not regex); assert structured + episodic records created; assert idempotency prevents re-extraction; assert no error on empty extraction
    - `VectorizeMemoryJobTest`: assert retries 3 times on gateway failure; assert SaveToPineconeJob dispatched with contact_id metadata
    - `EraseContactMemoryJobTest`: assert all memory types deleted; assert Redis keys flushed; assert audit log written; assert Pinecone namespace deleted
    - _Requirements: 5.5, 5.6, 6.6, 6.7, 13.2–13.5_

- [ ] 5. Phase 5 — Confidence Scoring, Decay, and Consolidation Scheduling

  - [ ] 5.1 Wire confidence assignment on structured memory creation
    - In `MemoryController::store()`, when creating a structured memory, accept optional `confidence` param (float 0.00–1.00); default to 0.80
    - Pass confidence value to `StructuredMemoryService::store()` and persist it on the database row
    - _Requirements: 7.1_

  - [ ] 5.2 Wire confidence reinforcement on extraction
    - In `ExtractMemoryJob`, after writing a structured memory, check if a record with the same `fact_type` and `contact_id` already exists
    - If it does, call `StructuredMemoryService::reinforceConfidence()` instead of creating a duplicate
    - _Requirements: 7.2_

  - [ ] 5.3 Wire decay exclusion from default retrieval
    - In `StructuredMemoryService::paginate()`, by default exclude records with `status IN ('low_confidence', 'expired')`
    - Accept an optional `include_low_confidence` boolean param (default false) to include `low_confidence` records
    - The listing API (`GET /api/v1/memories`) SHALL pass `include_low_confidence=true` only when the user explicitly requests it via a query param
    - _Requirements: 7.4, 7.5_

  - [ ] 5.4 Schedule RunContactMemoryMaintenanceJob via Laravel scheduler
    - In `app/Console/Kernel.php` (or `routes/console.php`), register `RunContactMemoryMaintenanceJob` dispatch at a configurable interval
    - Read interval from `config('memory.maintenance_interval_hours')` defaulting to 24
    - Ensure the scheduler entry is covered by the `memory.last_maintenance_run_at` setting check
    - _Requirements: 9.6_

  - [ ]* 5.5 Write confidence and decay integration tests
    - Assert newly created structured memory has `confidence = 0.80` by default
    - Assert `reinforceConfidence` caps at 1.00 and creates a version row
    - Assert `applyDecay` sets `status = 'low_confidence'` when confidence hits 0.15
    - Assert expired records are excluded from default listing; included when explicitly requested
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.7_

- [ ] 6. Phase 6 — Domain Events

  - [ ] 6.1 Create MemoryHub domain event classes
    - Create `app/Events/MemoryCreated.php` with payload: `memory_id`, `contact_id`, `type`, `fact_type` (nullable), `confidence` (nullable), `trace_id`
    - Create `app/Events/MemoryConfidenceChanged.php` with payload: `memory_id`, `contact_id`, `old_confidence`, `new_confidence`, `reason`, `trace_id`
    - Create `app/Events/MemoryDeleted.php` with payload: `memory_id`, `type`, `contact_id`, `trace_id`
    - Create `app/Events/MemoryBatchExtracted.php` with payload: `conversation_id`, `contact_id`, `count`, `trace_id`
    - Create `app/Events/MemoryMaintenanceCompleted.php` with payload: `contact_id` (nullable), `merged`, `pruned`, `decayed`, `trace_id`
    - All events conform to standard Nexus event envelope schema with `id`, `type`, `version`, `timestamp`, `source`, `payload`, `metadata`
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

  - [ ] 6.2 Dispatch events at service boundaries and register in EventServiceProvider
    - Dispatch `MemoryCreated` in `MemoryController::store()` after successful create
    - Dispatch `MemoryConfidenceChanged` in `StructuredMemoryService::reinforceConfidence()` and `applyDecay()`
    - Dispatch `MemoryDeleted` in `MemoryController::destroy()` after successful delete
    - Dispatch `MemoryBatchExtracted` at end of `ExtractMemoryJob::handle()` (replace existing `MemoriesExtracted` event)
    - Register `MemoryCreated` → `App\Listeners\NotifyAgentsOfNewMemory` in `EventServiceProvider::$listen`
    - _Requirements: 18.1–18.6_

  - [ ]* 6.3 Write event dispatch tests
    - Assert `MemoryCreated` is dispatched when POST /api/v1/memories succeeds
    - Assert `MemoryDeleted` is dispatched when DELETE /api/v1/memories/{id} succeeds
    - Assert `MemoryBatchExtracted` includes correct count after extraction job completes
    - Assert all events include `trace_id` in metadata
    - _Requirements: 18.1, 18.3, 18.4, 18.5_

- [ ] 7. Phase 7 — Checkpoint: Backend Complete

  - [ ] 7.1 Backend checkpoint — verify all tests pass and routes are registered
    - Run `php artisan migrate --force` to confirm all migrations apply cleanly
    - Run `php artisan route:list --path=memories` to verify all 20 routes are registered
    - Run `php artisan test --filter=Memory` to confirm all backend tests pass
    - Confirm `php -l` syntax check passes on all new/modified PHP files
    - _Requirements: all backend requirements_

- [ ] 8. Phase 8 — Frontend: Memory Bank Explorer Rewire

  - [ ] 8.1 Replace Zustand mock store with real apiClient calls in app/memory/page.tsx
    - Remove all `useAppStore` memory-related calls (`memories`, `hydrateMemories`, `createMemory`, `deleteMemory`, `resetAllMemories`)
    - Import `apiClient` from `@/lib/api/client`
    - On mount, call `GET /api/v1/memories` via `apiClient` to load memories into local React state
    - On tab change, call `GET /api/v1/memories?type={type}` to reload memories for the selected type
    - Call `GET /api/v1/memories/stats` on mount and store result for the stats sidebar
    - _Requirements: 14.1, 14.2_

  - [ ] 8.2 Wire search input to GET /api/v1/memories/search
    - Add a 300ms debounce to the search input using `useCallback` and `setTimeout`/`clearTimeout`
    - When query is non-empty, call `GET /api/v1/memories/search?query={q}&type={activeTab}` via `apiClient`
    - When query is cleared, revert to the paginated listing call
    - _Requirements: 14.3_

  - [ ] 8.3 Wire "Synthesize Knowledge" modal to POST /api/v1/memories
    - In `handleAddMemory`, replace the `createMemory()` store call with `apiClient.post('/memories', { ... })`
    - Accept optional `confidence` field in the form (default 0.80, visible only when type = 'structured')
    - On success: refresh the memory list and stats; dismiss modal
    - On error: display `NxErrorBanner` with the error message inside the modal; keep modal open
    - _Requirements: 14.6, 14.9_

  - [ ] 8.4 Wire delete icon to DELETE /api/v1/memories/{id}?type={type}
    - Replace `deleteMemory(mem.id)` store call with `apiClient.delete('/memories/${id}', { params: { type } })`
    - For structured or graph types: show a confirmation dialog before calling the API
    - On success: remove card from local state
    - On error: display inline error toast
    - _Requirements: 14.7_

  - [ ] 8.5 Wire "Flush Cache" button to DELETE /api/v1/memories/working/flush
    - Replace `resetAllMemories()` store call with `apiClient.delete('/memories/working/flush', { params: { session_key: 'all' } })`
    - On success: refresh the Working tab listing and show success toast
    - On error: show `NxErrorBanner`
    - _Requirements: 14.8_

  - [ ] 8.6 Wire stats sidebar to GET /api/v1/memories/stats
    - Pass real `{ semantic, episodic, working }` counts from the stats API response to `NxMemoryMiniGraph`
    - Pass real `totalCount` from the stats API response to `NxMemoryMiniGraph`
    - Derive `NxTagCloud` data from the current listing results' `metaTags` (existing logic kept)
    - Refresh stats after any create, delete, or flush operation
    - _Requirements: 14.5_

  - [ ] 8.7 Add responsive layout and error handling
    - On mobile (< lg breakpoint): tabs render as a horizontal scroll strip; stats panel moves below the memory grid
    - All API calls are wrapped in try/catch; errors render an `NxErrorBanner` with the error message and a retry button
    - Loading state: show `NxSkeleton` placeholders (3-column grid, same card dimensions) during initial fetch
    - _Requirements: 14.9, 14.10_

  - [ ]* 8.8 Write component tests for Memory Bank Explorer rewire
    - Assert page calls `GET /api/v1/memories` via `apiClient` on mount (no mock store)
    - Assert search input debounces and calls `/memories/search` with correct query
    - Assert "Synthesize Knowledge" submit calls `POST /api/v1/memories` and refreshes list on success
    - Assert delete calls `DELETE /api/v1/memories/{id}?type={type}` and removes card on success
    - Assert error banner renders when API returns 500
    - _Requirements: 14.1, 14.3, 14.6, 14.7, 14.9_

- [ ] 9. Phase 9 — Frontend: Structured & Graph Tabs + Advanced UI

  - [ ] 9.1 Create NxStructuredMemoryCard component
    - Create `components/NxStructuredMemoryCard.tsx`
    - Props: `memory: StructuredMemory`, `onDelete: (id: number) => void`, `onUpdate: (id: number) => void`
    - Display: `fact_type` as title, `data` JSON summary, `confidence` as percentage badge with color coding (green ≥ 70%, amber 20–69%, red < 20%), `created_at` relative timestamp, version count indicator
    - Expand/collapse toggle: on expand, call `GET /api/v1/memories/{id}/versions` and render `NxMemoryVersionPanel`
    - _Requirements: 15.1, 15.2, 15.7_

  - [ ] 9.2 Create NxMemoryVersionPanel component
    - Create `components/NxMemoryVersionPanel.tsx`
    - Props: `memoryId: number`, `versions: MemoryVersion[]`
    - Render each version as a row: version number, source, timestamp, diff summary (JSON diff), old/new confidence
    - Each row includes a "Rollback to this version" button that calls `POST /api/v1/memories/{id}/rollback` with the version number
    - On rollback success: call `onUpdate` callback to refresh the parent card
    - _Requirements: 15.2, 15.3_

  - [ ] 9.3 Wire Structured tab to use NxStructuredMemoryCard
    - In `app/memory/page.tsx`, when `activeTab === 'structured'`, render `NxStructuredMemoryCard` components instead of the generic memory card
    - Pass `onDelete` and `onUpdate` callbacks that refresh the listing after mutation
    - _Requirements: 15.1_

  - [ ] 9.4 Create NxGraphNodeCard component and wire Graph tab
    - Create `components/NxGraphNodeCard.tsx`
    - Props: `node: GraphNode`, `onDelete: (id: number) => void`
    - Display: `label`, `type` badge, `related_entity` (resolved from `related_id` + `related_type`), `edge_count`
    - On expand: call `GET /api/v1/memories/graph/edges/{node_id}` and render inbound/outbound edges as grouped lists
    - Include "Add Edge" button (per Req 15.6) that opens an edge creation modal calling `POST /api/v1/memories/graph/edges`
    - When `activeTab === 'graph'`, page calls `GET /api/v1/memories/graph/nodes` and renders `NxGraphNodeCard`
    - _Requirements: 15.4, 15.5, 15.6_

  - [ ] 9.5 Create NxMaintenanceModal component and wire into page header
    - Create `components/NxMaintenanceModal.tsx`
    - Props: `isOpen: boolean`, `onClose: () => void`
    - Render scope selector: All Contacts | Single Contact (with contact picker) | Dry Run
    - On Dry Run submit: call `GET /api/v1/memories/maintenance/preview` and display impact preview (merge_count, prune_count, decay_count)
    - On real submit: call `POST /api/v1/memories/maintenance` and show job progress indicator; poll `GET /api/v1/memories/stats` every 3 seconds until `maintenance_status === 'idle'`; show summary toast on completion
    - Add "Run Maintenance" button to Memory Bank Explorer header that opens this modal
    - _Requirements: 17.1, 17.2, 17.3, 17.4_

  - [ ]* 9.6 Write component tests for structured, graph, and maintenance UI
    - `NxStructuredMemoryCard`: assert confidence badge color is green/amber/red at correct thresholds; assert expand triggers versions API call
    - `NxMemoryVersionPanel`: assert rollback button calls correct API; assert rollback updates parent card
    - `NxGraphNodeCard`: assert edge expand calls correct API; assert Add Edge modal submits to correct endpoint
    - `NxMaintenanceModal`: assert dry-run shows preview without dispatching job; assert real submit shows spinner and polls stats
    - _Requirements: 15.1–15.7, 17.1–17.4_

- [ ] 10. Phase 10 — Frontend: Contact Memory Panel

  - [ ] 10.1 Create NxContactMemoryPanel component
    - Create `components/NxContactMemoryPanel.tsx`
    - Props: `contactId: number`, `contactName: string`
    - On mount: call `GET /api/v1/contacts/{contactId}/memories` via `apiClient`
    - Render four collapsible sections: Episodic, Semantic, Structured, Graph
    - Each section header shows a count badge from the `counts` response field
    - Loading state: `NxSkeleton` rows per section; error state: `NxErrorBanner` with retry
    - _Requirements: 16.1, 16.2_

  - [ ] 10.2 Implement Structured section with inline edit in Contact Memory Panel
    - Within the Structured section, each memory card shows `fact_type`, `confidence` badge (color-coded), and an inline edit (pencil) icon
    - Clicking the edit icon opens a pre-populated `NxModal` with the memory `data` as a JSON textarea and a `confidence` slider
    - On save: call `PUT /api/v1/memories/{id}` and refresh the contact memories list
    - _Requirements: 16.3_

  - [ ] 10.3 Implement Episodic section with relative timestamps in Contact Memory Panel
    - Within the Episodic section, render each record's `content` summary and `created_at` as a relative timestamp using `date-fns` `formatDistanceToNow()`
    - _Requirements: 16.4_

  - [ ] 10.4 Wire maintenance and erasure action buttons in Contact Memory Panel
    - Add "Run Maintenance" button: calls `POST /api/v1/memories/maintenance` with the `contactId`; shows spinner while job is in-flight (202 received); shows success toast with job id
    - Add "Erase All Memories" button (render only when user has admin role, check via auth store): shows a two-step confirmation dialog ("Type ERASE to confirm"); on confirm, calls `DELETE /api/v1/contacts/{contactId}/memories`; shows success toast; clears all section data locally
    - _Requirements: 16.5, 16.6_

  - [ ] 10.5 Add empty state with extraction CTA to Contact Memory Panel
    - If all section counts are zero after loading, render `NxEmptyState` with title "No memories yet" and a "Extract from Conversations" `NxActionButton`
    - The button calls `GET /api/v1/contacts/{contactId}/conversations?limit=1` to get the latest conversation id, then calls `POST /api/v1/memories/{conversationId}/index`
    - Show a spinner while the extraction job is queued; show success toast once 202 is received
    - _Requirements: 16.7_

  - [ ] 10.6 Add Memories tab to ContactHub Contact360 page
    - In `app/contacts/[id]/page.tsx`, add `memories` to the `tabs` array with a `Database` icon
    - Render `<NxContactMemoryPanel contactId={contact.id} contactName={contact.name} />` when `activeTab === 'memories'`
    - Add the tab switch case to the `activeTab` useEffect: no explicit data load call needed (panel loads itself on mount)
    - _Requirements: 16.1_

  - [ ]* 10.7 Write component tests for Contact Memory Panel
    - Assert panel calls `GET /api/v1/contacts/{id}/memories` on mount
    - Assert four sections render with correct count badges from API response
    - Assert edit modal pre-populates from memory data and calls PUT on save
    - Assert maintenance button calls POST with contact_id; shows spinner on 202
    - Assert empty state renders when all counts are 0; CTA calls extraction endpoint
    - _Requirements: 16.1–16.7_

- [ ] 11. Phase 11 — Final Checkpoint

  - [ ] 11.1 Frontend build verification and full test suite
    - Run `next build` in `Nexus-Frontend/` and confirm zero TypeScript errors
    - Run `npm run test -- --run` and confirm all component tests pass
    - Verify no raw `fetch()` calls, hardcoded URLs, or mock store usage remain in memory-related components
    - _Requirements: all frontend requirements_

  - [ ] 11.2 Backend full test suite and production readiness check
    - Run `php artisan test` in `Nexus-backend/` and confirm all tests pass (no regressions)
    - Verify `php artisan route:list --path=memories` shows all 20 endpoints
    - Confirm Horizon queues `memory-maintenance` and `default` are configured in `horizon.php`
    - Verify the scheduled task for `RunContactMemoryMaintenanceJob` appears in `php artisan schedule:list`
    - _Requirements: all backend requirements_
