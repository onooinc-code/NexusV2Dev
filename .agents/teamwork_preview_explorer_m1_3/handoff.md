# Handoff Report: Phase 9 Property-Based Tests (Frontend)

## Observation
- **Task 14.1 (NxAiAnalysisModal Property 1)**: The component `components/NxAiAnalysisModal.tsx` contains 4 checkboxes controlling an `options` state object: `extract_topics`, `infer_persona`, `detect_emotion`, and `suggest_rules`. When "Run Analysis" is clicked, it sends this object to `apiClient.post('/contacts/{id}/analysis-runs', { options, scope, agent_id })`.
- **Task 14.2 (Contact360 Property 2)**: The page component `app/contacts/[id]/page.tsx` features a tab bar. When `activeTab` changes, a `useEffect` runs a `switch` statement to load data:
  - `timeline` and `notes` call store functions (`fetchContactTimeline`, `fetchContactNotes`).
  - `rules` calls `apiClient.get('/contacts/${contact.id}/reply-mode')`.
  - `analytics`, `identifiers`, `relationships`, `preferences`, and `aliases` call `apiClient.get('/contacts/${contact.id}/[tab_name]')`.
  - `topics` and `audit` currently just `break;` without making API calls (this aligns with uncompleted task 2.4).
- Existing PBTs in this codebase (e.g., `app/settings/__tests__/SeedsTab.property.test.tsx`) combine `fast-check` with `@testing-library/react` and `vitest` mocks. `vitest` and `fast-check` (`^3.23.2`) are installed and ready.

## Logic Chain
1. **Testing Property 1 (Checkbox Payload Alignment)**: 
   - A property test should generate an arbitrary state object: `fc.record({ extract_topics: fc.boolean(), ... })`.
   - Inside the test runner, mock `apiClient`. Render the modal, target the labels (e.g., `screen.getByLabelText(/Topic Extraction/i)`), and use `fireEvent.click` to sync the UI state to the generated state.
   - Click "Run Analysis" and assert that the `options` field inside `apiClient.post` matches the generated record exactly.

2. **Testing Property 2 (Tab Data-Loading Coverage)**:
   - Define valid tabs: `fc.constantFrom('timeline', 'analytics', 'notes', 'identifiers', 'relationships', 'preferences', 'aliases', 'rules', 'topics', 'audit')`.
   - Mock `useAppStore` and `apiClient` to intercept data requests without network overhead.
   - For Next.js 14 `use(params)`, render `<ContactDetailPage params={Promise.resolve({ id: '1' })} />` inside `<Suspense>`.
   - On each run, fire a click on the randomly selected tab button. Await `waitFor` and assert that the correct spy (`fetchContactTimeline` for 'timeline', `apiClient.get` for API-driven tabs) was called exactly once. This test will actively fail on `topics` and `audit` until task 2.4 is resolved.

## Caveats
- Rendering full page components inside `fast-check` loops (100 runs) can be resource-intensive. To prevent timeouts, mock out heavy child components (like `NxMessageViewer` and `NxRelationshipGraph`) inside the `ContactDetailPage` test, or drop `numRuns` slightly if it exceeds standard test budgets.
- Tasks like `topics` and `audit` are guaranteed to fail the property test currently, proving that the test correctly identifies missing API hookups in the `switch` statement.

## Conclusion
The frontend property-based tests should be implemented using `@testing-library/react` combined with `fast-check` to simulate user interactions and assert API/store integrations.

**Implementation Strategy:**
1. Create `components/__tests__/NxAiAnalysisModal.property.test.tsx`:
   - Mock `apiClient`.
   - Use `fc.record` for boolean toggle states.
   - Assert `apiClient.post` payload.
2. Create `app/contacts/__tests__/Contact360Tabs.property.test.tsx`:
   - Mock `useAppStore` and `apiClient`.
   - Mock heavy child components.
   - Use `fc.constantFrom` for valid tabs.
   - Click the tab and assert the expected mock invocation in `page.tsx`'s `useEffect`.

## Verification Method
- Write the tests as proposed.
- Run `npm run test -- --run` from the `Nexus-Frontend` directory.
- Verify that `NxAiAnalysisModal` tests pass.
- Verify that `Contact360Tabs` tests fail specifically for the `topics` and `audit` tabs. Fix the `switch` statement in `app/contacts/[id]/page.tsx` to call `loadTopics()` and `loadAuditEvents()`, then run tests again to confirm 100% pass rate.
