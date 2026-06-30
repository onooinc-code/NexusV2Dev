# Implementation Plan: Tasks Hub

## Overview

The core page (`app/tasks/page.tsx`) already exists and is largely aligned with the spec. The
implementation work focuses on four areas: (1) fixing the confirmed priority-mapping gap in the
store, (2) hardening the page against the few spec deviations found in the design review,
(3) setting up the test infrastructure from scratch (Vitest + React Testing Library + fast-check +
MSW), and (4) writing all property tests, unit tests, and integration tests defined in the design
document.

---

## Tasks

- [x] 1. Fix the priority mapping gap in the Zustand store
  - [x] 1.1 Update `priorityFromInt` in `store/index.ts` to use range-based logic
    - In `hydrateTasks`, replace the exact-equality ternary (`=== 10`, `=== 5`, `=== 1`) with:
      `n >= 7 ? 'high' : n >= 4 ? 'medium' : 'low'`
    - Extract the helper as a named inline function `priorityFromInt(n: number)` inside
      `hydrateTasks` so it can be imported and tested independently
    - Also extract `priorityToInt(p: string)` from `createTask` for symmetry and test access
    - _Requirements: 3.5_

- [x] 2. Set up test infrastructure
  - [x] 2.1 Install test dependencies and configure Vitest
    - Add to `devDependencies`: `vitest`, `@vitejs/plugin-react`, `@testing-library/react`,
      `@testing-library/jest-dom`, `@testing-library/user-event`, `fast-check`, `msw`, `jsdom`
    - Create `vitest.config.ts` at project root:
      - environment: `jsdom`
      - globals: `true`
      - setupFiles: `['./tests/setup.ts']`
      - resolve aliases matching `tsconfig.json` (`@/ → ./`)
    - Add `"test": "vitest --run"` and `"test:watch": "vitest"` to `package.json` scripts
    - _Requirements: none (infrastructure)_

  - [x] 2.2 Create test setup file and shared test utilities
    - Create `tests/setup.ts`:
      - Import `@testing-library/jest-dom/vitest`
      - Mock `next/navigation` (stub `useRouter`, `usePathname`)
      - Mock `@/store/store-provider` with a factory that wraps a real Zustand store instance,
        allowing per-test store initialization
    - Create `tests/tasks/helpers.ts`:
      - Export `arbTask`: a `fast-check` arbitrary that generates valid `Task` objects with
        `status` from `['todo', 'in-progress', 'completed']`, `priority` from
        `['low', 'medium', 'high']`, and non-empty `title`, `description`, `dueDate` strings
      - Export `makeTask(overrides?)`: a factory for concrete `Task` objects used in unit tests
      - Export `makeMockStore(tasks?)`: returns a mock store object with `vi.fn()` stubs for
        `hydrateTasks`, `createTask`, `updateTask`, `deleteTask`, `addJob`
    - _Requirements: none (infrastructure)_

- [x] 3. Write property tests for the five design correctness properties
  - [x] 3.1 Write property test — Property 1: Column Filter Partition
    - Create `tests/tasks/properties.test.ts`
    - Use `arbTask` arbitrary; generate arrays of tasks with arbitrary status distributions
    - Assert: `todo.length + inProgress.length + completed.length === tasks.length`
    - Assert: each sub-array contains only tasks of its own status
    - Tag: `// Feature: tasks-hub, Property 1: every task appears in exactly one column`
    - `numRuns: 100`
    - _Requirements: 1.4_

  - [x] 3.2 Write property test — Property 2: Status Cycle Invariant
    - In `tests/tasks/properties.test.ts`
    - Use `fc.constantFrom('todo', 'in-progress', 'completed')`
    - Extract `nextStatus` function from page logic and import/duplicate it in the test
    - Assert: `nextStatus(nextStatus(nextStatus(s))) === s` for all three starting values
    - Tag: `// Feature: tasks-hub, Property 2: cycling status 3 times returns to origin`
    - `numRuns: 100`
    - _Requirements: 2.2_

  - [x] 3.3 Write property test — Property 3: Optimistic Rollback Preservation
    - In `tests/tasks/properties.test.ts`
    - Import the `useGlobalStore` Zustand store directly (not through the provider context)
    - For each generated task array: initialize a fresh store instance, mock `apiClient.patch`
      to reject, call `updateTask`, assert `store.getState().tasks` deep-equals the snapshot
    - Repeat for `deleteTask` (mock `apiClient.delete` to reject)
    - Tag: `// Feature: tasks-hub, Property 3: API failure rolls back to pre-action state`
    - `numRuns: 50` (store re-initialization is expensive)
    - _Requirements: 2.4, 2.5, 3.6, 3.8, 4.3, 4.4_

  - [x] 3.4 Write property test — Property 4: Priority Mapping Roundtrip
    - In `tests/tasks/properties.test.ts`
    - Import `priorityToInt` and `priorityFromInt` from `store/index.ts` (extracted in task 1.1)
    - Use `fc.constantFrom('low', 'medium', 'high')`
    - Assert: `priorityFromInt(priorityToInt(p)) === p` for every priority string
    - Tag: `// Feature: tasks-hub, Property 4: priority string → int → string is lossless`
    - `numRuns: 100`
    - _Requirements: 3.5_

  - [x] 3.5 Write property test — Property 5: TaskCard Complete Render
    - In `tests/tasks/properties.test.ts`
    - Import `TaskCard` by converting the co-located function to a named export or moving it
      to `app/tasks/TaskCard.tsx`
    - Use `arbTask` arbitrary; render `<TaskCard>` with mock callbacks for each generated task
    - Assert: rendered output contains `task.title`, `task.dueDate`, `task.priority` label
    - Assert: correct icon is present based on `task.status` (check data-testid or aria-label)
    - Tag: `// Feature: tasks-hub, Property 5: TaskCard renders all required fields for any task`
    - `numRuns: 100`
    - _Requirements: 1.6, 2.6_

- [x] 4. Write unit tests covering the 11 concrete test cases
  - [x] 4.1 Write unit tests for `TasksPage` — mount, hydration, column rendering
    - Create `tests/tasks/TasksPage.test.tsx`
    - Render `TasksPage` inside a test wrapper that provides the mock store
    - **Test: Mount hydration** — assert `hydrateTasks` is called exactly once after mount
    - **Test: Column render** — seed store with one task per status; assert "To Do",
      "In Progress", and "Completed" column headings are in the document
    - **Test: Empty state (all three columns)** — seed store with empty `tasks[]`; assert
      "No pending objectives.", "No running tasks.", "No completed objectives." are visible
    - _Requirements: 1.1, 1.2, 1.5_

  - [x] 4.2 Write unit tests for `TaskCard` — styling, badges, icons
    - Create `tests/tasks/TaskCard.test.tsx`
    - **Test: Completed styling** — render a task with `status='completed'`; assert the card
      container has `opacity-60`, and the title has `line-through` class
    - **Test: Priority badge colors** — render tasks with each priority value; assert the
      badge element contains the correct Tailwind color tokens for `low`, `medium`, `high`
    - **Test: Delete hover visibility** — render any task; assert the delete button has
      `opacity-0` and `group-hover:opacity-100` classes
    - _Requirements: 1.6, 1.7, 4.5_

  - [x] 4.3 Write unit tests for `TasksPage` — drawer and form interactions
    - In `tests/tasks/TasksPage.test.tsx`
    - **Test: Drawer open/close** — click "New Objective"; assert drawer is visible; click
      "Cancel"; assert drawer is no longer visible
    - **Test: Form submission** — fill in title, submit form; assert `createTask` is called
      with `{ title, status: 'todo', priority: 'medium', ... }`; assert drawer closes
    - **Test: Form reset** — after submission, assert all form fields return to default values
      (`title: ''`, `priority: 'medium'`, `dueDate: 'TBD'`)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.10, 3.11_

  - [x] 4.4 Write unit tests for `TasksPage` — addJob side effects
    - In `tests/tasks/TasksPage.test.tsx`
    - **Test: addJob on in-progress transition** — seed store with a `todo` task; click its
      toggle; assert `addJob` is called with a string matching
      `Agent solving task objective: id-{last4}`
    - **Test: addJob on create** — submit the create form with a valid title; assert `addJob`
      is called with `'Scheduling agent task allocation workflow'`
    - _Requirements: 2.7, 3.9_

  - [x] 4.5 Write unit test for `TasksPage` — delete interaction
    - In `tests/tasks/TasksPage.test.tsx`
    - **Test: Delete interaction** — seed store with one task; hover the card; click the delete
      button; assert `deleteTask` is called with the task's `id`
    - _Requirements: 4.1, 4.2_

- [x] 5. Extract `TaskCard` for independent testing
  - [x] 5.1 Move `TaskCard` to a named export in `app/tasks/page.tsx`
    - Change the bottom-of-file `function TaskCard(...)` to `export function TaskCard(...)`
    - Add proper TypeScript typing: replace `task: any` with `task: Task` (imported from
      `@/store`)
    - Add `data-testid` attributes needed by property tests:
      - `data-testid="task-card"` on the root `<div>`
      - `data-testid="status-icon-{status}"` on the status toggle button
      - `data-testid="priority-badge"` on the priority `<span>`
      - `data-testid="delete-btn"` on the delete `<button>`
    - Verify the page still renders correctly after the change
    - _Requirements: 1.6, 2.6_

- [x] 6. Write integration tests for API interactions
  - [x] 6.1 Set up MSW handlers for the tasks API
    - Create `tests/tasks/mocks/handlers.ts` with MSW `http` handlers:
      - `GET /tasks` → returns a fixture array of three tasks (one per status)
      - `PATCH /tasks/:id/status` → returns `{ data: { ...task, status } }`
      - `POST /tasks` → returns `{ data: { id: 'server-1', ...body } }`
      - `DELETE /tasks/:id` → returns `{ status: 200 }`
    - Create `tests/tasks/mocks/server.ts` that starts the MSW Node server
    - Wire `beforeAll(server.listen)`, `afterEach(server.resetHandlers)`,
      `afterAll(server.close)` into the integration test file
    - _Requirements: 1.1, 2.3, 3.4, 4.2_

  - [x] 6.2 Write integration test — GET /tasks hydration
    - Create `tests/tasks/integration.test.tsx`
    - Render `TasksPage` with real store (no mocks); MSW serves the fixture tasks
    - Assert all three task titles appear in the DOM after mount
    - Assert tasks are placed in their correct columns
    - _Requirements: 1.1, 1.4_

  - [x] 6.3 Write integration test — PATCH /tasks/:id/status
    - In `tests/tasks/integration.test.tsx`
    - After hydration, click a `todo` task's toggle button
    - Assert the card moves to the In Progress column (optimistic)
    - Assert `PATCH /tasks/{id}/status` was called with `{ status: 'in-progress' }`
    - _Requirements: 2.3, 2.4_

  - [x] 6.4 Write integration test — POST /tasks
    - In `tests/tasks/integration.test.tsx`
    - Open drawer, fill in title "Integration Test Task", set priority to High, submit
    - Assert the new card appears in the To Do column
    - Assert `POST /tasks` was called with `{ priority: 10, status: 'todo', ... }`
    - _Requirements: 3.4, 3.5_

  - [x] 6.5 Write integration test — DELETE /tasks/:id
    - In `tests/tasks/integration.test.tsx`
    - After hydration, hover a task card and click the delete button
    - Assert the card is removed from the DOM immediately (optimistic)
    - Assert `DELETE /tasks/{id}` was called
    - _Requirements: 4.2, 4.3_

- [x] 7. Final checkpoint — verify all tests pass
  - Run `npm run test` (or `npx vitest --run`) and confirm zero failures.
  - Fix any type errors surfaced by strict TypeScript checking in the test files.
  - Ensure `npm run lint` reports no new errors.
  - Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for an MVP delivery.
- Task 1.1 is a prerequisite for property test 3.4 — do it first.
- Task 5.1 (exporting `TaskCard`) is a prerequisite for property test 3.5 and unit tests in 4.2.
- Task 2.1–2.2 (infrastructure) must complete before any test tasks run.
- MSW v2 API (`http.*`) is assumed; adjust if the installed version uses `rest.*`.
- The store-provider context pattern means unit tests should mock `@/store/store-provider`
  rather than trying to render real context; integration tests use the real Zustand store
  with MSW intercepting network calls.
- Property tests are tagged `// Feature: tasks-hub, Property N: ...` as specified in the design.

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["2.2", "5.1"] },
    { "id": 3, "tasks": ["3.1", "3.2", "3.4", "4.1", "4.2", "4.3", "4.4", "4.5", "6.1"] },
    { "id": 4, "tasks": ["3.3", "3.5", "6.2", "6.3", "6.4", "6.5"] }
  ]
}
```
