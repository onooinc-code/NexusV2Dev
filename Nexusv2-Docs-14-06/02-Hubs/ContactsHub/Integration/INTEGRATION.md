# ContactsHub — Frontend ↔ Backend Integration

## 1. Data Flow Overview

```
User Action (Frontend)
  → API call via lib/api/contacts.ts (axios)
  → HTTP request → Laravel API (port 8000)
  → Sanctum auth middleware validates token
  → ContactController routes to appropriate method
  → Service layer (ContactHubService) executes logic
  → Database read/write via Eloquent
  → Response formatted as JSON (API Resource)
  → TanStack Query receives response → updates cache
  → React re-renders with new data
```

---

## 2. API Request-Response Examples

### 2.1 Fetch Contacts (List)

**Request:**
```http
GET /api/contacts?page=1&per_page=20&search=john&status=active
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "John Smith",
      "email": "john@example.com",
      "phone": "+1234567890",
      "status": "active",
      "type": "individual",
      "company": "Acme Corp",
      "tags": ["client", "vip"],
      "last_contacted_at": "2026-06-10T14:30:00Z",
      "created_at": "2026-05-01T10:00:00Z"
    }
  ],
  "links": { "first": "...", "last": "...", "prev": null, "next": "..." },
  "meta": { "current_page": 1, "per_page": 20, "total": 147 }
}
```

### 2.2 Create Contact (with Idempotency)

**Request:**
```http
POST /api/contacts
Authorization: Bearer {token}
X-Idempotency-Key: client-generated-uuid-12345
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "phone": "+10987654321",
  "type": "individual",
  "status": "active",
  "company": "TechCorp"
}
```

**Response (201):**
```json
{
  "data": {
    "id": "new-uuid",
    "name": "Jane Doe",
    ...
  },
  "message": "Contact created successfully"
}
```

### 2.3 Trigger AI Analysis

**Request:**
```http
POST /api/contacts/{id}/analyze
Authorization: Bearer {token}
```

**Response (202 Accepted):**
```json
{
  "analysis_run_id": "run-uuid",
  "status": "pending",
  "message": "Analysis started"
}
```

**Frontend polls:**
```http
GET /api/contacts/{id}/analysis-runs/{run_id}
→ { "status": "running", "progress": 45 }
→ { "status": "completed", "findings_count": 12 }
```

---

## 3. Real-Time Updates

ContactsHub uses WebSocket for live updates during analysis and import:

```typescript
// Frontend subscribes to contact-specific channel
Echo.private(`nexus.contacts.${contactId}`)
  .listen('ContactAnalysisCompleted', (event) => {
    // Invalidate analysis runs query
    queryClient.invalidateQueries(['contact', contactId, 'analysis-runs']);
  })
  .listen('ContactMemoryUpdated', (event) => {
    // Refresh memories
    queryClient.invalidateQueries(['contact', contactId, 'memories']);
  });
```

---

## 4. Error Handling Patterns

### Frontend Error Handling
```typescript
const { mutate } = useMutation({
  mutationFn: createContact,
  onError: (error: AxiosError) => {
    if (error.response?.status === 422) {
      // Validation errors
      setFormErrors(error.response.data.errors);
    } else if (error.response?.status === 409) {
      // Duplicate (idempotency key conflict or duplicate email)
      showToast('Contact already exists', 'warning');
    } else {
      showToast('An error occurred', 'error');
    }
  }
});
```

### Backend Error Responses
| HTTP Status | Scenario |
|-------------|---------|
| `200` | Successful read |
| `201` | Successful creation |
| `202` | Async operation accepted |
| `400` | Bad request / malformed data |
| `401` | Unauthenticated |
| `403` | Forbidden (not owner) |
| `404` | Contact not found |
| `409` | Duplicate contact (idempotency or email conflict) |
| `422` | Validation failed (with field errors) |
| `500` | Server error |

---

## 5. Contact Import Integration

### Frontend → Backend CSV Import

```typescript
// Frontend
const formData = new FormData();
formData.append('file', csvFile);
await axios.post('/api/contacts/import', formData, {
  headers: { 'Content-Type': 'multipart/form-data' }
});
```

```php
// Backend: ContactImportController
// Validates CSV, creates ContactImportBatch
// Dispatches ImportContactsJob to queue
// Returns batch ID for status polling
```

**CSV Expected Format:**
```csv
name,email,phone,company,type,status,tags
John Smith,john@example.com,+1234567890,Acme Corp,individual,active,"client,vip"
```

---

## 6. GDPR Erase Flow

```
User clicks "Erase Contact" (requires confirmation)
  → POST /api/contacts/{id}/erase
  → ContactController@erase
  → ContactPrivacyService::erase()
    → Removes: email, phone, name (anonymizes)
    → Deletes: memories, notes, custom fields
    → Keeps: audit event record (legal requirement)
    → Creates: ContactAuditEvent(type='erased')
  → Returns 200 OK
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
