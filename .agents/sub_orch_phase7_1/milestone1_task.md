# Task: Milestone 1 - Contact Card Updates

## Objective
Implement Task 10.1 and its corresponding component tests from Task 10.5.

### Task 10.1: Update `NxContactCard3D` with all required fields and 7 quick actions
- Extend the component's props interface to include: `gender`, `tags`, `emotional_baseline`, `conflict_count`, `last_interaction_at`.
- Add new optional callback props: `onOpenProfile`, `onStartAnalysis`, `onImportMessages`, `onViewConversations`, `onEditReplyMode`, `onMerge`, `onArchive`.
- Render all data fields when present (WhatsApp number, contact type badge, gender badge, reply mode indicator, override indicator, last interaction, emotional baseline chip, profile confidence, memory freshness, conflict count).
- Add a collapsible quick-actions row (appears on hover) with icon buttons for all 7 actions.

### Task 10.5: Write component tests for contact card
- `NxContactCard3D`: assert all 13 required fields render when populated (Property 22); assert all 7 quick action buttons present.

## Files
- `Nexus-Frontend/components/NxContactCard3D.tsx`
- Corresponding test file in `Nexus-Frontend/` (create or update).

## Output
Please analyze the code and propose a comprehensive implementation strategy. Do not implement it yourself. Write your handoff report to `c:\Users\hedra\Desktop\Sourcecode\NexusV2\.agents\sub_orch_phase7_1\explorer_M1_[ID]_handoff.md` and send a message when done.
