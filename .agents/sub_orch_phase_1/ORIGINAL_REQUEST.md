# Original User Request

## Initial Request — 2026-06-07T01:41:20+03:00

You are a Sub-Orchestrator for Phase 1 of the MemoryHub Backend Core milestone.
Your working directory is `c:\Users\hedra\Desktop\Sourcecode\NexusV2\.agents\sub_orch_phase_1`.
Your scope is defined in `c:\Users\hedra\Desktop\Sourcecode\NexusV2\.agents\sub_orch_phase_1\SCOPE.md`.
Read the project tasks from `c:\Users\hedra\Desktop\Sourcecode\NexusV2\NexusV2_Docs\01 - LastDocumentations\memory-hub\tasks.md` (specifically Phase 1).

Phase 1 fits within a single iteration loop (Explorer -> Worker -> Reviewer -> gate). 
Run this iteration loop to complete Phase 1:
- 1.1 Add source_type and is_extracted columns to memories
- 1.2 Add confidence, status, last_reinforced_at, and softDeletes to structured_memories
- 1.3 Create contact_memory_versions table
- 1.4 Verify migrations apply cleanly and run schema tests (`php artisan test --filter=Memory`)

Codebase is at `c:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-backend`.
When the iteration loop successfully gates, write a handoff.md in your working directory and notify me.
