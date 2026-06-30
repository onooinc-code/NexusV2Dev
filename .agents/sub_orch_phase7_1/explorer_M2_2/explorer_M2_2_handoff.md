# Handoff Report: Milestone 2 - Topbar & Page Wiring

## 1. Observation
- **`app/contacts/page.tsx`**: 
  - Currently contains an inline `<NxDrawer>` for message imports (lines 434-536) which includes a `<select>` for picking a contact.
  - Doesn't have any state or rendering for a maintenance modal.
  - The `ContactHubStats` interface here doesn't include fields for `active_import_jobs` or `active_maintenance_jobs`.
- **`components/ContactHubTopbarControls.tsx`**:
  - Exposes `onMaintenanceClick` and `onImportClick` props and wires them to "Maintain" and "Import" buttons.
  - Renders a queue status indicator for `pending_analysis_runs`.
  - The `ContactHubStats` interface (lines 24-34) doesn't include fields for `active_import_jobs` or `active_maintenance_jobs`.
- **`components/NxMemoryMaintenanceModal.tsx`**:
  - Requires `contactId: number` as a prop (line 13).
  - Triggers an API call to `/contacts/${contactId}/memory-maintenance` (line 34).
  - Does not accept a `scope` prop.
- **`components/NxImportModal.tsx`**:
  - Requires `contactId: number` as a prop (line 15) and appends it to FormData during import (`formData.append('contact_id', contactId.toString())` at line 48).
  - Does not include a dropdown to select a contact, assuming it's launched within the context of a specific contact.
- **`tests/components/ContactHubTopbarControls.test.tsx`**:
  - `find_by_name` and `view_file` revealed this file does not exist. Tests need to be created from scratch.

## 2. Logic Chain
1. **Task 10.2 (Maintenance Modal)**: To render `<NxMemoryMaintenanceModal scope="global" />` in `page.tsx`, the component itself must be updated to accept `scope?: 'global' | 'contact'` and make `contactId` optional. When `scope` is global, the API endpoint needs to point to a global maintenance endpoint rather than one scoped to a specific contact. Then, `isMaintenanceModalOpen` state can be added to `page.tsx`.
2. **Task 10.3 (Import Modal)**: Removing the inline import drawer in `page.tsx` and replacing it with `<NxImportModal>` means we lose the contact selection dropdown. To fix this, `NxImportModal` must be updated to make `contactId` optional, and if it's absent (or global), render a contact dropdown fetched from `useAppStore`. Then `page.tsx` can instantiate the updated modal and connect the state to `ContactHubTopbarControls`.
3. **Task 10.4 (Queue Indicators)**: `ContactHubStats` in both files must be expanded to include `active_import_jobs?: number;` and `active_maintenance_jobs?: number;`. Next to the existing `<Activity />` indicator in `ContactHubTopbarControls`, we need to conditionally render new UI pill containers for imports and maintenance if their counts are greater than 0.
4. **Task 10.5 (Tests)**: A new test file must be created using the existing project testing framework (likely `vitest` + `@testing-library/react`). The test should mock `apiClient` and `useAppStore`, render `ContactHubTopbarControls` with mocked `onMaintenanceClick` and `onImportClick` spies, click the buttons using `screen.getByText()`, and assert the functions are called.

## 3. Caveats
- **Backend API Readiness**: Expanding `ContactHubStats` relies on `/contacts/stats` actually returning `active_import_jobs` and `active_maintenance_jobs`. Similarly, `NxMemoryMaintenanceModal` using `scope="global"` implies there's a global maintenance endpoint on the backend. If these aren't ready, the frontend will either send 0 values or get 404s on the API calls.
- **Duplicate State**: `ContactHubStats` is duplicated in both `page.tsx` and `ContactHubTopbarControls.tsx`. This should ideally be extracted to a shared types file if possible.

## 4. Conclusion
**Implementation Strategy:**
- **Task 10.2**: Update `NxMemoryMaintenanceModal` interface to `{ isOpen: boolean; onClose: () => void; contactId?: number; scope?: 'global' | 'contact' }`. Adapt its API call logic based on `scope`. Add state and modal to `app/contacts/page.tsx` and pass handler down to `ContactHubTopbarControls`.
- **Task 10.3**: Port the contact `<select>` logic from `page.tsx` into `NxImportModal.tsx`, mapping contacts from `useAppStore((state) => state.contacts)`. Make its `contactId` optional. Remove the inline drawer from `page.tsx` and wire up the modal via state to `ContactHubTopbarControls`.
- **Task 10.4**: Update the `ContactHubStats` interface with `active_import_jobs` and `active_maintenance_jobs`. In `ContactHubTopbarControls`, add conditionally rendered DOM elements in the queue status section for these two new metrics.
- **Task 10.5**: Create `tests/components/ContactHubTopbarControls.test.tsx`. Use `vi.mock` for the store/API. Render the component with jest mock functions (`vi.fn()`) as props. Trigger `fireEvent.click` on the buttons and run `expect(spy).toHaveBeenCalled()`.

## 5. Verification Method
- **Type Checking**: Run `npx tsc --noEmit` to ensure no interface or prop mismatches exist.
- **Linting**: Run `npm run lint` on the modified files.
- **Testing**: Run `npm run test` (or `npx vitest tests/components/ContactHubTopbarControls.test.tsx`) to verify the new test file executes and passes.
- **Manual Verification**: Run the development server. Navigate to `/contacts` and verify the topbar buttons successfully launch their respective modals. Verify the import modal contains a dropdown when launched globally.
