# MemoryHub — Full Documentation

## Hub Overview

MemoryHub exposes the 5-type AI memory system used across all of Nexus. It stores, retrieves, searches, and maintains persistent knowledge about contacts, conversations, and the user's own profile (via HedraSoul).

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/memories` | `MemoryController@index` | List memories (filterable) |
| POST | `/api/memories` | `MemoryController@store` | Create memory |
| GET | `/api/memories/{id}` | `MemoryController@show` | Memory details |
| PUT | `/api/memories/{id}` | `MemoryController@update` | Update memory |
| DELETE | `/api/memories/{id}` | `MemoryController@destroy` | Delete memory |
| POST | `/api/memories/search` | `MemoryController@search` | Semantic search |
| POST | `/api/memories/index` | `MemoryController@indexMemory` | Re-index for search |
| GET | `/api/memories/contact/{contactId}` | Memories for a contact |
| POST | `/api/memories/maintenance` | `MemoryController@runMaintenance` | Maintenance run |
| GET | `/api/memories/maintenance-runs` | Maintenance run history |

---

## 1.2 Memory Types & Services

### EpisodicMemoryService
```php
// Stores event-based memories (what happened)
$service->store([
  'contact_id' => $contact->id,
  'content' => 'Discussed Q4 roadmap in call on 2026-06-10',
  'source' => 'conversation',
  'metadata' => ['conversation_id' => '...', 'duration_min' => 45]
]);

// Retrieval: most recent first, by contact or conversation
$memories = $service->getForContact($contactId, $limit = 50);
```

### SemanticMemoryService
```php
// Stores meaning-based knowledge (inferences, preferences)
$service->store([
  'content' => 'Prefers evening meetings, dislikes early morning calls',
  'embedding' => $vectorEmbedding,  // For semantic search
  'confidence' => 0.85,
]);

// Semantic search using vector similarity
$results = $service->search('meeting preferences', $limit = 10);
```

### StructuredMemoryService
```php
// Stores fact-based key-value data
$service->store([
  'contact_id' => $contact->id,
  'facts' => [
    'company'   => 'Acme Corp',
    'role'      => 'CTO',
    'linkedin'  => 'https://linkedin.com/in/...',
    'birthday'  => '1985-03-15',
  ],
  'confidence' => 0.95,
]);

// Fact retrieval
$facts = $service->getFacts($contactId);
$value = $service->getFact($contactId, 'role');
```

### GraphMemoryService
```php
// Stores entity relationships
$service->addRelationship([
  'source_type' => 'contact',
  'source_id'   => $contactId,
  'relation'    => 'works_with',
  'target_type' => 'contact',
  'target_id'   => $colleagueId,
  'weight'      => 0.8,
]);

// Graph traversal
$network = $service->getRelationshipNetwork($contactId, $depth = 2);
```

### WorkingMemoryService
```php
// Stores ephemeral in-session context
$service->set($sessionId, 'current_task', 'Drafting proposal for John');
$service->get($sessionId, 'current_task');
$service->clear($sessionId); // On session end
```

### MemoryRouter
```php
// Automatically routes content to the right service
$router->store([
  'content' => 'User said they prefer formal tone',
  'contact_id' => $id,
]);
// → Analyzes content → Routes to SemanticMemoryService
```

---

## 1.3 Memory Maintenance

### MemoryMaintenanceService
Runs scheduled maintenance to keep memory clean:

```
Maintenance Tasks:
1. EXPIRATION: Delete memories past expires_at
2. DEDUPLICATION: Find near-duplicate memories, merge into one
3. CONSOLIDATION: Merge multiple episodic memories into a semantic summary
4. CONFIDENCE DECAY: Reduce confidence of old, unconfirmed memories
5. INDEX REFRESH: Re-embed memories that need vector updates
```

**Maintenance Run Tracking:**
```
ContactMemoryMaintenanceRun tracks:
- total memories scanned
- duplicates removed
- memories consolidated
- errors encountered
- progress (0–100%)
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/memory/page.tsx`)

Features:
- Memory type tabs: All / Episodic / Semantic / Structured / Graph
- Search: Full-text + semantic search across memories
- Filter: By contact, type, confidence range, date
- Memory detail panel
- Trigger maintenance run
- Memory statistics dashboard

## 2.2 Key Components

| Component | Purpose |
|-----------|---------|
| `NxMemoriesViewer` | Main memory browser with tabs and search |
| `NxMemoryChip` | Compact memory chip with type color coding |
| `NxMemoryMiniGraph` | Small graph visualization for graph memories |
| `NxMemoryMaintenanceModal` | Launch and monitor maintenance runs |
| `NxConfidenceBadge` | Visual confidence score indicator |

## 2.3 Memory Search (Semantic)

```typescript
// Frontend sends search query
const results = await searchMemories({
  query: 'meeting preferences',
  type: 'semantic',
  limit: 10,
  minConfidence: 0.7,
});

// Backend: SemanticMemoryService.search()
// 1. Vectorize query via embedding model
// 2. Cosine similarity search against stored embeddings
// 3. Return top N matches ranked by similarity × confidence
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
