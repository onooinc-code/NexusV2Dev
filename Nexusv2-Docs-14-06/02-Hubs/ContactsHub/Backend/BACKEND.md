# ContactsHub — Backend Documentation

## 1. Overview

ContactsHub is the core CRM layer of Nexus. It manages the full lifecycle of contacts — individual people or organizations — including their identity, communication history, notes, AI-enriched memories, relationship graphs, and analytics.

---

## 2. API Endpoints

### Contact Management

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/contacts` | `ContactController@index` | Paginated list with search/filter |
| POST | `/api/contacts` | `ContactController@store` | Create contact (supports idempotency) |
| GET | `/api/contacts/{id}` | `ContactController@show` | Get single contact with relations |
| PUT | `/api/contacts/{id}` | `ContactController@update` | Update contact fields |
| DELETE | `/api/contacts/{id}` | `ContactController@destroy` | Soft delete contact |
| GET | `/api/contacts/{id}/timeline` | `ContactController@timeline` | Activity timeline |
| GET | `/api/contacts/{id}/analytics` | `ContactController@getAnalytics` | Contact analytics |
| GET | `/api/contacts/{id}/memory` | `ContactController@getMemory` | Contact memories |
| GET | `/api/contacts/{id}/rules` | `ContactController@getRules` | Automation rules |
| POST | `/api/contacts/{id}/merge` | `ContactController@merge` | Merge duplicate contacts |
| POST | `/api/contacts/{id}/enrich` | `ContactController@enrich` | AI data enrichment |
| DELETE | `/api/contacts/{id}/erase` | `ContactController@erase` | GDPR erase |
| POST | `/api/contacts/import` | `ContactImportController` | Bulk CSV import |
| GET | `/api/contacts/export` | `ContactController@export` | Bulk export |

### Contact Sub-Resources

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET/POST | `/api/contacts/{id}/identifiers` | `ContactIdentifierController` | Manage identifiers (email, phone, etc.) |
| GET/POST | `/api/contacts/{id}/notes` | `ContactNoteController` | Contact notes |
| GET/POST | `/api/contacts/{id}/relationships` | `ContactRelationshipController` | Contact-to-contact links |
| GET/POST | `/api/contacts/{id}/preferences` | `ContactPreferenceController` | Communication preferences |
| GET/POST | `/api/contacts/{id}/aliases` | `ContactAliasController` | Alternative names |

### AI Analysis

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/contacts/{id}/analyze` | Trigger AI analysis run |
| GET | `/api/contacts/{id}/analysis-runs` | List analysis runs |
| GET | `/api/contacts/{id}/analysis-runs/{runId}/findings` | Get analysis findings |

---

## 3. Key Service: ContactHubService

**File:** `app/Services/ContactHubService.php`

Orchestrates all contact business logic:

```php
// Contact lifecycle
createContact(array $data): Contact
mergeContacts(Contact $primary, Contact $secondary): Contact
enrichContact(Contact $contact): array
eraseContact(Contact $contact): void      // GDPR deletion

// Memory management
getContactMemory(Contact $contact): Collection
extractMemoryFromConversation(Contact, Conversation): void

// Identity resolution
resolveIdentity(string $type, string $value): ?Contact
```

### Identity Resolution Flow
```
Incoming data has email/phone/whatsapp_id
  → ContactIdentityResolver checks ContactIdentifier table
  → If found → link to existing contact
  → If not found → create new contact + identifier
  → Prevents duplicates across channels
```

---

## 4. AI Analysis System

### ContactAnalysisService
Triggers AI analysis runs that extract insights from a contact's conversation history:

```
Analysis Run Types:
- topic_extraction     → What topics does this contact discuss?
- sentiment_analysis   → Emotional tone over time
- preference_extraction → Communication preferences
- relationship_mapping  → Connected contacts/entities
- key_moments          → Important decisions or events
```

### ContactAnalysisRun / ContactAnalysisFinding Models
```
ContactAnalysisRun
  → has many → ContactAnalysisFinding
  → status: pending | running | completed | failed
  → error_message: (on failure)
  → progress columns: total, processed, found

ContactAnalysisFinding
  → type: topic | preference | emotion | decision | relationship
  → content: extracted insight text
  → confidence: 0.0–1.0
  → evidence: JSON array of supporting messages
```

---

## 5. Contact Memory System

Contact memories are managed via the global `MemoryController` and `MemoryRouter`. Each contact has memories across all 5 types:

| Memory Type | What Gets Stored |
|-------------|-----------------|
| `episodic` | "Had a call about Q4 budget on 2026-05-10" |
| `semantic` | "Prefers concise communication" |
| `structured` | `{ company: "Acme", role: "CTO", linkedin: "..." }` |
| `graph` | Relationships to other contacts / entities |
| `working` | Current session context (clears on session end) |

Memory maintenance is handled by `MemoryMaintenanceService`:
- **Expiration**: Removes stale working memories
- **Consolidation**: Merges duplicate episodic memories
- **Versioning**: Tracks memory changes via `ContactMemoryVersion`

---

## 6. Data Validation

Key validation rules in `ContactController::store()`:

```php
'name'      => 'required|string|max:255',
'email'     => 'nullable|email|unique:contacts,email',
'phone'     => 'nullable|string',
'type'      => 'nullable|in:individual,organization,system',
'status'    => 'nullable|in:active,inactive,archived,blocked',
```

---

## 7. Key Models & Relationships

```php
// Contact model (app/Models/Contact.php)
$contact->identifiers    // ContactIdentifier (email, phone, whatsapp_id)
$contact->notes          // ContactNote
$contact->tags           // ContactTag
$contact->customFields   // ContactCustomField
$contact->aliases        // ContactAlias
$contact->preferences    // ContactPreference
$contact->relationships  // ContactRelationship (→ other contacts)
$contact->memories       // Memory
$contact->messages       // ContactMessage
$contact->topics         // ContactTopic
$contact->analysisRuns   // ContactAnalysisRun
```

---

## 8. Import System

**File:** `app/Http/Controllers/ContactImportController.php`

Supports CSV bulk import:
```
POST /api/contacts/import
  multipart/form-data: file (CSV)
  
→ Creates ContactImportBatch record
→ Dispatches background job to process rows
→ Each row → identity resolution → create or update contact
→ Progress tracked via batch record
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
