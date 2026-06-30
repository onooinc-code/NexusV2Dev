# Handoff Report: Phase 9 Frontend PBT - Milestone 1

## Overview
Analysis of the `Nexus-Frontend` codebase for implementing Property-Based Tests (PBT) for Milestone 1 (tasks 14.1 and 14.2) using `fast-check` and `vitest`.

## Observation
1. **14.1 NxAiAnalysisModal (Property 1)**:
   - `components/NxAiAnalysisModal.tsx` tracks state via `const [options, setOptions] = useState({ extract_topics: true, infer_persona: true, detect_emotion: true, suggest_rules: true });` (lines 22-27).
   - On submission, it sends this state directly: `await apiClient.post(\`/contacts/${contactId}/analysis-runs\`, { options, scope, agent_id: agentId });` (lines 51-55).
   - The UI labels wrap the checkboxes and text (e.g., `<label>...<input type="checkbox"/>...<span>Topic Extraction</span></label>`), making them accessible via `testing-library` using `getByLabelText`.
2. **14.2 Contact360 Tab Data-loading (Property 2)**:
   - `app/contacts/[id]/page.tsx` renders a tab bar and manages the current tab via `const [activeTab, setActiveTab] = useState(...)`.
   - Its `useEffect` (lines 333-367) delegates data-loading depending on the tab (e.g., `loadAnalytics()`).
   - **Crucial difference from requirements**: The requirements state to "assert the corresponding data-loading function is invoked exactly once in the useEffect." However, in `page.tsx`, the `topics` and `audit` tabs (among others) explicitly have `break;` inside the `switch (activeTab)` block. They *do not* invoke a data-loading function in the page's `useEffect`. Instead, their data-loading is delegated to child components (e.g., `NxTopicsViewer` fetches its data when mounted).
3. **PBT Pattern in Codebase**:
   - `tests/tasks/properties.test.tsx` demonstrates a working React testing pattern with `fast-check`: using `fc.assert(fc.property(...))` and calling `@testing-library/react`'s `cleanup()` at the end of each iteration to prevent DOM pollution.

## Logic Chain
- For **Task 14.1**, the test must verify that the UI state correctly binds to the payload. A `fast-check` record arbitrary (e.g., `fc.record({ extract_topics: fc.boolean(), ... })`) can be used to generate configuration permutations. Within each iteration, we can render the modal, use `@testing-library/user-event` to align the checkbox states with the generated configuration, submit the form, and assert against the `apiClient.post` mock.
- For **Task 14.2**, rigidly following the instruction to "assert the corresponding data-loading function is invoked exactly once in the useEffect" would fail because `topics` and `audit` intentionally load data via their components instead of the page. To fulfill the *intent* of Property 2 (data-loading coverage), the test should render `ContactDetailPage`, click the selected tab, and verify the resulting network request (mocked `apiClient.get`) or global store action (`fetchContactTimeline`, `fetchContactNotes`), which cohesively tests both page-level and component-level data fetches.
- Given both properties deal with UI rendering in Next.js/React, `vi.clearAllMocks()` and `cleanup()` must be invoked on every property iteration.

## Caveats
- Running `render` and simulating clicks 100 times per test (`numRuns: 100`) may be slow. If performance is a significant issue during the CI pipeline, the number of runs might need adjustment, or the `ContactDetailPage` component test might need to rely on shallow rendering/mocking child components (though doing so would abstract away the internal fetch logic we want to verify).

## Conclusion
- **Implementation Strategy for 14.1**: 
  Create `tests/components/NxAiAnalysisModal.pbt.test.tsx`. Use `fc.asyncProperty` with an object containing 4 booleans. Mount the component, query the checkboxes by their label text (e.g., `/Topic Extraction/i`), toggle them if they differ from the generated values (they start as `true`), click "Run Analysis", and `expect(apiClient.post)` to have been called with the exact generated options object.
- **Implementation Strategy for 14.2**: 
  Create `tests/components/Contact360Tabs.pbt.test.tsx`. Use `fc.asyncProperty` with `fc.constantFrom(tabNames)`. Render `ContactDetailPage`, click the tab using `screen.getByRole('button', { name: tabName })`, and use a predefined mapping to check that the correct API endpoint (e.g., `/contacts/1/analytics`) or mocked store method (e.g., `fetchContactTimeline`) was invoked exactly once.

## Verification Method
1. The implementer should write the tests in `tests/components/` as described.
2. Run `npx vitest run tests/components/NxAiAnalysisModal.pbt.test.tsx` and `npx vitest run tests/components/Contact360Tabs.pbt.test.tsx`.
3. The tests must pass with 100 iterations without leaving active handles or polluting the DOM/mocks across iterations.
