# Original User Request

## 2026-06-05T18:56:05Z

# Teamwork Project Prompt

> Status: Launched

Complete the implementation, testing, and UI patching of the "Workflows Hub" for the Nexus Project based on the provided `design.md`, `requirements.md`, and `tasks.md` documents. Ensure the Next.js frontend code is production-ready with full test coverage and audited against all requirements.

Working directory: c:\Users\hedra\Desktop\Sourcecode\NexusV2
Integrity mode: development

## Requirements

### R1. Refactoring and Pure Utility Extraction
Extract all pure utility functions from `app/workflows/page.tsx` into `app/workflows/utils.ts` and update the page to use these extracted functions, without altering existing functionality. 

### R2. Test Framework Setup
Set up the testing framework using Jest, React Testing Library, and fast-check for property-based testing in the Next.js 14 environment.

### R3. Comprehensive Test Coverage
Implement property-based tests for the extracted pure utility functions, example-based unit tests for the page-level behavior (e.g., rendering, api calls, modal toggling), integration tests for WebSockets and polling fallbacks, and smoke tests.

### R4. UI Patching and Auditing
Add the missing `bg-grid` CSS class, ensure correct min-height on the canvas, and comprehensively audit the component code against all Acceptance Criteria listed in the requirements, making necessary code adjustments to comply (such as modal reset on close).

### R5. Documentation Update
Update the `tasks.md` checklist file to reflect all completed tasks as work is performed.

## Acceptance Criteria

### Utility Extraction Verification
- [ ] `app/workflows/utils.ts` is created and correctly exports `mapNodeType`, `mapNodeStatus`, `generateWorkflowKey`, `classifyLogLine`, and `applyOptimisticStepPatch`.
- [ ] `app/workflows/page.tsx` imports these utilities and the codebase compiles without type errors.

### Test Framework Verification
- [ ] Test dependencies (e.g., jest, fast-check, testing-library) are correctly configured in `package.json` and `jest.config.ts`.
- [ ] Running `npm run test:run` exits cleanly with no configuration errors.

### Test Implementation Verification
- [ ] All 5 property test suites run and pass.
- [ ] Unit tests for `WorkflowsPage.test.tsx` (fetch on mount, selection, modal behavior, execute button, api payload) execute and pass.
- [ ] Integration tests verify WebSocket channel subscriptions, polling behaviors, and approval modal triggering.
- [ ] Smoke tests for loading state and layout rendering run and pass.
- [ ] The command `npm run test` executes all implemented tests successfully.

### Auditing and UI Verification
- [ ] The `bg-grid` CSS class exists in `app/globals.css`.
- [ ] The canvas layout wrapper possesses the `min-h-[520px]` class.
- [ ] Code adjustments discovered during the codebase audit against `requirements.md` are correctly implemented.

## 2026-06-07T01:21:53+03:00

# Teamwork Project Prompt

Complete the Nexus Project "MemoryHub" implementation, upgrading it from a skeleton state to a fully production-ready feature set across the Laravel backend and Next.js frontend. The implementation must strictly follow the provided `design.md`, `requirements.md`, and `tasks.md`.

Working directory: c:\Users\hedra\Desktop\Sourcecode\NexusV2
Integrity mode: development

## Requirements

### R1. Backend Implementation (Laravel)
Execute the backend technical tasks outlined in `tasks.md` (Phases 1-7). This includes database schema migrations, completing the service layer, MemoryController API surface, async Horizon jobs (including Pinecone and AiModelsHub integrations), and domain events. Note that `php` might not be in the global PATH, so you should write Laravel migration files directly if `artisan make:migration` fails.

### R2. Frontend Implementation (Next.js)
Execute the frontend technical tasks outlined in `tasks.md` (Phases 8-10). This includes replacing the Zustand mock store with `apiClient`, wiring up the Memory Bank Explorer UI, building the Structured and Graph tabs, and creating the Contact Memory Panel.

### R3. Quality Assurance and Documentation
Perform rigorous testing to ensure there are no missing features, architectural discrepancies, or logic bugs. Update the `tasks.md` file to reflect progress.

## Acceptance Criteria

### Backend Verification
- [ ] Schema is updated with correct columns.
- [ ] Backend routes and controllers are fully implemented.
- [ ] Async jobs and services reflect the logic in `design.md` and `requirements.md`.

### Frontend Verification
- [ ] Zustand mock store replaced with `apiClient` in memory components.
- [ ] Memory Bank Explorer UI, Structured tab, Graph tab, and Contact Memory Panel are fully built according to spec.
- [ ] No raw `fetch()` calls or mock store usages remain in memory-related components.
