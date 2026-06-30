# Workflows Hub — Requirements

## Introduction

WorkflowsHub provides a visual canvas for browsing, creating, and executing workflow orchestration pipelines. It displays workflow steps as connected nodes on a canvas, streams real-time execution updates via WebSocket (Reverb), supports human approval gates, and maintains a full execution trace log.

## Glossary

| Term | Definition |
|------|-----------|
| Workflow | A named orchestration pipeline with steps, a trigger type, and a status |
| Step (Node) | A single unit of work within a workflow (trigger, action, condition, agent, wait, log) |
| Execution | A single run of a workflow, tracked with a unique ID, status, and step logs |
| Execution Tracer | A real-time log panel that displays step-by-step execution progress |
| Approval Gate | A workflow pause point requiring human approve/deny before continuing |
| WebSocket | A live connection (via Laravel Reverb/Echo) used to stream workflow events |
| Polling Fallback | Periodic HTTP polling used when WebSocket is unavailable |
| Node Status | The visual state of a step: pending, running, success, error |

---

## Requirement 1: Workflow List

**User Story:** As a user, I want to see all available workflows in a sidebar list, so that I can select one to view or execute.

### Acceptance Criteria

1. WHEN the user opens WorkflowsHub, THE system SHALL call GET `/workflows?limit=50` and load all workflows.
2. WHILE workflows are loading, THE page SHALL not crash or show a broken state.
3. THE sidebar SHALL display each workflow as a selectable button showing: workflow name and trigger type / status (uppercase, subdued).
4. THE currently selected workflow SHALL be highlighted with a nexus-blue border and background.
5. WHEN no workflows exist, THE sidebar SHALL display an empty state with the message "No Workflows" and a "Create a workflow to begin orchestration" description.
6. WHEN the first workflow loads, THE system SHALL auto-select it (the first in the list) unless the user has already made a selection.
7. A "Refresh" button in the header SHALL call `fetchWorkflows()` to reload the list.

---

## Requirement 2: Workflow Canvas

**User Story:** As a user, I want to see the steps of the selected workflow displayed as connected nodes on a canvas, so that I can understand the pipeline structure visually.

### Acceptance Criteria

1. THE canvas area SHALL display the steps of the selected workflow as a horizontal sequence of `NxWorkflowNode` components.
2. EACH node SHALL display: node name, node type label (above the node in monospace font), and a visual status indicator (pending/running/success/error).
3. NODES SHALL be connected by horizontal connector lines between consecutive steps.
4. THE node type SHALL be mapped: trigger/webhook/scheduled → "trigger", agent/task → "agent", decision/condition → "condition", all others → "action".
5. THE node status SHALL reflect live execution state: if an execution is active, the system SHALL look up the matching step log and map its status to pending/running/success/error.
6. WHEN a node's execution status is "running," IT SHALL be visually highlighted (selected=true on NxWorkflowNode).
7. WHEN the canvas has no steps, THE system SHALL display an empty state "Canvas is Empty."
8. THE canvas SHALL support horizontal scrolling for long workflows.

---

## Requirement 3: Workflow Execution

**User Story:** As a user, I want to execute a selected workflow and watch it run step by step in real time, so that I can monitor pipeline progress and catch failures.

### Acceptance Criteria

1. THE header SHALL contain an "Execute" button that calls POST `/workflows/{id}/execute` with `{ run_mode: "async", input_payload: { launched_from: "WorkflowsHub" } }`.
2. WHILE execution is starting, THE button SHALL show a loading spinner.
3. THE "Execute" button SHALL be disabled when no workflow is selected or the workflow's status is "running."
4. WHEN execution starts, THE Execution Tracer panel SHALL clear its previous logs.
5. THE execution response SHALL be stored and displayed in the Execution Tracer.
6. WHEN a WebSocket connection is active, THE system SHALL subscribe to the `workflow.{workflowId}` private channel and listen for events: `.workflow.started`, `.workflow.step_completed`, `.workflow.completed`, `.workflow.failed`.
7. EACH WebSocket event SHALL add a formatted log line to the Execution Tracer (▶ for started, ✓/✗ for step, ✅ for completed, ❌ for failed) with duration and error info if available.
8. WHEN a WebSocket event is received for a step, THE corresponding node status on the canvas SHALL update optimistically without a full re-fetch.
9. WHEN WebSocket is not connected, THE system SHALL poll GET `/workflows/{id}/progress` every 2.5 seconds as a fallback, stopping when the execution reaches a terminal state (completed/failed/cancelled).
10. THE WebSocket connection status SHALL be displayed in the header as a live indicator (green "Live" badge when connected, gray "Offline" otherwise).

---

## Requirement 4: Execution Tracer

**User Story:** As a user, I want to see a detailed log of each step's execution including status, duration, and errors, so that I can trace exactly what happened during a run.

### Acceptance Criteria

1. THE Execution Tracer panel SHALL display: real-time WebSocket log lines (at the top) and persisted step logs from the execution record (below a divider).
2. REAL-TIME log lines SHALL be color-coded: red for failures/errors, green for success, blue for started events, gray for other.
3. PERSISTED step log entries SHALL each show: step name, status (color-coded), duration in ms (if available), and error message (if present).
4. THE panel SHALL display the execution ID and overall status.
5. THE overall status SHALL be color-coded: emerald=completed, red=failed, amber=paused, blue=running, gray=other.
6. STATUS icons SHALL appear next to the panel title: green checkmark (completed), red X (failed), amber pause icon (paused).
7. WHEN no execution has been run, THE panel SHALL display "No active execution."
8. THE tracer log area SHALL be scrollable with a max height to prevent the panel from growing unboundedly.

---

## Requirement 5: Human Approval Gate

**User Story:** As an administrator, I want to approve or deny workflow execution when it pauses at an approval gate, so that I can maintain human oversight over sensitive pipeline steps.

### Acceptance Criteria

1. WHEN an execution's status is "paused" and `runtime_state.waiting_for.type === "approval"`, THE Execution Tracer SHALL display a "Review Approval Gate" button at the bottom.
2. WHEN the backend broadcasts a `.workflow.step_completed` event with `status === "paused"`, THE system SHALL call `fetchProgress()` and open the approval modal.
3. WHEN `fetchProgress()` returns an execution with `status=paused` and `waiting_for.type=approval`, THE system SHALL automatically open the `NxApprovalGateModal`.
4. THE approval modal SHALL be the `NxApprovalGateModal` component, receiving: `executionId`, `stepId`, and `contextData` from the execution's `runtime_state`.
5. WHEN the user clicks "Approve" in the modal, THE system SHALL call POST `/workflows/executions/{executionId}/resume` with `{ decision: "approve", input_payload: { approval_decision: "approve" } }`.
6. WHEN the user clicks "Reject," THE system SHALL call the same endpoint with `decision: "deny"`.
7. AFTER a resume action, THE execution state SHALL update from the API response and the modal SHALL close.

---

## Requirement 6: Workflow Creation

**User Story:** As a user, I want to create new workflow pipelines with a name and trigger type, so that I can build custom orchestration flows.

### Acceptance Criteria

1. THE header SHALL contain a "New Workflow" button that opens an `NxModal`.
2. THE creation modal SHALL include: Name input (required) and Trigger Type selector (manual, scheduled, event, webhook).
3. WHEN the form is submitted, THE system SHALL call POST `/workflows` with the workflow name, auto-generated key, description, trigger type, status "draft," and a default set of starter steps (manual_trigger, collect_context, approval_gate, final_log).
4. IF the workflow name generates a duplicate key, THE system SHALL append a timestamp to ensure uniqueness.
5. WHEN the workflow is created successfully, IT SHALL appear at the top of the sidebar list and be auto-selected.
6. IF creation fails, THE Execution Tracer SHALL display an error log line with the failure reason.
7. WHEN the modal is closed (Cancel or backdrop click), ALL form fields SHALL reset.

---

## Requirement 7: Navigation & Layout

**User Story:** As a user, I want WorkflowsHub to have a well-organized three-panel layout with clear controls, so that I can manage, view, and execute workflows efficiently.

### Acceptance Criteria

1. THE page SHALL render within `AppLayout` with the title "Workflow Orchestration Canvas."
2. THE layout SHALL use a three-panel grid: workflow list sidebar (280px), canvas (flexible), and execution tracer (320px) on large screens; stacking vertically on mobile.
3. THE page description in the header SHALL show the selected workflow name and version number (e.g., "Daily Sync v2").
4. THE minimum canvas height SHALL be 520px to display nodes without cramping.
5. THE page SHALL support responsive layout, collapsing the three-panel grid to a single column on small screens.
6. THE canvas background SHALL use a grid pattern for visual clarity.
