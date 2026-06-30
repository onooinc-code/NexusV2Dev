# ContactsHub — Frontend Documentation

## 1. Overview

The ContactsHub frontend provides a full-featured contact management interface with search, filtering, AI analysis, timeline view, relationship visualization, and memory management.

---

## 2. Route & Page Structure

```
/contacts                → Contact list view (app/contacts/page.tsx)
/contacts/{id}           → Contact detail view (app/contacts/[id]/page.tsx)
```

---

## 3. Key Components

### 3.1 Contact List Page (`app/contacts/page.tsx`)

Main features:
- **Search**: Real-time search across name, email, phone
- **Filtering**: By status, type, tags, date range
- **Sorting**: By name, last contacted, created date
- **Pagination**: Server-side via TanStack Query
- **Bulk actions**: Select multiple contacts for bulk operations
- **Import modal**: CSV import via `NxImportModal`
- **Quick create**: Inline contact creation

### 3.2 Contact Detail Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `NxContactCard3D` | `components/NxContactCard3D.tsx` | 3D contact profile card with glassmorphism |
| `NxAiAnalysisModal` | `components/NxAiAnalysisModal.tsx` | Trigger and view AI analysis |
| `NxAiAnalysisTab` | `components/NxAiAnalysisTab.tsx` | Analysis findings display tab |
| `NxAnalysisFindingsReview` | `components/NxAnalysisFindingsReview.tsx` | Review and approve findings |
| `NxMemoriesViewer` | `components/NxMemoriesViewer.tsx` | Browse all contact memories |
| `NxMemoryMaintenanceModal` | `components/NxMemoryMaintenanceModal.tsx` | Memory consolidation UI |
| `NxMessageViewer` | `components/NxMessageViewer.tsx` | View contact message history |
| `NxTopicsViewer` | `components/NxTopicsViewer.tsx` | Browse extracted topics |
| `NxConversationsViewer` | `components/NxConversationsViewer.tsx` | View conversation threads |
| `NxRulesViewer` | `components/NxRulesViewer.tsx` | View contact automation rules |
| `NxRelationshipGraph` | `components/NxRelationshipGraph.tsx` | Interactive relationship graph |
| `NxRelationTimeline` | `components/NxRelationTimeline.tsx` | Chronological activity timeline |
| `NxAuditViewer` | `components/NxAuditViewer.tsx` | Contact audit event log |
| `NxImportModal` | `components/NxImportModal.tsx` | CSV bulk import wizard |
| `NxTagCloud` | `components/NxTagCloud.tsx` | Tag visualization and management |

### 3.3 Contact Topbar Controls

**File:** `components/ContactHubTopbarControls.tsx`

Hub-level controls rendered in the top bar:
- Search input with debounce
- Filter dropdowns (status, type)
- View toggle (grid / list)
- Import button
- Export button
- Create new contact button

---

## 4. State Management

### Zustand Store Slices (relevant to ContactsHub)

```typescript
// store/index.ts — Contact-related slices
selectedContact: Contact | null
contactsFilter: ContactFilter
contactsPage: number
contactsSearch: string
isImportModalOpen: boolean
isContactDetailOpen: boolean
```

### TanStack Query Keys

```typescript
// Query key patterns for ContactsHub
['contacts']                              // Contact list
['contacts', filters]                     // Filtered list
['contact', id]                           // Single contact
['contact', id, 'memories']              // Contact memories
['contact', id, 'analysis-runs']         // Analysis history
['contact', id, 'messages']              // Message history
['contact', id, 'topics']                // Extracted topics
['contact', id, 'relationships']         // Relationship graph
```

---

## 5. API Client Functions

All API calls for ContactsHub are in `lib/api/contacts.ts`:

```typescript
// Contact CRUD
fetchContacts(params: ContactFilters): Promise<PaginatedContacts>
fetchContact(id: string): Promise<Contact>
createContact(data: CreateContactData): Promise<Contact>
updateContact(id: string, data: Partial<Contact>): Promise<Contact>
deleteContact(id: string): Promise<void>

// Contact operations
importContacts(file: File): Promise<ImportBatch>
exportContacts(filters: ContactFilters): Promise<Blob>
mergeContacts(primaryId: string, secondaryId: string): Promise<Contact>
enrichContact(id: string): Promise<EnrichmentResult>
eraseContact(id: string): Promise<void>

// Sub-resources
fetchContactMemories(id: string): Promise<Memory[]>
fetchContactMessages(id: string): Promise<ContactMessage[]>
fetchContactTopics(id: string): Promise<ContactTopic[]>
fetchContactTimeline(id: string): Promise<TimelineEvent[]>
triggerContactAnalysis(id: string): Promise<AnalysisRun>
fetchAnalysisFindings(id: string, runId: string): Promise<Finding[]>
```

---

## 6. Key UI Features

### 3D Contact Card (`NxContactCard3D`)
- CSS 3D perspective card with glassmorphism
- Front: Avatar, name, company, contact channels
- Hover: Flips to show stats (memory count, conversation count, last seen)
- Interactive tilt effect on mouse move

### Relationship Graph (`NxRelationshipGraph`)
- Renders using `react-force-graph-2d`
- Nodes: contacts, topics, organizations
- Edges: relationship types with weight indicators
- Click node → navigate to contact
- Zoom, pan, and node filtering

### AI Analysis Flow
```
User clicks "Analyze" button
  → NxAiAnalysisModal opens
  → Calls POST /api/contacts/{id}/analyze
  → Polling for status via GET /api/contacts/{id}/analysis-runs
  → On completion → show findings via NxAnalysisFindingsReview
  → User can approve/reject each finding
  → Approved findings saved as memories
```

### Memory Viewer (`NxMemoriesViewer`)
- Tabs: All / Episodic / Semantic / Structured / Graph
- Search/filter memories by content
- Delete individual memories
- Trigger maintenance run (consolidation)
- Memory confidence visualized with `NxConfidenceBadge`

---

## 7. TypeScript Types

Key types used in ContactsHub frontend:

```typescript
interface Contact {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  whatsapp_id: string | null;
  type: 'individual' | 'organization' | 'system';
  status: 'active' | 'inactive' | 'archived' | 'blocked';
  company: string | null;
  job_title: string | null;
  avatar_url: string | null;
  tags: string[];
  metadata: Record<string, any>;
  last_contacted_at: string | null;
  created_at: string;
  updated_at: string;
}

interface ContactFilter {
  search?: string;
  status?: string;
  type?: string;
  tag?: string;
  dateFrom?: string;
  dateTo?: string;
}

interface Memory {
  id: string;
  type: 'episodic' | 'semantic' | 'structured' | 'graph' | 'working';
  content: string;
  confidence: number;
  source: string;
  created_at: string;
}
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
