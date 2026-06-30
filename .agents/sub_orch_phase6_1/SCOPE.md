# Scope: Phase 6 — Frontend: New Contact360 Tabs

## Architecture
- Module boundaries: Next.js frontend pages and components interacting with Laravel backend API.
- Data flow: Next.js components use `apiClient` to fetch data from the backend.
- UI framework: React, Next.js, Tailwind CSS.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | 9.1 Add WhatsApp and Facebook tabs | `app/contacts/[id]/page.tsx`, `NxMessageViewer` | none | PLANNED |
| 2 | 9.2 Create NxConversationsViewer component | `components/NxConversationsViewer.tsx`, `app/contacts/[id]/page.tsx` | M1 | PLANNED |
| 3 | 9.3 Create NxMemoriesViewer component | `components/NxMemoriesViewer.tsx`, `app/contacts/[id]/page.tsx` | M1 | PLANNED |
| 4 | 9.4 Create NxIntelligencePanel component | `components/NxIntelligencePanel.tsx`, `app/contacts/[id]/page.tsx` | M1 | PLANNED |
| 5 | 9.5 Create NxAnalysisFindingsReview component | `components/NxAnalysisFindingsReview.tsx`, `app/contacts/[id]/page.tsx` | M1 | PLANNED |
| 6 | 9.6 Write component tests | Tests for the new components | M1-M5 | PLANNED |

## Interface Contracts
### Frontend ↔ Backend
- API base URL and endpoints conform to NexusV2 API specification.
- Use `@/lib/api/client` for all API calls. No raw `fetch()`.

## Code Layout
- Frontend code: `Nexus-Frontend/`
- Frontend components: `Nexus-Frontend/components/`
- Frontend pages: `Nexus-Frontend/app/`
- API client: `Nexus-Frontend/lib/api/client.ts`
