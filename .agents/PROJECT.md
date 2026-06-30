# Project: Nexus Contact Hub
# Scope: Phase 6-8 Frontend Features

## Architecture
- Module boundaries: Next.js frontend pages and components interacting with Laravel backend API.
- Data flow: Next.js components use `apiClient` to fetch data from the backend.
- UI framework: React, Next.js, Tailwind CSS.

## Code Layout
- Frontend code: `Nexus-Frontend/`
- Frontend components: `Nexus-Frontend/components/`
- Frontend pages: `Nexus-Frontend/app/`
- API client: `Nexus-Frontend/lib/api/client.ts`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Phase 6 | New Contact360 Tabs (WhatsApp, Facebook, Conversations, Memories, Intelligence, AI Analysis Review) | Phase 1-5 | DONE |
| 2 | Phase 7 | Contact Cards, Topbar, and Import Modal | Phase 1-5 | IN_PROGRESS |
| 3 | Phase 8 | Topics Evidence and Relationship Graph | Phase 1-5 | IN_PROGRESS |

## Interface Contracts
### Frontend ↔ Backend
- API base URL and endpoints conform to NexusV2 API specification.
- Use `@/lib/api/client` for all API calls. No raw `fetch()`.
