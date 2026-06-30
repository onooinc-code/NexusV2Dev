# Handoff Report: Workflows Hub M1 & M2 Audit Fix Strategy

## Summary
The M1 & M2 implementation contains a facade test file, hijacked Jest test configuration, and two bugs in the extracted pure utility functions. The strategy below dictates how an implementer should repair these violations without bypassing the audit.

## 1. Observation
- `Nexus-Frontend/app/workflows/__tests__/WorkflowsPage.test.tsx` (lines 44-48) contains an empty test block (`it('renders without crashing', () => { // Basic setup... })`) instead of the concrete unit and integration tests requested in `tasks.md` steps 6.2–6.13 and 7.1–7.3.
- `Nexus-Frontend/jest.config.ts` (line 18) sets `testMatch: ['<rootDir>/app/workflows/**/*.test.{ts,tsx}']`, which bypasses the rest of the project's ~70 tests.
- `Nexus-Frontend/app/workflows/utils.ts` (lines 89-91): `applyOptimisticStepPatch` replaces the entire existing log entry with `newLog`, destroying optional fields like `duration_ms` or `step_name` if they are omitted in the Reverb WebSocket event.
- `Nexus-Frontend/app/workflows/utils.ts` (line 65): `generateWorkflowKey` only appends a timestamp if the user input falls back to `workflow`. `page.tsx` (line 197) manually appends a timestamp, causing double-timestamps when the fallback is triggered.
- `tasks.md` task 6.1 instructs mocking `NxApprovalGateModal`, but it is missing from `WorkflowsPage.test.tsx`.

## 2. Logic Chain
1. The auditor expects substantive tests that cover UI components and their behavior under various conditions (loading, empty state, network responses). By providing an empty test block, the implementation cheated the code coverage and behavioral tests.
2. Limiting `jest.config.ts` to `app/workflows` creates a fake 100% test pass rate by ignoring existing project tests. Removing the `testMatch` override will correctly evaluate all tests.
3. Because Reverb events can be partial, the optimistic patch needs to merge fields rather than overwriting the log object entirely.
4. To correctly separate concerns, the `generateWorkflowKey` function should encapsulate the entire slugification and timestamp-appending logic, freeing `page.tsx` from appending dates manually.

## 3. Caveats
- No caveats. The issues were clearly identified by the auditor and reviewers.

## 4. Conclusion
To restore integrity, the implementer must:
1. **Fix Jest Config**: Remove `testMatch` in `jest.config.ts` entirely (or set it to `['**/?(*.)+(spec|test).[tj]s?(x)']`) so the global tests are evaluated.
2. **Implement Actual Tests**: Write the specific example-based and integration tests outlined in `tasks.md` (6.2-6.13, 7.1-7.3) in `WorkflowsPage.test.tsx`. Include `jest.mock('@/components/NxApprovalGateModal', () => ({ NxApprovalGateModal: () => null }));` at the top.
3. **Fix Optimistic Patch**: Update `applyOptimisticStepPatch` in `utils.ts` to use object spreading:
   ```typescript
   l.step_id === event.step_id ? { ...l, ...newLog, step_name: event.step_name ?? l.step_name, duration_ms: event.duration_ms ?? l.duration_ms, error: event.error ?? l.error } : l
   ```
4. **Fix Workflow Key**: Update `generateWorkflowKey` in `utils.ts` to always append the timestamp (`return \`${base}-${Date.now()}\``) and remove `-${Date.now()}` from `page.tsx`.

## 5. Verification Method
- **Tests Config**: Run `npm run test` or `npm run test:run` in `Nexus-Frontend` and verify it runs ~70+ tests, not just 1.
- **Test Substantiveness**: Inspect `WorkflowsPage.test.tsx` for real queries (`screen.getByText`, etc.) and assertions (`expect()`).
- **Data Integrity**: Inspect `applyOptimisticStepPatch` and `generateWorkflowKey` logic. Build the UI and trigger a WebSocket event; ensure node names and duration do not disappear.
