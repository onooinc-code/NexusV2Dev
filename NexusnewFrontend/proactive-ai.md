# Proactive AI Engine (proactive-ai)

## Overview
The Proactive AI Engine is where "Souly" acts autonomously. Users can define rules in plain natural language (ECA: Event-Condition-Action) and the system executes them at the right moment.

## Design Details
- **Container**: Max width `7xl`, auto-overflow vertical.
- **Glassmorphism**: Heavy use of `NxGlassCard` for stats and rule cards.
- **Header**: Icon (Bot, purple, pulsing), title, and a "New Rule" primary action button.
- **Stat Cards**: 4 grid cards (Total Rules, Active Rules, Pending Triggers, Actions Completed) with unique icons and colors (Purple, Green, Yellow, Blue).
- **Tabs**: Pill-shaped tab selector (`bg-white/5` rounded container) for "ECA Rules", "Scheduled Triggers", and "Action Logs".

## Core Features

### 1. Stats Overview
- Fetches and displays the counts of rules, triggers, and logs.

### 2. ECA Rules Tab (Event-Condition-Action)
- List of natural language rules created by the user (e.g., "Remind me tomorrow at 9 AM").
- **Optimistic UI**: Toggling rule active/paused state updates instantly, with rollback on error.
- **Rule Card**:
  - Indicator dot (pulsing purple if active, gray if paused).
  - Natural language text.
  - Event type badge and creation date.
  - Action buttons: Pause/Resume (Play/Pause icon) and Delete (Trash icon).
- **Empty State**: Uses `NxEmptyState` with a brain icon if no rules exist.

### 3. Add Rule Modal
- **Trigger**: "New Rule" button.
- **Form**:
  - Textarea for "Natural Language Rule".
  - Checkbox to "Connect Global Memory" (Allow cross-referencing semantic memory).
  - Quick Examples (Clickable chips to pre-fill the textarea).
- **Submission**: Sends rule to API and adds it to the top of the list.

### 4. Scheduled Triggers Tab
- Shows upcoming time-based actions.
- Displays trigger type, scheduled time, and status badge (Pending, Completed, Failed).

### 5. Action Logs Tab
- Shows a history of completed autonomous actions.
- Displays the action taken, reasoning trace (italic text), timestamp, and success/failure status.
