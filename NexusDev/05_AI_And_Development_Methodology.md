# AI & Development Methodology

This document outlines the strict methodology for developing features, interacting with the codebase, and utilizing AI Agents (like Cursor, GitHub Copilot, or Antigravity) to ensure a clean, stable, and documented project.

## 1. Local IDE Setup
- **Avoid Monolith Confusion**: Do not open the root `NexusV2` directory directly in VSCode/Cursor if you are working on the code.
- **Use Multi-root Workspaces**: Add `Nexus-Frontend` and `Nexus-backend` as separate folders in a single Workspace (`File -> Add Folder to Workspace`). Save this as `Nexus.code-workspace`.
- This ensures the IDE's Git source control, language servers (TypeScript/Intelephense), and AI context windows do not mix frontend and backend contexts inappropriately.

## 2. Git Workflow & Branching
1. **Never commit directly to `main`**.
2. Update local `main`: `git checkout main && git pull origin main`.
3. Create a feature branch: `git checkout -b feature/hub-name-feature-name` (e.g., `feature/agent-async-dispatch`).
4. Commit often using semantic commit messages:
   - `feat:` for new features.
   - `fix:` for bug fixes.
   - `docs:` for documentation updates.
   - `refactor:` for code restructuring.
5. Push branch and open a Pull Request against `main`.

## 3. Controlling AI Agents
When delegating work to an AI Agent, you must provide strict constraints:

### A. Context Provisioning
- **Rule**: Never ask an AI to "just fix the bug" without providing context.
- **Action**: Always point the AI to the `ARCHITECTURE_ANALYSIS.md`, `HUB_IMPLEMENTATION_FIX_AND_COMPLETION_PLAN.md`, and the specific `.ai-context.md` file (which should exist in the root of both frontend and backend).

### B. Micro-Tasking
- Break down large goals into small, verifiable steps.
- **Bad**: "Implement the SchedulerHub."
- **Good**: "Review the SchedulerHub backend requirements. First, create the database migration for storing run history. Stop and let me review."

### C. Test-Driven AI (TDAI)
- Require the AI to write a failing test *before* implementing the fix.
- **Prompt**: "Write a PHPUnit test for the Agent Async Job Dispatch that currently fails. Then fix the implementation until the test passes."

### D. Documentation Obligation
- Make it a mandatory rule for the AI:
- **Prompt**: "Once this feature is implemented and tested, you must update the relevant Markdown file in the `NexusV2_Docs` directory to reflect the new endpoints, capabilities, or architectural changes."

## 4. Submodule Management
If you are managing the project via Git Submodules in the root repository:
- When pulling the root repository, always run: `git submodule update --init --recursive`
- Do not make commits directly inside the submodule from the root terminal if you are confused. Always `cd` into the submodule (`cd Nexus-Frontend`), ensure you are on a branch, commit, push, and then return to the root to commit the updated submodule pointer.
