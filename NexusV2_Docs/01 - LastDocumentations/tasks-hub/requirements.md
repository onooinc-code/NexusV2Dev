# Tasks Hub — Requirements

## Introduction

TasksHub provides a kanban-style interface for tracking and managing task objectives across the Nexus system. It supports manual user-created tasks, allows status transitions, and integrates with the global job monitoring system to simulate agent-driven task progress.

## Glossary

| Term | Definition |
|------|-----------|
| Task | A work item with a title, description, status, priority, and due date |
| Status | The lifecycle stage of a task: todo, in-progress, or completed |
| Priority | Urgency level: low, medium, or high |
| Kanban | A three-column board layout organizing tasks by their current status |
| Due Date | A freeform date string indicating when a task should be completed |
| Optimistic Update | Immediately updating the UI before the API confirms the change, with rollback on failure |

---

## Requirement 1: Task Display (Kanban Board)

**User Story:** As a user, I want to see all my tasks organized in a three-column kanban board by status, so that I can understand the current state of my work at a glance.

### Acceptance Criteria

1. WHEN the user opens TasksHub, THE system SHALL call `hydrateTasks()` (GET `/tasks`) and load all tasks from the backend.
2. THE page SHALL render three columns: "To Do" (status=todo), "In Progress" (status=in-progress), and "Completed" (status=completed).
3. EACH column header SHALL display a colored status dot (blue pulse=todo, amber pulse=in-progress, emerald=completed) and the column label.
4. EACH column SHALL display a list of task cards filtered by that column's status.
5. WHEN a column has no tasks, THE system SHALL display a dashed-border placeholder message (e.g., "No pending objectives.").
6. EACH task card SHALL display: title (with strikethrough and reduced opacity when completed), description (truncated to 2 lines), priority badge (color-coded: low=gray, medium=amber, high=red), and due date with a calendar icon.
7. COMPLETED task cards SHALL have reduced opacity (60%) and a muted background.

---

## Requirement 2: Task Status Transitions

**User Story:** As a user, I want to cycle a task through its status states by clicking a toggle, so that I can track progress without leaving the board.

### Acceptance Criteria

1. EACH task card SHALL have a clickable status toggle button (checkbox-style icon in the top-left of the card).
2. THE status cycle SHALL be: todo → in-progress → completed → todo.
3. WHEN the user clicks the toggle, THE system SHALL call `updateTask(id, newStatus)` (PATCH `/tasks/{id}/status`) with the next status.
4. THE update SHALL use optimistic UI — the card SHALL reflect the new status immediately, before API confirmation.
5. IF the API call fails, THE status SHALL roll back to its previous value and an error notification SHALL be displayed.
6. THE toggle button icon SHALL reflect the current status: empty checkbox (todo), amber clock icon (in-progress), green checkmark (completed).
7. WHEN a task transitions to "in-progress," THE system SHALL call `addJob("Agent solving task objective: id-{taskId}")` to register the action in the global job monitor.

---

## Requirement 3: Task Creation

**User Story:** As a user, I want to create new task objectives from a drawer form, so that I can add work items quickly.

### Acceptance Criteria

1. THE page header SHALL contain a "New Objective" button with a plus icon.
2. WHEN the button is clicked, THE system SHALL open an `NxDrawer` with the title "Add Objective."
3. THE create form SHALL include: Objective Title (NxInput, required), Description (textarea, optional), Priority selector (NxSelect: Low/Medium/High), and Target Date (NxInput, freeform text like "Tomorrow" or date string).
4. WHEN the form is submitted with a valid title, THE system SHALL call `createTask()` (POST `/tasks`) with the provided data.
5. THE priority values sent to the API SHALL be mapped: high=10, medium=5, low=1 (integer values expected by backend).
6. THE task creation SHALL use optimistic UI — a temporary card SHALL appear in the "To Do" column immediately.
7. WHEN the API responds successfully, THE temporary card SHALL be replaced with the real task record.
8. IF the API call fails, THE temporary card SHALL be removed and an error notification SHALL be shown.
9. WHEN the form is submitted, THE system SHALL call `addJob("Scheduling agent task allocation workflow")`.
10. AFTER successful creation, THE drawer SHALL close and all form fields SHALL reset to default values.
11. THE "Cancel" button SHALL close the drawer without saving.

---

## Requirement 4: Task Deletion

**User Story:** As a user, I want to delete tasks I no longer need, so that my board stays relevant and focused.

### Acceptance Criteria

1. EACH task card SHALL show a delete icon button (alert-circle icon) in the bottom-right corner, visible only on hover.
2. WHEN the delete button is clicked, THE system SHALL call `deleteTask(id)` (DELETE `/tasks/{id}`).
3. THE deletion SHALL use optimistic UI — the card SHALL disappear immediately from the board.
4. IF the API call fails, THE card SHALL reappear and an error notification SHALL be displayed.
5. THE delete icon SHALL use a subtle hover animation (opacity: 0 → 1 on group hover).

---

## Requirement 5: Navigation & Layout

**User Story:** As a user, I want the Tasks page to be clean and well-organized so that managing objectives feels efficient.

### Acceptance Criteria

1. THE page SHALL render within `AppLayout` with the title "Task Objectives."
2. THE page description SHALL read "Track multi-stage agent workflows, user objectives, and system pipelines."
3. THE kanban board SHALL use a responsive three-column grid (stacking to 1 column on mobile).
4. THE maximum content width SHALL be `max-w-5xl`, centered on the page.
5. THE page SHALL support vertical scrolling for long task lists.
