# NexusV2 Development Lifecycle Checklist

This actionable checklist covers every phase of the development lifecycle, from initial architecture decoupling to production deployment.

## Phase 1: Repository Segmentation & Initialization
- [ ] Backup current monolithic `NexusV2` directory.
- [ ] Initialize independent Git repository in `Nexus-Frontend`.
- [ ] Initialize independent Git repository in `Nexus-backend`.
- [ ] Create remote repositories for Frontend, Backend, and Root on GitHub/GitLab.
- [ ] In the root folder, run `git submodule add <remote-url> Nexus-Frontend`.
- [ ] In the root folder, run `git submodule add <remote-url> Nexus-backend`.
- [ ] Verify that documentations (`NexusV2_Docs`) remain tracked only in the root repository.

## Phase 2: AI Agent Workflow Setup
- [ ] Create an `.ai-context.md` file in each repository detailing its specific framework and rules.
- [ ] Ensure AI agents are always prompted with: "Read `.ai-context.md` and `ARCHITECTURE_ANALYSIS.md` before generating code."
- [ ] Define the testing standard: Instruct AI to generate unit tests alongside any new component/controller.

## Phase 3: IDE & Git Workflow Standardization
- [ ] Configure IDE (VSCode/Cursor) to open individual submodules as separate workspace folders, OR use Multi-root Workspaces to avoid cross-repo git confusion.
- [ ] **Commit Protocol**:
  - Pull latest changes before starting work.
  - Create a feature branch: `git checkout -b feature/module-name`.
  - Stage changes: `git add .`
  - Commit with descriptive message: `git commit -m "feat: implement X"`
  - Push branch: `git push origin feature/module-name`.
  - Open Pull Request.
- [ ] **Submodule Sync**: Whenever pulling the root repo, always run `git submodule update --init --recursive`.

## Phase 4: Core Development Modules
- [ ] **ContactHub**: Finalize API integration and timeout resolution.
- [ ] **NexusConnectHub**: Complete migration schema and background sync jobs.
- [ ] **AgentsHub**: Ensure Phase 3-6 AI interactions are robust and tested.
- [ ] **AiModelsHub**: Finalize architecture compliance audit and implement required changes.

## Phase 5: Testing & Quality Assurance
- [ ] Run backend automated tests (e.g., PHPUnit / PyTest).
- [ ] Run frontend automated tests (e.g., Jest / Cypress).
- [ ] Conduct API endpoint stress tests to ensure timeout errors are completely mitigated.
- [ ] Verify complete separation of Frontend and Backend state.

## Phase 6: Staging Deployment
- [ ] Provision staging servers.
- [ ] Deploy backend to staging, configure `.env.staging`, and migrate database.
- [ ] Deploy frontend to staging and link it to the backend staging URL.
- [ ] Perform end-to-end (E2E) UI testing on the staging environment.

## Phase 7: Production Launch
- [ ] Freeze code updates.
- [ ] Provision production infrastructure with scaling configurations.
- [ ] Setup monitoring and logging pipelines (APM, Sentry, log rotation).
- [ ] Execute production deployment pipelines.
- [ ] Conduct final smoke tests on live production environment.
- [ ] Sign-off on complete release.
