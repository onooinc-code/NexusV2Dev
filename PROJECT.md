# Project: Workflows Hub

## Architecture
- **Frontend**: Next.js (React)
- **Core file**: `app/workflows/page.tsx` (to be refactored to use extracted `utils.ts`)
- **Test Framework**: Jest, React Testing Library, fast-check

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1_Extraction_And_Setup | R1 (Extraction) & R2 (Test Setup) | none | PLANNED |
| 2 | M2_UI_Patch_And_Audit | R4 (UI Patching and Auditing `page.tsx` and css) | M1 | PLANNED |
| 3 | M3_Tests_Prop_Unit | R3 (Property & Unit tests) | M1, M2 | PLANNED |
| 4 | M4_Tests_Integration | R3 (Integration & Smoke tests) | M3 | PLANNED |

## Interface Contracts
### `app/workflows/utils.ts`
- `mapNodeType`
- `mapNodeStatus`
- `generateWorkflowKey`
- `classifyLogLine`
- `applyOptimisticStepPatch`

## Code Layout
- Extracted utilities: `Nexus-Frontend/app/workflows/utils.ts`
- Core page: `Nexus-Frontend/app/workflows/page.tsx`
- Tests: `Nexus-Frontend/tests/workflows/*.test.ts(x)`
