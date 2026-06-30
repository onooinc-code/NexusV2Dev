# Scope: Phase 7 — Frontend: Contact Cards, Topbar, and Import Modal

## Architecture
- Module boundaries: Next.js frontend components (`NxContactCard3D`, `ContactHubTopbarControls`) and the main contacts page (`app/contacts/page.tsx`).
- Data flow: Next.js components receive props from the contacts page state and global context. Topbar will invoke the Global Maintenance Modal and Import Modal.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Contact Card Updates | Update `NxContactCard3D` with required fields, quick actions, and component tests. (Tasks 10.1) | none | DONE |
| 2 | Topbar & Page Wiring | Update `ContactHubTopbarControls` and `app/contacts/page.tsx` to wire the Maintain button to the maintenance modal, Import button to `NxImportModal`, extend progress indicator, and write tests. (Tasks 10.2, 10.3, 10.4, 10.5) | none | PLANNED |

## Interface Contracts
- Components must accept standard props.
- Use `@/lib/api/client` for any new API calls if needed.
- `NxContactCard3D` receives multiple optional callbacks for quick actions.
- `app/contacts/page.tsx` manages the open/close state of modals.
