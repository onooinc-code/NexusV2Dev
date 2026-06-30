# Implementation Plan: Workflows Hub

## Overview

The core page (`app/workflows/page.tsx`) is already working. This plan covers the remaining work:
extracting pure utility functions into a testable module, wiring up the test framework, writing
property-based and example-based tests for all 13 design properties and 12 example cases, patching
two missing UI items (`bg-grid` and canvas min-height), auditing `page.tsx` against every
acceptance criterion, and adding smoke tests.

---

## Tasks

- [x] 1. Extract pure utility functions into `app/workflows/utils.ts`
  - [x] 1.1 Create `app/workflows/utils.ts` and move/export the five pure functions
    - Export `mapNodeType(type: string): NodeType` — copy exact logic from `page.tsx`
    - Export `mapNodeStatus(step: WorkflowStep, execution?: WorkflowExecution): NodeStatus` — copy exact logic
    - Export `generateWorkflowKey(name: string): string` — extract slug + timestamp logic from `createWorkflow`
    - Export `classifyLogLine(line: string): 'text-red-400' | 'text-emerald-400' | 'text-blue-400' | 'text-gray-400'` — extract inline ternary from tracer log rendering
    - Export `applyOptimisticStepPatch(prev: WorkflowExecution, event: ReverbStepEvent): WorkflowExecution` — extract functional updater from the WebSocket `step_completed` handler
    - Re-export shared types `NodeType`, `NodeStatus`, `WorkflowStep`, `WorkflowExecution`, `ReverbStepEvent` from this module (or import them in `page.tsx` from here)
    - _Requirements: 2.4, 2.5, 3.7, 3.8, 4.2, 6.3, 6.4_

  - [x] 1.2 Update `app/workflows/page.tsx` to import all five functions from `./utils`
    - Remove the inline definitions of `mapNodeType` and `mapNodeStatus`
    - Replace the inline key-generation expression inside `createWorkflow` with `generateWorkflowKey`
    - Replace the inline color-class ternary in the tracer log `map` with `classifyLogLine`
    - Replace the `setExecution` functional updater body with `applyOptimisticStepPatch`
    - Verify `page.tsx` still compiles without type errors after the refactor
    - _Requirements: 2.4, 2.5, 3.7, 3.8, 4.2, 6.3, 6.4_

- [x] 2. Set up the test framework (Jest + React Testing Library + fast-check)
  - [x] 2.1 Install test dependencies and configure Jest for Next.js 14
    - Install exact versions: `jest@29`, `jest-environment-jsdom@29`, `@testing-library/react@16`, `@testing-library/user-event@14`, `@testing-library/jest-dom@6`, `fast-check@3`, `ts-jest@29`, `@types/jest@29`
    - Create `jest.config.ts` at project root using `next/jest` transformer preset so that path aliases (`@/`) resolve correctly
    - Create `jest.setup.ts` that imports `@testing-library/jest-dom`
    - Add `"test": "jest --runInBand"` and `"test:run": "jest --runInBand --passWithNoTests"` to `package.json` scripts
    - Verify `npx jest --passWithNoTests` exits cleanly (no config errors)
    - _Requirements: (infrastructure prerequisite for all test tasks)_

- [x] 3. Checkpoint — verify test framework boots
  - Run `npm run test:run`; ensure zero failures before writing any test files. Ask the user if questions arise.

- [ ] 4. Write property-based tests for the five pure functions
  - [ ] 4.1 Write property tests for `mapNodeType`
    - **Property 3: `mapNodeType` is a total function with correct outputs**
    - **Validates: Requirements 2.4**
    - File: `app/workflows/__tests__/utils.property.test.ts`
    - Use `fc.constantFrom('trigger','webhook','scheduled','agent','task','decision','condition','action','wait','log')` plus `fc.string()` for arbitrary inputs
    - Assert: always returns one of the four `NodeType` values, never throws, never returns `undefined`
    - Assert: each known input maps to its documented `NodeType`

  - [ ] 4.2 Write property tests for `mapNodeStatus`
    - **Property 5: `mapNodeStatus` pure mapping invariant**
    - **Validates: Requirements 2.5**
    - Use `fc.record` arbitraries for `WorkflowStep` and optional `WorkflowExecution` with arbitrary `step_logs`
    - Assert: if no matching `step_log` → `'pending'`; `running/paused` log → `'running'`; `failed` log → `'error'`; otherwise → `'success'`
    - Assert: never throws, never returns `undefined`

  - [ ] 4.3 Write property tests for `applyOptimisticStepPatch`
    - **Property 8: Optimistic step log patch is correct for any event**
    - **Validates: Requirements 3.8**
    - Use `fc.record` for `WorkflowExecution` (with arbitrary `step_logs` array) and `fc.record` for `ReverbStepEvent`
    - Assert: if `step_id` exists in logs → that entry is replaced, all others unchanged
    - Assert: if `step_id` is new → entry is appended, all others unchanged
    - Assert: top-level execution fields (except `step_logs`) are unchanged after patch
    - Assert: function never throws

  - [ ] 4.4 Write property tests for `generateWorkflowKey`
    - **Property 9: Workflow key generation produces valid slugs with timestamp suffix**
    - **Validates: Requirements 6.3, 6.4**
    - Use `fc.string({ minLength: 1 })` including unicode and special-char-only inputs
    - Assert: result matches `/^[a-z0-9][a-z0-9-]*$/` or is the fallback `workflow-{digits}`
    - Assert: no leading or trailing hyphens
    - Assert: result ends with `-{digits}` (timestamp suffix is always appended)
    - Assert: result is never empty

  - [ ] 4.5 Write property tests for `classifyLogLine`
    - **Property 13: Log line color classification is a total pure function**
    - **Validates: Requirements 4.2**
    - Use `fc.string()` plus targeted strings prefixed with `❌`, `✗`, `✅`, `✓`, `▶`
    - Assert: returns exactly one of the four CSS class strings
    - Assert: never returns `undefined`, never throws
    - Assert: prefix-to-class mapping is correct per the design spec

- [ ] 5. Checkpoint — all property tests pass
  - Run `npm run test:run`; all 5 property test suites must pass. Ask the user if questions arise.

- [x] 6. Write example-based unit tests for page-level behavior
  - [x] 6.1 Set up the page test file with mocks
    - Create `app/workflows/__tests__/WorkflowsPage.test.tsx`
    - Mock `@/lib/api/client` (apiClient), `@/hooks/useWebSocket`, and all child components that make network calls (`NxApprovalGateModal`)
    - Create reusable test fixtures: `mockWorkflows`, `mockExecution`, `mockPausedExecution`

  - [ ] 6.2 Write unit test: fetch on mount (Req 1.1)
    - Mock `apiClient.get('/workflows?limit=50')` returning `mockWorkflows`
    - Mount `WorkflowsPage`, assert `GET /workflows?limit=50` is called exactly once
    - _Requirements: 1.1_

  - [ ] 6.3 Write unit test: selected workflow highlight (Req 1.4)
    - Render sidebar with two workflows; verify the selected button has `border-nexus-blue/60` class
    - _Requirements: 1.4_

  - [ ] 6.4 Write unit test: empty state renders (Req 1.5)
    - Mock `apiClient.get` returning `{ data: [] }`; assert "No Workflows" text is visible
    - _Requirements: 1.5_

  - [ ] 6.5 Write unit test: canvas empty state (Req 2.7)
    - Render with a selected workflow whose `steps` array is empty; assert "Canvas is Empty" text
    - _Requirements: 2.7_

  - [ ] 6.6 Write unit test: execute button calls correct endpoint with correct body (Req 3.1)
    - Mock `apiClient.post`; click Execute button; assert called with `/workflows/{id}/execute` and `{ run_mode:'async', input_payload:{ launched_from:'WorkflowsHub' } }`
    - _Requirements: 3.1_

  - [ ] 6.7 Write unit test: logs cleared on execute (Req 3.4)
    - Pre-seed `realtimeLogs` state; click Execute; assert log panel is empty before new logs arrive
    - _Requirements: 3.4_

  - [ ] 6.8 Write unit test: WS "Live" badge (Req 3.10)
    - Mock `useWebSocket` returning `connectionStatus='connected'`; assert "Live" text in header badge
    - _Requirements: 3.10_

  - [ ] 6.9 Write unit test: approval modal auto-opens on paused execution (Req 5.3)
    - Mock `fetchProgress` to resolve with `mockPausedExecution`; assert `NxApprovalGateModal` is rendered
    - _Requirements: 5.3_

  - [ ] 6.10 Write unit test: approve call sends correct payload (Req 5.5)
    - Render with `showApprovalModal=true` and `mockPausedExecution`; click Approve; assert `POST /executions/{id}/resume` with `{ decision:'approve', input_payload:{ approval_decision:'approve' } }`
    - _Requirements: 5.5_

  - [ ] 6.11 Write unit test: deny call sends correct payload (Req 5.6)
    - Same setup; click Deny; assert same endpoint with `decision:'deny'`
    - _Requirements: 5.6_

  - [ ] 6.12 Write unit test: "New Workflow" button opens modal (Req 6.1)
    - Click "New Workflow" button; assert `NxModal` is visible (check for modal title "Create Workflow")
    - _Requirements: 6.1_

  - [ ] 6.13 Write unit test: creation error shows ❌ log line (Req 6.6)
    - Mock `apiClient.post('/workflows')` to reject with `{ message: 'Conflict' }`; submit the creation form; assert the realtime log area contains a line starting with `❌`
    - _Requirements: 6.6_

- [ ] 7. Write integration tests for real-time and WebSocket behavior
  - [ ] 7.1 Write integration test: WebSocket channel subscription
    - Mock `Echo` instance; render `WorkflowsPage` with `connectionStatus='connected'` and a selected workflow
    - Assert `echo.private('workflow.{workflowId}')` is called with the correct channel name
    - _Requirements: 3.6_

  - [ ] 7.2 Write integration test: polling fallback starts and stops
    - Mock `useWebSocket` returning `wsConnected=false`; render with a non-terminal `mockExecution`
    - Assert `setInterval` fires `fetchProgress` at ~2500 ms
    - Update execution to `status='completed'`; assert interval is cleared
    - _Requirements: 3.9_

  - [ ] 7.3 Write integration test: approval gate triggered by WS event
    - Render with a connected mock Echo; fire `.workflow.step_completed` event with `status='paused'`
    - Assert `fetchProgress` is called; assert `NxApprovalGateModal` becomes visible
    - _Requirements: 5.2_

- [ ] 8. Checkpoint — all unit and integration tests pass
  - Run `npm run test:run`; all test suites must pass. Ask the user if questions arise.

- [x] 9. Fix missing UI: add `bg-grid` CSS class and verify canvas min-height
  - [x] 9.1 Add `bg-grid` utility class to `app/globals.css`
    - Append a `.bg-grid` rule inside `@layer utilities` using a repeating CSS pattern:
      ```css
      .bg-grid {
        background-image:
          linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
          linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
        background-size: 32px 32px;
      }
      ```
    - Verify the class renders correctly in the browser (dot-grid or line-grid aesthetic per Req 7.6)
    - _Requirements: 7.6_

  - [x] 9.2 Verify canvas container has `min-h-[520px]` applied
    - Check the three-panel grid wrapper in `page.tsx` has `min-h-[520px]` on the grid row
    - If missing, add `min-h-[520px]` to the canvas column `div` or the grid container as appropriate
    - _Requirements: 7.4_

- [x] 10. Audit `page.tsx` against all acceptance criteria and fix gaps
  - [x] 10.1 Audit Requirement 1: Workflow List
    - Verify `GET /workflows?limit=50` is called on mount ✓ (already implemented)
    - Verify no crash during loading — confirm `isLoading` guard is present ✓
    - Verify sidebar button shows `name` and `trigger_type / status` uppercase ✓
    - Verify selected button uses `border-nexus-blue/60 bg-nexus-blue/10` ✓
    - Verify `NxEmptyState` "No Workflows" renders when list empty and not loading ✓
    - Verify auto-select logic picks `list[0].id` when `selectedId` is null ✓
    - Verify Refresh button calls `fetchWorkflows` ✓
    - Fix any deviations found; leave a `// AUDIT:` comment if no change needed
    - _Requirements: 1.1–1.7_

  - [x] 10.2 Audit Requirement 2: Workflow Canvas
    - Verify `NxWorkflowNode` rendered for each step with correct `type` (via `mapNodeType`) ✓
    - Verify type label `<div>` above each node is monospace uppercase ✓
    - Verify connector `div` is `hidden md:block` between consecutive nodes ✓
    - Verify `selected={node.status === 'running'}` prop is passed ✓
    - Verify `mapNodeStatus` looks up `step_logs` by `step.id` ✓
    - Verify `NxEmptyState` "Canvas is Empty" when `nodes.length === 0` ✓
    - Verify `overflow-x-auto` on canvas container ✓
    - Fix any deviations found
    - _Requirements: 2.1–2.8_

  - [x] 10.3 Audit Requirement 3: Execution & WebSocket
    - Verify Execute button POSTs correct body ✓
    - Verify Execute button shows spinner (`isRunning`) ✓
    - Verify Execute button disabled when `!selectedWorkflow || status==='running'` ✓
    - Verify `realtimeLogs` cleared on execute ✓
    - Verify WS subscription to `workflow.{id}` private channel ✓
    - Verify all four WS events produce correct log line prefixes (`▶`, `✓/✗`, `✅`, `❌`) ✓
    - Verify optimistic patch uses `applyOptimisticStepPatch` (post-refactor) ✓
    - Verify polling interval is 2500 ms and stops on terminal state ✓
    - Verify WS badge shows "Live" / "Offline" correctly ✓
    - Fix any deviations found
    - _Requirements: 3.1–3.10_

  - [x] 10.4 Audit Requirement 4: Execution Tracer
    - Verify realtime logs appear above `── API step logs ──` divider ✓
    - Verify log line colors use `classifyLogLine` (post-refactor) ✓
    - Verify persisted logs show step name, color-coded status, duration, error ✓
    - Verify execution ID and status are displayed ✓
    - Verify status color classes match: emerald=completed, red=failed, amber=paused, blue=running, gray=other ✓
    - Verify status icons: `CheckCircle2` for completed, `XCircle` for failed, `PauseCircle` for paused ✓
    - Verify "No active execution." shown when `execution === null` ✓
    - Verify log area has `max-h-[300px] overflow-y-auto` ✓
    - Fix any deviations found
    - _Requirements: 4.1–4.8_

  - [x] 10.5 Audit Requirement 5: Approval Gate
    - Verify "Review Approval Gate" button rendered iff `status==='paused' && waiting_for.type==='approval'` ✓
    - Verify WS `step_completed` with `status=paused` triggers `fetchProgress` and `setShowApprovalModal(true)` ✓
    - Verify `fetchProgress` result with paused+approval auto-opens modal ✓
    - Verify `NxApprovalGateModal` receives `executionId`, `stepId`, `contextData` props correctly ✓
    - Verify `onApprove` calls resume with `decision:'approve'` ✓
    - Verify `onReject` calls resume with `decision:'deny'` ✓
    - Verify modal closes and `execution` state updates after resume ✓
    - Fix any deviations found
    - _Requirements: 5.1–5.7_

  - [x] 10.6 Audit Requirement 6: Workflow Creation
    - Verify "New Workflow" button opens `NxModal` ✓
    - Verify form has Name `NxInput` and Trigger `NxSelect` with four options ✓
    - Verify POST body includes all required fields (name, key, description, trigger_type, status:'draft', steps, settings) ✓
    - Verify `generateWorkflowKey` is used (post-refactor) and produces timestamp suffix ✓
    - Verify new workflow prepended to list and auto-selected ✓
    - Verify creation failure logs `❌ Failed to create workflow: …` ✓
    - Verify Cancel resets `newName=''` and `newTrigger='manual'` — **check `NxModal` `onClose` handler resets both fields**
    - Fix any deviations found (the current `onClose` only calls `setIsModalOpen(false)` — add field resets)
    - _Requirements: 6.1–6.7_

  - [x] 10.7 Audit Requirement 7: Layout
    - Verify page renders inside `AppLayout` ✓
    - Verify three-panel grid uses `xl:grid-cols-[280px_1fr_320px]` and `grid-cols-1` on mobile ✓
    - Verify header subtitle shows `${name} v${version}` ✓
    - Verify `min-h-[520px]` on grid container (check/fix in 9.2 above) ✓
    - Verify `overflow-x-auto` on canvas ✓
    - Verify `bg-grid` class is on canvas container (fixed in 9.1 above — already applied in `page.tsx`) ✓
    - Fix any deviations found
    - _Requirements: 7.1–7.6_

- [ ] 11. Write smoke tests
  - [ ] 11.1 Write smoke test: loading state does not crash
    - Render `WorkflowsPage` with `apiClient.get` never resolving (loading state)
    - Assert no error boundary thrown; assert component is in the document
    - _Requirements: 1.2_

  - [ ] 11.2 Write smoke test: canvas has `overflow-x-auto`
    - Render `WorkflowsPage` with a workflow that has steps
    - Assert canvas container element has `overflow-x-auto` class
    - _Requirements: 2.8, 7.5_

  - [ ] 11.3 Write smoke test: tracer log area has max-height and overflow
    - Render `WorkflowsPage` with a non-null `mockExecution`
    - Assert the log scroll area has both `max-h-[300px]` and `overflow-y-auto` classes
    - _Requirements: 4.8_

- [ ] 12. Final checkpoint — full test suite passes
  - Run `npm run test:run`; all suites (property tests, unit tests, integration tests, smoke tests) must pass. Ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Tasks 1–2 (extraction + test setup) are strict prerequisites for all test tasks
- Task 3 (bg-grid + min-height) is a UI-only patch, independent of the test tasks
- Task 10 (audit) is a read-before-write pass — fix only what deviates; leave `// AUDIT: OK` comments where nothing changes
- The `generateWorkflowKey` function should NOT append a second timestamp internally — the caller in `createWorkflow` passes `name` and the function handles the full slug+timestamp, matching current behavior
- After Task 1.1 extraction, run `tsc --noEmit` to confirm the refactor is type-clean before writing tests

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "2.1"] },
    { "id": 2, "tasks": ["6.1", "9.1", "9.2", "10.1", "10.2", "10.3", "10.4", "10.5", "10.6", "10.7"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3", "4.4", "4.5", "6.2", "6.3", "6.4", "6.5", "6.6", "6.7", "6.8", "6.9", "6.10", "6.11", "6.12", "6.13", "7.1", "7.2", "7.3", "11.1", "11.2", "11.3"] }
  ]
}
```
