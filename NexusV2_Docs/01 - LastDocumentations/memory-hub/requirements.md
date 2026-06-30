# Requirements Document — MemoryHub

## Introduction

MemoryHub is the centralized cognitive memory backbone of the Nexus AI platform. It provides
unified read, write, search, and maintenance operations across five distinct memory types:
**Working** (ephemeral Redis, session-scoped), **Episodic** (chronological events per contact,
MySQL), **Semantic** (Pinecone vector embeddings for meaning-based retrieval), **Structured**
(typed facts such as beliefs, preferences, and personality traits in MySQL), and **Graph**
(relationship nodes and directed edges in MySQL). Every AI response, agent decision, and
contact interaction in Nexus draws from MemoryHub — making it the single source of truth for
what the system knows about each person.

The backend already has skeleton services (`WorkingMemoryService`, `EpisodicMemoryService`,
`SemanticMemoryService`, `StructuredMemoryService`, `GraphMemoryService`, `MemoryRouter`,
`MemoryMaintenanceService`, `MemorySummaryService`) and a partially wired `MemoryController`.
The existing jobs (`ExtractMemoryJob`, `VectorizeMemoryJob`, `SaveToPineconeJob`,
`SyncMemoryJob`, `RunContactMemoryMaintenanceJob`) are present but incompletely implemented.
The frontend `app/memory/page.tsx` is wired to a Zustand mock store and is missing
structured/graph tabs, per-contact views, maintenance controls, and real API integration.

This spec drives the work to complete both layers end-to-end, wire them together with real
API calls, add confidence scoring and time-decay, implement the consolidation pipeline, expose
version history and rollback, and deliver a production-ready Memory Bank Explorer UI.

---

## Glossary

- **MemoryHub**: The Nexus hub that owns all memory storage, retrieval, search, consolidation, and maintenance operations.
- **Memory_Router**: The `MemoryRouter` service that dispatches memory operations to the correct type-specific service.
- **Working_Memory**: Ephemeral session-scoped memory stored in Redis with TTL, managed by `WorkingMemoryService`.
- **Episodic_Memory**: Chronological event and message records per contact, stored in the `memories` table, managed by `EpisodicMemoryService`.
- **Semantic_Memory**: Vector embeddings stored in Pinecone representing semantic meaning of content, managed by `SemanticMemoryService`.
- **Structured_Memory**: Typed facts (beliefs, preferences, personality traits, relationship data) stored in `structured_memories`, managed by `StructuredMemoryService`. Carries a `confidence` score subject to time-decay.
- **Graph_Memory**: Relationship graph nodes and directed edges stored in `graph_nodes` / `graph_edges`, managed by `GraphMemoryService`.
- **Confidence_Score**: A decimal `0.00–1.00` on each structured memory record representing its reliability; subject to time-decay.
- **Time_Decay**: Scheduled reduction of `confidence` for unreinforced structured memories.
- **Memory_Maintenance_Service**: The `MemoryMaintenanceService` responsible for deduplication, confidence decay, staleness pruning, and rebuild.
- **Memory_Summary_Service**: The `MemorySummaryService` responsible for summarizing and consolidating episodic clusters into higher-order structured facts.
- **Extraction_Pipeline**: The background job chain (`ExtractMemoryJob` → `VectorizeMemoryJob` → `SaveToPineconeJob`) that automatically extracts memories from conversation messages.
- **Consolidation_Pipeline**: The background pipeline that merges duplicates, recalculates confidence, and writes summaries.
- **ContactMemoryVersion**: The audit model (`contact_memory_versions` table) capturing every change to a structured memory record.
- **AiModelsHub**: The Nexus hub providing access to LLM and embedding model providers.
- **ContactsHub**: The Nexus hub managing contact profiles and per-contact data access.
- **ConversationHub**: The Nexus hub managing conversation sessions and message pipelines.
- **AgentsHub**: The Nexus hub managing AI agents that read and write memories during task execution.
- **LogsHub**: The Nexus hub providing centralized audit trail logging for all memory operations.
- **Pinecone**: The external vector database used for Semantic_Memory embeddings.
- **Horizon**: Laravel Horizon, the queue worker system that runs background memory jobs.
- **Memory_Bank_Explorer**: The Next.js page at `app/memory/page.tsx` upgraded to the full MemoryHub UI.
- **Contact_Memory_Panel**: A per-contact memory view accessible from ContactsHub showing all memory types for a single contact.
- **NxGlassCard**: The Nexus design system glass-morphism card component.
- **NxActionButton**: The Nexus design system button component.
- **NxModal**: The Nexus design system modal component.
- **NxInput / NxSelect**: The Nexus design system text input and select components.
- **apiClient**: The centralized Axios-based HTTP client at `@/lib/api/client` used by all frontend components.

---

## Requirements

### Requirement 1: Unified Memory Listing API

**User Story:** As Hédra, I want to retrieve memories of any type through a single paginated
API endpoint, so that the frontend and agents always have a consistent, complete view of
what the system knows.

#### Acceptance Criteria

1. WHEN a `GET /api/v1/memories` request is received with no filters, THE Memory_Router
   SHALL return a paginated list of all non-expired memories across episodic, semantic,
   structured, and graph types with a default page size of 25.
2. WHEN a `GET /api/v1/memories` request includes a `type` filter set to one of `working`,
   `episodic`, `semantic`, `structured`, or `graph`, THE Memory_Router SHALL return only
   memories matching that type.
3. WHEN a `GET /api/v1/memories` request includes a `contact_id` filter, THE Memory_Router
   SHALL return only memories associated with that contact.
4. WHEN both `type` and `contact_id` parameters are present, THE Memory_Router SHALL apply
   both filters simultaneously.
5. EVERY listing response SHALL include `data`, `current_page`, `total`, `per_page`, and
   `last_page` fields conforming to the standard Nexus pagination envelope.
6. WHEN a `GET /api/v1/memories` request is received under normal load, THE MemoryHub
   SHALL respond within 500 ms.
7. IF a `type` parameter value is not one of the five valid types, THEN THE MemoryHub
   SHALL return a 422 Unprocessable Entity response with a descriptive validation error.
8. WHEN the `sort` query parameter is set to `confidence`, THE MemoryHub SHALL sort
   structured memory results by `confidence` descending; default sort is `created_at` desc.

---

### Requirement 2: Per-Contact Memory Listing Endpoint

**User Story:** As Hédra, I want to view all memory records for a specific contact through
a dedicated endpoint, so that ContactsHub and the Contact Memory Panel can surface full
cognitive context without issuing multiple requests.

#### Acceptance Criteria

1. WHEN a `GET /api/v1/contacts/{id}/memories` request is received, THE MemoryHub SHALL
   return memories from all applicable types (episodic, semantic, structured, graph) for
   that contact, grouped by type in the response body.
2. WHEN a `type` filter is included, THE MemoryHub SHALL return only memories of that
   type for the specified contact.
3. IF the `{id}` in the route does not exist in `contacts`, THEN THE MemoryHub SHALL
   return a 404 Not Found response.
4. THE response SHALL include a `counts` summary object showing total records per memory
   type (e.g., `{ episodic: 12, semantic: 8, structured: 15, graph: 3, working: 0 }`).
5. THE endpoint SHALL respond within 500 ms under normal load.

---

### Requirement 3: Full CRUD for All Memory Types

**User Story:** As Hédra, I want to create, read, update, and delete memories of any type
through the API, so that the admin UI and agents can maintain precise and up-to-date
knowledge records.

#### Acceptance Criteria

1. WHEN `POST /api/v1/memories` is received with a valid `type` and all required
   type-specific fields, THE MemoryHub SHALL create the memory in the appropriate backend
   and return 201 Created with the new record's `id` and `type`.
2. WHEN `GET /api/v1/memories/{id}` is received with a valid `id` and `type` query param,
   THE MemoryHub SHALL retrieve the memory from the correct type-specific service.
3. WHEN `PUT /api/v1/memories/{id}` is received for an episodic or structured memory,
   THE MemoryHub SHALL update the record and return 200 OK.
4. WHEN `DELETE /api/v1/memories/{id}` is received with a valid `id` and `type`, THE
   MemoryHub SHALL delete the memory from the appropriate backend and return 200 OK with
   the deleted `id`.
5. IF a `POST /api/v1/memories` request is missing a required field for the specified
   `type`, THEN THE MemoryHub SHALL return 422 listing every missing field.
6. IF a `DELETE` request references an `id` that does not exist, THEN THE MemoryHub
   SHALL return 404 Not Found.
7. WHEN a memory record is created, updated, or deleted, THE LogsHub SHALL record an
   audit entry containing the operation type, memory type, record id, and authenticated
   user id.
8. WHEN a structured memory is created via `POST /api/v1/memories`, THE MemoryHub SHALL
   dispatch `SyncMemoryJob` to queue within 1 second of the HTTP response.

---

### Requirement 4: Semantic Search via Pinecone

**User Story:** As Hédra, I want to search memories by semantic meaning rather than exact
keywords, so that the AI and admin UI can surface contextually relevant facts even when
the phrasing differs.

#### Acceptance Criteria

1. WHEN `GET /api/v1/memories/search` is received with a `query` string, THE
   SemanticMemoryService SHALL generate a vector embedding for the query via AiModelsHub
   and query Pinecone for the top-K nearest vectors.
2. WHEN a `contact_id` parameter is included, THE SemanticMemoryService SHALL scope the
   Pinecone query to that contact's namespace.
3. WHEN a `types` array parameter is included, THE MemoryHub SHALL search only those
   types and merge results, deduplicating by `id`.
4. WHEN a `limit` parameter between 1 and 100 is included, THE MemoryHub SHALL return
   at most that many results per type.
5. EVERY search result SHALL include a `score` field (relevance, 0.0–1.0) sorted
   descending by score.
6. IF Pinecone is unavailable, THEN THE MemoryHub SHALL fall back to full-text MySQL
   search on the `memories` and `structured_memories` tables and include `fallback: true`
   in the response `meta`.
7. THE endpoint SHALL respond within 500 ms for queries scoped to a single contact.
8. IF the `query` parameter is empty or absent, THEN THE MemoryHub SHALL return 422.

---

### Requirement 5: Embedding Generation and Pinecone Indexing

**User Story:** As Hédra, I want episodic and structured memories to be automatically
vectorized and indexed in Pinecone, so that semantic search always reflects the current
state of the memory store.

#### Acceptance Criteria

1. WHEN an episodic memory is stored via `EpisodicMemoryService`, THE MemoryHub SHALL
   dispatch `VectorizeMemoryJob` to the Horizon queue within 1 second.
2. WHEN `VectorizeMemoryJob` executes, THE MemoryHub SHALL call AiModelsHub to generate
   a text embedding vector for the memory content.
3. WHEN a valid embedding is produced, THE MemoryHub SHALL dispatch `SaveToPineconeJob`
   persisting the vector with `contact_id`, `memory_id`, `memory_type`, and `created_at`
   as metadata.
4. WHEN `SaveToPineconeJob` executes, THE SemanticMemoryService SHALL upsert the vector
   into the correct Pinecone namespace using the contact id as the namespace key.
5. IF the AiModelsHub embedding call fails, THEN `VectorizeMemoryJob` SHALL retry up to
   3 times with exponential backoff before marking the job failed and logging to LogsHub.
6. IF the Pinecone upsert fails, THEN `SaveToPineconeJob` SHALL retry up to 3 times with
   exponential backoff before marking failed and logging to LogsHub.
7. WHEN `POST /api/v1/memories/{id}/index` is called with a valid `conversation_id`, THE
   MemoryHub SHALL dispatch `ExtractMemoryJob` and return 202 Accepted with
   `status: queued`.

---

### Requirement 6: Memory Extraction from Conversations

**User Story:** As Hédra, I want the system to automatically extract structured facts and
episodic events from conversation messages, so that the memory store is continuously
enriched without manual intervention.

#### Acceptance Criteria

1. WHEN `ExtractMemoryJob` executes for a conversation, THE MemoryHub SHALL send the full
   message content to AiModelsHub with an extraction prompt designed to identify beliefs,
   preferences, personality traits, and key events.
2. WHEN AiModelsHub returns extracted facts, THE MemoryHub SHALL write each fact as a
   structured memory record in `structured_memories` with the originating `conversation_id`
   in the metadata.
3. WHEN AiModelsHub returns extracted events, THE MemoryHub SHALL write each event as an
   episodic memory record in `memories` with `source` set to `extraction`.
4. WHEN new structured or episodic records are created by extraction, THE MemoryHub SHALL
   automatically dispatch vectorization and Pinecone indexing jobs for each new record.
5. IF AiModelsHub returns no extractable facts, THEN `ExtractMemoryJob` SHALL complete
   without error and log a `no_facts_extracted` info entry to LogsHub.
6. IF AiModelsHub returns an error during extraction, THEN `ExtractMemoryJob` SHALL retry
   up to 3 times with exponential backoff and log the final failure to LogsHub with the
   conversation id.
7. THE MemoryHub SHALL prevent duplicate extraction by checking whether a `conversation_id`
   has already been extracted before dispatching `ExtractMemoryJob` again for the same
   conversation.

---

### Requirement 7: Confidence Scoring and Time-Decay

**User Story:** As Hédra, I want memories to carry a confidence score that automatically
decays over time when not reinforced, so that the AI prioritizes fresh, relevant information
and deprioritizes stale facts.

#### Acceptance Criteria

1. THE MemoryHub SHALL assign every newly created structured memory a `confidence` value
   between 0.00 and 1.00, defaulting to 0.80 when not explicitly provided.
2. WHEN a structured memory is confirmed or referenced in a new extraction, THE MemoryHub
   SHALL increment its `confidence` by 0.05, capped at a maximum of 1.00.
3. WHEN `MemoryMaintenanceService::runDecay()` executes on its scheduled interval, THE
   MemoryHub SHALL reduce the `confidence` of structured memories not referenced in the
   preceding 30 days by 0.05 per decay cycle.
4. WHEN a structured memory's `confidence` falls below 0.20, THE MemoryHub SHALL flag it
   as `low_confidence` in its metadata and exclude it from default retrieval results.
5. WHEN a structured memory's `confidence` falls below 0.05, THE MemoryHub SHALL mark it
   as `expired` and stop including it in any retrieval or search results (without deleting
   the record).
6. THE MemoryHub SHALL record each confidence change event (reason, old value, new value,
   timestamp) in a `contact_memory_versions` entry via `ContactMemoryVersion`.
7. WHEN retrieving structured memories through any listing or search endpoint, THE MemoryHub
   SHALL sort results by `confidence` descending as the default ordering.

---

### Requirement 8: Memory Consolidation Pipeline

**User Story:** As Hédra, I want the system to automatically detect and consolidate duplicate
or contradictory memory records, so that the memory store remains accurate, concise, and
free of redundant facts.

#### Acceptance Criteria

1. WHEN `MemoryMaintenanceService::runConsolidation()` executes, THE MemoryHub SHALL use
   AiModelsHub to compare structured memory records for a contact and identify semantically
   duplicate or contradictory pairs.
2. WHEN two records are identified as duplicates, THE MemoryHub SHALL merge them into one
   record by combining content, retaining the higher confidence score, and soft-deleting
   the redundant record.
3. WHEN two records are identified as contradictory, THE MemoryHub SHALL retain the more
   recently updated record, mark the older as `superseded` in metadata, and soft-delete
   the older record.
4. WHEN `MemorySummaryService::summarize()` executes for a contact with more than 50
   episodic memory records in a 30-day window, THE MemoryHub SHALL call AiModelsHub to
   produce a summary and store it as a new structured memory with `fact_type` set to
   `episode_summary`.
5. WHEN any consolidation or summarization produces a new or modified memory record,
   THE MemoryHub SHALL dispatch vectorization and Pinecone indexing jobs for those records.
6. THE MemoryHub SHALL log every consolidation action (merge, supersede, summarize) with
   the affected record ids and operation type to LogsHub.
7. WHEN the Consolidation_Pipeline runs for a contact, THE MemoryHub SHALL NOT modify
   records that were created or updated within the preceding 24 hours.

---

### Requirement 9: Memory Maintenance API and Scheduling

**User Story:** As Hédra, I want maintenance operations to run automatically on a schedule
and also be triggerable manually through the admin UI, so that the memory store stays
healthy without requiring constant manual oversight.

#### Acceptance Criteria

1. THE MemoryHub SHALL expose `POST /api/v1/memories/maintenance` that dispatches
   `RunContactMemoryMaintenanceJob` and returns 202 Accepted with the dispatched job's id.
2. WHEN called with a `contact_id` parameter, THE MemoryHub SHALL scope the maintenance
   run to that single contact.
3. WHEN called without a `contact_id`, THE MemoryHub SHALL schedule maintenance for all
   active contacts, processing them in batches of 50.
4. THE MemoryHub SHALL expose `GET /api/v1/memories/stats` returning counts per type,
   total count, count of `low_confidence` records, count of `expired` records, and
   `last_maintenance_run_at`.
5. WHEN `GET /api/v1/memories/stats` includes a `contact_id` parameter, THE MemoryHub
   SHALL scope all counts to that contact.
6. THE MemoryHub SHALL schedule `RunContactMemoryMaintenanceJob` via Laravel's scheduler
   at a configurable interval defaulting to once every 24 hours.
7. WHEN a maintenance run completes, THE MemoryHub SHALL update a `last_maintenance_run_at`
   setting in the `settings` table and log the result summary to LogsHub.
8. IF a maintenance run is already in progress for the same contact, THEN THE MemoryHub
   SHALL return 409 Conflict with `status: already_running`.

---

### Requirement 10: Memory Version History

**User Story:** As Hédra, I want every change to a structured memory to be versioned, so
that I can audit how a belief or preference evolved over time and roll back to a previous
version if needed.

#### Acceptance Criteria

1. WHEN a structured memory is updated via `PUT /api/v1/memories/{id}`, THE MemoryHub
   SHALL create a `ContactMemoryVersion` entry capturing the previous content, a diff of
   changes, the version number incremented by 1, and the timestamp.
2. THE MemoryHub SHALL expose `GET /api/v1/memories/{id}/versions` returning all version
   history entries for a memory, ordered by version number descending.
3. WHEN a `GET /api/v1/memories/{id}/versions` request is made for a memory with no
   version history, THE MemoryHub SHALL return an empty `data` array with 200 OK.
4. THE MemoryHub SHALL expose `POST /api/v1/memories/{id}/rollback` accepting a `version`
   parameter that restores the memory to that version's content and creates a new version
   entry recording the rollback.
5. IF a rollback `version` does not exist in history, THEN THE MemoryHub SHALL return
   404 Not Found.
6. WHEN any automated process (decay, consolidation, extraction) modifies a structured
   memory, THE MemoryHub SHALL create a version entry with a `source` field set to the
   name of the automated process.

---

### Requirement 11: Graph Memory Management

**User Story:** As Hédra, I want to store and query relationship graph data connecting
contacts to other contacts and to topics, so that the AI can reason about social connections
and contextual associations.

#### Acceptance Criteria

1. WHEN `POST /api/v1/memories` with `type: graph` is received with valid `label`,
   `node_type`, `related_id`, and `related_type` fields, THE GraphMemoryService SHALL
   insert a new row into `graph_nodes` and return the new node's id.
2. THE MemoryHub SHALL expose `POST /api/v1/memories/graph/edges` accepting
   `from_node_id`, `to_node_id`, and `label` and creating a directed edge in `graph_edges`.
3. WHEN `GET /api/v1/memories/graph/nodes` is received with `related_id` and
   `related_type` parameters, THE GraphMemoryService SHALL return all nodes related to
   that entity with their edge counts.
4. THE MemoryHub SHALL expose `GET /api/v1/memories/graph/edges/{node_id}` returning all
   inbound and outbound edges for a given node.
5. WHEN `DELETE /api/v1/memories/{id}` with `type: graph` is received for a node, THE
   GraphMemoryService SHALL delete the node and cascade-delete all associated edges in a
   single transaction.
6. IF `POST /api/v1/memories/graph/edges` references a `from_node_id` or `to_node_id`
   that does not exist, THEN THE MemoryHub SHALL return 422 Unprocessable Entity.
7. THE MemoryHub SHALL expose `GET /api/v1/memories/graph/path` accepting `from_node_id`
   and `to_node_id` and returning the shortest path between two nodes as an ordered array
   of node ids, up to a maximum depth of 10 hops.

---

### Requirement 12: Working Memory Session Management

**User Story:** As Hédra, I want working memory to scope correctly to active conversation
sessions, expire automatically via TTL, and be inspectable from the admin UI, so that
ephemeral context never leaks across conversations.

#### Acceptance Criteria

1. WHEN a working memory entry is created without an explicit `ttl`, THE WorkingMemoryService
   SHALL apply a default TTL of 3600 seconds from config `memory.working_ttl`.
2. WHEN created with an explicit `ttl`, THE WorkingMemoryService SHALL apply exactly that
   value, accepting values between 60 and 86400 seconds.
3. IF a `GET /api/v1/memories/{id}` request is made for a working memory key that has
   expired, THEN THE MemoryHub SHALL return 404 with `reason: expired`.
4. THE MemoryHub SHALL expose `GET /api/v1/memories/working/session/{session_key}` returning
   all working memory entries for a given session key prefix.
5. WHEN `DELETE /api/v1/memories/working/flush` is received with a `session_key`, THE
   WorkingMemoryService SHALL delete all Redis keys matching that session prefix and return
   the count of deleted keys.
6. WHEN a working memory entry is updated via `PUT /api/v1/memories/{id}`, THE
   WorkingMemoryService SHALL reset the TTL to the value specified in the request or to
   the default if no `ttl` is provided.

---

### Requirement 13: GDPR / Right-to-Erasure Cascade

**User Story:** As Hédra, I want a single API call to erase all memory records for a
contact across every memory type, so that I can honour deletion requests without leaving
orphaned data in any storage backend.

#### Acceptance Criteria

1. WHEN `DELETE /api/v1/contacts/{id}/memories` is received, THE MemoryHub SHALL dispatch
   `EraseContactMemoryJob` to queue and return 202 Accepted with the job id.
2. WHEN `EraseContactMemoryJob` executes, THE MemoryHub SHALL delete all episodic records
   in `memories` for the contact, all structured records in `structured_memories`, all
   graph nodes in `graph_nodes` (cascading to `graph_edges`), and all Pinecone vectors
   in the contact's namespace, within a single DB transaction where applicable.
3. WHEN `EraseContactMemoryJob` executes, THE MemoryHub SHALL flush all Redis working
   memory keys prefixed with the contact id.
4. WHEN the erasure completes, THE MemoryHub SHALL write a `memory_erased` audit entry
   to LogsHub with the contact id, counts of deleted records per type, and the timestamp.
5. IF any deletion step fails, THEN `EraseContactMemoryJob` SHALL perform a best-effort
   rollback of completed steps, mark the job as `failed`, and log the partial erasure
   details to LogsHub.
6. IF a `DELETE /api/v1/contacts/{id}/memories` request is made for a contact that does
   not exist, THEN THE MemoryHub SHALL return 404 Not Found.

---

### Requirement 14: Memory Bank Explorer — Core UI

**User Story:** As Hédra, I want a polished Memory Bank Explorer page that lists all
memories with filtering, search, and type tabs, and connects to real backend APIs,
so that I can inspect and manage the full cognitive state of the system.

#### Acceptance Criteria

1. WHEN the Memory Bank Explorer page loads, THE UI SHALL call `GET /api/v1/memories`
   via `apiClient` (not a Zustand mock store) and render the returned records.
2. THE Memory Bank Explorer SHALL render five tab filters: All Cache, Semantic, Episodic,
   Structured, Working, and Graph — with each tab calling the corresponding type filter
   on the API.
3. WHEN a user types in the search input, THE UI SHALL debounce (300 ms) and call
   `GET /api/v1/memories/search` with the query, updating results in place.
4. WHEN a user clicks a memory tag chip, THE UI SHALL set the search input to that tag
   and trigger a new search.
5. THE Memory Bank Explorer SHALL display a side stats panel showing per-type counts,
   a `NxMemoryMiniGraph`, and a `NxTagCloud`, all sourced from `GET /api/v1/memories/stats`.
6. WHEN a user clicks "Synthesize Knowledge", THE UI SHALL open the `NxModal` form,
   call `POST /api/v1/memories` on submit via `apiClient`, and refresh the memory list
   on success.
7. WHEN a user clicks the delete icon on a memory card, THE UI SHALL call
   `DELETE /api/v1/memories/{id}?type={type}` via `apiClient` and remove the card on
   success, with a confirmation prompt for structured or graph types.
8. WHEN a user clicks "Flush Cache", THE UI SHALL call
   `DELETE /api/v1/memories/working/flush?session_key=all` and display a success toast.
9. IF any API call fails, THE UI SHALL display an inline `NxErrorBanner` with the error
   message and a retry button — it SHALL NOT silently swallow errors.
10. THE Memory Bank Explorer SHALL support full responsive layout: on mobile, tabs collapse
    to a horizontal scroll strip and the stats panel moves below the memory grid.

---

### Requirement 15: Memory Bank Explorer — Structured and Graph Tabs

**User Story:** As Hédra, I want dedicated tabs in the Memory Bank Explorer for structured
facts and graph relationships, so that I can inspect and manage typed facts and social
connections with the appropriate context.

#### Acceptance Criteria

1. THE Structured tab SHALL display memory cards showing `fact_type`, `data` summary,
   `confidence` as a percentage badge, `created_at`, and a version count indicator.
2. WHEN a user clicks a structured memory card, THE UI SHALL expand an inline panel showing
   version history entries fetched from `GET /api/v1/memories/{id}/versions`.
3. THE expanded version history panel SHALL show a diff for each version entry and include
   a "Rollback to this version" button that calls `POST /api/v1/memories/{id}/rollback`.
4. THE Graph tab SHALL display nodes from `GET /api/v1/memories/graph/nodes` as a list with
   `label`, `type`, `related_entity`, and `edge_count`.
5. WHEN a user expands a graph node, THE UI SHALL fetch edges from
   `GET /api/v1/memories/graph/edges/{node_id}` and render inbound and outbound edges
   as a grouped list.
6. THE Graph tab SHALL include an "Add Edge" button that opens a modal accepting
   `from_node_id`, `to_node_id`, and `label`, then calls `POST /api/v1/memories/graph/edges`.
7. THE confidence percentage badge on structured memory cards SHALL use color coding:
   green (≥ 70%), amber (20–69%), red (< 20%).

---

### Requirement 16: Contact Memory Panel

**User Story:** As Hédra, I want a per-contact memory panel accessible from the ContactsHub
Contact360 page, so that I can view and manage all memories for a specific contact without
leaving the contact profile.

#### Acceptance Criteria

1. THE Contact Memory Panel SHALL fetch from `GET /api/v1/contacts/{id}/memories` and
   display memories grouped into four sections: Episodic, Semantic, Structured, and Graph.
2. EACH section SHALL show a count badge and be collapsible.
3. WITHIN the Structured section, EACH memory SHALL show its `fact_type`, `confidence`
   badge, and an inline edit button that opens a pre-populated `NxModal` for update.
4. WITHIN the Episodic section, EACH memory SHALL show its `content` summary and
   `created_at` timestamp, formatted relative to now.
5. THE Contact Memory Panel SHALL include a "Run Maintenance" button that calls
   `POST /api/v1/memories/maintenance` with the `contact_id` and shows a spinner until
   the 202 response is received.
6. THE Contact Memory Panel SHALL include a "Erase All Memories" button (admin-only,
   gated by role check) that calls `DELETE /api/v1/contacts/{id}/memories` with a
   confirmation dialog before proceeding.
7. IF the contact has zero memories of any type, THE Contact Memory Panel SHALL display a
   `NxEmptyState` with a "Extract from Conversations" CTA that calls
   `POST /api/v1/memories/{id}/index` with the latest conversation id.

---

### Requirement 17: Memory Maintenance UI Controls

**User Story:** As Hédra, I want maintenance controls directly in the Memory Bank Explorer
so that I can trigger consolidation, decay, and rebuild operations with a single click and
monitor their progress.

#### Acceptance Criteria

1. THE Memory Bank Explorer header SHALL include a "Run Maintenance" button that opens a
   `NxModal` maintenance panel with three scope options: All Contacts, Single Contact
   (contact picker), and Dry Run (preview only).
2. WHEN a user submits the maintenance modal, THE UI SHALL call
   `POST /api/v1/memories/maintenance` with the selected scope and display a job progress
   indicator linked to the returned job id.
3. THE maintenance modal SHALL show an estimated impact preview when "Dry Run" is selected,
   displaying predicted merge count, prune count, and decay candidates — sourced from a
   `GET /api/v1/memories/maintenance/preview` endpoint.
4. WHEN a maintenance job completes, THE UI SHALL display a summary toast: "Maintenance
   complete — X merged, Y pruned, Z decayed" pulled from the job result.
5. THE `GET /api/v1/memories/stats` response SHALL include a `maintenance_status` field
   set to `idle`, `running`, or `scheduled` so the UI can show a live status badge in
   the stats panel.

---

### Requirement 18: Hub Events and Cross-Hub Integration

**User Story:** As Hédra, I want MemoryHub to emit domain events when memories are created,
updated, or deleted, so that AgentsHub, ConversationHub, and other hubs can react in real
time without polling.

#### Acceptance Criteria

1. WHEN a structured memory is created, THE MemoryHub SHALL emit a `memory.created` event
   conforming to the standard Nexus event envelope schema with `contact_id`, `memory_id`,
   `type`, `fact_type`, and `confidence` in the payload.
2. WHEN a structured memory's confidence changes, THE MemoryHub SHALL emit a
   `memory.confidence_changed` event with `old_confidence`, `new_confidence`, and `reason`.
3. WHEN a memory is deleted, THE MemoryHub SHALL emit a `memory.deleted` event with the
   `memory_id`, `type`, and `contact_id`.
4. WHEN extraction produces new structured memories, THE MemoryHub SHALL emit a
   `memory.batch_extracted` event with the count of new records and the `conversation_id`.
5. ALL MemoryHub events SHALL include a `trace_id` in metadata for end-to-end tracing via
   OpenTelemetry, as per the Nexus Event Architecture standard.
6. THE `EventServiceProvider` SHALL register `memory.created` to the `AgentsHub` listener
   so that active agents can load fresh context without a manual cache flush.
