# Handoff Report: Agents Hub Gap Closure

## Observation
- **`PROJECT.md` Requirements:** Specifies that the Frontend `updateAgent` will send `name`, `temperature`, `max_tokens`, `guidelines`, `persona_id` via PUT `/api/v1/agents/{id}`. The Backend `AgentController::update` must validate these and nest `temperature`, `max_tokens`, and `guidelines` inside the `settings` JSON column.
- **Frontend Store (`store/index.ts`):** 
  - The `Agent` interface (around line 58) is missing the `guidelines?: string` property.
  - `hydrateAgents()` (around line 883) maps backend responses to the `Agent` interface but doesn't map `guidelines`.
  - The `GlobalState` lacks an `updateAgent` action.
- **Frontend Components (`app/agents/components/AgentsTab.tsx` & `PersonasTab.tsx`):**
  - `AgentsTab.tsx` currently has no drawer implementation (`NxDrawer`) for viewing/editing agent details or quarantining them.
  - `PersonasTab.tsx` currently only supports creation and deletion of personas, lacking an edit state and action.
- **Backend Controller (`app/Http/Controllers/AgentController.php`):**
  - The `update` method (around line 97) defines a validator that does not include `temperature`, `max_tokens`, or `guidelines`. It also does not transfer these top-level fields into the `settings` attribute.

## Logic Chain
1. **Backend Discrepancy:** Since the frontend will send `temperature`, `max_tokens`, and `guidelines` as top-level fields in the PUT payload, the backend will strip them out during validation. Modifying the `update` validator to accept these fields and explicitly merging them into `$agent->settings` before calling `$agent->update()` is required to fix the discrepancy.
2. **Frontend Store Updates (Tasks 1 & 2):** Adding `guidelines` to the `Agent` interface and `hydrateAgents()` is a prerequisite to allow the UI to consume and display this field. Implementing `updateAgent` with optimistic updates ensures the frontend can successfully communicate with the patched backend.
3. **Frontend UI Components (Tasks 3, 4, & 6):** 
  - `AgentsTab.tsx` needs local state (`isDrawerOpen`, `selectedAgentId`, `editForm`, `quarantineReason`, `showQuarantineConfirm`) to implement the `NxDrawer` component with the form fields and quarantine action.
  - `PersonasTab.tsx` requires `editingPersona` state and an `Edit2` button inside the card loop to switch the form into edit mode, calling `updatePersona` instead of `createPersona`.

## Caveats
- No caveats. The project documentation correctly specifies the intended behavior, and the current file contents align with the identified missing pieces. 

## Conclusion
The clear fix strategy for Milestone 1 is to:
1. **Backend:** Update `AgentController.php`'s `update` method validator to allow `temperature` (`numeric|min:0|max:2`), `max_tokens` (`integer|min:1`), and `guidelines` (`string`). Intercept these validated fields and merge them into `$agent->settings` before saving.
2. **Frontend Store:** Update `store/index.ts` to add `guidelines` to the `Agent` interface, map it in `hydrateAgents`, and implement the `updateAgent` action.
3. **Frontend UI:** Implement the `NxDrawer` in `AgentsTab.tsx` for inline editing and the quarantine flow, and add an edit mode to `PersonasTab.tsx` utilizing `updatePersona`.

## Verification Method
- **Backend:** Run `php artisan test` (or `phpunit`) targeting the `AgentControllerTest` after changes to verify `PUT /api/v1/agents/{id}` correctly stores `temperature` and `guidelines` within `settings`.
- **Frontend:** Verify the store builds correctly. Start the Next.js frontend and interact with the UI to ensure the drawer opens on clicking an Agent Card, and editing a persona works correctly.
