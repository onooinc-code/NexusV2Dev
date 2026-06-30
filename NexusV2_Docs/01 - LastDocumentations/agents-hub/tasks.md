# Implementation Plan: Agents Hub — Gap Closure

## Overview

The core AgentsHub feature is fully implemented (Tasks 1–7 complete). This plan reflects that state
and adds new tasks for six remaining gaps: missing `max_tokens` and `persona_id` fields on the
`Agent` interface, the hardcoded drawer title, the incomplete "Refresh Data" handler, and the
missing property-based and integration tests called for in the design.

## Tasks

- [x] 1. Add `guidelines` field to `Agent` interface and map it in `hydrateAgents()` (Gap 4)
  - [x] 1.1 Add `guidelines?: string` to the `Agent` interface in `store/index.ts`
    - _Requirements: 1.8_
  - [x] 1.2 Map `guidelines` from the backend response inside `hydrateAgents()`
    - `guidelines: a.settings?.guidelines ?? a.guidelines ?? ''`
    - _Requirements: 1.8_

- [x] 2. Add `updateAgent(id, data)` store action
  - [x] 2.1 Declare `updateAgent` in the `GlobalState` interface in `store/index.ts`
    - _Requirements: 1.8_
  - [x] 2.2 Implement `updateAgent` in the store with optimistic update + rollback
    - _Requirements: 1.8_

- [x] 3. Implement agent detail drawer in `AgentsTab`
  - [x] 3.1 Add local state for drawer and edit form to `AgentsTab`
    - _Requirements: 1.6, 1.8_
  - [x] 3.2 Wire card click to populate the form and open the drawer
    - _Requirements: 1.6, 1.8_
  - [x] 3.3 Render the `NxDrawer` with form fields (name, temperature, max_tokens, guidelines, persona)
    - _Requirements: 1.8_
  - [x] 3.4 Wire drawer footer actions (Save Changes, Reset to Defaults)
    - _Requirements: 1.8, 1.9_

- [x] 4. Implement quarantine action in the agent detail drawer
  - [x] 4.1 Add `quarantineReason` and `showQuarantineConfirm` local state to `AgentsTab`
    - _Requirements: 1.10_
  - [x] 4.2 Render inline quarantine confirmation UI in the drawer footer
    - _Requirements: 1.10_

- [x] 5. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement persona edit mode in `PersonasTab`
  - [x] 6.1 Add `editingPersona` local state and wire `updatePersona` from store
    - _Requirements: 2.10_
  - [x] 6.2 Render the `Edit2` icon button on persona card hover
    - _Requirements: 2.10_
  - [x] 6.3 Update form header and submit handler for edit mode
    - _Requirements: 2.10_
  - [x] 6.4 Update the Cancel button to clear edit state
    - _Requirements: 2.10_

- [x] 7. Final checkpoint — Ensure all tests pass, ask the user if questions arise.

- [x] 8. Add `max_tokens` and `persona_id` to `Agent` interface and hydration mapping
  - [x] 8.1 Add `max_tokens` and `persona_id` fields to the `Agent` interface in `store/index.ts`
    - Add `max_tokens?: number` and `persona_id?: string | null` to the `Agent` interface after `guidelines`
    - These fields are required so the drawer edit form can read real values from the agent instead of always defaulting to `2048` / `null`
    - _Requirements: 1.8_

  - [x] 8.2 Map `max_tokens` and `persona_id` from the backend response in `hydrateAgents()`
    - Add `max_tokens: a.settings?.max_tokens ?? a.max_tokens ?? 2048` to the `.map()` call
    - Add `persona_id: a.persona_id ?? a.settings?.persona_id ?? null` to the `.map()` call
    - _Requirements: 1.8_

  - [x] 8.3 Populate `max_tokens` and `persona_id` from the agent object when opening the drawer in `AgentsTab`
    - In the card `onClick` handler, replace the hardcoded `max_tokens: 2048` and `persona_id: null` with `max_tokens: a.max_tokens ?? 2048` and `persona_id: a.persona_id ?? null`
    - _Requirements: 1.8_

- [x] 9. Fix `NxDrawer` title to use the selected agent's name
  - [x] 9.1 Update the `NxDrawer` `title` prop in `AgentsTab` to use the selected agent's name
    - Find the selected agent: `const selectedAgent = agents.find(a => a.id === selectedAgentId)`
    - Change `title="Agent Details"` to `title={selectedAgent?.name ?? 'Agent Details'}`
    - _Requirements: 1.8_

- [x] 10. Fix "Refresh Data" button to hydrate all data slices in parallel
  - [x] 10.1 Update the `onClick` handler of the "Refresh Data" button in `app/agents/page.tsx`
    - Destructure `hydratePersonas` and `hydrateMCPServers` from `useGlobalStore` alongside `hydrateAgents`
    - Replace `onClick={() => hydrateAgents()}` with `onClick={() => { hydrateAgents(); hydratePersonas(); hydrateMCPServers(); }}`
    - All three calls fire in parallel (no `await` chaining) per the design's performance guidance
    - _Requirements: 1.7, 6.4_

- [x] 11. Checkpoint — Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement property-based tests for stats panel invariants
  - [x] 12.1 Create test file `app/agents/__tests__/stats-panel.test.ts` and set up fast-check
    - Install `fast-check` if not already present (`npm install --save-dev fast-check`)
    - Import `fc` from `fast-check` and define an `agentArbitrary` generator matching the `Agent` shape
    - _Requirements: 1.4_

  - [x]* 12.2 Write property test for Property 1: active count never exceeds total agents
    - **Property 1: Stats panel active count never exceeds total agents**
    - **Validates: Requirements 1.4**
    - `fc.property(fc.array(agentArbitrary), agents => activeCount(agents) <= agents.length)`
    - _Requirements: 1.4_

  - [x]* 12.3 Write property test for Property 2: quarantined count equals agents with status 'error'
    - **Property 2: Quarantined count equals agents with status 'error'**
    - **Validates: Requirements 1.4**
    - Extract `computeQuarantinedCount` helper from `AgentsTab` stats panel logic and test it
    - `fc.property(fc.array(agentArbitrary), agents => computeQuarantinedCount(agents) === agents.filter(a => a.status === 'error').length)`
    - _Requirements: 1.4_

- [x] 13. Implement property-based tests for persona form validation
  - [x] 13.1 Extract `validatePersonaForm` and `validateTemperature` pure helpers from `PersonasTab`
    - Move validation logic into `app/agents/utils/validation.ts` so it can be tested in isolation
    - Export `validatePersonaForm({ name, system_prompt }): { valid: boolean }` and `validateTemperature(value: number): { valid: boolean }`
    - Update `PersonasTab` to import and use these helpers
    - _Requirements: 2.4_

  - [x]* 13.2 Write property test for Property 3: form blocked when name or system_prompt is empty
    - **Property 3: Persona form is blocked when name or system_prompt is empty**
    - **Validates: Requirements 2.4**
    - `fc.property(fc.string(), fc.string(), (name, system_prompt) => validatePersonaForm({ name, system_prompt }).valid === (name.trim().length > 0 && system_prompt.trim().length > 0))`
    - _Requirements: 2.4_

  - [x]* 13.3 Write property test for Property 4: temperature outside [0, 2] is rejected
    - **Property 4: Temperature values outside [0, 2] must be rejected**
    - **Validates: Requirements 2.4**
    - Test both below-range (`< 0`) and above-range (`> 2`) float values
    - `fc.property(fc.oneof(fc.float({ min: -100, max: -0.01 }), fc.float({ min: 2.01, max: 100 })), t => validateTemperature(t).valid === false)`
    - _Requirements: 2.4_

- [x] 14. Implement property-based test for playground button state
  - [x]* 14.1 Write property test for Property 5: playground buttons disabled unless agent and prompt are set
    - **Property 5: Playground action buttons are disabled unless agent and prompt are both set**
    - **Validates: Requirements 5.4**
    - Extract `arePlaygroundButtonsEnabled(agentId, taskInput)` helper from `PlaygroundTab`
    - `fc.property(fc.option(fc.uuid()), fc.string(), (agentId, taskInput) => arePlaygroundButtonsEnabled(agentId, taskInput) === (agentId !== null && taskInput.trim().length > 0))`
    - _Requirements: 5.4_

- [x] 15. Implement integration tests for AgentsTab
  - [x]* 15.1 Write integration test: page renders and `hydrateAgents()` is called once on mount
    - Create `app/agents/__tests__/agents-page.test.tsx`
    - Use React Testing Library + MSW (or `jest.fn()` store mock) to verify `hydrateAgents` fires exactly once on mount
    - _Requirements: 1.1_

  - [x]* 15.2 Write integration test: drawer opens on card click and closes on save
    - Render `AgentsTab` with a mocked store containing at least one agent
    - Click a card, assert drawer is visible and fields are populated
    - Click "Save Changes", assert `updateAgent` was called with the correct payload
    - _Requirements: 1.6, 1.8_

  - [x]* 15.3 Write integration test: quarantine flow — confirm button calls `quarantineAgent`
    - Open drawer, click "Quarantine Agent", enter a reason, click "Confirm Quarantine"
    - Assert `quarantineAgent(id, reason)` was called and drawer closes
    - _Requirements: 1.10_

- [x] 16. Implement integration tests for PersonasTab
  - [x]* 16.1 Write integration test: create → display → delete flow for personas
    - Create `app/agents/__tests__/personas-tab.test.tsx`
    - Mock store: render empty personas list, submit the creation form, assert `createPersona` called; render card, click delete, assert `deletePersona` called
    - _Requirements: 2.4, 2.7, 2.9_

  - [x]* 16.2 Write integration test: edit mode pre-fills form fields from selected persona
    - Click the edit icon on a persona card, assert the form fields match the persona's values
    - Submit the form, assert `updatePersona(id, formData)` is called
    - _Requirements: 2.10_

- [x] 17. Final checkpoint — Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Tasks 1–7 are fully implemented and verified against source code
- Task 8 is a data-layer fix: `max_tokens` and `persona_id` must flow from backend → store → drawer form
- Task 9 is a one-line UI fix to the drawer title
- Task 10 is a one-line fix to the Refresh Data button handler in `page.tsx`
- Tasks 12–14 require extracting pure helper functions before testing; task 13.1 does this for persona validation
- fast-check must be available; check `package.json` before installing
- All property tests reference specific design document properties (Properties 1–5)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["8.1"] },
    { "id": 1, "tasks": ["8.2", "9.1", "10.1"] },
    { "id": 2, "tasks": ["8.3", "12.1", "13.1"] },
    { "id": 3, "tasks": ["12.2", "12.3", "13.2", "13.3", "14.1"] },
    { "id": 4, "tasks": ["15.1", "15.2", "15.3", "16.1", "16.2"] }
  ]
}
```
