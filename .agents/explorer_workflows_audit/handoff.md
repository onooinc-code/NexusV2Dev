# Forensic Audit & System Fix Strategy

## 1. Observation
- `Nexus-Frontend/jest.config.ts` configures `testMatch` to `['<rootDir>/app/workflows/**/*.test.{ts,tsx}']`, bypassing all other project tests.
- `Nexus-Frontend/app/workflows/__tests__/WorkflowsPage.test.tsx` line 44 contains an empty test block: `it('renders without crashing', () => { // Basic setup for upcoming tests });`. Task 6 in `tasks.md` expects actual unit testing of page behavior.
- Task 6.1 in `tasks.md` explicitly required mocking `NxApprovalGateModal`, but `WorkflowsPage.test.tsx` lacks `jest.mock('@/components/NxApprovalGateModal', ...)`.
- In `Nexus-Frontend/app/workflows/utils.ts` (lines 75-93), `applyOptimisticStepPatch` completely replaces an existing log instead of merging it, losing properties like `duration_ms` or `error` if the Reverb event omits them.
- In `Nexus-Frontend/app/workflows/utils.ts` (line 65), `generateWorkflowKey` only adds a timestamp as a fallback (`|| \`workflow-${Date.now()}\``). `Nexus-Frontend/app/workflows/page.tsx` line 197 redundantly appends a timestamp (`key: \`${key}-${Date.now()}\``), leading to double timestamps when the fallback is triggered.

## 2. Logic Chain
- The restricted `testMatch` falsely inflates project test success by preventing the runner from executing pre-existing tests. Restoring the default `testMatch` (or removing the override) will ensure system-wide tests are run.
- The dummy test creates a false positive for Milestone completion. Real tests fulfilling requirements 1.1-6.13 as defined in `tasks.md` must be fully implemented to pass the behavioral verification.
- The missing `NxApprovalGateModal` mock causes tests to try mounting the actual modal, which will likely fail or cause network/state warnings since it relies on unmocked dependencies.
- `applyOptimisticStepPatch` needs to spread the existing log entry `l` before applying `newLog` to prevent data loss on partial updates from the WebSocket.
- The timestamp logic must be centralized in `generateWorkflowKey` as intended by the instructions ("handle the full slug+timestamp"). Moving the timestamp append into the util function and out of `page.tsx` resolves the duplication.

## 3. Caveats
- I did not run the test suite locally to verify how many other tests are currently broken; removing the `jest.config.ts` tamper might expose preexisting failures elsewhere.
- The fix strategy assumes the rest of `tasks.md` (property-based tests for `utils.ts`, integration tests) still needs to be fully implemented by the developer.

## 4. Conclusion
To restore integrity and finalize M1 & M2, the implementer must:
1. **Fix the Audit Violations**: 
   - Remove the `testMatch` restriction in `Nexus-Frontend/jest.config.ts`.
   - Replace the dummy `renders without crashing` test in `Nexus-Frontend/app/workflows/__tests__/WorkflowsPage.test.tsx` with the actual tests specified in `tasks.md` (Tasks 6.1 through 6.13).
2. **Apply System Fixes**:
   - Update `applyOptimisticStepPatch` in `utils.ts` to merge step logs: `l.step_id === event.step_id ? { ...l, ...newLog, step_name: event.step_name ?? l.step_name, duration_ms: event.duration_ms ?? l.duration_ms, error: event.error ?? l.error } : l`.
   - Update `generateWorkflowKey` in `utils.ts` to ALWAYS append a timestamp: `const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'workflow'; return \`${slug}-${Date.now()}\`;`.
   - Update `createWorkflow` in `page.tsx` to just use `key: key` without re-appending `Date.now()`.
   - Add `jest.mock('@/components/NxApprovalGateModal', () => ({ NxApprovalGateModal: () => null }));` to `WorkflowsPage.test.tsx`.

## 5. Verification Method
- **Code Review**: Check `jest.config.ts` for the absence of restrictive `testMatch` arrays. Ensure `utils.ts` and `page.tsx` have been updated per the strategy.
- **Test Execution**: Run `npm run test` or `npx jest` from `Nexus-Frontend/` and ensure all tests (including the project's ~70 pre-existing tests) execute and pass.
- **Behavioral Check**: Create a workflow named `!!!` in the UI and verify the network payload uses `workflow-{timestamp}` instead of `workflow-{timestamp}-{timestamp}`.
