# Handoff Report: Milestone 2 - Topbar & Page Wiring

## Observation
- `app/contacts/page.tsx` currently has an inline `<NxDrawer>` for importing messages (lines 434-536) managed by `isImportOpen`. It imports `<ContactHubTopbarControls />` but doesn't pass handlers.
- `components/ContactHubTopbarControls.tsx` has optional props `onMaintenanceClick` and `onImportClick`, but if undefined, it falls back to displaying a generic info notification.
- `components/NxImportModal.tsx` handles importing via UI but expects a strict `contactId: number` prop, with no contact dropdown to allow general ("global") use.
- `components/NxMemoryMaintenanceModal.tsx` expects a `contactId: number` prop, targeting `/contacts/${contactId}/memory-maintenance`. The backend `api.php` already supports a global `POST /contacts/memory-maintenance` endpoint (line 116).
- `app/Services/ContactStatsService.php` (`getHubStats()`) currently lacks `active_imports` and `active_maintenance_runs` counts, and `ContactHubTopbarControls` only renders `pendingRuns` for the AI queue.
- `tests/components/ContactHubTopbarControls.test.tsx` does not exist. `package.json` confirms `vitest` is used.

## Logic Chain
1. **Task 10.2**: In `page.tsx`, we need to instantiate `isMaintenanceModalOpen` state. We must pass `onMaintenanceClick={() => setIsMaintenanceModalOpen(true)}` to `ContactHubTopbarControls`. Since `<NxMemoryMaintenanceModal>` is to be rendered with `scope="global"`, we must update `NxMemoryMaintenanceModalProps` to accept an optional `scope?: 'global' | 'contact'` and optional `contactId?: number`. Inside the modal, the API call should target `/contacts/memory-maintenance` instead of `/contacts/${contactId}/memory-maintenance` when scope is global.
2. **Task 10.3**: In `page.tsx`, we must rename or map `isImportOpen` state to `isImportModalOpen`. We need to pass `onImportClick={() => setIsImportModalOpen(true)}` to `ContactHubTopbarControls`. The current inline import drawer in `page.tsx` must be removed and replaced with `<NxImportModal isOpen={isImportModalOpen} onClose={() => setIsImportModalOpen(false)} />`. `NxImportModal` must be updated to make `contactId` optional; when `contactId` is absent, it must render an `<NxSelect>` for the user to choose a contact from `contacts = useAppStore(state => state.contacts)`.
3. **Task 10.4**: Update `ContactStatsService.php` in the backend so `getHubStats()` returns `active_imports` (`ContactImportBatch::whereIn('status', ['pending', 'processing'])->count()`) and `active_maintenance_runs` (`ContactMemoryMaintenanceRun::whereIn('status', ['queued', 'running'])->count()`). On the frontend, update the `ContactHubStats` interface in `ContactHubTopbarControls.tsx` to include these. Finally, extend the Queue Status Indicator block in `ContactHubTopbarControls` to conditionally render separate status tags for `active_imports` and `active_maintenance_runs` alongside `pendingRuns`.
4. **Task 10.5**: Create `ContactHubTopbarControls.test.tsx` using `vitest` and `@testing-library/react`. We need to mock the `onMaintenanceClick` and `onImportClick` props, render the component, simulate clicks on the "Maintain" and "Import" buttons, and assert that the mocked handlers were called.

## Caveats
- Since the task emphasizes the frontend, I am also providing the necessary backend additions for `ContactStatsService.php` as it is fundamentally required for Task 10.4 to function properly.
- The `ContactHubStats` interface in `page.tsx` is defined but unused (dead code). It can be safely deleted.
- The `page.tsx` internal states and functions specific to the inline import drawer (e.g., `importContactId`, `importSource`, `handleCommitImport`) should be deleted to prevent stale code.

## Conclusion
The implementation strategy is solid. First, modify the modals (`NxImportModal` and `NxMemoryMaintenanceModal`) to support optional `contactId`s and global scoping. Second, modify `page.tsx` to wire up the states, pass them to the topbar controls, and strip out the legacy inline drawer. Third, expand the backend stats payload and the corresponding frontend interface to render all background queues in `ContactHubTopbarControls`. Finally, create the specified test suite.

## Verification Method
- **UI**: Click "Maintain" on the topbar and verify the Memory Maintenance modal opens globally. Click "Import" and verify the Import Modal opens with a contact dropdown.
- **Backend/Integration**: Add test jobs/records to `ContactImportBatch` and `ContactMemoryMaintenanceRun` and verify `GET /api/v1/contacts/stats` successfully returns the new counters.
- **Tests**: Run `npm run test` or `npx vitest run tests/components/ContactHubTopbarControls.test.tsx` to ensure all tests pass.
