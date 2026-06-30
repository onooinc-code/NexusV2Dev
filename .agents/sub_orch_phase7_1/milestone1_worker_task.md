# Task: Implement Milestone 1 - Contact Card Updates (Task 10.1 & 10.5)

## Objective
Implement Task 10.1 and its corresponding component tests from Task 10.5.

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Context
The Explorer has analyzed the requirements and determined the following strategy:
- `NxContactCard3D.tsx` is at `Nexus-Frontend/components/NxContactCard3D.tsx`.
- Extend `NxContactCard3DProps['contact']` to include `gender` (string), `tags` (string[]), `emotional_baseline` (string), `conflict_count` (number), `last_interaction_at` (string).
- Extend `NxContactCard3DProps` to include the 7 optional callbacks: `onOpenProfile`, `onStartAnalysis`, `onImportMessages`, `onViewConversations`, `onEditReplyMode`, `onMerge`, `onArchive`.
- Import additional icons from `lucide-react`: `Clock`, `AlertTriangle`, `Activity`, `Download`, `MessageSquare`, `Settings`, `GitMerge`, `Archive`.
- Render all fields: badges for `gender` and `emotional_baseline`, `last_interaction_at` in the main details list, `conflict_count` in the bottom grid.
- Implement the quick actions as a hover-triggered div that slides in at the bottom. The card has a `group` class, so use `absolute bottom-0 w-full flex justify-center gap-2 p-2 translate-y-full group-hover:translate-y-0 transition-transform`. Buttons should have `title` attributes for the test queries.
- Create a new test file: `Nexus-Frontend/tests/components/NxContactCard3D.test.tsx` (or `Nexus-Frontend/tests/components/NxContactCard3D.test.tsx`? Actually look for the correct path, maybe `__tests__` or `tests`). Use `@testing-library/react` and Vitest.
- Test must assert the 13 required fields render when populated (Property 22) and all 7 quick action buttons are present.

## Instructions
1. Navigate to `Nexus-Frontend/`.
2. Edit `components/NxContactCard3D.tsx`.
3. Create/Edit `tests/components/NxContactCard3D.test.tsx` (check if the `tests` directory structure exists).
4. Run tests in `Nexus-Frontend/` to verify (`npm run test -- --run` or similar). Ensure compilation passes (`npm run build` or similar next build check).
5. Write a handoff report in your directory (`worker_M1_handoff.md`) containing:
   - Observation
   - Logic Chain
   - Caveats
   - Conclusion
   - Verification Commands (e.g. `cd Nexus-Frontend && npm test`)
6. Send me a message when done with the path to your handoff report.
