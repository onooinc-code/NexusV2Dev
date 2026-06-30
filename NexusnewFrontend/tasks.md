# Tasks Objectives (tasks)

## Overview
Task Objectives is a Kanban-style board for tracking multi-stage agent workflows, user objectives, and system pipelines.

## Design Details
- **Container**: Max width `5xl`, padded.
- **Header**: Icon (CheckSquare, blue), title, description, and "New Objective" button.
- **Columns**: 3-Column Grid for Kanban stages.
  1. **To Do**: Blue pulsing dot.
  2. **In Progress**: Amber pulsing dot.
  3. **Completed**: Emerald solid dot.

## Core Features

### 1. Kanban Board
- Displays `TaskCard` components in their respective columns based on status.
- Clicking a task card allows toggling its status:
  - `todo` -> `in-progress` (Triggers a simulated background job "Agent solving task objective...").
  - `in-progress` -> `completed`.
  - `completed` -> `todo`.
- Delete functionality on each card.
- Empty states for each column if no tasks exist (dashed border box).

### 2. New Objective Drawer (`NxDrawer`)
- A slide-out panel from the right.
- **Form Fields**:
  - **Objective Title**: Text input.
  - **Description**: Textarea.
  - **Priority**: Select dropdown (Low, Medium, High).
  - **Target Date**: Text input for natural language dates.
  - **Assigned Agent**: Select dropdown populated from the `agents` store.
  - **Associated Workflow**: Select dropdown populated from the `workflows` store.
- **Submission**:
  - Adds the task to the store.
  - Simulates a backend scheduling delay by triggering a job ("Scheduling agent task allocation workflow").
