# Task: Implement Milestone 2 - Topbar & Page Wiring

## Objective
Implement Tasks 10.2, 10.3, 10.4, and the topbar tests from 10.5.

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Context & Strategy
The Explorer has analyzed the requirements and determined the following:

- **Task 10.2**: 
  - Update `NxMemoryMaintenanceModal.tsx` interface to accept `contactId?: number; scope?: 'global' | 'contact'`. If `scope === 'global'`, ensure it makes the correct API call (maybe omitting contactId or using a global endpoint). 
  - In `app/contacts/page.tsx`, add `isMaintenanceModalOpen` state. Render `<NxMemoryMaintenanceModal isOpen={isMaintenanceModalOpen} onClose={() => setIsMaintenanceModalOpen(false)} scope="global" />`. Pass `onMaintenanceClick` down to `ContactHubTopbarControls`.

- **Task 10.3**: 
  - In `NxImportModal.tsx`, port the contact `<select>` logic from `page.tsx`. Map contacts from `useAppStore` or pass them as props. Make its `contactId` prop optional.
  - In `app/contacts/page.tsx`, remove the inline import drawer (lines 434-536 or so). Add `isImportModalOpen` state and render `<NxImportModal isOpen={isImportModalOpen} onClose={() => setIsImportModalOpen(false)} />`. Pass `onImportClick` to `ContactHubTopbarControls`.

- **Task 10.4**: 
  - Update `ContactHubStats` interface in both `page.tsx` and `ContactHubTopbarControls.tsx` to include `active_import_jobs?: number;` and `active_maintenance_jobs?: number;`. 
  - In `ContactHubTopbarControls.tsx`, update the queue status indicator next to the `<Activity />` icon to also render pills/indicators for imports and maintenance if their counts are greater than 0.

- **Task 10.5**: 
  - Create `tests/components/ContactHubTopbarControls.test.tsx`. 
  - Render `ContactHubTopbarControls` with mocked `onMaintenanceClick` and `onImportClick`. 
  - Assert that clicking the Maintain and Import buttons calls the respective spies.

## Instructions
1. Navigate to `Nexus-Frontend/`.
2. Edit `components/NxMemoryMaintenanceModal.tsx` and `components/NxImportModal.tsx`.
3. Edit `app/contacts/page.tsx` and `components/ContactHubTopbarControls.tsx`.
4. Create/Edit `tests/components/ContactHubTopbarControls.test.tsx`.
5. Run tests: `npm run test -- tests/components/ContactHubTopbarControls.test.tsx --run`.
6. Write a handoff report in your directory (`worker_M2_handoff.md`) containing Observation, Logic Chain, Caveats, Conclusion, Verification Commands.
7. Send me a message when done.
