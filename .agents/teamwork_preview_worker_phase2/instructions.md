# Scope: Phase 2 Documentation Generation

You are tasked with generating the unified, optimized set of documentation files for the Nexus Project in `NexusV2_Docs\02 - OptimizedDocumentations`.

## Tasks
1. Read the `PHASE1_AUDIT_REPORT.md` located in the project root (`c:\Users\hedra\Desktop\Sourcecode\NexusV2\PHASE1_AUDIT_REPORT.md`) to understand the technical debt, logic bugs, missing test infrastructure, and monolithic structures across the 10 hubs.
2. Create `requirements.md` in `NexusV2_Docs\02 - OptimizedDocumentations`. It should outline a unified functional requirement set, prioritizing fixing the bugs and implementing the missing Phase 1 and Phase 8 goals from the audit.
3. Create `design.md` in `NexusV2_Docs\02 - OptimizedDocumentations`. It must address architectural flaws (e.g., breaking down monoliths in AI Models Hub and Settings Hub, missing components in Dashboard) and define standard testing infrastructure for frontend and backend. It must also explicitly define interfaces bridging at least 3 cross-hub integration gaps:
   - Gap A: Webhook Payload Routing between People Connect and AI Models/Tasks
   - Gap B: Dashboard Data Integration from Agents and Memory
   - Gap C: Contact Hub Data Ingestion flows
4. Create `tasks.md` in `NexusV2_Docs\02 - OptimizedDocumentations`. It should present a definitive roadmap (step-by-step tasks) that explicitly targets resolving the logic bugs (e.g., PHP clone syntax, exact equality ternary in tasks-hub, `isModalOpen` bug in workflows-hub, webhook routing bugs in people-connect-hub) and adding the missing test suites and component extractions.
5. Notify the parent via `send_message` with the paths of the created files and a summary of your actions once you are done.
