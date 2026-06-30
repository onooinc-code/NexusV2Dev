# Task: Milestone 2 - Topbar & Page Wiring

## Objective
Implement Tasks 10.2, 10.3, 10.4, and the topbar tests from 10.5.

## Details
- **Task 10.2**: In `app/contacts/page.tsx`, add state `isMaintenanceModalOpen` and pass an `onMaintenanceClick` handler to `ContactHubTopbarControls`. Render `<NxMemoryMaintenanceModal isOpen={...} onClose={...} scope="global" />`.
- **Task 10.3**: In `app/contacts/page.tsx`, add state `isImportModalOpen` and pass an `onImportClick` handler to `ContactHubTopbarControls`. Replace the contacts page inline import drawer with `<NxImportModal>`.
- **Task 10.4**: Extend the queue/progress indicator on the contacts page to show counts of active import jobs (from `/contacts/stats`) and active maintenance jobs, separated from analysis jobs.
- **Task 10.5**: Write component tests for `ContactHubTopbarControls` asserting Maintain button opens the modal and Import button opens `NxImportModal`. 

## Files
- `Nexus-Frontend/components/ContactHubTopbarControls.tsx`
- `Nexus-Frontend/app/contacts/page.tsx`
- `Nexus-Frontend/tests/components/ContactHubTopbarControls.test.tsx` (create or update)

## Output
Analyze the code and propose an implementation strategy. Write your handoff report to your directory and send a message when done.
