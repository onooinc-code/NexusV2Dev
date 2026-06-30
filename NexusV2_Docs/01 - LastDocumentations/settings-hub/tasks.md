# Implementation Plan: Settings Hub

## Overview

The core `app/settings/page.tsx` and `ApiTesterPanel` are already functional. This plan covers:
- Extracting shared type definitions into a dedicated types file
- Splitting the monolithic page into discrete tab components
- Extracting `SettingControl`
- Fixing two known bugs (masked credential re-fetch guard, `agentPausedEnabled` initialization)
- Adding ARIA accessibility to the tab bar
- Wiring up the test framework
- Writing property-based and example-based tests for all 8 correctness properties and the full suite of unit/integration cases

---

## Tasks

### Phase 1: Code Organization & Refactoring

- [x] 1. Extract shared type definitions to `app/settings/types.ts`
  - [x] 1.1 Create `app/settings/types.ts` and export all shared interfaces
    - Export `SettingEntry`, `GroupedSettings`, `TabType`, `HealthStatus`, `Seed`
    - Copy exact definitions from `page.tsx` with no logic changes
    - _Requirements: 1.5, 1.6, 3.4, 5.4_

  - [x] 1.2 Update `app/settings/page.tsx` to import types from `./types`
    - Remove the five inline interface/type declarations
    - Add `import type { SettingEntry, GroupedSettings, TabType, HealthStatus, Seed } from './types'`
    - Verify `page.tsx` compiles cleanly (`tsc --noEmit`) after the change
    - _Requirements: 1.5, 1.6, 3.4, 5.4_

- [x] 2. Extract `SettingControl` component
  - [x] 2.1 Create `app/settings/components/SettingControl.tsx`
    - Accept `{ setting: SettingEntry; value: any; onChange: (key: string, value: any) => void }` as props
    - Move the complete `renderSettingControl` branching logic into this component verbatim
    - Import `NxSwitch`, `NxInput` from `@/components`; apply the same `textarea` JSX for `json`/`text`
    - Export as a named export `SettingControl`
    - _Requirements: 1.6_

  - [x] 2.2 Update `page.tsx` to use `<SettingControl />` instead of `renderSettingControl()`
    - Import `SettingControl` from `./components/SettingControl`
    - Replace every `{renderSettingControl(setting)}` call in the General tab and Integrations tab with `<SettingControl setting={setting} value={editedValues[setting.key]} onChange={handleValueChange} />`
    - Delete the `renderSettingControl` function from `page.tsx`
    - _Requirements: 1.6_

- [x] 3. Extract tab components
  - [x] 3.1 Create `app/settings/components/GeneralTab.tsx`
    - Accept `GeneralTabProps`: `{ groupedSettings: GroupedSettings; editedValues: Record<string, any>; loading: boolean; onValueChange: (key: string, value: any) => void }`
    - Move all JSX currently inside the `{activeTab === 'general' && (...)}` block into this component
    - Use `<SettingControl />` for each setting entry
    - Filter groups: exclude keys that start with `"integrations"` or equal `"security"`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [x] 3.2 Create `app/settings/components/IntegrationsTab.tsx`
    - Accept `IntegrationsTabProps`: `{ groupedSettings: GroupedSettings; editedValues: Record<string, any>; loading: boolean; showMaskedCredentials: Record<string, boolean>; maskedValues: Record<string, string>; editingEncrypted: Record<string, boolean>; onValueChange: (key: string, value: any) => void; onToggleMasked: (key: string) => void; onToggleEdit: (key: string) => void }`
    - Move all JSX from the `{activeTab === 'integrations' && (...)}` block into this component
    - Retain the Shield icon, Show/Hide button, Edit/Cancel Edit button, and masked value display
    - Use `<SettingControl />` for non-encrypted settings
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9_

  - [x] 3.3 Create `app/settings/components/HealthTab.tsx`
    - Accept `HealthTabProps`: `{ healthStatus: HealthStatus | null; isLoadingHealth: boolean; onRefresh: () => void }`
    - Move all JSX from the `{activeTab === 'health' && (...)}` block into this component
    - Preserve status color mapping: `healthy` → emerald, `degraded` → yellow, other → red
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 3.4 Create `app/settings/components/SeedsTab.tsx`
    - Accept `SeedsTabProps`: `{ seeds: Seed[]; isLoadingSeeds: boolean; saving: boolean; onRunSeed: (id: string) => void }`
    - Move all JSX from the `{activeTab === 'seeds' && (...)}` block into this component
    - Retain the permanent warning banner, spinner, empty state, and per-seed cards
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [x] 3.5 Create `app/settings/components/AdvancedTab.tsx`
    - Accept `AdvancedTabProps`: `{ agentPausedEnabled: boolean; saving: boolean; onToggleAgentPause: () => void; onFactoryReset: () => void }`
    - Move all JSX from the `{activeTab === 'advanced' && (...)}` block into this component
    - Retain the Danger Zone card, Global Agent Pause card, and Clear Cache card
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

  - [x] 3.6 Update `app/settings/page.tsx` to render extracted tab components
    - Import `GeneralTab`, `IntegrationsTab`, `HealthTab`, `SeedsTab`, `AdvancedTab`
    - Replace each inline tab JSX block with the corresponding component and its props
    - Remove all tab-related inline JSX fragments from `page.tsx` (file should become significantly shorter)
    - _Requirements: 7.1, 7.2_

- [ ] 4. Checkpoint — verify page compiles and renders correctly
  - Run `tsc --noEmit`; zero type errors. Visually verify all six tabs still function in the browser.

- [ ] 5. Fix bug: masked credential re-fetch guard
  - [ ] 5.1 Add fetch guard to `loadMaskedCredential` call in `IntegrationsTab` (or `page.tsx`)
    - In the Show/Hide `onClick` handler, add condition: only call `loadMaskedCredential(key)` if `!maskedValues[key]`
    - The guard prevents repeated `GET /settings/{key}/masked` calls when the value is already cached
    - Before fix, the existing code calls `loadMaskedCredential` every time the Show button is clicked
    - _Requirements: 2.4_

- [ ] 6. Fix bug: `agentPausedEnabled` initialization from server
  - [ ] 6.1 Load initial agent pause state from the settings payload on mount
    - After `loadSettings()` resolves and `groupedSettings` is populated, check if a setting key representing agent pause state exists (e.g., look for a `boolean` setting in the `advanced` or `system` group matching agent pause)
    - If the backend setting exists, initialize `agentPausedEnabled` from `editedValues[key]`
    - If no dedicated key exists, call `GET /settings/system/agent-pause` (or the appropriate endpoint) on mount to retrieve the current pause state and `setAgentPausedEnabled` from the response
    - Document the chosen approach with an inline comment
    - _Requirements: 6.2, 6.3_

- [ ] 7. Add ARIA accessibility to tab navigation
  - [ ] 7.1 Update the tab navigation bar in `page.tsx` with proper ARIA roles
    - Wrap the tab button container `<div>` with `role="tablist"` and `aria-label="Settings sections"`
    - Add `role="tab"` to each tab `<button>`
    - Add `aria-selected={activeTab === tab}` to each tab button
    - Add `aria-controls={`panel-${tab}`}` to each tab button
    - Add `id={`tab-${tab}`}` to each tab button
    - Add `role="tabpanel"`, `id={`panel-${tab}`}`, and `aria-labelledby={`tab-${tab}`}` to each tab content wrapper
    - _Requirements: 7.2, 7.3_

- [ ] 8. Set up the test framework (Jest + React Testing Library + fast-check)
  - [ ] 8.1 Install test dependencies and configure Jest for Next.js
    - Install exact versions: `jest@29`, `jest-environment-jsdom@29`, `@testing-library/react@16`, `@testing-library/user-event@14`, `@testing-library/jest-dom@6`, `fast-check@3`, `ts-jest@29`, `@types/jest@29`
    - Create `jest.config.ts` at project root using `next/jest` transformer preset so that path aliases (`@/`) resolve correctly
    - Create `jest.setup.ts` that imports `@testing-library/jest-dom`
    - Add `"test": "jest --runInBand"` and `"test:run": "jest --runInBand --passWithNoTests"` to `package.json` scripts
    - Verify `npx jest --passWithNoTests` exits cleanly (no config errors)
    - _Requirements: (infrastructure prerequisite for all test tasks)_

- [ ] 9. Checkpoint — verify test framework boots
  - Run `npm run test:run`; ensure zero failures before writing any test files.

- [ ] 10. Write property-based tests — P1 through P4
  - [ ] 10.1 Write property test for P1: Type-to-control mapping invariant
    - **Property 1: Type-to-control mapping invariant**
    - **Validates: Requirements 1.6**
    - File: `__tests__/settings/SettingControl.property.test.tsx`
    - Tag comment: `// Feature: settings-hub, Property 1: Type-to-control mapping invariant`
    - Use `fc.constantFrom('boolean','integer','json','text','string')` for `setting.type`
    - Use `fc.record` to generate complete `SettingEntry` objects with arbitrary `key`, `value`, and `description`
    - Render `<SettingControl />` for each generated input
    - Assert: `boolean` → an element with role `checkbox` is present; `integer` → an `input[type=number]`; `json`/`text` → a `textarea`; `string` → an `input` (not number)
    - Assert: no render throws; no unknown type maps to a wrong element

  - [ ] 10.2 Write property test for P2: General tab group filter invariant
    - **Property 2: General tab group filter invariant**
    - **Validates: Requirements 1.7**
    - File: `__tests__/settings/GeneralTab.property.test.tsx`
    - Tag comment: `// Feature: settings-hub, Property 2: General tab group filter invariant`
    - Use `fc.dictionary(fc.string(), fc.array(fc.record({...})))` to generate arbitrary `GroupedSettings` objects; inject `"integrations"`, `"integrations_extra"`, and `"security"` keys with non-empty setting arrays
    - Render `<GeneralTab />` with the generated `groupedSettings`
    - Assert: no rendered card's group label starts with `"integrations"` or equals `"security"`
    - Assert: all other group keys from the input appear in the rendered output

  - [ ] 10.3 Write property test for P3: Bulk save payload invariant
    - **Property 3: Bulk save payload invariant**
    - **Validates: Requirements 1.9**
    - File: `__tests__/settings/bulkSave.property.test.ts`
    - Tag comment: `// Feature: settings-hub, Property 3: Bulk save payload invariant`
    - Use `fc.dictionary(fc.string({ minLength: 1 }), fc.jsonValue())` to generate arbitrary `editedValues` maps
    - Mock `apiClient.put` to capture the call arguments
    - Invoke `handleSaveSettings` (extracted as a testable helper or via component interaction) with each generated map
    - Assert: the captured body is `{ settings: Object.entries(editedValues).map(([key, value]) => ({ key, value })) }`
    - Assert: `settings` array length equals `Object.keys(editedValues).length`
    - Assert: no key is omitted, no key is duplicated, no value is transformed

  - [ ] 10.4 Write property test for P4: Masked credential fetch invariant
    - **Property 4: Masked credential fetch invariant**
    - **Validates: Requirements 2.4**
    - File: `__tests__/settings/maskedCredential.property.test.ts`
    - Tag comment: `// Feature: settings-hub, Property 4: Masked credential fetch invariant`
    - Use `fc.string({ minLength: 1 })` to generate arbitrary setting `key` strings
    - Mock `apiClient.get` returning `{ data: { data: { masked: 'sk-***' } } }`; track call count per key
    - Simulate: toggle `showMaskedCredentials[key]` from `false` → `true` (first show)
    - Assert: `GET /settings/{key}/masked` is called exactly once
    - Simulate: toggle back `true` → `false`, then `false` → `true` again (second show)
    - Assert: `GET /settings/{key}/masked` is NOT called again (guard active because `maskedValues[key]` is already populated)
    - Assert: total call count for any given key never exceeds 1

- [ ] 11. Write property-based tests — P5 through P8
  - [ ] 11.1 Write property test for P5: Agent pause state invariant
    - **Property 5: Agent pause state invariant**
    - **Validates: Requirements 6.3**
    - File: `__tests__/settings/agentPause.property.test.ts`
    - Tag comment: `// Feature: settings-hub, Property 5: Agent pause state invariant`
    - Use `fc.boolean()` to generate arbitrary `enabled` values for the mock API response
    - Mock `apiClient.post('/settings/system/agent-pause')` to return `{ data: { data: { enabled: generated_bool } } }`
    - Invoke `handleToggleAgentPause()` for each generated boolean
    - Assert: `agentPausedEnabled` is set to exactly the boolean returned by the server — not the local pre-request negation
    - Assert: when the API call fails, `agentPausedEnabled` retains its pre-request value

  - [ ] 11.2 Write property test for P6: API tester status color invariant
    - **Property 6: API tester status color invariant**
    - **Validates: Requirements 4.6**
    - File: `__tests__/settings/ApiTesterPanel.property.test.ts`
    - Tag comment: `// Feature: settings-hub, Property 6: API tester status color invariant`
    - Extract `getStatusColor` as a standalone exported function from `ApiTesterPanel.tsx`
    - Use `fc.integer({ min: -100, max: 999 })` plus `fc.constant(undefined)` to generate arbitrary status inputs
    - Assert: `undefined` → `"text-gray-400"`
    - Assert: `200 ≤ s < 300` → `"text-green-400"` exclusively
    - Assert: `300 ≤ s < 400` → `"text-blue-400"` exclusively
    - Assert: `400 ≤ s < 500` → `"text-yellow-400"` exclusively
    - Assert: `s ≥ 500` → `"text-red-400"` exclusively
    - Assert: no integer maps to more than one color class
    - Assert: negative integers and zero map to `"text-red-400"` or `"text-gray-400"` (whichever the implementation specifies — document and lock the behavior)

  - [ ] 11.3 Write property test for P7: Save button visibility invariant
    - **Property 7: Save button visibility invariant**
    - **Validates: Requirements 7.6**
    - File: `__tests__/settings/saveButton.property.test.ts`
    - Tag comment: `// Feature: settings-hub, Property 7: Save button visibility invariant`
    - Use `fc.constantFrom('general','integrations','health','api-tester','seeds','advanced')` for `activeTab`
    - Render the save button footer section (or the full `SettingsPage` with a controlled tab) for each generated `activeTab`
    - Assert: Save Settings and Reload From Server buttons are in the DOM when `activeTab` is `'general'` or `'integrations'`
    - Assert: both buttons are absent from the DOM for all other four tab values

  - [ ] 11.4 Write property test for P8: Seeder card rendering invariant
    - **Property 8: Seeder card rendering invariant**
    - **Validates: Requirements 5.4**
    - File: `__tests__/settings/SeedsTab.property.test.tsx`
    - Tag comment: `// Feature: settings-hub, Property 8: Seeder card rendering invariant`
    - Use `fc.array(fc.record({ id: fc.string({ minLength: 1 }), name: fc.string({ minLength: 1 }), description: fc.string(), class: fc.string(), data_count: fc.string() }), { minLength: 1, maxLength: 20 })` to generate arbitrary `Seed[]`
    - Render `<SeedsTab seeds={generated} isLoadingSeeds={false} saving={false} onRunSeed={jest.fn()} />`
    - Assert: the number of rendered "Run Seeder" buttons equals `seeds.length` (one card per seed, no omissions or duplicates)
    - Assert: each seed's `name`, `description`, and `"Creates: {data_count}"` text appears in the output

- [ ] 12. Checkpoint — all property tests pass
  - Run `npm run test:run`; all 8 property test suites must pass. Ask the user if questions arise.

- [x] 13. Write example-based unit tests
  - [x] 13.1 Set up shared test fixtures and mocks
    - Create `__tests__/settings/fixtures.ts` with reusable mock data: `mockGroupedSettings`, `mockHealthStatus`, `mockSeeds`, `mockEncryptedSetting`
    - Create mock for `@/lib/api/client` using `jest.mock`
    - Create mock for `AppLayout` that renders `{children}` directly (avoids router/layout setup)
    - _Requirements: (infrastructure prerequisite for unit test tasks)_

  - [x] 13.2 Write unit tests for `SettingControl`
    - Test file: `__tests__/settings/SettingControl.test.tsx`
    - Test: `boolean` type renders `NxSwitch` with `checked` reflecting the value prop
    - Test: `integer` type renders an `<input type="number">`
    - Test: `json` type renders a `<textarea>`
    - Test: `text` type renders a `<textarea>`
    - Test: `string` type renders an `<input>` (not number type)
    - Test: `onChange` is called with the correct key and converted value when input changes
    - _Requirements: 1.6_

  - [x] 13.3 Write unit tests for `GeneralTab`
    - Test file: `__tests__/settings/GeneralTab.test.tsx`
    - Test: loading state renders "Loading settings…" text
    - Test: empty `groupedSettings` renders "No settings are available…" message
    - Test: `integrations` group is excluded from rendered cards
    - Test: `security` group is excluded from rendered cards
    - Test: non-excluded groups each render a card with the group name and key count
    - _Requirements: 1.2, 1.3, 1.4, 1.7_

  - [x] 13.4 Write unit tests for `IntegrationsTab`
    - Test file: `__tests__/settings/IntegrationsTab.test.tsx`
    - Test: loading state renders "Loading integrations…" text
    - Test: empty integrations renders "No integrations available." message
    - Test: encrypted setting renders the Shield icon
    - Test: Show button triggers `onToggleMasked` with the correct key
    - Test: masked value text is visible when `showMaskedCredentials[key]=true` and `maskedValues[key]` is populated and `editingEncrypted[key]=false`
    - Test: Edit button triggers `onToggleEdit` with the correct key
    - Test: password input is visible when `editingEncrypted[key]=true`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 13.5 Write unit tests for `HealthTab`
    - Test file: `__tests__/settings/HealthTab.test.tsx`
    - Test: loading state renders spinner and "Loading health status…"
    - Test: null `healthStatus` renders "No health data available."
    - Test: `status === 'healthy'` banner has emerald color class
    - Test: `status === 'degraded'` banner has yellow color class
    - Test: unknown status string banner has red color class
    - Test: each `checks` entry renders its own card with the service name and OK/ERROR badge
    - _Requirements: 3.2, 3.4, 3.5, 3.6_

  - [x] 13.6 Write unit tests for `SeedsTab`
    - Test file: `__tests__/settings/SeedsTab.test.tsx`
    - Test: loading state renders spinner and "Loading seeders…"
    - Test: empty seeds array renders "No seeders available."
    - Test: warning banner is always visible (present in both loading and populated states)
    - Test: each seed renders name, description, and "Creates: {data_count}" text
    - Test: "Run Seeder" button calls `onRunSeed` with the correct seed id
    - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.7_

  - [x] 13.7 Write unit tests for `AdvancedTab`
    - Test file: `__tests__/settings/AdvancedTab.test.tsx`
    - Test: Danger Zone card is always rendered
    - Test: `agentPausedEnabled=false` → button label is "Pause Agents" and status text is "✓ RUNNING"
    - Test: `agentPausedEnabled=true` → button label is "Resume Agents" and status text is "⚠️ PAUSED"
    - Test: clicking agent pause button calls `onToggleAgentPause`
    - Test: clicking Reset Cache button calls `onFactoryReset`
    - Test: both action buttons are disabled when `saving=true`
    - _Requirements: 6.1, 6.2, 6.4, 6.5, 6.6, 6.7_

  - [x] 13.8 Write unit tests for `ApiTesterPanel`
    - Test file: `__tests__/settings/ApiTesterPanel.test.tsx`
    - Test: body tab shows "Body is usually ignored for GET" warning when method is GET
    - Test: body tab shows warning when method is DELETE
    - Test: warning is absent when method is POST, PUT, or PATCH
    - Test: empty URL triggers error state without calling `apiClient.post`
    - Test: pressing Enter in the URL field calls `handleSend`
    - Test: response panel shows status code and latency after a successful send
    - Test: error panel is shown when `apiClient.post` rejects
    - _Requirements: 4.4, 4.5, 4.6, 4.8, 4.9_

- [x] 14. Checkpoint — all unit tests pass
  - Run `npm run test:run`; all property and unit test suites must pass. Ask the user if questions arise.

- [x] 15. Write integration tests
  - [x] 15.1 Write integration test: settings page full load and save cycle
    - Mount `SettingsPage` with mocked `apiClient`; mock `GET /settings/grouped` returning `mockGroupedSettings`
    - Assert the grouped data renders in the General tab
    - Change a setting value via user interaction
    - Click "Save Settings"
    - Assert `PUT /settings/bulk` is called with a `settings` array containing the modified entry
    - Assert `GET /settings/grouped` is called again after save (re-sync)
    - _Requirements: 1.1, 1.8, 1.9, 1.11_

  - [x] 15.2 Write integration test: Health tab auto-load on tab switch
    - Mount `SettingsPage`; mock `GET /monitoring/health`
    - Click the "Health & Diagnostics" tab button
    - Assert `GET /monitoring/health` is called exactly once per navigation to that tab
    - _Requirements: 7.4_

  - [x] 15.3 Write integration test: Seeds tab auto-load on tab switch
    - Mount `SettingsPage`; mock `GET /settings/seeds` returning `mockSeeds`
    - Click the "Database Seeds" tab button
    - Assert `GET /settings/seeds` is called exactly once per navigation
    - Assert seed cards are rendered after load
    - _Requirements: 7.5_

  - [x] 15.4 Write integration test: seeder run confirmation guard
    - Mount `SettingsPage` on the Seeds tab
    - Mock `window.confirm` returning `false`
    - Click a "Run Seeder" button
    - Assert `POST /settings/seeds/{id}/run` is NOT called when user cancels
    - Mock `window.confirm` returning `true`; click again
    - Assert `POST /settings/seeds/{id}/run` IS called
    - _Requirements: 5.5_

  - [x] 15.5 Write integration test: factory reset confirmation guard
    - Mount `SettingsPage` on the Advanced tab
    - Mock `window.confirm` returning `false`; click "Reset Cache"
    - Assert `POST /logs/clear` is NOT called
    - Mock `window.confirm` returning `true`; click again
    - Assert `POST /logs/clear` IS called, then `GET /settings/grouped` is called (reload)
    - Assert success message "System cache cleared and settings refreshed from backend." is displayed
    - _Requirements: 6.7, 6.8_

- [x] 16. Final checkpoint — full test suite passes
  - Run `npm run test:run`; all suites (property tests, unit tests, integration tests) must pass. Ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Task 1 (type extraction) and Task 2 (SettingControl extraction) are prerequisites for Task 3 (tab extraction)
- Task 8 (test framework setup) is a prerequisite for all test tasks (10–15)
- Task 5 (masked credential guard) must be applied to `IntegrationsTab` after Task 3.2 is complete
- Task 6 (agent pause init) — if no dedicated endpoint exists, initialize from the `advanced`/`system` settings group loaded by `loadSettings()`; document the decision in the code
- `getStatusColor` in `ApiTesterPanel.tsx` must be exported (not just module-local) before P6 property tests can import it
- After Task 3, run `tsc --noEmit` to confirm all tab components are type-clean before writing tests
- Property tests must run a minimum of 100 iterations each (fast-check default is sufficient)
- Each property test file must contain the tag comment `// Feature: settings-hub, Property N: {text}` at the top

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "8.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["2.1"] },
    { "id": 3, "tasks": ["2.2"] },
    { "id": 4, "tasks": ["3.1", "3.2", "3.3", "3.4", "3.5"] },
    { "id": 5, "tasks": ["3.6", "5.1", "7.1"] },
    { "id": 6, "tasks": ["6.1", "13.1"] },
    { "id": 7, "tasks": ["10.1", "10.2", "10.3", "10.4", "11.1", "11.2", "11.3", "11.4", "13.2", "13.3", "13.4", "13.5", "13.6", "13.7", "13.8"] },
    { "id": 8, "tasks": ["15.1", "15.2", "15.3", "15.4", "15.5"] }
  ]
}
```
