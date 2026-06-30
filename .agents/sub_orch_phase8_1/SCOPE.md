# Scope: Phase 8 — Frontend: Topics Evidence and Relationship Graph

## Architecture
- Module boundaries: Next.js components (`NxTopicsViewer`, `NxRelationshipGraph`, `Contact360 Relationships tab`)
- Data flow: Fetching data from the existing Laravel API endpoints via `apiClient`.
- External libraries: `react-force-graph-2d` for the relationship graph.

## Code Layout
- `Nexus-Frontend/components/NxTopicsViewer.tsx` (Update)
- `Nexus-Frontend/components/NxRelationshipGraph.tsx` (Create)
- `Nexus-Frontend/app/contacts/[id]/page.tsx` (or the equivalent file holding Contact360 tabs, update Relationships tab)
- `Nexus-Frontend/components/NxSourceCitation.tsx` (Ensure it exists or create if needed for citations)

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Topics Evidence | Task 11.1: Update `NxTopicsViewer` to expand topics with evidence citations using `NxSourceCitation`. | None | PLANNED |
| 2 | Relationship Graph Setup | Task 11.2: Install `react-force-graph-2d` and create `NxRelationshipGraph` component. | None | PLANNED |
| 3 | Contact360 Graph Toggle | Task 11.3: Add graph view toggle to Relationships tab in Contact360. | Milestone 2 | PLANNED |
| 4 | Component Tests | Task 11.4: Write component tests for topics evidence and relationship graph. | Milestones 1, 3 | PLANNED |

## Interface Contracts
### Frontend ↔ Backend
- `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions` via `apiClient`.
- `GET /api/v1/contacts/{contactId}/relationships` (or equivalent used by Relationships tab).
